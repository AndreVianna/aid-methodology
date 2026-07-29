# task-056: Graph view page layout, region order and interaction wireframe

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DESIGN

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** --

**Scope:**
- Produce one wireframe and interaction document at
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-004/design/graph-view-wireframe.md`,
  so that `graph-css.css` (task-058), `graph-controls.js` (task-062) and `graph-table.js`
  (tasks 063/064) are authored against a single mental picture of the page rather than three.
  The document is transient pipeline state: no permanent artifact may depend on it.
- Render -- do not invent -- the already-fixed component breakdowns of feature-007 § UI Specs and
  feature-009 § UI Specs into one page picture. Every element in the wireframe cites the SPEC row
  it renders.
- Cover exactly: region siblinghood and DOM-versus-visual order of the graph and table
  `<section>`s; the two live regions and nothing more; the control panel drawn at 1200 px, 768 px,
  732 px and 390 px; the legend `.diagram-box`; the whole-page focus order; and the placement of
  the zero-row region, its caption link and the relocated skip target.
- **Out of scope:** the drawing surface's internal visual encoding (feature-008 / task-078,
  delivery-005); any markup, CSS or JavaScript (tasks 057, 058, 062, 063, 064); any new colour
  token, control, region or state not already fixed by the two SPECs; the dashboard route
  (excluded from this delivery entirely).

**Acceptance Criteria:**
- [ ] The graph `<section aria-label="Relationship graph">` and the table
      `<section aria-label="Relationship table">` are drawn as **siblings**, neither nested in the
      other, with DOM order table-first, visual order graph-then-table at and above 768 px, and
      table-then-graph below it -- and neither region hidden in either arrangement.
- [ ] Exactly **two** live regions appear anywhere in the wireframe and both are labelled: the
      `role="alert"` integrity banner as first child of `<main>`, present-but-empty at load and
      written at most once; and one `aria-live="polite"` status line carrying
      `viewModel.announcement`. No third live region appears on any of the four widths.
- [ ] The control panel (grouping `<select>`, density `<input type="range" min="1" max="5">`, three
      filter fieldsets, text `<input type="search">`, focus-node combobox, depth stepper) is drawn
      at **1200 px** (max content width), **768 px** (collapsed into a `<details>` disclosure,
      single-column grid), **732 px** and **390 px**, and at no width does a region overflow its own
      container horizontally (T4).
- [ ] The legend is drawn as a `.diagram-box` that states every `glyph` and every provenance marker
      **in words**, and reports the zero-row node count when the set is non-empty -- through the
      ordinary reporting channel, never through the integrity alarm.
- [ ] Focus order is written as one ordered list from the first focusable element to the last: skip
      link, banner controls, the four preset buttons in `<nav aria-label="Preset lenses">`, the
      control panel in panel order, the skip-past-table link, each header sort button, each filter
      input, each row focus action. Table cells are **not** tab stops.
- [ ] The wireframe states the 2.4.11 obligation concretely: the two sticky layers (top bar
      ~60 px per `design-tokens.md` § "Spacing & sizing", plus the reused `.tbl th`
      `position: sticky; top: 0`) and the `scroll-margin-top` that must cover both.
- [ ] The zero-row region is placed as a sibling `<section id="graph-zero-row">` immediately after
      the main table, with `<span id="graph-table-end" tabindex="-1">` after **both** tables, and
      the main caption's `href="#graph-zero-row"` link shown as emitted together with the region.
- [ ] **Design system tokens used** (DESIGN default): every colour, spacing and radius call-out
      names a `var(--token)` from `canonical/aid/templates/knowledge-summary/design-tokens.md`, and
      the wireframe introduces **no new colour token** -- the five semantic roles map onto
      `--accent`, `--ok`, `--warn`, `--err`, `--purple`, with `--text-dim` for dimmed marks.
- [ ] **Responsive behaviour shown** (DESIGN default): the four widths above, with the 768 px
      breakpoint and 1200 px max content width as the only breakpoint scale -- no second scale.
- [ ] Every component, control, region and state in the wireframe traces to a row of feature-007
      § UI Specs "Component breakdown" or feature-009 § UI Specs "Component breakdown"; a reviewer
      can check the two lists against each other and find nothing added and nothing dropped.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending`
      or `Recurred`.
