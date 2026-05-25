# Dachi Trader EA — Clean Core M5 Primary Plan for Codex

## Tujuan Dokumen

Dokumen ini adalah instruksi implementasi untuk Codex agar EA Dachi Trader dibersihkan menjadi versi **Clean Core** yang lebih sederhana, mudah diuji, dan tidak terlalu banyak memblokir sinyal bagus.

Target utama:

1. **Hapus semua legacy entry filter kecuali F2 Crossing-to-Entry Distance.**
2. **Hapus IF / Intelligent Filter dari entry pipeline.**
3. **Hapus Market Regime dari entry pipeline dan label classification.**
4. **Hapus sistem SOFT / LIMITED mode untuk TP/SL.**
5. **Gunakan hanya dua hasil sinyal utama: VALID dan BLOCKED.**
6. **Entry utama berada di timeframe M5.**
7. **H1 dan M15 hanya digunakan sebagai bias/setup, bukan tempat entry.**
8. **M1 tidak digunakan pada versi ini.**
9. **ScanHistory harus tetap berjalan dan menampilkan sinyal mana yang VALID dan mana yang BLOCKED.**
10. **Exit system dirapikan dengan Progressive Exit sebagai exit utama.**

---

# 1. Filosofi Strategi

## 1.1 Masalah Versi Sebelumnya

Versi EA sebelumnya terlalu banyak memiliki filter yang dapat memblokir sinyal secara independen. Akibatnya, satu filter saja tidak setuju, sinyal langsung mati.

Masalah yang ingin diselesaikan:

```text
EMA crossing valid muncul
↓
F0 / F1 / F4 / F5 / IF / Regime / SOFT logic ikut menilai
↓
Sinyal bagus sering ikut ter-block
↓
EA terlihat tidak perform / terlalu pasif
```

Karena itu, versi Clean Core harus kembali ke prinsip sederhana:

```text
Core signal = EMA8 cross LWMA20
Main quality gate = F2 Crossing-to-Entry Distance
HTF context = H1 bias + M15 setup
Final decision = VALID or BLOCKED
```

---

# 2. Strategi Pilihan: M5 Primary Execution

## 2.1 Struktur Timeframe

Versi ini **tidak menggunakan M1**.

Struktur timeframe:

```text
H1  = trend bias utama
M15 = setup / struktur trend
M5  = execution timeframe / tempat entry
M1  = tidak digunakan
```

Artinya order hanya boleh dibuka berdasarkan sinyal yang muncul pada **M5 closed candle**.

---

## 2.2 Fungsi H1

H1 hanya menjawab:

```text
Market lebih aman BUY, SELL, atau NEUTRAL?
```

H1 tidak membuka entry.

### H1 BUY Bias

```text
Close H1 > EMA50
EMA20 > EMA50
EMA50 slope naik / tidak turun tajam
```

### H1 SELL Bias

```text
Close H1 < EMA50
EMA20 < EMA50
EMA50 slope turun / tidak naik tajam
```

### H1 NEUTRAL

```text
Harga bolak-balik di sekitar EMA50
EMA20 dan EMA50 terlalu dekat
EMA50 flat
```

Pada versi Clean Core awal, H1 bias boleh dibuat sebagai input:

```mq5
input bool InpUseH1Bias = true;
```

Jika `InpUseH1Bias = true`:

```text
H1 BUY  → hanya M5 BUY yang boleh entry
H1 SELL → hanya M5 SELL yang boleh entry
H1 NEUTRAL → block semua entry, atau allow hanya jika InpAllowNeutralBias = true
```

Rekomendasi default:

```mq5
input bool InpAllowNeutralBias = false;
```

---

## 2.3 Fungsi M15

M15 hanya menjawab:

```text
Apakah struktur market mendukung entry M5?
```

M15 tidak membuka entry.

### M15 BUY Setup

```text
Close M15 > EMA50
EMA20 > EMA50
Harga tidak breakdown di bawah EMA50
```

### M15 SELL Setup

