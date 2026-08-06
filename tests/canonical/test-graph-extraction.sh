#!/usr/bin/env bash
# test-graph-extraction.sh -- the two-pass relationship EXTRACTION pipeline.
#
# Scope:
#   The four scripts of work-005 feature-005, and nothing else:
#     canonical/aid/scripts/graph/report-endpoint-satisfiability.sh  (D3 map loader + D8 W3 report)
#     canonical/aid/scripts/graph/harvest-declared.sh                (Pass 1a)
#     canonical/aid/scripts/graph/derive-edges.sh                    (Pass 1b)
#     canonical/aid/scripts/graph/build-relationships.sh             (steps 11-16)
#
#   feature-003's relationship-schema.sh and validate-relationships.sh are
#   CONSUMED here, never asserted: test-graph-schema-loader.sh and
#   test-graph-relationship-validator.sh own those.
#
# S1 -- SUBJECT INVOCATION BUDGET: 18 subprocess spawns (10 pipeline + 8
#   parse-only) + 2 in-process library sources (LIB, REPORT). `--self-mutate`
#   adds 4 more build spawns (MUT02-05); MUT01 mutates REPORT and re-sources it
#   in a subshell, so it costs nothing extra. The pipeline and parse-only counts
#   are enumerated rule by rule in the COST MODEL immediately below -- this line
#   exists so a future author cannot add an eleventh spawn casually, the way the
#   four sibling graph suites already declare their own budget in this shape.
#
# ---------------------------------------------------------------------------
# COST MODEL -- read this before adding an assertion
# ---------------------------------------------------------------------------
#   Runtime here is proportional to PROCESS SPAWN COUNT and to nothing else.
#   Measured on the Git Bash / MSYS host this work is authored on:
#
#       300 command substitutions ... 25 s      (83 ms each)
#       100 awk forks .............. 16 s      (160 ms each)
#       300 plain function calls .... 0 s
#       300 parameter expansions .... 0 s
#
#   Sourcing feature-003's library and loading the 1,010-line vocabulary costs a
#   further ~29 s PER SUBJECT PROCESS, before a single assertion is evaluated.
#
#   So this suite obeys two rules, and every future edit must too:
#
#   1. EACH SUBJECT IS INVOKED ONCE PER DISTINCT INPUT, never once per assertion
#      group. TEN pipeline subject invocations, and each one is here because the
#      contract cannot be checked without it:
#
#        harvest-declared.sh   x2  |  derive-edges.sh x2  |  build-relationships.sh x2
#              AC-5 / FR-32 is "two runs over identical inputs produce identical
#              bytes". That is a property OF A SECOND RUN; it cannot be inferred
#              from one. All three stages repeat, because the hash-order hazard
#              BSH03 guards against lives in Pass 1a, not only in the renderer.
#        build-relationships.sh x1 (read ledger removed)
#              the D6-part-4 DEGRADATION outcome: exit 0 with a notice.
#        build-relationships.sh x1 (dispositions removed)
#              the D6-part-4 SHORTFALL outcome: exit 1, every item named, artifact
#              still written. Distinct input AND the opposite exit code, so it
#              cannot share a run with the one above.
#        build-relationships.sh x1 (one read-ledger entry duplicated)
#              FR-31a part 1's at-most-once bound, made mechanical by D6 part 4's
#              `count = 1` check: a document dispatched TWICE must fail the same
#              way an absent one would, and neither of the two runs above touches
#              this branch (one removes the whole ledger, the other leaves it
#              alone) -- so dropping this run would leave the "twice" half of
#              "at most once" unchecked.
#        harvest-declared.sh x1, against a SEPARATE all-absent fixture KB
#              AC-19's own claim -- a project supplying no instance of a carrier
#              convention still exits successfully with zero nodes of the
#              affected kind -- is a property of a KB that has NONE of that
#              convention anywhere. The main fixture corpus cannot exercise it:
#              every kind is deliberately present and non-zero there (that is
#              what the REST of this suite needs). `derive-edges.sh` and
#              `build-relationships.sh` are not re-invoked for this input because
#              the claim is decided entirely by `kb-stats.tsv`, which
#              `harvest-declared.sh` alone writes.
#
#      Plus eight parse-only invocations (four `--help`, four unknown-flag), which
#      return before the library load and cost ~0.1 s each.
#
#      `--self-mutate` adds FOUR more build invocations. It is off by default so
#      CI pays for one pass.
#
#   2. EVERY OUTPUT IS READ INTO MEMORY ONCE, AND EVERY ASSERTION IS A BUILTIN.
#      `mapfile` / one `while IFS=$'\t' read -r` pass per file, into indexed and
#      associative arrays; then `[[ ]]`, `case`, and parameter expansion. There is
#      no per-assertion grep, awk, cut, wc or command substitution anywhere below.
#      The library's fork-free accessors (`rel_endpoint_kinds_into` and
#      `rel_passes_into`, which set `REL_LOOKUP`) are used in place of the printing
#      forms, and the printing accessors that have no `_into` twin are called ONCE
#      each in a setup pass and cached -- which still exercises the published
#      accessor, at 76 calls instead of ~400.
#
# What is asserted, and why each group exists:
#   PRE  the four scripts, the library and the three carriers are present, and the
#        library exposes the two accessors Pass 1a's documented seam names.
#   MAP  the D3 edge-relation map loader: the accepting case and each of its four
#        fail-closed gates in isolation -- arity, completeness, pass legality,
#        endpoint legality (AC-S5).
#   W3   the D8 producer-satisfiability report: one mark per declared token for
#        every entry of the merged vocabulary, the closed three-value mark enum,
#        D8's `illustrated-by` worked example, and its `quotes` counter-example.
#   ORI  ORIENTATION SAFETY -- the group this suite exists for. feature-003 D7
#        stores rows normalised, swapping the two (Id, Kind, Name) TRIPLES and the
#        two relation labels together, so anything accumulating over the stored
#        `S2T` alone credits the inverse entry on roughly half of every asymmetric
#        pair. Three independent guarantees: W3's marks come from the MAP, so no
#        stored orientation can reach them; two genuinely flipped rows keep their
#        Kind cells matched to their own ids; and D2f reads BOTH readings of every
#        frozen row. MUT01 and MUT02 prove none of it is vacuous.
#   P1A  Pass 1a: the four KB node kinds, D2a's two source exclusions (excluded as
#        sources, still valid targets), the duplicate-slug ordinal, D2b's LEVEL
#        STACK containment, fenced-code inertness in both directions, AC-S2's
#        one-node-per-term merge, D2d case 1's qualified split, both sides of D2e's
#        data-driven ceiling, AC-19's featureless DOCUMENT, AC-19's KB-WIDE absent
#        convention (a separate fixture, since the main corpus keeps every kind
#        present on purpose), AC-S8's statement-keyed provenance, AC-4's provenance
#        enum (universal, over every row Pass 1a emits) and AC-16's `int:` id
#        hygiene (no `#` fragment; every id named is one feature-004 supplied).
#   P1B  Pass 1b: each observation kind typed through the map, `path-reference`
#        deliberately unmapped, both branches of feature-001 D6c's
#        resolution-keyed provenance, and the same AC-4 / AC-16 universals P1A
#        carries, re-run over Pass 1b's own rows.
#   MRG  step 11's merge -- the total de-duplication rule, D7's order and class 0 as
#        a contiguous prefix, AC-4's provenance enum re-checked on the MERGED
#        output (ORI06a) -- and each of D6's four class-1 rejections. Rejection
#        2 is included because a first implementation satisfied it vacuously; MUT03
#        is what proves this one is not the same check again.
#   CMP  the completion check: both arms of the disposition union, the degradation
#        outcome, the undispositioned-candidate shortfall, and the duplicate-read
#        shortfall (FR-31a part 1's at-most-once bound, made mechanical).
#   DET  byte identity of the whole artifact across two full pipeline runs, by md5.
#   IDEM `br_reject` appends no duplicate disposition row on a re-run.
#   D2F  the false-merge detector: the firing case, three near-misses that must NOT
#        fire, the degenerate exclusion, and AC-S7a's counter arithmetic.
#   REN  the rendered artifact: D1's byte grammar, D8's frontmatter, and D7a/D7a-1's
#        coverage section including the extra-row order ACROSS two producer files,
#        the coverage-notes HAND-OFF from feature-010's assemble-coverage-notes.sh
#        (byte-identity, the three loud-failure branches) and, task-009, the fixed
#        Kind rows' NODES COUNT against each producer's own numbers -- proof that a
#        well-formed but STALE or SWAPPED hand-off is caught, not merely an absent
#        or truncated one (MUT05).
#   V11  a routed cross-feature defect, skipped loudly rather than encoded.
#   BSH  four bash traps this pipeline shipped and had to fix, as REGRESSION scans
#        over all four scripts -- one awk per file computing all four counts -- each
#        paired with a synthetic demonstration that the hazard it guards against is
#        real on this bash, so no scan guards a rule that cannot be broken and no
#        assertion is a tautology.
#   HLP  every documented flag is parsed, every parsed flag's variable is READ, and
#        an unknown flag is a usage error.
#   MUT  `--self-mutate` only. Five mutants, each against a COPY in a mktemp dir.
#        The shipped tree is never written to, and its digest (or, for MUT05's
#        assembler mutant, its own cached text) is re-verified after every mutant.
#        Every mutant must first prove it RAN: the first version of
#        that section forgot to stage the sibling each entry point sources, so every
#        mutant died on its first statement and one assertion passed anyway -- the
#        "silence" it measured was the silence of a dead process.
#
# Fixtures:
#   Self-built under a mktemp dir, removed on EXIT. Nothing here reads or names
#   `.aid/works/` -- work folders are transient and this suite must outlive them.
#   The main KB fixture carries a level-4 nested under a level-3, two duplicate
#   headings, a fenced heading-shaped line, a fenced citation marker, an
#   anchor-less marker, a term defined twice, a markdown image reference, a
#   featureless document, a generated INDEX.md, a previous relationships.md, and a
#   four-document set exercising every arm of D2f's predicate -- none of which this
#   repository's own Knowledge Base can supply. A SECOND, separate one-document KB
#   -- no heading below H1, no citation marker, no definition marker -- exists only
#   for AC-19's KB-wide absent-convention claim, which the main corpus cannot make
#   (every kind is deliberately present there).
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
#
#   Each line is a reviewable claim, and the list is deliberately short. What is
#   ABSENT is as considered as what is present:
#     validate-relationships.sh -- every build invocation below passes
#       --skip-validate, so step 16 never executes here and a validator change
#       cannot alter one assertion. test-graph-relationship-validator.sh owns it.
#     scan-source.sh / significance-rules.sh -- feature-004's four streams are
#       hand-built in this file, so no scanner runs. The four scripts name both in
#       PROSE only, which is why a grep for siblings over-reports them.
#
# COVERS: canonical/aid/scripts/graph/harvest-declared.sh
# COVERS: canonical/aid/scripts/graph/derive-edges.sh
# COVERS: canonical/aid/scripts/graph/build-relationships.sh
# COVERS: canonical/aid/scripts/graph/assemble-coverage-notes.sh
# COVERS: canonical/aid/scripts/graph/report-endpoint-satisfiability.sh
# COVERS: canonical/aid/scripts/graph/relationship-schema.sh
# COVERS: canonical/aid/templates/graph/
# COVERS: tests/lib/assert.sh
#
# Usage:
#   bash test-graph-extraction.sh [-v | --verbose]
#   bash test-graph-extraction.sh --self-mutate      # + the mutation matrix
#   bash test-graph-extraction.sh --group MRG,CMP    # only those groups
#
#   --group takes group prefixes from the list above and runs ONLY those, spawning
#   only the subject invocations they need: `--group BSH` spawns none, `--group MRG`
#   spawns one pass, `--group DET` two. It exists so a one-line fix is verified by
#   re-running the failing GROUP rather than the suite.
#
# Exit codes:
#   0 -- all assertions pass
#   1 -- one or more assertions failed
#   2 -- the environment cannot support the run (a missing subject or carrier)

set -u

VERBOSE=0
MODE="assert"
GROUP_FILTER=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)  VERBOSE=1; shift ;;
        --self-mutate) MODE="mutate"; shift ;;
        --group)       GROUP_FILTER="${2:?--group needs a comma-separated group list}"; shift 2 ;;
        *) echo "test-graph-extraction.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Group filtering (T6). `sec` names the group each assertion below belongs to, and
# a filtered-out group's assertions are silently skipped -- not counted, not
# printed. `pass` and `fail` are RENAMED rather than reimplemented: a second copy
# of assert.sh's counter bookkeeping would be a rule living in two places.
# ---------------------------------------------------------------------------
# The filter variable is NOT called GROUPS. `GROUPS` is a bash BUILT-IN array
# variable holding the invoking user's group list, and "assignments to GROUPS have
# no effect" -- silently. Naming it that made `$GROUP_FILTER` expand to a numeric gid,
# so `want` returned false for EVERY group and the suite reported
# "Tests passed: 0 ... All tests passed." A zero-assertion pass is the worst
# possible failure mode, which is why SELF01 below now makes it impossible.
CURRENT_GROUP="PRE"
sec()  { CURRENT_GROUP="$1"; }
want() {
    [[ -z "$GROUP_FILTER" ]] && return 0
    case ",${GROUP_FILTER}," in *",$1,"*) return 0 ;; esac
    return 1
}
eval "orig_$(declare -f pass)"
eval "orig_$(declare -f fail)"
pass() { want "$CURRENT_GROUP" && orig_pass "$@"; return 0; }
fail() { want "$CURRENT_GROUP" && orig_fail "$@"; return 0; }
orig_skip() { SKIPPED=$((SKIPPED + 1)); echo "  SKIP: $*"; }
skip() { want "$CURRENT_GROUP" && orig_skip "$@"; return 0; }

# Groups whose assertions read a pipeline output. If none is selected, not one
# subject is spawned.
NEED_PIPELINE=0
for _g in P1A P1B ORI MRG CMP DET IDEM D2F REN V11 MUT; do
    want "$_g" && NEED_PIPELINE=1
done

GRAPH="${REPO_ROOT}/canonical/aid/scripts/graph"
TPL="${REPO_ROOT}/canonical/aid/templates/graph"

REPORT="${GRAPH}/report-endpoint-satisfiability.sh"
HARVEST="${GRAPH}/harvest-declared.sh"
DERIVE="${GRAPH}/derive-edges.sh"
BUILD="${GRAPH}/build-relationships.sh"
LIB="${GRAPH}/relationship-schema.sh"
ASSEMBLER="${GRAPH}/assemble-coverage-notes.sh"

SCHEMA="${TPL}/relationship-schema.yml"
VOCAB="${TPL}/relation-vocabulary.yml"
EDGE_MAP="${TPL}/edge-relation-map.yml"

for required in "$REPORT" "$HARVEST" "$DERIVE" "$BUILD" "$LIB" "$SCHEMA" "$VOCAB" "$EDGE_MAP" "$ASSEMBLER"; do
    if [[ ! -f "$required" ]]; then
        echo "test-graph-extraction.sh: missing subject or carrier: $required" >&2
        exit 2
    fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The hand-off's OWN subject, cached ONCE. It deliberately sits OUTSIDE
# SUBJECT_ORDER below: BSH's regression scans and HLP's flag-hygiene loop are both
# keyed to the three `$GRAPH_LIB`-sourcing entry points plus the report script's
# one exec-guarded exception, and folding a fifth, differently-shaped script into
# that loop would either skip it silently or fail it for not matching a rule it
# was never subject to. MUT05 mutates a COPY of this file (never the original);
# this cached text is what proves the original is untouched afterwards, the way
# BASE_DIGEST does for the four SUBJECT_ORDER scripts.
ASSEMBLER_TEXT="$(<"$ASSEMBLER")"

TAB=$'\t'
US=$'\x1f'
NL=$'\n'
SKIPPED=0

# ===========================================================================
# Builtin-only assertion helpers
#
# Counting is never done with `grep -c`: a sibling suite wrote
# `grep -c pattern file || echo 0`, which on no-match emits `0` from grep AND `0`
# from the fallback -- two lines where the caller expected one, so every numeric
# comparison against it silently compared against the string "0\n0". Nothing below
# spawns anything, so that shape cannot recur here.
# ===========================================================================

assert_count_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label — expected $expected, got $actual"
    fi
}

# A universal ("every X has property P") is vacuously true over an empty set, so
# every universal below is preceded by a non-emptiness assertion on the same set.
# This helper makes that pairing impossible to forget.
assert_nonempty() {
    local count="$1" label="$2"
    if [[ "${count:-0}" -gt 0 ]]; then
        pass "$label"
    else
        fail "$label — the set is EMPTY, so any universal over it would pass vacuously"
    fi
}

assert_true() {
    if [[ "$1" == "1" ]]; then pass "$2"; else fail "$2 — the condition does not hold"; fi
}

