#!/usr/bin/env bash
# kb-citation-lint.sh -- flag VOLATILE bare line-number citations in KB docs.
#
# The KB authoring standard (kb-authoring principles.md) requires DURABLE anchors: a file
# path plus a grep-recoverable symbol/heading, NOT a bare `file.ext:LINE` (line numbers drift).
# This lint catches the bare-line form MECHANICALLY so it is fixed at the source (GENERATE)
# instead of one phase later (REVIEW) -- the agent's prose instruction + self-report are not
# enough, so the orchestrator gates on this script.
#
# A finding is `<file>.<ext>:<linespec>` where <linespec> is a pure line number or range/list
# (e.g. :39, :33,47, :106-125, :126-141,228). DURABLE anchors are NOT flagged:
#   - file.ext:symbol_name   (letters right after the colon)
#   - concern-model.md:15-doc seed   (digits followed by letters)
#   - server.mjs:127.0.0.1   (IP / version: digits followed by .digit)
#
# Usage:  kb-citation-lint.sh [--root .aid/knowledge] [--depth N|all]
#
#   --depth N    scan N directory levels below --root. Default 1, which is the
#                KB's own shape (every doc sits directly under .aid/knowledge).
#   --depth all  scan every .md beneath --root, at any depth.
#
# Depth matters outside the KB. A work folder nests its feature SPECs two levels
# down, so a depth-1 scan of a work root opens a small handful of its markdown
# and reports "clean" -- a green that means "found nothing where it did not
# look". Judge a run by the opened count printed on stderr, not by the verdict
# alone, which is why opening ZERO files is an error rather than a clean bill.
#
# Exit:   0 = clean, 1 = violations found, 2 = usage/error.

set -uo pipefail

ROOT=".aid/knowledge"
DEPTH="1"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --depth) DEPTH="${2:-}"; shift 2 ;;
    --recursive) DEPTH="all"; shift ;;
    -h|--help) sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "kb-citation-lint.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$ROOT" ]] || { echo "kb-citation-lint.sh: not a directory: $ROOT" >&2; exit 2; }

if [[ "$DEPTH" != "all" ]] && ! [[ "$DEPTH" =~ ^[1-9][0-9]*$ ]]; then
  echo "kb-citation-lint.sh: --depth must be a positive integer or 'all', got: ${DEPTH}" >&2
  exit 2
fi

# Collect the doc set ONCE (find | sort) and scan ALL docs in a SINGLE awk pass.
# awk tracks per-file position itself (FILENAME / FNR reset per file), so batching
# over "${docs[@]}" in the same sorted order emits byte-identical findings to the old
# one-awk-per-doc loop -- while removing the per-doc subprocess spawn that was slow on
# Windows Git Bash / MSYS (one fork per KB doc). The awk program is unchanged.
# `-L` so a symlinked --root is followed. Without it, `find` returns nothing for
# a symlink while bash's `-d` guard happily accepts it, and the run reported
# "opened 0 file(s) ... clean" for a tree that in fact contained violations.
if [[ "$DEPTH" == "all" ]]; then
  mapfile -t docs < <(find -L "$ROOT" -type f -name '*.md' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
else
  mapfile -t docs < <(find -L "$ROOT" -maxdepth "$DEPTH" -type f -name '*.md' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
fi

# Printed on stderr for every run, clean or not, and deliberately not on stdout:
# the KB invocation's stdout stays byte-identical to before this option existed.
# It is here because "clean" and "looked at nothing" are the same verdict, and
# only this number tells them apart.
echo "kb-citation-lint: opened ${#docs[@]} file(s) under ${ROOT} (depth: ${DEPTH})." >&2

# Opening nothing is an ERROR, not a clean bill of health. The two are
# indistinguishable by exit code otherwise, and every way of reaching zero here
# is a mistake worth surfacing: a mistyped root, a root whose docs are nested
# below --depth, or a symlink that find refused to follow. Exit 2 rather than 1
# because the caller pointed the lint somewhere wrong -- it is not a finding
# about the content.
if [[ ${#docs[@]} -eq 0 ]]; then
  echo "kb-citation-lint: no markdown found under ${ROOT} at depth ${DEPTH} -- refusing to report clean." >&2
  echo "  A scan that opened nothing cannot be distinguished from one that found nothing." >&2
  echo "  Check the path, or widen with --depth all." >&2
  exit 2
fi

violations="$(
    awk '
      {
        line = $0
        while (match(line, /[A-Za-z0-9_.\/-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1):[0-9]+([,-][0-9]+)*/)) {
          m  = substr(line, RSTART, RLENGTH)               # e.g. installer-tests.yml:106-125
          a2 = substr(line, RSTART + RLENGTH, 2)           # the 2 chars right after the linespec
          a1 = substr(a2, 1, 1)
          bad = 0
          if (a1 ~ /[A-Za-z]/)        bad = 1              # letter   -> durable anchor
          else if (a2 ~ /^\.[0-9]/)   bad = 1              # .digit   -> IP / version
          else if (a2 ~ /^-[A-Za-z]/) bad = 1              # -letter  -> durable anchor
          if (!bad) printf "%s:%d: %s\n", FILENAME, FNR, m
          line = substr(line, RSTART + RLENGTH)            # advance past this match on the line
        }
      }
    ' "${docs[@]}"
  )"

if [[ -n "$violations" ]]; then
  echo "kb-citation-lint: VOLATILE bare line citations found -- use durable file:symbol anchors:" >&2
  printf '%s\n' "$violations" >&2
  n="$(printf '%s\n' "$violations" | grep -c .)"
  echo "kb-citation-lint: ${n} violation(s)." >&2
  exit 1
fi

echo "kb-citation-lint: clean (no bare line citations under ${ROOT})."
exit 0
