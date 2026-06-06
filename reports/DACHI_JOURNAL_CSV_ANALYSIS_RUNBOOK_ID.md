# Dachi Auto Journal CSV Analysis Runbook

This runbook was added because the current container can view the GitHub CSV metadata via the browser tool, but shell downloads to GitHub/raw/CDN endpoints are blocked by the environment proxy (`CONNECT tunnel failed: 403`). The repository now includes a stdlib-only analyzer so the same institutional-style journal analysis can be run locally from the CSV files.

## CSV files provided by user

- M1: `https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv`
- M5: `https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv`
- M15: `https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv`
- M30: `https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv`

GitHub metadata observed via browser:

- M1: 4,371 lines, approximately 1.2 MB.
- M5: 2,063 lines, approximately 582 KB.
- M15: 689 lines, approximately 195 KB.
- M30: 369 lines, approximately 105 KB.



## Common error: PowerShell says `M15=... is not recognized`

This happens when a Bash/CMD-style multi-line command is pasted into **PowerShell**. PowerShell tries to run `M15=...csv` as a program. Use one of these safer methods instead:

### Best method

Run the helper instead of typing the long command:

```text
tools\run_dachi_journal_analysis_windows.ps1
```

If Windows blocks PowerShell scripts, right-click the `.ps1` file and choose **Run with PowerShell**, or use the BAT helper:

```text
tools\run_dachi_journal_analysis_windows.bat
```

### PowerShell one-line command

If you want to run manually in PowerShell, use **one line** like this from the folder that contains the CSV files and `analyze_dachi_journal.py`:

```powershell
py -3 .\analyze_dachi_journal.py M1=.\Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv M5=.\Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv M15=.\Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv M30=.\Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv --out .\reports\dachi_journal_analysis_full.md
```

Do **not** type only `M15=...csv` or `M30=...csv` by itself; those are arguments to Python, not standalone PowerShell commands.

## Beginner step-by-step: Windows local run

Use this path if you are new to Python/terminal.

### Step 1 — Install Python

1. Download/install Python for Windows from the official Python site.
2. During installation, enable **Add Python to PATH** if the installer shows that option.
3. Open **Command Prompt** and check:

```bat
py -3 --version
```

If that prints a Python version, Python is ready.

### Step 2 — Put the CSV files in the repo folder

Copy the four journal CSV files into the same folder that contains this repo, beside `tools` and `reports`:

```text
DACHI-EA-PROJECT-2\
  tools\
  reports\
  Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv
  Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv
  Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv
  Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv
```

### Step 3A — Easiest method: double-click the BAT helper

Double-click the BAT helper:

```text
tools\run_dachi_journal_analysis_windows.bat
```

Or right-click the PowerShell helper and choose **Run with PowerShell**:

```text
tools\run_dachi_journal_analysis_windows.ps1
```

The script will create:

```text
reports\dachi_journal_analysis_full.md
```

Open that `.md` file with VS Code, Notepad, or any Markdown viewer, then send its contents back for deeper strategy interpretation.

### Step 3B — Manual Command Prompt method

Open Command Prompt inside the repo folder and run:

```bat
py -3 tools\analyze_dachi_journal.py ^
  M1=Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv ^
  M5=Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv ^
  M15=Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv ^
  M30=Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv ^
  --out reports\dachi_journal_analysis_full.md
```

### Step 4 — Send the result

After the report is created, send me either:

- the full `reports/dachi_journal_analysis_full.md`, or
- the key sections per timeframe if the file is too long.

## How to run locally

From the repo root, after the CSV files are available locally:

```bash
python3 tools/analyze_dachi_journal.py \
  M1=Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv \
  M5=Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv \
  M15=Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv \
  M30=Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv \
  --out reports/dachi_journal_analysis_full.md
```

If network access works on the local machine, URLs can be passed directly:

```bash
python3 tools/analyze_dachi_journal.py \
  M1=https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv \
  M5=https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv \
  M15=https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv \
  M30=https://raw.githubusercontent.com/webdevbsa-jpg/DACHI-EA-PROJECT-2/refs/heads/main/Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv \
  --out reports/dachi_journal_analysis_full.md
```

## What the analyzer computes

The analyzer reads Dachi semicolon-delimited Auto Journal files and computes, per timeframe:

- signal-to-signal win rate, net points, average move, profit factor;
- actual position-exit win rate, net points, average move, profit factor;
- distribution by `signal_class`, `signal_result`, and `position_result`;
- performance by ADX bin, ATR bin, slow MA angle bin, MA gap bin, DI alignment, V-Line alignment/state, and SW state;
- worst signal-to-signal rows and worst actual position rows.

## Institutional interpretation checklist

Because this test was described as **all filters OFF except spread** and **all exit gates OFF**, treat the output as a raw MA-cross baseline:

1. If `ADX<15` or `ADX15-18` is strongly negative, test a minimum ADX rule.
2. If `DI_OPPOSE` is strongly negative, require DI alignment for entry and BRE.
3. If `|angle|<1` or `|angle|1-3` is strongly negative, enable SlowMA Angle Guard.
4. If small MA-gap bins are negative, add a minimum MA-gap anti-chop rule.
5. If `VL_OPPOSE` is negative, keep V-Line as a BRE veto even if the V-Line hard guard remains OFF.
6. If `SW CHOP/MIXED` is negative while `TREND/TREND_OVR` is positive, re-enable SW as `F_SOFT` first.
7. Compare `signal_result` vs `position_result`: if signal wins but position loses, the exit/SL path is harming good entries; if signal loses but position wins, exit gates protect capital.
