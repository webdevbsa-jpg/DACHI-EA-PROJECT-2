# Dachi Trader — Advanced Modules Plan for Codex

**Dokumen lanjutan setelah Clean Core M5 Plan**  
Target: membangun modul lanjutan secara bertahap di atas baseline yang sudah disederhanakan.

Baseline yang diasumsikan sudah selesai:

```text
H1  = bias utama
M15 = setup / struktur trend
M5  = entry utama
M1  = tidak digunakan pada versi ini
F2  = satu-satunya legacy entry filter yang dipertahankan
IF / Market Regime / F0 / F1 / F3 / F4 / F5 = dihapus dari live decision
Soft / Limited TP-SL mode lama = dihapus
ScanHistory tetap aktif untuk label VALID / BLOCKED
```

Tujuan modul lanjutan:

```text
1. Menambah proteksi terhadap XAUUSD sideway-spike-false-break.
2. Menambah ATR Health Guard.
3. Menambah Squeeze State Machine.
4. Menambah Wick / Candle Quality Guard.
5. Menambah Anti Sideway-Spike Guard.
6. Menambah News / Session / Execution Protection.
7. Menambah Shadow Signal Logger.
8. Menjaga ScanHistory tetap berjalan dan konsisten dengan live decision.
```

---

# 1. Prinsip Utama Modul Lanjutan

Modul lanjutan **tidak boleh mengembalikan kompleksitas filter lama**.

User-facing input tetap sederhana:

```mq5
input bool InpUseATRHealthGuard       = true;
input bool InpUseSqueezeGuard         = true;
input bool InpUseWickGuard            = true;
input bool InpUseSidewaySpikeGuard    = true;
input bool InpUseNewsGuard            = false;
input bool InpUseShadowSignalLogger   = true;
```

Tidak boleh ada mode user-facing seperti:

```text
F_OFF / F_SOFT / F_HARD
```

Namun secara internal EA boleh memakai decision enum:

```mq5
enum ENUM_FILTER_DECISION
{
    DEC_OK = 0,
    DEC_LIMITED = 1,
    DEC_BLOCKED = 2
};
```

Catatan penting:

```text
LIMITED tidak berarti memakai Soft TP/SL mode lama.
LIMITED hanya label risiko / audit.
Jika baseline belum punya lot scaling baru yang rapi, LIMITED tetap boleh entry normal atau dibuat lot reduction di fase berikutnya.
```

Untuk versi pertama advanced module, keputusan live sebaiknya disederhanakan:

```text
DEC_OK       = boleh entry
DEC_LIMITED  = boleh entry, tetapi label LIMITED untuk audit
DEC_BLOCKED  = tidak entry
```

Jika ingin lebih konservatif:

```text
DEC_LIMITED = entry dengan lot multiplier 0.5
```

Tetapi jangan mengaktifkan kembali sistem Soft TP/SL lama.

---

# 2. Final Architecture Setelah Modul Lanjutan

```text
M5 signal EMA8/LWMA20 cross
↓
Operational Guard
    - license
    - session
    - spread
    - daily loss / daily profit stop
↓
H1 Bias Guard
↓
M15 Setup Guard
↓
F2 Crossing Distance Guard
↓
ATR Health Guard
↓
Squeeze Guard
↓
Sideway-Spike Guard
↓
Wick / Candle Quality Guard
↓
Final Decision
    - VALID
    - LIMITED
    - BLOCKED
↓
Entry
↓
Exit Manager
    - Hard SL
    - Manual TP2
    - Progressive Exit
    - SpikeSL optional
    - MaxBars optional
```

M1 tidak digunakan dalam versi ini.

---

# 3. Decision Engine Terpusat

Semua modul wajib dipanggil dari satu pusat keputusan.

Buat struct:

```mq5
struct STradeDecision
{
    ENUM_SIGNAL_CLASS final_class;   // SC_VALID / SC_SOFT / SC_BLOCKED
    bool              allow_entry;
    string            main_reason;
    string            reason_chain;

    ENUM_FILTER_DECISION f2_decision;
    ENUM_FILTER_DECISION atr_decision;
    ENUM_FILTER_DECISION squeeze_decision;
    ENUM_FILTER_DECISION spike_decision;
    ENUM_FILTER_DECISION wick_decision;

    string h1_state;
    string m15_state;
    string atr_state;
    string squeeze_state;
    string spike_state;
    string wick_state;
};
```

