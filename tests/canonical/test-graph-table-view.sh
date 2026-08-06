#!/usr/bin/env bash
# test-graph-table-view.sh -- feature-009's accessible-table criteria: the TV01-TV18
# assertions its SPEC names (SPEC.md:591-610) and the WCAG AA pass this task owns.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# COVERS: canonical/aid/templates/knowledge-graph/graph-table.js
# COVERS: canonical/aid/templates/knowledge-graph/accessibility-checklist.md
# COVERS: canonical/aid/scripts/summarize/validate-html-output.sh
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
#
# WHY A SECOND SUITE OVER THE SAME VIEW
#   tests/canonical/test-graph-view.sh (renamed test-graph-view-shell.sh by a
#   concurrent task -- NOT edited here) already proves the shell/table seam's
#   mechanism: GT30-64 IS D1/D2/D4, and its GS/GC/GX/DT groups already exercise
#   most of what a table-only reading needs. That suite is organised by
#   MECHANISM (row set, order, emphasis, DOM). This one is organised by feature-009's
#   own SPEC -- one row per TV id -- so the AC-to-assertion map is auditable
#   against the SPEC table rather than against a mechanism grouping. Wherever the
#   mechanism is already proven, this suite CITES the id that proves it (via the
#   same, unmodified helpers: graph-view-fixture.mjs, graph-view-mutate.mjs,
#   graph-view-model.mjs, graph-view-dom.mjs) rather than re-deriving it -- so no
#   assertion here is a stand-in FOR the mechanism suite, but every TV row still
#   gets its own PASS/FAIL/SKIP verdict, and nothing is skipped silently.
#
# THE REAL MODULE, NOT A STAND-IN
#   graph-view-dom.mjs's jsdom document is a legitimate stand-in for STRUCTURE
#   (SPEC's own permission). But every assertion below -- static or through the
#   bundle -- reads canonical/aid/templates/knowledge-graph/graph-table.js itself:
#   the TV05a/TV06a/TV06b/TV08a/TV09a/TV13a/TV14a groups grep that file directly
#   (zero copying, zero bundling -- the most direct route there is), and the
#   bundle graph-view-mutate.mjs builds in --self-mutate=off mode concatenates
#   that same file byte-for-byte (S5: nothing under canonical/ is ever written).
#   So every TV verdict below is a verdict about the shipped file, never about a
#   description of it.
#
# THE AC-TO-ASSERTION MAP (feature-009 SPEC.md:591-610)
#   TV id | Criterion         | This suite's own id(s)                    | Ground
#   ------|--------------------|--------------------------------------------|------------------------------------
#   TV01  | AC-7 (table half)  | TV01 (cites GT70, DT29)                   | headless + DOM
#   TV02  | AC-8a parts 1-2    | TV02 (cites GT32,GT32b,GT32c,DT14)        | headless + DOM
#   TV03  | AC-9                | TV03a/TV03b (validate-html-output.sh)     | assembled + booted page
#   TV04  | AC-9,AC-21,NFR-6   | TV04 (cites DT15,DT16,DT25)                | DOM
#   TV05  | AC-9, 2-region     | TV05a (static grep) + TV05b (cites DT12,DT13,DT18) | static + DOM
#   TV06  | AC-10, GV01        | TV06a/TV06b (static) + TV06c (cites DT11,DT29) | static + DOM
#   TV07  | AC-15               | TV07 (cites GT12,GT12b,GT50,GT50b,GT53,GT53b,GT54) | headless
#   TV08  | AC-21, D8, GV22    | TV08a (static) + TV08b (cites DT13,DT17)  | static + DOM
#   TV09  | AC-S1               | TV09a (static skeleton order) + TV09b (cites DT26) | static + DOM
#   TV10  | AC-S2, D2           | TV10 (cites GT34,GT34b,GT35,GT36,GT37,GT38,GT38b,GT39,GT40,DT18) | headless + DOM
#   TV11  | AC-S3, AC-S5, D1    | TV11 (cites GT30,GT31,GT31b)               | headless
#   TV12  | AC-S4, D4           | TV12 (cites GT60,GT61,GT61b,GT62,GT63,GT64,DT21) | headless + DOM
#   TV13  | AC-S5               | TV13a (static) + TV13b (cites DT19,GT55)  | static + DOM
#   TV14  | AC-S6               | TV14a (static)                             | static
#   TV15  | AC-S7, feat-007 S8  | TV15 (cites DT27)                           | DOM
#   TV16  | AC-9 checklist:105-6| ROUTED, not asserted -- see below           | (none: jsdom has no layout)
#   TV17  | AC-9                | TV17 (cites DT20)                          | DOM
#   TV18  | AC-S8, FR-14a, D7a  | TV18 (cites DT22, GT53)                     | headless + DOM
#   TV19  | task-033 AC 2,4     | TV19 (cites TWC01-06,06b,06c,06c-drain,10) | DOM (graph-table-window-check.mjs)
#   TV20  | task-033 AC 3,4     | TV20 (cites TWC07,TWC08,TWC09)              | DOM (graph-table-window-check.mjs)
#
# TV16 IS ROUTED, NOT SKIPPED SILENTLY. jsdom implements no layout (stated by
# graph-view-dom.mjs's own header, and by test-graph-view-shell.sh's "WHAT IS
# DELIBERATELY NOT HERE"), so "no region overflows its own container at 732px,
# 390px and 200% zoom" has no static or headless oracle in this repository today.
# The only route is the Playwright visual gate
# (canonical/aid/scripts/summarize/validate-visuals.mjs), and that gate does not
# yet carry a `--profile graph` mode -- task-019/task-021 wire read-setting.sh's
# graph profile into it. Faking a pass here would be exactly the failure class
# this wave is hunting (an assertion that can only ever pass). It is named,
# recorded SKIP with the reason, and left for whichever of task-019/021 (or a
# follow-on on-demand Playwright check, never the CI lane per S-AC-3 below)
# actually has an oracle.
#
# SHARED-CRITERION HALVES -- named as halves, so no gate reads one as a whole
#   AC-7  (this suite: the TABLE renders from the store's CURRENT ViewModel by
#         identity -- TV01/DT29). The CANVAS half and the cross-surface pairing
#         are feature-008's / task-018's (feature-009 Open Item 3). Full close: task-022.
#   AC-9  (this suite: every table-side clause -- TV03-05,09,13,14,16,17). The
#         REDUCED-MOTION clause for the settled graph is feature-008's NFR-4,
#         closed in task-018. Full close: task-022.
#
# WHAT IS DELIBERATELY NOT HERE (test-landscape.md S-AC-3, this task's own AC)
#   * No browser check, no Playwright invocation. Runtime UI verification does
#     not belong in the CI lane (test-landscape.md); TV16 is routed there instead
#     of faked here.
#   * No work-folder path. Every fixture comes from graph-view-fixture.mjs.
#
# SUITE BUDGET (S1) -- DERIVED BY GREPPING THIS FILE'S OWN CALL SITES, not assumed
#   Default run (no --self-mutate): 5 subject invocations --
#     1x graph-view-mutate.mjs (builds the one bundle every group below reads)
#     1x graph-view-model.mjs  (the headless half, against that one bundle)
#     1x graph-view-dom.mjs    (the DOM half, against that one bundle -- emits
#                               BOTH the assembled and the booted page in this
#                               one run)
#     2x validate-html-output.sh (once over the assembled page, once over the
#                               booted page -- TV03a/TV03b)
#   --self-mutate adds 11 more: 5 mutation ids (list-collapsed, unlisted-by-degree,
#   tiebreak-direction, sortof-keeps-direction, dimmed-either-map) each cost
#   1x graph-view-mutate.mjs + 1x graph-view-model.mjs --expect-fail = 10, plus
#   1x graph-view-mutate.mjs for colour-literal (grep-only verdict, no model.mjs
#   run needed) = 1. Total with --self-mutate: 16.
#   Verify: `grep -c 'node "\$MUTATE_MJS"' "$0"` must read 6 (1 default-run build +
#   5 mutation builds), and `grep -c 'node "\$MODEL_MJS"' "$0"` must read 6 (1
#   default-run + 5 --expect-fail runs) -- checked by TV-BUDGET below, at the tail.
#   task-033 adds ONE further invocation, `graph-table-window-check.mjs`
#   (WINDOW_MJS), building its OWN self-contained fixture and bundle -- it reads
#   the four real view files directly rather than through graph-view-mutate.mjs,
#   so it is intentionally outside this budget note's MUTATE_MJS/MODEL_MJS
#   arithmetic and outside the S1-budget self-check's grep patterns at the tail
#   (neither pattern names $WINDOW_MJS).
#
# RUNTIMES
#   node   required for everything except the static greps. Absent -> everything
#          past the static groups SKIPs loudly.
#   jsdom  optional (bare specifier or AID_GRAPH_JSDOM). Absent -> every
#          DOM-grounded TV verdict (TV01,02,04,05b,06c,08b,09b,10,12,15,17,18,
#          19,20) reports SKIP rather than a false PASS -- tv_check below treats
#          "no constituent produced PASS or FAIL" as SKIP, never as PASS.
#
# Usage:
#   bash test-graph-table-view.sh [-v|--verbose] [--self-mutate]
#
# Exit codes:
#   0 -- every assertion passed (skips are reported, never counted as passes)
#   1 -- one or more assertions failed

