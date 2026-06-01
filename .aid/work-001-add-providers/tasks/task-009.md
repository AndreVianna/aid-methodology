# task-009: Author profiles/copilot-cli.toml + profile-local committed AGENTS.md

**Type:** IMPLEMENT

**Source:** feature-002-copilot-cli → delivery-002

**Depends on:** task-004, task-005

**Scope:**
- Author `/home/andre.vianna/projects/AID/profiles/copilot-cli.toml` per SPEC §"Profile Data — `profiles/copilot-cli.toml`". The schema *keys* are fixed by task-005's widening; every concrete value tagged FR1-owned is filled from `provider-mapping.md` (task-004) — do NOT invent any value. Single-root layout modeled on `cursor.toml`. Required content:
  - `[layout]`: `output_root = "profiles/copilot-cli/.github"`; `agents_dir = "agents"` (→ `.github/agents/*.agent.md`); **`skills_dir = "skills"`** (→ `.github/skills/<slug>/SKILL.md` — the native Agent Skills home; this drives the existing `render_skills` folder pass exactly as cursor does, FR1 Q-A); `scripts_dir`/`templates_dir` kept as the bare names `"scripts"`/`"templates"` (SPEC recommendation — keeps emitted location and rewritten link in agreement, avoids touching `rewrite_install_paths`; Q-C). **Leave `recipes_dir` unset** so it takes the schema default `"recipes"` (`aid_profile.py:40`) — recipes emit at `.github/recipes/` as `[data]` via the unconditional `render_recipes` pass (`run_generator.py:45`), exactly like the 3 existing profiles (Q-C). `project_context_file = "AGENTS.md"` (token value).
  - `[agent] format = "copilot-agent"` (FR1 Q-A; binds the `.agent.md` suffix + Copilot frontmatter via task-006); `[agent.frontmatter] required = ["name", "description", "tools", "model"]`, `optional = []` (Q-A — the exact field set; optional Copilot fields omitted).
  - `[skill] decomposition = "references"`; `[skill.frontmatter] required = ["name", "description", "allowed-tools"]`, `optional = ["argument-hint"]`. **No `emit_as` knob** — skills are native Agent Skills emitted as folders by the existing pass (E2 dropped, Q-A).
  - `[model_tiers]` = the FR1 Copilot model strings (Q-E, **simple form**: `large="claude-opus-4.8"`, `medium="claude-sonnet-4.6"`, `small="claude-haiku-4.5"` — slug spelling is the `docs-only-noted` residual, confirm before pinning); `[tool_names]` = `Bash = "shell"` only (Q-F, rest pass through); `[capabilities]` = the 4 FR1-verified flags (Q-G: all true); `[filename_map]` with all 3 required keys (`project_context_file = "AGENTS.md"`, `reviewer_output_file = "STATE.md"`, `open_questions_file = "additional-info.md"`).
  - **No `[mcp]` table** — MCP is `[omit]` (Q-B: repo ships no MCP servers). Add the justifying comment (`# No [mcp] table — MCP is [omit] (Q-B)`). No `mcp-config.json` is emitted.
- Author the profile-local committed context file `/home/andre.vianna/projects/AID/profiles/copilot-cli/AGENTS.md` per SPEC §"Emitted Tree — AGENTS.md" and feature-001 Q-J: authored from the shared ~27-line context template with Copilot-specific paths and KB-import idiom substituted (the same convention codex/cursor follow). This file is **authored, git-committed, NOT emitted, and absent from `emission-manifest.jsonl`** — it must not be produced by any pass and must not appear in any manifest. Do NOT add a canonical context source and do NOT change any existing profile's output. Exact paths/idiom are informed by the FR1 mapping.
- Do NOT run the generator to emit the `.github/` tree, and do NOT touch any render_*.py / run_generator / verify (task-006 owns the engine; the first full render is task-010 TEST). Do NOT write committed emitted artifacts under `profiles/copilot-cli/.github/` in this task — that subtree is produced by task-010's render run.

**Acceptance Criteria:**
- [ ] `profiles/copilot-cli.toml` exists and loads + `validate`s clean: `python .claude/skills/aid-generate/scripts/aid_profile.py --profile profiles/copilot-cli.toml` exits 0 (depends on task-005 schema).
- [ ] Every FR1-owned value (`agent.format = "copilot-agent"`, the `name/description/tools/model` frontmatter set, `[model_tiers]` simple form, `[tool_names]` `Bash→shell`, `[capabilities]` 4 flags, scripts/templates bare home) is sourced from `provider-mapping.md` — no placeholder, no `"..."`, no `TBD` left in the file.
- [ ] `skills_dir = "skills"` is set (native Agent Skills home, drives the existing folder pass); **no `[skill].emit_as`** knob is present; `recipes_dir` is unset (default `"recipes"` → recipes emit as `[data]`); **no `[mcp]` table** is present (a justifying `[omit]` comment is, sourced to Q-B).
- [ ] `profiles/copilot-cli/AGENTS.md` exists as an authored, git-committed file, is produced by no render pass, and is absent from every `emission-manifest.jsonl` (verified in task-010's byte-identical/presence checks).
- [ ] No existing profile (`claude-code`/`codex`/`cursor`) `.toml` or output is modified by this task; no new canonical source is added.
- [ ] All §6 quality gates pass (tool-idiomatic fidelity — values match FR1's verified conventions, no faked primitives; convention-over-infrastructure — pure `[data]` + the committed-context convention).
