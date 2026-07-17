#!/usr/bin/env bash
# test-work-initiation-gate.sh -- unit suite for the Work Initiation Gate.
#
# SUT (unit-testable core of the gate):
#   canonical/aid/scripts/works/enumerate-works.sh  -- the shared enumeration
#   helper every work-starter runs before it allocates. It answers "what works
#   already exist?" across the main tree AND every git worktree, emitting one
#   TAB-separated record per work:
#       <work_id>\t<phase>\t<lifecycle>\t<branch_label>\t<title>
#   An EMPTY stdout is the gate's "no works anywhere -> proceed as NEW, no
#   prompt" signal. Any git failure degrades to a main-tree-only enumeration and
#   still exits 0 (never fails the starter).
#
# Gate reference (prose contract the routing depends on):
#   canonical/aid/templates/work-initiation-gate.md
#
# What this suite asserts (mapped to task-006 / SPEC ACs):
#   Group A  empty -> NEW (no prompt):     SPEC AC-8   (absent + present-but-empty)
#   Group B  non-empty -> enumerated:      SPEC AC-7/AC-9 (main tree + git worktree,
#                                          full 5-field record, name-independent)
#   Group C  continuation -> routing:      SPEC AC-10  (phase/lifecycle fields the
#                                          gate's route-per-phase decision needs)
#   Group D  degradation:                  SPEC AC-11  (non-git dir / git failure /
#                                          timeout -> main-tree-only, exit 0)
#   Group E  helper arg/contract surface   (exit codes 0/2, --help)
#   Group F  gate-doc structure:           SPEC AC-9/AC-10 (empty->new / non-empty
#                                          ->ask / continuation->route branches)
#   Group G  starter coverage:             SPEC AC-11  (all TEN affected starters
#                                          consult the shared gate)
#
# Fail-pre / pass-post contract:
#   These tests pass against the POST-task-005 tree (the shared helper + gate
#   reference now exist). Pre-fix there was no work-initiation gate at all -- the
#   shortcut engine always allocated a brand-new work, `aid-describe` auto-
#   continued a lone unapproved work, and the other starters allocated
#   unconditionally -- so there was no shared enumeration/prompt/routing to
#   satisfy any assertion below: the SUT path would not exist (Group A-E red),
#   the gate reference would be absent (Group F red), and no starter would cite
#   it (Group G red). The suite therefore establishes the gate's contract by
#   construction rather than by mutating known-good code back to a broken state.
#
# Usage:
#   test-work-initiation-gate.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed
#
# Local-test constraints honored: every fixture is a throwaway mktemp scratch
# dir (+ a temp `git worktree add`), cleaned up on exit. No port binding, no
# real 2s-timeout wait (the timeout trigger collapses onto the SAME degrade
# branch as a git-command failure -- `porcelain=""` -> main-tree-only -- which
# Group D exercises with an immediately-failing fake git, so no hang-prone real
# timeout is spun). Auto-wired into tests/run-all.sh by the test-*.sh glob.

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/canonical/aid/scripts/works/enumerate-works.sh"
GATE_DOC="${REPO_ROOT}/canonical/aid/templates/work-initiation-gate.md"

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
        # since we rm -rf the whole scratch tree (parent repo included) those
        # entries vanish with it -- no `git worktree remove` needed.
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d" 2>/dev/null || true
    done
}
trap cleanup_all EXIT

# make_git_repo -> path to a fresh throwaway git repo on branch `master`.
make_git_repo() {
    local repo
    repo=$(mktemp -d)
    git -C "$repo" init -q --initial-branch=master 2>/dev/null \
        || { git -C "$repo" init -q; git -C "$repo" checkout -q -b master 2>/dev/null || true; }
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    echo "$repo"
}

