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
- `.cursor/rules/aid-methodology.mdc` — Always-on rule: KB integration and phase workflow
- `.cursor/rules/aid-review.mdc` — Code review standards (applied to source files)
- 11 phase-specific rules (invoked on demand)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Rules

### Always-On Rules

#### `aid-methodology.mdc` (always applied)

Tells Cursor to:
- Read `knowledge/INDEX.md` before making changes
- Treat the Knowledge Base as the single source of truth
- Follow AID phases and produce artifacts at each gate

#### `aid-review.mdc` (applied to source files)

When Cursor reviews code it will:
- Check against task acceptance criteria
- Verify against `knowledge/coding-standards.md` and `knowledge/architecture.md`
- Grade A+ to F and tag issues by category

### Phase Rules (invoked on demand)

These rules contain the full AID phase instructions. Invoke them by referencing the rule name in your prompt (e.g., "use the aid-discover rule").

| Rule | Phase | Description |
|------|-------|-------------|
| `aid-discover.mdc` | Discovery | Brownfield codebase discovery with built-in quality gate (GENERATE → REVIEW → FIX → DONE) |
| `aid-interview.mdc` | Interview | Adaptive requirements gathering → `REQUIREMENTS.md` |
| `aid-specify.mdc` | Specify | Requirements → formal `SPEC.md` grounded in KB |
| `aid-plan.mdc` | Plan | High-level roadmap → `PLAN.md` (MVP, modules, deliverables) |
| `aid-detail.mdc` | Detail | Decompose plan → user stories, `TASK-{id}.md` files, execution waves |
| `aid-implement.mdc` | Implement | Execute tasks with KB context, mandatory build verification |
| `aid-review-skill.mdc` | Review | Spec-anchored code review, A+ to F grading, auto-fix P1/P2 |
| `aid-test.mdc` | Test | Staging validation — E2E, integration, manual testing |
| `aid-deploy.mdc` | Deploy | Final verification, PR creation, delivery summary, KB updates |
| `aid-track.mdc` | Track | Production telemetry interpretation → `TRACK-REPORT.md` |
| `aid-triage.mdc` | Triage | Classify findings (BUG/CR/Infra), root cause analysis, routing |

### Phase Flow

```
Discovery → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy → Track → Triage
    ↑                                                                                          │
    └──────────────────────── feedback loops (GAP.md, IMPEDIMENT.md) ──────────────────────────┘
```

## Usage

1. Run `setup.sh` to install into your project.
2. Edit `AGENTS.md` with your project description, build commands, and conventions.
3. Run the Discovery phase (invoke `aid-discover`) to generate `knowledge/INDEX.md`.
4. Cursor will automatically apply the always-on rules on every edit.
5. Invoke phase rules as needed throughout the development lifecycle.

## Agents

Cursor agents live in `.cursor/agents/` and are dispatched via the **Task tool** (experimental as of March 2026). If the Task tool is unavailable, run `/aid-discover` — it handles discovery sequentially without subagents.

### Discovery Agents (6)

These six agents are dispatched in parallel by the `aid-discover` orchestration to produce the Knowledge Base documents.

| Agent | File | Produces |
|-------|------|---------|
| `discovery-analyst` | `discovery-analyst.md` | `module-map.md`, `coding-standards.md`, `data-model.md` |
| `discovery-architect` | `discovery-architect.md` | `architecture.md`, `technology-stack.md` |
| `discovery-integrator` | `discovery-integrator.md` | `api-contracts.md`, `integration-map.md`, `domain-glossary.md` |
| `discovery-quality` | `discovery-quality.md` | `test-landscape.md`, `security-model.md`, `tech-debt.md` |
| `discovery-scout` | `discovery-scout.md` | `infrastructure.md`, `open-questions.md` |
| `discovery-reviewer` | `discovery-reviewer.md` | `DISCOVERY-GRADE.md` (cross-references KB against source) |

### Role-Based Agents (13)

Core pipeline agents that handle specific responsibilities across all AID phases.

| Agent | File | Role |
|-------|------|------|
| `orchestrator` | `orchestrator.md` | Coordinates AID pipeline, routes work, manages phase transitions with human gates |
| `architect` | `architect.md` | Transforms requirements and KB into SPEC.md, PLAN.md, DETAIL.md, and TASK files |
| `developer` | `developer.md` | Only agent that modifies production code; implements TASK files with build verification |
| `critic` | `critic.md` | Adversarial code quality evaluator, A+ to F grading; finds issues, never fixes them |
| `researcher` | `researcher.md` | Investigates and synthesizes information into KB documents and analysis reports |
| `operator` | `operator.md` | Executes deployment, PR creation, release management, and KB updates |
| `interviewer` | `interviewer.md` | One-question-at-a-time requirements dialogue with stakeholders → `REQUIREMENTS.md` |
| `data-engineer` | `data-engineer.md` | Specialist: schema design, migrations, query optimization, ETL patterns |
| `devops` | `devops.md` | Specialist: CI/CD, infrastructure-as-code, containerization, monitoring |
| `performance` | `performance.md` | Specialist: profiling, load testing, bottleneck analysis, caching strategies |
| `security` | `security.md` | Specialist: threat modeling, OWASP, auth patterns, secrets management |
| `tech-writer` | `tech-writer.md` | Specialist: end-user docs, API docs, changelogs, README quality |
| `ux-designer` | `ux-designer.md` | Specialist: UI/UX patterns, accessibility (WCAG), user flows, wireframes |

> **Note:** Cursor sub-agent dispatch via Task tool is experimental (Mar 2026). Discovery agents run with `permissionMode: bypassPermissions` and `background: true`.

## Notes

- Cursor uses `.mdc` files in `.cursor/rules/` — these are Markdown with YAML frontmatter
- `alwaysApply: true` rules are injected into every conversation
- `alwaysApply: false` rules are available on demand (invoke by name)
- `globs:` rules are injected when matching files are open
- Human-readable phase documentation lives in the repo's `skills/` directory
- Templates for all artifacts live in `templates/`
- `aid-review.mdc` is the always-on lightweight review rule; `aid-review-skill.mdc` is the full review phase with grading
