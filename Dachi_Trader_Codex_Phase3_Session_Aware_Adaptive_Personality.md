# Dachi Trader — Phase 3 Plan
## Session-Aware Adaptive Personality for XAUUSD

**Phase 3 ini dibuat setelah:**

```text
Phase 1 = Clean Core M5
Phase 2 = Advanced Modules: ATR Health, Squeeze, Sideway-Spike, Wick, Shadow Logger
Phase 3 = Session-Aware Adaptive Personality
```

Tujuan Phase 3:

```text
Membuat EA sadar sesi market, tetapi tidak kaku.
Session hanya menjadi context risk adjustment, bukan hard block tunggal.
Final decision tetap berdasarkan real-time market state.
```

---

# 1. Alasan Phase 3 Diperlukan

XAUUSD sekarang tidak bisa diasumsikan dengan pola klasik:

```text
Asia   = pasti sideway
London = pasti breakout
NY     = pasti trend/news
```

Di lapangan:

```text
1. Asia kadang bergerak kuat.
2. London sering menjadi trap / fake breakout.
3. New York sering spike besar lalu reversal cepat.
4. Karakter XAUUSD bisa berubah antar hari bahkan antar sesi.
```

Karena itu, EA tidak boleh memakai aturan kaku seperti:

```text
Jika Asia → block.
Jika London → allow breakout.
Jika NY → follow trend.
```

Yang benar:

```text
Session = context risiko
Market state real-time = penentu entry
```

---

# 2. Konsep Utama

Phase 3 mengubah konsep lama:

```text
Fixed Session Personality
```

menjadi:

```text
Session-Aware Adaptive Personality
```

Artinya EA tetap mengetahui sesi:

```text
ASIA
LONDON_OPEN
LONDON_MID
NY_PRE_NEWS
NY_OPEN
NY_OVERLAP
NY_LATE
OTHER
```

Tetapi sesi tidak langsung menentukan entry.  
EA harus menentukan real-time state:

```text
COMPRESSION
ACTIVE_TREND
HEALTHY_PULLBACK
BREAKOUT_ATTEMPT
CONFIRMED_BREAKOUT
TRAP_RISK
FALSE_BREAK_LOCKOUT
CHAOS_SPIKE
VWAP_CHOP
NORMAL
```

Final behavior ditentukan dari kombinasi:

```text
Session Tag + Real-Time Market State
```

Contoh:

```text
Asia + ACTIVE_TREND              = boleh entry
Asia + COMPRESSION               = block
London Open + BREAKOUT_ATTEMPT   = tunggu konfirmasi
London Open + TRAP_RISK          = block
NY + CHAOS_SPIKE                 = block
NY + HEALTHY_PULLBACK            = boleh entry
```

---

# 3. Posisi Phase 3 Dalam Arsitektur EA

Arsitektur final:

```text
H1 Bias
↓
M15 Setup
↓
M5 Entry Signal: EMA8/LWMA20 Cross
↓
F2 Distance
↓
ATR Health
↓
Squeeze Guard
↓
Sideway-Spike Guard
↓
Wick Guard
↓
VWAP Context Guard
↓
Phase 3: Session-Aware Adaptive Personality
↓
Final Decision: VALID / LIMITED / BLOCKED
```

Catatan:

```text
M1 tetap tidak digunakan.
Entry utama tetap M5.
H1 dan M15 tetap sebagai context.
```

---

# 4. Prinsip Implementasi

## 4.1 Session Tidak Boleh Menjadi Hard Block Tunggal

Dilarang membuat rule seperti:

```text
Asia = block all
London = allow all breakout
NY = allow all trend
```

Session hanya boleh mengubah sensitivitas guard.

Contoh:

```text
Asia:
- Squeeze threshold lebih ketat
- F2 lebih ketat
- Breakout harus lebih bersih

London Open:
- Trap detection lebih ketat
- Breakout wajib follow-through
- Spike candle pertama jangan langsung entry

New York:
- News/spike guard lebih ketat
- Spread/slippage guard lebih ketat
- Entry boleh jika trend/pullback valid setelah spike mereda
```

## 4.2 Final Decision Tetap Dari Decision Engine

Phase 3 harus masuk ke `BuildTradeDecision()`.

```mq5
STradeDecision BuildTradeDecision(int sig, int shift)
{
    // 1. Operational guard
    // 2. H1 bias
    // 3. M15 setup
    // 4. F2
    // 5. ATR
    // 6. Squeeze
    // 7. SidewaySpike
    // 8. Wick
    // 9. VWAP
    // 10. Session-Aware Adaptive Personality
    // 11. Final decision
}
```

