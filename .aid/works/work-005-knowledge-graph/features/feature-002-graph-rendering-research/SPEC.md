# Graph Rendering Approach Research

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.6 (FR-18), §8 (D-2), §10 (deliverable 1); STATE.md Q2 | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned to amended FR-16 — packaging constraints withdrawn, option space unrestricted; added accessibility-cost and scale-tension criteria | /aid-specify |
| 2026-07-28 | Dependency position re-scoped after the feature-011 three-way split — feature-012 is conditionally gated on this research and feature-013 transitively, so neither is listed as proceeding without it | /aid-specify |
| 2026-07-28 | Gate finding 2 [MEDIUM] fixed — the § Requirements baseline note no longer claims the requirements half is stale; decision record extended to trace the two criteria added by that realignment, and the rejected-alternatives clause restated against the current first criterion | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the vendored-library obligations, the drafted stack entry, the manifest impact and the packaging wiring are now **feature-012**'s, and the drafted `technology-stack.md` / `infrastructure.md` entries land at ship time by **feature-013**. feature-011 keeps only the validator-parameterisation carve-out. No decision in this SPEC changes | /aid-specify |

## Source

- REQUIREMENTS.md §5.6 (FR-18; constrained by FR-16 and FR-17)
- REQUIREMENTS.md §8 Assumptions & Dependencies (D-2 — implementation depends on this research completing)
- REQUIREMENTS.md §10 Priority (proposed deliverable 1)
- REQUIREMENTS.md §9 (establishes the feasibility of AC-6, which feature-007 must satisfy)
- STATE.md § Cross-phase Q&A — **Q2** (Architecture, Impact High, Deferred to RESEARCH). This
  feature **is** Q2; resolving it closes the question.

**Dependency position.** This is the second of the two RESEARCH features. It blocks
**only** feature-008 (the interactive graph canvas) outright. Features 003 through 006,
009, 010, and 011 all proceed without it, so `relationships.md` and the gap ledger still
ship if this research stalls (§10). Preserving that decoupling is the reason this is a
separate feature from feature-001 rather than one merged research feature.

*Restated 2026-07-28 after feature-011 split three ways.* Two of the resulting features sit
outside the simple blocks/does-not-block split above, so neither belongs in the list of
features that "proceed without it": **feature-012** does proceed for its registration and
count work, but its dependency-packaging gate is **conditional on this research** — it
cannot close until the recommendation is known; and **feature-013** depends on every other
feature landing, so it is gated transitively rather than directly. The decoupling claim is
unaffected: neither blocks the `relationships.md` and gap-ledger path.

## Description

This is a **RESEARCH feature. Its output is a decision, not shipped code** — a
recommendation that feature-008 then implements.

The interactive graph has to be drawn by something, and choosing what is this feature's job.
**The option space is unrestricted** (FR-16 as amended 2026-07-28): the packaging constraints
that once bounded it are withdrawn, so a candidate may ship as multiple files, may fetch from a
content delivery network, and may require a real build step with third-party dependencies. SVG,
Canvas, and WebGL renderers are all admissible at any payload size, as is hand-rolling the
layout in plain JavaScript.

Each option carries a real cost. Hand-rolling a force-directed layout with stable grouping and
sane density is a physics-tuning problem and a well-known time sink. Adopting third-party code
creates licence, attribution, and update obligations the project then owns. A network dependency
makes the artifact non-portable, and a build step adds a generate-time toolchain to a repository
whose command line is currently pure shell and Node standard library. This feature does the work
to choose deliberately rather than by default, and produces the evidence a reviewer needs to
agree.

What binds every option instead is **quality**: the recommendation is judged on interaction
quality, legibility at this project's node counts, and its accessibility cost against the WCAG AA
bar in §6 — not on packaging purity. Because node counts are bounded to the hundreds (FR-22,
FR-23, A-5), raw rendering ceiling and best-achievable artifact may point in opposite directions,
and the recommendation must confront that rather than default to the most powerful renderer.

## User Stories

- As the **AID methodology owner**, I want the rendering choice made with its licence,
  payload, and maintenance costs written down, so that I am not surprised later by a
  third-party dependency inside a generated artifact.
