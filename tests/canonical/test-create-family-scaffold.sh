#!/usr/bin/env bash
# test-create-family-scaffold.sh -- task-016 (work-001-lite-aid-skills, feature-006):
# aid-create family scaffold + alias-equivalence test.
#
# The shortcut engine + the create scaffolding reference are agent-executed PROSE, not
# executable scripts -- a deterministic canonical test cannot "run" /aid-create-api. This
# suite is therefore CONTRACT + FIXTURE-SHAPE, matching the other work-001 shortcut-engine
# suites (test-fix-family-scaffold.sh, test-catalog-dirs-parity.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/create.md (and the shared engine's
#      Family Scaffolding Consult section) for the load-bearing elements: the mandatory
#      three SPEC sections, the `api`/`data-model` conditional-section + task-breakdown
#      rows, the strictly-sequential task-dependency rule, and the Ownership-boundary
#      routing (test/experiment/document/report carved out of create).
#   2. Alias-equivalence contract -- checked against the REAL catalog + skill dirs:
#      `aid-add-api`'s row carries the identical `{verb, artifact}` binding as
#      `aid-create-api`'s and `alias_of: aid-create-api`; both generated doorways bind the
#      same VERB/ARTIFACT; the engine's own alias-resolution sentence is present.
#   3. Fixture-shape assertions -- two hand-authored flattened work fixtures mirroring what
#      `/aid-create-api` and `/aid-create-data-model` would produce (API: IMPLEMENT ->
#      IMPLEMENT -> TEST + `### API Contracts`; data-model: MIGRATE -> IMPLEMENT -> TEST +
#      `### Migration Plan`), both halted at APPROVAL-HALT (pre-Execute). A THIRD pair of
#      fixtures (built via the SAME builder, once labelled `aid-create-api` and once
#      `aid-add-api`) proves the alias produces the byte-identical work shape (AC-1) --
#      diffed after normalizing the one line that legitimately differs (the invoking
#      shortcut's own name).
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-create-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CREATE_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/create.md"
ENGINE="${REPO_ROOT}/canonical/aid/templates/shortcut-engine.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-create family scaffold + alias-equivalence (task-016, feature-006) ==="

assert_file_exists "$CREATE_SCAFFOLD" "CFS00a shortcut-scaffolding/create.md exists"
assert_file_exists "$ENGINE" "CFS00b shortcut-engine.md exists"
assert_file_exists "$CATALOG" "CFS00c shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "CFS00d canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

CREATE_TXT=$(cat "$CREATE_SCAFFOLD")
ENGINE_TXT=$(cat "$ENGINE")
# Whitespace-normalized (all newlines/runs of blanks collapsed to a single space)
# copy of the engine text, used for assertions whose target prose spans a
# hand-wrapped source line break. `assert_output_contains` greps line-by-line, so a
# pattern that straddles two physical lines only matches if that exact hard-wrap
# column is preserved — brittle across re-wraps/renders. Matching against the
# flattened text instead makes the assertion wrap-column-invariant while still
# proving the full sentence verbatim.
ENGINE_FLAT=$(tr '\n' ' ' <<< "$ENGINE_TXT" | tr -s '[:space:]' ' ')

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/create.md
# ===========================================================================
echo "--- Part 1: create.md contract assertions ---"

# CFS-01: the mandatory three SPEC sections always apply (two-phrase -- wraps source lines).
assert_output_contains "$CREATE_TXT" \
    'The mandatory three sections (`### Data Model`, `### Feature Flow`,' \
    "CFS01a mandatory three SPEC sections named (wrap point 1)"
assert_output_contains "$CREATE_TXT" \
    '`### Layers & Components`) always apply.' \
    "CFS01b mandatory three SPEC sections named (wrap point 2)"

# CFS-02: per-artifact conditional SPEC-section activation -- api / data-model rows.
assert_output_contains "$CREATE_TXT" \
    '| `api` | `### API Contracts` |' \
    "CFS02a api activates ### API Contracts"