Buat fungsi utama:

```mq5
STradeDecision BuildTradeDecision(int sig, int shift)
{
    STradeDecision d;
    ResetTradeDecision(d);

    // 1. Operational guard
    // 2. H1 bias
    // 3. M15 setup
    // 4. F2 distance
    // 5. ATR health
    // 6. Squeeze
    // 7. Sideway-spike
    // 8. Wick/candle quality
    // 9. Final class
    // 10. Return decision
}
```

Final class rule:

```text
Jika ada DEC_BLOCKED → SC_BLOCKED dan allow_entry=false.
Jika tidak ada BLOCKED tetapi ada DEC_LIMITED → SC_SOFT/LIMITED dan allow_entry=true.
Jika semua OK → SC_VALID dan allow_entry=true.
```

Pastikan label chart:

```text
VALID   = green
LIMITED = yellow
BLOCKED = magenta
```

---

# 4. Modul ATR Health Guard

## 4.1 Tujuan

ATR Health Guard dipakai untuk membaca apakah volatilitas XAUUSD sedang:

```text
1. Terlalu sempit.
2. Sehat untuk trend-following.
3. Terlalu tinggi / spike risk.
4. Chaos / news spike.
```

ATR tidak menentukan arah. ATR hanya menentukan apakah kondisi cukup sehat untuk entry.

---

## 4.2 Handle Indicator

Tambahkan handle:

```mq5
int h_atr_fast = INVALID_HANDLE;   // ATR(5)
int h_atr_base = INVALID_HANDLE;   // ATR(14)
int h_atr_slow = INVALID_HANDLE;   // ATR(50)
```

Initialize di OnInit:

```mq5
h_atr_fast = iATR(_Symbol, PERIOD_M5, 5);
h_atr_base = iATR(_Symbol, PERIOD_M5, 14);
h_atr_slow = iATR(_Symbol, PERIOD_M5, 50);
```

Release di OnDeinit.

Jika EA masih memakai ATR core existing, jangan duplicate handle jika bisa reuse. Tetapi untuk clarity, boleh buat helper yang mengambil ATR5/14/50.

---

## 4.3 Input Default M5

Karena versi ini tidak memakai M1, default fokus M5:

```mq5
input double InpATR_M5_MinTrade     = 0.90;
input double InpATR_M5_MaxNormal    = 2.80;
input double InpATR_M5_MaxAllowed   = 4.50;
input double InpATR_M5_BlockAbove   = 5.50;

input double InpATR_FastRatioLimited = 1.80;
input double InpATR_FastRatioBlock   = 2.20;
input double InpATR_SlowRatioLow     = 0.80;
input double InpATR_SlowRatioHigh    = 2.20;
```

Interpretasi:

```text
ATR14 < 0.90      = low volatility / compression risk
0.90–2.80         = healthy
2.80–4.50         = high volatility / LIMITED
> 5.50            = BLOCKED
ATR5/ATR14 > 2.20 = spike chaos / BLOCKED
```

---

## 4.4 Function

```mq5
ENUM_FILTER_DECISION EvalATRHealthGuard(int sig, int shift, string &state, string &reason)
{
    if(!InpUseATRHealthGuard)
    {
        state = "OFF";
        reason = "ATR_OFF";
        return DEC_OK;
    }

    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50))
    {
        state = "ERR";
        reason = "ATR_READ_FAIL";
        return DEC_BLOCKED;
    }

    double fast_ratio = atr5 / MathMax(atr14, _Point);
    double slow_ratio = atr14 / MathMax(atr50, _Point);

    if(atr14 > InpATR_M5_BlockAbove)
    {
        state = "CHAOS";
        reason = "ATR14_BLOCK";
        return DEC_BLOCKED;
    }

    if(fast_ratio > InpATR_FastRatioBlock)
    {
        state = "SPIKE";
        reason = "ATR_FAST_SPIKE";
        return DEC_BLOCKED;
    }

    if(atr14 < InpATR_M5_MinTrade)
    {
        state = "LOWVOL";
        reason = "ATR_TOO_LOW";
        return DEC_LIMITED;
    }

    if(atr14 > InpATR_M5_MaxAllowed)
    {
        state = "HIGHVOL";
        reason = "ATR_HIGH";
        return DEC_LIMITED;
    }

    if(fast_ratio > InpATR_FastRatioLimited)
    {
        state = "EXPANSION";
        reason = "ATR_EXPANSION";
        return DEC_LIMITED;
    }

    state = "HEALTHY";
    reason = "ATR_OK";
    return DEC_OK;
}
```

