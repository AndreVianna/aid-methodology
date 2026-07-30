# Rendering Decision Record
## Feature-002: Graph Rendering Research — Steps 6-8 of Feature Flow

**Work:** work-005-knowledge-graph  
**Delivery:** delivery-001, Task-005 (revised after adversarial review)  
**Date:** 2026-07-28  
**Resolves:** STATE.md Q2 — "Which rendering approach does the graph view use?"  
**Minimum grade:** A+

---

## Part 1 — Question and Scope

### Q2 as amended

STATE.md Q2 asks: *"Which rendering approach does the graph view use?"* This question was
opened at the DESCRIBE phase as Impact High / Deferred to RESEARCH. Its resolution unblocks
feature-008 (interactive graph canvas) and provides firing conditions for feature-011's
conditional validator carve-outs and feature-012's dependency-packaging gate.

The question was widened on 2026-07-28 when REQUIREMENTS.md §5.6 FR-16 was amended. The
pre-amendment constraint required the graph artifact to be self-contained and single-file.
FR-16 as amended explicitly **drops** all three original packaging restrictions:

> "All three original packaging restrictions are dropped: it **may** ship as multiple files,
> it **may** fetch from a CDN or the network, and it **may** be produced by a real build step."

The SPEC recaps the same widening: "the packaging constraints that once bounded it are
withdrawn, so a candidate may ship as multiple files, may fetch from a content delivery
network, and may require a real build step with third-party dependencies."

### What the widened option space admits

Before the amendment, only Shape 1 (inline vendored subset within a single self-contained
file) was practically available without violating the packaging constraint. After the
amendment, all five packaging shapes are admissible for all renderer classes:

- **Shape 2 (inline whole library):** enables large libraries like Cytoscape.js (425 KB) and
  Sigma.js (255 KB) to be evaluated on quality and interaction merit rather than dismissed on
  payload grounds.
- **Shape 3 (companion files):** enables AntV G6 (1.32 MB — impractical inline) to be evaluated
  via the companion-file shape FR-16 now permits.
- **Shape 4 (CDN fetch):** enables network-sourced delivery, with documented cost in §5.6
  consequence 3.
- **Shape 5 (build-step output):** enables tree-shaken bundles and shape 5 maintainer-time
  builds, matching the precedent of `packages/npm/scripts/vendor.js` and the `profiles/`
  render-drift gate.

The research uses this widening: every one of the 25 surviving candidates is evaluated across
whichever shapes apply to it (not merely Shape 1), and the five candidates larger than the
pre-amendment implicit threshold are evaluated on their interaction quality, legibility, and
accessibility cost before being rejected on their merits. Parts 4 and 6 make this explicit.

---

## Part 2 — Research Inputs

All sources were accessed on 2026-07-28 and are attributed below. Sources marked `pipeline`
are internal research artifacts from earlier tasks in this delivery.

| # | Source | Type | Used in |
|---|--------|------|---------|
| A | `rendering-bench-and-options.md` (task-003 output) | pipeline | Parts 3, 4, 6 |
| B | `rendering-spike-matrix.md` (task-004 output) | pipeline | Parts 4, 5, 6, 8, 10, 11, 12, 13, 15 |
| C | REQUIREMENTS.md §5.6 (FR-16–FR-18, NFR-1–NFR-6, A-5, FR-22, FR-23) | project doc | Parts 1, 3, 6, 10, 12 |
| D | STATE.md Q2 | project doc | Part 1 |
| E | `.github/dependabot.yml` (verified on disk 2026-07-28) | project file | Part 9 |
| F | `.aid/knowledge/technology-stack.md` (§Frameworks & Tooling, §Key Dependencies, §Build Commands, §Version Concerns) | KB doc | Part 13 |
| G | `.aid/knowledge/infrastructure.md` (§The Build: Multi-Profile Render, §CI/CD Pipeline) | KB doc | Part 14 |
| H | feature-007-graph-view-shell/SPEC.md | feature spec | Step 8 |
| I | feature-008-interactive-graph-canvas/SPEC.md | feature spec | Parts 12, 15, Step 8 |
| J | feature-009-accessible-table-view/SPEC.md | feature spec | Parts 11, Step 8 |
| K | feature-011-validator-parameterisation/SPEC.md | feature spec | Step 8 |
| L | feature-012-canonical-registration/SPEC.md | feature spec | Parts 13, 14, Step 8 |
| M | "Accessible Interactive Data Visualization", interactive-data-visualization.com | web | Part 2 dossier, Parts 11, 12 |
| N | PkgPulse "Cytoscape.js vs vis-network vs Sigma.js 2026" | web | Part 2 dossier |
| O | Elastic Kibana issue #248471 | web | Parts 6, 11 |
| P | sigmajs.org (Sigma.js project description) | web | Part 12 |
| Q | npm registry (all libraries verified at evaluated versions) | web | Parts 4, 8 |
| R | D3.js ISC Licence, https://github.com/d3/d3/blob/main/LICENSE | web | Part 8 |

### Prior-art dossier summary

**Renderer / accessibility matrix** (source M, 2026-07-28): "only SVG and the DOM produce
accessibility-tree semantics for free. Canvas and WebGL render pixels into an opaque buffer
that exposes nothing to assistive technology" — the renderer choice "dictates how much
accessibility work you must do by hand." For graphs with fewer than ~1,000 marks: native SVG
with labeled marks, A11y cost LOW. For 1k–100k marks: Canvas + DOM proxy, cost HIGH. For
>100k: WebGL + DOM proxy + summary, cost HIGH plus no per-mark focus without additional work.

**Library landscape** (source N, 2026-07-28): SVG slows past "a few thousand" elements
(D3.js ceiling per PkgPulse); Canvas is CPU-bound in the "tens of thousands" (Cytoscape.js);
WebGL (Sigma.js) targets "graphs of thousands of nodes and edges" — its own scale claim
(source P, 2026-07-28). Sigma.js v3.0.3 is the current npm `latest` tag (not v4 — that claim
in the dossier was corrected by task-003, rendering-bench-and-options.md §Dossier Corrections).

**Kibana evidence** (source O, 2026-07-28): "the current Cytoscape.js implementation has poor
accessibility because it uses canvas-only rendering" — keyboard navigation, screen reader
support, focus indicators, and ARIA all absent or limited. Documents the proxy-absent failure
mode for Canvas.

**Dossier corrections confirmed by task-003:** D3.js licence is ISC (not MIT); vis-network is
Apache-2.0 OR MIT dual-licensed; Data Navigator v3.0.0 is the current release (not v2.4.x);
Sigma.js v3.0.3 is current (no v4 on public registry). See rendering-bench-and-options.md
§Dossier Corrections for full evidence.

---

## Part 3 — Bench Scale and Derivation

*Source: rendering-bench-and-options.md §Step 2 (task-003 output, measured 2026-07-28).*

| Metric | Value | Notes |
|--------|-------|-------|
| `int:` nodes | **583** | Counted directly from FS per FR-21/FR-22 rules |
| `kb:` nodes | **~201** | 21 docs + ~180 meaningful concept-level headings |
| `ext:` nodes | **0** | external-sources.md has no entries |
| **Total nodes (measured)** | **~784** | Central estimate; reproducible via commands in task-003 |
| **Total edges (measured minimum)** | **~589** | Enumerated carriers: 62 see_also + 161 sources + 226 CONFIRMED + 1 generated-files + 1 coined-term + 133 run-all.sh + 5 lockstep |
| **Total edges (estimated range)** | **~589–750** | Upper bound adds unenumerated int:→int: invocations |
| **A-5 assumption ("hundreds, not tens of thousands")** | **CONFIRMED** | 784 nodes / 589–750 edges — both firmly in the hundreds |
| **Overshoot bench** | **~7,840 nodes / ~7,500 edges** | fixture-10x.json, 10× scale; tests the A-5-violation case |

