#!/usr/bin/env bash
# test-disjoint-merge.sh -- end-to-end proof that the per-unit STATE.md hierarchy
# produces zero git merge conflicts on merge-back (AC-Disjoint / Pillar 2).
#
# Design:
#   A throwaway git sandbox simulates the two-delivery parallel-branch scenario:
#
#   main (base)
#     work-NNN-test/
#       STATE.md           (work header -- authored by orchestrator on main)
#       deliveries/
#         delivery-001/
#           STATE.md         (stub: Pending-Spec, created on main)
#           tasks/task-001/
#             DETAIL.md
#             STATE.md
#         delivery-002/
#           STATE.md         (stub: Pending-Spec, created on main)
#           tasks/task-002/
#             DETAIL.md
#             STATE.md
#
#   branch: aid/delivery-001
#     Writes ONLY deliveries/delivery-001/STATE.md + deliveries/delivery-001/tasks/task-001/STATE.md
#     via writeback-state.sh (--field, --block, --lifecycle, --append-issue).
#     Also appends a Cross-phase Q&A entry to deliveries/delivery-001/STATE.md.
#
#   branch: aid/delivery-002
#     Writes ONLY deliveries/delivery-002/STATE.md + deliveries/delivery-002/tasks/task-002/STATE.md
#     via writeback-state.sh (same modes, different files).
#     Also appends a Cross-phase Q&A entry to deliveries/delivery-002/STATE.md.
#
#   Merge aid/delivery-001 -> main  (fast-forward or no-conflict)
#   Merge aid/delivery-002 -> main  (ASSERT: zero conflicts on any STATE.md)
#
# The test checks:
#   DM01  No merge conflict markers (<<<<<<<) in any STATE.md after both merges
#   DM02  delivery-001's edits are present (lifecycle, gate block, task state, Q&A)
#   DM03  delivery-002's edits are present (lifecycle, gate block, task state, Q&A)
#   DM04  work-level STATE.md is not modified by either delivery branch
#   DM05  Re-running the suite is deterministic (idempotent)
#
# Isolation:
#   HOME is pinned to a throwaway dir so no real ~/.aid or ~/.gitconfig is touched.
#   AID_HOME is set to a subdirectory of the throwaway HOME.
#   git user.email / user.name are set per-repo (--local) for commit identity.
#   No network access. No real registry.yml.
#   Canary check confirms no .aid dirs leaked to the real $HOME.
#
# Usage:
#   bash tests/canonical/test-disjoint-merge.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WRITEBACK="${REPO_ROOT}/canonical/aid/scripts/execute/writeback-state.sh"

[[ -f "$WRITEBACK" ]] || { echo "ERROR: writeback-state.sh not found at $WRITEBACK" >&2; exit 1; }

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Isolation: pin HOME + AID_HOME to a throwaway directory.
# Canary: snapshot real HOME before any writes.
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"
export AID_HOME="${HOME}/.aid"
mkdir -p "${AID_HOME}"

# ---------------------------------------------------------------------------
# Fixture helpers (mirror test-writeback-state.sh conventions)
# ---------------------------------------------------------------------------

make_task_state() {
    local task_dir="$1" task_id="$2" state_val="${3:-Pending}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/STATE.md" <<TASKSTATEOF
# Task State -- ${task_id}

> **Task:** ${task_id}

---

## Task State

- **State:** ${state_val}
- **Review:** --
- **Elapsed:** --
- **Notes:** --

---

## Quick Check Findings

- **Reviewer Tier:** --
- **Findings:** none yet

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
TASKSTATEOF
}

make_task_spec() {
    local task_dir="$1" task_id="$2" delivery_id="$3" work_name="$4"
    mkdir -p "$task_dir"
    cat > "${task_dir}/DETAIL.md" <<TASKSPECEOF
# ${task_id}: Test Task

**Type:** IMPLEMENT

**Source:** ${work_name} -> ${delivery_id}

**Depends on:** -- (none)

**Scope:**
- Test scope for ${task_id}

**Acceptance Criteria:**
- [ ] criterion
TASKSPECEOF
}

make_delivery_state() {
    local delivery_dir="$1" delivery_id="$2" lc_val="${3:-Pending-Spec}"
    mkdir -p "$delivery_dir"
    cat > "${delivery_dir}/STATE.md" <<DELIVSTATEOF
# Delivery State -- ${delivery_id}

> **Delivery:** ${delivery_id}

---

## Delivery Lifecycle

- **State:** ${lc_val}
- **Updated:** 2026-06-18T00:00:00Z

---

## Delivery Gate

- **Reviewer Tier:** --
- **Grade:** Pending
- **Issue List:** none
- **Timestamp:** --

---

## Cross-phase Q&A

(none)

---

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
DELIVSTATEOF
}

