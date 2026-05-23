# task-010: Bootstrap `canonical/skills/aid-plan/` and `canonical/skills/aid-detail/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-plan/` and `canonical/skills/aid-detail/` from the Claude Code tree.
- Bundled into one task because both are **low-drift** (`tech-debt.md` H1: `aid-plan` Claude Code 336 vs Codex 332 lines — 4-line drift; `aid-detail` Claude Code vs Codex 5-line drift, Claude Code vs Cursor 0-line drift). Mid-sized, similar shape, can be reconciled in one focused work session.
- For each skill, author:
  - `canonical/skills/aid-{plan|detail}/SKILL.md`.
  - `canonical/skills/aid-{plan|detail}/references/*.md` if any.
  - `canonical/skills/aid-{plan|detail}/scripts/*.sh` if any.
- Apply abstract-frontmatter + `{filename_map}` discipline.
- Reconcile the 4–5 line drifts: spot-diff the three install trees' SKILL.md bodies (e.g. `diff claude-code/.claude/skills/aid-plan/SKILL.md codex/.agents/skills/aid-plan/SKILL.md`). The drifts are likely cosmetic (frontmatter field ordering, blank-line differences) but resolve each one explicitly and record the resolution.
- Special note on `aid-detail`: this is the skill the user just invoked to produce this very task file. It writes individual `task-NNN.md` files into a `.aid/work-{id}/tasks/` directory per the template at `templates/delivery-plans/task-template.md`. Make sure the canonical body references the template path through the canonical-relative form.

**Acceptance Criteria:**
- [ ] Both `canonical/skills/aid-plan/SKILL.md` and `canonical/skills/aid-detail/SKILL.md` exist with abstract frontmatter.
- [ ] `references/` and `scripts/` siblings (if any) carried over for both.
- [ ] The 4–5 line drift between trees is reconciled explicitly per skill; the resolution is documented in the execution record (per the FR2-style per-task quick check pattern).
- [ ] Placeholder substitution applied.
- [ ] Re-render verification (post task-020): rendering both skills reproduces the current install-tree bodies modulo frontmatter and the documented drift fixes.
