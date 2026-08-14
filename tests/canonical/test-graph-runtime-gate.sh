#!/usr/bin/env bash
# test-graph-runtime-gate.sh -- /aid-graph's pipeline chain and its coverage-notes assembly
# (feature-010, work-005-knowledge-graph).
#
# ONE OF FOUR SUITES, AND THE SPLIT IS BY MEASURED COST, NOT BY TOPIC.
#   run-all.sh kills a suite at 300 s. On the shell this work is authored on a process spawn
#   costs 105-137 ms against 3.4 ms for a bash builtin, so a script's wall time is set by
#   its spawn count and not by its input size: scan-source.sh takes ~10 s on a two-file
#   repo, assemble-coverage-notes.sh ~7 s, grade-graph.sh ~27 s over a failing table. This
#   file measured 290 s when it also held the grading class and was killed mid-class, so the
#   grading class now has its own file.
#     test-graph-runtime.sh         structure, preflight, the write fence, --help honesty,
#                                   the ceiling carrier, floor resolution, verdict arms
#     test-graph-runtime-digest.sh  the staleness digest's component matrix
#     test-graph-runtime-gate.sh    this file -- the chain and the assembly
#     test-graph-runtime-grade.sh   the FR-28 gate and the ledger's round trip
#
# WHAT THIS FILE COVERS
#
#   CH -- THE CHAIN, END TO END, over a fixture project built here from the committed tree:
#     graph-preflight.sh -> kb-write-fence.sh --snapshot -> scan-source.sh ->
#     harvest-declared.sh -> derive-edges.sh -> [the Pass-2 degradation] ->
#     build-relationships.sh -> validate-relationships.sh -> detect-kb-gaps.mjs ->
#     graph-stale-check.sh -> kb-write-fence.sh --verify
#   That chain was blocked when this runtime was built (harvest-declared.sh exited 2 on a
#   schema loader that did not yet publish its fence mask). It is not blocked now, and this
#   suite proves the whole of it rather than taking that on report.
#
#   THE PASS-2 DEGRADATION IS PART OF THE CHAIN, not an aside. With no dispositions the
#   emitter exits 1 on a completion shortfall and NAMES every undispositioned candidate;
#   writing a `pass-2-unavailable` disposition for each -- which is what
#   references/state-extract.md Step 5 instructs the orchestrator to do when Pass 2 cannot
#   be dispatched -- is what makes the chain exit 0. So the degradation is executable, and
#   this suite executes it in BOTH directions rather than asserting only the happy one.
#
#   AS -- THE COVERAGE-NOTES ASSEMBLY: the field reordering (the rendered column order is
#   not the contribution's), the exclusion-label translation, the `count` column dropped
#   from the exclusions table entirely, extra rows ordered by key ACROSS both producers,
#   order-independence and idempotence, and both assembly conflicts.
#
# SUBJECT INVOCATIONS: 18, and every one is a distinct input --
#     11  the chain, in order; two of them are build-relationships.sh, once WITHOUT
#         dispositions (the shortfall) and once WITH them (the degradation)
#      7  assemble-coverage-notes.sh: the good render, the swapped-argument render, the
#         repeat render that proves idempotence, and four refusals
#   The suite's own assertions are fork-free: outputs and artifacts are read once with
#   `read` builtins and compared with `[[ ]]`, and a claim about a COLUMN is made over
#   parsed cells rather than as substring presence anywhere in the file.
#
# WHAT IS DELIBERATELY NOT HERE
#   * RENDER. The view has no canvas module (deliberately unbuilt, pending research the
#     owner commissioned), so there is no assembly to invoke and the chain CANNOT produce a
#     page. CH27 asserts exactly that consequence -- with the view installed and no page
#     produced, the honest verdict is STALE -- rather than skipping the arm or pretending a
#     page exists.
#   * The FR-28 gate: test-graph-runtime-grade.sh.
#   * VISUAL-GATE, FIX and DONE as state machines: prompt-driven prose, covered by
#     dogfooding and human review. The scripts they drive are asserted.
#   * Any browser, any suite count, any ceiling figure, any `.aid/works/` path.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
#   The whole graph script directory is claimed, without narrowing, because the chain
#   executes ELEVEN of its scripts in order and a change to any of them can break it.
#   Over-selecting costs time; under-selecting loses coverage, and this is the one suite
#   whose subject really is the whole directory.
# COVERS: canonical/aid/scripts/graph/
# COVERS: canonical/aid/templates/graph/
# COVERS: canonical/skills/aid-graph/references/state-extract.md
# COVERS: canonical/aid/scripts/config/read-setting.sh
# COVERS: canonical/aid/scripts/grade.sh
# COVERS: tests/lib/assert.sh
# COVERS: tests/canonical/test-graph-runtime-gate.sh
#
# Usage:
#   bash test-graph-runtime-gate.sh [-v | --verbose]
#   bash test-graph-runtime-gate.sh --group AS         # one group: CH, AS or SF
#   bash test-graph-runtime-gate.sh --self-mutate      # mutation-test THIS suite
#
#   --group runs one class and the fixtures it needs, so a one-line fix is verified against
#   the group that covers it rather than against the whole file.
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
        *) echo "test-graph-runtime-gate.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done
