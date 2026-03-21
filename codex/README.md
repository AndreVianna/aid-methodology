# AID for OpenAI Codex CLI

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/codex/.codex  .codex/
cp path/to/aid-methodology/codex/AGENTS.md  AGENTS.md
```

This gives you:
- `.codex/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (11 skills)
- `.codex/agents/{name}.toml` — Agent definitions in Codex TOML format (13 agents)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `.codex/agents/orchestrator.toml` | o3 | Pipeline coordination, routing, human gates |
| Researcher | `.codex/agents/researcher.toml` | o4-mini | Investigation, KB generation, analysis |
| Interviewer | `.codex/agents/interviewer.toml` | o3 | Adaptive dialogue, requirements gathering |
| Architect | `.codex/agents/architect.toml` | o3 | Design: specs, plans, task decomposition |
| Developer | `.codex/agents/developer.toml` | o4-mini | Code implementation (only code writer) |
| Critic | `.codex/agents/critic.toml` | o3 | Quality evaluation, grading (A+ to F) |
| Operator | `.codex/agents/operator.toml` | o4-mini | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `.codex/agents/ux-designer.toml` | o4-mini | UI/UX, accessibility, user flows |
| DevOps | `.codex/agents/devops.toml` | o4-mini | CI/CD, IaC, containerization |
| Tech Writer | `.codex/agents/tech-writer.toml` | o4-mini | Documentation, API docs, changelogs |
| Security | `.codex/agents/security.toml` | o3 | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.codex/agents/data-engineer.toml` | o4-mini | Schema, migrations, query optimization |
| Performance | `.codex/agents/performance.toml` | o4-mini | Profiling, load testing, caching |

## Skills

11 phase skills, one per AID phase. See [`.codex/skills/README.md`](.codex/skills/README.md) for the full list.

## Usage

### Skills
Skills are loaded as context when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields for skill selection.

### Agents
Agent TOML files define specialized roles with focused system prompts. Use them to delegate specific phases of the AID pipeline.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — lives in `.codex/skills/`
- **Agents:** TOML with `name`, `description`, `developer_instructions`, and `model` fields — lives in `.codex/agents/`

## Notes

- Skill bodies are shared with the claude-code versions; frontmatter uses Codex-specific fields (`metadata.short-description`) instead of Claude Code fields (`allowed-tools`, `context`, `agent`)
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates live in the repo's `templates/` directory — reference them from your project