- As a **maintainer/architect**, I want the recommendation to state exactly what the artifact
  needs at runtime — network access, companion files, or a build output — so that I know where
  and when the graph will and will not work before we commit to it.
- As a **KB reviewer**, I want the recommendation weighed against the accessibility bar rather
  than raw rendering power, so that the chosen renderer does not quietly make WCAG AA
  unaffordable.
- As the **AID methodology owner**, I want to know what updating the adopted approach will
  involve before adopting it, so that the artifact does not quietly rot.

## Priority

Must

## Acceptance Criteria

Completion criteria for the research (this feature ships a decision, so its criteria are
deliverables rather than runtime behaviour):

- [ ] A written recommendation names exactly one approach and states why the rejected
      alternatives were rejected, covering at minimum: minimal layout/zoom modules, a
      higher-level graph library, a WebGL-class renderer, and the hand-rolled option.
- [ ] The recommendation reports the **payload and packaging cost** the approach carries — added
      bytes, whether output is single- or multi-file, and whether a build step or network fetch
      is required.
- [ ] The recommendation reports the **licence and attribution obligations** the approach
      creates, including where attribution must appear in the generated artifact if required.
- [ ] The recommendation reports an **update story** — how the project refreshes the adopted
      code or logic when upstream changes, and who is responsible for noticing.
- [ ] The recommendation includes the **`technology-stack.md` entry** to be added for whatever
      is adopted, drafted and ready to land at ship time.
- [ ] The recommendation satisfies FR-16 **as amended**: it optimises for interaction quality and
      legibility rather than packaging purity, and it **documents the artifact's runtime
      prerequisites explicitly** (network access, companion assets, or a build output) so AC-6 can
      be met. A recommendation that leaves its prerequisites implicit is not accepted.
- [ ] The recommendation reports the **accessibility cost** of the approach against §6's WCAG AA
      bar — specifically whether the renderer yields accessibility-tree semantics natively or
      requires a hand-built proxy layer, and what that implies for feature-009's effort.
- [ ] The recommendation addresses the **scale-versus-accessibility tension** directly: given node
      counts bounded to the hundreds (FR-22, FR-23, A-5), it states why the chosen renderer is
      right at *this* scale rather than at the scale the library was built for.
- [ ] The recommendation states what it implies for feature-008's size, so that delivery
      sequencing can be planned honestly — a vendored library makes feature-008 small and adds
      obligations to feature-012, whereas hand-rolling makes feature-008 substantially larger.
- [ ] The recommendation confirms the approach can honour the accessibility obligations
      feature-008 owns: reduced-motion settling, keyboard-equivalent zoom and pan, and
      encoding meaning by shape or label rather than colour alone.

---

## Technical Specification

> Added by `/aid-specify`. Do not fill during interview.
> The sections below are determined by Specify based on KB, codebase, and developer discussion.

### Requirements baseline for this section

**The requirements half above and this section share one baseline: REQUIREMENTS.md as amended
2026-07-28.** The packaging constraint that once bounded this research is withdrawn — FR-16 now puts
quality and interaction ahead of packaging constraints, C-1 is struck through as withdrawn, FR-18
declares the option space "unrestricted — SVG, Canvas, and WebGL renderers are all admissible, at any
payload size, with or without a build step", and AC-6 requires only that the artifact "renders the
graph successfully" via "its documented entry point" with runtime prerequisites "documented
explicitly". STATE.md Q2 records the same widening. The Description and the sixth acceptance criterion
above are stated against that amended text and are current; nothing in this section overrides them.

What the amendment widened is the **option space**. What it did not touch still binds, and these are
the real constraints:

| Still binding | Source | Effect on the research |
|---------------|--------|-----------------------|
| WCAG AA on `graph.html` | NFR-1 | A hard screen, not a scoring dimension |
| Two peer renderings — graph **and** accessible table | NFR-2, NFR-3 | The recommendation must serve both from one data path |
| Reduced motion → settled graph; colour never sole carrier; keyboard zoom/pan | NFR-4, NFR-5, NFR-6 | Per-candidate capability, must be demonstrated not assumed |
| Four lenses incl. Impact's adjustable-depth neighbourhood; manual controls always live | FR-13, FR-14 | An interaction inventory each candidate is scored against |
| Renders from `relationships.md` alone | FR-3, AC-10 | No candidate may need a second extraction pass |
| Entry point is `graph.html`; companions sit beside it under `.aid/knowledge/` | FR-9, A-4 | Bounds the packaging shapes |
| Node counts land in the hundreds | A-5 | Sets the bench scale — see § the tension below |
| Reuse the summarize script layer; do not fork it | FR-12, C-4, AC-17 | Constrains what the adopted approach may ask of the toolchain |
| Node.js ≥ 20 for validator tooling; browser validation degrades gracefully | C-5 | Any build step inherits this floor |