# make_work <repo_root> <work_id> <phase> <lifecycle> <title> [delivery_state]
# Creates a work as a direct subfolder of <repo_root>/.aid/works/ with a
# frontmatter STATE.md (phase/lifecycle -- the routing inputs the helper reads
# via its `_frontmatter_value`) and a REQUIREMENTS.md carrying the `**Name:**`
# identity line (the title source `_work_title` reads).
make_work() {
    local base="$1" wid="$2" phase="$3" lifecycle="$4" title="$5" dstate="${6:-}"
    local wd="$base/.aid/works/$wid"
    mkdir -p "$wd"
    {
        echo "---"
        echo "phase: $phase"
        echo "lifecycle: $lifecycle"
        [[ -n "$dstate" ]] && echo "delivery_state: $dstate"
        echo "updated: '2026-07-17T00:00:00Z'"
        echo "---"
        echo ""
        echo "# Work State -- $wid"
    } > "$wd/STATE.md"
    printf -- '- **Name:** %s\n' "$title" > "$wd/REQUIREMENTS.md"
}

# run_sut <root> [extra PATH prefix] -> populates _OUT/_ERR/_CODE globals.
# Captures stdout and stderr separately so an empty-stdout "-> NEW" signal is
# never contaminated by a stderr degradation note.
run_sut() {
    local root="$1" path_prefix="${2:-}"
    local errf; errf=$(mktemp)
    if [[ -n "$path_prefix" ]]; then
        _OUT=$(PATH="$path_prefix:$PATH" bash "$SUT" --root "$root" 2>"$errf"); _CODE=$?
    else
        _OUT=$(bash "$SUT" --root "$root" 2>"$errf"); _CODE=$?
    fi
    _ERR=$(cat "$errf"); rm -f "$errf"
}

# record_for <output> <work_id> <branch_label> -> the matching TAB record line(s).
record_for() {
    awk -F'\t' -v id="$2" -v lbl="$3" '$1==id && $4==lbl { print }' <<<"$1"
}

# field <record_line> <n> -> the nth TAB field.
field() { awk -F'\t' -v n="$2" '{ print $n }' <<<"$1"; }

# count_records <output> -> number of non-empty record lines (0 for empty stdout).
count_records() { printf '%s' "$1" | grep -c '.' || true; }

# nfields <record_line> -> TAB field count.
nfields() { awk -F'\t' '{ print NF }' <<<"$1"; }

# ===========================================================================
echo ""
echo "=== Group A: empty / absent .aid/works/ -> NEW, no prompt (SPEC AC-8) ==="

# A1: absent .aid/works/ (dir never created) in a real git repo -> empty stdout, exit 0.
REPO_A1=$(make_git_repo); CLEANUP_DIRS+=("$REPO_A1")
run_sut "$REPO_A1"
assert_exit_zero "$_CODE" "A1: absent .aid/works/ exits 0"
assert_eq "$_OUT" "" "A1: absent .aid/works/ emits NO records (the 'proceed as NEW, no prompt' signal)"

# A2: present-but-empty .aid/works/ -> still empty stdout, exit 0.
REPO_A2=$(make_git_repo); CLEANUP_DIRS+=("$REPO_A2")
mkdir -p "$REPO_A2/.aid/works"
run_sut "$REPO_A2"
assert_exit_zero "$_CODE" "A2: empty .aid/works/ exits 0"
assert_eq "$_OUT" "" "A2: empty .aid/works/ emits NO records (NEW, no prompt)"

# ===========================================================================
echo ""
echo "=== Group B: non-empty -> enumerated across main tree + worktree (SPEC AC-7/AC-9) ==="

REPO_B=$(make_git_repo); CLEANUP_DIRS+=("$REPO_B")
# Two works in the MAIN tree, one numberless (proves discovery is name-independent, FR-2).
make_work "$REPO_B" "work-100-alpha" "Plan"    "Running" "Alpha Orders API"
make_work "$REPO_B" "hotfix-login"   "Execute" "Running" "Login Hotfix"
git -C "$REPO_B" add -A >/dev/null 2>&1
git -C "$REPO_B" commit -q -m "seed main-tree works"