assert_false() {
    if [[ "$1" == "1" ]]; then fail "$3"; else pass "$2"; fi
}

# A CELL-exact membership test, never a substring one.
#
# An id such as `kb:INDEX.md` occurs inside OTHER rows' Observation cells, so a
# whole-file substring search is true even when no row's Source Id cell is that id.
# Every probe below is a keyed lookup into a map built from ONE named column, so a
# value occurring inside another cell can never satisfy it.
assert_key() {
    local -n _m="$1"
    if [[ -n "${_m[$2]+set}" ]]; then pass "$3"; else fail "$3 — no row carries '$2' in that column"; fi
}

assert_no_key() {
    local -n _m="$1"
    if [[ -n "${_m[$2]+set}" ]]; then fail "$3 — a row carries '$2' in that column"; else pass "$3"; fi
}

# ---------------------------------------------------------------------------
# mutate <label> <src> <dst> <find> <replace>
#
# Literal, PATTERN-anchored mutation of a COPY. Never a line number, and never the
# shipped tree: a sibling suite mutated `canonical/` in place and a quota kill left
# `return 0` at the top of a live function, so every advisory in the shipped script
# was silently dead while its exit code stayed 0. The window between mutate and
# restore is a liability no result justifies, so there is no window here -- the
# mutant is a separate file and the original is only ever READ.
#
# Three guards, each FAILING the suite loudly rather than yielding a fixture that
# exercises nothing:
#   1. the anchor must be PRESENT in <src>;
#   2. the anchor must be UNIQUE in <src>;
#   3. the result must DIFFER from <src>.
# Guard 2 is the one earned the hard way: an anchor that also appeared in a comment
# edited the comment, left the code untouched, and passed guards 1 and 3 while
# testing nothing at all.
# ---------------------------------------------------------------------------
mutate() {
    local label="$1" src="$2" dst="$3" find="$4" repl="$5" body new rest occurrences
    body="$(<"$src")"
    case "$body" in
        *"$find"*) ;;
        *) fail "$label — FIXTURE BUG: anchor absent from ${src##*/}: '$find'"; return 1 ;;
    esac
    occurrences=0
    rest="$body"
    while [[ "$rest" == *"$find"* ]]; do
        occurrences=$((occurrences + 1))
        rest="${rest#*"$find"}"
        [[ $occurrences -gt 1 ]] && break
    done
    if [[ $occurrences -gt 1 ]]; then
        fail "$label — FIXTURE BUG: anchor is AMBIGUOUS in ${src##*/}: '$find'"
        return 1
    fi
    new="${body/"$find"/"$repl"}"
    if [[ "$new" == "$body" ]]; then
        fail "$label — FIXTURE BUG: the replacement left the file byte-identical"
        return 1
    fi
    printf '%s\n' "$new" > "$dst"
    return 0
}

# ===========================================================================
# PRE -- preconditions
# ===========================================================================
sec PRE

# The four subjects are read into memory ONCE. Every BSH scan, every CR check and
# every digest below works on these arrays, not on a re-read of the files.
declare -A SUBJECT_TEXT=()
SUBJECT_ORDER=("$REPORT" "$HARVEST" "$DERIVE" "$BUILD")
for f in "${SUBJECT_ORDER[@]}"; do
    SUBJECT_TEXT["$f"]="$(<"$f")"
done

for f in "${SUBJECT_ORDER[@]}"; do
    if bash -n "$f" 2>/dev/null; then
        pass "PRE01 ${f##*/} parses"
    else
        fail "PRE01 ${f##*/} — bash -n failed"
    fi
done

# LF only: .gitattributes pins *.sh to eol=lf, and a CRLF checkout breaks
# `#!/usr/bin/env bash` on a Linux adopter.
for f in "${SUBJECT_ORDER[@]}"; do
    if [[ "${SUBJECT_TEXT[$f]}" == *$'\r'* ]]; then
        fail "PRE02 ${f##*/} — carries CR bytes; *.sh is pinned eol=lf"
    else
        pass "PRE02 ${f##*/} is LF only"
    fi
done

BASE_DIGEST="$(cat "${SUBJECT_ORDER[@]}" | md5sum)"

# ---------------------------------------------------------------------------
# ONE in-process load, for every MAP, W3, ORI-map and MUT01 assertion below.
# The library must be sourced at TOP LEVEL -- see BSH02.
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
source "$LIB"
# shellcheck source=/dev/null
source "$REPORT"

# The two accessors Pass 1a's documented seam names. They sit beyond feature-003
# D9's published table, so their presence is asserted rather than assumed: without
# `rel_fence_mask` Pass 1a cannot share the library's single fenced-code state and
# AC-S1 is unachievable across the seam, and without `rel_fact_records` harvest
# kind 5 has no cited path to anchor on.
if declare -F rel_fence_mask >/dev/null; then
    pass "PRE03 the library exposes rel_fence_mask (Pass 1a's shared fence state, AC-S1)"
else
    fail "PRE03 the library does not expose rel_fence_mask — Pass 1a cannot share the fence state"
fi
if declare -F rel_fact_records >/dev/null; then
    pass "PRE04 the library exposes rel_fact_records (the cited path harvest kind 5 needs)"
else
    fail "PRE04 the library does not expose rel_fact_records — harvest kind 5 has no cited path"
fi

rc=0; rel_load_schema "$SCHEMA" >/dev/null 2>&1 || rc=$?
assert_exit_eq "$rc" 0 "PRE05 rel_load_schema accepts the shipped carrier"
rc=0; rel_load_vocabulary "$VOCAB" >/dev/null 2>&1 || rc=$?
assert_exit_eq "$rc" 0 "PRE06 rel_load_vocabulary accepts the shipped vocabulary"

# ---------------------------------------------------------------------------
# The setup pass: each printing accessor with no fork-free twin is called ONCE and
# cached. 19 kinds x 3 + 19 inverses = 76 calls, in place of the ~400 the naive
# per-assertion form spends. `rel_endpoint_kinds_into` and `rel_passes_into` set
# REL_LOOKUP and are called freely, because they cost nothing.
# ---------------------------------------------------------------------------
# MAP01 lives here rather than under the MAP banner because the map must load
# before any group can assert anything, and `sec` must name the group an assertion
# BELONGS to -- not the region it happens to sit in, or `--group MAP` would skip it.
sec MAP
rc=0; load_edge_relation_map "$EDGE_MAP" >/dev/null 2>&1 || rc=$?
assert_exit_eq "$rc" 0 "MAP01 the shipped edge-relation map loads"

read -r -a HARVEST_KINDS <<< "$(graph_harvest_kinds)"
read -r -a KIND_ENUM <<< "$(rel_kinds)"
read -r -a IMG_EXT <<< "$(rel_image_extensions)"
# `rel_vocab_relations` prints a newline-separated variable through `printf '%s\n'`,
# so the stream can end with a blank line. Every count below is compared against
# this array's LENGTH, so a stray empty element would silently shift W303 by one.
mapfile -t _vocab_raw < <(rel_vocab_relations)
VOCAB_RELATIONS=()
for r in "${_vocab_raw[@]}"; do [[ -n "$r" ]] && VOCAB_RELATIONS+=("$r"); done

declare -A K_RELATION=() K_PROVS=() K_PAIRS=() INVERSE=()
for k in "${HARVEST_KINDS[@]}"; do
    erm_is_mapped "$k" || continue
    K_RELATION["$k"]="$(erm_relation "$k")"
    K_PROVS["$k"]="$(erm_provenances "$k")"
    K_PAIRS["$k"]="$(erm_pairs "$k")"
    r="${K_RELATION[$k]}"
    [[ -n "${INVERSE[$r]+set}" ]] || INVERSE["$r"]="$(rel_inverse_of "$r")"
done

mention_rel="${K_RELATION[kb-concept-mention]:-}"
cites_rel="${K_RELATION[kb-inline-path-citation]:-}"
doclink_rel="${K_RELATION[kb-inline-doc-link]:-}"
documents_rel="${K_RELATION[frontmatter-sources-path]:-}"
ill_rel="${K_RELATION[image-reference]:-}"
cae_rel="${K_RELATION[kb-fact-anchor]:-}"
haspart_rel="${K_RELATION[kb-doc-section]:-}"

# ===========================================================================
# MAP -- the D3 edge-relation map loader and its four fail-closed gates (AC-S5)
# ===========================================================================
sec MAP

n_kinds="${#HARVEST_KINDS[@]}"
assert_nonempty "$n_kinds" "MAP02 the closed harvest-kind list is non-empty"
assert_count_eq "${#K_RELATION[@]}" "$(( n_kinds - 1 ))" \
    "MAP03 every declared harvest kind but one is mapped (the exception is a declaration, not a gap)"

# That one omission is DECLARED. A kind neither mapped nor declared unmapped fails
# the load (MAP11), which is what makes the omission auditable rather than silent.
if erm_is_unmapped "path-reference" && ! erm_is_mapped "path-reference"; then
    pass "MAP04 path-reference is declared unmapped and carries no entry (D3, by design)"
else
    fail "MAP04 path-reference is not both declared-unmapped and unmapped"
fi

# Universal: every mapped kind's relation is a merged-vocabulary member, every
# declared provenance is in that relation's `passes`, and every declared kind pair
# is in its `endpoint_kinds` -- compared after parsing, never textually.
bad_rel=0; bad_pass=0; bad_ep=0; checked=0
for k in "${!K_RELATION[@]}"; do
    r="${K_RELATION[$k]}"
    checked=$((checked + 1))
    rel_is_relation "$r" || bad_rel=$((bad_rel + 1))
    rel_passes_into "$r" || REL_LOOKUP=""
    passes="$REL_LOOKUP"
    for p in ${K_PROVS[$k]}; do
        erm_in_list "$p" "$passes" || bad_pass=$((bad_pass + 1))
    done
    rel_endpoint_kinds_into "$r" || REL_LOOKUP=""
    eps="$REL_LOOKUP"
    for t in ${K_PAIRS[$k]}; do
        erm_in_list "$t" "$eps" || bad_ep=$((bad_ep + 1))
    done
done
assert_nonempty "$checked"   "MAP05 the per-kind universals run over a non-empty set"
assert_count_eq "$bad_rel"  0 "MAP06 every mapped relation is a merged-vocabulary member"
assert_count_eq "$bad_pass" 0 "MAP07 every declared provenance is in its relation's passes (AC-S5)"
assert_count_eq "$bad_ep"   0 "MAP08 every declared kind pair is in its relation's endpoint_kinds (AC-S5)"

# The map's kind-pair field carries KIND names and never id prefixes -- the Q21
# proxy this work exists to prevent. A prefix token would carry a `:`.
prefix_proxy=0
for k in "${!K_PAIRS[@]}"; do
    for t in ${K_PAIRS[$k]}; do
        [[ "$t" == *:* ]] && prefix_proxy=1
    done
done
assert_false "$prefix_proxy" \
    "MAP09 no kind-pair field carries an id prefix (Q21: a prefix never stands in for a Kind)" \
    "MAP09 a kind-pair field carries a ':' — that is an id PREFIX standing in for a Kind (Q21)"

# The four gates, each in isolation, each against a MUTATED COPY of the carrier.
#
# `load_edge_relation_map` costs 15 s on this host, and this block calls it FIVE
# times plus a restore -- 90 s, the single most expensive thing outside the subject
# invocations. It is therefore gated: a run that did not ask for MAP does not pay
# for it. The gates also clobber the loaded ERM_* arrays, which is why the real map
# is reloaded at the end rather than left in whatever state the last gate produced.
if want MAP; then
MAPMUT="$TMP/map"; mkdir -p "$MAPMUT"

gate_rejects() {
    local label="$1" file="$2" grc=0
    load_edge_relation_map "$file" >/dev/null 2>&1 || grc=$?
    assert_exit_eq "$grc" 2 "$label"
}

if mutate "MAP10" "$EDGE_MAP" "$MAPMUT/arity.yml" \
    '  - invocation|derived|source-artifact->source-artifact|invokes' \
    '  - invocation|derived|source-artifact->source-artifact'; then
    gate_rejects "MAP10 an entry with three fields instead of four exits 2 (arity gate)" "$MAPMUT/arity.yml"
fi
if mutate "MAP11" "$EDGE_MAP" "$MAPMUT/complete.yml" \
    '  - invocation|derived|source-artifact->source-artifact|invokes' \
    '  - not-a-harvest-kind|derived|source-artifact->source-artifact|invokes'; then
    gate_rejects "MAP11 a kind outside the closed list exits 2 (completeness gate)" "$MAPMUT/complete.yml"
fi
if mutate "MAP12" "$EDGE_MAP" "$MAPMUT/pass.yml" \
    '  - kb-concept-definition|declared|document->concept|defines' \
    '  - kb-concept-definition|inferred|document->concept|defines'; then
    gate_rejects "MAP12 a provenance outside the relation's passes exits 2 (pass gate, AC-S5)" "$MAPMUT/pass.yml"
fi
# The endpoint-illegal fixture is a KIND pair of two real Kinds, so a loader still
# comparing id prefixes would accept it and this assertion would go red.
if mutate "MAP13" "$EDGE_MAP" "$MAPMUT/endpoint.yml" \
    '  - kb-concept-definition|declared|document->concept|defines' \
    '  - kb-concept-definition|declared|image->web-page|defines'; then
    gate_rejects "MAP13 a kind pair outside the relation's endpoint_kinds exits 2 (endpoint gate, AC-S5)" "$MAPMUT/endpoint.yml"
fi
rc=0; load_edge_relation_map "$MAPMUT/does-not-exist.yml" >/dev/null 2>&1 || rc=$?
assert_exit_eq "$rc" 2 "MAP14 an absent map exits 2 rather than loading an empty one"

# Restore the real map for every group below.
load_edge_relation_map "$EDGE_MAP" >/dev/null 2>&1
fi

# ===========================================================================
# W3 -- the D8 producer-satisfiability report (in process, then one pass)
# ===========================================================================
sec W3

# `erm_w3_rows` costs 47 s. It is computed ONCE, its exit status is CAPTURED for
# W314 (which used to re-run the whole report just to look at `$?`), and the whole
# block is skipped when no selected group reads it.
W3="$TMP/w3.tsv"
W3_LINES=(); w3_rc=0
W3_COMPUTED=0
if want W3 || want ORI || want DET || want MUT; then
    W3_COMPUTED=1
    erm_w3_rows > "$W3"; w3_rc=$?
    mapfile -t W3_LINES < "$W3"
fi

declare -A W3_MARK=() W3_PROD=() W3_DUP=() W3_REL_SEEN=() W3_MARK_COUNT=()
w3_rows=0; w3_badmark=0; w3_dupes=0
for line in "${W3_LINES[@]}"; do
    [[ -n "$line" ]] || continue
    IFS="$TAB" read -r wr wt wm wp <<< "$line"
    w3_rows=$((w3_rows + 1))
    key="${wr}|${wt}"
    if [[ -n "${W3_MARK[$key]+set}" ]]; then w3_dupes=$((w3_dupes + 1)); fi
    W3_MARK["$key"]="$wm"
    W3_PROD["$key"]="$wp"
    W3_REL_SEEN["$wr"]=1
    W3_MARK_COUNT["$wm"]=$(( ${W3_MARK_COUNT[$wm]:-0} + 1 ))
    case "$wm" in producer|inferred-only|unreachable) ;; *) w3_badmark=$((w3_badmark + 1)) ;; esac
done

assert_nonempty "$w3_rows" "W301 the W3 report is non-empty"
assert_nonempty "${#VOCAB_RELATIONS[@]}" "W302 the merged vocabulary is non-empty"
assert_count_eq "${#W3_REL_SEEN[@]}" "${#VOCAB_RELATIONS[@]}" \
    "W303 the report covers every merged relation, one block each"
assert_count_eq "$w3_dupes" 0 "W304 no (relation, token) pair is marked twice"

# One mark per declared token, over every entry: a shortfall would mean a declared
# token went unreported.
expected_tokens=0
for r in "${VOCAB_RELATIONS[@]}"; do
    rel_endpoint_kinds_into "$r" || REL_LOOKUP=""
    for _t in $REL_LOOKUP; do expected_tokens=$((expected_tokens + 1)); done
done
assert_nonempty "$expected_tokens" "W305 the declared endpoint-token set is non-empty"
assert_count_eq "$w3_rows" "$expected_tokens" "W306 every declared endpoint token carries exactly one mark (AC-S6)"
assert_count_eq "$w3_badmark" 0 "W307 every mark is one of producer / inferred-only / unreachable"

# D8's worked example: every `illustrated-by` token is `producer`, and its tokens
# are satisfied by producers in two DIFFERENT harvest kinds.
ill_tokens=0; ill_producer=0
declare -A ill_features=()
for key in "${!W3_MARK[@]}"; do
    [[ "$key" == "illustrated-by|"* ]] || continue
    ill_tokens=$((ill_tokens + 1))
    [[ "${W3_MARK[$key]}" == "producer" ]] && ill_producer=$((ill_producer + 1))
    IFS='|' read -r -a _feats <<< "${W3_PROD[$key]}"
    for _f in "${_feats[@]}"; do [[ "$_f" == "--" || -z "$_f" ]] || ill_features["$_f"]=1; done
