#!/usr/bin/env bash
# test-shortcut-gate-halt-batching.sh -- task-012 (work-001-lite-aid-skills, feature-004):
# gate + halt + batching test for the shortcut engine's GATE/APPROVAL-HALT states.
#
# The shortcut engine (canonical/aid/templates/shortcut-engine.md) is agent-executed PROSE
# (a state-machine spec in markdown), NOT an executable script -- a deterministic canonical
# test cannot "run" it. This suite is therefore CONTRACT + FIXTURE-SHAPE:
#
#   1. Contract assertions -- grep the engine's GATE/APPROVAL-HALT prose (and feature-004's
#      SPEC.md, which the prose implements) for the load-bearing elements: minimum_grade
#      resolution via read-setting.sh, grade.sh driving the two named ledger scopes, the
#      REVIEW->GRADE->FIX loop + its circuit breaker, and the APPROVAL-HALT no-branch /
#      no-execution / Paused-Awaiting-Input / Specified halt contract.
#   2. Fixture-shape assertions -- a hand-authored flattened work fixture (representative
#      vehicle: /aid-fix, task-013) at the POST-GATE, POST-HALT state proves the halt
#      shape (no task past Pending, Delivery Lifecycle Specified, Pipeline Lifecycle
#      Paused-Awaiting-Input) and TWO ledger fixtures (one per pass) are driven through
#      grade.sh for real (the actual grading computation, not re-implemented here -- this
#      suite reuses grade.sh's own binary/behavior, not its unit tests, per feature-004's
#      Testing Strategy note "reusing the existing grade.sh unit tests for the computation
#      itself").
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-shortcut-gate-halt-batching.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="${REPO_ROOT}/canonical/aid/templates/shortcut-engine.md"
FEATURE_SPEC="${REPO_ROOT}/.aid/work-001-lite-aid-skills/features/feature-004-approval-and-grading-gates/SPEC.md"
GRADE="${REPO_ROOT}/canonical/aid/scripts/grade.sh"
READ_SETTING="${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh"

echo "=== Shortcut engine GATE + halt + batching (task-012, feature-004) ==="

assert_file_exists "$ENGINE" "SGH00a shortcut-engine.md exists"
# SGH00b: feature-004's SPEC.md is a DESIGN doc from work-001-lite-aid-skills,
# which was merged then cleaned up (removed in the eead245e housekeep). Its
# assertions (SGH06c/d/e below) validate that removed design fixture; the ACTUAL
# batching/GATE behavior is validated against the LIVE engine (SGH06a/b). So the
# SPEC is OPTIONAL: run its assertions only when the fixture is still present,
# skip them otherwise, rather than hard-failing on a legitimately-removed artifact.
HAVE_SPEC=0
if [[ -f "$FEATURE_SPEC" ]]; then
    HAVE_SPEC=1
else
    echo "  SKIP: SGH00b / SGH06c-e — feature-004 SPEC absent (work-001 merged + cleaned up); engine-contract assertions still run"
fi
assert_file_exists "$GRADE" "SGH00c grade.sh exists"
assert_file_exists "$READ_SETTING" "SGH00d read-setting.sh exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

ENGINE_TXT=$(cat "$ENGINE")
SPEC_TXT=""
[[ "$HAVE_SPEC" -eq 1 ]] && SPEC_TXT=$(cat "$FEATURE_SPEC")

# ===========================================================================
# Part 1 -- Contract assertions (prose)
# ===========================================================================
echo "--- Part 1: contract assertions ---"

# SGH-01: minimum_grade resolves via read-setting.sh, shortcut floor default A+.
assert_output_contains "$ENGINE_TXT" \
    "bash canonical/aid/scripts/config/read-setting.sh --skill {name} --key minimum_grade --default A+" \
    "SGH01 GATE resolves minimum_grade via read-setting.sh --skill {name} --key minimum_grade --default A+"

# SGH-02: the two named ledger scopes.
assert_output_contains "$ENGINE_TXT" \
    '.aid/.temp/review-pending/shortcut-{work}-defn.md' \
    "SGH02a Pass 1 ledger scope shortcut-{work}-defn.md named"
