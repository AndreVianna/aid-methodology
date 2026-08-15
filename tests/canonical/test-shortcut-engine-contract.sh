#!/usr/bin/env bash
# test-shortcut-engine-contract.sh -- fixture-INDEPENDENT contract assertions for the
# shortcut engine's GATE / APPROVAL-HALT / batching prose, plus SEC08's verb-to-family
# reachability rule.
#
# Re-homed from test-shortcut-gate-halt-batching.sh (its SGH01-07 "Part 1" block), which
# was scoped to the now-removed work-001-lite-aid-skills / feature-004 fixture and is
# therefore skipped when that fixture is absent. These assertions validate only the LIVE
# canonical shortcut-engine.md -- no removed-work fixture -- so they run everywhere.
#
# Assertions grep the FILE directly (assert_file_contains) rather than piping the whole
# file through `echo "$var" | grep`, for portability across shells/runners.
#
# Usage:
#   bash test-shortcut-engine-contract.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed
#
# ---------------------------------------------------------------------------
# Overridable inputs
# ---------------------------------------------------------------------------
#   ENGINE       -- the shortcut-engine.md under test.
#   FAMILY_BASE  -- the directory the groupings table's RELATIVE family-file paths
#                   (`shortcut-scaffolding/<family>.md`) resolve against.
#   CATALOG      -- the shortcut-catalog.yml SEC08a derives its verb set from.
#
# All three default to the live canonical tree, so an unset environment resolves exactly
# the paths this suite resolved before the overrides existed. They exist so SEC08's negative
# controls can run against a materialised OLD revision or a mutated scratch copy WITHOUT
# editing this file: a temporary local edit reverted afterwards is worse on two counts --
# it leaves the suite transiently wrong, and the revert is unreviewable.
#
# In-repo precedent for the `${VAR:-default}` form, re-measured on this tree with
# `grep -rlE '\$\{[A-Z_]+:-' tests/`: 15 files under tests/canonical/ BEFORE this suite
# adopted it (16 including it), 3 under tests/lib/, plus tests/run-all.sh -- 20 under
# tests/ in total, and the decomposition sums. The two closest in shape override a
# REVISION for exactly this purpose -- test-release.sh:47
# (`WORKTREE_REF="${AID_TEST_REF:-$(git -C "${REPO_ROOT}" rev-parse HEAD)}"`) and
# test-release-install-e2e.sh:79, both verbatim at those lines.
#
# ---------------------------------------------------------------------------
# SEC08 -- what it proves, and what it deliberately does not
# ---------------------------------------------------------------------------
#   SEC08a  every distinct `verb` over shortcut-catalog.yml rows with `repurpose != true`
#           is bound in shortcut-engine.md's "Current verb -> family-file groupings"
#           table. CLASS-LEVEL and TOTAL over the catalogue: the verb set is DERIVED at
#           run time, never a hard-coded list, so a verb row added tomorrow is in scope
#           tomorrow and this is one rule rather than one assertion per renamed skill.
#           Only non-`repurpose` rows are in scope because only a GENERATED doorway
#           delegates to this engine -- build-shortcut-skills.py's
#           `generated_rows = [r for r in rows if not r.get("repurpose", False)]`.
#   SEC08b  every family file that table names exists on disk.
#   SEC08c  change-refactor.md's own H1 still claims the verb the table routes to it.
#           Named explicitly rather than derived from the table: it is the one family
#           file whose FILENAME still carries the retired verb (`change-`), so its header
#           is exactly the place a verb rename can silently fail to land.
#
# PROOF BOUNDARY: SEC08 proves each verb REACHES an existing family file. It does NOT
# prove the guidance behind the binding is correct -- the engine's own Absent-file
# fallback paragraph declares the scaffolding "not machine-parsed". Reaching the file is
# the whole of the FR-13 breach; claiming more would overcredit the guard.
#
# RAISE PATH: a catalogue verb the groupings table does not bind is a PRODUCT defect in
# the engine, raised against feature-005. It is never repaired by weakening SEC08a.
#
# ---------------------------------------------------------------------------
# WHY THE PREDICATE IS AN EXACT BACKTICK-DELIMITED TOKEN MATCH, NOT A SUBSTRING
# ---------------------------------------------------------------------------
# Measured over the groupings-table block of the PRE-feature-005 engine (the revision
# derived below), whose `change` cell read "`change` (+ `update-*` aliases), `refactor`":
#
#     grep -c  'update'   <that block>  ->  1     (substring form: ALREADY GREEN)
#     grep -cE '`update`' <that block>  ->  0     (delimited form: correctly RED)
#
# A substring predicate is therefore a TAUTOLOGY on the very engine SEC08a exists to
# reject: it scores 1 there off the `update-*` ALIAS mention, so SEC08a's demonstrated
# red becomes silently unobtainable while the guard still looks correct. This suite
# extracts only whole `` `token` `` cells and compares them with `grep -qxF` (exact
# whole-line match), which is why it can go red at all. Do not "simplify" this to a
# substring grep.
#
# ---------------------------------------------------------------------------
# SEC08a/b/c DEMONSTRATED RED -- durable record (work folders are transient)
# ---------------------------------------------------------------------------
# SEC08a's negative control is a PAST REVISION of a product file, not a mutation of the
# present tree, so it cannot be a permanent fixture leg the way a copy-and-mutate guard
# can. The reproduction therefore lives HERE, with the code, rather than only in a work
# folder that is pruned once the work ships.
#
# The revision is DERIVED, never hard-coded. Two independent routes must agree:
#
#   P=canonical/aid/templates/shortcut-engine.md
#   # route 1 -- write-set: the first commit that touched the engine in this work
#   LAND=$(git log --format=%H --reverse <pre-work-baseline>..HEAD -- "$P" | head -1)
#   # route 2 -- pickaxe on a token feature-005 removed (hard-codes no baseline at all)
#   LAND=$(git log --format=%H -1 -S'change-data-model' -- "$P")
#   PRE=$(git rev-parse "${LAND}^1")
#
# Reproduce (materialise, run, clean up -- never edit-and-revert):
#
#   S=$(mktemp -d); git show "${PRE}:${P}" > "$S/shortcut-engine.md"
#   ENGINE="$S/shortcut-engine.md" bash tests/canonical/test-shortcut-engine-contract.sh
#   rm -rf "$S"
#
# Observed 2026-07-31 -- a RECORD of what the derivation resolved to, not an input; the
# commands above name no revision: both routes agreed on LAND=bc40b7ef, giving
# PRE=a72ab409 (926 lines), and the run reported "Tests passed: 23 / Tests failed: 1",
# exit 1, on this line (the tail, listing both full verb sets, is elided here):
#
#   FAIL: SEC08a verb not bound to a family — unbound catalogue verb(s): update — ...
#
# SEC08b is shown red by pointing ENGINE at a scratch copy whose groupings table names a
# family file that does not exist. SEC08c by pointing FAMILY_BASE at a scratch tree
# holding that same PRE revision's shortcut-scaffolding/change-refactor.md, whose H1
# reads "# Shortcut Scaffolding: change / refactor". Both mutate SCRATCH COPIES under
# mktemp -d; neither touches the repository.
set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="${ENGINE:-${REPO_ROOT}/canonical/aid/templates/shortcut-engine.md}"
FAMILY_BASE="${FAMILY_BASE:-${REPO_ROOT}/canonical/aid/templates}"
CATALOG="${CATALOG:-${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml}"

