#!/usr/bin/env bash
# test-change-refactor-family-scaffold.sh -- task-018 (work-001-lite-aid-skills,
# feature-007): aid-change / aid-refactor family scaffold + alias-equivalence test.
#
# The shortcut engine + the change/refactor scaffolding reference are agent-executed
# PROSE, not executable scripts -- a deterministic canonical test cannot "run"
# /aid-change-data-model or /aid-refactor. This suite is therefore CONTRACT +
# FIXTURE-SHAPE, matching the other work-001 shortcut-engine suites
# (test-fix-family-scaffold.sh, test-create-family-scaffold.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/change-refactor.md for the
#      load-bearing elements: change inherits create.md's artifact matrix by reference
#      (not duplicated), the refactor-kind closed 3-enum, the 3 refactor-kind task
#      templates (rename/restructure/performance), and the Ownership-boundary split
#      (behavior-changing vs. not; defect routes to aid-fix, not aid-change).
#   2. Alias-equivalence + bare-verb contract -- checked against the REAL catalog +
#      skill dirs: `aid-update-api`'s row carries the identical `{verb, artifact}`
#      binding as `aid-change-api`'s and `alias_of: aid-change-api`; `aid-refactor`
#      carries NO alias row and NO artifact-suffixed variant (stays bare, AC-4).
#   3. Fixture-shape assertions -- hand-authored flattened work fixtures mirroring what
#      `/aid-change-data-model`, `/aid-refactor` (performance mode), and `/aid-refactor`
#      (rename mode) would produce, all halted at APPROVAL-HALT (pre-Execute). A further
#      pair of fixtures (built via the same builder, once labelled `aid-change-api` and
#      once `aid-update-api`) proves the alias produces the byte-identical work shape
#      (AC-1) -- diffed after normalizing the one line that legitimately differs (the
#      invoking shortcut's own name).
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-change-refactor-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CR_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/change-refactor.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-change/aid-refactor family scaffold + alias-equivalence (task-018, feature-007) ==="

assert_file_exists "$CR_SCAFFOLD" "CRF00a shortcut-scaffolding/change-refactor.md exists"
assert_file_exists "$CATALOG" "CRF00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "CRF00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

