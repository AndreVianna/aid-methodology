#!/usr/bin/env bash
# test-worktree-lifecycle.sh -- unit suite for the Worktree Lifecycle Helper.
#
# SUT:
#   canonical/aid/scripts/works/worktree-lifecycle.sh -- the single shared
#   implementation of the git-worktree mechanics every worktree-consuming
#   feature binds to: `create <work-id> <name> [--base <ref>]` (branch
#   <work-id>, dir .claude/worktrees/<work-id>-<name>, off master) and
#   `locate <work-id> [--name <slug>]` (the 4-rung "most-intact-state-first"
#   fallback ladder: registered -> branch-only recreate -> neither (create +
#   relocate) -> already-inside). This script is PURE GIT MECHANICS -- it
#   never switches a session.
#
# Prose reference (host-switch + cwd-fallback agent contract; AC4):
#   canonical/aid/templates/worktree-lifecycle.md
#
# What this suite asserts (mapped to feature-001 SPEC "Testing" / task-002 ACs):
#   Group A  create fresh (dir/branch/base/stdout)
#   Group B  create idempotent re-run, SAME <name>                (NFR2)
#   Group C  create idempotent re-run, DIFFERENT <name>            (NFR2 -- keyed on branch)
#   Group D  create --base <ref> honored (happy path)
#   Group E  locate rung 1 (registered)
#   Group F  locate rung 2 (branch-only: committed-preserved + bare-<work-id> dir
#                            + subsequent locate re-resolves via rung 1)
#   Group G  locate --name <slug> honored (happy path)
#   Group H  locate rung 3 (neither -> create + relocate the untracked work folder)
#   Group I  locate rung 3 relocate guards (target populated -> skip; traversal
#            derived slug -> exit 2)
#   Group J  path-consistency: create / locate rungs 1 + 4 emit the byte-identical
#            path regardless of which internal git call resolved it (task-001 fix)
#   Group K  divergence: create fails CLOSED vs locate DEGRADES on the identical
#            non-git condition (plain non-git dir; git present but broken)
#   Group L  input validation -- path-confinement traversal (exit 2, no mutation)
#   Group M  contract surface (--help / unknown operation / missing positional)
#   Group N  prose-ref (worktree-lifecycle.md) -- host-switch + cwd-fallback +
#            enter-is-an-agent-action + consumption contract (AC4 coverage)
#   Group O  create rung 2 (branch-only recreate: committed-preserved (NFR3) +
#            no re-branch + <work-id>-<name> dir naming + subsequent idempotent
#            re-run resolves via rung 1)
#   Group P  create rung 4 (already-inside target worktree: no-op, ignores a
#            differing <name>) + already-registered no-op from outside -- no
#            duplicate worktree/branch across any of the re-runs
#
# This suite validates the EXISTING task-001 implementation (not a red/green
# fixture): every assertion below is expected to pass against the current tree.
#
# Local-test constraints honored: every fixture is a throwaway `mktemp -d` git
# repo (real `git init` + real `git worktree add`), cleaned up via a
# CLEANUP_DIRS trap. No port binding. The degrade branch is exercised with an
# immediately-failing fake `git` shadowing PATH (Group K) -- never a real 2s
# `timeout` wait, mirroring the enumerate-works.sh precedent's Group D
# technique. Auto-wired into tests/run-all.sh by the test-*.sh glob.
#
# Usage:
#   test-worktree-lifecycle.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/canonical/aid/scripts/works/worktree-lifecycle.sh"
DOC="${REPO_ROOT}/canonical/aid/templates/worktree-lifecycle.md"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

CLEANUP_DIRS=()
cleanup_all() {
    local d
    for d in "${CLEANUP_DIRS[@]:-}"; do
        # `git worktree add` leaves administrative entries in the parent repo;
        # since we rm -rf the whole scratch tree (parent repo included, for
        # worktrees nested under it) those entries vanish with it.
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d" 2>/dev/null || true
    done
}
trap cleanup_all EXIT

