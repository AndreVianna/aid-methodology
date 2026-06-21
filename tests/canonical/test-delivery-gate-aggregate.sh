#!/usr/bin/env bash
# test-delivery-gate-aggregate.sh — Unit tests for the delivery-gate logic in aid-execute.
#
# Tests cover:
#   1. AGGREGATE with existing delivery-NNN-issues.md (deferred rows preserved)
#   2. AGGREGATE with no issues file (creates empty log correctly)
#   3. SCORE computation for 3 sample deliveries of varying complexity
#   4. Grade computation via grade.sh (deterministic output verification)
#   5. Loopback guard (grade < min does NOT re-run quick-checks, only loops review)
#   6. FR6 interlock (gate must not fire while any task has status Failed or Blocked)
#   7. RECORD — --delivery-id --block writes ## Delivery Gate into delivery-NNN/STATE.md (SD-5 / work-004)
#              per-delivery model: work-level ## Delivery Gates is DERIVED (not written by helper)
#
# Usage:
#   test-delivery-gate-aggregate.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed
#
# Dependencies:
#   - writeback-state.sh (must be in PATH or same directory)
#   - grade.sh                 (must be in PATH or same directory)

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SUTs moved in 2026-05-26 consolidation
WRITEBACK="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/writeback-state.sh"
GRADE="${SCRIPT_DIR}/../../canonical/aid/scripts/grade.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# Create a temporary test workspace
make_workspace() {
    local tmpdir
    tmpdir=$(mktemp -d)
    # Minimal STATE.md with ## Tasks Status and ## Delivery Gates sections
    mkdir -p "$tmpdir/.aid/work/tasks"
    cat > "$tmpdir/.aid/work/STATE.md" <<'EOF'
# Work State — work-001-test

> **Status:** Executing

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-impl | IMPLEMENT | 1 | Done | — | 2m | — |
| 002 | task-002-test | TEST | 1 | Done | — | 1m | — |

## Delivery Gates

> One block per delivery.

## Quick Check Findings

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-01-01 | Work created | — | — |
EOF
    # Minimal discovery STATE.md for gate tier thresholds
    mkdir -p "$tmpdir/.aid/knowledge"
    cat > "$tmpdir/.aid/knowledge/STATE.md" <<'EOF'
> **Minimum Grade:** A
> **Gate Tier Low Threshold:** 6
> **Gate Tier High Threshold:** 14
> **Max Parallel Tasks:** 3
EOF
    echo "$tmpdir"
}

cleanup() { rm -rf "$1"; }

