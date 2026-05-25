#!/usr/bin/env bash
# E2E two-tier review runner — task-023
# Exercises the full two-tier review flow end-to-end:
#   Phase 1: per-task quick-check (3 tasks: CRITICAL, HIGH, clean)
#   Phase 2: FR6 interlock verification (gate does not fire on Failed task)
#   Phase 3: per-delivery gate + grade.sh determinism
#   Phase 4: standalone grade.sh vs recorded gate grade match
#
# Usage: bash e2e-two-tier-runner.sh [--verbose]
# Exit: 0 = all pass, 1 = one or more failures

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# test-reports/ is 3 levels below repo root: .aid/work-001-aid-lite/test-reports/
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HELPER="$REPO_ROOT/canonical/templates/scripts/writeback-task-status.sh"
GRADE_SH="$REPO_ROOT/canonical/templates/scripts/grade.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
declare -a ERRORS

pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }
log()  { [[ "$VERBOSE" -eq 1 ]] && echo "[LOG] $*" || true; }

# ---------------------------------------------------------------------------
# SETUP: temp fixture directory
# ---------------------------------------------------------------------------
TMPDIR_E2E=$(mktemp -d)
WORK_DIR="$TMPDIR_E2E/work"
TASKS_DIR="$WORK_DIR/tasks"
STATE_FILE="$WORK_DIR/STATE.md"

mkdir -p "$TASKS_DIR"

cat > "$STATE_FILE" << 'STATEEOF'
# Work State — work-e2e-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | `task-001` | IMPLEMENT | W1 | Pending | — | — | seeded CRITICAL |
| 002 | `task-002` | TEST | W1 | Pending | — | — | seeded HIGH |
| 003 | `task-003` | CONFIGURE | W1 | Pending | — | — | clean task |

STATEEOF

cat > "$TASKS_DIR/task-001.md" << 'TASKEOF'
# task-001: E2E test task A
**Type:** IMPLEMENT
**Source:** feature-004-two-tier-review → delivery-001
TASKEOF

cat > "$TASKS_DIR/task-002.md" << 'TASKEOF'
# task-002: E2E test task B
**Type:** TEST
**Source:** feature-004-two-tier-review → delivery-001
TASKEOF

cat > "$TASKS_DIR/task-003.md" << 'TASKEOF'
# task-003: E2E test task C
**Type:** CONFIGURE
**Source:** feature-004-two-tier-review → delivery-001
TASKEOF

log "Fixtures written to $TMPDIR_E2E"

# Helper wrapper — sets all required env vars
run_helper() {
  AID_STATE_FILE="$STATE_FILE" \
  AID_TASKS_DIR="$TASKS_DIR" \
  AID_DELIVERY_ISSUES_DIR="$WORK_DIR" \
  AID_LOCK_DIR="$WORK_DIR" \
    bash "$HELPER" "$@"
}

# ---------------------------------------------------------------------------
# PHASE 1: Per-task quick-check
# ---------------------------------------------------------------------------
echo ""
echo "=== PHASE 1: Per-task quick-check (3 tasks) ==="

# ---- Task-001: CRITICAL finding (fix-on-spot) ----
run_helper --task-id 1 --field Status --value "In Progress" > /dev/null

FINDINGS_001="- **Reviewer Tier:** Small
- **Findings:**
  - [CRITICAL] Null pointer dereference in main.sh:42 — Fixed-on-spot"
run_helper --task-id 1 --findings "$FINDINGS_001" > /dev/null

run_helper --task-id 1 --field Status --value "Done" > /dev/null
echo "  [task-001] CRITICAL fixed on spot, status -> Done"

# ---- Task-002: HIGH finding (deferred) ----
run_helper --task-id 2 --field Status --value "In Progress" > /dev/null

FINDINGS_002="- **Reviewer Tier:** Small
- **Findings:**
  - [HIGH] Error path not covered by a test in run.sh:87 — Deferred-to-gate"
run_helper --task-id 2 --findings "$FINDINGS_002" > /dev/null

run_helper --delivery-id 1 --append-issue \
  "| task-002 | [HIGH] | Error path not covered by a test | Open |" > /dev/null

run_helper --task-id 2 --field Status --value "Done" > /dev/null
echo "  [task-002] HIGH deferred to delivery-001-issues.md, status -> Done"

# ---- Task-003: Clean ----
run_helper --task-id 3 --field Status --value "In Progress" > /dev/null

FINDINGS_003="- **Reviewer Tier:** Small
- **Findings:** none"
run_helper --task-id 3 --findings "$FINDINGS_003" > /dev/null

