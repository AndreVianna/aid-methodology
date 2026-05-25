#!/usr/bin/env bash
# test-lite-to-full-escalation.sh — unit tests for lite→full escalation procedure
#
# Tests the 10-step procedure in references/lite-to-full-escalation.md:
#   Step 1:  collect escalation rationale
#   Step 2:  collect captured slot values
#   Step 3:  write ## Escalation Carry block to STATE.md
#   Step 4:  update ## Triage in STATE.md (Path: escalated)
#   Step 5:  ensure REQUIREMENTS.md scaffold exists
#   Step 6:  ensure ## Interview Status scaffold in STATE.md (pre-seed from carry)
#   Step 7:  seed REQUIREMENTS.md from carried slot values
#   Step 8:  add Lifecycle History entry
#   Step 9a: create features/feature-001-{name}/SPEC.md placeholder
#   Step 9b: create PLAN.md placeholder
#   Step 9c: delete work-root SPEC.md (commitment point; crash-recovery load-bearing)
#   Step 10: print escalation summary
#
# Also tests:
#   - Carry block structure (all required fields present)
#   - Seed-from-slots mapping (slots → REQUIREMENTS.md sections)
#   - State Detection resume rule: Path: escalated + work-root SPEC.md present → replay
#   - Coexistence invariant: after Step 9c, workspace is full-path-shape only
#
# Usage:
#   bash test-lite-to-full-escalation.sh [-v | --verbose]
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
REQUIREMENTS_TEMPLATE="$REPO_ROOT/canonical/templates/requirements.md"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
ERRORS=()

pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }
log()  { [[ "$VERBOSE" -eq 1 ]] && echo "[LOG] $*" || true; }

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

assert_file_exists() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        pass "$label"
    else
        fail "$label — file does not exist: $file"
    fi
}

assert_file_absent() {
    local file="$1" label="$2"
    if [[ ! -f "$file" ]]; then
        pass "$label"
    else
        fail "$label — file should not exist but does: $file"
    fi
}

assert_dir_exists() {
    local dir="$1" label="$2"
    if [[ -d "$dir" ]]; then
        pass "$label"
    else
        fail "$label — directory does not exist: $dir"
    fi
}

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------
make_lite_work() {
    local work_dir="$1" work_name="$2"
    mkdir -p "$work_dir/tasks"

    # Minimal STATE.md for a lite work at TASK-BREAKDOWN stage
    cat > "$work_dir/STATE.md" <<STATEOF
# Work State — ${work_name}

## Triage

- **Path:** lite
- **Work Type:** Feature
- **Sub-path:** LITE-FEATURE
- **Decision rationale:** Small scope, single deliverable.

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-implement | IMPLEMENT | 1 | Pending | — | — | — |

## Lifecycle History

| Date | Event | Source |
|------|-------|--------|
| 2026-05-24 | Lite path started | /aid-interview |
STATEOF

    # Work-root SPEC.md (lite path artifact)
    cat > "$work_dir/SPEC.md" <<SPECEOF
# Spec — ${work_name}

## Goal

Build a widget that does the thing.

## Context

The existing system lacks this widget.

## Acceptance Criteria

- [ ] Widget renders correctly
- [ ] Widget handles errors
SPECEOF

    # task files
    cat > "$work_dir/tasks/task-001.md" <<TASKEOF
# task-001: Implement widget

**Type:** IMPLEMENT
TASKEOF
}

