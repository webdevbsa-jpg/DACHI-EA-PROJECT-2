#!/usr/bin/env python3
"""Analyze Dachi Auto Journal CSV files.

Usage examples:
  python3 tools/analyze_dachi_journal.py M1=path/to/M1.csv M5=path/to/M5.csv --out reports/report.md
  python3 tools/analyze_dachi_journal.py M1=https://...csv M5=https://...csv --out reports/report.md

The journal uses semicolon-separated fields as emitted by Dachi EA v13.11.44+.
This script is intentionally stdlib-only so it can run in MT5/Windows machines
without installing pandas.
"""
from __future__ import annotations

import argparse
import csv
import math
import os
import statistics as stats
import sys
import urllib.request
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, Any

NUMERIC_FIELDS = {
    "signal_entry_price", "signal_exit_price", "signal_move_pts", "signal_duration_bars",
    "position_exit_price", "position_move_pts", "position_duration_bars",
    "atr", "spread", "ema_fast", "slow_ma", "ma_gap_pts", "slow_angle_deg",
    "sw_score", "adx", "di_plus", "di_minus", "sl", "tp1", "tp2", "tp3", "tp4", "tp5",
}

DIRECTION_SIGN = {"BUY": 1, "SELL": -1}


def parse_float(v: Any) -> float | None:
    if v is None:
        return None
    s = str(v).strip()
    if not s:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def fmt(v: Any, nd: int = 2) -> str:
    if v is None:
        return "—"
    if isinstance(v, float):
        if math.isnan(v) or math.isinf(v):
            return "—"
        return f"{v:.{nd}f}"
    return str(v)


def pct(num: float, den: float) -> str:
    if not den:
        return "—"
    return f"{100.0*num/den:.1f}%"


def median(xs: list[float]) -> float | None:
    return stats.median(xs) if xs else None


def mean(xs: list[float]) -> float | None:
    return sum(xs) / len(xs) if xs else None


def quantile(xs: list[float], q: float) -> float | None:
    if not xs:
        return None
    ys = sorted(xs)
    idx = (len(ys)-1) * q
    lo = math.floor(idx); hi = math.ceil(idx)
    if lo == hi:
        return ys[int(idx)]
    return ys[lo] * (hi-idx) + ys[hi] * (idx-lo)


def signed_value(row: dict[str, str], field: str) -> float | None:
    v = parse_float(row.get(field))
    if v is None:
        return None
    # Journal move fields are already direction-adjusted by the EA.
    return v


def read_source(src: str) -> str:
    if src.startswith("http://") or src.startswith("https://"):
        req = urllib.request.Request(src, headers={"User-Agent": "DachiJournalAnalyzer/1.0"})
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.read().decode("utf-8-sig", errors="replace")
    return Path(src).read_text(encoding="utf-8-sig", errors="replace")


def load_csv(src: str) -> list[dict[str, str]]:
    text = read_source(src)
    rows = list(csv.DictReader(text.splitlines(), delimiter=";"))
    return rows


def counter_table(counter: Counter, max_rows: int = 12) -> str:
    total = sum(counter.values())
    lines = ["| Key | Count | % |", "|---|---:|---:|"]
    for k, c in counter.most_common(max_rows):
        lines.append(f"| {k or '—'} | {c} | {pct(c,total)} |")
    return "\n".join(lines)


def result_stats(rows: list[dict[str, str]], move_field: str, result_field: str) -> dict[str, Any]:
    moves = [signed_value(r, move_field) for r in rows if signed_value(r, move_field) is not None]
    wins = [x for r, x in ((r, signed_value(r, move_field)) for r in rows) if x is not None and str(r.get(result_field,"")) == "WIN"]
    losses = [x for r, x in ((r, signed_value(r, move_field)) for r in rows) if x is not None and str(r.get(result_field,"")) == "LOSS"]
    bes = [x for r, x in ((r, signed_value(r, move_field)) for r in rows) if x is not None and str(r.get(result_field,"")) == "BE"]
    gross_win = sum(x for x in moves if x > 0)
    gross_loss = -sum(x for x in moves if x < 0)
    return {
        "n": len(moves),
        "wins": len(wins),
        "losses": len(losses),
        "be": len(bes),
        "winrate": len(wins) / len(moves) if moves else None,
        "net": sum(moves) if moves else None,
        "avg": mean(moves),
        "median": median(moves),
        "avg_win": mean([x for x in moves if x > 0]),
        "avg_loss": mean([x for x in moves if x < 0]),
        "pf": gross_win / gross_loss if gross_loss else None,
        "q25": quantile(moves, 0.25),
        "q75": quantile(moves, 0.75),
    }


