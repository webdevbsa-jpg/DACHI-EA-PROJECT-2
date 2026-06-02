// Dachi_Trader_v13_11_33.mq5 — Expert Advisor
// Version: 13.11.33
// Clean Core branch: simplified runtime pipeline (F2 + HTF gate).

#property copyright   "Daniel @danieljulyanto"
#property version     "13.11.33"
#property description "Dachi Trader v13.11.33 — Expert Advisor"

#define MAX_TP            30
#define VOL_AVG_PERIOD    20
#define OBJ_PREFIX        "DT13_"
#define DB_CORNER         CORNER_LEFT_LOWER
#define DB_X              14
#define DB_Y_BASE         12
#define DB_LINE_H         17
#define DB_PANEL_W        320
#define DB_FONT_SZ        9
#define DB_FONT_NM        "Consolas"
#define DB_BG_COLOR       C'15,15,15'
#define DB_BG_BORDER      C'60,60,60'
#define DB_CLR_GREEN      C'0,200,80'
#define DB_CLR_RED        C'240,50,50'
#define DB_CLR_GRAY       C'160,160,160'
#define DB_CLR_WHITE      C'230,230,230'
#define DB_CLR_BLUE       C'70,130,255'
#define DB_CLR_YELLOW     C'255,200,50'
#define DB_CLR_CYAN       C'0,200,200'
#define DB_CLR_ORANGE     C'255,165,0'
#define DB_CLR_MAGENTA    C'255,0,255'    // v13.9.3: BLOCKED label color
#define DB_CLR_BG_GREEN   C'0,120,0'
#define DB_CLR_BG_RED     C'160,0,0'
#define DB_CLR_BG_BLACK   C'25,25,25'
#define DB_CLR_BG_TIME    C'30,40,60'
#define CLR_TP_HIT        C'64,224,208'

// === ENUMS ===
enum ENUM_FILTER_ACTION { F_OFF=0, F_SOFT=1, F_HARD=2 };
enum ENUM_SIGNAL_CLASS  { SC_VALID=0, SC_SOFT=1, SC_BLOCKED=2, SC_REENTRY=3, SC_REVERSAL=4, SC_F3_RECOVERY=5 };
enum ENUM_EXIT_TRIGGER  { EXIT_ON_TOUCH=0, EXIT_ON_CANDLE_CLOSE=1 };
enum ENUM_FILTER_DECISION { DEC_OK=0, DEC_LIMITED=1, DEC_BLOCKED=2 };
enum ENUM_SQUEEZE_STATE { SQ_NONE=0, SQ_BUILDUP=1, SQ_ARMED=2, SQ_BREAKOUT_UP=3, SQ_BREAKOUT_DN=4, SQ_CONFIRMED_UP=5, SQ_CONFIRMED_DN=6, SQ_FALSE_BREAK=7, SQ_LOCKOUT=8 };
// v13.10.0 Market Regime classification (issue #11)
enum ENUM_REGIME        { REG_UNKNOWN=0, REG_CHOPPY=1, REG_RANGING=2, REG_LONG_RANGING=3, REG_EARLY_BREAKOUT=4, REG_CONFIRMED_TREND=5, REG_DIRECTIONAL=6, REG_STRONG_DIRECTIONAL=7 };

// === INPUTS ===
input group "=== EA Trading ==="
input bool   InpIndicatorOnly   = false;
input bool   InpAutoLot         = false;
input double InpManualLot       = 0.01;
input double InpAutoLotDivider  = 20000;
input int    InpEAMagic         = 202603;
input int    InpStartupScanBars = 1200;      // max historical bars scanned on attach/settings reload
input int    InpVisualLazyBars  = 1200;      // initial MA/V-Line visual bars; expands on chart scroll
input bool   InpShowCoreMALines = true;      // show/hide both core MA lines and ribbon fill
input bool   InpShowTPSLEntryLines = true;   // show/hide ENTRY, SL, and TP lines/labels
input bool   InpShowBlockedSignals = true;  // show/hide BLOCKED signal labels and candle boxes
const bool   InpLateEntry       = false;
const double InpLateEntryATR    = 1.0;

input group "=== Core Engine ==="
input int    InpEMA_Fast        = 8;
input int    InpSMA_Slow        = 20;
input ENUM_MA_METHOD InpSlowMA_Method = MODE_LWMA;  // Slow MA method: SMA/EMA/SMMA/LWMA (v13.9.2: LWMA20 baseline)
input int    InpATR_Period      = 14;

input group "=== Visual Slow MA Angle Guard ==="
input bool   InpUseSlowMAAngleGuard   = true;
input double InpSlowMA_MinAngleDeg    = 0.0;    // BUY needs >= +deg, SELL needs <= -deg; 0 allows flat in signal direction

input group "=== Entropy Cluster Index (ECI v2) Sideways Filter ==="
input ENUM_FILTER_ACTION InpECI_Action         = F_SOFT; // OFF/SOFT/HARD anti-chop entropy gate
input int                InpECI_Lookback       = 18;     // rolling candle-structure window
input double             InpECI_ChopThreshold  = 0.82;   // high entropy needed before CHOP can trigger
input double             InpECI_MixedThreshold = 0.62;   // dashboard MIXED/ORDERED boundary
input double             InpECI_DirectionalBalanceMax = 0.22; // CHOP only if bull/bear balance is this low
input double             InpECI_BodyDominanceMax      = 0.38; // CHOP only if strong body share is this low

input group "=== Clean Core HTF Context (H1 Bias + M15 Setup) ==="
input bool   InpUseH1Bias         = true;
input bool   InpAllowNeutralBias  = false;
input bool   InpUseM15Setup       = true;
input bool   InpAllowM15Neutral   = false;
input bool   InpHTF_AllowReversalOverride = true;
input double InpHTF_ReversalBodyATRMin    = 0.70;

input group "=== V-Line Bias Guard ==="
input bool            InpUseVLineGuard      = true;   // V-Line bias guard
input ENUM_TIMEFRAMES InpVLine_TF                 = PERIOD_CURRENT;
input int             InpVLine_ATRLength          = 10;
input double          InpVLine_BaseMultiplier     = 3.0;
input double          InpVLine_NoiseThresholdATR  = 1.0;
input double          InpVLine_ExpansionAlphaATR  = 0.5;
input bool            InpVLine_BlockNeutral       = false;
input bool            InpVLine_ShowVisual         = true;
input bool            InpVLine_ShowSwitchLabels   = true;
input int             InpVLine_VisualBars         = 500;

input bool   InpUseSidewayGuard           = true;
input double InpSideway_MinEMASlopePts    = 0.35;
input int    InpSideway_CrossLookback      = 12;
input int    InpSideway_MaxCrosses         = 2;
input double InpSideway_MinMAGapATR        = 0.12;

input bool   InpUseATRHealthGuard          = true;
input double InpATR_M5_MinTrade            = 0.90;
input double InpATR_M5_MaxNormal           = 2.80;
input double InpATR_M5_MaxAllowed          = 4.50;
input double InpATR_M5_BlockAbove          = 5.50;
input double InpATR_FastRatioLimited       = 1.80;
input double InpATR_FastRatioBlock         = 2.20;

input bool   InpUseSqueezeGuard            = true;
input int    InpSQ_Lookback                = 20;
input double InpSQ_RangeATRMax             = 3.50;
input double InpSQ_ATRCompressionMax       = 0.80;
input double InpSQ_MAGapATRMax             = 0.18;
input int    InpSQ_CrossDensityLookback    = 30;
input int    InpSQ_CrossDensityMin         = 3;
input double InpSQ_BreakoutBufferATR       = 0.30;
input double InpSQ_MinBodyRatio            = 0.55;
input double InpSQ_BuyCloseLocMin          = 0.65;
input double InpSQ_SellCloseLocMax         = 0.35;
input double InpSQ_SpikeRatioBlock         = 2.20;

// input group "=== F0: EMA Gap Filter ==="
const ENUM_FILTER_ACTION InpGap_Action  = F_SOFT;
input int    InpGapPoints       = 100;       // min gap bar-0 look-ahead (points)
// v13.6.0: when true, the F0 threshold is computed dynamically as
// ATR × InpGap_ATRPct/100 instead of the static InpGapPoints.
// Useful when one EA preset is shared across high-vol (XAU news) and
// low-vol regimes — point thresholds don't scale, ATR-pct does.
const bool   InpGap_UseATRPct   = true;
const double InpGap_ATRPct      = 35.0;      // % of ATR to require as min gap

// input group "=== F1: DI+/DI- Validation (was F7 pre-v13.10.0) ==="
const ENUM_FILTER_ACTION InpF1_Action   = F_SOFT;
const double InpF1_Margin       = 3.0;       // DI margin

input group "=== F2: Crossing-to-Entry Distance (was F9 pre-v13.10.0) ==="
// Block signals where close (entry) is too far from the MA crossing point.
input ENUM_FILTER_ACTION InpF2_Action   = F_HARD;
input double InpF2_MaxDistATR            = 1.7;  // max |entry - cross_price| in ATR

// input group "=== F3: False-Block Recovery Entry (was F11 pre-v13.10.0) ==="
// Re-enters after a HARD blocked F0 cross only if price proves the block was
// false by breaking the blocked candle in signal direction.
const bool   InpF3_UseRecovery             = false;
const bool   InpF3_OnlyF0Blocks            = true;
const bool   InpF3_BlockOnF2               = true;   // never recover F2 (cross distance) blocks
const int    InpF3_RecoveryBars            = 8;
const double InpF3_BreakBufferATR          = 0.10;
const ENUM_EXIT_TRIGGER InpF3_Trigger      = EXIT_ON_CANDLE_CLOSE;
const bool   InpF3_RequireMAAligned        = true;
const bool   InpF3_RequireDIDirection      = true;
const bool   InpF3_EnterAsSoft             = true;
const bool   InpF3_BlockChoppyRange        = true;   // block recovery in ranging/choppy regimes
const double InpF3_MaxChoppyAND            = 0.65;   // stddev/ATR ceiling for F3 recovery
const int    InpF3_CooldownBars            = 20;     // block F3 N bars after a losing F3 trade
const bool   InpF3_BlockWickSweep          = true;   // skip F3 if last bar is a wick sweep against dir
const int    InpF3_CrossDensityLookback    = 30;     // bars to count MA crosses
const int    InpF3_MaxCrossDensity         = 5;      // > this many crosses in lookback → F3 off (sideway)
// Recovery point must be geometrically close to the original cross.
const double InpF3_MaxDistATR              = 1.5;    // |recovery_px - cross_px| max in ATR
// Refire window. Skip cooldown when the original setup is still intact.
const bool   InpF3_AllowRefire             = true;
const int    InpF3_RefireMaxBars           = 10;     // re-arm within this many bars of first fire
const double InpF3_RefireMaxDistATR        = 1.5;    // and price still within this many ATR of cross

// input group "=== F4: Slow MA Direction (was F14 pre-v13.10.0) ==="
const ENUM_FILTER_ACTION InpF4_Action       = F_SOFT;
const int                InpF4_LookbackBars = 4;
const double             InpF4_MinSlopePts  = 0.6;  // 0 = any direction; >0 = min slope pts/bar

// input group "=== F5: RVI Overbought/Oversold (was F15 pre-v13.10.0) ==="
const ENUM_FILTER_ACTION InpF5_Action          = F_SOFT;
const ENUM_TIMEFRAMES    InpF5_TF              = PERIOD_CURRENT;
const int                InpF5_Period          = 12;
const double             InpF5_OBLevel         = 0.72;   // BUY blocked when RVI > this
const double             InpF5_OSLevel         = -0.72;  // SELL blocked when RVI < this
const bool               InpF5_UseSignalLine   = true;  // also require RVI vs SignalLine cross

// input group "=== Intelligent Filter (v13.9.16) ==="
// Self-contained EMA20/EMA50 short-trend gate. No dashboard row, no labels,
// no visual artifacts. Works behind the scenes between signal detect and
// pipeline execution.
//   - Uptrend (EMA20 > EMA50): only BUY allowed.
//   - Downtrend (EMA20 < EMA50): only SELL allowed.
//   - Counter-trend signal with price OUTSIDE the EMA band: always blocked.
//   - Counter-trend signal with price BETWEEN the EMAs + UseExhaustion=true:
//     allowed only when the opposing trend is exhausted (RVI or Stochastic
//     extreme on the same TF). Without UseExhaustion, every counter-trend
//     signal is blocked.
// TF = PERIOD_CURRENT reads EMAs/RVI/Stoch on whatever timeframe the chart
// is showing (useful for one-EA-many-charts setups).
const bool            InpIF_Enable        = true;
const ENUM_TIMEFRAMES InpIF_TF            = PERIOD_CURRENT;
const bool            InpIF_UseExhaustion = true;

input group "=== Wick / Liquidity Sweep Detector (v13.9.0) ==="
// Used by Judge candle component and F11 break-candle guard. Distinguishes:
//   - "Bad sweep" = wick aligned with our intended entry direction
//     (BUY with upper-wick sweep into prior highs = entering at exhaustion).
//   - "Good sweep" = wick against the signal direction that flushed opposition
//     (BUY with lower-wick sweep that closed back up = bullish stop hunt).
input bool   InpWick_UseFilter              = true;  // Use wick / liquidity-sweep detector
input int    InpWick_SweepLookback          = 10;    // bars to scan for prev high/low
input double InpWick_MinWickRatio           = 0.60;  // wick/range ratio to count as dominant
input int    InpWick_ConfirmBars            = 1;     // post-sweep confirm bars (reserved)

// input group "=== Market Regime Detector (v13.10.0, issue #11) ==="
// Classifies the current bar into one of five regimes and gates entries.
// Built on ATR fast/slow + Efficiency Ratio + EMA20/50 + ADX/DI.
const bool   InpRegime_Enable         = true;
// --- ATR setup (in addition to base ATR(14)) ---
const int    InpRegime_ATRFastPeriod  = 5;       // ATR fast = recent volatility
const int    InpRegime_ATRSlowPeriod  = 20;      // ATR slow = stable baseline
// --- Efficiency Ratio ---
const int    InpRegime_ER_Period      = 12;      // N for ER calc (M1=14, M5=10..14)
const double InpRegime_ER_ChoppyMax   = 0.18;    // ER < this → choppy (fallback also)
const double InpRegime_ER_NeutralMax  = 0.33;    // ER < this → ranging fallback
const double InpRegime_ER_DirectionalMin = 0.33; // ER ≥ this → DIRECTIONAL fallback
const double InpRegime_ER_StrongDirMin   = 0.52; // ER ≥ this → STRONG_DIRECTIONAL fallback
// v13.11.2 — slope guard for fallback bucket. When ER is in [ChoppyMax,
// DirectionalMin) but EMA50 has clearly directional slope over the past N
// bars, upgrade RANGING WEAK_ER → DIRECTIONAL (so pullback bars inside a
// strong trend don't get blocked when their local ER dips).
const int    InpRegime_FallbackSlopeBars   = 10;   // bars back for EMA50 slope check
const double InpRegime_FallbackSlopeATRMult= 0.30; // EMA50 delta ≥ this × ATR ⇒ directional
// --- EMA20/EMA50 (reused from IF when IF is also on) ---
const int    InpRegime_EMA_Fast       = 20;
const int    InpRegime_EMA_Slow       = 50;
// --- Choppy regime detection ---
const bool   InpRegime_DetectChoppy   = true;
const int    InpRegime_ChoppyLookback = 24;      // bars for range / cross-count
const double InpRegime_ChoppyRangeATRMult = 1.5; // range < 1.5*ATR(14) for choppy
const double InpRegime_ChoppyMAGapATRMult = 0.25;// |EMA20-EMA50| < 0.25*ATR(14)
const int    InpRegime_ChoppyMinCrosses   = 3;   // min EMA8/LWMA20 crosses in lookback
// --- Ranging regime detection ---
const bool   InpRegime_DetectRanging  = true;
const int    InpRegime_RangingLookback = 24;
const double InpRegime_RangingSizeATRMult = 1.5; // RangeSize >= 1.5*ATR(14)
const double InpRegime_RangingMidLo  = 0.40;     // block when PricePos in [Lo,Hi]
const double InpRegime_RangingMidHi  = 0.60;
const double InpRegime_RangingER_Max = 0.35;
// --- Long Ranging detection (extended consolidation) ---
const bool   InpRegime_DetectLongRanging  = true;
const int    InpRegime_LongRangeLookbackM1 = 80;
const int    InpRegime_LongRangeLookbackM5 = 48;
const double InpRegime_LongRangeEMA50FlatATRMult = 0.20; // |EMA50[0]-EMA50[10]| < 0.20*ATR
const double InpRegime_LongRangeAvgERMax = 0.30;          // mean of last 3 ER samples
const double InpRegime_LongRangeBreakoutBufATRMult = 0.20;
// --- Early Breakout detection ---
const bool   InpRegime_DetectEarlyBreakout = true;
const double InpRegime_EarlyBreakoutADXMax = 22.0;
const int    InpRegime_EarlyBreakoutADXSlopeBars = 3;
const double InpRegime_EarlyBreakoutER_Min = 0.30;
const double InpRegime_EarlyBreakoutATRFastRatio = 1.10;  // ATR(5) >= 1.10 * ATR(20)
const int    InpRegime_EarlyBreakoutRangeBars = 20;
const double InpRegime_EarlyBreakoutBufATRMult = 0.10;
const double InpRegime_EarlyBreakoutMinBodyRatio = 0.50;
const double InpRegime_EarlyBreakoutMaxWickBodyMult = 1.5;
const double InpRegime_EarlyBreakoutLotMult = 0.5;        // 0.5x lot when in early breakout
// --- Confirmed Trend detection ---
const bool   InpRegime_DetectConfirmedTrend = true;
const int    InpRegime_ConfirmedSlowSlopeBars = 5;
const int    InpRegime_ConfirmedFastSlopeBars = 3;
const double InpRegime_ConfirmedMAGapATRMult  = 0.25;     // |EMA20-EMA50| > 0.25*ATR
const double InpRegime_ConfirmedADXMin = 22.0;
const double InpRegime_ConfirmedER_Min = 0.35;

input group "=== Soft Mode TP/SL (when filter = SOFT) ==="
input double InpSoft_TP1_Mult   = 0.4;
input double InpSoft_TP2_Mult   = 0.4;      // TP2 = TP1 + 0.4*ATR
input double InpSoft_SL_Mult    = 0.75;     // SL forced ON in soft mode

// === RETIRED RE-ENTRY CONSTANTS (hidden from Inputs) ===
const bool   InpUseReentry      = false;
const bool   InpReentryRequireMomentum = false;
const bool   InpUseRetestReentry= false;
const int    InpRetestBars      = 10;

input group "=== Take Profit ==="
input double InpTP1_Mult        = 0.75;     // TP1 = entry ± 0.75*ATR
input double InpTP1_to_TP2_Mult = 0.75;     // TP2 = TP1 ± 0.75*ATR → 1.5*ATR from entry
input double InpTP_Step_Mult    = 1.0;

input group "=== Manual TP Target Exit ==="
// When enabled, choose the TP number that will close the remaining position
// automatically on live touch. Example: Target=2 closes at TP2. If the
// partial system is disabled here, Smart-TP partials are suppressed and the
// full lot is held until the selected manual TP target is touched.
input bool   InpManualTP_Enable            = false;
input int    InpManualTP_Target            = 2;       // 1..30, e.g. 2 = TP2 close
input bool   InpManualTP_UsePartialSystem  = false;   // allow Smart-TP partials before final target

input group "=== Smart TP ==="
input bool   InpUseSmartTP      = false;   // Use Smart TP partial-close system
input bool   InpSTP1_UseSubZones = false;  // TP1 sub-zone partials (Smart TP)
input bool   InpSTP2_UseSubZones = false;  // TP2 sub-zone partials (Smart TP)
input bool   InpSTP3_UsePartial  = false;  // TP3+ reversal partials (Smart TP)
input double InpSTP1_Pct        = 30;
input double InpSTP2_Pct        = 30;

input group "=== Stop Loss ==="
input bool   InpUseSL           = false;
input double InpSL_Mult         = 1.25;
input ENUM_EXIT_TRIGGER InpSL_HardlineTrigger = EXIT_ON_TOUCH;

// === RETIRED SMART SL CONSTANTS (hidden from Inputs) ===
const bool   InpUseSmartSL      = false;

input group "=== Fast MA Protective Exit ==="
input bool   InpUseEarlyExit    = false;      // repurposed: exit on fast MA after MA expansion
input double InpEarlyExit_MinGapATR = 1.0;
input ENUM_EXIT_TRIGGER InpEarlyExit_Trigger = EXIT_ON_TOUCH;
input int    InpEarlyExit_ArmBars = 1;

input group "=== Adaptive Reversal Exit ==="
input bool   InpUseAdaptiveReversal = false;
input double InpAdapt_PullbackATR   = 1.5;
input int    InpAdapt_FastBars      = 3;

input group "=== Progressive Exit (v13.9.4) ==="
// Two-phase exit manager. Phase 1: while the configured TP-lock level has
// not been hit yet, close the position when a tick touches the fast EMA
// (TOUCH mode) or when the bar closes at/through the fast EMA (CANDLE_CLOSE
// mode). Phase 2: after TP[InpPE_BEPAfterTP] hits, the SL is moved to the
// original entry price ("SL+" / break-even lock) and PE continues to watch
// for any retrace back through entry, closing the position there if reached.
//
// Independent from InpUseSL — PE works whether or not a hard SL is set.
// PE only manages the EA's runtime position; it does not push broker-side
// SL changes (visual SL line still updates via g_sl_price).
input bool   InpUsePE              = false;
input ENUM_EXIT_TRIGGER InpPE_Trigger = EXIT_ON_TOUCH;
input int    InpPE_BEPAfterTP      = 2;       // 1..MAX_TP — TP level that arms BEP lock
// v13.9.5 — Phase 0 grace period (early-trade buffer)
input int    InpPE_Phase0Bars      = 4;       // bars after entry where Phase 0 (buffer) applies
input double InpPE_Phase0BufferATR = 0.5;     // buffer below/above fast MA in ATR multiples

input group "=== Spike SL (adverse-velocity exit) ==="
input bool   InpUseSpikeSL      = false;
input double InpSpike_ATR_Mult  = 2.0;       // exit if forming bar adverse move >= N × entry ATR

input group "=== Market Filters ==="
input int    InpMax_Spread      = 45;
input int    InpEASlippage      = 30;
input bool   InpUseDailyLoss    = false;
input double InpDailyLossLimit  = 50.0;
input bool   InpUseDailyProfitStop = false;
input double InpDailyProfitTarget  = 50.0;
input bool   InpUseSession      = false;
// Window in server hours [Start, End). Trades blocked OUTSIDE this window
// on days where the per-day toggle is true. End=24 means "until midnight".
input int    InpSessionStart    = 8;
input int    InpSessionEnd      = 22;
// Per-day "filter active" toggles. Semantics in v13.5.0:
//   true  → session filter ACTIVE this day, block trading outside the
//           [Start, End) hour window AND auto-close any open position
//           when the clock crosses End.
//   false → no session filter this day, EA trades freely 24h.
// All days default to false so the filter opts-in.
input bool   InpSessionMon      = true;
input bool   InpSessionTue      = true;
input bool   InpSessionWed      = true;
input bool   InpSessionThu      = true;
input bool   InpSessionFri      = true;
input bool   InpSessionSat      = false;
input bool   InpSessionSun      = false;
input int    InpMaxBarsInTrade  = 0;

input group "=== Alerts ==="
input bool   InpAlertSound      = true;
input bool   InpAlertPush       = false;
input bool   InpAlertPopup      = true;

input group "=== Display ==="
input color  InpBuyColor        = clrLime;
input color  InpSellColor       = clrRed;
input color  InpEntryColor      = clrDodgerBlue;

// === License (online verify, hardcoded in v13.5.0) ===
// HMAC-SHA256 against dachi-trader.com. Required to enter new trades.
// Existing positions are never auto-closed by license logic.
//
// Settings are HARDCODED constants (not exposed as Input parameters) so
// end users cannot disable the license check or paste a wrong secret.
// The .mq5 file MUST stay private — distribute only the compiled .ex5.
const bool   InpLicense_Enabled    = true;
const string InpLicense_URL        = "https://dachi-trader.com";
const string InpLicense_HmacSecret = "435eb0dc6163e6efb1cc067d56c7353eb7f6e8c98f8d80c4f8086bf1aab59236";
const int    InpLicense_RecheckMin = 60;   // re-verify setiap N menit
const int    InpLicense_GraceDays  = 7;    // toleransi offline (hari)

// === APPROVED FEATURE GATES (v13.10.0) ===
// Kept legacy modules forced OFF so old .set files cannot revive them.
bool UseLateEntry(){return false;}
bool UseClassicReentry(){return false;}
bool UseRetest(){return false;}
bool UseSmartSL(){return false;}
bool UseManualTPTarget(){return (InpManualTP_Enable&&InpManualTP_Target>=1&&InpManualTP_Target<=MAX_TP);}
bool UseSmartTP(){return (InpUseSmartTP&&(!UseManualTPTarget()||InpManualTP_UsePartialSystem));}

// === LICENSE STATE ===
bool     g_license_valid       = false;            // gate for EAOpen
datetime g_license_expires_at  = 0;                // 0 = lifetime
datetime g_license_last_ok     = 0;                // last successful verify
datetime g_license_last_check  = 0;                // last attempt (ok or not)
string   g_license_state_label = "UNKNOWN";        // for dashboard
string   g_license_plan        = "";
bool     g_license_grace_mode  = false;
// v13.5.0: distinguish "server actively denied this account" (do not enter
// offline grace) from "couldn't reach server / signature mismatch" (which
// can fall back to grace). Set by LIC_VerifyOnce; consumed by CheckLicence.
bool     g_license_explicit_deny = false;

// === HANDLES ===
int h_ema_fast=INVALID_HANDLE, h_sma_slow=INVALID_HANDLE, h_atr=INVALID_HANDLE;
int h_adx=INVALID_HANDLE;       // F1 DI± + Regime ADX/slope (ADX buf 0, DI+ buf 1, DI- buf 2)
int h_f5_rvi=INVALID_HANDLE;    // F5 RVI handle (was h_f15_rvi)
// Intelligent Filter handles — EMA20/EMA50 trend + exhaustion check
int h_if_ema20=INVALID_HANDLE;
int h_if_ema50=INVALID_HANDLE;
int h_if_rvi  =INVALID_HANDLE;
int h_if_stoch=INVALID_HANDLE;
// v13.10.0 Market Regime handles — ATR fast/slow (separate from base h_atr)
int h_atr_fast=INVALID_HANDLE;  // ATR(InpRegime_ATRFastPeriod)
int h_atr_slow=INVALID_HANDLE;  // ATR(InpRegime_ATRSlowPeriod)
int h_regime_ema_fast=INVALID_HANDLE;   // EMA20 (regime-side)
int h_regime_ema_slow=INVALID_HANDLE;   // EMA50 (regime-side)
// v13.9.17 — Intelligent Filter dashboard state (only updated when idx==1
// so historical ScanHistory passes don't clobber the live readout)
string g_if_trend = "---";   // UP / DN / FLAT / ---
string g_if_state = "---";   // ALIGN / OUT-BAND / BAND / EXH-OK / EXH-NO / ---
bool   g_if_block = false;   // last live decision (true = blocked)

// === CORE STATE ===
int    g_last_signal=0, g_last_signal_bar=0;
double g_last_entry=0, g_entry_price=0, g_sl_price=0, g_sl_initial_dist=0;
double g_tp[MAX_TP]; bool g_tp_hit[MAX_TP]; int g_tp_unlocked=5;
double g_entry_atr=0, g_initial_lot=0, g_closed_lot_total=0;
double g_ema_fast=0, g_sma_slow=0, g_atr_val=0;
double g_ema_fast_b0=0, g_sma_slow_b0=0;
datetime g_last_bar_time=0; int g_current_bar=0;
bool g_dash_visible=true, g_history_done=false, g_dashboard_dirty=true;
bool g_vline_visual_initialized=false;
double g_daily_loss=0, g_daily_profit=0; bool g_daily_blocked=false, g_daily_profit_blocked=false; datetime g_daily_date=0;
ulong g_ea_ticket=0; int g_bars_in_trade=0, g_entry_bar=0, g_consec_loss=0;
// Smart TP
int g_stp1_phase=0; double g_stp1_lot_per=0;
int g_stp2_phase=0; double g_stp2_lot_per=0;
int g_stp3_highestTP=0; double g_stp3_partialPct=0;
bool g_stp3_triggered[MAX_TP]; int g_stp3_direction=0; bool g_stp3_armed=false;
// Re-entry
bool g_awaiting_reentry=false; int g_reentry_dir=0; string g_reentry_reason="";
// SL state
bool g_sl_forced=false; int g_ssl_phase=0; double g_ssl_lot_per=0;
// Soft mode active
bool g_soft_mode=false;
// Peak tracking
double g_peak_price=0; int g_peak_bar=0;
// Retest
bool g_retest_armed=false; int g_retest_dir=0; int g_retest_counter=0;
bool g_retest_seen_pullback=false;
// Visual
int g_visual_signal=0; double g_visual_entry=0, g_visual_sl=0;
double g_visual_tp[MAX_TP]; bool g_visual_tp_hit[MAX_TP];
double g_visual_atr=0; int g_visual_tp_unlocked=5;