assert_output_contains "$CREATE_TXT" \
    '| `data-model` | `### Migration Plan` |' \
    "CFS02b data-model activates ### Migration Plan"

# CFS-03: per-artifact DETAIL task-breakdown template -- api / data-model rows (exact chains).
assert_output_contains "$CREATE_TXT" \
    '| `api` | `task-001` IMPLEMENT (schema/model), `task-002` IMPLEMENT (handler + persistence), `task-003` TEST (integration) |' \
    "CFS03a api task-breakdown: IMPLEMENT(schema) -> IMPLEMENT(handler+persistence) -> TEST(integration)"
assert_output_contains "$CREATE_TXT" \
    '| `data-model` | `task-001` MIGRATE (schema + migration), `task-002` IMPLEMENT (repo/model wiring), `task-003` TEST |' \
    "CFS03b data-model task-breakdown: MIGRATE -> IMPLEMENT -> TEST"

# CFS-04: task dependencies are strictly sequential (two-phrase -- wraps source lines).
assert_output_contains "$CREATE_TXT" \
    "Every multi-task artifact's task dependencies are strictly sequential" \
    "CFS04a strictly-sequential task-dependency rule stated (wrap point 1)"
assert_output_contains "$CREATE_TXT" \
    '(`task-002` depends on `task-001`, `task-003` depends on `task-002`)' \
    "CFS04b strictly-sequential task-dependency rule stated (wrap point 2)"

# CFS-05: Ownership boundary -- test/experiment/doc/report/dashboard carved out of create
# (work-005: routing re-authored -- running-tests -> aid-test, doc -> aid-create-document,
# report -> aid-report, dashboard -> aid-create-dashboard; each on its own source line).
assert_output_contains "$CREATE_TXT" \
    '**running tests / verification -> `aid-test`**' \
    "CFS05a Ownership boundary: running tests/verification -> aid-test"
assert_output_contains "$CREATE_TXT" \
    '**experiment -> `aid-experiment`**,' \
    "CFS05b Ownership boundary: experiment -> aid-experiment"
assert_output_contains "$CREATE_TXT" \
    '`aid-create-document`**, **report -> `aid-report`**, **dashboard ->' \
    "CFS05c Ownership boundary: doc/content -> aid-create-document, report -> aid-report"
assert_output_contains "$CREATE_TXT" \
    '`aid-create-dashboard`**.' \
    "CFS05d Ownership boundary: dashboard -> aid-create-dashboard"
assert_output_contains "$CREATE_TXT" \
    '`aid-change` (`shortcut-scaffolding/change-refactor.md`),' \
    "CFS05e Ownership boundary: modifying an existing artifact routes to aid-change"

echo ""
echo "--- Part 2: alias-equivalence contract (checked against the real catalog + skill dirs) ---"

# CFS-10: the engine's own alias-resolution sentence names this exact pair. Matched
# against the whitespace-flattened text (ENGINE_FLAT) so the assertion holds
# regardless of the source's hard-wrap column (the sentence spans a hand-wrapped
# line break in the canonical file, and a per-line grep against the raw text would
# be brittle to any re-wrap of that prose).
assert_output_contains "$ENGINE_FLAT" \
    "canonical mirror's, so both resolve the same file -- \`aid-add-api\` and \`aid-create-api\` both resolve \`shortcut-scaffolding/create.md\`;" \
    "CFS10a engine states an alias row's verb == its mirror's (aid-add-api/aid-create-api named, wrap-invariant)"
assert_output_contains "$ENGINE_FLAT" \
    'both resolve `shortcut-scaffolding/create.md`;' \
    "CFS10b engine states both resolve shortcut-scaffolding/create.md (wrap-invariant)"

# CFS-11: catalog rows -- aid-create-api and aid-add-api carry the identical {verb, artifact}
# binding; aid-add-api's alias_of points at aid-create-api exactly.
get_row_field() {
    local name="$1" field="$2"
    awk -v target="  - name: ${name}" -v fieldpat="^    ${field}:" '
        $0 == target { in_row=1; next }
        in_row && /^  - name:/ { in_row=0 }
        in_row && $0 ~ fieldpat { sub(fieldpat "[[:space:]]*", ""); print; exit }
    ' "$CATALOG"
}

