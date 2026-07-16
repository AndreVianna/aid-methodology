#!/usr/bin/env bash
# test-prototype-family-scaffold.sh -- task-022 (work-001-lite-aid-skills, feature-005):
# aid-prototype family scaffold + halt proof.
#
# The shortcut engine + the prototype scaffolding reference are agent-executed PROSE, not
# executable scripts -- a deterministic canonical test cannot "run" /aid-prototype-ui. This
# suite is therefore CONTRACT + FIXTURE-SHAPE, matching the other work-001 shortcut-engine
# suites (test-fix-family-scaffold.sh, test-create-family-scaffold.sh,
# test-change-refactor-family-scaffold.sh, test-test-experiment-family-scaffold.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/prototype.md for the load-bearing
#      elements: aid-prototype's CAPTURE slots (fidelity-level enum) and DESIGN ->
#      [IMPLEMENT] breakdown, aid-prototype-ui's CAPTURE slots and ### UI Specs activation,
#      and the Ownership-boundary handoff to aid-create/aid-change (+ testing-with-users
#      routed to G7).
#   2. Catalog contract -- checked against the REAL catalog + skill dirs: exactly 2 G3 rows
#      (aid-prototype, aid-prototype-ui), both default_type DESIGN, neither carrying an
#      alias (feature-005 SPEC "Catalog rows owned" -- 2 canonical, no aliases).
#   3. Fixture-shape assertions -- two hand-authored flattened work fixtures mirroring what
#      `/aid-prototype-ui` and bare `/aid-prototype` would produce, both halted at
#      APPROVAL-HALT (pre-Execute). Proves the binding drives the correct DESIGN-typed
#      shape (feature-005's own testing strategy) for both family members.
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-prototype-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROTOTYPE_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/prototype.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-prototype family scaffold + halt proof (task-022, feature-005) ==="

assert_file_exists "$PROTOTYPE_SCAFFOLD" "PFS00a shortcut-scaffolding/prototype.md exists"
assert_file_exists "$CATALOG" "PFS00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "PFS00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

