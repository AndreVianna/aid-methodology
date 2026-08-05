#!/usr/bin/env bash
# test-graph-schema-loader.sh -- the graph relationship-schema LIBRARY.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# A trailing slash means the directory and everything under it. Omitting the
# header entirely is fail-safe (the suite is then always selected); a WRONG
# entry is the only way to lose coverage, so these are reviewed as claims.
# COVERS: canonical/aid/scripts/graph/relationship-schema.sh
# COVERS: canonical/aid/templates/graph/
#
# Scope:
#   canonical/aid/scripts/graph/relationship-schema.sh -- the sourceable loader and
#   normaliser library for the `.aid/knowledge/relationships.md` relationship table
#   (work-005, feature-003). Its sibling suite, test-graph-relationship-validator.sh,
#   covers the V1-V15 linter that consumes it.
#
# S1 -- SUBJECT INVOCATION BUDGET: 24 in-process loads + 2 subprocess spawns.
#   Stated in this shape rather than as a bare number because S1's toll does not
#   apply the same way here. S1 exists because "each subject invocation is a fixed
#   ~10s toll" -- that is a SUBPROCESS cost. This suite sources the subject library
#   once (:193) and drives it with 17 `rel_load_vocabulary` and 7 `rel_load_schema`
#   in-process calls, each costing microseconds, plus exactly 2 deliberate `bash -c`
#   spawns where a clean-environment load is the property under test. The budget to
#   watch here is therefore the 2 spawns, not the 24 calls.
#
# S3 -- MUTATIONS ARE UNCONDITIONAL HERE, DELIBERATELY, AND THIS IS THE REASON.
#   S3 puts a mutation MATRIX behind `--self-mutate` because "a mutation matrix is N
#   suite runs" -- again a subprocess cost (and the cost defect tech-debt W5-4
#   records). These mutations are in-process calls into the already-sourced library.
#   Gating them behind an opt-in flag would mean CI never runs them, which would
#   WEAKEN the vacuity coverage S3's own text asks for. The convention bears this
#   out exactly: all 6 graph suites that carry `--self-mutate` are subprocess-based
#   (extraction, source-enumeration, the four runtime suites); both that do not --
#   this one and test-graph-relationship-validator.sh -- are in-process libraries.
#   So: keep the vacuity mutations, run them by default, no flag.
#
#   Every assertion here runs IN PROCESS: the library is sourced once and its
#   loaders RETURN 2 rather than calling `exit`, so a rejection class costs a
#   function call and not a ~100 ms process fork. That is what lets this suite keep
#   one fixture per rejection class instead of batching them.
#
# What is asserted, and why each group exists:
#   SC   the schema carrier loads and exposes every key, and fails CLOSED on each
#        way it can be broken (an absent/empty/malformed enum must never be read as
#        "every value is acceptable").
#   Q20  the two token-set properties that keep the loader from rejecting the
#        vocabulary it exists to load. Asserted as PROPERTIES over the set -- every
#        endpoint token has both sides in the Kind enum, every standards token
#        matches the grammar -- and never as a count. A gate record once carried
#        counts for this that measurement did not support; the property is the
#        contract, the numeral never was.
#   EX   the exposure surface the consumer table routes through, `passes` included
#        (a recorded defect was its omission) -- asserted for EVERY relation.
#   CAT  category completeness over the REAL shipped core (work-005 task-001,
#        feature-001 AC-S3) -- every declared category classifies at least one
#        relation, proven non-vacuous by mutating a COPY to add an orphan
#        category the LOAD itself does not reject, plus the mechanism proof
#        for an empty category meaning.
#   D9   the shipped file's own four worked rows -- its header comment -- checked
#        against the `pairs:` block they illustrate (work-005 task-001,
#        feature-001 AC-S6): membership, pairing, the declared endpoint token,
#        legal Provenance, and that Observation never smuggles in a relation
#        label. Proven non-vacuous by mutating a COPY's row 1 to a
#        real-but-wrong relation label.
#   VK   totality, the fixed key order, and the declared key set.
#   VV   each declared key's value rule, including the `derived_from` token grammar
#        and its two `coined` clauses.
#   RS   the restricted YAML subset, enforced rather than assumed.
#   CE   the cross-entry invariants over the merged set.
#   PC   PAIR COHERENCE -- gating, all five clauses isolated, plus the POSITIVE
#        set-reading fixture that must LOAD (a loader comparing sequences instead of
#        sets passes every negative case and rejects a legal pair).
#   MG   the core-plus-extension merge: adds cleanly, collides hard, absent is fine.
#   SR   the string rules -- heading slug, concept term, fact anchor token.
#   ID   the per-kind id grammars and the two-tier kind/prefix check, including the
#        branching `image` case that must ACCEPT `ext:`.
#   KB   the one-pass KB scan: the duplicate-slug ordinal, fenced-code exclusion in
#        both directions, the unanchored-citation record, the fence mask, and the
#        nested-heading case a real KB cannot supply.
#   RN   row normalisation, the duplicate key, the sort key, the class-0 extraction
#        and the coverage-note key accessors.
#   WT   the working-tree-untouched proof (S5): a PRE snapshot of the three real
#        subject files, compared byte-for-byte against themselves at the end of
#        the run, after every mutation above.
#
# AC-MAP -- feature-001's AC-S1..AC-S6, closed against the SHIPPED core
# (canonical/aid/templates/graph/relation-vocabulary.yml), never a fixture.
# Built by work-005 task-001, because AC-S1..AC-S6 had never been read against
# this suite's and test-graph-relationship-validator.sh's actual assertion ids
# before. A row with no id is a genuine gap the map exists to surface, not a
# formality; task-001's Scope bounds the map to AC-S1..AC-S6, so AC-S7..AC-S11
# and AC-2 are not mapped here.
#
#   AC-S1 (five inverse-pair properties + eight-key totality, over the core)
#     mechanism (proves the loader REJECTS each violation) -- CE01 closure,
#     CE02 involution, CE03 symmetric consistency, CE04/CE05 uniqueness,
#     VK01-05 totality/key order, PC01-06 pair coherence.
#     over the REAL core -- Q20-00 (the shipped core loads clean through the
#     SAME gates the mechanism tests just proved correct; a violation of any
#     of the five properties would make this load fail).
#   AC-S2 (derived_from: >=1 token, closed grammar, no 'coined' in the core;
#          every token in D1's in-scope column; classed at D6d or direct)
#     mechanical half -- VV05 (non-empty), VV06-09 (grammar), VV10/VV11
#     ('coined' forbidden); over the REAL core -- Q20-02 (grammar), Q20-03
#     ('coined' absent).
#     editorial half (D1's in-scope-column closure; direction audited at
#     D6d) -- NO assertion id, by design. Not machine-checkable from a
#     PERMANENT artifact: D1's traversal record is the transient research
#     report (this feature's own Layers & Components split puts it under
#     `.aid/works/`), so a test would have to depend on a work folder to cite
#     it -- forbidden project-wide. The shipped file's "Flagged tokens" header
#     comment IS the permanent record of the audit, but asserting its mere
#     PRESENCE would be a vacuous structural check, not a check of the CLAIM
#     (that all 64 token occurrences were actually classed against the live
#     standards). Raised against feature-001 rather than forced: a claim about
#     a citation's meaning and direction has no oracle short of a human
#     re-reading the six standards, which is what the 2026-07-29 review round
#     already did once and recorded at D6d.
#   AC-S3 (category count == the SPEC's stated count; one-line meaning; every
#          entry's category is a declared name; no declared category is empty)
#     "entry's category is declared" -- mechanism: VV04; over the real core:
#     folded into Q20-00 (category totality -- declared >= used -- is a load
#     gate).
#     "one-line meaning" -- mechanism: CAT03 (new, this task: an empty
#     category meaning is rejected); over the real core: folded into Q20-00
#     (an empty meaning could not have loaded).
#     "no declared category is empty" (the converse -- used >= declared -- and
#     so the count clause, since totality + this together make declared ==
#     used) -- CAT01 (new, this task), proven non-vacuous by CAT02 (new, this
#     task: the LOAD itself does not reject an orphan category, checked
#     directly, so CAT01's own set-equality check is the only thing that would
#     ever catch one).
#   AC-S4 (endpoint_kinds: <kind>-><kind>, both sides in the Kind enum read
#          from relationship-schema.yml, no id-prefix token)
#     mechanism -- VV12 (an id prefix rejected), VV13 (a non-Kind side), VV14
#     (no arrow); over the REAL core -- Q20-01 (every side is a member of
#     `rel_kinds`, which SC07 pins to the seven-value enum read from the
#     schema carrier).
#   AC-S5 (pair coherence: agreement on category/derived_from/passes across an
#          asymmetric pair; symmetric closure under transposition)
#     mechanism -- PC01/PC02 (transpose violations), PC03/PC04/PC05
#     (agreement violations), PC06 (the SET reading, positive); over the REAL
#     core -- Q20-00 (pair coherence is a load gate for every relation `rel__
#     vocab_cross_check` visits, real core included) and Q20-04 (the transpose
#     clause restated as an explicit set property over the whole declared
#     set).
#   AC-S6 (a worked row per §5.1's three sources plus the image-reference
#          mapping, using only vocabulary terms in both relation columns, free
#          text confined to Observation)
#     NO assertion existed before this task: the shipped file's own D9 worked
#     rows (its header comment) were never checked against the `pairs:` block
#     they illustrate. Added this task -- D9-00..D9-08 (parses the four rows
#     out of the shipped file and checks each against the loaded core:
#     membership, pairing, the declared endpoint token, legal Provenance, and
#     that Observation never smuggles in a relation label), proven non-vacuous
#     by D9-MUT (a mutated COPY with row 1's relation swapped to a
#     real-but-wrong label, which the same check must now refuse).
#
# Fixtures:
#   Self-built under a mktemp dir, removed on EXIT. Nothing here reads or references
#   `.aid/works/` -- work folders are transient and this suite must outlive them.
#   Every vocabulary fixture uses PLACEHOLDER relation labels, placeholder category
#   names and placeholder standards keys, so no shipped vocabulary value enters the
#   test tree. The two real carriers under canonical/aid/templates/graph/ are read
#   only where the assertion is about them.
#
# Non-vacuity:
#   Every group pairs an accepting case with a rejecting one -- a loader that
#   accepted everything would fail the reject halves, and one that rejected
#   everything would fail the accept halves. The `mutate` helper below is the guard
#   against the two ways a negative fixture silently tests nothing: it FAILS the
#   suite if its anchor is absent, and again if the replacement leaves the file
#   byte-identical. Fixtures are anchored on literal text, never on a line number.
#
# Usage:
#   bash test-graph-schema-loader.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all assertions pass
#   1 -- one or more assertions failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

LIB="${REPO_ROOT}/canonical/aid/scripts/graph/relationship-schema.sh"
SCHEMA="${REPO_ROOT}/canonical/aid/templates/graph/relationship-schema.yml"
VOCAB_CORE="${REPO_ROOT}/canonical/aid/templates/graph/relation-vocabulary.yml"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ERR="$TMP/stderr.txt"

assert_file_exists "$LIB" "PRE library present"
assert_file_exists "$SCHEMA" "PRE schema carrier present"
assert_file_exists "$VOCAB_CORE" "PRE core vocabulary present"

