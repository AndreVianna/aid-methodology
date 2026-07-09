#!/usr/bin/env bash
# test-writeback-state.sh — smoke-test harness for writeback-state.sh
#
# Covers the NEW per-unit writeback contract (work-004 Pillar 2 retarget).
# All writes go to per-unit STATE.md files, NOT to the monolithic work STATE.md.
#
# Unit layout under test (FULL path -- multi-delivery work; deliveries/ nests under
# the work root, mirroring features/):
#   work-NNN-{name}/
#     STATE.md                          -- work-level (--pipeline target only)
#     deliveries/
#       delivery-NNN/
#         STATE.md                      -- delivery-level (--block / --lifecycle target)
#         tasks/
#           task-NNN/
#             SPEC.md                   -- contains **Source:** line for delivery resolution
#             STATE.md                  -- task-level (--field / --findings target)
#
# The lite single-delivery flat layout -- tasks/ sits directly under the work root,
# with no deliveries/ or delivery-NNN/ folder, and the single delivery's
# ## Delivery Lifecycle / ## Delivery Gate sections are AUTHORED directly in the
# work-root STATE.md -- is covered by Unit 20 below (work-001-add-deliveries-folder
# task-003; the resolver's own lite-path branch was added by task-001).
#
# Test scenarios:
#   Unit 1: --task-id --delivery-id --field --value  (per-task STATE.md field update)
#   Unit 2: --task-id --delivery-id --findings       (per-task ## Quick Check Findings)
#   Unit 3: --delivery-id --block                    (per-delivery ## Delivery Gate)
#   Unit 4: --delivery-id --lifecycle                (per-delivery ## Delivery Lifecycle)
#   Unit 5: --delivery-id --append-issue             (delivery-NNN-issues.md append)
#   Unit 6: Source-line delivery resolution          (--delivery-id omitted, SPEC.md used)
#   Unit 7: Idempotency
#   Unit 8: Concurrent lock contention (5 parallel per-task writes)
#   Unit 9: --pipeline field writes (section creation + each base field)
#   Unit 10: --pipeline enum acceptance + rejection
#   Unit 11: --pipeline conditional Pause/Block fields
#   Unit 12: Isolation — task/findings/block writes do NOT touch work STATE.md
#   Unit 13: Error paths (missing args, invalid ids, lock timeout, missing files)
#   Unit 14: H2 — --value containing '|' rejected
#   Unit 15: M2 — missing lock directory
#   Unit 16: State field enum validation (field=State, new name)
#   Unit 17: --pipeline ∥ --pipeline and --pipeline ∥ --field concurrency
#   Unit 18: FR16 derivation primitives — on-disk block determinism
#   Unit 19: M5 — pause/block signal sequences
#   Unit 20: Lite-path resolution (no deliveries/ folder; work-root STATE.md is the
#            single delivery's home for ## Delivery Lifecycle / ## Delivery Gate)
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/writeback-state.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Escape canary: ensure we never scan the real $HOME for .aid/ repos
# (the delivery resolution uses find to scan the WORK_DIR, not $HOME;
#  this canary is defence-in-depth in case a future refactor widens the scan).
# ---------------------------------------------------------------------------
REAL_HOME="$HOME"
CANARY_AID="${REAL_HOME}/.aid"

# ---------------------------------------------------------------------------
# Setup: create a temporary workspace
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# make_task_state DELIVERY_DIR TASK_ID [STATE_VALUE]
# Creates delivery-NNN/tasks/task-NNN/STATE.md with ## Task State section.
# STATE_VALUE defaults to "Pending".
make_task_state() {
    local delivery_dir="$1" task_id="$2" state_val="${3:-Pending}"
    local padded_t
    padded_t=$(printf '%03d' "$task_id")
    local task_dir="${delivery_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/STATE.md" <<TASKSTATEOF
# Task State -- task-${padded_t}

> **Task:** task-${padded_t}

---

## Task State

- **State:** ${state_val}
- **Review:** --
- **Elapsed:** --
- **Notes:** --

---

## Quick Check Findings

- **Reviewer Tier:** --
- **Findings:** none yet

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
TASKSTATEOF
}

# make_task_spec DELIVERY_DIR TASK_ID DELIVERY_ID WORK_NAME
# Creates delivery-NNN/tasks/task-NNN/SPEC.md with a **Source:** line.
make_task_spec() {
    local delivery_dir="$1" task_id="$2" delivery_id="$3" work_name="${4:-work-004-test}"
    local padded_t padded_d
    padded_t=$(printf '%03d' "$task_id")
    padded_d=$(printf '%03d' "$delivery_id")
    local task_dir="${delivery_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/SPEC.md" <<TASKSPECEOF
# task-${padded_t}: Test Task

**Type:** IMPLEMENT

**Source:** ${work_name} -> delivery-${padded_d}

**Depends on:** --

**Scope:**
- Test scope for task ${padded_t}

**Acceptance Criteria:**
- [ ] criterion
TASKSPECEOF
}

# make_delivery_state WORK_DIR DELIVERY_ID [LIFECYCLE_VALUE]
# Creates deliveries/delivery-NNN/STATE.md (full path) with ## Delivery Lifecycle and
# ## Delivery Gate sections. LIFECYCLE_VALUE defaults to "Executing".
make_delivery_state() {
    local work_dir="$1" delivery_id="$2" lc_val="${3:-Executing}"
    local padded_d
    padded_d=$(printf '%03d' "$delivery_id")
    local delivery_dir="${work_dir}/deliveries/delivery-${padded_d}"
    mkdir -p "$delivery_dir"
    cat > "${delivery_dir}/STATE.md" <<DELIVSTATEOF
# Delivery State -- delivery-${padded_d}

> **Delivery:** delivery-${padded_d}

---

## Delivery Lifecycle

- **State:** ${lc_val}
- **Updated:** 2026-06-18T00:00:00Z

---

## Delivery Gate

- **Reviewer Tier:** --
- **Grade:** Pending
- **Issue List:** none
- **Timestamp:** --

---

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
DELIVSTATEOF
}

# make_work_state WORK_DIR
# Creates a minimal work-level STATE.md (--pipeline target only; no task rows).
make_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.md" <<'WORKSTATEOF'
# Work State — work-test

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-18T00:00:00Z

## Triage

(none)
WORKSTATEOF
}

# ---------------------------------------------------------------------------
# Global workspace: work root + deliveries/delivery-001 (tasks 1..5) +
# deliveries/delivery-002 (task 6) -- FULL path (multi-delivery work).
# ---------------------------------------------------------------------------
WORK_DIR="${TMPDIR_BASE}/work"
DELIVERY_001="${WORK_DIR}/deliveries/delivery-001"
DELIVERY_002="${WORK_DIR}/deliveries/delivery-002"

make_work_state "$WORK_DIR"
export AID_STATE_FILE="${WORK_DIR}/STATE.md"
export AID_DELIVERY_ISSUES_DIR="$WORK_DIR"
export AID_LOCK_TIMEOUT=10

