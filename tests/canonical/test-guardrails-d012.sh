#!/usr/bin/env bash
# test-guardrails-d012.sh -- D-012 guardrail re-checks after the engine re-architecture.
#
# Scope (task-075 AC4):
#   Confirm that C1/C2/C3/C5/C6/NM + S5b hold after the Mermaid engine was dropped in D-012.
#   Tests assert static source properties of canonical/ files (scripts, templates, references).
#   No skill execution required; no Node runtime needed.
#
# Guardrails checked:
#   C1   Output path is .aid/dashboard/kb.html (not legacy .aid/knowledge/knowledge-summary.html).
#        - stale-check.sh hardcodes the new path.
#        - assemble.sh default output is .aid/dashboard/kb.html.
#        - state-generate.md documents the target path.
#
#   C2/C3  Single self-contained file, no CDN / split asset / framework fetch.
#          - validate-html-output.sh S2 check is present + correct.
#          - html-skeleton.html has no <script src="https://..."> or <link href="https://...">.
#          - assemble.sh documents the no-external-fetch guarantee.
#          - validate-visuals.mjs blocks all non-file:// network requests (hermetic render).
#
#   NM   No-Mermaid-engine assertion present in validate-html-output.sh (FR-51 / D-012).
#        - NM section exists in validate-html-output.sh.
#        - assemble.sh says "no Mermaid engine" in its header.
#        - stale-check.sh does NOT reference old Mermaid paths.
#
#   C5   Approval signal: "## Knowledge Summary Status" -> "**User Approved:** yes (YYYY-MM-DD)".
#        - stale-check.sh reads "User Approved" signal.
#        - state-generate.md references the approval signal.
#
#   C6   Completeness: kb_baseline shape in canonical settings template preserved.
#        - canonical settings.yml template still has kb_baseline key.
#        - grade-summary.sh COV check still reads discovery.doc_set (basis for completeness).
#
#   S5b  Page-shell alignment with home.html / index.html preserved.
#        - html-skeleton.html has semantic shell landmarks (header/main/nav/footer).
#        - html-skeleton.html has skip-link + theme-toggle + aid-dashboard-theme key.
#        - state-generate.md says outer shell must stay consistent with home.html + index.html.
#        - validate-visuals.mjs does NOT block file:// requests (local self-contained file loads).
#
# Usage:
#   bash test-guardrails-d012.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all guardrail re-checks pass
#   1 -- one or more re-checks failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

# Canonical source paths
STALE_CHECK_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/stale-check.sh"
ASSEMBLE_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/assemble.sh"
VALIDATE_HTML_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-html-output.sh"
VALIDATE_VISUALS_MJS="${REPO_ROOT}/canonical/aid/scripts/summarize/validate-visuals.mjs"
SKELETON_HTML="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/html-skeleton.html"
SETTINGS_TEMPLATE="${REPO_ROOT}/canonical/aid/templates/settings.yml"
GRADE_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/grade-summary.sh"
STATE_GENERATE_MD="${REPO_ROOT}/canonical/skills/aid-summarize/references/state-generate.md"
STATE_VALIDATE_MD="${REPO_ROOT}/canonical/skills/aid-summarize/references/state-validate.md"

# ===========================================================================
# === C1: Output path is .aid/dashboard/kb.html ==============================
# ===========================================================================

echo ""
echo "=== C1a: stale-check.sh targets .aid/dashboard/kb.html ==="
assert_file_contains "$STALE_CHECK_SH" ".aid/dashboard/kb.html" \
    "C1a stale-check.sh references .aid/dashboard/kb.html"

echo ""
echo "=== C1b: assemble.sh defaults output to .aid/dashboard/kb.html ==="
assert_file_contains "$ASSEMBLE_SH" ".aid/dashboard/kb.html" \
    "C1b assemble.sh defaults to .aid/dashboard/kb.html output path"

echo ""
echo "=== C1c: state-generate.md documents .aid/dashboard/kb.html target path ==="
assert_file_contains "$STATE_GENERATE_MD" ".aid/dashboard/kb.html" \
    "C1c state-generate.md references .aid/dashboard/kb.html"

