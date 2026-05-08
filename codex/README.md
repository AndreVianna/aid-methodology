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
- `.agents/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (11 skills: 10 pipeline + 1 optional `aid-summarize`)
- `.codex/agents/{name}.toml` — Agent definitions in Codex TOML format (22 agents: 13 base + 6 discovery sub + 3 utility)
- `.agents/templates/` — Templates and bash scripts (grading rubric, `grade.sh`, `build-project-index.sh`)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Model Tiers

For Codex, the AID model tier matrix maps to OpenAI models as:

| Tier | Model | Reasoning Effort | When |
|------|-------|------------------|------|
| Opus | `gpt-5.5` | `high` | Foundational/adversarial/judgment-heavy work |
| Sonnet | `gpt-5.4` | `medium` | Production work with structured inputs |
| Haiku | `gpt-5.4-mini` | `low` | Mechanical sub-tasks (extraction, formatting, enumeration) |

The Reviewer ≥ Executor invariant is enforced: the agent that grades is never below the agent it grades.

> **Migration note (May 2026):** Prior versions of this directory had inconsistent tier assignments — 7 of the 9 Sonnet-tier agents (researcher, operator, ux-designer, devops, tech-writer, data-engineer, performance) were set to `gpt-5.4-mini` with `medium` reasoning, which doesn't correspond to any documented tier. They have been corrected to `gpt-5.4` `medium` (Sonnet). If you previously customized these files in your project install, your overrides may need re-applying.

## Agents

### Core Agents (always present)

| Agent | File | Model | Reasoning | Specialty |
|-------|------|-------|-----------|-----------|
| Orchestrator | `.codex/agents/orchestrator.toml` | gpt-5.4 | medium | Pipeline coordination, routing, human gates |
| Researcher | `.codex/agents/researcher.toml` | gpt-5.4 | medium | Investigation, KB generation, analysis |
| Interviewer | `.codex/agents/interviewer.toml` | gpt-5.5 | high | Adaptive dialogue, requirements gathering |
| Architect | `.codex/agents/architect.toml` | gpt-5.5 | high | Design: specs, plans, task decomposition |
| Developer | `.codex/agents/developer.toml` | gpt-5.4 | medium | Code implementation (only code writer) |
| Reviewer | `.codex/agents/reviewer.toml` | gpt-5.5 | high | Adversarial issue-finding; grade computed by `grade.sh` |
| Operator | `.codex/agents/operator.toml` | gpt-5.4 | medium | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Reasoning | Specialty |
|-------|------|-------|-----------|-----------|
| UX Designer | `.codex/agents/ux-designer.toml` | gpt-5.4 | medium | UI/UX, accessibility, user flows |
| DevOps | `.codex/agents/devops.toml` | gpt-5.4 | medium | CI/CD, IaC, containerization |
| Tech Writer | `.codex/agents/tech-writer.toml` | gpt-5.4 | medium | Documentation, API docs, changelogs |
| Security | `.codex/agents/security.toml` | gpt-5.5 | high | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.codex/agents/data-engineer.toml` | gpt-5.4 | medium | Schema, migrations, query optimization |
| Performance | `.codex/agents/performance.toml` | gpt-5.4 | medium | Profiling, load testing, caching |

### Discovery Sub-Agents (used by aid-discover skill)

All Discovery sub-agents run at the Opus tier — Discovery is foundational and runs once per project, so the cost case for cheaper tiers doesn't hold.

| Agent | File | Model | Reasoning | Specialty |
|-------|------|-------|-----------|-----------|
| Discovery Architect | `.codex/agents/discovery-architect.toml` | gpt-5.5 | high | Architecture, tech stack analysis |
| Discovery Analyst | `.codex/agents/discovery-analyst.toml` | gpt-5.5 | high | Modules, conventions, data models |
| Discovery Integrator | `.codex/agents/discovery-integrator.toml` | gpt-5.5 | high | APIs, integrations, domain glossary |
| Discovery Quality | `.codex/agents/discovery-quality.toml` | gpt-5.5 | high | Tests, security, tech debt |
| Discovery Scout | `.codex/agents/discovery-scout.toml` | gpt-5.5 | high | Infrastructure, open questions |
| Discovery Reviewer | `.codex/agents/discovery-reviewer.toml` | gpt-5.5 | high | KB quality review and grading |

### Utility Sub-Agents (called by Core/Specialist agents)

These Haiku-tier sub-agents are dispatched *by* full agents for mechanical sub-tasks. Never invoked at the skill layer.

| Agent | File | Model | Reasoning | Purpose |
|-------|------|-------|-----------|---------|
| simple-extractor | `.codex/agents/simple-extractor.toml` | gpt-5.4-mini | low | Extract structured items from files |
| simple-formatter | `.codex/agents/simple-formatter.toml` | gpt-5.4-mini | low | Fill markdown templates with structured input |
| simple-glob | `.codex/agents/simple-glob.toml` | gpt-5.4-mini | low | Enumerate files matching glob patterns with metadata |

## Skills

10 pipeline skills (Phase 0 Init through Phase 9 Triage) plus an optional
`aid-summarize` for generating a single-file visual HTML summary of the
Knowledge Base after discovery. See [`.agents/skills/README.md`](.agents/skills/README.md)
for the full list. Skills live in `.agents/skills/` — Codex reads skills from this directory.

Notable mechanisms:
- **aid-execute** uses an `agents:` selector that picks the executor by task type and the Reviewer for grading. Grade is computed by `.agents/templates/scripts/grade.sh` from the Reviewer's structured issue list.
- **aid-discover** runs `.agents/templates/scripts/build-project-index.sh` as a Step 0c pre-pass before dispatching the 5 discovery sub-agents in parallel.

## Usage

### Skills
Skills are loaded as context when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields for skill selection.

### Agents
Agent TOML files define specialized roles with focused system prompts. Skills with multiple agent options use an `agents:` block in frontmatter and a selector table in the body.

The `aid-init` skill scaffolds the Knowledge Base (16 documents) and sets up AGENTS.md before discovery begins. The `aid-discover` skill runs the file-index pre-pass, then dispatches 5 discovery agents for KB generation, then uses the discovery-reviewer agent for quality gating.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required; `agents:` block optional) — lives in `.agents/skills/`
- **Agents:** TOML with `name`, `description`, `developer_instructions`, `model`, and `model_reasoning_effort` fields — lives in `.codex/agents/`

## Notes

- Skill bodies are shared with the claude-code versions; frontmatter uses Codex-specific fields
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates and scripts live in `.agents/templates/` (and the source-of-truth at `templates/` in the AID repo)
- The grading script (`.agents/templates/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