# Create delivery-001 with tasks 1..5
make_delivery_state "$WORK_DIR" 1
for i in 1 2 3 4 5; do
    make_task_state "$DELIVERY_001" "$i"
    make_task_spec  "$DELIVERY_001" "$i" 1
done

# Create delivery-002 with task 6
make_delivery_state "$WORK_DIR" 2
make_task_state "$DELIVERY_002" 6
make_task_spec  "$DELIVERY_002" 6 2

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: --task-id --delivery-id --field --value ==="

run_field() {
    local tid="$1" did="$2" field="$3" val="$4"
    bash "$SCRIPT" --delivery-id "$did" --task-id "$tid" --field "$field" --value "$val"
}

# The task STATE.md is the target; verify the write lands there, NOT in work STATE.md.
run_field 1 1 State "In Progress"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "In Progress" "task-001 State updated in task STATE.md"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.md" "Pending" "task-002 still Pending (not disturbed)"

run_field 2 1 State "Done"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.md" "Done" "task-002 State updated to Done"

run_field 3 1 Review "A"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.md" "A" "task-003 Review field updated"

run_field 4 1 Notes "first note"
assert_file_contains "${DELIVERY_001}/tasks/task-004/STATE.md" "first note" "task-004 Notes updated"

run_field 5 1 Elapsed "12m"
assert_file_contains "${DELIVERY_001}/tasks/task-005/STATE.md" "12m" "task-005 Elapsed updated"

# Isolation: work STATE.md must NOT be touched by task field writes
assert_file_not_contains "${WORK_DIR}/STATE.md" "In Progress" "work STATE.md NOT modified by task field write (isolation)"
assert_file_not_contains "${WORK_DIR}/STATE.md" "first note"  "work STATE.md NOT modified by Notes write (isolation)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: --task-id --delivery-id --findings ==="

FINDINGS_BLOCK="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [HIGH] | missing error path | Deferred-to-gate |"

bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_BLOCK"
# Findings land in the task's own STATE.md ## Quick Check Findings
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "## Quick Check Findings" "task-001 STATE.md has ## Quick Check Findings"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "[HIGH]" "findings block written to task-001 STATE.md"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "Deferred-to-gate" "deferred status in task-001 findings"
# Work STATE.md must NOT receive findings
assert_file_not_contains "${WORK_DIR}/STATE.md" "[HIGH]" "work STATE.md NOT modified by --findings (isolation)"

FINDINGS_BLOCK2="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [CRITICAL] | null deref on empty input | Fixed-on-spot |"

bash "$SCRIPT" --delivery-id 1 --task-id 2 --findings "$FINDINGS_BLOCK2"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.md" "## Quick Check Findings" "task-002 STATE.md has ## Quick Check Findings"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.md" "[CRITICAL]" "critical finding in task-002 STATE.md"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.md" "Fixed-on-spot" "fixed-on-spot in task-002 STATE.md"
# Each task owns its own file — task-001 findings unaffected
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "Deferred-to-gate" "task-001 findings still present after task-002 write"

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
# Gate block lands in delivery-001/STATE.md ## Delivery Gate
assert_file_contains "${DELIVERY_001}/STATE.md" "## Delivery Gate" "delivery-001/STATE.md has ## Delivery Gate"
assert_file_contains "${DELIVERY_001}/STATE.md" "**Grade:** A+" "grade A+ in delivery-001 gate block"
assert_file_contains "${DELIVERY_001}/STATE.md" "PASS" "PASS in delivery-001 gate block"
# Work STATE.md must NOT receive the gate block
assert_file_not_contains "${WORK_DIR}/STATE.md" "**Grade:** A+" "work STATE.md NOT modified by --block (isolation)"
# Task files must NOT be modified
assert_file_not_contains "${DELIVERY_001}/tasks/task-005/STATE.md" "## Delivery Gate" "task-005 STATE.md NOT modified by --block"

# Replace (not append): re-run with different grade
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
assert_file_contains "${DELIVERY_001}/STATE.md" "**Grade:** A" "gate block replaced — grade A in delivery-001"
assert_file_not_contains "${DELIVERY_001}/STATE.md" "**Grade:** A+" "old grade A+ removed from delivery-001"
assert_file_contains "${DELIVERY_001}/STATE.md" "**Cycles:** 2" "cycle count updated in delivery-001"

# delivery-002 gets its own gate block (disjoint files)
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
assert_file_contains "${DELIVERY_002}/STATE.md" "## Delivery Gate" "delivery-002/STATE.md has ## Delivery Gate"
assert_file_contains "${DELIVERY_002}/STATE.md" "**Grade:** B" "grade B in delivery-002 gate block"
assert_file_contains "${DELIVERY_001}/STATE.md" "**Grade:** A" "delivery-001 gate block unaffected after delivery-002 write"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: --delivery-id --lifecycle ==="

# SD-8 enum: Pending-Spec | Specified | Executing | Gated | Done | Blocked
bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated"
assert_file_contains "${DELIVERY_001}/STATE.md" "## Delivery Lifecycle" "delivery-001/STATE.md has ## Delivery Lifecycle"
assert_file_contains "${DELIVERY_001}/STATE.md" "**State:** Gated" "delivery-001 lifecycle State set to Gated"
# Work STATE.md must NOT be touched
assert_file_not_contains "${WORK_DIR}/STATE.md" "Gated" "work STATE.md NOT modified by --lifecycle (isolation)"

# Advance through each enum member
for lc_val in "Pending-Spec" "Specified" "Executing" "Gated" "Done" "Blocked"; do
    code=0
    bash "$SCRIPT" --delivery-id 2 --lifecycle "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "--lifecycle $lc_val accepted (exit 0)"
done
assert_file_contains "${DELIVERY_002}/STATE.md" "**State:** Blocked" "delivery-002 lifecycle advanced to Blocked"

# Invalid lifecycle value → exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --lifecycle "Running" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "--lifecycle Running (invalid; that is pipeline enum) → exit 4"

code=0
bash "$SCRIPT" --delivery-id 1 --lifecycle "active" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "--lifecycle active (invalid lowercase) → exit 4"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: --delivery-id --append-issue ==="

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
assert_file_contains "$ISSUES_FILE" "task-003" "row1 still present after row2 append"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: Source-line delivery resolution (--delivery-id omitted) ==="

# The task SPEC.md already contains "**Source:** work-004-test -> delivery-001".
# Resolve the delivery from that line and write to the correct task STATE.md.
# We must supply AID_STATE_FILE so the script knows the work root.
code=0
bash "$SCRIPT" --task-id 3 --field State --value "In Review" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-3 → delivery-001, exit 0"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.md" "In Review" "task-003 State written via source-line resolution"

# task-6 is in delivery-002 per its SPEC.md
code=0
bash "$SCRIPT" --task-id 6 --field Notes --value "auto-resolved" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-6 → delivery-002, exit 0"
assert_file_contains "${DELIVERY_002}/tasks/task-006/STATE.md" "auto-resolved" "task-006 Notes written via source-line resolution"