set -u

VERBOSE=0
SELF_MUTATE=0
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --self-mutate) SELF_MUTATE=1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

GRAPH_DIR="${REPO_ROOT}/canonical/aid/templates/knowledge-graph"
TABLE_JS="${GRAPH_DIR}/graph-table.js"
CHECKLIST="${GRAPH_DIR}/accessibility-checklist.md"
VALIDATE_HTML="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-html-output.sh"

MUTATE_MJS="${SCRIPT_DIR}/graph-view-mutate.mjs"
MODEL_MJS="${SCRIPT_DIR}/graph-view-model.mjs"
DOM_MJS="${SCRIPT_DIR}/graph-view-dom.mjs"
WINDOW_MJS="${SCRIPT_DIR}/graph-table-window-check.mjs"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HAVE_NODE=0
command -v node >/dev/null 2>&1 && HAVE_NODE=1

assert_file_exists "$TABLE_JS" "table-view: subject present -- canonical/.../graph-table.js"

# Records the id-prefix of every GT/DT outcome line so tv_check below can look
# up "did this constituent id PASS, FAIL, or never run".
declare -A OUTCOME
consume() {
    local line kind label id
    while IFS= read -r line; do
        [[ "$line" == GV$'\t'* ]] || { [[ "$VERBOSE" -eq 1 ]] && echo "$line"; continue; }
        kind="${line#GV$'\t'}"; kind="${kind%%$'\t'*}"
        label="${line#GV$'\t'*$'\t'}"
        id="${label%% *}"
        case "$kind" in
            PASS) pass "$label"; OUTCOME["$id"]="PASS" ;;
            FAIL) fail "$label"; OUTCOME["$id"]="FAIL" ;;
            SKIP) skip "$label"; [[ -z "${OUTCOME[$id]:-}" ]] && OUTCOME["$id"]="SKIP" ;;
            NOTE) echo "  NOTE: $label" ;;
        esac
    done
}

