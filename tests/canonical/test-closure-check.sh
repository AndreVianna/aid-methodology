#!/usr/bin/env bash
# test-closure-check.sh -- Canonical tests for closure-check.sh (2-output coverage oracle).
#
# Tests cover the acceptance criteria from feature-004 / task-009 that survive the
# delivery-009 panel simplification (output (c) transcription-ratio was retired --
# transcription is now an M2 Anatomy reviewer judgment, not a mechanical ratio):
#   C01-C02  Output (a) termination: a planted used-but-undefined term is reported; a fully
#            closed fixture reports empty output (a).
#   C03-C05  Output (b) sources:-anchored coverage: a candidate present in a doc whose
#            local-file sources: contains it emits present; a candidate absent emits absent;
#            a doc whose only sources: is a URL yields anchoring-source = N/A (no absent).
#   C08      Determinism: a re-run is byte-identical across both outputs (NFR-3).
#
# (Former C06-C07 asserted output (c)'s transcription ratio; removed with output (c).)
#
# Fixtures live under tests/canonical/fixtures/closure-check/ (main fixture) and
# tests/canonical/fixtures/closure-check/closed/ (the fully-closed sub-fixture for C02).
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# Pattern mirrors test-harvest-coined-terms.sh: numbered C01.. assertions, set -u, sourced assert.sh.
#
# Usage:
#   bash tests/canonical/test-closure-check.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/closure-check.sh"
DENYLIST="${REPO}/canonical/aid/scripts/kb/coined-term-denylist.txt"

# Main fixture (ungrounded terms, mixed local-file + URL sources, near-verbatim doc)
FIXTURE_MAIN="${SCRIPT_DIR}/fixtures/closure-check"
CONCEPTS_MAIN="${FIXTURE_MAIN}/candidate-concepts.md"
SPINE_MAIN="${FIXTURE_MAIN}/kb/domain-glossary.md"
KB_DIR_MAIN="${FIXTURE_MAIN}/kb"

# Closed sub-fixture (all candidate terms defined in the spine -> output (a) empty)
FIXTURE_CLOSED="${FIXTURE_MAIN}/closed"
CONCEPTS_CLOSED="${FIXTURE_CLOSED}/candidate-concepts.md"
SPINE_CLOSED="${FIXTURE_CLOSED}/kb/domain-glossary.md"
KB_DIR_CLOSED="${FIXTURE_CLOSED}/kb"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-closure-check.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT + fixtures must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: closure-check.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "$DENYLIST" ]]; then
  echo "FATAL: coined-term-denylist.txt not found at $DENYLIST" >&2
  exit 2
fi
if [[ ! -f "$CONCEPTS_MAIN" ]]; then
  echo "FATAL: main fixture candidate-concepts.md not found at $CONCEPTS_MAIN" >&2
  exit 2
fi
if [[ ! -f "$SPINE_MAIN" ]]; then
  echo "FATAL: main fixture spine not found at $SPINE_MAIN" >&2
  exit 2
fi
if [[ ! -d "$KB_DIR_MAIN" ]]; then
  echo "FATAL: main fixture kb/ not found at $KB_DIR_MAIN" >&2
  exit 2
fi
if [[ ! -f "$CONCEPTS_CLOSED" ]]; then
  echo "FATAL: closed fixture candidate-concepts.md not found at $CONCEPTS_CLOSED" >&2
  exit 2
fi
if [[ ! -f "$SPINE_CLOSED" ]]; then
  echo "FATAL: closed fixture spine not found at $SPINE_CLOSED" >&2
  exit 2
fi
if [[ ! -d "$KB_DIR_CLOSED" ]]; then
  echo "FATAL: closed fixture kb/ not found at $KB_DIR_CLOSED" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Temporary scratch area (cleaned up on exit)
