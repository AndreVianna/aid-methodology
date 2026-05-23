# External Sources

> **Source:** aid-init + discovery-scout enrichment
> **Status:** ⚠️ URLs registered + local cross-reference — web fetch deferred
> **Last Updated:** 2026-05-21

## Registered Sources

The sources below are **web documentation** (not local files). They are official
vendor docs covering how each tool defines agents, skills, hooks (or their
equivalents). `/aid-discover` (discovery-scout) should fetch and cross-reference
them when populating the Knowledge Base — especially `architecture.md`,
`module-map.md`, `coding-standards.md`, and `integration-map.md`.

| # | Source | Type | URL / Entry Point | Scope | Accessible |
|---|--------|------|-------------------|-------|------------|
| 1 | Anthropic — Claude Code | web | https://docs.claude.com/en/docs/claude-code/overview | Agents (sub-agents), Skills, Hooks, Settings, MCP, Plugins | ⚠️ Pending fetch |
| 2 | Anthropic — Claude Agent SDK | web | https://docs.claude.com/en/api/agent-sdk/overview | Programmatic agent definition and tool use | ⚠️ Pending fetch |
| 3 | OpenAI — Codex CLI | web | https://github.com/openai/codex | AGENTS.md format, instruction files, CLI behavior | ⚠️ Pending fetch |
| 4 | OpenAI — Codex docs | web | https://developers.openai.com/codex/ | Official product/developer docs for Codex IDE & CLI | ⚠️ Pending fetch |
| 5 | Cursor — Rules & Agents | web | https://docs.cursor.com/context/rules-for-ai | Project rules, custom modes, agent configuration | ⚠️ Pending fetch |
| 6 | Cursor — MCP & Hooks | web | https://docs.cursor.com/context/model-context-protocol | MCP integration and tool/hook hooks | ⚠️ Pending fetch |
| 7 | GitHub Copilot CLI | web | https://docs.github.com/en/copilot | Copilot CLI, custom instructions, extensions | ⚠️ Pending fetch |
| 8 | Google Antigravity | web | https://antigravity.google/docs | Agents, skills/workflows, and configuration model | ⚠️ Pending fetch (URL to confirm via search) |

## Discovery Notes for `/aid-discover`

When fetching these sources, focus on extracting:

1. **Agent definition format** — frontmatter fields, file location conventions,
   tool-access declarations.
2. **Skills (or equivalents)** — how reusable, user-invocable workflows are
   structured (Claude `.skill/` packages, Cursor rules, Copilot instructions,
   Codex AGENTS.md sections, Antigravity equivalents).
3. **Hooks lifecycle** — events, payload shape, exit-code semantics,
   blocking vs. non-blocking behavior.
4. **Settings/permissions model** — where allow/deny lists live and what
   precedence rules apply.
5. **Cross-tool parity** — note where AID's current Claude Code skills/agents
   have direct equivalents in the other tools, and where they don't.

The findings should feed back into:
- `integration-map.md` — each external tool counts as an integration target.
- `module-map.md` — `.claude/`, `codex/`, `cursor/` source trees per tool.
- `coding-standards.md` — frontmatter conventions for each agent/skill format.
- `architecture.md` — how AID layers on top of each host tool.

---

## Local Cross-Reference — Where Each Vendor's Concepts Live in This Repo

Discovery-scout has mapped each external source to the directory inside this repository where AID's matching install payload lives. This is purely a local cross-reference — no web content has been fetched. Use it as a starting point for downstream agents that need to validate vendor-format conformance.

### 1 & 2 — Anthropic Claude Code + Claude Agent SDK

**Local payload:** `profiles/claude-code/.claude/` (agents, skills, templates) + `profiles/claude-code/CLAUDE.md` (project config placeholder).