// === FILTER STATE (for dashboard display) ===
bool   g_f0_trig=false, g_f1_trig=false, g_f2_trig=false, g_f4_trig=false, g_f5_trig=false;
double g_f1_dip=0, g_f1_dim=0;        // DI+ / DI- readings for F1 dashboard
double g_f4_slope_pts=0;              // F4 slow MA slope (pts/bar)
double g_f5_val=0;                    // F5 RVI main-line value
double g_f5_sig_line=0;               // F5 RVI signal line
string g_f5_reason="OK";              // F5 dashboard reason
// F3 false-block recovery state (was F11 pre-v13.10.0)
bool   g_f3_armed=false; int g_f3_dir=0, g_f3_counter=0;
double g_f3_break_high=0, g_f3_break_low=0; datetime g_f3_time=0; string g_f3_reason="---";
// Refire context captured at the moment F3 fires (live only)
datetime g_f3_fire_time = 0;
double   g_f3_fire_cross_px = 0;
double   g_f3_fire_atr = 0;
int      g_f3_fire_dir = 0;
int    g_f3_cooldown_bars=0;
bool   g_last_entry_was_f3=false;
int    g_f3_fire_count=0;
int    g_f3_loss_count=0;

// v13.9.4 Progressive Exit state — Phase-2 latch
bool     g_pe_bep_armed=false;
datetime g_pe_entry_time=0;
bool   g_pipe_hard=false, g_pipe_soft=false;
// v13.11.0 — filter-only hard (excludes regime contribution) so the chart
// label can combine filter_class with regime_class independently of the
// entry-gate decision (which still uses g_pipe_hard = filter || regime).
bool   g_pipe_filter_hard=false;
string g_last_decision="---"; // "V","S","B","D"

// === F0 dashboard fix ===
double g_last_signal_gap_pts=0;
double g_slowma_angle_deg=0.0; bool g_slowma_angle_block=false; string g_slowma_angle_state="OFF";
double g_eci_score=0.0, g_eci_direction_balance=0.0, g_eci_body_dominance=0.0; bool g_eci_trig=false; string g_eci_state="OFF";
ENUM_SQUEEZE_STATE g_sq_state = SQ_NONE;
double g_sq_range_high = 0.0;
double g_sq_range_low = 0.0;
string g_sq_reason = "";
int    g_est_dir = 0;
double g_est_band = 0.0;
bool   g_est_noisy = false;
string g_est_state = "OFF";

// === v13.9.0 Wick / Liquidity Sweep state ===
bool   g_wick_bad_sweep=false;
bool   g_wick_good_sweep=false;
string g_wick_reason="OK";
double g_wick_ratio=0;

// === v13.10.0 Market Regime state (issue #11) ===
ENUM_REGIME g_regime           = REG_UNKNOWN;
string      g_regime_reason    = "---";
double      g_regime_atr_fast  = 0;     // ATR(5) value
double      g_regime_atr_slow  = 0;     // ATR(20) value
double      g_regime_er        = 0;     // Efficiency Ratio (0..1)
double      g_regime_ema20     = 0;
double      g_regime_ema50     = 0;
double      g_regime_ma_gap    = 0;     // |EMA20 - EMA50|
double      g_regime_range     = 0;     // HighestHigh(N) - LowestLow(N) over ChoppyLookback
double      g_regime_pricepos  = 0.5;   // 0..1 position within ranging window
int         g_regime_cross_count = 0;   // EMA8/LWMA20 crosses within lookback
double      g_regime_lot_scale = 1.0;   // multiplier for early breakout (0.5x) etc.
bool        g_regime_block     = false; // current regime blocks entry?



// =============================================================================
// === LICENSE CLIENT (v13.4.0) ===
// =============================================================================
// Talks to https://<host>/backend/api/license/verify.php every N minutes,
// verifies the HMAC-SHA256 signature on the response, and caches the last
// successful result so the EA keeps trading during a brief outage.
//
// Server canonical signing string (must match exactly):
//   "<v>|<expires_or_lifetime>|<plan>|<account>|<server_time>"
//
// where <v> = "1" / "0", <expires_or_lifetime> = "YYYY-MM-DD" or "lifetime",
// <plan> = plan code, <account> = account number, <server_time> = ISO8601 UTC.
// =============================================================================

// Hex-encode a byte array (lowercase).
string LIC_HexEncode(const uchar &bytes[]){
    string s=""; int n=ArraySize(bytes);
    for(int i=0;i<n;i++) s+=StringFormat("%02x",bytes[i]);
    return s;
}

// HMAC-SHA256(key, message) → lowercase hex string.
// Implements the RFC 2104 construction on top of MQL5's CryptEncode SHA-256.
string LIC_HmacSha256(const string &key, const string &message){
    int BLK = 64;
    uchar key_bytes[]; StringToCharArray(key, key_bytes, 0, StringLen(key));
    uchar dummy[];
    if(ArraySize(key_bytes) > BLK){
        uchar khash[]; CryptEncode(CRYPT_HASH_SHA256, key_bytes, dummy, khash);
        ArrayResize(key_bytes, ArraySize(khash));
        for(int i=0;i<ArraySize(khash);i++) key_bytes[i] = khash[i];
    }
    uchar pad[]; ArrayResize(pad, BLK);
    for(int i=0;i<BLK;i++) pad[i] = (i < ArraySize(key_bytes)) ? key_bytes[i] : 0;
    uchar ikey[], okey[]; ArrayResize(ikey, BLK); ArrayResize(okey, BLK);
    for(int i=0;i<BLK;i++){ ikey[i] = pad[i] ^ 0x36; okey[i] = pad[i] ^ 0x5C; }

    uchar msg_bytes[]; StringToCharArray(message, msg_bytes, 0, StringLen(message));
    int mlen = ArraySize(msg_bytes);
    uchar inner_input[]; ArrayResize(inner_input, BLK + mlen);
    for(int i=0;i<BLK;i++)  inner_input[i]       = ikey[i];
    for(int i=0;i<mlen;i++) inner_input[BLK + i] = msg_bytes[i];
    uchar inner_hash[]; CryptEncode(CRYPT_HASH_SHA256, inner_input, dummy, inner_hash);

    int hlen = ArraySize(inner_hash);
    uchar outer_input[]; ArrayResize(outer_input, BLK + hlen);
    for(int i=0;i<BLK;i++)  outer_input[i]       = okey[i];
    for(int i=0;i<hlen;i++) outer_input[BLK + i] = inner_hash[i];
    uchar outer_hash[]; CryptEncode(CRYPT_HASH_SHA256, outer_input, dummy, outer_hash);

    return LIC_HexEncode(outer_hash);
}

// Tiny string-only JSON field extractor. Looks for "key":"value" or
// "key":bool/number/null. Returns the captured string, or "" if absent.
string LIC_JsonGet(const string &json, const string &key){
    string needle = "\"" + key + "\"";
    int p = StringFind(json, needle);
    if(p < 0) return "";
    p += StringLen(needle);
    while(p < StringLen(json) && (StringGetCharacter(json,p)==':' ||
                                  StringGetCharacter(json,p)==' ' ||
                                  StringGetCharacter(json,p)=='\t')) p++;
    if(p >= StringLen(json)) return "";
    ushort c = StringGetCharacter(json, p);
    if(c == '"'){
        int q = StringFind(json, "\"", p+1);
        if(q < 0) return "";
        return StringSubstr(json, p+1, q-p-1);
    }
    int e = p;
    while(e < StringLen(json)){
        ushort ch = StringGetCharacter(json,e);
        if(ch==',' || ch=='}' || ch==']' || ch==' ' || ch=='\n' || ch=='\r' || ch=='\t') break;
        e++;
    }
    return StringSubstr(json, p, e-p);
}

// Persist last successful verify so the EA can run InpLicense_GraceDays
// after going offline. Uses MT5 GlobalVariableSet (string-of-doubles).
// Format: 4 keys per EA-magic so multiple instances on the same terminal
// don't clobber each other.
string LIC_GVKey(string suffix){
    return StringFormat("DACHI_LIC_%I64u_%s",(ulong)InpEAMagic, suffix);
}
void LIC_SaveCache(datetime expires, datetime verified, string plan){
    GlobalVariableSet(LIC_GVKey("expires"),  (double)expires);
    GlobalVariableSet(LIC_GVKey("verified"), (double)verified);
    GlobalVariableTemp(LIC_GVKey("verified"));
    // plan is a short string; encode by storing length + bytes is overkill,
    // we just stash a hash to reconstruct visually. Skip.
}
bool LIC_LoadCache(datetime &expires, datetime &verified){
    if(!GlobalVariableCheck(LIC_GVKey("verified"))) return false;
    expires  = (datetime)GlobalVariableGet(LIC_GVKey("expires"));
    verified = (datetime)GlobalVariableGet(LIC_GVKey("verified"));
    return verified > 0;
}

// Update dashboard label + g_license_grace_mode based on current state.
void LIC_UpdateLabel(){
    if(g_license_valid){
        if(g_license_grace_mode){
            int days_left = (int)((g_license_last_ok + (long)InpLicense_GraceDays*86400 - TimeCurrent())/86400);
            if(days_left < 0) days_left = 0;
            g_license_state_label = "GRACE " + IntegerToString(days_left) + "d";
        } else {
            string until = (g_license_expires_at == 0) ? "lifetime"
                : TimeToString(g_license_expires_at, TIME_DATE);
            g_license_state_label = "OK " + until;
        }
    } else {
        g_license_state_label = (g_license_last_check == 0) ? "OFFLINE" : "DENIED";
    }
}

// Main verify routine. Returns true on a fresh authoritative valid response.
// On any failure (network, signature, denial) returns false; the caller
// (CheckLicense) decides whether to fall through to the cached grace.
bool LIC_VerifyOnce(){
    if(!InpLicense_Enabled){ g_license_valid=true; g_license_state_label="DISABLED"; return true; }
    if(StringLen(InpLicense_HmacSecret) < 16){
        Print("[LIC] HMAC secret kosong/terlalu pendek. Set InpLicense_HmacSecret.");
        return false;
    }
    string url = InpLicense_URL + "/backend/api/license/verify.php";
    long account = AccountInfoInteger(ACCOUNT_LOGIN);
    string body = StringFormat("{\"account_number\":\"%I64u\",\"ea_version\":\"13.11.33\"}", (ulong)account);
    char post[]; StringToCharArray(body, post, 0, StringLen(body));
    char result[]; string headers="Content-Type: application/json\r\n"; string resp_headers;
    int timeout = 5000;

    g_license_last_check = TimeCurrent();
    g_license_explicit_deny = false;   // reset; only set on signed denial
    ResetLastError();
    int code = WebRequest("POST", url, headers, timeout, post, result, resp_headers);
    if(code == -1){
        Print("[LIC] WebRequest failed err=",GetLastError(),
              " — pastikan ", InpLicense_URL, " sudah ditambahkan di",
              " Tools→Options→Expert Advisors→Allow WebRequest.");
        return false;
    }
    if(code != 200){
        Print("[LIC] HTTP ",code," from license server.");
        return false;
    }
    string resp = CharArrayToString(result);

    string valid_s   = LIC_JsonGet(resp, "valid");
    string expires_s = LIC_JsonGet(resp, "expires_at");
    string plan_s    = LIC_JsonGet(resp, "plan");
    string acct_s    = LIC_JsonGet(resp, "account_number");
    string time_s    = LIC_JsonGet(resp, "server_time");
    string sig_s     = LIC_JsonGet(resp, "signature");

    bool   srv_valid = (valid_s == "true" || valid_s == "1");
    if(StringLen(sig_s) != 64){ Print("[LIC] Bad signature length."); return false; }

    string canonical = StringFormat("%s|%s|%s|%s|%s",
        srv_valid ? "1" : "0",
        (expires_s == "" || expires_s == "null") ? "lifetime" : expires_s,
        plan_s, acct_s, time_s);
    string mine = LIC_HmacSha256(InpLicense_HmacSecret, canonical);
    if(mine != sig_s){
        Print("[LIC] Signature mismatch — kemungkinan secret salah / MITM.");
        Print("[LIC] expected=",mine," got=",sig_s);
        return false;
    }

    g_license_plan        = plan_s;
    g_license_expires_at  = (expires_s == "" || expires_s == "null")
                              ? 0
                              : StringToTime(expires_s + " 23:59:59");

    if(!srv_valid){
        g_license_valid          = false;
        g_license_grace_mode     = false;
        g_license_explicit_deny  = true;   // server reachable + signed denial
        Print("[LIC] DENIED for account ",acct_s," — server says license not valid.");
        return false;
    }

    g_license_valid          = true;
    g_license_grace_mode     = false;
    g_license_explicit_deny  = false;
    g_license_last_ok        = TimeCurrent();
    LIC_SaveCache(g_license_expires_at, g_license_last_ok, plan_s);
    Print("[LIC] OK acct=",acct_s," plan=",plan_s," expires=",
          (g_license_expires_at==0?"lifetime":TimeToString(g_license_expires_at, TIME_DATE)));
    return true;
}

// =============================================================================
// === UNAUTHORIZED OVERLAY (v13.4.1) ===
// =============================================================================
// When the license check fails (and is not in grace mode), block every UI
// element by repainting a full-chart red panel + 3-line message. The overlay
// is repainted on every OnTick to defeat manual ObjectDelete by the user.
// One-shot Alert popup fires the first time the license flips invalid each
// EA-load, plus on every valid->invalid transition during a session.
// =============================================================================

bool g_lic_alert_shown = false;     // OnInit-level latch
bool g_lic_was_valid   = true;      // tracks transitions for OnTimer alerts

string LIC_OverlayName(string suffix){ return OBJ_PREFIX + "LIC_OVERLAY_" + suffix; }

void LIC_ClearOverlay(){
    ObjectDelete(0, LIC_OverlayName("BG"));
    ObjectDelete(0, LIC_OverlayName("L1"));
    ObjectDelete(0, LIC_OverlayName("L2"));
    ObjectDelete(0, LIC_OverlayName("L3"));
}

// v13.5.0: when the overlay is showing, every other DT_-prefixed chart
// object is wiped so the chart truly looks "blank except for the warning".
// Iterates the chart's object list and deletes anything whose name starts
// with OBJ_PREFIX but is NOT one of the four LIC_OVERLAY_* objects.
void LIC_NukeAllOtherObjects(){
    string keep[4];
    keep[0] = LIC_OverlayName("BG");
    keep[1] = LIC_OverlayName("L1");
    keep[2] = LIC_OverlayName("L2");
    keep[3] = LIC_OverlayName("L3");
    int total = ObjectsTotal(0, 0, -1);
    for(int i = total - 1; i >= 0; i--){
        string n = ObjectName(0, i, 0, -1);
        if(StringFind(n, OBJ_PREFIX) != 0) continue;
        bool is_keep = false;
        for(int k = 0; k < 4; k++) if(n == keep[k]){ is_keep = true; break; }
        if(!is_keep) ObjectDelete(0, n);
    }
}

bool IsDachiEAObjectName(string name){
    // Current and legacy Dachi EA chart objects all use DT13/DT13_ prefixes.
    // Keep this defensive rather than relying on one exact prefix only, because
    // older builds used the same family of names and may remain after upgrades.
    return (StringFind(name, OBJ_PREFIX)==0 || StringFind(name, "DT13")==0);
}

int CleanupAllEAObjects(){
    // Defensive remove cleanup: delete every chart object created by this EA,
    // including license overlay, dashboard, V-Line, MA ribbon, signal labels,
    // TP/SL/Entry lines, F3 visuals, diagnostics, and exit markers.
    int total_deleted=0;
    for(int pass=0; pass<10; pass++){
        int deleted=0;
        for(int i=ObjectsTotal(0,0,-1)-1; i>=0; i--){
            string n=ObjectName(0,i,0,-1);
            if(IsDachiEAObjectName(n)){
                if(ObjectDelete(0,n)) deleted++;
                else ObjectDelete(0,n);
            }
        }
        ObjectsDeleteAll(0,OBJ_PREFIX,-1,-1);
        ObjectsDeleteAll(0,"DT13",-1,-1);
        total_deleted+=deleted;

        bool still_exists=false;
        for(int j=ObjectsTotal(0,0,-1)-1; j>=0; j--){
            string left=ObjectName(0,j,0,-1);
            if(IsDachiEAObjectName(left)){ still_exists=true; break; }
        }
        ChartRedraw();
        if(!still_exists) break;
    }
    LIC_ClearOverlay();
    return total_deleted;
}

void LIC_DrawUnauthorizedOverlay(){
    // Background panel — anchored to chart corners so it covers everything.
    string bg = LIC_OverlayName("BG");
    if(ObjectFind(0, bg) < 0){
        ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    }
    int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
    int chart_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
    ObjectSetInteger(0, bg, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
    ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, 0);
    ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, 0);
    ObjectSetInteger(0, bg, OBJPROP_XSIZE,     chart_w);
    ObjectSetInteger(0, bg, OBJPROP_YSIZE,     chart_h);
    ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,   C'30,0,0');
    ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bg, OBJPROP_COLOR,     C'120,0,0');
    ObjectSetInteger(0, bg, OBJPROP_WIDTH,     3);
    ObjectSetInteger(0, bg, OBJPROP_BACK,      false);
    ObjectSetInteger(0, bg, OBJPROP_SELECTABLE,false);
    ObjectSetInteger(0, bg, OBJPROP_HIDDEN,    true);

    // 3-line centred text. Use OBJ_LABEL with corner LEFT_UPPER so positions
    // are pixel-precise and re-render survives chart resize.
    int cx = chart_w / 2;
    int cy = chart_h / 2;

    string l1 = LIC_OverlayName("L1");
    if(ObjectFind(0, l1) < 0) ObjectCreate(0, l1, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, l1, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
    ObjectSetInteger(0, l1, OBJPROP_XDISTANCE, cx);
    ObjectSetInteger(0, l1, OBJPROP_YDISTANCE, cy - 56);
    ObjectSetInteger(0, l1, OBJPROP_ANCHOR,    ANCHOR_CENTER);
    ObjectSetString (0, l1, OBJPROP_TEXT,      "⚠  UNAUTHORIZED ACCOUNT");
    ObjectSetInteger(0, l1, OBJPROP_COLOR,     C'255,80,80');
    ObjectSetInteger(0, l1, OBJPROP_FONTSIZE,  28);
    ObjectSetString (0, l1, OBJPROP_FONT,      "Arial Black");
    ObjectSetInteger(0, l1, OBJPROP_SELECTABLE,false);
    ObjectSetInteger(0, l1, OBJPROP_HIDDEN,    true);

    string l2 = LIC_OverlayName("L2");
    if(ObjectFind(0, l2) < 0) ObjectCreate(0, l2, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, l2, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
    ObjectSetInteger(0, l2, OBJPROP_XDISTANCE, cx);
    ObjectSetInteger(0, l2, OBJPROP_YDISTANCE, cy - 8);
    ObjectSetInteger(0, l2, OBJPROP_ANCHOR,    ANCHOR_CENTER);
    ObjectSetString (0, l2, OBJPROP_TEXT,      "License invalid for this MT5 account.");
    ObjectSetInteger(0, l2, OBJPROP_COLOR,     C'230,200,200');
    ObjectSetInteger(0, l2, OBJPROP_FONTSIZE,  14);
    ObjectSetString (0, l2, OBJPROP_FONT,      "Arial");
    ObjectSetInteger(0, l2, OBJPROP_SELECTABLE,false);
    ObjectSetInteger(0, l2, OBJPROP_HIDDEN,    true);

    string l3 = LIC_OverlayName("L3");
    if(ObjectFind(0, l3) < 0) ObjectCreate(0, l3, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, l3, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
    ObjectSetInteger(0, l3, OBJPROP_XDISTANCE, cx);
    ObjectSetInteger(0, l3, OBJPROP_YDISTANCE, cy + 24);
    ObjectSetInteger(0, l3, OBJPROP_ANCHOR,    ANCHOR_CENTER);
    ObjectSetString (0, l3, OBJPROP_TEXT,      "Bind your account at dachi-trader.com or contact support (wa.me/6287855684222).");
    ObjectSetInteger(0, l3, OBJPROP_COLOR,     C'200,180,180');
    ObjectSetInteger(0, l3, OBJPROP_FONTSIZE,  11);
    ObjectSetString (0, l3, OBJPROP_FONT,      "Arial");
    ObjectSetInteger(0, l3, OBJPROP_SELECTABLE,false);
    ObjectSetInteger(0, l3, OBJPROP_HIDDEN,    true);

    ChartRedraw(0);
}

// True if the EA is currently running inside MT5's Strategy Tester or
// Optimizer. Both environments are sandboxed and do NOT support
// WebRequest, so we skip the network license check entirely there.
bool LIC_InTester(){
    return MQLInfoInteger(MQL_TESTER) == 1
        || MQLInfoInteger(MQL_OPTIMIZATION) == 1
        || MQLInfoInteger(MQL_VISUAL_MODE) == 1;
}

// Whether the per-tick code paths should bail out and let the overlay take
// the chart. Disabled-license (InpLicense_Enabled=false) opts out — used by
// devs / backtests that don't want to talk to the license server at all.
bool LicenseIsBlocking(){
    if(LIC_InTester()) return false;
    return InpLicense_Enabled && !g_license_valid;
}

// Public entry — called from OnInit and OnTimer.
void CheckLicence(){
    // Strategy Tester / Optimizer cannot reach the network — skip the
    // verify call so the log isn't spammed with WebRequest errors and
    // the overlay never appears in backtest mode.
    if(LIC_InTester()){
        g_license_valid       = true;
        g_license_grace_mode  = false;
        g_license_state_label = "TESTER";
        return;
    }
    if(LIC_VerifyOnce()){ LIC_UpdateLabel(); return; }

    // v13.5.0: when the server returned a signed valid=false (explicit
    // deny — subscription terminated, expired, or account not bound),
    // we MUST NOT fall back to the offline grace cache. Grace is only
    // for "couldn't reach the server" scenarios.
    if(g_license_explicit_deny){
        LIC_UpdateLabel();
        return;
    }

    // Verify failed without an authoritative deny → try grace cache.
    datetime cached_exp=0, cached_ver=0;
    if(LIC_LoadCache(cached_exp, cached_ver)){
        long age = (long)(TimeCurrent() - cached_ver);
        if(age <= (long)InpLicense_GraceDays*86400){
            g_license_valid       = true;
            g_license_expires_at  = cached_exp;
            g_license_last_ok     = cached_ver;
            g_license_grace_mode  = true;
            Print("[LIC] GRACE mode — using cached verify from ",
                  TimeToString(cached_ver, TIME_DATE|TIME_MINUTES));
            LIC_UpdateLabel();
            return;
        }
    }
    g_license_valid = false;
    LIC_UpdateLabel();
}


// === HELPERS ===
string ObjName(string s){return OBJ_PREFIX+s;}

void EnsureDashboardButton(){
    string btn=ObjName("DASH_BTN");
    if(ObjectFind(0,btn)<0) ObjectCreate(0,btn,OBJ_BUTTON,0,0,0);
    ObjectSetInteger(0,btn,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(0,btn,OBJPROP_XDISTANCE,90);ObjectSetInteger(0,btn,OBJPROP_YDISTANCE,24);
    ObjectSetInteger(0,btn,OBJPROP_XSIZE,75);ObjectSetInteger(0,btn,OBJPROP_YSIZE,22);
    ObjectSetString(0,btn,OBJPROP_TEXT,g_dash_visible?"HIDE":"SHOW");ObjectSetInteger(0,btn,OBJPROP_COLOR,clrWhite);
    ObjectSetInteger(0,btn,OBJPROP_BGCOLOR,g_dash_visible?C'40,50,70':C'70,30,30');ObjectSetInteger(0,btn,OBJPROP_BORDER_COLOR,C'80,100,140');
    ObjectSetString(0,btn,OBJPROP_FONT,"Arial");ObjectSetInteger(0,btn,OBJPROP_FONTSIZE,8);
    ObjectSetInteger(0,btn,OBJPROP_BACK,false);ObjectSetInteger(0,btn,OBJPROP_ZORDER,1000);
    ObjectSetInteger(0,btn,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,btn,OBJPROP_HIDDEN,false);ObjectSetInteger(0,btn,OBJPROP_STATE,false);
}
double CalcLot(){
    double base = InpAutoLot
                  ? (AccountInfoDouble(ACCOUNT_BALANCE)/InpAutoLotDivider)/10.0
                  : InpManualLot;
    // v13.11.1 — apply regime lot scale (EARLY_BREAKOUT = 0.5x by default).
    // Dormant in v13.10.0/v13.11.0 — the global was set but never read by
    // lot calc, so EARLY_BR's reduced-lot rule never took effect.
    if(InpRegime_Enable && g_regime_lot_scale > 0 && g_regime_lot_scale != 1.0)
        base *= g_regime_lot_scale;
    double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN), mx=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
    double vstep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
    base=MathMax(mn,MathMin(mx,base));
    base=MathFloor(base/vstep)*vstep;
    return NormalizeDouble(base,2);
}
string GetCandleTimer(){int ps=PeriodSeconds();if(ps<=0)return"--:--";int r=ps-(int)(TimeCurrent()-iTime(_Symbol,_Period,0));if(r<0)r=0;return StringFormat("%02d:%02d",r/60,r%60);}
double NormalizeLot(double lot){double st=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);lot=MathFloor(lot/st)*st;if(lot<mn)lot=mn;return NormalizeDouble(lot,2);}
double GetPositionVolume(){for(int i=PositionsTotal()-1;i>=0;i--)if(PositionGetTicket(i)>0&&PositionGetInteger(POSITION_MAGIC)==InpEAMagic&&PositionGetString(POSITION_SYMBOL)==_Symbol)return PositionGetDouble(POSITION_VOLUME);return 0.0;}
double GetPositionProfit(){for(int i=PositionsTotal()-1;i>=0;i--)if(PositionGetTicket(i)>0&&PositionGetInteger(POSITION_MAGIC)==InpEAMagic&&PositionGetString(POSITION_SYMBOL)==_Symbol)return PositionGetDouble(POSITION_PROFIT);return 0.0;}
bool RuntimeDirMatchesPosition(){int actual=GetActivePositionDir();return (actual!=0&&actual==g_last_signal);}
bool CanRunSmartTPPartial(){return (RuntimeDirMatchesPosition()&&GetPositionProfit()>0.0);}

bool UseBrokerStopLoss(){
    return (InpSL_HardlineTrigger==EXIT_ON_TOUCH&&(InpUseSL||g_sl_forced)&&g_sl_price>0);
}

double BrokerStopLossPrice(){
    if(!UseBrokerStopLoss())return 0.0;
    return NormalizeDouble(g_sl_price,_Digits);
}

bool ApplyBrokerStopLoss(string reason){
    if(InpIndicatorOnly||!UseBrokerStopLoss())return false;
    double sl=BrokerStopLossPrice();
    if(sl<=0)return false;
    bool applied=false;
    for(int i=PositionsTotal()-1;i>=0;i--){
        ulong tk=PositionGetTicket(i);if(tk<=0)continue;
        if(PositionGetInteger(POSITION_MAGIC)!=InpEAMagic)continue;
        if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue;
        double cur_sl=PositionGetDouble(POSITION_SL);
        if(MathAbs(cur_sl-sl)<=_Point*0.5){applied=true;continue;}
        MqlTradeRequest r={};MqlTradeResult rs={};
        r.action=TRADE_ACTION_SLTP;r.position=tk;r.symbol=_Symbol;r.sl=sl;
        r.tp=PositionGetDouble(POSITION_TP);r.magic=InpEAMagic;r.comment="DT13 "+reason;
        if(OrderSend(r,rs)&&(rs.retcode==TRADE_RETCODE_DONE||rs.retcode==TRADE_RETCODE_PLACED)){
            Print("[BROKER-SL] ",reason," set SL=",DoubleToString(sl,_Digits)," ticket=",tk);
            applied=true;
        }else{
            Print("[BROKER-SL] ",reason," failed SL=",DoubleToString(sl,_Digits)," ticket=",tk," err=",GetLastError()," retcode=",rs.retcode);
        }
    }
    return applied;
}

void ClearVisualTradeState(){
    g_visual_signal=0;g_visual_entry=0;g_visual_sl=0;g_visual_atr=0;g_visual_tp_unlocked=5;
    for(int i=0;i<MAX_TP;i++){g_visual_tp[i]=0;g_visual_tp_hit[i]=false;}
}

void ResetRuntimeTradeState(bool clear_visual=true){
    g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;g_soft_mode=false;
    g_entry_price=0;g_entry_atr=0;g_sl_price=0;g_sl_initial_dist=0;g_last_entry=0;g_closed_lot_total=0;
    g_tp_unlocked=5;g_peak_price=0;g_peak_bar=0;g_stp1_phase=0;g_stp2_phase=0;g_stp3_armed=false;
    for(int i=0;i<MAX_TP;i++)g_tp_hit[i]=false;
    g_pe_bep_armed=false;g_pe_entry_time=0;  // v13.9.4 + v13.9.5
    if(clear_visual)ClearVisualTradeState();
}

void SyncVisualFromRuntime(){
    if(g_last_signal==0||g_entry_price<=0||g_entry_atr<=0)return;
    g_visual_signal=g_last_signal;g_visual_entry=g_entry_price;g_visual_sl=g_sl_price;
    g_visual_atr=g_entry_atr;g_visual_tp_unlocked=g_tp_unlocked;
    for(int i=0;i<MAX_TP;i++){g_visual_tp[i]=g_tp[i];g_visual_tp_hit[i]=g_tp_hit[i];}
}

void BuildFallbackTradeFromPosition(int dir){
    if(dir==0)return;
    double open_price=0;
    for(int i=PositionsTotal()-1;i>=0;i--){
        ulong tk=PositionGetTicket(i);if(tk<=0)continue;
        if(PositionGetInteger(POSITION_MAGIC)!=InpEAMagic)continue;
        if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue;
        open_price=PositionGetDouble(POSITION_PRICE_OPEN);g_initial_lot=PositionGetDouble(POSITION_VOLUME);g_closed_lot_total=0;break;
    }
    if(open_price<=0)return;
    double atr=(g_atr_val>0)?g_atr_val:SymbolInfoDouble(_Symbol,SYMBOL_POINT)*100.0;
    g_last_signal=dir;g_entry_price=open_price;g_entry_atr=atr;g_last_entry=open_price;
    double risk=atr*(g_soft_mode?InpSoft_SL_Mult:InpSL_Mult);
    g_sl_price=(dir==1)?open_price-risk:open_price+risk;g_sl_initial_dist=risk;
    double tp1_d=atr*(g_soft_mode?InpSoft_TP1_Mult:InpTP1_Mult);
    double tp2_d=tp1_d+atr*(g_soft_mode?InpSoft_TP2_Mult:InpTP1_to_TP2_Mult);
    g_tp[0]=(dir==1)?open_price+tp1_d:open_price-tp1_d;
    g_tp[1]=(dir==1)?open_price+tp2_d:open_price-tp2_d;
    for(int t=2;t<MAX_TP;t++){double sd=(t-1)*atr*InpTP_Step_Mult;g_tp[t]=(dir==1)?g_tp[1]+sd:g_tp[1]-sd;}
    for(int t=0;t<MAX_TP;t++)g_tp_hit[t]=false;
    g_tp_unlocked=5;g_entry_bar=g_current_bar;g_bars_in_trade=0;g_peak_price=open_price;g_peak_bar=g_current_bar;
    SyncVisualFromRuntime();
    Print("[POSITION-SYNC] rebuilt TP/SL from server ",(dir==1?"BUY":"SELL")," open=",DoubleToString(open_price,_Digits));
}

// === POSITION TRUTH HELPERS (v12.11.5 — unchanged) ===
int GetActivePositionDir(){
    for(int i=PositionsTotal()-1;i>=0;i--){
        ulong tk=PositionGetTicket(i); if(tk<=0)continue;
        if(PositionGetInteger(POSITION_MAGIC)!=InpEAMagic)continue;
        if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue;
        return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)?1:-1;
    }
    return 0;
}
bool HasActivePosition(){return GetActivePositionDir()!=0;}

