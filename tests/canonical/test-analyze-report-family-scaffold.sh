#!/usr/bin/env bash
# test-analyze-report-family-scaffold.sh -- task-026 (work-001-lite-aid-skills,
# feature-011): aid-report / aid-show-dashboard family scaffold + halt proof.
#
# The shortcut engine + the analyze/report scaffolding reference are agent-executed
# PROSE, not executable scripts -- a deterministic canonical test cannot "run"
# /aid-report. This suite is therefore CONTRACT + FIXTURE-SHAPE, matching the other
# work-001 shortcut-engine suites (test-fix-family-scaffold.sh,
# test-test-experiment-family-scaffold.sh, test-document-family-scaffold.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/analyze-report.md for the
#      load-bearing elements: aid-report's CAPTURE slots + RESEARCH -> [DOCUMENT]
#      breakdown (EDA/metrics/>=2 interpretations/recommendation), aid-show-dashboard's
#      CAPTURE slots + ### Telemetry & Tracking / ### UI Specs activation + IMPLEMENT ->
#      [TEST] breakdown, and the Ownership-boundary distinguishing report/dashboard from
#      document/create-data-pipeline/test-data-quality/experiment.
#   2. Catalog contract -- checked against the REAL catalog + skill dirs: exactly 2 G11
#      rows (aid-report -> RESEARCH, aid-show-dashboard -> IMPLEMENT), neither carrying
#      an alias (feature-011 SPEC "Catalog rows owned" -- 2 canonical, no aliases).
#   3. Fixture-shape assertions -- two hand-authored flattened work fixtures mirroring
#      what `/aid-report` and `/aid-show-dashboard` would produce: a RESEARCH-typed
#      task-001 (EDA + recommendation) proving the non-code default-type mapping and
#      the G4->G11 reclassification, and an IMPLEMENT-typed task-001 with
#      `### Telemetry & Tracking` activated (AC-4). Both halted at APPROVAL-HALT
#      (pre-Execute).
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-analyze-report-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AR_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/analyze-report.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-report/aid-show-dashboard family scaffold + halt proof (task-026, feature-011) ==="

assert_file_exists "$AR_SCAFFOLD" "AFS00a shortcut-scaffolding/analyze-report.md exists"
assert_file_exists "$CATALOG" "AFS00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "AFS00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