Output Phase 3:

```mq5
ENUM_FILTER_DECISION session_decision;
string session_tag;
string market_state;
string session_reason;
```

---

# 5. Enum Yang Perlu Ditambahkan

## 5.1 Session Tag

```mq5
enum ENUM_SESSION_TAG
{
    SES_UNKNOWN = 0,
    SES_ASIA = 1,
    SES_LONDON_OPEN = 2,
    SES_LONDON_MID = 3,
    SES_NY_PRE_NEWS = 4,
    SES_NY_OPEN = 5,
    SES_NY_OVERLAP = 6,
    SES_NY_LATE = 7,
    SES_OTHER = 8
};
```

## 5.2 Real-Time Market State

```mq5
enum ENUM_REALTIME_MARKET_STATE
{
    MS_UNKNOWN = 0,
    MS_NORMAL = 1,
    MS_COMPRESSION = 2,
    MS_ACTIVE_TREND = 3,
    MS_HEALTHY_PULLBACK = 4,
    MS_BREAKOUT_ATTEMPT = 5,
    MS_CONFIRMED_BREAKOUT = 6,
    MS_TRAP_RISK = 7,
    MS_FALSE_BREAK_LOCKOUT = 8,
    MS_CHAOS_SPIKE = 9,
    MS_VWAP_CHOP = 10
};
```

Gunakan enum decision yang sudah dibuat pada Phase 2:

```mq5
enum ENUM_FILTER_DECISION
{
    DEC_OK = 0,
    DEC_LIMITED = 1,
    DEC_BLOCKED = 2
};
```

---

# 6. Input Phase 3

User-facing input harus sederhana:

```mq5
input bool InpUseSessionAdaptivePersonality = true;
```

Advanced settings:

```mq5
input int InpAsiaStartHour        = 0;
input int InpAsiaEndHour          = 7;

input int InpLondonOpenStartHour  = 7;
input int InpLondonOpenEndHour    = 9;

input int InpLondonMidStartHour   = 9;
input int InpLondonMidEndHour     = 13;

input int InpNYPreNewsStartHour   = 13;
input int InpNYPreNewsEndHour     = 15;

input int InpNYOpenStartHour      = 15;
input int InpNYOpenEndHour        = 17;

input int InpNYOverlapStartHour   = 17;
input int InpNYOverlapEndHour     = 20;

input int InpNYLateStartHour      = 20;
input int InpNYLateEndHour        = 23;

input int InpSessionTimeOffsetHours = 0;
```

London trap guard:

```mq5
input bool InpUseLondonTrapGuard = true;
input int  InpLondonTrapLockoutBars = 5;
input int  InpLondonTrapConfirmBars = 1;
```

Asia adaptive setting:

```mq5
input bool   InpAsiaAllowActiveTrend = true;
input double InpAsiaF2TightenFactor = 0.85;
input double InpAsiaBreakoutBodyMin = 0.60;
```

NY adaptive setting:

```mq5
input bool   InpNYUseExtraSpikeGuard = true;
input double InpNYFastATRBlock = 2.00;
input int    InpNYPostSpikeLockoutBars = 5;
```

---

# 7. Session Tagging

Function:

```mq5
ENUM_SESSION_TAG GetSessionTag(datetime t)
{
    // Apply InpSessionTimeOffsetHours.
    // Convert t to hour.
    // Return session tag based on configured hour window.
}
```

Important:

```text
Use broker server time unless offset is set.
Dashboard must show current session tag.
```

---

# 8. Real-Time Market State Detection

Phase 3 tidak perlu membuat indikator baru.  
Gunakan data dari Phase 2:

```text
ATR Health Guard
Squeeze Guard
Sideway-Spike Guard
Wick Guard
VWAP Guard
H1 Bias
M15 Setup
F2 Distance
```

Function concept:

```mq5
ENUM_REALTIME_MARKET_STATE DetectRealtimeMarketState(int sig, int shift, STradeDecision &d)
{
    if(d.atr_state == "SPIKE" || d.atr_state == "CHAOS")
        return MS_CHAOS_SPIKE;

    if(d.squeeze_state == "BUILDUP" || d.squeeze_state == "ARMED")
        return MS_COMPRESSION;

    if(d.squeeze_state == "LOCKOUT" || d.spike_state == "LOCKOUT")
        return MS_FALSE_BREAK_LOCKOUT;

    if(d.squeeze_state == "BR_UP" || d.squeeze_state == "BR_DN")
        return MS_BREAKOUT_ATTEMPT;

    if(d.squeeze_state == "CONF_UP" || d.squeeze_state == "CONF_DN")
        return MS_CONFIRMED_BREAKOUT;

    if(d.wick_state == "BAD_BUY" || d.wick_state == "BAD_SELL")
        return MS_TRAP_RISK;

    if(d.vwap_state == "CHOP")
        return MS_VWAP_CHOP;

    if(d.h1_state == "BUY" && d.m15_state == "PULLBACK_BUY" && sig > 0)
        return MS_HEALTHY_PULLBACK;

    if(d.h1_state == "SELL" && d.m15_state == "PULLBACK_SELL" && sig < 0)
        return MS_HEALTHY_PULLBACK;

    if(d.h1_state == "BUY" && d.m15_state == "TREND_BUY" && sig > 0)
        return MS_ACTIVE_TREND;

    if(d.h1_state == "SELL" && d.m15_state == "TREND_SELL" && sig < 0)
        return MS_ACTIVE_TREND;

    return MS_NORMAL;
}
```

Field names must be adjusted to actual implementation.

---

# 9. Adaptive Rules Per Session

## 9.1 Asia Session

Old assumption:

```text
Asia = always sideway
```

New rule:

```text
Asia = defensive by default, but allow valid active trend.
```

Asia should block:

```text
1. COMPRESSION
2. VWAP_CHOP
3. TRAP_RISK
4. FALSE_BREAK_LOCKOUT
5. CHAOS_SPIKE
```

Asia may allow:

```text
1. ACTIVE_TREND
2. HEALTHY_PULLBACK
3. CONFIRMED_BREAKOUT
```

Pseudo:

```mq5
ENUM_FILTER_DECISION EvalAsiaPersonality(ENUM_REALTIME_MARKET_STATE ms, int sig, int shift, string &reason)
{
    if(ms == MS_COMPRESSION)
    {
        reason = "ASIA_COMPRESSION";
        return DEC_BLOCKED;
    }

    if(ms == MS_FALSE_BREAK_LOCKOUT)
    {
        reason = "ASIA_FALSE_BREAK_LOCKOUT";
        return DEC_BLOCKED;
    }

    if(ms == MS_CHAOS_SPIKE)
    {
        reason = "ASIA_SPIKE";
        return DEC_BLOCKED;
    }

    if(ms == MS_TRAP_RISK || ms == MS_VWAP_CHOP)
    {
        reason = "ASIA_CHOP_TRAP";
        return DEC_BLOCKED;
    }

    if(ms == MS_ACTIVE_TREND || ms == MS_HEALTHY_PULLBACK || ms == MS_CONFIRMED_BREAKOUT)
    {
        reason = "ASIA_VALID_STATE";
        return DEC_OK;
    }

    reason = "ASIA_LIMITED";
    return DEC_LIMITED;
}
```

---

## 9.2 London Open

Old assumption:

```text
London = breakout session
```

New rule:

```text
London Open = trap-prone breakout window.
```

London Open should block:

```text
1. Breakout attempt without follow-through.
2. Wick rejection after breakout.
3. Spike candle that closes back into range.
4. Compression false cross.
5. False break lockout.
```

London Open may allow:

```text
1. Confirmed breakout.
2. Healthy pullback after trap completed.
3. Active trend continuation after confirmation.
```

Pseudo:

```mq5
ENUM_FILTER_DECISION EvalLondonOpenPersonality(ENUM_REALTIME_MARKET_STATE ms, int sig, int shift, string &reason)
{
    if(ms == MS_BREAKOUT_ATTEMPT)
    {
        reason = "LONDON_WAIT_CONFIRM";
        return DEC_BLOCKED;
    }

    if(ms == MS_TRAP_RISK)
    {
        reason = "LONDON_TRAP_RISK";
        return DEC_BLOCKED;
    }

    if(ms == MS_FALSE_BREAK_LOCKOUT)
    {
        reason = "LONDON_FALSE_BREAK_LOCKOUT";
        return DEC_BLOCKED;
    }

    if(ms == MS_COMPRESSION)
    {
        reason = "LONDON_COMPRESSION";
        return DEC_BLOCKED;
    }

    if(ms == MS_CONFIRMED_BREAKOUT)
    {
        reason = "LONDON_CONFIRMED_BREAKOUT";
        return DEC_OK;
    }

    if(ms == MS_HEALTHY_PULLBACK || ms == MS_ACTIVE_TREND)
    {
        reason = "LONDON_TREND_OK";
        return DEC_OK;
    }

    reason = "LONDON_LIMITED";
    return DEC_LIMITED;
}
```

