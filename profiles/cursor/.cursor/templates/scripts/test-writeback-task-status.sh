#!/usr/bin/env bash
# test-writeback-task-status.sh — smoke-test harness for writeback-task-status.sh
#
# Tests all 4 arg modes and lock-contention safety.
#
# Usage:
#   test-writeback-task-status.sh [-v | --verbose]
#
# Test scenarios:
#   Unit 1: --task-id --field --value  (single-field row update)
#   Unit 2: --task-id --findings       (## Quick Check block write)
#   Unit 3: --delivery-id --block      (## Delivery Gate block write)
#   Unit 4: --delivery-id --append-issue (delivery-NNN-issues.md append)
#   Unit 5: Idempotency — re-running each mode produces no additional change
#   Unit 6: Concurrent lock contention — 5 parallel processes, different rows
#   Unit 7: Error paths — missing args, invalid task-id, lock timeout
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/writeback-task-status.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
ERRORS=()

# ---------------------------------------------------------------------------
log()  { [[ "$VERBOSE" -eq 1 ]] && echo "[LOG] $*" || true; }
pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }

assert_file_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label — pattern not found: '$pattern' in $file"
        [[ "$VERBOSE" -eq 1 ]] && echo "---FILE---" && cat "$file" && echo "---END---"
    fi
}

assert_file_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if ! grep -qF "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label — unexpected pattern found: '$pattern' in $file"
    fi
}

assert_exit_nonzero() {
    local code="$1" label="$2"
    if [[ "$code" -ne 0 ]]; then
        pass "$label (exit $code)"
    else
        fail "$label — expected non-zero exit, got 0"
    fi
}

assert_line_count() {
    local file="$1" expected="$2" label="$3"
    local actual
    actual=$(wc -l < "$file" | tr -d ' ')
    if [[ "$actual" -eq "$expected" ]]; then
        pass "$label (line count $actual)"
    else
        fail "$label — expected $expected lines, got $actual"
    fi
}

# ---------------------------------------------------------------------------
# Setup: create a temporary workspace
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Shared env vars that writeback-task-status.sh honours
WORK_DIR="${TMPDIR_BASE}/work"
TASKS_DIR="${WORK_DIR}/tasks"
mkdir -p "$TASKS_DIR"

export AID_STATE_FILE="${WORK_DIR}/STATE.md"
export AID_TASKS_DIR="$TASKS_DIR"
export AID_DELIVERY_ISSUES_DIR="$WORK_DIR"
export AID_LOCK_DIR="$WORK_DIR"
export AID_LOCK_TIMEOUT=10   # retries

# Scaffold STATE.md with a Tasks Status section that has 5 rows
cat > "$AID_STATE_FILE" <<'STATEOF'
# Work State — work-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | — | — | — |
| 002 | task-002-bravo | TEST | 1 | Pending | — | — | — |
| 003 | task-003-charlie | DESIGN | 2 | Pending | — | — | — |
| 004 | task-004-delta | DOCUMENT | 2 | Pending | — | — | — |
| 005 | task-005-echo | REFACTOR | 3 | Pending | — | — | — |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
STATEOF

# Scaffold 5 task files
for i in 001 002 003 004 005; do
    cat > "${TASKS_DIR}/task-${i}.md" <<TASKEOF
# task-${i}: Test Task

**Type:** IMPLEMENT

**Scope:**
- Test scope for task ${i}

**Acceptance Criteria:**
- [ ] criterion

---

## Status

Pending

## Dispatches

(none yet)

TASKEOF
done

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: --task-id --field --value ==="

run_field() {
    local tid="$1" field="$2" val="$3"
    bash "$SCRIPT" --task-id "$tid" --field "$field" --value "$val"
}

run_field 1 Status "In Progress"
assert_file_contains "$AID_STATE_FILE" "In Progress" "task-001 Status updated"
assert_file_contains "$AID_STATE_FILE" "Pending" "other rows still Pending after task-001 update"

run_field 2 Status "Done"
assert_file_contains "$AID_STATE_FILE" "Done" "task-002 Status updated to Done"

run_field 3 Review "A"
assert_file_contains "$AID_STATE_FILE" "A" "task-003 Review field updated"

