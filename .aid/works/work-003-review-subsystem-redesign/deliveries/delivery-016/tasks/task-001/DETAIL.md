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
- The inherited defect the BLUEPRINT names: the *Minimum Grade Thresholds* paragraph's claim about where the bar is configured and what this repository requires. It is left in place deliberately, as the pass's worked example. The remedy is the one the BLUEPRINT prescribes -- **regenerate** `kb.html`, never hand-edit the render. The sentence exists only in the render, not in any generator source (`grep -rln "Minimum Grade Thresholds" canonical/` returns nothing). So the remedy is a regenerate, and the regenerated paragraph is checked against `.aid/settings.yml` itself -- not against any assertion made here about what the KB currently says

**Acceptance Criteria:**
- [ ] The content pass is dispatched and is separate from the machine validators and the human checklist
- [ ] The human checklist question is retained -- the human confirms or extends the agent's rows and adds the verdict no agent can produce
- [ ] The registry states both kinds for this class
- [ ] The pass's ledger carries a row against the *Minimum Grade Thresholds* paragraph, citing the contradiction rule with **the KB** as the winning authority -- `SUMMARY-04`'s own authority, and `.aid/knowledge/quality-gates.md § Minimum-Grade Thresholds` carries both halves: the resolution tiers, which name no `pipeline.` key, and this repository's bar. A row resolved against `.aid/settings.yml` instead is the wrong authority for this class -- `review-rubrics/INDEX.md` routes that file to `SETTINGS`, not `SUMMARY`. No such row means the sweep missed a defect measured before the pass ran, so the pass is not complete
- [ ] All section-6 quality gates pass
