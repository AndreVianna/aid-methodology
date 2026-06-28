#!/usr/bin/env bash
# test-work-state-template.sh -- shape assertions for the per-level STATE/SPEC template set
#
# Verifies that the canonical templates and their rendered copies satisfy the
# naming contract (state-not-status), SD-2 ordering, SD-8 delivery lifecycle enum,
# SD-9 authored-not-derived note, and the derived/read-only markers.
#
# Templates under test (5 files):
#   work-state-template.md       -- work-level STATE
#   delivery-state-template.md   -- delivery-level STATE
#   task-state-template.md       -- task-level STATE
#   delivery-spec-template.md    -- delivery-level SPEC
#   task-spec-template.md        -- task-level SPEC
#
# Tests:
#   WS01  work-state-template has ## Pipeline State header (naming contract)
#   WS02  work-state-template has all 7 Pipeline State fields
#   WS03  work-state-template declares Lifecycle enum verbatim (closed, 5 members)
#   WS04  work-state-template declares Phase enum verbatim (7 members)
#   WS05  work-state-template declares Active Skill enum placeholder
#   WS06  work-state-template has "Never hand-edited" note + closed enums note
#   WS07  Rendered dogfood work-state-template matches canonical (spot checks)
#   WS08  Rendered profile trees all contain the work-state-template ## Pipeline State header
#   WS09  No "Status" section/field names remain in any new template (naming contract)
#   WS10  delivery-state-template carries SD-8 delivery lifecycle enum
#   WS11  delivery-state-template has authored-not-derived note (SD-9)
#   WS12  delivery-state-template has ## Cross-phase Q&A section (SD-5)
#   WS13  delivery-state-template ## Tasks State is marked DERIVED
#   WS14  task-state-template has the 4 mutable cells (State/Review/Elapsed/Notes)
#   WS15  task-state-template has ## Quick Check Findings section
#   WS16  task-state-template has ## Dispatch Log section
#   WS17  work-state-template 7 derived sections are marked DERIVED / read-only (Deploy State is AUTHORED)
#   WS18  SD-2 ordering (Done > ... > Pending) present as authoritative list
#   WS19  aid-describe state-first-run seeds Pipeline State fields (Lifecycle/Phase/Active Skill)
#   WS20  The seed prose does not introduce any new user-facing output
#
# Usage:
#   bash test-work-state-template.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

WORK_STATE="${REPO_ROOT}/canonical/aid/templates/work-state-template.md"
DELIVERY_STATE="${REPO_ROOT}/canonical/aid/templates/delivery-state-template.md"
TASK_STATE="${REPO_ROOT}/canonical/aid/templates/task-state-template.md"
DELIVERY_SPEC="${REPO_ROOT}/canonical/aid/templates/delivery-spec-template.md"
TASK_SPEC="${REPO_ROOT}/canonical/aid/templates/task-spec-template.md"

DOGFOOD_WORK_STATE="${REPO_ROOT}/.claude/aid/templates/work-state-template.md"
FIRST_RUN="${REPO_ROOT}/canonical/skills/aid-describe/references/state-first-run.md"
PROFILES_DIR="${REPO_ROOT}/profiles"

# ---------------------------------------------------------------------------
# WS01: work-state-template has ## Pipeline State header (naming contract)
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "## Pipeline State" \
    "WS01 work-state-template has ## Pipeline State header"

# ---------------------------------------------------------------------------
# WS02: work-state-template has all 7 Pipeline State fields
# ---------------------------------------------------------------------------
for field in "**Lifecycle:**" "**Phase:**" "**Active Skill:**" "**Updated:**" \
             "**Pause Reason:**" "**Block Reason:**" "**Block Artifact:**"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$field" \
        "WS02 work-state-template has field $field"
done

# ---------------------------------------------------------------------------
# WS03: work-state-template declares Lifecycle enum verbatim (all 5 members)
# ---------------------------------------------------------------------------
for member in "Running" "Paused-Awaiting-Input" "Blocked" "Completed" "Canceled"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$member" \
        "WS03 Lifecycle enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS04: work-state-template declares Phase enum verbatim (all 7 members)
# ---------------------------------------------------------------------------
for member in "Interview" "Specify" "Plan" "Detail" "Execute" "Deploy" "Monitor"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$member" \
        "WS04 Phase enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS05: work-state-template declares Active Skill enum placeholder
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "aid-{skill}" \
    "WS05 Active Skill enum placeholder aid-{skill} present"
assert_file_contains \
    "$WORK_STATE" \
    "**Active Skill:** aid-{skill} | none" \
    "WS05 Active Skill field line has expected shape"

# ---------------------------------------------------------------------------
# WS06: work-state-template has "Never hand-edited" note + closed enums note
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "Never hand-edited" \
    "WS06 work-state-template has 'Never hand-edited' note"
assert_file_contains \
    "$WORK_STATE" \
    "closed enums" \
    "WS06 work-state-template has 'closed enums' note"

