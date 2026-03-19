# Contributing to AID

AID is an open methodology — it improves through use. If you've run these phases in production and found something that works better, we want it here.

## Repository Structure

Understanding the structure is key to contributing in the right place:

| Directory | Audience | Format | Purpose |
|-----------|----------|--------|---------|
| `skills/` | Humans | README.md | Rich documentation per phase |
| `agents/` | Humans | README.md | Rich documentation per agent role |
| `claude-code/skills/` | LLMs | SKILL.md (YAML frontmatter) | Concise, context-window-optimized |
| `claude-code/agents/` | LLMs | .md (YAML frontmatter) | Claude Code agent definitions |
| `codex/skills/` | LLMs | SKILL.md (YAML frontmatter) | Same as claude-code (shared standard) |
| `codex/agents/` | LLMs | .toml | Codex agent definitions |
| `templates/` | Both | Markdown | Fill-in templates for artifacts |
| `examples/` | Humans | Markdown | Real-world case studies |
| `methodology/` | Humans | Markdown | Core methodology document |

**Important:** When updating a skill or agent, update ALL locations:
1. `skills/aid-{phase}/README.md` — human docs
2. `claude-code/skills/aid-{phase}/SKILL.md` — LLM version
3. `codex/skills/aid-{phase}/SKILL.md` — LLM version (shared body, Codex-specific frontmatter)

Same for agents: update the human README, Claude Code .md, and Codex .toml.

## What We Accept

### Skill Improvements
- Improved phase instructions based on production experience
- Specialized variants (e.g., aid-discover for monorepos or Python projects)
- Skills for edge cases (multi-repo, microservices, data science)
- **Remember:** Update human README + both LLM formats

### Agent Improvements
- Better system prompts, tool constraints, or role definitions
- New agent roles for specialized workflows
- **Remember:** Update human README + Claude Code .md + Codex .toml

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
- Agent/skill definitions for tools not yet supported (Cursor, Copilot, etc.)
- Add a new top-level directory following the `claude-code/` and `codex/` pattern

## What We Don't Accept

- Skills that require specific proprietary services
- Examples with real client data, company names, or identifiable information
- Changes to the core methodology without discussion first (open an issue)

## How to Contribute

1. **Fork the repo** and create a branch: `git checkout -b your-contribution`

2. **For skill/agent improvements:** Update ALL three locations (human README + claude-code + codex). The human version should be rich and explanatory. The LLM versions should be concise and structured.

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

### LLM Files (`claude-code/`, `codex/`)
- Concise — these go into context windows
- SKILL.md files: YAML frontmatter with `name` and `description`
- Claude Code agents: YAML frontmatter with `name`, `description`, `tools`, `model`, `maxTurns`
- Codex agents: TOML with `name`, `description`, `developer_instructions`, `model`
- Under 500 lines per skill (AgentSkills best practice)
- Strip verbose explanations — keep: purpose, inputs, process steps, outputs, checklist

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
