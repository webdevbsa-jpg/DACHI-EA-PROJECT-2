# DACHI TRADER — M5 Institutional Rulebook

Tanggal penyusunan: 2026-06-07  
Basis data: Auto Journal raw baseline M1/M5/M15/M30, all filter OFF kecuali spread, all exit gate OFF.  
Target utama: XAUUSD intraday/scalping dengan M5 sebagai execution timeframe.

---

## 1. Executive Summary

Berdasarkan hasil journal baseline:

- **M1** terlalu noisy dan tidak layak menjadi entry generator utama.
- **M5** adalah timeframe terbaik untuk execution karena signal cukup banyak dan masih punya edge positif.
- **M15** paling cocok sebagai setup/context confirmation.
- **M30** paling cocok sebagai higher intraday bias/context.
- Core MA crossing masih punya edge di M5/M15/M30, sehingga belum perlu mengganti engine entry.
- Yang perlu diperbaiki adalah **market selection**, **risk structure**, dan **filter treatment**, bukan core crossing.

Struktur baku EA:

```text
M30 = directional bias / macro intraday context
M15 = setup confirmation
M5  = execution entry
M1  = OFF / optional visual micro-confirmation only
```

---

## 2. Baseline Timeframe Decision

| Timeframe | Keputusan | Catatan |
|---|---|---|
| M1 | Tidak dipakai entry utama | Raw PF negatif, terlalu noise, raw position result lebih buruk. |
| M5 | Execution utama | Edge positif tapi tipis; jangan over-filter. |
| M15 | Setup/context | Lebih bersih; cocok untuk ADX/DI/V-Line/angle confirmation. |
| M30 | Bias/context | Paling bersih secara raw expectancy; cocok untuk directional context. |

---

## 3. Core Entry Rule

Entry utama tetap memakai:

```text
M5 EMA Fast / MA Slow crossing pada bar close.
```

Default MA yang dipakai:

```text
Fast MA : EMA 8
Slow MA : LWMA 20
Execution TF : M5
```

Rule dasar:

### BUY

```text
Fast MA cross above Slow MA pada M5 bar close.
```

### SELL

```text
Fast MA cross below Slow MA pada M5 bar close.
```

Entry hanya boleh diproses setelah:

1. spread check lolos,
2. tidak ada posisi aktif jika mode one-position-at-a-time aktif,
3. context/filter rule tidak memblok,
4. risk profile SL/TP terbentuk.

---

## 4. Higher Timeframe Context

### M30 Bias

M30 dipakai sebagai directional context utama.

Rule:

```text
Jika M30 bullish, BUY lebih diprioritaskan.
Jika M30 bearish, SELL lebih diprioritaskan.
Jika M30 neutral/noise, entry M5 harus lebih selektif.
```

M30 tidak harus selalu menjadi hard blocker, tetapi harus menjadi context scoring.

### M15 Setup

M15 dipakai sebagai setup confirmation.

Rule:

```text
M15 harus menunjukkan struktur yang tidak melawan entry M5.
```

Untuk mode conservative:

```text
M15 harus align dengan direction M5.
```

Untuk mode balanced:

```text
M15 boleh neutral, tetapi tidak boleh berlawanan kuat.
```

---

## 5. ADX / DI Rules

Dari baseline, ADX tidak boleh dipakai sebagai rule minimum sederhana. Khususnya pada M5, ADX terlalu tinggi bisa menandakan entry terlambat / extended move.

### M5 ADX Band-Pass

Rule baku M5:

```text
Preferred ADX: 15–30
Avoid ADX < 15
Treat ADX > 30 as caution / LIMITED, not automatic valid
```

Recommended:

```text
M5 ADX < 15     = BLOCK / no trade
M5 ADX 15–30    = valid zone
M5 ADX 30–40    = LIMITED / caution
M5 ADX > 40     = avoid unless strong HTF context
```

### M15 ADX

Rule baku M15:

```text
ADX >= 18 preferred
ADX < 18 = weak setup
```

### M30 ADX

Rule baku M30:

```text
ADX 15–40 preferred
ADX < 15 = weak/noisy
ADX >= 40 = extended; avoid chase unless pullback/retest
```

### DI Direction