# make_git_repo -> path to a fresh throwaway git repo on branch `master` with
# ONE initial commit (unlike enumerate-works.sh's precedent fixture, an
# unborn-HEAD repo cannot be a `git worktree add` base -- every rung and
# `create`'s default --base master needs a resolvable HEAD/master from the
# start).
make_git_repo() {
    local repo
    repo=$(mktemp -d)
    git -C "$repo" init -q --initial-branch=master 2>/dev/null \
        || { git -C "$repo" init -q; git -C "$repo" checkout -q -b master 2>/dev/null || true; }
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    echo "seed" > "$repo/README.md"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "init"
    echo "$repo"
}

# run_sut <dir> <path-prefix-or-empty> <op> [args...] -> populates _OUT/_ERR/_CODE.
# Runs the SUT with <dir> as its cwd (worktree-lifecycle.sh operates on "."),
# optionally shadowing PATH with a fake-git bin dir for the degrade drills.
run_sut() {
    local dir="$1" path_prefix="$2"; shift 2
    local errf; errf=$(mktemp)
    if [[ -n "$path_prefix" ]]; then
        _OUT=$(cd "$dir" && PATH="$path_prefix:$PATH" bash "$SUT" "$@" 2>"$errf"); _CODE=$?
    else
        _OUT=$(cd "$dir" && bash "$SUT" "$@" 2>"$errf"); _CODE=$?
    fi
    _ERR=$(cat "$errf"); rm -f "$errf"
}

# field1 <TAB-record> / field2 <TAB-record> -> the two locate stdout fields.
field1() { local s="$1"; printf '%s' "${s%%$'\t'*}"; }
field2() { local s="$1"; printf '%s' "${s##*$'\t'}"; }

# ===========================================================================
echo ""
echo "=== Group A: create -- fresh (dir/branch/base/stdout) ==="

REPO_A=$(make_git_repo); CLEANUP_DIRS+=("$REPO_A")
REPO_A_ABS="$(cd "$REPO_A" && pwd -P)"

run_sut "$REPO_A" "" create work-101 alpha
assert_exit_zero "$_CODE" "A: fresh create exits 0"
assert_dir_exists "${REPO_A_ABS}/.claude/worktrees/work-101-alpha" "A: worktree directory .claude/worktrees/work-101-alpha exists"
EXPECTED_A="$(cd "${REPO_A_ABS}/.claude/worktrees/work-101-alpha" && pwd -P)"
assert_eq "$_OUT" "$EXPECTED_A" "A: stdout is exactly the worktree's absolute path, nothing else"
assert_eq "$(git -C "$EXPECTED_A" symbolic-ref --short HEAD)" "work-101" "A: new worktree is on branch work-101"
assert_eq "$(git -C "$EXPECTED_A" rev-parse HEAD)" "$(git -C "$REPO_A_ABS" rev-parse master)" "A: branch is based off master by default"

# ===========================================================================
echo ""
echo "=== Group B: create -- idempotent re-run, SAME <name> (NFR2) ==="

run_sut "$REPO_A" "" create work-101 alpha
assert_exit_zero "$_CODE" "B: idempotent same-name re-run exits 0"
assert_eq "$_OUT" "$EXPECTED_A" "B: idempotent same-name re-run re-prints the existing path"
WT_COUNT_B="$(git -C "$REPO_A_ABS" worktree list --porcelain | grep -c '^branch refs/heads/work-101$')"
assert_eq "$WT_COUNT_B" "1" "B: still exactly ONE worktree registered for branch work-101 (no duplicate)"

# ===========================================================================
echo ""
echo "=== Group C: create -- idempotent re-run, DIFFERENT <name> (keyed on branch) ==="

REPO_C=$(make_git_repo); CLEANUP_DIRS+=("$REPO_C")
REPO_C_ABS="$(cd "$REPO_C" && pwd -P)"

run_sut "$REPO_C" "" create work-970 alpha
assert_exit_zero "$_CODE" "C: initial create (alpha) exits 0"
PATH_C_ALPHA="$_OUT"

run_sut "$REPO_C" "" create work-970 beta
assert_exit_zero "$_CODE" "C: re-run with a DIFFERENT name (beta) still exits 0 (no-op keyed on branch)"
assert_eq "$_OUT" "$PATH_C_ALPHA" "C: re-run re-prints the ORIGINAL (alpha) path, not a beta path"
assert_output_contains "$_ERR" "ignoring differing name" "C: a one-line stderr note flags the ignored differing name"
if [[ -d "${REPO_C_ABS}/.claude/worktrees/work-970-beta" ]]; then
    fail "C: no work-970-beta directory should be created (the original is never renamed)"
