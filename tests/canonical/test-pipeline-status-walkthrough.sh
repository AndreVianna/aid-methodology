#!/usr/bin/env bash
# test-pipeline-status-walkthrough.sh
#   M4+M5 behavior-preservation walk-through tests (feature-001 task-009).
#
#   Two complementary angles:
#     Part A: Lifecycle SM walk-through (simulate via writeback-state.sh --pipeline).
#     Part B: Wiring-level C4 static assertions (grep against canonical skill files).
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WRITEBACK="${REPO_ROOT}/canonical/aid/scripts/execute/writeback-state.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Scratch workspace -- trap-cleaned on exit.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Helper: create a minimal STATE.md with no ## Pipeline Status section.
# Also creates the required AID_LOCK_DIR alongside it.
make_state() {
    local dest="$1"
    mkdir -p "$(dirname "$dest")"
    cat > "$dest" <<'STATEEOF'
# Work State -- work-walkthrough-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | -- | -- | -- |

## Deploy Status

| Delivery | State | PR |
|----------|----|---|
| -- | -- | -- |
STATEEOF
}

# Helper: emit a single --pipeline field write.
# Sets AID_STATE_FILE and AID_LOCK_DIR to the directory of STATE.md.
pipeline_write() {
    local sf="$1" field="$2" val="$3"
    local lockdir
    lockdir="$(dirname "$sf")"
    AID_STATE_FILE="$sf" AID_LOCK_DIR="$lockdir" \
        bash "$WRITEBACK" --pipeline --field "$field" --value "$val" 2>/dev/null
}

# Helper: extract the leading YAML frontmatter block (between the opening and
# closing "---" fences) from a STATE.md.
#
# work-003-state-schema task-004 relocated every Pipeline State scalar
# (Lifecycle/Phase/Active Skill/Updated/Pause Reason/Block Reason/Block
# Artifact) from a "## Pipeline State" body bullet into this frontmatter block
# via writeback-state.sh's wb_set_frontmatter -- the body section is now a
# static enum-reference blockquote/comment that writeback-state.sh never
# touches (and, in this suite's make_state fixture, does not exist at all --
# the fixture only ships ## Tasks Status / ## Deploy Status). Every Part A
# assertion below reads this frontmatter block, not the body, to see the
# value a --pipeline write actually produced.
get_frontmatter_block() {
    local f="$1"
    awk 'NR==1 && /^---[ \t]*$/{in_fm=1; next} in_fm && /^---[ \t]*$/{exit} in_fm{print}' "$f"
}

# ===========================================================================
# PART A: Lifecycle State Machine walk-through (helper-level simulation)
# ===========================================================================

echo ""
echo "=== Part A: Lifecycle SM walk-through ==="

# ---------------------------------------------------------------------------
# A1: Full phase progression
#   Running/Describe -> Running/Define -> Running/Specify -> Running/Plan ->
#   Running/Detail -> Running/Execute
# (Faithful numbered pipeline ending at Execute -- Interview was split into
# Describe + Define; Deploy and the dead Monitor value are not phases and are
# not part of this walkthrough.)
#
# Assert Phase + Active Skill + Lifecycle: Running at each step;
# block stays well-formed throughout.
# ---------------------------------------------------------------------------
echo ""
echo "--- A1: Full phase progression ---"

A1_STATE="${TMPDIR_BASE}/a1/STATE.md"
make_state "$A1_STATE"

# Declare an ordered array of (Phase, Active Skill) pairs
A1_PHASES=("Describe" "Define" "Specify" "Plan" "Detail" "Execute")
A1_SKILLS=("aid-describe" "aid-define" "aid-specify" "aid-plan" "aid-detail" "aid-execute")

