#!/usr/bin/env bash
# test-graph-runtime-digest.sh -- /aid-graph's staleness digest: one mutation per input,
# and the component each moves (feature-010 D2, work-005-knowledge-graph).
#
# ONE OF THREE SUITES -- see test-graph-runtime.sh's header for the split and the
# spawn-cost measurement behind it. This file owns the class that costs the most and is
# worth the most.
#
# WHY THIS CLASS IS THE ONE THAT MATTERS MOST
#   The digest is what makes a re-run a no-op and what makes a regeneration attributable.
#   Its correctness claim is that the six file sets are PAIRWISE DISJOINT -- mutate one
#   input and exactly one component moves. That claim cannot be checked by reading the code
#   and it cannot be checked on well-formed data: a digest that conflated two inputs would
#   agree with a correct one on every run where only one thing changed at a time and nobody
#   looked at WHICH component was named. Only mutation finds it.
#
#   So every component is mutated in turn, and every component with two arms is mutated on
#   BOTH arms:
#     kb     a Knowledge Base document
#     src    an enumerated source artifact, AND an enumerated in-repo image -- a `src`
#            term that omitted the media stream would pass the first and fail the second
#     ext    the external-sources registry
#     cfg    the settings file
#     vocab  the installed core vocabulary, AND a project extension added where none was
#     tool   an installed output-affecting file at an UNCHANGED version, AND the version
#            bumped with every installed file untouched -- an implementation carrying only
#            one of the two forms fails one of these
#   Each must yield STALE, name EXACTLY the mutated component, and leave the other five
#   component values byte-unchanged. Then three negatives: an excluded validator (added,
#   then edited) and the ceiling carrier decide a verdict or a warning rather than a byte,
#   so none of them may move the digest at all.
#
# SUBJECT INVOCATIONS: 15, and every one is a different input by construction --
#     2  the baseline: one run to read the digest, one to prove the baseline is CURRENT
#        (without that premise a later STALE would prove nothing, because the fixture
#        could have been STALE already)
#     9  the mutation matrix, one per arm
#     3  the negatives: the excluded validator added, then edited, and the ceiling edited
#     1  the closing run that proves every mutation was reverted
#   THE VERDICT ARMS ARE NOT REPEATED HERE. FIRST_RUN, CURRENT, determinism, the absent
#   stream, --reset and the view-out-of-scope arm are test-graph-runtime.sh's VA class;
#   duplicating them here would have cost seven more 8 s invocations to assert what a
#   sibling suite already asserts. What this file keeps is the ONE premise its matrix
#   depends on: the baseline is CURRENT before the first mutation.
#
#   The suite's own assertions are fork-free: the verdict output is parsed with `read`
#   builtins and parameter expansion, never with a per-assertion sed or awk. Measured on
#   this shell: 100 command substitutions 7.25 s, the same work in builtins 0.16 s.
#
#   BEFORE / AFTER this restructuring, same coverage of the matrix:
#     wall clock            203 s  ->  see the run log
#     subject invocations      21  ->  15   (seven verdict-arm duplicates handed to the
#                                           primary suite, one premise run kept)
#     mutation matrix     inline  ->  --self-mutate
#
# WHAT IS DELIBERATELY NOT HERE
#   The end-to-end pipeline chain and everything downstream of it (that is
#   test-graph-runtime-gate.sh). Every fixture is built under `mktemp -d` and the
#   enumerated streams are hand-written, so this class costs no pipeline run. No
#   `.aid/works/` path, no suite count, no ceiling figure.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
#   graph-stale-check.sh is the subject. kb-write-fence.sh is named because the `kb`
#   component excludes the run's own output by READING the fence's allowlist, so the fence
#   decides part of this digest. read-setting.sh and grade.sh are named because
#   make_install copies them into the fixture install, which is what the `tool` component
#   hashes.
# COVERS: canonical/aid/scripts/graph/graph-stale-check.sh
# COVERS: canonical/aid/scripts/graph/kb-write-fence.sh
# COVERS: canonical/aid/templates/graph/
# COVERS: canonical/aid/scripts/config/read-setting.sh
# COVERS: canonical/aid/scripts/grade.sh
# COVERS: tests/lib/assert.sh
# COVERS: tests/canonical/test-graph-runtime-digest.sh
#
# Usage:
#   bash test-graph-runtime-digest.sh [-v | --verbose]
#   bash test-graph-runtime-digest.sh --group DG      # one assertion group (DG or SF)
#   bash test-graph-runtime-digest.sh --self-mutate   # mutation-test THIS suite
#
#   --self-mutate copies the scripts into a mktemp dir, mutates the COPY by exact-string
#   replacement, and re-runs this suite against the copy requiring a non-zero exit. The
#   committed tree is never written, and every mutant re-digests it afterwards.
#
# Environment (the seam --self-mutate drives; unset in a normal run):
#   GRAPH_SCRIPTS_DIR  the scripts under test
#
# Exit codes:
#   0 -- all assertions passed (skips are reported, and never counted as passes)
#   1 -- one or more assertions failed