PROTO_TXT=$(cat "$PROTOTYPE_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/prototype.md
# ===========================================================================
echo "--- Part 1: prototype.md contract assertions ---"

# PFS-01: aid-prototype CAPTURE slots -- fidelity-level closed enum, default low-fi.
assert_output_contains "$PROTO_TXT" \
    'closed enum: `paper` \| `low-fi` \| `runnable spike`; default `low-fi`' \
    "PFS01a aid-prototype fidelity-level is a closed 3-enum (paper|low-fi|runnable spike), default low-fi"
assert_output_contains "$PROTO_TXT" \
    'Scope boundary | what the prototype does **not** attempt' \
    "PFS01b aid-prototype captures an explicit scope boundary (what it does NOT attempt)"

# PFS-02: aid-prototype-ui CAPTURE slots.
assert_output_contains "$PROTO_TXT" \
    'Target screen(s) / flow | the screen(s) or flow being wireframed' \
    "PFS02a aid-prototype-ui captures target screen(s)/flow"
assert_output_contains "$PROTO_TXT" \
    'Key interactions + states | the interactions and states to mock (loading, empty, error, success' \
    "PFS02b aid-prototype-ui captures key interactions + states"

# PFS-03: aid-prototype is a hand-authored collapse skill (work-005) -- it produces the
# throwaway model directly and emits NO SPEC.md and NO tasks; a prototype is throwaway
# (no schema change). (Was an engine family with a generated SPEC + task table; detached.)
assert_output_contains "$PROTO_TXT" \
    'emits no `SPEC.md`. A prototype is' \
    "PFS03a aid-prototype collapse emits no SPEC.md"
assert_output_contains "$PROTO_TXT" \
    'throwaway (no schema change)' \
    "PFS03b aid-prototype is throwaway (no schema change)"
assert_output_contains "$PROTO_TXT" \
    'it emits no tasks' \
    "PFS03c aid-prototype collapse emits no tasks"

# PFS-04: aid-prototype-ui likewise emits no SPEC.md (its interaction flow / a11y notes are
# part of the wireframe, not a ### UI Specs SPEC section).
assert_output_contains "$PROTO_TXT" \
    'A ui prototype likewise emits no `SPEC.md`' \
    "PFS04 aid-prototype-ui emits no SPEC.md"

# PFS-05: aid-prototype BUILD -- low-fidelity model + optional throwaway spike, never production.
assert_output_contains "$PROTO_TXT" \
    'the **low-fidelity model** of `{direction}`' \
    "PFS05a aid-prototype builds the low-fidelity model of {direction}"
assert_output_contains "$PROTO_TXT" \
    'optionally, a throwaway runnable spike' \
    "PFS05b aid-prototype optionally builds a throwaway runnable spike"
assert_output_contains "$PROTO_TXT" \
    'never a production build' \
    "PFS05c aid-prototype runnable spike is never a production build"

# PFS-06: aid-prototype-ui BUILD -- wireframe/mock + interaction flow, optional clickable flow.
assert_output_contains "$PROTO_TXT" \
    'a **wireframe/mock of `{screens}` + interaction flow**' \
    "PFS06a aid-prototype-ui builds a wireframe/mock + interaction flow"
assert_output_contains "$PROTO_TXT" \
    'optionally a clickable flow prototype' \
    "PFS06b aid-prototype-ui optionally builds a clickable flow prototype"

# PFS-07: Ownership boundary -- validates direction, not the production build; hands off to
# aid-create[-artifact]/aid-change; testing with users is G7.
assert_output_contains "$PROTO_TXT" \
    'A prototype **validates direction; it is not the production build**' \
    "PFS07a Ownership boundary: a prototype validates direction, is not the production build"
assert_output_contains "$PROTO_TXT" \
    'hand off to `aid-create[-artifact]` (or' \
    "PFS07b Ownership boundary: hands off to aid-create[-artifact] (wrap point 1)"
assert_output_contains "$PROTO_TXT" \
    '`aid-change` when the target already exists) -- prototype work never touches production' \
    "PFS07c Ownership boundary: or aid-change when the target already exists (wrap point 2)"
assert_output_contains "$PROTO_TXT" \
    'is a G7 activity' \
    "PFS07d Ownership boundary: testing the prototype with real users is a G7 activity (wrap point 1)"
assert_output_contains "$PROTO_TXT" \
    '(`aid-experiment` / `aid-test`), not part of this' \
    "PFS07e Ownership boundary: testing routes to aid-experiment/aid-test (wrap point 2)"

echo ""
echo "--- Part 2: catalog contract (checked against the real catalog + skill dirs) ---"

get_row_field() {
    local name="$1" field="$2"
    awk -v target="  - name: ${name}" -v fieldpat="^    ${field}:" '
        $0 == target { in_row=1; next }
        in_row && /^  - name:/ { in_row=0 }
        in_row && $0 ~ fieldpat { sub(fieldpat "[[:space:]]*", ""); gsub(/"/, "", $0); print; exit }
    ' "$CATALOG"
}

# PFS-10: exactly 2 G3 rows exist, each with the aid- prefix and a matching skill dir.
G3_NAMES=(aid-prototype aid-prototype-ui)
for name in "${G3_NAMES[@]}"; do
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "PFS10 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "PFS10 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "PFS10 [${name}] SKILL.md exists"
done

# PFS-11: default_type mapping -- both prototype rows -> DESIGN (feature-005 A-6 mapping).
for name in "${G3_NAMES[@]}"; do
    dt=$(get_row_field "$name" "default_type")
    assert_eq "$dt" "DESIGN" "PFS11 [${name}] row: default_type == DESIGN"
    grp=$(get_row_field "$name" "group")
    assert_eq "$grp" "G3" "PFS11 [${name}] row: group == G3"
done

# PFS-12: verb/artifact binding -- both share verb=prototype; artifact "" vs "ui".
VERB_PROTO=$(get_row_field "aid-prototype" "verb")
assert_eq "$VERB_PROTO" "prototype" "PFS12a aid-prototype row: verb == prototype"
ARTIFACT_PROTO=$(get_row_field "aid-prototype" "artifact")
assert_eq "$ARTIFACT_PROTO" "" "PFS12b aid-prototype row: artifact == \"\" (bare)"
VERB_PROTO_UI=$(get_row_field "aid-prototype-ui" "verb")
assert_eq "$VERB_PROTO_UI" "prototype" "PFS12c aid-prototype-ui row: verb == prototype"
ARTIFACT_PROTO_UI=$(get_row_field "aid-prototype-ui" "artifact")
assert_eq "$ARTIFACT_PROTO_UI" "ui" "PFS12d aid-prototype-ui row: artifact == ui"

# PFS-13: no alias on either row (feature-005 SPEC "2 canonical, no aliases").
for name in "${G3_NAMES[@]}"; do
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "PFS13 [${name}] row: alias_of == null (no alias family)"
done

# PFS-14: no aid-prototype-* directory beyond the one -ui suffix (no other artifact variant).
EXTRA_DIRS=$(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'aid-prototype-*' ! -name 'aid-prototype-ui' 2>/dev/null || true)
if [[ -z "$EXTRA_DIRS" ]]; then
    pass "PFS14 no canonical/skills/aid-prototype-* directory exists beyond aid-prototype-ui"
else
    fail "PFS14 no canonical/skills/aid-prototype-* directory exists beyond aid-prototype-ui -- found: ${EXTRA_DIRS}"
fi

# ===========================================================================
# Part 3 -- Fixture-shape assertions (aid-prototype-ui + bare aid-prototype)
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_prototype_ui_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-prototype-ui + shortcut-engine.md
# would produce: ### UI Specs activated, Data Model "no schema changes", single task-001
# DESIGN (wireframe/mock + interaction flow), halted pre-Execute.
build_prototype_ui_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** one-page checkout flow UI prototype
- **Description:** Wireframe/mock a simplified one-page checkout flow to validate whether
  collapsing cart -> shipping -> payment into a single screen reduces confusion.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-prototype-ui) | /aid-prototype-ui |

## 1. Objective

Wireframe/mock the simplified one-page checkout flow and its interaction states to
validate the collapsed-checkout direction before committing to a build.

## 2. Problem Statement

Checkout currently spans three separate pages; whether collapsing it to one page reduces
confusion is untested.

## 3. Users & Stakeholders

The requesting product owner/maintainer.

## 4. Scope

Target screen/flow: the checkout page (cart -> shipping -> payment collapsed to one
screen). Key interactions + states: form entry, payment step, loading, empty, error,
success. Visual reference: none supplied. Navigation/placement context: reached from the
cart page's "Proceed to checkout" button. This is a throwaway wireframe/mock, not a
production build.

## 5. Functional Requirements

Wireframe/mock the one-page checkout flow's screens, interactions, and states (loading,
empty, error, success), with accessibility notes.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the wireframe/mock, when reviewed, then it covers the checkout screen's key
  interactions and states (loading, empty, error, success).
- [ ] Given the wireframe/mock, when reviewed, then it carries accessibility notes.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# one-page checkout flow UI prototype

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-prototype-ui |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Wireframe/mock the simplified one-page checkout flow to validate the collapsed-checkout
direction.

## User Stories

- As an AID adopter validating a UX direction, I want a wireframe/mock of the one-page
  checkout flow so the direction is validated before a full build.

## Priority

Should

## Acceptance Criteria

- [ ] Given the wireframe/mock, when reviewed, then it covers the checkout screen's key
  interactions and states.

---

## Technical Specification

### Data Model

No schema changes -- this prototype is throwaway.

### Feature Flow

Cart -> collapsed checkout screen (shipping + payment inline) -> confirmation; states:
loading, empty, error, success.

### Layers & Components

The checkout page's presentation layer only -- no backend wiring.

### UI Specs

Screen: the collapsed one-page checkout (cart -> shipping -> payment). States: loading,
empty, error, success. Navigation: reached from the cart page's "Proceed to checkout"
button. Accessibility note: focus order follows the form's visual order; error states
carry an accessible error summary (task-type-rules.md ## DESIGN accessibility
consideration).
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- one-page checkout flow UI prototype

> **Work:** work-NNN-checkout-flow-ui-prototype
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- one-page checkout flow UI prototype
- **What it delivers:** the wireframe/mock of the collapsed checkout flow + its
  interaction states.
- **Features:** feature-001-checkout-flow-ui-prototype
- **Depends on:** -- (none)
- **Priority:** Should

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

    cat > "${work_dir}/BLUEPRINT.md" <<'EOF'
# Delivery BLUEPRINT -- delivery-001: one-page checkout flow UI prototype

> **Delivery:** delivery-001
> **Work:** work-NNN-checkout-flow-ui-prototype
> **Created:** 2026-07-09

---

## Objective

Wireframe/mock the simplified one-page checkout flow to validate the collapsed-checkout
direction.

## Scope

Target screen/flow: the checkout page. Key interactions + states: form entry, payment
step, loading, empty, error, success.

**Out of scope:** the production build of the collapsed checkout flow (routes to
aid-create/aid-change) and usability testing with real users (routes to aid-experiment /
aid-test).

## Gate Criteria

- [ ] The wireframe/mock covers the checkout screen's key interactions and states.
- [ ] The wireframe/mock carries accessibility notes.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DESIGN | Wireframe/mock the one-page checkout flow + interaction flow (states, transitions, a11y notes) |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-prototype-ui (prototype, artifact
'ui').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Wireframe/mock the one-page checkout flow + interaction flow

**Type:** DESIGN

**Source:** work-NNN-checkout-flow-ui-prototype -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Wireframe/mock the collapsed one-page checkout flow (cart -> shipping -> payment) and
  its interaction flow (states: loading, empty, error, success; transitions between
  them), with accessibility notes.

**Acceptance Criteria:**
- [ ] Given the wireframe/mock, when reviewed, then it covers the checkout screen's key
  interactions and states (loading, empty, error, success).
- [ ] Given the wireframe/mock, when reviewed, then it carries accessibility notes.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-checkout-flow-ui-prototype

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-prototype-ui
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
EOF
}

