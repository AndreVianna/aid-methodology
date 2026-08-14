#!/usr/bin/env bash
# test-executor-graph-flat-plan.sh -- feature-001 (flattened lite work structure)
# task-006: executor-graph flattened-PLAN parse test.
#
# Locks in that compute-block-radius.sh and complexity-score.sh parse a
# flattened single-delivery PLAN.md -- top-level `## Execution Graph` carrying
# `### Task Dependencies` + `### Can Be Done In Parallel`, with ZERO
# `### delivery-NNN` headings -- WITHOUT --delivery-id. The fixture mirrors
# canonical/aid/templates/delivery-plans/flattened-plan-template.md (the
# feature-001 flat PLAN.md shape); see SPEC.md "Testing strategy: Executor
# graph" (feature-001-flattened-lite-work-structure).
#
# Covers:
#   F1  Fixture carries ZERO ### delivery- headings (locks in the no-delivery-id
#       path both scripts key off)
#   F2  compute-block-radius.sh --plan-file <fixture> --failed-task <id> parses
#       the top-level graph with no --delivery-id and returns the correct
#       block-radius (linear chain: fail task-001 -> task-002,task-003; fail
#       task-002 -> task-003 only)
#   F3  compute-block-radius.sh --plan-file <fixture> WITHOUT --failed-task
#       exits 5 (--failed-task is a required arg)
#   F4  complexity-score.sh --plan-file <fixture> (no --delivery-id) parses the
#       top-level graph and returns the expected tasks/depth/risk/score
#
# Usage:
#   bash test-executor-graph-flat-plan.sh [-v|--verbose]
# Exit codes: 0 all passed; 1 any failed.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADIUS_SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/compute-block-radius.sh"
SCORE_SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/complexity-score.sh"

[[ -f "$RADIUS_SCRIPT" ]] || { echo "ERROR: compute-block-radius.sh not found at $RADIUS_SCRIPT" >&2; exit 1; }
[[ -f "$SCORE_SCRIPT"  ]] || { echo "ERROR: complexity-score.sh not found at $SCORE_SCRIPT" >&2; exit 1; }
[[ -x "$RADIUS_SCRIPT" ]] || chmod +x "$RADIUS_SCRIPT"
[[ -x "$SCORE_SCRIPT"  ]] || chmod +x "$SCORE_SCRIPT"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Pull one "key=value" line out of complexity-score.sh's stdout.
field() { grep -m1 "^$2=" <<< "$1" | cut -d= -f2; }

# ---------------------------------------------------------------------------
# Fixture: flattened single-delivery PLAN.md (feature-001 shape). Mirrors
# canonical/aid/templates/delivery-plans/flattened-plan-template.md: a
# top-level ## Execution Graph, ### Task Dependencies + ### Can Be Done In
# Parallel, ZERO ### delivery-NNN headings -- the single delivery is carried
# only by each task's DETAIL.md "-> delivery-001" Source field, never by a
# heading in this file.
# ---------------------------------------------------------------------------
PLAN="${TMP}/PLAN.md"
cat > "$PLAN" <<'EOF'
# Plan -- work-999-flat-fixture

> **Work:** work-999-flat-fixture
> **Created:** 2026-07-08

---

## Deliverables

- **Delivery:** delivery-001 -- Flat fixture delivery
- **What it delivers:** locks in the flattened executor-graph parse path
- **Features:** feature-001-flattened-lite-work-structure
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
EOF

# ---------------------------------------------------------------------------
# F1 -- fixture carries ZERO ### delivery- headings (keeps the no-delivery-id path)
# ---------------------------------------------------------------------------
DELIVERY_HEADINGS=$(grep -cE '^### delivery-' "$PLAN")
assert_eq "$DELIVERY_HEADINGS" "0" "F1 fixture has zero ### delivery- headings"

# ---------------------------------------------------------------------------
# F2 -- compute-block-radius.sh parses the top-level graph with no --delivery-id
# Chain: task-001 -> task-002 -> task-003; fail task-001 blocks task-002,task-003
# ---------------------------------------------------------------------------
RADIUS_OUT=$("$RADIUS_SCRIPT" --plan-file "$PLAN" --failed-task task-001 2>/dev/null)
RADIUS_RC=$?
EXPECTED_RADIUS="task-002
task-003"
assert_exit_eq "$RADIUS_RC" 0 "F2a compute-block-radius.sh exits 0 (no --delivery-id needed)"
assert_eq "$RADIUS_OUT" "$EXPECTED_RADIUS" "F2b compute-block-radius.sh block-radius (fail task-001 -> task-002,task-003)"

# Mid-chain fail: task-002 blocks only task-003 (not task-001, the ancestor)
RADIUS_MID=$("$RADIUS_SCRIPT" --plan-file "$PLAN" --failed-task task-002 2>/dev/null)
assert_eq "$RADIUS_MID" "task-003" "F2c compute-block-radius.sh mid-chain fail task-002 -> task-003 only"

# Leaf fail: task-003 has no dependents -> empty block-radius, still exit 0
RADIUS_LEAF=$("$RADIUS_SCRIPT" --plan-file "$PLAN" --failed-task task-003 2>/dev/null); RADIUS_LEAF_RC=$?
assert_exit_eq "$RADIUS_LEAF_RC" 0 "F2d compute-block-radius.sh leaf fail exits 0"
assert_eq "$RADIUS_LEAF" "" "F2e compute-block-radius.sh leaf fail (task-003) -> empty block-radius"

# ---------------------------------------------------------------------------
# F3 -- --failed-task is REQUIRED; compute-block-radius.sh exits 5 without it
# ---------------------------------------------------------------------------
"$RADIUS_SCRIPT" --plan-file "$PLAN" >/dev/null 2>&1
assert_exit_eq $? 5 "F3 compute-block-radius.sh without --failed-task exits 5"

# ---------------------------------------------------------------------------
# F4 -- complexity-score.sh parses the top-level graph with no --delivery-id
# 3 tasks, linear chain depth=2 (task-001=0, task-002=1, task-003=2);
# no --tasks-dir -> risk=0; no --consults/--quick-check-state -> consults=0.
# score = tasks + depth + risk + consults = 3 + 2 + 0 + 0 = 5
# ---------------------------------------------------------------------------
SCORE_OUT=$("$SCORE_SCRIPT" --plan-file "$PLAN" 2>/dev/null)
SCORE_RC=$?
assert_exit_eq "$SCORE_RC" 0 "F4a complexity-score.sh exits 0 (no --delivery-id needed)"
assert_eq "$(field "$SCORE_OUT" tasks)" "3" "F4b complexity-score.sh tasks=3"
assert_eq "$(field "$SCORE_OUT" depth)" "2" "F4c complexity-score.sh depth=2 (linear chain)"
assert_eq "$(field "$SCORE_OUT" risk)" "0" "F4d complexity-score.sh risk=0 (no --tasks-dir)"
assert_eq "$(field "$SCORE_OUT" consults)" "0" "F4e complexity-score.sh consults=0 (no --consults/--quick-check-state)"
assert_eq "$(field "$SCORE_OUT" score)" "5" "F4f complexity-score.sh score=5 (tasks+depth+risk+consults)"

test_summary
