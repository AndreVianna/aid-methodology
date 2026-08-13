# task-017: AC-2 proof for a removed check's defect class

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** TEST

**Source:** work-004-frontmatter-review-criteria -> delivery-003

**Depends on:** task-013

**Scope:**
- In a **disposable git worktree at the same commit** (NFR-1), never on the work branch, never committed:
  plant a defect of the class a **removed** check used to catch (e.g. a stale count of the kind
  `check-skill-counts.mjs` caught), and confirm a real review reports it **via the declaration that
  replaced it** — not via the deleted script.
- A removal whose replacement cannot catch the defect is a regression, not a retirement.

**Acceptance Criteria:**
- [ ] The planted defect is reported by a real review through the replacing declaration.
- [ ] The plant is never committed and never on the work branch (NFR-1); clean teardown.
- [ ] Result recorded (pass/fail + evidence); no new maintained test committed.
- [ ] Deterministic; all §6 quality gates pass.
