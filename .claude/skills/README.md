# AID Skills for Claude Code

14 skills in AgentSkills format (11 across five pipeline groups + 3 off-pipeline on-demand). Each `SKILL.md` contains YAML frontmatter with `name`, `description`, `allowed-tools`, `context`, and `agent` fields.

## Skills

| Skill | Phase | Agent | Description |
|-------|-------|-------|-------------|
| `aid-init` | 0. Init | Orchestrator | Initialize project — greenfield/brownfield, scaffold KB, collect metadata |
| `aid-discover` | 1. Discover | Researcher | Brownfield project discovery with quality gate (GENERATE → REVIEW → Q&A → FIX → APPROVAL → DONE) |
| `aid-describe` | 2a. Describe | Interviewer | Adaptive requirements gathering (seasoned-analyst engine) → REQUIREMENTS.md |
| `aid-define` | 2b. Define | Architect | Decompose approved requirements into features + cross-reference |
| `aid-specify` | 3. Specify | Architect | Requirements → SPEC.md grounded in KB |
| `aid-plan` | 4. Plan | Architect | SPEC.md → high-level roadmap (PLAN.md) |
| `aid-detail` | 5. Detail | Architect | PLAN.md → user stories, tasks, execution waves |
| `aid-execute` | 6. Implement | Developer | TASK → code with build verification |
| `aid-execute` | 8. Test | Reviewer | Staging validation — E2E, integration, manual |
| `aid-deploy` | 9. Deploy | Operator | Final verification, PR, KB updates |
| `aid-monitor` | 8. Monitor | Orchestrator | Observe, classify, route production findings |

### Optional

| Skill | When | Agent | Description |
|-------|------|-------|-------------|
| `aid-summarize` | After `/aid-discover` reaches DONE | Researcher | Generate single-file `knowledge-summary.html` from `.aid/knowledge/` — offline-capable, light/dark theme, accessibility-first (WCAG AA), Mermaid diagrams. Idempotent. |

## Usage

Skills are loaded automatically when matched by description. The `context: fork` field means each skill runs in an isolated subagent context.

See the repo's [`skills/`](../../skills/aid-README.md) directory for human-readable documentation with rationale and examples.
