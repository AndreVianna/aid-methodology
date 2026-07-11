#!/usr/bin/env bash
# test-shortcut-engine-contract.sh -- fixture-INDEPENDENT contract assertions for the
# shortcut engine's GATE / APPROVAL-HALT / batching prose.
#
# Re-homed from test-shortcut-gate-halt-batching.sh (its SGH01-07 "Part 1" block), which
# was scoped to the now-removed work-001-lite-aid-skills / feature-004 fixture and is
# therefore skipped when that fixture is absent. These assertions validate only the LIVE
# canonical shortcut-engine.md -- no removed-work fixture -- so they run everywhere.
#
# Assertions grep the FILE directly (assert_file_contains) rather than piping the whole
# file through `echo "$var" | grep`, for portability across shells/runners.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="${REPO_ROOT}/canonical/aid/templates/shortcut-engine.md"

echo "=== Shortcut engine contract (GATE / halt / batching prose) ==="
assert_file_exists "$ENGINE" "SEC00 shortcut-engine.md exists"

# SEC01: minimum_grade resolves via read-setting.sh, shortcut floor default A+.
assert_file_contains "$ENGINE" \
    "read-setting.sh --skill {name} --key minimum_grade --default A+" \
    "SEC01 GATE resolves minimum_grade via read-setting.sh (shortcut floor default A+)"

# SEC02: the two named ledger scopes.
assert_file_contains "$ENGINE" '.aid/.temp/review-pending/shortcut-{work}-defn.md' \
    "SEC02a Pass 1 ledger scope shortcut-{work}-defn.md named"
assert_file_contains "$ENGINE" '.aid/.temp/review-pending/shortcut-{work}-tasks.md' \
    "SEC02b Pass 2 ledger scope shortcut-{work}-tasks.md named"

# SEC03: grade.sh drives the computation.
assert_file_contains "$ENGINE" "grade.sh --explain <ledger-path>" \
    "SEC03 GATE drives grade.sh --explain over the ledger"

# SEC04: the REVIEW -> GRADE -> FIX loop + 3-cycle circuit breaker.
assert_file_contains "$ENGINE" "The Generic REVIEW -> GRADE -> FIX loop" \
    "SEC04a engine documents the Generic REVIEW -> GRADE -> FIX loop"
assert_file_contains "$ENGINE" "Circuit breaker" \
    "SEC04b1 loop names a Circuit breaker"
assert_file_contains "$ENGINE" "has not improved across 3" \
    "SEC04b2 circuit breaker keys off 3 cycles without improvement"
assert_file_contains "$ENGINE" "consecutive cycles, STOP" \
    "SEC04b3 circuit breaker STOPs after 3 consecutive non-improving cycles"

# SEC05: halt proof -- no branch, no execution, Paused-Awaiting-Input, Specified.
assert_file_contains "$ENGINE" "no branch is created, no task executes" \
    "SEC05a APPROVAL-HALT: no branch is created, no task executes"
assert_file_contains "$ENGINE" \
    'writeback-state.sh --pipeline --field Lifecycle --value Paused-Awaiting-Input' \
    "SEC05c APPROVAL-HALT sets Pipeline Lifecycle: Paused-Awaiting-Input"
assert_file_contains "$ENGINE" 'is already `Specified`' \
    "SEC05d APPROVAL-HALT leaves Delivery Lifecycle State at Specified (not Executing)"

# SEC06: batching -- exactly two batched Grading-Gate passes.
assert_file_contains "$ENGINE" "two batched Grading-Gate passes" \
    "SEC06a engine documents exactly two batched Grading-Gate passes"

# SEC07: ledger-scope count in the engine prose is exactly 2, distinct (defn, tasks) --
# a mechanical cross-check that the prose never grows a third/per-document scope pattern.
LEDGER_SCOPES=$(grep -oE '\.aid/\.temp/review-pending/shortcut-\{work\}-[a-z]+\.md' "$ENGINE" | sort -u)
LEDGER_SCOPE_COUNT=$(printf '%s\n' "$LEDGER_SCOPES" | grep -c . || true)
assert_eq "$LEDGER_SCOPE_COUNT" "2" \
    "SEC07 exactly two distinct ledger-scope patterns named in the engine prose"

test_summary
