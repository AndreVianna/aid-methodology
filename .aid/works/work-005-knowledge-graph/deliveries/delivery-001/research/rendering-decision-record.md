# Rendering Decision Record (re-issued)
## Feature-002: Graph Rendering Research — Viability & Performance Validation

**Work:** work-005-knowledge-graph
**Delivery:** delivery-001, Task-011 (re-issue of the 2026-07-28 record against the amended SPEC)
**Date:** 2026-08-06
**Resolves:** STATE.md Q2 (closed by owner decision, Q9 — see Part 0) and feature-002's D10, the
decision record's required parts
**Specification authority:** `features/feature-002-graph-rendering-research/SPEC.md` (re-specified
2026-07-29, gated A+ 2026-07-30)

> **This document is a research artifact under a transient work folder.** Per `CLAUDE.md` §
> Tracking discipline and the SPEC's own § Layers & Components, no permanent artifact may cite
> this document or depend on its contents. The facts that must survive land in
> `technology-stack.md` and `infrastructure.md` at ship time (feature-013) and in the packaging
> wiring (feature-012); Part 15 below drafts that content without landing it.

---

## Part 0 — Why this record is re-issued, and what changed underneath it

**The 2026-07-28 record this document replaces resolved a question that no longer exists.** It
scored six renderer classes (SVG, DOM, Canvas, WebGL, Multi, Hand-rolled) against five packaging
shapes across twelve dimensions, including accessibility cost as a per-candidate axis, and
recommended a static SVG graph that settles once before first paint. On 2026-07-29 the owner
**decided** the renderer by fiat (STATE.md Q9): `d3-force` on the CPU for physics, PixiJS on WebGL
for drawing, two dimensions — the split Obsidian's graph view uses. The canvas is **visual-only**;
WCAG AA is carried by the accessible table view as the conforming alternate version (NFR-2), not by
a hand-built DOM proxy. FR-18 was rewritten the same day: the renderer question is closed, and what
remains is a **viability-and-performance validation** in a fixed three-stage order. The entire
comparison apparatus the 2026-07-28 record built is therefore answering a question FR-18 no longer
asks.

**The audit table below is the SPEC's own, carried forward rather than dropped**, so a reader who
has seen the earlier revision can see that its absence here is deliberate, not an omission
(feature-002 SPEC § "Requirements baseline for this section"):

| The previous revision relied on | Status now | Replaced by |
|---|---|---|
| "The option space is **unrestricted**" (FR-18, 2026-07-28) | **Void** | FR-18 as rewritten: the architecture is decided; the former option space is closed |
| Six renderer classes × five packaging shapes, scored | **Void** | Nothing. There is no comparison. The packaging shapes survive only as a description of what the *decided* architecture must be delivered as (Part 10) |
| Five hard screens (WCAG reachability, single data path, NFR-4–6 capability, four lenses, licence) | **Void as screens** | Screens exist to eliminate candidates. With one architecture they became obligations to verify, and reappear as measurands (Part 6) and Stage-3 findings (Parts 10–12) |
| "Accessibility cost" as a per-candidate dimension — whether the renderer yields accessibility-tree semantics or needs a hand-built proxy | **Void** | Q9: the canvas is visual-only; AA is met by the accessible table view; **no DOM proxy layer is built.** The proxy-line-count arithmetic that dominated the superseded record priced work this feature does not do |
| The scale-versus-accessibility tension | **Void** | Both poles it traded off between are gone: the renderer is chosen and the accessibility route is chosen |
| "Node counts are bounded to the hundreds (FR-22, FR-23, A-5)" | **Void** | A-5 is voided; FR-23's granularity is widened; NFR-7 states no count and NFR-8 makes the ceiling a measured output (Part 4, Part 9) |
| A **static** SVG graph settling once before first paint | **Superseded** | FR-2 and FR-18: continuous simulation is the default; NFR-4's settled render is the reduced-motion **fallback**, not the whole behaviour |
| Edge labels drawn every tick as the binding cost | **Superseded** | Persistent labels dropped (Q11); category carried by colour + line style; the name shown on hover or selection (Part 6, measurands 4–5) |
| A five-category vocabulary | **Void** | feature-001's re-specified SPEC states **fourteen** categories (Part 5, Part 6) |
| `validate-visuals.mjs` T2 failing by design for an SVG graph | **Conditional, and now a recorded no-op** | A `<canvas>` matches none of that script's three selectors (D1b). No carve-out fires |

**What this document is not.** It does not reopen the renderer comparison — Q9 decided, and the
SPEC's own validation boundary forbids re-scoring candidates. Reporting a measured failure with
evidence, which this document does in Part 4 and Part 6–9, is a different act from re-opening that
choice, and nothing below does the latter.

---

## Part 1 — Question and Scope (D10 part 1)

**The question, from FR-18 as rewritten:** can the decided architecture (`d3-force` + PixiJS/WebGL)
be validated by this project's own toolchain, and does it meet the requirements' own measured
floors and ceilings? Three stages, fixed order:

| Stage | Question | Task | Deliverable cited here |
|---|---|---|---|
| **1** | Can the Playwright toolchain FR-12 reuses validate a WebGL canvas at all, headless, with no GPU? | task-002 (D1) | `research/rendering-stage1-webgl-probe.md` |
| **2a** | How does frame time respond to node count, edge count, maximum degree, category count and hover-label count? | task-003 (D2b) | `research/rendering-stage2a-response-surface.md` |
| **2b** | Does the derived bench clear NFR-7's floor, and where is NFR-8's ceiling? | task-010 (D2, D5) | `research/rendering-stage2b-bench-and-verdicts.md` |
| **3** | What does the project take on — payload, licence, update? | task-002 (D6, D7) | `research/rendering-stage3-payload-licence-update.md` |

All three stage deliverables are complete. **This document discharges nothing itself** — every
measured claim below is attributed to the stage document that produced it, per this task's own
DETAIL: "every D10 required part is present and attributed to the stage that discharged it; nothing
is carried over from the superseded revision without being re-derived."

**Explicitly out of scope, per the SPEC's own § "The validation boundary":** choosing a renderer
(Q9 decided); building a degraded rendering mode (NFR-8: measure, document, warn — no adaptive
degradation anywhere, by design); pricing an accessibility proxy layer (there is none); authoring
the palette; writing product code or Knowledge Base content; deriving the bench by counting files;
stating a bench size as this feature's own assertion (AC-S3 — every count below is Stage 2b's
measured output, never a size feature-002 specifies).

---

## Part 2 — Stage 1: the WebGL-under-headless probe (D10 part 2, AC-S1)

*Source: `rendering-stage1-webgl-probe.md` §§ 2, 4.*

| Environment | L1 context | L2 readable pixels | L3 capturable pixels |
|---|---|---|---|
| ENV-1 — CI `visual-fidelity` runner (`ubuntu-24.04`) | NOT VERIFIED | NOT VERIFIED | NOT VERIFIED — unreachable from this host |
| **ENV-2 — developer machine, Playwright provisioned** (Windows 11) | **PASS** | **PASS** | **PASS**, with one synchronisation qualification (below) |
| ENV-3 — Playwright not provisioned | NOT DETERMINABLE (correctly — the pre-existing C-5 skip path, undisturbed) | NOT DETERMINABLE | NOT DETERMINABLE |

**Renderer identity, verbatim, recorded because a pass on a software rasteriser and a pass on a
discrete GPU are different facts:**

```
UNMASKED_VENDOR_WEBGL    : "Google Inc. (Google)"
UNMASKED_RENDERER_WEBGL  : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"
```

**Every ENV-2 pass was produced by a CPU software rasteriser (SwiftShader), not a GPU**, under the
unmodified launch configuration `validate-visuals.mjs` uses (`headless: true`, no GPU flag). A
hardware-backed context (`ANGLE (NVIDIA, NVIDIA RTX 2000 Ada Generation Laptop GPU …)`) is reachable
on this host with one added launch flag (`--use-angle=d3d11`), which is the comparand Part 7 below
uses.

**The one loud qualification:** `canvas.toDataURL()` called *outside* the drawing frame on a
default-attribute WebGL canvas returns a fully transparent buffer (`preserveDrawingBuffer: false`
semantics), for both a single-draw and a continuously-simulating canvas. This is not an L3 negative
— the Playwright element screenshot (the route FR-12 actually reuses) passes on default-attribute
canvases regardless, and the same canvas passes `toDataURL()` when captured inside the drawing
frame. It is a synchronisation constraint for feature-008's draw loop (Stage 1 § 6.2), not a
renderer finding.

**ENV-1 is an honest gap, not a result** — not reachable from this host, and a live repo defect
(`.github/workflows/test.yml:105` points the `visual-fidelity` job at `.aid/dashboard/kb.html`,
which does not exist; the job has taken its SKIP branch on every run since commit `5f2b3682`,
2026-06-26) means the gate the ENV-1 verdict would protect does not currently execute at all. Both
are recorded with owners in the Stage 1 report §§ 5, 10 and are not fixed by this document.

---

## Part 3 — Stage 1 escalation (D10 part 3, AC-S2)

*Source: `rendering-stage1-webgl-probe.md` § 6.*

All three levels PASS on ENV-2 and no level is negative anywhere, so D1a's escalation rows for a
negative verdict (rows 2–4: capture-blank, context-produces-nothing, no-context-at-all) **do not
fire**, and nothing is handed to the work owner for a renderer-changing decision. The applicable row
is the first: *"L1 ✓ L2 ✓ L3 ✓ — record the renderer identity string as evidence and move to Stage
2."* Discharged.

**The one recommendation Stage 1 does owe on evidence, stated even though the escalation did not
fire:** if feature-008's drawing code ever needs `canvas.toDataURL()` (export, fixture, test), the
call must be made inside the frame that drew, or the context must request
`preserveDrawingBuffer: true`. This is a constraint on feature-008's seam, not a request to change
the decided architecture, and feature-011 is asked for nothing arising from Stage 1.

---

## Part 4 — The bench derivation procedure and derived figures (D10 part 4, AC-S3, AC-S6)

