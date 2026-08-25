# task-013: Frontmatter lint wired at GENERATE and citation lint added to CI

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

**Depends on:** task-009

**Scope:**
- `canonical/skills/aid-discover/references/state-generate.md`: run `lint-frontmatter.sh` in the GENERATE step beside the citation lint, under the same exit contract, re-dispatch behaviour and round cap.
- `.github/workflows/test.yml`: add a `kb-citation-lint.sh` step, which CI does not run today.
- Correct the enforcement-table claim that treats the two lints as symmetric when each has the opposite hole.

**Acceptance Criteria:**
- [ ] `grep -c 'lint-frontmatter' canonical/skills/aid-discover/references/state-generate.md` returns at least `2`, measured at `1` before, with the new hit inside the step's command block rather than in prose.
- [ ] `grep -rn kb-citation-lint .github/ | wc -l` returns at least `1`, measured at `0` before.
- [ ] The generator is re-run in the same commit and the render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
