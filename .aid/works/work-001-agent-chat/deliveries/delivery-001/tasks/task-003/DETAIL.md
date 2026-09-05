# task-003: Node lifecycle and the operator's start, stop and status

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-9, AC-22

**Depends on:** task-002

**Scope:**
- The node starts from the shipped payload with nothing fetched, resolved, verified or installed.
- It runs as a background service that outlives the session which started it.
- `start` / `stop` / `status`; loopback bind only at this stage.
- The runtime prerequisite checked **before any side effect**, with an explicit actionable error and never a stack trace.
- FR-1.1's named sub-decision resolved and recorded: whether `start` absorbs already-running as success or keeps a distinct code.

**Acceptance Criteria:**
- [ ] On a machine where `aid` is installed and the node has never run, `start` succeeds **with the network disabled** -- proving nothing is fetched.
- [ ] Running `start` again does not fail with an unhandled error, and behaves as the recorded sub-decision states.
- [ ] With no usable Node runtime present, `start` fails with a message naming Node as the prerequisite and no stack trace, and every `aid` command needing no runtime still works.
- [ ] The node survives exit of the shell that started it; verified by starting it, exiting, and querying status from a new shell.
- [ ] The listening socket is bound to 127.0.0.1 only; verified by socket listing.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
