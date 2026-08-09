# task-032: Make the graph view usable — the owner's findings from the first real page

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-032/STATE.md.
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

**Source:** feature-007-graph-view-shell + feature-008-interactive-graph-canvas + feature-009-accessible-table-view -> delivery-001 (Wave 3)

> **WHY THIS TASK EXISTS.** On 2026-08-06 a rendered `graph.html` was opened in real Chromium for the
> first time in this work -- real WebGL 2.0 context, the five real UMD library builds loaded. **Every
> headless proxy was green**: `mode: 'live'`, marks derived, frames drawn, all seven viewport controls
> present, the shell handle wired. The page was unusable: a blank-looking surface, a false "not
> available" message, and no working mouse interaction at all. The owner then inspected it personally
> and reported further defects.
>
> **Every finding below required LOOKING at the artifact.** None was found by a reviewer reading code;
> none would have been caught by the `GC`/`GV`/`TV` series as designed, because those assert over the
> published draw record and the DOM -- and the draw record said everything was fine. This is
> `work-017`'s failure mode repeating: that work shipped four broken edit surfaces past an A+ gate for
> exactly this reason.
>
> **It also produced a measurement error of mine that this task must not inherit.** I first reported
> "all seven viewport controls are wired and dead", measured by `frames.length` failing to grow. But
> `frames` is a RING buffer saturated at 240 -- its length can never grow. Re-measured against
> `frames[frames.length-1].t`, the wheel handler runs (`defaultPrevented === true`) and both the wheel
> and the zoom-fit click DO repaint. That finding is retracted (ledger row 9, marked Invalid, kept
> visible on purpose). What survives is narrower and real: see § C.
>
> The interaction model in § D and the control decision in § E are the **owner's specification, given
> directly**. They are not proposals to re-litigate.

**Depends on:** task-017

**Scope:**

**A. The canvas draws off-screen.**
- Positions are centred on the ORIGIN -- measured `kb:beta.md` at `(-29.58, 21.61)`,
  `kb:beta.md#decision-log` at `(28.40, -22.93)` -- but in PixiJS `(0,0)` is the drawing buffer's
  **top-left corner**, and the initial viewport is `{scale: 1, panX: 0, panY: 0}`. A ~60px cluster
  straddles the corner with its negative half off-canvas. The owner's screenshot shows exactly two
  glyphs and one dashed edge in the top-left corner of an otherwise empty surface.
- `gcViewportFor`'s `reset-to-fit` already computes the right transform and is **never applied at
  mount**. Apply it at first paint. Do not write a second fitting algorithm.

**A0. ROOT CAUSE, found and FIXED on 2026-08-06 -- read this before A, B or D.** A and B each named a
real defect but each mis-scoped its cause. The actual cause of "off-centre" AND of "mouse interaction
does not work" was one omission: **`view.viewport` was never written to the PixiJS stage on any path.**
- `view.viewport` was read in 12 places -- all hit-testing (`gcLocalPoint`, pick radii) or
  self-reporting (`frames[].applied`) -- and written to the stage in **none**. The only stage transform
  was `gcResize:628` setting `scale` to `(dpr, dpr)`; `stage.position` was never set anywhere. Marks
  draw at raw world coordinates (`gcDrawFrame:988`).
- So **A's prescription could not have worked**: applying a fit at mount writes `view.viewport`, and
  nothing rendered `view.viewport`. Any value would have drawn identically.
- And **B was one of two blockers in series, not the root cause**: fixing the placeholder let events
  reach the handlers (verified), and the owner correctly reported interaction still broken, because the
  handlers' output was never rendered.
- **Fixed** by `gcApplyStageTransform(view)`, called from `gcDrawFrame` before the draw call on every
  frame -- the exact inverse of `gcLocalPoint`, `buffer = world * (scale*dpr) + (pan + size/2)*dpr`.
  Verified in Chromium with real trusted input: graph centred with all 14 nodes on-surface, wheel moves
  `applied.scale` 1 -> 1.25 -> 1, left-drag moves `applied.panX/panY`, and a click at a node's
  transform-computed position emphasises exactly that node. Ledger row 13.
- **What A still owes:** centre-and-fit *at first paint* (the transform now exists to carry it) and the
  responsive-resize half. **What B still owes:** nothing -- B is done.
