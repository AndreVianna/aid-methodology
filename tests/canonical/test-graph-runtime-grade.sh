#!/usr/bin/env bash
# test-graph-runtime-grade.sh -- /aid-graph's FR-28 quality gate: the check inventory, the
# two-pool grade model, and the reviewer ledger's round trip (feature-010,
# work-005-knowledge-graph).
#
# ONE OF FOUR SUITES, AND THE REASON THIS ONE IS SEPARATE IS MEASURED, NOT STYLISTIC.
#   run-all.sh kills a suite at 300 s. grade-graph.sh costs ~27 s per invocation on a
#   FAILING table -- it orchestrates four reused validators plus the view's three -- and
#   this class needs four invocations, so it costs ~113 s on its own. Its former housemates
#   cost ~120 s (the pipeline chain) and ~57 s (the coverage-notes assembly); together they
#   measured 290 s and the suite was killed mid-class. The split is by measured cost.
#     test-graph-runtime.sh         structure, preflight, the write fence, --help honesty,
#                                   the ceiling carrier, floor resolution, verdict arms
#     test-graph-runtime-digest.sh  the staleness digest's component matrix
#     test-graph-runtime-gate.sh    the end-to-end pipeline chain + the coverage assembly
#     test-graph-runtime-grade.sh   this file
#
# WHAT THIS FILE COVERS
#   THE CHECK INVENTORY. FR-28's whole point is that the inventory carries a line for EVERY
#   rubric row, so an absent row can only mean a PASSED check and never an unrun one. That
#   is asserted over the nine declared rows by name, with every status held to the
#   run / skip / fail enum.
#
#   THE TWO-POOL GRADE MODEL in all three of its states: the view in scope with G1
#   unanswered (Human and Overall pending -- not a pass by omission), G1 answered pass
#   (Human A+, Overall the minimum of the pools), and no view in scope at all (Human N/A,
#   Overall the Machine Grade -- the honest form of "no human gate on a table").
#
#   THE LEDGER'S ROUND TRIP, which is the defect this class exists for. A relationship-table
#   finding quotes the carrier's ten-column header, so its Description legitimately CONTAINS
#   PIPES. A cell written escaped and read back split changes the row's identity between the
#   run that wrote it and the run that reads it: the live finding is marked `Fixed` and a
#   duplicate is appended, so the gate reports a persisting defect as repaired and counts it
#   twice. The premise (a pipe-bearing Description really is present) is asserted BEFORE the
#   round trip, so the round-trip assertion cannot pass for the wrong reason.
#
#   THE LEDGER'S SEVERITY RANGE, asserted over the Severity COLUMN. A severity tag can
#   legitimately appear inside a Description or Evidence cell, and counting those is an
#   over-count this project has already shipped once.
#
# SUBJECT INVOCATIONS: 4, and no two could be shared --
#     1  the first grading run, over a page and a failing table: the inventory, the
#        severity range, and the ledger it writes
#     1  the SAME command again: the round trip, which only exists once a previous ledger
#        does. A third repeat is deliberately not run -- if run 2 reproduced run 1's bytes
#        from run 1's ledger, run 3 has identical inputs and can say nothing new.
#     1  with a recorded G1 answer, which is a different input by definition
#     1  on an install with no view, which is a different install by definition
#   The suite's own assertions are fork-free: the report and the ledger are read once with
#   `read` builtins and every check is `[[ ]]` or parameter expansion. Measured on this
#   shell a spawn costs 105-137 ms against 3.4 ms for a builtin.
#
# WHAT IS DELIBERATELY NOT HERE
#   * RENDER. The view has no canvas module yet, so the page this class grades is a fixture
#     this file writes, not one the pipeline produced. Stated rather than implied: what is
#     asserted is the GATE's behaviour over a page, not the page's construction.
#   * VISUAL-GATE as a state machine. What is asserted is the recorded ANSWER's effect on
#     the grade -- the human judgement itself is not a bash assertion.
#   * Any browser, any suite count, any `.aid/works/` path.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
#   The whole graph script directory is claimed because grade-graph.sh ORCHESTRATES the
#   reused validators rather than reimplementing them: a change to any validator changes the
#   findings, the ledger and the grade. grade.sh is the grading algorithm itself.
# COVERS: canonical/aid/scripts/graph/
# COVERS: canonical/aid/templates/graph/
# COVERS: canonical/aid/scripts/grade.sh
# COVERS: canonical/aid/scripts/config/read-setting.sh
# COVERS: tests/lib/assert.sh
# COVERS: tests/canonical/test-graph-runtime-grade.sh
#
# Usage:
#   bash test-graph-runtime-grade.sh [-v | --verbose]
#   bash test-graph-runtime-grade.sh --group GR       # one group: GR or SF
#   bash test-graph-runtime-grade.sh --self-mutate    # mutation-test THIS suite
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
        *) echo "test-graph-runtime-grade.sh: unknown argument: $1" >&2; exit 2 ;;
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

