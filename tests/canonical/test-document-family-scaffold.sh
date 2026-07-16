#!/usr/bin/env bash
# test-document-family-scaffold.sh -- task-024 (work-001-lite-aid-skills, feature-010):
# aid-document family scaffold + halt proof (archetype-selects-structure test).
#
# The shortcut engine + the document scaffolding reference are agent-executed PROSE, not
# executable scripts -- a deterministic canonical test cannot "run" /aid-document-decision.
# This suite is therefore CONTRACT + FIXTURE-SHAPE, matching the other work-001
# shortcut-engine suites (test-fix-family-scaffold.sh, test-create-family-scaffold.sh,
# test-prototype-family-scaffold.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/document.md for the load-bearing
#      elements: the per-archetype CAPTURE slots, the "all 8 -> single DOCUMENT task-001"
#      contract, the exact per-archetype document-shape rows (ADR
#      Context->Decision->Alternatives->Consequences; runbook
#      trigger->diagnostic->remediation->escalation; the other 6 shapes), and the
#      Ownership-boundary cession of analytical reports to G11.
#   2. Catalog contract -- checked against the REAL catalog + skill dirs: exactly 8 G8 rows,
#      all default_type DOCUMENT, none carrying an alias (feature-010 SPEC "Catalog rows
#      owned" -- 8 canonical, no aliases).
#   3. Fixture-shape assertions -- two hand-authored flattened work fixtures mirroring what
#      `/aid-document-decision` and `/aid-document-runbook` would produce, proving the
#      artifact suffix selects the archetype's document STRUCTURE (not a synonym) --
#      each carries the OTHER archetype's shape nowhere. Both halted at APPROVAL-HALT
#      (pre-Execute).
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-document-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/document.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-document family scaffold + halt proof (task-024, feature-010) ==="

assert_file_exists "$DOC_SCAFFOLD" "DFS00a shortcut-scaffolding/document.md exists"
assert_file_exists "$CATALOG" "DFS00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "DFS00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

