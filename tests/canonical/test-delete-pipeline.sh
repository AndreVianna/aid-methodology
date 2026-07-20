#!/usr/bin/env bash
# test-delete-pipeline.sh -- unit tests for dashboard/scripts/delete-pipeline.sh
# (feature-009-pipeline-delete, work-017 task-024).
#
# delete-pipeline.sh is a SAFETY-CRITICAL, IRREVERSIBLE destructive writer. Every
# test below builds a THROWAWAY git repo (+ throwaway worktrees) under a fresh
# mktemp scratch directory OUTSIDE this repo's own working tree -- the suite
# NEVER touches this repo's own pipelines/branches/worktrees.
#
# Covers:
#   Unit 1  -- main-folder happy path (exit 0, folder removed, message format)
#   Unit 2  -- work_id not found in any enumerated worktree root (exit 1)
#   Unit 3  -- invalid --work-id shapes rejected (exit 4)
#   Unit 4  -- a structurally-valid-but-absent bare "work-N" id is NOT rejected
#              by the regex backstop -- it 404s (exit 1), not exit 4
#   Unit 5  -- missing --work-id (exit 5)
#   Unit 6  -- unknown flag (exit 5)
#   Unit 7  -- Running guard: lifecycle=Running refuses deletion (exit 7)
#   Unit 8  -- dedicated non-main worktree: folder + worktree removed,
#              branch STILL exists afterward (git branch --list)
#   Unit 9  -- shared non-main worktree: folder-only removed, sibling work
#              AND the worktree checkout itself untouched
#   Unit 10 -- current-worktree guard: refuses to remove the worktree the
#              process itself is running from (exit 7, no removal)
#   Unit 11 -- containment violation: a symlinked work_id entry escaping
#              .aid/works/ is refused (exit 3), outside target untouched
#   Unit 12 -- forced `git worktree remove` failure (locked worktree) -> exit 3,
#              folder left in place (no partial/silent success)
#   Unit 13 -- lock contention: a pre-existing sentinel is NEVER stolen/removed
#              by the contending process (exit 2)
#   Unit 14 -- reconcile-winner: newest STATE.md `updated` wins across two
#              worktree copies of the SAME work_id; the shadow copy is left
#              untouched (WT-1 symmetry -- no bulk delete)
#   Unit 15 -- reconcile-winner tie-break: a literal "main" branch label wins
#              over a non-main copy with an EQUAL `updated`
#   Unit 16 -- reconcile-winner tie-break: among two non-"main" labels tied on
#              `updated`, the lexically smaller branch_label wins
#   Unit 17 -- git-absent/non-git degrade: AID_REPO_ROOT pointing at a plain
#              (non-git) directory still resolves + deletes via the
#              main-root-only fallback
#   Unit 18 -- -h/--help exits 0 and prints usage
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../dashboard/scripts/delete-pipeline.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# _mk_repo <dir> [branch]  -- git init a fresh throwaway repo with an empty
# .aid/works/ container and one commit. Default branch: main.
_mk_repo() {
    local dir="$1" branch="${2:-main}"
    mkdir -p "$dir/.aid/works"
    ( cd "$dir" \
        && git init -q -b "$branch" \
        && git config user.email test@example.invalid \
        && git config user.name "Test" \
        && touch .aid/works/.gitkeep \
        && git add -A \
        && git commit -q -m init )
}

# _mk_work <root> <work_id> <lifecycle> <updated>  -- create
# <root>/.aid/works/<work_id>/STATE.md with the given frontmatter scalars.
_mk_work() {
    local root="$1" work_id="$2" lifecycle="$3" updated="$4"
    mkdir -p "$root/.aid/works/$work_id"
    {
        echo "---"
        echo "lifecycle: $lifecycle"
        echo "updated: '$updated'"
        echo "---"
        echo "# Work State"
    } > "$root/.aid/works/$work_id/STATE.md"
}

# _commit_all <dir> <msg>
_commit_all() {
    local dir="$1" msg="$2"
    ( cd "$dir" && git add -A && git commit -q -m "$msg" >/dev/null 2>&1 || true )
}

