# Accessible Table View

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §6.1 (NFR-1–NFR-3), §4, §9 (AC-7, AC-9) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Coverage-lens paragraph reattributed: the predicate is now a shared module feature-007 specifies and feature-006's generator runs, not feature-007's own. Consequence of feature-007's shared-predicate fix; the `viewModel.coverageGaps` contract is unchanged | Owner review |
| 2026-07-28 | Added the zero-row region. The main table is one row per edge, so an enumerated `int:` node with no relationship row had no representation here at all — an NFR-2 peer-rendering break at the FR-19/FR-20 case that matters most. Selected by `degree === 0` over `visibleNodes`, so no new `ViewModel` field; skip-target and caption-link adjusted with it | Owner review |

## Source

- REQUIREMENTS.md §6.1 (NFR-1 WCAG AA, NFR-2 the accessible table as a peer rendering, NFR-3
  every preset lens applies to both renderings) and its Rationale paragraph
- REQUIREMENTS.md §4 In Scope ("an accessible table view as a peer rendering of the graph")
- REQUIREMENTS.md §5 FR-3 (the table is the single input, so the peer rendering adds no second
  data path); §6.1 NFR-5 as it applies to table encoding
- REQUIREMENTS.md §9 (AC-9; AC-7 table side)

**Dependency position.** Blocked by feature-007 (the shell and the lens view-model it consumes).
**Not blocked by feature-002** — the table rendering needs no rendering-approach decision at all.
This is the reason the table view is a separate feature from the canvas: it can proceed while the
rendering research runs, and it gives the accessibility bar a named owner rather than leaving it a
footnote on a canvas feature.

**Consumes feature-007's lens view-model as a contract.** Interpreting a lens differently from the
graph rendering violates NFR-3 and AC-7.

**Shared acceptance criteria.** AC-9 is owned here overall, with feature-008 owning its
reduced-motion clause; AC-7's table side is owned here while feature-007 owns the criterion. Both
are mutual obligations and neither owner may consider them met alone.

## Description

The same relationships, presented as a real table on the page — sortable, filterable, navigable
from the keyboard, and usable with a screen reader.

This is not a fallback hidden behind the graph for readers who cannot use it. It is a peer view,
first-class alongside the drawing, and for a good deal of the work this artifact exists to support
it is simply the better tool: when the question is "which rows are unbacked", a filterable list
beats a picture. Every preset lens applies here exactly as it applies to the graph — asking for
Coverage in the table lists precisely the gap rows the graph highlights, not an approximation of
them.

Shipping two genuine renderings of the same data is how the accessibility bar gets met without
fighting the medium. A drawing canvas cannot carry a screen-reader experience convincingly; a
table can, and it can be checked mechanically as well. So the table takes on that burden, and the
overall artifact reaches the same accessibility standard the existing Knowledge Base summary
already holds. Because the table shows the same single source of data the graph does, this adds no
second data path — just a second way of looking.

Meaning in the table, as in the graph, is never carried by colour alone.

## User Stories

- As a **maintainer/architect** using a screen reader, I want the relationships available as a
  real, navigable table rather than only as a drawing, so that the artifact is usable to me at all.
- As a **KB reviewer**, I want to filter and sort the rows directly, so that I can work through the
  gap rows systematically instead of hunting for them in a picture.
- As a **maintainer/architect**, I want every preset lens to work in the table exactly as it does
  in the graph, so that switching rendering never changes what I am looking at.
- As a **maintainer/architect** working from the keyboard, I want to reach and operate the whole
  table without a mouse, so that navigation is not gated on pointing.

## Priority

Should

*In scope and required by §4 and §6.1; ranked Should rather than Must only because §10 states
explicitly that `relationships.md` and the gap ledger ship usefully with no view at all. This is a
schedule-risk ranking, not a statement that accessibility is optional — within the view, the
accessibility bar is mandatory.*

## Acceptance Criteria

- [ ] AC-9 *(owned here; the reduced-motion clause is owned by feature-008 — mutual obligation;
      neither feature may consider this met alone)*: Given the generated view, when it is checked
      against the existing structural and accessibility checks, then it passes at WCAG AA, the
      table view is keyboard-navigable and screen-reader usable, and reduced motion yields a
      settled graph.