- Lesson for whoever executes this task: reachability is not effect. `elementFromPoint` returning
  `CANVAS` and `defaultPrevented === true` prove an event arrived, not that anything happened. Assert on
  a rendered difference.

**B. One CSS bug causes the false message AND kills all mouse interaction. Fix this first.** *(FIXED
2026-08-06 -- the `[hidden]` rule is in `graph-css.css`; see A0 for why it was not the whole cause.)*
- `graph-controls.js:925` correctly sets `placeholder.hidden = true` -- the IDL property reads `true`.
  But the element's **computed `display` is `flex`**, and an author `display` declaration beats the
  `hidden` attribute's UA `display: none`.
- **Symptom 1:** the placeholder stays painted, reading "The interactive drawing surface is not present
  in this build..." while `mode === 'live'`. A false statement to every reader.
- **Symptom 2, the serious one:** it is `position: absolute` over the identical area as the canvas
  (measured 1158x495 at (164,819) vs the canvas's 1158x510 at the same origin) with `pointer-events:
  auto`, and being positioned it paints ABOVE the statically-positioned canvas.
  `document.elementFromPoint` inside the canvas returns **`P[data-graph-placeholder]`, not `CANVAS`**.
  So click, drag, wheel and double-click never reach their handlers. **The handlers are correctly
  bound** -- `gcBindPointerEvents` (`:458`) binds to `view.canvas`, the appended element set at `:419`.
  They simply never receive an event. Proven by removing the overlay in-page: `elementFromPoint` then
  returns `CANVAS` and a dispatched wheel reaches `gcOnWheel`.
- **Fix: a `[hidden]` rule that actually wins**, e.g. `[data-graph-placeholder][hidden] { display: none }`.
  **Do not "fix" the JS -- it is already correct.** This single change repairs the false sentence and
  every mouse gesture at once.

**C. The published draw record misreports the viewport.**
- Measured: a wheel over the canvas has `defaultPrevented === true` and the frame ring's newest `t`
  advances (324507.1 -> 394842); the zoom-fit click advances it too. **But
  `__aidGraphCanvas.viewport` stays `{scale:1,panX:0,panY:0}` throughout.**
- D3's published record is *the interface a headless driver reads*, and the only viewport signal
  `task-018`'s `GC` series can assert over. So an assertion of the form "after zoom-fit,
  `record.viewport` differs" fails against working code, and its inverse blesses broken code.
- **Fix the reporting surface**, not the behaviour. And note this is why my own row 9 was wrong -- a
  test written against `record.viewport` today would have "confirmed" a defect that is not there.

**D. The mouse interaction model -- the owner's specification, given directly.**
| Gesture | Action |
|---|---|
| **Left click** | select the **node** under the pointer (edge selection withdrawn -- see below) |
| **Left double-click** | `store.openTarget(id)` and navigate -- **unchanged from AC-S9** |
| **Right drag** | pan |
| **Right double-click** | reset view: re-centre and fit to the display div |
| **Scroll** | zoom in / out |
- **AC-S9 survives intact.** Its click, double-click and wheel clauses are all preserved -- the owner
  deliberately put reset on the RIGHT button so the left double-click keeps `openTarget`. The single
  clause that shifts is AC-S9's "wheel **or empty-surface drag**": the drag mechanism becomes
  right-drag. Record that as a recorded deviation; do not silently reword the SPEC.
- Right-button gestures **must suppress the context menu**, on the drawing surface only.
- **Update the legend's `Mouse` entry when you change these.** `renderLegend`
  (`graph-controls.js`) now states the gestures in words -- "Scroll to zoom. Drag to pan.
  Click a node to select it; hover a node or a line to read its name." -- which is accurate
  for TODAY's left-drag pan and becomes false the moment pan moves to the right button. The
  legend is the only place the gestures are written down for a reader, so leaving it stale
  would be worse than never having written it.
- **Edge selection is OUT OF SCOPE -- withdrawn by the owner on 2026-08-06:** *"Discard edge selection
  for now. We will revist that later too."* It is not deferred-because-hard; it is a scope decision.
  **Build nothing for it: no 15th lens key, no `focus.edgeKey`, no edge hit-testing beyond what
  already exists.** The four node-side gestures above are independent of it and are the whole of D.
- Why it was raised for a ruling rather than built (kept as the record of what a later revisit costs):
  `LENS_KEYS` has exactly 14 keys (`graph-model.js:237`-`:252`) and a grep for anything
  edge-selection-shaped returns **nothing**. It would need a 15th key, store and `ViewModel` support
  (feature-006/007), the table reflecting the same selection (feature-009), and it **breaks `GV25` by
  design** -- that assertion requires `INITIAL_LENS` to be total over all 14 keys.
- Note `gcLocalPoint`'s edge-distance helper and `gcOnClick`'s edge branch may already exist from
  task-017. Withdrawing selection does **not** mean ripping those out -- leave them unreferenced
  rather than churning shipped code for a scope the owner intends to revisit.

**E. Remove the viewport button row entirely -- OWNER DECISION, with its deviation recorded.**
- The owner's words: "The viewport controls should be only by mouse, no buttons. It could have a text
  explaining the mouse commands but that is all." Offered three options and the accessibility
  consequence of the third, the owner chose it explicitly: **"For now I want C. I will bring them back
  later if needed."**
- **So: delete all seven** -- `zoom-in`, `zoom-out`, `zoom-fit`, `pan-left`, `pan-right`, `pan-up`,
  `pan-down` -- and replace the row with a short line of text naming the mouse commands from § D.
- **Four of the seven are removable with no deviation at all.** NFR-6 (`feature-008 SPEC :32`) states
  "every gesture has a keyboard equivalent; **dragging is exempt** as path-dependent". The owner moved
  pan onto a right-DRAG, so `pan-left/right/up/down` lose their obligation outright.
- **The other three are a real deviation and must be recorded as one.** Scroll-to-zoom and
  right-double-click-to-reset are not drags, so NFR-6 still wants keyboard equivalents, and AC-21
  (`:193`-`:196`) requires them "by keyboard input alone through the shell's manifest-built control".
  Removing `zoom-in`/`zoom-out`/`zoom-fit` leaves a keyboard-only reader unable to zoom or re-centre.
  **Record a recorded deviation against AC-21 and NFR-6** naming: the clause, what is lost, that it was
  the owner's explicit choice on 2026-08-06 after the consequence was stated, and that the owner said
  "I will bring them back later if needed". Do NOT quietly reword AC-21 or NFR-6.
- **Do not put any control on the canvas** as a substitute. AC-21 `:193` calls that "the trap AC-21 was
  written to close", and AC-S8 (`:180`, `:228`) forbids the canvas taking a tab stop or hosting a
  control. Removing the buttons is the decision; moving them onto the canvas is not.
- Remove the now-false caption "Keyboard equivalents for zoom and pan." and the `CONTROL_MANIFEST`
  entries for the seven, so the manifest and the DOM stay in bijection (feature-007 D8) -- a manifest
  entry with no control is its own defect.

**F. Layout and sizing -- the owner's direction.**
- **Full viewport width.** `graph-css.css:124` sets `max-width: 1200px`. The owner wants the full
  viewport width. Remove or raise the cap for this page.
- **Responsive surface height.** `graph-css.css:360` hard-codes `.graph-surface { height: 32rem }`
  (512px), with a `22rem` override at `:599`. It never responds to viewport height.
- **Repaint on resize.** The `ResizeObserver` works (buffer measured 1160 -> 845 -> 1160) -- verify with
  the frame ring's newest `t`, **not** `frames.length`, that a resize actually repaints.
- **Data before chrome.** At an 889px-tall viewport the renderings begin at **y=465**: 52% of the first
  screen is H1, a 99px lede, the lens bar, the controls panel and one further section. The owner's
  ruling: "The data (the graph and the table) is the first class info. The graph controls are just
  supporting tools." Re-order so the graph and table come first, with every remaining control still
  present and keyboard-reachable.
- **The controls panel is badly proportioned.** Four equal columns where two are nearly empty
  ("Isolated nodes" holds one checkbox; "Provenance" holds three) while two scroll internally
  ("Relationship category" 14 items, "Node kind" 7). Size columns to content and let the long lists use
  the freed space instead of scrolling inside ~220px boxes.

**G. The relationship table.**
- **No way to clear a filter.** 29 filter inputs -- 24 checkboxes across category/kind/provenance, plus
  text, orphans, grouping, density, focus -- and **zero** clear/reset/select-all controls. Undoing a
  filter means unchecking up to 24 boxes one at a time.
- **Header sort buttons wrap and are over-padded.** No `th button` rule exists in `graph-css.css`, so
  they inherit the generic button style: "Target Name", "S2T Relation", "T2S Relation" and "Observation"
  all wrap mid-label with excessive vertical padding.
- **Cell content collides.** `Select` buttons sit inline with cell text and crowd it
  (`wcag-contrast-figure` / `Select`; `docs/media/table-view.png` / `Select`).
- **Legend glyph alignment breaks on wrapped rows** -- on "web-page — ring, a circle with a hollow
  centre" the glyph centres against two lines instead of aligning to the first.

**Out of scope, explicitly:**
- **Performance, the node-count ceiling, NFR-7/NFR-8.** Owner deferred outright: "forget the number of
  nodes and performance issues. We will address it when the rest is working correctly." Those stay with
  task-010 and task-021.
- **The `harvest-declared.sh` crash.** `:305` indexes `BASE_IDS` with an empty basename for the 85
  directory-shaped node ids this repo produces (`int:canonical/agents/aid-architect/`), and this host's
  bash rejects an empty associative-array subscript. It is fatal to the whole pipeline and is its own
  task -- but it means **this task can only be verified against the 14-node fixture.** Say so rather
  than implying real-data verification.
- Re-rendering `profiles/` and the two dogfood trees -- that is `task-024`. Byte-identity gates for the
  files touched here are expected red until then.

**Acceptance Criteria:**
- [ ] **Verified in a real browser, not only headlessly.** Every criterion below is confirmed against a
      rendered `graph.html` opened in Chromium with the five real UMD builds and a real WebGL context.
      A headless-only verification closes nothing here -- that is the precise reason this task exists
- [ ] **Never use `frames.length` as a repaint signal.** It is a ring saturated at 240. Use
      `frames[frames.length-1].t`. A criterion "verified" via the saturated counter is not verified --
      that error produced a retracted CRITICAL finding in this very task's history
- [ ] The placeholder is **not visible** when `mode === 'live'` (proven by computed style, not the
      `hidden` IDL property) and **still visible** when `mode === 'unavailable'`
- [ ] `document.elementFromPoint` inside the drawing surface returns the **canvas**, and all five § D
      gestures reach their handlers
- [ ] The graph is **centred and fitted at first paint** via the existing `reset-to-fit`, with every
      drawn mark inside the drawing buffer's bounds
- [ ] `record.viewport` **tracks the real viewport** after a wheel, a drag and a reset
- [ ] The five § D gestures behave as specified, context menu suppressed on the drawing surface only,
      and left double-click still reaches `store.openTarget(id)`
- [ ] All seven viewport buttons and their `CONTROL_MANIFEST` entries are gone; the manifest and the DOM
      remain in bijection; a short text names the mouse commands instead
- [ ] **Two recorded deviations exist and are legible**: AC-S9's drag mechanism, and AC-21/NFR-6's lost
      keyboard zoom/reset with the owner's decision and date
- [ ] Content uses the **full viewport width**; surface height **responds to the viewport**; a resize
      **repaints**
- [ ] Graph and table appear **before** the control surface in reading order and on first screen
- [ ] The controls panel's columns are sized to content, with no near-empty column beside an
      internally-scrolling one
- [ ] The table has a working **clear-filters** affordance; header sort buttons do not wrap; cell text
      and `Select` controls do not collide; legend glyphs align to the first line of a wrapped row
- [ ] **A runtime UI check is committed** so none of this can silently regress. `tests/ui/` with
      `@playwright/test` already exists and Chromium is installed. It must NOT join the required
      `tests/canonical/` suite (project rule: runtime UI checks live outside it) -- but every defect in
      this task was invisible to static tests, so shipping no runtime oracle repeats the failure exactly
- [ ] **All existing tests still pass.** Map the change set by `# COVERS:` and run those;
      `select-suites.sh --run` fail-safe-selects ~140 of 147 suites and will not finish
- [ ] All section-6 quality gates pass