# One synthetic TV verdict per SPEC row, built from the constituent ids it
# cites. FAIL if any constituent FAILed; PASS if at least one constituent
# PASSed and none FAILed; SKIP if every named constituent never produced a
# PASS or FAIL (e.g. jsdom absent) -- never silently PASS on that emptiness.
tv_check() {
    local tv="$1" desc="$2"; shift 2
    local ids=("$@")
    local any_pass=0 any_fail=0 failed_id="" ran=0
    for id in "${ids[@]}"; do
        case "${OUTCOME[$id]:-}" in
            PASS) any_pass=1; ran=1 ;;
            FAIL) any_fail=1; failed_id="$id"; ran=1 ;;
            SKIP) ran=1 ;;
        esac
    done
    if [[ "$any_fail" -eq 1 ]]; then
        fail "$tv $desc -- constituent $failed_id failed (cites: ${ids[*]})"
    elif [[ "$any_pass" -eq 1 ]]; then
        pass "$tv $desc (cites: ${ids[*]})"
    else
        skip "$tv $desc -- no constituent (${ids[*]}) produced a verdict"
    fi
}

# ===========================================================================
# === WCAG AA -- item by item, against accessibility-checklist.md ===========
# ===========================================================================
echo ""
echo "=== WCAG AA pass -- accessibility-checklist.md, this feature's table-scoped items ==="
assert_file_exists "$CHECKLIST" "AA subject present -- accessibility-checklist.md"
# Section 0 states which surface each existing check binds; the table rendering
# is bound by: HTML validity/landmarks/ARIA/focus/reduced-motion (TV03), and by
# every [auto]/[contract] item in Sections 1,2,5,7,8 that names "the table
# rendering" or names no surface restriction. This suite records each such item
# by its own checklist anchor (section.bullet-order) and its verdict; items
# scoped to the DRAWING surface, or [manual]/visual-gate items, are ROUTED to
# their stated owner rather than checked here, never silently dropped.
cat <<'AA_MAP'
  AA §1 "at most once per load" alert region              -> ROUTED  (page-load property, feature-007's shell, not this rendering)
  AA §1 table creates no third live region                -> TV05a (static: no aria-live in graph-table.js)
  AA §2 both renderings siblings, neither nested            -> TV09a/TV09b (static skeleton order + DT26)
  AA §2 DOM order table-first                                -> TV09a (static skeleton order)
  AA §2 table mounts first and unconditionally               -> TV09b (DT26: renders complete with no canvas module)
  AA §2 link from graph region to table region               -> ROUTED  (feature-007's shell emits it, not this file)
  AA §3 every relationship name present as TEXT in the table -> TV06a/TV06b (static: every cell value is TBL_COLUMNS-driven)
  AA §3 emphasis maps to a text marker, never colour alone   -> TV13a/TV13b (static colour-literal grep + DT19)
  AA §4 no colour literal, no --gk-/--gc- token in this file -> TV13a (static grep)
  AA §5 every control is a native focusable element           -> TV04/TV08b (DT16/DT17: native <button> set)
  AA §5 control set complete against the data (not merely reachable) -> TV04 (DT16: enumerated tab-stop set)
  AA §5 no control ever disabled/hidden by a preset           -> ROUTED  (this rendering emits 2 control KINDS with no preset-conditional branch of its own; the shell's panel controls are feature-007's, out of this file's scope)
  AA §7 accessible name is never the shortened form           -> TV15 (DT27)
  AA §7 a node with no relationship carries that fact in its accessible name -> ROUTED (feature-006/graph-model.js writes the label text this file only renders; asserted in test-graph-view-shell.sh's GT11)
  AA §8 sticky-bar scroll margin on every focusable            -> TV04 (DT16 constituent set; the margin value itself is a layout measure -- ROUTED with TV16, no jsdom layout oracle)
  AA §2/§6 manual visual-gate items (settled graph, forced colours, third-live-region eyeball) -> ROUTED (human visual gate / feature-008; out of this static suite by design)
AA_MAP
echo "  NOTE: rows marked ROUTED are named rather than checked here because either the item binds a"
echo "        different surface (the shell, the drawing rendering, graph-model.js) or it is a [manual]"
echo "        item reserved for the human visual gate -- neither is faked as a static PASS."

# ===========================================================================
# === Static groups -- direct greps against the REAL graph-table.js =========
# ===========================================================================
echo ""
echo "=== TV05a / TV08a / TV13a / TV14a -- static properties of the real file, no bundle ==="
n=$(grep -c "aria-live" "$TABLE_JS" || true)
assert_eq "$n" "0" "TV05a graph-table.js creates no third live region (no aria-live literal)"
n=$(grep -c "data-control=" "$TABLE_JS" || true)
assert_eq "$n" "0" "TV08a graph-table.js sets no data-control attribute (GV22 bijection intact)"
n=$(grep -c "data-group-toggle" "$TABLE_JS" || true)
assert_eq "$n" "0" "TV08a graph-table.js sets no data-group-toggle attribute (exactly-one-disclosure intact)"
for pattern in '#[0-9a-fA-F]{3}' 'rgba?\(' 'hsla?\(' 'oklch\(' '\-\-gk\-' '\-\-gc\-'; do
    n=$(grep -cE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "TV13a graph-table.js contains no /$pattern/"
done
NAMED_COLOURS='red|green|blue|black|white|gray|grey|yellow|orange|purple|pink|brown'
NAMED_COLOURS="${NAMED_COLOURS}|cyan|magenta|teal|navy|olive|maroon|silver|lime|aqua|fuchsia|currentcolor"
n=$(grep -ciwE "$NAMED_COLOURS" "$TABLE_JS" || true)
assert_eq "$n" "0" "TV13a graph-table.js names no colour, not even in a class name"
for pattern in 'smooth' 'transition' 'animation'; do
    n=$(grep -ciE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "TV14a graph-table.js contains no /$pattern/"
done
n=$(grep -cE 'scrollIntoView\(' "$TABLE_JS" || true)
assert_eq "$n" "1" "TV14a graph-table.js makes exactly one scroll call"
assert_file_contains "$TABLE_JS" "behavior: 'instant'" "TV14a that one scroll call is instantaneous"

echo ""
echo "=== TV06a / TV06b -- the column contract and the no-network property, static ==="
n=$(grep -cE $'^\t\ttoken:' "$TABLE_JS" || true)
assert_eq "$n" "10" "TV06b TBL_COLUMNS declares exactly ten column descriptors (D3's contract count)"
for token in source-id source-kind source-name target-id target-kind target-name s2t-relation t2s-relation provenance observation; do
    assert_file_contains "$TABLE_JS" "token: '${token}'" "TV06b column token present and in the relationship file's own order: ${token}"
done
for pattern in '^import' '^[[:space:]]*import[[:space:]]' 'fetch[[:space:]]*\(' 'XMLHttpRequest' 'import[[:space:]]*\(' 'require[[:space:]]*\('; do
    n=$(grep -cE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "TV06a graph-table.js contains no /$pattern/ (no second data path)"
done

echo ""
echo "=== TV09a -- the table page declares its own mount point, unconditionally (static, the skeleton) ==="
# WAS "DOM order is table-first" over graph-skeleton.html, comparing the table
# region's line to the graph region's line on ONE page. Since eedacc3d/
# task-033 the table rendering lives on its OWN page (table-view-skeleton.html),
# which declares no graph region at all -- an ordering claim between two
# elements when one of them is gone is not a weaker test, it is a test of
# nothing (the same reasoning test-graph-view-shell.sh's own GS07 already
# applies to graph-skeleton.html). What replaces it: table.html's own skeleton
# declares the table's mount point exactly once, unconditionally -- there is
# no OWNER_EXCLUDES_TABLE_RENDERING-style switch for this page at all
# (build-table-src.mjs's own header: "no flag to flip here", unlike
# build-graph-src.mjs's).
TABLE_SKELETON="${GRAPH_DIR}/table-view-skeleton.html"
n=$(grep -c 'data-table-region' "$TABLE_SKELETON" || true)
assert_eq "$n" "1" "TV09a table-view-skeleton.html declares [data-table-region] exactly once, unconditionally -- AC-S1"

if [[ "$HAVE_NODE" -eq 0 ]]; then
    skip "TV01,TV02,TV04,TV05b,TV06c,TV07,TV08b,TV09b,TV10,TV11,TV12,TV13b,TV15,TV17,TV18,TV03a,TV03b -- node is not on PATH"
else
    # =======================================================================
    # === One bundle, one headless run, one DOM run (S1) =====================
    # =======================================================================
    echo ""
    echo "=== Building the ONE bundle every group below reads (S1: one subject build) ==="
    node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" none > "${TMP}/bundle.log" 2>&1
    assert_exit_zero "$?" "table-view: the real graph-table.js (plus its three module-scope siblings) concatenates cleanly"

    echo ""
    echo "=== headless half (S1: one subject invocation), then TV01/02/07/10/11/12/18 by citation ==="
    set +e
    node "$MODEL_MJS" "${TMP}/bundle.mjs" > "${TMP}/model.out" 2>"${TMP}/model.err"
    model_rc=$?
    set -e
    consume < "${TMP}/model.out"
    model_lines=$(grep -cE '^GV.(PASS|FAIL)' "${TMP}/model.out" || true)
    if [[ "${model_lines:-0}" -ge 30 ]]; then
        pass "table-view: the headless half reported its assertions ($model_lines outcomes) -- the ground TV01/02/07/10/11/12/18 cite"
    else
        fail "table-view: the headless half reported its assertions -- only ${model_lines:-0} outcome line(s)"
    fi
    [[ "$model_rc" -ne 0 ]] && [[ "${model_lines:-0}" -eq 0 ]] && \
        fail "table-view: the headless half ran to completion -- exit $model_rc, no outcome: $(head -3 "${TMP}/model.err" | tr '\n' ' ')"

    tv_check TV01 "the table renders from the store's CURRENT ViewModel (AC-7 table half)" GT70 DT29
    tv_check TV02 "a single-category filter is non-vacuous and every preset composes with it (AC-8a parts 1-2)" GT32 GT32b GT32c DT14
    tv_check TV07 "the Coverage preset's two gap badges are exact, disjoint and survive a selection (AC-15)" GT12 GT12b GT50 GT50b GT53 GT53b GT54
    tv_check TV10 "the sort cycle is a permutation with a code-unit total order and a row-ascending tie-break (AC-S2, D2)" GT34 GT34b GT35 GT36 GT37 GT38 GT38b GT39 GT40
    tv_check TV11 "listed rows are exactly the unfolded rows, set equality both directions, non-vacuously (AC-S3, AC-S5, D1)" GT30 GT31 GT31b
    tv_check TV12 "every visible node is named -- listed or unlisted -- across all three D4 populations (AC-S4, D4)" GT60 GT61 GT61b GT62 GT63 GT64
    tv_check TV13b "emphasis maps totally over both value spaces (AC-S5)" GT55

    echo ""
    echo "=== DOM half (S1: one subject invocation, emits both pages), then TV04/05b/06c/08b/09b/10/12/13b/15/17/18 by citation ==="
    set +e
    node "$DOM_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" "${TMP}/page" > "${TMP}/dom.out" 2>"${TMP}/dom.err"
    dom_rc=$?
    set -e
    consume < "${TMP}/dom.out"
    dom_lines=$(grep -cE $'^GV\t(PASS|FAIL|SKIP)\t' "${TMP}/dom.out" || true)
    if [[ "${dom_lines:-0}" -ge 15 ]]; then
        pass "table-view: the DOM half reported its assertion classes ($dom_lines outcomes) -- the ground TV04/05b/06c/08b/09b/10/12/13b/15/17/18 cite"
    else
        fail "table-view: the DOM half reported its assertion classes -- only ${dom_lines:-0} outcome line(s)"
    fi
    [[ "$dom_rc" -ne 0 && "$dom_rc" -ne 3 ]] && [[ "${dom_lines:-0}" -eq 0 ]] && \
        fail "table-view: the DOM half ran to completion -- exit $dom_rc, no outcome: $(head -3 "${TMP}/dom.err" | tr '\n' ' ')"

    tv_check TV04 "tab stops are exactly the enumerated set at both gate widths, none is a cell or a summary (AC-9,AC-21,NFR-6)" DT15 DT16 DT25
    tv_check TV05b "aria-sort is on the listed table's ten headers, on no other cell, correct state (AC-9)" DT12 DT13 DT18
    tv_check TV06c "every rendered cell value traces to the ViewModel and to the current store instance (AC-10, GV01)" DT11 DT29
    tv_check TV08b "keyboard-only activation of both control kinds drives the asserted LensState effect (AC-21, D8, GV22)" DT13 DT17
    tv_check TV09b "the region renders complete with no canvas module in the build (AC-S1)" DT26
    tv_check TV10 "aria-sort transitions none -> ascending -> descending -> none under activation (AC-S2, D2)" DT18
    tv_check TV12 "the unlisted-nodes region is a real table naming every unlisted node (AC-S4, D4)" DT21
    tv_check TV13b "every emphasis class renders its text badge; dimmed renders none (AC-S5)" DT19
    tv_check TV15 "below the breakpoint the shortened label is aria-hidden and the full name is in the tree (AC-S7)" DT27
    tv_check TV17 "an emptied projection states why; a populated one never renders that row (AC-9)" DT20
    tv_check TV18 "selecting a node reveals its row/unlisted-row, moves no focus, and re-arms on re-selection (AC-S8, FR-14a)" DT22 GT53

    # =======================================================================
    # === TV19/TV20 -- task-033's own load-on-demand window and the
    #     filter-over-full-set property, over a fixture LARGER than one window
    # =======================================================================
    echo ""
    echo "=== TV19/TV20 (task-033) -- windowing, keyboard-only 'Load more', and filter-over-full-set ==="
    set +e
    node "$WINDOW_MJS" "$REPO_ROOT" "${TMP}/window-bundle.mjs" > "${TMP}/window.out" 2>"${TMP}/window.err"
    window_rc=$?
    set -e
    consume < "${TMP}/window.out"
    window_lines=$(grep -cE '^GV.(PASS|FAIL|SKIP)' "${TMP}/window.out" || true)
    if [[ "${window_lines:-0}" -ge 10 ]]; then
        pass "table-view: the task-033 window/filter check reported its assertions ($window_lines outcomes) -- the ground TV19/TV20 cite"
    else
        fail "table-view: the task-033 window/filter check reported its assertions -- only ${window_lines:-0} outcome line(s)"
    fi
    [[ "$window_rc" -ne 0 && "$window_rc" -ne 3 ]] && [[ "${window_lines:-0}" -eq 0 ]] && \
        fail "table-view: the task-033 window/filter check ran to completion -- exit $window_rc, no outcome: $(head -3 "${TMP}/window.err" | tr '\n' ' ')"

    tv_check TV19 "a first window renders; a real, keyboard-operable 'Load more' button (and, as a convenience, scroll) extends it; 'Showing N of M' is correct at every checkpoint (task-033 AC 2, AC 4)" TWC01 TWC02 TWC03 TWC04 TWC05 TWC06 TWC06b TWC06c TWC06c-drain TWC10
    tv_check TV20 "a filter applied with only the first window rendered returns a match from OUTSIDE that window, against a fixture larger than one window, and clearing the filter restores the first page (task-033 AC 3, AC 4)" TWC07 TWC08 TWC09

    # -----------------------------------------------------------------------
    # TV16 -- ROUTED, recorded as a SKIP with the reason, never faked.
    # -----------------------------------------------------------------------
    skip "TV16 containment at 732px, 390px and 200% zoom (AC-9, accessibility-checklist.md:105-106) -- jsdom implements"\
" no layout, so this repository has no static or headless oracle for overflow at a given viewport width. The"\
" only route is the Playwright visual gate (validate-visuals.mjs), which does not yet carry a --profile graph"\
" mode (task-019/task-021). Routed there rather than asserted here or skipped without a named owner."

    # =======================================================================
    # === TV03 -- validate-html-output.sh over the assembled AND booted TABLE
    #     page. graph-view-dom.mjs now assembles/boots BOTH graph.html and
    #     table.html in one run (see that file's own header); this feature's
    #     own subject is the accessible TABLE, so TV03 validates table.html,
    #     not graph.html -- test-graph-view-shell.sh's own GH group is what
    #     validates graph.html.
    # =======================================================================
    if [[ -f "$VALIDATE_HTML" && -f "${TMP}/page/table.html" ]]; then
        echo ""
        echo "=== TV03a/TV03b -- validate-html-output.sh, the two pages that make up 'a generated table.html' ==="
        set +e
        static_out=$(bash "$VALIDATE_HTML" "${TMP}/page/table.html" --kb-dir "${TMP}/page" 2>&1)
        static_rc=$?
        set -e
        [[ "$VERBOSE" -eq 1 ]] && echo "$static_out"
        assert_exit_zero "$static_rc" "TV03a the assembled page passes H1/A1/A4/A5/L1/L2 (AC-9)"
        # table.html's own relative-.md link set is smaller than graph.html's: one
        # distinct target (./relationships.md, linked twice -- the footer and the
        # noscript fallback), not graph.html's three (relationships.md,
        # external-sources.md, INDEX.md). Verified directly against a real run
        # rather than assumed.
        for check in "H1. HTML validity" "A1" "A4" "A5" "L2. 1/1 relative md links resolve"; do
            assert_output_contains "$static_out" "$check" "TV03a assembled page satisfies: $check"
        done

        if [[ -f "${TMP}/page/table-rendered.html" ]]; then
            set +e
            booted_out=$(bash "$VALIDATE_HTML" "${TMP}/page/table-rendered.html" --kb-dir "${TMP}/page" 2>&1)
            booted_rc=$?
            set -e
            [[ "$VERBOSE" -eq 1 ]] && echo "$booted_out"
            # The booted page is the stronger subject -- the table region is JS-built,
            # so a static check of the template alone never sees a cell of it.
            assert_output_contains "$booted_out" "H1. HTML validity" \
                "TV03b the BOOTED page -- the table's own rendered markup -- is valid HTML"
            if [[ "$booted_rc" -eq 0 ]]; then
                pass "TV03b the booted page also passes L1/L2"
            elif grep -q 'bad array subscript' <<< "$booted_out"; then
                # Same known validate-html-output.sh defect test-graph-view-shell.sh
                # routes to feature-011 (an empty id="" substring aborts its bash
                # associative-array key). Not this task's obligation to fix.
                skip "TV03b L1/L2 over the booted page -- validate-html-output.sh's known 'bad array subscript' abort"\
" on a serialized empty attribute (routed to feature-011). The anchor obligation itself is proven by DT30, part of"\
" the DOM half above."
            else
                fail "TV03b the booted page's link checks -- unexpected: $(tail -4 <<< "$booted_out" | tr '\n' ' ')"
            fi
        else
            skip "TV03b -- the DOM half did not produce a booted page (jsdom likely absent)"
        fi
    else
        skip "TV03a/TV03b -- validate-html-output.sh or the assembled page is absent"
    fi

    # =======================================================================
    # === S3: non-vacuity mutation matrix, gated behind --self-mutate =======
    # =======================================================================
    if [[ "$SELF_MUTATE" -eq 1 ]]; then
        echo ""
        echo "=== --self-mutate: D1/D2/D4/emphasis proven to bite against a mutated COPY (never canonical/) ==="
        run_mutation() {
            local id="$1" tv="$2" expect="$3"
            if ! node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/mut-${id}.mjs" "$id" > "${TMP}/mut-${id}.log" 2>&1; then
                fail "$tv self-mutate ${id} -- the mutation did not apply: $(head -2 "${TMP}/mut-${id}.log" | tr '\n' ' ')"
                return
            fi
            set +e
            node "$MODEL_MJS" "${TMP}/mut-${id}.mjs" --expect-fail "$expect" > "${TMP}/mut-${id}.out" 2>&1
            set -e
            local n
            n=$(grep -cE '^GV.(PASS|FAIL)' "${TMP}/mut-${id}.out" || true)
            if [[ "${n:-0}" -eq 0 ]]; then
                fail "$tv self-mutate ${id} -- the control produced no verdict: $(head -2 "${TMP}/mut-${id}.out" | tr '\n' ' ')"
                return
            fi
            # model.mjs --expect-fail emits ITS OWN PASS when the named id DID fail
            # against the mutation (the control held) and FAIL when it did not (the
            # control is broken). So the control's success is model.mjs's PASS line
            # for EVERY named id, not a literal "FAIL" -- inverting this check was
            # this suite's own first non-vacuity bug, caught by actually running it.
            # Every id in the comma list is checked, not just the first: a partial
            # miss (one id of several holds, another does not) is still a failed
            # control and reporting only the first id would hide that.
            local IFS_SAVE="$IFS" all_held=1 missing_id=""
            IFS=','
            for ex in $expect; do
                if ! grep -qE $'^GV\tPASS\t'"${ex} " "${TMP}/mut-${id}.out"; then
                    all_held=0; missing_id="$ex"; break
                fi
            done
            IFS="$IFS_SAVE"
            if [[ "$all_held" -eq 1 ]]; then
                pass "$tv self-mutate ${id} -- ${expect} all fail against the mutated implementation (non-vacuity proven)"
            else
                fail "$tv self-mutate ${id} -- ${missing_id} did NOT fail against the mutated implementation, so this class cannot detect the defect: $(grep -E $'^GV\t' "${TMP}/mut-${id}.out" | tr '\n' ' ')"
            fi
        }
        run_mutation list-collapsed          TV11  GT30,GT31
        # NOTE: graph-view-mutate.mjs's own MUTATIONS catalogue comment documents
        # this mutation's `expect` as 'GT61b,GT63' (its own file, line ~97). That is
        # WRONG: GT61b computes its own independent degree-based set from the
        # fixture and never calls the mutated tblUnlistedNodes() at all, so it
        # cannot fail against ANY implementation defect -- it is a fixture-property
        # check, not a subject assertion. test-graph-view.sh's own GX group already
        # uses the correct pair, GT61,GT63 (GT61 DOES call tblUnlistedNodes()), and
        # this suite follows that proven citation rather than the stale comment.
        # Found by actually running --self-mutate rather than trusting the doc.
        run_mutation unlisted-by-degree       TV12  GT61,GT63
        run_mutation tiebreak-direction       TV10  GT37
        run_mutation sortof-keeps-direction   TV10  GT39
        run_mutation dimmed-either-map        TV13b GT50,GT50b

        # colour-literal is a NEGATIVE CONTROL for TV13a's own grep: no model.mjs
        # run needed, so no extra model invocation counts against the S1 budget.
        node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/poison.mjs" colour-literal >/dev/null 2>&1
        if grep -qE '#[0-9a-fA-F]{3}' "${TMP}/poison.mjs"; then
            pass "TV13a self-mutate colour-literal -- the hex-literal grep fires on a poisoned copy (negative control)"
        else
            fail "TV13a self-mutate colour-literal -- the hex-literal grep did NOT fire on a poisoned copy, so TV13a proves nothing"
        fi
    else
        skip "TV11/TV12/TV10/TV13a/TV13b self-mutate matrix -- run with --self-mutate (S3: gated, not run by default)"
    fi
fi

# ===========================================================================
# === S5: the source tree is untouched by everything above ==================
# ===========================================================================
echo ""
echo "=== S5: the subject on disk is byte-identical to HEAD after every mutation above ==="
if git -C "$REPO_ROOT" diff --quiet -- "$TABLE_JS" 2>/dev/null; then
    pass "S5 canonical/.../graph-table.js is byte-identical to HEAD -- every mutation above ran on a mktemp -d copy"
else
    fail "S5 canonical/.../graph-table.js differs from HEAD -- a mutation escaped its copy"
fi

# ===========================================================================
# === S1 budget self-check -- the wrapper-multiplicity trap named in this task
#
# A raw `grep -c 'node "$MUTATE_MJS"'` UNDERCOUNTS here: run_mutation() is a
# WRAPPER around one node call, invoked five times below, so its own body is
# one textual call site standing for five runtime invocations -- exactly the
# "43 reject call sites counted as 1" trap this task names. So the wrapper's
# own CALL sites are counted (run_mutation \S), not its internal node line.
# ===========================================================================
SELF="${SCRIPT_DIR}/test-graph-table-view.sh"
run_mutation_calls=$(grep -cE '^\s+run_mutation\s+\S' "$SELF" || true)
mutate_toplevel=$(grep -c 'node "\$MUTATE_MJS" "\$REPO_ROOT" "\${TMP}/bundle.mjs" none' "$SELF" || true)
mutate_poison=$(grep -c 'node "\$MUTATE_MJS" "\$REPO_ROOT" "\${TMP}/poison.mjs" colour-literal' "$SELF" || true)
model_toplevel=$(grep -c 'node "\$MODEL_MJS" "\${TMP}/bundle.mjs" >' "$SELF" || true)
dom_toplevel=$(grep -c 'node "\$DOM_MJS" "\$REPO_ROOT"' "$SELF" || true)
validate_sites=$(grep -c 'bash "\$VALIDATE_HTML"' "$SELF" || true)
mutate_total=$((mutate_toplevel + run_mutation_calls + mutate_poison))
model_total=$((model_toplevel + run_mutation_calls))
echo "  NOTE: S1 budget, counting WRAPPER CALL SITES (run_mutation invoked $run_mutation_calls times), not its"\
" internal node line -- mutate.mjs: $mutate_toplevel top-level + $run_mutation_calls via run_mutation + $mutate_poison"\
" poison-only = $mutate_total total when --self-mutate; model.mjs: $model_toplevel top-level + $run_mutation_calls via"\
" run_mutation = $model_total total when --self-mutate; dom.mjs: $dom_toplevel; validate-html-output.sh: $validate_sites."\
" Default run (no --self-mutate) cost = $mutate_toplevel(mutate)+$model_toplevel(model)+$dom_toplevel(dom)+$validate_sites(validate)."\
" This matches the header's declared 5 default / 16 with --self-mutate exactly when run_mutation_calls=5."
if [[ "$run_mutation_calls" -ne 5 ]]; then
    fail "S1-budget the header's declared --self-mutate cost assumed run_mutation is called 5 times; it is called $run_mutation_calls times -- the header's arithmetic is stale, fix the comment"
else
    pass "S1-budget run_mutation is called exactly 5 times, matching the header's declared --self-mutate arithmetic"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
if [[ "$SKIP" -gt 0 ]]; then
    echo "=== Skipped (not run, and not counted as passes) ==="
    echo "  Tests skipped: $SKIP"
    for s in "${SKIPPED[@]}"; do echo "  - $s"; done
    echo ""
fi
test_summary
exit $?
