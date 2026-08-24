#!/usr/bin/env bash
# test-disjoint-merge.sh -- end-to-end proof that the per-unit STATE.yml hierarchy
# produces zero git merge conflicts on merge-back (AC-Disjoint / Pillar 2).
#
# Design:
#   A throwaway git sandbox simulates the two-delivery parallel-branch scenario:
#
#   main (base)
#     work-NNN-test/
#       STATE.yml          (work header -- authored by orchestrator on main)
#       deliveries/
#         delivery-001/
#           STATE.yml        (stub: Pending-Spec, created on main)
#           tasks/task-001/
#             DETAIL.md
#             STATE.yml
#         delivery-002/
#           STATE.yml        (stub: Pending-Spec, created on main)
#           tasks/task-002/
#             DETAIL.md
#             STATE.yml
#
#   branch: aid/delivery-001
#     Writes ONLY deliveries/delivery-001/STATE.yml + deliveries/delivery-001/tasks/task-001/STATE.yml
#     via writeback-state.sh (--field, --block, --lifecycle, --append-issue).
#     Also appends a Cross-phase Q&A entry to deliveries/delivery-001/STATE.yml's `qa:` sequence.
#
#   branch: aid/delivery-002
#     Writes ONLY deliveries/delivery-002/STATE.yml + deliveries/delivery-002/tasks/task-002/STATE.yml
#     via writeback-state.sh (same modes, different files).
#     Also appends a Cross-phase Q&A entry to deliveries/delivery-002/STATE.yml's `qa:` sequence.
#
#   Merge aid/delivery-001 -> main  (fast-forward or no-conflict)
#   Merge aid/delivery-002 -> main  (ASSERT: zero conflicts on any STATE.yml)
#
# The test checks:
#   DM01  No merge conflict markers (<<<<<<<) in any STATE.yml after both merges
#   DM02  delivery-001's edits are present (lifecycle, gate block, task state, Q&A)
#   DM03  delivery-002's edits are present (lifecycle, gate block, task state, Q&A)
#   DM04  work-level STATE.yml is not modified by either delivery branch
#   DM05  Cross-phase Q&A is per-delivery (SD-5 partition) -- retargeted to the `qa:`
#         sequence key (the `## Cross-phase Q&A` markdown heading FR-2b retires)
#   DM06  Isolation canary -- no real-HOME .aid leak
#   DM07  The file parses at every observable moment (each pre-merge/post-merge
#         snapshot is a well-formed YAML mapping) with no silently-lost write --
#         SP-6's stronger property than "no conflict markers" alone
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
# Fixture helpers (mirror test-writeback-state.sh conventions -- one
# whole-document YAML key space, no `---` fence, no markdown body; SS D-1/D-3)
# ---------------------------------------------------------------------------

make_task_state() {
    local task_dir="$1" task_id="$2" state_val="${3:-Pending}"
    mkdir -p "$task_dir"
    cat > "${task_dir}/STATE.yml" <<TASKSTATEOF
# Task State -- ${task_id}
state: ${state_val}
review: --
elapsed: --
notes: --
display_name: --
quick_check:
  reviewer_tier: --
  findings: []
dispatch_log: []
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
    cat > "${delivery_dir}/STATE.yml" <<DELIVSTATEOF
# Delivery State -- ${delivery_id}
delivery_state: ${lc_val}
gate_tier: --
gate_grade: Pending
gate_timestamp: --
delivery_lifecycle:
  updated: '2026-06-18T00:00:00Z'
  block_reason: --
  block_artifact: --
delivery_gate:
  issue_list: []
qa: []
DELIVSTATEOF
}

make_work_state() {
    local work_dir="$1"
    mkdir -p "$work_dir"
    cat > "${work_dir}/STATE.yml" <<'WORKSTATEOF'
# Work State -- work-test
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-18T00:00:00Z'
started: '2026-06-18'
minimum_grade: A
user_approved: 'no'

# Triage
# path: lite, work-type: new-feature, sub-path: LITE-FEATURE, override: no
WORKSTATEOF
}