# Add a real git worktree on a NEW branch and put a third (uncommitted) work in it.
WT_B="$(mktemp -d)/beta-wt"; CLEANUP_DIRS+=("$(dirname "$WT_B")")
git -C "$REPO_B" worktree add -q "$WT_B" -b feature-wt 2>/dev/null; wt_code=$?
assert_exit_zero "$wt_code" "B0: git worktree add succeeded (worktree fixture available)"
make_work "$WT_B" "work-200-beta" "Specify" "Running" "Beta Billing"

run_sut "$REPO_B"
assert_exit_zero "$_CODE" "B: enumeration exits 0"

# Committed works (work-100-alpha, hotfix-login) are present on BOTH branches;
# the uncommitted work-200-beta exists only in the feature-wt worktree. The
# helper is the ENUMERATE layer (no reconcile) so a committed work appears once
# per branch label. Expected: master{hotfix-login, work-100-alpha} +
# feature-wt{hotfix-login, work-100-alpha, work-200-beta} = 5 records.
assert_eq "$(count_records "$_OUT")" "5" "B: five records (2 main + 3 worktree, enumerate-layer duplication)"

# Main tree is listed first (reader ordering); within a root, lexicographic by id.
first_line=$(printf '%s\n' "$_OUT" | sed -n '1p')
assert_eq "$(field "$first_line" 1)" "hotfix-login" "B: first record's work_id is the lexicographically-first main-tree work"
assert_eq "$(field "$first_line" 4)" "master"       "B: first record is from the main tree (main worktree ordered first)"

# work-100-alpha appears under BOTH branch labels.
rec_main=$(record_for "$_OUT" "work-100-alpha" "master")
rec_wt=$(record_for "$_OUT" "work-100-alpha" "feature-wt")
assert_output_contains "$rec_main" "work-100-alpha" "B: work-100-alpha enumerated on main tree (label master)"
assert_output_contains "$rec_wt"   "work-100-alpha" "B: work-100-alpha enumerated on the git worktree (label feature-wt)"

# The full 5-field record contract: id / phase / lifecycle / branch_label / title.
assert_eq "$(nfields "$rec_main")" "5"                "B: record is exactly 5 TAB-separated fields"
assert_eq "$(field "$rec_main" 1)" "work-100-alpha"   "B: field 1 = work_id"
assert_eq "$(field "$rec_main" 2)" "Plan"             "B: field 2 = phase (from STATE.md frontmatter)"
assert_eq "$(field "$rec_main" 3)" "Running"          "B: field 3 = lifecycle (from STATE.md frontmatter)"
assert_eq "$(field "$rec_main" 4)" "master"           "B: field 4 = branch_label"
assert_eq "$(field "$rec_main" 5)" "Alpha Orders API" "B: field 5 = title (from REQUIREMENTS.md **Name:**)"

# The numberless work is discovered (name-independent enumeration, FR-2).
rec_hotfix=$(record_for "$_OUT" "hotfix-login" "master")
assert_output_contains "$rec_hotfix" "Login Hotfix" "B: numberless 'hotfix-login' work is enumerated (name-independent)"

# The worktree-only work is present under feature-wt and NOT under master.
rec_beta_wt=$(record_for "$_OUT" "work-200-beta" "feature-wt")
rec_beta_main=$(record_for "$_OUT" "work-200-beta" "master")
assert_output_contains "$rec_beta_wt" "work-200-beta" "B: worktree-only work-200-beta enumerated under feature-wt"
assert_eq "$rec_beta_main" "" "B: work-200-beta (uncommitted) is NOT present on the main tree"

# ===========================================================================
echo ""
echo "=== Group C: continuation -> routing inputs present (SPEC AC-10) ==="