done
assert_nonempty "$ill_tokens" "W308 illustrated-by declares at least one endpoint token"
assert_count_eq "$ill_producer" "$ill_tokens" "W309 every illustrated-by token is producer (D8's worked example)"
assert_count_eq "${#ill_features[@]}" 2 "W310 illustrated-by's tokens are produced by two DIFFERENT harvest kinds"

# The counter-example that separates the two non-producer marks: a relation no map
# entry reaches AND whose `passes` excludes `inferred` is `unreachable`, not
# `inferred-only`. Without this the two marks could collapse into one.
q_n=0; q_bad=0
for key in "${!W3_MARK[@]}"; do
    [[ "$key" == "quotes|"* ]] || continue
    q_n=$((q_n + 1))
    [[ "${W3_MARK[$key]}" == "unreachable" ]] || q_bad=$((q_bad + 1))
done
assert_nonempty "$q_n" "W311 quotes declares at least one endpoint token"
assert_count_eq "$q_bad" 0 "W312 every quotes token is unreachable, not inferred-only (its passes excludes inferred)"
assert_nonempty "${W3_MARK_COUNT[inferred-only]:-0}" "W313 the inferred-only mark is actually used, so W312 discriminates"

# The report gates nothing: a core vocabulary is deliberately larger than any one
# project's producer set (feature-001 D3a), so unsatisfied entries are not failures.
# The status is the one captured from the single computation above.
assert_exit_eq "$w3_rc" 0 "W314 the report never fails once its inputs load"

# ===========================================================================
# ORI -- ORIENTATION SAFETY, the map half
# ===========================================================================
sec ORI
#
# Property: for every map entry emitting pair `a->b` as relation `r`, the report
# marks BOTH (r, "a->b") AND (inverse(r), "b->a") as produced. The transposition is
# taken from the map entry in the same step, so no stored row orientation can bias
# it. MUT01 removes the transpose, and this group must go red.

ori_checked=0; ori_missing_fwd=0; ori_missing_inv=0
for k in "${!K_PAIRS[@]}"; do
    r="${K_RELATION[$k]}"; inv="${INVERSE[$r]:-}"
    for t in ${K_PAIRS[$k]}; do
        a="${t%%->*}"; b="${t#*->}"
        ori_checked=$((ori_checked + 1))
        [[ "${W3_MARK[${r}|${a}->${b}]:-}" == "producer" ]] || ori_missing_fwd=$((ori_missing_fwd + 1))
        [[ "${W3_MARK[${inv}|${b}->${a}]:-}" == "producer" ]] || ori_missing_inv=$((ori_missing_inv + 1))
    done
done
assert_nonempty "$ori_checked"       "ORI01 the transposition universal runs over a non-empty set of map tokens"
assert_count_eq "$ori_missing_fwd" 0 "ORI02 every mapped kind pair is marked producer in its FORWARD reading"
assert_count_eq "$ori_missing_inv" 0 "ORI03 every mapped kind pair is marked producer in its TRANSPOSED reading (the inverse entry)"

# The concrete asymmetric pair the row half below then stores flipped, asserted here
# as a property of the report rather than of any row.
[[ "${W3_MARK[mentions|section->concept]:-}" == "producer" ]] \
    && pass "ORI04 mentions section->concept is marked producer (the HARVESTED reading)" \
    || fail "ORI04 mentions section->concept is not marked producer"
[[ "${W3_MARK[mentioned-in|concept->section]:-}" == "producer" ]] \
    && pass "ORI05 mentioned-in concept->section is marked producer (the STORED reading, after D7 flips it)" \
    || fail "ORI05 mentioned-in concept->section is not marked producer — the transpose was lost"

# ===========================================================================
# The fixture corpus
# ===========================================================================

FIX="$TMP/proj"
KB="$FIX/.aid/knowledge"
GT="$FIX/.aid/.temp/graph"
mkdir -p "$KB" "$GT" "$FIX/src" "$FIX/assets" "$FIX/docs"
: > "$FIX/src/lib.sh"; : > "$FIX/src/tool.sh"; : > "$FIX/docs/guide.md"; : > "$FIX/assets/logo.png"

# a-guide.md. The `## Overview` paragraph is deliberately ONE block: the citation
# marker and the two inline carriers share a fact's range, which is what makes
# D2e's ceiling observable in both directions (P1A18, P1A19).
cat > "$KB/a-guide.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture guide.
summary: Fixture guide summary.
sources:
  - src/lib.sh
  - tool.sh
see_also: [domain-glossary.md, INDEX.md]
owner: architect
audience: [developer]
---

# A Guide

Intro text above the first emitted heading.

## Overview

CONFIRMED. `src/lib.sh` (search: "lookup_list")
Prose citing `src/tool.sh`. See [the notes](b-notes.md) for more.

### Deep Topic

Body of the deep topic.

#### Nested Detail

A level-4 under a level-3; containment must attach to the level-3.

### Deep Topic

A duplicate heading; its slug takes the -1 ordinal.

## Illustrations

![logo](assets/logo.png)

## Fenced

```
## Not A Heading
CONFIRMED. `src/lib.sh` (search: "fenced marker")
```

## Loose Marker

CONFIRMED via directory listing.
FIXEOF

cat > "$KB/domain-glossary.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture glossary.
summary: Fixture glossary summary.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# Domain Glossary

## Concept Spine

> A preamble blockquote, carrying no definition marker.

### Canonical

**Definition-as-used-here:** The single authored source of truth.

### Concept Spine

**Definition-as-used-here:** The project's load-bearing concepts.

### Widget

**Definition:** A first widget sense.
FIXEOF

# D2f condition 3: this document LINKS the defining document, so its mention of
# `Canonical` must not be reported.
cat > "$KB/b-notes.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture notes.
summary: Fixture notes summary.
see_also: [domain-glossary.md]
owner: architect
audience: [developer]
---

# B Notes

## Usage

The Canonical form matters here, and this document links the glossary.

### Widget

**Definition:** A second widget sense, so the term is qualified.
FIXEOF

# D2f condition 4: this document shares a SECOND concept with the defining
# document, so its mention of `Canonical` must not be reported either.
cat > "$KB/d-shared.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture shared-vocabulary document.
summary: Fixture shared summary.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# D Shared

## Notes

The Canonical form is discussed, and so is the Concept Spine.
FIXEOF

# D2f's firing case: mentions `Canonical`, links nothing, shares nothing else.
cat > "$KB/z-isolated.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture isolated document.
summary: Fixture isolated summary.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# Z Isolated

## Remarks

The Canonical form appears here with nothing else shared.

CONFIRMED. `src/tool.sh` (search: "main")
FIXEOF

# AC-19: no heading at levels 2-6, no anchor, no definition.
cat > "$KB/c-bare.md" <<'FIXEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture bare document.
summary: Fixture bare summary.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# C Bare

A paragraph with no heading at levels 2-6, no anchor and no definition.
FIXEOF

# D2a source exclusion, case 1: a GENERATED document. Its citation marker must mint
# no fact and its heading no section.
cat > "$KB/INDEX.md" <<'FIXEOF'
---
kb-category: primary
source: generated
generator: build-kb-index.sh
objective: Fixture index.
summary: Fixture index summary.
see_also: [domain-glossary.md]
owner: architect
audience: [developer]
---

# Knowledge Base Index

## Entries

CONFIRMED. `src/lib.sh` (search: "must not be harvested from a generated file")

- [A Guide](a-guide.md)
FIXEOF

# D2a source exclusion, case 2: THIS FEATURE'S OWN PREVIOUS OUTPUT. A run that
# harvested from it would bootstrap its next output from its last one.
cat > "$KB/relationships.md" <<'FIXEOF'
---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: Placeholder, overwritten by the run under test.
summary: Placeholder.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# Relationships

## Stale Section

CONFIRMED. `src/lib.sh` (search: "must not bootstrap from the previous run")
FIXEOF

# feature-004's four streams.
{
  printf 'int:src/lib.sh\tsrc/lib.sh\tscript\tpublic-surface\tsrc/lib.sh -- shell function (search: "lookup_list")\tdeclared\tsource-artifact\n'
  printf 'int:src/tool.sh\tsrc/tool.sh\tscript\tentry-point\tsrc/tool.sh -- entry point (search: "main")\tdeclared\tsource-artifact\n'
  printf 'int:docs/guide.md\tdocs/guide.md\tdoc\tnamed-unit\tdocs/guide.md -- named unit (search: "Guide")\tdeclared\tsource-artifact\n'
} | LC_ALL=C sort > "$GT/nodes.tsv"

printf 'int:assets/logo.png\tassets/logo.png\timage\tassets/logo.png -- extension listed in relationship-schema.yml (search: "image_extensions")\tderived\n' \
    > "$GT/media-nodes.tsv"

# One observation per typed kind, the deliberately unmapped one, and both branches
# of feature-001 D6c's resolution-keyed provenance: a literal full path and a bare
# basename, on the SAME observation kind, differing in nothing else.
{
  printf 'int:src/tool.sh\tint:src/lib.sh\tinvocation\tsrc/lib.sh -- inbound reference (search: "bash src/lib.sh" in src/tool.sh)\n'
  printf 'int:src/tool.sh\tint:assets/logo.png\timage-reference\tassets/logo.png -- inbound reference (search: "assets/logo.png" in src/tool.sh)\n'
  printf 'int:src/lib.sh\tint:assets/logo.png\timage-reference\tassets/logo.png -- inbound reference (search: "logo.png" in src/lib.sh)\n'
  printf 'int:src/tool.sh\tint:docs/guide.md\tdependency\tdocs/guide.md -- inbound reference (search: "guide.md" in src/tool.sh)\n'
  printf 'int:src/lib.sh\tint:src/tool.sh\tpath-reference\tsrc/tool.sh -- inbound reference (search: "src/tool.sh" in src/lib.sh)\n'
} | LC_ALL=C sort > "$GT/observations.tsv"

# A feature-004 candidate no class-1 row can ever name (an unresolved site-absolute
# URL path), so only the disposition arm of the union can discharge it.
printf 'edge\tsite/public/favicon.svg\tfavicon reference in site/astro.config.mjs\tunresolved-reference\n' \
    > "$GT/candidates.tsv"

# feature-004 D7's contribution. The two trailing `--` rows are what make REN16's
# interleave observable: `image-external` sorts BETWEEN two rows produced by the
# other file, so the rendered order cannot be a concatenation of the two files.
{
  printf 'kind\tsource-artifact\tpresent\t3\tproject source, per FR-21 significance\n'
  printf 'kind\timage\tpresent\t1\timage files in-repo; no external key is an image (D-5)\n'
  printf 'kind\tweb-page\tabsent\t0\tentries in the external-sources file\n'
  printf 'exclusion\tgenerated-trees\tyes\t--\tunconditional (FR-22)\n'
  printf 'exclusion\tvendored-code\tyes\t--\tunconditional (FR-22)\n'
  printf 'exclusion\tignore-list\tno\t--\tsetting absent -- ignore list unavailable (D-4)\n'
  printf 'kind\timage-external\t--\t--\texternal image keys registered: 0\n'
  printf 'kind\tsource-artifact-dropped\t--\t--\tsurviving paths dropped by the significance rule: 0\n'
} > "$GT/coverage.tsv"

( cd "$FIX" && git init -q . ) >/dev/null 2>&1

# ---------------------------------------------------------------------------
# The eight subject invocations. See the COST MODEL above for why each exists.
# ---------------------------------------------------------------------------
run_pass1() {
    local out="$1" prc=0
    ( cd "$FIX" && bash "$HARVEST" --temp-dir "$GT" --kb-root .aid/knowledge --repo-root "$FIX" ) \
        >"${out}.harvest" 2>&1 || prc=$?
    ( cd "$FIX" && bash "$DERIVE" --temp-dir "$GT" ) >"${out}.derive" 2>&1 || prc=$?
    return $prc
}

# Echoes the exit code, so a non-zero build never aborts the suite. Every carrier
# path is passed explicitly: a mutant lives outside the shipped tree, where the
# default `<script-dir>/../../templates/graph` resolution does not exist, and a
# mutant that exited 2 on a usage error would "prove" whatever was asserted next.
# `--assembler` is always the REAL canonical assemble-coverage-notes.sh unless a
# 4th argument overrides it -- a build-relationships.sh mutant lives in its own
# directory with no sibling assembler, and the hand-off script itself is never
# what MUT02-MUT04 mean to exercise.
run_build() {
    local log="$1" out="$2" script="${3:-$BUILD}" assembler="${4:-$ASSEMBLER}" brc=0
    ( cd "$FIX" && bash "$script" --temp-dir "$GT" --out "$out" \
        --schema "$SCHEMA" --vocabulary "$VOCAB" --edge-map "$EDGE_MAP" \
        --lib "$LIB" --assembler "$assembler" --skip-validate ) >"$log" 2>&1 || brc=$?
    printf '%s' "$brc"
}

rc=0
if [[ "$NEED_PIPELINE" -eq 1 ]]; then run_pass1 "$TMP/runA" || rc=$?; fi
sec P1A
assert_exit_eq "$rc" 0 "P1A01 Pass 1a and Pass 1b both exit 0 on the fixture corpus"

P1A="$GT/rows-pass1a.tsv"
P1B="$GT/rows-pass1b.tsv"
KBNODES="$GT/kb-nodes.tsv"
STATS="$GT/kb-stats.tsv"
ROWS0="$GT/rows-class0.tsv"
COV="$GT/kb-coverage.tsv"
CMC="$GT/concept-merge-candidates.tsv"
ACC="$GT/rows-class1-accepted.tsv"
CAND1B="$GT/candidates-pass1b.tsv"
DISP="$GT/dispositions.tsv"
ART="$KB/relationships.md"

# ---------------------------------------------------------------------------
# Pass 2's inputs, built from what Pass 1 actually emitted rather than guessed.
#
# Every candidate is dispositioned EXCEPT the one from candidates-pass1b.tsv, whose
# subject names two node ids. That one can be discharged only by the SECOND arm of
# FR-31a part 2's union -- an accepted class-1 row over the same pair -- so CMP04's
# "no shortfall" is a live test of that arm and not a second test of the first.
# ---------------------------------------------------------------------------
: > "$DISP"
n_disp=0
for cf in "$GT/candidates.tsv" "$GT/candidates-pass1a.tsv"; do
    [[ -f "$cf" ]] || continue
    while IFS="$TAB" read -r _kind subject context _reason || [[ -n "${_kind:-}" ]]; do
        [[ -n "${subject:-}" ]] || continue
        printf '%s%s%s\tcannot-type\tfixture: dispositioned by the suite\n' \
            "$subject" "$US" "${context:-}" >> "$DISP"
        n_disp=$((n_disp + 1))
    done < "$cf"
done
n_pair_cand=0
if [[ -f "$CAND1B" ]]; then
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && n_pair_cand=$((n_pair_cand + 1))
done < "$CAND1B"
fi
sec CMP
assert_nonempty "$n_pair_cand" \
    "CMP01 the id-pair candidate exists, so the union's SECOND arm is the only thing that can discharge it"
assert_nonempty "$n_disp" \
    "CMP02 at least one candidate is dispositioned, so the union's FIRST arm is exercised too"

n_reads=0
if [[ -f "$GT/pass2-inputs.tsv" ]]; then
: > "$GT/pass2-reads.tsv"
while IFS="$TAB" read -r mkind mval || [[ -n "${mkind:-}" ]]; do
    [[ "$mkind" == "document" ]] || continue
    printf '%s\n' "$mval" >> "$GT/pass2-reads.tsv"
    n_reads=$((n_reads + 1))
done < "$GT/pass2-inputs.tsv"
fi
assert_nonempty "$n_reads" "CMP03 the read ledger names at least one manifest document"