### Data Model

**No database, no schema, no migration.** This feature ships a decision. What follows specifies the
*shape of that decision*, in the place of the table-and-column model a runtime feature would carry.

#### The comparison matrix

One row per candidate. Every cell is filled from a measurement or a primary source, never from
reputation — a cell that cannot be filled is itself a finding about the candidate.

| Field | What it records | Fill rule |
|-------|-----------------|-----------|
| `Candidate` | Name, version evaluated, and project URL | Exact version; "latest" is not a value |
| `Renderer` | `SVG` \| `Canvas` \| `WebGL` \| `DOM` \| `multi` \| `hand-rolled` | The renderer actually used at our scale, not the ones the library can theoretically target |
| `Packaging shape` | Which of the five shapes in § Feature Flow Step 3 it is being evaluated under | A library evaluated under two shapes gets two rows |
| `Licence` | SPDX identifier, plus whether attribution must appear in the artifact | From the upstream LICENSE file, not from a summary page |
| `Payload` | Bytes the approach adds to the delivered artifact, and where they live (inlined / companion file / fetched) | Measured on the spike output; discharges the second completion criterion |
| `Build requirement` | `none` \| `maintainer-time` \| `adopter-time`, plus the toolchain it implies | See § External Integrations — the three are not equivalent costs |
| `Legibility at bench scale` | Whether structure is readable at the measured node/edge count, across the density range | Measured on the spike, at the scale derived in Step 2 |
| `Interaction coverage` | Which of FR-13/FR-14's behaviours are built in, which need writing | Per-behaviour verdict, not a score |
| `Accessibility cost` | Keyboard reachability, focus visibility, per-mark semantics, reduced-motion settling, non-colour encoding | Verdict per NFR-1/4/5/6; the dossier below predicts this varies hugely by renderer |
| `Validator impact` | What it does to the shared `validate-html-output.sh` assertions | Names the specific assertions (see § Layers & Components) |
| `Update story` | How the project refreshes it, and **who or what notices** upstream moved | Discharges the fourth completion criterion; see § External Integrations |
| `feature-008 size` | Whether adopting it makes feature-008 small or large | Discharges the seventh completion criterion |
| `Verdict` | `recommended` \| `rejected` + the one-line reason | Exactly one row is `recommended` |

#### The decision record

The report is the durable artifact. Its required parts, each traceable to a completion criterion in
the requirements half above or to STATE.md Q2's stated deliverable:

1. **Question and scope** — Q2 as amended, and what the widened option space now admits.
2. **Research inputs** — the prior art below, plus anything gathered during execution, each claim
   attributed and dated.
3. **Bench scale and how it was derived** — the node and edge counts the spike ran at, and the
   enumeration bound they came from.
4. **The comparison matrix** — every candidate, every field.
5. **The recommendation** — exactly one approach, named.
6. **The rejected alternatives** — with a reason each, covering at minimum the four renderer classes
   the first acceptance criterion names (minimal layout/zoom modules, a higher-level graph library, a
   WebGL-class renderer, and the hand-rolled option) **and**, because packaging is a second and
   independent axis (§ Feature Flow Step 3), the packaging shapes rejected alongside them — including
   CDN delivery and build-step output.
7. **Runtime prerequisites, stated explicitly** — network access, companion files, or build output.
   This is the sentence AC-6 will be checked against, so it is written as prose a reader can act on.
8. **Payload, licence and attribution, and where attribution must appear** in the artifact.
9. **The update story**, including who notices.
10. **The accessibility confirmation** — reduced-motion settling, keyboard zoom and pan, and
    non-colour encoding, each demonstrated rather than asserted.
11. **The accessibility cost of the recommended renderer** — whether it yields accessibility-tree
    semantics natively or requires a hand-built proxy layer, and what that implies for feature-009's
    effort. Distinct from part 10: that one confirms the behaviours are reachable, this one prices
    reaching them.
