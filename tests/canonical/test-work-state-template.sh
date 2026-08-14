#!/usr/bin/env bash
# test-work-state-template.sh -- shape assertions for the per-level STATE/SPEC template set
#
# Verifies that the canonical templates and their rendered copies satisfy the
# naming contract (state-not-status), SD-2 ordering, SD-8 delivery lifecycle enum,
# SD-9 authored-not-derived note, and the derived/read-only markers.
#
# Templates under test (5 files -- 3 renamed to .yml by FR-3, 2 stay markdown):
#   work-state-template.yml         -- work-level STATE (one whole-document YAML key space, no
#                                      `---` fence, no markdown body -- SPEC.md SS D-1/D-3)
#   delivery-state-template.yml     -- delivery-level STATE (same shape)
#   task-state-template.yml         -- task-level STATE (same shape)
#   delivery-blueprint-template.md  -- delivery-level BLUEPRINT (unaffected by FR-3)
#   task-detail-template.md         -- task-level DETAIL (unaffected by FR-3)
#
# Tests (WS01-WS20; WS06/WS11/WS17/WS18 were removed pre-refactor as comment-text
# assertions and stay removed -- 16 live ids):
#   WS01  work-state-template has the "# Work State --" full-line comment heading
#         (retargeted: FR-2b retires the `## Pipeline State` markdown heading entirely)
#   WS02  work-state-template has all 7 pipeline-scalar keys -- ALL SEVEN are now plain
#         `key:` lines in the one-zone document (the four that used to be bold-line body
#         prose -- Phase/Updated/Block Reason/Block Artifact -- are retargeted alongside the
#         three that were already frontmatter keys pre-refactor)
#   WS03  work-state-template declares Lifecycle enum verbatim (closed, 5 members) --
#         survives in substance (D-2), now inside a full-line comment above `lifecycle:`
#   WS04  work-state-template declares Phase enum verbatim (6 members) -- same, above `phase:`
#   WS05  work-state-template declares the Active Skill enum-hint substring `aid-{skill}`
#         (survives inside a full-line comment) AND the INSTANTIATED `active_skill: none`
#         key line (retargeted: SP-2/SP-20 -- no un-instantiated placeholder may sit on a
#         key whose value must be readable before the first write)
#   WS06  (removed) comment-text assertion -- see body note; coverage: WS07 (dogfood), WS03/WS04 (enums)
#   WS07  Rendered dogfood work-state-template.yml matches canonical (spot checks)
#   WS08  Rendered profile trees all contain the work-state-template.yml heading comment
#         (retargeted: the `## Pipeline State` heading this searched for is retired)
#   WS09  No "Status" section/field names remain in any new template (naming contract) --
#         still passes against the two heading-less .yml templates (vacuously: there are no
#         headings or bold lines left to match at all) and unchanged against the two .md ones
#   WS10  delivery-state-template carries SD-8 delivery lifecycle enum
#   WS11  (removed) comment-text assertion -- see body note; delivery enum coverage via WS10
#   WS12  delivery-state-template has a `qa:` key (retargeted: the `## Cross-phase Q&A`
#         markdown heading FR-2b retires; the SD-5 partition note survives inside a comment)
#   WS13  delivery-state-template has no represented Tasks State key -- the DERIVED
#         retirement note itself is asserted (retargeted: `## Tasks State` heading retired,
#         and per SS D-4/D-1 the whole point is that this view has NO key at all)
#   WS14  task-state-template has the 4 mutable-cell keys (state/review/elapsed/notes) --
#         survives in substance (D-2), just moves to the renamed file
#   WS15  task-state-template has a `quick_check:` key (retargeted: `## Quick Check
#         Findings` heading FR-2b retires)
#   WS16  task-state-template has a `dispatch_log:` key (retargeted: `## Dispatch Log`
#         heading FR-2b retires)
#   WS17  (removed) comment-text assertion -- see body note (DERIVED markers are HTML comments)
#   WS18  (removed) comment-text assertion -- see body note (ordering list + rationale live in a comment)
#   WS19  aid-describe state-first-run seeds the pipeline scalar keys (lifecycle/phase/
#         active_skill) -- unchanged in substance, only the dogfood path it resolves changed
#   WS20  The seed prose does not introduce any new user-facing output -- unchanged
#
# SP-20/SP-2/SP-3 additionally require, across every live assertion: no writer-owned key
# carries a trailing inline comment (D-3: documentation is a full-line comment ABOVE the
# key, never appended after the value); no un-instantiated placeholder sits on a key whose
# value must be readable before the first write (WS05); and no DERIVED key exists anywhere
# in the templates (WS13's whole point). These are asserted once, structurally, at the end.
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

