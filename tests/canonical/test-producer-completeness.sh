#!/usr/bin/env bash
# test-producer-completeness.sh -- PF-9 producer-completeness gate (delivery-007).
#
# Asserts that the PT-1 conforming fixture produces a model with no degraded
# sentinels (null title, null description, null delivery/lane, null short_name)
# for works that carry REQUIREMENTS.md or SPEC.md (conforming producer output).
#
# Also runs a NEGATIVE assertion: a deliberately degraded copy of the fixture
# MUST fail the same check (proving the gate bites on regressions).
#
# Calls the reader directly via python3 / node (no HTTP server needed).
# Follows the same skip-if-runtime-absent posture as sibling suites.
#
# Exit codes:
#   0 -- positive passes AND negative correctly fails
#   1 -- positive fails OR negative incorrectly passes
#
# Source is ASCII-only (shipped script posture; coding-standards.md).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Runtime availability
# ---------------------------------------------------------------------------

HAS_PYTHON=0
HAS_NODE=0

if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON=1
fi
if command -v node >/dev/null 2>&1; then
    HAS_NODE=1
fi

echo "=== PF-9 producer-completeness gate ==="
echo "  python3 present: $HAS_PYTHON"
echo "  node present:    $HAS_NODE"

if [[ $HAS_PYTHON -eq 0 && $HAS_NODE -eq 0 ]]; then
    echo "  SKIP: neither python3 nor node found; skipping all completeness checks."
    echo "=== Summary ==="
    echo "  Tests passed: 0"
    echo "  Tests failed: 0"
    echo ""
    echo "All tests passed."
    exit 0
fi

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

FIXTURE_FULL="${REPO_ROOT}/dashboard/server/tests/fixtures/pt1-aid"

# ---------------------------------------------------------------------------
# Temp dir for degraded fixture (cleaned up on exit)
# ---------------------------------------------------------------------------

TMP_ROOT="${CLAUDE_JOB_DIR:-/tmp}/tmp-pf9-$$"