# ---------------------------------------------------------------------------
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# ---------------------------------------------------------------------------
# Helper: run closure-check on the MAIN fixture, writing individual output files.
# Pins HOME to a throwaway dir to prevent .coined-term-denylist.local.txt leakage.
# Usage: run_main <suffix>
# Sets:  OUT_A, OUT_B (absolute paths to the two output files)
# ---------------------------------------------------------------------------
run_main() {
  local suffix="${1:-}"
  OUT_A="${TMPDIR_TEST}/out_a${suffix}.md"
  OUT_B="${TMPDIR_TEST}/out_b${suffix}.md"
  HOME=$(mktemp -d) bash "$SUT" \
    --root "$REPO" \
    --concepts "$CONCEPTS_MAIN" \
    --spine "$SPINE_MAIN" \
    --kb-dir "$KB_DIR_MAIN" \
    --denylist "$DENYLIST" \
    --output-a "$OUT_A" \
    --output-b "$OUT_B" \
    2>/dev/null
}

# ---------------------------------------------------------------------------
# Helper: run closure-check on the CLOSED fixture, writing to output files.
# ---------------------------------------------------------------------------
run_closed() {
  local suffix="${1:-}"
  OUT_A="${TMPDIR_TEST}/closed_a${suffix}.md"
  OUT_B="${TMPDIR_TEST}/closed_b${suffix}.md"
  HOME=$(mktemp -d) bash "$SUT" \
    --root "$REPO" \
    --concepts "$CONCEPTS_CLOSED" \
    --spine "$SPINE_CLOSED" \
    --kb-dir "$KB_DIR_CLOSED" \
    --denylist "$DENYLIST" \
    --output-a "$OUT_A" \
    --output-b "$OUT_B" \
    2>/dev/null
}

# ---------------------------------------------------------------------------
# Run the oracle on both fixtures once (used by C01-C07).
# C08 runs independently to get two byte-comparable outputs.
# ---------------------------------------------------------------------------
run_main "_r1"
MAIN_A="${TMPDIR_TEST}/out_a_r1.md"
MAIN_B="${TMPDIR_TEST}/out_b_r1.md"

run_closed "_r1"
CLOSED_A="${TMPDIR_TEST}/closed_a_r1.md"

# ============================================================
# C01: Output (a) -- planted used-but-undefined term is reported
#
# The main fixture has "Relative Bus" used in KB docs (architecture.md,
# external-only.md, domain-glossary.md) but NOT defined as a concept
# entry in the spine.  Output (a) must report it as ungrounded.
# ============================================================
log "C01: output (a) contains a row for 'relative bus' (ungrounded)"
assert_file_contains "$MAIN_A" "relative bus" \
  "C01 output (a) reports planted used-but-undefined term 'relative bus'"

# ============================================================
# C02: Output (a) -- fully closed fixture yields no data rows (empty set)
#
# The closed fixture defines every candidate term in the spine.
# After the header and table-header rows there must be no data rows --
# i.e. no pipe-separated data rows below the separator line.
# ============================================================
log "C02: closed fixture output (a) has no data rows"
# The table has 2 header rows (column names + separator): we want total pipe rows == 2
# i.e. data rows = total_pipe_rows - 2 = 0
total_pipe_rows=$(grep -cE '^\|' "$CLOSED_A" 2>/dev/null || true)
data_rows=$((total_pipe_rows - 2))
if [[ "$data_rows" -le 0 ]]; then
  pass "C02 closed fixture output (a) is empty (no ungrounded terms)"
else
  fail "C02 closed fixture output (a) -- expected 0 data rows, got $data_rows"
  [[ "$VERBOSE" -eq 1 ]] && cat "$CLOSED_A"
fi

# ============================================================
# C03: Output (b) -- candidate PRESENT in doc + local-file sources: emits 'present'
#
# architecture.md has sources: [local-source.md] which contains "SpineAnchor".
# architecture.md body also mentions "SpineAnchor".
# => spineanchor row for architecture.md must be 'present'.
# ============================================================
log "C03: output (b) emits 'present' for spineanchor in architecture.md"
# The row format is: | spineanchor | architecture.md | <src> | present |
assert_file_contains "$MAIN_B" "spineanchor" \
  "C03 output (b) has a row for spineanchor"
