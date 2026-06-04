# Arsip Sesi & Handoff Gabungan — Dachi Trader EA

Tanggal update terakhir: 2026-06-04
Branch kerja: `work`
EA aktif saat ini: `Dachi_Trader_v13_11_39.mq5`
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

## 2. Perjalanan sesi Clean Core sampai v13.11.39

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

### v13.11.29 — Remove cleanup hardening + V-Line lag analysis
- Menambahkan `CleanupAllEAObjects()` untuk memastikan semua object dengan prefix EA (`DT13_`) dihapus saat EA remove/chart close.
- Cleanup mencakup dashboard, license overlay, V-Line, MA ribbon, signal labels, TP/SL/Entry lines, F3 visuals, diagnostics, dan exit markers.
- Catatan analisis V-Line terlambat menangkap bear: Evasive/V-Line memang noise-avoidance sehingga dapat terlambat pada awal impuls besar. Ide fase berikutnya: tambahkan mode opsional `V-Line Early Flip` berbasis fast-break/body ATR/SlowMA Angle, atau profile input yang lebih responsif (ATR length/multiplier lebih kecil) khusus M5 scalping.
- Logic marker dibump ke `0x13C00290`.


### v13.11.30 — Phase A ECI Sideways Filter
- Menambahkan Phase A `Entropy Cluster Index (ECI)` sebagai anti-chop/sideways filter berbasis Shannon entropy dari struktur candle (body, upper wick, lower wick) dalam rolling window.
- Input baru: `InpSW_Action`, `InpECI_Lookback`, `InpSW_ChopThreshold`, dan `InpECI_MixedThreshold`. Default `F_SOFT` agar fase awal menjadi limited/diagnostic dulu, bukan hard-block agresif.
- Implementasi `CalcECIAt()` dan `ECITriggered()` menghitung skor entropy 0..1: `ORDER`, `MIXED`, atau `CHOP`.
- Pipeline live dan historical sekarang memperlakukan ECI `F_HARD` sebagai block, dan `F_SOFT` sebagai limited/soft. Dashboard menampilkan row `SW / Sideway Clustering`.
- Logic marker dibump ke `0x13C00300`.


### v13.11.31 — Stale BLOCKED label repaint fix
- Memperbaiki penyebab label `! BLOCKED` tetap muncul walaupun filter sudah OFF: `DrawSignalLabel()` sebelumnya menolak repaint label BLOCKED lama menjadi VALID/LIMITED.
- Sekarang jika timestamp yang sama dievaluasi ulang sebagai non-BLOCKED, object BLOCKED lama dihapus dulu lalu label baru digambar sesuai status terbaru.
- Logic marker dibump ke `0x13C00310`.


### v13.11.32 — ECI calibration: reduce over-filtering
- Menurunkan agresivitas ECI karena threshold entropy murni membuat hampir semua sinyal menjadi `LIMITED/BLOCKED` pada XAUUSD M1/M5.
- `CHOP` sekarang tidak hanya membutuhkan entropy tinggi, tetapi juga harus directionless dan body lemah: `InpECI_DirectionalBalanceMax` + `InpECI_BodyDominanceMax`.
- Default ECI dibuat lebih longgar: `InpSW_ChopThreshold=0.82`, `InpECI_MixedThreshold=0.62`.
- Dashboard dapat menampilkan `TREND` ketika entropy tinggi tetapi struktur candle masih punya directional bias/body dominance, sehingga sinyal tidak otomatis limited.
- Logic marker dibump ke `0x13C00320`.


### v13.11.33 — ECI v2 visibility + remove-cleanup hardening
- Memperjelas UI bahwa ECI yang aktif adalah `ECI v2` lewat input group dan dashboard row `SW / Sideway Clustering`.
- Memperkuat cleanup object EA: `CleanupAllEAObjects()` sekarang mencari current/legacy prefix `DT13_` dan `DT13`, melakukan multi-pass cleanup sampai tidak ada object EA tersisa, dan mengembalikan jumlah object yang dihapus untuk log deinit.
- `OnDeinit()` sekarang menjalankan cleanup pada semua reason (remove, chart close, parameter change, template/timeframe reload), lalu cleanup ulang setelah indicator handle release dan `ChartRedraw()`. Ini mencegah object stale tertinggal ketika user remove/reload EA.
- Logic marker dibump ke `0x13C00330`.