# S5 snapshot: every mutation in this suite writes to a mktemp COPY and never
# to these three real files (`mutate`'s <dst> and every `cp .../"$TMP"/...`
# target are the only write targets a reviewer needs to check) -- WT01 at the
# bottom of this run turns that structural claim into a checked property.
cp "$LIB" "$TMP/.snapshot-lib.sh"
cp "$SCHEMA" "$TMP/.snapshot-schema.yml"
cp "$VOCAB_CORE" "$TMP/.snapshot-vocab.yml"

# shellcheck source=../../canonical/aid/scripts/graph/relationship-schema.sh disable=SC1090
source "$LIB"

# ---------------------------------------------------------------------------
# mutate <label> <src> <dst> <find> <replace>
#
# Literal, PATTERN-anchored fixture mutation. Never a line number: a sibling suite
# once built two negative fixtures with `sed '13s/.../.../'` against line numbers
# that had shifted, and both reported success while testing nothing.
#
# THREE guards, each of which FAILS the suite loudly rather than producing a fixture
# that quietly exercises nothing:
#   1. the anchor must be PRESENT in <src>;
#   2. the anchor must be UNIQUE in <src>;
#   3. the result must DIFFER from <src>.
#
# Guard 1 catches an anchor that has drifted out of the file. Guard 3 catches a
# replacement that replaced text with itself. Guard 2 is the one earned the hard
# way: a first draft of this suite anchored a schema probe on `kinds:`, which also
# appears in three COMMENT lines of that carrier, so the mutation edited a comment,
# left the data untouched, and produced a fixture that tested nothing. Guards 1 and
# 3 both passed on it -- the anchor was present and the file did change. Only
# uniqueness catches that class, so a mutation whose anchor is ambiguous is a
# FIXTURE BUG here and not a coin toss.
#
# `$(<file)` is a fork-free read and the replacement is parameter expansion, so a
# fixture costs no process. Line numbers are never used: a sibling suite once built
# two negative fixtures with `sed '13s/.../.../'` against line numbers that had
# since shifted, and both reported success while testing nothing.
# ---------------------------------------------------------------------------
mutate() {
    local label="$1" src="$2" dst="$3" find="$4" repl="$5" body new rest occurrences
    body="$(<"$src")"
    case "$body" in
        *"$find"*) ;;
        *) fail "$label — FIXTURE BUG: anchor absent from $(basename "$src"): '$find'"; return 1 ;;
    esac
    occurrences=0
    rest="$body"
    while [[ "$rest" == *"$find"* ]]; do
        occurrences=$((occurrences + 1))
        rest="${rest#*"$find"}"
        [[ $occurrences -gt 1 ]] && break
    done
    if [[ $occurrences -gt 1 ]]; then
        fail "$label — FIXTURE BUG: anchor is AMBIGUOUS in $(basename "$src") (matches more than once): '$find'"
        return 1
    fi
    new="${body/"$find"/"$repl"}"
    if [[ "$new" == "$body" ]]; then
        fail "$label — FIXTURE BUG: the replacement left the fixture byte-identical"
        return 1
    fi
    printf '%s\n' "$new" > "$dst"
    return 0
}

# reject <label> <core-fixture> <expected-stderr-substring>
#   The load must return 2 AND say why. Asserting the message is what stops a
#   rejection for an unrelated reason from being read as this rule firing.
reject() {
    local label="$1" core="$2" want="$3" rc=0
    rel_load_vocabulary "$core" 2>"$ERR" || rc=$?
    if [[ $rc -ne 2 ]]; then
        fail "$label — expected the load to return 2, got $rc"
    else
        assert_file_contains "$ERR" "$want" "$label"
    fi
}

# accept <label> <core-fixture> [<extension-fixture>]
accept() {
    local label="$1" core="$2" ext="${3:-}" rc=0
    rel_load_vocabulary "$core" "$ext" 2>"$ERR" || rc=$?
    assert_exit_eq "$rc" 0 "$label"
    [[ $rc -eq 0 ]] || { [[ $VERBOSE -eq 1 ]] && cat "$ERR"; }
    return 0
}

# Restore a known-good merged load. Called only where an assertion READS the merged
# set, never after every reject: a rejected load leaves the tables partially
# populated, and the next load resets them all before parsing, so a reload between
# two rejections buys nothing and costs an awk fork -- about 100 of them across this
# suite, which is ~40 s on Windows Git Bash.
#
# The SCHEMA is deliberately not reloaded here: `rel_load_vocabulary` never touches
# the Kind or Provenance enums, so a rejected VOCABULARY load cannot disturb them.
# The one place a rejected SCHEMA load has to be undone is at the end of the
# fail-closed block below, and it is undone there explicitly.
reload_base() {
    rel_load_vocabulary "$TMP/base.yml" >/dev/null 2>&1
}

# ===========================================================================
# The base vocabulary fixture: one asymmetric pair plus one symmetric entry, all
# coherent. Every value is unique, so every `mutate` anchor below is unambiguous.
# ===========================================================================
cat > "$TMP/base.yml" <<'EOF'
# a full-line comment before anything, which the loader must skip
pairs:

  # --- a grouping comment, of the shape the real carrier uses ---
  - relation: aaa-forward
    inverse: aaa-back
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section", "section->concept"]
    passes: [declared, derived]
    definition: "The source stands in the forward relation to the target."

  - relation: aaa-back
    inverse: aaa-forward
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "concept->section"]
    passes: [declared, derived]
    definition: "The source stands in the backward relation to the target."

  - relation: sss-both
    inverse: sss-both
    symmetry: symmetric
    category: cat-two
    derived_from: ["std:TermTwo"]
    endpoint_kinds: ["document->document", "section->concept", "concept->section"]
    passes: [declared]
    definition: "The source and the target stand in the same relation to each other."

categories:
  - "cat-one|A first placeholder category."
  - "cat-two|A second placeholder category."
EOF

# ===========================================================================
# === SC: the schema carrier -- loads, exposes, and fails CLOSED ============
# ===========================================================================
echo ""
echo "=== SC: the schema carrier loads and exposes every declared key ==="

rc=0
rel_load_schema "$SCHEMA" 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 0 "SC01 the real schema carrier loads"

assert_eq "$(rel_columns | grep -c .)" "10" \
    "SC02 the column list is the ten-column contract"
assert_eq "$(rel_columns | tr '\n' '/')" \
    "Source Id/Source Kind/Source Name/Target Id/Target Kind/Target Name/S2T Relation/T2S Relation/Provenance/Observation/" \
    "SC03 the columns are in their fixed order, each Kind adjacent to its id"
assert_eq "$(rel_optional_columns | tr -d '\n')" "Observation" \
    "SC04 Observation is the one optional column"
assert_eq "$(rel_provenance_values)" "declared derived inferred" \
    "SC05 the Provenance enum"
assert_eq "$(rel_prefixes)" "kb int ext" \
    "SC06 the id-prefix set"
assert_eq "$(rel_kinds)" "document concept fact section source-artifact image web-page" \
    "SC07 the Kind enum, in carrier order"
assert_eq "$(rel_image_extensions)" "png jpg jpeg gif svg webp avif bmp ico" \
    "SC08 the image-extension set"

# The branching kind is the whole reason the pairing is data rather than code: a
# one-to-one implementation would reject every valid external image.
assert_eq "$(rel_kind_prefixes image)" "int ext" \
    "SC09 the branching kind carries a SET of two permitted prefixes"
assert_eq "$(rel_kind_prefixes document)" "kb" \
    "SC10 a single-prefix kind carries exactly one"
assert_eq "$(rel_kind_prefixes web-page)" "ext" \
    "SC11 the external-only kind carries exactly one"

# `REL_IMAGE_EXTENSIONS` and `rel_image_extensions` are BOTH read by the source
# scanner's schema seam, so both shapes are asserted rather than assumed.
assert_eq "$REL_IMAGE_EXTENSIONS" "$(rel_image_extensions)" \
    "SC12 the global and the accessor agree on image_extensions"

echo ""
echo "=== SC-FC: the schema carrier fails CLOSED, one probe per way to break it ==="

# Each probe copies the real carrier and breaks ONE thing. `kinds:` is dropped with
# a block-aware edit because the word also appears in three comment lines, and an
# anchor that matched a comment would leave the data intact -- a fixture that tests
# nothing while appearing to pass.
awk '
    /^kinds:/ { drop = 1; next }
    drop && /^  - / { next }
    { drop = 0; print }
' "$SCHEMA" > "$TMP/sch-nokinds.yml"
if grep -q '^kinds:' "$TMP/sch-nokinds.yml"; then
    fail "SC-FC01 kinds: block absent — FIXTURE BUG: the block survived the edit"
else
    rc=0; rel_load_schema "$TMP/sch-nokinds.yml" 2>"$ERR" || rc=$?
    if [[ $rc -ne 2 ]]; then
        fail "SC-FC01 kinds: block absent — expected 2, got $rc"
    else
        assert_file_contains "$ERR" "required key 'kinds' is absent" \
            "SC-FC01 an absent kinds: block exits 2 before any row is examined"
    fi
fi

sc_reject() {  # sc_reject <label> <find> <replace> <want>
    local label="$1" find="$2" repl="$3" want="$4" rc=0
    mutate "$label" "$SCHEMA" "$TMP/sch.yml" "$find" "$repl" || return
    rel_load_schema "$TMP/sch.yml" 2>"$ERR" || rc=$?
    if [[ $rc -ne 2 ]]; then
        fail "$label — expected 2, got $rc"
    else
        assert_file_contains "$ERR" "$want" "$label"
    fi
}

sc_reject "SC-FC02 a kind naming a prefix outside the prefix set" \
    '"document|kb"' '"document|nosuchprefix"' \
    "names prefix 'nosuchprefix'"
sc_reject "SC-FC03 an empty prefix set" \
    'prefixes: [kb, int, ext]' 'prefixes: []' \
    "'REL_PREFIXES' resolved empty"
sc_reject "SC-FC04 a mistyped top-level key" \
    'columns: [Source Id' 'columnz: [Source Id' \
    "unknown top-level key 'columnz'"
sc_reject "SC-FC05 a column in neither required nor optional" \
    'optional: [Observation]' 'optional: []' \
    "'REL_OPTIONAL' resolved empty"
sc_reject "SC-FC06 an empty image-extension set" \
    'image_extensions: [png, jpg, jpeg, gif, svg, webp, avif, bmp, ico]' 'image_extensions: []' \
    "'REL_IMAGE_EXTENSIONS' resolved empty"
# Anchored on the data line PLUS its first item, because the bare word also appears
# in three comment lines of this carrier -- see the `mutate` uniqueness guard.
sc_reject "SC-FC07 kinds: given an inline value instead of a block" \
    'kinds:
  - "document|kb"' 'kinds: [document]' \
    "must be a block sequence"

rc=0; rel_load_schema "$TMP/nope-absent.yml" 2>"$ERR" || rc=$?
if [[ $rc -ne 2 ]]; then
    fail "SC-FC08 an absent carrier — expected 2, got $rc"
else
    assert_file_contains "$ERR" "schema carrier not found at" \
        "SC-FC08 an absent carrier exits 2 and names its resolved absolute path"
fi

# Back to a good schema for everything below.
rel_load_schema "$SCHEMA" >/dev/null 2>&1