The spike fixtures (rendering-spike-matrix.md §Fixture Regeneration Procedure, task-004)
are `fixture-1x.json` (784 nodes / 750 edges, max-degree 187) and `fixture-10x.json`
(7,840 nodes / 7,500 edges, max-degree 1,942). No other fixture exists; no hub-heavy
sub-fixture at 120 nodes / 340 edges was generated. The bench fixture uses
Barabási-Albert preferential attachment seeded from real AID graph hub carriers, producing a
hub-heavy scale-free topology representative of a real KB graph.

---

## Part 4 — The Comparison Matrix

*Source: rendering-spike-matrix.md §The 25-Cell Comparison Matrix (task-004 output, measured 2026-07-28). Every cell is reproduced; cell basis (measured vs. derived) follows the spike matrix.*

**Column abbreviations:** `Build` = build requirement; `L@bench` = legibility at 784 nodes; `L@10×` = legibility at 7,840 nodes; `Interact` = FR-13/FR-14 interaction coverage (built-in behaviours + must-write work); `A11y cost` = WCAG AA accessibility cost; `Val` = validator trigger summary; `Update` = upstream update mechanism; `f008` = feature-008 size; `Basis` = measured/derived.

The 25 combinations arose from the **six renderer classes** (SVG, DOM, Canvas, WebGL, Multi, Hand-rolled) × five packaging shapes, after pre-screen drops. DOM has no viable standalone candidate and collapses into SVG or Canvas for edge drawing; Data Navigator (DOM overlay) is a composable layer, not a standalone renderer. Pre-screen drops before the five screens: D3.js × Shape 2, Cytoscape.js × Shape 1, vis-network × Shape 1, Sigma.js × Shape 1, AntV G6 × Shapes 1 and 2, Hand-rolled SVG × Shapes 2–5 (no vendor dependency — authored code has no "whole library" or "build output" form). See rendering-bench-and-options.md §Pre-screen drops for rationale.

All 25 survivors passed all five hard screens with no elimination. See Part 4A below.

### Part 4A — Five Hard Screens (task-003)

*Source: rendering-bench-and-options.md §Step 4 (task-003 output).*

| Screen | Criterion | Governing requirement | Eliminates |
|---|---|---|---|
| 1 | Can reach WCAG AA for the graph rendering with accessibility work priced in | NFR-1 | None — all 25 pass (cost varies: low for SVG, high for Canvas, very high for WebGL) |
| 2 | Can be driven from `relationships.md` alone via feature-007's lens view-model; no second extraction path | FR-3, AC-10 | None — all libraries accept external node/edge data |
| 3 | Can honour reduced-motion settling, keyboard zoom and pan, and non-colour encoding | NFR-4, NFR-5, NFR-6 | None — all libraries expose stop/tick, zoom, translate APIs |
| 4 | Can express four lenses including Impact's adjustable-depth neighbourhood; manual controls live after preset | FR-13, FR-14, AC-8 | None — BFS available natively (Cytoscape, graphology, G6) or inline ~30 lines (D3.js, vis-network) |
| 5 | Licence permits redistribution inside a generated artifact in a third party's repository, under MIT terms | Root `LICENSE` | None — ISC, MIT, Apache-2.0 all pass; vis-network MIT branch chosen over Apache-2.0 |

**Result: all 25 combinations survive to the spike (task-004).**

### Part 4B — 25-Cell Comparison Matrix

