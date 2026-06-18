# task-014: Reader test fixtures — hierarchy, legacy, multi-worktree, reconcile

**Type:** TEST

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-009, task-010, task-011, task-013

**Scope:**
- Add reader test fixtures + assertions (both twins) covering:
  - a hierarchical work (delivery/task folders with per-unit STATE.md/SPEC.md) → derived `## Tasks State` + Pipeline State correct;
  - a work with TWO deliveries where one is `Pending-Spec` with ZERO tasks while the sibling delivery's tasks are `In Progress` (the SD-9 SPIKE-defines-sibling scenario) → both deliveries render with their authored lifecycle state, no shared-file write, derived work view union-correct;
  - a hierarchical work whose two deliveries each carry their own `## Cross-phase Q&A` → the derived work-level `## Cross-phase Q&A` is the union (no conflict);
  - a legacy monolithic work → inline-table fallback still parses;
  - a repo with BOTH vintages → both render;
  - a multi-worktree repo (a `git worktree list --porcelain` fixture or a stubbed git runner) → works under each worktree are aggregated and labeled by branch;
  - same-work-on-N-roots → reconcile yields most-advanced State (exercise each SD-2 rank boundary, incl. Blocked vs Failed vs Pending) + newest-`Updated:` Pipeline State;
  - git-unavailable / non-git → degrade to main root only.
- Update any existing reader fixtures that assumed the monolithic-only layout.

**Acceptance Criteria:**
- [ ] Fixtures + assertions exist for hierarchical, legacy, mixed-vintage, multi-worktree, reconcile (all SD-2 boundaries), the SD-9 zero-task `Pending-Spec` delivery alongside an in-flight sibling, per-delivery Q&A union, and git-degrade cases.
- [ ] Tests run under both reader twins and pass; existing reader tests updated as needed.
- [ ] Tests are deterministic (git stubbed/fixtured; no dependence on the developer's real worktrees) and HOME-pinned where they touch scan/migration behavior.
- [ ] All §6 quality gates pass.
