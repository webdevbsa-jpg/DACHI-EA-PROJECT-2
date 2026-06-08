# Dachi Auto Journal Analysis

Generated: 2026-06-07T06:51:55

Sources:
- M1: 4370 rows
- M5: 2062 rows
- M15: 688 rows
- M30: 368 rows

## Institutional-style interpretation framework

Use this report as a baseline run because the user stated all filters were OFF except spread and all exit gates were OFF. The goal is not to maximize one backtest immediately; the goal is to identify which market conditions consistently create negative expectancy before re-enabling filters.

### Recommended decision rules to test next

1. **ADX/DI gate:** If the report shows negative expectancy in `ADX<15` or `ADX15-18`, enable a minimum ADX gate or require DI alignment. Start with `ADX >= 18` on M1/M5 and `ADX >= 15` on M15/M30, then retest.
2. **Slow MA angle gate:** If `|angle|<1` or `|angle|1-3` is strongly negative, enable SlowMA Angle Guard. Start with `0°` for reversal-friendly trading, then test `3°` for trend-follow only.
3. **MA gap anti-chop:** If `|gap|<25` or `|gap|25-75` is negative, add a minimum MA-gap filter. This is usually more direct than ADX for fast MA-cross systems because it blocks micro-crossing clusters.
4. **V-Line as BRE veto, not main hard filter:** If `VL_OPPOSE` is negative and `VL_ALIGN` is positive, keep `InpUseVLineGuard=false` for raw entries but set `InpBRE_UseVLineAlignment=true` so recovery entries cannot fight V-Line.
5. **SW / Sideway Clustering:** If `SW CHOP/MIXED` rows are negative but `TREND/TREND_OVR` positive, re-enable SW in `F_SOFT` first. Do not go hard until blocked-winner rate is measured.
6. **Exit system:** If `signal_result=WIN` but `position_result=LOSS`, exits/SL are too tight or reversal close is firing prematurely. If `signal_result=LOSS` but `position_result=WIN`, exit gates are protecting capital and should stay enabled.

### Timeframe ranking method

Rank each TF by: (1) signal profit factor, (2) average move, (3) drawdown proxy from worst rows, (4) signal density, and (5) stability across ADX/ATR bins. In practice, M1 is usually execution/noise-heavy, M5 is often the best scalper execution TF, M15 is best for context/confirmation, and M30 is usually cleaner but slower.

## M1

### Core metrics

| Metric | Value |
|---|---:|
| Rows / signals | 4370 |
| Signal winrate | 1361/4369 (31.2%) |
| Signal net move pts | -60037.0 |
| Signal avg move pts | -13.7 |
| Signal profit factor | 0.96 |
| Position rows | 4206 |
| Position winrate | 1269/4206 (30.2%) |
| Position net move pts | -113838.0 |
| Position avg move pts | -27.1 |
| Position profit factor | 0.91 |

### Distribution

#### signal_class
| Key | Count | % |
|---|---:|---:|
| VALID | 4290 | 98.2% |
| BLOCKED | 80 | 1.8% |

#### signal_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 3006 | 68.8% |
| WIN | 1361 | 31.1% |
| BE | 2 | 0.0% |
| OPEN | 1 | 0.0% |

#### position_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 2934 | 69.8% |
| WIN | 1269 | 30.2% |
| BE | 3 | 0.1% |

### By ADX bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ADX18-22 | 1147 | 29.6% | 33642.0 | 29.3 | 1070.9 | -407.7 | 1.10 |
| ADX25-30 | 853 | 32.4% | 35028.0 | 41.1 | 1087.0 | -460.1 | 1.13 |
| ADX22-25 | 762 | 31.9% | -52686.0 | -69.1 | 923.7 | -534.0 | 0.81 |
| ADX30-40 | 712 | 33.3% | -69059.0 | -97.0 | 784.8 | -537.0 | 0.73 |
| ADX15-18 | 527 | 29.4% | -23269.0 | -44.2 | 786.3 | -391.2 | 0.84 |
| ADX12-15 | 196 | 32.1% | 17754.0 | 90.6 | 1047.0 | -362.5 | 1.37 |
| ADX>=40 | 145 | 28.3% | -20.0 | -0.1 | 1183.0 | -466.5 | 1.00 |

### By ATR bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ATR1-2 | 1429 | 29.1% | 14254.0 | 10.0 | 570.2 | -220.1 | 1.06 |
| ATR2-3 | 1061 | 30.0% | 4307.0 | 4.1 | 781.2 | -329.0 | 1.02 |
| ATR3-5 | 1007 | 32.0% | -84542.0 | -84.0 | 794.3 | -497.5 | 0.75 |
| ATR5-8 | 419 | 35.6% | -21917.0 | -52.3 | 1347.1 | -824.6 | 0.90 |
| ATR8-12 | 226 | 33.6% | 7728.0 | 34.2 | 2764.8 | -1349.3 | 1.04 |
| ATR<1 | 113 | 32.7% | 2147.0 | 19.0 | 368.7 | -151.2 | 1.19 |
| ATR12-18 | 92 | 35.9% | 927.0 | 10.1 | 3005.3 | -1665.2 | 1.01 |

### By Slow MA angle bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |angle|<1 | 2744 | 29.1% | -102346.0 | -37.3 | 918.5 | -430.4 | 0.88 |
| |angle|>=12 | 1625 | 34.6% | 42309.0 | 26.0 | 1031.0 | -505.3 | 1.08 |

### By MA gap bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |gap|<25 | 2962 | 29.6% | -56130.0 | -19.0 | 716.2 | -328.3 | 0.92 |
| |gap|25-75 | 1107 | 32.9% | -28707.0 | -25.9 | 1135.9 | -595.9 | 0.94 |
| |gap|75-150 | 222 | 37.8% | -481.0 | -2.2 | 1888.3 | -1152.9 | 1.00 |

### By DI alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| DI_ALIGN | 3694 | 31.5% | -16216.0 | -4.4 | 1014.9 | -472.5 | 0.99 |
| DI_OPPOSE | 675 | 29.5% | -43821.0 | -64.9 | 673.5 | -373.6 | 0.75 |

### By V-Line alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| VL_OPPOSE | 2320 | 32.4% | -41856.0 | -18.0 | 906.2 | -461.6 | 0.94 |
| VL_ALIGN | 2048 | 29.7% | -19231.0 | -9.4 | 1037.6 | -451.8 | 0.97 |

