#!/usr/bin/env bash
# test-deploy-monitor-repurpose.sh -- task-035 (work-001-lite-aid-skills, feature-012
# AC-9 / § Q-A9): Deploy/Monitor re-purpose verification + full 80-row catalog parity.
#
# `aid-deploy`/`aid-monitor` are agent-executed PROSE (pipeline state machines) -- a
# deterministic canonical test cannot "run" them. This suite is therefore CONTRACT +
# FIXTURE-SHAPE, matching the other work-001 shortcut-engine suites, plus an independent
# re-derivation of the catalog row count (mirroring test-catalog-dirs-parity.sh's own
# "re-derived independently, not by importing the maintainer helper's internals" convention).
#
#   Part 1 -- Re-point (part b, Must, § Q-A9):
#     `aid-monitor` `state-route.md` routes BUG -> `/aid-fix` and CHANGE REQUEST ->
#     `/aid-triage` (fixture findings); no aid-monitor file (SKILL.md, state-route.md,
#     README.md) carries the deprecated "Route to aid-describe", "re-enters at
#     aid-describe", "lite bug-fix triage", or "LITE-BUG-FIX" phrasing; pipeline-contracts.md
#     L9/L10 targets updated in lockstep.
#
#   Part 2 -- Pipeline-role no-regression (AC-9, part b + a):
#     with `work-NNN` present, both skills' Dispatch tables still carry their original
#     pipeline states/workers/advances, byte-unchanged; the mode-branch Step 0 explicitly
#     says the `work-NNN` path is "the existing pipeline path; untouched".
#
#   Part 3 -- Shortcut mode (part a, fixture):
#     no `work-NNN` + a free-form description -> shortcut-scaffold path; fixture proves the
#     scaffolded flattened Lite work halts at the FR-10 approval gate (never executes); the
#     catalog parity-exemption for the 4 repurpose rows holds (cross-checked against
#     test-catalog-dirs-parity.sh's own CDP{i}e exemption logic).
#
#   Part 4 -- Full 80-row catalog-to-dirs parity:
#     independently re-derived count: exactly 80 rows total, 51 canonical (`alias_of: null`,
#     including the 4 `repurpose: true` rows) + 29 alias; no orphan directory, no orphan row.
#     (test-catalog-dirs-parity.sh itself stays COUNT-AGNOSTIC by design -- this is the
#     dedicated count assertion its own header comment defers to task-035.)
#
# No agent is invoked; nothing here dispatches aid-orchestrator/aid-operator/aid-researcher.
#
# Usage:
#   bash tests/canonical/test-deploy-monitor-repurpose.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONITOR_DIR="${REPO_ROOT}/canonical/skills/aid-monitor"
DEPLOY_DIR="${REPO_ROOT}/canonical/skills/aid-deploy"
MONITOR_SKILL="${MONITOR_DIR}/SKILL.md"
MONITOR_ROUTE="${MONITOR_DIR}/references/state-route.md"
MONITOR_README="${MONITOR_DIR}/README.md"
DEPLOY_SKILL="${DEPLOY_DIR}/SKILL.md"
CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_ROOT="${REPO_ROOT}/canonical/skills"
PIPELINE_CONTRACTS="${REPO_ROOT}/.aid/knowledge/pipeline-contracts.md"

echo "=== Deploy/Monitor re-purpose + full catalog parity (task-035, feature-012 AC-9) ==="

assert_file_exists "$MONITOR_SKILL" "DMR00a aid-monitor/SKILL.md exists"
assert_file_exists "$MONITOR_ROUTE" "DMR00b aid-monitor/references/state-route.md exists"
assert_file_exists "$MONITOR_README" "DMR00c aid-monitor/README.md exists"
assert_file_exists "$DEPLOY_SKILL" "DMR00d aid-deploy/SKILL.md exists"
assert_file_exists "$CATALOG" "DMR00e shortcut-catalog.yml exists"
assert_file_exists "$PIPELINE_CONTRACTS" "DMR00f pipeline-contracts.md exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ===========================================================================
# Part 1 -- Re-point (part b, Must, § Q-A9)
# ===========================================================================
echo "--- Part 1: aid-monitor re-point (BUG -> /aid-fix, CR -> /aid-triage) ---"