# ===========================================================================
# === Q20: the two token-set properties -- asserted as SETS, never counts ===
# ===========================================================================
echo ""
echo "=== Q20: the loader must not reject the vocabulary it exists to load ==="

rc=0
rel_load_vocabulary "$VOCAB_CORE" 2>"$ERR" || rc=$?
if [[ $rc -ne 0 ]]; then
    fail "Q20-00 the real core vocabulary loads — returned $rc"
    [[ $VERBOSE -eq 1 ]] && cat "$ERR"
else
    pass "Q20-00 the real core vocabulary loads clean (every value rule, every cross-entry property, pair coherence included)"
fi

# Property 1: every distinct `<kind>-><kind>` token declared anywhere in the
# vocabulary has BOTH sides in the schema carrier's Kind enum. Stated over the set;
# no cardinality is asserted, because the set is externally owned and a numeral
# standing in for it goes stale without being edited.
kinds_enum="$(rel_kinds)"
bad_sides=""
bad_grammar=""
missing_transpose=""
coined_in_core=""
empty_passes=""
while IFS= read -r r; do
    [[ -n "$r" ]] || continue
    rel_endpoint_kinds_into "$r" && toks="$REL_LOOKUP" || toks=""
    for t in $toks; do
        a="${t%%->*}"; b="${t#*->}"
        rel__has_word "$kinds_enum" "$a" || bad_sides="${bad_sides} ${r}:${t}(left)"
        rel__has_word "$kinds_enum" "$b" || bad_sides="${bad_sides} ${r}:${t}(right)"
    done
    rel_passes_into "$r" && p="$REL_LOOKUP" || p=""
    [[ -n "$p" ]] || empty_passes="${empty_passes} ${r}"
    rel__lookup "$REL_T_DERIVED_FROM" "$r" && df="$REL_LOOKUP" || df=""
    for t in $df; do
        rel__derived_token_ok "$t" || bad_grammar="${bad_grammar} ${r}:${t}"
        [[ "$t" == "coined" ]] && coined_in_core="${coined_in_core} ${r}"
    done
done < <(rel_vocab_relations)

assert_eq "$bad_sides" "" \
    "Q20-01 every declared endpoint token has both sides in the Kind enum"
assert_eq "$bad_grammar" "" \
    "Q20-02 every derived_from token matches 'coined' or the standards-token grammar"
assert_eq "$coined_in_core" "" \
    "Q20-03 'coined' appears in no entry of the delivered core"

# The transposition property, over the whole declared set. It is what makes the
# "declared" and "with transposes" readings of that set the same thing -- which is
# why a count of either was never the contract.
while IFS= read -r r; do
    [[ -n "$r" ]] || continue
    rel_endpoint_kinds_into "$r" && toks="$REL_LOOKUP" || toks=""
    rel__lookup "$REL_T_INVERSE" "$r" && inv="$REL_LOOKUP" || inv=""
    rel_endpoint_kinds_into "$inv" && itoks="$REL_LOOKUP" || itoks=""
    for t in $toks; do
        a="${t%%->*}"; b="${t#*->}"
        rel__has_word "$itoks" "$b->$a" || missing_transpose="${missing_transpose} ${r}:${t}"
    done
done < <(rel_vocab_relations)
assert_eq "$missing_transpose" "" \
    "Q20-04 every declared endpoint token's transpose is declared on the inverse entry"

# ===========================================================================
# === EX: the exposure surface, `passes` included ===========================
# ===========================================================================
echo ""
echo "=== EX: every key the consumer table routes through this loader ==="

assert_eq "$empty_passes" "" \
    "EX01 'passes' is exposed and non-empty for EVERY relation in the merged set"

missing_exposure=""
while IFS= read -r r; do
    [[ -n "$r" ]] || continue
    for fn in rel_inverse_of rel_category rel_endpoint_kinds rel_passes rel_definition rel_derived_from rel_relation_origin; do
        "$fn" "$r" >/dev/null 2>&1 || missing_exposure="${missing_exposure} ${fn}(${r})"
    done
done < <(rel_vocab_relations)
assert_eq "$missing_exposure" "" \
    "EX02 every exposed accessor answers for every relation"

# Membership and pairing are the two the row-level checks consume.
first_rel="$(rel_vocab_relations | head -1)"
rel_is_relation "$first_rel" && pass "EX03 rel_is_relation accepts a declared label" \
    || fail "EX03 rel_is_relation accepts a declared label — rejected '$first_rel'"
rel_is_relation "zz-no-such-relation" \
    && fail "EX04 rel_is_relation rejects an undeclared label — accepted it" \
    || pass "EX04 rel_is_relation rejects an undeclared label"

rel__lookup "$REL_T_INVERSE" "$first_rel" && first_inv="$REL_LOOKUP" || first_inv=""
rel_pair_ok "$first_rel" "$first_inv" \
    && pass "EX05 rel_pair_ok accepts a declared pair" \
    || fail "EX05 rel_pair_ok accepts a declared pair — rejected ($first_rel, $first_inv)"
rel_pair_ok "$first_inv" "$first_rel" \
    && pass "EX06 rel_pair_ok accepts the MIRROR orientation (what makes storage normalisation safe)" \
    || fail "EX06 rel_pair_ok accepts the mirror orientation — rejected it"
rel_pair_ok "$first_rel" "zz-no-such-relation" \
    && fail "EX07 rel_pair_ok rejects a non-pair — accepted it" \
    || pass "EX07 rel_pair_ok rejects a non-pair"

# Two declared keys are validated and deliberately NOT exposed as accessors.
if declare -F rel_symmetry >/dev/null 2>&1; then
    fail "EX08 'symmetry' has no accessor — one was found"
else
    pass "EX08 'symmetry' is validated but exposes no accessor (its only consumer is the pairing check)"
fi

# ===========================================================================
# === CAT: category completeness over the REAL core (feature-001 AC-S3) =====
# ===========================================================================
echo ""
echo "=== CAT: every declared category classifies something, over the shipped core ==="

# AC-S3's count clause reads "the stated count is the count of categories that
# actually classify something" -- so this is a SET EQUALITY (declared categories
# == categories some relation actually uses), never a literal cardinality. The
# loader's own category-totality gate (exercised at Q20-00 above) only checks
# the REFERENCE half -- a relation's category must be declared -- never the
# converse, so an orphan category the loader would happily load is exactly
# what this new check exists to catch.
used_cats=""
while IFS= read -r r; do
    [[ -n "$r" ]] || continue
    rel__lookup "$REL_T_CATEGORY" "$r" && used_cats="${used_cats}${REL_LOOKUP}
"
done < <(rel_vocab_relations)
used_cats_sorted="$(printf '%s' "$used_cats" | sort -u | grep -v '^$')"
declared_cats_sorted="$(rel_categories | sort -u)"
if [[ -z "$declared_cats_sorted" || -z "$used_cats_sorted" ]]; then
    fail "CAT01 — HARNESS BUG: read $(printf '%s\n' "$declared_cats_sorted" | grep -c .) declared and $(printf '%s\n' "$used_cats_sorted" | grep -c .) used categories from the real core"
else
    assert_eq "$used_cats_sorted" "$declared_cats_sorted" \
        "CAT01 the real core's declared categories: block equals the set actually used by some relation -- no declared category is empty (AC-S3)"
fi

# Non-vacuity (S3): prove the LOAD does not itself reject an orphan category,
# so CAT01's set-equality check above is the only thing that would ever catch
# one. Mutates a COPY of the real core, never the source tree (S5).
cp "$VOCAB_CORE" "$TMP/core-orphan.yml"
printf '  - "zz-orphan-category|A category no relation in this file ever names."\n' >> "$TMP/core-orphan.yml"
rc=0
rel_load_vocabulary "$TMP/core-orphan.yml" 2>"$ERR" || rc=$?
if [[ $rc -ne 0 ]]; then
    fail "CAT02 — FIXTURE BUG: appending one unused category to a COPY of the real core broke the load (rc=$rc): $(<"$ERR")"
else
    orphan_used=""
    while IFS= read -r r; do
        [[ -n "$r" ]] || continue
        rel__lookup "$REL_T_CATEGORY" "$r" && orphan_used="${orphan_used}${REL_LOOKUP}
"
    done < <(rel_vocab_relations)
    orphan_used_sorted="$(printf '%s' "$orphan_used" | sort -u | grep -v '^$')"
    orphan_declared_sorted="$(rel_categories | sort -u)"
    if [[ "$orphan_used_sorted" == "$orphan_declared_sorted" ]]; then
        fail "CAT02 an orphan category added to a COPY of the real core — CAT01's own check failed to notice it"
    else
        pass "CAT02 the load itself does NOT reject an orphan category (category totality is reference-only), so CAT01's set-equality check is provably not vacuous"
    fi
fi

# The other half of AC-S3's "one-line meaning" clause: the mechanism that
# would reject an empty meaning has never been exercised by a fixture. Reuses
# the base fixture already on disk (written before the SC section, above).
mutate "CAT03" "$TMP/base.yml" "$TMP/v.yml" \
    '  - "cat-two|A second placeholder category."' \
    '  - "cat-two|"' \
    && reject "CAT03 a categories: item with an empty meaning is rejected (mechanism proof for AC-S3's 'one-line meaning')" \
        "$TMP/v.yml" "has an empty side"

# Restore the real core as the active load for the D9 section below, which
# also reads it through the accessors.
rel_load_vocabulary "$VOCAB_CORE" >/dev/null 2>&1

# ===========================================================================
# === D9: the shipped worked rows, checked against the pairs: block =========
# === (feature-001 AC-S6) ====================================================
# ===========================================================================
echo ""
echo "=== D9: the vocabulary file's own worked rows are legal against itself ==="

# check_worked_row <label-prefix> <s2t> <t2s> <source-kind> <target-kind>
#                   <provenance> <observation>
#   The six checks AC-S6 needs for one worked row: both relation labels are
#   members, they form a declared inverse pair, the row's own kind pair is a
#   declared endpoint token of the S2T relation, the row's Provenance is legal
#   for that relation's `passes`, and Observation never smuggles in a relation
#   label. Every accessor called here is already proven correct elsewhere in
#   this suite (EX03-EX07, Q20-01); what is NEW here is comparing the header
#   comment's prose against the `pairs:` block it illustrates, which is not
#   vacuous by construction -- the two are independently authored text, and
#   D9-MUT below proves a divergence between them is caught.
check_worked_row() {
    local lp="$1" s2t="$2" t2s="$3" skind="$4" tkind="$5" prov="$6" obs="$7" tok toks ptoks
    if [[ -z "$s2t" || -z "$t2s" || -z "$skind" || -z "$tkind" || -z "$prov" || -z "$obs" ]]; then
        fail "${lp} — HARNESS BUG: a required field parsed empty (s2t='$s2t' t2s='$t2s' skind='$skind' tkind='$tkind' prov='$prov' obs='$obs')"
        return
    fi
    tok="${skind}->${tkind}"

    rel_is_relation "$s2t" && pass "${lp}a S2T Relation '$s2t' is a member of the merged vocabulary" \
        || fail "${lp}a S2T Relation '$s2t' is a member of the merged vocabulary — rejected"
    rel_is_relation "$t2s" && pass "${lp}b T2S Relation '$t2s' is a member of the merged vocabulary" \
        || fail "${lp}b T2S Relation '$t2s' is a member of the merged vocabulary — rejected"
    rel_pair_ok "$s2t" "$t2s" && pass "${lp}c '$s2t' / '$t2s' is a declared inverse pair" \
        || fail "${lp}c '$s2t' / '$t2s' is a declared inverse pair — rejected"

    rel_endpoint_kinds_into "$s2t" && toks="$REL_LOOKUP" || toks=""
    rel__has_word "$toks" "$tok" && pass "${lp}d the row's kind pair '$tok' is a declared endpoint of '$s2t'" \
        || fail "${lp}d the row's kind pair '$tok' is a declared endpoint of '$s2t' — not in: $toks"

    rel_passes_into "$s2t" && ptoks="$REL_LOOKUP" || ptoks=""
    rel__has_word "$ptoks" "$prov" && pass "${lp}e Provenance '$prov' is legal for '$s2t' (a member of its 'passes')" \
        || fail "${lp}e Provenance '$prov' is legal for '$s2t' — not in: $ptoks"

    if [[ "$obs" == "(left empty)" ]]; then
        pass "${lp}f Observation is empty -- nothing but free-text nuance, vacuously"
    elif rel_is_relation "$obs"; then
        fail "${lp}f Observation '$obs' is itself a vocabulary relation label"
    else
        pass "${lp}f Observation carries free text, never a vocabulary term"
    fi
}