CREATE_API_VERB=$(get_row_field "aid-create-api" "verb")
CREATE_API_ARTIFACT=$(get_row_field "aid-create-api" "artifact")
ADD_API_VERB=$(get_row_field "aid-add-api" "verb")
ADD_API_ARTIFACT=$(get_row_field "aid-add-api" "artifact")
ADD_API_ALIAS_OF=$(get_row_field "aid-add-api" "alias_of")

assert_eq "$CREATE_API_VERB" "create" "CFS11a aid-create-api row: verb == create"
assert_eq "$CREATE_API_ARTIFACT" "api" "CFS11b aid-create-api row: artifact == api"
assert_eq "$ADD_API_VERB" "$CREATE_API_VERB" "CFS11c aid-add-api row: verb identical to aid-create-api's"
assert_eq "$ADD_API_ARTIFACT" "$CREATE_API_ARTIFACT" "CFS11d aid-add-api row: artifact identical to aid-create-api's"
assert_eq "$ADD_API_ALIAS_OF" "aid-create-api" "CFS11e aid-add-api row: alias_of == aid-create-api"

# CFS-12: aid-create-data-model row is MIGRATE-typed (the feature-003 reclassification).
DATA_MODEL_DEFAULT_TYPE=$(get_row_field "aid-create-data-model" "default_type")
assert_eq "$DATA_MODEL_DEFAULT_TYPE" "MIGRATE" "CFS12 aid-create-data-model row: default_type == MIGRATE"

# CFS-13: both generated doorways bind the identical VERB=`create` ARTIFACT=`api` pair.
CREATE_API_BODY=$(cat "${SKILLS_ROOT}/aid-create-api/SKILL.md" 2>/dev/null || true)
ADD_API_BODY=$(cat "${SKILLS_ROOT}/aid-add-api/SKILL.md" 2>/dev/null || true)
assert_output_contains "$CREATE_API_BODY" 'VERB=`create`' "CFS13a aid-create-api doorway binds VERB=\`create\`"
assert_output_contains "$CREATE_API_BODY" 'ARTIFACT=`api`' "CFS13b aid-create-api doorway binds ARTIFACT=\`api\`"
assert_output_contains "$ADD_API_BODY" 'VERB=`create`' "CFS13c aid-add-api doorway binds the identical VERB=\`create\`"
assert_output_contains "$ADD_API_BODY" 'ARTIFACT=`api`' "CFS13d aid-add-api doorway binds the identical ARTIFACT=\`api\`"
assert_output_contains "$ADD_API_BODY" 'thin alias of `aid-create-api`' "CFS13e aid-add-api doorway self-documents as a thin alias of aid-create-api"

# ===========================================================================
# Part 3 -- Fixture-shape assertions
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_create_api_fixture <work-dir> <shortcut-name>
# Hand-authors a flattened work mirroring what /aid-create-api (or its alias
# /aid-add-api) + shortcut-engine.md would produce, per create.md's own SPEC-section
# activation + task-breakdown template for the `api` artifact, halted at APPROVAL-HALT.
build_create_api_fixture() {
    local work_dir="$1" shortcut="$2"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002" "${work_dir}/tasks/task-003"

    cat > "${work_dir}/REQUIREMENTS.md" <<EOF
# Requirements

- **Name:** orders resource
- **Description:** Create an API endpoint for the orders resource.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: ${shortcut}) | /${shortcut} |

## 1. Objective

Build a new orders resource API endpoint.

## 2. Problem Statement

No orders resource endpoint exists yet.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=create, artifact=api. New endpoint only; no client changes.

## 5. Functional Requirements

Build the schema/model, the handler + persistence, and an integration test for the
orders resource.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given a valid request, when the orders endpoint is called, then it returns the
  expected response per the request/response schema.
