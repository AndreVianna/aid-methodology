#!/usr/bin/env bash
# test-graph-canvas.sh -- feature-008's drawing rendering: a draw-record
# conformance suite, asserted against D3's published record
# (window.__aidGraphCanvas), never against pixels or a screenshot.
#
# SCOPE, NARROWED MID-TASK BY OWNER DIRECTION (task-018, work-005 delivery-001)
#   The first pass of this file authored the full GC01-GC19 series the SPEC
#   names. Running it found, empirically, that every one of those nineteen
#   assertions -- AS THE SPEC WORDS THEM -- can pass while a real page draws
#   nothing visible: `nodes` equalling `visibleNodes` says nothing about
#   whether a mark is ON SCREEN, and `mode: 'live'` with `positions` changing
#   between frames says nothing about WHERE those positions land. A human
#   opening a real page in real Chromium found exactly that: a live,
#   ticking, correctly-derived canvas drawing every mark at the wrong place
#   because the layout is centred on the coordinate ORIGIN while PixiJS
#   treats (0,0) as the drawing buffer's TOP-LEFT CORNER, and the stage is
#   never translated to compensate (graph-canvas.js:628, :988, verified on
#   disk). The owner's ruling: keep this file a DRAW-RECORD CONFORMANCE
#   layer -- cheap, headless, and honest about what it cannot see -- and move
#   every visual truth to tests/ui/ (Playwright, real Chromium, NOT in this
#   required suite; see graph-canvas.ui.spec.mjs alongside this file's own
#   commit).
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# COVERS: canonical/aid/templates/knowledge-graph/graph-canvas.js
# COVERS: canonical/aid/templates/knowledge-graph/graph-model.js
# COVERS: canonical/aid/templates/knowledge-graph/graph-controls.js
# COVERS: canonical/aid/templates/knowledge-graph/graph-table.js
# COVERS: canonical/aid/templates/knowledge-graph/graph-skeleton.html
# COVERS: canonical/aid/templates/knowledge-graph/graph-css.css
#
# WHAT THIS SUITE KEEPS, AND WHY EACH SURVIVED THE NARROWING
#   GC09  The mounted canvas's attribute set is EXACTLY role/aria-label/
#         width/height (AC-S8) -- a DOM-property read, not a visual judgement,
#         and the ONE surviving check of "no control on the canvas, no tab
#         stop" now that task-032 removes the viewport button manifest GC12
#         used to bind (GC12 is DEAD; not authored -- see below).
#   GC10  graph-canvas.js's own source: no `.prefix` read, no quoted prefix
#         literal, no load statement, no `canonical/` substring, no filename
#         placeholder, no `lens` member beyond `.zoom` and `.spacing` (the one
#         physics parameter FR-14a permits, added 2026-08-07), no `matchMedia`
#         call; and the record's `nodes`/`edges`/`revision` equal the
#         ViewModel's own sets (AC-10, AC-S1, AC-S2).
#   GC13  Every mark's content compared against the ViewModel entry for ITS
#         OWN id/key -- never a sibling field of itself -- over the fixture's
#         ext: pair (feature-007 AC-S3: same prefix, different Kind). This and
#         GC10 are Q17/Q21's own test: the founding defect class this whole
#         SPEC's history traces to, and the reason a same-record
#         self-consistency check is not enough (NFR-5, NFR-3, AC-S4's colour
#         half is also here).
#   GC17  Zero ARIA/live-region writes, zero getComputedStyle, zero
#         getBoundingClientRect FROM THE FRAME PATH (AC-S5) -- exact call
#         counts around one forced repaint; a screenshot cannot see this at
#         any cost, a counter sees it exactly.
#   GC19  Both unavailability paths (library absent, no WebGL context) plus
#         the late-failure transition (mount succeeds, `renderer.init()`
#         rejects afterwards -- ledger row 4, a SECOND, DISTINCT route to the
#         same end state) converge on: `mode: 'unavailable'`, exactly one
#         `console.warn` with the stable prefix, exactly two live regions, the
#         table present and populated (AC-S10).
#   GC21bounds  THE ONE ASSERTION ADDED THIS PASS, and the most valuable thing
#         in this file: every drawn node's position, mapped through the
#         recorded `viewport` and the buffer's own width/height by
#         `gcLocalPoint`'s own documented inverse, must land inside the
#         drawing buffer. Cheap, headless, and the exact shape of the real
#         defect above. VERIFIED STILL PRESENT ON DISK -- this assertion is
#         EXPECTED TO FAIL against the current module, and this suite reports
#         that as a real, named finding rather than adjusting the check to
#         pass it. Not a SPEC-numbered `GC*` id (the SPEC's own series stops at
#         nineteen); named for what it asserts rather than squatting a
#         `GC20`/`GC21` this SPEC never claims.
#
# WHAT WAS DROPPED, AND WHY (owner's mid-task correction; default is drop)
#   GC01/GC03/GC08 (motion, drag, settle-vs-live) -- proving a bitmap MOVES
#     needs the bitmap; simulating real physics headlessly to watch a
#     `positions` value change proves nothing about whether the moved mark
#     was ever inside the buffer, which is the finding that mattered.
#   GC02 (hover), GC18 (click/dblclick/wheel) -- both need a synthetic pointer
#     to hit a node at its DRAWN screen position, exactly the coordinate space
#     the real defect shows this file cannot trust without a browser's layout.
#   GC04 (frame-instrumentation shape) -- `frames` populated with tickMs/
#     drawMs samples is true from a RING BUFFER SATURATED AT 240 regardless of
#     whether anything is visible (the owner's own example of the class); AC-6a's
#     figure is feature-002's regardless.
#   GC05/GC06/GC07 (presets, filters, category encoding by value), GC11 (gap
#     badges), GC14 (forced-colours channels), GC15 (fold endpoints/parallel
#     rows), GC16 (exact-identity at rest) -- real obligations, reachable
#     headlessly, none as cheap/load-bearing as the kept set, and the
#     instruction is to default to dropping rather than keep every provable
#     thing. Flagged here rather than silently lost.
#   GC12 -- DEAD. task-032 SS E removes all seven viewport buttons (zoom-in/
#     out/fit, pan-left/right/up/down); the control this hook names will not
#     exist. Not authored.
#
# TWO HARD FACTS THAT SHAPE WHAT IS ASSERTED (owner correction, mid-task)
#   * `record.viewport` currently MISREPORTS after a committed gesture (a
#     zoom-only `setLens` notification runs `gcDrawFrame` alone, which never
#     writes `view.record.viewport` -- only `frames[].applied` does). No
#     assertion here reads `record.viewport` as a post-gesture signal for that
#     reason (ledger row 11, task-032 SS C) -- deferred until fixed.
#   * `frames.length` is a RING, saturated at 240, and is never read here as a
#     repaint signal: it proves nothing about whether a NEW frame was drawn
#     once the ring is full. GC17's forced-repaint proof reads a
#     getComputedStyle call COUNT instead, never the frame count.
#
# S1 BUDGET (subject-script invocations, wrapper bodies counted once per call
# site -- graph-view-mutate.mjs's bundling call and graph-canvas-dom.mjs's own
# assertion run, each ONE call site in this file):
#   DEFAULT (no args): 2 subject-script invocations --
#     node graph-view-mutate.mjs   (builds the plain, unmutated 5-file bundle)  x1
#     node graph-canvas-dom.mjs    (every kept GC/GC21bounds assertion)         x1
#   --self-mutate ADDS 6 more (3 mutation cases x 2 calls each: one mutate.mjs
#   build, one graph-canvas-dom.mjs --expect-fail run) -- 8 total with it.
#   No other subprocess is spawned; the bundle built by the default run's own
#   mutate.mjs call is REUSED by nothing else in this file (the mutation cases
#   each need their OWN mutated bundle, which is the point of building it).
#
# S3: every case in the GX (--self-mutate) mutation matrix is a subprocess
# spawn (two node invocations per case) and is gated behind --self-mutate --
# each rebuilds a mutated bundle and re-runs the full assertion file against
# it, matching the ~1-3s class this repo's sibling suites already gate the
# same way (test-graph-view-shell.sh's own GX/DX matrix). Nothing in the
# DEFAULT run is a mutation case.
#
# ANTI-VACUITY (this file's own founding concern, restated as a control): the
# GX matrix's three cases prove the kept assertions can FAIL against a
# deliberate defect --
#   canvas-old-renderer-symbol reproduces the HISTORICAL DEFECT ITSELF (ledger
#     row 4): reverting ONLY the `new PIXI.Renderer()` construction (never the
#     capability probe, which stays `WebGLRenderer`) makes every real mount
#     fall into `gcMountUnavailable` -- the exact "capability check passes,
#     construction always throws" shape this file's whole history is about.
#     Every mounted-page GC09/GC10/GC13/GC17/GC21bounds clause must go red.
#   canvas-prefix-glyph derives a node's glyph from its identifier PREFIX
#     instead of the ViewModel -- Q21's proxy class. GC13 must go red,
#     decisively on the fixture's ext: pair (same prefix, different Kind).
#   canvas-tab-stop adds an authored `tabindex` to the created canvas -- GC09
#     must go red.
# See graph-view-mutate.mjs's MUTATIONS map for the exact patterns.
#
# WHAT THIS SUITE CANNOT SEE, ON PURPOSE
#   Whether anything is actually painted, positioned relative to a reader's
#   eye, or reachable by a real click -- `tests/ui/graph-canvas.ui.spec.mjs`
#   (Playwright, real Chromium) covers those, is NOT in this required suite
#   (project rule: runtime UI checks stay outside tests/canonical/), and is run
#   on demand.
#
# RUNTIMES
#   node   required. Absent -> every GC class SKIPS loudly.
#   jsdom  optional, resolved by bare specifier or AID_GRAPH_JSDOM. Absent ->
#          every GC class SKIPS loudly (graph-canvas-dom.mjs's own convention).
#
# Usage:
#   bash test-graph-canvas.sh [-v | --verbose] [--self-mutate]
#
# Exit codes:
#   0 -- all assertions passed (skips are reported, never counted as passes)
#   1 -- one or more assertions failed
#   2 -- an unknown argument was given

