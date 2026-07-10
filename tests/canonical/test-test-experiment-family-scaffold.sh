#!/usr/bin/env bash
# test-test-experiment-family-scaffold.sh -- task-020 (work-001-lite-aid-skills,
# feature-009): aid-test / aid-experiment family scaffold test.
#
# The shortcut engine + the test/experiment scaffolding reference are agent-executed
# PROSE, not executable scripts -- a deterministic canonical test cannot "run"
# /aid-test-security or /aid-experiment. This suite is therefore CONTRACT +
# FIXTURE-SHAPE, matching the other work-001 shortcut-engine suites
# (test-fix-family-scaffold.sh, test-create-family-scaffold.sh,
# test-change-refactor-family-scaffold.sh):
#
#   1. Contract assertions -- grep shortcut-scaffolding/test-experiment.md for the
#      load-bearing elements: aid-test's two inferred modes (functional/model-eval),
#      aid-test-security's SPEC activation + findings-route-to-aid-fix contract,
#      aid-experiment's RESEARCH -> [IMPLEMENT] -> RESEARCH chain, and the Ownership
#      boundary (G7 owns test/experiment wholly, not aid-create).
#   2. Catalog contract -- checked against the REAL catalog + skill dirs: exactly 5 G7
#      rows (aid-test, -security, -performance, -data-quality, aid-experiment), NO alias
#      row for any of them (feature-009's "5 canonical, no aliases"), and the
#      test/test-* -> TEST, experiment -> RESEARCH default_type mapping.
#   3. Fixture-shape assertions -- three hand-authored flattened work fixtures mirroring
#      what `/aid-test-security`, `/aid-experiment`, and `/aid-test` (model-eval mode)
#      would produce, all halted at APPROVAL-HALT (pre-Execute).
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-test-experiment-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TE_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/test-experiment.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-test/aid-experiment family scaffold (task-020, feature-009) ==="

assert_file_exists "$TE_SCAFFOLD" "TEF00a shortcut-scaffolding/test-experiment.md exists"
assert_file_exists "$CATALOG" "TEF00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "TEF00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