for i in "${!A1_PHASES[@]}"; do
    phase="${A1_PHASES[$i]}"
    skill="${A1_SKILLS[$i]}"

    pipeline_write "$A1_STATE" Lifecycle Running
    pipeline_write "$A1_STATE" Phase "$phase"
    pipeline_write "$A1_STATE" "Active Skill" "$skill"
    pipeline_write "$A1_STATE" Updated "2026-06-10T00:00:00Z"

    FM=$(get_frontmatter_block "$A1_STATE")

    assert_output_contains "$FM" "lifecycle: Running" \
        "A1 phase=$phase: Lifecycle=Running"
    assert_output_contains "$FM" "phase: ${phase}" \
        "A1 phase=$phase: Phase field correct"
    assert_output_contains "$FM" "active_skill: ${skill}" \
        "A1 phase=$phase: Active Skill correct"

    # Conditional fields are never removed (task-004: the key stays present so
    # the frontmatter shape is stable across every write) -- during Running
    # they must hold the "--" null sentinel, never a real reason/artifact.
    assert_output_contains "$FM" "pause_reason: --" \
        "A1 phase=$phase: Pause Reason sentinel during Running"
    assert_output_contains "$FM" "block_reason: --" \
        "A1 phase=$phase: Block Reason sentinel during Running"
    assert_output_contains "$FM" "block_artifact: --" \
        "A1 phase=$phase: Block Artifact sentinel during Running"

    # Each key appears exactly once (well-formed, no duplication)
    for fname in "lifecycle" "phase" "active_skill" "updated"; do
        count=$(echo "$FM" | grep -cE "^${fname}:" || true)
        if [[ "$count" -eq 1 ]]; then
            pass "A1 phase=$phase: frontmatter key '$fname' appears exactly once"
        else
            fail "A1 phase=$phase: frontmatter key '$fname' appears $count times (expected 1)"
        fi
    done

    # Tasks Status section must not be disturbed
    assert_file_contains "$A1_STATE" "## Tasks Status" \
        "A1 phase=$phase: Tasks Status section preserved"
done

# ---------------------------------------------------------------------------
# A2: Pause / resume walk-through
#   Running -> Paused-Awaiting-Input (+ Pause Reason) -> Running
#
# Assert Pause Reason present while paused; Lifecycle returns to Running
# and Pause Reason is CLEARED on resume.
# ---------------------------------------------------------------------------
echo ""
echo "--- A2: Pause/resume walk-through ---"

A2_STATE="${TMPDIR_BASE}/a2/STATE.md"
make_state "$A2_STATE"

# Seed: Running / Specify
pipeline_write "$A2_STATE" Lifecycle Running
pipeline_write "$A2_STATE" Phase Specify
pipeline_write "$A2_STATE" "Active Skill" aid-specify
pipeline_write "$A2_STATE" Updated "2026-06-10T01:00:00Z"

# Transition to Paused-Awaiting-Input (PAUSE-FOR-USER-ACTION at BLOCKED state)
pipeline_write "$A2_STATE" Lifecycle "Paused-Awaiting-Input"
pipeline_write "$A2_STATE" "Pause Reason" "Blocker pending -- awaiting loopback resolution before /aid-specify can continue"
pipeline_write "$A2_STATE" Updated "2026-06-10T01:01:00Z"

FM_PAUSED=$(get_frontmatter_block "$A2_STATE")
assert_output_contains "$FM_PAUSED" "lifecycle: Paused-Awaiting-Input" \
    "A2 pause: Lifecycle=Paused-Awaiting-Input"
# Real reason text (substring check -- the value is single-quoted in YAML
# because it contains spaces, so we match the text, not the key: prefix).
assert_output_contains "$FM_PAUSED" "Blocker pending -- awaiting loopback resolution before /aid-specify can continue" \
    "A2 pause: Pause Reason set to real text while paused"
assert_output_contains "$FM_PAUSED" "block_reason: --" \
    "A2 pause: Block Reason sentinel during Paused state"
assert_output_contains "$FM_PAUSED" "block_artifact: --" \
    "A2 pause: Block Artifact sentinel during Paused state"

# Resume: user re-invokes /aid-specify -- state-continue emits Running
pipeline_write "$A2_STATE" Lifecycle Running
pipeline_write "$A2_STATE" Phase Specify
pipeline_write "$A2_STATE" "Active Skill" aid-specify
pipeline_write "$A2_STATE" Updated "2026-06-10T01:02:00Z"

FM_RESUMED=$(get_frontmatter_block "$A2_STATE")
assert_output_contains "$FM_RESUMED" "lifecycle: Running" \
    "A2 resume: Lifecycle returns to Running"
