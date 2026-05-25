#!/usr/bin/env bash
# test-lite-subpaths.sh — unit tests for the 4 lite-path sub-path state files
#
# Validates that the lite-path reference files:
#   - Exist with correct filenames
#   - Contain sub-path-specific prompt sets (question fields)
#   - Contain SPEC.md emission shapes for each sub-path
#   - Contain required sections and unit-testable decision tables
#   - state-condensed-intake.md covers all 4 sub-paths
#   - SKILL.md dispatch table routes to all L1–L4 states
#
# Usage:
#   test-lite-subpaths.sh [-v | --verbose]
#
# Test scenarios:
#   Unit 1: state-condensed-intake.md exists and is non-empty
#   Unit 2: LITE-BUG-FIX sub-path — prompt set (bug-title/description/reproduction/intended)
#   Unit 3: LITE-BUG-FIX sub-path — SPEC.md shape (Goal + Context + AC, no Specify-equivalent)
#   Unit 4: LITE-DOC sub-path — prompt set (doc-title/doc-purpose/outline-bullets)
#   Unit 5: LITE-DOC sub-path — SPEC.md shape (Goal + Context + Document Outline + AC)
#   Unit 6: LITE-REFACTOR sub-path — prompt set (scope/before-sketch/after-sketch/ac)
#   Unit 7: LITE-REFACTOR sub-path — SPEC.md shape (Goal + Context with before/after)
#   Unit 8: LITE-FEATURE sub-path — prompt set (feature-title/goal/scope/ac-1/ac-additional)
#   Unit 9: LITE-FEATURE sub-path — SPEC.md shape (Goal + Context + Given/when/then AC)
#   Unit 10: state-task-breakdown.md — exists, sub-path task-count guidance
#   Unit 11: state-task-breakdown.md — 6-section task-NNN.md shape + delivery-001 Source
#   Unit 12: state-task-breakdown.md — Execution Graph (Task Dependencies + Can Be Done In Parallel)
#   Unit 13: state-lite-review.md — exists, reviewer dispatch, grade check
#   Unit 14: state-lite-review.md — loopback paths to L1 and L2
#   Unit 15: state-lite-done.md — exists, SPEC.md Status=Ready, hand-off prompt
#   Unit 16: SKILL.md dispatch table — all 4 lite-path states present (L1/L2/L3/L4)
#   Unit 17: SKILL.md state detection — lite-path routing (Path=lite branches)
#   Unit 18: lite-spec-template.md — exists with required sections
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REFS_DIR="${SCRIPT_DIR}/../references"
SKILL_FILE="${SCRIPT_DIR}/../SKILL.md"
TEMPLATES_DIR="${SCRIPT_DIR}/../../../templates/specs"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
ERRORS=()

# ---------------------------------------------------------------------------
pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }

assert_file_exists() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        pass "$label"
    else
        fail "$label — file does not exist: $file"
    fi
}

assert_file_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label — pattern not found: '$pattern' in $file"
        [[ "$VERBOSE" -eq 1 ]] && echo "---FILE---" && cat "$file" 2>/dev/null && echo "---END---"
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

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: state-condensed-intake.md exists and covers all 4 sub-paths ==="

INTAKE="${REFS_DIR}/state-condensed-intake.md"
assert_file_exists "$INTAKE" "state-condensed-intake.md exists"
assert_file_contains "$INTAKE" "LITE-BUG-FIX" "intake: LITE-BUG-FIX sub-path present"
assert_file_contains "$INTAKE" "LITE-DOC" "intake: LITE-DOC sub-path present"
assert_file_contains "$INTAKE" "LITE-REFACTOR" "intake: LITE-REFACTOR sub-path present"
assert_file_contains "$INTAKE" "LITE-FEATURE" "intake: LITE-FEATURE sub-path present"
assert_file_contains "$INTAKE" "Unit-testable" "intake: Unit-testable cases section present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: LITE-BUG-FIX — prompt set ==="

assert_file_contains "$INTAKE" "bug-title" "BUG-FIX: bug-title question present"
assert_file_contains "$INTAKE" "bug-description" "BUG-FIX: bug-description question present"
assert_file_contains "$INTAKE" "reproduction-steps" "BUG-FIX: reproduction-steps question present"
assert_file_contains "$INTAKE" "intended-behavior" "BUG-FIX: intended-behavior question present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: LITE-BUG-FIX — SPEC.md shape ==="

assert_file_contains "$INTAKE" "reproduction + intended-behavior" "BUG-FIX: SPEC shape mentions reproduction + intended-behavior"
assert_file_contains "$INTAKE" "no Specify block" "BUG-FIX: SPEC shape notes no Specify block (AC shape)"
assert_file_contains "$INTAKE" "LITE-BUG-FIX" "BUG-FIX: Source field contains LITE-BUG-FIX"

