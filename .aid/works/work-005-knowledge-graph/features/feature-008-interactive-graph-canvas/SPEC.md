# Interactive Graph Canvas

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-30 | **Authored fresh against the amended REQUIREMENTS.md and the frozen 001–007 spine (STATE.md Q24 item 6, Q26 § Fresh authoring); it supersedes the 2026-07-28 pre-decision draft in whole rather than editing it.** That draft specified a renderer-agnostic "draw-layer contract" settling once before first paint, tabulated Native SVG / Canvas / WebGL across per-mark focus and accessible names, planned a hand-built DOM proxy layer, keyed its non-colour encoding on the `kb:`/`int:`/`ext:` id prefix, and cited an eight-column table — every one of which an owner decision has since withdrawn. Nothing was edited into shape, because a clause keyed on a superseded model stays grammatical while becoming false, which is the mechanical cause of this work's proxy-defect class (Q17, Q21). **Owner decisions implemented:** the graph is **live** — `d3-force` for physics plus **PixiJS (WebGL)** for drawing, 2D — and it **animates by default** (FR-2, FR-18, Q9); the canvas is **visual-only** with WCAG AA carried by the accessible table view as the conforming alternate version, and **no DOM proxy layer is built** (Q9, NFR-2, AC-9 as scoped); **NFR-4's settled render is the reduced-motion fallback, not the default**; edges are **directed**, and a symmetric relation is drawn with **no arrowhead**, the absence being the signal (Q11, Q14 item 5); relationship category is carried by **colour and line style**, the relationship **name on hover or selection**, with no persistent edge labels (Q11 as amended); **filtering by category is required** (FR-6a); and **no degraded rendering mode is built** (Q14 item 7, §4). **delivery-001's research is void** — `deliveries/delivery-001/FINDINGS.md` is stamped SUPERSEDED — so the 784-node bench, A-5's withdrawn figure and every performance conclusion resting on either are asserted nowhere here; § Figures states the rule and makes it true, and NFR-7/AC-6a name **feature-002** as the owner of the bench and of every figure. **Discharges feature-002 Open Item 5** by construction: the renderer-comparison table and the no-new-colour-token claim are absent rather than corrected, and the void ~279-line estimate was never any revision of this SPEC's own figure but delivery-001's *about* it | /aid-specify |
| 2026-07-30 | **First review cycle closed against the gate ledger.** The draw record gains `reveal` and `captions` — the two drawn-text fields GC02, GC05 and GC11 were asserting against nothing — and `marks` gains `emphasisDraw`, so GC14's distinguishability is read rather than argued. The gap classes are marked by a **badge beside the mark** instead of a hollow centre, which was feature-007 D5c's `web-page` glyph (:782); emphasis keeps an ordinal channel under forced colours in **stroke weight**, free because the `Strength` column was dropped, so `'dimmed'` and the previously unmapped `'chain'` each have one. GC05 no longer claims all four presets differ from the initial projection, which feature-007 :828–:829 falsifies for Impact. The canvas's `width`/`height` are stated as what they are — the drawing buffer, hence two attributes — with AC-S8, AC-9 and GC09 scoped to match. **AC-S9**/**GC18** and **AC-S10**/**GC19** hook the two node gestures and the unavailable path, which had none; sweeping the same class hooked the viewport gesture's single commit, resize invariance, the mid-session preference flip and quiescence, and excluded the label floor explicitly. Open Item 3 is corrected: `CONTROL_MANIFEST` is already satisfied, and the real gap is that reset-to-fit and the step factor live behind the canvas's private `positions`. `groups` gains the layout half D1 claimed; the picking index is this module's own code; feature-002 D6's expired claim about this SPEC's vendor path, and the ~279-line estimate's true provenance, are recorded rather than adopted. § Shared, § Figures, three misattributed quotations and one blank-line citation corrected | /aid-specify |
| 2026-07-30 | **Second review cycle closed.** The forced-colours ordinal channel is re-derived over feature-007 D5c's glyph table rather than over the dropped `Strength` column, which was only ever an edge argument: every kind that table draws *filled* has no stroke for a weight to grade (:776–:781) and the one it draws as a stroke, `web-page`'s ring (:782), is closed into `document`'s circle by a heavier weight, so a node's channel is **mark scale** — uniform, shape-preserving, and carrying nothing else in this work — while an edge keeps stroke weight. **GC14** now fails where a class records no channel value instead of passing on a field name, and **GC13** states why a recorded glyph *name* suffices: no channel alters a glyph's outline. Hover's highlight moves to `reveal.neighbourhood`, the one hover-written field, so **GC02** no longer asserts a change to per-projection `marks` — which no hover may write in any case (rule 1). The double-click clauses are restated to what the platform dispatches: two `click` events precede every `dblclick`, so the repeat click is ignored by its own `MouseEvent.detail` and the pair writes the leading click's single patch. **A resize is not a perturbation** — the forces run in a coordinate space no container measurement enters — which settles the new resize clause against § The simulation's resume list; **AC-S3** and **GC16** now name the read point of every exact-identity clause, at rest or at the notification, and `positions` is declared at that notification. Frame samples carry the `applied` transform, so **GC18** reads the gesture window where the transform actually moves. Open Item 4 splits **GC09** by half; § Discharged drops the last figure value and § Figures' confinement claim is restated over values rather than names. Sweeping the classes: every `GC*` was re-checked for vacuity and for the cadence of each field it reads — `frames[].t` and `alpha` gained their reader in **GC01**, `mode` and `forcedColours` declare the at-mount write the unavailable path and **GC14** depend on, four quantifiers an empty record would have satisfied are pinned (**GC13**'s one mark per drawn id, **GC14**'s fixture presenting each class, **GC16**'s populated `positions`, **GC17**'s drawn frames), and the criterion column now names **AC-S4** and **AC-S8** where their hook lists already pointed — and AC-S3's own emphasis-only clause turned out to need the same at-rest read point the resize clause does | /aid-specify |
| 2026-07-30 | **Third review cycle closed.** The vacuity pin written last cycle was itself vacuous: **GC13** pinned `marks` against `nodes` and `edges` — two of the record's *own* fields, so `0 = 0` held over an empty record and every quantifier after it stayed vacuous — and **GC14** inherited that hole. Both are now pinned against the `ViewModel`, which no do-nothing canvas can empty: GC13 against `visibleNodes` and the non-collapsed `visibleEdges` keys, GC14 against the classes each of **two** lenses presents (`emphasis` is single-valued, so the gap classes and `'chain'` cannot share one). Re-running that audit over all nineteen hooks against a canvas publishing empty arrays with a populated `ViewModel` caught two more of the same class: **GC08**'s identical-`positions` clause and **GC06**'s change-to-the-record clause, both now pinned, with **GC16**'s "populated `positions`" raised to the same external form and **GC03**'s and **GC04**'s givens tightened to the preference and the drawn node each needs. The **ordinal emphasis channel is asserted on the default path**, not only under forced colours — GC14 reads a non-null, ordered `opacity` in the same projections without the preference, so a canvas that copies every class and draws them all alike fails; **AC-7** gains it as a hook. **`captions` gains a failing reader** in **GC15** — the `counts` echo, one caption per group with its `label`, and each folded head's *n* from `foldedInto` — where before it was read only by one disjunct of GC05's "at least one of" and so could be absent with every hook green. **`'settled'` is defined as a standing mode**: every perturbation resumes the loop unpainted and paints once, the one exception being the pointer's own motion in a drag, which resolves § Reduced motion's former absolute against § Interaction's drag row and gives GC08 the crossing the two lacked; `'unavailable'`'s inputs are stated with it, and a viewport gesture is marked tick-free in both modes. feature-007 :645–:647's channel list is read **descriptively**, its normative clause being colour-alone, so mark scale is an additional channel rather than a re-reading | /aid-specify |
| 2026-07-30 | **Fourth review cycle closed** — two residual defects inside the pair of hooks NFR-5 rests on. **GC14**'s edge order asserted a step no projection can present: `'chain'` exists only under `'provenance-chain'`, which D6f marks the chain with and **dims the rest** (feature-007 :1030–:1031), so lens A draws no `'normal'` edge, while `'coverage'` marks node classes only (D6d) and `'none'` drives no lens-level dimming (:581), so `'normal'` never stands beside another edge class. The edge order now runs `'dimmed'` → `'chain'` under A with an entry pinned at each, and the `'dimmed'`-versus-`'normal'` relation is recorded as **unreachable** rather than asserted — the rule being that an order is asserted only where one projection presents both its members. **GC13** compared a mark's content to the record's **own sibling** `kind`, so a canvas keying its encoding on the id prefix — Q21's proxy class, and this work's founding defect — or permuting glyphs and tokens across ids published a self-consistent record and passed all nineteen hooks. Every mark's content is now compared to the `ViewModel` entry for **its own id or key** — `kind`, `glyph`, `colourToken` and `emphasis` on a node, `row`, `category`, `colourToken`, `lineStyle`, `arrowhead` and `emphasis` on an edge — and the fixture carries feature-007 **AC-S3**'s `ext:` pair (its :249–:255, GV12 :1806) mirrored over the record, the one construction no id-deriving canvas can produce. Re-deriving the field-to-reader map for a **wrong** value rather than an absent one closed the rest of that class: **GC10** gains `revision`'s equality and greps `prefix` and the quoted prefix literals — so § The canvas boundary's `prefix`-nowhere claim is asserted rather than argued — and **GC12** gains `viewport`'s equality with `lensState.zoom` between gestures, so a transform applied wrongly fails and not only one applied late | /aid-specify |
| 2026-07-30 | **Upstream re-sweep: feature-007 reopened under a scoped freeze exception for four seams, and its extended Open Item 13 (its :1985–:1990) answers Open Items 1, 2 and 3 of this SPEC in place.** All three are **closed as answered** and keep their numbers. **(1) The routed density exemption is withdrawn** — D1a refers the case to D10 (its :387–:388) and D10's density row is the whole rule (its :1451) — ratifying what § Density already drew; the guarantee that survives is over the gap **set**, which is `R ∪ G` computed once per load and keyed over neither `visibleNodes` nor `LensState` (its :1369–:1373), so AC-15 binds on the set. **(2) The preferences have a carrier**: `createStore`'s third argument with `getPreferences` / `setPreferences` / `subscribePreferences`, detection staying in the shell (its :609–:615), so § Reduced motion's interim `matchMedia` self-read is **withdrawn** and **GC10** greps for its absence; the route is a separate subscription because a flip advances no `revision` and notifies no `subscribe` listener, which is what this SPEC needed given it derives nothing from `changedKeys`. **(3) `mountCanvas` returns D8's viewport handle** — `{viewportFor(action)}` over the seven action tokens, the canvas computing and the shell's own handler writing through `setLens({zoom})` (its :1148–:1155) — so **GC12**'s fit clause becomes implementable and gains an external pin. **(4) `nodeEmphasis`'s precedence is now total with `'focus'` first (its :630), and that is the one real mechanism consequence here**: a *selected* gap node reads `'focus'`, so a class-derived gap badge vanishes from it, and GC11 ran only at the Coverage preset's `focus.nodeId: null` where no hook could see it — defeating AC-15's canvas half under a live selection. The badge is therefore driven by **`coverageGaps` membership** — the route D4 states generically — moved out of `emphasisDraw` into its own `gapBadge` mark field with its own § What is drawn row, and **GC11** gains the selected state plus a neither-list pin that fails a badge-everything or prefix-keyed implementation. Every feature-007 line anchor re-verified on disk against the 2,017-line revision and re-pointed | /aid-specify |