```text
Close M15 < EMA50
EMA20 < EMA50
Harga tidak breakout di atas EMA50
```

Input:

```mq5
input bool InpUseM15Setup = true;
```

Jika `InpUseM15Setup = true`:

```text
M15 BUY structure  → hanya M5 BUY yang boleh lanjut
M15 SELL structure → hanya M5 SELL yang boleh lanjut
M15 neutral        → block, kecuali InpAllowM15Neutral = true
```

Rekomendasi default:

```mq5
input bool InpAllowM15Neutral = false;
```

---

## 2.4 Fungsi M5

M5 adalah tempat entry utama.

Entry BUY:

```text
M5 candle close
EMA8 cross up LWMA20
F2 distance pass
H1 bias mendukung
M15 setup mendukung
Operational guard pass
EA open BUY
```

Entry SELL:

```text
M5 candle close
EMA8 cross down LWMA20
F2 distance pass
H1 bias mendukung
M15 setup mendukung
Operational guard pass
EA open SELL
```

Penting:

```text
Gunakan bar yang sudah close: shift = 1.
Jangan gunakan candle berjalan: shift = 0.
```

---

# 3. Entry Filter Cleanup

## 3.1 Filter Yang Harus Dihapus Dari Entry Pipeline

Hapus seluruh legacy entry filter berikut dari live pipeline dan historical pipeline:

```text
F0 EMA Gap
F1 DI+/DI- Validation
F3 False-Block Recovery Entry
F4 Slow MA Direction
F5 RVI Overbought/Oversold
IF / Intelligent Filter
Market Regime gate
SOFT / LIMITED filter class logic
```

Yang dipertahankan hanya:

```text
F2 Crossing-to-Entry Distance
```

Operational guards tetap dipertahankan karena itu bukan entry-quality filter:

```text
Spread guard
Session guard
Daily loss guard
Daily profit stop
License guard
IndicatorOnly mode
Position already active guard
Max spread / slippage setting
```

---

## 3.2 Kenapa F2 Dipertahankan

F2 adalah filter paling penting untuk sistem EMA crossing.

Fungsi F2:

```text
Mencegah EA masuk ketika harga sudah terlalu jauh dari titik crossing.
```

Masalah yang dicegah:

```text
EMA cross terjadi jauh sebelumnya
↓
harga sudah bergerak terlalu jauh
↓
EA entry terlambat
↓
risk/reward buruk
```

F2 harus menjadi hard block:

```text
Jika distance dari close entry ke cross price > MaxDistATR × ATR
maka signal = BLOCKED
```

Rekomendasi default:

```mq5
input bool   InpUseF2Distance = true;
input double InpF2_MaxDistATR = 1.5;
```

Untuk M5 XAUUSD:

```text
Conservative: 1.2 ATR
Balanced:     1.5 ATR
Aggressive:   1.8 ATR
```

Default:

```text
InpF2_MaxDistATR = 1.5
```

---

# 4. Remove SOFT / LIMITED TP-SL Mode

## 4.1 Masalah SOFT Mode Lama

Versi lama memiliki konsep:

```text
VALID  → normal TP/SL
SOFT   → tighter TP/SL
BLOCKED → no trade
```

Masalahnya:

```text
1. User bingung kenapa ada LIMITED/SOFT.
2. TP/SL bisa berubah karena filter, bukan karena strategi utama.
3. ScanHistory bisa menampilkan LIMITED tetapi entry logic tetap tidak konsisten.
4. Banyak variabel g_soft_mode dan InpSoft_* membuat debugging lebih sulit.
```

Versi Clean Core harus menghapus konsep SOFT TP/SL.

---

## 4.2 Instruksi Penghapusan

Hapus atau pensiunkan penggunaan runtime berikut:

```text
g_soft_mode
InpSoft_SL_Mult
InpSoft_TP1_Mult
InpSoft_TP2_Mult
InpSoft_* lainnya jika ada
SC_SOFT / LIMITED usage pada entry decision
```