# The routing itself is prose in the gate reference (asserted in Group F). Here
# we assert the FIELD CONTRACT the routing depends on: the helper surfaces each
# work's phase + lifecycle so the gate's route-per-phase decision is derivable.
REPO_C=$(make_git_repo); CLEANUP_DIRS+=("$REPO_C")
# A flattened Lite work halted at the shortcut engine's APPROVAL-HALT ->
# gate routes to `/aid-execute` (keys on lifecycle + delivery_state).
make_work "$REPO_C" "work-300-halted"  "Specify" "Paused-Awaiting-Input" "Halted Lite Work" "Specified"
# A partial full-path work still in a definition phase -> gate routes to the
# phase skill matching STATE.md `phase` (here `Plan` -> `/aid-plan`).
make_work "$REPO_C" "work-400-partial" "Plan"    "Running"               "Partial Full-path Work"

run_sut "$REPO_C"
assert_exit_zero "$_CODE" "C: enumeration exits 0"

rec_halt=$(record_for "$_OUT" "work-300-halted" "master")
assert_eq "$(field "$rec_halt" 3)" "Paused-Awaiting-Input" \
    "C: halted-work lifecycle surfaced (the field the /aid-execute route keys on)"
assert_eq "$(field "$rec_halt" 2)" "Specify" \
    "C: halted-work phase surfaced alongside lifecycle"

rec_partial=$(record_for "$_OUT" "work-400-partial" "master")
assert_eq "$(field "$rec_partial" 2)" "Plan" \
    "C: partial full-path work's phase surfaced (routes to the phase skill /aid-plan)"
assert_eq "$(field "$rec_partial" 3)" "Running" \
    "C: partial full-path work's lifecycle surfaced"

# ===========================================================================
echo ""
echo "=== Group D: degradation -> main-tree-only, never fail the starter (SPEC AC-11) ==="

# D1: a NON-git directory. `git rev-parse` fails -> no worktree enumeration ->
# degrade to main-tree-only. Still lists the work; still exits 0.
DIR_D1=$(mktemp -d); CLEANUP_DIRS+=("$DIR_D1")
make_work "$DIR_D1" "work-500-gamma" "Execute" "Running" "Gamma In A Non-Git Dir"
run_sut "$DIR_D1"
assert_exit_zero "$_CODE" "D1: non-git dir still exits 0 (never fail the starter)"
rec_gamma=$(record_for "$_OUT" "work-500-gamma" "main")
assert_output_contains "$rec_gamma" "work-500-gamma" "D1: non-git dir degrades to main-tree-only enumeration (work still listed)"
assert_eq "$(field "$rec_gamma" 4)" "main" "D1: branch_label falls back to the literal 'main' when git is unavailable"
assert_output_contains "$_ERR" "scanning main tree only" "D1: a one-line degradation note is emitted to stderr (not stdout)"
# The degradation note must NOT leak into the record stream on stdout.
assert_output_not_contains "$_OUT" "scanning main tree only" "D1: stderr diagnostics never mix into stdout records"

# D2: git present on disk but FAILING (shadowed by a fake git that always exits
# non-zero) -- the "git absent / git broken" case, which the helper treats
# identically to a `timeout` (any non-zero from the bounded call -> degrade).
FAKEBIN=$(mktemp -d); CLEANUP_DIRS+=("$FAKEBIN")
cat > "$FAKEBIN/git" <<'FAKEGIT'
#!/usr/bin/env bash
# Fake git: always fails, mimicking git-absent / git-broken / a killed 2s
# timeout return -- every one collapses onto the helper's degrade branch.
exit 1
FAKEGIT
chmod +x "$FAKEBIN/git"
DIR_D2=$(mktemp -d); CLEANUP_DIRS+=("$DIR_D2")
make_work "$DIR_D2" "work-600-delta" "Plan" "Running" "Delta Under Broken Git"
run_sut "$DIR_D2" "$FAKEBIN"
assert_exit_zero "$_CODE" "D2: git failure/absence still exits 0"
rec_delta=$(record_for "$_OUT" "work-600-delta" "main")
assert_output_contains "$rec_delta" "work-600-delta" "D2: git failure degrades to main-tree-only (work still listed)"
assert_output_contains "$_ERR" "scanning main tree only" "D2: degradation note emitted on git failure"