# One read of the shipped file, parsing its four worked rows (D9) out of the
# header comment. Field names are the ten-column contract's own labels, never
# a vocabulary value, so this stays a structural anchor rather than a content
# literal.
d9_records="$(awk '
    /^# [0-9]+\. / { if (n>0) print "===RECORD==="; n++; next }
    /^#      (Source Id|Source Kind|Source Name|Target Id|Target Kind|Target Name|S2T Relation|T2S Relation|Provenance|Observation)  / {
        line=$0
        sub(/^#      /, "", line)
        key=line
        sub(/  +.*/, "", key)
        val=line
        sub("^" key "  +", "", val)
        print key "\t" val
    }
' "$VOCAB_CORE")"

declare -A d9_row
d9_idx=0
d9_srcprefix=(); d9_tgtprefix=(); d9_skind=(); d9_tkind=()

flush_d9_row() {
    [[ -n "${d9_row["S2T Relation"]:-}" ]] || return 0
    d9_idx=$((d9_idx + 1))
    check_worked_row "D9-0${d9_idx}" "${d9_row["S2T Relation"]}" "${d9_row["T2S Relation"]}" \
        "${d9_row["Source Kind"]}" "${d9_row["Target Kind"]}" "${d9_row["Provenance"]}" "${d9_row["Observation"]}"
    d9_srcprefix+=("${d9_row["Source Id"]%%:*}")
    d9_tgtprefix+=("${d9_row["Target Id"]%%:*}")
    d9_skind+=("${d9_row["Source Kind"]}")
    d9_tkind+=("${d9_row["Target Kind"]}")
}

while IFS=$'\t' read -r key val; do
    if [[ "$key" == "===RECORD===" ]]; then
        flush_d9_row
        d9_row=()
        continue
    fi
    d9_row["$key"]="$val"
done <<< "$d9_records"
flush_d9_row

if [[ "$d9_idx" -ne 4 ]]; then
    fail "D9-00 — the header comment carries $d9_idx worked rows, expected the 4 that §5.1's three sources plus the image-reference mapping require"
else
    pass "D9-00 the header comment carries exactly the four worked rows §5.1 and D6c require"

    # Coverage: the four rows must span KB-to-KB, KB-to-source and KB-to-external
    # (§5.1's three sources) plus at least one image-kind endpoint (D6c). Read
    # from the id PREFIXES the rows themselves carry, never from a relation name.
    combo=""
    for i in 0 1 2 3; do
        combo="${combo}${d9_srcprefix[$i]}->${d9_tgtprefix[$i]} "
    done
    assert_output_contains "$combo" "kb->kb" "D9-05 the worked rows include a KB-to-KB row (§5.1 source 1)"
    assert_output_contains "$combo" "kb->int" "D9-06 the worked rows include a KB-to-source row (§5.1 source 2)"
    assert_output_contains "$combo" "kb->ext" "D9-07 the worked rows include a KB-to-external row (§5.1 source 3)"

    image_hit=""
    for k in "${d9_skind[@]}" "${d9_tkind[@]}"; do
        [[ "$k" == "image" ]] && image_hit=1
    done
    if [[ -n "$image_hit" ]]; then
        pass "D9-08 the worked rows include an image-kind endpoint (D6c's image-reference mapping)"
    else
        fail "D9-08 the worked rows include an image-kind endpoint — none found"
    fi
fi

# Non-vacuity (S3): the comparison above is between two independently authored
# parts of the same file (D6's pairs: block and D9's prose), so it is not
# vacuous by construction -- but the proof is required, not assumed. A COPY
# with row 1's S2T Relation swapped to a label that IS a member but does NOT
# declare the same row's kind pair must be a mismatch the same check would
# catch.
mutate "D9-MUT" "$VOCAB_CORE" "$TMP/vocab-badrow.yml" \
    '#      S2T Relation   defines' \
    '#      S2T Relation   has-part' \
    && {
        rc=0
        rel_load_vocabulary "$TMP/vocab-badrow.yml" 2>"$ERR" || rc=$?
        if [[ $rc -ne 0 ]]; then
            fail "D9-MUT — FIXTURE BUG: a COPY of the real core with only a comment line edited failed to load (rc=$rc): $(<"$ERR")"
        else
            rel_endpoint_kinds_into "has-part" && badtoks="$REL_LOOKUP" || badtoks=""
            if rel__has_word "$badtoks" "section->concept"; then
                fail "D9-MUT — FIXTURE BUG: 'has-part' legally declares 'section->concept', so this mutation exercises nothing"
            else
                pass "D9-MUT row 1's cross-check against the pairs: block is provably NOT vacuous: swapping its relation to a real-but-wrong label ('has-part') is a mismatch the same check would catch"
            fi
        fi
    }
rel_load_vocabulary "$VOCAB_CORE" >/dev/null 2>&1

# ===========================================================================
# === VK: totality, the fixed key order, the declared key set ===============
# ===========================================================================
echo ""
echo "=== VK: every declared key is validated, whether or not this feature reads it ==="

reload_base
accept "VK00 the base fixture vocabulary loads (comments anywhere, one pair plus one symmetric entry)" "$TMP/base.yml"

mutate "VK01" "$TMP/base.yml" "$TMP/v.yml" \
    '    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section", "section->concept"]' \
    '    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section", "section->concept"]' \
    && reject "VK01 a declared key missing" "$TMP/v.yml" "is missing declared key(s): symmetry"

mutate "VK02" "$TMP/base.yml" "$TMP/v.yml" \
    '    inverse: aaa-back
    symmetry: asymmetric' \
    '    inverse: aaa-back
    strength: high
    symmetry: asymmetric' \
    && reject "VK02 a key outside the declared set" "$TMP/v.yml" "outside the declared set: strength"

mutate "VK03" "$TMP/base.yml" "$TMP/v.yml" \
    '    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section"' \
    '    symmetry: asymmetric
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section"' \
    && reject "VK03 a key present twice" "$TMP/v.yml" "carries key 'symmetry' more than once"

mutate "VK04" "$TMP/base.yml" "$TMP/v.yml" \
    '    inverse: aaa-back
    symmetry: asymmetric
    category: cat-one' \
    '    symmetry: asymmetric
    inverse: aaa-back
    category: cat-one' \
    && reject "VK04 keys out of the fixed order" "$TMP/v.yml" "presents its keys out of the fixed order"

mutate "VK05" "$TMP/base.yml" "$TMP/v.yml" \
    '    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section"' \
    '    category:
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section"' \
    && reject "VK05 a declared key with an empty value" "$TMP/v.yml" "category has an empty value"

# ===========================================================================
# === VV: the per-key value rules ===========================================
# ===========================================================================
echo ""
echo "=== VV: each declared key's value rule ==="

mutate "VV01" "$TMP/base.yml" "$TMP/v.yml" '  - relation: aaa-forward' '  - relation: AAA_Forward' \
    && reject "VV01 a relation label breaking its charset" "$TMP/v.yml" "'relation' value 'AAA_Forward'"
mutate "VV02" "$TMP/base.yml" "$TMP/v.yml" '    inverse: aaa-back
    symmetry: asymmetric
    category: cat-one' '    inverse: AAA-Back
    symmetry: asymmetric
    category: cat-one' \
    && reject "VV02 an inverse label breaking its charset" "$TMP/v.yml" "'inverse' value 'AAA-Back'"
mutate "VV03" "$TMP/base.yml" "$TMP/v.yml" '    symmetry: symmetric' '    symmetry: antisymmetric' \
    && reject "VV03 a symmetry outside its closed enum" "$TMP/v.yml" "must be asymmetric or symmetric"
mutate "VV04" "$TMP/base.yml" "$TMP/v.yml" '    category: cat-two' '    category: cat-undeclared' \
    && reject "VV04 a category the merged categories: block does not declare" "$TMP/v.yml" \
        "category totality: relation 'sss-both' names category 'cat-undeclared'"