void ReconcilePositionState(){
    int actual=GetActivePositionDir();
    if(actual==0&&g_last_signal!=0){
        Print("[POSITION-SYNC] flag=",(g_last_signal==1?"BUY":"SELL")," but no server position. Resetting.");
        ResetRuntimeTradeState(true);
    } else if(actual!=0&&g_last_signal==0){
        BuildFallbackTradeFromPosition(actual);
        ApplyBrokerStopLoss("SYNC");
    } else if(actual!=0&&g_last_signal!=0&&actual!=g_last_signal){
        Print("[POSITION-SYNC] CRITICAL mismatch. Trusting server and rebuilding lines.");
        BuildFallbackTradeFromPosition(actual);
        ApplyBrokerStopLoss("SYNC");
    } else if(actual!=0&&g_last_signal!=0){
        ApplyBrokerStopLoss("SYNC");
    }
}

// === OnInit ===
int OnInit(){
    g_history_done=false;g_last_signal=0;g_last_signal_bar=0;g_last_entry=0;g_entry_price=0;
    g_sl_price=0;g_sl_initial_dist=0;g_entry_atr=0;g_initial_lot=0;g_closed_lot_total=0;g_tp_unlocked=5;
    g_last_bar_time=0;g_current_bar=0;g_ea_ticket=0;g_entry_bar=0;g_bars_in_trade=0;g_consec_loss=0;
    g_dashboard_dirty=true;g_vline_visual_initialized=false;g_awaiting_reentry=false;g_reentry_dir=0;g_reentry_reason="";
    g_sl_forced=false;g_ssl_phase=0;g_soft_mode=false;g_visual_signal=0;g_visual_entry=0;
    g_visual_sl=0;g_visual_atr=0;g_visual_tp_unlocked=5;g_peak_price=0;g_peak_bar=0;
    g_retest_armed=false;g_retest_dir=0;g_retest_counter=0;g_retest_seen_pullback=false;
    g_pipe_hard=false;g_pipe_soft=false;g_last_decision="---";
    g_last_signal_gap_pts=0;g_slowma_angle_deg=0.0;g_slowma_angle_block=false;g_slowma_angle_state="OFF";
    g_eci_score=0.0;g_eci_direction_balance=0.0;g_eci_body_dominance=0.0;g_eci_trig=false;g_eci_state="OFF";
    g_f3_armed=false;g_f3_dir=0;g_f3_counter=0;g_f3_break_high=0;g_f3_break_low=0;g_f3_time=0;g_f3_reason="---";
    g_f3_fire_time=0;g_f3_fire_cross_px=0;g_f3_fire_atr=0;g_f3_fire_dir=0;
    g_pe_bep_armed=false;g_pe_entry_time=0;
    g_wick_bad_sweep=false;g_wick_good_sweep=false;g_wick_reason="OK";g_wick_ratio=0;
    g_f3_cooldown_bars=0;g_last_entry_was_f3=false;g_f3_fire_count=0;g_f3_loss_count=0;
    // v13.10.0 Market Regime state
    g_regime=REG_UNKNOWN;g_regime_reason="---";g_regime_atr_fast=0;g_regime_atr_slow=0;
    g_regime_er=0;g_regime_ema20=0;g_regime_ema50=0;g_regime_ma_gap=0;
    g_regime_range=0;g_regime_pricepos=0.5;g_regime_cross_count=0;
    g_regime_lot_scale=1.0;g_regime_block=false;
    ArrayInitialize(g_tp,0);ArrayInitialize(g_tp_hit,false);
    ArrayInitialize(g_visual_tp,0);ArrayInitialize(g_visual_tp_hit,false);
    ResetSmartTPState();

    // v13.9.3 — compare filter signature to stored hash; if changed, wipe
    // historical signal labels so ScanHistory can redraw them against the
    // new filter state. First load on a chart will also clear in case any
    // stale objects remain from a previous run.
    {
        uint   cur_h = ComputeFilterHash();
        string gv    = FilterHashGVKey();
        uint   prev_h = 0;
        if(GlobalVariableCheck(gv)) prev_h = (uint)GlobalVariableGet(gv);

        // v13.9.10 — track the previous _Period seen on this chart so a TF
        // switch (M5 → M15) clears stale timestamp-anchored labels even when
        // the filter hash is unchanged.
        string tf_gv = LastChartTFGVKey();
        int    prev_tf = 0;
        if(GlobalVariableCheck(tf_gv)) prev_tf = (int)GlobalVariableGet(tf_gv);
        int    cur_tf = (int)_Period;
        bool   tf_changed = (prev_tf != 0 && prev_tf != cur_tf);

        if(prev_h != cur_h || tf_changed){
            CleanupHistoricalSignalLabels();
            GlobalVariableSet(gv, (double)cur_h);
            if(prev_h != cur_h)
                Print("[INIT] Filter hash ", prev_h, " → ", cur_h, " — historical signals will be re-scanned.");
            if(tf_changed)
                Print("[INIT] Chart TF ", prev_tf, " → ", cur_tf, " — cleared stale labels from previous timeframe.");
        }
        // Always update the per-chart TF tracker, even on first attach where
        // no cleanup is needed (prev_tf == 0).
        GlobalVariableSet(tf_gv, (double)cur_tf);
    }

    h_ema_fast=iMA(_Symbol,_Period,InpEMA_Fast,0,MODE_EMA,PRICE_CLOSE);
    h_sma_slow=iMA(_Symbol,_Period,InpSMA_Slow,0,InpSlowMA_Method,PRICE_CLOSE);
    h_atr=iATR(_Symbol,_Period,InpATR_Period);
    if(h_ema_fast==INVALID_HANDLE||h_sma_slow==INVALID_HANDLE||h_atr==INVALID_HANDLE){Print("[ERROR] Core handle fail");return INIT_FAILED;}

    // ADX handle — shared by F1 (DI±) and Market Regime detector.
    if(InpF1_Action!=F_OFF || InpRegime_Enable){
        h_adx=iADX(_Symbol,_Period,14);
        if(h_adx==INVALID_HANDLE){Print("[ERROR] ADX handle fail");return INIT_FAILED;}
    }
    // F5 RVI (was F15) — standalone OB/OS filter
    if(InpF5_Action!=F_OFF){
        h_f5_rvi=iRVI(_Symbol,InpF5_TF,InpF5_Period);
        if(h_f5_rvi==INVALID_HANDLE){Print("[ERROR] F5 RVI handle fail");return INIT_FAILED;}
    }
    // Intelligent Filter — EMA20/50 trend gate + exhaustion (RVI + Stoch)
    if(InpIF_Enable){
        ENUM_TIMEFRAMES iftf = (InpIF_TF == PERIOD_CURRENT) ? _Period : InpIF_TF;
        h_if_ema20 = iMA(_Symbol, iftf, 20, 0, MODE_EMA, PRICE_CLOSE);
        h_if_ema50 = iMA(_Symbol, iftf, 50, 0, MODE_EMA, PRICE_CLOSE);
        if(h_if_ema20==INVALID_HANDLE || h_if_ema50==INVALID_HANDLE){
            Print("[ERROR] Intelligent Filter EMA handles fail"); return INIT_FAILED;
        }
        if(InpIF_UseExhaustion){
            h_if_rvi   = iRVI(_Symbol, iftf, 10);
            h_if_stoch = iStochastic(_Symbol, iftf, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
            if(h_if_rvi==INVALID_HANDLE || h_if_stoch==INVALID_HANDLE){
                Print("[ERROR] Intelligent Filter exhaustion handles fail"); return INIT_FAILED;
            }
        }
    }
    // v13.10.0 Market Regime / ATR Health — ATR fast/slow + EMA20/EMA50 (separate handles)
    if(InpRegime_Enable || InpUseATRHealthGuard){
        h_atr_fast = iATR(_Symbol,_Period,InpRegime_ATRFastPeriod);
        h_atr_slow = iATR(_Symbol,_Period,InpRegime_ATRSlowPeriod);
        if(h_atr_fast==INVALID_HANDLE||h_atr_slow==INVALID_HANDLE){
            Print("[ERROR] ATR fast/slow handles fail");return INIT_FAILED;
        }
    }
    if(InpRegime_Enable){
        h_regime_ema_fast = iMA(_Symbol,_Period,InpRegime_EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
        h_regime_ema_slow = iMA(_Symbol,_Period,InpRegime_EMA_Slow,0,MODE_EMA,PRICE_CLOSE);
        if(h_regime_ema_fast==INVALID_HANDLE||h_regime_ema_slow==INVALID_HANDLE){
            Print("[ERROR] Regime EMA handles fail");return INIT_FAILED;
        }
    }
    CheckLicence();EventSetMillisecondTimer(500);

    EnsureDashboardButton();

    ChartSetInteger(0,CHART_COLOR_BACKGROUND,C'0,0,0');ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrWhite);
    ChartSetInteger(0,CHART_COLOR_CHART_UP,C'38,166,154');ChartSetInteger(0,CHART_COLOR_CHART_DOWN,C'239,83,80');
    ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,C'38,166,154');ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,C'239,83,80');
    ChartSetInteger(0,CHART_SHOW_GRID,false);ChartSetInteger(0,CHART_MODE,CHART_CANDLES);

    Print("==============================================================");
    Print("[INIT] Dachi Trader v13.11.33 | ",_Symbol," ",EnumToString(_Period),
          " | Mode=",(InpIndicatorOnly?"INDICATOR":"EA ACTIVE"));
    string slmm=(InpSlowMA_Method==MODE_EMA?"EMA":InpSlowMA_Method==MODE_SMMA?"SMMA":InpSlowMA_Method==MODE_LWMA?"LWMA":"SMA");
    Print("[INIT] Core: EMA",InpEMA_Fast,"/",slmm,InpSMA_Slow," | ATR",InpATR_Period);
    Print("[INIT] Filters: F0=",EnumToString(InpGap_Action)," F1=",EnumToString(InpF1_Action),
          " F2=",EnumToString(InpF2_Action)," F3=",(InpF3_UseRecovery?"ON":"OFF"),
          " F4=",EnumToString(InpF4_Action)," F5=",EnumToString(InpF5_Action));
    Print("[INIT] IF=",(InpIF_Enable?"ON":"OFF"),
          " | Wick=",(InpWick_UseFilter?"ON":"OFF"),
          " | Regime=",(InpRegime_Enable?"ON":"OFF"));
    Print("[INIT] TP1=",InpTP1_Mult,"x | TP2=TP1+",InpTP1_to_TP2_Mult,"x",
          " | ManualTP=",(UseManualTPTarget()?("TP"+IntegerToString(InpManualTP_Target)+(InpManualTP_UsePartialSystem?"+partials":" full")):"OFF"),
          " | SmartTP=",(UseSmartTP()?"ON":"OFF"));
    Print("[INIT] F3 (recovery): cooldown=",IntegerToString(InpF3_CooldownBars),"b",
          " maxDistATR=",DoubleToString(InpF3_MaxDistATR,2),
          " refire=",(InpF3_AllowRefire?"ON":"OFF"));
    Print("[INIT] NOTE: Reset EA inputs in dialog if any value differs from expected default.");
    Print("==============================================================");

    // License gate: if invalid at startup, show the overlay + popup Alert.
    // Subsequent OnTick early-returns will keep the chart locked behind it.
    if(LicenseIsBlocking()){
        LIC_NukeAllOtherObjects();
        LIC_DrawUnauthorizedOverlay();
        if(!g_lic_alert_shown){
            Alert("Dachi Trader: Unauthorized account. EA disabled. Bind your account at dachi-trader.com.");
            g_lic_alert_shown = true;
        }
        g_lic_was_valid = false;
    } else {
        g_lic_was_valid = true;
    }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason){
    EventKillTimer();
    // Always cleanup, not only REASON_REMOVE. Parameter/template/timeframe reloads
    // immediately recreate the needed objects in OnInit/OnTick, while remove and
    // chart-close must leave the chart completely clean.
    int deleted=CleanupAllEAObjects();
    if(h_ema_fast!=INVALID_HANDLE)IndicatorRelease(h_ema_fast);
    if(h_sma_slow!=INVALID_HANDLE)IndicatorRelease(h_sma_slow);
    if(h_atr!=INVALID_HANDLE)IndicatorRelease(h_atr);
    if(h_adx!=INVALID_HANDLE)IndicatorRelease(h_adx);
    if(h_f5_rvi!=INVALID_HANDLE)IndicatorRelease(h_f5_rvi);
    if(h_if_ema20!=INVALID_HANDLE)IndicatorRelease(h_if_ema20);
    if(h_if_ema50!=INVALID_HANDLE)IndicatorRelease(h_if_ema50);
    if(h_if_rvi  !=INVALID_HANDLE)IndicatorRelease(h_if_rvi);
    if(h_if_stoch!=INVALID_HANDLE)IndicatorRelease(h_if_stoch);
    if(h_atr_fast!=INVALID_HANDLE)IndicatorRelease(h_atr_fast);
    if(h_atr_slow!=INVALID_HANDLE)IndicatorRelease(h_atr_slow);
    if(h_regime_ema_fast!=INVALID_HANDLE)IndicatorRelease(h_regime_ema_fast);
    if(h_regime_ema_slow!=INVALID_HANDLE)IndicatorRelease(h_regime_ema_slow);
    deleted+=CleanupAllEAObjects();
    ChartRedraw();
    Print("[DEINIT] Dachi v13.11.33 removed reason=",reason," cleanup_deleted=",deleted);
}

void OnTimer(){
    if(!g_history_done){
        if(Bars(_Symbol,_Period)>InpSMA_Slow+50){
            g_history_done=true;g_current_bar=Bars(_Symbol,_Period);
            ReadIndicators();DrawEMARibbon();DrawEvasiveSTVisual();ScanHistory();
            if(!InpIndicatorOnly)ReconcilePositionState();
            if(UseLateEntry()&&g_last_signal!=0&&HasActivePosition())CheckLateEntry();
            DrawTPSLLines();DrawDashboard(true);ChartRedraw();
        }
    }
    // Periodic license re-check. InpLicense_RecheckMin=0 disables.
    if(InpLicense_Enabled && InpLicense_RecheckMin > 0){
        long recheck_secs = (long)InpLicense_RecheckMin * 60;
        if(TimeCurrent() - g_license_last_check >= recheck_secs){
            CheckLicence();
            // Transition handling: if license just flipped from valid → invalid
            // since the last timer fire, surface a fresh Alert + draw the
            // overlay so a mid-day expiry doesn't silently blank the chart.
            if(g_lic_was_valid && LicenseIsBlocking()){
                LIC_DrawUnauthorizedOverlay();
                Alert("Dachi Trader: License revoked / expired. EA disabled.");
                g_lic_was_valid = false;
            }
            // Reverse transition (admin re-enabled the user, EA recovers).
            if(!g_lic_was_valid && !LicenseIsBlocking()){
                LIC_ClearOverlay();
                g_lic_was_valid = true;
                g_lic_alert_shown = false;
                Print("[LIC] License restored — UI unlocked.");
            }
        }
    }
    if(LicenseIsBlocking()){
        LIC_NukeAllOtherObjects();
        LIC_DrawUnauthorizedOverlay();
        return;
    }
    DrawDashboard(false);ChartRedraw();
}

// === READ INDICATORS ===
bool ReadIndicators(){
    double b[2];
    if(CopyBuffer(h_ema_fast,0,1,1,b)<=0)return false;g_ema_fast=b[0];
    if(CopyBuffer(h_sma_slow,0,1,1,b)<=0)return false;g_sma_slow=b[0];
    if(CopyBuffer(h_atr,0,1,1,b)<=0)return false;g_atr_val=b[0];
    double b0[1];
    if(CopyBuffer(h_ema_fast,0,0,1,b0)>0)g_ema_fast_b0=b0[0];
    if(CopyBuffer(h_sma_slow,0,0,1,b0)>0)g_sma_slow_b0=b0[0];
    // Cache live filter readouts for dashboard
    if(h_adx!=INVALID_HANDLE){
        double dp[1],dm[1];
        if(CopyBuffer(h_adx,1,1,1,dp)>0)g_f1_dip=dp[0];
        if(CopyBuffer(h_adx,2,1,1,dm)>0)g_f1_dim=dm[0];
    }
    return true;
}


// =============================================================================
// === v13.9.3 — FILTER SIGNATURE + LABEL CLEANUP ===
// =============================================================================
// Detects when any setting that affects signal classification has changed
// since the last EA load (parameter dialog edit, attach to new chart, etc.)
// so historical signal labels can be cleared and re-drawn against the new
// filter state. Without this, v13.7.3's "do not repaint a BLOCKED label"
// rule causes stale BLOCKED labels to linger on chart after the user
// disables the filter that produced them, hiding the EA's true state.

uint ComputeFilterHash(){
    uint h = 2166136261;  // FNV-1a seed
    // Clean-core signature only
    h = (h ^ (uint)InpEMA_Fast)            * 16777619;
    h = (h ^ (uint)InpSMA_Slow)            * 16777619;
    h = (h ^ (uint)InpSlowMA_Method)       * 16777619;
    h = (h ^ (uint)(InpUseSlowMAAngleGuard?1:0)) * 16777619;
    h = (h ^ (uint)(int)(InpSlowMA_MinAngleDeg*100)) * 16777619;
    h = (h ^ (uint)InpECI_Action)          * 16777619;
    h = (h ^ (uint)InpECI_Lookback)        * 16777619;
    h = (h ^ (uint)(int)(InpECI_ChopThreshold*100)) * 16777619;
    h = (h ^ (uint)(int)(InpECI_MixedThreshold*100)) * 16777619;
    h = (h ^ (uint)(int)(InpECI_DirectionalBalanceMax*100)) * 16777619;
    h = (h ^ (uint)(int)(InpECI_BodyDominanceMax*100)) * 16777619;
    h = (h ^ (uint)InpF2_Action)           * 16777619;
    h = (h ^ (uint)(int)(InpF2_MaxDistATR*100))  * 16777619;

    h = (h ^ (uint)(InpUseH1Bias?1:0))           * 16777619;
    h = (h ^ (uint)(InpAllowNeutralBias?1:0))    * 16777619;
    h = (h ^ (uint)(InpUseM15Setup?1:0))         * 16777619;
    h = (h ^ (uint)(InpAllowM15Neutral?1:0))     * 16777619;
    h = (h ^ (uint)InpStartupScanBars)        * 16777619;
    h = (h ^ (uint)InpVisualLazyBars)          * 16777619;
    h = (h ^ (uint)(InpShowCoreMALines?1:0)) * 16777619;
    h = (h ^ (uint)(InpShowTPSLEntryLines?1:0)) * 16777619;
    h = (h ^ (uint)(InpShowBlockedSignals?1:0)) * 16777619;
    h = (h ^ (uint)(InpHTF_AllowReversalOverride?1:0)) * 16777619;
    h = (h ^ (uint)(int)(InpHTF_ReversalBodyATRMin*100)) * 16777619;
    h = (h ^ (uint)(InpUseVLineGuard?1:0)) * 16777619;
    h = (h ^ (uint)InpVLine_TF) * 16777619;
    h = (h ^ (uint)InpVLine_ATRLength) * 16777619;
    h = (h ^ (uint)(int)(InpVLine_BaseMultiplier*100)) * 16777619;
    h = (h ^ (uint)(int)(InpVLine_NoiseThresholdATR*100)) * 16777619;
    h = (h ^ (uint)(int)(InpVLine_ExpansionAlphaATR*100)) * 16777619;
    h = (h ^ (uint)(InpVLine_BlockNeutral?1:0)) * 16777619;
    h = (h ^ (uint)(InpUseSidewayGuard?1:0)) * 16777619;
    h = (h ^ (uint)(int)(InpSideway_MinEMASlopePts*100)) * 16777619;
    h = (h ^ (uint)InpSideway_CrossLookback) * 16777619;
    h = (h ^ (uint)InpSideway_MaxCrosses) * 16777619;
    h = (h ^ (uint)(int)(InpSideway_MinMAGapATR*100)) * 16777619;
    h = (h ^ (uint)(InpUseATRHealthGuard?1:0)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_M5_MinTrade*100)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_M5_MaxNormal*100)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_M5_MaxAllowed*100)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_M5_BlockAbove*100)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_FastRatioLimited*100)) * 16777619;
    h = (h ^ (uint)(int)(InpATR_FastRatioBlock*100)) * 16777619;
    h = (h ^ (uint)(InpUseSqueezeGuard?1:0)) * 16777619;
    h = (h ^ (uint)InpSQ_Lookback) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_RangeATRMax*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_ATRCompressionMax*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_MAGapATRMax*100)) * 16777619;
    h = (h ^ (uint)InpSQ_CrossDensityLookback) * 16777619;
    h = (h ^ (uint)InpSQ_CrossDensityMin) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_BreakoutBufferATR*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_MinBodyRatio*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_BuyCloseLocMin*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_SellCloseLocMax*100)) * 16777619;
    h = (h ^ (uint)(int)(InpSQ_SpikeRatioBlock*100)) * 16777619;

    h = (h ^ (uint)0x13C00330)             * 16777619;   // logic version marker
    return h;
}

string FilterHashGVKey(){
    return OBJ_PREFIX + "FILT_HASH_" + _Symbol + "_" + IntegerToString((int)_Period);
}

// v13.9.10 — per-chart record of the last _Period the EA initialised under,
// so a TF switch on the SAME chart can be detected and stale timestamp-
// anchored labels cleared. ChartID() is the live chart identifier and is
// unique within a session; that's all we need for in-session TF switches
// which is the scenario this guards against. Across MT5 restarts the ID
// may differ, but the cached value just won't match and cleanup runs once.
string LastChartTFGVKey(){
    return OBJ_PREFIX + "LAST_TF_" + IntegerToString(ChartID());
}

// Deletes only the visual artifacts produced by signal classification:
//   SIG_B_*,  SIG_S_*  — BUY/SELL/BLOCKED/LIMITED text labels
//   SIGBK_*            — black inner candle-background highlight rectangle
//   SIGBAR_*           — green/red 3px outline rectangle around signal candle
//   F11M_*             — F11 recovery markers (text)
//   F11LINE_*          — dotted Entry/SL/TP trend lines at F11 recoveries
//   F11VLINE_*         — orange vertical line at F11 recovery bar (v13.9.16)
//   DIAG_*             — gray DrawDiagMarker spread/session/daily skip markers
//   DR_*               — legacy dashboard-row prefix (regenerated each tick;
//                        kept for backward compat with any older charts)
// Dashboard panel (DB_*), panel button (DASH_BTN), license overlay
// (LIC_OVERLAY_*), TP/SL lines, EMA ribbon, and exit markers are NOT touched.
void CleanupHistoricalSignalLabels(){
    int total = ObjectsTotal(0,0,-1);
    int deleted = 0;
    for(int i=total-1; i>=0; i--){
        string n = ObjectName(0,i,0,-1);
        if(StringFind(n, OBJ_PREFIX+"SIG_B_")    == 0
        || StringFind(n, OBJ_PREFIX+"SIG_S_")    == 0
        || StringFind(n, OBJ_PREFIX+"SIGBK_")    == 0
        || StringFind(n, OBJ_PREFIX+"SIGBAR_")   == 0
        || StringFind(n, OBJ_PREFIX+"F11M_")     == 0   // legacy v13.9.x cleanup
        || StringFind(n, OBJ_PREFIX+"F11LINE_")  == 0   // legacy v13.9.x cleanup
        || StringFind(n, OBJ_PREFIX+"F11VLINE_") == 0   // legacy v13.9.x cleanup
        || StringFind(n, OBJ_PREFIX+"F3LINE_")   == 0
        || StringFind(n, OBJ_PREFIX+"F3VLINE_")  == 0
        || StringFind(n, OBJ_PREFIX+"DIAG_")     == 0
        || StringFind(n, OBJ_PREFIX+"DR_")       == 0){
            ObjectDelete(0, n); deleted++;
        }
    }
    if(deleted>0) Print("[INIT] Filter settings changed — cleared ",deleted," stale signal labels.");
}

// =============================================================================
// === v13.9.0 — F10 PRESET RESOLVER ===
// =============================================================================
// Maps InpF10_Preset to the effective F10 tuning constants the evaluator
// actually reads. CUSTOM keeps the legacy input values; the other presets
// override them with curated profiles. Called once in OnInit.
// =============================================================================
// === v13.9.0 — WICK / LIQUIDITY SWEEP DETECTOR ===
// =============================================================================
// Analyses bar 'idx' relative to the previous InpWick_SweepLookback bars.
// Sets two globals:
//   g_wick_bad_sweep  = true when this bar's dominant wick aligns WITH the
//                       intended entry direction (BUY with upper-wick sweep
//                       into prior highs ⇒ entering at exhaustion top).
//   g_wick_good_sweep = true when this bar's dominant wick aligns AGAINST
//                       the signal direction and the close re-enters the
//                       prior range (a flush against opposition that
//                       traps shorts/longs and supports the signal).
// g_wick_ratio = max(upper_wick, lower_wick) / range, for the dashboard.
void DetectWickPattern(int sig, int idx){
    g_wick_bad_sweep=false; g_wick_good_sweep=false; g_wick_reason="OK"; g_wick_ratio=0;
    if(!InpWick_UseFilter) return;
    if(sig==0) return;
    double h=iHigh(_Symbol,_Period,idx);
    double l=iLow (_Symbol,_Period,idx);
    double o=iOpen(_Symbol,_Period,idx);
    double c=iClose(_Symbol,_Period,idx);
    double range=h-l;
    if(range<=0) return;
    int look=MathMax(2,InpWick_SweepLookback);
    double prev_high=iHigh(_Symbol,_Period,idx+1);
    double prev_low =iLow (_Symbol,_Period,idx+1);
    for(int k=2;k<=look;k++){
        double hh=iHigh(_Symbol,_Period,idx+k);
        double ll=iLow (_Symbol,_Period,idx+k);
        if(hh>prev_high) prev_high=hh;
        if(ll<prev_low ) prev_low =ll;
    }
    double top_body=MathMax(o,c);
    double bot_body=MathMin(o,c);
    double upper_wick=h-top_body;
    double lower_wick=bot_body-l;
    double dominant=MathMax(upper_wick,lower_wick);
    g_wick_ratio = dominant/range;
    bool wick_dominant = (g_wick_ratio >= InpWick_MinWickRatio);
    if(!wick_dominant){g_wick_reason="NO_WICK";return;}
    bool upper_dominant=(upper_wick>=lower_wick);
    if(sig==1){
        // BUY entering at the top of a wick sweep into prior highs = bad
        if(upper_dominant && h>prev_high && c<prev_high){
            g_wick_bad_sweep=true; g_wick_reason="BAD_SWEEP_UP"; return;
        }
        // BUY after a lower-wick flush that closed back inside = good
        if(!upper_dominant && l<prev_low && c>prev_low){
            g_wick_good_sweep=true; g_wick_reason="GOOD_FLUSH_DN"; return;
        }
    } else {
        if(!upper_dominant && l<prev_low && c>prev_low){
            g_wick_bad_sweep=true; g_wick_reason="BAD_SWEEP_DN"; return;
        }
        if(upper_dominant && h>prev_high && c<prev_high){
            g_wick_good_sweep=true; g_wick_reason="GOOD_FLUSH_UP"; return;
        }
    }
}