cleanup() {
    rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Python completeness check runner.
# Args: AID_ROOT LABEL EXPECT_FAIL
#   AID_ROOT    -- path to the repo root (parent of the .aid/ directory)
#   LABEL       -- label prefix for pass/fail messages
#   EXPECT_FAIL -- "1" means we expect non-zero exit (negative assertion);
#                  "0" means we expect exit 0 (positive assertion).
# ---------------------------------------------------------------------------

run_python_check() {
    local aid_root="$1"
    local label="$2"
    local expect_fail="${3:-0}"

    if [[ $HAS_PYTHON -eq 0 ]]; then
        log "[$label] SKIP python (runtime absent)"
        return 0
    fi

    local out rc
    set +e
    out=$(python3 -c "
import sys, os, re
repo_root = sys.argv[1]
aid_root  = sys.argv[2]
sys.path.insert(0, repo_root)
from dashboard.reader.reader import read_repo

model = read_repo(aid_root)
errors = []

for w in model.works:
    # Always reconstruct work_dir from aid_root + work_id (work_path is triage source mode, not a path)
    work_dir = os.path.join(aid_root, '.aid', w.work_id)

    has_requirements = os.path.isfile(os.path.join(work_dir, 'REQUIREMENTS.md'))
    has_spec = os.path.isfile(os.path.join(work_dir, 'SPEC.md'))
    is_conforming = has_requirements or has_spec

    if not is_conforming:
        # Deliberate fallback/degraded work -- skip strict field checks
        continue

    slug_m = re.match(r'^work-\d+-(.+)$', w.work_id)
    slug = slug_m.group(1) if slug_m else w.work_id

    if w.title is None:
        errors.append(w.work_id + ': title is null (producer identity not emitted)')
    elif w.title == slug:
        errors.append(w.work_id + ': title equals de-slugged work_id (Name not emitted)')

    if w.description is None:
        errors.append(w.work_id + ': description is null')

    plan_path = os.path.join(work_dir, 'PLAN.md')
    has_plan = os.path.isfile(plan_path)

    for t in w.tasks:
        if t.short_name is None:
            errors.append(w.work_id + '/' + t.task_id + ': short_name is null')
        elif re.match(r'^task-\d+$', t.short_name, re.IGNORECASE):
            errors.append(w.work_id + '/' + t.task_id + ': short_name equals bare task-NNN id')

        if t.delivery is None:
            errors.append(w.work_id + '/' + t.task_id + ': delivery is null')

        if has_plan and t.lane is None:
            errors.append(w.work_id + '/' + t.task_id + ': lane is null (wave-map missing or incomplete)')

if errors:
    for e in errors:
        print('COMPLETENESS-FAIL: ' + e)
    sys.exit(1)

print('COMPLETENESS-OK: all conforming works have non-degraded fields')
" "${REPO_ROOT}" "${aid_root}" 2>&1)
    rc=$?
    set -e

    [[ "$VERBOSE" -eq 1 ]] && echo "$out"

    if [[ "$expect_fail" == "1" ]]; then
        if [[ $rc -ne 0 ]]; then
            pass "[$label] python completeness gate correctly fires on degraded fixture"
        else
            fail "[$label] python completeness gate did NOT fire on degraded fixture (expected non-zero)"
        fi
    else
        if [[ $rc -eq 0 ]]; then
            pass "[$label] python completeness gate passes on conforming fixture"
        else
            fail "[$label] python completeness gate FAILED on conforming fixture -- ${out}"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Node completeness check runner.
# Args: AID_ROOT LABEL EXPECT_FAIL
# ---------------------------------------------------------------------------

run_node_check() {
    local aid_root="$1"
    local label="$2"
    local expect_fail="${3:-0}"

    if [[ $HAS_NODE -eq 0 ]]; then
        log "[$label] SKIP node (runtime absent)"
        return 0
    fi

    # Write the Node checker to a temp file so its import of reader.mjs resolves correctly
    local node_script="${TMP_ROOT}/pf9_check.mjs"
    mkdir -p "${TMP_ROOT}"
    cat > "${node_script}" << MJSEOF
import { readRepo } from '${REPO_ROOT}/dashboard/server/reader.mjs';
import { existsSync } from 'fs';
import { join } from 'path';

const aidRoot  = process.argv[2];
const errors = [];
const model = readRepo(aidRoot);

for (const w of model.works) {
    const workDir = join(aidRoot, '.aid', w.work_id);
    const hasRequirements = existsSync(join(workDir, 'REQUIREMENTS.md'));
    const hasSpec = existsSync(join(workDir, 'SPEC.md'));
    const isConforming = hasRequirements || hasSpec;

    if (!isConforming) continue;

    const slugMatch = w.work_id.match(/^work-\d+-(.+)$/);
    const slug = slugMatch ? slugMatch[1] : w.work_id;

    if (w.title === null || w.title === undefined) {
        errors.push(w.work_id + ': title is null (producer identity not emitted)');
    } else if (w.title === slug) {
        errors.push(w.work_id + ': title equals de-slugged work_id (Name not emitted)');
    }

    if (w.description === null || w.description === undefined) {
        errors.push(w.work_id + ': description is null');
    }

    const planPath = join(workDir, 'PLAN.md');
    const hasPlan = existsSync(planPath);

    for (const t of w.tasks) {
        if (t.short_name === null || t.short_name === undefined) {
            errors.push(w.work_id + '/' + t.task_id + ': short_name is null');
        } else if (/^task-\d+$/.test(t.short_name)) {
            errors.push(w.work_id + '/' + t.task_id + ': short_name equals bare task-NNN id');
        }

        if (t.delivery === null || t.delivery === undefined) {
            errors.push(w.work_id + '/' + t.task_id + ': delivery is null');
        }

        if (hasPlan && (t.lane === null || t.lane === undefined)) {
            errors.push(w.work_id + '/' + t.task_id + ': lane is null (wave-map missing or incomplete)');
        }
    }
}

if (errors.length > 0) {
    for (const e of errors) process.stderr.write('COMPLETENESS-FAIL: ' + e + '\n');
    process.exit(1);
}
process.stdout.write('COMPLETENESS-OK: all conforming works have non-degraded fields\n');
MJSEOF

    local out rc
    set +e
    out=$(node "${node_script}" "${aid_root}" 2>&1)
    rc=$?
    set -e

    [[ "$VERBOSE" -eq 1 ]] && echo "$out"

    if [[ "$expect_fail" == "1" ]]; then
        if [[ $rc -ne 0 ]]; then
            pass "[$label] node completeness gate correctly fires on degraded fixture"
        else
            fail "[$label] node completeness gate did NOT fire on degraded fixture (expected non-zero)"
        fi
    else
        if [[ $rc -eq 0 ]]; then
            pass "[$label] node completeness gate passes on conforming fixture"
        else
            fail "[$label] node completeness gate FAILED on conforming fixture -- ${out}"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Build a degraded copy of the fixture.
# Degrades work-001-running-parallel:
#   - Removes the '- **Name:**' line from REQUIREMENTS.md (null title)
#   - Strips the title from task-001.md H1 (bare # task-001, null short_name)
#   - Removes all wave-map blocks from PLAN.md (null lane via PF-5a)
#   - ALSO strips all '- Wave N:' prose fallback lines (PF-5b) so lane is
#     genuinely null -- without this, PF-5b re-derives lane from prose lines
#     and the lane/delivery branch never fires.
# ---------------------------------------------------------------------------

build_degraded_fixture() {
    local src="$1"
    local dst="$2"

    cp -r "${src}/." "${dst}"

    local WORK_DIR="${dst}/.aid/work-001-running-parallel"

    # Degrade REQUIREMENTS.md: remove the - **Name:** line -> title will be null
    if [[ -f "${WORK_DIR}/REQUIREMENTS.md" ]]; then
        grep -v '\*\*Name:\*\*' "${WORK_DIR}/REQUIREMENTS.md" \
            > "${WORK_DIR}/REQUIREMENTS.md.tmp" \
            && mv "${WORK_DIR}/REQUIREMENTS.md.tmp" "${WORK_DIR}/REQUIREMENTS.md"
    fi

    # Degrade task-001.md: strip colon+title from H1 -> short_name will be null
    if [[ -f "${WORK_DIR}/tasks/task-001.md" ]]; then
        sed 's/^# task-001:.*$/# task-001/' "${WORK_DIR}/tasks/task-001.md" \
            > "${WORK_DIR}/tasks/task-001.md.tmp" \
            && mv "${WORK_DIR}/tasks/task-001.md.tmp" "${WORK_DIR}/tasks/task-001.md"
    fi

    # Degrade PLAN.md: remove wave-map blocks AND prose Wave lines -> lane truly null.
    # Removing only wave-map blocks is insufficient because PF-5b re-derives lane from
    # '- Wave N:' prose lines; stripping both ensures lane==null fires in the gate.
    if [[ -f "${WORK_DIR}/PLAN.md" ]]; then
        python3 -c "
import sys, re
path = sys.argv[1]
lines = open(path).readlines()
out = []
skip = False
re_wave_prose = re.compile(r'^\s*-\s*Wave\s+\d+\b', re.IGNORECASE)
for line in lines:
    stripped = line.strip()
    if stripped == '\`\`\`wave-map':
        skip = True
        continue
    if skip and stripped == '\`\`\`':
        skip = False
        continue
    if skip:
        continue
    # Also strip prose Wave lines so PF-5b has no fallback data
    if re_wave_prose.match(line):
        continue
    out.append(line)
open(path, 'w').writelines(out)
" "${WORK_DIR}/PLAN.md"
    fi
}

# ---------------------------------------------------------------------------
# Run the completeness check and capture output (for lane/delivery-null proof).
# Args: AID_ROOT LABEL EXPECT_FAIL EXPECT_LANE_NULL
#   EXPECT_LANE_NULL -- "1" means the output MUST contain a lane/delivery null line
#                       (proves the lane/delivery branch of the gate fires).
# ---------------------------------------------------------------------------

run_python_check_with_lane_proof() {
    local aid_root="$1"
    local label="$2"
    local expect_fail="${3:-0}"
    local expect_lane_null="${4:-0}"

    if [[ $HAS_PYTHON -eq 0 ]]; then
        log "[$label] SKIP python (runtime absent)"
        return 0
    fi

    local out rc
    set +e
    out=$(python3 -c "
import sys, os, re
repo_root = sys.argv[1]
aid_root  = sys.argv[2]
sys.path.insert(0, repo_root)
from dashboard.reader.reader import read_repo

model = read_repo(aid_root)
errors = []

for w in model.works:
    work_dir = os.path.join(aid_root, '.aid', w.work_id)

    has_requirements = os.path.isfile(os.path.join(work_dir, 'REQUIREMENTS.md'))
    has_spec = os.path.isfile(os.path.join(work_dir, 'SPEC.md'))
    is_conforming = has_requirements or has_spec

    if not is_conforming:
        continue

    slug_m = re.match(r'^work-\d+-(.+)$', w.work_id)
    slug = slug_m.group(1) if slug_m else w.work_id

    if w.title is None:
        errors.append(w.work_id + ': title is null (producer identity not emitted)')
    elif w.title == slug:
        errors.append(w.work_id + ': title equals de-slugged work_id (Name not emitted)')

    if w.description is None:
        errors.append(w.work_id + ': description is null')

    plan_path = os.path.join(work_dir, 'PLAN.md')
    has_plan = os.path.isfile(plan_path)

    for t in w.tasks:
        if t.short_name is None:
            errors.append(w.work_id + '/' + t.task_id + ': short_name is null')
        elif re.match(r'^task-\d+$', t.short_name, re.IGNORECASE):
            errors.append(w.work_id + '/' + t.task_id + ': short_name equals bare task-NNN id')

        if t.delivery is None:
            errors.append(w.work_id + '/' + t.task_id + ': delivery is null')

        if has_plan and t.lane is None:
            errors.append(w.work_id + '/' + t.task_id + ': lane is null (wave-map missing or incomplete)')

if errors:
    for e in errors:
        print('COMPLETENESS-FAIL: ' + e)
    sys.exit(1)

print('COMPLETENESS-OK: all conforming works have non-degraded fields')
" "${REPO_ROOT}" "${aid_root}" 2>&1)
    rc=$?
    set -e

    [[ "$VERBOSE" -eq 1 ]] && echo "$out"

    if [[ "$expect_fail" == "1" ]]; then
        if [[ $rc -ne 0 ]]; then
            pass "[$label] python completeness gate correctly fires on degraded fixture"
        else
            fail "[$label] python completeness gate did NOT fire on degraded fixture (expected non-zero)"
        fi
        # Prove the lane/delivery branch fires
        if [[ "$expect_lane_null" == "1" ]]; then
            if echo "$out" | grep -q 'lane is null\|delivery is null'; then
                pass "[$label] python: lane/delivery-null COMPLETENESS-FAIL line present (branch proven)"
            else
                fail "[$label] python: expected lane/delivery-null COMPLETENESS-FAIL but not found -- output: ${out}"
            fi
        fi
    else
        if [[ $rc -eq 0 ]]; then
            pass "[$label] python completeness gate passes on conforming fixture"
        else
            fail "[$label] python completeness gate FAILED on conforming fixture -- ${out}"
        fi
    fi
}

run_node_check_with_lane_proof() {
    local aid_root="$1"
    local label="$2"
    local expect_fail="${3:-0}"
    local expect_lane_null="${4:-0}"

    if [[ $HAS_NODE -eq 0 ]]; then
        log "[$label] SKIP node (runtime absent)"
        return 0
    fi

    local node_script="${TMP_ROOT}/pf9_check_lane.mjs"
    mkdir -p "${TMP_ROOT}"
    cat > "${node_script}" << MJSEOF
import { readRepo } from '${REPO_ROOT}/dashboard/server/reader.mjs';
import { existsSync } from 'fs';
import { join } from 'path';

const aidRoot  = process.argv[2];
const errors = [];
const model = readRepo(aidRoot);

for (const w of model.works) {
    const workDir = join(aidRoot, '.aid', w.work_id);
    const hasRequirements = existsSync(join(workDir, 'REQUIREMENTS.md'));
    const hasSpec = existsSync(join(workDir, 'SPEC.md'));
    const isConforming = hasRequirements || hasSpec;

    if (!isConforming) continue;

    const slugMatch = w.work_id.match(/^work-\d+-(.+)$/);
    const slug = slugMatch ? slugMatch[1] : w.work_id;

    if (w.title === null || w.title === undefined) {
        errors.push(w.work_id + ': title is null (producer identity not emitted)');
    } else if (w.title === slug) {
        errors.push(w.work_id + ': title equals de-slugged work_id (Name not emitted)');
    }

    if (w.description === null || w.description === undefined) {
        errors.push(w.work_id + ': description is null');
    }

    const planPath = join(workDir, 'PLAN.md');
    const hasPlan = existsSync(planPath);

    for (const t of w.tasks) {
        if (t.short_name === null || t.short_name === undefined) {
            errors.push(w.work_id + '/' + t.task_id + ': short_name is null');
        } else if (/^task-\d+$/.test(t.short_name)) {
            errors.push(w.work_id + '/' + t.task_id + ': short_name equals bare task-NNN id');
        }

        if (t.delivery === null || t.delivery === undefined) {
            errors.push(w.work_id + '/' + t.task_id + ': delivery is null');
        }

        if (hasPlan && (t.lane === null || t.lane === undefined)) {
            errors.push(w.work_id + '/' + t.task_id + ': lane is null (wave-map missing or incomplete)');
        }
    }
}

if (errors.length > 0) {
    for (const e of errors) process.stderr.write('COMPLETENESS-FAIL: ' + e + '\n');
    process.exit(1);
}
process.stdout.write('COMPLETENESS-OK: all conforming works have non-degraded fields\n');
MJSEOF

    local out rc
    set +e
    out=$(node "${node_script}" "${aid_root}" 2>&1)
    rc=$?
    set -e

    [[ "$VERBOSE" -eq 1 ]] && echo "$out"

    if [[ "$expect_fail" == "1" ]]; then
        if [[ $rc -ne 0 ]]; then
            pass "[$label] node completeness gate correctly fires on degraded fixture"
        else
            fail "[$label] node completeness gate did NOT fire on degraded fixture (expected non-zero)"
        fi
        # Prove the lane/delivery branch fires
        if [[ "$expect_lane_null" == "1" ]]; then
            if echo "$out" | grep -q 'lane is null\|delivery is null'; then
                pass "[$label] node: lane/delivery-null COMPLETENESS-FAIL line present (branch proven)"
            else
                fail "[$label] node: expected lane/delivery-null COMPLETENESS-FAIL but not found -- output: ${out}"
            fi
        fi
    else
        if [[ $rc -eq 0 ]]; then
            pass "[$label] node completeness gate passes on conforming fixture"
        else
            fail "[$label] node completeness gate FAILED on conforming fixture -- ${out}"
        fi
    fi
}

# ---------------------------------------------------------------------------
# POSITIVE assertion: conforming fixture must pass
# ---------------------------------------------------------------------------

echo ""
echo "--- Positive assertion (conforming fixture) ---"

run_python_check "${FIXTURE_FULL}" "positive-python" "0"
run_node_check   "${FIXTURE_FULL}" "positive-node"   "0"

# Guard: the SPEC-only work (work-006-lite-sample) MUST be present in the
# fixture and non-degraded. If it is absent, the SPEC path has silently
# dropped out of coverage and the test must fail.
echo ""
echo "--- SPEC-only coverage guard (work-006-lite-sample must be present and pass) ---"

SPEC_WORK_DIR="${FIXTURE_FULL}/.aid/work-006-lite-sample"
if [[ ! -d "${SPEC_WORK_DIR}" ]]; then
    fail "[spec-guard] work-006-lite-sample directory not found in fixture"
elif [[ -f "${SPEC_WORK_DIR}/REQUIREMENTS.md" ]]; then
    fail "[spec-guard] work-006-lite-sample has REQUIREMENTS.md -- it must be SPEC-only (Lite path)"
elif [[ ! -f "${SPEC_WORK_DIR}/SPEC.md" ]]; then
    fail "[spec-guard] work-006-lite-sample has no SPEC.md -- Lite fixture incomplete"
else
    pass "[spec-guard] work-006-lite-sample is SPEC-only (no REQUIREMENTS.md, SPEC.md present)"
fi

if [[ $HAS_PYTHON -eq 1 ]]; then
    spec_title=$(python3 -c "
import sys
sys.path.insert(0, sys.argv[1])
from dashboard.reader.reader import read_repo
model = read_repo(sys.argv[2])
for w in model.works:
    if w.work_id == 'work-006-lite-sample':
        print(w.title or '')
        break
" "${REPO_ROOT}" "${FIXTURE_FULL}" 2>/dev/null)
    if [[ -n "${spec_title}" && "${spec_title}" != "lite-sample" ]]; then
        pass "[spec-guard] python: SPEC-only work title is non-null and non-slug: ${spec_title}"
    else
        fail "[spec-guard] python: SPEC-only work title is null or de-slug (SPEC path not working): '${spec_title}'"
    fi
fi

if [[ $HAS_NODE -eq 1 ]]; then
    spec_node_script="${TMP_ROOT}/spec_guard.mjs"
    mkdir -p "${TMP_ROOT}"
    cat > "${spec_node_script}" << SPECEOF
import { readRepo } from '${REPO_ROOT}/dashboard/server/reader.mjs';
const model = readRepo(process.argv[2]);
const w = model.works.find(x => x.work_id === 'work-006-lite-sample');
process.stdout.write((w && w.title) ? w.title : '');
SPECEOF
    spec_title_node=$(node "${spec_node_script}" "${FIXTURE_FULL}" 2>/dev/null)
    if [[ -n "${spec_title_node}" && "${spec_title_node}" != "lite-sample" ]]; then
        pass "[spec-guard] node: SPEC-only work title is non-null and non-slug: ${spec_title_node}"
    else
        fail "[spec-guard] node: SPEC-only work title is null or de-slug (SPEC path not working): '${spec_title_node}'"
    fi
fi

# ---------------------------------------------------------------------------
# NEGATIVE assertion: degraded fixture must fail the gate.
# Also proves the lane/delivery-null branch fires (not only title/short_name).
# ---------------------------------------------------------------------------

echo ""
echo "--- Negative assertion (degraded fixture -- gate must fire) ---"

mkdir -p "${TMP_ROOT}"
DEGRADED_ROOT="${TMP_ROOT}/degraded-fixture"
mkdir -p "${DEGRADED_ROOT}"

build_degraded_fixture "${FIXTURE_FULL}" "${DEGRADED_ROOT}"

run_python_check_with_lane_proof "${DEGRADED_ROOT}" "negative-python" "1" "1"
run_node_check_with_lane_proof   "${DEGRADED_ROOT}" "negative-node"   "1" "1"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
test_summary