ONLY="${ONLY//,/ }"
want() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SELF_SRC="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

source "${SCRIPT_DIR}/../lib/assert.sh"

SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

GRAPH_SRC="${GRAPH_SCRIPTS_DIR:-${REPO_ROOT}/canonical/aid/scripts/graph}"
TPL_GRAPH="${REPO_ROOT}/canonical/aid/templates/graph"
SKILL_REFS="${REPO_ROOT}/canonical/skills/aid-graph/references"
SCHEMA_YML="${TPL_GRAPH}/relationship-schema.yml"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

US=$(printf '\037')

# ---------------------------------------------------------------------------
# Fork-free helpers. Each returns through a named global.
# ---------------------------------------------------------------------------
T=""; N=0; DIG=""; VER=""

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; T="${s%"${s##*[![:space:]]}"}"; }

sub_count() {
    local hay="$1" ned="$2" n=0
    while [[ "$hay" == *"$ned"* ]]; do hay="${hay#*"$ned"}"; n=$((n + 1)); done
    N="$n"
}

ok_contains() {
    local hay="$1" ned="$2" label="$3"
    if [[ "$hay" == *"$ned"* ]]; then
        pass "$label"
    else
        fail "$label — pattern not found: '$ned'"
        [[ "$VERBOSE" -eq 1 ]] && { echo "---HAYSTACK---"; echo "$hay"; echo "---END---"; }
    fi
}
ok_not_contains() {
    local hay="$1" ned="$2" label="$3"
    if [[ "$hay" != *"$ned"* ]]; then
        pass "$label"
    else
        fail "$label — unexpected pattern found: '$ned'"
    fi
}

# A universal over an empty set is vacuously true -- a known false-PASS shape.
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
            DIG="${line#graph_inputs_digest: }"; return 0
        fi
    done <<< "$1"
}
verdict_of() {
    local line
    VER=""
    while IFS= read -r line; do VER="$line"; done <<< "$1"
}

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

# --- the reviewer ledger, parsed the way the rendered table reads -----------------
# Split on UNESCAPED pipes only: a cell is written with its pipes escaped, so `\|` is
# protected before the split and restored after. This mirrors the reader under test, which
# is the point -- a Severity read out of the wrong column is the defect being regressed.

