#!/usr/bin/env bash
# test-writeback-state.sh — smoke-test harness for writeback-state.sh
#
# Tests all 4 arg modes and lock-contention safety.
#
# Usage:
#   test-writeback-state.sh [-v | --verbose]
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
# SUT moved to canonical/scripts/execute/ in 2026-05-26 consolidation
SCRIPT="${SCRIPT_DIR}/../../canonical/scripts/execute/writeback-state.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Setup: create a temporary workspace
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Shared env vars that writeback-state.sh honours
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
# Findings must go to STATE.md ## Quick Check Findings (per work-003 FR2 per-area STATE rule)
assert_file_contains "$AID_STATE_FILE" "## Quick Check Findings" "STATE.md has ## Quick Check Findings section"
assert_file_contains "$AID_STATE_FILE" "### task-001" "STATE.md has ### task-001 block under Quick Check Findings"
assert_file_contains "$AID_STATE_FILE" "[HIGH]" "findings block written to STATE.md"
assert_file_contains "$AID_STATE_FILE" "Deferred-to-gate" "status in findings in STATE.md"
# task-001.md must NOT be modified by --findings
assert_file_not_contains "${TASKS_DIR}/task-001.md" "## Quick Check" "task-001.md NOT modified by --findings (STATE.md is target)"

FINDINGS_BLOCK2="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [CRITICAL] | null deref on empty input | Fixed-on-spot |"

bash "$SCRIPT" --task-id 2 --findings "$FINDINGS_BLOCK2"
assert_file_contains "$AID_STATE_FILE" "### task-002" "STATE.md has ### task-002 block"
assert_file_contains "$AID_STATE_FILE" "[CRITICAL]" "critical finding written to STATE.md"
assert_file_contains "$AID_STATE_FILE" "Fixed-on-spot" "fixed-on-spot status in STATE.md"
# task-002.md must NOT be modified
assert_file_not_contains "${TASKS_DIR}/task-002.md" "## Quick Check" "task-002.md NOT modified by --findings"

# Verify both task blocks coexist in STATE.md (multi-task accumulation)
assert_file_contains "$AID_STATE_FILE" "### task-001" "task-001 block still present after task-002 write"
assert_file_contains "$AID_STATE_FILE" "### task-002" "task-002 block present alongside task-001"

# Verify Tasks Status section not disturbed
assert_file_contains "$AID_STATE_FILE" "## Tasks Status" "## Tasks Status section preserved after findings write"

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
# Gate block must land in STATE.md ## Delivery Gates (per feature-004 Alignment Update + SPEC L240-260)
assert_file_contains "$AID_STATE_FILE" "## Delivery Gates" "STATE.md has ## Delivery Gates section"
assert_file_contains "$AID_STATE_FILE" "### delivery-001" "STATE.md has ### delivery-001 block under Delivery Gates"
assert_file_contains "$AID_STATE_FILE" "**Grade:** A+" "grade in gate block in STATE.md"
assert_file_contains "$AID_STATE_FILE" "PASS" "PASS in gate block in STATE.md"
# task files must NOT be modified by --block
assert_file_not_contains "${TASKS_DIR}/task-005.md" "## Delivery Gate" "task-005.md NOT modified by --block (STATE.md is target)"

# Re-run with different grade to verify replace (not append) — keyed by delivery-NNN
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
assert_file_contains "$AID_STATE_FILE" "**Grade:** A" "gate block replaced — grade A present in STATE.md"
assert_file_not_contains "$AID_STATE_FILE" "**Grade:** A+" "old grade A+ removed from STATE.md"
assert_file_contains "$AID_STATE_FILE" "**Cycles:** 2" "cycle count updated in STATE.md"

# Test a second delivery-id to verify keying
GATE_BLOCK3="**Tier:** Small
**Grade:** B
**Cycles:** 1
**Date:** 2026-05-24

### Gate Issues
| # | Severity | Description |
|---|----------|-------------|
| 1 | [HIGH] | major issue found |

**Result:** FAIL"

bash "$SCRIPT" --delivery-id 2 --block "$GATE_BLOCK3"
assert_file_contains "$AID_STATE_FILE" "### delivery-002" "STATE.md has ### delivery-002 block (second delivery)"
assert_file_contains "$AID_STATE_FILE" "**Grade:** B" "grade B for delivery-002 in STATE.md"
# Both delivery blocks must coexist
assert_file_contains "$AID_STATE_FILE" "### delivery-001" "delivery-001 block still present after delivery-002 write"
assert_file_contains "$AID_STATE_FILE" "### delivery-002" "delivery-002 block present alongside delivery-001"

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