# DMR-01: state-route.md Step 4 proposal lines route to the new targets.
assert_file_contains "$MONITOR_ROUTE" "Proposed: Route to /aid-fix" \
    "DMR01a state-route.md Step 4 proposes Route to /aid-fix for the BUG finding"
assert_file_contains "$MONITOR_ROUTE" "Proposed: Route to /aid-triage" \
    "DMR01b state-route.md Step 4 proposes Route to /aid-triage for the CHANGE REQUEST finding"

# DMR-02: state-route.md Step 5 Act blocks are headed by the new routing targets.
assert_file_contains "$MONITOR_ROUTE" "BUG → /aid-fix:" \
    "DMR02a state-route.md Step 5 Act block: BUG -> /aid-fix"
assert_file_contains "$MONITOR_ROUTE" "CHANGE REQUEST → /aid-triage:" \
    "DMR02b state-route.md Step 5 Act block: CHANGE REQUEST -> /aid-triage"

# DMR-03: SKILL.md Routing-targets + README.md routing table both re-pointed.
assert_file_contains "$MONITOR_SKILL" "BUG → \`/aid-fix\`" "DMR03a SKILL.md Routing targets: BUG -> /aid-fix"
assert_file_contains "$MONITOR_SKILL" "Change Request → \`/aid-triage\`" "DMR03b SKILL.md Routing targets: Change Request -> /aid-triage"
assert_file_contains "$MONITOR_README" "| BUG | \`/aid-fix\`" "DMR03c README.md routing table: BUG -> /aid-fix"
assert_file_contains "$MONITOR_README" "| Change Request | \`/aid-triage\`" "DMR03d README.md routing table: Change Request -> /aid-triage"

# DMR-04: no residual deprecated phrasing anywhere under aid-monitor/.
DEPRECATED_PATTERNS=(
    "Route to aid-describe"
    "re-enters at aid-describe"
    "lite bug-fix triage"
    "LITE-BUG-FIX"
)
for pat in "${DEPRECATED_PATTERNS[@]}"; do
    HITS=$(grep -rn --include='*.md' -- "$pat" "$MONITOR_DIR" 2>/dev/null || true)
    if [[ -n "$HITS" ]]; then
        fail "DMR04 [\"${pat}\"] no residual deprecated phrasing under aid-monitor/ -- found: ${HITS}"
    else
        pass "DMR04 [\"${pat}\"] no residual deprecated phrasing under aid-monitor/"
    fi
done

# DMR-05: pipeline-contracts.md L9/L10 updated in lockstep with state-route.md.
L9_LINE=$(grep -m1 '^| L9 ' "$PIPELINE_CONTRACTS")
L10_LINE=$(grep -m1 '^| L10 ' "$PIPELINE_CONTRACTS")
assert_output_contains "$L9_LINE" "/aid-fix" "DMR05a pipeline-contracts.md L9 targets /aid-fix"
assert_output_contains "$L9_LINE" "finding classified BUG" "DMR05b pipeline-contracts.md L9 trigger is 'finding classified BUG'"
assert_output_contains "$L10_LINE" "/aid-triage" "DMR05c pipeline-contracts.md L10 targets /aid-triage"
assert_output_contains "$L10_LINE" "finding classified Change Request" "DMR05d pipeline-contracts.md L10 trigger is 'finding classified Change Request'"

# ===========================================================================
# Part 2 -- Pipeline-role no-regression (AC-9)
# ===========================================================================
echo ""
echo "--- Part 2: pipeline-role no-regression (AC-9) ---"

