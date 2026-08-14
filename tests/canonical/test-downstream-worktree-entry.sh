#!/usr/bin/env bash
# test-downstream-worktree-entry.sh -- task-008 (work-018-worktree-isolation,
# delivery-002, feature-003 SPEC.md § 12 Testing): contract + prose-shape suite
# for the downstream locate-and-enter wiring.
#
# SUT (prose, agent-executed -- not a runnable state machine, so this is a
# CONTRACT + PROSE-SHAPE suite, matching the precedent
# tests/canonical/test-describe-full-only.sh / test-work-initiation-gate.sh):
#   canonical/aid/templates/downstream-worktree-entry.md  -- the single shared
#     pre-flight reference (C1): normalize -> locate -> enter -> never create.
#   canonical/skills/{aid-define,aid-specify,aid-plan,aid-detail,aid-execute,
#     aid-deploy}/SKILL.md -- each cites C1 at its own pre-flight anchor,
#     before its first local `.aid/works/{work}/...` read.
#
# Every assertion below is a static prose/grep/awk check against the real
# wired files already committed on this branch (task-006/task-007) -- no git
# fixtures, no mktemp scratch repos, no port binding. Groups map 1:1 to
# feature-003 SPEC.md § 12's eight numbered assertions:
#   Group 1  Wiring present                        (§12 assertion 1)
#   Group 2  Ordering -- pointer before the first   (§12 assertion 2)
#            local .aid/works/{work}/... read, per-skill anchor; fine-grained
#            for aid-execute (step3_line < pointer_line < step4_line) and
#            aid-deploy (item2_line < pointer_line < item3_line)
#   Group 3  Cross-worktree resolution +            (§12 assertion 3)
#            aid-specify work-first Check-1 +
#            aid-define Approved sub-check +
#            false-negative fallback sub-check
#   Group 4  Never-create                           (§12 assertion 4)
#   Group 5  Shared-doc contract                    (§12 assertion 5)
#   Group 6  aid-deploy carve-out (slice+assert)    (§12 assertion 6)
#   Group 7  Nesting note preserved                 (§12 assertion 7)
#   (§12 assertion 8 -- render parity -- is explicitly "covered transitively
#    by the existing render-drift + test-dogfood-byte-identity.sh gates; not
#    re-implemented here" per SPEC.md § 12; this suite does not duplicate it.)
#
# Usage:
#   bash tests/canonical/test-downstream-worktree-entry.sh [-v | --verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHARED_DOC="${REPO_ROOT}/canonical/aid/templates/downstream-worktree-entry.md"
DEFINE_MD="${REPO_ROOT}/canonical/skills/aid-define/SKILL.md"
SPECIFY_MD="${REPO_ROOT}/canonical/skills/aid-specify/SKILL.md"
PLAN_MD="${REPO_ROOT}/canonical/skills/aid-plan/SKILL.md"
DETAIL_MD="${REPO_ROOT}/canonical/skills/aid-detail/SKILL.md"
EXECUTE_MD="${REPO_ROOT}/canonical/skills/aid-execute/SKILL.md"
DEPLOY_MD="${REPO_ROOT}/canonical/skills/aid-deploy/SKILL.md"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# _line_of <file> <literal-substring> -- first 1-based line number containing
# the literal substring ANYWHERE in the line (awk index(), so regex
# metacharacters in the pattern are treated literally). Empty string if not
# found.
_line_of() {
    local file="$1" pat="$2"
    awk -v p="$pat" 'index($0, p) { print NR; exit }' "$file"
}

# _line_of_at_start <file> <literal-substring> -- first 1-based line number
# where the literal substring begins AT COLUMN 1 (a real markdown heading /
# top-level list item, never an indented or mid-sentence backtick
# cross-reference to that same heading's name elsewhere in the prose).
_line_of_at_start() {
    local file="$1" pat="$2"
    awk -v p="$pat" 'index($0, p) == 1 { print NR; exit }' "$file"
}