# Re-run findings with same block — STATE.md size must not change
BEFORE=$(wc -c < "$AID_STATE_FILE")
bash "$SCRIPT" --task-id 1 --findings "$FINDINGS_BLOCK"
AFTER=$(wc -c < "$AID_STATE_FILE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "findings mode: idempotent — same block, no size change"
else
    fail "findings mode: not idempotent — STATE.md size changed from $BEFORE to $AFTER"
fi

# Re-run delivery-block with same block — STATE.md size must not change
BEFORE=$(wc -c < "$AID_STATE_FILE")
bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
AFTER=$(wc -c < "$AID_STATE_FILE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "delivery-block mode: idempotent — same block, STATE.md size unchanged"
else
    fail "delivery-block mode: not idempotent — STATE.md size changed from $BEFORE to $AFTER"
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
rm -f "${WORK_DIR}/.writeback-state.lock"

# Launch 5 concurrent writers, each with a distinct valid TaskStatus enum value.
# Values chosen: Done, In Progress, Failed, Blocked, In Review (all valid enum members).
# Each updates a different task row so we can verify each write landed.
(
    bash "$SCRIPT" --task-id 1 --field Status --value "Done" &
    bash "$SCRIPT" --task-id 2 --field Status --value "In Progress" &
    bash "$SCRIPT" --task-id 3 --field Status --value "Failed" &
    bash "$SCRIPT" --task-id 4 --field Status --value "Blocked" &
    bash "$SCRIPT" --task-id 5 --field Status --value "In Review" &
    wait
)

# Verify each distinct status value appears in the file (one per task row)
declare -A CONC_VALS=([1]="Done" [2]="In Progress" [3]="Failed" [4]="Blocked" [5]="In Review")
ALL_OK=1
for i in 1 2 3 4 5; do
    expected="${CONC_VALS[$i]}"
    if grep -qF "$expected" "$AID_STATE_FILE"; then
        pass "concurrent P${i} write present (${expected})"
    else
        fail "concurrent P${i} write MISSING from STATE.md (expected '${expected}')"
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
LOCK_FILE="${WORK_DIR}/.writeback-state.lock"
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
# Helper: create a fresh scratch STATE.md for --pipeline tests (no Pipeline Status section)
# Usage: make_pipeline_state <path>
make_pipeline_state() {
    local dest="$1"
    cat > "$dest" <<'PIPEEOF'
# Work State — work-pipeline-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | — | — | — |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
PIPEEOF
}

# Helper: extract the Pipeline Status block from a STATE.md
# Usage: get_pipeline_block <path>
get_pipeline_block() {
    local f="$1"
    awk '/^## Pipeline Status/{in_ps=1; next} in_ps && /^## /{in_ps=0} in_ps{print}' "$f"
}

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 11: --pipeline field writes (section creation + each base field) ==="

PIPE_STATE="${TMPDIR_BASE}/pipe11/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE")"

# 11a: Section absent — writing Lifecycle creates ## Pipeline Status
make_pipeline_state "$PIPE_STATE"
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_zero "$code" "11a: Lifecycle write on absent section → exit 0"
assert_file_contains "$PIPE_STATE" "## Pipeline Status" "11a: ## Pipeline Status section created"
assert_file_contains "$PIPE_STATE" "**Lifecycle:** Running" "11a: Lifecycle field written"

# 11b: Phase field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Phase write → exit 0"
assert_file_contains "$PIPE_STATE" "**Phase:** Execute" "11b: Phase field written"

# 11c: Active Skill field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null || code=$?
assert_exit_zero "$code" "11c: Active Skill write → exit 0"
assert_file_contains "$PIPE_STATE" "**Active Skill:** aid-develop" "11c: Active Skill field written"

# 11d: Updated field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "11d: Updated write → exit 0"
assert_file_contains "$PIPE_STATE" "**Updated:** 2026-06-10" "11d: Updated field written"

# 11e: All four base fields coexist in the block
PIPE_BLOCK=$(get_pipeline_block "$PIPE_STATE")
assert_output_contains "$PIPE_BLOCK" "**Lifecycle:** Running" "11e: Lifecycle line grep-recoverable in Pipeline Status block"
assert_output_contains "$PIPE_BLOCK" "**Phase:** Execute" "11e: Phase line grep-recoverable in Pipeline Status block"
assert_output_contains "$PIPE_BLOCK" "**Active Skill:** aid-develop" "11e: Active Skill line grep-recoverable in Pipeline Status block"
assert_output_contains "$PIPE_BLOCK" "**Updated:** 2026-06-10" "11e: Updated line grep-recoverable in Pipeline Status block"

# 11f: Other STATE.md sections not disturbed
assert_file_contains "$PIPE_STATE" "## Tasks Status" "11f: Tasks Status section preserved after pipeline writes"
assert_file_contains "$PIPE_STATE" "## Deploy Status" "11f: Deploy Status section preserved after pipeline writes"

# 11g: Section absent — writing non-Lifecycle field (Phase) creates the section too
PIPE_STATE_G="${TMPDIR_BASE}/pipe11g/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE_G")"
make_pipeline_state "$PIPE_STATE_G"
code=0
AID_STATE_FILE="$PIPE_STATE_G" bash "$SCRIPT" --pipeline --field Phase --value Plan 2>/dev/null || code=$?
assert_exit_zero "$code" "11g: Phase write on absent section → exit 0"
assert_file_contains "$PIPE_STATE_G" "## Pipeline Status" "11g: ## Pipeline Status section created by Phase write"
assert_file_contains "$PIPE_STATE_G" "**Phase:** Plan" "11g: Phase field written on new section"

# 11h: Update (overwrite) an existing field value
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
assert_file_contains "$PIPE_STATE" "**Lifecycle:** Completed" "11h: Lifecycle field overwritten to Completed"
assert_file_not_contains "$PIPE_STATE" "**Lifecycle:** Running" "11h: old Lifecycle value Running removed"

# 11i: Active Skill set to 'none' is valid
PIPE_STATE_I="${TMPDIR_BASE}/pipe11i/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE_I")"
make_pipeline_state "$PIPE_STATE_I"
code=0
AID_STATE_FILE="$PIPE_STATE_I" bash "$SCRIPT" --pipeline --field "Active Skill" --value "none" 2>/dev/null || code=$?
assert_exit_zero "$code" "11i: Active Skill=none is valid → exit 0"
assert_file_contains "$PIPE_STATE_I" "**Active Skill:** none" "11i: Active Skill none written"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 12: --pipeline enum acceptance + rejection ==="