Catatan:

```text
ATR_TOO_LOW jangan langsung BLOCKED di ATR module.
Biarkan SqueezeGuard yang menentukan apakah compression benar-benar harus BLOCKED.
```

---

# 5. Modul Squeeze Guard

## 5.1 Apakah Squeeze Diperlukan?

Ya, squeeze diperlukan, tetapi bukan sebagai entry signal.

Squeeze diperlukan karena XAUUSD sering membentuk pola:

```text
range sempit
↓
EMA8/LWMA20 crossing berkali-kali
↓
spike breakout
↓
false breakout
↓
harga kembali ke range
```

Masalah ini tidak bisa ditangani hanya dengan F2. F2 hanya membaca apakah entry terlalu jauh dari titik crossing. F2 tidak membaca apakah market sedang dalam compression/range.

---

## 5.2 Prinsip Squeeze

Squeeze bukan filter tunggal. Squeeze adalah state machine.

```text
SQ_NONE
SQ_BUILDUP
SQ_ARMED
SQ_BREAKOUT_UP
SQ_BREAKOUT_DN
SQ_CONFIRMED_UP
SQ_CONFIRMED_DN
SQ_FALSE_BREAK
SQ_LOCKOUT
```

Saat squeeze buildup/armed:

```text
Crossing biasa = BLOCKED.
```

Saat breakout valid:

```text
Entry boleh VALID atau LIMITED.
```

Saat false breakout:

```text
Entry BLOCKED + lockout beberapa candle.
```

---

## 5.3 Enum

```mq5
enum ENUM_SQUEEZE_STATE
{
    SQ_NONE = 0,
    SQ_BUILDUP = 1,
    SQ_ARMED = 2,
    SQ_BREAKOUT_UP = 3,
    SQ_BREAKOUT_DN = 4,
    SQ_CONFIRMED_UP = 5,
    SQ_CONFIRMED_DN = 6,
    SQ_FALSE_BREAK = 7,
    SQ_LOCKOUT = 8
};
```

Global:

```mq5
ENUM_SQUEEZE_STATE g_sq_state = SQ_NONE;
datetime g_sq_start_time = 0;
datetime g_sq_breakout_time = 0;
datetime g_sq_lockout_until_time = 0;
double g_sq_range_high = 0.0;
double g_sq_range_low = 0.0;
string g_sq_reason = "";
```

---

## 5.4 Inputs M5

```mq5
input int    InpSQ_Lookback              = 20;
input double InpSQ_RangeATRMax           = 3.50;
input double InpSQ_ATRCompressionMax     = 0.80;
input double InpSQ_MAGapATRMax           = 0.18;
input int    InpSQ_CrossDensityLookback  = 30;
input int    InpSQ_CrossDensityMin       = 3;
input double InpSQ_BreakoutBufferATR     = 0.30;
input double InpSQ_MinBodyRatio          = 0.55;
input double InpSQ_BuyCloseLocMin        = 0.65;
input double InpSQ_SellCloseLocMax       = 0.35;
input double InpSQ_SpikeRatioBlock       = 2.20;
input int    InpSQ_FalseBreakBars        = 3;
input int    InpSQ_LockoutBars           = 5;
```

---

## 5.5 Donchian Range Helper

Range harus dihitung dari bar sebelum signal, bukan memasukkan candle signal.