else
    pass "C: no work-970-beta directory created (directory not renamed)"
fi
WT_COUNT_C="$(git -C "$REPO_C_ABS" worktree list --porcelain | grep -c '^branch refs/heads/work-970$')"
assert_eq "$WT_COUNT_C" "1" "C: still exactly ONE worktree registered for branch work-970"

# ===========================================================================
echo ""
echo "=== Group D: create -- --base <ref> honored (happy path) ==="

REPO_D=$(make_git_repo); CLEANUP_DIRS+=("$REPO_D")
REPO_D_ABS="$(cd "$REPO_D" && pwd -P)"
git -C "$REPO_D_ABS" checkout -q -b main
echo "main-only" > "$REPO_D_ABS/main-only.txt"
git -C "$REPO_D_ABS" add -A
git -C "$REPO_D_ABS" commit -q -m "main-only commit (diverges main from master)"
git -C "$REPO_D_ABS" checkout -q master

run_sut "$REPO_D" "" create work-960 delta --base main
assert_exit_zero "$_CODE" "D: create with --base main exits 0"
PATH_D="$_OUT"
assert_eq "$(git -C "$PATH_D" rev-parse HEAD)" "$(git -C "$REPO_D_ABS" rev-parse main)" "D: new branch's tip == main's tip (not master's) -- --base honored"
assert_file_exists "${PATH_D}/main-only.txt" "D: new worktree carries main's committed content"

# ===========================================================================
echo ""
echo "=== Group E: locate -- rung 1 (registered) ==="

REPO_E=$(make_git_repo); CLEANUP_DIRS+=("$REPO_E")
run_sut "$REPO_E" "" create work-111 alpha
PATH_E="$_OUT"

run_sut "$REPO_E" "" locate work-111
assert_exit_zero "$_CODE" "E: locate rung1 exits 0"
assert_eq "$_OUT" "$(printf '%s\tregistered' "$PATH_E")" "E: locate rung1 = <path>\tregistered, byte-exact"

# ===========================================================================
echo ""
echo "=== Group F: locate -- rung 2 (branch-only recreate) ==="

REPO_F=$(make_git_repo); CLEANUP_DIRS+=("$REPO_F")
REPO_F_ABS="$(cd "$REPO_F" && pwd -P)"
TMPWT_F_PARENT=$(mktemp -d); CLEANUP_DIRS+=("$TMPWT_F_PARENT")
TMPWT_F="${TMPWT_F_PARENT}/tmpwt-303"
git -C "$REPO_F_ABS" branch work-303 master
git -C "$REPO_F_ABS" worktree add -q "$TMPWT_F" work-303
echo "committed content" > "$TMPWT_F/committed.txt"
git -C "$TMPWT_F" add -A
git -C "$TMPWT_F" commit -q -m "add committed.txt on work-303"
git -C "$REPO_F_ABS" worktree remove --force "$TMPWT_F" 2>/dev/null || rm -rf "$TMPWT_F"
git -C "$REPO_F_ABS" worktree prune

run_sut "$REPO_F" "" locate work-303
assert_exit_zero "$_CODE" "F: rung2 branch-only recreate exits 0"
PATH_F="$(field1 "$_OUT")"
assert_eq "$(field2 "$_OUT")" "recreated" "F: status=recreated"
assert_eq "$(basename "$PATH_F")" "work-303" "F: bare work-id directory (no -<slug> suffix -- .aid/works/ is uncommitted, no slug source)"
assert_file_exists "${PATH_F}/committed.txt" "F: committed file preserved into the recreated worktree (NFR3)"

run_sut "$REPO_F" "" locate work-303
assert_exit_zero "$_CODE" "F: subsequent locate exits 0"
assert_eq "$(field2 "$_OUT")" "registered" "F: subsequent locate resolves via rung1 (registered), not rung2 again"
assert_eq "$(field1 "$_OUT")" "$PATH_F" "F: subsequent locate re-prints the byte-identical path (keys on branch, not dir name)"

# ===========================================================================
echo ""
echo "=== Group G: locate -- --name <slug> honored (happy path) ==="

REPO_G=$(make_git_repo); CLEANUP_DIRS+=("$REPO_G")
REPO_G_ABS="$(cd "$REPO_G" && pwd -P)"
git -C "$REPO_G_ABS" branch work-450 master