# _mk_worktree <repo> <path> <branch>
_mk_worktree() {
    local repo="$1" path="$2" branch="$3"
    git -C "$repo" worktree add -q -b "$branch" "$path" >/dev/null 2>&1
}

echo "== delete-pipeline.sh tests =="

# ---------------------------------------------------------------------------
# Unit 1: main-folder happy path
# ---------------------------------------------------------------------------
D1="${TMPDIR_BASE}/u1"
_mk_repo "$D1"
_mk_work "$D1" work-100-demo Pending 2026-01-01T00:00:00Z
_commit_all "$D1" "add work-100-demo"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D1" bash "$SUT" --work-id work-100-demo 2>&1); ec=$?
assert_exit_zero "$ec" "U1 main-folder delete exits 0"
assert_eq "$out" "OK: deleted work-100-demo (folder)" "U1 success message format"
assert_dir_exists "$D1/.aid/works" "U1 .aid/works container survives"
if [[ ! -d "$D1/.aid/works/work-100-demo" ]]; then
    pass "U1 work folder removed"
else
    fail "U1 work folder NOT removed"
fi

# ---------------------------------------------------------------------------
# Unit 2: not-found
# ---------------------------------------------------------------------------
D2="${TMPDIR_BASE}/u2"
_mk_repo "$D2"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D2" bash "$SUT" --work-id work-999-nope 2>&1); ec=$?
assert_exit_eq "$ec" 1 "U2 not-found exits 1"

# ---------------------------------------------------------------------------
# Unit 3: invalid --work-id shapes (regex backstop)
# ---------------------------------------------------------------------------
D3="${TMPDIR_BASE}/u3"
_mk_repo "$D3"

for bad in "work1" "Work-1" "work-abc" "work-1/etc" "work-1-UPPER" "" "notwork-1"; do
    out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D3" bash "$SUT" --work-id "$bad" 2>&1); ec=$?
    assert_exit_eq "$ec" 4 "U3 invalid work_id '$bad' exits 4"
done

# ---------------------------------------------------------------------------
# Unit 4: a structurally-valid bare "work-N" id that does not exist -> 1, not 4
# ---------------------------------------------------------------------------
out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D3" bash "$SUT" --work-id work-1 2>&1); ec=$?
assert_exit_eq "$ec" 1 "U4 well-shaped-but-absent 'work-1' is a 404, not a regex rejection"

# ---------------------------------------------------------------------------
# Unit 5: missing --work-id
# ---------------------------------------------------------------------------
out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D3" bash "$SUT" 2>&1); ec=$?
assert_exit_eq "$ec" 5 "U5 missing --work-id exits 5"

# ---------------------------------------------------------------------------
# Unit 6: unknown flag
# ---------------------------------------------------------------------------
out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D3" bash "$SUT" --bogus 2>&1); ec=$?
assert_exit_eq "$ec" 5 "U6 unknown flag exits 5"

# ---------------------------------------------------------------------------
# Unit 7: Running guard
# ---------------------------------------------------------------------------
D7="${TMPDIR_BASE}/u7"
_mk_repo "$D7"
_mk_work "$D7" work-200-run Running 2026-01-01T00:00:00Z
_commit_all "$D7" "add work-200-run"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D7" bash "$SUT" --work-id work-200-run 2>&1); ec=$?
assert_exit_eq "$ec" 7 "U7 Running guard exits 7"
if [[ -d "$D7/.aid/works/work-200-run" ]]; then
    pass "U7 folder NOT removed (guard held)"
else
    fail "U7 folder was removed despite Running guard"
fi