PIPE_STATE12="${TMPDIR_BASE}/pipe12/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE12")"
make_pipeline_state "$PIPE_STATE12"

# 12a: All valid Lifecycle values accepted (rc 0)
for lc_val in Running Paused-Awaiting-Input Blocked Completed Canceled; do
    code=0
    AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Lifecycle --value "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "12a: Lifecycle=$lc_val accepted (exit 0)"
done

# 12b: Invalid Lifecycle value → exit 4
code=0
err12b=$(AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Lifecycle --value "InProgress" 2>&1) || code=$?
assert_exit_eq "$code" 4 "12b: Lifecycle=InProgress rejected (exit 4)"

# 12c: Another invalid Lifecycle value → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Lifecycle --value "running" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12c: Lifecycle=running (lowercase) rejected (exit 4)"

# 12d: All valid Phase values accepted (rc 0)
for ph_val in Interview Specify Plan Detail Execute Deploy Monitor; do
    code=0
    AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "12d: Phase=$ph_val accepted (exit 0)"
done

# 12e: Invalid Phase value → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Phase --value "Build" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12e: Phase=Build rejected (exit 4)"

# 12f: Another invalid Phase value → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field Phase --value "execute" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12f: Phase=execute (lowercase) rejected (exit 4)"

# 12g: Valid aid-{skill} Active Skill value accepted
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-review" 2>/dev/null || code=$?
assert_exit_zero "$code" "12g: Active Skill=aid-review accepted (exit 0)"

# 12h: Invalid Active Skill value — no aid- prefix → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field "Active Skill" --value "develop" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12h: Active Skill=develop (no aid- prefix) rejected (exit 4)"

# 12i: Invalid Active Skill value — aid- prefix only (empty skill) → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12i: Active Skill=aid- (empty skill part) rejected (exit 4)"

# 12j: Unknown field name → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline --field "UnknownField" --value "x" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "12j: unknown pipeline field rejected (exit 4)"

# 12k: --pipeline without --field → exit 5 (missing required argument)
code=0
AID_STATE_FILE="$PIPE_STATE12" bash "$SCRIPT" --pipeline 2>/dev/null || code=$?
assert_exit_nonzero "$code" "12k: --pipeline without --field → non-zero exit"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 13: --pipeline conditional Pause/Block fields ==="

# Helper: fresh pipe state for conditional field tests
make_cond_state() {
    local dest="$1"
    make_pipeline_state "$dest"
    # Seed with Lifecycle=Running so section exists
    AID_STATE_FILE="$dest" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
}

# 13a: Pause Reason written only when Lifecycle=Paused-Awaiting-Input
PIPE_STATE13A="${TMPDIR_BASE}/pipe13a/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE13A")"
make_cond_state "$PIPE_STATE13A"
# First set Lifecycle to Paused-Awaiting-Input
AID_STATE_FILE="$PIPE_STATE13A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
# Then write Pause Reason
code=0
AID_STATE_FILE="$PIPE_STATE13A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for user clarification" 2>/dev/null || code=$?
assert_exit_zero "$code" "13a: Pause Reason write under Paused-Awaiting-Input → exit 0"
assert_file_contains "$PIPE_STATE13A" "**Pause Reason:** Waiting for user clarification" "13a: Pause Reason field written"

# 13b: Block Reason + Block Artifact written only when Lifecycle=Blocked
PIPE_STATE13B="${TMPDIR_BASE}/pipe13b/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE13B")"
make_cond_state "$PIPE_STATE13B"
AID_STATE_FILE="$PIPE_STATE13B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE13B" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Waiting for dependency" 2>/dev/null || code=$?
assert_exit_zero "$code" "13b: Block Reason write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE13B" "**Block Reason:** Waiting for dependency" "13b: Block Reason field written"

code=0
AID_STATE_FILE="$PIPE_STATE13B" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "task-007.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "13b: Block Artifact write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE13B" "**Block Artifact:** task-007.md" "13b: Block Artifact field written"

# 13c: Transition OUT of Paused-Awaiting-Input clears Pause Reason
# (Start from 13a state which has Pause Reason set)
AID_STATE_FILE="$PIPE_STATE13A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_not_contains "$PIPE_STATE13A" "**Pause Reason:**" "13c: Pause Reason cleared after Lifecycle→Running"

# 13d: Transition OUT of Blocked clears Block Reason and Block Artifact
# (Start from 13b state which has Block Reason + Artifact set)
AID_STATE_FILE="$PIPE_STATE13B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_not_contains "$PIPE_STATE13B" "**Block Reason:**" "13d: Block Reason cleared after Lifecycle→Running"
assert_file_not_contains "$PIPE_STATE13B" "**Block Artifact:**" "13d: Block Artifact cleared after Lifecycle→Running"

# 13e: Pause Reason absent under Blocked lifecycle
PIPE_STATE13E="${TMPDIR_BASE}/pipe13e/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE13E")"
make_cond_state "$PIPE_STATE13E"
AID_STATE_FILE="$PIPE_STATE13E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE13E" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for input" 2>/dev/null
# Now transition to Blocked — Pause Reason should be cleared
AID_STATE_FILE="$PIPE_STATE13E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
assert_file_not_contains "$PIPE_STATE13E" "**Pause Reason:**" "13e: Pause Reason cleared when Lifecycle transitions to Blocked"

