#!/usr/bin/env bash
# test-closure-batching.sh -- large-universe regression guard for the batched
# closure-check.sh presence scan (work-009 / v2.0.3).
#
# closure-check.sh used to scan the doc/source set with a per-(term x doc x source)
# `grep -qiF` loop -- tens of thousands of fork()/exec calls on a ~500-term universe,
# which timed out (>3 min) on Windows Git Bash / MSYS. It now builds a term->file
# presence map in a single awk pass and derives outputs (a)/(b) from it, also in awk.
#
# This suite pins the regression with a LARGE-universe fixture (~500 terms, several KB
# docs, resolving sources):
#   T01  completes without hanging (internal timeout) and exits 0.
#   T02  output (a) reports a planted ungrounded term and NOT a grounded (spine-defined)
#        one -- the closure loop's termination oracle stays correct.
#   T03  output (b) has BOTH present and absent rows -- the source-scan path is exercised
#        (not just the N/A branch).
#   T04  determinism: two runs are byte-identical (the header promises CI-reproducible
#        byte-identical re-runs).
#
# Byte-identity to the pre-change script is separately verified (and was, manually, on
# the kb-essence closed-kb/unclosed-kb fixtures, which exercise output (a) anchors +
# output (b) present/absent/N/A). Here the point is scale + no-hang + correctness.
#
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob).
#
# Usage: bash tests/canonical/test-closure-batching.sh [--verbose]
# Exit: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/closure-check.sh"
DENYLIST="${REPO}/canonical/aid/scripts/kb/coined-term-denylist.txt"
FX="${SCRIPT_DIR}/fixtures/closure-batching"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-closure-batching.sh =="

for req in "$SUT" "$DENYLIST"; do
  [[ -e "$req" ]] || { echo "FATAL: missing $req" >&2; exit 2; }
done
[[ -f "$FX/generated/candidate-concepts.md" ]] || { echo "FATAL: fixture missing at $FX" >&2; exit 2; }

TMP="$(mktemp -d)"
FAKE_HOME="${TMP}/fh"; mkdir -p "$FAKE_HOME"
trap 'rm -rf "$TMP"' EXIT

# Sanity: the fixture universe really is large (guards a silently-shrunk fixture).
uni="$(grep -cE '^\| [0-9]+ \| harvest \|' "$FX/generated/candidate-concepts.md" 2>/dev/null || echo 0)"
if [[ "$uni" -ge 400 ]]; then
  pass "T00 fixture universe is large (${uni} terms)"
else
  fail "T00 fixture universe too small (${uni} terms) -- regression would not be caught"
fi

run_closure() {  # <out-a> <out-b>
  HOME="$FAKE_HOME" bash "$SUT" --root "$FX" \
    --concepts "$FX/generated/candidate-concepts.md" \
    --spine "$FX/knowledge/domain-glossary.md" \
    --kb-dir "$FX/knowledge" --denylist "$DENYLIST" \
    --output-a "$1" --output-b "$2" 2>/dev/null
}

# --- T01: completes without hanging (internal timeout) ---
OUTA="${TMP}/a.md"; OUTB="${TMP}/b.md"
RC=0
timeout 150 bash -c '
  HOME="$1" bash "$2" --root "$3" --concepts "$3/generated/candidate-concepts.md" \
    --spine "$3/knowledge/domain-glossary.md" --kb-dir "$3/knowledge" \
    --denylist "$4" --output-a "$5" --output-b "$6" 2>/dev/null
' _ "$FAKE_HOME" "$SUT" "$FX" "$DENYLIST" "$OUTA" "$OUTB" || RC=$?
if [[ "$RC" -eq 124 ]]; then
  fail "T01 closure-check HUNG on the large-universe fixture (>150s -- spawn-storm regression)"
  # A hang is the definitive failure this fixture guards against. Do NOT fall
  # through: T02/T03 would assert on partial output, and T04 re-runs
  # closure-check via run_closure WITHOUT a timeout -- on a genuine hang that
  # would wedge the whole CI job instead of failing fast. Report and stop now.
  test_summary
  exit 1
else
  assert_exit_zero "$RC" "T01 closure-check completes on the large-universe fixture (no hang)"
fi

# --- T02: output (a) correctness (termination oracle) ---
# Spine defines "Widget Engine"; "ghost token" is used in a doc but undefined.
assert_file_contains "$OUTA" "ghost token" \
  "T02a output (a) reports the planted ungrounded term 'ghost token'"
if grep -qE '^\| widget engine \|' "$OUTA" 2>/dev/null; then
  fail "T02b output (a) wrongly reports 'widget engine' (it is defined in the spine -> grounded)"
else
  pass "T02b output (a) does NOT report the grounded term 'widget engine'"
fi

# --- T03: output (b) exercises the source-scan path (present AND absent) ---
present_n="$(grep -c '| present |' "$OUTB" 2>/dev/null || echo 0)"
absent_n="$(grep -c '| absent |' "$OUTB" 2>/dev/null || echo 0)"
if [[ "$present_n" -ge 1 ]]; then pass "T03a output (b) has present rows (${present_n})"; else fail "T03a output (b) has no present rows"; fi
if [[ "$absent_n" -ge 1 ]]; then pass "T03b output (b) has absent rows (${absent_n})"; else fail "T03b output (b) has no absent rows"; fi

# --- T04: determinism (byte-identical re-run) ---
OUTA2="${TMP}/a2.md"; OUTB2="${TMP}/b2.md"
run_closure "$OUTA2" "$OUTB2"
if diff "$OUTA" "$OUTA2" >/dev/null 2>&1 && diff "$OUTB" "$OUTB2" >/dev/null 2>&1; then
  pass "T04 closure-check output is byte-identical on re-run (determinism)"
else
  fail "T04 closure-check output differs between runs (non-determinism)"
  [[ "$VERBOSE" -eq 1 ]] && { diff "$OUTA" "$OUTA2"; diff "$OUTB" "$OUTB2"; } || true
fi

test_summary
exit $?