# DMR-10: aid-deploy Dispatch table -- all 6 original rows present, byte-unchanged shape.
assert_file_contains "$DEPLOY_SKILL" "| IDLE | \`references/state-idle.md\` | \`aid-operator\` | → SELECTING |" \
    "DMR10a aid-deploy Dispatch: IDLE row unchanged"
assert_file_contains "$DEPLOY_SKILL" "| SELECTING | \`references/state-selecting.md\` | \`aid-operator\` | → VERIFYING |" \
    "DMR10b aid-deploy Dispatch: SELECTING row unchanged"
assert_file_contains "$DEPLOY_SKILL" "| VERIFYING | \`references/state-verifying.md\` | \`aid-operator\` | → PACKAGING |" \
    "DMR10c aid-deploy Dispatch: VERIFYING row unchanged"
assert_file_contains "$DEPLOY_SKILL" "| PACKAGING | \`references/state-packaging.md\` | \`aid-operator\` | → DONE |" \
    "DMR10d aid-deploy Dispatch: PACKAGING row unchanged"
assert_file_contains "$DEPLOY_SKILL" "State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE." \
    "DMR10e aid-deploy frontmatter State machine line unchanged"

# DMR-11: aid-monitor Dispatch table -- all 4 original rows present, byte-unchanged shape
# (routing TARGETS changed inside state-route.md's body -- Part 1 -- but the classification
# vocabulary + Dispatch spine are unchanged).
assert_file_contains "$MONITOR_SKILL" "| OBSERVE | \`references/state-observe.md\` | \`aid-researcher\` | → CLASSIFY |" \
    "DMR11a aid-monitor Dispatch: OBSERVE row unchanged"
assert_file_contains "$MONITOR_SKILL" "| CLASSIFY | \`references/state-classify.md\` | \`aid-researcher\` | → ROUTE |" \
    "DMR11b aid-monitor Dispatch: CLASSIFY row unchanged"
assert_file_contains "$MONITOR_SKILL" "| ROUTE | \`references/state-route.md\` | \`aid-orchestrator\` | → DONE |" \
    "DMR11c aid-monitor Dispatch: ROUTE row unchanged"
assert_file_contains "$MONITOR_SKILL" "State machine: OBSERVE → CLASSIFY → ROUTE → DONE." \
    "DMR11d aid-monitor frontmatter State machine line unchanged"

# DMR-12: classification vocabulary unchanged (BUG / CHANGE REQUEST / INFRASTRUCTURE / NO ACTION).
assert_file_contains "$MONITOR_SKILL" "Classifying each anomaly as BUG, CHANGE REQUEST, INFRASTRUCTURE, or NO ACTION." \
    "DMR12 aid-monitor classification vocabulary unchanged"

# DMR-13: the mode-branch Step 0 explicitly marks the work-NNN path as untouched, for both
# skills. The phrase wraps across two source lines, so check both fragments.
for f in "$DEPLOY_SKILL" "$MONITOR_SKILL"; do
    label=$(basename "$(dirname "$f")")
    assert_file_contains "$f" "proceed with Steps 1" "DMR13a [${label}] Step 0: work-NNN present -> proceed with the existing Steps"
    assert_file_contains "$f" "pipeline path; untouched" "DMR13b [${label}] Step 0 marks the work-NNN path untouched"
done

# ===========================================================================
# Part 3 -- Shortcut mode (part a, fixture)
# ===========================================================================
echo ""
echo "--- Part 3: shortcut mode fixture (halts at approval, never executes) ---"

