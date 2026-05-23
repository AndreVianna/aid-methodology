# task-014: Bootstrap `canonical/skills/aid-execute/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-execute/` from `claude-code/.claude/skills/aid-execute/`.
- Heavyweight: Claude Code 386 lines, Codex 558, Cursor 562 (per `tech-debt.md` H1).
- Files to author: `SKILL.md` + any `references/*.md` (module-map.md does not list any for aid-execute on Claude Code — verify directly) + any `scripts/`.
- The skill embeds the 8-type task taxonomy (`RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE` per `architecture.md §2.1` table). The body must use the canonical names verbatim — verify they match `api-contracts.md` (TASK schema with 8-type enum).
- Apply the same drift-resolution methodology as tasks 011–013.
- Apply abstract-frontmatter + `{filename_map}` discipline.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-execute/SKILL.md` (~386 lines) exists with abstract frontmatter; any `references/` and `scripts/` siblings carried over.
- [ ] Drift-resolution log produced. (Codex / Cursor inline ~172 lines of content vs Claude Code — most of that should resolve cleanly to extracted `references/*.md` files; if there is no Claude Code `references/` precedent, the work for this bootstrap includes **deciding how to factor the extra content**: as new canonical `references/*.md` files mirroring the logical sections that Codex / Cursor inline. Record the factoring decision.)
- [ ] The 8-type task taxonomy is preserved verbatim in the body.
- [ ] Placeholder substitution applied.
- [ ] FR2-style per-task quick check passes.