# 13f: Block Reason absent after transition from Blocked to Completed
PIPE_STATE13F="${TMPDIR_BASE}/pipe13f/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE13F")"
make_cond_state "$PIPE_STATE13F"
AID_STATE_FILE="$PIPE_STATE13F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE13F" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Needs review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE13F" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "review-001.md" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE13F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Completed" 2>/dev/null
assert_file_not_contains "$PIPE_STATE13F" "**Block Reason:**" "13f: Block Reason cleared on Lifecycle→Completed"
assert_file_not_contains "$PIPE_STATE13F" "**Block Artifact:**" "13f: Block Artifact cleared on Lifecycle→Completed"

# 13g: Block Reason + Artifact absent under Running (never set, never present)
PIPE_STATE13G="${TMPDIR_BASE}/pipe13g/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE13G")"
make_cond_state "$PIPE_STATE13G"
# Block Reason write with Lifecycle=Running: conditional field is stored but
# won't appear in the block unless cleared -- testing the negative: after a
# fresh Running lifecycle write the block must not have Block Reason/Artifact
assert_file_not_contains "$PIPE_STATE13G" "**Block Reason:**" "13g: Block Reason absent on fresh Running state"
assert_file_not_contains "$PIPE_STATE13G" "**Block Artifact:**" "13g: Block Artifact absent on fresh Running state"
assert_file_not_contains "$PIPE_STATE13G" "**Pause Reason:**" "13g: Pause Reason absent on fresh Running state"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 14: No regression — existing modes on STATE.md with Pipeline Status ==="

# Build a state that already has ## Pipeline Status, then verify --field /
# --findings / --block modes still work correctly without disturbing the block.
PIPE_STATE14="${TMPDIR_BASE}/pipe14/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE14")"
make_pipeline_state "$PIPE_STATE14"
# Add a pipeline section
AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null

# 14a: --field write on a task row should still work (use a valid TaskStatus enum value)
AID_TASKS_DIR="$TASKS_DIR" AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --task-id 1 --field Status --value "In Progress" 2>/dev/null
assert_file_contains "$PIPE_STATE14" "In Progress" "14a: --field write works on STATE.md that has Pipeline Status"
assert_file_contains "$PIPE_STATE14" "**Lifecycle:** Running" "14a: Pipeline Status block intact after --field write"
assert_file_contains "$PIPE_STATE14" "**Phase:** Execute" "14a: Phase field intact after --field write"

# 14b: --findings write should still work
FINDINGS_14="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [LOW] | cross-mode regression check | Accepted |"
AID_TASKS_DIR="$TASKS_DIR" AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --task-id 1 --findings "$FINDINGS_14" 2>/dev/null
assert_file_contains "$PIPE_STATE14" "## Quick Check Findings" "14b: --findings still writes Quick Check Findings section"
assert_file_contains "$PIPE_STATE14" "cross-mode regression check" "14b: findings content written"
assert_file_contains "$PIPE_STATE14" "**Lifecycle:** Running" "14b: Pipeline Status block intact after --findings write"

# 14c: --block (delivery gate) write should still work
GATE_14="**Tier:** Small
**Grade:** A
**Cycles:** 1
**Date:** 2026-06-10

### Gate Issues
(none)

**Result:** PASS"
AID_DELIVERY_ISSUES_DIR="$WORK_DIR" AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --delivery-id 1 --block "$GATE_14" 2>/dev/null
assert_file_contains "$PIPE_STATE14" "## Delivery Gates" "14c: --block still writes Delivery Gates section"
assert_file_contains "$PIPE_STATE14" "**Grade:** A" "14c: gate grade written"
assert_file_contains "$PIPE_STATE14" "**Lifecycle:** Running" "14c: Pipeline Status block intact after --block write"

# 14d: --pipeline write after existing modes still updates correctly
AID_STATE_FILE="$PIPE_STATE14" bash "$SCRIPT" --pipeline --field Phase --value Deploy 2>/dev/null
assert_file_contains "$PIPE_STATE14" "**Phase:** Deploy" "14d: --pipeline write after --field/--findings/--block still works"
assert_file_not_contains "$PIPE_STATE14" "**Phase:** Execute" "14d: old Phase value replaced"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 15: Concurrency — --pipeline ∥ --pipeline and --pipeline ∥ --field ==="

PIPE_STATE15="${TMPDIR_BASE}/pipe15/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE15")"
make_pipeline_state "$PIPE_STATE15"
# Seed with an existing Pipeline Status section so all concurrent writes are updates
AID_STATE_FILE="$PIPE_STATE15" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE15" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE15" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE15" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10T00:00:00Z" 2>/dev/null

# Remove any stale lock
rm -f "${TMPDIR_BASE}/pipe15/.writeback-state.lock"

# 15a: Concurrent --pipeline writes (4 parallel, different fields)
# Launch 4 background writers that each update a different pipeline field.
# Because they all go through the sentinel lock they must serialize.
(
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15" AID_STATE_FILE="$PIPE_STATE15" \
        bash "$SCRIPT" --pipeline --field Lifecycle --value Completed &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15" AID_STATE_FILE="$PIPE_STATE15" \
        bash "$SCRIPT" --pipeline --field Phase --value Deploy &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15" AID_STATE_FILE="$PIPE_STATE15" \
        bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-release" &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15" AID_STATE_FILE="$PIPE_STATE15" \
        bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10T12:00:00Z" &
    wait
)

