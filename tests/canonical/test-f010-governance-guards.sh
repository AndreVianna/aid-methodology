#!/usr/bin/env bash
# test-f010-governance-guards.sh -- f010 behavioral guards: suspect scoping + closure re-verify.
#
# Asserts the MECHANICAL halves of f010 governance that can be tested deterministically
# by grepping committed canonical skill bodies.  No fixtures, no teardown -- read-only.
#
# Guard 1 (FR-33/AC10 -- suspect scoping):
#   G01  state-kb-delta.md references kb-freshness-check.sh (suspect pre-pass wired)
#   G02  state-kb-delta.md declares git-date range is NO LONGER the scoping boundary
#        (the disclaimer must be present; git range is convenience-only, not the drift signal)
#   G03  state-kb-delta.md does NOT invoke git log --since / --after as a scoping step
#        (confirms the date-range gate is absent, not just disclaimed)
#
# Guard 2 (FR-33 -- whole-KB review retained, AC1 coverage not narrowed):
#   G04  state-kb-delta.md mandates a two-tier whole-KB review (Tier 2 keyword present)
#   G05  state-kb-delta.md requires reviewing current-verdict docs (not suspect-only)
#   G06  state-kb-delta.md contains the "No doc is skipped" invariant
#
# Guard 3 (FR-34 -- before-commit closure re-verify, both skills):
#   G07  state-kb-delta.md references closure-check.sh (housekeep before-commit path)
#   G08  state-kb-delta.md places the closure re-verify BEFORE the commit step
#   G09  state-done.md (aid-update-kb) references closure-check.sh (update-kb before-commit path)
#   G10  state-done.md places closure re-verify BEFORE commit (Step 1 before Step 4)
#
# No new script is tested at the script level -- f004's test-closure-check.sh and
# f007's test-kb-freshness-check.sh already cover the two helpers.  These guards
# assert only the wiring declared in the skill prose bodies (task-054 rewrite).
#
# Mechanical-vs-judgment boundary:
#   These guards cover the deterministic / structural halves (script references, ordering
#   of steps, prose invariants).  They do NOT assert LLM re-discovery judgment, the
#   content of a user's KB, or runtime suspect-set values -- those are judgment-side and
#   untestable at the doc-grep level.  This mirrors how f012 validation suites draw the line.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# ASCII-only (C2 requirement for any added test script).
#
# Usage:
#   bash tests/canonical/test-f010-governance-guards.sh [--verbose]
#   HOME=$(mktemp -d) bash tests/canonical/test-f010-governance-guards.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

KB_DELTA="${REPO_ROOT}/canonical/skills/aid-housekeep/references/state-kb-delta.md"
STATE_DONE="${REPO_ROOT}/canonical/skills/aid-update-kb/references/state-done.md"

echo "== test-f010-governance-guards.sh =="

# ---------------------------------------------------------------------------
# Pre-flight: both target skill files must exist.
# ---------------------------------------------------------------------------
assert_file_exists "${KB_DELTA}" \
    "setup: aid-housekeep/references/state-kb-delta.md exists"
assert_file_exists "${STATE_DONE}" \
    "setup: aid-update-kb/references/state-done.md exists"

# ===========================================================================
# Guard 1 -- FR-33/AC10: suspect scoping via kb-freshness-check.sh
# ===========================================================================

# G01: state-kb-delta.md references kb-freshness-check.sh (suspect pre-pass wired).
# The f007 script must be named so the prose correctly wires the suspect pre-pass.
assert_file_contains "${KB_DELTA}" "kb-freshness-check.sh" \
    "G01 state-kb-delta.md references kb-freshness-check.sh (suspect pre-pass wired)"

# G02: state-kb-delta.md declares that the git-date range is no longer the scoping boundary.
# The exact disclaimer text inserted by task-054 must be present.
assert_file_contains "${KB_DELTA}" "is no longer the scoping" \
    "G02 state-kb-delta.md declares git-date range is no longer the scoping boundary"

# G03: state-kb-delta.md does NOT invoke git log --since or --after as a drift-scoping step.
# This confirms the date-range gate is absent from the skill body (not merely disclaimed).
# The retained convenience git fetch is "git fetch origin master" -- not a --since/--after call.
if grep -qE 'git log.*(--since|--after)' "${KB_DELTA}" 2>/dev/null; then
    fail "G03 state-kb-delta.md must not use git log --since/--after as a scoping step (date-range gate must be absent)"
    if [[ "${VERBOSE}" -eq 1 ]]; then
        grep -nE 'git log.*(--since|--after)' "${KB_DELTA}" || true
    fi
