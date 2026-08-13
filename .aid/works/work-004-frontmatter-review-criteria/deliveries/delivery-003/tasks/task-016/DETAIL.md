# task-016: Exit arithmetic and the C-7 audit

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** DOCUMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-003

**Depends on:** task-013, task-015

*Two same-type close-out verifications are bundled here deliberately (both DOCUMENT, both produced once
at the end, same dependencies). Their acceptance criteria are separate and independently pass/fail, so
the reviewable-unit granularity is preserved without a second task — same-type bundling is permitted, and
splitting for this would proliferate tasks against the work's minimalism.*

**Scope:**
- **Exit arithmetic (AC-4 / NFR-2):** state, as a number, that removed **guard** lines exceed added
  **mechanism** lines. The guard-line floor is **379** (`check-skill-counts.mjs`, if fully deleted per
  task-013); the **1,802** documentation lines from the 20 deleted READMEs are reported **separately**
  and never summed into the guard figure. Authored `review-criteria:` blocks are not "added mechanism".
- **C-7 audit (AC-6):** review `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md`
  (created in delivery-001): every entry passes all six gates; confirm no commit, cherry-pick, or file
  copy from `work-003` appears anywhere in the branch (`git log`, `git diff master...work-004`).

**Acceptance Criteria:**
- [ ] The exit number is stated with guard lines and documentation lines reported separately (never
      merged); removed guard lines exceed added mechanism lines.
- [ ] If task-013 chose "narrow" rather than "full delete", the guard figure is re-derived accordingly.
- [ ] Every `imports-from-work-003.md` entry passes the six C-7 gates; no work-003 commit/cherry-pick/
      copy exists in the branch.
- [ ] Accuracy verified against the current repo state (post-render). All §6 quality gates pass.
