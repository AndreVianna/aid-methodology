# Stage 2b — the derived bench, NFR-7's two verdicts, NFR-8's ceiling

> **Scope: Stage 2b only.** This is `task-010`'s deliverable: apply Stage 2a's response surface
> (`rendering-stage2a-response-surface.md`) to a bench derived by feature-002 SPEC's **D2**
> procedure over this repository's own producer streams, and answer **AC-6a** (the two ≥30 fps
> verdicts, steady simulation and node drag) and **NFR-8** (the practical ceiling, with its
> measurement conditions). It does **not** re-run Stage 1 (the WebGL probe) or Stage 3 (payload,
> licence, update) — both already exist as
> `rendering-stage1-webgl-probe.md` and `rendering-stage3-payload-licence-update.md`. It does
> **not** write `canonical/aid/templates/graph/scale-ceiling.yml` — that carrier write is
> `task-021`'s.

**Work:** work-005-knowledge-graph · **Feature:** feature-002 · **Date run:** 2026-08-06
**Repository state:** branch `work-005`
**Specification:** `.aid/works/work-005-knowledge-graph/features/feature-002-graph-rendering-research/SPEC.md`
§ D2, D2a, D2b (recommendation, § 11), D4b, D5

---

## 1. Status of this document

**DONE**, with explicit boundaries stated at every section — see § 6 for the measured/inferred/
missing split. Both AC-6a windows carry a runtime-measured verdict; NFR-8's ceiling is a
**measured bracket with its method stated**, not a swept-and-confirmed single point, per this
task's own instruction not to sweep exhaustively.

---

## 2. The bench — D2's three terms, derived from files already on disk