*Source: `rendering-stage2b-bench-and-verdicts.md` § 2.*

**The bench is a procedure (SPEC § D2), not a stated figure, and every number below is Stage 2b's
measured output of running that procedure over this repository's own producer streams — never an
assertion of this feature's own.**

| Term | Producer | Measured value |
|---|---|---|
| 1 — KB-side node set | feature-005's Pass 1a, after Q13's concept merge | **479** (`document` 21, `section` 340, `fact` 86, `concept` 32) |
| 2 — source-artifact / image / web-page set | feature-004's enumerator | **1,130** (`source-artifact` 1,126, `image` 4, `web-page` 0) |
| **Total nodes** | — | **1,609** |
| 3 — edge set and degree distribution | feature-005 Pass 1/Pass 2, Q13's merge | **6,171** unique edges (deduplicated union — see limitation below); median degree 6 (connected nodes); 95th-percentile degree 42; **maximum degree 329** (`kb:concept:canonical`); 962 of 1,609 nodes touched by ≥1 edge (59.8 %); 647 isolated (40.2 %, kept deliberately per D3) |

**Categories actually exercised:** 7 of the vocabulary's 14 categories appear in this bench's real
edge set (`structure`, `documentation`, `evidence`, `dependency`, `navigation`, `definition`,
`representation`) — a finding about this repository's own graph shape, not a defect in the
derivation.

**The edge-set term's own honest limitation, stated rather than smoothed over.** The 6,171-edge
figure is a **measured-but-provisional** union of three classification-pass row files
(`rows-pass1a.tsv`, `rows-pass1b.tsv`, `rows-class0.tsv`) reconstructed from a stopped-mid-run
pipeline, not the output of a finished `relationships.md` produced by feature-004/feature-005's
shipped code — that code ships in delivery-002. Two of the three source files disagree on which of
two competing classification passes is authoritative for the same edges, so the union is a
best-effort deduplicated superset: it is very unlikely to undercount real edges, and may modestly
overcount. **This is flagged, not hidden**, and it is the reason the verdict fixture in Part 7 below
converges to fewer edges (3,854) than this term states (6,171) — making that verdict conservative in
the "understates the real cost" direction, per Stage 2b § 3.

**AC-S3 compliance, stated explicitly.** No node count, edge count or degree figure in this Part is
an assertion feature-002 makes about a bench size. Every figure is Stage 2b's runtime output of
running D2's named procedure against this repository's own on-disk producer streams, cited with its
command (Stage 2b §§ 2, 8), and it should be re-derived once delivery-002 ships a finished
`relationships.md` (Stage 2b § 7, item 5).

---

## Part 5 — The response surface (D10 part 5, AC-S4)

*Source: `rendering-stage2a-response-surface.md` §§ 3–8, all figures runtime outputs of a synthetic
self-built fixture generator, never this repository's own graph.*