DOC_TXT=$(cat "$DOC_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/document.md
# ===========================================================================
echo "--- Part 1: document.md contract assertions ---"

# DFS-01: per-archetype CAPTURE slots -- decision + runbook rows (the two fixture archetypes).
assert_output_contains "$DOC_TXT" \
    '| `aid-document-decision` | the decision; alternatives considered; consequences |' \
    "DFS01a aid-document-decision CAPTURE: the decision; alternatives considered; consequences"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-runbook` | the trigger/alert; diagnostic + remediation steps; escalation path |' \
    "DFS01b aid-document-runbook CAPTURE: the trigger/alert; diagnostic + remediation steps; escalation path"

# DFS-02: document is a hand-authored collapse artifact (work-005) -- the body produces the
# document directly, emits no separate SPEC.md, and activates no ## Technical Specification.
# (Was an engine family with a generated SPEC carrying the mandatory three; now detached.)
assert_output_contains "$DOC_TXT" \
    'The hand-authored collapse body produces the document **directly** and emits no separate' \
    "DFS02a collapse produces the document directly, emits no separate SPEC.md"
assert_output_contains "$DOC_TXT" \
    'there is no `## Technical Specification` to activate and no schema change' \
    "DFS02b no ## Technical Specification to activate (no schema change)"

# DFS-03: DETAIL -- the collapse emits no task or SPEC artifact (aid-create-document writes
# the document directly). (Was: one generated DOCUMENT task-001 per archetype; now detached.)
assert_output_contains "$DOC_TXT" \
    'the collapse emits no task or SPEC artifact' \
    "DFS03a collapse emits no task or SPEC artifact"

# DFS-04: exact per-archetype document-shape rows (the DETAIL table).
assert_output_contains "$DOC_TXT" \
    '| `aid-document-decision` | ADR: **Context -> Decision -> Alternatives -> Consequences** |' \
    "DFS04a aid-document-decision shape: ADR Context -> Decision -> Alternatives -> Consequences"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-runbook` | operational: **trigger -> diagnostic -> remediation -> escalation** |' \
    "DFS04b aid-document-runbook shape: operational trigger -> diagnostic -> remediation -> escalation"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-architecture` | components, boundaries, interactions, **C4/arc42 diagrams (Mermaid)** |' \
    "DFS04c aid-document-architecture shape: components/boundaries/interactions, C4/arc42 (Mermaid)"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-guideline` | advisory: **principle -> rationale -> do/don'"'"'t examples** |' \
    "DFS04d aid-document-guideline shape: advisory principle -> rationale -> do/don't examples"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-standard` | mandatory: **rule -> scope -> compliance/enforcement -> exceptions** |' \
    "DFS04e aid-document-standard shape: mandatory rule -> scope -> compliance/enforcement -> exceptions"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-tutorial` | learning: **prerequisites -> worked steps -> outcome** |' \
    "DFS04f aid-document-tutorial shape: learning prerequisites -> worked steps -> outcome"
assert_output_contains "$DOC_TXT" \
    '| `aid-document-changelog` | **[Added]/[Changed]/[Fixed]/[Removed]/[Security]** release notes |' \
    "DFS04g aid-document-changelog shape: [Added]/[Changed]/[Fixed]/[Removed]/[Security] release notes"
assert_output_contains "$DOC_TXT" \
    '| `aid-document` (general) | Diataxis how-to / reference / explanation **or** status/progress report, per the captured shape |' \
    "DFS04h aid-document (general) shape: Diataxis how-to/reference/explanation OR status/progress report"

# DFS-05: aid-document-decision extends the baseline ADR format with an explicit
# Alternatives step (two-phrase -- wraps source lines).
assert_output_contains "$DOC_TXT" \
    "extends \`task-type-rules.md ## DOCUMENT\`'s baseline Context -> Decision ->" \
    "DFS05a aid-document-decision extends task-type-rules.md baseline ADR format (wrap point 1)"
assert_output_contains "$DOC_TXT" \
    'Consequences ADR format with an explicit Alternatives step (feature-010 SPEC).' \
    "DFS05b aid-document-decision adds an explicit Alternatives step (wrap point 2)"

# DFS-06: Ownership boundary -- doc/content wholly aid-document; analytical reports cede to
# G11; only status/progress stays here.
assert_output_contains "$DOC_TXT" \
    '**Doc/content belongs wholly to `aid-document`.**' \
    "DFS06a Ownership boundary: doc/content belongs wholly to aid-document"
assert_output_contains "$DOC_TXT" \
    '**Analytical** reports (insight derived from data) cede to `aid-report` (G11) --' \
    "DFS06b Ownership boundary: analytical reports cede to aid-report (G11)"
assert_output_contains "$DOC_TXT" \
    'only the **status/progress**' \
    "DFS06c Ownership boundary: only the status/progress half stays here (wrap point 1)"
assert_output_contains "$DOC_TXT" \
    'half of the legacy `add-report`/`change-report` recipes (narration of known state)' \
    "DFS06d Ownership boundary: half of the legacy add-report/change-report recipes (wrap point 2)"

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

# DFS-10: exactly 8 G8 rows exist, each with the aid- prefix and a matching skill dir.
G8_NAMES=(aid-document aid-document-decision aid-document-architecture aid-document-guideline aid-document-standard aid-document-runbook aid-document-tutorial aid-document-changelog)
for name in "${G8_NAMES[@]}"; do
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "DFS10 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "DFS10 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "DFS10 [${name}] SKILL.md exists"
done

# DFS-11: default_type mapping -- all 8 -> DOCUMENT; all group G8.
for name in "${G8_NAMES[@]}"; do
    dt=$(get_row_field "$name" "default_type")
    assert_eq "$dt" "DOCUMENT" "DFS11 [${name}] row: default_type == DOCUMENT"
    grp=$(get_row_field "$name" "group")
    assert_eq "$grp" "G8" "DFS11 [${name}] row: group == G8"
done

# DFS-12: no alias on any row (feature-010 SPEC "8 canonical, no aliases").
for name in "${G8_NAMES[@]}"; do
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "DFS12 [${name}] row: alias_of == null (no alias family)"
done

# DFS-13: artifact suffix selects the structure -- decision/runbook rows carry the expected
# artifact value, verb=document.
DECISION_ARTIFACT=$(get_row_field "aid-document-decision" "artifact")
assert_eq "$DECISION_ARTIFACT" "decision" "DFS13a aid-document-decision row: artifact == decision"
RUNBOOK_ARTIFACT=$(get_row_field "aid-document-runbook" "artifact")
assert_eq "$RUNBOOK_ARTIFACT" "runbook" "DFS13b aid-document-runbook row: artifact == runbook"
for name in "${G8_NAMES[@]}"; do
    verb=$(get_row_field "$name" "verb")
    assert_eq "$verb" "document" "DFS13c [${name}] row: verb == document"
done

# DFS-14: no aid-document-* directory beyond the 7 named archetype suffixes (no stray 9th).
EXTRA_DIRS=$(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'aid-document-*' \
    ! -name 'aid-document-decision' ! -name 'aid-document-architecture' \
    ! -name 'aid-document-guideline' ! -name 'aid-document-standard' \
    ! -name 'aid-document-runbook' ! -name 'aid-document-tutorial' \
    ! -name 'aid-document-changelog' 2>/dev/null || true)
if [[ -z "$EXTRA_DIRS" ]]; then
    pass "DFS14 no canonical/skills/aid-document-* directory exists beyond the 7 named archetypes"
else
    fail "DFS14 no canonical/skills/aid-document-* directory exists beyond the 7 named archetypes -- found: ${EXTRA_DIRS}"
fi

# ===========================================================================
# Part 3 -- Fixture-shape assertions (aid-document-decision + aid-document-runbook)
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_document_decision_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-document-decision +
# shortcut-engine.md would produce: single task-001 DOCUMENT whose Scope requires the
# Context -> Decision -> Alternatives -> Consequences ADR structure, halted pre-Execute.
build_document_decision_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** ADR -- order-processing message queue choice
- **Description:** Document the decision to adopt Kafka over RabbitMQ/SQS for the
  order-processing pipeline.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-document-decision) | /aid-document-decision |