# build_prototype_bare_fixture <work-dir>
# Hand-authors a flattened work mirroring what bare /aid-prototype + shortcut-engine.md
# would produce: no ### UI Specs, Data Model "no schema changes", task-001 DESIGN + an
# optional task-002 IMPLEMENT throwaway spike, halted pre-Execute.
build_prototype_bare_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** shared-doc live-cursor direction prototype
- **Description:** Validate whether showing other editors' live cursors in the shared
  doc editor reduces accidental overwrite conflicts.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-prototype) | /aid-prototype |

## 1. Objective

Validate the live-cursor direction with a throwaway runnable spike before committing to
a real-time sync backend.

## 2. Problem Statement

Concurrent editors in the shared doc editor sometimes overwrite each other's changes;
whether showing live cursors would prevent this is untested.

## 3. Users & Stakeholders

The requesting product owner/maintainer.

## 4. Scope

Direction/hypothesis: showing other editors' live cursors reduces accidental overwrite
conflicts. Fidelity level: runnable spike (a working model is required to observe cursor
movement). Success signal: testers notice another cursor and avoid editing that region
without being told to. Scope boundary: no real-time sync backend, no persistence, no
conflict resolution -- only cursor-position broadcast over a mocked channel.

## 5. Functional Requirements

Build the low-fidelity model of the live-cursor direction and a throwaway runnable spike
that demonstrates cursor movement over a mocked channel, to capture the validation
signal.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the low-fidelity model, when reviewed, then it names the direction, the
  success signal, and the explicit scope boundary.