Jika menghapus `SC_SOFT` terlalu berisiko compile error karena banyak referensi visual, boleh sementara tetap biarkan enum-nya ada, tetapi jangan digunakan lagi dalam keputusan final.

Final decision hanya:

```mq5
enum ENUM_TRADE_DECISION
{
    DEC_VALID = 0,
    DEC_BLOCKED = 1
};
```

Atau kalau ingin tetap kompatibel dengan enum lama:

```text
SC_VALID   = valid entry signal
SC_BLOCKED = blocked entry signal
SC_SOFT    = deprecated, do not use
```

---

## 4.3 TP/SL Normal Saja

Semua trade menggunakan satu set TP/SL normal:

```text
SL = InpSL_Mult × ATR14
TP1 = InpTP1_Mult × ATR14
TP2 = InpTP2_Mult × ATR14
TP3 optional = InpTP3_Mult × ATR14
```

Jika current code belum punya `InpTP1_Mult` / `InpTP2_Mult` dalam bentuk sederhana, Codex boleh merapikan input menjadi:

```mq5
input double InpTP1_Mult = 1.0;
input double InpTP2_Mult = 1.8;
input double InpTP3_Mult = 2.5;
input double InpSL_Mult  = 1.25;
```

Default M5:

```text
SL  = 1.25 × ATR14
TP1 = 1.00 × ATR14
TP2 = 1.80 × ATR14
TP3 = 2.50 × ATR14
```

---

# 5. New Clean Decision Engine

## 5.1 Tujuan

Buat satu pusat keputusan agar live trading dan ScanHistory memakai logika yang sama.

Function utama:

```mq5
ENUM_TRADE_DECISION BuildTradeDecision(int sig, int shift, string &reason)
```

Parameter:

```text
sig    = 1 untuk BUY, -1 untuk SELL
shift  = candle index; live default = 1
reason = alasan final valid/block
```

Return:

```text
DEC_VALID
DEC_BLOCKED
```

---

## 5.2 Urutan Decision Engine

Urutan evaluasi:

```text
1. Operational guard
2. H1 bias
3. M15 setup
4. F2 distance
5. Final valid
```

Pseudocode:

```mq5
ENUM_TRADE_DECISION BuildTradeDecision(int sig, int shift, string &reason)
{
    reason = "OK";

    if(!OperationalGuardsPass(reason))
        return DEC_BLOCKED;

    if(InpUseH1Bias && !H1BiasAllows(sig, reason))
        return DEC_BLOCKED;

    if(InpUseM15Setup && !M15SetupAllows(sig, reason))
        return DEC_BLOCKED;

    if(InpUseF2Distance && EvalF2At(shift, sig))
    {
        reason = "F2_DISTANCE";
        return DEC_BLOCKED;
    }

    reason = "VALID";
    return DEC_VALID;
}
```

Catatan:

```text
EvalF2At() sebaiknya return true jika trigger/block.
Jika function lama memakai signature berbeda, sesuaikan tanpa mengubah prinsip.
```

---

## 5.3 Operational Guards

Operational guards boleh tetap hard block.

Contoh reason:

```text
SPREAD
SESSION
DAILY_LOSS
DAILY_PROFIT_STOP
LICENSE
INDICATOR_ONLY
POSITION_ACTIVE
TRADE_CONTEXT_BUSY
```

Function:

```mq5
bool OperationalGuardsPass(string &reason)
```

---

# 6. H1 Bias Implementation

## 6.1 Input

Tambahkan input:

```mq5
input bool InpUseH1Bias = true;
input ENUM_TIMEFRAMES InpBiasTF = PERIOD_H1;
input int InpBiasEMA_Fast = 20;
input int InpBiasEMA_Slow = 50;
input int InpBiasSlopeBars = 3;
input bool InpAllowNeutralBias = false;
```

---

## 6.2 Function

```mq5
enum ENUM_TF_BIAS
{
    TF_BIAS_NEUTRAL = 0,
    TF_BIAS_BUY = 1,
    TF_BIAS_SELL = -1
};
```

