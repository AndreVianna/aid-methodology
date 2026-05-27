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
#
# Usage:
#   bash test-compute-block-radius.sh
#   bash test-compute-block-radius.sh --verbose
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SUT moved to canonical/scripts/execute/ in 2026-05-26 consolidation
SCRIPT="${SCRIPT_DIR}/../../canonical/scripts/execute/compute-block-radius.sh"

[[ -f "$SCRIPT" ]] || { echo "ERROR: compute-block-radius.sh not found at $SCRIPT" >&2; exit 1; }
[[ -x "$SCRIPT" ]] || chmod +x "$SCRIPT"

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0
TMPDIR_TESTS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { [[ "$VERBOSE" -eq 1 ]] && echo "  $*" || true; }

# assert_output TEST_NAME ACTUAL EXPECTED
assert_output() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "[PASS] $name"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name"
        echo "       expected: $(echo "$expected" | tr '\n' ' ')"
        echo "       actual:   $(echo "$actual"   | tr '\n' ' ')"
        FAIL=$((FAIL + 1))
    fi
}

# assert_exit TEST_NAME CMD EXPECTED_EXIT
assert_exit() {
    local name="$1" cmd="$2" expected_exit="$3"
    eval "$cmd" >/dev/null 2>&1
    local actual_exit=$?
    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo "[PASS] $name (exit $expected_exit)"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $name (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

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
    assert_output "T01 linear chain: fail A → blocks B,C" "$RESULT" "$EXPECTED"
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
    assert_output "T02 diamond: fail A → blocks B,C,D" "$RESULT" "$EXPECTED"
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
    assert_output "T03 fan-out: fail A → blocks B,C,D" "$RESULT" "$EXPECTED"
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
    assert_output "T04 unrelated chain: fail A → blocks B only, not D/E" "$RESULT" "$EXPECTED"
}

# ---------------------------------------------------------------------------
# T05: No dependents: fail task-001 (root, no one depends on it) → empty
# ---------------------------------------------------------------------------
{
    G="${TMPDIR_TESTS}/t05.tsv"
    # task-002 depends on task-001, but task-001 has no one depending on it
    # Wait — task-002 depends on task-001 means task-001 → task-002 in reverse graph.
    # For T05 we want task-001 to have NO dependents at all:
    make_graph "$G" \
        "task-002\ttask-003"  # unrelated edge; task-001 absent from reverse graph

    RESULT=$("$SCRIPT" --failed-task task-001 --graph-file "$G" 2>/dev/null)
    EXPECTED=""
    assert_output "T05 no dependents: fail A (leaf) → empty block-radius" "$RESULT" "$EXPECTED"
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
    assert_output "T06 mid-chain fail: fail B → blocks C,D; not A" "$RESULT" "$EXPECTED"
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
    # If A fails, C is blocked (AND edges: must have all deps Done).
    # C blocked → D blocked.
    EXPECTED="task-003
task-004"
    assert_output "T07 multi-root fan: fail A → blocks C,D; not B" "$RESULT" "$EXPECTED"
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
    assert_output "T08 singleton failed task: empty block-radius" "$RESULT" "$EXPECTED"
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
    assert_output "T09 PLAN.md parse: fail A → blocks B,C (end-to-end)" "$RESULT" "$EXPECTED"
}

# ---------------------------------------------------------------------------
# T10: Integration — 5-task delivery graph (mirrors delivery-005 structure)
# Execution Graph (Depends On):
#   task-031: —
#   task-032: task-031
#   task-033: task-031
#   task-034: task-033
#   task-035: task-033
# Fail task-033 → blocks task-034, task-035; task-032 is unrelated after task-031 succeeds
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
    assert_output "T10 integration 5-task delivery: fail task-033 → blocks task-034,task-035" "$RESULT" "$EXPECTED"
}

# ---------------------------------------------------------------------------
# Error handling: missing required args
# ---------------------------------------------------------------------------
assert_exit "T11 missing --failed-task" \
    "\"$SCRIPT\" --plan-file /dev/null" 5

assert_exit "T12 missing --plan-file and --graph-file" \
    "\"$SCRIPT\" --failed-task task-001" 5

assert_exit "T13 both --plan-file and --graph-file" \
    "\"$SCRIPT\" --failed-task task-001 --plan-file /dev/null --graph-file /dev/null" 4

assert_exit "T14 invalid --failed-task format" \
    "\"$SCRIPT\" --failed-task not-a-task --graph-file /dev/null" 4

assert_exit "T15 graph-file not found" \
    "\"$SCRIPT\" --failed-task task-001 --graph-file /nonexistent-file.tsv" 1

# ---------------------------------------------------------------------------
# T16: bfs handles non-normalized failed-task input (whitespace + backticks)
# ---------------------------------------------------------------------------
# Use TSV reverse-graph format (dep TAB dependent) — same as T01-T08
T16_GRAPH="${TMPDIR_TESTS}/t16.tsv"
make_graph "$T16_GRAPH" \
    "task-001\ttask-002" \
    "task-002\ttask-003"

# Call with whitespace-wrapped task name; should still find task-002 + task-003
T16_OUT=$("$SCRIPT" --failed-task "  task-001  " --graph-file "$T16_GRAPH" 2>/dev/null)
T16_RC=$?
T16_EXPECTED="task-002
task-003"
if [[ "$T16_RC" -eq 0 ]] && [[ "$T16_OUT" == "$T16_EXPECTED" ]]; then
    echo "[PASS] T16 bfs_block_radius normalizes whitespace-wrapped failed-task"
    PASS=$((PASS + 1))
else
    echo "[FAIL] T16 bfs_block_radius normalization (rc=$T16_RC, out='$T16_OUT')"
    FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# T17: state-execute.md degradation notice has the stable format scrapers expect
# Format: [degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
# ---------------------------------------------------------------------------
STATE_EXEC="$(cd "$(dirname "$SCRIPT")/../../skills/aid-execute/references" && pwd)/state-execute.md"
if [[ -f "$STATE_EXEC" ]] && grep -q "\[degradation\] MaxConcurrent=" "$STATE_EXEC" && grep -q "host capability=sequential" "$STATE_EXEC" && grep -q "running effective=1" "$STATE_EXEC"; then
    echo "[PASS] T17 state-execute.md degradation notice has stable format"
    PASS=$((PASS + 1))
else
    echo "[FAIL] T17 state-execute.md degradation notice missing or wrong format"
    FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
