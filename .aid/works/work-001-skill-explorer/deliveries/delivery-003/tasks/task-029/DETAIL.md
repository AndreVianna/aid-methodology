# task-029: `buildFlowChart` façade and the authored-flow body provider

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-029. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-029/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-024, task-025, task-026, task-027, task-028

**Scope:**
- Create `site/scripts/lib/flow-graph/index.mjs`: the `buildFlowChart({ name, dir })` façade -- classify, dispatch to the matching authored extractor, validate -- plus the exported public API surface features 004, 005 and 006 consume (`classifySkill`, `buildFlowChart`, `validateChart`, `renderMermaid`, `serializeChart`). The dispatch table holds the three authored shapes here; task-037 adds the two doorway rows.
- **The façade throws** on any `validateChart` error, matching the guard shape `gen-reference.mjs` already uses. `chart.warnings` are logged with a run-level count and never thrown -- that is FR-2's best-effort boundary: a chart may be *approximate*, never *malformed*. Note that V9 throws earlier, from `advance.mjs` during extraction (task-023), so a V9-dirty chart never reaches the validator.
- Add the `flow-chart-authored` entry to `BODY_PROVIDERS` in `site/scripts/skills/body.mjs` -- **a file created by task-010 in delivery-002**, extended here by the seam feature-001 published for exactly this purpose. The entry's `applies()` claims exactly the three authored shapes (`dispatch-table`, `inline-states`, `residual`); it must not claim the two doorway shapes, which task-037's provider takes.
- The provider owns its own heading and emits **the `## Flow` H2 fixed by task-019's seam 3**, then the fenced mermaid block from `renderMermaid`, and -- for a chart whose `confidence` is `approximate` -- the short notice line above the fence that makes NFR-3's interpretation risk visible.
- `BODY_PROVIDERS` remains a **static array literal**: no globbing, no dynamic `import()`, no registration side effect, because filesystem enumeration order is not guaranteed and would put AC-6 at the mercy of the OS.

**Acceptance Criteria:**
- [ ] `buildFlowChart` classifies, dispatches to the correct authored extractor, validates, and **throws** on any `validateChart` error; the thrown message names the failing rule and the offending node or edge.
- [x] `chart.warnings` are logged with a run-level count and **never** thrown.
- [ ] The dispatch table routes `dispatch-table`, `inline-states` and `residual`; the two doorway shapes are absent here and are added only by task-037.
- [ ] The provider's `applies()` claims exactly `{dispatch-table, inline-states, residual}` -- verified by asserting it returns `false` for both doorway shapes.
- [ ] The provider emits the H2 string fixed by task-019 seam 3, byte-for-byte, and task-037's provider will emit the identical string.
- [ ] The `approximate` notice renders above the fence for, and only for, a chart with `confidence: 'approximate'`.
- [ ] The H2, fence markers and notice are emitted by the **provider**, not by `render-page.mjs` and not by `renderMermaid` -- feature-001's body slot imposes no structure and this task does not add one.
- [ ] `BODY_PROVIDERS` in `skills/body.mjs` remains a static array literal after the edit: no glob, no dynamic `import()`, no registration side effect.
- [ ] Only one entry is added to `body.mjs`; nothing else in that file is modified.
- [ ] Unit tests exist for the dispatch, the throw-on-invalid path and the provider predicate; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
