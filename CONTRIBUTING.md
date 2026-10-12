# Contributing to AID

AID is an open methodology — it improves through use. If you've run these phases in production and found something that works better, we want it here.

## Repository Structure

Understanding the structure is key to contributing in the right place:

| Directory | Audience | Format | Purpose |
|-----------|----------|--------|---------|
| `canonical/` | Generator | .md / .toml | Single source of truth for all shipped content: skills (`canonical/skills/`), agents (`canonical/agents/`), runtime and templates (`canonical/aid/`) |
| `profiles/*.toml` | Generator | .toml | Per-tool rendering conventions (one profile per tool) |
| `profiles/<tool>/` | LLMs | .md / .toml | Generated — one tool's rendered agents plus its `aid-tool.conf` (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`) |
| `examples/` | Humans | Markdown | Real-world case studies |
| `docs/` | Humans | Markdown | User-facing documentation, including the core methodology document |

**Important:** To update a skill, agent, or template, edit the canonical source under
`canonical/` and run `/generate-profile`. The five `profiles/<tool>/` trees hold only generated
agents and each tool's `aid-tool.conf`; they are **generated artifacts** — do not hand-edit them
directly. Your changes will be overwritten on the next generator run. Skills and runtime are not
in `profiles/`: they ship once, as one shared payload, installed to `.agents/skills/` and
`.aid/runtime/`. See `.aid/knowledge/architecture.md` (Invariants, *Deletion boundary*) for the
deletion safety boundary and `.claude/skills/generate-profile/SKILL.md` for the full generation
pipeline.

**End-user installation** (not generator): users install AID into their own projects via
`install.sh` (Bash) or `install.ps1` (PowerShell) — not `/generate-profile`.
`/generate-profile` is maintainer-only tooling for regenerating the agent trees under `profiles/`
and refreshing this repo's dogfood install.

## What We Accept

### Skill Improvements
- Improved phase instructions based on production experience
- Specialized variants (e.g., aid-discover for monorepos or Python projects)
- Skills for edge cases (multi-repo, microservices, data science)
- **Remember:** Edit `canonical/skills/aid-{phase}/SKILL.md` (and `references/` files if any),
  then run `/generate-profile`.
- **Shortcuts are different:** the verb-first shortcut skills (`aid-fix`, `aid-create-api`, `aid-update-cli`, …)
  are not hand-authored. They are generated from the catalog at
  `canonical/aid/templates/shortcut-catalog.yml` via the maintainer helper
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`, followed by the normal
  `run_generator.py` pass. To add or change a shortcut, edit the catalog row (and, if the shared
  behavior itself needs to change, `canonical/aid/templates/shortcut-engine.md` or the relevant
  `canonical/aid/templates/shortcut-scaffolding/<family>.md`) — never hand-edit a generated
  `canonical/skills/aid-<verb>[-<artifact>]/SKILL.md` directly.

### Agent Improvements
- Better system prompts, tool constraints, or role definitions
- New agent roles for specialized workflows
- **Remember:** Edit `canonical/agents/aid-{name}/AGENT.md`, then run `/generate-profile`.

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

2. **For skill/agent improvements:** Edit `canonical/` (the single source of truth), then run `/generate-profile` to regenerate the `profiles/<tool>/` agent trees and refresh the dogfood install.

3. **For new templates:** Add to the appropriate `templates/` subdirectory. Include guidance comments explaining *why* each section exists.

4. **For examples:** Add to `examples/` with a `README.md` explaining context. **Anonymize everything.**

5. **For methodology changes:** Open an issue first.

6. **Submit a PR** with:
   - What changed and why
   - What phase(s)/agent(s) this affects
   - Whether this was tested in production

## Style Guide

### Human Documentation (`docs/`, `examples/`)
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
- Generated agent trees (`profiles/<tool>/`, one per tool) are produced by `/generate-profile` — do not edit directly

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
