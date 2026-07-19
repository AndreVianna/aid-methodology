#!/usr/bin/env bash
# test-write-control-signal.sh -- unit tests for
# canonical/aid/scripts/execute/write-control-signal.sh (feature-008-execution-control,
# work-017 task-028): the cooperative task-level stop/resume signal writer.
#
# Tests cover:
#   U1   stop happy path -- control dir + task-NNN.stop created, exit 0
#   U2   stop content line format -- "[ISO-8601 UTC] stop | source=dashboard"
#   U3   stop idempotent -- re-stop exits 0, file still present (refreshed)
#   U4   resume happy path -- file removed, exit 0
#   U5   resume idempotent -- resuming with no file present exits 0, no error
#   U6   resume when the control dir itself was never created -- exit 0
#   U7   invalid --task-id (non-numeric) -> exit 4
#   U8   invalid --task-id (4+ digits) -> exit 4
#   U9   empty-string --task-id value treated as missing -> exit 5
#   U10  --task-id zero-padding -- "7" -> task-007.stop
#   U11  octal footgun -- "008" -> task-008.stop (base-10, not misread as octal)
#   U12  octal footgun -- "090" -> task-090.stop
#   U13  invalid --action -> exit 4
#   U14  missing --task-id -> exit 5
#   U15  missing --action -> exit 5
#   U16  --task-id given with no value -> exit 5
#   U17  --action given with no value -> exit 5
#   U18  no arguments at all -> exit 5
#   U19  unknown flag -> exit 5
#   U20  -h/--help -> exit 0, usage printed
#   U21  control dir derives from AID_WORK_DIR, NOT cwd (WT-1)
#   U22  AID_WORK_DIR unset -> falls back to cwd
#   U23  work_id = AID_WORK_DIR's own basename (not a client-supplied string)
#   U24  path-traversal attempt in --task-id is rejected (exit 4); nothing written
#        outside .aid/.control -- SEC-3
#   U25  atomicity -- no stray temp file left in the control dir after stop
#   U26  isolation -- stop/resume never touch STATE.md (byte-unchanged)
#   U27  isolation -- stop/resume never touch other tracked work-folder contents
#   U28  isolation -- stop/resume never invoke git (PATH-shadowed git stub untouched)
#   U29  IO failure -- mkdir -p blocked by a same-named regular file -> exit 2
#   U30  isolation -- stopping one task's signal never disturbs a sibling task's
#        signal file (per-task-token filenames)
#   U31  dashboard co-vendored copy is byte-identical to canonical and behaves
#        identically on a basic stop/resume round trip
#
# Usage:
#   bash tests/canonical/test-write-control-signal.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/write-control-signal.sh"
SUT_DASHBOARD="${SCRIPT_DIR}/../../dashboard/scripts/write-control-signal.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# make_work_dir BASE WORK_ID -> creates BASE/repo/.aid/works/WORK_ID and echoes its path.
make_work_dir() {
    local base="$1" work_id="$2"
    local wd="${base}/repo/.aid/works/${work_id}"
    mkdir -p "$wd"
    echo "$wd"
}

# control_file_for WORK_DIR TASK_TOKEN -> echoes the expected signal-file path.
control_file_for() {
    local work_dir="$1" task_token="$2"
    echo "${work_dir}/../../.control/$(basename "$work_dir")/${task_token}.stop"
}

echo "== write-control-signal.sh tests =="

# ---------------------------------------------------------------------------
# U1/U2 -- stop happy path + content line format
# ---------------------------------------------------------------------------
wd=$(make_work_dir "$TMPDIR_BASE/u1" "work-001-demo")
sig=$(control_file_for "$wd" "task-007")
out=$(AID_WORK_DIR="$wd" bash "$SUT" --task-id 7 --action stop 2>&1)
ec=$?
assert_exit_zero "$ec" "U1 stop exits 0"
assert_file_exists "$sig" "U1 signal file created at expected path"
assert_output_contains "$out" "OK:" "U1 stdout carries an OK: trace line"
assert_file_contains "$sig" "] stop | source=dashboard" "U2 content line format"
if grep -qE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] stop \| source=dashboard$' "$sig"; then
    pass "U2b content line matches ISO-8601 UTC timestamp pattern exactly"
else
    fail "U2b content line does not match ISO-8601 UTC pattern: $(cat "$sig")"
fi

# ---------------------------------------------------------------------------
# U3 -- stop idempotent (re-stop is a no-op success, file refreshed)
# ---------------------------------------------------------------------------
sleep 1
out2=$(AID_WORK_DIR="$wd" bash "$SUT" --task-id 7 --action stop 2>&1)
ec=$?
assert_exit_zero "$ec" "U3 re-stop exits 0 (idempotent)"
assert_file_exists "$sig" "U3 signal file still present after re-stop"