```mq5
ENUM_TF_BIAS GetH1Bias(int shift)
{
    // Read EMA20 and EMA50 from H1.
    // Use closed H1 candle.
    // BUY if EMA20 > EMA50 and close > EMA50.
    // SELL if EMA20 < EMA50 and close < EMA50.
    // Otherwise neutral.
}
```

```mq5
bool H1BiasAllows(int sig, string &reason)
{
    ENUM_TF_BIAS b = GetH1Bias(1);

    if(b == TF_BIAS_NEUTRAL)
    {
        if(InpAllowNeutralBias) return true;
        reason = "H1_NEUTRAL";
        return false;
    }

    if(sig == 1 && b != TF_BIAS_BUY)
    {
        reason = "H1_NOT_BUY";
        return false;
    }

    if(sig == -1 && b != TF_BIAS_SELL)
    {
        reason = "H1_NOT_SELL";
        return false;
    }

    return true;
}
```

---

# 7. M15 Setup Implementation

## 7.1 Input

```mq5
input bool InpUseM15Setup = true;
input ENUM_TIMEFRAMES InpSetupTF = PERIOD_M15;
input int InpSetupEMA_Fast = 20;
input int InpSetupEMA_Slow = 50;
input bool InpAllowM15Neutral = false;
```

---

## 7.2 Function

```mq5
ENUM_TF_BIAS GetM15Setup(int shift)
{
    // BUY setup:
    // close > EMA50 and EMA20 > EMA50
    // SELL setup:
    // close < EMA50 and EMA20 < EMA50
    // else neutral.
}
```

```mq5
bool M15SetupAllows(int sig, string &reason)
{
    ENUM_TF_BIAS s = GetM15Setup(1);

    if(s == TF_BIAS_NEUTRAL)
    {
        if(InpAllowM15Neutral) return true;
        reason = "M15_NEUTRAL";
        return false;
    }

    if(sig == 1 && s != TF_BIAS_BUY)
    {
        reason = "M15_NOT_BUY";
        return false;
    }

    if(sig == -1 && s != TF_BIAS_SELL)
    {
        reason = "M15_NOT_SELL";
        return false;
    }

    return true;
}
```

---

# 8. Live Entry Flow

## 8.1 OnTick Logic

Live entry hanya diproses pada candle M5 yang sudah close.

Jika EA dipasang pada M5 chart, gunakan `_Period == PERIOD_M5`.

Untuk versi ini, Codex boleh menambahkan guard:

```mq5
if(_Period != PERIOD_M5)
{
    // Do not trade. Dashboard should show: USE M5 CHART.
    return;
}
```

Atau jika ingin lebih fleksibel:

```mq5
input bool InpRequireM5Chart = true;
```

Default:

```text
InpRequireM5Chart = true
```

---

## 8.2 Entry Pseudocode

```mq5
void OnTick()
{
    // existing license / timer / dashboard logic may stay

    if(InpRequireM5Chart && _Period != PERIOD_M5)
    {
        DrawDashboardStatus("USE M5 CHART");
        return;
    }

    if(!IsNewBar())
    {
        ManageOpenPosition();
        return;
    }

    ManageOpenPosition();

    int sig = DetectSignalAt(1);
    if(sig == 0) return;

    string reason = "";
    ENUM_TRADE_DECISION d = BuildTradeDecision(sig, 1, reason);

    datetime t = iTime(_Symbol, _Period, 1);
    double price = iClose(_Symbol, _Period, 1);

    if(d == DEC_BLOCKED)
    {
        DrawSignalLabel(sig, t, price, SC_BLOCKED);
        DrawBlockReason(t, reason);
        return;
    }

    DrawSignalLabel(sig, t, price, SC_VALID);
    OpenTrade(sig);
}
```

---

# 9. ScanHistory Must Stay

## 9.1 Requirement

ScanHistory harus tetap berjalan saat EA attach / refresh / setting berubah.

Tujuannya:

```text
User dapat melihat sinyal historis mana yang VALID dan mana yang BLOCKED.
```

