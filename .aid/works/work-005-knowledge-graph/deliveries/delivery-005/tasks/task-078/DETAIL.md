# task-078: Graph canvas visual encoding, group framing and keyboard wireframe

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

**Type:** DESIGN

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-005, task-056

**Scope:**
- Produce the design artifact for the graph canvas's visual layer, expressed **at the renderer
  delivery-001 recommended**. Read task-005's rendering-approach decision record first: feature-008
  § "What changes with feature-002's answer" is a table of rows this design must decide per
  renderer (mark elements, per-mark focus, accessible names, hit testing, `validate-visuals.mjs`
  collection, proxy-drift risk, payload and build step), and each row resolves differently for
  native SVG, Canvas and WebGL.
- **Visual encoding.** Realise feature-008 § "Colour is never the sole carrier (NFR-5)" as a
  concrete mark specification: rounded rectangle + `kb:` id prefix for `kind: kb`, square + `int:`
  for `kind: int`, diamond + `ext:` for `kind: ext`; solid / dashed / dotted edge strokes for
  `declared` / `derived` / `inferred`, with an `inferred` badge on hover and on focus; hollow fill
  plus a `no source` label for `kb-unbacked` and a `no KB doc` label for `int-undocumented`;
  reduced opacity **and** label suppression for `dimmed`. Colour is additive on every row and is
  named only as an existing `var(--token)`.
- **Group frames.** One frame per `viewModel.groups` entry with a visible caption drawn from the
  group's `label` as text, never as a colour key -- including the dedicated `no relationships`
  group that feature-007 lists last under the `relation-category` and `provenance` grouping
  dimensions.
- **Focus presentation.** A focus ring **plus** a persistent label, specified so focus survives at
  low contrast and in forced-colors mode.
- **Keyboard wireframe.** The seven-row key map of feature-008 § "Keyboard equivalence (NFR-6)" --
  `Tab` / `Shift+Tab` (the surface is a **single** tab stop, not one per node), arrows to pan and
  `Shift`+arrows to move graph focus, `+` / `-` to zoom one step, `0` to reset to fit,
  `Enter` / `Space` to select, `[` / `]` for `focus.depth`, `Escape` to clear graph focus without
  clearing the lens -- each row annotated with whether it writes the renderer-private `zoom` field
  or goes through `setLens`.
- **Viewport controls and legend.** Real `<button>`s with `aria-label`s for zoom in, zoom out,
  reset and fit; and the legend as an authored `.diagram-box` mapping each glyph and each
  provenance marker to its meaning in words, carrying the zero-row-node count line feature-007
  places there.
- **Density, legibility and responsive behaviour.** Label suppression below the legibility
  threshold rather than shrinking, so no text is painted under the 10 px rendered size
  `validate-visuals.mjs` treats as illegible (T1); the surface fitting its container at the
  732 px and 390 px viewports the visual gate measures without horizontal overflow (T4); and the
  768 px mobile breakpoint, matching `canonical/aid/templates/knowledge-summary/design-tokens.md`
  § "Spacing & sizing". Show the control-panel-adjacent layout at 1200 / 768 / 732 / 390 px.
- **Provisional by instruction.** feature-008's SPEC and delivery-005's BLUEPRINT both state that
  the canvas must not be sized before delivery-001's rendering recommendation is known. This
  design is currently shaped for a hand-rolled or lightly-vendored layout; if a full library is
  adopted, several rows collapse into the library's own API. Re-read task-005's decision record
  before starting rather than trusting this slice.
- **Out of scope:** the page shell, region order, the control panel and the two live regions
  (feature-007, task-056 owns them); the peer table's presentation (feature-009); and any code --
  this task produces the design, not `graph-canvas.js`.

**Acceptance Criteria:**
- [ ] Design system tokens used: every colour named is an existing `var(--token)` from
      `canonical/aid/templates/knowledge-summary/design-tokens.md`, and **no new colour token** is
      introduced, so `contrast-check.mjs` keeps passing on the pairs it already knows.
- [ ] Responsive behaviour is shown at 1200 px, 768 px, 732 px and 390 px, with the 768 px mobile
      breakpoint matching `design-tokens.md` § "Spacing & sizing".
- [ ] Every meaning in feature-008's NFR-5 table has a stated non-colour carrier (shape, stroke
      pattern, fill, or label text), and the design records that the `kb:` / `int:` / `ext:` id
      prefix alone carries kind with no shape and no colour at all.
- [ ] Each of the seven key-map rows names its action and states whether it writes `zoom` or goes
      through `setLens`; no navigation action is left mouse-only (NFR-6).
- [ ] The design names the renderer task-005 recommended and records a decision for **every** row
      of feature-008 § "What changes with feature-002's answer" against that renderer.
- [ ] Group frames are captioned with the group `label` as text, and the `no relationships` group
      is placed last under the `relation-category` and `provenance` dimensions.
- [ ] The focus presentation is a ring **plus** a persistent label, and the design states how it
      reads in forced-colors mode.
- [ ] The legend is an authored `.diagram-box` stating each glyph and each provenance marker in
      words, and includes the zero-row-node count line.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
