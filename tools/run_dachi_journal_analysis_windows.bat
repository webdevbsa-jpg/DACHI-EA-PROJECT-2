@echo off
setlocal
REM Beginner helper for Dachi Auto Journal analysis on Windows.
REM Works from repo tools folder OR copied beside the CSV files and analyze_dachi_journal.py.

set SCRIPT_DIR=%~dp0
set WORKDIR=
set ANALYZER=

REM Case 1: BAT copied beside CSV files and analyzer.
if exist "%SCRIPT_DIR%analyze_dachi_journal.py" if exist "%SCRIPT_DIR%Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv" (
  set WORKDIR=%SCRIPT_DIR%
  set ANALYZER=%SCRIPT_DIR%analyze_dachi_journal.py
  goto found
)

REM Case 2: BAT is in repo\tools, CSV files are in repo root.
if exist "%SCRIPT_DIR%analyze_dachi_journal.py" if exist "%SCRIPT_DIR%..\Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv" (
  set WORKDIR=%SCRIPT_DIR%..\
  set ANALYZER=%SCRIPT_DIR%analyze_dachi_journal.py
  goto found
)

REM Case 3: BAT is in repo root, analyzer is in tools.
if exist "%SCRIPT_DIR%tools\analyze_dachi_journal.py" if exist "%SCRIPT_DIR%Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv" (
  set WORKDIR=%SCRIPT_DIR%
  set ANALYZER=%SCRIPT_DIR%tools\analyze_dachi_journal.py
  goto found
)

:found
if "%WORKDIR%"=="" goto no_analyzer
cd /d "%WORKDIR%"

set M1=Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv
set M5=Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv
set M15=Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv
set M30=Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv

if not exist "%M1%" echo Missing %M1%
if not exist "%M5%" echo Missing %M5%
if not exist "%M15%" echo Missing %M15%
if not exist "%M30%" echo Missing %M30%

if not exist "%M1%" goto missing
if not exist "%M5%" goto missing
if not exist "%M15%" goto missing
if not exist "%M30%" goto missing

if not exist reports mkdir reports

echo WorkDir : %cd%
echo Analyzer: %ANALYZER%
echo Output  : reports\dachi_journal_analysis_full.md
echo.

py -3 "%ANALYZER%" M1="%M1%" M5="%M5%" M15="%M15%" M30="%M30%" --out reports\dachi_journal_analysis_full.md
if errorlevel 1 (
  echo.
  echo Python command failed. If py is not installed, try installing Python from python.org and tick Add Python to PATH.
  pause
  exit /b 1
)

echo.
echo Done. Open this report:
echo reports\dachi_journal_analysis_full.md
echo.
pause
exit /b 0

:no_analyzer
echo.
echo Cannot find analyze_dachi_journal.py.
echo Put this BAT in the repo folder, or copy it beside analyze_dachi_journal.py and the CSV files.
echo.
pause
exit /b 1

:missing
echo.
echo Please copy the four Dachi_Signal_Journal_*.csv files into this folder:
echo %cd%
echo.
pause
exit /b 1
