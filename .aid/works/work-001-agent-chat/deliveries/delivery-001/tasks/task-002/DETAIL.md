# task-002: Store schema and `node:sqlite` open with the warning suppressed narrowly

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-10, AC-22

**Depends on:** task-001

**Scope:**
- The schema exactly as Feature 002 specifies: `session`, `channel`, `message`; `AUTOINCREMENT` on every surrogate key; `message`'s three uniqueness constraints; both indices.
- `channel.next_seq` defaulting to **1** and both positions defaulting to **0** -- the pairing that keeps the first message of a channel reachable.
- Open through the built-in SQLite module, with the store file under the per-user state home.
- Suppress the `ExperimentalWarning` for **that one message on that runtime range** and nothing else.

**Acceptance Criteria:**
- [ ] Every surrogate key is declared `AUTOINCREMENT`; verified by reading the schema back and asserting no bare rowid alias remains.
- [ ] Deleting a row then inserting a new one yields a strictly higher id, on `session`, `channel` and `message` -- the reaped-id-reuse defect cannot recur.
- [ ] The first message inserted into a fresh channel has `arrival_seq` 1, and a member at position 0 receives it under `arrival_seq > delivered_seq`.
- [ ] Starting on a runtime in the affected range produces **no** `ExperimentalWarning` on stderr, while an unrelated experimental warning still reaches the operator.
- [ ] Unit tests for all new public methods; all existing tests still pass; build passes.
- [ ] All section-6 quality gates pass
