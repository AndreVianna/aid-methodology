# task-035: Engine-doorway extractor

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-035. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-035/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-004-doorway-engine-charts)

**Depends on:** task-033, task-034

**Scope:**
- Create `site/scripts/lib/flow-graph/extract-engine.mjs` -- shape 3, `engine-doorway`: `extractEngineDoorway(skillRecord) -> FlowChart`.
- Build the one-node prefix from `readDoorwayBinding` (task-034): `name` is the directory name, per the engine's Invocation Contract that `{name}` is "the invoking doorway's own directory/skill name"; `label` is the doorway's own Bind clause rendered as `Bind VERB=..., ARTIFACT=...`, truncated by feature-003's shared truncator so it is V8-safe unconditionally; `provenance` is that single body line with `sourceKind: 'skill'`.
- The hop edge is `sequence` with `condition: null` -- a generated doorway binds and runs; nothing about it is conditional.
- Compose with `getEngineCore()` through `composeDoorwayChart`, then hand the result to feature-003's `validateChart` and `renderMermaid` unchanged. This feature defines no model, no validator, no renderer and no substrate.
- Emit the one-line **engine resolution notice** above the fence, so a reader does not conclude that `aid-create-api` contains an `APPROVAL-HALT` state: *derived from the shared shortcut engine, which this doorway binds and runs*, carrying a `canonical/` link on the same `GITHUB_BLOB_BASE` feature-001 declares. It is prose above the fence, not a chart node, so it costs feature-006 nothing.

**Acceptance Criteria:**
- [ ] For `aid-create-api`: `shape === 'engine-doorway'`, `extractor === 'extract-engine'`, `confidence === 'derived'`.
- [ ] `entries` is exactly `[nodes[0].id]`; `nodes[0].name === 'aid-create-api'`; `nodes[0].kind === 'entry'`; its `label` contains `VERB=create` and `ARTIFACT=api`; its `provenance.file` is that skill's `SKILL.md` and the excerpt matches the live slice.
- [ ] For `aid-fix`, the entry label carries the bare-verb form `ARTIFACT="" (bare verb)` **as written** -- the one binding form the primary fixture cannot exercise.
- [ ] The hop edge is `kind === 'sequence'` with `condition === null`.
- [ ] The prefix is exactly one node, so the composition offset is `1` on every page.
- [ ] The composed chart's node names in `order` are exactly the doorway followed by the nine engine-segment names, including the two B1 nodes in their deterministic positions.
- [ ] `validateChart(chart).ok === true`, with `entries.length === 1` and `exits.length >= 1`; `exits` contains `APPROVAL-HALT` with `terminal.advanceType === 'HALT'` and a `terminal.handoff` mentioning `/aid-execute`, plus `CONTINUATION` and `Circuit breaker`.
- [ ] The resolution notice is emitted as prose above the fence, carries a `GITHUB_BLOB_BASE` link, and is **not** a chart node.
- [ ] No model, validator, renderer or substrate is defined or modified by this module -- it consumes feature-003's as published, verified by diff over those files.
- [ ] Unit tests exist for the binding, the hop edge and the composed spine; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