---

## 9.3 London Mid

London Mid is less trap-prone than London Open but still not automatically valid.

```mq5
ENUM_FILTER_DECISION EvalLondonMidPersonality(ENUM_REALTIME_MARKET_STATE ms, int sig, int shift, string &reason)
{
    if(ms == MS_FALSE_BREAK_LOCKOUT || ms == MS_CHAOS_SPIKE)
    {
        reason = "LONDON_MID_BLOCK";
        return DEC_BLOCKED;
    }

    if(ms == MS_COMPRESSION || ms == MS_TRAP_RISK)
    {
        reason = "LONDON_MID_LIMITED";
        return DEC_LIMITED;
    }

    reason = "LONDON_MID_OK";
    return DEC_OK;
}
```

---

## 9.4 New York / NY Open

Old assumption:

```text
NY = trend / high volatility
```

New rule:

```text
NY = high-volatility window with strict spike/news protection.
```

NY should block:

```text
1. News window.
2. ATR chaos spike.
3. Spike candle without follow-through.
4. False break lockout.
5. Spread spike / slippage risk.
```

NY may allow:

```text
1. Healthy pullback after volatility normalizes.
2. Confirmed breakout.
3. Active trend continuation.
```

Pseudo:

```mq5
ENUM_FILTER_DECISION EvalNYPersonality(ENUM_REALTIME_MARKET_STATE ms, int sig, int shift, string &reason)
{
    if(IsInNewsWindow(TimeCurrent()))
    {
        reason = "NY_NEWS_WINDOW";
        return DEC_BLOCKED;
    }

    if(ms == MS_CHAOS_SPIKE)
    {
        reason = "NY_CHAOS_SPIKE";
        return DEC_BLOCKED;
    }

    if(ms == MS_FALSE_BREAK_LOCKOUT)
    {
        reason = "NY_FALSE_BREAK_LOCKOUT";
        return DEC_BLOCKED;
    }

    if(ms == MS_TRAP_RISK)
    {
        reason = "NY_TRAP_RISK";
        return DEC_BLOCKED;
    }

    if(ms == MS_CONFIRMED_BREAKOUT || ms == MS_HEALTHY_PULLBACK || ms == MS_ACTIVE_TREND)
    {
        reason = "NY_VALID_STATE";
        return DEC_OK;
    }

    reason = "NY_LIMITED";
    return DEC_LIMITED;
}
```

---

# 10. Main Eval Function

```mq5
ENUM_FILTER_DECISION EvalSessionAdaptivePersonality(
    int sig,
    int shift,
    STradeDecision &d,
    string &session_tag,
    string &market_state,
    string &reason
)
{
    if(!InpUseSessionAdaptivePersonality)
    {
        session_tag = "OFF";
        market_state = "OFF";
        reason = "SESSION_ADAPT_OFF";
        return DEC_OK;
    }

    ENUM_SESSION_TAG ses = GetSessionTag(iTime(_Symbol, PERIOD_M5, shift));
    ENUM_REALTIME_MARKET_STATE ms = DetectRealtimeMarketState(sig, shift, d);

    session_tag = SessionTagToString(ses);
    market_state = MarketStateToString(ms);

    switch(ses)
    {
        case SES_ASIA:
            return EvalAsiaPersonality(ms, sig, shift, reason);

        case SES_LONDON_OPEN:
            return EvalLondonOpenPersonality(ms, sig, shift, reason);

        case SES_LONDON_MID:
            return EvalLondonMidPersonality(ms, sig, shift, reason);

        case SES_NY_PRE_NEWS:
        case SES_NY_OPEN:
        case SES_NY_OVERLAP:
        case SES_NY_LATE:
            return EvalNYPersonality(ms, sig, shift, reason);

        default:
            reason = "SESSION_NEUTRAL";
            return DEC_OK;
    }
}
```

---

# 11. Integration Into Final Decision

In `STradeDecision`, add:

```mq5
ENUM_FILTER_DECISION session_decision;
string session_tag;
string market_state;
string session_reason;
```

