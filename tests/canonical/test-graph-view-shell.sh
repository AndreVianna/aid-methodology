#!/usr/bin/env bash
# test-graph-view-shell.sh -- feature-007's graph view shell: the concatenation
# boundary, the D10 shared coverage predicate across two runtimes, the shell's
# projection and table rendering, and the rendered DOM.
#
# RENAMED from test-graph-view.sh (task-014, work-005 delivery-001). The prior
# GC01-GC04 concatenation-oracle ids are renamed CAT01-CAT04 below to free the
# GC* prefix for feature-008's own suite (task-018); GS*, GT*, GX*, DT* and GH*
# keep their ids unchanged. This is a coverage-parity RE-HOME event, not a
# removal: see the task-014 hand-off for the before/after inventory `comm` proof.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# A trailing slash means the directory and everything under it. Omitting the
# header entirely is fail-safe (the suite is then always selected); a WRONG
# entry is the only way to lose coverage, so these are reviewed as claims.
# COVERS: canonical/aid/templates/knowledge-graph/
# COVERS: canonical/aid/scripts/graph/coverage-predicate.mjs
# COVERS: canonical/aid/scripts/graph/build-graph-src.mjs
# COVERS: canonical/aid/scripts/graph/render-graph-view.sh
# COVERS: canonical/aid/templates/graph/coverage-bearing.yml
# COVERS: canonical/aid/scripts/summarize/validate-html-output.sh
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh), so adding
# this suite needed no runner or workflow edit. select-suites.sh keys on the
# COVERS entries above, not on this file's own name, so the rename needed no
# edit there either.
#
# SUBJECT
#   canonical/aid/scripts/graph/coverage-predicate.mjs          (the shared predicate)
#   canonical/aid/scripts/graph/build-graph-src.mjs              (task-013's real producer)
#   canonical/aid/scripts/graph/render-graph-view.sh              (task-013's driver)
#   canonical/aid/templates/knowledge-graph/graph-model.js      (loader, projection, store)
#   canonical/aid/templates/knowledge-graph/graph-controls.js   (the shell)
#   canonical/aid/templates/knowledge-graph/graph-table.js      (the accessible table)
#   canonical/aid/templates/knowledge-graph/graph-skeleton.html (the page)
#
#   The four .js/.mjs files under knowledge-graph/ plus the predicate are
#   concatenated into ONE inline module block in the generated page, which is
#   what makes the first group below the cheapest high-value check in this
#   suite: a single duplicated top-level name across them is a SyntaxError and
#   the page does not run at all.
#
# GROUPS
#   GS   Static source properties -- no load statement, no network call, no
#        colour literal, no motion, no shell control attribute, and the page's
#        own table-first DOM order and two-live-region count.
#   GV   feature-007 SPEC's own numbered design-decision assertions (D10's
#        shared-predicate/two-runtime group). All 28 ids are now authored -- see
#        "STAGE 4" below for the four that closed last (GV17, GV19, GV22, GV24).
#   BLD  task-013's two previously-ownerless files (build-graph-src.mjs,
#        render-graph-view.sh): the real placeholder set matches the skeleton's
#        own, derived from both files at run time (BLD01), and the real
#        end-to-end render leaves zero surviving {{...}} in graph.html (BLD02).
#   CAT  The concatenation oracle (renamed from GC): each file parses alone AND
#        the four view files parse as one module. CAT04 is its negative
#        control -- a bundle with a duplicated top-level name must be REJECTED.
#   GT   The shell's projection and the table's row set, order, emphasis and
#        unlisted-node derivation, asserted headless (graph-view-model.mjs). No DOM.
#   GX   NON-VACUITY CONTROLS. A copy of the four files is mutated, one
#        deliberate defect at a time, and the GT assertions named for that
#        defect must FAIL. Nothing under canonical/ is touched (S5).
#   DT   The rendered DOM: markup, the keyboard drive, the reveal, determinism
#        (graph-view-dom.mjs). SKIPS LOUDLY, class by class, when jsdom cannot
#        be resolved -- jsdom is not a repository dependency and no assertion
#        here is ever allowed to degrade into a pass.
#   GH   validate-html-output.sh over the assembled page and over the BOOTED
#        page, the latter being the markup a reader actually receives.
#
# AC-15 and AC-7, THE SHELL HALVES THIS SUITE OWNS
#   AC-15 (the shared predicate, one implementation, two runtimes): this suite
#   carries the SHELL half (GV01-GV05, GV02's real-render form, CAT group) --
#   feature-006 (the Node-side detector and ledger) is the other named co-owner.
#   AC-7 (every control usable after every preset / peer rendering, never
#   disabled): this suite's GS/GT/DT groups carry the STRUCTURAL half (table
#   peer to the graph, DOM order, live regions); feature-008 (the drawing
#   surface and its viewport controls) and feature-009 (the table's own control
#   surface) are the other named co-owners. Neither AC is closed by this file
#   alone.
#
# OPEN, NOT AUTHORED -- task-014 STAGE 2 (the fixture layer landed; a residue did
# not, honest boundary rather than a silent gap)
#   graph-view-gv.mjs is the shell-level LensState/CONTROL_MANIFEST fixture layer
#   the first pass deferred. It authors GV06, GV07, GV08, GV09, GV10, GV11, GV12,
#   GV14, GV15, GV18, GV20, GV21, GV23a, GV25, GV26 and GV27, headless, with NO
#   DOM. GV23b was authored as a REAL FAIL: render-graph-view.sh printed no
#   console summary naming its runtime prerequisites at all, so only the
#   footer (GV23a) carried them -- production work outside a TEST task's
#   authority to fix, routed rather than muted. task-031 closed that gap
#   (build-graph-src.mjs, its own generator, now prints the same four facts
#   the footer carries); GV23b passes unedited -- see the GV23 block in
#   graph-view-gv.mjs.
#   STAGE 3 (this pass) authors GV13, GV16 and GV28, the three ids that were
#   unasserted but not blocked:
#     GV13 -- reads graph-css.css and drives contrast-check.mjs --profile graph
#       over a REAL assembled fixture (component-css.css + graph-css.css). Found
#       a REAL, VERIFIED defect in contrast-check.mjs's own `:root` fallback
#       extraction (see the GV13 block's NOTE) -- production work outside this
#       test task's owned files, routed rather than muted, exactly like GV23b's
#       gap. GV13 therefore asserts token COMPLETENESS/DISCOVERABILITY, never the
#       checker's pass/fail verdict, which is test-validator-profiles.sh's to own.
#     GV16 -- reads relationship-schema.yml and calls buildControlManifest (the
#       builder the published CONTROL_MANIFEST name actually is -- see
#       graph-controls.js's own doc comment). Two in-process scratch bundles (never
#       graph-view-mutate.mjs, outside this task's two files) prove the coverage
#       checks bite: one grows the category vocabulary by one entry, one drops
#       the manifest's provenance-axis loop.
#     GV28 -- a dedicated small CONNECTED fixture (never FX.FIXTURE, whose one
#       gap node is degree-0 and therefore unreachable by any focus ball), so a
#       live selection elsewhere still keeps every other gap id inside the ball.
#   CLOSED IN THE FIX PASS (task-014 review row 6/7): GV18's concept
#   defining-document (@doc) route and its fallback tie-break over two
#   equal-rank candidates, and GV20's two label-collision sub-clauses, are now
#   asserted over dedicated fixtures built inline in graph-view-gv.mjs (never in
#   the shared graph-view-fixture.mjs). Neither id carries an in-line NOTE
#   disclosing a gap any more.
#   STAGE 4 (task-014, closing the four that STAGE 3 left "STILL OPEN" behind a
#   "needs a real DOM" classification cited to tech-debt W5-9) -- the premise was
#   RE-VALIDATED against disk evidence rather than accepted, and did not survive:
#   jsdom 29.1.1 IS present on this machine, vendored at `site/node_modules/jsdom`
#   for the site build, and IS resolvable to this suite via the `AID_GRAPH_JSDOM`
#   override `graph-view-dom.mjs` already documents (see that file's own header).
#   W5-9 is RESOLVED and removed on that finding (`.aid/knowledge/tech-debt.md`
#   changelog, 2026-08-06) -- what remains open is narrower and CI-shaped (nothing
#   sets `AID_GRAPH_JSDOM` in `.github/workflows/test.yml`, and `site/node_modules/`
#   is not guaranteed present on a fresh clone), not a "the harness cannot express
#   this" gap. Two of the four were additionally OVER-SCOPED by STAGE 3's own
#   classification, and are corrected here rather than merely unblocked:
#     GV19 needs NO DOM at all. Its authority is `rel_slug_heading`, a bash
#       function in feature-003's own relationship-schema.sh, invoked as a real
#       subprocess over a self-authored fixture document (S5) -- never a second,
#       JS-side copy of D2a-1. Authored headless in graph-view-gv.mjs.
#     GV22 -- every clause but ONE is a plain GraphModel/ViewModel property
#       (foldedInto, groups[].foldable/expanded, edgeFold, counts, the
#       focus-through-the-fold precedence, and the absence of any fold under the
#       four other dimensions), needing neither a page nor jsdom, and is authored
#       headless as GV22a in graph-view-gv.mjs -- the SAME split GV23 already
#       uses. Only the data-group-toggle bijection is truly DOM-shaped; it is
#       GV22b in graph-view-dom.mjs.
#   GV17 and GV24 are genuinely DOM-shaped as STAGE 3 said, and are now authored
#   in graph-view-dom.mjs (GV17a-d, GV24), gated behind the SAME jsdom SKIP the
#   file's pre-existing DT ids already use -- see that file's own header for the
#   ids and CLASSES list. All six new ids were shown, during authorship, to fail
#   against a deliberate mutation (a disabled control handler in a scratch copy of
#   graph-controls.js, an orphan data-control/data-group-toggle attribute, a
#   wrong-key expandedGroups write caught in this very pass, and a mutated
#   `## Contents` fragment).
#   Owner: the file is now closed against all 28 GV ids; the CI-wiring residual
#   named above is a candidate for its own tech-debt row if the owner wants one
#   tracked, not silently opened here.
#
# AC-TO-ASSERTION MAP (feature-007-graph-view-shell/SPEC.md § Tests)
#   GV01 -> D10 rules 1-3,5; AC-10   (predicate + view files: no load statement,
#                                     no host global, no canonical/ path, none
#                                     of the three filename placeholders)
#   GV02 -> D10                      (byte-identity of the inlined predicate
#                                     region, asserted over a REAL render-graph-
#                                     view.sh output -- piggybacked on BLD02)
#   GV03 -> D10                      (bare-Node import binds RELATION_CATEGORY;
#                                     detectArtifactGaps' exact expected set)
#   GV04 -> D10                      (COVERAGE_BEARING == coverage-bearing.yml)
#   GV05 -> D10                      (COVERAGE_BEARING subseteq keys(RELATION_CATEGORY))
#   BLD01 -> AC-10 (task-013 hand-off)  (producer's placeholder set == skeleton's,
#                                        both derived at run time)
#   BLD02 -> AC-10 (task-013 hand-off)  (render-graph-view.sh end to end; zero
#                                        surviving {{...}} in the real graph.html)
#   CAT01-CAT04 -> AC-15 infra (renamed from GC01-GC04; see rename note above)
#   GS01-GS07 -> NFR-2, AC-9, D5a/b (as in the pre-rename suite)
#   GT*, GX*, DT*, GH* -> feature-009's row/order/emphasis contract and the
#     page's structural/a11y/link checks (as in the pre-rename suite)
#   GV06-GV12, GV14, GV15, GV18, GV20, GV21, GV23a, GV25-GV27 -> see the table at
#     feature-007 SPEC.md:1795-1822 for the criterion each binds; asserted by
#     graph-view-gv.mjs over the fixture layer it builds (D1c, D6a-D9 per id).
#   GV23b -> AC-6 (asserted; PASSES since task-031 -- see graph-view-gv.mjs)
#   GV13 -> AC-S4  (token completeness/discoverability over the REAL graph-css.css
#                   + a REAL contrast-check.mjs --profile graph run; no colour
#                   literal in graph-canvas.js/graph-model.js; see graph-view-gv.mjs)
#   GV16 -> AC-S7  (CONTROL_MANIFEST's coverage over categories/kinds/provenance/
#                   presets; the KIND_ENCODING/PROVENANCE_VALUES <-> relationship-
#                   schema.yml lockstep; see graph-view-gv.mjs)
#   GV28 -> D4, D6d, D6f, D7a  (the five-value nodeEmphasis precedence and the
#                   edge axis's own exhaustion, over a dedicated fixture;
#                   see graph-view-gv.mjs)
#   GV19 -> D7b  (feature-003's D2a-1 slug algorithm, over a REAL subprocess of
#                   rel_slug_heading and a self-authored ## Contents fixture; no
#                   DOM, no jsdom; see graph-view-gv.mjs -- STAGE 4)
#   GV22a -> D6c, FR-13, D8, AC-8  (the fold's model/ViewModel clauses -- headless;
#                   see graph-view-gv.mjs -- STAGE 4)
#   GV22b -> D6c, FR-13, D8, AC-8  (the one DOM-shaped clause: the group-toggle
#                   bijection before/after an expansion; see graph-view-dom.mjs)
#   GV17 -> AC-21, D8, NFR-6  (the CONTROL_MANIFEST<->data-control DOM bijection,
#                   native focusability, keyboard-driven LensState effects, the
#                   viewport handle with/without one, and the group-toggle
#                   presence/operability; see graph-view-dom.mjs, ids GV17a-d)
#   GV24 -> AC-8  (after each of the four presets, every named control class stays
#                   present, enabled and writable; see graph-view-dom.mjs)
#
# S1 BUDGET (one subject invocation per distinct input, enumerated by grepping
# every call site, wrapper bodies counted once PER CALL SITE, not once per
# wrapper definition).
#
# S3: the GX/DX mutation matrix is gated behind `--self-mutate` -- every case in
# it is a subprocess spawn (~10s-class toll), matching the ten sibling graph
# suites (test-graph-extraction.sh, test-graph-gap-ledger.sh, etc.) that already
# gate their own mutation matrix the same way. CAT02/CAT04 are NOT part of that
# matrix and stay unconditional: CAT02 builds the plain concatenated bundle
# every other group in this file consumes (it is not a design-decision mutation
# at all -- its mutation TYPE is "none"), and CAT04 is the concatenation
# oracle's OWN negative control (a duplicated top-level name), needed to prove
# CAT03's `node --check` can fail at all -- not a GX/DX-class defect probe.
# GV13's own non-vacuity pair (below) is likewise UNCONDITIONAL rather than
# gated: each is a single sub-second contrast-check.mjs invocation over one
# small HTML file, not the ~10s-class GX/DX matrix S3 exists to bound, and it
# matches GV23b's own precedent -- a second unconditional subprocess call
# already living inside GV_MJS. GV16's two non-vacuity scratch bundles are
# NOT subprocess spawns at all (a plain in-process `import()` of a freshly
# written temp file, same mechanism GV_MJS itself is loaded by) and so are
# not counted in this budget either way. GV19's three `rel_slug_heading` calls
# (two headings plus one mutated heading, its own non-vacuity proof) ARE
# counted below, on the same footing as GV13's contrast-check.mjs calls --
# each is a real subprocess invocation of a subject outside this suite's own
# four view files, even though (like GV13's) it is sub-second.
#
# DEFAULT (no args) -- 16 subject-script invocations:
#   CAT02, CAT04                                    node MUTATE_MJS   x2
#   GT (model over the plain bundle)                node MODEL_MJS    x1
#   GV06-GV28 fixture layer                         node GV_MJS       x1
#     (GV_MJS itself spawns SIX further subject invocations, counted here as
#     additional call sites rather than folded into the line above:
#       - GV23b drives render-graph-view.sh end to end a SECOND time, over its
#         own fixture, independently of BLD02's run -- see the RENDER_VIEW line
#         below;
#       - GV13 drives contrast-check.mjs --profile graph TWICE -- once over the
#         real assembled palette (component-css.css + graph-css.css) and once
#         over a scratch copy with one extra token added, to prove the
#         "every declared token is found" check actually discriminates. Neither
#         is gated -- see the S3 note above;
#       - GV19 drives feature-003's own rel_slug_heading (relationship-schema.sh)
#         via bash THREE times -- two headings plus one mutated heading, its own
#         non-vacuity proof. Not gated either -- see the S3 note above.)
#   DT01 (--assemble-only)                          node DOM_MJS      x1
#   DT (full DOM run, incl. GV17/GV22b/GV24)        node DOM_MJS      x1
#   GH (static page, booted page)                   bash VALIDATE_HTML x2
#   GV03-GV05                                       node graph-view-predicate-check.mjs x1
#   BLD01/BLD02/GV02 (the suite's own end-to-end render) bash RENDER_VIEW x1
#   GV23b (GV_MJS's own end-to-end render, a second fixture) bash RENDER_VIEW x1
#   GV13 (GV_MJS's two contrast-check.mjs runs)     node CONTRAST_CHECK x2
#   GV19 (GV_MJS's three rel_slug_heading runs)     bash BASH_SLUG x3
#   ------------------------------------------------------------------------
#   TOTAL: 16 subject-script invocations for the default run.
#
# `--self-mutate` ADDS exactly 17 more subprocess spawns (30 total), all inside
# the GX/DX mutation matrix:
#   run_mutation (6 call sites: prefix-encoding, dimmed-either-map,
#     list-collapsed, unlisted-by-degree, tiebreak-direction,
#     sortof-keeps-direction) -- each call site is 1x MUTATE_MJS + 1x MODEL_MJS
#                                                    node             x12
#   GX colour-literal                                node MUTATE_MJS   x1
#   dom_mutation_bites (2 call sites) -- each 1x MUTATE_MJS + 1x DOM_MJS
#                                                    node             x4
#   ------------------------------------------------------------------------
#   TOTAL WITH --self-mutate: 30 subject-script invocations.
#   (GS01-07, GV01 and BLD01's set comparison are plain-text `grep`/`diff`
#   utility spawns over files already on disk -- cheap, and not the ~10s-class
#   toll S1 exists to bound, so they are not counted in this budget, matching
#   the pre-existing GS group's own convention. GV08's profiles/ walk and GV26's
#   graph-controls.js grep are the same class, INSIDE GV_MJS, and are likewise
#   not separately counted.)
#
# WHAT IS DELIBERATELY NOT HERE
#   * No browser check of any kind. Runtime UI verification does not belong in the
#     required suite (`.aid/knowledge/test-landscape.md`), and the browser's own
#     evaluation of the page's inline module block is the one thing only a browser
#     can cover -- so it is stated as uncovered rather than approximated.
#   * No layout assertion (containment at the two gate widths, 200% text zoom).
#     jsdom implements no layout, so a layout claim here would be fiction.
#   * No work-folder path anywhere. Work folders are transient by project rule, so a
#     suite that read one could not survive the folder being pruned; every fixture
#     this suite uses is built by tests/canonical/graph-view-fixture.mjs or written
#     inline under $TMP.
#
# RUNTIMES
#   node      required for GV/BLD/CAT/GT/GX/DT and for assembling the page in GH.
#             Absent -> those classes SKIP loudly; the GS greps still run.
#   jsdom     optional, resolved by bare specifier or from AID_GRAPH_JSDOM (its
#             package entry module). Absent -> the DT classes SKIP loudly.
#   tidy / npx html-validate  optional; validate-html-output.sh degrades to its own
#             regex fallback, which it reports.
#
# Usage:
#   bash test-graph-view-shell.sh [-v | --verbose] [--self-mutate]
#   bash test-graph-view-shell.sh --self-mutate      # + the GX/DX mutation matrix
#
# Exit codes:
#   0 -- all assertions passed (skips are reported, and never counted as passes)
#   1 -- one or more assertions failed
#   2 -- an unknown argument was given

