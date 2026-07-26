# task-003: Absorbed stale-assertion corrections in the five TypeScript suites

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-003. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-003/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-001 (feature-001-skill-detail-pages)

**Depends on:** task-002

**Scope:**
- **This task is CONTINGENT AND CANCELLABLE.** It exists solely so that delivery-001's gate criterion "anything Part C surfaces beyond the eight known items is either fixed within this delivery **or** escalated to the owner" has a vehicle for its *fixed-here* arm. **If task-002 routes nothing to "absorb", this task is Canceled at creation** -- set `state: Canceled` and record the reason; do not invent scope for it.
- Correct only what task-002 classified as a stale assertion of KI-005's class **and** routed "absorb".
- Bounded to literal-for-derived assertion corrections inside `site/src/data/__tests__/*.ts` and `site/src/lib/__tests__/*.ts`. A real defect in `site/src/lib` or `site/src/data` production code, or any correction larger than one agent session, is escalated to the owner rather than absorbed.
- No production source file is touched. `site/scripts/gen-reference.mjs` remains frozen by REQUIREMENTS section 7.

**Acceptance Criteria:**
- [ ] Every corrected assertion re-derives its expectation from source where a source exists; no literal is swapped for another literal.
- [ ] No file outside `site/src/**/__tests__/` is modified.
- [ ] `npm test` in `site/` exits 0 for the whole suite on a clean `npm ci`.
- [ ] Tests are deterministic with clean setup/teardown, and each corrected suite still covers every acceptance criterion of the feature it was written for -- verified by reading that feature's criteria, not assumed.
- [ ] Anything encountered and not absorbed is written as a named gate escalation in `deliveries/delivery-001/STATE.md`, naming the finding and why it exceeded this task's bound.
- [ ] If task-002 routed nothing to absorb, this task's `state` is `Canceled` with the reason recorded, and no file is modified.
- [ ] All section-6 quality gates pass
