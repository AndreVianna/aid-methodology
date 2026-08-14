#!/usr/bin/env bash
# test-writeback-state.sh — smoke-test harness for writeback-state.sh
#
# Covers the collapsed single-key YAML write path (work-009-refactor task-007):
# the target file is ONE whole-document YAML key space, no `---` frontmatter
# fence and no markdown body/sections. All writes go to per-unit STATE.yml
# files, NOT to the monolithic work STATE.yml (that isolation property is
# unchanged from the pre-refactor per-unit contract, work-004 Pillar 2).
#
# Unit layout under test:
#   work-NNN-{name}/
#     STATE.yml                          -- work-level (--pipeline target only)
#     deliveries/
#       delivery-NNN/
#         STATE.yml                        -- delivery-level (--block / --lifecycle / --gate-field target)
#         tasks/
#           task-NNN/
#             DETAIL.md                   -- contains **Source:** line for delivery resolution
#             STATE.yml                   -- task-level (--field / --findings target)
#
# Test scenarios:
#   Unit 1:  --task-id --delivery-id --field --value  (per-task STATE.yml key update)
#   Unit 2:  --task-id --delivery-id --findings       (quick_check.reviewer_tier + .findings)
#   Unit 3:  --delivery-id --block                    (delivery_gate.issue_list)
#   Unit 4:  --delivery-id --lifecycle                (delivery_state scalar)
#   Unit 5:  --delivery-id --append-issue             (delivery-NNN-issues.md append; unaffected by the YAML migration)
#   Unit 6:  Source-line delivery resolution          (--delivery-id omitted, DETAIL.md used)
#   Unit 7:  Idempotency
#   Unit 8:  Concurrent lock contention (5 parallel per-task writes)
#   Unit 9:  --pipeline field writes (key creation on a document with none of the base keys yet)
#   Unit 10: --pipeline enum acceptance + rejection
#   Unit 11: --pipeline conditional Pause/Block fields
#   Unit 12: Isolation — task/findings/block/lifecycle writes do NOT touch work STATE.yml
#   Unit 13: Error paths (missing args, invalid ids, lock timeout, missing files, malformed YAML)
#   Unit 14: H2 — INVERTED under FR-4b: a `|` (and a newline) in --value now round-trips intact
#   Unit 15: M2 — missing lock directory
#   Unit 16: State field enum validation (field=State)
#   Unit 17: --pipeline ∥ --pipeline and --pipeline ∥ --field concurrency
#   Unit 18: FR16 derivation primitives — on-disk key determinism
#   Unit 19: M5 — pause/block signal sequences
#   Unit 20: feature-001 flattened single-delivery layout (auto-detected) — tasks_lifecycle mapping
#   Unit 21: octal footgun regression — zero-padded ids containing 8/9 (008, 090)
#            must resolve via base-10 (not be misparsed as invalid octal)
#   Unit 22: gate-field + Started/Minimum Grade/User Approved/Pipeline Path/Pipeline Initiator +
#            single-line-diff / pre-existing-line invariance + CRLF + quoted-value (colon/quote/
#            hash/backslash) round-trip
#   Unit 23: Name -> display_name task field
#   Unit 24: AID_WORK_DIR-only caller reaches mode_append_issue's work-dir branch
#   Unit 25: --findings on the feature-001 flattened layout (quick_check stored as one verbatim scalar)
#
# Exit codes (SPEC.md SS L-2):
#   0 success | 1 STATE.yml/artifact missing | 2 lock contention | 3 writeback unverifiable |
#   4 invalid argument value | 5 missing required argument | 6 malformed STATE.yml (not a mapping)

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
# Creates deliveries/delivery-NNN/tasks/task-NNN/STATE.yml matching the shape
# task-state-template.yml declares: every field is a top-level scalar in ONE
# whole-document YAML key space (no frontmatter fence, no markdown body).
# STATE_VALUE defaults to "Pending".
make_task_state() {
    local delivery_dir="$1" task_id="$2" state_val="${3:-Pending}"
    local padded_t
    padded_t=$(printf '%03d' "$task_id")
    local task_dir="${delivery_dir}/tasks/task-${padded_t}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/STATE.yml" <<TASKSTATEOF
# Task State -- task-${padded_t}
state: ${state_val}
review: --
elapsed: --
notes: --
display_name: --
quick_check:
  reviewer_tier: --
  findings: []
dispatch_log: []
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
# Creates deliveries/delivery-NNN/STATE.yml matching delivery-state-template.yml's shape.
# LIFECYCLE_VALUE defaults to "Executing".
make_delivery_state() {
    local work_dir="$1" delivery_id="$2" lc_val="${3:-Executing}"
    local padded_d
    padded_d=$(printf '%03d' "$delivery_id")
    local delivery_dir="${work_dir}/deliveries/delivery-${padded_d}"
    mkdir -p "$delivery_dir"
    cat > "${delivery_dir}/STATE.yml" <<DELIVSTATEOF
# Delivery State -- delivery-${padded_d}
delivery_state: ${lc_val}
gate_tier: --
gate_grade: Pending
gate_timestamp: --
delivery_lifecycle:
  updated: '2026-06-18T00:00:00Z'
  block_reason: --
  block_artifact: --
delivery_gate:
  issue_list: []
qa: []
DELIVSTATEOF
}

# make_work_state WORK_DIR
# Creates a minimal work-level STATE.yml (--pipeline target only; no task rows).
make_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.yml" <<'WORKSTATEOF'
# Work State -- work-test
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-18T00:00:00Z'

# Triage
# (none)
WORKSTATEOF
}

# ---------------------------------------------------------------------------
# Global workspace: work root + delivery-001 (tasks 1..5) + delivery-002 (task 6)
# ---------------------------------------------------------------------------
WORK_DIR="${TMPDIR_BASE}/work"
DELIVERY_001="${WORK_DIR}/deliveries/delivery-001"
DELIVERY_002="${WORK_DIR}/deliveries/delivery-002"

make_work_state "$WORK_DIR"
export AID_STATE_FILE="${WORK_DIR}/STATE.yml"
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

# flat_task_block FILE TASK_KEY -- extracts one flattened-layout
# tasks_lifecycle.TASK_KEY mapping entry: the exact "  TASK_KEY:" header line
# plus every following 4+-space-indented child line, stopping at the first
# line that is NOT 4+-space-indented (a sibling task-NNN: entry at 2-space
# indent, or the next top-level key at 0-space indent, or a blank spacer
# line -- any of which ends the current task's own subtree).
flat_task_block() {
    local file="$1" task_key="$2"
    awk -v key="  ${task_key}:" '
        $0 == key { f=1; print; next }
        f && /^    / { print; next }
        f { exit }
    ' "$file"
}

run_field() {
    local tid="$1" did="$2" field="$3" val="$4"
    bash "$SCRIPT" --delivery-id "$did" --task-id "$tid" --field "$field" --value "$val"
}

# The task STATE.yml is the target; verify the write lands there, NOT in work STATE.yml.
run_field 1 1 State "In Progress"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "state: 'In Progress'" "task-001 State updated in task STATE.yml"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.yml" "state: Pending" "task-002 still Pending (not disturbed)"

run_field 2 1 State "Done"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.yml" "state: Done" "task-002 State updated to Done"

run_field 3 1 Review "A"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "review: A" "task-003 Review field updated"

run_field 4 1 Notes "first note"
assert_file_contains "${DELIVERY_001}/tasks/task-004/STATE.yml" "notes: 'first note'" "task-004 Notes updated"

run_field 5 1 Elapsed "12m"
assert_file_contains "${DELIVERY_001}/tasks/task-005/STATE.yml" "elapsed: '12m'" "task-005 Elapsed updated"

# Isolation: work STATE.yml must NOT be touched by task field writes
assert_file_not_contains "${WORK_DIR}/STATE.yml" "In Progress" "work STATE.yml NOT modified by task field write (isolation)"
assert_file_not_contains "${WORK_DIR}/STATE.yml" "first note"  "work STATE.yml NOT modified by Notes write (isolation)"

# SP-4/SP-5 single-line-diff property: overwriting an EXISTING scalar changes
# exactly the one line that carries that key -- every other line (including
# the leading full-line comment and every sibling key) is byte-reproduced.
SLD_BEFORE="${TMPDIR_BASE}/sld-before.txt"
SLD_AFTER="${TMPDIR_BASE}/sld-after.txt"
cp "${DELIVERY_001}/tasks/task-004/STATE.yml" "$SLD_BEFORE"
bash "$SCRIPT" --delivery-id 1 --task-id 4 --field Notes --value "second note"
cp "${DELIVERY_001}/tasks/task-004/STATE.yml" "$SLD_AFTER"
SLD_DIFF_LINES=$(diff "$SLD_BEFORE" "$SLD_AFTER" | grep -cE '^[<>]')
if [[ "$SLD_DIFF_LINES" -eq 2 ]]; then
    pass "single-line-diff: overwriting an existing scalar changes exactly one line (1 removed + 1 added)"
else
    fail "single-line-diff: expected a 2-line diff (1 old + 1 new), got $SLD_DIFF_LINES diff lines"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: --task-id --delivery-id --findings ==="

FINDINGS_BLOCK="- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] missing error path -- Deferred-to-gate"

bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_BLOCK"
# Findings land in the task's own STATE.yml quick_check mapping
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "quick_check:" "task-001 STATE.yml has a quick_check mapping"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "reviewer_tier: Small" "reviewer_tier written to task-001 STATE.yml"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "[HIGH] missing error path" "findings item written to task-001 STATE.yml"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "Deferred-to-gate" "deferred status in task-001 findings"
# Work STATE.yml must NOT receive findings
assert_file_not_contains "${WORK_DIR}/STATE.yml" "[HIGH]" "work STATE.yml NOT modified by --findings (isolation)"

# Regression guard: sibling keys (dispatch_log, and every other top-level key
# in the file) must survive the --findings rewrite untouched -- KI-010's
# wb_get_kv seq-verify bug (fixed by this task) manifested exactly here: a
# non-empty findings sequence followed by a sibling top-level key died at
# exit 3 even though the computed rewrite was correct.
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "dispatch_log: []" "task-001 STATE.yml dispatch_log key survives the --findings rewrite"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "notes: --" "task-001 STATE.yml unrelated sibling key (notes) survives the --findings rewrite"

FINDINGS_BLOCK2="- **Reviewer Tier:** Small
- **Findings:**
  - [CRITICAL] null deref on empty input -- Fixed-on-spot"

bash "$SCRIPT" --delivery-id 1 --task-id 2 --findings "$FINDINGS_BLOCK2"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.yml" "quick_check:" "task-002 STATE.yml has a quick_check mapping"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.yml" "[CRITICAL] null deref" "critical finding in task-002 STATE.yml"
assert_file_contains "${DELIVERY_001}/tasks/task-002/STATE.yml" "Fixed-on-spot" "fixed-on-spot in task-002 STATE.yml"
# Each task owns its own file -- task-001 findings unaffected
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "Deferred-to-gate" "task-001 findings still present after task-002 write"

# Multi-item findings sequence + overwrite-shrink (fewer items than before)
# round-trips correctly -- the sequence-replace path must swallow every stale
# continuation line, not just the first.
FINDINGS_MULTI="- **Reviewer Tier:** Medium
- **Findings:**
  - [HIGH] first finding
  - [LOW] second finding
  - [MEDIUM] third finding"
bash "$SCRIPT" --delivery-id 1 --task-id 3 --findings "$FINDINGS_MULTI"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "[HIGH] first finding" "multi-item findings: item 1 written"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "[LOW] second finding" "multi-item findings: item 2 written"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "[MEDIUM] third finding" "multi-item findings: item 3 written"

FINDINGS_SHRINK="- **Reviewer Tier:** Small
- **Findings:**
  - [LOW] only one now"
bash "$SCRIPT" --delivery-id 1 --task-id 3 --findings "$FINDINGS_SHRINK"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "[LOW] only one now" "shrink-on-overwrite: the new single item is present"
assert_file_not_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "first finding" "shrink-on-overwrite: stale item 1 fully swallowed"
assert_file_not_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "third finding" "shrink-on-overwrite: stale item 3 fully swallowed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: --delivery-id --block ==="

GATE_BLOCK="- **Complexity Score:** 3
- **Cycles:** 1
- **Issue List:**
  - [LOW] minor style issue"

bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK"
# Gate block lands in delivery-001/STATE.yml's delivery_gate.issue_list
assert_file_contains "${DELIVERY_001}/STATE.yml" "delivery_gate:" "delivery-001/STATE.yml has a delivery_gate mapping"
assert_file_contains "${DELIVERY_001}/STATE.yml" "[LOW] minor style issue" "issue item written to delivery-001 gate block"
# Complexity Score / Cycles have no persisted target (SPEC.md SS D-4) -- not asserted.
# Work STATE.yml must NOT receive the gate block
assert_file_not_contains "${WORK_DIR}/STATE.yml" "minor style issue" "work STATE.yml NOT modified by --block (isolation)"
# Task files must NOT be modified
assert_file_not_contains "${DELIVERY_001}/tasks/task-005/STATE.yml" "delivery_gate" "task-005 STATE.yml NOT modified by --block"

# Replace (not append): re-run with a different issue list
GATE_BLOCK2="- **Complexity Score:** 5
- **Cycles:** 2
- **Issue List:**
  - [HIGH] a more severe issue"

bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
assert_file_contains "${DELIVERY_001}/STATE.yml" "[HIGH] a more severe issue" "gate block replaced -- new issue present in delivery-001"
assert_file_not_contains "${DELIVERY_001}/STATE.yml" "minor style issue" "old issue removed from delivery-001 (replace, not append)"

# delivery-002 gets its own gate block (disjoint files)
GATE_BLOCK3="- **Issue List:**
  - [HIGH] major issue found"

bash "$SCRIPT" --delivery-id 2 --block "$GATE_BLOCK3"
assert_file_contains "${DELIVERY_002}/STATE.yml" "[HIGH] major issue found" "delivery-002/STATE.yml gets its own gate block"
assert_file_contains "${DELIVERY_001}/STATE.yml" "[HIGH] a more severe issue" "delivery-001 gate block unaffected after delivery-002 write"

# Empty issue list (clean gate) round-trips to []
GATE_BLOCK_CLEAN="- **Issue List:** none"
bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK_CLEAN"
assert_file_contains "${DELIVERY_001}/STATE.yml" "issue_list: []" "clean gate (no issues) round-trips to an empty sequence"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: --delivery-id --lifecycle ==="

# SD-8 enum: Pending-Spec | Specified | Executing | Gated | Done | Blocked
bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated"
assert_file_contains "${DELIVERY_001}/STATE.yml" "delivery_state: Gated" "delivery-001 delivery_state set to Gated"
# Work STATE.yml must NOT be touched
assert_file_not_contains "${WORK_DIR}/STATE.yml" "Gated" "work STATE.yml NOT modified by --lifecycle (isolation)"

# Advance through each enum member
for lc_val in "Pending-Spec" "Specified" "Executing" "Gated" "Done" "Blocked"; do
    code=0
    bash "$SCRIPT" --delivery-id 2 --lifecycle "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "--lifecycle $lc_val accepted (exit 0)"
done
assert_file_contains "${DELIVERY_002}/STATE.yml" "delivery_state: Blocked" "delivery-002 delivery_state advanced to Blocked"

# Invalid lifecycle value -> exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --lifecycle "Running" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "--lifecycle Running (invalid; that is pipeline enum) -> exit 4"

code=0
bash "$SCRIPT" --delivery-id 1 --lifecycle "active" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "--lifecycle active (invalid lowercase) -> exit 4"

# Malformed delivery STATE.yml (not a YAML mapping) -> exit 6
MALFORMED_DELIV="${TMPDIR_BASE}/malformed-delivery-lc"
mkdir -p "$MALFORMED_DELIV"
printf 'This is not a YAML mapping at all.\n' > "${MALFORMED_DELIV}/STATE.yml"
code=0
AID_DELIVERY_STATE_FILE="${MALFORMED_DELIV}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated" 2>/dev/null || code=$?
assert_exit_eq "$code" 6 "--lifecycle against a non-mapping STATE.yml -> exit 6 (malformed)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: --delivery-id --append-issue (unaffected by the YAML migration) ==="

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
# Resolve the delivery from that line and write to the correct task STATE.yml.
# We must supply AID_STATE_FILE so the script knows the work root.
code=0
bash "$SCRIPT" --task-id 3 --field State --value "In Review" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-3 -> delivery-001, exit 0"
assert_file_contains "${DELIVERY_001}/tasks/task-003/STATE.yml" "state: 'In Review'" "task-003 State written via source-line resolution"

# task-6 is in delivery-002 per its DETAIL.md
code=0
bash "$SCRIPT" --task-id 6 --field Notes --value "auto-resolved" 2>/dev/null || code=$?
assert_exit_zero "$code" "Source-line resolution: task-6 -> delivery-002, exit 0"
assert_file_contains "${DELIVERY_002}/tasks/task-006/STATE.yml" "notes: auto-resolved" "task-006 Notes written via source-line resolution"

# Omit delivery-id AND have no DETAIL.md -> must fail with exit 5
ORPHAN_WORK="${TMPDIR_BASE}/orphan-work"
mkdir -p "$ORPHAN_WORK"
make_task_state "$ORPHAN_WORK/deliveries/delivery-001" 99  # state only, no DETAIL.md
code=0
AID_STATE_FILE="${ORPHAN_WORK}/STATE.yml" bash "$SCRIPT" --task-id 99 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 5 "no --delivery-id + no DETAIL.md -> exit 5 (cannot resolve delivery)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: Idempotency ==="

# Field update with same value -- task STATE.yml byte-count must not change
BEFORE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.yml")
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress"
AFTER=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.yml")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "field mode: idempotent -- same value, no size change"
else
    fail "field mode: not idempotent -- task STATE.yml size changed from $BEFORE to $AFTER"
fi

# Findings: re-write same block -- task STATE.yml size must not change
BEFORE=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.yml")
bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_BLOCK"
AFTER=$(wc -c < "${DELIVERY_001}/tasks/task-001/STATE.yml")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "findings mode: idempotent -- same block, no task STATE.yml size change"
else
    fail "findings mode: not idempotent -- task STATE.yml size changed from $BEFORE to $AFTER"
fi

# delivery-block: re-write same block -- delivery STATE.yml size must not change.
# Unit 3 left delivery-001 at the GATE_BLOCK_CLEAN (empty issue_list) state, so
# first re-establish GATE_BLOCK2 as the current state before measuring idempotency
# against it (otherwise this compares two DIFFERENT blocks, not "same block twice").
bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
BEFORE=$(wc -c < "${DELIVERY_001}/STATE.yml")
bash "$SCRIPT" --delivery-id 1 --block "$GATE_BLOCK2"
AFTER=$(wc -c < "${DELIVERY_001}/STATE.yml")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "delivery-block mode: idempotent -- same block, delivery STATE.yml size unchanged"
else
    fail "delivery-block mode: not idempotent -- delivery STATE.yml size changed from $BEFORE to $AFTER"
fi

# append-issue: same row -> no-op (no duplicate)
BEFORE=$(grep -c "task-003" "$ISSUES_FILE")
bash "$SCRIPT" --delivery-id 1 --append-issue "$ROW1"
AFTER=$(grep -c "task-003" "$ISSUES_FILE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "append-issue: idempotent -- duplicate row not added"
else
    fail "append-issue: not idempotent -- row count changed from $BEFORE to $AFTER"
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
    AID_STATE_FILE="${CONC_WORK}/STATE.yml" \
        bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" &
    AID_STATE_FILE="${CONC_WORK}/STATE.yml" \
        bash "$SCRIPT" --delivery-id 1 --task-id 2 --field State --value "In Progress" &
    AID_STATE_FILE="${CONC_WORK}/STATE.yml" \
        bash "$SCRIPT" --delivery-id 1 --task-id 3 --field State --value "Failed" &
    AID_STATE_FILE="${CONC_WORK}/STATE.yml" \
        bash "$SCRIPT" --delivery-id 1 --task-id 4 --field State --value "Blocked" &
    AID_STATE_FILE="${CONC_WORK}/STATE.yml" \
        bash "$SCRIPT" --delivery-id 1 --task-id 5 --field State --value "In Review" &
    wait
)

declare -A CONC_VALS=([1]="Done" [2]="In Progress" [3]="Failed" [4]="Blocked" [5]="In Review")
for i in 1 2 3 4 5; do
    padded=$(printf '%03d' "$i")
    expected="${CONC_VALS[$i]}"
    assert_file_contains "${CONC_DELIV}/tasks/task-${padded}/STATE.yml" "$expected" \
        "concurrent P${i} write landed in task-${padded}/STATE.yml (${expected})"
done

# No lock files left behind
for i in 1 2 3 4 5; do
    padded=$(printf '%03d' "$i")
    if [[ ! -f "${CONC_DELIV}/tasks/task-${padded}/.writeback-state.lock" ]]; then
        pass "task-${padded}: no stale lock file after concurrent write"
    else
        fail "task-${padded}: stale lock file found -- possible deadlock"
    fi
done

# Work STATE.yml must remain untouched
assert_file_not_contains "${CONC_WORK}/STATE.yml" "Done" "work STATE.yml NOT touched by concurrent task writes"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: --pipeline field writes (key creation on a document with none of the base keys yet) ==="

# make_pipeline_state: an EXISTING work STATE.yml with none of the base
# pipeline keys yet -- comments only. The whole document is now the key
# space (no separate frontmatter zone to synthesize any more; D-1), so a
# missing key is simply appended at the END of the file by wb_set_kv, and
# every pre-existing line is reproduced byte-for-byte ahead of it (FR-4a).
make_pipeline_state() {
    local dest="$1"
    mkdir -p "$(dirname "$dest")"
    cat > "$dest" <<'PIPEEOF'
# Work State -- work-pipeline-test

# Triage
# (none)

# Deploy State
# no deliveries yet
PIPEEOF
}

PIPE_STATE="${TMPDIR_BASE}/pipe09/STATE.yml"
make_pipeline_state "$PIPE_STATE"
BODY_BEFORE_09_FILE="${TMPDIR_BASE}/pipe09/before-body.txt"
cp "$PIPE_STATE" "$BODY_BEFORE_09_FILE"

# 9a: No base keys yet -- writing Lifecycle appends the key (no die: the FILE exists)
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_zero "$code" "9a: Lifecycle write with no prior base keys -> exit 0"
assert_file_contains "$PIPE_STATE" "lifecycle: Running" "9a: lifecycle key written"

# 9b: Phase field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "9b: Phase write -> exit 0"
assert_file_contains "$PIPE_STATE" "phase: Execute" "9b: Phase field written"

# 9c: Active Skill field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null || code=$?
assert_exit_zero "$code" "9c: Active Skill write -> exit 0"
assert_file_contains "$PIPE_STATE" "active_skill: aid-develop" "9c: Active Skill field written"

# 9d: Updated field write
code=0
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Updated --value "2026-06-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "9d: Updated write -> exit 0"
assert_file_contains "$PIPE_STATE" "updated: '2026-06-10'" "9d: Updated field written (single-quoted -- date-like value, D-5/NFR-2)"

# 9e: All four base fields coexist, each exactly once
for f_name in "lifecycle" "phase" "active_skill" "updated"; do
    count=$(grep -cE "^${f_name}:" "$PIPE_STATE")
    if [[ "$count" -eq 1 ]]; then
        pass "9e: key '$f_name' appears exactly once after four separate writes"
    else
        fail "9e: key '$f_name' appears $count times (expected 1)"
    fi
done

# 9f: Other pre-existing comment lines not disturbed
assert_file_contains "$PIPE_STATE" "# Triage" "9f: Triage comment preserved after pipeline writes"
assert_file_contains "$PIPE_STATE" "# Deploy State" "9f: Deploy State comment preserved after pipeline writes"

# 9f-2: FR-4a byte-invariance -- every pre-existing line is reproduced
# byte-for-byte ahead of the newly-appended keys (proven via `cmp` on the
# BEFORE file against the AFTER file's equal-length PREFIX, not `$(...)`
# command substitution, which silently strips trailing newlines and would
# hide exactly the class of regression this check exists to catch).
BEFORE_LINES_09=$(wc -l < "$BODY_BEFORE_09_FILE")
PREFIX_AFTER_09_FILE="${TMPDIR_BASE}/pipe09/after-prefix.txt"
head -n "$BEFORE_LINES_09" "$PIPE_STATE" > "$PREFIX_AFTER_09_FILE"
if cmp -s "$BODY_BEFORE_09_FILE" "$PREFIX_AFTER_09_FILE"; then
    pass "9f-2: every pre-existing line reproduced byte-for-byte (FR-4a) ahead of the newly-appended keys"
else
    fail "9f-2: pre-existing lines changed after key synthesis (byte-invariance violated) -- cmp: $(cmp "$BODY_BEFORE_09_FILE" "$PREFIX_AFTER_09_FILE" 2>&1)"
fi

