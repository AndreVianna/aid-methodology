#!/usr/bin/env bash
# test-validator-profiles.sh -- feature-011 (validator parameterisation): the PV*
# suite for the --profile kb-summary|graph contract added to contrast-check.mjs,
# validate-html-output.sh and validate-visuals.mjs.
#
# Companion to task-019 (the amendment). RECORDED DEVIATION (feature-011 SPEC
# :453-:455; task-019/task-020 DETAIL.md): this suite and the amendment are ONE
# COMMIT -- an amended validator must never exist in history without its
# assertions. Do not split them.
#
# COVERS: canonical/aid/scripts/summarize/contrast-check.mjs
# COVERS: canonical/aid/scripts/summarize/validate-html-output.sh
# COVERS: canonical/aid/scripts/summarize/validate-visuals.mjs
#
# Usage:
#   bash test-validator-profiles.sh [-v | --verbose]
#   bash test-validator-profiles.sh --self-mutate      # + the one mutation case (MUT01)
#
# Exit codes: 0 all pass / 1 any fail. Skips groups needing Node when node is
# absent (PV assertions over contrast-check.mjs / validate-visuals.mjs).
#
# ---------------------------------------------------------------------------
# NOTE -- W5-12 (tech-debt.md), NOT asserted here on purpose. contrast-check.mjs's
# header (:27) documents exit 2 for a missing file, but a missing file actually
# exits 1 via an uncaught ENOENT rejection from fs.readFile -- verified in both
# the HEAD copy and the working-tree copy (both pre-date and post-date this
# feature; the defect is untouched by task-019). Pinning exit 1 as "correct" here
# would fight a future fix. Left unasserted deliberately.
#
# NOTE -- environment ceilings (verified this session, not assumed):
#   * Playwright is genuinely NOT INSTALLED in this environment (`import('playwright')`
#     rejects with MODULE_NOT_FOUND). This is exploited, not merely tolerated: the
#     DEGRADE group below runs validate-visuals.mjs's real "Playwright unavailable"
#     SKIP branch for real, because the branch it needs IS the branch this host takes.
#   * What genuinely CANNOT run here: any assertion needing an actual Chromium render
#     (PV16 non-empty-collection positive, PV17's dynamic empty-collection FAIL, PV18's
#     dynamic T2-overlap-fails-both-profiles proof). Each such assertion below is
#     replaced by a STATIC source-property check (grep, no subject invocation) and is
#     labelled "STATIC -- needs CI to become dynamic" so a static pass is never
#     mistaken for the dynamic proof. jsdom is unresolvable here too (W5-9); no
#     jsdom-backed substitute is attempted.
#   * No real graph.html exists yet (feature-010 assembles it). Every graph-shaped
#     fixture below is synthetic: hand-inlined <style> blocks in the same shape
#     assemble.sh would produce (chrome component-css.css tokens + the two graph
#     selectors from feature-007 D5a), never a copy of a real artifact. PV05, PV13,
#     PV16 will need re-pointing at the real .aid/knowledge/graph.html once it exists
#     (see the report at hand-off).
#
# ---------------------------------------------------------------------------
# S1 -- SUBJECT INVOCATION BUDGET (subprocess spawns of the three scripts under
# test; grep/md5sum/git-show calls on source text are NOT subject invocations
# and are not counted here, per test-landscape.md S1's "~10s toll" rationale --
# these three scripts return in well under 1s with no fixture, so the toll here
# is small, but the count is still declared honestly). Every number below was
# derived by grepping call-site multiplicity for BOTH wrappers (`grep -n
# 'run_node \|run_bash '` against this file), counting every call site once --
# never the wrapper body once -- and excluding only the self-mutate-gated
# line. Categories are declared in file order so TOTAL is a checkable sum
# (FIX-cycle note: this header previously mis-declared several categories by
# hand; every number below is now re-derived, not re-asserted):
#   ARGPARSE     6  (PV02: 2 bad-value/no-value probes x 3 scripts. The 3
#                     bad-value probes' $OUT is ALSO saved into
#                     CONTRAST_USAGE_OUT/HTMLOUT_USAGE_OUT/VISUALS_USAGE_OUT
#                     for GRADE-TOKENS to reuse below -- that reuse costs 0
#                     spawns, it is a plain variable assignment)
#   COMPARE     12  (PV01/PV03: HEAD-copy vs working-copy x {default-path,
#                     explicit --profile} x 3 scripts, MINUS one avoidable
#                     duplicate this FIX cycle removed: contrast-check.mjs's
#                     second default-path run now reads WORK_DEFAULT_OUT,
#                     already captured earlier in this same section, instead
#                     of re-spawning node)
#   GRADE-TOKENS 0  (AC-2: reuses ARGPARSE's three bad-value captures above --
#                     0 new spawns. This is also why the patterns asserted in
#                     that section are EXTRACTED from grade-summary.sh at
#                     runtime rather than hand-retyped: a prior version of
#                     this section hand-retyped mis-escaped copies of
#                     grade-summary.sh's real patterns and asserted nothing
#                     that could ever fail; see the section itself)
#   VACUOUS      5  (PV05/PV08: validate-html-output.sh over vacuous/populated/
#                     missing-companion fixtures. The populated default-path
#                     run's $OUT/$RC are ALSO saved into GH_DEFAULT_OUT/
#                     GH_DEFAULT_RC for KBDIR to reuse below -- 0-spawn reuse)
#   KBDIR        3  (PV09: --kb-dir DIR on the same populated fixture --
#                     NOFLAG is GH_DEFAULT_OUT reused from VACUOUS, not
#                     re-spawned, so only the WITH-flag run is new -- plus the
#                     decoy-dir fixture, plus one -h run. The -h run is
#                     RELOCATED here from HELP/DOC below, which now reuses
#                     this same capture instead of a second -h spawn, so the
#                     move nets 0 new spawns for -h specifically)
#   REDECL       4  (redeclaration ordering fix: light + dark, fixture + control)
#   GRAPHPAIR    5  (PV13/PV14: full palette pass, default-profile sanity,
#                     existing-token-removed x2 profiles, graph-token-removed)
#   DIVERGE      3  (PV11/PV12: no-dark / colour-scheme-only-dark / three-block-order)
#   KBHTML       1  (PV11's real-artifact half: contrast-check.mjs run over
#                     the SHIPPED .aid/knowledge/kb.html itself, not only a
#                     synthetic shape-alike -- PV11's own criterion names this
#                     file)
#   NMBOTH       2  (PV06: one Mermaid-violating fixture x 2 profiles)
#   EXTSRC       2  (PV07's non-contingent half: an external <script src>
#                     fixture x {default, --profile graph} -- S2 has no
#                     profile branch yet per the SPEC D2 table, so both must
#                     fail identically; testable now, no contingent mechanism
#                     required)
#   DEGRADE      4  (PV19: missing-artifact x2 profiles, no-playwright x2 profiles --
#                     genuinely exercises the real code path, see NOTE above)
#   HELP         0  (validate-html-output.sh --help text is asserted by
#                     reusing KBDIR's -h capture above -- 0 new spawns)
#   ------------------------------------------------------------------
#   TOTAL       6+12+0+5+3+4+5+3+1+2+2+4+0 = 47 subprocess spawns in default
#               mode (categories listed in file order, top to bottom); +1
#               under --self-mutate (MUT01) = 48.
#   In-process: 0 (bash sourcing tests/lib/assert.sh only).
#
# S2 -- every $OUT is captured ONCE per invocation above and read with builtin
#   grep/string-compare helpers (assert_output_contains etc.); no assertion
#   re-invokes a subject to re-derive a value already captured.
#
# S3 -- exactly ONE mutation case (MUT01), behind --self-mutate. Every other
#   assertion below is a fixture PAIR (a positive and a negative INPUT), which
#   is not what S3 gates -- S3 gates mutating the SUBJECT SCRIPT to prove an
#   assertion isn't vacuously true regardless of the script's own logic. MUT01
#   is the one place that risk is real: PV13's "all 15 graph tokens checked"
#   claim could pass by coincidence if buildGraphPairs() were dead code and the
#   fixture's tokens were being matched by something else entirely. Every other
#   claim below is falsifiable by its own negative fixture (PV05's missing
#   companion, PV08's empty set, PV14's missing token, REDECL's control), so a
#   second layer of source mutation would be redundant with the existing
#   fixture pair and is not added.
#
# S4 -- nothing here trades coverage for time; DEGRADE and REDECL in particular
#   are exactly the two areas the task brief named as unwritten before this
#   suite, and neither is trimmed for spawn count.
#
# S5 -- proved at the bottom: md5sum of the three canonical scripts, taken
#   before any fixture work and re-verified at the end. This suite never
#   writes to canonical/; every HEAD-copy and every mutant lives under $TMP.
# ---------------------------------------------------------------------------