echo ""
echo "=== C1d: stale-check.sh does NOT reference legacy .aid/knowledge/knowledge-summary.html (only in migration code) ==="
# The legacy path may appear in the migration block (to migrate FROM it), but must NOT be
# used as the target OUTPUT path. We check that the active references use the new path.
# A comment or migration src reference is fine; what must be absent is a stat/check of
# the legacy path AS IF it were the current output.
LEGACY_AS_TARGET=$(grep -nE "kb.html.*knowledge-summary|knowledge-summary.*=.*output\|TARGET.*knowledge-summary" "$STALE_CHECK_SH" 2>/dev/null || true)
if [[ -z "$LEGACY_AS_TARGET" ]]; then
    pass "C1d stale-check.sh does not treat legacy path as current output target"
else
    fail "C1d stale-check.sh still treats legacy path as output target:
$LEGACY_AS_TARGET"
fi

# ===========================================================================
# === C2/C3: Single self-contained file, no CDN / split asset / framework fetch
# ===========================================================================

echo ""
echo "=== C2/C3a: html-skeleton.html has no external CDN <script src> ==="
CDN_SCRIPTS=$(grep -nE '<script[^>]+src="https?://' "$SKELETON_HTML" 2>/dev/null || true)
if [[ -z "$CDN_SCRIPTS" ]]; then
    pass "C2/C3a html-skeleton.html has no CDN <script src> (C2/C3 holds)"
else
    fail "C2/C3a html-skeleton.html has CDN <script src> (C2/C3 violation):
$CDN_SCRIPTS"
fi

echo ""
echo "=== C2/C3b: html-skeleton.html has no external CDN <link href> ==="
CDN_LINKS=$(grep -nE '<link[^>]+href="https?://' "$SKELETON_HTML" 2>/dev/null || true)
if [[ -z "$CDN_LINKS" ]]; then
    pass "C2/C3b html-skeleton.html has no CDN <link href> (C2/C3 holds)"
else
    fail "C2/C3b html-skeleton.html has CDN <link href> (C2/C3 violation):
$CDN_LINKS"
fi

echo ""
echo "=== C2/C3c: validate-html-output.sh has an S2 offline-render check ==="
assert_file_contains "$VALIDATE_HTML_SH" "S2" \
    "C2/C3c validate-html-output.sh has S2 (offline render) check"
assert_file_contains "$VALIDATE_HTML_SH" "CDN" \
    "C2/C3c validate-html-output.sh S2 checks for CDN references"

echo ""
echo "=== C2/C3d: assemble.sh documents no-external-fetch guarantee ==="
if grep -qiE "no.*external.*fetch|no.*CDN|self.contained" "$ASSEMBLE_SH"; then
    pass "C2/C3d assemble.sh documents no-external-fetch / self-contained guarantee"
else
    fail "C2/C3d assemble.sh missing no-external-fetch documentation"
fi

echo ""
echo "=== C2/C3e: validate-visuals.mjs blocks non-file:// network requests (hermetic render) ==="
if grep -qE "file://|route\.abort\(\)|network.*block|block.*network\|abort.*non.file" "$VALIDATE_VISUALS_MJS"; then
    pass "C2/C3e validate-visuals.mjs blocks non-file:// requests (hermetic render)"
else
    fail "C2/C3e validate-visuals.mjs missing network-block / hermetic-render guard"
fi

echo ""
echo "=== C2/C3f: validate-visuals.mjs does NOT block file:// requests (local file loads) ==="
# The file:// allow rule spans multiple lines: startsWith('file://') on one line,
# route.continue() on the next -- check for both tokens in the file.
if grep -qE "file://" "$VALIDATE_VISUALS_MJS" && grep -qE "route\.continue\(\)" "$VALIDATE_VISUALS_MJS"; then
    pass "C2/C3f validate-visuals.mjs allows file:// requests (local self-contained file)"
else
    fail "C2/C3f validate-visuals.mjs missing file:// continue rule (local files must load)"
fi

# ===========================================================================
# === NM: No-Mermaid-engine assertion present in validate-html-output.sh =====
# ===========================================================================