- [ ] AC-7 *(table side; shared with feature-007, which owns the criterion — mutual obligation)*:
      Given the generated view, when each of the four preset lenses is applied, then each visibly
      changes the table rendering as well as the graph.
- [ ] Given the Coverage lens applied to the table, when the resulting rows are compared with the
      gap ledger, then the table lists exactly the gap rows the graph highlights.
- [ ] Given the table view, when a reader sorts and filters it, then both work across the
      relationship columns — the table is genuinely interactive, not a static dump.
- [ ] Given the table view, when its role in the artifact is examined, then it is presented as a
      peer rendering rather than a hidden fallback.
- [ ] Given the table view, when its content is examined, then it renders the same
      `relationships.md` data the graph renders, adding no second data path.
- [ ] Given the table view, when node type and provenance are examined, then neither relies on
      colour alone to be understood.

---

## Technical Specification

> **Renderer-independent by construction.** This feature is not blocked by feature-002 and nothing
> below changes with its answer (FR-18, Q2). That is the whole reason the table is a separate
> feature: it can be built and graded while the rendering research runs, and it gives the WCAG AA
> bar a named owner instead of leaving it a footnote on a drawing feature.
>
> **Design pressure on record (research gathered 2026-07-28).** The prior art on accessible
> interactive data visualisation names "SVG plus an accessible data table" as the approach that
> works at any size and for complex relationships, with the standing risk being **keeping the table
> and the chart in sync**. Its recommended remedy is exactly the architecture feature-007
> implements: one accessibility model beside the visual model, decoupled from drawing, read by both
> the renderer and the accessibility layer, acting as the single source of truth for the data-table
> fallback, the live-region text, and the per-mark labels — which is what stops the three surfaces
> drifting apart. The research also notes that only SVG and the DOM produce accessibility-tree
> semantics for free, which is why the table (plain DOM) is the surface that carries the
> screen-reader experience rather than the canvas. The relevant WCAG A/AA criteria for this artifact
> class are 1.1.1, 1.3.1, 2.1.1, 2.4.7, 2.4.11, 1.4.3, 1.4.11, and 4.1.3.

### Data Model

**No persistent schema and no data model of its own.** The table renders feature-007's `ViewModel`
and holds one piece of private, non-authoritative state:

| Structure | Fields | Lifetime | Authority |
|-----------|--------|----------|-----------|
| `RowOrder` | `order: Edge[]`, `orderedFor: {revision, column, direction}` | Rebuilt when `viewModel.revision` changes, or when `lensState.sort` changes | **Private.** Nothing outside this module reads it |

`RowOrder.order` is a reordering of `viewModel.visibleEdges` and never a re-selection of it. The
table may not add, drop, or re-derive a row — membership belongs to `project()`. That single
restriction is what makes "the table lists exactly the gap rows the graph highlights" true rather
than approximately true, and it is this feature's half of NFR-3 and AC-7.

Per feature-007's API contract this module reads `lensState` for **`sort` only**. Sorting is
table-private and cannot affect membership or emphasis; every other control the table exposes writes
through `store.setLens(...)`, so it changes the graph in the same tick.

**Eight columns, matching the file (§5.2).** The rendered table has exactly the columns
`relationships.md` has — Source Id, Source Name, Target Id, Target Name, S2T Relation, T2S Relation,
Provenance, Observation. There is no `Strength` column (Q1, resolved 2026-07-28) and **no ninth
column is added**: emphasis is carried by a badge inside the Source Id / Target Id cells and a
`data-emphasis` attribute on the `<tr>`, so the table stays a faithful rendering of the source file
rather than a re-shaped derivative of it. This is the structural form of AC-10 on the table side:
what a reader sees in a cell is what they can find in the file, at the row `edge.row` names.

### Feature Flow

1. **Mount.** `mountTable(container, store)` subscribes and renders from `store.getViewModel()`.
   Per feature-007's flow the table mounts **first and unconditionally**, so a build where the graph
   module is missing or throws still yields a complete, usable artifact. Load order is the
   structural argument for NFR-2 — this is a peer rendering, not a fallback hidden behind the graph.