set -u

VERBOSE=0
SELF_MUTATE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)  VERBOSE=1; shift ;;
        --self-mutate) SELF_MUTATE=1; shift ;;
        *) echo "test-graph-canvas.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

GRAPH_DIR="${REPO_ROOT}/canonical/aid/templates/knowledge-graph"
CANVAS_JS="${GRAPH_DIR}/graph-canvas.js"
MODEL_JS="${GRAPH_DIR}/graph-model.js"
CONTROLS_JS="${GRAPH_DIR}/graph-controls.js"
TABLE_JS="${GRAPH_DIR}/graph-table.js"
SKELETON="${GRAPH_DIR}/graph-skeleton.html"
GRAPH_CSS="${GRAPH_DIR}/graph-css.css"
PREDICATE="${REPO_ROOT}/canonical/aid/scripts/graph/coverage-predicate.mjs"

MUTATE_MJS="${SCRIPT_DIR}/graph-view-mutate.mjs"
DOM_MJS="${SCRIPT_DIR}/graph-canvas-dom.mjs"

for f in "$CANVAS_JS" "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS" "$SKELETON" "$MUTATE_MJS" "$DOM_MJS"; do
    assert_file_exists "$f" "GS present: ${f#${REPO_ROOT}/}"
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HAVE_NODE=0
command -v node >/dev/null 2>&1 && HAVE_NODE=1