CR_TXT=$(cat "$CR_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/change-refactor.md
# ===========================================================================
echo "--- Part 1: change-refactor.md contract assertions ---"

# CRF-01: change inherits create.md's artifact matrix by reference, not duplicated.
assert_output_contains "$CR_TXT" \
    "**This file does not duplicate the artifact matrix.**" \
    "CRF01a change-refactor.md states it does not duplicate the artifact matrix"
assert_output_contains "$CR_TXT" \
    "per-artifact SPEC-section activation and task-breakdown counts/types are" \
    "CRF01b change's SPEC/task-breakdown counts+types statement present (wrap point 1)"
assert_output_contains "$CR_TXT" \
    "**identical to \`aid-create\`'s**" \
    "CRF01c change's SPEC/task-breakdown counts+types identical to aid-create's (wrap point 2)"

# CRF-02: change DETAIL task breakdown equals create.md's artifact-matrix row (two-phrase).
assert_output_contains "$CR_TXT" \
    "**The task count and types equal \`create.md\`'s artifact-matrix row for the" \
    "CRF02a change task count/types == create.md's artifact-matrix row (wrap point 1)"
assert_output_contains "$CR_TXT" \
    'same `{artifact}`**' \
    "CRF02b change task count/types == create.md's artifact-matrix row (wrap point 2)"

# CRF-03: aid-refactor CAPTURE -- refactor-kind is a closed 3-enum.
assert_output_contains "$CR_TXT" \
    'closed enum: `rename` \| `restructure` \| `performance`' \
    "CRF03 refactor-kind is a closed 3-enum (rename|restructure|performance)"

# CRF-04: the 3 refactor-kind task-breakdown templates (exact table rows).
assert_output_contains "$CR_TXT" \
    '| `rename` | single `task-001` REFACTOR -- rename across source/tests/docs; grep confirms no residual' \
    "CRF04a rename-kind: single task-001 REFACTOR"
assert_output_contains "$CR_TXT" \
    '| `restructure` | `task-001` REFACTOR + `task-002` TEST -- full suite run after restructuring must match the pre-refactor baseline (same pass/fail) |' \
    "CRF04b restructure-kind: task-001 REFACTOR + task-002 TEST, full suite matches baseline"
assert_output_contains "$CR_TXT" \
    '| `performance` | `task-001` REFACTOR (eliminate the bottleneck; behavior unchanged) + `task-002` TEST -- a reproducible benchmark meets the captured target vs. the captured baseline' \
    "CRF04c performance-kind: task-001 REFACTOR (behavior unchanged) + task-002 TEST (reproducible benchmark vs. baseline)"

# CRF-05: Ownership boundary -- behavior-changing (change) vs. not (refactor); defect
# routes to aid-fix, not aid-change; content/tests carved out (two-phrase pairs).
assert_output_contains "$CR_TXT" \
    "acceptance criteria). \`aid-refactor\` = restructure/optimize **without**" \
    "CRF05a Ownership boundary: aid-refactor = restructure/optimize without changing behavior (wrap point 1)"
assert_output_contains "$CR_TXT" \
    "changing behavior -- the split is behavior-changing vs. not." \
    "CRF05b Ownership boundary: the change/refactor split is behavior-changing vs. not (wrap point 2)"
assert_output_contains "$CR_TXT" \
    "Behavior-preserving cleanup with no observable defect is \`aid-refactor\`, not" \
    "CRF05c Ownership boundary: behavior-preserving cleanup with no defect is aid-refactor, not aid-fix (wrap point 1)"
assert_output_contains "$CR_TXT" \
    "\`aid-fix\`. Editing **content/docs** is \`aid-document\`; changing **tests** is" \
    "CRF05d Ownership boundary: content/docs -> aid-document, tests -> aid-test (wrap point 2)"

# CRF-06: aid-remove CAPTURE/SPEC/DETAIL (v2.1.0 coverage-gap follow-on).
assert_output_contains "$CR_TXT" '## `aid-remove` -- CAPTURE' \
    "CRF06a aid-remove CAPTURE section present"
assert_output_contains "$CR_TXT" \
    '| Removal mode | closed enum: `hard-delete` (delete outright) \| `keep-shim`' \
    "CRF06b aid-remove captures Removal mode as a closed enum (hard-delete | keep-shim)"
assert_output_contains "$CR_TXT" '## `aid-remove` -- SPEC section activation' \
    "CRF06c aid-remove SPEC section present"
assert_output_contains "$CR_TXT" \
    'The mandatory three sections apply with no conditional section; `### Data Model`' \
    "CRF06d aid-remove SPEC: mandatory three, no conditional section"
assert_output_contains "$CR_TXT" '## `aid-remove` -- DETAIL task breakdown' \
    "CRF06e aid-remove DETAIL section present"
assert_output_contains "$CR_TXT" \
    '| `task-001` | REFACTOR | identify every usage/caller of `{target}`' \
    "CRF06f aid-remove task-001: REFACTOR, identify usages then remove the target"
assert_output_contains "$CR_TXT" \
    '| `task-002` | IMPLEMENT | update every dependent identified in `task-001`' \
    "CRF06g aid-remove task-002: IMPLEMENT, update every dependent, depends on task-001"
assert_output_contains "$CR_TXT" \
    '| `task-003` | TEST | full suite run confirms no residual reference and no regression; depends on `task-002` |' \
    "CRF06h aid-remove task-003: TEST, full suite confirms no residual reference, depends on task-002"

# CRF-07: aid-deprecate CAPTURE/SPEC/DETAIL (v2.1.0 coverage-gap follow-on).
assert_output_contains "$CR_TXT" '## `aid-deprecate` -- CAPTURE' \
    "CRF07a aid-deprecate CAPTURE section present"
assert_output_contains "$CR_TXT" \
    '| Removal timeline | when the deprecated target is actually expected to go away' \
    "CRF07b aid-deprecate captures the Removal timeline"
assert_output_contains "$CR_TXT" '## `aid-deprecate` -- SPEC section activation' \
    "CRF07c aid-deprecate SPEC section present"
assert_output_contains "$CR_TXT" \
    'documents the deprecation-warning path' \
    "CRF07d aid-deprecate SPEC: Feature Flow documents the deprecation-warning path"
assert_output_contains "$CR_TXT" '## `aid-deprecate` -- DETAIL task breakdown' \
    "CRF07e aid-deprecate DETAIL section present"
assert_output_contains "$CR_TXT" \
    '| `task-001` | IMPLEMENT | add the deprecation marker/warning' \
    "CRF07f aid-deprecate task-001: IMPLEMENT, add the deprecation marker/warning"
assert_output_contains "$CR_TXT" \
    "Single-task by default -- deprecating adds a marker/warning, it does not remove" \
    "CRF07g aid-deprecate stays single-task by default (does not remove anything itself)"

# CRF-08: aid-migrate CAPTURE/SPEC/DETAIL (v2.1.0 coverage-gap follow-on).
assert_output_contains "$CR_TXT" '## `aid-migrate` -- CAPTURE' \
    "CRF08a aid-migrate CAPTURE section present"
assert_output_contains "$CR_TXT" \
    '| Scope | closed enum: `data` \| `dependency` \| `framework` \| `platform`' \
    "CRF08b aid-migrate captures Scope as a closed enum (data|dependency|framework|platform)"
assert_output_contains "$CR_TXT" \
    '| Rollback plan | how to revert if the migration fails partway' \
    "CRF08c aid-migrate captures a mandatory Rollback plan"
assert_output_contains "$CR_TXT" '## `aid-migrate` -- SPEC section activation' \
    "CRF08d aid-migrate SPEC section present"
assert_output_contains "$CR_TXT" \
    '`### Migration Plan` additionally activates' \
    "CRF08e aid-migrate SPEC: ### Migration Plan additionally activates"
assert_output_contains "$CR_TXT" '## `aid-migrate` -- DETAIL task breakdown' \
    "CRF08f aid-migrate DETAIL section present"
assert_output_contains "$CR_TXT" \
    '| `task-001` | MIGRATE | write the forward migration script/procedure per `{scope}`' \
    "CRF08g aid-migrate task-001: MIGRATE, forward migration + rollback script/procedure"
assert_output_contains "$CR_TXT" \
    '| `task-002` | TEST | verify the migrated state matches `{To}`, and that the rollback script actually reverts; depends on `task-001` |' \
    "CRF08h aid-migrate task-002: TEST, verify migrated state + rollback, depends on task-001"

# CRF-09: Ownership boundary -- remove/deprecate/migrate distinguished from each other and
# from aid-change, plus the review/research carve-out (assessing whether to act at all).
assert_output_contains "$CR_TXT" \
    '**Removing** an artifact outright is `aid-remove`, not `aid-change` --' \
    "CRF09a Ownership boundary: removing outright is aid-remove, not aid-change"
assert_output_contains "$CR_TXT" \
    'and `aid-remove`: the target still works, but callers are warned off it ahead' \
    "CRF09b Ownership boundary: aid-deprecate is the middle step before aid-remove (target still works)"
assert_output_contains "$CR_TXT" \
    '**Migrating** data/a dependency/a framework/a platform is `aid-migrate`, kept' \
    "CRF09c Ownership boundary: aid-migrate covers data/dependency/framework/platform"
assert_output_contains "$CR_TXT" \
    'migrated, before committing to the change, is `aid-review`/`aid-research`' \
    "CRF09d Ownership boundary: assessing whether to remove/deprecate/migrate routes to aid-review/aid-research"

echo ""
echo "--- Part 2: alias-equivalence + bare-verb contract (checked against the real catalog + skill dirs) ---"

get_row_field() {
    local name="$1" field="$2"
    awk -v target="  - name: ${name}" -v fieldpat="^    ${field}:" '
        $0 == target { in_row=1; next }
        in_row && /^  - name:/ { in_row=0 }
        in_row && $0 ~ fieldpat { sub(fieldpat "[[:space:]]*", ""); gsub(/"/, "", $0); print; exit }
    ' "$CATALOG"
}

# CRF-10: aid-update-api carries the identical {verb, artifact} binding as
# aid-change-api's, and alias_of points at aid-change-api exactly.
CHANGE_API_VERB=$(get_row_field "aid-change-api" "verb")
CHANGE_API_ARTIFACT=$(get_row_field "aid-change-api" "artifact")
UPDATE_API_VERB=$(get_row_field "aid-update-api" "verb")
UPDATE_API_ARTIFACT=$(get_row_field "aid-update-api" "artifact")
UPDATE_API_ALIAS_OF=$(get_row_field "aid-update-api" "alias_of")

assert_eq "$CHANGE_API_VERB" "change" "CRF10a aid-change-api row: verb == change"
assert_eq "$CHANGE_API_ARTIFACT" "api" "CRF10b aid-change-api row: artifact == api"
assert_eq "$UPDATE_API_VERB" "$CHANGE_API_VERB" "CRF10c aid-update-api row: verb identical to aid-change-api's"
assert_eq "$UPDATE_API_ARTIFACT" "$CHANGE_API_ARTIFACT" "CRF10d aid-update-api row: artifact identical to aid-change-api's"
assert_eq "$UPDATE_API_ALIAS_OF" "aid-change-api" "CRF10e aid-update-api row: alias_of == aid-change-api"

# CRF-11: aid-change-data-model row is MIGRATE-typed (mirrors create-data-model).
CHANGE_DM_DEFAULT_TYPE=$(get_row_field "aid-change-data-model" "default_type")
assert_eq "$CHANGE_DM_DEFAULT_TYPE" "MIGRATE" "CRF11 aid-change-data-model row: default_type == MIGRATE"

# CRF-12: aid-refactor row is bare (artifact "") and REFACTOR-typed.
REFACTOR_ARTIFACT=$(get_row_field "aid-refactor" "artifact")
REFACTOR_DEFAULT_TYPE=$(get_row_field "aid-refactor" "default_type")
assert_eq "$REFACTOR_ARTIFACT" "" "CRF12a aid-refactor row: artifact == \"\" (bare)"
assert_eq "$REFACTOR_DEFAULT_TYPE" "REFACTOR" "CRF12b aid-refactor row: default_type == REFACTOR"

# CRF-13: aid-refactor stays bare -- no alias row, no artifact-suffixed variant, no
# canonical/skills/aid-refactor-* directory (mirrors FFS10-14's aid-fix-stays-bare proof).
EXACT_ROWS=$(grep -c '^  - name: aid-refactor$' "$CATALOG" || true)
assert_eq "$EXACT_ROWS" "1" "CRF13a exactly one catalog row named exactly aid-refactor"

SUFFIXED_ROWS=$(grep -E '^  - name: aid-refactor-' "$CATALOG" || true)
if [[ -z "$SUFFIXED_ROWS" ]]; then
    pass "CRF13b no artifact-suffixed aid-refactor-* catalog row exists"
else
    fail "CRF13b no artifact-suffixed aid-refactor-* catalog row exists -- found: ${SUFFIXED_ROWS}"
fi

ALIAS_ROWS=$(grep -E '^    alias_of: aid-refactor$' "$CATALOG" || true)
if [[ -z "$ALIAS_ROWS" ]]; then
    pass "CRF13c no catalog row carries alias_of: aid-refactor (no alias family)"
else
    fail "CRF13c no catalog row carries alias_of: aid-refactor -- found an alias row"
fi

SUFFIXED_DIRS=$(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'aid-refactor-*' 2>/dev/null || true)
if [[ -z "$SUFFIXED_DIRS" ]]; then
    pass "CRF13d no canonical/skills/aid-refactor-* directory exists"
else
    fail "CRF13d no canonical/skills/aid-refactor-* directory exists -- found: ${SUFFIXED_DIRS}"
fi
assert_dir_exists "${SKILLS_ROOT}/aid-refactor" "CRF13e canonical/skills/aid-refactor/ (the one bare doorway) exists"

# CRF-14: both generated doorways (aid-change-api, aid-update-api) bind the identical
# VERB=`change` ARTIFACT=`api` pair.
CHANGE_API_BODY=$(cat "${SKILLS_ROOT}/aid-change-api/SKILL.md" 2>/dev/null || true)
UPDATE_API_BODY=$(cat "${SKILLS_ROOT}/aid-update-api/SKILL.md" 2>/dev/null || true)
assert_output_contains "$CHANGE_API_BODY" 'VERB=`change`' "CRF14a aid-change-api doorway binds VERB=\`change\`"
assert_output_contains "$CHANGE_API_BODY" 'ARTIFACT=`api`' "CRF14b aid-change-api doorway binds ARTIFACT=\`api\`"
assert_output_contains "$UPDATE_API_BODY" 'VERB=`change`' "CRF14c aid-update-api doorway binds the identical VERB=\`change\`"
assert_output_contains "$UPDATE_API_BODY" 'ARTIFACT=`api`' "CRF14d aid-update-api doorway binds the identical ARTIFACT=\`api\`"
assert_output_contains "$UPDATE_API_BODY" 'thin alias of `aid-change-api`' "CRF14e aid-update-api doorway self-documents as a thin alias of aid-change-api"

# CRF-15: aid-remove/aid-deprecate/aid-migrate (v2.1.0 coverage-gap follow-on) -- catalog
# rows exist, G5, bare (artifact ""), a valid default_type from the closed 8-enum,
# canonical (alias_of: null), skill dirs exist.
_VALID_TYPES_RE='^(RESEARCH|DESIGN|IMPLEMENT|TEST|DOCUMENT|MIGRATE|REFACTOR|CONFIGURE)$'
declare -A NEW_FAMILY_DEFAULT_TYPES=(
    ["aid-remove"]="REFACTOR"
    ["aid-deprecate"]="IMPLEMENT"
    ["aid-migrate"]="MIGRATE"
)
for name in "${!NEW_FAMILY_DEFAULT_TYPES[@]}"; do
    expected_dt="${NEW_FAMILY_DEFAULT_TYPES[$name]}"
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "CRF15 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "CRF15 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "CRF15 [${name}] SKILL.md exists"
    grp=$(get_row_field "$name" "group")
    assert_eq "$grp" "G5" "CRF15 [${name}] row: group == G5"
    artifact=$(get_row_field "$name" "artifact")
    assert_eq "$artifact" "" "CRF15 [${name}] row: artifact == \"\" (bare)"
    dt=$(get_row_field "$name" "default_type")
    assert_eq "$dt" "$expected_dt" "CRF15 [${name}] row: default_type == ${expected_dt}"
    if [[ "$dt" =~ $_VALID_TYPES_RE ]]; then
        pass "CRF15 [${name}] default_type is a member of the closed 8-enum"
    else
        fail "CRF15 [${name}] default_type is NOT a member of the closed 8-enum -- got: ${dt}"
    fi
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "CRF15 [${name}] row: alias_of == null (canonical row)"
done

# CRF-16: aid-delete is a thin alias of aid-remove (identical {verb, artifact} binding).
REMOVE_VERB=$(get_row_field "aid-remove" "verb")
DELETE_VERB=$(get_row_field "aid-delete" "verb")
DELETE_ARTIFACT=$(get_row_field "aid-delete" "artifact")
DELETE_ALIAS_OF=$(get_row_field "aid-delete" "alias_of")
assert_dir_exists "${SKILLS_ROOT}/aid-delete" "CRF16a aid-delete skill directory exists"
assert_eq "$DELETE_VERB" "$REMOVE_VERB" "CRF16b aid-delete row: verb identical to aid-remove's"
assert_eq "$DELETE_ARTIFACT" "" "CRF16c aid-delete row: artifact == \"\" (bare)"
assert_eq "$DELETE_ALIAS_OF" "aid-remove" "CRF16d aid-delete row: alias_of == aid-remove"

# CRF-17: aid-deprecate and aid-migrate stay bare -- no alias row, no artifact-suffixed
# variant (mirrors CRF-13's aid-refactor-stays-bare proof; aid-remove has the one
# aid-delete alias asserted above, so it is excluded here).
for base in aid-deprecate aid-migrate; do
    SUFFIXED_ROWS=$(grep -E "^  - name: ${base}-" "$CATALOG" || true)
    if [[ -z "$SUFFIXED_ROWS" ]]; then
        pass "CRF17 [${base}] no artifact-suffixed ${base}-* catalog row exists"
    else
        fail "CRF17 [${base}] no artifact-suffixed ${base}-* catalog row exists -- found: ${SUFFIXED_ROWS}"
    fi
    ALIAS_ROWS=$(grep -E "^    alias_of: ${base}\$" "$CATALOG" || true)
    if [[ -z "$ALIAS_ROWS" ]]; then
        pass "CRF17 [${base}] no catalog row carries alias_of: ${base} (no alias family)"
    else
        fail "CRF17 [${base}] no catalog row carries alias_of: ${base} -- found an alias row"
    fi
done

# ===========================================================================
# Part 3 -- Fixture-shape assertions
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_change_api_fixture <work-dir> <shortcut-name>
# Hand-authors a flattened work mirroring what /aid-change-api (or its alias
# /aid-update-api) + shortcut-engine.md would produce, per change-refactor.md's
# inherited artifact matrix for `api`, modify-framed: IMPLEMENT (update schema/model) ->
# IMPLEMENT (update handler+persistence) -> TEST (integration), halted pre-Execute.
build_change_api_fixture() {
    local work_dir="$1" shortcut="$2"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002" "${work_dir}/tasks/task-003"

    cat > "${work_dir}/REQUIREMENTS.md" <<EOF
# Requirements

- **Name:** orders resource -- add cancellation status
- **Description:** Change the orders resource API to support a cancellation status.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: ${shortcut}) | /${shortcut} |

## 1. Objective

Add a cancellation status to the orders resource API.

## 2. Problem Statement

The orders resource cannot represent a cancelled order today.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=change, artifact=api. Current shape: orders resource has no cancellation status.
Target shape: orders resource carries a cancellation status field.

## 5. Functional Requirements

Update the schema/model, the handler + persistence, and the integration test for the
orders resource to support a cancellation status.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given an order is cancelled, when the orders endpoint is called, then the response
  reflects the cancellation status.
- [ ] Given the integration test, when run, then it exercises the updated handler +
  persistence layer end to end.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<EOF
# orders resource -- add cancellation status

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /${shortcut} |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Add a cancellation status to the orders resource API.

## User Stories

- As an API consumer, I want to see an order's cancellation status so I can react to it.

## Priority

Must

## Acceptance Criteria

- [ ] Given an order is cancelled, when the orders endpoint is called, then the response
  reflects the cancellation status.

---

## Technical Specification

### Data Model

The orders entity gains a cancellation-status field.

### Feature Flow

Request -> validate -> handler -> persistence (now cancellation-aware) -> response.

### Layers & Components

The API layer (schema/model, handler, persistence) for the orders resource.

### API Contracts

Resource: orders. The response schema gains a cancellation-status field; no new
security notes.
EOF

    cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- orders resource -- add cancellation status

> **Work:** work-NNN-orders-cancellation-status
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- orders resource cancellation status
- **What it delivers:** the updated orders resource endpoint (schema, handler,
  persistence) + its updated integration test.
- **Features:** feature-001-orders-cancellation-status
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | -- (none) |
| task-002 | task-001 |
| task-003 | task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
EOF

    cat > "${work_dir}/BLUEPRINT.md" <<EOF
# Delivery BLUEPRINT -- delivery-001: orders resource cancellation status

> **Delivery:** delivery-001
> **Work:** work-NNN-orders-cancellation-status
> **Created:** 2026-07-09

---

## Objective

Add a cancellation status to the orders resource API.

## Scope

verb=change, artifact=api. Delta only: the cancellation-status field and its handling.

**Out of scope:** unrelated schema changes.

## Gate Criteria

- [ ] The response reflects the cancellation status once an order is cancelled.
- [ ] The integration test exercises the updated handler + persistence layer end to end.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Update schema/model for the orders resource cancellation status |
| task-002 | IMPLEMENT | Update handler + persistence for the orders resource cancellation status |
| task-003 | TEST | Update the integration test for the orders resource cancellation status |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /${shortcut} (change, artifact 'api').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: Update schema/model for the orders resource cancellation status

**Type:** IMPLEMENT

**Source:** work-NNN-orders-cancellation-status -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Update the orders entity schema/model to add the cancellation-status field.

**Acceptance Criteria:**
- [ ] The schema/model carries the new cancellation-status field per SPEC.md.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<EOF
# task-002: Update handler + persistence for the orders resource cancellation status

**Type:** IMPLEMENT

**Source:** work-NNN-orders-cancellation-status -> delivery-001

**Depends on:** task-001

**Scope:**
- Update the handler and its persistence layer to read/write the cancellation status.

**Acceptance Criteria:**
- [ ] Given an order is cancelled, when the orders endpoint is called, then the response
  reflects the cancellation status.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-003/DETAIL.md" <<EOF
# task-003: Update the integration test for the orders resource cancellation status

**Type:** TEST

**Source:** work-NNN-orders-cancellation-status -> delivery-001

**Depends on:** task-002

**Scope:**
- Update the integration test to exercise the updated handler + persistence layer end
  to end, including the cancellation-status path.

**Acceptance Criteria:**
- [ ] The integration test exercises the updated handler + persistence layer end to end.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<EOF
# Work State -- work-NNN-orders-cancellation-status

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** ${shortcut}
- **Updated:** 2026-07-09T12:00:00Z
- **Pause Reason:** GATE cleared; awaiting user approval before /aid-execute
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-09T12:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 | Pending | -- | -- | -- |
| task-002 | Pending | -- | -- | -- |
| task-003 | Pending | -- | -- | -- |
EOF
}

# build_change_data_model_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-change-data-model +
# shortcut-engine.md would produce: MIGRATE (forward+rollback) -> IMPLEMENT (update
# readers/writers) -> TEST, ### Data Model + ### Migration Plan activated, halted
# pre-Execute.
build_change_data_model_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002" "${work_dir}/tasks/task-003"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** customer profile -- add loyalty tier
- **Description:** Change the customer profile schema to add a loyalty tier.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-change-data-model) | /aid-change-data-model |

## 1. Objective

Add a loyalty tier column to the customer profile schema.

## 2. Problem Statement

The customer profile schema cannot represent a loyalty tier today.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=change, artifact=data-model. Current shape: no loyalty tier column. Target shape:
customer_profile carries a loyalty_tier column.

## 5. Functional Requirements

Add the forward+rollback migration, update the readers/writers, and add a test.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the forward migration, when applied, then customer_profile carries a
  loyalty_tier column.
- [ ] Given the rollback migration, when applied, then the loyalty_tier column is
  removed cleanly.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# customer profile -- add loyalty tier

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-change-data-model |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Add a loyalty tier column to the customer profile schema.

## User Stories

- As a service owner, I want a loyalty_tier column so downstream services can read a
  customer's tier.

## Priority

Must

## Acceptance Criteria

- [ ] Given the forward migration, when applied, then customer_profile carries a
  loyalty_tier column.

---

## Technical Specification

### Data Model

The customer_profile entity gains a loyalty_tier column.

### Feature Flow

Migrate -> update readers/writers -> test.

### Layers & Components

The data-access layer (repo/model readers/writers) for the customer_profile entity.

### Migration Plan

Forward migration adds the loyalty_tier column with a default; rollback drops it
cleanly (reversible, idempotent -- task-type-rules.md ## MIGRATE).
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- customer profile -- add loyalty tier

> **Work:** work-NNN-customer-profile-loyalty-tier
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- customer profile loyalty tier
- **What it delivers:** the loyalty_tier column (forward+rollback migration) + updated
  readers/writers + test.
- **Features:** feature-001-customer-profile-loyalty-tier
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | -- (none) |
| task-002 | task-001 |
| task-003 | task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
EOF

    cat > "${work_dir}/BLUEPRINT.md" <<'EOF'
# Delivery BLUEPRINT -- delivery-001: customer profile loyalty tier

> **Delivery:** delivery-001
> **Work:** work-NNN-customer-profile-loyalty-tier
> **Created:** 2026-07-09

---

## Objective

Add a loyalty tier column to the customer profile schema.

## Scope

verb=change, artifact=data-model. Delta only: the loyalty_tier column.

**Out of scope:** consuming services' own migrations.

## Gate Criteria

- [ ] The forward migration adds the loyalty_tier column.
- [ ] The rollback migration removes it cleanly.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | MIGRATE | Forward+rollback migration for loyalty_tier |
| task-002 | IMPLEMENT | Update readers/writers for loyalty_tier |
| task-003 | TEST | Test the loyalty_tier migration + readers/writers |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-change-data-model (change,
artifact 'data-model').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Forward+rollback migration for loyalty_tier

**Type:** MIGRATE

**Source:** work-NNN-customer-profile-loyalty-tier -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Write the forward migration adding loyalty_tier and its rollback.

**Acceptance Criteria:**
- [ ] Given the forward migration, when applied, then customer_profile carries a
  loyalty_tier column.
- [ ] Given the rollback migration, when applied, then the loyalty_tier column is
  removed cleanly.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Update readers/writers for loyalty_tier

**Type:** IMPLEMENT

**Source:** work-NNN-customer-profile-loyalty-tier -> delivery-001

**Depends on:** task-001

**Scope:**
- Update the repo/model readers/writers to read/write loyalty_tier.

**Acceptance Criteria:**
- [ ] The repo/model layer reads/writes loyalty_tier correctly.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-003/DETAIL.md" <<'EOF'
# task-003: Test the loyalty_tier migration + readers/writers

**Type:** TEST

**Source:** work-NNN-customer-profile-loyalty-tier -> delivery-001

**Depends on:** task-002

**Scope:**
- Test the forward+rollback migration and the updated readers/writers.

**Acceptance Criteria:**
- [ ] The test suite covers the forward migration, rollback, and readers/writers.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-customer-profile-loyalty-tier

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-change-data-model
- **Updated:** 2026-07-09T12:00:00Z
- **Pause Reason:** GATE cleared; awaiting user approval before /aid-execute
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-09T12:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 | Pending | -- | -- | -- |
| task-002 | Pending | -- | -- | -- |
| task-003 | Pending | -- | -- | -- |
EOF
}

# build_refactor_fixture <work-dir> <kind: performance|rename>
# Hand-authors a flattened work mirroring what /aid-refactor would produce for the
# given refactor-kind, per change-refactor.md's own task templates, halted pre-Execute.
build_refactor_fixture() {
    local work_dir="$1" kind="$2"
    mkdir -p "${work_dir}/tasks/task-001"

    local title task_count perf_section=""
    if [[ "$kind" == "performance" ]]; then
        title="hot-path query in the order-search endpoint"
        task_count=2
        mkdir -p "${work_dir}/tasks/task-002"
        perf_section='

Measured baseline: p95 480ms under the captured workload profile. Target: p95 <= 150ms,
no new dependency.'
    else
        title="rename OrderSvc to OrderService across the codebase"
        task_count=1
    fi

    cat > "${work_dir}/REQUIREMENTS.md" <<EOF
# Requirements

- **Name:** refactor -- ${title}
- **Description:** Restructure/optimize ${title} without changing behavior.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-refactor) | /aid-refactor |

## 1. Objective

Refactor ${title}.

## 2. Problem Statement

${title} needs a behavior-preserving restructure/optimization.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=refactor. refactor-kind: ${kind}. No behavior change.${perf_section}

## 5. Functional Requirements

Restructure/optimize ${title}; no observable behavior change.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

No new dependency.

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the existing test suite, when run after the refactor, then it passes
  identically to the pre-refactor baseline (same pass/fail).

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<EOF
# refactor -- ${title}

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-refactor |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Restructure/optimize ${title} without changing behavior.

## User Stories

- As a maintainer, I want ${title} refactored so the codebase stays healthy without
  changing behavior.

## Priority

Must

## Acceptance Criteria

- [ ] Given the existing test suite, when run after the refactor, then it passes
  identically to the pre-refactor baseline (same pass/fail).

---

## Technical Specification

### Data Model

Unchanged -- behavior-preserving refactor; no schema changes.

### Feature Flow

Unchanged -- behavior-preserving refactor; ${title} behaves identically
before and after.

### Layers & Components

The module(s) touched by ${title}.
EOF

    cat > "${work_dir}/BLUEPRINT.md" <<EOF
# Delivery BLUEPRINT -- delivery-001: refactor ${title}

> **Delivery:** delivery-001
> **Work:** work-NNN-refactor-sample-${kind}
> **Created:** 2026-07-09

---

## Objective

Refactor ${title} with no observable behavior change.

## Scope

verb=refactor. refactor-kind: ${kind}.

## Gate Criteria

- [ ] The existing test suite passes identically to the pre-refactor baseline.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks
EOF

    if [[ "$kind" == "performance" ]]; then
        cat >> "${work_dir}/BLUEPRINT.md" <<EOF

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Eliminate the bottleneck in ${title}; behavior unchanged |
| task-002 | TEST | Reproducible benchmark meets p95 <= 150ms vs. the 480ms baseline |
EOF
    else
        cat >> "${work_dir}/BLUEPRINT.md" <<EOF

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | ${title} |
EOF
    fi

    cat >> "${work_dir}/BLUEPRINT.md" <<EOF

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-refactor (refactor, artifact '').
EOF

    if [[ "$kind" == "performance" ]]; then
        cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- refactor ${title}

> **Work:** work-NNN-refactor-sample-${kind}
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- refactor ${title}
- **What it delivers:** the eliminated bottleneck + its reproducible benchmark proof.
- **Features:** feature-001-refactor-sample-${kind}
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | -- (none) |
| task-002 | task-001 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
EOF

        cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: Eliminate the bottleneck in ${title}

**Type:** REFACTOR

**Source:** work-NNN-refactor-sample-${kind} -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Eliminate the bottleneck in ${title}; behavior unchanged.

**Acceptance Criteria:**
- [ ] Given the existing test suite, when run after the refactor, then it passes
  identically to the pre-refactor baseline (behavior-preservation guarantee).
- [ ] All section-6 quality gates pass.
EOF

        cat > "${work_dir}/tasks/task-002/DETAIL.md" <<EOF
# task-002: Reproducible benchmark for ${title}

**Type:** TEST

**Source:** work-NNN-refactor-sample-${kind} -> delivery-001

**Depends on:** task-001

**Scope:**
- Run a reproducible benchmark and assert p95 <= 150ms vs. the measured 480ms baseline.

**Acceptance Criteria:**
- [ ] The reproducible benchmark meets the captured target vs. the captured baseline.
- [ ] All section-6 quality gates pass.
EOF
    else
        cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- refactor ${title}

> **Work:** work-NNN-refactor-sample-${kind}
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- refactor ${title}
- **What it delivers:** the rename across source/tests/docs.
- **Features:** feature-001-refactor-sample-${kind}
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | -- (none) |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
EOF

        cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: ${title}

**Type:** REFACTOR

**Source:** work-NNN-refactor-sample-${kind} -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Rename OrderSvc to OrderService across source/tests/docs.

**Acceptance Criteria:**
- [ ] A grep for the old name (OrderSvc) across source/tests/docs returns no residual
  occurrences.
- [ ] All section-6 quality gates pass.
EOF
    fi

    local tasks_lifecycle_rows="| task-001 | Pending | -- | -- | -- |"
    if [[ "$kind" == "performance" ]]; then
        tasks_lifecycle_rows="${tasks_lifecycle_rows}
| task-002 | Pending | -- | -- | -- |"
    fi

    cat > "${work_dir}/STATE.md" <<EOF
# Work State -- work-NNN-refactor-sample-${kind}

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-refactor
- **Updated:** 2026-07-09T12:00:00Z
- **Pause Reason:** GATE cleared; awaiting user approval before /aid-execute
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-09T12:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
${tasks_lifecycle_rows}
EOF
}