# assert_pointer_before <file> <before-anchor-substring> <label> [mode]
#     [pointer-pat] [pointer-mode] --
# asserts the shared-doc reference (default pattern "downstream-worktree-entry.md")
# appears, in file order, strictly BEFORE the given first-local-read anchor
# substring. mode="heading" requires the ANCHOR to begin at column 1 (guards
# against an earlier inline backtick cross-reference to the same heading's
# name, e.g. aid-define's Layer-2 prose names `## State Detection` step 2 by
# name well before the actual `## State Detection` heading).
#
# pointer-pat/pointer-mode (default "downstream-worktree-entry.md" / "any")
# override what counts as the POINTER itself. Pass pointer-mode="heading" with
# a real section-heading pointer-pat when the plain substring
# "downstream-worktree-entry.md" occurs more than once earlier in the file
# (e.g. an inline cross-reference to the pointer section, as in aid-specify's
# Check-1 step 3 prose) -- otherwise `_line_of`'s first-occurrence match would
# silently anchor on the inline mention instead of the real pointer section,
# making the ordering assertion vacuous against a misplacement of the real
# section.
assert_pointer_before() {
    local file="$1" anchor="$2" label="$3" mode="${4:-any}"
    local pointer_pat="${5:-downstream-worktree-entry.md}" pointer_mode="${6:-any}"
    local pointer_line anchor_line
    if [[ "$pointer_mode" == "heading" ]]; then
        pointer_line=$(_line_of_at_start "$file" "$pointer_pat")
    else
        pointer_line=$(_line_of "$file" "$pointer_pat")
    fi
    if [[ "$mode" == "heading" ]]; then
        anchor_line=$(_line_of_at_start "$file" "$anchor")
    else
        anchor_line=$(_line_of "$file" "$anchor")
    fi
    if [[ -z "$pointer_line" ]]; then
        fail "$label -- pointer not found: '$pointer_pat' in $(basename "$file")"
    elif [[ -z "$anchor_line" ]]; then
        fail "$label -- anchor not found: '$anchor' in $(basename "$file")"
    elif [[ "$pointer_line" -lt "$anchor_line" ]]; then
        pass "$label (pointer line $pointer_line < anchor line $anchor_line)"
    else
        fail "$label -- pointer (line $pointer_line) does NOT precede anchor (line $anchor_line)"
    fi
}

# assert_strict_between <file> <before-substr> <mid-substr> <after-substr> <label>
# -- asserts before_line < mid_line < after_line (all three, strict).
assert_strict_between() {
    local file="$1" before="$2" mid="$3" after="$4" label="$5"
    local line_before line_mid line_after
    line_before=$(_line_of "$file" "$before")
    line_mid=$(_line_of "$file" "$mid")
    line_after=$(_line_of "$file" "$after")
    if [[ -z "$line_before" || -z "$line_mid" || -z "$line_after" ]]; then
        fail "$label -- anchor(s) not found (before='$line_before' mid='$line_mid' after='$line_after')"
    elif [[ "$line_before" -lt "$line_mid" && "$line_mid" -lt "$line_after" ]]; then
        pass "$label (before=$line_before < mid=$line_mid < after=$line_after)"
    else
        fail "$label -- ordering violated (before=$line_before mid=$line_mid after=$line_after)"
    fi
}

echo "=== test-downstream-worktree-entry.sh (task-008, feature-003 SPEC.md § 12) ==="

# ===========================================================================
echo ""
echo "--- Group 0: files exist (preamble) ---"
assert_file_exists "$SHARED_DOC" "G0 downstream-worktree-entry.md exists (C1)"
assert_file_exists "$DEFINE_MD"  "G0 aid-define/SKILL.md exists"
assert_file_exists "$SPECIFY_MD" "G0 aid-specify/SKILL.md exists"
assert_file_exists "$PLAN_MD"    "G0 aid-plan/SKILL.md exists"
assert_file_exists "$DETAIL_MD"  "G0 aid-detail/SKILL.md exists"
assert_file_exists "$EXECUTE_MD" "G0 aid-execute/SKILL.md exists"
assert_file_exists "$DEPLOY_MD"  "G0 aid-deploy/SKILL.md exists"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ===========================================================================
echo ""
echo "=== Group 1: wiring present -- each of the six SKILL.md files references"
echo "    downstream-worktree-entry.md within its pre-flight section (§12 assertion 1) ==="

