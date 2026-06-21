#!/usr/bin/env bash
# test-housekeep-state.sh — unit suite for canonical/scripts/housekeep/housekeep-state.sh
#
# Tests:
#   Unit 1:  --read on a file with no ## Housekeep Status section → empty, exit 0
#   Unit 2:  --write creates the section and the field line
#   Unit 3:  --read retrieves a written field verbatim
#   Unit 4:  --write is idempotent (second write replaces, no duplicate)
#   Unit 5:  --write updates a different field, both fields co-exist
#   Unit 6:  All nine C-2 fields round-trip write → read correctly
#   Unit 7:  --resume row 1 — no section, no --cleanup-only → PREFLIGHT
#   Unit 8:  --resume row 2 — no section, --cleanup-only → CLEANUP
#   Unit 9:  --resume row 3 — KB Stage = stalled → KB-DELTA
#   Unit 10: --resume row 3 — KB Stage = running → KB-DELTA
#   Unit 11: --resume row 3 — KB Stage = — → KB-DELTA
#   Unit 12: --resume row 4 — KB passed, Summary = stalled → SUMMARY-DELTA
#   Unit 13: --resume row 4 — KB skipped, Summary = — → SUMMARY-DELTA
#   Unit 14: --resume row 5 — KB+Summary passed, Cleanup = — → CLEANUP
#   Unit 15: --resume row 5 — KB+Summary skipped, Cleanup = stalled → CLEANUP
#   Unit 16: --resume row 6 — all passed/skipped, State = DONE → DONE
#   Unit 17: error paths — missing --state → exit 2
#   Unit 18: error paths — missing --field with --read → exit 2
#   Unit 19: error paths — STATE.md file not found → exit 1
#   Unit 20: error paths — missing --value with --write → exit 2
#
# Usage:
#   test-housekeep-state.sh [-v | --verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/housekeep/housekeep-state.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Setup: create a temporary workspace; cleanup on exit
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Helper: create a fresh STATE.md fixture with NO ## Housekeep Status section
make_state() {
    local path="$1"
    cat > "$path" <<'EOF'
# Work State — work-test

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001-alpha | IMPLEMENT | 1 | Pending | — | — | — |

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-02 | Work created | — | Initial scaffold |
EOF
}

