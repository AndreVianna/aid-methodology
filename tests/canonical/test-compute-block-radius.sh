#!/usr/bin/env bash
# test-compute-block-radius.sh — Unit + integration tests for the BFS
# transitive-descendant computation in compute-block-radius.sh.
#
# Tests cover:
#   T01  Linear chain: A → B → C; fail A → blocks B, C
#   T02  Diamond:      A → B, A → C, B → D, C → D; fail A → blocks B, C, D
#   T03  Fan-out:      A → B, A → C, A → D; fail A → blocks B, C, D
#   T04  Unrelated chain: A → B; D → E; fail A → blocks B only, not D/E
#   T05  No dependents: A (root); fail A → empty block-radius
#   T06  Mid-chain fail: A → B → C → D; fail B → blocks C, D; NOT A
#   T07  Multi-root fan: A → C, B → C, C → D; fail A → blocks C, D; not B
#   T08  Already-failed has no transitives (singleton graph)
#   T09  Parse from PLAN.md snippet — end-to-end with --plan-file
#   T10  Integration: seeded failure with 5-task delivery graph
#   T11–T15  Error handling: missing/conflicting/invalid args
#   T16  bfs normalizes whitespace-wrapped failed-task input
#   T17  state-execute.md degradation notice has the stable scraper format
#
# Usage:
#   bash test-compute-block-radius.sh
#   bash test-compute-block-radius.sh --verbose
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SUT moved to canonical/scripts/execute/ in 2026-05-26 consolidation
SCRIPT="${SCRIPT_DIR}/../../canonical/scripts/execute/compute-block-radius.sh"

[[ -f "$SCRIPT" ]] || { echo "ERROR: compute-block-radius.sh not found at $SCRIPT" >&2; exit 1; }
[[ -x "$SCRIPT" ]] || chmod +x "$SCRIPT"

TMPDIR_TESTS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# make_graph FILE "dep TAB dependent" ...
# Each argument after FILE is one edge line.
make_graph() {
    local file="$1"; shift
    > "$file"
    for edge in "$@"; do
        echo -e "$edge" >> "$file"
    done
}

# make_plan FILE — writes a minimal PLAN.md snippet with the given Depends-On table
# Args after FILE: "task-NNN:dep1,dep2" or "task-NNN:—" per line
make_plan() {
    local file="$1"; shift
    cat > "$file" <<'HEADER'
# Plan — test-delivery

## Execution Graphs (per delivery)

### delivery-001: Test Delivery — N tasks

#### Execution Graph

| Task | Depends On |
|------|-----------|
HEADER
    for spec in "$@"; do
        local task="${spec%%:*}"
        local deps="${spec#*:}"
        echo "| ${task} | ${deps} |" >> "$file"
    done
    cat >> "$file" <<'FOOTER'

| Can Be Done In Parallel |
|------------------------|
| (see graph) |
FOOTER
}

# ---------------------------------------------------------------------------
# T01: Linear chain A → B → C; fail task-001 → blocks task-002, task-003
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t01.tsv"
    # reverse graph (dep TAB dependent): task-001 depended-on by task-002; task-002 by task-003
    make_graph "$G" \
        "task-001\ttask-002" \
        "task-002\ttask-003"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED="task-002
task-003"
    assert_eq "$RESULT" "$EXPECTED" "T01 linear chain: fail A → blocks B,C"
}

# ---------------------------------------------------------------------------
# T02: Diamond: fail task-001 → blocks task-002, task-003, task-004
# task-001 depended by task-002 and task-003; task-002 and task-003 depended by task-004
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t02.tsv"
    make_graph "$G" \
        "task-001\ttask-002" \
        "task-001\ttask-003" \
        "task-002\ttask-004" \
        "task-003\ttask-004"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED="task-002
task-003
task-004"
    assert_eq "$RESULT" "$EXPECTED" "T02 diamond: fail A → blocks B,C,D"
}

# ---------------------------------------------------------------------------
# T03: Fan-out: task-001 → task-002, task-003, task-004
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t03.tsv"
    make_graph "$G" \
        "task-001\ttask-002" \
        "task-001\ttask-003" \
        "task-001\ttask-004"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED="task-002
task-003
task-004"
    assert_eq "$RESULT" "$EXPECTED" "T03 fan-out: fail A → blocks B,C,D"
}

# ---------------------------------------------------------------------------
# T04: Unrelated chain: A → B; D → E; fail A → blocks B only (not D, E)
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t04.tsv"
    make_graph "$G" \
        "task-001\ttask-002" \
        "task-004\ttask-005"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED="task-002"
    assert_eq "$RESULT" "$EXPECTED" "T04 unrelated chain: fail A → blocks B only, not D/E"
}

# ---------------------------------------------------------------------------
# T05: No dependents: fail task-001 (root, no one depends on it) → empty
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t05.tsv"
    # task-001 absent from the reverse graph → it has no dependents at all
    make_graph "$G" \
        "task-002\ttask-003"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED=""
    assert_eq "$RESULT" "$EXPECTED" "T05 no dependents: fail A (leaf) → empty block-radius"
}

# ---------------------------------------------------------------------------
# T06: Mid-chain fail: A → B → C → D; fail B → blocks C, D (not A)
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t06.tsv"
    make_graph "$G" \
        "task-001\ttask-002" \
        "task-002\ttask-003" \
        "task-003\ttask-004"

    RESULT=$("$SCRIPT" --failed-task task-002 --graph-file "$G" 2>/dev/null)
    EXPECTED="task-003