set -u

VERBOSE=0
MODE="assert"
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose)  VERBOSE=1; shift ;;
        --self-mutate) MODE="mutate"; shift ;;
        --group)       ONLY="${ONLY} ${2:?--group needs a group name}"; shift 2 ;;
        "")            shift ;;
        *) echo "test-graph-runtime-digest.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done
ONLY="${ONLY//,/ }"
want() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Absolute: this suite cd's into its fixtures, and a relative self-path would make every
# self-check read an absent file and report an empty count.
SELF_SRC="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

source "${SCRIPT_DIR}/../lib/assert.sh"

# A skip is NOT a pass. tests/lib/assert.sh has no notion of one, so this suite counts them
# separately and always lists them.
SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

GRAPH_SRC="${GRAPH_SCRIPTS_DIR:-${REPO_ROOT}/canonical/aid/scripts/graph}"
TPL_GRAPH="${REPO_ROOT}/canonical/aid/templates/graph"
CEILING_YML="${TPL_GRAPH}/scale-ceiling.yml"

MINE=(graph-preflight.sh graph-stale-check.sh kb-write-fence.sh grade-graph.sh
      assemble-coverage-notes.sh)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Fork-free helpers. Each returns through a named global: a `$(...)` capture forks, and at
# ~105-137 ms a spawn on this shell the capture costs more than everything it computes.
# ---------------------------------------------------------------------------