### By V-Line state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| BEAR | 2137 | 30.2% | -48515.0 | -22.7 | 1024.6 | -476.8 | 0.93 |
| BULL | 1421 | 31.0% | 4806.0 | 3.4 | 859.4 | -380.6 | 1.01 |
| BEAR NOISE | 480 | 35.4% | -31554.0 | -65.7 | 920.6 | -608.6 | 0.83 |
| BULL NOISE | 330 | 31.5% | 14176.0 | 43.0 | 1112.8 | -449.3 | 1.14 |

### By SW state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| OFF | 4369 | 31.2% | -60037.0 | -13.7 | 965.0 | -456.9 | 0.96 |

### Worst signal-to-signal rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.30 23:49:00 | BUY | VALID | -13168.0 | -7119.0 | LOSS | LOSS | 23.3 | 8.05 | 23.6 | 14.6 | 0.0 | BEAR/SELL | OFF/0.85 |
| 2026.02.11 15:22:00 | BUY | VALID | -6161.0 | -6166.0 | LOSS | LOSS | 27.5 | 4.91 | 34.5 | 21.3 | 14.0 | BEAR NOISE/SELL | OFF/0.82 |
| 2026.02.02 23:41:00 | SELL | VALID | -5671.0 | -210.0 | LOSS | LOSS | 20.0 | 5.54 | 19.2 | 16.1 | 0.0 | BULL/BUY | OFF/0.87 |
| 2026.01.30 20:01:00 | BUY | VALID | -5511.0 | -5571.0 | LOSS | LOSS | 36.0 | 19.46 | 27.0 | 17.6 | 14.0 | BEAR NOISE/SELL | OFF/0.83 |
| 2026.01.30 20:37:00 | SELL | VALID | -4710.0 | -4660.0 | LOSS | LOSS | 32.1 | 27.77 | 9.2 | 23.4 | -14.0 | BEAR/SELL | OFF/0.82 |
| 2026.02.02 08:00:00 | BUY | VALID | -4323.0 | -4329.0 | LOSS | LOSS | 36.4 | 22.69 | 21.2 | 21.5 | 0.0 | BEAR/SELL | OFF/0.65 |
| 2026.02.11 15:30:00 | SELL | BLOCKED | -4309.0 | — | LOSS |  | 24.5 | 8.90 | 21.3 | 33.2 | -68.2 | BEAR/SELL | OFF/0.72 |
| 2026.01.30 20:32:00 | BUY | VALID | -4059.0 | -4031.0 | LOSS | LOSS | 39.4 | 32.59 | 16.3 | 14.7 | 0.0 | BEAR/SELL | OFF/0.77 |
| 2026.02.02 17:39:00 | BUY | VALID | -3671.0 | -3672.0 | LOSS | LOSS | 23.3 | 16.43 | 27.4 | 15.8 | 0.0 | BULL/BUY | OFF/0.80 |
| 2026.01.29 01:58:00 | BUY | BLOCKED | -3670.0 | — | LOSS |  | 24.3 | 15.52 | 14.9 | 17.9 | 0.0 | BULL/BUY | OFF/0.88 |
| 2026.02.06 02:57:00 | BUY | VALID | -3657.0 | -3665.0 | LOSS | LOSS | 20.2 | 8.10 | 25.1 | 18.6 | 14.0 | BULL/BUY | OFF/0.76 |
| 2026.01.30 08:24:00 | BUY | VALID | -3630.0 | -3573.0 | LOSS | LOSS | 30.3 | 9.24 | 28.3 | 16.6 | 0.0 | BEAR NOISE/SELL | OFF/0.88 |
| 2026.01.26 23:55:00 | SELL | VALID | -3624.0 | -1336.0 | LOSS | LOSS | 16.8 | 4.77 | 17.4 | 21.2 | 0.0 | BEAR/SELL | OFF/0.89 |
| 2026.02.05 16:06:00 | BUY | VALID | -3353.0 | -3386.0 | LOSS | LOSS | 22.5 | 9.37 | 26.1 | 18.5 | 26.6 | BEAR NOISE/SELL | OFF/0.89 |
| 2026.01.30 04:35:00 | SELL | VALID | -3336.0 | -3414.0 | LOSS | LOSS | 33.4 | 20.80 | 20.0 | 24.5 | 0.0 | BEAR/SELL | OFF/0.87 |

### Worst actual position rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.30 23:49:00 | BUY | VALID | -13168.0 | -7119.0 | LOSS | LOSS | 23.3 | 8.05 | 23.6 | 14.6 | 0.0 | BEAR/SELL | OFF/0.85 |
| 2026.02.11 15:22:00 | BUY | VALID | -6161.0 | -6166.0 | LOSS | LOSS | 27.5 | 4.91 | 34.5 | 21.3 | 14.0 | BEAR NOISE/SELL | OFF/0.82 |
| 2026.01.30 20:01:00 | BUY | VALID | -5511.0 | -5571.0 | LOSS | LOSS | 36.0 | 19.46 | 27.0 | 17.6 | 14.0 | BEAR NOISE/SELL | OFF/0.83 |
| 2026.01.30 20:37:00 | SELL | VALID | -4710.0 | -4660.0 | LOSS | LOSS | 32.1 | 27.77 | 9.2 | 23.4 | -14.0 | BEAR/SELL | OFF/0.82 |
| 2026.02.02 08:00:00 | BUY | VALID | -4323.0 | -4329.0 | LOSS | LOSS | 36.4 | 22.69 | 21.2 | 21.5 | 0.0 | BEAR/SELL | OFF/0.65 |
| 2026.01.30 20:32:00 | BUY | VALID | -4059.0 | -4031.0 | LOSS | LOSS | 39.4 | 32.59 | 16.3 | 14.7 | 0.0 | BEAR/SELL | OFF/0.77 |
| 2026.02.02 17:39:00 | BUY | VALID | -3671.0 | -3672.0 | LOSS | LOSS | 23.3 | 16.43 | 27.4 | 15.8 | 0.0 | BULL/BUY | OFF/0.80 |
| 2026.02.06 02:57:00 | BUY | VALID | -3657.0 | -3665.0 | LOSS | LOSS | 20.2 | 8.10 | 25.1 | 18.6 | 14.0 | BULL/BUY | OFF/0.76 |
| 2026.01.30 08:24:00 | BUY | VALID | -3630.0 | -3573.0 | LOSS | LOSS | 30.3 | 9.24 | 28.3 | 16.6 | 0.0 | BEAR NOISE/SELL | OFF/0.88 |
| 2026.02.12 23:51:00 | BUY | VALID | -1462.0 | -3441.0 | LOSS | LOSS | 28.7 | 1.77 | 36.8 | 14.2 | 0.0 | BEAR NOISE/SELL | OFF/0.89 |
| 2026.01.30 04:35:00 | SELL | VALID | -3336.0 | -3414.0 | LOSS | LOSS | 33.4 | 20.80 | 20.0 | 24.5 | 0.0 | BEAR/SELL | OFF/0.87 |
| 2026.02.05 16:06:00 | BUY | VALID | -3353.0 | -3386.0 | LOSS | LOSS | 22.5 | 9.37 | 26.1 | 18.5 | 26.6 | BEAR NOISE/SELL | OFF/0.89 |
| 2026.02.02 09:32:00 | SELL | VALID | -3330.0 | -3365.0 | LOSS | LOSS | 24.3 | 14.10 | 17.2 | 33.2 | 0.0 | BEAR/SELL | OFF/0.84 |
| 2026.01.30 19:25:00 | BUY | VALID | -3313.0 | -3330.0 | LOSS | LOSS | 26.7 | 17.55 | 20.1 | 15.9 | 14.0 | BEAR/SELL | OFF/0.84 |
| 2026.02.03 23:54:00 | BUY | VALID | -3307.0 | -3308.0 | LOSS | LOSS | 39.0 | 4.41 | 22.6 | 15.2 | 0.0 | BEAR/SELL | OFF/0.71 |

