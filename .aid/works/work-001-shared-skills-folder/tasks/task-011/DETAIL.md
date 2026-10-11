# task-011: Resolve the work-level worktree root from `host.conf` in `worktree-lifecycle.sh`

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-4, AC-8

**Depends on:** task-002

**Scope:**
Per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 9 and § Gap 2. The runtime script has no
PowerShell twin.
- `canonical/aid/scripts/works/worktree-lifecycle.sh`:
  - new read-only operation `root`: prints the absolute path of the work-level worktree container
    and creates the directory if needed;
  - `_worktrees_root_from` reads `worktree_root` from `${main_root}/.aid/runtime/host.conf`,
    falling back to `./.aid/runtime/host.conf`, parsing it as the descriptor format (never sourced);
  - the value is validated with the CLI's rule (`.aid/.worktrees` or `<tool-root>/worktrees`,
    relative, no `..`); absent or invalid -> `.aid/.worktrees` plus exactly one stderr diagnostic;
  - `create` and `locate` use that container; `locate` rung 1 stays branch-keyed, so a worktree
    registered under `.claude/worktrees/` is still found when the root is `.aid/.worktrees/`;
  - the usage header documents `root` and the `host.conf` source.
- `canonical/aid/templates/worktree-lifecycle.md`: describe the host-resolved root (no host path
  written as THE root).
- No `.claude/worktrees` literal remains anywhere in `canonical/`. Work-level folders
  (`work-NNN-*`) and the existing per-task worktrees (`task-NNN`) share `.aid/.worktrees/` without
  colliding, because their names differ.
- Unit cases in `tests/canonical/test-worktree-lifecycle.sh` with hand-written `host.conf`
  fixtures (the CLI-written `host.conf` and `.gitignore` checks are task-022).

**Acceptance Criteria:**
- [ ] `grep -rn '\.claude/worktrees' canonical/aid | wc -l` prints `0` (the `canonical/skills/` occurrences belong to task-001).
- [ ] In a fixture git repo with no `.aid/runtime/host.conf`, `bash canonical/aid/scripts/works/worktree-lifecycle.sh root` prints `<repo>/.aid/.worktrees` (absolute), creates it, and writes one diagnostic line to stderr.
- [ ] With `host.conf` = `worktree_root=.claude/worktrees`, `root` prints `<repo>/.claude/worktrees`; with `worktree_root=../escape`, it prints `<repo>/.aid/.worktrees` plus one stderr diagnostic.
- [ ] With `host.conf` = `worktree_root=.aid/.worktrees`, `create work-001 x` prints a path under `<repo>/.aid/.worktrees/`, and a worktree pre-registered at `.claude/worktrees/work-002-y` on branch `work-002` is returned by `locate work-002` with status `registered`.
- [ ] `bash tests/canonical/test-worktree-lifecycle.sh` exits `0`.
- [ ] All section-6 quality gates pass.