# ---------------------------------------------------------------------------
# U4 -- resume happy path
# ---------------------------------------------------------------------------
out=$(AID_WORK_DIR="$wd" bash "$SUT" --task-id 7 --action resume 2>&1)
ec=$?
assert_exit_zero "$ec" "U4 resume exits 0"
if [[ ! -f "$sig" ]]; then pass "U4b signal file removed"; else fail "U4b signal file still present after resume"; fi
assert_output_contains "$out" "OK:" "U4c stdout carries an OK: trace line"

# ---------------------------------------------------------------------------
# U5 -- resume idempotent (already absent -> exit 0, no error)
# ---------------------------------------------------------------------------
out=$(AID_WORK_DIR="$wd" bash "$SUT" --task-id 7 --action resume 2>&1)
ec=$?
assert_exit_zero "$ec" "U5 resume-when-absent exits 0 (idempotent)"

# ---------------------------------------------------------------------------
# U6 -- resume when the control dir itself was never created
# ---------------------------------------------------------------------------
wd6=$(make_work_dir "$TMPDIR_BASE/u6" "work-006-demo")
out=$(AID_WORK_DIR="$wd6" bash "$SUT" --task-id 3 --action resume 2>&1)
ec=$?
assert_exit_zero "$ec" "U6 resume with no control dir at all exits 0"

# ---------------------------------------------------------------------------
# U7/U8/U9 -- invalid --task-id values
# ---------------------------------------------------------------------------
wd7=$(make_work_dir "$TMPDIR_BASE/u7" "work-007-demo")
ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id abc --action stop >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 4 "U7 non-numeric --task-id exits 4"

ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id 1234 --action stop >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 4 "U8 4-digit --task-id exits 4"

ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id "" --action stop >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U9 empty-string --task-id treated as missing -> exit 5"

# ---------------------------------------------------------------------------
# U10/U11/U12 -- zero-padding + octal footgun
# ---------------------------------------------------------------------------
wd10=$(make_work_dir "$TMPDIR_BASE/u10" "work-010-demo")
AID_WORK_DIR="$wd10" bash "$SUT" --task-id 7 --action stop >/dev/null 2>&1
assert_file_exists "$(control_file_for "$wd10" "task-007")" "U10 task-id '7' pads to task-007"

wd11=$(make_work_dir "$TMPDIR_BASE/u11" "work-011-demo")
ec=0
AID_WORK_DIR="$wd11" bash "$SUT" --task-id 008 --action stop >/dev/null 2>&1 || ec=$?
assert_exit_zero "$ec" "U11 task-id '008' is accepted (not misread as invalid octal)"
assert_file_exists "$(control_file_for "$wd11" "task-008")" "U11b '008' -> task-008.stop"

wd12=$(make_work_dir "$TMPDIR_BASE/u12" "work-012-demo")
ec=0
AID_WORK_DIR="$wd12" bash "$SUT" --task-id 090 --action stop >/dev/null 2>&1 || ec=$?
assert_exit_zero "$ec" "U12 task-id '090' is accepted (base-10, not octal)"
assert_file_exists "$(control_file_for "$wd12" "task-090")" "U12b '090' -> task-090.stop"

# ---------------------------------------------------------------------------
# U13 -- invalid --action
# ---------------------------------------------------------------------------
ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id 7 --action pause >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 4 "U13 invalid --action exits 4"

# ---------------------------------------------------------------------------
# U14/U15 -- missing required arguments
# ---------------------------------------------------------------------------
ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --action stop >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U14 missing --task-id exits 5"

ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id 7 >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U15 missing --action exits 5"

# ---------------------------------------------------------------------------
# U16/U17 -- flag given with no trailing value
# ---------------------------------------------------------------------------
ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U16 --task-id with no value exits 5"

ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --action >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U17 --action with no value exits 5"

# ---------------------------------------------------------------------------
# U18 -- no arguments at all
# ---------------------------------------------------------------------------
ec=0
bash "$SUT" >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U18 no arguments exits 5"

# ---------------------------------------------------------------------------
# U19 -- unknown flag
# ---------------------------------------------------------------------------
ec=0
AID_WORK_DIR="$wd7" bash "$SUT" --task-id 7 --action stop --bogus x >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 5 "U19 unknown flag exits 5"

# ---------------------------------------------------------------------------
# U20 -- -h/--help
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --help 2>&1)
ec=$?
assert_exit_zero "$ec" "U20 --help exits 0"
assert_output_contains "$out" "write-control-signal.sh" "U20b usage mentions the script name"
assert_output_contains "$out" "stop|resume" "U20c usage documents the action enum"