run_field 4 Notes "first note"
assert_file_contains "$AID_STATE_FILE" "first note" "task-004 Notes updated"

run_field 5 Elapsed "12m"
assert_file_contains "$AID_STATE_FILE" "12m" "task-005 Elapsed updated"

# Verify other rows not disturbed
assert_file_contains "$AID_STATE_FILE" "task-001-alpha" "task-001 row intact after other updates"
assert_file_contains "$AID_STATE_FILE" "task-005-echo" "task-005 row intact"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: --task-id --findings ==="

FINDINGS_BLOCK="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [HIGH] | missing error path | Deferred-to-gate |"

bash "$SCRIPT" --task-id 1 --findings "$FINDINGS_BLOCK"
assert_file_contains "${TASKS_DIR}/task-001.md" "## Quick Check" "task-001.md has ## Quick Check"
assert_file_contains "${TASKS_DIR}/task-001.md" "[HIGH]" "findings block written to task-001.md"
assert_file_contains "${TASKS_DIR}/task-001.md" "Deferred-to-gate" "status in findings"

FINDINGS_BLOCK2="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [CRITICAL] | null deref on empty input | Fixed-on-spot |"

bash "$SCRIPT" --task-id 2 --findings "$FINDINGS_BLOCK2"
assert_file_contains "${TASKS_DIR}/task-002.md" "[CRITICAL]" "task-002.md critical finding written"
assert_file_contains "${TASKS_DIR}/task-002.md" "Fixed-on-spot" "fixed-on-spot status in task-002"

# Verify other sections not disturbed
assert_file_contains "${TASKS_DIR}/task-001.md" "## Status" "## Status section preserved after findings write"
assert_file_contains "${TASKS_DIR}/task-001.md" "## Dispatches" "## Dispatches section preserved"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: --delivery-id --block ==="

GATE_BLOCK="**Tier:** Small
**Grade:** A+
**Cycles:** 1
**Date:** 2026-05-24

### Gate Issues
(none)

**Result:** PASS"

bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK"
# Gate task is the highest-numbered: task-005.md
assert_file_contains "${TASKS_DIR}/task-005.md" "## Delivery Gate" "task-005.md has ## Delivery Gate"
assert_file_contains "${TASKS_DIR}/task-005.md" "**Grade:** A+" "grade in gate block"
assert_file_contains "${TASKS_DIR}/task-005.md" "PASS" "PASS in gate block"

# Re-run with different grade to verify replace (not append)
GATE_BLOCK2="**Tier:** Medium
**Grade:** A
**Cycles:** 2
**Date:** 2026-05-24

### Gate Issues
| # | Severity | Description |
|---|----------|-------------|
| 1 | [LOW] | minor style issue |

**Result:** PASS"

bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
assert_file_contains "${TASKS_DIR}/task-005.md" "**Grade:** A" "gate block replaced — grade A present"
assert_file_not_contains "${TASKS_DIR}/task-005.md" "**Grade:** A+" "old grade A+ removed"
assert_file_contains "${TASKS_DIR}/task-005.md" "**Cycles:** 2" "cycle count updated"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: --delivery-id --append-issue ==="

ISSUES_FILE="${WORK_DIR}/delivery-001-issues.md"

ROW1="| task-003 | [HIGH] | error path not covered by a test | Open |"
ROW2="| task-005 | [HIGH] | naming deviates from coding-standards | Open |"

bash "$SCRIPT" --delivery-id 1 --append-issue "$ROW1"
assert_file_contains "$ISSUES_FILE" "task-003" "delivery-001-issues.md created with row1"
assert_file_contains "$ISSUES_FILE" "# Delivery Issue Log" "header present"
assert_file_contains "$ISSUES_FILE" "Source task" "table header present"

bash "$SCRIPT" --delivery-id 1 --append-issue "$ROW2"
assert_file_contains "$ISSUES_FILE" "task-005" "second row appended"
assert_file_contains "$ISSUES_FILE" "naming deviates" "row2 content present"

# Both rows must be present
assert_file_contains "$ISSUES_FILE" "task-003" "row1 still present after row2 append"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: Idempotency ==="