def summarize_group(rows: list[dict[str, str]], key: str, move_field: str = "signal_move_pts", result_field: str = "signal_result", min_n: int = 10) -> list[tuple[str, dict[str, Any]]]:
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for r in rows:
        groups[str(r.get(key, "") or "—")].append(r)
    out = []
    for k, rs in groups.items():
        if len(rs) >= min_n:
            out.append((k, result_stats(rs, move_field, result_field)))
    out.sort(key=lambda kv: (kv[1].get("net") is None, -(kv[1].get("n") or 0), kv[0]))
    return out


def group_md(title: str, groups: list[tuple[str, dict[str, Any]]], max_rows: int = 12) -> str:
    lines = [f"### {title}", "", "| Group | N | Winrate | Net pts | Avg | Avg Win | Avg Loss | PF |", "|---|---:|---:|---:|---:|---:|---:|---:|"]
    for k, s in groups[:max_rows]:
        wr = "—" if s["winrate"] is None else f"{s['winrate']*100:.1f}%"
        lines.append(f"| {k} | {s['n']} | {wr} | {fmt(s['net'],1)} | {fmt(s['avg'],1)} | {fmt(s['avg_win'],1)} | {fmt(s['avg_loss'],1)} | {fmt(s['pf'],2)} |")
    return "\n".join(lines)


def bin_adx(v: float | None) -> str:
    if v is None: return "NO_DATA"
    if v < 12: return "ADX<12"
    if v < 15: return "ADX12-15"
    if v < 18: return "ADX15-18"
    if v < 22: return "ADX18-22"
    if v < 25: return "ADX22-25"
    if v < 30: return "ADX25-30"
    if v < 40: return "ADX30-40"
    return "ADX>=40"


def bin_atr(v: float | None) -> str:
    if v is None: return "NO_DATA"
    if v < 1: return "ATR<1"
    if v < 2: return "ATR1-2"
    if v < 3: return "ATR2-3"
    if v < 5: return "ATR3-5"
    if v < 8: return "ATR5-8"
    if v < 12: return "ATR8-12"
    if v < 18: return "ATR12-18"
    return "ATR>=18"


def bin_angle(v: float | None) -> str:
    if v is None: return "NO_DATA"
    a = abs(v)
    if a < 1: return "|angle|<1"
    if a < 3: return "|angle|1-3"
    if a < 5: return "|angle|3-5"
    if a < 8: return "|angle|5-8"
    if a < 12: return "|angle|8-12"
    return "|angle|>=12"


def bin_magap(v: float | None) -> str:
    if v is None: return "NO_DATA"
    a = abs(v)
    if a < 25: return "|gap|<25"
    if a < 75: return "|gap|25-75"
    if a < 150: return "|gap|75-150"
    if a < 300: return "|gap|150-300"
    if a < 600: return "|gap|300-600"
    return "|gap|>=600"


def add_bins(rows: list[dict[str, str]]) -> None:
    for r in rows:
        r["_adx_bin"] = bin_adx(parse_float(r.get("adx")))
        r["_atr_bin"] = bin_atr(parse_float(r.get("atr")))
        r["_angle_bin"] = bin_angle(parse_float(r.get("slow_angle_deg")))
        r["_magap_bin"] = bin_magap(parse_float(r.get("ma_gap_pts")))
        d = r.get("direction", "")
        di_p = parse_float(r.get("di_plus")); di_m = parse_float(r.get("di_minus"))
        if di_p is None or di_m is None:
            r["_di_align"] = "NO_DATA"
        elif d == "BUY":
            r["_di_align"] = "DI_ALIGN" if di_p > di_m else "DI_OPPOSE"
        elif d == "SELL":
            r["_di_align"] = "DI_ALIGN" if di_m > di_p else "DI_OPPOSE"
        else:
            r["_di_align"] = "NO_DIR"
        vl = str(r.get("vline_dir", "") or "NONE")
        if d == "BUY":
            r["_vline_align"] = "VL_ALIGN" if vl == "BUY" else ("VL_OPPOSE" if vl == "SELL" else "VL_NONE")
        elif d == "SELL":
            r["_vline_align"] = "VL_ALIGN" if vl == "SELL" else ("VL_OPPOSE" if vl == "BUY" else "VL_NONE")
        else:
            r["_vline_align"] = "NO_DIR"