| D2b axis | Range sampled | Observed shape | Verdict |
|---|---|---|---|
| 1 — node count | 200 → 4,000 (mean degree, max degree held fixed) | **Super-linear.** Total median frame time: 3.3 ms → 371.6 ms. Each doubling more than triples total time in three of four steps sampled | Draw dominates total at every point (contrast the superseded record's "layout dominates" finding, not reproduced here) |
| 2 — edge count | mean degree 1 → 16 (node count held fixed) | **Approximately linear.** Doubling edge count yields ×1.89–2.01 total-time growth | Edge redraw is the near-linear cost driver; nodes-and-edges growing **together** compounds super-linearly, edges alone do not |
| 3 — maximum degree | hub degree 15 → 240 (edge budget held fixed) | **Flat**, ±2 ms across a 16× range | **Conditioned**: this holds *because* the generator conserves the overall edge budget while concentrating degree into the hub. A hub that is a genuine net *addition* of edges falls under axis 2's sensitivity instead |
| 4 — category count | 1, 2, 4, 8, 14 | **A step, not a ramp.** 1→2 costs almost nothing; 2→4 nearly doubles total time; 4→8→14 flat | **Root cause, read from source**: PixiJS 8.14.0's core `Graphics` API has no native dashed-stroke primitive. `dotted`/`dash-dot` line styles (the 3rd/4th of four patterns) enter the mix only at `categoryCount ≥ 4`, and cost roughly double the solid/dashed budget — a step function of style count, not category count |
| 5 — concurrent hover-label count | 4 → 60 labels | **Flat**, within a ~7 ms band, not distinguishable from the no-hover baseline | Feasible; on this ~1,600-edge fixture its cost is not measurably distinguishable from the base edge-redraw cost. Scoped: a much sparser fixture, or a materially larger hub than 60, was not tested |

**The headless-conservatism comparison** (software vs. a hardware-forced launch flag, same fixture):
hardware is faster at every sampled point, but the margin **shrinks sharply with scale** — 34.3 % at
500 nodes to 1.5 % at 2,000 nodes. This is the comparison Part 7 below applies to the actual bench
verdict.

---

## Part 6 — Every measurand in D4's set (D10 part 6, AC-S5)

*Sources: `rendering-stage2a-response-surface.md` (measurands 1–5, 7–8 partial), and note where a
measurand is not covered.*

| # | Measurand | Verdict |
|---|---|---|
| 1 | Layout tick cost | Minority contributor at every sampled point (12–19 % of total, Stage 2a § 3) — the superseded record's "layout dominates" claim is **not reproduced** in this implementation |
| 2 | Node draw cost, across every `Kind` value | Architecturally cheap: position-only update on geometry built once per node. All seven `Kind` values render distinctly (shape + colour), confirmed by direct screenshot inspection (Stage 2a § 7.2) |
| 3 | Directed-edge arrowheads | Feasible, cheap: ~1.2 ms of draw time at 1,502 edges (~4 % of draw budget), A/B isolated (Stage 2a § 7.1) |
| 4 | Four line styles (solid/dashed/dotted/dash-dot) | **Feasible, not free.** No native dashed-stroke primitive in PixiJS 8.14.0's `Graphics`; dotted/dash-dot roughly double the draw cost of solid/dashed once introduced (Stage 2a § 6) |
| 5 | Hover labels at max-degree worst case | Feasible; not measurably distinguishable from base edge-redraw cost up to 60 concurrent labels on the tested fixture (Stage 2a § 7) |
| 6 | Node drag | **Measured at Stage 2b, not Stage 2a** (not one of D2b's five axes). See Part 7 — does not clear NFR-7 |
| 7 | Category filtering, full category count | Steady cost at 14 categories: 36.05 ms median / 46.9 ms p95 — over budget at this synthetic point (not the derived bench). Filter-toggle transition (8.4 ms, single-frame sample) is **not** a spike above the post-filter steady state (6.3 ms median) for this implementation's `.visible`-flag toggling strategy (Stage 2a § 6.1) |
| 8 | Reduced-motion settled render | **Not measured by any stage.** Not one of D2b's five axes (Stage 2a's own scope exclusion); no stage built or drove the NFR-4 fallback path for the decided architecture. Recorded as a gap — see Part 8 |
| 9 | Vendored-bundle token / render-transform checks | **Clean at the evaluated versions.** Zero hits for `mermaid`, `canonical/`, or any of the three substitution placeholders across all five vendored files (Stage 3 § 3.4) |

---

## Part 7 — The frame-time predicate, and NFR-7's two verdicts at the derived bench (D10 part 7, AC-S7)

**The predicate** (D4b, applied identically by Stage 2a and Stage 2b): median and 95th percentile
over 150 sampled frames, after 30 excluded warm-up frames, against a 33.33 ms/frame (30 fps)
threshold. Applied **separately** to steady simulation and to node drag. "Clears" is decided on p95
(the conservative statistic).

**The headless-conservatism argument, and why it does not rescue the verdict below.** Stage 2a found
the software/hardware gap narrows to under 2 % by 2,000 nodes. Stage 2b's own words: *"that caveat
does not apply here in the failing direction: the margin by which this bench misses the floor … is
far larger than any plausible few-percent hardware speedup could close."*

**This is the single most consequential finding in this document, and it is recorded plainly rather
than softened.** *Source: `rendering-stage2b-bench-and-verdicts.md` § 3.*

| Window | tick median/p95 (ms) | draw median/p95 (ms) | **total median/p95 (ms)** | Clears 33.33 ms at p95? |
|---|---|---|---|---|
| **Steady simulation** | 13.7 / 23.6 | 78.15 / 103.1 | **92.4 / 124.9** | **No — does NOT clear.** ~2.8× over budget at median, ~3.7× at p95 |
| **Node drag** (hub pinned and swept, the worst case) | 13.05 / 19.2 | 92.9 / 119.6 | **105.1 / 134.9** | **No — does NOT clear.** ~3.2–4× over budget, and *worse than steady* — dragging re-heats the simulation and adds pointer-handling cost on top of an already-failing baseline |

**Both verdicts are measured at this project's own derived bench** — 1,609 nodes, converging to
3,854 edges against the bench's real 6,171 (Part 4's honest limitation), maximum degree 329 — using
the identical d3-force + PixiJS harness and Playwright launch configuration Stage 1 and Stage 2a
characterised. **Both figures are conservative in the direction of understating the real bench's
cost**, because the verdict fixture's actual edge count (3,854) undershoots the bench's own measured
edge count (6,171), and Stage 2a's own edge-count axis found cost tracks edges near-linearly — more
edges would cost more, not less.

**AC-6a is answered, and stated without euphemism: at the derived bench, the graph does not sustain
NFR-7's ≥30 fps floor during steady simulation, and it does not sustain it during node drag either.**
Per NFR-8's own governing text (Q14 item 7) and the SPEC's own validation boundary, **exceeding a
measured floor or ceiling is a finding this validation reports, not a defect this validation
resolves — no adaptive degradation is built anywhere by design, and this document does not invent
one.** What this implies for the artifact's shippability is the work owner's decision, not this
document's; Part 4's edge-set limitation and the recommendation at Part 9 bound what is and is not
yet knowable about it.

---

## Part 8 — Settle time: reported and not gated (D10 part 8, AC-S8)