TE_TXT=$(cat "$TE_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/test-experiment.md
# ===========================================================================
echo "--- Part 1: test-experiment.md contract assertions ---"

# TEF-01: aid-test's two modes -- functional (default) + model-eval, inferred not captured.
assert_output_contains "$TE_TXT" \
    "Bare \`aid-test\` covers **functional** testing by default, plus a **model-eval**" \
    "TEF01a aid-test: functional (default) + model-eval mode named"
assert_output_contains "$TE_TXT" \
    "\`mode\` is inferred" \
    "TEF01b aid-test: mode is inferred (not a captured slot)"

# TEF-02: aid-test DETAIL table -- functional single TEST tracing to an AC; model-eval
# single TEST running the harness (maps to TEST, no enum change).
assert_output_contains "$TE_TXT" \
    '| `functional` | single `task-001` TEST -- author/extend + run; **each test traces to a specific acceptance criterion**' \
    "TEF02a functional mode: single task-001 TEST, each test traces to an AC"
assert_output_contains "$TE_TXT" \
    'run the evaluation harness against `eval-dataset` and assert `metric` meets `threshold`' \
    "TEF02b model-eval mode: run the evaluation harness against eval-dataset, assert metric meets threshold"
assert_output_contains "$TE_TXT" \
    'maps to the `TEST` type; no enum change' \
    "TEF02c model-eval mode maps to the TEST type -- no enum change (§5.1 places it inside bare aid-test)"

# TEF-03: aid-test-security -- SPEC activates ### Security Specs; DETAIL findings route to aid-fix.
assert_output_contains "$TE_TXT" \
    "Activates \`### Security Specs\`." \
    "TEF03a aid-test-security SPEC activates ### Security Specs"
assert_output_contains "$TE_TXT" \
    "Single \`task-001\` TEST -- security-verification plan + run (SAST/DAST/fuzz/" \
    "TEF03b aid-test-security DETAIL: single task-001 TEST, security-verification plan + run (wrap point 1)"
assert_output_contains "$TE_TXT" \
    "audit, per the captured technique). **Findings route to \`aid-fix\`**" \
    "TEF03c aid-test-security DETAIL: findings route to aid-fix (wrap point 2)"
assert_output_contains "$TE_TXT" \
    "remediation is never folded into this task" \
    "TEF03d aid-test-security: remediation is never folded into the verification task"

# TEF-04: aid-experiment's RESEARCH -> [IMPLEMENT] -> RESEARCH chain (exact table rows).
assert_output_contains "$TE_TXT" \
    '| `task-001` | RESEARCH | design: hypothesis -> variants -> metric -> significance plan |' \
    "TEF04a aid-experiment task-001: RESEARCH (design: hypothesis -> variants -> metric -> significance)"
assert_output_contains "$TE_TXT" \
    '| `task-002` (optional) | IMPLEMENT | build the variants, only when the description says the variants must be built' \
    "TEF04b aid-experiment task-002: optional IMPLEMENT (build the variants)"
assert_output_contains "$TE_TXT" \
    'run the experiment, analyze results against the significance criteria, end with a recommendation |' \
    "TEF04c aid-experiment final RESEARCH task: run + analyze + end with a recommendation"

# TEF-05: Ownership boundary -- test/experiment belongs wholly to G7, not aid-create.
assert_output_contains "$TE_TXT" \
    "**Test/experiment belong wholly to G7, not to \`aid-create\`.**" \
    "TEF05a Ownership boundary: test/experiment belongs wholly to G7, not aid-create"
assert_output_contains "$TE_TXT" \
    "\`aid-test-security\`" \
    "TEF05b Ownership boundary names aid-test-security"
assert_output_contains "$TE_TXT" \
    'only *verifies/plans* -- the remediation of any finding is **`aid-fix`**' \
    "TEF05c Ownership boundary: aid-test-security only verifies/plans; remediation is aid-fix"

# TEF-06: no alias for any test/experiment row (feature-009's "5 canonical, no aliases").
assert_output_contains "$TE_TXT" \
    'No `aid-test-*`/`aid-experiment` row carries' \
    "TEF06a test-experiment.md states no aid-test-*/aid-experiment row carries an alias"
assert_output_contains "$TE_TXT" \
    'an alias (feature-009 SPEC "Catalog rows owned" -- 5 canonical, no aliases).' \
    "TEF06b test-experiment.md cites feature-009: 5 canonical rows, no aliases"

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

# TEF-10: exactly 5 G7 rows exist, each with the aid- prefix and a matching skill dir.
G7_NAMES=(aid-test aid-test-security aid-test-performance aid-test-data-quality aid-experiment)
for name in "${G7_NAMES[@]}"; do
    ROW_COUNT=$(grep -c "^  - name: ${name}\$" "$CATALOG" || true)
    assert_eq "$ROW_COUNT" "1" "TEF10 [${name}] exactly one catalog row named exactly ${name}"
    assert_dir_exists "${SKILLS_ROOT}/${name}" "TEF10 [${name}] skill directory exists"
    assert_file_exists "${SKILLS_ROOT}/${name}/SKILL.md" "TEF10 [${name}] SKILL.md exists"
done

# TEF-11: default_type mapping -- test/test-* -> TEST, experiment -> RESEARCH.
for name in aid-test aid-test-security aid-test-performance aid-test-data-quality; do
    dt=$(get_row_field "$name" "default_type")
    assert_eq "$dt" "TEST" "TEF11 [${name}] row: default_type == TEST"
done
EXPERIMENT_DT=$(get_row_field "aid-experiment" "default_type")
assert_eq "$EXPERIMENT_DT" "RESEARCH" "TEF12 aid-experiment row: default_type == RESEARCH (non-code default-type mapping, AC-4)"

# TEF-13: no alias_of on any G7 row (5 canonical, no aliases -- feature-009 SPEC).
for name in "${G7_NAMES[@]}"; do
    alias_of=$(get_row_field "$name" "alias_of")
    assert_eq "$alias_of" "null" "TEF13 [${name}] row: alias_of == null (no alias family)"
done

# TEF-14: no aid-test-*/aid-experiment-* alias row exists anywhere in the catalog (no row
# whose alias_of points at any G7 canonical name).
ALIAS_HITS=0
for name in "${G7_NAMES[@]}"; do
    hit=$(grep -E "^    alias_of: ${name}\$" "$CATALOG" || true)
    if [[ -n "$hit" ]]; then
        fail "TEF14 [${name}] no catalog row carries alias_of: ${name} -- found one"
        ALIAS_HITS=1
    fi
done
if [[ "$ALIAS_HITS" -eq 0 ]]; then
    pass "TEF14 no catalog row carries alias_of pointing at any G7 canonical name"
fi

# ===========================================================================
# Part 3 -- Fixture-shape assertions
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_test_security_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-test-security +
# shortcut-engine.md would produce: ### Security Specs activated, single task-001 TEST
# (SAST/DAST plan), findings routed to aid-fix, halted pre-Execute.
build_test_security_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** security verification -- orders search endpoint
- **Description:** SAST/DAST verification of the orders search endpoint.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-test-security) | /aid-test-security |

