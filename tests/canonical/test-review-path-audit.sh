#!/usr/bin/env bash
# test-review-path-audit.sh -- the contract of scripts/checks/review-path-audit.sh
#
# COVERS: scripts/checks/review-path-audit.sh
#
# The audit proves the review stack is singular (one skill, one agent) and that
# every review-family slash-ref in canonical/ resolves to a real skill.  It uses
# four layers: L1 SINGLETON (glob count), L2 LEXICON (name match),
# L3 SLASH-REFS (dangling-ref extraction), L4 AGENT-REFS (reviewer present).
#
# Critical design point: the *review* glob (L1) returns 1 when aid-screener is
# the only non-review agent, so L1 passes while the rival sits in the tree.
# L2 catches it via the review-family lexicon.  PA03 is the assertion that
# exists specifically for this class of bypass.
#
# Assertions:
#   PA01  passes against the real repository tree
#   PA02  fails when a second review-family skill directory is present
#   PA03  fails when an agent named aid-screener is present -- the case the
#         *review* glob misses; L2 LEXICON catches what L1 cannot see
#   PA04  fails on vacuity: zero slash-refs extracted from the corpus
#   PA05  fails on vacuity: refs extracted but none are review-family
#
# Fixtures are built in a temp directory.  The real tree is never mutated.
# All fixtures are torn down on exit, even on failure.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
#
# Usage:
#   bash tests/canonical/test-review-path-audit.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/scripts/checks/review-path-audit.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-review-path-audit.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
    echo "FATAL: review-path-audit.sh not found at $SUT" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Temporary scratch area (cleaned up on exit, even on failure)
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Helper: run the audit from a given directory.
# The script uses relative paths (canonical/skills/, canonical/agents/, etc.)
# so the working directory must be the root of the tree under test.
# stdout and stderr are merged; exit code is preserved through the substitution.
# ---------------------------------------------------------------------------
run_audit() {
    ( cd "$1" && bash "$SUT" 2>&1 )
}

# ---------------------------------------------------------------------------
# Helper: build a minimal fixture with the canonical tree shape.
# Creates the sanctioned pair (aid-review, aid-reviewer) and one .md file that
# contains a /aid-review slash-ref so L3 finds both a non-zero distinct count
# and at least one review-family reference.
# ---------------------------------------------------------------------------
mk_fixture() {
    local dir="$1"
    mkdir -p "${dir}/canonical/skills/aid-review" \
             "${dir}/canonical/agents/aid-reviewer" \
             "${dir}/canonical/docs"
    printf 'SKILL placeholder\n' > "${dir}/canonical/skills/aid-review/SKILL.md"
    printf 'AGENT placeholder\n' > "${dir}/canonical/agents/aid-reviewer/AGENT.md"
    # Provide a /aid-review slash-ref so L3 is non-vacuous.
    printf 'Use /aid-review to trigger a review. The aid-reviewer agent runs it.\n' \
        > "${dir}/canonical/docs/index.md"
}

# ===========================================================================
# PA01: passes against the real repository tree
# ===========================================================================
echo "=== PA01: passes against the real repository tree ==="
OUT="$(run_audit "$REPO")"
rc=$?
assert_exit_zero    $rc    "PA01 real tree exits 0"
assert_output_contains "$OUT" "RESULT PASS" "PA01 real tree prints RESULT PASS"

# ===========================================================================
# PA02: fails when a second review-family skill directory is present
# ===========================================================================
echo "=== PA02: fails with a second review-family skill directory ==="
FX2="${TMP}/fx2"
mk_fixture "$FX2"
# A second *review* skill directory makes L1 SINGLETON see count=2.
mkdir -p "${FX2}/canonical/skills/aid-review-extra"
printf 'rival review skill\n' > "${FX2}/canonical/skills/aid-review-extra/SKILL.md"
OUT="$(run_audit "$FX2")"
rc=$?
assert_exit_nonzero $rc    "PA02 second review skill dir → non-zero exit"
assert_output_contains "$OUT" "RESULT FAIL" "PA02 second review skill dir → RESULT FAIL"

# ===========================================================================
# PA03: fails when aid-screener agent is present
#       The *review* glob (L1) still returns 1 for skills and 1 for agents,
#       so L1 SINGLETON passes.  L2 LEXICON matches "screener" and catches it.
# ===========================================================================
echo "=== PA03: aid-screener agent -- L2 LEXICON catches what *review* glob misses ==="
FX3="${TMP}/fx3"
mk_fixture "$FX3"
# aid-screener: not matched by *review* glob (L1 passes) but caught by lexicon (L2 fails).
mkdir -p "${FX3}/canonical/agents/aid-screener"
printf 'rival screener agent\n' > "${FX3}/canonical/agents/aid-screener/AGENT.md"
OUT="$(run_audit "$FX3")"
rc=$?
assert_exit_nonzero $rc    "PA03 aid-screener agent → non-zero exit"
assert_output_contains "$OUT" "RESULT FAIL"  "PA03 aid-screener agent → RESULT FAIL"
assert_output_contains "$OUT" "VIOLATION"    "PA03 aid-screener agent → VIOLATION line present"
assert_output_contains "$OUT" "aid-screener" "PA03 VIOLATION names aid-screener"

# ===========================================================================
# PA04: fails on vacuity -- zero slash-refs extracted from the corpus
# ===========================================================================
echo "=== PA04: fails on vacuity -- zero refs extracted ==="
FX4="${TMP}/fx4"
mk_fixture "$FX4"
# Overwrite the index so the corpus contains no /aid-* refs.
printf 'This document contains no slash-refs whatsoever.\n' \
    > "${FX4}/canonical/docs/index.md"
# The placeholder SKILL.md and AGENT.md also contain no refs.
OUT="$(run_audit "$FX4")"
rc=$?
assert_exit_nonzero $rc    "PA04 zero refs extracted → non-zero exit"
assert_output_contains "$OUT" "RESULT FAIL"  "PA04 zero refs extracted → RESULT FAIL"
assert_output_contains "$OUT" "VIOLATION"    "PA04 zero refs extracted → VIOLATION line present"
assert_output_contains "$OUT" "distinct=0"   "PA04 output reports distinct=0"

# ===========================================================================
# PA05: fails on vacuity -- refs are present but none are review-family
# ===========================================================================
echo "=== PA05: fails on vacuity -- no review-family refs found ==="
FX5="${TMP}/fx5"
mk_fixture "$FX5"
# Overwrite index.md with non-review-family refs only.
# /aid-create and /aid-plan match no lexicon term (review|screener|critique|
# audit|inspect|verif|grade|rubric), so review_count stays 0.
printf 'Use /aid-create to create things and /aid-plan for planning.\n' \
    > "${FX5}/canonical/docs/index.md"
OUT="$(run_audit "$FX5")"
rc=$?
assert_exit_nonzero $rc    "PA05 no review-family refs → non-zero exit"
assert_output_contains "$OUT" "RESULT FAIL"     "PA05 no review-family refs → RESULT FAIL"
assert_output_contains "$OUT" "VIOLATION"       "PA05 no review-family refs → VIOLATION line present"
assert_output_contains "$OUT" "review-family=0" "PA05 output reports review-family=0"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
test_summary
exit $?
