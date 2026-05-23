# task-019: Write the agent renderer

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-004, task-018, task-022

**Scope:**
- Author `.claude/skills/aid-generate/scripts/render_agents.py`.
- Input: `canonical/agents/*.md` + one `Profile` (loaded via `profile.py`) + the `EmissionManifest` (from `harness.py`).
- Output: per the profile's `[agent]` table — either markdown files (Claude Code, Cursor) under `{output_root}/{agents_dir}/{name}.md`, OR TOML files (Codex) under `{agents_root}/agents/{name}.toml`.
- Transformations per profile:
  - **Frontmatter rewriting** — read the canonical abstract frontmatter (`name`, `description`, `tier`, `tools`, optional `permissionMode`, optional `background`), emit per the profile's `agent.frontmatter` schema:
    - For markdown profiles: `model:` maps from `tier` via `model_tiers` (`large → opus`); `tools:` maps via `tool_names` (Cursor: `Bash → Terminal`).
    - For the Codex TOML profile: emit `name`, `description`, `model`, `model_reasoning_effort` (both from the `[model_tiers]` table for the tier); the markdown body becomes `developer_instructions = """..."""` per `coding-standards.md §2.2`.
  - **Body substitution** — apply `substitute_filenames()` with the profile's `filename_map`.
  - **Path discipline** — output paths are exactly the locations the existing install trees use today (so the generator can be diffed against the current trees during bootstrap verification in task-026).
- Determinism — iterate `canonical/agents/` in sorted order; emit in sorted order; no timestamps.
- Each emitted file is recorded in the `EmissionManifest` with `{profile, src, dst, sha256}` per task-003.

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/render_agents.py` exists; compiles; runs end-to-end against `canonical/agents/` + each of the three profiles.
- [ ] For each profile, the renderer emits 22 files (the 22-agent count from `architecture.md`) into the expected per-profile location.
- [ ] Spot-checks: the rendered `architect.md` (Claude Code) is byte-identical to the current `claude-code/.claude/agents/architect.md` modulo any abstract→concrete substitution that was actually applied; the rendered `architect.toml` (Codex) is byte-identical to the current `codex/.codex/agents/architect.toml`; the rendered `architect.md` (Cursor) has `Terminal` in `tools:` per the M6 fix.
- [ ] Two consecutive renders into separate scratch directories produce byte-identical output trees (AC2 hard gate at the per-renderer level).
- [ ] The `EmissionManifest` records every emitted file with a valid sha256.