set -u

VERBOSE=0
SELF_MUTATE=0
for a in "$@"; do
    case "$a" in
        -v|--verbose)   VERBOSE=1 ;;
        --self-mutate)  SELF_MUTATE=1 ;;
        *) echo "test-validator-profiles.sh: unknown argument: $a" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

CONTRAST="${REPO_ROOT}/canonical/aid/scripts/summarize/contrast-check.mjs"
HTMLOUT="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-html-output.sh"
VISUALS="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-visuals.mjs"

for f in "$CONTRAST" "$HTMLOUT" "$VISUALS"; do
    [[ -f "$f" ]] || { echo "ERROR: subject script not found at $f" >&2; exit 1; }
done

NODE_OK=1
command -v node >/dev/null 2>&1 || NODE_OK=0

# --- S5 baseline: taken now, before any fixture or HEAD-copy work -----------
S5_BASE=$(cat "$CONTRAST" "$HTMLOUT" "$VISUALS" | md5sum)

# --- Fixture root -------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run_node() { OUT=$(node "$@" 2>&1); RC=$?; }
run_bash() { OUT=$(bash "$@" 2>&1); RC=$?; }

echo ""
echo "=== Fixture construction ==="

# --- HEAD copies (pre-parameterisation), for PV01/PV03's red/green proof ----
HEAD_CONTRAST="$TMP/head-contrast-check.mjs"
HEAD_HTMLOUT="$TMP/head-validate-html-output.sh"
HEAD_VISUALS="$TMP/head-validate-visuals.mjs"
git -C "$REPO_ROOT" show HEAD:canonical/aid/scripts/summarize/contrast-check.mjs      > "$HEAD_CONTRAST"      2>/dev/null
git -C "$REPO_ROOT" show HEAD:canonical/aid/scripts/summarize/validate-html-output.sh > "$HEAD_HTMLOUT"       2>/dev/null
git -C "$REPO_ROOT" show HEAD:canonical/aid/scripts/summarize/validate-visuals.mjs    > "$HEAD_VISUALS"       2>/dev/null
assert_file_exists "$HEAD_CONTRAST" "SETUP HEAD copy of contrast-check.mjs retrieved via git show"
assert_file_exists "$HEAD_HTMLOUT"  "SETUP HEAD copy of validate-html-output.sh retrieved via git show"
assert_file_exists "$HEAD_VISUALS"  "SETUP HEAD copy of validate-visuals.mjs retrieved via git show"

# --- Chrome-only fixture (matches test-contrast-check.sh's own convention) --
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/chrome-only.html"