assert_output_contains "$FM_RESUMED" "pause_reason: --" \
    "A2 resume: Pause Reason reset to the '--' sentinel on Running transition"
assert_output_contains "$FM_RESUMED" "block_reason: --" \
    "A2 resume: Block Reason sentinel after resume"

# lifecycle key appears exactly once after resume (no duplication)
count=$(get_frontmatter_block "$A2_STATE" | grep -cE "^lifecycle:" || true)
if [[ "$count" -eq 1 ]]; then
    pass "A2 resume: lifecycle key appears exactly once (no duplication)"
else
    fail "A2 resume: lifecycle key appears $count times (expected 1)"
fi

# ---------------------------------------------------------------------------
# A3: Block / resolve walk-through
#   Running -> Blocked (+ Block Reason + Block Artifact) -> Running
#
# Assert Block fields present while blocked; CLEARED on resolution.
# ---------------------------------------------------------------------------
echo ""
echo "--- A3: Block/resolve walk-through ---"

A3_STATE="${TMPDIR_BASE}/a3/STATE.md"
make_state "$A3_STATE"

# Seed: Running / Execute
pipeline_write "$A3_STATE" Lifecycle Running
pipeline_write "$A3_STATE" Phase Execute
pipeline_write "$A3_STATE" "Active Skill" aid-execute
pipeline_write "$A3_STATE" Updated "2026-06-10T02:00:00Z"

# IMPEDIMENT raised: task failed
AID_STATE_FILE="$A3_STATE" AID_LOCK_DIR="$(dirname "$A3_STATE")" bash "$WRITEBACK" \
    --task-id 1 --field Status --value "Failed" 2>/dev/null

pipeline_write "$A3_STATE" Lifecycle Blocked
pipeline_write "$A3_STATE" "Block Reason" "Task failed with unresolved impediment -- task-001"
pipeline_write "$A3_STATE" "Block Artifact" ".aid/work-test/IMPEDIMENT-task-001.md"
pipeline_write "$A3_STATE" Updated "2026-06-10T02:01:00Z"

FM_BLOCKED=$(get_frontmatter_block "$A3_STATE")
assert_output_contains "$FM_BLOCKED" "lifecycle: Blocked" \
    "A3 block: Lifecycle=Blocked"
assert_output_contains "$FM_BLOCKED" "Task failed with unresolved impediment" \
    "A3 block: Block Reason set to real text while blocked"
assert_output_contains "$FM_BLOCKED" "block_artifact: .aid/work-test/IMPEDIMENT-task-001.md" \
    "A3 block: Block Artifact present while blocked"
assert_output_contains "$FM_BLOCKED" "pause_reason: --" \
    "A3 block: Pause Reason sentinel while Blocked"

# Resolve: user fixes impediment, re-runs /aid-execute
pipeline_write "$A3_STATE" Lifecycle Running
pipeline_write "$A3_STATE" Phase Execute
pipeline_write "$A3_STATE" "Active Skill" aid-execute
pipeline_write "$A3_STATE" Updated "2026-06-10T02:02:00Z"

FM_RESOLVED=$(get_frontmatter_block "$A3_STATE")
assert_output_contains "$FM_RESOLVED" "lifecycle: Running" \
    "A3 resolve: Lifecycle returns to Running"
assert_output_contains "$FM_RESOLVED" "block_reason: --" \
    "A3 resolve: Block Reason reset to the '--' sentinel on Running transition"
assert_output_contains "$FM_RESOLVED" "block_artifact: --" \
    "A3 resolve: Block Artifact reset to the '--' sentinel on Running transition"
assert_output_contains "$FM_RESOLVED" "pause_reason: --" \
    "A3 resolve: Pause Reason sentinel after resolution"

# ---------------------------------------------------------------------------
# A4: Valid-only transitions -- assert helper rejects illegal lifecycle values
# (Helper validates enums; no illegal jump can silently land in the block.)
# ---------------------------------------------------------------------------
echo ""
echo "--- A4: Enum validation guards illegal lifecycle values ---"

A4_STATE="${TMPDIR_BASE}/a4/STATE.md"
make_state "$A4_STATE"
pipeline_write "$A4_STATE" Lifecycle Running

