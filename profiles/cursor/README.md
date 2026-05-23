# AID for Cursor

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/profiles/cursor/.cursor  .cursor/
cp path/to/aid-methodology/cursor/AGENTS.md   AGENTS.md
```

This gives you:
- `.cursor/rules/` — Always-on rules (methodology workflow, code review standards)
- `.cursor/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (11 skills: 10 pipeline + 1 optional `aid-summarize`)
- `.cursor/agents/{name}.md` — Agent definitions (22 agents: 13 base + 6 discovery sub + 3 utility), dispatched via Task tool when available
- `.cursor/templates/` — Templates and bash scripts (grading rubric, `grade.sh`, `build-project-index.sh`)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Agents

### Core Agents (always present)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| Orchestrator | `.cursor/agents/orchestrator.md` | sonnet | Pipeline coordination, routing, human gates |
| Researcher | `.cursor/agents/researcher.md` | sonnet | Investigation, KB generation, analysis |
| Interviewer | `.cursor/agents/interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| Architect | `.cursor/agents/architect.md` | opus | Design: specs, plans, task decomposition |
| Developer | `.cursor/agents/developer.md` | sonnet | Code implementation (only code writer) |
| Reviewer | `.cursor/agents/reviewer.md` | opus | Adversarial issue-finding; grade computed by `grade.sh` |
| Operator | `.cursor/agents/operator.md` | sonnet | Deployment, PR creation, releases |

### Specialist Agents (invoked ad-hoc)

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| UX Designer | `.cursor/agents/ux-designer.md` | sonnet | UI/UX, accessibility, user flows |
| DevOps | `.cursor/agents/devops.md` | sonnet | CI/CD, IaC, containerization |
| Tech Writer | `.cursor/agents/tech-writer.md` | sonnet | Documentation, API docs, changelogs |
| Security | `.cursor/agents/security.md` | opus | Threat modeling, OWASP, auth patterns |
| Data Engineer | `.cursor/agents/data-engineer.md` | sonnet | Schema, migrations, query optimization |
| Performance | `.cursor/agents/performance.md` | sonnet | Profiling, load testing, caching |

### Discovery Sub-Agents (dispatched by aid-discover)

All Discovery sub-agents run at the Large tier — Discovery is foundational and runs once per project, so the cost case for cheaper tiers doesn't hold.

| Agent | File | Model | Outputs |
|-------|------|-------|---------|
| discovery-architect | `.cursor/agents/discovery-architect.md` | opus | architecture.md, technology-stack.md, ui-architecture.md |
| discovery-analyst | `.cursor/agents/discovery-analyst.md` | opus | module-map.md, coding-standards.md, data-model.md |
| discovery-integrator | `.cursor/agents/discovery-integrator.md` | opus | api-contracts.md, integration-map.md, domain-glossary.md |
| discovery-quality | `.cursor/agents/discovery-quality.md` | opus | test-landscape.md, security-model.md, tech-debt.md |
| discovery-scout | `.cursor/agents/discovery-scout.md` | opus | project-structure.md, external-sources.md |
| discovery-reviewer | `.cursor/agents/discovery-reviewer.md` | opus | `.aid/knowledge/STATE.md` (KB grading; per FR2) |

A bash pre-pass (`templates/scripts/build-project-index.sh`) runs before the 5 sub-agents to emit `project-index.md` — a shared file inventory that eliminates duplicated `find`/`wc` work across agents.

### Utility Sub-Agents (called by Core/Specialist agents)

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| simple-extractor | `.cursor/agents/simple-extractor.md` | haiku | Extract structured items from files (annotations, imports, endpoints) |
| simple-formatter | `.cursor/agents/simple-formatter.md` | haiku | Fill markdown templates with structured input |
| simple-glob | `.cursor/agents/simple-glob.md` | haiku | Enumerate files matching glob patterns with metadata |

## Skills

10 phase skills (one per AID phase) plus an optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base. See [`.cursor/skills/README.md`](.cursor/skills/README.md) for the full list.

| Skill | Phase | Description |
|-------|-------|-------------|
| `aid-init` | Init | Initialize AID project — scaffold .aid/knowledge/ (16 KB templates), set up AGENTS.md |
| `aid-discover` | Discovery | Brownfield project discovery with quality gate (GENERATE → REVIEW → FIX → DONE) |
| `aid-interview` | Interview | Adaptive requirements gathering → `REQUIREMENTS.md` |
| `aid-specify` | Specify | Requirements → formal `SPEC.md` grounded in KB |
| `aid-plan` | Plan | High-level roadmap → `PLAN.md` (MVP, modules, deliverables) |
| `aid-detail` | Detail | Decompose plan → user stories, `task-NNN.md` files, execution waves |
| `aid-execute` | Implement | Type-aware execution with built-in review loop; agent picked by task type |
| `aid-deploy` | Deploy | Final verification, PR creation, delivery summary, KB updates |
| `aid-monitor` | Track | Production telemetry interpretation → `MONITOR-STATE.md` |
| `aid-summarize` | Optional (post-discovery) | Generate single-file `knowledge-summary.html` from KB |

Notable mechanisms:
- **aid-execute** picks the executor by task type (RESEARCH→researcher, IMPLEMENT→developer, etc.) and the Reviewer for grading.
- **aid-discover** runs `build-project-index.sh` as a pre-pass before dispatching the 5 discovery sub-agents in parallel.

### Phase Flow

```
Discovery → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy → Track → Triage
    ↑                                                                                          │
    └──────────────────────── feedback loops (Q&A entries, IMPEDIMENT.md) ──────────────────────────┘
```

## Rules (`.cursor/rules/`)

Cursor-specific addition. Always-on contextual rules loaded into every conversation or on file match.

### `aid-methodology.mdc` (always applied)

Tells Cursor to:
- Read `.aid/knowledge/INDEX.md` before making changes
- Treat the Knowledge Base as the single source of truth
- Follow AID phases and produce artifacts at each gate

When Cursor reviews code it will:
- Check against task acceptance criteria
- Verify against `.aid/knowledge/coding-standards.md` and `.aid/knowledge/architecture.md`
- Tag issues by severity (`[CRITICAL]`/`[HIGH]`/`[MEDIUM]`/`[LOW]`/`[MINOR]`) — grade computed deterministically by `grade.sh`

## Usage

1. Run `setup.sh` to install into your project
2. Edit `AGENTS.md` with your project description, build commands, and conventions
3. Run Discovery: tell Cursor "run aid-discover" to generate the Knowledge Base
4. Cursor automatically applies the always-on rules on every conversation
5. Invoke phase skills as needed: "run aid-interview", "run aid-execute", etc.

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Dispatched via the Task tool (experimental as of March 2026); falls back to sequential execution if Task tool is unavailable.

### Utility Sub-Agents
The `simple-*` agents are not invoked at the skill layer. Core/Specialist agents call them internally to offload mechanical work (extraction, formatting, file enumeration) to the Small tier. The caller validates the output.

## File Format

- **Rules:** `.mdc` files for always-on constraints — lives in `.cursor/rules/`
- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — lives in `.cursor/skills/`
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`) — lives in `.cursor/agents/`

## Notes

- **Rules** (`.mdc`) are for always-on constraints; **Skills** (`SKILL.md`) are for on-demand workflows
- Cursor also reads skills from `.claude/skills/` and `.codex/skills/` — cross-tool compatible
- Cursor does not use `CLAUDE.md` — all project context goes into `AGENTS.md`
- Templates and scripts live in the repo's `templates/` directory — reference them from your project
- The grading script (`templates/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
- Human-readable agent and phase documentation lives in the repo's `agents/` and `skills/` directories