BUY confirmation:

```text
DI+ > DI-
```

SELL confirmation:

```text
DI- > DI+
```

DI alignment wajib untuk:

- BRE,
- conservative entry profile,
- M15 setup validation.

DI alignment tidak wajib sebagai hard block untuk all M5 entries pada balanced profile, karena M5 early reversal bisa muncul sebelum DI sepenuhnya align.

---

## 6. V-Line Rules

V-Line tidak dijadikan hard guard universal untuk M5 entry.

Rule baku:

```text
V-Line hard guard untuk entry awal = OFF by default.
V-Line visual = ON.
V-Line sebagai BRE alignment/veto = ON.
```

Artinya:

- Jika V-Line bearish, BRE BUY tidak boleh fire.
- Jika V-Line bullish, BRE SELL tidak boleh fire.
- Jika V-Line neutral/no-data, BRE ditahan jika `BlockNeutralVLine=true`.

### V-Line State Treatment

| V-Line State | Treatment |
|---|---|
| BULL + BUY | Preferred |
| BEAR + SELL | Preferred |
| BULL + SELL | Caution / only if reversal setup kuat |
| BEAR + BUY | Caution / only if reversal setup kuat |
| BULL NOISE | Avoid / LIMITED |
| BEAR NOISE | Avoid / LIMITED |

Catatan:

V-Line alignment sangat berguna pada M15/M30, tetapi jika dijadikan hard blocker pada M5 dapat membunuh early reversal. Karena itu V-Line lebih baik menjadi **context + BRE veto**, bukan hard entry filter universal.

---

## 7. SW / Sideway Clustering Rules

SW / Sideway Clustering tetap dipakai, tetapi default harus **F_SOFT**, bukan F_HARD.

Rule baku:

```text
SW Action = F_SOFT
SW CHOP = LIMITED
SW CHOP + no trend override + bad ADX/DI = BLOCK candidate
```

Recommended default:

```text
InpSW_Action = F_SOFT
InpSW_ChopThreshold = 0.86
InpSW_MixedThreshold = 0.65
InpSW_DirectionalBalanceMax = 0.18
InpSW_BodyDominanceMax = 0.34
InpSW_UseTrendOverride = true
```

Trend override harus mengizinkan signal tetap valid jika:

- MA alignment searah,
- slow MA angle tidak buruk,
- ADX cukup,
- DI direction searah.

SW jangan langsung F_HARD sampai blocked-winner rate terbukti rendah.

---

## 8. Slow MA Angle Rules

Slow MA Angle tidak boleh memakai threshold universal untuk semua timeframe.

### M5

Dari data baseline, M5 justru banyak winner saat slow angle masih flat/awal berubah.

Rule:

```text
M5 SlowMA Angle Guard = OFF
atau threshold = 0°
```

Jangan pakai 3–5° sebagai hard requirement untuk M5 balanced entry.

### M15

Rule:

```text
M15 SlowMA angle boleh digunakan sebagai confirmation ringan.
Threshold: 0–3°
```

### M30

Rule:

```text
M30 SlowMA angle cocok untuk trend confirmation.
Threshold: 3–5°
```

---

## 9. Risk / SL / TP Rules

Karena raw winrate hanya sekitar 31–33%, sistem ini butuh RR lebih besar dari 1:1.

### Default Execution Risk Profile: M5 Balanced

Gunakan ini sebagai default EA utama:

```text
SL Active : 900 points

TP1 : 900 points
TP2 : 1800 points
TP3 : 2700 points
TP4 : 3600 points
TP5 : 5000 points
```

### Management

```text
TP1 hit -> partial kecil / BE preparation
TP2 hit -> BE lock wajib / partial utama
TP3 hit -> runner management
TP4/TP5 -> trend runner only
```

Jika single TP:

```text
SL : 900 points
TP : 2200 points
```

RR:

```text
2200 / 900 = ±2.44R
```

Ini cocok untuk system dengan winrate ±32%.

---

## 10. Alternative Risk Profiles

### M15 Context Profile

```text
SL Active : 1500 points

TP1 : 1500
TP2 : 3000
TP3 : 4500
TP4 : 6000
TP5 : 9000
```

### M30 Swing/Bias Profile

