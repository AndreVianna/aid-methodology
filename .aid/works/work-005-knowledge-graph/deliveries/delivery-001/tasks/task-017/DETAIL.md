# task-017: Build the interactive graph canvas -- draw layer and interaction

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-017/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** feature-008-interactive-graph-canvas -> delivery-001 (Wave 3)

**Depends on:** task-011, task-013

**Scope:**
- **Greenfield — nothing exists.** There is no `*canvas*` file anywhere in `canonical/`, and
  `graph-skeleton.html`'s `{{INLINE_GRAPH_JS}}` placeholder has no source. This task writes the
  whole draw layer and fills that placeholder.
- **Draw layer:** `d3-force` physics plus PixiJS/WebGL drawing, 2D, per the settled FR-18. D2's four
  private structures, none authoritative; D3's published draw record — the interface a headless
  driver reads. The drawn node set is exactly `visibleNodes` and the drawn edge set is exactly those
  `visibleEdges` rows whose `edgeFold` entry is not `'collapsed'`, drawn between the endpoints that
  entry names (AC-S1). Glyph per node kind, line style per category, arrowhead iff the relation is
  asymmetric, colour additive in every case (NFR-5). The gap badge is driven by `coverageGaps` list
  membership, **never** by `nodeEmphasis` — `'focus'` outranks a gap class, so a class-derived badge
  would vanish from the one node a reader had just selected (AC-15 canvas half).
- **SIZE RISK, stated with its escape.** This is the largest task in the set: greenfield d3-force
  plus PixiJS, the whole interaction surface, three degraded modes, and criteria spanning `AC-S1`
  through `AC-S10`, with **nothing pre-existing to build on** (`find canonical -iname '*canvas*'`
  returns nothing). The merge into one task is an owner decision and stands. But if the executing
  session cannot carry it to a reviewable state, **split at the seam this Scope already names** --
  mount/layout/draw-record as one task, interaction/degraded-modes as the next -- and record the split
  and its reason rather than delivering a half-done single task. Splitting is a recorded deviation;
  silently overrunning is not.
- **Interaction and the degraded modes** (merged into this task by owner decision): hover focus/dim;
  click writing exactly `{'focus.nodeId': id}`; double-click calling `store.openTarget(id)` with that
  same single patch and no other; wheel or empty-surface drag writing `setLens({zoom})` **once**, at
  its end; node drag pulling neighbours; the settled-before-first-paint reduced-motion render
  (NFR-4); forced colours dropping the palette entirely while all three non-colour channels remain,
  with emphasis carried by mark scale on a node and stroke weight on an edge; and `mode:
  'unavailable'` when either library global is absent or no WebGL context exists — static sentence as
  ordinary text, one `console.warn` with the stable prefix, page still carrying exactly two live
  regions (AC-S10).
- **Depends on task-011** (BLUEPRINT edge 2 — feature-002 sizes this feature outright and states its
  runtime prerequisites) **and task-013** (BLUEPRINT edge 5 — it mounts into the shell and consumes
  its view model).

**Acceptance Criteria:**
- [ ] AC-S1: drawn node set is exactly `visibleNodes`; drawn edge set is exactly the non-collapsed
      `visibleEdges` rows, each between the endpoints `edgeFold` names
- [ ] AC-S2: `zoom` is the ONLY `LensState` field read, and no membership, emphasis, grouping, fold or
      label decision is computed here
- [ ] `Node.prefix` is read **nowhere at all**, and no prefix literal appears in the file
- [ ] AC-S3: an emphasis-only re-projection at rest moves no mark; a membership change keeps every
      surviving node's position and places only new nodes; a container resize at rest leaves
      `viewport` unchanged and re-places nothing
- [ ] AC-S4: no colour value appears in the drawing code — every colour resolves from a CSS custom
      property or the forced-colours system-colour probe
- [ ] AC-S5: the frame path performs no ARIA write, no live-region write, no DOM style read and no
      layout measurement
- [ ] AC-S6: two rows between the same drawn pair are two distinct, individually hoverable marks,
      each citing its own table row
- [ ] AC-S7: hover changes appearance only — drawn sets identical before, during and after, and
      nothing written to the store
- [ ] AC-S8: the canvas element gains no attribute but the `width`/`height` that ARE the drawing
      buffer; it takes no tab stop, hosts no control and contains no child element
- [ ] AC-S9: the three write patterns are exactly as specified, with the platform's leading `click`
      selecting and the repeat ignored
- [ ] AC-S10: both unavailability paths reach `mode: 'unavailable'` with the static sentence, one
      prefixed `console.warn`, and exactly two live regions still on the page
- [ ] AC-10: every mark corresponds to a `ViewModel` entry; no fetch, no dynamic import, no second
      read of anything
- [ ] AC-21: every viewport action — zoom in, zoom out, reset-to-fit, pan in four directions — is
      driven by keyboard alone through the shell's manifest-built control, and **no control exists on
      the canvas**. Node dragging is excluded under NFR-6's path-dependent exemption
- [ ] AC-6a instrumentation supplied for the headless predicate to read, asserting **no figure** —
      the bench, the statistic and the verdict are task-010's
- [ ] No media query is called here; the preference pair is read from the store (feature-007 detects
      it)
- [ ] No degraded mode for a large graph is built and no ceiling warning is emitted here — the
      ceiling is task-010's measurement and task-021's warning
- [ ] **All existing tests still pass** (IMPLEMENT type-default, `task-decomposition.md`:175). Named
      explicitly because this task touches surfaces shared beyond this work's own suites, so a
      regression can land where the graph suites do not look: run the affected suites, not only the
      `test-graph-*` set. Use `tests/canonical/select-suites.sh --run` to pick them by change set
- [ ] All section-6 quality gates pass
