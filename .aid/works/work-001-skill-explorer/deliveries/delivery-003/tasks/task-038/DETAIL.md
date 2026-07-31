# task-038: `flow-graph-doorways.test.mjs` unit tier

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-038. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-038/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-004-doorway-engine-charts)

**Depends on:** task-037

**Scope:**
- Author the **unit tier** of `site/scripts/__tests__/flow-graph-doorways.test.mjs` -- a sibling file of feature-003's suite, not a merge into it. Task-039 appends the corpus tier to this same file; the two tasks are a strict sequence.
- Cover four groups over inline fixtures written in the test file: **binding extraction** (each rung of both ladders), **engine core** (memo identity and deep-freeze), **purity of compose**, and **degradation** (the five warning classes W1-W5).
- Binding-extraction fixtures: `Bind **VERB=...**, **ARTIFACT=`...`**`; the bare-verb form `**ARTIFACT="" (bare verb)**`; `{verb: ..., artifact: ...}`; `{verb: ..., artifact: ""}`; `alias_of: ...`; and the no-binding fallback with its warning.

**Acceptance Criteria:**
- [ ] Every binding rung of both ladders has a passing case, including the bare-verb form, the empty-artifact braced form, the `alias_of` form and the no-binding W1 fallback.
- [ ] `getEngineCore()` returns the **identical object reference** on the second call, asserted by reference equality rather than deep equality.
- [ ] The returned engine core is **deeply frozen**: a write attempt to a node, an edge and a nested `Provenance` each throw in strict mode.
- [ ] The core's nine node names are asserted to be the seven `## State Machine` rows in table order with each B1 node immediately after its parent state.
- [ ] **Compose purity is asserted by object identity**, not deep equality alone: no composed chart shares a node or edge object with the core, and composing two different doorways leaves `getEngineCore()`'s output deep-equal to a fresh derivation.
- [ ] Each of W1 through W5 produces a `warnings` entry **and a still-valid chart**; none of them throws.
- [ ] Every fixture is inline in the test file and the tier depends on nothing outside it -- nothing under `.aid/works/` is read.
- [ ] **No numeric corpus or per-shape count literal appears** anywhere in the tier.
- [ ] Tests are deterministic with clean setup/teardown.
- [ ] All section-6 quality gates pass