# SPEC.md for BUG-FIX must NOT have 'Technical Specification' (no Specify-equivalent block)
assert_file_not_contains "$INTAKE" "## Technical Specification" "BUG-FIX: no Technical Specification block in shape"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: LITE-DOC — prompt set ==="

assert_file_contains "$INTAKE" "doc-title" "DOC: doc-title question present"
assert_file_contains "$INTAKE" "doc-purpose" "DOC: doc-purpose question present"
assert_file_contains "$INTAKE" "outline-bullets" "DOC: outline-bullets question present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: LITE-DOC — SPEC.md shape ==="

assert_file_contains "$INTAKE" "Document Outline" "DOC: SPEC shape has Document Outline section"
assert_file_contains "$INTAKE" "LITE-DOC" "DOC: Source field contains LITE-DOC"
# DOC SPEC emits single task of type DOCUMENT
assert_file_contains "$INTAKE" "DOCUMENT" "DOC: task type is DOCUMENT"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: LITE-REFACTOR — prompt set ==="

assert_file_contains "$INTAKE" "scope" "REFACTOR: scope question present"
assert_file_contains "$INTAKE" "before-sketch" "REFACTOR: before-sketch question present"
assert_file_contains "$INTAKE" "after-sketch" "REFACTOR: after-sketch question present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: LITE-REFACTOR — SPEC.md shape ==="

assert_file_contains "$INTAKE" "Before:" "REFACTOR: SPEC shape has Before: field"
assert_file_contains "$INTAKE" "After:" "REFACTOR: SPEC shape has After: field"
assert_file_contains "$INTAKE" "LITE-REFACTOR" "REFACTOR: Source field contains LITE-REFACTOR"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 8: LITE-FEATURE — prompt set ==="

assert_file_contains "$INTAKE" "feature-title" "FEATURE: feature-title question present"
assert_file_contains "$INTAKE" "ac-1" "FEATURE: ac-1 question present"
assert_file_contains "$INTAKE" "ac-additional" "FEATURE: ac-additional question present"
# FEATURE has extra AC elicitation vs REFACTOR
assert_file_contains "$INTAKE" "Given {precondition}" "FEATURE: Given/when/then AC elicitation present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: LITE-FEATURE — SPEC.md shape ==="

assert_file_contains "$INTAKE" "LITE-FEATURE" "FEATURE: Source field contains LITE-FEATURE"
# FEATURE emits explicit AC slots (Given/when/then per AC)
assert_file_contains "$INTAKE" "Given/when/then" "FEATURE: AC shape uses Given/when/then"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: state-task-breakdown.md — exists, sub-path task-count guidance ==="

BREAKDOWN="${REFS_DIR}/state-task-breakdown.md"
assert_file_exists "$BREAKDOWN" "state-task-breakdown.md exists"
assert_file_contains "$BREAKDOWN" "LITE-BUG-FIX" "breakdown: LITE-BUG-FIX task-count guidance"
assert_file_contains "$BREAKDOWN" "LITE-DOC" "breakdown: LITE-DOC task-count guidance"
assert_file_contains "$BREAKDOWN" "LITE-REFACTOR" "breakdown: LITE-REFACTOR task-count guidance"
assert_file_contains "$BREAKDOWN" "LITE-FEATURE" "breakdown: LITE-FEATURE task-count guidance"
assert_file_contains "$BREAKDOWN" "architect" "breakdown: architect agent dispatch mentioned"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 11: state-task-breakdown.md — 6-section task shape + delivery-001 Source ==="

assert_file_contains "$BREAKDOWN" "6-section flat" "breakdown: 6-section flat shape mentioned"
assert_file_contains "$BREAKDOWN" "delivery-001" "breakdown: delivery-001 Source convention"
# Source field uses work-NNN-name format
assert_file_contains "$BREAKDOWN" "{work-NNN-name} → delivery-001" "breakdown: Source field format correct"
# task template sections
assert_file_contains "$BREAKDOWN" "**Type:**" "breakdown: Type field in task shape"
assert_file_contains "$BREAKDOWN" "**Depends on:**" "breakdown: Depends on field in task shape"
assert_file_contains "$BREAKDOWN" "**Scope:**" "breakdown: Scope field in task shape"
assert_file_contains "$BREAKDOWN" "**Acceptance Criteria:**" "breakdown: Acceptance Criteria field in task shape"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 12: state-task-breakdown.md — Execution Graph ==="

assert_file_contains "$BREAKDOWN" "## Execution Graph" "breakdown: Execution Graph section present"
assert_file_contains "$BREAKDOWN" "Task Dependencies" "breakdown: Task Dependencies table present"
assert_file_contains "$BREAKDOWN" "Can Be Done In Parallel" "breakdown: parallel wave table present"
assert_file_contains "$BREAKDOWN" "Wave" "breakdown: Wave column in parallel table"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 13: state-lite-review.md — exists, reviewer dispatch, grade check ==="

