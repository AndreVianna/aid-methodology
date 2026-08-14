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
# What this suite asserts (mapped to task-006 / SPEC ACs, plus the work-018
# feature-002 worktree-automation extensions added by work-018 task-005):
#   Group A  empty -> NEW (no prompt):     SPEC AC-8   (absent + present-but-empty)
#   Group B  non-empty -> enumerated:      SPEC AC-7/AC-9 (main tree + git worktree,
#                                          full 5-field record, name-independent)
#   Group C  continuation -> routing:      SPEC AC-10  (phase/lifecycle fields the
#                                          gate's route-per-phase decision needs)
#   Group D  degradation:                  SPEC AC-11  (non-git dir / git failure /
#                                          timeout -> main-tree-only, exit 0)
#   Group E  helper arg/contract surface   (exit codes 0/2, --help)
#   Group F  gate-doc structure:           SPEC AC-9/AC-10 (empty->new / non-empty
#                                          ->ask / continuation->route branches),
#                                          extended (work-018 feature-002) with the
#                                          § 3a create+enter / § 3b locate+enter
#                                          sub-steps, the create-failure guard, the
#                                          create-before-allocate file-order
#                                          invariant, the cross-worktree
#                                          next-number source, and a regression
#                                          guard that § 3b never mislabels
#                                          `locate` as fail-closed/exit-1
#   Group G  starter coverage:             SPEC AC-11  (all TEN affected starters
#                                          consult the shared gate), extended
#                                          (work-018 feature-002) with each
#                                          starter's own worktree-create reference
#                                          and its create-before-allocate file-order
#                                          invariant
#   Reconciliation  aid-review's now-mandatory work-level worktree (FR1) vs.
#                   aid-research/aid-prototype's surviving SPIKE-only opt-in
#                   worktree sentences (work-018 feature-002)
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
#   The Group F/G worktree-wiring extensions and the Reconciliation group (added
#   by work-018 task-005) pass against the tree wired by work-018 task-003/004
#   (`worktree-lifecycle.sh create`/`locate` threaded through the gate doc and
#   all ten starters); pre-task-003/004 none of those references existed either.
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

# --- Group F extensions: §3a create+enter / §3b locate+enter worktree wiring
# (feature-002 SPEC § Testing). ---
assert_file_contains "$GATE_DOC" "### 3a" "F: doc documents the § 3a create+enter sub-step"
assert_file_contains "$GATE_DOC" "### 3b" "F: doc documents the § 3b locate+enter sub-step"
assert_file_contains "$GATE_DOC" "worktree-lifecycle.sh create" "F: doc names worktree-lifecycle.sh create"
assert_file_contains "$GATE_DOC" "worktree-lifecycle.sh locate" "F: doc names worktree-lifecycle.sh locate"
assert_file_contains "$GATE_DOC" "Create-failure guard" "F: doc documents § 3a's create-failure guard"

# create-before-allocate ordering: the `create` mention precedes the STATE.md-scaffold
# mention in file order (§ 3a Feature Flow -- number resolution + create+enter happen
# BEFORE the work folder + STATE.md are authored).
#
# Coverage-key discipline (`FF01-gate-doc`): the two line NUMBERS below are genuine
# diagnostics but must NOT reach the coverage-parity key, or any unrelated edit to
# work-initiation-gate.md re-keys this assertion. A leading multi-letter ID token
# fixes that: normalize_key (tests/coverage-parity.sh:136) takes
# `^[A-Za-z][A-Za-z]+[0-9][A-Za-z0-9._-]*` as the WHOLE key and discards the rest of
# the label, so the line numbers stay visible in the log and out of the key. The
# token is repeated on all four branches so a pass->fail flip keeps ONE key (the tool
# counts EXECUTION, not correctness -- coverage-parity.sh:48-52). Note the digit must
# come immediately after the letters: a hyphen before it (`FF-01`) defeats step 2 and
# falls through to whole-label masking, which is exactly the defect being repaired.
gate_create_line=$(grep -nF -- "worktree-lifecycle.sh create <work-id> <name>" "$GATE_DOC" | head -1 | cut -d: -f1)
gate_scaffold_line=$(grep -nF -- 'scaffold `STATE.md`' "$GATE_DOC" | head -1 | cut -d: -f1)
if [[ -z "$gate_create_line" ]]; then
    fail "FF01-gate-doc — F: 'worktree-lifecycle.sh create <work-id> <name>' mention not found"
