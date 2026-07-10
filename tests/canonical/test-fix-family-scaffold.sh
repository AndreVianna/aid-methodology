#!/usr/bin/env bash
# test-fix-family-scaffold.sh -- task-014 (work-001-lite-aid-skills, feature-008 + engine
# smoke): aid-fix family scaffold + halt proof.
#
# The shortcut engine + the fix scaffolding reference are agent-executed PROSE, not
# executable scripts -- a deterministic canonical test cannot "run" /aid-fix. This suite is
# therefore CONTRACT + FIXTURE-SHAPE, matching the other work-001 shortcut-engine suites:
#
#   1. Contract assertions -- grep shortcut-scaffolding/fix.md for the load-bearing
#      elements: the fix-kind slot (closed 4-enum), the default task-001 IMPLEMENT ->
#      task-002 TEST breakdown, the 4 fix-kind adaptations, and the Ownership-boundary
#      routing table (feature-008 SPEC).
#   2. "aid-fix stays bare" (AC-4) -- checked against the REAL catalog + skill dirs: exactly
#      one `aid-fix` row, no artifact-suffixed variant, no alias, no `aid-fix-*` directory.
#   3. Fixture-shape assertions -- two hand-authored flattened work fixtures mirroring what
#      `/aid-fix` would produce: a `vulnerability`-kind one (`### Security Specs` activated,
#      `task-002` proves the exploit path closed) and a `defect`-kind one (base 2-task
#      shape, no Security Specs). Both halt pre-Execute (no task past Pending) -- this also
#      doubles as feature-003's engine smoke: the full flattened REQUIREMENTS/SPEC/PLAN/
#      BLUEPRINT/tasks set, no execution.
#
# No agent is invoked; nothing here dispatches aid-architect/aid-reviewer.
#
# Usage:
#   bash tests/canonical/test-fix-family-scaffold.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIX_SCAFFOLD="${REPO_ROOT}/canonical/aid/templates/shortcut-scaffolding/fix.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"

echo "=== aid-fix family scaffold + halt proof (task-014, feature-008 + engine smoke) ==="

assert_file_exists "$FIX_SCAFFOLD" "FFS00a shortcut-scaffolding/fix.md exists"
assert_file_exists "$CATALOG" "FFS00b shortcut-catalog.yml exists"
assert_dir_exists "$SKILLS_ROOT" "FFS00c canonical/skills/ exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

FIX_TXT=$(cat "$FIX_SCAFFOLD")

# ===========================================================================
# Part 1 -- Contract assertions against shortcut-scaffolding/fix.md
# ===========================================================================
echo "--- Part 1: fix.md contract assertions ---"

# FFS-01: fix-kind slot, closed 4-enum.
assert_output_contains "$FIX_TXT" \
    'closed enum: `defect` \| `regression` \| `incident` \| `vulnerability`' \
    "FFS01 fix-kind is a closed 4-enum (defect|regression|incident|vulnerability)"

# FFS-02: default task breakdown -- task-001 IMPLEMENT -> task-002 TEST depends on task-001.
assert_output_contains "$FIX_TXT" \
    '| `task-001` | `IMPLEMENT` | "Reproduce, root-cause, and patch {bug}" | -- (none) |' \
    "FFS02a default breakdown: task-001 IMPLEMENT, no dependency"
assert_output_contains "$FIX_TXT" \
    '| `task-002` | `TEST` | "Regression test that fails on pre-fix code and passes on post-fix code" | `task-001` |' \
    "FFS02b default breakdown: task-002 TEST depends on task-001"

# FFS-03: the 4 fix-kind adaptations (defect / regression / vulnerability / incident).
assert_output_contains "$FIX_TXT" \
    '| `vulnerability` | `### Security Specs` | the exploit path and the closure mechanism' \
    "FFS03a vulnerability fix-kind activates ### Security Specs"
assert_output_contains "$FIX_TXT" \
    'proves the **exploit path is closed**, not just that the symptom disappeared' \
    "FFS03b vulnerability task-002 proves the exploit path is closed"
assert_output_contains "$FIX_TXT" \
    'the **postmortem / runbook document is a separate deliverable**' \
    "FFS03c incident fix-kind routes the postmortem/runbook out of aid-fix"