- [ ] Given the integration test, when run, then it exercises the handler + persistence
  layer end to end.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<EOF
# orders resource

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /${shortcut} |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Build a new orders resource API endpoint.

## User Stories

- As an API consumer, I want an orders resource endpoint so I can create/read orders.

## Priority

Must

## Acceptance Criteria

- [ ] Given a valid request, when the orders endpoint is called, then it returns the
  expected response per the request/response schema.

---

## Technical Specification

### Data Model

The orders entity's persisted shape (fields inferred from the request/response schema).

### Feature Flow

Request -> validate -> handler -> persistence -> response.

### Layers & Components

The API layer (schema/model, handler, persistence) for the orders resource.

### API Contracts

Resource: orders. Endpoint path, request/response schema, and security notes captured
from the description; no security notes beyond standard auth were named.
EOF

    cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- orders resource

> **Work:** work-NNN-orders-resource-api
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- orders resource API
- **What it delivers:** the orders resource endpoint (schema, handler, persistence) + its
  integration test.
- **Features:** feature-001-orders-resource-api
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
# Delivery BLUEPRINT -- delivery-001: orders resource API

> **Delivery:** delivery-001
> **Work:** work-NNN-orders-resource-api
> **Created:** 2026-07-09

---

## Objective

Build a new orders resource API endpoint.

## Scope

verb=create, artifact=api.

**Out of scope:** client changes, broader test authoring beyond the one integration
test.

## Gate Criteria

- [ ] The endpoint returns the expected response per the request/response schema.
- [ ] The integration test exercises the handler + persistence layer end to end.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Schema/model for the orders resource |
| task-002 | IMPLEMENT | Handler + persistence for the orders resource |
| task-003 | TEST | Integration test for the orders resource endpoint |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /${shortcut} (create, artifact 'api').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: Schema/model for the orders resource

**Type:** IMPLEMENT

**Source:** work-NNN-orders-resource-api -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Define the orders entity schema/model.

**Acceptance Criteria:**
- [ ] The schema/model matches the request/response schema captured in SPEC.md.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<EOF
# task-002: Handler + persistence for the orders resource

**Type:** IMPLEMENT

**Source:** work-NNN-orders-resource-api -> delivery-001

**Depends on:** task-001

**Scope:**
- Implement the handler and its persistence layer for the orders resource.

**Acceptance Criteria:**
- [ ] Given a valid request, when the orders endpoint is called, then it returns the
  expected response.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-003/DETAIL.md" <<EOF
# task-003: Integration test for the orders resource endpoint

**Type:** TEST

**Source:** work-NNN-orders-resource-api -> delivery-001

**Depends on:** task-002

**Scope:**
- Integration test exercising the handler + persistence layer end to end.

**Acceptance Criteria:**
- [ ] The integration test exercises the handler + persistence layer end to end.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<EOF
# Work State -- work-NNN-orders-resource-api

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

# build_create_data_model_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-create-data-model +
# shortcut-engine.md would produce, per create.md's data-model row: MIGRATE ->
# IMPLEMENT -> TEST, ### Data Model + ### Migration Plan activated, halted pre-Execute.
build_create_data_model_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002" "${work_dir}/tasks/task-003"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** customer profile data model
- **Description:** Create the customer profile entity/schema.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-create-data-model) | /aid-create-data-model |

## 1. Objective

Build the customer profile entity/schema.

## 2. Problem Statement

No customer profile entity exists yet.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=create, artifact=data-model.

## 5. Functional Requirements

Define the schema + migration, wire the repo/model, and add a test.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the migration, when applied, then the customer_profile table exists with the
  captured relationships and validation rules.
- [ ] Given the rollback, when applied, then the table is removed cleanly.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# customer profile data model

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-create-data-model |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Build the customer profile entity/schema.

## User Stories

- As a service owner, I want a customer profile entity so other services can persist
  profile data.

## Priority

Must

## Acceptance Criteria

- [ ] Given the migration, when applied, then the customer_profile table exists with the
  captured relationships and validation rules.