**This part is not discharged, and that is recorded rather than papered over.** D4b's own text: "settle
time is reported and not gated… so that a reader cannot mistake a number presented beside a gated
one for a second gate." No stage document measured a settle-time figure for the decided
architecture. Stage 2a's harness runs the simulation with `alphaDecay(0)` — it deliberately **never**
settles, because FR-2's default path is continuous simulation, not the one-time-settle behaviour the
superseded (SVG) record measured. The NFR-4 reduced-motion **fallback** path — which is where a
"time to converge" figure would actually apply — was not built or driven by any stage (D4 measurand
8, Part 6 above).

**Consequence, stated as a gap rather than as a decision this document is not authorised to make:**
AC-S8 asks the report to state settle time explicitly, with the words that say it is not gated. This
document cannot supply a measured figure because none exists yet. **Flagged as an open question for
the owner**: whether a settle-time measurement for the NFR-4 fallback path is scheduled as a small
follow-on task, or whether the fallback's convergence time is accepted as unmeasured pending
feature-008's build (at which point the fallback path will actually exist to drive). This document
does not decide between those options.

---

## Part 9 — The ceiling: NFR-8, curve, threshold, degree sensitivity, comparand (D10 part 9, AC-S9, AC-16a)

*Source: `rendering-stage2b-bench-and-verdicts.md` § 4.*

**Method, bracketed downward rather than swept exhaustively**, per this task's own scope
instruction: two brackets, at two different, both-real degree distributions, because D5 requires the
ceiling to be stated at a stated degree distribution and requires its sensitivity to be shown.

| Bracket | Topology | Ceiling |
|---|---|---|
| **A** — Stage 2a's own baseline (mean degree 4, max degree 60, 14 categories, ~5 % isolated) | Not this project's own topology; reused because already measured | **(500, 1,000] nodes** |
| **B** — this project's own measured degree distribution (mean degree target 7.67, max degree 329, 7 of 14 categories, ~40 % isolated) | **This project's own** | **(500, 550] nodes** — clears comfortably at 500 (p95 30.7 ms), fails at 550 by 0.4 ms at p95, clearly fails at 600 (median within 3 ms of threshold) |

**NFR-8's stated ceiling for this project is Bracket B, not Bracket A.** Bracket A is retained only
to show the degree sensitivity NFR-8's own wording requires: Bracket A's topology has half this
project's mean degree and a fifth of its maximum degree, and its ceiling is correspondingly roughly
double Bracket B's — consistent with Part 5's own finding that edge count, not node count alone, is
the dominant cost driver. **This project's own current bench (1,609 nodes) is roughly 3× past the
upper edge of its own measured ceiling.**

**The comparand question is not resolved by this document**, per D5's own instruction. NFR-8 and
AC-16a name "node count," but Part 5's axis-3 finding (max degree, with edge total held fixed, does
not move frame time) means a bare node-count warning would be wrong in both directions on a
differently-shaped graph. **This document supplies the evidence and states the tension; the choice
between a raw-node-count comparand and a degree-aware one is feature-010's implementation decision
(Open Item 6 of the SPEC), not decided here.**

---

## Part 10 — Payload, at every tracked copy, and the render-transform integrity verdict (D10 part 10, AC-S10)

*Source: `rendering-stage3-payload-licence-update.md` §§ 2–3.*

**The vendored set is five files, not two — a finding this document owes before it can price
anything.** `d3-force`'s classic-script build does not stand alone: it requires `d3-quadtree`,
`d3-dispatch` and `d3-timer` to already be merged onto the same global before it runs. PixiJS carries
no such chain.

| File | Version | Bytes | Licence |
|---|---|---|---|
| `d3-quadtree.min.js` | 3.0.1 | 5,279 | ISC |
| `d3-dispatch.min.js` | 3.0.1 | 1,901 | ISC |
| `d3-timer.min.js` | 3.0.1 | 1,947 | ISC |
| `d3-force.min.js` | 3.0.0 | 8,300 | ISC |
| `pixi.min.js` | 8.19.0 | 797,792 | MIT |
| **Combined, one copy** | — | **815,219 bytes** (≈ 796 KiB) | — |

**The repository-side multiplier: a corrected finding, not the SPEC's stated 6×.** The SPEC states
six tracked copies (canonical + five profile renders). Verified against the sibling
`canonical/aid/templates/graph/` directory: this repository also carries **root-level dogfood
mirrors** at `.claude/` and `.cursor/`, byte-identical to their `profiles/` counterparts, that the
SPEC's 6× figure does not count. **The multiplier is stated as a range, 6×–8×** (4,891,314 –
6,521,752 bytes), because the vendor directory itself does not exist on disk yet and cannot be
measured directly — feature-012 should re-run the check once it authors that directory and pin the
real number.

**Render-transform integrity verdict: clean at the evaluated versions.** All five files are `.js`,
which is inside `render.py`'s `_TEXT_EXTENSIONS`, so all five are run through `substitute_filenames`
and `rewrite_install_paths` on their way into every profile render. Grepping the actual downloaded
bytes for every trigger string (`canonical/`, the three placeholder tokens, `mermaid`): **zero hits
in every file.** This is **not stable across a version bump** — the update procedure (Part 12) must
re-run this check every time, not once.