mutate "VV05" "$TMP/base.yml" "$TMP/v.yml" \
    '    derived_from: ["std:TermTwo"]
    endpoint_kinds: ["document->document"' \
    '    endpoint_kinds: ["document->document"' \
    && reject "VV05 derived_from absent" "$TMP/v.yml" "is missing declared key(s): derived_from"
mutate "VV06" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '["stdTermTwo"]' \
    && reject "VV06 a derived_from token with no colon" "$TMP/v.yml" "matches neither 'coined' nor"
mutate "VV07" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '["9std:TermTwo"]' \
    && reject "VV07 a derived_from key beginning with a digit" "$TMP/v.yml" "matches neither 'coined' nor"
mutate "VV08" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '["std:9TermTwo"]' \
    && reject "VV08 a derived_from term beginning with a digit" "$TMP/v.yml" "matches neither 'coined' nor"
mutate "VV09" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '[std:TermTwo]' \
    && reject "VV09 derived_from tokens not double quoted" "$TMP/v.yml" "tokens must be double quoted"
mutate "VV10" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '["coined"]' \
    && reject "VV10 'coined' in a CORE entry" "$TMP/v.yml" "'coined' is forbidden in the core vocabulary"
mutate "VV11" "$TMP/base.yml" "$TMP/v.yml" '["std:TermTwo"]' '["std:TermTwo", "coined"]' \
    && reject "VV11 'coined' beside a standards token" "$TMP/v.yml" "'coined' is forbidden in the core vocabulary"
mutate "VV12" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: ["kb:->kb:"]' \
    && reject "VV12 an endpoint token naming an id PREFIX (the migration regression)" "$TMP/v.yml" \
        "names something that is not a Kind"
mutate "VV13" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: ["document->paragraph"]' \
    && reject "VV13 an endpoint side that is not a Kind" "$TMP/v.yml" "names something that is not a Kind"
mutate "VV14" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: ["document-document"]' \
    && reject "VV14 an endpoint token with no arrow" "$TMP/v.yml" "is not '<kind>-><kind>'"
mutate "VV15" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: []' \
    && reject "VV15 endpoint_kinds empty" "$TMP/v.yml" "'endpoint_kinds' is empty"
mutate "VV16" "$TMP/base.yml" "$TMP/v.yml" \
    '    passes: [declared]
    definition: "The source and the target' '    passes: [declared, guessed]
    definition: "The source and the target' \
    && reject "VV16 a passes value outside the Provenance enum" "$TMP/v.yml" "is not in the Provenance enum"
mutate "VV17" "$TMP/base.yml" "$TMP/v.yml" \
    '    passes: [declared]
    definition: "The source and the target' '    passes: []
    definition: "The source and the target' \
    && reject "VV17 passes empty" "$TMP/v.yml" "'passes' is empty"
mutate "VV18" "$TMP/base.yml" "$TMP/v.yml" \
    '    definition: "The source and the target stand in the same relation to each other."' \
    '    definition: Bare prose carrying no quotes at all.' \
    && reject "VV18 a definition that is not a double-quoted scalar" "$TMP/v.yml" "must be a double-quoted scalar"

# ===========================================================================
# === RS: the restricted YAML subset, enforced rather than assumed ==========
# ===========================================================================
echo ""
echo "=== RS: the restricted subset -- what makes two independent loaders agree ==="

mutate "RS01" "$TMP/base.yml" "$TMP/v.yml" '    category: cat-two' '    category: &anch cat-two' \
    && reject "RS01 an anchor" "$TMP/v.yml" "anchor or alias"
mutate "RS02" "$TMP/base.yml" "$TMP/v.yml" '    category: cat-two' '    category: *anch' \
    && reject "RS02 an alias" "$TMP/v.yml" "anchor or alias"
mutate "RS03" "$TMP/base.yml" "$TMP/v.yml" '    symmetry: symmetric' '    <<: base
    symmetry: symmetric' \
    && reject "RS03 a merge key" "$TMP/v.yml" "restricted-YAML violation"
mutate "RS04" "$TMP/base.yml" "$TMP/v.yml" \
    '    definition: "The source and the target stand in the same relation to each other."' \
    '    definition: |' \
    && reject "RS04 a block scalar" "$TMP/v.yml" "block scalar"
mutate "RS05" "$TMP/base.yml" "$TMP/v.yml" 'pairs:' 'pairs:
---' \
    && reject "RS05 a second YAML document" "$TMP/v.yml" "second YAML document"
mutate "RS06" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: ["document->document",
      "section->concept", "concept->section"]' \
    && reject "RS06 a flow sequence split over two physical lines" "$TMP/v.yml" \
        "flow sequence is not on one physical line"
mutate "RS07" "$TMP/base.yml" "$TMP/v.yml" \
    '    passes: [declared]
    definition: "The source and the target' \
    '    passes:
      - declared
    definition: "The source and the target' \
    && reject "RS07 nesting below an entry" "$TMP/v.yml" "restricted-YAML violation"
mutate "RS08" "$TMP/base.yml" "$TMP/v.yml" 'pairs:' 'extras: [a]
pairs:' \
    && reject "RS08 an unknown top-level key" "$TMP/v.yml" "unknown top-level key"

# ===========================================================================
# === CE: the cross-entry invariants over the merged set ====================
# ===========================================================================
echo ""
echo "=== CE: closure, involution, symmetric consistency, uniqueness ==="

# Broken on the SYMMETRIC entry, which has no partner, so closure is reached before
# involution or symmetric consistency can mask it.
mutate "CE01" "$TMP/base.yml" "$TMP/v.yml" '    inverse: sss-both' '    inverse: zzz-missing' \
    && reject "CE01 broken closure (an inverse naming no entry)" "$TMP/v.yml" \
        "closure: relation 'sss-both' declares inverse 'zzz-missing'"
mutate "CE02" "$TMP/base.yml" "$TMP/v.yml" '    inverse: aaa-back
    symmetry: asymmetric' '    inverse: sss-both
    symmetry: asymmetric' \
    && reject "CE02 broken involution with closure intact" "$TMP/v.yml" "involution: inverse(inverse("
mutate "CE03" "$TMP/base.yml" "$TMP/v.yml" '    symmetry: symmetric' '    symmetry: asymmetric' \
    && reject "CE03 a self-inverse entry declaring asymmetric" "$TMP/v.yml" \
        "symmetric consistency: 'sss-both' is its own inverse"
mutate "CE04" "$TMP/base.yml" "$TMP/v.yml" 'categories:' '  - relation: aaa-forward
    inverse: aaa-back
    symmetry: asymmetric
    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["document->section"]
    passes: [declared]
    definition: "A second entry claiming a label the core already declares."

categories:' \
    && reject "CE04 one relation label declared twice inside the core" "$TMP/v.yml" \
        "relation 'aaa-forward' is declared twice"
mutate "CE05" "$TMP/base.yml" "$TMP/v.yml" '  - "cat-two|A second placeholder category."' \
    '  - "cat-two|A second placeholder category."
  - "cat-two|A different meaning for a name already declared."' \
    && reject "CE05 one category name declared twice" "$TMP/v.yml" "category 'cat-two' is declared twice"

awk '/^pairs:/ { print; print ""; next } /^categories:/ { incat = 1 } incat { print }' \
    "$TMP/base.yml" > "$TMP/v-nopairs.yml"
if grep -q '  - relation:' "$TMP/v-nopairs.yml"; then
    fail "CE06 an empty pairs: block — FIXTURE BUG: entries survived the edit"
else
    reject "CE06 an empty pairs: block fails closed" "$TMP/v-nopairs.yml" "no 'pairs:' entries"
fi

rc=0; rel_load_vocabulary "$TMP/nope-absent.yml" 2>"$ERR" || rc=$?
if [[ $rc -ne 2 ]]; then
    fail "CE07 an absent core — expected 2, got $rc"
else
    assert_file_contains "$ERR" "core relation vocabulary not found at" \
        "CE07 an absent core exits 2, naming the blocking dependency"
fi
reload_base

rc=0
rel_load_vocabulary "" 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 2 "CE08 no core argument at all is a usage error"

# ===========================================================================
# === PC: PAIR COHERENCE -- gating, five clauses, plus the positive case ====
# ===========================================================================
echo ""
echo "=== PC: pair coherence gates, and 'equal' means EQUAL AS SETS ==="

mutate "PC01" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["section->document", "concept->section"]' \
    '    endpoint_kinds: ["section->document"]' \
    && reject "PC01 an asymmetric pair whose endpoint sets are not transposes" "$TMP/v.yml" \
        "does not declare the transpose"
mutate "PC02" "$TMP/base.yml" "$TMP/v.yml" \
    '    endpoint_kinds: ["document->document", "section->concept", "concept->section"]' \
    '    endpoint_kinds: ["document->document", "section->concept"]' \
    && reject "PC02 a symmetric entry not closed under transposition" "$TMP/v.yml" \
        "must be closed under transposition"
mutate "PC03a" "$TMP/base.yml" "$TMP/v0.yml" '  - "cat-two|A second placeholder category."' \
    '  - "cat-two|A second placeholder category."
  - "cat-three|A third placeholder category."' \
    && mutate "PC03" "$TMP/v0.yml" "$TMP/v.yml" \
        '    category: cat-one
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "concept->section"]' \
        '    category: cat-three
    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "concept->section"]' \
    && reject "PC03 a pair disagreeing on category" "$TMP/v.yml" "disagree on 'category'"
mutate "PC04" "$TMP/base.yml" "$TMP/v.yml" \
    '    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "concept->section"]' \
    '    derived_from: ["std:TermOther"]
    endpoint_kinds: ["section->document", "concept->section"]' \
    && reject "PC04 a pair disagreeing on derived_from" "$TMP/v.yml" "disagree on 'derived_from'"
mutate "PC05" "$TMP/base.yml" "$TMP/v.yml" \
    '    passes: [declared, derived]
    definition: "The source stands in the backward' \
    '    passes: [declared]
    definition: "The source stands in the backward' \
    && reject "PC05 a pair disagreeing on passes" "$TMP/v.yml" "disagree on 'passes'"

# The POSITIVE case, and it is not decoration: a loader comparing SEQUENCES instead
# of sets passes all five negatives above and then rejects a perfectly legal pair.
# Same tokens, different order, one repeated -- must LOAD.
mutate "PC06a" "$TMP/base.yml" "$TMP/v0.yml" \
    '    derived_from: ["std:TermOne"]
    endpoint_kinds: ["section->document", "concept->section"]
    passes: [declared, derived]' \
    '    derived_from: ["std:TermOne", "std:TermOne"]
    endpoint_kinds: ["concept->section", "section->document"]
    passes: [derived, declared]' \
    && accept "PC06 same tokens in a different order, one repeated, MUST LOAD (the set reading)" "$TMP/v0.yml"

# ===========================================================================
# === MG: the core-plus-extension merge ====================================
# ===========================================================================
echo ""
echo "=== MG: an upgrade never overwrites a project pair, and a collision is hard ==="

cat > "$TMP/ext-clean.yml" <<'EOF'
pairs:
  - relation: bbb-forward
    inverse: bbb-back
    symmetry: asymmetric
    category: cat-proj
    derived_from: ["coined"]
    endpoint_kinds: ["document->image"]
    passes: [declared]
    definition: "A project-defined forward relation."

  - relation: bbb-back
    inverse: bbb-forward
    symmetry: asymmetric
    category: cat-proj
    derived_from: ["coined"]
    endpoint_kinds: ["image->document"]
    passes: [declared]
    definition: "A project-defined backward relation."

categories:
  - "cat-proj|A project-defined category."
EOF
rc=0
rel_load_vocabulary "$TMP/base.yml" "$TMP/ext-clean.yml" 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 0 "MG01 an extension adds cleanly, and 'coined' is legal THERE"
if [[ $rc -eq 0 ]]; then
    assert_output_contains "$(rel_vocab_relations | tr '\n' ' ')" "bbb-forward" \
        "MG02 an extension pair joins the merged membership set"
    assert_output_contains "$(rel_categories | tr '\n' ' ')" "cat-proj" \
        "MG03 an extension category joins the merged category set"
    assert_eq "$(rel_relation_origin bbb-forward)" "extension" \
        "MG04 the loader knows which file an entry came from (what makes the core 'coined' rule decidable)"
    assert_eq "$(rel_relation_origin aaa-forward)" "core" \
        "MG05 a core entry reports origin core"
fi

mutate "MG06" "$TMP/ext-clean.yml" "$TMP/ext.yml" '  - relation: bbb-forward' '  - relation: aaa-forward' \
    && {
        rc=0; rel_load_vocabulary "$TMP/base.yml" "$TMP/ext.yml" 2>"$ERR" || rc=$?
        if [[ $rc -ne 2 ]]; then
            fail "MG06 an extension colliding on a relation label — expected 2, got $rc"
        else
            assert_file_contains "$ERR" "is declared twice" \
                "MG06 an extension colliding on a relation label exits 2, naming BOTH resolved paths"
        fi
    }