elif [[ -z "$gate_scaffold_line" ]]; then
    fail "FF01-gate-doc — F: 'scaffold \`STATE.md\`' mention not found"
elif [[ "$gate_create_line" -lt "$gate_scaffold_line" ]]; then
    pass "FF01-gate-doc — F: § 3a create mention (line $gate_create_line) precedes the STATE.md-scaffold mention (line $gate_scaffold_line)"
else
    fail "FF01-gate-doc — F: § 3a create mention (line $gate_create_line) does NOT precede the STATE.md-scaffold mention (line $gate_scaffold_line)"
fi

assert_file_contains "$GATE_DOC" "Never** re-scan a local" \
    "F: § 3a's next-number source is the cross-worktree enumeration, not a local .aid/works/ glob"

# § 3b regression guard: locate's guard is framed as a defensive backstop, and § 3b never
# describes `locate` itself as fail-closed / exit-1 (feature-001's FROZEN contract: locate
# always exits 0, degrading to a non-empty `<cwd-abs>\tcurrent`).
assert_file_contains "$GATE_DOC" "Defensive backstop (NOT fail-closed)" \
    "F: § 3b frames its locate guard as a defensive backstop, NOT fail-closed"
section_3b=$(awk '/^### 3b\./{flag=1} /^## Invariant/{flag=0} flag' "$GATE_DOC")
assert_output_not_contains "$section_3b" "(fail-closed):**" \
    "F: § 3b does NOT mislabel locate's guard as fail-closed (regression guard)"
assert_output_contains "$section_3b" "exits 0 on every resolution" \
    "F: § 3b documents locate's exits-0-always contract (never fail-closed)"

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
    # feature-003 moved the document-editing starter: its directory was deleted and the body
    # promoted into aid-update-document/. One element's VALUE moves; the array's length does
    # not -- nothing is added or removed, so the "10" below is re-checked and kept, not stale.
    # Its twin binding in STARTER_ALLOC_ANCHOR below must move with it.
    "canonical/skills/aid-update-document/SKILL.md"
)
assert_eq "${#STARTERS[@]}" "10" "G: exactly ten affected work-starters under coverage"

# Per-starter anchor for the create-before-allocate ordering check below: the first line,
# after the `worktree-lifecycle.sh create` mention, that is this starter's own
# STATE.md-scaffold / work-folder-allocation line (wording differs per starter -- some
# name `STATE.md` literally, some fold the allocation into a single "**then** allocate ("
# clause; each anchor here is verified unique-enough to sit strictly after its file's first
# `create` mention).
declare -A STARTER_ALLOC_ANCHOR=(
    ["canonical/aid/templates/shortcut-engine.md"]="### Step 4: Scaffold STATE.md"
    ["canonical/skills/aid-describe/SKILL.md"]="create \`.aid/works/work-001-{name}/\`"
    ["canonical/skills/aid-review/SKILL.md"]="STATE.md"
    ["canonical/skills/aid-research/SKILL.md"]="STATE.md"
    ["canonical/skills/aid-design/SKILL.md"]="**then** allocate (\`"
    ["canonical/skills/aid-report/SKILL.md"]="**then** allocate (\`"
    ["canonical/skills/aid-test/SKILL.md"]="**then** allocate (\`"
    ["canonical/skills/aid-prototype/SKILL.md"]="**then** allocate (\`"
    ["canonical/skills/aid-create-document/SKILL.md"]="**then** allocate (\`"
    ["canonical/skills/aid-update-document/SKILL.md"]="**then** allocate (\`"
)

