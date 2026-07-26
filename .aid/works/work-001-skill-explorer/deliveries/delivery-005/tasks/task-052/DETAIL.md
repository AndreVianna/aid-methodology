# task-052: `skill-node-panel.test.ts` -- node-environment suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-052. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-052/STATE.md.
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

**Depends on:** task-046, task-049

**Scope:**
- Author `site/src/lib/__tests__/skill-node-panel.test.ts` in vitest's **default `node` environment** -- no environment directive, so this suite proves the pure half needs no DOM. Four groups: **Gate**, **Projection**, **Embedding** and **Controller source shape**.
- The Gate, Projection and Embedding groups drive task-046's exported functions. The **Controller source shape** group reads the *text* of `site/public/skill-node-panel.mjs` and asserts what it must not contain -- the mechanically checkable half of "no new runtime dependency" (AC-6.6) and of the XSS rule, and the only way to check a `public/` asset that Astro neither bundles nor type-checks.
- **Why this suite depends on task-049 rather than task-050:** the source-shape assertions need the controller file to exist, and task-049 creates it. The assertions are negative, so they hold against the partially-written file too, and task-050's own "all existing tests still pass" criterion re-runs them once the panel half lands -- which is what catches an `innerHTML` introduced later.
- This suite is deliberately silent about DOM lifecycle, ARIA and focus: those need jsdom and belong to task-053.

**Acceptance Criteria:**
- [ ] The file carries **no `@vitest-environment` directive** and passes in the default `node` environment, with no `document`, `window` or `MutationObserver` reference anywhere in it.
- [ ] **Gate:** `shouldMount()` is asserted against all five cases by name -- a real skill `generatedFrom`; a `reference/*.md` page's `generatedFrom`; `undefined`; a skill name absent from the sidecar set; and a name failing the charset -- including feature-002's index `generatedFrom` string, which must be rejected by the anchor rather than by a special case.
- [ ] **Projection:** the emitted field set is exactly `PanelNode`'s, asserted by walking the serialized JSON and confirming **no `edges`, `warnings`, `sources`, `entries`, `exits`, `title`, `shape` or `extractor` key survives at any depth**.
- [ ] **Projection:** `nodes` keeps chart array order without re-sorting; `fragment === provenance.excerpt` byte-for-byte; `source.url === blobUrl(...)` for **both** the single-line and multi-line anchor forms; `detail` is `null` or link-only.
- [ ] **Embedding:** `embedJson()` output contains no literal `<`, and `JSON.parse` round-trips to a deep-equal object -- with fixtures containing `</script>`, `<!--`, `<div>`, a 4-backtick run, a pipe, `{braces}` and a non-BMP character.
- [ ] **Controller source shape:** the text of `site/public/skill-node-panel.mjs` contains no `import `, no `fetch(`, no `localStorage`, no `sessionStorage`, no `innerHTML`, no `eval` and no `new Function`.
- [ ] Every fixture is built inside the test file; nothing under `.aid/works/` is read; no network call is made.
- [ ] Tests are deterministic with clean setup/teardown.
- [ ] AC-6.1's data half, AC-6.5's pure predicate and AC-6.6 are covered by this suite.
- [ ] All existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
