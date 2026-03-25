# aid-specify

Technical specification through conversational refinement, one feature at a time.

The agent acts as a tech lead — reads KB, Requirements, codebase, and proposes concrete solutions. The developer validates, redirects, or deepens the discussion. Writes to SPEC.md in the feature folder.

## The Universal Loop

Each technical section follows the same cycle:

```
1. PROPOSE  → agent proposes (grounded in KB, codebase, SPEC)
2. DISCUSS  → developer and agent refine together
3. WRITE    → save what was agreed to SPEC.md
4. REVIEW   → grade against KB/codebase reality — pass? next section. fail? back to 1.
```

**Re-run = enter at step 4 with existing content.**

## Usage

```
/aid-specify work-001/feature-001
/aid-specify feature-001              # shortcut when single work
/aid-specify work-001/feature-001 --reset
```

## Workspace

```
aid-workspace/
  knowledge/               ← shared KB
  work-NNN-{name}/
    REQUIREMENTS.md
    features/
      feature-NNN-{name}/
        SPEC.md            ← product (requirements + technical specification)
        STATE.md           ← process state (section status, Q&A, loopbacks)
```

## How It Works

### First Run

1. **Load context** — SPEC.md (requirements), REQUIREMENTS.md, KB docs, codebase
2. **Determine sections** — 3 core (Data Model, Feature Flow, Layers & Components) + up to 20 conditional sections auto-activated or asked via default questions
3. **Create STATE.md** — tracks section progress
4. **Run the loop** for each section:
   - **Propose:** concrete solution referencing specific files, classes, patterns
   - **Discuss:** free-form conversation until developer is satisfied
   - **Write:** save to SPEC.md, seed empty KB docs (greenfield)
   - **Review:** verify against KB reality and other sections — grade A/B/C

### Re-run (Review)

When STATUS is `Ready`, re-run enters the loop at step 4:
- Checks for KB drift, requirements drift, codebase drift, missing sections, stale content
- Grades A–D overall
- Re-enters the loop for sections needing updates

## Core Sections (always present)

| Section | Content |
|---------|---------|
| Data Model | Tables, columns, types, constraints, indices |
| Feature Flow | Request → service → repo → response |
| Layers & Components | What goes in each layer, DI registrations |

## Conditional Sections (20 available)

Each has an auto-activation rule and a default question for ambiguous cases:

API Contracts · UI Specs · Events & Messaging · DDD Analysis · BDD Scenarios · CQRS Specs · State Machines · Security Specs · Migration Plan · Cache Strategy · External Integrations · Batch/Jobs · Mobile Specs · Search/Indexing · AI Enhancements · Telemetry & Tracking · Recovery Management · Cloud Support · Hardware Requirements

## States

| State | Trigger | Action |
|-------|---------|--------|
| Initialize | No STATE.md | Load context, determine sections, start loop |
| Continue | In Discussion | Resume loop at first pending section |
| Spike Info | Spike Needed | Collect spike results, resume |
| Blocked | Loopback pending | Check upstream, unblock or wait |
| Review | Ready | Enter loop at step 4, grade A–D |

## Conversation Style

The agent is a **tech lead**, not an interviewer:
- Proposes based on what the KB and codebase show
- References specific files, classes, patterns
- Pushes back on contradictions
- Admits when unsure

## Feedback Loops

- **→ Discovery:** KB wrong → Q&A to DISCOVERY-STATE.md
- **→ Interview:** Requirements wrong → Q&A to INTERVIEW-STATE.md
- **→ Spike:** Investigation needed → pause, record, resume later
- **→ Split/Merge:** Feature scope → create/merge feature folders

## Greenfield KB Seeding

During Write, if technical decisions fill gaps in empty KB docs, the agent updates those KB docs. This is how greenfield projects build their KB incrementally through specification.
