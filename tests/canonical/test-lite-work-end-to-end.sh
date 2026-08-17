#!/usr/bin/env bash
# test-lite-work-end-to-end.sh -- run a CURRENT-SHAPE Lite work through the whole chain
# and require every stage to agree about it.
#
# WHY THIS EXISTS, and why the unit suites did not make it unnecessary.
#
# Each mechanism this work introduced is unit-tested in isolation and each of those suites
# passed throughout. What none of them could see is the thing that actually broke: the
# dashboard's forked writer classified a declared-`lite` work as NESTED while every reader
# classified it FLAT, so the product would READ a work one way and WRITE to it another.
# Every component was individually correct. The composition was not.
#
# The fixture is deliberately a work with NO `BLUEPRINT.md`, which is what makes it a
# regression test rather than a demo. BLUEPRINT.md presence used to BE the flat-layout
# signal, and it is retired as an authored artifact, so a current work has none. Any stage
# that still infers layout from that file gets this work wrong -- which is exactly how the
# fork's bug would have surfaced here, and did not surface anywhere else for three passes.
#
# It exercises the FORK (`dashboard/scripts/writeback-state.sh`), not the canonical writer,
# because the server's WRITER_DIR is `dashboard/scripts`: the fork is the code path the
# product takes. Testing canonical here would re-test what is already covered and miss the
# copy that failed.
#
# Chain under test, on ONE fixture:
#   E2E01  slice-requirements.sh returns the criteria the task cites, and only those
#   E2E02  derive-waves.sh --from-tasks derives the wave order from task dependencies
#   E2E03  the FORKED writer routes the write to the FLAT target (tasks_lifecycle)
#   E2E04  reader.py reads back the declared path, the written status and derived lanes
#   E2E05  reader.mjs agrees with reader.py, field for field
#
# Read-only against the repo; the fixture lives in a temp dir.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/assert.sh" 2>/dev/null || {
    PASS_COUNT=0; FAIL_COUNT=0
    pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "  PASS: $1"; }
    fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "  FAIL: $1" >&2; }
    assert_eq() { [[ "$1" == "$2" ]] && pass "$3" || fail "$3 -- expected '$2' got '$1'"; }
    test_summary() {
        echo ""; echo "=== Summary ==="
        echo "  Tests passed: ${PASS_COUNT}"; echo "  Tests failed: ${FAIL_COUNT}"
        [[ "${FAIL_COUNT}" -eq 0 ]] && { echo ""; echo "All tests passed."; return 0; }
        return 1
    }
}

echo "== test-lite-work-end-to-end.sh =="
echo ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WORK="${TMP}/root/.aid/works/work-001-order-cache"
mkdir -p "${WORK}/tasks/task-001" "${WORK}/tasks/task-002" "${WORK}/tasks/task-003"

cat > "${WORK}/STATE.yml" <<'EOF'
pipeline:
  path: lite
lifecycle: Running
phase: Execute
tasks_lifecycle: {}
qa: []
EOF

cat > "${WORK}/REQUIREMENTS.md" <<'EOF'
# Stale cache on order update

- **Name:** order-cache-fix
- **Description:** Invalidate the order cache on write.

## 9. Acceptance Criteria

- **AC-1** Given an order updated, when read within 30 minutes, the response is fresh.
- **AC-2** A regression test asserts cache.invalidate is called with order_id.
- **AC-3** All quality gates pass.

## 11. Features

### Feature 001 -- Order-status cache invalidation

- **Criteria:** AC-1, AC-2, AC-3

#### Technical Specification

update_order() calls OrdersCache.invalidate(order_id) after the write commits.
EOF

for n in 001 002 003; do
    case "$n" in
        001) dep="- (none)" ;;
        002) dep="task-001" ;;
        003) dep="task-002" ;;
    esac
    cat > "${WORK}/tasks/task-${n}/DETAIL.md" <<EOF
# task-${n}: Work item ${n}

**Type:** IMPLEMENT

**Source:** feature-001-order-cache -> delivery-001 -> AC-1, AC-2

**Depends on:** ${dep}
EOF
done