# Omit delivery-id AND have no SPEC.md → must fail with exit 5
ORPHAN_WORK="${TMPDIR_BASE}/orphan-work"
mkdir -p "$ORPHAN_WORK"
make_task_state "$ORPHAN_WORK/deliveries/delivery-001" 99  # state only, no SPEC.md
code=0
AID_STATE_FILE="${ORPHAN_WORK}/STATE.md" bash "$SCRIPT" --task-id 99 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 5 "no --delivery-id + no SPEC.md → exit 5 (cannot resolve delivery)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: Idempotency ==="

# Field update with same value — task STATE.md byte-count must not change
BEFORE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress"
AFTER=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "field mode: idempotent — same value, no size change"
else
    fail "field mode: not idempotent — task STATE.md size changed from $BEFORE to $AFTER"
fi

# Findings: re-write same block — task STATE.md size must not change
BEFORE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_BLOCK"
AFTER=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "findings mode: idempotent — same block, no task STATE.md size change"
else
    fail "findings mode: not idempotent — task STATE.md size changed from $BEFORE to $AFTER"
fi

# delivery-block: re-write same block — delivery STATE.md size must not change
BEFORE=$(wc -c < "${DELIVERY_001}/STATE.md")
bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
AFTER=$(wc -c < "${DELIVERY_001}/STATE.md")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "delivery-block mode: idempotent — same block, delivery STATE.md size unchanged"
else
    fail "delivery-block mode: not idempotent — delivery STATE.md size changed from $BEFORE to $AFTER"
fi

# append-issue: same row → no-op (no duplicate)
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
echo "=== Unit 8: Concurrent lock contention (5 parallel per-task writes) ==="

# Reset task states to Pending for a clean concurrency baseline
CONC_WORK="${TMPDIR_BASE}/conc-work"
CONC_DELIV="${CONC_WORK}/deliveries/delivery-001"
make_work_state "$CONC_WORK"
make_delivery_state "$CONC_WORK" 1
for i in 1 2 3 4 5; do
    make_task_state "$CONC_DELIV" "$i"
done

# Launch 5 concurrent writers, each targeting a DIFFERENT task (different files).
# The sentinel lock is per-file-directory; each writer gets its own lock.
(
    AID_STATE_FILE="${CONC_WORK}/STATE.md" \
        bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" &
    AID_STATE_FILE="${CONC_WORK}/STATE.md" \
        bash "$SCRIPT" --delivery-id 1 --task-id 2 --field State --value "In Progress" &
    AID_STATE_FILE="${CONC_WORK}/STATE.md" \
        bash "$SCRIPT" --delivery-id 1 --task-id 3 --field State --value "Failed" &
    AID_STATE_FILE="${CONC_WORK}/STATE.md" \
        bash "$SCRIPT" --delivery-id 1 --task-id 4 --field State --value "Blocked" &
    AID_STATE_FILE="${CONC_WORK}/STATE.md" \
        bash "$SCRIPT" --delivery-id 1 --task-id 5 --field State --value "In Review" &
    wait
)

declare -A CONC_VALS=([1]="Done" [2]="In Progress" [3]="Failed" [4]="Blocked" [5]="In Review")
for i in 1 2 3 4 5; do
    padded=$(printf '%03d' "$i")
    expected="${CONC_VALS[$i]}"
    assert_file_contains "${CONC_DELIV}/tasks/task-${padded}/STATE.md" "$expected" \
        "concurrent P${i} write landed in task-${padded}/STATE.md (${expected})"
done

# No lock files left behind
for i in 1 2 3 4 5; do
    padded=$(printf '%03d' "$i")
    if [[ ! -f "${CONC_DELIV}/tasks/task-${padded}/.writeback-state.lock" ]]; then
        pass "task-${padded}: no stale lock file after concurrent write"
    else
        fail "task-${padded}: stale lock file found — possible deadlock"
    fi
done

# Work STATE.md must remain untouched
assert_file_not_contains "${CONC_WORK}/STATE.md" "Done" "work STATE.md NOT touched by concurrent task writes"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: --pipeline field writes (section creation + each base field) ==="

make_pipeline_state() {
    local dest="$1"
    mkdir -p "$(dirname "$dest")"
    cat > "$dest" <<'PIPEEOF'
# Work State — work-pipeline-test

## Triage

(none)

## Deploy State

| Delivery | State | PR |
|----------|----|---|
| — | — | — |
PIPEEOF
}

get_pipeline_block() {
    local f="$1"
    awk '/^## Pipeline State/{in_ps=1; next} in_ps && /^## /{in_ps=0} in_ps{print}' "$f"
}

PIPE_STATE="${TMPDIR_BASE}/pipe09/STATE.md"
make_pipeline_state "$PIPE_STATE"

# 9a: Section absent — writing Lifecycle creates ## Pipeline State
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_zero "$code" "9a: Lifecycle write on absent section → exit 0"
assert_file_contains "$PIPE_STATE" "## Pipeline State" "9a: ## Pipeline State section created"
assert_file_contains "$PIPE_STATE" "**Lifecycle:** Running" "9a: Lifecycle field written"

# 9b: Phase field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "9b: Phase write → exit 0"
assert_file_contains "$PIPE_STATE" "**Phase:** Execute" "9b: Phase field written"

# 9c: Active Skill field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null || code=$?
assert_exit_zero "$code" "9c: Active Skill write → exit 0"
assert_file_contains "$PIPE_STATE" "**Active Skill:** aid-develop" "9c: Active Skill field written"

# 9d: Updated field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "9d: Updated write → exit 0"
assert_file_contains "$PIPE_STATE" "**Updated:** 2026-06-10" "9d: Updated field written"

# 9e: All four base fields coexist in the block
PIPE_BLOCK=$(get_pipeline_block "$PIPE_STATE")
assert_output_contains "$PIPE_BLOCK" "**Lifecycle:** Running" "9e: Lifecycle line grep-recoverable in Pipeline State block"
assert_output_contains "$PIPE_BLOCK" "**Phase:** Execute" "9e: Phase line grep-recoverable in Pipeline State block"
assert_output_contains "$PIPE_BLOCK" "**Active Skill:** aid-develop" "9e: Active Skill line grep-recoverable in Pipeline State block"
assert_output_contains "$PIPE_BLOCK" "**Updated:** 2026-06-10" "9e: Updated line grep-recoverable in Pipeline State block"

# 9f: Other STATE.md sections not disturbed
assert_file_contains "$PIPE_STATE" "## Triage" "9f: Triage section preserved after pipeline writes"
assert_file_contains "$PIPE_STATE" "## Deploy State" "9f: Deploy State section preserved after pipeline writes"

# 9g: Section absent — writing non-Lifecycle field (Phase) creates the section too
PIPE_STATE_G="${TMPDIR_BASE}/pipe09g/STATE.md"
make_pipeline_state "$PIPE_STATE_G"
code=0
AID_STATE_FILE="$PIPE_STATE_G" bash "$SCRIPT" --pipeline --field Phase --value Plan 2>/dev/null || code=$?
assert_exit_zero "$code" "9g: Phase write on absent section → exit 0"
assert_file_contains "$PIPE_STATE_G" "## Pipeline State" "9g: ## Pipeline State section created by Phase write"
assert_file_contains "$PIPE_STATE_G" "**Phase:** Plan" "9g: Phase field written on new section"