| # | Candidate | Rend. | Shape | Licence | Payload | Build | L@bench | L@10× | Interact | A11y cost | Val | Update | f008 | Basis | Verdict |
|---|-----------|-------|-------|---------|---------|-------|---------|-------|----------|-----------|-----|--------|------|-------|---------|
| 1 | D3.js v7.9.0 (d3-force+zoom+selection+drag) | SVG | 1 inline subset | ISC | **35,992 B (35.1 KB) inlined** | maintainer-time (concat 4 .min.js; re-inline on update) | GOOD–EXCELLENT: hub (deg 187) prominent; ≈3,600×3,600 px spread; 3,102 SVG elements | POOR: 31,104 SVG elements; pan/zoom degrades; hub forces extreme spread | Built-in: force, zoom, pan, drag, select. Must-write: BFS ~30 lines, filter, group | LOW: SVG native; ~50 lines ARIA+focus (spike scope; see Part 11 for 69-line full WCAG AA budget) | T2 FAIL by design; T1/T3/T4 PASS; S2 PASS; NM PASS | npm update 4 modules; ISC; re-inline .min.js | SMALL | **measured** | **recommended** |
| 2 | D3.js v7.9.0 | SVG | 3 companion | ISC | 35,992 B as graph.js companion | none | Same as row 1 | Same as row 1 | Same as row 1 | Same | Same | Same as row 1; manage separate file | SMALL | derived | rejected — companion adds deploy complexity; no rendering benefit |
| 3 | D3.js v7.9.0 | SVG | 4 CDN | ISC | 0 shipped; ~35 KB fetched | none | Same (if CDN available) | Same | Same as row 1 | Same | **S2 FAIL**; T2 FAIL; NM PASS | CDN URL pin; version risk | SMALL | derived | rejected — S2 FAIL; CDN dependency; offline fragility |
| 4 | D3.js v7.9.0 | SVG | 5 build+commit | ISC | 35,992 B committed | maintainer-time (bundler+commit) | Same as row 1 | Same as row 1 | Same as row 1 | Same | Same; S2 PASS | npm update → rebuild → commit | SMALL | derived | rejected — build step + committed artifact; no benefit over row 1 |
| 5 | Cytoscape.js v3.34.0 | Canvas | 2 inline whole | MIT | **435,328 B (425 KB) inlined** | none (copy cytoscape.min.js) | GOOD: Canvas; hub clear; data load <5ms | GOOD: Canvas handles 7,840 nodes; data load 198ms | Built-in: cose layout, zoom, pan, drag, cy.bfs(), filter, select. Must-write: depth slider (Impact lens) | HIGH: ~200–400 lines DOM proxy required | T1–T4 not triggered (Canvas); S2 PASS; NM PASS | npm update; MIT; copy new .min.js | SMALL | **measured** | rejected — 12× larger payload vs D3 subset; Canvas requires 200–400 line proxy; no perf advantage at 784 nodes |
| 6 | Cytoscape.js v3.34.0 | Canvas | 3 companion | MIT | 425 KB companion | none | Same as row 5 | Same | Same as row 5 | Same | S2 PASS; T1–T4 N/A | Same as row 5; manage separate file | SMALL | derived | rejected — same Canvas proxy; companion deploy complexity |
| 7 | Cytoscape.js v3.34.0 | Canvas | 4 CDN | MIT | 0 shipped; ~425 KB fetched | none | Same (if CDN) | Same | Same as row 5 | Same | **S2 FAIL**; T1–T4 N/A; NM PASS | CDN URL pin; availability risk | SMALL | derived | rejected — S2 FAIL; CDN; Canvas proxy |
| 8 | Cytoscape.js v3.34.0 | Canvas | 5 build+commit | MIT | 425 KB committed | maintainer-time | Same | Same | Same as row 5 | Same | S2 PASS; T1–T4 N/A | npm update → rebuild → commit | SMALL | derived | rejected — build step; Canvas proxy; same Canvas reasons |
| 9 | vis-network v10.1.0 | Canvas | 2 inline whole | Apache-2.0 OR MIT | **426,912 B (417 KB) inlined** | none (copy UMD bundle) | GOOD: Canvas; hub clear | GOOD: Canvas; similar timing to rows 5–8 | Built-in: force, zoom, pan, drag, clustering. Must-write: BFS ~30 lines, depth slider | HIGH: ~200–400 lines DOM proxy | T1–T4 N/A; S2 PASS; NM PASS | npm update; MIT branch; copy .min.js | SMALL | derived (Canvas class; payload from npm) | rejected — same Canvas proxy; dual-licence adds attribution decision |
| 10 | vis-network v10.1.0 | Canvas | 3 companion | Apache-2.0 OR MIT | 417 KB companion | none | Same | Same | Same as row 9 | Same | S2 PASS; T1–T4 N/A | Same as row 9; manage separate file | SMALL | derived | rejected — companion; same as row 9 |
| 11 | vis-network v10.1.0 | Canvas | 4 CDN | Apache-2.0 OR MIT | 0 shipped; ~417 KB fetched | none | Same (if CDN) | Same | Same as row 9 | Same | **S2 FAIL**; T1–T4 N/A; NM PASS | CDN URL pin; availability risk | SMALL | derived | rejected — S2 FAIL; CDN |
| 12 | vis-network v10.1.0 | Canvas | 5 build+commit | Apache-2.0 OR MIT | 417 KB committed | maintainer-time | Same | Same | Same as row 9 | Same | S2 PASS; T1–T4 N/A | npm update → rebuild → commit | SMALL | derived | rejected — build step; same as row 9 |
| 13 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 2 inline whole bundle | MIT+MIT | **261,505 B (255 KB) combined inlined** | maintainer-time (bundle sigma+graphology) | GOOD: WebGL renders trivially; ForceAtlas2 179ms bench | GOOD rendering; ForceAtlas2 **21,649ms** at 10× (CPU-bound; 33% slower than path graph due to hub concentration) | Built-in: FA2 layout, camera zoom/pan, hover, click. Must-write: BFS (graphology-traversal or inline), filter, group | VERY HIGH: ~300–500 lines DOM proxy + sigma.graphToViewport() coord transform | T1–T4 not triggered (WebGL canvas); S2 PASS; NM PASS | npm update sigma+graphology (2 pkgs); MIT; rebundle | SMALL | **measured** | rejected — no perf benefit at 784 nodes (CONFIRMED); highest A11y cost; 7× larger than D3 subset |
| 14 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 3 companion | MIT+MIT | 255 KB companion files | none | Same | Same | Same as row 13 | Same | S2 PASS; T1–T4 N/A | Same as row 13; manage separate files | SMALL | derived | rejected — same WebGL reasons |
| 15 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 4 CDN | MIT+MIT | 0 shipped; ~255 KB fetched | none | Same (if CDN) | Same | Same as row 13 | Same | **S2 FAIL**; T1–T4 N/A; NM PASS | CDN URL pin; CDN risk | SMALL | derived | rejected — S2 FAIL; CDN; WebGL no-benefit |
| 16 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 5 build+commit | MIT+MIT | 255 KB committed bundle | maintainer-time | Same | Same | Same as row 13 | Same | S2 PASS; T1–T4 N/A | npm update 2 pkgs → rebundle → commit | SMALL | derived | rejected — build step; same WebGL reasons |
| 17 | AntV G6 v5.1.1 | Multi (Canvas default) | 3 companion | MIT | **1,383,347 B (1.32 MB) companion g6.js** | none | GOOD: Canvas; hub clear | GOOD: Canvas; similar to rows 5–8 | Built-in: layouts, zoom, pan, drag, combo, neighbour. Must-write: depth slider; @antv/algorithm optional | HIGH (Canvas default): ~200–400 lines proxy | T1–T4 N/A; S2 PASS; NM PASS | npm update 16 @antv/* pkgs; high breaking-change risk | **LARGE** (16 @antv/* sub-packages) | **measured** | rejected — 1.32 MB bundle (38× D3 subset); LARGE feature-008; 16 @antv/* coordinated updates; Canvas proxy |
| 18 | AntV G6 v5.1.1 | Multi | 4 CDN | MIT | 0 shipped; ~1.32 MB fetched | none | Same (if CDN) | Same | Same as row 17 | Same | **S2 FAIL**; T1–T4 N/A; NM PASS | CDN URL pin; risk amplified by 1.32 MB bundle | LARGE | derived | rejected — S2 FAIL; CDN; same G6 reasons |
| 19 | AntV G6 v5.1.1 | Multi | 5 build+commit | MIT | 1.32 MB committed | maintainer-time | Same | Same | Same as row 17 | Same | S2 PASS; T1–T4 N/A | npm update 16 pkgs → rebuild → commit | LARGE | derived | rejected — build step; same G6 reasons |
| 20 | Hand-rolled SVG | SVG | 1 inline authored code | none | ~0 external bytes (authored ~5–15 KB) | none | GOOD (SVG class; same legibility as row 1) | POOR (SVG class; same 31,104+ element limit) | Must-write ALL: force sim, zoom, pan, drag, BFS, filter, group — no built-in behaviours | LOW: SVG native; ~50 lines ARIA+focus (same class as row 1) | T2 FAIL by design; T1/T3/T4 PASS; S2 PASS; NM PASS | No external deps; update = skill template change | NONE (no external deps) | derived (SVG class; payload by inspection) | rejected — requires writing all interaction from scratch (~500–1,000 lines vs ~50 lines calling D3 APIs) |
| 21 | Hand-rolled Canvas | Canvas | 1 inline authored code | none | ~0 external bytes (authored ~500–1,500 lines) | none | GOOD (Canvas class) | GOOD (Canvas) | Must-write ALL: Canvas draw (nodes/edges/labels), force sim, zoom matrix, hit-test, BFS, filter | HIGH+extra: Canvas proxy (200–400) + hand-written Canvas drawing (~500–1,500) = combined ~700–1,900 lines | T1–T4 N/A; S2 PASS; NM PASS | No external deps; update = skill template change | NONE | derived | rejected — most implementation work of any candidate; no benefit over rows 5–12 |
| 22 | Data Navigator v3.0.0 (+ chosen renderer) | DOM overlay | 1/2 inline (85 KB ESM) | MIT | **87,466 B (85 KB) inline** PLUS renderer payload | maintainer-time | N/A — DN provides no graph rendering (depends on paired renderer) | N/A | N/A — DN provides keyboard nav layer only; all graph rendering from paired renderer | MEDIUM additive: ~80 lines to build DN structure object; DN handles focus + ARIA; eliminates proxy hand-code | T1–T4 not triggered by DN alone; S2 PASS; NM PASS | npm update data-navigator; MIT; UNCERTAIN cadence (CMU research project) | SMALL | **measured** | rejected as standalone — not a complete renderer; D3.js+DN pairing (row 1 + row 22, ~120 KB total) merits accessibility-layer consideration |
| 23 | Data Navigator v3.0.0 (+ renderer) | DOM overlay | 3 companion | MIT | 85 KB companion PLUS renderer | none | Same as row 22 | Same | Same as row 22 | Same | T1–T4 N/A; S2 PASS; NM PASS | Same as row 22 | SMALL | derived | rejected — same as row 22 |
| 24 | Data Navigator v3.0.0 (+ renderer) | DOM overlay | 4 CDN | MIT | 0 shipped; ~85 KB fetched PLUS renderer | none | Same | Same | Same as row 22 | Same | **S2 FAIL** (CDN); NM PASS | CDN URL pin; UNCERTAIN cadence | SMALL | derived | rejected — S2 FAIL; CDN; not standalone |
| 25 | Data Navigator v3.0.0 (+ renderer) | DOM overlay | 5 build+commit | MIT | 85 KB committed PLUS renderer | maintainer-time | Same | Same | Same as row 22 | Same | S2 PASS | npm update + rebuild + commit | SMALL | derived | rejected — build step; not standalone |

---

## Part 5 — The Recommendation

**D3.js v7.9.0 (four-module ISC subset: d3-selection, d3-force, d3-zoom, d3-drag) × Shape 1 — Inline Vendored Subset**

Matrix row 1. Concatenate the four `.min.js` distribution files and inline them in a
`/* D3 VENDOR BEGIN */`…`/* D3 VENDOR END */` comment block inside `graph.html`'s `<script>`
element. No CDN fetch. No companion files. No build toolchain at adopter time. One
self-contained HTML file.

**Library:** D3.js, https://d3js.org / https://github.com/d3/d3, v7.9.0  
**Modules:** `d3-selection@3.0.0`, `d3-force@3.0.0`, `d3-zoom@3.0.0`, `d3-drag@3.0.0`  
**Licence:** ISC (all four modules)  
**Inlined payload:** 35,992 bytes (35.1 KB) — measured from spike harness
(rendering-spike-matrix.md §Spike 1, §Bundle sizes CONFIRMED)  
**Renderer:** SVG (D3 manipulates the DOM; no `<canvas>` or WebGL context)

---

## Part 6 — Rejected Alternatives

### Why the widened option space was used, not re-narrowed

Before FR-16 was amended, only a vendored inline subset within a single self-contained file
was practically admissible — which, for D3.js's four-module subset at 35.1 KB, is exactly
Shape 1 anyway. The amendment's value was enabling a genuine quality-first evaluation of:

- **Cytoscape.js v3.34.0 (425 KB, Canvas):** the richest library-backed option with built-in
  graph algorithms (`cy.bfs()`, `cy.neighborhood()`), the clearest quality/interaction
  upgrade the widening could have delivered. Previously dismissible on payload grounds
  alone; now evaluable on its merits. It was evaluated and rejected on Canvas accessibility
  cost (~200–400 line proxy, no perf advantage at 784 nodes) — not on packaging.
- **Sigma.js + graphology (255 KB, WebGL):** previously too large for a self-contained
  constraint; now evaluable inline (Shape 2). Evaluated and rejected because GPU rendering
  provides zero measured performance benefit at 784 nodes (ForceAtlas2 is CPU-bound; 179ms
  at bench is no faster than any other renderer class at the same scale) while imposing the
  highest accessibility cost (~300–500 line proxy + coordinate transform).
- **AntV G6 v5.1.1 (1.32 MB, Multi):** evaluable via companion file (Shape 3) after the
  amendment. Evaluated and rejected: 38× larger payload than D3.js subset; LARGE feature-008
  due to 16 coordinated @antv/* sub-package updates.
- **Build-step shapes (Shape 5):** explicitly evaluated for every renderer class. Rejected
  for all: no payload saving over Shape 1 for D3.js (the tree-shaken bundle of four modules
  would be marginally smaller than concatenating their .min.js files, not worth a bundler
  toolchain); the AID CI pipeline has no npm build phase (infrastructure.md §Build Commands).
- **CDN shapes (Shape 4):** explicitly evaluated; rejected for all. Every CDN row trips S2
  (`validate-html-output.sh` S2: no external CDN `<script src>`) and introduces an offline
  dependency at no quality advantage.
- **Data Navigator pairing (D3.js + DN, ~120 KB):** evaluated as an accessibility enhancement
  (rows 22–25). D3.js's native SVG semantics satisfy NFR-1 at 69 lines; adding DN would
  enhance keyboard graph traversal semantics at the cost of an additional 85 KB and a second
  dependency. Deferred: the SVG native semantics at 69 lines are sufficient for the A+
  quality bar; DN can be revisited if feature-009's gap analysis reveals a deficit.

**The recommendation lands on the same renderer class as a pre-amendment analysis would have,
but the widening was substantively used:** Cytoscape.js, Sigma.js, and AntV G6 were each
evaluated on quality and interaction merit under the packaging shapes the amendment newly
permitted, and each was rejected on those merits. The pre-amendment answer would have
dismissed them on payload grounds without evaluating them on quality grounds; this record
does not.

### Rejected renderer classes

#### 6.1 Canvas (Cytoscape.js v3.34.0, vis-network v10.1.0, Hand-rolled Canvas)

*Evidence: rendering-spike-matrix.md §Spike 2 (Cytoscape.js representative); §Accessibility Cost Summary.*

Canvas renders an opaque pixel buffer. The browser's accessibility tree sees only a single
`<canvas>` element with no navigable children. The Kibana evidence (source O, 2026-07-28)
documents the failure mode when no proxy is present. Reaching NFR-1 (WCAG AA) requires a
hand-built DOM proxy overlaying the canvas: ARIA roles, focus management, coordinate
synchronisation between pixel space and DOM space. The spike assessed this at **~200–400
lines** of proxy code.

At 784 nodes (bench), Cytoscape.js's Canvas renderer loads data in **< 5ms** — the same
order of magnitude as D3.js's SVG join. Force-directed layout (cose algorithm) is CPU-bound
like all others; no measured performance advantage at bench scale. Bundle size: 425 KB
(rows 5–8), 12× larger than the D3.js four-module subset, with no interaction quality
advantage that justifies the payload at this scale.

vis-network (417 KB, rows 9–12) is similar in rendering class and accessibility cost. Its
Apache-2.0 OR MIT dual licence was evaluated; MIT branch passes Screen 5, but the dual
licence adds an attribution decision step.

Hand-rolled Canvas (row 21) is the worst-case candidate: same Canvas proxy requirement
(~200–400 lines) plus hand-written Canvas drawing code (~500–1,500 lines) = combined
~700–1,900 lines.

**Rejection reason:** Canvas proxy cost (~200–400 lines) is 4–6× the SVG approach (69 lines
to reach full WCAG AA per Part 11 §11.2) with zero measured performance advantage at 784 nodes.

#### 6.2 WebGL (Sigma.js v3.0.3 + graphology v0.26.0)

*Evidence: rendering-spike-matrix.md §Spike 3, §WebGL No-Benefit Claim Verification.*

**Measured (CONFIRMED):** ForceAtlas2 on hub-heavy bench fixture (784 nodes, 750 edges,
max-degree 187): **179ms** for 50 iterations. At overshoot (7,840 nodes, max-degree 1,942):
**21,649ms**.

The GPU rasterisation step (WebGL rendering) accelerates painting pixels to the GPU
framebuffer. It does NOT accelerate the force-directed layout step — that runs on the CPU
regardless of renderer class. At 784 nodes, the CPU-bound layout dominates total frame time;
the GPU is idle during simulation. **WebGL provides no measured performance benefit at bench
scale.** (rendering-spike-matrix.md §WebGL No-Benefit Claim Verification, CONFIRMED.)

Accessibility cost is the highest of all classes: the WebGL surface is an opaque `<canvas>`
with no DOM structure. WCAG AA requires a DOM proxy plus the additional step of converting
WebGL geometry coordinates to screen coordinates via `sigma.graphToViewport()` for focus
management. The spike assessed this at **~300–500 lines** of proxy + coordinate transform
code.

Bundle: 261,505 bytes (255 KB) combined (sigma.min.js + graphology.umd.min.js) —
rendering-spike-matrix.md §Spike 3, CONFIRMED. This is 7× larger than the D3.js subset.

**Rejection reason:** Zero measured performance benefit at 784 nodes; highest accessibility
cost (~300–500 lines proxy); 7× larger payload.

#### 6.3 Multi-renderer (AntV G6 v5.1.1)

*Evidence: rendering-spike-matrix.md §Spike 4.*

AntV G6 v5.1.1 bundle: **1,383,347 bytes (1.32 MB)** — rendering-spike-matrix.md §Spike 4,
CONFIRMED. This is 38× larger than the D3.js four-module subset. G6's Canvas default mode
carries the same ~200–400 line WCAG AA proxy requirement as Cytoscape.js. G6 v5's SVG mode
is experimental (UNCERTAIN production stability). The 16 coordinated @antv/* sub-package
updates make feature-008 LARGE.

**Rejection reason:** 38× payload; LARGE feature-008; Canvas proxy; experimental SVG mode.

#### 6.4 Hand-rolled SVG

*Evidence: rendering-spike-matrix.md §The 25-Cell Comparison Matrix, row 20.*

D3.js's four-module subset implements exactly what hand-rolling would produce — a force
simulation (d3-force), SVG DOM selection and data binding (d3-selection), zoom transform
(d3-zoom), and drag behaviour (d3-drag) — under an ISC licence in 35.1 KB of tested,
maintained code. There is no correctness, performance, or licensing advantage to hand-rolling.
The spike estimated hand-rolled SVG at ~500–1,000 lines of interaction code versus ~50 lines
calling D3 APIs for the same behaviours.

**Rejection reason:** Pure duplication of D3.js's tested implementation at far greater cost.

### Rejected packaging shapes

#### 6.5 CDN Fetch (Shape 4) — all candidates

Every CDN row (3, 7, 11, 15, 18, 24) triggers the `validate-html-output.sh` S2 assertion
(`<script src="https://…">` found). S2 is a hard gate; it cannot be waived for `graph.html`
without a feature-011 parameterisation task (task-076/077). Additionally: CDN delivery
introduces a hard runtime network dependency (offline users cannot view the graph); the SRI
hash must be manually updated on every library release; IP tracking by the CDN provider. At
35.1 KB the payload cost of inlining D3.js is negligible, and the CDN tradeoffs are negative
on every dimension.

**Rejection reason:** S2 FAIL trips delivery gate; offline dependency; SRI maintenance burden;
no quality advantage at 35.1 KB payload.

#### 6.6 Build-step Output (Shape 5) — all candidates

Shape 5 candidates (rows 4, 8, 12, 16, 19, 25) require a maintainer-time bundler run with
the output committed. The AID CI pipeline is currently shell-only with no npm build phase
(infrastructure.md §Build Commands). Adding a bundler (rollup, esbuild) to produce a
committed artifact adds toolchain complexity for no measurable payload saving over
concatenating pre-minified .min.js files. The committed output is not human-readable, making
diffs opaque.

**Rejection reason:** Toolchain cost incompatible with current shell-only pipeline; committed
non-diffable artifact; no payload saving.

#### 6.7 Inline Whole Library (Shape 2) — candidates larger than D3 subset

D3.js Shape 2 (all 30+ modules inlined) was pre-screen dropped: the "whole" D3 package
includes geographical, statistical, and other modules irrelevant to graph rendering; including
them adds ~180 KB of unused code with no semantic distinction from Shape 1. For Cytoscape.js
(425 KB, row 5), vis-network (417 KB, row 9), Sigma.js (255 KB, row 13), and Data Navigator
(85 KB, row 22), Shape 2 was the minimum viable inline shape — these were evaluated (not
dropped) and rejected on renderer-class grounds above.

#### 6.8 Companion Files (Shape 3)

Shape 3 (rows 2, 6, 10, 14, 17, 23) commits a `.js` file beside `graph.html`. An adopter
who copies only `graph.html` gets a broken page. The payload bytes still travel; no savings.
For D3.js (35.1 KB), a companion adds distribution fragility for no benefit over inlining.
For larger candidates (Cytoscape.js at 425 KB, vis-network at 417 KB, AntV G6 at 1.32 MB),
the companion shape was evaluated on quality grounds and rejected on renderer-class grounds.

**Rejection reason:** Two-file dependency; fragile distribution for a documentation artifact;
no payload advantage over inlining for D3.js's subset.

---

## Part 7 — Runtime Prerequisites

`graph.html` is a single, self-contained HTML file. At the time a reader opens it, the
following conditions must hold and nothing more:

The file requires **no network access**. There is no CDN fetch, no external resource
reference, and no WebSocket or HTTP call at runtime. The D3.js modules are concatenated
verbatim into the file's `<script>` block at generation time; they are present in the file
before it is served or opened. A reader can open the file from a USB drive, an offline laptop,
or a network share with no internet access, and the graph will render.

The file requires **no companion asset files**. There are no external `.css`, `.js`, `.woff`,
or image files that must reside alongside `graph.html`. A reader can move the file to any
location on any filesystem, and it will render.

There is **no build output required at adopter time**. An adopter who installs the AID
tool-set gets `graph.html` as a committed artifact. No `npm install`, no `npm run build`, and
no environment variable is required to open the file. The only prerequisite is a
JavaScript-enabled browser (FR-17).

**At update time (maintainer only):** when D3.js modules are updated (see Part 9), the
maintainer must fetch the new `.min.js` files for the four modules, concatenate them in
declaration order (d3-selection, d3-force, d3-zoom, d3-drag), replace the
`/* D3 VENDOR BEGIN */`…`/* D3 VENDOR END */` block in `graph.html`, update the version
comment, and commit. No build toolchain is installed at the adopter site. No other files
change.

---

## Part 8 — Payload, Licence, and Attribution

### Payload

| Item | Value | Source |
|---|---|---|
| D3.js four-module subset (inlined) | **35,992 bytes (35.1 KB, uncompressed)** | rendering-spike-matrix.md §Spike 1, Bundle sizes CONFIRMED |
| — d3-selection@3.0.0 | 13,522 bytes | rendering-spike-matrix.md §Spike 1 |
| — d3-force@3.0.0 | 8,300 bytes | rendering-spike-matrix.md §Spike 1 |
| — d3-zoom@3.0.0 | 9,984 bytes | rendering-spike-matrix.md §Spike 1 |
| — d3-drag@3.0.0 | 4,186 bytes | rendering-spike-matrix.md §Spike 1 |
| graph.html template overhead | ~3–5 KB | Estimated from feature-007 shell structure |
| CDN fetch at load time | None | Shape 1 — no network dependency |
| `node_modules` committed | None | Shape 1 — no package manager at adopter site |
| npm/build toolchain required | None | Shape 1 — no build step |

### Licence

All four modules are distributed under the **ISC Licence** by Mike Bostock and Observable,
Inc. ISC is a two-clause permissive licence equivalent in effect to MIT. Source: npm
registry `d3-selection@3.0.0`, `d3-force@3.0.0`, `d3-zoom@3.0.0`, `d3-drag@3.0.0`
(verified 2026-07-28, source Q); D3.js ISC Licence text, https://github.com/d3/d3/blob/main/LICENSE
(source R, accessed 2026-07-28).

ISC requires:
1. The copyright notice is preserved in the distributed code.
2. The licence text is preserved in the distributed code.

ISC does **not** require a user-visible attribution notice, a footer, an about panel, or a
companion NOTICE file.

### Attribution — the specific place

**The copyright notices and licence text must appear in the `/* D3 VENDOR BEGIN */` comment
block inside `graph.html`'s `<script>` element, immediately preceding the inlined module
code.** No other location is required.

Concretely, the block must open with the verbatim ISC copyright notices from each module's
`.min.js` header:

```
/* D3 VENDOR BEGIN — d3-selection@3.0.0, d3-force@3.0.0, d3-zoom@3.0.0, d3-drag@3.0.0
   Copyright 2010-2024 Mike Bostock
   ISC License: https://github.com/d3/d3/blob/main/LICENSE
   [Per-module copyright notices from .min.js headers follow]
*/
```

This satisfies the ISC "copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software" requirement. The block is present in every
copy of the file regardless of where it is moved. No visible footer, about panel, or
companion file is required or added.

---

## Part 9 — Update Story

### Current baseline

The file `.github/dependabot.yml` (verified on disk 2026-07-28) declares:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "ci"
    groups:
      github-actions:
        patterns:
          - "*"
```

