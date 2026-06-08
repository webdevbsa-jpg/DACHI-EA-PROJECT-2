# Beginner PowerShell helper for Dachi Auto Journal analysis.
# You can run it from the repo root OR copy this .ps1 beside the CSV files and analyze_dachi_journal.py.

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Candidates = @(
    @{ WorkDir = $ScriptDir; Analyzer = Join-Path $ScriptDir 'analyze_dachi_journal.py' },
    @{ WorkDir = $ScriptDir; Analyzer = Join-Path $ScriptDir 'tools\analyze_dachi_journal.py' },
    @{ WorkDir = (Resolve-Path (Join-Path $ScriptDir '..') -ErrorAction SilentlyContinue).Path; Analyzer = Join-Path $ScriptDir 'analyze_dachi_journal.py' },
    @{ WorkDir = (Resolve-Path (Join-Path $ScriptDir '..') -ErrorAction SilentlyContinue).Path; Analyzer = Join-Path (Resolve-Path (Join-Path $ScriptDir '..') -ErrorAction SilentlyContinue).Path 'tools\analyze_dachi_journal.py' }
)

$WorkDir = $null
$Analyzer = $null
foreach ($c in $Candidates) {
    if ($null -ne $c.WorkDir -and (Test-Path $c.Analyzer)) {
        # Prefer the folder that actually contains the CSV files.
        if (Test-Path (Join-Path $c.WorkDir 'Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv')) {
            $WorkDir = $c.WorkDir
            $Analyzer = $c.Analyzer
            break
        }
        if ($null -eq $Analyzer) {
            $WorkDir = $c.WorkDir
            $Analyzer = $c.Analyzer
        }
    }
}

if ($null -eq $Analyzer) {
    Write-Host 'Cannot find analyze_dachi_journal.py.' -ForegroundColor Red
    Write-Host 'Put this .ps1 in the repo folder, or copy it beside analyze_dachi_journal.py and the CSV files.'
    Read-Host 'Press Enter to close'
    exit 1
}

Set-Location $WorkDir

$M1  = 'Dachi_Signal_Journal_XAUUSD_M1_20260101_000000_801487109.csv'
$M5  = 'Dachi_Signal_Journal_XAUUSD_M5_20260101_000000_801512250.csv'
$M15 = 'Dachi_Signal_Journal_XAUUSD_M15_20260101_000000_801534187.csv'
$M30 = 'Dachi_Signal_Journal_XAUUSD_M30_20260101_000000_801945593.csv'

$Missing = @()
foreach ($f in @($M1, $M5, $M15, $M30)) {
    if (-not (Test-Path (Join-Path $WorkDir $f))) { $Missing += $f }
}

if ($Missing.Count -gt 0) {
    Write-Host 'Missing CSV files:' -ForegroundColor Red
    $Missing | ForEach-Object { Write-Host "  $_" }
    Write-Host "Current folder: $WorkDir"
    Write-Host 'Copy the four CSV files into this folder, then run again.'
    Read-Host 'Press Enter to close'
    exit 1
}

$ReportDir = Join-Path $WorkDir 'reports'
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$OutFile = Join-Path $ReportDir 'dachi_journal_analysis_full.md'

Write-Host "WorkDir : $WorkDir"
Write-Host "Analyzer: $Analyzer"
Write-Host "Output  : $OutFile"
Write-Host ''

$Py = Get-Command py -ErrorAction SilentlyContinue
if ($null -ne $Py) {
    & py -3 $Analyzer M1=$M1 M5=$M5 M15=$M15 M30=$M30 --out $OutFile
} else {
    $Python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $Python) {
        Write-Host 'Python was not found. Install Python from python.org, then run this script again.' -ForegroundColor Red
        Read-Host 'Press Enter to close'
        exit 1
    }
    & python $Analyzer M1=$M1 M5=$M5 M15=$M15 M30=$M30 --out $OutFile
}

if ($LASTEXITCODE -ne 0) {
    Write-Host 'Analyzer failed.' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'Done. Open this report:' -ForegroundColor Green
Write-Host $OutFile
Read-Host 'Press Enter to close'
