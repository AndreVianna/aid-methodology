# task-062: `graph-controls.js` control wiring and the two live regions

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

**Depends on:** task-057, task-060

**Scope:**
- Create `canonical/aid/templates/knowledge-graph/graph-controls.js`: the wiring for every control
  in task-056's control panel and lens bar, against the shell task-057 authored.
- Wire the four preset buttons (`applyPreset`, `aria-pressed` reflecting `lensState.preset`) and
  the manual controls: grouping `<select>`, density `<input type="range" min="1" max="5">`, the
  three filter fieldsets (`nodeKinds`, `categories`, `provenance`), the text `<input
  type="search">`, the focus-node combobox and the depth stepper -- each writing through
  `store.setLens(...)` on `change`/`input` and nowhere else.
- Implement reconciliation: on every store notification, each control's displayed value is
  re-derived from `lensState`, so no control holds a local copy of any `LensState` field.
- Implement the announcement write: `viewModel.announcement` into the single existing
  `aria-live="polite"` region, once per lens change.
- **Out of scope:** creating either live region (task-057 authors both, empty); any write into the
  `role="alert"` region, which is task-061's integrity channel alone; the table's own header and
  filter controls (task-063); persisting anything except the existing shared
  `aid-dashboard-theme` key; any `import` statement.

**Acceptance Criteria:**
- [ ] Every control is a native element with a real `<label for>`, and **none is ever `disabled`**:
      after applying each of the four presets in turn, grouping, density, every filter, the text
      search, focus and depth remain enabled and their writes still take effect (AC-8, FR-14).
- [ ] No control holds a component-local copy of a `LensState` field -- every displayed value is
      reconciled from `lensState` on each notification, so a preset button and the density slider
      cannot show different densities.
- [ ] `aria-pressed` on each preset button reflects `lensState.preset` and is advisory only: it
      gates no control and disables nothing.
- [ ] Every control write goes through `store.setLens(...)`; a grep finds no direct mutation of
      `lensState` and no second projection of the data in this file.
- [ ] `viewModel.announcement` is written into the single `aria-live="polite"` region **once per
      lens change**, never per frame or per control event; the module creates no live region of its
      own and never writes into the `role="alert"` container.
- [ ] Reading `lensState` in this module is limited to reconciliation and to the graph-private
      `zoom` field; membership and emphasis are never re-derived here (feature-007 § API Contracts
      rule 1).
- [ ] The file declares no top-level `import` and reaches the store's exports through the shared
      module scope (GV01).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suites are the control-liveness half of task-072 and the WCAG verification in task-073.
      *(Stated override of the IMPLEMENT default "unit tests for all new public methods", per the
      vehicle note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
