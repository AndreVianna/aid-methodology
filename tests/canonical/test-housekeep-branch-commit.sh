#!/usr/bin/env bash
# test-housekeep-branch-commit.sh — unit suite for branch-commit.sh
#
# Tests the branch-ensure + per-stage commit helper against a throwaway git repo
# fixture (created in a mktemp directory; cleaned up on exit).
#
# Usage:
#   test-housekeep-branch-commit.sh [-v | --verbose]
#
# Test scenarios:
#   Unit 1: --ensure-branch on master → creates aid/housekeep-<slug> branch
#   Unit 2: --ensure-branch when already on aid/housekeep-* → reuses branch (resume)
#   Unit 3: --ensure-branch on non-master, non-housekeep branch → refused (exit 3)
#   Unit 4: --commit on aid/housekeep-* branch → exactly one commit produced
#   Unit 5: --commit on master (no ensure-branch) → refused (exit 3)
#   Unit 6: Source file contains no 'git push' (static assertion)
#   Unit 7: No remote interaction occurs during any operation
#   Unit 8: Combined --ensure-branch + --commit in one invocation
#   Unit 9: Argument validation errors (missing slug, missing message, etc.)
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/scripts/housekeep/branch-commit.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# Create a fresh throwaway git repo; set up an initial commit on master.
# Prints the repo dir path.
make_repo() {
    local repo
    repo=$(mktemp -d)
    # Use --initial-branch=master so the default branch is master regardless of
    # the host git defaultBranch config (which may be 'main' on modern systems).
    git -C "$repo" init -q --initial-branch=master 2>/dev/null \
        || { git -C "$repo" init -q; git -C "$repo" checkout -q -b master 2>/dev/null || true; }
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    # Initial commit so master exists
    echo "init" > "${repo}/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "chore: initial commit"
    echo "$repo"
}

# Run the SUT inside a specific repo directory.
# Usage: run_sut_in <repo_dir> [args...]
run_sut_in() {
    local repo="$1"; shift
    (cd "$repo" && bash "$SUT" "$@")
}

