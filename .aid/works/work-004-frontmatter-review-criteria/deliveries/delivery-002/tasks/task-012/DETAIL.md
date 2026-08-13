# task-012: AC-2 proof for a populated file

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** TEST

**Source:** work-004-frontmatter-review-criteria -> delivery-002

**Depends on:** task-009, task-010

**Scope:**
- In a **disposable git worktree at the same commit** (NFR-1), never on the work branch, never committed:
  plant a body-vs-`review-criteria` contradiction in a file this delivery **populated** (a file that
  gained a file-level block, or a KB doc whose declaration was corrected), run a real review, and confirm
  the finding returns citing that file's criterion `id`.
- No maintained test is added; reuse the scratch-tree convention.

**Acceptance Criteria:**
- [ ] The planted contradiction is reported by a real review, citing the file's criterion `id`.
- [ ] The plant is never committed and never on the work branch (NFR-1); clean teardown.
- [ ] Result recorded (pass/fail + evidence); no new maintained test committed.
- [ ] Deterministic; all §6 quality gates pass.