## 1. Objective

Write the ADR recording the message-queue decision for the order-processing pipeline.

## 2. Problem Statement

The order-processing pipeline needs a message queue; the choice among Kafka, RabbitMQ,
and SQS has been made informally and is undocumented.

## 3. Users & Stakeholders

The requesting architect/maintainer; future engineers reading the decision record.

## 4. Scope

Subject: message-queue choice for order-processing. Audience: engineering team. The
decision: adopt Kafka. Alternatives considered: RabbitMQ, SQS. Consequences: higher
operational complexity, higher sustained throughput, at-least-once delivery semantics.

## 5. Functional Requirements

Write the ADR following Context -> Decision -> Alternatives -> Consequences.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the ADR, when reviewed, then it contains Context, Decision, Alternatives, and
  Consequences sections in that order.
- [ ] Given the ADR's Alternatives section, when reviewed, then it names RabbitMQ and SQS
  and states why each was not chosen.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# ADR -- order-processing message queue choice

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-document-decision |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Write the ADR recording the message-queue decision for the order-processing pipeline.

## User Stories

- As an engineer reading the codebase later, I want the message-queue decision recorded
  as an ADR so the rationale and rejected alternatives are not lost.

## Priority

Should

## Acceptance Criteria

- [ ] Given the ADR, when reviewed, then it contains Context, Decision, Alternatives, and
  Consequences sections in that order.

---

## Technical Specification

### Data Model

No schema changes -- this work only documents an already-made decision.

### Feature Flow

Gather context -> state the decision -> enumerate alternatives considered (and why
rejected) -> state consequences.

### Layers & Components

The order-processing pipeline's messaging layer (documentation only -- no code change).
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- ADR -- order-processing message queue choice

> **Work:** work-NNN-adr-order-processing-mq-choice
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- ADR: order-processing message queue choice
- **What it delivers:** the ADR document.
- **Features:** feature-001-adr-order-processing-mq-choice
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
# Delivery BLUEPRINT -- delivery-001: ADR -- order-processing message queue choice

> **Delivery:** delivery-001
> **Work:** work-NNN-adr-order-processing-mq-choice
> **Created:** 2026-07-09

---

## Objective

Write the ADR recording the message-queue decision for the order-processing pipeline.

## Scope

verb=document, artifact=decision. Subject: message-queue choice. Decision: Kafka.
Alternatives: RabbitMQ, SQS.

**Out of scope:** implementing the Kafka migration itself (routes to
aid-change-infra/aid-refactor); this work documents the decision only.

## Gate Criteria

- [ ] The ADR contains Context, Decision, Alternatives, and Consequences sections in
  that order.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Write the ADR: Context -> Decision -> Alternatives -> Consequences |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-document-decision (document,
artifact 'decision').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Write the ADR -- order-processing message queue choice

**Type:** DOCUMENT

**Source:** work-NNN-adr-order-processing-mq-choice -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Write the ADR following the Context -> Decision -> Alternatives -> Consequences
  structure: Context (why a message queue is needed), Decision (adopt Kafka),
  Alternatives (RabbitMQ, SQS, and why each was not chosen), Consequences (operational
  complexity, throughput, delivery semantics).