run_sut "$REPO_G" "" locate work-450 --name custom-slug
assert_exit_zero "$_CODE" "G: locate --name honored exits 0"
PATH_G="$(field1 "$_OUT")"
assert_eq "$(field2 "$_OUT")" "recreated" "G: status=recreated"
assert_eq "$(basename "$PATH_G")" "work-450-custom-slug" "G: --name override composes <work-id>-<slug>, overriding auto-derivation"

# ===========================================================================
echo ""
echo "=== Group H: locate -- rung 3 (neither -> create + relocate untracked work folder) ==="

REPO_H=$(make_git_repo); CLEANUP_DIRS+=("$REPO_H")
REPO_H_ABS="$(cd "$REPO_H" && pwd -P)"
mkdir -p "$REPO_H_ABS/.aid/works/work-404-zeta"
echo "# Work State" > "$REPO_H_ABS/.aid/works/work-404-zeta/STATE.md"
# STATE.md is UNTRACKED (never git add/commit) -- exactly the real-world convention.

run_sut "$REPO_H" "" locate work-404
assert_exit_zero "$_CODE" "H: rung3 relocate exits 0"
PATH_H="$(field1 "$_OUT")"
assert_eq "$(field2 "$_OUT")" "created" "H: status=created"
assert_eq "$(basename "$PATH_H")" "work-404-zeta" "H: dir basename derived from the untracked folder's slug"
assert_eq "$(git -C "$PATH_H" symbolic-ref --short HEAD)" "work-404" "H: new worktree is on branch work-404"
assert_file_exists "${PATH_H}/.aid/works/work-404-zeta/STATE.md" "H: STATE.md relocated INTO the new worktree"
if [[ -f "${REPO_H_ABS}/.aid/works/work-404-zeta/STATE.md" ]]; then
    fail "H: STATE.md must no longer exist on the origin checkout after relocate"
else
    pass "H: STATE.md no longer on the origin checkout (relocated, not copied)"
fi

# ===========================================================================
echo ""
echo "=== Group I: locate -- rung 3 relocate guards ==="

# I1: target already populated -> mv skipped, no overwrite, no data loss.
# Constructed by COMMITTING a .aid/works/<id>-<slug>/ folder onto HEAD (an
# artificial fixture -- normally never committed) so `git worktree add`'s own
# checkout of HEAD's committed tree pre-populates the relocate target before
# the guard's -e check runs; a SEPARATE untracked file in the same source
# folder is what would be relocated absent the guard.
REPO_I1=$(make_git_repo); CLEANUP_DIRS+=("$REPO_I1")
REPO_I1_ABS="$(cd "$REPO_I1" && pwd -P)"
mkdir -p "$REPO_I1_ABS/.aid/works/work-707-eta"
echo "committed" > "$REPO_I1_ABS/.aid/works/work-707-eta/committed-marker.txt"
git -C "$REPO_I1_ABS" add -A
git -C "$REPO_I1_ABS" commit -q -m "pre-populate the rung3 relocate target (artificial fixture)"
echo "untracked" > "$REPO_I1_ABS/.aid/works/work-707-eta/untracked-marker.txt"

run_sut "$REPO_I1" "" locate work-707
assert_exit_zero "$_CODE" "I1: rung3 with a pre-populated target still exits 0"
PATH_I1="$(field1 "$_OUT")"
assert_eq "$(field2 "$_OUT")" "created" "I1: status=created (worktree still produced)"
assert_output_contains "$_ERR" "already populated; skipped relocate" "I1: guard emits the skip note on stderr"
assert_file_exists "${PATH_I1}/.aid/works/work-707-eta/committed-marker.txt" "I1: pre-existing (committed) target file untouched"
if [[ -f "${PATH_I1}/.aid/works/work-707-eta/untracked-marker.txt" ]]; then
    fail "I1: untracked-marker.txt must NOT be moved into the target (guard must skip the mv)"
else
    pass "I1: untracked-marker.txt NOT moved into the target (mv skipped -- no overwrite)"
fi
if [[ -f "${REPO_I1_ABS}/.aid/works/work-707-eta/untracked-marker.txt" ]]; then
    pass "I1: untracked-marker.txt remains on the origin checkout (no data loss -- mv never ran)"
