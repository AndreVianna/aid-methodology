# AID Skills — Human Reference

Each skill represents one phase of the AID pipeline. These README files provide rich, human-readable documentation — rationale, examples, and detailed explanations.

> **Looking for LLM-optimized versions?** See [`claude-code/skills/`](../claude-code/skills/) for Claude Code or [`codex/skills/`](../codex/skills/) for OpenAI Codex.

---

## The Skills

### Setup (run once, before the pipeline)

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-init](aid-init/README.md) | 0. Init | Initialize a project: collect metadata, scaffold KB structure, create AGENTS.md and CLAUDE.md placeholders |

> Run `/aid-init` before Discovery (brownfield) or Interview (greenfield). It creates the `.aid/knowledge/` directory with 16 empty KB templates and all required placeholders. This is bootstrapping — not a methodology phase.

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
| [aid-detail](aid-detail/README.md) | 5. Detail | Decompose deliverables into small, sequential, typed tasks |

### Group 3: Execute

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-execute](aid-execute/README.md) | 6. Execute | Type-aware task execution (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE) with built-in review |

### Group 4: Deliver

| Skill | Phase | Purpose |
|-------|-------|---------|
| [aid-deploy](aid-deploy/README.md) | 7. Deploy | Final verification, PR creation, KB update, delivery summary |
| [aid-monitor](aid-monitor/README.md) | 8. Monitor | Observe production, classify findings (BUG/CR/Infra/No Action), route actions |

### Optional (runs after Discovery)

| Skill | When | Purpose |
|-------|------|---------|
| `aid-summarize` | After `/aid-discover` reaches DONE and the KB is approved | Generate a single-file `knowledge-summary.html` from `.aid/knowledge/` — offline, light/dark theme, accessibility-first (WCAG AA), Mermaid diagrams. Idempotent: re-running on an unchanged KB is a no-op. |

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

You don't need all 8 phases from day one:

1. **Start:** Detail + Execute (formalize task decomposition and agent execution)
2. **Add:** Review (introduce grading and spec-anchored review)
3. **Add:** Test (staging validation gate)
4. **Add:** Plan (separate strategy from tactics)
5. **Add:** Discover (for next brownfield project)
6. **Add:** Interview (for next client engagement)
7. **Add:** Track + Triage (once shipping regularly — Triage includes root cause analysis for bugs)
8. **Full pipeline:** All 8 phases with feedback loops