WORK_STATE="${REPO_ROOT}/canonical/aid/templates/work-state-template.yml"
DELIVERY_STATE="${REPO_ROOT}/canonical/aid/templates/delivery-state-template.yml"
TASK_STATE="${REPO_ROOT}/canonical/aid/templates/task-state-template.yml"
DELIVERY_SPEC="${REPO_ROOT}/canonical/aid/templates/delivery-blueprint-template.md"
TASK_SPEC="${REPO_ROOT}/canonical/aid/templates/task-detail-template.md"

DOGFOOD_WORK_STATE="${REPO_ROOT}/.claude/aid/templates/work-state-template.yml"
FIRST_RUN="${REPO_ROOT}/canonical/skills/aid-describe/references/state-first-run.md"
PROFILES_DIR="${REPO_ROOT}/profiles"

# ---------------------------------------------------------------------------
# WS01: work-state-template has the "# Work State --" full-line comment
# heading (retargeted -- the `## Pipeline State` markdown heading FR-2b
# retires no longer exists anywhere in the one-zone document).
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "# Work State --" \
    "WS01 work-state-template has the '# Work State --' comment heading"

# ---------------------------------------------------------------------------
# WS02: work-state-template has all 7 pipeline-scalar keys. Pre-refactor,
# Lifecycle/Active Skill/Pause Reason were frontmatter keys and Phase/Updated/
# Block Reason/Block Artifact were bold-line body prose; FR-2b collapses the
# whole document to one zone, so ALL SEVEN are now plain `key:` lines.
# ---------------------------------------------------------------------------
for key in "lifecycle:" "phase:" "active_skill:" "updated:" "pause_reason:" "block_reason:" "block_artifact:"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$key" \
        "WS02 work-state-template has key $key"
done

# ---------------------------------------------------------------------------
# WS03: work-state-template declares Lifecycle enum verbatim (all 5 members).
# Survives in substance (D-2): now inside a full-line comment above `lifecycle:`.
# ---------------------------------------------------------------------------
for member in "Running" "Paused-Awaiting-Input" "Blocked" "Completed" "Canceled"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$member" \
        "WS03 Lifecycle enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS04: work-state-template declares Phase enum verbatim (all 6 members) --
# faithful numbered pipeline; ends at Execute (Deploy is a separate path, not a
# phase; Interview/Monitor retired). Survives in substance, comment-hosted.
# ---------------------------------------------------------------------------
for member in "Describe" "Define" "Specify" "Plan" "Detail" "Execute"; do
    assert_file_contains \
        "$WORK_STATE" \
        "$member" \
        "WS04 Phase enum member present: $member"
done

# ---------------------------------------------------------------------------
# WS05: work-state-template declares the Active Skill enum-hint substring
# (survives inside a full-line comment, per D-2) AND the INSTANTIATED
# `active_skill: none` key line (content-breaking retarget: SP-2/SP-20 --
# a key whose value must be readable before the first write, like the seed
# template, must carry a real value, not an un-instantiated placeholder).
# ---------------------------------------------------------------------------
assert_file_contains \
    "$WORK_STATE" \
    "aid-{skill}" \
    "WS05 Active Skill enum-hint substring aid-{skill} present (comment)"
assert_file_contains \
    "$WORK_STATE" \
    "active_skill: none" \
    "WS05 active_skill key carries a real instantiated value (none), not a placeholder"