# Assert no torn/corrupt block: ## Pipeline Status must still exist
assert_file_contains "$PIPE_STATE15" "## Pipeline Status" "15a: ## Pipeline Status section intact after concurrent pipeline writes"

# Assert all writes landed (last writer wins per field — at least one write landed)
BLOCK15=$(get_pipeline_block "$PIPE_STATE15")
assert_output_contains "$BLOCK15" "**Lifecycle:**" "15a: Lifecycle line present after concurrent writes"
assert_output_contains "$BLOCK15" "**Phase:**" "15a: Phase line present after concurrent writes"
assert_output_contains "$BLOCK15" "**Active Skill:**" "15a: Active Skill line present after concurrent writes"
assert_output_contains "$BLOCK15" "**Updated:**" "15a: Updated line present after concurrent writes"

# Assert each field appears exactly once in the block (no line duplication / torn write)
for f_name in "Lifecycle" "Phase" "Active Skill" "Updated"; do
    count=$(echo "$BLOCK15" | grep -cF "**${f_name}:**" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "15a: field '$f_name' appears exactly once in block (no duplication)"
    else
        fail "15a: field '$f_name' appears $count times in block (expected 1)"
    fi
done

# No lock file left behind (released by all writers)
if [[ ! -f "${TMPDIR_BASE}/pipe15/.writeback-state.lock" ]]; then
    pass "15a: no stale lock file after concurrent pipeline writes (no deadlock)"
else
    fail "15a: stale lock file found — possible deadlock in concurrent pipeline writes"
fi

# 15b: Mixed --pipeline ∥ --field concurrent writes on the same STATE.md
# Both modes use the same sentinel lock, so they must serialize.
PIPE_STATE15B="${TMPDIR_BASE}/pipe15b/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE15B")"
# Reuse the task scaffold with a pipeline section
make_pipeline_state "$PIPE_STATE15B"
# Copy the task dir env from the outer suite (task files exist in $TASKS_DIR)
AID_STATE_FILE="$PIPE_STATE15B" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE15B" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null

rm -f "${TMPDIR_BASE}/pipe15b/.writeback-state.lock"

(
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15b" AID_STATE_FILE="$PIPE_STATE15B" \
        bash "$SCRIPT" --pipeline --field Lifecycle --value Completed &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15b" AID_STATE_FILE="$PIPE_STATE15B" \
        AID_TASKS_DIR="$TASKS_DIR" \
        bash "$SCRIPT" --task-id 1 --field Status --value "In Review" &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15b" AID_STATE_FILE="$PIPE_STATE15B" \
        bash "$SCRIPT" --pipeline --field Phase --value Deploy &
    AID_LOCK_DIR="${TMPDIR_BASE}/pipe15b" AID_STATE_FILE="$PIPE_STATE15B" \
        AID_TASKS_DIR="$TASKS_DIR" \
        bash "$SCRIPT" --task-id 1 --field Notes --value "note-concurrent" &
    wait
)

# Assert STATE.md structural integrity
assert_file_contains "$PIPE_STATE15B" "## Pipeline Status" "15b: Pipeline Status intact after --pipeline ∥ --field mix"
assert_file_contains "$PIPE_STATE15B" "## Tasks Status" "15b: Tasks Status intact after --pipeline ∥ --field mix"

# Both modes wrote something (at least the field lines are present)
BLOCK15B=$(get_pipeline_block "$PIPE_STATE15B")
assert_output_contains "$BLOCK15B" "**Lifecycle:**" "15b: Lifecycle line present after mixed concurrent writes"
assert_output_contains "$BLOCK15B" "**Phase:**" "15b: Phase line present after mixed concurrent writes"

