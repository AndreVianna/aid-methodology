# AID for Cursor

Use the `setup.sh` (or `setup.ps1` on Windows) script at the repo root to install AID into your project, or copy manually:

## Setup

```bash
# Automated (recommended)
path/to/aid-methodology/setup.sh /path/to/your/project

# Manual
cp -r path/to/aid-methodology/cursor/.cursor  .cursor/
cp path/to/aid-methodology/cursor/AGENTS.md   AGENTS.md
```

This gives you:
- `.cursor/rules/` — Always-on rules (methodology workflow, code review standards)
- `.cursor/skills/` — 11 phase skills (invoked on demand by the agent)
- `.cursor/agents/` — 19 specialist agents (dispatched via Task tool when available)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Rules (`.cursor/rules/`)

Always-on contextual rules loaded into every conversation or on file match.

### `aid-methodology.mdc` (always applied)

Tells Cursor to:
- Read `knowledge/INDEX.md` before making changes
- Treat the Knowledge Base as the single source of truth
- Follow AID phases and produce artifacts at each gate

### `aid-review.mdc` (applied to source files)

When Cursor reviews code it will:
- Check against task acceptance criteria
- Verify against `knowledge/coding-standards.md` and `knowledge/architecture.md`
- Grade A+ to F and tag issues by category

## Skills (`.cursor/skills/`)

Skills are the full AID phase instructions. Cursor loads them based on relevance — describe the phase you want and the agent will pick the right skill.

| Skill | Phase | Description |
|-------|-------|-------------|
| `aid-discover` | Discovery | Brownfield codebase discovery with quality gate (GENERATE → REVIEW → FIX → DONE) |
| `aid-interview` | Interview | Adaptive requirements gathering → `REQUIREMENTS.md` |
| `aid-specify` | Specify | Requirements → formal `SPEC.md` grounded in KB |
| `aid-plan` | Plan | High-level roadmap → `PLAN.md` (MVP, modules, deliverables) |
| `aid-detail` | Detail | Decompose plan → user stories, `TASK-{id}.md` files, execution waves |
| `aid-implement` | Implement | Execute tasks with KB context, mandatory build verification |
| `aid-review` | Review | Spec-anchored code review, A+ to F grading, auto-fix P1/P2 |
| `aid-test` | Test | Staging validation — E2E, integration, manual testing |
| `aid-deploy` | Deploy | Final verification, PR creation, delivery summary, KB updates |
| `aid-track` | Track | Production telemetry interpretation → `TRACK-REPORT.md` |
| `aid-triage` | Triage | Classify findings (BUG/CR/Infra), root cause analysis, routing |

### Phase Flow

```
Discovery → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy → Track → Triage
    ↑                                                                                          │
    └──────────────────────── feedback loops (GAP.md, IMPEDIMENT.md) ──────────────────────────┘
```

## Agents (`.cursor/agents/`)

Cursor agents are dispatched via the **Task tool** (experimental as of March 2026). If the Task tool is unavailable, skills fall back to sequential execution in the main context.

### Discovery Agents (6)

Dispatched in parallel by `aid-discover` to produce Knowledge Base documents.

| Agent | Produces |
|-------|---------|
| `discovery-architect` | `architecture.md`, `technology-stack.md` |
| `discovery-analyst` | `module-map.md`, `coding-standards.md`, `data-model.md` |
| `discovery-integrator` | `api-contracts.md`, `integration-map.md`, `domain-glossary.md` |
| `discovery-quality` | `test-landscape.md`, `security-model.md`, `tech-debt.md` |
| `discovery-scout` | `infrastructure.md`, `additional-info.md` |
| `discovery-reviewer` | `DISCOVERY-STATE.md` (cross-references KB against source, tracks grade + approval) |

### Role-Based Agents (13)

Core pipeline agents for specific responsibilities across all AID phases.

| Agent | Role |
|-------|------|
| `orchestrator` | Coordinates AID pipeline, routes work, manages phase transitions with human gates |
| `architect` | Transforms requirements and KB into SPEC.md, PLAN.md, DETAIL.md, and TASK files |
| `developer` | Only agent that modifies production code; implements TASK files with build verification |
| `critic` | Adversarial code quality evaluator, A+ to F grading; finds issues, never fixes them |
| `researcher` | Investigates and synthesizes information into KB documents and analysis reports |
| `operator` | Executes deployment, PR creation, release management, and KB updates |
| `interviewer` | One-question-at-a-time requirements dialogue with stakeholders → `REQUIREMENTS.md` |
| `data-engineer` | Specialist: schema design, migrations, query optimization, ETL patterns |
| `devops` | Specialist: CI/CD, infrastructure-as-code, containerization, monitoring |
| `performance` | Specialist: profiling, load testing, bottleneck analysis, caching strategies |
| `security` | Specialist: threat modeling, OWASP, auth patterns, secrets management |
| `tech-writer` | Specialist: end-user docs, API docs, changelogs, README quality |
| `ux-designer` | Specialist: UI/UX patterns, accessibility (WCAG), user flows, wireframes |

## Usage

1. Run `setup.sh` to install into your project
2. Edit `AGENTS.md` with your project description, build commands, and conventions
3. Run Discovery: tell Cursor "run aid-discover" to generate the Knowledge Base
4. Cursor automatically applies the always-on rules on every conversation
5. Invoke phase skills as needed: "run aid-interview", "run aid-implement", etc.

## Notes

- **Rules** (`.mdc`) are for always-on constraints; **Skills** (`SKILL.md`) are for on-demand workflows
- Cursor also reads skills from `.claude/skills/` and `.codex/skills/` — cross-tool compatible
- Cursor does not use `CLAUDE.md` — all project context goes into `AGENTS.md`
- Templates for all artifacts live in the repo's `templates/` directory
- Human-readable phase documentation lives in the repo's `skills/` directory