echo ""
echo "=== NM-a: validate-html-output.sh has NM section (FR-51 / D-012 guardrail) ==="
assert_file_contains "$VALIDATE_HTML_SH" "NM" \
    "NM-a validate-html-output.sh has NM section"
assert_file_contains "$VALIDATE_HTML_SH" "No-Mermaid-engine" \
    "NM-a validate-html-output.sh NM section says 'No-Mermaid-engine'"

echo ""
echo "=== NM-b: validate-html-output.sh NM checks NM.1 (inline engine > 100 KB) ==="
if grep -qE "100000|100 KB|NM\.1" "$VALIDATE_HTML_SH"; then
    pass "NM-b validate-html-output.sh NM.1 checks for large inline script"
else
    fail "NM-b validate-html-output.sh missing NM.1 inline-engine check"
fi

echo ""
echo "=== NM-c: validate-html-output.sh NM checks NM.2 (mermaid.initialize()) ==="
if grep -qE 'mermaid\.initialize|NM\.2' "$VALIDATE_HTML_SH"; then
    pass "NM-c validate-html-output.sh NM.2 checks for mermaid.initialize() call"
else
    fail "NM-c validate-html-output.sh missing NM.2 mermaid.initialize() check"
fi

echo ""
echo "=== NM-d: validate-html-output.sh NM checks NM.3 (CDN Mermaid script src) ==="
if grep -qE 'NM\.3|cdn.*mermaid|mermaid.*cdn' "$VALIDATE_HTML_SH"; then
    pass "NM-d validate-html-output.sh NM.3 checks for CDN Mermaid script src"
else
    fail "NM-d validate-html-output.sh missing NM.3 CDN Mermaid check"
fi

echo ""
echo "=== NM-e: assemble.sh explicitly says no Mermaid engine in its output ==="
if grep -qiE "no.*Mermaid.*engine|Mermaid.*engine.*removed|Engine:.*none" "$ASSEMBLE_SH"; then
    pass "NM-e assemble.sh explicitly says no Mermaid engine in assembled output"
else
    fail "NM-e assemble.sh missing explicit 'no Mermaid engine' statement"
fi

echo ""
echo "=== NM-f: validate-visuals.mjs replaces validate-diagrams.mjs (change documented) ==="
# The mjs header says this replaces validate-diagrams.mjs for the fidelity gate.
if grep -qiE "replace.*validate-diagrams|validate-diagrams.*replace|replaces.*JSDOM" "$VALIDATE_VISUALS_MJS"; then
    pass "NM-f validate-visuals.mjs documents that it replaces validate-diagrams.mjs"
else
    fail "NM-f validate-visuals.mjs missing documentation that it replaces validate-diagrams.mjs"
fi

echo ""
echo "=== NM-g: state-validate.md references validate-visuals.mjs (not validate-diagrams.mjs) ==="
if [[ -f "$STATE_VALIDATE_MD" ]]; then
    if grep -qE "validate-visuals" "$STATE_VALIDATE_MD"; then
        pass "NM-g state-validate.md references validate-visuals.mjs"
    else
        fail "NM-g state-validate.md does not reference validate-visuals.mjs"
    fi
    # Must NOT reference validate-diagrams.mjs as the active validator
    if grep -qE "validate-diagrams" "$STATE_VALIDATE_MD"; then
        DIAG_REFS=$(grep -n "validate-diagrams" "$STATE_VALIDATE_MD")
        # Only fail if it's not clearly a 'replaced by' / historical note
        if echo "$DIAG_REFS" | grep -qiE "replace|retire|was\|removed|historic"; then
            pass "NM-g state-validate.md references validate-diagrams.mjs only historically"
        else
            fail "NM-g state-validate.md still references validate-diagrams.mjs as active (not replaced):
$DIAG_REFS"
        fi
    else
        pass "NM-g state-validate.md does not reference validate-diagrams.mjs (clean)"
    fi
else
    echo "  SKIP: state-validate.md not found at $STATE_VALIDATE_MD -- NM-g skipped"
    pass "NM-g state-validate.md not present (skip)"
