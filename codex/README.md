# AID for OpenAI Codex CLI

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/codex/.codex  .codex/
cp -r path/to/aid-methodology/codex/.agents .agents/
cp path/to/aid-methodology/codex/AGENTS.md  AGENTS.md
```

This gives you:
- `.agents/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (12 skills)
- `.codex/agents/{name}.toml` — Agent definitions in Codex TOML format (19 agents)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `.codex/agents/orchestrator.toml` | gpt-5.4 | Pipeline coordination, routing, human gates |
| Researcher | `.codex/agents/researcher.toml` | gpt-5.4-mini | Investigation, KB generation, analysis |
| Interviewer | `.codex/agents/interviewer.toml` | gpt-5.4 | Adaptive dialogue, requirements gathering |
| Architect | `.codex/agents/architect.toml` | gpt-5.4 | Design: specs, plans, task decomposition |
| Developer | `.codex/agents/developer.toml` | gpt-5.4-mini | Code implementation (only code writer) |
| Critic | `.codex/agents/critic.toml` | gpt-5.4 | Quality evaluation, grading (A+ to F) |
| Operator | `.codex/agents/operator.toml` | gpt-5.4-mini | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `.codex/agents/ux-designer.toml` | gpt-5.4-mini | UI/UX, accessibility, user flows |
| DevOps | `.codex/agents/devops.toml` | gpt-5.4-mini | CI/CD, IaC, containerization |
| Tech Writer | `.codex/agents/tech-writer.toml` | gpt-5.4-mini | Documentation, API docs, changelogs |
| Security | `.codex/agents/security.toml` | gpt-5.4 | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.codex/agents/data-engineer.toml` | gpt-5.4-mini | Schema, migrations, query optimization |
| Performance | `.codex/agents/performance.toml` | gpt-5.4-mini | Profiling, load testing, caching |

### Discovery Agents (used by aid-discover skill)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Discovery Architect | `.codex/agents/discovery-architect.toml` | gpt-5.4 | Architecture, tech stack analysis |
| Discovery Analyst | `.codex/agents/discovery-analyst.toml` | gpt-5.4 | Modules, conventions, data models |
| Discovery Integrator | `.codex/agents/discovery-integrator.toml` | gpt-5.4 | APIs, integrations, domain glossary |
| Discovery Quality | `.codex/agents/discovery-quality.toml` | gpt-5.4 | Tests, security, tech debt |
| Discovery Scout | `.codex/agents/discovery-scout.toml` | gpt-5.4 | Infrastructure, open questions |
| Discovery Reviewer | `.codex/agents/discovery-reviewer.toml` | gpt-5.4 | KB quality review and grading |

## Skills

12 phase skills (Phase 0 Init through Phase 11 Triage). See [`.agents/skills/README.md`](.agents/skills/README.md) for the full list.
Skills live in `.agents/skills/` — Codex reads skills from this directory.

## Usage

### Skills
Skills are loaded as context when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields for skill selection.

### Agents
Agent TOML files define specialized roles with focused system prompts. Use them to delegate specific phases of the AID pipeline.

The `aid-init` skill scaffolds the Knowledge Base (14 documents) and sets up AGENTS.md before discovery begins. The `aid-discover` skill dispatches 5 discovery agents for KB generation, then uses the discovery-reviewer agent for quality gating.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — lives in `.agents/skills/`
- **Agents:** TOML with `name`, `description`, `developer_instructions`, `model`, and `model_reasoning_effort` fields — lives in `.codex/agents/`

## Notes

- Skill bodies are shared with the claude-code versions; frontmatter uses Codex-specific fields
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates live in the repo's `templates/` directory — reference them from your project
- gpt-5.4 agents use `model_reasoning_effort = "high"`, gpt-5.4-mini agents use `model_reasoning_effort = "medium"`
