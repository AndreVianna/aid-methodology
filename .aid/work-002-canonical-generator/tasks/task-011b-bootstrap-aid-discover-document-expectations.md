# task-011b: Bootstrap `canonical/skills/aid-discover/references/document-expectations.md`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- One of the three `references/*.md` artifacts split off from task-011's parent. Author **only this file**:
  - `canonical/skills/aid-discover/references/document-expectations.md` (~121 lines, per module-map.md table).
- Source of truth: `claude-code/.claude/skills/aid-discover/references/document-expectations.md`.
- **Drift resolution for this reference:**
  - Locate the corresponding inlined block in `codex/.agents/skills/aid-discover/SKILL.md` and `cursor/.cursor/skills/aid-discover/SKILL.md` using a grep on a distinctive line from the Claude Code reference body.
  - Diff against the inlined blocks; resolve non-cosmetic divergence explicitly. Default to Claude Code unless Codex / Cursor carries a fix Claude Code missed.
  - Record an empty log if all divergences were cosmetic.
- Apply abstract-frontmatter + `{filename_map}` placeholder discipline. This file describes the expected shape of KB documents — any literal `CLAUDE.md` / `AGENTS.md` references must use `{project_context_file}` where they refer to the per-tool file.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-discover/references/document-expectations.md` exists at ~121 lines with placeholder substitution applied.
- [ ] Drift-resolution log enumerates each non-cosmetic divergence (empty log explicitly stated if none).
- [ ] FR2 quick check: a re-render of `aid-discover` post task-020 emits this reference into all three profiles' trees byte-identically.
