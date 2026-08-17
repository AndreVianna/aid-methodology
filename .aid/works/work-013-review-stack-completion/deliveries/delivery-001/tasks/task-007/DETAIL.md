# task-007: review-path-audit.sh — the four-layer single-path audit

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-001

**Scope:**
- New `scripts/checks/review-path-audit.sh` implementing four layers: singleton directories, the review-family lexicon, slash-reference resolution, and agent-reference resolution.
- Bash and awk only, `LC_ALL=C` for byte-stable ordering, no network and no clock dependency.
- A header block citing the measured re-derivation it removes, per the file-header convention in `coding-standards.md`.

**Acceptance Criteria:**
- [ ] The script prints each layer's measurement beside its expectation, then `RESULT PASS` and exits `0` on the current tree.
- [ ] It cannot pass vacuously: extracting zero references, or finding zero review-family references, is a VIOLATION rather than a pass.
- [ ] The lexicon layer covers `review`, `reviewer`, `screener`, `critique`, `audit`, `inspect`, `verif`, `grade` and `rubric` outside the sanctioned `aid-review` / `aid-reviewer` pair — this is the guard the `*review*` glob is not.
- [ ] The header's cited re-derivation reproduces the naive `7` versus guarded `1` dangling-reference figures when re-run.
- [ ] Two consecutive runs produce byte-identical output.
- [ ] All section-6 quality gates pass
