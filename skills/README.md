# AID Skills — Human Reference

Each skill represents one phase of the AID pipeline. These README files provide rich, human-readable documentation — rationale, examples, and detailed explanations.

> **Looking for LLM-optimized versions?** See [`claude-code/skills/`](../claude-code/skills/) for Claude Code or [`codex/skills/`](../codex/skills/) for OpenAI Codex.

---

## The 12 Skills

### Setup (run once, before the pipeline)

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-init](aid-init/README.md) | 0. Init | Initialize a project: collect metadata, scaffold KB structure, create AGENTS.md and CLAUDE.md placeholders |

> Run `/aid-init` before Discovery (brownfield) or Interview (greenfield). It creates the `aid-workspace/knowledge/` directory with 14 empty KB templates and all required placeholders. This is bootstrapping — not a methodology phase.

### Group 1: Define

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-discover](aid-discover/README.md) | 1. Discover | Analyze an existing codebase and produce a structured Knowledge Base |
| [aid-interview](aid-interview/README.md) | 2. Interview | Gather requirements and decompose into features through adaptive conversation |
| [aid-specify](aid-specify/README.md) | 3. Specify | Technical refinement per feature — tech lead proposes, developer discusses |

### Group 2: Map

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-plan](aid-plan/README.md) | 4. Plan | Sequence features into deliverables — each one a functional MVP |
| [aid-detail](aid-detail/README.md) | 5. Detail | Decompose the plan into user stories, tasks, and execution waves |

### Group 3: Execute

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-implement](aid-implement/README.md) | 6. Implement | Execute a task by spawning a coding agent with full KB context |
| [aid-review](aid-review/README.md) | 7. Review | Spec-anchored code review with A+ to F grading and auto-fix |
| [aid-test](aid-test/README.md) | 8. Test | Staging validation — E2E, integration, manual testing |

### Group 4: Deliver

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-deploy](aid-deploy/README.md) | 9. Deploy | Final verification, PR creation, KB update, delivery summary |
| [aid-track](aid-track/README.md) | 10. Track | Interpret production telemetry — not just collect, understand |
| [aid-triage](aid-triage/README.md) | 11. Triage | Classify production findings, perform root cause analysis for bugs, and route (BUG → Implement, CR → Discover) |

---

## Starting Point

```
Every project:
  Run aid-init first (scaffolds KB, creates placeholders)
    ↓
  Is there existing code?
    YES → aid-discover (Phase 1)
    NO  → aid-interview (Phase 2)
```

## Incremental Adoption

You don't need all 11 phases from day one:

1. **Start:** Detail + Implement (formalize task decomposition and agent execution)
2. **Add:** Review (introduce grading and spec-anchored review)
3. **Add:** Test (staging validation gate)
4. **Add:** Plan (separate strategy from tactics)
5. **Add:** Discover (for next brownfield project)
6. **Add:** Interview (for next client engagement)
7. **Add:** Track + Triage (once shipping regularly — Triage includes root cause analysis for bugs)
8. **Full pipeline:** All 11 phases with feedback loops