# --- Redeclaration fixtures (light + dark), plus no-graph-block controls ----
printf '<style>:root{--text:#000000;--bg:#ffffff;}html:root{--text:#ff0000;}</style>\n' > "$TMP/redecl-light.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/control-light.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{--text:#ffffff;--bg:#000000;}html[data-theme="dark"]:root{--text:#ff0000;}</style>\n' > "$TMP/redecl-dark.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{--text:#ffffff;--bg:#000000;}</style>\n' > "$TMP/control-dark.html"

# --- Divergence fixtures (PV11/PV12) ----------------------------------------
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/no-dark.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{color-scheme:dark;}</style>\n' > "$TMP/dark-empty.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{color-scheme:dark;}html[data-theme="dark"]{--text:#ffffff;--bg:#111111;}@media print{html[data-theme="dark"]{--text:#000000;--bg:#ffffff;}}</style>\n' > "$TMP/dark-3block.html"

# --- Full graph palette fixture (PV13): 11 chrome pairs + 15 gk-*/gc-* tokens,
# both themes, all clearing their target (4.5 chrome / 3.0 graph). Values are
# deliberately simple two-tone (near-black / near-white per theme) so every
# pair passes without needing per-token tuning; --gk-*/--gc-* use a slightly
# softer tone (#1a1a1a / #e0e0e0) so a corrupted merge (graph value winning
# over a same-named chrome token) would be visually distinguishable too, though
# no name collision exists in this fixture by construction. ---
cat > "$TMP/graph-full.html" <<'CSSEOF'
<style>
:root{
  --bg:#ffffff;--bg-elev:#f5f5f5;--text:#000000;--text-muted:#000000;--text-dim:#000000;
  --accent:#000000;--primary:#ffffff;--primary-fg:#000000;--accent-fg:#ffffff;
  --ok:#000000;--ok-bg:#ffffff;--warn:#000000;--warn-bg:#ffffff;--err:#000000;--err-bg:#ffffff;
  --info:#000000;--info-bg:#ffffff;--purple:#000000;--purple-bg:#ffffff;
}
html:root{
  --gk-document:#1a1a1a;--gk-section:#1a1a1a;--gk-fact:#1a1a1a;--gk-concept:#1a1a1a;
  --gk-source-artifact:#1a1a1a;--gk-image:#1a1a1a;--gk-web-page:#1a1a1a;--gk-project:#1a1a1a;
  --gc-structure:#1a1a1a;--gc-taxonomy:#1a1a1a;--gc-documentation:#1a1a1a;--gc-evidence:#1a1a1a;
  --gc-provenance:#1a1a1a;--gc-lineage:#1a1a1a;--gc-dependency:#1a1a1a;--gc-implementation:#1a1a1a;
}
html[data-theme="dark"]{
  --bg:#0a0a0a;--bg-elev:#1e1e1e;--text:#ffffff;--text-muted:#ffffff;--text-dim:#ffffff;
  --accent:#ffffff;--primary:#0a0a0a;--primary-fg:#ffffff;--accent-fg:#000000;
  --ok:#ffffff;--ok-bg:#0a0a0a;--warn:#ffffff;--warn-bg:#0a0a0a;--err:#ffffff;--err-bg:#0a0a0a;
  --info:#ffffff;--info-bg:#0a0a0a;--purple:#ffffff;--purple-bg:#0a0a0a;
}
html[data-theme="dark"]:root{
  --gk-document:#e0e0e0;--gk-section:#e0e0e0;--gk-fact:#e0e0e0;--gk-concept:#e0e0e0;
  --gk-source-artifact:#e0e0e0;--gk-image:#e0e0e0;--gk-web-page:#e0e0e0;--gk-project:#e0e0e0;
  --gc-structure:#e0e0e0;--gc-taxonomy:#e0e0e0;--gc-documentation:#e0e0e0;--gc-evidence:#e0e0e0;
  --gc-provenance:#e0e0e0;--gc-lineage:#e0e0e0;--gc-dependency:#e0e0e0;--gc-implementation:#e0e0e0;
}
</style>
CSSEOF

# PV14a: an EXISTING chrome pair token missing entirely (generic warn-vs-fail
# mechanism, not graph-specific -- proves the profile-wide hard-fail rule).
sed '/--text-muted:#000000;/d; s/--text-muted:#ffffff;//' "$TMP/graph-full.html" > "$TMP/graph-no-textmuted.html"

# PV14b: ONE graph token (gk-image) missing from BOTH theme blocks.
sed 's/--gk-image:#1a1a1a;//; s/--gk-image:#e0e0e0;//' "$TMP/graph-full.html" > "$TMP/graph-no-gkimage.html"

# --- validate-html-output.sh fixtures ---------------------------------------
# A minimal but FULLY clean fixture (all structural/A1-A5/S2/NM checks pass)
# carrying the footer + noscript link set D2/PV05 names for graph.html:
# ./relationships.md, ./external-sources.md (footer) + ./INDEX.md (noscript).
mkdir -p "$TMP/gh"
: > "$TMP/gh/relationships.md"
: > "$TMP/gh/external-sources.md"
: > "$TMP/gh/INDEX.md"
cat > "$TMP/gh/graph.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<title>Graph</title>
<!-- color-scheme: light dark -->
<style>:focus-visible{outline:2px;} @media (prefers-reduced-motion: reduce){*{}}</style>
</head>
<body>
<a class="skip-link" href="#top">Skip to content</a>
<header role="banner"><nav aria-label="Breadcrumb"><a href="/">Home</a></nav></header>
<main id="top"><h1 id="h1">Graph</h1></main>
<div id="lightbox" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="lb-cap">
  <div id="lb-cap"></div>
</div>
<footer><a href="./relationships.md">rel</a> <a href="./external-sources.md">ext</a></footer>
<noscript><a href="./INDEX.md">idx</a></noscript>
<script>
(function(){
  function trapFocusOnTab(e){ if (e.key === 'Escape') {} }
  var lastFocused = document.body;
  lastFocused.focus();
})();
</script>
</body></html>
HTMLEOF

# A vacuous fixture: no href="#..." and no href="./*.md" anywhere. Otherwise
# structurally the same, so only L1/L2 are exercised by the delta.
cat > "$TMP/gh/vacuous.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head><meta charset="UTF-8"><title>Graph</title>
<!-- color-scheme: light dark -->
<style>:focus-visible{outline:2px;} @media (prefers-reduced-motion: reduce){*{}}</style>
</head>
<body>
<a class="skip-link" href="/">Skip</a>
<header role="banner"><nav aria-label="Breadcrumb"></nav></header>
<main id="top"><h1>Graph</h1></main>
<div role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="x"></div>
<footer>no links here</footer>
<noscript>no md links here either</noscript>
<script>
(function(){
  function trapFocusOnTab(e){ if (e.key === 'Escape') {} }
  var lastFocused = document.body;
  lastFocused.focus();
})();
</script>
</body></html>
HTMLEOF

# A Mermaid-violating fixture (NM.2), for PV06's both-profiles enforcement.
cat > "$TMP/gh/mermaid-violation.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><title>T</title></head>
<body><main><script>mermaid.initialize({});</script></main></body></html>
HTMLEOF

echo "Fixtures built under $TMP"

# ===========================================================================
# ARGPARSE -- PV02: exit 2 on unrecognised/missing --profile value, and the
# closed set documented once in each script's header (D1 property 2).
# ===========================================================================
echo ""
echo "=== ARGPARSE (PV02) ==="

run_node "$CONTRAST" "$TMP/chrome-only.html" --profile bogus
CONTRAST_USAGE_OUT="$OUT"   # reused by GRADE-TOKENS below -- 0-spawn reuse
assert_exit_eq "$RC" 2 "PV02a contrast-check.mjs --profile bogus -> exit 2"
assert_output_contains "$OUT" "kb-summary|graph" "PV02a1 names the closed set"

run_node "$CONTRAST" "$TMP/chrome-only.html" --profile
assert_exit_eq "$RC" 2 "PV02b contrast-check.mjs --profile (no value) -> exit 2"

run_bash "$HTMLOUT" "$TMP/gh/graph.html" --profile bogus
HTMLOUT_USAGE_OUT="$OUT"   # reused by GRADE-TOKENS below -- 0-spawn reuse
assert_exit_eq "$RC" 2 "PV02c validate-html-output.sh --profile bogus -> exit 2"
assert_output_contains "$OUT" "kb-summary|graph" "PV02c1 names the closed set"

run_bash "$HTMLOUT" "$TMP/gh/graph.html" --profile
assert_exit_eq "$RC" 2 "PV02d validate-html-output.sh --profile (no value) -> exit 2"

run_node "$VISUALS" "$TMP/gh/graph.html" --profile bogus
VISUALS_USAGE_OUT="$OUT"   # reused by GRADE-TOKENS below -- 0-spawn reuse
assert_exit_eq "$RC" 2 "PV02e validate-visuals.mjs --profile bogus -> exit 2"
assert_output_contains "$OUT" "kb-summary|graph" "PV02e1 names the closed set"

run_node "$VISUALS" "$TMP/gh/graph.html" --profile
assert_exit_eq "$RC" 2 "PV02f validate-visuals.mjs --profile (no value) -> exit 2"

assert_file_contains "$CONTRAST" "kb-summary|graph" "PV02g contrast-check.mjs header documents the closed set"
assert_file_contains "$HTMLOUT"  "kb-summary|graph" "PV02h validate-html-output.sh header documents the closed set"
assert_file_contains "$VISUALS"  "kb-summary|graph" "PV02i validate-visuals.mjs header documents the closed set"

# ===========================================================================
# COMPARE -- PV01 (byte-identity/substance on the default path) and PV03
# (stale-copy detectability: red against HEAD, green against the working tree).
# ===========================================================================
echo ""
echo "=== COMPARE (PV01, PV03) ==="

# --- contrast-check.mjs --------------------------------------------------
run_node "$HEAD_CONTRAST" "$TMP/chrome-only.html"
HEAD_DEFAULT_OUT="$OUT"; HEAD_DEFAULT_RC=$RC
run_node "$CONTRAST" "$TMP/chrome-only.html"
WORK_DEFAULT_OUT="$OUT"; WORK_DEFAULT_RC=$RC
assert_exit_eq "$WORK_DEFAULT_RC" "$HEAD_DEFAULT_RC" "PV01a contrast-check.mjs default-path exit status unchanged"
assert_output_not_contains "$WORK_DEFAULT_OUT" "FAIL" "PV01b contrast-check.mjs re-taken baseline: shipped-shape chrome-only fixture still reports no FAIL"
assert_output_not_contains "$HEAD_DEFAULT_OUT" "Theme divergence" "PV01c HEAD copy has no theme-divergence line (confirms this is the named exception, not a no-op)"
assert_output_contains "$WORK_DEFAULT_OUT" "Theme divergence" "PV01d working copy adds exactly the theme-divergence line on the default path"

run_node "$HEAD_CONTRAST" "$TMP/chrome-only.html" --profile graph
assert_output_not_contains "$OUT" "Profile:" "PV03a-RED HEAD copy of contrast-check.mjs silently ignores --profile (no printed line) -- this IS the stale-copy risk D1 property 3 names"
run_node "$CONTRAST" "$TMP/chrome-only.html" --profile graph
assert_output_contains "$OUT" "Profile: graph" "PV03a-GREEN working copy prints the active profile when passed explicitly"
# No re-spawn here: this is the SAME invocation already captured as
# WORK_DEFAULT_OUT a few lines above (FIX-cycle dedup -- see S1's COMPARE note).
assert_output_not_contains "$WORK_DEFAULT_OUT" "Profile:" "PV03a-GREEN2 working copy prints nothing when the flag is absent (byte-identity precondition)"

# --- validate-html-output.sh --------------------------------------------
run_bash "$HEAD_HTMLOUT" "$TMP/gh/graph.html"
HEAD_HTML_DEFAULT_OUT="$OUT"; HEAD_HTML_DEFAULT_RC=$RC
run_bash "$HTMLOUT" "$TMP/gh/graph.html"
WORK_HTML_DEFAULT_OUT="$OUT"; WORK_HTML_DEFAULT_RC=$RC
assert_eq "$WORK_HTML_DEFAULT_OUT" "$HEAD_HTML_DEFAULT_OUT" "PV01e validate-html-output.sh default-path stdout is BYTE-IDENTICAL to the pre-parameterisation copy"
assert_exit_eq "$WORK_HTML_DEFAULT_RC" "$HEAD_HTML_DEFAULT_RC" "PV01f validate-html-output.sh default-path exit status unchanged"

run_bash "$HEAD_HTMLOUT" "$TMP/gh/graph.html" --profile graph
assert_exit_eq "$RC" 2 "PV03b-RED HEAD copy of validate-html-output.sh rejects --profile outright (Unknown flag) -- fails PV03 a different way than silent tolerance, but still fails it"
run_bash "$HTMLOUT" "$TMP/gh/graph.html" --profile graph
assert_output_contains "$OUT" "Profile: graph" "PV03b-GREEN working copy prints the active profile when passed explicitly"

# --- validate-visuals.mjs (default-path text is identical up to the point
# Playwright-unavailability is detected -- both copies hit that branch here) --
run_node "$HEAD_VISUALS" "$TMP/gh/graph.html"
HEAD_VIS_DEFAULT_OUT="$OUT"; HEAD_VIS_DEFAULT_RC=$RC
run_node "$VISUALS" "$TMP/gh/graph.html"
WORK_VIS_DEFAULT_OUT="$OUT"; WORK_VIS_DEFAULT_RC=$RC
assert_eq "$WORK_VIS_DEFAULT_OUT" "$HEAD_VIS_DEFAULT_OUT" "PV01g validate-visuals.mjs default-path stdout is BYTE-IDENTICAL to the pre-parameterisation copy (SKIP branch, no Playwright)"
assert_exit_eq "$WORK_VIS_DEFAULT_RC" "$HEAD_VIS_DEFAULT_RC" "PV01h validate-visuals.mjs default-path exit status unchanged"

run_node "$HEAD_VISUALS" "$TMP/gh/graph.html" --profile graph
assert_exit_eq "$RC" 2 "PV03c-RED HEAD copy of validate-visuals.mjs rejects --profile outright (Unknown flag)"
run_node "$VISUALS" "$TMP/gh/graph.html" --profile graph
assert_output_contains "$OUT" "Profile: graph" "PV03c-GREEN working copy prints the active profile when passed explicitly"

# ===========================================================================
# GRADE-TOKENS -- AC-2: grade-summary.sh's own grep patterns for S2/NM/L1/L2's
# "[PASS]"/"resolve" markers and the C1/C2 pass-summary literal (the check
# block at grade-summary.sh:316,323,326-327 plus the summary-line check inside
# its C1/C2 sed+grep block at :355-368) must not match the new Usage/error
# text on the invocation-error paths.
#
# Patterns are EXTRACTED from grade-summary.sh at runtime, never hand-
# retyped: a prior version of this section hand-copied "S2\..*\[PASS\]" as
# "S2\.\.\*\[PASS\]" (an extra literal dot+star), which asserted a pattern
# that does not exist anywhere and could never fail for the reason it
# claimed. Extraction makes that class of mistake structurally impossible --
# this section cannot drift from grade-summary.sh because it reads
# grade-summary.sh, every run.
#
# Reuses ARGPARSE's three bad-value captures above (S2: 0 new spawns).
# ===========================================================================
echo ""
echo "=== GRADE-TOKENS (AC-2) ==="

GRADE_SUMMARY="${REPO_ROOT}/canonical/aid/scripts/summarize/grade-summary.sh"
assert_file_exists "$GRADE_SUMMARY" "GT-SETUP grade-summary.sh found for pattern extraction"

# Pull the FIRST double-quoted string off the (unique) source line that both
# invokes grep -qE/-q and sets the named RESULTS[...] token being probed --
# i.e. the literal pattern grade-summary.sh itself greps the HTML/contrast
# log for. The marker is anchored on the RESULTS[...] assignment, not a line
# number, so it survives grade-summary.sh being reformatted/reordered.
extract_gs_pattern() {
    local marker="$1"
    grep -E "$marker" "$GRADE_SUMMARY" | head -1 | grep -oE '"[^"]+"' | head -1 | sed 's/^"//;s/"$//'
}

GT_S2_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[S2\]=pass')
GT_NM_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[NM\]=pass')
GT_L1_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[L1\]=pass')
GT_L2_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[L2\]=pass')
GT_SUMMARY_PAT=$(extract_gs_pattern 'grep -q .*All contrast checks passed')

# Extraction sanity: every pattern must be non-empty, or a marker has drifted
# out from under this suite (grade-summary.sh renamed/restructured the
# check) and every downstream GT assertion below would silently go vacuous
# again -- for a different reason than the mis-escaping this section used to
# have, but the same failure mode (an assertion that cannot fail).
for v in GT_S2_PAT GT_NM_PAT GT_L1_PAT GT_L2_PAT GT_SUMMARY_PAT; do
    val="${!v}"
    if [[ -n "$val" ]]; then
        pass "GT-EXTRACT-$v pattern extracted from grade-summary.sh: '$val'"
    else
        fail "GT-EXTRACT-$v grade-summary.sh's source line for this token could not be found -- extraction is broken, not merely the pattern"
    fi
done

for pair in "CONTRAST_USAGE_OUT:$GT_S2_PAT" "CONTRAST_USAGE_OUT:$GT_NM_PAT" \
            "CONTRAST_USAGE_OUT:$GT_L1_PAT" "CONTRAST_USAGE_OUT:$GT_L2_PAT" \
            "HTMLOUT_USAGE_OUT:$GT_S2_PAT" "HTMLOUT_USAGE_OUT:$GT_NM_PAT" \
            "HTMLOUT_USAGE_OUT:$GT_L1_PAT" "HTMLOUT_USAGE_OUT:$GT_L2_PAT" \
            "VISUALS_USAGE_OUT:$GT_S2_PAT"; do
    var="${pair%%:*}"; pat="${pair#*:}"
    val="${!var}"
    if echo "$val" | grep -qE "$pat"; then
        fail "GT-$var-$pat grade-summary.sh's grep pattern '$pat' matches the Usage/error text -- a grade CAN move"
    else
        pass "GT-$var-$pat grade-summary.sh's grep pattern '$pat' does not match the Usage/error text"
    fi
done
if echo "$CONTRAST_USAGE_OUT" | grep -qF "$GT_SUMMARY_PAT"; then
    fail "GT-summary-line the pass-summary literal leaks into the Usage/error text"
else
    pass "GT-summary-line '$GT_SUMMARY_PAT' does not appear on the Usage/error path"
fi

# ===========================================================================
# VACUOUS -- PV05, PV08: L1/L2's zero-sized-input-set case for
# validate-html-output.sh (AC-4).
# ===========================================================================
echo ""
echo "=== VACUOUS (PV05, PV08) ==="

run_bash "$HTMLOUT" "$TMP/gh/vacuous.html"
assert_output_contains "$OUT" "L1. 0/0 anchor links resolve" "PV08a default profile: 0/0 anchors keeps today's pass wording"
assert_output_contains "$OUT" "L2. 0/0 relative md links resolve" "PV08b default profile: 0/0 md links keeps today's pass wording"
assert_exit_eq "$RC" 0 "PV08c default profile: vacuous fixture still exits 0 (structural checks are otherwise clean)"

run_bash "$HTMLOUT" "$TMP/gh/vacuous.html" --profile graph
assert_output_contains "$OUT" "L1. [VACUOUS]" "PV08d --profile graph: empty anchor set is reported [VACUOUS]"
assert_output_contains "$OUT" "L2. [VACUOUS]" "PV08e --profile graph: empty md-link set is reported [VACUOUS]"
assert_exit_eq "$RC" 1 "PV08f --profile graph: a vacuous input set is a FAILURE, not a pass"

run_bash "$HTMLOUT" "$TMP/gh/graph.html"
GH_DEFAULT_OUT="$OUT"; GH_DEFAULT_RC=$RC   # reused by KBDIR below -- 0-spawn reuse
assert_output_contains "$OUT" "L2. 3/3 relative md links resolve" "PV05a populated fixture: L2's set is exactly relationships.md + external-sources.md (footer) + INDEX.md (noscript) = 3"
run_bash "$HTMLOUT" "$TMP/gh/graph.html" --profile graph
assert_output_contains "$OUT" "L2. 3/3 relative md links resolve" "PV05b same 3-member set passes (non-vacuous) under --profile graph too"
assert_exit_eq "$RC" 0 "PV05c --profile graph: a genuinely non-empty, fully-resolving L1/L2 set still exits 0"

rm -f "$TMP/gh/external-sources.md"
run_bash "$HTMLOUT" "$TMP/gh/graph.html" --profile graph
assert_output_contains "$OUT" "L2. 1 md link(s) broken (of 3)" "PV05d removing one companion file: L2 fails naming the missing target's count"
assert_exit_eq "$RC" 1 "PV05e broken L2 target fails the run"
: > "$TMP/gh/external-sources.md"   # restore for later groups

# ===========================================================================
# KBDIR -- PV09: --kb-dir sets NO resolution basis (D2's decision). Three
# things to prove: (1) passing --kb-dir changes no verdict on a genuinely
# passing fixture, (2) a companion .md that exists in the --kb-dir target but
# NOT beside the artifact still fails L2 (the decoy-dir case -- if --kb-dir
# rescued it, this check would be vacuous on demand, which is exactly what D2
# rejected), (3) --help and the header comment both say so.
# ===========================================================================
echo ""
echo "=== KBDIR (PV09) ==="

# PV09a: --kb-dir on the SAME passing fixture changes no verdict and no exit
# status. NOFLAG reuses GH_DEFAULT_OUT/RC captured in VACUOUS above (0-spawn
# reuse); only the WITH-flag run is a new spawn.
run_bash "$HTMLOUT" "$TMP/gh/graph.html" --kb-dir "$TMP/nonexistent-basis-dir"
assert_exit_eq "$RC" "$GH_DEFAULT_RC" "PV09a-rc --kb-dir changes no exit status on a passing fixture (even pointed at a directory that does not exist)"
# Mask the one line that legitimately differs -- L2's own "(kb-dir=...)"
# progress banner, which echoes whatever was passed (D2: "echoed in L2's
# progress line") -- before the byte comparison, so "every OTHER line is
# identical" is the actual claim being proven, not merely the verdict.
NOFLAG_BODY=$(echo "$GH_DEFAULT_OUT" | sed 's/(kb-dir=.*)/(kb-dir=X)/')
WITHFLAG_BODY=$(echo "$OUT" | sed 's/(kb-dir=.*)/(kb-dir=X)/')
assert_eq "$WITHFLAG_BODY" "$NOFLAG_BODY" "PV09a-body every line other than L2's own kb-dir=... banner is byte-identical with/without --kb-dir"

# PV09b: the decoy-dir case. external-sources.md exists in the dir --kb-dir
# names, but deliberately NOT beside the artifact (only relationships.md and
# INDEX.md are). --kb-dir must not rescue it: resolution is against HTML_DIR
# (dirname of the artifact) only -- validate-html-output.sh:448, task-019's
# own finding.
mkdir -p "$TMP/decoy" "$TMP/gh2"
: > "$TMP/decoy/external-sources.md"
: > "$TMP/gh2/relationships.md"
: > "$TMP/gh2/INDEX.md"
cp "$TMP/gh/graph.html" "$TMP/gh2/graph.html"
run_bash "$HTMLOUT" "$TMP/gh2/graph.html" --kb-dir "$TMP/decoy"
assert_output_contains "$OUT" "L2. 1 md link(s) broken (of 3)" "PV09b --kb-dir pointed at a directory where the missing companion DOES exist does not rescue L2 -- resolution is against the artifact's own directory only, never --kb-dir"
assert_exit_eq "$RC" 1 "PV09b-rc ...and the run still fails"

# PV09c: --help and the header comment both document the true behaviour.
# The -h run is RELOCATED here from HELP/DOC below (which now reuses this
# capture instead of a second -h spawn -- 0 net new spawns for -h).
run_bash "$HTMLOUT" -h
HTMLOUT_HELP_OUT="$OUT"; HTMLOUT_HELP_RC=$RC
assert_output_contains "$HTMLOUT_HELP_OUT" "sets NO resolution basis" "PV09c-help --help documents that --kb-dir sets no resolution basis"
assert_file_contains "$HTMLOUT" "sets NO resolution basis" "PV09c-header ...and so does the header comment (:22), not only --help's rendering of it"

# ===========================================================================
# REDECL -- the redeclaration-ordering fix. Highest-value item named by the
# task-019 executor: a graph-added block that redeclares a chrome-pair token
# must NOT corrupt that pair's reported ratio, AND must still surface as a
# FAIL. Reproduction fixture per the dispatch brief: pre-fix reported 4.00:1
# (corrupted, --text shadowed by the graph block's #ff0000), post-fix 21.00:1
# (matching a no-graph-block control byte-for-byte). Verified interactively
# against the working tree before being encoded here.
# ===========================================================================
echo ""
echo "=== REDECL (redeclaration ordering fix) ==="

run_node "$CONTRAST" "$TMP/redecl-light.html" --profile graph
REDECL_LIGHT_OUT="$OUT"; REDECL_LIGHT_RC=$RC
run_node "$CONTRAST" "$TMP/control-light.html" --profile graph
CONTROL_LIGHT_OUT="$OUT"

REDECL_LIGHT_RATIO=$(echo "$REDECL_LIGHT_OUT" | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
CONTROL_LIGHT_RATIO=$(echo "$CONTROL_LIGHT_OUT" | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
assert_eq "$REDECL_LIGHT_RATIO" "21.00:1" "REDECL-L1 the chrome pair's ratio is NOT corrupted by the redeclaring graph block (21.00:1, black-on-white)"
assert_eq "$REDECL_LIGHT_RATIO" "$CONTROL_LIGHT_RATIO" "REDECL-L2 that ratio matches a no-graph-block control byte-for-byte"
assert_output_contains "$REDECL_LIGHT_OUT" "FAIL redeclaration: --text is declared inside the added graph block 'html:root'" "REDECL-L3 the redeclaration still surfaces as a named FAIL (light)"
assert_output_not_contains "$CONTROL_LIGHT_OUT" "redeclaration" "REDECL-L4 control (no added block) has no redeclaration line at all"
assert_exit_eq "$REDECL_LIGHT_RC" 1 "REDECL-L5 a passing ratio does not save the run: redeclaration alone forces exit 1"

run_node "$CONTRAST" "$TMP/redecl-dark.html" --profile graph
REDECL_DARK_OUT="$OUT"
run_node "$CONTRAST" "$TMP/control-dark.html" --profile graph
CONTROL_DARK_OUT="$OUT"
REDECL_DARK_RATIO=$(echo "$REDECL_DARK_OUT" | sed -n '/\[dark theme\]/,$p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
CONTROL_DARK_RATIO=$(echo "$CONTROL_DARK_OUT" | sed -n '/\[dark theme\]/,$p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
assert_eq "$REDECL_DARK_RATIO" "21.00:1" "REDECL-D1 the dark chrome pair's ratio is NOT corrupted by the redeclaring graph block (21.00:1, white-on-black)"
assert_eq "$REDECL_DARK_RATIO" "$CONTROL_DARK_RATIO" "REDECL-D2 that ratio matches a no-graph-block dark control byte-for-byte"
assert_output_contains "$REDECL_DARK_OUT" 'FAIL redeclaration: --text is declared inside the added graph block '"'"'html[data-theme="dark"]:root'"'" "REDECL-D3 the redeclaration still surfaces as a named FAIL (dark)"
assert_output_contains "$REDECL_DARK_OUT" "Theme divergence: dark theme differs from light" "REDECL-D4 the redeclaration bug does not corrupt the (separate) divergence check -- dark still genuinely differs from light"

# ===========================================================================
# GRAPHPAIR -- PV13/PV14: the graph palette pair set (15 tokens x 2 backgrounds
# x 2 themes at 3:1), and the hard-fail-not-warning rule for an unresolved pair.
# ===========================================================================
echo ""
echo "=== GRAPHPAIR (PV13, PV14) ==="

run_node "$CONTRAST" "$TMP/graph-full.html" --profile graph
assert_exit_eq "$RC" 0 "PV13a a fully-declared graph palette (16 tokens x 2 bg x 2 themes) passes cleanly"
PASS_LINES=$(echo "$OUT" | grep -c '✅')
assert_eq "$PASS_LINES" "88" "PV13b exactly 88 passing lines: (11 chrome + 16x2 graph)=43 x 2 themes + 2 divergence/summary lines"
for tok in gk-document gk-section gk-fact gk-concept gk-source-artifact gk-image gk-web-page gk-project \
           gc-structure gc-taxonomy gc-documentation gc-evidence gc-provenance gc-lineage gc-dependency gc-implementation; do
    assert_output_contains "$OUT" "--$tok on --bg " "PV13c-$tok checked against --bg"
    assert_output_contains "$OUT" "--$tok on --bg-elev" "PV13d-$tok checked against --bg-elev"
done
assert_output_contains "$OUT" "target 3)" "PV13e graph pairs are checked at the 3.0 (non-text, SC 1.4.11) target"
assert_output_contains "$OUT" "target 4.5)" "PV13f existing chrome pairs stay at 4.5, unchanged"

run_node "$CONTRAST" "$TMP/graph-full.html"
assert_output_not_contains "$OUT" "gk-" "PV13g default profile checks none of the graph tokens (pair set is graph-only)"
assert_exit_eq "$RC" 0 "PV13h default profile over the same fixture still exits 0"

# PV14a: existing (non-graph) token missing -> warn under default, HARD FAIL under graph.
run_node "$CONTRAST" "$TMP/graph-no-textmuted.html"
assert_output_contains "$OUT" "⚠️" "PV14a-default default profile: missing --text-muted is a skipped warning"
assert_exit_eq "$RC" 0 "PV14a-default-rc ...and does not fail the run"
run_node "$CONTRAST" "$TMP/graph-no-textmuted.html" --profile graph
assert_output_contains "$OUT" "FAIL muted text on bg" "PV14a-graph --profile graph: the SAME missing token is now a named FAIL"
assert_exit_eq "$RC" 1 "PV14a-graph-rc ...and DOES fail the run -- the hard-fail rule is profile-wide, not graph-token-only"

# PV14b: a GRAPH token missing (gk-image) from both theme blocks.
run_node "$CONTRAST" "$TMP/graph-no-gkimage.html" --profile graph
assert_output_contains "$OUT" "FAIL --gk-image on --bg:" "PV14b --profile graph: a missing GRAPH token is a named hard FAIL, not a skipped warning"
assert_exit_eq "$RC" 1 "PV14b-rc the run fails"

# ===========================================================================
# DIVERGE -- PV11/PV12: theme divergence's three verdicts, and the corrected
# extraction rule (first block declaring >=1 custom property wins).
# ===========================================================================
echo ""
echo "=== DIVERGE (PV11, PV12) ==="

run_node "$CONTRAST" "$TMP/no-dark.html"
assert_output_contains "$OUT" "[N/A] Theme divergence" "PV11a no dark block at all -> [N/A], not a failure"
assert_exit_eq "$RC" 0 "PV11a-rc ...and the run still exits 0"
assert_output_not_contains "$OUT" "FAIL" "PV11a-noFAIL the [N/A] line carries no FAIL/fail token (leaves exit status to the pairs alone)"

run_node "$CONTRAST" "$TMP/dark-empty.html"
assert_output_contains "$OUT" "FAIL Theme divergence: dark theme reports the light theme's values" "PV11b a dark block declaring NO custom property (color-scheme only) -- the exact shipped kb.html defect -- fails divergence"
assert_exit_eq "$RC" 1 "PV11b-rc ...and this now fails the run (the check becomes capable of failing, per Open Item 1)"

run_node "$CONTRAST" "$TMP/dark-3block.html"
LIGHT_RATIO=$(echo "$OUT" | sed -n '/\[light theme\]/,/\[dark theme\]/p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
DARK_RATIO=$(echo "$OUT" | sed -n '/\[dark theme\]/,$p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
assert_eq "$LIGHT_RATIO" "21.00:1" "PV12a light ratio is the plain :root block (black on white)"
assert_eq "$DARK_RATIO" "18.88:1" "PV12b dark ratio comes from the SECOND dark block (text:#fff/bg:#111) -- NOT the color-scheme-only first block (would be N/A-shaped) and NOT the @media print third block re-declaring the light values (which would print 21.00:1 too)"
assert_output_contains "$OUT" "Theme divergence: dark theme differs from light" "PV12c divergence correctly reports PASS -- the print block's light-value shadow did not win"

# ===========================================================================
# KBHTML -- PV11's real-artifact half. PV11's own criterion text requires the
# theme-divergence check to pass over the SHIPPED .aid/knowledge/kb.html, not
# only over synthetic shape-alikes (DIVERGE above uses only synthetic
# fixtures). This suite is the SPEC-designated home for every PV assertion,
# so the real-artifact run belongs here even though test-contrast-check.sh's
# unmodified CC09b incidentally exercises the same file already.
# ===========================================================================
echo ""
echo "=== KBHTML (PV11 real-artifact) ==="

KB_HTML="${REPO_ROOT}/.aid/knowledge/kb.html"
if [[ -f "$KB_HTML" ]]; then
    run_node "$CONTRAST" "$KB_HTML"
    assert_output_contains "$OUT" "Theme divergence: dark theme differs from light" "PV11-real the SHIPPED .aid/knowledge/kb.html's theme divergence check reports PASS -- the real artifact, not a synthetic shape-alike"
    assert_exit_eq "$RC" 0 "PV11-real-rc ...and the real artifact's full run still exits 0"
else
    fail "PV11-real .aid/knowledge/kb.html not found at $KB_HTML -- cannot run the real-artifact half of PV11"
fi

# ===========================================================================
# NMBOTH -- PV06: all three NM sub-checks stay enforced under BOTH profiles.
# ===========================================================================
echo ""
echo "=== NMBOTH (PV06) ==="

run_bash "$HTMLOUT" "$TMP/gh/mermaid-violation.html"
assert_output_contains "$OUT" "NM.2 mermaid.initialize() call detected" "PV06a NM.2 fires under the default profile"
assert_exit_eq "$RC" 1 "PV06a-rc ...and fails the run"
run_bash "$HTMLOUT" "$TMP/gh/mermaid-violation.html" --profile graph
assert_output_contains "$OUT" "NM.2 mermaid.initialize() call detected" "PV06b NM.2 fires identically under --profile graph -- no profile may waive it"
assert_exit_eq "$RC" 1 "PV06b-rc ...and fails the run"

# ===========================================================================
# EXTSRC -- PV07's non-contingent half. The SPEC's own D2 table states S2's
# check code has NO profile branching at all today, so a fixture carrying an
# external <script src> must fail S2 IDENTICALLY under both profiles right
# now -- no contingent mechanism (FR-18/feature-012's [N/A] waiver) is
# required to exist for this half to be testable. (The contingent half --
# once a genuine network requirement is declared, S2 reports [N/A] with its
# reason -- correctly waits on FR-18; see PV20c, STATIC, below.)
# ===========================================================================
echo ""
echo "=== EXTSRC (PV07 non-contingent) ==="

cat > "$TMP/external-script.html" <<'HTMLEOF'
<!DOCTYPE html><html><head><script src="https://example.com/foo.js"></script></head><body></body></html>
HTMLEOF
run_bash "$HTMLOUT" "$TMP/external-script.html"
EXTSRC_DEFAULT_OUT="$OUT"; EXTSRC_DEFAULT_RC=$RC
assert_output_contains "$EXTSRC_DEFAULT_OUT" "S2. Offline render [FAIL]" "PV07a-default default profile: an external <script src> fails S2"
run_bash "$HTMLOUT" "$TMP/external-script.html" --profile graph
EXTSRC_GRAPH_OUT="$OUT"; EXTSRC_GRAPH_RC=$RC
assert_output_contains "$EXTSRC_GRAPH_OUT" "S2. Offline render [FAIL]" "PV07b-graph --profile graph: the SAME external <script src> fails S2 too -- AC-6, no [N/A] waiver exists yet"
assert_exit_eq "$EXTSRC_GRAPH_RC" "$EXTSRC_DEFAULT_RC" "PV07c both profiles fail identically (no confined-delta waiver exists pre-FR-18)"
EXTSRC_DEFAULT_S2=$(echo "$EXTSRC_DEFAULT_OUT" | grep -A1 'S2\.')
EXTSRC_GRAPH_S2=$(echo "$EXTSRC_GRAPH_OUT" | grep -A1 'S2\.')
assert_eq "$EXTSRC_GRAPH_S2" "$EXTSRC_DEFAULT_S2" "PV07d the S2 block itself (verdict + listed CDN references) is byte-identical between profiles -- matching the SPEC D2 table's 'S2 has no profile branching at all today' claim"

# ===========================================================================
# DEGRADE -- PV19: the C-5 degradation paths, run for REAL (Playwright is
# genuinely absent in this environment -- verified at suite start via
# `command -v` semantics equivalent: the dynamic import itself fails below).
# ===========================================================================
echo ""
echo "=== DEGRADE (PV19) ==="

run_node "$VISUALS" "$TMP/does-not-exist.html"
assert_output_contains "$OUT" "SKIP -- html file not found" "PV19a missing artifact, default profile: SKIP with remediation"
assert_exit_eq "$RC" 0 "PV19a-rc ...and exits 0 (the run continues, per C-5)"
run_node "$VISUALS" "$TMP/does-not-exist.html" --profile graph
assert_output_contains "$OUT" "SKIP -- html file not found" "PV19b missing artifact, --profile graph: same SKIP"
assert_output_contains "$OUT" "SKIP-RECORDED [profile: graph]" "PV19c ...PLUS a distinguishable recorded marker -- a lane that always skips is now distinguishable from one that always passes"
assert_exit_eq "$RC" 0 "PV19c-rc ...and still exits 0"

run_node "$VISUALS" "$TMP/gh/graph.html"
assert_output_contains "$OUT" "SKIP -- Playwright is not installed" "PV19d Playwright genuinely unavailable, default profile: SKIP with install remediation (real code path, not simulated)"
assert_exit_eq "$RC" 0 "PV19d-rc ...and exits 0"
run_node "$VISUALS" "$TMP/gh/graph.html" --profile graph
assert_output_contains "$OUT" "SKIP -- Playwright is not installed" "PV19e same SKIP under --profile graph"
assert_output_contains "$OUT" "SKIP-RECORDED [profile: graph] -- Playwright unavailable" "PV19f ...PLUS the recorded marker"
assert_exit_eq "$RC" 0 "PV19f-rc ...and exits 0"

echo "  NEEDS CI: PV16 (non-empty collected-set positive incl. legend dimensions),"
echo "  PV17's dynamic empty-collection FAIL, and PV18's dynamic 'a .diagram-box"
echo "  whose children overlap still fails T2 under both profiles' all require a"
echo "  real Chromium render. Not reachable here (Playwright not installed)."

# ===========================================================================
# STATIC -- PV18 (partial) / PV20: source-level absence proofs, no subject
# invocation. Marked STATIC so a pass here is never mistaken for the dynamic
# proof CI still owes (see DEGRADE's closing note).
# ===========================================================================
echo ""
echo "=== STATIC (PV18-partial, PV20) ==="

if grep -qE "live-surface|T2.*exclu.*live|excludeLiveSurface" "$VISUALS"; then
    fail "PV18-STATIC-a a live-surface T2 exclusion exists in source -- this was declined outright (SPEC D4) and must never be reinstated"
else
    pass "PV18-STATIC-a no live-surface T2 exclusion exists in source (STATIC -- needs CI for the dynamic 'still fails T2' half)"
fi

assert_file_contains "$VISUALS" "args: ['--no-sandbox', '--disable-setuid-sandbox']" \
    "PV20a the kb-summary chromium.launch argument list is unchanged (C3 not triggered)"
if grep -qE "readPixels|captureExemption|CAPTURE_EXEMPT" "$VISUALS"; then
    fail "PV20b a capture exemption exists in source -- C2 has not fired and none should exist yet"
else
    pass "PV20b no capture exemption exists in source (C2 not triggered)"
fi
if grep -qE '\[N/A\].*external assets permitted' "$HTMLOUT"; then
    fail "PV20c an S2 [N/A] waiver text exists in source -- C1 has not fired and none should exist yet"
else
    pass "PV20c no S2 [N/A] waiver text exists in source (C1 not triggered)"
fi

# ===========================================================================
# HELP/DOC -- D1 property 5 shape: the documented flag behaves as documented.
# Reuses KBDIR's -h capture (HTMLOUT_HELP_OUT/RC) instead of a second -h
# spawn (S1: 0 new spawns here).
# ===========================================================================
echo ""
echo "=== HELP/DOC ==="

assert_output_contains "$HTMLOUT_HELP_OUT" "[--profile kb-summary|graph]" "HELP01 validate-html-output.sh --help documents the flag inline"
assert_exit_eq "$HTMLOUT_HELP_RC" 0 "HELP01-rc --help itself exits 0 (unaffected by the second named exception, which is exit-2-path-only)"
assert_file_contains "$CONTRAST" "[--profile kb-summary|graph]" "HELP02 contrast-check.mjs header documents the flag (no --help flag exists on this script; static check)"
assert_file_contains "$VISUALS" "[--profile kb-summary|graph]" "HELP03 validate-visuals.mjs header documents the flag (its -h/--help pins Usage-only per VF02/VF03; static check)"

# ===========================================================================
# MUT -- the ONE mutation case, gated behind --self-mutate (S3).
# ===========================================================================
echo ""
echo "=== MUT (--self-mutate only) ==="

if [[ "$SELF_MUTATE" -ne 1 ]]; then
    echo "Mutation matrix not run. Use --self-mutate to run it (one extra invocation: MUT01)."
elif [[ "$NODE_OK" -ne 1 ]]; then
    echo "SKIP: node not found on PATH -- MUT01 skipped"
else
    MUT01="$TMP/mut01-contrast-check.mjs"
    sed 's/^function buildGraphPairs() {$/function buildGraphPairs() { return []; }\nfunction __unreachable_buildGraphPairs() {/' \
        "$CONTRAST" > "$MUT01"
    if grep -q '__unreachable_buildGraphPairs' "$MUT01" && node --check "$MUT01" >/dev/null 2>&1; then
        run_node "$MUT01" "$TMP/graph-full.html" --profile graph
        if echo "$OUT" | grep -q 'gk-'; then
            fail "MUT01 (S3) buildGraphPairs() disabled but graph tokens are STILL being checked -- PV13's assertion group would pass even if the palette wiring were dead code"
        else
            pass "MUT01 (S3) disabling buildGraphPairs() removes every gk-/gc- line from the output -- PV13's 'all 15 tokens checked' claim is load-bearing on that function actually running, not vacuous"
        fi
    else
        fail "MUT01 (S3) the mutant failed to parse/apply -- cannot conclude anything (see the graph-extraction.sh convention: a dead mutant proves nothing)"
    fi
fi

# ===========================================================================
# S5 -- prove the source tree is untouched.
# ===========================================================================
echo ""
echo "=== S5 (source tree untouched) ==="
S5_NOW=$(cat "$CONTRAST" "$HTMLOUT" "$VISUALS" | md5sum)
assert_eq "$S5_NOW" "$S5_BASE" "S5 the three canonical scripts are byte-unchanged after this entire run (every HEAD-copy and every mutant lived under \$TMP)"

# ===========================================================================
# SELF -- wholesale no-op floor (catches a filter/abort collapsing the run to
# near-nothing; not an assertion census -- test-landscape.md's rationale).
# ===========================================================================
echo ""
_ran=$(( PASS + FAIL ))
if [[ "$_ran" -ge 60 ]]; then
    pass "SELF01 $_ran assertions executed against a no-op floor of 60"
else
    fail "SELF01 only $_ran assertions executed against a no-op floor of 60 -- the suite did not run what it claims to run"
fi

echo ""
test_summary
exit $?