# Per-starter coverage ID for the ordering check below -- the token that gives each
# starter its OWN stable coverage-parity key.
#
# Why this map exists: the ordering assertion's natural label carries the starter path
# plus the two matched line numbers, and normalize_key masks the path to `<PATH>`
# (tests/coverage-parity.sh:158-159) while leaving the NUMBERS intact. The ten starters
# were therefore distinguished in the coverage inventory ONLY by their line-number
# pairs, which has two consequences, both observed:
#   * any unrelated `canonical/` edit re-keys the assertion (measured: aid-review
#     103/111 -> 104/112 and aid-research 64/68 -> 62/66 at 69133fcf, shortcut-engine
#     283/300 -> 281/298 at bc40b7ef -- 3 REMOVED + 3 ADDED, none of it a real
#     coverage change); and
#   * two starters that happened to match at the SAME line pair would collapse into
#     one key, so the inventory would silently read 9 starters instead of 10.
# Leading each label with a multi-letter ID token makes normalize_key's step 2
# (coverage-parity.sh:136) take `GGnn-<starter>` as the WHOLE key and discard the rest,
# so starter IDENTITY distinguishes the keys and the line numbers remain in the log for
# diagnostics only. The digit must follow the letters IMMEDIATELY -- `GG-01` would put a
# hyphen before it, defeat step 2, and fall back to whole-label masking.
#
# Keyed by starter PATH, not by array position, so re-ordering STARTERS is key-neutral.
# When a starter's identity genuinely MOVES (as feature-003 moved the document-editing
# starter into aid-update-document/), its slug moves with it and the re-key is the
# intended signal that a different file is now under test.
declare -A STARTER_COVERAGE_ID=(
    ["canonical/aid/templates/shortcut-engine.md"]="GG01-shortcut-engine"
    ["canonical/skills/aid-describe/SKILL.md"]="GG02-aid-describe"
    ["canonical/skills/aid-review/SKILL.md"]="GG03-aid-review"
    ["canonical/skills/aid-research/SKILL.md"]="GG04-aid-research"
    ["canonical/skills/aid-design/SKILL.md"]="GG05-aid-design"
    ["canonical/skills/aid-report/SKILL.md"]="GG06-aid-report"
    ["canonical/skills/aid-test/SKILL.md"]="GG07-aid-test"
    ["canonical/skills/aid-prototype/SKILL.md"]="GG08-aid-prototype"
    ["canonical/skills/aid-create-document/SKILL.md"]="GG09-aid-create-document"
    ["canonical/skills/aid-update-document/SKILL.md"]="GG10-aid-update-document"
)

# Collision-proofness is ENFORCED here, not merely asserted in prose: an ID that is
# missing (empty) or duplicated drops the distinct non-empty count below ten and reds
# this assertion, instead of silently merging two starters into one coverage key.
#
# This one oracle covers ALL THREE per-starter assertions in the loop below, not just the
# ordering one: the other two key off `${sid}-consults` / `${sid}-create-mention`, which
# are derived from the same `sid`, so distinctness of the ten `sid` values implies
# distinctness of their suffixed forms. Nothing further is needed for them, and nothing
# below may key off the starter PATH alone -- normalize_key masks a path to `<PATH>`, so a
# path-only label collapses all ten starters into a single key.
G_COVERAGE_IDS=()
for rel in "${STARTERS[@]}"; do
    G_COVERAGE_IDS+=("${STARTER_COVERAGE_ID[$rel]:-}")
done
assert_eq "$(printf '%s\n' "${G_COVERAGE_IDS[@]}" | sort -u | grep -c '.')" "10" \
    "GG00: the ten Group G ordering coverage IDs are all present and pairwise distinct"

