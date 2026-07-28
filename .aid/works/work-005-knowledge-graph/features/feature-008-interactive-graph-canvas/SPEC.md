# Interactive Graph Canvas

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.6 (FR-2, FR-6, FR-18), §6.1 (NFR-4–NFR-6), §9 (AC-9, AC-15); STATE.md Q2 | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Requirements half realigned to amended FR-16 — packaging constraint withdrawn; renderer bound by the accessibility bar instead | /aid-specify |
| 2026-07-28 | Density paragraph corrected: the shared coverage predicate no longer reads `node.degree`, so the "thinning never hides a gap" guarantee now rests solely on the explicit `coverageGaps` exemption. Consequence of feature-007's shared-predicate fix; the `viewModel.coverageGaps` contract is unchanged | Owner review |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the attribution, `technology-stack.md` and update obligations of a vendored library are now **feature-012**'s. The two validator-parameterisation references stay with feature-011. No decision in this SPEC changes | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-2 (the interactive graph itself — layout, grouping, density, zoom)
- REQUIREMENTS.md §5.4 FR-6 (relation category as a grouping dimension the canvas honours)
- REQUIREMENTS.md §5.6 FR-18 (the rendering approach this feature implements)
- REQUIREMENTS.md §6.1 (NFR-4 reduced motion, NFR-5 colour never the sole carrier, NFR-6
  keyboard-equivalent zoom and pan); contributes to NFR-1 on the canvas side
- REQUIREMENTS.md §8 (A-5 node counts land in the hundreds, which is what makes the layout
  tractable — if a target project violates this, density controls alone will not rescue the view)
- REQUIREMENTS.md §9 (AC-9 reduced-motion clause, AC-15 graph side)

**Size depends on Q2's resolution.** This feature implements whatever feature-002 recommends, and
**its size swings substantially on that answer**: adopting a vendored library makes this feature
small and pushes attribution, technology-stack, and update obligations into feature-012, whereas
hand-rolling the layout makes this feature considerably larger and adds no feature-012 work.
Delivery sequencing must not size this feature before feature-002 lands. The feature *boundary* is
stable either way; only the effort is uncertain.

**Dependency position.** Blocked by feature-002 (the rendering decision) and feature-007 (the
shell and the lens view-model it consumes). This is the only feature feature-002 blocks — which is
what allows everything else to proceed while that research runs.

**Consumes feature-007's lens view-model as a contract.** Interpreting a lens differently from the
table rendering violates NFR-3 and AC-7.

**Shared acceptance criteria.** AC-9's reduced-motion clause is owned here while feature-009 owns
the accessibility bar overall; AC-15's graph side is owned here while feature-006 owns the ledger.
Both are mutual obligations.

## Description

This is the drawing itself: the part that turns the relationship table into a picture a reader can
move around in.

Nodes are laid out so that structure is visible rather than tangled, and the reader can regroup
them — by relation category, by document, by whatever dimension the shell exposes — and watch the
picture reorganise around the question they are asking. Density can be turned down when there is
too much on screen and turned up when detail is wanted. The view zooms and pans.

Three things about how it presents information are not negotiable. A reader who has asked their
system to reduce motion gets a settled graph rather than an animated one — the layout arrives
already resolved instead of shuffling into place. Meaning is never carried by colour alone: what
kind of node something is, and how its relationships were established, are also conveyed by shape
or by label, so the picture still reads for someone who does not distinguish those colours. And
every navigation action has a keyboard equivalent, so zoom and pan are not reserved for a mouse.

How the drawing is actually accomplished is decided by the rendering research, not here. **No
packaging constraint bounds that choice** *(FR-16 as amended 2026-07-28; C-1 withdrawn)* — the
result may be multi-file, may fetch from a hosted library, and may come from a build step. What
does bind it is the accessibility bar in §6: the renderer chosen determines how much of that bar
must be built by hand, since only DOM-based drawing yields accessibility semantics for free.

## User Stories

