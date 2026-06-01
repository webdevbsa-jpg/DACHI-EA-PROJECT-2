# Arsip Sesi & Handoff Gabungan — Dachi Trader EA

Tanggal update terakhir: 2026-06-01
Branch kerja: `work`
EA aktif saat ini: `Dachi_Trader_v13_11_28.mq5`
Dokumen ini menggabungkan handoff baseline (`HANDOFF_DACHI_TRADER_V13_11_7_ID.md`) dengan perjalanan sesi Clean Core / Advanced Modules. **Setiap update berikutnya wajib memperbarui dokumen ini.**

---

## 1. Baseline handoff lama — v13.11.7

Sumber: `HANDOFF_DACHI_TRADER_V13_11_7_ID.md`.

### Identitas baseline
- EA aktif baseline: `Dachi_Trader_v13_11_7.mq5`
- Version baseline: `13.11.7`
- Logic marker baseline: `0x13C00070`

### Prinsip baseline penting
- Filter ON/OFF tidak selalu berarti hard block; class filter menentukan efek:
  - `F_SOFT` => LIMITED.
  - `F_HARD` => BLOCKED.
- Regime v13.11.6+ terutama sebagai guidance; hard block regime hanya untuk opposite-direction breakout eksplisit.
- Historical evaluation harus parity dengan live pipeline.
- SOP wajib:
  1. Rename file sesuai versi baru.
  2. Bump version/header/property/description/license payload/init-deinit log.
  3. Bump logic marker di `ComputeFilterHash()`.
  4. Jalankan static check/compile bila environment mendukung.

---

## 2. Perjalanan sesi Clean Core sampai v13.11.28

### v13.11.8 — HTF Context + Clean Core awal
- Menambahkan HTF context gate H1/M15.
- Pipeline mulai disederhanakan ke F2 + HTF.
- Bump version/hash/license payload dilakukan setelah user menegur bahwa setiap rilis wajib bump version.

### v13.11.9 — Phase-1 Rule Optimization
- Menambahkan reversal override untuk HTF mismatch.
- Menambahkan sideway noise guard awal.
- Bump version ke v13.11.9.

### v13.11.10–v13.11.18 — Clean Core iterative fixes
- Iterasi untuk mengurangi filter legacy yang masih tampil/aktif.
- Perbaikan label blocked yang stale setelah setting berubah.
- Penyesuaian pipeline/dashboard supaya lebih fokus pada Clean Core.
- User beberapa kali menekankan bahwa fitur yang dihapus tidak boleh hanya dimatikan di pipeline, tetapi sebaiknya tidak muncul di UI jika sudah tidak relevan.

### v13.11.19–v13.11.20 — Supertrend prototype reset
- v13.11.19 menambahkan Supertrend klasik, tetapi visual H1 berantakan dan arah warna/logic tampak terbalik.
- v13.11.20 menghapus prototype Supertrend hard-coded sepenuhnya untuk rebuild dari PineScript LuxAlgo.

### v13.11.21–v13.11.23 — Evasive Supertrend rebuild
- Port logic LuxAlgo Evasive SuperTrend dari PineScript user.
- Menambahkan input group Evasive Supertrend, timeframe adjustable, visual line, dotted/noise mode, dan switch labels.
- Memperbaiki visual patah-patah dengan series calculation sequential.
- Memperpanjang visual agar tidak hanya beberapa bar terakhir.
- Memperbaiki ATR Health yang sebelumnya membandingkan ATR dalam point, sehingga semua sinyal terblock.

### v13.11.24 — V-Line guard default + lazy visual
- Evasive ST guard default ON agar bias benar-benar memfilter sinyal.
- Menambahkan `InpVisualLazyBars` untuk load awal ±1200 bar dan expand saat scroll chart.
- MA ribbon dan V-Line memakai lazy depth.
- `CHARTEVENT_CHART_CHANGE` redraw visual saat user scroll/ubah tampilan chart.

### v13.11.25 — Rename EST ke V-Line + hide blocked signals
- User-facing Evasive/EST diganti menjadi **V-Line**:
  - `InpUseVLineGuard`
  - `InpVLine_*`
  - dashboard row `V-Line`
  - block reason `V_LINE`
- Menambahkan `InpShowBlockedSignals` untuk show/hide label dan candle box BLOCKED.