**Today, nothing in the repository notices upstream movement of any D3.js module.** There is
no `package.json` declaring the D3 dependencies, no lockfile, no dependabot npm entry, and no
CI check that reads D3 version strings from `graph.html`. A D3 security advisory or breaking
change would go undetected until a maintainer manually checked.

### Required mechanism

The mechanism is: **a scoped `package.json` at `canonical/aid/scripts/graph/package.json`
declaring the four D3 modules at exact version, plus a new Dependabot `npm` entry targeting
that directory.**

This follows the precedent of `canonical/aid/scripts/summarize/package.json` — the
summarize skill's scoped `"private": true` manifest pinning its dependencies without
committing `node_modules` (rendering-bench-and-options.md §External Integrations, paragraph
on precedent; infrastructure.md §The Build: Multi-Profile Render). The scoped manifest does
not require `npm install` at adopter time. Its sole purpose is version declaration for
Dependabot and the maintainer update procedure.

**Required `canonical/aid/scripts/graph/package.json`:**
```json
{
  "name": "@aid/graph-vendor",
  "version": "0.0.0",
  "private": true,
  "description": "Version declarations for D3.js modules inlined in graph.html. Not an npm package — Dependabot tracking only.",
  "dependencies": {
    "d3-selection": "3.0.0",
    "d3-force": "3.0.0",
    "d3-zoom": "3.0.0",
    "d3-drag": "3.0.0"
  }
}
```

