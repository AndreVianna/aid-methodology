# delivery-001 — Research Foundation: Findings

> # ⚠️ SUPERSEDED 2026-07-29
>
> **Both research conclusions in this report are withdrawn by owner decision.** It is kept as
> history, not as guidance. Do not build on §2 (the vocabulary) or §3/§6 (the renderer).
>
> **What was wrong.** The rendering decision recommended a **static** SVG graph — settled once
> before first paint, no animation. That is a picture of a graph, not a graph. It contradicted
> NFR-4 (whose reduced-motion clause only means something if the default animates) and FR-16
> (which directs the research to optimise for interaction quality). The vocabulary was harvested
> **only** from this repository's own frontmatter conventions, with **no standard vocabulary
> consulted** — no SKOS, Dublin Core, PROV-O, schema.org, IANA link relations or CiTO — so whole
> families of relation are missing. The root cause of its small size is the node model: nodes were
> **files**, and file-to-file relations are inherently few.
>
> **The scale basis is void too.** The 784-node bench, and every performance conclusion resting on
> it, assumed whole-artifact granularity (FR-23) and node counts "in the hundreds" (A-5). Both are
> superseded: concepts, facts and sections are now nodes, putting this repository at **~1,200+**.
>
> **What still stands and should be reused rather than re-paid for:** the five inverse-pair contract
> properties (closure, totality, involution, symmetric consistency, category totality); the YAML
> entry mechanism; the fixture methodology (hub seeding, isolated nodes deliberately kept); the
> generated-tree exclusion reasoning; the finding that `external-sources.md` is empty; and the
> "nothing watches JavaScript dependencies" baseline.
>
> **Why the A+ gate did not catch it** — worth carrying into the methodology. All eleven gate
> criteria tested the record's *completeness and traceability*: fifteen parts present, exactly one
> approach named, rejections stated, prerequisites explicit. Not one asked whether the recommended
> artifact was **alive**, or whether the vocabulary **generalised beyond this repository**. Three
> review cycles polished the arithmetic of the wrong answer.
>
> Replacement decisions: REQUIREMENTS.md change log (2026-07-29) and STATE.md Q9/Q10/Q11.

**Work:** work-005-knowledge-graph · **Date:** 2026-07-28
**Result (as gated, now superseded):** all 5 tasks Done · gate grade **A+** · delivery **Done**

This delivery answered two questions: what vocabulary describes relationships, and
what renders the graph. It wrote no product code. It produced one permanent file
and five research reports.

---

## 1. How big is the graph?

**784 nodes, ~750 edges.** That is small — a few hundred nodes, sparsely connected.

- 583 source files + ~201 KB docs + **0 external** (`external-sources.md` is empty,
  which is why the external test data is a synthetic fixture)
- Stress bench: ~8,000 nodes, ten times bigger

We excluded the profile emission manifests (1,765 records). They point at generated
files, which FR-22 says are not nodes — so their edges would have no target.
Including them would have tripled the bench and thrown off every rendering estimate.

## 2. The vocabulary (shipped)

`canonical/aid/templates/graph/relation-vocabulary.yml` — the one permanent file here.
**15 entries, 8 pairs, 5 categories.**

| Category | Pairs |
|---|---|
| dependency | `depends-on`/`dependency-of`, `invokes`/`invoked-by` |
| documentation | `documents`/`documented-by`, `cites`/`cited-by`, `references`/`referenced-by` |
| generation | `generates`/`generated-by` |
| navigation | `cross-references`/`cross-referenced-by` |
| obligation | `lockstep-with` (its own inverse) |

Two things had to be fixed along the way:

- **The categories were regrouped.** The original grouping (by KB / source / external)
  left source-to-source edges with nowhere to go. Grouping by the *kind* of relationship
  covers every pair.
- **The inverses had the wrong endpoints.** Each inverse was given the same endpoints as
  its forward direction instead of the reverse — `cites: kb:->int:` should invert to
  `cited-by: int:->kb:`. Unfixed, a later validator would have flagged every valid row.

## 3. The renderer decision

**D3.js v7 (four modules), drawing SVG, pasted straight into the HTML file.**
36 KB, ISC licence, no CDN, no build step, no extra files. Readers need only a browser
with JavaScript.

Why: **the slow part is computing the layout, not drawing it.** At 784 nodes the force
simulation takes 750 ms one time at load; the drawing is free at this size. A GPU
renderer speeds up drawing, so it buys nothing here — and it would cost 231–431 extra
lines of hand-written accessibility code, because WebGL and Canvas are invisible to
screen readers. SVG is readable by screen readers for free.

So we chose accessibility, and paid 750 ms of one-time layout for it.

| | |
|---|---|
| Payload | 36 KB (4 D3 modules) |
| Attribution | ISC notice kept in a comment inside the `<script>` — nothing user-visible needed |
| Update tracking | **Nothing watches D3 today.** `dependabot.yml` only covers GitHub Actions; a watcher must be added |
| Accessibility work | ~69 lines of ARIA/focus code; nothing extra for the table view |
| Next feature's size | ~279 lines |

**Caveat for later readers:** SVG is comfortable at 784 nodes but breaks down at 8,000.
If the graph grows an order of magnitude, revisit this.

## 4. What this unblocks

| Later task | Fires? |
|---|---|
| 076/077 — CDN carve-out | **No** — we don't use a CDN |
| 083 — dependency packaging gate | **Yes** — D3 is third-party, so pin the version and record the licence |
| 084/085 — visual-test exclusion | **Yes** — SVG graphs overlap on purpose, which the visual test forbids. Must land before the CI visual check |

## 5. Two mistakes caught by review

Worth recording, because both were caught by checking numbers rather than reading prose:

- **A made-up measurement.** The first draft of the rendering decision claimed a 68 ms
  layout time. That number appears nowhere in the source; the real figure is 750 ms —
  ten times slower. Two other untraceable figures turned up in the same pass. The final
  record's numbers all trace to a measured line.
- **A test fixture that tested nothing.** The first fixture was accidentally a straight
  line of nodes, so all the layout timings were meaningless. The rebuilt fixture has a
  realistic shape — one hub with 187 connections, and 35% isolated nodes. Isolated nodes
  were kept deliberately: they are exactly what the gap ledger exists to find.

## 6. Gate

**Passed at A+** (Medium tier, 2 cycles). Two findings, both fixed: entries in the
vocabulary file were out of alphabetical order, and three example rows were formatted
sideways instead of as real table rows.

Confirmed: no product code changed, the Knowledge Base was untouched, and no test
harness was committed.

---

## Artifacts

| File | Lines |
|---|---|
| `canonical/.../relation-vocabulary.yml` | permanent |
| `research/relation-vocabulary-evidence.md` | 830 |
| `research/relation-vocabulary-report.md` | 329 |
| `research/rendering-bench-and-options.md` | 654 |
| `research/rendering-spike-matrix.md` | 418 |
| `research/rendering-decision-record.md` | 970 |