# Verify the row for (spineanchor, architecture.md) says 'present'
spineanchor_arch_row=$(grep -iF "spineanchor" "$MAIN_B" | grep "architecture.md" | grep -v "^#" || true)
if echo "$spineanchor_arch_row" | grep -qF "present"; then
  pass "C03 output (b) row for (spineanchor, architecture.md) is 'present'"
else
  fail "C03 output (b) row for (spineanchor, architecture.md) -- expected 'present', got: $spineanchor_arch_row"
fi

# ============================================================
# C04: Output (b) -- candidate ABSENT from doc (anchored via local-file sources:) emits 'absent'
#
# architecture.md has sources: [local-source.md].  The term
# 'eventual-consistency contract' does NOT appear in architecture.md body
# nor in local-source.md => the row must say 'absent' (the coverage gap finding).
# ============================================================
log "C04: output (b) emits 'absent' for eventual-consistency contract in architecture.md"
absent_row=$(grep -iF "eventual-consistency contract" "$MAIN_B" | grep "architecture.md" | grep -v "^#" || true)
if echo "$absent_row" | grep -qF "absent"; then
  pass "C04 output (b) row for (eventual-consistency contract, architecture.md) is 'absent'"
else
  fail "C04 output (b) row for (eventual-consistency contract, architecture.md) -- expected 'absent', got: $absent_row"
fi

# ============================================================
# C05: Output (b) -- doc with URL-only sources: yields anchoring-source = N/A
#      and NO 'absent' finding (URL scoping).
#
# external-only.md has sources: [https://example.com/external-spec.html] only.
# => all rows for external-only.md must have 'N/A' in the anchoring-source column
#    and must NOT emit an 'absent' row.
# ============================================================
log "C05: output (b) URL-only sources: yields N/A anchoring-source (no absent finding)"
# All external-only rows must contain N/A
external_rows=$(grep -F "external-only.md" "$MAIN_B" | grep -v "^#" || true)
if [[ -z "$external_rows" ]]; then
  # No rows at all for external-only.md -- also valid (URL sources produce N/A rows or are skipped)
  pass "C05 output (b) external-only.md produces no absent finding (no rows)"
else
  # Verify no 'absent' finding and anchoring-source is N/A
  if echo "$external_rows" | grep -qF "absent"; then
    fail "C05 output (b) external-only.md -- unexpected 'absent' finding for URL-only source"
  else
    pass "C05 output (b) external-only.md has no 'absent' finding"
  fi
  if echo "$external_rows" | grep -qF "N/A"; then
    pass "C05 output (b) external-only.md rows show anchoring-source = N/A"
  else
    fail "C05 output (b) external-only.md rows -- expected N/A, got: $external_rows"
  fi
fi

# ============================================================
# C08: Determinism -- a re-run is byte-identical across both outputs (NFR-3)
#
# Run the oracle a second time and compare the two output files byte-for-byte.
# URL sources: resolve to N/A, never fetched, so both outputs are deterministic.
# ============================================================
log "C08: re-run produces byte-identical outputs (a), (b)"

run_main "_r2"
MAIN_A2="${TMPDIR_TEST}/out_a_r2.md"
MAIN_B2="${TMPDIR_TEST}/out_b_r2.md"

if diff -q "$MAIN_A" "$MAIN_A2" >/dev/null 2>&1; then
  pass "C08 output (a) is byte-identical on re-run"
else
  fail "C08 output (a) differs between runs"
  [[ "$VERBOSE" -eq 1 ]] && diff "$MAIN_A" "$MAIN_A2"
fi

if diff -q "$MAIN_B" "$MAIN_B2" >/dev/null 2>&1; then
  pass "C08 output (b) is byte-identical on re-run"
else
  fail "C08 output (b) differs between runs"
  [[ "$VERBOSE" -eq 1 ]] && diff "$MAIN_B" "$MAIN_B2"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