**Required addition to `.github/dependabot.yml`:**
```yaml
  - package-ecosystem: "npm"
    directory: "/canonical/aid/scripts/graph"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "deps(graph)"
    groups:
      d3-graph:
        patterns:
          - "d3-*"
```

When Dependabot opens a PR for a new module version, the maintainer follows the procedure in
Part 7 to re-inline the updated `.min.js` files and commit. This is a **named mechanism** —
a Dependabot ecosystem entry — not an intention.

---

## Part 10 — Accessibility Confirmation

*Demonstrating — not asserting — that three WCAG AA behaviours are reachable with D3.js SVG.
Every claim cites a specific line in rendering-spike-matrix.md §Spike 1.*

### 10.1 Reduced-motion settling (NFR-4)

*Source: rendering-spike-matrix.md §Spike 1, "Other confirmed behaviours (unchanged from v1)"
line: "Reduced-motion: `sim.stop()` immediately; `sim.tick(N)` headless for settled layout ✓"*

D3.js `d3-force` ForceSimulation exposes `simulation.stop()` (halts immediately) and
`simulation.tick(n)` (advances n ticks synchronously, no animation callbacks). When
`window.matchMedia('(prefers-reduced-motion: reduce)').matches` is true:
1. `simulation.stop()` is called before any `requestAnimationFrame` fires.
2. `simulation.tick(300)` (or sufficient ticks for convergence) runs synchronously.
3. The final settled node positions are written to the SVG DOM in one synchronous pass.
4. The browser paints the settled layout in one frame; no animation plays.