## Source

Line citations of the form `:N` are into the cited feature's own `SPEC.md`, read 2026-07-30.

- REQUIREMENTS.md §5 — **FR-2** (the view is **live, continuously-simulating, interactive**), **FR-3**
  and **AC-10** (the table is the single input; nothing this feature draws comes from anywhere else)
- REQUIREMENTS.md §5.6 — **FR-13** (the four lenses this surface renders), **FR-14** (controls stay
  usable), **FR-14a** (`density` is **view** density and **not** an exposure of `d3-force`'s physics
  parameters; the **two node gestures**; the open target `./external-sources.md` for a `web-page` or
  external `image`, owner decision, which this feature reaches through the store rather than resolving),
  **FR-15**, **FR-16** (packaging unconstrained), **FR-17** (runtime JS mandatory), **FR-18** (the
  **decided** architecture: `d3-force` + PixiJS (WebGL), 2D; the remaining research is a
  viability-and-performance validation)
- REQUIREMENTS.md §5.4 — **FR-6** (category as a grouping dimension), **FR-6a** (filtering is a
  required feature), **FR-6b** (the palette does not grow with the category count)
- REQUIREMENTS.md §6.1 — **NFR-3** (a lens means the same thing on both renderings), **NFR-4**
  (reduced motion is the **fallback**), **NFR-5** (colour never the sole carrier: node kind by colour
  **and shape**, category by colour **and line style**, the name on hover or selection, direction by an
  arrowhead whose **absence** signals symmetry), **NFR-6** (every gesture has a keyboard equivalent;
  **dragging is exempt** as path-dependent), **NFR-7** (**≥30 fps** at the project's derived bench during
  both steady simulation and node drag, measured headless), **NFR-8** (the ceiling is measured and
  documented; the warning is feature-010's)
- REQUIREMENTS.md §7 — **C-2** (canonical authoring, rendered per profile), **C-4** (reuse, never fork),
  **C-5** *as extended* (Playwright may be provisioned **and still unable to draw**), **C-8**
  (`graph.html` is deliberately not dashboard-reachable)
- REQUIREMENTS.md §8 — **A-4** (`graph.html` is the entry point), **A-6** (self-built fixtures),
  **A-5** (**void**; no bench figure is stated anywhere and none is stated here)
- REQUIREMENTS.md §9 — **AC-6** ("renders successfully" means the live simulation runs), **AC-6a**
  (NFR-7's floor, headless), **AC-7**, **AC-8**, **AC-8a**, **AC-9** *as scoped* (the DOM-level checks
  bind page structure and the table view, **not** the canvas, which carries only a text alternative),
  **AC-15**, **AC-21**
- REQUIREMENTS.md §4 Out of Scope — no degraded rendering mode, no dashboard reachability, no
  function- or symbol-level source nodes; and gaps are reported, never gated
- STATE.md `## Cross-phase Q&A` — **Q9** (live graph; visual-only canvas), **Q11** (edge encoding and
  the ~8-colour/4-line-style design ceiling), **Q13** (concept merge; the ≥30 fps floor; settle time
  reported and not gated), **Q14** (the `Kind` columns; no arrowhead for symmetric; filtering required;
  no degraded mode), **Q17** with **Q19** and **Q21** (proxy-keyed clauses, the count-that-*is*-the-contract
  exemption, and the rule that a prefix is right about **where an id comes from** and wrong about **what
  class a node belongs to**), **Q18 ruling 3**, **Q20 (A-5 figure)** (requirements state derivations,
  research states figures; read every occurrence), **Q20 (loader sync)** (an item routed into a gated SPEC
  is a pending reopen), **Q23**, **Q25**, **Q26** (fresh authoring; mechanism versus editorial; the freeze)
- **feature-007 — the primary input, consumed as a fixed contract and never re-litigated.** The
  `ViewModel` (D4, :623–:643), `LensState` (D3, :568–:583), the store surface and the **consumer rules**
  (§ API Contracts, :1638–:1697, cited individually by their own numbers below), the **preference route** —
  `createStore`'s third argument with `getPreferences` / `setPreferences` / `subscribePreferences`, detected in
  the shell (D3 :609–:615, :1656, :1660) — `KIND_ENCODING` (:1646) with D5c's glyph per kind (:774–:782),
  `CATEGORY_ENCODING` (:1648) with D5b's colour-and-line-style assignment (:725–:755), the palette as CSS
  custom properties resolved at draw time (D5a row 1, :686) with **its AC-S4** (:261–:264), forced colours
  (D5d, :790–:802), `nodeEmphasis`'s total precedence and the edge axis's exhaustion (D4, :630, :631), the
  preset patches (D6a, :815–:818), the Overview fold (D6c, :881–:920), the Impact lens (D6e, :1021–:1026),
  the **viewport handle** (D8, :1148–:1155), the mount order (Feature Flow step 6, :1510–:1515), the
  announcement and `canvasAlt` writes (step 8, :1520–:1524), **exactly two live regions** (:1526–:1531), the file tree
  (:1540–:1552), the packaging constraint that the vendored bundles are **classic scripts** (:1599–:1603),
  the AC-6 prerequisite emission (:1604–:1609), the **validator surface** — a `<canvas>` matches none of
  `validate-visuals.mjs`'s three selectors, so the T2 exclusion is a recorded no-op (:1624), and the canvas
  element "carries **only a text alternative**" (:1626) — the responsive contract (:1743–:1751), the
  keyboard row that makes zoom and pan this feature's (:1770), the reduced-motion row that makes the
  settled layout this feature's (:1778), and the tab-stop granularity rule (:1781–:1784)
- **feature-002** — the FR-18 validation. Stage 2b derives the bench and returns the floor verdict
  (:348); **D4** is the measurement set, five of whose measurands are this feature's cost drivers —
  directed-edge arrowheads, four line styles, hover labels at the maximum-degree worst case, node drag,
  and filtering at the full category count (:638–:648); **D4b** fixes the ≥30 fps predicate and requires
  the harness to instrument **in the page** (:680–:721); **D5** owns the ceiling (:723); **D1a**'s
  `L1 ✓ L2 ✓ L3 ✗` row names this feature as the owner of one of its two fallbacks (:437); and **no
  permanent artifact may cite its report** (:1063)
- **feature-001** — the relation category set and its per-category meanings (D5, :613), and the
  eight-colour legibility consequence (D5a, :673). This feature consumes the category set **through**
  `GraphModel.categories` and `CATEGORY_ENCODING` and enumerates no category itself
- **feature-003** — the ten-column contract (D1, :239), the `Kind` enum (D1a, :334), the id grammars
  (D2, :387), display names (D5, :1233), and row normalisation and ordering with `rel_row_key` (D7,
  :1284, its row-key paragraph at :1306), which is the identity `Edge.key` carries
- **feature-004** (:388, :436) and **feature-005** (:342) — what the picture contains: the enumerated
  `source-artifact`, `image` and `web-page` nodes, and the Knowledge-Base-side kinds feature-003's `Kind`
  enum names. Both reach this feature only through the table
- **feature-006** — the gap ledger and the `kb_gaps` carrier (D6, :590) and the lens/ledger asymmetry
  (D6a, :708). This feature computes no coverage and reads `ViewModel.coverageGaps`

**Dependency position.** Blocked by **feature-007** (the shell, the store and the projection) and by
**feature-002** for three verdicts and no more: Stage 1's WebGL-under-headless result, Stage 2b's floor
verdict, and Stage 3's adopted bundle shape. Blocked by **feature-003**, **feature-004** and
**feature-005** only for real data. Blocks nothing.

**Shared acceptance criteria**, scoped as each criterion's annotation below states it. **AC-7**, **AC-8a**
and **AC-21** are shared with **feature-007** (the shell) and **feature-009** (the table view) — the three
feature-007's list names (:110–:112) — and **AC-9**'s non-canvas clauses are theirs; **AC-6**, **AC-8** and
**AC-10** are shared with feature-007 alone, **AC-15** with **feature-006** and feature-007. Each is a
mutual obligation, met by no owner alone. **feature-009 is authored concurrently from the same frozen
inputs**; where the two must agree, this SPEC states the obligation as feature-007 fixes it (Open Item 6).

## Description

This is the picture, and it is alive. Nodes drift toward equilibrium from the first frame rather than
arriving pre-arranged; dragging one pulls its neighbours; hovering one lights up its neighbourhood and
dims the rest; the relationship's name appears when a reader hovers or selects rather than being painted
on every line every frame. A reader who has asked their system for less motion gets the settled picture
instead — that is the fallback, and the only one.

Everything the picture shows is decided before it is drawn. The shell reads the relationship table once,
interprets the lens once, and hands over a list of the nodes and edges that are visible, what each is
called, what shape and colour token each carries, which are emphasised and which are dimmed, and — where
a lens has folded a document's sections back into the document — which two nodes each surviving row is
drawn between, or that it is drawn at all. This feature draws exactly that and decides none of it — because
the moment a drawing works out for itself which marks exist, the graph and the table can disagree about what
the reader is looking at, which is the one failure the two renderings exist to make impossible.

The drawing surface is a bitmap, and this feature does not pretend otherwise. There are no controls
painted on it, no per-mark focus ring, no invented accessibility tree standing in for one. Every control
is a real element in the page around it, the table beside it carries the same data as text, and the
canvas itself carries one sentence describing what it shows. What the surface does carry is the part a
bitmap can carry honestly: shape for what kind of thing a node is, line style for what kind of
relationship an edge is, an arrowhead where a relationship reads in one direction and none where it
reads both ways, and — where the reader's system has taken colour away entirely — those three channels
with no colour at all.

## User Stories

- As a **maintainer/architect**, I want the graph to move — to drift, settle, and respond when I drag a
  node — so that I can feel the structure rather than read a diagram of it.
- As a **maintainer/architect**, I want hovering a node to light up its neighbourhood and dim the rest,
  so that I can follow one thread without filtering the rest away first.
- As a **maintainer/architect**, I want the relationship's name when I ask for it and not before, so
  that the picture is legible at the density I actually work at.
- As a **reader who has asked for reduced motion**, I want the graph to be there already, settled, so
  that the view is usable rather than nauseating.
- As a **reader whose system removes colour**, I want shape, line style and arrowheads to still tell me
  what I am looking at, so that the picture is not a colour puzzle.
- As a **maintainer/architect working from the keyboard**, I want zoom, pan and fit to be real controls
  in the page, so that navigating the graph is not reserved for a mouse.

## Priority

Should

*In scope and required by §4; ranked Should rather than Must only because §10 states explicitly that
`relationships.md` and the gap ledger ship usefully with no view at all. This is a schedule-risk
ranking, not a statement that the canvas is optional.*

## Acceptance Criteria

Assertions named below live in **`tests/canonical/test-graph-canvas.sh`**, on the sibling convention of
one suite per feature carrying one prefix — feature-006's `GL*` in `test-graph-gap-ledger.sh` (its L4,
:1104–:1105) and feature-007's `GV*` in `test-graph-view-shell.sh` (its :1790). The `GC*` series is this
feature's, is contiguous, and collides with neither.

- [ ] **AC-6** *(canvas half; shared with feature-007, which owns the prerequisite text)*: Given
      `graph.html` opened at its documented entry point with a working WebGL context, when it loads,
      then the live simulation runs — nodes drift toward equilibrium, hovering focuses a neighbourhood
      and dims the rest, and dragging a node pulls its neighbours. *Hooks: **GC01**, **GC02**, **GC03**.*