SENT=$(printf '\001')

# ---------------------------------------------------------------------------
# Fork-free helpers. Each returns through a named global.
# ---------------------------------------------------------------------------
T=""; N=0

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
declare -a L_NUM=() L_SEV=() L_ST=() L_DOC=() L_LN=() L_DESC=() L_EV=()
ledger_load() {
    L_NUM=(); L_SEV=(); L_ST=(); L_DOC=(); L_LN=(); L_DESC=(); L_EV=()
    [[ -f "$1" ]] || return 0
    local line s sev
    local -a c=()
    while IFS= read -r line; do
        [[ "${line:0:1}" == "|" ]] || continue
        [[ "$line" =~ ^\|[[:space:]]*[-:]+[[:space:]]*\| ]] && continue
        s="${line//\\|/$SENT}"
        IFS='|' read -ra c <<< "$s"
        [[ "${#c[@]}" -ge 8 ]] || continue
        trim "${c[2]}"; sev="${T//$SENT/\\|}"
        [[ "$sev" == "Severity" || "$sev" == "#" ]] && continue
        L_SEV+=("$sev")
        trim "${c[1]}"; L_NUM+=("${T//$SENT/\\|}")
        trim "${c[3]}"; L_ST+=("${T//$SENT/\\|}")
        trim "${c[4]}"; L_DOC+=("${T//$SENT/\\|}")
        trim "${c[5]}"; L_LN+=("${T//$SENT/\\|}")
        trim "${c[6]}"; L_DESC+=("${T//$SENT/\\|}")
        trim "${c[7]}"; L_EV+=("${T//$SENT/\\|}")
    done < "$1"
}

# --- a rendered markdown table's rows, as cell arrays ----------------------------
# Used by the AS class so a claim about a COLUMN is made over that column, never as
# substring presence anywhere in the file.

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


if [[ "$MODE" == "assert" ]]; then

# ===========================================================================
# === GR: the FR-28 gate, and the ledger's round trip =======================
# ===========================================================================

if want GR; then
echo ""
echo "=== GR: the check inventory, the two-pool grade model, and the ledger round trip ==="
echo "    (4 subject invocations: run 1, the re-read of its own ledger, a G1 answer, no view)"

need_install
GG="$INST/aid/scripts/graph/grade-graph.sh"
GRD="$TMP/gate"; mkdir -p "$GRD/.aid/.temp/graph"
cd "$GRD"

# A table that FAILS the shape check, because the finding for a wrong header quotes the
# carrier's ten-column list -- so its Description legitimately contains pipes. That is the
# input the round trip is regressed against.
printf -- '---\nkb-category: primary\n---\n\n# Relationships\n\n| Wrong | Header |\n|---|---|\n| a | b |\n\ntail\n' \
    > "$GRD/table.md"
printf '<!DOCTYPE html>\n<html><head><title>graph</title></head><body><div id="graph"></div></body></html>\n' \
    > "$GRD/graph.html"
LED="$GRD/.aid/.temp/review-pending/ledger.md"

OUT1=$(bash "$GG" --install-root "$INST" --table "$GRD/table.md" --html "$GRD/graph.html" \
        --ledger "$LED" 2>&1); RC1=$?
assert_file_exists "$LED" "GR01 the gate wrote its ledger"

# THE INVENTORY carries a line for EVERY rubric row, so an absent row can only mean a
# passed check and never an unrun one.
RUBRIC=("R*" V-H1 V-A V-ST V-L V-S2 V-NM V-C V-T)
declare -A INV=()
ininv=0
while IFS= read -r line; do
    if [[ "$line" == "Check inventory:" ]]; then ininv=1; continue; fi
    [[ "$ininv" -eq 1 ]] || continue
    [[ "${line:0:2}" == "  " ]] || { ininv=0; continue; }
    trim "$line"
    row="${T%% *}"
    rest="${T#"$row"}"; trim "$rest"
    INV["$row"]="${T%% *}"