# 9h: Update (overwrite) an existing field value
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
assert_file_contains "$PIPE_STATE" "**Lifecycle:** Completed" "9h: Lifecycle field overwritten to Completed"
assert_file_not_contains "$PIPE_STATE" "**Lifecycle:** Running" "9h: old Lifecycle value Running removed"

# 9i: Active Skill set to 'none' is valid
PIPE_STATE_I="${TMPDIR_BASE}/pipe09i/STATE.md"
make_pipeline_state "$PIPE_STATE_I"
code=0
AID_STATE_FILE="$PIPE_STATE_I" bash "$SCRIPT" --pipeline --field "Active Skill" --value "none" 2>/dev/null || code=$?
assert_exit_zero "$code" "9i: Active Skill=none is valid → exit 0"
assert_file_contains "$PIPE_STATE_I" "**Active Skill:** none" "9i: Active Skill none written"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: --pipeline enum acceptance + rejection ==="

PIPE_STATE10="${TMPDIR_BASE}/pipe10/STATE.md"
make_pipeline_state "$PIPE_STATE10"

# 10a: All valid Lifecycle values accepted (rc 0)
for lc_val in Running Paused-Awaiting-Input Blocked Completed Canceled; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "10a: Lifecycle=$lc_val accepted (exit 0)"
done

# 10b: Invalid Lifecycle value → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "InProgress" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10b: Lifecycle=InProgress rejected (exit 4)"

# 10c: Lowercase Lifecycle rejected → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "running" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10c: Lifecycle=running (lowercase) rejected (exit 4)"

# 10d: All valid Phase values accepted (rc 0)
for ph_val in Interview Specify Plan Detail Execute Deploy Monitor; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "10d: Phase=$ph_val accepted (exit 0)"
done

# 10e: Invalid Phase value → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "Build" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10e: Phase=Build rejected (exit 4)"

# 10f: Lowercase Phase rejected → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "execute" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10f: Phase=execute (lowercase) rejected (exit 4)"

# 10g: Valid aid-{skill} Active Skill value accepted
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-review" 2>/dev/null || code=$?
assert_exit_zero "$code" "10g: Active Skill=aid-review accepted (exit 0)"

# 10h: Active Skill without aid- prefix → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "develop" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10h: Active Skill=develop (no aid- prefix) rejected (exit 4)"

# 10i: Active Skill = aid- only (empty skill part) → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10i: Active Skill=aid- (empty skill part) rejected (exit 4)"

# 10j: Unknown field name → exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "UnknownField" --value "x" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10j: unknown pipeline field rejected (exit 4)"

# 10k: --pipeline without --field → exit non-zero (exit 5)
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline 2>/dev/null || code=$?
assert_exit_nonzero "$code" "10k: --pipeline without --field → non-zero exit"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 11: --pipeline conditional Pause/Block fields ==="

make_cond_state() {
    local dest="$1"
    make_pipeline_state "$dest"
    AID_STATE_FILE="$dest" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
}

# 11a: Pause Reason written when Lifecycle=Paused-Awaiting-Input
PIPE_STATE11A="${TMPDIR_BASE}/pipe11a/STATE.md"
make_cond_state "$PIPE_STATE11A"
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for user clarification" 2>/dev/null || code=$?
assert_exit_zero "$code" "11a: Pause Reason write under Paused-Awaiting-Input → exit 0"
assert_file_contains "$PIPE_STATE11A" "**Pause Reason:** Waiting for user clarification" "11a: Pause Reason field written"

# 11b: Block Reason + Block Artifact written when Lifecycle=Blocked
PIPE_STATE11B="${TMPDIR_BASE}/pipe11b/STATE.md"
make_cond_state "$PIPE_STATE11B"
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Waiting for dependency" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Reason write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE11B" "**Block Reason:** Waiting for dependency" "11b: Block Reason field written"
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "task-007.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Artifact write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE11B" "**Block Artifact:** task-007.md" "11b: Block Artifact field written"

# 11c: Transition OUT of Paused-Awaiting-Input clears Pause Reason
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_not_contains "$PIPE_STATE11A" "**Pause Reason:**" "11c: Pause Reason cleared after Lifecycle→Running"

# 11d: Transition OUT of Blocked clears Block Reason and Block Artifact
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_not_contains "$PIPE_STATE11B" "**Block Reason:**" "11d: Block Reason cleared after Lifecycle→Running"
assert_file_not_contains "$PIPE_STATE11B" "**Block Artifact:**" "11d: Block Artifact cleared after Lifecycle→Running"

# 11e: Pause Reason cleared when Lifecycle transitions to Blocked
PIPE_STATE11E="${TMPDIR_BASE}/pipe11e/STATE.md"
make_cond_state "$PIPE_STATE11E"
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
assert_file_not_contains "$PIPE_STATE11E" "**Pause Reason:**" "11e: Pause Reason cleared when Lifecycle transitions to Blocked"

# 11f: Block Reason + Artifact absent after transition from Blocked to Completed
PIPE_STATE11F="${TMPDIR_BASE}/pipe11f/STATE.md"
make_cond_state "$PIPE_STATE11F"
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Needs review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "review-001.md" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Completed" 2>/dev/null
assert_file_not_contains "$PIPE_STATE11F" "**Block Reason:**" "11f: Block Reason cleared on Lifecycle→Completed"
assert_file_not_contains "$PIPE_STATE11F" "**Block Artifact:**" "11f: Block Artifact cleared on Lifecycle→Completed"

# 11g: Fresh Running state — no conditional fields
PIPE_STATE11G="${TMPDIR_BASE}/pipe11g/STATE.md"
make_cond_state "$PIPE_STATE11G"
assert_file_not_contains "$PIPE_STATE11G" "**Block Reason:**" "11g: Block Reason absent on fresh Running state"
assert_file_not_contains "$PIPE_STATE11G" "**Block Artifact:**" "11g: Block Artifact absent on fresh Running state"
assert_file_not_contains "$PIPE_STATE11G" "**Pause Reason:**" "11g: Pause Reason absent on fresh Running state"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 12: Isolation — task/findings/block do NOT touch work STATE.md ==="

ISOL_WORK="${TMPDIR_BASE}/isol-work"
ISOL_DELIV="${ISOL_WORK}/deliveries/delivery-001"
make_work_state "$ISOL_WORK"
make_delivery_state "$ISOL_WORK" 1
make_task_state "$ISOL_DELIV" 1
make_task_spec  "$ISOL_DELIV" 1 1

WORK_STATE_BEFORE="${ISOL_WORK}/STATE.md"
INITIAL_WORK_CONTENT=$(cat "$WORK_STATE_BEFORE")

# Task field write
AID_STATE_FILE="${ISOL_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12a: work STATE.md unchanged after task --field write"
else
    fail "12a: work STATE.md was modified by task --field write (isolation breach)"
fi

