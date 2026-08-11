# task-001: class-sweep.sh

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

**Source:** work-003-review-subsystem-redesign -> delivery-025

**Depends on:** -- (none)

**Scope:**
- `canonical/aid/scripts/review/class-sweep.sh`: takes `--phrase` and `--root`, prints every site the phrase appears at
- Its exit and output contract, following the conventions of the scripts already in `review/`

**Acceptance Criteria:**
- [ ] Given a phrase and a root, every site containing the phrase is printed, one per line, path first
- [ ] A phrase that appears nowhere prints no sites and does not fail -- an empty sweep is a result, not an error
- [ ] The script judges nothing: it reports sites and says nothing about whether a site should change
- [ ] It follows the temp-file and error-handling conventions `coding-standards.md § Shell (Bash) Conventions` declares
- [ ] All section-6 quality gates pass