12. **The scale-versus-accessibility tension, resolved** — why the chosen renderer is right at this
    project's measured node count rather than at the scale its library was built for (§ the tension
    below).
13. **The drafted `technology-stack.md` entry**, ready to land at ship time.
14. **The drafted `infrastructure.md` implications**, if a build step is recommended (STATE.md Q2
    names this deliverable alongside the stack entry).
15. **The implication for feature-008's size**, so sequencing can be planned honestly.

### Research inputs / prior art

**These are inputs, not conclusions.** They were gathered on 2026-07-28 to shape the question, and
this feature's job is still to reach and justify its own decision. Every claim below is attributed;
none of it substitutes for the spike in Step 5.

#### Renderer / accessibility decision matrix

Source: "Accessible Interactive Data Visualization", interactive-data-visualization.com, accessed
2026-07-28.

| Approach | Best for | Renderer | A11y cost | Watch out |
|----------|----------|----------|-----------|-----------|
| Native SVG with labeled marks | < ~1,000 marks, rich interaction | SVG | Low — semantics inherent | Verbose announcements if every mark is focusable |
| SVG + accessible data table fallback | Any size, complex relationships | SVG/DOM | Low–medium | Keeping table and chart in sync |
| Canvas + DOM proxy layer | 1k–100k marks | Canvas | High — proxies hand-built | Proxy/pixel coordinate drift on resize |
| WebGL + DOM proxy + summary | > 100k marks | WebGL | High, plus no per-mark focus | Proxy granularity |

Quoted findings from that source, same access date:

- "only SVG and the DOM produce accessibility-tree semantics for free. Canvas and WebGL render pixels
  into an opaque buffer that exposes nothing to assistive technology" — the renderer choice
  "dictates how much accessibility work you must do by hand."
- "if you can afford SVG, accessibility is dramatically cheaper."
- It recommends maintaining an **accessibility model alongside the visual model** — a plain data
  structure of nodes and focus order, decoupled from drawing, read by both the renderer and the
  accessibility layer, so it "survives a renderer swap" and is the single source of truth for the
  data-table fallback, live-region text, and per-mark labels.
- The WCAG criteria it concentrates at A/AA for this artifact class: 1.1.1 Non-text Content, 1.3.1
  Info & Relationships, 2.1.1 Keyboard, 2.4.7 Focus Visible, 1.4.3 / 1.4.11 contrast, 4.1.3 Status
  Messages.

That last recommendation lands squarely on a decision this project has *already* made: NFR-2 makes
the accessible table a **peer** rendering, and FR-3 makes `relationships.md` the single input to
both. So the "accessibility model alongside the visual model" is, here, feature-007's lens
view-model over the table — which means the research should evaluate whether each candidate can be
driven from that shared model rather than from its own internal graph state.

#### Library landscape (2026)

Sources, all accessed 2026-07-28: PkgPulse "Cytoscape.js vs vis-network vs Sigma.js 2026" guide;
gdotv "Practical Advice on Graph Visualization: The Case of SigmaJS"; solosoft.dev AntV G6 2026
overview; js.cytoscape.org.

| Claim | Attributed to |
|-------|---------------|
| Renderer ceilings: SVG slows past a few thousand elements (D3.js); Canvas is CPU-bound in the tens of thousands (Cytoscape.js default); WebGL scales to hundreds of thousands (Sigma.js) | PkgPulse comparison guide, 2026-07-28 |
| **Cytoscape.js** — MIT, pure JS, rich built-in graph algorithms / centrality / pathfinding, Canvas by default; positioned for "graph as analysis object" | js.cytoscape.org + PkgPulse, 2026-07-28 |
| **vis-network** — positioned for interactive network diagrams with physics, drag/drop, clustering | PkgPulse, 2026-07-28 |
| **Sigma.js** — WebGL, data layer decoupled via `graphology`; v4 claims to close the historic customization gap ("GPU performance and rich, customizable visuals in the same renderer") | PkgPulse + gdotv, 2026-07-28 |
| **AntV G6** — multi-renderer (Canvas/SVG/WebGL/3D), ~11K stars, GPU layout, cited as handling 10k+ nodes at 60fps | solosoft.dev overview, 2026-07-28 |
| Documented accessibility evidence against canvas-only: Elastic Kibana issue #248471 evaluates replacing Cytoscape.js precisely because "the current Cytoscape.js implementation has poor accessibility because it uses canvas-only rendering", tabulating keyboard navigation, screen reader support, focus indicators, and ARIA as absent or limited | Elastic Kibana issue #248471, 2026-07-28 |
| **Data Navigator** (CMU DIG; npm `data-navigator`, v2.4.x published Feb–Mar 2026; IEEE TVCG 2023 paper) builds a semantic, navigable accessible HTML layer over *any* renderer — SVG, Canvas, images, WebGL | npm + the TVCG paper, 2026-07-28 |

