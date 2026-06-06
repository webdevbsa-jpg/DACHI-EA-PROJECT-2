@echo off
setlocal
REM Beginner helper for Dachi Auto Journal analysis on Windows.
REM Put this file/repo folder together with the four CSV files, then double-click this .bat.

cd /d "%~dp0\.."

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

py -3 tools\analyze_dachi_journal.py M1="%M1%" M5="%M5%" M15="%M15%" M30="%M30%" --out reports\dachi_journal_analysis_full.md
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

:missing
echo.
echo Please copy the four Dachi_Signal_Journal_*.csv files into this repo folder:
echo %cd%
echo.
pause
exit /b 1