ScanHistory tidak boleh membuka posisi.

ScanHistory hanya visual dan audit.

---

## 9.2 Historical Decision Must Match Live Decision

Historical scan harus memakai function yang sama:

```mq5
BuildTradeDecision(sig, i, reason)
```

Jangan membuat logic terpisah untuk history.

Ini penting agar:

```text
Label historis = keputusan live yang sama pada candle tersebut
```

---

## 9.3 ScanHistory Pseudocode

```mq5
void ScanHistory()
{
    int total = Bars(_Symbol, _Period);
    int scan = MathMin(total - InpSMA_Slow - 5, 4000);
    if(scan < 3) return;

    int count_valid = 0;
    int count_blocked = 0;

    for(int i = scan; i >= 1; i--)
    {
        int sig = DetectSignalAt(i);
        if(sig == 0) continue;

        datetime t = iTime(_Symbol, _Period, i);
        double price = iClose(_Symbol, _Period, i);

        string reason = "";
        ENUM_TRADE_DECISION d = BuildTradeDecision(sig, i, reason);

        if(d == DEC_BLOCKED)
        {
            count_blocked++;
            DrawSignalLabel(sig, t, price, SC_BLOCKED);
            DrawBlockReason(t, reason);
        }
        else
        {
            count_valid++;
            DrawSignalLabel(sig, t, price, SC_VALID);
            DrawHistoricalTPSLPreview(sig, t, price, i);
        }

        ColorSignalCandle(sig, t);
    }

    Print("[SCAN] valid=", count_valid, " blocked=", count_blocked);
}
```

---

## 9.4 Historical H1/M15 Lookup

Karena ScanHistory berjalan pada M5, H1/M15 bias harus dihitung sesuai waktu candle historis.

Jangan gunakan H1/M15 kondisi saat ini untuk seluruh history.

Gunakan:

```mq5
iBarShift(_Symbol, PERIOD_H1, m5_time, false)
iBarShift(_Symbol, PERIOD_M15, m5_time, false)
```

Pseudocode:

```mq5
int GetShiftForTF(ENUM_TIMEFRAMES tf, datetime base_time)
{
    return iBarShift(_Symbol, tf, base_time, false);
}
```

Historical H1 bias:

```mq5
ENUM_TF_BIAS GetH1BiasAtTime(datetime t)
{
    int sh = iBarShift(_Symbol, PERIOD_H1, t, false);
    if(sh < 1) return TF_BIAS_NEUTRAL;
    return ComputeBiasOnTF(PERIOD_H1, sh);
}
```

Historical M15 setup:

```mq5
ENUM_TF_BIAS GetM15SetupAtTime(datetime t)
{
    int sh = iBarShift(_Symbol, PERIOD_M15, t, false);
    if(sh < 1) return TF_BIAS_NEUTRAL;
    return ComputeBiasOnTF(PERIOD_M15, sh);
}
```

---

## 9.5 ScanHistory Labels

Only two main labels:

```text
VALID BUY / VALID SELL
BLOCKED BUY / BLOCKED SELL
```

No more:

```text
LIMITED
SOFT
F3 RECOVERY
REGIME LIMITED
IF BLOCK
```

Optional reason text:

```text
BLOCKED H1_NOT_BUY
BLOCKED M15_NEUTRAL
BLOCKED F2_DISTANCE
BLOCKED SPREAD
```

---

# 10. Remove Market Regime

## 10.1 What To Remove

Remove from entry pipeline:

```text
InpRegime_Enable
MarketRegimeBlocks()
ComputeRegimeAt() usage inside ScanHistory label classification
RegimeLabelClass()
CombineSignalClass() dependency on regime
Regime dashboard row
Regime lot scale
Regime action inputs
REG_CHOPPY / REG_RANGING / etc. as trade gate
```

If full deletion is too large, Codex may keep functions in file temporarily but must ensure:

```text
They are not called in live entry.
They are not called in ScanHistory classification.
They do not affect label, lot, TP, SL, or block decision.
```

