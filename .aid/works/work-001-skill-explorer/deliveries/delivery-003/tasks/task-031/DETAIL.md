# task-031: `flow-graph.test.mjs` contract-tier suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-031. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-031/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-030

**Scope:**
- Author the **contract tier** of `site/scripts/__tests__/flow-graph.test.mjs`, over frozen inline markdown fixtures written in the test file itself so they depend on nothing outside it. Task-032 appends the remaining tiers to this same file; the two tasks are a strict sequence.
- Pin: classifier precedence D1-D5; the Advance-clause grammar including every separator and rules 4-10; label truncation; node id assignment; and every validator rule.
- **Rule targeting -- read this before writing the validator group.** V1 through V8 are tested against `validateChart` in `validate.mjs`. **V9 is NOT in `validate.mjs` and must not be looked for there** -- it is enforced in the parser, in `advance.mjs`, at the moment edges are emitted, because the residue it inspects exists only during parsing (owner decision, work `STATE.md` Q3, delivery-003 seam 5). The V9 group therefore drives `advance.mjs` directly and asserts that it **throws**, while the V1-V8 groups drive `validateChart` and assert on its returned `errors`. feature-003's SPEC still says `validateChart` implements V1-V9 and is wrong on that point; task-019 records the delta.

**Acceptance Criteria:**
- [ ] Every fixture is inline in the test file and the tier depends on nothing outside it -- no `canonical/` read, nothing under `.aid/works/`.
- [ ] Each of **V1 through V8** has a case that fails only that rule, driven through `validateChart` and asserted on the returned `errors`.
- [ ] **V9 is tested against `advance.mjs`, not `validateChart`**, and asserts a **throw** carrying V9's stable guard name -- including the KI-008 case, where ` then ` left unrecognised leaves `DONE` named in the residue and unconsumed.
- [ ] The suite asserts that `validateChart` implements exactly eight rules -- a chart that would violate V9 passes `validateChart` cleanly, which is the positive statement of where the boundary now sits.
- [ ] The classifier group pins all five discriminators **and** the precedence order between them, including the `aid-triage`-shaped fixture that carries a `## State Machine` heading, a Dispatch table and inline `## State:` sections at once.
- [ ] The parser group covers every separator in the measured set and rules 4 through 10, including rule 6's marked and unmarked ` then ` arms.
- [ ] Label truncation is asserted at 59, 60 and 61 code points **and** for a single unbroken token with no whitespace boundary, so the hard-cut fallback is exercised.
- [ ] Node ids are asserted to be assigned `n1...nN` by first appearance in source order, and to match the id charset.
- [ ] **No numeric corpus or per-shape count appears** anywhere in the tier.
- [ ] Tests are deterministic with clean setup/teardown.
- [ ] All section-6 quality gates pass