# 9g: A second fresh file -- writing a non-Lifecycle field (Phase) FIRST also
# appends cleanly (order of first-write does not matter).
PIPE_STATE_G="${TMPDIR_BASE}/pipe09g/STATE.yml"
make_pipeline_state "$PIPE_STATE_G"
code=0
AID_STATE_FILE="$PIPE_STATE_G" bash "$SCRIPT" --pipeline --field Phase --value Plan 2>/dev/null || code=$?
assert_exit_zero "$code" "9g: Phase write with no prior base keys -> exit 0"
assert_file_contains "$PIPE_STATE_G" "phase: Plan" "9g: Phase field written on a document with no base keys yet"

# 9h: Update (overwrite) an existing key value
AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
assert_file_contains "$PIPE_STATE" "lifecycle: Completed" "9h: Lifecycle key overwritten to Completed"
assert_file_not_contains "$PIPE_STATE" "lifecycle: Running" "9h: old Lifecycle value Running removed"

# 9i: Active Skill set to 'none' is valid
PIPE_STATE_I="${TMPDIR_BASE}/pipe09i/STATE.yml"
make_pipeline_state "$PIPE_STATE_I"
code=0
AID_STATE_FILE="$PIPE_STATE_I" bash "$SCRIPT" --pipeline --field "Active Skill" --value "none" 2>/dev/null || code=$?
assert_exit_zero "$code" "9i: Active Skill=none is valid -> exit 0"
assert_file_contains "$PIPE_STATE_I" "active_skill: none" "9i: Active Skill none written"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: --pipeline enum acceptance + rejection ==="

PIPE_STATE10="${TMPDIR_BASE}/pipe10/STATE.yml"
make_pipeline_state "$PIPE_STATE10"

# 10a: All valid Lifecycle values accepted (rc 0)
for lc_val in Running Paused-Awaiting-Input Blocked Completed Canceled; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "$lc_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "10a: Lifecycle=$lc_val accepted (exit 0)"
done

# 10b: Invalid Lifecycle value -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "InProgress" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10b: Lifecycle=InProgress rejected (exit 4)"

# 10c: Lowercase Lifecycle rejected -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Lifecycle --value "running" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10c: Lifecycle=running (lowercase) rejected (exit 4)"

# 10d: All valid Phase values accepted (rc 0) -- faithful numbered pipeline;
# ends at Execute (Deploy/Monitor/Interview are not phases -- see 10d-ii).
for ph_val in Describe Define Specify Plan Detail Execute; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "10d: Phase=$ph_val accepted (exit 0)"
done

# 10d-ii: non-phase / retired values rejected on WRITE -- Deploy is a separate
# path (no longer a phase); Interview/Monitor are retired labels.
for ph_val in Deploy Interview Monitor; do
    code=0
    AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/null || code=$?
    assert_exit_eq "$code" 4 "10d-ii: Phase=$ph_val (retired) rejected (exit 4)"
done

# 10e: Invalid Phase value -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "Build" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10e: Phase=Build rejected (exit 4)"

# 10f: Lowercase Phase rejected -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "execute" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10f: Phase=execute (lowercase) rejected (exit 4)"

# 10g: Valid aid-{skill} Active Skill value accepted
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-review" 2>/dev/null || code=$?
assert_exit_zero "$code" "10g: Active Skill=aid-review accepted (exit 0)"

# 10h: Active Skill without aid- prefix -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "develop" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10h: Active Skill=develop (no aid- prefix) rejected (exit 4)"

# 10i: Active Skill = aid- only (empty skill part) -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10i: Active Skill=aid- (empty skill part) rejected (exit 4)"

# 10j: Unknown field name -> exit 4
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field "UnknownField" --value "x" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "10j: unknown pipeline field rejected (exit 4)"

# 10k: --pipeline without --field -> exit non-zero (exit 5)
code=0
AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline 2>/dev/null || code=$?
assert_exit_nonzero "$code" "10k: --pipeline without --field -> non-zero exit"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 11: --pipeline conditional Pause/Block fields ==="

make_cond_state() {
    local dest="$1"
    make_pipeline_state "$dest"
    AID_STATE_FILE="$dest" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
}

# 11a: Pause Reason written when Lifecycle=Paused-Awaiting-Input
PIPE_STATE11A="${TMPDIR_BASE}/pipe11a/STATE.yml"
make_cond_state "$PIPE_STATE11A"
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for user clarification" 2>/dev/null || code=$?
assert_exit_zero "$code" "11a: Pause Reason write under Paused-Awaiting-Input -> exit 0"
assert_file_contains "$PIPE_STATE11A" "pause_reason: 'Waiting for user clarification'" "11a: Pause Reason field written"

# 11b: Block Reason + Block Artifact written when Lifecycle=Blocked
PIPE_STATE11B="${TMPDIR_BASE}/pipe11b/STATE.yml"
make_cond_state "$PIPE_STATE11B"
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Waiting for dependency" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Reason write under Blocked -> exit 0"
assert_file_contains "$PIPE_STATE11B" "block_reason: 'Waiting for dependency'" "11b: Block Reason field written"
code=0
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "task-007.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "11b: Block Artifact write under Blocked -> exit 0"
assert_file_contains "$PIPE_STATE11B" "block_artifact: task-007.md" "11b: Block Artifact field written"

# 11c: Transition OUT of Paused-Awaiting-Input clears Pause Reason (reset to
# the "--" null sentinel -- the key stays present, just cleared)
AID_STATE_FILE="$PIPE_STATE11A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_contains "$PIPE_STATE11A" "pause_reason: --" "11c: Pause Reason cleared after Lifecycle->Running"
assert_file_not_contains "$PIPE_STATE11A" "Waiting for user clarification" "11c: old Pause Reason value gone after clear"

# 11d: Transition OUT of Blocked clears Block Reason and Block Artifact
AID_STATE_FILE="$PIPE_STATE11B" bash "$SCRIPT" --pipeline --field Lifecycle --value "Running" 2>/dev/null
assert_file_contains "$PIPE_STATE11B" "block_reason: --" "11d: Block Reason cleared after Lifecycle->Running"
assert_file_contains "$PIPE_STATE11B" "block_artifact: --" "11d: Block Artifact cleared after Lifecycle->Running"
assert_file_not_contains "$PIPE_STATE11B" "Waiting for dependency" "11d: old Block Reason value gone after clear"

# 11e: Pause Reason cleared when Lifecycle transitions to Blocked
PIPE_STATE11E="${TMPDIR_BASE}/pipe11e/STATE.yml"
make_cond_state "$PIPE_STATE11E"
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Waiting for input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11E" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
assert_file_contains "$PIPE_STATE11E" "pause_reason: --" "11e: Pause Reason cleared when Lifecycle transitions to Blocked"
assert_file_not_contains "$PIPE_STATE11E" "Waiting for input" "11e: old Pause Reason value gone after Blocked transition"

# 11f: Block Reason + Artifact reset to -- after transition from Blocked to Completed
PIPE_STATE11F="${TMPDIR_BASE}/pipe11f/STATE.yml"
make_cond_state "$PIPE_STATE11F"
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Blocked" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Needs review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "review-001.md" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE11F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Completed" 2>/dev/null
assert_file_contains "$PIPE_STATE11F" "block_reason: --" "11f: Block Reason cleared on Lifecycle->Completed"
assert_file_contains "$PIPE_STATE11F" "block_artifact: --" "11f: Block Artifact cleared on Lifecycle->Completed"

# 11g: Fresh Running state -- conditional fields present but at the -- sentinel
PIPE_STATE11G="${TMPDIR_BASE}/pipe11g/STATE.yml"
make_cond_state "$PIPE_STATE11G"
assert_file_contains "$PIPE_STATE11G" "block_reason: --" "11g: Block Reason at -- sentinel on fresh Running state"
assert_file_contains "$PIPE_STATE11G" "block_artifact: --" "11g: Block Artifact at -- sentinel on fresh Running state"
assert_file_contains "$PIPE_STATE11G" "pause_reason: --" "11g: Pause Reason at -- sentinel on fresh Running state"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 12: Isolation -- task/findings/block/lifecycle do NOT touch work STATE.yml ==="

ISOL_WORK="${TMPDIR_BASE}/isol-work"
ISOL_DELIV="${ISOL_WORK}/deliveries/delivery-001"
make_work_state "$ISOL_WORK"
make_delivery_state "$ISOL_WORK" 1
make_task_state "$ISOL_DELIV" 1
make_task_spec  "$ISOL_DELIV" 1 1

WORK_STATE_BEFORE="${ISOL_WORK}/STATE.yml"
INITIAL_WORK_CONTENT=$(cat "$WORK_STATE_BEFORE")

# Task field write
AID_STATE_FILE="${ISOL_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12a: work STATE.yml unchanged after task --field write"
else
    fail "12a: work STATE.yml was modified by task --field write (isolation breach)"
fi

# Task findings write
AID_STATE_FILE="${ISOL_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "- **Reviewer Tier:** Small
- **Findings:**
  - [LOW] test findings" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12b: work STATE.yml unchanged after task --findings write"
else
    fail "12b: work STATE.yml was modified by task --findings write (isolation breach)"
fi

# Delivery block write
AID_STATE_FILE="${ISOL_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --block "- **Issue List:**
  - [LOW] test gate block" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12c: work STATE.yml unchanged after --block write"
else
    fail "12c: work STATE.yml was modified by --block write (isolation breach)"
fi

# Delivery lifecycle write
AID_STATE_FILE="${ISOL_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --lifecycle "Gated" 2>/dev/null
WORK_CONTENT_AFTER=$(cat "$WORK_STATE_BEFORE")
if [[ "$INITIAL_WORK_CONTENT" == "$WORK_CONTENT_AFTER" ]]; then
    pass "12d: work STATE.yml unchanged after --lifecycle write"
else
    fail "12d: work STATE.yml was modified by --lifecycle write (isolation breach)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 13: Error paths ==="

# 13a: No arguments -> exit non-zero
out=$( bash "$SCRIPT" 2>&1 ) || code=$?
assert_exit_nonzero "${code:-0}" "no args -> non-zero exit"

# 13b: Missing --value with --task-id --field
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State 2>/dev/null || code=$?
assert_exit_nonzero "$code" "missing --value -> exit 5"

# 13c: Invalid task-id (non-numeric)
code=0
bash "$SCRIPT" --delivery-id 1 --task-id abc --field State --value Done 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric task-id -> exit 4"

# 13d: Unknown field name -> exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field NONEXISTENT --value x 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "unknown field name -> exit 4"

# 13e: Task STATE.yml does not exist -> exit 1
code=0
bash "$SCRIPT" --delivery-id 99 --task-id 99 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "task STATE.yml missing -> exit 1"

# 13f: Invalid delivery-id (non-numeric)
code=0
bash "$SCRIPT" --delivery-id xyz --append-issue "| a | b | c | d |" 2>/dev/null || code=$?
assert_exit_nonzero "$code" "non-numeric delivery-id -> exit 4"

# 13g: append-issue with non-table row -> exit 4
code=0
bash "$SCRIPT" --delivery-id 1 --append-issue "not a table row" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "invalid issue row format -> exit 4"

# 13h: Lock held -- simulate contention timeout
LOCK_TEST_TASK="${DELIVERY_001}/tasks/task-001"
LOCK_FILE="${LOCK_TEST_TASK}/.writeback-state.lock"
echo "99999" > "$LOCK_FILE"
code=0
AID_LOCK_TIMEOUT=2 bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value Done 2>/dev/null || code=$?
assert_exit_nonzero "$code" "lock timeout -> exit 2"
rm -f "$LOCK_FILE"

# 13i: work STATE.yml missing -> exit 1 (for --pipeline mode)
code=0
AID_STATE_FILE="${TMPDIR_BASE}/nonexistent/STATE.yml" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "work STATE.yml missing -> exit 1 (--pipeline mode)"

# 13j: Delivery STATE.yml missing -> exit 1 (for --block mode)
code=0
bash "$SCRIPT" --delivery-id 88 --block "- **Issue List:** none" 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "delivery STATE.yml missing -> exit 1 (--block mode)"

# 13k: Delivery STATE.yml missing -> exit 1 (for --lifecycle mode)
code=0
bash "$SCRIPT" --delivery-id 88 --lifecycle "Executing" 2>/dev/null || code=$?
assert_exit_eq "$code" 1 "delivery STATE.yml missing -> exit 1 (--lifecycle mode)"