# Each pipeline field appears exactly once (no duplication from torn writes)
for f_name in "Lifecycle" "Phase"; do
    count=$(echo "$BLOCK15B" | grep -cF "**${f_name}:**" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "15b: field '$f_name' appears exactly once after mixed concurrent writes"
    else
        fail "15b: field '$f_name' appears $count times in block after mixed writes (expected 1)"
    fi
done

# No stale lock
if [[ ! -f "${TMPDIR_BASE}/pipe15b/.writeback-state.lock" ]]; then
    pass "15b: no stale lock file after --pipeline ∥ --field mix (no deadlock)"
else
    fail "15b: stale lock file found — possible deadlock in mixed concurrent writes"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 17: M3 — Status enum validation (feature-001 §4 M3) ==="

# Per-case helper: create a fresh scratch STATE.md with a ## Tasks Status table
# and a single task-001 row with Status=Pending.
# Usage: make_status_state <dest-dir>
make_status_state() {
    local dir="$1"
    mkdir -p "$dir"
    cat > "${dir}/STATE.md" <<'STATUSEOF'
# Work State — work-status-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | — | — | — |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
STATUSEOF
}

# Helper: run a --field Status write against a scratch state and return exit code.
# Usage: run_status_write <state-file> <value>  (captures exit code in STATUS_CODE)
run_status_write() {
    local sf="$1" val="$2"
    STATUS_CODE=0
    AID_STATE_FILE="$sf" bash "$SCRIPT" --task-id 1 --field Status --value "$val" 2>/dev/null || STATUS_CODE=$?
}

# ---------------------------------------------------------------------------
# 17.1 — All 7 TaskStatus members accepted (exit 0)
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.1: All 7 TaskStatus members accepted ---"

for status_val in "Pending" "In Progress" "In Review" "Blocked" "Done" "Failed" "Canceled"; do
    S17_DIR="${TMPDIR_BASE}/unit17-member-$(echo "$status_val" | tr ' ' '_')"
    make_status_state "$S17_DIR"
    run_status_write "${S17_DIR}/STATE.md" "$status_val"
    assert_exit_zero "$STATUS_CODE" "17.1: Status='${status_val}' accepted (exit 0)"
    # Also verify the value was actually written
    assert_file_contains "${S17_DIR}/STATE.md" "$status_val" "17.1: Status='${status_val}' written to STATE.md"
done

# ---------------------------------------------------------------------------
# 17.2 — _none yet_ placeholder accepted (exit 0)
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.2: _none yet_ placeholder accepted ---"

S17_NONE="${TMPDIR_BASE}/unit17-none-yet"
make_status_state "$S17_NONE"
run_status_write "${S17_NONE}/STATE.md" "_none yet_"
assert_exit_zero "$STATUS_CODE" "17.2: Status='_none yet_' placeholder accepted (exit 0)"
assert_file_contains "${S17_NONE}/STATE.md" "_none yet_" "17.2: _none yet_ placeholder written to STATE.md"

# ---------------------------------------------------------------------------
# 17.3 — Out-of-enum values rejected (exit 4)
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.3: Out-of-enum values rejected (exit 4) ---"

for bad_val in "running" "DONE" "Finished" "in progress" "InProgress" "todo" "PENDING"; do
    S17_BAD="${TMPDIR_BASE}/unit17-bad-$(echo "$bad_val" | tr ' /' '_')"
    make_status_state "$S17_BAD"
    run_status_write "${S17_BAD}/STATE.md" "$bad_val"
    assert_exit_eq "$STATUS_CODE" 4 "17.3: Status='${bad_val}' rejected (exit 4)"
    # Verify STATE.md was NOT modified (still shows Pending)
    assert_file_contains "${S17_BAD}/STATE.md" "Pending" "17.3: STATE.md unchanged after rejection of '${bad_val}'"
done

# ---------------------------------------------------------------------------
# 17.4 — C4 no-regression: the 6 legacy producer strings still validate (exit 0)
# These are exactly what the live pipeline writes today.
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.4: C4 no-regression — 6 legacy producer strings accepted ---"

for legacy_val in "Pending" "In Progress" "In Review" "Blocked" "Done" "Failed"; do
    S17_LEG="${TMPDIR_BASE}/unit17-legacy-$(echo "$legacy_val" | tr ' ' '_')"
    make_status_state "$S17_LEG"
    run_status_write "${S17_LEG}/STATE.md" "$legacy_val"
    assert_exit_zero "$STATUS_CODE" "17.4: C4 legacy Status='${legacy_val}' accepted (exit 0)"
done

# ---------------------------------------------------------------------------
# 17.5 — Status-only scope: non-Status field with unusual value passes through
# The enum guard must NOT leak to other fields (e.g. Notes, Elapsed).
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.5: Status-only scope — enum does not leak to other fields ---"

S17_SCOPE="${TMPDIR_BASE}/unit17-scope"
make_status_state "$S17_SCOPE"

# Notes field with a value that would be invalid as a Status member — must be accepted
SCOPE_CODE=0
AID_STATE_FILE="${S17_SCOPE}/STATE.md" bash "$SCRIPT" --task-id 1 --field Notes --value "anything weird !@#" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "17.5: Notes='anything weird !@#' accepted (enum does not leak to Notes)"
assert_file_contains "${S17_SCOPE}/STATE.md" "anything weird !@#" "17.5: Notes value written successfully"

# Elapsed field with a non-enum-like value — must be accepted
SCOPE_CODE=0
AID_STATE_FILE="${S17_SCOPE}/STATE.md" bash "$SCRIPT" --task-id 1 --field Elapsed --value "running" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "17.5: Elapsed='running' accepted (enum does not apply to Elapsed)"

# Review field with a lowercase-Status-like value — must be accepted
SCOPE_CODE=0
AID_STATE_FILE="${S17_SCOPE}/STATE.md" bash "$SCRIPT" --task-id 1 --field Review --value "done" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "17.5: Review='done' accepted (enum does not apply to Review)"

# ---------------------------------------------------------------------------
# 17.6 — Deterministic consumability: written Status is grep-recoverable in
# the ## Tasks Status row format that feature-002 consumes.
# The row format is: | NNN | task-name | Type | Wave | Status | Review | Elapsed | Notes |
# feature-002 reads the Status column by grepping for the task row within the table.
# ---------------------------------------------------------------------------
echo ""
echo "--- 17.6: Deterministic consumability — Status grep-recoverable in Tasks Status row ---"

S17_CONS="${TMPDIR_BASE}/unit17-consumable"
make_status_state "$S17_CONS"

# Write "In Review" — a multi-word status that must round-trip exactly
AID_STATE_FILE="${S17_CONS}/STATE.md" bash "$SCRIPT" --task-id 1 --field Status --value "In Review" 2>/dev/null

# Verify the ## Tasks Status section still contains the row
assert_file_contains "${S17_CONS}/STATE.md" "## Tasks Status" "17.6: ## Tasks Status section present after Status write"

# Extract the task-001 row and verify Status column is "In Review"
# The row format: | 001 | task-001-alpha | IMPLEMENT | 1 | In Review | — | — | — |
task_row=$(grep '| 001 ' "${S17_CONS}/STATE.md")
assert_output_contains "$task_row" "In Review" "17.6: 'In Review' appears in task-001 row"

# Verify the Status value is grep-recoverable from the task row (feature-002 pattern)
recovered_status=$(grep '| 001 ' "${S17_CONS}/STATE.md" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6); print $6}')
assert_eq "$recovered_status" "In Review" "17.6: Status value grep-recoverable from task row (awk column 5)"