done <<< "$OUT1"
assert_nonempty "${#INV[@]}" "GR02 the inventory was parsed at all"
MISSING=""
BADST=""
for row in "${RUBRIC[@]}"; do
    st="${INV[$row]:-}"
    [[ -n "$st" ]] || { MISSING+=" $row"; continue; }
    case "$st" in
        run|skip|fail) ;;
        *) BADST+=" ${row}=${st}" ;;
    esac
done
if [[ -z "$MISSING" ]]; then
    pass "GR03 [FR-28] the inventory names every one of the ${#RUBRIC[@]} rubric rows, so an absent row can only mean a passed check"
else
    fail "GR03 [FR-28] the inventory omits rubric row(s):${MISSING}"
fi
if [[ -z "$BADST" ]]; then
    pass "GR04 [FR-28] every inventory status is one of run / skip / fail"
else
    fail "GR04 [FR-28] an inventory status is outside the enum:${BADST}"
fi

# THE LEDGER. Its severity range is exactly [HIGH] and [MEDIUM], asserted over the
# SEVERITY COLUMN -- a severity tag can legitimately appear inside a Description, and
# counting those is the over-count this project has already shipped once.
ledger_load "$LED"
ROWS1="${#L_SEV[@]}"
assert_nonempty "$ROWS1" "GR05 the ledger carries rows, so every claim below is over a non-empty set"
declare -A SEV_SEEN=()
for s in "${L_SEV[@]}"; do SEV_SEEN["$s"]=1; done
OUTSIDE=""
for s in "${!SEV_SEEN[@]}"; do
    case "$s" in
        '[HIGH]'|'[MEDIUM]') ;;
        *) OUTSIDE+=" '$s'" ;;
    esac
done
if [[ -z "$OUTSIDE" ]]; then
    pass "GR06 [FR-28] every Severity CELL is one of [HIGH] or [MEDIUM] — the range this rubric emits"
else
    fail "GR06 [FR-28] a Severity cell is outside the emitted range:${OUTSIDE}"
fi
ST_OUTSIDE=""
for s in "${L_ST[@]}"; do
    [[ "$s" == "Pending" ]] || ST_OUTSIDE+=" '$s'"
done
if [[ -z "$ST_OUTSIDE" ]]; then
    pass "GR07 on a FIRST grading run every row is Pending — nothing can be Fixed before a cycle has passed"
else
    fail "GR07 a first-run row is not Pending:${ST_OUTSIDE}"
fi

# THE PREMISE of the round trip: a Description cell really does contain a pipe. Without
# this the idempotence assertion below would hold for the wrong reason.
PIPED=0
for d in "${L_DESC[@]}"; do
    [[ "$d" == *'\|'* ]] && PIPED=$((PIPED + 1))
done
assert_nonempty "$PIPED" "GR08 PREMISE: a Description cell carries an ESCAPED PIPE (the shape-check finding quotes the ten-column header), so the round trip below is tested against the cell that broke it"

# THE ROUND TRIP. Run 2 reads back what run 1 wrote and must reproduce it byte for byte.
# A reader that splits on every pipe shifts the pipe-bearing row's fields, fails to match
# its own key, marks the live finding Fixed and appends a duplicate.
LED1=$(<"$LED")
OUT2=$(bash "$GG" --install-root "$INST" --table "$GRD/table.md" --html "$GRD/graph.html" \
        --ledger "$LED" 2>&1); RC2=$?
LED2=$(<"$LED")
if [[ "$LED1" == "$LED2" ]]; then
    pass "GR09 the ledger survives its own round trip BYTE-IDENTICALLY — a cell written escaped is read back as the same cell (idempotence: run 2 rewrote the file it read)"
else
    fail "GR09 the ledger is not idempotent: re-grading an unchanged, still-failing artifact rewrote it"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- run 1 ---"; echo "$LED1"; echo "--- run 2 ---"; echo "$LED2"; }
