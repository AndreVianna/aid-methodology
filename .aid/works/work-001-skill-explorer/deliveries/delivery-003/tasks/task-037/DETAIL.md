# task-037: Doorway dispatch rows and the doorway body provider

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-037. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-037/STATE.md.
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

**Depends on:** task-035, task-036

**Scope:**
- Add two rows to the shape-to-extractor dispatch in `site/scripts/lib/flow-graph/index.mjs` -- `engine-doorway -> extractEngineDoorway` and `sibling-doorway -> extractSiblingDoorway` (E-DEP-1). **That file was created by task-029**; this is the additive extension feature-003's own Feature Flow already names as the declared seam.
- Add the `flow-chart-doorway` entry to `BODY_PROVIDERS` in `site/scripts/skills/body.mjs` (E-DEP-2). **That file was created by task-010 in delivery-002 and last edited by task-029**; this task adds one entry and edits nothing else in it, including feature-003's existing entry.
- The provider emits the **same `## Flow` H2** task-029's provider emits, fixed by task-019's seam 3, so the page table of contents, feature-005's appended fragment list and feature-006's DOM lookup anchor identically whatever a skill's shape is.
- **Array order is not load-bearing, and that is a designed property rather than luck.** `classifySkill` returns exactly one value from a five-member enum; feature-003's provider claims `{dispatch-table, inline-states, residual}` and this one claims `{engine-doorway, sibling-doorway}`. The two sets **partition** the enum, so at most one predicate can ever fire and neither provider can shadow the other. Relying on ordering instead would be fragile in the one way that matters: the day a sixth shape is added, an order-dependent design silently routes it to whichever provider is first, while a partition design leaves it unclaimed. **The guard is therefore a test, not a comment.**
- `classifySkill` is called more than once per skill -- once by the provider predicate, once inside `buildFlowChart`. That is accepted: it is a pure regex scan over a short body, and purity, not call count, is what AC-6 depends on. Memoizing it is an optimization the implementer may take, not a contract.

**Acceptance Criteria:**
- [ ] Both dispatch rows are present in `index.mjs` and route to the two extractors from task-035 and task-036; the three authored rows are unchanged.
- [ ] **For every directory under `canonical/skills/`, exactly one `BODY_PROVIDERS` entry's `applies()` returns `true`** -- asserted as a test over the live directory listing, not stated as a comment.
- [ ] The two providers' `applies()` sets partition the five-shape enum: neither claims a shape the other claims, and together they claim all five.
- [ ] Both providers emit the identical `## Flow` H2 string, asserted by comparing the two rendered outputs rather than by inspection.
- [ ] `BODY_PROVIDERS` remains a **static array literal** after the edit -- no glob, no dynamic `import()`, no registration side effect.
- [ ] Exactly one entry is added to `body.mjs`; feature-003's existing entry and every other line of that file are untouched, verified by diff.
- [ ] **FR-2 holds at the page level:** no skill page is left with an unfilled body slot, which the provider-partition assertion discharges alongside feature-003's classifier-level version of it.
- [ ] Delivery-002's guarantees still hold: AC-1, AC-2 and AC-8 pass unchanged and `gen-reference.mjs` is byte-unmodified.
- [ ] Unit tests exist for the dispatch rows and the partition guard; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