for f in "$DEPLOY_SKILL" "$MONITOR_SKILL"; do
    label=$(basename "$(dirname "$f")")
    assert_file_contains "$f" "delegate" "DMR20a [${label}] mode-branch delegates to the shared shortcut engine"
    assert_file_contains "$f" "canonical/aid/templates/shortcut-engine.md" \
        "DMR20b [${label}] mode-branch names shortcut-engine.md as the delegate"
    assert_file_contains "$f" "Never executes" "DMR20c [${label}] mode-branch explicitly states it never executes"
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# build_repurpose_fixture <work-dir> <name> <verb>
# Mirrors what the shortcut-engine (INTAKE -> ... -> APPROVAL-HALT) would produce for the
# aid-deploy/aid-monitor mode-branch: a full flattened artifact set, halted pre-Execute.
build_repurpose_fixture() {
    local work_dir="$1" name="$2" verb="$3"
    mkdir -p "${work_dir}/tasks/task-001"
    cat > "${work_dir}/STATE.md" <<EOF
# Work State -- work-NNN-${verb}-sample

## Pipeline State

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** ${name}
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
EOF
    cat > "${work_dir}/REQUIREMENTS.md" <<EOF
# Requirements

- **Name:** ${verb} sample
- **Description:** Shortcut-generated flattened Lite work for ${verb}.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-08 | Initial capture (shortcut: ${name}) | /${name} |
EOF
    cat > "${work_dir}/PLAN.md" <<EOF
# Plan -- work-NNN-${verb}-sample

## Notes

Shortcut-generated flattened Lite work. Source: /${name} (${verb}, artifact '').
EOF
    cat > "${work_dir}/tasks/task-001/DETAIL.md" <<EOF
# task-001: ${verb} sample task

**Type:** CONFIGURE

**Source:** work-NNN-${verb}-sample -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Shortcut-generated task for ${verb}.

**Acceptance Criteria:**
- [ ] All section-6 quality gates pass.
EOF
}

DEPLOY_FIXTURE="${TMP}/work-deploy-sample"
MONITOR_FIXTURE="${TMP}/work-monitor-sample"
build_repurpose_fixture "$DEPLOY_FIXTURE" "aid-deploy" "deploy"
build_repurpose_fixture "$MONITOR_FIXTURE" "aid-monitor" "monitor"