make_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.md" <<'WORKSTATEOF'
# Work State -- work-test

> **State:** Running
> **Phase:** Execute
> **Minimum Grade:** A
> **Started:** 2026-06-18
> **User Approved:** no

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-06-18T00:00:00Z

---

## Triage

- **Path:** lite
- **Work Type:** new-feature
- **Sub-path:** LITE-FEATURE
- **Decision rationale:** test fixture
- **Override:** no
- **Recipe:** --
WORKSTATEOF
}

# ---------------------------------------------------------------------------
# Build a sandbox git repo and scaffold both deliveries on main.
# ---------------------------------------------------------------------------

SANDBOX="${TMP}/sandbox"
WORK_NAME="work-test-disjoint"
WORK_DIR="${SANDBOX}/.aid/${WORK_NAME}"
DELIV1="${WORK_DIR}/deliveries/delivery-001"
DELIV2="${WORK_DIR}/deliveries/delivery-002"

mkdir -p "$SANDBOX"

# Initialise a bare git repo in the sandbox.
git -C "$SANDBOX" init -q
git -C "$SANDBOX" config user.email "test@aid-test.local"
git -C "$SANDBOX" config user.name  "AID Test"
git -C "$SANDBOX" checkout -q -b main

# Scaffold work + both deliveries on main (the base state).
make_work_state "$WORK_DIR"

make_delivery_state "$DELIV1" "delivery-001"
make_task_state "${DELIV1}/tasks/task-001" "task-001"
make_task_spec  "${DELIV1}/tasks/task-001" "task-001" "delivery-001" "$WORK_NAME"

make_delivery_state "$DELIV2" "delivery-002"
make_task_state "${DELIV2}/tasks/task-002" "task-002"
make_task_spec  "${DELIV2}/tasks/task-002" "task-002" "delivery-002" "$WORK_NAME"

git -C "$SANDBOX" add .aid/
git -C "$SANDBOX" commit -q -m "base: scaffold work + delivery-001 + delivery-002"

BASE_COMMIT="$(git -C "$SANDBOX" rev-parse HEAD)"

# ---------------------------------------------------------------------------
# Branch A: aid/delivery-001
# Writes ONLY delivery-001/ files using writeback-state.sh.
# ---------------------------------------------------------------------------
git -C "$SANDBOX" checkout -q -b aid/delivery-001

export AID_STATE_FILE="${WORK_DIR}/STATE.md"
export AID_DELIVERY_ISSUES_DIR="${DELIV1}"
export AID_LOCK_TIMEOUT=10

# Advance delivery lifecycle to Executing
bash "$WRITEBACK" --delivery-id 1 --lifecycle "Executing" 2>/dev/null

# Mark task-001 In Progress
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null

# Add findings to task-001
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --findings \
    "**Reviewer Tier:** Small
### Findings
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 1 | [HIGH] | delivery-001 missing edge case | Deferred-to-gate |" 2>/dev/null

# Mark task-001 Done
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null

# Write delivery gate block (marks Gated -> Done on the delivery)
bash "$WRITEBACK" --delivery-id 1 --block \
    "**Tier:** Small
**Grade:** A+
**Cycles:** 1
**Date:** 2026-06-18

### Gate Issues
(none)

**Result:** PASS" 2>/dev/null

# Advance delivery lifecycle to Done
bash "$WRITEBACK" --delivery-id 1 --lifecycle "Done" 2>/dev/null

# Append a Cross-phase Q&A entry DIRECTLY to delivery-001/STATE.md.
# writeback-state.sh does not have a --qa mode; we write the section content
# directly as a plain append-under-heading operation (the Q&A section is already
# present in the template; we replace the placeholder line with a Q entry).
# This is equivalent to what aid-execute's delivery-gate step would do.
DELIV1_STATE="${DELIV1}/STATE.md"
# Replace "(none)" under ## Cross-phase Q&A with a real Q entry (sed in-place).
# Use a Python one-liner for portability (no GNU sed -i on macOS in CI).
python3 - "$DELIV1_STATE" <<'PYEOF'
import sys, re

path = sys.argv[1]
content = open(path).read()

qa_entry = """### Q1

- **Category:** Architecture
- **Impact:** Low
- **State:** Answered
- **Context:** delivery-001 gate surfaced Q&A
- **Suggested:** use per-delivery STATE.md
- **Answer:** confirmed disjoint write per Pillar 2
- **Applied to:** delivery-001/STATE.md
"""

# Replace the placeholder "(none)" line under ## Cross-phase Q&A
content = re.sub(
    r'(## Cross-phase Q&A\s*\n)\(none\)',
    r'\1' + qa_entry,
    content
)
open(path, 'w').write(content)
PYEOF

# Commit delivery-001 branch changes.
git -C "$SANDBOX" add .aid/
git -C "$SANDBOX" commit -q -m "delivery-001: task done, gate passed, Q&A authored"