## 1. Objective

Verify the security posture of the orders search endpoint.

## 2. Problem Statement

The orders search endpoint has not had a SAST/DAST pass.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=test, artifact=security. Target surface: the orders search endpoint. Technique:
SAST + DAST. Threat focus: injection.

## 5. Functional Requirements

Run a SAST scan and a DAST pass against the orders search endpoint and produce a
verification report; any finding is out of scope for remediation here.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the SAST scan, when run, then it produces a verification report against the
  orders search endpoint.
- [ ] Given the DAST pass, when run, then it produces a verification report against the
  orders search endpoint.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# security verification -- orders search endpoint

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-test-security |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Verify the security posture of the orders search endpoint.

## User Stories

- As a security-conscious maintainer, I want a SAST/DAST pass on the orders search
  endpoint so any exploit path is caught before it ships.

## Priority

Must

## Acceptance Criteria

- [ ] Given the SAST scan, when run, then it produces a verification report against the
  orders search endpoint.

---

## Technical Specification

### Data Model

No schema changes -- this work only verifies, it does not modify data shape.

### Feature Flow

Plan technique (SAST/DAST) -> run -> produce verification report.

### Layers & Components

The orders search endpoint and its immediate dependency set.

### Security Specs

Target surface: the orders search endpoint. Technique: SAST + DAST. Threat focus:
injection. Any finding routes to aid-fix (vulnerability kind) for remediation -- this
work's own scope ends at the verification report.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- security verification -- orders search endpoint

> **Work:** work-NNN-security-verification-orders-search
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- security verification of the orders search endpoint
- **What it delivers:** the SAST/DAST verification report.
- **Features:** feature-001-security-verification-orders-search
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

    cat > "${work_dir}/BLUEPRINT.md" <<'EOF'
# Delivery BLUEPRINT -- delivery-001: security verification of the orders search endpoint

> **Delivery:** delivery-001
> **Work:** work-NNN-security-verification-orders-search
> **Created:** 2026-07-09

---

## Objective

Verify the security posture of the orders search endpoint via SAST + DAST.

## Scope

verb=test, artifact=security. Target surface: the orders search endpoint.

**Out of scope:** remediation of any finding -- route to aid-fix (vulnerability kind).

## Gate Criteria

- [ ] The SAST scan produces a verification report.
- [ ] The DAST pass produces a verification report.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | TEST | SAST/DAST verification plan + run against the orders search endpoint |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-test-security (test, artifact
'security'). Findings route to aid-fix (vulnerability kind), not back into this work.
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: SAST/DAST verification plan + run against the orders search endpoint

**Type:** TEST

**Source:** work-NNN-security-verification-orders-search -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Plan and run a SAST scan + DAST pass against the orders search endpoint; produce a
  verification report. Remediation of any finding is out of scope -- route to aid-fix
  (vulnerability kind).

**Acceptance Criteria:**
- [ ] Given the SAST scan, when run, then it produces a verification report against the
  orders search endpoint.
- [ ] Given the DAST pass, when run, then it produces a verification report against the
  orders search endpoint.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-security-verification-orders-search

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-test-security
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

# build_experiment_fixture <work-dir>
# Hand-authors a flattened work mirroring what /aid-experiment + shortcut-engine.md
# would produce: RESEARCH (design) -> IMPLEMENT (build variants) -> RESEARCH (analyze +
# recommend), halted pre-Execute. Proves the RESEARCH-typed task-001 (non-code
# default-type mapping, AC-4).
build_experiment_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002" "${work_dir}/tasks/task-003"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** checkout button color A/B test
- **Description:** Test whether a green checkout button improves conversion vs. blue.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-experiment) | /aid-experiment |