for rel in "${STARTERS[@]}"; do
    f="${REPO_ROOT}/${rel}"
    # One ID per starter, led on EVERY outcome branch below (missing file, missing
    # anchor, either mention absent, ordering satisfied, ordering violated), so this
    # starter contributes exactly ONE coverage key whichever branch fires -- a
    # pass->fail flip must not re-key an assertion that still executed.
    sid="${STARTER_COVERAGE_ID[$rel]:-}"
    if [[ -z "$sid" ]]; then
        # Already red via GG00 above; reuse that key rather than emit an ID-less
        # (and therefore unstable) one.
        fail "GG00: ${rel} — no coverage ID configured for the ordering check"
    elif [[ -f "$f" ]]; then
        # These two carry the SAME starter identity as the ordering check, plus a
        # per-assertion suffix. A bare "${sid}" on all three would give each starter one
        # key of count 3 and lose ASSERTION identity, which is the mirror of the defect
        # being fixed; a path-only label loses STARTER identity (normalize_key masks the
        # path to `<PATH>`, collapsing all ten starters into one key of count 10). The
        # suffixed form keeps both, and step 2 takes the whole token because
        # `[A-Za-z0-9._-]*` admits the hyphens.
        assert_file_contains "$f" "work-initiation-gate.md" \
            "${sid}-consults — G: ${rel} consults the shared gate"
        assert_file_contains "$f" "worktree-lifecycle.sh create" \
            "${sid}-create-mention — G: ${rel} references the gate's worktree-create step at its allocation point"

        anchor="${STARTER_ALLOC_ANCHOR[$rel]:-}"
        create_line=$(grep -nF -- "worktree-lifecycle.sh create" "$f" | head -1 | cut -d: -f1)
        scaffold_line=$(grep -nF -- "$anchor" "$f" | head -1 | cut -d: -f1)
        if [[ -z "$anchor" ]]; then
            fail "${sid} — G: ${rel} no allocation-line anchor configured for the ordering check"
        elif [[ -z "$create_line" ]]; then
            fail "${sid} — G: ${rel} 'worktree-lifecycle.sh create' mention not found"
        elif [[ -z "$scaffold_line" ]]; then
            fail "${sid} — G: ${rel} STATE.md-scaffold/allocation line not found (anchor: '$anchor')"
        elif [[ "$create_line" -lt "$scaffold_line" ]]; then
            pass "${sid} — G: ${rel} create mention (line $create_line) precedes STATE.md-scaffold/allocation line (line $scaffold_line)"
        else
            fail "${sid} — G: ${rel} create mention (line $create_line) does NOT precede STATE.md-scaffold/allocation line (line $scaffold_line)"
        fi
    else
        fail "${sid} — G: starter file missing: ${rel}"
    fi
done

# ===========================================================================
echo ""
echo "=== Reconciliation group: aid-review mandatory / aid-research+aid-prototype spike opt-in survives ==="

AID_REVIEW="${REPO_ROOT}/canonical/skills/aid-review/SKILL.md"
AID_RESEARCH="${REPO_ROOT}/canonical/skills/aid-research/SKILL.md"
AID_PROTOTYPE="${REPO_ROOT}/canonical/skills/aid-prototype/SKILL.md"

# aid-review: the WORK-LEVEL worktree is no longer merely optional (FR1) -- its old
# "Optionally associate a git worktree ..." sentence is replaced by the mandatory gate § 3a
# create+enter.
assert_file_not_contains "$AID_REVIEW" "Optionally associate a git worktree" \
    "Recon: aid-review's old work-level opt-in worktree sentence is gone"
assert_file_contains "$AID_REVIEW" "mandatory per FR1, no longer optional" \
    "Recon: aid-review documents the work-level worktree as mandatory (FR1), not optional"
assert_file_contains "$AID_REVIEW" "gate \`§ 3a\` step 2" \
    "Recon: aid-review references gate § 3a work-level create+enter at its allocation step"

# aid-research / aid-prototype: the opposite -- their SPIKE/throwaway opt-in worktree
# sentences survive UNCHANGED (a distinct, nested concern from the now-mandatory
# work-level worktree; see the gate doc's Edge Cases), while a gate § 3a work-level
# create+enter reference is now ALSO present at their allocation step.
assert_file_contains "$AID_RESEARCH" "Associate a git worktree" \
    "Recon: aid-research's spike opt-in worktree sentence survives unchanged"
assert_file_contains "$AID_RESEARCH" "gate's \`§ 3a\` step 2" \
    "Recon: aid-research references gate § 3a work-level create+enter at its allocation step"

assert_file_contains "$AID_PROTOTYPE" "associate an opt-in git worktree so the throwaway" \
    "Recon: aid-prototype's spike opt-in worktree sentence survives unchanged"
assert_file_contains "$AID_PROTOTYPE" "gate's \`§ 3a\` step 2" \
    "Recon: aid-prototype references gate § 3a work-level create+enter at its allocation step"

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