### v13.11.34 — Blocked Retest Re-entry + safer remove cleanup
- Menambahkan sistem `Blocked Signal Retest Re-entry` untuk menangkap ulang sinyal bagus yang awalnya hard-blocked. Setelah block, EA menunggu retest ke MA band lalu entry ulang jika close kembali searah signal.
- Re-entry memakai konfirmasi native MT5 ADX DI: BUY butuh `DI+ > DI- + InpBRE_DIMargin`, SELL butuh `DI- > DI+ + InpBRE_DIMargin`. Input baru: `InpUseBlockedRetestReentry`, `InpBRE_Bars`, `InpBRE_RetestBufferATR`, `InpBRE_RequireMAAlign`, `InpBRE_RequireDIDirection`, `InpBRE_DIMargin`, dan `InpBRE_RequireSignalCandle`.
- Menambahkan dashboard row `Blocked ReEntry` untuk melihat status arm/wait/reason.
- Mengubah cleanup remove agar lebih aman dari `abnormal termination`: `CleanupAllEAObjects()` kini memakai satu panggilan sinkron `ObjectsDeleteAll(0,"DT13",-1,-1)` daripada ribuan `ObjectDelete()` multi-pass. Ini mengikuti perilaku MQL5 bahwa `ObjectsDeleteAll` menghapus object berdasarkan prefix dan mengembalikan jumlah object terhapus.
- Menambahkan startup self-clean (`[INIT-CLEANUP]`) agar jika MT5 melakukan abnormal termination sebelum `OnDeinit()` selesai, attach berikutnya tetap menghapus sisa object lama sebelum EA menggambar ulang.
- Logic marker dibump ke `0x13C00340`.

### v13.11.35 — Historical BRE labels + safer deinit cleanup v2
- Label re-entry sekarang tampil sebagai `RE-ENTRY BUY` / `RE-ENTRY SELL` dengan font warna krem agar berbeda dari BUY/SELL normal, LIMITED, dan BLOCKED.
- `ScanHistory()` sekarang mensimulasikan Blocked Retest Re-entry secara historis sehingga efektivitas fitur dapat dievaluasi dari chart lama, bukan hanya live tick.
- Cleanup remove dibuat lebih defensif lagi: object EA dihapus per tipe object pada main chart, tanpa `ChartRedraw()` paksa di `OnDeinit()`, agar mengurangi risiko `abnormal termination` saat object historical visual sangat banyak.
- Logic marker dibump ke `0x13C00350`.

### v13.11.36 — BRE reason toggles + ADX strength guard
- Menambahkan toggle per alasan block agar `Blocked Retest Re-entry` hanya bekerja untuk filter yang dipilih: F2, HTF, V-Line, SlowMA Angle, SW, Sideway, ATR Health, Squeeze, dan fallback Other.
- Menambahkan `InpBRE_MinADX`, `InpBRE_RequireADXRising`, dan `InpBRE_ADXRiseBars` agar re-entry hanya valid saat ADX cukup kuat dan, secara default, sedang naik. Ini ditujukan untuk mengurangi re-entry whipsaw pada area sideway.
- Default re-entry untuk block `SW`, `SIDEWAY`, `ATR_HEALTH`, `SQUEEZE`, dan `FILTER/OTHER` dibuat OFF agar sideway/chop tidak otomatis di-entry ulang.
- `ScanHistory()` memakai alasan block historis yang sama sehingga label `RE-ENTRY BUY/SELL` hanya muncul jika alasan block tersebut memang diizinkan.
- Logic marker dibump ke `0x13C00360`.

### v13.11.37 — SW naming + re-entry TP/SL visual context
- Mengubah nama user-facing `ECI v2 Entropy` menjadi `SW / Sideway Clustering`, termasuk input group, dashboard row, helper, dan block reason `SW`.
- Menambahkan dashboard row `Block Reason` agar penyebab block terakhir terlihat langsung; ini menjawab kasus audit ketika sinyal terakhir `BLOCKED` tetapi dashboard lama hanya menampilkan total `1H` tanpa reason.
- Dashboard no-position sekarang memakai arah MA saat ini sebagai arah evaluasi, bukan default BUY, sehingga `Filters 1H` lebih sesuai dengan kondisi chart.
- Historical BRE sekarang mempertahankan visual ENTRY/SL/TP untuk re-entry terakhir yang valid, sehingga kasus re-entry tetap punya konteks risk/reward seperti signal valid.
- Logic marker dibump ke `0x13C00370`.