# Pass 2's returned rows: three legal ones, one per D6 rejection. Row 2 carries an
# EMPTY Observation, which is what makes REN09's well-formed-empty rule testable.
{
  printf '1\tkb:concept:canonical\tconcept\tCanonical\tkb:concept:widget@b-notes.md\tconcept\tWidget (b-notes.md)\tbroader-than\tnarrower-than\tinferred\taccepted: concept->concept admits inferred\n'
  printf '1\tkb:concept:canonical\tconcept\tCanonical\tkb:concept:concept-spine\tconcept\tConcept Spine\trelated-concept\trelated-concept\tinferred\t\n'
  printf '1\tint:src/lib.sh\tsource-artifact\tsrc/lib.sh\tint:src/tool.sh\tsource-artifact\tsrc/tool.sh\tsame-as\tsame-as\tinferred\taccepted: discharges the path-reference candidate by id pair\n'
  printf '1\tkb:concept:nonexistent\tconcept\tNope\tkb:a-guide.md\tdocument\ta-guide.md\tmentions\tmentioned-in\tinferred\trejection 1: endpoint in no node stream\n'
  printf '1\tkb:concept:canonical\tconcept\tCanonical\tkb:concept:concept-spine\tconcept\tConcept Spine\trelated-concept\trelated-concept\tderived\trejection 3: provenance is not inferred\n'
  printf '1\tkb:concept:canonical\tconcept\tCanonical\tkb:concept:concept-spine\tconcept\tConcept Spine\tfrobnicates\tfrobnicated-by\tinferred\trejection 4a: not a vocabulary member\n'
  printf '1\tkb:domain-glossary.md\tdocument\tdomain-glossary.md\tkb:concept:concept-spine\tconcept\tConcept Spine\tdefines\tdefined-by\tinferred\trejection 4b: passes excludes inferred\n'
  printf '1\tkb:a-guide.md\tdocument\ta-guide.md\tkb:b-notes.md\tdocument\tb-notes.md\tbroader-than\tnarrower-than\tinferred\trejection 4c: endpoint_kinds excludes document->document\n'
  printf '1\tkb:z-isolated.md#remarks\tsection\tz-isolated.md \xc2\xa7 Remarks\tkb:concept:canonical\tconcept\tCanonical\tmentions\tmentioned-in\tinferred\trejection 2: collides with a frozen class-0 key\n'
} > "$GT/rows-class1.tsv"
cp "$GT/rows-class1.tsv" "$TMP/rows-class1.keep"

A_RC=0; A_OUT=""
if [[ "$NEED_PIPELINE" -eq 1 ]]; then
    A_RC="$(run_build "$TMP/runA.build" "$ART")"
    A_OUT="$(<"$TMP/runA.build")"
    # Snapshot run 1 immediately, before a later run overwrites the scratch files.
    cp "$ART" "$TMP/artifact.run1"
    cp "$ROWS0" "$TMP/rows0.run1"
    cp "$COV" "$TMP/cov.run1"
    cp "$GT/coverage-notes.md" "$TMP/coverage-notes.run1"
    [[ "$W3_COMPUTED" -eq 1 ]] && cp "$W3" "$TMP/w3.run1"
    cp "$DISP" "$TMP/dispositions.keep"
fi

# ===========================================================================
# ONE READ of every output, into memory. Every assertion after this point is a
# builtin over these arrays.
# ===========================================================================

# --- kb-nodes.tsv: id | kind | name | doc ---
declare -A NODE_KIND=() NODE_NAME=() NODE_KIND_COUNT=()
NODE_IDS=()
if [[ -f "$KBNODES" ]]; then
while IFS="$TAB" read -r nid nkind nname ndoc || [[ -n "${nid:-}" ]]; do
    [[ -n "${nid:-}" ]] || continue
    NODE_IDS+=("$nid")
    NODE_KIND["$nid"]="$nkind"
    NODE_NAME["$nid"]="${nname:-}"
    NODE_KIND_COUNT["$nkind"]=$(( ${NODE_KIND_COUNT[$nkind]:-0} + 1 ))
done < "$KBNODES"
fi

# --- kb-stats.tsv and kb-coverage.tsv: key -> value ---
declare -A STAT=()
if [[ -f "$STATS" ]]; then
while IFS="$TAB" read -r sk sv || [[ -n "${sk:-}" ]]; do
    [[ -n "${sk:-}" ]] && STAT["$sk"]="${sv:-}"
done < "$STATS"
fi
declare -A COV_KEY=()
# The count field, kept in its OWN map rather than re-split from COV_KEY's
# pipe-joined string: task-009's REN25 compares this -- kb-coverage.tsv's own
# number -- against the rendered artifact's Nodes cell, so it must be the exact
# substring the producer wrote and never a re-parse of an already-joined value.
declare -A COV_COUNT=()
if [[ -f "$COV" ]]; then
while IFS="$TAB" read -r ck2 ck cstat ccount cnote || [[ -n "${ck2:-}" ]]; do
    [[ -n "${ck:-}" ]] && COV_KEY["$ck"]="${cstat:-}|${ccount:-}|${cnote:-}"
    [[ -n "${ck:-}" ]] && COV_COUNT["$ck"]="${ccount:-}"
done < "$COV"
fi

# --- the two Pass-1 row streams and the frozen set ---
# The eleven columns are class | sid | skind | sname | tid | tkind | tname |
# s2t | t2s | provenance | observation.
EXT_RE=""   # set below, once REL_CITE_EXTENSIONS is read

declare -A P1A_SRC_COUNT=() P1A_TGT_COUNT=() P1A_S2T_COUNT=() \
           P1A_SRC_OF_TGT=() P1A_RELTGT_SKIND=() P1A_RELTGT_PROV=() \
           P1A_RELTGT_OBS=() P1A_PAIR_S2T=()
p1a_n=0; p1a_mention_canonical=0; p1a_bad_anchor=0; p1a_bad_prov=0
p1a_int_hash=0; p1a_int_unknown=0; p1a_int_checked=0

declare -A P1B_S2T_COUNT=() P1B_OBS_PROV=()
p1b_n=0; p1b_blank=0; p1b_bad_prov=0; p1b_int_hash=0; p1b_int_unknown=0

declare -A R0_KEYS=() R0_PAIR=()
r0_n=0; r0_dup=0; r0_kindmismatch=0; r0_bad_prov=0
R0_SORTKEYS=()

# AC-16: the closed set of `int:` ids this feature may ever NAME as an endpoint --
# read from the fixture's own feature-004 streams, never re-derived, because the
# claim is "this feature emits no int: id it did not read from feature-004's
# streams" and re-deriving the set here would test the fixture against itself.
declare -A FIX_INT_IDS=()
for _f in "$GT/nodes.tsv" "$GT/media-nodes.tsv"; do
    [[ -f "$_f" ]] || continue
    while IFS="$TAB" read -r _iid _rest || [[ -n "${_iid:-}" ]]; do
        [[ "${_iid:-}" == int:* ]] && FIX_INT_IDS["$_iid"]=1
    done < "$_f"
done

implied_kind() {   # sets IMPLIED, no fork
    case "$1" in
        kb:concept:*) IMPLIED=concept ;;
        kb:*#fact:*)  IMPLIED=fact ;;
        kb:*#*)       IMPLIED=section ;;
        kb:*)         IMPLIED=document ;;
        *)            IMPLIED="" ;;
    esac
}

# ===========================================================================
# P1A -- Pass 1a
# ===========================================================================
sec P1A

assert_nonempty "${#NODE_IDS[@]}" "P1A02 the KB node set is non-empty"
for kind in document section fact concept; do
    assert_nonempty "${NODE_KIND_COUNT[$kind]:-0}" "P1A03 at least one '$kind' node is emitted"
done

# D2a: the two generated documents are excluded as SOURCES of sub-document nodes
# and of edges, and both remain valid TARGETS.
assert_key NODE_KIND "kb:INDEX.md" \
    "P1A04 INDEX.md is still a document NODE (membership is feature-003's predicate, not this exclusion)"
assert_key NODE_KIND "kb:relationships.md" "P1A05 relationships.md is still a document NODE"
idx_sub=0; rel_sub=0; bare_sub=0; h1_node=0
for nid in "${NODE_IDS[@]}"; do
    case "$nid" in
        kb:INDEX.md#*)         idx_sub=$((idx_sub + 1)) ;;
        kb:relationships.md#*) rel_sub=$((rel_sub + 1)) ;;
        kb:c-bare.md#*)        bare_sub=$((bare_sub + 1)) ;;
        kb:a-guide.md#a-guide) h1_node=$((h1_node + 1)) ;;
    esac
done
assert_count_eq "$idx_sub" 0 "P1A06 INDEX.md yields NO section or fact node (excluded as a source)"
assert_count_eq "$rel_sub" 0 "P1A07 relationships.md yields NO section or fact node (no bootstrap from the previous run)"
assert_count_eq "$h1_node" 0 "P1A08 the level-1 heading mints no section node (the H1 is the document)"

# Fenced-code inertness, BOTH directions, each with a positive control so an
# absence cannot pass merely because the slug or the counter has another shape.
assert_key NODE_KIND "kb:a-guide.md#fenced" \
    "P1A09 the real '## Fenced' heading DOES mint a section (the positive control for the slug form)"
assert_no_key NODE_KIND "kb:a-guide.md#not-a-heading" \
    "P1A10 a heading-shaped line INSIDE a fence mints no section node (AC-S1)"
assert_count_eq "${NODE_KIND_COUNT[fact]:-0}" 2 \
    "P1A11 exactly two facts are minted — the fenced citation marker mints none (AC-S1, the second direction)"

# D2a-1: the duplicate heading takes the -1 ordinal. Both ids exist and differ.
assert_key NODE_KIND "kb:a-guide.md#deep-topic"   "P1A12 the first duplicate heading keeps the bare slug"
assert_key NODE_KIND "kb:a-guide.md#deep-topic-1" "P1A13 the second occurrence takes the -1 ordinal (D2a-1)"

# AC-S2: a term defined once and named in four documents is ONE node.
assert_key NODE_KIND "kb:concept:canonical" "P1A14 the singly-defined term yields the PLAIN concept id"
canon_nodes=0
for nid in "${NODE_IDS[@]}"; do
    [[ "$nid" == kb:concept:canonical* ]] && canon_nodes=$((canon_nodes + 1))
done
assert_count_eq "$canon_nodes" 1 "P1A15 that term yields exactly ONE node however many documents name it (AC-S2, Q13)"

# D2d case 1: a term defined twice never emits the plain form.
assert_no_key NODE_KIND "kb:concept:widget" "P1A16 a term with two definitions never emits the plain id (D2d case 1)"
assert_key NODE_KIND "kb:concept:widget@domain-glossary.md" "P1A17a the first definition takes the @<doc> form"
assert_key NODE_KIND "kb:concept:widget@b-notes.md"         "P1A17b the second definition takes the @<doc> form"

# AC-19: a document with no heading, no anchor and no definition is still a node
# and contributes no sub-document node -- a floor, not an error.
assert_key NODE_KIND "kb:c-bare.md" "P1A20 a featureless document is still a document node (AC-19)"
assert_count_eq "$bare_sub" 0 "P1A21 a featureless document contributes no sub-document node, and is not an error"

# D7's counters, each a function of the deterministic pass.
assert_count_eq "${STAT[fact-unanchored]:-}" 1 \
    "P1A22 the anchor-less citation marker is COUNTED, not turned into a fact node (D2a-2)"
assert_count_eq "${STAT[concept-qualified]:-}" 2 "P1A23 both qualified definitions are counted"
assert_count_eq "${STAT[section-empty-slug]:-}" 0 "P1A24a the empty-slug counter is reported even when zero"

# The V11 extension set, read from the library's single carrier and used by V1102
# below and by the V11 skip decision. `SQ` exists because a backslash before a
# single quote inside DOUBLE quotes is not an escape in bash -- `"\'"` is two
# characters, and a pattern built that way would never match.
SQ=$'\047'
cite_ext=""
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "REL_CITE_EXTENSIONS="* ]]; then
        cite_ext="${line#*=}"
        cite_ext="${cite_ext#$SQ}"
        cite_ext="${cite_ext%$SQ}"
        break
    fi
done < "$LIB"
assert_nonempty "${#cite_ext}" "P1A24c the Citation Rule's extension set was read from the library's single carrier"
EXT_RE="\.(${cite_ext// /|})\$"

# --- the single pass over rows-pass1a.tsv ---
if [[ -f "$P1A" ]]; then
while IFS="$TAB" read -r cls sid skind sname tid tkind tname s2t t2s prov obs || [[ -n "${cls:-}" ]]; do
    [[ -n "${sid:-}" ]] || continue
    p1a_n=$((p1a_n + 1))
    P1A_SRC_COUNT["$sid"]=$(( ${P1A_SRC_COUNT[$sid]:-0} + 1 ))
    P1A_TGT_COUNT["$tid"]=$(( ${P1A_TGT_COUNT[$tid]:-0} + 1 ))
    P1A_S2T_COUNT["$s2t"]=$(( ${P1A_S2T_COUNT[$s2t]:-0} + 1 ))
    P1A_PAIR_S2T["${sid}|${tid}"]="$s2t"
    # The containment probe: the SOURCE of the row whose target is this node. Kept
    # as a deduplicated space-joined list so a second parent is visible rather than
    # silently overwritten.
    case " ${P1A_SRC_OF_TGT[$tid]:-} " in
        *" $sid "*) ;;
        *) P1A_SRC_OF_TGT["$tid"]="${P1A_SRC_OF_TGT[$tid]:-}${P1A_SRC_OF_TGT[$tid]:+ }$sid" ;;
    esac
    rtk="${s2t}|${tid}"
    case " ${P1A_RELTGT_SKIND[$rtk]:-} " in
        *" $skind "*) ;;
        *) P1A_RELTGT_SKIND["$rtk"]="${P1A_RELTGT_SKIND[$rtk]:-}${P1A_RELTGT_SKIND[$rtk]:+ }$skind" ;;
    esac
    P1A_RELTGT_PROV["$rtk"]="${prov:-}"
    P1A_RELTGT_OBS["$rtk"]="${obs:-}"
    [[ "$s2t" == "$mention_rel" && "$tid" == "kb:concept:canonical" ]] && \
        p1a_mention_canonical=$((p1a_mention_canonical + 1))
    if [[ -n "${obs:-}" ]]; then
        tok="${obs%% *}"
        [[ "$tok" =~ $EXT_RE ]] || p1a_bad_anchor=$((p1a_bad_anchor + 1))
    fi
    # AC-4 (D5): Pass 1a is wholly deterministic, so every row it emits is
    # `declared` or `derived` -- never `inferred` (that provenance is Pass 2's
    # alone, D6 rejection 3) and never blank (D5 assigns it by the carrier rule,
    # not left to a default).
    case "${prov:-}" in declared|derived) ;; *) p1a_bad_prov=$((p1a_bad_prov + 1)) ;; esac
    # AC-16: no `int:` id carries a `#` fragment of any kind, and every `int:` id
    # this feature NAMES is a member of feature-004's own streams -- this feature
    # mints no `int:` id of its own.
    for _id in "$sid" "$tid"; do
        [[ "$_id" == int:*'#'* ]] && p1a_int_hash=$((p1a_int_hash + 1))
        if [[ "$_id" == int:* ]]; then
            p1a_int_checked=$((p1a_int_checked + 1))
            [[ -n "${FIX_INT_IDS[$_id]+set}" ]] || p1a_int_unknown=$((p1a_int_unknown + 1))
        fi
    done
done < "$P1A"
fi

assert_nonempty "$p1a_n" "P1A24b Pass 1a emitted rows"
assert_count_eq "${P1A_SRC_COUNT[kb:INDEX.md]:-0}" 0 "P1A25 no harvested row is SOURCED from INDEX.md"
assert_count_eq "${P1A_SRC_COUNT[kb:relationships.md]:-0}" 0 "P1A26 no harvested row is SOURCED from relationships.md"
assert_nonempty "${P1A_TGT_COUNT[kb:INDEX.md]:-0}" \
    "P1A27 INDEX.md IS a valid TARGET (a hand-authored citation of it is a real edge)"
assert_eq "${P1A_RELTGT_PROV[${haspart_rel}|kb:a-guide.md#overview]:-}" "derived" \
    "P1A24d a containment edge is literally 'derived' (D5: nothing STATES a section is part of its document — the scan computes it) — the positive control the next universal needs"
assert_count_eq "$p1a_bad_prov" 0 \
    "P1A24d1 every Pass 1a row's Provenance is 'declared' or 'derived' — never blank, never 'inferred' (AC-4, D5)"
assert_count_eq "$p1a_int_hash" 0 \
    "P1A24e no Pass 1a row names an 'int:' id carrying a '#' fragment of any kind (AC-16)"
assert_nonempty "$p1a_int_checked" \
    "P1A24f Pass 1a names at least one 'int:' id, so P1A24g is not a universal over an empty set"
assert_count_eq "$p1a_int_unknown" 0 \
    "P1A24g every 'int:' id Pass 1a names is a member of feature-004's own streams — this feature mints no int: id (AC-16)"

# D2b: containment by LEVEL STACK, not by the block-body scan. The level-4 must
# attach to the level-3 above it -- not to the nearest preceding heading of any
# level, and not to the enclosing level-2.
assert_eq "${P1A_SRC_OF_TGT[kb:a-guide.md#nested-detail]:-}" "kb:a-guide.md#deep-topic" \
    "P1A28 the level-4 heading is contained by the level-3 above it (D2b's level stack, not D2a-3a's block body)"
assert_eq "${P1A_SRC_OF_TGT[kb:a-guide.md#deep-topic-1]:-}" "kb:a-guide.md#overview" \
    "P1A29 the second level-3 attaches to the level-2, not to the level-4 that precedes it"