## M5

### Core metrics

| Metric | Value |
|---|---:|
| Rows / signals | 2062 |
| Signal winrate | 662/2061 (32.1%) |
| Signal net move pts | 105933.0 |
| Signal avg move pts | 51.4 |
| Signal profit factor | 1.08 |
| Position rows | 2036 |
| Position winrate | 645/2036 (31.7%) |
| Position net move pts | 82458.0 |
| Position avg move pts | 40.5 |
| Position profit factor | 1.07 |

### Distribution

#### signal_class
| Key | Count | % |
|---|---:|---:|
| VALID | 2037 | 98.8% |
| BLOCKED | 25 | 1.2% |

#### signal_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 1396 | 67.7% |
| WIN | 662 | 32.1% |
| BE | 3 | 0.1% |
| OPEN | 1 | 0.0% |

#### position_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 1391 | 68.3% |
| WIN | 645 | 31.7% |

### By ADX bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ADX18-22 | 520 | 31.9% | 31003.0 | 59.6 | 2159.7 | -927.8 | 1.09 |
| ADX25-30 | 420 | 34.3% | 65648.0 | 156.3 | 2157.1 | -887.6 | 1.27 |
| ADX22-25 | 387 | 32.3% | -5215.0 | -13.5 | 1976.5 | -966.6 | 0.98 |
| ADX30-40 | 290 | 31.0% | -70649.0 | -243.6 | 1400.6 | -988.5 | 0.64 |
| ADX15-18 | 263 | 31.2% | 74779.0 | 284.3 | 2667.1 | -795.1 | 1.52 |
| ADX12-15 | 115 | 27.8% | -8468.0 | -73.6 | 1641.2 | -734.8 | 0.86 |
| ADX>=40 | 60 | 36.7% | 18143.0 | 302.4 | 2643.9 | -1053.2 | 1.45 |

### By ATR bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ATR5-8 | 726 | 32.9% | 24659.0 | 34.0 | 1747.1 | -810.1 | 1.06 |
| ATR3-5 | 659 | 28.7% | 24021.0 | 36.5 | 1631.8 | -605.1 | 1.08 |
| ATR8-12 | 308 | 35.1% | -16225.0 | -52.7 | 2054.9 | -1196.8 | 0.93 |
| ATR12-18 | 149 | 37.6% | 59934.0 | 402.2 | 3562.9 | -1500.9 | 1.43 |
| ATR2-3 | 119 | 26.9% | 1713.0 | 14.4 | 1421.7 | -503.2 | 1.04 |
| ATR>=18 | 96 | 39.6% | 12794.0 | 133.3 | 4805.4 | -2927.8 | 1.08 |

### By Slow MA angle bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |angle|<1 | 1203 | 33.1% | 209476.0 | 174.1 | 2188.9 | -825.1 | 1.32 |
| |angle|>=12 | 858 | 30.8% | -103543.0 | -120.7 | 1910.3 | -1023.3 | 0.83 |

### By MA gap bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |gap|<25 | 825 | 29.3% | 82172.0 | 99.6 | 1864.8 | -635.3 | 1.22 |
| |gap|25-75 | 787 | 34.6% | 89117.0 | 113.2 | 1995.2 | -880.7 | 1.20 |
| |gap|75-150 | 320 | 31.2% | -29280.0 | -91.5 | 2379.0 | -1220.0 | 0.89 |
| |gap|150-300 | 98 | 33.7% | -45795.0 | -467.3 | 2367.0 | -1906.2 | 0.63 |

### By DI alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| DI_ALIGN | 1776 | 32.6% | 79672.0 | 44.9 | 2052.5 | -928.6 | 1.07 |
| DI_OPPOSE | 285 | 29.1% | 26261.0 | 92.1 | 2254.1 | -796.2 | 1.16 |

### By V-Line alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| VL_OPPOSE | 1075 | 33.4% | 2648.0 | 2.5 | 1861.0 | -933.3 | 1.00 |
| VL_ALIGN | 985 | 30.8% | 103589.0 | 105.2 | 2334.7 | -885.4 | 1.17 |

### By V-Line state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| BEAR | 873 | 31.6% | 42597.0 | 48.8 | 2297.3 | -994.0 | 1.07 |
| BULL | 821 | 31.5% | 78610.0 | 95.7 | 1917.1 | -745.0 | 1.19 |
| BEAR NOISE | 188 | 39.4% | 36317.0 | 193.2 | 2331.5 | -1194.9 | 1.27 |
| BULL NOISE | 178 | 29.8% | -51287.0 | -288.1 | 1366.1 | -989.5 | 0.59 |