---

## 10.2 Why Removed

Market Regime was too aggressive and became a hard gate.

Clean Core strategy uses:

```text
H1 bias
M15 setup
M5 EMA cross
F2 distance
```

This is easier to test and debug.

---

# 11. Remove Intelligent Filter / IF

## 11.1 What To Remove

Remove from entry pipeline:

```text
InpIF_Enable
InpIF_TF
InpIF_UseExhaustion
EvalIntelligentFilter()
IF dashboard row
IF states: ALIGN, OUT-BAND, BAND, EXH-OK, EXH-NO
h_if hard gate in EvaluatePipeline
```

If functions remain for future use, they must not be called.

---

## 11.2 Why Removed

IF was designed as a hard EMA20/EMA50 trend gate. In a crossing system, reversal or early continuation signals often appear before EMA20/EMA50 fully aligns.

Result:

```text
Good M5 cross appears
↓
IF says counter-trend
↓
signal blocked
```

Clean Core uses H1/M15 context instead, which is clearer and easier to debug.

---

# 12. Remove Other Legacy Filters

## 12.1 Remove F0

Remove:

```text
InpGap_Action
InpGapPoints
InpGap_UseATRPct
InpGap_ATRPct
EvalF0()
g_f0_trig
F0 dashboard row
F0 hash contribution
```

Reason:

```text
At the exact MA cross, EMA gap is often naturally small.
F0 can block early entries that are actually valid.
```

---

## 12.2 Remove F1 DI Validation

Remove:

```text
InpF1_Action
InpF1_Margin
EvalF1()
g_f1_trig
F1 dashboard row
```

Reason:

```text
DI often confirms late.
H1/M15 bias is cleaner for this version.
```

DI/ADX can be reintroduced later only as diagnostics, not as hard gate.

---

## 12.3 Remove F3 Recovery

Remove:

```text
InpF3_UseRecovery
FindF3RecoveryAt()
ArmF3Recovery()
ProcessF3Recovery()
DrawF3RecoveryTPSL()
DrawF3RecoveryVLine()
SC_F3_RECOVERY usage
F3 recovery label logic
```

Reason:

```text
F3 exists to recover false-blocked signals.
If legacy filters are removed, F3 is no longer needed in Clean Core.
```

---

## 12.4 Remove F4 Slow MA Direction

Remove:

```text
InpF4_Action
InpF4_LookbackBars
InpF4_MinSlopePts
EvalF4()
g_f4_trig
F4 dashboard row
```

Reason:

```text
It overlaps with M15/H1 structure and can delay reversal/continuation entries.
```

---

## 12.5 Remove F5 RVI OB/OS

Remove:

```text
InpF5_Action
InpF5_TF
InpF5_Period
InpF5_OBLevel
InpF5_OSLevel
InpF5_UseSignalLine
EvalF5()
g_f5_trig
F5 dashboard row
RVI handles used only by F5/IF
```

Reason:

```text
Oscillator extremes can stay overbought/oversold during strong XAUUSD trend.
Not suitable for Clean Core trend-following default.
```

---

# 13. Exit System Strategy

## 13.1 Keep Exit System Simple

Entry logic is being simplified. Exit should also be clean.

Recommended default:

```text
Hard SL = ON
Manual TP Target = ON, target TP2
Progressive Exit = ON
Spike SL = optional ON
FMA-X = OFF
Adaptive Reversal = OFF
Smart TP = OFF
```

---

## 13.2 Progressive Exit As Main Exit

Progressive Exit remains the best default exit manager.

Recommended M5 settings:

```mq5
InpUsePE = true;
InpPE_Trigger = EXIT_ON_CANDLE_CLOSE;
InpPE_BEPAfterTP = 2;
InpPE_Phase0Bars = 4;
InpPE_Phase0BufferATR = 0.5;
```

Reason:

```text
Phase 0 gives entry room.
Phase 1 exits on fast EMA failure.
Phase 2 protects trade after TP2 by BEP lock.
```

---