assert_output_contains "$FIX_TXT" \
    'reproduction is **pinned to the regressing commit/change**' \
    "FFS03d regression fix-kind pins reproduction to the regressing change"

# FFS-04: Ownership-boundary routing table (out-of-scope destinations).
for route in "aid-test-security" "aid-document-runbook" "aid-test" "aid-change" "aid-refactor" "aid-change-infra"; do
    assert_output_contains "$FIX_TXT" "$route" "FFS04 [${route}] named as a routing destination in the Ownership boundary"
done

echo ""
echo "--- Part 2: aid-fix stays bare (AC-4) -- checked against the real catalog + skill dirs ---"

# FFS-10: exactly one catalog row named exactly "aid-fix"; no artifact-suffixed variant.
EXACT_ROWS=$(grep -c '^  - name: aid-fix$' "$CATALOG" || true)
assert_eq "$EXACT_ROWS" "1" "FFS10 exactly one catalog row named exactly aid-fix"

SUFFIXED_ROWS=$(grep -E '^  - name: aid-fix-' "$CATALOG" || true)
if [[ -z "$SUFFIXED_ROWS" ]]; then
    pass "FFS11 no artifact-suffixed aid-fix-* catalog row exists"
else
    fail "FFS11 no artifact-suffixed aid-fix-* catalog row exists -- found: ${SUFFIXED_ROWS}"
fi

# FFS-12: no alias row points at aid-fix (aid-fix has no alias family).
ALIAS_ROWS=$(grep -E '^    alias_of: aid-fix$' "$CATALOG" || true)
if [[ -z "$ALIAS_ROWS" ]]; then
    pass "FFS12 no catalog row carries alias_of: aid-fix (no alias family)"
else
    fail "FFS12 no catalog row carries alias_of: aid-fix -- found an alias row"
fi

# FFS-13: canonical/skills/ has no aid-fix-* directory (only the bare aid-fix dir).
SUFFIXED_DIRS=$(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'aid-fix-*' 2>/dev/null || true)
if [[ -z "$SUFFIXED_DIRS" ]]; then
    pass "FFS13 no canonical/skills/aid-fix-* directory exists"
else
    fail "FFS13 no canonical/skills/aid-fix-* directory exists -- found: ${SUFFIXED_DIRS}"
fi
assert_dir_exists "${SKILLS_ROOT}/aid-fix" "FFS14 canonical/skills/aid-fix/ (the one bare doorway) exists"