- [ ] **AC-6a**: Given the bench feature-002 Stage 2b derives, when the frame-time predicate of its D4b
      is applied headless to a steady-simulation window and to a node-drag window, then each clears
      NFR-7's floor. This SPEC supplies the in-page instrumentation the predicate reads and asserts **no
      figure**; the bench, the statistic and the verdict are feature-002's. *Hook: **GC04**.*
- [ ] **AC-7** *(canvas half; shared with feature-007 and feature-009)*: Given the four preset lenses —
      Impact with a focus node set, which feature-007 D6a prompts for when unset (:817) — when each is
      applied in turn, then the drawing visibly changes for each: a different drawn set, emphasis assignment
      or grouping. *Hooks: **GC05**, **GC14** (that an emphasis assignment is drawn at all).*
- [ ] **AC-8** *(canvas half)*: Given a reader who arrived through a preset, when they change grouping,
      density, a filter or the zoom, then the drawing responds to each; the preset has locked nothing.
      *Hook: **GC06**.*
- [ ] **AC-8a** *(canvas half; shared with feature-007 and feature-009)*: Given a single-category
      filter at `grouping: 'none'`, when it is applied, then the drawn edge set is exactly the surviving
      rows of that category, and every colour and line style drawn comes from `CATEGORY_ENCODING` — this
      feature assigns none and so cannot exceed the eight-colour bound. *Hook: **GC07**.*
- [ ] **AC-9** *(canvas clauses; the criterion overall is feature-007's and feature-009's)*: Given a
      reduced-motion preference, when the graph loads, then no frame is painted before the layout has
      converged and the picture arrives settled; **and** the canvas element carries `role="img"` and its
      `aria-label` and no other ARIA or interactive attribute, takes no tab stop, hosts no control, and
      has no DOM-level a11y assertion made against it. *Hooks: **GC08**, **GC09**.*
- [ ] **AC-10** *(canvas half)*: Given the running canvas, when its inputs are examined, then every mark
      it draws corresponds to a `ViewModel` entry and it performs no fetch, no dynamic import and no
      second read of anything. *Hook: **GC10**.*
- [ ] **AC-15** *(canvas half; shared with feature-006 and feature-007, which own the equality)*: Given
      the Coverage lens as its preset applies it, when the drawing is inspected, then every id in
      `coverageGaps` is drawn and is distinguishable by a non-colour channel, and the two gap classes are
      distinguishable from each other — **including with one of them selected**, which is why the badge is
      driven by list membership and not by the emphasis class (§ What is drawn). *Hook: **GC11**. The equality
      is the ledger's and the shell's and binds the **set**, which no lens thins; no gap is lost either way.*
- [ ] **AC-21** *(canvas relationship; shared with feature-007 and feature-009)*: Given every viewport
      action — zoom in, zoom out, reset-to-fit, and pan in each of four directions — when each is driven
      by keyboard input alone through the shell's manifest-built control, then `lensState.zoom` changes
      and the drawing follows; and **no control exists on the canvas**, which is the trap AC-21 was
      written to close. Node dragging is excluded per NFR-6's path-dependent exemption. *Hooks:
      **GC09**, **GC12**.*
- [ ] **NFR-5** *(§9 gives it no numbered criterion; this is the canvas's share, stated so it has a
      hook)*: Given the drawing, when every drawn mark is examined, then each
      node carries its kind's glyph and each edge carries its category's line style and an arrowhead iff
      the relation is asymmetric — with colour additive in every case; and under forced colours the
      palette is dropped entirely while all three non-colour channels remain. *Hooks: **GC13**, **GC14**.*

Spec-authored criteria, numbered `AC-S<n>` under the scheme feature-003 introduced and offered to its
siblings. **The numbering is scoped to this SPEC** — a sibling's is cited with its feature number.

- [ ] **AC-S1**: Given any projection, when the draw record is compared against the `ViewModel`, then
      the drawn node set is exactly `visibleNodes`, the drawn edge set is exactly those `visibleEdges`
      rows whose `edgeFold` entry is not `'collapsed'`, and each drawn edge's two endpoints are the ids
      that entry names. *Hooks: **GC10**, **GC15**.*
- [ ] **AC-S2**: Given the module, when its reads of `lensState` are enumerated, then `zoom` is the only
      field read, and no membership, emphasis, grouping, fold or label decision is computed here.
      *Hook: **GC10**.*
- [ ] **AC-S3**: Given an emphasis-only re-projection **at rest**, when the next frame is drawn, then no
      mark has moved; given a membership change, then every surviving node keeps its position and only new
      nodes are placed; and given a container resize at rest, `viewport` is unchanged and nothing is
      re-placed or re-heated. *Hook: **GC16**.*
- [ ] **AC-S4**: Given the drawing code, when it is searched, then no colour value appears in it: every
      colour drawn is resolved from a CSS custom property or from the forced-colours system-colour probe.
      *Hooks: **GC13**, **GC14**, **GC17**.*
- [ ] **AC-S5**: Given the frame path, when it is instrumented, then it performs no ARIA write, no
      live-region write, no DOM style read and no layout measurement. *Hook: **GC17**.*
- [ ] **AC-S6**: Given two rows between the same drawn pair of nodes, when they are drawn, then they are
      two distinct marks, each individually hoverable and each citing its own table row. *Hook: **GC15**.*
- [ ] **AC-S7**: Given a hover, when the drawn sets are compared before, during and after it, then they
      are identical — hover changes appearance and nothing else, and writes nothing to the store.
      *Hook: **GC02**.*
- [ ] **AC-S8**: Given the generated `graph.html`, when the canvas element is inspected, then this feature
      has added no attribute to it, it takes no tab stop, it hosts no control and it contains no child
      element; and given the mounted page, the only attributes it has added are the `width`/`height` that
      **are** the drawing buffer. *Hooks: **GC09**, **GC12**.*
- [ ] **AC-S9**: Given a drawn node, when it is clicked, then exactly `{'focus.nodeId': id}` is written; when
      it is double-clicked, then `store.openTarget(id)` is called and the gesture writes that same single
      patch and no other — the platform's leading `click` selects and the repeat is ignored (§ Interaction);
      and a wheel or empty-surface drag writes `setLens({zoom})` **once**, at its end. *Hook: **GC18**.*
- [ ] **AC-S10**: Given either library global absent or no WebGL context, when the module mounts, then
      `mode` is `'unavailable'`, the static sentence is ordinary text, one `console.warn` carries the stable
      prefix, and the page keeps exactly two live regions. *Hook: **GC19**.*

---

## Technical Specification

> **Written against a decided architecture and a frozen shell.** FR-18 is settled — `d3-force` for
> physics plus **PixiJS (WebGL)** for drawing, 2D — and Q9 makes the canvas **visual-only**, so this SPEC
> contains no renderer comparison, no accessibility-tree proxy design and no packaging choice. What it
> contains is the draw layer's own contract: what it reads, what it holds privately, what it draws for
> each thing it reads, how it responds to a pointer, and what it must never do inside a frame.
>
> **No figure here is a measurement.** Every number below is a **contract count**, a set **enumerated on
> the spot**, or a **labelled design choice**. Where a quantity would be a measurement — frame rate,
> bench size, settle time, payload, a tuned force constant — this SPEC names the owner and asserts
> nothing (§ Figures).

### The canvas boundary — what this feature does not do

Stated first, because a reader of a drawing layer will otherwise infer scope from what a canvas usually
carries.

| It does not | Because | Owner |
|---|---|---|
| Decide which nodes or edges are present, grouped, folded, thinned, filtered or emphasised | `project()` interprets the lens **exactly once** and states the drawn set itself (feature-007 D3 :605–:607, D4 :626/:629, consumer rules 1 and 7 :1674/:1693). A drawing that re-derived any of it would make membership a per-renderer convention, which is the drift NFR-3 forbids | feature-007 |
| Parse an id, or read `Node.prefix` | Kind comes from the `Kind` column via `Node.kind` and reaches encoding through `nodeEncoding` (§5.2, feature-007 rule 5 :1687). **This feature reads `prefix` nowhere at all** — Q21's test is not merely passed but has no site to apply to, and neither half is left to argument: **GC10** greps for `prefix` and for a prefix literal, and **GC13** compares every mark against the `ViewModel` entry for its own id | — |
| Build a DOM proxy layer, per-mark focus, or any accessibility tree over the bitmap | Q9 makes the canvas visual-only; AA rests on the table view as the conforming alternate version (NFR-2), and AC-9 as scoped asserts no DOM-level check against the canvas | feature-007, feature-009 |
| Host any control, or take a tab stop | AC-21's trap is precisely a control drawn on the canvas. Every control is a real focusable element built from `CONTROL_MANIFEST` (feature-007 D8 :1121–:1146) | feature-007 |
| Detect `prefers-reduced-motion` or `forced-colors` | The shell detects each at load and on its `change` event and publishes the pair on the store, which is what keeps `project()` DOM-free and the store "pure and headless" (feature-007 D3 :609–:615, D5d :801–:802, :1699). This feature **reads** the pair and calls no media query (Open Item 2, **GC10**) | feature-007 |
| Write `canvasAlt`, the announcement, or any ARIA attribute | The shell writes both, once per lens change (feature-007 step 8 :1520–:1524), and the page has **exactly two** live regions (:1526–:1531) | feature-007 |
| Author the legend, the coverage panel, the group disclosure button, or the selected-node detail region | All four are the shell's DOM (feature-007 § UI Specs :1711–:1726) | feature-007 |
| Expose a physics parameter as a control | FR-14a: repulsion, link distance and centre force are internal constants, and there is **no `LensState` field that can reach them** (feature-007 D3 :588–:595) | — |
| Build a degraded mode for a large graph, or warn about one | §4 and Q14 item 7: no adaptive degradation is built; the ceiling is measured by feature-002 D5 (:723) and the warning is emitted by feature-010 (feature-007 Open Item 13 :1985–:1990) | feature-002, feature-010 |
| Resolve an external key to a URL, or compute any open target | `openTarget(nodeId)` is the store's (feature-007 § API Contracts :1663, D7b :1053–:1079); for a `web-page` or external `image` it returns `./external-sources.md` by owner decision (FR-14a) | feature-007 |
| Measure, bench or gate performance | feature-002 owns the predicate, the bench and every figure (its D4b :680, Stage 2b :348) | feature-002 |
| Vendor, licence, attribute or update `d3-force` and PixiJS | feature-002 Stage 3 reports; feature-012 wires | feature-002, feature-012 |

### Data Model

**No persistent schema, no stored artifact, and no model of the graph.** `relationships.md` is the only
durable store and the shell is the only reader of it (FR-3, AC-10). This feature adds four **private**
in-memory structures and one **published** record.

#### D1. What it consumes, and the field each obligation reads

Every row is a field of feature-007's `ViewModel` or `LensState` — plus the one store surface that is
neither, the preference pair — consumed as-is. Nothing here is recomputed, defaulted or widened.