for bad_val in "running" "InProgress" "Paused" "blocked" "COMPLETED" "Unknown"; do
    code=0
    AID_STATE_FILE="$A4_STATE" AID_LOCK_DIR="$(dirname "$A4_STATE")" bash "$WRITEBACK" \
        --pipeline --field Lifecycle --value "$bad_val" 2>/dev/null || code=$?
    if [[ "$code" -ne 0 ]]; then
        pass "A4: illegal Lifecycle='$bad_val' rejected (exit $code)"
    else
        fail "A4: illegal Lifecycle='$bad_val' accepted -- helper did not guard the enum"
    fi
done

# Verify the frontmatter still holds the original Running value (rejected write did not corrupt)
assert_file_contains "$A4_STATE" "lifecycle: Running" \
    "A4: frontmatter intact after rejected illegal lifecycle writes"

# ---------------------------------------------------------------------------
# A5: Pause -> Block (cross-state conditional field clear)
#   Pause Reason cleared when transitioning from Paused to Blocked.
# ---------------------------------------------------------------------------
echo ""
echo "--- A5: Paused to Blocked clears Pause Reason ---"

A5_STATE="${TMPDIR_BASE}/a5/STATE.md"
make_state "$A5_STATE"
pipeline_write "$A5_STATE" Lifecycle Running
pipeline_write "$A5_STATE" Lifecycle "Paused-Awaiting-Input"
pipeline_write "$A5_STATE" "Pause Reason" "Awaiting interview re-run"
pipeline_write "$A5_STATE" Updated "2026-06-10T03:00:00Z"

assert_file_contains "$A5_STATE" "Awaiting interview re-run" \
    "A5 setup: Pause Reason set to real text before transition"

# Now transition to Blocked
pipeline_write "$A5_STATE" Lifecycle Blocked
pipeline_write "$A5_STATE" "Block Reason" "Delivery gate circuit breaker"
pipeline_write "$A5_STATE" "Block Artifact" ".aid/work-test/IMPEDIMENT-delivery-001.md"

assert_file_not_contains "$A5_STATE" "Awaiting interview re-run" \
    "A5: Pause Reason real text cleared when Lifecycle transitions to Blocked"
assert_file_contains "$A5_STATE" "pause_reason: --" \
    "A5: Pause Reason reset to the '--' sentinel when Lifecycle transitions to Blocked"
assert_file_contains "$A5_STATE" "Delivery gate circuit breaker" \
    "A5: Block Reason present after transition to Blocked"

# ===========================================================================
# PART B: Wiring-level C4 static assertions
# ===========================================================================

echo ""
echo "=== Part B: Wiring-level C4 static assertions ==="

# ---------------------------------------------------------------------------
# B1: M4 phase emits -- each of the 6 phase skills (aid-describe, aid-define, etc.) contains
# the correct Phase + Active Skill emit at its wired transition point.
# ---------------------------------------------------------------------------
echo ""
echo "--- B1: M4 phase emits present in canonical skill files ---"

# Map: skill-name => canonical state file that owns the M4 emit
declare -A M4_FILES
M4_FILES["aid-define"]="${REPO_ROOT}/canonical/skills/aid-define/references/state-feature-decomposition.md"
M4_FILES["aid-specify"]="${REPO_ROOT}/canonical/skills/aid-specify/references/state-initialize.md"
M4_FILES["aid-plan"]="${REPO_ROOT}/canonical/skills/aid-plan/references/first-run-loop.md"
M4_FILES["aid-detail"]="${REPO_ROOT}/canonical/skills/aid-detail/references/first-run.md"
M4_FILES["aid-execute"]="${REPO_ROOT}/canonical/skills/aid-execute/references/state-execute.md"

declare -A M4_PHASES
M4_PHASES["aid-define"]="Define"
M4_PHASES["aid-specify"]="Specify"
M4_PHASES["aid-plan"]="Plan"
M4_PHASES["aid-detail"]="Detail"
M4_PHASES["aid-execute"]="Execute"

