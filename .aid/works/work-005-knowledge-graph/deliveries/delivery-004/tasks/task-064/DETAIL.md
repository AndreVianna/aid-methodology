# task-064: `graph-table.js` zero-row region and skip-target relocation

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

**Depends on:** task-061, task-063

**Scope:**
- Extend `canonical/aid/templates/knowledge-graph/graph-table.js` with the zero-row region: a
  second, two-column `<table class="tbl">` inside its own `<section id="graph-zero-row">`, sibling
  to the main table and emitted immediately after it, rendered only when
  `visibleNodes.some(n => n.degree === 0)`.
- Add the region's `<caption>`, the main caption's count report and its `href="#graph-zero-row"`
  link, and the row focus action on each zero-row row.
- Relocate `<span id="graph-table-end" tabindex="-1">` so it is emitted after **both** tables.
- Add only the zero-row region's rules to `canonical/aid/templates/knowledge-graph/graph-css.css`
  if task-058's rules do not already cover it -- reusing `table.tbl` and `.badge-*`, adding no
  colour token.
- **Out of scope:** materialising the nodes (task-061 owns `orphans` and the complete `Node`
  records); the main table's rendering, sort and filter behaviour (task-063), which this task must
  leave unchanged; any new `ViewModel` field.

**Acceptance Criteria:**
- [ ] The region's row set is selected by `degree === 0` over `viewModel.visibleNodes` -- no new
      `ViewModel` field is read or added, and the module has no knowledge of how the node was
      materialised (no `synthetic`/`orphan` property is referenced anywhere).
- [ ] Exactly two columns, `Id` and `Name`: `Id` is the row header (`<th scope="row">`), matching
      the main table's convention, and `Name` renders `viewModel.nodeLabels`, so the
      "— no recorded relationships" marker appears with no second encoding to keep in sync.
- [ ] The region's `<caption>` states the count and the meaning -- "N enumerated artifacts with no
      recorded relationship", citing FR-19/FR-20 and `./relationships.md` -- so the region explains
      itself on entry.
- [ ] The main table's caption reports the same count and links `href="#graph-zero-row"`; the link
      and the `id` are emitted **together**, so L1 always resolves and the pair cannot dangle. When
      the set is empty, neither the region nor the link is emitted, and L1 still resolves.
- [ ] `<span id="graph-table-end" tabindex="-1">` is emitted after **both** tables, so "Skip
      relationship table" skips all tabular content and does not strand the reader in a second
      table -- verified in both the empty and non-empty states.
- [ ] The region is **not** gated on the Coverage lens -- it renders under every lens whenever the
      set is non-empty -- and it is subject to `filters` exactly like any other node.
- [ ] Each zero-row row carries the existing `no KB doc` badge unchanged and the same row focus
      action as the main table, so selecting it moves `focus.nodeId` and the reader learns it has
      no neighbours.
- [ ] The region is a real `<table>` with `<caption>`, `<thead>` and `<th scope>`, so H1 holds by
      the same construction as the main table; it reuses `table.tbl` and `.badge-*` and adds no
      colour token, so C1/C2 are unaffected.
- [ ] Task-063's main-table rendering, ordering, sorting, filtering and ARIA state are unchanged:
      the diff adds the region, the caption link and the moved skip target, and edits nothing else.
- [ ] The file still declares no top-level `import` (GV01).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suite is `tests/canonical/test-graph-view-shell.sh` (task-071 carries GV07's zero-row-region
      clause), with the lens-parity suite in task-072. *(Stated override of the IMPLEMENT default
      "unit tests for all new public methods", per the vehicle note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
