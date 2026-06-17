# Contributing to AID

AID is an open methodology — it improves through use. If you've run these phases in production and found something that works better, we want it here.

## Repository Structure

Understanding the structure is key to contributing in the right place:

| Directory | Audience | Format | Purpose |
|-----------|----------|--------|---------|
| `skills/` | Humans | README.md | Rich documentation per phase (hand-maintained) |
| `agents/` | Humans | README.md | Rich documentation per agent role (hand-maintained) |
| `canonical/` | Generator | .md / .toml | Single source of truth for all install-tree content |
| `profiles/` | Generator | .toml | Per-tool rendering conventions (one profile per tool) |
| `profiles/claude-code/.claude/` | LLMs | .md (YAML frontmatter) | Generated — Claude Code install tree |
| `profiles/codex/.codex/agents/` | LLMs | .toml | Generated — Codex CLI agent definitions |
| `profiles/codex/.agents/skills/` | LLMs | SKILL.md | Generated — Codex CLI skill files |
| `profiles/cursor/.cursor/` | LLMs | .md / .mdc | Generated — Cursor IDE install tree |
| `templates/` | Both | Markdown | Fill-in templates (canonical source in `canonical/templates/`) |
| `examples/` | Humans | Markdown | Real-world case studies |
| `docs/` | Humans | Markdown | User-facing documentation, including the core methodology document |

**Important:** To update a skill, agent, or template, edit the canonical source under
`canonical/` and run `/generate-profile`. The five install trees (`profiles/claude-code/.claude/`,
`profiles/codex/.codex/` + `profiles/codex/.agents/`, `profiles/cursor/.cursor/`,
`profiles/copilot-cli/.github/`, `profiles/antigravity/.agent/`) are **generated artifacts** —
do not hand-edit them directly. Your changes will be overwritten on the next generator run.
See `canonical/EMISSION-MANIFEST.md` for the deletion safety boundary and
`.claude/skills/generate-profile/SKILL.md` for the full generation pipeline.

**Exception:** The human-readable `skills/` and `agents/` directories at the repo root
are **not** generated — they remain hand-maintained READMEs and must be updated
separately when methodology content changes.

**End-user installation** (not generator): users install AID into their own projects via
`install.sh` (Bash) or `install.ps1` (PowerShell) — not `/generate-profile`.
`/generate-profile` is maintainer-only tooling for regenerating the install trees in this repo.

## What We Accept

### Skill Improvements
- Improved phase instructions based on production experience
- Specialized variants (e.g., aid-discover for monorepos or Python projects)
- Skills for edge cases (multi-repo, microservices, data science)
- **Remember:** Edit `canonical/skills/aid-{phase}/SKILL.md` (and `references/` files if any),
  then run `/generate-profile`. Also update the human `skills/aid-{phase}/README.md` separately.

### Agent Improvements
- Better system prompts, tool constraints, or role definitions
- New agent roles for specialized workflows
- **Remember:** Edit `canonical/agents/aid-{name}/AGENT.md`, then run `/generate-profile`.
  Also update the human `agents/aid-{name}/README.md` separately.

### Improved Templates
- Better KB document templates with more concrete guidance
- New template variants (e.g., task template for data pipeline vs. API tasks)
- Example content that makes templates immediately usable

### Examples
- Anonymized real-world case studies — discovery outputs, task specs, review reports
- Examples from domains not yet covered (mobile, data science, IaC)
- Anti-pattern examples showing what NOT to do and why

### Methodology Feedback
- Phase descriptions that don't match production reality
- Missing feedback loops you've encountered
- Anti-patterns that deserve documenting
- Adoption challenges and how you solved them

### New Tool Formats
- Agent/skill definitions for tools not yet supported (GitHub Copilot CLI, Google Antigravity, etc.)
- Add a new `profiles/{tool-name}.toml` following the existing profile schema, then run `/generate-profile`.
  Claude Code, Codex CLI, and Cursor are already supported.

## What We Don't Accept

- Skills that require specific proprietary services
- Examples with real client data, company names, or identifiable information
- Changes to the core methodology without discussion first (open an issue)

## How to Contribute

1. **Fork the repo** and create a branch: `git checkout -b your-contribution`

2. **For skill/agent improvements:** Edit `canonical/` (the single source of truth), run `/generate-profile` to regenerate all install trees, then update the human README in `skills/` or `agents/`. The human version should be rich and explanatory. The generated LLM versions are concise and structured.

3. **For new templates:** Add to the appropriate `templates/` subdirectory. Include guidance comments explaining *why* each section exists.

4. **For examples:** Add to `examples/` with a `README.md` explaining context. **Anonymize everything.**

5. **For methodology changes:** Open an issue first.

6. **Submit a PR** with:
   - What changed and why
   - What phase(s)/agent(s) this affects
   - Whether this was tested in production

## Style Guide

### Human Documentation (`skills/`, `agents/`)
- Rich explanations, rationale, examples
- No YAML frontmatter
- No token optimization — clarity over brevity
- Markdown tables, diagrams, and examples welcome

### Canonical Files (`canonical/`)
- Concise — these go into context windows after generation
- SKILL.md files: YAML frontmatter with `name`, `description`, `allowed-tools`; `tier: large|medium|small` (abstract)
- Agent files: YAML frontmatter with `name`, `description`, `tools`, `tier` (abstract)
- Under 500 lines per skill (AgentSkills best practice)
- Strip verbose explanations — keep: purpose, inputs, process steps, outputs, checklist
- Generated install trees (`profiles/claude-code/.claude/`, `profiles/codex/`, `profiles/cursor/.cursor/`, `profiles/copilot-cli/.github/`, `profiles/antigravity/.agent/`) are produced by `/generate-profile` — do not edit directly

### General
- **Tone:** Professional and practical. Opinionated. Methodology from someone who ships.
- **Language:** Active voice. Concrete over abstract. "Do X" not "X should be done."
- **No vendor lock-in:** Tool-specific formats go in their directories. Core methodology is tool-agnostic.

## Anonymization Rules

If you're contributing examples from real projects:
- Replace company names with generic descriptions
- Replace team member names with roles
- Replace real URLs with example.com
- Replace real data with representative fake data
- If the client is identifiable from the description, change enough to break the link

## Questions?

Open an issue. We respond.