# D2e, both sides, from ONE paragraph. The map's kind pairs are the ceiling:
# `kb-inline-path-citation` declares fact->source-artifact, so the citation
# attributes to the FACT; `kb-inline-doc-link` declares no fact->document, so the
# link inside the SAME fact's range stops at the section. The difference is DATA.
assert_eq "${P1A_RELTGT_SKIND[${cites_rel}|int:src/tool.sh]:-}" "fact" \
    "P1A30 an inline path citation inside a fact attributes to the FACT (the map admits fact->source-artifact)"
assert_eq "${P1A_RELTGT_SKIND[${doclink_rel}|kb:b-notes.md]:-}" "section" \
    "P1A31 an inline doc link in the SAME fact attributes to the SECTION (the map admits no fact->document) — D2e's ceiling is data"

assert_nonempty "$p1a_mention_canonical" "P1A32 mention count appears as graph DEGREE, not as duplicate nodes"

# AC-S8: provenance is keyed on the STATEMENT, so a bare basename that required
# resolution still emits `declared`, and the anchor quotes what was WRITTEN.
assert_eq "${P1A_RELTGT_PROV[${documents_rel}|int:src/tool.sh]:-}" "declared" \
    "P1A33 a bare-basename sources: entry emits 'declared' — provenance keys on the statement, not the resolution (AC-S8)"
case "${P1A_RELTGT_OBS[${documents_rel}|int:src/tool.sh]:-}" in
    *'(search: "tool.sh")'*) pass "P1A34 the anchor quotes the literal that was WRITTEN, not the path it resolved to" ;;
    *) fail "P1A34 the anchor does not quote the written literal — got '${P1A_RELTGT_OBS[${documents_rel}|int:src/tool.sh]:-}'" ;;
esac

# ---------------------------------------------------------------------------
# AC-19's KB-WIDE claim: a project supplying no instance of section/fact/concept's
# carrier convention still exits successfully with ZERO nodes of the affected kind
# — not a failed run. The main fixture above cannot exercise this: every kind is
# deliberately present and non-zero there (P1A02/P1A03 need that). A SEPARATE,
# minimal one-document KB is built here for exactly this claim, and it is the one
# extra subject invocation this task adds (see the S1 budget above) — nothing
# downstream of `kb-stats.tsv` (Pass 1b, the merge, the render) varies with this
# claim, so `derive-edges.sh` and `build-relationships.sh` are not re-run for it.
# `br_status_of` (build-relationships.sh) maps that flag to the rendered
# `present`/`absent` cell with one line -- `[ "$1" = "1" ] && present || absent` --
# reviewable by grep rather than re-run, on R8's own precedent.
if want P1A; then
ABSROOT="$TMP/abs"
ABSKB="$ABSROOT/.aid/knowledge"
ABSGT="$ABSROOT/.aid/.temp/graph"
mkdir -p "$ABSKB" "$ABSGT"
cat > "$ABSKB/only.md" <<'ABSEOF'
---
kb-category: primary
source: hand-authored
objective: Fixture with no carrier convention at all.
summary: No heading below H1, no citation marker, no definition marker.
see_also: [INDEX.md]
owner: architect
audience: [developer]
---

# Only

A paragraph with nothing any of Pass 1a's four carrier conventions recognise: no
ATX heading at level 2-6, no checkable source anchor, and no definition marker.
ABSEOF
: > "$ABSGT/nodes.tsv"
: > "$ABSGT/media-nodes.tsv"
( cd "$ABSROOT" && git init -q . ) >/dev/null 2>&1

abs_rc=0
( cd "$ABSROOT" && bash "$HARVEST" --temp-dir "$ABSGT" --kb-root .aid/knowledge --repo-root "$ABSROOT" ) \
    >"$TMP/abs.harvest" 2>&1 || abs_rc=$?
assert_exit_eq "$abs_rc" 0 \
    "P1A35 a KB supplying NO instance of the section/fact/concept carrier still exits 0 (AC-19: absence is not a failed run)"

declare -A ABS_STAT=()
if [[ -f "$ABSGT/kb-stats.tsv" ]]; then
while IFS="$TAB" read -r ask asv || [[ -n "${ask:-}" ]]; do
    [[ -n "${ask:-}" ]] && ABS_STAT["$ask"]="${asv:-}"
done < "$ABSGT/kb-stats.tsv"
fi
for k in section fact concept; do
    assert_count_eq "${ABS_STAT[carrier-$k]:-X}" 0 \
        "P1A36 the '$k' carrier flag reads 0 on a KB with no instance of it — br_status_of's only input for the rendered 'absent' cell (AC-19)"
    assert_count_eq "${ABS_STAT[${k}s]:-X}" 0 \
        "P1A37 the '$k' node count reads 0 on the same KB — zero nodes of the affected kind (AC-19), not an error"
done
abs_nodes=0
if [[ -f "$ABSGT/kb-nodes.tsv" ]]; then
while IFS="$TAB" read -r anid ankind _ _ || [[ -n "${anid:-}" ]]; do
    [[ -n "${anid:-}" ]] || continue
    case "$ankind" in section|fact|concept) abs_nodes=$((abs_nodes + 1)) ;; esac
done < "$ABSGT/kb-nodes.tsv"
fi
assert_count_eq "$abs_nodes" 0 \
    "P1A38 kb-nodes.tsv itself carries zero section/fact/concept nodes on this fixture, so P1A36/P1A37 are not reading a counter the run never touched"
fi

# ===========================================================================
# P1B -- Pass 1b
# ===========================================================================
sec P1B

if [[ -f "$P1B" ]]; then
while IFS="$TAB" read -r cls sid skind sname tid tkind tname s2t t2s prov obs || [[ -n "${cls:-}" ]]; do
    [[ -n "${sid:-}" ]] || continue
    p1b_n=$((p1b_n + 1))
    [[ -z "${s2t:-}" || -z "${t2s:-}" ]] && p1b_blank=$((p1b_blank + 1))
    P1B_S2T_COUNT["$s2t"]=$(( ${P1B_S2T_COUNT[$s2t]:-0} + 1 ))
    case "${obs:-}" in
        *'search: "assets/logo.png"'*) P1B_OBS_PROV["${s2t}|literal"]="${prov:-}" ;;
        *'search: "logo.png"'*)        P1B_OBS_PROV["${s2t}|basename"]="${prov:-}" ;;
    esac
    # AC-4 (D5): Pass 1b is likewise wholly deterministic (feature-004's scanner
    # already ran), so every row is `declared` or `derived`, never `inferred` and
    # never blank.
    case "${prov:-}" in declared|derived) ;; *) p1b_bad_prov=$((p1b_bad_prov + 1)) ;; esac
    # AC-16, over Pass 1b's own rows: no `int:` id carries a `#` fragment, and every
    # `int:` id named is a member of feature-004's streams.
    for _id in "$sid" "$tid"; do
        [[ "$_id" == int:*'#'* ]] && p1b_int_hash=$((p1b_int_hash + 1))
        if [[ "$_id" == int:* ]]; then
            [[ -n "${FIX_INT_IDS[$_id]+set}" ]] || p1b_int_unknown=$((p1b_int_unknown + 1))
        fi
    done
done < "$P1B"
fi

assert_nonempty "$p1b_n" "P1B01 Pass 1b emitted rows"
for okind in invocation dependency image-reference; do
    expect="${K_RELATION[$okind]}"
    assert_nonempty "${P1B_S2T_COUNT[$expect]:-0}" \
        "P1B02 the '$okind' observation is typed as '$expect' through the map"
done
assert_count_eq "$p1b_blank" 0 "P1B03 no Pass 1b row carries a blank relation label"
assert_count_eq "$p1b_bad_prov" 0 \
    "P1B02a every Pass 1b row's Provenance is 'declared' or 'derived' — never blank, never 'inferred' (AC-4, D5)"
assert_count_eq "$p1b_int_hash" 0 \
    "P1B02b no Pass 1b row names an 'int:' id carrying a '#' fragment of any kind (AC-16)"
assert_count_eq "$p1b_int_unknown" 0 \
    "P1B02c every 'int:' id Pass 1b names is a member of feature-004's own streams — this feature mints no int: id (AC-16)"

# `path-reference` is deliberately unmapped: it becomes a Pass-2 candidate and no row.
unmapped_candidate=0
if [[ -f "$CAND1B" ]]; then
while IFS="$TAB" read -r _k _s _c _r || [[ -n "${_k:-}" ]]; do
    [[ "${_c:-}" == *"path-reference"* ]] && unmapped_candidate=1
done < "$CAND1B"
fi
assert_true "$unmapped_candidate" \
    "P1B04 the unmapped path-reference observation becomes a Pass-2 candidate and no row (D3, by design)"

# feature-001 D6c, keyed on the RESOLUTION and not on the kind: `declared` where
# the target was reached by a literal full path, `derived` where by a basename. The
# two rows differ in nothing else, so the branch is the only explanation.
assert_eq "${P1B_OBS_PROV[${ill_rel}|literal]:-}"  "declared" \
    "P1B05 an illustration reached by a LITERAL full path is declared (feature-001 D6c)"
assert_eq "${P1B_OBS_PROV[${ill_rel}|basename]:-}" "derived" \
    "P1B06 the SAME observation kind reached by a BASENAME is derived (feature-001 D6c)"

# ===========================================================================
# ORI -- ORIENTATION SAFETY, the row half; and MRG -- the merge
# ===========================================================================
sec ORI
#
# The fixture guarantees genuinely FLIPPED pairs: harvested
# `kb:z-isolated.md#remarks -> kb:concept:canonical` has a Source Id that sorts
# AFTER its Target Id under LC_ALL=C, so feature-003 D7 must store it reversed.

if [[ -f "$ROWS0" ]]; then
while IFS="$TAB" read -r cls sid skind sname tid tkind tname s2t t2s prov obs || [[ -n "${cls:-}" ]]; do
    [[ -n "${sid:-}" ]] || continue
    r0_n=$((r0_n + 1))
    key="${sid}${US}${tid}${US}${s2t}${US}${t2s}"
    if [[ -n "${R0_KEYS[$key]+set}" ]]; then r0_dup=$((r0_dup + 1)); fi
    R0_KEYS["$key"]=1
    R0_PAIR["${sid}|${tid}"]="${skind}|${tkind}|${s2t}|${t2s}"
    R0_SORTKEYS+=("${cls}${TAB}${sid}${TAB}${tid}${TAB}${s2t}${TAB}${t2s}")
    implied_kind "$sid"; [[ -z "$IMPLIED" || "$IMPLIED" == "$skind" ]] || r0_kindmismatch=$((r0_kindmismatch + 1))
    implied_kind "$tid"; [[ -z "$IMPLIED" || "$IMPLIED" == "$tkind" ]] || r0_kindmismatch=$((r0_kindmismatch + 1))
    # AC-4 (D5), re-checked on the MERGED, FROZEN output rather than trusting the
    # two pre-merge streams: the merge's own de-duplication (step 11) is the one
    # place a tie-break could theoretically carry a bad value forward undetected.
    case "${prov:-}" in declared|derived) ;; *) r0_bad_prov=$((r0_bad_prov + 1)) ;; esac
done < "$ROWS0"
fi

assert_nonempty "$r0_n" "ORI06 the frozen class-0 set is non-empty"
assert_count_eq "$r0_bad_prov" 0 \
    "ORI06a every frozen class-0 row's Provenance is 'declared' or 'derived' post-merge (AC-4, D5)"
assert_eq "${P1A_PAIR_S2T[kb:z-isolated.md#remarks|kb:concept:canonical]:-}" "$mention_rel" \
    "ORI07 the pair is HARVESTED section->concept, carrying the forward relation"
stored="${R0_PAIR[kb:concept:canonical|kb:z-isolated.md#remarks]:-}"
assert_nonempty "${#stored}" \
    "ORI08 the row IS stored flipped (its Source Id sorts after its Target Id, so D7 reverses it)"
assert_eq "$stored" "concept|section|${INVERSE[$mention_rel]}|${mention_rel}" \
    "ORI09 the two (Id, Kind, Name) TRIPLES swap WITH the two labels: the Kinds still match their own ids, and the harvested section->concept reading survives in T2S"

# The carry-over bug as a universal over EVERY stored row: a normalisation that
# moved ids and names but left the Kind cells behind would put a `concept` Kind on
# a `kb:<doc>#<slug>` id, on about half the rows.
assert_count_eq "$r0_kindmismatch" 0 \
    "ORI10 every stored row's Kind cells agree with their own id grammar (the normalisation moved TRIPLES, not cells)"

# A second flipped pair, from a different harvest kind and ACROSS id prefixes, so
# the property is not an artefact of one relation or of one prefix.
fact_stored=""
for pk in "${!R0_PAIR[@]}"; do
    [[ "$pk" == "int:src/tool.sh|kb:z-isolated.md#fact:"* ]] || continue
    v="${R0_PAIR[$pk]}"
    fact_stored="${v#*|*|}"
done
assert_eq "$fact_stored" "${INVERSE[$cae_rel]}|${cae_rel}" \
    "ORI11 the fact-anchor pair also flips (int: sorts before kb:) and its forward token survives in T2S"

sec MRG
assert_count_eq "$r0_dup" 0 "MRG01 no two frozen rows share a row key (AC-3)"

# The frozen set is in D7 order: class-major, then (sid, tid, s2t, t2s). The one
# `sort` here is the oracle, not an accessor -- it is the comparison being made.
sorted_ok=1
printf '%s\n' "${R0_SORTKEYS[@]}" > "$TMP/sortkeys.raw"
LC_ALL=C sort "$TMP/sortkeys.raw" -o "$TMP/sortkeys.sorted"
cmp -s "$TMP/sortkeys.raw" "$TMP/sortkeys.sorted" || sorted_ok=0
assert_true "$sorted_ok" "MRG02 the frozen rows are in LC_ALL=C sort-key order (D7)"

# --- the rendered artifact, read once ---
ART_LINES=(); ART_TEXT=""
if [[ -f "$ART" ]]; then
    mapfile -t ART_LINES < "$ART"
    ART_TEXT="$(<"$ART")"
fi

