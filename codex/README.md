# AID for OpenAI Codex CLI

Copy this folder's contents into your project's `.agents/` directory to use AID with Codex CLI.

## Setup

```bash
# From your project root
cp -r path/to/aid-methodology/codex/.  .agents/
```

This gives you:
- `skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (12 skills)
- `agents/{name}.toml` — Agent definitions in Codex TOML format (13 agents)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `agents/orchestrator.toml` | o3 | Pipeline coordination, routing, human gates |
| Researcher | `agents/researcher.toml` | o4-mini | Investigation, KB generation, analysis |
| Interviewer | `agents/interviewer.toml` | o3 | Adaptive dialogue, requirements gathering |
| Architect | `agents/architect.toml` | o3 | Design: specs, plans, task decomposition |
| Developer | `agents/developer.toml` | o4-mini | Code implementation (only code writer) |
| Critic | `agents/critic.toml` | o3 | Quality evaluation, grading (A+ to F) |
| Operator | `agents/operator.toml` | o4-mini | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `agents/ux-designer.toml` | o4-mini | UI/UX, accessibility, user flows |
| DevOps | `agents/devops.toml` | o4-mini | CI/CD, IaC, containerization |
| Tech Writer | `agents/tech-writer.toml` | o4-mini | Documentation, API docs, changelogs |
| Security | `agents/security.toml` | o3 | Threat modeling, OWASP, auth patterns |
| Data Engineer | `agents/data-engineer.toml` | o4-mini | Schema, migrations, query optimization |
| Performance | `agents/performance.toml` | o4-mini | Profiling, load testing, caching |

## Skills

12 phase skills, one per AID phase. See [`skills/README.md`](skills/README.md) for the full list.

## Usage

### Skills
Skills are loaded as context when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields for skill selection.

### Agents
Agent TOML files define specialized roles with focused system prompts. Use them to delegate specific phases of the AID pipeline.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — same standard as Claude Code
- **Agents:** TOML with `name`, `description`, `developer_instructions`, and `model` fields

## Notes

- Skill bodies are shared with the claude-code versions; frontmatter uses Codex-specific fields (`metadata.short-description`) instead of Claude Code fields (`allowed-tools`, `context`, `agent`)
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates live in the repo's `templates/` directory — reference them from your project
