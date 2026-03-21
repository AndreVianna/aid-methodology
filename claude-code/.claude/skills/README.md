# AID Skills for Claude Code

11 phase skills in AgentSkills format. Each `SKILL.md` contains YAML frontmatter with `name`, `description`, `allowed-tools`, `context`, and `agent` fields.

## Skills

| Skill | Phase | Agent | Description |
|-------|-------|-------|-------------|
| `aid-discover` | 1. Discover | Researcher | Brownfield codebase analysis → Knowledge Base |
| `aid-interview` | 2. Interview | Interviewer | Adaptive requirements gathering → REQUIREMENTS.md |
| `aid-specify` | 3. Specify | Architect | Requirements → SPEC.md grounded in KB |
| `aid-plan` | 4. Plan | Architect | SPEC.md → high-level roadmap (PLAN.md) |
| `aid-detail` | 5. Detail | Architect | PLAN.md → user stories, tasks, execution waves |
| `aid-implement` | 6. Implement | Developer | TASK → code with build verification |
| `aid-review` | 7. Review | Critic | Spec-anchored review with A+ to F grading |
| `aid-test` | 8. Test | Critic | Staging validation — E2E, integration, manual |
| `aid-deploy` | 9. Deploy | Operator | Final verification, PR, KB updates |
| `aid-track` | 10. Track | Researcher | Production telemetry interpretation |
| `aid-triage` | 11. Triage | Orchestrator | Root cause analysis + classify findings → route to implement or discover |

## Usage

Skills are loaded automatically when matched by description. The `context: fork` field means each skill runs in an isolated subagent context.

See the repo's [`skills/`](../../skills/README.md) directory for human-readable documentation with rationale and examples.
