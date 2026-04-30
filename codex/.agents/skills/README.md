# AID Skills for Codex CLI

11 skills in AgentSkills format (10 pipeline + 1 optional). Each `SKILL.md` contains YAML frontmatter with `name`, `description`, and `metadata.short-description` fields.

## Skills

| Skill | Phase | Description |
|-------|-------|-------------|
| `aid-init` | 0. Init | Initialize AID project — scaffold .aid/knowledge/ with 16 KB templates, set up AGENTS.md |
| `aid-discover` | 1. Discover | Brownfield project discovery → populate Knowledge Base (14 documents) |
| `aid-interview` | 2. Interview | Adaptive requirements gathering → REQUIREMENTS.md |
| `aid-specify` | 3. Specify | Requirements → SPEC.md grounded in KB |
| `aid-plan` | 4. Plan | SPEC.md → high-level roadmap (PLAN.md) |
| `aid-detail` | 5. Detail | PLAN.md → user stories, tasks, execution waves |
| `aid-execute` | 6. Implement | TASK → code with build verification |
| `aid-execute` | 8. Test | Staging validation — E2E, integration, manual |
| `aid-deploy` | 9. Deploy | Final verification, PR, KB updates |
| `aid-monitor` | 8. Monitor | Orchestrator | Observe, classify, route production findings |

### Optional

| Skill | When | Description |
|-------|------|-------------|
| `aid-summarize` | After `/aid-discover` reaches DONE | Generate single-file `knowledge-summary.html` from `.aid/knowledge/` — offline-capable, light/dark theme, accessibility-first (WCAG AA), Mermaid diagrams. Idempotent. |

## Usage

Skills are loaded as context when matched by description. Skill bodies are identical in structure to the Claude Code versions — AgentSkills is a shared standard.

See the repo's [`skills/`](../../skills/README.md) directory for human-readable documentation with rationale and examples.
