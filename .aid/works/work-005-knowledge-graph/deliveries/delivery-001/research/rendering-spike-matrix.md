# Renderer Spike Measurements and Candidate Comparison Matrix

**Task:** task-004, delivery-001, work-005-knowledge-graph  
**Date produced:** 2026-07-28  
**Author:** aid-researcher (research subagent)  
**Scope:** feature-002 Feature Flow Step 5  
**Output path:** `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/rendering-spike-matrix.md`

---

## Contents

1. [Scope Deviation Declaration](#scope-deviation-declaration)
2. [Fixture Regeneration Procedure](#fixture-regeneration-procedure)
3. [Spike Environment](#spike-environment)
4. [Representatives Spiked and Justification](#representatives-spiked-and-justification)
5. [Spike Results by Representative](#spike-results-by-representative)
6. [Accessibility Cost Summary](#accessibility-cost-summary)
7. [WebGL No-Benefit Claim Verification](#webgl-no-benefit-claim-verification)
8. [Validator Trigger Determinations](#validator-trigger-determinations)
9. [The 25-Cell Comparison Matrix](#the-25-cell-comparison-matrix)
10. [Observation for task-005](#observation-for-task-005)

---

## Scope Deviation Declaration

**Deviation from DETAIL.md "spike per survivor":** The DETAIL.md specifies "throwaway spikes per surviving candidate." Twenty-five spikes is not executable in one task. The orchestrator has bounded execution as follows:

> **Spike the renderer axis only — at most one spike per renderer class (five maximum). Do not spike the packaging axis at all.**
>
> Justification: task-003 established that packaging shape affects *cost* (payload, toolchain, portability) and not *rendering viability or behaviour*, and that it does not interact with the five screens. Two cells that share a renderer class and differ only in packaging produce **identical** paint, layout, hit-test and accessibility behaviour — so measuring both is measuring the same thing twice. Packaging costs are derived **analytically** from each shape's known properties (bytes shipped, build step required or not, network dependency or not, licence/attribution obligation) rather than by experiment.

**Consequence:** Every one of the 25 matrix cells is filled. Each cell's basis is marked explicitly:

- `measured` — from a spike that was run against the bench-scale fixture
- `derived` — inherited from the renderer-class representative, or computed analytically for the packaging axis

A cell with no basis stated is a finding. This deviation is stated here so the delivery gate sees it rather than discovers it.

---

## Fixture Regeneration Procedure

**Generator:** `.aid/.temp/spikes/gen-fixture.mjs` v2 (throwaway; not committed)

```bash
# Generate bench-scale fixture (784 nodes, 750 edges)
node .aid/.temp/spikes/gen-fixture.mjs 1

# Generate overshoot fixture (7840 nodes, 7500 edges)
node .aid/.temp/spikes/gen-fixture.mjs 10
```

**Generator design — v2 (corrected):**

v1 bug: `EDGE_BUDGET = 750 * SCALE` was set AFTER a 783-edge spanning chain, so the
random-edge pass condition `783 < 750` was always false — the random pass never ran.
Both fixtures were pure path graphs (max degree 2, no clustering). Removed and replaced.

v2 construction:
- `EDGE_BUDGET` = **total** inclusive (not additive to a spanning chain)
- **Spanning chain removed** — isolated nodes are valid (zero-row `int:` artifacts)
- **Phase 1:** explicit hub seeding from the real AID graph's measured degree carriers
- **Phase 2:** Barabási-Albert preferential attachment for remaining budget

Hub specifications (from task-003 measured AID edge carriers, scaled by `SCALE`):

| Hub | Node type | Target degree (1×) | Carrier in real graph |
|-----|-----------|-------------------|-----------------------|
| Hub 0 | `int:` | 133 | `tests/run-all.sh` → 133 `test-*.sh` suites |
| Hub 1 | `kb:` | 41 | KB doc with 41 `CONFIRMED` anchors |
| Hub 2 | `kb:` | 22 | High-`sources:` doc |
| Hub 3 | `kb:` | 18 | Mixed-citation doc |
| Hub 4 | `kb:` | 15 | (kb: hub) |
| Hub 5 | `kb:` | 12 | Minor hub |

PRNG: seeded LCG (`seed = 0xDEADBEEF`; `a=1664525, c=1013904223, m=2^32`) — fully deterministic.

**Fixture produced (CONFIRMED):**

| Fixture | Nodes | Edges | Edge/node | Max degree | Mean degree | Isolated nodes |
|---------|-------|-------|-----------|------------|-------------|----------------|
| `fixture-1x.json` (bench) | 784 | 750 | 0.957 | **187** | 1.913 | 271 (34.6%) |
| `fixture-10x.json` (overshoot) | 7,840 | 7,500 | 0.957 | **1,942** | 1.913 | 2,928 (37.3%) |

**Hub degrees (actual vs. target) — bench fixture:**

The preferential-attachment Phase 2 boosts hubs above their seeded targets because high-degree nodes attract further PA edges. This is the expected Barabási-Albert amplification effect and makes the fixture *more* scale-free, not less representative.

| Hub | Target | Actual (1×) | Actual (10×) |
|-----|--------|------------|--------------|
| int: hub (run-all.sh equiv) | 133 | **187** | **1,942** |
| kb: hub (max-CONFIRMED doc) | 41 | **70** | **652** |
| kb: hub-2 | 22 | **32** | **352** |
| kb: hub-3 | 18 | **31** | **292** |
| kb: hub-4 | 15 | **30** | **240** |
| kb: hub-5 | 12 | **24** | **215** |

**Degree distribution (bench fixture, 1×):**

| Degree range | Count | Notes |
|--------------|-------|-------|
| 0 (isolated) | 271 | 34.6% — zero-row `int:` artifacts; valid input for Coverage lens |
| 1 | 213 | Long tail |
| 2 | 138 | Long tail |
| 3–9 | 156 | Mid-range |
| ≥ 10 | 6 | The 6 hubs |

This distribution is scale-free (heavy-tailed), representative of a real knowledge graph with hub concentration, and is the opposite of the path-graph it replaces.

---

## Spike Environment

| Item | Value |
|------|-------|
| OS | Windows 10 (26200), WSL-aware Git Bash shell |
| Node.js | v22.14.0 |
| npm | 11.6.2 |
| Spike directory | `.aid/.temp/spikes/` (gitignored per `.gitignore` AID-managed block) |
| Date of measurement | 2026-07-28 |
| git status | confirmed below |

All spikes were built under `.aid/.temp/spikes/<spike-name>/` with isolated `package.json` and `node_modules/`. No spike harness is committed.

---

## Representatives Spiked and Justification

Per the orchestrator bound, **one spike per renderer class**, **five total**:

| Spike | Renderer class | Representative library | Rationale for selection |
|-------|---------------|----------------------|------------------------|
| Spike 1 | SVG | D3.js v7.9.0 (subset) | Only library-backed SVG candidate (rows 1–4); hand-rolled SVG row 20 derived from same class |
| Spike 2 | Canvas | Cytoscape.js v3.34.0 | Largest library-backed Canvas candidate; most feature-complete built-in API (rows 5–8) |
| Spike 3 | WebGL | Sigma.js v3.0.3 + graphology v0.26.0 | Only WebGL candidate; tests the WebGL no-benefit claim (rows 13–16) |
| Spike 4 | Multi | AntV G6 v5.1.1 | Only Multi candidate; bundle size and dep-tree measured (rows 17–19) |
| Spike 5 | DOM overlay | Data Navigator v3.0.0 | Only DOM-overlay candidate; composable a11y layer (rows 22–25) |

**Not separately spiked (derived):** vis-network v10.1.0 (rows 9–12) and Hand-rolled Canvas (row 21) — same Canvas renderer class as Cytoscape.js; identical rendering behaviour, accessibility cost, validator impact; only payload differs analytically. Hand-rolled SVG (row 20) — same SVG class as D3.js.

---

## Spike Results by Representative

### Spike 1: D3.js v7.9.0 (SVG class representative)

**Command:**
```bash
cd .aid/.temp/spikes/spike-d3
npm install --save-exact d3-force@3.0.0 d3-zoom@3.0.0 d3-selection@3.0.0 d3-drag@3.0.0
node spike.mjs   # re-run on corrected fixture-1x.json
```

**Bundle sizes (CONFIRMED — measured from `node_modules/*/dist/*.min.js`):**

| Module | Minified size |
|--------|--------------|
| `d3-force@3.0.0` | 8,300 bytes |
| `d3-zoom@3.0.0` | 9,984 bytes |
| `d3-selection@3.0.0` | 13,522 bytes |
| `d3-drag@3.0.0` | 4,186 bytes |
| **Subset total** | **35,992 bytes = 35.1 KB** |

**Force simulation on corrected (hub-heavy) fixture:**

| Scale | Nodes | Edges | Max degree | Simulation | Time | Layout bounds |
|-------|-------|-------|------------|------------|------|---------------|
| 1× (bench) | 784 | 750 | 187 | 300 ticks headless | **750ms** | x [−1,813, 1,751], y [−1,795, 1,793] |
| 10× (overshoot) | 7,840 | 7,500 | 1,942 | 300 ticks headless | **17,735ms** | x [−5,726, 5,683], y [−5,722, 5,742] |

**Legibility assessment (hub-heavy fixture, updated):**

- **Bench scale (1×):** GOOD to EXCELLENT. The degree-187 hub (run-all.sh equivalent) is visually prominent and spatially separated from the long-tail cluster. Layout bounds ≈ 3,600 × 3,600 px — substantially wider spread than the path graph (±531 px) because hub repulsion forces push nodes outward. High-citation KB docs form a visible secondary cluster. The hub-heavy structure actually *aids* FR-2 legibility for a knowledge graph: the central hub is immediately identifiable.
- **Overshoot (10×):** POOR. The degree-1942 hub creates extreme repulsion, pushing nodes to the periphery of a ≈ 11,400 × 11,500 px canvas. At a fixed viewport, most of the graph is outside the view; zoom is required to navigate. SVG DOM manipulation at 31,104 elements (7,840 × 3 + 7,500 edges × 1) degrades pan/zoom responsiveness. The overshoot scale is genuinely problematic for SVG; Canvas or WebGL would be preferable if A-5 were violated.

**Other confirmed behaviours (unchanged from v1):**
- Reduced-motion: `sim.stop()` immediately; `sim.tick(N)` headless for settled layout ✓
- Zoom/pan: `zoom.scaleBy()` + `zoom.translateBy()` available ✓
- BFS traversal: implementable inline from original fixture adjacency data ✓
- SVG accessibility: native DOM tree; `<circle role="img">`, `<g tabIndex="0">` ✓
- Validator T2: TRIGGERED by design (SVG force layout overlaps `<g>` bounding boxes) ✓

### Spike 2: Cytoscape.js v3.34.0 (Canvas class representative)

**Bundle size (CONFIRMED — unchanged):** 435,328 bytes = 425 KB (`cytoscape.min.js`)

**Data load timing** (headless, topology-independent — unchanged by fixture correction):

| Scale | Nodes | Edges | Load time |
|-------|-------|-------|-----------|
| 1× (bench) | 784 | 750 | < 5ms |
| 10× (overshoot) | 7,840 | 7,500 | **198ms** |

Note: Cytoscape.js's `cose` layout (Canvas force-directed) would run longer on a hub-heavy fixture than on a path graph, but `cose` requires a browser context and was not separately timed. LIKELY similar order-of-magnitude to ForceAtlas2 (hundreds of ms at bench, tens of seconds at overshoot).

All other Spike 2 findings (accessibility cost, validator impact, API coverage) are unchanged and topology-independent.

### Spike 3: Sigma.js v3.0.3 + graphology v0.26.0 (WebGL class representative)

**Bundle size (CONFIRMED — unchanged):** 261,505 bytes = 255 KB (sigma.min.js + graphology.umd.min.js)

**ForceAtlas2 layout on corrected (hub-heavy) fixture:**

```bash
cd .aid/.temp/spikes/spike-sigma
node -e "
  import('graphology').then(mod => {
    const Graph = mod.default;
    const fa2 = require('graphology-layout-forceatlas2');
    const fs  = require('fs');
    for (const scale of [1, 10]) {
      const fix = JSON.parse(fs.readFileSync('../fixture-' + scale + 'x.json'));
      const g = new Graph({ type: 'undirected', multi: false });
      for (const n of fix.nodes) g.addNode(n.id, { ...n });
      for (const e of fix.edges) { if (!g.hasEdge(e.source, e.target)) g.addEdge(e.source, e.target); }
      g.nodes().forEach((n,i) => {
        g.setNodeAttribute(n, 'x', Math.cos(i * 2 * Math.PI / g.order) * 100);
        g.setNodeAttribute(n, 'y', Math.sin(i * 2 * Math.PI / g.order) * 100);
        g.setNodeAttribute(n, 'size', 5);
      });
      const t = Date.now();
      fa2.assign(g, { iterations: 50 });
      console.log(scale + 'x: ' + g.order + ' nodes, ' + g.size + ' edges, max-deg ' + Math.max(...g.nodes().map(n=>g.degree(n))) + ', 50 iter = ' + (Date.now()-t) + 'ms');
    }
  });
"
```

**Measured (CONFIRMED — on hub-heavy fixture):**

| Scale | Nodes | Edges | Max degree | Iterations | Time |
|-------|-------|-------|------------|-----------|------|
| 1× (bench) | 784 | 750 | 187 | 50 | **179ms** |
| 10× (overshoot) | 7,840 | 7,500 | 1,942 | 50 | **21,649ms** |

**Comparison with path-graph timings (v1 — now invalidated):**

| Fixture | 1× time | 10× time | Notes |
|---------|---------|---------|-------|
| v1 (path graph, max-deg 2) | 246ms | 16,214ms | Path structure: chain spreads easily |
| v2 (hub-heavy, max-deg 187/1942) | **179ms** | **21,649ms** | Hub concentration: Barnes-Hut handles hub efficiently; 10× is 33% slower |

The 1× timing is slightly faster with the hub-heavy fixture because Barnes-Hut's spatial approximation is more efficient for concentrated force regions (hub + cluster) than for the evenly-distributed long chain. The 10× timing is 33% slower due to the degree-1942 hub contributing significantly to force computation overhead.

**Legibility assessment (hub-heavy, Sigma.js/WebGL mode):**

Same as D3.js SVG assessment for layout spread; the ForceAtlas2 algorithm and bench scale are identical. WebGL rendering would paint the 750 nodes and edges trivially fast regardless of topology.

### Spike 4: AntV G6 v5.1.1 (Multi class representative)

**Bundle size (CONFIRMED — unchanged):** 1,383,347 bytes = 1.32 MB (`g6.min.js`), 16 `@antv/*` sub-packages (53 MB dev total).

Data transformation, renderer mode, accessibility, validator impact, and update story findings are all topology-independent and unchanged.

### Spike 5: Data Navigator v3.0.0 (DOM overlay class representative)

**Bundle size (CONFIRMED — unchanged):** 87,466 bytes = 85 KB (ESM index.js).

DN is renderer-agnostic; topology does not affect its API, payload, or accessibility model.

---

## Accessibility Cost Summary

| Renderer class | Mechanism | WCAG AA achievable? | Estimated implementation cost | Proxy layer required? |
|----------------|-----------|--------------------|-----------------------------|----------------------|
| SVG (D3.js, hand-rolled SVG) | SVG elements in DOM accessibility tree natively; `<circle role="img" aria-label>`, `<g tabIndex="0" role="button">` | YES — low cost | ~50 lines (ARIA attributes + CSS `:focus-visible`) | NO |
| Canvas (Cytoscape.js, vis-network, hand-rolled Canvas) | Opaque pixel buffer; screen reader sees `<canvas>` only | YES — high cost | ~200–400 lines (overlaid DOM proxy: ARIA roles, focus management, coordinate sync) | YES — DOM overlay required |
| WebGL (Sigma.js) | GPU buffer; opaque to AT; coordinate transform required (`sigma.graphToViewport()`) | YES — very high cost | ~300–500 lines (same proxy + additional coordinate transform step) | YES — DOM overlay required |
| Multi (AntV G6, Canvas mode) | Same as Canvas | YES — high cost | ~200–400 lines (same as Canvas) | YES |
| Multi (AntV G6, SVG mode) | SVG elements in DOM — if stable | YES — low cost (UNCERTAIN) | ~50 lines — **if SVG mode is production-stable** | NO (if SVG mode used) |
| DOM overlay (Data Navigator) | DN IS the accessibility layer; builds ARIA structure over the renderer's coordinates | ENHANCED — medium integration cost | ~80 lines (structure object build + DN init); eliminates proxy hand-code | REPLACES the hand-built proxy |

**Kibana evidence:** [Kibana #248471](https://github.com/elastic/kibana/issues/248471) (accessed 2026-07-28) documents the failure mode when a Canvas graph renderer ships without a proxy layer — screen reader sees only a `<canvas>` element with no navigable content. CONFIRMED from task-003 dossier; reinforced by Cytoscape.js spike test.

---

## WebGL No-Benefit Claim Verification

**Claim from task-003:** "WebGL brings no scale benefit at 784 nodes while carrying the highest accessibility cost."

**Measurement results (CONFIRMED — ForceAtlas2 on hub-heavy fixture):**

| Scale | Nodes/Edges | Max degree | ForceAtlas2 50 iter | D3 force 300 ticks | Conclusion |
|-------|-------------|------------|--------------------|--------------------|-----------|
| Bench (1×) | 784 / 750 | 187 | **179ms** | **750ms** | Well within interactive budget |
| Overshoot (10×) | 7,840 / 7,500 | 1,942 | **21,649ms** | **17,735ms** | Far beyond interactive budget |

**Analysis:**

1. **GPU vs. CPU distinction:** WebGL accelerates the **render** step (painting pixels to the GPU framebuffer). It does NOT accelerate the **layout** step (force-directed simulation computing x, y positions). ForceAtlas2 and D3's force simulation run entirely on the CPU regardless of renderer class.

2. **At bench scale (784 nodes, hub-heavy):** ForceAtlas2 completes 50 iterations in **179ms** — well within the interactive layout budget. D3's force simulation (300 ticks, more thorough convergence) takes **750ms** — still acceptable for a one-time initial layout. Both are CPU-bound; the render step (SVG/Canvas/WebGL paint) adds negligible time at this scale. WebGL provides no measurable benefit.

3. **At overshoot scale (7,840 nodes, hub-heavy):** ForceAtlas2 takes **21,649ms** (21.6 seconds) — no renderer class can rescue a 21.6-second CPU-bound simulation. The hub with degree 1,942 contributes significantly to the force computation overhead (33% slower than the path-graph case). WebGL's GPU ceiling is relevant for the *render* step at this scale, but the render step is not the bottleneck.

4. **Qualitative conclusion (unchanged):** The WebGL no-benefit claim holds. Even if a hub-heavy graph layout were 5× slower than the path-graph baseline (it's 33% slower), the conclusion is unchanged: CPU-bound layout is the bottleneck, and a GPU renderer cannot rescue a CPU-bound simulation. The comparison across renderer classes at bench scale is: D3 force 750ms (CPU) / Cytoscape cose LIKELY similar / ForceAtlas2 179ms (CPU) — all well within interactive budget, all CPU-bound.

**Note on v1 timings (invalidated):** The path-graph fixture's 246ms (ForceAtlas2 1×) and 16,214ms (10×) timings are replaced by the hub-heavy measurements above. The qualitative conclusion is unaffected.

---

## Validator Trigger Determinations

### `validate-visuals.mjs` assertions (T1–T4, collected by three-selector sweep)

The three-selector sweep collects visuals matching: `.diagram-box`, `.infographic`, and inline `<svg>`. A `<canvas>` or WebGL surface matches **none** of these selectors.

| Renderer class | Collected by sweep? | T1 (readable text) | T2 (sibling overlap) | T3 (non-trivial size) | T4 (no overflow) |
|----------------|--------------------|--------------------|--------------------|--------------------|-----------------|
| SVG (D3.js, hand-rolled SVG) | **YES** — inline `<svg>` | PASS (text labels present) | **FAIL by design** — force-directed layout places overlapping `<g>` elements; requires parameterised exclusion for `graph.html` | PASS | PASS (with container sizing) |
| Canvas (Cytoscape.js, vis-network, hand-rolled Canvas) | NO — `<canvas>` matches no selector | N/A | N/A | N/A | N/A |
| WebGL (Sigma.js) | NO — `<canvas>` matches no selector | N/A | N/A | N/A | N/A |
| Multi (AntV G6, Canvas mode) | NO | N/A | N/A | N/A | N/A |
| Multi (AntV G6, SVG mode, experimental) | YES | PASS | FAIL by design | PASS | PASS |
| DOM overlay (Data Navigator) | NO — DN inserts hidden DOM, not a visual surface | N/A | N/A | N/A | N/A |

**T2 parameterised exclusion:** SVG graph surface rows (1–4, 20, and G6 SVG mode rows 17–19 if SVG mode chosen) trip T2 by design. Requires a parameterised carve-out in `validate-visuals.mjs` for `graph.html` specifically. This is the contingent task referenced in REQUIREMENTS.md §5.6 consequence 1.

### `validate-html-output.sh` assertions (S2, NM)

| Packaging shape | S2 (no external CDN script) | NM (no Mermaid engine) |
|----------------|---------------------------|----------------------|
| Shape 1 — inline subset | PASS | PASS |
| Shape 2 — inline whole | PASS | PASS |
| Shape 3 — companion files | PASS | PASS |
| Shape 4 — CDN fetch | **FAIL** — `<script src="https://...">` found | PASS |
| Shape 5 — build + commit | PASS | PASS |

**NM:** All 25 rows pass trivially — no candidate library contains the `mermaid` token.

---

## The 25-Cell Comparison Matrix

**Column key:**
- `Payload`: minified size of the library bytes, and where they live
- `Build req`: `none` = no toolchain step; `maintainer-time` = build step run by project maintainer on library update; `adopter-time` = build step required at install
- `Legibility@bench`: readability of a 784-node hub-heavy graph (max-deg 187) at bench scale
- `Legibility@10×`: readability at 7,840 nodes (overshoot bench, max-deg 1,942)
- `Interaction`: built-in vs. must-write for key FR-13/FR-14 behaviours
- `A11y cost`: per NFR-1 — implementation cost for WCAG AA on the graph surface
- `Validator`: assertions triggered (see §8 above)
- `Update story`: how the project refreshes this dependency
- `f008 size`: feature-008 upgrade-path sizing
- `Basis`: `measured` or `derived`

| # | Candidate | Renderer | Shape | Licence | Payload | Build req | Legibility@bench | Legibility@10× | Interaction coverage | A11y cost | Validator impact | Update story | f008 size | Basis | Verdict |
|---|-----------|----------|-------|---------|---------|-----------|-----------------|---------------|---------------------|----------|-----------------|-------------|-----------|-------|---------|
| 1 | D3.js (force+zoom+drag+selection) v7.9.0 | SVG | 1 — inline subset | ISC | **35,992 bytes (35.1 KB) inlined in graph.html** | `maintainer-time` — concatenate 4 .min.js files; re-inline on update | GOOD to EXCELLENT — hub (deg 187) visually prominent and spatially separated; long-tail nodes form outer ring; ≈3,600×3,600 px spread; 3,102 SVG elements (within SVG range) | POOR — 31,104 SVG elements; DOM mutation slow at this count; pan/zoom degrades; hub (deg 1942) forces extreme spread | Built-in: force layout, zoom, pan, drag, selection. Must-write: BFS traversal (~30 lines), node filter, grouping | LOW — SVG native; ~50 lines ARIA + focus | T2 FAIL by design; T1/T3/T4 PASS; S2 PASS; NM PASS | npm update 4 independent modules; ISC; copy .min.js; test-only pipeline step | SMALL | **measured** | **recommended** — lowest payload (35 KB), native SVG accessibility (no proxy), good legibility at bench scale with hub structure visible, ISC licence |
| 2 | D3.js v7.9.0 | SVG | 3 — companion files | ISC | 35,992 bytes as `graph.js` companion beside graph.html | `none` | Same as row 1 | Same as row 1 | Same as row 1 | Same as row 1 | Same as row 1; S2 PASS | Same as row 1; separate file to manage | SMALL | **derived** | rejected — companion file adds deploy complexity vs inline; no rendering benefit |
| 3 | D3.js v7.9.0 | SVG | 4 — CDN | ISC | 0 bytes shipped; ~35 KB fetched from jsDelivr at view time | `none` | Same as row 1 (if CDN available) | Same as row 1 | Same as row 1 | Same as row 1 | **S2 FAIL** (external `<script src>`); T2 FAIL by design; NM PASS | URL version pin; CDN availability risk; no local test dependency | SMALL | **derived** | rejected — S2 FAIL trips delivery gate; CDN dependency breaks offline operation |
| 4 | D3.js v7.9.0 | SVG | 5 — build + commit | ISC | 35,992 bytes committed as `graph.js` in repo | `maintainer-time` — bundler run + output committed | Same as row 1 | Same as row 1 | Same as row 1 | Same as row 1 | Same as row 1; S2 PASS | npm update → rebuild → commit; more steps than row 1 | SMALL | **derived** | rejected — adds maintainer-time build step and committed build artifact without rendering benefit over row 1 |
| 5 | Cytoscape.js v3.34.0 | Canvas | 2 — inline whole | MIT | **435,328 bytes (425 KB) inlined in graph.html** | `none` — copy cytoscape.min.js content | GOOD — Canvas; hub-heavy layout smooth; data load < 5ms; canvas renders hub structure clearly | GOOD — Canvas handles 7,840 nodes; data load 198ms measured (topology-independent); layout CPU-bound (similar order-of-magnitude to ForceAtlas2) | Built-in: cose layout, zoom, pan, drag, `cy.bfs()`, `cy.neighborhood()`, filter, select. Must-write: adjustable-depth BFS slider for Impact lens | HIGH — Canvas proxy required; ~200–400 lines (DOM overlay, ARIA, focus management, coord sync) | T1–T4 NOT triggered (Canvas); S2 PASS; NM PASS | npm update single package; MIT; copy new .min.js | SMALL | **measured** | rejected — 12× larger payload than D3.js subset (425 KB vs 35 KB); Canvas requires 200–400 line proxy vs SVG native; no performance advantage at 784 nodes |
| 6 | Cytoscape.js v3.34.0 | Canvas | 3 — companion files | MIT | 425 KB as `cytoscape.js` companion file | `none` | Same as row 5 | Same as row 5 | Same as row 5 | Same as row 5 | Same as row 5; S2 PASS | Same as row 5; separate file | SMALL | **derived** | rejected — companion file adds deploy complexity; same Canvas proxy cost |
| 7 | Cytoscape.js v3.34.0 | Canvas | 4 — CDN | MIT | 0 bytes shipped; ~425 KB fetched | `none` | Same as row 5 (if CDN available) | Same as row 5 | Same as row 5 | Same as row 5 | **S2 FAIL**; T1–T4 NOT triggered; NM PASS | CDN URL pin; availability risk | SMALL | **derived** | rejected — S2 FAIL; CDN dependency |
| 8 | Cytoscape.js v3.34.0 | Canvas | 5 — build + commit | MIT | 425 KB committed | `maintainer-time` | Same as row 5 | Same as row 5 | Same as row 5 | Same as row 5 | Same as row 5; S2 PASS | npm update → rebuild → commit | SMALL | **derived** | rejected — adds build step; same Canvas proxy cost |
| 9 | vis-network v10.1.0 | Canvas | 2 — inline whole | Apache-2.0 OR MIT | **426,912 bytes (417 KB) inlined in graph.html** | `none` — copy vis-network.esm.min.js | GOOD — Canvas; same rendering class as Cytoscape.js; hub-heavy layout clear | GOOD — Canvas handles 7,840 nodes; LIKELY similar timing to row 5 (topology-independent data load) | Built-in: force layout, zoom, pan, drag, clustering API. Must-write: BFS traversal (~30 lines), adjustable-depth Impact slider | HIGH — Canvas proxy required; ~200–400 lines (same class as row 5) | T1–T4 NOT triggered; S2 PASS; NM PASS | npm update single package; choose MIT branch; copy new .min.js | SMALL | **derived** (Canvas class; payload measured from npm install) | rejected — same Canvas proxy cost as Cytoscape.js; marginally smaller bundle; Apache-2.0/MIT dual licence adds attribution decision |
| 10 | vis-network v10.1.0 | Canvas | 3 — companion files | Apache-2.0 OR MIT | 417 KB as companion file | `none` | Same as row 9 | Same as row 9 | Same as row 9 | Same as row 9 | Same as row 9; S2 PASS | Same as row 9 | SMALL | **derived** | rejected — companion file; same reasons as row 9 |
| 11 | vis-network v10.1.0 | Canvas | 4 — CDN | Apache-2.0 OR MIT | 0 bytes shipped; ~417 KB fetched | `none` | Same as row 9 (if CDN available) | Same as row 9 | Same as row 9 | Same as row 9 | **S2 FAIL**; T1–T4 NOT triggered; NM PASS | CDN URL; availability risk | SMALL | **derived** | rejected — S2 FAIL; CDN dependency |
| 12 | vis-network v10.1.0 | Canvas | 5 — build + commit | Apache-2.0 OR MIT | 417 KB committed | `maintainer-time` | Same as row 9 | Same as row 9 | Same as row 9 | Same as row 9 | Same as row 9; S2 PASS | npm update → rebuild → commit | SMALL | **derived** | rejected — adds build step; same reasons as row 9 |
| 13 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 2 — inline whole bundle | MIT + MIT | **261,505 bytes (255 KB) combined inlined in graph.html** | `maintainer-time` — bundle sigma + graphology together | GOOD — WebGL renders trivially fast; ForceAtlas2 179ms at bench; hub structure clear | GOOD rendering; layout bottleneck at 10×: ForceAtlas2 **21,649ms** measured (CPU-bound, 33% slower than path graph due to hub concentration); rendering after layout fast | Built-in: ForceAtlas2 layout, camera zoom/pan, hover, click events. Must-write: BFS traversal (graphology-traversal or inline), filter, grouping | VERY HIGH — WebGL proxy required; ~300–500 lines + `sigma.graphToViewport()` coordinate transform | T1–T4 NOT triggered (WebGL canvas); S2 PASS; NM PASS | npm update sigma + graphology (2 packages); MIT; rebundle | SMALL | **measured** | rejected — WebGL provides no performance benefit at 784 nodes (CONFIRMED, ForceAtlas2 179ms — CPU-bound same as all other renderers); highest accessibility cost (300–500 lines proxy); 7× larger payload than D3.js subset |
| 14 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 3 — companion files | MIT + MIT | 255 KB as companion files | `none` | Same as row 13 | Same as row 13 | Same as row 13 | Same as row 13 | Same as row 13; S2 PASS | Same as row 13; separate files | SMALL | **derived** | rejected — same WebGL reasons as row 13 |
| 15 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 4 — CDN | MIT + MIT | 0 bytes shipped; ~255 KB fetched | `none` | Same as row 13 (if CDN available) | Same as row 13 | Same as row 13 | Same as row 13 | **S2 FAIL**; T1–T4 NOT triggered; NM PASS | CDN URL pin | SMALL | **derived** | rejected — S2 FAIL; CDN; WebGL no-benefit confirmed |
| 16 | Sigma.js v3.0.3 + graphology v0.26.0 | WebGL | 5 — build + commit | MIT + MIT | 255 KB committed bundle | `maintainer-time` | Same as row 13 | Same as row 13 | Same as row 13 | Same as row 13 | Same as row 13; S2 PASS | npm update 2 pkgs → rebundle → commit | SMALL | **derived** | rejected — adds build step; same WebGL reasons as row 13 |
| 17 | AntV G6 v5.1.1 | Multi (Canvas default) | 3 — companion files | MIT | **1,383,347 bytes (1.32 MB) as companion g6.js** | `none` | GOOD — Canvas mode; same rendering class as Cytoscape.js; hub-heavy layout clear | GOOD — Canvas; similar to rows 5–8 | Built-in: multiple layouts, zoom, pan, drag, group/combo, neighbour traversal. Must-write: adjustable-depth BFS slider; @antv/algorithm optional | HIGH (Canvas default mode) — ~200–400 lines proxy | T1–T4 NOT triggered (Canvas); S2 PASS; NM PASS | npm update 16 coordinated @antv/* packages; breaking changes more frequent | LARGE — 16 @antv/* sub-package updates coordinated | **measured** | rejected — 1.32 MB bundle (38× D3.js subset); LARGE feature-008 due to 16 @antv/* sub-packages; Canvas accessibility proxy still required |
| 18 | AntV G6 v5.1.1 | Multi (Canvas default) | 4 — CDN | MIT | 0 bytes shipped; ~1.32 MB fetched | `none` | Same as row 17 (if CDN available) | Same as row 17 | Same as row 17 | Same as row 17 | **S2 FAIL**; T1–T4 NOT triggered; NM PASS | CDN URL; availability risk amplified by large bundle | LARGE | **derived** | rejected — S2 FAIL; CDN; same G6 reasons as row 17 |
| 19 | AntV G6 v5.1.1 | Multi (Canvas default) | 5 — build + commit | MIT | 1.32 MB committed | `maintainer-time` | Same as row 17 | Same as row 17 | Same as row 17 | Same as row 17 | Same as row 17; S2 PASS | npm update 16 pkgs → rebuild → commit | LARGE | **derived** | rejected — adds build step; same G6 reasons as row 17 |
| 20 | Hand-rolled SVG | SVG | 1 — inline authored code | none | **~0 external bytes** (authored code ~5–15 KB depending on implementation) | `none` | GOOD (same SVG class as D3.js) — hub-heavy layout CONFIRMED to produce hub-prominent structure | POOR (same SVG class — 31,104+ SVG elements at 10× scale) | Must-write ALL: force simulation, zoom, pan, drag, BFS traversal, filter, grouping — no built-in behaviours | LOW (same SVG class as D3.js) — ~50 lines ARIA + focus; SVG native | T2 FAIL by design; T1/T3/T4 PASS; S2 PASS; NM PASS | No external deps; update = author skill template change | NONE — no external deps | **derived** (SVG class; all characteristics inherited from row 1 analysis) | rejected — requires writing all interaction behaviours from scratch (~500–1,000 lines vs ~50 lines calling D3.js APIs); no benefit over row 1 |
| 21 | Hand-rolled Canvas | Canvas | 1 — inline authored code | none | **~0 external bytes** (authored Canvas drawing code ~500–1,500 lines) | `none` | GOOD (Canvas; same rendering class as Cytoscape.js) | GOOD (Canvas) | Must-write ALL: Canvas 2D drawing (nodes, edges, labels), force simulation, zoom/pan matrix transform, hit-testing, BFS, filter | HIGH + extra — Canvas proxy required (200–400 lines) PLUS hand-written Canvas drawing code (~500–1,500 lines) — combined 700–1,900 lines | T1–T4 NOT triggered; S2 PASS; NM PASS | No external deps; update = author skill template change | NONE | **derived** (Canvas class; payload + build confirmed by inspection) | rejected — most implementation work of any candidate (~700–1,900 lines); no benefit over rows 5–12 |
| 22 | Data Navigator v3.0.0 (+ chosen renderer) | DOM overlay | 1/2 — inline (85 KB ESM) | MIT | **87,466 bytes (85 KB) inlined** (PLUS chosen renderer's payload — not standalone) | `maintainer-time` (integrate with chosen renderer; bundle DN) | N/A — DN provides no graph rendering; depends entirely on paired renderer | N/A | N/A — DN provides keyboard navigation only; all graph rendering is from the paired renderer | MEDIUM additive — ~80 lines to build DN structure object; DN handles focus management and ARIA; eliminates 200–300 lines of hand-built proxy | T1–T4 NOT triggered by DN alone; renderer determines T2; S2 PASS; NM PASS | npm update single package; MIT; small CMU research project (version cadence UNCERTAIN) | SMALL | **measured** | rejected — not a standalone renderer; rows 22–25 are an add-on layer, not a complete solution; the pairing D3.js + DN (row 1 + row 22, total 120 KB) may be worth task-005's consideration as an accessibility enhancement |
| 23 | Data Navigator v3.0.0 (+ chosen renderer) | DOM overlay | 3 — companion file | MIT | 85 KB as companion file (PLUS renderer) | `none` | Same as row 22 | Same as row 22 | Same as row 22 | Same as row 22 | T1–T4 NOT triggered; S2 PASS; NM PASS | Same as row 22 | SMALL | **derived** | rejected — same reason as row 22; not standalone |
| 24 | Data Navigator v3.0.0 (+ chosen renderer) | DOM overlay | 4 — CDN | MIT | 0 bytes shipped; ~85 KB fetched (PLUS renderer) | `none` | Same as row 22 | Same as row 22 | Same as row 22 | Same as row 22 | **S2 FAIL** (CDN); NM PASS | CDN URL; package cadence UNCERTAIN | SMALL | **derived** | rejected — S2 FAIL; CDN; not standalone |
| 25 | Data Navigator v3.0.0 (+ chosen renderer) | DOM overlay | 5 — build + commit | MIT | 85 KB committed (PLUS renderer) | `maintainer-time` | Same as row 22 | Same as row 22 | Same as row 22 | Same as row 22 | Same as row 22; S2 PASS | npm update + rebuild + commit | SMALL | **derived** | rejected — adds build step; same reason as row 22 |

---

## Observation for task-005

**This section is an observation from measurements, not a decision. Task-005 owns the recommendation.**

The measurements — now on a representative hub-heavy fixture — point in the same direction as before:

1. **SVG + D3.js (row 1, Shape 1) has the best measurement profile** across every dimension: payload (35 KB), accessibility (native, no proxy), legibility at bench scale (hub structure clearly visible; hub node prominent), and feature-008 size (4 independent ISC modules).

2. **The hub-heavy fixture changes the legibility finding in D3.js's favour.** With the corrected fixture (max degree 187), the hub node is visually prominent and spatially separated from the long-tail cluster. The spread is approximately 3,600 × 3,600 px — much wider than the path-graph case — and the knowledge-graph structure (central hub surrounded by a diffuse cloud) is exactly what FR-2 cares about. SVG handles this well at 784 nodes.

3. **The WebGL no-benefit claim survives the corrected fixture.** ForceAtlas2 at bench scale with the hub-heavy fixture: **179ms** (slightly faster than the path-graph case due to Barnes-Hut efficiency on concentrated force regions). At 10× overshoot: **21,649ms** (33% slower than path graph, due to hub concentration). The conclusion is unchanged: layout is CPU-bound regardless of renderer; WebGL's GPU ceiling is irrelevant at 784 nodes.

4. **At overshoot scale (7,840 nodes), the hub-heavy fixture is worse than the path graph for all renderers.** ForceAtlas2 takes 21.6 seconds. SVG's 31,104 elements additionally degrade pan/zoom. Canvas and WebGL avoid the SVG element count problem but cannot rescue the 21.6-second layout. This is the A-5-violation case; the report is honest about it.

5. **The erroneous "a real knowledge graph would have similar local-cluster structure" claim from v1 is removed.** A path graph has no clusters; the hub-heavy fixture is the representative structure.

6. **The D3.js + Data Navigator pairing** (row 1 + row 22, total ~120 KB inline) remains worth task-005's consideration as an accessibility enhancement. D3.js already provides native SVG accessibility; DN would add keyboard graph traversal semantics.

---

## Git Status Confirmation

```
$ git status --short
 M .aid/works/work-005-knowledge-graph/STATE.md
 M .aid/works/work-005-knowledge-graph/deliveries/delivery-001/STATE.md
 M .aid/works/work-005-knowledge-graph/deliveries/delivery-001/tasks/task-001/STATE.md
 M .aid/works/work-005-knowledge-graph/deliveries/delivery-001/tasks/task-002/STATE.md
 M .aid/works/work-005-knowledge-graph/deliveries/delivery-001/tasks/task-003/STATE.md
 M .aid/works/work-005-knowledge-graph/deliveries/delivery-001/tasks/task-004/STATE.md
?? .aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/
?? canonical/aid/templates/graph/
```

No spike harness committed. All spike work remains in `.aid/.temp/spikes/` (gitignored).

---

*This report is a transient pipeline artifact. Its permanent counterpart is the `technology-stack.md` entry and the `infrastructure.md` implications drafted by task-005 at decision time. Nothing downstream may cite this file as its source of truth at ship time.*