for skill in "aid-define" "aid-specify" "aid-plan" "aid-detail" "aid-execute"; do
    sfile="${M4_FILES[$skill]}"
    expected_phase="${M4_PHASES[$skill]}"

    assert_file_exists "$sfile" \
        "B1 $skill: canonical state file exists"

    # The file must contain the --pipeline phase emit with correct Phase value
    if grep -qF "writeback-state.sh --pipeline --field Phase --value ${expected_phase}" "$sfile" 2>/dev/null; then
        pass "B1 $skill: --pipeline Phase=${expected_phase} emit present"
    else
        fail "B1 $skill: --pipeline Phase=${expected_phase} emit NOT found in $sfile"
    fi

    # The file must contain the Active Skill emit with the correct skill name
    if grep -qF "writeback-state.sh --pipeline --field \"Active Skill\" --value ${skill}" "$sfile" 2>/dev/null; then
        pass "B1 $skill: --pipeline Active Skill=${skill} emit present"
    else
        fail "B1 $skill: --pipeline Active Skill=${skill} emit NOT found in $sfile"
    fi

    # The file must contain the Lifecycle=Running emit
    if grep -qF "writeback-state.sh --pipeline --field Lifecycle --value Running" "$sfile" 2>/dev/null; then
        pass "B1 $skill: Lifecycle=Running emit present"
    else
        fail "B1 $skill: Lifecycle=Running emit NOT found in $sfile"
    fi
done

# ---------------------------------------------------------------------------
# B2: M5 pause emits -- state-machine-chaining.md PAUSE handler contains
# Paused-Awaiting-Input + Pause Reason emits.
# aid-specify state-blocked.md contains the per-skill pause emit.
# aid-execute state-delivery-gate.md (non-CODE stop) contains the pause emit.
# ---------------------------------------------------------------------------
echo ""
echo "--- B2: M5 pause emits present in canonical files ---"

CHAINING_FILE="${REPO_ROOT}/canonical/aid/templates/state-machine-chaining.md"
SPECIFY_BLOCKED="${REPO_ROOT}/canonical/skills/aid-specify/references/state-blocked.md"
DELIVERY_GATE="${REPO_ROOT}/canonical/skills/aid-execute/references/state-delivery-gate.md"

# state-machine-chaining.md: shared PAUSE handler
assert_file_exists "$CHAINING_FILE" \
    "B2: state-machine-chaining.md exists"
if grep -qF 'writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"' "$CHAINING_FILE" 2>/dev/null; then
    pass "B2 chaining: Paused-Awaiting-Input emit in PAUSE handler"
else
    fail "B2 chaining: Paused-Awaiting-Input emit NOT found in state-machine-chaining.md"
fi
if grep -qF 'writeback-state.sh --pipeline --field "Pause Reason"' "$CHAINING_FILE" 2>/dev/null; then
    pass "B2 chaining: Pause Reason emit in PAUSE handler"
else
    fail "B2 chaining: Pause Reason emit NOT found in state-machine-chaining.md"
fi

# aid-specify/state-blocked.md: per-skill pause emit
assert_file_exists "$SPECIFY_BLOCKED" \
    "B2: aid-specify/state-blocked.md exists"
if grep -qF 'writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"' "$SPECIFY_BLOCKED" 2>/dev/null; then
    pass "B2 aid-specify/state-blocked: Paused-Awaiting-Input emit present"
else
    fail "B2 aid-specify/state-blocked: Paused-Awaiting-Input emit NOT found"
fi
if grep -qF 'writeback-state.sh --pipeline --field "Pause Reason"' "$SPECIFY_BLOCKED" 2>/dev/null; then
    pass "B2 aid-specify/state-blocked: Pause Reason emit present"
else
    fail "B2 aid-specify/state-blocked: Pause Reason emit NOT found"
fi

# state-delivery-gate.md: non-CODE stop -> Paused-Awaiting-Input
assert_file_exists "$DELIVERY_GATE" \
    "B2: state-delivery-gate.md exists"
if grep -qF 'writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"' "$DELIVERY_GATE" 2>/dev/null; then
    pass "B2 delivery-gate: non-CODE stop Paused-Awaiting-Input emit present"