AR_TXT=$(cat "$AR_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/analyze-report.md
# ===========================================================================
echo "--- Part 1: analyze-report.md contract assertions ---"

# AFS-01: aid-report CAPTURE slots.
assert_output_contains "$AR_TXT" \
    '| Question / hypothesis | the specific question the analysis answers |' \
    "AFS01a aid-report captures the question/hypothesis"
assert_output_contains "$AR_TXT" \
    '| Decision it informs | the decision the insight feeds |' \
    "AFS01b aid-report captures the decision it informs"

# AFS-02: aid-report SPEC -- base sections only, Data Model "no schema changes".
assert_output_contains "$AR_TXT" \
    'Base sections only -- the mandatory three (`### Data Model`, `### Feature Flow`,' \
    "AFS02a aid-report SPEC: base sections only, mandatory three named (wrap point 1)"
assert_output_contains "$AR_TXT" \
    '`### Layers & Components`) apply with no conditional section; `### Data Model` reads' \
    "AFS02b aid-report SPEC: no conditional section, Data Model reads... (wrap point 2)"

# AFS-03: aid-report DETAIL -- task-001 RESEARCH (EDA/metrics/>=2 interpretations/
# recommendation), optional task-002 DOCUMENT depends on task-001.
assert_output_contains "$AR_TXT" \
    '| `task-001` | RESEARCH | EDA + metrics; at least 2 interpretations of the finding; ends with a recommendation |' \
    "AFS03a aid-report task-001: RESEARCH, EDA + metrics, >=2 interpretations, ends with a recommendation"
assert_output_contains "$AR_TXT" \
    '| `task-002` (optional) | DOCUMENT | write up the finding for `{audience}`; depends on `task-001` |' \
    "AFS03b aid-report task-002: optional DOCUMENT, write up for audience, depends on task-001"
assert_output_contains "$AR_TXT" \
    "maps directly onto EDA's requirement for multiple interpretations of" \
    "AFS03c task-type-rules.md RESEARCH (>=2 alternatives) maps onto EDA's multi-interpretation requirement"

# AFS-04: aid-show-dashboard CAPTURE slots.
assert_output_contains "$AR_TXT" \
    '| Visualization type | chart/table/view shape |' \
    "AFS04a aid-show-dashboard captures visualization type"
assert_output_contains "$AR_TXT" \
    '| Publish target | where/how the dashboard is published |' \
    "AFS04b aid-show-dashboard captures the publish target"

# AFS-05: aid-show-dashboard SPEC -- activates ### Telemetry & Tracking + ### UI Specs.
assert_output_contains "$AR_TXT" \
    'Activates `### Telemetry & Tracking` + `### UI Specs` on top of the mandatory three' \
    "AFS05a aid-show-dashboard activates ### Telemetry & Tracking + ### UI Specs on top of the mandatory three"

# AFS-06: aid-show-dashboard DETAIL -- task-001 IMPLEMENT, optional task-002 TEST depends
# on task-001.
assert_output_contains "$AR_TXT" \
    '| `task-001` | IMPLEMENT | build the view: source -> viz -> publish/refresh |' \
    "AFS06a aid-show-dashboard task-001: IMPLEMENT, build the view source -> viz -> publish/refresh"
assert_output_contains "$AR_TXT" \
    '| `task-002` (optional) | TEST | validate data accuracy + refresh; depends on `task-001` |' \
    "AFS06b aid-show-dashboard task-002: optional TEST, validate data accuracy + refresh, depends on task-001"

# AFS-07: Ownership boundary -- distinguishes report (derive insight, RESEARCH) from
# document (communicate already-known); names create-data-pipeline, test-data-quality,
# experiment as the neighboring carve-outs.
assert_output_contains "$AR_TXT" \
    '**Report/dashboard belong wholly to G11**, distinguished from neighbors by intent:' \
    "AFS07a Ownership boundary: report/dashboard belong wholly to G11, distinguished by intent"
assert_output_contains "$AR_TXT" \
    '`aid-report` = **derive insight** from data (RESEARCH); `aid-document` = **communicate' \
    "AFS07b Ownership boundary: aid-report derives insight (RESEARCH) vs aid-document communicates already-known (wrap point 1)"
assert_output_contains "$AR_TXT" \
    'already-known** information (a status/progress report is G8'"'"'s bare `aid-document`;' \
    "AFS07c Ownership boundary: status/progress report is G8's bare aid-document (wrap point 2)"
assert_output_contains "$AR_TXT" \
    'is `aid-create-data-pipeline` (G4); adding **data-quality checks**' \
    "AFS07d Ownership boundary: building the data pipeline is aid-create-data-pipeline (G4)"
assert_output_contains "$AR_TXT" \
    'on the source is `aid-test-data-quality` (G7); a controlled **experiment/A-B test**' \
    "AFS07e Ownership boundary: data-quality checks are aid-test-data-quality (G7)"
assert_output_contains "$AR_TXT" \
    '(design + run) is `aid-experiment` (G7) -- `aid-report` analyzes results, it does not' \
    "AFS07f Ownership boundary: a controlled experiment/A-B test design is aid-experiment (G7); aid-report only analyzes results"

# AFS-08: aid-review CAPTURE/SPEC/DETAIL (v2.1.0 coverage-gap follow-on).
assert_output_contains "$AR_TXT" '## `aid-review` -- CAPTURE' \
    "AFS08a aid-review CAPTURE section present"
assert_output_contains "$AR_TXT" \
    '| Target | the artifact under review -- code, a change/diff, or a design |' \
    "AFS08b aid-review captures the review Target"
assert_output_contains "$AR_TXT" '## `aid-review` -- SPEC' \
    "AFS08c aid-review SPEC section present"
assert_output_contains "$AR_TXT" \
    'Base sections only -- the mandatory three (`### Data Model`, `### Feature Flow`,' \
    "AFS08d aid-review SPEC: base sections only (no conditional section)"
assert_output_contains "$AR_TXT" '## `aid-review` -- DETAIL' \
    "AFS08e aid-review DETAIL section present"
assert_output_contains "$AR_TXT" \
    '| `task-001` | RESEARCH | assess `{target}` against the captured criteria/rubric;' \
    "AFS08f aid-review task-001: RESEARCH, assesses target against criteria/rubric"
assert_output_contains "$AR_TXT" \
    'Emits the reviewer-ledger per the global review-output schema' \
    "AFS08g aid-review task-001 emits the reviewer-ledger schema, not prose findings"
assert_output_contains "$AR_TXT" \
    '| `task-002` (optional) | DOCUMENT | write up the findings for a stakeholder audience; depends on `task-001` |' \
    "AFS08h aid-review task-002: optional DOCUMENT, write up findings, depends on task-001"

# AFS-09: aid-research CAPTURE/SPEC/DETAIL (v2.1.0 coverage-gap follow-on).
assert_output_contains "$AR_TXT" '## `aid-research` -- CAPTURE' \
    "AFS09a aid-research CAPTURE section present"
assert_output_contains "$AR_TXT" \
    '| Question / decision | the open technical question or decision this research resolves |' \
    "AFS09b aid-research captures the Question / decision"
assert_output_contains "$AR_TXT" '## `aid-research` -- SPEC' \
    "AFS09c aid-research SPEC section present"
assert_output_contains "$AR_TXT" \
    'research investigates a question, it does not model new' \
    "AFS09d aid-research SPEC: base sections only, Data Model reads no schema changes"
assert_output_contains "$AR_TXT" '## `aid-research` -- DETAIL' \
    "AFS09e aid-research DETAIL section present"
assert_output_contains "$AR_TXT" \
    '| `task-001` | RESEARCH | compare >= 2 alternatives against `{decision criteria}`' \
    "AFS09f aid-research task-001: RESEARCH, compares >= 2 alternatives against decision criteria"
assert_output_contains "$AR_TXT" \
    '| `task-002` (optional) | DOCUMENT | write up the recommendation' \
    "AFS09g aid-research task-002: optional DOCUMENT, write up the recommendation, depends on task-001"

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

# AFS-10: exactly 2 G11 rows exist, each with the aid- prefix and a matching skill dir.
G11_NAMES=(aid-report aid-show-dashboard)
for name in "${G11_NAMES[@]}"; do
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "AFS10 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "AFS10 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "AFS10 [${name}] SKILL.md exists"
    grp=$(get_row_field "$name" "group")
    assert_eq "$grp" "G11" "AFS10 [${name}] row: group == G11"
done

# AFS-11: default_type mapping -- report -> RESEARCH (non-code, G4->G11 reclassification);
# show-dashboard -> IMPLEMENT.
REPORT_DT=$(get_row_field "aid-report" "default_type")
assert_eq "$REPORT_DT" "RESEARCH" "AFS11a aid-report row: default_type == RESEARCH (non-code default-type mapping, AC-4; G4->G11 reclassification)"
DASHBOARD_DT=$(get_row_field "aid-show-dashboard" "default_type")
assert_eq "$DASHBOARD_DT" "IMPLEMENT" "AFS11b aid-show-dashboard row: default_type == IMPLEMENT"

# AFS-12: verb binding -- report's verb is "report"; show-dashboard's verb is the whole
# name (no artifact suffix, per feature-011 SPEC's naming flag).
REPORT_VERB=$(get_row_field "aid-report" "verb")
assert_eq "$REPORT_VERB" "report" "AFS12a aid-report row: verb == report"
DASHBOARD_VERB=$(get_row_field "aid-show-dashboard" "verb")
assert_eq "$DASHBOARD_VERB" "show-dashboard" "AFS12b aid-show-dashboard row: verb == show-dashboard (whole name is the verb)"
DASHBOARD_ARTIFACT=$(get_row_field "aid-show-dashboard" "artifact")
assert_eq "$DASHBOARD_ARTIFACT" "" "AFS12c aid-show-dashboard row: artifact == \"\" (no artifact suffix)"

# AFS-13: no alias on either row (feature-011 SPEC "2 canonical, no aliases").
for name in "${G11_NAMES[@]}"; do
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "AFS13 [${name}] row: alias_of == null (no alias family)"
done

# AFS-15: aid-review + aid-research (v2.1.0 coverage-gap follow-on) -- catalog rows exist,
# G11, default_type RESEARCH (a valid member of the closed 8-enum), skill dirs exist.
_VALID_TYPES_RE='^(RESEARCH|DESIGN|IMPLEMENT|TEST|DOCUMENT|MIGRATE|REFACTOR|CONFIGURE)$'
REVIEW_RESEARCH_NAMES=(aid-review aid-research)
for name in "${REVIEW_RESEARCH_NAMES[@]}"; do
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "AFS15 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "AFS15 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "AFS15 [${name}] SKILL.md exists"
    grp=$(get_row_field "$name" "group")
    assert_eq "$grp" "G11" "AFS15 [${name}] row: group == G11"
    dt=$(get_row_field "$name" "default_type")
    assert_eq "$dt" "RESEARCH" "AFS15 [${name}] row: default_type == RESEARCH"
    if [[ "$dt" =~ $_VALID_TYPES_RE ]]; then
        pass "AFS15 [${name}] default_type is a member of the closed 8-enum"
    else
        fail "AFS15 [${name}] default_type is NOT a member of the closed 8-enum -- got: ${dt}"
    fi
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "AFS15 [${name}] row: alias_of == null (canonical row)"
done

# AFS-16: alias rows -- aid-audit -> aid-review; aid-investigate/aid-spike -> aid-research.
declare -A REVIEW_RESEARCH_ALIASES=(
    ["aid-audit"]="aid-review"
    ["aid-investigate"]="aid-research"
    ["aid-spike"]="aid-research"
)
for alias_name in "${!REVIEW_RESEARCH_ALIASES[@]}"; do
    canonical_target="${REVIEW_RESEARCH_ALIASES[$alias_name]}"
    assert_dir_exists "${SKILLS_ROOT}/${alias_name}" "AFS16 [${alias_name}] skill directory exists"
    alias_of=$(get_row_field "$alias_name" "alias_of")
    assert_eq "$alias_of" "$canonical_target" "AFS16 [${alias_name}] row: alias_of == ${canonical_target}"
done

# AFS-14: no aid-report-*/aid-show-dashboard-* suffixed directory exists (bare-only family).
for base in aid-report aid-show-dashboard; do
    SUFFIXED_DIRS=$(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -name "${base}-*" 2>/dev/null || true)
    if [[ -z "$SUFFIXED_DIRS" ]]; then
        pass "AFS14 [${base}] no canonical/skills/${base}-* directory exists (bare-only)"
    else
        fail "AFS14 [${base}] no canonical/skills/${base}-* directory exists (bare-only) -- found: ${SUFFIXED_DIRS}"
    fi
done

# ===========================================================================
# Part 3 -- Fixture-shape assertions (aid-report + aid-show-dashboard)
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_report_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-report + shortcut-engine.md would
# produce: single RESEARCH task-001 (EDA + metrics + >=2 interpretations + a
# recommendation) plus an optional DOCUMENT task-002, halted pre-Execute. Proves the
# non-code default-type mapping (RESEARCH, not DOCUMENT) and the G4->G11 reclassification.
build_report_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** checkout funnel drop-off analysis
- **Description:** Analyze why users abandon checkout between cart and payment, and
  communicate the finding to the product team.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-report) | /aid-report |