T=""; N=0; DIG=""; VER=""; CHG=""; COMP=""

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; T="${s%"${s##*[![:space:]]}"}"; }

ok_contains() {
    local hay="$1" ned="$2" label="$3"
    if [[ "$hay" == *"$ned"* ]]; then
        pass "$label"
    else
        fail "$label — pattern not found: '$ned'"
        [[ "$VERBOSE" -eq 1 ]] && { echo "---HAYSTACK---"; echo "$hay"; echo "---END---"; }
    fi
}

# A universal over an empty set is vacuously true -- a known false-PASS shape. Every
# universal below is preceded by one of these.
assert_nonempty() {
    local n="$1" label="$2"
    if [[ "${n:-0}" -gt 0 ]]; then
        pass "$label (n=$n)"
    else
        fail "$label — the set is EMPTY, so any universal claim over it would be vacuous"
    fi
}

digest_of() {
    local line
    DIG=""
    while IFS= read -r line; do
        if [[ "$line" == "graph_inputs_digest: "* ]]; then
            DIG="${line#graph_inputs_digest: }"
            return 0
        fi
    done <<< "$1"
}
verdict_of() {                     # the verdict is the LAST stdout line, by contract
    local line
    VER=""
    while IFS= read -r line; do VER="$line"; done <<< "$1"
}
changed_of() {
    local line pre="[stale-check] changed components:"
    CHG=""
    while IFS= read -r line; do
        if [[ "$line" == "$pre"* ]]; then
            trim "${line#"$pre"}"; CHG="$T"
            return 0
        fi
    done <<< "$1"
}
# One component's value out of the report: `  <name> = <value>`.
component_of() {
    local out="$1" name="$2" line rest
    COMP=""
    while IFS= read -r line; do
        [[ "$line" == "  ${name}"* ]] || continue
        rest="${line#  ${name}}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        [[ "${rest:0:1}" == "=" ]] || continue
        rest="${rest#=}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        COMP="$rest"
        return 0
    done <<< "$out"
}

# Scan this suite's own EXECUTABLE lines for a forbidden idiom, fork-free. Comment lines
# and the self-check class are skipped: an assertion whose label quotes the idiom it forbids
# is not an occurrence of it.
self_code_count() {
    local pat="$1" line n=0
    while IFS= read -r line; do
        trim "$line"
        [[ "${T:0:1}" == "#" ]] && continue
        [[ "$line" == *SF[0-9][0-9]* ]] && continue
        [[ "$line" == *self_code_count* ]] && continue
        [[ "$line" =~ $pat ]] && n=$((n + 1))
    done < "$SELF_SRC"
    N="$n"
}

# Build a self-contained fixture project. The template is built once (~1.1 s, mostly
# `git init`) and copied afterwards (~0.24 s).
PROJ_TEMPLATE="$TMP/_project-template"
build_project_template() {
    local d="$1" i
    mkdir -p "$d/.aid/knowledge" "$d/.aid/.temp/graph" "$d/src" "$d/docs/img"
    ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t )
    printf -- '---\nkb-category: meta\nkb_status: Approved\n---\n\n# Discovery State\n\n> **User Approved:** yes\n' \
        > "$d/.aid/knowledge/STATE.md"
    {
        printf -- '---\nkb-category: primary\nsource: hand-authored\n---\n\n# Module Map\n\n## Modules\n\n'
        for i in $(seq 1 40); do echo "Line $i of real module-map content."; done
    } > "$d/.aid/knowledge/module-map.md"
    echo '# external sources'                       > "$d/.aid/knowledge/external-sources.md"
    printf 'format_version: 3\nminimum_grade: B-\n' > "$d/.aid/settings.yml"
    printf '{\n  "aid_version": "9.9.9"\n}\n'       > "$d/.aid/.aid-manifest.json"
    echo 'export function main() { return 1; }'     > "$d/src/lib.js"
    printf 'PNGDATA'                                > "$d/docs/img/logo.png"
    # The enumerated streams STALE-CHECK consumes, hand-written so this class costs no
    # pipeline run. The media stream carries the image whose edit is the `src` second arm.
    printf 'int:src/lib.js\tlib.js\tscript\tnamed-unit\tsrc/lib.js\tdeclared\tsource-artifact\n' \
        > "$d/.aid/.temp/graph/nodes.tsv"
    {
        printf 'int:docs/img/logo.png\tlogo.png\timage\tdocs/img/logo.png\tdeclared\n'
        printf 'ext:example.com/spec\tspec\tweb-page\texternal-sources.md\tdeclared\n'
    } > "$d/.aid/.temp/graph/media-nodes.tsv"
}
make_project() {
    [[ -d "$PROJ_TEMPLATE" ]] || build_project_template "$PROJ_TEMPLATE"
    cp -r "$PROJ_TEMPLATE" "$1"
}

INST_TEMPLATE="$TMP/_install-template"
build_install_template() {
    local d="$1" f
    mkdir -p "$d/aid/scripts/graph" "$d/aid/templates/graph" \
             "$d/aid/templates/knowledge-graph" "$d/aid/scripts/config"
    for f in "${MINE[@]}"; do cp "${GRAPH_SRC}/${f}" "$d/aid/scripts/graph/"; done
    cp "${TPL_GRAPH}/relation-vocabulary.yml" "${TPL_GRAPH}/relationship-schema.yml" \
       "${CEILING_YML}" "$d/aid/templates/graph/"
    echo '<html></html>' > "$d/aid/templates/knowledge-graph/graph-skeleton.html"
    cp "${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh" "$d/aid/scripts/config/"
    cp "${REPO_ROOT}/canonical/aid/scripts/grade.sh" "$d/aid/scripts/"
}
make_install() {
    [[ -d "$INST_TEMPLATE" ]] || build_install_template "$INST_TEMPLATE"
    cp -r "$INST_TEMPLATE" "$1"
}

# Write the artifact frontmatter STALE-CHECK reads, carrying a given digest.
seed_artifact() {
    printf -- '---\nsource: generated\ngraph_inputs_digest: %s\ngraph_generated_at: 2026-01-01T00:00:00Z\n---\n\n# Relationships\n' \
        "$2" > "$1"
}

if [[ "$MODE" == "assert" ]]; then

# ===========================================================================
# === DG: graph-stale-check.sh -- the six digest components =================
# ===========================================================================

if want DG; then
echo ""
echo "=== DG: one mutation per digest component, and two per component with two arms ==="
echo "    (15 subject invocations: 2 baseline, 9 matrix arms, 3 negatives, 1 closing revert)"