2. **Order.** Compute `RowOrder` from `visibleEdges` and `lensState.sort`. The default order is
   `edge.row` ascending — source-file order — so an unsorted table reads the same as the file.
3. **Render.** Emit one `<tr>` per ordered edge with eight cells — a `<th scope="row">` for Source
   Id and seven `<td>` for the rest — plus the emphasis badge and `data-emphasis`. Every row is
   rendered; there is no virtualisation and no pagination, because a
   partially-present table breaks screen-reader row counts, breaks the browser's own find-in-page,
   and breaks printing — and **A-5** bounds the row count to a scale where rendering all of it is
   fine.
4. **Sort.** A column header button toggles `lensState.sort` through the store. The re-projection is
   a no-op for membership; only `RowOrder` changes. Rows are re-emitted in place with no transition
   (see § Reduced motion).
5. **Filter.** The table's filter controls write into `lensState.filters` — the **shared** filter
   fields. Filtering the table therefore filters the graph, which is what NFR-3 asks for; a
   table-private filter would be the drift AC-7 exists to prevent.
6. **Select.** A row's focus action writes `focus.nodeId` through the store, so choosing a row in
   the table moves the graph's Impact neighbourhood to the same node.
7. **Announce.** After each change the module updates the `<caption>` and the `aria-sort` state, and
   hands the summary text to feature-007's single `aria-live="polite"` region. It does **not** create
   a second live region — two regions on one page produce doubled or lost announcements.

### Layers & Components

Authored canonically and rendered to every profile by the existing generator (**C-2**); rendered
copies are build output and are never hand-edited (`module-map.md` § Invariants).

```
canonical/aid/templates/knowledge-graph/
├── graph-table.js        # THIS FEATURE: ordering, rendering, sort/filter wiring, ARIA state
├── graph-model.js        # feature-007 — consumed, never modified
└── graph-css.css         # shared; this feature adds only table-specific rules
canonical/aid/scripts/graph/
└── (none owned by this feature)
```

**Reuse, not reimplementation (FR-12, C-4, AC-17).** This feature adds no assembler, no validator,
and **no table CSS from scratch**:

| Reused | How |
|--------|-----|
| `canonical/aid/templates/knowledge-summary/component-css.css` | Already carries `.tbl-wrap` (the horizontally scrollable bordered container) and `table.tbl` with its `th`/`td` rules, sticky-styled header cells, row hover, and `.badge-*` classes for `ok`/`warn`/`err`/`info`/`purple`. The table view uses these directly; `graph-css.css` adds only sort-affordance and emphasis-row rules |
| the same file's `@media print` rules | Give the table a usable printed form with no extra work |
| the same file's `@media (forced-colors: active)` block | Preserves card and callout borders under Windows High Contrast |
| `canonical/aid/scripts/summarize/validate-html-output.sh` | H1, A1–A5, L1, L2 against the assembled page |
| `canonical/aid/scripts/summarize/contrast-check.mjs` | C1/C2 across both themes |
| `canonical/aid/templates/knowledge-summary/design-tokens.md` | The single palette source; this feature declares no new colour token, so C1/C2 keep passing on the pairs the script already checks |
| `canonical/aid/templates/knowledge-summary/accessibility-checklist.md` | The AA checklist this artifact is measured against; the graph addendum extends it rather than replacing it |

#### Which checks this feature is answerable for (AC-9)

NFR-1 sets the bar at WCAG AA, matching the bar `kb.html` already holds, and AC-9 makes it checkable
by pointing at "the existing structural and accessibility checks". Read against the scripts as they
actually are, the table view is the surface that satisfies most of them:

| Check | How the table satisfies it |
|-------|---------------------------|
| **H1** (HTML validity — `tidy`, else `npx html-validate`, else a regex fallback) | A real `<table>` with `<caption>`, `<thead>`, `<tbody>`, and `<th scope>` is valid by construction; a div-grid imitation is where validity failures come from |
| **A1** (semantic landmarks) | The table lives inside feature-007's `<section>` within `<main>`; A1's own sub-checks (`lang`, `header role="banner"`, `main`, `nav`, `footer`, `title`) are the shell's |
| **A4** (`@media (prefers-reduced-motion: reduce)` present) | Reused from `component-css.css`; and this feature animates nothing (below) |
| **A5** (`:focus-visible` rule present) | Reused from `component-css.css`; every control here is a native focusable element |
| **C1 / C2** (WCAG contrast, both themes) | Tokens only; the badge pairs `--ok`/`--ok-bg`, `--warn`/`--warn-bg`, `--err`/`--err-bg`, `--info`/`--info-bg`, `--purple`/`--purple-bg` are already in the script's pair list |
| **L1** (every `href="#X"` resolves to an `id="X"`) | The skip-past-table link's target id is emitted with the table, so the pair is created together and cannot dangle |
| **L2** (`href="./x.md"` resolves against the HTML file's own directory) | The caption's source citation points at `./relationships.md`, which sits beside `graph.html` in `.aid/knowledge/` (FR-9) |
| **S2 / NM** | Not this feature's surface — the table introduces no script src, no link href, and no drawing engine. Both are packaging and renderer concerns (feature-007, feature-008, feature-011) |
| **S7 / T1–T4** (`validate-visuals.mjs`) | The collector walks `.diagram-box`, `.infographic`, and `<svg>`. The table uses none of those, so it is **not collected** — and must not be given one of those classes to "get it checked", since T2's overlap rule is meaningless for tabular layout |

The manual items in `accessibility-checklist.md` this feature owns: every form control has an
associated `<label for>`; heading hierarchy has no skipped levels; interactive controls have a
44 × 44 px hit area; the layout stays usable at 200% zoom, with horizontal scrolling confined to the
`.tbl-wrap` container where a wide table legitimately scrolls.

### UI Specs

#### Component breakdown

| Component | Markup | Contract |
|-----------|--------|----------|
| Section heading | `<h2>` inside feature-007's table `<section>` | Present in the page TOC at the same level as the graph's — the visible form of "peer rendering" |
| Skip-past-table link | `<a href="#graph-table-end">Skip relationship table</a>` before the table | Its target, `<span id="graph-table-end" tabindex="-1">`, is emitted after the main table **and** the zero-row region, so the link skips all tabular content and L1 always resolves |
| Caption | `<caption>` | States the row count, the hidden-row count, the active lens (`viewModel.lensSummary`), and cites `./relationships.md` as the source. Screen readers read it on table entry, so the reader learns the scope before the data |
| Header row | `<thead>` with `<th scope="col">` per column, each wrapping a `<button>` | The button is the sort affordance; `aria-sort` is `ascending`, `descending`, or `none` on exactly the sorted `<th>` |
| Filter row | A second `<tr>` in `<thead>` with a labelled `<input>` per filterable column | Each input has a visually hidden `<label for>`; values write to `lensState.filters` |
| Body rows | `<tbody>` with one `<tr data-emphasis="…">` per ordered edge | Eight cells: `<th scope="row">` for Source Id, `<td>` for the other seven |
| Emphasis badge | A `.badge-*` span inside the Source Id / Target Id cell | Carries its meaning as **text** — `no source`, `no KB doc` — never as colour alone |
| Row focus action | A `<button aria-label="Show neighbourhood of {name}">` in the Source Name cell | Writes `focus.nodeId`; the graph follows |
| Empty state | A single-cell row explaining which control emptied the table and how to widen it | A blank table body is indistinguishable from a broken one |
| Zero-row region | A second, two-column `<table class="tbl">` in its own `<section>` immediately after the main table, present only when the set is non-empty | See below |

#### Zero-row nodes: why they need their own region

The main table is one row per **edge** (`visibleEdges`), so an enumerated `int:` node with no
relationship row produces no row in it — and that node is precisely the FR-19/FR-20 defect
feature-007 materialises from `kb_gaps` (feature-007 § "Zero-row nodes"). Leaving it out would
break NFR-2's peer-rendering guarantee at exactly the point it matters most: the graph would show
an artifact the table silently omitted.

Forcing it into the main table was considered and rejected. A row with a real Source Id and six
em-dashes claims a relationship the file does not contain, breaks the caption's row count as a
count of relationships, and gives a screen-reader user six "blank" cell announcements before the
one fact that matters. Instead:

- **Its own `<section>`**, sibling to the main table, rendered only when
  `visibleNodes.some(n => n.degree === 0)`. The set is selected by `degree === 0` over
  `visibleNodes` — no new `ViewModel` field, and no knowledge of how the node was materialised.
- **Two columns**, `Id` and `Name`, because those are the only two facts such a node has. `Id` is
  the row header (`<th scope="row">`), matching the main table's convention.
- **Its own `<caption>`**: *"N enumerated artifacts with no recorded relationship — the sharpest
  form of Knowledge Base gap (FR-19, FR-20). Source: ./relationships.md."* The caption states the
  count and the meaning, so the region explains itself on entry rather than reading as a stray
  table.
- **The existing `no KB doc` badge**, unchanged — these nodes are `int-undocumented` like any other
  gap. The additional "no recorded relationships" fact needs no new badge: feature-007 appends it to
  `viewModel.nodeLabels`, which the `Name` column renders, so the graph and this region name the
  node identically with no second encoding to keep in sync (NFR-3).
- **The same row focus action** as the main table, so selecting one moves the graph's Impact
  neighbourhood to it and the reader learns it has no neighbours.
- **Reuses `table.tbl` and `.badge-*`** from `component-css.css`; adds no colour token, so C1/C2 are
  unaffected. It is a real `<table>` with `<caption>`, `<thead>` and `<th scope>`, so H1 holds by the
  same construction as the main table.
- **The main table's caption reports the count too** and links to the region via
  `href="#graph-zero-row"`; the region carries `id="graph-zero-row"` and the two are emitted
  together, so the pair cannot dangle and **L1** always resolves. A reader who never scrolls past
  the main table still learns the nodes exist.
- **The skip-past-table target moves.** `<span id="graph-table-end" tabindex="-1">` is emitted after
  **both** tables rather than after the main one, so "Skip relationship table" still skips all
  tabular content and does not strand the reader in a second table.

The region is **not gated on the Coverage lens** — these nodes are a fact about the data, not a lens
result, and hiding them behind one lens would reintroduce the omission this fixes. It is still
subject to `filters`, exactly like every other node, because a reader who filters out `int:` nodes
meant it.

#### State management

No component-local copy of anything in `LensState`. Header `aria-sort` and every filter input's
displayed value are reconciled from `lensState` on each notification, so the table's controls and
feature-007's control panel can never show different filter values. Nothing is persisted between
loads; the theme stays on the existing shared `aid-dashboard-theme` key so the graph, the KB summary
and the dashboard agree.

#### The four lenses in the table (AC-7 table side, NFR-3)

Each lens changes the table visibly, and does so because the table reads the same projection the
graph does — not because a second interpretation was written to match.

| Lens | Visible change in the table |
|------|----------------------------|
| **Coverage** | Rows are grouped by emphasis with `int-undocumented` and `kb-unbacked` rows first, each carrying its text badge; the caption reports the gap counts. This is the "which rows are unbacked" question a filterable list answers better than a picture |
| **Overview** | Rows collapse to the document-level and category-level groups `viewModel.groups` defines, with a per-group row count; density thinning removes low-degree rows and the caption reports how many are hidden |
| **Impact** | The table lists only rows within `focus.depth` hops of `focus.nodeId`, with a hop-distance indicator on each row; the caption names the focused node and the depth |
| **Provenance** | The table shows only `kb:` → `int:`/`ext:` rows, ordered by provenance, with the `Provenance` column's own value carrying the distinction |

The Coverage row set is `viewModel.coverageGaps` — produced by the single shared coverage predicate
feature-007 specifies, the same module feature-006's ledger generator runs. This feature adds no
second gap computation, which is how its side of AC-15 holds. Note the scoping feature-007 fixes:
the ledger carries rows for the `int-undocumented` class only (FR-20, FR-26), while the Coverage
lens surfaces both classes because FR-13 says it highlights unbacked `kb:` nodes as well; the table
labels the two classes distinctly so a reviewer can see which rows have a ledger counterpart and
which do not.

#### Keyboard reach (2.1.1) and focus (2.4.7, 2.4.11)

- **Cells are not tab stops.** Screen readers navigate table cells with their own table-navigation
  commands, and the prior art warns explicitly against making every datum a tab stop. Adding a
  cell-level tab order would produce thousands of stops and defeat both audiences.
- The tab stops are: the skip-past-table link, each header sort button, each filter input, and each
  row's focus action — reached in visual order, with the skip link providing the escape for a reader
  who does not want to traverse the rows.
- The reused `:focus-visible` rule (asserted by A5) supplies the ring. Two sticky layers can obscure
  a focused element here, and 2.4.11 requires accounting for both: the shell's top bar (roughly
  60 px per `design-tokens.md` § "Spacing & sizing") and the reused `.tbl th` rule, which is itself
  `position: sticky; top: 0`. So the sticky header is given a top offset equal to the top-bar height
  rather than pinning to the viewport edge, and focusable elements inside `<tbody>` carry a
  `scroll-margin-top` covering **both** layers — otherwise a focused row action scrolls neatly under
  the column headers.
