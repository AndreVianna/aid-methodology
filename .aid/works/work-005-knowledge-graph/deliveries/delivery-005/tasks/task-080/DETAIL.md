# task-080: Layout, group frames and settled-before-first-paint reduced-motion path

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

**Depends on:** task-078, task-079

**Scope:**
- Implement the layout stage of `canonical/aid/templates/knowledge-graph/graph-canvas.js`
  (feature-008 § Feature Flow step 3): position `viewModel.visibleNodes` and `visibleEdges` so
  structure is visible rather than tangled, and compute one group box per `viewModel.groups` entry
  into `LayoutCache.groupBoxes`. Grouping is a partition feature-007 already computed -- this task
  **positions** the partition, it does not decide it (FR-6). Layout distance is conveyed by hop
  count; the `Strength` column was dropped at Q1, so no edge weight, thickness or spring constant
  is derived from row data.
- **The reduced-motion path is the obligation, and it is stronger than "disable animation."**
  Per feature-008 § "Reduced motion (NFR-4, AC-9 reduced-motion clause)": read the preference once
  with `window.matchMedia('(prefers-reduced-motion: reduce)')` and subscribe to its `change`
  event; when reduced motion is requested, run the layout **to convergence before the first
  paint** -- a fixed iteration budget with an early exit on a movement threshold -- and paint
  once. No tick is ever painted mid-simulation and no transition is applied to mark position. The
  graph arrives already resolved.
- **The two paths must converge to the same positions.** When reduced motion is not requested the
  same settled result may be reached through animated ticks, and the converged positions are
  **identical** on both paths: the two differ only in what the reader watches. That equality is
  what makes the accessible experience and the visual experience the same graph, so it is written
  here as a testable property rather than an intention.
- Write `LayoutCache.settledFor = viewModel.revision` and `LayoutCache.bounds` at convergence, so
  task-079's emphasis-only path can reuse the layout instead of relaunching it.
- **The CSS block is the backstop, not the compliance.** Confirm that every transition and
  animation this feature adds is additionally covered by the reused
  `@media (prefers-reduced-motion: reduce)` block in
  `canonical/aid/templates/knowledge-summary/component-css.css`, which is what
  `validate-html-output.sh`'s A4 asserts. A CSS rule cannot un-shuffle a simulation that paints
  while it runs; the pre-settled layout is the actual compliance.
- A disconnected (zero-row) node has no attractive force acting on it, so its position comes from
  the layout's centring behaviour alone. That is an accepted placement and is owned here through
  `LayoutCache`.
- **Provisional by instruction.** feature-008's SPEC and delivery-005's BLUEPRINT both state that
  the canvas must not be sized before delivery-001's rendering recommendation is known. This task
  is currently shaped for a hand-rolled or lightly-vendored layout; **if a full library is
  adopted, most of this task collapses into task-079** and task-083 becomes mandatory rather than
  conditional. Re-read delivery-001's decision record (task-005) before starting rather than
  trusting this slice. The settled-before-first-paint obligation survives either way -- all three
  candidate engines can be stepped headlessly to convergence before the first paint.
- **Out of scope:** mount and change classification (task-079); mark painting, the NFR-5 encoding
  and the accessibility proxies (task-081); interaction and the viewport transform (task-082); and
  the AC-9 closure verification (task-088).

**Acceptance Criteria:**
- [ ] Under `prefers-reduced-motion: reduce`, the layout reaches a settled result **before the
      first paint**: the first painted frame is the converged one and no intermediate tick is
      painted.
- [ ] Node positions are **identical** between the animated path and the settled path for the same
      `ViewModel` -- assertable by running both paths over the same input and comparing
      `LayoutCache.positions` entry by entry.
- [ ] Convergence is bounded: a fixed iteration budget and an early-exit movement threshold are
      both named constants in the code, so the pre-paint layout cannot run unbounded.
- [ ] A runtime change of the media-query state is observed through the subscribed `change` event
      and takes effect on the next layout.
- [ ] Exactly one group box exists per `viewModel.groups` entry -- including the
      `no relationships` group -- with no group invented and none dropped.
- [ ] `LayoutCache.settledFor` equals `viewModel.revision` after a layout, so task-079's
      emphasis-only path reuses positions.
- [ ] No transition is applied to mark position on either path, and
      `component-css.css`'s `@media (prefers-reduced-motion: reduce)` block covers every
      transition and animation this task adds, with `validate-html-output.sh` A4 still passing.
- [ ] All existing canonical suites still pass; the named suite covering the reduced-motion
      obligation lands in **task-088**.
- [ ] Build passes: `graph.html` still assembles through task-065's section manifest and
      `canonical/aid/scripts/summarize/assemble.sh`; the full generator run and the render-drift
      confirmation land in task-086.
- [ ] `.aid/knowledge/coding-standards.md` JS conventions are honoured, and the file is authored
      under `canonical/` only -- no rendered copy is hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