---

## Technical Specification

### Data Model

The customer_profile entity: fields, relationships, and validation rules captured from
the description.

### Feature Flow

Define schema -> migrate -> wire repo/model -> test.

### Layers & Components

The data-access layer (repo/model) for the customer_profile entity.

### Migration Plan

Forward migration creates the customer_profile table; rollback drops it cleanly
(reversible, idempotent -- task-type-rules.md ## MIGRATE).
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- customer profile data model

> **Work:** work-NNN-customer-profile-data-model
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- customer profile data model
- **What it delivers:** the customer_profile schema + migration + repo/model wiring +
  test.
- **Features:** feature-001-customer-profile-data-model
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
# Delivery BLUEPRINT -- delivery-001: customer profile data model

> **Delivery:** delivery-001
> **Work:** work-NNN-customer-profile-data-model
> **Created:** 2026-07-09

---

## Objective

Build the customer profile entity/schema.

## Scope

verb=create, artifact=data-model.

**Out of scope:** consuming services' own migrations.

## Gate Criteria

- [ ] The migration creates the customer_profile table with the captured relationships
  and validation rules.
- [ ] The rollback removes the table cleanly.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | MIGRATE | Schema + migration for customer_profile |
| task-002 | IMPLEMENT | Repo/model wiring for customer_profile |
| task-003 | TEST | Test the customer_profile repo/model |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-create-data-model (create,
artifact 'data-model').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Schema + migration for customer_profile

**Type:** MIGRATE

**Source:** work-NNN-customer-profile-data-model -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Define the customer_profile entity/schema and its forward + rollback migration.

**Acceptance Criteria:**
- [ ] Given the migration, when applied, then the customer_profile table exists with the
  captured relationships and validation rules.
- [ ] Given the rollback, when applied, then the table is removed cleanly.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Repo/model wiring for customer_profile

**Type:** IMPLEMENT

**Source:** work-NNN-customer-profile-data-model -> delivery-001

**Depends on:** task-001

**Scope:**
- Wire the repo/model layer to the customer_profile schema.

**Acceptance Criteria:**
- [ ] The repo/model layer reads/writes the customer_profile table correctly.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-003/DETAIL.md" <<'EOF'
# task-003: Test the customer_profile repo/model

**Type:** TEST

**Source:** work-NNN-customer-profile-data-model -> delivery-001

**Depends on:** task-002

**Scope:**
- Test the customer_profile repo/model wiring, including the migration's forward +
  rollback path.

**Acceptance Criteria:**
- [ ] The test suite covers the repo/model layer against the customer_profile schema.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-customer-profile-data-model

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-create-data-model
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

# ---------------------------------------------------------------------------
# Fixture A: aid-create-api
# ---------------------------------------------------------------------------
API_DIR="${TMP}/work-create-api"
build_create_api_fixture "$API_DIR" "aid-create-api"

assert_file_contains "${API_DIR}/SPEC.md" "### API Contracts" \
    "CFS20 create-api fixture: SPEC.md activates ### API Contracts"
assert_file_contains "${API_DIR}/tasks/task-001/DETAIL.md" "**Type:** IMPLEMENT" \
    "CFS21 create-api fixture: task-001 is IMPLEMENT (schema)"
assert_file_contains "${API_DIR}/tasks/task-002/DETAIL.md" "**Type:** IMPLEMENT" \
    "CFS22 create-api fixture: task-002 is IMPLEMENT (handler+persistence)"
assert_file_contains "${API_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "CFS23 create-api fixture: task-002 depends on task-001"
assert_file_contains "${API_DIR}/tasks/task-003/DETAIL.md" "**Type:** TEST" \
    "CFS24 create-api fixture: task-003 is TEST (integration)"
assert_file_contains "${API_DIR}/tasks/task-003/DETAIL.md" "**Depends on:** task-002" \
    "CFS25 create-api fixture: task-003 depends on task-002"
assert_file_contains "${API_DIR}/PLAN.md" "| task-002 | task-001 |" \
    "CFS26a create-api fixture: PLAN.md Execution Graph carries task-002 -> task-001"
assert_file_contains "${API_DIR}/PLAN.md" "| task-003 | task-002 |" \
    "CFS26b create-api fixture: PLAN.md Execution Graph carries task-003 -> task-002"

# ---------------------------------------------------------------------------
# Fixture B: aid-create-data-model
# ---------------------------------------------------------------------------
DM_DIR="${TMP}/work-create-data-model"
build_create_data_model_fixture "$DM_DIR"

assert_file_contains "${DM_DIR}/SPEC.md" "### Migration Plan" \
    "CFS30 create-data-model fixture: SPEC.md activates ### Migration Plan"
assert_file_contains "${DM_DIR}/SPEC.md" "### Data Model" \
    "CFS31 create-data-model fixture: SPEC.md carries ### Data Model (mandatory section)"
assert_file_contains "${DM_DIR}/tasks/task-001/DETAIL.md" "**Type:** MIGRATE" \
    "CFS32 create-data-model fixture: task-001 is MIGRATE (the feature-003 reclassification)"
assert_file_contains "${DM_DIR}/tasks/task-002/DETAIL.md" "**Type:** IMPLEMENT" \
    "CFS33 create-data-model fixture: task-002 is IMPLEMENT (repo/model wiring)"
assert_file_contains "${DM_DIR}/tasks/task-003/DETAIL.md" "**Type:** TEST" \
    "CFS34 create-data-model fixture: task-003 is TEST"
assert_file_contains "${DM_DIR}/STATE.md" "**Active Skill:** aid-create-data-model" \
    "CFS35 create-data-model fixture: Active Skill is aid-create-data-model"

# ---------------------------------------------------------------------------
# Both fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$API_DIR" "$DM_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "CFS40 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for t in task-001 task-002 task-003; do
        assert_file_exists "${FIXTURE_DIR}/tasks/${t}/DETAIL.md" "CFS41 [${fixture_label}] tasks/${t}/DETAIL.md present"
        if [[ -f "${FIXTURE_DIR}/tasks/${t}/STATE.md" ]]; then
            fail "CFS42 [${fixture_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        else
            pass "CFS42 [${fixture_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        fi
    done

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "CFS43 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "CFS43 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "CFS44 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "CFS45 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "CFS46 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

# ===========================================================================
# Part 4 -- Alias-equivalence fixture-shape proof: aid-add-api == aid-create-api
# ===========================================================================
echo ""
echo "--- Part 4: alias-equivalence fixture-shape proof (aid-add-api == aid-create-api) ---"

ADD_DIR="${TMP}/work-add-api"
build_create_api_fixture "$ADD_DIR" "aid-add-api"

FILES_TO_COMPARE=(REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md
    tasks/task-001/DETAIL.md tasks/task-002/DETAIL.md tasks/task-003/DETAIL.md STATE.md)

alias_diff_found=0
for f in "${FILES_TO_COMPARE[@]}"; do
    create_norm=$(sed -e 's/aid-create-api/SHORTCUT/g' "${API_DIR}/${f}")
    add_norm=$(sed -e 's/aid-add-api/SHORTCUT/g' "${ADD_DIR}/${f}")
    if [[ "$create_norm" == "$add_norm" ]]; then
        pass "CFS50 [${f}] byte-identical after normalizing the invoking shortcut's own name"
    else
        fail "CFS50 [${f}] byte-identical after normalizing the invoking shortcut's own name -- diff found"
        alias_diff_found=1
        if [[ "$VERBOSE" -eq 1 ]]; then
            diff <(echo "$create_norm") <(echo "$add_norm") || true
        fi
    fi
done
if [[ "$alias_diff_found" -eq 0 ]]; then
    pass "CFS51 aid-add-api scaffolds the byte-identical work shape as aid-create-api (AC-1)"
else
    fail "CFS51 aid-add-api scaffolds the byte-identical work shape as aid-create-api (AC-1)"
fi

echo ""
test_summary
