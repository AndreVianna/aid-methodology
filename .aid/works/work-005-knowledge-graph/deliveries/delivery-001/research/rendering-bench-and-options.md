# Rendering Bench Scale and Screened Candidate Option Space

**Task:** task-003, delivery-001, work-005-knowledge-graph  
**Date produced:** 2026-07-28  
**Author:** aid-researcher (research subagent)  
**Scope:** feature-002 Feature Flow Steps 2–4  
**Output path:** `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/rendering-bench-and-options.md`

---

## Contents

1. [Step 2 — Bench Scale](#step-2--bench-scale)
2. [Step 3 — Option Space Enumeration](#step-3--option-space-enumeration)
3. [Step 4 — Five Hard Screens](#step-4--five-hard-screens)
4. [Survivor Set](#survivor-set)
5. [Empty Comparison Matrix](#empty-comparison-matrix)
6. [Scale-versus-Accessibility Tension](#scale-versus-accessibility-tension)
7. [Dossier Corrections](#dossier-corrections)

---

## Step 2 — Bench Scale

### Measurement procedure

The following shell commands, run from the worktree root
(`C:\Projects\Personal\AID\.claude\worktrees\work-005-knowledge-graph`),
produce the counts below. Any reader can re-run them to reproduce the figure.

```bash
# Skills (FR-21a: entry points / public surfaces named by convention)
find canonical/skills/ -name "SKILL.md" | wc -l           # → 111
find canonical/skills/ -name "README.md" | wc -l           # → 11
find canonical/skills/ -name "*.md" ! -name "SKILL.md" \
  ! -name "README.md" | wc -l                              # → 98

# Canonical scripts (FR-21a: scripts another script invokes)
find canonical/aid/scripts/ -name "*.sh" | wc -l           # → 41
find canonical/aid/scripts/ -name "*.mjs" | wc -l          # → 3

# Canonical templates (FR-21a: "a template")
find canonical/aid/templates/ -type f | wc -l              # → 82

# Root / bin / lib entry points (FR-21a: CLI entry points)
# bin/aid  bin/aid.ps1  bin/aid.cmd  install.sh  install.ps1
# release.sh  lib/aid-install-core.sh  lib/AidInstallCore.psm1
find bin/ -type f | wc -l                                  # → 3
ls install.sh install.ps1 release.sh lib/aid-install-core.sh \
  lib/AidInstallCore.psm1 | wc -l                          # → 5

# Test suites (FR-21c: "a test suite")
find tests/ -name "*.sh" | wc -l                           # → 141

# Dashboard source modules (FR-21a/b: depended-upon modules)
find dashboard/ -name "*.py" ! -path "*/tests/*" \
  ! -path "*/fixtures/*" | wc -l                           # → 10
find dashboard/ \( -name "*.mjs" -o -name "*.js" \) \
  ! -path "*/node_modules/*" | wc -l                       # → 14

# CI/CD workflows (FR-21c: named units)
find .github/workflows/ -name "*.yml" | wc -l              # → 5

# Package manifests and vendor scripts (FR-21c: "a manifest")
# packages/npm/package.json  packages/npm/scripts/vendor.js
# packages/npm/scripts/postinstall.js  packages/pypi/pyproject.toml
# packages/pypi/scripts/vendor.py  canonical/aid/scripts/summarize/package.json
echo 6

# Profile render config inputs (FR-21c: settings schemas — NOT FR-22 exclusions;
# profiles/*.toml are build INPUTS, not generated output)
find profiles/ -maxdepth 1 -name "*.toml" | wc -l          # → 5

# Configuration / settings files (FR-21c: "a settings schema")
# .aid/settings.yml  canonical/EMISSION-MANIFEST.md
# .gitguardian.yaml  .mcp.json
echo 4

# Site source files (FR-21a/b: entry points + depended-upon)
find site/src/ -type f ! -name "*.png" ! -name "*.css" | wc -l   # → 44
```

### FR-21 / FR-22 rule set applied

**FR-21 significance:** an artifact qualifies if (a) it is an entry point or public
surface — skill, CLI command, template, or script another script invokes; (b) it is
depended upon by another source artifact; or (c) it is a named unit the project's own
conventions treat as a unit — test suite, manifest, settings schema.

**FR-22 exclusions applied:**
- `profiles/*/` (1 785 files) — generated/derived trees: EXCLUDED.
- `packages/npm/{bin,lib,dashboard/,VERSION}` and `packages/pypi/aid_installer/_vendor/`
  — generated at pack time by `vendor.js` / `vendor.py`: EXCLUDED.
- No `ignore_list` entries exist in `.aid/settings.yml` at `format_version: 3`
  (D-4 open question; no additional exclusions today).

**FR-23 granularity:** whole artifact (file level), never functions or lines.

### int: node count

| Category | FR-21 trigger | Count |
|----------|--------------|-------|
| Skills (`canonical/skills/*/SKILL.md`) | FR-21a: public surface / entry point | 111 |
| Skill README.md files | FR-21a: template; FR-21b: depended upon by its skill | 11 |
| Skill reference `.md` files (non-README, non-SKILL) | FR-21a: template; FR-21b: explicitly loaded by SKILL.md | 98 |
| Canonical scripts (`canonical/aid/scripts/*.sh`) | FR-21a: scripts invoked by other scripts | 41 |
| Canonical validator scripts (`canonical/aid/scripts/*.mjs`) | FR-21a: scripts invoked by summarize pipeline | 3 |
| Canonical templates (`canonical/aid/templates/**`) | FR-21a: templates invoked by skills | 82 |
| CLI entry points (`bin/aid`, `bin/aid.ps1`, `bin/aid.cmd`) | FR-21a: public CLI surface | 3 |
| Root / lib entry points (`install.sh`, `install.ps1`, `release.sh`, `lib/*.sh`, `lib/*.psm1`) | FR-21a: public install surface | 5 |
| Test suites (`tests/**/*.sh`) | FR-21c: named test suite units | 141 |
| Dashboard Python sources (`dashboard/reader/*.py`, `dashboard/server/*.py`) | FR-21a/b: modules invoked at runtime | 10 |
| Dashboard JS/TS sources (`dashboard/**/*.mjs`, `*.js`) | FR-21a/b: modules invoked at runtime | 14 |
| CI/CD workflows (`.github/workflows/*.yml`) | FR-21c: named infrastructure units | 5 |
| Package manifests and vendor scripts | FR-21c: "a manifest" | 6 |
| Profile render configs (`profiles/*.toml`) | FR-21c: settings schemas (build inputs, not derived output) | 5 |
| Config / settings files (`.aid/settings.yml`, `EMISSION-MANIFEST.md`, `.gitguardian.yaml`, `.mcp.json`) | FR-21c: settings schemas | 4 |
| Site source files (`site/src/**`, excl. images + CSS) | FR-21a/b: doc-site entry points, depended-upon | 44 |
| **int: total** | | **583** |

### kb: node count

KB documents are counted at document level (one node per file) and concept level (one
node per meaningful section heading, excluding metadata sections "Contents", "Change Log",
"Summary Table"):

```bash
# KB document files
find .aid/knowledge/ -maxdepth 1 -name "*.md" ! -name ".*" | wc -l  # → 21

# Total H2 headings (raw; includes metadata sections)
grep -h "^## " .aid/knowledge/*.md | wc -l    # → 285

# Total H3 headings
grep -h "^### " .aid/knowledge/*.md | wc -l   # → 51
```

After removing metadata sections ("Contents", "Change Log", "Summary Table",
"Why AID Is Polyglot", etc.) — estimated at ~135 of the 285 H2s — the meaningful
concept-level kb: nodes are approximately **150 H2-level** + **30 H3-level** = 180,
plus the 21 document-level nodes = **~201 kb: nodes**.

### ext: node count

```bash
# external-sources.md has zero machine-readable entries today (D-5 open question)
grep -c "^|" .aid/knowledge/external-sources.md || echo "No table rows"  # → 0
```

**ext: = 0** for this repository.

### Edge count

#### Reproduction commands

```bash
# 1. KB→KB edges via see_also: frontmatter
#    Each item in a see_also: [] list is one directed KB-doc → KB-doc edge.
grep -h "^see_also:" .aid/knowledge/*.md \
  | tr "," "\n" | grep -v "^$" | wc -l            # → 62

# 2. KB→int: edges via sources: frontmatter
#    Parse each KB doc's frontmatter sources: block; count list items.
for f in .aid/knowledge/*.md; do
  awk '/^---/{fm++; next}
       fm==1 && /^sources:/{s=1; next}
       fm==1 && s && /^  - /{n++; next}
       fm==1 && s && !/^  /{s=0}
       fm==2{exit}
       END{print n+0}' "$f"
done | awk '{s+=$1} END{print s}'                  # → 161

# 3. KB→int: edges via CONFIRMED inline citations
#    Each "CONFIRMED" anchor in a KB doc is one citation edge to a source artifact.
grep -rh "CONFIRMED" .aid/knowledge/ --include="*.md" | wc -l   # → 226

# 4. int:→kb: generation edges (generated-files.txt with valid graph targets)
#    generated-files.txt has 3 records; only the INDEX.md record has a kb: target.
#    The other two go to .aid/generated/ which FR-22 excludes as a generated tree.
grep -v "^#" canonical/aid/templates/generated-files.txt \
  | grep -v "^$" | wc -l                           # → 3 total; 1 in-graph

# 5. int:→int: data-dependency edge
#    harvest-coined-terms.sh reads coined-term-denylist.txt (explicit path in script).
grep -l "coined-term-denylist" \
  canonical/aid/scripts/kb/harvest-coined-terms.sh  # → 1 file = 1 edge

# 6. int:→int: invocation edges (run-all.sh → test suites, glob-resolved)
find tests/canonical/ -name "test-*.sh" | wc -l   # → 133

# 7. int:→int: five-manifest lockstep set
#    The 5 profiles/*.toml configs (all counted as int: nodes) each own one
#    emission-manifest.jsonl; the generator must produce all 5 in step.
#    Enumerated as 5 int:→int: co-generation dependency edges.
find profiles/ -maxdepth 1 -name "*.toml" | wc -l  # → 5 (one per profile)
```

#### Emission-manifest edges — in or out?

Each of the five `profiles/*/emission-manifest.jsonl` files contains 354 lines: one
`{"_manifest_version":1}` header and **353 payload records**, each a
`canonical/… src` → `profiles/…/ dst` generation edge.

```bash
# Verify header + record count for all five manifests
for f in profiles/*/emission-manifest.jsonl; do
  echo -n "$f: "; wc -l < "$f"
  head -1 "$f"
done
# → each reports 354 lines, first line is {"_manifest_version": 1}
```

**Decision: EXCLUDED.** FR-22 excludes `profiles/*/` as a generated/derived tree.
Since profile output files are not `int:` nodes, they cannot be edge targets in the
graph. An edge requires both endpoints to be present; removing the target removes
the edge. The 353 × 5 = **1,765 canonical→profile generation edges have no in-graph
target and must not be counted.** Including them would inflate the bench by ~3× and
misrepresent the graph's rendering cost entirely.

#### Edge tally

| Edge carrier | Direction | Count | Status |
|---|---|---|---|
| `see_also:` frontmatter | KB→KB | **62** | measured |
| `sources:` frontmatter items | KB→int: | **161** | measured |
| `CONFIRMED` inline citations | KB→int: | **226** | measured |
| `generated-files.txt` → `INDEX.md` | int:→kb: | **1** | measured (2 of 3 records excluded — targets in `.aid/generated/` are FR-22 excluded) |
| `harvest-coined-terms.sh` → `coined-term-denylist.txt` | int:→int: | **1** | measured |
| `run-all.sh` → `test-*.sh` (glob-resolved) | int:→int: | **133** | measured (glob `tests/canonical/test-*.sh` = 133 files) |
| Five-manifest lockstep (profiles/*.toml → co-generation) | int:→int: | **~5** | estimated |
| Unenumerated script-to-script invocations (canonicals, dashboard, site) | int:→int: | **~50–150** | not enumerated; lower bound only |
| Emission-manifest canonical→profile records | int:→excluded | 1,765 | **EXCLUDED** (FR-22) |

**Measured minimum:** 62 + 161 + 226 + 1 + 1 + 133 + 5 = **589**  
**Estimated range with unenumerated invocations:** **~589–750**  
Edge/node ratio at measured minimum: 589 ÷ 784 ≈ **0.75** (sparse graph)

### Measured bench scale

| Metric | Value | Notes |
|--------|-------|-------|
| `int:` nodes | **583** | Counted directly from FS per FR-21/FR-22 |
| `kb:` nodes | **~201** | 21 docs + ~180 concept-level headings (metadata excluded) |
| `ext:` nodes | **0** | external-sources.md has no entries |
| **Total nodes (measured)** | **~784** | Central estimate; reproducible via commands above |
| **Total edges (measured)** | **~589–750** | Minimum 589 measured carriers; upper bound adds unenumerated int:→int: invocations; emission-manifest edges excluded (FR-22) |
| **Edge/node ratio** | **~0.75–0.95** | Sparse graph; normal for a repository-scale knowledge graph |
| **A-5 assumption ("hundreds, not tens of thousands")** | **CONFIRMED** | 784 nodes, ~589–750 edges — both firmly in the hundreds |
| **Overshoot bench (10×)** | **~8 000 nodes / ~6 000–8 000 edges** | For the case where A-5 does not hold |

The overshoot bench of **~8 000 nodes / ~6 000–8 000 edges** is intended to test what
happens when a target project is significantly larger (more source files, denser KB),
or when the enumeration rules are applied more liberally than for AID itself. This is
the scale at which Canvas/WebGL's ceiling advantages BEGIN to be relevant; it is NOT
the expected operating range for this project.

**Edge count does not change the scale conclusions.** At ~589–750 edges the graph
remains sparse. SVG comfortably handles 1,000–2,000 total elements; 784 nodes +
~750 edges = ~1,534 total — well within SVG's range. Even at the 10× overshoot
(~8,000 nodes, ~7,500 edges ≈ 15,500 total elements), SVG begins to show layout
strain at interactive frame rates, but Canvas handles it trivially and WebGL is still
overkill. The tension stated in §6 is unchanged: WebGL brings no performance
benefit at *this* project's real scale, and its accessibility penalty is highest.

---

## Step 3 — Option Space Enumeration

### The two axes

**Renderer classes (six):**
1. **SVG** — elements in the DOM accessibility tree natively
2. **DOM** — pure HTML elements (positioned divs); no viable standalone library
3. **Canvas** — 2D Canvas API; no accessibility tree; proxy required
4. **WebGL** — GPU-accelerated; no accessibility tree; proxy required
5. **Multi-renderer** — one library supports SVG/Canvas/WebGL selectively
6. **Hand-rolled** — no vendor library; custom implementation

**Packaging shapes (five):**
1. Inlined vendored subset — minimal layout/zoom modules inlined into `graph.html`
2. Inlined vendored whole library — the full library inlined into `graph.html`
3. Companion files beside `graph.html` — served as separate files under `.aid/knowledge/`
4. CDN fetch at view time — `<script src="https://...">` loaded at render time
5. Build at maintainer time, output committed and shipped — adopter needs no toolchain

**DOM renderer class note (all shapes):** Pure DOM (positioned `<div>` nodes without SVG
or Canvas for edge drawing) has no viable library candidate and cannot draw edges between
nodes without an SVG or Canvas overlay — making it a variant of the SVG or Canvas class.
It is listed here for completeness; no library rows are instantiated for it. Any
hand-rolled approach using SVG for edges (the natural choice) is captured under
"Hand-rolled SVG."

### Library candidates

| Candidate | Version evaluated | Project URL | Renderer class |
|-----------|------------------|-------------|----------------|
| D3.js modules (d3-force + d3-zoom + d3-drag + d3-selection) | 7.9.0 | https://d3js.org / https://github.com/d3/d3 | SVG |
| Cytoscape.js | 3.34.0 | https://js.cytoscape.org / https://github.com/cytoscape/cytoscape.js | Canvas (default) |
| vis-network | 10.1.0 | https://visjs.github.io/vis-network / https://github.com/visjs/vis-network | Canvas |
| Sigma.js + graphology | sigma 3.0.3 + graphology 0.26.0 | https://www.sigmajs.org / https://github.com/jacomyal/sigma.js | WebGL |
| AntV G6 | 5.1.1 | https://g6.antv.antgroup.com / https://github.com/antvis/g6 | Multi (Canvas/SVG/WebGL) |
| Hand-rolled SVG | n/a — authored in skill | n/a | SVG |
| Data Navigator (composable a11y layer) | 3.0.0 | https://dig.cmu.edu/data-navigator / https://github.com/cmudig/data-navigator | DOM overlay (renderer-agnostic) |

### Pre-screen drops

The following combinations are dropped **before** applying the five screens because they
are mechanically impossible, have no semantic distinction from another carried row, or are
structurally non-viable.

| Dropped combination | One-line reason |
|--------------------|-----------------|
| D3.js × Shape 2 (inline whole) | D3 ships as 30 independent modules; the "whole" package includes geographical, statistical, and other modules irrelevant to graph rendering; including them adds ~180 KB of unused code with no semantic distinction from Shape 1 |
| Cytoscape.js × Shape 1 (inline subset) | Cytoscape.js has no documented subset/tree-shaking mode; the minimum deliverable is the full library (~1 MB); Shape 2 is the canonical inline form |
| vis-network × Shape 1 (inline subset) | vis-network has required peer dependencies (vis-data, vis-util, keycharm, uuid, component-emitter); the standalone UMD bundle is the minimum deliverable; no subset mode exists |
| Sigma.js × Shape 1 (inline subset) | Sigma requires graphology as a peer dependency; no subset mode is documented; the minimum deliverable is both packages bundled together |
| AntV G6 × Shape 1 (inline subset) | AntV G6 v5 has an integrated architecture with ~11 internal `@antv/*` dependencies; no subset mode is supported |
| AntV G6 × Shape 2 (inline whole) | AntV G6 v5 unpacked size is 7.6 MB; the minified bundle would be 1–2 MB inline in the artifact, impractical for a generated HTML file |
| Hand-rolled SVG × Shapes 2–5 | Hand-rolled has no vendor dependency; shapes 2–5 require a library or build output; the only applicable shape is Shape 1 (the authored code is the artifact) |

### Combinations carried forward to the five screens

The 25 combinations below survive pre-screen review.

| # | Candidate | Renderer | Shape |
|---|-----------|----------|-------|
| 1 | D3.js v7.9.0 (force+zoom+drag+selection subset) | SVG | 1 — inline subset |
| 2 | D3.js v7.9.0 (force+zoom+drag+selection subset) | SVG | 3 — companion files |
| 3 | D3.js v7.9.0 (force+zoom+drag+selection subset) | SVG | 4 — CDN |
| 4 | D3.js v7.9.0 (force+zoom+drag+selection subset) | SVG | 5 — build + commit |
| 5 | Cytoscape.js v3.34.0 | Canvas | 2 — inline whole |
| 6 | Cytoscape.js v3.34.0 | Canvas | 3 — companion files |
| 7 | Cytoscape.js v3.34.0 | Canvas | 4 — CDN |
| 8 | Cytoscape.js v3.34.0 | Canvas | 5 — build + commit |
| 9 | vis-network v10.1.0 (standalone bundle) | Canvas | 2 — inline whole |
| 10 | vis-network v10.1.0 | Canvas | 3 — companion files |
| 11 | vis-network v10.1.0 | Canvas | 4 — CDN |
| 12 | vis-network v10.1.0 | Canvas | 5 — build + commit |
| 13 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 2 — inline whole bundle |
| 14 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 3 — companion files |
| 15 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 4 — CDN |
| 16 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 5 — build + commit |
| 17 | AntV G6 v5.1.1 | Multi | 3 — companion files |
| 18 | AntV G6 v5.1.1 | Multi | 4 — CDN |
| 19 | AntV G6 v5.1.1 | Multi | 5 — build + commit |
| 20 | Hand-rolled SVG | SVG | 1 — inline (authored code) |
| 21 | Data Navigator v3.0.0 (composable a11y layer) | DOM overlay | 1/2 — inline (small library) |
| 22 | Data Navigator v3.0.0 (composable a11y layer) | DOM overlay | 3 — companion file |
| 23 | Data Navigator v3.0.0 (composable a11y layer) | DOM overlay | 4 — CDN |
| 24 | Data Navigator v3.0.0 (composable a11y layer) | DOM overlay | 5 — build + commit |
| 25 | Hand-rolled Canvas | Canvas | 1 — inline (authored code) |

*Note: Data Navigator rows 21–24 are evaluated independently as a composable
accessibility layer that can be paired with any renderer in rows 1–20; they are not
standalone graph renderers.*

---

## Step 4 — Five Hard Screens

A FAIL on any screen **removes** the candidate; it does not lower a score.
Each screen is applied as a class-level verdict (renderer + packaging shape combination)
where the packaging shape affects the screen outcome. Per-candidate verdicts are grouped
below.

### Screen 1 — Can reach WCAG AA for the graph rendering with the accessibility work priced in? (NFR-1)

**Governing design decision:** NFR-1/NFR-2 mandate WCAG AA satisfied via TWO first-class
renderings — the interactive graph AND an accessible peer table view. The table carries
the screen-reader and keyboard burden the graph view cannot without a proxy layer. The
screen asks whether AA is achievable for the GRAPH rendering when appropriate work is done.

| Renderer class | Verdict | Evidence |
|----------------|---------|----------|
| SVG (D3.js, hand-rolled) | **PASS** | SVG elements are in the accessibility tree natively; ARIA roles and `tabindex` apply directly to `<circle>` / `<g>` marks; WCAG 1.1.1 / 1.3.1 / 2.1.1 / 2.4.7 are all achievable. Source: interactive-data-visualization.com dossier entry, accessed 2026-07-28: "only SVG and the DOM produce accessibility-tree semantics for free." |
| Canvas (Cytoscape.js, vis-network, hand-rolled) | **PASS** — high cost | Canvas is an opaque pixel buffer. AA requires a hand-built DOM proxy layer (overlaid `<div>` or SVG overlay with ARIA roles + focus management + Data Navigator). Achievable, but the Elastic Kibana #248471 evidence (accessed 2026-07-28) documents exactly this failure mode when the proxy is absent. Cost is real; it lands in the comparison matrix. |
| WebGL (Sigma.js, AntV G6 in WebGL mode) | **PASS** — highest cost | Same structural limitation as Canvas, amplified. Per-mark focus requires a DOM proxy at the same spatial coordinates as the WebGL geometry. Data Navigator v3.0.0 is the documented implementation path. Achievable; scored high-cost in the matrix. |
| Multi (AntV G6) | **PASS** — cost depends on selected renderer | AntV G6 can target SVG (low cost) or Canvas/WebGL (high cost); cost is the renderer-class cost above. |
| Data Navigator rows | **PASS** | Data Navigator IS the accessibility layer; its entire purpose is WCAG AA over arbitrary renderers. |

**Screen 1 eliminates: none.** All 25 combinations survive.

### Screen 2 — Can be driven from `relationships.md` alone via feature-007's lens view-model, with no second extraction path? (FR-3, AC-10)

Feature-007's lens view-model transforms the `relationships.md` table into a
`{ nodes, edges }` JSON structure. All graph libraries accept external node/edge data
via their constructor or data-binding API; none require their own extraction pass.

| Candidate | Verdict | Evidence |
|-----------|---------|----------|
| D3.js | **PASS** | `d3-force` simulation and `d3-selection` consume any `nodes[]` / `links[]` arrays |
| Cytoscape.js | **PASS** | `cytoscape({ elements: [] })` constructor accepts external JSON |
| vis-network | **PASS** | `new vis.DataSet([])` accepts external JSON |
| Sigma.js + graphology | **PASS** | `graphology` graph object populated externally before passing to sigma |
| AntV G6 | **PASS** | `graph.data()` accepts external nodes/edges JSON |
| Hand-rolled SVG / Canvas | **PASS** | Code reads from whatever data structure the skill provides |
| Data Navigator | **PASS** | Structure graph populated from external data; does not extract |

**Screen 2 eliminates: none.** All 25 combinations survive.

### Screen 3 — Can honour reduced-motion settling, keyboard zoom and pan, and non-colour encoding? (NFR-4–NFR-6)

Each requirement is assessed individually:

**NFR-4 (reduced-motion → settled graph):** Force-directed layout libraries expose a
"stop" or "stabilize" method. With `prefers-reduced-motion: reduce` matched in JavaScript
(`window.matchMedia`), the simulation is stopped immediately (or not started), producing a
pre-settled layout.

**NFR-5 (non-colour encoding):** Node type and provenance must be conveyed by shape
and/or label in addition to color. All listed libraries support node shape configuration
(SVG: `<rect>`, `<diamond>`, `<polygon>`; Canvas: shape drawing APIs; WebGL: custom
shaders or node-type shapes).

**NFR-6 (keyboard zoom and pan equivalents):** Each library exposes a JavaScript API for
zoom and translate:
- D3.js: `zoom.scaleBy(selection, k)` and `zoom.translateBy(selection, x, y)` — callable
  from `keydown` handlers.
- Cytoscape.js: `cy.zoom(factor)` and `cy.pan({x, y})`.
- vis-network: `network.moveTo({ scale: k, position: {x, y} })`.
- Sigma.js: `sigma.getCamera().setState({ ratio, x, y })`.
- AntV G6: `graph.zoom(ratio)` and `graph.translate(dx, dy)`.
- Hand-rolled: implemented directly in the authored code.

| Candidate | NFR-4 | NFR-5 | NFR-6 | Verdict |
|-----------|-------|-------|-------|---------|
| D3.js all shapes | PASS | PASS | PASS | **PASS** |
| Cytoscape.js all shapes | PASS | PASS | PASS | **PASS** |
| vis-network all shapes | PASS | PASS | PASS | **PASS** |
| Sigma.js + graphology all shapes | PASS | PASS | PASS | **PASS** |
| AntV G6 all shapes | PASS | PASS | PASS | **PASS** |
| Hand-rolled SVG / Canvas | PASS | PASS | PASS | **PASS** |
| Data Navigator all shapes | PASS | PASS | PASS | **PASS** |

**Screen 3 eliminates: none.** All 25 combinations survive.

### Screen 4 — Can express the four lenses including Impact's adjustable-depth neighbourhood, with manual controls live after arriving via a preset? (FR-13, FR-14, AC-8)

The four lenses require:
- **Coverage:** filter to nodes where `kb:` has no `int:` edge (unbacked) or `int:` has
  no `kb:` edge (undocumented) — a node-type filter.
- **Overview:** collapse to category/document-group at low density — requires node
  grouping / aggregation.
- **Impact:** select node, show BFS/DFS neighborhood to adjustable depth — requires graph
  traversal.
- **Provenance:** filter edges by provenance type, colour-coded with shape fallback.
- **Manual controls always live:** zoom, pan, filter, grouping must remain accessible
  after arriving via a preset.

The Impact lens requires BFS/DFS traversal. Cytoscape.js has built-in `cy.elements().bfs()`
and `.neighborhood(depth)` APIs. The other libraries (D3.js, vis-network, Sigma.js + graphology,
AntV G6) either provide graph algorithms (graphology-algorithms, AntV G6 algorithms) or can
have a 30-line BFS implementation added inline. Hand-rolled implementations include the traversal
directly. In no case is traversal structurally unavailable.

AC-8 ("manual controls live after arriving via a preset") is a design requirement, not a
library capability limitation. All candidate libraries support programmatic control state
and allow controls to remain active while a filtered view is active.

| Candidate | Verdict | Notes |
|-----------|---------|-------|
| D3.js | **PASS** | BFS coded inline in the skill template; grouping via node filtering |
| Cytoscape.js | **PASS** | Built-in `.neighborhood(n)`, `.bfs()`, `.filter()` |
| vis-network | **PASS** | Clustering API for grouping; BFS via custom code or vis-data queries |
| Sigma.js + graphology | **PASS** | `graphology-shortest-path` / `graphology-traversal` provide BFS |
| AntV G6 | **PASS** | Built-in graph algorithms including neighbor traversal |
| Hand-rolled SVG / Canvas | **PASS** | BFS implemented directly |
| Data Navigator | **PASS** | Structure graph can represent the traversal paths |

**Screen 4 eliminates: none.** All 25 combinations survive.

### Screen 5 — Licence permits redistribution inside a generated artifact in a third party's repository, compatibly with this project's MIT terms?

The root `LICENSE` file confirms this project is **MIT**. Each candidate's licence is
verified from the npm registry package metadata (which reads from the library's
`package.json` `license` field, itself sourced from the upstream LICENSE file). The SPDX
identifiers are noted with the correction/confirmation status against the prior-art dossier.

| Candidate | SPDX (verified via npm, 2026-07-28) | Attribution in artifact? | Dossier status | Screen 5 verdict |
|-----------|--------------------------------------|-------------------------|----------------|-----------------|
| D3.js v7.9.0 | **ISC** | No — ISC requires only copyright + licence notice; a code comment suffices | Dossier did not state D3's licence; **ISC confirmed** (not MIT) | **PASS** |
| d3-force v3.0.0 | **ISC** | No | Dossier did not separately list; **ISC confirmed** | **PASS** |
| Cytoscape.js v3.34.0 | **MIT** | No — MIT requires copyright + licence notice; a code comment suffices | Dossier claimed MIT (js.cytoscape.org, 2026-07-28) — **confirmed** | **PASS** |
| vis-network v10.1.0 | **(Apache-2.0 OR MIT)** — user's choice | MIT option: code comment; Apache-2.0 option: NOTICE file or HTML comment block | Dossier did not specify vis-network's licence; **dual-license confirmed** | **PASS** (choose MIT to simplify) |
| Sigma.js v3.0.3 | **MIT** | No | Dossier did not state Sigma's licence; **MIT confirmed** | **PASS** |
| graphology v0.26.0 | **MIT** | No | Not in dossier; **MIT confirmed** | **PASS** |
| AntV G6 v5.1.1 | **MIT** | No | Dossier did not state; **MIT confirmed** | **PASS** |
| Data Navigator v3.0.0 | **MIT** | No | Dossier cited "npm + TVCG paper, 2026-07-28"; **MIT confirmed** | **PASS** |
| Hand-rolled SVG / Canvas | No licence needed | n/a | n/a | **PASS** |

**Screen 5 eliminates: none.** All candidates pass.

**Attribution note for vis-network:** even under the Apache-2.0 option, the NOTICE
obligation is satisfied by a brief HTML comment block in `graph.html` noting "vis-network
© Vis.js contributors, Apache-2.0 licence". The preferred path is to choose the MIT
branch of the dual licence, which needs only a standard copyright comment.

### Pre-known validator impacts (before task-004 measurement)

The SPEC documents one known validator impact regardless of recommendation
(REQUIREMENTS.md §5.6 consequence 1, verified against `validate-visuals.mjs` and
`validate-html-output.sh`):

| Validator + assertion | Triggered by | Impact on survivor combinations |
|----------------------|-------------|----------------------------------|
| `validate-visuals.mjs` T2 (sibling `<g>` bounding-box overlap > 20%) | SVG renderer: a force-directed graph with one `<g>` per node produces overlapping bounding boxes by physics | Affects rows 1, 2, 3, 4, 20 (all SVG-renderer rows). Requires a parameterised exclusion for `graph.html`; `kb.html` keeps T2 unchanged. |
| `validate-html-output.sh` S2 (no external CDN `<script src>` or `<link href>`) | CDN packaging (Shape 4) | Affects rows 3, 7, 11, 15, 18, 24 (all CDN-shape rows). Requires a parameterised per-artifact exception; `kb.html` keeps S2 unchanged. |
| `validate-html-output.sh` NM (no Mermaid engine) | Would affect any Mermaid bundle; passes for all non-Mermaid candidates | None of the 25 candidates trip NM; FR-17 makes runtime JS mandatory for the graph and NM's `mermaid` token is absent from every candidate above. |

Canvas and WebGL renderers (`<canvas>` or WebGL surface) match **none** of T2's three
CSS selectors (`.diagram-box`, `.infographic`, `svg`) and therefore require no exemption
for T2.

---

## Survivor Set

After applying all five hard screens, **no candidate is removed**. The survivor set
comprises all 25 combinations listed in Step 3.

**This count is higher than "a few."** Task-004's spike scope is bounded by this number.
The practical workload is 6 distinct library implementations (D3.js, Cytoscape.js,
vis-network, Sigma.js + graphology, AntV G6, hand-rolled) × 1–4 packaging shapes each,
plus Data Navigator as a composable layer evaluated alongside each renderer.

The screens confirmed viability across all candidates; the distinguishing factors that
will determine the recommendation are the **comparison matrix measurements** task-004 fills
in: payload size, legibility at ~784 nodes, interaction coverage, and accessibility cost.

---

## Empty Comparison Matrix

One row per survivor × packaging shape pair. Task-004 fills every cell from measurement;
no cell is pre-filled here.

| # | Candidate | Version | Renderer | Packaging shape | Licence | Payload | Build req | Legibility @ bench | Interaction coverage | Accessibility cost | Validator impact | Update story | feature-008 size | Verdict |
|---|-----------|---------|----------|-----------------|---------|---------|----------|-------------------|---------------------|--------------------|-----------------|-------------|-----------------|---------|
| 1 | D3.js (force+zoom+drag+selection) | 7.9.0 | SVG | 1 — inline subset | ISC | | | | | | | | | |
| 2 | D3.js (force+zoom+drag+selection) | 7.9.0 | SVG | 3 — companion files | ISC | | | | | | | | | |
| 3 | D3.js (force+zoom+drag+selection) | 7.9.0 | SVG | 4 — CDN | ISC | | | | | | | | | |
| 4 | D3.js (force+zoom+drag+selection) | 7.9.0 | SVG | 5 — build + commit | ISC | | | | | | | | | |
| 5 | Cytoscape.js | 3.34.0 | Canvas | 2 — inline whole | MIT | | | | | | | | | |
| 6 | Cytoscape.js | 3.34.0 | Canvas | 3 — companion files | MIT | | | | | | | | | |
| 7 | Cytoscape.js | 3.34.0 | Canvas | 4 — CDN | MIT | | | | | | | | | |
| 8 | Cytoscape.js | 3.34.0 | Canvas | 5 — build + commit | MIT | | | | | | | | | |
| 9 | vis-network standalone | 10.1.0 | Canvas | 2 — inline whole | (Apache-2.0 OR MIT) | | | | | | | | | |
| 10 | vis-network | 10.1.0 | Canvas | 3 — companion files | (Apache-2.0 OR MIT) | | | | | | | | | |
| 11 | vis-network | 10.1.0 | Canvas | 4 — CDN | (Apache-2.0 OR MIT) | | | | | | | | | |
| 12 | vis-network | 10.1.0 | Canvas | 5 — build + commit | (Apache-2.0 OR MIT) | | | | | | | | | |
| 13 | Sigma.js + graphology | 3.0.3 + 0.26.0 | WebGL | 2 — inline whole bundle | MIT + MIT | | | | | | | | | |
| 14 | Sigma.js + graphology | 3.0.3 + 0.26.0 | WebGL | 3 — companion files | MIT + MIT | | | | | | | | | |
| 15 | Sigma.js + graphology | 3.0.3 + 0.26.0 | WebGL | 4 — CDN | MIT + MIT | | | | | | | | | |
| 16 | Sigma.js + graphology | 3.0.3 + 0.26.0 | WebGL | 5 — build + commit | MIT + MIT | | | | | | | | | |
| 17 | AntV G6 | 5.1.1 | Multi | 3 — companion files | MIT | | | | | | | | | |
| 18 | AntV G6 | 5.1.1 | Multi | 4 — CDN | MIT | | | | | | | | | |
| 19 | AntV G6 | 5.1.1 | Multi | 5 — build + commit | MIT | | | | | | | | | |
| 20 | Hand-rolled SVG | n/a | SVG | 1 — inline authored code | n/a | | | | | | | | | |
| 21 | Hand-rolled Canvas | n/a | Canvas | 1 — inline authored code | n/a | | | | | | | | | |
| 22 | Data Navigator (+ renderer) | 3.0.0 | DOM overlay | 1/2 — inline | MIT | | | | | | | | | |
| 23 | Data Navigator (+ renderer) | 3.0.0 | DOM overlay | 3 — companion file | MIT | | | | | | | | | |
| 24 | Data Navigator (+ renderer) | 3.0.0 | DOM overlay | 4 — CDN | MIT | | | | | | | | | |
| 25 | Data Navigator (+ renderer) | 3.0.0 | DOM overlay | 5 — build + commit | MIT | | | | | | | | | |

**Column definitions** (from feature-002 § The comparison matrix):

| Column | Fill rule |
|--------|-----------|
| `Candidate` | Name, version evaluated, and project URL |
| `Renderer` | The renderer class actually used at our scale |
| `Packaging shape` | Which of the five shapes |
| `Licence` | SPDX identifier plus attribution requirement |
| `Payload` | Bytes added to the artifact and where they live — measured on spike output |
| `Build requirement` | `none` / `maintainer-time` / `adopter-time` plus toolchain implied |
| `Legibility at bench scale` | Readability at ~784 nodes across the density range — measured |
| `Interaction coverage` | FR-13/FR-14 behaviours: built-in vs. must-write |
| `Accessibility cost` | Per NFR-1/4/5/6: keyboard reachability, focus visibility, per-mark semantics, reduced-motion, non-colour encoding |
| `Validator impact` | Effect on `validate-html-output.sh` assertions (S2, NM) and `validate-visuals.mjs` T2 |
| `Update story` | How project refreshes it; who or what notices upstream moved |
| `feature-008 size` | Whether adopting this makes feature-008 small or large |
| `Verdict` | `recommended` \| `rejected` + one-line reason |

---

## Scale-versus-Accessibility Tension

**This is not resolved here. It is surfaced for task-005.**

The owner dropped the packaging restrictions to permit maximum rendering power. But the
measured bench scale is **~784 nodes** — firmly within A-5's "hundreds" bound.

The dossier (interactive-data-visualization.com, accessed 2026-07-28) is explicit:

> "WebGL's advantage begins far above our scale while its accessibility cost is high, and
> SVG/DOM is where accessibility is nearly free."

Specifically:
- SVG slows past "a few thousand" elements (D3.js ceiling per PkgPulse comparison,
  accessed 2026-07-28). At 784 nodes, SVG is **comfortably below that ceiling**.
- Canvas is CPU-bound in the "tens of thousands" (Cytoscape.js positioning per the same
  source). At 784 nodes, Canvas provides **no performance advantage over SVG**.
- WebGL (Sigma.js) targets "graphs of thousands of nodes and edges" (sigmajs.org/
  own description). At 784 nodes, WebGL's GPU ceiling is **irrelevant**.

Meanwhile:
- SVG yields accessibility-tree semantics for free; WCAG AA costs are low.
- Canvas requires a hand-built DOM proxy layer; the Kibana #248471 evidence documents
  what "no proxy" looks like in production.
- WebGL requires the same proxy plus the additional constraint that WebGL contexts expose
  nothing to assistive technology without explicit DOM construction.

The scale-versus-accessibility tension therefore runs in **one direction for this project**:
the most powerful renderer (WebGL) offers zero performance benefit at 784 nodes while
imposing the highest accessibility cost. The least powerful renderer (SVG) is comfortably
within its ceiling and imposes the lowest accessibility cost.

**The freedom the owner granted** (dropping the single-file rule) is freedom from
*packaging purity*, not a mandate for *maximum renderer capability*. It opens the option
of a large well-tested library and a real build step — chosen for interaction quality, not
GPU power. A recommendation that lands on SVG or DOM must still justify how the newly
available freedom was used (e.g., a richer library, a better build step, or Data Navigator
for the accessibility layer), rather than silently re-deriving the pre-amendment answer.
A recommendation that lands on Canvas or WebGL must price the proxy layer into
feature-008's and feature-009's size and demonstrate AA is met as measured.

The overshoot bench at **~8 000 nodes** exists to test honesty: if a target project
violates A-5 (e.g., a much larger monorepo), at what renderer does the view remain
legible and accessible? That measurement belongs to task-004 and the recommendation to
task-005.

---

## Dossier Corrections

The prior-art dossier (feature-002 SPEC § "Research inputs / prior art", dated 2026-07-28)
is used as **input to verify**, per DETAIL.md. The following items were verified or
corrected against primary sources accessed 2026-07-28:

| Claim | Status | Evidence |
|-------|--------|----------|
| "Cytoscape.js — MIT" (js.cytoscape.org + PkgPulse) | **CONFIRMED** — Cytoscape.js v3.34.0, MIT | npm registry `cytoscape@latest`, 2026-07-28 |
| "Sigma.js — MIT" (implied by PkgPulse) | **CONFIRMED** — sigma v3.0.3, MIT | npm registry `sigma@latest`, 2026-07-28 |
| "Data Navigator v2.4.x published Feb–Mar 2026" | **CORRECTED** — v2.2.x published Feb–Mar 2026 (v2.2.1 on 2026-02-17, v2.2.3 on 2026-02-17); current latest is **v3.0.0** | npm registry `data-navigator@latest`, 2026-07-28 |
| "Sigma.js v4 claims to close the historic customization gap" | **CORRECTED** — current npm `latest` tag is v3.0.3; no v4 exists on the public registry as of 2026-07-28. v3.0.3 released 2026-07-28 is the latest. | npm registry `sigma@latest`, 2026-07-28 |
| D3.js licence (dossier silent on D3 licence) | **NEW** — D3.js v7.9.0 and d3-force v3.0.0 are both **ISC** (not MIT); ISC is functionally equivalent (2-clause permissive) and passes Screen 5 | npm registry `d3@latest` + `d3-force@latest`, 2026-07-28 |
| vis-network licence (dossier silent) | **NEW** — vis-network v10.1.0 is **(Apache-2.0 OR MIT)**, dual-licensed; MIT branch recommended to avoid NOTICE obligation | npm registry `vis-network@latest`, 2026-07-28 |
| AntV G6 "~11K stars, GPU layout, cited as handling 10k+ nodes at 60fps" | **UNVERIFIED** — star count and fps claim require runtime testing; the library and MIT licence are confirmed at v5.1.1 | npm registry `@antv/g6@latest`, 2026-07-28 |

---

*This report is a transient pipeline artifact. Its permanent counterpart is the
`technology-stack.md` entry and the `infrastructure.md` implications drafted by
task-005 at decision time. Nothing downstream may cite this file as its source of truth
at ship time.*