assert_output_contains "$ENGINE_TXT" \
    '.aid/.temp/review-pending/shortcut-{work}-tasks.md' \
    "SGH02b Pass 2 ledger scope shortcut-{work}-tasks.md named"

# SGH-03: grade.sh drives the computation.
assert_output_contains "$ENGINE_TXT" \
    "bash canonical/aid/scripts/grade.sh --explain <ledger-path>" \
    "SGH03 GATE drives grade.sh --explain over the ledger"

# SGH-04: the REVIEW -> GRADE -> FIX loop, bounded by a 3-cycle circuit breaker.
# (the circuit-breaker sentence wraps across two source lines in the prose -- matched as
# two adjacent-phrase assertions rather than one contiguous string, since grep -F matches
# within a single line only.)
assert_output_contains "$ENGINE_TXT" \
    "The Generic REVIEW -> GRADE -> FIX loop" \
    "SGH04a engine documents the Generic REVIEW -> GRADE -> FIX loop"
assert_output_contains "$ENGINE_TXT" \
    "Circuit breaker" \
    "SGH04b1 loop names a Circuit breaker"
assert_output_contains "$ENGINE_TXT" \
    "has not improved across 3" \
    "SGH04b2 circuit breaker keys off 3 cycles without improvement"
assert_output_contains "$ENGINE_TXT" \
    "consecutive cycles, STOP" \
    "SGH04b3 circuit breaker STOPs after 3 consecutive non-improving cycles"
assert_output_contains "$ENGINE_TXT" \
    'If the pass'"'"'s grade `>= {floor}` -> the pass clears' \
    "SGH04c pass clears only once grade >= {floor}"

# SGH-05: halt proof -- no branch, no execution, Paused-Awaiting-Input, Specified.
# (the "no branch / no task advances past Pending" sentence also wraps across two source
# lines -- same two-phrase treatment as SGH04b above.)
assert_output_contains "$ENGINE_TXT" \
    "no branch is created, no task executes" \
    "SGH05a APPROVAL-HALT: no branch is created, no task executes"
assert_output_contains "$ENGINE_TXT" \
    'No branch is created; no `### Tasks lifecycle` row' \
    "SGH05b1 halt-proof fixture claim: no Tasks lifecycle row (wrap point 1)"
assert_output_contains "$ENGINE_TXT" \
    'advances past `Pending`' \
    "SGH05b2 halt-proof fixture claim: ...advances past Pending (wrap point 2)"
assert_output_contains "$ENGINE_TXT" \
    'bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Paused-Awaiting-Input' \
    "SGH05c APPROVAL-HALT sets Pipeline Lifecycle: Paused-Awaiting-Input"
assert_output_contains "$ENGINE_TXT" \
    'is already `Specified`' \
    "SGH05d APPROVAL-HALT leaves Delivery Lifecycle State at Specified (not Executing)"

# SGH-06: batching -- exactly two passes, one dispatch per pass covering all its documents
# (not one-per-document); each document still clears the floor within its pass (AC-11).
assert_output_contains "$ENGINE_TXT" \
    "two batched Grading-Gate passes" \
    "SGH06a engine documents exactly two batched Grading-Gate passes"
assert_output_contains "$ENGINE_TXT" \
    'ARTIFACTS UNDER REVIEW:** `.aid/{work}/REQUIREMENTS.md`,' \
    "SGH06b Pass 1 reviews all 4 definition docs in ONE dispatch (not one-per-document)"
if [[ "$HAVE_SPEC" -eq 1 ]]; then
    assert_output_contains "$SPEC_TXT" \
        'batch into **two** dispatches, each one ledger' \
        "SGH06c feature-004 SPEC confirms exactly two dispatches, each one ledger"
    # (this sentence also wraps across two source lines -- same two-phrase treatment.)
    assert_output_contains "$SPEC_TXT" \
        "exactly two reviewer dispatches / two ledgers for a representative" \
        "SGH06d1 feature-004 Testing Strategy states the batching assertion (wrap point 1)"
    assert_output_contains "$SPEC_TXT" \
        "work (not one-per-document)" \
        "SGH06d2 feature-004 Testing Strategy states the batching assertion (wrap point 2)"
    assert_output_contains "$SPEC_TXT" \
        'Each document still clears `minimum_grade` via its own REVIEW->FIX loop within the pass' \
        "SGH06e batching changes dispatch granularity only -- per-document guarantee (AC-11) intact"