- As a **maintainer/architect**, I want to regroup and thin out the graph as I explore, so that I
  can move from an overview to a specific neighbourhood without losing my place.
- As a **maintainer/architect** who has asked for reduced motion, I want the graph to appear
  already settled, so that the view is usable rather than nauseating.
- As a **newcomer to the project**, I want node type and provenance conveyed by shape and label as
  well as colour, so that the picture reads for me regardless of how I perceive colour.
- As a **maintainer/architect** working from the keyboard, I want zoom and pan without a mouse, so
  that I can navigate the graph the same way I navigate everything else.

## Priority

Should

*In scope and required by §4; ranked Should rather than Must only because §10 states explicitly
that `relationships.md` and the gap ledger ship usefully with no view at all. This is a
schedule-risk ranking, not a statement that the graph is optional.*

## Acceptance Criteria

- [ ] AC-9 *(reduced-motion clause; the criterion overall is owned by feature-009 — mutual
      obligation)*: Given a reader whose environment requests reduced motion, when the graph
      loads, then layout animation is disabled and the graph renders already settled.
- [ ] AC-15 *(graph side; shared with feature-006, which owns the criterion — mutual obligation;
      neither feature may consider this met alone)*: Given a generated ledger, when the Coverage
      lens is applied to the graph, then the graph highlights exactly the gaps the ledger records.
- [ ] Given the rendered graph, when node type and provenance are examined, then each is conveyed
      by shape and/or label in addition to colour — colour is never the sole carrier of meaning.
- [ ] Given the rendered graph, when a reader uses only the keyboard, then zoom and pan are both
      achievable through keyboard equivalents.
- [ ] Given the relation categories from feature-001 and the grouping control from feature-007,
      when the reader groups by category, then the graph regroups accordingly.
- [ ] Given the density and zoom controls, when the reader adjusts them, then the graph responds
      and remains legible across the range.
- [ ] Given feature-007's lens view-model, when each of the four lenses is applied, then the graph
      interprets it identically to the table rendering — satisfying its half of NFR-3 and AC-7.
- [ ] *(rewritten 2026-07-28 — the single-file guarantee it asserted is withdrawn with C-1)*
      Given the approach recommended by feature-002, when the view is assembled, then whatever
      runtime prerequisites the renderer introduces — network fetches, companion assets, or a build
      output — are declared to feature-007 so they appear in the documented prerequisites AC-6
      requires, and the renderer's accessibility cost is carried by feature-009's peer view rather
      than left unmet.

---

## Technical Specification

> **The renderer is not decided here.** feature-002 owns that recommendation (FR-18, Q2) and this
> SPEC does not pre-empt it. What follows is written as a **draw-layer contract**: an interface the
> graph module must satisfy, plus the parts that genuinely change per renderer, each marked. The
> accessibility obligations hold under every candidate, which is the point of putting them on
> feature-007's shared model rather than inside the drawing.
>
> **Design pressure on record (research gathered 2026-07-28).** Only SVG and the DOM produce
> accessibility-tree semantics without hand-built proxies; Canvas and WebGL paint into an opaque
> buffer that exposes nothing to assistive technology, so the renderer choice sets how much
> accessibility work is manual — with SVG, "accessibility is dramatically cheaper". Renderer
> ceilings run roughly: SVG degrades past a few thousand marks, Canvas is CPU-bound in the tens of
> thousands, WebGL reaches hundreds of thousands. Candidate libraries in the 2026 landscape include
> Cytoscape.js (MIT, Canvas by default, strong graph algorithms), vis-network (physics and diagram
> editing), Sigma.js (WebGL over `graphology`), and AntV G6 (multi-renderer Canvas/SVG/WebGL with
> GPU layout). Two findings bear directly on this feature: Elastic's Kibana issue #248471 documents
> Cytoscape.js accessibility as poor **because** it is canvas-only — limited keyboard navigation,
> poor screen-reader support, absent focus indicators, minimal ARIA — and evaluates replacing it
> with a DOM-based renderer for exactly that reason; and Data Navigator (CMU DIG; npm
> `data-navigator`, IEEE TVCG 2023) exists specifically to build a navigable, semantic accessible
> HTML layer over any renderer, making it a candidate for the proxy layer if a pixel renderer wins.
>
> **The tension, stated plainly.** FR-16 dropped the packaging ceiling to allow maximum rendering
> power, but **A-5** bounds this project's node counts to the hundreds, and NFR-1 sets a hard WCAG
> AA bar. WebGL's advantage starts far above the scale in play while carrying the highest
> accessibility cost of the four approaches — so "most powerful renderer" and "best artifact" may
> point in opposite directions here. This SPEC therefore commits to an interface, not an engine,
> and the § "What changes with feature-002's answer" table below is the honest bill for each
> outcome.

