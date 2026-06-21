#!/usr/bin/env bash
# test-assemble-3part-ps1.sh — tests for the PowerShell mirror
# canonical/scripts/summarize/assemble-3part.ps1, which byte-concatenates
# Part1 + Mermaid + Part2 into Output (creating Output's dir if needed).
#
# This suite is a thin bash wrapper (like the .mjs suites): it invokes `pwsh`
# as the SUT and asserts via tests/lib/assert.sh. assemble-3part.ps1 is
# cross-platform (explicit paths + byte I/O), so it runs fully under pwsh on the
# Linux CI runner. Skips (exit 0) when pwsh is not on PATH.
#
# Usage:
#   bash test-assemble-3part-ps1.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/summarize/assemble-3part.ps1"

[[ -f "$SUT" ]] || { echo "ERROR: assemble-3part.ps1 not found at $SUT" >&2; exit 1; }

if ! command -v pwsh >/dev/null 2>&1; then
    echo "SKIP: pwsh not found on PATH — skipping assemble-3part.ps1 suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# run -Part1 a -Mermaid b -Part2 c -Output d  → captures OUT, RC
run() { OUT=$(pwsh -NoProfile -NonInteractive -File "$SUT" "$@" 2>&1); RC=$?; }

# --- Fixtures ---------------------------------------------------------------
P1="$TMP/part1.html";  printf '<html><body>\n' > "$P1"
MID="$TMP/mermaid.js"; printf 'MERMAIDLIB' > "$MID"
P2="$TMP/part2.html";  printf '\n</body></html>\n' > "$P2"
EMPTY="$TMP/empty";    : > "$EMPTY"

# --- Input validation -------------------------------------------------------
run -Part1 "$TMP/nope.html" -Mermaid "$MID" -Part2 "$P2" -Output "$TMP/out1.html"
assert_exit_eq "$RC" 1 "APS01 missing input file → exit 1"
assert_output_contains "$OUT" "Missing input:" "APS01b 'Missing input' message"

run -Part1 "$P1" -Mermaid "$EMPTY" -Part2 "$P2" -Output "$TMP/out2.html"
assert_exit_eq "$RC" 1 "APS02 empty input file → exit 1"
assert_output_contains "$OUT" "Empty input:" "APS02b 'Empty input' message"

# --- Happy path -------------------------------------------------------------
OUTFILE="$TMP/sub/dir/summary.html"   # nested dir does not exist yet
run -Part1 "$P1" -Mermaid "$MID" -Part2 "$P2" -Output "$OUTFILE"
assert_exit_eq "$RC" 0 "APS03 valid inputs → exit 0"
assert_output_contains "$OUT" "Wrote" "APS03b reports the written file"
assert_file_exists "$OUTFILE" "APS03c output file created"
assert_dir_exists "$TMP/sub/dir" "APS03d output dir auto-created"

# Byte-exact concatenation in order Part1 + Mermaid + Part2 (matches the .sh oracle)
REF="$TMP/ref.html"; cat "$P1" "$MID" "$P2" > "$REF"
assert_eq "$(cmp -s "$OUTFILE" "$REF" && echo same || echo diff)" "same" \
    "APS04 output is byte-exact Part1+Mermaid+Part2"
assert_file_contains "$OUTFILE" "MERMAIDLIB" "APS05 middle part present in output"

test_summary