Data Navigator is a candidate **dependency for the accessibility layer independent of the renderer
choice**, so it belongs in the matrix as a composable row, not only as an alternative to the
renderers. Note also that Sigma.js's `graphology` split and Data Navigator's renderer-agnostic layer
are both instances of the same "decouple the model from the drawing" advice above — which is
corroboration from three independent sources, and the strongest signal in the dossier.

#### The tension this research must resolve explicitly

The owner dropped the packaging restrictions to permit maximum rendering power. But this project's
scale is bounded to the **hundreds** of nodes by FR-22 (generated trees, vendored code, and
ignore-listed paths excluded), FR-23 (whole-artifact granularity, never functions or lines), and
A-5. And NFR-1 sets a hard WCAG AA bar.

The dossier says WebGL's advantage begins **far above** our scale while its accessibility cost is
high, and that SVG/DOM is where accessibility is nearly free. So "maximum rendering power" and "best
achievable artifact" may point in **opposite directions here**. The research must confront that
head-on rather than reading the widened option space as an instruction to pick the most powerful
renderer:

- The freedom the owner granted is freedom **from packaging purity**, not a mandate for maximum
  renderer capability. Dropping the single-file rule buys the option of a large well-tested library
  and a real build; it does not make GPU rendering the goal.
- A recommendation that lands on SVG or DOM must still justify why the newly available freedom was
  *used* — for instance, a larger library or a build step chosen for interaction quality — rather
  than quietly re-deriving the pre-amendment answer and leaving the owner's decision with no effect.
- A recommendation that lands on Canvas or WebGL must show it clears NFR-1 at AA **as measured**, and
  price the hand-built proxy layer the dossier warns about into feature-008's and feature-009's size.
- Either way the report states the recommendation, the rejected options, and why — including which of
  the two poles it chose and at what cost.

### Feature Flow

The research method, as an ordered sequence. `.claude/skills/aid-execute/references/task-type-rules.md`
§ RESEARCH governs: compare at least two alternatives, cite sources, document trade-offs explicitly,
end with an actionable recommendation, write findings to the path in the task's `Scope`, and make no
code changes to the project.

**Step 1 — Read the amended frame.** REQUIREMENTS.md §5.6 as rewritten (FR-16, FR-17, FR-18, and the
four numbered consequences), §6.1 in full, FR-3, FR-9, FR-13, FR-14, A-4, A-5, A-6, AC-6, AC-7,
AC-8, AC-9, AC-10, and C-1's withdrawal. Then STATE.md Q2. Then the KB: `decisions.md` D18 (the
`kb.html` visual artifact is the deliberate exception to the KB's no-diagram rule, and its Mermaid
engine was **superseded by pre-rendered inline SVG plus a Playwright visual gate** — the closest
prior decision this project has made in this exact problem space), `technology-stack.md`
§ "Frameworks & Tooling" and § "Key Dependencies", and `infrastructure.md` § "The Build:
Multi-Profile Render".

**Step 2 — Derive the bench scale.** Do not spike at an assumed size. Compute the candidate `int:`
node count for this repository under FR-21's significance rule and FR-22's exclusions, add the KB
document and concept count from `.aid/knowledge/`, and use the result as the bench scale, recording
how it was derived. A-5's "hundreds" is the assumption being tested, and a measured figure is what
makes every legibility and performance claim in the matrix checkable. Also bench a deliberate
overshoot — roughly an order of magnitude above the measured figure — so the recommendation says
something honest about the case where A-5 does not hold.

