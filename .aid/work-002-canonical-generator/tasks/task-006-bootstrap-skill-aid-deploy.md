# task-006: Bootstrap `canonical/skills/aid-deploy/`

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/skills/aid-deploy/` and populate it from the **Claude Code tree** (`claude-code/.claude/skills/aid-deploy/`).
- `aid-deploy` is one of the two **lowest-drift** skills per `tech-debt.md` H1: all three install trees are identical (`aid-deploy/SKILL.md` and `aid-monitor/SKILL.md` are identical across all three trees). Low-risk warm-up before the heavyweight bootstraps.
- Files to author:
  - `canonical/skills/aid-deploy/SKILL.md` (265 lines per Claude Code; carried over as-is).
  - `canonical/skills/aid-deploy/references/*.md` if any exist on Claude Code (verify directory contents; copy whatever is there).
  - `canonical/skills/aid-deploy/scripts/*.sh` if any exist on Claude Code (same).
- SKILL.md frontmatter: same abstract shape as the agent frontmatter — `name`, `description` (YAML folded `>`), `allowed-tools` (comma-separated, abstract names — `Bash` stays as `Bash`; the Cursor profile remaps to `Terminal`), optional `argument-hint`. Do NOT carry Claude Code-only fields (`context: fork`, `agent: <name>`) into the canonical — those are emitted per-profile by the skill renderer.
- Body uses the same `{project_context_file}` / `{reviewer_output_file}` / `{open_questions_file}` placeholders established in task-004 wherever the body mentions per-tool filenames.
- Verify against Codex (`codex/.agents/skills/aid-deploy/SKILL.md`) and Cursor (`cursor/.cursor/skills/aid-deploy/SKILL.md`) — confirm they are byte-identical to the Claude Code source modulo frontmatter (per `tech-debt.md` H1 evidence). Any genuine body divergence must be surfaced and resolved in this task's execution record.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-deploy/SKILL.md` exists, ~265 lines, with abstract frontmatter (no Claude Code-only fields).
- [ ] Any `references/` and `scripts/` siblings present on Claude Code are also present under `canonical/skills/aid-deploy/`.
- [ ] A `diff` of the canonical SKILL.md body against the Codex and Cursor SKILL.md bodies (frontmatter stripped) shows zero meaningful difference, OR any difference is documented in the task execution record with a resolution.
- [ ] Body contains the placeholder substitution (no literal `CLAUDE.md` / `AGENTS.md` where the body refers to the per-tool project-context file).