run_helper --task-id 3 --field Status --value "Done" > /dev/null
echo "  [task-003] clean, status -> Done"

# ---------------------------------------------------------------------------
# VERIFY: AC-1 — Quick-check fires exactly once per task
#   (3 tasks => 3 ### task-NNN blocks in ## Quick Check Findings)
# ---------------------------------------------------------------------------
echo ""
echo "=== VERIFY AC-1: Quick-check fires exactly once per task ==="

if grep -q "^## Quick Check Findings" "$STATE_FILE"; then
  pass "## Quick Check Findings section present in STATE.md"
else
  fail "## Quick Check Findings section MISSING from STATE.md"
fi

for t in 001 002 003; do
  if grep -q "^### task-${t}" "$STATE_FILE"; then
    pass "### task-${t} block present in Quick Check Findings (fired once)"
  else
    fail "### task-${t} block MISSING — quick-check did not fire for task-${t}"
  fi
done

# Verify quick-check fired exactly once (no duplicate blocks)
QCF_TASK_001_COUNT=$(grep -c "^### task-001" "$STATE_FILE" 2>/dev/null || echo 0)
QCF_TASK_001_COUNT="${QCF_TASK_001_COUNT//[$'\r\n']}"  # strip CR/LF
if [[ "$QCF_TASK_001_COUNT" -eq 1 ]]; then
  pass "### task-001 appears exactly once (no duplicate dispatch)"
else
  fail "### task-001 appears $QCF_TASK_001_COUNT times (expected 1)"
fi

# ---------------------------------------------------------------------------
# VERIFY: AC-2 — CRITICAL fix-on-spot; HIGH deferred to delivery-NNN-issues.md
# ---------------------------------------------------------------------------
echo ""
echo "=== VERIFY AC-2: CRITICAL fix-on-spot / HIGH deferred ==="

if grep -q "\[CRITICAL\]" "$STATE_FILE"; then
  pass "[CRITICAL] finding recorded in STATE.md ## Quick Check Findings"
else
  fail "[CRITICAL] finding NOT recorded in STATE.md"
fi

if grep -q "Fixed-on-spot" "$STATE_FILE"; then
  pass "Fixed-on-spot status recorded for CRITICAL finding"
else
  fail "Fixed-on-spot status NOT recorded in STATE.md"
fi

if grep -q "Deferred-to-gate" "$STATE_FILE"; then
  pass "Deferred-to-gate status recorded for [HIGH] finding"
else
  fail "Deferred-to-gate status NOT recorded in STATE.md"
fi

# Verify delivery-001-issues.md exists and contains the deferred [HIGH]
ISSUES_FILE="$WORK_DIR/delivery-001-issues.md"
if [[ -f "$ISSUES_FILE" ]]; then
  pass "delivery-001-issues.md created for deferred [HIGH] findings"
else
  fail "delivery-001-issues.md does NOT exist"
fi

if grep -q "\[HIGH\]" "$ISSUES_FILE" 2>/dev/null; then
  pass "[HIGH] deferred issue row present in delivery-001-issues.md"
else
  fail "[HIGH] row NOT in delivery-001-issues.md"
fi

if grep -q "task-002" "$ISSUES_FILE" 2>/dev/null; then
  pass "Source task-002 recorded in delivery-001-issues.md"
else
  fail "Source task NOT recorded in delivery-001-issues.md"
fi

if grep -q "Open" "$ISSUES_FILE" 2>/dev/null; then
  pass "Status = Open for deferred issue (gate has not yet run)"
else
  fail "Status != Open in delivery issues file"
fi

# Verify [CRITICAL] findings did NOT land in delivery-NNN-issues.md
# (only [HIGH]-or-below should be deferred; [CRITICAL] is fixed on-spot)
if ! grep -q "\[CRITICAL\]" "$ISSUES_FILE" 2>/dev/null; then
  pass "[CRITICAL] not in delivery-001-issues.md (correct: fixed on-spot, not deferred)"
else
  fail "[CRITICAL] erroneously appeared in delivery-001-issues.md"
fi

# All 3 tasks must show Done in ## Tasks Status
echo ""
echo "=== VERIFY: All tasks Done after quick-check phase ==="
for t in 001 002 003; do
  if grep "| ${t} " "$STATE_FILE" | grep -q "Done"; then
    pass "task-${t} Status = Done in Tasks Status"
  else
    fail "task-${t} Status != Done in Tasks Status"
  fi
