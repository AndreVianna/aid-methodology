#!/usr/bin/env bash
# test-task-state-transitions.sh -- work-003-state-schema task-009 regression guard.
#
# The user-reported bug this locks in: a task shows "Pending" in the dashboard
# for its ENTIRE execution, then jumps straight to "Done", because the
# intermediate "In Progress" / "In Review" writes are skipped. The mechanism
# itself (writeback-state.sh --field State; both reader twins; the dashboard)
# already exists -- the gap task-009 closes is that the aid-execute skill flow
# did not EMPHATICALLY/UNMISSABLY require writing each transition the moment
# it happens. This suite proves the writer + BOTH reader twins never regress
# on reflecting a state the instant it is written, for the flattened
# `### Tasks lifecycle` path (feature-001 layout).
#
# Drives a scratch flattened work's task-001 row through the full lifecycle
#   _none yet_ -> Pending -> In Progress -> In Review -> Done
# via the EXACT command the aid-execute "State-Write Protocol" mandate uses
# (canonical/skills/aid-execute/references/state-execute.md):
#   writeback-state.sh --delivery-id DDD --task-id NNN --field State --value V
#
# After EACH write, asserts BOTH:
#   (a) the work-root STATE.md's `### Tasks lifecycle` table row shows the new
#       state (direct read of what the flattened `--field` write path produced), and
#   (b) both dashboard reader twins -- Python `read_repo()` and Node `readRepo()`,
#       each run in-process (no server, no port, no *parity*.sh -- those hang on
#       this host; see test-dashboard-parity.sh) -- surface that same state for
#       task-001.
#
# Meaningfulness (manually verified during authorship, not re-asserted here to
# avoid a redundant permanent negative branch): re-running this same sequence
# with the "In Progress" write REMOVED reproduces the exact user-reported bug
# -- the table/readers jump straight from "Pending" to "Done" -- which would
# fail this suite's per-transition assertions (each checks the row/readers show
# the value of the write that JUST ran, not a later one). The strict per-step
# equality check is what makes a skipped transition write visible; it is not
# vacuously true regardless of what was actually written.
#
# Exit codes:
#   0 -- all assertions passed
#   1 -- one or more assertions failed
#
# Usage: bash tests/canonical/test-task-state-transitions.sh [-v|--verbose]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

WRITEBACK="${REPO_ROOT}/canonical/aid/scripts/execute/writeback-state.sh"
READER_MJS="${REPO_ROOT}/dashboard/server/reader.mjs"

HAS_PYTHON=0
HAS_NODE=0
command -v python3 >/dev/null 2>&1 && HAS_PYTHON=1
command -v node    >/dev/null 2>&1 && HAS_NODE=1

echo "=== task-009: task-state transition regression guard (### Tasks lifecycle + reader twins) ==="
echo "  python3 present: $HAS_PYTHON"
echo "  node present:    $HAS_NODE"
[[ $HAS_PYTHON -eq 0 ]] && echo "  NOTE: python3 absent -- reader-twin (Python) assertions will be skipped; writer assertions still run."
[[ $HAS_NODE -eq 0 ]]   && echo "  NOTE: node absent -- reader-twin (Node) assertions will be skipped; writer assertions still run."

# ---------------------------------------------------------------------------
# Scratch flattened work (feature-001 shape: work-root BLUEPRINT.md +
# tasks/task-NNN/DETAIL.md directly under the work root, no deliveries/
# wrapper -- the SAME 3-part detection rule writeback-state.sh's
# is_flat_layout() and both reader twins' _detect_flat/_detectFlat use).
# ---------------------------------------------------------------------------

TMP_ROOT="${CLAUDE_JOB_DIR:-/tmp}/tmp-task009-$$"
cleanup() { rm -rf "${TMP_ROOT}"; }
trap cleanup EXIT

WORK_ID="work-999-task009-demo"
# Container model (work-016): works live under the .aid/works/ container; both
# reader twins enumerate .aid/works/* (never top-level .aid/work-*), so the
# scratch fixture MUST be built under works/ or read_repo/readRepo won't find it.
WORK_DIR="${TMP_ROOT}/.aid/works/${WORK_ID}"
mkdir -p "${WORK_DIR}/tasks/task-001"

cat > "${WORK_DIR}/BLUEPRINT.md" << 'EOF'
# Delivery BLUEPRINT -- delivery-001: Demo

## Objective

Scratch fixture for the task-009 task-state transition regression guard.
Never executed for real; exists only for this suite's lifetime.

## Gate Criteria

- [ ] All tasks in delivery-001 are Done or Canceled.
EOF

cat > "${WORK_DIR}/tasks/task-001/DETAIL.md" << 'EOF'
# task-001: Demo task

**Type:** REFACTOR

**Source:** work-999-task009-demo -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Fixture task for the task-009 regression guard; never executed for real.

**Acceptance Criteria:**
- [ ] N/A -- fixture only.
EOF

cat > "${WORK_DIR}/STATE.md" << 'EOF'
---
pipeline:
  path: lite
  initiator: aid-refactor
started: "2026-07-10"
minimum_grade: A
user_approved: yes
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: "2026-07-10T00:00:00Z"
delivery_state: Executing
---

# Work STATE -- work-999-task009-demo

## Delivery Lifecycle

- **Updated:** 2026-07-10T00:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| _none yet_ | | | | |
EOF