set -u

VERBOSE=0
SELF_MUTATE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)  VERBOSE=1; shift ;;
        --self-mutate) SELF_MUTATE=1; shift ;;
        *) echo "test-graph-view-shell.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

# A skip is NOT a pass. assert.sh has no notion of one, so this suite counts them
# separately, always prints them, and lists them in its own summary. Nothing that
# could not run is ever reported as green.
SKIP=0
SKIPPED=()
skip() { SKIP=$((SKIP + 1)); SKIPPED+=("$*"); echo "  SKIP: $*"; }

PREDICATE="${REPO_ROOT}/canonical/aid/scripts/graph/coverage-predicate.mjs"
GRAPH_DIR="${REPO_ROOT}/canonical/aid/templates/knowledge-graph"
MODEL_JS="${GRAPH_DIR}/graph-model.js"
CONTROLS_JS="${GRAPH_DIR}/graph-controls.js"
TABLE_JS="${GRAPH_DIR}/graph-table.js"
SKELETON="${GRAPH_DIR}/graph-skeleton.html"
GRAPH_CSS="${GRAPH_DIR}/graph-css.css"
VALIDATE_HTML="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-html-output.sh"
BUILD_SRC="${REPO_ROOT}/canonical/aid/scripts/graph/build-graph-src.mjs"
RENDER_VIEW="${REPO_ROOT}/canonical/aid/scripts/graph/render-graph-view.sh"
BEARING_YML="${REPO_ROOT}/canonical/aid/templates/graph/coverage-bearing.yml"

