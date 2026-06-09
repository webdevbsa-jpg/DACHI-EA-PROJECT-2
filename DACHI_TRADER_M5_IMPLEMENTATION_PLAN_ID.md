# DACHI TRADER — M5 Implementation Plan & Operating Workflow

Tanggal: 2026-06-08  
Dokumen terkait: `DACHI_TRADER_M5_RULEBOOK_ID.md`  
Tujuan: memisahkan **plan implementasi teknis** dari rulebook strategi agar fase coding berikutnya jelas, terukur, dan tidak mencampur aturan trading dengan task engineering.

---

## 1. Prinsip Utama

EA Dachi tidak boleh diubah menjadi sistem yang terlalu banyak filter tanpa bukti journal.

Baseline journal menunjukkan struktur paling masuk akal:

```text
M30 = directional bias / macro intraday context
M15 = setup / confirmation
M5  = execution entry
M1  = OFF sebagai entry generator
```

Core MA crossing tetap dipertahankan. Yang ditambahkan adalah **market selection**, **risk preset**, dan **workflow exit/re-entry** yang lebih disiplin.

---

## 2. Target Build Berikutnya

Target rilis berikutnya setelah rulebook ini:

```text
Dachi_Trader_v13_11_45.mq5
```

Wajib mengikuti SOP:

1. Rename/copy file aktif ke versi baru.
2. Update header version.
3. Update `#property version`.
4. Update description/version payload/license string jika ada.
5. Update init/deinit log version.
6. Bump logic marker di `ComputeFilterHash()`.
7. Update `DACHI_TRADER_SESSION_ARCHIVE_ID.md`.
8. Jika perubahan rule besar, update `DACHI_TRADER_M5_RULEBOOK_ID.md`.
9. Compile di MetaEditor sebelum backtest.
10. Jalankan Auto Journal untuk validasi.

---

## 3. Phase 1 — Risk Profile Preset

### Tujuan

Menerjemahkan hasil journal baseline menjadi preset SL/TP yang konsisten dan mudah dipilih user.

### Input yang disarankan

```mql5
enum ENUM_RISK_PROFILE
{
   RISK_MANUAL = 0,
   RISK_M5_BALANCED = 1,
   RISK_M15_CONTEXT = 2,
   RISK_M30_SWING = 3
};

input ENUM_RISK_PROFILE InpRiskProfile = RISK_M5_BALANCED;
input bool InpRiskProfileAllowManualOverride = true;
```

### Preset

#### RISK_M5_BALANCED

```text
SL  = 900 points
TP1 = 900
TP2 = 1800
TP3 = 2700
TP4 = 3600
TP5 = 5000
```

#### RISK_M15_CONTEXT

```text
SL  = 1500 points
TP1 = 1500
TP2 = 3000
TP3 = 4500
TP4 = 6000
TP5 = 9000
```

#### RISK_M30_SWING

```text
SL  = 2100 points
TP1 = 2100
TP2 = 4200
TP3 = 6300
TP4 = 8400
TP5 = 12000
```

### Acceptance Criteria

- Jika `RISK_M5_BALANCED`, visual ENTRY/SL/TP memakai SL 900 dan TP ladder M5.
- Jika `RISK_MANUAL`, input existing tidak berubah.
- Auto Journal mencatat `risk_profile` pada setiap signal.
- Historical Scan dan live mode memakai nilai yang sama.

---

## 4. Phase 2 — ADX Band Guard

### Tujuan

Menghindari kelemahan ADX minimum-only. Journal menunjukkan M5 paling sehat pada ADX 15–30 dan berisiko jika ADX terlalu rendah atau terlalu tinggi.

### Input yang disarankan

```mql5
input bool InpUseADXBandGuard = true;
input double InpADX_MinAllowed = 15.0;
input double InpADX_MaxAllowed = 30.0;
input ENUM_FILTER_ACTION InpADX_LowAction = F_HARD;
input ENUM_FILTER_ACTION InpADX_HighAction = F_SOFT;
```

### Rule M5