### Data Model

**No persistent schema and no model of its own.** This feature adds *no* data structure. It reads
feature-007's `ViewModel` and holds exactly one piece of private, non-authoritative state:

| Structure | Fields | Lifetime | Authority |
|-----------|--------|----------|-----------|
| `LayoutCache` | `positions: Map<nodeId, {x, y}>`, `groupBoxes: Map<groupKey, {x, y, w, h}>`, `settledFor: number`, `bounds` | Discarded and recomputed when `viewModel.revision` changes in a way that alters membership or grouping | **Private.** Nothing outside this module reads it |

`settledFor` records the `viewModel.revision` the cached positions were computed for, so a
re-projection that changes only emphasis (a dim/highlight change) reuses the existing layout instead
of relaunching it — the picture must not jump when the reader only changed what is emphasised.

Everything else this feature draws from is feature-007's: `visibleNodes`, `visibleEdges`, `groups`,
`nodeEmphasis`, `edgeEmphasis`, `nodeLabels`, `counts`. Per that feature's API contract this module
reads `lensState` for **`zoom` only**; it never re-derives membership or emphasis, because doing so
would re-implement `project()` and reintroduce exactly the graph-versus-table drift NFR-3 and AC-7
forbid.

**No strength-driven encoding.** The `Strength` column was dropped (Q1, resolved 2026-07-28) and the
table is eight columns, so no edge weight, thickness, or spring constant is derived from row data.
Layout distance is conveyed by hop count, as the Q1 resolution intends.

### Feature Flow

1. **Mount.** `mountGraph(container, store)` subscribes to the store and performs a first render
   from `store.getViewModel()`. The module reports its own readiness; if it throws or is absent from
   the build, the shell and the table stay fully usable (feature-007 mounts the table first and
   unconditionally).
2. **Classify the change.** On each notification, compare `changedKeys` and `viewModel.revision`
   against `LayoutCache.settledFor` and take one of three paths:
   - **emphasis-only** (`emphasis` changed, membership identical) → repaint from cached positions.
     No layout, no motion.
   - **membership or grouping changed** → relayout, then repaint.
   - **`zoom` changed** → apply the viewport transform only; no layout, no repaint of marks.
3. **Lay out.** Run the layout to a **settled** result *before* the first paint (see
   § Reduced motion). Group boxes come from `viewModel.groups`, so grouping by relation category
   (FR-6) is a partition the shell already computed — this feature positions the partition, it does
   not decide it.
4. **Paint.** Draw edges, then nodes, then labels. Each mark's shape comes from `node.glyph` and its
   emphasis class from `nodeEmphasis` / `edgeEmphasis`; colour is applied *in addition*, never
   instead (NFR-5).
5. **Interact.** Pointer and keyboard input either write to the store (`setLens`, for selection and
   depth) or update `zoom` (for viewport moves). Nothing else in the page is touched directly —
   selecting a node changes the table too, because the selection went through the store.

### Layers & Components

Authored canonically and rendered to every profile by the existing generator (**C-2**); rendered
copies are build output and are never hand-edited (`module-map.md` § Invariants).

