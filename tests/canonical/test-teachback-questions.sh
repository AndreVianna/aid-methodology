#!/usr/bin/env bash
# test-teachback-questions.sh -- Canonical tests for kb-teachback-questions.sh.
#
# Tests (TB01-TB08) cover all acceptance criteria from feature-005 / task-012:
#   TB01  Cross-source terms (spread>=2) are selected.
#   TB02  Spread==1 terms are excluded (neither in top-N nor synthesis).
#   TB03  Synthesis-tagged concepts are included regardless of empty Spread
#         (the load-bearing OR clause -- the primary guard against dropping
#         tokenless concepts).
#   TB04  Spread>=2 AND synthesis coexist: both selection clauses work together.
#   TB05  Fixed engine question is always emitted (even with zero emitted rows).
#   TB06  Fixed engine question is the last line (output ordering).
#   TB07  Output is byte-identical on re-run (NFR-3 determinism).
#   TB08  Missing concepts file exits non-zero with a diagnostic.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# Pattern mirrors test-harvest-coined-terms.sh: numbered TB01.. assertions,
# set -u, sourced assert.sh.
#
# Usage:
#   bash tests/canonical/test-teachback-questions.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/kb-teachback-questions.sh"
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/teachback-questions"

MIXED_FIXTURE="${FIXTURES_BASE}/candidate-concepts-mixed.md"
SYNTHESIS_ONLY_FIXTURE="${FIXTURES_BASE}/candidate-concepts-synthesis-only.md"
EMPTY_FIXTURE="${FIXTURES_BASE}/candidate-concepts-empty.md"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-teachback-questions.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT and fixtures must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: kb-teachback-questions.sh not found at $SUT" >&2
  exit 2
fi

for fix in "$MIXED_FIXTURE" "$SYNTHESIS_ONLY_FIXTURE" "$EMPTY_FIXTURE"; do
  if [[ ! -f "$fix" ]]; then
    echo "FATAL: fixture not found: $fix" >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# Helper: run the SUT against a concepts file; return the output via temp file path.
# ---------------------------------------------------------------------------
run_sut() {
  local concepts="$1"
  local out
  out=$(mktemp)
  bash "$SUT" --concepts "$concepts" > "$out" 2>/dev/null
  echo "$out"
}

TMPDIR_CLEANUP=$(mktemp -d)
trap 'rm -rf "$TMPDIR_CLEANUP"' EXIT

# ---------------------------------------------------------------------------
# TB01: Cross-source terms (spread>=2) are selected.
#
# The mixed fixture has:
#   RelativeBus  spread=4  -> selected
#   QuorumPulse  spread=3  -> selected
#   CrunchFactor spread=2  -> selected
# All three must appear in the output.
# ---------------------------------------------------------------------------
OUT_TB01=$(run_sut "$MIXED_FIXTURE")
output_TB01=$(cat "$OUT_TB01")

assert_output_contains "$output_TB01" "What is RelativeBus?" \
  "TB01a spread=4 term RelativeBus is selected (What is RelativeBus?)"

assert_output_contains "$output_TB01" "What is QuorumPulse?" \
  "TB01b spread=3 term QuorumPulse is selected (What is QuorumPulse?)"

assert_output_contains "$output_TB01" "What is CrunchFactor?" \
  "TB01c spread=2 term CrunchFactor is selected (What is CrunchFactor?)"

rm -f "$OUT_TB01"

# ---------------------------------------------------------------------------
# TB02: Spread==1 terms are excluded.
#
# The mixed fixture has FluxMatrix spread=1, Source=harvest -> must NOT appear.
# ---------------------------------------------------------------------------
OUT_TB02=$(run_sut "$MIXED_FIXTURE")
output_TB02=$(cat "$OUT_TB02")

assert_output_not_contains "$output_TB02" "FluxMatrix" \
  "TB02 spread=1 harvest term FluxMatrix is excluded"

rm -f "$OUT_TB02"