### v13.11.38 — BRE V-Line alignment Opsi B
- Mengoreksi SOP: pembaruan logic setelah v13.11.37 tidak boleh tetap memakai file/hash v13.11.37; rilis ini membump file aktif ke v13.11.38 dan logic marker ke `0x13C00380`.
- Mengimplementasikan **Opsi B**: V-Line dapat dipakai sebagai acuan/bias BRE tanpa harus menjadi hard entry guard.
- Mengonsolidasikan SW Trend Override secara resmi di rilis ini: SW CHOP/LIMITED dapat dibypass jika MA alignment, slow MA angle, ADX, dan DI direction mengonfirmasi trend searah signal.
- Input baru `InpSW_UseTrendOverride`, `InpSW_OverrideMinSlowAngleDeg`, `InpSW_OverrideMinADX`, `InpSW_OverrideRequireDIDirection`, dan `InpSW_OverrideRequireMAAlign` mengatur override SW.
- Input baru `InpBRE_UseVLineAlignment` membuat BRE membaca arah V-Line sebelum fire: jika V-Line bearish maka BRE BUY ditahan; jika V-Line bullish maka BRE SELL ditahan.
- Input baru `InpBRE_BlockNeutralVLine` menentukan apakah V-Line neutral/no-data boleh atau tidak untuk BRE; default true agar re-entry lebih aman.
- Menambahkan helper `GetVLineDirectionAt()` agar arah V-Line bisa dihitung terpisah dari `InpUseVLineGuard`; `InpUseVLineGuard=false` kini hanya mematikan hard block V-Line, bukan kemampuan BRE memakai V-Line sebagai kompas.
- Dashboard menampilkan row `BRE V-Line` untuk audit alignment BRE.
- Historical BRE memakai V-Line alignment yang sama sehingga label `RE-ENTRY BUY/SELL` di ScanHistory parity dengan live.
- Catatan: user menyebut dua pembaruan sebelumnya sempat tetap berada di v13.11.37; rilis ini menjadi koreksi versioning/handoff resmi.
- Logic marker dibump ke `0x13C00380`.

### v13.11.39 — Backtest Auto Journal + BRE limited/valid mode
- Membump file aktif ke `Dachi_Trader_v13_11_39.mq5` dan logic marker ke `0x13C00390`.
- Menambahkan **Backtest Auto Journal** berbasis CSV untuk mencatat semua signal yang muncul, termasuk `VALID`, `LIMITED`, `RE-ENTRY`, `F3_RECOVERY`, dan `BLOCKED` yang tidak menjadi entry.
- CSV journal mencatat `signal_entry_price` pada harga signal muncul dan menutup row sebelumnya dengan `signal_exit_price` ketika signal berikutnya muncul. Dengan demikian exit-price satu signal sama dengan entry-price signal berikutnya; journal juga mencatat `signal_duration_bars`, `signal_result`, dan `signal_exit_reason`.
- Snapshot indicator yang dicatat mencakup ATR, spread, EMA fast, slow MA, MA gap, SlowMA angle, V-Line state/direction, SW state/score, ADX, DI+, DI-, SL, dan TP1–TP5.
- Input baru `InpUseAutoJournal`, `InpJournalOnlyTester`, `InpJournalSignals`, dan `InpJournalUseCommonFolder` mengatur export jurnal ke `MQL5/Files/Dachi_Trader_Logs/`.
- Input baru `InpBRE_EnterAsLimited` menentukan perlakuan BRE: `true` = RE-ENTRY memakai mode LIMITED/tight TP-SL, `false` = RE-ENTRY diperlakukan seperti VALID/normal TP-SL. Live BRE dan visual historical BRE mengikuti opsi ini.

---

## 3. Status EA aktif saat ini

File aktif: `Dachi_Trader_v13_11_39.mq5`

Identifier yang harus sinkron:
- Header file: `Dachi_Trader_v13_11_39.mq5`
- Version: `13.11.39`
- License payload: `"ea_version":"13.11.39"`
- Init/deinit log: `v13.11.39`
- Logic marker: `0x13C00390`

---

## 4. Prinsip desain saat ini

1. **Clean Core tetap prioritas**
   - Entry signal masih berbasis crossing MA utama.
   - Filter tambahan berfungsi sebagai guard, bukan mengganti core signal kecuali user minta eksplisit.

2. **V-Line sebagai bias guard terpisah**
   - V-Line bukan HTF gate.
   - Default timeframe `PERIOD_CURRENT` agar match chart aktif.
   - Visual V-Line harus stabil, tidak flicker.
   - Mulai v13.11.38, V-Line juga dapat menjadi acuan BRE secara independen dari hard guard: `InpUseVLineGuard=false` boleh, tetapi `InpBRE_UseVLineAlignment=true` tetap membuat BRE mengikuti bias V-Line.

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