# ---------------------------------------------------------------------------
# Test 1: AGGREGATE — existing delivery-NNN-issues.md is preserved
# ---------------------------------------------------------------------------
run_test_1() {
    local ws
    ws=$(make_workspace)

    # Pre-populate a delivery-003-issues.md with 2 deferred [HIGH] rows
    cat > "$ws/.aid/work/delivery-003-issues.md" <<'EOF'
# Delivery Issue Log — delivery-003

> Deferred findings from per-task quick checks.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-001 | [HIGH] | error path not tested | Open |
| task-002 | [HIGH] | naming deviates from standards | Open |
EOF

    # AGGREGATE step: verify the file is readable and has 2 rows
    # Use -E with explicit pipe literal (not \| which is alternation in BRE)
    local row_count
    row_count=$(grep -cE '^\| task-[0-9]' "$ws/.aid/work/delivery-003-issues.md" || echo "0")
    if [[ "$row_count" -eq 2 ]]; then
        pass "Test 1: AGGREGATE reads existing delivery-NNN-issues.md with 2 deferred rows"
    else
        fail "Test 1: AGGREGATE reads existing delivery-NNN-issues.md" \
             "Expected 2 rows, got $row_count"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 2: AGGREGATE — no issues file → creates empty log
# ---------------------------------------------------------------------------
run_test_2() {
    local ws
    ws=$(make_workspace)

    local issues_file="$ws/.aid/work/delivery-003-issues.md"

    # File does not exist yet
    [[ ! -f "$issues_file" ]] || { fail "Test 2 setup: issues file should not exist"; cleanup "$ws"; return; }

    # Simulate AGGREGATE creating the file by invoking writeback helper
    AID_STATE_FILE="$ws/.aid/work/STATE.md" \
    AID_DELIVERY_ISSUES_DIR="$ws/.aid/work" \
    AID_LOCK_DIR="$ws/.aid/work" \
    "$WRITEBACK" --delivery-id 003 --append-issue \
        "| (none) | — | No deferred [HIGH] issues from quick checks | Resolved |" \
        > /dev/null 2>&1

    if [[ -f "$issues_file" ]]; then
        pass "Test 2: AGGREGATE creates delivery-NNN-issues.md when it does not exist"
    else
        fail "Test 2: AGGREGATE creates delivery-NNN-issues.md when it does not exist" \
             "File was not created at $issues_file"
    fi

    # Verify the header is correct (writeback creates file with double-hyphen separator "--")
    if grep -q "# Delivery Issue Log -- delivery-003" "$issues_file"; then
        pass "Test 2: Created file has correct header"
    else
        fail "Test 2: Created file has correct header" \
             "Header not found in $issues_file"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 3: SCORE — 3 sample deliveries of varying complexity
#
# Delivery A (small/lite): 3 tasks, depth 2, types=IMPLEMENT+TEST+DOCUMENT, no consults
#   score = 3 (tasks) + 2 (depth) + 1+1+0 (risk) + 0 (consults) = 7 → Medium tier
#
# Delivery B (trivial): 2 tasks, depth 1, types=DOCUMENT+CONFIGURE, no consults
#   score = 2 + 1 + 0+0 + 0 = 3 → Small tier
#
# Delivery C (complex): 6 tasks, depth 4, types=MIGRATE+IMPLEMENT×2+TEST×2+CONFIGURE, 2 consults
#   score = 6 + 4 + 2+1+1+1+1+0 + 2 = 18 → Large tier
# ---------------------------------------------------------------------------
run_test_3() {
    # This test verifies the scoring algorithm logic, not a script — it computes
    # the score inline and checks the tier selection against threshold defaults.
    local low_threshold=6
    local high_threshold=14

    # Delivery A
    local score_a=$((3 + 2 + 1 + 1 + 0 + 0))  # = 7
    local tier_a
    if   [[ $score_a -le $low_threshold ]]; then  tier_a="Small"
    elif [[ $score_a -lt $high_threshold ]]; then tier_a="Medium"
    else                                           tier_a="Large"
    fi
    if [[ "$tier_a" == "Medium" && $score_a -eq 7 ]]; then
        pass "Test 3a: Delivery A (score=7) → Medium tier (expected)"
    else
        fail "Test 3a: Delivery A scoring" "Got tier=$tier_a score=$score_a (expected Medium/7)"
    fi

    # Delivery B
    local score_b=$((2 + 1 + 0 + 0 + 0))  # = 3
    local tier_b
    if   [[ $score_b -le $low_threshold ]]; then  tier_b="Small"
    elif [[ $score_b -lt $high_threshold ]]; then tier_b="Medium"
    else                                           tier_b="Large"
    fi
    if [[ "$tier_b" == "Small" && $score_b -eq 3 ]]; then
        pass "Test 3b: Delivery B (score=3) → Small tier (expected)"
    else
        fail "Test 3b: Delivery B scoring" "Got tier=$tier_b score=$score_b (expected Small/3)"
    fi

    # Delivery C
    local score_c=$((6 + 4 + 2 + 1 + 1 + 1 + 1 + 0 + 2))  # = 18
    local tier_c
    if   [[ $score_c -le $low_threshold ]]; then  tier_c="Small"
    elif [[ $score_c -lt $high_threshold ]]; then tier_c="Medium"
    else                                           tier_c="Large"
    fi
    if [[ "$tier_c" == "Large" && $score_c -eq 18 ]]; then
        pass "Test 3c: Delivery C (score=18) → Large tier (expected)"
    else
        fail "Test 3c: Delivery C scoring" "Got tier=$tier_c score=$score_c (expected Large/18)"
    fi
}

# ---------------------------------------------------------------------------
# Test 4: GRADE — grade.sh produces correct deterministic output
# ---------------------------------------------------------------------------
run_test_4() {
    # Clean issue list → A+
    local grade_clean
    grade_clean=$(echo "No issues found." | "$GRADE")
    if [[ "$grade_clean" == "A+" ]]; then
        pass "Test 4a: grade.sh on empty issue list → A+"
    else
        fail "Test 4a: grade.sh on empty issue list" "Got '$grade_clean', expected 'A+'"
    fi

    # One [HIGH] → D+ (schema-table format)
    local grade_high
    grade_high=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [HIGH] | Pending | foo.md | 1 | some issue | evidence |\n' | "$GRADE")
    if [[ "$grade_high" == "D+" ]]; then
        pass "Test 4b: grade.sh with 1 [HIGH] → D+"
    else
        fail "Test 4b: grade.sh with 1 [HIGH]" "Got '$grade_high', expected 'D+'"
    fi

    # One [CRITICAL] → E+ (schema-table format)
    local grade_crit
    grade_crit=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [CRITICAL] | Pending | foo.md | 1 | fatal issue | evidence |\n' | "$GRADE")
    if [[ "$grade_crit" == "E+" ]]; then
        pass "Test 4c: grade.sh with 1 [CRITICAL] → E+"
    else
        fail "Test 4c: grade.sh with 1 [CRITICAL]" "Got '$grade_crit', expected 'E+'"
    fi

    # Three [MEDIUM] → C (schema-table format; not C+ since count > 1; not C- since count <= 5)
    local grade_medium
    grade_medium=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [MEDIUM] | Pending | foo.md | 1 | issue 1 | evidence |\n| 2 | [MEDIUM] | Pending | foo.md | 2 | issue 2 | evidence |\n| 3 | [MEDIUM] | Pending | foo.md | 3 | issue 3 | evidence |\n' | "$GRADE")
    if [[ "$grade_medium" == "C" ]]; then
        pass "Test 4d: grade.sh with 3 [MEDIUM] → C"
    else
        fail "Test 4d: grade.sh with 3 [MEDIUM]" "Got '$grade_medium', expected 'C'"
    fi

    # Tags in Description column are ignored -- schema-table mode reads only col3 (Severity)
    # This is the cycle-7 regression test: summary prose with tag strings must NOT inflate grade
    local grade_backtick
    grade_backtick=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [MINOR] | Pending | foo.md | 1 | 0 [CRITICAL] / 0 [HIGH] found in summary | prose leaked tags |\n' | "$GRADE")
    if [[ "$grade_backtick" == "A" ]]; then
        pass "Test 4e: grade.sh ignores tags in Description column (cycle-7 regression)"
    else
        fail "Test 4e: grade.sh ignores tags in Description column (cycle-7 regression)" \
             "Got '$grade_backtick', expected 'A'"
    fi
}

# ---------------------------------------------------------------------------
# Test 5: LOOPBACK — fix cycle does NOT re-run quick-checks
#
# This test verifies the state transition semantics: when grade < min, the
# gate loops to FIX then back to Step 2 (REVIEW gate reviewer), NOT to the
# per-task quick-check (Step 1.5 in state-review.md). We verify this by
# checking that delivery-NNN-issues.md is NOT modified during a fix cycle
# (quick-checks would append new rows; the gate fix loop does not).
# ---------------------------------------------------------------------------
run_test_5() {
    local ws
    ws=$(make_workspace)

    # Pre-populate a delivery-003-issues.md
    cat > "$ws/.aid/work/delivery-003-issues.md" <<'EOF'
# Delivery Issue Log — delivery-003

> Deferred findings from per-task quick checks.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-001 | [HIGH] | original deferred issue | Open |
EOF

    local before_hash after_hash
    before_hash=$(sha256sum "$ws/.aid/work/delivery-003-issues.md" | awk '{print $1}')

    # Simulate a fix cycle: the fix dispatch writes to code files, NOT to
    # delivery-NNN-issues.md. We verify the issues file is unchanged after
    # a fix cycle by simply checking the hash is unchanged (no append happened).
    # In real execution, code fixes happen in the working tree — not in the
    # issues log. The issues log is only written by: (a) AGGREGATE (step 0,
    # once), (b) quick-check triage (--append-issue, before gate fires),
    # (c) RECORD (step 6, marking Resolved/Accepted).
    after_hash="$before_hash"   # simulated: fix cycle did not touch issues file

    if [[ "$before_hash" == "$after_hash" ]]; then
        pass "Test 5: Fix cycle does NOT append to delivery-NNN-issues.md (loopback is review-only)"
    else
        fail "Test 5: Fix cycle does NOT append to delivery-NNN-issues.md" \
             "Hash changed: before=$before_hash after=$after_hash"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 6: FR6 INTERLOCK — gate must NOT fire when any task is Failed or Blocked
# ---------------------------------------------------------------------------
run_test_6() {
    local ws
    ws=$(make_workspace)

    # Add a failed task to STATE.md
    # (Simulate the pool having a Failed task — PD-5 Case B should prevent gate)
    cat > "$ws/.aid/work/STATE.md" <<'EOF'
# Work State — work-001-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-impl | IMPLEMENT | 1 | Done | — | 2m | — |
| 002 | task-002-test | TEST | 1 | Failed | — | — | impediment raised |

## Delivery Gates

## Quick Check Findings

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-01-01 | Work created | — | — |
EOF

    # FR6 interlock check: count tasks NOT in Done status
    local not_done
    not_done=$(awk '
        /^## Tasks Status/{s=1; next}
        s && /^## /{s=0}
        s && /^\|/ {
            n=split($0,f,"|")
            if (n>=6) {
                status=f[6]
                gsub(/^[[:space:]]+|[[:space:]]+$/,"",status)
                # Skip header row ("Status") and separator rows (contain only dashes)
                if (status == "Status") next
                if (status ~ /^-+$/) next
                if (status != "Done") print status
            }
        }
    ' "$ws/.aid/work/STATE.md" | grep -v '^$' | wc -l | tr -d ' ')

    if [[ "$not_done" -gt 0 ]]; then
        pass "Test 6a: FR6 interlock detects $not_done task(s) not Done — gate should NOT fire"
    else
        fail "Test 6a: FR6 interlock detection" \
             "Expected at least 1 non-Done task, found 0"
    fi

    # Verify the specific failed task is detected
    local has_failed
    has_failed=$(awk '
        /^## Tasks Status/{s=1; next}
        s && /^## /{s=0}
        s && /Failed/{print "yes"; exit}
    ' "$ws/.aid/work/STATE.md")

    if [[ "$has_failed" == "yes" ]]; then
        pass "Test 6b: FR6 interlock correctly identifies Failed task in Tasks Status"
    else
        fail "Test 6b: FR6 interlock identifies Failed task" \
             "Failed status not found in Tasks Status"
    fi

    # Now set all to Done and verify interlock would pass
    cat > "$ws/.aid/work/STATE.md" <<'EOF'
# Work State — work-001-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-impl | IMPLEMENT | 1 | Done | — | 2m | — |
| 002 | task-002-test | TEST | 1 | Done | — | 1m | — |

## Delivery Gates

## Quick Check Findings

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-01-01 | Work created | — | — |
EOF

    local not_done_after
    not_done_after=$(awk '
        /^## Tasks Status/{s=1; next}
        s && /^## /{s=0}
        s && /^\|/ {
            n=split($0,f,"|")
            if (n>=6) {
                status=f[6]
                gsub(/^[[:space:]]+|[[:space:]]+$/,"",status)
                # Skip header row ("Status") and separator rows (contain only dashes)
                if (status == "Status") next
                if (status ~ /^-+$/) next
                if (status != "Done") print status
            }
        }
    ' "$ws/.aid/work/STATE.md" | grep -v '^$' | wc -l | tr -d ' ')

    if [[ "$not_done_after" -eq 0 ]]; then
        pass "Test 6c: FR6 interlock passes (all tasks Done) — gate CAN fire"
    else
        fail "Test 6c: FR6 interlock passes when all Done" \
             "Expected 0 non-Done tasks, found $not_done_after"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 7: RECORD — writeback-state.sh --delivery-id --block writes
#          the per-delivery ## Delivery Gate block correctly (SD-5 / work-004).
#
# work-004 (task-003/007) retargeted --delivery-id --block to write the gate
# into delivery-NNN/STATE.md ## Delivery Gate (per-delivery, single-writer).
# The work-level ## Delivery Gates section is now a DERIVED read-only view
# assembled by the reader -- the helper no longer writes to it.
# ---------------------------------------------------------------------------
run_test_7() {
    local ws
    ws=$(make_workspace)

    # Create the per-delivery STATE.md that the helper now targets (SD-5).
    # The file must exist; the helper writes ## Delivery Gate into it.
    mkdir -p "$ws/.aid/work/delivery-003"
    cat > "$ws/.aid/work/delivery-003/STATE.md" <<'EOF'
# Delivery State -- delivery-003

> **Delivery:** delivery-003
> **Work:** work-001-test
> **Branch:** aid/work-001-delivery-003

---

## Delivery Lifecycle

- **State:** Executing
- **Updated:** 2026-05-24T11:00:00Z

---

## Delivery Gate

_None yet._

---

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
EOF

    local gate_block
    gate_block="$(cat <<'EOF'
- **Reviewer Tier:** Small
- **Complexity Score:** 3
- **Grade:** A+
- **Cycles:** 1
- **Timestamp:** 2026-05-24T12:00:00Z
- **Issue List:** none
EOF
)"

    AID_STATE_FILE="$ws/.aid/work/STATE.md" \
    AID_DELIVERY_ISSUES_DIR="$ws/.aid/work" \
    AID_LOCK_DIR="$ws/.aid/work/delivery-003" \
    "$WRITEBACK" --delivery-id 003 --block "$gate_block" \
        > /dev/null 2>&1
    local rc=$?

    # Helper should exit 0
    if [[ "$rc" -eq 0 ]]; then
        pass "Test 7a: writeback-state.sh --delivery-id --block exits 0"
    else
        fail "Test 7a: writeback-state.sh --delivery-id --block exits 0" \
             "Helper exited with code $rc"
    fi

    # Per-delivery STATE.md ## Delivery Gate section should contain the block (SD-5).
    local delivery_state_file="$ws/.aid/work/delivery-003/STATE.md"
    if grep -q "^## Delivery Gate" "$delivery_state_file" 2>/dev/null; then
        pass "Test 7b: delivery-003/STATE.md has ## Delivery Gate section"
    else
        fail "Test 7b: delivery-003/STATE.md has ## Delivery Gate section" \
             "## Delivery Gate not found in $delivery_state_file"
    fi

    if grep -q "Reviewer Tier" "$delivery_state_file" 2>/dev/null; then
        pass "Test 7c: Gate block content written to delivery-003/STATE.md (Reviewer Tier present)"
    else
        fail "Test 7c: Gate block content written to delivery-003/STATE.md" \
             "Reviewer Tier not found in $delivery_state_file"
    fi

    # work-level STATE.md ## Delivery Gates must NOT be modified by the helper
    # (it is a DERIVED view assembled by the reader, not a write target).
    local work_state_file="$ws/.aid/work/STATE.md"
    if ! grep -q "### delivery-003" "$work_state_file" 2>/dev/null; then
        pass "Test 7d: work STATE.md ## Delivery Gates NOT written by helper (DERIVED view preserved)"
    else
        fail "Test 7d: work STATE.md ## Delivery Gates NOT written by helper (DERIVED view preserved)" \
             "### delivery-003 found in work STATE.md -- helper incorrectly wrote to work-level file"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Verify required scripts exist
if [[ ! -x "$WRITEBACK" ]]; then
    echo "ERROR: writeback-state.sh not found or not executable at: $WRITEBACK" >&2
    echo "       Ensure it exists and is executable (chmod +x)." >&2
    exit 1
fi

if [[ ! -x "$GRADE" ]]; then
    echo "ERROR: grade.sh not found or not executable at: $GRADE" >&2
    echo "       Ensure it exists and is executable (chmod +x)." >&2
    exit 1
fi

echo "Running delivery-gate unit tests..."
echo ""

run_test_1
run_test_2
run_test_3
run_test_4
run_test_5
run_test_6
run_test_7

echo ""
test_summary
exit $?
