#!/usr/bin/env bash
# test-grade-summary.sh -- canonical tests for the feature-015 D-011 summarize redesign.
#
# Scope (task-069):
#   AC1  Change-1: doc-set/domain-driven sections -- one section per resolved doc;
#        no phantom repo-presentation.md; noscript list is derived (NOSCRIPT_DOC_LIST
#        placeholder in template, not hardcoded doc list).
#   AC2  Change-2: bespoke concept components present in component-css.css
#        (.gloss-* / .adr-* / .cap-*) and in bespoke-components.md template.
#        Generic fallback covers non-bespoke docs (auto-detect.md).
#   AC3  Change-3: grade-summary.sh has no C+/diagram-count cap;
#        a complete diagram-light kb.html is NOT capped (COV drives the grade).
#        A diagram-rich but coverage-poor HTML does NOT get floored.
#   AC4/5 Change-4/5: newcomer "At a Glance" framing (no software-metric lead);
#        shell landmarks (header/main/nav/footer) and shell-consistency markers
#        present in html-skeleton.html.
#   GR   Guardrails C1/C2/C3/C5/C6:
#        C1 output path .aid/knowledge/kb.html;
#        C2/C3 no CDN / no external script src / no sibling sub-resource fetches;
#        C5 "## Knowledge Summary Status" -> "**User Approved:** yes" literal;
#        C6 "## Completeness" + "kb_baseline:" shapes.
#
# Tests assert STATIC SOURCE PROPERTIES (canonical/ files) and COV-based grading
# logic (grade-summary.sh fixtures). They do NOT run the full /aid-summarize skill
# or require a Node runtime. The validate-visuals + contrast-check mjs paths are
# irrelevant to this suite's coverage (they are exercised by test-visual-fidelity.sh
# and test-contrast-check.sh respectively).
#
# Usage:
#   tests/canonical/test-grade-summary.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# Canonical source paths
GRADE_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/grade-summary.sh"
RUBRIC_MD="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/grading-rubric.md"
COMPONENT_CSS="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/component-css.css"
SKELETON_HTML="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/html-skeleton.html"
STATE_PROFILE_MD="${REPO_ROOT}/canonical/skills/aid-summarize/references/state-profile.md"
STATE_GENERATE_MD="${REPO_ROOT}/canonical/skills/aid-summarize/references/state-generate.md"
BESPOKE_MD="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/section-templates/bespoke-components.md"
AUTO_DETECT_MD="${REPO_ROOT}/canonical/aid/templates/knowledge-summary/section-templates/auto-detect.md"
STALE_CHECK_SH="${REPO_ROOT}/canonical/aid/scripts/summarize/stale-check.sh"

# Temp directory for fixture repos
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Helper: build a minimal settings.yml with a doc_set
# ---------------------------------------------------------------------------
make_settings() {
    local dir="$1"; shift
    mkdir -p "${dir}/.aid"
    cat > "${dir}/.aid/settings.yml" <<'SETTINGSEOF'
discovery:
  doc_set:
    - domain-glossary.md|aid-researcher|required
    - decisions.md|aid-researcher|required
    - capability-inventory.md|aid-researcher|required
    - architecture.md|aid-researcher|required
    - workflow-map.md|aid-researcher|required
SETTINGSEOF
}

# ---------------------------------------------------------------------------
# Helper: build a minimal STATE.md with Knowledge Summary Status
# ---------------------------------------------------------------------------
make_state() {
    local dir="$1"
    mkdir -p "${dir}/.aid/knowledge"
    cat > "${dir}/.aid/knowledge/STATE.md" <<'STATEEOF'
## Discovery Domain

- **Domain:** hybrid:methodology-tooling+software-cli

## Knowledge Summary Status

**User Approved:** no
**Last Run:** 2026-06-25

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-06-25 | A | /aid-discover | initial |

## Summarization History

| # | Date | Grade | Profile | Notes |
|---|------|-------|---------|-------|
STATEEOF
}

# ---------------------------------------------------------------------------
# Helper: create a minimal kb doc (at least 3 lines of content)
# ---------------------------------------------------------------------------
make_kb_doc() {
    local path="$1"; local title="$2"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<EOF
---
kb-category: primary
objective: ${title} objective
summary: ${title} summary
---

# ${title}

This document covers ${title}.
More content here.
And more here.
EOF
}