def worst_rows_md(rows: list[dict[str,str]], title: str, field: str, n: int = 15) -> str:
    items = []
    for r in rows:
        v = parse_float(r.get(field))
        if v is not None:
            items.append((v, r))
    items.sort(key=lambda x: x[0])
    lines = [f"### {title}", "", "| Time | Dir | Class | Move | PosMove | SigResult | PosResult | ADX | ATR | DI+ | DI- | Angle | VLine | SW |", "|---|---|---|---:|---:|---|---|---:|---:|---:|---:|---:|---|---|"]
    for v, r in items[:n]:
        lines.append("| {event_time} | {direction} | {signal_class} | {sm} | {pm} | {sr} | {pr} | {adx} | {atr} | {dip} | {dim} | {ang} | {vl} | {sw} |".format(
            event_time=r.get("event_time",""), direction=r.get("direction",""), signal_class=r.get("signal_class",""),
            sm=fmt(parse_float(r.get("signal_move_pts")),1), pm=fmt(parse_float(r.get("position_move_pts")),1),
            sr=r.get("signal_result",""), pr=r.get("position_result",""), adx=fmt(parse_float(r.get("adx")),1),
            atr=fmt(parse_float(r.get("atr")),2), dip=fmt(parse_float(r.get("di_plus")),1), dim=fmt(parse_float(r.get("di_minus")),1),
            ang=fmt(parse_float(r.get("slow_angle_deg")),1), vl=(r.get("vline_state","") + "/" + r.get("vline_dir","")).strip("/"),
            sw=(r.get("sw_state","") + "/" + r.get("sw_score","")).strip("/")))
    return "\n".join(lines)