```text
ADX < 15  -> BLOCK
ADX 15–30 -> VALID zone
ADX > 30  -> LIMITED / caution
ADX > 40  -> candidate BLOCK if no HTF alignment
```

### Acceptance Criteria

- Dashboard menampilkan row `ADX Band`.
- Block reason baru: `ADX_BAND`.
- Jika high ADX action soft, signal menjadi `LIMITED`, bukan blocked.
- Auto Journal mencatat ADX value dan ADX band state.

---

## 5. Phase 3 — V-Line Noise Guard

### Tujuan

V-Line tidak menjadi hard blocker universal untuk M5, tetapi state noise perlu diperlakukan khusus karena journal menunjukkan noise state dapat menjadi area loss.

### Input yang disarankan

```mql5
input bool InpUseVLineNoiseGuard = true;
input ENUM_FILTER_ACTION InpVLineNoiseAction = F_SOFT;
```

### Rule

```text
V-Line BULL + BUY       -> preferred
V-Line BEAR + SELL      -> preferred
V-Line opposite         -> caution
V-Line BULL NOISE       -> LIMITED / avoid
V-Line BEAR NOISE       -> LIMITED / avoid
```

### Acceptance Criteria

- V-Line hard entry guard tetap default OFF untuk M5.
- V-Line tetap aktif sebagai visual/context.
- BRE tetap memakai V-Line alignment veto.
- Jika V-Line noise action soft, signal menjadi `LIMITED`.
- Journal mencatat `VLINE_NOISE` atau state setara.

---

## 6. Phase 4 — SW / Sideway Clustering Finalization

### Tujuan

SW tetap soft terlebih dahulu, bukan hard-block default.

### Default M5

```text
InpSW_Action = F_SOFT
InpSW_ChopThreshold = 0.86
InpSW_MixedThreshold = 0.65
InpSW_DirectionalBalanceMax = 0.18
InpSW_BodyDominanceMax = 0.34
InpSW_UseTrendOverride = true
```

### Rule

```text
SW ORDER/TREND/TREND_OVR -> allow
SW MIXED                 -> caution
SW CHOP                  -> LIMITED
SW CHOP + weak trend     -> candidate BLOCK
```

### Acceptance Criteria

- SW state terlihat di dashboard.
- SW trend override terlihat jelas sebagai `TREND_OVR`.
- BRE default tetap tidak mengizinkan re-entry dari SW block.
- Journal mencatat SW state dan SW score.

---

## 7. Phase 5 — Analyzer Upgrade

### Tujuan

Analyzer saat ini membaca angle sebagai absolut. Untuk trading, yang lebih penting adalah apakah angle **searah signal** atau **melawan signal**.

### Tambahan analyzer

Tambahkan bin:

```text
ANGLE_ALIGN
ANGLE_OPPOSE
ANGLE_FLAT
```

Rule:

```text
BUY  + angle positif -> ANGLE_ALIGN
BUY  + angle negatif -> ANGLE_OPPOSE
SELL + angle negatif -> ANGLE_ALIGN
SELL + angle positif -> ANGLE_OPPOSE
abs(angle) < 1       -> ANGLE_FLAT
```

### Acceptance Criteria

- Report punya table `By Slow MA angle alignment`.
- Bisa membedakan BUY dengan angle +12 vs BUY dengan angle -12.
- Bisa dipakai untuk memutuskan apakah SlowMA Angle Guard cocok untuk M5 atau hanya untuk M15/M30.

---

## 8. Entry Workflow Baku

### Step 1 — M5 Cross Detection

```text
BUY  = Fast MA crosses above Slow MA on M5 bar close
SELL = Fast MA crosses below Slow MA on M5 bar close
```

### Step 2 — Market Precheck

```text
Spread <= max spread
Daily/session constraints pass
License/trading mode pass
```

### Step 3 — Risk Profile Load

```text
Load RISK_M5_BALANCED by default
Set SL/TP ladder before drawing visual lines
```

### Step 4 — Context Check