# ---------------------------------------------------------------------------
# WS06 removed: tests must not assert comment text (owner directive); render fidelity is covered by the render-drift / byte-identity gates, enum members by WS03/WS04.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# WS07: Rendered dogfood work-state-template.yml has the comment heading and
# the pipeline-scalar keys (path retargeted from the retired .md render).
# ---------------------------------------------------------------------------
if [[ -f "$DOGFOOD_WORK_STATE" ]]; then
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "# Work State --" \
        "WS07 dogfood rendered work-state-template.yml has the comment heading"
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "lifecycle:" \
        "WS07 dogfood rendered work-state-template.yml has the lifecycle key"
    assert_file_contains \
        "$DOGFOOD_WORK_STATE" \
        "phase:" \
        "WS07 dogfood rendered work-state-template.yml has the phase key"
else
    fail "WS07 dogfood rendered work-state-template.yml not found: $DOGFOOD_WORK_STATE"
fi

# ---------------------------------------------------------------------------
# WS08: Each rendered profile tree contains the work-state-template.yml
# comment heading (retargeted -- the `## Pipeline State` heading this
# searched for pre-refactor is retired script-wide).
# ---------------------------------------------------------------------------
profile_found=0
while IFS= read -r -d '' rendered_tmpl; do
    profile_found=$((profile_found + 1))
    assert_file_contains \
        "$rendered_tmpl" \
        "# Work State --" \
        "WS08 profile rendered work-state-template.yml has the comment heading: ${rendered_tmpl#"$REPO_ROOT/"}"
done < <(find "$REPO_ROOT/profiles" -name "work-state-template.yml" -print0 2>/dev/null)

if [[ $profile_found -eq 0 ]]; then
    echo "  NOTE: no rendered profile copies of work-state-template.yml found -- run generator to create them"
    pass "WS08 profile rendered templates check (none found -- generator not yet run)"
fi

# ---------------------------------------------------------------------------
# WS09: No "Status" section/field names in any new template (naming contract).
# Path-level only: the two heading-less .yml templates pass VACUOUSLY (there
# are no `## ` headings or `**...:**` bold lines left to match at all), and
# the two still-markdown templates (DELIVERY_SPEC/TASK_SPEC) are unaffected
# by FR-3 and checked exactly as before.
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
# WS11 removed: tests must not assert comment text (owner directive); the authored-not-derived note is comment-only. Delivery lifecycle enum members still covered by WS10.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# WS12: delivery-state-template has a `qa:` key (content-breaking retarget:
# `## Cross-phase Q&A` is a markdown heading FR-2b retires; the SD-5
# per-delivery Q&A partition survives inside the `qa:` key's own comment).
# ---------------------------------------------------------------------------
assert_file_contains \
    "$DELIVERY_STATE" \
    "qa:" \
    "WS12 delivery-state-template has a qa: key"
assert_file_contains \
    "$DELIVERY_STATE" \
    "Cross-phase Q&A" \
    "WS12 the SD-5 Cross-phase Q&A partition note survives (comment-hosted)"

# ---------------------------------------------------------------------------
# WS13: delivery-state-template's Tasks State view has NO represented key --
# content-breaking retarget: `## Tasks State` was a markdown heading; SS D-1/
# D-4 retire it entirely (DERIVED, assembled at read time from per-task
# STATE.yml files), so the assertion is now that the DERIVED retirement note
# itself is present, not a heading.
# ---------------------------------------------------------------------------
assert_file_contains \
    "$DELIVERY_STATE" \
    "DERIVED: tasks rollup" \
    "WS13 delivery-state-template documents the Tasks State DERIVED retirement (no key represented)"
if grep -qE '^## Tasks State' "$DELIVERY_STATE" 2>/dev/null; then
    fail "WS13 a literal '## Tasks State' markdown heading survived -- FR-2b must retire it"
else
    pass "WS13 no literal '## Tasks State' markdown heading (DERIVED, not represented)"
fi