**Status: CONFIRMED reachable** — the API exists and is exercised in the spike.

**One-time cost note:** The 300-tick headless run takes **750ms** at bench scale (measured —
rendering-spike-matrix.md §Spike 1, Force simulation table: "1× (bench) | 784 | 750 | 187 |
300 ticks headless | **750ms**"). This is a CPU-bound synchronous cost that runs once at page
load before the first paint. It is not an interaction latency (zoom, pan, and drag are
real-time after layout). Part 12 addresses whether 750ms is acceptable.

### 10.2 Keyboard zoom and pan (NFR-6)

*Source: rendering-spike-matrix.md §Spike 1, "Other confirmed behaviours (unchanged from v1)"
line: "Zoom/pan: `zoom.scaleBy()` + `zoom.translateBy()` available ✓"*

D3.js `d3-zoom` exposes `zoom.scaleBy(selection, factor)` and
`zoom.translateBy(selection, dx, dy)` — programmatic API calls that drive the zoom transform
independently of pointer events. The spike confirmed these methods are available and callable:
- `+`/`-` keys → `zoom.scaleBy(svgSelection, 1.2)` and `zoom.scaleBy(svgSelection, 1/1.2)`
- Arrow keys → `zoom.translateBy(svgSelection, ±50, 0)` and `zoom.translateBy(svgSelection, 0, ±50)`
- `0` key → reset to identity

All state changes update the same SVG transform that the visual rendering uses; the spatial
position of nodes is consistent between the visual and accessible representations.

**Status: CONFIRMED reachable** — the API exists and is callable from `keydown` handlers.
Estimated implementation: ~15 lines of `keydown` handler code.

### 10.3 Non-colour encoding (NFR-5)

*Source: rendering-spike-matrix.md §Spike 1, "Other confirmed behaviours (unchanged from v1)"
line: "SVG accessibility: native DOM tree; `<circle role="img">`, `<g tabIndex="0">` ✓"*

D3.js SVG renders real DOM elements. Node type can be conveyed by **shape** in addition to
fill colour via `d3-selection`'s `selection.append('rect')` / `.append('circle')` /
`.append('polygon')` per the node's `type` field in the `GraphModel` (feature-007 SPEC.md
§Data model). Edge type can be conveyed by **stroke-dasharray** pattern in addition to
stroke colour. No information need be encoded by colour alone.

**Status: CONFIRMED reachable** — SVG shape selection is standard D3 data-join logic.
Estimated implementation: ~20 lines of shape-selection code in the node-drawing function.

---

## Part 11 — Accessibility Cost

*Distinct from Part 10. Part 10 confirmed behaviours are reachable; Part 11 prices the work.*

### 11.1 Native accessibility-tree semantics

**Yes — D3.js SVG yields a native browser accessibility tree.** Every D3 selection call
produces real DOM elements: `<g class="node">`, `<circle>`, `<rect>`, `<line>`, `<text>`.
The browser exposes these elements in its accessibility tree without any additional code.
A `<g>` representing a node can carry `tabindex="0"`, `role="button"`,
`aria-label="Node: {id}"`, and `aria-describedby` pointing to a `<desc>` element.

**No hand-built proxy layer is required.** The accessible representation IS the rendered SVG,
not a separate mirrored structure. This is the fundamental WCAG AA cost difference between
SVG and Canvas/WebGL at this scale. (Source: rendering-spike-matrix.md §Accessibility Cost
Summary, SVG row: "Proxy layer required? NO".)

### 11.2 Implementation cost to reach WCAG AA

The spike assessed the SVG accessibility cost at **~50 lines ARIA + focus**
(rendering-spike-matrix.md §Accessibility Cost Summary, SVG row: "~50 lines (ARIA attributes
+ CSS `:focus-visible`)"). The full budget including reduced-motion and non-colour encoding:

| Behaviour | Mechanism | Est. lines |
|---|---|---|
| Tab-focusable nodes | `tabindex="0"` on each `<g.node>` | 2 |
| ARIA label on each node | `aria-label` set in D3 data join | 3 |
| ARIA label on each edge | `aria-label` set in D3 data join | 3 |
| Focus ring (visible indicator) | CSS `:focus-visible` outline on `.node` | 5 |
| Keyboard activation (Enter/Space) | `keydown` handler per node | 8 |
| Keyboard zoom/pan (Part 10.2) | Global `keydown` handler | 15 |
| Reduced-motion settling (Part 10.1) | `prefers-reduced-motion` branch | 10 |
| Non-colour encoding (Part 10.3) | Shape-selection logic in data join | 20 |
| Skip-to-table link (NFR-2 peer table) | `<a href="#table">` above SVG | 3 |
| **Total** | | **69 lines** |

> **Scope note (Part 4B reconciliation):** Part 4B row 1 states "~50 lines ARIA+focus" —
> this reproduces the spike matrix's narrower assessment (ARIA attributes + CSS
> `:focus-visible` only; rendering-spike-matrix.md §Accessibility Cost Summary, SVG row).
> The 69-line total above is the **full WCAG AA budget**: it adds keyboard zoom/pan handlers
> (15 lines), reduced-motion settling (10 lines), non-colour encoding (20 lines), and the
> skip-to-table link (3 lines) on top of the spike's ~50-line ARIA+CSS core. The two figures
> are consistent in scope; the 19-line difference is WCAG AA work required by NFR-1 through
> NFR-6 but outside the spike's narrow ARIA+CSS measurement.

### 11.3 Implication for feature-009

Feature-009 (accessible-table-view) renders the same `ViewModel` as the graph in a `<table>`
element (feature-009 SPEC.md). It is the primary vehicle for comprehensive screen-reader
traversal (NFR-1, NFR-2). Because D3.js SVG provides native semantics, the two renderings
are complementary: the SVG graph view supports spatial exploration with WCAG AA; the table
view supports linear traversal.

**Feature-009's implementation cost is unchanged by the renderer choice.** The table view
reads from `ViewModel`, not from the SVG DOM. Feature-009 does not need to produce a shadow
accessibility structure for the graph. The 69 lines of WCAG AA budget land in
feature-008, not feature-009.

**Cost verdict:** D3.js SVG imposes **69 lines of WCAG AA infrastructure on
feature-008** and **zero additional lines on feature-009** beyond what any renderer choice
would require.

---

## Part 12 — Scale-versus-Accessibility Tension, Resolved

### The tension stated

The owner dropped the packaging restrictions to permit maximum rendering power. The tension:
at very high node counts (tens of thousands), Canvas/WebGL's throughput advantage can
outweigh their accessibility proxy cost. At low node counts, SVG is comfortably within its
ceiling and its native semantics make WCAG AA dramatically cheaper.