## 1. Objective

Determine whether a green checkout button improves conversion vs. the current blue.

## 2. Problem Statement

Conversion on the checkout page has plateaued; button color is an untested lever.

## 3. Users & Stakeholders

The requesting product owner/maintainer.

## 4. Scope

verb=experiment. Hypothesis: a green checkout button increases conversion vs. blue.
Variants: control (blue), treatment (green). Success metric: checkout conversion rate.
Significance criteria: p < 0.05 at the pre-registered sample size. Audience: all
checkout-page visitors.

## 5. Functional Requirements

Design the experiment, build the green-button variant, run it, and analyze the result
against the significance criteria.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the experiment design, when reviewed, then it names the hypothesis,
  >= 2 variants, the success metric, and the significance criteria.
- [ ] Given the experiment run, when analyzed, then it ends with a recommendation
  (ship the treatment, keep the control, or inconclusive).

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# checkout button color A/B test

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-experiment |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Determine whether a green checkout button improves conversion vs. the current blue.

## User Stories

- As a product owner, I want a controlled A/B test on button color so the decision is
  evidence-based, not a guess.

## Priority

Must

## Acceptance Criteria

- [ ] Given the experiment run, when analyzed, then it ends with a recommendation.

---

## Technical Specification

### Data Model

No schema changes -- the experiment reads existing conversion-event data;
it introduces no new persisted shape.

### Feature Flow

Design (hypothesis -> variants -> metric -> significance) -> build the treatment
variant -> run -> analyze -> recommend.

### Layers & Components

The checkout page's button component and the analytics pipeline that records
conversion events.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- checkout button color A/B test

> **Work:** work-NNN-checkout-button-color-ab-test
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- checkout button color A/B test
- **What it delivers:** the experiment design, the built treatment variant, and the
  analysis + recommendation.
- **Features:** feature-001-checkout-button-color-ab-test
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
# Delivery BLUEPRINT -- delivery-001: checkout button color A/B test

> **Delivery:** delivery-001
> **Work:** work-NNN-checkout-button-color-ab-test
> **Created:** 2026-07-09

---

## Objective

Determine whether a green checkout button improves conversion vs. the current blue.

## Scope

verb=experiment. Hypothesis, >= 2 variants (control + treatment), success metric,
significance criteria, audience -- all captured in REQUIREMENTS.md §4.

**Out of scope:** shipping the winning variant permanently (a follow-on aid-change).

## Gate Criteria

- [ ] The experiment design names the hypothesis, >= 2 variants, the success metric,
  and the significance criteria.
- [ ] The analysis ends with a recommendation.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | Design: hypothesis -> variants -> metric -> significance plan |
| task-002 | IMPLEMENT | Build the green-button treatment variant |
| task-003 | RESEARCH | Run the experiment, analyze results, end with a recommendation |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-experiment (experiment, artifact
'').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Design: hypothesis -> variants -> metric -> significance plan

**Type:** RESEARCH

**Source:** work-NNN-checkout-button-color-ab-test -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Design the experiment: hypothesis, >= 2 variants (control + treatment), success
  metric, significance criteria, audience/segment.

**Acceptance Criteria:**
- [ ] The design names the hypothesis, >= 2 variants, the success metric, and the
  significance criteria.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<'EOF'
# task-002: Build the green-button treatment variant

**Type:** IMPLEMENT

**Source:** work-NNN-checkout-button-color-ab-test -> delivery-001

**Depends on:** task-001

**Scope:**
- Build the green-button treatment variant per the experiment design.

**Acceptance Criteria:**
- [ ] The treatment variant renders the green checkout button per the design.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-003/DETAIL.md" <<'EOF'
# task-003: Run the experiment, analyze results, end with a recommendation

**Type:** RESEARCH

**Source:** work-NNN-checkout-button-color-ab-test -> delivery-001

**Depends on:** task-002

**Scope:**
- Run the experiment against the built variants, analyze the result against the
  significance criteria, and end with a recommendation.

**Acceptance Criteria:**
- [ ] The analysis ends with a recommendation (ship the treatment, keep the control, or
  inconclusive).
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-checkout-button-color-ab-test

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-experiment
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

