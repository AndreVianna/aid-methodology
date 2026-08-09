# Graph Rendering Viability & Performance Validation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.6 (FR-18), §8 (D-2), §10 (deliverable 1); STATE.md Q2 | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned to amended FR-16 — packaging constraints withdrawn, option space unrestricted; added accessibility-cost and scale-tension criteria | /aid-specify |
| 2026-07-28 | Dependency position re-scoped after the feature-011 three-way split — feature-012 is conditionally gated on this research and feature-013 transitively, so neither is listed as proceeding without it | /aid-specify |
| 2026-07-28 | Gate finding 2 [MEDIUM] fixed — the § Requirements baseline note no longer claims the requirements half is stale; decision record extended to trace the two criteria added by that realignment, and the rejected-alternatives clause restated against the current first criterion | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the vendored-library obligations, the drafted stack entry, the manifest impact and the packaging wiring are now **feature-012**'s, and the drafted `technology-stack.md` / `infrastructure.md` entries land at ship time by **feature-013**. feature-011 keeps only the validator-parameterisation carve-out. No decision in this SPEC changes | /aid-specify |
| 2026-07-29 | **Re-specified against the amended REQUIREMENTS.md (A+, six adversarial cycles, then twice corrected; STATE.md Q9–Q19) and against the four A+ SPECs it now depends on. The entire premise of the previous revision is superseded, not adjusted.** FR-18 no longer asks which renderer to use: the architecture is **decided** — `d3-force` for physics plus **PixiJS (WebGL)** for drawing, 2D, the split Obsidian's graph view uses — and what remains is a **viability-and-performance validation** in FR-18's fixed order. Both halves of this SPEC are rewritten. (1) **The option space is closed and every clause resting on it is struck**: the twenty-five-cell comparison matrix, the six renderer classes, the five packaging shapes as a scored axis, the five hard screens, the scale-versus-accessibility tension, and the accessibility-cost dimension — the last because Q9 made the canvas **visual-only** with WCAG AA carried by the table view (NFR-2), so "does this renderer yield accessibility-tree semantics" is no longer a selection question. (2) **Stage 1 is the WebGL-under-headless probe and it gates everything below it** (FR-18 item 1, C-5 as extended, Q14's standing risk). D1 specifies it as a **three-level** decidable probe — context, readable pixels, capturable pixels — because a context that exists and a canvas that screenshots are different facts and C-5's fallback differs per level; D1a states, per level, what a negative result changes in **C-5, FR-12 and the renderer decision**, with owners. (3) **No bench size is stated anywhere, and the derivation is specified instead** (A-5 void, NFR-7 states no count). D2 shows the bench has **three** terms, all outputs of delivery-002's spine, and names the producer of each: the source-artifact term needs feature-004's enumerator, the KB term needs feature-005's Pass 1a, and the degree distribution needs Q13's concept merge. D-2a originally named feature-005 alone; **it was corrected the same day, in response to this finding, to state three terms with two producing features**, so the requirements and this SPEC now agree. (4) **The KB term cannot be the `CONFIRMED` token count** — D2a records the verification: the KB figure A-5 then stated took its `fact` component from occurrences of the **bare token** `CONFIRMED` (227 on the read date), precisely the count feature-003 D2a-2 forbids an implementation from treating as facts, while only **33** lines carry both `CONFIRMED` and `(search:`. Q17's defect class surviving the cycles that withdrew 583 and corrected 641. **Corrected upstream the same day**: A-5 now states no KB figure and carries the finding, the root was traced to the change-log entry where the fact definition was first recorded, FR-18 item 2's figure went with it, and REQUIREMENTS.md's own A+ was reopened over it. (5) **The serialisation D-2a forces is answered by a two-stage split** (D2b): a **parametric response surface** measurable now over the axes it lists, and a **verdict** read off it once the bench lands — so NFR-7's answer is a lookup rather than a second spike. (6) **The measurement set is rebuilt around what the superseded work never measured** (D4): per-edge **arrowheads** (the graph is directed — Q11), **four line styles** (NFR-5's non-colour carrier, whose per-frame cost was argued and never measured — a claim NFR-5 **withdrew** the same day and reassigned to this research as a verdict it owes), **hover labels** at the max-degree worst case (text, measured for the first time), **category filtering** at the vocabulary's full category count (feature-001 Open Item 11, routed here and closed here), and **node drag** (NFR-7 gates it and no prior harness drove it). (7) **Two mechanical hazards found on disk and priced** — `contrast-check.mjs` reads only CSS custom properties, so a palette living in drawing code is silently unchecked while SC 1.4.11 still binds (D8); and **all four** of `.js`, `.mjs`, `.html` and `.css` are in `render.py`'s `_TEXT_EXTENSIONS` — the breadth is the point, since it is what pulls a vendored bundle in — so that bundle is **text-transformed** into five profiles and the render-drift gate cannot see the corruption (D7). (8) **AC-21 is validated without the canvas** (D9), which is what makes it survivable if Stage 1 lands negative. Reused rather than re-paid for, per delivery-001's supersession banner: the fixture methodology (hub seeding, isolated nodes deliberately kept), the generated-tree exclusion reasoning, and the "nothing watches a JavaScript dependency" baseline — the last re-verified on disk. **The title changes** from "Graph Rendering Approach Research", which asserted a selection this feature no longer performs. Thirteen Open Items: two to the REQUIREMENTS amendment pass *(both discharged the same day — see the row below)*, two to feature-007, one each to features 003, 008, 009, 011, 012 and 013, one to feature-010, one to the PLAN.md amendment pass, and one to the work owner | /aid-specify |
| 2026-07-29 | **Realigned to the five corrections the requirements took the same day, after the gate found four places where this SPEC still described the pre-correction state.** A-5 now states **no** KB figure and carries the 227-bare / 33-anchored finding; D-2a now states **three** bench terms with **two** producing features; NFR-5 has **withdrawn** the unmeasured "line style costs nothing per frame" and reassigned it here as a verdict this research owes; FR-18 item 2 no longer quotes a figure. Changed: D2 restated to describe the current D-2a and to record that it was corrected in response to this feature, so its dependency statement no longer claims to be "stronger than" the requirements; **Open Items 1 and 2 retired as discharged**, each naming what landed upstream, so neither can be closed-without-doing nor re-applied over corrected text; the Q20 preamble restated because the reopen it predicted has already happened; D2a retitled and reframed from "the requirements assert a wrong figure" to the verification that corrected them, with every command, count and read date left intact; the withdrawn-figure inventory extended to name 616 and the ~1,200 composite alongside 784, 641 and 583; D4 measurand 4, D10 part 4, the § Source A-5/D-2a entries and the proxy-sweep row on the fact term all repointed at the corrected text; and every remaining **count-as-proxy** phrasing repointed at its set — D10 part 5's "five axes", the change log's "not two as D-2a says" (itself a miscount inside a sentence about a prerequisite set), and the four "seven `Kind` values" references, which now cite §5.2's **closed enum** because the same proxy shape was one of the defects corrected in the requirements. Also corrected: `_TEXT_EXTENSIONS` is quoted as **all four** of `.js`, `.mjs`, `.html` and `.css`, since the render-drift finding depends on the list's breadth rather than on any one member. No measurement, criterion, probe level, escalation, bench procedure or verified on-disk finding changes | /aid-specify |

## Source

- REQUIREMENTS.md §5.6 — **FR-18** (*rewritten 2026-07-29* — the renderer is **decided**, not deferred;
  `d3-force` + PixiJS (WebGL), 2D, true-3D rejected; the remaining task is a viability-and-performance
  validation in a **fixed three-item order**; the former option space and its static-SVG recommendation are
  superseded), **FR-16** (quality and interaction take priority over packaging; the research is *not* to
  narrow its option space to preserve packaging purity), **FR-17** (runtime JS is mandatory; `kb.html`'s
  no-runtime-engine rule does not bind this artifact), **FR-13 / FR-14 / FR-14a** (the four lenses, the
  always-live manual controls, and the specified filter axes and node gestures the measurement must exercise),
  and §5.6's **four numbered consequences** of dropping the packaging restrictions
- REQUIREMENTS.md §5.4 — **FR-6a** (filtering and highlighting by relationship category is a **required**
  feature with its own criterion, not a manual control), **FR-6b** (category governance; the palette does not
  grow with the category count)
- REQUIREMENTS.md §5.2 — the **ten**-column table and the **closed `Kind` enum** whose permitted values the renderer reads
  directly to choose node colour and shape; §5.3 — the per-kind id grammars, and the fact that a `concept` id
  is **not** document-scoped, which is why merging turns mentions into degree
- REQUIREMENTS.md §6.1 — **NFR-4** (reduced motion is the **fallback**, not the default: the default path
  animates continuously), **NFR-5** (colour never the sole carrier: node **shape**, edge **line style**,
  hover/selection labels, arrowhead-or-absence for direction — WCAG 2.2 SC 1.4.1, Level A; its
  "line style costs nothing per frame" clause was **withdrawn 2026-07-29** as never measured, and the
  line-style feasibility-and-cost verdict is now explicitly **owed by this research**), **NFR-6** (every
  interactive gesture has a keyboard equivalent; dragging exempt — SC 2.1.1, Level A), **NFR-7** (*new* — **≥30
  fps at the project's derived bench during both steady simulation and node drag**, measured headless through
  the Playwright harness FR-12 reuses; settle time reported, not gated; **no node count is stated**),
  **NFR-8** (*new* — the practical node-count **ceiling is measured and documented**, and the skill warns past
  it; no degraded mode is built)
- REQUIREMENTS.md §5.5 — **FR-12** (reuse `/aid-summarize`'s HTML toolchain at the script layer: single-file
  assembly, contrast checking, HTML output validation, **Playwright-backed visual validation**), **FR-9 / FR-9a**
  (where the artifact and its companions land), **FR-8a** (genericity: the validation may not key on this
  repository's content)
- REQUIREMENTS.md §7 — **C-5** (*extended 2026-07-29* — a **second, distinct failure mode**: Playwright
  provisioned *and still unable to draw*, because the headless browser has no GPU or no WebGL context; recorded
  as **the highest-risk open item in the work**, to be resolved *before* any performance measurement),
  **C-1** (withdrawn), **C-2 / C-3 / C-4** (canonical authoring, manifest lockstep, no forked validators),
  **C-8** (`graph.html` is deliberately not dashboard-reachable)
- REQUIREMENTS.md §8 — **A-5** (*void, and restated 2026-07-29 in response to this feature* — it now states
  **no** KB figure at all and records why: the 616 it previously called verified was built from the count
  feature-003 forbids, and 583, 641, 784 and the ~1,200 composite are withdrawn with it), **A-6** (self-built
  fixtures), **D-2** (implementation depends on this validation), **D-2a** (*new 2026-07-29, prerequisite set
  corrected the same day* — the bench now depends on the extraction **and enumeration** work: **three terms with
  two producing features**, which **serialises** features that used to run in parallel)
- REQUIREMENTS.md §9 — **AC-6** (*extended* — "renders successfully" now means the live simulation runs, and
  **WebGL support is itself a runtime prerequisite** that must be documented), **AC-6a** (*new* — the ≥30 fps
  criterion, "the criterion that makes 'live' testable"), **AC-8a** (at most **eight** distinct category
  colours; beyond that, colour reuse plus line style plus filtering), **AC-9** (as scoped — the DOM-level
  structural and a11y checks apply to the page and the table, not to the canvas), **AC-16a** (*new* — warn past
  the ceiling), **AC-21** (*new* — every interactive control keyboard-operable, SC 2.1.1)
- REQUIREMENTS.md §10 — deliverable 1, **and its own amendment**: "the rendering half of step 1 is no longer
  fully parallel with step 2, and `/aid-plan` must re-sequence rather than reuse this shape"
- STATE.md `## Cross-phase Q&A` — **Q9** (the liveness decision, the reference architecture, the visual-only
  canvas, and why three review cycles and an A+ gate missed it), **Q11** (directed edges; the dropped persistent
  labels; hover/selection naming; the ~8-colour and ~4-line-style design ceiling), **Q12** (asymmetric
  granularity; the voided scale basis), **Q13** (the concept merge rule, and that the bench must be derived
  **after** it is implemented), **Q14** (the ten columns; the `Kind` enum; item 7's measure-document-warn ruling;
  and the standing technical risk to check first), **Q15** (every node count withdrawn from the requirements;
  the bench is a research deliverable), **Q17** (the proxy-keyed defect class and its standing sweep
  instruction), **Q18 ruling 3** and **Q19** (*"if there is a defect, the A+ is false"* — a gated SPEC is
  reopened whenever a real defect is found in it), **Q20** (an Open Item routed **into** a gated SPEC is a
  pending reopen, not a note). **Q2 is closed** — it asked which rendering approach the view uses, and Q9
  answered it by decision
- **feature-001's SPEC (re-specified 2026-07-29)** — treated as an **input**. It supplies the category count
  the filtering measurement must exercise and routes its **Open Item 11** here: the bench must exercise
  **fourteen** categories with filtering active, not the five the superseded bench was built against
- **feature-003's SPEC (A+, 2026-07-29)** — treated as an **immutable input**. Its **D2a-2** defines what a
  checkable source anchor is, and states in terms that this SPEC's D2a depends on that counting every
  `CONFIRMED` occurrence would manufacture nodes that resolve to nothing
- **feature-004's SPEC (A+, 2026-07-29)** — treated as an **immutable input**. Its enumerator and exclusion
  filter are the only thing that can produce the bench's `source-artifact` term
- **feature-005's SPEC (A+, 2026-07-29)** — treated as an **immutable input**. Its Pass 1a produces the bench's
  KB-side terms and its concept merge produces the degree distribution; its **D8** producer map is what bounds
  which relation categories a real bench can actually carry
- **feature-007's and feature-008's SPECs (not re-specified; on the pre-redesign baseline)** — read as
  consumers, not as inputs. Where a clause of either is void under the redesign, this SPEC records it as an
  Open Item and does not rely on it

**Measurement posture, stated once because it governs every figure below.** This feature's own prior output is
the reason this work forbids invented numbers: the superseded decision record's supporting figures included a
D3 layout time of **68 ms** that appears nowhere in its cited source, where the real value is 750 ms
(delivery-001 FINDINGS.md §5, and the change-log entry that withdrew it). So every quantity in this SPEC and in
the report it specifies is exactly one of three things, and which one is always visible:

1. a **runtime output** of a named harness, quoted with the harness and the invocation that produced it;
2. a **verified on-disk fact**, quoted with the command that reads it and the date it was read;
3. an explicitly-labelled **quantity the validation must produce** — a hole with a shape, never a placeholder
   filled in with a plausible number.

There is no fourth category. A figure with no attribution is treated here as a defect of the same class as the
68 ms, not as an approximation. **AC-S6** makes that a checkable property of the delivered report rather than an
instruction to its author.

**Dependency position.** This is the second of the two RESEARCH features, and its position changed materially on
2026-07-29. It still **blocks only feature-008** outright, so the decoupling that justifies keeping it separate
from feature-001 holds: if this validation stalls, `relationships.md` and the gap ledger still ship (§10). What
changed is the other direction — **this feature is now blocked in part**, by D-2a. Its Stage 1 (D1) and its
Stage 2a parametric surface (D2b) depend on nothing in this work and can run immediately; its Stage 2b verdict
depends on **feature-004's enumerator and feature-005's Pass 1a having run on a real repository** (D2), which
are delivery-002 outputs. Features 003, 004, 005, 006, 009, 010 and 011 proceed without it. **feature-007**
proceeds — the shell, the loader and the lens layer are renderer-independent — but two of its clauses are void
under the redesign and are routed as Open Items 4 and 5. **feature-012**'s dependency-packaging gate is
conditional on this validation's payload, licence and update findings; **feature-013** is gated transitively.

## Description

This is a **RESEARCH feature. Its output is a decision record, not shipped code** — but the decision it records
is no longer *which* renderer. That was settled by owner decision on 2026-07-29: physics by `d3-force`, drawing
by PixiJS on WebGL, two dimensions, the same split Obsidian's graph view uses. A true-3D orbit camera was
considered and rejected. What this feature now produces is the evidence that the decided architecture **works
here**, and the numbers that make the requirements' own acceptance criteria testable.

That is a different job from the one this feature previously did, and the difference is not a matter of emphasis.
The previous revision scored six renderer classes against five packaging shapes on twelve dimensions and
recommended a **static** SVG graph that settles once before first paint and never animates. That
recommendation is withdrawn: it satisfied neither NFR-4, whose reduced-motion clause only means something if the
default path animates, nor FR-16, which directs this research to optimise for interaction quality. Everything in
this SPEC that existed to support a comparison — the matrix, the screens, the renderer-class trade-offs, the
accessibility-cost dimension — is gone, because there is nothing left to compare.

**The order of the work is fixed by the requirement, and the first item is the largest unknown in the work.**
FR-12 commits `/aid-graph` to reusing `/aid-summarize`'s Playwright-backed visual validation. C-5 already
required that toolchain to degrade gracefully when the browser is not provisioned. A WebGL renderer introduces a
second and different failure: the browser *is* provisioned and still cannot draw, because a headless machine has
no GPU. Whether the harness can validate a WebGL canvas at all is therefore established **first**, before any
performance measurement, because a negative answer changes either the renderer or the constraint — and
measuring the frame rate of something the harness cannot see would be work spent on the wrong question. This
SPEC treats that probe as three separate facts rather than one, because "a WebGL context exists", "a draw
produces pixels a program can read" and "those pixels appear in a screenshot" are independently true or false,
and each failure has a different and cheaper remedy than the one below it.

**The bench is a finding this feature owes, and it cannot be counted from files.** Every node count previously
in circulation is withdrawn — 784 as the superseded basis, 641 as an arithmetic error, 616 as built from the
token count feature-003 forbids (D2a), 583 as unreproducible and inherited from research known to contain
fabrications, and the ~1,200 composite that inherited the same fact term. The requirements now deliberately
state none, and A-5 was restated on 2026-07-29 to say so explicitly. And the bench
cannot be recovered by counting the repository, for a reason that is about graph shape rather than arithmetic: a
concept named in five documents is now **one** node with five edges, so repeated mentions become **degree**, and
layout cost is a function of the degree distribution far more than of the node total. A representative bench
therefore requires the merged concept nodes to exist, which means it is an output of the extraction work rather
than an input to it. This SPEC states that dependency exactly — **three** terms with **two** producing features,
which is what D-2a now says after being corrected in response to this feature — and splits the measurement so
that the part which does not need the bench is not held hostage to the part that does.

**The measurement set is built from what the superseded work did not measure.** It measured node and edge paint
on an undirected, unlabelled, five-category graph. The graph this work is building is **directed**, so every
asymmetric edge carries an arrowhead; its relationship category is carried by **colour and line style**, whose
per-frame cost was argued rather than measured — NFR-5 withdrew that claim on 2026-07-29 and made the verdict
this research's, and legibility across the zoom range was never tested either; its relationship
names appear on **hover**, which means text — the one thing the prior work never measured at all, and the thing
Obsidian avoids paying for entirely by drawing no edge labels; and it must stay usable across a category count
that exceeds any palette, which makes **filtering** part of the interaction being measured rather than a feature
layered on afterwards. Node drag is gated by NFR-7 and was never driven by any harness. Each of these is a cost
that the decided architecture may absorb easily or may not, and the honest position is that nobody knows yet.

Finally, this feature owes three findings that have nothing to do with performance and everything to do with
what the project takes on: what the delivered artifact weighs, what its licences oblige, and who notices when
upstream moves. The last is the sharpest, because the answer today is nobody: the repository's only dependency
watcher covers GitHub Actions and nothing else, so no JavaScript dependency — vendored, pinned or fetched — is
watched by anything.

## User Stories

- As the **AID methodology owner**, I want to know before any implementation begins whether our own test
  harness can see a WebGL canvas at all, so that I find out now rather than after a feature is built against an
  architecture we cannot validate.
- As the **AID methodology owner**, I want a negative result from that probe to arrive with its consequences
  already worked out — what it costs the constraint, what it costs the toolchain reuse, and what it costs the
  renderer decision — so that I am choosing between stated options rather than reopening the question from
  scratch.
- As a **maintainer/architect**, I want the performance floor measured on a bench derived from this project's
  real graph rather than an assumed size, so that a passing measurement means something about the artifact I
  will actually open.
- As a **maintainer/architect**, I want the things the graph actually draws — arrowheads, four line styles,
  hover labels, a filtered view over more categories than a palette can hold — measured rather than assumed
  cheap, because the last time a rendering cost was assumed cheap it was the one that was never measured.
- As a **maintainer/architect**, I want the practical node-count ceiling published as a number, so that the
  warning the skill emits past it is a real threshold rather than a gesture.
- As the **AID methodology owner**, I want the licence, payload and update obligations of the adopted libraries
  written down before adoption, and I want "who notices when upstream moves" answered with a mechanism rather
  than an intention.
- As a **KB reviewer**, I want every figure in the report to trace to a command or a harness run, so that I can
  re-run it rather than trust it — this feature's own history being the reason.
- As a **person who navigates by keyboard**, I want the keyboard route to the graph's controls proven to work
  independently of whether the drawing surface renders, so that a rendering failure is a loss of illustration
  rather than a loss of access.

## Priority

Must

## Acceptance Criteria

Completion criteria for the validation. This feature ships a decision record, so its criteria are deliverables
and checkable properties of them rather than runtime behaviour. They are **SPEC-authored** — no requirement
states them, so they carry no requirement number — and they use the `AC-S<n>` scheme feature-003 introduced and
features 001, 004 and 005 have since adopted. The four requirement-originated criteria this feature is
answerable for are stated last, because each is decided at runtime by another feature and this one supplies the
figure or the statement that makes it decidable.

- [ ] AC-S1: Given the Stage-1 probe, when it is **run** rather than reasoned about, then it reports a verdict
      at each of D1's three levels — context, readable pixels, capturable pixels — together with the WebGL
      renderer identity string the browser reports, for **each** environment in D1's environment set, and every
      verdict is a runtime output carrying the invocation that produced it.
- [ ] AC-S2: Given a **negative** verdict at any level, when the report states its consequence, then it names
      what changes in **C-5**, in **FR-12's reuse of the visual-validation toolchain**, and in **the renderer
      decision**, per level, each with a named owner and each with the alternative that was considered and not
      taken — so that no negative outcome arrives as an open question.
- [ ] AC-S3: Given the report, when it is searched for a bench size, then **no node count, edge count or degree
      figure appears except as the output of a named producer run** (D2's three terms), and the derivation
      procedure is stated in enough detail that a second party can re-derive it and get the same numbers.
- [ ] AC-S4: Given the Stage-2a measurements, when they are read, then frame time is reported as a **function**
      of **each axis D2b lists** rather than at a single point, so that the Stage-2b verdict at the eventual
      bench is a lookup on the measured surface rather than a second spike.
- [ ] AC-S5: Given the Stage-2 harness, when its drawn content is inspected, then it exercises **every measurand
      in D4's set** — including per-edge arrowheads on asymmetric edges, four distinguishable line styles, hover
      labels instantiated at the fixture's **maximum-degree** node, and category filtering at the full category
      count feature-001's vocabulary declares — and the report states a verdict for each, never a blanket one.
      **D4's list is authoritative, not its cardinality**, so this criterion does not become wrong when a
      measurand is added.
- [ ] AC-S6: Given any figure anywhere in the report, when its attribution is checked, then it is a quoted
      runtime output with its harness and invocation, a verified on-disk fact with its command and read date, or
      explicitly labelled as a quantity still to be produced. **No figure is unattributed, and no figure is
      carried over from the superseded record without being re-measured.**
- [ ] AC-S7: Given NFR-7's floor, when the report states how it was measured, then it gives a **frame-time
      predicate** — the statistic, the sample window, and the threshold in milliseconds — applied separately to
      **steady simulation** and to **node drag**, and it states whether a headless measurement is admissible as
      the acceptance measurement or whether AC-6a additionally requires a hardware-rendered confirmation.
- [ ] AC-S8: Given layout settle time, when the report presents it, then it is **reported and not gated**, and
      the report says so explicitly — because a settle figure presented beside a gated frame rate invites being
      read as a second gate.
- [ ] AC-S9: Given NFR-8, when the report states the ceiling, then it gives both the **curve** and the single
      **threshold** the skill's warning compares against, and it names the quantity that is compared — because
      a warning keyed on a node total and a ceiling measured against a degree distribution would not agree.
- [ ] AC-S10: Given the payload finding, when it is stated, then it covers the bytes at **every tracked copy**
      — the canonical source and each profile render — and reports the **render-transform integrity verdict** of
      D7: whether the vendored bytes survive `render.py`'s text transforms unchanged.
- [ ] AC-S11: Given the licence finding, when it is stated, then each library's licence is read from its
      **upstream licence file at the evaluated version**, the version is exact ("latest" is not a value), and
      the report names **where in the delivered artifact** any required attribution appears.
- [ ] AC-S12: Given the update finding, when it is stated, then it names a **mechanism** and the party or
      process that acts on it, against the verified baseline that nothing watches a JavaScript dependency
      today; and it answers the second question D7 raises — who notices if the shipped copy stops equalling
      upstream.
- [ ] AC-S13: Given AC-21's keyboard obligation, when the report states its validation route, then that route
      is shown to be **independent of the drawing surface rendering**, so that it remains valid under every
      Stage-1 outcome including the worst.
- [ ] AC-6: Given the artifact as packaged, when the report states its **runtime prerequisites**, then WebGL
      support is named as one of them alongside network access, companion assets and build output, in prose a
      reader can act on. *(This feature supplies the statement; feature-007 and feature-008 satisfy the
      criterion at runtime.)*
- [ ] AC-6a: Given the derived bench, when the ≥30 fps floor is evaluated, then this validation has supplied
      both the bench and the measurement method, so the criterion is decidable without further research.
- [ ] AC-16a: Given a target project, when `/aid-graph` decides whether to warn, then this validation has
      supplied the documented ceiling it compares against. *(feature-010 owns emitting the warning.)*
- [ ] AC-21: Given every interactive control, when keyboard operability is verified, then this validation has
      supplied the route by which it is verified and shown that route survives a canvas that does not render.
      *(feature-007, feature-008 and feature-009 own the controls.)*

---

## Technical Specification

> The amended REQUIREMENTS.md (2026-07-29) is the authority for everything below. The renderer is an **owner
> decision** (Q9), not a finding of this feature, and nothing here reopens it — what this feature may do is
> report that it does not work, with evidence, which is a different act. Where this SPEC touches a contract
> another feature owns, it **consumes** rather than restates: feature-004 owns which non-KB nodes exist,
> feature-005 owns the KB-side node set and the merge, feature-001 owns the category set, feature-007 owns the
> page shell and the lens view-model, feature-008 owns the drawing code, feature-011 owns validator
> parameterisation, feature-012 owns the packaging wiring. Disagreement with any of them is recorded as an Open
> Item naming the owner, never as a silent divergence.

### Requirements baseline for this section

**The requirements half above and this section share one baseline: REQUIREMENTS.md as amended and twice
corrected on 2026-07-29.** The 2026-07-28 baseline the previous revision was written against is superseded in
its load-bearing parts, and the table below is the audit — what the previous revision relied on, and what
replaced it. It is recorded rather than deleted because a reader who has seen the earlier revision needs to know
that its absence is deliberate.

| The previous revision relied on | Status now | Replaced by |
|---|---|---|
| "The option space is **unrestricted**" (FR-18, 2026-07-28) | **Void** | FR-18 as rewritten: the architecture is decided; "the former option space is closed" |
| Six renderer classes × five packaging shapes, scored | **Void** | Nothing. There is no comparison. The packaging shapes survive only as a description of what the *decided* architecture must be delivered as (D6) |
| Five hard screens (WCAG reachability, single data path, NFR-4–6 capability, four lenses, licence) | **Void as screens** | Screens exist to eliminate candidates. With one architecture they become **obligations to verify**, and they reappear as measurands in D4 and as findings in D6 |
| "Accessibility cost" as a per-candidate dimension — whether the renderer yields accessibility-tree semantics or needs a hand-built proxy | **Void** | Q9: the canvas is **visual-only**; AA is met by the accessible table view as the conforming alternate version (NFR-2), and **no DOM proxy layer is built**. The proxy-line-count arithmetic that dominated the superseded record priced work this work does not do |
| The scale-versus-accessibility tension | **Void** | It was a tension between two candidate poles. Both poles are gone: the renderer is chosen and the accessibility route is chosen |
| "Node counts are bounded to the hundreds (FR-22, FR-23, **A-5**)" | **Void** | A-5 is voided; FR-23's granularity is widened; NFR-7 states no count and NFR-8 makes the ceiling a measured output (D2, D5) |
| A **static** SVG graph settling once before first paint | **Superseded** | FR-2 and FR-18: continuous simulation is the default; NFR-4's settled render is the reduced-motion **fallback** |
| Edge labels drawn every tick as the binding cost | **Superseded** | Q11 as amended: persistent labels dropped; category carried by colour + line style; the name shown on **hover or selection** (D4 measurands 4 and 5) |
| A five-category vocabulary | **Void** | feature-001's re-specified SPEC states **fourteen** categories, and routes the fourteen-category filtering bench here as its Open Item 11 (D4a) |
| `validate-visuals.mjs` T2 failing by design for an SVG graph | **Conditional and now not expected to fire** | A `<canvas>` matches none of its three selectors (verified — D1b). The live-surface exclusion feature-011 held in reserve is expected to be a **recorded no-op**, which Q9 already anticipated. The *hermetic-render* and *frame-timing* interactions with that script are new and are D1b's subject |

What the amendments did **not** touch still binds, and these are the real constraints on the validation:

| Still binding | Source | Effect on the validation |
|---|---|---|
| WCAG AA on `graph.html`, with the canvas visual-only and the table as the conforming alternate | NFR-1, NFR-2, Q9, AC-9 as scoped | Not a scoring dimension and not free: SC 1.4.1 (Level A) and SC 1.4.11 (Level AA) still bind the marks the canvas draws (D8) |
| Every interactive gesture keyboard-operable; dragging exempt | NFR-6, AC-21 | A validation route that does not depend on the canvas (D9) |
| Renders from `relationships.md` alone | FR-3, AC-10 | The harness's fixture is a `relationships.md` in §5.2's ten-column shape, not a bespoke JSON graph (D3) |
| Entry point `graph.html`, companions beside it under `.aid/knowledge/` | FR-9, A-4, C-8 | Bounds what "payload" means and where the artifact is opened from (D6) |
| Reuse the summarize script layer; do not fork it | FR-12, C-4, AC-17 | The harness measures **through** the reused scripts where it can, and every needed change is a parameterisation routed to feature-011 (D1b, D8) |
| Node.js ≥ 20; browser validation degrades gracefully when the browser is absent | C-5 | The probe's own fallback shape, and the floor any tooling inherits (D1) |
| Fixtures are self-built and independent of any work folder's contents | A-6, `CLAUDE.md` § Tracking discipline | D3's generator; and the report may not be cited by a permanent artifact (§ Layers & Components) |
| No relation type, node kind, carrier or threshold defined by what this repository contains | FR-8a | The bench derivation is a **procedure**, portable to any project with an approved KB; this repository is one instance of it (D2) |

### The validation boundary — what this feature does **not** produce

Stated first, because the previous revision's scope was much wider and a reader carrying it forward would look
for outputs that no longer exist.

- **It does not choose a renderer.** Q9 decided. This feature validates and, if the evidence demands, reports a
  failure to the owner. It does not re-open the comparison, and it does not evaluate 3D.
- **It does not build a degraded rendering mode.** Q14 item 7 and NFR-8: measure the ceiling, document it, warn
  past it. No adaptive degradation is designed here or anywhere.
- **It does not price an accessibility proxy layer.** Q9 made the canvas visual-only. There is no DOM proxy, so
  there is nothing to price.
- **It does not author the palette.** It states the contrast obligation and the mechanical hole in checking it
  (D8); choosing eight colours and pairing them with line styles is feature-007's and feature-008's, per
  feature-001 Open Item 7.
- **It does not write product code.** `task-type-rules.md` § RESEARCH: research produces documents only. The
  harnesses are throwaway and nothing from them ships.
- **It does not write to the Knowledge Base.** Drafted `technology-stack.md` and `infrastructure.md` content
  lands at ship time, by feature-013.
- **It does not derive the bench by counting files.** D2 explains why that is not an option and what replaces
  it.
- **It does not state a bench size.** Not once, anywhere. That is AC-S3, and it is the criterion most directly
  aimed at this feature's own failure mode.

### The three stages at a glance (FR-18's fixed order)

| Stage | Question | Depends on | Blocks | Deliverable |
|---|---|---|---|---|
| **1** | Can the Playwright toolchain FR-12 reuses validate a WebGL canvas at all, with no GPU? | Nothing in this work | **Everything below it** (FR-18 item 1) | D1's three-level verdict per environment; D1a's escalation matrix |
| **2a** | How does frame time respond to node count, edge count, maximum degree, category count and hover-label count? | Stage 1 at level 2 or better | Stage 2b | D2b's response surface; D4's per-measurand verdicts |
| **2b** | Does the **derived** bench clear NFR-7's floor, and where is NFR-8's ceiling? | Stage 2a **and** feature-004's enumerator **and** feature-005's Pass 1a (D2) | AC-6a, AC-16a | The bench numbers, the floor verdict, the ceiling |
| **3** | What does the project take on? | Nothing in this work | feature-012's packaging gate | D6's payload and licence findings; D7's update mechanism |

Two properties of this table are decisions, not description. **Stage 3 does not wait for Stage 1**, because
payload, licence and update obligations are data-independent and a negative Stage-1 result does not change what
PixiJS weighs or what its licence says — so a stalled probe does not stall the whole feature. And **Stage 2 is
split** rather than deferred whole: the alternative was to hold all performance work until delivery-002 lands,
which would serialise the entire feature behind the extraction spine for no gain, since four of D2b's five axes
are properties of a synthetic fixture and need no real data at all. That split is the author's decision and its
consequence for sequencing is Open Item 12.

### Data Model

**No database, no schema, no migration.** This feature ships a decision record. What follows specifies the
*shape of that record and the shape of the evidence behind it*, in the place of the table-and-column model a
runtime feature would carry here.

#### D1. Stage 1 — the WebGL-under-headless probe

**Why this is one item in FR-18 and three facts here.** C-5 as extended says a WebGL renderer may leave
Playwright "provisioned *and still unable to draw*". That sentence conflates three independently-checkable
conditions, and the fallback C-5 asks for differs for each. Treating them as one would produce a single
pass/fail whose failure mode is unknown, which is the least useful possible outcome for the work's
highest-risk item.

| Level | The fact | How it is decided | What it is necessary for |
|---|---|---|---|
| **L1 — context** | A WebGL rendering context can be created on a `<canvas>` in the harness's browser | `canvas.getContext('webgl2')`, falling back to `'webgl'`, is non-null; **and** the context is not lost immediately (`gl.isContextLost()` false after the first draw) | The renderer running at all. A negative here is the renderer-changing case |
| **L2 — readable pixels** | A draw call produces the pixels it was asked to produce, and a program can read them back | Draw a known figure of known colour on a known background; `gl.readPixels` a sampled set of coordinates and assert the expected values, including at least one coordinate that must be **background** so a uniformly-filled buffer cannot pass | Any measurement of drawing at all, and any assertion that the graph drew what it meant to |
| **L3 — capturable pixels** | Those same pixels appear in what the harness captures | Playwright `page.screenshot()` of the canvas element, and `canvas.toDataURL()`, each decoded and sampled at the same coordinates as L2 | FR-12's reuse of the **visual** validation specifically — a screenshot-based gate, and the human visual gate's evidence |

**The renderer identity is recorded alongside every verdict, and it is not optional.** The probe reads
`WEBGL_debug_renderer_info`'s `UNMASKED_RENDERER_STRING` and `UNMASKED_VENDOR_STRING` where the extension is
exposed, and records the raw strings verbatim. Without them a passing verdict is uninterpretable: a pass on a
software rasteriser and a pass on a discrete GPU are different facts with different consequences for Stage 2,
and the second half of D4b depends on knowing which one produced a frame time. Where the extension is not
exposed, that absence is itself recorded as the value.

**The environment set.** A verdict from one environment is not a verdict for all, and C-5's degradation applies
to developers and to CI alike. The probe runs, and reports separately, in each of:

| Environment | Why it is in the set | Verified basis |
|---|---|---|
| The CI `visual-fidelity` runner | It is where FR-12's gate actually runs, and the only environment whose configuration the project controls | `.github/workflows/test.yml` declares the `visual-fidelity` job on `ubuntu-24.04`, installing with `npm ci` then `npx playwright install chromium --with-deps` (read 2026-07-29) |
| A developer machine with Playwright provisioned | C-5's graceful-degradation obligation is a local-developer obligation too, and this work is being done on Windows | `playwright-provisioning.md` § "How to install locally" documents `npm ci` + `npx playwright install chromium` as the local path |
| A machine with Playwright **not** provisioned | The pre-existing C-5 case, included to confirm the extension did not disturb it | `validate-visuals.mjs` lines 119–146: a dynamic `import('playwright')` inside `try/catch`, printing `SKIP` and `process.exit(0)` on failure |

**The probe launches the browser exactly as the reused script does, and that is the whole point.** Measuring a
WebGL context under a launch configuration the project does not use would answer a question nobody asked. The
configuration, read from `canonical/aid/scripts/summarize/validate-visuals.mjs` on 2026-07-29:

```js
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});
```

Two verified properties of that configuration bear directly on the probe. **No GPU-related flag is passed** —
neither one that forces software rendering nor one that disables the GPU — so whatever WebGL support exists is
whatever Playwright's pinned Chromium provides by default on the host; the pin is `playwright: 1.61.1`, declared
as a `devDependency` with `engines.node >= 20` in `canonical/aid/scripts/summarize/package.json` (read
2026-07-29). And **the script blocks the network**: `page.route('**/*', …)` continues only URLs beginning
`file://` and aborts everything else (lines 195–202), which is a guardrail for `kb.html`'s self-containment and
is inherited here as a hard fact about how the graph will be validated.

**If a launch flag turns a negative verdict positive, that is a finding, not a fix applied quietly.** The probe
may re-run under additional flags to establish *whether* a software-rendering path exists at all — that is
useful evidence for D1a's remedy 1 — but any flag that becomes necessary is a **change to a shared reused
script**, which C-4 and AC-17 forbid forking and §5.6 consequence 1 requires to be parameterised rather than
weakened. So a flag that fixes the graph must not change `kb.html`'s render, and owning that parameterisation is
feature-011's (Open Item 8). The report states the flag, its effect on each level, and its effect on
`kb.html`'s existing T1–T4 results.

**What the probe is not.** It is not a performance measurement, and it must not be allowed to become one. Its
figure of merit is a set of booleans and two strings. It draws one figure, not a graph. It needs no fixture, no
vocabulary and no `relationships.md`, which is exactly why it can run before anything else in this work exists —
and why letting performance work precede it, which FR-18 forbids, would have been a choice rather than a
necessity.

#### D1a. What a negative verdict changes — the escalation matrix

AC-S2's substance. Each row states the consequence for **C-5**, for **FR-12's toolchain reuse**, and for **the
renderer decision**, plus the remedy and its owner. The rows are ordered from cheapest to most expensive, which
is also from most to least likely.

| Verdict | C-5 | FR-12's reuse | The renderer decision | Remedy, and owner |
|---|---|---|---|---|
| **L1 ✓ L2 ✓ L3 ✓** | Satisfied by the existing shape: the unprovisioned-browser skip is untouched and no second failure mode exists in this environment | Intact. The visual gate can see the surface | Untouched | Record the renderer identity string as evidence and move to Stage 2. **Owner: this feature** |
| **L1 ✓ L2 ✓ L3 ✗** — draws, but the capture is blank | Needs its **second** fallback, and it is a narrow one: a *screenshot* skip, not a validation skip | **Partially broken, and only the visual half.** Frame timing, interaction driving and DOM assertions all still work, because they never needed a screenshot | Untouched. The renderer draws; only the camera fails | Two candidates, and the report must choose between them on evidence rather than list them: (a) request `preserveDrawingBuffer` on the context and capture at a controlled point in the frame, which costs a documented per-frame penalty D4 must then measure; (b) treat the live surface as **capture-exempt** and substitute an in-page `readPixels` assertion as the machine check, with the human visual gate carrying what a screenshot would have carried. (b) leaves `kb.html` untouched and is the cheaper of the two; (a) preserves a screenshot-based gate. **Owners: feature-011** for the exemption's parameterisation, **feature-008** for (a)'s draw-loop consequence, **this feature** for the recommendation |
| **L1 ✓ L2 ✗** — a context exists and produces nothing readable | Needs a **skip with a recorded skip** at the validation level, not the screenshot level | **Broken for the graph.** Nothing the harness asserts about the surface means anything | **Not yet changed, but now conditional.** A context that draws nothing is indistinguishable from no renderer *in the harness*, but may draw correctly on a real machine — so the question becomes whether a hardware-rendered confirmation lane is acceptable as the acceptance path (D4b's second half) | Escalate: the owner chooses between a hardware lane for AC-6a and a renderer change. The report must state what each costs. **Owner: the work owner**, on evidence this feature supplies |
| **L1 ✗** — no WebGL context at all | The extension C-5 received on 2026-07-29 is confirmed as a **real, distinct failure mode**, and needs its own recorded state | **Broken outright** for the graph, which is what C-5 called "the highest-risk open item in the work" | **Changed.** FR-18's own words: "a negative result changes either the renderer or C-5" | Escalate with both options priced: (a) change C-5 — accept that the graph's surface is never machine-validated and rest on the human visual gate plus the DOM-level checks AC-9 already scopes to the page and table; (b) change the drawing layer while keeping `d3-force`, since the decided split is physics-plus-drawing and only the drawing half fails. The report must **not** choose (b) — that is a renderer decision and Q9 is the owner's. **Owner: the work owner** |

**One property of this matrix is load-bearing and is stated rather than left to be noticed.** In every row, the
**physics half is unaffected**. `d3-force` runs on the CPU and produces node positions with no graphics context
at all, which means the layout cost — the dominant cost at every scale the superseded work measured, and the one
thing its numbers were right about — is measurable under *every* verdict, including L1 ✗. So a total WebGL
failure does not zero this feature's Stage 2: it removes the draw term and leaves the layout term, and the
report says which of its measurements survived. That is why D4 separates the two rather than reporting a single
frame time.

#### D1b. The reused validators, re-read against a live WebGL surface

feature-007's SPEC already worked out which shared assertions a renderer choice disturbs, and this SPEC does not
restate that analysis. What it adds is the part that only appears once the surface is both **WebGL** and
**live**, which no previous reading covered.

| Script | What is already settled | What is new, and why |
|---|---|---|
| `validate-html-output.sh` **S2** (offline render) | Greps `<script … src="https?://` and `<link … href="https?://`; fails only if the packaging actually references a CDN | Nothing new. It is packaging-dependent, and D6 states the packaging |
| `validate-html-output.sh` **NM** (no-Mermaid-engine) | All three sub-checks are keyed on the literal token `mermaid`, so a non-Mermaid engine passes unchanged | **One cheap verdict this feature owes.** NM.1 fires on a non-`text/markdown` inline `<script>` over 100 KB *containing the token* `mermaid`. An inlined PixiJS bundle clears the size trigger comfortably, so whether NM.1 fires reduces to whether the token appears anywhere in the vendored bytes — a grep, and a measurand in D4 |
| `validate-visuals.mjs` **T1–T4** | Its collector builds its container list from `document.querySelectorAll('.diagram-box')` and `.infographic`, then walks `document.querySelectorAll('svg')` for any inline SVG outside those containers. A `<canvas>` matches none of those selectors, so the live surface is **not collected** and needs no exemption — which is what Q9 already recorded as turning the reserved carve-out into a no-op | **Two new interactions, both from liveness rather than from WebGL.** (i) The page is loaded with `page.goto(…, { waitUntil: 'domcontentloaded' })` and asserted immediately. A continuously-simulating graph has **not settled** at that point, so any measurement taken there samples an arbitrary early frame — harmless for a script that ignores the canvas, but fatal for any future check that does not, and directly relevant to how the harness must synchronise (D4b). (ii) Its hermetic `page.route('**/*', …)` handler continues only `file://` URLs and aborts the rest, so a CDN packaging renders **without its renderer** under this gate, whatever the engine — the packaging finding in D6 is constrained by the validator, not only by S2 |
| `contrast-check.mjs` | Extracts CSS custom properties and checks a fixed pair list | **A mechanical hole**, specified at D8 — the least visible of the interactions in this table, because its failure mode is a check that never runs rather than a check that fails |

#### D2. The bench — why it cannot be counted, and what produces it

**A-5 is void and NFR-7 deliberately states no count**, so the bench is this feature's to derive. D-2a states the
reason: concept **merging** (Q13) turns repeated mentions into graph *degree* rather than duplicate nodes, and
hub distribution is what layout cost depends on. **D-2a's first version named feature-005 alone; it was corrected
on 2026-07-29, in response to this specification, to state three bench terms with two producing features.** The
table below is that prerequisite set at the granularity a planner needs — which producer, which of its design
sections, and why no term is countable — and the requirements and this SPEC now agree on its shape:

| Term | What it is | Its only producer | Can it be counted from the filesystem? |
|---|---|---|---|
| **1 — the KB-side node set** | `document`, `section`, `fact` and `concept` nodes, after Q13's merge | **feature-005's Pass 1a** (its D2), which applies feature-003's slug rule (D2a-1), anchor-token grammar (D2a-2) and concept normalisation (D2a-3) | **No.** Each of those three algorithms decides what is and is not a node, and D2a below shows the difference is large |
| **2 — the source-artifact, image and web-page node set** | `int:` and `ext:` nodes passing FR-21's significance rule and surviving FR-22's exclusions | **feature-004's enumerator** (its D2, D2a, D4) | **No.** "Significance, not mere file existence" is a computed property, and the withdrawn 583 is the monument to guessing it |
| **3 — the edge set and its degree distribution** | Every row of `relationships.md`, and the degree of every node | **feature-005's Pass 1 and Pass 2**, typed through feature-001's vocabulary and feature-005's D3 edge-relation map | **No**, and this is the term whose merge-dependence D-2a explains. Degree is a property of the merge, not of the files |

**What this adds to D-2a, now that D-2a is corrected.** The requirement states the prerequisite set — three
terms, feature-004's enumerator and feature-005's Pass 1, plus Q13's merge for the degree distribution. What it
does not state, and does not need to, is *which* design section of each producer emits each term, or that term 1
is decided by three separate algorithms of feature-003 (D2a below shows how large that difference is). The
practical consequence is unchanged and no longer contested: a wider prerequisite set, the same serialisation,
answered by D2b's split rather than by a requirements amendment. **Nothing is routed from here.**

**What this feature does instead of counting.** It states the bench as a **procedure**, and runs it when its
inputs exist:

1. Run feature-004's enumerator on the target repository with FR-22's exclusions applied, and take its node
   count by `artifact_class` and by `Kind`. Record the ignore-list availability state, because FR-22's behaviour
   differs across its three states and the node set differs with it.
2. Run feature-005's Pass 1a on the approved KB, and take its `document`, `section`, `fact` and `concept` counts
   **after** the merge — plus the `fact-unanchored`, `section-empty-slug`, `concept-qualified` and
   `concept-merge-candidates` coverage rows, because each records nodes that were *not* produced and therefore
   bounds the difference between this count and any naive one.
3. Take the resulting `relationships.md` and compute, from the table alone (FR-3): node count by `Kind`, edge
   count by relation and by category, and the **degree distribution** — at minimum the maximum degree, the
   median, and the ninety-fifth percentile, because D2b's surface is parameterised on maximum degree and D4's
   hover-label worst case is instantiated at it.
4. State each figure with the command that produced it, per AC-S6, and state the tool version, because FR-11
   input 6 makes the installed tool one of the things that changes what is emitted.

**This procedure is portable, which FR-8a requires.** Nothing in it names this repository. Run on a project with
no glossary it yields zero `concept` nodes and a different degree distribution, and the bench is whatever it
yields — which is also why NFR-8's ceiling is stated as a curve rather than only as a number (D5).

**What may be reported before step 1 is possible.** Only the parametric surface of D2b, and it is labelled as
such. A synthetic figure presented as "the bench" would be the exact defect this SPEC's measurement posture
exists to prevent.

#### D2a. Why the KB term cannot be a `CONFIRMED` token count — the verification, and what it corrected

**A-5 formerly stated a KB-side figure of 616 and the brief for this re-specification treated it as verified. It
was arithmetically correct and semantically a proxy**, so it could not serve as term 1 of the bench. **A-5 was
restated on 2026-07-29 in response to this finding and now states no KB figure at all**; the derivation is kept
here, with every command and its read date, because it is what makes term 1 a procedure rather than a number —
and because a reviewer should re-run it rather than trust either document.

Read on **2026-07-29** in `/c/Projects/Personal/AID/.claude/worktrees/work-005-knowledge-graph`:

| Component of the figure A-5 then stated | Command | Result | Verdict |
|---|---|---|---|
| documents | `ls .aid/knowledge/*.md \| wc -l` | 21 | Reproduces |
| glossary concepts | `grep -cE '^#{3} ' .aid/knowledge/domain-glossary.md` | 32 | Reproduces |
| sections | `grep -rhE '^#{2,6} ' .aid/knowledge/*.md \| wc -l` | 336 | Reproduces — the figure counts headings at levels 2–6 and excludes level 1 |
| facts | `grep -roh 'CONFIRMED' .aid/knowledge/*.md \| wc -l` | **227** | **Reproduces the number and not the concept** — see below |

21 + 32 + 336 + 227 sums to the stated 616 exactly, so the composition was never in doubt. The `fact` term is the
problem. Two further counts, same date, same tree:

- `grep -rhE 'CONFIRMED.*\(search:' .aid/knowledge/*.md | wc -l` → **33**
- `grep -roh 'CONFIRMED.\{0,60\}' .aid/knowledge/*.md | sort | uniq -c | sort -rn` → the marker's most common
  forms are `CONFIRMED in`, `CONFIRMED:`, bare `CONFIRMED` on its own, `CONFIRMED via` and `CONFIRMED.` —
  including eleven occurrences of `CONFIRMED` with nothing following it at all

**Why that is a defect rather than a discrepancy.** FR-30 names the carrier as "inline durable anchors of the
form `CONFIRMED <path> (search: \"<token>\")`", and **feature-003 D2a-2 — gated A+ — states the exclusion in
terms that leave no room**: a citation naming a path with no anchor string "is not checkable — there is nothing
to grep for — and yields **no** fact node", and "an implementation that counted every `CONFIRMED` occurrence as
a fact would manufacture nodes that resolve to nothing, which is precisely what AC-1 exists to prevent."
The withdrawn `fact` term **was** that forbidden count. So the figure included a population the gated schema
forbids becoming nodes, and the true term is bounded above by it and unknown until feature-005 runs — which is
precisely what its `fact-unanchored` coverage row exists to report.

**This is Q17's defect class, and it is the fourth instance in this work.** A **count standing in for a set**:
`227` stood in for "claims carrying a checkable source anchor" while actually meaning "occurrences of a token",
and the substitution held only while the two were the same — which they never were. It survived the six
adversarial cycles that withdrew 583 as unreproducible and corrected 641 to 616, because those cycles checked
the arithmetic of the composition and not the semantics of a component.

**What it corrected upstream, so this section is a derivation and not an accusation.** On the same day, A-5 was
restated to state no KB figure and to carry this finding; the change-log entry that first recorded Q13's fact
definition — where the bare-token count entered before A-5 inherited it — was corrected at source; FR-18 item 2's
figure was removed with it; and **REQUIREMENTS.md's own A+ was reopened over it** under Q18 ruling 3. Nothing
remains routed from here (Open Item 2, retired).

**The consequence for this feature is narrow and total.** Term 1 of the bench comes from running feature-005's
Pass 1a, and from nothing else. No withdrawn figure — 616 included — may appear in the report as a bench or as an
estimate of one; where the history is worth recording, it is recorded as *this* derivation, labelled, with the
counts above and their commands. **AC-S3** is what enforces that.

#### D2b. The parametric response surface — what is measurable before the bench exists

D-2a's serialisation is real and this SPEC does not argue with it. What it does is bound the damage: the bench
determines **where on a curve** the artifact sits, and the curve itself is a property of the architecture and a
synthetic fixture. Measuring the curve now turns Stage 2b from a spike into a lookup.

**The five axes**, each varied independently over a stated range with the others held at a stated value:

| # | Axis | Why it is an axis rather than a constant | What the fixture varies |
|---|---|---|---|
| 1 | **Node count** | The obvious one, and the only one the superseded work varied (at two points) | Node total, holding mean degree fixed |
| 2 | **Edge count** | Edges dominate both the force computation's link term and the draw call count, and edge count is not a function of node count | Mean degree, holding node total fixed |
| 3 | **Maximum degree** | Q13's merge concentrates mentions into hubs. A force layout's per-tick cost and a hover neighbourhood's size both scale with the hub, not with the mean | Degree of the largest hub, holding node and edge totals fixed |
| 4 | **Category count** | Category drives colour and line style (NFR-5) and is the required filter axis (FR-6a). More categories means more draw-state changes, which is a batching question a GPU renderer is sensitive to | Number of distinct categories over the same edge set |
| 5 | **Concurrent hover-label count** | The measurand that has never been measured. Hovering focuses a *neighbourhood*, so the labels instantiated at once is a function of the hovered node's degree — worst case, axis 3's hub | Labels instantiated in one frame |

**Reported as a function, not as a point.** For each axis the report gives frame time at a minimum of four
sampled values, and states the shape it observed rather than fitting a curve it cannot justify. Four points is
the floor because two points cannot distinguish linear from super-linear, and the superseded work's two-point
bench is the reason that floor is stated.

**Layout and draw are reported separately at every point.** Three numbers per sample, not one: time in the
`d3-force` tick, time in the draw, and total frame time. The separation is what makes the surface survive a
negative Stage-1 verdict (D1a's closing note), and it is also the correction to the superseded record's clearest
real insight being buried — that the layout dominated and the drawing was nearly free. If that remains true, the
directed arrowheads, the line styles and the hover text change nothing and this feature can say so with
evidence; if it stops being true, the reason will be visible in which of the two terms moved.

**What the surface cannot tell us**, stated so it is not over-claimed: it cannot tell us where the real bench
sits on it, which is Stage 2b's job; and it cannot substitute for a measurement on a fixture whose *topology* is
representative, which is why D3's generator is shaped rather than random.

#### D3. The fixture — self-built, shaped, and in the delivered schema

**Self-built and independent of any work folder** (A-6, and the project's transient-work-folder rule). Nothing
in the harness reads `.aid/works/`.

**Reused from the superseded work, deliberately.** delivery-001's supersession banner lists what still stands
and should not be re-paid for, and two items apply directly: the **fixture methodology** — hub seeding, with
isolated nodes deliberately kept — and the **generated-tree exclusion reasoning**. Both are reused. The banner
also records why the methodology mattered: the first fixture was accidentally a straight line of nodes, which
made every layout timing meaningless. What is **not** reused is any fixture *size*, since those are the voided
figures.

**Isolated nodes stay in, and the reason is not aesthetic.** They are exactly what the Coverage lens and the gap
ledger exist to surface (FR-13, FR-20, FR-26), and FR-14a makes hiding them a deliberate act via the orphan
toggle. A fixture with no isolated nodes could not exercise either.

**The fixture is a `relationships.md`, not a graph JSON.** FR-3 and AC-10 make the ten-column table the single
input to the view, and feature-007's loader parses it. A harness fed a bespoke JSON structure would measure a
data path the product does not have, and would silently skip the parse cost. So the generator emits §5.2's
ten-column shape with valid `Kind` values from the closed enum, valid relation labels and inverses from the
loaded vocabulary, and `Provenance` values across all three — which additionally exercises FR-14a's provenance
filter axis.

**The generator is parameterised on D2b's five axes** and on nothing else, so that a point on the surface is
reproducible from its parameters. It records its seed, and the report states it, because a hub-seeded generator
that cannot be re-run to the same graph makes every figure unfalsifiable.

**One dependency the fixture cannot avoid.** Valid relation labels come from the vocabulary, and the file on
disk is the superseded one: `canonical/aid/templates/graph/relation-vocabulary.yml` carries **15 `- relation:`
entries and 5 categories** (read 2026-07-29), while feature-001's re-specified SPEC states 31 pairs / 57 entries
/ **14 categories** as its research finding, with authoring the file left as execution work. Until that file is
authored, the fixture's category axis is exercised against feature-001's **stated** count, and the report says
so — a labelled dependency on a specification rather than an invented vocabulary. This is D4a's subject and is
tracked as Open Item 3.

#### D4. The measurement set

The superseded work measured two things: node paint and edge paint, on an undirected, unlabelled, five-category
graph, at two node counts. Every row below except the first two is new, and each is new because a **requirement**
changed rather than because more rigour seemed prudent.

**The list below is authoritative; its length is not.** Stated because Q17's instruction applies to this SPEC's
own clauses, and a criterion reading "all nine measurands" would silently become wrong the moment a tenth was
warranted — the same count-standing-in-for-a-set defect FR-11 corrected in four of its own clauses. AC-S5 is
therefore keyed on the set.

| # | Measurand | Why it is measured | Requirement | Never measured before because |
|---|---|---|---|---|
| 1 | **Layout tick cost** | The dominant term at every scale the prior work sampled | NFR-7 | — (it was measured; the figure is void because the bench is) |
| 2 | **Node draw cost**, across **every value of §5.2's closed `Kind` enum** with shape **and** colour | Node shape carries kind alongside colour (NFR-5), so nodes are not uniform circles | NFR-5, §5.2 | The prior graph drew one node type |
| 3 | **Directed-edge draw cost — arrowheads on asymmetric edges, none on symmetric** | The graph is **directed** (Q11), and a symmetric relation renders with no arrowhead, the absence being the signal (Q14 item 5). Arrowhead geometry is per-edge work | FR-2, NFR-5, Q11 | The prior graph was undirected — Obsidian's is, and it was inherited |
| 4 | **Four line styles — solid, dashed, dotted, dash-dot** | Category's non-colour carrier (NFR-5). **And a feasibility verdict, not only a cost:** whether the drawing layer provides distinguishable dash patterns natively, at what per-frame cost, and whether four remain distinguishable at the zoom range FR-14's controls reach. The claim that "line style costs nothing per frame" was argued when NFR-5 was retained, **never tested, and withdrawn from NFR-5 on 2026-07-29** — which makes this measurand the place the requirements now expect that verdict to be paid | NFR-5 as amended, and the 2026-07-29 retention decision | The prior encoding used persistent labels, which were then dropped |
| 5 | **Hover labels — text, at the maximum-degree worst case** | Hover shows the relationship name (Q11 as amended), and hover focuses a *neighbourhood*, so the hovered hub's degree sets how many labels appear at once. **This is the measurement the prior work never took at all**, and Obsidian is fast partly *because* it draws no edge labels, so the reference architecture is not evidence here | FR-2, NFR-5, Q11 | It measured node and edge paint only, and never text |
| 6 | **Node drag** | NFR-7 gates the frame rate **during node drag**, not only during steady simulation. Dragging re-heats the simulation and pulls neighbours, so it is the most expensive interaction the artifact has | NFR-7, AC-6a | No harness drove an interaction |
| 7 | **Category filtering at the full category count** | FR-6a makes filtering **required**, and at fourteen categories over an eight-colour bound it is load-bearing for basic legibility rather than a convenience. Both the **steady** cost of a filtered view and the **transition** cost of toggling a filter are measured, because a re-projection plus a redraw is a spike, not a steady-state cost | FR-6a, AC-8a, FR-14a | The prior bench had five categories and no filtering |
| 8 | **Reduced-motion settled render** | NFR-4's fallback must still work, and it is now the *fallback* rather than the whole behaviour. Settle-to-static must produce the same picture the live path converges to | NFR-4, AC-9 | It was the only behaviour, so there was nothing to compare |
| 9 | **Vendored-bundle token and transform checks** | Two cheap mechanical verdicts with disproportionate consequences: whether the bundle contains the literal token `mermaid` (which decides whether NM.1 fires — D1b), and whether it survives `render.py`'s text transforms unchanged (D7) | §5.6 consequence 1, C-2, C-3 | The prior recommendation vendored four small modules and asked neither question |

**Every measurand is reported as a verdict of its own.** A blanket "performance is acceptable" would repeat the
structural failure Q9 diagnosed: the superseded record was complete, traceable and internally consistent while
answering the wrong question, and its gate passed because all eleven criteria tested completeness rather than
whether the artifact was alive. A per-measurand verdict is harder to satisfy vacuously.

#### D4a. The fourteen-category filtering case (feature-001 Open Item 11, closed here)

feature-001 routed this here and it is adopted rather than relayed. Its substance:

- The vocabulary's category count is a **stated research finding** of feature-001, and it is **fourteen**.
  AC-8a part 3 caps the palette at **eight** distinct category colours. Fourteen exceeds eight by six.
- So the encoding at the real category count is **colour reuse plus line style plus filtering**, and filtering
  is what makes the graph legible rather than what makes it convenient. Q11's design ceiling says the same from
  the other side: beyond roughly eight colours and four line styles, simultaneous distinction fails for all
  users.
- Therefore filtering is **part of the interaction being measured**. A frame rate measured on an unfiltered
  fourteen-category graph is not the frame rate of the artifact anyone will use, and a frame rate measured with
  filtering active but at five categories is not it either.

**What this feature measures, and what it does not.** It measures the *cost* of the encoding and of filtering at
the full category count (D4 measurands 4 and 7). It does **not** choose the eight colours, pair them with line
styles, or contrast-check them — that is feature-007's and feature-008's, per feature-001 Open Item 7, and D8
below states the obligation those owners inherit.

**One honest limit.** Whether a real bench even *carries* all fourteen categories is not this feature's to
assert: feature-005's D8 producer map records that ten of the vocabulary's thirty-one pairs have no producer,
and feature-001's W3 layer reports reachability **per project**. So the fourteen-category fixture is a
deliberate worst case, and the report states the difference between the worst case it measured and whatever the
derived bench turns out to contain.

#### D4b. The ≥30 fps predicate — how NFR-7's floor is measured headless

NFR-7 states the floor and the environment: "≥30 frames per second at the project's derived bench, during both
steady simulation and node-drag interaction, measured headless through the same Playwright harness FR-12
reuses." Three things have to be pinned before that is testable, and none of them is stated by any requirement.

**1 — The predicate.** "≥30 fps" is reported as a **frame-time distribution**, not a mean, and the report states
the statistic, the window and the threshold. A mean hides exactly the failure a reader cares about: a graph that
averages 40 fps while stalling for 200 ms whenever a filter is toggled is not a graph that sustains 30. The
predicate is applied **separately** to steady simulation and to node drag, because NFR-7 names both and they are
different workloads — drag re-heats the simulation and adds pointer handling on top of it. The report also states
its warm-up exclusion and justifies it, since the first frames after load include one-time costs that no steady
measurement should carry.

**2 — Synchronisation, which is a new problem created by liveness.** The reused validator loads with
`waitUntil: 'domcontentloaded'` and asserts immediately (verified, `validate-visuals.mjs` line 204). A
continuously-simulating graph has not settled at that moment, so a measurement taken there samples an arbitrary
early frame during the most expensive part of the layout. The harness therefore instruments **in the page** —
timing the tick and the draw from inside the frame loop and exposing the samples for the driver to read — rather
than inferring frame rate from outside. That is also the property that keeps the measurement alive under D1a's
L3 ✗ row, where nothing can be captured but everything can be timed.

**3 — What a headless number is evidence of, which depends on Stage 1's renderer string.** This is the part the
report must argue rather than assert, and the argument has a testable shape:

- The **layout** term transfers unconditionally. `d3-force` is CPU work with no graphics context, so a headless
  layout time is a layout time.
- The **draw** term does not transfer unconditionally. If Stage 1 reports a software rasteriser, the headless
  draw is expected to be *slower* than a hardware-rendered one — which would make a headless **pass** a
  conservative result (pass implies pass on real hardware) and a headless **fail** inconclusive. That
  asymmetry, if it holds, is what makes NFR-7's headless gate safe: it can only be too strict, never too
  lenient.
- **It is a hypothesis, and the report must test it**, not assume it. The test is one comparison: the same
  fixture at the same points, measured headless and measured once with hardware rendering available, with both
  renderer identity strings recorded. Software rasterisation avoids some transfer costs as well as adding
  others, so the direction is not guaranteed by argument.
- If the comparison shows headless is **not** conservative, then AC-6a needs a second lane and that is an owner
  decision, not an author one — **Open Item 13**.

**Settle time is reported and not gated.** NFR-7 says so, and Q13 flags the split as owed confirmation. The
report states it as a reported figure, with the words, so that a reader cannot mistake a number presented beside
a gated one for a second gate. **AC-S8** exists because that mistake is easy to make and free to prevent.

#### D5. The ceiling (NFR-8) and what the warning compares

NFR-8 requires the practical node-count ceiling to be **measured and documented**, and `/aid-graph` to **warn**
past it (AC-16a). No degraded mode is built (Q14 item 7).

**The ceiling is read off D2b's surface, not measured separately.** It is the point at which the frame-time
predicate of D4b stops holding, which is a property the surface already contains. Reporting it as a curve and a
threshold rather than only a threshold is what makes it portable to a project whose graph has a different shape.

**And the warning needs a comparand, which is where a naive ceiling would fail.** NFR-8 says "node-count
ceiling" and AC-16a says "when a target project's node count exceeds the documented ceiling". But D2b axis 3
exists because **maximum degree matters more than node total**, so a ceiling measured on one topology and
compared against a bare node count on another would be wrong in both directions: a large sparse graph would
warn needlessly, and a small hub-heavy one would not warn when it should. The report therefore states:

- the ceiling as a node count **at a stated degree distribution**, which is the form NFR-8's wording admits;
- the sensitivity of that ceiling to maximum degree, from the surface, so the number's fragility is visible;
- **the quantity `/aid-graph` should actually compare**, with the trade-off stated. A node-count comparison is
  what NFR-8 and AC-16a literally specify and is trivially computable from `relationships.md`; a
  degree-aware comparison is more accurate and is also computable from the same table. Which one the skill uses
  is **feature-010's** to implement and may be a requirements amendment — **Open Item 6**.

**This feature does not lower or raise NFR-8's obligation.** It measures, it documents, and it names the
comparand problem rather than resolving it silently by picking one.

#### D6. Payload, licence and attribution — Stage 3, part one

Three findings the validation owes, none of which depends on the bench or on Stage 1. Each is specified as *what
must be established and from where*, not as a value — every value here is a quantity the validation must
produce (AC-S6, AC-S11).

**The packaging shape is no longer a scored axis, but it still has to be stated**, because AC-6 requires the
runtime prerequisites in prose and because two of the reused validators are packaging-dependent (D1b). FR-16
permits multiple files, a CDN and a build step; FR-9 and A-4 fix the entry point at `.aid/knowledge/graph.html`
with companions in a subdirectory beneath it; feature-008's SPEC already places any vendored library at
`canonical/aid/templates/knowledge-graph/vendor/<name>/`. The report states the shape it recommends **for the
decided architecture** and prices it — which is a delivery question, not a renderer comparison.

**Payload is counted at every tracked copy, and that is six.** This is a consequence of C-2 and C-3 that the
superseded record never priced because it priced only the delivered `graph.html`. A file authored under
`canonical/` is rendered to **five** profile install trees by the existing generator, each carrying its own
`sha256` record in `profiles/*/emission-manifest.jsonl` (the mechanism feature-001 records as its P4, and which
the render-drift CI job gates). So a vendored bundle of *B* bytes adds roughly *6B* tracked bytes to the
repository, not *B*. The report states both figures and labels which is which, because they answer different
questions: what a reader downloads, and what the repository carries.

**The two libraries, and the exact obligation.** `d3-force` and PixiJS are both to be evaluated at an **exact
version**; "latest" is not a value. For each, the licence is read from the **upstream licence file at that
version** and not from a summary page, a registry field, or this SPEC. The superseded record's licence claims —
including that the D3 modules it vendored are ISC — are **inputs to verify, not facts to copy**; delivery-001's
own findings record that its first draft's D3 licence claim was itself corrected during review. The report then
states, per library: the SPDX identifier read from the file, whether attribution must appear in the delivered
artifact, and if so **where** — a comment block in the inlined script, a visible footer, an about panel, or a
companion file. Naming the place is the obligation; "attribution is required" is not an answer.

**One licence question the decided architecture raises and the previous one did not.** The redistributed unit is
a file generated into a **third party's** repository, under this project's own MIT terms (root `LICENSE`). A
permissive licence poses no problem. Anything else is an owner decision rather than a formality, and the report
must say which case each library is rather than assuming.

#### D7. The update mechanism — Stage 3, part two, and the sharpest of the three

**The baseline, re-verified on disk 2026-07-29.** `.github/dependabot.yml` declares exactly one ecosystem:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
```

Its own header comment states the purpose — keeping the SHA-pinned GitHub Actions current. So **nothing in this
repository watches a JavaScript dependency today**, whether vendored into a generated artifact, pinned to a CDN
URL, or declared in a scoped manifest. delivery-001's supersession banner lists this as one of the findings that
still stands, and it does.

**The precedent that exists, and the difference that matters.** `canonical/aid/scripts/summarize/package.json`
is a scoped, `"private": true` manifest pinning `playwright: 1.61.1` as a `devDependency` with
`engines.node >= 20`, described in its own `description` field as tooling "Not shipped to adopters", with a
`package-lock.json` beside it (read 2026-07-29). So a scoped manifest in a script area is an established shape
here. But `playwright-provisioning.md` § "Dependency isolation" records that both files **do** render into every
profile install tree and serve as an on-demand install manifest for adopters — so "scoped" means scoped by
directory, not withheld from the install. The report must state which of those two properties it is relying on.

**The mechanism must be a mechanism.** A new Dependabot ecosystem entry, a scoped manifest, a CI check, or a
named human responsibility — with the party or process that acts on it. Not an intention. Two libraries in one
manifest are covered by one entry, so the cost here is small; the reason to state it precisely is that
vendoring is the worst case for detection, because a blob inside a generated artifact has no manifest for any
tool to read.

**And a second question, which is new and which no prior reading asked: who notices if the shipped copy stops
equalling upstream?** This is not the same question as "who notices that upstream moved", and it has a verified
mechanical cause.

`render.py` declares the extensions that receive text transforms (read 2026-07-29):

```python
_TEXT_EXTENSIONS = frozenset({
    ".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css", ".py",
})
```

and applies `substitute_filenames` then `rewrite_install_paths` to any file whose suffix is in that set. **`.js`,
`.mjs`, `.html` and `.css` are all in it.** So unlike the `.yml` case feature-001 analysed — where a data file is
copied byte-for-byte precisely because `.yml` is *absent* from this set — a vendored `.js` bundle, or a bundle
inlined into `graph.html`, is **text-transformed on its way into each profile**. The transforms are narrow and
their triggers are decidable, read from `render_lib.py` on the same date:

- `rewrite_install_paths` rewrites literal `canonical/{scripts,templates,skills,agents,recipes}/…` references
  (and the `canonical/aid/…` nested forms) to the per-profile install path, and **skips lines whose first
  non-whitespace character is `#`** — a protection that does nothing for a minified bundle, which is typically
  one long line with no such prefix.
- `substitute_filenames` substitutes only three known placeholder keys: `{project_context_file}`,
  `{reviewer_output_file}`, `{open_questions_file}`.

**So the corruption condition is a grep, and the detection gap is the real finding.** A bundle is mangled only
if it contains one of those literal strings — unlikely, but not checkable by inspection and not stable across an
upstream version bump, which can introduce one silently. And the gap: the **render-drift CI job cannot see it**,
because it re-runs the generator and diffs `profiles/` against the committed render, and a consistently-mangled
copy matches a freshly-mangled one perfectly. The only detector is a byte comparison of the profile copy against
the upstream distribution at the pinned version. The report therefore owes: the grep verdict at the evaluated
versions (D4 measurand 9), and the integrity check as a **step in the update procedure**, not as a one-time
observation. Routed to **feature-012** as Open Item 9, since it owns the packaging wiring and the manifest
surfaces.

#### D8. The palette's contrast obligation, and why `contrast-check.mjs` cannot see it

**A mechanical hole, verified, with a consequence for a WCAG Level AA criterion.**

**The obligation.** WCAG 2.2 **SC 1.4.11 Non-text Contrast is Level AA** and requires that "the visual
presentation of the following have a contrast ratio of at least 3:1 against adjacent color(s) … **Graphical
Objects** — Parts of graphics required to understand the content" (w3.org/WAI/WCAG22/Understanding/
non-text-contrast.html, accessed 2026-07-29). The graph's node and edge marks are exactly that: colour carries
node kind and relationship category (NFR-5), so the marks are required to understand the content. NFR-1 sets AA,
and the requirements' own 2026-07-29 note declines to rest colour conformance on the conforming alternate
version — "extending it to colour would make the graph itself non-conformant and rest all conformance on the
table. Not adopted." So the palette must clear 3:1, mechanically, on the graph itself.

**The hole.** `canonical/aid/scripts/summarize/contrast-check.mjs`, read 2026-07-29, is a pure text extractor
with no browser: it regex-extracts CSS custom properties from `:root, html[data-theme="light"]`, `:root` and
`html[data-theme="dark"]` blocks, and checks a **hardcoded eleven-entry `pairs` list** of token names — `text`
on `bg`, `accent` on `bg-elev`, the five badge pairs, and so on — each at `target: 4.5`. Two verified
consequences:

1. **A colour that is not a CSS custom property is invisible to it.** A WebGL drawing layer passes fill colours
   to its graphics API as values, not as CSS. A palette living as literals in the drawing code is not merely
   unchecked — it produces no warning and no failure, because the script never looks for it.
2. **Even a token that *is* declared is unchecked unless it is named in the `pairs` list**, and an unresolvable
   pair is skipped with a `⚠️` and a `continue`, not a failure. So an incomplete pair list is silently
   incomplete.

**What follows, and who owns it.** The finding is this feature's; the remedies are not.

- **The palette must be declared as CSS custom properties** and read from there at runtime by the drawing code,
  so the values the canvas paints are the values the checker can see. **Owner: feature-007** (which owns
  `graph-css.css` and the design-token integration) with **feature-008** (which does the drawing).
- **`contrast-check.mjs`'s pair list must grow**, and the new pairs target **3:1** per SC 1.4.11 rather than the
  4.5 every existing pair uses — so this is a parameterisation of a shared validator, which §5.6 consequence 1
  requires to be parameterised and never weakened, with `kb.html` keeping its checks unchanged. **Owner:
  feature-011**, as Open Item 8.
- **feature-007's current claim that the graph "adds no colour token", and feature-008's matching claim that
  `contrast-check.mjs` "keeps passing on the pairs it already knows", are both void under the redesign.** They
  map five semantic roles onto existing tokens; the redesign needs up to eight category colours (AC-8a) plus
  colour for **every value of §5.2's closed `Kind` enum**, which no five-role mapping covers. Routed as Open
  Items 4 and 5.

**What this feature owes rather than routes.** The contrast measurement belongs in D4's set as a verdict on the
*mechanism*: the report states whether the palette-as-CSS-custom-properties route works under the decided
architecture — that is, whether the drawing layer can consume computed CSS values at acceptable cost — because
if it cannot, the accessible-and-checkable palette is not merely unwritten but unavailable, and that is a
finding the owner needs.

#### D9. AC-21's keyboard validation, without depending on the canvas

AC-21 requires every interactive control to be operable by keyboard alone — selecting a node, opening its
artifact, choosing a preset lens, filtering by category — verified by driving each with keyboard input only. NFR-6
widens SC 2.1.1 (Level A) to every gesture except dragging, which is exempt as genuinely path-dependent. The
question this SPEC has to answer is how that is validated on a canvas that Stage 1 may show cannot render.

**The answer is that it does not need the canvas to render, and the reason is structural rather than lucky.**
Three facts, each already on the books:

1. **The canvas is visual-only** (Q9). No control is drawn on it. NFR-6 states the consequence directly: "the
   **accessible table view** provides the keyboard-operable route to select and open, so the canvas's mouse
   gestures are an enhancement rather than the only path — which is what lets the canvas stay visual-only
   without failing this criterion."
2. **Every control is a real focusable HTML element.** AC-9 as scoped confirms the split from the other side:
   the DOM-level structural and a11y checks apply to the page structure and the table view, not to the canvas,
   which carries only a text alternative.
3. **Therefore AC-21 is decided against the DOM**, and a keyboard-only drive plus a focus-order and
   activation assertion needs no graphics context at all. It survives L1 ✗.

**And that is exactly why AC-21 has a trap the report must name.** AC-21's own wording says why it exists: "a
control drawn **on the canvas** rather than as a focusable HTML element would fail WCAG SC 2.1.1 (Level A) while
passing AC-7, AC-8 and AC-8a". So the criterion is not a test of the keyboard handlers; it is a test of **where
the controls live**. The check that decides it is therefore an assertion that the control set is *complete* in
the DOM — every filter axis of FR-14a, every lens of FR-13, select and open — and not merely that the DOM
controls present are reachable. A canvas-drawn control passes the second and fails the first.

**What this feature owes.** The route, stated above, plus the observation that it is renderer-independent, plus
one consequence for the reduced-motion path: NFR-4's settled render is the fallback, and a settled canvas is
still a canvas, so nothing about AC-21 changes between the two paths. **Owners of the controls: feature-007**
(shell, lens bar, filters), **feature-008** (canvas gestures as enhancement), **feature-009** (the table's
select/open route).

#### D10. The decision record — required parts

The report is the durable evidence, and its parts are enumerated so that a gate cannot pass it on completeness
alone. That failure mode is Q9's, verbatim: "all eleven gate criteria tested the record's **completeness and
traceability** … and none tested whether the recommended artifact is alive." Each part below therefore names the
criterion it discharges, and the criteria are properties of measurements rather than of the document.

| # | Part | Discharges |
|---|---|---|
| 1 | **Question and scope** — FR-18 as rewritten; that the renderer is decided and this is a validation; what is explicitly out (§ The validation boundary) | — |
| 2 | **Stage 1 — the probe**: the three-level verdict per environment, each renderer identity string verbatim, each invocation | AC-S1 |
| 3 | **Stage 1 — the escalation**: per negative level, the consequence for C-5, FR-12 and the renderer, with owners and the rejected alternative | AC-S2 |
| 4 | **The bench derivation procedure** and, once its inputs exist, the derived figures with their commands. **No withdrawn figure appears as a bench or as an estimate of one** — A-5 now states none — and where the history is recorded it is recorded as D2a's derivation, with its counts and commands | AC-S3, AC-S6 |
| 5 | **The response surface** — three timings per sample, four or more samples per axis, **every axis D2b lists**, observed shape stated | AC-S4 |
| 6 | **Every measurand in D4's set**, one verdict each, including the two feasibility verdicts (line styles; palette-from-CSS) | AC-S5 |
| 7 | **The frame-time predicate**, its warm-up exclusion, its two workloads, and the headless-conservatism comparison with both renderer strings | AC-S7 |
| 8 | **Settle time**, reported, with the words that say it is not gated | AC-S8 |
| 9 | **The ceiling** — curve, threshold, degree sensitivity, and the comparand recommendation | AC-S9, AC-16a |
| 10 | **Payload** at the delivered artifact and at all six tracked copies, plus the render-transform integrity verdict | AC-S10 |
| 11 | **Licence and attribution** per library at an exact version, read from the upstream file, with the place attribution appears | AC-S11 |
| 12 | **The update mechanism**, against the verified dependabot baseline, answering both "who notices upstream moved" and "who notices the copy diverged" | AC-S12 |
| 13 | **Runtime prerequisites in prose**, with WebGL support named among them | AC-6 |
| 14 | **The AC-21 validation route**, and its independence from the drawing surface | AC-S13, AC-21 |
| 15 | **Drafted `technology-stack.md` and `infrastructure.md` content**, ready to land at ship time and landed by nobody here | — |
| 16 | **What this implies for feature-008's size** — as a *range with its drivers named*, not a line count. The superseded record's ~279-line estimate is void (Q9), and its derivation note reconciling 325 to 279 by four named adjustments is precisely the kind of arithmetic precision that made a wrong answer look rigorous | — |
| 17 | **Every figure's attribution**, in one of the three admissible forms | AC-S6 |

### Feature Flow

The validation method, as an ordered sequence. `.claude/skills/aid-execute/references/task-type-rules.md`
§ RESEARCH governs: compare alternatives where alternatives exist, cite sources, document trade-offs explicitly,
end with an actionable recommendation, write findings to the path in the task's `Scope`, and **make no code
changes to the project**. The harnesses are throwaway; nothing from them ships.

**Step 1 — Fix the frame, which is not the frame the previous revision read.** REQUIREMENTS.md §5.6 as
rewritten (FR-16, FR-17, **FR-18 including its numbered order**, and the four consequences), §5.4 (FR-6a, FR-6b),
§5.2 and §5.3 (the ten columns, the `Kind` enum, the id grammars), §6.1 in full (NFR-4 through **NFR-8**), §7
(C-5 as extended, C-8), §8 (A-5's void, A-6, D-2, **D-2a**), §9 (AC-6, **AC-6a**, AC-8a, AC-9 as scoped,
**AC-16a**, **AC-21**), §10 including its sequencing amendment. Then STATE.md **Q9, Q11, Q12, Q13, Q14, Q15,
Q17, Q18, Q19, Q20**. Then delivery-001's **FINDINGS.md supersession banner**, which is the shortest statement of
what was wrong and of what still stands. Then the four A+ SPECs this feature depends on — 001 for the category
count and Open Item 11, 003 for D2a-2's anchor contract, 004 for the enumerator, 005 for Pass 1a and the
producer map. Then the KB: `decisions.md` **D18** (the `kb.html` visual artifact as the deliberate exception to
the no-diagram rule, whose Mermaid engine was superseded by pre-rendered SVG plus a Playwright visual gate — the
nearest prior decision in this problem space), `technology-stack.md` § "Frameworks & Tooling" and § "Key
Dependencies", `infrastructure.md` § "The Build: Multi-Profile Render".

**Step 2 — Read the three reused validators as code, not as description.** `validate-visuals.mjs`,
`validate-html-output.sh` and `contrast-check.mjs`, in full. D1b and D8 are the output of having done this once;
the step is retained because each is a moving target and because two of this SPEC's findings exist only because
the scripts were read rather than summarised.

**Step 3 — Stage 1. Build and run the probe.** D1: three levels, the environment set, the launch configuration
copied from the reused script rather than invented. Record every verdict and every renderer string.
**Nothing below this step begins until it has an answer**, which is FR-18's order and the reason C-5 calls it the
work's highest-risk item.

**Step 4 — Stage 1 escalation, if needed.** D1a. Where the verdict is negative, write the consequence for C-5,
FR-12 and the renderer with owners, and hand it to the owner **before** proceeding. A negative verdict does not
stop Step 8, which needs no browser.

**Step 5 — Build the fixture generator.** D3: parameterised on D2b's five axes, emitting §5.2's ten-column
`relationships.md`, hub-seeded with isolated nodes kept, seeded reproducibly, self-built per A-6. Reuse the prior
methodology; reuse no prior size.

**Step 6 — Stage 2a. Measure the response surface.** D2b and D4: every axis, four or more points each, three
timings per point, every measurand in D4's set with its own verdict, the frame-time predicate of D4b, and the
headless-conservatism comparison. Instrument in the page, not from outside.

**Step 7 — Stage 2b. Derive the bench and read the verdict off the surface.** D2's four-step procedure, once
feature-004's enumerator and feature-005's Pass 1a exist. Then NFR-7's verdict at that point, NFR-8's ceiling
and its degree sensitivity, and the comparand recommendation of D5. **This step is gated on delivery-002**, which
is the serialisation D-2a forces and Open Item 12 sequences.

**Step 8 — Stage 3. Payload, licence, attribution, update.** D6 and D7. Independent of Steps 3–7 and of the
bench, so it runs in parallel with them and is not blocked by a negative probe.

**Step 9 — Sweep for proxies before writing.** Q17's standing instruction, applied to this feature's own output
as well as to its inputs. The sweep of the previous revision is recorded at § Proxy sweep.

**Step 10 — Write the record and hand off.** Every part D10 requires. Then draft the `technology-stack.md` and
`infrastructure.md` content — drafted, not landed; this feature writes no KB.

**Consumers.** Who reads this validation, and for what:

| Consumer | Consumes | Note |
|---|---|---|
| feature-008 | The whole record: the Stage-1 verdict, the measurands' verdicts, the frame-time predicate, the vendored-bundle shape | The only feature this validation **blocks**. Its size and its draw-loop shape both swing on the answer, and its pre-redesign renderer-dependent table is void (Open Item 5) |
| feature-007 | The runtime-prerequisite statement, the packaging shape, and D8's palette-as-CSS-custom-properties requirement | Owns `graph.html` as the entry point (A-4), the shell the canvas mounts into, and the design-token integration whose "adds no colour token" claim is void (Open Item 4) |
| feature-009 | D9's AC-21 route | Owns the table view, which is both the conforming alternate version (NFR-2) and the keyboard route to select and open |
| feature-010 | NFR-8's ceiling and D5's comparand recommendation | Owns emitting AC-16a's warning, and owns the staleness digest FR-11 input 6 requires |
| feature-011 | D1b's and D8's parameterisation requirements | Owns the shared-validator carve-outs. The reserved T2 live-surface exclusion is expected to be a **recorded no-op**; two *new* parameterisations may fire instead (Open Item 8) |
| feature-012 | Payload at all six copies, licence and attribution, the update mechanism, and D7's integrity check | Owns the canonical registration, the manifest surfaces and the distribution wiring |
| feature-013 | The drafted `technology-stack.md` and `infrastructure.md` content | Lands it at ship time |
| The work owner | D1a's escalation matrix, and D4b's headless-admissibility question if it resolves against us | Two of this feature's possible outcomes are decisions only the owner can take |

### Proxy sweep (Q17)

Q17 records a defect class — a clause keyed on a **proxy** for something the model change altered — and issues a
standing instruction to sweep for it during re-specification. The sweep of this SPEC's previous revision found
six. Recorded rather than merely fixed, because the value of the instruction is in the pattern, and because one
of the six is a defect in the **requirements** rather than in this SPEC — since corrected there, which is the
sweep's most useful result to date.

| # | Clause in the previous revision | The proxy | What broke |
|---|---|---|---|
| 1 | "node counts are bounded to the **hundreds** (FR-22, FR-23, A-5)", carried in the Description, the constraints table and the tension section | a **magnitude** standing in for a **node model** | The bound was a consequence of whole-artifact granularity. FR-23's widening made concepts, facts and sections nodes, so the magnitude changed while the sentence citing three requirements stayed persuasive (D2) |
| 2 | "legibility at **this project's node counts**" as the quality bar | a **count** standing in for a **degree distribution** | Layout cost and hover-neighbourhood size both scale with the hub, not the total. Q13's merge converts mentions into degree, so a count-keyed bar would pass a graph that is unusable and fail one that is fine (D2b axis 3) |
| 3 | "**accessibility cost** … whether the renderer yields accessibility-tree semantics natively or requires a hand-built proxy layer" | a **renderer property** standing in for an **accessibility architecture** | It was exact while the accessibility route was undecided. Q9 decided it — the canvas is visual-only, AA rests on the table as the conforming alternate version — so the whole dimension, and the proxy-line arithmetic built on it, price work this work does not do |
| 4 | "the **five hard screens**", and every clause referring to them as a set | a **count** standing in for a **set**, over a set that then became empty | With one architecture there is nothing to screen. The screens' *content* survives as obligations, so deleting them would have lost real requirements; they are re-homed as D4's measurands and D6's findings rather than dropped |
| 5 | "**A-5**'s 'hundreds' is the assumption being tested" as the bench-derivation instruction | an **assumption** standing in for a **finding** | A-5 is void, so the instruction pointed at nothing. NFR-8 replaced the assumption with a measured, documented ceiling, which inverts the relationship: the bench is not tested against an assumption, it is derived and the ceiling is measured from it (D2, D5) |
| 6 | **In the requirements, not here** — the KB-side figure A-5 then stated, and the `227` fact term inside it | a **count of a token** standing in for a **set of checkable anchors** | feature-003 D2a-2 forbids exactly that count from becoming nodes. Verified at D2a; **corrected upstream the same day** — A-5 now states no figure, the root entry was fixed at source, and REQUIREMENTS.md's A+ was reopened over it. The fourth instance of Q17's class in this work, and the first found in a figure the requirements presented as verified |

Three clauses were checked and confirmed **not** proxies, so the sweep's negative results are recorded too. The
**`<canvas>` non-collection** verdict keys on `validate-visuals.mjs`'s three literal selectors, which is a
property of the script and not of the renderer, so it is exact and survives — it was checked because Q9 restated
it and a restated conditional is where a stale proxy hides. **C-5's Node ≥ 20 floor** is declared by the
validator tooling's own `package.json` rather than inferred from a CI pin, which the work's cross-reference gate
already established, so the widened node model does not touch it. And **FR-12's "reuses at the script layer"**
keys on a layer, not on a script list, so adding a parameterisation to a reused script does not falsify it — the
clause that *would* break is a count of reused scripts, and no clause states one.

### Layers & Components

#### Where the output lives

| Output | Path | Lifetime |
|---|---|---|
| The validation report / decision record | the path named in the RESEARCH task's `Scope` field under `.aid/works/work-005-knowledge-graph/`, assigned by `/aid-detail` | **transient** — disposable with the work folder |
| The Stage-1 probe, the fixture generator, and the Stage-2 harness | scratch space; not committed | throwaway by construction |
| The drafted `technology-stack.md` and `infrastructure.md` content | inside the report, as drafts | land at ship time, by feature-013 |

**No permanent artifact and no test may cite this report.** `CLAUDE.md` § "Tracking discipline" states that work
folders are transient and that no permanent artifact "may depend on the contents of a specific work folder". The
report is pipeline evidence, so the work folder is its right home — but everything downstream that must survive
the work has to be restated in a permanent place. Concretely: **feature-008 may not cite the report as its
source of truth at ship time**, and the facts that must survive — the adopted versions, the licences, the
attribution location, the update procedure including D7's integrity step, the documented ceiling, and the
runtime prerequisites including WebGL — belong in `technology-stack.md`, `infrastructure.md` and the skill's own
documentation. Nothing in this feature is added to `tests/`, because it ships no code; the tests that assert the
adopted architecture's behaviour belong to features 008, 011 and 013.

#### What the delivered artifact looks like on disk

Fixed by FR-9 and A-4; the packaging shape only fills in the companions.

- `.aid/knowledge/graph.html` — the documented entry point, beside `kb.html`, opened as a local file (C-8).
- Companion assets, if the recommended shape produces any, in a **subdirectory** under `.aid/knowledge/`, named
  so the KB index generator does not treat them as KB documents (FR-9).

That requirement is satisfied structurally rather than by new work, which the report should note rather than
re-solve: `build-kb-index.sh` selects entries with `find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`,
and `INDEX.md`'s own frontmatter states the contract as one entry per non-dot, non-recursive KB document. So a
subdirectory is outside the scan, and a non-`.md` companion is outside it even at the top level — which is why
`kb.html` is not indexed today. `relationships.md` is top-level `.md` and therefore **is** indexed, which is what
Q3 resolved.

#### Artifacts to update on adoption

**Not this feature's writes.** Which of these fire depends on the recommended packaging, and the report says
which.

| Artifact | Update | Fires when | Owner |
|---|---|---|---|
| `.aid/knowledge/technology-stack.md` § "Frameworks & Tooling" | A row per adopted library with its exact version and purpose | Always — the architecture adopts third-party code | feature-013 |
| `.aid/knowledge/technology-stack.md` § "Key Dependencies" | A row recording where each dependency lives and its concern. **State the scope precisely:** that section's standing claim is that AID ships zero runtime dependencies for the CLI, which a library inside a *generated browser artifact* does not contradict — but the row must say so rather than leaving the claim ambiguous | Always | feature-013 |
| `.aid/knowledge/technology-stack.md` § "Version Concerns" | The pinned versions and the coupling: a `d3-force` major bump can change the simulation API and a drawing-layer major bump can change the draw surface, so the vendor block and the drawing code move together | Always | feature-013 |
| `.aid/knowledge/infrastructure.md` § "The Build: Multi-Profile Render" / § "CI/CD Pipeline" | The vendoring procedure including **D7's upstream-equality check**, and any CI lane the headless-admissibility answer requires | Always for the procedure; the CI lane only if D4b resolves against a headless-only gate | feature-013 |
| `.github/dependabot.yml` and a scoped manifest | The update mechanism D7 names | Always — the baseline watches nothing | feature-012 |
| `canonical/aid/scripts/summarize/contrast-check.mjs` | Parameterised pairs for the graph palette at a 3:1 target, with `kb.html`'s eleven pairs unchanged (D8) | Always, once the palette exists | feature-011 |
| `canonical/aid/scripts/summarize/validate-visuals.mjs` | A parameterised capture exemption **only if** Stage 1 returns L3 ✗; and any launch-flag change **only if** a flag is needed, with `kb.html`'s T1–T4 results unchanged (D1, D1b) | Conditional on Stage 1 | feature-011 |
| The install and emission manifests | Account for the added file set; run the **full** generator so `profiles/*/emission-manifest.jsonl` and the render-drift gate stay green | Any new canonical file | feature-012 |
| `.aid/knowledge/capability-inventory.md` | The `/aid-graph` capability entry | Ship time | feature-013 |

**The T2 row that used to be here is gone, and its absence is deliberate.** The previous revision listed a
`validate-visuals.mjs` T2 parameterisation as firing "regardless of the recommendation", which was correct when
SVG was a live candidate. Under the decided architecture the live surface is a `<canvas>`, which matches none of
that script's three selectors, so the reserved carve-out becomes a **recorded no-op** — which Q9 already
anticipated. Recorded rather than deleted so that a reader of the earlier revision does not look for a firing
condition that no longer exists.

#### One open question, routed not answered

Whether `/aid-graph`'s outputs belong in `canonical/aid/templates/generated-files.txt` is **not** settled here.
That registry's own header says it is consumed by `/aid-discover`'s FIX state for an end-of-cycle refresh-all,
which would mean `/aid-discover` regenerating the graph — plausibly wrong, since FR-7 makes `/aid-graph` a
standalone on-demand sibling of `/aid-summarize` rather than a phase of discovery, and `kb.html` is likewise
absent from that registry today. This belongs to feature-010 (the skill runtime) and feature-012 (the wiring);
it is recorded here because a multi-file packaging shape is what makes it worth asking. Unchanged from the
previous revision, and unaffected by the redesign.

### External Integrations

This section exists because the decided architecture adopts third-party code. It covers what the project takes
on and what the report must state; the findings themselves are D6's and D7's.

#### Licence and attribution

- **The bar:** the licence must permit redistribution of the code inside an artifact this project generates into
  a **third party's** repository, compatibly with this project's own MIT terms (root `LICENSE`). Permissive
  licences pass. Anything else is an explicit owner decision, because the redistributed unit lands in someone
  else's repository — the report must not treat this as a formality.
- **Read the licence file, at the evaluated version.** Not a registry field, not a summary page, and not this
  SPEC. delivery-001's own findings record that its first draft's D3 licence claim was corrected during review,
  which is precisely why the rule is stated as a rule.
- **Name the place.** Where a licence requires a notice, the report names where it appears in the delivered
  artifact — a comment block in the inlined script, a visible footer, an about panel, or a companion file — not
  merely that it is required.

#### The update obligation, and who notices

Two questions, both specified at D7, and the second is the one no prior reading asked. The baseline is verified:
`.github/dependabot.yml` watches GitHub Actions and nothing else, so **nothing watches a JavaScript
dependency today**. The precedent is verified: a scoped `"private": true` manifest with a lockfile exists at
`canonical/aid/scripts/summarize/package.json`, though `playwright-provisioning.md` records that it renders into
every install tree rather than being withheld from adopters. And the gap is verified: the render-drift gate
cannot detect a bundle mangled by `render.py`'s text transforms, because it compares a fresh render to a
committed render rather than either to upstream.

#### Network and portability

- A CDN shape is permitted by FR-16 and is constrained twice over by the tooling: `validate-html-output.sh`'s
  S2 greps for external `<script src>` and `<link href>`, and `validate-visuals.mjs` aborts every request whose
  URL does not begin `file://` — so a CDN artifact renders **without its renderer** under the visual gate. FR-16
  consequence 3 additionally requires the non-portability cost to be stated plainly and vendoring to be
  preferred where interaction quality is comparable.
- C-8 records that `graph.html` is deliberately not dashboard-reachable, and that the dashboard's
  `default-src 'self'` policy would block a CDN artifact there if it ever were.
- AC-6 is the receipt: whatever is chosen, the runtime prerequisites — **including WebGL support** — are
  documented explicitly enough that a reader knows what the artifact needs to work.

#### Toolchain reach

Any adopter-time build step means `/aid-graph` can fail for reasons unrelated to the Knowledge Base — a missing
`node_modules`, a lockfile mismatch, a bundler error. §5.6 consequence 2 names this, and C-5 sets the floor it
inherits: Node ≥ 20 for validator tooling, with browser-backed validation degrading gracefully when the browser
is absent. The report says what the skill's preflight must check, and hands that to feature-010. **And the
decided architecture adds one preflight item the previous revision had no reason to consider:** WebGL
availability is a *runtime* prerequisite of the artifact rather than a generate-time one, so it is not a
preflight check at all — it is a documented prerequisite plus, if Stage 1 demands it, a recorded skip in the
validation lane. Confusing the two would put a browser capability check into a shell preflight, where it cannot
be performed.

### Open Items

Recorded rather than silently assumed. Where an item belongs to another feature or to the methodology, that
owner is named and the item is **not** absorbed here. None blocks Stage 1, Stage 2a or Stage 3; item 3 bounds
Stage 2b, as do the two producing features D2 names.

**Items 1 and 2 are retired, not open.** Both were addressed in REQUIREMENTS.md on 2026-07-29, the same day they
were raised, and each states below exactly what landed. They are kept as a record with **no owner and no action
attached**, so that a later amendment pass neither closes an item it can find no work for nor re-applies a
correction over text that already carries it. Their numbers are kept because the change log and D2a refer to
them, and a renumbering would make those references point at live items.

> **Standing rule for every item below whose owner is already gated A+** (STATE.md Q18 ruling 3, *"if there is a
> defect, the A+ is false"*): a gate grade is a live claim about the artifact, not a milestone banked and then
> defended. Scheduling such an item therefore **reopens that feature's SPEC and re-gates it** — the grade does
> not survive the change, and the cost of re-gating is never an argument against making it. **feature-001,
> feature-003, feature-004 and feature-005 are all gated A+ as of 2026-07-29**, so Open Items 3 and 7 carry the
> consequence explicitly. Items owned by an ungated feature carry no such consequence and say so. Per **Q20**,
> an item routed **into** a gated SPEC is a **pending reopen, not a note**, and must be scheduled before that
> SPEC's grade is relied upon.
>
> **The rule reached REQUIREMENTS.md, and was applied to it rather than argued about.** Q15 records
> REQUIREMENTS.md re-graded **A+** after six adversarial cycles. Item 2 below was a **defect in that document** —
> a figure it presented as verified, which the gated feature-003 schema forbids from meaning what the document
> used it to mean. Ruling 3 does not distinguish artifact classes: a grade that coexists with a known defect was
> never true, so the requirements' A+ was **reopened, corrected and re-graded on 2026-07-29**, exactly as a
> feature SPEC's would have been, and item 1 was corrected on the same pass. Kept here because the principle is
> easier to apply to someone else's artifact than to the one every other artifact is graded against, and because
> this is the instance where it was applied to the hardest case.

1. ~~**D-2a understates the serialisation: the bench has three terms and two producing features, not one.**~~
   **DISCHARGED 2026-07-29 — no action remains, and none may be taken from this item.** The finding was that
   D-2a named concept merging and therefore pointed at feature-005 alone, while D2 shows the `source-artifact`,
   `image` and `web-page` term is produced by **feature-004's enumerator** and the KB-side term by feature-005's
   Pass 1a rather than by counting. **What landed:** D-2a was amended the same day to state "**three terms with
   two producing features**", naming feature-004's enumerator, feature-005's Pass 1 and Q13's merge, and to
   record that an earlier version named only feature-005; a matching correction entry sits in the requirements'
   change log; and the mitigation this SPEC offers (D2b's parametric surface plus a later lookup) is recorded
   there too. **No owner, because there is nothing to route:** the requirements now state the wider set, D2
   states the producer-level detail that a requirement should not carry, and re-applying the original correction
   would overwrite corrected text with the text it replaced. The sequencing consequence is live and is **item
   12's**, not this one's.
2. ~~**A-5's KB-side figure includes a fact term that the gated schema forbids becoming nodes.**~~
   **DISCHARGED 2026-07-29 — no action remains, and none may be taken from this item.** The finding, verified at
   D2a: the term was the 227 occurrences of the bare token `CONFIRMED` in `.aid/knowledge/*.md`, while only 33
   lines carry both `CONFIRMED` and `(search:`, and **feature-003 D2a-2** states that counting every `CONFIRMED`
   occurrence "would manufacture nodes that resolve to nothing, which is precisely what AC-1 exists to prevent."
   **What landed, all in REQUIREMENTS.md the same day:** A-5 restated to state **no** KB figure, with the
   227-versus-33 finding and an independently re-counted anchored total recorded as *not* a requirement either;
   the root traced to the change-log entry where Q13's fact definition was first recorded, and corrected at
   source, which is where the wrong figure entered before A-5 inherited it; **FR-18 item 2's figure removed**;
   two further change-log entries that still asserted withdrawn figures corrected; and the document's **A+
   reopened and re-graded** under Q18 ruling 3. **No owner, because there is nothing to route** — and note the
   asymmetry that makes this item worth retiring rather than deleting: a stale routing here would ask an executor
   to re-insert a labelled estimate into a requirement that now correctly states none.
3. **The fixture's category axis is exercised against a specified count, not a shipped file.**
   `canonical/aid/templates/graph/relation-vocabulary.yml` on disk carries **15 `- relation:` entries and 5
   categories** (read 2026-07-29) — the superseded contents. feature-001's re-specified SPEC states **14
   categories / 31 pairs / 57 entries** as its finding, with authoring the file left as execution work. Until
   that task runs, D3's generator draws its relation labels and categories from feature-001's stated content,
   and the report labels the dependency. Nothing here asks feature-001 to change: the item exists so that the
   sequencing is visible and so that a fourteen-category measurement is not mistaken for a measurement against a
   shipped vocabulary. **Owner: the task that authors `relation-vocabulary.yml` under feature-001 — gated A+; if
   any change to that SPEC's content proves necessary, scheduling it reopens and re-gates that SPEC.**
4. **feature-007's design-token claim is void under the redesign.** Its § "Design-token integration" states that
   `graph-css.css` "adds **no colour token**", mapping five semantic roles onto existing contrast-checked tokens
   so that `contrast-check.mjs` "keeps passing without new pairs being added to the script". The redesign needs
   colour for up to **eight** relationship categories (AC-8a part 3) **plus** every value of §5.2's closed
   `Kind` enum, and
   no five-role mapping covers that. D8 states the two consequences: the palette must be declared as CSS custom
   properties so the checker can see it, and the checker's pair list must grow. **Owner: feature-007** (ungated —
   no reopen consequence), with **feature-011** for the checker (item 8).
5. **feature-008's renderer-dependent table and its contrast claim are void under the redesign.** Its
   § "What changes with feature-002's answer" tabulates Native SVG / Canvas / WebGL across per-mark focus,
   accessible names and proxy-drift — a comparison Q9 closed and whose accessibility half Q9 also removed by
   making the canvas visual-only. Its § "Reuse, not reimplementation" repeats feature-007's
   no-new-colour claim. And its ~279-line size estimate is void (Q9), which D10 part 16 replaces with a range
   whose drivers are named. **Owner: feature-008** (ungated — no reopen consequence).
6. **NFR-8's ceiling and AC-16a's warning may need a comparand other than a node count.** D5 explains: the
   ceiling's dominant variable is **maximum degree**, and a node-count comparison would warn on a large sparse
   graph and stay silent on a small hub-heavy one. Both quantities are computable from `relationships.md` alone,
   so this is a choice rather than a constraint. This feature supplies the curve, the threshold and the
   sensitivity, and recommends; it does not silently pick one, because NFR-8 and AC-16a both say "node count"
   and changing that is a requirements amendment. **Owner: feature-010** (which emits the warning; ungated),
   **with the work owner** if the recommendation is the degree-aware form.
7. **The `fact-unanchored` coverage row is what makes the KB term of the bench derivable, and it arrives through
   an unresolved ordering contract.** D2's step 2 reads that row, and Q19 records that the extra coverage rows
   have **no defined total order** across the two contributing files, so AC-5's byte-identity guarantee rests on
   unspecified assembly behaviour. This feature depends only on the row's *value*, not on its position, so
   nothing here breaks — but the row is a Stage-2b input and its contract is open, which is worth stating rather
   than discovering. Already routed by feature-005 as its Open Item 16. **Owner: feature-003** for the ordering
   contract — **gated A+; scheduling this reopens and re-gates that SPEC**, which the work owner has already
   ruled under Q18 ruling 3 — and **feature-010** for the assembly (ungated).
8. **Two shared-validator parameterisations may fire, and neither is the one held in reserve.** The reserved
   `validate-visuals.mjs` **T2** live-surface exclusion is now expected to be a **recorded no-op**, because a
   `<canvas>` matches none of that script's three selectors. What may fire instead: (a) a **capture exemption**,
   if Stage 1 returns L3 ✗ (D1a); (b) a **launch-flag change**, if a flag proves necessary to obtain a WebGL
   context at all (D1); and (c) **new `contrast-check.mjs` pairs at a 3:1 target** for the graph palette, where
   every existing pair targets 4.5 (D8). All three must be expressed by parameterisation and never by weakening,
   with `kb.html` keeping every check unchanged (§5.6 consequence 1, C-4, AC-17). **Owner: feature-011**
   (ungated — no reopen consequence).
9. **A vendored bundle is text-transformed into five profiles, and the render-drift gate cannot detect the
   corruption.** D7 verifies both halves: `.js`, `.mjs`, `.html` and `.css` are all in `render.py`'s
   `_TEXT_EXTENSIONS`, so `substitute_filenames` and `rewrite_install_paths` run on them; and render-drift
   compares a fresh render to a committed render, so a consistently-mangled copy passes. The corruption
   condition is a decidable grep over the bundle bytes, but it is not stable across an upstream version bump, so
   the check belongs in the **update procedure** rather than being taken once. **Owner: feature-012** (packaging
   wiring and manifest surfaces; ungated), with **feature-013** for the `infrastructure.md` procedure text.
10. **The payload figure that matters for the repository is six times the one that matters for the reader.** D6:
    a canonical file renders to five install trees, each with its own `sha256` in
    `profiles/*/emission-manifest.jsonl`. The superseded record priced only the delivered `graph.html`, which is
    the right figure for a reader and the wrong one for a reviewer of a pull request. Both are reported here;
    what remains is whether the repository-side figure is acceptable at the decided architecture's size, which
    is a packaging judgment. **Owner: feature-012**, with **the work owner** if the figure is large enough to
    reopen the packaging shape.
11. **Whether a real bench carries all fourteen categories is not knowable from this feature.** feature-005's
    D8 producer map records ten of the vocabulary's thirty-one pairs with no producer, and feature-001's W3 layer
    reports reachability per project. So D4a's fourteen-category fixture is a deliberate worst case, and the
    difference between it and the derived bench is a fact Stage 2b reports rather than a defect. Recorded so that
    a reader does not treat the worst-case measurement as a description of this repository. **Owner: this
    feature**, discharged at Stage 2b; no other feature is asked for anything.
12. **The delivery sequencing must be re-derived, and PLAN.md still describes this feature as a renderer
    selection.** §10's own amendment says the proposed shape "no longer holds cleanly" and that `/aid-plan` must
    re-sequence. Three specifics this SPEC adds: Stage 1 and Stage 3 are unblocked and should run first; Stage 2a
    needs only Stage 1; Stage 2b is gated on **two** delivery-002 features — feature-004's enumerator and
    feature-005's Pass 1 — per D2 and the corrected D-2a. Alongside that, PLAN.md,
    delivery-001's BLUEPRINT and its gate criteria describe this feature's deliverable as a renderer
    recommendation with a comparison matrix, and **the feature's title changed** in this revision from "Graph
    Rendering Approach Research". Q14's amendment-sequencing decision hand-amends PLAN.md rather than patching
    regenerated artifacts, so both belong to that pass; nothing mechanical breaks in the meantime. **Owner:
    whoever performs the PLAN.md amendment.**
13. **If a headless measurement turns out not to be conservative, AC-6a needs a second lane and that is an
    owner decision.** D4b states the hypothesis and its test. If the comparison shows a headless figure can be
    *better* than a hardware-rendered one, NFR-7's "measured headless" clause would be gating on a number that
    does not bound the real one, and the choices are a hardware-rendered confirmation lane in CI, a stated
    tolerance, or an amendment to NFR-7. Each has a cost this feature will have measured; none is an author's to
    choose. **Owner: the work owner**, on evidence this feature supplies.
