# Technical Specification — Conversational Refinement

Specify the technical implementation of a single feature through conversational collaboration with the developer. The agent acts as a tech lead — reads KB, Requirements, codebase, and proposes concrete solutions. The developer validates, redirects, or deepens the discussion.

## Core Principle

**Specify is Agile refinement for AI-augmented teams.** Interview captured *what* the stakeholder wants. Specify determines *how* to build it — one feature at a time, through discussion with the developer.

The agent doesn't ask generic questions ("what technology do you want to use?"). It proposes based on what the KB and codebase already show: "I see you use Spring Boot with JPMS modules. Here's how this feature fits into the existing module structure." The developer validates, not dictates.

## What Changed from V2

In V2, Specify generated a standalone `SPEC.md` from `REQUIREMENTS.md` — Vision, Constraints, Architecture, Domain Model, NFRs. A monolithic document produced in one pass.

In V3, the spec is per-feature and conversational:
- Each feature has its own `SPEC.md` (created by Interview with requirements side, enriched by Specify with technical side).
- The agent proposes one section at a time, discusses with the developer, then writes.
- Vision, Constraints, and NFRs stay in REQUIREMENTS.md where they belong.
- Module mapping, test scenarios, and per-feature risks are covered here — Plan doesn't duplicate them.

## Workspace

```
aid-workspace/
  knowledge/                    ← shared KB (read)
  work-NNN-{name}/
    REQUIREMENTS.md             ← stakeholder requirements (read)
    features/
      feature-NNN-{name}/
        SPEC.md                 ← requirements (from Interview) + technical spec (Specify writes here)
        STATE.md                ← process state (section status, Q&A, loopbacks)
```

## When to Use

- **Primary:** After Interview has decomposed requirements into features. Run once per feature.
- **Re-entry:** When a downstream phase (Plan, Detail, Implement) writes a Q&A entry to a feature's STATE.md because the SPEC is ambiguous or incomplete.

## Inputs

- **SPEC.md** — the feature's requirements side (description, user stories, acceptance criteria).
- **REQUIREMENTS.md** — full requirements context for cross-reference.
- **Knowledge Base** — always read: architecture.md, technology-stack.md, coding-standards.md, module-map.md, data-model.md. Conditionally: api-contracts.md, integration-map.md, security-model.md, domain-glossary.md, test-landscape.md, infrastructure.md.
- **Codebase** — explored via grep/glob to ground proposals in actual code.

## Technical Sections

### Core (always present)

| Section | Content |
|---------|---------|
| **Data Model** | Tables, columns, types, constraints, FKs, indices — or "no schema changes" |
| **Feature Flow** | Technical flowchart: request → service → repo → response |
| **Layers & Components** | What goes in each layer, dependencies, DI registrations |

### Conditional (activated by context)

Each has an auto-activation rule (obvious from KB/codebase — just include) and a default question (not obvious — ask the developer):

| Section | Auto-activate when... |
|---------|----------------------|
| API Contracts | KB or requirements mention endpoints/API |
| UI Specs | Requirements mention screens/UI |
| Events & Messaging | KB has queues/events or requirements mention async |
| DDD Analysis | KB indicates DDD/bounded contexts |
| BDD Scenarios | Requirements indicate BDD/Gherkin |
| CQRS Specs | KB shows CQRS pattern |
| State Machines | Requirements describe stateful workflows |
| Security Specs | Requirements mention auth/roles/permissions |
| Migration Plan | Brownfield + schema changes in Data Model |
| Cache Strategy | Requirements mention performance/caching |
| External Integrations | Requirements mention 3rd party services |
| Batch/Jobs | Requirements mention scheduled processing |
| Mobile Specs | Requirements target mobile platforms |
| Search/Indexing | Requirements mention search/complex filtering |
| AI Enhancements | Requirements mention AI/ML/LLM |
| Telemetry & Tracking | Not obvious from context |
| Recovery Management | Not obvious from context |
| Cloud Support | Requirements mention deploy/cloud |
| Hardware Requirements | Not obvious from context |

The agent auto-activates what's obvious and asks about the rest — all ambiguous questions at once, not one-by-one.

## Process

### The Discussion Loop

For each activated section:

1. **Propose** — The agent proposes a concrete solution referencing specific files, classes, patterns, and conventions from the codebase. Not generic — grounded.
2. **Discuss** — Free-form conversation. The developer may agree, adjust, redirect, ask questions, or raise concerns. The agent presents trade-offs and options.
3. **Write** — When agreed, the section is written to SPEC.md under `## Technical Specification`. STATE.md is updated.
4. **Next** — Move to the next pending section, or finish if all complete.

### Proposal Quality