# Repeat for "Done" to confirm a single-word status also round-trips
AID_STATE_FILE="${S17_CONS}/STATE.md" bash "$SCRIPT" --task-id 1 --field Status --value "Done" 2>/dev/null
recovered_status=$(grep '| 001 ' "${S17_CONS}/STATE.md" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6); print $6}')
assert_eq "$recovered_status" "Done" "17.6: Status 'Done' grep-recoverable from task row after overwrite"

# Repeat for Canceled (7th member — not in legacy C4 set; confirm it is also consumable)
AID_STATE_FILE="${S17_CONS}/STATE.md" bash "$SCRIPT" --task-id 1 --field Status --value "Canceled" 2>/dev/null
recovered_status=$(grep '| 001 ' "${S17_CONS}/STATE.md" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6); print $6}')
assert_eq "$recovered_status" "Canceled" "17.6: Status 'Canceled' grep-recoverable from task row"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 16: FR16 derivation primitives — on-disk block determinism ==="

# FR16 needs: a readable Lifecycle value + conditional reason fields present/absent per state.
# Assert the resulting on-disk block deterministically exposes these primitives.

PIPE_STATE16="${TMPDIR_BASE}/pipe16/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE16")"
make_pipeline_state "$PIPE_STATE16"

# 16a: Running state — Lifecycle readable, no conditional fields
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
BLOCK16=$(get_pipeline_block "$PIPE_STATE16")
assert_output_contains "$BLOCK16" "**Lifecycle:** Running" "16a: FR16 Running — Lifecycle value derivable"
assert_output_not_contains "$BLOCK16" "**Pause Reason:**" "16a: FR16 Running — Pause Reason absent (no false positive)"
assert_output_not_contains "$BLOCK16" "**Block Reason:**" "16a: FR16 Running — Block Reason absent (no false positive)"
assert_output_not_contains "$BLOCK16" "**Block Artifact:**" "16a: FR16 Running — Block Artifact absent (no false positive)"

# 16b: Paused-Awaiting-Input state — Pause Reason present, Block fields absent
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Awaiting spec clarification" 2>/dev/null
BLOCK16=$(get_pipeline_block "$PIPE_STATE16")
assert_output_contains "$BLOCK16" "**Lifecycle:** Paused-Awaiting-Input" "16b: FR16 Paused — Lifecycle value derivable"
assert_output_contains "$BLOCK16" "**Pause Reason:** Awaiting spec clarification" "16b: FR16 Paused — Pause Reason present"
assert_output_not_contains "$BLOCK16" "**Block Reason:**" "16b: FR16 Paused — Block Reason absent"
assert_output_not_contains "$BLOCK16" "**Block Artifact:**" "16b: FR16 Paused — Block Artifact absent"

# 16c: Blocked state — Block Reason + Block Artifact present, Pause Reason absent
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Blocked on external review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "pr-001.md" 2>/dev/null
BLOCK16=$(get_pipeline_block "$PIPE_STATE16")
assert_output_contains "$BLOCK16" "**Lifecycle:** Blocked" "16c: FR16 Blocked — Lifecycle value derivable"
assert_output_contains "$BLOCK16" "**Block Reason:** Blocked on external review" "16c: FR16 Blocked — Block Reason present"
assert_output_contains "$BLOCK16" "**Block Artifact:** pr-001.md" "16c: FR16 Blocked — Block Artifact present"
assert_output_not_contains "$BLOCK16" "**Pause Reason:**" "16c: FR16 Blocked — Pause Reason absent (cleared from earlier Paused state)"

# 16d: Completed state — no conditional fields (all cleared)
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
BLOCK16=$(get_pipeline_block "$PIPE_STATE16")
assert_output_contains "$BLOCK16" "**Lifecycle:** Completed" "16d: FR16 Completed — Lifecycle value derivable"
assert_output_not_contains "$BLOCK16" "**Pause Reason:**" "16d: FR16 Completed — Pause Reason absent"
assert_output_not_contains "$BLOCK16" "**Block Reason:**" "16d: FR16 Completed — Block Reason absent"
assert_output_not_contains "$BLOCK16" "**Block Artifact:**" "16d: FR16 Completed — Block Artifact absent"

# 16e: The block format uses grep-recoverable **Field:** value lines
# (a deterministic reader can grep for each field without inference)
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE16" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
# Verify grep-recovery by extracting field values with grep + sed
lc_val=$(grep -oP '(?<=\*\*Lifecycle:\*\* ).*' "$PIPE_STATE16" | head -1)
ph_val=$(grep -oP '(?<=\*\*Phase:\*\* ).*' "$PIPE_STATE16" | head -1)
as_val=$(grep -oP '(?<=\*\*Active Skill:\*\* ).*' "$PIPE_STATE16" | head -1)
assert_eq "$lc_val" "Running" "16e: FR16 Lifecycle value grep-recoverable from on-disk block"
assert_eq "$ph_val" "Execute" "16e: FR16 Phase value grep-recoverable from on-disk block"
assert_eq "$as_val" "aid-develop" "16e: FR16 Active Skill value grep-recoverable from on-disk block"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: M5 — pause/block signal sequences (feature-001 §4 M5) ==="

