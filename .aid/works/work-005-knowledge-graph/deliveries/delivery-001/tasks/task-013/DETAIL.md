# task-013: Build the graph view assembly driver

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-013/STATE.md.
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

**Source:** feature-007-graph-view-shell -> delivery-001 (Wave 2)

**Depends on:** task-012

**Scope:**
- **The missing producer.** Five view templates ship
  (`canonical/aid/templates/knowledge-graph/graph-model.js`, `graph-controls.js`, `graph-table.js`,
  `graph-css.css`, `graph-skeleton.html`) but **nothing on disk writes `graph.html`**:
  `canonical/aid/scripts/summarize/assemble.sh` contains zero graph references and the skeleton's
  ten placeholders have no filler. `canonical/skills/aid-graph/references/state-render.md` is a
  router that invokes an assembly which does not yet exist.
- **STEP ZERO — a conformance read, before writing any model code. This task is the ASSEMBLY DRIVER;
  it is not a rewrite of the model layer.** `graph-model.js` already ships at **93,550 bytes** and
  already defines `project()`, `createStore`, `setLens`, `openTargetFor`, `edgeFold`, `nodeEmphasis`,
  `coverageGaps`, `LENS_KEYS`, `PRESETS`, `LABEL_BUDGET` and `HEADER_LITERAL` — which is feature-007's
  D1, D2, D3, D4, D6, D7 and D9 — and `graph-controls.js` ships at 46,606 bytes with
  `buildControlManifest`. So **read those two files against feature-007's design decisions first and
  record, per decision, whether it already holds.** Only the decisions that do **not** hold are in
  this task's write scope. Without this step the Scope below reads as licence to rewrite ~140 KB of
  shipped, passing template code; `task-015` applies exactly this treatment to the identical situation
  for `graph-table.js`, and the two tasks must not disagree about the same fact.
- Generate the `.aid/.temp/graph/graph-src` layout the reused assembler already validates —
  `skeleton-head.html`, `sections/*.html`, `section-manifest.txt`, `skeleton-foot.html`,
  `post-script.html` — and invoke
  `canonical/aid/scripts/summarize/assemble.sh --src .aid/.temp/graph/graph-src --manifest <manifest>
  --output .aid/knowledge/graph.html`. All three flags are real (feature-007 SPEC `:1565`). **No
  fork of the assembler** (AC-17, FR-12, C-4).
- Fill every skeleton placeholder: `{{LANG}}`, `{{PROJECT_NAME}}`, `{{GENERATION_DATE}}`,
  `{{SOURCE_STAMP}}`, `{{INLINE_CSS}}`, `{{INLINE_COVERAGE_PREDICATE}}` (byte-identical to the
  canonical `coverage-predicate.mjs`), `{{INLINE_LIGHTBOX_JS}}` (reused from
  `knowledge-summary/references/lightbox.js`), `{{PREREQUISITES}}`, `{{SCALE_CEILING_NOTE}}`, and
  `{{INLINE_GRAPH_JS}}` — the last stubbed here and filled by task-017.
- Implements feature-007's D1 `GraphModel`, D2 loader, D3 `LensState`, D4 `ViewModel`, D5 palette,
  D6 filtering and the four lenses, D7 the two node gestures, D8 the `CONTROL_MANIFEST`, D9 label
  shortening, D10 the coverage predicate in two runtimes.
- **Depends on task-012 because this is BLUEPRINT edge 4** — feature-006 before feature-007: the
  `GV02`/`GV04`/`GV08` assertions and the Coverage lens verify against `coverage-predicate.mjs` and
  the `kb_gaps` record feature-006 writes.

**Acceptance Criteria:**
- [ ] `.aid/knowledge/graph.html` is produced, from `relationships.md` **alone** — one input, no
      fetch, no dynamic import, no second read of anything (FR-3, AC-10)
- [ ] The reused `assemble.sh` is invoked with its three real flags; no assembler or validator logic
      is duplicated anywhere (AC-17)
- [ ] `{{INLINE_COVERAGE_PREDICATE}}` is byte-identical to
      `canonical/aid/scripts/graph/coverage-predicate.mjs` — one implementation, two runtimes (D10,
      AC-15)
- [ ] The store is created with the `prefers-reduced-motion` and `forced-colors` pair detected inside
      the shell, on load and on each `change` event, keeping `project()` DOM-free and headless
- [ ] Mount order puts the table half **first and unconditional**, so the page is usable with no
      drawing context
- [ ] The page carries **exactly two** live regions
- [ ] Every control is a real focusable element built from `CONTROL_MANIFEST`; no control is drawn on
      a canvas (AC-21's trap)
- [ ] `project()` interprets the lens exactly once and publishes the drawn set; no membership,
      emphasis, grouping or fold decision is left for a renderer to re-derive (NFR-3)
- [ ] Exit codes match `state-render.md`'s routing table exactly: 0 chains to VALIDATE, 1 chains only
      if a page was written, 2 aborts as an invocation error
- [ ] Both `graph.html` and any companion files sit under `.aid/knowledge/` (FR-9, A-4, C-8)
- [ ] All section-6 quality gates pass
