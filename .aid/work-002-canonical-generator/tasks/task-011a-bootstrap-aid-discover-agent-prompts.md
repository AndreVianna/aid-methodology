# task-011a: Bootstrap `canonical/skills/aid-discover/references/agent-prompts.md`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- One of the three `references/*.md` artifacts split off from task-011's parent. Author **only this file**:
  - `canonical/skills/aid-discover/references/agent-prompts.md` (~142 lines, per module-map.md table).
- Source of truth: `claude-code/.claude/skills/aid-discover/references/agent-prompts.md`.
- **Drift resolution for this reference:**
  - Locate the corresponding inlined block in `codex/.agents/skills/aid-discover/SKILL.md` (grep a distinctive line from the Claude Code reference body to find the start) and the matching block in `cursor/.cursor/skills/aid-discover/SKILL.md`.
  - Diff the Claude Code reference body against the inlined blocks; resolve any non-cosmetic divergence explicitly. Default to Claude Code unless a Codex / Cursor variant carries a fix Claude Code missed.
  - Record an empty log if all divergences were cosmetic (whitespace, line-wrap differences).
- Apply abstract-frontmatter + `{filename_map}` placeholder discipline (this reference describes how sub-agent prompts are constructed — verify any literal `CLAUDE.md` / `AGENTS.md` / `DISCOVERY-STATE.md` substrings are replaced with the placeholders established in task-004).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-discover/references/agent-prompts.md` exists at ~142 lines with placeholder substitution applied.
- [ ] Drift-resolution log enumerates each non-cosmetic divergence between the Claude Code reference and the corresponding inlined Codex / Cursor block (empty log explicitly stated if no genuine divergence).
- [ ] FR2 quick check: a re-render of `aid-discover` post task-020 emits this reference into all three profiles' trees byte-identically (Decision F — externalized, not inlined).