task-004"
    assert_eq "$RESULT" "$EXPECTED" "T06 mid-chain fail: fail B → blocks C,D; not A"
}

# ---------------------------------------------------------------------------
# T07: Multi-root fan: A → C, B → C, C → D; fail A → blocks C, D (not B)
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t07.tsv"
    make_graph "$G" \
        "task-001\ttask-003" \
        "task-002\ttask-003" \
        "task-003\ttask-004"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    # C (task-003) depends on BOTH A (task-001) and B (task-002).
    # If A fails, C is blocked (AND edges: must have all deps Done). C blocked → D blocked.
    EXPECTED="task-003
task-004"
    assert_eq "$RESULT" "$EXPECTED" "T07 multi-root fan: fail A → blocks C,D; not B"
}

# ---------------------------------------------------------------------------
# T08: Singleton failed task (only node in graph): empty block-radius
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t08.tsv"
    # Empty graph — task-001 has no edges at all
    > "$G"

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED=""
    assert_eq "$RESULT" "$EXPECTED" "T08 singleton failed task: empty block-radius"
}

# ---------------------------------------------------------------------------
# T09: Parse from PLAN.md snippet — end-to-end with --plan-file
# Graph: task-001 (no deps), task-002 (depends on task-001), task-003 (depends on task-002)
# Fail task-001 → blocks task-002, task-003
# ---------------------------------------------------------------------------
{
    P="${TMPDIR_TESTS}/t09-plan.md"
    make_plan "$P" \
        "task-001:—" \
        "task-002:task-001" \
        "task-003:task-002"

    RESULT=$("$SCRIPT" --failed-task task-001 --plan-file "$P" 2>/dev/null)
    EXPECTED="task-002
task-003"
    assert_eq "$RESULT" "$EXPECTED" "T09 PLAN.md parse: fail A → blocks B,C (end-to-end)"
}

# ---------------------------------------------------------------------------
# T10: Integration — 5-task delivery graph (mirrors delivery-005 structure)
# Fail task-033 → blocks task-034, task-035; task-032 unrelated after task-031 succeeds
# ---------------------------------------------------------------------------
{
    P="${TMPDIR_TESTS}/t10-plan.md"
    make_plan "$P" \
        "task-031:—" \
        "task-032:task-031" \
        "task-033:task-031" \
        "task-034:task-033" \
        "task-035:task-033"

    RESULT=$("$SCRIPT" --failed-task task-033 --plan-file "$P" 2>/dev/null)
    EXPECTED="task-034
task-035"
    assert_eq "$RESULT" "$EXPECTED" "T10 integration 5-task delivery: fail task-033 → blocks task-034,task-035"
}

# ---------------------------------------------------------------------------
# T11–T15: Error handling: missing/conflicting/invalid args (exact exit codes)
# ---------------------------------------------------------------------------
"$SCRIPT" --plan-file /dev/null >/dev/null 2>&1
assert_exit_eq $? 5 "T11 missing --failed-task"

"$SCRIPT" --failed-task task-001 >/dev/null 2>&1
assert_exit_eq $? 5 "T12 missing --plan-file and --graph-file"

"$SCRIPT" --failed-task task-001 --plan-file /dev/null --graph-file /dev/null >/dev/null 2>&1
assert_exit_eq $? 4 "T13 both --plan-file and --graph-file"

"$SCRIPT" --failed-task not-a-task --graph-file /dev/null >/dev/null 2>&1
assert_exit_eq $? 4 "T14 invalid --failed-task format"

"$SCRIPT" --failed-task task-001 --graph-file /nonexistent-file.tsv >/dev/null 2>&1
assert_exit_eq $? 1 "T15 graph-file not found"

# ---------------------------------------------------------------------------
# T16: bfs handles non-normalized failed-task input (whitespace + backticks)
# ---------------------------------------------------------------------------
T16_GRAPH="${TMPDIR_TESTS}/t16.tsv"
make_graph "$T16_GRAPH" \
    "task-001\ttask-002" \
    "task-002\ttask-003"

# Call with whitespace-wrapped task name; should still find task-002 + task-003
T16_OUT=$("$SCRIPT" --failed-task "  task-001  " --graph-file "$T16_GRAPH" 2>/dev/null)
T16_RC=$?
T16_EXPECTED="task-002
task-003"
if [[ "$T16_RC" -eq 0 && "$T16_OUT" == "$T16_EXPECTED" ]]; then
    pass "T16 bfs_block_radius normalizes whitespace-wrapped failed-task"
else
    fail "T16 bfs_block_radius normalization — rc=$T16_RC out='$T16_OUT'"
fi

# ---------------------------------------------------------------------------
# T17: state-execute.md degradation notice has the stable format scrapers expect
# Format: [degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
# ---------------------------------------------------------------------------
STATE_EXEC="$(cd "$(dirname "$SCRIPT")/../../skills/aid-execute/references" && pwd)/state-execute.md"
if [[ -f "$STATE_EXEC" ]] \
    && grep -q "\[degradation\] MaxConcurrent=" "$STATE_EXEC" \
    && grep -q "host capability=sequential" "$STATE_EXEC" \
    && grep -q "running effective=1" "$STATE_EXEC"; then
    pass "T17 state-execute.md degradation notice has stable format"
else
    fail "T17 state-execute.md degradation notice missing or wrong format"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
