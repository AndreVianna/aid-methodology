# task-002: aid-screener

> **Execution protocol (binding on whoever executes this task -- no exceptions):** the moment
> this task's `State` changes, write it -- `In Progress` before starting work, `In Review` before
> dispatching the reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally whether the
> main/orchestrator agent executes this task directly or dispatches it to a sub-agent; neither may
> skip, batch, or defer these writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- never self-written by the task being
> executed.) Full mandate: `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-003-review-subsystem-redesign -> delivery-010

**Depends on:** task-001

**Scope:**
- `canonical/agents/aid-screener/{AGENT.md,README.md}`: small tier, `Read, Glob, Grep`, no `Bash`, no write tools
- A counter-instruction body: one pass, first instance of a class, stop at the floor, a clean screen is not an all-clear
- The include of the shared boilerplate only -- never the discipline block

**Acceptance Criteria:**
- [ ] Re-rendering produces additions on the screener's paths and nothing else
- [ ] The rendered body grants `Read, Glob, Grep` and not `Bash`, in every tree
- [ ] The screener does **not** carry the exhaustiveness mandate while `aid-reviewer` does -- a difference that must exist in every tree
- [ ] The Codex TOML render parses
- [ ] All section-6 quality gates pass