assert_file_contains "$DEFINE_MD"  "downstream-worktree-entry.md" "G1 aid-define references the shared doc"
assert_file_contains "$SPECIFY_MD" "downstream-worktree-entry.md" "G1 aid-specify references the shared doc"
assert_file_contains "$PLAN_MD"    "downstream-worktree-entry.md" "G1 aid-plan references the shared doc"
assert_file_contains "$DETAIL_MD"  "downstream-worktree-entry.md" "G1 aid-detail references the shared doc"
assert_file_contains "$EXECUTE_MD" "downstream-worktree-entry.md" "G1 aid-execute references the shared doc"
assert_file_contains "$DEPLOY_MD"  "downstream-worktree-entry.md" "G1 aid-deploy references the shared doc"

# ===========================================================================
echo ""
echo "=== Group 2: per-skill anchor ordering -- pointer before the first local"
echo "    .aid/works/{work}/... read (§12 assertion 2) ==="

assert_pointer_before "$DEFINE_MD"  "## State Detection" \
    "G2 aid-define -- pointer precedes '## State Detection' (STATE.md read)" "heading"
# aid-specify: "downstream-worktree-entry.md" occurs TWICE before Check 2 --
# an inline cross-reference in Check-1 step 3 prose, then the real pointer
# section. Anchor the pointer on the real section's heading (column-1
# match) rather than the first substring occurrence, or this assertion
# would stay vacuously green even if the real section were moved after
# Check 2.
assert_pointer_before "$SPECIFY_MD" "### Check 2: Feature Exists" \
    "G2 aid-specify -- pointer precedes '### Check 2: Feature Exists' (SPEC.md glob)" \
    "any" "### Locate + Enter the Work's Worktree" "heading"
assert_pointer_before "$PLAN_MD"    "### Check 2: Verify Feature SPECs" \
    "G2 aid-plan -- pointer precedes '### Check 2: Verify Feature SPECs'"
assert_pointer_before "$DETAIL_MD"  "### Check 2: Verify PLAN.md Exists" \
    "G2 aid-detail -- pointer precedes '### Check 2: Verify PLAN.md Exists'"

# aid-deploy: pointer sits BETWEEN numbered item 2 ("Resolve work directory")
# and item 3 ("Read work STATE.md").
assert_strict_between "$DEPLOY_MD" "2. Resolve work directory" "downstream-worktree-entry.md" "3. Read work" \
    "G2 aid-deploy -- pointer sits between item 2 and item 3 (item2 < pointer < item3)"

# aid-execute: fine-grained -- pointer must sit strictly AFTER Check-1 step 3
# (work id resolved: "Read second arg") and strictly BEFORE Check-1 step 4
# (first local read: "Detect the layout"). A bare "somewhere in Check 1"
# assertion would not catch a misplacement inside the Check-1 region.
assert_strict_between "$EXECUTE_MD" "Read second arg" "downstream-worktree-entry.md" "Detect the layout" \
    "G2 aid-execute -- pointer sits strictly between Check-1 step 3 and step 4 (step3 < pointer < step4)"

# ===========================================================================
echo ""
echo "=== Group 3: cross-worktree resolution -- no-arg / auto-select reachable"
echo "    from the main checkout (§12 assertion 3) ==="

assert_file_contains "$SHARED_DOC" "a bare local \`.aid/works/\` glob" \
    "G3 shared doc documents no-arg resolution is NEVER a bare local .aid/works/ glob"
assert_file_contains "$SHARED_DOC" "git worktree list --porcelain" \
    "G3 shared doc documents the cross-worktree source (git worktree list --porcelain)"

# The four skills with a literal single-work auto-select reference the
# cross-worktree enumeration source at their resolution step.
assert_file_contains "$SPECIFY_MD" "enumerate-works.sh" \
    "G3 aid-specify auto-select references enumerate-works.sh (cross-worktree, not a local glob)"
assert_file_contains "$PLAN_MD"    "enumerate-works.sh" \
    "G3 aid-plan auto-select references enumerate-works.sh"
assert_file_contains "$DETAIL_MD"  "enumerate-works.sh" \
    "G3 aid-detail auto-select references enumerate-works.sh"
assert_file_contains "$EXECUTE_MD" "enumerate-works.sh" \
    "G3 aid-execute auto-select references enumerate-works.sh"

# aid-specify's no-feature-path Check 1 is rewritten work-first.
assert_file_contains "$SPECIFY_MD" "work-first" \
    "G3 aid-specify's no-feature-path Check 1 resolves work-first"