// Cross density helper for F3 anti-sideway: counts MA cross events in the
// last InpF3_CrossDensityLookback bars.
int F3CountRecentCrosses(){
    int look=MathMax(5,InpF3_CrossDensityLookback);
    int crosses=0;
    for(int k=1;k<=look;k++){
        if(DetectSignalAt(k)!=0) crosses++;
    }
    return crosses;
}


// === FILTER EVALUATORS ===

// F0: EMA Gap (look-ahead bar 0)
// F4: Slow MA Direction (was F14 pre-v13.10.0) — lightweight visual check.
// F2: Crossing-to-entry distance filter (was F9 pre-v13.10.0).
// Geometric cross via linear interpolation between bar idx and bar idx+1.

// Shared helper: linear-interp geometric cross price at bar idx
// (cross is between bar idx and bar idx+1 — see DetectSignal). Returns
// false when the MA buffers can't be read or both bars are on the same
// side (no cross between them). On true, out_cross_px is the price where
// the two MA lines meet, and out_atr is the ATR at bar idx (falls back to
// g_atr_val if the ATR buffer copy fails).
bool ComputeCrossPriceLI(int idx, double &out_cross_px, double &out_atr){
    double ef[], es[];
    ArraySetAsSeries(ef, true); ArraySetAsSeries(es, true);
    if(CopyBuffer(h_ema_fast, 0, idx, 2, ef) < 2) return false;
    if(CopyBuffer(h_sma_slow, 0, idx, 2, es) < 2) return false;
    double delta2 = ef[1] - es[1];   // older bar, pre-cross signed gap
    double delta1 = ef[0] - es[0];   // newer bar, post-cross signed gap
    double denom  = delta1 - delta2;
    if(MathAbs(denom) > _Point){
        double t = -delta2 / denom;
        if(t < 0.0) t = 0.0;
        if(t > 1.0) t = 1.0;
        out_cross_px = es[1] + t * (es[0] - es[1]);
    } else {
        out_cross_px = (ef[0]+es[0]+ef[1]+es[1]) / 4.0;
    }
    double ah[1];
    out_atr = 0.0;
    if(CopyBuffer(h_atr, 0, idx, 1, ah) > 0) out_atr = ah[0];
    if(out_atr <= 0) out_atr = g_atr_val;
    return (out_atr > 0);
}

bool EvalF2At(int idx){
    double cross_px, atr_use;
    if(!ComputeCrossPriceLI(idx, cross_px, atr_use)) return false;
    double entry_px = iClose(_Symbol,_Period,idx);
    double dist = MathAbs(entry_px - cross_px);
    return (dist > InpF2_MaxDistATR * atr_use);
}
bool EvalF2(){ return EvalF2At(1); }

bool CalcSlowMAVisualAngleAt(int idx, double &angle_deg){
    angle_deg=0.0;
    double es[]; ArraySetAsSeries(es,true);
    if(CopyBuffer(h_sma_slow,0,idx,2,es)<2) return false;

    datetime t_new=iTime(_Symbol,_Period,idx);
    datetime t_old=iTime(_Symbol,_Period,idx+1);
    if(t_new<=0 || t_old<=0 || t_new==t_old) return false;

    int x_old=0,y_old=0,x_new=0,y_new=0;
    bool ok_old=ChartTimePriceToXY(0,0,t_old,es[1],x_old,y_old);
    bool ok_new=ChartTimePriceToXY(0,0,t_new,es[0],x_new,y_new);
    if(ok_old && ok_new && x_new!=x_old){
        double dx=(double)(x_new-x_old);
        double dy=(double)(y_old-y_new); // screen Y grows downward; positive dy means visually rising
        angle_deg=MathArctan(dy/dx)*180.0/3.14159265358979323846;
        return true;
    }

    int visible=(int)ChartGetInteger(0,CHART_VISIBLE_BARS);
    int width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
    int height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
    double pmin=ChartGetDouble(0,CHART_PRICE_MIN,0);
    double pmax=ChartGetDouble(0,CHART_PRICE_MAX,0);
    if(visible<=0 || width<=0 || height<=0 || pmax<=pmin) return false;

    double dx=(double)width/(double)visible;
    double dy=(es[0]-es[1])/(pmax-pmin)*(double)height;
    if(dx<=0.0) return false;
    angle_deg=MathArctan(dy/dx)*180.0/3.14159265358979323846;
    return true;
}

bool SlowMAAngleBlocks(int sig, int idx){
    g_slowma_angle_block=false;
    g_slowma_angle_state=InpUseSlowMAAngleGuard?"ERR":"OFF";
    g_slowma_angle_deg=0.0;
    if(!InpUseSlowMAAngleGuard) return false;

    double angle=0.0;
    if(!CalcSlowMAVisualAngleAt(idx,angle)){
        g_slowma_angle_state="NO_DATA";
        return false;
    }

    g_slowma_angle_deg=angle;
    double th=MathMax(0.0,InpSlowMA_MinAngleDeg);
    bool block=(sig>0 ? (angle < th) : (angle > -th));
    g_slowma_angle_block=block;
    g_slowma_angle_state=DoubleToString(angle,1)+"°";
    return block;
}

// === F3 FALSE-BLOCK RECOVERY (was F11 pre-v13.10.0) ===
// Gates (in order): cooldown after losing F3 → cross density (anti-sideway) →
// wick sweep against signal → arming.
void ArmF3Recovery(int dir, datetime t, string reason){
    if(!InpF3_UseRecovery)return;
    if(InpF3_OnlyF0Blocks && !g_f0_trig)return;
    // F2 cross-distance blocks are real late-entry rejects, not false blocks.
    if(InpF3_BlockOnF2 && g_f2_trig){
        g_f3_reason = "F2_BLOCK";
        return;
    }
    if(InpF3_RecoveryBars<=0)return;
    // Cooldown after losing F3 trade; optional refire window bypass.
    if(g_f3_cooldown_bars>0){
        bool refire_ok = false;
        if(InpF3_AllowRefire && g_f3_fire_time > 0 && g_f3_fire_dir == dir
           && g_f3_fire_atr > 0){
            int bars_since = (int)((TimeCurrent() - g_f3_fire_time) / (long)PeriodSeconds());
            if(bars_since < InpF3_RefireMaxBars){
                double cur_px = (dir == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                           : SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double dist = MathAbs(cur_px - g_f3_fire_cross_px);
                if(dist < InpF3_RefireMaxDistATR * g_f3_fire_atr) refire_ok = true;
            }
        }
        if(!refire_ok){
            g_f3_reason=StringFormat("COOLDOWN(%d)",g_f3_cooldown_bars);
            return;
        }
        g_f3_cooldown_bars = 0;
        Print("[F3-REFIRE] bypass cooldown, bars_since=",
              (int)((TimeCurrent()-g_f3_fire_time)/(long)PeriodSeconds()));
    }
    // Anti-sideway cross density
    int crosses=F3CountRecentCrosses();
    if(crosses>InpF3_MaxCrossDensity){
        g_f3_reason=StringFormat("DENSITY(%d>%d)",crosses,InpF3_MaxCrossDensity);
        return;
    }
    // Wick sweep guard on blocked candle
    if(InpF3_BlockWickSweep){
        DetectWickPattern(dir,1);
        if(g_wick_bad_sweep){
            g_f3_reason=StringFormat("WICK_%s",g_wick_reason);
            return;
        }
    }
    int idx=iBarShift(_Symbol,_Period,t);
    if(idx<0)idx=1;
    double atr_use=g_atr_val;
    if(atr_use<=0){double ah[1];if(CopyBuffer(h_atr,0,idx,1,ah)>0)atr_use=ah[0];}
    if(atr_use<=0)return;
    g_f3_armed=true;g_f3_dir=dir;g_f3_counter=InpF3_RecoveryBars;g_f3_time=t;
    g_f3_break_high=iHigh(_Symbol,_Period,idx)+InpF3_BreakBufferATR*atr_use;
    g_f3_break_low =iLow (_Symbol,_Period,idx)-InpF3_BreakBufferATR*atr_use;
    g_f3_reason=reason;
    Print("[F3-ARM] ",(dir==1?"BUY":"SELL")," ",reason," high=",DoubleToString(g_f3_break_high,_Digits)," low=",DoubleToString(g_f3_break_low,_Digits)," bars=",g_f3_counter,
          " crosses=",crosses);
}

bool F3DIOk(int dir){
    if(!InpF3_RequireDIDirection)return true;
    if(h_adx==INVALID_HANDLE)return true;
    double dp[1],dm[1];
    if(CopyBuffer(h_adx,1,1,1,dp)<=0||CopyBuffer(h_adx,2,1,1,dm)<=0)return true;
    if(dir==1) return (dp[0] > dm[0]);
    return (dm[0] > dp[0]);
}

double CalcANDAt(int idx){
    int N=20;
    double cl[];ArraySetAsSeries(cl,true);
    if(CopyClose(_Symbol,_Period,idx,N,cl)<N)return 0.0;
    double sum=0;for(int i=0;i<N;i++)sum+=cl[i];
    double mean=sum/(double)N;double sq=0;
    for(int i=0;i<N;i++){double d=cl[i]-mean;sq+=d*d;}
    double sd=MathSqrt(sq/(double)N);
    double ah[1];double atr=0;
    if(CopyBuffer(h_atr,0,idx,1,ah)>0)atr=ah[0];
    return (atr>0)?sd/atr:0.0;
}

bool F3RangeOkAt(int idx){
    if(!InpF3_BlockChoppyRange)return true;
    double andv=CalcANDAt(idx);
    if(andv<=0)return true;
    return (andv<=InpF3_MaxChoppyAND);
}

void ProcessF3Recovery(bool new_bar){
    // Cooldown ticks down on every new bar even when F3 isn't armed.
    if(new_bar && g_f3_cooldown_bars>0) g_f3_cooldown_bars--;
    if(!InpF3_UseRecovery||!g_f3_armed||g_last_signal!=0)return;
    if(g_f3_counter<=0){g_f3_armed=false;g_f3_dir=0;g_f3_reason="EXPIRED";return;}
    if(new_bar)g_f3_counter--;
    int dir=g_f3_dir;
    if(InpF3_RequireMAAligned){
        bool aligned=(dir==1&&g_ema_fast>g_sma_slow)||(dir==-1&&g_ema_fast<g_sma_slow);
        if(!aligned){g_f3_armed=false;g_f3_reason="MA_CANCEL";Print("[F3-CANCEL] MA no longer aligned");return;}
    }
    if(!F3DIOk(dir)){g_f3_reason="DI_WAIT";return;}
    if(!F3RangeOkAt(1)){g_f3_reason="RANGE_WAIT";return;}
    // Wick sweep guard on the break candle
    if(InpF3_BlockWickSweep){
        DetectWickPattern(dir,1);
        if(g_wick_bad_sweep){g_f3_reason=StringFormat("WICK_%s",g_wick_reason);return;}
    }
    double trigger_px;
    if(InpF3_Trigger==EXIT_ON_TOUCH){
        trigger_px=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
    } else {
        if(!new_bar)return;
        trigger_px=iClose(_Symbol,_Period,1);
    }
    bool broke=(dir==1)?(trigger_px>=g_f3_break_high):(trigger_px<=g_f3_break_low);
    if(!broke)return;
    if(!PreCheckMarketConditions()){g_f3_reason="MKT_WAIT";return;}
    // Recovery price must stay within InpF3_MaxDistATR × ATR of the original cross_px.
    double f3_cross_px = 0, f3_cross_atr = 0;
    bool   f3_has_cross = ComputeCrossPriceLI(1, f3_cross_px, f3_cross_atr);
    if(f3_has_cross && InpF3_MaxDistATR > 0.0){
        if(MathAbs(trigger_px - f3_cross_px) > InpF3_MaxDistATR * f3_cross_atr){
            g_f3_reason = "DIST_FAR";
            return;
        }
    }
    Print("[F3-FIRE] ",(dir==1?"BUY":"SELL")," after false block ",g_f3_reason);
    SetupTrade(dir,InpF3_EnterAsSoft);
    EAOpen(dir);
    if(g_last_signal!=0){
        g_last_entry_was_f3 = true;
        g_f3_fire_count++;
        if(g_f3_fire_time == 0 || g_f3_fire_dir != dir){
            g_f3_fire_time     = TimeCurrent();
            g_f3_fire_cross_px = f3_has_cross ? f3_cross_px : trigger_px;
            g_f3_fire_atr      = (f3_cross_atr > 0) ? f3_cross_atr : g_atr_val;
            g_f3_fire_dir      = dir;
        }
        // Hide BLOCKED label at the original block bar; add the F3 visual at
        // recovery — orange "^/v F3 BUY/SELL" + vertical line scoped to the
        // recovery candle (matches the v13.9.16 spec carried into v13.10.0).
        datetime recovery_bar_time = iTime(_Symbol, _Period, 0);
        HideBlockedLabelForF3(dir, g_f3_time);
        DrawSignalLabel(dir,recovery_bar_time,trigger_px,SC_F3_RECOVERY);
        DrawF3RecoveryVLine(recovery_bar_time);
        DrawTPSLLines();
    }
    g_f3_armed=false;g_f3_dir=0;g_f3_counter=0;g_f3_reason="FIRED";
}

int GetHTFDirection(ENUM_TIMEFRAMES tf, int idx){
    double c = iClose(_Symbol, tf, idx);
    int h20 = iMA(_Symbol, tf, 20, 0, MODE_EMA, PRICE_CLOSE);
    int h50 = iMA(_Symbol, tf, 50, 0, MODE_EMA, PRICE_CLOSE);
    if(c==0 || h20==INVALID_HANDLE || h50==INVALID_HANDLE) return 0;

    double b20[1], b50[1], b50_prev[1];
    if(CopyBuffer(h20, 0, idx,   1, b20)      <= 0) return 0;
    if(CopyBuffer(h50, 0, idx,   1, b50)      <= 0) return 0;
    if(CopyBuffer(h50, 0, idx+3, 1, b50_prev) <= 0) return 0;

    double e20 = b20[0];
    double e50 = b50[0];
    double slope = e50 - b50_prev[0];

    if(c>e50 && e20>e50 && slope>=0) return 1;
    if(c<e50 && e20<e50 && slope<=0) return -1;
    return 0;
}

bool IsReversalOverride(int sig, int idx){
    if(!InpHTF_AllowReversalOverride) return false;
    double o=iOpen(_Symbol,_Period,idx), c=iClose(_Symbol,_Period,idx), h=iHigh(_Symbol,_Period,idx), l=iLow(_Symbol,_Period,idx);
    double atr[1]; if(CopyBuffer(h_atr,0,idx,1,atr)<=0 || atr[0]<=0) return false;
    double body=MathAbs(c-o), range=MathMax(_Point,h-l);
    bool strong_body = (body/atr[0] >= InpHTF_ReversalBodyATRMin);
    bool strong_close = (sig==1)?(c > (l + 0.65*range)):(c < (h - 0.65*range));
    return strong_body && strong_close;
}

// V-Line logic ported from user-provided Evasive SuperTrend PineScript (© LuxAlgo, CC BY-NC-SA 4.0).
// Keep usage/distribution aligned with that license.
bool BuildEvasiveSTSeries(ENUM_TIMEFRAMES tf, int bars, double &bands[], int &dirs[], bool &noisies[], bool &changed[]){
    int period=MathMax(1, InpVLine_ATRLength);
    int warmup=MathMax(300, period*30);
    int need=bars+warmup+2;
    if(bars<1 || Bars(_Symbol,tf)<=need) return false;

    int hatr=iATR(_Symbol,tf,period);
    if(hatr==INVALID_HANDLE) return false;

    MqlRates rates[]; ArraySetAsSeries(rates,true);
    double atr[]; ArraySetAsSeries(atr,true);
    int copied_rates=CopyRates(_Symbol,tf,0,need,rates);
    int copied_atr=CopyBuffer(hatr,0,0,need,atr);
    IndicatorRelease(hatr);
    if(copied_rates<need || copied_atr<need) return false;

    ArrayResize(bands,bars+1);   ArraySetAsSeries(bands,true);
    ArrayResize(dirs,bars+1);    ArraySetAsSeries(dirs,true);
    ArrayResize(noisies,bars+1); ArraySetAsSeries(noisies,true);
    ArrayResize(changed,bars+1); ArraySetAsSeries(changed,true);

    double st_band=0.0;
    bool has_band=false;
    int trend=1;
    int prev_trend=trend;
    bool noisy=false;

    for(int k=need-1; k>=0; k--){
        if(rates[k].high<=0 || rates[k].low<=0 || rates[k].close<=0 || atr[k]<=0) return false;
        double src=(rates[k].high+rates[k].low)*0.5;
        double upper_base=src + InpVLine_BaseMultiplier*atr[k];
        double lower_base=src - InpVLine_BaseMultiplier*atr[k];
        double prev_band=has_band ? st_band : (trend==1 ? lower_base : upper_base);
        prev_trend=trend;
        noisy=(MathAbs(rates[k].close-prev_band) < (atr[k]*InpVLine_NoiseThresholdATR));

        if(trend==1){
            st_band = noisy ? (prev_band - atr[k]*InpVLine_ExpansionAlphaATR) : MathMax(lower_base, prev_band);
            if(rates[k].close < st_band){ trend=-1; st_band=upper_base; }
        } else {
            st_band = noisy ? (prev_band + atr[k]*InpVLine_ExpansionAlphaATR) : MathMin(upper_base, prev_band);
            if(rates[k].close > st_band){ trend=1; st_band=lower_base; }
        }
        has_band=true;

        if(k<=bars){
            bands[k]=st_band;
            dirs[k]=trend;
            noisies[k]=noisy;
            changed[k]=(trend!=prev_trend);
        }
    }
    return true;
}

bool CalcEvasiveSupertrendAt(ENUM_TIMEFRAMES tf, int idx, double &out_band, int &out_dir, bool &out_noisy, bool &out_changed){
    out_band=0.0; out_dir=0; out_noisy=false; out_changed=false;
    double bands[]; int dirs[]; bool noisies[]; bool changed[];
    if(!BuildEvasiveSTSeries(tf,idx,bands,dirs,noisies,changed)) return false;
    out_band=bands[idx];
    out_dir=dirs[idx];
    out_noisy=noisies[idx];
    out_changed=changed[idx];
    return true;
}

bool EvasiveSTBlocks(int sig, int idx){
    g_est_dir=0; g_est_band=0.0; g_est_noisy=false; g_est_state=InpUseVLineGuard?"ERR":"OFF";
    if(!InpUseVLineGuard) return false;
    ENUM_TIMEFRAMES tf=(InpVLine_TF==PERIOD_CURRENT?_Period:InpVLine_TF);
    int tf_shift=idx;
    if(tf!=_Period){
        datetime t=iTime(_Symbol,_Period,idx);
        tf_shift=iBarShift(_Symbol,tf,t,false);
        if(tf_shift<0){ g_est_state="NO_BAR"; return InpVLine_BlockNeutral; }
    }
    bool changed=false;
    if(!CalcEvasiveSupertrendAt(tf,tf_shift,g_est_band,g_est_dir,g_est_noisy,changed)){
        g_est_state="NO_DATA";
        return InpVLine_BlockNeutral;
    }
    g_est_state=(g_est_dir>0?"BULL":"BEAR")+(g_est_noisy?" NOISE":"");
    return (sig!=g_est_dir);
}

void ClearEvasiveSTVisual(){
    for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--){
        string n=ObjectName(0,i,0,-1);
        if(StringFind(n,ObjName("EST_"))==0) ObjectDelete(0,n);
    }
}

int GetLazyVisualBars(ENUM_TIMEFRAMES tf){
    int base=MathMax(100,MathMin(InpVisualLazyBars,4000));
    int visible=(int)ChartGetInteger(0,CHART_VISIBLE_BARS);
    int first=(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
    int chart_sec=PeriodSeconds(_Period), tf_sec=PeriodSeconds(tf);
    int need=base;
    if(visible>0 && first>=0 && chart_sec>0 && tf_sec>0){
        int chart_need=first+visible+100;
        need=(int)MathCeil((double)chart_need*(double)chart_sec/(double)tf_sec);
        need=MathMax(base,need);
    }
    int available=Bars(_Symbol,tf)-MathMax(InpSMA_Slow,InpVLine_ATRLength)-5;
    return MathMax(5,MathMin(need,MathMin(available,4000)));
}

void DrawEvasiveSTVisual(){
    if(!InpVLine_ShowVisual){ ClearEvasiveSTVisual(); g_vline_visual_initialized=false; return; }
    if(!g_vline_visual_initialized){ ClearEvasiveSTVisual(); g_vline_visual_initialized=true; }
    ENUM_TIMEFRAMES tf=(InpVLine_TF==PERIOD_CURRENT?_Period:InpVLine_TF);
    int bars=MathMax(InpVLine_VisualBars,GetLazyVisualBars(tf));
    bars=MathMax(5,MathMin(bars,4000));
    if(Bars(_Symbol,tf)<bars+InpVLine_ATRLength+20) bars=MathMax(5,Bars(_Symbol,tf)-InpVLine_ATRLength-25);
    if(bars<5) return;

    double bands[]; int dirs[]; bool noisies[]; bool changed[];
    if(!BuildEvasiveSTSeries(tf,bars,bands,dirs,noisies,changed)) return;

    for(int k=bars; k>=1; k--){
        datetime t0=iTime(_Symbol,tf,k), t1=iTime(_Symbol,tf,k-1);
        if(t0<=0 || t1<=0 || bands[k]<=0 || bands[k-1]<=0) continue;

        string n=ObjName("EST_LINE_"+IntegerToString(k));
        if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_TREND,0,t0,bands[k],t1,bands[k-1]);
        else{
            ObjectSetInteger(0,n,OBJPROP_TIME,0,t0);  ObjectSetDouble(0,n,OBJPROP_PRICE,0,bands[k]);
            ObjectSetInteger(0,n,OBJPROP_TIME,1,t1);  ObjectSetDouble(0,n,OBJPROP_PRICE,1,bands[k-1]);
        }
        ObjectSetInteger(0,n,OBJPROP_COLOR,(dirs[k]>0?C'8,153,129':C'242,54,69'));
        ObjectSetInteger(0,n,OBJPROP_WIDTH,2);
        ObjectSetInteger(0,n,OBJPROP_STYLE,noisies[k]?STYLE_DOT:STYLE_SOLID);
        ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false);
        ObjectSetInteger(0,n,OBJPROP_RAY_LEFT,false);
        ObjectSetInteger(0,n,OBJPROP_BACK,false);
        ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
        ObjectSetInteger(0,n,OBJPROP_ZORDER,10);

        if(InpVLine_ShowSwitchLabels && changed[k]){
            string nl=ObjName("EST_LBL_"+IntegerToString(k));
            if(ObjectFind(0,nl)<0) ObjectCreate(0,nl,OBJ_TEXT,0,t0,bands[k]);
            else{ ObjectSetInteger(0,nl,OBJPROP_TIME,0,t0); ObjectSetDouble(0,nl,OBJPROP_PRICE,0,bands[k]); }
            ObjectSetString(0,nl,OBJPROP_TEXT,(dirs[k]>0?"BULL":"BEAR"));
            ObjectSetInteger(0,nl,OBJPROP_COLOR,(dirs[k]>0?C'8,153,129':C'242,54,69'));
            ObjectSetString(0,nl,OBJPROP_FONT,"Arial Bold");
            ObjectSetInteger(0,nl,OBJPROP_FONTSIZE,8);
            ObjectSetInteger(0,nl,OBJPROP_ANCHOR,(dirs[k]>0?ANCHOR_LOWER:ANCHOR_UPPER));
            ObjectSetInteger(0,nl,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(0,nl,OBJPROP_HIDDEN,true);
            ObjectSetInteger(0,nl,OBJPROP_ZORDER,20);
        }
    }
}


bool CalcECIAt(int idx, double &score, string &state){
    score=0.0; state="ERR";
    int look=MathMax(5, InpECI_Lookback);
    int bars=Bars(_Symbol,_Period);
    if(idx<0 || bars <= idx+look+1){ state="NO_DATA"; return false; }

    int buckets[7];
    ArrayInitialize(buckets,0);
    int total=0;
    for(int i=idx; i<idx+look; i++){
        double o=iOpen(_Symbol,_Period,i), h=iHigh(_Symbol,_Period,i), l=iLow(_Symbol,_Period,i), c=iClose(_Symbol,_Period,i);
        double range=h-l;
        if(range<=_Point*0.1) continue;
        double body=MathAbs(c-o);
        double upper=h-MathMax(o,c);
        double lower=MathMin(o,c)-l;
        double body_ratio=body/range;
        double upper_ratio=upper/range;
        double lower_ratio=lower/range;
        int bucket=6; // neutral / weak-bear cluster

        if(body_ratio>=0.55) bucket=(c>=o?0:1);                            // ordered bull/bear body
        else if(upper_ratio>=0.45 && upper_ratio>lower_ratio*1.20) bucket=2; // upper rejection
        else if(lower_ratio>=0.45 && lower_ratio>upper_ratio*1.20) bucket=3; // lower rejection
        else if(body_ratio<=0.20) bucket=4;                                  // doji / wick-dominant noise
        else bucket=(c>=o?5:6);                                               // weak bull / weak bear

        buckets[bucket]++;
        total++;
    }
    if(total<5){ state="NO_DATA"; return false; }

    double entropy=0.0;
    for(int b=0; b<7; b++){
        if(buckets[b]<=0) continue;
        double p=(double)buckets[b]/(double)total;
        entropy -= p*MathLog(p);
    }
    score = entropy / MathLog(7.0); // normalized 0..1, high=random/chop, low=ordered

    double bull_count = buckets[0] + buckets[3] + buckets[5];
    double bear_count = buckets[1] + buckets[2] + buckets[6];
    g_eci_direction_balance = MathAbs(bull_count - bear_count) / (double)total;
    g_eci_body_dominance = (double)(buckets[0] + buckets[1]) / (double)total;

    bool entropy_high = (score >= InpECI_ChopThreshold);
    bool directionless = (g_eci_direction_balance <= InpECI_DirectionalBalanceMax);
    bool body_weak = (g_eci_body_dominance <= InpECI_BodyDominanceMax);
    bool true_chop = (entropy_high && directionless && body_weak);

    if(true_chop) state="CHOP "+DoubleToString(score,2);
    else if(entropy_high) state="TREND "+DoubleToString(score,2);
    else if(score>=InpECI_MixedThreshold) state="MIXED "+DoubleToString(score,2);
    else state="ORDER "+DoubleToString(score,2);
    return true;
}

bool ECITriggered(int idx){
    g_eci_score=0.0;
    g_eci_direction_balance=0.0;
    g_eci_body_dominance=0.0;
    g_eci_trig=false;
    g_eci_state=(InpECI_Action==F_OFF?"OFF":"ERR");
    if(InpECI_Action==F_OFF) return false;
    if(!CalcECIAt(idx,g_eci_score,g_eci_state)) return false;
    g_eci_trig=(StringFind(g_eci_state,"CHOP") == 0);
    return g_eci_trig;
}

bool SidewayBlocks(int sig, int idx){
    if(!InpUseSidewayGuard) return false;
    double e0[1], e4[1], s0[1];
    if(CopyBuffer(h_ema_fast,0,idx,1,e0)<=0 || CopyBuffer(h_ema_fast,0,idx+4,1,e4)<=0 || CopyBuffer(h_sma_slow,0,idx,1,s0)<=0) return false;
    double slope_pts = MathAbs((e0[0]-e4[0])/_Point)/4.0;

    double atr[1];
    if(CopyBuffer(h_atr,0,idx,1,atr)<=0 || atr[0]<=0) return (slope_pts < InpSideway_MinEMASlopePts);
    double ma_gap_atr = MathAbs(e0[0]-s0[0]) / atr[0];

    int crosses=0;
    int look=MathMax(4, InpSideway_CrossLookback);
    for(int k=idx; k<idx+look; k++) if(DetectSignalAt(k)!=0) crosses++;

    bool flat = (slope_pts < InpSideway_MinEMASlopePts);
    bool tight = (ma_gap_atr < InpSideway_MinMAGapATR);
    bool noisy_cross = (crosses > InpSideway_MaxCrosses);
    return (flat && tight) || (flat && noisy_cross) || (tight && noisy_cross);
}