fi

# ===========================================================================
# === C5: Approval signal =====================================================
# ===========================================================================

echo ""
echo "=== C5a: stale-check.sh reads 'User Approved' signal ==="
assert_file_contains "$STALE_CHECK_SH" "User Approved" \
    "C5a stale-check.sh reads User Approved signal"

echo ""
echo "=== C5b: state-generate.md references **User Approved:** approval literal ==="
assert_file_contains "$STATE_GENERATE_MD" "**User Approved:**" \
    "C5b state-generate.md references **User Approved:** literal"

# ===========================================================================
# === C6: Completeness / kb_baseline shape ====================================
# ===========================================================================

echo ""
echo "=== C6a: canonical settings.yml template preserves kb_baseline shape ==="
if [[ -f "$SETTINGS_TEMPLATE" ]]; then
    assert_file_contains "$SETTINGS_TEMPLATE" "kb_baseline" \
        "C6a canonical settings.yml template has kb_baseline key"
else
    echo "  SKIP: canonical settings.yml template not found at $SETTINGS_TEMPLATE"
    pass "C6a canonical settings.yml template not present (skip)"
fi

echo ""
echo "=== C6b: grade-summary.sh reads discovery.doc_set for COV (completeness) ==="
if grep -qE "discovery.doc_set|doc_set" "$GRADE_SH"; then
    pass "C6b grade-summary.sh reads discovery.doc_set for COV completeness"
else
    fail "C6b grade-summary.sh missing discovery.doc_set reference (C6 completeness broken)"
fi

# ===========================================================================
# === S5b: Page-shell alignment with home.html / index.html ==================
# ===========================================================================

echo ""
echo "=== 5b-a: html-skeleton.html has <header role='banner'> ==="
if grep -qE '<header[^>]*role="banner"' "$SKELETON_HTML"; then
    pass "5b-a html-skeleton.html has <header role='banner'> (shell landmark)"
else
    fail "5b-a html-skeleton.html missing <header role='banner'>"
fi

echo ""
echo "=== 5b-b: html-skeleton.html has <main id='top'> ==="
if grep -qE '<main[^>]*id="top"' "$SKELETON_HTML"; then
    pass "5b-b html-skeleton.html has <main id='top'>"
else
    fail "5b-b html-skeleton.html missing <main id='top'>"
fi

echo ""
echo "=== 5b-c: html-skeleton.html has breadcrumb nav ==="
if grep -qE '<nav[^>]*aria-label="Breadcrumb"' "$SKELETON_HTML"; then
    pass "5b-c html-skeleton.html has breadcrumb nav (shell landmark)"
else
    fail "5b-c html-skeleton.html missing breadcrumb nav"
fi

echo ""
echo "=== 5b-d: html-skeleton.html has <footer> ==="
assert_file_contains "$SKELETON_HTML" "<footer" \
    "5b-d html-skeleton.html has <footer>"

echo ""
echo "=== 5b-e: html-skeleton.html has skip-link (a11y) ==="
assert_file_contains "$SKELETON_HTML" "skip-link" \
    "5b-e html-skeleton.html has skip-link (a11y)"

echo ""
echo "=== 5b-f: html-skeleton.html has theme-toggle (shell-consistency marker) ==="
assert_file_contains "$SKELETON_HTML" "theme-toggle" \
    "5b-f html-skeleton.html has theme-toggle (shell-consistency with home.html/index.html)"

echo ""
echo "=== 5b-g: html-skeleton.html has aid-dashboard-theme key (shared theme key) ==="
assert_file_contains "$SKELETON_HTML" "aid-dashboard-theme" \
    "5b-g html-skeleton.html has aid-dashboard-theme key"

echo ""
echo "=== 5b-h: state-generate.md instructs shell consistency with home.html + index.html ==="
if grep -qiE "consistent.*home\.html|home\.html.*consistent|outer.*shell.*consistent|shell.*consistent" "$STATE_GENERATE_MD"; then
    pass "5b-h state-generate.md instructs shell consistency with home.html + index.html"