**Acceptance Criteria:**
- [ ] Given the ADR, when reviewed, then it contains Context, Decision, Alternatives,
  and Consequences sections in that order.
- [ ] Given the ADR's Alternatives section, when reviewed, then it names RabbitMQ and
  SQS and states why each was not chosen.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-adr-order-processing-mq-choice

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-document-decision
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

# build_document_runbook_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-document-runbook +
# shortcut-engine.md would produce: single task-001 DOCUMENT whose Scope requires the
# trigger -> diagnostic -> remediation -> escalation runbook structure, halted pre-Execute.
build_document_runbook_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** runbook -- checkout-service high-latency alert
- **Description:** Write the operational runbook for responding to the checkout-service
  high-latency alert.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-document-runbook) | /aid-document-runbook |

## 1. Objective

Write the runbook that guides an on-call responder through the checkout-service
high-latency alert.

## 2. Problem Statement

The checkout-service high-latency alert currently pages on-call with no documented
response procedure.

## 3. Users & Stakeholders

The on-call responder; the SRE/maintainer team.

## 4. Scope

Subject: checkout-service high-latency alert response. Audience: on-call responders.
Trigger/alert: p99 latency > 2s for 5 minutes on the checkout service. Diagnostic steps:
check downstream payment-provider latency, check DB connection-pool saturation.
Remediation steps: fail over to the secondary payment provider, scale the connection
pool. Escalation path: page the checkout-service owning team if unresolved after 15
minutes.

## 5. Functional Requirements

Write the runbook following trigger -> diagnostic -> remediation -> escalation.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the runbook, when reviewed, then it contains trigger, diagnostic,
  remediation, and escalation sections in that order.
- [ ] Given the escalation section, when reviewed, then it names who to page and after
  how long.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# runbook -- checkout-service high-latency alert

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-document-runbook |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Write the operational runbook for the checkout-service high-latency alert.

## User Stories

- As an on-call responder, I want a runbook for the high-latency alert so I know exactly
  what to check and who to page without guessing.

## Priority

Should

## Acceptance Criteria

- [ ] Given the runbook, when reviewed, then it contains trigger, diagnostic,
  remediation, and escalation sections in that order.

---

## Technical Specification

### Data Model

No schema changes -- this work only documents an operational response procedure.

### Feature Flow

Trigger fires -> responder runs the diagnostic steps -> responder applies the
remediation steps -> if unresolved, responder escalates per the escalation path.

### Layers & Components

The checkout service and its payment-provider + DB connection-pool dependencies
(documentation only -- no code change).
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- runbook -- checkout-service high-latency alert

> **Work:** work-NNN-runbook-checkout-high-latency
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- runbook: checkout-service high-latency alert
- **What it delivers:** the operational runbook document.
- **Features:** feature-001-runbook-checkout-high-latency
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
# Delivery BLUEPRINT -- delivery-001: runbook -- checkout-service high-latency alert

> **Delivery:** delivery-001
> **Work:** work-NNN-runbook-checkout-high-latency
> **Created:** 2026-07-09

---

## Objective

Write the runbook for the checkout-service high-latency alert.

## Scope

verb=document, artifact=runbook. Trigger: p99 latency > 2s for 5 minutes. Escalation:
page the owning team after 15 minutes unresolved.

**Out of scope:** the observability wiring the alert itself depends on (routes to
aid-change-infra/aid-monitor); this work documents the response procedure only.

## Gate Criteria

- [ ] The runbook contains trigger, diagnostic, remediation, and escalation sections in
  that order.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Write the runbook: trigger -> diagnostic -> remediation -> escalation |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-document-runbook (document,
artifact 'runbook').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Write the runbook -- checkout-service high-latency alert

**Type:** DOCUMENT

**Source:** work-NNN-runbook-checkout-high-latency -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Write the runbook following the trigger -> diagnostic -> remediation -> escalation
  structure: Trigger (p99 latency > 2s for 5 minutes), Diagnostic (check downstream
  payment-provider latency, check DB connection-pool saturation), Remediation (fail over
  to the secondary payment provider, scale the connection pool), Escalation (page the
  checkout-service owning team if unresolved after 15 minutes).

**Acceptance Criteria:**
- [ ] Given the runbook, when reviewed, then it contains trigger, diagnostic,
  remediation, and escalation sections in that order.
- [ ] Given the escalation section, when reviewed, then it names who to page and after
  how long.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-runbook-checkout-high-latency

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-document-runbook
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

