# task-009: Render the two artifact sets in the six reviewer briefs

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml.

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

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-008

**Scope:**
- The six `canonical/skills/{aid-define,aid-detail,aid-discover,aid-execute,aid-plan,aid-specify}/references/reviewer-brief.md` files.
- Each renders the verification set and the hunt set as two labelled lists on cycles >= 2, and the single unlabelled list on cycle 1 and the final pass.
- Authored instruction only.

**Acceptance Criteria:**
- [ ] All six briefs render both sets, with the cycle-1 and final-pass shapes unchanged
- [ ] Each brief's existing 5-section structure is preserved; no section is added or removed
- [ ] The OUT-OF-SCOPE FINDINGS POLICY text stays identical across all six, as the dispatch protocol requires
- [ ] No script, validator, gate or CI step is added
- [ ] All REQUIREMENTS.md §6 quality gates pass