# ---------------------------------------------------------------------------
# Reader-twin check scripts. Every path is passed as a bash ARGUMENT (never
# embedded as a literal in the generated script source) so this test is
# portable across POSIX and Windows/Git-Bash hosts: MSYS/Git-Bash silently
# rewrites a POSIX-style argv path (e.g. /c/Users/...) to the native form
# before a native python3.exe/node.exe process ever sees it, but the SAME
# rewrite does NOT happen for a path baked into a heredoc as source text --
# a literal "/c/..." string embedded that way fails on native Windows Python
# (os.path.isfile('/c/...') -> False; verified during this suite's authorship).
# The Node script additionally uses a runtime `import()` (not a static import)
# so the reader.mjs module path is ALSO argv-driven, not baked into the source.
# ---------------------------------------------------------------------------

PY_CHECK="${TMP_ROOT}/reader_check.py"
cat > "${PY_CHECK}" << 'PYEOF'
import sys

repo_root, aid_root, work_id, task_id = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
sys.path.insert(0, repo_root)
from dashboard.reader.reader import read_repo

model = read_repo(aid_root)
work = next((w for w in model.works if w.work_id == work_id), None)
if work is None:
    print(f"ERROR: work {work_id} not found")
    sys.exit(2)
task = next((t for t in work.tasks if t.task_id == task_id), None)
if task is None:
    print(f"ERROR: task {task_id} not found")
    sys.exit(2)
status = task.status.value if hasattr(task.status, "value") else str(task.status)
print(status)
PYEOF

NODE_CHECK="${TMP_ROOT}/reader_check.mjs"
cat > "${NODE_CHECK}" << 'MJSEOF'
import { pathToFileURL } from 'node:url';

const readerPath = process.argv[2];
const aidRoot = process.argv[3];
const workId = process.argv[4];
const taskId = process.argv[5];

const { readRepo } = await import(pathToFileURL(readerPath).href);
const model = readRepo(aidRoot);
const work = model.works.find((w) => w.work_id === workId);
if (!work) {
    console.log(`ERROR: work ${workId} not found`);
    process.exit(2);
}
const task = work.tasks.find((t) => t.task_id === taskId);
if (!task) {
    console.log(`ERROR: task ${taskId} not found`);
    process.exit(2);
}
console.log(task.status);
MJSEOF

# ---------------------------------------------------------------------------
# Per-transition assertion: writer row (a) + both reader twins (b).
# ---------------------------------------------------------------------------

assert_transition() {
    local expected="$1"

    # (a) writer: the ### Tasks lifecycle table row on disk.
    local row
    row=$(grep -i "| task-001 |" "${WORK_DIR}/STATE.md" || true)
    assert_output_contains "$row" "| ${expected} |" "writer: ### Tasks lifecycle row -> ${expected}"

    # (b1) Python read_repo() twin.
    #
    # No `set +e`/`set -e` toggling here (deliberately): this suite never
    # enables `-e` at the top (only `-uo pipefail`), and unconditionally
    # calling `set -e` after capturing $? would LEAK `-e` on globally for
    # the rest of the script -- tripping a latent landmine in
    # tests/lib/assert.sh's assert_output_contains/assert_file_contains
    # (their fail-branch ends in a bare `[[ "$VERBOSE" -eq 1 ]] && echo ...`
    # with no `|| true` guard, which aborts the whole script under `-e`
    # the next time an assertion actually fails). Capturing $? right after
    # a command works regardless of `-e` as long as `-e` was never enabled
    # to begin with -- verified during this suite's authorship.
    if [[ $HAS_PYTHON -eq 1 ]]; then
        local py_out py_rc
        py_out=$(python3 "${PY_CHECK}" "${REPO_ROOT}" "${TMP_ROOT}" "${WORK_ID}" "task-001" 2>&1)
        py_rc=$?
        if [[ $py_rc -eq 0 ]]; then
            assert_eq "$py_out" "$expected" "python read_repo() surfaces -> ${expected}"
        else
            fail "python read_repo() surfaces -> ${expected} -- script errored (rc=${py_rc}): ${py_out}"
        fi
    else
        log "SKIP python reader-twin check (python3 not found)"
    fi

    # (b2) Node readRepo() twin (same no-set-e-toggle rationale as above).
    if [[ $HAS_NODE -eq 1 ]]; then
        local node_out node_rc
        node_out=$(node "${NODE_CHECK}" "${READER_MJS}" "${TMP_ROOT}" "${WORK_ID}" "task-001" 2>&1)
        node_rc=$?
        if [[ $node_rc -eq 0 ]]; then
            assert_eq "$node_out" "$expected" "node readRepo() surfaces -> ${expected}"
        else
            fail "node readRepo() surfaces -> ${expected} -- script errored (rc=${node_rc}): ${node_out}"
        fi
    else
        log "SKIP node reader-twin check (node not found)"
    fi
}

# ---------------------------------------------------------------------------
# Drive the full lifecycle -- one writeback-state.sh call per transition,
# asserting immediately after each (the "as it changes" contract task-009
# mandates in the aid-execute skill flow).
# ---------------------------------------------------------------------------

for value in "Pending" "In Progress" "In Review" "Done"; do
    out=$(AID_STATE_FILE="${WORK_DIR}/STATE.md" bash "${WRITEBACK}" \
        --delivery-id 1 --task-id 1 --field State --value "${value}" 2>&1)
    rc=$?
    assert_exit_zero "$rc" "writeback-state.sh --field State --value \"${value}\""
    [[ "$VERBOSE" -eq 1 ]] && echo "$out"
    assert_transition "${value}"
done

test_summary
exit $?