## 1. Objective

Determine why checkout drop-off between cart and payment has increased, and recommend
a next step.

## 2. Problem Statement

Checkout completion rate has fallen 8% over the last quarter; the cause is unknown.

## 3. Users & Stakeholders

The requesting product owner/maintainer; the product team (audience for the finding).

## 4. Scope

Question/hypothesis: why has checkout completion fallen 8%. Data source: the analytics
warehouse's checkout-funnel events table. Metric(s): checkout completion rate, per-step
drop-off rate. Audience: the product team. Decision it informs: whether to redesign the
payment step.

## 5. Functional Requirements

Run EDA against the checkout-funnel events, compute per-step drop-off metrics, produce
at least 2 interpretations of the finding, and end with a recommendation.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the EDA + metrics, when reviewed, then it presents at least 2 distinct
  interpretations of the drop-off finding.
- [ ] Given the analysis, when concluded, then it ends with a recommendation.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# checkout funnel drop-off analysis

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-report |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Determine why checkout drop-off between cart and payment has increased, and recommend a
next step.

## User Stories

- As a product owner, I want the checkout drop-off analyzed and explained so I can
  decide whether to redesign the payment step.

## Priority

Should

## Acceptance Criteria

- [ ] Given the analysis, when concluded, then it ends with a recommendation.