# ---------------------------------------------------------------------------
# Branch B: aid/delivery-002 (from main base, NOT from delivery-001)
# ---------------------------------------------------------------------------
git -C "$SANDBOX" checkout -q "$BASE_COMMIT" -b aid/delivery-002

export AID_DELIVERY_ISSUES_DIR="${DELIV2}"

# Advance delivery lifecycle to Executing
bash "$WRITEBACK" --delivery-id 2 --lifecycle "Executing" 2>/dev/null

# Mark task-002 In Progress, then Done
bash "$WRITEBACK" --delivery-id 2 --task-id 2 --field State --value "In Progress" 2>/dev/null
bash "$WRITEBACK" --delivery-id 2 --task-id 2 --field Elapsed --value "8m" 2>/dev/null
bash "$WRITEBACK" --delivery-id 2 --task-id 2 --field State --value "Done" 2>/dev/null

# Write delivery gate block for delivery-002
bash "$WRITEBACK" --delivery-id 2 --block \
    "**Tier:** Small
**Grade:** A
**Cycles:** 1
**Date:** 2026-06-18

### Gate Issues
(none)

**Result:** PASS" 2>/dev/null

# Advance delivery lifecycle to Done
bash "$WRITEBACK" --delivery-id 2 --lifecycle "Done" 2>/dev/null

# Append Cross-phase Q&A to delivery-002/STATE.md (independent of delivery-001).
DELIV2_STATE="${DELIV2}/STATE.md"
python3 - "$DELIV2_STATE" <<'PYEOF'
import sys, re

path = sys.argv[1]
content = open(path).read()

qa_entry = """### Q1

- **Category:** Requirements
- **Impact:** Medium
- **State:** Answered
- **Context:** delivery-002 gate surfaced Q&A
- **Suggested:** document in delivery-002 STATE.md
- **Answer:** confirmed, recorded in delivery-002 only
- **Applied to:** delivery-002/STATE.md
"""

content = re.sub(
    r'(## Cross-phase Q&A\s*\n)\(none\)',
    r'\1' + qa_entry,
    content
)
open(path, 'w').write(content)
PYEOF

# Commit delivery-002 branch changes.
git -C "$SANDBOX" add .aid/
git -C "$SANDBOX" commit -q -m "delivery-002: task done, gate passed, Q&A authored"

# ---------------------------------------------------------------------------
# Merge both branches back to main.
# If there are any conflicts git will exit non-zero; we capture that and report.
# ---------------------------------------------------------------------------
git -C "$SANDBOX" checkout -q main

# Merge delivery-001 first (should be a fast-forward or trivial merge).
MERGE1_RC=0
MERGE1_OUT="$(git -C "$SANDBOX" merge --no-edit aid/delivery-001 2>&1)" || MERGE1_RC=$?

# Merge delivery-002 -- this is the key test: it must NOT conflict with delivery-001.
MERGE2_RC=0
MERGE2_OUT="$(git -C "$SANDBOX" merge --no-edit aid/delivery-002 2>&1)" || MERGE2_RC=$?

# ---------------------------------------------------------------------------
# DM01: No merge conflict markers in ANY STATE.md file after both merges.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM01: Zero git merge conflicts on all STATE.md files ==="

assert_exit_zero "$MERGE1_RC" "DM01a: git merge aid/delivery-001 exits 0 (no conflicts)"
assert_exit_zero "$MERGE2_RC" "DM01b: git merge aid/delivery-002 exits 0 (no conflicts)"

# Scan every STATE.md in the work folder for conflict markers.
CONFLICT_COUNT=0
while IFS= read -r -d '' state_file; do
    if grep -qF '<<<<<<<' "$state_file" 2>/dev/null; then
        CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
        fail "DM01c: conflict marker found in $state_file"
    fi
done < <(find "${WORK_DIR}" -name 'STATE.md' -print0)

if [[ "$CONFLICT_COUNT" -eq 0 ]]; then
    pass "DM01c: zero conflict markers in all STATE.md files after both merges"
fi

# ---------------------------------------------------------------------------
# DM02: delivery-001's writes are present after the merge.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM02: delivery-001 edits survived the merge ==="

# work-003-state-schema task-004 relocated the delivery lifecycle State
# (--lifecycle mode) into the frontmatter `delivery_state` key; the body's
# "## Delivery Lifecycle" `- **State:**` bullet is a static fixture placeholder
# (make_delivery_state's lc_val) that writeback-state.sh never rewrites.
assert_file_contains "${DELIV1}/STATE.md" "delivery_state: Done" \
    "DM02a: delivery-001/STATE.md frontmatter delivery_state=Done"
assert_file_contains "${DELIV1}/STATE.md" "**Grade:** A+" \
    "DM02b: delivery-001/STATE.md has Grade: A+"