INST="$TMP/install"; make_install "$INST"
SC="${INST}/aid/scripts/graph/graph-stale-check.sh"
DGP="$TMP/digest"; make_project "$DGP"
ART="$DGP/.aid/knowledge/relationships.md"
cd "$DGP"

# Baseline run 1: read the composite. The verdict arms themselves belong to the primary
# suite's VA class; what is asserted here is only what this matrix rests on.
OUT=$(bash "$SC" --install-root "$INST" 2>&1); RC=$?
assert_exit_zero "$RC" "DG01 [SR03] the baseline run exits 0 (a verdict is informational)"
digest_of "$OUT"; BASE_DIGEST="$DIG"
if [[ "$BASE_DIGEST" =~ ^kb=[0-9a-f]{64},src=[0-9a-f]{64},ext=[0-9a-f]{64},cfg=[0-9a-f]{64},vocab=[0-9a-f]{64},tool=[0-9a-f]{64}$ ]]; then
    pass "DG02 [FR-11] the composite is six name=<hex> pairs, comma-joined, in the inputs' own order"
else
    fail "DG02 [FR-11] the composite's shape is wrong: '$BASE_DIGEST'"
fi

# Baseline run 2: the premise the whole matrix depends on. Without it, a STALE after a
# mutation would prove nothing -- the fixture could have been STALE to begin with.
seed_artifact "$ART" "$BASE_DIGEST"
echo '<html>graph</html>' > "$DGP/.aid/knowledge/graph.html"
OUT=$(bash "$SC" --install-root "$INST" 2>&1)
verdict_of "$OUT"
assert_eq "$VER" "CURRENT" "DG03 PREMISE: the unmutated baseline is CURRENT, so every STALE below is caused by the mutation and not by the fixture"
changed_of "$OUT"
assert_eq "$CHG" "none" "DG04 PREMISE: and no component is reported changed at the baseline"

COMPONENTS=(kb src ext cfg vocab tool)
declare -A BASE_C=()
BAD_PARSE=0
for c in "${COMPONENTS[@]}"; do
    component_of "$OUT" "$c"
    BASE_C["$c"]="$COMP"
    [[ -n "$COMP" ]] || { BAD_PARSE=1; fail "DG05 the ${c} component value did not parse out of the report"; }
done
assert_nonempty "${#BASE_C[@]}" "DG05a all six component values were read from the baseline report"
[[ "$BAD_PARSE" -eq 0 ]] && pass "DG05 every one of the six baseline component values is non-empty — otherwise the disjointness comparison below would be comparing empty to empty"

# One mutation per component; two where a component has two arms. Each must yield STALE,
# must name EXACTLY the mutated component, and must leave the other five values byte-equal.
dg_mutation() {  # <label> <expected-component> <apply-cmd> <revert-cmd>
    local label="$1" want_c="$2" apply="$3" revert="$4"
    local out c others_ok=1
    eval "$apply"
    out=$(bash "$SC" --install-root "$INST" 2>&1)
    verdict_of "$out"; assert_eq "$VER" "STALE" "${label} yields STALE"
    changed_of "$out"; assert_eq "$CHG" "$want_c" "${label} names EXACTLY the ${want_c} component"
    for c in "${COMPONENTS[@]}"; do
        [[ "$c" == "$want_c" ]] && continue
        component_of "$out" "$c"
        if [[ "$COMP" != "${BASE_C[$c]}" ]]; then
            others_ok=0
            fail "${label} — component ${c} also moved, so the six file sets are not pairwise disjoint"
        fi
    done
    [[ "$others_ok" -eq 1 ]] && pass "${label} — the other five component values are byte-unchanged"
    eval "$revert"
}

dg_mutation "DG06 [SR04] kb: a Knowledge Base document edited" kb \
    "echo 'appended' >> '$DGP/.aid/knowledge/module-map.md'" \
    "sed -i '\$ d' '$DGP/.aid/knowledge/module-map.md'"
dg_mutation "DG07 [SR04] src arm 1: an enumerated source artifact edited" src \
    "echo '// edit' >> '$DGP/src/lib.js'" \
    "sed -i '\$ d' '$DGP/src/lib.js'"