---

## Technical Specification

### Data Model

No schema changes -- the report reads existing checkout-funnel event data; it
introduces no new persisted shape.

### Feature Flow

Pull checkout-funnel events -> compute per-step drop-off metrics (EDA) -> form at least
2 interpretations of the finding -> recommend.

### Layers & Components

The analytics warehouse's checkout-funnel events table; no application code is
touched.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- checkout funnel drop-off analysis

> **Work:** work-NNN-checkout-funnel-dropoff-analysis
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- checkout funnel drop-off analysis
- **What it delivers:** the EDA + metrics, >= 2 interpretations, the recommendation, and
  the optional write-up for the product team.
- **Features:** feature-001-checkout-funnel-dropoff-analysis
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
# Delivery BLUEPRINT -- delivery-001: checkout funnel drop-off analysis

> **Delivery:** delivery-001
> **Work:** work-NNN-checkout-funnel-dropoff-analysis
> **Created:** 2026-07-09

---

## Objective

Determine why checkout drop-off between cart and payment has increased, and recommend a
next step.

## Scope

verb=report, artifact="" (bare). Question/hypothesis, data source, metric(s), audience,
decision it informs -- all captured in REQUIREMENTS.md §4.

**Out of scope:** building the data pipeline feeding the events table (routes to
aid-create-data-pipeline), data-quality checks on the source (routes to
aid-test-data-quality), and designing/running a controlled experiment on the payment
step (routes to aid-experiment).

