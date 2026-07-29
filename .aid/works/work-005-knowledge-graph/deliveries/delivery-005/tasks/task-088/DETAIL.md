# task-088: AC-9 closure and the NFR-5 / NFR-6 presentational obligations

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

**Type:** TEST

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-073, task-086

**Scope:**
- **This task closes AC-9 overall, and it has two owners.** feature-009 owns AC-9 overall and its
  table half was verified in delivery-004 **task-073** -- `validate-html-output.sh` H1 and A1-A5,
  L1 and L2, `contrast-check.mjs` in both themes, keyboard reach, and screen-reader semantics.
  feature-008 owns the reduced-motion clause and it is verified here. **Neither owner may consider
  the criterion met alone**, so this task verifies **both** contributions together and records
  AC-9 as closed only when both hold. Re-confirming task-073's evidence against the current
  `.aid/knowledge/graph.html` -- which now carries the canvas -- is part of this scope, not an
  assumption carried forward from delivery-004.
- **Reduced motion (NFR-4, AC-9's clause owned here).** With `prefers-reduced-motion: reduce`
  requested, the graph loads already settled: layout animation is disabled, the first painted
  frame is the converged one, no intermediate tick is painted, and no transition is applied to
  mark position. Verify additionally that the settled positions are **identical** to the animated
  path's converged positions for the same input -- the equality that makes the accessible
  experience and the visual experience the same graph. `validate-html-output.sh` A4 (the
  `@media (prefers-reduced-motion: reduce)` block) is the CSS backstop and must also pass, but the
  pre-settled layout is the compliance.
- **NFR-5 -- colour is never the sole carrier.** Node type and provenance are each conveyed by
  shape and/or label in addition to colour: with colour removed (forced-colors emulation) both
  still read, and the `kb:` / `int:` / `ext:` id prefix in the label alone carries kind.
- **NFR-6 -- keyboard-equivalent zoom and pan.** Zoom in, zoom out, reset-to-fit and pan in all
  four directions each complete from the keyboard alone, with no navigation action reserved for a
  mouse.
- **The accessibility layer built in task-081.** Confirm `role="application"` with its
  `aria-roledescription`, the `aria-describedby` surface description with its counts, active lens
  and navigation guidance, and that the description is written on **membership change only** --
  the frame-budget rule that keeps forced accessibility-tree rebuilds off the repaint path.
- **Out of scope:** AC-7 parity, FR-6 regrouping and FR-2 legibility (task-087); the AC-15
  Coverage-lens equality (task-089); and any fix to `graph-canvas.js` or the peer table, which
  belong to their owning tasks.

**Acceptance Criteria:**
- [ ] Tests are deterministic: the same rendered artifact yields the same result on every run.
- [ ] Clean setup and teardown: any working directory is created under `mktemp -d` and removed,
      and the run leaves `.aid/knowledge/graph.html` unmodified.
- [ ] Under `prefers-reduced-motion: reduce` the graph renders already settled -- no intermediate
      layout tick is painted and no transition is applied to mark position.
- [ ] The settled positions under reduced motion are **identical**, node by node, to the animated
      path's converged positions for the same input.
- [ ] `validate-html-output.sh` A4 passes against the rendered `graph.html`.
- [ ] Node kind and provenance each read with colour removed (forced-colors emulation), through
      shape, stroke pattern, fill or label text, and the id prefix alone carries kind.
- [ ] Zoom in, zoom out, reset-to-fit and pan in all four directions each complete from the
      keyboard alone.
- [ ] The graph surface carries `role="application"` with an `aria-roledescription`, and its
      `aria-describedby` target states the node and edge counts, the active lens, and how to
      navigate.
- [ ] The surface description is rewritten on membership change only: an emphasis-only change, a
      zoom, and a repaint each produce zero ARIA writes.
- [ ] **Both AC-9 halves are verified in this run.** Task-073's table-half evidence -- H1, A1-A5,
      L1, L2, `contrast-check.mjs` in both themes, keyboard reach and screen-reader semantics --
      is re-confirmed against the current `graph.html`, and the reduced-motion clause above holds.
      AC-9 is recorded as closed **only** if both do; a pass on either half alone is recorded as
      not-closed.
- [ ] All acceptance criteria from feature-008's AC-9 reduced-motion clause and from
      feature-009's overall AC-9 ownership are covered.
- [ ] When Playwright is absent the run follows the documented `SKIP` to exit 0 with its
      remediation message rather than failing, and the summary records that feature-010's `G1`
      human visual gate is then the sole carrier of visual assurance.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