### By SW state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| OFF | 2061 | 32.1% | 105933.0 | 51.4 | 2077.8 | -909.4 | 1.08 |

### Worst signal-to-signal rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.30 17:00:00 | SELL | VALID | -7374.0 | -7414.0 | LOSS | LOSS | 31.5 | 33.82 | 11.3 | 28.4 | -26.6 | BEAR/SELL | OFF/0.80 |
| 2026.01.30 16:15:00 | BUY | VALID | -6888.0 | -6898.0 | LOSS | LOSS | 33.1 | 27.85 | 17.5 | 13.9 | 0.0 | BEAR/SELL | OFF/0.77 |
| 2026.01.30 23:30:00 | BUY | VALID | -5988.0 | -5987.0 | LOSS | LOSS | 28.6 | 29.35 | 19.8 | 10.3 | 0.0 | BEAR/SELL | OFF/0.87 |
| 2026.02.02 18:45:00 | SELL | VALID | -5570.0 | -5615.0 | LOSS | LOSS | 24.5 | 31.28 | 16.9 | 31.6 | -14.0 | BEAR/SELL | OFF/0.79 |
| 2026.03.23 14:10:00 | SELL | VALID | -5525.0 | -5542.0 | LOSS | LOSS | 23.8 | 48.26 | 13.9 | 19.6 | 0.0 | BULL/BUY | OFF/0.87 |
| 2026.02.02 02:05:00 | BUY | VALID | -5226.0 | -5271.0 | LOSS | LOSS | 19.4 | 44.48 | 29.6 | 12.7 | 14.0 | BEAR NOISE/SELL | OFF/0.78 |
| 2026.01.29 03:00:00 | SELL | BLOCKED | -5211.0 | — | LOSS |  | 24.5 | 29.69 | 16.5 | 21.4 | -14.0 | BULL NOISE/BUY | OFF/0.78 |
| 2026.01.29 02:35:00 | BUY | BLOCKED | -5012.0 | — | LOSS |  | 36.1 | 37.17 | 31.1 | 15.5 | 0.0 | BULL/BUY | OFF/0.77 |
| 2026.02.02 16:30:00 | BUY | VALID | -4877.0 | -4795.0 | LOSS | LOSS | 17.2 | 30.50 | 27.7 | 18.7 | 0.0 | BEAR NOISE/SELL | OFF/0.87 |
| 2026.03.23 11:40:00 | SELL | VALID | -4509.0 | -4483.0 | LOSS | LOSS | 38.8 | 23.69 | 24.4 | 25.6 | -14.0 | BEAR/SELL | OFF/0.63 |
| 2026.02.02 19:05:00 | BUY | VALID | -4490.0 | -4509.0 | LOSS | LOSS | 20.9 | 29.79 | 26.3 | 19.0 | 14.0 | BEAR/SELL | OFF/0.82 |
| 2026.05.22 23:35:00 | SELL | VALID | -4449.0 | -4408.0 | LOSS | LOSS | 19.7 | 2.55 | 18.1 | 18.0 | 0.0 | BEAR/SELL | OFF/0.86 |
| 2026.03.06 23:00:00 | BUY | VALID | -4313.0 | -4322.0 | LOSS | LOSS | 21.7 | 6.03 | 16.0 | 19.8 | 0.0 | BULL/BUY | OFF/0.86 |
| 2026.03.04 23:30:00 | SELL | VALID | -4269.0 | -1727.0 | LOSS | LOSS | 18.8 | 5.97 | 14.8 | 21.8 | -14.0 | BULL NOISE/BUY | OFF/0.84 |
| 2026.04.02 15:55:00 | SELL | VALID | -4237.0 | -4268.0 | LOSS | LOSS | 18.4 | 11.15 | 15.8 | 27.5 | -26.6 | BEAR/SELL | OFF/0.91 |

### Worst actual position rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.30 17:00:00 | SELL | VALID | -7374.0 | -7414.0 | LOSS | LOSS | 31.5 | 33.82 | 11.3 | 28.4 | -26.6 | BEAR/SELL | OFF/0.80 |
| 2026.01.30 16:15:00 | BUY | VALID | -6888.0 | -6898.0 | LOSS | LOSS | 33.1 | 27.85 | 17.5 | 13.9 | 0.0 | BEAR/SELL | OFF/0.77 |
| 2026.01.30 23:30:00 | BUY | VALID | -5988.0 | -5987.0 | LOSS | LOSS | 28.6 | 29.35 | 19.8 | 10.3 | 0.0 | BEAR/SELL | OFF/0.87 |
| 2026.02.02 18:45:00 | SELL | VALID | -5570.0 | -5615.0 | LOSS | LOSS | 24.5 | 31.28 | 16.9 | 31.6 | -14.0 | BEAR/SELL | OFF/0.79 |
| 2026.03.23 14:10:00 | SELL | VALID | -5525.0 | -5542.0 | LOSS | LOSS | 23.8 | 48.26 | 13.9 | 19.6 | 0.0 | BULL/BUY | OFF/0.87 |
| 2026.02.02 02:05:00 | BUY | VALID | -5226.0 | -5271.0 | LOSS | LOSS | 19.4 | 44.48 | 29.6 | 12.7 | 14.0 | BEAR NOISE/SELL | OFF/0.78 |
| 2026.02.02 16:30:00 | BUY | VALID | -4877.0 | -4795.0 | LOSS | LOSS | 17.2 | 30.50 | 27.7 | 18.7 | 0.0 | BEAR NOISE/SELL | OFF/0.87 |
| 2026.02.02 19:05:00 | BUY | VALID | -4490.0 | -4509.0 | LOSS | LOSS | 20.9 | 29.79 | 26.3 | 19.0 | 14.0 | BEAR/SELL | OFF/0.82 |
| 2026.03.23 11:40:00 | SELL | VALID | -4509.0 | -4483.0 | LOSS | LOSS | 38.8 | 23.69 | 24.4 | 25.6 | -14.0 | BEAR/SELL | OFF/0.63 |
| 2026.05.22 23:35:00 | SELL | VALID | -4449.0 | -4408.0 | LOSS | LOSS | 19.7 | 2.55 | 18.1 | 18.0 | 0.0 | BEAR/SELL | OFF/0.86 |
| 2026.03.06 23:00:00 | BUY | VALID | -4313.0 | -4322.0 | LOSS | LOSS | 21.7 | 6.03 | 16.0 | 19.8 | 0.0 | BULL/BUY | OFF/0.86 |
| 2026.04.02 15:55:00 | SELL | VALID | -4237.0 | -4268.0 | LOSS | LOSS | 18.4 | 11.15 | 15.8 | 27.5 | -26.6 | BEAR/SELL | OFF/0.91 |
| 2026.01.29 07:20:00 | SELL | VALID | -4135.0 | -4190.0 | LOSS | LOSS | 26.6 | 10.65 | 14.9 | 26.1 | -14.0 | BEAR/SELL | OFF/0.90 |
| 2026.03.06 16:35:00 | SELL | VALID | -4160.0 | -4190.0 | LOSS | LOSS | 20.2 | 17.03 | 23.1 | 18.6 | -14.0 | BULL/BUY | OFF/0.84 |
| 2026.03.06 14:55:00 | SELL | VALID | -4065.0 | -4106.0 | LOSS | LOSS | 18.8 | 8.18 | 15.8 | 22.0 | 0.0 | BEAR/SELL | OFF/0.68 |

