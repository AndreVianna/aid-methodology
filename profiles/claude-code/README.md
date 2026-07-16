# AID for Claude Code

Install the persistent `aid` CLI once per machine, then add this profile inside your project:

## Setup

```bash
# 1. Bootstrap the aid CLI (once per machine)
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash

# 2. Add the profile inside your project
aid add claude-code

# Manual copy alternative (from a repo checkout)
cp -r path/to/aid-methodology/profiles/claude-code/.claude   .claude/
cp    path/to/aid-methodology/profiles/claude-code/CLAUDE.md  CLAUDE.md
```

See the repo README for npm / pipx / offline install options.

This gives you:
- `.claude/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (108 skills: 14 curated pipeline / on-demand / router skills plus the 94-row shortcut catalog's skills — 64 verb-first shortcut doorways + 30 hand-authored repurpose skills)
- `.claude/agents/{name}.md` — Agent definitions in Claude Code format (9 agents with `aid-` prefix)
- `.claude/aid/templates/` — Templates (grading rubric, settings schema); `.claude/aid/scripts/` — bash helpers (`grade.sh`, `kb/build-project-index.sh`)
- `CLAUDE.md` — Claude Code project configuration (edit with your project details)

## Agents

| Agent | File | Model | Specialty |
|-------|------|-------|-----------|
| aid-orchestrator | `.claude/agents/aid-orchestrator.md` | sonnet | Pipeline coordination, routing, human gates |
| aid-researcher | `.claude/agents/aid-researcher.md` | opus | Investigation, KB generation, analysis (parameterized doc-set) |
| aid-interviewer | `.claude/agents/aid-interviewer.md` | opus | Adaptive dialogue, requirements gathering |
| aid-architect | `.claude/agents/aid-architect.md` | opus | Design: specs, plans, task decomposition |
| aid-developer | `.claude/agents/aid-developer.md` | sonnet | Code implementation, data migrations, CI/CD config |
| aid-reviewer | `.claude/agents/aid-reviewer.md` | opus | Adversarial issue-finding; grade computed by `grade.sh` |
| aid-operator | `.claude/agents/aid-operator.md` | sonnet | Deployment, PR creation, releases |
| aid-tech-writer | `.claude/agents/aid-tech-writer.md` | sonnet | User-facing documentation, API docs, changelogs |
| aid-clerk | `.claude/agents/aid-clerk.md` | haiku | Mechanical utility: extract, format, or glob (operation parameter) |

## Skills

108 skills total: 14 curated skills — the pipeline phase skills, the optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base, the on-demand `aid-housekeep`, `aid-update-kb`, `aid-set-connector`, and `aid-unset-connector` skills, and the `/aid-triage` router — plus the 94-row shortcut catalog's skills: 64 verb-first shortcut doorways and 30 hand-authored `repurpose` skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, and the re-registered `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask`). `/aid-triage` is a stateless, suggest-only router: it reads one free-form description and suggests either the matching shortcut, the full `aid-describe` path, or — when the input reads as a question — `/aid-ask`, writing nothing itself. `/aid-ask` is a friendly-named Q&A alias of the classic `aid-query-kb` skill. The shortcuts (`aid-fix`, `aid-create-api`, `aid-change-ui`, `aid-refactor`, `aid-review`, `aid-remove`, `aid-migrate`, …) are direct-entry doorways that skip straight to a flattened Lite work for a single named change. Each skill lives in `.claude/skills/aid-<name>/SKILL.md`.

Notable mechanisms:
- **aid-execute** uses an `agents:` selector that picks the executor by task type (RESEARCH→aid-researcher, IMPLEMENT→aid-developer, etc.) and aid-reviewer for grading. Grade is computed by `.claude/aid/scripts/grade.sh` from the Reviewer's structured issue list.
- **aid-discover** runs `.claude/aid/scripts/kb/build-project-index.sh` as a Step 0c pre-pass before dispatching aid-researcher with parameterized doc-sets in parallel — eliminates duplicated file-reading.

## Usage

### Skills
Skills are loaded automatically when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields that Claude Code uses for skill selection.

### Agents
Agent files define specialized roles with constrained tool access and focused system prompts. Skills with multiple agent options use an `agents:` block in frontmatter and a selector table in the body.

### Utility Sub-Agent
`aid-clerk` is not invoked at the skill layer. Core agents call it internally to offload mechanical work (extraction, template-fill, file enumeration) to the Small tier. The caller passes an `operation:` parameter (extract / format / glob) and validates the output.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required; `agents:` block optional) — lives in `.claude/skills/`
- **Agents:** Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`) — lives in `.claude/agents/`

## Notes

- Skills are optimized for LLM context windows — concise, no verbose explanations
- Authoring sources live in the methodology repo under `canonical/skills/` and `canonical/agents/`
- Templates install to `.claude/aid/templates/` and bash helpers to `.claude/aid/scripts/`
- The grading script (`.claude/aid/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
