# task-016: Author `profiles/codex.toml`

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `profiles/codex.toml`, encoding the Codex CLI host tool's conventions.
- Codex has a **split layout** unique among the three tools (per `coding-standards.md §8` "Codex split" row): `.codex/` for agent TOML files; `.agents/` for skills and templates.
  - `[layout]`: `output_root` here is **two roots** — declare them as `agents_root = "codex/.codex"` and `assets_root = "codex/.agents"` so the renderer can place agents under `codex/.codex/agents/` and everything else under `codex/.agents/{skills,templates}/`. Plus `project_context_file = "AGENTS.md"` (committed at `codex/AGENTS.md`).
- `[agent]`: `format = "toml"`; frontmatter schema declaring `name`, `description`, `model`, `model_reasoning_effort`, `developer_instructions` (the triple-quoted body wrapper) per `coding-standards.md §2.2`.
- `[skill]`: `decomposition = "references"` (Decision F — Codex now also externalizes references, eliminating the inlining that produced the 1,078-line bloat); frontmatter schema declaring `name`, `description`, `allowed-tools`, optional `argument-hint` (no `context:` / `agent:` per `coding-standards.md §1.1`).
- `[model_tiers]`: `large = { model = "gpt-5.5", reasoning_effort = "high" }`; `medium = { model = "gpt-5.4", reasoning_effort = "medium" }`; `small = { model = "gpt-5.4-mini", reasoning_effort = "low" }` (per `tech-debt.md` L6 table, post-May 2026 migration).
- `[tool_names]`: identity (Codex uses the same `Bash`, `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Agent` names as Claude Code per `coding-standards.md §1.1`). Declare empty / identity.
- `[filename_map]`: `project_context_file = "AGENTS.md"`; `reviewer_output_file = "DISCOVERY-STATE.md"` (NOT `DISCOVERY-GRADE.md` — per R12 / Q30 in `tech-debt.md`, the Codex variant is being standardized to the Claude Code / Cursor canonical names); `open_questions_file = "additional-info.md"` (same standardization).
- `[extras]`: any Codex-specific files (verify; `codex/.codex/` may carry a `developer.toml` or settings; declare what the install tree currently contains).
- `[capabilities]`: per `host-tools-matrix.md` — verify each flag against the Codex CLI's current support; consult `external-sources.md` for the Codex doc URL. Reasonable starting values: `hooks = false` (Codex CLI hooks support not confirmed); `skill_chaining = true` (Codex supports skills); `background_execution = false` (Codex agents do not run as background processes); `stop_hook_autocontinue = false`. These are placeholders the maintainer can adjust in this same task with confirming evidence.

**Acceptance Criteria:**
- [ ] `profiles/codex.toml` exists and parses cleanly with `tomllib`.
- [ ] All SPEC Data Model fields present; `[layout]` correctly carries the **two-root** split (`agents_root` + `assets_root`).
- [ ] Agent frontmatter schema declares Codex's TOML-specific fields (`model_reasoning_effort`, `developer_instructions`).
- [ ] `[filename_map]` standardizes on the canonical names per R12 (no `DISCOVERY-GRADE.md`).
- [ ] Capability values either confirmed against vendor docs (cited in the task execution log) or explicitly flagged as `# TODO: confirm against vendor doc` for the VERIFY-4b advisory pass to surface.
- [ ] Spot-check: emit one agent through a stub renderer — frontmatter matches `codex/.codex/agents/architect.toml:1-4` shape.