# 13l: Malformed task STATE.yml (not a YAML mapping) -> exit 6 (nested layout, mode_field)
MALFORMED_TASK="${TMPDIR_BASE}/malformed-task"
mkdir -p "${MALFORMED_TASK}/deliveries/delivery-001/tasks/task-001"
printf 'This is not a YAML mapping at all -- just prose text.\n' > "${MALFORMED_TASK}/deliveries/delivery-001/tasks/task-001/STATE.yml"
code=0
AID_TASK_STATE_FILE="${MALFORMED_TASK}/deliveries/delivery-001/tasks/task-001/STATE.yml" \
    bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 6 "malformed task STATE.yml (not a mapping) -> exit 6"

# 13m: Malformed work STATE.yml -> exit 6 (nested layout, mode_delivery_lifecycle already
# covered at Unit 4; this covers the SAME check surfaced through mode_field's flat branch)
MALFORMED_FLAT_FIELD="${TMPDIR_BASE}/malformed-flat-field"
mkdir -p "$MALFORMED_FLAT_FIELD"
printf -- '- this is a sequence, not a mapping\n- second item\n' > "${MALFORMED_FLAT_FIELD}/STATE.yml"
cat > "${MALFORMED_FLAT_FIELD}/BLUEPRINT.md" <<'BPEOF'
# Delivery BLUEPRINT -- delivery-001
BPEOF
mkdir -p "${MALFORMED_FLAT_FIELD}/tasks/task-001"
cat > "${MALFORMED_FLAT_FIELD}/tasks/task-001/DETAIL.md" <<'DEOF'
# task-001: Test Task
**Source:** work-malformed-flat -> delivery-001
DEOF
code=0
AID_STATE_FILE="${MALFORMED_FLAT_FIELD}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value Done 2>/dev/null || code=$?
assert_exit_eq "$code" 6 "malformed flat-layout STATE.yml (a sequence, not a mapping) -> exit 6"

# 13n: exit 3 -- writeback verify failure, fault-injected. The verify-and-die
# wiring is real production code, but WB_SET_KV_AWK never legitimately
# mismatches through the public CLI surface (every scalar is single-line by
# construction, D-5), so this runs a corrupted COPY of the script whose
# quote_value() is patched to silently drop the value for one magic sentinel,
# confirming wb_state_verify catches the mismatch and dies with exit 3 rather
# than writing corrupted output.
CORRUPT_SCRIPT="${TMPDIR_BASE}/corrupt-writeback-state.sh"
sed 's/function quote_value(v,    out) {/function quote_value(v,    out) { if (v == "EXIT3-SENTINEL") return "WRONG-VALUE";/' "$SCRIPT" > "$CORRUPT_SCRIPT"
EXIT3_WORK="${TMPDIR_BASE}/exit3-work"
EXIT3_DELIV="${EXIT3_WORK}/deliveries/delivery-001"
make_work_state "$EXIT3_WORK"
make_delivery_state "$EXIT3_WORK" 1
make_task_state "$EXIT3_DELIV" 1
make_task_spec  "$EXIT3_DELIV" 1 1
code=0
AID_STATE_FILE="${EXIT3_WORK}/STATE.yml" bash "$CORRUPT_SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value "EXIT3-SENTINEL" 2>/dev/null || code=$?
assert_exit_eq "$code" 3 "13n: verify-mismatch (fault-injected) -> exit 3"
assert_file_not_contains "${EXIT3_DELIV}/tasks/task-001/STATE.yml" "WRONG-VALUE" "13n: corrupted output discarded, original file preserved on exit 3"
assert_file_contains "${EXIT3_DELIV}/tasks/task-001/STATE.yml" "notes: --" "13n: original notes value untouched after the exit-3 fault"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 14: FR-4b INVERSION -- --value containing '|' or a newline now round-trips intact ==="