```text
M30 bias checked
M15 setup checked
```

### Step 5 — Quality Gate

```text
F2 distance check
ADX Band check
SW state check
V-Line noise/context check
Optional SlowMA Angle depending TF/profile
```

### Step 6 — Classification

```text
VALID   = all required gates pass
LIMITED = soft guard warning but not hard rejection
BLOCKED = hard guard rejection
```

### Step 7 — Execution

```text
If VALID or allowed LIMITED -> SetupTrade + EAOpen
If BLOCKED -> label blocked + possible BRE arm if reason allowed
Always write Auto Journal event
```

---

## 9. BRE Workflow Baku

### BRE Purpose

BRE hanya untuk mengambil ulang signal bagus yang blocked terlalu awal, bukan untuk menyelamatkan semua signal sideway.

### BRE Allowed Reasons

```text
F2
SLOW_ANGLE
V_LINE
HTF/context mismatch in balanced mode
```

### BRE Disallowed Default Reasons

```text
SW
SIDEWAY
SQUEEZE
ATR_HEALTH
FILTER/OTHER
```

### BRE Fire Requirements

BUY:

```text
Retest MA band
Close back above MA band
DI+ > DI-
ADX >= 18
ADX rising preferred
V-Line not bearish
```

SELL:

```text
Retest MA band
Close back below MA band
DI- > DI+
ADX >= 18
ADX rising preferred
V-Line not bullish
```

### BRE Risk

```text
Default: BRE as LIMITED
If journal proves strong expectancy: allow BRE as VALID
```

---

## 10. Exit Workflow Baku

### Default M5 Ladder

```text
SL  = 900
TP1 = 900
TP2 = 1800
TP3 = 2700
TP4 = 3600
TP5 = 5000
```

### Management

```text
TP1 hit -> partial kecil / BE preparation
TP2 hit -> BE lock mandatory
TP3 hit -> runner management
TP4/TP5 -> trend runner only
```

### Opposite Signal

```text
Opposite cross closes or marks signal_exit_price.
Do not auto reverse unless reverse-entry mode is explicitly enabled.
```

---

## 11. Testing Workflow

### Test A — Compile

```text
Compile Dachi_Trader_v13_11_45.mq5 in MetaEditor
No compile errors
Warnings documented if unavoidable
```

### Test B — Visual Attach

```text
Attach to XAUUSD M5
Verify dashboard rows:
- Risk Profile
- ADX Band
- SW / Sideway Clustering
- V-Line
- BRE state
```

### Test C — Backtest Raw vs Profile

Run two backtests:

```text
1. Raw baseline-like settings
2. M5 Balanced profile settings
```

Compare:

```text
signal_result
position_result
block_reason
risk_profile
ADX band state
V-Line state
SW state
```

### Test D — Auto Journal

Auto Journal must prove:

- all signals recorded,
- blocked signals recorded,
- re-entry signals recorded,
- position exit recorded separately from signal exit,
- risk profile recorded.

---

## 12. Implementation Order

Recommended order:

```text
1. Risk Profile Preset
2. ADX Band Guard
3. V-Line Noise Guard
4. Analyzer angle alignment upgrade
5. Timeframe-aware profile preset
```

Do not implement all changes without backtest separation. Each phase must be A/B tested.

---

## 13. Success Criteria

A change is accepted only if journal shows improvement in at least two of these:

1. Position profit factor improves.
2. Net position points improve.
3. Worst loss tail decreases.
4. Losses in ADX low/high bins decrease.
5. M5 signal density remains acceptable.
6. Blocked-winner rate does not become excessive.
7. BRE win quality improves or false BRE drops.

---

## 14. Final Notes

Dachi EA should be managed as a journal-driven execution engine.

The goal is not to predict every market turn. The goal is to take only M5 crosses where:

```text
market structure + context + volatility + risk profile
```

justify the trade.

The default operating assumption:

```text
Dachi = low-winrate, positive-fat-tail system
```

Therefore risk profile, trade selection, and journal feedback are more important than adding many filters blindly.