bool HTFContextBlocks(int sig, int idx){
    bool blocked=false;
    if(InpUseH1Bias){
        int h1 = GetHTFDirection(PERIOD_H1, idx);
        if(h1==0 && !InpAllowNeutralBias) blocked=true;
        if(h1!=0 && sig!=h1) blocked=true;
    }
    if(InpUseM15Setup){
        int m15 = GetHTFDirection(PERIOD_M15, idx);
        if(m15==0 && !InpAllowM15Neutral) blocked=true;
        if(m15!=0 && sig!=m15) blocked=true;
    }
    if(blocked && IsReversalOverride(sig, idx)) return false;
    return blocked;
}

// === PIPELINE (v13.10.0 simplified — no scoring, no judge) ===
// Returns true if signal should proceed (not blocked).
// v13.11.7 behavior: each filter keeps ON/OFF runtime, with class-based effect: SOFT=>LIMITED, HARD=>BLOCKED when ON and triggered.
// Enabled filters follow class effect: SOFT=>LIMITED, HARD=>BLOCKED.
// Market Regime detector (when enabled) and Intelligent Filter are also
// blocking gates when their conditions are met.
string SqueezeStateToString(ENUM_SQUEEZE_STATE st){
    switch(st){
        case SQ_BUILDUP: return "BUILDUP";
        case SQ_ARMED: return "ARMED";
        case SQ_BREAKOUT_UP: return "BR_UP";
        case SQ_BREAKOUT_DN: return "BR_DN";
        case SQ_CONFIRMED_UP: return "CONF_UP";
        case SQ_CONFIRMED_DN: return "CONF_DN";
        case SQ_FALSE_BREAK: return "FALSE_BR";
        case SQ_LOCKOUT: return "LOCKOUT";
        default: return "NONE";
    }
}

bool ReadATRSet(int idx, double &atr5, double &atr14, double &atr50){
    atr5=0; atr14=0; atr50=0;
    if(h_atr==INVALID_HANDLE || h_atr_fast==INVALID_HANDLE || h_atr_slow==INVALID_HANDLE) return false;
    double a5[1], a14[1], a50[1];
    if(CopyBuffer(h_atr_fast,0,idx,1,a5)<=0) return false;
    if(CopyBuffer(h_atr,0,idx,1,a14)<=0) return false;
    if(CopyBuffer(h_atr_slow,0,idx,1,a50)<=0) return false;
    atr5=a5[0]; atr14=a14[0]; atr50=a50[0];
    return (atr5>0 && atr14>0 && atr50>0);
}

bool ReadCoreMA(int idx, double &ema_fast, double &ma_slow){
    ema_fast=0; ma_slow=0;
    double ef[1], es[1];
    if(CopyBuffer(h_ema_fast,0,idx,1,ef)<=0) return false;
    if(CopyBuffer(h_sma_slow,0,idx,1,es)<=0) return false;
    ema_fast=ef[0]; ma_slow=es[0];
    return (ema_fast>0 && ma_slow>0);
}

bool CalcDonchianRange(int lookback, int shift_start, double &range_high, double &range_low){
    range_high = -1.0e100;
    range_low = 1.0e100;
    int look = MathMax(2, lookback);
    for(int i=shift_start; i<shift_start+look; i++){
        double h=iHigh(_Symbol,_Period,i), l=iLow(_Symbol,_Period,i);
        if(h<=0 || l<=0) return false;
        if(h>range_high) range_high=h;
        if(l<range_low) range_low=l;
    }
    return (range_high>range_low && range_low>0.0);
}

int CountCoreCrosses(int lookback, int shift_start){
    int crosses=0;
    int look=MathMax(2, lookback);
    for(int i=shift_start; i<shift_start+look; i++) if(DetectSignalAt(i)!=0) crosses++;
    return crosses;
}

bool IsSqueezeCompression(int shift, string &reason){
    double hi, lo;
    if(!CalcDonchianRange(InpSQ_Lookback, shift+1, hi, lo)){ reason="SQ_RANGE_FAIL"; return false; }
    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50)){ reason="SQ_ATR_FAIL"; return false; }
    double ema_fast, ma_slow;
    if(!ReadCoreMA(shift, ema_fast, ma_slow)){ reason="SQ_MA_FAIL"; return false; }
    double range_atr=(hi-lo)/MathMax(atr14,_Point);
    double atr_comp=atr14/MathMax(atr50,_Point);
    double ma_gap_atr=MathAbs(ema_fast-ma_slow)/MathMax(atr14,_Point);
    int crosses=CountCoreCrosses(InpSQ_CrossDensityLookback, shift+1);
    g_sq_range_high=hi; g_sq_range_low=lo;
    if(range_atr<=InpSQ_RangeATRMax && atr_comp<=InpSQ_ATRCompressionMax && ma_gap_atr<=InpSQ_MAGapATRMax && crosses>=InpSQ_CrossDensityMin){
        reason="SQ_COMPRESS";
        return true;
    }
    reason="SQ_NONE";
    return false;
}

bool IsBreakoutQualityGood(int sig, int shift, string &reason){
    double o=iOpen(_Symbol,_Period,shift), h=iHigh(_Symbol,_Period,shift), l=iLow(_Symbol,_Period,shift), c=iClose(_Symbol,_Period,shift);
    double range=MathMax(h-l,_Point), body=MathAbs(c-o);
    double body_ratio=body/range, close_loc=(c-l)/range;
    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50)){ reason="BR_ATR_FAIL"; return false; }
    double fast_ratio=atr5/MathMax(atr14,_Point);
    if(fast_ratio>InpSQ_SpikeRatioBlock){ reason="BR_SPIKE_CHAOS"; return false; }
    if(body_ratio<InpSQ_MinBodyRatio){ reason="BR_WEAK_BODY"; return false; }
    if(sig>0 && close_loc<InpSQ_BuyCloseLocMin){ reason="BR_BAD_CLOSE_BUY"; return false; }
    if(sig<0 && close_loc>InpSQ_SellCloseLocMax){ reason="BR_BAD_CLOSE_SELL"; return false; }
    reason="BR_QUALITY_OK";
    return true;
}

ENUM_FILTER_DECISION EvalSqueezeGuard(int sig, int shift, string &state, string &reason){
    state="OFF"; reason="SQ_OFF";
    if(!InpUseSqueezeGuard){ g_sq_state=SQ_NONE; g_sq_reason=reason; return DEC_OK; }
    string comp_reason="";
    bool compressed=IsSqueezeCompression(shift, comp_reason);
    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50)){ g_sq_state=SQ_NONE; state="ERR"; reason="SQ_ATR_FAIL"; g_sq_reason=reason; return DEC_OK; }
    double c=iClose(_Symbol,_Period,shift);
    double buffer=InpSQ_BreakoutBufferATR*atr14;
    bool br_up=compressed && c>(g_sq_range_high+buffer);
    bool br_dn=compressed && c<(g_sq_range_low-buffer);
    if(!compressed){ g_sq_state=SQ_NONE; state=SqueezeStateToString(g_sq_state); reason=comp_reason; g_sq_reason=reason; return DEC_OK; }
    if(br_up || br_dn){
        g_sq_state=br_up?SQ_BREAKOUT_UP:SQ_BREAKOUT_DN;
        state=SqueezeStateToString(g_sq_state);
        if((br_up && sig<0) || (br_dn && sig>0)){ reason=br_up?"SQ_OPPOSITE_SELL":"SQ_OPPOSITE_BUY"; g_sq_reason=reason; return DEC_BLOCKED; }
        string br_reason="";
        if(IsBreakoutQualityGood(sig, shift, br_reason)){ reason=br_reason; g_sq_reason=reason; return DEC_LIMITED; }
        reason=br_reason; g_sq_reason=reason; g_sq_state=SQ_FALSE_BREAK; state=SqueezeStateToString(g_sq_state); return DEC_BLOCKED;
    }
    g_sq_state=SQ_ARMED;
    state=SqueezeStateToString(g_sq_state);
    reason="SQ_COMPRESS_BLOCK";
    g_sq_reason=reason;
    return DEC_BLOCKED;
}

ENUM_FILTER_DECISION EvalATRHealthAt(int idx, string &state){
    state = "OFF";
    if(!InpUseATRHealthGuard) return DEC_OK;
    if(h_atr==INVALID_HANDLE || h_atr_fast==INVALID_HANDLE || h_atr_slow==INVALID_HANDLE) return DEC_OK;
    double a14[1], a5[1], a50[1];
    if(CopyBuffer(h_atr,0,idx,1,a14)<=0 || CopyBuffer(h_atr_fast,0,idx,1,a5)<=0 || CopyBuffer(h_atr_slow,0,idx,1,a50)<=0) return DEC_OK;
    if(a14[0]<=0 || a50[0]<=0) return DEC_OK;
    double atrVal = a14[0]; // price units, matching dashboard ATR and user inputs (e.g. XAU ATR 1.67)
    double fastRatio = a5[0]/a14[0];
    if(atrVal >= InpATR_M5_BlockAbove || fastRatio >= InpATR_FastRatioBlock){ state="CHAOS"; return DEC_BLOCKED; }
    if(atrVal < InpATR_M5_MinTrade){ state="LOWVOL"; return DEC_LIMITED; }
    if(atrVal > InpATR_M5_MaxAllowed){ state="TOO_HIGH"; return DEC_BLOCKED; }
    if(atrVal > InpATR_M5_MaxNormal || fastRatio >= InpATR_FastRatioLimited){ state="LIMITED"; return DEC_LIMITED; }
    state="OK"; return DEC_OK;
}

bool EvaluatePipeline(int sig){
    g_pipe_hard=false; g_pipe_soft=false;
    g_f0_trig=false;g_f1_trig=false;g_f2_trig=false;
    g_f4_trig=false;g_f5_trig=false;
    g_regime_lot_scale=1.0;

    bool h_f2=false;
    if(InpF2_Action!=F_OFF){
        g_f2_trig=EvalF2();
        if(g_f2_trig) h_f2=true;
    }

    bool h_htf = HTFContextBlocks(sig, 1);
    bool h_est = EvasiveSTBlocks(sig, 1);
    bool h_slow_angle = SlowMAAngleBlocks(sig, 1);
    bool t_eci = ECITriggered(1);
    bool h_eci = (InpECI_Action==F_HARD && t_eci);
    bool s_eci = (InpECI_Action==F_SOFT && t_eci);
    bool h_sideway = SidewayBlocks(sig, 1);
    string atr_state="";
    ENUM_FILTER_DECISION atr_dec = EvalATRHealthAt(1, atr_state);
    string sq_state="", sq_reason="";
    ENUM_FILTER_DECISION sq_dec = EvalSqueezeGuard(sig, 1, sq_state, sq_reason);
    bool h_atr = (atr_dec==DEC_BLOCKED);
    bool s_atr = (atr_dec==DEC_LIMITED);
    bool h_sq = (sq_dec==DEC_BLOCKED);
    bool s_sq = (sq_dec==DEC_LIMITED);
    g_pipe_filter_hard = h_f2 || h_htf || h_est || h_slow_angle || h_eci || h_sideway || h_atr || h_sq;
    g_pipe_soft = s_eci || s_atr || s_sq;
    g_pipe_hard = g_pipe_filter_hard;
    return !g_pipe_hard;
}

// Historical pipeline evaluation (for ScanHistory).
// v13.10.0 simplified — no scoring/judge; each F_HARD filter independently blocks.
bool EvaluatePipelineAt(int idx, int sig, bool &out_hard, bool &out_soft){
    out_hard=false; out_soft=false;
    if(InpF2_Action!=F_OFF && EvalF2At(idx)) out_hard=true;
    if(HTFContextBlocks(sig, idx)) out_hard=true;
    if(EvasiveSTBlocks(sig, idx)) out_hard=true;
    if(SlowMAAngleBlocks(sig, idx)) out_hard=true;
    bool t_eci=ECITriggered(idx);
    if(t_eci && InpECI_Action==F_HARD) out_hard=true;
    if(t_eci && InpECI_Action==F_SOFT) out_soft=true;
    if(SidewayBlocks(sig, idx)) out_hard=true;
    string atr_state="";
    ENUM_FILTER_DECISION atr_dec = EvalATRHealthAt(idx, atr_state);
    if(atr_dec==DEC_BLOCKED) out_hard=true;
    if(atr_dec==DEC_LIMITED) out_soft=true;
    string sq_state="", sq_reason="";
    ENUM_FILTER_DECISION sq_dec = EvalSqueezeGuard(sig, idx, sq_state, sq_reason);
    if(sq_dec==DEC_BLOCKED) out_hard=true;
    if(sq_dec==DEC_LIMITED) out_soft=true;
    return !out_hard;
}

// === SIGNAL DETECTION ===
int DetectSignal(){
    double ef[],es[];ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);
    if(CopyBuffer(h_ema_fast,0,1,2,ef)<2)return 0;
    if(CopyBuffer(h_sma_slow,0,1,2,es)<2)return 0;
    if((ef[1]<=es[1])&&(ef[0]>es[0]))return 1;
    if((ef[1]>=es[1])&&(ef[0]<es[0]))return -1;
    return 0;
}
int DetectSignalAt(int idx){
    double ef[],es[];ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);
    if(CopyBuffer(h_ema_fast,0,idx,2,ef)<2)return 0;
    if(CopyBuffer(h_sma_slow,0,idx,2,es)<2)return 0;
    if((ef[1]<=es[1])&&(ef[0]>es[0]))return 1;
    if((ef[1]>=es[1])&&(ef[0]<es[0]))return -1;
    return 0;
}

// === MARKET CONDITION PRE-CHECK ===
bool PreCheckMarketConditions(){
    int sp=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
    if(sp>InpMax_Spread)return false;
    if(InpUseSession){
        MqlDateTime m;TimeToStruct(TimeCurrent(),m);
        // Filter active flag for the current weekday.
        // true  → block trading outside [Start, End) hour window
        // false → no filter today, allow 24h
        bool day_filter_active=false;
        switch(m.day_of_week){
            case 0: day_filter_active=InpSessionSun; break;
            case 1: day_filter_active=InpSessionMon; break;
            case 2: day_filter_active=InpSessionTue; break;
            case 3: day_filter_active=InpSessionWed; break;
            case 4: day_filter_active=InpSessionThu; break;
            case 5: day_filter_active=InpSessionFri; break;
            case 6: day_filter_active=InpSessionSat; break;
        }
        if(day_filter_active && (m.hour<InpSessionStart || m.hour>=InpSessionEnd))
            return false;
    }
    if(InpUseDailyLoss&&g_daily_blocked)return false;
    if(InpUseDailyProfitStop&&g_daily_profit_blocked)return false;
    return true;
}


// === SETUP TRADE ===
// tight_mode=true when at least one SOFT filter triggered
void SetupTrade(int dir, bool tight_mode){
    double c1=iClose(_Symbol,_Period,1);
    g_entry_price=c1;g_entry_atr=g_atr_val;g_soft_mode=tight_mode;
    double risk=g_atr_val*(tight_mode?InpSoft_SL_Mult:InpSL_Mult);
    g_sl_price=(dir==1)?c1-risk:c1+risk;g_sl_initial_dist=risk;
    // TP calculation
    double tp1_dist, tp2_dist;
    if(tight_mode){
        tp1_dist=g_atr_val*InpSoft_TP1_Mult;
        tp2_dist=tp1_dist+g_atr_val*InpSoft_TP2_Mult;
    } else {
        tp1_dist=g_atr_val*InpTP1_Mult;
        tp2_dist=tp1_dist+g_atr_val*InpTP1_to_TP2_Mult;
    }
    g_tp[0]=(dir==1)?c1+tp1_dist:c1-tp1_dist;
    g_tp[1]=(dir==1)?c1+tp2_dist:c1-tp2_dist;
    for(int i=2;i<MAX_TP;i++){double sd=(i-1)*g_atr_val*InpTP_Step_Mult;g_tp[i]=(dir==1)?g_tp[1]+sd:g_tp[1]-sd;}
    for(int i=0;i<MAX_TP;i++)g_tp_hit[i]=false;
    g_tp_unlocked=5;g_last_signal=dir;g_last_signal_bar=g_current_bar;
    g_last_entry=c1;g_entry_bar=g_current_bar;g_bars_in_trade=0;
    g_initial_lot=CalcLot();g_closed_lot_total=0;g_awaiting_reentry=false;g_reentry_dir=0;g_reentry_reason="";
    g_ssl_phase=0;
    // In soft mode SL is always forced ON
    g_sl_forced=tight_mode;
    g_peak_price=c1;g_peak_bar=g_current_bar;
    g_retest_armed=false;g_retest_dir=0;g_retest_counter=0;g_retest_seen_pullback=false;
    g_f3_armed=false;g_f3_dir=0;g_f3_counter=0;g_f3_reason="---";
    ResetSmartTPState();
    g_visual_signal=dir;g_visual_entry=c1;g_visual_sl=g_sl_price;
    g_visual_atr=g_atr_val;g_visual_tp_unlocked=5;
    for(int i=0;i<MAX_TP;i++){g_visual_tp[i]=g_tp[i];g_visual_tp_hit[i]=false;}
    Print("[SIGNAL] ",(dir==1?"BUY":"SELL"),tight_mode?" [SOFT]":""," Entry=",DoubleToString(c1,_Digits),
          " SL=",DoubleToString(g_sl_price,_Digits)," TP1=",DoubleToString(g_tp[0],_Digits));
    SendAlert((dir==1?"BUY":"SELL")+(tight_mode?" SOFT":"")+" @ "+DoubleToString(c1,_Digits));
}

void ResetSmartTPState(){
    g_stp1_phase=0;g_stp1_lot_per=0;g_stp2_phase=0;g_stp2_lot_per=0;
    g_stp3_highestTP=0;g_stp3_partialPct=0;g_stp3_direction=0;g_stp3_armed=false;
    ArrayInitialize(g_stp3_triggered,false);
    g_ssl_phase=0;g_ssl_lot_per=0;
}

// === MANUAL TP TARGET EXIT ===
// Closes the remaining EA position at the user-selected TP level. This is a
// final target exit, not a partial itself; InpManualTP_UsePartialSystem decides
// whether Smart-TP partials may run before the selected target is touched.
bool ProcessManualTPTargetExit(){
    if(g_last_signal==0||!UseManualTPTarget())return false;
    int idx=InpManualTP_Target-1;
    if(idx<0||idx>=MAX_TP||g_tp[idx]<=0)return false;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(price<=0)return false;
    bool hit=(g_last_signal==1&&price>=g_tp[idx])||(g_last_signal==-1&&price<=g_tp[idx]);
    if(!hit)return false;
    string reason="MTP"+IntegerToString(InpManualTP_Target);
    if(InpIndicatorOnly){
        DrawExitMarker(TimeCurrent(),price,reason);
        Print("[MANUAL TP] ",reason," touched — indicator-only close marker");
        g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;g_soft_mode=false;
        return true;
    }
    if(!RuntimeDirMatchesPosition()){
        Print("[MANUAL TP] ",reason," skipped: server position direction mismatches runtime state");
        return false;
    }
    if(EAClose(reason)){
        DrawExitMarker(TimeCurrent(),price,reason);
        Print("[MANUAL TP] ",reason," touched — closed remaining position at TP",InpManualTP_Target);
        g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;g_soft_mode=false;
        return true;
    }
    Print("[MANUAL TP] ",reason," close FAILED");
    return false;
}

// === TP HIT DETECTION ===
void CheckTPHits(){
    if(g_last_signal==0)return;
    double hi=iHigh(_Symbol,_Period,0),lo=iLow(_Symbol,_Period,0);
    for(int i=0;i<g_tp_unlocked;i++){
        if(g_tp_hit[i])continue;
        bool hit=(g_last_signal==1&&hi>=g_tp[i])||(g_last_signal==-1&&lo<=g_tp[i]);
        if(hit){
            g_tp_hit[i]=true;g_visual_tp_hit[i]=true;
            Print("[TP",i+1," HIT] ",DoubleToString(g_tp[i],_Digits));
            if(i==4&&g_tp_unlocked<10){g_tp_unlocked=10;g_visual_tp_unlocked=10;}
            if(i==9&&g_tp_unlocked<20){g_tp_unlocked=20;g_visual_tp_unlocked=20;}
            if(i==19&&g_tp_unlocked<30){g_tp_unlocked=30;g_visual_tp_unlocked=30;}
            if(i>=2&&!g_stp3_armed)g_stp3_armed=true;
        }
    }
    // Manual TP target is a final close layer. Run it before Smart-TP so a
    // selected target such as TP2 can close immediately on touch.
    if(ProcessManualTPTargetExit())return;
    // Smart TP sub-zone partials run every tick (not gated on discrete TP hits)
    ProcessSTP1();ProcessSTP2();
    if(UseSmartTP())ProcessSTP3();
    ProcessSmartSL();
}

// === SMART SL (sub-zone risk mitigation) ===
// Splits entry→SL into 5 equal zones. Each adverse zone-touch closes 20 % of
// the initial lot via EAPartialClose. When the 5th zone (= SL price) is hit
// the remaining volume is flattened. Mirror of Smart TP1 on the loss side.
//
// Comparator: live tick price (Bid for BUY, Ask for SELL). NOT bar low/high —
// using bar extremes would phantom-trigger on transient dips that recover
// before bar close (e.g. a profitable bar that briefly wicked through entry).
void ProcessSmartSL(){
    if(g_last_signal==0||InpIndicatorOnly||!UseSmartSL()||g_ssl_phase>=5)return;
    double entry=g_entry_price, sl=g_sl_price;
    if(entry<=0||sl<=0||entry==sl)return;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(price<=0)return;
    // Bail if current price is on the favorable side of entry — Smart SL only
    // operates between entry and SL.
    if((g_last_signal==1 && price>=entry) || (g_last_signal==-1 && price<=entry))return;
    double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
    if(g_ssl_lot_per<=0)g_ssl_lot_per=g_initial_lot*0.20;
    int reached=0;
    for(int k=1;k<=5;k++){
        double lvl=entry+(sl-entry)*(double)k/5.0;
        bool hit=(g_last_signal==1)?(price<=lvl):(price>=lvl);
        if(hit)reached=k;
    }
    while(g_ssl_phase<reached){
        double pv=GetPositionVolume();if(pv<=mn){g_ssl_phase=5;break;}
        double lot=NormalizeLot(g_ssl_lot_per);
        if(lot>=pv){
            // Closing the last slice fully flattens the position.
            if(EAClose("SSL"+IntegerToString(g_ssl_phase+1))){
                Print("[SMART SL] zone ",g_ssl_phase+1,"/5 flatten");
                g_ssl_phase=5;g_last_signal=0;g_sl_forced=false;
            }
            break;
        }
        g_ssl_phase++;
        if(!EAPartialClose(lot,"SSL"+IntegerToString(g_ssl_phase))){
            Print("[SMART SL] partial zone ",g_ssl_phase," FAILED");
            break;
        }
        Print("[SMART SL] zone ",g_ssl_phase,"/5 partial ",DoubleToString(lot,2));
    }
}

// === SMART TP PHASE 1 — progressive sub-zone partials (entry → TP1 in 2 zones) ===
// Each zone is 1/2 of the distance entry→TP1. When price touches a zone for the
// first time, one partial fires (InpSTP1_Pct % × 1/2 of initial lot). After both
// zones trigger, total closed = InpSTP1_Pct % of initial lot.
void ProcessSTP1(){
    if(g_last_signal==0||InpIndicatorOnly||g_stp1_phase>=2||!UseSmartTP()||!InpSTP1_UseSubZones)return;
    double entry=g_entry_price, tp1=g_tp[0];
    if(entry<=0||tp1<=0||entry==tp1)return;
    // Live tick comparator (consistent with Smart SL / Smart TP3) — avoids
    // phantom-trigger on bars that wick past a zone then retrace.
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(price<=0)return;
    double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
    if(g_stp1_lot_per<=0)g_stp1_lot_per=(InpSTP1_Pct/100.0)*g_initial_lot*0.50;
    int reached=0;
    for(int k=1;k<=2;k++){
        double lvl=entry+(tp1-entry)*(double)k/2.0;
        bool hit=(g_last_signal==1)?(price>=lvl):(price<=lvl);
        if(hit)reached=k;
    }
    if(reached>0&&!CanRunSmartTPPartial()){Print("[SMART TP1] skipped: server position mismatch or not in profit");return;}
    while(g_stp1_phase<reached){
        double pv=GetPositionVolume();
        if(pv<=mn){
            if(reached>=2&&CanRunSmartTPPartial()&&EAClose("TP1_MINLOT")){
                Print("[SMART TP1] TP1 reached; minimum-lot position closed because broker cannot partial below min lot");
                g_stp1_phase=2;g_last_signal=0;
            } else g_stp1_phase=2;
            break;
        }
        double lot=NormalizeLot(g_stp1_lot_per);if(lot>=pv){g_stp1_phase=2;break;}
        g_stp1_phase++;
        if(!EAPartialClose(lot,"STP1_"+IntegerToString(g_stp1_phase)))break;
        Print("[SMART TP1] zone ",g_stp1_phase,"/2 partial ",DoubleToString(lot,2));
    }
}
// === SMART TP PHASE 2 — progressive sub-zone partials (TP1 → TP2 in 2 zones) ===
void ProcessSTP2(){
    if(g_last_signal==0||InpIndicatorOnly||g_stp2_phase>=2||!UseSmartTP()||!InpSTP2_UseSubZones)return;
    double tp1=g_tp[0], tp2=g_tp[1];
    if(tp1<=0||tp2<=0||tp1==tp2)return;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(price<=0)return;
    double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
    if(g_stp2_lot_per<=0)g_stp2_lot_per=(InpSTP2_Pct/100.0)*g_initial_lot*0.50;
    int reached=0;
    for(int k=1;k<=2;k++){
        double lvl=tp1+(tp2-tp1)*(double)k/2.0;
        bool hit=(g_last_signal==1)?(price>=lvl):(price<=lvl);
        if(hit)reached=k;
    }
    if(reached>0&&!CanRunSmartTPPartial()){Print("[SMART TP2] skipped: server position mismatch or not in profit");return;}
    while(g_stp2_phase<reached){
        double pv=GetPositionVolume();if(pv<=mn){g_stp2_phase=2;break;}
        double lot=NormalizeLot(g_stp2_lot_per);if(lot>=pv){g_stp2_phase=2;break;}
        g_stp2_phase++;
        if(!EAPartialClose(lot,"STP2_"+IntegerToString(g_stp2_phase)))break;
        Print("[SMART TP2] zone ",g_stp2_phase,"/2 partial ",DoubleToString(lot,2));
    }
}
// === SMART TP PHASE 3 ===
void ProcessSTP3(){
    if(g_last_signal==0||InpIndicatorOnly||!InpSTP3_UsePartial||!g_stp3_armed||g_stp1_phase<2||g_stp2_phase<2)return;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    int cur_level=0;
    for(int i=g_tp_unlocked-1;i>=0;i--){bool above=(g_last_signal==1&&price>=g_tp[i])||(g_last_signal==-1&&price<=g_tp[i]);if(above){cur_level=i+1;break;}}
    if(cur_level>g_stp3_highestTP){
        if(g_stp3_highestTP>0&&(cur_level-g_stp3_highestTP)>=2){ArrayInitialize(g_stp3_triggered,false);g_stp3_direction=0;}
        g_stp3_highestTP=cur_level;g_stp3_partialPct=1.0/(double)cur_level;g_stp3_direction=0;return;
    }
    if(cur_level<g_stp3_highestTP){
        if(g_stp3_direction==0){g_stp3_direction=1;Print("[STP3] Reversal TP",g_stp3_highestTP,"→TP",cur_level);}
        for(int i=g_stp3_highestTP-1;i>=cur_level;i--){
            if(i<0||g_stp3_triggered[i])continue;g_stp3_triggered[i]=true;
            double pv=GetPositionVolume();double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);if(pv<=mn)break;
            double lot=NormalizeLot(pv*g_stp3_partialPct/3.0);if(lot<0.01)lot=0.01;if(lot>=pv)lot=NormalizeLot(pv*0.5);
            EAPartialClose(lot,"STP3_TP"+IntegerToString(i+1));
        }
    }
}


// === EXIT CHECKS ===

// Spike SL — pure adverse-velocity exit.
// Fires when the forming bar's worst adverse excursion vs entry exceeds
// InpSpike_ATR_Mult × entry ATR. No volume gate — a sudden fast move IS the
// signal regardless of tick density. Does NOT arm re-entry; a fresh crossing
// signal must form for a new trade.
void CheckSpikeSL(){
    if(g_last_signal==0||!InpUseSpikeSL||g_entry_atr<=0)return;
    double adverse;
    if(g_last_signal==1) adverse = g_entry_price - iLow(_Symbol,_Period,0);
    else                 adverse = iHigh(_Symbol,_Period,0) - g_entry_price;
    if(adverse < InpSpike_ATR_Mult*g_entry_atr) return;
    double p=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(InpIndicatorOnly){DrawExitMarker(TimeCurrent(),p,"SPIKE");g_last_signal=0;}
    else if(EAClose("SPIKE")){DrawExitMarker(TimeCurrent(),p,"SPIKE");g_last_signal=0;}
    else Print("[SPIKE] close FAILED");
}