fi
ledger_load "$LED"
assert_eq "${#L_SEV[@]}" "$ROWS1" "GR10 and the row count did not grow — a persisting defect is ONE row, not one per cycle"
ST2=""
for s in "${L_ST[@]}"; do [[ "$s" == "Pending" ]] || ST2+=" '$s'"; done
if [[ -z "$ST2" ]]; then
    pass "GR11 and every row is still Pending — a defect that still reproduces was not marked Fixed"
else
    fail "GR11 a still-reproducing finding changed status:${ST2}"
fi
assert_eq "$RC2" "$RC1" "GR12 and the exit status is the same on both runs"

# THE HUMAN POOL, in all three states. State 1: the view is in scope and G1 is unanswered.
ok_contains "$OUT1" "Human Grade:    pending" \
    "GR13 [G1] with the view in scope and no recorded answer, the Human Grade is pending — not a pass by omission"
ok_contains "$OUT1" "Overall Grade:  pending" \
    "GR14 [G1] and the Overall Grade is pending too, because the minimum of a known and an unknown is unknown"
MACHINE=""
while IFS= read -r line; do
    [[ "$line" == "Machine Grade:"* ]] && { trim "${line#Machine Grade:}"; MACHINE="$T"; break; }
done <<< "$OUT1"
assert_nonempty "${#MACHINE}" "GR15 the Machine Grade was computed and printed"

# State 2: G1 answered pass. The Human pool is A+ and Overall falls back to the minimum.
printf '{ "g1": "pass" }\n' > "$GRD/visual-gate.json"
OUT3=$(bash "$GG" --install-root "$INST" --table "$GRD/table.md" --html "$GRD/graph.html" \
        --ledger "$LED" --visual-gate "$GRD/visual-gate.json" 2>&1)
ok_contains "$OUT3" "Human Grade:    A+" "GR16 [G1] a recorded G1 pass sets the Human Grade"
ok_contains "$OUT3" "Overall Grade:  ${MACHINE}" \
    "GR17 [G1] and the Overall Grade is the MINIMUM of the two pools, which here is the Machine Grade"

# State 3: no view in scope. The human pool is N/A, and Overall is the Machine Grade -- the
# honest form of "no human gate on a table".
NOVIEW="$TMP/install-noview"
mkdir -p "$NOVIEW/aid/scripts" "$NOVIEW/aid/templates"
cp -r "$INST/aid/scripts/graph"  "$NOVIEW/aid/scripts/graph"
cp -r "$INST/aid/scripts/config" "$NOVIEW/aid/scripts/config"
cp    "$INST/aid/scripts/grade.sh" "$NOVIEW/aid/scripts/"
cp -r "$INST/aid/templates/graph" "$NOVIEW/aid/templates/graph"
OUT4=$(bash "$NOVIEW/aid/scripts/graph/grade-graph.sh" --install-root "$NOVIEW" \
        --table "$GRD/table.md" --ledger "$LED" 2>&1)
ok_contains "$OUT4" "Human Grade:    N/A" \
    "GR18 [AC-S10] with no view installed the human pool is N/A — not pending, and not a silent pass"
ok_contains "$OUT4" "nothing to judge" "GR19 [AC-S10] and it says why"
MACHINE4=""
while IFS= read -r line; do
    [[ "$line" == "Machine Grade:"* ]] && { trim "${line#Machine Grade:}"; MACHINE4="$T"; break; }
done <<< "$OUT4"
ok_contains "$OUT4" "Overall Grade:  ${MACHINE4}" \
    "GR20 [AC-S10] and the Overall Grade is the Machine Grade, with no human pool folded in"
ok_not_contains "$OUT4" "and ${GRD}/graph.html" \
    "GR21 [AC-S10] the subject line names only the table when no view is in scope"

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
self_code_count 'ledger_load'
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
# M1 is the mutant this suite exists for: the ledger reader stops protecting
# escaped pipes before the split, so the pipe-bearing row's fields shift and its identity
# does not survive the round trip.
run_mutant "M1 the ledger read by splitting on EVERY pipe (the round-trip defect)" \
    grade-graph.sh \
    '            gsub(/\\\|/, SEP, line)' \
    '            # mutant: no pipe protection before the split' \
    GR

run_mutant "M2 the check inventory reduced to the rows that have something to say" \
    grade-graph.sh \
    'echo "Check inventory:"' \
    'echo "Check inventory:"; RUBRIC_ROWS=("R*")' \
    GR

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