# ---------------------------------------------------------------------------
# Helper: build a minimal self-contained kb.html fixture with all
# required structural landmarks (passes H1 A1 A2 A3 A4 A5 L1 L2 S2 C1 C2).
# The COV score depends on doc references in the HTML body.
# ---------------------------------------------------------------------------
make_kb_html() {
    local path="$1"; shift
    local extra_body="${1:-}"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<HTMLEOF
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<title>Test KB Summary</title>
<style>
:root { color-scheme: light dark; }
:root, html[data-theme="light"] {
  --bg: #F7F9FC; --bg-elev: #FFFFFF; --bg-sunken: #EEF2F7;
  --text: #101828; --text-muted: #4B5565; --text-dim: #667085;
  --border: #E3E8EF; --border-strong: #CDD5DF;
  --primary: #0B1F3A; --primary-fg: #FFFFFF;
  --accent: #007F7D; --accent-fg: #FFFFFF;
}
html[data-theme="dark"] {
  --bg: #0B1220; --bg-elev: #111A2E; --bg-sunken: #081021;
  --text: #E5EAF2; --text-muted: #9AA5B8; --text-dim: #8A99B8;
  --border: #1E293B; --border-strong: #2B3A52;
  --primary: #0D2A52; --primary-fg: #E8F2FF;
  --accent: #2DD4D2; --accent-fg: #051514;
}
@media (prefers-reduced-motion: reduce) { * { transition-duration: 0.01ms !important; } }
:focus { outline: none; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.skip-link { position: absolute; top: -40px; }
</style>
</head>
<body>
<a class="skip-link" href="#top">Skip to content</a>
<header class="top-bar" role="banner">
  <span class="app-title">AID Dashboard</span>
  <nav class="breadcrumb" aria-label="Breadcrumb">
    <a href="/">Home</a>
    <span class="sep">&#x203A;</span>
    <span class="current">Knowledge Base</span>
  </nav>
  <div class="controls">
    <button type="button" id="theme-toggle" aria-label="Switch theme">Dark</button>
  </div>
</header>
<main id="top">
  <h1>Test Project Knowledge Base Summary</h1>
  <p>This is a test knowledge base summary for a newcomer.</p>
  <p>What this project is and what it does -- plain language for a newcomer.</p>
  <section id="glossary" class="sec">
    <header><h2>Key Vocabulary</h2></header>
    <div class="gloss-grid">
      <div class="gloss-card" id="gloss-test-term">
        <span class="gloss-term">Test Term</span>
        <p class="gloss-def">Definition of test term.</p>
      </div>
    </div>
    <p>Source: <a href="./domain-glossary.md">domain-glossary.md</a></p>
  </section>
  <section id="decisions" class="sec">
    <header><h2>Key Decisions</h2></header>
    <div class="adr-list">
      <div class="adr-card" id="adr-d1">
        <div class="adr-header">
          <span class="adr-id">D1</span>
          <span class="adr-title">Test Decision</span>
          <span class="adr-status accepted">Accepted</span>
        </div>
        <div class="adr-body">
          <div class="adr-row">
            <span class="adr-row-label">Decision</span>
            <span class="adr-row-content">We chose X over Y.</span>
          </div>
        </div>
      </div>
    </div>
    <p>Source: <a href="./decisions.md">decisions.md</a></p>
  </section>
  <section id="capabilities" class="sec">
    <header><h2>What This Can Do</h2></header>
    <div class="cap-grid">
      <div class="cap-card" id="cap-test-capability">
        <span class="cap-kicker">Capability</span>
        <span class="cap-name">Test Capability</span>
        <dl class="cap-dl">
          <dt>What</dt><dd>Does testing.</dd>
          <dt>When</dt><dd>On demand.</dd>
        </dl>
      </div>
    </div>
    <p>Source: <a href="./capability-inventory.md">capability-inventory.md</a></p>
  </section>
  <section id="architecture" class="sec">
    <header><h2>Architecture</h2></header>
    <p>Source: <a href="./architecture.md">architecture.md</a></p>
  </section>
  <section id="workflow-map" class="sec">
    <header><h2>Workflow Map</h2></header>
    <p>Source: <a href="./workflow-map.md">workflow-map.md</a></p>
  </section>
  ${extra_body}
</main>
<div class="lightbox" id="lightbox" role="dialog" aria-modal="true" aria-hidden="true"
     aria-labelledby="lb-caption" aria-describedby="lb-hint">
  <div class="lb-toolbar" role="toolbar" aria-label="Diagram zoom controls">
    <button type="button" id="lb-close" aria-label="Close (Esc)">x</button>
  </div>
  <div class="lb-hint" id="lb-hint">Esc to close</div>
  <div class="lb-stage" id="lb-stage"><div class="lb-inner" id="lb-inner"></div></div>
  <div class="lb-caption" id="lb-caption" aria-live="polite"></div>
</div>
<footer id="page-footer">
  <p>Generated from <code>.aid/knowledge/</code>. No external assets.</p>
</footer>
<noscript>
  <div class="noscript-fallback">
    <h2>JavaScript required</h2>
    <ul>
      <li><a href="./INDEX.md">INDEX.md</a></li>
      <li><a href="./domain-glossary.md">domain-glossary.md</a></li>
      <li><a href="./decisions.md">decisions.md</a></li>
      <li><a href="./capability-inventory.md">capability-inventory.md</a></li>
      <li><a href="./architecture.md">architecture.md</a></li>
      <li><a href="./workflow-map.md">workflow-map.md</a></li>
    </ul>
  </div>
</noscript>
<script>
/* lightbox.js inlined */
(function(){
  var lb = document.getElementById('lightbox');
  function trapFocusOnTab(e){
    if(e.key==='Tab'){}
    if(e.key==='Escape'){lb.classList.remove('open');}
  }
  var lastFocused=document.body;
  lastFocused.focus();
  document.addEventListener('keydown',trapFocusOnTab);
  document.querySelectorAll('[data-lightbox]').forEach(function(el){
    el.addEventListener('click',function(){lb.classList.add('open');});
  });
})();
</script>
</body>
</html>
HTMLEOF
}

# ===========================================================================
# === AC1 -- Change-1: doc-set/domain-driven; no phantom repo-presentation.md;
#     derived noscript (NOSCRIPT_DOC_LIST placeholder, not hardcoded) =========
# ===========================================================================

echo ""
echo "=== AC1a: state-profile.md says NOT to auto-detect a project TYPE ==="
# The correct content is a DO-NOT instruction: "Do NOT auto-detect a project TYPE".
# We assert the prohibition is present (the positive assertion: feature-015 Change 1 was applied).
if grep -qiE "do not auto.detect|NOT auto.detect|auto-detect.*retired|profile.as.project.type.*retired|profile-as-project-type.*retired" "$STATE_PROFILE_MD" 2>/dev/null; then
    pass "AC1a: state-profile.md explicitly prohibits project-type auto-detection (retired)"
else
    fail "AC1a: state-profile.md missing explicit prohibition on project-type auto-detection"
fi

echo ""
echo "=== AC1b: state-profile.md reads doc-set from .aid/settings.yml ==="
if grep -qF "discovery.doc_set" "$STATE_PROFILE_MD"; then
    pass "AC1b: state-profile.md references discovery.doc_set (settings.yml input)"
else
    fail "AC1b: state-profile.md missing reference to discovery.doc_set"
fi

echo ""
echo "=== AC1c: state-profile.md reads domain from .aid/knowledge/STATE.md ==="
if grep -qE "## Discovery Domain|Discovery Domain" "$STATE_PROFILE_MD"; then
    pass "AC1c: state-profile.md references Discovery Domain from knowledge/STATE.md"
else
    fail "AC1c: state-profile.md missing Discovery Domain reference"
fi

echo ""
echo "=== AC1d: NO phantom repo-presentation.md in summarize canonical sources ==="
PHANTOM_HITS=$(grep -rn "repo-presentation.md" \
    "${REPO_ROOT}/canonical/skills/aid-summarize/" \
    "${REPO_ROOT}/canonical/aid/templates/knowledge-summary/" \
    2>/dev/null | grep -v "\.md:#\|^Binary" || true)
if [[ -z "$PHANTOM_HITS" ]]; then
    pass "AC1d: no phantom repo-presentation.md references in summarize canonical sources"
else
    fail "AC1d: phantom repo-presentation.md still referenced:
$PHANTOM_HITS"
fi

echo ""
echo "=== AC1e: html-skeleton.html uses NOSCRIPT_DOC_LIST placeholder (not hardcoded list) ==="
if grep -qF "{{NOSCRIPT_DOC_LIST}}" "$SKELETON_HTML"; then
    pass "AC1e: html-skeleton.html uses {{NOSCRIPT_DOC_LIST}} placeholder (list is derived)"
else
    fail "AC1e: html-skeleton.html missing {{NOSCRIPT_DOC_LIST}} placeholder"
fi

echo ""
echo "=== AC1f: html-skeleton.html has no hardcoded doc filenames in noscript block ==="
# Extract the noscript block and check it has no hardcoded knowledge/ doc filenames
# (only INDEX.md is expected, wrapped in the placeholder region)
NOSCRIPT_BLOCK=$(sed -n '/<noscript>/,/<\/noscript>/p' "$SKELETON_HTML" 2>/dev/null || true)
if echo "$NOSCRIPT_BLOCK" | grep -qE '\./[a-z][a-z0-9-]+\.md"' && \
   ! echo "$NOSCRIPT_BLOCK" | grep -qF "{{NOSCRIPT_DOC_LIST}}"; then
    fail "AC1f: html-skeleton.html noscript block has hardcoded doc links without NOSCRIPT_DOC_LIST placeholder"
else
    pass "AC1f: html-skeleton.html noscript block uses placeholder, not hardcoded doc list"
fi

echo ""
echo "=== AC1g: state-generate.md instructs deriving noscript from resolved doc-set ==="
if grep -qiE "noscript.*resolved|derived.*noscript|noscript.*doc.set|noscript.*derive" "$STATE_GENERATE_MD"; then
    pass "AC1g: state-generate.md instructs deriving noscript from resolved doc-set"
else
    fail "AC1g: state-generate.md missing noscript derivation instruction"
fi

echo ""
echo "=== AC1h: state-profile.md noscript section says 'resolved doc-set (not a hardcoded list)' ==="
if grep -qiE "not.*hardcoded|no.*hardcoded|hardcoded.*no" "$STATE_PROFILE_MD"; then
    pass "AC1h: state-profile.md explicitly says noscript list is not hardcoded"
else
    fail "AC1h: state-profile.md missing explicit anti-hardcode note for noscript"
fi

# ===========================================================================
# === AC2 -- Change-2: concept components in component-css.css and template ===
# ===========================================================================

echo ""
echo "=== AC2a: component-css.css has .gloss-grid class (Glossary component) ==="
if grep -qF ".gloss-grid" "$COMPONENT_CSS"; then
    pass "AC2a: component-css.css defines .gloss-grid"
else
    fail "AC2a: component-css.css missing .gloss-grid (Glossary component)"
fi

echo ""
echo "=== AC2b: component-css.css has .gloss-card class ==="
if grep -qF ".gloss-card" "$COMPONENT_CSS"; then
    pass "AC2b: component-css.css defines .gloss-card"
else
    fail "AC2b: component-css.css missing .gloss-card"
fi

echo ""
echo "=== AC2c: component-css.css has .adr-list class (Decision/ADR component) ==="
if grep -qF ".adr-list" "$COMPONENT_CSS"; then
    pass "AC2c: component-css.css defines .adr-list"
else
    fail "AC2c: component-css.css missing .adr-list (ADR component)"
fi

echo ""
echo "=== AC2d: component-css.css has .adr-card class ==="
if grep -qF ".adr-card" "$COMPONENT_CSS"; then
    pass "AC2d: component-css.css defines .adr-card"
else
    fail "AC2d: component-css.css missing .adr-card"
fi

echo ""
echo "=== AC2e: component-css.css has .cap-grid class (Capability component) ==="
if grep -qF ".cap-grid" "$COMPONENT_CSS"; then
    pass "AC2e: component-css.css defines .cap-grid"
else
    fail "AC2e: component-css.css missing .cap-grid (Capability component)"
fi

echo ""
echo "=== AC2f: component-css.css has .cap-card class ==="
if grep -qF ".cap-card" "$COMPONENT_CSS"; then
    pass "AC2f: component-css.css defines .cap-card"
else
    fail "AC2f: component-css.css missing .cap-card"
fi

echo ""
echo "=== AC2g: bespoke-components.md template has glossary section HTML template ==="
if grep -qE "gloss-grid|gloss-card" "$BESPOKE_MD"; then
    pass "AC2g: bespoke-components.md contains gloss-grid/gloss-card HTML template"
else
    fail "AC2g: bespoke-components.md missing glossary component HTML template"
fi

echo ""
echo "=== AC2h: bespoke-components.md template has ADR card section HTML template ==="
if grep -qE "adr-list|adr-card" "$BESPOKE_MD"; then
    pass "AC2h: bespoke-components.md contains adr-list/adr-card HTML template"
else
    fail "AC2h: bespoke-components.md missing ADR card HTML template"
fi

echo ""
echo "=== AC2i: bespoke-components.md template has capability entry section HTML template ==="
if grep -qE "cap-grid|cap-card" "$BESPOKE_MD"; then
    pass "AC2i: bespoke-components.md contains cap-grid/cap-card HTML template"
else
    fail "AC2i: bespoke-components.md missing capability entry HTML template"
fi

echo ""
echo "=== AC2j: bespoke-components.md says rendered as content, not as links ==="
if grep -qiE "rendered.*content.*not.*link|content.*not.*link|not.*link" "$BESPOKE_MD"; then
    pass "AC2j: bespoke-components.md explicitly says rendered as content (not linked)"
else
    fail "AC2j: bespoke-components.md missing 'rendered as content, not linked' assertion"
fi

echo ""
echo "=== AC2k: auto-detect.md covers generic fallback for non-bespoke docs ==="
if grep -qiE "generic.*fallback|fallback.*generic|tier.*primary|tier.*extension|tier.*meta" "$AUTO_DETECT_MD"; then
    pass "AC2k: auto-detect.md describes generic fallback for non-bespoke docs"
else
    fail "AC2k: auto-detect.md missing generic fallback description"
fi

echo ""
echo "=== AC2l: state-generate.md instructs rendering glossary as content (not linked) ==="
if grep -qiE "rendered.*not.*link|not.*link.*glossary|glossary.*content" "$STATE_GENERATE_MD"; then
    pass "AC2l: state-generate.md says glossary rendered as content, not linked"
else
    fail "AC2l: state-generate.md missing explicit 'rendered as content, not linked' for glossary"
fi

# ===========================================================================
# === AC3 -- Change-3: no C+/diagram-count cap in grade-summary.sh ============
# ===========================================================================

echo ""
echo "=== AC3a: grade-summary.sh has no C+ cap implementation (only removed-cap comment) ==="
# The script may reference the OLD cap in a historical comment saying it was REMOVED.
# What must NOT exist is any active logic that caps the grade at C+ based on diagram count.
# We check that no line assigns GRADE="C+" or forces a C+ ceiling conditioned on diagram count
# (the active-code check: assignment of GRADE or ceiling based on ACTUAL_MERMAID comparison).
# A comment saying the cap was removed is correct and expected.
CAP_CODE=$(grep -nE '(GRADE|CEILING|MACHINE_GRADE).*C\+|ACTUAL_MERMAID.*C\+|C\+.*ACTUAL_MERMAID' "$GRADE_SH" 2>/dev/null | grep -v '^#\|#.*cap' || true)
if [[ -z "$CAP_CODE" ]]; then
    pass "AC3a: grade-summary.sh has no active C+/diagram-count cap implementation"
else
    fail "AC3a: grade-summary.sh has active C+/diagram cap code:
$CAP_CODE"
fi

# AC3b removed: tests must not assert comment/header text (brittle). AC3a above
# covers the actual behavior (no active C+/diagram-count cap in grade-summary.sh).

echo ""
echo "=== AC3c: grading-rubric.md says diagram-count hard rule REMOVED ==="
if grep -qiE "diagram.count.*hard.*rule.*removed|removed.*diagram.*count.*hard|diagram.*count.*cap.*removed" "$RUBRIC_MD"; then
    pass "AC3c: grading-rubric.md contains 'Diagram-count hard rule: REMOVED'"
else
    fail "AC3c: grading-rubric.md missing 'Diagram-count hard rule: REMOVED' section"
fi

echo ""
echo "=== AC3d: grading-rubric.md says no diagram floor AND no diagram ceiling ==="
# The rubric has these as separate statements on separate lines.
if grep -qiE "no diagram floor" "$RUBRIC_MD" && grep -qiE "no diagram ceiling" "$RUBRIC_MD"; then
    pass "AC3d: grading-rubric.md says no diagram floor and no diagram ceiling"
else
    fail "AC3d: grading-rubric.md missing 'no diagram floor' or 'no diagram ceiling' statement"
fi

echo ""
echo "=== AC3e: grade-summary.sh COV check is the completeness gate (not diagram count) ==="
if grep -qE "COV.*coverage.*60|60.*COV|COV.*completeness" "$GRADE_SH"; then
    pass "AC3e: grade-summary.sh uses COV coverage < 60% as completeness gate"
else
    fail "AC3e: grade-summary.sh missing COV coverage gate"
fi

echo ""
echo "=== AC3f: grade-summary.sh grades complete diagram-light HTML as A+ (fixture test) ==="
# Build a fixture: full-coverage HTML (5/5 docs referenced) with NO mermaid blocks.
# Expected: COV=full (15 pts), D1/D2/S2 trivially passed, COV drives grade.
# We cannot easily pass all auto checks in unit test, so test just the COV contribution.
REPO_3F="${TMPDIR_BASE}/ac3f"
make_settings "$REPO_3F"
mkdir -p "${REPO_3F}/.aid/knowledge"
for doc in domain-glossary.md decisions.md capability-inventory.md architecture.md workflow-map.md; do
    make_kb_doc "${REPO_3F}/.aid/knowledge/${doc}" "${doc%.md}"
done
KB_HTML_3F="${REPO_3F}/.aid/knowledge/kb.html"
make_kb_html "$KB_HTML_3F"

# Run grade-summary.sh from the fixture dir, capture report
GRADE_OUT_3F=$(cd "$REPO_3F" && bash "$GRADE_SH" "${KB_HTML_3F}" 2>&1 || true)

# COV must be full (15/15) because all 5 docs are referenced in the HTML
if echo "$GRADE_OUT_3F" | grep -qE "COV.*\[PASS\].*full|COV.*full.*\[PASS\]"; then
    pass "AC3f: diagram-light HTML with full COV grades COV as 'full' (15/15)"
else
    fail "AC3f: expected COV=full in grade-summary output; got:
$(echo "$GRADE_OUT_3F" | grep -E "COV|Coverage|Machine" | head -10)"
fi

# Machine grade must NOT be F (the diagram-count cap would have forced F before)
MACHINE_3F=$(echo "$GRADE_OUT_3F" | grep -oE "Machine Grade: [A-F][+-]?" | head -1)
if [[ -n "$MACHINE_3F" ]] && ! echo "$MACHINE_3F" | grep -qE "Machine Grade: F$"; then
    pass "AC3f: Machine Grade for diagram-light + full COV is NOT F (no cap applied)"
else
    fail "AC3f: Machine Grade expected non-F for diagram-light full-COV HTML; got: $MACHINE_3F"
fi

echo ""
echo "=== AC3g: grade-summary.sh forces Machine Grade F when COV < 60% (coverage gate) ==="
REPO_3G="${TMPDIR_BASE}/ac3g"
make_settings "$REPO_3G"
mkdir -p "${REPO_3G}/.aid/knowledge"
for doc in domain-glossary.md decisions.md capability-inventory.md architecture.md workflow-map.md; do
    make_kb_doc "${REPO_3G}/.aid/knowledge/${doc}" "${doc%.md}"
done
# Build HTML that only references 1 of 5 docs (20% coverage -> below 60% -> F)
KB_HTML_3G="${REPO_3G}/.aid/knowledge/kb.html"
mkdir -p "$(dirname "$KB_HTML_3G")"
cat > "$KB_HTML_3G" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<title>Low Coverage Test</title>
<style>
:root { --accent: #007F7D; }
@media (prefers-reduced-motion: reduce) { * { transition-duration: 0.01ms !important; } }
:focus-visible { outline: 2px solid var(--accent); }
</style>
</head>
<body>
<a class="skip-link" href="#top">Skip</a>
<header role="banner"><nav aria-label="Breadcrumb"><a href="/">Home</a></nav></header>
<main id="top">
  <p>This summary only mentions domain-glossary content.</p>
  <p>See <a href="./domain-glossary.md">domain-glossary.md</a> for vocabulary.</p>
</main>
<div id="lightbox" role="dialog" aria-modal="true" aria-hidden="true" aria-labelledby="lb-caption" aria-describedby="lb-hint">
  <div role="toolbar" aria-label="Diagram zoom controls"><button aria-label="Close (Esc)">x</button></div>
  <div id="lb-hint">hint</div>
  <div id="lb-stage"><div id="lb-inner"></div></div>
  <div id="lb-caption" aria-live="polite"></div>
</div>
<footer><p>Footer</p></footer>
<noscript><ul><li><a href="./domain-glossary.md">domain-glossary.md</a></li></ul></noscript>
<script>(function(){function trapFocusOnTab(e){if(e.key==='Escape'){}};var lastFocused=document.body;lastFocused.focus();})();</script>
</body>
</html>
HTMLEOF

GRADE_OUT_3G=$(cd "$REPO_3G" && bash "$GRADE_SH" "${KB_HTML_3G}" 2>&1 || true)

# Machine Grade must be F (COV < 60% forces F)
if echo "$GRADE_OUT_3G" | grep -qE "Machine Grade: F"; then
    pass "AC3g: grade-summary.sh forces Machine Grade F when COV < 60% (1/5 docs = 20%)"
else
    fail "AC3g: expected Machine Grade F for 20% coverage; got:
$(echo "$GRADE_OUT_3G" | grep -E "COV|Coverage|Machine|coverage" | head -10)"
fi

# ===========================================================================
# === AC4/5 -- Change-4/5: newcomer framing + shell landmarks =================
# ===========================================================================

echo ""
echo "=== AC4a: state-profile.md 'At a Glance' does NOT lead with software metrics ==="
# The PROFILE step derives At a Glance; check the "At a Glance" section says no metric lead.
if grep -qiE "At a Glance.*lead.*what|what.*why.*not.*metric|does.*not.*lead.*software.metric|not.*lead.*metric" "$STATE_PROFILE_MD"; then
    pass "AC4a: state-profile.md At a Glance does not lead with software metrics"
else
    fail "AC4a: state-profile.md missing explicit statement that At a Glance avoids software-metric lead"
fi

echo ""
echo "=== AC4b: state-generate.md 'At a Glance' targets newcomer plain language ==="
if grep -qiE "newcomer.friendly.*plain.language|plain.language.*newcomer|newcomer.*what.*why" "$STATE_GENERATE_MD"; then
    pass "AC4b: state-generate.md At a Glance is newcomer-friendly plain language"
else
    fail "AC4b: state-generate.md missing newcomer plain-language framing for At a Glance"
fi

echo ""
echo "=== AC4c: state-generate.md says NOT to render audience: as role-badge ==="
if grep -qiE "not.*render.*audience.*role.badge|audience.*not.*role.badge|role.badge.*not" "$STATE_GENERATE_MD"; then
    pass "AC4c: state-generate.md says audience: is not rendered as role-badge"
else
    fail "AC4c: state-generate.md missing explicit instruction to not render audience as role-badge"
fi

echo ""
echo "=== AC5a: html-skeleton.html has <header role='banner'> (landmark) ==="
if grep -qE '<header[^>]*role="banner"' "$SKELETON_HTML"; then
    pass "AC5a: html-skeleton.html has <header role='banner'>"
else
    fail "AC5a: html-skeleton.html missing <header role='banner'>"
fi

echo ""
echo "=== AC5b: html-skeleton.html has <main id='top'> (landmark) ==="
if grep -qE '<main[^>]*id="top"' "$SKELETON_HTML"; then
    pass "AC5b: html-skeleton.html has <main id='top'>"
else
    fail "AC5b: html-skeleton.html missing <main id='top'>"
fi

echo ""
echo "=== AC5c: html-skeleton.html has breadcrumb nav landmark ==="
if grep -qE '<nav[^>]*aria-label="Breadcrumb"' "$SKELETON_HTML"; then
    pass "AC5c: html-skeleton.html has <nav aria-label='Breadcrumb'>"
else
    fail "AC5c: html-skeleton.html missing breadcrumb nav landmark"
fi

echo ""
echo "=== AC5d: html-skeleton.html has <footer> (landmark) ==="
if grep -qF "<footer" "$SKELETON_HTML"; then
    pass "AC5d: html-skeleton.html has <footer>"
else
    fail "AC5d: html-skeleton.html missing <footer>"
fi

echo ""
echo "=== AC5e: html-skeleton.html has theme-toggle button (shell-consistency marker) ==="
if grep -qF "theme-toggle" "$SKELETON_HTML"; then
    pass "AC5e: html-skeleton.html has theme-toggle (shell-consistency with home.html/index.html)"
else
    fail "AC5e: html-skeleton.html missing theme-toggle (shell-consistency marker)"
fi

echo ""
echo "=== AC5f: html-skeleton.html has skip-link (a11y, shell-consistency) ==="
if grep -qF "skip-link" "$SKELETON_HTML"; then
    pass "AC5f: html-skeleton.html has skip-link"
else
    fail "AC5f: html-skeleton.html missing skip-link"
fi

echo ""
echo "=== AC5g: html-skeleton.html has aid-dashboard-theme comment (shared theme key) ==="
if grep -qF "aid-dashboard-theme" "$SKELETON_HTML"; then
    pass "AC5g: html-skeleton.html uses aid-dashboard-theme key (consistent with home.html/index.html)"
else
    fail "AC5g: html-skeleton.html missing aid-dashboard-theme shared key"
fi

echo ""
echo "=== AC5h: state-generate.md instructs keeping outer shell consistent with home.html/index.html ==="
if grep -qiE "consistent.*home\.html.*index\.html|home\.html.*index\.html.*consistent|outer.*shell.*consistent" "$STATE_GENERATE_MD"; then
    pass "AC5h: state-generate.md instructs shell consistency with home.html + index.html"
else
    fail "AC5h: state-generate.md missing shell consistency instruction"
fi

# ===========================================================================
# === GUARDRAILS -- C1/C2/C3/C5/C6 ===========================================
# ===========================================================================

echo ""
echo "=== GR-C1: stale-check.sh hardcodes output path .aid/knowledge/kb.html ==="
if grep -qF ".aid/knowledge/kb.html" "$STALE_CHECK_SH"; then
    pass "GR-C1: stale-check.sh uses .aid/knowledge/kb.html as the output path"
else
    fail "GR-C1: stale-check.sh does not reference .aid/knowledge/kb.html"
fi

echo ""
echo "=== GR-C1b: state-generate.md assemble step targets .aid/knowledge/kb.html ==="
if grep -qF ".aid/knowledge/kb.html" "$STATE_GENERATE_MD"; then
    pass "GR-C1b: state-generate.md targets .aid/knowledge/kb.html output path"
else
    fail "GR-C1b: state-generate.md missing .aid/knowledge/kb.html output path"
fi

echo ""
echo "=== GR-C2/C3: html-skeleton.html has no external CDN script src ==="
# Single self-contained file: no <script src="https://..."> or <link href="https://...">
# Allowed: inline <script> (no src), inline <style>
CDN_SCRIPTS=$(grep -nE '<script[^>]+src="https?://' "$SKELETON_HTML" 2>/dev/null || true)
if [[ -z "$CDN_SCRIPTS" ]]; then
    pass "GR-C2/C3a: html-skeleton.html has no external CDN <script src=>"
else
    fail "GR-C2/C3a: html-skeleton.html has CDN script references:
$CDN_SCRIPTS"
fi

CDN_LINKS=$(grep -nE '<link[^>]+href="https?://' "$SKELETON_HTML" 2>/dev/null || true)
if [[ -z "$CDN_LINKS" ]]; then
    pass "GR-C2/C3b: html-skeleton.html has no external CDN <link href=>"
else
    fail "GR-C2/C3b: html-skeleton.html has CDN link references:
$CDN_LINKS"
fi

echo ""
echo "=== GR-C2/C3c: state-generate.md says assembled kb.html is single self-contained file ==="
if grep -qiE "single.*self.contained.*file|single.file.*self.contained|no.*CDN.*no.*split|no.*split.*no.*CDN" "$STATE_GENERATE_MD"; then
    pass "GR-C2/C3c: state-generate.md says kb.html is single self-contained file"
else
    fail "GR-C2/C3c: state-generate.md missing single self-contained file assertion"
fi

echo ""
echo "=== GR-C5: C5 approval signal literal in state-generate.md ==="
# C5: ## Knowledge Summary Status -> **User Approved:** yes (YYYY-MM-DD)
if grep -qF "**User Approved:**" "$STATE_GENERATE_MD"; then
    pass "GR-C5a: state-generate.md references **User Approved:** literal"
else
    fail "GR-C5a: state-generate.md missing **User Approved:** approval signal literal"
fi

echo ""
echo "=== GR-C5b: C5 approval signal literal in stale-check.sh ==="
if grep -qF "User Approved" "$STALE_CHECK_SH"; then
    pass "GR-C5b: stale-check.sh reads **User Approved:** signal"
else
    fail "GR-C5b: stale-check.sh missing User Approved signal read"
fi

echo ""
echo "=== GR-C5c: test that STATE.md with 'User Approved: yes' is read by stale-check ==="
REPO_C5="${TMPDIR_BASE}/gc5"
mkdir -p "${REPO_C5}/.aid/knowledge"
echo "<html><body>test</body></html>" > "${REPO_C5}/.aid/knowledge/kb.html"
cat > "${REPO_C5}/.aid/knowledge/STATE.md" <<'STATEEOF'
## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-06-01 | A | /aid-discover | initial |

## Summarization History

| # | Date | Grade | Profile | Notes |
|---|------|-------|---------|-------|
| 1 | 2026-06-25 | A | doc-set | test |

## Knowledge Summary Status

**User Approved:** yes (2026-06-25)
STATEEOF
STALE_OUT=$(cd "$REPO_C5" && bash "$STALE_CHECK_SH" 2>/dev/null | tail -1)
if echo "$STALE_OUT" | grep -qE "CURRENT_APPROVED"; then
    pass "GR-C5c: stale-check returns CURRENT_APPROVED when STATE.md has 'User Approved: yes'"
else
    fail "GR-C5c: stale-check did not return CURRENT_APPROVED; got: $STALE_OUT"
fi

echo ""
echo "=== GR-C6a: grade-summary.sh reads kb_baseline from .aid/settings.yml ==="
# The COV check reads discovery.doc_set from settings.yml -- same file where kb_baseline lives.
# Guardrail C6 says the kb_baseline shape must be preserved.
# Test: settings.yml WITH kb_baseline: block is accepted (COV still reads doc_set correctly).
REPO_C6="${TMPDIR_BASE}/gc6"
make_settings "$REPO_C6"
# Add kb_baseline to settings.yml
cat >> "${REPO_C6}/.aid/settings.yml" <<'KBEOF'
kb_baseline:
  doc_count: 5
  last_review: 2026-06-25
KBEOF
mkdir -p "${REPO_C6}/.aid/knowledge"
for doc in domain-glossary.md decisions.md capability-inventory.md architecture.md workflow-map.md; do
    make_kb_doc "${REPO_C6}/.aid/knowledge/${doc}" "${doc%.md}"
done
KB_HTML_C6="${REPO_C6}/.aid/knowledge/kb.html"
make_kb_html "$KB_HTML_C6"
GRADE_OUT_C6=$(cd "$REPO_C6" && bash "$GRADE_SH" "$KB_HTML_C6" 2>&1 || true)
# COV must still work (kb_baseline presence must not break doc_set parsing)
if echo "$GRADE_OUT_C6" | grep -qE "COV.*\[PASS\]"; then
    pass "GR-C6a: grade-summary.sh COV works correctly when settings.yml also has kb_baseline block"
else
    fail "GR-C6a: grade-summary.sh COV broke when settings.yml had kb_baseline; output:
$(echo "$GRADE_OUT_C6" | grep -E "COV|Coverage|Error" | head -10)"
fi

echo ""
echo "=== GR-C6b: canonical settings template preserves knowledge: baseline shape ==="
# Guardrail C6: .aid/settings.yml completeness/baseline shape must be preserved (reader
# derives doc_count / outdated from it). The kb_baseline: block was superseded by the flat
# schema's knowledge: block (source/last_update/doc_set/term_exclusions); the settings
# template in canonical/ is the authoritative definition -- its presence + content confirms
# the (renamed) shape is not removed.
SETTINGS_TEMPLATE="${REPO_ROOT}/canonical/aid/templates/settings.yml"
if [[ -f "$SETTINGS_TEMPLATE" ]] && grep -qF "knowledge:" "$SETTINGS_TEMPLATE" && grep -qF "source:" "$SETTINGS_TEMPLATE"; then
    pass "GR-C6b: canonical settings.yml template preserves knowledge: baseline shape"
else
    fail "GR-C6b: canonical settings.yml template missing knowledge: baseline shape"
fi

# ===========================================================================
# === Summary ================================================================
# ===========================================================================
echo ""
test_summary
exit $?