else
    pass "G03 state-kb-delta.md: no git log --since/--after date-range scoping (convenience hint only)"
fi

# ===========================================================================
# Guard 2 -- FR-33: whole-KB content re-review retained (AC1 coverage not narrowed)
# ===========================================================================

# G04: state-kb-delta.md mandates a two-tier whole-KB review.
# "Tier 2" is the canonical label for the retained whole-KB pass that prevents
# narrowing to suspect-only.
assert_file_contains "${KB_DELTA}" "Tier 2" \
    "G04 state-kb-delta.md mandates two-tier review (Tier 2 label present)"

# G05: state-kb-delta.md requires reviewing current-verdict docs beyond the suspect set.
# The exact AC1 language that current-verdict docs are still content-reviewed must be present.
assert_file_contains "${KB_DELTA}" "current" \
    "G05 state-kb-delta.md reviews current-verdict docs (whole-KB, not suspect-only)"

# Tighter: the "then `current` docs" phrase in the Tier 2 section confirms coverage.
# The word "current" followed by "docs" in the Tier 2 retained review instruction.
if grep -qE 'then.*current.*docs' "${KB_DELTA}" 2>/dev/null; then
    pass "G05b state-kb-delta.md Tier 2 explicitly covers current docs"
else
    fail "G05b state-kb-delta.md Tier 2 does not mention current docs coverage"
fi

# G06: state-kb-delta.md contains the "No doc is skipped" invariant.
# This is the AC1 safety-net phrase -- a future edit that removes it would narrow coverage.
assert_file_contains "${KB_DELTA}" "No doc is skipped" \
    "G06 state-kb-delta.md contains the 'No doc is skipped' AC1 invariant"

# ===========================================================================
# Guard 3 -- FR-34: before-commit closure re-verify in BOTH KB-mutating skills
# ===========================================================================

# G07: state-kb-delta.md references closure-check.sh (housekeep before-commit path).
# The closure re-verify step must name the script that performs the check.
assert_file_contains "${KB_DELTA}" "closure-check.sh" \
    "G07 state-kb-delta.md references closure-check.sh (housekeep closure re-verify)"

# G08: state-kb-delta.md places the closure re-verify BEFORE the commit call.
# Verify ordering: the heading "closure re-verify BEFORE commit" appears before the
# branch-commit.sh --commit invocation in the file.
# Strategy: find the line numbers for both; closure-check section must precede commit.
closure_line=$(grep -n "closure re-verify BEFORE commit\|BEFORE commit" "${KB_DELTA}" | head -1 | cut -d: -f1)
commit_line=$(grep -n "branch-commit.sh.*--commit\|--commit" "${KB_DELTA}" | head -1 | cut -d: -f1)

if [[ -z "${closure_line}" ]]; then
    fail "G08 state-kb-delta.md: 'closure re-verify BEFORE commit' heading not found"
elif [[ -z "${commit_line}" ]]; then
    fail "G08 state-kb-delta.md: branch-commit.sh --commit invocation not found"
elif [[ "${closure_line}" -lt "${commit_line}" ]]; then
    pass "G08 state-kb-delta.md: closure re-verify (line ${closure_line}) precedes commit (line ${commit_line})"
else
    fail "G08 state-kb-delta.md: closure re-verify (line ${closure_line}) does NOT precede commit (line ${commit_line})"
fi

# G09: state-done.md (aid-update-kb) references closure-check.sh (update-kb before-commit path).
# The standing invariant must be wired in BOTH KB-mutating skill bodies (FR-34 contract).
assert_file_contains "${STATE_DONE}" "closure-check.sh" \
    "G09 state-done.md references closure-check.sh (update-kb closure re-verify)"

# G10: state-done.md places closure re-verify BEFORE the commit step.
# Step 1 is the closure check; Step 4 is the commit.  Verify ordering by line numbers.
done_closure_line=$(grep -n "Re-verify closure\|closure-check.sh" "${STATE_DONE}" | head -1 | cut -d: -f1)
done_commit_line=$(grep -n "git commit\|## Step 4" "${STATE_DONE}" | head -1 | cut -d: -f1)

if [[ -z "${done_closure_line}" ]]; then
    fail "G10 state-done.md: closure re-verify step not found"
elif [[ -z "${done_commit_line}" ]]; then
    fail "G10 state-done.md: commit step not found"
elif [[ "${done_closure_line}" -lt "${done_commit_line}" ]]; then
    pass "G10 state-done.md: closure re-verify (line ${done_closure_line}) precedes commit (line ${done_commit_line})"
else
    fail "G10 state-done.md: closure re-verify (line ${done_closure_line}) does NOT precede commit (line ${done_commit_line})"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