# aid-define Approved sub-check: cross-worktree candidate set (Layer 1) +
# per-candidate git show sub-filter (Layer 2), because enumerate-works.sh's
# record carries no Interview-State field.
assert_file_contains "$DEFINE_MD" "enumerate-works.sh" \
    "G3 aid-define Layer 1 -- cross-worktree candidate set via enumerate-works.sh"
assert_file_contains "$DEFINE_MD" 'git show "<branch_label>:.aid/works/<work_id>/STATE.md"' \
    "G3 aid-define Layer 2 -- per-candidate read-only git show of STATE.md"
assert_file_contains "$DEFINE_MD" 'branch_label` is the literal `(detached)`' \
    "G3 aid-define -- detached-HEAD branch_label case named explicitly"
assert_file_contains "$DEFINE_MD" 'skip** the `git show` check for this candidate and **retain**' \
    "G3 aid-define -- detached-HEAD candidate is RETAINED (not dropped) rather than git-show-filtered"

# False-negative fallback sub-check: the committed-view git show pre-filter
# can miss an Approved-but-uncommitted work; the direct work-NNN argument is
# the documented fallback, and ## State Detection step 2 is the authoritative
# post-enter gate.
assert_file_contains "$DEFINE_MD" 'Documented fallback:** invoke `/aid-define work-NNN` directly.' \
    "G3 aid-define -- direct work-NNN argument documented as the false-negative fallback"
assert_file_contains "$DEFINE_MD" '`## State Detection` step 2 confirms `Approved`' \
    "G3 aid-define -- ## State Detection step 2 named as the authoritative post-enter Approved gate"

# ===========================================================================
echo ""
echo "=== Group 4: never-create -- none of the six SKILL.md files (nor C1)"
echo "    invokes worktree-lifecycle.sh create (§12 assertion 4) ==="

assert_file_not_contains "$DEFINE_MD"  "worktree-lifecycle.sh create" "G4 aid-define never invokes create"
assert_file_not_contains "$SPECIFY_MD" "worktree-lifecycle.sh create" "G4 aid-specify never invokes create"
assert_file_not_contains "$PLAN_MD"    "worktree-lifecycle.sh create" "G4 aid-plan never invokes create"
assert_file_not_contains "$DETAIL_MD"  "worktree-lifecycle.sh create" "G4 aid-detail never invokes create"
assert_file_not_contains "$EXECUTE_MD" "worktree-lifecycle.sh create" "G4 aid-execute never invokes create"
assert_file_not_contains "$DEPLOY_MD"  "worktree-lifecycle.sh create" "G4 aid-deploy never invokes create"

# C1 itself: never invokes the actual create call (it only NAMES the term in
# prose to explain it is NOT invoked); C1 DOES invoke locate.
assert_file_not_contains "$SHARED_DOC" "bash canonical/aid/scripts/works/worktree-lifecycle.sh create" \
    "G4 C1 (shared doc) never INVOKES worktree-lifecycle.sh create"
assert_file_contains "$SHARED_DOC" "bash canonical/aid/scripts/works/worktree-lifecycle.sh locate" \
    "G4 C1 (shared doc) invokes worktree-lifecycle.sh locate"

# ===========================================================================
echo ""
echo "=== Group 5: shared-doc contract -- downstream-worktree-entry.md names"
echo "    the required minimum content (§12 assertion 5) ==="

assert_file_contains "$SHARED_DOC" "normalize -> \`locate\` -> enter -> never \`create\`" \
    "G5 shared doc states the control-flow chain: normalize -> locate -> enter -> never create"
assert_file_contains "$SHARED_DOC" "Normalize to the bare \`work-NNN\` branch name" \
    "G5 shared doc names Step 1 -- normalize to bare work-NNN"
assert_file_contains "$SHARED_DOC" "safety-critical" \
    "G5 shared doc names the bare-work-NNN normalization step as safety-critical (FR6/NFR2/NFR3)"
assert_file_contains "$SHARED_DOC" "IFS=\$'\\t' read -r WT_PATH WT_STATUS" \
    "G5 shared doc documents the TAB split idiom (IFS=\$'\\t' read), never a space split"