```mq5
bool CalcDonchianRange(int lookback, int shift_start, double &range_high, double &range_low)
{
    range_high = -DBL_MAX;
    range_low  = DBL_MAX;

    for(int i = shift_start; i < shift_start + lookback; i++)
    {
        double h = iHigh(_Symbol, PERIOD_M5, i);
        double l = iLow(_Symbol, PERIOD_M5, i);

        if(h > range_high) range_high = h;
        if(l < range_low)  range_low = l;
    }

    return (range_high > range_low && range_low > 0.0);
}
```

Untuk signal shift=1:

```mq5
CalcDonchianRange(InpSQ_Lookback, shift + 1, hi, lo);
```

Tujuannya agar candle signal diuji terhadap range sebelumnya.

---

## 5.6 Compression Detection

```mq5
bool IsSqueezeCompression(int shift, string &reason)
{
    double hi, lo;
    if(!CalcDonchianRange(InpSQ_Lookback, shift + 1, hi, lo))
    {
        reason = "SQ_RANGE_FAIL";
        return false;
    }

    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50))
    {
        reason = "SQ_ATR_FAIL";
        return false;
    }

    double ema_fast, ma_slow;
    if(!ReadCoreMA(shift, ema_fast, ma_slow))
    {
        reason = "SQ_MA_FAIL";
        return false;
    }

    double range_atr = (hi - lo) / MathMax(atr14, _Point);
    double atr_comp  = atr14 / MathMax(atr50, _Point);
    double ma_gap_atr = MathAbs(ema_fast - ma_slow) / MathMax(atr14, _Point);
    int crosses = CountCoreCrosses(InpSQ_CrossDensityLookback, shift + 1);

    bool compressed =
        range_atr <= InpSQ_RangeATRMax &&
        atr_comp <= InpSQ_ATRCompressionMax &&
        ma_gap_atr <= InpSQ_MAGapATRMax &&
        crosses >= InpSQ_CrossDensityMin;

    if(compressed)
        reason = "SQ_COMPRESS";
    else
        reason = "SQ_NONE";

    return compressed;
}
```

---

## 5.7 Breakout Detection

BUY breakout:

```mq5
close > g_sq_range_high + buffer
```

SELL breakout:

```mq5
close < g_sq_range_low - buffer
```

Buffer:

```mq5
buffer = InpSQ_BreakoutBufferATR * atr14;
```

---

## 5.8 Breakout Quality

Minimal valid breakout harus punya:

```text
1. Close keluar range.
2. Body ratio cukup besar.
3. Close location kuat.
4. ATR5/ATR14 tidak chaos.
5. Tidak ada wick rejection berlawanan.
```

Function:

```mq5
bool IsBreakoutQualityGood(int sig, int shift, string &reason)
{
    double o = iOpen(_Symbol, PERIOD_M5, shift);
    double h = iHigh(_Symbol, PERIOD_M5, shift);
    double l = iLow(_Symbol, PERIOD_M5, shift);
    double c = iClose(_Symbol, PERIOD_M5, shift);

    double range = MathMax(h - l, _Point);
    double body = MathAbs(c - o);
    double body_ratio = body / range;
    double close_loc = (c - l) / range;

    double atr5, atr14, atr50;
    if(!ReadATRSet(shift, atr5, atr14, atr50))
    {
        reason = "BR_ATR_FAIL";
        return false;
    }

    double fast_ratio = atr5 / MathMax(atr14, _Point);

    if(fast_ratio > InpSQ_SpikeRatioBlock)
    {
        reason = "BR_SPIKE_CHAOS";
        return false;
    }

    if(body_ratio < InpSQ_MinBodyRatio)
    {
        reason = "BR_WEAK_BODY";
        return false;
    }

    if(sig > 0 && close_loc < InpSQ_BuyCloseLocMin)
    {
        reason = "BR_BAD_CLOSE_BUY";
        return false;
    }

    if(sig < 0 && close_loc > InpSQ_SellCloseLocMax)
    {
        reason = "BR_BAD_CLOSE_SELL";
        return false;
    }

    reason = "BR_QUALITY_OK";
    return true;
}
```

---

## 5.9 EvalSqueezeGuard