# Task findings write
AID_STATE_FILE="${ISOL_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "test findings" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12b: work STATE.md unchanged after task --findings write"
else
    fail "12b: work STATE.md was modified by task --findings write (isolation breach)"
fi

# Delivery block write
AID_STATE_FILE="${ISOL_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --block "test gate block" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12c: work STATE.md unchanged after --block write"
else
    fail "12c: work STATE.md was modified by --block write (isolation breach)"
fi

# Delivery lifecycle write
AID_STATE_FILE="${ISOL_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12d: work STATE.md unchanged after --lifecycle write"
else
    fail "12d: work STATE.md was modified by --lifecycle write (isolation breach)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 13: Error paths ==="

# 13a: No arguments → exit non-zero
out=$( bash "$SCRIPT" 2>&1 ) || code=$?
assert_exit_nonzero "${code:-0}" "no args → non-zero exit"

# 13b: Missing --value with --task-id --field
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State 2>/dev/null || code=$?
assert_exit_nonzero "$code" "missing --value → exit 5"

# 13c: Invalid task-id (non-numeric)
code=0
bash "$SCRIPT" --delivery-id 1 --task-id abc --field State --value Done 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric task-id → exit 4"

# 13d: Unknown field name → exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field NONEXISTENT --value x 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "unknown field name → exit 4"

# 13e: Task STATE.md does not exist → exit 1
code=0
bash "$SCRIPT" --delivery-id 99 --task-id 99 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "task STATE.md missing → exit 1"

# 13f: Invalid delivery-id (non-numeric)
code=0
bash "$SCRIPT" --delivery-id xyz --append-issue "| a | b | c | d |" 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric delivery-id → exit 4"

# 13g: append-issue with non-table row → exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --append-issue "not a table row" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "invalid issue row format → exit 4"

# 13h: Lock held — simulate contention timeout
LOCK_TEST_TASK="${DELIVERY_001}/tasks/task-001"
LOCK_FILE="${LOCK_TEST_TASK}/.writeback-state.lock"
echo "99999" > "$LOCK_FILE"
code=0
AID_LOCK_TIMEOUT=2 bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value Done 2>/dev/null || code=$?
assert_exit_nonzero "$code" "lock timeout → exit 2"
rm -f "$LOCK_FILE"

# 13i: work STATE.md missing → exit 1 (for --pipeline mode)
code=0
AID_STATE_FILE="${TMPDIR_BASE}/nonexistent/STATE.md" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "work STATE.md missing → exit 1 (--pipeline mode)"

# 13j: Delivery STATE.md missing → exit 1 (for --block mode)
code=0
bash "$SCRIPT" --delivery-id 88 --block "test block" 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "delivery STATE.md missing → exit 1 (--block mode)"

# 13k: Delivery STATE.md missing → exit 1 (for --lifecycle mode)
code=0
bash "$SCRIPT" --delivery-id 88 --lifecycle "Executing" 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "delivery STATE.md missing → exit 1 (--lifecycle mode)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 14: H2 — --value containing literal '|' rejected ==="

code=0
err_out=$(bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value "a|b" 2>&1) || code=$?
assert_exit_eq "$code" 4 "H2 pipe in --value → exit 4"
if echo "$err_out" | grep -q "cannot contain '|'"; then
    pass "H2 pipe in --value: error message mentions \"cannot contain '|'\""
else
    fail "H2 pipe in --value: expected \"cannot contain '|'\" in error output, got: $err_out"
fi

# Verify the task STATE.md is not modified when pipe is in value
BEFORE_SIZE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value "pipe|here" 2>/dev/null || true
AFTER_SIZE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.md")
if [[ "$BEFORE_SIZE" -eq "$AFTER_SIZE" ]]; then
    pass "H2 pipe rejection: task STATE.md not modified"
else
    fail "H2 pipe rejection: task STATE.md was modified despite pipe in value"
fi

# H2b: newline in --value also rejected
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value $'line\nnewline' 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "H2b newline in --value → exit 4"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 15: M2 — missing lock directory detected before contention ==="

# When AID_LOCK_DIR is set to a nonexistent directory, the lock acquire step
# should detect the missing directory before waiting and return exit 1.
# The task file must exist for the lock path to be derived from the file's dir;
# use AID_LOCK_DIR to force a non-existent path.
code=0
err_out=$(AID_LOCK_DIR="${TMPDIR_BASE}/nonexistent-lock-dir" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value Done 2>&1) || code=$?
assert_exit_nonzero "$code" "M2 missing lock dir → exit non-zero"
if echo "$err_out" | grep -q "lock directory does not exist"; then
    pass "M2 missing lock dir: error message mentions 'lock directory does not exist'"
else
    fail "M2 missing lock dir: expected 'lock directory does not exist' in error output, got: $err_out"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 16: State field enum validation (field=State; replaces old Status) ==="

make_state_task() {
    local dir="$1" delivery_id="${2:-1}"
    local delivery_dir="${dir}/deliveries/delivery-$(printf '%03d' "$delivery_id")"
    make_task_state "$delivery_dir" 1
    make_task_spec  "$delivery_dir" 1 "$delivery_id"
}

# 16.1 — All 7 State members accepted (exit 0)
echo ""
echo "--- 16.1: All 7 State members accepted ---"

for state_val in "Pending" "In Progress" "In Review" "Blocked" "Done" "Failed" "Canceled"; do
    S16_DIR="${TMPDIR_BASE}/unit16-member-$(echo "$state_val" | tr ' ' '_')"
    S16_WORK="${S16_DIR}/work"
    make_work_state "$S16_WORK"
    make_delivery_state "$S16_WORK" 1
    make_task_state "${S16_WORK}/deliveries/delivery-001" 1
    make_task_spec  "${S16_WORK}/deliveries/delivery-001" 1 1
    code=0
    AID_STATE_FILE="${S16_WORK}/STATE.md" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$state_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "16.1: State='${state_val}' accepted (exit 0)"
    assert_file_contains "${S16_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
        "**State:** ${state_val}" "16.1: State='${state_val}' written to task STATE.md"
done

# 16.2 — _none yet_ placeholder accepted
echo ""
echo "--- 16.2: _none yet_ placeholder accepted ---"

S16_NONE_WORK="${TMPDIR_BASE}/unit16-none/work"
make_work_state "$S16_NONE_WORK"
make_delivery_state "$S16_NONE_WORK" 1
make_task_state "${S16_NONE_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_NONE_WORK}/deliveries/delivery-001" 1 1
code=0
AID_STATE_FILE="${S16_NONE_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "_none yet_" 2>/dev/null || code=$?
assert_exit_zero "$code" "16.2: State='_none yet_' placeholder accepted (exit 0)"
assert_file_contains "${S16_NONE_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
    "_none yet_" "16.2: _none yet_ placeholder written to task STATE.md"

# 16.3 — Out-of-enum values rejected (exit 4)
echo ""
echo "--- 16.3: Out-of-enum values rejected (exit 4) ---"