# locate's FROZEN exit contract: exit 0 always / never fails the caller (the
# sentence wraps across a markdown line-break, so flatten newlines to spaces
# before checking for the full phrase rather than grep -F's single-line match).
DOC_FLAT=$(tr '\n' ' ' < "$SHARED_DOC" | tr -s ' ')
assert_output_contains "$DOC_FLAT" "exits \`0\` on every resolution, including the degrade below -- it never fails the caller" \
    "G5 shared doc states locate exits 0 always / never fails the caller (FROZEN contract)"
assert_file_contains "$SHARED_DOC" "degrades to \`<cwd-abs>\\tcurrent\`" \
    "G5 shared doc states the degrade target: <cwd-abs>\\tcurrent (non-empty path)"

assert_file_contains "$SHARED_DOC" "## Never \`create\`" \
    "G5 shared doc carries the '## Never create' section heading"
assert_file_contains "$SHARED_DOC" "ever invokes it from this pre-flight step -- they call" \
    "G5 shared doc states the never-create guarantee explicitly for all six skills"

assert_file_contains "$SHARED_DOC" "surface that path to the user" \
    "G5 shared doc documents the FR4 degradation fallback -- surface the path to the user"
assert_file_contains "$SHARED_DOC" "FR4 / AC4" \
    "G5 shared doc cross-references FR4 / AC4 for the degradation fallback"

# Regression guard: the doc must NOT describe locate as failing (exit 1 /
# empty stdout / no status token) on an unrecoverable state -- that phrasing
# would contradict feature-001's FROZEN "always exits 0" contract.
assert_file_not_contains "$SHARED_DOC" "fail-closed" \
    "G5 shared doc does NOT mislabel locate's guard as fail-closed (regression guard)"
assert_file_not_contains "$SHARED_DOC" "empty stdout" \
    "G5 shared doc does NOT describe locate as returning empty stdout on failure (regression guard)"
assert_file_not_contains "$SHARED_DOC" "no status token" \
    "G5 shared doc does NOT describe locate as returning no status token on failure (regression guard)"

# ===========================================================================
echo ""
echo "=== Group 6: aid-deploy carve-out -- slice-and-assert (§12 assertion 6) ==="

# Slice 1: the Step-0 free-form shortcut region (heading through the first
# numbered pre-flight item "1. Verify").
SHORTCUT_REGION=$(awk '
    /^### Step 0: Invocation-context mode detection/ { flag = 1 }
    flag { print }
    flag && /^1\. Verify/ { exit }
' "$DEPLOY_MD")

# Slice 2: the work-NNN pipeline region (numbered item "2. Resolve work
# directory" through item "3. Read work").
PIPELINE_REGION=$(awk '
    /^2\. Resolve work directory/ { flag = 1 }
    flag { print }
    flag && /^3\. Read work/ { exit }
' "$DEPLOY_MD")

assert_output_contains "$SHORTCUT_REGION" "shortcut-engine.md" \
    "G6 shortcut region (Step 0) correctly sliced -- names shortcut-engine.md"
assert_output_contains "$PIPELINE_REGION" "Resolve work directory" \
    "G6 pipeline region (items 2-3) correctly sliced -- names 'Resolve work directory'"

assert_output_contains "$PIPELINE_REGION" "downstream-worktree-entry.md" \
    "G6 pipeline region (work-NNN path) DOES carry the downstream-worktree-entry.md reference"
assert_output_not_contains "$SHORTCUT_REGION" "downstream-worktree-entry.md" \
    "G6 shortcut region (Step 0 free-form path) does NOT carry the downstream-worktree-entry.md reference"

# ===========================================================================
echo ""
echo "=== Group 7: aid-execute nesting note preserved (§12 assertion 7) ==="

NESTING_BLOCK=$(awk '
    /Ephemeral worktrees \(pool dispatch PD-2\)/ { flag = 1 }
    /^## Delivery Lifecycle/ { flag = 0 }
    flag { print }
' "$EXECUTE_MD")

assert_output_contains "$NESTING_BLOCK" ".aid/.worktrees/task-" \
    "G7 'Ephemeral worktrees (pool dispatch PD-2)' paragraph still names .aid/.worktrees/task-"
assert_output_contains "$NESTING_BLOCK" "Nesting with the work-level worktree" \
    "G7 the work-level nesting cross-note paragraph is present"
assert_output_contains "$NESTING_BLOCK" "nested, unchanged, inside" \
    "G7 the nesting cross-note states per-task worktrees are nested, unchanged, inside the work-level worktree"

# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