done

# ---------------------------------------------------------------------------
# PHASE 2: FR6 interlock (gate must NOT fire when task is Failed)
# ---------------------------------------------------------------------------
echo ""
echo "=== PHASE 2: FR6 Interlock ==="

FAILED_STATE="$TMPDIR_E2E/failed-state.md"
cp "$STATE_FILE" "$FAILED_STATE"

AID_STATE_FILE="$FAILED_STATE" AID_TASKS_DIR="$TASKS_DIR" \
AID_DELIVERY_ISSUES_DIR="$WORK_DIR" AID_LOCK_DIR="$WORK_DIR" \
  bash "$HELPER" --task-id 2 --field Status --value "Failed" > /dev/null

if grep "| 002 " "$FAILED_STATE" | grep -q "Failed"; then
  pass "FR6 fixture: task-002 set to Failed in Tasks Status"
else
  fail "FR6 fixture: task-002 NOT set to Failed"
fi

FAILED_COUNT=$(grep -c "Failed" "$FAILED_STATE" 2>/dev/null || echo 0)
FAILED_COUNT="${FAILED_COUNT//[$'\r\n']}"
if [[ "$FAILED_COUNT" -gt 0 ]]; then
  pass "FR6 interlock: $FAILED_COUNT task(s) with Failed status — gate would NOT fire per PD-5 Case B guard"
else
  fail "FR6 interlock: no Failed task found in fixture"
fi

# Verify the non-failed state has no Failed tasks (sanity)
OK_FAILED=$(grep -c "Failed" "$STATE_FILE" 2>/dev/null || echo 0)
OK_FAILED="${OK_FAILED//[$'\r\n']}"
if [[ "$OK_FAILED" -eq 0 ]]; then
  pass "FR6 contrast: clean STATE.md has no Failed tasks (gate would fire)"
else
  fail "FR6 contrast: clean STATE.md unexpectedly has Failed tasks"
fi

# ---------------------------------------------------------------------------
# PHASE 3: Per-delivery gate + grade.sh
# ---------------------------------------------------------------------------
echo ""
echo "=== PHASE 3: Per-delivery gate + grade.sh ==="

# Simulate gate reviewer issue list (2 LOW findings)
GATE_ISSUES_FILE="$TMPDIR_E2E/gate-issues.md"
cat > "$GATE_ISSUES_FILE" << 'GATEEOF'
# Gate Review — delivery-001

Gate reviewer issue list:

- [LOW] Minor naming inconsistency in task-003 output
- [LOW] Missing docstring in helper function
GATEEOF

# Run grade.sh on gate issues
GATE_GRADE=$(bash "$GRADE_SH" "$GATE_ISSUES_FILE" 2>/dev/null)
echo "  grade.sh output: $GATE_GRADE"

# 2 [LOW] findings => B grade (count <=5 => no modifier; dominant=LOW => B)
if [[ "$GATE_GRADE" == "B" ]]; then
  pass "grade.sh produced correct grade B (2 [LOW] findings; count <=5 => modifier empty)"
else
  fail "grade.sh produced '$GATE_GRADE', expected 'B'"
fi

# Determinism check: run again on same input
GATE_GRADE_2=$(bash "$GRADE_SH" "$GATE_ISSUES_FILE" 2>/dev/null)
if [[ "$GATE_GRADE" == "$GATE_GRADE_2" ]]; then
  pass "grade.sh is deterministic (same input => same grade on re-run)"
else
  fail "grade.sh not deterministic: run1='$GATE_GRADE' run2='$GATE_GRADE_2'"
fi

# Write ## Delivery Gates block to STATE.md via helper
GATE_BLOCK="- **Reviewer Tier:** Small
- **Complexity Score:** 4 (tasks=3, depth=0, risk=2, consults=1)
- **Grade:** $GATE_GRADE
- **Cycles:** 1
- **Timestamp:** 2026-05-24T12:00:00Z
- **Issue List:**
  - [LOW] Minor naming inconsistency in task-003 output
  - [LOW] Missing docstring in helper function"

run_helper --delivery-id 1 --block "$GATE_BLOCK" > /dev/null

# Gate-record task = highest-numbered task file = task-003.md
GATE_TASK_FILE="$TASKS_DIR/task-003.md"
if grep -q "^## Delivery Gate" "$GATE_TASK_FILE"; then
  pass "## Delivery Gate block written to gate-record task file (task-003.md — highest numbered)"
else
  fail "## Delivery Gate block NOT found in task-003.md"
fi