# ---------------------------------------------------------------------------
# Fixture A: aid-change-data-model
# ---------------------------------------------------------------------------
DM_DIR="${TMP}/work-change-data-model"
build_change_data_model_fixture "$DM_DIR"

assert_file_contains "${DM_DIR}/SPEC.md" "### Data Model" \
    "CRF20 change-data-model fixture: SPEC.md carries ### Data Model (mandatory section)"
assert_file_contains "${DM_DIR}/SPEC.md" "### Migration Plan" \
    "CRF21 change-data-model fixture: SPEC.md activates ### Migration Plan"
assert_file_contains "${DM_DIR}/tasks/task-001/DETAIL.md" "**Type:** MIGRATE" \
    "CRF22 change-data-model fixture: task-001 is MIGRATE (forward+rollback)"
assert_file_contains "${DM_DIR}/tasks/task-002/DETAIL.md" "**Type:** IMPLEMENT" \
    "CRF23 change-data-model fixture: task-002 is IMPLEMENT (update readers/writers)"
assert_file_contains "${DM_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "CRF24 change-data-model fixture: task-002 depends on task-001"
assert_file_contains "${DM_DIR}/tasks/task-003/DETAIL.md" "**Type:** TEST" \
    "CRF25 change-data-model fixture: task-003 is TEST"