dg_mutation "DG08 [SR04] src arm 2: an enumerated in-repo IMAGE edited (a src term omitting media-nodes.tsv fails here)" src \
    "printf 'PNGDATA2' > '$DGP/docs/img/logo.png'" \
    "printf 'PNGDATA' > '$DGP/docs/img/logo.png'"
dg_mutation "DG09 [SR04] ext: external-sources.md edited" ext \
    "echo '- one' >> '$DGP/.aid/knowledge/external-sources.md'" \
    "printf '# external sources\n' > '$DGP/.aid/knowledge/external-sources.md'"
dg_mutation "DG10 [SR04] cfg: .aid/settings.yml edited" cfg \
    "printf 'format_version: 3\nminimum_grade: A\n' > '$DGP/.aid/settings.yml'" \
    "printf 'format_version: 3\nminimum_grade: B-\n' > '$DGP/.aid/settings.yml'"
dg_mutation "DG11 [SR04] vocab arm 1: the installed core vocabulary edited" vocab \
    "echo '# tweak' >> '$INST/aid/templates/graph/relation-vocabulary.yml'" \
    "sed -i '\$ d' '$INST/aid/templates/graph/relation-vocabulary.yml'"
dg_mutation "DG12 [SR04] vocab arm 2: an EMPTY project extension added where none existed" vocab \
    "mkdir -p '$DGP/.aid/graph' && : > '$DGP/.aid/graph/relation-vocabulary.yml'" \
    "rm -rf '$DGP/.aid/graph'"
dg_mutation "DG13 [SR04] tool arm 1: an installed output-affecting file edited at an UNCHANGED version" tool \
    "echo '# tweak' >> '$INST/aid/scripts/graph/assemble-coverage-notes.sh'" \
    "sed -i '\$ d' '$INST/aid/scripts/graph/assemble-coverage-notes.sh'"
dg_mutation "DG14 [SR04] tool arm 2: aid_version bumped with every installed file untouched" tool \
    "printf '{\n  \"aid_version\": \"9.9.10\"\n}\n' > '$DGP/.aid/.aid-manifest.json'" \
    "printf '{\n  \"aid_version\": \"9.9.9\"\n}\n' > '$DGP/.aid/.aid-manifest.json'"

# Three negatives. An excluded file decides a verdict or a warning, never a byte.
mkdir -p "$INST/aid/scripts/graph"
if [[ -f "${GRAPH_SRC}/validate-relationships.sh" ]]; then
    cp "${GRAPH_SRC}/validate-relationships.sh" "$INST/aid/scripts/graph/"
else
    printf '#!/usr/bin/env bash\nexit 0\n' > "$INST/aid/scripts/graph/validate-relationships.sh"
fi
OUT=$(bash "$SC" --install-root "$INST" 2>&1)
verdict_of "$OUT"
assert_eq "$VER" "CURRENT" "DG15 [SR04] adding an EXCLUDED validator to the install does not move the digest"

dg_negative() {  # <label> <apply> <revert>
    local label="$1" out
    eval "$2"
    out=$(bash "$SC" --install-root "$INST" 2>&1)
    verdict_of "$out"; assert_eq "$VER" "CURRENT" "${label} leaves the verdict CURRENT"
    eval "$3"
}
dg_negative "DG16 [SR04] editing an excluded validator" \
    "echo '# tweak' >> '$INST/aid/scripts/graph/validate-relationships.sh'" \
    "sed -i '\$ d' '$INST/aid/scripts/graph/validate-relationships.sh'"
dg_negative "DG17 [SR04] editing scale-ceiling.yml, which decides a warning and not a byte" \
    "echo '# tweak' >> '$INST/aid/templates/graph/scale-ceiling.yml'" \
    "sed -i '\$ d' '$INST/aid/templates/graph/scale-ceiling.yml'"

OUT=$(bash "$SC" --install-root "$INST" 2>&1)
digest_of "$OUT"
assert_eq "$DIG" "$BASE_DIGEST" "DG18 every mutation was reverted — the digest is back at its baseline, so no arm above leaked into the next"

cd "$REPO_ROOT"
fi

# ===========================================================================
# === SF: this suite's own false-PASS controls ==============================
# ===========================================================================

if want SF; then
echo ""
echo "=== SF: the known false-PASS shapes, checked against this suite's own source ==="