1. Compile `Dachi_Trader_v13_11_39.mq5`.
2. Attach ke XAUUSD M5.
3. Test Blocked Retest Re-entry:
   - Buat kondisi sinyal hard-blocked, lalu tunggu pullback/retest ke MA band.
   - BUY re-entry hanya boleh fire jika ADX >= `InpBRE_MinADX`, ADX rising bila `InpBRE_RequireADXRising=true`, dan `DI+ > DI- + InpBRE_DIMargin`; SELL jika `DI- > DI+ + InpBRE_DIMargin`.
   - Jika `InpBRE_UseVLineAlignment=true`, BUY BRE harus ditahan saat V-Line bearish dan SELL BRE harus ditahan saat V-Line bullish, meskipun `InpUseVLineGuard=false`.
   - Dashboard `Blocked ReEntry` harus menampilkan direction, countdown bars, dan reason saat armed; dashboard `BRE V-Line` harus menunjukkan bias yang dipakai BRE.
   - History scan harus menampilkan label krem `RE-ENTRY BUY/SELL` pada retest yang valid dan hanya untuk alasan block yang toggle-nya ON serta lolos V-Line alignment.
4. Test remove cleanup:
   - Attach EA, aktifkan visual V-Line/MA/TP-SL/dashboard, lalu remove EA.
   - Semua object prefix `DT13`/`DT13_` harus hilang dari chart.
   - Journal harus mencetak `cleanup_deleted=...` pada `[DEINIT]`.
5. Test visual toggles:
   - `InpShowCoreMALines=false` harus menghapus/sembunyikan EMA/LWMA lines dan fill.
   - `InpShowTPSLEntryLines=false` harus menghapus/sembunyikan ENTRY/SL/TP lines dan labels.
   - `InpShowBlockedSignals=false` harus menghapus/sembunyikan blocked labels/candle boxes.
6. Test stale BLOCKED repaint:
   - Matikan filter/gate, reload EA, lalu pastikan label lama `! BLOCKED` berubah menjadi BUY/SELL/LIMITED sesuai evaluasi terbaru.
   - Jika `InpShowBlockedSignals=false`, object `SIG_B_*/SIG_S_*` blocked lama harus hilang.
7. Test SW / Sideway Clustering:
   - `InpSW_Action=F_SOFT` harus menampilkan `LIMITED` saat `SW / Sideway Clustering` masuk `CHOP`, tanpa hard-block, kecuali `InpSW_UseTrendOverride=true` dan trend evidence valid.
   - `InpSW_Action=F_HARD` harus memblok sinyal saat skor SW >= `InpSW_ChopThreshold`.
   - Dashboard row `SW / Sideway Clustering` harus berubah antara `ORDER`, `MIXED`, `TREND`, `CHOP`, dan `TREND_OVR`.
8. Test V-Line:
   - `InpVLine_TF=PERIOD_CURRENT` untuk match chart M5.
   - Band tidak flicker saat scroll/chart update.
9. Test SlowMA Angle:
   - Threshold `0`, `3`, `5` derajat.
   - BUY harus butuh angle positif sesuai threshold.
   - SELL harus butuh angle negatif sesuai threshold.

10. Test Backtest Auto Journal:
   - Jalankan Strategy Tester dengan `InpUseAutoJournal=true`.
   - Pastikan file `Dachi_Trader_Logs/Dachi_Signal_Journal_<symbol>_<tf>_<date>.csv` terbentuk di `MQL5/Files` atau `Common/Files` jika `InpJournalUseCommonFolder=true`.
   - Pastikan row `BLOCKED` tetap tercatat walaupun tidak ada trade/deal.
   - Pastikan `signal_exit_price` satu row sama dengan `signal_entry_price` row signal berikutnya, dan row terakhir tertulis `OPEN` saat EA deinit/backtest selesai.
   - Uji `InpBRE_EnterAsLimited=true/false` untuk memastikan RE-ENTRY memakai TP/SL tight atau normal sesuai opsi.

---

## 6. Aturan wajib untuk sesi berikutnya

- Selalu update file ini setelah perubahan EA.
- Selalu bump version/file/hash untuk rilis baru.
- Jangan klaim compile/backtest sukses jika tidak benar-benar dijalankan di MT5/MetaEditor.
- Jika ada fitur visual baru, sediakan toggle jika fitur itu berpotensi membuat chart terlalu ramai.
- Jika filter baru memblok sinyal, tampilkan state/reason di dashboard agar user bisa audit.
- Untuk SW / Sideway Clustering, kalibrasi threshold di XAUUSD M5 dulu dengan default `F_SOFT`; gunakan `F_HARD` hanya setelah skor CHOP terbukti akurat. Untuk v13.11.32, CHOP harus memenuhi entropy tinggi + directional balance rendah + body dominance rendah.
- Saat analisis V-Line lag, jangan langsung mengganti logic utama; pertimbangkan mode opsional early-flip agar karakter noise-avoidance tetap bisa dipertahankan.