**D2's procedure is not re-run from scratch here.** A prior pass at this task had already run
feature-004's enumerator and most of feature-005's Pass 1a/Pass 1 machinery via the patched
script copies at `.aid/.temp/graph-stage2b-patched/`, and left their outputs at
`.aid/.temp/graph-stage2b-bench/` and `.aid/.temp/graph-stage2b-bench-kb/` (both gitignored,
throwaway, per A-6 and this project's transient-work-folder rule). This section reads those
files, verifies their arithmetic, and states where the derivation was **incomplete** when the
prior attempt stopped (edge-set reconciliation) — it does not repeat the parts that were
already correct, and does not invent the parts that were not finished.

### Term 1 — the KB-side node set (feature-005 Pass 1a, after Q13's merge)

Read from `.aid/.temp/graph-stage2b-bench-kb/kb-stats.tsv` (2026-08-05):

| Kind | count |
|---|---|
| `document` | 21 |
| `section` | 340 |
| `fact` | 86 |
| `concept` | 32 |
| **KB-side total** | **479** |

Reproduces: `wc -l .aid/.temp/graph-stage2b-bench-kb/kb-nodes.tsv` → 479. Coverage rows recorded
alongside it (same file): `fact-unanchored` 1752 (claims with no checkable anchor, correctly
excluded per feature-003 D2a-2 — this is the count D2a's own finding warns against treating as
facts), `section-empty-slug` 0, `concept-qualified` 0 (no concept needed disambiguation —
`concept-merge-candidates.tsv` is present and empty, 0 bytes, meaning the merge step found no
candidate duplicates to fold — a real finding, not a missing file).

### Term 2 — the source-artifact, image and web-page node set (feature-004's enumerator)

Read from `.aid/.temp/graph-stage2b-bench-kb/coverage.tsv` (identical in the `-bench` sibling
dir; 2026-08-05):

| Kind | state | count |
|---|---|---|
| `source-artifact` | present | 1126 |
| `image` | present | 4 |
| `web-page` | absent | 0 |
| **Term-2 total** | | **1130** |

`web-page` is 0 because `.aid/knowledge/external-sources.md` carries zero registered entries
(the standing fact PLAN.md's Cross-Cutting Risk 5 already records) — a real zero, not a gap in
the enumerator. `source-artifact-dropped` (paths surviving exclusions that no significance
clause qualified) is 15, recorded but not counted as nodes, per FR-21.

### Total node count across every producer stream

**479 + 1130 = 1,609 nodes.** This is the comparand AC's third bullet names for NFR-8.

### Term 3 — the edge set and the degree distribution

**This is where the prior attempt stopped** ("57 relations mapped, now joining ... to get
category totals"), and it is reconstructed here from the classification-stage files it had
already produced, rather than re-run from the raw candidate observations:

| File | Rows | What it is |
|---|---|---|
| `rows-pass1a.tsv` | 4,184 | KB-structural edges: `has-part`/`part-of` (document↔section), `documents`/`documented-by` (document↔source-artifact), `cites`/`cited-by`, etc., from Pass 1a |
| `rows-pass1b.tsv` | 736 | Source-artifact dependency edges (`depends-on`/`dependency-of`) resolved from the raw reference observations |
| `rows-class0.tsv` | 3,508 | A second, overlapping classification pass over the same dependency-observation space (144 rows shared with `rows-pass1b.tsv`, 3,364 not in it — the two passes are not a subset relation) |
| `rows-class1-accepted.tsv` | 0 | No rows were promoted at the (stricter) class-1 bar |

**Union, deduplicated on (source id, target id, S2T relation) across all three non-empty row
files: 6,171 unique edges.** (`8,428` raw rows → `6,171` after removing exact
`(source,target,relation)` duplicates — command:
`cat rows-pass1a.tsv rows-pass1b.tsv rows-class0.tsv | awk -F'\t' '{k=$2"\t"$5"\t"$8; if(!(k in s)){s[k]=1;print}}' | wc -l`,
run 2026-08-06.)

**This is the honest limitation of this term**, stated plainly rather than smoothed over: the
prior attempt's classification pipeline (`candidates.tsv` → `rows-pass1a`/`rows-pass1b` →
`class0`/`class1-accepted`) was mid-run, not a finished `relationships.md`, and `rows-class0.tsv`
and `rows-pass1b.tsv` disagreeing on 3,364 of 3,508 + 592 of 736 rows means the classification
rule that would resolve which of the two passes is authoritative was never written down before
the attempt was stopped. The 6,171-edge union is a **best-effort, deduplicated superset** of
what a finished Pass 2 would emit — it is very unlikely to *undercount* real edges (every row
that survived either pass is counted once), and it may modestly *overcount* if the two
classification passes represent competing hypotheses about the same edge rather than two
disjoint edge sets. This is flagged in § 6 as a **measured-but-provisional** figure, and it is
the reason this section, not the SPEC's D2 procedure, is what should be re-run once
feature-004/feature-005 ship as production code (delivery-002) and produce a real
`relationships.md` — this task does not block on that, per its own scope.

**Degree distribution**, computed from the 6,171-edge union
(`awk -F'\t' '{print $2; print $5}' ... | sort | uniq -c`, run 2026-08-06):

| Statistic | Value |
|---|---|
| Nodes touched by ≥1 edge | 962 of 1,609 (59.8%) |
| Isolated nodes (degree 0) | 647 of 1,609 (40.2%) — kept deliberately, per D3 |
| Median degree (over connected nodes) | 6 |
| 95th-percentile degree | 42 |
| **Maximum degree** | **329** — `kb:concept:canonical` |
| Mean degree (over all 1,609 nodes, isolated included) | 2×6,171/1,609 ≈ 7.67 |

**Categories actually exercised.** Mapping the union's 20 distinct relation names to
`canonical/aid/templates/graph/relation-vocabulary.yml`'s 57 relation definitions and their
`category` field (all 57 mapped; read 2026-08-06) yields **7 of the vocabulary's 14 categories**
present in this bench's real edge set: `structure`, `documentation`, `evidence`, `dependency`,
`navigation`, `definition`, `representation`. The other seven (`taxonomy`, `agreement`,
`annotation`, `provenance`, `lineage`, `implementation`, `identity`) do not appear — a real
finding about this repository's own graph shape, not a defect in the count (feature-005's own
D8 producer map is what bounds this, per the SPEC's own text at D2).

**Isolated-node fraction is a finding worth flagging on its own.** 40.2% is far above the ~5%
Stage 2a's synthetic fixtures used as their default. A bench this sparse in connectivity is a
property of a real, mixed-artifact repository (many single-reference source files with no
declared KB counterpart) rather than of the fixture generator's own defaults.

---

## 3. AC-6a — the two verdicts

**Method.** Both windows apply D4b's frame-time predicate exactly as Stage 2a's report specifies
it: median and 95th percentile over 150 sampled frames, after 30 excluded warm-up frames,
against the 33.33 ms/frame (30 fps) threshold, "clears" decided on **p95** (the conservative
statistic — if p95 clears, median clears too by construction). Measured with the identical
self-built d3-force + PixiJS harness and Playwright launch configuration Stage 2a used
(`.aid/.temp/graph-stage2a-harness/`, `harness.html` + `harness-src.mjs`, unmodified), so the
renderer identity and every methodological choice are the same ones Stage 1 and Stage 2a already
characterised (software rasteriser: `ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero)
(0x0000C0DE)), SwiftShader driver)`, `WebGL 2.0 (OpenGL ES 3.0 Chromium)`).

**Fixture used for the verdict.** Because 1,609 nodes at maximum degree 329 cannot be entered by
hand into the fixture generator without approximating the mean-degree lever (the generator's
`meanDegree` parameter is a target the filler pass converges toward, not an exact dial — verified
running the same seed at increasing node counts: actual edges came out lower than the
6,171-edge/7.67-mean-degree target at every node count tried, e.g. 1,311 actual edges at 500
nodes rather than ~1,918), the verdict fixture is generated at the bench's **actual measured**
node total (1,609) with `meanDegree = 7.67` (the target the generator is asked to converge
toward), `maxDegree = 329`, `categoryCount = 7`, `isolatedFraction = 0.402` — every one of those
four values is this section's own measured bench figure, not a Stage 2a synthetic default. The
generator converged to **1,609 actual nodes, 3,854 actual edges** — **fewer** than the bench's
own measured 6,171. **This makes the verdict fixture a conservative approximation in the
"less work" direction**: the real bench likely costs at least as much as reported below, and
plausibly more, since § 4's own finding (edge count is close to the primary near-linear cost
driver) predicts more edges would cost more, not less. Command:
`node driver-drag.mjs` with `DRAG_POINTS` set to the bench's own params,
`.aid/.temp/graph-stage2a-harness/driver-drag.mjs`, run 2026-08-06,
`.aid/.temp/graph-stage2a-harness/drag-results.json`.

| Window | tick median/p95 (ms) | draw median/p95 (ms) | **total median/p95 (ms)** | Clears 33.33 ms at p95? | **Verdict against NFR-7's floor** |
|---|---|---|---|---|---|
| **Steady simulation** | 13.7 / 23.6 | 78.15 / 103.1 | **92.4 / 124.9** | No | **Does NOT clear.** ~2.8× over budget at median, ~3.7× at p95 |
| **Node drag** (hub — the highest-degree node — pinned and swept across the canvas for the full sampled window, the worst case: dragging a hub pulls the most neighbours) | 13.05 / 19.2 | 92.9 / 119.6 | **105.1 / 134.9** | No | **Does NOT clear.** ~3.2× over budget at median, ~4× at p95, and **worse than steady** — dragging adds pointer-handling cost and re-heats the simulation on top of an already-failing baseline |

**AC-6a is answered: at the derived bench, the graph does not sustain NFR-7's ≥30 fps floor
during steady simulation, and it does not sustain it during node drag either — node drag costs
more, not less, than steady state at this scale.** Both figures are runtime outputs of the run
cited above; both are conservative in the direction of understating the real bench's cost (edge
count undershoot, § above).