# ===========================================================================
echo ""
echo "=== Group E: helper argument / contract surface ==="

# E1: --help exits 0 and documents the record shape + degrade contract.
help_out=$(bash "$SUT" --help 2>&1); help_code=$?
assert_exit_zero "$help_code" "E1: --help exits 0"
assert_output_contains "$help_out" "enumerate-works.sh" "E1: --help identifies the tool"

# E2: unknown flag -> argument error (exit 2).
code_e2=0; bash "$SUT" --bogus-flag >/dev/null 2>&1 || code_e2=$?
assert_exit_eq "$code_e2" 2 "E2: unknown flag -> exit 2"

# E3: --root with no value -> argument error (exit 2).
code_e3=0; bash "$SUT" --root >/dev/null 2>&1 || code_e3=$?
assert_exit_eq "$code_e3" 2 "E3: --root without a value -> exit 2"

# ===========================================================================
echo ""
echo "=== Group F: gate reference documents the three branches + routing (SPEC AC-9/AC-10) ==="

assert_file_exists "$GATE_DOC" "F: work-initiation-gate.md exists (the shared front-door reference)"
# empty -> NEW branch
assert_file_contains "$GATE_DOC" "NEW, no prompt" "F: doc documents the empty -> NEW (no prompt) branch"
# non-empty -> ASK branch
assert_file_contains "$GATE_DOC" "One or more works exist" "F: doc documents the non-empty -> ASK branch"
# continuation -> route branch + routing targets
assert_file_contains "$GATE_DOC" "CONTINUATION" "F: doc documents the continuation branch"
assert_file_contains "$GATE_DOC" "/aid-execute" "F: routing table names the /aid-execute resume target (halted / mid-Execute work)"
assert_file_contains "$GATE_DOC" "/aid-plan"    "F: routing table names a phase-skill resume target (partial full-path work)"
# field contract the routing consumes
assert_file_contains "$GATE_DOC" "enumerate-works.sh" "F: doc points starters at the shared enumeration helper"
assert_file_contains "$GATE_DOC" '<work_id>\t<phase>\t<lifecycle>\t<branch_label>\t<title>' \
    "F: doc documents the 5-field record contract the gate consumes"

# ===========================================================================
echo ""
echo "=== Group G: all TEN affected work-starters consult the shared gate (SPEC AC-11) ==="

# Each starter references the gate at its allocation point rather than
# re-implementing the new-vs-continuation logic.
STARTERS=(
    "canonical/aid/templates/shortcut-engine.md"          # shortcut-engine INTAKE (all shortcuts)
    "canonical/skills/aid-describe/SKILL.md"
    "canonical/skills/aid-review/SKILL.md"
    "canonical/skills/aid-research/SKILL.md"
    "canonical/skills/aid-design/SKILL.md"
    "canonical/skills/aid-report/SKILL.md"
    "canonical/skills/aid-test/SKILL.md"
    "canonical/skills/aid-prototype/SKILL.md"
    "canonical/skills/aid-create-document/SKILL.md"
    "canonical/skills/aid-change-document/SKILL.md"
)
assert_eq "${#STARTERS[@]}" "10" "G: exactly ten affected work-starters under coverage"
for rel in "${STARTERS[@]}"; do
    f="${REPO_ROOT}/${rel}"
    if [[ -f "$f" ]]; then
        assert_file_contains "$f" "work-initiation-gate.md" "G: ${rel} consults the shared gate"
    else
        fail "G: starter file missing: ${rel}"
    fi
done

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
