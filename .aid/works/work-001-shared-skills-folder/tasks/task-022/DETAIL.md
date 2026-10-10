# task-022: End-to-end worktree-root cases with a CLI-written `host.conf`

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

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-8

**Depends on:** task-010, task-011

**Scope:**
- Extend `tests/canonical/test-worktree-lifecycle.sh` with fixtures installed by the CLI (staging
  via `tests/lib/bundle.sh`, `HOME` pinned), so `host.conf` and the `.gitignore` block come from
  the real install path rather than from hand-written files:
  - a cursor-only fixture: the installed `.aid/runtime/scripts/works/worktree-lifecycle.sh create work-001 x`
    prints a path under `.aid/.worktrees/`, and `.aid/.worktrees/` appears in the `.gitignore` AID managed block;
  - the same fixture with a worktree pre-registered at `.claude/worktrees/work-002-y` on branch
    `work-002`: `locate work-002` returns it with status `registered`;
  - a claude-code fixture: `root` prints `<fixture>/.claude/worktrees`, and `.claude/worktrees/`
    appears in the `.gitignore` block.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-worktree-lifecycle.sh --verbose` exits `0`, with `PASS:` lines for the cursor-only `create` path, the cursor-only `.gitignore` entry, the `locate ... registered` case, the claude-code `root` value and the claude-code `.gitignore` entry.
- [ ] The new cases invoke the INSTALLED runtime script under the fixture's `.aid/runtime/`, not `canonical/aid/` (`grep` of the new cases shows the `.aid/runtime/scripts/works/worktree-lifecycle.sh` path).
- [ ] All section-6 quality gates pass.