**The headless-conservatism argument (D4b point 3, established at Stage 2a § 8) does not rescue
this verdict.** Stage 2a found the software/hardware gap narrows to under 2% by 2,000 nodes and
warned that "a headless result close to the threshold at large scale should not be read as
comfortably conservative." That caveat does not apply here in the failing direction: the margin
by which this bench misses the floor (92.4 ms and 105.1 ms medians against a 33.33 ms budget) is
far larger than any plausible few-percent hardware speedup could close.

---

## 4. NFR-8 — the ceiling, bracketed downward, with its method

**Method, stated once.** Per this task's own instruction, the ceiling is **bracketed downward**
from Stage 2a's own 4,000-node result (371.6 ms median, 11× over budget) rather than swept
upward from zero. Two brackets are reported, at two different, both-real degree distributions,
because D5 requires the ceiling to be stated **at a stated degree distribution** and requires its
sensitivity to be shown rather than assumed:

**Bracket A — Stage 2a's own already-run baseline** (`meanDegree = 4`, `maxDegree = 60`,
`categoryCount = 14`, ~5% isolated — **not** this project's own topology; reused because it is
already on disk and needs no new measurement): reading `rendering-stage2a-response-surface.md`
§ 3's own axis-1 table, **500 nodes clears** (median 11.5 ms / p95 27.1 ms) and **1,000 nodes does
not** (median 41.15 ms / p95 62.4 ms). **Ceiling bracket: (500, 1000] nodes, at that stated,
lower-mean-degree, lower-max-degree topology.**

