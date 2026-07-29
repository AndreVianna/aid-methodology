# task-082: Pointer and keyboard interaction, viewport controls and the coverage density exemption

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

**Depends on:** task-081

**Scope:**
- Implement interaction in `canonical/aid/templates/knowledge-graph/graph-canvas.js`
  (feature-008 § Feature Flow step 5 and § "Keyboard equivalence (NFR-6)").
- **The seven-row key map**, with the surface as a **single** tab stop rather than one stop per
  node: `Tab` / `Shift+Tab` move into and out of the graph surface; arrow keys pan, and with
  `Shift` move graph focus to the nearest mark in that direction; `+` / `-` zoom in and out by one
  step; `0` resets zoom and pan to fit; `Enter` / `Space` selects the focused node by writing
  `focus.nodeId` through the store, so the table follows; `[` / `]` decrease and increase
  `focus.depth` for the Impact lens; `Escape` clears graph focus **without** clearing the lens.
- Pointer interaction to the same contract, including hit testing against
  `LayoutCache.positions` where the chosen renderer provides none natively.
- **Viewport controls:** real `<button>` elements with `aria-label`s for zoom in, zoom out, reset
  and fit. The keyboard routes above are **in addition** to them, not instead of them.
- **The write split is the mechanism, not a convention.** Zoom and pan write only the
  renderer-private `zoom` field (`{scale, panX, panY}`) and never re-project, so keyboard
  navigation cannot desynchronise the two renderings. Selection and depth go through
  `store.setLens`, so they always do. Nothing else in the page is touched directly.
- **The coverage density exemption -- this feature's half of AC-15.** `density` thins by
  `node.degree`, but the shared coverage predicate does not read that counter: it is
  edge-shape-aware, not degree-based. Thinning and gap detection are therefore independent, and
  the guarantee that thinning never hides a gap has to be **explicit** rather than incidental. It
  is: when the active emphasis is `coverage`, nodes in `viewModel.coverageGaps` (both
  `kbUnbacked` and `intUndocumented`) are **exempt from density thinning**. A lens whose whole
  purpose is to surface gaps must not let an unrelated slider hide them.
- Keep the surface fitting its container at the 732 px and 390 px viewports the visual gate
  measures, with no horizontal overflow (T4) and no collapse (T3); the mobile breakpoint is
  768 px.
- **Provisional by instruction.** feature-008's SPEC and delivery-005's BLUEPRINT both state that
  the canvas must not be sized before delivery-001's rendering recommendation is known -- hit
  testing in particular is browser-native under SVG and manual under Canvas or WebGL. Re-read
  delivery-001's decision record (task-005) before starting rather than trusting this slice.
- **Out of scope:** the control panel, the preset buttons, the grouping/density/filter/text/focus
  controls and the two live regions (feature-007, task-062); the peer table's row focus action
  (feature-009, task-063); mark painting and the accessibility proxies (task-081); the parity,
  keyboard and AC-15 verification (tasks 087, 088, 089).

**Acceptance Criteria:**
- [ ] Each of the seven key-map rows performs its action from the keyboard alone, and no
      navigation action is reserved for a mouse (NFR-6).
- [ ] The graph surface is exactly **one** tab stop; `Tab` does not enumerate marks.
- [ ] Zoom and pan write **only** `lensState.zoom`: neither path calls `setLens` with any other
      field, and `viewModel.revision` is unchanged across a zoom or a pan, proving no
      re-projection occurred.
- [ ] `Enter` / `Space` writes `focus.nodeId` and `[` / `]` writes `focus.depth`, both through
      `store.setLens`, and the peer table's rendering changes in the same notification.
- [ ] `Escape` clears graph focus and leaves `emphasis`, `preset` and the filters untouched.
- [ ] With `emphasis === 'coverage'`, every id in `viewModel.coverageGaps.kbUnbacked` and
      `viewModel.coverageGaps.intUndocumented` is drawn at **every** density level 1 through 5;
      raising density to 5 hides no gap.
- [ ] The exemption is implemented against `coverageGaps` membership, not against any degree-based
      heuristic -- no `node.degree` test guards it, reviewable by reading the thinning branch.
- [ ] The viewport controls are real `<button>` elements each carrying an `aria-label`.
- [ ] The surface has a non-trivial bounding rect and no horizontal overflow of its own container
      at the 732 px and 390 px viewports (T3, T4).
- [ ] All existing canonical suites still pass; the named suites land in **task-087** (FR-2
      density and zoom response and legibility, and AC-7 graph-half parity), **task-088** (NFR-6
      keyboard zoom and pan) and **task-089** (the AC-15 equality this exemption underwrites).
- [ ] Build passes: `graph.html` still assembles through task-065's section manifest and
      `canonical/aid/scripts/summarize/assemble.sh`; the full generator run and the render-drift
      confirmation land in task-086.
- [ ] `.aid/knowledge/coding-standards.md` JS conventions are honoured, and the file is authored
      under `canonical/` only -- no rendered copy is hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
