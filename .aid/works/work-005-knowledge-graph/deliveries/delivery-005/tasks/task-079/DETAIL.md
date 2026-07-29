# task-079: `graph-canvas.js` mount, change classification and `LayoutCache`

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-061, task-069

**Scope:**
- Create `canonical/aid/templates/knowledge-graph/graph-canvas.js` -- authored canonically only;
  the rendered copies under `profiles/`, `.claude/` and `.cursor/` are build output and are never
  hand-edited (`.aid/knowledge/module-map.md` § Invariants).
- **Mount (feature-008 § Feature Flow step 1).** `mountGraph(container, store)` subscribes to
  feature-007's store and performs a first render from `store.getViewModel()`. The module reports
  its own readiness; if it throws or is absent from the build, the shell and the peer table stay
  fully usable, because feature-007 mounts the table first and unconditionally. This module must
  not change that ordering.
- **Change classification (step 2).** On each notification -- signature
  `listener(viewModel, lensState, changedKeys)` -- compare `changedKeys` and `viewModel.revision`
  against `LayoutCache.settledFor` and take exactly one of three paths: **emphasis-only**
  (emphasis changed, membership identical) repaints from cached positions with no layout and no
  motion; **membership or grouping changed** relayouts and then repaints; **`zoom` changed**
  applies the viewport transform only, with no layout and no repaint of marks. The picture must
  not jump when the reader only changed what is emphasised.
- **`LayoutCache` (feature-008 § Data Model).** `positions: Map<nodeId, {x, y}>`,
  `groupBoxes: Map<groupKey, {x, y, w, h}>`, `settledFor: number`, `bounds`. It is **private** --
  nothing outside this module reads it -- and is discarded and recomputed only when
  `viewModel.revision` changes in a way that alters membership or grouping. This feature adds no
  other state and no data structure of its own.
- **Honour feature-007's API contract.** Render from `ViewModel`, never from `LensState`; read
  `lensState` for **`zoom` only**; never re-derive membership or emphasis, because doing so
  re-implements `project()` and reintroduces exactly the graph-versus-table drift NFR-3 and AC-7
  forbid; treat `ViewModel` as frozen and mutate nothing on it.
- **Provisional by instruction.** feature-008's SPEC and delivery-005's BLUEPRINT both state that
  the canvas must not be sized before delivery-001's rendering recommendation is known. This task
  is currently shaped for a hand-rolled or lightly-vendored layout; if a full library is adopted,
  task-080 largely collapses into this task and task-083 becomes mandatory rather than
  conditional. Re-read delivery-001's decision record (task-005) before starting rather than
  trusting this slice.
- **Out of scope:** the layout algorithm and the reduced-motion path (task-080); mark painting,
  the NFR-5 encoding and the accessibility proxy layer (task-081); pointer and keyboard
  interaction, the viewport controls and the coverage density exemption (task-082); packaging any
  third-party renderer (task-083); the full profile render (task-086).

**Acceptance Criteria:**
- [ ] `mountGraph(container, store)` subscribes once and first-renders from
      `store.getViewModel()`, and reports its own readiness to the caller.
- [ ] An emphasis-only notification triggers no layout: `LayoutCache.settledFor` is unchanged and
      `positions` is reused byte-for-byte across the repaint.
- [ ] A `zoom`-only notification applies the viewport transform and repaints no mark.
- [ ] A membership or grouping change is classified as such and is the only path that discards
      and recomputes the cache.
- [ ] `LayoutCache` is unreachable from outside the module -- no export exposes `positions`,
      `groupBoxes`, `settledFor` or `bounds`.
- [ ] The module reads no `LensState` field other than `zoom`, and derives `nodeEmphasis` /
      `edgeEmphasis` / membership from the `ViewModel` rather than recomputing them -- reviewable
      by grep, and by the absence of any projection logic in the file.
- [ ] Deliberately failing to load this module leaves the shell and the peer table fully usable,
      with no console error blocking either.
- [ ] All existing canonical suites still pass; the named suite covering this module's mount and
      classification behaviour lands in **task-087**.
- [ ] Build passes: `graph.html` still assembles through task-065's section manifest and
      `canonical/aid/scripts/summarize/assemble.sh`; the full generator run and the render-drift
      confirmation land in task-086.
- [ ] `.aid/knowledge/coding-standards.md` JS conventions are honoured, and the file is authored
      under `canonical/` only -- no rendered copy is hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