## M15

### Core metrics

| Metric | Value |
|---|---:|
| Rows / signals | 688 |
| Signal winrate | 229/687 (33.3%) |
| Signal net move pts | 128720.0 |
| Signal avg move pts | 187.4 |
| Signal profit factor | 1.19 |
| Position rows | 676 |
| Position winrate | 223/676 (33.0%) |
| Position net move pts | 112561.0 |
| Position avg move pts | 166.5 |
| Position profit factor | 1.17 |

### Distribution

#### signal_class
| Key | Count | % |
|---|---:|---:|
| VALID | 677 | 98.4% |
| BLOCKED | 11 | 1.6% |

#### signal_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 458 | 66.6% |
| WIN | 229 | 33.3% |
| OPEN | 1 | 0.1% |

#### position_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 453 | 67.0% |
| WIN | 223 | 33.0% |

### By ADX bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ADX18-22 | 176 | 33.0% | 87960.0 | 499.8 | 4173.2 | -1305.8 | 1.57 |
| ADX25-30 | 143 | 33.6% | 17755.0 | 124.2 | 3514.2 | -1588.7 | 1.12 |
| ADX22-25 | 138 | 31.2% | 16948.0 | 122.8 | 3859.7 | -1568.6 | 1.11 |
| ADX30-40 | 90 | 36.7% | 18079.0 | 200.9 | 3427.7 | -1667.3 | 1.19 |
| ADX15-18 | 82 | 25.6% | -13462.0 | -164.2 | 2997.2 | -1252.5 | 0.82 |
| ADX12-15 | 36 | 36.1% | -369.0 | -10.2 | 2915.6 | -1664.0 | 0.99 |
| ADX>=40 | 20 | 60.0% | 2274.0 | 113.7 | 1894.6 | -2557.6 | 1.11 |

### By ATR bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ATR8-12 | 236 | 32.6% | 43695.0 | 185.1 | 3058.2 | -1206.2 | 1.23 |
| ATR5-8 | 191 | 28.3% | 1695.0 | 8.9 | 2699.7 | -1051.7 | 1.01 |
| ATR12-18 | 155 | 31.6% | -53174.0 | -343.1 | 2758.1 | -1776.6 | 0.72 |
| ATR>=18 | 92 | 48.9% | 126976.0 | 1380.2 | 6236.1 | -3269.1 | 1.83 |
| ATR3-5 | 13 | 30.8% | 9528.0 | 732.9 | 4242.2 | -826.8 | 2.28 |

### By Slow MA angle bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |angle|<1 | 508 | 32.1% | 59140.0 | 116.4 | 3413.8 | -1441.5 | 1.12 |
| |angle|>=12 | 179 | 36.9% | 69580.0 | 388.7 | 3902.3 | -1663.5 | 1.37 |

### By MA gap bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |gap|25-75 | 257 | 33.5% | 124122.0 | 483.0 | 3983.2 | -1277.4 | 1.57 |
| |gap|<25 | 169 | 27.8% | -15712.0 | -93.0 | 2487.7 | -1087.2 | 0.88 |
| |gap|75-150 | 141 | 30.5% | -53445.0 | -379.0 | 2548.7 | -1663.7 | 0.67 |
| |gap|150-300 | 90 | 43.3% | 80656.0 | 896.2 | 4495.4 | -1856.2 | 1.85 |
| |gap|300-600 | 21 | 38.1% | -26388.0 | -1256.6 | 3417.5 | -4132.9 | 0.51 |

### By DI alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| DI_ALIGN | 578 | 34.3% | 134184.0 | 232.2 | 3656.8 | -1552.3 | 1.23 |
| DI_OPPOSE | 109 | 28.4% | -5464.0 | -50.1 | 2901.8 | -1223.3 | 0.94 |

### By V-Line alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| VL_OPPOSE | 357 | 31.9% | -22179.0 | -62.1 | 2912.7 | -1457.7 | 0.94 |
| VL_ALIGN | 329 | 34.7% | 147618.0 | 448.7 | 4198.9 | -1539.8 | 1.45 |

### By V-Line state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| BULL | 288 | 27.1% | -36845.0 | -127.9 | 3154.2 | -1347.0 | 0.87 |
| BEAR | 280 | 35.7% | 114909.0 | 410.4 | 4106.7 | -1643.1 | 1.39 |
| BULL NOISE | 60 | 40.0% | -1032.0 | -17.2 | 2491.1 | -1689.4 | 0.98 |
| BEAR NOISE | 58 | 44.8% | 48407.0 | 834.6 | 3624.5 | -1432.2 | 2.06 |

### By SW state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| OFF | 687 | 33.3% | 128720.0 | 187.4 | 3554.6 | -1496.2 | 1.19 |

