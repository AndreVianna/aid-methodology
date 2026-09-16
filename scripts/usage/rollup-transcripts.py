#!/usr/bin/env python3
"""Roll up Claude Code token usage for this project's sessions and sub-agent dispatches.

Maintainer tooling (not shipped to adopters). Reads the Claude Code transcripts under
``~/.claude/projects/<encoded-cwd>/`` -- ``<session>.jsonl`` for the main agent and
``<session>/subagents/agent-*.jsonl`` for each dispatched sub-agent -- and prints one
row per session and per dispatch with the four token meters the API bills separately:
uncached input, cache writes, cache reads, output. Tokens only; no dollar figures,
because the meters map to money differently per billing plan.

Usage:
    python scripts/usage/rollup-transcripts.py                 # every session of this project
    python scripts/usage/rollup-transcripts.py --session <id>  # one session + its dispatches
    python scripts/usage/rollup-transcripts.py --since 2026-09-01
    python scripts/usage/rollup-transcripts.py --project-dir <path-to-transcript-dir>

Exit 0 on success, 2 when the transcript directory cannot be found.
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
import sys
from pathlib import Path

METERS = ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens")


def encoded_cwd(path: str) -> str:
    """Claude Code names the transcript dir by replacing every non-alphanumeric char with '-'."""
    return re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(path))


def default_project_dir() -> Path:
    home = Path(os.environ.get("USERPROFILE") or os.environ.get("HOME") or "~").expanduser()
    return home / ".claude" / "projects" / encoded_cwd(os.getcwd())


def scan(file: Path, since: str | None):
    """Yield (model, timestamp, usage) once per assistant turn in one transcript file.

    Claude Code writes one JSONL line per content block (thinking, text, tool_use) and
    repeats the turn's ``usage`` on each, so lines are de-duplicated by ``message.id``,
    keeping the entry with the largest ``output_tokens`` (the final block of the turn).
    """
    turns: dict[str, tuple[str, str, dict]] = {}
    order: list[str] = []
    with file.open(encoding="utf-8", errors="ignore") as fh:
        for n, line in enumerate(fh):
            if '"usage"' not in line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg = obj.get("message") or {}
            usage = msg.get("usage")
            if not isinstance(usage, dict):
                continue
            ts = (obj.get("timestamp") or "")[:19]
            if since and ts[:10] < since:
                continue
            key = msg.get("id") or f"line-{n}"
            prev = turns.get(key)
            if prev is None:
                order.append(key)
                turns[key] = (msg.get("model", "?"), ts, usage)
            elif int(usage.get("output_tokens") or 0) >= int(prev[2].get("output_tokens") or 0):
                turns[key] = (msg.get("model", "?"), ts, usage)
    for key in order:
        yield turns[key]


def rollup(files, since):
    totals = collections.Counter()
    by_model = collections.defaultdict(collections.Counter)
    first = last = None
    max_cache_read = 0
    for f in files:
        for model, ts, u in scan(f, since):
            totals["turns"] += 1
            by_model[model]["turns"] += 1
            for m in METERS:
                v = int(u.get(m) or 0)
                totals[m] += v
                by_model[model][m] += v
            max_cache_read = max(max_cache_read, int(u.get("cache_read_input_tokens") or 0))
            if ts:
                first = ts if first is None or ts < first else first
                last = ts if last is None or ts > last else last
    return totals, by_model, first, last, max_cache_read


def fmt_row(label: str, c: collections.Counter, extra: str = "") -> str:
    turns = c["turns"]
    inp, cw, cr, out = (c[m] for m in METERS)
    denom = inp + cw + cr
    hit = 100.0 * cr / denom if denom else 0.0
    per_turn = cr // turns if turns else 0
    return (f"{label:<44}{turns:>6}{inp:>11,}{cw:>12,}{cr:>14,}{out:>10,}"
            f"{hit:>7.1f}{per_turn:>14,}{extra}")


HEADER = (f"{'session / dispatch':<44}{'turns':>6}{'input':>11}{'cache_w':>12}"
          f"{'cache_r':>14}{'output':>10}{'hit%':>7}{'cache_r/turn':>14}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--project-dir", type=Path, default=None, help="transcript dir (default: derived from cwd)")
    ap.add_argument("--session", default=None, help="only this session id (file stem)")
    ap.add_argument("--since", default=None, help="ISO date; ignore turns before it")
    args = ap.parse_args()

    # Windows consoles often default to cp1252; keep the table printable everywhere.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

    pdir = args.project_dir or default_project_dir()
    if not pdir.is_dir():
        print(f"transcript dir not found: {pdir}", file=sys.stderr)
        return 2

    sessions = sorted(pdir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
    if args.session:
        sessions = [p for p in sessions if p.stem == args.session]
        if not sessions:
            print(f"no session {args.session!r} under {pdir}", file=sys.stderr)
            return 2

    print(f"transcripts: {pdir}")
    print(HEADER)
    grand = collections.Counter()
    grand_models = collections.defaultdict(collections.Counter)
    for s in sessions:
        tot, models, first, last, max_cr = rollup([s], args.since)
        if not tot["turns"]:
            continue
        span = f"  {first[:16]}..{last[11:16]}" if first and last else ""
        print(fmt_row(s.stem[:8] + " (main)", tot, span))
        grand.update(tot)
        for m, c in models.items():
            grand_models[m].update(c)
        subdir = s.with_suffix("") / "subagents"
        for sub in sorted(subdir.glob("*.jsonl")) if subdir.is_dir() else []:
            st, sm, _, _, _ = rollup([sub], args.since)
            if not st["turns"]:
                continue
            model = ",".join(sorted(k for k in sm if k != "?")) or "?"
            print(fmt_row(f"  └ {sub.stem[:22]} [{model[:14]}]", st))
            grand.update(st)
            for m, c in sm.items():
                grand_models[m].update(c)
    print("-" * len(HEADER))
    print(fmt_row("TOTAL", grand))
    if len(grand_models) > 1:
        for m, c in sorted(grand_models.items(), key=lambda kv: -kv[1]["cache_read_input_tokens"]):
            print(fmt_row(f"  by model: {m}", c))
    return 0


if __name__ == "__main__":
    sys.exit(main())
