# AID Skills for Cursor

12 phase skills in AgentSkills format. Each `SKILL.md` contains YAML frontmatter with `name`, `description`, and `allowed-tools` fields.

## Skills

| Skill | Phase | Description |
|-------|-------|-------------|
| `aid-init` | 0. Init | Initialize AID project — scaffold .aid/knowledge/ with 15 KB templates, set up AGENTS.md |
| `aid-discover` | 1. Discover | Brownfield project discovery → populate Knowledge Base (14 documents) |
| `aid-interview` | 2. Interview | Adaptive requirements gathering → REQUIREMENTS.md |
| `aid-specify` | 3. Specify | Requirements → SPEC.md grounded in KB |
| `aid-plan` | 4. Plan | SPEC.md → high-level roadmap (PLAN.md) |
| `aid-detail` | 5. Detail | PLAN.md → user stories, tasks, execution waves |
| `aid-implement` | 6. Implement | TASK → code with build verification |
| `aid-review` | 7. Review | Spec-anchored review with A+ to F grading |
| `aid-test` | 8. Test | Staging validation — E2E, integration, manual |
| `aid-deploy` | 9. Deploy | Final verification, PR, KB updates |
| `aid-track` | 10. Track | Production telemetry interpretation |
| `aid-triage` | 11. Triage | Root cause analysis + classify findings → route to implement or discover |

## Usage

Skills are loaded as context when matched by description. Cursor uses the `Task` tool (when available) to dispatch specialist agents. If the Task tool is unavailable, skills fall back to sequential execution in the main context.

## Phase Flow

```
Init → Discover → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy
  ↑                                                                                    │
  └──────────────────────── feedback loops (GAP.md, IMPEDIMENT.md, TRACK-REPORT.md) ──┘
```

See the repo's [`skills/`](../../skills/README.md) directory for human-readable documentation with rationale and examples.
