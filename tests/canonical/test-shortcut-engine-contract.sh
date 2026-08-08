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

# SEC03/SEC04: grade.sh drives the computation, inside a REVIEW -> GRADE -> FIX loop with a 3-cycle
# circuit breaker.
#
# These used to be asserted as literal strings in the engine. The review extraction moved the loop OUT
# of the engine and into `/aid-deep-review`, so the engine no longer spells it -- it delegates. The
# contract still has to hold, but it is now satisfied TRANSITIVELY: the engine must delegate, and the
# delegate must carry the loop. Asserting the old literals in the engine would demand the engine keep a
# copy of exactly what the extraction removed, which is the duplication the extraction existed to end.
#
# Same shape as the gap-gate suite, where a caller satisfies the gate either directly or by delegating.
DEEP="${REPO_ROOT}/canonical/skills/aid-deep-review/SKILL.md"

if grep -q 'grade.sh --explain <ledger-path>' "$ENGINE" 2>/dev/null; then
    assert_file_contains "$ENGINE" "grade.sh --explain <ledger-path>" \
        "SEC03 GATE drives grade.sh --explain over the ledger (inline)"
else
    assert_file_contains "$ENGINE" "/aid-deep-review" \
        "SEC03a engine delegates the gate to /aid-deep-review"
    assert_file_contains "$DEEP" "grade.sh --explain" \
        "SEC03b the delegate drives grade.sh --explain"
fi

if grep -q 'The Generic REVIEW -> GRADE -> FIX loop' "$ENGINE" 2>/dev/null; then
    assert_file_contains "$ENGINE" "Circuit breaker" \
        "SEC04 engine documents the loop and its circuit breaker (inline)"
else
    assert_file_contains "$ENGINE" "REVIEW -> GRADE -> FIX" \
        "SEC04a engine still names the REVIEW -> GRADE -> FIX loop it delegates"
    assert_file_contains "$DEEP" "Circuit breaker" \
        "SEC04b the delegate names a Circuit breaker"
    # ASSERT THE CONDITION, NOT THE PHRASE. This used to search for the literal "3 cycles", which a
    # flat cycle-count breaker satisfies just as well as the non-improvement one the KB declares
    # (`pipeline-contracts.md § Circuit breaker (Execute)`: "if the grade does not improve after 3
    # consecutive cycles"). The delegate had in fact been rewritten to the flat form, and this
    # assertion reported the contract as holding transitively over the drop.
    assert_file_contains "$DEEP" "3 consecutive cycles" \
        "SEC04c the delegate's circuit breaker names 3 CONSECUTIVE cycles"
    assert_file_contains "$DEEP" "does not improve" \
        "SEC04d the delegate's breaker trips on NON-IMPROVEMENT, not on a cycle count"
fi

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
