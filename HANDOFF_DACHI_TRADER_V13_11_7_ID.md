# Handoff Proyek — Dachi Trader EA v13.11.7

Tanggal handoff: 2026-05-25
Branch kerja: `work`
EA aktif: `Dachi_Trader_v13_11_7.mq5`

Supersede: `docs/HANDOFF_DACHI_TRADER_V13_11_0_ID.md`.

## 1) Ringkasan perubahan terakhir (v13.11.3 → v13.11.7)

### v13.11.3
- Implementasi awal plan improvement v2 pada regime gating.
- Perbaikan kalkulasi range (`shift+1`) agar candle sinyal tidak ikut boundary range.

### v13.11.4
- Sempat diubah ke model ON/OFF murni blocker (semua filter ON+trigger jadi block).
- Model ini ditolak karena tidak sesuai kebutuhan klasifikasi SOFT/HARD.

### v13.11.5
- Dikembalikan ke model yang benar:
  - **Setiap filter tetap ON/OFF**.
  - Jika ON+trigger dan class **SOFT** → LIMITED (`g_pipe_soft`).
  - Jika ON+trigger dan class **HARD** → BLOCKED (`g_pipe_hard`).
- Sinkronisasi juga diterapkan di evaluator historical (`EvaluatePipelineAt`).

### v13.11.6
- Regime over-blocking diperbaiki:
  - `MarketRegimeBlocks()` hanya block untuk **opposite-direction breakout** eksplisit (`LONG_RANGING` dan `EARLY_BREAKOUT`).
  - Regime lain menjadi non-blocking guidance.
- `RegimeLabelClass()` mengubah CHOPPY/RANGING/LONG_RANGING/EARLY_BREAKOUT menjadi `SC_SOFT` agar chart tidak banjir label BLOCKED pada regime-only mode.

### v13.11.7 (current)
- Tuning default difokuskan ke **M5 profile**:
  - F0 = SOFT + ATR% ON (35%)
  - F1 = SOFT (margin 3.0)
  - F2 = HARD (max dist 1.7 ATR)
  - F4 = SOFT (lookback 4, min slope 0.6)
  - F5 = SOFT (period 12, OB/OS ±0.72, signal-line ON)
  - IF ON + exhaustion ON
  - Wick filter ON (min wick ratio 0.60)
  - Regime ON + parameter ER/lookback lebih responsif untuk M5
  - Session weekdays Mon–Fri ON

## 2) Identitas versi saat ini (wajib sinkron)

Pada `Dachi_Trader_v13_11_7.mq5` semua identifier sudah sinkron:
- Filename: `Dachi_Trader_v13_11_7.mq5`
- Header version: `13.11.7`
- `#property version "13.11.7"`
- `#property description "Dachi Trader v13.11.7 — Expert Advisor"`
- License payload: `"ea_version":"13.11.7"`
- Init/deinit log: `v13.11.7`
- Logic hash marker: `0x13C00070`

## 3) Behavior operasional yang perlu diingat

1. **Filter semantics**
   - ON/OFF hanya menentukan aktif/tidak.
   - Saat aktif dan trigger, aksi ikut class:
     - `F_SOFT` => LIMITED (tidak memblok entry)
     - `F_HARD` => BLOCKED (memblok entry)

2. **Regime semantics (v13.11.6+)**
   - Label regime dominan sebagai guidance (SOFT) agar tidak misleading.
   - Hard block regime hanya untuk opposite breakout eksplisit:
     - LONG_RANGING + BREAKOUT_UP => block SELL
     - LONG_RANGING + BREAKOUT_DN => block BUY
     - EARLY_BREAKOUT + EARLY_BR_UP => block SELL
     - EARLY_BREAKOUT + EARLY_BR_DN => block BUY

3. **Historical parity**
   - `EvaluatePipelineAt()` sudah memisahkan output hard/soft sesuai class filter,
     sehingga hasil ScanHistory konsisten dengan live pipeline.

## 4) Daftar file penting

- EA aktif: `Dachi_Trader_v13_11_7.mq5`
- Handoff lama (baseline architecture): `docs/HANDOFF_DACHI_TRADER_V13_11_0_ID.md`
- Improvement plan: `docs/Dachi_Trader_Codex_Improvement_Plan_v2.md`
- Changelog ringkas: `docs/CHANGELOG_AFTER_13_6_1.md`
- Linter: `scripts/lint_mq5.py`

## 5) SOP untuk perubahan berikutnya

1. Bump version `X.Y.Z` + rename file `Dachi_Trader_vX_Y_Z.mq5`.
2. Sinkronkan 7 identifier versi (filename, header, property version/description,
   license payload, init/deinit print).
3. Bump logic marker di `ComputeFilterHash()` untuk force rescan.
4. Jalankan:
   - `python3 scripts/lint_mq5.py Dachi_Trader_vX_Y_Z.mq5`
5. Saat ubah regime/filter logic, validasi 3 skenario minimum:
   - regime-only ON,
   - filter-only ON,
   - regime+filter ON.

## 6) Catatan tuning M5 (praktis)

- Jika sinyal terlalu sedikit:
  - longgarkan F2 (`InpF2_MaxDistATR` naik bertahap 1.7 → 1.9)
  - turunkan strictness IF exhaustion (opsi `InpIF_UseExhaustion=false` untuk uji)
  - turunkan wick strictness (`InpWick_MinWickRatio` 0.60 → 0.55)

- Jika sinyal terlalu noisy:
  - naikkan F0 ATR% (35 → 40)
  - naikkan F1 margin (3.0 → 4.0)
  - naikkan F4 slope min (0.6 → 0.8)