## Gate Criteria

- [ ] The EDA + metrics present at least 2 distinct interpretations of the finding.
- [ ] The analysis ends with a recommendation.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | EDA + metrics on checkout drop-off; >= 2 interpretations; recommendation |
| task-002 | DOCUMENT | Write up the finding for the product team |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-report (report, artifact '').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: EDA + metrics on checkout drop-off; recommendation

**Type:** RESEARCH

**Source:** work-NNN-checkout-funnel-dropoff-analysis -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Run EDA against the checkout-funnel events table, compute per-step drop-off metrics,
  form at least 2 distinct interpretations of the finding, and end with a
  recommendation on whether to redesign the payment step.

**Acceptance Criteria:**
- [ ] Given the EDA + metrics, when reviewed, then it presents at least 2 distinct
  interpretations of the drop-off finding.
- [ ] Given the analysis, when concluded, then it ends with a recommendation.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Write up the checkout drop-off finding for the product team

**Type:** DOCUMENT

**Source:** work-NNN-checkout-funnel-dropoff-analysis -> delivery-001

**Depends on:** task-001

**Scope:**
- Write up the EDA finding, the interpretations, and the recommendation for the product
  team audience.

**Acceptance Criteria:**
- [ ] Given the write-up, when reviewed, then it presents the finding, the
  interpretations, and the recommendation for the product team.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-checkout-funnel-dropoff-analysis

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-report
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

# build_show_dashboard_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-show-dashboard + shortcut-engine.md
# would produce: ### Telemetry & Tracking + ### UI Specs activated, single IMPLEMENT
# task-001 (build the view: source -> viz -> publish/refresh) plus an optional TEST
# task-002, halted pre-Execute.
build_show_dashboard_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** support-ticket volume dashboard
- **Description:** Build a durable dashboard showing daily support-ticket volume by
  category, published to the internal BI tool.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-show-dashboard) | /aid-show-dashboard |

## 1. Objective

Build a durable dashboard tracking daily support-ticket volume by category.

## 2. Problem Statement

Support-ticket volume by category is currently only visible via ad hoc exports; there is
no durable, refreshing view.

## 3. Users & Stakeholders

