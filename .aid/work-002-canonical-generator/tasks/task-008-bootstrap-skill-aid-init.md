# task-008: Bootstrap `canonical/skills/aid-init/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-init/` from `claude-code/.claude/skills/aid-init/`.
- `aid-init` is mid-complexity (Claude Code SKILL.md = 438 lines per module-map.md Module 3 table). Drift across trees is small (no entry in H1's high-drift list — Claude Code, Codex, Cursor are close in size); the `references/` decomposition pattern is minimal here.
- Files to author:
  - `canonical/skills/aid-init/SKILL.md` (~438 lines).
  - `canonical/skills/aid-init/references/*.md` if any exist on Claude Code.
  - `canonical/skills/aid-init/scripts/*.sh` if any.
- Apply abstract-frontmatter + `{filename_map}` discipline.
- `aid-init` is the install scaffold — pay attention to any literal `CLAUDE.md` / `AGENTS.md` mentions in its body that refer to the per-tool project-context file (Claude Code uses `CLAUDE.md`; Codex and Cursor use `AGENTS.md`). Use the `{project_context_file}` placeholder.
- Verify against Codex (`codex/.agents/skills/aid-init/SKILL.md`) and Cursor (`cursor/.cursor/skills/aid-init/SKILL.md`) for any body content that genuinely diverges (vs. cosmetic frontmatter differences). Resolve to Claude Code by default; flag any non-cosmetic Codex / Cursor content for the maintainer.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-init/SKILL.md` exists with abstract frontmatter and `{project_context_file}` placeholder applied at every mention of `CLAUDE.md`/`AGENTS.md` that refers to the per-tool file.
- [ ] `references/` and `scripts/` siblings carried over verbatim.
- [ ] Body content reconciled against Codex and Cursor — any genuine divergence (not just inlining of `references/`) is enumerated in the execution record with a resolution rationale.
- [ ] FR2-style per-task quick check: a re-render of just this skill via the renderer (once task-020 lands) reproduces the three trees' current `aid-init` SKILL.md bodies modulo frontmatter.
