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
- `.cursor/agents/{name}.md` — Agent definitions (9 agents with `aid-` prefix), dispatched via Task tool when available
- `.cursor/templates/` — Templates and bash scripts (grading rubric, `grade.sh`, `build-project-index.sh`)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Agents

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| aid-orchestrator | `.cursor/agents/aid-orchestrator.md` | sonnet | Pipeline coordination, routing, human gates |
| aid-researcher | `.cursor/agents/aid-researcher.md` | opus | Investigation, KB generation, analysis (parameterized doc-set) |
| aid-interviewer | `.cursor/agents/aid-interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| aid-architect | `.cursor/agents/aid-architect.md` | opus | Design: specs, plans, task decomposition |
| aid-developer | `.cursor/agents/aid-developer.md` | sonnet | Code implementation, data migrations, CI/CD config |
| aid-reviewer | `.cursor/agents/aid-reviewer.md` | opus | Adversarial issue-finding; grade computed by `grade.sh` |
| aid-operator | `.cursor/agents/aid-operator.md` | sonnet | Deployment, PR creation, releases |
| aid-tech-writer | `.cursor/agents/aid-tech-writer.md` | sonnet | User-facing documentation, API docs, changelogs |
| aid-clerk | `.cursor/agents/aid-clerk.md` | haiku | Mechanical utility: extract, format, or glob (operation parameter) |

`aid-researcher` is dispatched by `aid-discover` with a parameterized doc-set (pre-scan, architecture, analyst, integrator, quality) and by `aid-execute` for RESEARCH-typed tasks. A bash pre-pass (`templates/scripts/build-project-index.sh`) runs before the parameterized dispatches to emit `project-index.md` — a shared file inventory that eliminates duplicated `find`/`wc` work.

## Skills

10 phase skills (one per AID phase) plus an optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base. See [`.cursor/skills/aid-README.md`](.cursor/skills/aid-README.md) for the full list.

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
- **aid-execute** picks the executor by task type (RESEARCH→aid-researcher, IMPLEMENT→aid-developer, etc.) and aid-reviewer for grading.
- **aid-discover** runs `build-project-index.sh` as a pre-pass before dispatching aid-researcher with parameterized doc-sets in parallel.

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

### Utility Sub-Agent
`aid-clerk` is not invoked at the skill layer. Core agents call it internally to offload mechanical work (extraction, template-fill, file enumeration) to the Small tier. The caller passes an `operation:` parameter (extract / format / glob) and validates the output.

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