### Worst signal-to-signal rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.02.12 17:30:00 | BUY | VALID | -11939.0 | -11942.0 | LOSS | LOSS | 13.2 | 13.53 | 25.1 | 18.8 | 0.0 | BULL/BUY | OFF/0.86 |
| 2026.01.30 13:15:00 | BUY | VALID | -9838.0 | -9968.0 | LOSS | LOSS | 39.4 | 57.35 | 21.6 | 13.0 | 0.0 | BEAR/SELL | OFF/0.81 |
| 2026.01.20 22:30:00 | SELL | VALID | -8746.0 | -1382.0 | LOSS | LOSS | 29.6 | 6.86 | 13.3 | 19.6 | 0.0 | BULL/BUY | OFF/0.82 |
| 2026.01.21 20:45:00 | BUY | VALID | -8435.0 | -8415.0 | LOSS | LOSS | 23.1 | 15.97 | 26.5 | 14.1 | 0.0 | BULL/BUY | OFF/0.88 |
| 2026.03.24 19:30:00 | SELL | VALID | -8220.0 | -8266.0 | LOSS | LOSS | 24.9 | 20.57 | 14.7 | 26.5 | 0.0 | BEAR/SELL | OFF/0.99 |
| 2026.01.21 21:30:00 | SELL | VALID | -6675.0 | -6722.0 | LOSS | LOSS | 21.3 | 20.50 | 17.7 | 27.6 | -26.6 | BEAR/SELL | OFF/0.81 |
| 2026.03.23 17:45:00 | SELL | VALID | -6262.0 | -6304.0 | LOSS | LOSS | 28.6 | 46.65 | 13.7 | 31.4 | -14.0 | BULL NOISE/BUY | OFF/0.67 |
| 2026.01.30 22:00:00 | BUY | VALID | -5961.0 | -5960.0 | LOSS | LOSS | 30.8 | 74.98 | 22.7 | 26.2 | 0.0 | BEAR/SELL | OFF/0.87 |
| 2026.01.29 20:00:00 | BUY | VALID | -5915.0 | -5916.0 | LOSS | LOSS | 23.5 | 81.91 | 22.5 | 16.0 | 0.0 | BEAR/SELL | OFF/0.74 |
| 2026.01.29 22:00:00 | SELL | VALID | -5784.0 | -5827.0 | LOSS | LOSS | 26.9 | 39.61 | 7.7 | 24.8 | 0.0 | BEAR/SELL | OFF/0.80 |
| 2026.03.24 01:00:00 | BUY | VALID | -5593.0 | -5596.0 | LOSS | LOSS | 17.4 | 22.02 | 29.4 | 14.6 | 0.0 | BULL/BUY | OFF/0.87 |
| 2026.03.19 17:00:00 | BUY | VALID | -5565.0 | -5568.0 | LOSS | LOSS | 42.0 | 46.27 | 17.1 | 19.9 | 0.0 | BEAR/SELL | OFF/0.81 |
| 2026.02.03 05:00:00 | SELL | VALID | -5186.0 | -5222.0 | LOSS | LOSS | 25.4 | 38.21 | 16.2 | 22.7 | 0.0 | BEAR/SELL | OFF/0.91 |
| 2026.03.20 10:15:00 | BUY | VALID | -4947.0 | -4942.0 | LOSS | LOSS | 36.3 | 15.95 | 42.2 | 12.3 | 0.0 | BEAR NOISE/SELL | OFF/0.84 |
| 2026.01.29 22:30:00 | BUY | VALID | -4376.0 | -4368.0 | LOSS | LOSS | 23.7 | 39.59 | 19.5 | 18.6 | 14.0 | BEAR/SELL | OFF/0.80 |

### Worst actual position rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.02.12 17:30:00 | BUY | VALID | -11939.0 | -11942.0 | LOSS | LOSS | 13.2 | 13.53 | 25.1 | 18.8 | 0.0 | BULL/BUY | OFF/0.86 |
| 2026.01.30 13:15:00 | BUY | VALID | -9838.0 | -9968.0 | LOSS | LOSS | 39.4 | 57.35 | 21.6 | 13.0 | 0.0 | BEAR/SELL | OFF/0.81 |
| 2026.01.21 20:45:00 | BUY | VALID | -8435.0 | -8415.0 | LOSS | LOSS | 23.1 | 15.97 | 26.5 | 14.1 | 0.0 | BULL/BUY | OFF/0.88 |
| 2026.03.24 19:30:00 | SELL | VALID | -8220.0 | -8266.0 | LOSS | LOSS | 24.9 | 20.57 | 14.7 | 26.5 | 0.0 | BEAR/SELL | OFF/0.99 |
| 2026.01.21 21:30:00 | SELL | VALID | -6675.0 | -6722.0 | LOSS | LOSS | 21.3 | 20.50 | 17.7 | 27.6 | -26.6 | BEAR/SELL | OFF/0.81 |
| 2026.03.23 17:45:00 | SELL | VALID | -6262.0 | -6304.0 | LOSS | LOSS | 28.6 | 46.65 | 13.7 | 31.4 | -14.0 | BULL NOISE/BUY | OFF/0.67 |
| 2026.01.30 22:00:00 | BUY | VALID | -5961.0 | -5960.0 | LOSS | LOSS | 30.8 | 74.98 | 22.7 | 26.2 | 0.0 | BEAR/SELL | OFF/0.87 |
| 2026.01.29 20:00:00 | BUY | VALID | -5915.0 | -5916.0 | LOSS | LOSS | 23.5 | 81.91 | 22.5 | 16.0 | 0.0 | BEAR/SELL | OFF/0.74 |
| 2026.01.29 22:00:00 | SELL | VALID | -5784.0 | -5827.0 | LOSS | LOSS | 26.9 | 39.61 | 7.7 | 24.8 | 0.0 | BEAR/SELL | OFF/0.80 |
| 2026.03.24 01:00:00 | BUY | VALID | -5593.0 | -5596.0 | LOSS | LOSS | 17.4 | 22.02 | 29.4 | 14.6 | 0.0 | BULL/BUY | OFF/0.87 |
| 2026.03.19 17:00:00 | BUY | VALID | -5565.0 | -5568.0 | LOSS | LOSS | 42.0 | 46.27 | 17.1 | 19.9 | 0.0 | BEAR/SELL | OFF/0.81 |
| 2026.02.03 05:00:00 | SELL | VALID | -5186.0 | -5222.0 | LOSS | LOSS | 25.4 | 38.21 | 16.2 | 22.7 | 0.0 | BEAR/SELL | OFF/0.91 |
| 2026.03.20 10:15:00 | BUY | VALID | -4947.0 | -4942.0 | LOSS | LOSS | 36.3 | 15.95 | 42.2 | 12.3 | 0.0 | BEAR NOISE/SELL | OFF/0.84 |
| 2026.01.29 22:30:00 | BUY | VALID | -4376.0 | -4368.0 | LOSS | LOSS | 23.7 | 39.59 | 19.5 | 18.6 | 14.0 | BEAR/SELL | OFF/0.80 |
| 2026.03.24 16:45:00 | BUY | VALID | -4308.0 | -4306.0 | LOSS | LOSS | 30.8 | 27.01 | 27.1 | 11.3 | 0.0 | BEAR/SELL | OFF/0.97 |