# Pre-refactor this was H2 ("pipe rejected, exit 4"). FR-4b deletes the pipe
# and newline reject guards entirely: a value carrying either now single- or
# double-quotes cleanly and round-trips, per D-5. Recorded as an intended
# change-set inversion, not a regression.
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value "a|b" 2>/dev/null || code=$?
assert_exit_zero "$code" "H2 INVERTED: pipe in --value now accepted -> exit 0"
recovered_pipe=$(grep -m1 '^notes:' "${DELIVERY_001}/tasks/task-001/STATE.yml" | sed 's/^notes:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_pipe" "a|b" "H2 INVERTED: the '|' round-trips intact through single-quote escaping"

# H2b INVERTED: newline in --value also accepted and round-trips (double-quoted, D-5 mode 3)
code=0
bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Notes --value $'line1\nline2' 2>/dev/null || code=$?
assert_exit_zero "$code" "H2b INVERTED: newline in --value now accepted -> exit 0"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" 'notes: "line1\nline2"' "H2b INVERTED: the double-quoted escaped form is on disk"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 15: M2 -- missing lock directory detected before contention ==="

# When AID_LOCK_DIR is set to a nonexistent directory, the lock acquire step
# should detect the missing directory before waiting and return exit 1.
code=0
err_out=$(AID_LOCK_DIR="${TMPDIR_BASE}/nonexistent-lock-dir" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value Done 2>&1) || code=$?
assert_exit_nonzero "$code" "M2 missing lock dir -> exit non-zero"
if echo "$err_out" | grep -q "lock directory does not exist"; then
    pass "M2 missing lock dir: error message mentions 'lock directory does not exist'"
else
    fail "M2 missing lock dir: expected 'lock directory does not exist' in error output, got: $err_out"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 16: State field enum validation (field=State) ==="

# 16.1 -- All 7 State members accepted (exit 0)
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
    AID_STATE_FILE="${S16_WORK}/STATE.yml" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$state_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "16.1: State='${state_val}' accepted (exit 0)"
    # D-5: bare iff the value has no space/special char; a multi-word value single-quotes.
    if [[ "$state_val" =~ ^[A-Za-z0-9_./+-]+$ ]]; then
        EXPECT16="state: ${state_val}"
    else
        EXPECT16="state: '${state_val}'"
    fi
    assert_file_contains "${S16_WORK}/deliveries/delivery-001/tasks/task-001/STATE.yml" \
        "$EXPECT16" "16.1: State='${state_val}' written to task STATE.yml"
done

# 16.2 -- _none yet_ placeholder accepted
echo ""
echo "--- 16.2: _none yet_ placeholder accepted ---"

S16_NONE_WORK="${TMPDIR_BASE}/unit16-none/work"
make_work_state "$S16_NONE_WORK"
make_delivery_state "$S16_NONE_WORK" 1
make_task_state "${S16_NONE_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_NONE_WORK}/deliveries/delivery-001" 1 1
code=0
AID_STATE_FILE="${S16_NONE_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "_none yet_" 2>/dev/null || code=$?
assert_exit_zero "$code" "16.2: State='_none yet_' placeholder accepted (exit 0)"
assert_file_contains "${S16_NONE_WORK}/deliveries/delivery-001/tasks/task-001/STATE.yml" \
    "_none yet_" "16.2: _none yet_ placeholder written to task STATE.yml"

# 16.3 -- Out-of-enum values rejected (exit 4)
echo ""
echo "--- 16.3: Out-of-enum values rejected (exit 4) ---"

for bad_val in "running" "DONE" "Finished" "in progress" "InProgress" "todo" "PENDING" "Status"; do
    S16_BAD_WORK="${TMPDIR_BASE}/unit16-bad-$(echo "$bad_val" | tr ' /' '_')/work"
    make_work_state "$S16_BAD_WORK"
    make_delivery_state "$S16_BAD_WORK" 1
    make_task_state "${S16_BAD_WORK}/deliveries/delivery-001" 1
    make_task_spec  "${S16_BAD_WORK}/deliveries/delivery-001" 1 1
    code=0
    AID_STATE_FILE="${S16_BAD_WORK}/STATE.yml" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$bad_val" 2>/dev/null || code=$?
    assert_exit_eq "$code" 4 "16.3: State='${bad_val}' rejected (exit 4)"
    # task STATE.yml still shows Pending
    assert_file_contains "${S16_BAD_WORK}/deliveries/delivery-001/tasks/task-001/STATE.yml" \
        "state: Pending" "16.3: task STATE.yml unchanged after rejection of '${bad_val}'"
done

# 16.4 -- C4 no-regression: the 6 legacy producer strings still accepted
echo ""
echo "--- 16.4: C4 no-regression -- 6 legacy producer strings accepted (field=State) ---"

for legacy_val in "Pending" "In Progress" "In Review" "Blocked" "Done" "Failed"; do
    S16_LEG_WORK="${TMPDIR_BASE}/unit16-legacy-$(echo "$legacy_val" | tr ' ' '_')/work"
    make_work_state "$S16_LEG_WORK"
    make_delivery_state "$S16_LEG_WORK" 1
    make_task_state "${S16_LEG_WORK}/deliveries/delivery-001" 1
    make_task_spec  "${S16_LEG_WORK}/deliveries/delivery-001" 1 1
    code=0
    AID_STATE_FILE="${S16_LEG_WORK}/STATE.yml" bash "$SCRIPT" \
        --delivery-id 1 --task-id 1 --field State --value "$legacy_val" 2>/dev/null || code=$?
    assert_exit_zero "$code" "16.4: C4 legacy State='${legacy_val}' accepted (exit 0)"
done

# 16.5 -- Enum guard is State-field-only; other fields accept arbitrary values
echo ""
echo "--- 16.5: State-only scope -- enum does not leak to other fields ---"

S16_SCOPE_WORK="${TMPDIR_BASE}/unit16-scope/work"
make_work_state "$S16_SCOPE_WORK"
make_delivery_state "$S16_SCOPE_WORK" 1
make_task_state "${S16_SCOPE_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_SCOPE_WORK}/deliveries/delivery-001" 1 1

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Notes --value "anything weird !@#" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Notes='anything weird !@#' accepted (enum does not leak to Notes)"
assert_file_contains "${S16_SCOPE_WORK}/deliveries/delivery-001/tasks/task-001/STATE.yml" \
    "anything weird !@#" "16.5: Notes value written successfully"

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Elapsed --value "running" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Elapsed='running' accepted (enum does not apply to Elapsed)"

SCOPE_CODE=0
AID_STATE_FILE="${S16_SCOPE_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field Review --value "done" 2>/dev/null || SCOPE_CODE=$?
assert_exit_zero "$SCOPE_CODE" "16.5: Review='done' accepted (enum does not apply to Review)"

# 16.6 -- State value grep-recoverable in task STATE.yml
echo ""
echo "--- 16.6: Deterministic consumability -- State grep-recoverable in task STATE.yml ---"

S16_CONS_WORK="${TMPDIR_BASE}/unit16-cons/work"
make_work_state "$S16_CONS_WORK"
make_delivery_state "$S16_CONS_WORK" 1
make_task_state "${S16_CONS_WORK}/deliveries/delivery-001" 1
make_task_spec  "${S16_CONS_WORK}/deliveries/delivery-001" 1 1

TASK_STATE_FILE="${S16_CONS_WORK}/deliveries/delivery-001/tasks/task-001/STATE.yml"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "In Review" 2>/dev/null
assert_file_contains "$TASK_STATE_FILE" "state: 'In Review'" "16.6: 'In Review' written as a quoted state: scalar"

# Recover via grep (single-quoted scalar; strip one layer of surrounding
# quotes -- either style -- as the reader twins' scalar parsers do)
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "In Review" "16.6: State value grep-recoverable from task STATE.yml"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "Done" "16.6: State 'Done' grep-recoverable after overwrite"

AID_STATE_FILE="${S16_CONS_WORK}/STATE.yml" bash "$SCRIPT" \
    --delivery-id 1 --task-id 1 --field State --value "Canceled" 2>/dev/null
recovered_state=$(grep -m1 '^state:' "$TASK_STATE_FILE" | sed 's/^state:[ \t]*//' | sed "s/^\\(.\\)\\(.*\\)\\1\$/\\2/")
assert_eq "$recovered_state" "Canceled" "16.6: State 'Canceled' grep-recoverable from task STATE.yml"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 17: Concurrency -- --pipeline ∥ --pipeline and --pipeline ∥ --field ==="

PIPE_STATE17="${TMPDIR_BASE}/pipe17/STATE.yml"
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

assert_file_contains "$PIPE_STATE17" "# Triage" "17a: unrelated comment intact after concurrent pipeline writes"

for f_name in "lifecycle" "phase" "active_skill" "updated"; do
    count=$(grep -cE "^${f_name}:" "$PIPE_STATE17" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17a: field '$f_name' appears exactly once after concurrent writes (no duplication)"
    else
        fail "17a: field '$f_name' appears $count times after concurrent writes (expected 1)"
    fi
done

if [[ ! -f "$(dirname "$PIPE_STATE17")/.writeback-state.lock" ]]; then
    pass "17a: no stale lock file after concurrent pipeline writes"
else
    fail "17a: stale lock file found -- possible deadlock in concurrent pipeline writes"
fi

# 17b: Mixed --pipeline ∥ --field concurrent writes -- different target files
# (work STATE.yml vs. task STATE.yml), so they use different lock files and
# can proceed fully in parallel.
PIPE_STATE17B="${TMPDIR_BASE}/pipe17b/STATE.yml"
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

assert_file_contains "$PIPE_STATE17B" "# Triage" "17b: unrelated comment intact after --pipeline ∥ --field mix"
assert_file_contains "${CONC17B_DELIV}/tasks/task-001/STATE.yml" "quick_check:" "17b: task STATE.yml intact after mixed concurrent writes"

for f_name in "lifecycle" "phase"; do
    count=$(grep -cE "^${f_name}:" "$PIPE_STATE17B" || true)
    if [[ "$count" -eq 1 ]]; then
        pass "17b: field '$f_name' appears exactly once after mixed concurrent writes"
    else
        fail "17b: field '$f_name' appears $count times in the work file after mixed writes (expected 1)"
    fi
done

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: FR16 derivation primitives -- on-disk key determinism ==="

PIPE_STATE18="${TMPDIR_BASE}/pipe18/STATE.yml"
make_pipeline_state "$PIPE_STATE18"

# 18a: Running state -- lifecycle readable, conditional fields at the -- sentinel
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE18" "lifecycle: Running" "18a: FR16 Running -- lifecycle value derivable"
assert_file_contains "$PIPE_STATE18" "pause_reason: --" "18a: FR16 Running -- pause_reason at -- sentinel"
assert_file_contains "$PIPE_STATE18" "block_reason: --" "18a: FR16 Running -- block_reason at -- sentinel"
assert_file_contains "$PIPE_STATE18" "block_artifact: --" "18a: FR16 Running -- block_artifact at -- sentinel"

# 18b: Paused-Awaiting-Input state -- pause_reason present, Block fields at --
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Awaiting spec clarification" 2>/dev/null
assert_file_contains "$PIPE_STATE18" "lifecycle: Paused-Awaiting-Input" "18b: FR16 Paused -- lifecycle value derivable"
assert_file_contains "$PIPE_STATE18" "pause_reason: 'Awaiting spec clarification'" "18b: FR16 Paused -- pause_reason present"
assert_file_contains "$PIPE_STATE18" "block_reason: --" "18b: FR16 Paused -- block_reason at -- sentinel"
assert_file_contains "$PIPE_STATE18" "block_artifact: --" "18b: FR16 Paused -- block_artifact at -- sentinel"

# 18c: Blocked state -- Block Reason + Block Artifact present, pause_reason at --
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Blocked on external review" 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Block Artifact" --value "pr-001.md" 2>/dev/null
assert_file_contains "$PIPE_STATE18" "lifecycle: Blocked" "18c: FR16 Blocked -- lifecycle value derivable"
assert_file_contains "$PIPE_STATE18" "block_reason: 'Blocked on external review'" "18c: FR16 Blocked -- block_reason present"
assert_file_contains "$PIPE_STATE18" "block_artifact: pr-001.md" "18c: FR16 Blocked -- block_artifact present"
assert_file_contains "$PIPE_STATE18" "pause_reason: --" "18c: FR16 Blocked -- pause_reason at -- sentinel"

# 18d: Completed state -- all conditional fields at the -- sentinel
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Completed 2>/dev/null
assert_file_contains "$PIPE_STATE18" "lifecycle: Completed" "18d: FR16 Completed -- lifecycle value derivable"
assert_file_contains "$PIPE_STATE18" "pause_reason: --" "18d: FR16 Completed -- pause_reason at -- sentinel"
assert_file_contains "$PIPE_STATE18" "block_reason: --" "18d: FR16 Completed -- block_reason at -- sentinel"
assert_file_contains "$PIPE_STATE18" "block_artifact: --" "18d: FR16 Completed -- block_artifact at -- sentinel"

# 18e: Grep-recovery of field values from the on-disk key space
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field "Active Skill" --value "aid-develop" 2>/dev/null
lc_val=$(grep -m1 '^lifecycle:' "$PIPE_STATE18" | sed 's/^lifecycle:[ \t]*//')
ph_val=$(grep -m1 '^phase:' "$PIPE_STATE18" | sed 's/^phase:[ \t]*//')
as_val=$(grep -m1 '^active_skill:' "$PIPE_STATE18" | sed 's/^active_skill:[ \t]*//')
assert_eq "$lc_val" "Running" "18e: FR16 lifecycle value grep-recoverable on disk"
assert_eq "$ph_val" "Execute" "18e: FR16 phase value grep-recoverable on disk"
assert_eq "$as_val" "aid-develop" "18e: FR16 active_skill value grep-recoverable on disk"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 19: M5 -- pause/block signal sequences ==="

# 19a: Pause path (PAUSE-FOR-USER-ACTION emit sequence)
PIPE_STATE19A="${TMPDIR_BASE}/pipe19a/STATE.yml"
make_pipeline_state "$PIPE_STATE19A"
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Phase --value Specify 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-specify 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Blocker pending -- awaiting loopback resolution before /aid-specify can continue" 2>/dev/null || code=$?
assert_exit_zero "$code" "19a: Pause Reason emit after PAUSE transition -> exit 0"
assert_file_contains "$PIPE_STATE19A" "lifecycle: Paused-Awaiting-Input" "19a: Lifecycle set to Paused-Awaiting-Input"
assert_file_contains "$PIPE_STATE19A" "pause_reason: 'Blocker pending" "19a: Pause Reason written"

# 19b: Resume path -- M4 Running emit clears Pause Reason
AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19A" "lifecycle: Running" "19b: Lifecycle returns to Running on resume"
assert_file_contains "$PIPE_STATE19A" "pause_reason: --" "19b: Pause Reason cleared on Running transition (M4 resume)"
assert_file_not_contains "$PIPE_STATE19A" "Blocker pending" "19b: old Pause Reason text gone after clear"

# 19c: Block path (impediment / Failed task emit sequence)
PIPE_STATE19C="${TMPDIR_BASE}/pipe19c/STATE.yml"
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
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Task failed with unresolved impediment -- task-001" 2>/dev/null || code=$?
assert_exit_zero "$code" "19c: Block Reason emit after task failure -> exit 0"
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-task-001.md" 2>/dev/null
assert_file_contains "$PIPE_STATE19C" "lifecycle: Blocked" "19c: Lifecycle set to Blocked on task failure"
assert_file_contains "$PIPE_STATE19C" "block_reason: 'Task failed" "19c: Block Reason written"
assert_file_contains "$PIPE_STATE19C" "block_artifact: .aid/work-001/IMPEDIMENT-task-001.md" "19c: Block Artifact written"
assert_file_contains "$PIPE_STATE19C" "pause_reason: --" "19c: Pause Reason at -- sentinel when Blocked"

# 19d: Block resolution path -- M4 Running emit clears Block fields
AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
assert_file_contains "$PIPE_STATE19C" "lifecycle: Running" "19d: Lifecycle returns to Running after impediment resolved"
assert_file_contains "$PIPE_STATE19C" "block_reason: --" "19d: Block Reason cleared on Running transition"
assert_file_contains "$PIPE_STATE19C" "block_artifact: --" "19d: Block Artifact cleared on Running transition"
assert_file_not_contains "$PIPE_STATE19C" "IMPEDIMENT-task-001.md" "19d: old Block Artifact value gone after clear"

# 19e: Delivery-gate circuit-breaker block
PIPE_STATE19E="${TMPDIR_BASE}/pipe19e/STATE.yml"
make_pipeline_state "$PIPE_STATE19E"
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field Lifecycle --value Blocked 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Reason" --value "Delivery gate circuit breaker triggered -- grade not improving after 3 cycles" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19E" bash "$SCRIPT" --pipeline --field "Block Artifact" --value ".aid/work-001/IMPEDIMENT-delivery-001.md" 2>/dev/null || code=$?
assert_exit_zero "$code" "19e: Delivery gate circuit-breaker block emit -> exit 0"
assert_file_contains "$PIPE_STATE19E" "lifecycle: Blocked" "19e: Lifecycle Blocked on circuit-breaker stop"
assert_file_contains "$PIPE_STATE19E" "block_artifact: .aid/work-001/IMPEDIMENT-delivery-001.md" "19e: Block Artifact is delivery IMPEDIMENT path"

# 19f: Delivery-gate non-CODE pause (non-CODE-only STOP -> Paused-Awaiting-Input)
PIPE_STATE19F="${TMPDIR_BASE}/pipe19f/STATE.yml"
make_pipeline_state "$PIPE_STATE19F"
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field Lifecycle --value "Paused-Awaiting-Input" 2>/dev/null
code=0
AID_STATE_FILE="$PIPE_STATE19F" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "Delivery gate blocked on non-CODE issues -- upstream fix required (SPEC/TASK/KB)" 2>/dev/null || code=$?
assert_exit_zero "$code" "19f: Delivery gate non-CODE pause emit -> exit 0"
assert_file_contains "$PIPE_STATE19F" "lifecycle: Paused-Awaiting-Input" "19f: Lifecycle Paused on non-CODE-only gate stop"
assert_file_contains "$PIPE_STATE19F" "pause_reason: 'Delivery gate blocked on non-CODE issues" "19f: Pause Reason explains upstream fix needed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 20: feature-001 flattened single-delivery layout (auto-detected) ==="

# Flat layout fixture: no deliveries/ wrapper; tasks/task-NNN/DETAIL.md directly
# under the work root. The promoted delivery/task keys (delivery_state,
# gate_tier/grade/timestamp, delivery_lifecycle, tasks_lifecycle, delivery_gate)
# all live in the work-root STATE.yml (work-state-template.yml's flattened
# shape, SS D-4).

# make_flat_task_spec WORK_DIR TASK_ID
# Creates tasks/task-NNN/DETAIL.md directly under the work root (no per-task STATE.yml).
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
# Creates the work-root STATE.yml with the promoted feature-001 keys.
make_flat_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.yml" <<'FLATSTATEEOF'
# Work State -- work-flat-test
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-07-08T00:00:00Z'

# Flattened single-delivery layout -- promoted delivery/task keys
delivery_state: Specified
gate_tier: --
gate_grade: Pending
gate_timestamp: --

delivery_lifecycle:
  updated: '2026-07-08T00:00:00Z'
  block_reason: --
  block_artifact: --

tasks_lifecycle: {}

delivery_gate:
  issue_list: []
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

FLAT_STATE="${FLAT_WORK}/STATE.yml"

# 20a: --task-id --field --value on the flat layout targets
# tasks_lifecycle.task-NNN.state -- NOT a per-task STATE.yml (none exists).
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null || code=$?
assert_exit_zero "$code" "20a: flat --field write -> exit 0"
assert_file_contains "$FLAT_STATE" "state: 'In Progress'" "20a: task-001 state key written under tasks_lifecycle"
if [[ ! -f "${FLAT_WORK}/tasks/task-001/STATE.yml" ]]; then
    pass "20a: no per-task STATE.yml created for the flat layout"
else
    fail "20a: a per-task STATE.yml was created -- flat layout must not use one"
fi

# 20b: the tasks_lifecycle: {} placeholder is replaced by a real mapping entry
assert_file_not_contains "$FLAT_STATE" "tasks_lifecycle: {}" "20b: tasks_lifecycle: {} placeholder replaced by a real mapping"
assert_file_contains "$FLAT_STATE" "task-001:" "20b: tasks_lifecycle.task-001 entry present"

# 20c: a second task's first write adds its own sibling entry, and the FIRST
# task's entry survives byte-identical (per-task mapping, not a shared row).
BLOCK_T1_BEFORE_20=$(awk '/^  task-001:/{f=1; print; next} f && !/^    /{exit} f{print}' "$FLAT_STATE")
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 2 --field State --value "Pending" 2>/dev/null || code=$?
assert_exit_zero "$code" "20c: second flat task --field write -> exit 0"
assert_file_contains "$FLAT_STATE" "task-002:" "20c: tasks_lifecycle.task-002 entry appended"
BLOCK_T1_AFTER_20=$(awk '/^  task-001:/{f=1; print; next} f && !/^    /{exit} f{print}' "$FLAT_STATE")
if [[ "$BLOCK_T1_AFTER_20" == "$BLOCK_T1_BEFORE_20" ]]; then
    pass "20c: task-001's mapping entry survived the task-002 write byte-identical"
else
    fail "20c: task-002's write disturbed task-001's mapping entry"
fi
assert_match_count_20() { local pattern="$1" expected="$2" label="$3"
    local actual; actual=$(grep -cE "$pattern" "$FLAT_STATE" 2>/dev/null || true)
    if [[ "${actual:-0}" -eq "$expected" ]]; then pass "$label"; else fail "$label -- expected $expected got ${actual:-0}"; fi
}
assert_match_count_20 '^tasks_lifecycle:' 1 "20c: exactly one tasks_lifecycle: parent header (no duplication)"

# 20d: updating a different field on an existing task entry preserves the state cell
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Review --value "A" 2>/dev/null || code=$?
assert_exit_zero "$code" "20d: flat --field Review write on existing task entry -> exit 0"
assert_file_contains "$FLAT_STATE" "review: A" "20d: task-001 review set to A"
assert_file_contains "$FLAT_STATE" "state: 'In Progress'" "20d: task-001 state preserved (not clobbered by the Review write)"

# 20e: --delivery-id 001 --lifecycle updates the work-root delivery_state
# key directly (no deliveries/delivery-001/STATE.yml is created)
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --lifecycle "Executing" 2>/dev/null || code=$?
assert_exit_zero "$code" "20e: flat --lifecycle write -> exit 0"
assert_file_contains "$FLAT_STATE" "delivery_state: Executing" "20e: work-root delivery_state set to Executing"
if [[ ! -d "${FLAT_WORK}/deliveries" ]]; then
    pass "20e: no deliveries/ directory created for the flat layout"
else
    fail "20e: a deliveries/ directory was created -- flat layout must not use one"
fi

# 20f: --delivery-id 001 --block writes the work-root delivery_gate.issue_list
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --block "- **Issue List:**
  - [LOW] flat gate finding" 2>/dev/null || code=$?
assert_exit_zero "$code" "20f: flat --block write -> exit 0"
assert_file_contains "$FLAT_STATE" "[LOW] flat gate finding" "20f: work-root delivery_gate.issue_list item written"
# Sibling keys survive the rewrite (KI-010 regression guard on the flat path too)
assert_file_contains "$FLAT_STATE" "delivery_state: Executing" "20f: delivery_state key survives the --block rewrite"

# 20g: idempotency -- rewriting the same field value leaves the file byte-identical
BEFORE=$(wc -c < "$FLAT_STATE")
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null
AFTER=$(wc -c < "$FLAT_STATE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "20g: flat --field write is idempotent -- no size change on same value"
else
    fail "20g: flat --field write not idempotent -- size changed from $BEFORE to $AFTER"
fi

# 20h: malformed flat work (not a YAML mapping at all) -> exit 6
FLAT_MALFORMED="${TMPDIR_BASE}/work-flat-malformed"
mkdir -p "$FLAT_MALFORMED"
printf 'This is not a YAML mapping at all -- just prose text.\n' > "${FLAT_MALFORMED}/STATE.yml"
# BLUEPRINT.md must be present so is_flat_layout()'s 3-part rule (BLUEPRINT.md
# present AND DETAIL.md present AND no deliveries/) still routes this fixture
# through the flat branch -- otherwise it falls through to the hierarchical
# --field path (a different, unresolvable delivery-STATE.yml path) and this
# unit would no longer exercise the "malformed flat work" scenario.
make_flat_blueprint "$FLAT_MALFORMED"
make_flat_task_spec "$FLAT_MALFORMED" 1
code=0
AID_STATE_FILE="${FLAT_MALFORMED}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null || code=$?
assert_exit_eq "$code" 6 "20h: flat work with a non-mapping STATE.yml -> exit 6 (malformed)"

# 20i: nested-path regression -- the ORIGINAL hierarchical fixture (has
# deliveries/) from the top of this file must still route through the
# per-unit STATE.yml files, completely unaffected by the flat-layout branch.
code=0
run_field 1 1 State "Done" || code=$?
assert_exit_zero "$code" "20i: nested-path --field write still succeeds after flat-layout changes"
assert_file_contains "${DELIVERY_001}/tasks/task-001/STATE.yml" "state: Done" "20i: nested-path task-001 STATE.yml still the write target"
# The flat fixture's OWN task-001 entry (from 20a) is expected to be present --
# the property under test is that the nested write did not add a SECOND one
# (cross-contamination), not that "task-001:" is absent altogether.
FLAT_T1_COUNT=$(grep -cE '^  task-001:' "$FLAT_STATE")
if [[ "$FLAT_T1_COUNT" -eq 1 ]]; then
    pass "20i: flat fixture's own task-001 entry still appears exactly once (no cross-contamination)"
else
    fail "20i: flat fixture's task-001 entry count is $FLAT_T1_COUNT, expected 1"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 21: octal footgun regression -- zero-padded ids containing 8/9 ==="

# A zero-padded id containing an 8 or 9 (e.g. "008", "090") is NOT a valid
# octal literal. Before the fix, every `printf '%03d' "$id"` site in this
# script fed the raw id straight to printf, which bash parses as an octal
# number when it looks like one -- "008"/"090" triggered a bash "invalid
# octal number" error and printf substituted "000" on stdout (captured by
# the surrounding `$(...)`), silently resolving to the WRONG path
# (delivery-000/task-000) instead of erroring loudly. The fix wraps every
# such id in `$((10#$id))` first to force base-10 arithmetic before padding.
# Unaffected by the STATE.md -> STATE.yml rename (SP-7): the padding sites are
# filename-independent.

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
AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id "008" --task-id "008" --field State --value "Done" 2>/dev/null || code=$?
assert_exit_zero "$code" "21a: --delivery-id 008 --task-id 008 --field -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.yml" "state: Done" "21a: write landed in delivery-008/tasks/task-008/STATE.yml"
if [[ ! -e "${WORK_21}/deliveries/delivery-000" ]]; then
    pass "21a: no delivery-000 directory was ever consulted (octal misparse would have targeted it)"
else
    fail "21a: delivery-000 exists -- octal misparse regression"
fi

# 21b: --field with zero-padded --delivery-id "090" / --task-id "009" resolves
# to delivery-090/tasks/task-009 (090 is invalid octal; 009 is invalid octal).
code=0
AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id "090" --task-id "009" --field Notes --value "octal-ok" 2>/dev/null || code=$?
assert_exit_zero "$code" "21b: --delivery-id 090 --task-id 009 --field -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_090}/tasks/task-009/STATE.yml" "octal-ok" "21b: write landed in delivery-090/tasks/task-009/STATE.yml"

# 21c: --delivery-id "090" --lifecycle targets delivery-090/STATE.yml directly
# (mode_delivery_lifecycle's own padded_id site).
code=0
AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id "090" --lifecycle "Gated" 2>/dev/null || code=$?
assert_exit_zero "$code" "21c: --delivery-id 090 --lifecycle -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_090}/STATE.yml" "delivery_state: Gated" "21c: lifecycle written to delivery-090/STATE.yml"

# 21d: --delivery-id "008" --block targets delivery-008/STATE.yml directly
# (mode_delivery_block's own padded_id site).
code=0
AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id "008" --block "- **Issue List:**
  - [LOW] octal footgun regression" 2>/dev/null || code=$?
assert_exit_zero "$code" "21d: --delivery-id 008 --block -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/STATE.yml" "octal footgun regression" "21d: gate block written to delivery-008/STATE.yml"

# 21e: --delivery-id "009" --append-issue targets delivery-009-issues.md
# (mode_append_issue's own padded_id site). AID_DELIVERY_ISSUES_DIR is
# overridden per-call here -- it was exported globally to the ORIGINAL
# $WORK_DIR near the top of this file (Unit 5), so without the override
# this write would land in the wrong (original) work dir, not $WORK_21.
code=0
AID_STATE_FILE="${WORK_21}/STATE.yml" AID_DELIVERY_ISSUES_DIR="${WORK_21}" \
    bash "$SCRIPT" --delivery-id "009" --append-issue "| task-009 | [LOW] | octal footgun regression row | Open |" 2>/dev/null || code=$?
assert_exit_zero "$code" "21e: --delivery-id 009 --append-issue -> exit 0 (no octal parse error)"
assert_file_contains "${WORK_21}/delivery-009-issues.md" "octal footgun regression row" "21e: issue row appended to delivery-009-issues.md"

# 21f: omitting --delivery-id and resolving from the task's Source line
# (resolve_delivery_from_task_spec's own padded_t site) for zero-padded
# task-id "008".
code=0
AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --task-id "008" --field Review --value "B" 2>/dev/null || code=$?
assert_exit_zero "$code" "21f: Source-line resolution with task-id 008 -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.yml" "review: B" "21f: Source-line-resolved write landed in delivery-008/tasks/task-008/STATE.yml"

# 21g: feature-001 flattened layout -- the flat --field key path's own
# padded_t site for zero-padded task-id "008".
FLAT_WORK_21="${TMPDIR_BASE}/work-flat-octal21"
make_flat_work_state "$FLAT_WORK_21"
make_flat_blueprint "$FLAT_WORK_21"
make_flat_task_spec "$FLAT_WORK_21" 8
code=0
AID_STATE_FILE="${FLAT_WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id "008" --field State --value "In Progress" 2>/dev/null || code=$?
assert_exit_zero "$code" "21g: flat layout --task-id 008 --field -> exit 0 (no octal parse error)"
assert_file_contains "${FLAT_WORK_21}/STATE.yml" "task-008:" "21g: flat layout tasks_lifecycle entry written for task-008 (not task-000)"

# 21h: --findings with zero-padded --delivery-id/--task-id "008" targets
# delivery-008/tasks/task-008/STATE.yml (mode_findings' own padded_id site,
# used only in its user-facing confirmation message).
FINDINGS_OCTAL="- **Reviewer Tier:** Small
- **Findings:**
  - [LOW] octal footgun regression finding"
code=0
err_out21h=$(AID_STATE_FILE="${WORK_21}/STATE.yml" bash "$SCRIPT" --delivery-id "008" --task-id "008" --findings "$FINDINGS_OCTAL" 2>&1) || code=$?
assert_exit_zero "$code" "21h: --delivery-id 008 --task-id 008 --findings -> exit 0 (no octal parse error)"
assert_file_contains "${DELIVERY_008}/tasks/task-008/STATE.yml" "octal footgun regression finding" "21h: findings block written to delivery-008/tasks/task-008/STATE.yml"
if echo "$err_out21h" | grep -q "task-008"; then
    pass "21h: confirmation message reports 'task-008' (padded_id resolved correctly, not 'task-000')"
else
    fail "21h: confirmation message did not report 'task-008' as expected -- got: $err_out21h"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 22: gate-field + new base fields + single-line-diff/pre-existing-line invariance + CRLF + quoted-value round-trip ==="

# 22a: --pipeline --field extended to Started / Minimum Grade / User Approved /
# Pipeline Path / Pipeline Initiator (all handled by mode_pipeline).
PIPE_STATE22="${TMPDIR_BASE}/pipe22/STATE.yml"
make_pipeline_state "$PIPE_STATE22"
code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field Started --value "2026-07-10" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Started write -> exit 0"
assert_file_contains "$PIPE_STATE22" "started: '2026-07-10'" "22a: started key written (single-quoted -- date-like value, D-5/NFR-2)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Minimum Grade" --value "A+" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Minimum Grade write -> exit 0"
assert_file_contains "$PIPE_STATE22" "minimum_grade: A+" "22a: minimum_grade key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Minimum Grade" --value "Z" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Minimum Grade='Z' (invalid grade) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "User Approved" --value "yes" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: User Approved=yes write -> exit 0"
assert_file_contains "$PIPE_STATE22" "user_approved: 'yes'" "22a: user_approved key written (single-quoted -- yes/no deny-list value, D-5/NFR-2)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "User Approved" --value "maybe" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: User Approved='maybe' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value "lite" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Pipeline Path=lite write -> exit 0"
assert_file_contains "$PIPE_STATE22" "  path: lite" "22a: pipeline.path nested key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value "medium" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Pipeline Path='medium' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value "aid-refactor" 2>/dev/null || code=$?
assert_exit_zero "$code" "22a: Pipeline Initiator=aid-refactor write -> exit 0"
assert_file_contains "$PIPE_STATE22" "  initiator: aid-refactor" "22a: pipeline.initiator nested key written"

code=0
AID_STATE_FILE="$PIPE_STATE22" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value "refactor" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22a: Pipeline Initiator='refactor' (no aid- prefix) rejected (exit 4)"

# Both nested pipeline.* keys coexist under ONE `pipeline:` parent mapping (no duplicate header)
PIPELINE_PARENT_COUNT=$(grep -cE '^pipeline:$' "$PIPE_STATE22")
assert_eq "$PIPELINE_PARENT_COUNT" "1" "22a: exactly one 'pipeline:' parent mapping (path+initiator share it)"

# 22b: --gate-field enum validation
GATE22_WORK="${TMPDIR_BASE}/gate22-work"
make_delivery_state "$GATE22_WORK" 1
code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Medium" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Tier=Medium accepted (exit 0)"
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.yml" "gate_tier: Medium" "22b: gate_tier key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Huge" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: gate-field Tier='Huge' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Grade --gate-value "A-" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Grade=A- accepted (exit 0)"
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.yml" "gate_grade: A-" "22b: gate_grade key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Grade --gate-value "Z" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: gate-field Grade='Z' (invalid) rejected (exit 4)"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Timestamp --gate-value "2026-07-10T12:00:00Z" 2>/dev/null || code=$?
assert_exit_zero "$code" "22b: gate-field Timestamp accepted (exit 0)"
# Quoted -- the value contains ':' (D-5's quoting rule)
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.yml" "gate_timestamp: '2026-07-10T12:00:00Z'" "22b: gate_timestamp key written"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Unknown --gate-value "x" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: unknown gate-field name rejected (exit 4)"

code=0
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Timestamp --gate-value "$(printf 'line1\nline2')" 2>/dev/null || code=$?
assert_exit_eq "$code" 4 "22b: gate-value containing a newline rejected (exit 4; the ONE surviving control-char guard)"

# 22c: gate-field isolation -- the delivery_gate.issue_list sequence is
# untouched by --gate-field writes (disjoint keys).
GATE22B_ISSUE="- **Issue List:**
  - [LOW] pre-existing issue"
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --block "$GATE22B_ISSUE" 2>/dev/null
AID_STATE_FILE="${GATE22_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Small" 2>/dev/null
assert_file_contains "${GATE22_WORK}/deliveries/delivery-001/STATE.yml" "[LOW] pre-existing issue" "22c: delivery_gate.issue_list untouched by a subsequent --gate-field write"

# 22d: gate-field flattened layout -- targets work-root keys (--delivery-id 001)
GATE22_FLAT="${TMPDIR_BASE}/gate22-flat"
make_flat_work_state "$GATE22_FLAT"
make_flat_blueprint "$GATE22_FLAT"
make_flat_task_spec "$GATE22_FLAT" 1
code=0
AID_STATE_FILE="${GATE22_FLAT}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --gate-field Tier --gate-value "Small" 2>/dev/null || code=$?
assert_exit_zero "$code" "22d: flat-layout gate-field write -> exit 0"
assert_file_contains "${GATE22_FLAT}/STATE.yml" "gate_tier: Small" "22d: work-root gate_tier set (flat layout)"
if [[ ! -d "${GATE22_FLAT}/deliveries" ]]; then
    pass "22d: no deliveries/ directory created for the flat layout gate-field write"
else
    fail "22d: a deliveries/ directory was created by --gate-field -- flat layout must not use one"
fi

# 22e: pre-existing-line invariance (critical AC, FR-4a) -- the REAL
# production template. Its five target keys (lifecycle/phase/active_skill/
# pipeline.path/pipeline.initiator) are ALREADY populated (this is an
# overwrite-in-place scenario, not an append), so the invariance property
# under test is narrower and stronger than "unchanged prefix": every line
# NOT among the five touched key lines must be byte-for-byte identical, in
# the SAME position, and the total line count must not change (proving no
# line was inserted or removed by the five writes). Proven via `cmp` on
# file-based, redacted captures (not `$(...)`, which silently strips
# trailing newlines and would hide exactly the class of regression this
# guards).
BINV_WORK="${TMPDIR_BASE}/bodyinvariance-work"
mkdir -p "$BINV_WORK"
BINV_HAS_TEMPLATE=0
if [[ -f "${SCRIPT_DIR}/../../canonical/aid/templates/work-state-template.yml" ]]; then
    cat "${SCRIPT_DIR}/../../canonical/aid/templates/work-state-template.yml" > "${BINV_WORK}/STATE.yml"
    BINV_HAS_TEMPLATE=1
else
    make_pipeline_state "${BINV_WORK}/STATE.yml"
fi
# Drop any trailing newline the source template/fixture happens to end with,
# so this run also exercises the "no final newline" case rather than only
# the far more common "ends with \n" case.
printf '%s' "$(cat "${BINV_WORK}/STATE.yml")" > "${BINV_WORK}/STATE.yml.tmp" && mv "${BINV_WORK}/STATE.yml.tmp" "${BINV_WORK}/STATE.yml"

BEFORE_LINES_22E=$(wc -l < "${BINV_WORK}/STATE.yml")
BODY_BEFORE_22E="${BINV_WORK}/before-body.txt"
cp "${BINV_WORK}/STATE.yml" "$BODY_BEFORE_22E"
AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field Lifecycle --value Running 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field "Active Skill" --value aid-execute 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field "Pipeline Path" --value lite 2>/dev/null
AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field "Pipeline Initiator" --value aid-refactor 2>/dev/null

AFTER_LINES_22E=$(wc -l < "${BINV_WORK}/STATE.yml")
if [[ "$BINV_HAS_TEMPLATE" -eq 1 ]]; then
    # Overwrite-in-place: the five keys pre-exist, so no line is added or removed.
    assert_eq "$AFTER_LINES_22E" "$BEFORE_LINES_22E" "22e: line count unchanged (overwrite-in-place, no insertion/removal)"
    REDACT_RE='^(lifecycle|phase|active_skill|  path|  initiator):'
    BODY_BEFORE_REDACTED="${BINV_WORK}/before-redacted.txt"
    BODY_AFTER_REDACTED="${BINV_WORK}/after-redacted.txt"
    grep -vE "$REDACT_RE" "$BODY_BEFORE_22E" > "$BODY_BEFORE_REDACTED"
    grep -vE "$REDACT_RE" "${BINV_WORK}/STATE.yml" > "$BODY_AFTER_REDACTED"
    if cmp -s "$BODY_BEFORE_REDACTED" "$BODY_AFTER_REDACTED"; then
        pass "22e: every OTHER pre-existing line byte-identical (cmp, redacting only the 5 touched keys) after a sequence of scalar writes (critical AC)"
    else
        fail "22e: a line other than the 5 touched keys changed -- byte-invariance violated -- cmp: $(cmp "$BODY_BEFORE_REDACTED" "$BODY_AFTER_REDACTED" 2>&1)"
    fi
else
    # Fallback fixture (make_pipeline_state): none of the 5 keys pre-exist, so
    # this IS a pure-append scenario -- the prefix must be byte-identical.
    PREFIX_AFTER_22E="${BINV_WORK}/after-prefix.txt"
    head -n "$BEFORE_LINES_22E" "${BINV_WORK}/STATE.yml" > "$PREFIX_AFTER_22E"
    if cmp -s "$BODY_BEFORE_22E" "$PREFIX_AFTER_22E"; then
        pass "22e: every pre-existing line byte-identical (cmp) after a sequence of scalar writes, incl. missing final newline (critical AC)"
    else
        fail "22e: pre-existing lines changed after scalar writes -- byte-invariance violated -- cmp: $(cmp "$BODY_BEFORE_22E" "$PREFIX_AFTER_22E" 2>&1)"
    fi
fi

# 22f: CRLF fixture -- a `\r\n` STATE.yml must survive a scalar write with
# every OTHER line byte-identical (proven via `cmp` rather than `$(...)`,
# which would silently normalize the very `\r` bytes this check guards).
CRLF_WORK="${TMPDIR_BASE}/crlf-work"
mkdir -p "$CRLF_WORK"
CRLF_STATE="${CRLF_WORK}/STATE.yml"
printf -- 'lifecycle: Running\r\nphase: Describe\r\n\r\n# Some comment content with CRLF.\r\nSecond-line-key: no trailing newline' > "$CRLF_STATE"
CRLF_LINES_BEFORE=2  # only the first two lines (lifecycle, phase) are being overwritten
CRLF_TAIL_BEFORE="${CRLF_WORK}/before-tail.txt"
tail -n "+3" "$CRLF_STATE" > "$CRLF_TAIL_BEFORE"
code=0
AID_STATE_FILE="$CRLF_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null || code=$?
assert_exit_zero "$code" "22f: CRLF STATE.yml scalar write -> exit 0"
FENCE_CHECK_22F=$(head -1 "$CRLF_STATE" | od -An -c | grep -c -- '\\r' || true)
if [[ "$FENCE_CHECK_22F" -ge 1 ]]; then
    pass "22f: the untouched lines still carry \\r (CRLF preserved)"
else
    fail "22f: CRLF was stripped from an untouched line -- CRLF handling regressed"
fi
assert_file_contains "$CRLF_STATE" "phase: Execute" "22f: phase key updated"
CRLF_TAIL_AFTER="${CRLF_WORK}/after-tail.txt"
tail -n "+3" "$CRLF_STATE" > "$CRLF_TAIL_AFTER"
if cmp -s "$CRLF_TAIL_BEFORE" "$CRLF_TAIL_AFTER"; then
    pass "22f: CRLF trailing content byte-identical (cmp) after the write, incl. \\r\\n line endings and missing final newline"
else
    fail "22f: CRLF trailing content changed after the write -- cmp: $(cmp "$CRLF_TAIL_BEFORE" "$CRLF_TAIL_AFTER" 2>&1)"
fi

# 22g: quoted-value write is valid YAML and PyYAML-round-trips -- a value
# containing `"`, `\`, `:`, `#`, `|` and a leading `-` must produce a
# single- or double-quoted YAML scalar that survives yaml.safe_load() /
# yaml.safe_dump() with the exact original text intact (SP-5, D-5).
NASTY_VALUE="- a dash-led value with \"double quotes\", a backslash \\ a colon: a #hash and a | pipe"
NASTY_STATE="${TMPDIR_BASE}/pipe22nasty/STATE.yml"
make_pipeline_state "$NASTY_STATE"
code=0
AID_STATE_FILE="$NASTY_STATE" bash "$SCRIPT" --pipeline --field "Pause Reason" --value "$NASTY_VALUE" 2>/dev/null || code=$?
assert_exit_zero "$code" "22g: quoted (nasty, pipe-bearing) value write -> exit 0"

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
try:
    data = yaml.safe_load(text)
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
            pass "22g: quoted-value document is valid YAML and round-trips through PyYAML safe_load/safe_dump"
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
echo "=== Unit 23: Name -> display_name task field ==="

# 23a: nested layout -- --field Name writes the display_name key,
# NOT a literal `name:` key (fm_key indirection).
NAME_WORK="${TMPDIR_BASE}/name-nested-work"
NAME_DELIV="${NAME_WORK}/deliveries/delivery-001"
make_task_state "$NAME_DELIV" 1
make_task_spec  "$NAME_DELIV" 1 1 "work-name-test"
NAME_TASK_STATE="${NAME_DELIV}/tasks/task-001/STATE.yml"

code=0
AID_STATE_FILE="${NAME_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Name --value "Custom Task Title" 2>/dev/null || code=$?
assert_exit_zero "$code" "23a: nested --field Name write -> exit 0"
assert_file_contains "$NAME_TASK_STATE" "display_name: 'Custom Task Title'" "23a: display_name key written (quoted -- value contains spaces)"
if grep -qE '^name:' "$NAME_TASK_STATE"; then
    fail "23a: a literal 'name:' key was written (must be mapped to display_name)"
else
    pass "23a: no literal 'name:' key present (fm_key indirection correct)"
fi
assert_file_contains "$NAME_TASK_STATE" "dispatch_log: []" "23a: unrelated sibling key survives the Name write"
assert_file_contains "$NAME_TASK_STATE" "state: Pending" "23a: other fields (state) untouched by the Name write"

# 23b: idempotency -- rewriting the same Name value leaves the file byte-identical
BEFORE=$(wc -c < "$NAME_TASK_STATE")
AID_STATE_FILE="${NAME_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Name --value "Custom Task Title" 2>/dev/null
AFTER=$(wc -c < "$NAME_TASK_STATE")
if [[ "$BEFORE" -eq "$AFTER" ]]; then
    pass "23b: nested Name write idempotent -- no size change on same value"
else
    fail "23b: nested Name write not idempotent -- size changed from $BEFORE to $AFTER"
fi

# 23c: unknown-field error message still lists Name in the allowed set
code=0
NAME_ERR_OUT=$(AID_STATE_FILE="${NAME_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Bogus --value "x" 2>&1) || code=$?
assert_exit_eq "$code" 4 "23c: unknown field still rejected (exit 4)"
assert_output_contains "$NAME_ERR_OUT" "Name" "23c: unknown-field error message lists Name in the allowed set"

# 23d/23e: FR-4b INVERSION -- Name values containing '|' or a newline now
# round-trip too (the reject guards were deleted script-wide, not just for Notes).
code=0
AID_STATE_FILE="${NAME_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Name --value "bad|value" 2>/dev/null || code=$?
assert_exit_zero "$code" "23d INVERTED: Name value containing '|' now accepted (exit 0)"
assert_file_contains "$NAME_TASK_STATE" "bad|value" "23d INVERTED: the pipe-bearing Name value round-trips intact"

code=0
AID_STATE_FILE="${NAME_WORK}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Name --value "$(printf 'line1\nline2')" 2>/dev/null || code=$?
assert_exit_zero "$code" "23e INVERTED: Name value containing a newline now accepted (exit 0)"
assert_file_contains "$NAME_TASK_STATE" 'display_name: "line1\nline2"' "23e INVERTED: the newline-bearing Name value round-trips (double-quoted, escaped)"

# 23f: flat layout -- Name write on the EXISTING flat fixture ($FLAT_STATE,
# from Unit 20) proves the write targets tasks_lifecycle.task-NNN.display_name
# alongside the existing state/review cells, with no cross-field clobbering.
code=0
AID_STATE_FILE="$FLAT_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --field Name --value "Custom Flat Title" 2>/dev/null || code=$?
assert_exit_zero "$code" "23f: flat --field Name write -> exit 0"
assert_file_contains "$FLAT_STATE" "display_name: 'Custom Flat Title'" "23f: display_name written under tasks_lifecycle.task-001"
assert_file_contains "$FLAT_STATE" "review: A" "23f: task-001's existing review cell (from Unit 20d) survives the Name write"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 24: AID_WORK_DIR-only caller reaches mode_append_issue's work-dir branch ==="

# WHY THIS UNIT EXISTS.
#
# mode_append_issue takes a work-dir-relative issues path when DELIVERY_ISSUES_DIR is
# still its default. That condition used to ALSO require AID_STATE_FILE to be set, which
# broke callers that export AID_WORK_DIR instead -- aid-execute's delivery gate is exactly
# such a caller -- and sent them at a `.aid/works/work` lock directory that does not exist.
#
# Nothing in this suite covered it before that fix. Line ~215 exports
# AID_DELIVERY_ISSUES_DIR for the WHOLE file, so DELIVERY_ISSUES_DIR is never the default
# in any other unit and that branch is unreachable from anywhere else here. Filename-
# independent (SP-7): unaffected by the STATE.md -> STATE.yml rename.
#
# Every call below therefore runs under `env -u` to clear the file-level exports. That is
# the point of the unit, not an incidental detail: with them set, these assertions pass
# vacuously against the wrong code path.

WD24="${TMPDIR_BASE}/wd24"
mkdir -p "$WD24"

# 24a: AID_WORK_DIR only -- no AID_STATE_FILE, no AID_DELIVERY_ISSUES_DIR.
code=0
env -u AID_STATE_FILE -u AID_DELIVERY_ISSUES_DIR AID_WORK_DIR="$WD24" \
    bash "$SCRIPT" --delivery-id 7 --append-issue \
    "| task-070 | [MEDIUM] | AID_WORK_DIR-only caller regression row | Open |" 2>/dev/null || code=$?
assert_exit_zero "$code" "24a: AID_WORK_DIR-only --append-issue -> exit 0 (no unbound-variable abort, no missing lock dir)"

# 24b: and it landed under AID_WORK_DIR, not under a literal `.aid/works/work`.
assert_file_exists "${WD24}/delivery-007-issues.md" \
    "24b: issues file resolved to AID_WORK_DIR/delivery-007-issues.md"
assert_file_contains "${WD24}/delivery-007-issues.md" "task-070" \
    "24b: the row was actually written"

# 24c: the literal default path must NOT have been created.
if [[ -e ".aid/works/work" ]]; then
    fail "24c: a literal .aid/works/work path was created -- the work-dir branch did not fire"
else
    pass "24c: no literal .aid/works/work path created"
fi

# 24d: idempotence holds on this path too (the branch must not bypass the dedup).
env -u AID_STATE_FILE -u AID_DELIVERY_ISSUES_DIR AID_WORK_DIR="$WD24" \
    bash "$SCRIPT" --delivery-id 7 --append-issue \
    "| task-070 | [MEDIUM] | AID_WORK_DIR-only caller regression row | Open |" 2>/dev/null
BEFORE24=$(grep -c 'task-070' "${WD24}/delivery-007-issues.md")
if [[ "$BEFORE24" -eq 1 ]]; then
    pass "24d: idempotent on the AID_WORK_DIR path -- duplicate row not added"
else
    fail "24d: duplicate written on the AID_WORK_DIR path -- row count is $BEFORE24, expected 1"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 25: --findings on the feature-001 flattened layout ==="

# On a flattened work there is NO per-task STATE.yml and no top-level
# quick_check key to nest a sequence under without exceeding the declared
# 3-level nesting cap (SPEC.md SS D-3). --findings on this layout therefore
# targets tasks_lifecycle.task-NNN.quick_check and stores the caller's BLOCK
# verbatim as ONE scalar (double-quoted, D-5 mode 3) -- KI-005 records this
# asymmetry (structured sequence on the full layout, one opaque scalar here)
# as a deliberate, tracked design gap, not a regression.

FLAT_F="${TMPDIR_BASE}/work-flat-findings"
make_flat_work_state "$FLAT_F"
make_flat_blueprint "$FLAT_F"
make_flat_task_spec "$FLAT_F" 1
make_flat_task_spec "$FLAT_F" 2
FLAT_F_STATE="${FLAT_F}/STATE.yml"

# 25a: first flat --findings write succeeds and creates the task-001 entry
FINDINGS_T1="- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] col1 tab-separated -- {a.sh:12} -- Deferred-to-gate"

code=0
AID_STATE_FILE="$FLAT_F_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_T1" 2>/dev/null || code=$?
assert_exit_zero "$code" "25a: flat --findings write -> exit 0 (no per-task STATE.yml required)"
assert_file_contains "$FLAT_F_STATE" "task-001:" "25a: tasks_lifecycle.task-001 entry created"
assert_file_contains "$FLAT_F_STATE" "quick_check:" "25a: quick_check scalar key written under task-001"
assert_file_contains "$FLAT_F_STATE" "Reviewer Tier" "25a: caller block content present verbatim (escaped scalar)"

# 25b: no per-task STATE.yml and no deliveries/ wrapper are conjured
if [[ ! -f "${FLAT_F}/tasks/task-001/STATE.yml" ]]; then
    pass "25b: no per-task STATE.yml created for the flat layout"
else
    fail "25b: a per-task STATE.yml was created -- flat layout must not use one"
fi
if [[ ! -d "${FLAT_F}/deliveries" ]]; then
    pass "25b: no deliveries/ directory created for the flat layout"
else
    fail "25b: a deliveries/ directory was created -- flat layout must not use one"
fi

# 25c: SIBLING PRESERVATION -- writing task-002's findings leaves task-001's
# quick_check entry byte-identical (each task owns its own mapping entry).
BLOCK_T1_BEFORE_25=$(awk '/^  task-001:/{f=1; print; next} f && !/^    /{exit} f{print}' "$FLAT_F_STATE")
FINDINGS_T2="- **Reviewer Tier:** Medium
- **Findings:** none"
code=0
AID_STATE_FILE="$FLAT_F_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 2 --findings "$FINDINGS_T2" 2>/dev/null || code=$?
assert_exit_zero "$code" "25c: second task's flat --findings write -> exit 0"
assert_file_contains "$FLAT_F_STATE" "task-002:" "25c: tasks_lifecycle.task-002 entry created"
BLOCK_T1_AFTER_25=$(awk '/^  task-001:/{f=1; print; next} f && !/^    /{exit} f{print}' "$FLAT_F_STATE")
if [[ "$BLOCK_T1_AFTER_25" == "$BLOCK_T1_BEFORE_25" ]]; then
    pass "25c: task-001's entry survived the task-002 write byte-identical (SIBLING PRESERVATION)"
else
    fail "25c: task-002's write clobbered task-001's entry -- before='$BLOCK_T1_BEFORE_25' after='$BLOCK_T1_AFTER_25'"
fi

# 25d: REPLACEMENT -- rewriting task-001's findings replaces only its own
# quick_check scalar; task-002's entry survives byte-identical.
BLOCK_T2_BEFORE_25=$(awk '/^  task-002:/{f=1; print; next} f && /^  [a-z]/{exit} f{print}' "$FLAT_F_STATE")
FINDINGS_T1B="- **Reviewer Tier:** Large
- **Findings:**
  - [CRITICAL] replaced block -- {b.sh:3} -- Fixed-on-spot"
code=0
AID_STATE_FILE="$FLAT_F_STATE" bash "$SCRIPT" --delivery-id 1 --task-id 1 --findings "$FINDINGS_T1B" 2>/dev/null || code=$?
assert_exit_zero "$code" "25d: rewriting task-001's findings -> exit 0"
assert_file_contains "$FLAT_F_STATE" "replaced block" "25d: task-001's new block written"
assert_file_not_contains "$FLAT_F_STATE" "col1 tab-separated" "25d: task-001's stale block content removed (replaced, not appended)"
BLOCK_T2_AFTER_25=$(awk '/^  task-002:/{f=1; print; next} f && /^  [a-z]/{exit} f{print}' "$FLAT_F_STATE")
if [[ "$BLOCK_T2_AFTER_25" == "$BLOCK_T2_BEFORE_25" ]]; then
    pass "25d: task-002's entry survived the task-001 rewrite byte-identical (SIBLING PRESERVATION)"
else
    fail "25d: task-001's rewrite clobbered task-002's entry -- before='$BLOCK_T2_BEFORE_25' after='$BLOCK_T2_AFTER_25'"
fi

# 25e: --delivery-id is not required -- the flat branch is reached before any
# delivery resolution (a layout with exactly one delivery never needs it).
code=0
AID_STATE_FILE="$FLAT_F_STATE" bash "$SCRIPT" --task-id 2 --findings "- **Reviewer Tier:** Small
- **Findings:** none" 2>/dev/null || code=$?
assert_exit_zero "$code" "25e: flat --findings without --delivery-id -> exit 0"

# 25f: octal footgun -- a zero-padded task-id containing 8/9 resolves base-10.
FLAT_F8="${TMPDIR_BASE}/work-flat-findings-octal"
make_flat_work_state "$FLAT_F8"
make_flat_blueprint "$FLAT_F8"
make_flat_task_spec "$FLAT_F8" 8
code=0
AID_STATE_FILE="${FLAT_F8}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id "008" --findings "- **Reviewer Tier:** Small
- **Findings:** none" 2>/dev/null || code=$?
assert_exit_zero "$code" "25f: flat --findings --task-id 008 -> exit 0 (no octal parse error)"
assert_file_contains "${FLAT_F8}/STATE.yml" "task-008:" "25f: entry keyed task-008 (not task-000)"

# 25g: nested-layout regression -- the FULL layout keeps writing the
# structured quick_check.reviewer_tier / quick_check.findings sequence in the
# task's OWN STATE.yml. Unaffected by the flat branch.
FLAT_SNAPSHOT_25G=$(cat "$FLAT_F_STATE")
code=0
AID_STATE_FILE="${WORK_DIR}/STATE.yml" bash "$SCRIPT" --delivery-id 1 --task-id 5 --findings "- **Reviewer Tier:** Small
- **Findings:**
  - [MEDIUM] nested-layout regression finding -- Deferred-to-gate" 2>/dev/null || code=$?
assert_exit_zero "$code" "25g: nested-layout --findings write still succeeds"
assert_file_contains "${DELIVERY_001}/tasks/task-005/STATE.yml" "reviewer_tier: Small" "25g: nested-layout findings still target the per-task STATE.yml, structured"
assert_file_contains "${DELIVERY_001}/tasks/task-005/STATE.yml" "nested-layout regression finding" "25g: nested-layout findings body written to the per-task STATE.yml"
assert_file_not_contains "${WORK_DIR}/STATE.yml" "nested-layout regression finding" "25g: nested-layout findings did NOT land in the work-root STATE.yml"
if [[ "$(cat "$FLAT_F_STATE")" == "$FLAT_SNAPSHOT_25G" ]]; then
    pass "25g: nested-layout write left the flat fixture byte-identical (no cross-layout leak)"
else
    fail "25g: nested-layout write modified the flat fixture STATE.yml"
fi

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
