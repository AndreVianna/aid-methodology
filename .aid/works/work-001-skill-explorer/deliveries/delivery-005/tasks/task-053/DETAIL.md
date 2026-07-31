# task-053: `skill-node-panel.dom.test.ts` -- jsdom lifecycle and ARIA suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-053. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-053/STATE.md.
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

**Type:** TEST

**Source:** work-001-skill-explorer -> delivery-005 (feature-006-interactive-node-panel)

**Depends on:** task-045, task-049, task-050, task-051

**Scope:**
- Author `site/src/lib/__tests__/skill-node-panel.dom.test.ts` under `// @vitest-environment jsdom`, against **a synthetic SVG fixture the test builds itself** in the shape verified against the locked mermaid install: a node's group element is `<g class="node default aidNode" id="flowchart-<id>-<n>">`, `domId` is `"flowchart-" + id + "-" + vertexCounter`, and the layer order inside the SVG is clusters, edgePaths, edgeLabels, **nodes last**. jsdom cannot run mermaid and does not need to -- the fixture reproduces the rendered shape, and tests build their own fixtures per the tracking rule.
- Six groups: **Activation**, **Keyboard + ARIA**, **Re-render survival**, **Degradation**, **Resolve-or-skip** and **Schema guard**.
- **Focus *placement* is deliberately NOT asserted here, and the suite must say why.** jsdom's focusable-area model does not reliably treat an SVG `<g>` carrying `tabindex` as focusable, so `document.activeElement` there would prove nothing about a real browser. This suite therefore asserts the **attributes and state that make focus possible** -- `tabindex`, `role`, `aria-label`, `aria-controls`, `aria-expanded` -- while focus order, focus return, screen-reader announcement and the 360 px layout are the four checks performed **once by hand at the delivery gate**, recorded like feature-005's AC-7 with a dated Pass / Pass-with-observations / Fail verdict. Per feature-006's default the three accessibility checks block and the layout check is an observation; feature-006's OQ-3 puts the severity line and the staffing to the owner.
- The Activation fixture deliberately contains **no fragment list at all** -- omitting it is the point, because it proves the panel's data path runs through the projection and not through feature-005's DOM, which that feature explicitly forbids this one from reading.

**Acceptance Criteria:**
- [ ] The file carries `// @vitest-environment jsdom` and the rest of the suite runs unchanged in the default `node` environment.
- [ ] The synthetic SVG fixture is built **inside the test file** and matches the verified mermaid shape: `g.node.default.aidNode` with `id="flowchart-<id>-<n>"`, and nodes painted last.
- [ ] **Activation (AC-6.1):** clicking a node reveals the panel with that node's `name`, `label` and `kind`, and a `<pre>` whose `textContent` equals the projection's `fragment` exactly; the `[Source]` href equals `source.url`; the `full step` link appears iff `detail !== null`; the `#fragment-<id>` link is present. **The fixture contains no fragment list**, proving the data path does not read feature-005's DOM.
- [ ] **Keyboard + ARIA (AC-6.2):** every decorated node carries `role="button"`, `tabindex="0"`, a non-empty `aria-label`, `aria-controls` equal to the panel id, and an `aria-expanded` tracking open state. `Enter` and `Space` open; `Space` calls `preventDefault`; `Escape` closes and resets `aria-expanded`; re-activating the open node toggles it closed.
- [ ] **Re-render survival (AC-6.3):** the theme observer is simulated in the integration's exact order -- remove `data-processed`, replace the container's `innerHTML` with a fresh SVG, set `data-processed` again -- for **three cycles**, asserting every new node is decorated and that **one** activation produces **exactly one** panel-open, measured by a counting spy on the reveal.
- [ ] **Degradation (AC-6.4):** (a) no `data-processed` yields no decoration, no panel and no throw; (b) `data-processed` set **after** the controller loads triggers decoration on the mutation; (c) `data-processed` set with an error `<div>` and **no `<svg>`** yields no decoration, no panel and exactly one `console.warn`.
- [ ] **Resolve-or-skip:** a `g.node.aidNode` whose id does not match the template, and one whose recovered id is absent from the projection, are both left undecorated while siblings still work -- with one `console.warn` **per page, not per node**.
- [ ] **Schema guard:** `v: 2` in the island makes the controller no-op entirely and warn once.
- [ ] **Focus placement is not asserted**, and the suite carries a comment giving the jsdom reason and naming the four manual gate checks that cover it.
- [ ] Every fixture is built in the test file; nothing under `.aid/works/` is read; no network call is made.
- [ ] Tests are deterministic with clean setup/teardown, and each test tears down its jsdom document so no state leaks between cases.
- [ ] AC-6.1 through AC-6.4 are covered by this suite.
- [ ] All existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