# ---------------------------------------------------------------------------
# WS07: Rendered dogfood work-state-template has Pipeline State header and fields
# ---------------------------------------------------------------------------
if [[ -f "$DOGFOOD_WORK_STATE" ]]; then
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "## Pipeline State" \
        "WS07 dogfood rendered work-state-template has ## Pipeline State header"
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "**Lifecycle:**" \
        "WS07 dogfood rendered work-state-template has Lifecycle field"
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "**Phase:**" \
        "WS07 dogfood rendered work-state-template has Phase field"
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "Never hand-edited" \
        "WS07 dogfood rendered work-state-template has Never hand-edited note"
else
    fail "WS07 dogfood rendered work-state-template not found: $DOGFOOD_WORK_STATE"
fi

# ---------------------------------------------------------------------------
# WS08: Each rendered profile tree contains the ## Pipeline State header
# ---------------------------------------------------------------------------
profile_found=0
while IFS= read -r -d '' rendered_tmpl; do
    profile_found=$((profile_found + 1))
    assert_file_contains \
        "$rendered_tmpl" \
        "## Pipeline State" \
        "WS08 profile rendered work-state-template has ## Pipeline State: ${rendered_tmpl#"$REPO_ROOT/"}"
done < <(find "$REPO_ROOT/profiles" -name "work-state-template.md" -print0 2>/dev/null)

if [[ $profile_found -eq 0 ]]; then
    echo "  NOTE: no rendered profile copies of work-state-template.md found -- run generator to create them"
    pass "WS08 profile rendered templates check (none found -- generator not yet run)"
fi

# ---------------------------------------------------------------------------
# WS09: No "Status" section/field names in any new template (naming contract)
# The naming contract requires "state" not "status" for ALL section/field names.
# Enum VALUES are unchanged (Pending|In Progress|In Review|Blocked|Done|Failed|Canceled).
# We scan for patterns that would indicate a renamed field was missed:
#   ## <word> Status (section heading)
#   **<word> Status:** (field name)
#   State: <value> Status (inline label)
# We use a targeted grep that matches the bad patterns, not the word "Status" in general
# (the word legitimately appears in comments explaining the old name).
# ---------------------------------------------------------------------------
for tmpl in "$WORK_STATE" "$DELIVERY_STATE" "$TASK_STATE" "$DELIVERY_SPEC" "$TASK_SPEC"; do
    tmpl_name="${tmpl#"$REPO_ROOT/"}"
    # Pattern: ## heading containing "Status" as a word boundary section name
    if grep -qE '^## .*\bStatus\b' "$tmpl" 2>/dev/null; then
        fail "WS09 naming contract violated -- '## ... Status' heading found in $tmpl_name"
    else
        pass "WS09 no '## ... Status' heading in $tmpl_name"
    fi
    # Pattern: bold field name **...Status:**
    if grep -qE '^\*\*[^*]*Status[^*]*:\*\*' "$tmpl" 2>/dev/null; then
        fail "WS09 naming contract violated -- '**...Status:**' field found in $tmpl_name"
    else
        pass "WS09 no '**...Status:**' field in $tmpl_name"
    fi
done

# ---------------------------------------------------------------------------
# WS10: delivery-state-template carries SD-8 delivery lifecycle enum
# ---------------------------------------------------------------------------
for member in "Pending-Spec" "Specified" "Executing" "Gated" "Done" "Blocked"; do
    assert_file_contains \
        "$DELIVERY_STATE" \
        "$member" \
        "WS10 delivery-state-template has SD-8 enum member: $member"
done

# ---------------------------------------------------------------------------
# WS11: delivery-state-template has authored-not-derived note (SD-9)
# ---------------------------------------------------------------------------
assert_file_contains \
    "$DELIVERY_STATE" \
    "SD-9" \
    "WS11 delivery-state-template references SD-9"
assert_file_contains \
    "$DELIVERY_STATE" \
    "independently authored" \
    "WS11 delivery-state-template has independently-authored note"

# ---------------------------------------------------------------------------
# WS12: delivery-state-template has ## Cross-phase Q&A section (SD-5)
# ---------------------------------------------------------------------------
assert_file_contains \
    "$DELIVERY_STATE" \
    "## Cross-phase Q&A" \
    "WS12 delivery-state-template has ## Cross-phase Q&A section"
assert_file_contains \
    "$DELIVERY_STATE" \
    "SD-5" \
    "WS12 delivery-state-template references SD-5 for Q&A partitioning"

# ---------------------------------------------------------------------------
# WS13: delivery-state-template ## Tasks State is marked DERIVED
# ---------------------------------------------------------------------------
assert_file_contains \
    "$DELIVERY_STATE" \
    "## Tasks State" \
    "WS13 delivery-state-template has ## Tasks State section"
assert_file_contains \
    "$DELIVERY_STATE" \
    "DERIVED" \
    "WS13 delivery-state-template marks Tasks State as DERIVED"

