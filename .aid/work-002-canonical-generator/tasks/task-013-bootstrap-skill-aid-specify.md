# task-013: Bootstrap `canonical/skills/aid-specify/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-specify/` from `claude-code/.claude/skills/aid-specify/`.
- Heavyweight: Claude Code 413 lines, Codex 485, Cursor 488 (per `tech-debt.md` H1). Two `references/*.md` files per module-map.md:
  - `handling-outcomes.md` (37 lines)
  - `known-issues-scope.md` (52 lines)
- Files to author: `SKILL.md` + both `references/*.md` + any `scripts/` (verify).
- Apply the same drift-resolution methodology as tasks 011–012.
- Apply abstract-frontmatter + `{filename_map}` discipline.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-specify/SKILL.md` (~413 lines) + two `references/*.md` files exist with abstract frontmatter.
- [ ] Drift-resolution log produced.
- [ ] Placeholder substitution applied.
- [ ] FR2-style per-task quick check passes (maintainer review of drift log).