```mq5
ENUM_FILTER_DECISION EvalSqueezeGuard(int sig, int shift, string &state, string &reason)
{
    if(!InpUseSqueezeGuard)
    {
        state = "OFF";
        reason = "SQ_OFF";
        return DEC_OK;
    }

    UpdateSqueezeState(shift);

    state = SqueezeStateToString(g_sq_state);
    reason = g_sq_reason;

    if(g_sq_state == SQ_LOCKOUT)
        return DEC_BLOCKED;

    if(g_sq_state == SQ_BUILDUP || g_sq_state == SQ_ARMED)
        return DEC_BLOCKED;

    if(g_sq_state == SQ_BREAKOUT_UP)
    {
        if(sig < 0)
        {
            reason = "SQ_OPPOSITE_SELL";
            return DEC_BLOCKED;
        }

        string br_reason = "";
        if(IsBreakoutQualityGood(sig, shift, br_reason))
        {
            reason = br_reason;
            return DEC_OK;
        }

        reason = br_reason;
        return DEC_BLOCKED;
    }

    if(g_sq_state == SQ_BREAKOUT_DN)
    {
        if(sig > 0)
        {
            reason = "SQ_OPPOSITE_BUY";
            return DEC_BLOCKED;
        }

        string br_reason = "";
        if(IsBreakoutQualityGood(sig, shift, br_reason))
        {
            reason = br_reason;
            return DEC_OK;
        }

        reason = br_reason;
        return DEC_BLOCKED;
    }

    return DEC_OK;
}
```

---

# 6. Modul Anti Sideway-Spike Guard

## 6.1 Tujuan

Modul ini khusus menangani kasus terbesar XAUUSD:

```text
sideway sempit
↓
spike besar
↓
false breakout
↓
harga kembali sideway
↓
EA loss karena entry pada crossing palsu berikutnya
```

SqueezeGuard membaca compression.  
SidewaySpikeGuard membaca spike + failed follow-through.

---

## 6.2 Inputs

```mq5
input int    InpSS_RangeLookback        = 20;
input double InpSS_RangeATRMax          = 3.50;
input double InpSS_SpikeCandleATR       = 2.00;
input double InpSS_ReturnToRangeATR     = 0.20;
input int    InpSS_FollowThroughBars    = 3;
input int    InpSS_LockoutBars          = 5;
input double InpSS_MaxCloseBackInsideATR = 0.30;
```

---

## 6.3 Logic

Hard block jika:

```text
1. Range 20 bar sempit.
2. Candle saat ini spike > 2.0 × ATR14.
3. Candle close kembali dekat range / ke dalam range.
4. Tidak ada follow-through dalam 1–3 candle.
5. Setelah kejadian ini, aktifkan lockout.
```

Pseudo:

```mq5
ENUM_FILTER_DECISION EvalSidewaySpikeGuard(int sig, int shift, string &state, string &reason)
{
    if(!InpUseSidewaySpikeGuard)
    {
        state = "OFF";
        reason = "SS_OFF";
        return DEC_OK;
    }

    if(IsInSidewaySpikeLockout())
    {
        state = "LOCKOUT";
        reason = "SS_LOCKOUT";
        return DEC_BLOCKED;
    }

    if(DetectSidewaySpikeFalseBreak(shift, reason))
    {
        ActivateSidewaySpikeLockout(InpSS_LockoutBars);
        state = "FALSE_BREAK";
        return DEC_BLOCKED;
    }

    state = "OK";
    reason = "SS_OK";
    return DEC_OK;
}
```

---

# 7. Modul Wick / Candle Quality Guard

## 7.1 Tujuan

Wick Guard membaca apakah candle signal adalah:

```text
1. Breakout bersih.
2. Rejection.
3. Liquidity sweep.
4. False breakout.
```

Wick Guard tidak boleh menjadi hard block universal.  
Wick Guard menjadi hard block hanya saat konteksnya berbahaya:

```text
1. Sedang squeeze.
2. Sedang range.
3. Baru spike.
4. Breakout belum confirmed.
```

---

## 7.2 Inputs

```mq5
input int    InpWick_SweepLookback    = 10;
input double InpWick_MinWickRatio     = 0.60;
input double InpWick_MinBodyRatio     = 0.30;
input double InpWick_BadCloseLocBuy   = 0.50;
input double InpWick_BadCloseLocSell  = 0.50;
```