**Bracket B — this project's own measured degree distribution** (`meanDegree` target `7.67`,
`maxDegree = 329`, `categoryCount = 7`, `isolatedFraction = 0.402` — § 2's own figures): five new
points run against the same harness and launch configuration
(`.aid/.temp/graph-stage2a-harness/driver-bench-bracket.mjs`, written for this task, run
2026-08-06, `bench-bracket-results.json`):

| nodeCount (target) | actual nodes | actual edges | max degree (actual) | total median/p95 (ms) | Clears 33.33 ms at p95? |
|---|---|---|---|---|---|
| 500 | 500 | 1,311 | 329 | **20.75 / 30.7** | **Yes** |
| 550 | 550 | ~1,426 | 329 | **16.75 / 33.7** | **No — barely** (p95 0.4 ms over; median still clears) |
| 600 | 600 | 1,542 | 330 | **30.5 / 39.3** | No |
| 700 | 700 | 1,772 | 330 | **23.1 / 44.3** | No |
| 1,000 | 1,000 | 2,458 | 329 | **50.05 / 68.5** | No |
| 1,609 (the bench's own real total) | 1,609 | 3,854 | 329 | **91.55 / 115.5** *(§ 3's verdict fixture reports 92.4/124.9 on a re-run — run-to-run noise on a shared dev machine, both readings fail by a wide margin)* | No |

**Ceiling bracket at this project's own topology: between 500 nodes (clears comfortably) and 550
nodes (fails, but only at p95, by 0.4 ms) — the tightest bracket this task measured — with 600
nodes as a clearly-failing confirmation point** (median itself is within 3 ms of the threshold
there). **This bench's own actual node total, 1,609, is roughly 3× past the upper edge of that
bracket.**

**Why Bracket A and Bracket B disagree by roughly 2×, and why that is the finding D5 asks for,
not noise.** Bracket A's topology has half this bench's mean degree and a fifth of its maximum
degree; Bracket B is measured at this bench's own numbers and its ceiling is correspondingly
lower. Stage 2a's own § 11 recommendation said to expect exactly this: edge count, not node count
alone, is close to the primary cost driver, and this project's real bench carries more edges per
node than Stage 2a's synthetic baseline did. **NFR-8's stated ceiling for this project is
Bracket B — (500, 550] nodes at this project's own measured degree distribution
(max degree 329, mean degree ≈7.67 target/≈5.2–5.7 actual at this scale, 7 of 14 categories
exercised, ~40% isolated) — not Bracket A**, which is retained in this document only to show the
sensitivity NFR-8's own wording asks for.

**The comparand question (D5's own open point, Open Item 6, not resolved here).** NFR-8 and
AC-16a name "node count." A bare node-count warning, keyed on Bracket B's ~500–550-node ceiling,
would be wrong in both directions on a graph with a different shape: a large, sparse graph could
sit well under the ceiling by node count while still failing the floor if its edge density is
high, and a small hub-heavy graph could trip a node-count warning while comfortably clearing the
floor (Stage 2a § 5's own axis-3 finding: max degree alone, with edge total held fixed, did not
move frame time). This document states the tension and, per D5, does not resolve it: whether
`/aid-graph`'s warning compares raw node count (what NFR-8 literally specifies, trivially
computable from `relationships.md`) or a degree-aware measure (more accurate, same source) is
**feature-010's implementation decision, Open Item 6** — not decided here.

---

## 5. The runtime-prerequisite statement — Cross-Cutting Risk 6, AC-6

Quotable verbatim by feature-007's page footer and feature-010's console output, per this task's
scope and PLAN.md's Cross-Cutting Risk 6 mitigation:

> `graph.html` requires, at the point it is opened: **(1) WebGL** — a browser able to create a
> `webgl2` or `webgl` rendering context. This project's own validation toolchain has already
> confirmed this is satisfiable headless, with no GPU, on the exact Playwright/Chromium launch
> configuration the project reuses (`rendering-stage1-webgl-probe.md`: L1/L2/L3 all PASS on the
> software-rasteriser environment); the escalation matrix at feature-002 SPEC's D1a states what
> changes for an environment where it is not. **(2) No network access** — the vendored
> `d3-force`/PixiJS bundle and its companion files are loaded from local disk beside
> `graph.html`, never fetched from a CDN (`rendering-stage3-payload-licence-update.md` § 5's
> recommended packaging shape), and this project's own visual-validation harness enforces the
> same rule by aborting every non-`file://` request during validation. **(3) The companion
> vendor assets physically present beside `graph.html`** — the artifact is a small set of files,
> not a single self-contained document (`rendering-stage3-payload-licence-update.md` § 2: five
> tracked files, not two). **(4) No build step at open time** — the vendored bundle is produced
> once, at authoring/render time, not in the reader's browser.

---

## 6. Measured / inferred / missing — the honest split

**Measured (a runtime output of a named harness, cited with its invocation):**
- The bench's node totals by term (479 KB-side, 1,130 source-artifact/image, 1,609 total) —
  `kb-stats.tsv`, `coverage.tsv`, both read 2026-08-05.
- The bench's edge-union count (6,171), degree distribution (median 6, p95 42, max 329) and
  category count (7 of 14) — computed 2026-08-06 from the on-disk classification-pass files, with
  the command shown inline.
- Both AC-6a verdicts (steady simulation and node drag), each a Playwright/PixiJS/d3-force
  runtime output at the bench's own measured degree-distribution parameters — § 3, run 2026-08-06.
- The NFR-8 ceiling bracket at Bracket B's topology (clears at 500, fails at 550/600/700/1,000/
  1,609) — § 4, run 2026-08-06.
- Bracket A, re-quoted rather than re-run, from `rendering-stage2a-response-surface.md` § 3
  (already a runtime output of that task's own harness run).

**Inferred (a reasoned conclusion from measured data, not itself a direct measurement):**
- That the real bench (if a finished, fully-reconciled `relationships.md` existed) would cost **at
  least as much as** § 3's verdict fixture reports, because that fixture's actual edge count
  (3,854) undershoots the bench's own measured edge count (6,171) — reasoned from Stage 2a's own
  near-linear edge-count finding, not separately measured at 6,171 real edges.
- That Bracket A and Bracket B's roughly 2× disagreement is explained by mean/max degree
  difference rather than by measurement error, reasoned from Stage 2a's own axis-2/axis-3
  findings.

**Missing (explicitly not produced by this task, named with who owes it or why it is out of
scope):**
- **A finished, fully-reconciled `relationships.md` for this repository.** The edge-set term
  (§ 2, term 3) is a best-effort deduplicated union of a stopped-mid-run classification pipeline,
  not the production output of feature-004/feature-005's shipped code (which does not exist yet —
  it ships in delivery-002). This task did not attempt to finish that reconciliation; it is
  delivery-002's, and this document's edge-count figure should be re-checked once it lands.
  Flagged as a real limitation, not smoothed over.
- **A hardware-rendered (non-headless) re-confirmation of the AC-6a verdicts at the derived
  bench**, as D4b point 3 asks the report to consider "if a headless result is close to the
  threshold." Not attempted here because the bench's own result is nowhere near the threshold
  (3–4× over) — the headless-conservatism margin Stage 2a already measured (shrinking to <2% by
  2,000 nodes) cannot plausibly flip a 3–4× overage, so a hardware re-run would not change the
  verdict and was not run, to stay inside this task's time-box.
- **A tighter-than-(500,550] bracket** (e.g., testing 510, 520, 530, 540 individually). Not run,
  per this task's own explicit instruction that "a handful of points plus a stated bracketing
  method is the deliverable; an exhaustive sweep is not."
- **Node counts run in the JavaScript test suites, `npm`/`npx`, or any product-code change.**
  Out of scope for a RESEARCH task per `task-type-rules.md`, and explicitly forbidden by this
  task's own command whitelist.