### v13.11.26 — V-Line TF alignment + flicker fix
- Default `InpVLine_TF` diubah dari `PERIOD_M15` ke `PERIOD_CURRENT` agar match chart M5 seperti TradingView.
- Warmup V-Line diperbesar (`max(300, period*30)`) untuk mengurangi mismatch state BULL/BEAR.
- V-Line visual tidak lagi delete-create semua object setiap redraw; object hanya di-clear saat initial build atau visual OFF untuk mengurangi flicker.

### v13.11.27 — Visual Slow MA Angle Guard
- Menambahkan filter visual slope/angle slow MA:
  - `InpUseSlowMAAngleGuard`
  - `InpSlowMA_MinAngleDeg`
- Angle dibaca dalam derajat visual:
  - datar = `0°`
  - naik = positif
  - turun = negatif
- BUY valid jika angle `>= +threshold`.
- SELL valid jika angle `<= -threshold`.
- Dashboard row: `SlowMA Angle`.
- Block reason: `SLOW_ANGLE`.

### v13.11.28 — Visual toggles
- Menambahkan toggle visual core MA:
  - `InpShowCoreMALines`
  - Mengontrol kedua MA line serta ribbon fill (`EF_*`, `ES_*`, `EFILL*`).
- Menambahkan toggle visual ENTRY/SL/TP:
  - `InpShowTPSLEntryLines`
  - Mengontrol `ENTRY_LINE`, `SL_LINE`, semua `TP*_L`, dan label terkait.
- Logic marker dibump ke `0x13C00280`.

---

## 3. Status EA aktif saat ini

File aktif: `Dachi_Trader_v13_11_28.mq5`

Identifier yang harus sinkron:
- Header file: `Dachi_Trader_v13_11_28.mq5`
- Version: `13.11.28`
- License payload: `"ea_version":"13.11.28"`
- Init/deinit log: `v13.11.28`
- Logic marker: `0x13C00280`

---

## 4. Prinsip desain saat ini

1. **Clean Core tetap prioritas**
   - Entry signal masih berbasis crossing MA utama.
   - Filter tambahan berfungsi sebagai guard, bukan mengganti core signal kecuali user minta eksplisit.

2. **V-Line sebagai bias guard terpisah**
   - V-Line bukan HTF gate.
   - Default timeframe `PERIOD_CURRENT` agar match chart aktif.
   - Visual V-Line harus stabil, tidak flicker.

3. **Slow MA Angle Guard sebagai filter visual**
   - Dibaca dari sudut visual chart.
   - Threshold derajat user-adjustable.
   - Digunakan untuk menghindari sinyal melawan kemiringan slow MA.

4. **Visual harus user-toggleable**
   - Blocked signal: `InpShowBlockedSignals`.
   - MA lines/ribbon: `InpShowCoreMALines`.
   - Entry/SL/TP lines: `InpShowTPSLEntryLines`.

5. **Jika user melihat sinyal BLOCKED meski V-Line searah**
   - V-Line searah hanya berarti guard V-Line pass.
   - Sinyal masih bisa diblock oleh F2, HTF, SlowMA Angle, Sideway, ATR Health, atau Squeeze.
   - Dashboard harus dipakai untuk diagnosis filter mana yang block.

---

## 5. Testing yang ideal di MT5

Karena environment Codex tidak memiliki compiler MQL5, test runtime wajib di MetaEditor/MT5:

1. Compile `Dachi_Trader_v13_11_28.mq5`.
2. Attach ke XAUUSD M5.
3. Test visual toggles:
   - `InpShowCoreMALines=false` harus menghapus/sembunyikan EMA/LWMA lines dan fill.
   - `InpShowTPSLEntryLines=false` harus menghapus/sembunyikan ENTRY/SL/TP lines dan labels.
   - `InpShowBlockedSignals=false` harus menghapus/sembunyikan blocked labels/candle boxes.
4. Test V-Line:
   - `InpVLine_TF=PERIOD_CURRENT` untuk match chart M5.
   - Band tidak flicker saat scroll/chart update.
5. Test SlowMA Angle:
   - Threshold `0`, `3`, `5` derajat.
   - BUY harus butuh angle positif sesuai threshold.
   - SELL harus butuh angle negatif sesuai threshold.

---

## 6. Aturan wajib untuk sesi berikutnya

- Selalu update file ini setelah perubahan EA.
- Selalu bump version/file/hash untuk rilis baru.
- Jangan klaim compile/backtest sukses jika tidak benar-benar dijalankan di MT5/MetaEditor.
- Jika ada fitur visual baru, sediakan toggle jika fitur itu berpotensi membuat chart terlalu ramai.
- Jika filter baru memblok sinyal, tampilkan state/reason di dashboard agar user bisa audit.
