# AID for Antigravity

Install the persistent `aid` CLI once per machine, then add this profile inside your project:

## Setup

```bash
# 1. Bootstrap the aid CLI (once per machine)
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash

# 2. Add the profile inside your project
aid add antigravity

# Manual copy alternative (from a repo checkout)
cp -r path/to/aid-methodology/profiles/antigravity/.agent    .agent/
cp    path/to/aid-methodology/profiles/antigravity/AGENTS.md   AGENTS.md
```

See the repo README for npm / pipx / offline install options.

This gives you:
- `.agent/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (111 skills: 17 curated pipeline / on-demand / router skills plus the 94-row shortcut catalog's skills — 64 verb-first shortcut doorways + 30 hand-authored repurpose skills)
- `.agent/agents/{name}.md` — Agent definitions in Markdown format (9 agents with `aid-` prefix)
- `.agent/aid/templates/` — Templates (grading rubric, settings schema); `.agent/aid/scripts/` — bash helpers (`grade.sh`, `kb/build-project-index.sh`)
- `AGENTS.md` — Project context for AI agents (edit with your project details)

## Model Tiers

For Antigravity, the AID model tier matrix maps to Gemini models as:

| Tier | Model | Reasoning Effort | When |
|------|-------|------------------|------|
| Large | `gemini-3-pro` | `high` | Foundational/adversarial/judgment-heavy work |
| Medium | `gemini-3-pro` | `low` | Production work with structured inputs |
| Small | `gemini-3-flash` | `low` | Mechanical sub-tasks (extraction, formatting, enumeration) |

The Reviewer ≥ Executor invariant is enforced: the agent that grades is never below the agent it grades.

## Skills

111 skills total: 17 curated skills — the pipeline phase skills, the optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base, the on-demand `aid-housekeep`, `aid-update-kb`, `aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`, and `aid-update-ticket` skills, and the `/aid-triage` router — plus the 94-row shortcut catalog's skills: 64 verb-first shortcut doorways and 30 hand-authored `repurpose` skills (`aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, and the re-registered `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask`). `/aid-triage` is a stateless, suggest-only router: it reads one free-form description and suggests either the matching shortcut, the full `aid-describe` path, or — when the input reads as a question — `/aid-ask`, writing nothing itself. `/aid-ask` is a friendly-named Q&A alias of the classic `aid-query-kb` skill. The shortcuts (`aid-fix`, `aid-create-api`, `aid-change-ui`, `aid-refactor`, `aid-review`, `aid-remove`, `aid-migrate`, …) are direct-entry doorways that skip straight to a flattened Lite work for a single named change. Each skill lives in `.agent/skills/aid-<name>/SKILL.md`.

### Phase Flow

```
aid-config (bootstrap)
   → Discover → Describe (2a) → Define (2b) → Specify → Plan → Detail → Execute
   → optional Deliver: Deploy · Monitor
   ↑
   └── feedback loops: Q&A entries, IMPEDIMENT.md
```

## Notes

- Skill bodies are shared across the tool profiles; frontmatter uses each tool's conventions
- Authoring sources live in the methodology repo under `canonical/skills/` and `canonical/agents/`
- Templates install to `.agent/aid/templates/` and bash helpers to `.agent/aid/scripts/`
- The grading script (`.agent/aid/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