# append_qa_entry FILE CONTEXT_TEXT: replaces the file's `qa: []` sentinel
# with a one-entry sequence, matching delivery-state-template.yml's `qa:`
# shape (id/category/impact/state/context/suggested/answer/applied_to).
# writeback-state.sh has no --qa mode (unaffected by this refactor -- Q&A
# authoring is a human/orchestrator action, not a writer mode); this direct
# edit is equivalent to what aid-execute's delivery-gate step would do.
append_qa_entry() {
    local file="$1" context="$2" applied_to="$3"
    python3 - "$file" "$context" "$applied_to" <<'PYEOF'
import sys
path, context, applied_to = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path, encoding="utf-8").read()
entry = (
    "qa:\n"
    "  - id: 1\n"
    "    category: Architecture\n"
    "    impact: Low\n"
    "    state: Answered\n"
    f"    context: {context}\n"
    "    suggested: use per-delivery STATE.yml\n"
    "    answer: confirmed disjoint write per Pillar 2\n"
    f"    applied_to: {applied_to}\n"
)
assert "qa: []" in content, f"qa: [] sentinel not found in {path}"
content = content.replace("qa: []", entry, 1)
open(path, "w", encoding="utf-8", newline="\n").write(content)
PYEOF
}

# assert_is_yaml_mapping FILE LABEL -- SP-6: the file parses at every
# observable moment. Same bounded check writeback-state.sh's own
# wb_state_is_mapping applies (non-empty; first non-blank/non-comment line is
# a column-0 `key:` line) -- not a full YAML parse, consistent with the
# declared hand-rolled subset (SS D-3).
assert_is_yaml_mapping() {
    local file="$1" label="$2"
    if [[ ! -s "$file" ]]; then
        fail "$label -- file is empty or missing: $file"
        return
    fi
    local first_line
    first_line=$(grep -vE '^[[:space:]]*(#.*)?$' "$file" | head -1)
    if [[ "$first_line" =~ ^[A-Za-z0-9_-]+: ]]; then
        pass "$label"
    else
        fail "$label -- first non-blank/non-comment line is not a column-0 key: '$first_line'"
    fi
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

assert_is_yaml_mapping "${WORK_DIR}/STATE.yml" "DM07 pre-branch: work STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV1}/STATE.yml" "DM07 pre-branch: delivery-001 STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV2}/STATE.yml" "DM07 pre-branch: delivery-002 STATE.yml parses as a mapping"

# ---------------------------------------------------------------------------
# Branch A: aid/delivery-001
# Writes ONLY delivery-001/ files using writeback-state.sh.
# ---------------------------------------------------------------------------
git -C "$SANDBOX" checkout -q -b aid/delivery-001

export AID_STATE_FILE="${WORK_DIR}/STATE.yml"
export AID_DELIVERY_ISSUES_DIR="${DELIV1}"
export AID_LOCK_TIMEOUT=10

# Advance delivery lifecycle to Executing
bash "$WRITEBACK" --delivery-id 1 --lifecycle "Executing" 2>/dev/null
assert_is_yaml_mapping "${DELIV1}/STATE.yml" "DM07 delivery-001: parses as a mapping after --lifecycle Executing"

# Mark task-001 In Progress
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --field State --value "In Progress" 2>/dev/null

# Add findings to task-001
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --findings \
    "- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] delivery-001 missing edge case -- Deferred-to-gate" 2>/dev/null
assert_is_yaml_mapping "${DELIV1}/tasks/task-001/STATE.yml" "DM07 delivery-001/task-001: parses as a mapping after --findings"

# Mark task-001 Done
bash "$WRITEBACK" --delivery-id 1 --task-id 1 --field State --value "Done" 2>/dev/null

# Write delivery gate block (marks the gate clean, PASS)
bash "$WRITEBACK" --delivery-id 1 --block \
    "- **Issue List:** none" 2>/dev/null

# Advance delivery lifecycle to Done
bash "$WRITEBACK" --delivery-id 1 --lifecycle "Done" 2>/dev/null
bash "$WRITEBACK" --delivery-id 1 --gate-field Grade --gate-value "A+" 2>/dev/null
assert_is_yaml_mapping "${DELIV1}/STATE.yml" "DM07 delivery-001: parses as a mapping after the gate sequence"

# Append a Cross-phase Q&A entry DIRECTLY to delivery-001/STATE.yml's `qa:`
# sequence (writeback-state.sh has no --qa mode -- unaffected by this
# refactor; equivalent to what aid-execute's delivery-gate step would do).
append_qa_entry "${DELIV1}/STATE.yml" "delivery-001 gate surfaced Q&A" "delivery-001/STATE.yml"
assert_is_yaml_mapping "${DELIV1}/STATE.yml" "DM07 delivery-001: parses as a mapping after the Q&A append"

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
    "- **Issue List:** none" 2>/dev/null

# Advance delivery lifecycle to Done
bash "$WRITEBACK" --delivery-id 2 --lifecycle "Done" 2>/dev/null
bash "$WRITEBACK" --delivery-id 2 --gate-field Grade --gate-value "A" 2>/dev/null

# Append Cross-phase Q&A to delivery-002/STATE.yml (independent of delivery-001).
append_qa_entry "${DELIV2}/STATE.yml" "delivery-002 gate surfaced Q&A" "delivery-002/STATE.yml"

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
# DM01: No merge conflict markers in ANY STATE.yml file after both merges.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM01: Zero git merge conflicts on all STATE.yml files ==="

assert_exit_zero "$MERGE1_RC" "DM01a: git merge aid/delivery-001 exits 0 (no conflicts)"
assert_exit_zero "$MERGE2_RC" "DM01b: git merge aid/delivery-002 exits 0 (no conflicts)"

# Scan every STATE.yml in the work folder for conflict markers.
CONFLICT_COUNT=0
while IFS= read -r -d '' state_file; do
    if grep -qF '<<<<<<<' "$state_file" 2>/dev/null; then
        CONFLICT_COUNT=$((CONFLICT_COUNT + 1))
        fail "DM01c: conflict marker found in $state_file"
    fi
done < <(find "${WORK_DIR}" -name 'STATE.yml' -print0)

if [[ "$CONFLICT_COUNT" -eq 0 ]]; then
    pass "DM01c: zero conflict markers in all STATE.yml files after both merges"
fi

# ---------------------------------------------------------------------------
# DM02: delivery-001's writes are present after the merge.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM02: delivery-001 edits survived the merge ==="

assert_file_contains "${DELIV1}/STATE.yml" "delivery_state: Done" \
    "DM02a: delivery-001/STATE.yml delivery_state=Done"
assert_file_contains "${DELIV1}/STATE.yml" "gate_grade: A+" \
    "DM02b: delivery-001/STATE.yml has gate_grade: A+"
assert_file_contains "${DELIV1}/STATE.yml" "delivery-001 gate surfaced Q&A" \
    "DM02c: delivery-001/STATE.yml has its Cross-phase Q&A entry"
assert_file_contains "${DELIV1}/tasks/task-001/STATE.yml" "state: Done" \
    "DM02d: delivery-001/tasks/task-001/STATE.yml state=Done"
assert_file_contains "${DELIV1}/tasks/task-001/STATE.yml" "delivery-001 missing edge case" \
    "DM02e: delivery-001/tasks/task-001/STATE.yml has findings"

# ---------------------------------------------------------------------------
# DM03: delivery-002's writes are present after the merge.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM03: delivery-002 edits survived the merge ==="

assert_file_contains "${DELIV2}/STATE.yml" "delivery_state: Done" \
    "DM03a: delivery-002/STATE.yml delivery_state=Done"
assert_file_contains "${DELIV2}/STATE.yml" "gate_grade: A" \
    "DM03b: delivery-002/STATE.yml has gate_grade: A"
assert_file_contains "${DELIV2}/STATE.yml" "delivery-002 gate surfaced Q&A" \
    "DM03c: delivery-002/STATE.yml has its Cross-phase Q&A entry"
assert_file_contains "${DELIV2}/tasks/task-002/STATE.yml" "state: Done" \
    "DM03d: delivery-002/tasks/task-002/STATE.yml state=Done"
# D-5/NFR-2: a value starting with a digit is deny-listed as number-like and
# single-quoted, even though "8m" itself is not a pure number (task-015
# addendum: was the unquoted "elapsed: 8m").
assert_file_contains "${DELIV2}/tasks/task-002/STATE.yml" "elapsed: '8m'" \
    "DM03e: delivery-002/tasks/task-002/STATE.yml elapsed='8m'"

# ---------------------------------------------------------------------------
# DM04: work-level STATE.yml NOT touched by either delivery branch.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM04: Work-level STATE.yml not modified by delivery branches ==="

# The work STATE.yml should retain only the base-commit content (no delivery edits).
assert_file_not_contains "${WORK_DIR}/STATE.yml" "delivery-001 gate surfaced Q&A" \
    "DM04a: work STATE.yml does not contain delivery-001 Q&A (disjoint)"
assert_file_not_contains "${WORK_DIR}/STATE.yml" "delivery-002 gate surfaced Q&A" \
    "DM04b: work STATE.yml does not contain delivery-002 Q&A (disjoint)"
assert_file_not_contains "${WORK_DIR}/STATE.yml" "gate_grade: A+" \
    "DM04c: work STATE.yml does not contain the delivery gate grade (disjoint)"

# The work-level pipeline keys authored by main must still be intact.
assert_file_contains "${WORK_DIR}/STATE.yml" "lifecycle: Running" \
    "DM04d: work STATE.yml lifecycle key intact (not overwritten by delivery branches)"
assert_file_contains "${WORK_DIR}/STATE.yml" "phase: Execute" \
    "DM04e: work STATE.yml phase key intact"

# ---------------------------------------------------------------------------
# DM05: The two deliveries wrote INDEPENDENT Cross-phase Q&A (SD-5 partition).
# Retargeted: each delivery's Q&A lives in its OWN `qa:` sequence key (the
# `## Cross-phase Q&A` markdown heading FR-2b retires), never in the
# work-level STATE.yml.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM05: Cross-phase Q&A is per-delivery (SD-5 partition) ==="

assert_file_contains "${DELIV1}/STATE.yml" "qa:" \
    "DM05a: delivery-001/STATE.yml has a qa: key"
assert_file_contains "${DELIV2}/STATE.yml" "qa:" \
    "DM05b: delivery-002/STATE.yml has a qa: key"

# delivery-001 Q&A is ONLY in delivery-001/STATE.yml (not in delivery-002)
assert_file_not_contains "${DELIV2}/STATE.yml" "delivery-001 gate surfaced Q&A" \
    "DM05c: delivery-001 Q&A does not bleed into delivery-002/STATE.yml"
assert_file_not_contains "${DELIV1}/STATE.yml" "delivery-002 gate surfaced Q&A" \
    "DM05d: delivery-002 Q&A does not bleed into delivery-001/STATE.yml"

# ---------------------------------------------------------------------------
# DM06: Isolation canary -- no .aid/ leaked to real HOME.
#
# task-015 addendum (SP-16 / AC-12 hermetic-suite fix, unrelated to the
# STATE.yml content retarget): on a host where the OS temp dir lives UNDER
# $HOME (Windows: %TEMP% is typically ~/AppData/Local/Temp), $TMP itself sits
# within maxdepth 6 of REAL_HOME -- every throwaway .aid/ this suite creates
# BY DESIGN (fakehome/.aid, sandbox/.aid) is then indistinguishable from a
# real leak by a bare "did REAL_HOME's .aid inventory change" check. $TMP is
# captured (line ~79) strictly AFTER the BEFORE snapshot (line 77), so it can
# never itself appear in _CANARY_BEFORE; excluding anything under $TMP/ from
# the AFTER snapshot is therefore safe and does not weaken the check -- a
# genuine leak (a .aid/ written OUTSIDE this suite's own throwaway root) is
# still caught.
# ---------------------------------------------------------------------------
echo ""
echo "=== DM06: Isolation canary -- no real-HOME .aid leak ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
# Filter by $TMP's basename, not its full path: on MSYS/cygwin (Windows), mktemp
# prints the posix-mount alias ("/tmp/tmp.XXXXXX") while `find` walking from
# REAL_HOME resolves the SAME directory via its native path
# ("/c/Users/<user>/AppData/Local/Temp/tmp.XXXXXX") -- two string forms for one
# physical directory. mktemp's random suffix is unique enough that a basename
# match cannot false-positive on an unrelated real .aid/ dir.
_TMP_BASENAME="$(basename "${TMP}")"
_CANARY_AFTER_FILTERED="$(printf '%s\n' "$_CANARY_AFTER" | grep -vF "/${_TMP_BASENAME}/" || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER_FILTERED" ]]; then
    pass "DM06: no new .aid/ directories appeared under real HOME (outside this suite's own throwaway root)"
else
    NEW_AID="$(comm -13 <(echo "$_CANARY_BEFORE") <(echo "$_CANARY_AFTER_FILTERED"))"
    fail "DM06: isolation breach -- new .aid/ dirs under real HOME: $NEW_AID"
fi

# ---------------------------------------------------------------------------
# DM07: post-merge -- every merged file still parses as a mapping (SP-6: the
# file parses at every observable moment, no silently-lost write).
# ---------------------------------------------------------------------------
echo ""
echo "=== DM07: every STATE.yml parses at every observable moment (SP-6) ==="

assert_is_yaml_mapping "${WORK_DIR}/STATE.yml" "DM07: post-merge work STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV1}/STATE.yml" "DM07: post-merge delivery-001 STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV2}/STATE.yml" "DM07: post-merge delivery-002 STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV1}/tasks/task-001/STATE.yml" "DM07: post-merge task-001 STATE.yml parses as a mapping"
assert_is_yaml_mapping "${DELIV2}/tasks/task-002/STATE.yml" "DM07: post-merge task-002 STATE.yml parses as a mapping"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
test_summary
