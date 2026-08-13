# task-007: AC-2 proof harness — writer + reviewer in a disposable worktree

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** TEST

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** task-004, task-005

**Scope:**
- In a **disposable git worktree at the same commit** (`git worktree add` detached + `git worktree
  remove`), never on the work branch and never committed (NFR-1):
  - **Writer direction:** dispatch an agent to edit a typed file without telling it the criteria in the
    prompt; confirm it resolves that type's criteria and complies.
  - **Reviewer direction:** plant a body-vs-`review-criteria` contradiction; run a real review; confirm
    the finding returns citing that criterion's `id`.
- No maintained test is added to the suite; this reuses the `test-dogfood-byte-identity.sh` scratch-tree
  convention scaled to a tree.

**Acceptance Criteria:**
- [ ] Both directions pass in the disposable worktree; the plant is never committed and never on the
      work branch (NFR-1).
- [ ] The reviewer finding cites the planted criterion's `id`.
- [ ] The result is recorded (pass/fail + evidence); no new maintained test file is committed.
- [ ] Tests are deterministic; clean setup/teardown (`git worktree remove`). All §6 quality gates pass.