# Re-run field update with same value — file size must not change
BEFORE=$(wc -c < "$AID_STATE_FILE")
run_field 1 Status "In Progress"
AFTER=$(wc -c < "$AID_STATE_FILE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "field mode: idempotent — same value, no size change"
else
    fail "field mode: not idempotent — size changed from $BEFORE to $AFTER"
fi

# Re-run findings with same block — file size must not change
BEFORE=$(wc -c < "${TASKS_DIR}/task-001.md")
bash "$SCRIPT" --task-id 1 --findings "$FINDINGS_BLOCK"
AFTER=$(wc -c < "${TASKS_DIR}/task-001.md")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "findings mode: idempotent — same block, no size change"
else
    fail "findings mode: not idempotent — size changed from $BEFORE to $AFTER"
fi

# Re-run append-issue with same row — must be no-op (no duplicate row)
BEFORE=$(grep -c "task-003" "$ISSUES_FILE")
bash "$SCRIPT" --delivery-id 1 --append-issue "$ROW1"
AFTER=$(grep -c "task-003" "$ISSUES_FILE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "append-issue: idempotent — duplicate row not added"
else
    fail "append-issue: not idempotent — row count changed from $BEFORE to $AFTER"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: Concurrent lock contention (5 parallel processes) ==="

# Each of 5 processes updates a different task row (row 1..5).
# After all 5 complete the STATE.md must have all 5 status values.
# Reset the STATE.md to a clean 5-row state first.
cat > "$AID_STATE_FILE" <<'STATEOF2'
# Work State — work-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | — | — | — |
| 002 | task-002-bravo | TEST | 1 | Pending | — | — | — |
| 003 | task-003-charlie | DESIGN | 2 | Pending | — | — | — |
| 004 | task-004-delta | DOCUMENT | 2 | Pending | — | — | — |
| 005 | task-005-echo | REFACTOR | 3 | Pending | — | — | — |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
STATEOF2

# Remove stale lock if any
rm -f "${WORK_DIR}/.writeback-task-status.lock"

# Launch 5 concurrent writers
(
    bash "$SCRIPT" --task-id 1 --field Status --value "Done-P1" &
    bash "$SCRIPT" --task-id 2 --field Status --value "Done-P2" &
    bash "$SCRIPT" --task-id 3 --field Status --value "Done-P3" &
    bash "$SCRIPT" --task-id 4 --field Status --value "Done-P4" &
    bash "$SCRIPT" --task-id 5 --field Status --value "Done-P5" &
    wait
)

# All 5 status values must appear in the file
ALL_OK=1
for i in 1 2 3 4 5; do
    if grep -qF "Done-P${i}" "$AID_STATE_FILE"; then
        pass "concurrent P${i} write present (Done-P${i})"
    else
        fail "concurrent P${i} write MISSING from STATE.md"
        ALL_OK=0
    fi
done

# No corruption: still has the Tasks Status header
assert_file_contains "$AID_STATE_FILE" "## Tasks Status" "Tasks Status section intact after concurrent writes"

# No duplicate rows: each task appears exactly once
for i in 1 2 3 4 5; do
    count=$(grep -c "task-00${i}-" "$AID_STATE_FILE" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "task-00${i} row appears exactly once (no duplication)"
    else
        fail "task-00${i} row appears $count times (expected 1)"
    fi
done

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: Error paths ==="

# 7a: No arguments → exit non-zero
out=$( bash "$SCRIPT" 2>&1 ) || code=$?
assert_exit_nonzero "${code:-0}" "no args → non-zero exit"

# 7b: Missing --value with --field
code=0
bash "$SCRIPT" --task-id 1 --field Status 2>/dev/null || code=$?
assert_exit_nonzero "$code" "missing --value → exit 5"

# 7c: Invalid task-id (non-numeric)
code=0
bash "$SCRIPT" --task-id abc --field Status --value Done 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric task-id → exit 4"

# 7d: Unknown field name
code=0
bash "$SCRIPT" --task-id 1 --field NONEXISTENT --value x 2>/dev/null || code=$?
assert_exit_nonzero "$code" "unknown field name → exit 4"

# 7e: Task id not in STATE.md
code=0
bash "$SCRIPT" --task-id 999 --field Status --value x 2>/dev/null || code=$?
assert_exit_nonzero "$code" "task-id not in STATE.md → exit non-zero"

# 7f: Invalid delivery-id (non-numeric)
code=0
bash "$SCRIPT" --delivery-id xyz --append-issue "| a | b | c | d |" 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric delivery-id → exit 4"

# 7g: append-issue with non-table row
code=0
bash "$SCRIPT" --delivery-id 1 --append-issue "not a table row" 2>/dev/null || code=$?
assert_exit_nonzero "$code" "invalid issue row format → exit 4"

# 7h: Lock held — simulate contention timeout
LOCK_FILE="${WORK_DIR}/.writeback-task-status.lock"
echo "99999" > "$LOCK_FILE"
code=0
AID_LOCK_TIMEOUT=2 bash "$SCRIPT" --task-id 1 --field Status --value x 2>/dev/null || code=$?
assert_exit_nonzero "$code" "lock timeout → exit 2"
rm -f "$LOCK_FILE"

# 7i: STATE.md missing
SAVED="$AID_STATE_FILE"
export AID_STATE_FILE="${TMPDIR_BASE}/nonexistent/STATE.md"
code=0
bash "$SCRIPT" --task-id 1 --field Status --value x 2>/dev/null || code=$?
assert_exit_nonzero "$code" "STATE.md missing → exit 1"
export AID_STATE_FILE="$SAVED"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 8: H1 — schema mismatch (row has wrong column count) ==="

# Create a STATE.md with a task row that has only 6 columns instead of 8
BAD_STATE="${TMPDIR_BASE}/bad-state/STATE.md"
mkdir -p "${TMPDIR_BASE}/bad-state"
cat > "$BAD_STATE" <<'BADSTATEOF'
# Work State — work-test

## Tasks Status

| # | Task | Type | Wave | Status | Notes |
|---|------|------|------|--------|-------|
| 042 | task-042-bad | IMPLEMENT | 1 | Pending | — |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
BADSTATEOF

code=0
err_out=$(AID_STATE_FILE="$BAD_STATE" bash "$SCRIPT" --task-id 42 --field Status --value Done 2>&1) || code=$?
assert_exit_nonzero "$code" "H1 schema mismatch: wrong column count → exit 4"
if echo "$err_out" | grep -q "wrong column count"; then
    pass "H1 schema mismatch: error message mentions 'wrong column count'"
else
    fail "H1 schema mismatch: expected 'wrong column count' in error output, got: $err_out"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: H2 — --value containing literal '|' rejected ==="

code=0
err_out=$(bash "$SCRIPT" --task-id 1 --field Notes --value "a|b" 2>&1) || code=$?
assert_exit_nonzero "$code" "H2 pipe in --value → exit 4"
if echo "$err_out" | grep -q "cannot contain '|'"; then
    pass "H2 pipe in --value: error message mentions \"cannot contain '|'\""
else
    fail "H2 pipe in --value: expected \"cannot contain '|'\" in error output, got: $err_out"
fi

# Also test that the check fires before lock acquisition (STATE.md not modified)
BEFORE_SIZE=$(wc -c < "$AID_STATE_FILE")
bash "$SCRIPT" --task-id 1 --field Notes --value "pipe|here" 2>/dev/null || true
AFTER_SIZE=$(wc -c < "$AID_STATE_FILE")
if [[ "$BEFORE_SIZE" -eq "$AFTER_SIZE" ]]; then
    pass "H2 pipe rejection: STATE.md not modified"
else
    fail "H2 pipe rejection: STATE.md was modified despite pipe in value"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: M2 — missing lock directory detected before contention ==="

code=0
err_out=$(AID_LOCK_DIR="${TMPDIR_BASE}/nonexistent-lock-dir" bash "$SCRIPT" --task-id 1 --field Status --value Done 2>&1) || code=$?
assert_exit_nonzero "$code" "M2 missing lock dir → exit non-zero (exit 1)"
if echo "$err_out" | grep -q "lock directory does not exist"; then
    pass "M2 missing lock dir: error message mentions 'lock directory does not exist'"
else
    fail "M2 missing lock dir: expected 'lock directory does not exist' in error output, got: $err_out"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "  Tests passed: $PASS"
echo "  Tests failed: $FAIL"
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for e in "${ERRORS[@]}"; do
        echo "  - $e"
    done
    exit 1
fi
echo ""
echo "All tests passed."
exit 0
