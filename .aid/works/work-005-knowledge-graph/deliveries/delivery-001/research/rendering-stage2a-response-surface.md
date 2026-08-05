# Stage 2a — the parametric frame-time response surface

> **Scope: Stage 2a only.** This document is task-003's deliverable: feature-002 D2b's response
> surface and D4's per-measurand verdicts *that D2b's five axes can exercise*, measured under
> D4b's frame-time predicate. **No bench size is stated anywhere in this document** (AC-S3) —
> every node count, edge count, degree and category count below is a **synthetic fixture
> parameter**, self-built by this task's own generator, explicitly labelled as such everywhere it
> appears, and never presented as "the bench" or as this repository's own graph. Stage 2b (the
> derived bench, NFR-7's verdict, NFR-8's ceiling) is `task-010`'s, gated on delivery-002; Stage 3
> (payload, licence, update mechanism) is `task-002`'s. Neither is in this document, and their
> absence is deliberate — § 8 states exactly what is owed by which task.

**Work:** work-005-knowledge-graph · **Feature:** feature-002 · **Date run:** 2026-08-05
**Repository state:** branch `work-005`, HEAD at the time of this run (harness touches no
product file; see § 9)
**Specification:** `.aid/works/work-005-knowledge-graph/features/feature-002-graph-rendering-research/SPEC.md`
§ D2b, § D3, § D4, § D4a, § D4b (revision gated A+ 2026-07-30)
**Depends on:** `deliveries/delivery-001/research/rendering-stage1-webgl-probe.md` (Stage 1 — L1/L2/L3
all PASS on ENV-2, software rasteriser; no escalation fires; this task's precondition is met)

---

## 1. Question and scope — D10 part 1 (Stage 2a's share of it)

**The question, from D2b:** *how does frame time respond to node count, edge count, maximum
degree, category count and concurrent hover-label count* — the five axes D2b names, each varied
independently over a stated range with the other four held at a stated baseline?

**Type note on this task's RESEARCH default override.** task-003's own scope record states the
override explicitly: this task measures a response surface rather than selecting between
alternatives, so the usual "at least 2 alternatives compared" RESEARCH default does not apply. The
substituted obligation — *every one of D2b's five axes is actually varied and reported* — is
discharged at § 3–7 below, one section per axis, each stating what was varied, over what range, and
with what else held fixed.

**Explicitly out of scope here**, named so an absence below is never mistaken for an omission:

| Not in this document | Why, and who owes it |
|---|---|
| The derived bench, NFR-7's clears/does-not-clear verdict at it, NFR-8's ceiling | Stage 2b — `task-010`, which depends on this document plus feature-004's enumerator and feature-005's Pass 1a (D2, D-2a) |
| Node drag (D4 measurand 6) | Not one of D2b's five axes. NFR-7 gates it as AC-6a's second window; `task-010`'s scope names both windows explicitly and needs its own drive mechanism (a simulated pointer drag re-heating the simulation), which this harness does not build |
| Reduced-motion settled render (D4 measurand 8) | Not one of D2b's five axes |
| Vendored-bundle token / render-transform checks (D4 measurand 9) | Stage 3 — `task-002` |
| Payload, licence, attribution, update mechanism (D6, D7) | Stage 3 — `task-002` |
| Palette-as-CSS-custom-properties feasibility (D8) | feature-007/008, per D8's own routing |
| AC-21's keyboard route (D9) | Renderer-independent by construction (D9); not re-derived here |
| A CI-environment (ENV-1) or unprovisioned-browser (ENV-3) run of *this* harness | Stage 1 already established the environment-generalisation risk and its remedy (§ 2.6 of the Stage 1 report); this task ran on the ENV-2 equivalent only — see § 10's limitation note |

---

## 2. Method

### 2.1 The frame-time predicate — D4b, cited by section, not re-invented

Per feature-002 SPEC **§ D4b**, "≥30 fps" is reported as a **frame-time distribution**, not a
mean: this document states the statistic (median and the 95th percentile, "p95"), the window (150
sampled frames per point, after 30 excluded warm-up frames), and the threshold (33.33 ms per
frame, the reciprocal of 30 fps) at every sampled point. D4b's warm-up-exclusion clause is honoured
literally: the first 30 frames after scene construction are ticked and drawn but never timed, so a
one-time cost (shader compilation, first-frame buffer allocation) cannot leak into the statistic.

**This document applies the predicate to steady simulation only.** D4b's own text names two
workloads — steady simulation and node drag — and task-003's scope is the five D2b axes, none of
which is drag. The drag workload is `task-010`'s (§ 1's table).

**D4b point 3 — the headless-conservatism comparison — is discharged at § 8**, with both renderer
identity strings recorded, per AC-S7.

### 2.2 The fixture generator — D3