**Example files:**
- `profiles/claude-code/.claude/agents/architect.md` — Claude Code agent definition with YAML frontmatter (`name`, `description`, `tools`, `model`). 40 lines.
- `profiles/claude-code/.claude/agents/discovery-reviewer.md` — Larger background-mode agent showing `permissionMode: bypassPermissions` and `background: true` fields. 381 lines.
- `profiles/claude-code/.claude/skills/aid-discover/SKILL.md` — AgentSkills format with `name`, `description`, `allowed-tools`, `argument-hint` frontmatter and a structured body. 453 lines.
- `profiles/claude-code/.claude/skills/aid-interview/references/kb-hydration.md` — `references/` subdirectory pattern used to externalize skill content out of the main SKILL.md body.
- `profiles/claude-code/.claude/templates/scripts/build-project-index.sh` — runtime Bash script consumed by `aid-discover`.
- `.claude/settings.json` (this repo's own) — narrow Bash permission allow-list pattern as understood by Claude Code.

**Covered locally:** agent file format, AgentSkills SKILL.md format including `agents:` selector tables, `references/` and `scripts/` subdirectory patterns, tier mapping (Opus / Sonnet / Haiku), permission allow-list shape in `.claude/settings.json`, and the dispatch idiom whereby a skill calls multiple sub-agents in parallel via the Agent tool.

**Still requires vendor docs:** authoritative list of supported frontmatter fields and any new ones added since the AID code was written; full hook lifecycle and event payload schema; Plugins API; the exact Claude Agent SDK Python / TypeScript surface; MCP server registration semantics; Claude Code-specific behavior of `permissionMode: bypassPermissions` versus `acceptEdits`; long-running `background: true` agent semantics.

### 3 & 4 — OpenAI Codex CLI + Codex docs

**Local payload:** `profiles/codex/.codex/agents/` (TOML agent defs) + `profiles/codex/.agents/{skills,templates}/` (markdown skills + scripts) + `profiles/codex/AGENTS.md` (project config placeholder).

**Example files:**
- `profiles/codex/.codex/agents/architect.toml` — TOML format with `name`, `description`, `developer_instructions`, `model`, `model_reasoning_effort`. 39 lines.
- `profiles/codex/.codex/agents/discovery-reviewer.toml` — Largest agent definition. 314 lines.
- `profiles/codex/.codex/agents/simple-extractor.toml` — Haiku-tier utility agent showing the `gpt-5.4-mini` + `low` reasoning combination.
- `profiles/codex/.agents/skills/aid-discover/SKILL.md` — Inlined skill body (1,078 lines — much longer than the Claude Code equivalent because Codex tree appears to inline what Claude Code factors out into `references/`).
- `profiles/codex/AGENTS.md` — Top-level project context placeholder consumed by Codex CLI. 28 lines.

**Covered locally:** Codex agent TOML schema, model tier mapping (`gpt-5.5` high / `gpt-5.4` medium / `gpt-5.4-mini` low), the AGENTS.md project-context convention, and the deliberate split between `.codex/` (agent defs) and `.agents/` (skills + templates) per `profiles/codex/README.md:12-15`. The May 2026 migration note in `profiles/codex/README.md:35` documents past tier-assignment inconsistencies that have been corrected.

**Still requires vendor docs:** authoritative AGENTS.md schema and any nested override semantics; whether Codex CLI supports skills beyond AGENTS.md sections at all (the AID install ships skills under `.agents/skills/` but it is unclear from local files alone whether Codex CLI reads them); Codex hook lifecycle (if any); confirmation that the `model_reasoning_effort` field is honored by current Codex CLI versions; the exact dispatch mechanism for sub-agents in Codex.

### 5 & 6 — Cursor Rules & Agents + Cursor MCP & Hooks

**Local payload:** `profiles/cursor/.cursor/{rules,agents,skills,templates}/` + `profiles/cursor/AGENTS.md` (project context placeholder).

**Example files:**
- `profiles/cursor/.cursor/rules/aid-methodology.mdc` — Always-on `.mdc` rule with `description` + `alwaysApply: true` frontmatter. 29 lines.
- `profiles/cursor/.cursor/rules/aid-review.mdc` — Glob-scoped `.mdc` rule with `globs: "**/*.{java,py,ts,js,cs,go,rs}"` and `alwaysApply: false`. 11 lines.
- `profiles/cursor/.cursor/agents/architect.md` — Agent definition reused verbatim from the Claude Code shape (Cursor consumes the same markdown + YAML frontmatter).
- `profiles/cursor/.cursor/skills/aid-discover/SKILL.md` — 1,090 lines (longest of the three trees).
- `profiles/cursor/AGENTS.md` — Project context placeholder. 45 lines. Notes that `Task tool is experimental — Mar 2026`.

**Covered locally:** `.mdc` rule format (frontmatter + body), the rules vs. skills distinction (rules = always-on constraints, skills = on-demand workflows per `profiles/cursor/README.md:141`), the AGENTS.md convention shared with Codex, and the cross-tool compatibility note that Cursor also reads skills from `.claude/skills/` and `.codex/skills/` (`profiles/cursor/README.md:142`).

**Still requires vendor docs:** the precise status of Cursor's Task tool for sub-agent dispatch (locally marked experimental as of March 2026 — needs confirmation against current Cursor docs); whether Cursor honors `tools:` and `model:` fields in agent frontmatter the same way Claude Code does; Cursor MCP server registration; Cursor hook events (if any); precedence rules for `.cursor/rules/` versus `AGENTS.md` versus `.cursor/skills/`.

### 7 — GitHub Copilot CLI

**Local payload:** **None.** There is no `copilot/` install tree in this repository.

**References found:**
- `README.md:267` mentions GitHub Copilot as a supported "agent mode with spec context" target.
- `CONTRIBUTING.md:58` lists Copilot among tools "not yet supported" for which agent / skill definitions are accepted.
- `docs/faq.md:28` includes GitHub Copilot in the list of tool-agnostic targets.
- No `.github/`, no `.copilot/`, no `copilot-instructions.md`, no `copilot/` directory anywhere in the tree (verified by `Grep` for `copilot|antigravity` — only the three documentation mentions above).

**Status:** AID treats GitHub Copilot as a future target. Adopters using Copilot would currently have to load AID context manually (the `skills/` READMEs are described in the manual-setup table at `README.md:87` as the fallback). A Copilot install tree would be a meaningful contribution per the CONTRIBUTING guide.

**Still requires vendor docs:** Copilot CLI installation and configuration; the schema for `copilot-instructions.md` (Copilot's equivalent of AGENTS.md); the Copilot Extensions API surface; any sub-agent or skill equivalent; permissions / approval semantics.

### 8 — Google Antigravity

**Local payload:** **None.** There is no `antigravity/` install tree, no rules file, no reference of any kind anywhere in this repository (verified by `Grep`).

**Status:** Antigravity was registered by `/aid-init` as a future-watch source but has zero footprint in the repository. The URL itself is flagged as `to confirm via search` in row 8 of the registered-sources table above.

**Still requires vendor docs:** even the basic shape of Antigravity's agent/skill/workflow model — Antigravity is the source for which AID has the least prior absorbed knowledge. Confirm URL exists, then characterize the configuration model from scratch.

---

### Summary

| Vendor | Local tree | Format reference files | Web fetch still needed for |
|--------|------------|------------------------|----------------------------|
| Anthropic / Claude Code | `profiles/claude-code/.claude/` | agents `*.md`, skills `*/SKILL.md`, templates `templates/`, this repo's `.claude/settings.json` | Hooks, Plugins, MCP registration, current Agent SDK surface, full frontmatter inventory |
| OpenAI / Codex | `profiles/codex/.codex/` + `profiles/codex/.agents/` + `profiles/codex/AGENTS.md` | agents `*.toml`, skills `*/SKILL.md`, AGENTS.md | AGENTS.md authoritative schema, skill-loading behavior, hooks, sub-agent dispatch |
| Cursor | `profiles/cursor/.cursor/` + `profiles/cursor/AGENTS.md` | rules `*.mdc`, agents `*.md`, skills `*/SKILL.md` | Task tool status, MCP / hooks, precedence rules across rules/skills/AGENTS.md |
| GitHub Copilot | (none — future) | — | Everything: CLI install, instructions format, Extensions API |
| Google Antigravity | (none — future, URL unconfirmed) | — | Everything, starting with URL existence |

---

## Trust Model for Web-Fetched Vendor Documentation (per DISCOVERY-STATE Q80)

When AID's discovery agents fetch the 8 registered vendor doc URLs, they operate on the following trust assumptions:

1. **Vendor docs are trusted not to be adversarial.** AID treats `docs.claude.com`, `github.com/openai`, `developers.openai.com`, `docs.cursor.com`, `docs.github.com`, and `antigravity.google` as authoritative origin-of-truth sources for their respective tools' agent / skill / hook formats. The fetched content is allowed to inform downstream KB documents (`api-contracts.md`, `coding-standards.md`, `integration-map.md`).
2. **No per-URL allow-list of expected content patterns** is currently enforced. A compromised CDN, URL hijack, or vendor-site defacement would deliver malicious instructions directly into the AID discovery agent's context window.
3. **Mitigation in place:** discovery-scout and the 4 parallel discovery sub-agents do **not** have `WebFetch` in their tool allow-lists (per `profiles/claude-code/.claude/agents/discovery-*.md` frontmatter). Web content from these URLs reaches the agents only via the orchestrator (the skill itself) including content in the prompt, OR via a future Q&A cycle where the user pastes content. Direct adversarial code execution from a compromised vendor site is therefore bounded by what the orchestrator chooses to include.
4. **Adopter responsibility:** users running AID against their own projects who add additional `external-sources.md` rows are responsible for vouching for those URLs' integrity.

**Future hardening (deferred to v3.x per Q80 resolution):** add a per-URL "expected content patterns" allow-list to `templates/scripts/fetch-vendor-docs.sh` (if such a script is introduced) that rejects fetched content not matching expected markers (e.g., expected H1 headings, expected code-fence languages). Until then, the trust assumption is stated explicitly and adopters can audit.
