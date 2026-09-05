# task-023: Peer registry and discovery

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

**Source:** feature-004-lan-federation -> delivery-004 -> AC-4

**Depends on:** task-022

**Scope:**
- The `peer` table, and CLI verbs to add and list peers.
- **The guaranteed path** -- a static peer list plus heartbeat -- depending on no network feature.
- Zero-configuration discovery layered **above** it as best-effort, carrying no criterion and never load-bearing.

**Acceptance Criteria:**
- [ ] Two machines on a network that blocks broadcast and multicast find each other by the guaranteed path alone.
- [ ] On a network that permits it they also find each other with no configuration; recorded as best-effort and not gating.
- [ ] Disabling the best-effort layer entirely leaves `AC-4` passing; verified by running the criterion with it switched off.
- [ ] Unit tests for every new public function or endpoint this task adds.
- [ ] All existing tests still pass.
- [ ] Build passes.
- [ ] All section-6 quality gates pass