MUTATE_MJS="${SCRIPT_DIR}/graph-view-mutate.mjs"
MODEL_MJS="${SCRIPT_DIR}/graph-view-model.mjs"
GV_MJS="${SCRIPT_DIR}/graph-view-gv.mjs"
DOM_MJS="${SCRIPT_DIR}/graph-view-dom.mjs"
PREDICATE_CHECK_MJS="${SCRIPT_DIR}/graph-view-predicate-check.mjs"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

HAVE_NODE=0
command -v node >/dev/null 2>&1 && HAVE_NODE=1

# Turn one `GV<TAB>KIND<TAB>label` line from a node helper into a real assertion,
# so the counters, the failure list and the coverage inventory all see it.
consume() {
    local line kind label
    while IFS= read -r line; do
        [[ "$line" == GV$'\t'* ]] || { [[ "$VERBOSE" -eq 1 ]] && echo "$line"; continue; }
        kind="${line#GV$'\t'}"; kind="${kind%%$'\t'*}"
        label="${line#GV$'\t'*$'\t'}"
        case "$kind" in
            PASS) pass "$label" ;;
            FAIL) fail "$label" ;;
            SKIP) skip "$label" ;;
            NOTE) echo "  NOTE: $label" ;;
        esac
    done
}

# ===========================================================================
# === GS: static source properties ==========================================
# ===========================================================================