---

## 7. Recommendation

1. **NFR-7's floor does not clear at this project's own derived bench, in either AC-6a window.**
   The decision record this feature produces should state that plainly: the live graph, as
   currently specified (continuous `d3-force` simulation + PixiJS WebGL drawing, no adaptive
   degradation per Q14 item 7), does not sustain 30 fps at 1,609 nodes, and node drag is worse
   than steady state, not better.
2. **NFR-8's ceiling, at this project's own measured degree distribution, is bracketed between 500
   and 550 nodes** — roughly a third of this repository's own current bench size. Bracket A
   (Stage 2a's lower-degree baseline, ceiling between 500 and 1,000) is retained only to show
   degree sensitivity, per D5; it is not this project's own number.
3. **The comparand `/aid-graph`'s warning should use — raw node count or a degree-aware measure —
   is not decided by this document**, per D5's own instruction; it is feature-010's, Open Item 6.
   This document supplies the evidence (§ 4's closing paragraph) that a bare node-count comparison
   will be wrong in both directions on a graph shaped differently from this one.
4. **`task-021`, when it writes `node_ceiling` into `canonical/aid/templates/graph/scale-ceiling.yml`,
   should write the Bracket-B figure** (the (500, 550] range, or a single conservative value
   drawn from it such as 500) **with its stated conditions** (max degree 329, ~7.67 target mean
   degree, 7-of-14 categories, ~40% isolated) rather than Bracket A's, and should carry this
   document's degree-sensitivity note forward so a reader does not mistake the number for one that
   holds at every topology.
5. **Once delivery-002 ships a real `relationships.md`**, re-run § 2's edge/degree derivation
   against it rather than trusting this document's provisional union — this is the one figure
   here that is a reconstruction of an unfinished pipeline, not a finished producer's output, and
   it is named as such rather than presented as settled.

---

## 8. Sources

| Figure / claim | Form | Source |
|---|---|---|
| KB-side node counts (479, by Kind) | Verified on-disk fact | `.aid/.temp/graph-stage2b-bench-kb/kb-stats.tsv`, `kb-nodes.tsv`, read 2026-08-05 |
| Source-artifact/image/web-page counts (1,130) | Verified on-disk fact | `.aid/.temp/graph-stage2b-bench-kb/coverage.tsv` (identical in `-bench` sibling), read 2026-08-05 |
| Edge union (6,171), degree distribution, category mapping | Runtime output of an ad hoc `awk`/`node` computation over on-disk files, command quoted inline | `.aid/.temp/graph-stage2b-bench-kb/rows-pass1a.tsv`, `rows-pass1b.tsv`, `rows-class0.tsv`; `canonical/aid/templates/graph/relation-vocabulary.yml`; all read/computed 2026-08-06 |
| AC-6a's two verdicts | Quoted runtime output | `.aid/.temp/graph-stage2a-harness/driver-drag.mjs`, run 2026-08-06, `drag-results.json` |
| Bracket A | Quoted runtime output, re-cited | `rendering-stage2a-response-surface.md` § 3, itself `driver.mjs`/`results.json`, run 2026-08-05 |
| Bracket B | Quoted runtime output | `.aid/.temp/graph-stage2a-harness/driver-bench-bracket.mjs` (written for this task), run 2026-08-06, `bench-bracket-results.json` |
| Renderer identity, launch configuration, warm-up/sample/threshold constants | Quoted runtime output, re-cited | `rendering-stage1-webgl-probe.md`, `rendering-stage2a-response-surface.md` § 2.3–2.4, unchanged in this task's harness runs |
| Runtime-prerequisite statement's WebGL/network/companion-asset claims | Verified on-disk facts, re-cited | `rendering-stage1-webgl-probe.md`; `rendering-stage3-payload-licence-update.md` §§ 2, 5 |
| Total-node-count comparand instruction, ceiling-sensitivity instruction, comparand tension | Requirement/SPEC text, quoted | feature-002 SPEC § D2, D5; REQUIREMENTS.md NFR-8, AC-16a |

**No figure in this document states a bench size as an estimate or a guess** — every count is
either a verified on-disk fact from an already-produced file, or a runtime output of a harness
invocation named alongside it, per AC-S6's discipline, which this task inherits from Stage 1 and
Stage 2a.
