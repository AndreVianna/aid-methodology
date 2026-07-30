#!/usr/bin/env bash
# test-skill-counts.sh -- repo-wide guard: every stated skill count equals the ONE derivation.
#
# Thin wrapper so `run-all.sh` (which globs tests/canonical/test-*.sh) picks this up. The
# checker itself is Node, because the derivation it must agree with is a Node module --
# site/scripts/skills/skill-counts.mjs -- and re-implementing that derivation in Bash would
# create the very second source of truth this guard exists to prevent.
#
# RELATIONSHIP TO test-doc-counts.sh (which predates this and stays).
# That suite asserts README + docs/ + the five profile READMEs state the current counts, and
# its header records a deliberate exclusion:
#
#     "The KB under .aid/knowledge/ is intentionally NOT asserted here -- it carries heavy
#      version-history sections and is reconciled by /aid-housekeep; guarding it by
#      prose-grep would false-positive."
#
# That reasoning was correct for a prose-grep. It is also exactly why work-001's two delivery
# gates found 55 wrong counts sitting unguarded, most of them in the KB: nothing was watching.
# This checker removes the objection rather than the exclusion -- it separates a claim about
# NOW from a record of a MOMENT by the line's SHAPE (a dated changelog row or `- YYYY-MM-DD:`
# bullet is history), plus an explicit per-line `count-history` marker for the handful of
# historical clauses that sit in ordinary prose. On the corpus that produced those 55
# findings it skips 185 history lines and reports zero false positives.
#
# The two suites overlap on README + docs/ and that is fine -- both derive from the same
# canonical tree, so they cannot disagree; they differ in mechanism (assert-expected-phrase
# vs. scan-every-claim) and this one additionally covers .aid/knowledge/, canonical/,
# site/src/content/docs/ and the repo-local maintainer skills.
#
# Fast + hermetic: reads files only, binds no port, mutates nothing.
#
# Usage: bash test-skill-counts.sh [--verbose]

set -euo pipefail

_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_repo="$(cd "${_here}/../.." && pwd)"

_passed=0
_failed=0

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not available -- repo-wide skill-count guard not run"
    echo "Tests passed: 0"
    echo "Tests failed: 0"
    exit 0
fi

_out="$(cd "$_repo" && node tests/canonical/check-skill-counts.mjs 2>&1)" && _rc=0 || _rc=$?

if [[ "${1:-}" == "--verbose" || "$_rc" -ne 0 ]]; then
    echo "$_out"
fi

if [[ "$_rc" -eq 0 ]]; then
    # Report the count the checker compared. The pass count here is always 1, so a shrinking
    # corpus does not show up as a falling pass count -- the guard against that lives in the
    # checker itself (CLAIM_FLOOR), set near the live figure rather than at a token value.
    _n="$(printf '%s\n' "$_out" | sed -n 's/^Claims checked: *\([0-9]\+\).*/\1/p' | head -1)"
    _n="${_n:-0}"
    echo "PASS SC01 every stated skill count agrees with the derivation (${_n} claims compared)"
    _passed=$((_passed + 1))
else
    echo "FAIL SC01 at least one stated skill count disagrees with the derivation (see above)"
    _failed=$((_failed + 1))
fi

echo ""
echo "=== Summary ==="
echo "  Tests passed: ${_passed}"
echo "  Tests failed: ${_failed}"

if [[ "$_failed" -gt 0 ]]; then
    echo ""
    echo "Some tests failed."
    exit 1
fi
echo ""
echo "All tests passed."