**Step 3 — Enumerate the option space.** Two independent axes, now that packaging is unconstrained.
Renderer class: SVG, DOM, Canvas, WebGL, multi-renderer, hand-rolled. Packaging shape:

1. **Inlined vendored subset** — a minimal set of layout/zoom modules inlined into `graph.html`.
2. **Inlined vendored whole library** — the full library inlined.
3. **Companion files beside `graph.html`** — permitted by FR-16, placed per FR-9 and A-4.
4. **CDN fetch at view time** — permitted by FR-16, at the cost in §5.6 consequence 3.
5. **Build at maintainer time, with the output committed and shipped** — the adopter needs no
   toolchain. Three separate pieces of existing practice make this a precedented shape rather than a
   novel one: `packages/npm/scripts/vendor.js` runs at `prepack` and `packages/pypi/scripts/vendor.py`
   runs as a hatchling build hook (both maintainer-side builds, per `infrastructure.md`
   § "Distribution Channels"); `profiles/` is already "treated as committed build output that must
   always equal a fresh render", gated by render-drift (`infrastructure.md` § "The Build:
   Multi-Profile Render"); and D18 replaced a shipped runtime engine with a **pre-rendered** asset in
   this very artifact family.

Shape 5 is called out because §5.6 consequence 2 warns specifically about "a generate-time dependency
chain — `node_modules`, a lockfile, and a bundler" being added "to a repository whose CLI is currently
pure Bash/Node-stdlib". That warning is about the cost landing at **adopter** time, when `/aid-graph`
runs. A maintainer-time build answers the warning without giving up a real toolchain, and the research
should say plainly whether that is available for its recommendation or not.

**Step 4 — Screen before measuring.** Hard screens; failing one removes the candidate, it does not
lower its score:

1. Can reach WCAG AA for the graph rendering with the accessibility work priced in (NFR-1).
2. Can be driven from `relationships.md` alone via feature-007's lens view-model — no second
   extraction path (FR-3, AC-10).
3. Can honour reduced-motion settling, keyboard zoom and pan, and non-colour encoding (NFR-4–NFR-6).
4. Can express the four lenses including Impact's adjustable-depth neighbourhood, with manual
   controls live after arriving via a preset (FR-13, FR-14, AC-8).
5. Licence permits redistribution inside an artifact generated into a third party's repository, under
   this project's own MIT terms (root `LICENSE`).

**Step 5 — Spike the survivors.** Build a throwaway harness per surviving candidate against a
**self-built synthetic fixture** at the Step 2 scale — self-built and independent of any work
folder's contents, per A-6. Measure, do not estimate: legibility across the density range, the
interaction inventory, keyboard reachability and focus visibility, screen-reader behaviour,
reduced-motion settling, and payload. Spikes are throwaway; nothing from them ships, and none of
them touch product code.

**Step 6 — Confront the tension.** Work § the tension above explicitly, in the report.

**Step 7 — Decide and record.** Fill the matrix, name one recommendation, write the decision record's
fifteen parts. Then draft the `technology-stack.md` entry and, if a build step is recommended, the
`infrastructure.md` implications — drafted and ready to land, not landed (this feature writes no KB).

**Step 8 — Hand off.** This research *blocks* exactly one downstream feature by design, but its
findings are consumed by five.

| Consumer | Consumes | Note |
|----------|----------|------|
| feature-008 | the recommendation itself | The only feature this research **blocks**; its size swings on the answer |
| feature-007 | the runtime-prerequisite statement and the packaging shape | Owns `graph.html` as the entry point (A-4) and the shell the canvas mounts into |
| feature-009 | the accessibility-model finding | Owns the peer table rendering (NFR-2) and the AA bar overall |
| feature-011 | the validator-parameterisation requirement | Owns the shared-validator carve-out and the toolchain reuse |
| feature-012 | the drafted stack entry, the manifest impact | Owns the canonical registration and the distribution wiring |

Nothing else in the work waits on this. §10 states that if this research stalls, `relationships.md`
and the gap ledger still ship — which is the reason this is a separate feature from feature-001.

### Layers & Components

#### Where the output lives