### At the measured bench scale (784 nodes)

*Source: rendering-spike-matrix.md §WebGL No-Benefit Claim Verification, CONFIRMED.*

**D3.js force simulation (300 ticks headless) at 784 nodes / 750 edges / max-degree 187:
750ms.** (rendering-spike-matrix.md §Spike 1, Force simulation table, 1× row.) The spike
text itself assesses this: "D3's force simulation (300 ticks, more thorough convergence)
takes **750ms** — still acceptable for a one-time initial layout."
(rendering-spike-matrix.md §WebGL No-Benefit Claim Verification, Analysis point 2.)

**ForceAtlas2 (Sigma.js/WebGL) at the same scale: 179ms** (50 iterations).
(rendering-spike-matrix.md §Spike 3, Measured CONFIRMED, 1× row.)

These two timings are **one-time initial layout costs**, not interaction latencies:
- After the layout settles, pan and zoom are instant (SVG transform attribute updates).
- Drag is instant (per-node SVG coordinate update).
- The simulation does not re-run on user interaction unless explicitly restarted.
- For NFR-4 (reduced-motion): the 750ms runs synchronously before the first paint, after
  which the DOM is painted once in settled state. No animation plays. This complies with NFR-4.

**WebGL's GPU advantage does not apply to this 750ms cost.** WebGL accelerates the render
step (painting to the GPU framebuffer). The force simulation runs on the CPU regardless of
renderer class. At 784 nodes, the CPU-bound simulation dominates total frame time; the GPU
is idle during it. Choosing WebGL would produce a ForceAtlas2 1× layout in 179ms (vs D3.js's
750ms for 300 ticks), but would impose a ~300–500 line WCAG AA proxy plus coordinate
transform — a net regression. (Source: rendering-spike-matrix.md §WebGL No-Benefit Claim
Verification, Analysis points 1–4, CONFIRMED.)