```text
SL Active : 2100 points

TP1 : 2100
TP2 : 4200
TP3 : 6300
TP4 : 8400
TP5 : 12000
```

### M1 Aggressive Profile

Not recommended as core.

If forced:

```text
SL Active : 400–500 points

TP1 : 500
TP2 : 900–1000
TP3 : 1300–1500
```

---

## 11. ATR-Based Risk Option

Fixed SL/TP is good for baseline, but XAUUSD volatility changes. Professional mode should support ATR-based SL.

### M5 ATR Dynamic

```text
SL = 0.7–0.9 × ATR_points
SL floor = 700 points
SL cap   = 1200 points
TP2 = 2.0 × SL
TP3 = 3.0 × SL
```

### M15 ATR Dynamic

```text
SL = 0.8–1.0 × ATR_points
SL floor = 1200 points
SL cap   = 2200 points
TP2 = 2.0 × SL
TP3 = 3.0 × SL
```

### M30 ATR Dynamic

```text
SL = 1.0–1.2 × ATR_points
SL floor = 1800 points
SL cap   = 3200 points
TP2 = 2.0 × SL
TP3 = 3.0 × SL
```

---

## 12. Entry Workflow

### Step 1 — Detect M5 Cross

EA waits for M5 bar close.

```text
If fast MA crosses slow MA upward -> BUY candidate
If fast MA crosses slow MA downward -> SELL candidate
```

### Step 2 — Spread Check

```text
If spread > max allowed -> skip / log MARKET_BLOCK
```

### Step 3 — F2 Distance Check

```text
If crossing-to-entry distance too far -> BLOCK or candidate for BRE
```

### Step 4 — M15/M30 Context

Balanced mode:

```text
M30/M15 opposing strongly -> LIMITED/BLOCK depending mode
Neutral -> allowed with stronger M5 confirmation
Aligned -> preferred
```

Conservative mode:

```text
M15 or M30 must align
```

### Step 5 — ADX Band Check

For M5:

```text
ADX < 15 -> BLOCK
ADX 15–30 -> allowed
ADX 30–40 -> LIMITED / avoid chase
ADX > 40 -> BLOCK unless pullback/retest
```

### Step 6 — SW Check

```text
SW ORDER/TREND/TREND_OVR -> allowed
SW MIXED -> caution
SW CHOP -> LIMITED
SW CHOP + no override + weak ADX/DI -> BLOCK
```

### Step 7 — V-Line Context

```text
V-Line align -> quality boost
V-Line oppose -> caution
V-Line noise -> limited/avoid
```

### Step 8 — Entry Approval

If no hard block:

```text
SetupTrade()
Draw Entry/SL/TP
Open position if trading mode active
Write Auto Journal row
```

---

## 13. BRE Workflow

BRE = Blocked Retest Re-entry.

BRE exists to recover good signals that were blocked too early.

### BRE Should Be Allowed For

Recommended allowed block reasons:

```text
F2
SLOW_ANGLE
V_LINE
HTF/context mismatch in balanced mode
```

### BRE Should Be Disabled By Default For

```text
SW
SIDEWAY
SQUEEZE
ATR_HEALTH
FILTER/OTHER
```

Reason:

If the original block reason is sideway/chop, re-entry can become dangerous.

### BRE Requirements

BUY BRE:

```text
Retest to MA band
Close back above band
DI+ > DI-
ADX >= 18
ADX rising preferred
V-Line not bearish
```

SELL BRE:

```text
Retest to MA band
Close back below band
DI- > DI+
ADX >= 18
ADX rising preferred
V-Line not bullish
```

### BRE Risk Treatment

Default:

```text
BRE as LIMITED = true
```

Meaning:

- tighter TP/SL,
- lower risk,
- more defensive handling.

If journal later proves BRE has strong expectancy:

```text
BRE as VALID = allowed
```

---

## 14. Exit Workflow

### Default

Use M5 risk profile:

```text
SL 900
TP1 900
TP2 1800
TP3 2700
TP4 3600
TP5 5000
```

### After TP1

```text
Move management toward BE preparation.
Optional partial close.
```

### After TP2

```text
BE lock mandatory.
Partial close recommended.
```

### After TP3