---

## 7.3 Candle Metrics

```mq5
struct SCandleMetrics
{
    double open;
    double high;
    double low;
    double close;
    double range;
    double body;
    double upper_wick;
    double lower_wick;
    double body_ratio;
    double upper_wick_ratio;
    double lower_wick_ratio;
    double close_location;
};
```

Helper:

```mq5
bool GetCandleMetrics(int shift, SCandleMetrics &m)
{
    m.open = iOpen(_Symbol, PERIOD_M5, shift);
    m.high = iHigh(_Symbol, PERIOD_M5, shift);
    m.low  = iLow(_Symbol, PERIOD_M5, shift);
    m.close = iClose(_Symbol, PERIOD_M5, shift);

    m.range = MathMax(m.high - m.low, _Point);
    m.body = MathAbs(m.close - m.open);
    m.upper_wick = m.high - MathMax(m.open, m.close);
    m.lower_wick = MathMin(m.open, m.close) - m.low;

    m.body_ratio = m.body / m.range;
    m.upper_wick_ratio = m.upper_wick / m.range;
    m.lower_wick_ratio = m.lower_wick / m.range;
    m.close_location = (m.close - m.low) / m.range;

    return true;
}
```

---

## 7.4 Bad Wick Rules

BUY bad wick:

```text
upper wick dominan
high sweep previous high
close kembali lemah
```

SELL bad wick:

```text
lower wick dominan
low sweep previous low
close kembali lemah
```

Function:

```mq5
ENUM_FILTER_DECISION EvalWickGuard(int sig, int shift, string &state, string &reason)
{
    if(!InpUseWickGuard)
    {
        state = "OFF";
        reason = "WICK_OFF";
        return DEC_OK;
    }

    SCandleMetrics m;
    if(!GetCandleMetrics(shift, m))
    {
        state = "ERR";
        reason = "WICK_READ_FAIL";
        return DEC_LIMITED;
    }

    double prev_hi, prev_lo;
    CalcDonchianRange(InpWick_SweepLookback, shift + 1, prev_hi, prev_lo);

    bool buy_bad =
        sig > 0 &&
        m.upper_wick_ratio >= InpWick_MinWickRatio &&
        m.high > prev_hi &&
        m.close < prev_hi;

    bool sell_bad =
        sig < 0 &&
        m.lower_wick_ratio >= InpWick_MinWickRatio &&
        m.low < prev_lo &&
        m.close > prev_lo;

    if(buy_bad)
    {
        state = "BAD_BUY";
        reason = "UPPER_WICK_REJECT";
        if(IsDangerContext())
            return DEC_BLOCKED;

        return DEC_LIMITED;
    }

    if(sell_bad)
    {
        state = "BAD_SELL";
        reason = "LOWER_WICK_REJECT";
        if(IsDangerContext())
            return DEC_BLOCKED;

        return DEC_LIMITED;
    }

    state = "OK";
    reason = "WICK_OK";
    return DEC_OK;
}
```

Danger context:

```mq5
bool IsDangerContext()
{
    return (
        g_sq_state == SQ_BUILDUP ||
        g_sq_state == SQ_ARMED ||
        g_sq_state == SQ_BREAKOUT_UP ||
        g_sq_state == SQ_BREAKOUT_DN ||
        g_sq_state == SQ_LOCKOUT ||
        IsInSidewaySpikeLockout()
    );
}
```

---

# 8. News Guard

## 8.1 Tujuan

Untuk versi awal, jangan integrasi kalender otomatis.  
Gunakan manual news window.

---

## 8.2 Inputs

```mq5
input bool   InpUseNewsGuard          = false;
input int    InpNewsBlockBeforeMin    = 15;
input int    InpNewsBlockAfterMin     = 15;
input string InpNewsTime1             = "";
input string InpNewsTime2             = "";
input string InpNewsTime3             = "";
```

Format:

```text
"19:30"
"21:00"
```

Jika server time broker berbeda dari waktu lokal, beri input offset:

```mq5
input int InpNewsTimeOffsetHours = 0;
```

---

## 8.3 Decision

```mq5
bool IsInNewsWindow(datetime now)
{
    // parse InpNewsTime1/2/3
    // block from time-before to time+after
}
```