```
canonical/aid/templates/knowledge-graph/
├── graph-canvas.js       # THIS FEATURE: draw layer, layout, interaction, a11y proxies
├── graph-model.js        # feature-007 — consumed, never modified
├── graph-css.css         # shared; this feature adds only mark/surface rules
└── (vendored renderer)   # present only if feature-002 recommends a library; see below
canonical/aid/scripts/graph/
└── (none owned by this feature)
```

**Vendored third-party code, if any.** A library adopted by feature-002 is vendored under
`canonical/aid/templates/knowledge-graph/vendor/<name>/`, carrying its upstream licence text
verbatim alongside it. Because the KB index generator enumerates candidates with
`find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`, and the vendored tree lives in the
canonical template area rather than in `.aid/knowledge/` at all, nothing here can be mistaken for a
KB document. Attribution, the `technology-stack.md` entry, and the update story are **feature-012's
and feature-002's** deliverables (FR-16 consequence 4; feature-002's acceptance criteria name the
licence, attribution, and update-story reports) — this feature's obligation is to consume the
vendored code without forking it and without adding a second copy.

**Reuse, not reimplementation (FR-12, C-4, AC-17).** This feature adds no assembler and no
validator. Its module is inlined into the page by the same `post-script.html` slot feature-007
assembles with `canonical/aid/scripts/summarize/assemble.sh`, and its styling consumes the palette
in `canonical/aid/templates/knowledge-summary/design-tokens.md` via `var(--token)` without
declaring a new colour — so `contrast-check.mjs` keeps passing on the pairs it already knows.

#### What changes with feature-002's answer

Every row below is a place this SPEC would be revised. Nothing outside this table is
renderer-dependent, which is the property the accessibility-model-beside-visual-model pattern buys.

