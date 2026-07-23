# AID for OpenAI Codex CLI

Install the persistent `aid` CLI once per machine, then add this profile inside your project:

## Setup

```bash
# 1. Bootstrap the aid CLI (once per machine)
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash

# 2. Add the profile inside your project
aid add codex

# Manual copy alternative (from a repo checkout)
cp -r path/to/aid-methodology/profiles/codex/.codex    .codex/
cp    path/to/aid-methodology/profiles/codex/AGENTS.md  AGENTS.md
```

See the repo README for npm / pipx / offline install options.

This gives you:
- `.codex/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (111 skills: 17 curated pipeline / on-demand / router skills plus the 94-row shortcut catalog's skills — 64 verb-first shortcut doorways + 30 hand-authored repurpose skills)
- `.codex/agents/{name}.toml` — Agent definitions in Codex TOML format (9 agents with `aid-` prefix)
- `.codex/aid/scripts/`, `.codex/aid/templates/` — AID-own support files
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Model Tiers

For Codex, the AID model tier matrix maps to OpenAI models as:

| Tier | Model | Reasoning Effort | When |
|------|-------|------------------|------|
| Large | `gpt-5.5` | `high` | Foundational/adversarial/judgment-heavy work |
| Medium | `gpt-5.4` | `medium` | Production work with structured inputs |
| Small | `gpt-5.4-mini` | `low` | Mechanical sub-tasks (extraction, formatting, enumeration) |

The Reviewer ≥ Executor invariant is enforced: the agent that grades is never below the agent it grades.

## Agents

| Agent | File | Model | Reasoning | Specialty |
|-------|------|-------|-----------|-----------|
| aid-orchestrator | `.codex/agents/aid-orchestrator.toml` | gpt-5.4 | medium | Pipeline coordination, routing, human gates |
| aid-researcher | `.codex/agents/aid-researcher.toml` | gpt-5.5 | high | Investigation, KB generation, analysis (parameterized doc-set) |
| aid-interviewer | `.codex/agents/aid-interviewer.toml` | gpt-5.5 | high | Adaptive dialogue, requirements gathering |
| aid-architect | `.codex/agents/aid-architect.toml` | gpt-5.5 | high | Design: specs, plans, task decomposition |
| aid-developer | `.codex/agents/aid-developer.toml` | gpt-5.4 | medium | Code implementation, data migrations, CI/CD config |
| aid-reviewer | `.codex/agents/aid-reviewer.toml` | gpt-5.5 | high | Adversarial issue-finding; grade computed by `grade.sh` |
| aid-operator | `.codex/agents/aid-operator.toml` | gpt-5.4 | medium | Deployment, PR creation, releases |
| aid-tech-writer | `.codex/agents/aid-tech-writer.toml` | gpt-5.4 | medium | User-facing documentation, API docs, changelogs |
| aid-clerk | `.codex/agents/aid-clerk.toml` | gpt-5.4-mini | low | Mechanical utility: extract, format, or glob (operation parameter) |

## Skills

111 skills total: 17 curated skills — the pipeline phase skills, the optional `aid-summarize` for
generating a single-file visual HTML summary of the Knowledge Base, the
on-demand `aid-housekeep`, `aid-update-kb`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, and `aid-update-ticket` skills, and the `/aid-triage` router — plus the 94-row shortcut catalog's skills: 64 verb-first shortcut doorways and 30 hand-authored `repurpose` skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, and the re-registered `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask`). `/aid-triage` is a stateless, suggest-only router: it reads one free-form description and suggests either the matching shortcut, the full `aid-describe` path, or — when the input reads as a question — `/aid-ask`, writing nothing itself. `/aid-ask` is a friendly-named Q&A alias of the classic `aid-query-kb` skill. The shortcuts (`aid-fix`, `aid-create-api`, `aid-change-ui`, `aid-refactor`, `aid-review`, `aid-remove`, `aid-migrate`, …) are direct-entry doorways that skip straight to a flattened Lite work for a single named change. Each skill lives in `.codex/skills/aid-<name>/SKILL.md` — Codex reads skills from this directory.

Notable mechanisms:
- **aid-execute** uses an `agents:` selector that picks the executor by task type (RESEARCH→aid-researcher, IMPLEMENT→aid-developer, etc.) and aid-reviewer for grading. Grade is computed by `.codex/aid/scripts/grade.sh` from the Reviewer's structured issue list.
- **aid-discover** runs `.codex/aid/scripts/kb/build-project-index.sh` as a Step 0c pre-pass before dispatching aid-researcher with parameterized doc-sets in parallel.

## Usage

### Skills
Skills are loaded as context when matched by description. Each SKILL.md contains YAML frontmatter with `name` and `description` fields for skill selection.

### Agents
Agent TOML files define specialized roles with focused system prompts. Skills with multiple agent options use an `agents:` block in frontmatter and a selector table in the body.

The `aid-config` skill bootstraps project settings (`.aid/settings.yml`) before the pipeline begins; `AGENTS.md` is installed by the AID installer. The `aid-discover` skill runs the file-index pre-pass, then dispatches `aid-researcher` with parameterized doc-sets for KB generation, then uses `aid-reviewer` for quality gating.

## File Format

- **Skills:** Markdown with YAML frontmatter (`name`, `description` required; `agents:` block optional) — lives in `.codex/skills/`
- **Agents:** TOML with `name`, `description`, `developer_instructions`, `model`, and `model_reasoning_effort` fields — lives in `.codex/agents/`

## Notes

- Skill bodies are shared with the claude-code versions; frontmatter uses Codex-specific fields
- Authoring sources live in the methodology repo under `canonical/skills/` and `canonical/agents/`
- Templates and scripts live in `.codex/aid/` (and the source-of-truth at `canonical/` in the AID repo)
- The grading script (`.codex/aid/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