REVIEW="${REFS_DIR}/state-lite-review.md"
assert_file_exists "$REVIEW" "state-lite-review.md exists"
assert_file_contains "$REVIEW" "reviewer" "review: reviewer agent dispatch mentioned"
assert_file_contains "$REVIEW" "grading-rubric.md" "review: grading rubric referenced"
assert_file_contains "$REVIEW" "Grade" "review: Grade field in output"
assert_file_contains "$REVIEW" "delivery-001" "review: delivery gate written to STATE.md"
assert_file_contains "$REVIEW" "## Delivery Gates" "review: writes to STATE.md ## Delivery Gates"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 14: state-lite-review.md — loopback paths ==="

assert_file_contains "$REVIEW" "CONDENSED-INTAKE" "review: loopback to CONDENSED-INTAKE (L1) path"
assert_file_contains "$REVIEW" "TASK-BREAKDOWN" "review: loopback to TASK-BREAKDOWN (L2) path"
assert_file_contains "$REVIEW" "Escalate" "review: escalation option present"
assert_file_contains "$REVIEW" "grade < minimum" "review: grade-below-minimum condition present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 15: state-lite-done.md — exists, SPEC.md Ready, hand-off ==="

DONE="${REFS_DIR}/state-lite-done.md"
assert_file_exists "$DONE" "state-lite-done.md exists"
assert_file_contains "$DONE" "Status:** Ready" "done: SPEC.md Status set to Ready"
assert_file_contains "$DONE" "/aid-execute" "done: hand-off to /aid-execute printed"
assert_file_contains "$DONE" "work-NNN-name" "done: work id included in hand-off command"
assert_file_contains "$DONE" "Terminal" "done: terminal state documented"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 16: SKILL.md dispatch table — all L1–L4 states present ==="

assert_file_contains "$SKILL_FILE" "state-condensed-intake.md" "SKILL: CONDENSED-INTAKE in dispatch table"
assert_file_contains "$SKILL_FILE" "state-task-breakdown.md" "SKILL: TASK-BREAKDOWN in dispatch table"
assert_file_contains "$SKILL_FILE" "state-lite-review.md" "SKILL: LITE-REVIEW in dispatch table"
assert_file_contains "$SKILL_FILE" "state-lite-done.md" "SKILL: LITE-DONE in dispatch table"
assert_file_contains "$SKILL_FILE" "CONDENSED-INTAKE" "SKILL: CONDENSED-INTAKE state listed"
assert_file_contains "$SKILL_FILE" "TASK-BREAKDOWN" "SKILL: TASK-BREAKDOWN state listed"
assert_file_contains "$SKILL_FILE" "LITE-REVIEW" "SKILL: LITE-REVIEW state listed"
assert_file_contains "$SKILL_FILE" "LITE-DONE" "SKILL: LITE-DONE state listed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 17: SKILL.md state detection — lite-path routing ==="

assert_file_contains "$SKILL_FILE" "**Path:** lite" "SKILL: lite-path routing branch in State Detection"
assert_file_contains "$SKILL_FILE" "State L1" "SKILL: State L1 in detection table"
assert_file_contains "$SKILL_FILE" "State L2" "SKILL: State L2 in detection table"
assert_file_contains "$SKILL_FILE" "State L3" "SKILL: State L3 in detection table"
assert_file_contains "$SKILL_FILE" "State L4" "SKILL: State L4 in detection table"
# Agents table mentions lite-path roles
assert_file_contains "$SKILL_FILE" "L1 CONDENSED-INTAKE" "SKILL: L1 in agents table"
assert_file_contains "$SKILL_FILE" "L2 TASK-BREAKDOWN" "SKILL: L2 in agents table"
assert_file_contains "$SKILL_FILE" "L3 LITE-REVIEW" "SKILL: L3 in agents table"
assert_file_contains "$SKILL_FILE" "L4 LITE-DONE" "SKILL: L4 in agents table"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: lite-spec-template.md exists with required sections ==="

LITE_TEMPLATE="${TEMPLATES_DIR}/lite-spec-template.md"
assert_file_exists "$LITE_TEMPLATE" "lite-spec-template.md exists"
assert_file_contains "$LITE_TEMPLATE" "## Goal" "template: ## Goal section present"
assert_file_contains "$LITE_TEMPLATE" "## Context" "template: ## Context section present"
assert_file_contains "$LITE_TEMPLATE" "## Acceptance Criteria" "template: ## Acceptance Criteria section present"
assert_file_contains "$LITE_TEMPLATE" "## Tasks" "template: ## Tasks section present"
assert_file_contains "$LITE_TEMPLATE" "## Execution Graph" "template: ## Execution Graph section present"
assert_file_contains "$LITE_TEMPLATE" "## Revision History" "template: ## Revision History section present"
assert_file_contains "$LITE_TEMPLATE" "delivery-001" "template: delivery-001 referenced"
assert_file_contains "$LITE_TEMPLATE" "lite path" "template: lite path provenance noted"

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
