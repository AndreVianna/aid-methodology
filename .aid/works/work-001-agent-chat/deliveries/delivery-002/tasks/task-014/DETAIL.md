# task-014: Roster and connect on the `aid chat` surface

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

**Source:** feature-002-node-and-message-plane -> delivery-002 -> AC-27, AC-28

**Depends on:** task-013

**Scope:**
- Both verbs on both CLI twins, with their exit codes and stderr tokens.
- The agent-facing surface gaining exactly these two verbs and no administrative one.

**Acceptance Criteria:**
- [ ] Both verbs behave identically under Bash and PowerShell; covered by the parity test.
- [ ] A refusal from either exits 8 with its token on stderr.
- [ ] The verbs added are exactly the roster and the connect request; verified by diffing the agent-facing surface against FR-7.3's prohibited list.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
