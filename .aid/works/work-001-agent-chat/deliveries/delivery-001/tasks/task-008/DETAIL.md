# task-008: `aid chat` CLI twins, exit codes and stderr tokens

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-6, AC-9

**Depends on:** task-007

**Scope:**
- `aid chat` in both `bin/aid` and `bin/aid.ps1`, behaviourally equivalent.
- One HTTP call per verb into the one core; **no rule and no SQL** in either CLI.
- The exit-code map including `8` for a well-formed request the node refused; the stable stderr token table.
- stdout carries the result, stderr the diagnostics -- the repository's existing split.

**Acceptance Criteria:**
- [ ] Every `aid chat` verb behaves identically under Bash and PowerShell; verified by extending the repository's existing CLI parity test to the new verbs.
- [ ] A refusal exits 8 with its stable token first on stderr; a usage error exits 2; a runtime failure exits 1.
- [ ] stdout carries only the result; verified by piping stdout alone into a parser and asserting it parses.
- [ ] Neither CLI reimplements node behaviour; verified by grepping both for SQL and for route construction beyond the single call site.
- [ ] Unit tests; all existing tests pass; build passes.
- [ ] All section-6 quality gates pass