mutate "MG07" "$TMP/ext-clean.yml" "$TMP/ext.yml" '  - "cat-proj|A project-defined category."' \
    '  - "cat-one|A project redefinition of a core category name."' \
    && {
        rc=0; rel_load_vocabulary "$TMP/base.yml" "$TMP/ext.yml" 2>"$ERR" || rc=$?
        if [[ $rc -ne 2 ]]; then
            fail "MG07 an extension colliding on a category name — expected 2, got $rc"
        else
            assert_file_contains "$ERR" "category 'cat-one' is declared twice" \
                "MG07 an extension may not silently redefine a core category's meaning"
        fi
    }
# "may not redefine a core pair" needs no rule of its own: involution enforces it.
# A single-entry extension, deliberately: mutating one half of the two-entry
# extension above would orphan the other half and trip CLOSURE first, which would
# have this assertion pass on the wrong rule.
cat > "$TMP/ext-inv.yml" <<'EOF'
pairs:
  - relation: ccc-new
    inverse: aaa-back
    symmetry: asymmetric
    category: cat-proj
    derived_from: ["coined"]
    endpoint_kinds: ["document->image"]
    passes: [declared]
    definition: "An extension entry pointing its inverse at a relation the core owns."

categories:
  - "cat-proj|A project-defined category."
EOF
rc=0; rel_load_vocabulary "$TMP/base.yml" "$TMP/ext-inv.yml" 2>"$ERR" || rc=$?
if [[ $rc -ne 2 ]]; then
    fail "MG08 an extension pointing its inverse at a core relation — expected 2, got $rc"
else
    assert_file_contains "$ERR" "involution" \
        "MG08 an extension cannot redefine a core pair -- involution rejects it, with no rule of its own"
fi

rc=0
rel_load_vocabulary "$TMP/base.yml" "$TMP/no-such-extension.yml" 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 0 "MG09 an ABSENT extension is not an error (the majority case)"

# ===========================================================================
# === SR: the string rules ==================================================
# ===========================================================================
echo ""
echo "=== SR: one implementation of each string rule, checked against fixed cases ==="

# The heading-slug rules. Each case discriminates between candidate rules: a
# deleted character between spaces must leave TWO hyphens (runs are not collapsed),
# and `_` must survive, or a section id stops being the anchor it has to equal.
rel_slug_heading_into "JavaScript / Node Conventions"
assert_eq "$REL_STR" "javascript--node-conventions" \
    "SR01 a deleted '/' between spaces leaves two hyphens (no run collapsing)"
rel_slug_heading_into "Lexicon — Pipeline Run-State"
assert_eq "$REL_STR" "lexicon--pipeline-run-state" \
    "SR02 a deleted em dash behaves the same, and an existing hyphen is kept"
rel_slug_heading_into 'D13 — Per-repo `format_version` stamp (git model)'
assert_eq "$REL_STR" "d13--per-repo-format_version-stamp-git-model" \
    "SR03 '_' is RETAINED, backticks stripped, parentheses deleted without adding hyphens"
rel_slug_heading_into "Abbreviations & Acronyms"
assert_eq "$REL_STR" "abbreviations--acronyms" \
    "SR04 a deleted ampersand between spaces leaves two hyphens"
rel_slug_heading_into "Only ASCII Letters"
assert_eq "$REL_STR" "only-ascii-letters" \
    "SR05 a single space becomes exactly one hyphen"
rel_slug_heading_into "  [A Link](https://example.invalid)  "
assert_eq "$REL_STR" "a-link" \
    "SR06 link brackets are removed and the link TEXT is kept"

# Concept-term normalisation diverges from the slug on purpose: a term folds `_` to
# `-` while a section slug keeps it, and V2 recomputes each against its own rule.
rel_normalise_term_into "AidInstallCore"
assert_eq "$REL_STR" "aid-install-core" \
    "SR07 a compound splits at a lower-to-upper boundary"
rel_normalise_term_into "AIDHome"
assert_eq "$REL_STR" "aid-home" \
    "SR08 a compound splits at an ACRONYM-to-Word boundary"
rel_normalise_term_into "AID_HOME"
assert_eq "$REL_STR" "aid-home" \
    "SR09 '_' folds to '-' for a TERM, where the slug rule would keep it"
rel_normalise_term_into "Concept Spine"
assert_eq "$REL_STR" "concept-spine" \
    "SR10 whitespace folds to a single hyphen"
rel_normalise_term_into "Statuses"
s_plural="$REL_STR"
rel_normalise_term_into "Status"
assert_eq "$s_plural|$REL_STR" "statuses|status" \
    "SR11 plurals are NOT folded -- two labels differing by plurality stay two terms"

# The fact anchor token, including the truncation rule's two branches.
rel_fact_token_into "read-setting.sh" "lookup_list"
assert_eq "$REL_STR" "read-setting-sh--lookup_list" \
    "SR12 the symbol form yields <path-slug>--<anchor-slug>"
rel_fact_token_into "x.md" "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwx"
assert_eq "$REL_STR" "x-md--abcdefghijklmnopqrstuvwxyz0123456789abcd" \
    "SR13 a hyphen-free over-long anchor takes the HARD cut at exactly 40 characters"
rel_fact_token_into "README.md" "A full-lifecycle methodology for building software with AI agents"
assert_eq "$REL_STR" "readme-md--a-full-lifecycle-methodology-for" \
    "SR14 an over-long anchor with a hyphen in range cuts at the word boundary"
rel_fact_token_into "a/b/c.md" "Short"
assert_eq "$REL_STR" "a-b-c-md--short" \
    "SR15 path separators and dots become hyphens, runs collapsed"

# ===========================================================================
# === ID: the per-kind id grammars and the two-tier kind check ==============
# ===========================================================================
echo ""
echo "=== ID: an id is parseable BEFORE its Kind cell is trusted ==="

id_kind() {  # id_kind <label> <id> <expected-grammar-kind>
    local label="$1" id="$2" want="$3"
    if rel_parse_id "$id"; then
        assert_eq "$REL_ID_KIND" "$want" "$label"
    else
        fail "$label — the grammar rejected '$id': $REL_ID_REASON"
    fi
}
id_kind "ID01 a bare kb: body is a document"            "kb:domain-glossary.md" "document"
id_kind "ID02 a '#' fragment is a section"              "kb:domain-glossary.md#concept-spine" "section"
id_kind "ID03 a '#fact:' fragment is a fact"            "kb:a.md#fact:readme-md--x" "fact"
id_kind "ID04 a 'concept:' body is a concept"           "kb:concept:aid-home" "concept"
id_kind "ID05 the document-qualified concept form"      "kb:concept:aid-home@domain-glossary.md" "concept"

id_ok() {  # id_ok <label> <id>
    if rel_parse_id "$2"; then pass "$1"; else fail "$1 — rejected '$2': $REL_ID_REASON"; fi
}
id_ok "ID06 an int: file path"       "int:README.md"
id_ok "ID07 an int: directory path"  "int:canonical/skills/aid-summarize/"
id_ok "ID08 an int: nested path"     "int:docs/images/3-ironman.png"
id_ok "ID09 an ext: key"             "ext:wcag-22-aa"

id_reject() {  # id_reject <label> <id> <expected-reason>
    if rel_parse_id "$2"; then
        fail "$1 — the grammar ACCEPTED '$2'"
    else
        assert_eq "$REL_ID_REASON" "$3" "$1"
    fi
}
id_reject "ID10 an int: id carrying any '#' fragment" "int:src/x.sh#main" "int-fragment"
id_reject "ID11 an int: path escaping the repo"       "int:../etc/passwd"  "parent-segment-path"
id_reject "ID12 an absolute int: path"                "int:/abs/path"      "absolute-path"
id_reject "ID13 a drive-lettered int: path"           "int:C:/win"         "drive-letter-path"
id_reject "ID14 a backslash int: path"                'int:a\b'            "backslash-path"
id_reject "ID15 a kb: doc without a .md basename"     "kb:no-extension"    "bad-doc"
id_reject "ID16 an ext: key carrying whitespace"      "ext:has space"      "bad-external-key"
id_reject "ID17 an id with no prefix at all"          "nocolon"            "no-prefix"
id_reject "ID18 an unknown prefix"                    "zz:something"       "unknown-prefix"

echo ""
echo "=== ID-KP: the two-tier kind/prefix check, branching case included ==="

kp_ok() { if rel_kind_prefix_ok "$2" "$3"; then pass "$1"; else fail "$1 — rejected: $REL_KIND_REASON"; fi; }
kp_no() {
    if rel_kind_prefix_ok "$2" "$3"; then fail "$1 — ACCEPTED $2 + $3"
    else assert_output_contains "$REL_KIND_REASON" "$4" "$1"; fi
}
# The positive half of the branching case is the one that matters: without it, an
# implementation rejecting every external image passes a suite of rejections.
kp_ok "ID-KP01 image + int: passes"                     image           "int:docs/x.png"
kp_ok "ID-KP02 image + ext: MUST PASS (the branch)"     image           "ext:remote-logo"
kp_ok "ID-KP03 source-artifact + int: file"             source-artifact "int:tool.sh"
kp_ok "ID-KP04 source-artifact + int: directory"        source-artifact "int:canonical/skills/aid-summarize/"
kp_ok "ID-KP05 web-page + ext:"                         web-page        "ext:wcag-22-aa"
kp_ok "ID-KP06 section + a kb: '#' fragment"            section         "kb:a.md#overview"

kp_no "ID-KP07 image + kb: (tier 1, prefix set)"        image   "kb:a.md"     "permits prefix(es) 'int ext', not 'kb'"
kp_no "ID-KP08 document + ext: (tier 1)"                document "ext:k"      "permits prefix(es) 'kb', not 'ext'"
kp_no "ID-KP09 a Kind outside the enum entirely"        gadget  "ext:k"       "is not in the Kind enum"
kp_no "ID-KP10 a kb: id whose grammar implies another kind" document "kb:a.md#overview" "implies kind 'section'"
kp_no "ID-KP11 an int: image extension typed source-artifact" source-artifact "int:img/logo.png" "is 'image', not 'source-artifact'"
kp_no "ID-KP12 an int: non-image extension typed image" image  "int:tool.sh"  "is 'source-artifact', not 'image'"
kp_no "ID-KP13 an int: DIRECTORY typed image"           image  "int:some/dir/" "is 'source-artifact', not 'image'"

# ===========================================================================
# === KB: the one-pass KB scan ==============================================
# ===========================================================================
echo ""
echo "=== KB: one scan feeds every derived set, so none can disagree about a fence ==="

mkdir -p "$TMP/kb" "$TMP/kb-nested" "$TMP/repo/img"
cat > "$TMP/kb/alpha.md" <<'EOF'
# Alpha

## Overview

Some prose citing `README.md` (search: "A full-lifecycle methodology") as its evidence.

An anchor-less citation of `docs/notes.md`, with nothing to grep for.

### Widget

**Definition:** A widget is a thing that does a thing.

```bash
# a heading-shaped line inside a fence must NOT close a block
**Definition:** and a marker inside a fence must NOT qualify one
`fenced.md` (search: "must not become a fact")
```

## Overview

A second heading with the same text, so its slug takes the ordinal.
EOF
printf '# Beta\n\n## Notes\n\nBeta refers to alpha.\n' > "$TMP/kb/beta.md"
cat > "$TMP/kb/external-sources.md" <<'EOF'
# External Sources

## Sources