art_data=0; art_bad_arity=0; art_double_space=0; art_empty_obs=0
art_inferred_seen=0; art_inferred_then_not=0; art_timestamp=0
TS_RE='[0-9]{4}-[0-9]{2}-[0-9]{2}'
declare -A ART_COVKEY=() ART_KIND_COUNT=()
cov_section=""; cov_kind_rows=(); cov_excl_rows=()
for line in "${ART_LINES[@]}"; do
    [[ "$line" =~ $TS_RE ]] && art_timestamp=$((art_timestamp + 1))
    case "$line" in
        '### Node kinds'*)  cov_section="kinds"; continue ;;
        '### Enumeration'*) cov_section="excl";  continue ;;
    esac
    if [[ "$line" == '| int:'* || "$line" == '| kb:'* ]]; then
        art_data=$((art_data + 1))
        # A real cell split, not suffix arithmetic: `${line%' | '*}` would find the
        # WRONG boundary on any row whose Observation contains ` | `, and the
        # Provenance cell drives the class-contiguity check below.
        IFS='|' read -r -a cells <<< "$line"
        # `| a | ... | j |` splits into ELEVEN fields, not twelve: bash `read -a`
        # emits an empty field for the leading `|` but DROPS the one after the
        # trailing `|`. Writing 12 here (awk's NF convention) both mis-set the arity
        # check and pushed the Observation cell out of the double-space loop below,
        # which a helper smoke test caught before this suite ever ran.
        [[ "${#cells[@]}" -eq 11 ]] || art_bad_arity=$((art_bad_arity + 1))
        for (( ci = 1; ci <= 10 && ci < ${#cells[@]}; ci++ )); do
            [[ "${cells[$ci]}" == "  " ]] && art_double_space=$((art_double_space + 1))
        done
        # D1 fixes an empty cell at ONE space, so the tenth cell of a well-formed
        # empty Observation is exactly " ".
        [[ "${#cells[@]}" -eq 11 && "${cells[10]}" == " " ]] && art_empty_obs=$((art_empty_obs + 1))
        prov_cell="${cells[9]:-}"; prov_cell="${prov_cell# }"; prov_cell="${prov_cell% }"
        if [[ "$prov_cell" == "inferred" ]]; then
            art_inferred_seen=1
        elif [[ "$art_inferred_seen" -eq 1 ]]; then
            art_inferred_then_not=$((art_inferred_then_not + 1))
        fi
        continue
    fi
    if [[ "$cov_section" == "kinds" && "$line" == '| '[a-z]* ]]; then
        k="${line#| }"; k="${k%% |*}"
        # The row's LAST cell is its Nodes count (rendered order: key, note, status,
        # count); the same suffix-slice `${line% |}` / `${line##*| }` REN18 already
        # uses for the exclusions table's last cell, applied to this table's own.
        cnt_body="${line% |}"; cnt="${cnt_body##*| }"
        cov_kind_rows+=("$k"); ART_COVKEY["$k"]=1; ART_KIND_COUNT["$k"]="$cnt"
    elif [[ "$cov_section" == "excl" && "$line" == '| '* && "$line" != '| Exclusion '* ]]; then
        cov_excl_rows+=("$line")
    fi
done

assert_count_eq "$art_inferred_then_not" 0 "MRG03 class 0 is a contiguous prefix and class 1 a contiguous suffix (FR-32)"

# The four rejections, from run A's captured output.
assert_output_contains "$A_OUT" "endpoint id is in none of the three node streams" \
    "MRG04 rejection 1 fires: an endpoint outside the three node streams (D6 part 2, AC-S3)"
assert_output_contains "$A_OUT" "is not 'inferred'" \
    "MRG05 rejection 3 fires: a returned row not stamped inferred"
assert_output_contains "$A_OUT" "is not a member of the merged vocabulary" \
    "MRG06 rejection 4 fires: a relation label outside the merged vocabulary"
assert_output_contains "$A_OUT" "excludes 'inferred'" \
    "MRG07 rejection 4 fires: a relation whose passes excludes inferred"
assert_output_contains "$A_OUT" "endpoint_kinds excludes document->document" \
    "MRG08 rejection 4 fires on the KIND pair — a prefix pair could not tell these rows apart (Q21)"
assert_output_contains "$A_OUT" "collides with a frozen class-0 row" \
    "MRG09 rejection 2 fires: a class-1 key already in the frozen class-0 set (MUT03 proves this is not vacuous)"

# The rejections are not universal: three legal rows are accepted.
declare -A ACC_S2T=()
acc_n=0; acc_not_inferred=0
if [[ -f "$ACC" ]]; then
while IFS="$TAB" read -r cls sid skind sname tid tkind tname s2t t2s prov obs || [[ -n "${cls:-}" ]]; do
    [[ -n "${sid:-}" ]] || continue
    acc_n=$((acc_n + 1))
    ACC_S2T["$s2t"]=1
    [[ "$prov" == "inferred" ]] || acc_not_inferred=$((acc_not_inferred + 1))
done < "$ACC"
fi
assert_count_eq "$acc_n" 3 "MRG10 exactly the three legal class-1 rows are accepted"
assert_count_eq "$acc_not_inferred" 0 "MRG11 every accepted class-1 row is stamped inferred"
assert_key ACC_S2T "broader-than" "MRG12 an accepted row carries the relation it was typed with"
assert_key ACC_S2T "same-as"      "MRG13 the id-pair row is accepted, which is what discharges the pair candidate"

# ===========================================================================
# CMP -- the completion check (D6 part 4, FR-31a)
# ===========================================================================
sec CMP

assert_exit_eq "$A_RC" 0 "CMP04 a run whose every candidate is dispositioned exits 0"
assert_output_not_contains "$A_OUT" "undispositioned candidate" \
    "CMP05 no candidate is left undispositioned — BOTH arms of the union work (the pair candidate has no disposition row)"
assert_output_not_contains "$A_OUT" "unread manifest document" \
    "CMP06 no manifest document is reported unread when the ledger names each exactly once"

# ===========================================================================
# D2F -- the false-merge candidate report (AC-S7, AC-S7a)
# ===========================================================================
sec D2F

declare -A CMC_MDOC=()
cmc_fired=0; cmc_qualified=0
if [[ -f "$CMC" ]]; then
while IFS="$TAB" read -r cid odoc mdoc cobs || [[ -n "${cid:-}" ]]; do
    [[ -n "${cid:-}" ]] || continue
    CMC_MDOC["$mdoc"]=$(( ${CMC_MDOC[$mdoc]:-0} + 1 ))
    [[ "$cid" == "kb:concept:canonical" && "$odoc" == "domain-glossary.md" && "$mdoc" == "z-isolated.md" ]] \
        && cmc_fired=$((cmc_fired + 1))
    [[ "$cid" == *@* ]] && cmc_qualified=$((cmc_qualified + 1))
done < "$CMC"
fi

assert_count_eq "$cmc_fired" 1 "D2F01 the isolated mention IS reported (AC-S7's firing case; MUT02 proves it needs both readings)"
assert_count_eq "${CMC_MDOC[b-notes.md]:-0}" 0 \
    "D2F02 a mention whose document LINKS the defining document is not reported (condition 3)"
assert_count_eq "${CMC_MDOC[d-shared.md]:-0}" 0 \
    "D2F03 a mention whose document shares a SECOND concept is not reported (condition 4)"
assert_count_eq "$cmc_qualified" 0 "D2F04 a @<doc> qualified concept is never reported (condition 1: nothing was merged)"

# AC-S7a: all four reach counters are reported, and the arithmetic holds, so a zero
# candidate count is interpretable rather than ambiguous.
counters=""
if [[ -f "$TMP/runA.build" ]]; then
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *"pairs_1_3="* ]] && counters="$line"
done < "$TMP/runA.build"
fi
assert_nonempty "${#counters}" "D2F05 all four reach counters are reported on every run (AC-S7a)"
p13="${counters#*pairs_1_3=}"; p13="${p13%% *}"
filt="${counters#*filtered_by_shared_vocabulary=}"; filt="${filt%% *}"
skipd="${counters#*skipped_single_concept=}"; skipd="${skipd%% *}"
cand="${counters#*candidates=}"; cand="${cand%% *}"
assert_nonempty "${#skipd}" "D2F06 the skipped_single_concept counter is present, so a degenerate definer is auditable"
assert_count_eq "$cand" "$(( p13 - filt ))" \
    "D2F07 candidates = pairs_1_3 - filtered_by_shared_vocabulary (AC-S7a's arithmetic)"
assert_nonempty "$filt" \
    "D2F08 the condition-4 filter is NON-EMPTY on this fixture, so its reach loss is measured rather than assumed"

# Advisory throughout: reported at [LOW], counted in the coverage notes, gating
# nothing. D2F10 is what makes the finding durable rather than a passing log line.
assert_output_contains "$A_OUT" "[LOW]" "D2F09 candidates are reported at [LOW]"
assert_key COV_KEY "concept-merge-candidates" \
    "D2F10 the count reaches the coverage notes, so the advisory survives the run"

# ===========================================================================
# REN -- the rendered artifact (feature-003 D1, D7a, D7a-1, D8)
# ===========================================================================
sec REN

header='| Source Id | Source Kind | Source Name | Target Id | Target Kind | Target Name | S2T Relation | T2S Relation | Provenance | Observation |'
for probe in \
    "REN01 the header row is byte-exact D1's ten-column form${TAB}${header}" \
    "REN02 the delimiter row carries ten cells${TAB}|---|---|---|---|---|---|---|---|---|---|" \
    "REN03 D8's frontmatter names this generator${TAB}generator: build-relationships.sh" \
    "REN04 the AUTO-GENERATED marker is present${TAB}<!-- AUTO-GENERATED by aid/scripts/graph/build-relationships.sh" \
    "REN05 the H1 is present${TAB}# Relationships" \
    "REN06 the coverage-notes section follows the table (FR-9a, on every run)${TAB}## Coverage notes"
do
    lbl="${probe%%$TAB*}"; needle="${probe#*$TAB}"
    if [[ "$ART_TEXT" == *"$needle"* ]]; then pass "$lbl"; else fail "$lbl — not found in the artifact"; fi
done

# feature-010 D7, Open Item 7: build-relationships.sh no longer composes the
# `## Coverage notes` section -- it runs assemble-coverage-notes.sh and moves its
# bytes. This is the load-bearing proof: the section in the emitted artifact is
# byte-identical to the hand-off file the SAME run wrote at coverage-notes.md, not
# a second, possibly-diverging rendering of the same content.
if [[ -f "$TMP/coverage-notes.run1" ]]; then
    notes_expected="$(<"$TMP/coverage-notes.run1")"
    notes_rest="${ART_TEXT#*"## Coverage notes"}"
    notes_actual="## Coverage notes${notes_rest}"
    if [[ "$notes_actual" == "$notes_expected" ]]; then
        pass "REN06a the emitted '## Coverage notes' section is byte-identical to assemble-coverage-notes.sh's own hand-off file (feature-010 D7)"
    else
        fail "REN06a the emitted section diverges from the hand-off file -- build-relationships.sh is composing bytes of its own again"
    fi
else
    fail "REN06a — FIXTURE BUG: no coverage-notes.run1 snapshot was taken"
fi

assert_nonempty "$art_data" "REN07 the rendered table has data rows"
assert_count_eq "$art_bad_arity" 0 "REN08 every data row has exactly ten cells"
assert_count_eq "$art_double_space" 0 "REN09 no cell renders as two spaces (D1 fixes an empty cell at one)"
assert_nonempty "$art_empty_obs" \
    "REN10 a row's Observation renders as exactly ONE space, so REN09 tests a real empty cell (D1's well-formed-empty rule)"
assert_count_eq "$art_timestamp" 0 \
    "REN11 no timestamp appears anywhere in the artifact (FR-32 mechanism 6; INDEX.md embeds one and therefore churns)"

# AC-20: every Kind of the enum contributes a coverage row, zero-count included.
kinds_missing=0
for k in "${KIND_ENUM[@]}"; do
    [[ -n "${ART_COVKEY[$k]+set}" ]] || kinds_missing=$((kinds_missing + 1))
done
assert_nonempty "${#KIND_ENUM[@]}" "REN12 the Kind enum is non-empty"
assert_count_eq "$kinds_missing" 0 "REN13 every Kind of the enum has a coverage row, zero-count included (AC-20)"

# D7a-1: the extra rows form a contiguous block below the fixed ones, ordered
# LC_ALL=C by key -- across BOTH producer files. The interleave is the proof that
# the order is a function of the row set alone and not of the assembly order.
n_fixed="${#KIND_ENUM[@]}"
extras=()
for (( i = n_fixed; i < ${#cov_kind_rows[@]}; i++ )); do extras+=("${cov_kind_rows[$i]}"); done
assert_nonempty "${#extras[@]}" "REN14 the kinds table carries extra rows below the fixed ones"
extras_ok=1
if [[ "${#extras[@]}" -gt 0 ]]; then
    printf '%s\n' "${extras[@]}" > "$TMP/extras.raw"
    LC_ALL=C sort "$TMP/extras.raw" -o "$TMP/extras.sorted"
    cmp -s "$TMP/extras.raw" "$TMP/extras.sorted" || extras_ok=0
fi
assert_true "$extras_ok" "REN15 the extra rows are in LC_ALL=C ascending order by key (D7a-1)"
declare -A EXTRA_SET=()
for e in "${extras[@]}"; do EXTRA_SET["$e"]=1; done
if [[ -n "${EXTRA_SET[fact-unanchored]+s}" && -n "${EXTRA_SET[image-external]+s}" \
      && -n "${EXTRA_SET[section-empty-slug]+s}" ]]; then
    pass "REN16 rows from BOTH producer files appear INTERLEAVED by key (assembly order is unobservable)"
else
    fail "REN16 the two producer files' extra rows are not both present and interleaved: ${extras[*]}"
fi

# The three FR-22 exclusion rows, each carrying its Note. The Note is the cell a
# four-field reading of feature-004's five-field producer shape would leave empty.
assert_count_eq "${#cov_excl_rows[@]}" 3 "REN17 the three FR-22 exclusion rows are present"
excl_empty_note=0
for line in "${cov_excl_rows[@]}"; do
    body="${line% |}"; note="${body##*| }"
    [[ -n "$note" ]] || excl_empty_note=$((excl_empty_note + 1))
done
assert_count_eq "$excl_empty_note" 0 \
    "REN18 every exclusion row carries its Note (the five-field producer shape is read correctly)"

# --- REN19-24: the hand-off's three loud-failure branches (feature-010 D7, Open
# Item 7). "Nothing guarantees feature-010 ran first" is a real runtime state --
# an absent, failing, empty or truncated coverage-notes.md must abort the run with
# NOTHING written, never fall back to composing the section itself. Each shim
# below stands in for a differently-broken assembler; the real one is used
# everywhere else in this suite.
if [[ "$NEED_PIPELINE" -eq 1 ]]; then
    SHIM_EMPTY="$TMP/shim-empty.sh"
    cat > "$SHIM_EMPTY" <<'SHIMEOF'
#!/usr/bin/env bash
out=""
while [ $# -gt 0 ]; do
    case "$1" in --output) out="$2"; shift 2 ;; *) shift ;; esac
done
: > "$out"
exit 0
SHIMEOF
    SHIM_GARBAGE="$TMP/shim-garbage.sh"
    cat > "$SHIM_GARBAGE" <<'SHIMEOF'
#!/usr/bin/env bash
out=""
while [ $# -gt 0 ]; do
    case "$1" in --output) out="$2"; shift 2 ;; *) shift ;; esac
done
printf 'not a coverage section\n' > "$out"
exit 0
SHIMEOF

    # REN19-20: the assembler script itself is absent.
    rm -f "$TMP/hand.missing.md"
    HAND_RC="$(run_build "$TMP/hand.missing.build" "$TMP/hand.missing.md" "" "$TMP/no-such-assembler.sh")"
    HAND_OUT="$(<"$TMP/hand.missing.build")"
    assert_exit_eq "$HAND_RC" 2 "REN19 a missing assembler aborts with exit 2, not a silent self-render"
    assert_output_contains "$HAND_OUT" "assembler is not found" "REN19a and the reason is named"
    if [[ -f "$TMP/hand.missing.md" ]]; then
        fail "REN20 no artifact was written when the assembler is missing"
    else
        pass "REN20 no artifact was written when the assembler is missing"
    fi

    # REN21-22: the assembler ran and exited 0 but produced an EMPTY hand-off.
    rm -f "$TMP/hand.empty.md"
    HAND_RC="$(run_build "$TMP/hand.empty.build" "$TMP/hand.empty.md" "" "$SHIM_EMPTY")"
    HAND_OUT="$(<"$TMP/hand.empty.build")"
    assert_exit_eq "$HAND_RC" 2 "REN21 an empty hand-off aborts with exit 2, not a silent self-render"
    assert_output_contains "$HAND_OUT" "absent or empty" "REN21a and the reason is named"
    if [[ -f "$TMP/hand.empty.md" ]]; then
        fail "REN22 no artifact was written when the hand-off is empty"
    else
        pass "REN22 no artifact was written when the hand-off is empty"
    fi

    # REN23-24: the assembler ran and exited 0 but produced a TRUNCATED/malformed hand-off.
    rm -f "$TMP/hand.garbage.md"
    HAND_RC="$(run_build "$TMP/hand.garbage.build" "$TMP/hand.garbage.md" "" "$SHIM_GARBAGE")"
    HAND_OUT="$(<"$TMP/hand.garbage.build")"
    assert_exit_eq "$HAND_RC" 2 "REN23 a truncated/malformed hand-off aborts with exit 2, not a silent self-render"
    assert_output_contains "$HAND_OUT" "truncated or malformed" "REN23a and the reason is named"
    if [[ -f "$TMP/hand.garbage.md" ]]; then
        fail "REN24 no artifact was written when the hand-off is malformed"
    else
        pass "REN24 no artifact was written when the hand-off is malformed"
    fi
fi

# --- REN25-26: the fixed Kind rows carry the real NODES COUNT, not merely a
# row (feature-005 D7 / feature-010 D7a-1, task-009). REN13 proves every enum
# kind has A row; REN06a proves the emitted section is byte-identical to the
# file assemble-coverage-notes.sh itself wrote THIS run. Neither proves that
# file's own content is correct: a "plausible but stale" assembler -- one that
# renders a structurally perfect table carrying yesterday's numbers, or that
# silently swaps two rows' counts -- satisfies every REN assertion above it and
# is caught only here. MUT05 below is the demonstration: it hardcodes every
# Kind row's Nodes cell, passes REN01-24/REN13-18 in full, and fails only
# REN25/REN26.
#
# The four KB-side kinds never reach the artifact except through
# kb-coverage.tsv (this feature's own D7 contribution, read into COV_COUNT
# above) -- so comparing the RENDERED cell against that file's cell is a
# direct check of the one hop that matters here: did the hand-off preserve the
# number, end to end, rather than re-deriving or re-measuring it.
kbside_mismatch=0
for k in document section fact concept; do
    [[ "${ART_KIND_COUNT[$k]:-__art_missing__}" == "${COV_COUNT[$k]:-__cov_absent__}" ]] \
        || kbside_mismatch=$((kbside_mismatch + 1))
done
assert_count_eq "$kbside_mismatch" 0 \
    "REN25 the four KB-side Kind rows carry the exact Nodes count kb-coverage.tsv wrote this run — not stale, not swapped with a sibling row"

# The three source-side kinds never touch kb-coverage.tsv at all -- they are
# feature-004's OWN fixture numbers, fixed at coverage.tsv's construction
# above -- so this is also the one assertion proving the assembler's fixed
# block is fed from BOTH producer files and not only the one this script
# writes; REN16 already proves as much for the EXTRA rows, this closes the gap
# on the FIXED ones.
declare -A SRCSIDE_EXPECT=([source-artifact]=3 [image]=1 [web-page]=0)
srcside_mismatch=0
for k in "${!SRCSIDE_EXPECT[@]}"; do
    [[ "${ART_KIND_COUNT[$k]:-__art_missing__}" == "${SRCSIDE_EXPECT[$k]}" ]] \
        || srcside_mismatch=$((srcside_mismatch + 1))
done
assert_count_eq "$srcside_mismatch" 0 \
    "REN26 the three source-side Kind rows carry coverage.tsv's own fixture numbers, read from the OTHER producer file"

# ===========================================================================
# DET -- byte identity across two full pipeline runs (FR-32, AC-5)
# ===========================================================================
sec DET
#
# Run B repeats the WHOLE pipeline on byte-identical inputs. This is the second of
# the two full passes the COST MODEL accounts for, and the only way to check a
# property that is defined over two runs.

# The second full pass runs only when a group needs it. IDEM is included because
# it measures what the RE-RUN appended to the dispositions file.
DET_RAN=0
rc=0; B_RC=0
if want DET || want IDEM; then
    DET_RAN=1
    run_pass1 "$TMP/runB" || rc=$?
    B_RC="$(run_build "$TMP/runB.build" "$TMP/artifact.run2")"
fi
assert_exit_eq "$rc" 0 "DET01 the second full Pass 1 run exits 0"
assert_exit_eq "$B_RC" 0 "DET02 the second build exits 0 on the same inputs"

cmp -s "$TMP/artifact.run1" "$TMP/artifact.run2" \
    && pass "DET03 the WHOLE artifact is byte-identical across two full pipeline runs (AC-5, FR-32)" \
    || fail "DET03 the artifact differs between two runs over identical inputs"
cmp -s "$TMP/rows0.run1" "$ROWS0" \
    && pass "DET04 the frozen class-0 row set is byte-identical across two runs (AC-5, extraction 1)" \
    || fail "DET04 the frozen class-0 row set differs between two runs"
cmp -s "$TMP/cov.run1" "$COV" \
    && pass "DET05 this feature's coverage contribution is byte-identical across two runs (AC-5, extraction 2)" \
    || fail "DET05 the coverage contribution differs between two runs"

# The W3 report depends on the map and the vocabulary alone, never on a generated
# table, so it too must be byte-stable. This is the ONE legitimate second call to a
# 47 s function: byte stability is a property of two computations.
if [[ "$DET_RAN" -eq 1 && "$W3_COMPUTED" -eq 1 ]]; then
    erm_w3_rows > "$TMP/w3.run2"
    cmp -s "$TMP/w3.run1" "$TMP/w3.run2" \
        && pass "DET06 the W3 report is byte-identical across two computations" \
        || fail "DET06 the W3 report differs between two computations"
fi

# IDEM -- run B re-applied every rejection against the dispositions file run A had
# already appended to. A blind append would have doubled each rejection row, so two
# runs on identical inputs would leave different bytes behind.
declare -A DISP_SEEN=()
disp_dup=0; disp_rejections=0
if [[ -f "$DISP" ]]; then
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    if [[ -n "${DISP_SEEN[$line]+set}" ]]; then disp_dup=$((disp_dup + 1)); fi
    DISP_SEEN["$line"]=1
    [[ "$line" == *"${TAB}rejected: "* ]] && disp_rejections=$((disp_rejections + 1))
done < "$DISP"
fi
sec IDEM
assert_count_eq "$disp_dup" 0 "IDEM01 a re-run appends no duplicate disposition row (br_reject is idempotent)"
assert_nonempty "$disp_rejections" "IDEM02 rejection rows WERE appended, so IDEM01 is not measuring an empty file"

# ===========================================================================
# CMP, continued -- the two remaining outcomes, each needing its own build run
# ===========================================================================
sec CMP

# The degradation case: an ABSENT read ledger means Pass 2 was never dispatched,
# which is a recorded TOTAL outcome and not a shortfall.
G_RC=0; G_OUT="Pass 2 was not dispatched"; S_RC=1; S_OUT="undispositioned candidate"
T_RC=1; T_OUT="read-ledger entries: 2"
if want CMP; then
mv "$GT/pass2-reads.tsv" "$TMP/reads.keep"
G_RC="$(run_build "$TMP/runG.build" "$TMP/runG.md")"
G_OUT="$(<"$TMP/runG.build")"
assert_output_contains "$G_OUT" "Pass 2 was not dispatched" \
    "CMP07 an absent read ledger is reported as the degradation case, not as an unread shortfall"
assert_exit_eq "$G_RC" 0 "CMP08 the degradation case exits 0 (graceful degradation is a total outcome)"
mv "$TMP/reads.keep" "$GT/pass2-reads.tsv"

# The shortfall: remove every disposition and the run must exit 1, NAME each item,
# and still write the artifact.
mv "$DISP" "$TMP/dispositions.shortfall"
S_RC="$(run_build "$TMP/runS.build" "$TMP/runS.md")"
S_OUT="$(<"$TMP/runS.build")"

# FR-31a part 1's "at most once" bound, tested at the point that would fail if it
# were DROPPED: a document entered TWICE in the read ledger is exactly what a
# re-dispatched or batched Pass 2 would produce, and D6 part 4's count check --
# `[ "$count" = "1" ]`, never `-ge 1` -- is what catches it. Dispositions are
# restored first, so this run isolates the read-ledger failure from CMP09's
# undispositioned-candidate one rather than compounding both under one exit code.
mv "$TMP/dispositions.shortfall" "$DISP"
cp "$GT/pass2-reads.tsv" "$TMP/reads.single"
{ cat "$GT/pass2-reads.tsv"; head -n 1 "$GT/pass2-reads.tsv"; } > "$TMP/reads.dup"
cp "$TMP/reads.dup" "$GT/pass2-reads.tsv"
T_RC="$(run_build "$TMP/runT.build" "$TMP/runT.md")"
T_OUT="$(<"$TMP/runT.build")"
cp "$TMP/reads.single" "$GT/pass2-reads.tsv"
fi
assert_exit_eq "$S_RC" 1 "CMP09 an undispositioned candidate exits 1 (FR-31a part 4: not a silent omission)"
assert_output_contains "$S_OUT" "undispositioned candidate" "CMP10 the shortfall NAMES each undispositioned item"
assert_file_exists "$TMP/runS.md" "CMP11 the artifact is still written when the completion check fails"
assert_exit_eq "$T_RC" 1 \
    "CMP12 a manifest document read TWICE fails the completion check (FR-31a part 1's at-most-once bound, made mechanical by D6 part 4)"
assert_output_contains "$T_OUT" "unread manifest document" \
    "CMP13 the duplicate read is reported through the 'unread' channel (D6 part 4 defines unread as count != 1, not count == 0)"
assert_output_contains "$T_OUT" "read-ledger entries: 2" \
    "CMP14 the report names the actual entry count, so a reader can tell a double-read from an absence"

# ===========================================================================
# V11 -- a routed cross-feature defect. SKIPPED LOUDLY, never encoded.
# ===========================================================================
sec V11
#
# An `illustrated-by` row derived from feature-004's `image-reference` observation
# carries that observation's evidence verbatim (feature-005 Feature Flow step 10),
# and that string LEADS WITH THE IMAGE PATH. feature-003 D6/V11's durable-anchor
# predicate requires the first whitespace-delimited token to match the Citation
# Rule's extension set, and REL_CITE_EXTENSIONS carries twelve source extensions
# and no image extension -- so every such row fails V11 at [HIGH].
#
# UNRESOLVED and ROUTED. It is not asserted as required behaviour in either
# direction: the check below is skipped while the defect stands, and becomes live
# the moment either fix lands.
v11_admits_images=0
for e in "${IMG_EXT[@]}"; do
    case " $cite_ext " in *" $e "*) v11_admits_images=1 ;; esac
done
if [[ "$v11_admits_images" -eq 1 ]]; then
    ill_obs=""
    if [[ -f "$P1B" ]]; then
    while IFS="$TAB" read -r cls sid skind sname tid tkind tname s2t t2s prov obs || [[ -n "${cls:-}" ]]; do
        [[ "${s2t:-}" == "$ill_rel" ]] || continue
        ill_obs="${obs:-}"; break
    done < "$P1B"
    fi
    tok="${ill_obs%% *}"
    if [[ "$tok" =~ $EXT_RE ]]; then
        pass "V1101 an illustrated-by row's Observation is a durable anchor under V11"
    else
        fail "V1101 an illustrated-by row's Observation is not a durable anchor under V11"
    fi
else
    skip "V1101 illustrated-by rows vs V11's durable-anchor predicate — ROUTED DEFECT, deliberately NOT encoded here. REL_CITE_EXTENSIONS ('${cite_ext}') admits no image extension, while the schema carries image_extensions ('${IMG_EXT[*]}'), so an illustrated-by row derived from an image-reference observation leads its Observation with an image path and fails V11 at [HIGH]. Which clause needs the ruling: feature-003 D6/V11's extension set, or feature-004 template 13's leading token. OWNER: feature-003 or feature-004. This check goes live automatically once either lands."
fi

# What is assertable regardless of that ruling: every class-0 row THIS feature
# authors itself (Pass 1a) leads its Observation with a repo-relative path, so V11
# holds by construction on the rows feature-005 writes rather than carries.
assert_count_eq "$p1a_bad_anchor" 0 \
    "V1102 every Pass 1a row's Observation leads with a durable-anchor path (Feature Flow step 9; V11 by construction)"

# ===========================================================================
# BSH -- four bash traps this pipeline shipped and had to fix
# ===========================================================================
sec BSH
#
# Each is a REGRESSION scan over all four scripts, paired with a synthetic
# demonstration that the hazard is real on this bash -- so no scan guards a rule
# that cannot be broken, and no assertion is a tautology.
#
# All four scans, plus R8's, are computed by ONE awk per file (four forks total,
# not twenty): the naive one-awk-per-scan-per-label form spent 23 s of process
# spawns for exactly the same five numbers.

# BSH01a -- `local a="$1" b="$a"`. bash declares every name in a `local` statement
# BEFORE performing the assignments, so `b` reads an UNSET local.
demo_trap() { local x="$1" y="$x"; printf '%s' "$y"; }
demo_out="$( demo_trap hello 2>/dev/null || true )"
if [[ "$demo_out" == "hello" ]]; then
    fail "BSH01a the same-statement local hazard did NOT reproduce on this bash — BSH01b guards nothing here"
else
    pass "BSH01a the same-statement local hazard is real on this bash (a self-reference yields an unset local)"
fi

# BSH02a -- `. "$lib"` inside a FUNCTION makes the sourced file's `declare`
# statements function-local, so the library's loaded state vanishes on return.
#
# The probe is `declare -p`, not a subscript. `${DEMO_MAP[key]:-}` would look safe
# and is not: with DEMO_MAP absent, bash treats it as an INDEXED array and
# evaluates `key` ARITHMETICALLY, so a bare word there is read as a variable name
# and `set -u` aborts the whole suite on it. That is a second bash trap, and the
# first draft of this very block tripped it.
printf 'declare -A DEMO_MAP=()\nDEMO_MAP[demokey]=v\n' > "$TMP/demolib.sh"
demo_src_in_fn() { . "$TMP/demolib.sh"; }
demo_src_in_fn
if declare -p DEMO_MAP >/dev/null 2>&1; then
    fail "BSH02a sourcing inside a function did not localise declare — BSH02b/c guard nothing here"
else
    pass "BSH02a sourcing inside a function DOES scope its declare statements locally (the hazard is real)"
fi

# The label list R8 scans for, written once.
printf '%s\n' "${VOCAB_RELATIONS[@]}" > "$TMP/labels.txt"

selfref=0; nested_source=0; toplevel_source=0; unsorted_walk=0; bare_sort=0; hardcoded=0
report_guarded_source=0
for f in "${SUBJECT_ORDER[@]}"; do
    # One awk, five counts. Comments are stripped FIRST, before every scan: these
    # files' own headers quote the very hazards being scanned for (harvest-declared.sh
    # documents the `local a="$1" b="$a"` trap in prose), so a scan that counted
    # comments would fail a clean file for describing its own fix.
    IFS=' ' read -r c_selfref c_indented c_top c_walk c_sort c_hard <<< "$(
        awk -v labels="$TMP/labels.txt" -v sq="'" '
            BEGIN { while ((getline l < labels) > 0) if (l != "") L[++n] = l }
            /^[ \t]*#/ { next }
            { line = $0; sub(/[ \t]#.*/, "", line) }
            # -- BSH01b: a local statement referencing a name it declares itself --
            line ~ /^[ \t]*local / {
                s = line; sub(/^[ \t]*local[ \t]+/, "", s); nn = 0
                while (match(s, /[A-Za-z_][A-Za-z0-9_]*=/)) {
                    nm = substr(s, RSTART, RLENGTH - 1); nn++; names[nn] = nm
                    rest = substr(s, RSTART + RLENGTH)
                    for (i = 1; i < nn; i++)
                        if (rest ~ ("[$]" names[i] "([^A-Za-z0-9_]|$)") || rest ~ ("[$][{]" names[i] "[}:]")) { selfref++; break }
                    s = rest
                }
                delete names
            }
            # -- BSH02b/c/e: where the library is sourced. Indentation is the proxy;
            #    see the note under BSH02b for the one legitimate indented case.
            line ~ /^[ \t]+\. "\$GRAPH_LIB"/ { indented++ }
            line ~ /^\. "\$GRAPH_LIB"/       { top++ }
            # -- BSH03: an unordered walk of an associative array --
            line ~ /for [A-Za-z_]+ in "?\$\{!/ { if (line !~ /sort/) walk++ }
            # -- BSH04: a sort without LC_ALL=C --
            line ~ /[^A-Za-z_-]sort( |$)/ { if (line !~ /LC_ALL=C/) bsort++ }
            # -- R8: a relation label as a quoted literal --
            {
                for (i = 1; i <= n; i++)
                    if (line ~ ("[\"" sq "]" L[i] "[\"" sq "]")) hits[L[i]] = 1
            }
            END { h = 0; for (x in hits) h++
                  printf "%d %d %d %d %d %d\n", selfref + 0, indented + 0, top + 0, walk + 0, bsort + 0, h }
        ' "$f"
    )"
    selfref=$((selfref + c_selfref))
    unsorted_walk=$((unsorted_walk + c_walk))
    bare_sort=$((bare_sort + c_sort))
    hardcoded=$((hardcoded + c_hard))
    if [[ "$f" == "$REPORT" ]]; then
        # The report script sources the library INSIDE its `BASH_SOURCE = $0` guard,
        # which is an `if` block at top level -- and an `if` block is not a scope, so
        # its `declare` statements stay global. That is the one legitimate indented
        # source in this feature, and it is asserted rather than silently excused.
        report_guarded_source="$c_indented"
    else
        nested_source=$((nested_source + c_indented))
        if [[ "$c_top" -ge 1 ]]; then
            toplevel_source=$((toplevel_source + 1))
            pass "BSH02c ${f##*/} sources the library at TOP LEVEL, so its declares stay global"
        else
            fail "BSH02c ${f##*/} does not source the library at top level (column 0)"
        fi
    fi
done

assert_count_eq "$selfref" 0 "BSH01b no 'local' statement references a name it declares in the SAME statement"
assert_count_eq "$nested_source" 0 "BSH02b no ENTRY POINT sources the library from an indented position (the function-scope hazard)"
assert_count_eq "$toplevel_source" 3 "BSH02d all three entry points source the library, so BSH02b is not vacuous"
assert_count_eq "$report_guarded_source" 1 \
    "BSH02e the report script's ONE indented source sits in its top-level exec guard, not in a function (an if block is not a scope)"
assert_count_eq "$unsorted_walk" 0 \
    "BSH03 no script iterates an associative array's keys without an explicit sort (row order must not depend on hash order)"
assert_count_eq "$bare_sort" 0 "BSH04 every sort is LC_ALL=C (FR-32 mechanism 5)"
assert_nonempty "${#VOCAB_RELATIONS[@]}" "BSH05 the R8 scan runs over a non-empty label set"
assert_count_eq "$hardcoded" 0 "BSH06 / R8 no relation label appears as a quoted literal in any of the four scripts"

# ===========================================================================
# HLP -- every documented flag is parsed, and every parsed flag is READ
# ===========================================================================
sec HLP
#
# Per file: one `--help`, one unknown-flag run, and ONE awk that both lists the
# parser's arms and counts every arm variable's reads. The naive form spent four
# processes per flag across 31 flags.

for f in "${SUBJECT_ORDER[@]}"; do
    b="${f##*/}"
    rc=0; help_out="$(bash "$f" --help 2>/dev/null)" || rc=$?
    assert_exit_eq "$rc" 0 "HLP01 $b --help exits 0"
    case $'\n'"$help_out" in
        *$'\n''set -'*|*$'\n''#!/'*) fail "HLP02 $b --help leaks shell source" ;;
        *) pass "HLP02 $b --help leaks no shell source" ;;
    esac
    rc=0; bash "$f" --bogus >/dev/null 2>&1 || rc=$?
    assert_exit_eq "$rc" 2 "HLP03 $b rejects an unknown flag with exit 2"

    # `<flag> <var> <reads>` per parser arm. A flag that is parsed, defaulted and
    # then never used for resolution is a --help that lies.
    # TWO passes inside ONE awk. Counting reads on the fly as the arms are
    # discovered misses every read that occurs EARLIER in the file than the parser
    # -- which is most of them in a script whose `--help` text and helper functions
    # sit above `*_parse_args`. That produced two false "never read" reports on
    # build-relationships.sh, so the whole file is buffered and scanned in END.
    mapfile -t arms < <(awk '
        { L[NR] = $0 }
        /^[ \t]+--[a-z-]+\)[ \t]+[A-Za-z_]+=/ {
            line = $0
            match(line, /--[a-z-]+/);   flag = substr(line, RSTART, RLENGTH)
            rest = substr(line, RSTART + RLENGTH)
            match(rest, /[A-Za-z_]+=/); var  = substr(rest, RSTART, RLENGTH - 1)
            FLAG[++k] = flag; VAR[k] = var; ARM[NR] = k
        }
        END {
            for (i = 1; i <= k; i++)
                for (j = 1; j <= NR; j++) {
                    # The arm line itself is an ASSIGNMENT, never a read.
                    if (ARM[j] == i) continue
                    if (L[j] ~ ("[$]" VAR[i] "([^A-Za-z0-9_]|$)") || L[j] ~ ("[$][{]" VAR[i] "[}:[]")) READS[i]++
                }
            for (i = 1; i <= k; i++) printf "%s %s %d\n", FLAG[i], VAR[i], READS[i] + 0
        }
    ' "$f")

    undoc=0; unread=0; nflags=0
    for arm in "${arms[@]}"; do
        [[ -n "$arm" ]] || continue
        flag="${arm%% *}"; rest="${arm#* }"; var="${rest%% *}"; reads="${rest##* }"
        nflags=$((nflags + 1))
        case $'\n'"$help_out" in
            *$'\n'"  ${flag} "*|*$'\n'"  ${flag},"*|*$'\n'"  ${flag}"$'\n'*) ;;
            *) undoc=$((undoc + 1)); log "  $b: undocumented flag $flag" ;;
        esac
        # The arm's own assignment (`VAR="${2:-}"`) is not a READ, so a variable used
        # nowhere else scores zero here.
        [[ "$reads" -ge 1 ]] || { unread=$((unread + 1)); log "  $b: $flag sets $var, which is never read"; }
    done
    assert_nonempty "$nflags" "HLP04 $b declares at least one flag, so the flag universals are not vacuous"
    assert_count_eq "$undoc"  0 "HLP05 $b documents every flag its parser accepts"
    assert_count_eq "$unread" 0 "HLP06 $b READS every flag's variable (no flag is parsed and then ignored)"