Decision chain:

```text
If session_decision == DEC_BLOCKED:
    final_class = SC_BLOCKED
    allow_entry = false
    main_reason = session_reason

If session_decision == DEC_LIMITED:
    final_class = SC_SOFT / LIMITED
    allow_entry = true
    append reason
```

Important:

```text
If earlier guard already BLOCKED, session layer must not overwrite the main reason unless it is more severe or more specific.
```

Example:

```text
F2_DISTANCE should stay main reason if F2 blocked.
SQ_LOCKOUT should stay main reason if squeeze blocked.
Session reason can be appended to reason_chain.
```

---

# 12. ScanHistory Requirement

Phase 3 must work in ScanHistory.

Historical labels must show:

```text
VALID
LIMITED
BLOCKED
```

and include reasons like:

```text
ASIA_COMPRESSION
ASIA_VALID_STATE
LONDON_WAIT_CONFIRM
LONDON_TRAP_RISK
LONDON_CONFIRMED_BREAKOUT
NY_CHAOS_SPIKE
NY_NEWS_WINDOW
```

Critical requirement:

```text
Use iTime(_Symbol, PERIOD_M5, shift) for historical session tagging.
Do not use TimeCurrent() for historical ScanHistory except live-only checks.
```

For News Guard in historical mode:

```text
If no historical news schedule is available, skip news guard or only use manually configured intraday news times.
```

---

# 13. Dashboard Additions

Add dashboard rows:

```text
SESSION : ASIA / LON-OPEN / LON-MID / NY / OTHER
MSTATE  : COMPRESSION / ACTIVE_TREND / TRAP / CHAOS / ...
S-ADAPT : OK / LIMITED / BLOCKED
S-REASON: LONDON_TRAP_RISK / ASIA_VALID_STATE / ...
```

Example:

```text
SESSION : LON-OPEN
MSTATE  : BREAKOUT_ATTEMPT
S-ADAPT : BLOCKED
S-REASON: LONDON_WAIT_CONFIRM
```

---

# 14. Shadow Logger Additions

Add these columns:

```text
session_tag
market_state
session_decision
session_reason
```

This allows analysis like:

```text
Which session produces the most loss?
Which session blocks the most valid signals?
Does London trap guard improve performance?
Is Asia really bad, or does Asia active trend perform well?
Does NY spike guard reduce drawdown?
```

---

# 15. Testing Plan Phase 3

Test in this order:

```text
Test 1:
Phase 1 Clean Core only.

Test 2:
Phase 1 + Phase 2 Advanced Modules.

Test 3:
Phase 1 + Phase 2 + Session Adaptive Personality ON.

Test 4:
Asia only analysis.

Test 5:
London Open analysis.

Test 6:
NY analysis.

Test 7:
All sessions combined.
```

Metrics:

```text
Net profit
Profit factor
Max DD
Average loss
Consecutive loss
Trade count
Valid signal count
Limited signal count
Blocked signal count
Most common session reason
Worst session
Best session
False-break block accuracy
Session-specific win rate
Session-specific profit factor
```

Do not judge Phase 3 by total profit only.  
Judge it by:

```text
1. Whether it reduces false-break losses.
2. Whether it avoids London traps.
3. Whether it still allows Asia valid trend.
4. Whether it prevents NY spike chaos.
5. Whether it does not over-block clean M5 trend continuation.
```

---

# 16. What Phase 3 Must Not Do

Do not implement:

```text
1. Asia hard block.
2. London auto breakout entry.
3. NY auto trend entry.
4. Session-based martingale.
5. Session-based grid.
6. M1 entry.
7. Reintroducing IF or Market Regime.
8. Reintroducing old Soft TP/SL mode.
9. Overwriting core reason chain.
```

---

# 17. Final Phase 3 Summary

Phase 3 should make EA smarter about market time, but not dependent on market time.

Final concept:

```text
Session-aware, state-driven M5 trend-following EA.
```

Meaning:

```text
Clock/session gives context.
ATR/Squeeze/SidewaySpike/Wick/VWAP gives actual market state.
H1/M15 gives directional context.
M5 gives execution.
Decision Engine gives final VALID/LIMITED/BLOCKED.
ScanHistory proves the logic visually.
Shadow Logger proves the logic statistically.
```

The goal is not to predict session behavior.  
The goal is to prevent the EA from treating all market hours the same while still respecting real-time XAUUSD behavior.