# ---------------------------------------------------------------------------
# TB03: Synthesis-tagged concepts are included regardless of empty Spread.
#
# This is the load-bearing OR clause test: the synthesis-only fixture has:
#   SingleSource  spread=1, harvest  -> excluded
#   Invisible Concept  synthesis, empty spread  -> MUST be included
#
# A bare spread>=2 filter would drop Invisible Concept entirely.
# ---------------------------------------------------------------------------
OUT_TB03=$(run_sut "$SYNTHESIS_ONLY_FIXTURE")
output_TB03=$(cat "$OUT_TB03")

assert_output_contains "$output_TB03" "What is Invisible Concept?" \
  "TB03a synthesis concept (empty Spread) is included via OR clause"

assert_output_not_contains "$output_TB03" "SingleSource" \
  "TB03b spread=1 harvest term SingleSource is excluded from synthesis-only fixture"

rm -f "$OUT_TB03"

# ---------------------------------------------------------------------------
# TB04: Both selection clauses coexist in the mixed fixture.
#
# The mixed fixture has both spread>=2 harvest rows AND synthesis rows.
# Verify synthesis concepts appear alongside cross-source terms.
# ---------------------------------------------------------------------------
OUT_TB04=$(run_sut "$MIXED_FIXTURE")
output_TB04=$(cat "$OUT_TB04")

# Synthesis rows from the mixed fixture
assert_output_contains "$output_TB04" "What is Relative Bus?" \
  "TB04a synthesis concept 'Relative Bus' appears in mixed fixture output"

assert_output_contains "$output_TB04" "What is Scheduling Engine?" \
  "TB04b synthesis concept 'Scheduling Engine' appears in mixed fixture output"

# Cross-source rows also present (spread>=2)
assert_output_contains "$output_TB04" "What is CrunchFactor?" \
  "TB04c spread>=2 harvest term CrunchFactor also present alongside synthesis terms"

rm -f "$OUT_TB04"

# ---------------------------------------------------------------------------
# TB05: Fixed engine question is always emitted.
#
# Even with zero qualifying terms (empty fixture -> no data rows),
# the engine question must appear.
# ---------------------------------------------------------------------------
OUT_TB05=$(run_sut "$EMPTY_FIXTURE")
output_TB05=$(cat "$OUT_TB05")

assert_output_contains "$output_TB05" "Explain how this system works, in its own language." \
  "TB05 fixed engine question emitted even with no qualifying term rows"

rm -f "$OUT_TB05"

# ---------------------------------------------------------------------------
# TB06: Fixed engine question is the last line.
#
# The engine question must be the final line of the output.
# ---------------------------------------------------------------------------
OUT_TB06=$(run_sut "$MIXED_FIXTURE")

last_line=$(tail -1 "$OUT_TB06")
if [[ "$last_line" == "Explain how this system works, in its own language." ]]; then
  pass "TB06 fixed engine question is the last line of output"
else
  fail "TB06 fixed engine question is not the last line -- got: '$last_line'"
fi

rm -f "$OUT_TB06"

# ---------------------------------------------------------------------------
# TB07: Output is byte-identical on re-run (NFR-3 determinism).
# ---------------------------------------------------------------------------
OUT_TB07A=$(run_sut "$MIXED_FIXTURE")
OUT_TB07B=$(run_sut "$MIXED_FIXTURE")

if diff "$OUT_TB07A" "$OUT_TB07B" > /dev/null 2>&1; then
  pass "TB07 output is byte-identical on re-run (determinism)"
else
  fail "TB07 output differs between runs (determinism violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    diff "$OUT_TB07A" "$OUT_TB07B" || true
  fi
fi

rm -f "$OUT_TB07A" "$OUT_TB07B"

# ---------------------------------------------------------------------------
# TB08: Missing concepts file exits non-zero with a diagnostic.
# ---------------------------------------------------------------------------
EXIT_TB08=0
bash "$SUT" --concepts "/nonexistent/path/candidate-concepts.md" > /dev/null 2>&1 || EXIT_TB08=$?
assert_exit_nonzero "$EXIT_TB08" "TB08 missing concepts file exits non-zero"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
