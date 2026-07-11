#!/usr/bin/env bash
# test-writeback-state.sh — smoke-test harness for writeback-state.sh
#
# Covers the NEW per-unit writeback contract (work-004 Pillar 2 retarget).
# All writes go to per-unit STATE.md files, NOT to the monolithic work STATE.md.
#
# Unit layout under test:
#   work-NNN-{name}/
#     STATE.md                          -- work-level (--pipeline target only)
#     deliveries/
#       delivery-NNN/
#         STATE.md                        -- delivery-level (--block / --lifecycle target)
#         tasks/
#           task-NNN/
#             DETAIL.md                   -- contains **Source:** line for delivery resolution
#             STATE.md                    -- task-level (--field / --findings target)
#
# Test scenarios:
#   Unit 1: --task-id --delivery-id --field --value  (per-task STATE.md field update)
#   Unit 2: --task-id --delivery-id --findings       (per-task ## Quick Check Findings)
#   Unit 3: --delivery-id --block                    (per-delivery ## Delivery Gate)
#   Unit 4: --delivery-id --lifecycle                (per-delivery ## Delivery Lifecycle)
#   Unit 5: --delivery-id --append-issue             (delivery-NNN-issues.md append)
#   Unit 6: Source-line delivery resolution          (--delivery-id omitted, DETAIL.md used)
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
#   Unit 21: octal footgun regression — zero-padded ids containing 8/9 (008, 090)
#            must resolve via base-10 (not be misparsed as invalid octal)
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
# Creates deliveries/delivery-NNN/tasks/task-NNN/STATE.md matching the CURRENT
# task-state-template.md shape (task-001/004): state/review/elapsed/notes live
# in the leading YAML frontmatter block; the ## Task State body section is
# comment-only (no bullets -- those were relocated to frontmatter).
# STATE_VALUE defaults to "Pending".
make_task_state() {
    local delivery_dir="$1" task_id="$2" state_val="${3:-Pending}"
    local padded_t
    padded_t=$(printf '%03d' "$task_id")
    local task_dir="${delivery_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/STATE.md" <<TASKSTATEOF
---
state: ${state_val}
review: --
elapsed: --
notes: --
---

# Task State -- task-${padded_t}

> **Task:** task-${padded_t}

---

## Task State

<!-- values live in the frontmatter block above (task-001/004). -->

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
# Creates deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md with a **Source:** line.
make_task_spec() {
    local delivery_dir="$1" task_id="$2" delivery_id="$3" work_name="${4:-work-004-test}"
    local padded_t padded_d
    padded_t=$(printf '%03d' "$task_id")
    padded_d=$(printf '%03d' "$delivery_id")
    local task_dir="${delivery_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/DETAIL.md" <<TASKSPECEOF
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
# Creates deliveries/delivery-NNN/STATE.md matching the CURRENT
# delivery-state-template.md shape (task-001/004): delivery_state/gate_tier/
# gate_grade/gate_timestamp live in the leading YAML frontmatter block; the
# ## Delivery Lifecycle / ## Delivery Gate body sections keep only the
# non-relocated bullets (Updated/Block Reason/Block Artifact/Issue List).
# LIFECYCLE_VALUE defaults to "Executing".
make_delivery_state() {
    local work_dir="$1" delivery_id="$2" lc_val="${3:-Executing}"
    local padded_d
    padded_d=$(printf '%03d' "$delivery_id")
    local delivery_dir="${work_dir}/deliveries/delivery-${padded_d}"
    mkdir -p "$delivery_dir"
    cat > "${delivery_dir}/STATE.md" <<DELIVSTATEOF
---
delivery_state: ${lc_val}
gate_tier: --
gate_grade: Pending
gate_timestamp: --
---

# Delivery State -- delivery-${padded_d}

> **Delivery:** delivery-${padded_d}

---

## Delivery Lifecycle

- **Updated:** 2026-06-18T00:00:00Z

---

## Delivery Gate

- **Issue List:** none

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
# Global workspace: work root + delivery-001 (tasks 1..5) + delivery-002 (task 6)
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

# Regression guard: the `---` separator between ## Quick Check Findings and
# ## Dispatch Log (task-state-template.md) must survive the --findings
# rewrite untouched. mode_findings shares the same "swallow everything up to
# the next `## ` heading" awk pattern as mode_delivery_block (## Delivery
# Gate), which was found to delete an intervening `---` separator.
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "## Dispatch Log" "task-001 STATE.md ## Dispatch Log survives the --findings rewrite"
FINDINGS_TO_LOG=$(awk '/^## Quick Check Findings/{f=1} f{print} /^## Dispatch Log/{exit}' "${DELIVERY_001}/tasks/task-001/STATE.md")
if echo "$FINDINGS_TO_LOG" | grep -qE '^---$'; then
    pass "--- separator between ## Quick Check Findings and ## Dispatch Log survives the --findings rewrite"
else
    fail "--- separator between ## Quick Check Findings and ## Dispatch Log was deleted by the --findings rewrite"
fi

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
assert_file_contains "${DELIVERY_001}/STATE.md" "delivery_state: Gated" "delivery-001 frontmatter delivery_state set to Gated"
# Work STATE.md must NOT be touched
assert_file_not_contains "${WORK_DIR}/STATE.md" "Gated" "work STATE.md NOT modified by --lifecycle (isolation)"

# Advance through each enum member
for lc_val in "Pending-Spec" "Specified" "Executing" "Gated" "Done" "Blocked"; do
    code=0
    bash "$SCRIPT" --delivery-id 2 --lifecycle "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "--lifecycle $lc_val accepted (exit 0)"
done
assert_file_contains "${DELIVERY_002}/STATE.md" "delivery_state: Blocked" "delivery-002 frontmatter delivery_state advanced to Blocked"

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

# The task DETAIL.md already contains "**Source:** work-004-test -> delivery-001".
# Resolve the delivery from that line and write to the correct task STATE.md.
# We must supply AID_STATE_FILE so the script knows the work root.
code=0
bash "$SCRIPT" --task-id 3 --field State --value "In Review" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-3 → delivery-001, exit 0"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.md" "In Review" "task-003 State written via source-line resolution"

# task-6 is in delivery-002 per its DETAIL.md
code=0
bash "$SCRIPT" --task-id 6 --field Notes --value "auto-resolved" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-6 → delivery-002, exit 0"
assert_file_contains "${DELIVERY_002}/tasks/task-006/STATE.md" "auto-resolved" "task-006 Notes written via source-line resolution"

# Omit delivery-id AND have no DETAIL.md → must fail with exit 5
ORPHAN_WORK="${TMPDIR_BASE}/orphan-work"
mkdir -p "$ORPHAN_WORK"
make_task_state "$ORPHAN_WORK/deliveries/delivery-001" 99  # state only, no DETAIL.md
code=0
AID_STATE_FILE="${ORPHAN_WORK}/STATE.md" bash "$SCRIPT" --task-id 99 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 5 "no --delivery-id + no DETAIL.md → exit 5 (cannot resolve delivery)"

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
echo "=== Unit 9: --pipeline field writes (frontmatter creation + each base field; task-004) ==="

# make_pipeline_state: a work STATE.md with NO frontmatter at all (an
# un-migrated, pre-task-001 file) -- exercises wb_set_frontmatter's
# from-scratch synthesis path. ## Triage / ## Deploy State stand in for
# arbitrary body content that must survive byte-unchanged.
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

# get_frontmatter_block FILE — the raw text between the leading `---` fences
# (empty string if the file has no frontmatter block).
get_frontmatter_block() {
    local f="$1"
    awk 'NR==1 && $0!~/^---[ \t]*$/{exit} NR==1{f=1; next} f && /^---[ \t]*$/{exit} f{print}' "$f"
}

PIPE_STATE="${TMPDIR_BASE}/pipe09/STATE.md"
make_pipeline_state "$PIPE_STATE"
BODY_BEFORE_09_FILE="${TMPDIR_BASE}/pipe09/before-body.txt"
cp "$PIPE_STATE" "$BODY_BEFORE_09_FILE"

# 9a: No frontmatter yet — writing Lifecycle synthesizes one (task-004)
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_zero "$code" "9a: Lifecycle write with no prior frontmatter → exit 0"
assert_file_contains "$PIPE_STATE" "lifecycle: Running" "9a: lifecycle frontmatter key written"
if head -1 "$PIPE_STATE" | grep -qE '^---[ \t]*$'; then
    pass "9a: frontmatter block synthesized at the top of the file"
else
    fail "9a: no frontmatter fence found at the top of the file after synthesis"
fi

# 9b: Phase field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "9b: Phase write → exit 0"
assert_file_contains "$PIPE_STATE" "phase: Execute" "9b: Phase field written"

# 9c: Active Skill field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null || code=$?
assert_exit_zero "$code" "9c: Active Skill write → exit 0"
assert_file_contains "$PIPE_STATE" "active_skill: aid-develop" "9c: Active Skill field written"

# 9d: Updated field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "9d: Updated write → exit 0"
assert_file_contains "$PIPE_STATE" "updated: 2026-06-10" "9d: Updated field written"

# 9e: All four base fields coexist in the frontmatter block
PIPE_BLOCK=$(get_frontmatter_block "$PIPE_STATE")
assert_output_contains "$PIPE_BLOCK" "lifecycle: Running" "9e: lifecycle grep-recoverable in frontmatter block"
assert_output_contains "$PIPE_BLOCK" "phase: Execute" "9e: phase grep-recoverable in frontmatter block"
assert_output_contains "$PIPE_BLOCK" "active_skill: aid-develop" "9e: active_skill grep-recoverable in frontmatter block"
assert_output_contains "$PIPE_BLOCK" "updated: 2026-06-10" "9e: updated grep-recoverable in frontmatter block"

# 9f: Other STATE.md sections not disturbed
assert_file_contains "$PIPE_STATE" "## Triage" "9f: Triage section preserved after pipeline writes"
assert_file_contains "$PIPE_STATE" "## Deploy State" "9f: Deploy State section preserved after pipeline writes"

# 9f-2: body byte-invariance — the ENTIRE original file content (now the body,
# following the synthesized frontmatter) is still present byte-for-byte.
# Locate the closing fence dynamically instead of a hardcoded line number, and
# compare via `cmp` (byte-exact file comparison) rather than `$(...)` command
# substitution -- the latter silently strips trailing newlines, which would
# hide exactly the class of regression (findings 4/5, task-004 FIX review)
# this check exists to catch.
CLOSE_LINE_09=$(awk '/^---[ \t]*$/{n++; if(n==2){print NR; exit}}' "$PIPE_STATE")
BODY_AFTER_09_FILE="${TMPDIR_BASE}/pipe09/after-body.txt"
tail -n "+$((CLOSE_LINE_09 + 2))" "$PIPE_STATE" > "$BODY_AFTER_09_FILE"
if cmp -s "$BODY_BEFORE_09_FILE" "$BODY_AFTER_09_FILE"; then
    pass "9f-2: original file content preserved byte-for-byte as the BODY after frontmatter synthesis"
else
    fail "9f-2: BODY changed after frontmatter synthesis (byte-invariance violated) — cmp: $(cmp "$BODY_BEFORE_09_FILE" "$BODY_AFTER_09_FILE" 2>&1)"
fi

# 9g: No frontmatter yet — writing a non-Lifecycle field (Phase) also synthesizes one
PIPE_STATE_G="${TMPDIR_BASE}/pipe09g/STATE.md"
make_pipeline_state "$PIPE_STATE_G"
code=0
AID_STATE_FILE="$PIPE_STATE_G" bash "$SCRIPT" --pipeline --field Phase --value Plan 2>/dev/null || code=$?
assert_exit_zero "$code" "9g: Phase write with no prior frontmatter → exit 0"
if head -1 "$PIPE_STATE_G" | grep -qE '^---[ \t]*$'; then
    pass "9g: frontmatter block created by Phase write"
else
    fail "9g: no frontmatter fence found after Phase write"
fi
assert_file_contains "$PIPE_STATE_G" "phase: Plan" "9g: Phase field written on new frontmatter block"

# 9h: Update (overwrite) an existing field value
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
assert_file_contains "$PIPE_STATE" "lifecycle: Completed" "9h: Lifecycle field overwritten to Completed"
assert_file_not_contains "$PIPE_STATE" "lifecycle: Running" "9h: old Lifecycle value Running removed"

# 9i: Active Skill set to 'none' is valid
PIPE_STATE_I="${TMPDIR_BASE}/pipe09i/STATE.md"
make_pipeline_state "$PIPE_STATE_I"
code=0
AID_STATE_FILE="$PIPE_STATE_I" bash "$SCRIPT" --pipeline --field "Active Skill" --value "none" 2>/dev/null || code=$?
assert_exit_zero "$code" "9i: Active Skill=none is valid → exit 0"
assert_file_contains "$PIPE_STATE_I" "active_skill: none" "9i: Active Skill none written"

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

# 10d: All valid Phase values accepted (rc 0) -- work-003-state-schema task-010:
# faithful 6-phase pipeline (Interview split into Describe+Define; Monitor removed).
for ph_val in Describe Define Specify Plan Detail Execute Deploy; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "10d: Phase=$ph_val accepted (exit 0)"
done

# 10d-ii: retired Phase values rejected on WRITE (task-010) -- the reader's
# back-compat alias (Interview -> Describe, Monitor -> Unknown) is a READ-side
# concession for pre-migration files; writers must emit only the new enum.
for ph_val in Interview Monitor; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_eq "$code" 4 "10d-ii: Phase=$ph_val (retired) rejected (exit 4)"
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
assert_file_contains "$PIPE_STATE11A" "pause_reason: 'Waiting for user clarification'" "11a: Pause Reason field written"

# 11b: Block Reason + Block Artifact written when Lifecycle=Blocked
PIPE_STATE11B="${TMPDIR_BASE}/pipe11b/STATE.md"
make_cond_state "$PIPE_STATE11B"
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Waiting for dependency" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Reason write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE11B" "block_reason: 'Waiting for dependency'" "11b: Block Reason field written"
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "task-007.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Artifact write under Blocked → exit 0"
assert_file_contains "$PIPE_STATE11B" "block_artifact: task-007.md" "11b: Block Artifact field written"

# 11c: Transition OUT of Paused-Awaiting-Input clears Pause Reason (reset to the
# "--" null sentinel -- the key stays present, just cleared)
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_contains "$PIPE_STATE11A" "pause_reason: --" "11c: Pause Reason cleared after Lifecycle→Running"
assert_file_not_contains "$PIPE_STATE11A" "Waiting for user clarification" "11c: old Pause Reason value gone after clear"

# 11d: Transition OUT of Blocked clears Block Reason and Block Artifact
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_contains "$PIPE_STATE11B" "block_reason: --" "11d: Block Reason cleared after Lifecycle→Running"
assert_file_contains "$PIPE_STATE11B" "block_artifact: --" "11d: Block Artifact cleared after Lifecycle→Running"
assert_file_not_contains "$PIPE_STATE11B" "Waiting for dependency" "11d: old Block Reason value gone after clear"

# 11e: Pause Reason cleared when Lifecycle transitions to Blocked
PIPE_STATE11E="${TMPDIR_BASE}/pipe11e/STATE.md"
make_cond_state "$PIPE_STATE11E"
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
assert_file_contains "$PIPE_STATE11E" "pause_reason: --" "11e: Pause Reason cleared when Lifecycle transitions to Blocked"
assert_file_not_contains "$PIPE_STATE11E" "Waiting for input" "11e: old Pause Reason value gone after Blocked transition"

# 11f: Block Reason + Artifact reset to -- after transition from Blocked to Completed
PIPE_STATE11F="${TMPDIR_BASE}/pipe11f/STATE.md"
make_cond_state "$PIPE_STATE11F"
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Needs review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "review-001.md" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Completed" 2>/dev/null
assert_file_contains "$PIPE_STATE11F" "block_reason: --" "11f: Block Reason cleared on Lifecycle→Completed"
assert_file_contains "$PIPE_STATE11F" "block_artifact: --" "11f: Block Artifact cleared on Lifecycle→Completed"

# 11g: Fresh Running state — conditional fields present but at the -- sentinel
PIPE_STATE11G="${TMPDIR_BASE}/pipe11g/STATE.md"
make_cond_state "$PIPE_STATE11G"
assert_file_contains "$PIPE_STATE11G" "block_reason: --" "11g: Block Reason at -- sentinel on fresh Running state"
assert_file_contains "$PIPE_STATE11G" "block_artifact: --" "11g: Block Artifact at -- sentinel on fresh Running state"
assert_file_contains "$PIPE_STATE11G" "pause_reason: --" "11g: Pause Reason at -- sentinel on fresh Running state"

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
    # wb_set_frontmatter single-quotes only values that need it (contain a
    # space, e.g. "In Progress"/"In Review"); bare single-word values stay
    # unquoted (task-004 FIX review finding 1 -- single-quote style, not
    # double-quote + backslash-escaping).
    if [[ "$state_val" =~ ^[A-Za-z0-9_./+-]+$ ]]; then
        EXPECT16="state: ${state_val}"
    else
        EXPECT16="state: '${state_val}'"
    fi
    assert_file_contains "${S16_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
        "$EXPECT16" "16.1: State='${state_val}' written to task STATE.md frontmatter"
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
    # STATE.md frontmatter still shows Pending
    assert_file_contains "${S16_BAD_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md" \
        "state: Pending" "16.3: task STATE.md unchanged after rejection of '${bad_val}'"
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

# 16.6 — State value grep-recoverable in task STATE.md frontmatter (task-004)
echo ""
echo "--- 16.6: Deterministic consumability — State grep-recoverable in task STATE.md frontmatter ---"

S16_CONS_WORK="${TMPDIR_BASE}/unit16-cons/work"
make_work_state "$S16_CONS_WORK"
make_delivery_state "$S16_CONS_WORK" 1
make_task_state "${S16_CONS_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_CONS_WORK}/deliveries/delivery-001" 1 1

TASK_STATE_FILE="${S16_CONS_WORK}/deliveries/delivery-001/tasks/task-001/STATE.md"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "In Review" 2>/dev/null
assert_file_contains "$TASK_STATE_FILE" "## Task State" "16.6: ## Task State section present after State write"
assert_file_contains "$TASK_STATE_FILE" "state: 'In Review'" "16.6: 'In Review' written as state: line in the frontmatter block"

# Recover via grep (single-quoted scalar; strip one layer of surrounding
# quotes -- either style -- as the reader twins'
# parse_frontmatter_scalars/parseFrontmatterScalars do)
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "In Review" "16.6: State value grep-recoverable from task STATE.md frontmatter"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "Done" "16.6: State 'Done' grep-recoverable after overwrite"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.md" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Canceled" 2>/dev/null
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "Canceled" "16.6: State 'Canceled' grep-recoverable from task STATE.md frontmatter"

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

assert_file_contains "$PIPE_STATE17" "## Triage" "17a: unrelated body section intact after concurrent pipeline writes"

BLOCK17=$(get_frontmatter_block "$PIPE_STATE17")
assert_output_contains "$BLOCK17" "lifecycle:" "17a: lifecycle line present after concurrent writes"
assert_output_contains "$BLOCK17" "phase:" "17a: phase line present after concurrent writes"
assert_output_contains "$BLOCK17" "active_skill:" "17a: active_skill line present after concurrent writes"
assert_output_contains "$BLOCK17" "updated:" "17a: updated line present after concurrent writes"

for f_name in "lifecycle" "phase" "active_skill" "updated"; do
    count=$(echo "$BLOCK17" | grep -cE "^${f_name}:" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17a: field '$f_name' appears exactly once in frontmatter (no duplication)"
    else
        fail "17a: field '$f_name' appears $count times in frontmatter (expected 1)"
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

assert_file_contains "$PIPE_STATE17B" "## Triage" "17b: unrelated body section intact after --pipeline ∥ --field mix"
assert_file_contains "${CONC17B_DELIV}/tasks/task-001/STATE.md" "## Task State" "17b: task STATE.md intact after mixed concurrent writes"

BLOCK17B=$(get_frontmatter_block "$PIPE_STATE17B")
assert_output_contains "$BLOCK17B" "lifecycle:" "17b: lifecycle line present after mixed concurrent writes"
assert_output_contains "$BLOCK17B" "phase:" "17b: phase line present after mixed concurrent writes"

for f_name in "lifecycle" "phase"; do
    count=$(echo "$BLOCK17B" | grep -cE "^${f_name}:" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17b: field '$f_name' appears exactly once after mixed concurrent writes"
    else
        fail "17b: field '$f_name' appears $count times in frontmatter after mixed writes (expected 1)"
    fi
done

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: FR16 derivation primitives — on-disk block determinism ==="

PIPE_STATE18="${TMPDIR_BASE}/pipe18/STATE.md"
make_pipeline_state "$PIPE_STATE18"

# 18a: Running state — lifecycle readable, conditional fields at the -- sentinel
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
BLOCK18=$(get_frontmatter_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "lifecycle: Running" "18a: FR16 Running — lifecycle value derivable"
assert_output_contains "$BLOCK18" "pause_reason: --" "18a: FR16 Running — pause_reason at -- sentinel"
assert_output_contains "$BLOCK18" "block_reason: --" "18a: FR16 Running — block_reason at -- sentinel"
assert_output_contains "$BLOCK18" "block_artifact: --" "18a: FR16 Running — block_artifact at -- sentinel"

# 18b: Paused-Awaiting-Input state — pause_reason present, Block fields at --
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Awaiting spec clarification" 2>/dev/null
BLOCK18=$(get_frontmatter_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "lifecycle: Paused-Awaiting-Input" "18b: FR16 Paused — lifecycle value derivable"
assert_output_contains "$BLOCK18" "pause_reason: 'Awaiting spec clarification'" "18b: FR16 Paused — pause_reason present"
assert_output_contains "$BLOCK18" "block_reason: --" "18b: FR16 Paused — block_reason at -- sentinel"
assert_output_contains "$BLOCK18" "block_artifact: --" "18b: FR16 Paused — block_artifact at -- sentinel"

# 18c: Blocked state — Block Reason + Block Artifact present, pause_reason at --
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Blocked on external review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "pr-001.md" 2>/dev/null
BLOCK18=$(get_frontmatter_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "lifecycle: Blocked" "18c: FR16 Blocked — lifecycle value derivable"
assert_output_contains "$BLOCK18" "block_reason: 'Blocked on external review'" "18c: FR16 Blocked — block_reason present"
assert_output_contains "$BLOCK18" "block_artifact: pr-001.md" "18c: FR16 Blocked — block_artifact present"
assert_output_contains "$BLOCK18" "pause_reason: --" "18c: FR16 Blocked — pause_reason at -- sentinel"

# 18d: Completed state — all conditional fields at the -- sentinel
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
BLOCK18=$(get_frontmatter_block "$PIPE_STATE18")
assert_output_contains "$BLOCK18" "lifecycle: Completed" "18d: FR16 Completed — lifecycle value derivable"
assert_output_contains "$BLOCK18" "pause_reason: --" "18d: FR16 Completed — pause_reason at -- sentinel"
assert_output_contains "$BLOCK18" "block_reason: --" "18d: FR16 Completed — block_reason at -- sentinel"
assert_output_contains "$BLOCK18" "block_artifact: --" "18d: FR16 Completed — block_artifact at -- sentinel"

# 18e: Grep-recovery of field values from the on-disk frontmatter block
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
lc_val=$(grep -m1 '^lifecycle:' "$PIPE_STATE18" | sed 's/^lifecycle:[ \t]*//')
ph_val=$(grep -m1 '^phase:' "$PIPE_STATE18" | sed 's/^phase:[ \t]*//')
as_val=$(grep -m1 '^active_skill:' "$PIPE_STATE18" | sed 's/^active_skill:[ \t]*//')
assert_eq "$lc_val" "Running" "18e: FR16 lifecycle value grep-recoverable from on-disk frontmatter"
assert_eq "$ph_val" "Execute" "18e: FR16 phase value grep-recoverable from on-disk frontmatter"
assert_eq "$as_val" "aid-develop" "18e: FR16 active_skill value grep-recoverable from on-disk frontmatter"

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
assert_file_contains "$PIPE_STATE19A" "lifecycle: Paused-Awaiting-Input" "19a: Lifecycle set to Paused-Awaiting-Input"
assert_file_contains "$PIPE_STATE19A" "pause_reason: 'Blocker pending" "19a: Pause Reason written"

# 19b: Resume path — M4 Running emit clears Pause Reason
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19A" "lifecycle: Running" "19b: Lifecycle returns to Running on resume"
assert_file_contains "$PIPE_STATE19A" "pause_reason: --" "19b: Pause Reason cleared on Running transition (M4 resume)"
assert_file_not_contains "$PIPE_STATE19A" "Blocker pending" "19b: old Pause Reason text gone after clear"

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
assert_file_contains "$PIPE_STATE19C" "lifecycle: Blocked" "19c: Lifecycle set to Blocked on task failure"
assert_file_contains "$PIPE_STATE19C" "block_reason: 'Task failed" "19c: Block Reason written"
assert_file_contains "$PIPE_STATE19C" "block_artifact: .aid/work-001/IMPEDIMENT-task-001.md" "19c: Block Artifact written"
assert_file_contains "$PIPE_STATE19C" "pause_reason: --" "19c: Pause Reason at -- sentinel when Blocked"

# 19d: Block resolution path — M4 Running emit clears Block fields
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19C" "lifecycle: Running" "19d: Lifecycle returns to Running after impediment resolved"
assert_file_contains "$PIPE_STATE19C" "block_reason: --" "19d: Block Reason cleared on Running transition"
assert_file_contains "$PIPE_STATE19C" "block_artifact: --" "19d: Block Artifact cleared on Running transition"
assert_file_not_contains "$PIPE_STATE19C" "IMPEDIMENT-task-001.md" "19d: old Block Artifact value gone after clear"

# 19e: Delivery-gate circuit-breaker block
PIPE_STATE19E="${TMPDIR_BASE}/pipe19e/STATE.md"
make_pipeline_state "$PIPE_STATE19E"
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Delivery gate circuit breaker triggered — grade not improving after 3 cycles" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-delivery-001.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "19e: Delivery gate circuit-breaker block emit → exit 0"
assert_file_contains "$PIPE_STATE19E" "lifecycle: Blocked" "19e: Lifecycle Blocked on circuit-breaker stop"
assert_file_contains "$PIPE_STATE19E" "block_artifact: .aid/work-001/IMPEDIMENT-delivery-001.md" "19e: Block Artifact is delivery IMPEDIMENT path"

# 19f: Delivery-gate non-CODE pause (non-CODE-only STOP → Paused-Awaiting-Input)
PIPE_STATE19F="${TMPDIR_BASE}/pipe19f/STATE.md"
make_pipeline_state "$PIPE_STATE19F"
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Delivery gate blocked on non-CODE issues — upstream fix required (SPEC/TASK/KB)" 2>/dev/null || code=$?
assert_exit_zero "$code" "19f: Delivery gate non-CODE pause emit → exit 0"
assert_file_contains "$PIPE_STATE19F" "lifecycle: Paused-Awaiting-Input" "19f: Lifecycle Paused on non-CODE-only gate stop"
assert_file_contains "$PIPE_STATE19F" "pause_reason: 'Delivery gate blocked on non-CODE issues" "19f: Pause Reason explains upstream fix needed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 20: feature-001 flattened single-delivery layout (auto-detected) ==="

# Flat layout fixture: no deliveries/ wrapper; tasks/task-NNN/DETAIL.md directly
# under the work root; the promoted ## Delivery Lifecycle (### Tasks lifecycle)
# and ## Delivery Gate blocks live in the work-root STATE.md.

# make_flat_task_spec WORK_DIR TASK_ID
# Creates tasks/task-NNN/DETAIL.md directly under the work root (no per-task STATE.md).
make_flat_task_spec() {
    local work_dir="$1" task_id="$2"
    local padded_t
    padded_t=$(printf '%03d' "$task_id")
    local task_dir="${work_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/DETAIL.md" <<FLATTASKEOF
# task-${padded_t}: Flat test task

**Type:** IMPLEMENT

**Source:** work-flat-test -> delivery-001

**Depends on:** --

**Scope:**
- Test scope for flat task ${padded_t}

**Acceptance Criteria:**
- [ ] criterion
FLATTASKEOF
}

# make_flat_work_state WORK_DIR
# Creates the work-root STATE.md with the three promoted feature-001 blocks:
# ## Delivery Lifecycle (+ ### Tasks lifecycle) and ## Delivery Gate.
make_flat_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.md" <<'FLATSTATEEOF'
# Work State — work-flat-test

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-07-08T00:00:00Z

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-08T00:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| _none yet_ | | | | |

## Delivery Gate

- **Reviewer Tier:** Small
- **Grade:** Pending
- **Issue List:** none
- **Timestamp:** --

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     ============================================================ -->

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
FLATSTATEEOF
}

# make_flat_blueprint WORK_DIR: the work-root BLUEPRINT.md (delivery definition).
make_flat_blueprint() {
    local work_dir="$1"
    cat > "${work_dir}/BLUEPRINT.md" <<'FLATBPEOF'
# Delivery BLUEPRINT -- delivery-001: Flat test delivery

## Gate Criteria
- [ ] criterion
FLATBPEOF
}

FLAT_WORK="${TMPDIR_BASE}/work-flat-test"
make_flat_work_state "$FLAT_WORK"
make_flat_blueprint "$FLAT_WORK"
make_flat_task_spec "$FLAT_WORK" 1
make_flat_task_spec "$FLAT_WORK" 2

FLAT_STATE="${FLAT_WORK}/STATE.md"

# 20a: --task-id --field --value on the flat layout targets the work-root
# STATE.md's ### Tasks lifecycle table -- NOT a per-task STATE.md (none exists).
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null || code=$?
assert_exit_zero "$code" "20a: flat --field write → exit 0"
assert_file_contains "$FLAT_STATE" "| task-001 | In Progress |" "20a: task-001 row written to ### Tasks lifecycle"
if [[ ! -f "${FLAT_WORK}/tasks/task-001/STATE.md" ]]; then
    pass "20a: no per-task STATE.md created for the flat layout"
else
    fail "20a: a per-task STATE.md was created — flat layout must not use one"
fi

# 20b: the ### Tasks lifecycle placeholder row is replaced, not left dangling.
# NOTE: must match the exact 5-column "### Tasks lifecycle" placeholder LINE,
# not a bare substring check -- the fixture's OWN plural DERIVED "## Tasks
# State" section (8 columns) legitimately keeps its own "_none yet_" placeholder
# forever on the flat layout (nothing ever populates that unused view), and the
# 8-column placeholder line's first 6 pipe-delimited cells are byte-identical
# to the ENTIRE 5-column placeholder line -- a plain `grep -F` substring test
# (assert_file_not_contains) would ALWAYS find the 5-column string as a prefix
# of the 8-column line and could never pass. Use `grep -x` (exact whole-line
# match) instead, matching what the comment above always intended.
if grep -qxF "| _none yet_ | | | | |" "$FLAT_STATE"; then
    fail "20b: ### Tasks lifecycle placeholder row replaced by the first real task row — exact 5-column placeholder line still present"
else
    pass "20b: ### Tasks lifecycle placeholder row replaced by the first real task row"
fi
assert_file_contains "$FLAT_STATE" "| _none yet_ | | | | | | | |" "20b: unrelated plural DERIVED ## Tasks State placeholder is untouched"

# 20c: a second task's first write APPENDS a contiguous row (no blank line
# splitting the table into two blocks)
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 2 --field State --value "Pending" 2>/dev/null || code=$?
assert_exit_zero "$code" "20c: second flat task --field write → exit 0"
assert_file_contains "$FLAT_STATE" "| task-002 | Pending |" "20c: task-002 row appended to ### Tasks lifecycle"
# Contiguity: the line between the task-001 and task-002 rows must itself be
# a table row (not blank), i.e. the two rows are adjacent in the file.
BETWEEN_ROWS=$(awk '/^\| task-001 \|/{f=1; next} f{print; exit}' "$FLAT_STATE")
if [[ "$BETWEEN_ROWS" == "| task-002 |"* ]]; then
    pass "20c: appended row is contiguous with the existing table (no blank-line split)"
else
    fail "20c: appended row broke table contiguity — line after task-001 was: '$BETWEEN_ROWS'"
fi

# 20d: updating a different field on an existing row preserves the other columns
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Review --value "A" 2>/dev/null || code=$?
assert_exit_zero "$code" "20d: flat --field Review write on existing row → exit 0"
assert_file_contains "$FLAT_STATE" "| task-001 | In Progress | A |" "20d: task-001 Review set to A, State preserved"
assert_file_contains "$FLAT_STATE" "| task-002 | Pending |" "20d: task-002 row unaffected by task-001 update"

# 20e: --delivery-id 001 --lifecycle updates the work-root frontmatter's
# delivery_state key directly (no deliveries/delivery-001/STATE.md is created)
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --lifecycle "Executing" 2>/dev/null || code=$?
assert_exit_zero "$code" "20e: flat --lifecycle write → exit 0"
assert_file_contains "$FLAT_STATE" "delivery_state: Executing" "20e: work-root frontmatter delivery_state set to Executing"
if [[ ! -d "${FLAT_WORK}/deliveries" ]]; then
    pass "20e: no deliveries/ directory created for the flat layout"
else
    fail "20e: a deliveries/ directory was created — flat layout must not use one"
fi

# 20f: --delivery-id 001 --block writes the work-root ## Delivery Gate block
FLAT_GATE_BLOCK="- **Reviewer Tier:** Small
- **Grade:** A
- **Issue List:** none
- **Timestamp:** 2026-07-08T01:00:00Z"
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --block "$FLAT_GATE_BLOCK" 2>/dev/null || code=$?
assert_exit_zero "$code" "20f: flat --block write → exit 0"
assert_file_contains "$FLAT_STATE" "**Grade:** A" "20f: work-root ## Delivery Gate grade written"
# The plural DERIVED ## Tasks State view (distinct section) must be untouched
assert_file_contains "$FLAT_STATE" "| _none yet_ | | | | | | | |" "20f: plural DERIVED ## Tasks State view still shows the placeholder (untouched)"
# Regression guard: the `---` separator and the `DERIVED / READ-ONLY VIEWS`
# banner comment that sit between ## Delivery Gate and ## Tasks State in the
# real work-state-template.md must survive the --block rewrite untouched (the
# old awk swallowed everything up to the next `## ` heading, deleting both).
assert_file_contains "$FLAT_STATE" "DERIVED / READ-ONLY VIEWS" "20f: DERIVED/READ-ONLY VIEWS banner comment survives the --block rewrite"
GATE_TO_TASKS=$(awk '/^## Delivery Gate$/{f=1} f{print} /^## Tasks State$/{exit}' "$FLAT_STATE")
if echo "$GATE_TO_TASKS" | grep -qE '^---$'; then
    pass "20f: --- separator between ## Delivery Gate and ## Tasks State survives the --block rewrite"
else
    fail "20f: --- separator between ## Delivery Gate and ## Tasks State was deleted by the --block rewrite"
fi
if echo "$GATE_TO_TASKS" | grep -q "DERIVED / READ-ONLY VIEWS"; then
    pass "20f: DERIVED/READ-ONLY VIEWS banner is positioned between ## Delivery Gate and ## Tasks State (not pulled up/deleted)"
else
    fail "20f: DERIVED/READ-ONLY VIEWS banner is NOT between ## Delivery Gate and ## Tasks State — section boundary corrupted"
fi

# 20g: idempotency — rewriting the same field value leaves the file byte-identical
BEFORE=$(wc -c < "$FLAT_STATE")
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null
AFTER=$(wc -c < "$FLAT_STATE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "20g: flat --field write is idempotent — no size change on same value"
else
    fail "20g: flat --field write not idempotent — size changed from $BEFORE to $AFTER"
fi

# 20h: malformed flat work (### Tasks lifecycle section absent) → exit 6
FLAT_MALFORMED="${TMPDIR_BASE}/work-flat-malformed"
mkdir -p "$FLAT_MALFORMED"
cat > "${FLAT_MALFORMED}/STATE.md" <<'MALFORMEDEOF'
# Work State — work-flat-malformed

## Pipeline State

- **Lifecycle:** Running
MALFORMEDEOF
# BLUEPRINT.md must be present so is_flat_layout()'s 3-part rule (BLUEPRINT.md
# present AND DETAIL.md present AND no deliveries/) still routes this fixture
# through the flat branch -- otherwise it would fall through to the
# hierarchical --field path (a different, unresolvable delivery-STATE.md path)
# and this unit would no longer exercise the "malformed flat work" scenario.
make_flat_blueprint "$FLAT_MALFORMED"
make_flat_task_spec "$FLAT_MALFORMED" 1
code=0
AID_STATE_FILE="${FLAT_MALFORMED}/STATE.md" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null || code=$?
assert_exit_eq "$code" 6 "20h: flat work missing ### Tasks lifecycle → exit 6 (malformed)"

# 20i: nested-path regression — the ORIGINAL hierarchical fixture (has
# deliveries/) from the top of this file must still route through the
# per-unit STATE.md files, completely unaffected by the flat-layout branch.
code=0
run_field 1 1 State "Done" || code=$?
assert_exit_zero "$code" "20i: nested-path --field write still succeeds after flat-layout changes"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.md" "Done" "20i: nested-path task-001 STATE.md still the write target"
assert_file_not_contains "$FLAT_STATE" "task-001 | Done" "20i: nested-path write did not leak into the flat fixture"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 21: octal footgun regression — zero-padded ids containing 8/9 ==="

# A zero-padded id containing an 8 or 9 (e.g. "008", "090") is NOT a valid
# octal literal. Before the fix, every `printf '%03d' "$id"` site in this
# script fed the raw id straight to printf, which bash parses as an octal
# number when it looks like one — "008"/"090" triggered a bash "invalid
# octal number" error and printf substituted "000" on stdout (captured by
# the surrounding `$(...)`), silently resolving to the WRONG path
# (delivery-000/task-000) instead of erroring loudly. The fix wraps every
# such id in `$((10#$id))` first to force base-10 arithmetic before padding.

WORK_21="${TMPDIR_BASE}/work-octal21"
DELIVERY_008="${WORK_21}/deliveries/delivery-008"
DELIVERY_090="${WORK_21}/deliveries/delivery-090"

make_work_state "$WORK_21"
make_delivery_state "$WORK_21" 8
make_task_state "$DELIVERY_008" 8
make_task_spec  "$DELIVERY_008" 8 8 "work-octal21-test"
make_delivery_state "$WORK_21" 90
make_task_state "$DELIVERY_090" 9

# 21a: --field with zero-padded --delivery-id/--task-id "008" resolves to
# delivery-008/tasks/task-008 (NOT delivery-000/tasks/task-000).
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id "008" --task-id "008" --field State --value "Done" 2>/dev/null || code=$?
assert_exit_zero "$code" "21a: --delivery-id 008 --task-id 008 --field → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.md" "state: Done" "21a: write landed in delivery-008/tasks/task-008/STATE.md"
if [[ ! -e "${WORK_21}/deliveries/delivery-000" ]]; then
    pass "21a: no delivery-000 directory was ever consulted (octal misparse would have targeted it)"
else
    fail "21a: delivery-000 exists — octal misparse regression"
fi

# 21b: --field with zero-padded --delivery-id "090" / --task-id "009" resolves
# to delivery-090/tasks/task-009 (090 is invalid octal; 009 is invalid octal).
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id "090" --task-id "009" --field Notes --value "octal-ok" 2>/dev/null || code=$?
assert_exit_zero "$code" "21b: --delivery-id 090 --task-id 009 --field → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_090}/tasks/task-009/STATE.md" "octal-ok" "21b: write landed in delivery-090/tasks/task-009/STATE.md"

# 21c: --delivery-id "090" --lifecycle targets delivery-090/STATE.md directly
# (mode_delivery_lifecycle's own padded_id site).
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id "090" --lifecycle "Gated" 2>/dev/null || code=$?
assert_exit_zero "$code" "21c: --delivery-id 090 --lifecycle → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_090}/STATE.md" "delivery_state: Gated" "21c: lifecycle written to delivery-090/STATE.md"

# 21d: --delivery-id "008" --block targets delivery-008/STATE.md directly
# (mode_delivery_block's own padded_id site).
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id "008" --block "**Grade:** A" 2>/dev/null || code=$?
assert_exit_zero "$code" "21d: --delivery-id 008 --block → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/STATE.md" "**Grade:** A" "21d: gate block written to delivery-008/STATE.md"

# 21e: --delivery-id "009" --append-issue targets delivery-009-issues.md
# (mode_append_issue's own padded_id site). AID_DELIVERY_ISSUES_DIR is
# overridden per-call here -- it was exported globally to the ORIGINAL
# $WORK_DIR near the top of this file (Unit 5), so without the override
# this write would land in the wrong (original) work dir, not $WORK_21.
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" AID_DELIVERY_ISSUES_DIR="${WORK_21}" \
    bash "$SCRIPT" --delivery-id "009" --append-issue "| task-009 | [LOW] | octal footgun regression row | Open |" 2>/dev/null || code=$?
assert_exit_zero "$code" "21e: --delivery-id 009 --append-issue → exit 0 (no octal parse error)"
assert_file_contains "${WORK_21}/delivery-009-issues.md" "octal footgun regression row" "21e: issue row appended to delivery-009-issues.md"

# 21f: omitting --delivery-id and resolving from the task's Source line
# (resolve_delivery_from_task_spec's own padded_t site) for zero-padded
# task-id "008".
code=0
AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --task-id "008" --field Review --value "B" 2>/dev/null || code=$?
assert_exit_zero "$code" "21f: Source-line resolution with task-id 008 → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.md" "review: B" "21f: Source-line-resolved write landed in delivery-008/tasks/task-008/STATE.md"

# 21g: feature-001 flattened layout — write_task_field_flat's own padded_t
# site for zero-padded task-id "008".
FLAT_WORK_21="${TMPDIR_BASE}/work-flat-octal21"
make_flat_work_state "$FLAT_WORK_21"
make_flat_blueprint "$FLAT_WORK_21"
make_flat_task_spec "$FLAT_WORK_21" 8
code=0
AID_STATE_FILE="${FLAT_WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id 1 --task-id "008" --field State --value "In Progress" 2>/dev/null || code=$?
assert_exit_zero "$code" "21g: flat layout --task-id 008 --field → exit 0 (no octal parse error)"
assert_file_contains "${FLAT_WORK_21}/STATE.md" "| task-008 | In Progress |" "21g: flat layout row written for task-008 (not task-000)"

# 21h: --findings with zero-padded --delivery-id/--task-id "008" targets
# delivery-008/tasks/task-008/STATE.md (mode_findings' own padded_id site,
# used only in its user-facing confirmation message).
FINDINGS_OCTAL="**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [LOW] | octal footgun regression finding | Deferred-to-gate |"
code=0
err_out21h=$(AID_STATE_FILE="${WORK_21}/STATE.md" bash "$SCRIPT" --delivery-id "008" --task-id "008" --findings "$FINDINGS_OCTAL" 2>&1) || code=$?
assert_exit_zero "$code" "21h: --delivery-id 008 --task-id 008 --findings → exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.md" "octal footgun regression finding" "21h: findings block written to delivery-008/tasks/task-008/STATE.md"
if echo "$err_out21h" | grep -q "task-008"; then
    pass "21h: confirmation message reports 'task-008' (padded_id resolved correctly, not 'task-000')"
else
    fail "21h: confirmation message did not report 'task-008' as expected — got: $err_out21h"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 22: task-004 frontmatter-writer path — new fields + gate-field + body invariance ==="

# 22a: --pipeline --field extended to Started / Minimum Grade / User Approved /
# Pipeline Path / Pipeline Initiator (all newly handled by mode_pipeline).
PIPE_STATE22="${TMPDIR_BASE}/pipe22/STATE.md"
make_pipeline_state "$PIPE_STATE22"
code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field Started --value "2026-07-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Started write → exit 0"
assert_file_contains "$PIPE_STATE22" "started: 2026-07-10" "22a: started frontmatter key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Minimum Grade" --value "A+" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Minimum Grade write → exit 0"
assert_file_contains "$PIPE_STATE22" "minimum_grade: A+" "22a: minimum_grade frontmatter key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Minimum Grade" --value "Z" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Minimum Grade='Z' (invalid grade) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "User Approved" --value "yes" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: User Approved=yes write → exit 0"
assert_file_contains "$PIPE_STATE22" "user_approved: yes" "22a: user_approved frontmatter key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "User Approved" --value "maybe" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: User Approved='maybe' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value "lite" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Pipeline Path=lite write → exit 0"
assert_file_contains "$PIPE_STATE22" "  path: lite" "22a: pipeline.path nested frontmatter key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value "medium" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Pipeline Path='medium' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value "aid-refactor" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Pipeline Initiator=aid-refactor write → exit 0"
assert_file_contains "$PIPE_STATE22" "  initiator: aid-refactor" "22a: pipeline.initiator nested frontmatter key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value "refactor" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Pipeline Initiator='refactor' (no aid- prefix) rejected (exit 4)"

# Both nested pipeline.* keys coexist under ONE `pipeline:` parent mapping (no duplicate header)
PIPELINE_PARENT_COUNT=$(grep -cE '^pipeline:$' "$PIPE_STATE22")
assert_eq "$PIPELINE_PARENT_COUNT" "1" "22a: exactly one 'pipeline:' parent mapping header (path+initiator share it)"

# 22b: --gate-field enum validation
GATE22_WORK="${TMPDIR_BASE}/gate22-work"
make_delivery_state "$GATE22_WORK" 1
code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Medium" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Tier=Medium accepted (exit 0)"
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.md" "gate_tier: Medium" "22b: gate_tier frontmatter key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Huge" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: gate-field Tier='Huge' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Grade --gate-value "A-" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Grade=A- accepted (exit 0)"
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.md" "gate_grade: A-" "22b: gate_grade frontmatter key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Grade --gate-value "Z" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: gate-field Grade='Z' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Timestamp --gate-value "2026-07-10T12:00:00Z" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Timestamp accepted (exit 0)"
# Quoted -- the value contains ':' (wb_set_frontmatter's quoting rule)
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.md" "gate_timestamp: '2026-07-10T12:00:00Z'" "22b: gate_timestamp frontmatter key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Unknown --gate-value "x" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: unknown gate-field name rejected (exit 4)"

# 22c: gate-field isolation — the ## Delivery Gate body block (Complexity
# Score/Cycles/Issue List) is untouched by --gate-field writes. (assert.sh's
# grep -qF now uses `--`, so the natural leading-"-" bullet pattern is safe
# again -- task-004 FIX review finding 3.)
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.md" "- **Issue List:** none" "22c: ## Delivery Gate body Issue List bullet untouched by --gate-field"

# 22d: gate-field flattened layout — targets work-root frontmatter (--delivery-id 001)
GATE22_FLAT="${TMPDIR_BASE}/gate22-flat"
make_flat_work_state "$GATE22_FLAT"
make_flat_blueprint "$GATE22_FLAT"
make_flat_task_spec "$GATE22_FLAT" 1
code=0
AID_STATE_FILE="${GATE22_FLAT}/STATE.md" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Small" 2>/dev/null || code=$?
assert_exit_zero "$code" "22d: flat-layout gate-field write → exit 0"
assert_file_contains "${GATE22_FLAT}/STATE.md" "gate_tier: Small" "22d: work-root frontmatter gate_tier set (flat layout)"
if [[ ! -d "${GATE22_FLAT}/deliveries" ]]; then
    pass "22d: no deliveries/ directory created for the flat layout gate-field write"
else
    fail "22d: a deliveries/ directory was created by --gate-field — flat layout must not use one"
fi

# capture_body FILE OUT_FILE
# Byte-exact copy of everything strictly after the closing frontmatter fence
# (or the whole file, if it has none) into OUT_FILE. Deliberately file-based,
# not `$(...)` command substitution -- command substitution silently strips
# ALL trailing newlines from whatever it captures, which would hide exactly
# the class of regression (a missing final newline gaining one, or a CRLF
# body losing its `\r`s) this check exists to catch (task-004 FIX review
# findings 2/4/5). `cmp`, not string equality, is what actually proves
# byte-invariance.
capture_body() {
    local f="$1" out="$2"
    if head -1 "$f" | grep -qE '^---[ \t]*\r?$'; then
        local close_line
        close_line=$(awk '/^---[ \t]*\r?$/{n++; if(n==2){print NR; exit}}' "$f")
        tail -n "+$((close_line + 1))" "$f" > "$out"
    else
        cp "$f" "$out"
    fi
}

# 22e: body byte-invariance (critical AC) — capture the markdown BODY (every
# line strictly after the closing frontmatter fence) before and after a
# sequence of frontmatter writes; it must be byte-identical, INCLUDING a
# missing final newline (the fixture body deliberately has none).
BINV_WORK="${TMPDIR_BASE}/bodyinvariance-work"
mkdir -p "$BINV_WORK"
if [[ -f "${SCRIPT_DIR}/../../canonical/aid/templates/work-state-template.md" ]]; then
    cat "${SCRIPT_DIR}/../../canonical/aid/templates/work-state-template.md" > "${BINV_WORK}/STATE.md"
else
    make_pipeline_state "${BINV_WORK}/STATE.md"
fi
# Drop any trailing newline the source template/fixture happens to end with,
# so this run also exercises the "body lacks a final newline" case (findings
# 4/5) rather than only the far more common "body ends with \n" case.
printf '%s' "$(cat "${BINV_WORK}/STATE.md")" > "${BINV_WORK}/STATE.md.tmp" && mv "${BINV_WORK}/STATE.md.tmp" "${BINV_WORK}/STATE.md"

BODY_BEFORE_22E="${BINV_WORK}/before-body.txt"
capture_body "${BINV_WORK}/STATE.md" "$BODY_BEFORE_22E"
AID_STATE_FILE="${BINV_WORK}/STATE.md" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.md" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.md" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-execute 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.md" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value lite 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.md" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value aid-refactor 2>/dev/null
BODY_AFTER_22E="${BINV_WORK}/after-body.txt"
capture_body "${BINV_WORK}/STATE.md" "$BODY_AFTER_22E"
if cmp -s "$BODY_BEFORE_22E" "$BODY_AFTER_22E"; then
    pass "22e: markdown BODY byte-identical (cmp) after a sequence of frontmatter writes, incl. missing final newline (critical AC)"
else
    fail "22e: markdown BODY changed after frontmatter writes — body byte-invariance violated — cmp: $(cmp "$BODY_BEFORE_22E" "$BODY_AFTER_22E" 2>&1)"
fi

# 22f: CRLF fixture — a `\r\n` STATE.md must survive a frontmatter write with
# its body byte-identical (task-004 FIX review finding 2), proven via `cmp`
# rather than `$(...)` (finding 5), which would silently normalize the very
# `\r` bytes this check exists to guard.
CRLF_WORK="${TMPDIR_BASE}/crlf-work"
mkdir -p "$CRLF_WORK"
CRLF_STATE="${CRLF_WORK}/STATE.md"
printf -- '---\r\nlifecycle: Running\r\nphase: Describe\r\n---\r\n\r\n# Work State\r\n\r\nSome body content with CRLF.\r\nSecond line, no trailing newline.' > "$CRLF_STATE"
CRLF_BODY_BEFORE="${CRLF_WORK}/before-body.txt"
capture_body "$CRLF_STATE" "$CRLF_BODY_BEFORE"
code=0
AID_STATE_FILE="$CRLF_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "22f: CRLF STATE.md frontmatter write → exit 0"
if head -1 "$CRLF_STATE" | od -An -c | grep -qF -- '\r'; then
    pass "22f: opening fence still carries \\r (CRLF preserved, no duplicate frontmatter block prepended)"
else
    fail "22f: opening fence lost its \\r -- CRLF handling regressed"
fi
FENCE_COUNT_22F=$(grep -c -- '^---\r\{0,1\}$' "$CRLF_STATE")
if [[ "$FENCE_COUNT_22F" -eq 2 ]]; then
    pass "22f: exactly 2 frontmatter fence lines (no duplicate block prepended)"
else
    fail "22f: expected exactly 2 fence lines, found $FENCE_COUNT_22F (duplicate/corrupted frontmatter block)"
fi
assert_file_contains "$CRLF_STATE" "phase: Execute" "22f: phase frontmatter key updated"
CRLF_BODY_AFTER="${CRLF_WORK}/after-body.txt"
capture_body "$CRLF_STATE" "$CRLF_BODY_AFTER"
if cmp -s "$CRLF_BODY_BEFORE" "$CRLF_BODY_AFTER"; then
    pass "22f: CRLF body byte-identical (cmp) after frontmatter write, incl. \\r\\n line endings and missing final newline"
else
    fail "22f: CRLF body changed after frontmatter write — cmp: $(cmp "$CRLF_BODY_BEFORE" "$CRLF_BODY_AFTER" 2>&1)"
fi

# 22g: quoted-value write is valid YAML and PyYAML-round-trips (task-004 FIX
# review finding 1) -- a value containing `"`, `\`, `:`, `#`, and a leading
# `-` must produce a single-quoted YAML scalar that survives
# yaml.safe_load()/yaml.safe_dump() with the exact original text intact
# (awk's `-v` C-escape reprocessing previously undid any backslash-escaping
# done in bash, corrupting the emitted YAML for exactly this class of value).
NASTY_VALUE="- a dash-led value with \"double quotes\", it's a backslash \\ and a colon: plus a #hash"
NASTY_STATE="${TMPDIR_BASE}/pipe22nasty/STATE.md"
make_pipeline_state "$NASTY_STATE"
code=0
AID_STATE_FILE="$NASTY_STATE" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "$NASTY_VALUE" 2>/dev/null || code=$?
assert_exit_zero "$code" "22g: quoted (nasty) value write → exit 0"

PYBIN=""
if command -v python3 >/dev/null 2>&1; then
    PYBIN=python3
elif command -v python >/dev/null 2>&1; then
    PYBIN=python
fi

if [[ -n "$PYBIN" ]]; then
    YAML_CHECK_OUT=$("$PYBIN" - "$NASTY_STATE" "$NASTY_VALUE" <<'PYEOF'
import sys
try:
    import yaml
except ImportError:
    print("SKIP: PyYAML not installed")
    sys.exit(0)

path, expected = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
fm_text = text.split("---")[1]
try:
    data = yaml.safe_load(fm_text)
except yaml.YAMLError as exc:
    print(f"FAIL: yaml.safe_load raised: {exc}")
    sys.exit(1)
if data is None:
    print("FAIL: yaml.safe_load returned None")
    sys.exit(1)
actual = data.get("pause_reason")
if actual != expected:
    print(f"FAIL: round-trip mismatch: expected {expected!r} got {actual!r}")
    sys.exit(1)
redumped = yaml.safe_dump(data)
reloaded = yaml.safe_load(redumped)
if reloaded.get("pause_reason") != expected:
    print("FAIL: safe_dump/safe_load round-trip mismatch")
    sys.exit(1)
print("OK")
PYEOF
    )
    case "$YAML_CHECK_OUT" in
        OK)
            pass "22g: quoted-value frontmatter is valid YAML and round-trips through PyYAML safe_load/safe_dump"
            ;;
        SKIP:*)
            log "22g: skipped ($YAML_CHECK_OUT)"
            ;;
        *)
            fail "22g: quoted-value YAML round-trip failed: $YAML_CHECK_OUT"
            ;;
    esac
else
    log "22g: skipped (no python interpreter on PATH)"
fi

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
