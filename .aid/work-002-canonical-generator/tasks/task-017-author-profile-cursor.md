# task-017: Author `profiles/cursor.toml`

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `profiles/cursor.toml`, encoding the Cursor host tool's conventions.
- `[layout]`: `output_root = "cursor/.cursor"`; `agents_dir = "agents"`; `skills_dir = "skills"`; `templates_dir = "templates"`; `rules_dir = "rules"` (Cursor-specific — `.mdc` rule files per `coding-standards.md §3`); `project_context_file = "AGENTS.md"` (committed at `cursor/AGENTS.md`).
- `[agent]`: `format = "markdown"` (same as Claude Code); frontmatter schema same shape as Claude Code per `coding-standards.md §2.3`.
- `[skill]`: `decomposition = "references"` (Decision F); frontmatter schema same as Claude Code minus `context:` / `agent:` per `coding-standards.md §1.1`.
- `[model_tiers]`: same enum names as Claude Code — Cursor uses Anthropic models (`opus` / `sonnet` / `haiku`) per `tech-debt.md` L6 verification.
- `[tool_names]`: **must remap** `Bash → Terminal` per `coding-standards.md §2.3` and `tech-debt.md` M6 / Q52. This is the one non-identity entry in any profile's `tool_names`. Declare `[tool_names] Bash = "Terminal"` and confirm no other tool-name divergences exist (cross-check the canonical agents' `tools:` declarations).
- `[filename_map]`: `project_context_file = "AGENTS.md"`; `reviewer_output_file = "DISCOVERY-STATE.md"`; `open_questions_file = "additional-info.md"` (Cursor uses the canonical names per `coding-standards.md §2.4`).
- `[extras]`: declare the `rules/` extra — Cursor has `.mdc` rule files (`cursor/.cursor/rules/aid-methodology.mdc`, `cursor/.cursor/rules/aid-review.mdc` per `coding-standards.md §3`). The skill renderer (or a Cursor-specific extras renderer) needs to emit these. Note their schema: `description`, `globs`, `alwaysApply`.
- `[capabilities]`: per `host-tools-matrix.md` — `hooks = true` (Cursor's `.cursor/hooks.json` is beta per PLAN task 4 note); `skill_chaining = true`; `background_execution = false` (verify); `stop_hook_autocontinue = false`. Same TODO discipline as task-016 for any unconfirmed value.

**Acceptance Criteria:**
- [ ] `profiles/cursor.toml` exists and parses cleanly with `tomllib`.
- [ ] All SPEC Data Model fields present, plus the Cursor-specific `rules_dir` under `[layout]` and the `.mdc` schema under `[extras]`.
- [ ] `[tool_names]` declares `Bash = "Terminal"` and nothing else.
- [ ] Capability values either confirmed or explicitly flagged for VERIFY-4b.
- [ ] Spot-check: emit one agent through a stub renderer — `tools:` in the output has `Terminal` instead of `Bash`; frontmatter matches `cursor/.cursor/agents/architect.md:1-7`.