# --- E2E01: the requirements slice -------------------------------------------------
slice="$(bash "${REPO_ROOT}/canonical/aid/scripts/execute/slice-requirements.sh" "$WORK" task-002 2>/dev/null)"
# Assert on the DEFINITIONS the slice carries, not on whether the string "AC-3" occurs
# anywhere in it. The first version of this check did the latter and failed against a
# correct slicer: the feature section cites `**Criteria:** AC-1, AC-2, AC-3` because the
# FEATURE owns all three, and the slice reproduces that section verbatim. What must be
# absent is AC-3's own `- **AC-3**` entry from section 9 -- the text the task would be
# judged against. Mistaking a citation for a definition is exactly the confusion the
# ids-only rule exists to prevent, so the test should not make it either.
defs="$(grep -cE '^- \*\*AC-[0-9]+\*\*' <<<"$slice")"
if grep -qE '^- \*\*AC-1\*\*' <<<"$slice" \
   && grep -qE '^- \*\*AC-2\*\*' <<<"$slice" \
   && ! grep -qE '^- \*\*AC-3\*\*' <<<"$slice"; then
    pass "E2E01 the slice defines exactly the cited criteria (AC-1, AC-2; ${defs} total) and not AC-3"
else
    fail "E2E01 slice carried the wrong criterion definitions (${defs} found)"
fi

# --- E2E02: the derived graph ------------------------------------------------------
graph="$(bash "${REPO_ROOT}/canonical/aid/scripts/execute/derive-waves.sh" --from-tasks "$WORK" 2>/dev/null)"
waves="$(grep -E '^wave [0-9]+:' <<<"$graph" | tr -d ' ' | paste -sd'|' -)"
assert_eq "$waves" "wave1:task-001|wave2:task-002|wave3:task-003" \
    "E2E02 derive-waves --from-tasks orders the waves from the task dependencies"

# --- E2E03: the FORKED writer, which is the path the dashboard actually takes ------
FORK="${REPO_ROOT}/dashboard/scripts/writeback-state.sh"
if [[ ! -f "$FORK" ]]; then
    fail "E2E03 dashboard/scripts/writeback-state.sh is missing (the dashboard's WRITER_DIR target)"
else
    AID_STATE_FILE="${WORK}/STATE.yml" bash "$FORK" \
        --task-id 1 --field State --value "In Progress" >/dev/null 2>&1
    # The FLAT target is the work-root tasks_lifecycle mapping. A stage still inferring
    # layout from BLUEPRINT.md presence would have taken the nested path and written
    # nothing here -- with no error, which is what makes it worth asserting.
    if grep -A3 'tasks_lifecycle:' "${WORK}/STATE.yml" | grep -q "state: 'In Progress'"; then
        pass "E2E03 the forked writer routed the write to the FLAT target on a work with no BLUEPRINT.md"
    else
        fail "E2E03 the forked writer did NOT write to tasks_lifecycle -- it read the layout as nested"
    fi
fi

# --- E2E04 / E2E05: both readers, and their agreement -----------------------------
py="$( cd "$REPO_ROOT" && python3 - "$TMP" <<'PYEOF'
import json, sys
sys.path.insert(0, ".")
from dashboard.reader.reader import read_repo
d = json.loads(json.dumps(read_repo(sys.argv[1] + "/root/.aid"),
                          default=lambda o: getattr(o, "__dict__", str(o))))
w = (d.get("works") or [{}])[0]
rows = [f"{t.get('task_id')}:{t.get('status')}:{t.get('lane')}" for t in (w.get("tasks") or [])]
print(f"{w.get('work_path')}|" + ",".join(rows))
PYEOF
)"
assert_eq "$py" "lite|task-001:In Progress:1,task-002:Unknown:2,task-003:Unknown:3" \
    "E2E04 reader.py reads the declared path, the written status, and lanes derived from DETAILs"

if command -v node >/dev/null 2>&1; then
    nd="$( cd "$REPO_ROOT" && node --input-type=module -e '
import { pathToFileURL } from "node:url";
const mod = await import(pathToFileURL("dashboard/server/reader.mjs").href);
const fn = mod.readRepo || mod.read_repo || mod.default;
const d = fn(process.argv[1] + "/root/.aid");
const w = (d.works || [])[0] || {};
const rows = (w.tasks || []).map(t => `${t.taskId ?? t.task_id}:${t.status}:${t.lane}`);
process.stdout.write(`${w.workPath ?? w.work_path}|` + rows.join(","));
' "$TMP" 2>/dev/null )"
    assert_eq "$nd" "$py" "E2E05 reader.mjs agrees with reader.py field for field on the same work"
else
    pass "E2E05 SKIPPED: node not available"
fi

echo ""
test_summary
exit $?
