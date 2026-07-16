# AID for Cursor

Install the persistent `aid` CLI once per machine, then add this profile inside your project:

## Setup

```bash
# 1. Bootstrap the aid CLI (once per machine)
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash

# 2. Add the profile inside your project
aid add cursor

# Manual copy alternative (from a repo checkout)
cp -r path/to/aid-methodology/profiles/cursor/.cursor    .cursor/
cp    path/to/aid-methodology/profiles/cursor/AGENTS.md   AGENTS.md
```

See the repo README for npm / pipx / offline install options.

This gives you:
- `.cursor/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (108 skills: 14 curated pipeline / on-demand / router skills plus the 94-row shortcut catalog's skills — 64 verb-first shortcut doorways + 30 hand-authored repurpose skills)
- `.cursor/agents/{name}.md` — Agent definitions (9 agents with `aid-` prefix), dispatched via Task tool when available
- `.cursor/aid/scripts/`, `.cursor/aid/templates/` — AID-own support files
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

`aid-researcher` is dispatched by `aid-discover` with a parameterized doc-set (pre-scan, architecture, analyst, integrator, quality) and by `aid-execute` for RESEARCH-typed tasks. A bash pre-pass (`.cursor/aid/scripts/kb/build-project-index.sh`) runs before the parameterized dispatches to emit `project-index.md` — a shared file inventory that eliminates duplicated `find`/`wc` work.

## Skills

108 skills total: 14 curated skills — the pipeline phase skills, the optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base, the on-demand `aid-housekeep`, `aid-update-kb`, `aid-set-connector`, and `aid-unset-connector` skills, and the `/aid-triage` router — plus the 94-row shortcut catalog's skills: 64 verb-first shortcut doorways and 30 hand-authored `repurpose` skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, and the re-registered `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask`). `/aid-triage` is a stateless, suggest-only router: it reads one free-form description and suggests either the matching shortcut, the full `aid-describe` path, or — when the input reads as a question — `/aid-ask`, writing nothing itself. `/aid-ask` is a friendly-named Q&A alias of the classic `aid-query-kb` skill. The shortcuts (`aid-fix`, `aid-create-api`, `aid-change-ui`, `aid-refactor`, `aid-review`, `aid-remove`, `aid-migrate`, …) are direct-entry doorways that skip straight to a flattened Lite work for a single named change. Each skill lives in `.cursor/skills/aid-<name>/SKILL.md`.

| Skill | Phase | Description |
|-------|-------|-------------|
| `aid-config` | Bootstrap | View/update AID pipeline settings; first run scaffolds `.aid/settings.yml` |
| `aid-discover` | Discover | Brownfield project discovery with quality gate (GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE) |
| `aid-describe` | Describe (2a) | Adaptive requirements gathering (seasoned-analyst engine) → `REQUIREMENTS.md` |
| `aid-define` | Define (2b) | Decompose approved requirements into features + cross-reference |
| `aid-specify` | Specify | Requirements → formal `SPEC.md` grounded in KB |
| `aid-plan` | Plan | High-level roadmap → `PLAN.md` (MVP, modules, deliverables) |
| `aid-detail` | Detail | Decompose plan → user stories, `task-NNN.md` files, execution waves |
| `aid-execute` | Execute | Type-aware execution with built-in review loop; agent picked by task type |
| `aid-deploy` | Deploy (optional) | Final verification, PR creation, delivery summary, KB updates |
| `aid-monitor` | Monitor (optional) | Observe production, classify findings, and route actions |
| `aid-summarize` | Optional (post-discovery) | Generate single-file `kb.html` from KB |

Notable mechanisms:
- **aid-execute** picks the executor by task type (RESEARCH→aid-researcher, IMPLEMENT→aid-developer, etc.) and aid-reviewer for grading.
- **aid-discover** runs `.cursor/aid/scripts/kb/build-project-index.sh` as a pre-pass before dispatching aid-researcher with parameterized doc-sets in parallel.

### Phase Flow

```
aid-config (bootstrap)
   → Discover → Describe (2a) → Define (2b) → Specify → Plan → Detail → Execute
   → optional Deliver: Deploy · Monitor
   ↑
   └── feedback loops: Q&A entries, IMPEDIMENT.md
```

## Usage

1. Run `aid add cursor` to install into your project
2. Edit `AGENTS.md` with your project description, build commands, and conventions
3. Run Discovery: tell Cursor "run aid-discover" to generate the Knowledge Base
4. Invoke phase skills as needed: "run aid-describe", "run aid-execute", etc.

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Dispatched via the Task tool (experimental as of March 2026); falls back to sequential execution if Task tool is unavailable.

### Utility Sub-Agent
`aid-clerk` is not invoked at the skill layer. Core agents call it internally to offload mechanical work (extraction, template-fill, file enumeration) to the Small tier. The caller passes an `operation:` parameter (extract / format / glob) and validates the output.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required) — lives in `.cursor/skills/`
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`) — lives in `.cursor/agents/`

## Notes

- Cursor also reads skills from `.claude/skills/` and `.codex/skills/` — cross-tool compatible
- Cursor does not use `CLAUDE.md` — all project context goes into `AGENTS.md`
- Templates install to `.cursor/aid/templates/` and bash helpers to `.cursor/aid/scripts/`
- The grading script (`.cursor/aid/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
- Authoring sources live in the methodology repo under `canonical/agents/` and `canonical/skills/`