# build_test_model_eval_fixture <work-dir>
# Hand-authors a flattened work mirroring what bare /aid-test would produce when the
# description signals the model-eval mode (test-experiment.md § aid-test -- two modes):
# a single task-001 TEST running the eval harness against eval-dataset, asserting metric
# meets threshold. Proves the model-eval mode is present (not just the functional
# default), halted pre-Execute.
build_test_model_eval_fixture() {
    local work_dir="$1"
    mkdir -p "${work_dir}/tasks/task-001"

    cat > "${work_dir}/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** fraud-classifier model evaluation
- **Description:** Eval the fraud-classifier model's accuracy against the holdout
  dataset; threshold 0.95.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial capture (shortcut: aid-test) | /aid-test |

## 1. Objective

Evaluate the fraud-classifier model's accuracy against the holdout dataset.

## 2. Problem Statement

The fraud-classifier model has not been evaluated against the current holdout dataset.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

verb=test, artifact="" (bare), mode=model-eval (inferred from "eval"/"model"/
"accuracy"/"dataset"/"threshold" in the description). Model: fraud-classifier.
Eval-dataset: the holdout dataset. Metric/threshold: accuracy >= 0.95.

## 5. Functional Requirements

Run the evaluation harness against the holdout dataset and assert accuracy meets the
0.95 threshold.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the evaluation harness run against the holdout dataset, when accuracy is
  computed, then it is >= 0.95.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<'EOF'
# fraud-classifier model evaluation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | SPEC authored from REQUIREMENTS.md | /aid-test |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Evaluate the fraud-classifier model's accuracy against the holdout dataset.

## User Stories

- As a model owner, I want the fraud-classifier's accuracy checked against the holdout
  dataset so a regression is caught before deployment.

## Priority

Must

## Acceptance Criteria

- [ ] Given the evaluation harness run against the holdout dataset, when accuracy is
  computed, then it is >= 0.95.

---

## Technical Specification

### Data Model

No schema changes -- the evaluation reads the existing eval-dataset; it
introduces no new persisted shape.

### Feature Flow

Load model -> run evaluation harness against eval-dataset -> compute metric -> assert
metric meets threshold.

### Layers & Components

The fraud-classifier model artifact and the evaluation harness that scores it.
EOF

    cat > "${work_dir}/PLAN.md" <<'EOF'
# Plan -- fraud-classifier model evaluation

> **Work:** work-NNN-fraud-classifier-model-eval
> **Created:** 2026-07-09

---

## Deliverables

- **Delivery:** delivery-001 -- fraud-classifier model evaluation
- **What it delivers:** the model-eval run + its pass/fail verdict against the 0.95
  accuracy threshold.
- **Features:** feature-001-fraud-classifier-model-eval
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

    cat > "${work_dir}/BLUEPRINT.md" <<'EOF'
# Delivery BLUEPRINT -- delivery-001: fraud-classifier model evaluation

> **Delivery:** delivery-001
> **Work:** work-NNN-fraud-classifier-model-eval
> **Created:** 2026-07-09

---

## Objective

Evaluate the fraud-classifier model's accuracy against the holdout dataset.

## Scope

verb=test, artifact="" (bare), mode=model-eval.

**Out of scope:** retraining the model; functional/unit/integration/e2e testing (the
functional mode of aid-test).

## Gate Criteria

- [ ] The evaluation harness run against the holdout dataset computes accuracy >= 0.95.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | TEST | Run the evaluation harness against the holdout dataset; assert accuracy >= 0.95 |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-test (test, artifact ''),
mode=model-eval.
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<'EOF'
# task-001: Run the evaluation harness against the holdout dataset

**Type:** TEST

**Source:** work-NNN-fraud-classifier-model-eval -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Run the fraud-classifier model's evaluation harness against the holdout dataset and
  assert accuracy meets the 0.95 threshold. (mode=model-eval; maps to the TEST type, no
  enum change.)

**Acceptance Criteria:**
- [ ] Given the evaluation harness run against the holdout dataset, when accuracy is
  computed, then it is >= 0.95.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<'EOF'
# Work State -- work-NNN-fraud-classifier-model-eval

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-test
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
# Fixture A: aid-test-security
# ---------------------------------------------------------------------------
SEC_DIR="${TMP}/work-test-security"
build_test_security_fixture "$SEC_DIR"

assert_file_contains "${SEC_DIR}/SPEC.md" "### Security Specs" \
    "TEF20 test-security fixture: SPEC.md activates ### Security Specs"
assert_file_contains "${SEC_DIR}/tasks/task-001/DETAIL.md" "**Type:** TEST" \
    "TEF21 test-security fixture: task-001 is TEST (SAST/DAST plan)"
TEST_SECURITY_TASK_COUNT=$(find "${SEC_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$TEST_SECURITY_TASK_COUNT" "1" "TEF22 test-security fixture: single-task shape (task-001 only)"
assert_file_contains "${SEC_DIR}/tasks/task-001/DETAIL.md" "route to aid-fix" \
    "TEF23 test-security fixture: task-001 scope names aid-fix as the remediation route"
assert_file_contains "${SEC_DIR}/BLUEPRINT.md" "route to aid-fix (vulnerability kind)" \
    "TEF24 test-security fixture: BLUEPRINT.md out-of-scope names aid-fix (vulnerability kind) for remediation"

# ---------------------------------------------------------------------------
# Fixture B: aid-experiment
# ---------------------------------------------------------------------------
EXP_DIR="${TMP}/work-experiment"
build_experiment_fixture "$EXP_DIR"

assert_file_contains "${EXP_DIR}/tasks/task-001/DETAIL.md" "**Type:** RESEARCH" \
    "TEF30 experiment fixture: task-001 is RESEARCH (non-code default-type mapping, AC-4)"
assert_file_contains "${EXP_DIR}/tasks/task-002/DETAIL.md" "**Type:** IMPLEMENT" \
    "TEF31 experiment fixture: task-002 is IMPLEMENT (build the variants)"
assert_file_contains "${EXP_DIR}/tasks/task-003/DETAIL.md" "**Type:** RESEARCH" \
    "TEF32 experiment fixture: task-003 is RESEARCH (run + analyze + recommend)"
assert_file_contains "${EXP_DIR}/tasks/task-003/DETAIL.md" "end with a recommendation" \
    "TEF33 experiment fixture: task-003 AC ends with a recommendation"

# ---------------------------------------------------------------------------
# Fixture C: aid-test, model-eval mode
# ---------------------------------------------------------------------------
MEVAL_DIR="${TMP}/work-test-model-eval"
build_test_model_eval_fixture "$MEVAL_DIR"

assert_file_contains "${MEVAL_DIR}/tasks/task-001/DETAIL.md" "**Type:** TEST" \
    "TEF40 test-model-eval fixture: task-001 is TEST (maps to TEST, no enum change)"
assert_file_contains "${MEVAL_DIR}/tasks/task-001/DETAIL.md" "mode=model-eval" \
    "TEF41 test-model-eval fixture: task-001 scope names mode=model-eval"
assert_file_contains "${MEVAL_DIR}/tasks/task-001/DETAIL.md" "evaluation harness" \
    "TEF42 test-model-eval fixture: task-001 runs the evaluation harness against the eval-dataset"
assert_file_contains "${MEVAL_DIR}/STATE.md" "**Active Skill:** aid-test" \
    "TEF43 test-model-eval fixture: Active Skill is bare aid-test (model-eval mode lives inside bare aid-test, not a separate skill)"

# ---------------------------------------------------------------------------
# All three fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$SEC_DIR" "$EXP_DIR" "$MEVAL_DIR"; do
    fixture_label=$(basename "$FIXTURE_DIR")

    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "TEF50 [${fixture_label}] ${f} present (engine smoke: full flattened set)"
    done
    for section in "### Data Model" "### Feature Flow" "### Layers & Components"; do
        assert_file_contains "${FIXTURE_DIR}/SPEC.md" "$section" \
            "TEF57 [${fixture_label}] SPEC.md carries mandatory section ${section} (engine contract: mandatory three always apply)"
    done
    assert_file_exists "${FIXTURE_DIR}/tasks/task-001/DETAIL.md" "TEF51 [${fixture_label}] tasks/task-001/DETAIL.md present"
    if [[ -f "${FIXTURE_DIR}/tasks/task-001/STATE.md" ]]; then
        fail "TEF52 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    else
        pass "TEF52 [${fixture_label}] tasks/task-001/ has no sibling STATE.md (flat layout has none)"
    fi

    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "TEF53 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "TEF53 [${fixture_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "TEF54 [${fixture_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "TEF55 [${fixture_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "TEF56 [${fixture_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

echo ""
test_summary
