#!/usr/bin/env bash
# test-validator-behavior.sh -- behavioral assertions for the three summarize
# validators: contrast-check.mjs, validate-html-output.sh, validate-visuals.mjs.
#
# Covers: theme-divergence checks (corrected dark-theme extraction, three-verdict
# discrimination), --kb-dir semantics (sets NO resolution basis), L1/L2 link
# resolution, NM/no-Mermaid-engine enforcement, S2 offline-render enforcement,
# Playwright/missing-artifact graceful-degradation paths, grade-summary.sh token
# isolation, and source-integrity (S5).
#
# COVERS: canonical/aid/scripts/summarize/contrast-check.mjs
# COVERS: canonical/aid/scripts/summarize/validate-html-output.sh
# COVERS: canonical/aid/scripts/summarize/validate-visuals.mjs
#
# Usage:
#   bash test-validator-behavior.sh [-v | --verbose]
#
# Exit codes: 0 all pass / 1 any fail. Skips groups needing Node when node is
# absent (assertions over contrast-check.mjs / validate-visuals.mjs).
#
# ---------------------------------------------------------------------------
# NOTE -- W5-12 (tech-debt.md), NOT asserted here on purpose. contrast-check.mjs's
# header documents exit 2 for a missing file, but a missing file actually
# exits 1 via an uncaught ENOENT rejection from fs.readFile -- verified
# against the working tree, so the defect predates this suite and is
# untouched. Pinning exit 1 as "correct" here would fight a future fix.
# Left unasserted deliberately.
#
# NOTE -- environment ceilings (verified this session, not assumed):
#   * Playwright is genuinely NOT INSTALLED in this environment (`import('playwright')`
#     rejects with MODULE_NOT_FOUND). This is exploited, not merely tolerated: the
#     DEGRADE group below runs validate-visuals.mjs's real "Playwright unavailable"
#     SKIP branch for real, because the branch it needs IS the branch this host takes.
#   * What genuinely CANNOT run here: any assertion needing an actual Chromium render
#     (PV16 non-empty-collection positive, PV17's dynamic empty-collection behaviour,
#     PV18's dynamic T2-overlap proof). Each such assertion below is replaced by a
#     STATIC source-property check (grep, no subject invocation) and is labelled
#     "STATIC -- needs CI to become dynamic".
#
# ---------------------------------------------------------------------------
# S1 -- SUBJECT INVOCATION BUDGET (subprocess spawns of the three scripts under
# test; grep/md5sum calls on source text are NOT subject invocations and are
# not counted here). Every number below is derived by counting run_node/run_bash
# call sites, never the wrapper body once:
#   COMPARE      5  (PV01a contrast default-path, PV01d2 diverge-differs,
#                     PV01d3 diverge-identical, PV01e HTML default,
#                     PV01g visuals default)
#   GRADE-TOKENS 3  (one error-path capture per script; reused by assertions
#                     below -- 0 additional spawns in the assertion loop)
#   VACUOUS      3  (PV08 vacuous fixture, PV05 populated fixture default,
#                     PV05d broken-companion)
#   KBDIR        3  (PV09a with-flag, PV09b decoy-dir, PV09c -h)
#   DIVERGE      3  (PV11a no-dark, PV11b dark-empty, PV12 dark-3block)
#   KBHTML       1  (PV11 real-artifact run over .aid/knowledge/kb.html)
#   NM           1  (PV06a mermaid-violation fixture)
#   EXTSRC       1  (PV07a external-script fixture)
#   DEGRADE      2  (PV19a missing-artifact, PV19d no-playwright)
#   STATIC       0  (grep/source checks, not subject invocations)
#   S5           0  (md5sum, not a subject invocation)
#   ------------------------------------------------------------------
#   TOTAL        5+3+3+3+3+1+1+1+2 = 22 subprocess spawns in default mode.
#   In-process: 0 (bash sourcing tests/lib/assert.sh only).
#
# S2 -- every $OUT is captured ONCE per invocation above and read with builtin
#   grep/string-compare helpers; no assertion re-invokes a subject to re-derive
#   a value already captured.
#
# S4 -- nothing here trades coverage for time; DEGRADE and divergence checks
#   in particular are exactly the areas named as highest-value, and neither
#   is trimmed for spawn count.
#
# S5 -- proved at the bottom: md5sum of the three canonical scripts, taken
#   before any fixture work and re-verified at the end. This suite never
#   writes to canonical/; every fixture lives under $TMP.
# ---------------------------------------------------------------------------

set -u