| Output | Path | Lifetime |
|--------|------|----------|
| The research report / decision record | the path named in the RESEARCH task's `Scope` field under `.aid/works/work-005-knowledge-graph/`, assigned by `/aid-detail` | **transient** — disposable with the work folder |
| The spike harnesses and their fixtures | scratch space; not committed | throwaway by construction |
| The drafted `technology-stack.md` and `infrastructure.md` entries | inside the report, as drafts | land at ship time, by feature-013 |

The report is the only artifact this feature writes. It is pipeline evidence, so the work folder is
the right home — but by the same rule (`CLAUDE.md` § "Tracking discipline": no permanent artifact may
depend on a specific work folder's contents), **anything downstream that must survive the work has to
be restated in a permanent home**. Concretely: feature-008 may not cite the report as its source of
truth at ship time; the adopted approach's facts must be in `technology-stack.md` and in the skill's
own documentation.

#### What the delivered artifact looks like on disk

Fixed by FR-9 and A-4, and the packaging shape only fills in the companions:

- `.aid/knowledge/graph.html` — the documented entry point (A-4), beside `kb.html`.
- Companion assets, if the selected shape produces any, in a **subdirectory** under
  `.aid/knowledge/`, named so the KB index generator does not treat them as KB documents (FR-9).

That requirement is already satisfied structurally, which the research should note rather than
re-solve: `build-kb-index.sh` selects index entries with `find "$ROOT" -maxdepth 1 -type f -name
'*.md' ! -name '.*'`, and `INDEX.md`'s own frontmatter states the contract as "One entry per non-dot,
non-recursive KB document under `.aid/knowledge/`". So a subdirectory is outside the scan, and a
non-`.md` companion is outside it even at the top level — which is why `kb.html` is not in the index
today. `relationships.md`, by contrast, is top-level `.md` and therefore **is** indexed, which is
exactly what Q3 resolved.

#### Artifacts to update on adoption

Not this feature's writes. Which of these actually fire depends on the recommendation, and the report
says which:

| Artifact | Update | Fires when |
|----------|--------|-----------|
| `.aid/knowledge/technology-stack.md` § "Frameworks & Tooling" | A row for the adopted library or engine with its version and purpose | Any third-party adoption |
| `.aid/knowledge/technology-stack.md` § "Key Dependencies" | A row recording where the dependency lives and its concern. **State the scope precisely:** that section's standing claim is that "AID deliberately ships zero runtime dependencies for the CLI", which a library inside a *generated artifact* does not contradict — but the row must say so explicitly rather than leaving the claim ambiguous | Any third-party adoption |
| `.aid/knowledge/technology-stack.md` § "Build Commands" / § "Version Concerns" | A command and a version floor | Build step at maintainer or adopter time |
| `.aid/knowledge/infrastructure.md` § "The Build: Multi-Profile Render" and § "CI/CD Pipeline" | The new build stage and its CI lane | Build step at maintainer time |
| `canonical/aid/scripts/summarize/validate-html-output.sh` | Parameterise the `S2` offline-render assertion (whose failure message is "found CDN reference(s) in output HTML") and the `NM` no-Mermaid-engine assertion, so both keep firing for `kb.html` while `graph.html` is an explicit exception | Always — see below |
| The install and emission manifests | Account for any added file set; run the **full** generator so `profiles/*/emission-manifest.jsonl` and the render-drift gate stay green | Any new canonical file |
| `.aid/knowledge/capability-inventory.md` | The `/aid-graph` capability entry | Ship time |

The validator row fires **regardless of the recommendation**, and it is worth being precise about
why, because §5.6 consequence 1 states it in the general case and the script confirms it in the
specific: `validate-html-output.sh` documents `S2 Offline render — no external CDN script or link src
(self-contained)` and `NM No-Mermaid-engine assertion` in its own header, and implements `S2` by
grepping for `<script … src="https?://` and `<link … href="https?://`. `NM` fails on an inline
bundle over 100 KB containing `mermaid`, on a `mermaid.initialize()` call, and on a CDN-sourced
Mermaid script. FR-17 makes runtime JS mandatory for the graph, so `NM`'s intent does not apply to
it; a CDN shape would additionally trip `S2`. Both must be **parameterised, never weakened** —
`kb.html` keeps both checks unchanged (C-4, AC-17, and feature-011's own criterion that the carve-out
be "expressed by parameterization, not by a forked validator").

#### One open question, routed not answered

Whether `/aid-graph`'s outputs belong in `canonical/aid/templates/generated-files.txt` is **not**
settled here. That registry's own header says it is consumed by `/aid-discover`'s FIX state for an
end-of-cycle refresh-all, which would mean `/aid-discover` regenerating the graph — plausibly wrong,
since FR-7 makes `/aid-graph` a standalone on-demand sibling of `/aid-summarize` and not a phase of
discovery. Note that `kb.html` is likewise absent from that registry today. This belongs to
feature-010 (the skill runtime) and feature-012 (the wiring); it is recorded here because a
multi-file packaging shape is what makes it worth asking.

### External Integrations

This section exists because the amendment made third-party adoption a real option at any size. It
covers what the project takes on, and what the report must state.

#### Licence and attribution

- **The screen:** the licence must permit redistribution of the code inside an artifact this project
  generates into a third party's repository, compatibly with this project's own MIT terms (root
  `LICENSE`). Permissive licences (MIT, BSD, Apache-2.0) pass. A strong-copyleft licence does not
  pass this screen without an explicit owner decision, because the redistributed unit is a file
  landing in someone else's repository — the report must not treat this as a formality.
- **Apache-2.0 specifically** carries a NOTICE obligation that a single generated HTML file has no
  obvious place for. The report must name **where** attribution appears in the artifact — visible
  footer, HTML comment, an about panel, or a companion file — not merely that it is required. The
  third completion criterion asks exactly this.
- **Every candidate's licence is read from its upstream LICENSE file**, at the evaluated version. The
  dossier's licence claims (Cytoscape.js MIT, per js.cytoscape.org, accessed 2026-07-28) are inputs
  to verify, not facts to copy.

#### The update obligation, and who notices

This is the sharpest of the four §5.6 consequences and the easiest to under-answer, because the
project currently has **no automation that would notice**:

- `.github/dependabot.yml` declares exactly one ecosystem — `package-ecosystem: "github-actions"`,
  `directory: "/"` — so it watches SHA-pinned GitHub Actions and nothing else. No JS dependency,
  whether vendored into an artifact, pinned to a CDN URL, or declared in a scoped `package.json`, is
  watched by anything today.
- Vendoring is the worst case for detection: a blob inside a generated artifact has no manifest, so
  no tool can even see it. The report must answer "who notices" with a mechanism (a new dependabot
  ecosystem entry, a scoped manifest, a CI check, or a named human responsibility) — not with an
  intention.
- **Precedent worth using:** `canonical/aid/scripts/summarize/package.json` already exists as a
  scoped, `"private": true` manifest pinning `playwright` to an exact version (`1.61.1`) with
  `engines.node >= 20`, described in its own `description` field as "Dev/validator tooling … Not
  shipped to adopters", and accompanied by a `package-lock.json`. So a scoped manifest in a script
  area is an established shape here — but note the difference that matters: that one is
  **maintainer-side dev tooling**, whereas an adopter-time build dependency would run on the
  adopter's machine during `/aid-graph`. The two are not the same cost, and §5.6 consequence 2 is
  about the second.

#### Network and portability

- A CDN shape makes the artifact non-portable and network-dependent — a graph generated today may not
  render later or offline (§5.6 consequence 3). The requirement is not that this disqualifies the
  option; it is that the research **states the cost plainly** for whichever option it recommends, and
  **prefers vendoring when the interaction quality is comparable**. That preference is written into
  the requirement, so a CDN recommendation has to beat vendoring on quality, not merely tie it.
- A CDN shape also needs subresource integrity and a pinned version to be defensible at all, and it
  trips the `S2` assertion above, so it carries both a security and a toolchain obligation.
- AC-6 is the receipt: whatever is chosen, the runtime prerequisites are documented explicitly enough
  that a reader knows what the artifact needs to work.

#### Toolchain reach

Any adopter-time build step means `/aid-graph` can fail for reasons unrelated to the Knowledge Base —
a missing `node_modules`, a lockfile mismatch, a bundler error. §5.6 consequence 2 names this, and
C-5 sets the floor it inherits (Node ≥ 20 for validator tooling, with browser-backed validation
degrading gracefully when the browser is absent, as `/aid-summarize` already does). The report must
say what the skill's preflight has to check, and hand that to feature-010.