- [ ] Given the runnable spike, when run, then testers can observe another cursor's
  position update in near-real time over the mocked channel.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# shared-doc live-cursor direction prototype

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-prototype |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Validate the live-cursor direction with a throwaway runnable spike.

## User Stories

- As an AID adopter validating a direction, I want a low-fidelity model plus a runnable
  spike so the live-cursor hypothesis is validated before a real build.

## Priority

Should

## Acceptance Criteria

- [ ] Given the runnable spike, when run, then testers can observe another cursor's
  position update in near-real time.

---

## Technical Specification

### Data Model

No schema changes -- this prototype is throwaway.

### Feature Flow

Direction: live cursors reduce overwrite conflicts. Validation narrative: build the
low-fidelity model -> run the throwaway spike over a mocked channel -> observe whether
testers notice and avoid the occupied region -> capture the success signal.

### Layers & Components

A single throwaway spike component broadcasting mocked cursor positions; no production
module is touched.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- shared-doc live-cursor direction prototype

> **Work:** work-NNN-live-cursor-direction-prototype
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- shared-doc live-cursor direction prototype
- **What it delivers:** the low-fidelity model + the throwaway runnable spike that
  captures the validation signal.
- **Features:** feature-001-live-cursor-direction-prototype
- **Depends on:** -- (none)
- **Priority:** Should

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

    cat > "${work_dir}/BLUEPRINT.md" <<'EOF'
# Delivery BLUEPRINT -- delivery-001: shared-doc live-cursor direction prototype

> **Delivery:** delivery-001
> **Work:** work-NNN-live-cursor-direction-prototype
> **Created:** 2026-07-09

---

## Objective

Validate the live-cursor direction before committing to a real-time sync backend.

## Scope

Direction: live cursors reduce overwrite conflicts. Fidelity: runnable spike.

**Out of scope:** the real-time sync backend / production build (routes to
aid-create/aid-change) and usability testing with real users (routes to aid-experiment /
aid-test).

## Gate Criteria

- [ ] The low-fidelity model names the direction, the success signal, and the explicit
  scope boundary.
- [ ] The runnable spike lets testers observe another cursor's position update.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DESIGN | Build the low-fidelity model of the live-cursor direction and capture the validation signal |
| task-002 | IMPLEMENT | Throwaway runnable spike demonstrating cursor-position broadcast over a mocked channel |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-prototype (prototype, artifact '').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Build the low-fidelity model of the live-cursor direction

**Type:** DESIGN