# Get the current branch of a repo.
current_branch() {
    local repo="$1"
    git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Count commits on the current branch in a repo.
commit_count() {
    local repo="$1"
    git -C "$repo" rev-list --count HEAD 2>/dev/null
}

# ---------------------------------------------------------------------------
# Global teardown: register a cleanup list and sweep them at exit.
# ---------------------------------------------------------------------------
CLEANUP_DIRS=()
cleanup_all() {
    local d
    for d in "${CLEANUP_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: --ensure-branch on master → creates aid/housekeep-<slug> ==="

REPO1=$(make_repo)
CLEANUP_DIRS+=("$REPO1")

assert_eq "$(current_branch "$REPO1")" "master" "U1: fixture starts on master"

out1=$(run_sut_in "$REPO1" --ensure-branch --slug "2026-06-02" 2>&1)
code1=$?
assert_exit_zero "$code1" "U1: --ensure-branch exits 0"
assert_eq "$(current_branch "$REPO1")" "aid/housekeep-2026-06-02" "U1: branch switched to aid/housekeep-2026-06-02"
assert_output_contains "$out1" "aid/housekeep-2026-06-02" "U1: stdout mentions the new branch name"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: --ensure-branch on aid/housekeep-* → reuse (resume case) ==="

REPO2=$(make_repo)
CLEANUP_DIRS+=("$REPO2")

# First ensure creates the branch
run_sut_in "$REPO2" --ensure-branch --slug "postmerge" >/dev/null 2>&1
assert_eq "$(current_branch "$REPO2")" "aid/housekeep-postmerge" "U2: branch created by first call"

# Second ensure on the same branch should reuse, not fail or create a new one
out2=$(run_sut_in "$REPO2" --ensure-branch --slug "postmerge" 2>&1)
code2=$?
assert_exit_zero "$code2" "U2: second --ensure-branch exits 0"
assert_eq "$(current_branch "$REPO2")" "aid/housekeep-postmerge" "U2: still on same branch after second ensure"
assert_output_contains "$out2" "reusing" "U2: stdout indicates reuse"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: --ensure-branch on non-master, non-housekeep branch → refused ==="

REPO3=$(make_repo)
CLEANUP_DIRS+=("$REPO3")

# Create a feature branch (not master, not aid/housekeep-*)
git -C "$REPO3" switch -c "feature/some-other-work" -q

out3=$(run_sut_in "$REPO3" --ensure-branch --slug "test" 2>&1) || code3=$?
assert_exit_eq "${code3:-0}" 3 "U3: refused on non-master/non-housekeep branch (exit 3)"
assert_eq "$(current_branch "$REPO3")" "feature/some-other-work" "U3: branch unchanged after refusal"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: --commit on aid/housekeep-* → exactly one commit ==="

REPO4=$(make_repo)
CLEANUP_DIRS+=("$REPO4")

# Ensure we are on a housekeep branch
run_sut_in "$REPO4" --ensure-branch --slug "kb-refresh" >/dev/null 2>&1

BEFORE_COUNT=$(commit_count "$REPO4")

# Make a file change to commit
echo "delta content" > "${REPO4}/delta.txt"

out4=$(run_sut_in "$REPO4" --commit --message "chore(housekeep): KB delta refresh [feature-002]" --add delta.txt 2>&1)
code4=$?
assert_exit_zero "$code4" "U4: --commit exits 0"

AFTER_COUNT=$(commit_count "$REPO4")
DIFF=$((AFTER_COUNT - BEFORE_COUNT))
assert_eq "$DIFF" "1" "U4: exactly one new commit produced"

# Verify the commit message is correct
LAST_MSG=$(git -C "$REPO4" log -1 --pretty=format:"%s")
assert_eq "$LAST_MSG" "chore(housekeep): KB delta refresh [feature-002]" "U4: commit message matches supplied message"

# Verify still on the housekeep branch (no branch change during commit)
assert_eq "$(current_branch "$REPO4")" "aid/housekeep-kb-refresh" "U4: still on housekeep branch after commit"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: --commit on master (without --ensure-branch) → refused ==="

REPO5=$(make_repo)
CLEANUP_DIRS+=("$REPO5")

# We are on master; no ensure-branch call
echo "some change" > "${REPO5}/newfile.txt"
git -C "$REPO5" add newfile.txt

out5=$(run_sut_in "$REPO5" --commit --message "chore(housekeep): should not land on master" --add newfile.txt 2>&1) || code5=$?
assert_exit_eq "${code5:-0}" 3 "U5: --commit on master refused (exit 3)"
assert_eq "$(current_branch "$REPO5")" "master" "U5: still on master after refusal"

# Verify no extra commit was made on master
COUNT5=$(commit_count "$REPO5")
assert_eq "$COUNT5" "1" "U5: commit count on master unchanged (still 1)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: source file contains no executable 'git push' call ==="

# Check for actual invocations (lines with leading whitespace then `git push`)
# excluding comment-only lines (lines where the first non-space char is `#`).
if grep -E '^[[:space:]]*git push' "$SUT" 2>/dev/null | grep -vE '^[[:space:]]*#' | grep -q .; then
    fail "U6: executable 'git push' found in script source — violates VC boundary contract"
else
    pass "U6: no executable 'git push' in script source"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: no remote interaction during any operation ==="

REPO7=$(make_repo)
CLEANUP_DIRS+=("$REPO7")

# Verify the repo has no remotes configured (our fixture has no remotes)
REMOTES=$(git -C "$REPO7" remote 2>/dev/null)
assert_eq "$REMOTES" "" "U7: fixture repo has no remotes (clean isolation)"

# Run ensure-branch; if it tried to push/fetch, it would fail since no remote exists
run_sut_in "$REPO7" --ensure-branch --slug "no-remote-test" >/dev/null 2>&1
code7a=$?
assert_exit_zero "$code7a" "U7: ensure-branch succeeds with no remote configured"

# Make a change and commit; if script tried to push/fetch, it would fail
echo "remote isolation test" > "${REPO7}/remote-test.txt"
run_sut_in "$REPO7" --commit --message "chore(housekeep): remote isolation test" --add remote-test.txt >/dev/null 2>&1
code7b=$?
assert_exit_zero "$code7b" "U7: commit succeeds with no remote configured"

# Verify no push: verify HEAD is local only (no remote tracking branch)
REMOTE_TRACKING=$(git -C "$REPO7" rev-parse --abbrev-ref "@{u}" 2>/dev/null || echo "none")
assert_eq "$REMOTE_TRACKING" "none" "U7: branch has no remote tracking (never pushed)"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 8: combined --ensure-branch + --commit in one invocation ==="

REPO8=$(make_repo)
CLEANUP_DIRS+=("$REPO8")

assert_eq "$(current_branch "$REPO8")" "master" "U8: fixture starts on master"
echo "combined operation content" > "${REPO8}/combined.txt"

BEFORE_COUNT8=$(commit_count "$REPO8")

out8=$(run_sut_in "$REPO8" \
    --ensure-branch --slug "combined-test" \
    --commit --message "chore(housekeep): combined ensure+commit test" \
    --add combined.txt 2>&1)
code8=$?
assert_exit_zero "$code8" "U8: combined --ensure-branch + --commit exits 0"
assert_eq "$(current_branch "$REPO8")" "aid/housekeep-combined-test" "U8: on housekeep branch after combined op"

AFTER_COUNT8=$(commit_count "$REPO8")
DIFF8=$((AFTER_COUNT8 - BEFORE_COUNT8))
assert_eq "$DIFF8" "1" "U8: exactly one new commit from combined operation"

LAST_MSG8=$(git -C "$REPO8" log -1 --pretty=format:"%s")
assert_eq "$LAST_MSG8" "chore(housekeep): combined ensure+commit test" "U8: commit message correct in combined op"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: argument validation errors ==="

REPO9=$(make_repo)
CLEANUP_DIRS+=("$REPO9")

# 9a: --ensure-branch without --slug
code9a=0
run_sut_in "$REPO9" --ensure-branch 2>/dev/null || code9a=$?
assert_exit_eq "$code9a" 2 "U9a: --ensure-branch without --slug → exit 2"

# 9b: --commit without --message
code9b=0
run_sut_in "$REPO9" --commit 2>/dev/null || code9b=$?
assert_exit_eq "$code9b" 2 "U9b: --commit without --message → exit 2"

# 9c: --commit with --message but no --add or --add-all
code9c=0
run_sut_in "$REPO9" --commit --message "test" 2>/dev/null || code9c=$?
assert_exit_eq "$code9c" 2 "U9c: --commit with message but no --add → exit 2"

# 9d: no operation flags at all
code9d=0
run_sut_in "$REPO9" 2>/dev/null || code9d=$?
assert_exit_eq "$code9d" 2 "U9d: no operation flags → exit 2"

# 9e: unknown flag
code9e=0
run_sut_in "$REPO9" --unknown-flag 2>/dev/null || code9e=$?
assert_exit_eq "$code9e" 2 "U9e: unknown flag → exit 2"

# 9f: --slug with empty value (empty string — slug validation)
code9f=0
run_sut_in "$REPO9" --ensure-branch --slug "" 2>/dev/null || code9f=$?
assert_exit_eq "$code9f" 2 "U9f: --slug with empty value → exit 2"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: --add-all stages all changes ==="

REPO10=$(make_repo)
CLEANUP_DIRS+=("$REPO10")

run_sut_in "$REPO10" --ensure-branch --slug "add-all-test" >/dev/null 2>&1

echo "file one" > "${REPO10}/file1.txt"
echo "file two" > "${REPO10}/file2.txt"

BEFORE_COUNT10=$(commit_count "$REPO10")

out10=$(run_sut_in "$REPO10" --commit \
    --message "chore(housekeep): cleanup stage [feature-004]" \
    --add-all 2>&1)
code10=$?
assert_exit_zero "$code10" "U10: --add-all commit exits 0"

AFTER_COUNT10=$(commit_count "$REPO10")
DIFF10=$((AFTER_COUNT10 - BEFORE_COUNT10))
assert_eq "$DIFF10" "1" "U10: exactly one commit with --add-all"

# Both files should be tracked
TRACKED=$(git -C "$REPO10" show --name-only --format="" HEAD | sort | tr '\n' ' ' | sed 's/ $//')
if echo "$TRACKED" | grep -q "file1.txt" && echo "$TRACKED" | grep -q "file2.txt"; then
    pass "U10: both files staged and committed via --add-all"
else
    fail "U10: not all files were staged — committed files: '$TRACKED'"
fi

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