NewsGuard selalu DEC_BLOCKED.

---

# 9. Execution Protection

Tambahkan proteksi berikut:

```text
1. Spread spike guard.
2. Slippage check after order result.
3. Cooldown setelah order gagal.
4. Cooldown setelah spread melebar ekstrem.
5. No reverse entry until close confirmed.
```

Inputs:

```mq5
input int InpOrderFailCooldownBars = 3;
input int InpSpreadSpikeCooldownBars = 3;
input bool InpNoReverseUntilCloseConfirmed = true;
```

---

# 10. Shadow Signal Logger

## 10.1 Tujuan

Logger wajib dibuat agar kita tahu:

```text
1. Signal valid mana yang profit.
2. Signal blocked mana yang sebenarnya profit.
3. Filter mana yang menyelamatkan EA.
4. Filter mana yang terlalu banyak membunuh signal bagus.
```

---

## 10.2 CSV Columns

```text
time
symbol
timeframe
signal
entry_price
h1_state
m15_state
f2_state
atr_state
atr5
atr14
atr50
atr5_atr14
atr14_atr50
squeeze_state
sideway_spike_state
wick_state
final_class
allow_entry
main_reason
reason_chain
mfe_5
mae_5
mfe_10
mae_10
mfe_20
mae_20
tp1_hit_first
tp2_hit_first
sl_hit_first
```

---

## 10.3 Logging Mode

Input:

```mq5
input bool InpUseShadowSignalLogger = true;
input int  InpShadowEvalBars1 = 5;
input int  InpShadowEvalBars2 = 10;
input int  InpShadowEvalBars3 = 20;
```

Untuk live signal, tulis initial row saat signal muncul.  
Untuk historical ScanHistory, boleh generate shadow summary berdasarkan historical future bars jika tersedia.

---

# 11. ScanHistory Integration

## 11.1 Requirement

ScanHistory wajib tetap berjalan.

ScanHistory harus menampilkan:

```text
VALID
LIMITED
BLOCKED
```

Untuk setiap historical M5 crossing signal.

ScanHistory harus memakai decision engine yang sama:

```mq5
STradeDecision d = BuildTradeDecisionAt(sig, shift);
```

Jangan membuat logic historical berbeda dari live.

---

## 11.2 Historical Function

Buat function pure shift-aware:

```mq5
STradeDecision BuildTradeDecisionAt(int sig, int shift)
{
    // Same as live but all indicator reads use shift.
    // No side effects that modify live-only state except optional historical local state.
}
```

Untuk stateful module seperti SqueezeGuard:

```text
ScanHistory harus memproses dari bar lama ke bar baru agar state squeeze historical terbentuk benar.
```

Pseudocode:

```mq5
void ScanHistory()
{
    ResetHistoricalSqueezeState();
    ResetHistoricalSidewaySpikeState();

    for(int shift = scan_bars; shift >= 1; shift--)
    {
        int sig = DetectSignalAt(shift);
        UpdateHistoricalSqueezeState(shift);
        UpdateHistoricalSidewaySpikeState(shift);

        if(sig != 0)
        {
            STradeDecision d = BuildTradeDecisionAt(sig, shift);
            DrawSignalLabelAt(shift, sig, d.final_class, d.main_reason);
            LogShadowHistorical(sig, shift, d);
        }
    }
}
```

---

## 11.3 Label Rules

```text
SC_VALID:
^ BUY / v SELL green

SC_SOFT:
LIMITED BUY / LIMITED SELL yellow

SC_BLOCKED:
! BLOCKED BUY / ! BLOCKED SELL magenta
```

Reason text should include:

```text
F2_DISTANCE
ATR_SPIKE
SQ_BUILDUP
SQ_LOCKOUT
SS_FALSE_BREAK
WICK_REJECT
H1_NOT_ALIGNED
M15_NOT_READY
SPREAD
NEWS
```

---

# 12. Dashboard Additions

Add dashboard rows:

```text
MODE       : M5_PRIMARY
H1         : BUY / SELL / NEUTRAL
M15        : PULLBACK / TREND / RANGE / NEUTRAL
F2         : OK / FAR
ATR        : HEALTHY / LOWVOL / HIGHVOL / SPIKE
SQ         : NONE / BUILDUP / ARMED / BR_UP / BR_DN / LOCKOUT
SS         : OK / FALSE_BREAK / LOCKOUT
WICK       : OK / BAD_BUY / BAD_SELL / LIMITED
DECISION   : VALID / LIMITED / BLOCKED
REASON     : main reason
```

---

# 13. Implementation Order for Codex

Do not implement all modules at once without compiling after each step.

Recommended sequence:

```text
Step 1:
Create ENUM_FILTER_DECISION and STradeDecision.

Step 2:
Refactor live decision into BuildTradeDecision() while keeping current Clean Core behavior.

Step 3:
Add BuildTradeDecisionAt() for ScanHistory.

Step 4:
Add ATR Health Guard.

Step 5:
Add Donchian helper and SqueezeGuard state machine.

Step 6:
Add SidewaySpikeGuard.

Step 7:
Add CandleMetrics and WickGuard.

Step 8:
Add NewsGuard.

Step 9:
Add Execution Protection cooldowns.

Step 10:
Add ShadowSignalLogger.

Step 11:
Update dashboard.

Step 12:
Run compile and tester.
```

---

# 14. Testing Plan

Test in order:

```text
Test A:
Clean Core only.

Test B:
Clean Core + ATR Health.

Test C:
Clean Core + ATR + SqueezeGuard.

Test D:
Clean Core + ATR + Squeeze + SidewaySpike.

Test E:
Clean Core + ATR + Squeeze + SidewaySpike + Wick.

Test F:
All modules + NewsGuard off.

Test G:
All modules + NewsGuard manual on.
```

Metrics:

```text
Net profit
Profit factor
Max DD
Expected payoff
Average win
Average loss
Max consecutive loss
Trade count
Blocked signal count
Limited signal count
Valid signal count
Most common block reason
Most profitable hour/session
Worst hour/session
```

---

# 15. Default Recommended Setup

For first advanced version:

```text
Entry:
M5 primary only.
H1 bias required.
M15 setup required.
F2 distance ON.
ATR Health ON.
SqueezeGuard ON.
SidewaySpikeGuard ON.
WickGuard ON.
NewsGuard OFF by default.
ShadowLogger ON.

Exit:
Hard SL ON.
Manual TP2 ON.
Progressive Exit ON.
SpikeSL optional ON.
FMA-X OFF.
Adaptive Reversal OFF.
SmartTP OFF.
Soft TP/SL old mode removed.
```

---

# 16. What Not To Reintroduce

Do not reintroduce these in advanced module:

```text
1. IF as hard gate.
2. Market Regime as hard gate.
3. F0/F1/F3/F4/F5 as independent filters.
4. Soft TP/SL legacy mode.
5. Scoring/Judge old complex stack.
6. M1 precision entry.
7. MACD/RSI/Bollinger stack.
```

If later needed, build them as new clean modules, not by restoring old tangled logic.

---

# 17. Final Strategic Rationale

This EA should become:

```text
A clean M5 trend-following XAUUSD EA with H1/M15 context,
using F2 for late-entry prevention,
ATR for volatility health,
Squeeze and SidewaySpike logic for false-break protection,
Wick/Candle metrics for candle quality,
and Progressive Exit for trade management.
```

The main objective is not to block everything.

The main objective is:

```text
1. Avoid entry in dead range.
2. Avoid entry after fake spike.
3. Avoid late entry.
4. Allow clean M5 trend-following continuation.
5. Keep ScanHistory transparent so every signal can be audited.
```

Advanced modules must improve signal quality without making the EA opaque.

---

# 18. Codex Final Instruction

When modifying the EA:

```text
1. Rename file/version according to project versioning rule.
2. Keep ScanHistory visual output.
3. Keep chart labels for VALID / LIMITED / BLOCKED.
4. Keep historical and live decision logic consistent.
5. Do not use M1 in this version.
6. Do not restore removed filters.
7. Do not restore old Soft TP/SL mode.
8. Compile after each implementation step.
9. Add comments explaining each new module.
10. Add dashboard state for every module.
```