echo "=== Shortcut engine contract (GATE / halt / batching prose) ==="
log "ENGINE      = $ENGINE"
log "FAMILY_BASE = $FAMILY_BASE"
log "CATALOG     = $CATALOG"
assert_file_exists "$ENGINE" "SEC00 shortcut-engine.md exists"

# SEC01: minimum_grade resolves via read-setting.sh, shortcut floor default A.
# Retargeted for an owner-approved, pre-existing default-grade edit unrelated
# to the STATE.yml migration (commit d149ddc1: "A+" -> "A", "not investigated
# further by request") -- recorded in the task-001 change-set addendum since
# it is not itself a state-format change but was needed to keep this
# in-scope suite green.
assert_file_contains "$ENGINE" \
    "read-setting.sh --skill {name} --key minimum_grade --default A" \
    "SEC01 GATE resolves minimum_grade via read-setting.sh (shortcut floor default A)"

# SEC02: the two named ledger scopes.
assert_file_contains "$ENGINE" '.aid/.temp/review-pending/shortcut-{work}-defn.md' \
    "SEC02a Pass 1 ledger scope shortcut-{work}-defn.md named"
assert_file_contains "$ENGINE" '.aid/.temp/review-pending/shortcut-{work}-tasks.md' \
    "SEC02b Pass 2 ledger scope shortcut-{work}-tasks.md named"

