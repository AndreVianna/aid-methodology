#!/usr/bin/env bash
# test-dashboard-node.sh - Runs the Node built-in tests of the dashboard's phase
# mapping and stage rail, which no other suite runs.
#
# Covers: the stage-rail test of home.html (renderStageRail, a gate criterion),
# the Node twins of the Python phase-mapping and intent-phase tests, and the
# work fixtures of each phase read by the Node reader (task-079).
#
# Usage:
#   bash test-dashboard-node.sh
# Exit codes: 0 all pass / 1 any fail / 0 with a SKIP when node is absent.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

NODE_TESTS=(
    "dashboard/server/tests/test_home_stage_rails.mjs"
    "dashboard/server/tests/test_task048_phase_mapping.mjs"
    "dashboard/server/tests/test_task031_intent_phases.mjs"
    "dashboard/server/tests/test_task079_phase_fixtures.mjs"
)

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not found; dashboard node tests not run"
    test_summary
    exit 0
fi

for rel in "${NODE_TESTS[@]}"; do
    if [[ ! -f "$REPO_ROOT/$rel" ]]; then
        fail "dashboard node test exists: $rel -- file missing"
        continue
    fi
    out=$(cd "$REPO_ROOT" && node --test "$rel" 2>&1)
    rc=$?
    if [[ $rc -eq 0 ]]; then
        pass "dashboard node test passes: $rel"
    else
        fail "dashboard node test passes: $rel -- node --test exited $rc"
        [[ $VERBOSE -eq 1 ]] && echo "$out"
    fi
done

test_summary