# ===========================================================================
# Part 3 -- Fixture-shape assertions (vulnerability + defect)
# ===========================================================================
echo ""
echo "--- Part 3: fixture-shape assertions ---"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_fix_fixture <work-dir> <fix-kind> <title>
# Hand-authors a flattened work mirroring what /aid-fix + shortcut-engine.md would produce
# for the given fix-kind, per shortcut-scaffolding/fix.md's own default breakdown +
# fix-kind adaptations, halted at APPROVAL-HALT (pre-Execute).
build_fix_fixture() {
    local work_dir="$1" kind="$2" title="$3"
    mkdir -p "${work_dir}/tasks/task-001" "${work_dir}/tasks/task-002"

    local security_section="" task2_ac
    if [[ "$kind" == "vulnerability" ]]; then
        security_section='

### Security Specs

The exploit path exercised by the reproduction steps and the closure mechanism the patch
applies. A deep SAST/DAST scan or dependency audit is out of scope for this task set --
route that to aid-test-security.'
        task2_ac="Regression test proves the exploit path is closed (fails against the pre-fix code, passes against the post-fix code)."
    else
        task2_ac="Regression test fails against the pre-fix code and passes against the post-fix code."
    fi

    cat > "${work_dir}/REQUIREMENTS.md" <<EOF
# Requirements

- **Name:** ${title}
- **Description:** Diagnose and correct ${title}.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-08 | Initial capture (shortcut: aid-fix) | /aid-fix |

## 1. Objective

Correct ${title}.

## 2. Problem Statement

${title} is observably wrong; reproduction steps below.

## 3. Users & Stakeholders

The requesting developer/maintainer.

## 4. Scope

fix-kind: ${kind}. Affected area inferred from reproduction steps.

## 5. Functional Requirements

Reproduce, root-cause, and patch ${title}; add a regression test proving the fix.

## 6. Non-Functional Requirements

N/A

## 7. Constraints

N/A

## 8. Assumptions & Dependencies

*(pending)*

## 9. Acceptance Criteria

- [ ] Given the reproduction steps, when the patch is applied, then the symptom no longer occurs.
- [ ] Given the regression test, when run pre-fix, then it fails; when run post-fix, then it passes.

## 10. Priority

Must
EOF

    cat > "${work_dir}/SPEC.md" <<EOF
# ${title}

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-08 | SPEC authored from REQUIREMENTS.md | /aid-fix |

## Source

- REQUIREMENTS.md §5 Functional Requirements
- REQUIREMENTS.md §9 Acceptance Criteria

## Description

Diagnose and correct ${title}.

## User Stories

- As an AID adopter with a known ${kind}, I want it fixed without the interview.

## Priority

Must

## Acceptance Criteria

- [ ] Given the reproduction steps, when the patch is applied, then the symptom no longer occurs.

---

## Technical Specification

### Data Model

No schema changes.

### Feature Flow

Reproduce -> root-cause -> patch -> regression test.

### Layers & Components

The affected module identified during reproduction.${security_section}
EOF

    cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- ${title}

> **Work:** work-NNN-fix-sample-${kind}
> **Created:** 2026-07-08

---

## Deliverables

- **Delivery:** delivery-001 -- ${title}
- **What it delivers:** the fix + regression test for ${title}.
- **Features:** feature-001-fix-sample-${kind}
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

    cat > "${work_dir}/BLUEPRINT.md" <<EOF
# Delivery BLUEPRINT -- delivery-001: ${title}

> **Delivery:** delivery-001
> **Work:** work-NNN-fix-sample-${kind}
> **Created:** 2026-07-08

---

## Objective

Diagnose and correct ${title}.

## Scope

fix-kind: ${kind}.

**Out of scope:** broad test authoring, security verification beyond the one exploit path, postmortem/runbook authoring.

## Gate Criteria

- [ ] The patch resolves the reported symptom.
- [ ] The regression test fails pre-fix and passes post-fix.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Reproduce, root-cause, and patch ${title} |
| task-002 | TEST | ${task2_ac} |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-fix (fix, artifact '').
EOF

    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: Reproduce, root-cause, and patch ${title}

**Type:** IMPLEMENT

**Source:** work-NNN-fix-sample-${kind} -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Reproduce ${title}, identify the root cause, and apply the patch.

**Acceptance Criteria:**
- [ ] Given the reproduction steps, when the patch is applied, then the symptom no longer occurs.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/tasks/task-002/DETAIL.md" <<EOF
# task-002: Regression test for ${title}

**Type:** TEST

**Source:** work-NNN-fix-sample-${kind} -> delivery-001

**Depends on:** task-001

**Scope:**
- ${task2_ac}

**Acceptance Criteria:**
- [ ] The regression test fails when run against the pre-fix code.
- [ ] The regression test passes when run against the post-fix code.
- [ ] All section-6 quality gates pass.
EOF

    cat > "${work_dir}/STATE.md" <<EOF
# Work State -- work-NNN-fix-sample-${kind}

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** aid-fix
- **Updated:** 2026-07-08T12:00:00Z
- **Pause Reason:** GATE cleared; awaiting user approval before /aid-execute
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Lifecycle

- **State:** Specified
- **Updated:** 2026-07-08T12:00:00Z
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
# Fixture A: vulnerability
# ---------------------------------------------------------------------------
VULN_DIR="${TMP}/work-vuln"
build_fix_fixture "$VULN_DIR" "vulnerability" "SQL injection in the /orders search endpoint"

assert_file_contains "${VULN_DIR}/SPEC.md" "### Security Specs" \
    "FFS20 vulnerability fixture: SPEC.md activates ### Security Specs"
assert_file_contains "${VULN_DIR}/tasks/task-001/DETAIL.md" "**Type:** IMPLEMENT" \
    "FFS21 vulnerability fixture: task-001 is IMPLEMENT"
assert_file_contains "${VULN_DIR}/tasks/task-002/DETAIL.md" "**Type:** TEST" \
    "FFS22 vulnerability fixture: task-002 is TEST"
assert_file_contains "${VULN_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "FFS23 vulnerability fixture: task-002 depends on task-001"
assert_file_contains "${VULN_DIR}/tasks/task-002/DETAIL.md" "exploit path is closed" \
    "FFS24 vulnerability fixture: task-002 proves the exploit path is closed (not just symptom-gone)"

# ---------------------------------------------------------------------------
# Fixture B: defect
# ---------------------------------------------------------------------------
DEFECT_DIR="${TMP}/work-defect"
build_fix_fixture "$DEFECT_DIR" "defect" "off-by-one pagination bug"

if grep -q "### Security Specs" "${DEFECT_DIR}/SPEC.md"; then
    fail "FFS30 defect fixture: SPEC.md does NOT activate ### Security Specs (base Feature Flow only)"
else
    pass "FFS30 defect fixture: SPEC.md does NOT activate ### Security Specs (base Feature Flow only)"
fi
assert_file_contains "${DEFECT_DIR}/tasks/task-001/DETAIL.md" "**Type:** IMPLEMENT" \
    "FFS31 defect fixture: task-001 is IMPLEMENT"
assert_file_contains "${DEFECT_DIR}/tasks/task-002/DETAIL.md" "**Type:** TEST" \
    "FFS32 defect fixture: task-002 is TEST"
assert_file_contains "${DEFECT_DIR}/tasks/task-002/DETAIL.md" "**Depends on:** task-001" \
    "FFS33 defect fixture: task-002 depends on task-001"
if grep -q "exploit path is closed" "${DEFECT_DIR}/tasks/task-002/DETAIL.md"; then
    fail "FFS34 defect fixture: task-002 does NOT carry the vulnerability-only 'exploit path closed' wording"
else
    pass "FFS34 defect fixture: task-002 does NOT carry the vulnerability-only 'exploit path closed' wording"
fi
# Base 2-task shape -- exactly task-001 and task-002, no task-003.
DEFECT_TASK_COUNT=$(find "${DEFECT_DIR}/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$DEFECT_TASK_COUNT" "2" "FFS35 defect fixture: base 2-task shape (exactly task-001, task-002)"
assert_file_contains "${DEFECT_DIR}/STATE.md" "**Active Skill:** aid-fix" \
    "FFS36 defect fixture: Active Skill is aid-fix (stays bare -- AC-4, not aid-fix-defect)"

# ---------------------------------------------------------------------------
# Both fixtures: halt-proof + engine-smoke shape (feature-003 FR-3/FR-4/FR-6/FR-10).
# ---------------------------------------------------------------------------
for FIXTURE_DIR in "$VULN_DIR" "$DEFECT_DIR"; do
    kind_label=$(basename "$FIXTURE_DIR")

    # Full flattened artifact set present.
    for f in REQUIREMENTS.md SPEC.md PLAN.md BLUEPRINT.md; do
        assert_file_exists "${FIXTURE_DIR}/${f}" "FFS40 [${kind_label}] ${f} present (engine smoke: full flattened set)"
    done
    for t in task-001 task-002; do
        assert_file_exists "${FIXTURE_DIR}/tasks/${t}/DETAIL.md" "FFS41 [${kind_label}] tasks/${t}/DETAIL.md present"
        if [[ -f "${FIXTURE_DIR}/tasks/${t}/STATE.md" ]]; then
            fail "FFS42 [${kind_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        else
            pass "FFS42 [${kind_label}] tasks/${t}/ has no sibling STATE.md (flat layout has none)"
        fi
    done

    # No ### delivery-NNN heading in PLAN.md (feature-001 parser-compatibility constraint).
    if grep -qE '^### delivery-' "${FIXTURE_DIR}/PLAN.md"; then
        fail "FFS43 [${kind_label}] PLAN.md carries no ### delivery-NNN heading"
    else
        pass "FFS43 [${kind_label}] PLAN.md carries no ### delivery-NNN heading"
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
    assert_eq "$NOT_PENDING" "0" "FFS44 [${kind_label}] every task is Pending -- halts pre-Execute (FR-10)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "FFS45 [${kind_label}] Delivery Lifecycle State is Specified (tasks defined, not Executing)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "FFS46 [${kind_label}] Pipeline Lifecycle is Paused-Awaiting-Input (halted for approval)"
done

echo ""
test_summary
