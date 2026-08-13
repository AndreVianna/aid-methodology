# task-014: Bring the front face current — docs, root README, examples

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-003

**Depends on:** -- (none within delivery-003; delivery-002 must be complete)

**Scope:**
- Update the user-facing front face to describe the trees as they now are, after streams 1–2:
  `docs/*.md` (7), the repo-root `README.md` (257 lines), and `examples/**/README.md` (4 files).
- All four `examples/` READMEs stay (all referenced — `greenfield`/`brownfield-full-path` via directory
  links in `examples/README.md` and `docs/repository-structure.md`).
- Edit `docs/*.md` as **source**; `site/src/content/docs` is regenerated in task-015, not hand-edited.

**Acceptance Criteria:**
- [ ] `docs/`, root `README.md` and `examples/**/README.md` describe the current trees (skill counts,
      the criteria mechanism, the removed READMEs).
- [ ] No `examples/` README is deleted; all four remain and resolve.
- [ ] Only `docs/*.md` sources are edited here; the synced `site/src/content/docs` copies are left for
      task-015's render.
- [ ] All §6 quality gates pass.