```text
Runner mode.
Trailing or Progressive Exit may activate.
```

### Opposite Signal

If opposite M5 cross appears:

```text
Close existing position or mark signal_exit_price in journal.
Do not instantly reverse unless reverse-entry mode is explicitly enabled.
```

---

## 15. Auto Journal Rules

Auto Journal must remain ON during optimization.

Required fields:

```text
signal_entry_price
signal_exit_price
position_exit_price
signal_result
position_result
block_reason
bre_reason
ADX
DI+
DI-
ATR
spread
MA gap
SlowMA angle
V-Line state/dir
SW state/score
SL/TP profile
```

Analysis priority:

1. Compare signal_result vs position_result.
2. Identify filters that would have removed losing trades.
3. Identify filters that would have killed winning trades.
4. Tune one variable at a time.
5. Do not activate many filters simultaneously without A/B test.

---

## 16. Rules That Must Not Be Violated

1. Do not use M1 as primary entry generator.
2. Do not use V-Line as universal hard blocker for M5 entry.
3. Do not use SlowMA Angle 3–5° as hard requirement on M5.
4. Do not use ADX minimum-only logic; use band-pass logic.
5. Do not make SW hard-block by default.
6. Do not allow BRE from sideway/chop block reasons by default.
7. Do not use 1:1 RR as default because raw winrate is too low.
8. Do not optimize only by net profit; check expectancy by ADX/ATR/DI/V-Line/SW bins.
9. Do not change core MA crossing before confirming market-selection improvements fail.
10. Always update archive and version when EA logic changes.

---

## 17. Recommended Next Coding Plan

### Phase 1 — Risk Profile Preset

Add:

```text
RISK_M5_BALANCED
RISK_M15_CONTEXT
RISK_M30_SWING
```

Default:

```text
RISK_M5_BALANCED
```

### Phase 2 — ADX Band Guard

Add:

```text
InpUseADXBandGuard
InpADX_MinAllowed
InpADX_MaxAllowed
InpADX_ExtremeAction
```

For M5:

```text
Min = 15
Max = 30
```

### Phase 3 — V-Line Noise Guard

Add:

```text
InpUseVLineNoiseGuard
InpVLineNoiseAction = LIMITED / BLOCK
```

Default:

```text
LIMITED
```

### Phase 4 — Timeframe-Aware Filter Profile

Add:

```text
PROFILE_M5_BALANCED
PROFILE_M5_CONSERVATIVE
PROFILE_M30_BIAS
```

Each profile sets recommended ADX, SW, angle, V-Line, and BRE behavior.

### Phase 5 — Analyzer Upgrade

Add new analysis bins:

```text
SlowMA angle align/opposed with signal
V-Line noise separated by direction
ADX rising/falling if data exists
MA gap normalized by ATR
```

---

## 18. Default Recommended Preset

```text
Execution TF = M5
M1 Entry = OFF
M15 Context = ON
M30 Bias = ON

V-Line hard guard = OFF
V-Line visual = ON
BRE V-Line alignment = ON

SW Action = F_SOFT
SW Trend Override = ON

SlowMA Angle Guard M5 = OFF / 0°

ADX Band Guard:
  M5 Min = 15
  M5 Max = 30

BRE:
  Enabled = ON
  BRE as Limited = ON
  ADX Min = 18
  Require DI Direction = ON
  Require ADX Rising = ON
  Allow SW Blocks = OFF
  Allow Sideway Blocks = OFF

Risk:
  SL = 900
  TP1 = 900
  TP2 = 1800
  TP3 = 2700
  TP4 = 3600
  TP5 = 5000
```

---

## 19. Final Institutional View

Dachi EA should not be treated as a high-winrate scalper.

It is a **low-winrate, positive-fat-tail MA-cross system** that becomes viable when:

1. M1 noise is removed,
2. M5 is used only for execution,
3. M15/M30 provide context,
4. ADX is used as band-pass,
5. SW is soft-filtered,
6. V-Line is used as context/BRE veto,
7. risk uses minimum 2R target structure,
8. journal feedback is used after every backtest.

The goal is not to catch every signal.

The goal is to only take the subset of M5 crosses that have enough market structure to justify the 2R–3R target.