else
    fail "B2 delivery-gate: non-CODE stop Paused-Awaiting-Input emit NOT found"
fi
if grep -qF '"Delivery gate blocked on non-CODE issues' "$DELIVERY_GATE" 2>/dev/null; then
    pass "B2 delivery-gate: Pause Reason message contains expected non-CODE text"
else
    fail "B2 delivery-gate: Pause Reason message text NOT found in state-delivery-gate.md"
fi

# ---------------------------------------------------------------------------
# B3: M5 block emits -- Blocked + Block Reason + Block Artifact at the three
# aid-execute block points: IMPEDIMENT path, review CRITICAL path, and the
# delivery-gate circuit-breaker.
# ---------------------------------------------------------------------------
echo ""
echo "--- B3: M5 block emits present in aid-execute canonical files ---"

STATE_EXECUTE="${REPO_ROOT}/canonical/skills/aid-execute/references/state-execute.md"
STATE_REVIEW="${REPO_ROOT}/canonical/skills/aid-execute/references/state-review.md"

# state-execute.md: IMPEDIMENT / Failed task block
assert_file_exists "$STATE_EXECUTE" \
    "B3: state-execute.md exists"
if grep -qF "writeback-state.sh --pipeline --field Lifecycle --value Blocked" "$STATE_EXECUTE" 2>/dev/null; then
    pass "B3 state-execute: Blocked emit present (impediment path)"
else
    fail "B3 state-execute: Blocked emit NOT found (impediment path)"
fi
if grep -qF '"Task failed with unresolved impediment' "$STATE_EXECUTE" 2>/dev/null; then
    pass "B3 state-execute: Block Reason message present (impediment path)"
else
    fail "B3 state-execute: Block Reason message NOT found in state-execute.md"
fi
if grep -qF 'writeback-state.sh --pipeline --field "Block Artifact"' "$STATE_EXECUTE" 2>/dev/null; then
    pass "B3 state-execute: Block Artifact emit present (impediment path)"
else
    fail "B3 state-execute: Block Artifact emit NOT found in state-execute.md"
fi

# state-review.md: CRITICAL-persists block (review path)
assert_file_exists "$STATE_REVIEW" \
    "B3: state-review.md exists"
if grep -qF "writeback-state.sh --pipeline --field Lifecycle --value Blocked" "$STATE_REVIEW" 2>/dev/null; then
    pass "B3 state-review: Blocked emit present (critical-persists path)"
else
    fail "B3 state-review: Blocked emit NOT found (critical-persists path)"
fi
if grep -qF '"Critical finding persists after fix attempt' "$STATE_REVIEW" 2>/dev/null; then
    pass "B3 state-review: Block Reason message present (critical-persists path)"
else
    fail "B3 state-review: Block Reason message NOT found in state-review.md"
fi

# state-delivery-gate.md: circuit-breaker block
if grep -qF "writeback-state.sh --pipeline --field Lifecycle --value Blocked" "$DELIVERY_GATE" 2>/dev/null; then
    pass "B3 delivery-gate: Blocked emit present (circuit-breaker path)"
else
    fail "B3 delivery-gate: Blocked emit NOT found (circuit-breaker path)"
fi
if grep -qF '"Delivery gate circuit breaker triggered' "$DELIVERY_GATE" 2>/dev/null; then
    pass "B3 delivery-gate: Block Reason message present (circuit-breaker path)"
else
    fail "B3 delivery-gate: Block Reason message NOT found in state-delivery-gate.md"
fi
if grep -qF 'writeback-state.sh --pipeline --field "Block Artifact"' "$DELIVERY_GATE" 2>/dev/null; then
    pass "B3 delivery-gate: Block Artifact emit present (circuit-breaker path)"
else
    fail "B3 delivery-gate: Block Artifact emit NOT found in state-delivery-gate.md"
fi

# ---------------------------------------------------------------------------
# B4: C4 silence -- emit blocks are annotated as silent; no new Print: inside
# the emit block itself; pause/resume message + resume-command instructions
# still surround the emit (additive, not a replacement).
#
# This is the behavioral-preservation guard: any new prompt/gate introduced
# INSIDE an emit block will appear as a "Print:" directive adjacent to the
# emit commands; that would be the CRITICAL-class C4 violation this test
# exists to catch.
# ---------------------------------------------------------------------------
echo ""
echo "--- B4: C4 silence -- emit blocks are annotated silent, no new Print: ---"