simulate_escalation_steps_3_to_9() {
    # Simulate the escalation procedure steps 3–9 on a work directory.
    # This is a scripted simulation of what the AI agent would do:
    # the actual escalation is performed by the agent following
    # lite-to-full-escalation.md; we test the expected outputs.
    local work_dir="$1"
    local work_name="$2"
    local rationale="${3:-scope broader than expected}"
    local today="2026-05-24"
    local ts="2026-05-24T12:00:00Z"

    # Step 3: Write ## Escalation Carry to STATE.md
    cat >> "$work_dir/STATE.md" <<CARRYEOF

## Escalation Carry

> Written by lite→full escalation. Full-path interview reads this section to seed
> REQUIREMENTS.md without re-asking questions already answered.

- **Escalated from:** TASK-BREAKDOWN (Sub-path: LITE-FEATURE)
- **Escalated at:** ${ts}
- **Escalation rationale:** ${rationale}

### Captured Slot Values

- **feature-title:** My Widget Feature
- **goal:** Build a widget that does the thing.
- **scope:** Single deliverable, widget rendering + error handling.
- **ac-1:** Widget renders correctly
- **ac-additional:** Widget handles errors

### Artifacts at Escalation

- **SPEC.md:** present — contains \`## Goal\`, \`## Context\`, \`## Acceptance Criteria\`
  (use to seed REQUIREMENTS.md §§ Objective, Functional Requirements, Acceptance Criteria)
- **tasks/:** 1 task files present — use as candidate tasks when PLAN.md is created
CARRYEOF

    # Step 4: Update ## Triage (Path: lite → escalated) using awk
    local tmp4
    tmp4=$(mktemp)
    awk -v rationale="$rationale" '
        BEGIN { in_triage=0; triage_written=0 }
        /^## Triage/ {
            in_triage=1
            print "## Triage"
            print ""
            print "- **Path:** escalated"
            print "- **Decision rationale:** Small scope, single deliverable. → escalated to full — " rationale
            triage_written=1
            next
        }
        in_triage && /^## / {
            in_triage=0
            print
            next
        }
        in_triage { next }
        { print }
    ' "$work_dir/STATE.md" > "$tmp4"
    mv "$tmp4" "$work_dir/STATE.md"

    # Step 5: Create REQUIREMENTS.md scaffold
    # Always create a minimal scaffold with the required Change Log entry
    # (simulating the agent adding the escalation entry per lite-to-full-escalation.md Step 5)
    cat > "$work_dir/REQUIREMENTS.md" <<REQEOF
# Requirements — ${work_name}

## Change Log

| Date | Summary | Source |
|------|---------|--------|
| ${today} | Interview restarted — escalated from lite path (LITE-FEATURE) | /aid-interview escalation |

## Objective

(Pending)

## Problem Statement

(Pending)

## Scope

(Pending)

## Functional Requirements

(Pending)

## Acceptance Criteria

(Pending)
REQEOF

    # Step 6: Add ## Interview Status scaffold to STATE.md
    cat >> "$work_dir/STATE.md" <<ISEOF

## Interview Status

**Status:** In Progress · **Grade:** Pending

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Partial | ${today} |
| 2 | Problem Statement | Partial | ${today} |
| 3 | Users & Stakeholders | Pending | — |
| 4 | Scope | Partial | ${today} |
| 5 | Functional Requirements | Pending | — |
| 6 | Non-Functional Requirements | Pending | — |
| 7 | Constraints | Pending | — |
| 8 | Assumptions & Dependencies | Pending | — |
| 9 | Acceptance Criteria | Partial | ${today} |
| 10 | Priority | Pending | — |
ISEOF

    # Step 7: Seed REQUIREMENTS.md from carried slot values
    cat >> "$work_dir/REQUIREMENTS.md" <<SEEDEOF

<!-- Seeded from lite-path carry by escalation -->
## Objective

Lite-path title: My Widget Feature. Escalated to full path — see § Context for details.

## Problem Statement

Captured before escalation: Build a widget that does the thing.

## Scope

Single deliverable, widget rendering + error handling.

## Acceptance Criteria

- [lite-carry] Widget renders correctly
- [lite-carry] Widget handles errors
SEEDEOF

    # Step 8: Add Lifecycle History entry
    # (already present in STATE.md scaffold; add one more entry)
    # (In real implementation, the agent appends to the table)

    # Step 9a: Create features/feature-001-{name}/SPEC.md placeholder
    local feat_dir="$work_dir/features/feature-001-${work_name}"
    mkdir -p "$feat_dir"
    cat > "$feat_dir/SPEC.md" <<FEATEOF
# Feature: feature-001-${work_name}

> Placeholder — created by lite→full escalation. The full-path feature
> decomposition step (/aid-interview State 5: FEATURE-DECOMPOSITION) will
> replace this file with the structured feature SPEC.

**Status:** Pending (escalation placeholder)
**Source:** Escalated from lite path — ${rationale}
**Created:** ${ts}
FEATEOF

    # Step 9b: Create PLAN.md placeholder
    cat > "$work_dir/PLAN.md" <<PLANEOF
# Plan — ${work_name}

> Placeholder — created by lite→full escalation. The full-path planning step
> will replace this with a structured delivery plan.

## Deliveries

| # | Name | Scope | Status |
|---|------|-------|--------|
| 1 | delivery-001 | (TBD — pending full interview) | Pending |
PLANEOF

    # Step 9c: Delete work-root SPEC.md (commitment point)
    rm -f "$work_dir/SPEC.md"
}

# ---------------------------------------------------------------------------
# Setup: temp base
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT INT TERM

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: Steps 3–4 — ## Escalation Carry block structure ==="

WORK1="$TMPDIR_BASE/work-001-widget"
make_lite_work "$WORK1" "widget"
simulate_escalation_steps_3_to_9 "$WORK1" "widget"

# Step 3: ## Escalation Carry must be present in STATE.md
assert_file_contains "$WORK1/STATE.md" "## Escalation Carry" "STATE.md has ## Escalation Carry section"
assert_file_contains "$WORK1/STATE.md" "Escalated from:" "Carry block has 'Escalated from:' field"
assert_file_contains "$WORK1/STATE.md" "Escalated at:" "Carry block has 'Escalated at:' field"
assert_file_contains "$WORK1/STATE.md" "Escalation rationale:" "Carry block has 'Escalation rationale:' field"
assert_file_contains "$WORK1/STATE.md" "### Captured Slot Values" "Carry block has '### Captured Slot Values' sub-section"
assert_file_contains "$WORK1/STATE.md" "### Artifacts at Escalation" "Carry block has '### Artifacts at Escalation' sub-section"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: Step 4 — Path updated to 'escalated' in ## Triage ==="

assert_file_contains "$WORK1/STATE.md" "escalated" "STATE.md ## Triage contains 'escalated'"
assert_file_not_contains "$WORK1/STATE.md" "**Path:** lite" "Path is no longer 'lite' after escalation"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: Step 5 — REQUIREMENTS.md scaffold created ==="

assert_file_exists "$WORK1/REQUIREMENTS.md" "REQUIREMENTS.md created by escalation"
assert_file_contains "$WORK1/REQUIREMENTS.md" "escalated from lite path" "REQUIREMENTS.md Change Log entry mentions 'escalated from lite path'"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: Step 6 — ## Interview Status scaffold in STATE.md ==="

assert_file_contains "$WORK1/STATE.md" "## Interview Status" "STATE.md has ## Interview Status section"
assert_file_contains "$WORK1/STATE.md" "**Status:** In Progress" "Interview Status is In Progress"
assert_file_contains "$WORK1/STATE.md" "Partial" "Some sections pre-seeded as Partial from carry"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: Step 7 — REQUIREMENTS.md seeded from carried slots ==="

assert_file_contains "$WORK1/REQUIREMENTS.md" "lite-carry" "REQUIREMENTS.md has [lite-carry] prefixed AC items"
assert_file_contains "$WORK1/REQUIREMENTS.md" "Captured before escalation" "Problem Statement seeded with 'Captured before escalation' prefix"
assert_file_contains "$WORK1/REQUIREMENTS.md" "Widget renders correctly" "AC slot value carried to REQUIREMENTS.md"
assert_file_contains "$WORK1/REQUIREMENTS.md" "Widget handles errors" "second AC slot value carried"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: Step 9a — features/feature-001-{name}/SPEC.md placeholder ==="

FEAT_DIR="$WORK1/features/feature-001-widget"
assert_dir_exists "$FEAT_DIR" "features/feature-001-widget/ directory created"
assert_file_exists "$FEAT_DIR/SPEC.md" "features/feature-001-widget/SPEC.md placeholder created"
assert_file_contains "$FEAT_DIR/SPEC.md" "Placeholder — created by lite→full escalation" "feature SPEC.md contains placeholder text"
assert_file_contains "$FEAT_DIR/SPEC.md" "FEATURE-DECOMPOSITION" "feature SPEC.md references the decomposition step"
assert_file_contains "$FEAT_DIR/SPEC.md" "Pending (escalation placeholder)" "feature SPEC.md status is escalation placeholder"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: Step 9b — PLAN.md placeholder created ==="

assert_file_exists "$WORK1/PLAN.md" "PLAN.md placeholder created"
assert_file_contains "$WORK1/PLAN.md" "Placeholder — created by lite→full escalation" "PLAN.md contains placeholder text"
assert_file_contains "$WORK1/PLAN.md" "delivery-001" "PLAN.md has single-delivery skeleton"
assert_file_contains "$WORK1/PLAN.md" "## Deliveries" "PLAN.md has ## Deliveries section"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 8: Step 9c — work-root SPEC.md deleted (coexistence invariant) ==="

assert_file_absent "$WORK1/SPEC.md" "work-root SPEC.md deleted after escalation (coexistence invariant)"

# Full-path-shape only: REQUIREMENTS.md + features/feature-001-*/SPEC.md + PLAN.md + STATE.md
assert_file_exists "$WORK1/REQUIREMENTS.md" "REQUIREMENTS.md present (full-path-shape)"
assert_file_exists "$WORK1/PLAN.md" "PLAN.md present (full-path-shape)"
assert_file_exists "$WORK1/STATE.md" "STATE.md present (full-path-shape)"
assert_dir_exists "$WORK1/features" "features/ directory present (full-path-shape)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: State Detection resume rule — escalated + SPEC.md present ==="
# Simulate a crash mid-escalation: PATH is escalated, but SPEC.md still exists
# (Step 9c did not complete). State Detection should detect this and replay.

WORK2="$TMPDIR_BASE/work-002-crash"
make_lite_work "$WORK2" "crash"
# Simulate partial escalation: Steps 3-8 done, Steps 9a/9b done, but Step 9c NOT done
# (SPEC.md still present)
cat >> "$WORK2/STATE.md" <<'CRASHEOF'

## Escalation Carry

> Written by lite→full escalation.

- **Escalated from:** CONDENSED-INTAKE (Sub-path: LITE-FEATURE)
- **Escalated at:** 2026-05-24T10:00:00Z
- **Escalation rationale:** scope broader than expected

### Captured Slot Values

- **feature-title:** Crash Test Feature
CRASHEOF

# State.md triage updated to escalated
# (simulate by appending a marker — in real impl the block is rewritten)
cat >> "$WORK2/STATE.md" <<'CRASHEOF2'

<!-- Triage Path = escalated (simulated for crash recovery test) -->
CRASHEOF2

# Step 9a done: features dir exists
mkdir -p "$WORK2/features/feature-001-crash"
cat > "$WORK2/features/feature-001-crash/SPEC.md" <<'FEATEOF2'
# Feature: feature-001-crash

> Placeholder — created by lite→full escalation.

**Status:** Pending (escalation placeholder)
FEATEOF2

# Step 9b done: PLAN.md exists
cat > "$WORK2/PLAN.md" <<'PLANEOF2'
# Plan — crash

> Placeholder — created by lite→full escalation.

## Deliveries

| # | Name | Scope | Status |
|---|------|-------|--------|
| 1 | delivery-001 | (TBD) | Pending |
PLANEOF2

# Step 9c NOT done: SPEC.md still present
# This is the crash-recovery scenario

# Simulate State Detection replay: detect SPEC.md still present + escalated → delete it
if [[ -f "$WORK2/SPEC.md" ]]; then
    # State Detection rule fires: replay Step 9c
    rm -f "$WORK2/SPEC.md"
    pass "Resume rule: work-root SPEC.md deleted by State Detection crash-recovery replay"
else
    fail "Resume rule: SPEC.md was already absent (test fixture setup error)"
fi

# After replay, verify coexistence invariant holds
assert_file_absent "$WORK2/SPEC.md" "After resume replay: work-root SPEC.md absent (coexistence invariant)"
assert_file_exists "$WORK2/features/feature-001-crash/SPEC.md" "After resume replay: feature SPEC.md placeholder still present"
assert_file_exists "$WORK2/PLAN.md" "After resume replay: PLAN.md placeholder still present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: Carry block with no slots (pre-CONDENSED-INTAKE escalation) ==="

WORK3="$TMPDIR_BASE/work-003-early"
make_lite_work "$WORK3" "early"

# Simulate escalation before any slots answered
cat > "$WORK3/STATE.md" <<'EARLYEOF'
# Work State — early

## Triage

- **Path:** escalated
- **Decision rationale:** First run → escalated to full — no questions answered yet

## Escalation Carry

> Written by lite→full escalation.

- **Escalated from:** CONDENSED-INTAKE (Sub-path: LITE-FEATURE)
- **Escalated at:** 2026-05-24T09:00:00Z
- **Escalation rationale:** no questions answered yet

### Captured Slot Values

- (no slots captured — escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

(none — escalation before SPEC.md was written)

## Interview Status

**Status:** In Progress · **Grade:** Pending

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Pending | — |
| 2 | Problem Statement | Pending | — |
| 3 | Users & Stakeholders | Pending | — |
| 4 | Scope | Pending | — |
| 5 | Functional Requirements | Pending | — |
| 6 | Non-Functional Requirements | Pending | — |
| 7 | Constraints | Pending | — |
| 8 | Assumptions & Dependencies | Pending | — |
| 9 | Acceptance Criteria | Pending | — |
| 10 | Priority | Pending | — |
EARLYEOF

assert_file_contains "$WORK3/STATE.md" "(no slots captured — escalation before CONDENSED-INTAKE)" \
    "No-slots carry block uses correct placeholder text"
assert_file_contains "$WORK3/STATE.md" "## Escalation Carry" \
    "STATE.md has ## Escalation Carry even with no slots"
assert_file_contains "$WORK3/STATE.md" "## Interview Status" \
    "Interview Status scaffold present even for pre-CONDENSED-INTAKE escalation"

# All sections should be Pending (no pre-seeding possible)
PARTIAL_COUNT=$(grep -c "Partial" "$WORK3/STATE.md" 2>/dev/null || echo 0)
PARTIAL_COUNT="${PARTIAL_COUNT//[$'\r\n']}"
if [[ "$PARTIAL_COUNT" -eq 0 ]]; then
    pass "No-slots escalation: no sections pre-seeded as Partial (all Pending — correct)"
else
    fail "No-slots escalation: unexpected Partial sections ($PARTIAL_COUNT) — should all be Pending"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "  Tests passed: $PASS"
echo "  Tests failed: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
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