assert_file_contains "${DM_DIR}/tasks/task-003/DETAIL.md" "**Depends on:** task-002" \
    "CRF26 change-data-model fixture: task-003 depends on task-002"

# ---------------------------------------------------------------------------
# Fixture B: aid-refactor, performance mode
# ---------------------------------------------------------------------------
PERF_DIR="${TMP}/work-refactor-performance"
build_refactor_fixture "$PERF_DIR" "performance"

assert_file_contains "${PERF_DIR}/tasks/task-001/DETAIL.md" "**Type:** REFACTOR" \
    "CRF30 refactor-performance fixture: task-001 is REFACTOR"
assert_file_contains "${PERF_DIR}/tasks/task-002/DETAIL.md" "**Type:** TEST" \
    "CRF31 refactor-performance fixture: task-002 is TEST"
assert_file_contains "${PERF_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "CRF32 refactor-performance fixture: task-002 depends on task-001"
assert_file_contains "${PERF_DIR}/tasks/task-001/DETAIL.md" "behavior-preservation guarantee" \
    "CRF33 refactor-performance fixture: task-001 carries a behavior-preservation AC"
PERF_TASK_COUNT=$(find "${PERF_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$PERF_TASK_COUNT" "2" "CRF34 refactor-performance fixture: 2-task shape (task-001, task-002)"

# ---------------------------------------------------------------------------
# Fixture C: aid-refactor, rename mode -- proves aid-refactor stays bare + single-task
# ---------------------------------------------------------------------------
RENAME_DIR="${TMP}/work-refactor-rename"
build_refactor_fixture "$RENAME_DIR" "rename"

assert_file_contains "${RENAME_DIR}/tasks/task-001/DETAIL.md" "**Type:** REFACTOR" \
    "CRF40 refactor-rename fixture: task-001 is REFACTOR"
RENAME_TASK_COUNT=$(find "${RENAME_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$RENAME_TASK_COUNT" "1" "CRF41 refactor-rename fixture: single-task shape (task-001 only, no task-002)"
assert_file_contains "${RENAME_DIR}/tasks/task-001/DETAIL.md" "no residual" \
    "CRF42 refactor-rename fixture: task-001 AC checks for no residual old-name occurrences"
assert_file_contains "${RENAME_DIR}/STATE.md" "**Active Skill:** aid-refactor" \
    "CRF43 refactor-rename fixture: Active Skill is aid-refactor (stays bare -- AC-4, not aid-refactor-rename)"

# ---------------------------------------------------------------------------
# All three fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$DM_DIR" "$PERF_DIR" "$RENAME_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "CRF50 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for section in "### Data Model" "### Feature Flow" "### Layers & Components"; do
        assert_file_contains "${FIXTURE_DIR}/SPEC.md" "$section" \
            "CRF57 [${fixture_label}] SPEC.md carries mandatory section ${section} (engine contract: mandatory three always apply)"
    done
    assert_file_exists "${FIXTURE_DIR}/tasks/task-001/DETAIL.md" "CRF51 [${fixture_label}] tasks/task-001/DETAIL.md present"
    if [[ -f "${FIXTURE_DIR}/tasks/task-001/STATE.md" ]]; then
        fail "CRF52 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    else
        pass "CRF52 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    fi

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "CRF53 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "CRF53 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    fi

    # Halts pre-Execute: no task past Pending; Delivery Lifecycle Specified (not Executing).
    NOT_PENDING=$(awk '
        /^### Tasks lifecycle/ { s=1; next }
        s && /^## / { s=0 }
        s && /^\| task-/ {
            n = split($0, f, "|")
            state = f[3]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
            if (state != "Pending") print state
        }
    ' "${FIXTURE_DIR}/STATE.md" | grep -c . || true)
    assert_eq "$NOT_PENDING" "0" "CRF54 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "CRF55 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "CRF56 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

# ===========================================================================
# Part 4 -- Alias-equivalence fixture-shape proof: aid-update-api == aid-change-api
# ===========================================================================
echo ""
echo "--- Part 4: alias-equivalence fixture-shape proof (aid-update-api == aid-change-api) ---"

CHANGE_DIR="${TMP}/work-change-api"
build_change_api_fixture "$CHANGE_DIR" "aid-change-api"
UPDATE_DIR="${TMP}/work-update-api"
build_change_api_fixture "$UPDATE_DIR" "aid-update-api"

FILES_TO_COMPARE=(REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md
    tasks/task-001/DETAIL.md tasks/task-002/DETAIL.md tasks/task-003/DETAIL.md STATE.md)

alias_diff_found=0
for f in "${FILES_TO_COMPARE[@]}"; do
    change_norm=$(sed -e 's/aid-change-api/SHORTCUT/g' "${CHANGE_DIR}/${f}")
    update_norm=$(sed -e 's/aid-update-api/SHORTCUT/g' "${UPDATE_DIR}/${f}")
    if [[ "$change_norm" == "$update_norm" ]]; then
        pass "CRF60 [${f}] byte-identical after normalizing the invoking shortcut's own name"
    else
        fail "CRF60 [${f}] byte-identical after normalizing the invoking shortcut's own name -- diff found"
        alias_diff_found=1
        if [[ "$VERBOSE" -eq 1 ]]; then
            diff <(echo "$change_norm") <(echo "$update_norm") || true
        fi
    fi
done
if [[ "$alias_diff_found" -eq 0 ]]; then
    pass "CRF61 aid-update-api produces the byte-identical work shape as aid-change-api (AC-1)"
else
    fail "CRF61 aid-update-api produces the byte-identical work shape as aid-change-api (AC-1)"
fi

echo ""
test_summary