Self-built for this task, independent of any work folder's contents (A-6) and of this
repository's own Knowledge Base (FR-8a): `.aid/.temp/graph-stage2a-harness/generate-fixture.mjs`,
gitignored, throwaway, **not added to `canonical/` or `tests/`**. It emits the delivered
ten-column `relationships.md` shape (FR-3, AC-10: `Source Id`, `Source Kind`, `Source Name`,
`Target Id`, `Target Kind`, `Target Name`, `S2T Relation`, `T2S Relation`, `Provenance`,
`Observation`), with every `Kind` cell a member of the closed seven-value enum and every relation
pair read from `canonical/aid/templates/graph/relation-vocabulary.yml` (read 2026-08-05): one
verified (relation, inverse, source-kind, target-kind, provenance) tuple per category, checked
against that entry's own `endpoint_kinds` and `passes` fields at the time this file was written
(the generator's own `CATEGORY_TABLE` constant carries the citation inline). All 14 categories
that file states as feature-001's research finding are exercised (D4a).

Reused from the superseded work's methodology, per the delivery-001 supersession banner: **hub
seeding** and **isolated nodes deliberately kept** (5 % of the fixture's base population by
default). Not reused: any fixture *size* — every count below is a fresh parameter of this task's
own sweep.

**Parameterised on D2b's five axes and nothing else:**

1. `nodeCount` — total node count.
2. `meanDegree` — the lever for edge count, independent of node count.
3. `maxDegree` — the degree of one designated hub node.
4. `categoryCount` — how many of the 14 categories the fixture's edges are drawn from.
5. `hoverProbeDegrees` — a small set of extra, separately-reported probe nodes, each wired to
   exactly *N* fresh leaf nodes, so the hover-label axis can be swept by choosing *which* node to
   hover without perturbing axes 1–4's own totals.

Every sample below is generated with an explicit, recorded seed (`mulberry32`, a public-domain
32-bit PRNG), so any point is reproducible.

**A defect in this generator was found and fixed before any measurement was trusted, and is
recorded rather than silently corrected**, in the same spirit Stage 1 recorded its own S1-1: the
first version of the max-degree lever let the *filler* pass (the one that builds the base
population's mean degree) freely pick nodes already at or near the intended hub, so at small
`maxDegree` targets a *different*, unintended node could exceed it by chance (measured: a target of
10 produced an observed maximum of 17, on an unrelated node). Fixed by capping every non-hub node's
degree at `maxDegree − 1` during the filler pass, so the designated hub is provably the fixture's
unique maximum-degree node. `nonHubMaxDegree` is reported at every sample point specifically so
this property is checkable rather than asserted (see the per-axis tables below; `fillerShortfall`
reports whether the cap ever prevented the filler from reaching its own target — `false` at every
sampled point in this run).

### 2.3 The rendering harness — d3-force + PixiJS, the decided architecture

Also self-built, also throwaway, at the same path: `harness-src.mjs` (bundled by `esbuild` into
`bundle.js`, loaded by a bare `harness.html`), driven by `driver.mjs` through Playwright. **No
product code is depended on** — feature-007's loader and feature-008's canvas do not exist yet
(both are `Pending` elsewhere in this delivery), and D3 requires the fixture and harness to be
self-built regardless.

- **Physics: `d3-force` 3.0.0** (`forceSimulation`, `forceLink`, `forceManyBody`, `forceCenter`,
  `forceCollide`), `alphaDecay(0)` so the simulation never settles — FR-2's default
  continuously-simulating path — and `.stop()` immediately after construction so the harness
  drives every tick explicitly and can attribute its time exactly.
- **Drawing: PixiJS 8.14.0**, WebGL preference, one `Application` per built scene. Node geometry
  (a shape per `Kind`: circle, square, triangle or diamond, coloured per `Kind`) is built **once**
  per node and only repositioned per frame; edge geometry is rebuilt every frame because both
  endpoints move under continuous simulation. This split matters for reading the tick/draw
  attribution below: node draw cost is architecturally cheap by construction (a position write on
  pre-built geometry), so the draw term's growth is attributable to **edges**, not nodes, unless
  stated otherwise.
- **Instrumented in the page**, exactly as D4b's point 2 requires for a continuously-simulating
  surface: `performance.now()` brackets the `simulation.tick()` call and the draw-plus-`app.render()`
  call separately, every frame, so "tick" and "draw" are two numbers per frame, not one inferred
  split.
- **Bundled by `esbuild` 0.24.0** (a dev-only bundling tool; not shipped, not a runtime dependency
  of anything this task produces).
- **Browser: Playwright 1.61.1**, `chromium.launch({ headless: true, args: ['--no-sandbox',
  '--disable-setuid-sandbox'] })` — **the identical launch configuration Stage 1 verified against
  `validate-visuals.mjs`**, so this task's numbers are attributable to the same renderer Stage 1
  already characterised.

### 2.4 Measurement conditions, stated once because every table below depends on them

```
Renderer identity (this run, quoted verbatim from the page):
  vendor   : "Google Inc. (Google)"
  renderer : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"
  version  : "WebGL 2.0 (OpenGL ES 3.0 Chromium)"
```

This is the **same software rasteriser** Stage 1 identified (§ 2.2 and § 4 of the Stage 1 report).
Every frame time below is therefore a **CPU-rasterised** time, and D4b's headless-conservatism
question is addressed directly at § 8 rather than assumed.

Node `v22.14.0` (>= 20, C-5's floor). Canvas `1200 × 900` px, `devicePixelRatio` unset (Node-side
Playwright default). Warm-up 30 frames, sample window 150 frames, threshold 33.33 ms/frame (30
fps). Every number below is a **runtime output** of `.aid/.temp/graph-stage2a-harness/driver.mjs`,
`driver-conservatism.mjs` or `driver-extras.mjs`, run 2026-08-05; the full per-sample distributions
(not only median/p95) are in that directory's `results.json`, `conservatism-results.json` and
`extras-results.json`, which are not committed (§ 9).

**The baseline every axis holds the other four at, stated once:** `nodeCount = 800`,
`meanDegree = 4`, `maxDegree = 60`, `categoryCount = 14`, no hover, no filter. Two axes deviate
from this baseline for a stated, principled reason (the degree-cap headroom the fixed-in-§2.2
generator needs), and each says so at its own section.

---

## 3. Axis 1 — node count (D2b axis 1)

Varied: `nodeCount`. Held at baseline: `meanDegree = 4`, `maxDegree = 60`, `categoryCount = 14`.

| `nodeCount` (target) | actual nodes | actual edges | tick median / p95 (ms) | draw median / p95 (ms) | **total median / p95 (ms)** | clears 30 fps at p95, *at this synthetic point* |
|---|---|---|---|---|---|---|
| 200  | 200  | 398  | 0.7 / 1.5   | 2.6 / 6.2     | **3.3 / 7.5**     | yes |
| 500  | 500  | 950  | 2.5 / 6.1   | 9.1 / 22.2    | **11.5 / 27.1**   | yes |
| 1000 | 1000 | 1870 | 7.7 / 16.2  | 32.6 / 50.4   | **41.15 / 62.4**  | no |
| 2000 | 2000 | 3710 | 20.0 / 33.8 | 95.6 / 133.6  | **115.4 / 165.5** | no |
| 4000 | 4000 | 7390 | 44.05 / 78.2| 322.15 / 474.9| **371.6 / 551.7** | no |

**Observed shape: super-linear.** Each doubling of node count (which, at fixed mean degree, also
roughly doubles edge count) more than triples total median frame time in three of the four
doublings sampled (500→1000: ×3.58; 1000→2000: ×2.80; 2000→4000: ×3.22). Draw dominates total at
every point and grows faster than edge count alone would predict (contrast § 4, where edge count is
varied **alone** and total grows only about ×2 per doubling of edges). This document does not
isolate *why* — a profiler run would be needed and is out of this task's scope — and states the
shape as measured, not as diagnosed. A plausible contributor, named without being asserted as the
cause: the retained-object count (nodes **and** edges, both as persistent PixiJS `Graphics`
objects) grows with node count in a way it does not on the edge-count axis, so garbage-collection
and scene-graph traversal overhead are candidates the axis-2 comparison cannot rule out.

**Verdict (measurand 1, layout tick; measurand 2, node draw across `Kind`):** the layout term
(`tick`) stays a minority contributor at every sampled point (12–19 % of total at the low end,
rising to about 15 % at 4000 nodes) — **this measurement does not reproduce the superseded record's
"layout dominates, drawing is nearly free" finding**; in this implementation, drawing dominates at
every node count sampled. Node draw itself (position-only updates on pre-built per-`Kind` geometry)
is architecturally cheap; the draw term's growth is attributable to edge redraw (§ 4) and to
whatever compounds when node and edge totals grow together (this paragraph's first point).

---

## 4. Axis 2 — edge count (D2b axis 2)

Varied: `meanDegree` (the edge-count lever, independent of node count per D2b's own framing). Held
at baseline: `nodeCount = 800`, `categoryCount = 14`. **`maxDegree` raised to 100** for this axis
only (baseline is 60): at `meanDegree = 16` the degree-cap fix of § 2.2 needs headroom above the
mean to avoid `fillerShortfall`; 100 clears it with margin at every sampled point (`fillerShortfall:
false` throughout — checked, not assumed).

| `meanDegree` (target) | actual edges | actual nodes | tick median / p95 (ms) | draw median / p95 (ms) | **total median / p95 (ms)** | clears 30 fps at p95 |
|---|---|---|---|---|---|---|
| 1  | 418  | 800 | 4.9 / 7.3  | 7.4 / 10.2    | **12.2 / 16.7**  | yes |
| 2  | 786  | 800 | 4.7 / 7.1  | 14.35 / 20.4  | **19.25 / 24.7** | yes |
| 4  | 1522 | 800 | 5.4 / 8.0  | 30.8 / 43.7   | **36.3 / 50.2**  | no |
| 8  | 2994 | 800 | 7.75 / 15.7| 61.45 / 93.3  | **68.85 / 101.6**| no |
| 16 | 5938 | 800 | 7.2 / 13.7 | 130.05 / 219.7| **138.7 / 229.8**| no |

**Observed shape: approximately linear in edge count**, holding node count fixed. Each ~doubling
of edge count (786→1522, ×1.94; 1522→2994, ×1.97; 2994→5938, ×1.98) yields total-median growth of
×1.89, ×1.90 and ×2.01 respectively — within noise of proportional. The layout term (`tick`) stays
essentially flat (4.7–7.75 ms across a 14× edge-count range); the draw term tracks edge count almost
exactly. This is consistent with per-edge redraw (clear, path segmentation, stroke, and an
arrowhead poly for asymmetric edges) being the dominant, near-linear cost driver at this scale, and
it is the comparison that makes § 3's super-linear finding notable rather than a restatement of the
same fact: growing edges **alone** costs roughly linearly; growing nodes and edges **together**
costs super-linearly.

---

## 5. Axis 3 — maximum degree (D2b axis 3)

Varied: `maxDegree` (the hub's own degree). Held at baseline: `nodeCount = 800`,
`categoryCount = 14`. **`meanDegree` lowered to 2** for this axis only (baseline is 4): the
degree-cap fix needs the *base* population's degree to stay comfortably below even the smallest
sampled `maxDegree` (15), and `meanDegree = 4` would leave too little headroom at that end.

Two sub-conditions on the **same fixtures**, so the hub's own hover premium is isolable: hovering
the hub continuously throughout the sampled window, versus no hover (steady state).

**Hub hovered (labels shown = the hub's own degree, i.e. the swept value):**

| `maxDegree` (target = hub degree) | actual edges | non-hub max degree | tick median / p95 | draw median / p95 | **total median / p95** | clears 30 fps |
|---|---|---|---|---|---|---|
| 15  | 744 | 10 | 4.5 / 6.9  | 14.05 / 20.2 | **18.8 / 24.7**  | yes |
| 30  | 751 | 10 | 5.15 / 7.6 | 16.05 / 20.1 | **21.3 / 26.8**  | yes |
| 60  | 766 | 11 | 5.25 / 7.4 | 15.9 / 20.0  | **21.4 / 25.8**  | yes |
| 120 | 796 | 11 | 5.1 / 7.7  | 15.3 / 20.0  | **20.8 / 26.5**  | yes |
| 240 | 856 | 11 | 5.3 / 7.5  | 16.9 / 22.0  | **22.25 / 27.4** | yes |

**Steady state, no hover, same five fixtures:**

| `maxDegree` (target) | tick median / p95 | draw median / p95 | **total median / p95** | clears 30 fps |
|---|---|---|---|---|
| 15  | 4.95 / 7.1 | 15.05 / 21.5 | **19.95 / 27.4** | yes |
| 30  | 5.35 / 8.8 | 15.95 / 23.8 | **21.8 / 30.9**  | yes |
| 60  | 5.1 / 7.6  | 15.3 / 19.9  | **20.5 / 25.8**  | yes |
| 120 | 5.4 / 8.3  | 17.3 / 22.9  | **22.7 / 29.2**  | yes |
| 240 | 5.5 / 7.7  | 17.05 / 21.2 | **22.7 / 27.1**  | yes |

**Observed shape: flat, over a 16× range of hub degree (15 → 240).** Both sub-conditions vary only
within about ±2 ms of a ~20–22 ms median — no discernible monotonic trend either up or down, at
either sub-condition, distinguishable from run-to-run noise at this sample size. This holds
**specifically because the generator conserves the overall edge budget** while concentrating
degree into the hub (actual edge count only creeps from 744 to 856, +15 %, across the whole sweep —
see § 2.2): axis 2's own finding (draw cost tracks edge count near-linearly) predicts correctly that
a nearly-constant edge total should yield a nearly-constant frame time, regardless of how that
total is *distributed* across nodes. **This is a scoped finding, not a general one**: it says
maximum degree does not, by itself, drive frame time when the edge total is held fixed; it does not
say a hub-heavy topology is free in general, since a hub that is a genuine net *addition* of edges
(rather than a redistribution) would fall under § 4's near-linear edge-count sensitivity instead.

**Hover premium at the hub: not distinguishable from noise at these label counts.** Comparing the
two tables row by row (15: 18.8 vs 19.95; 30: 21.3 vs 21.8; 60: 21.4 vs 20.5; 120: 20.8 vs 22.7;
240: 22.25 vs 22.7), the hovered condition is sometimes *below* the steady condition — there is no
consistent direction, let alone a consistent premium. This anticipates § 7's more direct probe of
the hover-label axis specifically.

---

## 6. Axis 4 — category count (D2b axis 4, including D4a's fourteen-category case)

Varied: `categoryCount` (1, 2, 4, 8, 14 — **14 is D4a's fixture, feature-001 Open Item 11's
routed case**). Held at baseline: `nodeCount = 800`, `meanDegree = 4`, `maxDegree = 60`.

| `categoryCount` | categories used | edges (constant) | tick median / p95 | draw median / p95 | **total median / p95** | clears 30 fps |
|---|---|---|---|---|---|---|
| 1  | 1  | 1502 | 4.4 / 6.3  | 13.2 / 16.6  | **18.0 / 21.5**  | yes |
| 2  | 2  | 1502 | 4.25 / 6.5 | 15.1 / 21.2  | **19.3 / 27.2**  | yes |
| 4  | 4  | 1502 | 5.45 / 8.2 | 32.9 / 47.6  | **38.4 / 54.6**  | no |
| 8  | 8  | 1502 | 5.4 / 7.0  | 31.85 / 40.9 | **37.6 / 46.6**  | no |
| **14** | **14** | 1502 | 5.35 / 6.5 | 30.7 / 41.3  | **36.05 / 46.9** | **no** |

**Observed shape: a step, not a ramp.** `categoryCount` 1→2 costs almost nothing (18.0→19.3 ms);
2→4 nearly doubles the total (19.3→38.4 ms); 4→8→14 is flat within noise (38.4→37.6→36.05 ms).

**Root cause, read from the harness's own source rather than argued abstractly (the feasibility
verdict D4 measurand 4 asks for):** the harness assigns one of four line-style patterns to each
category by `categoryIndex % 4` — `solid`, `dashed`, `dotted`, `dash-dot` — so the third and fourth
patterns (dotted, dash-dot) enter the mix only once `categoryCount` reaches 4. **PixiJS 8.14.0's
core `Graphics` API has no native dashed-stroke primitive** (verified against its own surface while
writing the harness: `.stroke()` takes no `dash` option); a non-solid line style is drawn by
hand-segmenting the edge into many short `moveTo`/`lineTo` subpaths before one `.stroke()` call.
`dotted`'s pattern (a 1.6 px dash, a 4 px gap) is the densest of the four and is the one newly
introduced at `categoryCount = 4` — which is exactly where the jump appears. **Verdict: four
distinguishable line styles are feasible in this architecture, but not free** — dotted and
dash-dot cost roughly double the solid/dashed draw budget at this edge count (1502), and the cost
is driven by segment density, not by the category count itself: once all four styles are in the mix
(`categoryCount >= 4`), adding more categories (8, 14) adds no further measurable cost, because
they reuse the same four patterns.

**D4a's own verdict, stated at its named point:** at the full fourteen-category fixture, median
total frame time is 36.05 ms and p95 is 46.9 ms — **both above the 33.33 ms/frame (30 fps) budget,
at this synthetic point**, which is one baseline fixture (800 nodes, mean degree 4, hub 60), not
the derived bench. D4a's own text is explicit that whether a real bench even carries all fourteen
categories is not this task's to assert (feature-005's D8 producer map; feature-001's W3
reachability) — this verdict is about the *cost of the encoding*, which is what task-003 owes.

### 6.1 Category-filtering transition and post-filter steady state (D4a's other half)

Two further, related measurements on the fourteen-category fixture:

- **Filtering transition**: starting all fourteen categories visible, the filter is set to a
  single category at sampled frame 60 of 150. The **specific transition frame** measured
  total = 8.4 ms (tick 4.5, draw 3.9). This is a **single-frame sample (n = 1)**, reported as such —
  weaker evidence than the medians above, and stated once so it is not mistaken for a distribution.
- **Post-filter steady state** (a single category visible, sampled for a full 150-frame window on
  a fresh scene): total median 6.3 ms, p95 9.4 ms.

**Finding, stated against the SPEC's own working hypothesis.** D4's own text calls the transition
"a spike, not a steady-state cost" as something to be measured rather than assumed. In this
implementation — where filtering is a `.visible` flag flip on pre-existing `Graphics` objects, not
a removal/re-creation — **the transition frame (8.4 ms) is not a spike above the post-filter steady
state (6.3 ms median); it is within the same range**, and both are far below the pre-filter,
fourteen-category steady state (36.05 ms median). The one-pass visibility recomputation over 1502
edges is cheap relative to the per-frame draw cost it then avoids. This is evidence *against* a
transition spike **for this specific implementation strategy**; a strategy that destroyed and
rebuilt edge `Graphics` objects on every filter toggle could differ, and was not tested.

---

## 7. Axis 5 — concurrent hover-label count (D2b axis 5)

Varied: which of five purpose-built probe nodes is hovered, each wired to exactly *N* fresh leaf
nodes (`N` = 4, 8, 16, 32, 60) so the label count shown is controlled directly rather than inferred.
Held at baseline: `nodeCount = 800` (actual, with the five probes and their leaves added:
`925`), `meanDegree = 4`, `maxDegree = 60`, `categoryCount = 14`. A no-hover baseline on the **same**
augmented fixture isolates the hover premium.

| hovered probe, target label count | actual label count | tick median / p95 | draw median / p95 | **total median / p95** | clears 30 fps |
|---|---|---|---|---|---|
| (no hover, baseline)         | 0  | —          | —            | **46.1 / 56.7** *(one outlier at 744.6 ms, reported not discarded — see note)* | no |
| probe, target 4  | 4  | 6.25 / — | 32.25 / — | **39.05 / 50.7** | no |
| probe, target 8  | 8  | 6.7 / —  | 33.3 / —  | **40.0 / 48.2**  | no |
| probe, target 16 | 16 | 6.7 / —  | 35.75 / — | **42.6 / 57.2**  | no |
| probe, target 32 | 32 | 6.6 / —  | 34.0 / —  | **40.85 / 51.0** | no |
| probe, target 60 | 60 | 7.7 / —  | 38.95 / — | **46.2 / 64.1**  | no |

*(tick/draw p95 omitted from the table for space; the full distributions are in `results.json`.)*

**Observed shape: flat, within a roughly 7 ms band, and not distinguishable from the no-hover
baseline.** Total medians range 39.05–46.2 ms across a 15× range of concurrent label count (4→60),
and the no-hover baseline (46.1 ms) sits **inside** that same band rather than clearly below it.
**Verdict (measurand 5, hover labels — "the measurement the prior work never took at all"):**
instantiating up to 60 concurrent `Text` objects for a hovered hub's incident edges is **feasible**
and, on this 925-node / 1622-edge fixture, its cost is **not measurably distinguishable from the
base graph's own edge-redraw cost**. This is a scoped finding: it does not claim label cost is zero
in an absolute sense, only that it is small relative to a realistic edge-count baseline; a much
sparser fixture, where edge-redraw cost is itself small, was not tested and could show a clearer
premium.

**The no-hover baseline's one outlier (744.6 ms, against a median of 46.1 ms)** is reported rather
than discarded, per this document's own attribution discipline (§ 10): it is a real sampled value
from `runTimedWindow`'s 150-frame array, consistent with a single garbage-collection pause or
OS/Playwright scheduling jitter on a shared development machine, not a defect found in the harness
code. It is exactly why the predicate (§ 2.1) reports **median and p95**, not a mean, which a single
such outlier would distort disproportionately (the reported mean for that row, 51.15 ms in
`results.json`, is visibly pulled up by it; the median is not).

### 7.1 Arrowhead marginal cost (D4 measurand 3), isolated

A/B measurement on the 800-node baseline fixture (actual 1502 edges): the same edges, once left as
generated (asymmetric edges draw an arrowhead, symmetric ones do not — the encoding D4 measurand 3
asks to be verified) and once with every edge forced `symmetric: true` so no arrowhead branch
executes, everything else in the draw path identical.

| Condition | draw median (ms) | total median (ms) |
|---|---|---|
| With arrowheads (as generated) | 28.5 | 34.5 |
| Without arrowheads (all edges forced symmetric) | 27.3 | 34.2 |

**Verdict:** arrowhead geometry (a per-edge triangle, computed from the edge's direction vector)
costs about 1.2 ms of draw time, roughly 4 % of the draw budget, at 1502 edges. Feasible, cheap, not
free.

### 7.2 Node draw across every `Kind` value (D4 measurand 2), and visual confirmation

All seven `Kind` values (`document`, `concept`, `fact`, `section`, `source-artifact`, `image`,
`web-page`) are given a distinct shape (circle, square, triangle, diamond — cycled) and colour, and
every fixture in every axis above instantiates all seven (§ 2.2's kind-population weights). Per §
2.3, node draw cost is a per-frame **position write** on geometry built once at scene construction,
not a per-frame redraw, so its cost does not appear as a separate line in the tables above — it is
folded into the (small) fraction of `draw` not attributable to edges. A screenshot taken during
harness construction (a 46-node fixture, visual-inspection use only, **not committed** — see § 9)
confirms, by direct observation rather than by source-reading alone: shapes render distinctly per
kind, arrowheads are visible on directed edges, dashed/dotted line styles are visibly distinct from
solid, and a hovered probe's incident-edge relation labels (`has-revision`) render as text at the
edge midpoints. This mirrors Stage 1's own discipline of confirming a claim by capture rather than
by argument alone.

---

## 8. The headless-conservatism comparison — D4b point 3, AC-S7

D4b's own text: *"the report must argue rather than assert"* whether a headless (software-
rasterised) frame time is conservative relative to a hardware-rendered one, because Stage 1 (§ 4)
established that a hardware-backed context is reachable on this host with one added launch flag.
One comparison, as D4b specifies: the same fixture, at the same points, under the **reused** launch
configuration (no GPU flag, verified identical to `validate-visuals.mjs`) and under the
**hardware-forced** configuration (`--use-angle=d3d11`, Stage 1 § 4's path), both renderer identity
strings recorded.

```
software : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"
hardware : "ANGLE (NVIDIA, NVIDIA RTX 2000 Ada Generation Laptop GPU (0x000028B8) Direct3D11 vs_5_0 ps_5_0, D3D11)"
```

| nodeCount (actual) | edges (actual) | software total median (ms) | hardware total median (ms) | hardware faster by |
|---|---|---|---|---|
| 500  | 950  | 20.15  | 13.25  | 34.3 % |
| 1000 | 1870 | 47.65  | 44.5   | 6.6 %  |
| 2000 | 3710 | 120.35 | 118.55 | 1.5 %  |

**Finding: hardware is faster at every sampled point in this comparison — confirmed, not
assumed — so a headless PASS at these points is conservative evidence toward a hardware PASS, in
the direction D4b hypothesises.** But the margin **shrinks sharply with scale**: from a 34 % gap at
500 nodes to under 2 % at 2000. This is consistent with § 3's own reading — as the fixture grows,
more of the total cost sits in CPU-side JavaScript work (Graphics geometry construction, d3-force's
tick, garbage collection) that both launch configurations share equally, rather than in the
GPU-bound rasterisation step that differs between them. **The practical consequence for AC-6a**,
stated as D4b's own text asks it to be: a headless PASS comfortably below the 30 fps threshold *at
small scale* is strong conservative evidence; a headless result *close to the threshold at large
scale* should not be read as comfortably conservative, because the margin this comparison measured
at similar scale is itself small. This is evidence for `task-010` to carry forward when it evaluates
AC-6a at the derived bench, not a resolution of the question — three points is not enough to fit a
trend, and this comparison's own honest limit is that it was run at only three of the (otherwise
five-point) node-count axis's samples, for time.

---

## 9. Reproduction, and what was installed — mirrors Stage 1's own disclosure

**Harness location:** `.aid/.temp/graph-stage2a-harness/` — gitignored (`.gitignore:69`),
**throwaway by construction**, and not committed. Files: `generate-fixture.mjs` (D3),
`harness-src.mjs` (the d3-force + PixiJS scene, bundled by `esbuild` into `bundle.js`),
`harness.html`, `driver.mjs` (the five-axis sweep, § 3–7), `driver-conservatism.mjs` (§ 8),
`driver-extras.mjs` (§ 7.1's arrowhead A/B and § 7.2's screenshot), `smoke.mjs` (a pre-sweep sanity
check), and their outputs `results.json`, `conservatism-results.json`, `extras-results.json`,
`evidence.png`. **No product code was written and nothing from this harness ships** — per
`task-type-rules.md` § RESEARCH and this task's own AC ("the harness is declared throwaway and no
part of it is added to `canonical/` or `tests/`").

**Installed into the scratch directory only, and disclosed:**

| What | Where | Command | Tracked files touched? |
|---|---|---|---|
| `d3-force@3.0.0`, `pixi.js@8.14.0`, `esbuild@0.24.0`, `playwright@1.61.1` | `.aid/.temp/graph-stage2a-harness/node_modules/` | `npm install --no-save d3-force@3.0.0 pixi.js@8.14.0 esbuild@0.24.0 playwright@1.61.1` | No — gitignored path, `--no-save`, no `package.json`/lockfile committed |
| Chromium (cached from Stage 1) | `%LOCALAPPDATA%\ms-playwright\` — outside the repository | `npx playwright install chromium` — cache hit, no download | No |

**Node.js floor (C-5) honoured**: this run used `v22.14.0` (>= 20). **Browser-absence degradation
verified, not merely coded**: `node_modules/playwright` was renamed away and `driver.mjs` was
re-run; it printed an actionable message (Node version check, the exact re-install command, and the
reason) and exited `0` rather than throwing an unhandled stack trace — literal transcript:

```
SKIP -- Playwright is not installed in this scratch environment.
  import('playwright') failed with: ERR_MODULE_NOT_FOUND
  This harness cannot run without it. To install (throwaway, this scratch dir only):
    cd .aid/.temp/graph-stage2a-harness && npm install --no-save playwright@1.61.1 && npx playwright install chromium
  Node.js floor (C-5): >= 20. This machine reports v22.14.0 -- meets the floor.
EXIT_CODE=0
```

**Cleanup:** the scratch directory is left in place only for the duration of this work's review
(gitignored; never staged). Per this project's transient-work-folder rule and this task's own AC,
it is not a permanent artifact and nothing permanent may cite it as a source.

---

## 10. Attribution of every figure — AC-S6

| Figure class | Form | Source |
|---|---|---|
| Every median/p95/tick/draw/total number in § 3–7; the renderer identity string in § 2.4; every `actual` node/edge/degree/category count | Quoted runtime output | `.aid/.temp/graph-stage2a-harness/driver.mjs`, run 2026-08-05, full distributions in `results.json` |
| § 8's software/hardware comparison and both renderer strings | Quoted runtime output | `driver-conservatism.mjs`, run 2026-08-05, `conservatism-results.json` |
| § 7.1's arrowhead A/B numbers | Quoted runtime output | `driver-extras.mjs`, run 2026-08-05, `extras-results.json` |
| § 7.2's visual observations | Direct observation of a captured screenshot | `driver-extras.mjs`'s `evidence.png`, captured 2026-08-05, not committed |
| The relation-vocabulary tuples the fixture generator uses; the 14-category count; the ten-column contract; the closed `Kind` enum | Verified on-disk fact with command and read date | `canonical/aid/templates/graph/relation-vocabulary.yml` and `relationship-schema.yml`, read 2026-08-05 |
| "PixiJS 8.14.0's core `Graphics` has no native dashed-stroke primitive" | Verified against the installed package's own type/API surface while writing `harness-src.mjs` | `.aid/.temp/graph-stage2a-harness/node_modules/pixi.js`, version pinned at install (§ 9) |
| The launch configuration matching `validate-visuals.mjs` | Verified on-disk fact, re-quoted from Stage 1 | Stage 1 report § 2.4, itself sourced to `canonical/aid/scripts/summarize/validate-visuals.mjs` lines 185–188, read 2026-08-05 by that report |
| The generator defect (§ 2.2) and its fix | Quoted runtime output, before/after | Ad hoc `node -e` sanity checks against `generate-fixture.mjs`, run 2026-08-05, quoted inline at § 2.2 |
| Everything named in § 1's "explicitly out of scope" table | Explicitly labelled as owed elsewhere, not measured here | Named with the task or stage that owes it |

**No figure in this document is carried over from the superseded record**, and no figure states a
bench size (AC-S3) — every count above is a labelled synthetic fixture parameter or an actual value
the generator reports for that same synthetic fixture.

---

## 11. Recommendation — how `task-010` (Stage 2b) should read this surface

Stated as D2b's own closing line requires: what the surface can and cannot tell Stage 2b.

1. **Do not read any single point above as a ceiling or a bench figure.** Every point is a
   synthetic fixture at a stated, arbitrary baseline. `task-010` must re-evaluate NFR-7's floor and
   NFR-8's ceiling **at the derived bench's own actual node/edge/degree/category figures**, using
   this surface only as a *shape* — which axis dominates, and by how much — not as a lookup table
   keyed on the derived bench's numbers landing near one of the five points sampled per axis.
2. **Layout (`tick`) is a minor term at every scale and axis sampled here.** If the derived bench's
   own layout/draw split differs sharply from that (i.e., if layout turns out to dominate at the
   bench's real topology), that is itself a finding worth flagging, since it would depart from
   every measurement in this document.
3. **Edge count is close to the primary cost driver** measured here, essentially linearly (§ 4);
   node count compounds super-linearly with it (§ 3) for a reason this document does not isolate.
   `task-010` should expect the derived bench's **edge count**, not its node count alone, to be the
   more informative predictor, and should report both regardless (NFR-8's own comparand question,
   D5, is explicitly not resolved by this document).
4. **Line style cost is concentrated in the dotted/dash-dot patterns, not in category count as
   such** (§ 6). If the derived bench's real category distribution under-represents categories 3–4
   in the harness's cycling order (an artefact of this harness's own arbitrary category→line-style
   assignment, not a property of the real vocabulary), `task-010` should not assume the same
   line-style cost profile without checking which patterns the real palette actually assigns
   (feature-007/008's, per D8's routing) — this document's mapping is a measurement convenience,
   not a design recommendation.
5. **The headless-conservatism margin narrows with scale** (§ 8). If the derived bench is large
   enough to sit in the range where this document measured under 2 % separation, `task-010` should
   treat a headless result close to the 30 fps line as inconclusive rather than comfortably
   conservative, per D4b's own instruction, and should consider running its own conservatism check
   at the bench's actual scale rather than extrapolating this document's three points.
6. **Concurrent hover-label cost was not distinguishable from noise up to 60 labels on a
   ~1600-edge fixture** (§ 7). If the derived bench's maximum degree is materially larger than 60,
   `task-010` inherits an open question this document does not close: whether that flatness
   continues, since the largest label count tested here is well below many plausible KB hub degrees.

---

## 12. What was not measured, restated plainly (per this task's own instruction to be specific)

- **Node drag** (D4 measurand 6; NFR-7's second AC-6a window): not attempted. Not one of D2b's five
  axes; owned by `task-010`, which needs a drive mechanism this harness does not build (a simulated
  pointer drag that re-heats the simulation and adds pointer-handling cost on top of it).
- **Reduced-motion settled render** (D4 measurand 8): not attempted. Not one of D2b's five axes.
- **Vendored-bundle token / render-transform checks** (D4 measurand 9), **payload, licence,
  attribution, the update mechanism** (D6, D7): not attempted. Stage 3, `task-002`'s.
- **The derived bench, NFR-7's verdict at it, NFR-8's ceiling and its degree sensitivity, the
  comparand recommendation** (D2, D5): not attempted. Stage 2b, `task-010`'s, gated on
  delivery-002.
- **A CI-environment (ENV-1) or unprovisioned-browser (ENV-3) run of this harness**: not attempted.
  This task ran only on the ENV-2 equivalent (developer machine, Playwright provisioned, the same
  software rasteriser Stage 1 characterised). Stage 1 already covers the environment-generalisation
  risk and its remedy (its own § 2.6, § 5); this document does not re-run that analysis for the
  Stage 2a harness specifically, and a reader who needs Stage 2a numbers from CI's own hardware has
  no figure here to consult.
- **Root-causing the super-linear node-count growth** (§ 3): measured and reported as a shape,
  not diagnosed to a specific mechanism. Would need a profiler run, out of this task's scope.
- **A profiling breakdown of node-only versus edge-only draw cost**: § 3's reasoning that node draw
  is cheap rests on the architecture (position-only updates on pre-built geometry) and on the
  arrowhead/line-style isolation experiments (§ 6, § 7.1), not on a dedicated node-only run; no
  fixture with zero edges was measured.