fi

# SGH-07: ledger-scope count in the engine prose is exactly 2, distinct (defn, tasks) --
# a mechanical cross-check that the prose never grows a third/per-document scope pattern.
LEDGER_SCOPES=$(echo "$ENGINE_TXT" | grep -oE '\.aid/\.temp/review-pending/shortcut-\{work\}-[a-z]+\.md' | sort -u)
LEDGER_SCOPE_COUNT=$(echo "$LEDGER_SCOPES" | grep -c . || true)
assert_eq "$LEDGER_SCOPE_COUNT" "2" "SGH07 exactly two distinct ledger-scope patterns named in the engine prose"

echo ""
echo "--- Part 2: fixture-shape assertions (representative vehicle: /aid-fix) ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ===========================================================================
# SGH-10..12: minimum_grade resolution -- actually invoke read-setting.sh the way GATE
# Step 1 does, in a project with no .aid/settings.yml (the shortcut path's own built-in
# default fires: A+, not the global A every other skill falls back to).
# ===========================================================================
PROJ="${TMP}/proj-no-settings"
mkdir -p "$PROJ"
FLOOR=$(cd "$PROJ" && bash "$READ_SETTING" --skill aid-fix --key minimum_grade --default A+)
assert_eq "$FLOOR" "A+" "SGH10 read-setting.sh --skill aid-fix --key minimum_grade --default A+ resolves A+ with no settings.yml"

# Per-skill override still wins (3-tier resolution; a project MAY lower the floor).
PROJ_OVR="${TMP}/proj-override"
mkdir -p "${PROJ_OVR}/.aid"
cat > "${PROJ_OVR}/.aid/settings.yml" <<'EOF'
aid-fix:
  minimum_grade: A
EOF
FLOOR_OVR=$(cd "$PROJ_OVR" && bash "$READ_SETTING" --skill aid-fix --key minimum_grade --default A+)
assert_eq "$FLOOR_OVR" "A" "SGH11 a per-skill override still resolves ahead of the shortcut's own A+ built-in default"

# ===========================================================================
# SGH-20..25: grade.sh drives the two named ledger scopes; the loop clears >= A+.
# ===========================================================================
WORK="work-099-fix-sample"
LEDGER_DIR="${TMP}/.aid/.temp/review-pending"
mkdir -p "$LEDGER_DIR"
DEFN_LEDGER="${LEDGER_DIR}/shortcut-${WORK}-defn.md"
TASKS_LEDGER="${LEDGER_DIR}/shortcut-${WORK}-tasks.md"

ledger_header() {
    printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n'
}

# Cycle 1: Pass 1 (defn) ledger starts clean -- both ledgers clear A+ on the first pass.
ledger_header > "$DEFN_LEDGER"
ledger_header > "$TASKS_LEDGER"
DEFN_GRADE=$(bash "$GRADE" "$DEFN_LEDGER")
TASKS_GRADE=$(bash "$GRADE" "$TASKS_LEDGER")
assert_eq "$DEFN_GRADE" "A+" "SGH20 Pass 1 (defn) ledger clears A+ (grade.sh over shortcut-${WORK}-defn.md)"
assert_eq "$TASKS_GRADE" "A+" "SGH21 Pass 2 (tasks) ledger clears A+ (grade.sh over shortcut-${WORK}-tasks.md)"

# Cycle N: a Pending [HIGH] finding drops the grade below the A+ floor -- REVIEW -> FIX
# loop does not advance to the next pass until it clears again.
{
    ledger_header
    printf '| 1 | [HIGH] | Pending | REQUIREMENTS.md | 12 | fabricated content standing in for *(pending)* | disk shows *(pending)* was never actually filled |\n'
} > "$DEFN_LEDGER"
DEFN_GRADE_CYCLE2=$(bash "$GRADE" "$DEFN_LEDGER")
if [[ "$DEFN_GRADE_CYCLE2" != "A+" ]]; then
    pass "SGH22 a Pending [HIGH] finding drops Pass 1 below the A+ floor (got ${DEFN_GRADE_CYCLE2}) -- FIX required, no advance to Pass 2"
