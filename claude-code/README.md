# AID for Claude Code

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/claude-code/.claude  .claude/
cp path/to/aid-methodology/claude-code/CLAUDE.md   CLAUDE.md
```

This gives you:
- `.claude/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (11 skills: 10 pipeline + 1 optional `aid-summarize`)
- `.claude/agents/{name}.md` — Agent definitions in Claude Code format (13 agents)
- `CLAUDE.md` — Claude Code project configuration (edit with your project details)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `.claude/agents/orchestrator.md` | opus | Pipeline coordination, routing, human gates |
| Researcher | `.claude/agents/researcher.md` | opus | Investigation, KB generation, analysis |
| Interviewer | `.claude/agents/interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| Architect | `.claude/agents/architect.md` | opus | Design: specs, plans, task decomposition |
| Developer | `.claude/agents/developer.md` | opus | Code implementation (only code writer) |
| Critic | `.claude/agents/critic.md` | opus | Quality evaluation, grading (A+ to F) |
| Operator | `.claude/agents/operator.md` | opus | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `.claude/agents/ux-designer.md` | opus | UI/UX, accessibility, user flows |
| DevOps | `.claude/agents/devops.md` | opus | CI/CD, IaC, containerization |
| Tech Writer | `.claude/agents/tech-writer.md` | opus | Documentation, API docs, changelogs |
| Security | `.claude/agents/security.md` | opus | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.claude/agents/data-engineer.md` | opus | Schema, migrations, query optimization |
| Performance | `.claude/agents/performance.md` | opus | Profiling, load testing, caching |

## Skills

10 phase skills (one per AID phase) plus an optional `aid-summarize` for generating
a single-file visual HTML summary of the Knowledge Base. See
[`.claude/skills/README.md`](.claude/skills/README.md) for the full list.

## Usage

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields that Claude Code uses for skill selection.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Use them to delegate specific phases of the AID pipeline.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — lives in `.claude/skills/`
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`) — lives in `.claude/agents/`

## Notes

- Skills are optimized for LLM context windows — concise, no verbose explanations
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates live in the repo's `templates/` directory — reference them from your project