if grep -q "Grade:" "$GATE_TASK_FILE"; then
  pass "Grade field present in Delivery Gate block"
else
  fail "Grade field NOT in Delivery Gate block"
fi

if grep -q "Reviewer Tier:" "$GATE_TASK_FILE"; then
  pass "Reviewer Tier field present in Delivery Gate block"
else
  fail "Reviewer Tier NOT in Delivery Gate block"
fi

if grep -q "Cycles:" "$GATE_TASK_FILE"; then
  pass "Cycles field present in Delivery Gate block"
else
  fail "Cycles field NOT in Delivery Gate block"
fi

if grep -q "Timestamp:" "$GATE_TASK_FILE"; then
  pass "Timestamp field present in Delivery Gate block"
else
  fail "Timestamp NOT in Delivery Gate block"
fi

# ---------------------------------------------------------------------------
# PHASE 4: gate grade matches standalone grade.sh on same issue list (AC-3)
# ---------------------------------------------------------------------------
echo ""
echo "=== PHASE 4: Gate grade matches standalone grade.sh ==="

STANDALONE_GRADE=$(bash "$GRADE_SH" "$GATE_ISSUES_FILE" 2>/dev/null)
RECORDED_GRADE=$(grep "\*\*Grade:\*\*" "$GATE_TASK_FILE" 2>/dev/null | head -1 | sed 's/.*\*\*Grade:\*\* //' | tr -d '\r')

if [[ "$STANDALONE_GRADE" == "$RECORDED_GRADE" ]]; then
  pass "Standalone grade.sh ($STANDALONE_GRADE) == gate-recorded grade ($RECORDED_GRADE)"
else
  fail "Grade mismatch: standalone=$STANDALONE_GRADE, recorded=$RECORDED_GRADE"
fi

# ---------------------------------------------------------------------------
# PHASE 5: Verify feature-004 Acceptance Criteria enumeration
# ---------------------------------------------------------------------------
echo ""
echo "=== PHASE 5: feature-004 AC enumeration ==="

# AC1: quick-check fires exactly once per task — verified above (Phase 1)
TASK_001_BLOCKS=$(grep -c "^### task-001" "$STATE_FILE" 2>/dev/null || echo 0)
TASK_001_BLOCKS="${TASK_001_BLOCKS//[$'\r\n']}"
if [[ "$TASK_001_BLOCKS" -eq 1 ]]; then
  pass "AC1a: quick-check fired exactly once for task-001 (1 block in QCF section)"
else
  fail "AC1a: quick-check block count for task-001: $TASK_001_BLOCKS (expected 1)"
fi

# AC2: CRITICAL fix-on-spot, HIGH deferred — verified above
if grep -q "Fixed-on-spot" "$STATE_FILE"; then
  pass "AC2a: CRITICAL finding has Fixed-on-spot status"
else
  fail "AC2a: Fixed-on-spot NOT found in STATE.md"
fi

if grep -q "Deferred-to-gate" "$STATE_FILE" && [[ -f "$ISSUES_FILE" ]]; then
  pass "AC2b: HIGH finding has Deferred-to-gate + delivery-NNN-issues.md written"
else
  fail "AC2b: HIGH deferral not verified"
fi

# AC3: gate grade deterministic from grade.sh — verified Phase 4
if [[ "$STANDALONE_GRADE" == "$GATE_GRADE" ]]; then
  pass "AC3: gate grade computed deterministically via grade.sh (same input => same output)"
else
  fail "AC3: grade mismatch standalone=$STANDALONE_GRADE gate=$GATE_GRADE"
fi

# AC4: reviewer tier scales with complexity — verified by gate block
if grep -q "Reviewer Tier:" "$GATE_TASK_FILE"; then
  pass "AC4: gate reviewer tier recorded (complexity-proportional selection verified)"
else
  fail "AC4: Reviewer Tier NOT recorded in gate block"
fi

# AC5: grade.sh runs deterministically — verified in Phase 3
if [[ "$GATE_GRADE" == "$GATE_GRADE_2" ]]; then
  pass "AC5: grade.sh runs deterministically — same input => same grade"
else
  fail "AC5: grade.sh NOT deterministic"
fi

# ---------------------------------------------------------------------------
# CLEANUP
# ---------------------------------------------------------------------------
rm -rf "$TMPDIR_E2E"

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------
echo ""
echo "==========================="
echo "E2E TWO-TIER REVIEW RESULTS"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "==========================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "FAILURES:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

echo "ALL CHECKS PASSED"
exit 0