# List of all files that contain --pipeline emits
ALL_EMIT_FILES=(
    "${CHAINING_FILE}"
    "${SPECIFY_BLOCKED}"
    "${REPO_ROOT}/canonical/skills/aid-specify/references/state-initialize.md"
    "${REPO_ROOT}/canonical/skills/aid-specify/references/state-continue.md"
    "${REPO_ROOT}/canonical/skills/aid-plan/references/first-run-loop.md"
    "${REPO_ROOT}/canonical/skills/aid-detail/references/first-run.md"
    "${STATE_EXECUTE}"
    "${STATE_REVIEW}"
    "${DELIVERY_GATE}"
    "${REPO_ROOT}/canonical/skills/aid-deploy/references/state-idle.md"
    "${REPO_ROOT}/canonical/skills/aid-define/references/state-feature-decomposition.md"
    "${REPO_ROOT}/canonical/skills/aid-describe/references/state-completion.md"
)

for ef in "${ALL_EMIT_FILES[@]}"; do
    [[ -f "$ef" ]] || continue
    bname="$(basename "$ef")"

    # B4a: Every emit block must carry a "silent state-write" or "no output, no gate" annotation.
    # The annotation is always on the line immediately before or within 2 lines of the first
    # --pipeline emit in each emit block. We check that the file contains the canonical annotation.
    if grep -qF "silent state-write" "$ef" 2>/dev/null || \
       grep -qF "no output, no gate" "$ef" 2>/dev/null; then
        pass "B4a $bname: silent-write annotation present"
    else
        fail "B4a $bname: silent-write annotation NOT found -- emit block may be missing the C4 silence marker"
    fi

    # B4b: No standalone "Print:" directive exists within the boundaries of any --pipeline emit block.
    # Strategy: extract each line that is within 3 lines AFTER a --pipeline emit line and assert it
    # does not contain "Print:" as a standalone directive. We use awk to scan: within a emit group
    # (lines from a writeback --pipeline call until a blank line or non-writeback line), no "Print:"
    # should appear. We check a simpler invariant: every "Print:" line in the file must be outside
    # any emit block by asserting that no line in the file has both "--pipeline" AND "Print:" on it.
    if grep -qF "--pipeline" "$ef" 2>/dev/null && \
       grep -qF "Print:" "$ef" 2>/dev/null; then
        # There is both --pipeline and Print: in this file -- verify they don't co-occur on the same line.
        cooccurrence=$(grep -nF "Print:" "$ef" | grep -F -- "--pipeline" || true)
        if [[ -z "$cooccurrence" ]]; then
            pass "B4b $bname: no Print: on same line as --pipeline emit"
        else
            fail "B4b $bname: CRITICAL -- Print: and --pipeline on same line: $cooccurrence"
        fi
        # Additionally, use awk to confirm no Print: appears in the body of a emit block
        # (between the first and last writeback --pipeline line in any contiguous group)
        print_in_block=$(awk '
            /writeback-state\.sh --pipeline/ { in_block=1 }
            in_block && /^[[:space:]]*$/ { in_block=0 }
            in_block && /Print:/ { print NR": "$0 }
        ' "$ef" || true)
        if [[ -z "$print_in_block" ]]; then
            pass "B4b $bname: no Print: directive inside any --pipeline emit block"
        else
            fail "B4b $bname: CRITICAL -- Print: found inside --pipeline emit block: $print_in_block"
        fi
    else
        pass "B4b $bname: no co-occurrence of --pipeline and Print: (safe)"
    fi
done

# B4c: Pause instructions still present surrounding the PAUSE handler emit.
# Assert that state-machine-chaining.md still says "print the pause reason" and
# "resume command" AFTER the emit block (the emit is ADDITIVE, not a replacement).
if grep -qF "print the pause reason" "$CHAINING_FILE" 2>/dev/null || \
   grep -qF "Then print the pause reason" "$CHAINING_FILE" 2>/dev/null; then
    pass "B4c chaining: pause-reason print instruction still present after emit"
else
    fail "B4c chaining: pause-reason print instruction MISSING -- emit may have replaced it (C4 violation)"
fi
if grep -qF "resume command" "$CHAINING_FILE" 2>/dev/null; then
    pass "B4c chaining: resume-command instruction still present after emit"
else
    fail "B4c chaining: resume-command instruction MISSING -- emit may have replaced it (C4 violation)"
fi

# B4d: aid-specify/state-blocked.md still has the PAUSE-FOR-USER-ACTION Advance line
# (the pause instruction is still there; the emit is additive).
if grep -qF "PAUSE-FOR-USER-ACTION" "$SPECIFY_BLOCKED" 2>/dev/null; then
    pass "B4d state-blocked: PAUSE-FOR-USER-ACTION advance instruction still present (additive)"
else
    fail "B4d state-blocked: PAUSE-FOR-USER-ACTION advance instruction MISSING -- emit may have replaced it"
fi

# B4e: aid-execute/state-execute.md still has the impediment-write instruction
# AND the failure-emit instruction (emit is additive, not a replacement).
if grep -qF "IMPEDIMENT" "$STATE_EXECUTE" 2>/dev/null || \
   grep -qF "Emit" "$STATE_EXECUTE" 2>/dev/null; then
    pass "B4e state-execute: impediment/failure instructions still present alongside emit (additive)"
else
    fail "B4e state-execute: impediment/failure instructions MISSING -- emit may have replaced them"
fi

# B4f: state-delivery-gate.md still has its non-CODE stop user-facing instructions
# (presents what needs to change and where) BEFORE the emit.
if grep -qF "STOP" "$DELIVERY_GATE" 2>/dev/null; then
    pass "B4f delivery-gate: STOP instruction still present alongside pause emit (additive)"
else
    fail "B4f delivery-gate: STOP instruction MISSING -- emit may have replaced user-facing gate instruction"
fi

# B4g: Negative test -- verify these assertions would FAIL if a new Print: were
# introduced inside an emit block. We synthesize a scratch file with a Print:
# inside an emit block and confirm our awk detector fires.
echo ""
echo "--- B4g: Self-test of the silence guard (confirms it is not hollow) ---"

SYNTH_FILE="${TMPDIR_BASE}/synth-with-print-in-emit.md"
cat > "$SYNTH_FILE" <<'SYNTHEOF'
# Synthetic test file

Before the emit:

Emit pipeline phase (silent state-write -- no output, no gate):
```
bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
Print: [Step X] Starting phase
bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify
```

After the emit.
SYNTHEOF

# Our awk detector must find the Print: inside the emit block
synth_detect=$(awk '
    /writeback-state\.sh --pipeline/ { in_block=1 }
    in_block && /^[[:space:]]*$/ { in_block=0 }
    in_block && /Print:/ { print NR": "$0 }
' "$SYNTH_FILE" || true)

if [[ -n "$synth_detect" ]]; then
    pass "B4g self-test: awk detector correctly fires on Print: inside emit block (not hollow)"
else
    fail "B4g self-test: awk detector FAILED to catch Print: inside emit block -- guard is hollow"
fi

# Verify the detector does NOT fire on a Print: OUTSIDE the emit block
SYNTH_SAFE="${TMPDIR_BASE}/synth-print-outside-emit.md"
cat > "$SYNTH_SAFE" <<'SYNTHSAFEEOF'
# Synthetic safe file

Print: this line is outside the emit block.

Emit pipeline phase (silent state-write -- no output, no gate):
```
bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
```

Print: this line is also outside the emit block.
SYNTHSAFEEOF

synth_safe_detect=$(awk '
    /writeback-state\.sh --pipeline/ { in_block=1 }
    in_block && /^[[:space:]]*$/ { in_block=0 }
    in_block && /Print:/ { print NR": "$0 }
' "$SYNTH_SAFE" || true)

if [[ -z "$synth_safe_detect" ]]; then
    pass "B4g self-test: awk detector correctly passes when Print: is outside emit block"
else
    fail "B4g self-test: awk detector falsely fires on Print: outside emit block"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