# SEC03/SEC04: grade.sh drives the computation, inside a REVIEW -> GRADE -> FIX loop with a 3-cycle
# circuit breaker.
#
# These used to be asserted as literal strings in the engine. The review extraction moved the loop OUT
# of the engine and into `/aid-deep-review`, so the engine no longer spells it -- it delegates. The
# contract still has to hold, but it is now satisfied TRANSITIVELY: the engine must delegate, and the
# delegate must carry the loop. Asserting the old literals in the engine would demand the engine keep a
# copy of exactly what the extraction removed, which is the duplication the extraction existed to end.
#
# Same shape as the gap-gate suite, where a caller satisfies the gate either directly or by delegating.
DEEP="${REPO_ROOT}/canonical/skills/aid-deep-review/SKILL.md"

if grep -q 'grade.sh --explain <ledger-path>' "$ENGINE" 2>/dev/null; then
    assert_file_contains "$ENGINE" "grade.sh --explain <ledger-path>" \
        "SEC03 GATE drives grade.sh --explain over the ledger (inline)"
else
    assert_file_contains "$ENGINE" "/aid-deep-review" \
        "SEC03a engine delegates the gate to /aid-deep-review"
    assert_file_contains "$DEEP" "grade.sh --explain" \
        "SEC03b the delegate drives grade.sh --explain"
fi

if grep -q 'The Generic REVIEW -> GRADE -> FIX loop' "$ENGINE" 2>/dev/null; then
    assert_file_contains "$ENGINE" "Circuit breaker" \
        "SEC04 engine documents the loop and its circuit breaker (inline)"
else
    assert_file_contains "$ENGINE" "REVIEW -> GRADE -> FIX" \
        "SEC04a engine still names the REVIEW -> GRADE -> FIX loop it delegates"
    assert_file_contains "$DEEP" "Circuit breaker" \
        "SEC04b the delegate names a Circuit breaker"
    # ASSERT THE CONDITION, NOT THE PHRASE. This used to search for the literal "3 cycles", which a
    # flat cycle-count breaker satisfies just as well as the non-improvement one the KB declares
    # (`pipeline-contracts.md § Circuit breaker (Execute)`: "if the grade does not improve after 3
    # consecutive cycles"). The delegate had in fact been rewritten to the flat form, and this
    # assertion reported the contract as holding transitively over the drop.
    assert_file_contains "$DEEP" "3 consecutive cycles" \
        "SEC04c the delegate's circuit breaker names 3 CONSECUTIVE cycles"
    assert_file_contains "$DEEP" "does not improve" \
        "SEC04d the delegate's breaker trips on NON-IMPROVEMENT, not on a cycle count"
fi

# SEC05: halt proof -- no branch, no execution, Paused-Awaiting-Input, Specified.
assert_file_contains "$ENGINE" "no branch is created, no task executes" \
    "SEC05a APPROVAL-HALT: no branch is created, no task executes"
assert_file_contains "$ENGINE" \
    'writeback-state.sh --pipeline --field Lifecycle --value Paused-Awaiting-Input' \
    "SEC05c APPROVAL-HALT sets Pipeline Lifecycle: Paused-Awaiting-Input"
assert_file_contains "$ENGINE" 'is already `Specified`' \
    "SEC05d APPROVAL-HALT leaves Delivery Lifecycle State at Specified (not Executing)"

# SEC06: batching -- exactly two batched Grading-Gate passes.
assert_file_contains "$ENGINE" "two batched Grading-Gate passes" \
    "SEC06a engine documents exactly two batched Grading-Gate passes"

# SEC07: ledger-scope count in the engine prose is exactly 2, distinct (defn, tasks) --
# a mechanical cross-check that the prose never grows a third/per-document scope pattern.
LEDGER_SCOPES=$(grep -oE '\.aid/\.temp/review-pending/shortcut-\{work\}-[a-z]+\.md' "$ENGINE" | sort -u)
LEDGER_SCOPE_COUNT=$(printf '%s\n' "$LEDGER_SCOPES" | grep -c . || true)
assert_eq "$LEDGER_SCOPE_COUNT" "2" \
    "SEC07 exactly two distinct ledger-scope patterns named in the engine prose"