self_code_count 'sed -i.*(REPO_ROOT|GRAPH_SRC|CEILING_YML)'
assert_eq "$N" "0" "SF01 no in-place edit of any committed path (every mutation and revert targets a copy under mktemp -d)"
self_code_count 'sed .*[0-9]+s/'
assert_eq "$N" "0" "SF02 no line-numbered sed substitution — line numbers shift and the edit silently misses"
self_code_count '\|\| echo 0'
assert_eq "$N" "0" "SF03 no 'grep -c ... || echo 0' idiom, which emits '0\n0' and compares as neither"
self_code_count 'assert_nonempty'
assert_nonempty "$N" "SF04 universals are guarded by an explicit non-emptiness assertion"
self_code_count '\.aid/works/'
assert_eq "$N" "0" "SF05 no .aid/works/ path — every fixture here is self-built"
self_code_count 'assert_(file|output)_(contains|not_contains)'
assert_eq "$N" "0" "SF06 no per-assertion grep: every containment check is the fork-free ok_contains"

# The COVERS manifest select-suites.sh reads. A WRONG entry is the only way this suite can
# silently stop being selected, so every entry must resolve on disk.
COVERS_N=0
BAD_COVER=0
while IFS= read -r line; do
    [[ "$line" == "# COVERS:"* ]] || continue
    trim "${line#\# COVERS:}"
    [[ -n "$T" ]] || continue
    COVERS_N=$((COVERS_N + 1))
    if [[ ! -e "${REPO_ROOT}/${T%/}" ]]; then
        BAD_COVER=1
        fail "SF07 a COVERS entry names a path that does not exist: ${T}"
    fi
done < "$SELF_SRC"
assert_nonempty "$COVERS_N" "SF07a the suite declares a COVERS manifest (a suite without one runs on every unrelated change)"
[[ "$BAD_COVER" -eq 0 ]] && pass "SF07 every COVERS entry resolves on disk"

cd "$REPO_ROOT"
fi

# ===========================================================================
echo ""
echo "=== Summary ==="
echo "  Tests passed:  $PASS"
echo "  Tests failed:  $FAIL"
echo "  Tests skipped: $SKIP"
if [[ "$SKIP" -gt 0 ]]; then
    echo ""
    echo "Skipped (a skip is never a pass):"
    for s in "${SKIPPED[@]}"; do echo "  - $s"; done
fi
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for e in "${ERRORS[@]}"; do echo "  - $e"; done
    exit 1
fi
echo ""
echo "All tests passed."
exit 0

# ===========================================================================
else   # MODE == mutate
# ===========================================================================

CANON_GRAPH="${REPO_ROOT}/canonical/aid/scripts/graph"
SELF="${BASH_SOURCE[0]}"

digest_src() { sha256sum "$CANON_GRAPH"/graph-stale-check.sh | awk '{ print $1 }' | tr '\n' ' '; }
BASE_SRC_DIGEST="$(digest_src)"

# Exact-string replacement. NO numeric line addresses: an address that shifts is a known
# false-PASS shape, so the anchor is the text itself. Aborts unless the anchor occurs
# EXACTLY once AND the write changed the file.
mutate_apply() {
    local file="$1" n
    # The anchor and the replacement are passed through the ENVIRONMENT, not through
    # `awk -v`. awk processes escape sequences in a -v assignment, so an anchor containing
    # a tab, a newline or an escaped pipe -- which several of the anchors below do -- would
    # arrive at awk as the CHARACTER that escape denotes and match nothing. The mutant would
    # then ABORT rather than run, and a mutation harness that quietly stops testing is worse
    # than none. ENVIRON[] is not escape-processed.
    export MUT_FROM="$2" MUT_TO="$3"
    n="$(awk 'BEGIN { s = ENVIRON["MUT_FROM"] } index($0, s) > 0 { c++ } END { print c + 0 }' "$file")"
    if [[ "$n" -ne 1 ]]; then
        echo "    ABORT: anchor occurs $n times (need exactly 1): ${MUT_FROM:0:60}" >&2
        return 1
    fi
    awk '
        BEGIN { s = ENVIRON["MUT_FROM"]; r = ENVIRON["MUT_TO"] }
        { p = index($0, s); if (p > 0) $0 = substr($0, 1, p - 1) r substr($0, p + length(s)); print }
    ' "$file" > "$file.mut" || return 1
    if cmp -s "$file" "$file.mut"; then
        echo "    ABORT: replacement changed nothing" >&2
        rm -f "$file.mut"; return 1
    fi
    mv -f "$file.mut" "$file"
}

