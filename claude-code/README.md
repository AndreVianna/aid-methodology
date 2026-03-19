# AID for Claude Code

Copy this folder's contents into your project's `.claude/` directory to use AID with Claude Code.

## Setup

```bash
# From your project root
cp -r path/to/aid-methodology/claude-code/.  .claude/
```

This gives you:
- `skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (12 skills)
- `agents/{name}.md` — Agent definitions in Claude Code format (13 agents)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `agents/orchestrator.md` | opus | Pipeline coordination, routing, human gates |
| Researcher | `agents/researcher.md` | sonnet | Investigation, KB generation, analysis |
| Interviewer | `agents/interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| Architect | `agents/architect.md` | opus | Design: specs, plans, task decomposition |
| Developer | `agents/developer.md` | sonnet | Code implementation (only code writer) |
| Critic | `agents/critic.md` | opus | Quality evaluation, grading (A+ to F) |
| Operator | `agents/operator.md` | sonnet | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `agents/ux-designer.md` | sonnet | UI/UX, accessibility, user flows |
| DevOps | `agents/devops.md` | sonnet | CI/CD, IaC, containerization |
| Tech Writer | `agents/tech-writer.md` | sonnet | Documentation, API docs, changelogs |
| Security | `agents/security.md` | opus | Threat modeling, OWASP, auth patterns |
| Data Engineer | `agents/data-engineer.md` | sonnet | Schema, migrations, query optimization |
| Performance | `agents/performance.md` | sonnet | Profiling, load testing, caching |

## Skills

12 phase skills, one per AID phase. See [`skills/README.md`](skills/README.md) for the full list.

## Usage

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields that Claude Code uses for skill selection.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Use them to delegate specific phases of the AID pipeline.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required)
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`, `maxTurns`)

## Notes

- Skills are optimized for LLM context windows — concise, no verbose explanations
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates live in the repo's `templates/` directory — reference them from your project