Good proposals:
- Reference specific files, classes, and patterns from the codebase.
- Follow conventions from `coding-standards.md`.
- Fit into the architecture from `architecture.md`.
- Use domain terms from `domain-glossary.md`.
- Call out explicitly when something existing needs to change.

Bad proposals:
- "Use repository pattern" — which repository? Where? Following what convention?
- Generic solutions that could apply to any project.
- Walls of specification without discussion.

## Handling Outcomes

During discussion, the agent may discover problems beyond this feature:

| Situation | Action |
|-----------|--------|
| **KB is wrong (simple fix)** | Fix the KB document directly, note in STATE.md Change Log |
| **KB needs re-discovery** | Write Q&A entry to DISCOVERY-STATE.md, continue with unblocked sections |
| **Requirements are wrong (simple fix)** | Fix REQUIREMENTS.md and SPEC.md directly, add Change Log entries |
| **Requirements need re-interview** | Write Q&A entry to INTERVIEW-STATE.md |
| **Spike needed** | Record what/why/scope in STATE.md, pause feature |
| **Feature needs splitting** | Create new feature folders, redistribute content |
| **Feature needs merging** | Merge into target, delete current |

## Greenfield KB Seeding

For greenfield projects where KB documents are empty: technical decisions made during specification are written back to the KB. Data Model decisions → update `data-model.md`. Architecture choices → update `architecture.md`. This is how greenfield projects build their KB incrementally through specification.

## Output

`## Technical Specification` section added to `aid-workspace/{work}/features/feature-NNN/SPEC.md`:

```markdown
---
## Technical Specification

### Data Model
{Tables, columns, constraints, indices}

### Feature Flow
{Request → service → repo → response}

### Layers & Components
{Layer assignments, dependencies, DI registrations}

### {Conditional sections as activated}
...

### Change Log
| Date | Change | Source |
|------|--------|--------|
```

The SPEC.md now contains both requirements (from Interview) and technical specification — a complete feature definition.

## Conversation Style

The agent is a **technical collaborator**, not an interviewer or a generator.

**The rhythm:**
```
Agent: [reads context] "I think this fits like {proposal}. Based on {KB evidence}."
Dev:   "Actually, we should do X because Y."
Agent: "Good point. That means we also need to change Z. Here's the updated approach..."
Dev:   "Yeah, that works."
Agent: [writes section] [moves to next]
```

The agent pushes back when the developer proposes something that contradicts KB patterns. It admits when it doesn't know. It asks follow-up questions when the developer's answer opens new technical questions.

## Feedback Loops

### → Discovery

KB is wrong or incomplete for this feature's domain. Write Q&A to `DISCOVERY-STATE.md` with context from the discussion.

### → Interview

Requirements are wrong, incomplete, or contradictory. Write Q&A to `INTERVIEW-STATE.md` with the specific gap.

### ← Plan / Detail / Implement

Downstream phases find the SPEC ambiguous or incomplete. They write Q&A to this feature's `STATE.md`. Next Specify run picks up the questions.

## Re-run = Review

Running `/aid-specify` on a feature that already has Status: Ready triggers a **review** instead of starting over.

The agent re-reads the current KB, codebase, and requirements, then compares against the existing technical specification. This catches:

- **KB drift** — KB documents updated by re-discovery since the spec was written
- **Requirements drift** — REQUIREMENTS.md changed since the spec was written
- **Codebase drift** — code changed by another feature's implementation
- **Missing sections** — new conditional sections that should now be activated
- **Stale sections** — sections that contradict what now exists

**Grading:**

| Grade | Meaning | Action |
|-------|---------|--------|
| A | Spec is current | No changes needed |
| B | Minor drift (1–3 updates) | Fix inline |
| C | Significant drift (4+ updates or section rewrite) | Re-enter Discussion Loop for affected sections |
| D | Major drift (core assumptions invalidated) | Recommend `--reset` and re-specify |

This is the same pattern as Discovery (re-run → grade → fix) and Interview (re-run → cross-reference → grade). **Every content phase can validate itself.**

## Quality Checklist

- [ ] All activated sections have content under `## Technical Specification`.
- [ ] No placeholder text remaining.
- [ ] Technical sections reference KB documents and codebase locations.
- [ ] Change Log has entries for each section written.
- [ ] Proposals were discussed, not just generated.
- [ ] KB seeded for greenfield projects where decisions were made.

## Related Phases

- **Previous:** [Interview](../aid-interview/) — provides REQUIREMENTS.md and feature SPEC.md stubs
- **Next:** [Plan](../aid-plan/) — sequences specified features into deliverables
- **Triggered by:** Q&A entries from Plan, Detail, or Implement

## See Also

- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
