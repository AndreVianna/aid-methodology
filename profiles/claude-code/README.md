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
- `.claude/skills/aid-{phase}/SKILL.md` — Phase instructions in AgentSkills format (14 skills: 11 across five pipeline groups + 3 off-pipeline on-demand)
- `.claude/agents/{name}.md` — Agent definitions in Claude Code format (9 agents with `aid-` prefix)
- `.claude/templates/` — Templates and bash scripts (grading rubric, `grade.sh`, `build-project-index.sh`)
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

14 skills total: the pipeline phase skills, the optional `aid-summarize` for generating
a single-file visual HTML summary of the Knowledge Base; plus the on-demand `aid-housekeep`, `aid-query-kb`, and `aid-update-kb` skills. See
[`.claude/skills/aid-README.md`](.claude/skills/aid-README.md) for the full list.

Notable mechanisms:
- **aid-execute** uses an `agents:` selector that picks the executor by task type (RESEARCH→aid-researcher, IMPLEMENT→aid-developer, etc.) and aid-reviewer for grading. Grade is computed by `templates/scripts/grade.sh` from the Reviewer's structured issue list.
- **aid-discover** runs `templates/scripts/build-project-index.sh` as a Step 0c pre-pass before dispatching aid-researcher with parameterized doc-sets in parallel — eliminates duplicated file-reading.

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
- Human-readable documentation lives in the repo's `skills/` and `agents/` directories
- Templates and scripts live in the repo's `templates/` directory — reference them from your project
- The grading script (`templates/scripts/grade.sh`) is deterministic — same issue list always produces the same grade
