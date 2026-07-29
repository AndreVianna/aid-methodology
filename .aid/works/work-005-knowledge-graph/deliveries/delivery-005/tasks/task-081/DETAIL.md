# task-081: Mark painting, non-colour encoding and the accessibility proxy layer

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

**Depends on:** task-078, task-080

**Scope:**
- **Paint (feature-008 § Feature Flow step 4).** In
  `canonical/aid/templates/knowledge-graph/graph-canvas.js`, draw edges, then nodes, then labels.
  Each mark's shape comes from `node.glyph` -- assigned in `GraphModel` precisely so the graph and
  the table cannot disagree about it -- its emphasis class from `viewModel.nodeEmphasis` /
  `edgeEmphasis`, and its accessible name from `viewModel.nodeLabels`. Colour is applied **in
  addition**, never instead (NFR-5).
- Zero-row nodes arrive as complete `Node` records with `degree === 0` and a `nodeLabels` entry
  already carrying `"<name> -- no recorded relationships"`. This module picks that marker up
  through `nodeLabels` and must contain **no `degree === 0` branch** -- the whole point of the
  complete record is that consumers handle the class without knowing it exists.
- **Styling.** Add the mark and surface rules to
  `canonical/aid/templates/knowledge-graph/graph-css.css` using `var(--token)` only and declaring
  **no new colour token**, so `contrast-check.mjs` keeps passing on the pairs it already knows.
  This file is shared: tasks 058 and 063/064 land before this one, and this task adds only
  mark/surface rules.
- **The accessibility proxy layer, and why it exists.** Canvas and WebGL paint into an opaque
  buffer that exposes nothing to assistive technology; only SVG and the DOM produce
  accessibility-tree semantics for free. So the semantics are built here, whatever the renderer:
  the graph surface carries `role="application"` with an `aria-roledescription` naming it a
  relationship graph -- telling the reader the arrow keys are the graph's rather than the
  browser's -- inside feature-007's `<section aria-label="Relationship graph">`; and a visually
  hidden **surface description** paragraph, referenced by `aria-describedby`, states node and edge
  counts from `viewModel.counts`, the active lens, and how to navigate. Under a pixel renderer
  this layer additionally carries per-mark accessible names and must be kept aligned with the
  drawing on resize.
- **Announce on membership change only -- this is a hard budget, not a preference.** Per
  feature-008 § "Frame budget", the expensive accessibility operations are forced
  accessibility-tree rebuilds caused by writing many ARIA attributes or live-region updates per
  frame, not the visual draws. So ARIA attributes and the surface description are written **only**
  on membership change; no ARIA write and no live-region write ever happens inside a layout tick
  or a repaint. The polite live region belongs to feature-007 and is written once per lens change
  -- this module never writes it.
- **Focus and group frames.** Draw the current graph focus as a ring **plus** a persistent label,
  so focus survives at low contrast and in forced-colors mode; draw one frame per
  `viewModel.groups` entry with its visible caption taken from the group's `label` as text.
- **Legibility.** Suppress labels below the legibility threshold rather than shrinking them, so no
  text is ever painted under the 10 px rendered size `validate-visuals.mjs` treats as illegible
  (T1) -- a rule worth keeping even where the surface is not collected by that gate, because the
  reason behind the threshold is the reader, not the script.
- **Provisional by instruction.** feature-008's SPEC and delivery-005's BLUEPRINT both state that
  the canvas must not be sized before delivery-001's rendering recommendation is known. The size
  and shape of the proxy layer in particular swings on that answer -- it is near-free under SVG
  and hand-built under Canvas or WebGL. Re-read delivery-001's decision record (task-005) before
  starting rather than trusting this slice.
- **Out of scope:** pointer and keyboard interaction, the viewport controls and the coverage
  density exemption (task-082); the peer table's ARIA and badges (feature-009); feature-007's two
  live regions and the control panel; the AC-9 and NFR-5 verification (task-088).

**Acceptance Criteria:**
- [ ] Paint order is edges, then nodes, then labels, and every mark's shape derives from
      `node.glyph` rather than from a mapping local to this module.
- [ ] Every meaning in feature-008's NFR-5 table renders its non-colour carrier: with colour
      removed (forced-colors emulation) node kind and provenance are still distinguishable, and
      the `kb:` / `int:` / `ext:` id prefix in the label alone carries kind.
- [ ] `graph-css.css` declares **no new colour token** -- every colour is an existing
      `var(--token)` from `design-tokens.md` -- and
      `node canonical/aid/scripts/summarize/contrast-check.mjs .aid/knowledge/graph.html` passes
      in both themes.
- [ ] The graph surface carries `role="application"` and an `aria-roledescription` naming it a
      relationship graph, with `aria-describedby` resolving to the visually hidden surface
      description.
- [ ] The surface description states node and edge counts from `viewModel.counts`, the active
      lens, and how to navigate.
- [ ] The surface description and every ARIA attribute are written **only** on membership change:
      across a scripted sequence of one emphasis-only change, one `zoom` change, one layout tick
      and one repaint, the count of ARIA writes is **zero**.
- [ ] This module performs no write to feature-007's live regions at all.
- [ ] Graph focus is drawn as a ring **plus** a persistent text label.
- [ ] Group frames carry their `viewModel.groups[].label` as a visible text caption.
- [ ] Labels are suppressed, never shrunk, below the legibility threshold; no label is painted
      below 10 px rendered size.
- [ ] A zero-row node renders with its `nodeLabels` text including `-- no recorded
      relationships`, and this module contains no `degree === 0` branch.
- [ ] All existing canonical suites still pass; the named suites land in **task-088** (the NFR-5
      encoding and the accessibility obligations) and **task-087** (legibility across the density
      and zoom range).
- [ ] Build passes: `graph.html` still assembles through task-065's section manifest and
      `canonical/aid/scripts/summarize/assemble.sh`; the full generator run and the render-drift
      confirmation land in task-086.
- [ ] `.aid/knowledge/coding-standards.md` JS conventions are honoured, and both edited files are
      authored under `canonical/` only -- no rendered copy is hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
