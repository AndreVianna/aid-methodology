# task-007: Bootstrap `canonical/skills/aid-monitor/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-monitor/` and populate it from the **Claude Code tree** (`claude-code/.claude/skills/aid-monitor/`).
- `aid-monitor` is the other **lowest-drift** skill per `tech-debt.md` H1 (identical across all three trees). Pairs naturally with task-006 as the warm-up cluster.
- Files to author:
  - `canonical/skills/aid-monitor/SKILL.md` (242 lines per Claude Code; carried over as-is).
  - `canonical/skills/aid-monitor/references/*.md` if any.
  - `canonical/skills/aid-monitor/scripts/*.sh` if any.
- Apply the same abstract-frontmatter and `{filename_map}` placeholder discipline as task-006.
- Note: `aid-monitor` is the skill flagged in **H7** for missing templates (`MONITOR-STATE.md`, `track-report-template.md`). Those template files are an *adjacent* fix and out of scope here — this task only bootstraps the SKILL.md body. The missing templates will continue to be missing after this task; their fix is tracked separately under H7 (R5 from Q8) and is not blocking the generator cutover.
- Verify against Codex and Cursor — confirm byte-identical bodies per H1 evidence.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-monitor/SKILL.md` exists, ~242 lines, abstract frontmatter.
- [ ] Any `references/` and `scripts/` siblings present on Claude Code carried over.
- [ ] `diff` against Codex and Cursor SKILL.md bodies (frontmatter stripped) shows zero meaningful difference, or differences are documented and resolved.
- [ ] Placeholder substitution applied.
- [ ] The H7 missing-templates concern is acknowledged in the execution record as out-of-scope-but-known.