# ---------------------------------------------------------------------------
# Unit 8: dedicated non-main worktree -- folder + worktree gone, BRANCH RETAINED
# ---------------------------------------------------------------------------
D8="${TMPDIR_BASE}/u8"
_mk_repo "$D8"
WT8="${TMPDIR_BASE}/u8-wt-dedicated"
_mk_worktree "$D8" "$WT8" feature-ded8
_mk_work "$WT8" work-300-ded Pending 2026-01-01T00:00:00Z
_commit_all "$WT8" "add work-300-ded"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D8" bash "$SUT" --work-id work-300-ded 2>&1); ec=$?
assert_exit_zero "$ec" "U8 dedicated-worktree delete exits 0"
assert_output_contains "$out" "worktree" "U8 success message mentions the removed worktree"
if [[ ! -d "$WT8" ]]; then
    pass "U8 worktree directory removed"
else
    fail "U8 worktree directory still present"
fi
if git -C "$D8" branch --list feature-ded8 | grep -q feature-ded8; then
    pass "U8 branch feature-ded8 STILL EXISTS after delete (retained, per OQ-PL3)"
else
    fail "U8 branch feature-ded8 was deleted -- branch retention violated"
fi

# ---------------------------------------------------------------------------
# Unit 9: shared non-main worktree -- folder-only, sibling + worktree survive
# ---------------------------------------------------------------------------
D9="${TMPDIR_BASE}/u9"
_mk_repo "$D9"
WT9="${TMPDIR_BASE}/u9-wt-shared"
_mk_worktree "$D9" "$WT9" feature-shared9
_mk_work "$WT9" work-400-a Pending 2026-01-01T00:00:00Z
_mk_work "$WT9" work-400-b Pending 2026-01-01T00:00:00Z
_commit_all "$WT9" "add works"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D9" bash "$SUT" --work-id work-400-a 2>&1); ec=$?
assert_exit_zero "$ec" "U9 shared-worktree delete exits 0"
assert_eq "$out" "OK: deleted work-400-a (folder)" "U9 success message is folder-only (no 'worktree')"
if [[ ! -d "$WT9/.aid/works/work-400-a" ]]; then
    pass "U9 work-400-a folder removed"
else
    fail "U9 work-400-a folder NOT removed"
fi
assert_dir_exists "$WT9/.aid/works/work-400-b" "U9 sibling work-400-b untouched"
assert_dir_exists "$WT9" "U9 shared worktree checkout itself survives"
if git -C "$D9" branch --list feature-shared9 | grep -q feature-shared9; then
    pass "U9 branch feature-shared9 still exists"
else
    fail "U9 branch feature-shared9 was deleted"
fi

# ---------------------------------------------------------------------------
# Unit 10: current-worktree guard
# ---------------------------------------------------------------------------
D10="${TMPDIR_BASE}/u10"
_mk_repo "$D10"
WT10="${TMPDIR_BASE}/u10-wt-cur"
_mk_worktree "$D10" "$WT10" feature-cur10
_mk_work "$WT10" work-500-cur Pending 2026-01-01T00:00:00Z
_commit_all "$WT10" "add work-500-cur"

out=$(cd "$WT10" && AID_REPO_ROOT="$D10" bash "$SUT" --work-id work-500-cur 2>&1); ec=$?
assert_exit_eq "$ec" 7 "U10 current-worktree guard exits 7"
if [[ -d "$WT10/.aid/works/work-500-cur" ]]; then
    pass "U10 folder NOT removed (guard held)"
else
    fail "U10 folder was removed despite current-worktree guard"
fi
if [[ -d "$WT10" ]]; then
    pass "U10 worktree itself untouched"
else
    fail "U10 worktree itself was removed"
fi

# ---------------------------------------------------------------------------
# Unit 11: containment violation (symlink escape)
#
# MSYS=winsymlinks:nativestrict forces a GENUINE (non-junction) symlink on
# Windows Git-Bash so this test is meaningful there too; a no-op elsewhere.
# If the runtime still cannot produce a real, realpath-resolvable symlink
# (no privilege / restricted host), the sub-test is SKIPPED with a clear note
# rather than asserted -- distinguishes a host limitation from a script defect.
# ---------------------------------------------------------------------------
D11="${TMPDIR_BASE}/u11"
_mk_repo "$D11"
OUTSIDE11="${TMPDIR_BASE}/u11-outside"
mkdir -p "$OUTSIDE11"
touch "$OUTSIDE11/marker"