consume() {
    local line kind label
    while IFS= read -r line; do
        [[ "$line" == GC$'\t'* ]] || { [[ "$VERBOSE" -eq 1 ]] && echo "$line"; continue; }
        kind="${line#GC$'\t'}"; kind="${kind%%$'\t'*}"
        label="${line#GC$'\t'*$'\t'}"
        case "$kind" in
            PASS) pass "$label" ;;
            FAIL) fail "$label" ;;
            SKIP) skip "$label" ;;
            NOTE) echo "  NOTE: $label" ;;
        esac
    done
}

# ===========================================================================
# The default run: one bundle, one assertion pass over it
# ===========================================================================
if [[ "$HAVE_NODE" -eq 0 ]]; then
    skip "GC** the whole suite — node is not on PATH"
else
    echo ""
    echo "=== Building the 5-file bundle (predicate+model+controls+table+canvas) ==="
    set +e
    GRAPH_BUNDLE_INCLUDE_CANVAS=1 node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" none > "${TMP}/bundle.log" 2>&1
    build_rc=$?
    set -e
    if [[ "$build_rc" -ne 0 ]]; then
        fail "GC00 the 5-file bundle builds — exit $build_rc: $(tail -3 "${TMP}/bundle.log" | tr '\n' ' ')"
    else
        pass "GC00 the 5-file bundle builds ($(grep -oE 'lines=[0-9]+' "${TMP}/bundle.log" | head -1))"

        echo ""
        echo "=== GC09/GC10/GC13/GC17/GC19/GC21bounds: the kept draw-record conformance set ==="
        set +e
        AID_GRAPH_JSDOM="${AID_GRAPH_JSDOM:-}" node "$DOM_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" "${TMP}/page" > "${TMP}/dom.out" 2>"${TMP}/dom.err"
        dom_rc=$?
        set -e
        consume < "${TMP}/dom.out"
        if [[ "$dom_rc" -ne 0 && "$dom_rc" -ne 1 && "$dom_rc" -ne 3 ]] && ! grep -q $'\tFAIL\t' "${TMP}/dom.out"; then
            fail "GC00b the assertion run completed — exit $dom_rc with no reported failure: $(head -3 "${TMP}/dom.err" | tr '\n' ' ')"
        fi
        # A helper emitting NOTHING would contribute no assertion at all -- a
        # silent pass wearing a green suite. Positive floor, well below the
        # current count, fires on a collapse and never on growth.
        dom_lines=$(grep -cE $'^GC\t(PASS|FAIL|SKIP)\t' "${TMP}/dom.out" || true)
        if [[ "${dom_lines:-0}" -ge 15 ]]; then
            pass "GC00c the assertion run reported its outcomes ($dom_lines outcome lines)"
        else
            fail "GC00c the assertion run reported its outcomes — only ${dom_lines:-0} outcome line(s), so most of the suite did not run"
        fi
    fi

    # =======================================================================
    # GX: the anti-vacuity mutation matrix (--self-mutate only, S3)
    # =======================================================================
    echo ""
    echo "=== GX: each kept assertion class is shown to FAIL against a deliberate defect ==="
    run_mutation() {
        local id="$1" expect="$2"
        set +e
        GRAPH_BUNDLE_INCLUDE_CANVAS=1 node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/mut-${id}.mjs" "$id" > "${TMP}/mut-${id}.build.log" 2>&1
        local mut_rc=$?
        set -e
        if [[ "$mut_rc" -ne 0 ]]; then
            fail "GX ${id} — the mutation did not apply: $(head -2 "${TMP}/mut-${id}.build.log" | tr '\n' ' ')"
            return
        fi
        set +e
        node "$DOM_MJS" "$REPO_ROOT" "${TMP}/mut-${id}.mjs" "${TMP}/mut-page-${id}" --expect-fail "$expect" > "${TMP}/mut-${id}.out" 2>&1
        local run_rc=$?
        set -e
        consume < "${TMP}/mut-${id}.out"
        local n
        n=$(grep -cE '^GC.(PASS|FAIL|NOTE)' "${TMP}/mut-${id}.out" || true)
        if [[ "${n:-0}" -eq 0 ]]; then
            fail "GX ${id} — the control produced no verdict: $(head -2 "${TMP}/mut-${id}.out" | tr '\n' ' ')"
        elif [[ "$run_rc" -ne 0 ]]; then
            fail "GX ${id} — expected id(s) [$expect] did not all fail against the mutated bundle: $(grep FAIL "${TMP}/mut-${id}.out" | head -2 | tr '\n' ' ')"
        fi
    }
    if [[ "$SELF_MUTATE" -ne 1 ]]; then
        echo "Mutation matrix not run. Use --self-mutate to run it (6 extra subprocess spawns: 3 cases x 2 calls each)."
    else
        run_mutation canvas-old-renderer-symbol "GC09,GC10,GC13,GC21bounds"
        run_mutation canvas-prefix-glyph        "GC13"
        run_mutation canvas-tab-stop            "GC09"
    fi
fi

# ===========================================================================
# S5: the source tree is untouched -- every mutation happened on a copy
# ===========================================================================
echo ""
echo "=== S5: this run's own subject files are byte-identical to HEAD afterwards ==="
S5_SUBJECTS=("$CANVAS_JS" "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS" "$SKELETON" "$GRAPH_CSS" "$PREDICATE")
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    s5_out=$(git -C "$REPO_ROOT" diff --name-only -- "${S5_SUBJECTS[@]}" 2>&1)
    if [[ -z "$s5_out" ]]; then
        pass "S5 every subject file this suite reads is byte-identical to HEAD after the run — every mutation happened on a copy under \$TMP, never on the source tree"
    else
        fail "S5 the source tree changed during this run — modified: $(echo "$s5_out" | tr '\n' ' ') — NOTE: expected to fail while another task's work is uncommitted; not this suite's own defect"
    fi
else
    skip "S5 — git is not available, so the untouched-tree proof could not be run"
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