void CheckHardSL(){
    if(g_last_signal==0||(!InpUseSL&&!g_sl_forced)||g_sl_price<=0)return;
    double px;
    if(InpSL_HardlineTrigger==EXIT_ON_TOUCH)
        px=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    else
        px=iClose(_Symbol,_Period,1);
    bool hit=(g_last_signal==1&&px<=g_sl_price)||(g_last_signal==-1&&px>=g_sl_price);
    if(!hit)return;
    if(InpIndicatorOnly){DrawExitMarker(TimeCurrent(),px,"SL");ArmReentry(g_last_signal,"SL");g_last_signal=0;}
    else if(EAClose("SL")){DrawExitMarker(TimeCurrent(),px,"SL");ArmReentry(g_last_signal,"SL");g_consec_loss++;g_last_signal=0;}
    else Print("[SL] close FAILED");
}

// v13.5.0: auto-close any open EA position the moment the clock crosses
// the end-of-session boundary on a filter-active day (#6). Per-tick check
// so the close fires within ~1s of the boundary instead of waiting for a
// new bar.
bool g_was_in_session_window = true;
void CheckSessionEndExit(){
    if(!InpUseSession) { g_was_in_session_window = true; return; }
    MqlDateTime m; TimeToStruct(TimeCurrent(), m);
    bool day_filter_active = false;
    switch(m.day_of_week){
        case 0: day_filter_active=InpSessionSun; break;
        case 1: day_filter_active=InpSessionMon; break;
        case 2: day_filter_active=InpSessionTue; break;
        case 3: day_filter_active=InpSessionWed; break;
        case 4: day_filter_active=InpSessionThu; break;
        case 5: day_filter_active=InpSessionFri; break;
        case 6: day_filter_active=InpSessionSat; break;
    }
    bool is_in_window;
    if(!day_filter_active){
        // Days where the session filter is OFF count as "in window" so
        // we don't trigger a close at midnight rollover into a free day.
        is_in_window = true;
    } else {
        is_in_window = (m.hour >= InpSessionStart && m.hour < InpSessionEnd);
    }
    if(g_was_in_session_window && !is_in_window){
        // Just crossed out of an active session window → close.
        if(g_last_signal != 0 && !InpIndicatorOnly){
            Print("[SESSION] End-of-window reached, auto-closing position.");
            EAClose("SESSION");
            g_last_signal = 0;
            g_sl_forced = false; g_ssl_phase = 0; g_soft_mode = false;
        }
    }
    g_was_in_session_window = is_in_window;
}

void CheckMaxBars(){
    if(g_last_signal==0||InpMaxBarsInTrade<=0)return;
    g_bars_in_trade=g_current_bar-g_entry_bar;
    if(g_bars_in_trade<InpMaxBarsInTrade)return;
    double p=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(InpIndicatorOnly){DrawExitMarker(TimeCurrent(),p,"MAXBAR");g_last_signal=0;}
    else if(EAClose("MAXBAR")){DrawExitMarker(TimeCurrent(),p,"MAXBAR");g_last_signal=0;}
    else Print("[MAXBAR] close FAILED");
}

void CheckEarlyExitSlowMA(){
    // Repurposed in v13.6.x: protective exit on FAST MA after trend expansion.
    // It arms only once the MA gap is at least X ATR, so normal early cross
    // noise does not immediately close the trade.
    // v13.9.21: F11 recovery entries skip the MA-gap gate. They fire right at
    // the cross where the gap is zero by definition, so the gate silently
    // shielded F11 trades from FMA-X for many bars. F11 is SOFT already, so
    // reactive fast-MA exits fit its tighter risk profile.
    if(g_last_signal==0||!InpUseEarlyExit||g_entry_atr<=0)return;
    int bars_live=g_current_bar-g_entry_bar;
    if(bars_live<InpEarlyExit_ArmBars)return;
    if(!g_last_entry_was_f3){
        double gap=MathAbs(g_ema_fast-g_sma_slow);
        if(gap<InpEarlyExit_MinGapATR*g_entry_atr)return;
    }
    double px=(InpEarlyExit_Trigger==EXIT_ON_TOUCH)
        ?((g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK))
        :iClose(_Symbol,_Period,1);
    bool ex=(g_last_signal==1&&px<=g_ema_fast)||(g_last_signal==-1&&px>=g_ema_fast);
    if(!ex)return;
    double p=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(InpIndicatorOnly){DrawExitMarker(TimeCurrent(),p,"FMA-X");ArmReentry(g_last_signal,"FMA-X");g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;}
    else if(EAClose("FMA-X")){DrawExitMarker(TimeCurrent(),p,"FMA-X");ArmReentry(g_last_signal,"FMA-X");g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;}
    else Print("[FMA-X] close FAILED");
}

// === v13.9.4/v13.9.5 — PROGRESSIVE EXIT ===
// Three phases:
//   Phase 0 (v13.9.5)  — first InpPE_Phase0Bars bars after entry. Exit level
//                         is fast EMA shifted by InpPE_Phase0BufferATR × ATR
//                         AWAY from price (below for BUY, above for SELL),
//                         giving the trade room to develop while fast MA is
//                         still close to entry. Without Phase 0, an early tick
//                         could close the trade prematurely.
//   Phase 1            — once Phase 0 expires, exit at fast EMA touch/close
//                         (the protective stop the user originally requested).
//   Phase 2            — after TP[InpPE_BEPAfterTP] hits, SL line snaps to
//                         entry price ("SL+" / BEP). Continues to monitor for
//                         retrace back through entry. Overrides Phase 0/1.
//
// The function is safe to call on every tick and on every new bar; it gates
// internally on InpPE_Trigger so the right side runs in the right layer.
// Phase-2 arming runs unconditionally so the BEP line locks immediately when
// the configured TP prints, regardless of trigger mode.

// Bars elapsed since the EA opened the current position. Returns 0 when
// entry is on the live forming bar; increments each time a new bar opens.
int PEBarsSinceEntry(){
    if(g_pe_entry_time <= 0) return 0;
    int shift = iBarShift(_Symbol, _Period, g_pe_entry_time, false);
    return (shift < 0) ? 0 : shift;
}

void ProcessProgressiveExit(bool new_bar){
    if(!InpUsePE) return;
    if(g_last_signal==0) return;
    if(g_entry_price<=0) return;            // position not fully opened yet

    // Phase resolution
    int lock_idx = InpPE_BEPAfterTP - 1;
    if(lock_idx < 0)        lock_idx = 0;
    if(lock_idx >= MAX_TP)  lock_idx = MAX_TP - 1;
    bool phase2 = g_tp_hit[lock_idx];

    int  bars_since = PEBarsSinceEntry();
    int  p0_limit   = MathMax(0, InpPE_Phase0Bars);
    bool phase0     = (!phase2 && bars_since < p0_limit);

    // Phase-2 latch — runs whether or not we end up triggering an exit on
    // this call, so the visual SL line "snaps" to BEP the moment the
    // configured TP prints.
    if(phase2 && !g_pe_bep_armed){
        g_pe_bep_armed = true;
        g_sl_price     = g_entry_price;
        ApplyBrokerStopLoss("PE-BEP-LOCK");  // no-op when broker SL conditions are not met
        Print("[PE-BEP] TP",InpPE_BEPAfterTP," hit — SL moved to BEP ",DoubleToString(g_entry_price,_Digits));
    }

    // Trigger-mode gating
    if(InpPE_Trigger==EXIT_ON_TOUCH){
        if(new_bar) return;                  // TOUCH mode runs on tick only
    } else {
        if(!new_bar) return;                 // CANDLE_CLOSE mode runs on new-bar only
    }

    double trigger_px;
    if(InpPE_Trigger==EXIT_ON_TOUCH){
        trigger_px = (g_last_signal==1) ? SymbolInfoDouble(_Symbol,SYMBOL_BID)
                                        : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    } else {
        trigger_px = iClose(_Symbol,_Period,1);
    }

    double exit_level;
    string reason;
    if(phase2){
        exit_level = g_entry_price;
        reason     = "PE-BEP";
    } else if(phase0){
        // Phase 0 buffer — fast EMA shifted away from price by N × ATR.
        double atr_use = (g_atr_val > 0) ? g_atr_val : (g_entry_atr > 0 ? g_entry_atr : 0);
        double buffer  = MathMax(0.0, InpPE_Phase0BufferATR) * atr_use;
        if(buffer <= 0) buffer = _Point * 50.0;   // safety fallback when ATR unavailable
        exit_level = (g_last_signal==1) ? (g_ema_fast - buffer) : (g_ema_fast + buffer);
        reason     = "PE-P0";
    } else {
        exit_level = g_ema_fast;
        reason     = "PE-FAST";
    }

    bool trigger = (g_last_signal==1) ? (trigger_px <= exit_level)
                                      : (trigger_px >= exit_level);
    if(!trigger) return;

    Print("[",reason,"] ",(g_last_signal==1?"BUY":"SELL"),
          " bars=",bars_since,
          " px=",DoubleToString(trigger_px,_Digits),
          " level=",DoubleToString(exit_level,_Digits));

    double p = (g_last_signal==1) ? SymbolInfoDouble(_Symbol,SYMBOL_BID)
                                  : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(InpIndicatorOnly){
        DrawExitMarker(TimeCurrent(),p,reason);
        g_last_signal=0; g_sl_forced=false; g_ssl_phase=0;
    } else if(EAClose(reason)){
        DrawExitMarker(TimeCurrent(),p,reason);
        g_last_signal=0; g_sl_forced=false; g_ssl_phase=0;
    } else {
        Print("[",reason,"] close FAILED");
    }
}

void UpdatePeakTracking(){
    if(g_last_signal==0)return;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    if(g_last_signal==1){if(price>g_peak_price){g_peak_price=price;g_peak_bar=g_current_bar;}}
    else{if(price<g_peak_price||g_peak_price==0){g_peak_price=price;g_peak_bar=g_current_bar;}}
}

void CheckAdaptiveReversal(bool tick_level){
    if(g_last_signal==0||!InpUseAdaptiveReversal||g_entry_atr<=0||g_peak_price==0)return;
    double price=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    double pullback=(g_last_signal==1)?(g_peak_price-price):(price-g_peak_price);
    if(pullback<InpAdapt_PullbackATR*g_entry_atr)return;
    int bars_since=g_current_bar-g_peak_bar;
    bool is_fast=(bars_since<InpAdapt_FastBars);
    if(tick_level&&!is_fast)return; if(!tick_level&&is_fast)return;
    string cr=is_fast?"ADAPT_FAST":"ADAPT_SLOW", mk=is_fast?"ADPT-F":"ADPT-S";
    if(InpIndicatorOnly){DrawExitMarker(TimeCurrent(),price,mk);ArmReentry(g_last_signal,"ADAPT");g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;}
    else if(EAClose(cr)){DrawExitMarker(TimeCurrent(),price,mk);ArmReentry(g_last_signal,"ADAPT");g_last_signal=0;g_sl_forced=false;g_ssl_phase=0;}
    else Print("[ADAPT] close FAILED");
}

// === RE-ENTRY ===
void ArmReentry(int dir, string reason){
    if(g_awaiting_reentry&&g_reentry_dir!=dir)
        Print("[REENTRY-CANCEL] old=",(g_reentry_dir==1?"BUY":"SELL")," superseded by ",(dir==1?"BUY":"SELL")," ",reason);
    g_reentry_dir=dir;g_reentry_reason=reason;
    g_awaiting_reentry=UseClassicReentry();
    if(UseClassicReentry())Print("[REENTRY-ARMED] ",(dir==1?"BUY":"SELL")," reason=",reason);
    if(UseRetest()){
        g_retest_armed=true;g_retest_dir=dir;g_retest_counter=InpRetestBars;g_retest_seen_pullback=false;
        Print("[RETEST-ARMED] ",(dir==1?"BUY":"SELL")," bars=",InpRetestBars);
    }
}

void ProcessRetestReentry(){
    if(!UseRetest()||!g_retest_armed||g_last_signal!=0)return;
    if(g_retest_counter<=0){g_retest_armed=false;g_retest_dir=0;return;}
    g_retest_counter--;
    bool aligned_opp=(g_retest_dir==1&&g_ema_fast<g_sma_slow)||(g_retest_dir==-1&&g_ema_fast>g_sma_slow);
    if(aligned_opp){Print("[RETEST] Cancelled — MA cross opposite");g_retest_armed=false;g_retest_dir=0;g_retest_seen_pullback=false;return;}
    bool aligned=(g_retest_dir==1&&g_ema_fast>g_sma_slow)||(g_retest_dir==-1&&g_ema_fast<g_sma_slow);
    double dist=MathAbs(g_ema_fast-g_sma_slow)/_Point;
    if(dist<InpGapPoints*2&&!g_retest_seen_pullback){g_retest_seen_pullback=true;Print("[RETEST] Pullback seen");}
    if(g_retest_seen_pullback&&aligned&&PreCheckMarketConditions()){
        bool pipe_ok=EvaluatePipeline(g_retest_dir);
        if(pipe_ok&&!g_pipe_hard){
            Print("[RETEST] Pattern confirmed — entering ",(g_retest_dir==1?"BUY":"SELL"));
            // Treat retest re-entry as SOFT — same "RE-ENTRY" white label class.
            int rdir=g_retest_dir;
            SetupTrade(rdir,true);EAOpen(rdir);
            if(g_last_signal!=0){
                DrawSignalLabel(rdir,iTime(_Symbol,_Period,0),iClose(_Symbol,_Period,1),SC_REENTRY);
                DrawTPSLLines();
            }
            g_retest_armed=false;g_retest_seen_pullback=false;
        }
    }
}

// === EA TRADE FUNCTIONS ===
void EAOpen(int dir){
    if(InpIndicatorOnly||!g_license_valid)return;
    if(InpUseDailyLoss&&g_daily_blocked)return;
    if(InpUseDailyProfitStop&&g_daily_profit_blocked)return;
    if(HasActivePosition()){
        Print("[EA-OPEN] Existing position — closing before opening ",(dir==1?"BUY":"SELL"));
        if(!EAClose("PRE-OPEN")){Print("[EA-OPEN] ABORTED: close failed");return;}
        if(HasActivePosition()){Print("[EA-OPEN] ABORTED: position still present after close");return;}
    }
    // Reset F3-origin flag here. ProcessF3Recovery sets it back to
    // true if this open was triggered by F3 — but only AFTER EAOpen returns,
    // so a normal entry path here correctly clears any stale tag.
    g_last_entry_was_f3 = false;
    g_pe_bep_armed = false;                       // v13.9.4
    g_pe_entry_time = iTime(_Symbol,_Period,0);   // v13.9.5: anchor Phase-0 timer to entry bar
    double lot=CalcLot();g_initial_lot=lot;g_closed_lot_total=0;ResetSmartTPState();
    g_stp1_lot_per=(InpSTP1_Pct/100.0)*lot*0.50;
    MqlTradeRequest req={};MqlTradeResult res={};
    req.action=TRADE_ACTION_DEAL;req.symbol=_Symbol;req.volume=lot;
    req.type=(dir==1)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
    req.price=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
    req.sl=BrokerStopLossPrice();req.tp=0;req.deviation=InpEASlippage;req.magic=InpEAMagic;
    req.comment="DT13 "+(dir==1?"BUY":"SELL");
    long fl=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
    if((fl&SYMBOL_FILLING_IOC)!=0)req.type_filling=ORDER_FILLING_IOC;
    else if((fl&SYMBOL_FILLING_FOK)!=0)req.type_filling=ORDER_FILLING_FOK;
    else req.type_filling=ORDER_FILLING_RETURN;
    if(OrderSend(req,res)&&(res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED)){
        g_ea_ticket=res.order;g_consec_loss=0;
        Sleep(50);
        int actual=GetActivePositionDir();
        if(actual==dir){
            Print("[EA-OPEN] OK ",(dir==1?"BUY":"SELL")," ticket=",res.order," lot=",DoubleToString(lot,2)," brokerSL=",DoubleToString(req.sl,_Digits));
            ApplyBrokerStopLoss("POST-OPEN");
        } else {
            Print("[EA-OPEN] SERVER NOT CONFIRMED expected=",(dir==1?"BUY":"SELL")," actual=",actual," retcode=",res.retcode);
            g_last_signal=actual;
            if(actual==0){ResetRuntimeTradeState(true);}else{BuildFallbackTradeFromPosition(actual);}
        }
    } else {
        Print("[EA-OPEN] FAIL err=",GetLastError()," retcode=",res.retcode);
        ResetRuntimeTradeState(true);
    }
}

bool EAClose(string reason){
    if(InpIndicatorOnly)return true;
    bool ok=true;int max_r=3;
    for(int i=PositionsTotal()-1;i>=0;i--){
        ulong tk=PositionGetTicket(i);if(tk<=0)continue;
        if(PositionGetInteger(POSITION_MAGIC)!=InpEAMagic)continue;
        if(PositionGetString(POSITION_SYMBOL)!=_Symbol)continue;
        bool closed=false;
        double pf=PositionGetDouble(POSITION_PROFIT);
        for(int attempt=1;attempt<=max_r;attempt++){
            if(!PositionSelectByTicket(tk)){closed=true;break;}
            MqlTradeRequest r={};MqlTradeResult rs={};
            r.action=TRADE_ACTION_DEAL;r.position=tk;r.symbol=_Symbol;
            r.volume=PositionGetDouble(POSITION_VOLUME);
            r.type=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
            r.price=(r.type==ORDER_TYPE_SELL)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            r.deviation=InpEASlippage;r.magic=InpEAMagic;r.comment="DT13 "+reason;
            long fl=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
            if((fl&SYMBOL_FILLING_IOC)!=0)r.type_filling=ORDER_FILLING_IOC;
            else if((fl&SYMBOL_FILLING_FOK)!=0)r.type_filling=ORDER_FILLING_FOK;
            else r.type_filling=ORDER_FILLING_RETURN;
            bool sent=OrderSend(r,rs);
            if(sent&&(rs.retcode==TRADE_RETCODE_DONE||rs.retcode==TRADE_RETCODE_DONE_PARTIAL)){
                Sleep(50);
                if(!PositionSelectByTicket(tk)){
                    if(pf<0&&InpUseDailyLoss){g_daily_loss+=MathAbs(pf);if(g_daily_loss>=InpDailyLossLimit)g_daily_blocked=true;}
                    if(pf>0&&InpUseDailyProfitStop){g_daily_profit+=pf;if(g_daily_profit>=InpDailyProfitTarget)g_daily_profit_blocked=true;}
                    // Apply F3 cooldown when an F3-originated trade closes in loss.
                    if(g_last_entry_was_f3 && pf<0){
                        g_f3_cooldown_bars=InpF3_CooldownBars;
                        g_f3_loss_count++;
                        Print("[F3-COOLDOWN] losing F3 trade pf=",DoubleToString(pf,2),
                              " cooldown=",g_f3_cooldown_bars," bars (loss_total=",g_f3_loss_count,"/",g_f3_fire_count,")");
                    }
                    g_last_entry_was_f3 = false;
                    closed=true;if(attempt>1)Print("[CLOSE-RETRY] OK ticket=",tk," attempts=",attempt);break;
                }
                // DONE_PARTIAL or hedging/netting residual: keep retrying until the ticket disappears.
                Print("[CLOSE-VERIFY] ticket=",tk," still present after retcode=",rs.retcode," attempt=",attempt);
            } else {
                Print("[CLOSE-RETRY] FAIL ticket=",tk," attempt=",attempt,"/",max_r," err=",GetLastError()," retcode=",rs.retcode);
            }
            Sleep(80);
        }
        if(!closed){ok=false;Print("[CLOSE-FAILED] ticket=",tk," after ",max_r," retries; server position still present.");}
    }
    if(ok){g_ea_ticket=0;if(g_initial_lot>0)g_closed_lot_total=g_initial_lot;}
    return ok;
}

bool EAPartialClose(double vol,string label){
    if(InpIndicatorOnly)return false;
    for(int i=PositionsTotal()-1;i>=0;i--){
        ulong tk=PositionGetTicket(i);
        if(tk>0&&PositionGetInteger(POSITION_MAGIC)==InpEAMagic&&PositionGetString(POSITION_SYMBOL)==_Symbol){
            double pv=PositionGetDouble(POSITION_VOLUME);
            double pf_before=PositionGetDouble(POSITION_PROFIT);
            double mn=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
            if(g_initial_lot<=0)g_initial_lot=pv;
            if(StringFind(label,"STP") == 0 && (!RuntimeDirMatchesPosition() || PositionGetDouble(POSITION_PROFIT) <= 0.0)){
                Print("[PARTIAL-SAFETY] ",label," rejected because server direction mismatches runtime or position is not in profit");
                return false;
            }
            if(StringFind(label,"SSL") == 0 && !UseSmartSL()){
                Print("[PARTIAL-SAFETY] ",label," rejected because Smart SL is retired/disabled");
                return false;
            }
            double remaining_allowance=g_initial_lot-g_closed_lot_total;
            if(remaining_allowance<=mn*0.5){
                Print("[PARTIAL-SAFETY] ",label," rejected because closed-volume guard reached initial lot");
                return false;
            }
            if(vol<mn)vol=mn;
            vol=MathMin(vol,remaining_allowance);
            vol=NormalizeLot(vol);
            if(vol>=pv)return false;
            MqlTradeRequest r={};MqlTradeResult rs={};
            r.action=TRADE_ACTION_DEAL;r.position=tk;r.symbol=_Symbol;r.volume=vol;
            r.type=(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
            r.price=(r.type==ORDER_TYPE_SELL)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            r.deviation=InpEASlippage;r.magic=InpEAMagic;r.comment="DT13 "+label;
            long fl=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
            if((fl&SYMBOL_FILLING_IOC)!=0)r.type_filling=ORDER_FILLING_IOC;
            else if((fl&SYMBOL_FILLING_FOK)!=0)r.type_filling=ORDER_FILLING_FOK;
            else r.type_filling=ORDER_FILLING_RETURN;
            bool sent=OrderSend(r,rs);
            if(!(sent&&(rs.retcode==TRADE_RETCODE_DONE||rs.retcode==TRADE_RETCODE_DONE_PARTIAL))){
                Print("[EA ERROR] Partial ",label," failed err=",GetLastError()," retcode=",rs.retcode);
                return false;
            }
            Sleep(50);
            double after=0.0;
            if(PositionSelectByTicket(tk))after=PositionGetDouble(POSITION_VOLUME);
            double closed=MathMax(0.0,pv-after);
            if(closed<=0.0){
                Print("[PARTIAL-VERIFY] ",label," retcode=",rs.retcode," but server volume did not decrease. before=",DoubleToString(pv,2)," after=",DoubleToString(after,2));
                return false;
            }
            g_closed_lot_total=MathMin(g_initial_lot,g_closed_lot_total+closed);
            if(pf_before>0&&InpUseDailyProfitStop&&pv>0){
                g_daily_profit+=pf_before*(closed/pv);
                if(g_daily_profit>=InpDailyProfitTarget)g_daily_profit_blocked=true;
            }
            Print("[EA] ",label," partial requested=",DoubleToString(vol,2)," closed=",DoubleToString(closed,2)," total=",DoubleToString(g_closed_lot_total,2),"/",DoubleToString(g_initial_lot,2));
            return true;
        }
    }
    return false;
}

void CheckLateEntry(){
    if(InpIndicatorOnly||!UseLateEntry()||g_last_signal==0||g_entry_price<=0||g_entry_atr<=0)return;
    for(int i=PositionsTotal()-1;i>=0;i--)
        if(PositionGetTicket(i)>0&&PositionGetInteger(POSITION_MAGIC)==InpEAMagic&&PositionGetString(POSITION_SYMBOL)==_Symbol)return;
    double cp=(g_last_signal==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
    if(MathAbs(cp-g_entry_price)/g_entry_atr<=InpLateEntryATR){SendAlert("LATE ENTRY");EAOpen(g_last_signal);}
}

void SendAlert(string msg){
    if(InpAlertPopup)Alert(msg);if(InpAlertSound)PlaySound("alert2.wav");
    if(InpAlertPush)SendNotification(_Symbol+" "+EnumToString(_Period)+": "+msg);
}


// === VISUALS ===
void DrawExitMarker(datetime t,double p,string r){
    string n=ObjName("EXIT_"+IntegerToString((long)t)+"_"+r);
    ObjectCreate(0,n,OBJ_TEXT,0,t,p);ObjectSetString(0,n,OBJPROP_TEXT,"x "+r);
    ObjectSetInteger(0,n,OBJPROP_COLOR,clrYellow);ObjectSetInteger(0,n,OBJPROP_FONTSIZE,8);
    ObjectSetString(0,n,OBJPROP_FONT,"Arial");ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
}

// DrawDiagMarker: gray diagnostic markers for market-condition skips (? SPREAD / ? SESSION / ? DAILY)
void DrawDiagMarker(int dir,datetime t,double price,string reason){
    int bi=iBarShift(_Symbol,_Period,t);double a=g_atr_val>0?g_atr_val:5;
    string nm=ObjName("DIAG_"+reason+"_"+IntegerToString((long)t));
    string txt="? "+reason;
    double y=(dir==1)?((bi>=0)?iLow(_Symbol,_Period,bi)-a*0.8:price):((bi>=0)?iHigh(_Symbol,_Period,bi)+a*0.8:price);
    ObjectCreate(0,nm,OBJ_TEXT,0,t,y);ObjectSetString(0,nm,OBJPROP_TEXT,txt);
    ObjectSetInteger(0,nm,OBJPROP_COLOR,DB_CLR_GRAY);ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,9);
    ObjectSetString(0,nm,OBJPROP_FONT,"Arial");
    ObjectSetInteger(0,nm,(dir==1)?OBJPROP_ANCHOR:OBJPROP_ANCHOR,(dir==1)?ANCHOR_UPPER:ANCHOR_LOWER);
    ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

bool ShouldShowSignalVisual(ENUM_SIGNAL_CLASS sc){
    return (sc!=SC_BLOCKED || InpShowBlockedSignals);
}

void DeleteSignalVisualAt(datetime t){
    string ts=IntegerToString((long)t);
    ObjectDelete(0,ObjName("SIG_B_"+ts));
    ObjectDelete(0,ObjName("SIG_S_"+ts));
    ObjectDelete(0,ObjName("SIGBK_"+ts));
    ObjectDelete(0,ObjName("SIGBAR_"+ts));
}

// DrawSignalLabel: class-aware label (VALID / LIMITED / BLOCKED)
void DrawSignalLabel(int dir,datetime t,double price,ENUM_SIGNAL_CLASS sc){
    if(sc==SC_BLOCKED && !InpShowBlockedSignals){ DeleteSignalVisualAt(t); return; }
    int bi=iBarShift(_Symbol,_Period,t);double a=g_atr_val>0?g_atr_val:5;
    string txt; color clr;
    switch(sc){
        case SC_VALID:   txt=(dir==1?"^ BUY":"v SELL");      clr=(dir==1?InpBuyColor:InpSellColor); break;
        case SC_SOFT:    txt=(dir==1?"^ LIMITED BUY":"v LIMITED SELL"); clr=DB_CLR_YELLOW; break;
        case SC_BLOCKED: txt=(dir==1?"! BLOCKED BUY":"! BLOCKED SELL"); clr=DB_CLR_MAGENTA;break;  // v13.9.3
        case SC_REENTRY: txt=(dir==1?"^ RE-ENTRY BUY":"v RE-ENTRY SELL"); clr=DB_CLR_WHITE; break;
        case SC_REVERSAL: txt=(dir==1?"^ REV BUY":"v REV SELL"); clr=DB_CLR_CYAN; break;
        case SC_F3_RECOVERY: txt=(dir==1?"^ F3 BUY":"v F3 SELL"); clr=DB_CLR_ORANGE; break;
        default:         txt="?";                              clr=DB_CLR_GRAY; break;
    }
    string nm=ObjName(dir==1?"SIG_B_":"SIG_S_");
    nm+=IntegerToString((long)t);
    if(ObjectFind(0,nm)>=0){
        string old_txt=ObjectGetString(0,nm,OBJPROP_TEXT);
        // v13.11.33 — do not let stale BLOCKED labels survive a settings change.
        // When filters are disabled or a signal re-evaluates as VALID/LIMITED,
        // remove the old blocked object first so the current classification can
        // repaint the timestamp correctly during ScanHistory/live redraw.
        if(StringFind(old_txt,"BLOCKED")>=0 && sc!=SC_BLOCKED){
            ObjectDelete(0,nm);
        }
    }
    if(sc==SC_BLOCKED){
        string other_prefix=(dir==1?"SIG_S_":"SIG_B_");
        ObjectDelete(0,ObjName(other_prefix+IntegerToString((long)t)));
    }
    double offset=a*0.8;
    if(dir==1){
        double y=(bi>=0)?iLow(_Symbol,_Period,bi)-offset:price;
        ObjectCreate(0,nm,OBJ_TEXT,0,t,y);ObjectSetString(0,nm,OBJPROP_TEXT,txt);
        ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_UPPER);
    } else {
        double y=(bi>=0)?iHigh(_Symbol,_Period,bi)+offset:price;
        ObjectCreate(0,nm,OBJ_TEXT,0,t,y);ObjectSetString(0,nm,OBJPROP_TEXT,txt);
        ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_LOWER);
    }
    ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,10);
    ObjectSetString(0,nm,OBJPROP_FONT,"Arial Bold");ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nm,OBJPROP_HIDDEN,true);
}