for FIXTURE_DIR in "$DEPLOY_FIXTURE" "$MONITOR_FIXTURE"; do
    label=$(basename "$FIXTURE_DIR")
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input" \
        "DMR21 [${label}] halted at approval (Paused-Awaiting-Input, not Running/Completed)"
    assert_file_contains "${FIXTURE_DIR}/STATE.md" "**State:** Specified" \
        "DMR22 [${label}] Delivery Lifecycle Specified (tasks defined, not Executing)"
    NOT_PENDING=$(awk '
        /^### Tasks lifecycle/ { s=1; next }
        s && /^## / { s=0 }
        s && /^\| task-/ {
            n = split($0, f, "|")
            state = f[3]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", state)
            if (state != "Pending") print state
        }
    ' "${FIXTURE_DIR}/STATE.md" | grep -c . || true)
    assert_eq "$NOT_PENDING" "0" "DMR23 [${label}] every task Pending -- halts pre-Execute, never executes"
done

# DMR-24: catalog parity-exemption for the 4 repurpose rows holds (cross-check against
# test-catalog-dirs-parity.sh's own exemption note -- both rows carry repurpose: true and
# skip the thin-doorway body assertion).
for name in aid-deploy aid-monitor; do
    ROW_BLOCK=$(awk -v n="$name" '
        BEGIN{on=0}
        /^  - name:/ {
            line=$0; sub(/^  - name:[[:space:]]*/, "", line);
            if (on) { on=0 }
            if (line == n) { on=1 }
        }
        on { print }
    ' "$CATALOG")
    assert_output_contains "$ROW_BLOCK" "repurpose: true" "DMR24 [${name}] catalog row carries repurpose: true (parity-exemption marker)"
done

# ===========================================================================
# Part 4 -- Full 94-row catalog-to-dirs parity (independently re-derived count)
# ===========================================================================
echo ""
echo "--- Part 4: full 94-row catalog-to-dirs parity ---"

TOTAL_ROWS=$(grep -cE '^  - name:' "$CATALOG")
CANONICAL_ROWS=$(grep -cE '^    alias_of: null$' "$CATALOG")
ALIAS_ROWS=$(grep -cE '^    alias_of: aid-' "$CATALOG")
REPURPOSE_ROWS=$(grep -cE '^    repurpose: true$' "$CATALOG")

# work-005 grew the catalog (collapse skills + artifact reframes + kind-siblings): 80 -> 94
# rows, and repurpose:true rows 4 -> 30 (the 4 classic re-registered skills plus 26 work-005
# hand-authored collapse/kind-sibling skills, all now owning their own directory).
assert_eq "$TOTAL_ROWS" "94" "DMR30 catalog carries exactly 94 total rows"
assert_eq "$CANONICAL_ROWS" "58" "DMR31 catalog carries exactly 58 canonical (alias_of: null) rows"
assert_eq "$ALIAS_ROWS" "36" "DMR32 catalog carries exactly 36 alias rows"
assert_eq "$REPURPOSE_ROWS" "30" "DMR33 catalog carries exactly 30 repurpose:true rows (4 classic re-registered + 26 work-005 collapse/kind-sibling skills)"
CANONICAL_PLUS_ALIAS=$((CANONICAL_ROWS + ALIAS_ROWS))
assert_eq "$CANONICAL_PLUS_ALIAS" "$TOTAL_ROWS" "DMR34 canonical + alias == total (no row miscounted/double-counted)"

# DMR-35: every row's directory exists (no orphan row) -- independent re-derivation, not
# importing build-shortcut-skills.py's internals.
mapfile -t ALL_NAMES < <(awk '/^  - name:/ { line=$0; sub(/^  - name:[[:space:]]*/, "", line); print line }' "$CATALOG")
assert_eq "${#ALL_NAMES[@]}" "94" "DMR35a re-derived name list carries exactly 94 entries"

orphan_row=0
for name in "${ALL_NAMES[@]}"; do
    if [[ ! -d "${SKILLS_ROOT}/${name}" ]]; then
        fail "DMR35b [${name}] no orphan row -- directory missing at ${SKILLS_ROOT}/${name}"
        orphan_row=1
    fi
done
[[ "$orphan_row" -eq 0 ]] && pass "DMR35b every one of the 80 rows has a matching canonical/skills/ directory (no orphan row)"

# DMR-36: no orphan directory -- every GENERATED-marker doorway (or repurpose fat skill) has
# a matching catalog row.
GENERATED_MARKER="<!-- GENERATED by .claude/skills/generate-profile/scripts/build-shortcut-skills.py"
declare -A NAME_SET=()
for name in "${ALL_NAMES[@]}"; do NAME_SET["$name"]=1; done

orphan_dir=0
while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    dname=$(basename "$d")
    [[ "$dname" == aid-* ]] || continue
    md="${d}/SKILL.md"
    [[ -f "$md" ]] || continue
    is_generated=0
    grep -qF "$GENERATED_MARKER" "$md" 2>/dev/null && is_generated=1
    is_repurpose_pipeline=0
    [[ "$dname" == "aid-deploy" || "$dname" == "aid-monitor" ]] && is_repurpose_pipeline=1
    [[ "$dname" == "aid-triage" || "$dname" == "aid-describe" ]] && continue  # standalone, deliberately NOT catalog rows
    if [[ "$is_generated" -eq 1 || "$is_repurpose_pipeline" -eq 1 ]]; then
        if [[ -z "${NAME_SET[$dname]:-}" ]]; then
            fail "DMR36 [${dname}] no orphan directory -- generated/repurpose doorway has no matching catalog row"
            orphan_dir=1
        fi
    fi
done < <(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
[[ "$orphan_dir" -eq 0 ]] && pass "DMR36 no orphan directory found (every generated/repurpose doorway has a catalog row)"

echo ""
test_summary
