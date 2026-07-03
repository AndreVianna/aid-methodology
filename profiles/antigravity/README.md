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
- `.agent/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (14 skills: 11 across five pipeline groups + 3 off-pipeline on-demand)
- `.agent/agents/{name}.md` — Agent definitions in Markdown format (9 agents with `aid-` prefix)
- `.agent/aid/templates/` — Templates (grading rubric, settings schema); `.agent/aid/scripts/` — bash helpers (`grade.sh`, `kb/build-project-index.sh`); `.agent/aid/recipes/` — lite-path recipes
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

14 skills total: the pipeline phase skills, the optional `aid-summarize` for generating a single-file visual HTML summary of the Knowledge Base; plus the on-demand `aid-housekeep`, `aid-query-kb`, and `aid-update-kb` skills. Each skill lives in `.agent/skills/aid-<name>/SKILL.md`.

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