void ColorSignalCandle(int dir,datetime t){
    int bi=iBarShift(_Symbol,_Period,t);if(bi<0)return;
    double op=iOpen(_Symbol,_Period,bi),cl=iClose(_Symbol,_Period,bi);
    double hi=iHigh(_Symbol,_Period,bi),lo=iLow(_Symbol,_Period,bi);
    datetime t0=iTime(_Symbol,_Period,bi),t1=t0+PeriodSeconds()-1;
    double bh=MathMax(op,cl),bl=MathMin(op,cl);if(MathAbs(bh-bl)<_Point)bh=bl+_Point*5;
    string nb=ObjName("SIGBK_"+IntegerToString((long)t));
    ObjectCreate(0,nb,OBJ_RECTANGLE,0,t0,bh,t1,bl);
    ObjectSetInteger(0,nb,OBJPROP_COLOR,clrBlack);ObjectSetInteger(0,nb,OBJPROP_FILL,true);
    ObjectSetInteger(0,nb,OBJPROP_BACK,false);ObjectSetInteger(0,nb,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nb,OBJPROP_HIDDEN,true);
    double pd=g_atr_val*0.05;string nl=ObjName("SIGBAR_"+IntegerToString((long)t));
    ObjectCreate(0,nl,OBJ_RECTANGLE,0,t0,hi+pd,t1,lo-pd);
    ObjectSetInteger(0,nl,OBJPROP_COLOR,(dir==1)?clrLime:clrRed);ObjectSetInteger(0,nl,OBJPROP_FILL,false);
    ObjectSetInteger(0,nl,OBJPROP_WIDTH,3);ObjectSetInteger(0,nl,OBJPROP_BACK,false);
    ObjectSetInteger(0,nl,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nl,OBJPROP_HIDDEN,true);
}

void ClearEMARibbonVisual(){
    for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--){
        string n=ObjectName(0,i,0,-1);
        if(StringFind(n,ObjName("EFILL1_"))==0 || StringFind(n,ObjName("EFILL2_"))==0
        || StringFind(n,ObjName("EF_"))==0 || StringFind(n,ObjName("ES_"))==0)
            ObjectDelete(0,n);
    }
}

// === EMA RIBBON ===
void DrawEMARibbon(){
    if(!InpShowCoreMALines){ ClearEMARibbonVisual(); return; }
    int bd=GetLazyVisualBars(_Period);if(bd<=0)return;
    double ef[],es[];ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);
    if(CopyBuffer(h_ema_fast,0,0,bd,ef)<bd)return;
    if(CopyBuffer(h_sma_slow,0,0,bd,es)<bd)return;
    for(int i=0;i<bd-1;i++){
        datetime t0=iTime(_Symbol,_Period,i),t1=iTime(_Symbol,_Period,i+1);
        color fc=(ef[i]>es[i])?C'0,80,40':C'80,20,20';
        string f1=ObjName("EFILL1_"+IntegerToString(i));
        if(ObjectFind(0,f1)<0)ObjectCreate(0,f1,OBJ_TRIANGLE,0,t0,ef[i],t1,ef[i+1],t1,es[i+1]);
        ObjectSetDouble(0,f1,OBJPROP_PRICE,0,ef[i]);ObjectSetDouble(0,f1,OBJPROP_PRICE,1,ef[i+1]);ObjectSetDouble(0,f1,OBJPROP_PRICE,2,es[i+1]);
        ObjectSetInteger(0,f1,OBJPROP_TIME,0,t0);ObjectSetInteger(0,f1,OBJPROP_TIME,1,t1);ObjectSetInteger(0,f1,OBJPROP_TIME,2,t1);
        ObjectSetInteger(0,f1,OBJPROP_COLOR,fc);ObjectSetInteger(0,f1,OBJPROP_FILL,true);ObjectSetInteger(0,f1,OBJPROP_BACK,true);
        ObjectSetInteger(0,f1,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,f1,OBJPROP_HIDDEN,true);
        string f2=ObjName("EFILL2_"+IntegerToString(i));
        if(ObjectFind(0,f2)<0)ObjectCreate(0,f2,OBJ_TRIANGLE,0,t0,ef[i],t1,es[i+1],t0,es[i]);
        ObjectSetDouble(0,f2,OBJPROP_PRICE,0,ef[i]);ObjectSetDouble(0,f2,OBJPROP_PRICE,1,es[i+1]);ObjectSetDouble(0,f2,OBJPROP_PRICE,2,es[i]);
        ObjectSetInteger(0,f2,OBJPROP_TIME,0,t0);ObjectSetInteger(0,f2,OBJPROP_TIME,1,t1);ObjectSetInteger(0,f2,OBJPROP_TIME,2,t0);
        ObjectSetInteger(0,f2,OBJPROP_COLOR,fc);ObjectSetInteger(0,f2,OBJPROP_FILL,true);ObjectSetInteger(0,f2,OBJPROP_BACK,true);
        ObjectSetInteger(0,f2,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,f2,OBJPROP_HIDDEN,true);
        string nf=ObjName("EF_"+IntegerToString(i));
        if(ObjectFind(0,nf)<0)ObjectCreate(0,nf,OBJ_TREND,0,t1,ef[i+1],t0,ef[i]);
        else{ObjectSetDouble(0,nf,OBJPROP_PRICE,0,ef[i+1]);ObjectSetDouble(0,nf,OBJPROP_PRICE,1,ef[i]);
            ObjectSetInteger(0,nf,OBJPROP_TIME,0,t1);ObjectSetInteger(0,nf,OBJPROP_TIME,1,t0);}
        ObjectSetInteger(0,nf,OBJPROP_COLOR,clrRed);ObjectSetInteger(0,nf,OBJPROP_WIDTH,2);
        ObjectSetInteger(0,nf,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,nf,OBJPROP_RAY_LEFT,false);
        ObjectSetInteger(0,nf,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nf,OBJPROP_HIDDEN,true);ObjectSetInteger(0,nf,OBJPROP_BACK,true);
        string ns=ObjName("ES_"+IntegerToString(i));
        if(ObjectFind(0,ns)<0)ObjectCreate(0,ns,OBJ_TREND,0,t1,es[i+1],t0,es[i]);
        else{ObjectSetDouble(0,ns,OBJPROP_PRICE,0,es[i+1]);ObjectSetDouble(0,ns,OBJPROP_PRICE,1,es[i]);
            ObjectSetInteger(0,ns,OBJPROP_TIME,0,t1);ObjectSetInteger(0,ns,OBJPROP_TIME,1,t0);}
        ObjectSetInteger(0,ns,OBJPROP_COLOR,DB_CLR_CYAN);ObjectSetInteger(0,ns,OBJPROP_WIDTH,2);
        ObjectSetInteger(0,ns,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,ns,OBJPROP_RAY_LEFT,false);
        ObjectSetInteger(0,ns,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,ns,OBJPROP_HIDDEN,true);ObjectSetInteger(0,ns,OBJPROP_BACK,true);
    }
}

// UpdateVisualForSignal: compute TP/SL/entry for any signal (blocked, limited, or valid)
// and update g_visual_* so DrawTPSLLines can render the levels even without an open position.
void UpdateVisualForSignal(int dir,double entry_price,double atr,bool tight_mode){
    if(dir==0||atr<=0)return;
    double risk=atr*(tight_mode?InpSoft_SL_Mult:InpSL_Mult);
    double tp1_d,tp2_d;
    if(tight_mode){tp1_d=atr*InpSoft_TP1_Mult;tp2_d=tp1_d+atr*InpSoft_TP2_Mult;}
    else{tp1_d=atr*InpTP1_Mult;tp2_d=tp1_d+atr*InpTP1_to_TP2_Mult;}
    g_visual_signal=dir; g_visual_entry=entry_price;
    g_visual_sl=(dir==1)?entry_price-risk:entry_price+risk;
    g_visual_atr=atr; g_visual_tp_unlocked=5;
    g_visual_tp[0]=(dir==1)?entry_price+tp1_d:entry_price-tp1_d;
    g_visual_tp[1]=(dir==1)?entry_price+tp2_d:entry_price-tp2_d;
    for(int i=2;i<MAX_TP;i++){
        double sd=(i-1)*atr*InpTP_Step_Mult;
        g_visual_tp[i]=(dir==1)?g_visual_tp[1]+sd:g_visual_tp[1]-sd;
    }
    for(int i=0;i<MAX_TP;i++)g_visual_tp_hit[i]=false;
}

void ClearTPSLEntryLines(){
    ObjectDelete(0,ObjName("ENTRY_LINE"));ObjectDelete(0,ObjName("SL_LINE"));
    ObjectDelete(0,ObjName("ENTRY_LBL"));ObjectDelete(0,ObjName("SL_LBL"));
    for(int i=0;i<MAX_TP;i++){
        ObjectDelete(0,ObjName("TP"+IntegerToString(i+1)+"_L"));
        ObjectDelete(0,ObjName("TP"+IntegerToString(i+1)+"_LBL"));
    }
}

// === TP/SL LINES ===
void DrawTPSLLines(){
    if(!InpShowTPSLEntryLines){ ClearTPSLEntryLines(); return; }
    double de,ds,da;int dd,du;bool uv=false;
    if(g_last_signal!=0){dd=g_last_signal;de=g_entry_price;ds=g_sl_price;da=g_entry_atr;du=g_tp_unlocked;}
    else if(g_visual_signal!=0){dd=g_visual_signal;de=g_visual_entry;ds=g_visual_sl;da=g_visual_atr;du=g_visual_tp_unlocked;uv=true;}
    else{ ClearTPSLEntryLines(); return; }
    datetime tl=iTime(_Symbol,_Period,0)+PeriodSeconds()*3;double lo=da*0.08;
    string ne=ObjName("ENTRY_LINE");if(ObjectFind(0,ne)<0)ObjectCreate(0,ne,OBJ_HLINE,0,0,de);
    ObjectSetDouble(0,ne,OBJPROP_PRICE,de);ObjectSetInteger(0,ne,OBJPROP_COLOR,uv?C'80,80,160':InpEntryColor);
    ObjectSetInteger(0,ne,OBJPROP_WIDTH,2);ObjectSetInteger(0,ne,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,ne,OBJPROP_HIDDEN,true);
    string nel=ObjName("ENTRY_LBL");if(ObjectFind(0,nel)<0)ObjectCreate(0,nel,OBJ_TEXT,0,tl,de+lo);
    ObjectMove(0,nel,0,tl,de+lo);ObjectSetString(0,nel,OBJPROP_TEXT,"ENTRY: "+DoubleToString(de,_Digits));
    ObjectSetInteger(0,nel,OBJPROP_COLOR,uv?C'80,80,160':InpEntryColor);ObjectSetInteger(0,nel,OBJPROP_FONTSIZE,9);
    ObjectSetString(0,nel,OBJPROP_FONT,DB_FONT_NM);ObjectSetInteger(0,nel,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
    ObjectSetInteger(0,nel,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nel,OBJPROP_HIDDEN,true);
    string ns=ObjName("SL_LINE");if(ObjectFind(0,ns)<0)ObjectCreate(0,ns,OBJ_HLINE,0,0,ds);
    ObjectSetDouble(0,ns,OBJPROP_PRICE,ds);ObjectSetInteger(0,ns,OBJPROP_COLOR,InpSellColor);
    ObjectSetInteger(0,ns,OBJPROP_WIDTH,2);ObjectSetInteger(0,ns,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,ns,OBJPROP_HIDDEN,true);
    string nsl=ObjName("SL_LBL");if(ObjectFind(0,nsl)<0)ObjectCreate(0,nsl,OBJ_TEXT,0,tl,ds+lo);
    ObjectMove(0,nsl,0,tl,ds+lo);ObjectSetString(0,nsl,OBJPROP_TEXT,"SL: "+DoubleToString(ds,_Digits));
    ObjectSetInteger(0,nsl,OBJPROP_COLOR,InpSellColor);ObjectSetInteger(0,nsl,OBJPROP_FONTSIZE,9);
    ObjectSetString(0,nsl,OBJPROP_FONT,DB_FONT_NM);ObjectSetInteger(0,nsl,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
    ObjectSetInteger(0,nsl,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nsl,OBJPROP_HIDDEN,true);
    for(int i=0;i<MAX_TP;i++){
        string nt=ObjName("TP"+IntegerToString(i+1)+"_L");string ntl=ObjName("TP"+IntegerToString(i+1)+"_LBL");
        if(i>=du){ObjectDelete(0,nt);ObjectDelete(0,ntl);continue;}
        double tp=uv?g_visual_tp[i]:g_tp[i];bool th=uv?g_visual_tp_hit[i]:g_tp_hit[i];
        color clr=th?CLR_TP_HIT:(i<2)?clrLime:(i<5)?C'0,150,0':(i<10)?clrGold:clrOrange;
        if(ObjectFind(0,nt)<0)ObjectCreate(0,nt,OBJ_HLINE,0,0,tp);
        ObjectSetDouble(0,nt,OBJPROP_PRICE,tp);ObjectSetInteger(0,nt,OBJPROP_COLOR,clr);
        ObjectSetInteger(0,nt,OBJPROP_WIDTH,1);ObjectSetInteger(0,nt,OBJPROP_STYLE,(i<2)?STYLE_SOLID:STYLE_DASH);
        ObjectSetInteger(0,nt,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nt,OBJPROP_HIDDEN,true);
        if(ObjectFind(0,ntl)<0)ObjectCreate(0,ntl,OBJ_TEXT,0,tl,tp+lo);
        ObjectMove(0,ntl,0,tl,tp+lo);ObjectSetString(0,ntl,OBJPROP_TEXT,"TP"+IntegerToString(i+1)+": "+DoubleToString(tp,_Digits)+(th?" *":""));
        ObjectSetInteger(0,ntl,OBJPROP_COLOR,clr);ObjectSetInteger(0,ntl,OBJPROP_FONTSIZE,(i<10)?9:7);
        ObjectSetString(0,ntl,OBJPROP_FONT,DB_FONT_NM);ObjectSetInteger(0,ntl,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
        ObjectSetInteger(0,ntl,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,ntl,OBJPROP_HIDDEN,true);
    }
}


// Historical F3 audit for blocked signals. Returns true when a later candle
// breaks the blocked signal candle in the original direction and all selected
// F3 guards still pass. This is visual-only and never arms runtime state.
bool FindF3RecoveryAt(int block_idx,int dir,datetime &rt,double &rp){
    if(!InpF3_UseRecovery||InpF3_RecoveryBars<=0)return false;
    double ah[1];if(CopyBuffer(h_atr,0,block_idx,1,ah)<=0||ah[0]<=0)return false;
    // Historical scan must respect InpF3_OnlyF0Blocks the same way live ArmF3Recovery does.
    if(InpF3_OnlyF0Blocks){
        if(InpGap_Action==F_OFF) return false;        // F0 not active — no F0 block possible
        double ef0[1],es0[1];
        if(CopyBuffer(h_ema_fast,0,block_idx,1,ef0)<=0
        || CopyBuffer(h_sma_slow,0,block_idx,1,es0)<=0) return false;
        double gap_pts = MathAbs(ef0[0]-es0[0])/_Point;
        double thr_f0;
        if(InpGap_UseATRPct && ah[0]>0)
            thr_f0 = (ah[0]/_Point) * InpGap_ATRPct / 100.0;
        else
            thr_f0 = (double)InpGapPoints;
        if(gap_pts >= thr_f0) return false;           // F0 didn't trigger at this bar
    }
    // Refuse historical F3 recovery when F2 (cross-distance) was the blocker at block_idx.
    if(InpF3_BlockOnF2 && InpF2_Action != F_OFF){
        if(EvalF2At(block_idx)) return false;
    }
    double bh=iHigh(_Symbol,_Period,block_idx)+InpF3_BreakBufferATR*ah[0];
    double bl=iLow (_Symbol,_Period,block_idx)-InpF3_BreakBufferATR*ah[0];
    // cross_px at block_idx for the recovery distance gate.
    double cross_px = 0, cross_atr = 0;
    bool has_cross = ComputeCrossPriceLI(block_idx, cross_px, cross_atr);
    int last=MathMax(1,block_idx-InpF3_RecoveryBars);
    for(int b=block_idx-1;b>=last;b--){
        if(InpF3_RequireMAAligned){
            double ef[1],es[1];
            if(CopyBuffer(h_ema_fast,0,b,1,ef)<=0||CopyBuffer(h_sma_slow,0,b,1,es)<=0)continue;
            bool aligned=(dir==1&&ef[0]>es[0])||(dir==-1&&ef[0]<es[0]);
            if(!aligned)continue;
        }
        if(InpF3_RequireDIDirection&&h_adx!=INVALID_HANDLE){
            double dp[1],dm[1];
            if(CopyBuffer(h_adx,1,b,1,dp)>0&&CopyBuffer(h_adx,2,b,1,dm)>0){
                if(dir==1&&dp[0]<=dm[0])continue;
                if(dir==-1&&dm[0]<=dp[0])continue;
            }
        }
        if(!F3RangeOkAt(b))continue;
        double px=(InpF3_Trigger==EXIT_ON_TOUCH)?((dir==1)?iHigh(_Symbol,_Period,b):iLow(_Symbol,_Period,b)):iClose(_Symbol,_Period,b);
        bool broke=(dir==1)?(px>=bh):(px<=bl);
        if(!broke)continue;
        // Recovery price must stay within InpF3_MaxDistATR × ATR of the original cross price.
        if(has_cross && InpF3_MaxDistATR > 0.0){
            if(MathAbs(px - cross_px) > InpF3_MaxDistATR * cross_atr) continue;
        }
        rt=iTime(_Symbol,_Period,b);rp=px;return true;
    }
    return false;
}

// Hide the BLOCKED label at the original block bar when F3 has recovered the signal.
void HideBlockedLabelForF3(int sig, datetime block_time){
    string prefix = (sig == 1) ? "SIG_B_" : "SIG_S_";
    string name = ObjName(prefix + IntegerToString((long)block_time));
    if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
}

// Orange vertical marker at the F3 recovery bar (OBJ_TREND segment scoped
// to the candle's high/low ± padding).
void DrawF3RecoveryVLine(datetime rt){
    int bi = iBarShift(_Symbol, _Period, rt);
    double hi, lo;
    if(bi >= 0){
        hi = iHigh(_Symbol, _Period, bi);
        lo = iLow (_Symbol, _Period, bi);
    } else {
        // Fallback to live ATR span around the trigger price when iBarShift
        // can't resolve the bar (extreme history, missing data).
        double a = (g_atr_val > 0) ? g_atr_val : _Point * 50;
        hi = lo = 0; hi += a; lo -= a;
    }
    double pad = (g_atr_val > 0) ? g_atr_val * 0.10 : _Point * 5;
    string name = ObjName("F3VLINE_" + IntegerToString((long)rt));
    if(ObjectFind(0, name) < 0)
        ObjectCreate(0, name, OBJ_TREND, 0, rt, hi + pad, rt, lo - pad);
    else {
        ObjectMove(0, name, 0, rt, hi + pad);
        ObjectMove(0, name, 1, rt, lo - pad);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR,        DB_CLR_ORANGE);
    ObjectSetInteger(0, name, OBJPROP_STYLE,        STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_WIDTH,        2);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,    false);
    ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,     false);
    ObjectSetInteger(0, name, OBJPROP_BACK,         true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE,   false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN,       true);
}

void DrawF3RecoveryTPSL(int dir, datetime rt, double rp, double atr){
    if(atr <= 0) return;
    bool soft = InpF3_EnterAsSoft;
    double risk  = atr * (soft ? InpSoft_SL_Mult  : InpSL_Mult);
    double tp1_d = atr * (soft ? InpSoft_TP1_Mult : InpTP1_Mult);
    double tp2_d = tp1_d + atr * (soft ? InpSoft_TP2_Mult : InpTP1_to_TP2_Mult);
    double sl_px  = (dir==1) ? rp - risk  : rp + risk;
    double tp1_px = (dir==1) ? rp + tp1_d : rp - tp1_d;
    double tp2_px = (dir==1) ? rp + tp2_d : rp - tp2_d;
    datetime t2   = rt + 30 * PeriodSeconds();

    // v13.9.13 — only draw if the hypothetical F11 trade is still "open":
    // walk the bars from recovery+1 to current bar 1 and bail out if either
    // the final TP (TP2) or the SL was reached. This stops past-and-done
    // recoveries from painting a permanent cluster of dotted lines.
    int rt_idx = iBarShift(_Symbol, _Period, rt);
    if(rt_idx > 1){
        for(int b = rt_idx - 1; b >= 1; b--){
            double bh = iHigh(_Symbol, _Period, b);
            double bl = iLow (_Symbol, _Period, b);
            bool hit;
            if(dir == 1) hit = (bl <= sl_px) || (bh >= tp2_px);
            else         hit = (bh >= sl_px) || (bl <= tp2_px);
            if(hit) return;
        }
    }

    string base = "F3LINE_" + IntegerToString((long)rt);

    // Entry
    string n_en = ObjName(base + "_EN");
    if(ObjectFind(0, n_en) < 0) ObjectCreate(0, n_en, OBJ_TREND, 0, rt, rp, t2, rp);
    ObjectSetInteger(0, n_en, OBJPROP_COLOR, InpEntryColor);
    ObjectSetInteger(0, n_en, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, n_en, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, n_en, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, n_en, OBJPROP_BACK, true);
    ObjectSetInteger(0, n_en, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, n_en, OBJPROP_HIDDEN, true);

    // SL
    string n_sl = ObjName(base + "_SL");
    if(ObjectFind(0, n_sl) < 0) ObjectCreate(0, n_sl, OBJ_TREND, 0, rt, sl_px, t2, sl_px);
    ObjectSetInteger(0, n_sl, OBJPROP_COLOR, clrCrimson);
    ObjectSetInteger(0, n_sl, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, n_sl, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, n_sl, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, n_sl, OBJPROP_BACK, true);
    ObjectSetInteger(0, n_sl, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, n_sl, OBJPROP_HIDDEN, true);

    // TP1
    string n_t1 = ObjName(base + "_TP1");
    if(ObjectFind(0, n_t1) < 0) ObjectCreate(0, n_t1, OBJ_TREND, 0, rt, tp1_px, t2, tp1_px);
    ObjectSetInteger(0, n_t1, OBJPROP_COLOR, clrLimeGreen);
    ObjectSetInteger(0, n_t1, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, n_t1, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, n_t1, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, n_t1, OBJPROP_BACK, true);
    ObjectSetInteger(0, n_t1, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, n_t1, OBJPROP_HIDDEN, true);

    // TP2
    string n_t2 = ObjName(base + "_TP2");
    if(ObjectFind(0, n_t2) < 0) ObjectCreate(0, n_t2, OBJ_TREND, 0, rt, tp2_px, t2, tp2_px);
    ObjectSetInteger(0, n_t2, OBJPROP_COLOR, clrLimeGreen);
    ObjectSetInteger(0, n_t2, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, n_t2, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, n_t2, OBJPROP_RAY_RIGHT, false);
    ObjectSetInteger(0, n_t2, OBJPROP_BACK, true);
    ObjectSetInteger(0, n_t2, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, n_t2, OBJPROP_HIDDEN, true);
}

// === SCAN HISTORY ===
void ScanHistory(){
    int total=Bars(_Symbol,_Period),scan=MathMin(total-InpSMA_Slow-5,MathMax(200,MathMin(InpStartupScanBars,4000)));
    if(scan<3)return;Print("[SCAN] ",scan," bars...");
    int sc=0,sc_blocked=0,sc_soft=0;
    ENUM_SQUEEZE_STATE sq_save_state=g_sq_state; double sq_save_hi=g_sq_range_high, sq_save_lo=g_sq_range_low; string sq_save_reason=g_sq_reason;
    int est_save_dir=g_est_dir; double est_save_band=g_est_band; bool est_save_noisy=g_est_noisy; string est_save_state=g_est_state;
    int last_dir=0; double last_entry=0, last_atr=0; bool last_tight=false;
    ENUM_SIGNAL_CLASS last_cls=SC_BLOCKED;
    bool has_last=false;
    double vis_tp[MAX_TP]; bool vis_hit[MAX_TP]; int vis_unlock=5; double vis_sl=0;
    ArrayInitialize(vis_tp,0);ArrayInitialize(vis_hit,false);

    for(int i=scan;i>=1;i--){
        int sig=DetectSignalAt(i);if(sig==0)continue;
        datetime st=iTime(_Symbol,_Period,i);double sp=iClose(_Symbol,_Period,i);
        double ah[1];if(CopyBuffer(h_atr,0,i,1,ah)<=0)continue;
        double sv=g_atr_val;g_atr_val=ah[0];sc++;
        double ef_b[1],es_b[1];
        if(CopyBuffer(h_ema_fast,0,i,1,ef_b)>0&&CopyBuffer(h_sma_slow,0,i,1,es_b)>0)
            g_last_signal_gap_pts=MathAbs(ef_b[0]-es_b[0])/_Point;

        bool hard=false, soft=false;
        EvaluatePipelineAt(i,sig,hard,soft);

        // v13.11.0 — combine filter class with regime class (harshest wins).
        // ComputeRegimeAt(i, ...) evaluates regime at the historical bar so
        // the label history matches what would have been live at that bar.
        ENUM_SIGNAL_CLASS filter_cls = hard ? SC_BLOCKED : (soft ? SC_SOFT : SC_VALID);
        ENUM_SIGNAL_CLASS sc_class = filter_cls;
        if(sc_class==SC_BLOCKED) sc_blocked++;
        else if(sc_class==SC_SOFT) sc_soft++;

        DrawSignalLabel(sig,st,sp,sc_class);
        if(ShouldShowSignalVisual(sc_class)) ColorSignalCandle(sig,st);
        // F3 recovery scan still uses the FILTER-level hard flag — regime
        // blocks (e.g. CHOPPY) are not eligible for F3 false-block recovery.
        if(hard){
            datetime rt=0;double rp=0;
            if(FindF3RecoveryAt(i,sig,rt,rp)){
                // v13.9.16 — remove the BLOCKED label at the original signal
                // bar and add a vertical orange line at the F11 recovery bar.
                // v13.9.19 — the "? F11" DrawDiagMarker was just clipping
                // behind the orange F11 label at the same bar; removed.
                HideBlockedLabelForF3(sig, st);
                DrawSignalLabel(sig,rt,rp,SC_F3_RECOVERY);
                DrawF3RecoveryTPSL(sig,rt,rp,ah[0]);
                DrawF3RecoveryVLine(rt);
            }
        }

        has_last=true;last_dir=sig;last_entry=sp;last_atr=ah[0];
        last_cls=sc_class;
        // v13.11.0 — tight TP/SL only when FILTER is SOFT. Regime-only SOFT
        // (RANGING/LONG_RANGING/EARLY_BR labels) keeps normal TP/SL per user
        // spec: "perlakuan tetap regime rules" — regime affects the label,
        // not the TP/SL multiplier.
        last_tight=false;

        // ScanHistory must never arm runtime trading state. It only prepares
        // optional visual TP/SL levels for the last non-blocked historical
        // signal. Skip visual draw whenever combined class is BLOCKED so
        // regime-CHOPPY history doesn't show phantom TP lines.
        if(sc_class!=SC_BLOCKED){
            double risk=ah[0]*(last_tight?InpSoft_SL_Mult:InpSL_Mult);
            vis_sl=(sig==1)?sp-risk:sp+risk;
            double tp1_d=ah[0]*(last_tight?InpSoft_TP1_Mult:InpTP1_Mult);
            double tp2_d=tp1_d+ah[0]*(last_tight?InpSoft_TP2_Mult:InpTP1_to_TP2_Mult);
            vis_tp[0]=(sig==1)?sp+tp1_d:sp-tp1_d;
            vis_tp[1]=(sig==1)?sp+tp2_d:sp-tp2_d;
            for(int t=2;t<MAX_TP;t++){double sd=(t-1)*ah[0]*InpTP_Step_Mult;vis_tp[t]=(sig==1)?vis_tp[1]+sd:vis_tp[1]-sd;}
            for(int t=0;t<MAX_TP;t++)vis_hit[t]=false;
            for(int b=i-1;b>=0;b--)for(int t=0;t<MAX_TP;t++){
                if(vis_hit[t])continue;
                if(sig==1&&iHigh(_Symbol,_Period,b)>=vis_tp[t])vis_hit[t]=true;
                if(sig==-1&&iLow(_Symbol,_Period,b)<=vis_tp[t])vis_hit[t]=true;
            }
            vis_unlock=5;if(vis_hit[4])vis_unlock=10;if(vis_hit[9])vis_unlock=20;if(vis_hit[19])vis_unlock=30;
        }
        g_atr_val=sv;
    }
    Print("[SCAN] ",sc," crossovers | VALID=",(sc-sc_blocked-sc_soft)," LIMITED=",sc_soft," BLOCKED=",sc_blocked);

    ResetRuntimeTradeState(true);
    if(has_last&&last_cls!=SC_BLOCKED){
        g_visual_signal=last_dir;g_visual_entry=last_entry;g_visual_sl=vis_sl;
        g_visual_atr=last_atr;g_visual_tp_unlocked=vis_unlock;
        for(int i=0;i<MAX_TP;i++){g_visual_tp[i]=vis_tp[i];g_visual_tp_hit[i]=vis_hit[i];}
    } else {
        ClearVisualTradeState();
    }
    g_entry_bar=g_current_bar;g_bars_in_trade=0;
    g_sq_state=sq_save_state; g_sq_range_high=sq_save_hi; g_sq_range_low=sq_save_lo; g_sq_reason=sq_save_reason;
    g_est_dir=est_save_dir; g_est_band=est_save_band; g_est_noisy=est_save_noisy; g_est_state=est_save_state;
}

// === DASHBOARD HELPERS ===
void DrawDR(string id,int row,string label,string value,color vc,int yb){
    int y=yb-row*DB_LINE_H;
    string nl=ObjName("DB_L_"+id);ObjectCreate(0,nl,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,nl,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,nl,OBJPROP_XDISTANCE,DB_X);
    ObjectSetInteger(0,nl,OBJPROP_YDISTANCE,y);ObjectSetString(0,nl,OBJPROP_TEXT,label);
    ObjectSetInteger(0,nl,OBJPROP_COLOR,DB_CLR_WHITE);ObjectSetString(0,nl,OBJPROP_FONT,DB_FONT_NM);
    ObjectSetInteger(0,nl,OBJPROP_FONTSIZE,DB_FONT_SZ);ObjectSetInteger(0,nl,OBJPROP_BACK,false);
    ObjectSetInteger(0,nl,OBJPROP_ZORDER,200);
    ObjectSetInteger(0,nl,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nl,OBJPROP_HIDDEN,true);
    string nv=ObjName("DB_V_"+id);ObjectCreate(0,nv,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,nv,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,nv,OBJPROP_XDISTANCE,DB_PANEL_W-10);
    ObjectSetInteger(0,nv,OBJPROP_YDISTANCE,y);ObjectSetString(0,nv,OBJPROP_TEXT,value);
    ObjectSetInteger(0,nv,OBJPROP_COLOR,vc);ObjectSetString(0,nv,OBJPROP_FONT,DB_FONT_NM);
    ObjectSetInteger(0,nv,OBJPROP_FONTSIZE,DB_FONT_SZ);ObjectSetInteger(0,nv,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
    ObjectSetInteger(0,nv,OBJPROP_BACK,false);ObjectSetInteger(0,nv,OBJPROP_ZORDER,200);
    ObjectSetInteger(0,nv,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nv,OBJPROP_HIDDEN,true);
}
void DrawDH(string id,int row,string label,string value,color bgc,color tc,int yb){
    int y=yb-row*DB_LINE_H;
    string nb=ObjName("DB_B_"+id);ObjectCreate(0,nb,OBJ_RECTANGLE_LABEL,0,0,0);
    ObjectSetInteger(0,nb,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,nb,OBJPROP_XDISTANCE,3);
    ObjectSetInteger(0,nb,OBJPROP_YDISTANCE,y+3);ObjectSetInteger(0,nb,OBJPROP_XSIZE,DB_PANEL_W-6);
    ObjectSetInteger(0,nb,OBJPROP_YSIZE,DB_LINE_H);ObjectSetInteger(0,nb,OBJPROP_BGCOLOR,bgc);
    ObjectSetInteger(0,nb,OBJPROP_BORDER_TYPE,BORDER_FLAT);ObjectSetInteger(0,nb,OBJPROP_BORDER_COLOR,bgc);
    ObjectSetInteger(0,nb,OBJPROP_BACK,false);ObjectSetInteger(0,nb,OBJPROP_ZORDER,150);
    ObjectSetInteger(0,nb,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nb,OBJPROP_HIDDEN,true);
    string nl=ObjName("DB_L_"+id);ObjectCreate(0,nl,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,nl,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,nl,OBJPROP_XDISTANCE,DB_X);
    ObjectSetInteger(0,nl,OBJPROP_YDISTANCE,y);ObjectSetString(0,nl,OBJPROP_TEXT,label);
    ObjectSetInteger(0,nl,OBJPROP_COLOR,tc);ObjectSetString(0,nl,OBJPROP_FONT,DB_FONT_NM);
    ObjectSetInteger(0,nl,OBJPROP_FONTSIZE,DB_FONT_SZ);ObjectSetInteger(0,nl,OBJPROP_BACK,false);
    ObjectSetInteger(0,nl,OBJPROP_ZORDER,200);
    ObjectSetInteger(0,nl,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nl,OBJPROP_HIDDEN,true);
    string nv=ObjName("DB_V_"+id);ObjectCreate(0,nv,OBJ_LABEL,0,0,0);
    ObjectSetInteger(0,nv,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,nv,OBJPROP_XDISTANCE,DB_PANEL_W-10);
    ObjectSetInteger(0,nv,OBJPROP_YDISTANCE,y);ObjectSetString(0,nv,OBJPROP_TEXT,value);
    ObjectSetInteger(0,nv,OBJPROP_COLOR,tc);ObjectSetString(0,nv,OBJPROP_FONT,DB_FONT_NM);
    ObjectSetInteger(0,nv,OBJPROP_FONTSIZE,DB_FONT_SZ);ObjectSetInteger(0,nv,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
    ObjectSetInteger(0,nv,OBJPROP_BACK,false);ObjectSetInteger(0,nv,OBJPROP_ZORDER,200);
    ObjectSetInteger(0,nv,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nv,OBJPROP_HIDDEN,true);
}

// Per-filter dashboard row helper: shows action letter + state + color
void DrawFilterRow(string id,int row,string label,ENUM_FILTER_ACTION action,bool triggered,string state_val,int yb){
    string act_str=(action==F_OFF?"OFF":"ON");
    string full_label=label+" ["+act_str+"]";
    color vc;
    if(action==F_OFF)vc=DB_CLR_GRAY;
    else if(!triggered)vc=DB_CLR_GREEN;
    else if(action==F_SOFT)vc=DB_CLR_YELLOW;
    else vc=DB_CLR_RED;
    string val_str=(action==F_OFF?"---":state_val);
    DrawDR(id,row,full_label,val_str,vc,yb);
}

// === DASHBOARD (31 rows) ===
void DrawDashboard(bool force){
    EnsureDashboardButton();
    static uint lms=0;uint now=GetTickCount();
    if(!force&&now-lms<500)return;lms=now;
    if(!g_dash_visible){
        for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--){string n=ObjectName(0,i,0,-1);if(StringFind(n,OBJ_PREFIX+"DB_")==0)ObjectDelete(0,n);}return;
    }
    int nr=28,ph=(nr+1)*DB_LINE_H+DB_Y_BASE+8;
    string bg=ObjName("DB_BG");ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
    ObjectSetInteger(0,bg,OBJPROP_CORNER,DB_CORNER);ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,2);
    ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,2+ph);ObjectSetInteger(0,bg,OBJPROP_XSIZE,DB_PANEL_W);
    ObjectSetInteger(0,bg,OBJPROP_YSIZE,ph);ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,DB_BG_COLOR);
    ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);ObjectSetInteger(0,bg,OBJPROP_BORDER_COLOR,DB_BG_BORDER);
    ObjectSetInteger(0,bg,OBJPROP_BACK,false);   // v13.9.18 — keep panel above chart objects
    ObjectSetInteger(0,bg,OBJPROP_ZORDER,100);
    ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,bg,OBJPROP_HIDDEN,true);

    int row=0,yb=ph-DB_Y_BASE;
    DrawDH("CTIME",row++,"Candle",GetCandleTimer(),DB_CLR_BG_TIME,DB_CLR_CYAN,yb);
    MqlDateTime sv;TimeToStruct(TimeCurrent(),sv);
    DrawDH("STIME",row++,"Server",StringFormat("%02d:%02d:%02d",sv.hour,sv.min,sv.sec),DB_CLR_BG_TIME,DB_CLR_WHITE,yb);
    MqlDateTime lc;TimeToStruct(TimeLocal(),lc);
    DrawDH("LTIME",row++,"Local",StringFormat("%02d:%02d:%02d",lc.hour,lc.min,lc.sec),DB_CLR_BG_TIME,DB_CLR_WHITE,yb);
    string slow_tag=(InpSlowMA_Method==MODE_EMA?"EMA":InpSlowMA_Method==MODE_SMMA?"SMMA":InpSlowMA_Method==MODE_LWMA?"LWMA":"SMA");
    DrawDH("MA",row++,"EMA"+IntegerToString(InpEMA_Fast)+"/"+slow_tag+IntegerToString(InpSMA_Slow),
        g_ema_fast>g_sma_slow?"BULL":"BEAR",DB_CLR_BG_BLACK,g_ema_fast>g_sma_slow?DB_CLR_GREEN:DB_CLR_RED,yb);

    // Clean Core dashboard: only F2 + HTF context gate
    int n_hard=0;
    if(InpF2_Action!=F_OFF && g_f2_trig) n_hard++;
    int dash_sig=(g_last_signal==0?1:g_last_signal);
    bool htf_block = HTFContextBlocks(dash_sig, 1);
    bool est_block = EvasiveSTBlocks(dash_sig,1);
    bool slow_angle_block = SlowMAAngleBlocks(dash_sig,1);
    bool eci_trig = ECITriggered(1);
    bool eci_block = (InpECI_Action==F_HARD && eci_trig);
    bool side_block = SidewayBlocks(dash_sig,1);
    string atr_state=""; ENUM_FILTER_DECISION atr_dec=EvalATRHealthAt(1,atr_state);
    string sq_state="", sq_reason=""; ENUM_FILTER_DECISION sq_dec=EvalSqueezeGuard(dash_sig,1,sq_state,sq_reason);
    if(htf_block) n_hard++;
    if(est_block) n_hard++;
    if(slow_angle_block) n_hard++;
    if(eci_block) n_hard++;
    if(side_block) n_hard++;
    if(atr_dec==DEC_BLOCKED) n_hard++;
    if(sq_dec==DEC_BLOCKED) n_hard++;
    string fsum_val=IntegerToString(n_hard)+"H "+g_last_decision;
    color fsum_c=n_hard>0?DB_CLR_RED:DB_CLR_GREEN;
    DrawDR("FSUM",row++,"Filters",fsum_val,fsum_c,yb);

    DrawFilterRow("F2",row++,"F2 CrossDist",InpF2_Action,g_f2_trig,g_f2_trig?"FAR":"OK",yb);

    string htfv = StringFormat("H1=%s M15=%s RevOVR=%s", InpUseH1Bias?"ON":"OFF", InpUseM15Setup?"ON":"OFF", InpHTF_AllowReversalOverride?"ON":"OFF");
    DrawDR("HTF",row++,"HTF Gate", htf_block?"BLOCK":"PASS", htf_block?DB_CLR_RED:DB_CLR_GREEN, yb);
    DrawDR("HTFC",row++,"HTF Config", htfv, DB_CLR_CYAN, yb);
    DrawDR("EST",row++,"V-Line", (InpUseVLineGuard?(g_est_state+" "+EnumToString(InpVLine_TF)):"OFF"), !InpUseVLineGuard?DB_CLR_GRAY:(est_block?DB_CLR_RED:(g_est_dir>0?DB_CLR_GREEN:DB_CLR_ORANGE)), yb);
    DrawDR("SANG",row++,"SlowMA Angle", InpUseSlowMAAngleGuard?g_slowma_angle_state:"OFF", !InpUseSlowMAAngleGuard?DB_CLR_GRAY:(slow_angle_block?DB_CLR_RED:DB_CLR_GREEN), yb);
    DrawFilterRow("ECI",row++,"ECI v2 Entropy",InpECI_Action,eci_trig,g_eci_state,yb);
    DrawDR("ATRH",row++,"ATR Health", InpUseATRHealthGuard?atr_state:"OFF", !InpUseATRHealthGuard?DB_CLR_GRAY:(atr_dec==DEC_BLOCKED?DB_CLR_RED:(atr_dec==DEC_LIMITED?DB_CLR_YELLOW:DB_CLR_GREEN)), yb);
    DrawDR("SQ",row++,"Squeeze", SqueezeStateToString(g_sq_state)+" "+g_sq_reason, g_sq_state==SQ_ARMED||g_sq_state==SQ_FALSE_BREAK?DB_CLR_RED:(g_sq_state==SQ_BREAKOUT_UP||g_sq_state==SQ_BREAKOUT_DN?DB_CLR_YELLOW:DB_CLR_GRAY), yb);

    // Spike SL
    DrawDR("SPKA",row++,"Spike ATRMult",InpUseSpikeSL?DoubleToString(InpSpike_ATR_Mult,1)+"x":"OFF",InpUseSpikeSL?DB_CLR_WHITE:DB_CLR_GRAY,yb);
    DrawDR("ATR",row++,"ATR",DoubleToString(g_atr_val,2),DB_CLR_WHITE,yb);
    int sp2=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
    DrawDR("SPR",row++,"Spread",IntegerToString(sp2),sp2<=InpMax_Spread?DB_CLR_GREEN:DB_CLR_RED,yb);
    DrawDH("SIG",row++,"Signal",g_last_signal==1?"BUY":g_last_signal==-1?"SELL":"NONE",
        g_last_signal==1?DB_CLR_BG_GREEN:g_last_signal==-1?DB_CLR_BG_RED:DB_CLR_BG_BLACK,clrWhite,yb);
    int tc=0;for(int t=0;t<g_tp_unlocked;t++)if(g_tp_hit[t])tc++;
    DrawDR("TP",row++,"TP Hit",IntegerToString(tc)+"/"+IntegerToString(g_tp_unlocked),tc>0?DB_CLR_GREEN:DB_CLR_GRAY,yb);
    string mtp=UseManualTPTarget()?("TP"+IntegerToString(InpManualTP_Target)+(InpManualTP_UsePartialSystem?" +partials":" full")):"OFF";
    DrawDR("MTP",row++,"Manual TP",mtp,UseManualTPTarget()?DB_CLR_CYAN:DB_CLR_GRAY,yb);
    string stp="P1:"+(InpSTP1_UseSubZones?IntegerToString(g_stp1_phase)+"/2":"OFF")+" P2:"+(InpSTP2_UseSubZones?IntegerToString(g_stp2_phase)+"/2":"OFF");
    if(InpSTP3_UsePartial&&g_stp3_armed)stp+=" P3:"+IntegerToString(g_stp3_highestTP);
    if(!InpSTP3_UsePartial)stp+=" P3:OFF";
    DrawDR("STP",row++,"Smart TP",stp,DB_CLR_CYAN,yb);
    string slSt=g_sl_forced?(g_soft_mode?"SOFT":"FORCED"):InpUseSL?"ON":"OFF";
    DrawDR("SLH",row++,"SL Hardline",slSt,g_sl_forced?DB_CLR_ORANGE:InpUseSL?DB_CLR_GREEN:DB_CLR_GRAY,yb);
    DrawDR("EE",row++,"Early Exit",InpUseEarlyExit?"ON":"OFF",InpUseEarlyExit?DB_CLR_GREEN:DB_CLR_GRAY,yb);
    DrawDR("AR",row++,"Adapt Rev",InpUseAdaptiveReversal?"ON":"OFF",InpUseAdaptiveReversal?DB_CLR_GREEN:DB_CLR_GRAY,yb);
    // v13.9.4 + v13.9.5 Progressive Exit
    string pe_val; color pe_c;
    if(!InpUsePE){
        pe_val="OFF"; pe_c=DB_CLR_GRAY;
    } else if(g_last_signal==0){
        pe_val=StringFormat("IDLE (P0=%db, BEP@TP%d)",InpPE_Phase0Bars,InpPE_BEPAfterTP);
        pe_c=DB_CLR_GRAY;
    } else if(g_pe_bep_armed){
        pe_val=StringFormat("P2 BEP@%s",DoubleToString(g_entry_price,_Digits));
        pe_c=DB_CLR_GREEN;
    } else {
        int bs = PEBarsSinceEntry();
        if(bs < InpPE_Phase0Bars){
            double atr_use=(g_atr_val>0)?g_atr_val:0;
            double buf = MathMax(0.0,InpPE_Phase0BufferATR) * atr_use;
            double lvl = (g_last_signal==1) ? (g_ema_fast - buf) : (g_ema_fast + buf);
            pe_val = StringFormat("P0 %d/%d fast%s%.1fx@%s",
                                  bs, InpPE_Phase0Bars,
                                  (g_last_signal==1?"-":"+"),
                                  InpPE_Phase0BufferATR,
                                  DoubleToString(lvl,_Digits));
            pe_c = DB_CLR_CYAN;
        } else {
            pe_val = StringFormat("P1 fast@%s",DoubleToString(g_ema_fast,_Digits));
            pe_c   = DB_CLR_YELLOW;
        }
    }
    DrawDR("PE",row++,"ProgExit",pe_val,pe_c,yb);
    // License (v13.4.0 LicenseClient state)
    color licc = !InpLicense_Enabled       ? DB_CLR_GRAY
               : !g_license_valid          ? DB_CLR_RED
               : g_license_grace_mode      ? DB_CLR_YELLOW
               : DB_CLR_GREEN;
    DrawDR("LIC",row++,"License",g_license_state_label,licc,yb);
    DrawDR("MODE",row++,"Mode",InpIndicatorOnly?"INDICATOR":"EA ACTIVE",InpIndicatorOnly?DB_CLR_YELLOW:DB_CLR_GREEN,yb);
}


