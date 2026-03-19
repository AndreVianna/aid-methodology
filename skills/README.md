# AID Skills — Human Reference

Each skill represents one phase of the AID pipeline. These README files provide rich, human-readable documentation — rationale, examples, and detailed explanations.

> **Looking for LLM-optimized versions?** See [`claude-code/skills/`](../claude-code/skills/) for Claude Code or [`codex/skills/`](../codex/skills/) for OpenAI Codex.

---

## The 12 Skills

### Group 1: Problem Mapping

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-discover](aid-discover/README.md) | 1. Discover | Analyze an existing codebase and produce a structured Knowledge Base |
| [aid-interview](aid-interview/README.md) | 2. Interview | Gather requirements through adaptive, one-question-at-a-time conversation |

### Group 2: Planning

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-specify](aid-specify/README.md) | 3. Specify | Transform requirements into a grounded SPEC.md anchored in the KB |
| [aid-plan](aid-plan/README.md) | 4. Plan | Define MVP scope, modules, deliverables — strategy, not tactics |
| [aid-detail](aid-detail/README.md) | 5. Detail | Decompose the plan into user stories, tasks, and execution waves |

### Group 3: Implementation

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-implement](aid-implement/README.md) | 6. Implement | Execute a task by spawning a coding agent with full KB context |
| [aid-review](aid-review/README.md) | 7. Review | Spec-anchored code review with A+ to F grading and auto-fix |
| [aid-test](aid-test/README.md) | 8. Test | Staging validation — E2E, integration, manual testing |

### Group 4: Production

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-deploy](aid-deploy/README.md) | 9. Deploy | Final verification, PR creation, KB update, delivery summary |
| [aid-track](aid-track/README.md) | 10. Track | Interpret production telemetry — not just collect, understand |

### Group 5: Maintenance

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-triage](aid-triage/README.md) | 11. Triage | Classify production findings and route them (BUG → Correct, CR → Discover) |
| [aid-correct](aid-correct/README.md) | 12. Correct | Root cause analysis, patch scope definition, hand off to Implement |

---

## Starting Point

```
Is there existing code?
  YES → Start with aid-discover (Phase 1)
  NO  → Start with aid-interview (Phase 2)
```

## Incremental Adoption

You don't need all 12 phases from day one:

1. **Start:** Detail + Implement (formalize task decomposition and agent execution)
2. **Add:** Review (introduce grading and spec-anchored review)
3. **Add:** Test (staging validation gate)
4. **Add:** Plan (separate strategy from tactics)
5. **Add:** Discover (for next brownfield project)
6. **Add:** Interview (for next client engagement)
7. **Add:** Track + Triage (once shipping regularly)
8. **Add:** Correct (close the bug loop)
9. **Full pipeline:** All 12 phases with feedback loops