# ---------------------------------------------------------------------------
# U21 -- control dir derives from AID_WORK_DIR, NOT cwd (WT-1)
# ---------------------------------------------------------------------------
wd21=$(make_work_dir "$TMPDIR_BASE/u21" "work-021-demo")
otherdir="${TMPDIR_BASE}/u21/elsewhere"
mkdir -p "$otherdir"
( cd "$otherdir" && AID_WORK_DIR="$wd21" bash "$SUT" --task-id 5 --action stop >/dev/null 2>&1 )
assert_file_exists "$(control_file_for "$wd21" "task-005")" "U21 signal lands under AID_WORK_DIR, not cwd"
[[ ! -d "${otherdir}/.aid" ]] && pass "U21b no .aid/ materialized under the unrelated cwd" || fail "U21b unexpected .aid/ under cwd"

# ---------------------------------------------------------------------------
# U22 -- AID_WORK_DIR unset -> falls back to cwd
# ---------------------------------------------------------------------------
wd22=$(make_work_dir "$TMPDIR_BASE/u22" "work-022-demo")
( cd "$wd22" && unset AID_WORK_DIR; bash "$SUT" --task-id 9 --action stop >/dev/null 2>&1 )
assert_file_exists "$(control_file_for "$wd22" "task-009")" "U22 falls back to \$PWD when AID_WORK_DIR is unset"

# ---------------------------------------------------------------------------
# U23 -- work_id is AID_WORK_DIR's own basename, not any client-supplied string
# ---------------------------------------------------------------------------
wd23=$(make_work_dir "$TMPDIR_BASE/u23" "work-023-distinctive-name")
AID_WORK_DIR="$wd23" bash "$SUT" --task-id 1 --action stop >/dev/null 2>&1
assert_dir_exists "${TMPDIR_BASE}/u23/repo/.aid/.control/work-023-distinctive-name" \
    "U23 control dir named after AID_WORK_DIR's own basename"

# ---------------------------------------------------------------------------
# U24 -- path-traversal attempt in --task-id is rejected; nothing written
# ---------------------------------------------------------------------------
wd24=$(make_work_dir "$TMPDIR_BASE/u24" "work-024-demo")
ec=0
AID_WORK_DIR="$wd24" bash "$SUT" --task-id "../../evil" --action stop >/dev/null 2>&1 || ec=$?
assert_exit_eq "$ec" 4 "U24 traversal-shaped --task-id rejected (exit 4)"
if find "${TMPDIR_BASE}/u24" -name '*evil*' 2>/dev/null | grep -q .; then
    fail "U24b a file/dir named after the rejected value was created"
else
    pass "U24b no file/dir reflects the rejected --task-id value anywhere"
fi