MUT_TOTAL=0; MUT_KILLED=0; MUT_SURVIVED=0; MUT_ABORTED=0

run_mutant() {
    local name="$1" from="$2" to="$3"
    MUT_TOTAL=$((MUT_TOTAL + 1))
    local dir="$TMP/mut$MUT_TOTAL"
    mkdir -p "$dir"
    cp "$CANON_GRAPH"/*.sh "$dir/" 2>/dev/null
    echo "=== $name"
    if ! mutate_apply "$dir/graph-stale-check.sh" "$from" "$to"; then
        echo "    RESULT: ABORTED (anchor drifted -- the mutant proves nothing; fix the anchor)"
        MUT_ABORTED=$((MUT_ABORTED + 1)); return
    fi
    local out rc=0 flipped
    out="$(GRAPH_SCRIPTS_DIR="$dir" bash "$SELF" 2>&1)" || rc=$?
    flipped="$(printf '%s\n' "$out" | grep -cE '^  FAIL: ' || true)"
    if [[ "$rc" -ne 0 ]]; then
        echo "    RESULT: KILLED (suite exit $rc, $flipped assertion(s) flipped)"
        printf '%s\n' "$out" | grep -E '^  FAIL: ' | head -3 | sed 's/^/      /'
        MUT_KILLED=$((MUT_KILLED + 1))
    else
        echo "    RESULT: *** SURVIVED *** -- this defect is invisible to the suite"
        MUT_SURVIVED=$((MUT_SURVIVED + 1))
    fi
    if [[ "$(digest_src)" == "$BASE_SRC_DIGEST" ]]; then
        echo "    source tree: UNTOUCHED (digests match)"
    else
        echo "    source tree: *** MODIFIED *** -- aborting everything"
        exit 1
    fi
}

echo "=========================================================================="
echo " Mutation harness -- mutating COPIES under $TMP, never the tree"
echo " baseline digest: $BASE_SRC_DIGEST"
echo "=========================================================================="

# M1 is the mutant this suite exists for. The digest still MOVES when
# external-sources.md changes, so a suite that only asserted STALE would not notice --
# but the changed-component report can no longer name one input.
run_mutant "M1 the ext component collapsed onto kb (the components stop being disjoint)" \
    '    EXT_C=$(hash_one "$EXTERNAL_SOURCES") || die "cannot hash ${EXTERNAL_SOURCES}"' \
    '    EXT_C="$KB_C"'

# M2 is the reason `src` is mutated on two arms rather than one.
run_mutant "M2 the src component stops reading the media stream (images leave the digest)" \
    'cut -f1 "$NODES" "$MEDIA_NODES" 2>/dev/null \' \
    'cut -f1 "$NODES" 2>/dev/null \'

# M3 is the reason the vocab arm adds an EMPTY extension: with the absent marker and the
# present-but-empty record made identical, the digest cannot tell the two states apart.
run_mutant "M3 a present project vocabulary recorded exactly as an absent one" \
    '    PROJECT_VOCAB_HASH=$(hash_one "$PROJECT_VOCAB") || die "cannot hash ${PROJECT_VOCAB}"' \
    '    PROJECT_VOCAB_HASH="absent"'

# M4 is the reason `tool` is mutated on two arms: a file digest alone cannot see a version
# bump that changed no installed byte.
run_mutant "M4 the tool component drops the version string and keeps only the file digest" \
    'printf '"'"'aid_version\t%s\n'"'"' "$AID_VERSION" >> "$W/tool.stream"' \
    ': # mutant: the tool component ignores the version'

echo "=========================================================================="
echo " mutants: $MUT_TOTAL   killed: $MUT_KILLED   survived: $MUT_SURVIVED   aborted: $MUT_ABORTED"
echo " source tree after every mutant: $(digest_src)"
echo "=========================================================================="
if [[ "$MUT_SURVIVED" -gt 0 || "$MUT_ABORTED" -gt 0 || "$MUT_KILLED" -ne "$MUT_TOTAL" ]]; then
    echo "MUTATION TESTING FAILED"
    exit 1
fi
echo "All mutants killed."
exit 0

fi