---

## Part 11 — Licence and attribution, per library, exact version (D10 part 11, AC-S11)

*Source: `rendering-stage3-payload-licence-update.md` § 4.*

All four D3 modules are **ISC** (Mike Bostock, 2010–2021), read from each package's upstream
`LICENSE` file at its pinned version, not from a registry field or a summary page. PixiJS is **MIT**
(Mathew Groves, Chad Engler, 2013–2023), same discipline. Both are permissive, non-copyleft licences
with no source-disclosure obligation; the redistributed unit is a file generated into a **third
party's** repository under this project's own MIT terms, and a permissive licence poses no problem
under that combination.

**Neither bundle's own inline header comment is sufficient attribution by itself** — each carries a
one-line project/version/copyright comment, but not the full permission-notice paragraph either
licence's wording requires to travel with the software.

**Where attribution should appear — the recommendation, and why.** A **companion `LICENSE` file
placed beside each vendored bundle**, copied verbatim from the upstream package at the pinned
version. This satisfies "included in all copies" for both ISC and MIT directly, and is
**structurally immune** to Part 10's corruption risk: a file literally named `LICENSE` has no
suffix, so it is not a member of `render.py`'s `_TEXT_EXTENSIONS` and renders byte-identical to every
profile, the same way `.yml` data files do. Editing the notice into the vendored `.js` bytes directly
was considered and rejected — it would defeat the update procedure's own byte-comparison check
(Part 12).

---

## Part 12 — The update mechanism, against the verified Dependabot baseline (D10 part 12, AC-S12)

*Source: `rendering-stage3-payload-licence-update.md` §§ 6–8.*

**Verified baseline, re-confirmed on disk rather than carried forward:** `.github/dependabot.yml`
declares exactly one ecosystem, `github-actions`, scoped to `/`. **Nothing in this repository watches
a JavaScript dependency today** — not one declared in a manifest, pinned to a CDN, or vendored into a
generated artifact.

**Two distinct questions, both named because the second is new and no prior reading asked it:**

1. **Who notices upstream moved?** Recommended: a scoped, `"private": true`
   `canonical/aid/scripts/graph/package.json` pinning all five packages at exact versions, plus a new
   `.github/dependabot.yml` entry targeting that directory. This reuses the shape of the existing
   Playwright-manifest precedent (`canonical/aid/scripts/summarize/package.json`) rather than adding
   a bespoke CI script this project alone would maintain. **Its ongoing obligation, stated rather
   than left implicit:** a merged Dependabot PR is only a version-bump notification — it does not
   re-vendor the bytes. A human must, every time: re-download the dist files, re-run Part 10's
   integrity grep, re-verify Part 11's licence text, re-measure the payload, and only then replace
   the vendored bytes.
2. **Who notices if the shipped copy silently stops equalling upstream?** Under the recommended
   manifest alone: nobody, mechanically — the render-drift CI job compares a fresh render to a
   committed render, so a consistently-mangled copy matches a freshly-mangled one perfectly. The
   answer becomes "the person executing the update procedure, if it is followed," once Part 10's
   grep plus a byte-comparison against a fresh upstream download at the pinned version is made a
   **named step inside the update procedure** — run at vendor time and at every version bump, not
   once. This is feature-012's own G6 condition, and this document supplies the check's method and
   its clean result; feature-012 owns wiring it in.

---

## Part 13 — Runtime prerequisites, in prose (D10 part 13, AC-6)

*Source: `rendering-stage2b-bench-and-verdicts.md` § 5, verbatim — quotable by feature-007 and
feature-010 without paraphrase, per this task's own criterion.*

