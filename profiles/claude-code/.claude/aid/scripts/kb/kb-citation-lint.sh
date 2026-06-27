#!/usr/bin/env bash
# kb-citation-lint.sh -- flag VOLATILE bare line-number citations in KB docs.
#
# The KB authoring standard (kb-authoring principles.md P1d) requires DURABLE anchors: a file
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
# Usage:  kb-citation-lint.sh [--root .aid/knowledge]
# Exit:   0 = clean, 1 = violations found, 2 = usage/error.

set -uo pipefail

ROOT=".aid/knowledge"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "kb-citation-lint.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$ROOT" ]] || { echo "kb-citation-lint.sh: not a directory: $ROOT" >&2; exit 2; }

violations="$(
  find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' 2>/dev/null | sort | while IFS= read -r f; do
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
    ' "$f"
  done
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