The requesting support-team lead; the support team (dashboard audience).

## 4. Scope

Data source: the support-ticket system's export API. Metrics/dimensions: ticket volume,
by category and by day. Visualization type: a daily line chart plus a per-category
table. Refresh cadence: daily, at 06:00 UTC. Publish target: the internal BI tool.

## 5. Functional Requirements

Build the dashboard: wire the data source, build the line-chart + table visualization,
and publish it to the internal BI tool on the daily refresh cadence.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the dashboard, when published, then it shows daily ticket volume by
  category as a line chart plus a per-category table.
- [ ] Given the refresh cadence, when the daily job runs, then the dashboard's data is
  no more than 24 hours stale.

## 10. Priority

Should
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# support-ticket volume dashboard

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-show-dashboard |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Build a durable dashboard tracking daily support-ticket volume by category.

## User Stories

- As a support-team lead, I want a durable dashboard of ticket volume by category so I
  no longer rely on ad hoc exports.

## Priority

Should

## Acceptance Criteria

- [ ] Given the dashboard, when published, then it shows daily ticket volume by
  category as a line chart plus a per-category table.

---

## Technical Specification

### Data Model

No schema changes -- the dashboard reads from the existing support-ticket export API;
it introduces no new persisted shape.

### Feature Flow

Pull from the support-ticket export API -> aggregate by day/category -> render the line
chart + table -> publish to the internal BI tool on the daily refresh cadence.

### Layers & Components

The support-ticket export API (source), the dashboard's aggregation/view layer, and the
internal BI tool (publish target).

### Telemetry & Tracking

Data source: the support-ticket system's export API. Metrics/dimensions: ticket volume,
by category and by day. Refresh cadence: daily at 06:00 UTC.

### UI Specs

Visualization type: a daily line chart plus a per-category table. Publish target: the
internal BI tool.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- support-ticket volume dashboard

> **Work:** work-NNN-support-ticket-volume-dashboard
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- support-ticket volume dashboard
- **What it delivers:** the built dashboard (source -> viz -> publish/refresh) and its
  optional data-accuracy/refresh validation.
- **Features:** feature-001-support-ticket-volume-dashboard
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
# Delivery BLUEPRINT -- delivery-001: support-ticket volume dashboard

> **Delivery:** delivery-001
> **Work:** work-NNN-support-ticket-volume-dashboard
> **Created:** 2026-07-09

---

## Objective

Build a durable dashboard tracking daily support-ticket volume by category.

## Scope

verb=show-dashboard, artifact="" (bare, whole name is the verb). Data source, metrics/
dimensions, visualization type, refresh cadence, publish target -- all captured in
REQUIREMENTS.md §4.

**Out of scope:** the source support-ticket system itself (out of this work's scope; a
new pipeline feeding it would be aid-create-data-pipeline) and a controlled experiment
on the dashboard's design (aid-experiment).

## Gate Criteria

- [ ] The dashboard shows daily ticket volume by category as a line chart plus a
  per-category table.
- [ ] The dashboard's data is no more than 24 hours stale after the daily refresh.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Build the view: support-ticket source -> line chart + table -> publish/refresh |
| task-002 | TEST | Validate data accuracy + the daily refresh |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-show-dashboard (show-dashboard,
artifact '').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Build the support-ticket volume dashboard (source -> viz -> publish/refresh)

**Type:** IMPLEMENT

**Source:** work-NNN-support-ticket-volume-dashboard -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Wire the support-ticket export API as the data source, build the daily line-chart +
  per-category table visualization, and publish it to the internal BI tool on the daily
  06:00 UTC refresh cadence.

**Acceptance Criteria:**
- [ ] Given the dashboard, when published, then it shows daily ticket volume by
  category as a line chart plus a per-category table.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Validate data accuracy + the daily refresh

**Type:** TEST

**Source:** work-NNN-support-ticket-volume-dashboard -> delivery-001

**Depends on:** task-001

**Scope:**
- Validate the dashboard's ticket-volume figures against the source export API and
  confirm the daily refresh keeps the data no more than 24 hours stale.