- `Enter` and `Space` operate every button; nothing here is pointer-only.

#### Screen-reader behaviour (1.3.1, 4.1.3)

Real table semantics do most of the work: `<caption>` for scope, `<th scope="col">` for column
association, `<th scope="row">` on the Source Id cell for row association, and `aria-sort` on the
sorted column so the current order is announced rather than merely drawn. After a sort or a filter
the module hands a one-sentence summary to feature-007's single polite live region — "8 of 214 rows,
Coverage lens, sorted by Source Id ascending" — written once per change, never per row. Row-level
detail is not announced; it is already reachable by table navigation, and announcing it would flood
the region.

#### Reduced motion (AC-9)

This feature animates **nothing**. Sorting re-emits rows with no transition, filtering does not
cross-fade, and no row height is animated — so there is no motion for the reduced-motion preference
to suppress. The reused `@media (prefers-reduced-motion: reduce)` block still covers the shell's
hover transitions, which is what A4 asserts. The settled-graph half of AC-9 is feature-008's
(NFR-4); this half is satisfied by having no motion to settle.

#### Colour is never the sole carrier (NFR-5)

| Meaning | Non-colour carrier | Colour (additive) |
|---------|-------------------|-------------------|
| Node kind | The `kb:` / `int:` / `ext:` prefix is already part of every id (§5.3), so it is present in the cell text | `--accent` / `--info` / `--purple` |
| Provenance | `Provenance` is a literal column with a text value — `declared`, `derived`, `inferred` | `--ok` / `--info` / `--purple` badge tints |
| `kb-unbacked` | A `no source` badge, text | `--warn` on `--warn-bg` |
| `int-undocumented` | A `no KB doc` badge, text | `--err` on `--err-bg` |
| Sort state | `aria-sort` plus a caret glyph in the header button | none |
| Dimmed / thinned | Rows are **removed and counted in the caption**, never merely faded | none |

Because `Provenance` and the id prefixes are literal text in the cells, colour-only encoding is
impossible here by construction rather than by discipline — which is part of why the table is the
right surface to carry the accessibility bar.

#### Responsive behaviour

`.tbl-wrap` supplies the horizontal scroll a wide eight-column table legitimately needs, so the
page itself never scrolls sideways. Below the 768 px mobile breakpoint from
`design-tokens.md` § "Spacing & sizing", the filter row collapses into a `<details>` disclosure
above the table and the Observation column is moved into an expandable cell so the seven identifying
columns stay readable. The table is checked at the two widths the visual gate measures — 732 px and
390 px — for containment within `.tbl-wrap` rather than overflow of the page (T4's
container-relative predicate).

#### The JavaScript-off case

FR-17 makes runtime script mandatory for this view, so the honest fallback is not a degraded table —
it is the source file. The `<noscript>` region (asserted by the structural check in
`validate-html-output.sh`) links `./relationships.md` and `./INDEX.md`, and `relationships.md` *is*
this table in Markdown, readable with no script at all. That is a property of FR-3 and AC-10: the
single input is itself a human-readable rendering, which is also why §10 can say the table and the
ledger ship usefully with no view at all.