| Key | Origin | Contributed to |
|-----|--------|----------------|
| `wcag-22-aa` | https://example.invalid/wcag | alpha.md |
EOF
printf '#!/usr/bin/env bash\necho tool\n' > "$TMP/repo/tool.sh"
printf 'not-really-a-png\n' > "$TMP/repo/img/logo.png"

rel_set_kb_root "$TMP/kb"
rel_set_repo_root "$TMP/repo"
rel_set_external_sources "$TMP/kb/external-sources.md"
rel_scan_kb

assert_eq "$(rel_kb_docs | tr '\n' ' ')" "alpha.md beta.md external-sources.md " \
    "KB01 the scan set is the flat *.md membership predicate, LC_ALL=C ordered"
assert_eq "$(rel_doc_slugs alpha.md | tr '\n' ' ')" "overview widget overview-1 " \
    "KB02 slugs come out in document order, and a duplicate takes the '-<N-1>' ordinal"
assert_eq "$(rel_fact_tokens alpha.md | tr '\n' ' ')" "readme-md--a-full-lifecycle-methodology " \
    "KB03 only the ANCHORED citation becomes a fact token"
assert_eq "$(rel_concept_terms | tr '\n' ' ')" "widget " \
    "KB04 one definition marker under a level-3 heading yields one concept term"
assert_eq "$(rel_external_keys | tr '\n' ' ')" "wcag-22-aa " \
    "KB05 the external registry predicate reads a backticked first cell under '## Sources'"

# Fenced code is excluded in BOTH directions, and both matter. A heading-shaped
# line inside a fence must not close a block; a marker inside one must not qualify
# a heading. Real KB documents quote shell freely, so the first direction fires
# constantly; the second has no instance on real content, which is exactly why it
# needs a fixture.
assert_output_not_contains "$(rel_fact_tokens alpha.md)" "fenced" \
    "KB06 a citation inside a fence yields NO fact token"
assert_eq "$(rel_concept_terms | grep -c . )" "1" \
    "KB07 a definition marker inside a fence qualifies NOTHING"
# `### Widget` sits at line 9 and the next heading of ANY level is `## Overview` at
# 19, so the body is 10..18 -- it SPANS the fenced block at 13..17. A rule that let
# the fenced `#`-shaped line at 14 close the block would report 10-13 instead.
widget_body="$(rel_block_bodies alpha.md | awk -F'\t' '$5=="Widget"{print $3"-"$4}')"
assert_eq "$widget_body" "10-18" \
    "KB08 a block body spans the fence rather than being cut short at a fenced heading"

# The unanchored record: without it the coverage notes' fact-unanchored row has no
# producer, and an anchor-less citation would be dropped silently.
assert_output_contains "$(rel_fact_records alpha.md)" "unanchored" \
    "KB09 an anchor-less citation is RECORDED as unanchored"
assert_output_contains "$(rel_fact_records alpha.md)" "anchored" \
    "KB10 a well-formed anchor is recorded as anchored, with its token and path"
assert_eq "$(rel_fact_records alpha.md | grep -c .)" "2" \
    "KB11 exactly the two out-of-fence citations are recorded"

# The fence mask is the seam that keeps a caller from writing a second fence scan.
mask="$(rel_fence_mask alpha.md | tr -d '\n')"
assert_eq "${mask:11:7}" "0111110" \
    "KB12 the fence mask marks the delimiters and their contents as inside"
assert_eq "$(rel_fence_mask alpha.md | grep -c .)" "$(grep -c '' "$TMP/kb/alpha.md")" \
    "KB13 the mask carries exactly one line per physical line of the document"
rc=0; rel_fence_mask no-such-doc.md >/dev/null 2>"$ERR" || rc=$?
assert_exit_nonzero "$rc" "KB14 the fence mask refuses a document outside the scan root"

# Resolution, by the protocol for each kind.
res() { assert_eq "$(rel_resolve_id "$2" "$3" 2>/dev/null)" "$4" "$1"; }
res "KB15 a document resolves through the scan set"      document        "kb:alpha.md" ok
res "KB16 a section resolves through the recomputed slug" section        "kb:alpha.md#overview-1" ok
res "KB17 a fact resolves through the recomputed token"   fact           "kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology" ok
res "KB18 a concept resolves through its one definition"  concept        "kb:concept:widget" ok
res "KB19 an in-repo artifact resolves from the repo root" source-artifact "int:tool.sh" ok
res "KB20 an in-repo image resolves from the repo root"   image          "int:img/logo.png" ok
res "KB21 an external key resolves through the registry"  web-page       "ext:wcag-22-aa" ok
res "KB22 an unknown document does not resolve"           document       "kb:absent.md" no-such-document
res "KB23 an unknown slug does not resolve"               section        "kb:alpha.md#nope" no-such-section
res "KB24 an unrecomputable fact token does not resolve"  fact           "kb:alpha.md#fact:nope" no-such-fact-anchor
res "KB25 an undefined concept does not resolve"          concept        "kb:concept:nope" no-such-concept-definition
res "KB26 a missing path does not resolve"                source-artifact "int:absent.sh" no-such-file
res "KB27 an unregistered key does not resolve"           web-page       "ext:nope" unregistered-external-key

# Display names are DERIVED, which is what keeps the identity check checkable in
# both directions and removes a churn source from byte-identity.
dn() { assert_eq "$(rel_display_name "$2" "$3" 2>/dev/null)" "$4" "$1"; }
dn "KB28 a document name is its basename"          document        "kb:alpha.md" "alpha.md"
dn "KB29 a section name is '<doc> § <heading>'"    section         "kb:alpha.md#overview" "alpha.md § Overview"
dn "KB30 a fact name is '<doc> § <anchor>'"        fact            "kb:alpha.md#fact:readme-md--a-full-lifecycle-methodology" "alpha.md § A full-lifecycle methodology"
dn "KB31 a concept name is the heading verbatim"   concept         "kb:concept:widget" "Widget"
dn "KB32 an artifact name is its path verbatim"    source-artifact "int:tool.sh" "tool.sh"
dn "KB33 an external name is its key"              web-page        "ext:wcag-22-aa" "wcag-22-aa"

# The nested-heading case a real Knowledge Base cannot supply. Under the rejected
# "next heading of the same or higher level" reading, blocks nest and ONE marker
# mints a concept for its heading AND for every ancestor at level >= 3 -- silently,
# because the ancestors carry different text so no duplicate report fires. This
# fixture is the only thing that discriminates the two readings.
cat > "$TMP/kb-nested/nested.md" <<'EOF'
# Nested

## Container

### Outer Term

Prose under the level-3 heading, carrying no marker.

#### Inner Term

**Definition:** the marker sits under the level-4 heading only.

##### Deeper Still

Prose with no marker.

## After
EOF
rel_set_kb_root "$TMP/kb-nested"
rel_scan_kb
assert_eq "$(rel_concept_terms | tr '\n' ' ')" "inner-term " \
    "KB34 a marker under a nested heading yields exactly ONE concept, not one per ancestor"
assert_eq "$(rel_concept_defs outer-term | grep -c .)" "0" \
    "KB35 the level-3 ancestor of a marked child is NOT itself a concept"
assert_eq "$(rel_concept_defs inner-term | tr '\n' ' ')" "nested.md " \
    "KB36 the marked level-4 heading is the concept, and resolves to its document"
assert_eq "$(rel_doc_slugs nested.md | tr '\n' ' ')" "container outer-term inner-term deeper-still after " \
    "KB37 section nodes cover heading levels 2-6 and exclude the H1"
assert_output_contains "$(rel_block_bodies nested.md)" "$(printf '4\t1\t')" \
    "KB38 the marked heading is reported at level 4 with its marker flag set"

# A term with two definitions must resolve to NEITHER plain form -- which is what
# forces the document-qualified id mechanically rather than by instruction.
cat > "$TMP/kb-nested/twice.md" <<'EOF'
# Twice

### Inner Term

**Definition:** a second, different definition of a term already defined.
EOF
rel_scan_kb
assert_eq "$(rel_resolve_id concept "kb:concept:inner-term" 2>/dev/null)" "ambiguous-concept-definition" \
    "KB39 a term with two definitions makes the PLAIN concept form unresolvable"
assert_eq "$(rel_resolve_id concept "kb:concept:inner-term@twice.md" 2>/dev/null)" "ok" \
    "KB40 the document-qualified form resolves against one document alone"

# ===========================================================================
# === RN: normalisation, keys, ordering, and the extractions ================
# ===========================================================================
echo ""
echo "=== RN: the stored orientation, the duplicate key, and the sort tuple ==="

# The TRIPLE swaps, not the pair. A rule that moved ids and names while leaving the
# two Kind cells in place would produce a row whose kinds no longer match their ids
# -- and any implementation carried over from an eight-column design has that bug.
norm="$(rel_normalise_row "int:tool.sh" "source-artifact" "tool.sh" \
        "int:img/logo.png" "image" "img/logo.png" "r-fwd" "r-back" "declared" "" | tr '\n' '/')"
assert_eq "$norm" "int:img/logo.png/image/img/logo.png/int:tool.sh/source-artifact/tool.sh/r-back/r-fwd/declared//" \
    "RN01 the swap moves both (Id, Kind, Name) TRIPLES and both relation labels together"
norm="$(rel_normalise_row "kb:a.md" "document" "a.md" "kb:b.md" "document" "b.md" "r-fwd" "r-back" "declared" "" | tr '\n' '/')"
assert_eq "$norm" "kb:a.md/document/a.md/kb:b.md/document/b.md/r-fwd/r-back/declared//" \
    "RN02 an already-canonical row is left exactly as written"
norm="$(rel_normalise_row "kb:a.md" "document" "a.md" "kb:a.md" "document" "a.md" "r-sym" "r-sym" "declared" "" | tr '\n' '/')"
assert_eq "$norm" "kb:a.md/document/a.md/kb:a.md/document/a.md/r-sym/r-sym/declared//" \
    "RN03 a self-edge is left as written"

# A verbatim repeat and a separately written inverse row collapse to ONE key, which
# is what makes the duplicate check catch both halves of the criterion.
k_fwd="$(rel_row_key "int:tool.sh" "source-artifact" "tool.sh" "int:img/logo.png" "image" "img/logo.png" "r-fwd" "r-back" "declared" "")"
k_mir="$(rel_row_key "int:img/logo.png" "image" "img/logo.png" "int:tool.sh" "source-artifact" "tool.sh" "r-back" "r-fwd" "declared" "a different observation")"
assert_eq "$k_fwd" "$k_mir" \
    "RN04 a row and its mirror collapse to one row key (Observation is not in the key)"
k_other="$(rel_row_key "int:tool.sh" "source-artifact" "tool.sh" "int:img/logo.png" "image" "img/logo.png" "r-other" "r-other-back" "declared" "")"
if [[ "$k_fwd" == "$k_other" ]]; then
    fail "RN05 a DIFFERENT typed relation over the same endpoints is a different key — keys collided"
else
    pass "RN05 a different typed relation over the same endpoints is a DIFFERENT key (two relations between two nodes are two relationships)"
fi
# Kind is deliberately absent from the key: an id determines its kind, so adding it
# could only mask a duplicate.
k_wrongkind="$(rel_row_key "int:tool.sh" "image" "tool.sh" "int:img/logo.png" "image" "img/logo.png" "r-fwd" "r-back" "declared" "")"
assert_eq "$k_fwd" "$k_wrongkind" \
    "RN06 Kind is not part of the row key (including it could only mask a duplicate)"

