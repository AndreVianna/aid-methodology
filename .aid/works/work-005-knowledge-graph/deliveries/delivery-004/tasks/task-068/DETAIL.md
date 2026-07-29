# task-068: `lens-presets.md` and the graph accessibility-checklist addendum

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

**Type:** DOCUMENT

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-060

**Scope:**
- Author `canonical/aid/templates/knowledge-graph/lens-presets.md`: the reviewer-facing prose form
  of feature-007's preset patch table -- the four presets with their exact patches, the initial
  `LensState`, the purpose each serves, and the statement that a preset is an entry point rather
  than a mode.
- Author `canonical/aid/templates/knowledge-graph/accessibility-checklist.md`: the graph addendum
  to `canonical/aid/templates/knowledge-summary/accessibility-checklist.md`, carrying only the
  delta this artifact adds to the AA checklist.
- **Out of scope:** replacing or restating the summary checklist (this file extends it); any code
  change to `PRESETS` / `INITIAL_LENS` (task-060 owns them and this task documents them); the
  discoverability surfaces in `docs/` and `README.md` (task-090, delivery-006).

**Acceptance Criteria:**
- [ ] `lens-presets.md` states all four presets -- Coverage, Overview, Impact, Provenance -- each
      with its exact field patch, and the initial `LensState` (`preset: null`, `grouping: 'none'`,
      `density: 1`, all filters on, `emphasis: 'none'`, `focus.nodeId: null`).
- [ ] It states explicitly that no preset is the default layout (FR-15) and that arriving through a
      preset locks nothing: every control stays live afterwards (FR-14, AC-8).
- [ ] **Accuracy verified against the current codebase** (DOCUMENT default): every preset name,
      field name and value in the document matches `PRESETS` and `INITIAL_LENS` in
      `graph-model.js` as task-060 wrote them; a reviewer can diff the two by eye and find no
      divergence.
- [ ] The accessibility addendum extends rather than replaces the summary checklist, and names the
      manual items this artifact owns: a `<label for>` on every form control, no skipped heading
      levels, a 44 × 44 px hit area on interactive controls, and usability at 200 % zoom with
      horizontal scrolling confined to `.tbl-wrap`.
- [ ] The addendum records the two artifact-specific structural obligations: exactly two live
      regions (one `aria-live="polite"`, one `role="alert"` present-but-empty at load), and the
      2.4.11 sticky accounting across the top bar and the sticky table header.
- [ ] The addendum states which half of AC-9 this delivery closes and which does not -- the
      reduced-motion clause is feature-008's in delivery-005 -- so a reviewer reading only this
      file does not conclude AC-9 is closed.
- [ ] Both files sit in `canonical/aid/templates/knowledge-graph/` and are rendered by the full
      generator; the render-drift confirmation is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