## 13.3 Manual TP Target

Set:

```mq5
InpManualTP_Enable = true;
InpManualTP_Target = 2;
InpManualTP_UsePartialSystem = false;
```

Reason:

```text
TP2 should actually close the position, not only draw visual TP line.
```

---

## 13.4 Hard SL

Set:

```mq5
InpUseSL = true;
InpSL_Mult = 1.25;
InpSL_HardlineTrigger = EXIT_ON_TOUCH;
```

For M5 XAUUSD, start with:

```text
SL = 1.25 × ATR14
```

---

## 13.5 FMA-X and Adaptive Reversal

Default:

```mq5
InpUseEarlyExit = false;
InpUseAdaptiveReversal = false;
```

Reason:

```text
FMA-X overlaps with Progressive Exit Phase 1.
Adaptive Reversal overlaps with SpikeSL / trailing protection.
Do not enable too many exit managers at once.
```

They may remain in code as optional exit features, but not default.

---

# 14. Dashboard Requirements

Dashboard should show the Clean Core states:

```text
MODE      : M5_PRIMARY
H1 BIAS   : BUY / SELL / NEUTRAL
M15 SETUP : BUY / SELL / NEUTRAL
F2 DIST   : OK / BLOCK
DECISION  : VALID / BLOCKED
REASON    : VALID / H1_NOT_BUY / M15_NEUTRAL / F2_DISTANCE / SPREAD / etc.
EXIT      : PE-P0 / PE-P1 / PE-BEP / TP2 / SL / NONE
```

Remove dashboard rows for:

```text
F0
F1
F3
F4
F5
IF
Regime
Filter Summary with SOFT
```

---

# 15. Label & Visual Requirements

## 15.1 Valid Label

```text
^ BUY
v SELL
```

Use existing green/red label style.

## 15.2 Blocked Label

```text
! BLOCKED BUY
! BLOCKED SELL
```

Also display reason:

```text
H1_NOT_BUY
M15_NOT_SELL
F2_DISTANCE
SPREAD
SESSION
```

## 15.3 No Limited Label

Do not draw:

```text
LIMITED
SOFT
REGIME LIMITED
F3 RECOVERY
```

---

# 16. Hash / Cleanup Requirements

Because many filters are removed, update logic hash/version marker.

Required:

```text
1. Bump filename version.
2. Bump #property version.
3. Bump logic-version hash constant.
4. On first attach after update, cleanup all old labels.
5. ScanHistory must redraw all labels using Clean Core logic.
```

Cleanup prefixes should remove old objects from:

```text
SIG_ / SIG_B_ / SIG_S_
SIGBK_
SIGBAR_
F11 / F3 recovery objects
REGIME-related labels
DIAG_ old reasons
```

Keep dashboard objects regenerated normally.

---

# 17. Compatibility Recommendation

Do not try to minimally patch old pipeline.

Create new functions and route both live and ScanHistory through them:

```mq5
BuildTradeDecision()
H1BiasAllows()
M15SetupAllows()
EvalF2DistanceAt()
DrawCleanSignalLabel()
ScanHistoryCleanCore()
```

This reduces the risk of old filters still affecting live trading.

---

# 18. Testing Checklist

## 18.1 Compile Test

Codex must ensure:

```text
No undeclared identifiers.
No unused handle errors causing init fail.
No references to removed inputs.
No references to removed dashboard rows.
No references to SC_SOFT in decision logic.
```

---

## 18.2 Runtime Test

On M5 XAUUSD chart:

```text
EA loads successfully.
Dashboard says MODE M5_PRIMARY.
ScanHistory runs.
Historical labels appear.
Only VALID and BLOCKED labels appear.
No LIMITED labels.
No F3 recovery labels.
No Regime labels.
```

---

## 18.3 ScanHistory Test

Expected:

```text
Historical M5 EMA crosses are detected.
Each cross is either VALID or BLOCKED.
Blocked labels show reason.
F2 blocks late entries.
H1/M15 blocks opposite-direction entries.
Valid entries show TP/SL preview.
Blocked entries do not show TP/SL preview.
```