# Helper: create a STATE.md fixture WITH a ## Housekeep Status section,
# setting named fields. Accepts field=value pairs as args.
# Usage: make_state_with_fields PATH field1 value1 field2 value2 ...
make_state_with_fields() {
    local path="$1"; shift
    make_state "$path"
    # Append the section
    {
        echo ""
        echo "## Housekeep Status"
        echo ""
        while [[ $# -ge 2 ]]; do
            local f="$1" v="$2"; shift 2
            echo "**${f}:** ${v}"
        done
    } >> "$path"
}

# ---------------------------------------------------------------------------
echo "--- Unit 1: --read on file with no section returns empty, exit 0"
STATE1="${TMPDIR_BASE}/state1.md"
make_state "$STATE1"
out=$(bash "$SUT" --state "$STATE1" --read --field "State")
rc=$?
assert_exit_zero "$rc" "T01 read missing section exit 0"
assert_eq "$out" "" "T01 read missing section value is empty"

# ---------------------------------------------------------------------------
echo "--- Unit 2: --write creates section + field line"
STATE2="${TMPDIR_BASE}/state2.md"
make_state "$STATE2"
out=$(bash "$SUT" --state "$STATE2" --write --field "State" --value "KB-DELTA")
rc=$?
assert_exit_zero "$rc" "T02 write creates section exit 0"
assert_file_contains "$STATE2" "## Housekeep Status" "T02 section heading present"
assert_file_contains "$STATE2" "**State:** KB-DELTA" "T02 field line present"

# ---------------------------------------------------------------------------
echo "--- Unit 3: --read retrieves written field verbatim"
val=$(bash "$SUT" --state "$STATE2" --read --field "State")
assert_eq "$val" "KB-DELTA" "T03 read retrieves written value"

# ---------------------------------------------------------------------------
echo "--- Unit 4: --write is idempotent (replace, no duplicate)"
bash "$SUT" --state "$STATE2" --write --field "State" --value "SUMMARY-DELTA" > /dev/null
count=$(grep -c "^\*\*State:\*\*" "$STATE2" || true)
assert_eq "$count" "1" "T04 no duplicate field lines after second write"
val=$(bash "$SUT" --state "$STATE2" --read --field "State")
assert_eq "$val" "SUMMARY-DELTA" "T04 second write replaced the value"

# ---------------------------------------------------------------------------
echo "--- Unit 5: multiple fields co-exist"
bash "$SUT" --state "$STATE2" --write --field "Stage Status" --value "running" > /dev/null
bash "$SUT" --state "$STATE2" --write --field "Mode" --value "full" > /dev/null
val_state=$(bash "$SUT" --state "$STATE2" --read --field "State")
val_stage=$(bash "$SUT" --state "$STATE2" --read --field "Stage Status")
val_mode=$(bash "$SUT" --state "$STATE2" --read --field "Mode")
assert_eq "$val_state" "SUMMARY-DELTA" "T05 State field survives additional writes"
assert_eq "$val_stage" "running" "T05 Stage Status field"
assert_eq "$val_mode" "full" "T05 Mode field"

# ---------------------------------------------------------------------------
echo "--- Unit 6: all nine C-2 fields round-trip"
STATE6="${TMPDIR_BASE}/state6.md"
make_state "$STATE6"

declare -A NINE_FIELDS=(
    ["State"]="KB-DELTA"
    ["Stage Status"]="stalled"
    ["Branch"]="aid/housekeep-2026-06-02"
    ["Mode"]="full"
    ["Stall Reason"]="KB approval declined"
    ["Last Run"]="2026-06-02T10:00:00Z"
    ["KB Stage"]="stalled"
    ["Summary Stage"]="—"
    ["Cleanup Stage"]="—"
)

for field in "State" "Stage Status" "Branch" "Mode" "Stall Reason" "Last Run" "KB Stage" "Summary Stage" "Cleanup Stage"; do
    expected="${NINE_FIELDS[$field]}"
    bash "$SUT" --state "$STATE6" --write --field "$field" --value "$expected" > /dev/null
done

for field in "State" "Stage Status" "Branch" "Mode" "Stall Reason" "Last Run" "KB Stage" "Summary Stage" "Cleanup Stage"; do
    expected="${NINE_FIELDS[$field]}"
    actual=$(bash "$SUT" --state "$STATE6" --read --field "$field")
    assert_eq "$actual" "$expected" "T06 round-trip: $field"
done

# ---------------------------------------------------------------------------
echo "--- Unit 7: --resume row 1 — no section, no --cleanup-only → PREFLIGHT"
STATE7="${TMPDIR_BASE}/state7.md"
make_state "$STATE7"
target=$(bash "$SUT" --state "$STATE7" --resume)
rc=$?
assert_exit_zero "$rc" "T07 resume row1 exit 0"
assert_eq "$target" "PREFLIGHT" "T07 resume row1 result"

# ---------------------------------------------------------------------------
echo "--- Unit 8: --resume row 2 — no section, --cleanup-only → CLEANUP"
STATE8="${TMPDIR_BASE}/state8.md"
make_state "$STATE8"
target=$(bash "$SUT" --state "$STATE8" --resume --cleanup-only)
rc=$?
assert_exit_zero "$rc" "T08 resume row2 exit 0"
assert_eq "$target" "CLEANUP" "T08 resume row2 result"

# ---------------------------------------------------------------------------
echo "--- Unit 9: --resume row 3 — KB Stage = stalled → KB-DELTA"
STATE9="${TMPDIR_BASE}/state9.md"
make_state_with_fields "$STATE9" "KB Stage" "stalled" "Summary Stage" "—" "Cleanup Stage" "—" "State" "KB-DELTA"
target=$(bash "$SUT" --state "$STATE9" --resume)
rc=$?
assert_exit_zero "$rc" "T09 resume row3 stalled exit 0"
assert_eq "$target" "KB-DELTA" "T09 resume row3 stalled result"

# ---------------------------------------------------------------------------
echo "--- Unit 10: --resume row 3 — KB Stage = running → KB-DELTA"
STATE10="${TMPDIR_BASE}/state10.md"
make_state_with_fields "$STATE10" "KB Stage" "running" "Summary Stage" "—" "Cleanup Stage" "—" "State" "KB-DELTA"
target=$(bash "$SUT" --state "$STATE10" --resume)
assert_eq "$target" "KB-DELTA" "T10 resume row3 running"

# ---------------------------------------------------------------------------
echo "--- Unit 11: --resume row 3 — KB Stage = — → KB-DELTA"
STATE11="${TMPDIR_BASE}/state11.md"
make_state_with_fields "$STATE11" "KB Stage" "—" "Summary Stage" "—" "Cleanup Stage" "—" "State" "KB-DELTA"
target=$(bash "$SUT" --state "$STATE11" --resume)
assert_eq "$target" "KB-DELTA" "T11 resume row3 dash"

# ---------------------------------------------------------------------------
echo "--- Unit 12: --resume row 4 — KB passed, Summary = stalled → SUMMARY-DELTA"
STATE12="${TMPDIR_BASE}/state12.md"
make_state_with_fields "$STATE12" "KB Stage" "passed" "Summary Stage" "stalled" "Cleanup Stage" "—" "State" "SUMMARY-DELTA"
target=$(bash "$SUT" --state "$STATE12" --resume)
assert_eq "$target" "SUMMARY-DELTA" "T12 resume row4 stalled"

# ---------------------------------------------------------------------------
echo "--- Unit 13: --resume row 4 — KB skipped, Summary = — → SUMMARY-DELTA"
STATE13="${TMPDIR_BASE}/state13.md"
make_state_with_fields "$STATE13" "KB Stage" "skipped" "Summary Stage" "—" "Cleanup Stage" "—" "State" "SUMMARY-DELTA"
target=$(bash "$SUT" --state "$STATE13" --resume)
assert_eq "$target" "SUMMARY-DELTA" "T13 resume row4 skipped+dash"

# ---------------------------------------------------------------------------
echo "--- Unit 14: --resume row 5 — KB+Summary passed, Cleanup = — → CLEANUP"
STATE14="${TMPDIR_BASE}/state14.md"
make_state_with_fields "$STATE14" "KB Stage" "passed" "Summary Stage" "passed" "Cleanup Stage" "—" "State" "CLEANUP"
target=$(bash "$SUT" --state "$STATE14" --resume)
assert_eq "$target" "CLEANUP" "T14 resume row5 cleanup dash"

# ---------------------------------------------------------------------------
echo "--- Unit 15: --resume row 5 — KB+Summary skipped, Cleanup = stalled → CLEANUP"
STATE15="${TMPDIR_BASE}/state15.md"
make_state_with_fields "$STATE15" "KB Stage" "skipped" "Summary Stage" "skipped" "Cleanup Stage" "stalled" "State" "CLEANUP"
target=$(bash "$SUT" --state "$STATE15" --resume)
assert_eq "$target" "CLEANUP" "T15 resume row5 cleanup stalled"

# ---------------------------------------------------------------------------
echo "--- Unit 16: --resume row 6 — all passed/skipped, State = DONE → DONE"
STATE16="${TMPDIR_BASE}/state16.md"
make_state_with_fields "$STATE16" "KB Stage" "passed" "Summary Stage" "passed" "Cleanup Stage" "passed" "State" "DONE"
target=$(bash "$SUT" --state "$STATE16" --resume)
rc=$?
assert_exit_zero "$rc" "T16 resume row6 exit 0"
assert_eq "$target" "DONE" "T16 resume row6 result"

# ---------------------------------------------------------------------------
echo "--- Unit 17: error — missing --state → exit 2"
out=$(bash "$SUT" --read --field "State" 2>&1) || rc=$?
assert_exit_eq "${rc:-0}" 2 "T17 missing --state exit 2"

# ---------------------------------------------------------------------------
echo "--- Unit 18: error — missing --field with --read → exit 2"
DUMMY_STATE="${TMPDIR_BASE}/dummy.md"
make_state "$DUMMY_STATE"
out=$(bash "$SUT" --state "$DUMMY_STATE" --read 2>&1) || rc=$?
assert_exit_eq "${rc:-0}" 2 "T18 missing --field exit 2"

# ---------------------------------------------------------------------------
echo "--- Unit 19: absent run-state file is tolerated (project-level .temp file may not exist yet)"
# --read on an absent file → empty value, exit 0 (fresh-run friendly).
rc=0
out=$(bash "$SUT" --state "/nonexistent/path/STATE.md" --read --field "State" 2>&1) || rc=$?
assert_exit_eq "${rc:-0}" 0 "T19a read absent file exit 0"
assert_eq "$out" "" "T19b read absent file prints empty"
# --resume on an absent file → PREFLIGHT (row 1) / CLEANUP with --cleanup-only (row 2).
rc=0
out=$(bash "$SUT" --state "/nonexistent/path/STATE.md" --resume 2>&1) || rc=$?
assert_exit_eq "${rc:-0}" 0 "T19c resume absent file exit 0"
assert_eq "$out" "PREFLIGHT" "T19d resume absent file → PREFLIGHT"
# --write on an absent file → creates it (+ parent dir) and writes the field.
T19_DIR=$(mktemp -d)
T19_SF="$T19_DIR/.aid/.temp/HOUSEKEEP_STATE_209901010000.md"
rc=0
bash "$SUT" --state "$T19_SF" --write --field "State" --value "KB-DELTA" >/dev/null 2>&1 || rc=$?
assert_exit_eq "${rc:-0}" 0 "T19e write creates absent file exit 0"
assert_eq "$(bash "$SUT" --state "$T19_SF" --read --field "State")" "KB-DELTA" "T19f created file round-trips"
rm -rf "$T19_DIR"

# ---------------------------------------------------------------------------
echo "--- Unit 20: error — missing --value with --write → exit 2"
STATE20="${TMPDIR_BASE}/state20.md"
make_state "$STATE20"
out=$(bash "$SUT" --state "$STATE20" --write --field "State" 2>&1) || rc=$?
assert_exit_eq "${rc:-0}" 2 "T20 missing --value exit 2"

# ---------------------------------------------------------------------------
test_summary