## M30

### Core metrics

| Metric | Value |
|---|---:|
| Rows / signals | 368 |
| Signal winrate | 116/367 (31.6%) |
| Signal net move pts | 145210.0 |
| Signal avg move pts | 395.7 |
| Signal profit factor | 1.29 |
| Position rows | 359 |
| Position winrate | 114/359 (31.8%) |
| Position net move pts | 125976.0 |
| Position avg move pts | 350.9 |
| Position profit factor | 1.25 |

### Distribution

#### signal_class
| Key | Count | % |
|---|---:|---:|
| VALID | 361 | 98.1% |
| BLOCKED | 7 | 1.9% |

#### signal_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 251 | 68.2% |
| WIN | 116 | 31.5% |
| OPEN | 1 | 0.3% |

#### position_result
| Key | Count | % |
|---|---:|---:|
| LOSS | 245 | 68.2% |
| WIN | 114 | 31.8% |

### By ADX bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ADX18-22 | 95 | 29.5% | 22168.0 | 233.3 | 5269.9 | -1871.5 | 1.18 |
| ADX15-18 | 66 | 33.3% | 43540.0 | 659.7 | 6135.3 | -2078.1 | 1.48 |
| ADX25-30 | 62 | 38.7% | 6992.0 | 112.8 | 3438.7 | -1987.8 | 1.09 |
| ADX22-25 | 57 | 35.1% | 48955.0 | 858.9 | 7054.9 | -2490.3 | 1.53 |
| ADX30-40 | 50 | 30.0% | 31690.0 | 633.8 | 6832.3 | -2022.7 | 1.45 |
| ADX12-15 | 20 | 15.0% | 652.0 | 32.6 | 7338.0 | -1256.6 | 1.03 |
| ADX>=40 | 9 | 33.3% | -6515.0 | -723.9 | 1859.7 | -2015.7 | 0.46 |
| ADX<12 | 8 | 12.5% | -2272.0 | -284.0 | 9012.0 | -1612.0 | 0.80 |

### By ATR bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| ATR12-18 | 135 | 32.6% | 33797.0 | 250.3 | 4250.4 | -1683.7 | 1.22 |
| ATR>=18 | 117 | 34.2% | 89132.0 | 761.8 | 8127.4 | -3064.5 | 1.38 |
| ATR8-12 | 105 | 27.6% | 594.0 | 5.7 | 3557.6 | -1349.7 | 1.01 |
| ATR5-8 | 10 | 30.0% | 21687.0 | 2168.7 | 9988.0 | -1182.4 | 3.62 |

### By Slow MA angle bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |angle|<1 | 235 | 28.5% | 66195.0 | 281.7 | 5565.0 | -1825.4 | 1.22 |
| |angle|>=12 | 132 | 37.1% | 79015.0 | 598.6 | 5559.0 | -2329.8 | 1.41 |

### By MA gap bin

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| |gap|25-75 | 101 | 29.7% | 25289.0 | 250.4 | 4816.4 | -1678.9 | 1.21 |
| |gap|75-150 | 87 | 32.2% | 18681.0 | 214.7 | 5112.8 | -2109.8 | 1.15 |
| |gap|<25 | 84 | 27.4% | 55012.0 | 654.9 | 5904.7 | -1324.5 | 1.68 |
| |gap|150-300 | 67 | 34.3% | 37297.0 | 556.7 | 5595.1 | -2077.0 | 1.41 |
| |gap|300-600 | 18 | 38.9% | -10015.0 | -556.4 | 2460.7 | -2476.4 | 0.63 |
| |gap|>=600 | 10 | 50.0% | 18946.0 | 1894.6 | 15175.8 | -11386.6 | 1.33 |

### By DI alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| DI_ALIGN | 300 | 33.3% | 132618.0 | 442.1 | 5445.7 | -2059.8 | 1.32 |
| DI_OPPOSE | 67 | 23.9% | 12592.0 | 187.9 | 6292.2 | -1727.1 | 1.14 |

### By V-Line alignment

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| VL_OPPOSE | 190 | 30.0% | 42613.0 | 224.3 | 5544.9 | -2056.0 | 1.16 |
| VL_ALIGN | 176 | 33.5% | 104122.0 | 591.6 | 5579.4 | -1923.6 | 1.46 |

### By V-Line state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| BULL | 165 | 27.9% | 56229.0 | 340.8 | 5618.7 | -1699.4 | 1.28 |
| BEAR | 156 | 34.0% | 103216.0 | 661.6 | 6428.9 | -2306.0 | 1.43 |
| BEAR NOISE | 24 | 45.8% | -3786.0 | -157.8 | 2752.8 | -2620.5 | 0.89 |
| BULL NOISE | 21 | 28.6% | -8924.0 | -425.0 | 2629.7 | -1646.8 | 0.64 |

### By SW state

| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |
|---|---:|---:|---:|---:|---:|---:|---:|
| OFF | 367 | 31.6% | 145210.0 | 395.7 | 5562.5 | -1992.2 | 1.29 |