done

# ===========================================================================
# MUT -- the mutation matrix. `--self-mutate` only.
# ===========================================================================
sec MUT

if [[ "$MODE" == "mutate" && "$NEED_PIPELINE" -eq 1 ]]; then

MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"

# Stage a mutant directory. The SIBLING COPY is not optional: each entry point
# sources `report-endpoint-satisfiability.sh` from its OWN directory with no flag
# to override, so a mutant dir without it dies on its first statement. The first
# version of this section omitted the copy, every mutant died before running, and
# one mutant assertion PASSED anyway -- the "silence" it asserted was the silence
# of a dead process. That is why every mutant below must first prove it RAN.
stage_mutant() {
    local dir="$1"
    mkdir -p "$dir"
    cp "$REPORT" "$dir/report-endpoint-satisfiability.sh"
}

# The guard that closes the false-PASS shape above: a mutant's output means nothing
# unless the mutant reached its own summary line.
mutant_completed() {
    local log="$1" label="$2" text
    text="$(<"$log")"
    if [[ "$text" == *'[relationships]'* ]]; then
        pass "$label"
    else
        fail "$label — the mutant never reached its summary line, so any assertion about its output would be measuring a DEAD RUN: ${text//$NL/ }"
    fi
}

# The second guard: step 13 must have been entered, or a "no rejection reported"
# assertion is satisfied by a mutant that never got that far.
mutant_reached_rejections() {
    local log="$1" label="$2" text
    text="$(<"$log")"
    if [[ "$text" == *'class-1 row rejected'* ]]; then
        pass "$label"
    else
        fail "$label — the mutant reported no rejection at all, so step 13 was never entered"
    fi
}