def analyze_tf(tf: str, rows: list[dict[str, str]]) -> str:
    add_bins(rows)
    sig_stats = result_stats(rows, "signal_move_pts", "signal_result")
    pos_rows = [r for r in rows if parse_float(r.get("position_move_pts")) is not None]
    pos_stats = result_stats(pos_rows, "position_move_pts", "position_result")
    lines = [f"## {tf}", ""]
    lines += ["### Core metrics", "", "| Metric | Value |", "|---|---:|"]
    lines.append(f"| Rows / signals | {len(rows)} |")
    lines.append(f"| Signal winrate | {sig_stats['wins']}/{sig_stats['n']} ({fmt((sig_stats['winrate'] or 0)*100,1)}%) |")
    lines.append(f"| Signal net move pts | {fmt(sig_stats['net'],1)} |")
    lines.append(f"| Signal avg move pts | {fmt(sig_stats['avg'],1)} |")
    lines.append(f"| Signal profit factor | {fmt(sig_stats['pf'],2)} |")
    lines.append(f"| Position rows | {pos_stats['n']} |")
    lines.append(f"| Position winrate | {pos_stats['wins']}/{pos_stats['n']} ({fmt((pos_stats['winrate'] or 0)*100,1)}%) |")
    lines.append(f"| Position net move pts | {fmt(pos_stats['net'],1)} |")
    lines.append(f"| Position avg move pts | {fmt(pos_stats['avg'],1)} |")
    lines.append(f"| Position profit factor | {fmt(pos_stats['pf'],2)} |")
    lines += ["", "### Distribution", "", "#### signal_class", counter_table(Counter(r.get("signal_class","") for r in rows)), "", "#### signal_result", counter_table(Counter(r.get("signal_result","") for r in rows)), "", "#### position_result", counter_table(Counter(r.get("position_result","") for r in rows if r.get("position_result"))), ""]
    for title, key in [
        ("By ADX bin", "_adx_bin"), ("By ATR bin", "_atr_bin"), ("By Slow MA angle bin", "_angle_bin"),
        ("By MA gap bin", "_magap_bin"), ("By DI alignment", "_di_align"), ("By V-Line alignment", "_vline_align"),
        ("By V-Line state", "vline_state"), ("By SW state", "sw_state"),
    ]:
        lines += [group_md(title, summarize_group(rows, key, min_n=max(5, len(rows)//50))), ""]
    lines += [worst_rows_md(rows, "Worst signal-to-signal rows", "signal_move_pts"), ""]
    if pos_rows:
        lines += [worst_rows_md(pos_rows, "Worst actual position rows", "position_move_pts"), ""]
    return "\n".join(lines)


def recommendations(all_rows_by_tf: dict[str, list[dict[str,str]]]) -> str:
    lines = ["## Institutional-style interpretation framework", ""]
    lines.append("Use this report as a baseline run because the user stated all filters were OFF except spread and all exit gates were OFF. The goal is not to maximize one backtest immediately; the goal is to identify which market conditions consistently create negative expectancy before re-enabling filters.")
    lines += ["", "### Recommended decision rules to test next", ""]
    lines += [
        "1. **ADX/DI gate:** If the report shows negative expectancy in `ADX<15` or `ADX15-18`, enable a minimum ADX gate or require DI alignment. Start with `ADX >= 18` on M1/M5 and `ADX >= 15` on M15/M30, then retest.",
        "2. **Slow MA angle gate:** If `|angle|<1` or `|angle|1-3` is strongly negative, enable SlowMA Angle Guard. Start with `0°` for reversal-friendly trading, then test `3°` for trend-follow only.",
        "3. **MA gap anti-chop:** If `|gap|<25` or `|gap|25-75` is negative, add a minimum MA-gap filter. This is usually more direct than ADX for fast MA-cross systems because it blocks micro-crossing clusters.",
        "4. **V-Line as BRE veto, not main hard filter:** If `VL_OPPOSE` is negative and `VL_ALIGN` is positive, keep `InpUseVLineGuard=false` for raw entries but set `InpBRE_UseVLineAlignment=true` so recovery entries cannot fight V-Line.",
        "5. **SW / Sideway Clustering:** If `SW CHOP/MIXED` rows are negative but `TREND/TREND_OVR` positive, re-enable SW in `F_SOFT` first. Do not go hard until blocked-winner rate is measured.",
        "6. **Exit system:** If `signal_result=WIN` but `position_result=LOSS`, exits/SL are too tight or reversal close is firing prematurely. If `signal_result=LOSS` but `position_result=WIN`, exit gates are protecting capital and should stay enabled.",
    ]
    lines += ["", "### Timeframe ranking method", ""]
    lines.append("Rank each TF by: (1) signal profit factor, (2) average move, (3) drawdown proxy from worst rows, (4) signal density, and (5) stability across ADX/ATR bins. In practice, M1 is usually execution/noise-heavy, M5 is often the best scalper execution TF, M15 is best for context/confirmation, and M30 is usually cleaner but slower.")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("sources", nargs="+", help="TF=path_or_url pairs, e.g. M5=file.csv")
    ap.add_argument("--out", default="reports/dachi_journal_analysis.md")
    args = ap.parse_args()
    by_tf: dict[str, list[dict[str,str]]] = {}
    for item in args.sources:
        if "=" not in item:
            raise SystemExit(f"source must be TF=path_or_url: {item}")
        tf, src = item.split("=", 1)
        print(f"Loading {tf}: {src}", file=sys.stderr)
        rows = load_csv(src)
        by_tf[tf] = rows
        print(f"  rows={len(rows)}", file=sys.stderr)
    out = ["# Dachi Auto Journal Analysis", "", f"Generated: {datetime.now().isoformat(timespec='seconds')}", "", "Sources:"]
    for tf in by_tf:
        out.append(f"- {tf}: {len(by_tf[tf])} rows")
    out += ["", recommendations(by_tf), ""]
    for tf, rows in by_tf.items():
        out.append(analyze_tf(tf, rows))
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text("\n".join(out), encoding="utf-8")
    print(args.out)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