# ---------------------------------------------------------------------------
# U25 -- atomicity: no stray temp file left in the control dir after stop
# ---------------------------------------------------------------------------
wd25=$(make_work_dir "$TMPDIR_BASE/u25" "work-025-demo")
AID_WORK_DIR="$wd25" bash "$SUT" --task-id 2 --action stop >/dev/null 2>&1
ctrldir="${TMPDIR_BASE}/u25/repo/.aid/.control/work-025-demo"
entries=$(find "$ctrldir" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
assert_eq "$entries" "1" "U25 control dir holds exactly one entry (the .stop file, no stray temp)"

# ---------------------------------------------------------------------------
# U26 -- isolation: STATE.md is never touched
# ---------------------------------------------------------------------------
wd26=$(make_work_dir "$TMPDIR_BASE/u26" "work-026-demo")
printf -- '---\nlifecycle: Running\n---\n\n# STATE\n' > "${wd26}/STATE.md"
before_hash=$(cat "${wd26}/STATE.md")
AID_WORK_DIR="$wd26" bash "$SUT" --task-id 4 --action stop >/dev/null 2>&1
AID_WORK_DIR="$wd26" bash "$SUT" --task-id 4 --action resume >/dev/null 2>&1
after_hash=$(cat "${wd26}/STATE.md")
assert_eq "$after_hash" "$before_hash" "U26 STATE.md byte-unchanged across stop+resume"

# ---------------------------------------------------------------------------
# U27 -- isolation: other tracked work-folder contents untouched
# ---------------------------------------------------------------------------
wd27=$(make_work_dir "$TMPDIR_BASE/u27" "work-027-demo")
mkdir -p "${wd27}/deliveries/delivery-001/tasks/task-001"
printf 'unrelated content\n' > "${wd27}/deliveries/delivery-001/tasks/task-001/DETAIL.md"
before27=$(cat "${wd27}/deliveries/delivery-001/tasks/task-001/DETAIL.md")
AID_WORK_DIR="$wd27" bash "$SUT" --task-id 1 --action stop >/dev/null 2>&1
after27=$(cat "${wd27}/deliveries/delivery-001/tasks/task-001/DETAIL.md")
assert_eq "$after27" "$before27" "U27 unrelated tracked task DETAIL.md byte-unchanged"

# ---------------------------------------------------------------------------
# U28 -- isolation: git is never invoked (PATH-shadowed stub stays untouched)
# ---------------------------------------------------------------------------
wd28=$(make_work_dir "$TMPDIR_BASE/u28" "work-028-demo")
fakebin="${TMPDIR_BASE}/u28/fakebin"
mkdir -p "$fakebin"
marker="${TMPDIR_BASE}/u28/git-was-invoked"
cat > "${fakebin}/git" <<EOF
#!/usr/bin/env bash
touch "$marker"
exit 1
EOF
chmod +x "${fakebin}/git"
ec=0
PATH="${fakebin}:${PATH}" AID_WORK_DIR="$wd28" bash "$SUT" --task-id 1 --action stop >/dev/null 2>&1 || ec=$?
assert_exit_zero "$ec" "U28 stop succeeds with a PATH-shadowed git stub present"
if [[ ! -f "$marker" ]]; then pass "U28b git stub never invoked"; else fail "U28b git stub WAS invoked"; fi
ec=0
PATH="${fakebin}:${PATH}" AID_WORK_DIR="$wd28" bash "$SUT" --task-id 1 --action resume >/dev/null 2>&1 || ec=$?
assert_exit_zero "$ec" "U28c resume succeeds with a PATH-shadowed git stub present"
if [[ ! -f "$marker" ]]; then pass "U28d git stub never invoked by resume either"; else fail "U28d git stub WAS invoked by resume"; fi

# ---------------------------------------------------------------------------
# U29 -- IO failure: mkdir -p blocked by a same-named regular file -> exit 2
# ---------------------------------------------------------------------------
wd29=$(make_work_dir "$TMPDIR_BASE/u29" "work-029-demo")
# Pre-create ".aid/.control" as a REGULAR FILE so mkdir -p cannot descend into it
# (a portable ENOTDIR-class failure, independent of POSIX permission-bit emulation).
touch "${TMPDIR_BASE}/u29/repo/.aid/.control"
ec=0
out=$(AID_WORK_DIR="$wd29" bash "$SUT" --task-id 1 --action stop 2>&1) || ec=$?
assert_exit_eq "$ec" 2 "U29 mkdir -p blocked by a colliding regular file exits 2"
assert_output_contains "$out" "ERROR:" "U29b stderr carries an ERROR: diagnostic"

# ---------------------------------------------------------------------------
# U30 -- isolation: sibling task signals are independent
# ---------------------------------------------------------------------------
wd30=$(make_work_dir "$TMPDIR_BASE/u30" "work-030-demo")
AID_WORK_DIR="$wd30" bash "$SUT" --task-id 1 --action stop >/dev/null 2>&1
AID_WORK_DIR="$wd30" bash "$SUT" --task-id 2 --action stop >/dev/null 2>&1
AID_WORK_DIR="$wd30" bash "$SUT" --task-id 1 --action resume >/dev/null 2>&1
if [[ ! -f "$(control_file_for "$wd30" "task-001")" ]] && [[ -f "$(control_file_for "$wd30" "task-002")" ]]; then
    pass "U30 resuming task-001 leaves task-002's signal file intact"
else
    fail "U30 sibling task signal isolation violated"
fi

# ---------------------------------------------------------------------------
# U31 -- dashboard co-vendored copy: byte-identical + behaves identically
# ---------------------------------------------------------------------------
if [[ -f "$SUT_DASHBOARD" ]]; then
    if diff -q "$SUT" "$SUT_DASHBOARD" >/dev/null 2>&1; then
        pass "U31 dashboard/scripts copy is byte-identical to canonical"
    else
        fail "U31 dashboard/scripts copy DIFFERS from canonical (co-vendor drift)"
    fi
    wd31=$(make_work_dir "$TMPDIR_BASE/u31" "work-031-demo")
    ec=0
    AID_WORK_DIR="$wd31" bash "$SUT_DASHBOARD" --task-id 6 --action stop >/dev/null 2>&1 || ec=$?
    assert_exit_zero "$ec" "U31b dashboard copy: stop exits 0"
    assert_file_exists "$(control_file_for "$wd31" "task-006")" "U31c dashboard copy: signal file created"
    AID_WORK_DIR="$wd31" bash "$SUT_DASHBOARD" --task-id 6 --action resume >/dev/null 2>&1
    if [[ ! -f "$(control_file_for "$wd31" "task-006")" ]]; then
        pass "U31d dashboard copy: resume removes the signal file"
    else
        fail "U31d dashboard copy: signal file survived resume"
    fi
else
    fail "U31 dashboard/scripts/write-control-signal.sh not found (co-vendor MANIFEST edit missing?)"
fi

# ---------------------------------------------------------------------------
test_summary
exit $?
