#!/usr/bin/env bash
# test-assemble-3part.sh — tests for canonical/scripts/summarize/assemble-3part.sh,
# which assembles the final knowledge-summary.html by byte-concatenating
# PART1 + MERMAID + PART2 into OUTPUT (creating OUTPUT's dir if needed).
#
# Usage:
#   bash test-assemble-3part.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/scripts/summarize/assemble-3part.sh"

[[ -f "$SUT" ]] || { echo "ERROR: assemble-3part.sh not found at $SUT" >&2; exit 1; }
[[ -x "$SUT" ]] || chmod +x "$SUT"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run() { OUT=$(bash "$SUT" "$@" 2>&1); RC=$?; }

# --- Fixtures ---------------------------------------------------------------
P1="$TMP/part1.html";  printf '<html><body>\n' > "$P1"
MID="$TMP/mermaid.js"; printf 'MERMAIDLIB' > "$MID"
P2="$TMP/part2.html";  printf '\n</body></html>\n' > "$P2"
EMPTY="$TMP/empty";    : > "$EMPTY"

# --- Argument / input validation -------------------------------------------
run
assert_exit_nonzero "$RC" "AS01 no args → non-zero exit"

run "$P1" "$MID" "$P2"     # only 3 of 4 required args
assert_exit_nonzero "$RC" "AS02 too few args → non-zero exit"

run "$TMP/nope.html" "$MID" "$P2" "$TMP/out1.html"
assert_exit_eq "$RC" 1 "AS03 missing input file → exit 1"
assert_output_contains "$OUT" "Missing input:" "AS03b 'Missing input' message"

run "$P1" "$EMPTY" "$P2" "$TMP/out2.html"
assert_exit_eq "$RC" 1 "AS04 empty input file → exit 1"
assert_output_contains "$OUT" "Empty input:" "AS04b 'Empty input' message"

# --- Happy path -------------------------------------------------------------
OUTFILE="$TMP/sub/dir/summary.html"   # nested dir does not exist yet
run "$P1" "$MID" "$P2" "$OUTFILE"
assert_exit_eq "$RC" 0 "AS05 valid inputs → exit 0"
assert_output_contains "$OUT" "Wrote" "AS05b reports the written file"
assert_file_exists "$OUTFILE" "AS05c output file created"
assert_dir_exists "$TMP/sub/dir" "AS05d output dir auto-created (mkdir -p)"

# Byte-exact concatenation in order PART1 + MERMAID + PART2
REF="$TMP/ref.html"; cat "$P1" "$MID" "$P2" > "$REF"
assert_eq "$(cmp -s "$OUTFILE" "$REF" && echo same || echo diff)" "same" \
    "AS06 output is byte-exact PART1+MERMAID+PART2"
assert_file_contains "$OUTFILE" "MERMAIDLIB" "AS07 middle part present in output"

# Order matters: the mermaid lib sits between the two HTML parts.
mid_before_close=$(grep -aob 'MERMAIDLIB' "$OUTFILE" | cut -d: -f1)
close_pos=$(grep -aob '</body>' "$OUTFILE" | cut -d: -f1)
assert_eq "$([[ -n "$mid_before_close" && -n "$close_pos" && "$mid_before_close" -lt "$close_pos" ]] && echo ok || echo bad)" \
    "ok" "AS08 PART1 < MERMAID < PART2 ordering preserved"

test_summary
