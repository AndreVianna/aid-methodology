# task-001: Wire the content pass

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-003-review-subsystem-redesign -> delivery-016

**Depends on:** --

**Scope:**
- A deep-review dispatch over `.aid/knowledge/kb.html` against the `SUMMARY` rule set
- The whole-document sweep replacing the fixed-size fact spot-check
- The class registry row recording the two review kinds
- The inherited defect the BLUEPRINT names: the *Minimum Grade Thresholds* paragraph's claim about where the bar is configured and what this repository requires. It is left in place deliberately, as the pass's worked example; anyone fixing it corrects the generator source, never the render

**Acceptance Criteria:**
- [ ] The content pass is dispatched and is separate from the machine validators and the human checklist
- [ ] The human checklist question is retained -- the human confirms or extends the agent's rows and adds the verdict no agent can produce
- [ ] The registry states both kinds for this class
- [ ] The pass's ledger carries a row against the *Minimum Grade Thresholds* paragraph, citing the contradiction rule with `.aid/settings.yml` -- the file that paragraph itself points at -- as the winning authority on both halves: the settings key it names and the bar it states are each wrong. No such row means the sweep missed a defect measured before the pass ran, so the pass is not complete
- [ ] All section-6 quality gates pass