**Acceptance Criteria:**
- [ ] Given the refresh cadence, when the daily job runs, then the dashboard's data is
  no more than 24 hours stale.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-support-ticket-volume-dashboard

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-show-dashboard
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
# Fixture A: aid-report
# ---------------------------------------------------------------------------
REPORT_DIR="${TMP}/work-report"
build_report_fixture "$REPORT_DIR"

assert_file_contains "${REPORT_DIR}/tasks/task-001/DETAIL.md" "**Type:** RESEARCH" \
    "AFS20 report fixture: task-001 is RESEARCH (non-code default-type mapping, AC-4; G4->G11 reclassification)"
assert_file_contains "${REPORT_DIR}/tasks/task-001/DETAIL.md" "at least 2 distinct" \
    "AFS21 report fixture: task-001 AC requires >= 2 distinct interpretations of the finding"
assert_file_contains "${REPORT_DIR}/tasks/task-001/DETAIL.md" "ends with a recommendation" \
    "AFS22 report fixture: task-001 AC ends with a recommendation"
assert_file_contains "${REPORT_DIR}/tasks/task-002/DETAIL.md" "**Type:** DOCUMENT" \
    "AFS23 report fixture: task-002 is DOCUMENT (optional write-up)"
assert_file_contains "${REPORT_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "AFS24 report fixture: task-002 depends on task-001"
if grep -qE '^### (Telemetry & Tracking|UI Specs)' "${REPORT_DIR}/SPEC.md"; then
    fail "AFS25 report fixture: SPEC.md activates no conditional section (base sections only)"
else
    pass "AFS25 report fixture: SPEC.md activates no conditional section (base sections only)"
fi
assert_file_contains "${REPORT_DIR}/STATE.md" "**Active Skill:** aid-report" \
    "AFS26 report fixture: Active Skill is aid-report"

# ---------------------------------------------------------------------------
# Fixture B: aid-show-dashboard
# ---------------------------------------------------------------------------
DASHBOARD_DIR="${TMP}/work-show-dashboard"
build_show_dashboard_fixture "$DASHBOARD_DIR"

assert_file_contains "${DASHBOARD_DIR}/SPEC.md" "### Telemetry & Tracking" \
    "AFS30 show-dashboard fixture: SPEC.md activates ### Telemetry & Tracking (AC-4)"
assert_file_contains "${DASHBOARD_DIR}/SPEC.md" "### UI Specs" \
    "AFS31 show-dashboard fixture: SPEC.md activates ### UI Specs"
assert_file_contains "${DASHBOARD_DIR}/tasks/task-001/DETAIL.md" "**Type:** IMPLEMENT" \
    "AFS32 show-dashboard fixture: task-001 is IMPLEMENT"
assert_file_contains "${DASHBOARD_DIR}/tasks/task-002/DETAIL.md" "**Type:** TEST" \
    "AFS33 show-dashboard fixture: task-002 is TEST (optional data-accuracy/refresh validation)"
assert_file_contains "${DASHBOARD_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "AFS34 show-dashboard fixture: task-002 depends on task-001"
assert_file_contains "${DASHBOARD_DIR}/STATE.md" "**Active Skill:** aid-show-dashboard" \
    "AFS35 show-dashboard fixture: Active Skill is aid-show-dashboard"

# ---------------------------------------------------------------------------
# Both fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$REPORT_DIR" "$DASHBOARD_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "AFS40 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for section in "### Data Model" "### Feature Flow" "### Layers & Components"; do
        assert_file_contains "${FIXTURE_DIR}/SPEC.md" "$section" \
            "AFS41 [${fixture_label}] SPEC.md carries mandatory section ${section} (engine contract: mandatory three always apply)"
    done
    for t in task-001 task-002; do
        assert_file_exists "${FIXTURE_DIR}/tasks/${t}/DETAIL.md" "AFS42 [${fixture_label}] tasks/${t}/DETAIL.md present"
        if [[ -f "${FIXTURE_DIR}/tasks/${t}/STATE.md" ]]; then
            fail "AFS43 [${fixture_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        else
            pass "AFS43 [${fixture_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        fi
    done

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "AFS44 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "AFS44 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "AFS45 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "AFS46 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "AFS47 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

echo ""
test_summary