# ---------------------------------------------------------------------------
# Fixture A: aid-document-decision
# ---------------------------------------------------------------------------
DECISION_DIR="${TMP}/work-document-decision"
build_document_decision_fixture "$DECISION_DIR"

assert_file_contains "${DECISION_DIR}/tasks/task-001/DETAIL.md" "**Type:** DOCUMENT" \
    "DFS20 decision fixture: task-001 is DOCUMENT"
assert_file_contains "${DECISION_DIR}/tasks/task-001/DETAIL.md" \
    "Context -> Decision -> Alternatives -> Consequences" \
    "DFS21 decision fixture: task-001 Scope requires the ADR Context -> Decision -> Alternatives -> Consequences structure"
DECISION_TASK_COUNT=$(find "${DECISION_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$DECISION_TASK_COUNT" "1" "DFS22 decision fixture: single-task shape (task-001 only)"
if grep -q "trigger -> diagnostic -> remediation -> escalation" "${DECISION_DIR}/tasks/task-001/DETAIL.md"; then
    fail "DFS23 decision fixture: task-001 does NOT carry the runbook-only trigger/diagnostic/remediation/escalation shape"
else
    pass "DFS23 decision fixture: task-001 does NOT carry the runbook-only trigger/diagnostic/remediation/escalation shape"
fi
assert_file_contains "${DECISION_DIR}/STATE.md" "**Active Skill:** aid-document-decision" \
    "DFS24 decision fixture: Active Skill is aid-document-decision"

# ---------------------------------------------------------------------------
# Fixture B: aid-document-runbook
# ---------------------------------------------------------------------------
RUNBOOK_DIR="${TMP}/work-document-runbook"
build_document_runbook_fixture "$RUNBOOK_DIR"

assert_file_contains "${RUNBOOK_DIR}/tasks/task-001/DETAIL.md" "**Type:** DOCUMENT" \
    "DFS30 runbook fixture: task-001 is DOCUMENT"
assert_file_contains "${RUNBOOK_DIR}/tasks/task-001/DETAIL.md" \
    "trigger -> diagnostic -> remediation -> escalation" \
    "DFS31 runbook fixture: task-001 Scope requires the trigger -> diagnostic -> remediation -> escalation structure"
RUNBOOK_TASK_COUNT=$(find "${RUNBOOK_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$RUNBOOK_TASK_COUNT" "1" "DFS32 runbook fixture: single-task shape (task-001 only)"
if grep -q "Context -> Decision -> Alternatives -> Consequences" "${RUNBOOK_DIR}/tasks/task-001/DETAIL.md"; then
    fail "DFS33 runbook fixture: task-001 does NOT carry the ADR-only Context/Decision/Alternatives/Consequences shape"
else
    pass "DFS33 runbook fixture: task-001 does NOT carry the ADR-only Context/Decision/Alternatives/Consequences shape"
fi
assert_file_contains "${RUNBOOK_DIR}/STATE.md" "**Active Skill:** aid-document-runbook" \
    "DFS34 runbook fixture: Active Skill is aid-document-runbook"

# ---------------------------------------------------------------------------
# Both fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10);
# both use the same all-8 -> DOCUMENT default_type (AC-1/AC-4).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$DECISION_DIR" "$RUNBOOK_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "DFS40 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for section in "### Data Model" "### Feature Flow" "### Layers & Components"; do
        assert_file_contains "${FIXTURE_DIR}/SPEC.md" "$section" \
            "DFS41 [${fixture_label}] SPEC.md carries mandatory section ${section} (engine contract: mandatory three always apply)"
    done
    if grep -qE '^### (UI Specs|API Contracts|Security Specs|Migration Plan)' "${FIXTURE_DIR}/SPEC.md"; then
        fail "DFS42 [${fixture_label}] SPEC.md activates no conditional section (document family: mandatory three only)"
    else
        pass "DFS42 [${fixture_label}] SPEC.md activates no conditional section (document family: mandatory three only)"
    fi
    assert_file_exists "${FIXTURE_DIR}/tasks/task-001/DETAIL.md" "DFS43 [${fixture_label}] tasks/task-001/DETAIL.md present"
    if [[ -f "${FIXTURE_DIR}/tasks/task-001/STATE.md" ]]; then
        fail "DFS44 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    else
        pass "DFS44 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    fi

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "DFS45 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "DFS45 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "DFS46 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "DFS47 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "DFS48 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

echo ""
test_summary