assert_eq "$(rel_sort_key kb:a.md d a kb:b.md d b r1 r2 declared '' | cut -c1)" "0" \
    "RN07 a declared row sorts in class 0"
assert_eq "$(rel_sort_key kb:a.md d a kb:b.md d b r1 r2 derived '' | cut -c1)" "0" \
    "RN08 a derived row sorts in class 0 as well (the deterministic class)"
assert_eq "$(rel_sort_key kb:a.md d a kb:b.md d b r1 r2 inferred '' | cut -c1)" "1" \
    "RN09 an inferred row sorts in class 1, which is what makes class 0 a contiguous prefix"

rc=0; rel_normalise_row a b c >/dev/null 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 2 "RN10 a row with the wrong field count is a usage error, not a silent partial"

echo ""
echo "=== RN-C0: the class-0 extraction, and the coverage-note key accessors ==="

cat > "$TMP/table.md" <<'EOF'
---
kb-category: primary
source: generated
---
<!-- AUTO-GENERATED -->

# Relationships

| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|---|---|
| kb:a.md | document | a.md | kb:b.md | document | b.md | r-one | r-one-back | declared | |
| kb:a.md | document | a.md | kb:c.md | document | c.md | r-one | r-one-back | derived | |
| kb:b.md | document | b.md | kb:c.md | document | c.md | r-two | r-two-back | inferred | free prose here |

## Coverage notes

### Node kinds

| Kind | Carrier convention | Status | Nodes |
|------|--------------------|--------|-------|
| document | KB documents | present | 3 |
| concept | markers | absent | 0 |
| fact | anchors | absent | 0 |
| section | headings | present | 4 |
| source-artifact | source | present | 1 |
| image | images | absent | 0 |
| web-page | registry | absent | 0 |
| concept-qualified | qualified ids | present | 0 |
| fact-unanchored | skipped markers | present | 1 |

### Enumeration exclusions

| Exclusion | Applied | Note |
|-----------|---------|------|
| generated/derived trees | yes | unconditional |
| vendored third-party code | yes | unconditional |
| `.aid/settings.yml` ignore list | no | setting absent |
EOF

c0="$(rel_class0_block "$TMP/table.md")"
assert_eq "$(printf '%s\n' "$c0" | grep -c '^|')" "4" \
    "RN-C001 the extraction is the header, the delimiter and the two class-0 rows"
assert_output_contains "$c0" "| Source Id | Source Kind |" \
    "RN-C002 the header row is INCLUDED, so a column rename fails the comparison"
assert_output_contains "$c0" "|---|---|---|---|---|---|---|---|---|---|" \
    "RN-C003 the delimiter row is included"
assert_output_not_contains "$c0" "inferred" \
    "RN-C004 the block stops before the first inferred row"
assert_output_not_contains "$c0" "kb-category" \
    "RN-C005 frontmatter is excluded, being outside the byte-identity boundary"

mutate "RN-C006" "$TMP/table.md" "$TMP/table-all0.md" \
    '| kb:b.md | document | b.md | kb:c.md | document | c.md | r-two | r-two-back | inferred | free prose here |' \
    '| kb:b.md | document | b.md | kb:c.md | document | c.md | r-two | r-two-back | derived | |' \
    && assert_eq "$(rel_class0_block "$TMP/table-all0.md" | grep -c '^|')" "5" \
        "RN-C006 with no inferred row the block is EVERY data row"

rc=0; rel_class0_block "$TMP/no-such-table.md" >/dev/null 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 2 "RN-C007 the extraction refuses an absent file"

assert_eq "$(rel_coverage_fixed_keys kinds | tr '\n' ' ')" \
    "document concept fact section source-artifact image web-page " \
    "RN-C008 the kinds table's fixed keys ARE the Kind enum, read from the carrier"
assert_eq "$(rel_coverage_fixed_keys exclusions | grep -c .)" "3" \
    "RN-C009 the exclusions table carries three fixed rows"
rc=0; rel_coverage_fixed_keys bogus >/dev/null 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 2 "RN-C010 an unknown table name is a usage error"

assert_eq "$(rel_coverage_extra_keys "$TMP/table.md" kinds | tr '\n' ' ')" \
    "concept-qualified fact-unanchored " \
    "RN-C011 the extra-row keys exclude the fixed block"
assert_eq "$(rel_coverage_extra_keys "$TMP/table.md" exclusions | grep -c .)" "0" \
    "RN-C012 a table with no extra rows yields none"

# The accessor returns FILE order, never a sorted view. That is the whole point:
# the ordering check recomputes the sort and compares, so an accessor that sorted
# would make the check compare a value against itself and pass on any input.
mutate "RN-C013" "$TMP/table.md" "$TMP/table-shuf.md" \
    '| concept-qualified | qualified ids | present | 0 |
| fact-unanchored | skipped markers | present | 1 |' \
    '| fact-unanchored | skipped markers | present | 1 |
| concept-qualified | qualified ids | present | 0 |' \
    && assert_eq "$(rel_coverage_extra_keys "$TMP/table-shuf.md" kinds | tr '\n' ' ')" \
        "fact-unanchored concept-qualified " \
        "RN-C013 the accessor reports FILE order, not a sorted view (so the order check can fail)"

# ===========================================================================
# === XC: the sibling carriers agree with this loader's view ================
# ===========================================================================
echo ""
echo "=== XC: the sibling graph carriers cross-check clean through this loader ==="

rel_load_schema "$SCHEMA" >/dev/null 2>&1
rel_load_vocabulary "$VOCAB_CORE" >/dev/null 2>&1

COVERAGE_BEARING="${REPO_ROOT}/canonical/aid/templates/graph/coverage-bearing.yml"
EDGE_MAP="${REPO_ROOT}/canonical/aid/templates/graph/edge-relation-map.yml"

if [[ -f "$COVERAGE_BEARING" ]]; then
    bad=""
    n=0
    while IFS= read -r r; do
        [[ -n "$r" ]] || continue
        n=$((n + 1))
        rel_is_relation "$r" || bad="${bad} ${r}"
    done < <(awk '/^coverage_bearing:/{f=1} f&&/^  - /{t=$0; sub(/^  - /,"",t); print t}' "$COVERAGE_BEARING")
    if [[ $n -eq 0 ]]; then
        fail "XC01 coverage-bearing relations are members — FIXTURE BUG: the scan found no names to check"
    else
        assert_eq "$bad" "" "XC01 every coverage-bearing relation is a member of the merged vocabulary"
    fi
else
    log "XC01 skipped: coverage-bearing.yml absent"
fi

if [[ -f "$EDGE_MAP" ]]; then
    bad_lbl=""; bad_pass=""; bad_ep=""; n=0
    while IFS= read -r row; do
        [[ -n "$row" ]] || continue
        n=$((n + 1))
        IFS='|' read -r mid mpasses meps mlabel <<<"$row"
        if ! rel_is_relation "$mlabel"; then bad_lbl="${bad_lbl} ${mid}:${mlabel}"; continue; fi
        rel_passes_into "$mlabel" && dp="$REL_LOOKUP" || dp=""
        for p in ${mpasses//,/ }; do
            rel__has_word "$dp" "$p" || bad_pass="${bad_pass} ${mid}:${p}"
        done
        rel_endpoint_kinds_into "$mlabel" && de="$REL_LOOKUP" || de=""
        for e in ${meps//,/ }; do
            rel__has_word "$de" "$e" || bad_ep="${bad_ep} ${mid}:${e}"
        done
    done < <(awk '/^map:/{f=1} f&&/^  - /{t=$0; sub(/^  - /,"",t); print t}' "$EDGE_MAP")
    if [[ $n -eq 0 ]]; then
        fail "XC02 edge-map rows cross-check — FIXTURE BUG: the scan found no rows to check"
    else
        assert_eq "$bad_lbl" "" "XC02 every edge-map relation label is a member of the merged vocabulary"
        assert_eq "$bad_pass" "" "XC03 every edge-map pass is legal for the relation it maps to"
        assert_eq "$bad_ep" "" "XC04 every edge-map endpoint token is declared by the relation it maps to"
    fi
else
    log "XC02 skipped: edge-relation-map.yml absent"
fi

# ===========================================================================
# === LIB: the library's own posture ========================================
# ===========================================================================
echo ""
echo "=== LIB: sourcing is side-effect free, and --help does not lie ==="

# The direct-execution guard must not misfire. `bash -c '. "$0"' <lib> <args>` sets
# $0 to the library, which the familiar single-test idiom reads as "executed
# directly" -- it would then apply `set -eu` to the SOURCING shell and exit 2 on the
# caller's first argument.
rc=0
env LIBP="$LIB" SCHP="$SCHEMA" bash -c '. "$LIBP"; rel_load_schema "$SCHP" >/dev/null' >/dev/null 2>"$ERR" || rc=$?
assert_exit_eq "$rc" 0 "LIB01 sourcing with \$0 set to the library is a SOURCE, not a direct execution"

help_out="$(bash "$LIB" --help 2>&1)"
assert_output_contains "$help_out" "Provides:" "LIB02 --help prints the header index"

# --help must stop at the LAST comment line and print no shell. Asserted by
# comparing its last line against the header's own last line rather than by hunting
# for a code-looking string: the header legitimately DISCUSSES `set -eu`, so a
# substring probe for that would fail on correct output. This form cannot: it is
# recomputed from the file, so it stays true as the header grows.
last_hdr="$(awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$LIB" | tail -1)"
assert_eq "$(printf '%s\n' "$help_out" | tail -1)" "$last_hdr" \
    "LIB03 --help ends exactly at the header's last comment line (a fixed line range lies as the header grows)"
if printf '%s\n' "$help_out" | grep -qE '^(REL_[A-Z_]+=|set -u|#!/)'; then
    fail "LIB03b --help leaks shell source — a code-shaped line reached the help output"
else
    pass "LIB03b --help leaks no shell source (no assignment, strict-mode or shebang line)"
fi
rc=0; bash "$LIB" --bogus >/dev/null 2>&1 || rc=$?
assert_exit_eq "$rc" 2 "LIB04 an unknown argument on direct execution is a usage error"

# Every flag the validator documents must be honoured; the library must not smuggle
# vocabulary CONTENT into the shipped tree.
assert_file_not_contains "$LIB" "skos:" "LIB05 no standards token is hardcoded in the library"
assert_file_not_contains "$LIB" "cites-as-evidence" "LIB06 no shipped relation label is hardcoded in the library"

# ===========================================================================
# === WT: the working tree is untouched by every mutation above (S5) ========
# ===========================================================================
echo ""
echo "=== WT: every mutation above operated on a mktemp COPY, never these files ==="

if cmp -s "$LIB" "$TMP/.snapshot-lib.sh" \
    && cmp -s "$SCHEMA" "$TMP/.snapshot-schema.yml" \
    && cmp -s "$VOCAB_CORE" "$TMP/.snapshot-vocab.yml"; then
    pass "WT01 the library, the schema carrier and the core vocabulary are byte-identical to their PRE snapshot"
else
    fail "WT01 a real subject file changed during this run -- a mutation escaped its mktemp copy"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
test_summary
exit $?