# --- a rendered markdown table's rows, as cell arrays ----------------------------
# Used by the AS class so a claim about a COLUMN is made over that column, never as
# substring presence anywhere in the file.
declare -a TBL_ROWS=()
table_rows() {                 # table_rows <text> <header-line> ; fills TBL_ROWS with
    local text="$1" hdr="$2" line inside=0    # tab-joined cell strings
    TBL_ROWS=()
    local -a c=()
    while IFS= read -r line; do
        if [[ "$line" == "$hdr" ]]; then inside=1; continue; fi
        [[ "$inside" -eq 1 ]] || continue
        [[ "$line" =~ ^\|[[:space:]]*[-:]+ ]] && continue
        if [[ "${line:0:1}" != "|" ]]; then inside=0; continue; fi
        IFS='|' read -ra c <<< "$line"
        local joined="" i
        for ((i = 1; i < ${#c[@]}; i++)); do
            trim "${c[$i]}"
            joined+="${T}"$'\t'
        done
        TBL_ROWS+=("${joined%$'\t'}")
    done <<< "$text"
}

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# A full install: the CHAIN executes eleven scripts, so the whole graph area is installed
# rather than the five this work owns.
INST=""
need_install() {
    [[ -z "$INST" ]] || return 0
    INST="$TMP/install"
    mkdir -p "$INST/aid/scripts" "$INST/aid/templates" "$INST/aid/templates/knowledge-graph"
    cp -r "$GRAPH_SRC"                                    "$INST/aid/scripts/graph"
    cp -r "${REPO_ROOT}/canonical/aid/scripts/config"     "$INST/aid/scripts/config"
    cp    "${REPO_ROOT}/canonical/aid/scripts/grade.sh"   "$INST/aid/scripts/"
    cp -r "$TPL_GRAPH"                                    "$INST/aid/templates/graph"
    if [[ -f "${REPO_ROOT}/canonical/aid/templates/knowledge-graph/graph-skeleton.html" ]]; then
        cp "${REPO_ROOT}/canonical/aid/templates/knowledge-graph/graph-skeleton.html" \
           "$INST/aid/templates/knowledge-graph/"
    else
        echo '<html><body></body></html>' > "$INST/aid/templates/knowledge-graph/graph-skeleton.html"
    fi
}

# A project the enumerator can walk and the harvester can read.
build_project() {
    local d="$1" i
    mkdir -p "$d/.aid/knowledge" "$d/.aid/.temp/graph" "$d/src" "$d/docs/img"
    ( cd "$d" && git init -q . && git config user.email t@example.com && git config user.name t )
    printf -- '---\nkb-category: meta\nkb_status: Approved\n---\n\n# Discovery State\n\n> **User Approved:** yes\n' \
        > "$d/.aid/knowledge/STATE.md"
    {
        printf -- '---\nkb-category: primary\nsource: hand-authored\n---\n\n# Module Map\n\n## Modules\n\n'
        printf 'The entry point is `src/lib.js`, which this project depends on.\n\n'
        for i in $(seq 1 34); do echo "Line $i of real module-map content."; done
    } > "$d/.aid/knowledge/module-map.md"
    echo '# external sources'                       > "$d/.aid/knowledge/external-sources.md"
    printf 'format_version: 3\nminimum_grade: B-\n' > "$d/.aid/settings.yml"
    printf '{\n  "aid_version": "9.9.9"\n}\n'       > "$d/.aid/.aid-manifest.json"
    echo 'export function main() { return 1; }'     > "$d/src/lib.js"
    printf 'PNGDATA'                                > "$d/docs/img/logo.png"
    ( cd "$d" && git add -A >/dev/null 2>&1 && git commit -qm fixture >/dev/null 2>&1 )
}

if [[ "$MODE" == "assert" ]]; then

# ===========================================================================
# === CH: the pipeline chain, end to end ====================================
# ===========================================================================

if want CH; then
echo ""
echo "=== CH: PREFLIGHT -> ENUMERATE -> EXTRACT -> EMIT -> VALIDATE -> GAP-REPORT ==="
echo "    (11 subject invocations, in the order the skill runs them)"

need_install
CHG="$INST/aid/scripts/graph"
CHP="$TMP/chain"; build_project "$CHP"
cd "$CHP"

OUT=$(bash "$CHG/graph-preflight.sh" --install-root "$INST" 2>&1); RC=$?
assert_exit_zero "$RC" "CH01 PREFLIGHT over a fixture project built from the committed tree"

OUT=$(bash "$CHG/kb-write-fence.sh" --snapshot 2>&1); RC=$?
assert_exit_zero "$RC" "CH02 the write fence is raised before the run's first write"
assert_file_exists "$CHP/.aid/.temp/graph/kb-fence.txt" "CH03 and the snapshot exists for DONE to verify against"

SCAN=$(bash "$CHG/scan-source.sh" 2>&1); RC=$?
assert_exit_zero "$RC" "CH04 ENUMERATE — scan-source.sh walks the project source"
for s in nodes.tsv media-nodes.tsv observations.tsv candidates.tsv coverage.tsv; do
    assert_file_exists "$CHP/.aid/.temp/graph/$s" "CH05 ENUMERATE wrote the stream ${s}"
done
# read-setting.sh now carries --probe (D4a, task-030/W5-8), so this fixture's graph-less
# settings.yml probes as UNDECLARED rather than UNSUPPORTED -- observed LIVE rather than
# assumed, and flipped together with the primary suite's HH06-HH09 per the coupling this
# comment used to anticipate.
ok_contains "$SCAN" "graph.ignore not declared" \
    "CH06 the enumerator reports the ignore list UNDECLARED for this fixture, and still exits 0"

OUT=$(bash "$CHG/harvest-declared.sh" 2>&1); RC=$?
assert_exit_zero "$RC" "CH07 EXTRACT Pass 1a — harvest-declared.sh (the blocker that is now closed)"
assert_file_exists "$CHP/.aid/.temp/graph/kb-nodes.tsv" "CH08 Pass 1a wrote the Knowledge Base node stream"
assert_file_exists "$CHP/.aid/.temp/graph/pass2-inputs.tsv" "CH09 Pass 1a wrote the manifest that bounds Pass 2"

OUT=$(bash "$CHG/derive-edges.sh" 2>&1); RC=$?
assert_exit_zero "$RC" "CH11 EXTRACT Pass 1b — derive-edges.sh types the enumerator's observations"

# --- the Pass-2 degradation, in both directions -------------------------------------
# Direction 1: Pass 2 was never dispatched AND no disposition was written. The emitter must
# NOT call that success -- an undispositioned candidate is a shortfall, and the whole point
# of the completion check is that the pass cannot finish by giving up quietly.
CANDS=()
for cf in candidates.tsv candidates-pass1a.tsv candidates-pass1b.tsv; do
    [[ -f "$CHP/.aid/.temp/graph/$cf" ]] || continue
    while IFS=$'\t' read -r kind subject context reason || [[ -n "${kind:-}" ]]; do
        [[ -n "${subject:-}" ]] || continue
        CANDS+=("${subject}${US}${context:-}")
    done < "$CHP/.aid/.temp/graph/$cf"
done
assert_nonempty "${#CANDS[@]}" "CH12 the fixture produced candidates, so the shortfall arm is reachable at all"

rm -f "$CHP/.aid/.temp/graph/dispositions.tsv"
OUT=$(bash "$CHG/build-relationships.sh" 2>&1); RC=$?
assert_exit_eq "$RC" "1" "CH13 EMIT with Pass 2 undispositioned exits 1 — a completion shortfall, not a silent pass"
sub_count "$OUT" "undispositioned candidate:"
assert_eq "$N" "${#CANDS[@]}" "CH14 and EVERY undispositioned candidate is named, one line each (not a count, not the first one)"
assert_file_exists "$CHP/.aid/knowledge/relationships.md" \
    "CH15 the artifact is still written, so the failure is visible in the artifact rather than hidden behind a missing file"

# Direction 2: the total degradation references/state-extract.md Step 5 prescribes -- a
# `pass-2-unavailable` disposition for EVERY candidate.
: > "$CHP/.aid/.temp/graph/dispositions.tsv"
for key in "${CANDS[@]}"; do
    printf '%s\tcannot-type\tpass-2-unavailable\n' "$key" >> "$CHP/.aid/.temp/graph/dispositions.tsv"
done
ok_contains "$(<"${SKILL_REFS}/state-extract.md")" "pass-2-unavailable" \
    "CH16 [state-extract.md Step 5] the disposition this degradation writes is the one the state doc prescribes"

OUT=$(bash "$CHG/build-relationships.sh" 2>&1); RC=$?
assert_exit_zero "$RC" "CH17 EMIT — the degradation clears the completion shortfall, so the chain completes"
ART_CH="$CHP/.aid/knowledge/relationships.md"
ART_TXT=$(<"$ART_CH")
ok_contains "$ART_TXT" "# Relationships"    "CH18 the artifact carries its H1"
ok_contains "$ART_TXT" "## Coverage notes"  "CH19 [FR-9a] the coverage-notes section is present on an emitting run"
ok_contains "$ART_TXT" "AUTO-GENERATED"     "CH20 the artifact names what overwrites it"
# The extraction's coverage contribution is written by the EMITTER, not by Pass 1a -- the
# first version of this suite asserted it one step too early and the chain told it so.
assert_file_exists "$CHP/.aid/.temp/graph/kb-coverage.tsv" \
    "CH20a EMIT wrote the extraction's coverage contribution, which the assembly consumes"
ok_not_contains "$ART_TXT" "graph_inputs_digest" \
    "CH21 the emitter writes NEITHER of feature-010's two scalars — EMIT inserts them, so this seam has exactly one writer"

# VALIDATE's table half, over the artifact the chain just produced.
OUT=$(bash "$CHG/validate-relationships.sh" --file "$ART_CH" 2>&1); RC=$?
assert_exit_zero "$RC" "CH22 VALIDATE — no GATING finding in the emitted artifact"
ok_contains "$OUT" "Checked:" "CH23 and it reports what it checked"

# GAP-REPORT, over the same artifact and the same streams.
mkdir -p "$CHP/.aid/.temp/review-pending"
OUT=$(node "$CHG/detect-kb-gaps.mjs" --table "$ART_CH" \
        --nodes "$CHP/.aid/.temp/graph/nodes.tsv" \
        --output "$CHP/.aid/.temp/review-pending/graph-kb-gaps.md" 2>&1); RC=$?
assert_exit_zero "$RC" "CH24 GAP-REPORT — the detector exits 0 whatever the gap count"
ok_contains "$OUT" "KB gaps:" "CH25 and reports the count on stdout, never in the exit status"

# STALE-CHECK over the real artifact, before and after EMIT's scalar insertion.
D_OUT=$(bash "$CHG/graph-stale-check.sh" --install-root "$INST" 2>&1)
digest_of "$D_OUT"; CH_DIGEST="$DIG"
verdict_of "$D_OUT"
assert_eq "$VER" "FIRST_RUN" "CH26 STALE-CHECK over an artifact carrying no digest yields FIRST_RUN"
assert_nonempty "${#CH_DIGEST}" "CH26a and it computed a composite to insert"
# Insert the two scalars exactly as state-emit.md Step 3 has EMIT do.
{
    IFS= read -r first || true
    printf '%s\n' "$first"
    printf 'graph_inputs_digest: %s\n' "$CH_DIGEST"
    printf 'graph_generated_at: 2026-01-01T00:00:00Z\n'
    cat
} < "$ART_CH" > "$TMP/art.new" && mv -f "$TMP/art.new" "$ART_CH"
D_OUT=$(bash "$CHG/graph-stale-check.sh" --install-root "$INST" 2>&1)
verdict_of "$D_OUT"
# RENDER has no canvas module, so the chain CANNOT produce a page. With the view installed
# the honest verdict is therefore STALE on the presence arm -- stated, not approximated.
assert_eq "$VER" "STALE" \
    "CH27 with the view installed and no page produced, the presence arm reports STALE — RENDER is genuinely uncovered, and the verdict says so"
ok_contains "$D_OUT" "missing expected artifact" "CH28 and it names the page it expected"

# Lower the fence. The whole chain wrote inside .aid/knowledge/ only where it is allowed --
# including detect-kb-gaps.mjs, which rewrites the artifact's kb_gaps: scalar.
OUT=$(bash "$CHG/kb-write-fence.sh" --verify 2>&1); RC=$?
assert_exit_zero "$RC" "CH29 [AC-13] the fence verifies clean after the WHOLE chain — every write landed on an allowlisted path"
ok_contains "$OUT" "unchanged" "CH30 [AC-13] and it says so"

cd "$REPO_ROOT"
fi

# ===========================================================================
# === AS: assemble-coverage-notes.sh ========================================
# ===========================================================================

if want AS; then
echo ""
echo "=== AS: the rendered section -- reordered fields, translated labels, sorted extras ==="
echo "    (7 subject invocations: 3 renders and 4 refusals)"

need_install
AS="$INST/aid/scripts/graph/assemble-coverage-notes.sh"
ASD="$TMP/assemble"; mkdir -p "$ASD"
cd "$ASD"

# The Kind enum, read from the schema rather than copied: the rendered fixed block must be
# in the schema's declared order, and a suite carrying its own copy of the order would stop
# noticing when the schema's changed.
KINDS=()
inkinds=0
while IFS= read -r line; do
    if [[ "$line" == "kinds:"* ]]; then inkinds=1; continue; fi
    [[ "$inkinds" -eq 1 ]] || continue
    trim "$line"
    if [[ "${T:0:2}" != "- " ]]; then [[ -z "$T" ]] && continue; inkinds=0; continue; fi
    k="${T#- }"; k="${k%\"}"; k="${k#\"}"; k="${k%%|*}"
    KINDS+=("$k")
done < "$SCHEMA_YML"
assert_nonempty "${#KINDS[@]}" "AS01 the Kind enum was read from the schema, so the order assertion below is not vacuous"

# The two contributions. Every fixed key appears exactly once across BOTH files, and each
# file carries one EXTRA row for each table -- the extras are deliberately given keys whose
# LC_ALL=C order is the OPPOSITE of the file order they arrive in.
: > "$ASD/coverage.tsv"
: > "$ASD/kb-coverage.tsv"
half=$(( ${#KINDS[@]} / 2 ))
i=0
for k in "${KINDS[@]}"; do
    if [[ "$i" -lt "$half" ]]; then dest="$ASD/kb-coverage.tsv"; else dest="$ASD/coverage.tsv"; fi
    printf 'kind\t%s\tcomplete\t%s\tcarrier note for %s\n' "$k" "$((i + 1))" "$k" >> "$dest"
    i=$((i + 1))
done
printf 'exclusion\tgenerated-trees\tyes\t4242\tnote about generated trees\n' >> "$ASD/coverage.tsv"
printf 'exclusion\tvendored-code\tyes\t4242\tnote about vendored code\n'     >> "$ASD/coverage.tsv"
printf 'exclusion\tignore-list\tno\t4242\tnote about the ignore list\n'      >> "$ASD/coverage.tsv"
# extras: `zzz-` is written FIRST and in the first file, `aaa-` second and in the second
printf 'kind\tzzz-extra-kind\tpartial\t9\tnote zzz\n'                       >> "$ASD/coverage.tsv"
printf 'exclusion\tzzz-extra-exclusion\tyes\t7\tnote zzz excl\n'            >> "$ASD/coverage.tsv"
printf 'kind\taaa-extra-kind\tpartial\t8\tnote aaa\n'                       >> "$ASD/kb-coverage.tsv"
printf 'exclusion\taaa-extra-exclusion\tno\t6\tnote aaa excl\n'             >> "$ASD/kb-coverage.tsv"

OUT=$(bash "$AS" --coverage "$ASD/coverage.tsv" --kb-coverage "$ASD/kb-coverage.tsv" \
        --schema "$SCHEMA_YML" --output "$ASD/notes.md" 2>&1); RC=$?
assert_exit_zero "$RC" "AS02 the section is assembled from both contributions"
NOTES=$(<"$ASD/notes.md")
ok_contains "$NOTES" "| Kind | Carrier convention | Status | Nodes |" "AS03 the kinds table header is the schema's rendered form"
ok_contains "$NOTES" "| Exclusion | Applied | Note |"                 "AS04 the exclusions table header is the schema's rendered form"

# THE FIELD REORDERING. The contribution is scope|key|status|count|note; a kind row renders
# key, NOTE, status, count. A pass-through implementation renders status third from the
# left and produces a section the table validator rejects.
table_rows "$NOTES" "| Kind | Carrier convention | Status | Nodes |"
assert_nonempty "${#TBL_ROWS[@]}" "AS05 the kinds table has rows to check"
FIRST_KIND="${KINDS[0]}"
WANT_ROW="${FIRST_KIND}"$'\t'"carrier note for ${FIRST_KIND}"$'\t'"complete"$'\t'"1"
if [[ "${TBL_ROWS[0]}" == "$WANT_ROW" ]]; then
    pass "AS06 a kind row renders key, NOTE, status, count — the fields are reordered, not passed through"
else
    fail "AS06 the kind row is not reordered: got '${TBL_ROWS[0]//$'\t'/ | }' want '${WANT_ROW//$'\t'/ | }'"
fi

# The fixed block is in the SCHEMA's declared order, and every enum value is present once.
ORDER_OK=1
for i in "${!KINDS[@]}"; do
    row="${TBL_ROWS[$i]:-}"
    if [[ "${row%%$'\t'*}" != "${KINDS[$i]}" ]]; then
        ORDER_OK=0
        fail "AS07 the fixed kind block is out of the schema's order at position $((i + 1)): got '${row%%$'\t'*}' want '${KINDS[$i]}'"
    fi
done
[[ "$ORDER_OK" -eq 1 ]] && pass "AS07 the fixed kind block is exactly the enum, once each, in the schema's declared order"

# EXTRA ROWS SORT BY KEY ACROSS BOTH FILES. `zzz-` arrived first and in the first file;
# `aaa-` second and in the second. Rendered order must be aaa, zzz.
X1="${TBL_ROWS[${#KINDS[@]}]:-}"
X2="${TBL_ROWS[$(( ${#KINDS[@]} + 1 ))]:-}"
assert_eq "${X1%%$'\t'*}" "aaa-extra-kind" "AS08 the first extra kind row is the LC_ALL=C least key, though it arrived second and from the other file"
assert_eq "${X2%%$'\t'*}" "zzz-extra-kind" "AS09 the second extra kind row follows it"

# THE EXCLUSION LABELS ARE TRANSLATED, and `count` is dropped from the table entirely.
table_rows "$NOTES" "| Exclusion | Applied | Note |"
assert_nonempty "${#TBL_ROWS[@]}" "AS10 the exclusions table has rows to check"
declare -A EXCL_SEEN=()
CELLS_OK=1
COUNT_LEAK=0
for row in "${TBL_ROWS[@]}"; do
    IFS=$'\t' read -ra rc_ <<< "$row"
    [[ "${#rc_[@]}" -eq 3 ]] || { CELLS_OK=0; fail "AS11 an exclusions row has ${#rc_[@]} cells, want 3 — `count` must be dropped, not rendered"; }
    EXCL_SEEN["${rc_[0]}"]=1
    for cell in "${rc_[@]}"; do [[ "$cell" == "4242" ]] && COUNT_LEAK=1; done
done
[[ "$CELLS_OK" -eq 1 ]] && pass "AS11 every exclusions row has exactly three cells — the count column is dropped, not rendered"
assert_eq "$COUNT_LEAK" "0" "AS12 no exclusions CELL carries the contribution's count value (checked per cell, not as substring absence)"
for lbl in "generated/derived trees" "vendored third-party code" '`.aid/settings.yml` ignore list'; do
    if [[ -n "${EXCL_SEEN[$lbl]:-}" ]]; then
        pass "AS13 the rendered exclusion label is the TRANSLATED one: ${lbl}"
    else
        fail "AS13 the machine key was rendered instead of its label: ${lbl} is absent from the Exclusion column"
    fi
done
for key in generated-trees vendored-code ignore-list; do
    if [[ -n "${EXCL_SEEN[$key]:-}" ]]; then
        fail "AS14 a fixed exclusion rendered as its MACHINE KEY: ${key}"
    else
        pass "AS14 the machine key ${key} does not appear in the Exclusion column"
    fi
done
# An extra exclusion has no label and renders as its own key -- by rule, not by accident.
if [[ -n "${EXCL_SEEN[aaa-extra-exclusion]:-}" ]]; then
    pass "AS15 an EXTRA exclusion key, having no label, renders as itself"
else
    fail "AS15 the extra exclusion row is missing from the Exclusion column"
fi

# ORDER INDEPENDENCE: the two contributions may be read in either order.
OUT=$(bash "$AS" --coverage "$ASD/kb-coverage.tsv" --kb-coverage "$ASD/coverage.tsv" \
        --schema "$SCHEMA_YML" --output "$ASD/notes-swapped.md" 2>&1); RC=$?
assert_exit_zero "$RC" "AS16 the assembly runs with the two contributions swapped"
if [[ "$NOTES" == "$(<"$ASD/notes-swapped.md")" ]]; then
    pass "AS17 swapping the two contributions produces BYTE-IDENTICAL output — the order keys on the row, never on its origin"
else
    fail "AS17 the output depends on which contribution was read first"
fi
# IDEMPOTENCE: a second run over the same inputs overwrites with the same bytes.
bash "$AS" --coverage "$ASD/coverage.tsv" --kb-coverage "$ASD/kb-coverage.tsv" \
    --schema "$SCHEMA_YML" --output "$ASD/notes.md" >/dev/null 2>&1
if [[ "$NOTES" == "$(<"$ASD/notes.md")" ]]; then
    pass "AS18 re-running over unchanged inputs rewrites the same bytes (idempotence, not merely determinism)"
else
    fail "AS18 a second assembly of the same inputs produced different bytes"
fi

# The two assembly conflicts, and the two usage refusals.
# Drop the FIRST enum value's row -- which is in this file by construction, so the fixture
# cannot silently stop being the discriminating one the way a pattern-based deletion did.
: > "$ASD/missing.tsv"
while IFS= read -r line; do
    [[ "$line" == $'kind\t'"${KINDS[0]}"$'\t'* ]] && continue
    printf '%s\n' "$line" >> "$ASD/missing.tsv"
done < "$ASD/kb-coverage.tsv"
if [[ "$(<"$ASD/missing.tsv")" != "$(<"$ASD/kb-coverage.tsv")" ]]; then
    pass "AS18a PREMISE: the conflict fixture really is missing a fixed row (the deletion took effect)"
else
    fail "AS18a the conflict fixture is identical to the good one, so AS19 below would assert nothing"
fi
CONF=$(bash "$AS" --coverage "$ASD/coverage.tsv" --kb-coverage "$ASD/missing.tsv" \
        --schema "$SCHEMA_YML" --output "$ASD/bad.md" 2>&1); CRC=$?
assert_exit_eq "$CRC" "1" "AS19 a fixed block missing one of its rows is an assembly CONFLICT, not a section a validator rejects later"
ok_contains "$CONF" "not written" "AS20 and the section is not written"

cp "$ASD/kb-coverage.tsv" "$ASD/dup.tsv"
printf 'kind\t%s\tcomplete\t99\tsecond row for a fixed key\n' "${KINDS[0]}" >> "$ASD/dup.tsv"
CONF=$(bash "$AS" --coverage "$ASD/coverage.tsv" --kb-coverage "$ASD/dup.tsv" \
        --schema "$SCHEMA_YML" --output "$ASD/bad.md" 2>&1); CRC=$?
assert_exit_eq "$CRC" "1" "AS21 a DOUBLED fixed row is an assembly conflict too"

CONF=$(bash "$AS" --coverage "$TMP/no-such-file.tsv" --kb-coverage "$ASD/kb-coverage.tsv" \
        --schema "$SCHEMA_YML" --output "$ASD/bad.md" 2>&1); CRC=$?
assert_exit_eq "$CRC" "2" "AS22 an unreadable contribution is a usage error, distinct from a conflict"
CONF=$(bash "$AS" --bogus 2>&1); CRC=$?
assert_exit_eq "$CRC" "2" "AS23 an unknown flag is a usage error"
ok_contains "$CONF" "unknown flag" "AS24 and it names the flag"

cd "$REPO_ROOT"
fi

# ===========================================================================
# === SF: this suite's own false-PASS controls ==============================
# ===========================================================================

if want SF; then
echo ""
echo "=== SF: the known false-PASS shapes, checked against this suite's own source ==="

self_code_count 'sed -i.*(REPO_ROOT|GRAPH_SRC|TPL_GRAPH|SCHEMA_YML)'
assert_eq "$N" "0" "SF01 no in-place edit of any committed path (every fixture is built under mktemp -d)"
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
self_code_count 'table_rows'
assert_nonempty "$N" "SF07 column claims are made over parsed CELLS, never as substring presence anywhere in the file"

COVERS_N=0
BAD_COVER=0
while IFS= read -r line; do
    [[ "$line" == "# COVERS:"* ]] || continue
    trim "${line#\# COVERS:}"
    [[ -n "$T" ]] || continue
    COVERS_N=$((COVERS_N + 1))
    if [[ ! -e "${REPO_ROOT}/${T%/}" ]]; then
        BAD_COVER=1
        fail "SF08 a COVERS entry names a path that does not exist: ${T}"
    fi
done < "$SELF_SRC"
assert_nonempty "$COVERS_N" "SF08a the suite declares a COVERS manifest (a suite without one runs on every unrelated change)"
[[ "$BAD_COVER" -eq 0 ]] && pass "SF08 every COVERS entry resolves on disk"

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

digest_src() {
    sha256sum "$CANON_GRAPH"/assemble-coverage-notes.sh "$CANON_GRAPH"/grade-graph.sh \
              "$CANON_GRAPH"/build-relationships.sh | awk '{ print $1 }' | tr '\n' ' '
}
BASE_SRC_DIGEST="$(digest_src)"

# Exact-string replacement. No numeric line addresses: an address that shifts is a known
# false-PASS shape. Aborts unless the anchor occurs EXACTLY once AND the write changed the
# bytes, so a drifted anchor fails loudly instead of reporting a survivor.
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

run_mutant() {   # <name> <file-within-graph-dir> <anchor> <replacement> [group]
    local name="$1" file="$2" from="$3" to="$4" group="${5:-}"
    MUT_TOTAL=$((MUT_TOTAL + 1))
    local dir="$TMP/mut$MUT_TOTAL"
    mkdir -p "$dir"
    cp -r "$CANON_GRAPH/." "$dir/"
    echo "=== $name"
    if ! mutate_apply "$dir/$file" "$from" "$to"; then
        echo "    RESULT: ABORTED (anchor drifted -- the mutant proves nothing; fix the anchor)"
        MUT_ABORTED=$((MUT_ABORTED + 1)); return
    fi
    local out rc=0 flipped
    if [[ -n "$group" ]]; then
        out="$(GRAPH_SCRIPTS_DIR="$dir" bash "$SELF" --group "$group" 2>&1)" || rc=$?
    else
        out="$(GRAPH_SCRIPTS_DIR="$dir" bash "$SELF" 2>&1)" || rc=$?
    fi
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
echo " baseline digests: $BASE_SRC_DIGEST"
echo "=========================================================================="

# Each mutant runs only the GROUP that covers it: a mutant proves an assertion flips, and
# re-running three classes to see one of them flip costs 100 s to learn nothing extra.
run_mutant "M1 the kind row passed through instead of reordered (status renders as the note)" \
    assemble-coverage-notes.sh \
    '    awk -F'"'"'\t'"'"' '"'"'{ printf "| %s | %s | %s | %s |\n", $3, $6, $4, $5 }'"'"' "$1"' \
    '    awk -F'"'"'\t'"'"' '"'"'{ printf "| %s | %s | %s | %s |\n", $3, $4, $5, $6 }'"'"' "$1"' \
    AS

run_mutant "M2 an exclusion key rendered as itself instead of its label" \
    assemble-coverage-notes.sh \
    "        generated-trees) printf '%s' \"generated/derived trees\" ;;" \
    "        generated-trees) printf '%s' \"generated-trees\" ;;" \
    AS

run_mutant "M3 the extra rows ordered by arrival instead of by key" \
    assemble-coverage-notes.sh \
    '| sort -t$'"'"'\t'"'"' -k3,3' \
    '| cat' \
    AS


run_mutant "M4 the completion check gives up quietly (an undispositioned candidate passes)" \
    build-relationships.sh \
    '    for item in "${undispositioned[@]:-}"; do' \
    '    for item in ; do' \
    CH

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