### Worst signal-to-signal rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.29 23:00:00 | BUY | VALID | -23923.0 | -23913.0 | LOSS | LOSS | 17.3 | 90.71 | 23.3 | 16.1 | 0.0 | BEAR/SELL | OFF/0.90 |
| 2026.02.02 17:30:00 | SELL | VALID | -11820.0 | -11845.0 | LOSS | LOSS | 24.5 | 64.92 | 20.6 | 25.7 | -14.0 | BEAR/SELL | OFF/0.84 |
| 2026.02.05 04:30:00 | SELL | VALID | -10962.0 | -10987.0 | LOSS | LOSS | 30.8 | 42.44 | 12.6 | 33.8 | -26.6 | BEAR/SELL | OFF/0.91 |
| 2026.02.02 11:30:00 | BUY | VALID | -9942.0 | -9936.0 | LOSS | LOSS | 33.1 | 86.97 | 27.0 | 13.8 | 14.0 | BEAR/SELL | OFF/0.87 |
| 2026.04.02 01:00:00 | BUY | VALID | -7720.0 | -7710.0 | LOSS | LOSS | 21.1 | 17.49 | 22.5 | 21.9 | 0.0 | BULL/BUY | OFF/0.84 |
| 2026.03.24 19:30:00 | SELL | VALID | -6865.0 | -6911.0 | LOSS | LOSS | 22.7 | 33.27 | 15.5 | 23.8 | -14.0 | BULL/BUY | OFF/0.90 |
| 2026.02.05 10:00:00 | BUY | VALID | -6649.0 | -6652.0 | LOSS | LOSS | 21.6 | 52.63 | 16.7 | 15.9 | -14.0 | BEAR/SELL | OFF/0.83 |
| 2026.03.13 13:30:00 | BUY | VALID | -6646.0 | -6636.0 | LOSS | LOSS | 25.1 | 14.80 | 19.0 | 15.9 | 0.0 | BEAR NOISE/SELL | OFF/0.90 |
| 2026.03.24 01:00:00 | BUY | VALID | -6137.0 | -6140.0 | LOSS | LOSS | 24.0 | 40.28 | 28.5 | 11.8 | 14.0 | BULL/BUY | OFF/0.85 |
| 2026.03.26 15:30:00 | BUY | VALID | -6059.0 | -6057.0 | LOSS | LOSS | 22.3 | 25.12 | 14.9 | 14.2 | 0.0 | BEAR/SELL | OFF/0.82 |
| 2026.02.17 13:00:00 | BUY | VALID | -5718.0 | -5719.0 | LOSS | LOSS | 20.7 | 21.06 | 17.5 | 18.6 | -14.0 | BEAR/SELL | OFF/0.81 |
| 2026.02.25 01:00:00 | SELL | VALID | -5451.0 | -5482.0 | LOSS | LOSS | 19.6 | 15.40 | 12.6 | 33.2 | -14.0 | BEAR/SELL | OFF/0.79 |
| 2026.01.29 16:00:00 | BUY | VALID | -4714.0 | -4751.0 | LOSS | LOSS | 18.1 | 29.09 | 20.0 | 21.0 | 14.0 | BULL/BUY | OFF/0.88 |
| 2026.04.07 08:00:00 | SELL | VALID | -4567.0 | -4630.0 | LOSS | LOSS | 24.5 | 18.51 | 19.1 | 16.7 | -14.0 | BEAR/SELL | OFF/0.78 |
| 2026.05.22 22:00:00 | SELL | VALID | -4512.0 | -4501.0 | LOSS | LOSS | 17.2 | 12.23 | 13.0 | 27.6 | 0.0 | BULL/BUY | OFF/0.87 |

### Worst actual position rows

| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |
|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 2026.01.29 23:00:00 | BUY | VALID | -23923.0 | -23913.0 | LOSS | LOSS | 17.3 | 90.71 | 23.3 | 16.1 | 0.0 | BEAR/SELL | OFF/0.90 |
| 2026.02.02 17:30:00 | SELL | VALID | -11820.0 | -11845.0 | LOSS | LOSS | 24.5 | 64.92 | 20.6 | 25.7 | -14.0 | BEAR/SELL | OFF/0.84 |
| 2026.02.05 04:30:00 | SELL | VALID | -10962.0 | -10987.0 | LOSS | LOSS | 30.8 | 42.44 | 12.6 | 33.8 | -26.6 | BEAR/SELL | OFF/0.91 |
| 2026.02.02 11:30:00 | BUY | VALID | -9942.0 | -9936.0 | LOSS | LOSS | 33.1 | 86.97 | 27.0 | 13.8 | 14.0 | BEAR/SELL | OFF/0.87 |
| 2026.04.02 01:00:00 | BUY | VALID | -7720.0 | -7710.0 | LOSS | LOSS | 21.1 | 17.49 | 22.5 | 21.9 | 0.0 | BULL/BUY | OFF/0.84 |
| 2026.03.24 19:30:00 | SELL | VALID | -6865.0 | -6911.0 | LOSS | LOSS | 22.7 | 33.27 | 15.5 | 23.8 | -14.0 | BULL/BUY | OFF/0.90 |
| 2026.02.05 10:00:00 | BUY | VALID | -6649.0 | -6652.0 | LOSS | LOSS | 21.6 | 52.63 | 16.7 | 15.9 | -14.0 | BEAR/SELL | OFF/0.83 |
| 2026.03.13 13:30:00 | BUY | VALID | -6646.0 | -6636.0 | LOSS | LOSS | 25.1 | 14.80 | 19.0 | 15.9 | 0.0 | BEAR NOISE/SELL | OFF/0.90 |
| 2026.03.24 01:00:00 | BUY | VALID | -6137.0 | -6140.0 | LOSS | LOSS | 24.0 | 40.28 | 28.5 | 11.8 | 14.0 | BULL/BUY | OFF/0.85 |
| 2026.03.26 15:30:00 | BUY | VALID | -6059.0 | -6057.0 | LOSS | LOSS | 22.3 | 25.12 | 14.9 | 14.2 | 0.0 | BEAR/SELL | OFF/0.82 |
| 2026.02.17 13:00:00 | BUY | VALID | -5718.0 | -5719.0 | LOSS | LOSS | 20.7 | 21.06 | 17.5 | 18.6 | -14.0 | BEAR/SELL | OFF/0.81 |
| 2026.02.25 01:00:00 | SELL | VALID | -5451.0 | -5482.0 | LOSS | LOSS | 19.6 | 15.40 | 12.6 | 33.2 | -14.0 | BEAR/SELL | OFF/0.79 |
| 2026.01.29 16:00:00 | BUY | VALID | -4714.0 | -4751.0 | LOSS | LOSS | 18.1 | 29.09 | 20.0 | 21.0 | 14.0 | BULL/BUY | OFF/0.88 |
| 2026.04.07 08:00:00 | SELL | VALID | -4567.0 | -4630.0 | LOSS | LOSS | 24.5 | 18.51 | 19.1 | 16.7 | -14.0 | BEAR/SELL | OFF/0.78 |
| 2026.05.22 22:00:00 | SELL | VALID | -4512.0 | -4501.0 | LOSS | LOSS | 17.2 | 12.23 | 13.0 | 27.6 | 0.0 | BULL/BUY | OFF/0.87 |