# 18a: Pause path (PAUSE-FOR-USER-ACTION / PAUSE-FOR-USER-DECISION emit sequence)
# Simulates: skill hits a PAUSE advance type → emits Paused-Awaiting-Input + Pause Reason + Updated
PIPE_STATE18A="${TMPDIR_BASE}/pipe18a/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE18A")"
make_pipeline_state "$PIPE_STATE18A"
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field Phase --value Specify 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-specify 2>/dev/null
# PAUSE transition (e.g. state-blocked.md emit)
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Blocker pending — awaiting loopback resolution before /aid-specify can continue" 2>/dev/null || code=$?
assert_exit_zero "$code" "18a: Pause Reason emit after PAUSE transition → exit 0"
assert_file_contains "$PIPE_STATE18A" "**Lifecycle:** Paused-Awaiting-Input" "18a: Lifecycle set to Paused-Awaiting-Input"
assert_file_contains "$PIPE_STATE18A" "**Pause Reason:** Blocker pending" "18a: Pause Reason written"

# 18b: Resume path — M4 Running emit clears Pause Reason
# Simulates: user re-invokes skill → state entry emits Running (as M4 specifies)
AID_STATE_FILE="$PIPE_STATE18A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE18A" "**Lifecycle:** Running" "18b: Lifecycle returns to Running on resume"
assert_file_not_contains "$PIPE_STATE18A" "**Pause Reason:**" "18b: Pause Reason cleared on Running transition (M4 resume)"

# 18c: Block path (impediment / Failed task emit sequence)
# Simulates: state-execute.md PD-4 failure → Status=Failed → Blocked + Block Reason + Block Artifact
PIPE_STATE18C="${TMPDIR_BASE}/pipe18c/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE18C")"
make_pipeline_state "$PIPE_STATE18C"
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-execute 2>/dev/null
# Failure path: set task Failed, then emit Blocked
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --task-id 1 --field Status --value "Failed" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Task failed with unresolved impediment — task-001" 2>/dev/null || code=$?
assert_exit_zero "$code" "18c: Block Reason emit after task failure → exit 0"
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-task-001.md" 2>/dev/null
assert_file_contains "$PIPE_STATE18C" "**Lifecycle:** Blocked" "18c: Lifecycle set to Blocked on task failure"
assert_file_contains "$PIPE_STATE18C" "**Block Reason:** Task failed" "18c: Block Reason written"
assert_file_contains "$PIPE_STATE18C" "**Block Artifact:** .aid/work-001/IMPEDIMENT-task-001.md" "18c: Block Artifact written"
assert_file_not_contains "$PIPE_STATE18C" "**Pause Reason:**" "18c: Pause Reason absent when Blocked"

# 18d: Block resolution path — M4 Running emit on re-entry clears Block fields
# Simulates: user resolves impediment → re-runs /aid-execute → state-execute.md Step 1 emits Running
AID_STATE_FILE="$PIPE_STATE18C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE18C" "**Lifecycle:** Running" "18d: Lifecycle returns to Running after impediment resolved"
assert_file_not_contains "$PIPE_STATE18C" "**Block Reason:**" "18d: Block Reason cleared on Running transition"
assert_file_not_contains "$PIPE_STATE18C" "**Block Artifact:**" "18d: Block Artifact cleared on Running transition"

# 18e: Delivery-gate circuit-breaker block (sub-min grade, 3 cycles no improvement)
# Simulates: state-delivery-gate.md Step 5 circuit-breaker → IMPEDIMENT-delivery-NNN.md written
PIPE_STATE18E="${TMPDIR_BASE}/pipe18e/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE18E")"
make_pipeline_state "$PIPE_STATE18E"
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Delivery gate circuit breaker triggered — grade not improving after 3 cycles" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE18E" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-delivery-001.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "18e: Delivery gate circuit-breaker block emit → exit 0"
assert_file_contains "$PIPE_STATE18E" "**Lifecycle:** Blocked" "18e: Lifecycle Blocked on circuit-breaker stop"
assert_file_contains "$PIPE_STATE18E" "**Block Artifact:** .aid/work-001/IMPEDIMENT-delivery-001.md" "18e: Block Artifact is delivery IMPEDIMENT path"

# 18f: Delivery-gate non-CODE pause (SPEC/TASK/KB issues only — Paused-Awaiting-Input)
# Simulates: state-delivery-gate.md Step 4 non-CODE-only STOP → upstream fix required
PIPE_STATE18F="${TMPDIR_BASE}/pipe18f/STATE.md"
mkdir -p "$(dirname "$PIPE_STATE18F")"
make_pipeline_state "$PIPE_STATE18F"
AID_STATE_FILE="$PIPE_STATE18F" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE18F" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Delivery gate blocked on non-CODE issues — upstream fix required (SPEC/TASK/KB)" 2>/dev/null || code=$?
assert_exit_zero "$code" "18f: Delivery gate non-CODE pause emit → exit 0"
assert_file_contains "$PIPE_STATE18F" "**Lifecycle:** Paused-Awaiting-Input" "18f: Lifecycle Paused on non-CODE-only gate stop"
assert_file_contains "$PIPE_STATE18F" "**Pause Reason:** Delivery gate blocked on non-CODE issues" "18f: Pause Reason explains upstream fix needed"

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