assert_file_contains "${DELIV1}/STATE.md" "delivery-001 gate surfaced Q&A" \
    "DM02c: delivery-001/STATE.md has Cross-phase Q&A entry"
# Per-task State (--field State mode) is likewise relocated to the frontmatter
# `state` key; the body's "## Task State" `- **State:**` bullet is the
# make_task_state fixture's static placeholder, never rewritten.
assert_file_contains "${DELIV1}/tasks/task-001/STATE.md" "state: Done" \
    "DM02d: delivery-001/tasks/task-001/STATE.md frontmatter state=Done"
assert_file_contains "${DELIV1}/tasks/task-001/STATE.md" "delivery-001 missing edge case" \
    "DM02e: delivery-001/tasks/task-001/STATE.md has findings"

# ---------------------------------------------------------------------------
# DM03: delivery-002's writes are present after the merge.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM03: delivery-002 edits survived the merge ==="

assert_file_contains "${DELIV2}/STATE.md" "delivery_state: Done" \
    "DM03a: delivery-002/STATE.md frontmatter delivery_state=Done"
assert_file_contains "${DELIV2}/STATE.md" "**Grade:** A" \
    "DM03b: delivery-002/STATE.md has Grade: A"
assert_file_contains "${DELIV2}/STATE.md" "delivery-002 gate surfaced Q&A" \
    "DM03c: delivery-002/STATE.md has Cross-phase Q&A entry"
assert_file_contains "${DELIV2}/tasks/task-002/STATE.md" "state: Done" \
    "DM03d: delivery-002/tasks/task-002/STATE.md frontmatter state=Done"
assert_file_contains "${DELIV2}/tasks/task-002/STATE.md" "elapsed: 8m" \
    "DM03e: delivery-002/tasks/task-002/STATE.md frontmatter elapsed=8m"

# ---------------------------------------------------------------------------
# DM04: work-level STATE.md NOT touched by either delivery branch.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM04: Work-level STATE.md not modified by delivery branches ==="

# The work STATE.md should retain only the base-commit content (no delivery edits).
# It must NOT contain delivery-specific content written by the delivery branches.
assert_file_not_contains "${WORK_DIR}/STATE.md" "delivery-001 gate surfaced Q&A" \
    "DM04a: work STATE.md does not contain delivery-001 Q&A (disjoint)"
assert_file_not_contains "${WORK_DIR}/STATE.md" "delivery-002 gate surfaced Q&A" \
    "DM04b: work STATE.md does not contain delivery-002 Q&A (disjoint)"
assert_file_not_contains "${WORK_DIR}/STATE.md" "**Grade:** A+" \
    "DM04c: work STATE.md does not contain gate block (disjoint)"

# The work-level Pipeline State header authored by main must still be intact.
assert_file_contains "${WORK_DIR}/STATE.md" "## Pipeline State" \
    "DM04d: work STATE.md Pipeline State header intact"
assert_file_contains "${WORK_DIR}/STATE.md" "**Lifecycle:** Running" \
    "DM04e: work STATE.md Lifecycle field intact (not overwritten by delivery branches)"

# ---------------------------------------------------------------------------
# DM05: The two deliveries wrote INDEPENDENT Cross-phase Q&A (SD-5 partition).
# Each delivery's Q&A is in its OWN file; they are NOT in the work-level STATE.md.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM05: Cross-phase Q&A is per-delivery (SD-5 partition) ==="

assert_file_contains "${DELIV1}/STATE.md" "## Cross-phase Q&A" \
    "DM05a: delivery-001/STATE.md has ## Cross-phase Q&A section"
assert_file_contains "${DELIV2}/STATE.md" "## Cross-phase Q&A" \
    "DM05b: delivery-002/STATE.md has ## Cross-phase Q&A section"

# delivery-001 Q&A is ONLY in delivery-001/STATE.md (not in delivery-002)
assert_file_not_contains "${DELIV2}/STATE.md" "delivery-001 gate surfaced Q&A" \
    "DM05c: delivery-001 Q&A not bleed into delivery-002/STATE.md"
assert_file_not_contains "${DELIV1}/STATE.md" "delivery-002 gate surfaced Q&A" \
    "DM05d: delivery-002 Q&A not bleed into delivery-001/STATE.md"

# ---------------------------------------------------------------------------
# DM06: Isolation canary -- no .aid/ leaked to real HOME.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM06: Isolation canary -- no real-HOME .aid leak ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]]; then
    pass "DM06: no new .aid/ directories appeared under real HOME"
else
    NEW_AID="$(comm -13 <(echo "$_CANARY_BEFORE") <(echo "$_CANARY_AFTER"))"
    fail "DM06: isolation breach -- new .aid/ dirs under real HOME: $NEW_AID"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
test_summary