---

## 18.4 Live Entry Test

Expected:

```text
EA only opens on M5 closed candle.
EA does not open on M1/M15/H1 chart if InpRequireM5Chart = true.
EA does not open if H1 bias opposes signal.
EA does not open if M15 setup opposes signal.
EA does not open if F2 distance fails.
EA opens if all checks pass.
```

---

# 19. Recommended Default Inputs

```mq5
// Core
InpEMA_Fast = 8;
InpSMA_Slow = 20;
InpSlowMA_Method = MODE_LWMA;
InpATR_Period = 14;

// Execution
InpRequireM5Chart = true;
InpUseH1Bias = true;
InpUseM15Setup = true;
InpAllowNeutralBias = false;
InpAllowM15Neutral = false;

// F2 only
InpUseF2Distance = true;
InpF2_MaxDistATR = 1.5;

// Operational
InpMax_Spread = 45;
InpEASlippage = 30;

// SL / TP
InpUseSL = true;
InpSL_Mult = 1.25;
InpManualTP_Enable = true;
InpManualTP_Target = 2;
InpManualTP_UsePartialSystem = false;

// Progressive Exit
InpUsePE = true;
InpPE_Trigger = EXIT_ON_CANDLE_CLOSE;
InpPE_BEPAfterTP = 2;
InpPE_Phase0Bars = 4;
InpPE_Phase0BufferATR = 0.5;

// Optional exit protection
InpUseSpikeSL = true;
InpSpike_ATR_Mult = 2.0;

// Disabled defaults
InpUseEarlyExit = false;
InpUseAdaptiveReversal = false;
InpUseSmartTP = false;
```

---

# 20. What Not To Add In This Version

Do not add yet:

```text
M1 precision entry
XGBoost / ONNX
New Market Regime
New IF
RSI / MACD / Bollinger stack
Complex scoring system
F3 recovery
Soft mode TP/SL
```

Reason:

```text
This version must become a clean baseline first.
Only after baseline is measurable, add advanced modules one by one.
```

---

# 21. Future Phase After Clean Core

After Clean Core is stable and ScanHistory/logs are reliable, future modules can be added carefully:

```text
Phase 2: ATR health guard
Phase 3: Squeeze / false-break guard
Phase 4: Wick quality guard
Phase 5: Shadow Signal Logger
Phase 6: XGBoost / ONNX signal quality model
```

But do not add them in this cleanup task unless explicitly requested.

---

# 22. Final Architecture

```text
M5 closed candle
↓
EMA8 cross LWMA20
↓
Operational Guard
↓
H1 Bias Check
↓
M15 Setup Check
↓
F2 Crossing Distance Check
↓
VALID / BLOCKED
↓
If VALID: open trade
↓
Exit by Hard SL + Manual TP2 + Progressive Exit + optional SpikeSL
```

This is the cleanest baseline for the EA.

---

# 23. Codex Completion Criteria

The task is complete only if:

```text
1. EA compiles.
2. All legacy filters except F2 are removed from decision pipeline.
3. IF does not affect live trading or ScanHistory.
4. Market Regime does not affect live trading or ScanHistory.
5. SOFT / LIMITED TP-SL logic no longer affects trades.
6. M5 is the only execution timeframe.
7. H1 and M15 are context filters only.
8. M1 is not used.
9. ScanHistory still works.
10. Historical labels show VALID or BLOCKED.
11. Blocked labels include reason.
12. Valid historical signals may show TP/SL preview.
13. Blocked historical signals must not show TP/SL preview.
14. Live entry and historical scan use the same decision function.
```

---

## Final Note

This cleanup is not meant to make EA “less intelligent”. It is meant to remove conflicting intelligence.

The chosen strategy is:

```text
Simple core signal
Clear higher timeframe context
One critical distance filter
Clean exit manager
Reliable historical visualization
```

That gives a measurable baseline before adding advanced protection such as squeeze guard, wick guard, or AI scoring.