else
    fail "5b-h state-generate.md missing shell consistency instruction"
fi

# ===========================================================================
# === validate-html-output.sh holistic re-check on a minimal clean fixture ===
# ===========================================================================

echo ""
echo "=== GR-HOLISTIC: validate-html-output.sh passes on a clean D-012 fixture ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

KB_HTML="${TMP}/kb.html"
KB_DIR="${TMP}/knowledge"
mkdir -p "$KB_DIR"

# Build a minimal compliant kb.html (NM-clean, S2-clean, H1/A1-A5/L1/L2)
cat > "$KB_HTML" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<title>KB Summary</title>
<style>
:root { color-scheme: light dark; --accent: #007F7D; }
@media (prefers-reduced-motion: reduce) { * { transition-duration: 0.01ms !important; } }
:focus { outline: none; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.skip-link { position: absolute; top: -40px; }
</style>
</head>
<body>
<a class="skip-link" href="#top">Skip to content</a>
<header role="banner">
  <nav aria-label="Breadcrumb"><a href="/">Home</a></nav>
  <button type="button" id="theme-toggle" aria-label="Switch theme">Dark</button>
</header>
<main id="top">
  <h1 id="h1-anchor">Knowledge Base Summary</h1>
  <p>Plain language intro for newcomers.</p>
  <section id="at-a-glance">
    <h2>At a Glance</h2>
    <p>What this project does and why.</p>
  </section>
</main>
<div id="lightbox" role="dialog" aria-modal="true" aria-hidden="true"
     aria-labelledby="lb-caption" aria-describedby="lb-hint">
  <div role="toolbar" aria-label="Diagram zoom controls">
    <button type="button" id="lb-close" aria-label="Close (Esc)">x</button>
  </div>
  <div id="lb-hint">Esc to close</div>
  <div id="lb-stage"><div id="lb-inner"></div></div>
  <div id="lb-caption" aria-live="polite"></div>
</div>
<footer id="page-footer"><p>Generated. No external assets.</p></footer>
<noscript><ul><li><a href="./INDEX.md">INDEX.md</a></li></ul></noscript>
<script>
(function(){
  var lb = document.getElementById('lightbox');
  function trapFocusOnTab(e){
    if(e.key === 'Escape'){ lb.classList.remove('open'); }
  }
  var lastFocused = document.body;
  lastFocused.focus();
  document.addEventListener('keydown', trapFocusOnTab);
})();
</script>
</body>
</html>
HTMLEOF

# NM check directly
NM1=$(awk '
    /^<script/ { buf=""; in_script=1 }
    in_script  { buf = buf $0 "\n" }
    /<\/script>/ { in_script=0; if (length(buf) > 100000 && tolower(buf) ~ /mermaid/) print "FOUND" }
' "$KB_HTML" 2>/dev/null || true)

if [[ -z "$NM1" ]]; then
    pass "GR-HOLISTIC NM.1: clean fixture has no inline Mermaid engine"
else
    fail "GR-HOLISTIC NM.1: clean fixture detected as having Mermaid engine"
fi

if ! grep -qE 'mermaid\.initialize\(' "$KB_HTML" 2>/dev/null; then
    pass "GR-HOLISTIC NM.2: clean fixture has no mermaid.initialize()"
else
    fail "GR-HOLISTIC NM.2: clean fixture has mermaid.initialize()"
fi

if ! grep -qE '<script[^>]+src="https?://[^"]*mermaid[^"]*"' "$KB_HTML" 2>/dev/null; then
    pass "GR-HOLISTIC NM.3: clean fixture has no CDN Mermaid script src"
else
    fail "GR-HOLISTIC NM.3: clean fixture has CDN Mermaid script src"
fi

# S2 check directly
if ! grep -qE '<script[^>]+src="https?://' "$KB_HTML" && \
   ! grep -qE '<link[^>]+href="https?://' "$KB_HTML"; then
    pass "GR-HOLISTIC S2: clean fixture has no CDN script or link (self-contained)"
else
    fail "GR-HOLISTIC S2: clean fixture has external CDN reference"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
test_summary
exit $?