# ---------------------------------------------------------------------------
# WS14: task-state-template has the 4 mutable cells
# ---------------------------------------------------------------------------
for cell in "**State:**" "**Review:**" "**Elapsed:**" "**Notes:**"; do
    assert_file_contains \
        "$TASK_STATE" \
        "$cell" \
        "WS14 task-state-template has mutable cell $cell"
done

# ---------------------------------------------------------------------------
# WS15: task-state-template has ## Quick Check Findings section
# ---------------------------------------------------------------------------
assert_file_contains \
    "$TASK_STATE" \
    "## Quick Check Findings" \
    "WS15 task-state-template has ## Quick Check Findings section"

# ---------------------------------------------------------------------------
# WS16: task-state-template has ## Dispatch Log section
# ---------------------------------------------------------------------------
assert_file_contains \
    "$TASK_STATE" \
    "## Dispatch Log" \
    "WS16 task-state-template has ## Dispatch Log section"

# ---------------------------------------------------------------------------
# WS17: work-state-template derived sections are marked DERIVED / read-only
# work-004 (task-016b): Deploy State was reclassified AUTHORED (single-writer
# aid-deploy; not hierarchy-migrated). The 7 remaining sections are DERIVED.
# ---------------------------------------------------------------------------
# Check each of the 7 DERIVED sections contains the DERIVED marker
for section in "Features State" "Plan / Deliveries" "Tasks State" \
               "Delivery Gates" "Cross-phase Q&A" "Calibration Log" "Dispatches"; do
    # Find the section header and check that DERIVED appears in that vicinity
    if grep -q "## ${section}" "$WORK_STATE" 2>/dev/null; then
        # Extract 5 lines after the section header and check for DERIVED
        section_block="$(grep -A5 "## ${section}" "$WORK_STATE" 2>/dev/null || true)"
        if echo "$section_block" | grep -q "DERIVED"; then
            pass "WS17 work-state-template section '${section}' marked DERIVED"
        else
            fail "WS17 work-state-template section '${section}' not marked DERIVED"
        fi
    else
        fail "WS17 work-state-template missing section: ## ${section}"
    fi
done

# ---------------------------------------------------------------------------
# WS18: SD-2 ordering present as authoritative ordered list
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "SD-2 STATE ADVANCEMENT ORDERING" \
    "WS18 work-state-template has SD-2 ordering comment block"
assert_file_contains \
    "$WORK_STATE" \
    "Done" \
    "WS18 SD-2 ordering contains Done"
assert_file_contains \
    "$WORK_STATE" \
    "Canceled" \
    "WS18 SD-2 ordering contains Canceled"
assert_file_contains \
    "$WORK_STATE" \
    "In Review" \
    "WS18 SD-2 ordering contains In Review"
assert_file_contains \
    "$WORK_STATE" \
    "Pending" \
    "WS18 SD-2 ordering contains Pending"
# Check that Rationale is present (the ordering must have a rationale, not just a list)
assert_file_contains \
    "$WORK_STATE" \
    "Rationale" \
    "WS18 SD-2 ordering has rationale"

# ---------------------------------------------------------------------------
# WS19: aid-describe state-first-run seeds Pipeline State fields
# (renamed from Pipeline Status -- check new field names are seeded)
# ---------------------------------------------------------------------------
if [[ -f "$FIRST_RUN" ]]; then
    assert_file_contains \
        "$FIRST_RUN" \
        "Lifecycle:** Running" \
        "WS19 aid-describe state-first-run seeds Lifecycle: Running"
    assert_file_contains \
        "$FIRST_RUN" \
        "Phase:** Interview" \
        "WS19 aid-describe state-first-run seeds Phase: Interview"
    assert_file_contains \
        "$FIRST_RUN" \
        "Active Skill:** aid-describe" \
        "WS19 aid-describe state-first-run seeds Active Skill: aid-describe"
else
    fail "WS19 state-first-run.md not found: $FIRST_RUN"
fi

# ---------------------------------------------------------------------------
# WS20: The seed prose does NOT introduce any user-visible print/output
# The seed step must be a silent state-write with no new prompts/gates.
# ---------------------------------------------------------------------------
if [[ -f "$FIRST_RUN" ]]; then
    SEED_SECTION="$(awk '/### 1b-ii/,/### 1c/' "$FIRST_RUN" 2>/dev/null || true)"
    if [[ -n "$SEED_SECTION" ]]; then
        if echo "$SEED_SECTION" | grep -qF "Print:"; then
            fail "WS20 seed block contains 'Print:' -- would add user-visible output (C4 violation)"
        else
            pass "WS20 seed block has no 'Print:' user-output instruction"
        fi
        if echo "$SEED_SECTION" | grep -qE '^\[.+\]'; then
            fail "WS20 seed block contains menu/gate markers -- would add user-facing prompts"
        else
            pass "WS20 seed block has no menu/gate markers"
        fi
    else
        fail "WS20 could not extract seed section from state-first-run.md"
    fi
else
    fail "WS20 state-first-run.md not found: $FIRST_RUN"
fi

test_summary