# ---------------------------------------------------------------------------
# WS14: task-state-template has the 4 mutable-cell keys. Survives in
# substance (D-2) -- these were already frontmatter keys pre-refactor; only
# the file this resolves moves (STATE.md -> STATE.yml).
# ---------------------------------------------------------------------------
for cell in "state:" "review:" "elapsed:" "notes:"; do
    assert_file_contains \
        "$TASK_STATE" \
        "$cell" \
        "WS14 task-state-template has mutable-cell key $cell"
done

# ---------------------------------------------------------------------------
# WS15: task-state-template has a `quick_check:` key (content-breaking
# retarget: `## Quick Check Findings` is a markdown heading FR-2b retires).
# ---------------------------------------------------------------------------
assert_file_contains \
    "$TASK_STATE" \
    "quick_check:" \
    "WS15 task-state-template has a quick_check: key"

# ---------------------------------------------------------------------------
# WS16: task-state-template has a `dispatch_log:` key (content-breaking
# retarget: `## Dispatch Log` is a markdown heading FR-2b retires).
# ---------------------------------------------------------------------------
assert_file_contains \
    "$TASK_STATE" \
    "dispatch_log:" \
    "WS16 task-state-template has a dispatch_log: key"

# ---------------------------------------------------------------------------
# WS17 removed: tests must not assert comment text (owner directive); the DERIVED / read-only zone markers are HTML comments and are no longer separately asserted.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# WS18 removed: tests must not assert comment text (owner directive); the state-advancement ordering list + rationale live in an HTML comment. Enum members still covered by WS03.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# WS19: aid-describe state-first-run seeds the pipeline scalar keys.
# Unchanged in substance -- these were already frontmatter keys pre-refactor;
# only the dogfood path this section resolves (`### 1b-ii`) changed.
# ---------------------------------------------------------------------------
if [[ -f "$FIRST_RUN" ]]; then
    assert_file_contains \
        "$FIRST_RUN" \
        "lifecycle: Running" \
        "WS19 aid-describe state-first-run seeds lifecycle: Running"
    assert_file_contains \
        "$FIRST_RUN" \
        "phase: Describe" \
        "WS19 aid-describe state-first-run seeds phase: Describe"
    assert_file_contains \
        "$FIRST_RUN" \
        "active_skill: aid-describe" \
        "WS19 aid-describe state-first-run seeds active_skill: aid-describe"
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
        if grep -qF "Print:" <<<"$SEED_SECTION"; then
            fail "WS20 seed block contains 'Print:' -- would add user-visible output (C4 violation)"
        else
            pass "WS20 seed block has no 'Print:' user-output instruction"
        fi
        if grep -qE '^\[.+\]' <<<"$SEED_SECTION"; then
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

# ---------------------------------------------------------------------------
# SP-20/SP-2/SP-3 structural checks, asserted once across all three renamed
# templates: no writer-owned key carries a TRAILING inline comment (D-3
# requires documentation as a full-line comment ABOVE the key); and no
# DERIVED key exists anywhere (WS13's point, generalized).
# ---------------------------------------------------------------------------
for tmpl in "$WORK_STATE" "$DELIVERY_STATE" "$TASK_STATE"; do
    tmpl_name="${tmpl#"$REPO_ROOT/"}"
    # A key: value line followed by a same-line trailing " #" comment (not a
    # full-line comment) would violate D-3. Bare "--" / "[]" / quoted values
    # never legitimately contain " #" unescaped, so this is a safe grep.
    if grep -qE '^[a-z_]+:.*[^"'"'"']  #' "$tmpl" 2>/dev/null; then
        fail "SP-20 $tmpl_name: a key line carries a trailing inline comment (D-3 requires full-line comments above the key)"
    else
        pass "SP-20 $tmpl_name: no writer-owned key carries a trailing inline comment"
    fi
    if grep -qE '^[a-z_]+:\s*DERIVED\b' "$tmpl" 2>/dev/null; then
        fail "SP-3 $tmpl_name: a literal DERIVED key exists (DERIVED views must have no key at all)"
    else
        pass "SP-3 $tmpl_name: no DERIVED key present"
    fi
done

test_summary