| Read | From | What the canvas does with it |
|---|---|---|
| `visibleNodes` | `ViewModel` (:626) | The node marks to draw — the complete drawn set, zero-row `kb_gaps` nodes included as ordinary records with no `synthetic` branch |
| `visibleEdges` | `ViewModel` (:625) | One candidate mark per surviving row, in `row` order (feature-003 D7's order), so both surfaces paint and list edges in the same sequence |
| `edgeFold` | `ViewModel` (:629) | **The endpoints an edge is drawn between**, or the literal `'collapsed'` — for which nothing is drawn. `Edge.sourceId`/`targetId` are read only to cite the row, never to place a line (rule 7, :1693) |
| `groups[]` with `foldable` and `expanded` | `ViewModel` (:627) | The partition to lay out and caption. Where the canvas indicates a folded group it reads `foldable` and `expanded` **verbatim** and derives neither; the `aria-expanded` attribute belongs to the shell's `data-group-toggle` button (feature-007 :1717, D6c clause 3 :913–:920) |
| `foldedInto` | `ViewModel` (:628) | Read only to caption "*n* folded into this document". It is the fold's record, not an instruction — `project()` has already applied it |
| `nodeEmphasis` / `edgeEmphasis` | `ViewModel` (:630, :631) | Mapped to one ordinal channel — opacity, or under forced colours the channel each mark actually has: **mark scale** on a node, **stroke weight** on an edge (§ Forced colours) — plus the ring and the label (§ What is drawn). **Classification, not styling** — and its domain is `visibleNodes` / the non-collapsed rows, so the canvas never has a class for a mark it may not draw, and never invents one. **One class per node, `'focus'` first**, by D4's total precedence over `nodeEmphasis`'s whole value space (:630); the edge axis needs none, two edge classes not co-occurring in any projection (:631). The **gap badge is not on this axis**, for that reason exactly (§ What is drawn) |
| `nodeEncoding` / `edgeEncoding` | `ViewModel` (:634, :635) | The **colour token name**, the glyph, the line style, and `arrowhead: boolean`. Token names, resolved from CSS at draw time (D2 below) |
| `Node.glyph` | `Node` (:375–:379) | The same glyph, copied onto the node so the draw loop needs no second lookup. The colour is deliberately **not** on `Node` |
| `nodeShortLabels` | `ViewModel` (:633) | The **persistent** on-canvas label |
| `nodeLabels` | `ViewModel` (:632) | The **hover and selection** reveal — never abbreviated (feature-007 AC-S8 :276), and the carrier of the zero-row marker `"— no recorded relationships"` (:1433–:1441), which is how that fact reaches a canvas reader without the canvas inventing a badge |
| `Edge.s2t` / `t2s`, `category`, `provenance`, `row`, `observation` | `Edge` (:410–:430) | The hover reveal's text, and the row citation |
| `coverageGaps`, `coverageOrigin` | `ViewModel` (:636, :637) | **The gap badge's only source.** Which of the two lists holds an id decides which badge its mark carries — never `nodeEmphasis`, whose `'focus'` outranks a gap class, so a class-derived badge would vanish from the one node a reader had just selected (:630, AC-15, **GC11**). Additively, `coverageOrigin` is which side each came from |
| `counts` | `ViewModel` (:643) | The drawn/hidden pair the on-canvas caption echoes, so the canvas cannot disagree with the header or the table caption |
| `revision` | `ViewModel` (:642) | The change key: the position table and the draw record are stamped with it |
| `lensState.zoom` | `LensState` (:582) | The viewport transform — **the only `LensState` field this feature reads** (rule 1 :1674, AC-S2) |
| `getPreferences()`, `subscribePreferences(fn)` | the **store**, in neither record (:609–:615) | `reducedMotion` selects § Reduced motion's path and `forcedColours` § Forced colours'. **The shell detects both**, so this feature reads no media query (**GC10**) and the store still projects headless (:1699); the subscription is separate because a flip advances no `revision` and notifies no `subscribe` listener (:613–:615) |

**Two things it deliberately does not receive, and both are correct.** No **relation property** reaches the
drawing as strength, weight or thickness — the `Strength` column was dropped, layout distance is carried by
hop count, and feature-007 D1 states there is "**no strength-driven visual encoding anywhere in this
work**" (:315–:316) — which leaves an **edge's** stroke weight free to carry emphasis where opacity cannot
(§ Forced colours). And there is no hover field in either record: hover is transient and routing it through
the store would re-project on every pointer move, so it is local to this feature and bounded by one rule —
**hover may change appearance, never membership** (feature-007 D3 :596–:601, rule 6 :1691).

#### D2. Private state — four structures, none authoritative

| Structure | Shape | Lifetime | Why it is private |
|---|---|---|---|
| `positions` | `Map<nodeId, {x, y, vx, vy, fx, fy}>` | Survives every re-projection; an entry is dropped when its node leaves `GraphModel` | Nothing else needs a coordinate. Positions are **not** in `LensState`, so a drag is not shared with the table and is not restored across a reload — which is the honest consequence of there being no field for it |
| `palette` | `Map<tokenName, colourValue>` | Invalidated on a theme change and on a forced-colours change; otherwise cached | The only place a colour **value** exists is the stylesheet (feature-007 D5a, AC-S4) |
| `index` | a spatial index over `positions`, described by role rather than by algorithm | Rebuilt when positions change | Picking, because a bitmap has no hit testing. It is **this module's own code over `positions`**, not a third vendored library: § External Integrations consumes exactly two and neither's capability list names picking, so a third would carry a licence and a payload no document owns |
| `text` | `Map<key, bitmap-text handle>` | Evicted with its mark | Label objects are the expensive kind of allocation to repeat; creating them per frame is what the frame budget forbids |

**Theme invalidation is verified, not assumed.** The reused theme toggle sets `data-theme` on
`document.documentElement` (`canonical/aid/templates/knowledge-summary/lightbox.js`:11, :18, :32, with
the shared `aid-dashboard-theme` key at :33), so a `MutationObserver` on that one attribute is the
complete and cheapest invalidation trigger. No `getComputedStyle` call is made inside a frame.

#### D3. The draw record — the published interface a headless driver reads

A bitmap cannot be asserted against from the DOM, and feature-002 D4b requires the harness to instrument
**in the page** rather than infer frame rate from outside (:694–:700). One object satisfies both needs:
`window.__aidGraphCanvas`, present from mount, plain arrays and objects throughout, so a driver reads it in
one `page.evaluate` and compares it field-for-field against the `ViewModel`.

| Field | Content | Updated |
|---|---|---|
| `revision` | the `ViewModel.revision` this record describes | per projection |
| `mode` | `'live' \| 'settled' \| 'unavailable'` — `'settled'` is a **standing** mode and not a load-time one (§ Reduced motion), and on `'unavailable'` nothing is drawn and no gesture is bound, so every drawn set stays empty and no store write originates here | **at mount** — which is where `'unavailable'` is written, there being no projection on that path (**GC19**) — per projection, and on a preference change |
| `forcedColours` | boolean | at mount and on a preference change |
| `nodes` | drawn node ids | per projection |
| `edges` | drawn edge keys | per projection |
| `marks` | per node `{id, kind, glyph, colourToken, emphasis, emphasisDraw, gapBadge, labelDrawn}`; per edge `{key, row, sourceId, targetId, category, colourToken, lineStyle, arrowhead, emphasis, emphasisDraw}` — the endpoints as `edgeFold` resolved them; `row` so an assertion can name the table row a mark came from; `emphasisDraw` the channels the class actually drew, `{opacity, markScale, ring}` per node and `{opacity, weight}` per edge, with `opacity: null` under forced colours and the ordinal channel then carried by `markScale` or `weight` (§ Forced colours); and **`gapBadge` outside `emphasisDraw` deliberately**, because its source is `coverageGaps` and not the class (D1, § What is drawn) — the badge glyph drawn beside the mark, or `null` for a node in neither list | per projection |
| `reveal` | `{kind: 'node' \| 'edge' \| null, target, text, neighbourhood}` — what the bitmap currently shows for a hover or selection: `text` verbatim the target's `nodeLabels` entry or the edge's `s2t`, and `neighbourhood` the ids drawn at hover emphasis — the target with its one-hop neighbours, every other drawn id dimmed. `kind: null` with an empty text and an empty `neighbourhood` when nothing is revealed. **Hover's highlight is recorded here and not in `marks`**: it is transient appearance, not an emphasis class, and a class is `project()`'s alone (feature-007 :645–:647, rule 6 :1691) | when the hover or selection target changes |
| `captions` | the caption strings drawn on the bitmap: the `counts` line with the number of entries in `groups`, and one entry per drawn group carrying its label and, where the fold applies, its "*n* folded into this document" text | per projection |
| `viewport` | the applied `{scale, panX, panY}` | per projection and per committed gesture |
| `positions` | id → `{x, y}` as last drawn | per frame, **and at a notification that changes the drawn node set** — step 5's diff, so its carry-over and its placements are readable before any frame ticks (**GC16**) |
| `frames` | a bounded ring of `{t, tickMs, drawMs, alpha, dragging, applied}` samples, `applied` being the `{scale, panX, panY}` that frame was drawn with — equal to `viewport` except while a gesture is in flight, which is where the locally-applied transform becomes observable (**GC18**); ring length a **labelled design choice**, sized to cover a steady window and a drag window | per frame |

**Only `positions` and `frames` are written per frame**, both preallocated; `positions` also at a drawn-set
notification, every other field on a projection change and `reveal` on a hover — none inside the frame path.
That split is what keeps the record off the frame budget (AC-S5), and it is why the record is always on
rather than behind a debug flag: a probe that ships disabled would mean the tested artifact is not the
delivered one.

### Feature Flow

The whole flow is client-side, inside the shell's load sequence (feature-007 § Feature Flow). This
feature owns steps 3 onward.

1. **Mounted last, and optionally.** The shell mounts the table **first and unconditionally**, then calls this
   module (feature-007 step 6 :1510–:1515). `mountCanvas(container, store)` returns **D8's viewport handle** —
   `{viewportFor(action)}` over the seven action tokens, each returning a `{scale, panX, panY}` (:1148–:1155)
   — or **nothing** where it is not ready; either way the shell, the controls and the table stay fully usable,
   which is NFR-2's "peer view, not a hidden fallback" at load order.
2. **Acquire a context, or say so plainly.** The vendored `d3-force` and PixiJS bundles are **classic
   scripts** loaded before the inline module block, so this module reads two globals and declares no
   `import` (feature-007 :1599–:1603, GV01 :1795). If either global is absent, or no WebGL context can
   be created, the module sets `mode: 'unavailable'`, places a **static** sentence inside its own region
   — the live graph needs a working WebGL context; the table below carries the same data — and writes one
   `console.warn` with the stable prefix `graph.html: canvas unavailable`. That sentence is **not** a
   live region and not the shell's `role="alert"` banner, because it states a capability rather than
   reporting a load-time failure event, and the page has exactly two live regions (:1526–:1531). The
   accessible route to the same fact is the footer prerequisite AC-6 already requires (:1604–:1609).
3. **First projection.** Read `store.getViewModel()`, place nodes, and enter one of two paths:
   **live** (default) or **settled** (reduced motion) — § Reduced motion.
4. **Subscribe.** `subscribe(listener)` with `listener(viewModel, lensState, changedKeys)` (:1665).
   Notification is synchronous and total (rule 3 :1681): the record of *what will be drawn* is updated
   in the notification, and only the painting is deferred to the next frame. So a test that reads the
   draw record after a `setLens` never observes a stale set, even if no frame has run.
5. **Classify the change** and do the least work that is correct. The classification is derived from the
   **projection itself** — the drawn sets against the ones the record already holds — and not from
   `changedKeys`' vocabulary, which feature-007 passes (:1665) but does not enumerate. `changedKeys`
   supplies two single-key fast paths and correctness never depends on it:

   | Condition | Response |
   |---|---|
   | `changedKeys` is exactly `zoom` | Apply the transform. No layout, no re-place, no re-heat |
   | `changedKeys` is exactly `sort` | Nothing. It is the table's private field (:583) |
   | The drawn sets and `groups` are unchanged | Repaint from `positions` unchanged — no tick and no re-heat, so at rest **no mark moves** (AC-S3) |
   | The drawn sets are unchanged and `groups` differs | Re-heat against the new group centres. Every node keeps its current position as its starting point and none is re-placed — the partition moves marks, it does not relaunch them |
   | The drawn sets differ | Diff them; keep every surviving node's position, place the new ones, drop the departed, then re-heat |

6. **Frame.** Tick the simulation, draw edges, then nodes, then labels, then the caption; append one
   frame sample. Nothing else happens in this path.
7. **Interact.** Pointer gestures either stay local (hover, drag, a gesture in progress) or write to the
   store (`setLens`, `openTarget` navigation) — § Interaction. **Patch keys are dotted paths**, not nested
   objects: `setLens` is a **shallow** merge (:1661), so `{focus: {nodeId}}` would drop `focus.depth` and
   break the Impact lens, while `{'focus.nodeId': id}` cannot. That is the key space feature-007's own
   preset patches use (`focus.depth`, `focus.nodeId`, D6a :815–:818) and the one **feature-007's AC-S6**
   presumes (its :268–:269). `zoom` is the exception and is written **whole**, because its three components
   are one field and are always set together.

### Layers & Components

Authored **once in `canonical/`** and rendered to every host profile by the existing generator (**C-2**);
the rendered copies under `profiles/`, `packages/*/_vendor/` and the dogfood `.claude/` tree are build
output and are **never** hand-edited (`.aid/knowledge/module-map.md`:337).

```
canonical/aid/templates/knowledge-graph/
├── graph-canvas.js   # THIS FEATURE — the whole of it
├── graph-css.css     # feature-007's file; this feature contributes the surface rules below
├── graph-model.js    # feature-007 — consumed, never modified
└── (everything else) # feature-007, feature-009
```

**One file, and one contribution to a shared one.** `graph-canvas.js` is this feature's only new
artifact; its placement is fixed by feature-007's tree (:1546). To `graph-css.css` it contributes the
canvas surface rules and nothing else: the element's box, and the forced-colours **probe** — a
visually-hidden element carrying `color: CanvasText; background-color: Canvas` whose computed values the
draw layer resolves exactly as it resolves a palette token. That keeps AC-S4 true by construction, since
the system-colour keywords live in CSS and never in the drawing code, and it is required because
`component-css.css`'s `@media (forced-colors: active)` block styles elements only — verified on disk at
`canonical/aid/templates/knowledge-summary/component-css.css`:684, whose rules reach `.card`,
`.callout`, `.toc`, `details.accord` and `.badge` and no canvas — so nothing in it can reach a pixel.

**Reuse, not reimplementation (FR-12, C-4, AC-17).** This feature adds **no assembler, no validator and
no test-harness of its own**. Its module is inlined by the same `post-script.html` slot the shell
assembles with `canonical/aid/scripts/summarize/assemble.sh`, and the reused gates bind it exactly as
feature-007's § Validator surface states: a `<canvas>` matches none of `validate-visuals.mjs`'s three
selectors (verified — `.diagram-box` and `.infographic` at that script's :303–:304 and any `svg` at
:328), so the live surface is not collected and the reserved T2 exclusion stays a recorded no-op
(feature-007 :1624).

**One transform rule, because `.js` is text-processed.** `_TEXT_EXTENSIONS` includes `.js`
(`.claude/skills/generate-profile/scripts/render.py`:78), so every rendered copy of this module passes
through `substitute_filenames` and `rewrite_install_paths` (`render_lib.py`:108, :145). The latter's
comment protection does **not** help a JavaScript comment: read on disk, it takes `line.lstrip()` and skips
the line only when it `startswith("#")` (`render_lib.py`:213–:215), which `//` and `/* */` do not. So this
module names no `canonical/…` path and carries none of the three filename placeholders, **in code or in
comments** — the same fixed-point rule feature-007 D10 rule 5 states for the shared module (:1236), applied
here so a header comment cannot make the rendered copies differ from the canonical one for a reason that is
not a defect. **GC10** greps it.

### External Integrations

Two vendored libraries, one narrow seam each. The coupling is deliberately thin so the adopted versions
remain feature-002's and feature-012's to change without reopening this SPEC.

| Aspect | Contract |
|---|---|
| What is consumed | A force-simulation library (`d3-force`) and a WebGL 2D renderer (PixiJS), reached as **globals** — classic `<script src>` builds, because a `file://` page cannot import a relative ES module (feature-007 :1599–:1603, its Open Item 7) |
| API surface depended on | Named at the **capability** level, not by symbol, because the adopted version is Stage 3's to fix: many-body repulsion, link and centring forces with a per-tick callback; and a retained scene graph with batched line and simple-shape geometry, bitmap text, and a draw call this feature controls the timing of |
| Direction of coupling | One way. Neither library sees `LensState`, `GraphModel` or the store; neither becomes a model. They receive ids and positions and return geometry, and any internal graph object either builds is a rendering detail discarded on relayout |
| Data hand-off | Ids and positions only |
| Failure mode | Absent global, or no context: `mode: 'unavailable'`, per Feature Flow step 2 (**AC-S10**, **GC19**). The artifact never becomes unusable because the drawing failed |
| Licence, attribution, payload, update mechanism | **Not this feature's.** Reported by feature-002 Stage 3 (its D6, D7), landed by feature-012. Per feature-002 :1063 this feature may not cite that report at ship time: the facts that must survive belong in `technology-stack.md` and `infrastructure.md` |
| Bundle integrity under the profile render | feature-002 D4 measurand 9 asks whether the bundle survives `render.py`'s text transforms; a negative answer is feature-012's packaging problem, not a change here |

### UI Specs

#### The surface

The `<section aria-label="Relationship graph">` and the `<canvas role="img">` inside it are fixed by
feature-007 (:1718), and their `aria-label` is written by the shell from `canvasAlt` (:1520–:1524). **This
feature authors no attribute on either element and writes no ARIA, `role`, `tabindex` or `data-*`
attribute ever** — with the one exception the platform forces: a canvas's drawing buffer *is* its
`width`/`height` content attributes, which its IDL properties reflect, so the sizing rule below writes
those two and no other (AC-S8, GC09). What it owns is inside the bitmap and around its sizing:

- The backing store is the element's CSS box scaled by device pixel ratio, capped so a high-DPR display
  cannot multiply fill cost without bound — **a labelled design choice**, the cap's value being a
  legibility and cost judgment rather than a figure asserted here.
- Resize is observed with a `ResizeObserver`, which **preserves the viewport transform and triggers no
  relayout and no re-heat** — a resize is neither a membership change nor a perturbation (§ The simulation).
  The surface fits its container at both widths the visual gate measures (732 px and 390 px, verified at
  `validate-visuals.mjs`:95) and never overflows it horizontally, which is feature-007's responsive
  contract (:1743–:1751), not a second breakpoint scale.
- An on-canvas caption draws `counts` as text with the number of entries in `groups`, published as
  `captions` (D3). It invents no value: `counts` is the pair the header and the table caption report (:643).

#### What is drawn for each thing read

| Mark | Non-colour channel (NFR-5) | Colour |
|---|---|---|
| Node | The **glyph** its kind names — feature-007 D5c's table (:774–:782) is the authority and is **not restated here**, because a second copy of a mapping is a divergence waiting to happen | `nodeEncoding[id].colourToken`, resolved from CSS |
| Edge | The **line style** its category names (`CATEGORY_ENCODING`, feature-007 D5b :725–:755), plus an **arrowhead iff `edgeEncoding[key].arrowhead`** — which is `!edge.symmetric`, so a symmetric relation is drawn with none and the absence is the signal (Q14 item 5) | `edgeEncoding[key].colourToken` |
| Direction | The arrowhead points from `edgeFold`'s `sourceId` to its `targetId`. Those are the resolved images of the row's own source and target **in that order**, so the reading stays Source→Target through a fold and `s2t` remains the name to reveal | — |
| Emphasis | One **ordinal** channel plus **additive markers**, and `emphasisDraw` records which each class drew (D3). Ordinal with colour: `'dimmed'` reduces opacity to a floor that keeps a mark visible, `'focus'` and the edge class `'chain'` raise it. Ordinal without it: the channel each mark **has**, derived over D5c's glyph table row by row rather than assumed. An **edge**'s is **stroke weight**, free because no relation property uses it (the `Strength` column was dropped, D1) and safe because a dash period is a length along the line rather than a function of its width. A **node**'s is **mark scale**: every kind D5c draws as a *filled* shape (:776–:781) has no stroke for a weight to grade, and the one it draws as a stroke — `web-page`'s ring (:782) — is where raising weight closes the hollow centre into `document`'s filled circle, while one uniform scale leaves every kind in that table its own outline and node size carries nothing else in this work — and the collision radius (§ The simulation) is taken from the largest scale step, so a raised mark cannot overlap a neighbour. feature-007's own summary lists the canvas's emphasis channels as "shape, opacity and label" (:645–:647) **descriptively** — its normative clause is "Neither maps a class to colour alone" — and "shape" already has its referent in `'focus'`'s ring, so mark scale is an **additional** channel rather than a re-reading of that list (§ Forced colours). Additive: `'focus'` adds a ring **outside the glyph's extent** and the node's label. The gap badge is **not** on this axis — the row below owns it | additive |
| Gap | A distinct **badge glyph beside the mark, never inside it** — one per `coverageGaps` list, so the two classes differ from each other and from an unmarked node with no colour (AC-15, NFR-5). Driven by **list membership, never by `nodeEmphasis`**: the fold-resolved `focus.nodeId` is `'focus'` whatever else applies (feature-007 :630), so a class-driven badge would leave a *selected* gap node unmarked, which is the one state AC-15's canvas half must survive (**GC11**). Drawn in **every** projection — forced rather than chosen, since no `ViewModel` field names the active lens and rule 1 forbids reading `lensState.emphasis` (:1674, AC-S2), while `coverageGaps` is a fact about the data, computed once per load and keyed over neither `visibleNodes` nor `LensState` (:1369–:1373, :1451). No channel alters or replaces a kind glyph, which is what stops a marked `document` from being drawn as D5c's `web-page` ring | additive |
| Label | `nodeShortLabels`, drawn only above a legibility floor and **suppressed rather than shrunk** below it. The floor is a design choice taking `validate-visuals.mjs`'s 10 px default (verified at its :13) as its reference, because the reason behind that threshold is the reader and not the script — which does not collect this surface at all | — |
| Parallel rows | Two rows between the same drawn pair stay two entries (feature-007 D6c clause 2 :912), so they are drawn as two separated marks, each hoverable and each citing its own `row` (AC-S6). No edge is aggregated or synthesised here, for the reason feature-007 gives: an aggregate has no counterpart in feature-003's `rel_row_key` (its :1306) and would cost every surface the ability to cite a row | — |

#### Interaction

| Gesture | Effect | Where the state goes |
|---|---|---|
| **Hover** a node | Its neighbourhood at one hop *(a design choice; the Impact lens is where an adjustable depth lives)* is highlighted and the rest dimmed; the hovered node's `nodeLabels` text is revealed. Both are published as `reveal`, with the highlighted ids as its `neighbourhood` — never as an emphasis class, which no hover may write (D3) | **Nowhere.** Local, transient, appearance-only (rule 6 :1691). The drawn sets are identical before, during and after (**AC-S7**, **GC02**) |
| **Hover** an edge | Its relationship name is revealed — `s2t`, which is also `t2s` when the relation is symmetric — with its provenance and its row | Nowhere. This is NFR-5's "name on hover or selection", and the reason no name is painted per tick |
| **Single click** a node | Select: `setLens({'focus.nodeId': id})`, which re-projects, so the table follows and the Impact lens's depth expansion applies. **Navigates nowhere** (FR-14a). One dotted key and no other write — the store's only membership-affecting write from this feature. Only the **first** click of a sequence selects: a `click` whose `MouseEvent.detail` reports it as a repeat rather than the first is ignored, which is the whole of the double-click accommodation and costs no delay (**AC-S9**, **GC18**) | The store |
| **Double click** a node | `store.openTarget(nodeId)` and navigate. The `dblclick` handler writes no patch of its own, and the gesture as a whole writes exactly one: the platform always dispatches the two `click` events first, the leading one selects, and the repeat is the one the rule above ignores (**AC-S9**, **GC18**) | The store's, computed by the shell (feature-007 D7b) |
| **Drag** starting **on a node** | Pins it under the pointer, re-heats the simulation, and its neighbours follow (AC-6). Released, the pin clears. Under `mode: 'settled'` the re-heat is deferred to the release: the pin still follows the pointer while every other mark holds still (§ Reduced motion, **GC08**) | **Nowhere.** There is no `LensState` field for a position, so drag is exempt from NFR-6 and its result is not shared with the table and does not survive a reload |
| **Wheel or pinch**, and a **drag starting on empty surface** | Pans or scales the viewport — the gesture's target is what separates it from a node drag. The transform is applied locally for the gesture's duration and **committed to `setLens({zoom})` at its end**. No simulation tick is involved in either mode: step 5's `zoom` row applies the transform and re-places, re-heats and lays out nothing | The store, once per gesture |
| **Keyboard** | Nothing is bound to the canvas: it takes no tab stop. Zoom, pan and fit arrive as `lensState.zoom` changes from the shell's controls, each value computed by **D8's `viewportFor(action)`** (:1148–:1155) and written by that control's own handler — the extent a fit is computed from living in the private `positions` (D2) | The store, written by the shell |

**Why a gesture commits at its end rather than per frame.** `setLens` merges, re-projects and notifies
**every** subscriber synchronously (feature-007 :1661, rule 3 :1681). A zoom write per pointer move would
therefore push a projection and a table notification into the frame path — the one thing the frame budget
forbids — for a field no other surface reads (`zoom` is graph-private, :582/:605). Every **discrete**
step, from a control or the keyboard, writes immediately, so `lensState.zoom` is authoritative between
gestures and **GC12**'s "changes `lensState.zoom` and then `viewport`" holds.

**The viewport action set, and the handle that carries it.** Zoom in, zoom out, reset-to-fit, and pan by
one step in each of four directions — the seven tokens D8's handle is keyed on (:1148–:1155). feature-007
D8 **already authors** those as `CONTROL_MANIFEST` entries carrying `requirement: NFR-6` (:1131–:1138), which
GV17's bijection and GV24's usable-after-a-preset assertion bind, so the manifest is satisfied and the entry
ids and their DOM stay the shell's. What no document carried was the **value**, and D8 now names the seam:
`viewportFor(action)` returns the `{scale, panX, panY}` this feature computes — the step factor is its own,
and a fit is a function of the drawn extent, which lives in the private `positions` (D2) — while **the shell's
own handler writes it** through `setLens({zoom})`, so each entry's effect on `LensState` is produced by that
entry's handler and stays assertable there (D8 assertion 3, :1129). This feature writes nothing to the store
on that path, and **with no handle the entries stay present, focusable, never `disabled`, and write
nothing** (:1154).

#### The simulation, and what "live" means

- **It animates by default and is never pre-settled.** The first frame is painted before convergence and
  the picture drifts into place. That is FR-2 and AC-6, and it is what makes NFR-4's reduced-motion clause
  mean something.
- **It may quiesce, and idling is not the settled render.** *Author decision, flagged for owner
  confirmation, because FR-2's "continuously-simulating" and AC-6's "toward equilibrium" admit both
  readings (Open Item 5).* AC-6's own words presuppose arrival, so the loop stops requesting frames once
  movement falls below a threshold and **resumes on any perturbation** — a drag, a hover that re-heats, a
  membership change, a grouping change; under `'settled'` each resumption is **unpainted** (§ Reduced motion).
  **A resize is not one**: the forces run in the simulation's own coordinate space, which no container
  measurement enters, so a resize re-sizes the backing store and repaints at the same transform, re-placing
  and re-heating nothing (§ The surface, **GC16**). This is distinguishable from NFR-4's fallback by a test
  rather than by intent: under reduced motion **no frame is painted before convergence**, whereas here the
  drift is painted (**GC01** versus **GC08**).
- **The force constants are one frozen record in this module**, so there is exactly one place they are
  tuned: many-body repulsion, link distance and strength, centring, collision radius, and a **per-group
  attraction** pulling a group's members toward a shared centre — the *layout* half of what D1 states
  `groups` is for, so a grouping change moves marks rather than only relabelling them. **No value is
  asserted here.** Tuning is a legibility judgment for the mandatory human visual gate — the same posture
  feature-007 D5c takes for its per-kind glyphs (:785–:788) — and FR-14a forbids exposing any of them,
  which is structural rather than promised: no `LensState` field can reach them (:588–:595).
- **Placement is deterministic, and positions are seeded rather than scattered.** A node's initial
  position is derived from its id, so one fixture yields one arrangement across runs — which is what lets
  GC08 and GC16 assert positions rather than merely that they changed. A node entering an existing picture
  is placed near the centroid of its already-placed neighbours, or of its group where it has none, so a
  membership change re-arranges the picture locally instead of relaunching it (AC-S3, **GC16**).

#### Reduced motion (NFR-4, AC-9)

The obligation is a *settled* graph, not a faster animation, so it is met in the layout rather than in
CSS.

1. The preference is read **from the store** — `getPreferences().reducedMotion` at mount, and
   `subscribePreferences(fn)` for a mid-session flip, which needs no reload (feature-007 :609–:615, :1660).
   The **shell** detects it and this feature queries no media feature, which keeps the store pure and
   headless (:1699); the route is a *separate* subscription precisely because a flip advances no `revision`
   and notifies no `subscribe` listener (:613–:615), so nothing here may wait for one. **GC10** greps that
   no `matchMedia` call remains.
2. When it is requested the simulation is stepped to convergence **before the first paint** — a fixed
   iteration budget with an early exit on a movement threshold, both **labelled design choices** — and the
   surface is painted once. No transition is applied to a mark's position, and `mode` is `'settled'`.
   **The mode is standing, not load-time**: each of § The simulation's four perturbations — a hover that
   re-heats, a membership change, a grouping change, a drag at its release — resumes the loop **unpainted**
   and paints once, so no tick is painted for motion the reader did not cause. The one exception is motion
   the reader *is* causing: a drag paints its pinned node under the pointer — a mark that does not follow it
   is not draggable — while every other mark holds still, held by its own `fx`/`fy` in `positions` (D2), so
   the ticks stay ticks and step 6 remains the only draw path (**GC08**).
3. When it is not requested, the **same forces, the same deterministic placement and the same convergence
   threshold** are used and the ticks are painted. The two paths differ in what the reader watches, not in
   what decides the arrangement — which is why **GC08** can compare the two over one fixture.
4. The reused `@media (prefers-reduced-motion: reduce)` block
   (`canonical/aid/templates/knowledge-summary/component-css.css`:658) is a **backstop only**, and reading it
   on disk shows why: it zeroes `animation-duration` and `transition-duration` for every element, which
   cannot un-shuffle a simulation drawn into a bitmap by JavaScript. **The pre-settled layout is the actual
   compliance.**

#### Forced colours (feature-007 D5d)

feature-007 records the limit — a bitmap is not remapped by forced-colours mode, so the page around the
graph changes and the graph does not — and assigns detection and exposure to itself over D3's store route,
the drawing to this feature (:790–:802). So `forcedColours` arrives as `getPreferences().forcedColours` with
`subscribePreferences(fn)` for a flip, exactly as reduced motion does, and no media query is read here. The
response uses the channel NFR-5 already required: in forced-colours mode **no palette colour is drawn at
all**. Every mark is painted in the forced foreground on the forced background, read from the CSS probe
(§ Layers), leaving **shape** for kind, **line style** for category, the **arrowhead** for direction and
filtering for the rest. **Emphasis stops using opacity and carries its ordinal channel in a node's mark
scale and an edge's stroke weight** — the channel each mark has, derived over D5c's glyph table at § What is
drawn — so the classes stay ordered on both, the ring, the gap badge and the label stay additive, and
**GC14** reads the recorded channel rather than arguing it, failing where a class drew none. Scale's floor is
the shape-legibility gate feature-007 routes its own glyphs to (:785–:788). Opacity goes for contrast rather
than capability: a bitmap *can* draw the forced foreground at reduced alpha, but the result is a blend that
is neither of the two system colours and can fall under the 3:1 non-text-contrast bar feature-007 D5a holds
the palette to — a degraded but coherent picture, available only because colour was never the sole carrier.

#### Density, gaps and legibility

`density` thins in `project()` — levels `2`–`5` hide nodes with `degree < density`, level `1` thins
nothing (feature-007 D3 :573). **This feature applies no thinning and no exemption**: it draws
`visibleNodes`. The Coverage preset sets `density: 1` (:815), so no gap node is thinned in the lens whose
purpose is to surface them, and every id in `coverageGaps` is drawn and non-colour-marked (**GC11**). The
renderer-side exemption feature-007 once routed here is **withdrawn** — D1a refers the case to D10 (:387–:388)
and D10's density row is the whole rule (:1451) — so above level `1` a gap **mark** thins with every other
node while the gap **set** does not, being computed once per load and keyed over neither `visibleNodes` nor
`LensState` (:1369–:1373). AC-15 binds on the set (Open Item 1).

#### Frame budget

feature-007 records the finding this section respects: the expensive operations are forced
accessibility-tree rebuilds — many ARIA or live-region writes — not the visual draws, which is why it
batches its announcements at the state boundary (:599, :1520–:1524). So, as rules rather than
intentions (**GC17**):

- **No ARIA attribute is written by this feature, ever**, and no live region: `canvasAlt` and the
  announcement are the shell's, once per lens change (:1520–:1524).
- **No DOM style read and no layout measurement inside the frame path.** Colours come from the cache,
  invalidated by the `data-theme` observer; the container size comes from the `ResizeObserver` callback.
- **No allocation per mark per frame.** Label objects and geometry are created on change and reused;
  `positions` and `frames` are written into preallocated structures.
- **Hover-label count is bounded by the hovered node's degree**, which is exactly the worst case
  feature-002 D4 measurand 5 measures (:644) — this SPEC states the shape of the cost and asserts none of
  its size.

### Tests

Fixtures are self-built and depend on no work folder's contents (**A-6**). The suite is
**`tests/canonical/test-graph-canvas.sh`**, discovered by `tests/run-all.sh`'s
`tests/canonical/test-*.sh` glob. Every assertion about what is **drawn** reads **D3's draw record** and
only fields it declares — the DOM, source-grep and instrumentation halves of GC09, GC10, GC13, GC17 and
GC19 aside — which is what makes a bitmap testable headlessly and keeps the suite runnable under
feature-002 D1a's `L1 ✓ L2 ✓ L3 ✗` row, where nothing can be captured but everything can be timed and read.

| ID | Assertion | Criterion |
|---|---|---|
| **GC01** | from a fixture with a working context and no reduced-motion preference, `positions` differs between the first painted frame and a later one, `mode` is `'live'`, `frames[].alpha` decays across the window, and once it has quiesced the newest sample's `t` stops advancing until a perturbation appends another | **AC-6** |
| **GC02** | dispatching a hover over a node leaves `nodes`, `edges` and every `marks` entry **identical** — no hover writes a class (D1) — while `reveal` carries `kind: 'node'`, that node as `target`, a `text` equal to its `nodeLabels` entry, and a `neighbourhood` holding the target and at least one linked neighbour but **not** every drawn id, so the rest are the dimmed ones; hovering an edge gives `reveal.text === s2t`; moving off the mark empties `reveal`; no `setLens` occurs | **AC-6**, rule 6, **AC-S7** |
| **GC03** | with no reduced-motion preference, a synthetic drag moves the dragged node **and** at least one linked neighbour, `frames[].dragging` is set for the window, and `lensState` is unchanged before and after | **AC-6**, NFR-6 exemption |
| **GC04** | `frames` is populated with per-frame `tickMs`/`drawMs` samples over a steady window and a drag window on a drawn node, in the shape feature-002 D4b's predicate consumes. **The suite asserts the instrumentation, not a frame rate**: the floor verdict is feature-002 Stage 2b's and no figure appears in this suite | **AC-6a** |
| **GC05** | applying each of the four presets in turn changes at least one of `nodes`, `edges`, `marks` emphasis or `captions` against the projection before it — Impact exercised **after a focus node is set**, its patch otherwise moving only `focus.depth` (feature-007 D6a :817, with the GV25 note at :828–:829) | **AC-7** |
| **GC06** | after each preset, a subsequent write to grouping, density, a category filter and `zoom` each advances `revision` and changes the record beyond it — a drawn set, `marks` or `captions` for the first three, `viewport` for `zoom` — so the drawing is not locked | **AC-8** |
| **GC07** | at `grouping: 'none'`, a single-category filter leaves `edges` equal to exactly the fixture's non-collapsed rows of that category; and every `colourToken`/`lineStyle` in `marks` is a value of `CATEGORY_ENCODING`, never a literal | **AC-8a** |
| **GC08** | with `prefers-reduced-motion: reduce` emulated, `mode` is `'settled'`, exactly one paint occurs before any input, and `positions` carries an entry per `visibleNodes` id and is **identical** across frames; over the same fixture the settled arrangement equals the live path's converged arrangement to a tolerance the suite states; a later membership change takes `positions` from the notification's carry-over-and-seed write straight to the converged paint with **no value in between** — an unpainted step writes nothing (D3's cadence) — while a synthetic drag moves the pinned node's entry alone until the release moves the rest (§ Reduced motion); and emulating the preference **mid-session** flips `mode` with no reload — the emulation reaching this module only as `getPreferences().reducedMotion` through the shell's detection and `subscribePreferences` (§ Reduced motion), so the seam is driven end to end rather than by a read of this module's own | **AC-9**, NFR-4 |
| **GC09** | in a generated `graph.html`, the canvas element carries `role="img"` and `aria-label` and **no other authored attribute**, is **not** focusable, matches no `data-control` or `data-group-toggle` selector, and contains no element at all; and in the mounted page `getAttributeNames()` returns those two plus `width` and `height` — the drawing buffer — and nothing more | **AC-9**, **AC-21**, **AC-S8** |
| **GC10** | `nodes` equals the id set of `visibleNodes` and `edges` equals the non-`'collapsed'` `visibleEdges` keys, as sets, and `revision` equals `ViewModel.revision`; and `graph-canvas.js` contains no `fetch`, no `XMLHttpRequest`, no dynamic `import(`, no top-level `import`, no `lensState` member access other than `zoom`, no `matchMedia` call — the preferences arrive on the store's own route and detection is the shell's (Open Item 2) — no `canonical/` substring, none of the three filename placeholders, no `prefix` member access and no quoted `'kb:'`, `'int:'` or `'ext:'` prefix literal — the grep is deliberately over the quoted forms, since a bare `ext:` occurs inside `text:` in any object literal; the decisive case is **GC13**'s `ext:` pair, which no id-parse of any shape passes | **AC-10**, **AC-S1**, **AC-S2** |
| **GC11** | under the Coverage preset, every id in `coverageGaps.kbUnbacked` and `coverageGaps.artifactUndocumented` appears in `nodes` and its mark's `gapBadge` equals the badge for **the list that id is in** — compared against `coverageGaps` (feature-007 :636) and never against the record's own `emphasis` — the two lists' badges differ, no badge equals any `KIND_ENCODING` glyph, and the fixture's **required** non-gap pair — a drawn `document` and a drawn `source-artifact` in neither list, without which this clause could go unexercised — carry `gapBadge: null`, so a canvas badging every node, or keying the badge on the id prefix, fails here; **and again with a gap id selected** — `setLens({'focus.nodeId': id})` after the preset, the state the preset's own `focus.nodeId: null` (:815) puts out of reach — where that mark's `emphasis` is `'focus'` by D4's precedence (:630) while its `gapBadge` and every other gap id's are **unchanged** and the two lists are unchanged, which is the state a class-derived badge silently loses; and a zero-row gap node is drawn in both states, with a `reveal.text` ending `— no recorded relationships` when it is hovered | **AC-15** |
| **GC12** | with `mountCanvas`'s handle registered, each of the seven actions driven by keyboard alone through its manifest control changes `lensState.zoom` and then `viewport`, which **equals** it between gestures (D3), so a transform applied wrongly fails and not only one applied late; the four pan directions and the fit action are each exercised, and **fit** is pinned outside the record — after it, every `visibleNodes` id's `positions` entry falls inside the surface under the applied transform, and two fixtures whose drawn extents differ yield **different** fit transforms, so a `viewportFor` returning a constant fails | **AC-21**, **AC-S8**, NFR-6 |
| **GC13** | `marks` carries exactly one **node** entry per id in `visibleNodes` and one **edge** entry per non-`'collapsed'` `visibleEdges` key — the `ViewModel`'s own sets, which this record cannot empty, so an empty `marks` fails rather than satisfying the quantifiers that follow; and every entry's content is compared against the `ViewModel` entry for **its own id or key**, never against a sibling field of itself: a node's `kind` equals that id's `Node.kind` in `visibleNodes`, its `glyph` and `colourToken` equal `nodeEncoding[id]`'s — where the colour token exists and nowhere else (feature-007 :634, :378–:379) — and its `emphasis` equals `nodeEmphasis[id]`; an edge's `row` and `category` equal that key's `Edge.row` and `Edge.category`, its `colourToken`, `lineStyle` and `arrowhead` equal `edgeEncoding[key]`'s — that `arrowhead` being `!edge.symmetric` there (:635), so a symmetric row's mark carries none — and its `emphasis` equals `edgeEmphasis[key]`. The recorded glyph *name* suffices because no emphasis channel alters a glyph's outline (§ What is drawn), so the drawn shape cannot diverge from it. The fixture carries **feature-007 AC-S3**'s construction — two `ext:` nodes with different keys, one `Kind = web-page` and one `image` (its :249–:255, **GV12** :1806) — mirrored over this record rather than over the projection, so a canvas keying its encoding on the id prefix, or permuting glyphs and tokens across ids, fails here where a self-consistent record would otherwise pass every clause; and no hex, `rgb(`, `hsl(` or named-colour literal appears in `graph-canvas.js` | **NFR-5**, **NFR-3**, **AC-S4** |
| **GC14** | over one fixture and two lenses, `emphasis` being single-valued (feature-007 :581) — **A** (`emphasis: 'provenance-chain'` with a focus node set) presents `'dimmed'`, `'normal'` and `'focus'` on nodes and `'chain'` and `'dimmed'` on edges, **B** (`emphasis: 'coverage'`) presents the two gap classes — each projected with `forced-colors: active` emulated and again without it. In all four projections `marks` carries a node entry per class its lens presents, and under A an edge entry at `'chain'` and one at `'dimmed'`, so no clause below is satisfiable by an empty record. **With** the preference: every `marks` entry's `colourToken` is the probe's foreground token, `forcedColours` is true, glyphs and line styles equal the same projection without it, and **every `emphasisDraw` has `opacity: null` while the channel that replaces it is present and ordered** — every node's `markScale` and every edge's `weight` is non-null, and under A strictly increases across `'dimmed'`, `'normal'`, `'focus'` on nodes and from `'dimmed'` to `'chain'` on edges. **Each order is asserted only in a projection presenting both its members**: D6f marks the chain edges and **dims the rest** (feature-007 :1030–:1031), so A draws no `'normal'` edge, while `'coverage'` marks node classes only (D6d :922–:1009) and `'none'` drives no lens-level dimming at all (:581), so every drawn edge under either is `'normal'` alone — no projection presents a `'normal'` edge beside a `'dimmed'` or a `'chain'` one, so that relation is unreachable rather than merely unasserted, and is stated here so it is not dropped as a missing step. Under B each gap class's node carries a non-null `gapBadge` and the two differ — read from `coverageGaps`, whose comparison is **GC11**'s; and `ring` is set on `'focus'` and on nothing else. **Without** it: `forcedColours` is false and `opacity` is non-null throughout, carrying those same two orders under A — so on neither path may a class record no channel value or draw every class alike | **NFR-5**, **AC-S4**, **AC-7**, D5d |
| **GC15** | over a fixture folded by `grouping: 'document'`: a row whose `edgeFold` entry is `'collapsed'` appears in **no** `marks` edge; every drawn edge's endpoints equal that entry's `sourceId`/`targetId` and not the row's own where they differ; two rows between one drawn pair yield two distinct `marks` entries with different `key` and `row`; and `captions` echoes `ViewModel.counts` and the number of `groups` entries (D3), carries one entry per `groups` entry whose `nodeIds` is non-empty with that group's `label`, and gives each folded group's entry an *n* equal to the number of `foldedInto` entries naming that group's head — so an absent, partial or stale caption fails | **AC-S1**, **AC-S6**, **NFR-3**, rule 7 |
| **GC16** | each clause read at a stated point over a `positions` carrying an entry per `visibleNodes` id. At quiescence: an emphasis-only `setLens` leaves `positions` **identical**, and so does a container resize, which also leaves `viewport` identical. At the notification, before any frame ticks (D3's `positions` cadence): a membership change leaves every surviving id's entry identical and adds one entry per new id and nothing else | **AC-S3** |
| **GC17** | over an instrumented window in which frames were drawn: zero ARIA attribute writes, zero live-region writes, zero `getComputedStyle` calls and zero `getBoundingClientRect` calls occur inside the frame path; and toggling `data-theme` on `<html>` re-resolves the palette exactly once | **AC-S5**, **AC-S4** |
| **GC18** | a synthetic single click on a node records exactly one `setLens` whose patch is the single dotted key `'focus.nodeId'` — no nested `focus` object, so `focus.depth` survives it — and the next projection carries `'focus'` emphasis for that node; a synthetic double click calls `store.openTarget` once with the same id and records **exactly one** `setLens` in total — the leading click's, the repeat click writing nothing; a click on empty surface does neither; and a synthetic wheel gesture moves `frames[].applied` across its frames while `viewport` stays unchanged until the one `setLens({zoom})` it records at its end | **AC-S9**, FR-14a |
| **GC19** | with a library global deleted, and again with context creation forced to fail, `mode` is `'unavailable'`, the graph region holds the static sentence with no `aria-live` and no `role="alert"`, exactly one `console.warn` matches `graph.html: canvas unavailable`, the page still has exactly two live regions, and the table is present and populated — the one assertion here that needs no drawing context in any part | **AC-S10**, NFR-2 |

**What is deliberately not tested here.** Frame-rate *figures* and the bench (feature-002); the ledger
equality itself (feature-006, feature-007); the control manifest's completeness (feature-007 GV16/GV17);
the table's rendering of the same `ViewModel` (feature-009); the label legibility floor, whose value is the
visual gate's and is asserted nowhere, so `labelDrawn` is published rather than bounded; and pixel
appearance, which is that gate's judgment and not a machine assertion — the canvas is not collected by
`validate-visuals.mjs` at all (feature-007 :1624).

### Open Items

Each names its owner and its **Q26 class** — a **mechanism** item changes a contract, a field, an
interface or an acceptance criterion's truth and reopens its owner; an **editorial** item is a real
defect that is collected onto STATE.md's § Editorial queue and fixed in the Q24 item-9 batched pass.
An item that cannot be classified confidently is treated as mechanism. **Features 001–007 are frozen
(Q26 § Freeze), so an item against one of them is an explicit owner decision, not an automatic reopen.**
None blocks this feature's implementation. **Items 1, 2 and 3 are answered in place** by feature-007's
2026-07-30 scoped reopen — they keep their numbers, because sibling SPECs cite them.

1. **Answered: the routed density exemption is withdrawn, ratifying what this SPEC already drew.** D1a now
   reads "**No renderer exempts a gap node from thinning**", referring the case to D10 (:387–:388), and that
   row is "the whole rule", against which "D1a's routed renderer-side exemption is withdrawn" (:1451). So a
   gap mark thins above `density: 1` like any other node — which is what § Density draws. **What is never
   thinned is the gap set, not the mark:** `coverageGaps.artifactUndocumented` is the union `R ∪ G` computed
   **once per load** inside `createStore`, keyed over neither `visibleNodes` nor `LensState` (:1369–:1373,
   :1384), so **AC-15 binds on the set** and is *drawn* in full at the Coverage preset's own `density: 1`
   (:815). **Owner: feature-007, decided.** **Q26 class: mechanism** — closed by the owner, not here.
2. **Answered: the two preferences have a carrier, and it is the store.** `createStore` takes
   `(graphModel, initialLens, preferences)`, the pair defaulting to `false`, and publishes `getPreferences()`,
   `setPreferences(patch)` and `subscribePreferences(fn)` (:609–:615, :1656, :1660, :1778–:1779).
   **Detection stays in the shell** (:1501–:1502, :801–:802) — deliberately, since that is what keeps "the
   store is pure and headless" (:1699) true and the DOM read out of `project()`. A flip changes no
   `revision` and notifies no `subscribe` listener (:613–:615, **GV27** :1821), which is why the route is a
   separate subscription rather than a `changedKeys` token: this SPEC derives nothing from that vocabulary
   (§ Feature Flow step 5). The interim self-read is **withdrawn** (§ Reduced motion, § Forced colours) and
   **GC10** greps for its absence. **Owner: feature-007, decided.** **Q26 class: mechanism.**
3. **Answered: `mountCanvas` returns a viewport handle — option (a), in a stronger form.** D8 states it:
   `{viewportFor(action)}` over the seven action tokens, each returning a `{scale, panX, panY}`, or nothing
   where the module is absent or not ready, with **the entry's own handler writing the result through
   `setLens({zoom})`** (:1148–:1155, step 6 :1515). The canvas computes and the shell writes because D8
   assertion 3 asserts each entry's effect on `LensState`, and that effect must come from that entry's handler
   to stay assertable there (:1129, **GV17** :1811). **With no handle the entries stay present, focusable,
   never `disabled`, and write nothing** (:1154, **GV24** :1818). The manifest needed no redesign and got none
   (:1131–:1138). **GC12**'s fit clause is implementable as of this answer. **Owner: feature-007, decided.**
   **Q26 class: mechanism.**
4. **Three feature-002 verdicts are consumed and none is second-guessed.** Stage 1's WebGL-under-headless
   result decides which assertions run in CI and which degrade with a recorded skip (**C-5** as extended):
   every one that needs a drawing context, which is all of them but **GC19**, the generated-`graph.html`
   half of **GC09** — its mounted-page half reads the two sizing attributes and so needs one — and the
   source-level halves of **GC10** and **GC13**. Stage 2b's bench and floor verdict are AC-6a's content;
   Stage 3's bundle shape is what feature-012 wires. Additionally, feature-002 D1a's `L1 ✓ L2 ✓ L3 ✗` row
   names **this feature** as the owner of its option (a) — requesting `preserveDrawingBuffer` and capturing
   at a controlled point in the frame, at a documented per-frame cost (:437). If that row fires and (a) is
   chosen, the draw loop changes. **Owner: feature-002** for the verdicts, **this feature** for (a)'s
   consequence, **feature-011** for its option (b) — treating the live surface as capture-exempt with an
   in-page `readPixels` assertion — if that is chosen instead. **Q26 class: mechanism** if the row fires.
5. **Whether a live graph may quiesce at equilibrium — an author decision wanting owner confirmation.**
   FR-2 says "continuously-simulating" and AC-6 says "drift **toward equilibrium**". § The simulation
   takes the second reading: the loop idles once movement falls below a threshold and resumes on any
   perturbation, which is distinguishable from NFR-4's settled fallback by GC01 versus GC08. The
   alternative — a graph that never stops moving — is the one AC-6's wording does not require and that
   costs the reader legibility and battery. **Owner: the work owner** (confirmation).
   **Q26 class: mechanism** — AC-6a's measurement window is defined over the non-idle state.
6. **Coordination with feature-009, authored concurrently from the same frozen inputs.** Every criterion
   the two share — AC-7, AC-8a, AC-9, AC-21 — and every field they both read is fixed by
   feature-007, which is the shared authority; this SPEC specifies no table internals and proposes no
   joint mechanism. Two obligations are recorded so neither SPEC invents one: `canvasAlt` and the table's
   caption are both written by the shell from the same `counts` (:643, :1520–:1524), so neither surface
   may compose its own; and the canvas touches no DOM outside its own region, so a focus or selection
   behaviour spanning both surfaces travels through `focus.nodeId` in the store and nowhere else.
   **Owners: feature-009** (its half) **with feature-007** (the authority). **Q26 class: mechanism** if a
   joint mechanism turns out to be needed, in which case it is feature-007's to state.

**Discharged here, and recorded so it is not re-routed.** **feature-002 Open Item 5** — this feature's void
renderer-comparison table and its repetition of the withdrawn no-new-colour-token claim — is discharged by
the fresh authoring: neither is corrected, because neither is present. Its third part, the **void size
estimate**, was never in any revision of this SPEC — it is delivery-001's figure *about* this feature — so
it is **inapplicable** rather than struck. **feature-007 Open Item 13** is **accepted** rather than open in its
original half — AC-6a and NFR-4's settled render, implemented at § Reduced motion and AC-6a — while its
2026-07-30 extension carries the answers to items 1, 2 and 3 and records the re-sweep this revision
discharges (:1985–:1990). And one inbound claim has
**expired**, reported rather than adopted (Q26 § Freeze): feature-002 D6 (its :757–:758) says this SPEC
already places a vendored library under `…/knowledge-graph/vendor/<name>/`; it does not, and that location
belongs with the licence and the payload — **feature-002 Stage 3** to recommend it and **feature-012** to
land it.

**Not open, and recorded so it is not reopened.** That the canvas is visual-only with no DOM proxy layer
(Q9); that it hosts no control and takes no tab stop (AC-21, feature-007 D8); that membership, emphasis,
grouping and the fold are read and never derived (rules 1 and 7); that a symmetric relation is drawn with
no arrowhead (Q14 item 5); that relationship names appear on hover or selection and never per tick (Q11
as amended); that the palette reaches the drawing as **token names** resolved from CSS (feature-007 D5a,
AC-S4); and that no degraded rendering mode is built (§4, Q14 item 7).

**Figures.** No measured quantity is asserted anywhere in this SPEC. Every number in a live clause is one of
three things, and each is labelled where it appears.

- A **contract count**, normative in a document that owns it and cited rather than restated: NFR-7's
  **≥30 fps** floor; **FR-13's four preset lenses**, AC-8a part 3's **eight-colour** cap and Q11's **four**
  line styles; feature-003 D1's **ten** columns; WCAG's **3:1** non-text-contrast bar (feature-007 D5a);
  feature-007's density levels **1–5** (:573), its **two** live regions (:1526–:1531) and the **three**
  filename placeholders of its D10 rule 5 (:1236); and — off `validate-visuals.mjs` on disk — the visual
  gate's widths **732 px** and **390 px** (:95) with the **10 px** legibility default (:13).
- A set **enumerated on the spot**, countable in the section that states it: D2's four private
  structures; D3's eleven draw-record fields; § Interaction's seven viewport actions, four of them pan
  directions, the same seven tokens D8's handle is keyed on; NFR-5's three non-colour channels; the three
  feature-002 verdicts of Open Item 4; the three Open Items feature-007's reopen answered (1, 2 and 3); the
  four shell-owned surfaces this feature does not author; and this SPEC's own six Open Items, ten `AC-S<n>`
  criteria and nineteen `GC*` assertions.
- A **labelled design choice**. Exactly one carries a numeral — the **one-hop** hover neighbourhood — and
  the rest are deliberately **unvalued**, named so that the tuning has a single home rather than to assert a
  size: the frame-sample ring length, the device-pixel-ratio cap, the label legibility floor (referencing
  the verified 10 px default above), the reduced-motion iteration budget and movement threshold, the
  emphasis opacity floor with its forced-colours scale and weight steps, the zoom step factor, and every
  force constant. Each is settled at implementation against the mandatory human visual gate.

**Outside the change log this SPEC produces no measurement** — no frame rate, no bench size, no node count,
no settle time, no payload, no duration and no force-constant value; NFR-7's floor is cited above as its
owner's contract count, measured nowhere here. No count stands in for a set an upstream feature owns: the
relation categories are cited as `GraphModel.categories` and `CATEGORY_ENCODING`, the node kinds as
`KIND_ENCODING` and feature-007 D5c's table, the consumer rules by their own numbers, and the gap classes as
`coverageGaps`'s two lists — never as their cardinalities. Q19's second direction was checked too: no
normative count was weakened into a citation. The withdrawn node bench, A-5's withdrawn KB figure, the void
size estimate and the superseded column count are the record of what was struck; where any is named with a
**value**, that value stands in the change log alone, and none is asserted in a live clause — per
Q20 (A-5 figure), the claim to check is the derivation, and every derivation here belongs to **feature-002**.