MSYS=winsymlinks:nativestrict ln -s "$OUTSIDE11" "$D11/.aid/works/work-600-sym" 2>/dev/null
link_real="$(cd "$D11/.aid/works/work-600-sym" 2>/dev/null && pwd -P)"
works_real="$(cd "$D11/.aid/works" 2>/dev/null && pwd -P)"

if [[ -n "$link_real" && "$link_real" != "$works_real"* ]]; then
    out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D11" bash "$SUT" --work-id work-600-sym 2>&1); ec=$?
    assert_exit_eq "$ec" 3 "U11 containment violation exits 3"
    if [[ -e "$OUTSIDE11/marker" ]]; then
        pass "U11 outside target untouched (no traversal)"
    else
        fail "U11 outside target was removed -- containment breach"
    fi
else
    echo "  SKIP: U11 containment violation -- this host cannot create a" \
         "realpath-resolvable symlink (no privilege / Windows Developer Mode" \
         "off); deferred to a host where symlink creation is unrestricted" \
         "(e.g. CI/Linux)"
fi

# ---------------------------------------------------------------------------
# Unit 12: forced `git worktree remove` failure (locked worktree) -> exit 3
# ---------------------------------------------------------------------------
D12="${TMPDIR_BASE}/u12"
_mk_repo "$D12"
WT12="${TMPDIR_BASE}/u12-wt-locked"
_mk_worktree "$D12" "$WT12" feature-locked12
_mk_work "$WT12" work-950-locked Pending 2026-01-01T00:00:00Z
_commit_all "$WT12" "add work"
git -C "$D12" worktree lock "$WT12" --reason "locked for test" >/dev/null 2>&1

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D12" bash "$SUT" --work-id work-950-locked 2>&1); ec=$?
assert_exit_eq "$ec" 3 "U12 git-worktree-remove failure exits 3"
if [[ -d "$WT12/.aid/works/work-950-locked" ]]; then
    pass "U12 folder left in place (no partial/silent success)"
else
    fail "U12 folder gone despite reported removal failure"
fi
git -C "$D12" worktree unlock "$WT12" >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Unit 13: lock contention -- a pre-existing sentinel is never stolen
# ---------------------------------------------------------------------------
D13="${TMPDIR_BASE}/u13"
_mk_repo "$D13"
_mk_work "$D13" work-700-lock Pending 2026-01-01T00:00:00Z
_commit_all "$D13" "add work-700-lock"
touch "$D13/.aid/works/work-700-lock/.writeback-state.lock"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D13" AID_LOCK_TIMEOUT=2 bash "$SUT" --work-id work-700-lock 2>&1); ec=$?
assert_exit_eq "$ec" 2 "U13 lock contention exits 2"
assert_dir_exists "$D13/.aid/works/work-700-lock" "U13 folder NOT removed (lock held)"
assert_file_exists "$D13/.aid/works/work-700-lock/.writeback-state.lock" "U13 pre-existing lock file preserved (not stolen by the contending process)"

# ---------------------------------------------------------------------------
# Unit 14: reconcile-winner -- newest `updated` wins; shadow copy untouched
# ---------------------------------------------------------------------------
D14="${TMPDIR_BASE}/u14"
_mk_repo "$D14"
_mk_work "$D14" work-800-shadow Pending 2020-01-01T00:00:00Z
_commit_all "$D14" "add older main copy"
WT14="${TMPDIR_BASE}/u14-wt-shadow"
_mk_worktree "$D14" "$WT14" feature-shadow14
_mk_work "$WT14" work-800-shadow Pending 2026-06-01T00:00:00Z
_commit_all "$WT14" "add newer worktree copy"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D14" bash "$SUT" --work-id work-800-shadow 2>&1); ec=$?
assert_exit_zero "$ec" "U14 reconcile-winner delete exits 0"
if [[ ! -d "$WT14/.aid/works/work-800-shadow" ]]; then
    pass "U14 newer (winner) copy removed"