for bad_val in "running" "DONE" "Finished" "in progress" "InProgress" "todo" "PENDING" "Status"; do
    S16_BAD_WORK="${TMPDIR_BASE}/unit16-bad-$(echo "$bad_val" | tr ' /' '_')/work"
    make_work_state "$S16_BAD_WORK"
    make_delivery_state "$S16_BAD_WORK" 1
    make_task_state "${S16_BAD_WORK}/deliveries/delivery-001" 1
    make_task_spec  "${S16_BAD_WORK}/deliveries/delivery-001" 1 1
    code=0
    AID_STATE_FILE="${S16_BAD_WORK}/STATE.md" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$bad_val" 2>/dev/null || code=$?
    assert_exit_eq "$code" 4 "16.3: State='${bad_val}' rejected (exit 4)"
    # STATE.md still shows Pending
    assert_file_contains "${S16_BAD_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
        "**State:** Pending" "16.3: task STATE.md unchanged after rejection of '${bad_val}'"
done

# 16.4 — C4 no-regression: the 6 legacy producer strings still accepted
echo ""
echo "--- 16.4: C4 no-regression — 6 legacy producer strings accepted (field=State) ---"

for legacy_val in "Pending" "In Progress" "In Review" "Blocked" "Done" "Failed"; do
    S16_LEG_WORK="${TMPDIR_BASE}/unit16-legacy-$(echo "$legacy_val" | tr ' ' '_')/work"
    make_work_state "$S16_LEG_WORK"
    make_delivery_state "$S16_LEG_WORK" 1
    make_task_state "${S16_LEG_WORK}/deliveries/delivery-001" 1
    make_task_spec  "${S16_LEG_WORK}/deliveries/delivery-001" 1 1
    code=0
    AID_STATE_FILE="${S16_LEG_WORK}/STATE.md" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$legacy_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "16.4: C4 legacy State='${legacy_val}' accepted (exit 0)"
done

# 16.5 — Enum guard is State-field-only; other fields accept arbitrary values
echo ""
echo "--- 16.5: State-only scope — enum does not leak to other fields ---"

S16_SCOPE_WORK="${TMPDIR_BASE}/unit16-scope/work"
make_work_state "$S16_SCOPE_WORK"
make_delivery_state "$S16_SCOPE_WORK" 1
make_task_state "${S16_SCOPE_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_SCOPE_WORK}/deliveries/delivery-001" 1 1

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Notes --value "anything weird !@#" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Notes='anything weird !@#' accepted (enum does not leak to Notes)"
assert_file_contains "${S16_SCOPE_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
    "anything weird !@#" "16.5: Notes value written successfully"

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Elapsed --value "running" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Elapsed='running' accepted (enum does not apply to Elapsed)"

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Review --value "done" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Review='done' accepted (enum does not apply to Review)"

# 16.6 — State value grep-recoverable in task STATE.md ## Task State section
echo ""
echo "--- 16.6: Deterministic consumability — State grep-recoverable in task STATE.md ---"

S16_CONS_WORK="${TMPDIR_BASE}/unit16-cons/work"
make_work_state "$S16_CONS_WORK"
make_delivery_state "$S16_CONS_WORK" 1
make_task_state "${S16_CONS_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_CONS_WORK}/deliveries/delivery-001" 1 1

TASK_STATE_FILE="${S16_CONS_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "In Review" 2>/dev/null
assert_file_contains "$TASK_STATE_FILE" "## Task State" "16.6: ## Task State section present after State write"
assert_file_contains "$TASK_STATE_FILE" "**State:** In Review" "16.6: 'In Review' written as **State:** line in ## Task State"

# Recover via grep
recovered_state=$(grep -m1 '^\- \*\*State:\*\*' "$TASK_STATE_FILE" | sed 's/^- \*\*State:\*\* //')
assert_eq "$recovered_state" "In Review" "16.6: State value grep-recoverable from task STATE.md"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null
recovered_state=$(grep -m1 '^\- \*\*State:\*\*' "$TASK_STATE_FILE" | sed 's/^- \*\*State:\*\* //')
assert_eq "$recovered_state" "Done" "16.6: State 'Done' grep-recoverable after overwrite"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Canceled" 2>/dev/null
recovered_state=$(grep -m1 '^\- \*\*State:\*\*' "$TASK_STATE_FILE" | sed 's/^- \*\*State:\*\* //')
assert_eq "$recovered_state" "Canceled" "16.6: State 'Canceled' grep-recoverable from task STATE.md"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 17: Concurrency — --pipeline ∥ --pipeline and --pipeline ∥ --field ==="

PIPE_STATE17="${TMPDIR_BASE}/pipe17/STATE.md"
make_pipeline_state "$PIPE_STATE17"
AID_STATE_FILE="$PIPE_STATE17" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE17" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE17" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE17" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10T00:00:00Z" 2>/dev/null

# Remove any stale lock
rm -f "$(dirname "$PIPE_STATE17")/.writeback-state.lock"

# 17a: Concurrent --pipeline writes (4 parallel, different fields)
(
    AID_LOCK_DIR="$(dirname "$PIPE_STATE17")" AID_STATE_FILE="$PIPE_STATE17" \
        bash "$SCRIPT" --pipeline --field Lifecycle --value Completed &
    AID_LOCK_DIR="$(dirname "$PIPE_STATE17")" AID_STATE_FILE="$PIPE_STATE17" \
        bash "$SCRIPT" --pipeline --field Phase --value Deploy &
    AID_LOCK_DIR="$(dirname "$PIPE_STATE17")" AID_STATE_FILE="$PIPE_STATE17" \
        bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-release" &
    AID_LOCK_DIR="$(dirname "$PIPE_STATE17")" AID_STATE_FILE="$PIPE_STATE17" \
        bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10T12:00:00Z" &
    wait
)

assert_file_contains "$PIPE_STATE17" "## Pipeline State" "17a: ## Pipeline State section intact after concurrent pipeline writes"

BLOCK17=$(get_pipeline_block "$PIPE_STATE17")
assert_output_contains "$BLOCK17" "**Lifecycle:**" "17a: Lifecycle line present after concurrent writes"
assert_output_contains "$BLOCK17" "**Phase:**" "17a: Phase line present after concurrent writes"
assert_output_contains "$BLOCK17" "**Active Skill:**" "17a: Active Skill line present after concurrent writes"
assert_output_contains "$BLOCK17" "**Updated:**" "17a: Updated line present after concurrent writes"

