# task-004: Bootstrap `canonical/agents/` from the Claude Code tree

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Create `canonical/agents/` at the repo root.
- For each of the 22 agents in `claude-code/.claude/agents/*.md` (7 Core + 6 Specialist + 3 Utility + 6 Discovery sub-agents per `architecture.md`), extract the tool-agnostic agent definition into `canonical/agents/{name}.md`.
- The canonical agent file carries an **abstract frontmatter** — the fields common to all three trees, with the tool-specific bits (`model:` enum values, `tools:` token names) expressed at an abstract level the renderers map to per-tool values:
  - `name` (kebab-case, unchanged).
  - `description` (single line OR YAML folded block — preserve whichever the Claude Code source uses).
  - `tier` (abstract: `large` | `medium` | `small` — mapped per profile's `model_tiers` table; Claude Code Opus → `large`, Sonnet → `medium`, Haiku → `small`; tier source is `tech-debt.md` L6 table).
  - `tools` (comma-separated, using abstract names — keep `Bash` as the abstract name; the Cursor profile remaps to `Terminal` per coding-standards.md / Q52 / M6).
  - `permissionMode` (optional, only when present on Claude Code source).
  - `background` (optional, only when present on Claude Code source).
- The body is copied **verbatim** from the Claude Code agent file (no rewording). The Codex `developer_instructions = """..."""` body is the same markdown, just wrapped — confirm a 3-agent spot check against Codex agents shows no body drift beyond the wrapping.
- Do NOT touch the existing install trees in this task. The renderers (tasks 019–021) will eventually re-emit them; this task only authors the canonical source.
- File-path discipline: `canonical/agents/{name}.md`, kebab-case slug equals the `name` frontmatter value.
- Cross-check against the per-tool divergence table in `coding-standards.md §2.4` — `CLAUDE.md` vs `AGENTS.md`, `DISCOVERY-STATE.md` vs `DISCOVERY-GRADE.md`, `additional-info.md` vs `open-questions.md`. The canonical body uses the Claude Code / Cursor names (`CLAUDE.md` for the project-context file is a renderer concern handled per-profile — but the body text mentions the file by name; the canonical body uses **placeholders** like `{project_context_file}` where the per-tool filename matters, OR — simpler — the canonical body uses the Claude Code names and the profile declares a per-tool substitution map under a new `filename_map` field, applied by the agent renderer. **Pick the simpler path: write `{project_context_file}` / `{reviewer_output_file}` / `{open_questions_file}` placeholders in the canonical body, and declare those three keys in each profile's `filename_map`.**

**Acceptance Criteria:**
- [ ] `canonical/agents/*.md` contains 22 files, one per agent named in `coding-standards.md §2` / `module-map.md`.
- [ ] Every canonical agent file has frontmatter with the abstract fields: `name`, `description`, `tier`, `tools`, plus optional `permissionMode` and `background` only where the Claude Code source carries them.
- [ ] Every canonical agent body uses the three filename placeholders (`{project_context_file}`, `{reviewer_output_file}`, `{open_questions_file}`) instead of literal `CLAUDE.md` / `AGENTS.md` / `DISCOVERY-STATE.md` / `DISCOVERY-GRADE.md` / `additional-info.md` / `open-questions.md` strings — at least the discovery-reviewer agent's body shows these substitutions.
- [ ] Spot-check three agents (one Opus tier, one Sonnet tier, one Haiku tier — e.g. `architect`, `developer`, `simple-extractor`) — the canonical body equals the Claude Code body modulo the three filename placeholders.
- [ ] The 22 tier assignments match the `tech-debt.md` L6 table (all agents tier-consistent across trees — preserved here).