> `graph.html` requires, at the point it is opened: **(1) WebGL** — a browser able to create a
> `webgl2` or `webgl` rendering context. This project's own validation toolchain has already
> confirmed this is satisfiable headless, with no GPU, on the exact Playwright/Chromium launch
> configuration the project reuses (Part 2 above: L1/L2/L3 all PASS on the software-rasteriser
> environment); the escalation matrix at feature-002 SPEC's D1a states what changes for an
> environment where it is not. **(2) No network access** — the vendored `d3-force`/PixiJS bundle and
> its companion files are loaded from local disk beside `graph.html`, never fetched from a CDN (Part
> 14's recommended packaging shape), and this project's own visual-validation harness enforces the
> same rule by aborting every non-`file://` request during validation. **(3) The companion vendor
> assets physically present beside `graph.html`** — the artifact is a small set of files, not a
> single self-contained document (Part 10: five tracked files, not two). **(4) No build step at open
> time** — the vendored bundle is produced once, at authoring/render time, not in the reader's
> browser.

This is the receipt for **task-017** (canvas sizing and runtime prerequisites): the prose above is
the statement it consumes directly, without inference.

---

## Part 14 — AC-21's keyboard validation route, independent of the drawing surface (D10 part 14, AC-S13, AC-21)

*Structural, decided by Q9 and stated at the SPEC's own D9 — not re-derived by any stage, because
none of the three stages touches it. Reused rather than re-measured, consistent with this task's
instruction to attribute rather than re-derive what a stage did not need to re-establish.*

**The canvas is visual-only (Q9). No control is drawn on it.** NFR-6's own consequence: the
accessible table view provides the keyboard-operable route to select and open, so the canvas's mouse
gestures are an enhancement rather than the only path. Every control is a real focusable HTML
element (AC-9 as scoped: the DOM-level checks apply to the page structure and the table view, not to
the canvas). **AC-21 is therefore decided against the DOM**, and a keyboard-only drive plus a
focus-order and activation assertion needs no graphics context at all — it survives every Stage-1
outcome, including the worst (L1 ✗, had it occurred).

**The trap this route must not fall into, stated because AC-21's own wording names it:** the
criterion is a test of *where the controls live*, not merely a test of whether keyboard handlers
work. The check that decides it must assert the control set is *complete* in the DOM — every filter
axis, every lens, select and open — not merely that the DOM controls present are reachable. A
control drawn on the canvas would pass a narrower check and fail this one.

**Owners of the controls:** feature-007 (shell, lens bar, filters), feature-008 (canvas gestures as
enhancement only), feature-009 (the table's select/open route). This document supplies the route and
its independence; it builds none of the controls.

---

## Part 15 — Drafted `technology-stack.md` and `infrastructure.md` content (D10 part 15)

*Drafts only, for feature-013 to land at ship time. Not written to `.aid/knowledge/` by this
document.*

**Proposed addition to `technology-stack.md` § Key Dependencies:**

```markdown
### Graph View — d3-force + PixiJS (browser-only; inside graph.html and its companions)

Five vendored classic-script (UMD/IIFE) builds ship as local companion files beside `graph.html`,
loaded via `<script src>` in dependency order. Not installed at adopter time; do not affect the
CLI's runtime environment.

| File | Version | Licence | Bytes |
|------|---------|---------|-------|
| d3-quadtree.min.js | 3.0.1 | ISC | 5,279 |
| d3-dispatch.min.js | 3.0.1 | ISC | 1,901 |
| d3-timer.min.js | 3.0.1 | ISC | 1,947 |
| d3-force.min.js | 3.0.0 | ISC | 8,300 |
| pixi.min.js | 8.19.0 | MIT | 797,792 |
| **Total** | | | **815,219 bytes (≈796 KiB)** |

Attribution: a companion `LICENSE` file per library, copied verbatim from the upstream package at
the pinned version, placed beside its bundle.

Version tracking: `canonical/aid/scripts/graph/package.json` (private; Dependabot npm entry).
```

**Proposed addition to `technology-stack.md` § Version Concerns:**

```markdown
- **d3-force / PixiJS (graph.html companions):** pinned at d3-force@3.0.0 (+ d3-quadtree@3.0.1,
  d3-dispatch@3.0.1, d3-timer@3.0.1) and pixi.js@8.19.0. A major bump to either changes the
  simulation or drawing API and requires a coordinated update to feature-008's drawing code.
  Every Dependabot PR against the scoped manifest is a version-bump notification only — re-vendoring
  the bytes, re-running the integrity grep and re-checking the licence text are separate,
  required follow-on steps (see infrastructure.md's vendoring procedure).
```

**Proposed addition to `infrastructure.md` § The Build: Multi-Profile Render (or a new §
Dependency Vendoring subsection):**

```markdown
### Graph View Dependency Vendoring (maintainer task; not in CI build)

Triggered by a Dependabot PR against `canonical/aid/scripts/graph/package.json`. Procedure:
1. Fetch the bumped package(s)' dist files at the exact new version.
2. Grep the new bytes for `canonical/`, the three render.py placeholder tokens, and `mermaid`
   (render-transform integrity check — must be clean before proceeding).
3. Byte-diff the new files against the currently-vendored copies to confirm what changed.
4. Replace the vendored `.min.js` files and their companion `LICENSE` files.
5. Re-run the render.py integrity grep against the newly-vendored bytes.
6. Update the version comment and commit.

CI impact: none. The committed vendor files are source files for CI purposes.
```

---

## Part 16 — Implication for feature-008's size (D10 part 16 — a range with named drivers, not a line count)

**The superseded record's ~279-line estimate is void (Q9 removed the accessibility-proxy work it
priced), and this document does not replace it with a new line count.** Per the SPEC's own D10 part
16 instruction, what follows is a range with its drivers named:

| Driver | Direction | Basis |
|---|---|---|
| No DOM accessibility proxy | **Reduces** size, relative to any Canvas/WebGL candidate the superseded comparison considered | Q9: canvas is visual-only, AA carried by the table view |
| Node draw (position-only, geometry built once) | Small, flat contributor | Part 6, measurand 2 |
| Edge redraw, every frame (both endpoints move under continuous simulation) | **Dominant** cost driver and dominant code-size driver — arrowhead geometry, per-edge line-style segmentation | Part 5 axis 2; Part 6, measurands 3–4 |
| Four line styles via hand-segmented subpaths (no native dashed-stroke primitive in PixiJS's core `Graphics`) | Adds drawing-code complexity beyond a single `.stroke()` call per edge | Part 5 axis 4; Part 6, measurand 4 |
| Category filtering as a `.visible` flag flip (not object destroy/rebuild) | Small, if this implementation strategy is followed — Stage 2a's own finding is scoped to that strategy | Part 6, measurand 7 |
| Node drag driving pointer handling and re-heating the simulation | Adds interaction code; also the more expensive runtime path (Part 7) | Part 7 |
| Palette-as-CSS-custom-properties integration (D8) | Adds an integration seam between the drawing code and the CSS design tokens, not previously required under the superseded SVG design | SPEC § D8; routed to feature-007/008 as Open Items 4–5 |
| `toDataURL()` synchronisation constraint (Part 3) | Adds a documented constraint on any export/test code path, not a steady-state cost | Part 2, § 2.5 of the Stage 1 report |

**No numeric estimate is offered.** The honest position, consistent with this document's own
measurement posture, is that feature-008's size depends on which of the above drivers its
implementation strategy engages most heavily — and Part 7's finding that the decided architecture
does not clear NFR-7 at this project's own bench is itself a fact feature-008's implementers need
before sizing anything, since it bears on whether optimisation work (not scoped by this feature,
and not decided here) becomes part of feature-008's own work.

---

## Part 17 — Hand-off: firing conditions readable as yes/no (BLUEPRINT edge 2)

Per this task's scope, feature-002 sits before features 008, 011 and 012 in the BLUEPRINT, and three
downstream tasks read their firing conditions directly off this document:

| Consumer | Firing condition | Answer |
|---|---|---|
| **task-017** (canvas sizing, runtime prerequisites) | Reads Part 13's prose statement | **Statement supplied, quotable verbatim** — no inference required |
| **task-019** (feature-011's `validate-html-output.sh` S2 CDN carve-out) | Fires only if the recommended packaging shape references a CDN | **Does not fire.** Part 14 (Stage 3 § 5): the recommended shape is five local companion files, no CDN reference anywhere. S2 never triggers under this packaging; the carve-out held in reserve is a **recorded no-op** |
| — (the `validate-visuals.mjs` T2 live-surface exclusion, also held in reserve) | Fires only if the live surface matches one of T2's three selectors | **Does not fire.** A `<canvas>` matches none of `.diagram-box`, `.infographic`, or the bare-`svg` walk (D1b, confirmed by `rendering-stage1-webgl-probe.md` § 4's re-run of `validate-visuals.mjs` against `kb.html`, still 4/4 PASS with the graph work present in the tree) |
| **task-023** (feature-012's dependency-packaging gate, D6 G1–G7) | Fires whenever a third-party library is adopted as a vendored dependency | **Fires.** Two libraries — five files — under ISC/MIT, at the exact versions in Part 10, with the licence/attribution facts of Part 11 and the update mechanism of Part 12 mapped directly onto G1–G7 in Stage 3 § 5's own table |

---

## Part 18 — Attribution of every figure (D10 part 17, AC-S6)

Every figure in Parts 2–13 is one of the three admissible forms and is attributed at its own point
of use to the stage document that produced it: a **quoted runtime output** (Parts 2, 3, 5, 6, 7, 9,
10 payload bytes, integrity grep), a **verified on-disk or upstream fact with its command and read
date** (Part 10's multiplier check, Part 11's licence files, Part 12's Dependabot baseline), or an
**explicitly labelled quantity still owed** (Part 4's edge-set provisional flag, Part 8's settle-time
gap, Part 16's deliberately-absent line count). No figure in this document is carried over from the
superseded 2026-07-28 record. Where this document restates a figure already attributed in a stage
document, it cites that document and section rather than re-deriving the number.

---

## Quality Gates — self-check against this task's acceptance criteria

- [x] Every D10 required part present and attributed to its discharging stage (Parts 1–17; Part 8
      is explicitly **not discharged**, and is recorded as a gap rather than papered over)
- [x] The superseded-baseline audit table carried forward (Part 0)
- [x] Runtime-prerequisite sentence stated as prose, quotable verbatim (Part 13)
- [x] feature-011's S2 firing condition and feature-012's D6 gate firing condition readable as
      yes/no (Part 17)
- [x] No renderer comparison reopened — Part 7 reports a measured failure with evidence; Part 0
      states explicitly that this is a different act
- [x] AC-S3 holds: no bench size is asserted by this feature (Part 4's compliance statement; every
      count attributed to Stage 2b's measured output)
- [x] No permanent artifact cites this document (header note; this is a transient work-folder
      artifact per `CLAUDE.md` § Tracking discipline)
- [x] Accuracy verified against the current SPEC at execution time — read in full on 2026-08-06,
      not against this task's own brief's summary of it
- [x] Section-6 quality gates: this checklist

---

*End of re-issued record. Written by aid-tech-writer, task-011, delivery-001,
work-005-knowledge-graph, re-issuing task-005's 2026-07-28 revision against the amended SPEC.
2026-08-06.*