else
    fail "I1: untracked-marker.txt missing from the origin checkout (guard should skip the mv, not delete the source)"
fi

# I2: a derived slug containing ".." -> rejected by path-confinement, exit 2,
# no `git worktree add` attempted and no branch created.
REPO_I2=$(make_git_repo); CLEANUP_DIRS+=("$REPO_I2")
REPO_I2_ABS="$(cd "$REPO_I2" && pwd -P)"
mkdir -p "$REPO_I2_ABS/.aid/works/work-808-my..evil"
echo "x" > "$REPO_I2_ABS/.aid/works/work-808-my..evil/marker.txt"

run_sut "$REPO_I2" "" locate work-808
assert_exit_eq "$_CODE" 2 "I2: traversal-bearing derived slug -> exit 2"
assert_eq "$_OUT" "" "I2: rejected derivation emits no stdout"
assert_output_contains "$_ERR" "path-confinement" "I2: stderr names the path-confinement rejection"
if [[ -d "${REPO_I2_ABS}/.claude/worktrees" ]] && [[ -n "$(find "${REPO_I2_ABS}/.claude/worktrees" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    fail "I2: no worktree should have been created for the rejected traversal derivation"
else
    pass "I2: no worktree created (rejected before git worktree add)"
fi
if git -C "$REPO_I2_ABS" show-ref --verify --quiet refs/heads/work-808; then
    fail "I2: branch work-808 must not have been created"
else
    pass "I2: branch work-808 not created (rejected before any git mutation)"
fi

# ===========================================================================
echo ""
echo "=== Group J: path-consistency -- create/locate rungs 1+4 byte-identical path (task-001 fix) ==="

REPO_J=$(make_git_repo); CLEANUP_DIRS+=("$REPO_J")

run_sut "$REPO_J" "" create work-950 gamma
assert_exit_zero "$_CODE" "J: initial create exits 0"
PATH_J="$_OUT"
if [[ -n "$PATH_J" ]]; then pass "J: initial create produced a non-empty path"; else fail "J: initial create produced a non-empty path"; fi

run_sut "$REPO_J" "" create work-950 gamma
assert_exit_zero "$_CODE" "J: idempotent create re-run exits 0"
assert_eq "$_OUT" "$PATH_J" "J: idempotent create re-run re-prints the BYTE-IDENTICAL path"

run_sut "$REPO_J" "" locate work-950
assert_exit_zero "$_CODE" "J: locate (rung1, from the main tree) exits 0"
assert_eq "$(field2 "$_OUT")" "registered" "J: locate rung1 status=registered"
assert_eq "$(field1 "$_OUT")" "$PATH_J" "J: locate rung1 emits the BYTE-IDENTICAL path (porcelain-parsed, normalized via _abs_path)"

run_sut "$PATH_J" "" locate work-950
assert_exit_zero "$_CODE" "J: locate (rung4, from inside the worktree) exits 0"
assert_eq "$(field2 "$_OUT")" "current" "J: locate rung4 status=current"
assert_eq "$(field1 "$_OUT")" "$PATH_J" "J: locate rung4 emits the BYTE-IDENTICAL path (rev-parse-derived, normalized via _abs_path)"

# ===========================================================================
echo ""
echo "=== Group K: divergence -- create fails CLOSED, locate DEGRADES (same non-git condition) ==="

# K1: a plain non-git directory.
DIR_K1=$(mktemp -d); CLEANUP_DIRS+=("$DIR_K1")
DIR_K1_ABS="$(cd "$DIR_K1" && pwd -P)"

run_sut "$DIR_K1" "" create work-909 whatever
assert_exit_eq "$_CODE" 1 "K1: create in a non-git dir fails CLOSED (exit 1)"
assert_eq "$_OUT" "" "K1: create emits EMPTY stdout on the fail-closed path"
assert_output_contains "$_ERR" "not a git repo" "K1: create's stderr names the condition"

run_sut "$DIR_K1" "" locate work-909
assert_exit_zero "$_CODE" "K1: locate in the SAME non-git dir still exits 0 (degrade, never fail the caller)"
assert_eq "$_OUT" "$(printf '%s\tcurrent' "$DIR_K1_ABS")" "K1: locate degrades to <cwd-abs>\tcurrent (non-empty path)"
assert_output_contains "$_ERR" "operating in current directory" "K1: locate's stderr note accompanies the degrade"

# K2: git present on disk but FAILING (shadowed by a fake git that always exits
# non-zero) inside an otherwise-real repo -- avoids any real 2s-timeout wait.
REPO_K2=$(make_git_repo); CLEANUP_DIRS+=("$REPO_K2")
REPO_K2_ABS="$(cd "$REPO_K2" && pwd -P)"
FAKEBIN=$(mktemp -d); CLEANUP_DIRS+=("$FAKEBIN")
cat > "$FAKEBIN/git" <<'FAKEGIT'
#!/usr/bin/env bash
# Fake git: always fails immediately -- mimics git-absent / git-broken / a
# killed 2s timeout return, without any real hang (enumerate-works.sh
# precedent's Group D technique).
exit 1
FAKEGIT
chmod +x "$FAKEBIN/git"

run_sut "$REPO_K2" "$FAKEBIN" create work-910 whatever
assert_exit_eq "$_CODE" 1 "K2: create with a broken git still fails CLOSED (exit 1)"
assert_eq "$_OUT" "" "K2: create emits EMPTY stdout"

run_sut "$REPO_K2" "$FAKEBIN" locate work-910
assert_exit_zero "$_CODE" "K2: locate with the SAME broken git still exits 0 (degrade)"
assert_eq "$_OUT" "$(printf '%s\tcurrent' "$REPO_K2_ABS")" "K2: locate degrades to <cwd-abs>\tcurrent"
assert_output_contains "$_ERR" "operating in current directory" "K2: locate's stderr note accompanies the degrade"

# ===========================================================================
echo ""
echo "=== Group L: input validation -- path-confinement traversal (exit 2, no mutation) ==="

REPO_L=$(make_git_repo); CLEANUP_DIRS+=("$REPO_L")
REPO_L_ABS="$(cd "$REPO_L" && pwd -P)"

run_sut "$REPO_L" "" create "../escape" alpha
assert_exit_eq "$_CODE" 2 "L: create with a traversal <work-id> -> exit 2"
assert_eq "$_OUT" "" "L: create traversal <work-id> emits no stdout"

run_sut "$REPO_L" "" create work-981 "../escape"
assert_exit_eq "$_CODE" 2 "L: create with a traversal <name> -> exit 2"

run_sut "$REPO_L" "" create work-982 alpha --base "../escape"
assert_exit_eq "$_CODE" 2 "L: create with a traversal --base ref -> exit 2"

run_sut "$REPO_L" "" locate "../escape"
assert_exit_eq "$_CODE" 2 "L: locate with a traversal <work-id> -> exit 2"

run_sut "$REPO_L" "" locate work-983 --name "../escape"
assert_exit_eq "$_CODE" 2 "L: locate with a traversal --name -> exit 2"

run_sut "$REPO_L" "" create "work-1/../2" alpha
assert_exit_eq "$_CODE" 2 "L: create with a slash-bearing <work-id> -> exit 2"

run_sut "$REPO_L" "" create work-984 "a/b"
assert_exit_eq "$_CODE" 2 "L: create with a slash-bearing <name> -> exit 2"

if [[ -d "${REPO_L_ABS}/.claude/worktrees" ]] && [[ -n "$(find "${REPO_L_ABS}/.claude/worktrees" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    fail "L: no worktree should exist after any rejected traversal call"
else
    pass "L: no worktree directory created by any rejected traversal call"
fi
BRANCH_COUNT_L="$(git -C "$REPO_L_ABS" branch --list | wc -l | tr -d ' ')"
assert_eq "$BRANCH_COUNT_L" "1" "L: only the fixture's own master branch exists (no branch created by any rejected call)"

# ===========================================================================
echo ""
echo "=== Group M: contract surface (help / unknown operation / missing positional) ==="

HELP_OUT=$(bash "$SUT" --help 2>&1); HELP_CODE=$?
assert_exit_zero "$HELP_CODE" "M: --help exits 0"
assert_output_contains "$HELP_OUT" "worktree-lifecycle.sh" "M: --help identifies the tool"
assert_output_contains "$HELP_OUT" "create <work-id> <name>" "M: --help documents the create usage"
assert_output_contains "$HELP_OUT" "locate <work-id>" "M: --help documents the locate usage"

code=0; bash "$SUT" bogus-op >/dev/null 2>&1 || code=$?
assert_exit_eq "$code" 2 "M: unknown operation -> exit 2"

code=0; bash "$SUT" >/dev/null 2>&1 || code=$?
assert_exit_eq "$code" 2 "M: no operation given -> exit 2"

code=0; bash "$SUT" create >/dev/null 2>&1 || code=$?
assert_exit_eq "$code" 2 "M: create with no positionals -> exit 2"

code=0; bash "$SUT" create work-990 >/dev/null 2>&1 || code=$?
assert_exit_eq "$code" 2 "M: create missing <name> -> exit 2"

code=0; bash "$SUT" locate >/dev/null 2>&1 || code=$?
assert_exit_eq "$code" 2 "M: locate with no positional -> exit 2"

# ===========================================================================
echo ""
echo "=== Group N: prose-ref (worktree-lifecycle.md) -- host-switch + cwd-fallback (AC4) ==="

assert_file_exists "$DOC" "N: worktree-lifecycle.md exists"
assert_file_contains "$DOC" "EnterWorktree" "N: doc names the claude-code EnterWorktree agent tool"
assert_file_contains "$DOC" "agent tool" "N: doc frames EnterWorktree as an agent tool (harness primitive)"
assert_file_contains "$DOC" "never shell out" "N: doc states skills instruct the agent to switch, never shell out to it"
assert_file_contains "$DOC" "operating with the resolved path as the working directory" "N: doc documents the cwd-fallback for hosts without a native switch"
assert_file_contains "$DOC" "Working in worktree:" "N: doc documents the surfaced-path fallback message"
assert_file_contains "$DOC" "Enter is an agent action, never a script call." "N: doc states enter is an agent action, never a script call"
assert_file_contains "$DOC" "feature-002 work-starting automation" "N: consumption contract names feature-002"
assert_file_contains "$DOC" "feature-003 downstream locate-and-enter" "N: consumption contract names feature-003"
assert_file_contains "$DOC" 'feature-004 `aid-housekeep` teardown' "N: consumption contract names feature-004"

# ===========================================================================
echo ""
echo "=== Group O: create -- rung 2 (branch-only recreate) ==="

REPO_O=$(make_git_repo); CLEANUP_DIRS+=("$REPO_O")
REPO_O_ABS="$(cd "$REPO_O" && pwd -P)"
TMPWT_O_PARENT=$(mktemp -d); CLEANUP_DIRS+=("$TMPWT_O_PARENT")
TMPWT_O="${TMPWT_O_PARENT}/tmpwt-606"
git -C "$REPO_O_ABS" branch work-606 master
git -C "$REPO_O_ABS" worktree add -q "$TMPWT_O" work-606
echo "committed content" > "$TMPWT_O/committed.txt"
git -C "$TMPWT_O" add -A
git -C "$TMPWT_O" commit -q -m "add committed.txt on work-606"
BRANCH_TIP_O_BEFORE="$(git -C "$REPO_O_ABS" rev-parse work-606)"
MASTER_TIP_O="$(git -C "$REPO_O_ABS" rev-parse master)"
git -C "$REPO_O_ABS" worktree remove --force "$TMPWT_O" 2>/dev/null || rm -rf "$TMPWT_O"
git -C "$REPO_O_ABS" worktree prune

run_sut "$REPO_O" "" create work-606 theta
assert_exit_zero "$_CODE" "O: create rung2 branch-only recreate exits 0"
PATH_O="$_OUT"
if [[ -n "$PATH_O" ]]; then pass "O: create rung2 recreate produced a non-empty path"; else fail "O: create rung2 recreate produced a non-empty path"; fi
assert_eq "$(basename "$PATH_O")" "work-606-theta" "O: worktree dir composed as <work-id>-<name> (create always uses the passed name, unlike locate's bare-<work-id> fallback)"
assert_file_exists "${PATH_O}/committed.txt" "O: committed file preserved into the recreated worktree (NFR3)"
assert_eq "$(git -C "$PATH_O" symbolic-ref --short HEAD)" "work-606" "O: recreated worktree is on branch work-606"
BRANCH_TIP_O_AFTER="$(git -C "$REPO_O_ABS" rev-parse work-606)"
assert_eq "$BRANCH_TIP_O_AFTER" "$BRANCH_TIP_O_BEFORE" "O: branch tip unchanged across recreate (no re-branch -- the EXISTING branch was reused, not recreated)"
if [[ "$BRANCH_TIP_O_AFTER" == "$MASTER_TIP_O" ]]; then
    fail "O: branch tip must differ from master's tip (else the committed.txt commit was lost / branch was force-reset off --base)"
else
    pass "O: branch tip differs from master's tip (the committed.txt commit is genuinely preserved, not rebuilt off --base)"
fi
WT_COUNT_O="$(git -C "$REPO_O_ABS" worktree list --porcelain | grep -c '^branch refs/heads/work-606$')"
assert_eq "$WT_COUNT_O" "1" "O: exactly ONE worktree registered for branch work-606 after recreate (no duplicate)"

run_sut "$REPO_O" "" create work-606 theta
assert_exit_zero "$_CODE" "O: subsequent create re-run exits 0"
assert_eq "$_OUT" "$PATH_O" "O: subsequent create re-run re-prints the byte-identical path (now resolved via rung 1, not rung 2 again)"

# ===========================================================================
echo ""
echo "=== Group P: create -- rung 4 (already-inside no-op) + already-registered no-op ==="

REPO_P=$(make_git_repo); CLEANUP_DIRS+=("$REPO_P")
REPO_P_ABS="$(cd "$REPO_P" && pwd -P)"

run_sut "$REPO_P" "" create work-333 kappa
assert_exit_zero "$_CODE" "P: initial create exits 0"
PATH_P="$_OUT"
WT_COUNT_P_BEFORE="$(git -C "$REPO_P_ABS" worktree list --porcelain | grep -c '^worktree ')"
BRANCH_COUNT_P_BEFORE="$(git -C "$REPO_P_ABS" branch --list | wc -l | tr -d ' ')"

# P1: re-run from OUTSIDE the worktree (already registered) -- rung 1 no-op.
run_sut "$REPO_P" "" create work-333 kappa
assert_exit_zero "$_CODE" "P1: outside re-run (already registered) exits 0"
assert_eq "$_OUT" "$PATH_P" "P1: outside re-run re-prints the existing path"

# P2: re-run with cwd ALREADY INSIDE the target worktree -- rung 4 no-op, the
# code path at op_create's cur_branch==work_id check (lines ~264-279), which
# is checked BEFORE rung 1's own no-op and is otherwise wholly uncovered.
run_sut "$PATH_P" "" create work-333 kappa
assert_exit_zero "$_CODE" "P2: cwd-inside re-run exits 0 (rung4 no-op)"
assert_eq "$_OUT" "$PATH_P" "P2: cwd-inside re-run re-prints the existing path (byte-identical)"

# P3: cwd-inside re-run with a DIFFERENT <name> -- rung4 short-circuits on
# cur_branch alone (before rung1's name-mismatch check ever runs), so the
# differing name is silently ignored AND no "ignoring differing name" stderr
# note is emitted (that note is rung1-only) -- proves rung4, not rung1, ran.
run_sut "$PATH_P" "" create work-333 differentname
assert_exit_zero "$_CODE" "P3: cwd-inside re-run with a DIFFERENT name still exits 0 (rung4 no-op, name irrelevant)"
assert_eq "$_OUT" "$PATH_P" "P3: cwd-inside re-run with a different name re-prints the SAME existing path"
assert_output_not_contains "$_ERR" "ignoring differing name" "P3: no rung1 differing-name note emitted (confirms rung4's short-circuit ran, not rung1)"

# No no-op re-run (outside or inside, same name or different) may register a
# second worktree or create a second branch.
WT_COUNT_P_AFTER="$(git -C "$REPO_P_ABS" worktree list --porcelain | grep -c '^worktree ')"
assert_eq "$WT_COUNT_P_AFTER" "$WT_COUNT_P_BEFORE" "P: worktree count unchanged across every no-op re-run (no duplicate worktree)"
BRANCH_COUNT_P_AFTER="$(git -C "$REPO_P_ABS" branch --list | wc -l | tr -d ' ')"
assert_eq "$BRANCH_COUNT_P_AFTER" "$BRANCH_COUNT_P_BEFORE" "P: branch count unchanged across every no-op re-run (no duplicate branch)"

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