tree_unchanged() {
    local label="$1" now
    now="$(cat "${SUBJECT_ORDER[@]}" | md5sum)"
    if [[ "$now" == "$BASE_DIGEST" ]]; then pass "$label"; else fail "$label — a subject changed on disk"; fi
}

# --- MUT01: the orientation transpose, removed. In process, so it costs nothing.
#
# The mutant registers only the FORWARD reading of each map entry. Every inverse
# entry's token then looks unproduced -- precisely the false advisory a
# stored-orientation accumulator produces on half of every asymmetric pair.
mkdir -p "$MUTDIR/m1"
if mutate "MUT01" "$REPORT" "$MUTDIR/m1/report.sh" \
    '            if [ -n "$inverse" ]; then
                key="${inverse}${ERM_US}${dst}->${src}"
                producers["$key"]="${producers[$key]:-} $kind"
            fi' \
    '            : "$inverse"'; then
    (
        # shellcheck source=/dev/null
        source "$MUTDIR/m1/report.sh"
        load_edge_relation_map "$EDGE_MAP" >/dev/null 2>&1
        erm_w3_rows
    ) > "$TMP/mut1.tsv" 2>/dev/null
    mapfile -t M1_LINES < "$TMP/mut1.tsv"
    declare -A M1_MARK=()
    for line in "${M1_LINES[@]}"; do
        [[ -n "$line" ]] || continue
        IFS="$TAB" read -r wr wt wm _wp <<< "$line"
        M1_MARK["${wr}|${wt}"]="$wm"
    done
    assert_nonempty "${#M1_MARK[@]}" \
        "MUT01a the mutant still produced a report, so MUT01b measures a behaviour change and not a crash"
    m1_missing=0
    for k in "${!K_PAIRS[@]}"; do
        r="${K_RELATION[$k]}"; inv="${INVERSE[$r]:-}"
        for t in ${K_PAIRS[$k]}; do
            a="${t%%->*}"; b="${t#*->}"
            [[ "${M1_MARK[${inv}|${b}->${a}]:-}" == "producer" ]] || m1_missing=$((m1_missing + 1))
        done
    done
    assert_nonempty "$m1_missing" \
        "MUT01b removing the transpose makes inverse tokens look unproduced — ORI03 and ORI05 are NOT vacuous"
fi
tree_unchanged "MUT01z the shipped tree is byte-unchanged after MUT01"

# --- MUT02: D2f reads only the stored S2T.
#
# The crown-jewel mutant. On this fixture the mention row is STORED FLIPPED, so a
# detector reading only `s2t` never sees it and the firing case disappears.
cp "$TMP/rows-class1.keep" "$GT/rows-class1.tsv"
cp "$TMP/dispositions.keep" "$DISP"
stage_mutant "$MUTDIR/m2"
if mutate "MUT02" "$BUILD" "$MUTDIR/m2/build-relationships.sh" \
    '        elif [ "$t2s" = "$r_mention" ]; then
            cdoc=$(br_owner_doc "$tid" "$tkind"); cid="$sid"
        fi' \
    '        fi'; then
    M2_RC="$(run_build "$TMP/mut2.build" "$TMP/mut2.md" "$MUTDIR/m2/build-relationships.sh")"
    assert_exit_eq "$M2_RC" 0 "MUT02a the mutant build exits 0, so MUT02c measures a behaviour change and not a crash"
    mutant_completed "$TMP/mut2.build" "MUT02b the mutant RAN to its summary line, so its candidate list is its own and not a stale file"
    m2_fired=0
    while IFS="$TAB" read -r cid odoc mdoc _cobs || [[ -n "${cid:-}" ]]; do
        [[ "${cid:-}" == "kb:concept:canonical" && "${mdoc:-}" == "z-isolated.md" ]] && m2_fired=$((m2_fired + 1))
    done < "$CMC"
    assert_count_eq "$m2_fired" 0 \
        "MUT02c a D2f reading only the stored S2T MISSES the flipped mention row — D2F01 is NOT vacuous, and the both-readings rule is load-bearing"
fi
tree_unchanged "MUT02z the shipped tree is byte-unchanged after MUT02"

# --- MUT03: rejection 2 removed.
#
# A first implementation tested the collision AFTER the merge, where the shared
# de-duplication index had already absorbed the row: the check passed forever
# without ever firing. This mutant restores that shape.
cp "$TMP/rows-class1.keep" "$GT/rows-class1.tsv"
stage_mutant "$MUTDIR/m3"
if mutate "MUT03" "$BUILD" "$MUTDIR/m3/build-relationships.sh" \
    '        if [ -n "$key" ] && [ -n "${CLASS0_KEYS[$key]:-}" ]; then
            br_reject "row key collides with a frozen class-0 row" "$sid" "$tid"
            continue
        fi' \
    '        : "$key"'; then
    run_build "$TMP/mut3.build" "$TMP/mut3.md" "$MUTDIR/m3/build-relationships.sh" >/dev/null
    # Two positive controls before the silence, because "the message is absent" is
    # also true of a mutant that died on its first line and of one that never
    # entered step 13.
    mutant_completed "$TMP/mut3.build" "MUT03a the mutant RAN to its summary line"
    mutant_reached_rejections "$TMP/mut3.build" "MUT03b the mutant still reported its OTHER rejections, so step 13 was entered"
    m3_text="$(<"$TMP/mut3.build")"
    if [[ "$m3_text" == *'collides with a frozen class-0 row'* ]]; then
        fail "MUT03c removing rejection 2 still reported the collision — MRG09 does not depend on the check"
    else
        pass "MUT03c removing rejection 2 SILENCES the collision report while the other rejections still fire — MRG09 is NOT vacuous"
    fi
fi
tree_unchanged "MUT03z the shipped tree is byte-unchanged after MUT03"

# --- MUT04: the Q21 proxy -- rejection 4 keyed on the id PREFIX, not the Kind.
#
# This is the defect a sibling suite passed 294 assertions with: on a well-formed
# table every KB node id carries `kb:`, so the broken and the correct readings agree
# on every ordinary row and only a mutant separates them. It is caught here because
# the endpoint check then compares a PREFIX pair against a kind-keyed endpoint set,
# and matches nothing.
cp "$TMP/rows-class1.keep" "$GT/rows-class1.tsv"
stage_mutant "$MUTDIR/m4"
if mutate "MUT04" "$BUILD" "$MUTDIR/m4/build-relationships.sh" \
    '        skind="${NODE_KIND[$sid]}"
        tkind="${NODE_KIND[$tid]}"' \
    '        skind="${sid%%:*}"
        tkind="${tid%%:*}"'; then
    run_build "$TMP/mut4.build" "$TMP/mut4.md" "$MUTDIR/m4/build-relationships.sh" >/dev/null
    mutant_completed "$TMP/mut4.build" "MUT04a the mutant RAN to its summary line, so MUT04c reads its own accepted file"
    # The POSITIVE form, which a dead run could not produce: the endpoint check now
    # compares a PREFIX pair, and says so in its own rejection message.
    m4_text="$(<"$TMP/mut4.build")"
    if [[ "$m4_text" == *'endpoint_kinds excludes kb->kb'* || "$m4_text" == *'endpoint_kinds excludes int->int'* ]]; then
        pass "MUT04b the mutant's endpoint check compares a PREFIX pair (kb->kb / int->int), which the shipped one never does"
    else
        fail "MUT04b the mutant did not report a prefix-pair endpoint rejection — the mutation did not reach the endpoint check"
    fi
    m4_acc=0
    while IFS= read -r line || [[ -n "$line" ]]; do [[ -n "$line" ]] && m4_acc=$((m4_acc + 1)); done < "$ACC"
    assert_count_eq "$m4_acc" 0 \
        "MUT04c deriving the endpoint Kind from the id PREFIX rejects all three legal rows — MRG10/MRG12/MRG13 prove the Kind comes from the node record (Q21)"
fi
tree_unchanged "MUT04z the shipped tree is byte-unchanged after MUT04"

# --- MUT05: the coverage-notes hand-off, well-formed but WRONG (feature-010 D7,
# Open Item 7 / task-009). Every Kind row's Nodes cell is hardcoded to '999' --
# a section indistinguishable in SHAPE from a correct one, so REN01-24 and
# REN13-18 all stay green against it, and wrong in every number REN25/REN26
# exist to catch. This mutates a COPY of assemble-coverage-notes.sh, never
# build-relationships.sh: the REAL renderer is what MUT01-04 exercise, and this
# mutant proves the OTHER half of the hand-off -- the assembler's own output --
# is not merely trusted once it exists.
mkdir -p "$MUTDIR/m5"
if mutate "MUT05" "$ASSEMBLER" "$MUTDIR/m5/assemble-coverage-notes.sh" \
    '$3, $6, $4, $5 }' \
    '$3, $6, $4, "999" }'; then
    M5_RC="$(run_build "$TMP/mut5.build" "$TMP/mut5.md" "" "$MUTDIR/m5/assemble-coverage-notes.sh")"
    assert_exit_eq "$M5_RC" 0 "MUT05a the mutant build exits 0, so MUT05c measures a behaviour change and not a crash"
    m5_art="$(<"$TMP/mut5.md")"
    m5_doc_line=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == '| document | '* ]] && m5_doc_line="$line"
    done <<< "$m5_art"
    if [[ -n "$m5_doc_line" ]]; then
        pass "MUT05b the mutant RAN and rendered a 'document' Kind row, so MUT05c reads its own output and not a stale or dead one"
    else
        fail "MUT05b the mutant rendered no 'document' Kind row at all — MUT05c cannot measure anything"
    fi
    m5_cnt_body="${m5_doc_line% |}"; m5_cnt="${m5_cnt_body##*| }"
    if [[ "$m5_cnt" == "999" && "999" != "${COV_COUNT[document]:-}" ]]; then
        pass "MUT05c the mutant's 'document' row carries the hardcoded, WRONG Nodes count '999' inside an otherwise well-formed section — REN25 is NOT vacuous: it reads the count, not merely the row's presence"
    else
        fail "MUT05c the mutant's 'document' row count is '${m5_cnt}', not the injected '999' — the mutation did not reach the render"
    fi
fi
if [[ "$(<"$ASSEMBLER")" == "$ASSEMBLER_TEXT" ]]; then
    pass "MUT05z the shipped assemble-coverage-notes.sh is byte-unchanged after MUT05 (S5: mutate() wrote only to the copy)"
else
    fail "MUT05z assemble-coverage-notes.sh changed on disk after MUT05 — mutate() wrote to the source, not the copy"
fi

fi   # MODE == mutate

# ===========================================================================
# Summary
# ===========================================================================
# SELF01 -- the guard against the failure mode that produced
# "Tests passed: 0 ... All tests passed." A suite whose assertions all silently
# no-op is worse than a failing one, because it reports success. The floor is
# deliberately a large round number well under the real count, so it catches a
# wholesale no-op without becoming a count to maintain (test-landscape.md is stale
# about suite counts for exactly that reason -- a number nobody updates).
sec SELF
_ran=$(( PASS + FAIL ))
if [[ -n "$GROUP_FILTER" ]]; then
    _floor=1
else
    # 150 against a real default-mode count of 228 (and 247 with --self-mutate).
    # The gap is deliberate: this is a WHOLESALE-NO-OP detector, not an assertion
    # census, so adding or removing a few checks must never turn it red. Only a
    # collapse -- the filter misfiring, an early abort, a helper silently
    # short-circuiting -- can breach it.
    _floor=150
fi
CURRENT_GROUP="SELF"; GROUP_FILTER=""    # SELF always reports
if [[ "$_ran" -ge "$_floor" ]]; then
    pass "SELF01 $_ran assertions actually executed (no-op floor $_floor)"
else
    fail "SELF01 only $_ran assertions executed against a no-op floor of $_floor — the suite did not run what it claims to run"
fi

echo ""
if [[ "$SKIPPED" -gt 0 ]]; then
    echo "Skipped: $SKIPPED (each names the clause needing a ruling and its owner, above)"
fi
if [[ "$MODE" != "mutate" ]]; then
    echo "Mutation matrix not run. Use --self-mutate to run it (four extra build invocations)."
fi
test_summary
exit $?
