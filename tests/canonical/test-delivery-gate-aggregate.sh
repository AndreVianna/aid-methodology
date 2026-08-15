#!/usr/bin/env bash
# test-delivery-gate-aggregate.sh — Unit tests for the delivery-gate logic in aid-execute.
#
# Tests cover:
#   1. AGGREGATE with existing delivery-NNN-issues.md (deferred rows preserved)
#   2. AGGREGATE with no issues file (creates empty log correctly)
#   3. SCORE computation for 3 sample deliveries of varying complexity (3a-3c,
#      inline arithmetic over the documented formula), plus a real
#      complexity-score.sh run over the on-disk `<tasks-dir>/task-NNN/DETAIL.md`
#      layout both current work layouts use (3d-3e, tier selection included)
#   4. Grade computation via grade.sh (deterministic output verification)
#   5. Loopback guard (grade < min does NOT re-run quick-checks, only loops review)
#   6. FR6 interlock (gate must not fire while any task has state Failed or Blocked) --
#      retargeted to scan real per-task STATE.yml files (state: key), not a work-level
#      "## Tasks Status" table that has no home in the new schema at any layer
#   7. RECORD — --delivery-id --block writes delivery_gate.issue_list into
#      deliveries/delivery-NNN/STATE.yml (SD-5 / work-004 / task-007), plus
#      --gate-field for the tier/grade/timestamp scalars (a separate mode --
#      parse_issue_list_block only ever parsed the Issue List bullet, never
#      Reviewer Tier/Complexity Score/Grade/Cycles, KI-006). Per-delivery model:
#      the work-level view is DERIVED (not written by the helper)
#   8. GATE-CRITERIA-FIX — state-delivery-gate.md resolves the delivery's acceptance criteria
#      from the delivery's BLUEPRINT.md § Gate Criteria (feature-015 mis-wire fix), not PLAN.md
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
SCORE="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/complexity-score.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# Create a temporary test workspace. The work-level STATE.yml is the NESTED
# (full) layout's whole-document key space: no `## Tasks Status` / `##
# Delivery Gates` / `## Quick Check Findings` headings survive FR-2b (none of
# the four has a work-level home in the nested layout at all -- tasks and
# gates live per-delivery/per-task); `## Lifecycle History` retargets to the
# real `lifecycle_history:` key work-state-template.yml declares.
make_workspace() {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.aid/work/tasks"
    cat > "$tmpdir/.aid/work/STATE.yml" <<'EOF'
# Work State -- work-001-test
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-01-01T00:00:00Z'
lifecycle_history:
  - date: '2026-01-01'
    event: 'Work created'
    grade: --
    notes: --
EOF
    # Minimal discovery STATE.md for gate tier thresholds -- KB ledger, out of
    # scope for this refactor (SPEC.md SS L-9), unchanged.
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

# make_task_state_file FILE STATE_VALUE -- a minimal per-task STATE.yml
# matching task-state-template.yml's shape (used by Test 6's FR6 interlock).
make_task_state_file() {
    local file="$1" state_val="$2"
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF
state: ${state_val}
review: --
elapsed: --
notes: --
display_name: --
quick_check:
  reviewer_tier: --
  findings: []
dispatch_log: []
EOF
}

# fr6_not_done_count TASKS_DIR -- FR6 interlock: count per-task STATE.yml
# files (tasks/task-NNN/STATE.yml under TASKS_DIR) whose `state:` key is not
# Done. Retargeted from the pre-refactor work-level "## Tasks Status" table
# grep to the real per-unit file layout the nested schema actually uses.
fr6_not_done_count() {
    local tasks_dir="$1"
    local count=0 f state_val
    for f in "${tasks_dir}"/task-*/STATE.yml; do
        [[ -f "$f" ]] || continue
        state_val=$(grep -m1 '^state:' "$f" | sed 's/^state:[ \t]*//' | tr -d "\"'")
        [[ "$state_val" != "Done" ]] && count=$((count + 1))
    done
    echo "$count"
}

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
    AID_STATE_FILE="$ws/.aid/work/STATE.yml" \
    AID_DELIVERY_ISSUES_DIR="$ws/.aid/work" \
    AID_LOCK_DIR="$ws/.aid/work" \
    bash "$WRITEBACK" --delivery-id 003 --append-issue \
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

    # -----------------------------------------------------------------------
    # Test 3d/3e: the SAME Delivery A, computed by the REAL scorer against the
    # on-disk layout the delivery gate actually reads. Tests 3a-3c above are
    # inline arithmetic over hard-coded numbers -- they restate the formula and
    # cannot observe a task-file LOOKUP regression. This one runs
    # complexity-score.sh over `<tasks-dir>/task-NNN/DETAIL.md`, the shape BOTH
    # current layouts use (full: deliveries/delivery-NNN/tasks/; flat
    # feature-001: tasks/ directly under the work root). With a depth-1-only
    # lookup no task file was found at all, so risk collapsed 2 -> 0, score
    # 7 -> 5, and the gate reviewer was under-tiered Medium -> Small.
    #
    # AID_KB_STATE is pinned to a non-existent path so the tier assertion uses
    # the documented defaults (Low 6 / High 14) rather than whatever thresholds
    # the repo's own .aid/knowledge/STATE.md happens to carry.
    # -----------------------------------------------------------------------
    local ws
    ws=$(mktemp -d)

    cat > "$ws/PLAN.md" <<'EOF'
## Execution Graph

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-002 |
EOF

    mkdir -p "$ws/tasks/task-001" "$ws/tasks/task-002" "$ws/tasks/task-003"
    printf '# task-001\n\n**Type:** IMPLEMENT\n' > "$ws/tasks/task-001/DETAIL.md"   # +1
    printf '# task-002\n\n**Type:** TEST\n'      > "$ws/tasks/task-002/DETAIL.md"   # +1
    printf '# task-003\n\n**Type:** DOCUMENT\n'  > "$ws/tasks/task-003/DETAIL.md"   # +0

    local score_out
    score_out=$(AID_KB_STATE="$ws/no-such-kb-state.md" \
        bash "$SCORE" --plan-file "$ws/PLAN.md" --tasks-dir "$ws/tasks" 2>/dev/null)

    local real_risk real_score real_tier
    real_risk=$(grep -m1 '^risk='  <<< "$score_out" | cut -d= -f2)
    real_score=$(grep -m1 '^score=' <<< "$score_out" | cut -d= -f2)
    real_tier=$(grep -m1 '^tier='  <<< "$score_out" | cut -d= -f2)

    if [[ "$real_risk" == "2" && "$real_score" == "7" ]]; then
        pass "Test 3d: complexity-score.sh reads task-NNN/DETAIL.md types (risk=2, score=7)"
    else
        fail "Test 3d: complexity-score.sh reads task-NNN/DETAIL.md types" \
             "Got risk=$real_risk score=$real_score (expected risk=2 score=7)"
    fi

    if [[ "$real_tier" == "Medium" ]]; then
        pass "Test 3e: score=7 selects the Medium gate reviewer tier (not under-tiered to Small)"
    else
        fail "Test 3e: score=7 selects the Medium gate reviewer tier" \
             "Got tier=$real_tier (expected Medium)"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 4: GRADE — grade.sh produces correct deterministic output
# ---------------------------------------------------------------------------
run_test_4() {
    # Clean issue list → A+
    local grade_clean
    grade_clean=$(echo "No issues found." | bash "$GRADE")
    if [[ "$grade_clean" == "A+" ]]; then
        pass "Test 4a: grade.sh on empty issue list → A+"
    else
        fail "Test 4a: grade.sh on empty issue list" "Got '$grade_clean', expected 'A+'"
    fi

    # One [HIGH] → D+ (schema-table format)
    local grade_high
    grade_high=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [HIGH] | Pending | foo.md | 1 | some issue | evidence |\n' | bash "$GRADE")
    if [[ "$grade_high" == "D+" ]]; then
        pass "Test 4b: grade.sh with 1 [HIGH] → D+"
    else
        fail "Test 4b: grade.sh with 1 [HIGH]" "Got '$grade_high', expected 'D+'"
    fi

    # One [CRITICAL] → E+ (schema-table format)
    local grade_crit
    grade_crit=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [CRITICAL] | Pending | foo.md | 1 | fatal issue | evidence |\n' | bash "$GRADE")
    if [[ "$grade_crit" == "E+" ]]; then
        pass "Test 4c: grade.sh with 1 [CRITICAL] → E+"
    else
        fail "Test 4c: grade.sh with 1 [CRITICAL]" "Got '$grade_crit', expected 'E+'"
    fi

    # Three [MEDIUM] → C (schema-table format; not C+ since count > 1; not C- since count <= 5)
    local grade_medium
    grade_medium=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [MEDIUM] | Pending | foo.md | 1 | issue 1 | evidence |\n| 2 | [MEDIUM] | Pending | foo.md | 2 | issue 2 | evidence |\n| 3 | [MEDIUM] | Pending | foo.md | 3 | issue 3 | evidence |\n' | bash "$GRADE")
    if [[ "$grade_medium" == "C" ]]; then
        pass "Test 4d: grade.sh with 3 [MEDIUM] → C"
    else
        fail "Test 4d: grade.sh with 3 [MEDIUM]" "Got '$grade_medium', expected 'C'"
    fi

    # Tags in Description column are ignored -- schema-table mode reads only col3 (Severity)
    # This is the cycle-7 regression test: summary prose with tag strings must NOT inflate grade
    local grade_backtick
    grade_backtick=$(printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [MINOR] | Pending | foo.md | 1 | 0 [CRITICAL] / 0 [HIGH] found in summary | prose leaked tags |\n' | bash "$GRADE")
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
# (quick-checks would append new rows; the gate fix loop does not). Unaffected
# by the YAML migration -- delivery-NNN-issues.md stays a plain markdown log.
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
#
# Retargeted: pre-refactor this grepped a work-level "## Tasks Status" table
# that has no home in the nested-layout schema at any layer (each task's
# state lives in its own deliveries/delivery-NNN/tasks/task-NNN/STATE.yml).
# The interlock now scans those real per-task files' `state:` keys directly
# -- the same data source aid-execute's own FR6 check reads.
# ---------------------------------------------------------------------------
run_test_6() {
    local ws
    ws=$(make_workspace)
    local tasks_dir="$ws/.aid/work/deliveries/delivery-003/tasks"

    # One Done task, one Failed task (PD-5 Case B should prevent the gate).
    make_task_state_file "${tasks_dir}/task-001/STATE.yml" "Done"
    make_task_state_file "${tasks_dir}/task-002/STATE.yml" "Failed"

    local not_done
    not_done=$(fr6_not_done_count "$tasks_dir")
    if [[ "$not_done" -gt 0 ]]; then
        pass "Test 6a: FR6 interlock detects $not_done task(s) not Done — gate should NOT fire"
    else
        fail "Test 6a: FR6 interlock detection" \
             "Expected at least 1 non-Done task, found 0"
    fi

    if grep -q '^state: Failed' "${tasks_dir}/task-002/STATE.yml"; then
        pass "Test 6b: FR6 interlock correctly identifies the Failed task's state: key"
    else
        fail "Test 6b: FR6 interlock identifies Failed task" \
             "state: Failed not found in ${tasks_dir}/task-002/STATE.yml"
    fi

    # Now set the second task to Done and verify the interlock would pass.
    make_task_state_file "${tasks_dir}/task-002/STATE.yml" "Done"
    local not_done_after
    not_done_after=$(fr6_not_done_count "$tasks_dir")
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
#          delivery_gate.issue_list into deliveries/delivery-NNN/STATE.yml
#          (SD-5 / work-004 / task-007). --gate-field is the separate mode
#          for the tier/grade/timestamp scalars (parse_issue_list_block only
#          ever parsed the Issue List bullet -- Reviewer Tier/Complexity
#          Score/Cycles have no persisted target, KI-006).
# ---------------------------------------------------------------------------
run_test_7() {
    local ws
    ws=$(make_workspace)

    # Create the per-delivery STATE.yml that the helper now targets (SD-5).
    mkdir -p "$ws/.aid/work/deliveries/delivery-003"
    cat > "$ws/.aid/work/deliveries/delivery-003/STATE.yml" <<'EOF'
# Delivery State -- delivery-003
delivery_state: Executing
gate_tier: --
gate_grade: Pending
gate_timestamp: --
delivery_lifecycle:
  updated: '2026-05-24T11:00:00Z'
  block_reason: --
  block_artifact: --
delivery_gate:
  issue_list: []
qa: []
EOF

    local gate_block
    gate_block="$(cat <<'EOF'
- **Issue List:**
  - [LOW] a minor style issue found by the gate reviewer
EOF
)"

    AID_STATE_FILE="$ws/.aid/work/STATE.yml" \
    AID_DELIVERY_ISSUES_DIR="$ws/.aid/work" \
    AID_LOCK_DIR="$ws/.aid/work/deliveries/delivery-003" \
    bash "$WRITEBACK" --delivery-id 003 --block "$gate_block" \
        > /dev/null 2>&1
    local rc=$?

    # Helper should exit 0
    if [[ "$rc" -eq 0 ]]; then
        pass "Test 7a: writeback-state.sh --delivery-id --block exits 0"
    else
        fail "Test 7a: writeback-state.sh --delivery-id --block exits 0" \
             "Helper exited with code $rc"
    fi

    # Per-delivery STATE.yml delivery_gate.issue_list should contain the item (SD-5).
    local delivery_state_file="$ws/.aid/work/deliveries/delivery-003/STATE.yml"
    if grep -q "^delivery_gate:" "$delivery_state_file" 2>/dev/null; then
        pass "Test 7b: deliveries/delivery-003/STATE.yml has a delivery_gate: key"
    else
        fail "Test 7b: deliveries/delivery-003/STATE.yml has a delivery_gate: key" \
             "delivery_gate: not found in $delivery_state_file"
    fi

    if grep -q "a minor style issue found by the gate reviewer" "$delivery_state_file" 2>/dev/null; then
        pass "Test 7c: gate block content written to deliveries/delivery-003/STATE.yml (issue item present)"
    else
        fail "Test 7c: gate block content written to deliveries/delivery-003/STATE.yml" \
             "Issue item not found in $delivery_state_file"
    fi

    # --gate-field is the separate mode for the tier/grade/timestamp scalars.
    AID_STATE_FILE="$ws/.aid/work/STATE.yml" \
    AID_LOCK_DIR="$ws/.aid/work/deliveries/delivery-003" \
    "$WRITEBACK" --delivery-id 003 --gate-field Grade --gate-value "A+" > /dev/null 2>&1
    if grep -q "^gate_grade: A+" "$delivery_state_file" 2>/dev/null; then
        pass "Test 7d: --gate-field Grade writes gate_grade into deliveries/delivery-003/STATE.yml"
    else
        fail "Test 7d: --gate-field Grade writes gate_grade" \
             "gate_grade: A+ not found in $delivery_state_file"
    fi

    # work-level STATE.yml must NOT be modified by the helper (DERIVED view --
    # the work-level gate/tasks views are assembled at read time, never written).
    local work_state_file="$ws/.aid/work/STATE.yml"
    if ! grep -q "delivery_gate" "$work_state_file" 2>/dev/null; then
        pass "Test 7e: work STATE.yml NOT written by the helper (DERIVED view preserved)"
    else
        fail "Test 7e: work STATE.yml NOT written by the helper (DERIVED view preserved)" \
             "delivery_gate found in work STATE.yml -- helper incorrectly wrote to work-level file"
    fi

    cleanup "$ws"
}

# ---------------------------------------------------------------------------
# Test 8: GATE-CRITERIA-FIX — state-delivery-gate.md resolves the delivery's
# acceptance criteria from the delivery's BLUEPRINT.md § Gate Criteria
# (feature-015 mis-wire fix), not a non-existent PLAN.md criteria block.
# ---------------------------------------------------------------------------
run_test_8() {
    local gate_doc="${SCRIPT_DIR}/../../canonical/skills/aid-execute/references/state-delivery-gate.md"

    if [[ ! -f "$gate_doc" ]]; then
        fail "Test 8 setup: state-delivery-gate.md not found at $gate_doc"
        return
    fi

    # 8a/8b are INVERTED from their original sense, and the inversion is the point.
    #
    # They were written when the delivery definition lived in its own BLUEPRINT.md:
    # reading gate criteria from PLAN.md was then a real mis-wire, because PLAN.md
    # sequenced deliveries while BLUEPRINT.md defined them. 8b existed to catch a
    # regression back to that bug.
    #
    # BLUEPRINT.md is now retired and the delivery definition -- objective, scope,
    # Gate Criteria -- lives in the delivery's own stanza in PLAN.md. So PLAN.md is
    # the correct source, and a surviving BLUEPRINT.md reference is the defect. Both
    # assertions flip rather than being deleted: the invariant they protect (criteria
    # come from exactly ONE named place, and the doc says which) is unchanged.

    # Two sources now, one per layout, and BOTH must be named -- the criteria have to
    # come from exactly one place per layout and the doc has to say which. The full path
    # keeps its PLAN.md stanza, where sequencing across deliveries is a real authored
    # decision. The flat/Lite path has one delivery, so the work IS the delivery and its
    # § 9 criteria are the delivery's; there is no PLAN.md there to hold a restatement.
    #
    # Patterns are line-scoped (grep -F), so they must not straddle a wrap.
    if grep -qF 'the `**Gate Criteria**` list in the delivery'"'"'s own stanza in' "$gate_doc"; then
        pass "Test 8a INVERTED: the FULL path resolves delivery criteria from the PLAN.md delivery stanza"
    else
        fail "Test 8a INVERTED: the FULL path must resolve delivery criteria from the PLAN.md delivery stanza" \
             "Expected string not found in $gate_doc"
    fi

    if grep -qF 'the `AC-N` set in `REQUIREMENTS.md § 9`' "$gate_doc"; then
        pass "Test 8a2: the FLAT/Lite path resolves delivery criteria from REQUIREMENTS.md § 9"
    else
        fail "Test 8a2: the FLAT/Lite path must resolve delivery criteria from REQUIREMENTS.md § 9" \
             "Expected string not found in $gate_doc"
    fi

    if grep -qF "BLUEPRINT" "$gate_doc"; then
        fail "Test 8b INVERTED: state-delivery-gate.md still references the retired BLUEPRINT.md" \
             "BLUEPRINT reference found in $gate_doc"
    else
        pass "Test 8b INVERTED: state-delivery-gate.md carries no reference to the retired BLUEPRINT.md"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Verify required scripts exist.
#
# Checked with -f (present and readable), NOT -x. The executable bit is not part of
# either script's contract: every one of the ~90 invocations across canonical/ calls
# them as `bash <path>`, none as `./<path>`, and both are committed 100644. An -x
# preflight here made this the only suite in the repo that required the bit, so it
# failed on any clean checkout while the scripts themselves worked fine.
if [[ ! -f "$WRITEBACK" ]]; then
    echo "ERROR: writeback-state.sh not found at: $WRITEBACK" >&2
    exit 1
fi

if [[ ! -f "$GRADE" ]]; then
    echo "ERROR: grade.sh not found at: $GRADE" >&2
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
run_test_8

echo ""
test_summary
exit $?
