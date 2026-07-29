# task-063: `graph-table.js` peer table rendering, sort, filter and ARIA state

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-058, task-060

**Scope:**
- Create `canonical/aid/templates/knowledge-graph/graph-table.js`: `mountTable(container, store)`
  and the main peer table -- the private `RowOrder` structure, the eight-column rendering, sort,
  filter, the row focus action, the caption, and the ARIA state.
- Implement `RowOrder` = `{order: Edge[], orderedFor: {revision, column, direction}}`, rebuilt when
  `viewModel.revision` or `lensState.sort` changes; default order `edge.row` ascending.
- Render the components feature-009 § UI Specs fixes: section heading, skip-past-table link,
  `<caption>`, `<thead>` header row of `<th scope="col">` each wrapping a sort `<button>`, the
  filter row, `<tbody>` rows of `<tr data-emphasis>` with `<th scope="row">` for Source Id and
  seven `<td>`, the text emphasis badge, the row focus action button, and the empty state.
- Mount **first and unconditionally**, so a build where the canvas module is absent or throws still
  yields a complete, usable artifact (NFR-2).
- **Out of scope:** the zero-row region, its caption link and the relocation of
  `#graph-table-end` (task-064); creating any live region or writing announcements outside
  feature-007's single polite region; any new colour token or table CSS beyond task-058's file;
  any `import` statement.

**Acceptance Criteria:**
- [ ] `RowOrder.order` is a **reordering of `viewModel.visibleEdges` only** -- the module never
      adds, drops or re-derives a row. Over a fixture, the rendered row set equals `visibleEdges`
      exactly, for every lens.
- [ ] Exactly eight columns are rendered, matching §5.2 and `relationships.md`, with **no ninth
      column**: emphasis is carried by a `.badge-*` span inside the Source Id / Target Id cell and
      by `data-emphasis` on the `<tr>`.
- [ ] Row semantics: `<th scope="row">` on the Source Id cell, `<th scope="col">` on every header,
      each wrapping a `<button>`; `aria-sort` is `ascending` or `descending` on **exactly** the
      sorted `<th>` and `none` elsewhere.
- [ ] The `<caption>` states the row count, the hidden-row count, `viewModel.lensSummary`, and
      cites `./relationships.md` as a relative link that resolves against the file's own directory
      (L2).
- [ ] Sorting writes `lensState.sort` through the store and changes only `RowOrder`; the
      re-projection is a no-op for membership. The filter inputs write the **shared**
      `lensState.filters`, so filtering the table filters the graph in the same tick. The row focus
      action writes `focus.nodeId`.
- [ ] The module reads `lensState` for **`sort` only** (feature-009 § Data Model) and creates no
      second live region -- summary text is handed to feature-007's single polite region.
- [ ] Every row is rendered: no virtualisation, no pagination, so screen-reader row counts,
      find-in-page and printing all work.
- [ ] The module animates nothing -- no transition on sort, no cross-fade on filter, no animated
      row height (its half of AC-9's reduced-motion clause).
- [ ] Meaning is never carried by colour alone: the badges read `no source` / `no KB doc` as text,
      `Provenance` and the id prefixes are literal cell text, and thinned rows are **removed and
      counted in the caption**, never faded (NFR-5).
- [ ] The table mounts first and unconditionally: with the canvas module absent or throwing, the
      table still renders completely and every control still works.
- [ ] Cells are not tab stops -- the tab stops are the skip-past-table link, each header sort
      button, each filter input and each row focus action, in visual order.
- [ ] The file declares no top-level `import` (GV01), and reuses `.tbl-wrap`, `table.tbl` and
      `.badge-*` from `component-css.css` rather than restyling them (C-4, AC-17).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suites are the lens-parity suite (task-072) and the WCAG verification (task-073). *(Stated
      override of the IMPLEMENT default "unit tests for all new public methods", per the vehicle
      note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
