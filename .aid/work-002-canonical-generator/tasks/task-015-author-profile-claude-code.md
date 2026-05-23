# task-015: Author `profiles/claude-code.toml`

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `profiles/claude-code.toml` at the repo root, encoding the Claude Code host tool's conventions per SPEC Data Model §"Profiles" table.
- Extract every field from the existing `claude-code/.claude/` tree and from `coding-standards.md`:
  - `[layout]`: `output_root = "claude-code/.claude"`; `agents_dir = "agents"`; `skills_dir = "skills"`; `templates_dir = "templates"`; `project_context_file = "CLAUDE.md"` (committed at `claude-code/CLAUDE.md`).
  - `[agent]`: `format = "markdown"`; frontmatter schema declaring `name`, `description`, `tools`, `model`, optional `permissionMode`, optional `background` (per `coding-standards.md §2.1` table).
  - `[skill]`: `decomposition = "references"` (Decision F); frontmatter schema declaring `name`, `description`, `allowed-tools`, optional `argument-hint`, plus Claude Code-specific optionals `context` and `agent` (per `coding-standards.md §1.1`).
  - `[model_tiers]`: `large = "opus"`; `medium = "sonnet"`; `small = "haiku"` (per `tech-debt.md` L6 table).
  - `[tool_names]` (abstract → tool-specific): no remapping needed — Claude Code is the abstract baseline (`Bash` stays `Bash`, `Read` stays `Read`, etc.). Declare an empty or identity map.
  - `[filename_map]`: `project_context_file = "CLAUDE.md"`; `reviewer_output_file = "DISCOVERY-STATE.md"`; `open_questions_file = "additional-info.md"` (per `coding-standards.md §2.4` Claude Code column).
  - `[extras]`: any Claude Code-specific additions (e.g. settings.json templates) — verify by inspecting the install tree; declare empty if none.
  - `[capabilities]`: `hooks = true`; `skill_chaining = true`; `background_execution = true`; `stop_hook_autocontinue = true` (verify against host-tools-matrix.md; Claude Code is the most capable tool per the matrix).
- Use TOML conventions consistent with `codex/.codex/agents/*.toml` (the existing TOML in the repo): `key = "value"`; tables in `[brackets]`; arrays of tables in `[[brackets]]` if needed; comments with `#`.
- The profile must be **complete** — every field the renderers (tasks 019–021) and the profile parser (task-018) read must be declared.

**Acceptance Criteria:**
- [ ] `profiles/claude-code.toml` exists and parses cleanly with Python `tomllib` (`python -c "import tomllib; tomllib.load(open('profiles/claude-code.toml', 'rb'))"`).
- [ ] All fields enumerated in the SPEC Data Model table are present (`layout`, `agent.format`, `agent.frontmatter`, `skill.decomposition`, `skill.frontmatter`, `model_tiers`, `tool_names`, `extras`, `capabilities`).
- [ ] `[filename_map]` declares the three keys the canonical bootstrap relies on (`project_context_file`, `reviewer_output_file`, `open_questions_file`).
- [ ] All values cross-verified against `coding-standards.md`, `host-tools-matrix.md`, `tech-debt.md` L6 — citations recorded in the task execution log.
- [ ] Spot-check: emit a single agent (e.g. `architect`) into a scratch directory using a stub renderer or a manual application of the profile's frontmatter schema — the output's frontmatter exactly matches `claude-code/.claude/agents/architect.md:1-6`.