for f_name in "Lifecycle" "Phase" "Active Skill" "Updated"; do
    count=$(echo "$BLOCK17" | grep -cF "**${f_name}:**" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17a: field '$f_name' appears exactly once in block (no duplication)"
    else
        fail "17a: field '$f_name' appears $count times in block (expected 1)"
    fi
done

if [[ ! -f "$(dirname "$PIPE_STATE17")/.writeback-state.lock" ]]; then
    pass "17a: no stale lock file after concurrent pipeline writes"
else
    fail "17a: stale lock file found — possible deadlock in concurrent pipeline writes"
fi

# 17b: Mixed --pipeline ∥ --field concurrent writes on the same STATE.md
# --field targets task STATE.md (different file from work STATE.md), so they
# use different lock files and can proceed fully in parallel.
PIPE_STATE17B="${TMPDIR_BASE}/pipe17b/STATE.md"
CONC17B_WORK="${TMPDIR_BASE}/pipe17b"
CONC17B_DELIV="${CONC17B_WORK}/deliveries/delivery-001"
make_pipeline_state "$PIPE_STATE17B"
make_delivery_state "$CONC17B_WORK" 1
make_task_state "$CONC17B_DELIV" 1
make_task_spec  "$CONC17B_DELIV" 1 1

AID_STATE_FILE="$PIPE_STATE17B" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE17B" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null

rm -f "${CONC17B_WORK}/.writeback-state.lock"

(
    AID_LOCK_DIR="${CONC17B_WORK}" AID_STATE_FILE="$PIPE_STATE17B" \
        bash "$SCRIPT" --pipeline --field Lifecycle --value Completed &
    AID_STATE_FILE="$PIPE_STATE17B" \
        bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Review" &
    AID_LOCK_DIR="${CONC17B_WORK}" AID_STATE_FILE="$PIPE_STATE17B" \
        bash "$SCRIPT" --pipeline --field Phase --value Deploy &
    AID_STATE_FILE="$PIPE_STATE17B" \
        bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value "note-concurrent" &
    wait
)

assert_file_contains "$PIPE_STATE17B" "## Pipeline State" "17b: Pipeline State intact after --pipeline ∥ --field mix"
assert_file_contains "${CONC17B_DELIV}/tasks/task-001/STATE.md" "## Task State" "17b: task STATE.md intact after mixed concurrent writes"

BLOCK17B=$(get_pipeline_block "$PIPE_STATE17B")
assert_output_contains "$BLOCK17B" "**Lifecycle:**" "17b: Lifecycle line present after mixed concurrent writes"
assert_output_contains "$BLOCK17B" "**Phase:**" "17b: Phase line present after mixed concurrent writes"

for f_name in "Lifecycle" "Phase"; do
    count=$(echo "$BLOCK17B" | grep -cF "**${f_name}:**" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17b: field '$f_name' appears exactly once after mixed concurrent writes"
    else
        fail "17b: field '$f_name' appears $count times in block after mixed writes (expected 1)"
    fi
done

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: FR16 derivation primitives — on-disk block determinism ==="

PIPE_STATE18="${TMPDIR_BASE}/pipe18/STATE.md"
make_pipeline_state "$PIPE_STATE18"

# 18a: Running state — Lifecycle readable, no conditional fields
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
BLOCK18=$(get_pipeline_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "**Lifecycle:** Running" "18a: FR16 Running — Lifecycle value derivable"
assert_output_not_contains "$BLOCK18" "**Pause Reason:**" "18a: FR16 Running — Pause Reason absent"
assert_output_not_contains "$BLOCK18" "**Block Reason:**" "18a: FR16 Running — Block Reason absent"
assert_output_not_contains "$BLOCK18" "**Block Artifact:**" "18a: FR16 Running — Block Artifact absent"

# 18b: Paused-Awaiting-Input state — Pause Reason present, Block fields absent
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Awaiting spec clarification" 2>/dev/null
BLOCK18=$(get_pipeline_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "**Lifecycle:** Paused-Awaiting-Input" "18b: FR16 Paused — Lifecycle value derivable"
assert_output_contains "$BLOCK18" "**Pause Reason:** Awaiting spec clarification" "18b: FR16 Paused — Pause Reason present"
assert_output_not_contains "$BLOCK18" "**Block Reason:**" "18b: FR16 Paused — Block Reason absent"
assert_output_not_contains "$BLOCK18" "**Block Artifact:**" "18b: FR16 Paused — Block Artifact absent"

# 18c: Blocked state — Block Reason + Block Artifact present, Pause Reason absent
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Blocked on external review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "pr-001.md" 2>/dev/null
BLOCK18=$(get_pipeline_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "**Lifecycle:** Blocked" "18c: FR16 Blocked — Lifecycle value derivable"
assert_output_contains "$BLOCK18" "**Block Reason:** Blocked on external review" "18c: FR16 Blocked — Block Reason present"
assert_output_contains "$BLOCK18" "**Block Artifact:** pr-001.md" "18c: FR16 Blocked — Block Artifact present"
assert_output_not_contains "$BLOCK18" "**Pause Reason:**" "18c: FR16 Blocked — Pause Reason absent"

# 18d: Completed state — no conditional fields
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
BLOCK18=$(get_pipeline_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "**Lifecycle:** Completed" "18d: FR16 Completed — Lifecycle value derivable"
assert_output_not_contains "$BLOCK18" "**Pause Reason:**" "18d: FR16 Completed — Pause Reason absent"
assert_output_not_contains "$BLOCK18" "**Block Reason:**" "18d: FR16 Completed — Block Reason absent"
assert_output_not_contains "$BLOCK18" "**Block Artifact:**" "18d: FR16 Completed — Block Artifact absent"

# 18e: Grep-recovery of field values from on-disk block
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
lc_val=$(grep -oP '(?<=\*\*Lifecycle:\*\* ).*' "$PIPE_STATE18" | head -1)
ph_val=$(grep -oP '(?<=\*\*Phase:\*\* ).*' "$PIPE_STATE18" | head -1)
as_val=$(grep -oP '(?<=\*\*Active Skill:\*\* ).*' "$PIPE_STATE18" | head -1)
assert_eq "$lc_val" "Running" "18e: FR16 Lifecycle value grep-recoverable from on-disk block"
assert_eq "$ph_val" "Execute" "18e: FR16 Phase value grep-recoverable from on-disk block"
assert_eq "$as_val" "aid-develop" "18e: FR16 Active Skill value grep-recoverable from on-disk block"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 19: M5 — pause/block signal sequences ==="

# 19a: Pause path (PAUSE-FOR-USER-ACTION emit sequence)
PIPE_STATE19A="${TMPDIR_BASE}/pipe19a/STATE.md"
make_pipeline_state "$PIPE_STATE19A"
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Phase --value Specify 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-specify 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Blocker pending — awaiting loopback resolution before /aid-specify can continue" 2>/dev/null || code=$?
assert_exit_zero "$code" "19a: Pause Reason emit after PAUSE transition → exit 0"
assert_file_contains "$PIPE_STATE19A" "**Lifecycle:** Paused-Awaiting-Input" "19a: Lifecycle set to Paused-Awaiting-Input"
assert_file_contains "$PIPE_STATE19A" "**Pause Reason:** Blocker pending" "19a: Pause Reason written"

# 19b: Resume path — M4 Running emit clears Pause Reason
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19A" "**Lifecycle:** Running" "19b: Lifecycle returns to Running on resume"
assert_file_not_contains "$PIPE_STATE19A" "**Pause Reason:**" "19b: Pause Reason cleared on Running transition (M4 resume)"

# 19c: Block path (impediment / Failed task emit sequence)
PIPE_STATE19C="${TMPDIR_BASE}/pipe19c/STATE.md"
WORK_19C="${TMPDIR_BASE}/pipe19c"
DELIV_19C="${WORK_19C}/deliveries/delivery-001"
make_pipeline_state "$PIPE_STATE19C"
make_delivery_state "$WORK_19C" 1
make_task_state "$DELIV_19C" 1

AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Failed" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Task failed with unresolved impediment — task-001" 2>/dev/null || code=$?
assert_exit_zero "$code" "19c: Block Reason emit after task failure → exit 0"
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-task-001.md" 2>/dev/null
assert_file_contains "$PIPE_STATE19C" "**Lifecycle:** Blocked" "19c: Lifecycle set to Blocked on task failure"
assert_file_contains "$PIPE_STATE19C" "**Block Reason:** Task failed" "19c: Block Reason written"
assert_file_contains "$PIPE_STATE19C" "**Block Artifact:** .aid/work-001/IMPEDIMENT-task-001.md" "19c: Block Artifact written"
assert_file_not_contains "$PIPE_STATE19C" "**Pause Reason:**" "19c: Pause Reason absent when Blocked"

# 19d: Block resolution path — M4 Running emit clears Block fields
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19C" "**Lifecycle:** Running" "19d: Lifecycle returns to Running after impediment resolved"
assert_file_not_contains "$PIPE_STATE19C" "**Block Reason:**" "19d: Block Reason cleared on Running transition"
assert_file_not_contains "$PIPE_STATE19C" "**Block Artifact:**" "19d: Block Artifact cleared on Running transition"

# 19e: Delivery-gate circuit-breaker block
PIPE_STATE19E="${TMPDIR_BASE}/pipe19e/STATE.md"
make_pipeline_state "$PIPE_STATE19E"
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Delivery gate circuit breaker triggered — grade not improving after 3 cycles" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-delivery-001.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "19e: Delivery gate circuit-breaker block emit → exit 0"
assert_file_contains "$PIPE_STATE19E" "**Lifecycle:** Blocked" "19e: Lifecycle Blocked on circuit-breaker stop"
assert_file_contains "$PIPE_STATE19E" "**Block Artifact:** .aid/work-001/IMPEDIMENT-delivery-001.md" "19e: Block Artifact is delivery IMPEDIMENT path"

# 19f: Delivery-gate non-CODE pause (non-CODE-only STOP → Paused-Awaiting-Input)
PIPE_STATE19F="${TMPDIR_BASE}/pipe19f/STATE.md"
make_pipeline_state "$PIPE_STATE19F"
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Delivery gate blocked on non-CODE issues — upstream fix required (SPEC/TASK/KB)" 2>/dev/null || code=$?
assert_exit_zero "$code" "19f: Delivery gate non-CODE pause emit → exit 0"
assert_file_contains "$PIPE_STATE19F" "**Lifecycle:** Paused-Awaiting-Input" "19f: Lifecycle Paused on non-CODE-only gate stop"
assert_file_contains "$PIPE_STATE19F" "**Pause Reason:** Delivery gate blocked on non-CODE issues" "19f: Pause Reason explains upstream fix needed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 20: Lite-path resolution (single delivery; no deliveries/ folder) ==="

# A lite work has exactly one delivery and no deliveries/ or delivery-NNN/ folder:
# tasks live directly at <work-root>/tasks/task-NNN/, and the single delivery's
# ## Delivery Lifecycle / ## Delivery Gate sections are AUTHORED directly in the
# work-root STATE.md (work-001-add-deliveries-folder task-001/task-003).
LITE_WORK="${TMPDIR_BASE}/lite-work"
mkdir -p "$LITE_WORK"
cat > "${LITE_WORK}/STATE.md" <<'LITEWORKEOF'
# Work State — work-lite-test

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-18T00:00:00Z

## Delivery Lifecycle

- **State:** Executing
- **Updated:** 2026-06-18T00:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Gate

- **Reviewer Tier:** --
- **Grade:** Pending
- **Issue List:** none
- **Timestamp:** --
LITEWORKEOF

make_task_state "$LITE_WORK" 1
make_task_spec  "$LITE_WORK" 1 1 "work-lite-test"

# 20a: --task-id --delivery-id --field --value resolves directly to tasks/task-NNN/STATE.md
# (no deliveries/ parent -- the lite-path branch in resolve_task_state_file).
code=0
AID_STATE_FILE="${LITE_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null || code=$?
assert_exit_zero "$code" "20a: lite-path --task-id --field → exit 0"
assert_file_contains "${LITE_WORK}/tasks/task-001/STATE.md" "**State:** In Progress" "20a: lite-path task STATE.md written directly under tasks/ (no deliveries/)"
if [[ ! -e "${LITE_WORK}/deliveries" ]]; then
    pass "20a: no deliveries/ folder created for lite-path task write"
else
    fail "20a: no deliveries/ folder created for lite-path task write — found ${LITE_WORK}/deliveries"
fi

# 20b: Source-line delivery resolution also works for the lite-flat SPEC.md location
# (tasks/task-NNN/SPEC.md directly under the work root, no --delivery-id supplied).
code=0
AID_STATE_FILE="${LITE_WORK}/STATE.md" bash "$SCRIPT" --task-id 1 --field Notes --value "auto-resolved-lite" 2>/dev/null || code=$?
assert_exit_zero "$code" "20b: lite-path source-line resolution (--delivery-id omitted) → exit 0"
assert_file_contains "${LITE_WORK}/tasks/task-001/STATE.md" "auto-resolved-lite" "20b: Notes written via lite-path source-line resolution"

# 20c: --delivery-id --lifecycle targets the work-root STATE.md's own
# ## Delivery Lifecycle section directly (no per-delivery STATE.md file exists
# for a lite work -- the lite-path branch in resolve_delivery_state_file).
code=0
AID_STATE_FILE="${LITE_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated" 2>/dev/null || code=$?
assert_exit_zero "$code" "20c: lite-path --delivery-id --lifecycle → exit 0"
assert_file_contains "${LITE_WORK}/STATE.md" "**State:** Gated" "20c: work-root STATE.md ## Delivery Lifecycle updated in place"
assert_file_contains "${LITE_WORK}/STATE.md" "## Pipeline State" "20c: work-root ## Pipeline State section untouched"

# 20d: --delivery-id --block targets the same work-root STATE.md's ## Delivery Gate
# section (still no separate delivery-level STATE.md / deliveries/ folder created).
LITE_GATE_BLOCK="- **Reviewer Tier:** Small
- **Grade:** A+
- **Issue List:** none
- **Timestamp:** 2026-06-18T01:00:00Z"
code=0
AID_STATE_FILE="${LITE_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --block "$LITE_GATE_BLOCK" 2>/dev/null || code=$?
assert_exit_zero "$code" "20d: lite-path --delivery-id --block → exit 0"
assert_file_contains "${LITE_WORK}/STATE.md" "**Grade:** A+" "20d: work-root STATE.md ## Delivery Gate updated in place"
if [[ ! -e "${LITE_WORK}/deliveries" ]]; then
    pass "20d: no deliveries/ folder created for lite-path delivery gate write"
else
    fail "20d: no deliveries/ folder created for lite-path delivery gate write — found ${LITE_WORK}/deliveries"
fi

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