else
    fail "U14 newer (winner) copy NOT removed"
fi
assert_dir_exists "$D14/.aid/works/work-800-shadow" "U14 older (shadow) copy left untouched -- WT-1 symmetry, no bulk delete"

# ---------------------------------------------------------------------------
# Unit 15: reconcile-winner tie-break -- literal "main" label wins on a tie
# ---------------------------------------------------------------------------
D15="${TMPDIR_BASE}/u15"
_mk_repo "$D15" main
_mk_work "$D15" work-900-tie Pending 2026-01-01T00:00:00Z
_commit_all "$D15" "add main copy"
WT15="${TMPDIR_BASE}/u15-wt-tie"
_mk_worktree "$D15" "$WT15" feature-tie15
_mk_work "$WT15" work-900-tie Pending 2026-01-01T00:00:00Z
_commit_all "$WT15" "add same-timestamp copy"

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D15" bash "$SUT" --work-id work-900-tie 2>&1); ec=$?
assert_exit_zero "$ec" "U15 tie-break delete exits 0"
if [[ ! -d "$D15/.aid/works/work-900-tie" ]]; then
    pass "U15 'main'-labeled copy won the tie and was removed"
else
    fail "U15 'main'-labeled copy did NOT win the tie"
fi
assert_dir_exists "$WT15/.aid/works/work-900-tie" "U15 non-main tied copy left untouched"

# ---------------------------------------------------------------------------
# Unit 16: reconcile-winner tie-break -- among two non-"main" labels, the
# lexically smaller branch_label wins.
# ---------------------------------------------------------------------------
D16="${TMPDIR_BASE}/u16"
_mk_repo "$D16" trunk16
_mk_work "$D16" work-910-lex Pending 2026-01-01T00:00:00Z
_commit_all "$D16" "add trunk copy (label 'trunk16')"
WT16="${TMPDIR_BASE}/u16-wt-aaa"
_mk_worktree "$D16" "$WT16" aaa-branch16
_mk_work "$WT16" work-910-lex Pending 2026-01-01T00:00:00Z
_commit_all "$WT16" "add aaa-branch16 copy"

# "aaa-branch16" < "trunk16" lexically, and neither is literally "main" -- the
# aaa-branch16 copy should win the tie.
out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D16" bash "$SUT" --work-id work-910-lex 2>&1); ec=$?
assert_exit_zero "$ec" "U16 lexical tie-break delete exits 0"
if [[ ! -d "$WT16/.aid/works/work-910-lex" ]]; then
    pass "U16 lexically-smaller label ('aaa-branch16') won the tie and was removed"
else
    fail "U16 lexically-smaller label did NOT win the tie"
fi
assert_dir_exists "$D16/.aid/works/work-910-lex" "U16 trunk copy left untouched"

# ---------------------------------------------------------------------------
# Unit 17: non-git AID_REPO_ROOT degrades to main-root-only fallback
# ---------------------------------------------------------------------------
D17="${TMPDIR_BASE}/u17-plain"
mkdir -p "$D17/.aid/works/work-990-nogit"
cat > "$D17/.aid/works/work-990-nogit/STATE.md" <<'EOF'
---
lifecycle: Pending
updated: '2026-01-01T00:00:00Z'
---
EOF

out=$(cd "$TMPDIR_BASE" && AID_REPO_ROOT="$D17" bash "$SUT" --work-id work-990-nogit 2>&1); ec=$?
assert_exit_zero "$ec" "U17 non-git repo root still deletes via main-only fallback"
if [[ ! -d "$D17/.aid/works/work-990-nogit" ]]; then
    pass "U17 folder removed under git-absent degrade"
else
    fail "U17 folder NOT removed under git-absent degrade"
fi

# ---------------------------------------------------------------------------
# Unit 18: -h/--help
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --help 2>&1); ec=$?
assert_exit_zero "$ec" "U18 --help exits 0"
assert_output_contains "$out" "Usage:" "U18 --help prints usage"

echo
test_summary
exit $?