**Source:** work-NNN-live-cursor-direction-prototype -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Build the low-fidelity model of the live-cursor direction and capture the validation
  signal (testers notice another cursor and avoid editing that region).

**Acceptance Criteria:**
- [ ] Given the low-fidelity model, when reviewed, then it names the direction, the
  success signal, and the explicit scope boundary.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Throwaway runnable spike -- cursor-position broadcast over a mocked channel

**Type:** IMPLEMENT

**Source:** work-NNN-live-cursor-direction-prototype -> delivery-001

**Depends on:** task-001

**Scope:**
- Build a throwaway runnable spike (no real-time sync backend, no persistence, no
  conflict resolution) that broadcasts mocked cursor positions so testers can observe
  another cursor's position update in near-real time. This is not a production build.

**Acceptance Criteria:**
- [ ] Given the runnable spike, when run, then testers can observe another cursor's
  position update in near-real time over the mocked channel.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-live-cursor-direction-prototype

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-prototype
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
EOF
}

# ---------------------------------------------------------------------------
# Fixture A: aid-prototype-ui (the literal fixture named by task-022's Scope)
# ---------------------------------------------------------------------------
UI_DIR="${TMP}/work-prototype-ui"
build_prototype_ui_fixture "$UI_DIR"

assert_file_contains "${UI_DIR}/SPEC.md" "### UI Specs" \
    "PFS20 prototype-ui fixture: SPEC.md activates ### UI Specs"
assert_file_contains "${UI_DIR}/SPEC.md" "No schema changes -- this prototype is throwaway." \
    "PFS21 prototype-ui fixture: SPEC.md Data Model reads no schema changes"
assert_file_contains "${UI_DIR}/tasks/task-001/DETAIL.md" "**Type:** DESIGN" \
    "PFS22 prototype-ui fixture: task-001 is DESIGN"
UI_TASK_COUNT=$(find "${UI_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$UI_TASK_COUNT" "1" "PFS23 prototype-ui fixture: single-task shape (task-001 only)"
assert_file_contains "${UI_DIR}/STATE.md" "**Active Skill:** aid-prototype-ui" \
    "PFS24 prototype-ui fixture: Active Skill is aid-prototype-ui"

# ---------------------------------------------------------------------------
# Fixture B: bare aid-prototype (proves the family's DESIGN default + optional spike)
# ---------------------------------------------------------------------------
BARE_DIR="${TMP}/work-prototype-bare"
build_prototype_bare_fixture "$BARE_DIR"

if grep -q "### UI Specs" "${BARE_DIR}/SPEC.md"; then
    fail "PFS30 prototype-bare fixture: SPEC.md does NOT activate ### UI Specs (bare aid-prototype)"
else
    pass "PFS30 prototype-bare fixture: SPEC.md does NOT activate ### UI Specs (bare aid-prototype)"
fi
assert_file_contains "${BARE_DIR}/tasks/task-001/DETAIL.md" "**Type:** DESIGN" \
    "PFS31 prototype-bare fixture: task-001 is DESIGN"
assert_file_contains "${BARE_DIR}/tasks/task-002/DETAIL.md" "**Type:** IMPLEMENT" \
    "PFS32 prototype-bare fixture: task-002 is IMPLEMENT (throwaway spike)"
assert_file_contains "${BARE_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "PFS33 prototype-bare fixture: task-002 depends on task-001"
assert_file_contains "${BARE_DIR}/tasks/task-002/DETAIL.md" "This is not a production build." \
    "PFS34 prototype-bare fixture: task-002 is explicitly not a production build"
assert_file_contains "${BARE_DIR}/STATE.md" "**Active Skill:** aid-prototype" \
    "PFS35 prototype-bare fixture: Active Skill is bare aid-prototype"

# ---------------------------------------------------------------------------
# Both fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$UI_DIR" "$BARE_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "PFS40 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for section in "### Data Model" "### Feature Flow" "### Layers & Components"; do
        assert_file_contains "${FIXTURE_DIR}/SPEC.md" "$section" \
            "PFS41 [${fixture_label}] SPEC.md carries mandatory section ${section} (engine contract: mandatory three always apply)"
    done
    assert_file_exists "${FIXTURE_DIR}/tasks/task-001/DETAIL.md" "PFS42 [${fixture_label}] tasks/task-001/DETAIL.md present"
    if [[ -f "${FIXTURE_DIR}/tasks/task-001/STATE.md" ]]; then
        fail "PFS43 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    else
        pass "PFS43 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    fi

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "PFS44 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "PFS44 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "PFS45 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "PFS46 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "PFS47 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

echo ""
test_summary