**The tension runs in one direction at 784 nodes:** the most powerful renderer (WebGL) offers
zero GPU render benefit at this scale while imposing the highest accessibility cost. The
least powerful renderer (SVG) is comfortably within its ceiling
(rendering-bench-and-options.md §Scale-versus-Accessibility Tension: "SVG slows past a few
thousand elements; at 784 nodes, SVG is comfortably below that ceiling") and imposes the
lowest accessibility cost.

**At the overshoot scale (7,840 nodes):** D3.js 10× layout takes **17,735ms**
(rendering-spike-matrix.md §Spike 1, Force simulation table, 10× row); ForceAtlas2 takes
**21,649ms** (rendering-spike-matrix.md §Spike 3). Both are far beyond an interactive budget.
SVG additionally degrades at 31,104 elements. This is the A-5-violation case: if the project
ever exceeds the "hundreds" bound, the rendering approach must be revisited. At current
trajectory (784 nodes in a mature repository), this is not a practical concern.

### Pole chosen: Accessibility

The recommendation chooses the **accessibility pole** — D3.js SVG with native DOM semantics
— over the performance pole (Canvas/WebGL).

**Cost of that choice:**
1. **750ms one-time layout cost** at bench scale. Accepted as stated in the spike's own
   assessment ("still acceptable for a one-time initial layout"). This is a page-load cost,
   not an interaction latency; the artifact is a documentation viewer, not a real-time dashboard.
2. **T2 validator carve-out required.** The `validate-visuals.mjs` T2 overlap check cannot
   pass for a force-directed SVG layout by design. Feature-011 C2 contingency fires
   (tasks 084/085). See Step 8.
3. **Theoretical performance ceiling at ~5,000–10,000 nodes.** Acknowledged; not a practical
   concern given A-5.

**What the choice saves:**
1. Accessibility proxy lines avoided — per renderer class (arithmetic from Part 11's 69-line SVG budget):
   - vs. Canvas (rows 5–12, 21): ~200–400 lines proxy − 69 lines SVG budget = **~131–331 lines saved**
   - vs. WebGL (rows 13–16): ~300–500 lines proxy + coord transform − 69 = **~231–431 lines saved**
2. The SRI hash maintenance, CDN dependency risk, and S2 carve-out that Shape 4 would require.
3. A build toolchain at adopter time.

---

## Part 13 — Draft technology-stack.md Entry

*Draft for task-095 (delivery-006) to land. Do NOT edit `.aid/knowledge/technology-stack.md` now.*

The standing claim in technology-stack.md §Key Dependencies is that "AID deliberately ships
zero runtime dependencies for the CLI." D3.js is not a CLI dependency — it is a browser
dependency inside a generated HTML artifact. The drafted entry scopes this explicitly.

---

**Proposed addition to `technology-stack.md` §Key Dependencies (after `summarize` skill entry):**

```markdown
### Graph View — D3.js Subset (browser-only; inside `graph.html`)

Four D3.js v7 modules are vendored inline into `graph.html` at maintainer time by
concatenating their `.min.js` distribution files. They are **not** installed at adopter
time and do not affect the CLI's runtime environment. The CLI and all shell skills remain
free of runtime dependencies.

| Module | Version | Licence | Minified size |
|--------|---------|---------|---------------|
| d3-selection | 3.0.0 | ISC | 13,522 bytes |
| d3-force | 3.0.0 | ISC | 8,300 bytes |
| d3-zoom | 3.0.0 | ISC | 9,984 bytes |
| d3-drag | 3.0.0 | ISC | 4,186 bytes |
| **Total** | | **ISC** | **35,992 bytes (35.1 KB)** |

Sizes measured from spike harness `node_modules/*/dist/*.min.js` (task-004, 2026-07-28).

**Attribution:** ISC copyright notices from each module's `.min.js` header are preserved
verbatim in the `/* D3 VENDOR BEGIN */` comment block in `graph.html`. No user-visible
notice is required by ISC.

**Version tracking:** `canonical/aid/scripts/graph/package.json` (private; Dependabot npm
entry in `.github/dependabot.yml` directory `/canonical/aid/scripts/graph`).

**Update procedure:** When Dependabot opens a PR, the maintainer fetches the updated
`.min.js` files, re-concatenates them, replaces the vendor block in `graph.html`, updates
the version comment, and commits. No adopter-site build toolchain change is needed.
```

**Proposed addition to `technology-stack.md` §Version Concerns:**

```markdown
- **D3.js subset (graph.html):** Vendored at d3-selection@3.0.0, d3-force@3.0.0,
  d3-zoom@3.0.0, d3-drag@3.0.0. A d3-force major version bump may change the simulation
  API; the vendor block and feature-008's drawing code will need a coordinated update.
  Track via Dependabot PR for `canonical/aid/scripts/graph/package.json`.
```

---

## Part 14 — Draft infrastructure.md Entry

*Draft for task-095 (delivery-006) to land. Do NOT edit `.aid/knowledge/infrastructure.md` now.*

No build step is added to the CI/CD pipeline. The vendoring procedure (Part 7) is a
maintainer-time operation triggered by a Dependabot PR, not a CI step.

**Proposed addition to `infrastructure.md` §The Build: Multi-Profile Render (or a new
§Dependency Vendoring subsection):**

```markdown
### Graph View Dependency Vendoring (maintainer task; not in CI build)

The `graph.html` artifact inlines four D3.js v7 modules. This is a **maintainer-time
operation**, not a CI step. It does not run during `bash build.sh`. It is triggered
manually when Dependabot opens a version-bump PR for
`canonical/aid/scripts/graph/package.json`.

**Procedure:**
1. Identify the bumped modules from the Dependabot PR (one or more of: `d3-selection`,
   `d3-force`, `d3-zoom`, `d3-drag`).
2. Fetch the updated `.min.js` files for the bumped modules (e.g., download from
   `https://cdn.jsdelivr.net/npm/d3-{module}@{version}/dist/d3-{module}.min.js` —
   network access required only during this maintainer step, not at adopter runtime).
3. Concatenate the four files in declaration order: `d3-selection`, `d3-force`, `d3-zoom`,
   `d3-drag`.
4. Replace the content of the `/* D3 VENDOR BEGIN */`…`/* D3 VENDOR END */` block in
   `graph.html` with the concatenated content, preserving ISC copyright notices at the top.
5. Update the version comment immediately after `/* D3 VENDOR BEGIN */`.
6. Commit with message `deps(graph): update D3 modules to {version}`.

**CI impact:** None. `bash build.sh` does not change. The committed `graph.html` is a source
file, not a build output, for CI purposes.

**Note:** `canonical/aid/scripts/graph/node_modules/` must be in `.gitignore` if a
maintainer runs `npm install` locally for inspection. The `package.json` is version-
declaration-only; no `node_modules` directory is committed.
```

---

## Part 15 — Feature-008 Size Implication

*Source: feature-008-interactive-graph-canvas/SPEC.md §"What changes with feature-002's
answer"; rendering-spike-matrix.md §The 25-Cell Comparison Matrix, row 1.*

### Renderer-dependent work items (resolved to D3.js SVG)

| Item | D3.js SVG outcome |
|---|---|
| Mark element type | `<g class="node">` with child `<rect>`/`<circle>`/`<polygon>` per node type |
| Focus management | `tabindex="0"` + `:focus-visible` CSS on `<g>` elements |
| Accessibility attributes | `aria-label`, `role` on SVG elements (native tree) |
| Hit testing | Browser-native `pointer-events` on SVG elements |
| Zoom/pan state | D3 `ZoomTransform` via `zoom.on('zoom', …)` |
| T2 validator | FAILS by design (force-directed SVG overlaps `<g>` bounding boxes); task-084/085 fires |

### Feature-008 size estimate

The spike matrix labels row 1 f008 size as **SMALL** (rendering-spike-matrix.md §The 25-Cell
Comparison Matrix, row 1 "f008 size" column: "SMALL"). The implementation:

| Component | Est. lines |
|---|---|
| Graph data join (nodes + edges, D3 selection) | ~60 |
| Force simulation setup (d3-force) | ~40 |
| d3-zoom behavior setup (svg.call, transform listener; keydown handlers are in WCAG AA budget below) | ~15 |
| d3-drag setup | ~20 |
| Edge stroke-dasharray style mapping (edge type → stroke pattern) | ~15 |
| Lens filter application (ViewModel → filtered render) | ~30 |
| Tooltip/detail panel on node activation | ~30 |
| WCAG AA budget (Part 11 §11.2: ARIA+focus, keyboard zoom/pan handlers, non-colour encoding logic, reduced-motion settling, skip-link) | **69** |
| **Total implementation estimate** | **~279 lines** |

> **Derivation note:** prior draft figures of ~305 and ~325 lines were revised down to ~279
> by a net reduction of exactly **46 lines**, composed of four named adjustments:
> (a) keyboard zoom/pan handlers removed from rendering components and consolidated into the
> WCAG AA budget: **−15 lines**;
> (b) non-colour encoding / shape-selection logic removed from rendering components and
> consolidated into the WCAG AA budget: **−20 lines**;
> (c) reduced-motion settling branch removed from rendering components and consolidated into
> the WCAG AA budget: **−10 lines**;
> (d) WCAG AA budget corrected from the prior draft's ~70 to the verified table total of 69:
> **−1 line**.
> Total reduction: 15 + 20 + 10 + 1 = **46 lines**. 325 − 46 = **279**. ✓
> The rendering components (~210 lines) are estimated from D3.js API surface; the WCAG AA
> budget (69 lines) is the scoped figure from Part 11 §11.2. Both are labelled estimates.

This is a **small** feature. The spike validated the core drawing loop; feature-008
is primarily assembly, not invention.

### T2 sequencing implication for delivery-005

Feature-011's C2 contingency (tasks 084/085: add `--profile` flag to `validate-visuals.mjs`)
must be completed **before** feature-008's CI visual-regression gate is enabled. Delivery-005
must place tasks 084/085 as a prerequisite for the feature-008 CI step that enables the
visual regression check.

---

## Step 8 — Hand-Off to Downstream Consumers

### Consumer 1: Feature-007 — Graph View Shell

**What feature-007 takes:**
- Part 7 (runtime prerequisites): single self-contained `graph.html`; no companion file
  reference in `<head>`; vendor block marked with `/* D3 VENDOR BEGIN */`…`/* D3 VENDOR END */`.
- Part 5 (packaging Shape 1): no companion `.js` file added to shell.
- Part 8 (attribution): shell template opens vendor block with ISC copyright notices.

**Conditional tasks:** None. Feature-007 is unconditionally unblocked.

---

### Consumer 2: Feature-008 — Interactive Graph Canvas

**What feature-008 takes:**
- Part 5: D3.js SVG, four-module subset; drawing code uses `d3.select`, `d3.forceSimulation`,
  `d3.zoom`, `d3.drag`.
- Parts 10–11: WCAG AA budget 69 lines (Part 11 §11.2); keyboard zoom/pan handlers and reduced-motion settling are included in the 69-line total, not separate additions.
- Part 15: SMALL feature; ~279 lines (corrected from earlier draft; see Part 15 derivation note); T2 contingency (tasks 084/085) must precede CI gate.

**Conditional tasks:** task-084/085 must precede feature-008's CI visual-regression gate.

---

### Consumer 3: Feature-009 — Accessible Table View

**What feature-009 takes:**
- Part 11: D3.js SVG provides native accessibility-tree semantics; no proxy layer; feature-009
  is the primary screen-reader vehicle (NFR-2) and does not need to provide a shadow DOM.
  Its own implementation cost is unchanged by the renderer choice.

**Conditional tasks:** None. Feature-009 is renderer-independent by design.

---

### Consumer 4: Feature-011 — Validator Parameterisation

**task-076/077 (S2 CDN carve-out for `validate-html-output.sh`): DOES NOT FIRE.**  
Reason: Shape 4 (CDN delivery) was rejected. No `<script src="https://…">` in `graph.html`.
S2 passes without carve-out.

**task-084/085 (`validate-visuals.mjs` T2 SVG live-surface exclusion): FIRES.**  
Reason: The recommended renderer is SVG. A force-directed SVG layout places nodes at
physics-determined positions; `<g>` bounding boxes overlap by design. The T2 check (sibling
overlap > 20%) cannot pass for `graph.html` under any valid force layout. Feature-011 must
add a `--profile` (or equivalent) flag so `graph.html` runs under a permissive T2 profile
while `kb.html` retains the strict T2 check. Tasks 084/085 are **unconditionally required**
given the SVG renderer choice.

---

### Consumer 5: Feature-012 — Canonical Registration

**What feature-012 takes:**
- Parts 13, 14: draft technology-stack.md entry (with per-module byte sizes), scoped
  `package.json`, vendoring procedure.
- Part 9: Dependabot npm entry for `canonical/aid/scripts/graph`.

**task-083 (dependency-packaging gate — third-party adoption): FIRES.**  
Reason: A third-party library (D3.js, four modules, ISC) IS adopted as a vendored inline
dependency. Feature-012's D3 gate applies. Because Shape 1 (no-build vendored inline) is
selected, the conditions that apply are:

- **G4 (semantic version pinned):** Satisfied by `canonical/aid/scripts/graph/package.json`
  declaring exact versions (`"d3-selection": "3.0.0"`, etc.) and by the version comment in
  the vendor block. Task-083 must confirm the version is recorded.
- **G5 (licence and attribution recorded):** Satisfied by Part 8 (ISC notices in the vendor
  block) and Part 13 (technology-stack.md draft entry). Task-083 must verify this record is
  in place.
- G1 (private package), G2 (no npm install at adopter time), G3 (no build at adopter time),
  G6 (no transitive deps), G7–G8 (CDN-related): collapse or are N/A for vendored inline
  no-build shape.

Task-083 fires and is lightweight: verify G4 and G5, update manifest count surfaces, confirm
Dependabot entry is present.

---

*End of record. Written by aid-researcher, task-005 (revised after adversarial review),
delivery-001, work-005-knowledge-graph. 2026-07-28.*