// === MAIN OnTick ===
void OnTick(){
    // License gate (v13.4.1): when invalid, EVERY tick exits early after
    // repainting the UNAUTHORIZED overlay. No signal detection, no ribbon,
    // no dashboard, no Smart-TP — chart is fully locked. Existing positions
    // are NOT closed (deliberate — never trap user funds).
    if(LicenseIsBlocking()){
        LIC_NukeAllOtherObjects();
        LIC_DrawUnauthorizedOverlay();
        return;
    }
    int rt=Bars(_Symbol,_Period);if(rt<InpSMA_Slow+50)return;
    if(!g_history_done){
        g_history_done=true;g_current_bar=rt;
        DrawEMARibbon();DrawEvasiveSTVisual();ScanHistory();
        if(!InpIndicatorOnly)ReconcilePositionState();
        if(UseLateEntry()&&g_last_signal!=0&&HasActivePosition())CheckLateEntry();
        DrawTPSLLines();DrawDashboard(true);ChartRedraw();return;
    }
    datetime ct=iTime(_Symbol,_Period,0);bool nb=(ct!=g_last_bar_time);
    if(nb){g_last_bar_time=ct;g_current_bar++;}
    MqlDateTime mdt;TimeToStruct(TimeCurrent(),mdt);
    datetime td=StringToTime(IntegerToString(mdt.year)+"."+IntegerToString(mdt.mon)+"."+IntegerToString(mdt.day));
    if(td!=g_daily_date){
        g_daily_date=td;g_daily_loss=0;g_daily_profit=0;g_daily_blocked=false;g_daily_profit_blocked=false;
        // New trading day → reset trailing-DD circuit breaker
    }
    if(!ReadIndicators())return;
    if(!InpIndicatorOnly)ReconcilePositionState();

    // === TICK LAYER ===
    if(g_last_signal!=0)UpdatePeakTracking();
    if(g_last_signal!=0&&InpSL_HardlineTrigger==EXIT_ON_TOUCH)CheckHardSL();
    if(g_last_signal!=0&&InpEarlyExit_Trigger==EXIT_ON_TOUCH)CheckEarlyExitSlowMA();
    if(g_last_signal!=0)CheckSpikeSL();
    if(g_last_signal!=0)CheckAdaptiveReversal(true);
    CheckSessionEndExit();
    CheckTPHits();
    // v13.9.4: Progressive Exit tick-layer evaluation (TOUCH-mode and BEP latch)
    if(g_last_signal!=0&&InpUsePE)ProcessProgressiveExit(false);
    if(g_last_signal==0)ProcessF3Recovery(false);

    // Defensive re-entry state clear while position is active
    if(g_last_signal!=0){
        if(g_awaiting_reentry){g_awaiting_reentry=false;g_reentry_dir=0;g_reentry_reason="";}
        if(g_retest_armed){g_retest_armed=false;g_retest_dir=0;g_retest_counter=0;g_retest_seen_pullback=false;}
    }

    // === BAR CLOSE LAYER ===
    if(nb){
        if(g_last_signal!=0)CheckAdaptiveReversal(false);
        if(g_last_signal!=0&&InpEarlyExit_Trigger==EXIT_ON_CANDLE_CLOSE)CheckEarlyExitSlowMA();
        // v13.9.4: Progressive Exit bar-close evaluation (CANDLE_CLOSE mode)
        if(g_last_signal!=0&&InpUsePE)ProcessProgressiveExit(true);
        if(g_last_signal!=0&&InpSL_HardlineTrigger==EXIT_ON_CANDLE_CLOSE)CheckHardSL();
        if(g_last_signal!=0)CheckMaxBars();
        if(g_last_signal==0)ProcessF3Recovery(true);

        int sig=DetectSignal();
        if(sig!=0){
            datetime st=iTime(_Symbol,_Period,1);
            double sp=iClose(_Symbol,_Period,1);
            // Capture EMA-fast vs slow gap AT THE SIGNAL BAR (not live).
            // F0 evaluates against this number, dashboard displays this number.
            g_last_signal_gap_pts=MathAbs(g_ema_fast-g_sma_slow)/_Point;

            // Indicator-only mode has no real server position, so reverse
            // signals must reset virtual runtime direction to avoid stale
            // SELL/BUY state sticking on dashboard/TP-SL visuals.
            if(InpIndicatorOnly && g_last_signal!=0 && sig!=g_last_signal){
                DrawSignalLabel(sig,st,sp,SC_REVERSAL);
                ColorSignalCandle(sig,st);
                ResetRuntimeTradeState(true);
            }

            // Close opposite position using server truth
            int cur_pos_dir=GetActivePositionDir();
            if(cur_pos_dir!=0&&sig!=cur_pos_dir){
                // Always show the opposite raw cross as a REV signal marker first.
                // Even if the broker/server close confirmation fails, the chart keeps
                // a visible BUY/SELL reversal reference for manual exit review.
                DrawSignalLabel(sig,st,sp,SC_REVERSAL);
                ColorSignalCandle(sig,st);
                double ep=(cur_pos_dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                DrawExitMarker(TimeCurrent(),ep,"REV");
                SendAlert("REV: "+(cur_pos_dir==1?"BUY>SELL":"SELL>BUY"));
                if(!InpIndicatorOnly){
                    if(!EAClose("REVERSE")){
                        Print("[REV] CRITICAL close failed — aborting new entry.");
                        DrawEMARibbon();DrawEvasiveSTVisual();g_dashboard_dirty=true;DrawTPSLLines();
                        if(g_dashboard_dirty){DrawDashboard(false);g_dashboard_dirty=false;}
                        return;
                    }
                }
                ResetRuntimeTradeState(true);
            }

            // No duplicate suppression — filters decide validity. An opposite-direction
            // crossing already closed the position via REV above. A same-direction
            // crossing still evaluates filters for dashboard/chart feedback; physical
            // entry is guarded below by g_last_signal==0.
            if(!PreCheckMarketConditions()){
                // Market condition block — draw diagnostic marker
                int cur_sp=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
                string reason=cur_sp>InpMax_Spread?"SPREAD":(InpUseSession?"SESSION":"DAILY");
                DrawDiagMarker(sig,st,sp,reason);
                Print("[SKIP-MARKET] ",(sig==1?"BUY":"SELL")," blocked: ",reason);
            } else {
                // Evaluate filter pipeline
                bool pipe_ok=EvaluatePipeline(sig);

                // v13.11.0 — chart label = harshest(filter_class, regime_class).
                // Entry/exit branches still use g_pipe_hard/g_pipe_soft (filter
                // pipeline including regime block), so behavior is unchanged
                // when regime is OFF or when regime status matches filter.
                ENUM_SIGNAL_CLASS live_label = g_pipe_hard ? SC_BLOCKED : (g_pipe_soft ? SC_SOFT : SC_VALID);

                if(pipe_ok&&!g_pipe_hard){
                    // VALID per filter pipeline. Label may be SOFT if regime is
                    // RANGING/LONG_RANGING/EARLY_BR — entry still proceeds with
                    // normal TP/SL because regime rules don't dictate TP/SL.
                    g_last_decision="V";
                    DrawSignalLabel(sig,st,sp,live_label);
                    if(ShouldShowSignalVisual(live_label)) ColorSignalCandle(sig,st);
                    UpdateVisualForSignal(sig,sp,g_atr_val,false);
                    if(g_last_signal==0){
                        SetupTrade(sig,false);EAOpen(sig);DrawTPSLLines();
                    }
                } else {
                    // HARD BLOCKED (filter or regime) — label only, no entry/TP/SL
                    // lines. Combined class is BLOCKED here regardless of which
                    // side triggered the block.
                    g_last_decision="B";
                    DrawSignalLabel(sig,st,sp,live_label);
                    if(ShouldShowSignalVisual(live_label)) ColorSignalCandle(sig,st);
                    if(g_last_signal==0){
                        ClearVisualTradeState();
                        DrawTPSLLines();
                        // Identify which filter caused the BLOCK so F3 reason is specific.
                        string breason;
                        if(g_f2_trig) breason="F2";
                        else if(HTFContextBlocks(sig,1)) breason="HTF";
                        else if(EvasiveSTBlocks(sig,1)) breason="V_LINE";
                        else if(SlowMAAngleBlocks(sig,1)) breason="SLOW_ANGLE";
                        else if(ECITriggered(1) && InpECI_Action==F_HARD) breason="ECI";
                        else if(SidewayBlocks(sig,1)) breason="SIDEWAY";
                        else breason="FILTER";
                        ArmF3Recovery(sig,st,breason);
                        if(UseClassicReentry()){
                            ArmReentry(sig,"BLOCKED");
                            Print("[BLOCKED] ",(sig==1?"BUY":"SELL")," — hard filter blocked, re-entry armed");
                        }
                    }
                }
            }
        }

        // Standard re-entry check
        if(g_awaiting_reentry&&g_last_signal==0&&UseClassicReentry()){
            bool aligned=(g_reentry_dir==1&&g_ema_fast>g_sma_slow)||(g_reentry_dir==-1&&g_ema_fast<g_sma_slow);
            if(!aligned){
                Print("[REENTRY-CANCEL] ",g_reentry_dir==1?"BUY":"SELL"," MA no longer aligned");
                g_awaiting_reentry=false;g_reentry_dir=0;g_reentry_reason="";
            } else if(!PreCheckMarketConditions()){
                Print("[REENTRY-HOLD] market conditions");
            } else {
                bool pipe_ok=EvaluatePipeline(g_reentry_dir);
                if(!pipe_ok||g_pipe_hard){
                    Print("[REENTRY-HOLD] pipeline blocked");
                } else {
                    bool momentum_ok=true;
                    if(InpReentryRequireMomentum){
                        double op1=iOpen(_Symbol,_Period,1),cl1=iClose(_Symbol,_Period,1);
                        momentum_ok=(g_reentry_dir==1)?(cl1>op1):(cl1<op1);
                        if(!momentum_ok)Print("[REENTRY-HOLD] momentum not confirmed");
                    }
                    if(momentum_ok){
                        Print("[REENTRY-FIRE] ",(g_reentry_dir==1?"BUY":"SELL")," after=",g_reentry_reason);
                        // Re-entry is always treated as SOFT: forced Smart-SL, tight TP/SL,
                        // white "RE-ENTRY" chart label.
                        int rdir=g_reentry_dir;
                        SetupTrade(rdir,true);EAOpen(rdir);
                        if(g_last_signal!=0){
                            DrawSignalLabel(rdir,iTime(_Symbol,_Period,1),iClose(_Symbol,_Period,1),SC_REENTRY);
                            DrawTPSLLines();
                        }
                        g_awaiting_reentry=false;g_reentry_dir=0;g_reentry_reason="";
                    }
                }
            }
        }

        ProcessRetestReentry();
        DrawEMARibbon();DrawEvasiveSTVisual();g_dashboard_dirty=true;
    }
    DrawTPSLLines();
    if(g_dashboard_dirty){DrawDashboard(false);g_dashboard_dirty=false;}
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
    if(id==CHARTEVENT_OBJECT_CLICK&&sparam==ObjName("DASH_BTN")){
        g_dash_visible=!g_dash_visible;
        EnsureDashboardButton();
        DrawDashboard(true);
        ChartRedraw();
    }
    if(id==CHARTEVENT_CHART_CHANGE){
        DrawEMARibbon();
        DrawEvasiveSTVisual();
        ChartRedraw();
    }
}