VERBOSE=0
for a in "$@"; do
    case "$a" in
        -v|--verbose)   VERBOSE=1 ;;
        *) echo "test-validator-behavior.sh: unknown argument: $a" >&2; exit 2 ;;
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

# --- S5 baseline: taken now, before any fixture or mutant work --------------
S5_BASE=$(cat "$CONTRAST" "$HTMLOUT" "$VISUALS" | md5sum)

# --- Fixture root -------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run_node() { OUT=$(node "$@" 2>&1); RC=$?; }
run_bash() { OUT=$(bash "$@" 2>&1); RC=$?; }

echo ""
echo "=== Fixture construction ==="

# --- Chrome-only fixture (no dark block -- theme-divergence N/A case) --------
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/chrome-only.html"

# --- Theme-divergence discrimination fixtures (PV01d1-PV01d3) ---------------
# Three fixtures for three verdicts. chrome-only.html above supplies the first
# (no dark block at all -> N/A); these two supply the other two.
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{--text:#ffffff;--bg:#000000;}</style>\n' > "$TMP/diverge-differs.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/diverge-identical.html"

# --- Divergence fixtures (PV11/PV12) ----------------------------------------
printf '<style>:root{--text:#000000;--bg:#ffffff;}</style>\n' > "$TMP/no-dark.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{color-scheme:dark;}</style>\n' > "$TMP/dark-empty.html"
printf '<style>:root{--text:#000000;--bg:#ffffff;}html[data-theme="dark"]{color-scheme:dark;}html[data-theme="dark"]{--text:#ffffff;--bg:#111111;}@media print{html[data-theme="dark"]{--text:#000000;--bg:#ffffff;}}</style>\n' > "$TMP/dark-3block.html"

# --- validate-html-output.sh fixtures ---------------------------------------
# A minimal but FULLY clean fixture (all structural/A1-A5/S2/NM checks pass)
# carrying the footer + noscript link set: ./architecture.md,
# ./external-sources.md (footer) + ./INDEX.md (noscript).
mkdir -p "$TMP/gh"
: > "$TMP/gh/architecture.md"
: > "$TMP/gh/external-sources.md"
: > "$TMP/gh/INDEX.md"
cat > "$TMP/gh/summary.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<title>Summary</title>
<!-- color-scheme: light dark -->
<style>:focus-visible{outline:2px;} @media (prefers-reduced-motion: reduce){*{}}</style>
</head>
<body>
<a class="skip-link" href="#top">Skip to content</a>
<header role="banner"><nav aria-label="Breadcrumb"><a href="/">Home</a></nav></header>
<main id="top"><h1 id="h1">Summary</h1></main>
<div id="lightbox" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="lb-cap">
  <div id="lb-cap"></div>
</div>
<footer><a href="./architecture.md">rel</a> <a href="./external-sources.md">ext</a></footer>
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
<head><meta charset="UTF-8"><title>Summary</title>
<!-- color-scheme: light dark -->
<style>:focus-visible{outline:2px;} @media (prefers-reduced-motion: reduce){*{}}</style>
</head>
<body>
<a class="skip-link" href="/">Skip</a>
<header role="banner"><nav aria-label="Breadcrumb"></nav></header>
<main id="top"><h1>Summary</h1></main>
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

# A Mermaid-violating fixture (NM.2), for PV06a's enforcement check.
cat > "$TMP/gh/mermaid-violation.html" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><title>T</title></head>
<body><main><script>mermaid.initialize({});</script></main></body></html>
HTMLEOF

echo "Fixtures built under $TMP"

# ===========================================================================
# COMPARE -- PV01: the default path prints no Profile: line and exercises
# the theme-divergence check. Three inputs → three divergence verdicts
# proves the check is not a rubber stamp.
# ===========================================================================
echo ""
echo "=== COMPARE (PV01) ==="

# --- contrast-check.mjs --------------------------------------------------
run_node "$CONTRAST" "$TMP/chrome-only.html"
WORK_DEFAULT_OUT="$OUT"; WORK_DEFAULT_RC=$RC
assert_exit_eq "$WORK_DEFAULT_RC" 0 "PV01a contrast-check.mjs default path exits 0 on the chrome-only fixture"
assert_output_not_contains "$WORK_DEFAULT_OUT" "FAIL" "PV01b contrast-check.mjs default path over the chrome-only fixture reports no FAIL"
assert_output_not_contains "$WORK_DEFAULT_OUT" "Profile:" "PV01c contrast-check.mjs prints NO Profile: line -- flag removed, nothing ever prints this"

assert_output_contains "$WORK_DEFAULT_OUT" "Theme divergence" "PV01d the theme-divergence check runs on the default path"
assert_output_contains "$WORK_DEFAULT_OUT" "nothing to diverge from" "PV01d1 ... and reports N/A when the source declares no dark-theme block"
run_node "$CONTRAST" "$TMP/diverge-differs.html"
assert_output_contains "$OUT" "dark theme differs from light" "PV01d2 ... PASSES when the dark block differs from light on a declared token"
run_node "$CONTRAST" "$TMP/diverge-identical.html"
assert_output_contains "$OUT" "FAIL Theme divergence" "PV01d3 ... FAILS when the dark block reports the light theme's values -- three distinct verdicts over three inputs, so the check cannot be a rubber stamp"

# --- validate-html-output.sh --------------------------------------------
run_bash "$HTMLOUT" "$TMP/gh/summary.html"
WORK_HTML_DEFAULT_OUT="$OUT"; WORK_HTML_DEFAULT_RC=$RC
assert_output_not_contains "$WORK_HTML_DEFAULT_OUT" "Profile:" "PV01e validate-html-output.sh prints NO Profile: line on the default path"

# --- validate-visuals.mjs (this host has no Playwright, so the run below takes
# the real "Playwright unavailable" SKIP branch -- see the environment note) --
run_node "$VISUALS" "$TMP/gh/summary.html"
WORK_VIS_DEFAULT_OUT="$OUT"; WORK_VIS_DEFAULT_RC=$RC
assert_output_not_contains "$WORK_VIS_DEFAULT_OUT" "Profile:" "PV01g validate-visuals.mjs prints NO Profile: line on the default path"

# ===========================================================================
# GRADE-TOKENS -- AC-2: grade-summary.sh's own grep patterns for S2/NM/L1/L2's
# "[PASS]"/"resolve" markers and the C1/C2 pass-summary literal must not match
# the invocation-error output of any of the three scripts.
#
# Error-path captures: each script is invoked in a way that produces only
# usage/error text (no html to process). Patterns are EXTRACTED from
# grade-summary.sh at runtime so this section cannot drift from the real
# patterns grade-summary.sh uses (a prior version hand-copied patterns
# with mis-escapes that could never fail for the reason claimed).
# ===========================================================================
echo ""
echo "=== GRADE-TOKENS (AC-2) ==="

# Capture error-path output from each script (3 spawns; reused by assertions below).
run_node "$CONTRAST"                       # no args -> exits 2 with usage
CONTRAST_USAGE_OUT="$OUT"
assert_exit_eq "$RC" 2 "GT-ERR-contrast error path exits 2"

run_bash "$HTMLOUT" "$TMP/nonexistent.html"  # missing file -> exits 2 with usage
HTMLOUT_USAGE_OUT="$OUT"
assert_exit_eq "$RC" 2 "GT-ERR-htmlout error path exits 2"

run_node "$VISUALS"                        # no args -> exits 2 with usage
VISUALS_USAGE_OUT="$OUT"
assert_exit_eq "$RC" 2 "GT-ERR-visuals error path exits 2"

GRADE_SUMMARY="${REPO_ROOT}/canonical/aid/scripts/summarize/grade-summary.sh"
assert_file_exists "$GRADE_SUMMARY" "GT-SETUP grade-summary.sh found for pattern extraction"

extract_gs_pattern() {
    local marker="$1"
    grep -E "$marker" "$GRADE_SUMMARY" | head -1 | grep -oE '"[^"]+"' | head -1 | sed 's/^"//;s/"$//'
}

GT_S2_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[S2\]=pass')
GT_NM_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[NM\]=pass')
GT_L1_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[L1\]=pass')
GT_L2_PAT=$(extract_gs_pattern 'grep -qE.*RESULTS\[L2\]=pass')
GT_SUMMARY_PAT=$(extract_gs_pattern 'grep -q .*All contrast checks passed')

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
# validate-html-output.sh's default profile.
# ===========================================================================
echo ""
echo "=== VACUOUS (PV05, PV08) ==="

run_bash "$HTMLOUT" "$TMP/gh/vacuous.html"
assert_output_contains "$OUT" "L1. 0/0 anchor links resolve" "PV08a default profile: 0/0 anchors is reported as a pass (not a VACUOUS failure)"
assert_output_contains "$OUT" "L2. 0/0 relative md links resolve" "PV08b default profile: 0/0 md links is reported as a pass"
assert_exit_eq "$RC" 0 "PV08c default profile: vacuous fixture exits 0 (structural checks are otherwise clean)"

run_bash "$HTMLOUT" "$TMP/gh/summary.html"
GH_DEFAULT_OUT="$OUT"; GH_DEFAULT_RC=$RC   # reused by KBDIR below -- 0-spawn reuse
assert_output_contains "$OUT" "L2. 3/3 relative md links resolve" "PV05a populated fixture: L2's set is exactly architecture.md + external-sources.md (footer) + INDEX.md (noscript) = 3"

rm -f "$TMP/gh/external-sources.md"
run_bash "$HTMLOUT" "$TMP/gh/summary.html"
assert_output_contains "$OUT" "L2. 1 md link(s) broken (of 3)" "PV05d removing one companion file: L2 fails naming the missing target's count"
assert_exit_eq "$RC" 1 "PV05e broken L2 target fails the run"
: > "$TMP/gh/external-sources.md"   # restore for later groups

# ===========================================================================
# KBDIR -- PV09: --kb-dir sets NO resolution basis (D2's decision). Three
# things to prove: (1) passing --kb-dir changes no verdict on a genuinely
# passing fixture, (2) a companion .md that exists in the --kb-dir target but
# NOT beside the artifact still fails L2 (the decoy-dir case), (3) --help
# and the header comment both say so.
# ===========================================================================
echo ""
echo "=== KBDIR (PV09) ==="

# PV09a: --kb-dir on the SAME passing fixture changes no verdict and no exit
# status. NOFLAG reuses GH_DEFAULT_OUT/RC captured in VACUOUS above (0-spawn
# reuse); only the WITH-flag run is a new spawn.
run_bash "$HTMLOUT" "$TMP/gh/summary.html" --kb-dir "$TMP/nonexistent-basis-dir"
assert_exit_eq "$RC" "$GH_DEFAULT_RC" "PV09a-rc --kb-dir changes no exit status on a passing fixture (even pointed at a directory that does not exist)"
NOFLAG_BODY=$(echo "$GH_DEFAULT_OUT" | sed 's/(kb-dir=.*)/(kb-dir=X)/')
WITHFLAG_BODY=$(echo "$OUT" | sed 's/(kb-dir=.*)/(kb-dir=X)/')
assert_eq "$WITHFLAG_BODY" "$NOFLAG_BODY" "PV09a-body every line other than L2's own kb-dir=... banner is byte-identical with/without --kb-dir"

# PV09b: the decoy-dir case. external-sources.md exists in the dir --kb-dir
# names, but deliberately NOT beside the artifact. --kb-dir must not rescue it.
mkdir -p "$TMP/decoy" "$TMP/gh2"
: > "$TMP/decoy/external-sources.md"
: > "$TMP/gh2/architecture.md"
: > "$TMP/gh2/INDEX.md"
cp "$TMP/gh/summary.html" "$TMP/gh2/summary.html"
run_bash "$HTMLOUT" "$TMP/gh2/summary.html" --kb-dir "$TMP/decoy"
assert_output_contains "$OUT" "L2. 1 md link(s) broken (of 3)" "PV09b --kb-dir pointed at a directory where the missing companion DOES exist does not rescue L2 -- resolution is against the artifact's own directory only, never --kb-dir"
assert_exit_eq "$RC" 1 "PV09b-rc ...and the run still fails"

# PV09c: --help and the header comment both document the true behaviour.
run_bash "$HTMLOUT" -h
HTMLOUT_HELP_OUT="$OUT"; HTMLOUT_HELP_RC=$RC
assert_output_contains "$HTMLOUT_HELP_OUT" "sets NO resolution basis" "PV09c-help --help documents that --kb-dir sets no resolution basis"
assert_file_contains "$HTMLOUT" "sets NO resolution basis" "PV09c-header ...and so does the header comment, not only --help's rendering of it"
assert_exit_eq "$HTMLOUT_HELP_RC" 0 "PV09c-rc --help exits 0"

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
assert_exit_eq "$RC" 1 "PV11b-rc ...and this now fails the run"

run_node "$CONTRAST" "$TMP/dark-3block.html"
LIGHT_RATIO=$(echo "$OUT" | sed -n '/\[light theme\]/,/\[dark theme\]/p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
DARK_RATIO=$(echo "$OUT" | sed -n '/\[dark theme\]/,$p' | grep -m1 'body text on bg' | grep -oE '[0-9]+\.[0-9]+:1')
assert_eq "$LIGHT_RATIO" "21.00:1" "PV12a light ratio is the plain :root block (black on white)"
assert_eq "$DARK_RATIO" "18.88:1" "PV12b dark ratio comes from the SECOND dark block (text:#fff/bg:#111) -- NOT the color-scheme-only first block and NOT the @media print third block"
assert_output_contains "$OUT" "Theme divergence: dark theme differs from light" "PV12c divergence correctly reports PASS -- the print block's light-value shadow did not win"

# ===========================================================================
# KBHTML -- PV11's real-artifact half. PV11's own criterion text requires the
# theme-divergence check to pass over the SHIPPED .aid/knowledge/kb.html, not
# only over synthetic shape-alikes (DIVERGE above uses only synthetic fixtures).
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
# NM -- PV06: all three NM sub-checks are enforced unconditionally.
# ===========================================================================
echo ""
echo "=== NM (PV06) ==="

run_bash "$HTMLOUT" "$TMP/gh/mermaid-violation.html"
assert_output_contains "$OUT" "NM.2 mermaid.initialize() call detected" "PV06a NM.2 fires on a mermaid.initialize() fixture"
assert_exit_eq "$RC" 1 "PV06a-rc ...and fails the run"

# ===========================================================================
# EXTSRC -- PV07: S2 fails on an external <script src>.
# ===========================================================================
echo ""
echo "=== EXTSRC (PV07) ==="

cat > "$TMP/external-script.html" <<'HTMLEOF'
<!DOCTYPE html><html><head><script src="https://example.com/foo.js"></script></head><body></body></html>
HTMLEOF
run_bash "$HTMLOUT" "$TMP/external-script.html"
assert_output_contains "$OUT" "S2. Offline render [FAIL]" "PV07a-default an external <script src> fails S2"

# ===========================================================================
# DEGRADE -- PV19: the C-5 degradation paths. Playwright is genuinely absent
# in this environment -- the real "Playwright unavailable" SKIP branch is
# exercised directly (not simulated).
# ===========================================================================
echo ""
echo "=== DEGRADE (PV19) ==="

run_node "$VISUALS" "$TMP/does-not-exist.html"
assert_output_contains "$OUT" "SKIP -- html file not found" "PV19a missing artifact: SKIP with remediation"
assert_exit_eq "$RC" 0 "PV19a-rc ...and exits 0 (the run continues, per C-5)"

run_node "$VISUALS" "$TMP/gh/summary.html"
assert_output_contains "$OUT" "SKIP -- Playwright is not installed" "PV19d Playwright genuinely unavailable: SKIP with install remediation (real code path, not simulated)"
assert_exit_eq "$RC" 0 "PV19d-rc ...and exits 0"

echo "  NEEDS CI: PV16 (non-empty collected-set positive), PV17's dynamic"
echo "  empty-collection behaviour, and PV18's dynamic T2-overlap proof all"
echo "  require a real Chromium render. Not reachable here (Playwright not installed)."

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
    "PV20a the chromium.launch argument list is unchanged (C3 not triggered)"
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
# HELP/DOC -- --kb-dir is documented by --help and the header comment.
# ===========================================================================
echo ""
echo "=== HELP/DOC ==="

# HTMLOUT_HELP_OUT captured in KBDIR above (0 new spawns).
assert_output_contains "$HTMLOUT_HELP_OUT" "--kb-dir DIR" "HELP01 validate-html-output.sh --help documents the --kb-dir flag"
assert_file_contains "$HTMLOUT" "--kb-dir DIR" "HELP01-header the header comment also documents --kb-dir"

# ===========================================================================
# S5 -- prove the source tree is untouched.
# ===========================================================================
echo ""
echo "=== S5 (source tree untouched) ==="
S5_NOW=$(cat "$CONTRAST" "$HTMLOUT" "$VISUALS" | md5sum)
assert_eq "$S5_NOW" "$S5_BASE" "S5 the three canonical scripts are byte-unchanged after this entire run (every fixture lived under \$TMP)"

# ===========================================================================
# SELF -- wholesale no-op floor (catches a filter/abort collapsing the run to
# near-nothing; not an assertion census -- test-landscape.md's rationale).
# ===========================================================================
echo ""
_ran=$(( PASS + FAIL ))
if [[ "$_ran" -ge 50 ]]; then
    pass "SELF01 $_ran assertions executed against a no-op floor of 50"
else
    fail "SELF01 only $_ran assertions executed against a no-op floor of 50 -- the suite did not run what it claims to run"
fi

echo ""
test_summary
exit $?