| Concern | Native SVG | Canvas | WebGL |
|---------|-----------|--------|-------|
| Mark elements | Real DOM nodes; semantics inherent | Pixels; no elements | Pixels; no elements |
| Per-mark focus | Native `tabindex` / `focus()` on the mark | Hand-built DOM proxy layer, kept aligned on resize | Proxy layer, coarser granularity; no per-mark focus in practice |
| Accessible names | `aria-label` directly on the mark, from `nodeLabels` | Proxy element carries the name | Aggregate summaries carry it |
| Hit testing | Browser-native | Manual, against `LayoutCache.positions` | Manual, plus picking buffer |
| **S7 / `validate-visuals.mjs`** | The collector walks every `<svg>`, so the live surface **is** collected and **T2 fails by design** — sibling `<g>` boxes may not overlap by more than 20% of the smaller area, and overlapping groups are what a graph layout *is*. **T1** can also fail on labels below a 10 px rendered size. Needs a parameterised exclusion (feature-011). | `<canvas>` matches none of `.diagram-box`, `.infographic`, `svg` — **not collected, no exemption needed** | Same as Canvas — **not collected** |
| Proxy drift risk | None | Real: proxy-to-pixel coordinate drift on resize | Real, and coarser |
| Candidate prior art | AntV G6 (SVG mode); Data Navigator unnecessary | Cytoscape.js — accessibility documented as poor precisely because canvas-only (Kibana #248471); Data Navigator a candidate for the proxy layer | Sigma.js / G6 GPU; Data Navigator a candidate |
| Payload and build step | Smallest; may need no build | Medium | Largest; most likely to need a bundler and a lockfile (FR-16 consequence 2) |

Two things do **not** change with the answer, and both are load-bearing:

- **S2 and the S7 hermetic render are packaging-dependent, not renderer-dependent.** `S2` greps for
  `<script src="http…">` / `<link href="http…">`, and `validate-visuals.mjs` aborts every request
  whose URL does not begin with `file://`. So a CDN layout fails S2 *and* renders without its
  renderer under the visual gate, whichever engine is behind it (FR-16 consequence 3).
- **`NM` is Mermaid-keyed.** Its three sub-checks look for a non-`text/markdown` inline `<script>`
  over 100 KB containing the token `mermaid`, a `mermaid.initialize(` call, and a CDN `<script src>`
  whose URL contains `mermaid`. A non-Mermaid graph engine trips none of them, so `NM` passes
  unchanged and needs an exemption only if the adopted bundle happens to match one of those literal
  patterns. Owning any needed parameterisation is feature-011's; `kb.html` keeps both checks
  unchanged either way (FR-16 consequence 1).

### External Integrations

Only if feature-002 recommends a library. The integration surface is deliberately narrow so the
choice stays reversible:

| Aspect | Contract |
|--------|----------|
| Delivery | Vendored into the canonical template tree; no package manager at the adopter's runtime |
| Coupling | Confined to `graph-canvas.js`. The library never sees `LensState`, never sees `GraphModel`, and never becomes a data model of its own — it receives node ids and positions and returns geometry |
| Data hand-off | Ids and positions only. `visibleNodes` / `visibleEdges` are read from `ViewModel`; a library's internal graph object is a rendering detail, discarded on relayout |
| Licence and attribution | Reported by feature-002; landed by feature-012. Upstream licence text travels with the vendored tree |
| Update story | Reported by feature-002; owned by feature-012 |
| Build step | Permitted by FR-16. If adopted it adds `node_modules`, a lockfile and a bundler to a repository whose CLI is otherwise pure Bash and Node stdlib, touching `technology-stack.md`, `infrastructure.md`, CI, and `/aid-graph`'s preflight — and it means the skill can fail for reasons unrelated to the KB (FR-16 consequence 2). Node tooling in this repo requires **Node ≥ 20**, the floor the validator tooling's own `package.json` declares (**C-5**) |
| Failure mode | If the library is missing or throws at load, this module reports not-ready and the shell plus the table stay fully usable. The artifact never becomes unusable because the drawing failed |

An accessibility-layer dependency (for example npm `data-navigator`, which builds a semantic
navigable HTML layer over any renderer) is admissible on the same terms and would be adopted only
if feature-002 selects a pixel renderer — under SVG the semantics come free and the extra dependency
buys nothing.

### UI Specs

#### Component breakdown

| Component | Role | Accessibility contract |
|-----------|------|-----------------------|
| Graph surface | The drawing surface inside feature-007's `<section aria-label="Relationship graph">` | `role="application"` with an `aria-roledescription` naming it a relationship graph, so the reader is told the arrow keys are the graph's rather than the browser's |
| Surface description | A visually hidden paragraph referenced by `aria-describedby` | States node and edge counts from `viewModel.counts`, the active lens, and how to navigate. Rewritten on membership change, not per frame |
| Mark layer | Nodes and edges | Shape per `node.glyph`; emphasis per `nodeEmphasis` / `edgeEmphasis`; colour additive only |
| Focus ring | The current graph focus | Drawn as a ring **plus** a persistent label, so focus survives at low contrast and in forced-colors mode |
| Group frames | One frame per `viewModel.groups` entry, with a visible caption | The caption is the group's `label` — text, not a colour key |
| Viewport controls | Zoom in, zoom out, reset, fit | Real `<button>`s with `aria-label`s; the keyboard equivalents below are in addition, not instead |
| Legend | Glyph-to-meaning and provenance-to-marker mapping | An authored `.diagram-box` visual; stays inside the S7 gate |

#### Keyboard equivalence (NFR-6)

Every navigation action has a keyboard route, and the surface is one tab stop — not one per node —
per the research's guidance against exposing every datum as a tab stop.

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Move into and out of the graph surface as a single stop |
| Arrow keys | Pan; with `Shift`, move graph focus to the nearest mark in that direction |
| `+` / `-` | Zoom in / out by one step |
| `0` | Reset zoom and pan to fit |
| `Enter` / `Space` | Select the focused node — writes `focus.nodeId` through the store, so the table follows |
| `[` / `]` | Decrease / increase `focus.depth` (Impact lens) |
| `Escape` | Clear graph focus without clearing the lens |

Zoom and pan are `zoom`-only writes and never re-project, so keyboard navigation cannot desynchronise
the two renderings. Selection and depth go through `setLens`, so they always do.

#### Reduced motion (NFR-4, AC-9 reduced-motion clause)

The obligation is a *settled* graph, not merely a faster animation, so it is met in the layout
stage rather than in CSS:

1. Read the preference once with `window.matchMedia('(prefers-reduced-motion: reduce)')` and
   subscribe to its `change` event.
2. When reduced motion is requested, run the layout to convergence **before the first paint** — a
   fixed iteration budget with an early exit on a movement threshold — and paint once. The graph
   arrives already resolved; no tick is ever painted mid-simulation, and no transition is applied
   to mark position.
3. When it is not requested, the same settled result may be reached with animated ticks; the
   converged positions are identical, so the two paths differ only in what the reader watches.
4. Every transition and animation this feature adds is additionally covered by the reused
   `@media (prefers-reduced-motion: reduce)` block in
   `canonical/aid/templates/knowledge-summary/component-css.css`, which is what
   `validate-html-output.sh`'s A4 asserts. The CSS block is the backstop; **the pre-settled layout
   is the actual compliance**, because a CSS rule cannot un-shuffle a simulation that paints while
   it runs.

This is renderer-independent: all three candidate engines can be stepped headlessly to convergence
before the first paint.

#### Colour is never the sole carrier (NFR-5)

| Meaning | Non-colour carrier | Colour (additive) |
|---------|-------------------|-------------------|
| `kind: kb` | Rounded rectangle + `kb:` id prefix in the label | `--accent` |
| `kind: int` | Square + `int:` id prefix in the label | `--info` |
| `kind: ext` | Diamond + `ext:` id prefix in the label | `--purple` |
| `provenance: declared` | Solid edge stroke | `--ok` |
| `provenance: derived` | Dashed edge stroke | `--info` |
| `provenance: inferred` | Dotted edge stroke + an `inferred` badge on hover and on focus | `--purple` |
| `kb-unbacked` | Hollow fill + a `no source` label | `--warn` |
| `int-undocumented` | Hollow fill + a `no KB doc` label | `--err` |
| `dimmed` | Reduced opacity **and** label suppression | `--text-dim` |

The `glyph` token comes from `GraphModel`, so the graph and the table name a node's kind the same
way. Because the id prefix (`kb:` / `int:` / `ext:`) is already part of every id (§5.3), the label
alone carries kind even with no shape and no colour at all — which is what keeps the encoding honest
under forced-colors mode.

#### Density, legibility and responsive behaviour

`density` thins by `node.degree`. The coverage predicate does **not** read that counter — it is
edge-shape-aware, not degree-based (feature-007 § "The coverage predicate") — so thinning and gap
detection are independent, and the guarantee that thinning never hides a gap has to be explicit
rather than incidental. It is: when `emphasis === 'coverage'`, nodes in `viewModel.coverageGaps` are
exempt from density thinning. A lens whose whole purpose is to surface gaps must not let an
unrelated slider hide them, and this exemption is the concrete mechanism behind this feature's half
of AC-15.

Labels are suppressed below a legibility threshold rather than shrunk, so no text is ever painted
under the 10 px rendered size `validate-visuals.mjs` treats as illegible (T1) — a rule worth keeping
even where the surface is not collected by that gate, since the reason behind the threshold is the
reader, not the script. The surface fits its container at both widths the visual gate measures
(732 px and 390 px) and never overflows horizontally (T4); the mobile breakpoint is 768 px, matching
`design-tokens.md` § "Spacing & sizing".

#### Frame budget

Per the research, the expensive accessibility operations are forced accessibility-tree rebuilds from
writing many ARIA attributes or live-region updates per frame — not the visual draws. So: ARIA
attributes and the surface description are written **only** on membership change; the live region
belongs to feature-007 and is written once per lens change; and no ARIA write, and no live-region
write, ever happens inside a layout tick or a repaint.