else
    fail "SGH22 expected a below-floor grade with 1 Pending [HIGH], got ${DEFN_GRADE_CYCLE2}"
fi

# FIX cycle: the architect addresses the row; the fixer never sets Status itself -- the
# next clean-context REVIEW re-verifies and flips it to Fixed (reviewer-ledger-schema.md
# § Authoring rules for the fixer). Simulate that re-verified outcome directly.
{
    ledger_header
    printf '| 1 | [HIGH] | Fixed | REQUIREMENTS.md | 12 | fabricated content standing in for *(pending)* | re-verified cycle 2: disk now shows the genuine *(pending)* marker |\n'
} > "$DEFN_LEDGER"
DEFN_GRADE_CYCLE3=$(bash "$GRADE" "$DEFN_LEDGER")
assert_eq "$DEFN_GRADE_CYCLE3" "A+" "SGH23 Pass 1 clears A+ again once the Pending row is re-verified Fixed -- loop terminates, advances to Pass 2"

# ===========================================================================
# SGH-30..36: halt-proof fixture -- a flattened /aid-fix work at APPROVAL-HALT, both
# passes already cleared: no branch, no task past Pending, Paused-Awaiting-Input,
# Delivery Lifecycle Specified.
# ===========================================================================
WORK_DIR="${TMP}/.aid/${WORK}"
mkdir -p "${WORK_DIR}/tasks/task-001" "${WORK_DIR}/tasks/task-002"

cat > "${WORK_DIR}/STATE.md" <<'EOF'
# Work State -- work-099-fix-sample

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-fix
- **Updated:** 2026-07-08T12:00:00Z
- **Pause Reason:** GATE cleared; awaiting user approval before /aid-execute
- **Block Reason:** --
- **Block Artifact:** --

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-08 | Work created | -- | Initial scaffold by /aid-fix |
| 2026-07-08 | GATE Pass 1 (definition docs) cleared | A+ | /aid-fix GATE defn |
| 2026-07-08 | GATE Pass 2 (task set) cleared | A+ | /aid-fix GATE tasks |

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-08T12:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 | Pending | -- | -- | -- |
| task-002 | Pending | -- | -- | -- |
EOF

# No branch is ever created by this engine pre-Execute -- the flattened layout carries no
# deliveries/ wrapper and no Branch: field at this stage.
assert_dir_exists "$WORK_DIR" "SGH30 halt fixture: work folder exists"
if [[ -d "${WORK_DIR}/deliveries" ]]; then
    fail "SGH31 halt fixture: no deliveries/ (branch) wrapper exists pre-Execute"
else
    pass "SGH31 halt fixture: no deliveries/ (branch) wrapper exists pre-Execute"
fi
if grep -q '^- \*\*Branch:\*\*' "${WORK_DIR}/STATE.md"; then
    fail "SGH32 halt fixture: STATE.md carries no Branch: field pre-Execute"
else
    pass "SGH32 halt fixture: STATE.md carries no Branch: field pre-Execute"
fi

assert_file_contains "${WORK_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
    "SGH33 halt fixture: Pipeline Lifecycle is Paused-Awaiting-Input"
assert_file_contains "${WORK_DIR}/STATE.md" "**State:** Specified" \
    "SGH34 halt fixture: Delivery Lifecycle State is Specified (not Executing)"

# No ### Tasks lifecycle row advances past Pending.
NOT_PENDING=$(awk '
    /^### Tasks lifecycle/ { s=1; next }
    s && /^## / { s=0 }
    s && /^\| task-/ {
        n = split($0, f, "|")
        state = f[3]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
        if (state != "Pending") print state
    }
' "${WORK_DIR}/STATE.md" | grep -c . || true)
assert_eq "$NOT_PENDING" "0" "SGH35 halt fixture: every Tasks lifecycle row is Pending (none past it)"

# Exactly two GATE-pass rows recorded (batching proof, tied to the concrete fixture).
GATE_ROWS=$(grep -cE '^\| 2026-07-08 \| GATE Pass [12]' "${WORK_DIR}/STATE.md" || true)
assert_eq "$GATE_ROWS" "2" "SGH36 halt fixture: exactly two GATE-pass rows recorded (Pass 1 + Pass 2, not one-per-document)"

echo ""
test_summary
