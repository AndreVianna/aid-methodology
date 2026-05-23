# AID for Claude Code

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/profiles/claude-code/.claude  .claude/
cp path/to/aid-methodology/claude-code/CLAUDE.md   CLAUDE.md
```

This gives you:
- `.claude/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (11 skills: 10 pipeline + 1 optional `aid-summarize`)
- `.claude/agents/{name}.md` — Agent definitions in Claude Code format (22 agents: 13 base + 6 discovery sub + 3 utility)
- `.claude/templates/` — Templates and bash scripts (grading rubric, `grade.sh`, `build-project-index.sh`)
- `CLAUDE.md` — Claude Code project configuration (edit with your project details)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `.claude/agents/orchestrator.md` | sonnet | Pipeline coordination, routing, human gates |
| Researcher | `.claude/agents/researcher.md` | sonnet | Investigation, KB generation, analysis |
| Interviewer | `.claude/agents/interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| Architect | `.claude/agents/architect.md` | opus | Design: specs, plans, task decomposition |
| Developer | `.claude/agents/developer.md` | sonnet | Code implementation (only code writer) |
| Reviewer | `.claude/agents/reviewer.md` | opus | Adversarial issue-finding; grade computed by `grade.sh` |
| Operator | `.claude/agents/operator.md` | sonnet | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `.claude/agents/ux-designer.md` | sonnet | UI/UX, accessibility, user flows |
| DevOps | `.claude/agents/devops.md` | sonnet | CI/CD, IaC, containerization |
| Tech Writer | `.claude/agents/tech-writer.md` | sonnet | Documentation, API docs, changelogs |
| Security | `.claude/agents/security.md` | opus | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.claude/agents/data-engineer.md` | sonnet | Schema, migrations, query optimization |
| Performance | `.claude/agents/performance.md` | sonnet | Profiling, load testing, caching |

### Discovery Sub-Agents (dispatched by aid-discover)

| Agent | File | Model | Outputs |
|-------|------|-------|---------|
| discovery-architect | `.claude/agents/discovery-architect.md` | opus | architecture.md, technology-stack.md, ui-architecture.md |
| discovery-analyst | `.claude/agents/discovery-analyst.md` | opus | module-map.md, coding-standards.md, data-model.md |
| discovery-integrator | `.claude/agents/discovery-integrator.md` | opus | api-contracts.md, integration-map.md, domain-glossary.md |
| discovery-quality | `.claude/agents/discovery-quality.md` | opus | test-landscape.md, security-model.md, tech-debt.md |
| discovery-scout | `.claude/agents/discovery-scout.md` | opus | project-structure.md, external-sources.md |
| discovery-reviewer | `.claude/agents/discovery-reviewer.md` | opus | DISCOVERY-STATE.md (KB grading) |

### Utility Sub-Agents (called by Core/Specialist agents)

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| simple-extractor | `.claude/agents/simple-extractor.md` | haiku | Extract structured items from files (annotations, imports, endpoints) |
| simple-formatter | `.claude/agents/simple-formatter.md` | haiku | Fill markdown templates with structured input |
| simple-glob | `.claude/agents/simple-glob.md` | haiku | Enumerate files matching glob patterns with metadata |

## Skills

10 phase skills (one per AID phase) plus an optional `aid-summarize` for generating
a single-file visual HTML summary of the Knowledge Base. See
[`.claude/skills/README.md`](.claude/skills/README.md) for the full list.

Notable mechanisms:
- **aid-execute** uses an `agents:` selector that picks the executor by task type (RESEARCH→researcher, IMPLEMENT→developer, etc.) and the Reviewer for grading. Grade is computed by `templates/scripts/grade.sh` from the Reviewer's structured issue list.
- **aid-discover** runs `templates/scripts/build-project-index.sh` as a Step 0c pre-pass before dispatching the 5 discovery sub-agents in parallel — eliminates duplicated file-reading.

## Usage

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields that Claude Code uses for skill selection.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Skills with multiple agent options use an `agents:` block in frontmatter and a selector table in the body.

### Utility Sub-Agents
The `simple-*` agents are not invoked at the skill layer. Core/Specialist agents call them internally to offload mechanical work (extraction, formatting, file enumeration) to the Small tier. The caller validates the output.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required; `agents:` block optional) — lives in `.claude/skills/`
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`) — lives in `.claude/agents/`

## Notes

- Skills are optimized for LLM context windows — concise, no verbose explanations
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates and scripts live in the repo's `templates/` directory — reference them from your project
- The grading script (`templates/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