echo ""
echo "=== GS01: the five files the view is built from are present ==="
for f in "$PREDICATE" "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS" "$SKELETON"; do
    assert_file_exists "$f" "GS01 present: ${f#${REPO_ROOT}/}"
done

echo ""
echo "=== GS02: the table rendering declares no load statement and reaches no network ==="
# The view's files are concatenated into one inline module in a page that may be
# opened as a local file, where a relative module cannot be loaded at all. This is
# the greppable half of "renders from relationships.md alone, no second data path".
for pattern in '^import' '^[[:space:]]*import[[:space:]]' 'fetch[[:space:]]*\(' 'XMLHttpRequest' 'import[[:space:]]*\(' 'require[[:space:]]*\('; do
    n=$(grep -cE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "GS02 graph-table.js contains no /$pattern/"
done

echo ""
echo "=== GS03: no colour literal by any route, and no palette token declared ==="
# The palette lives in CSS custom properties so the project's contrast checker can
# read it; a colour VALUE in the rendering would be invisible to that check.
for pattern in '#[0-9a-fA-F]{3}' 'rgba?\(' 'hsla?\(' 'oklch\(' 'color-mix\(' '\-\-gk\-' '\-\-gc\-'; do
    n=$(grep -cE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "GS03 graph-table.js contains no /$pattern/"
done
NAMED_COLOURS='red|green|blue|black|white|gray|grey|yellow|orange|purple|pink|brown'
NAMED_COLOURS="${NAMED_COLOURS}|cyan|magenta|teal|navy|olive|maroon|silver|lime|aqua|fuchsia|currentcolor"
n=$(grep -ciwE "$NAMED_COLOURS" "$TABLE_JS" || true)
assert_eq "$n" "0" "GS03 graph-table.js names no colour, not even in a class name"

echo ""
echo "=== GS04: nothing this rendering drives animates ==="
# The shared stylesheet's own `html { scroll-behavior: smooth }` would animate the
# reveal, so the scroll passes an explicit instant behaviour -- the one route no
# CSS grep reaches.
for pattern in 'smooth' 'transition' 'animation'; do
    n=$(grep -ciE "$pattern" "$TABLE_JS" || true)
    assert_eq "$n" "0" "GS04 graph-table.js contains no /$pattern/"
done
n=$(grep -cE 'scrollIntoView\(' "$TABLE_JS" || true)
assert_eq "$n" "1" "GS04 graph-table.js makes exactly one scroll call"
assert_file_contains "$TABLE_JS" "behavior: 'instant'" "GS04 that one scroll call is instantaneous"

echo ""
echo "=== GS05: the table region emits neither of the shell's control attributes ==="
# This DOM is per projection while the shell's manifest is built once at load, so a
# manifest entry per row would falsify the manifest-to-DOM bijection the moment a
# filter removed a row; a second group disclosure would falsify "exactly one per
# foldable group".
assert_file_not_contains "$TABLE_JS" "data-control=" "GS05 graph-table.js sets no data-control attribute"
assert_file_not_contains "$TABLE_JS" "data-group-toggle" "GS05 graph-table.js sets no data-group-toggle attribute"
assert_file_not_contains "$TABLE_JS" "aria-live" "GS05 graph-table.js creates no third live region"

echo ""
echo "=== GS06: the shell mounts the table FIRST and UNCONDITIONALLY ==="
# The load-order form of "peer rendering, not fallback": the artifact is complete
# on a build where the drawing module is absent.
table_at=$(grep -n "resolveMount('table'" "$CONTROLS_JS" | head -1 | cut -d: -f1)
canvas_at=$(grep -n "resolveMount('canvas'" "$CONTROLS_JS" | head -1 | cut -d: -f1)
if [[ -n "$table_at" && -n "$canvas_at" && "$table_at" -lt "$canvas_at" ]]; then
    pass "GS06 the shell resolves the table rendering before the drawing rendering (lines $table_at < $canvas_at)"
else
    fail "GS06 the shell resolves the table rendering before the drawing rendering — table@${table_at:-none} canvas@${canvas_at:-none}"
fi
assert_file_contains "$TABLE_JS" "registerRendering('table', mountTable)" \
    "GS06 the table rendering registers itself at its own top level"

echo ""
echo "=== GS07: the graph page declares no table region, links to the one that does, and keeps exactly two live regions ==="
# WAS "DOM order is table-first". It cannot be: on 2026-08-06 the owner removed the
# relationship table from this page (the repo's own extraction produced thousands of
# rows, which dominated the page the table existed to support), so there is no table
# region left to come first. Asserting an order between two elements when one of them
# is gone is not a weaker test, it is a test of nothing.
#
# What replaces it is the property that actually protects the reader now. The table
# was this page's CONFORMING ALTERNATE VERSION -- the canvas is visual-only and builds
# no DOM proxy -- so with the table on a separate page (`table.html`, task-033), the
# thing that must hold is that the alternative is REACHABLE FROM HERE. A link is what
# carries that, and a page with no table region AND no link would be the real
# regression this hook now catches.
tr_at=$(grep -n 'data-table-region' "$SKELETON" | head -1 | cut -d: -f1)
if [[ -z "$tr_at" ]]; then
    pass "GS07 the graph skeleton declares no table region (the table lives on its own page)"
else
    fail "GS07 the graph skeleton declares a table region at line $tr_at — the table was removed from this page; either the removal was reverted or a stray mount point returned"
fi
n=$(grep -cE 'href="\./table\.html"' "$SKELETON" || true)
if [[ "$n" -ge 2 ]]; then
    pass "GS07 the graph skeleton links to the accessible table page in $n places (the lede, and the placeholder shown when the drawing surface cannot run)"
else
    fail "GS07 the graph skeleton links to ./table.html only $n time(s) — the conforming alternate version must be reachable from this page both in the lede and from the placeholder"
fi
n=$(grep -cE 'data-status aria-live="polite"' "$SKELETON" || true)
assert_eq "$n" "1" "GS07 the skeleton declares exactly one polite region of the view's own"
n=$(grep -cE 'role="alert"' "$SKELETON" || true)
assert_eq "$n" "1" "GS07 the skeleton declares exactly one alert region"
# The view's contract is "exactly two live regions and no more". The skeleton in
# fact carries a THIRD, `aria-live="polite"` on the reused lightbox caption inside
# the aria-hidden dialog. The true state is asserted -- the two the view owns exist
# exactly once each, the table region adds none (GS05), and the total is pinned at
# three so a fourth would fail -- and the discrepancy is named rather than encoded
# as if the contract already held.
n=$(grep -cE 'aria-live' "$SKELETON" || true)
assert_eq "$n" "2" "GS07 the skeleton carries exactly two aria-live attributes: the view's status line and the reused lightbox caption"
echo "  NOTE: feature-007's \"exactly two live regions and no more\" counts the view's own two; the reused"
echo "        lightbox caption (id=lb-caption, inside the aria-hidden dialog) is a third aria-live region in"
echo "        the same skeleton. The clause needs that qualifier; nothing in the table rendering adds one."
assert_file_contains "$GRAPH_CSS" ".table-region { order: 2; min-width: 0; }" \
    "GS07 the visual order is set in the stylesheet, not in the markup"

# ===========================================================================
# === GV01: the D10 boundary rules, greppable (predicate + view files) =====
# ===========================================================================

echo ""
echo "=== GV01: coverage-predicate.mjs obeys the Node/browser boundary rules; the view's own ==="
echo "===       .js files declare no load statement (D10 rules 1-3,5; AC-10) ==="
for pattern in '\bimport\b' 'require[[:space:]]*\(' 'node:' 'document\.' 'window\.' 'globalThis\.' 'canonical/' \
    '\{project_context_file\}' '\{reviewer_output_file\}' '\{open_questions_file\}'; do
    n=$(grep -cE "$pattern" "$PREDICATE" || true)
    assert_eq "$n" "0" "GV01 coverage-predicate.mjs contains no /$pattern/"
done
for f in "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS"; do
    for pattern in '^import' '^[[:space:]]*import[[:space:]]' 'fetch[[:space:]]*\(' 'XMLHttpRequest' 'import[[:space:]]*\('; do
        n=$(grep -cE "$pattern" "$f" || true)
        assert_eq "$n" "0" "GV01 ${f#${REPO_ROOT}/} contains no /$pattern/"
    done
done

# ===========================================================================
# === GV03-GV05: the bare-Node import, and the two doc<->code lockstep =====
# ===========================================================================

echo ""
echo "=== GV03-GV05: the predicate imports cleanly in bare Node; the two containments ==="
if [[ "$HAVE_NODE" -eq 0 ]]; then
    skip "GV03-GV05 the predicate import and the doc<->code containments — node is not on PATH"
    skip "GV02, BLD01, BLD02 — node is not on PATH, so neither the real producer nor its driver could run"
    skip "CAT01-CAT04 the concatenation oracle — node is not on PATH, so no parse was attempted"
    skip "GT** the headless projection and table assertions — node is not on PATH"
    skip "GX** the non-vacuity mutation controls — node is not on PATH"
    skip "DT** the rendered-DOM assertions — node is not on PATH"
    skip "GH** validate-html-output.sh over an assembled page — node is not on PATH to assemble one"
else
    node "$PREDICATE_CHECK_MJS" "$REPO_ROOT" > "${TMP}/predcheck.out" 2>"${TMP}/predcheck.err"
    predcheck_rc=$?
    consume < "${TMP}/predcheck.out"
    if [[ "$predcheck_rc" -ne 0 ]] && ! grep -q $'\tFAIL\t' "${TMP}/predcheck.out"; then
        fail "GV03 the predicate check ran to completion — exit $predcheck_rc with no reported failure: $(head -3 "${TMP}/predcheck.err" | tr '\n' ' ')"
    fi

    # ===========================================================================
    # === GV02, BLD01, BLD02: task-013's real producer and its driver ==========
    # ===========================================================================
    echo ""
    echo "=== BLD01: the REAL producer's declared substitution keys == the skeleton's own, derived ==="
    echo "===        from BOTH files at run time -- never a literal list here ==="
    if [[ -f "$BUILD_SRC" && -f "$SKELETON" ]]; then
        skel_ph=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$SKELETON" | sort -u)
        producer_ph=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$BUILD_SRC" | sort -u)
        bld01_diff=$(diff <(printf '%s\n' "$skel_ph") <(printf '%s\n' "$producer_ph") 2>&1 || true)
        if [[ -z "$bld01_diff" ]]; then
            n=$(printf '%s\n' "$skel_ph" | grep -c . || true)
            pass "BLD01 build-graph-src.mjs's declared substitution keys equal graph-skeleton.html's declared placeholders ($n names, both read from disk) -- a new skeleton placeholder fails this until the producer is taught to fill it"
        else
            fail "BLD01 build-graph-src.mjs's declared substitution keys equal graph-skeleton.html's declared placeholders — $(echo "$bld01_diff" | tr '\n' ' ')"
        fi
    else
        fail "BLD01 — build-graph-src.mjs or graph-skeleton.html is missing on disk"
    fi

    echo ""
    echo "=== BLD02, GV02: render-graph-view.sh driven end to end, over ONE fixture input ==="
    BLD_FIXTURE="${TMP}/bld-relationships.md"
    printf '# Relationships\n\nSuite fixture for the BLD group (task-014) -- non-empty text is the only\ncontract build-graph-src.mjs states on this input (AC-10/FR-3); the table\nshape itself is GraphModel'"'"'s loader contract, asserted elsewhere (GV09+).\n' > "$BLD_FIXTURE"
    BLD_OUT="${TMP}/bld-graph.html"
    set +e
    bash "$RENDER_VIEW" --relationships "$BLD_FIXTURE" --output "$BLD_OUT" --src "${TMP}/bld-graph-src" \
        --project-name "GV shell suite" --generation-date "2026-01-01" > "${TMP}/bld-render.out" 2>&1
    bld_rc=$?
    set -e
    if [[ "$bld_rc" -eq 0 && -f "$BLD_OUT" ]]; then
        pass "BLD02a render-graph-view.sh exits 0 and writes graph.html via the REAL build-graph-src.mjs + the real assemble.sh -- not the DOM half's assembly stand-in"
    else
        fail "BLD02a render-graph-view.sh drives the real producer end to end — exit $bld_rc: $(tail -3 "${TMP}/bld-render.out" | tr '\n' ' ')"
    fi
    if [[ -f "$BLD_OUT" ]]; then
        leftover=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$BLD_OUT" | sort -u || true)
        if [[ -z "$leftover" ]]; then
            pass "BLD02b the REAL generated graph.html carries ZERO surviving {{...}} placeholders"
        else
            fail "BLD02b the REAL generated graph.html carries ZERO surviving placeholders — found: $(echo "$leftover" | tr '\n' ' ')"
        fi
        if node -e "
            const fs = require('fs');
            const html = fs.readFileSync(process.argv[1], 'utf8');
            const predicate = fs.readFileSync(process.argv[2], 'utf8');
            process.exit(html.includes(predicate) ? 0 : 1);
        " "$BLD_OUT" "$PREDICATE"; then
            pass "GV02 the predicate's inlined region in the REAL generated graph.html is byte-identical to canonical/aid/scripts/graph/coverage-predicate.mjs of the tree that generated it"
        else
            fail "GV02 the predicate's inlined region in the REAL generated graph.html is byte-identical to the canonical coverage-predicate.mjs — the exact bytes were not found as a substring"
        fi
    else
        skip "BLD02b, GV02 (real-render half) — render-graph-view.sh wrote no graph.html"
    fi

    # ===========================================================================
    # === CAT: the concatenation oracle (renamed from GC01-GC04) ================
    # ===========================================================================
    echo ""
    echo "=== CAT01-CAT04 (renamed from GC01-GC04): the four files parse alone, and parse as ONE module ==="
    # Each file alone. A .mjs copy is used because these are ES modules living
    # under a .js extension by the page's own convention.
    total_parts=0
    part_ok=1
    for f in "$PREDICATE" "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS"; do
        cp "$f" "${TMP}/$(basename "${f%.*}").mjs"
        if ! node --check "${TMP}/$(basename "${f%.*}").mjs" >/dev/null 2>&1; then
            part_ok=0
            fail "CAT01 ${f#${REPO_ROOT}/} parses as a module"
        fi
        total_parts=$((total_parts + $(wc -l < "$f")))
    done
    [[ "$part_ok" -eq 1 ]] && pass "CAT01 all four view files parse as modules on their own ($total_parts lines total)"

    node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" none > "${TMP}/bundle.log" 2>&1
    assert_exit_zero "$?" "CAT02 the four files concatenate in the page's manifest order"
    if node --check "${TMP}/bundle.mjs" >/dev/null 2>&1; then
        bundle_lines=$(wc -l < "${TMP}/bundle.mjs")
        pass "CAT03 the concatenation parses as ONE module — no duplicated top-level name ($bundle_lines lines)"
    else
        fail "CAT03 the concatenation parses as ONE module — $(node --check "${TMP}/bundle.mjs" 2>&1 | head -2 | tr '\n' ' ')"
    fi
    # The line budget is asserted as a RELATIONSHIP, never as a magic number: the
    # bundle is the four files plus one separator each. A hard-coded total would
    # have to be re-typed on every edit to any of them.
    bundle_lines=$(wc -l < "${TMP}/bundle.mjs")
    assert_eq "$bundle_lines" "$((total_parts + 3))" \
        "CAT03b the bundle is exactly the four files joined, nothing added or dropped"

    # THE NEGATIVE CONTROL. Without this, CAT03 could be passing because
    # `node --check` never fails. One extra top-level `const el = 1;` collides with
    # the shell's own helper, which is precisely the failure mode the shared scope
    # creates.
    node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/dup.mjs" duplicate-name >/dev/null 2>&1
    if node --check "${TMP}/dup.mjs" >/dev/null 2>&1; then
        fail "CAT04 a duplicated top-level name is REJECTED — node --check accepted it, so CAT03 proves nothing"
    else
        pass "CAT04 a duplicated top-level name is rejected by the same check CAT03 uses (negative control)"
    fi
fi

# ===========================================================================
# === GT: the projection and the table, headless ============================
# ===========================================================================

if [[ "$HAVE_NODE" -eq 1 ]]; then
    echo ""
    echo "=== GT: the shell's projection and the table's rows, order, emphasis and unlisted set ==="
    set +e
    node "$MODEL_MJS" "${TMP}/bundle.mjs" > "${TMP}/model.out" 2>"${TMP}/model.err"
    model_rc=$?
    set -e
    consume < "${TMP}/model.out"
    if [[ "$model_rc" -ne 0 ]] && ! grep -q $'\tFAIL\t' "${TMP}/model.out"; then
        fail "GT00 the headless half ran to completion — exit $model_rc with no reported failure: $(head -3 "${TMP}/model.err" | tr '\n' ' ')"
    fi

    # A helper that emitted NOTHING would contribute no assertion at all -- a
    # silent pass wearing a green suite. The floor is positive and well below the
    # current count, so it fires on a collapse and never on growth.
    model_lines=$(grep -cE '^GV.(PASS|FAIL)' "${TMP}/model.out" || true)
    if [[ "${model_lines:-0}" -ge 40 ]]; then
        pass "GT01 the headless half reported its assertions ($model_lines outcomes)"
    else
        fail "GT01 the headless half reported its assertions — only ${model_lines:-0} outcome line(s), so the class did not run"
    fi

    # =======================================================================
    # === GV06-GV28: the shell-level LensState/CONTROL_MANIFEST fixture layer
    # =======================================================================
    echo ""
    echo "=== GV06-GV28: LensState/ViewModel design decisions D1c/D6-D9, over a purpose-built fixture layer ==="
    set +e
    node "$GV_MJS" "${TMP}/bundle.mjs" "$REPO_ROOT" > "${TMP}/gv.out" 2>"${TMP}/gv.err"
    gv_rc=$?
    set -e
    consume < "${TMP}/gv.out"
    if [[ "$gv_rc" -ne 0 ]] && ! grep -q $'\tFAIL\t' "${TMP}/gv.out"; then
        fail "GV00 the GV fixture layer ran to completion — exit $gv_rc with no reported failure: $(head -3 "${TMP}/gv.err" | tr '\n' ' ')"
    fi
    gv_lines=$(grep -cE '^GV.(PASS|FAIL)' "${TMP}/gv.out" || true)
    if [[ "${gv_lines:-0}" -ge 15 ]]; then
        pass "GV05b the GV06-GV28 fixture layer reported its assertions ($gv_lines outcomes)"
    else
        fail "GV05b the GV06-GV28 fixture layer reported its assertions — only ${gv_lines:-0} outcome line(s), so the class did not run"
    fi

    # =======================================================================
    # === GX: non-vacuity controls (--self-mutate only, S3) =================
    # =======================================================================
    echo ""
    echo "=== GX: each assertion class is shown to FAIL against a deliberate defect ==="
    run_mutation() {
        local id="$1" expect="$2"
        if ! node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/mut-${id}.mjs" "$id" > "${TMP}/mut-${id}.log" 2>&1; then
            # A mutation whose pattern no longer matches is a BROKEN CONTROL and is
            # reported as a failure, never skipped: a control that silently did not
            # apply is exactly how a suite starts proving nothing.
            fail "GX ${id} — the mutation did not apply: $(head -2 "${TMP}/mut-${id}.log" | tr '\n' ' ')"
            return
        fi
        set +e
        node "$MODEL_MJS" "${TMP}/mut-${id}.mjs" --expect-fail "$expect" > "${TMP}/mut-${id}.out" 2>&1
        set -e
        consume < "${TMP}/mut-${id}.out"
        # And the control itself must have produced a verdict. A crashed helper
        # emits no outcome line, which would leave this control contributing
        # nothing while the suite still went green.
        local n
        n=$(grep -cE '^GV.(PASS|FAIL)' "${TMP}/mut-${id}.out" || true)
        if [[ "${n:-0}" -eq 0 ]]; then
            fail "GX ${id} — the control produced no verdict: $(head -2 "${TMP}/mut-${id}.out" | tr '\n' ' ')"
        fi
    }
    if [[ "$SELF_MUTATE" -ne 1 ]]; then
        echo "Mutation matrix not run. Use --self-mutate to run it (17 extra subprocess spawns: the six"
        echo "run_mutation cases, the GS03 colour-literal control, and the two DX dom_mutation_bites cases)."
    else
        run_mutation prefix-encoding        GT20,GT21,GT22
        run_mutation dimmed-either-map      GT50,GT50b
        run_mutation list-collapsed         GT30,GT31
        run_mutation unlisted-by-degree     GT61,GT63
        run_mutation tiebreak-direction     GT37
        run_mutation sortof-keeps-direction GT39

        # The GS03 colour grep gets the same treatment: proven to bite.
        node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/poison.mjs" colour-literal >/dev/null 2>&1
        if grep -qE '#[0-9a-fA-F]{3}' "${TMP}/poison.mjs"; then
            pass "GX colour-literal — the GS03 hex-literal pattern fires on a poisoned copy (negative control)"
        else
            fail "GX colour-literal — the GS03 hex-literal pattern did NOT fire on a poisoned copy, so GS03 proves nothing"
        fi
    fi
fi

# ===========================================================================
# === DT: the rendered DOM ==================================================
# ===========================================================================

if [[ "$HAVE_NODE" -eq 1 ]]; then
    echo ""
    echo "=== DT: the page assembled, booted into a document, and asserted from the outside ==="
    # Assembly needs no DOM, so it happens even when jsdom is absent -- which is
    # what lets the GH group below run either way.
    set +e
    node "$DOM_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" "${TMP}/page" --assemble-only > "${TMP}/assemble.out" 2>&1
    assemble_rc=$?
    set -e
    if [[ "$assemble_rc" -eq 0 && -f "${TMP}/page/graph.html" ]]; then
        pass "DT01 the page assembles from the skeleton with every placeholder substituted"
    else
        fail "DT01 the page assembles from the skeleton — $(head -3 "${TMP}/assemble.out" | tr '\n' ' ')"
    fi

    set +e
    node "$DOM_MJS" "$REPO_ROOT" "${TMP}/bundle.mjs" "${TMP}/page" > "${TMP}/dom.out" 2>"${TMP}/dom.err"
    dom_rc=$?
    set -e
    consume < "${TMP}/dom.out"
    if [[ "$dom_rc" -ne 0 && "$dom_rc" -ne 3 ]] && ! grep -q $'\tFAIL\t' "${TMP}/dom.out"; then
        fail "DT00 the DOM half ran to completion — exit $dom_rc with no reported failure: $(head -3 "${TMP}/dom.err" | tr '\n' ' ')"
    fi
    # A helper that emitted NOTHING would contribute no assertion at all, which is
    # a silent pass wearing a green suite. The floor is asserted positively, well
    # below the current count, so it fires only on a collapse and never on growth.
    dom_lines=$(grep -cE $'^GV\t(PASS|FAIL|SKIP)\t' "${TMP}/dom.out" || true)
    if [[ "${dom_lines:-0}" -ge 20 ]]; then
        pass "DT02 the DOM half reported its assertion classes ($dom_lines outcomes)"
    else
        fail "DT02 the DOM half reported its assertion classes — only ${dom_lines:-0} outcome line(s), so most of the class was neither run nor skipped"
    fi

    # --- Non-vacuity for the DOM group (--self-mutate only, S3) -----------
    # The GX controls above prove the headless assertions bite. These prove the
    # same for the two most load-bearing rendered ones, by running the DOM half
    # against a mutated bundle and requiring the named assertion to FAIL.
    if [[ "$SELF_MUTATE" -ne 1 ]]; then
        echo "DX mutation matrix not run. Use --self-mutate to run it (2 extra subprocess pairs)."
    elif [[ "$dom_rc" -eq 3 ]]; then
        skip "DX** the DOM group's non-vacuity controls — the DOM half itself did not run (see the DT skips)"
    else
        dom_mutation_bites() {
            local id="$1" expect="$2"
            if ! node "$MUTATE_MJS" "$REPO_ROOT" "${TMP}/dmut-${id}.mjs" "$id" >/dev/null 2>&1; then
                fail "DX ${id} — the mutation did not apply"
                return
            fi
            set +e
            node "$DOM_MJS" "$REPO_ROOT" "${TMP}/dmut-${id}.mjs" "${TMP}/dpage-${id}" > "${TMP}/dmut-${id}.out" 2>&1
            set -e
            if grep -q $'\tFAIL\t'"${expect} " "${TMP}/dmut-${id}.out"; then
                pass "DX ${expect} fails against the mutated implementation (${id})"
            else
                fail "DX ${expect} fails against the mutated implementation (${id}) — it did NOT fail, so that assertion cannot detect this defect"
            fi
        }
        dom_mutation_bites dimmed-either-map  DT19b
        dom_mutation_bites unlisted-by-degree DT21e
    fi
fi

# ===========================================================================
# === GH: the page's own structural / accessibility / link checks ===========
# ===========================================================================

if [[ "$HAVE_NODE" -eq 1 && -f "$VALIDATE_HTML" && -f "${TMP}/page/graph.html" ]]; then
    echo ""
    echo "=== GH: validate-html-output.sh over the assembled page, and over the booted page ==="
    set +e
    static_out=$(bash "$VALIDATE_HTML" "${TMP}/page/graph.html" --kb-dir "${TMP}/page" 2>&1)
    static_rc=$?
    set -e
    [[ "$VERBOSE" -eq 1 ]] && echo "$static_out"
    assert_exit_zero "$static_rc" "GH01 the assembled page passes every structural, a11y and link check"
    assert_output_contains "$static_out" "H1. HTML validity" "GH01b H1 ran over the assembled page"
    assert_output_contains "$static_out" "L2. 3/3 relative md links resolve" \
        "GH01c the page's three relative .md targets resolve, and the table's caption link adds none"

    if [[ -f "${TMP}/page/rendered.html" ]]; then
        set +e
        booted_out=$(bash "$VALIDATE_HTML" "${TMP}/page/rendered.html" --kb-dir "${TMP}/page" 2>&1)
        booted_rc=$?
        set -e
        [[ "$VERBOSE" -eq 1 ]] && echo "$booted_out"
        # The booted page is the stronger subject: the table region is JS-built, so
        # a static check of the template never sees a single cell of it.
        assert_output_contains "$booted_out" "✅ H1. HTML validity" \
            "GH02 the BOOTED page -- the markup a reader receives, table included -- is valid HTML"
        for check in "A1.1 has <html lang" "A4.1 prefers-reduced-motion" "A5.1 :focus-visible" "S2. Offline render"; do
            assert_output_contains "$booted_out" "$check" "GH02b the booted page satisfies: $check"
        done
        if [[ "$booted_rc" -eq 0 ]]; then
            pass "GH03 the booted page also passes L1/L2 (the id=\"\" defect below appears to be fixed)"
        elif grep -q 'bad array subscript' <<< "$booted_out"; then
            # NOT worked around silently. validate-html-output.sh's L1 keys a bash
            # associative array on every `id="..."` SUBSTRING in the file and aborts
            # on an empty key; a serialized DOM writes valueless attributes as
            # `attr=""`, and the shell's own `data-controls-grid=""` then contains
            # the substring `id=""`. Routed to feature-011. The obligation itself is
            # asserted over the same rendered markup by DT30.
            skip "GH03 L1/L2 over the booted page — validate-html-output.sh aborts with 'bad array
        subscript' on the empty id=\"\" substring that a serialized data-controls-grid=\"\" produces.
        Defect routed to feature-011; the anchor obligation itself is asserted instead by DT30."
        else
            fail "GH03 the booted page's link checks — unexpected failure: $(tail -4 <<< "$booted_out" | tr '\n' ' ')"
        fi
    else
        skip "GH02-GH03 validate-html-output.sh over the booted page — the DOM half did not run, so no booted page was produced"
    fi
elif [[ "$HAVE_NODE" -eq 1 ]]; then
    skip "GH** validate-html-output.sh — the validator or the assembled page is absent"
fi

# ===========================================================================
# === S5: the source tree is untouched -- every mutation happened on a copy =
# ===========================================================================

echo ""
echo "=== S5: this run's own subject files are byte-identical to HEAD afterwards ==="
S5_SUBJECTS=("$PREDICATE" "$MODEL_JS" "$CONTROLS_JS" "$TABLE_JS" "$SKELETON" "$GRAPH_CSS" "$BUILD_SRC" "$RENDER_VIEW" "$BEARING_YML")
if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    s5_out=$(git -C "$REPO_ROOT" diff --name-only -- "${S5_SUBJECTS[@]}" 2>&1)
    if [[ -z "$s5_out" ]]; then
        pass "S5 every subject file this suite reads is byte-identical to HEAD after the run — every mutation in GX/DX/CAT happened on a copy under \$TMP, never on the source tree"
    else
        fail "S5 the source tree changed during this run — modified: $(echo "$s5_out" | tr '\n' ' ')"
    fi
else
    skip "S5 — git is not available, so the untouched-tree proof could not be run (no file writes into canonical/ are made by this suite regardless; see GX/CAT's copy-into-\$TMP pattern)"
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