# ---------------------------------------------------------------------------
# SEC08: verb -> family-file reachability (feature-006 AC-12 / FR-13).
# See the file header for the proof boundary, the substring-vs-delimited
# measurement, and the demonstrated-red derivation.
# ---------------------------------------------------------------------------
assert_file_exists "$CATALOG" "SEC08-00a shortcut-catalog.yml exists (SEC08 input)"
assert_dir_exists "$FAMILY_BASE" "SEC08-00b family-file base directory exists (SEC08 input)"

# -- Derive the catalogue side. One "<verb>\t<repurpose>" record per `  - name:` row.
CATALOG_ROWS=$(awk '
    /^  - name: / {
        if (n != "") print v "\t" r
        n = $3; v = ""; r = "false"
    }
    /^    verb: /                       { v = $2 }
    /^    repurpose: true[[:space:]]*$/ { r = "true" }
    END { if (n != "") print v "\t" r }
' "$CATALOG")
CATALOG_ROW_COUNT=$(grep -c . <<< "$CATALOG_ROWS" || true)
CATALOG_NAME_COUNT=$(grep -c '^  - name: ' "$CATALOG" || true)
CATALOG_VERB_LINES=$(grep -c '^    verb: ' "$CATALOG" || true)

# Totality of the parse: exactly one `verb:` line per row, and no row parsed a blank
# verb. Without these two, a silently-partial parse would make SEC08a pass by
# enumerating nothing -- the same shape as a clean result. The row count is deliberately
# cross-checked against an INDEPENDENT anchor (`^    verb: ` lines, not the `^  - name: `
# lines the parser itself keys on): comparing the parser's record count against its own
# start pattern could not fail. This form catches a row with no verb AND a row that grew
# a second one.
assert_eq "$CATALOG_VERB_LINES" "$CATALOG_NAME_COUNT" \
    "SEC08a0a catalogue parse is total (exactly one 'verb:' line per '- name:' row)"
CATALOG_BLANK_VERBS=$(awk -F'\t' '$1 == "" { c++ } END { print c+0 }' <<< "$CATALOG_ROWS")
assert_eq "$CATALOG_BLANK_VERBS" "0" \
    "SEC08a0b every catalogue row parsed a non-empty verb"

CATALOG_VERBS=$(awk -F'\t' '$2 == "false" { print $1 }' <<< "$CATALOG_ROWS" | LC_ALL=C sort -u)
CATALOG_VERB_COUNT=$(grep -c . <<< "$CATALOG_VERBS" || true)

# -- Derive the engine side: the groupings table, header row to the first non-table line.
TABLE_ROWS=$(awk '
    /^\| Verb\(s\) \| Family file \|/    { inblock = 1; next }
    inblock && /^\|[-| ]+\|[[:space:]]*$/ { next }
    inblock && /^\|/                      { print; next }
    inblock                               { exit }
' "$ENGINE")
TABLE_ROW_COUNT=$(grep -c . <<< "$TABLE_ROWS" || true)

# Cell 1 = the verb cell; cell 2 = the family-file cell. Only WHOLE backtick-delimited
# tokens are harvested, so `update-*` (an alias mention, not a binding) does not match --
# that distinction is the whole reason this guard can go red. See the header.
#
# `sed -n ... p` (print only on match) rather than a substitute-in-place: a row that does
# not have the full `| cell | cell |` shape is DROPPED from the verb set rather than
# harvested whole, so its verbs read as unbound and SEC08a fails loudly. A
# substitute-in-place would leave the malformed row intact and let the file cell's own
# backticked tokens (e.g. `test`) leak in as phantom bound verbs -- a silent pass.
ENGINE_VERBS=$(sed -nE 's/^\|([^|]*)\|.*\|[[:space:]]*$/\1/p' <<< "$TABLE_ROWS" \
    | grep -oE '`[a-z][a-z-]*`' | tr -d '`' | LC_ALL=C sort -u)
ENGINE_VERB_COUNT=$(grep -c . <<< "$ENGINE_VERBS" || true)
ENGINE_FAMILY_FILES=$(sed -nE 's/^\|[^|]*\|(.*)\|[[:space:]]*$/\1/p' <<< "$TABLE_ROWS" \
    | grep -oE '`[A-Za-z0-9_./-]+\.md`' | tr -d '`' | LC_ALL=C sort -u)
FAMILY_FILE_COUNT=$(grep -c . <<< "$ENGINE_FAMILY_FILES" || true)

log "SEC08 derived: CATALOG_ROWS=${CATALOG_ROW_COUNT} NONREPURPOSE_VERBS=${CATALOG_VERB_COUNT}" \
    "TABLE_ROWS=${TABLE_ROW_COUNT} TABLE_VERBS=${ENGINE_VERB_COUNT} FAMILY_FILES=${FAMILY_FILE_COUNT}"
log "SEC08 catalogue verbs (non-repurpose, sorted): $(tr '\n' ' ' <<< "$CATALOG_VERBS")"
log "SEC08 groupings-table verbs (sorted): $(tr '\n' ' ' <<< "$ENGINE_VERBS")"
log "SEC08 groupings-table family files (sorted): $(tr '\n' ' ' <<< "$ENGINE_FAMILY_FILES")"

# Vacuity guards: an enumeration that came back empty reads exactly like a clean pass.
if [[ "$CATALOG_VERB_COUNT" -gt 0 ]]; then
    pass "SEC08a0c catalogue yields a non-empty non-repurpose verb set"
else
    fail "SEC08a0c catalogue yields a non-empty non-repurpose verb set — enumerated 0, so SEC08a would be vacuous"
fi
if [[ "$ENGINE_VERB_COUNT" -gt 0 ]]; then
    pass "SEC08a0d groupings table yields a non-empty backtick-delimited verb set"
else
    fail "SEC08a0d groupings table yields a non-empty backtick-delimited verb set — enumerated 0 in $ENGINE"
fi

# SEC08a -- THE RULE. Class-level, total over the catalogue, exact token match.
SEC08A_UNBOUND=""
while IFS= read -r sec08_verb; do
    [[ -n "$sec08_verb" ]] || continue
    if ! grep -qxF -- "$sec08_verb" <<< "$ENGINE_VERBS"; then
        SEC08A_UNBOUND="${SEC08A_UNBOUND}${SEC08A_UNBOUND:+ }${sec08_verb}"
    fi
done <<< "$CATALOG_VERBS"
if [[ -z "$SEC08A_UNBOUND" ]]; then
    pass "SEC08a every non-repurpose catalogue verb is bound in the engine's groupings table"
else
    fail "SEC08a verb not bound to a family — unbound catalogue verb(s): ${SEC08A_UNBOUND} — catalogue verbs [$(tr '\n' ' ' <<< "$CATALOG_VERBS")] vs groupings-table verbs [$(tr '\n' ' ' <<< "$ENGINE_VERBS")] in $ENGINE"
fi

# SEC08b -- every family file the table names exists.
if [[ "$FAMILY_FILE_COUNT" -gt 0 ]]; then
    pass "SEC08b0 groupings table names at least one family file"
else
    fail "SEC08b0 groupings table names at least one family file — enumerated 0 in $ENGINE"
fi
SEC08B_MISSING=""
while IFS= read -r sec08_family; do
    [[ -n "$sec08_family" ]] || continue
    [[ -f "${FAMILY_BASE}/${sec08_family}" ]] \
        || SEC08B_MISSING="${SEC08B_MISSING}${SEC08B_MISSING:+ }${sec08_family}"
done <<< "$ENGINE_FAMILY_FILES"
if [[ -z "$SEC08B_MISSING" ]]; then
    pass "SEC08b every family file named by the groupings table exists on disk"
else
    fail "SEC08b family file named by the groupings table does not exist — missing: ${SEC08B_MISSING} (resolved under ${FAMILY_BASE})"
fi

# SEC08c -- the one family file whose NAME still carries the retired verb must, in its
# own H1, claim the verb the table routes to it.
SEC08C_FILE="${FAMILY_BASE}/shortcut-scaffolding/change-refactor.md"
SEC08C_H1=$(grep -m1 '^# ' "$SEC08C_FILE" 2>/dev/null || true)
log "SEC08c change-refactor.md H1: ${SEC08C_H1:-<none>}"
if grep -qE '(^|[^A-Za-z-])update([^A-Za-z-]|$)' <<< "$SEC08C_H1"; then
    pass "SEC08c change-refactor.md's H1 claims the 'update' verb"
else
    fail "SEC08c change-refactor.md's H1 does not claim the 'update' verb — H1 reads '${SEC08C_H1:-<no H1 found>}' in ${SEC08C_FILE}"
fi

test_summary
