---
name: aid-specify
description: >
  Technical specification through conversational refinement, one feature at a time.
  The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes
  technical solutions, and builds the spec collaboratively with the developer.
  Writes to SPEC.md in the feature folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "work-001/feature-001 (required)  [--reset] clear technical spec for this feature"
---

# Technical Specification — Conversational Refinement

Specify the technical implementation of a single feature through conversational refinement
with the developer.

**The agent is a tech lead, not an interviewer.** It proposes concrete solutions grounded
in the existing architecture. The developer validates, redirects, or deepens the discussion.

**One feature at a time.** The feature path is a required argument.

## The Loop

Every section follows the same cycle:

```
1. PROPOSE  → agent proposes (grounded in KB, codebase, SPEC)
2. DISCUSS  → developer and agent refine together
3. WRITE    → save what was agreed to SPEC.md
4. REVIEW   → grade what was written against KB/codebase reality
             → pass? next section. fail? back to 1.
```

**Re-run = enter at step 4 with existing content.**

**Workspace:**
```
.aid/
  knowledge/               ← shared KB
  work-NNN-{name}/
    REQUIREMENTS.md
    features/
      feature-NNN-{name}/
        SPEC.md            ← product (requirements + technical specification)
        STATE.md           ← process (section status, Q&A, loopbacks)
```

---

## ⚠️ Pre-flight Checks

### Check 1: Feature Path Required

If no feature path was provided, list available features across all works:

```
Usage: /aid-specify work-001/feature-001

Available features:
  work-001-user-auth/feature-001-login        [No STATE — not started]
  work-001-user-auth/feature-002-password      [In Discussion — 2/5 sections]
  work-002-reporting/feature-001-dashboard     [Ready ✅]
```

Scan all `.aid/work-*/features/feature-*/` directories.
For each, check if STATE.md exists and show status. Exit.

**Shortcut:** If only one work exists, accept bare `feature-001` and resolve automatically.

### Check 2: Feature Exists

Resolve the feature path using **prefix matching** (glob):
- `feature-001` → match `.aid/{work}/features/feature-001-*/SPEC.md`
- `work-001/feature-002` → match `.aid/work-001-*/features/feature-002-*/SPEC.md`

**If zero matches:** Exit with instruction to run `/aid-interview` first.
**If multiple matches:** List them, ask user to be more specific. Exit.
**If exactly one match:** Use that path. Print: `[Resolved: {full-path}]`

### Check 3: Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

---

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN/feature-NNN` | **Required.** Path to the feature to specify. |
| `feature-NNN` | Shortcut when only one work exists. |
| `--reset` | Clear `## Technical Specification` from SPEC.md and delete STATE.md. |

---

## State Detection

All paths relative to `.aid/{work}/features/{feature}/`.

```
State 1: No STATE.md                                        → INITIALIZE
State 2: STATE.md exists, Status: In Discussion              → CONTINUE
State 3: STATE.md exists, Status: Spike Needed               → SPIKE INFO
State 4: STATE.md exists, Status: Blocked (loopback pending) → BLOCKED
State 5: STATE.md exists, Status: Ready                      → REVIEW (enter loop at step 4)
```

Print: `[{work}/{feature}: {STATE}]`

---

## State 1: INITIALIZE

### Step 1: Load Full Context

Read ALL before making any proposal:

1. **SPEC.md** — the feature's requirements (description, user stories, acceptance criteria)
2. **REQUIREMENTS.md** — full requirements for cross-reference
3. **KB documents via INDEX.md:**
   - Always: `architecture.md`, `technology-stack.md`, `coding-standards.md`,
     `module-map.md`, `data-model.md`
   - If relevant: `api-contracts.md`, `integration-map.md`, `security-model.md`,
     `domain-glossary.md`, `test-landscape.md`, `infrastructure.md`
   - **Greenfield:** If KB docs are init placeholders (`❌ Pending`), treat as empty.
     Propose from scratch; decisions will seed KB during Write step.
4. **Codebase** — `Grep`/`Glob` to explore relevant source code. Skip for greenfield.

### Step 2: Determine Applicable Sections

**Core sections (always present unless truly N/A):**

| Section | Content |
|---------|---------|
| Data Model | Tables, columns, types, constraints, FKs, indices — or "no schema changes" |
| Feature Flow | Technical flowchart: request → service → repo → response |
| Layers & Components | What goes in each layer, dependencies, DI registrations |

**Conditional sections — activation rules:**

Each has two paths: **Auto-activate** (obvious from context) or **Ask** (use default question).

| Section | Auto-activate when... | Default question |
|---------|----------------------|------------------|
| API Contracts | KB/Requirements mention endpoints/API | Does this feature expose or modify any APIs? |
| UI Specs | Requirements mention screens/UI | Does this feature include UI changes? |
| Events & Messaging | KB has queues/events or async | Does this feature involve async processing or events? |
| DDD Analysis | KB/Requirements indicate DDD | Does the project follow DDD? Define bounded contexts? |
| BDD Scenarios | Requirements indicate BDD/Gherkin | Does the project use BDD? Write Gherkin scenarios? |
| CQRS Specs | KB shows CQRS pattern | Does this feature use Command/Query separation? |
| State Machines | Requirements describe stateful workflows | Any stateful workflows with defined transitions? |
| Security Specs | Requirements mention auth/roles | Specific auth/permission requirements beyond basic? |
| Migration Plan | Brownfield + schema changes | Does this change existing schemas or require migration? |
| Cache Strategy | Requirements mention performance | Performance requirements that may need caching? |
| External Integrations | Requirements mention 3rd party | Does this integrate with external services? |
| Batch/Jobs | Requirements mention scheduled work | Any scheduled jobs or background tasks? |
| Mobile Specs | Requirements target mobile | Mobile platforms? Offline-first? Platform-specific? |
| Search/Indexing | Requirements mention search | Full-text search or complex filtering needed? |
| AI Enhancements | Requirements mention AI/ML | AI or ML involved? (prompts, RAG, agents, fine-tuning) |
| Telemetry & Tracking | Not obvious | Specific logging, auditing, or alerting requirements? |
| Recovery Management | Not obvious | Disaster recovery or backup requirements? |
| Cloud Support | Requirements mention deploy/cloud | Specific cloud provider requirements? |
| Hardware Requirements | Not obvious | Particular hardware considerations? |

### Step 3: Create STATE.md

Create from template (`../templates/feature-state.md`):
- **Started:** today's date
- **Sections table:** each activated section, Status `Pending`, source (`core`/`auto`/`user-confirmed`)
- **Change Log:** initial entry

### Step 4: Present and Start

Present activated sections + ambiguous questions:

```
I've analyzed {feature} against the KB and codebase.

**Core sections:**
- Data Model — {brief rationale}
- Feature Flow — {brief rationale}
- Layers & Components — {brief rationale}

**Also activated:**
- {Section} — {why}

**Questions:**
1. {default question for ambiguous section}
2. ...

Does this look right? Answer the questions, and tell me if I'm missing anything.
```

Process response → update STATE.md → begin **The Loop** for first Pending section.

---

## State 2: CONTINUE

STATE.md exists, status "In Discussion." Find first `Pending` or `In Discussion` section.
Resume **The Loop** for that section.

---

## The Loop — Per Section

### 1. Propose

Read relevant KB and codebase for this section. Then:

```
### {Section Name}

Based on {KB evidence}, here's what I propose:

{Concrete technical proposal — specific files, classes, patterns from the codebase.
Reference conventions from coding-standards.md. Fit architecture.md. Use domain terms.
If changing something that exists, call it out.}

What do you think?
```

Update section status to `In Discussion` in STATE.md.

**Proposal quality rules:**
- Reference specific files, classes, patterns from the codebase
- Follow conventions from `coding-standards.md`
- Fit the architecture from `architecture.md`
- Use domain terms from `domain-glossary.md`
- Call out explicitly if changing something that exists

### 2. Discuss

Free-form conversation. The developer may:
- **Agree** → move to Write
- **Adjust** → revise proposal, present again
- **Redirect** → different approach. Adapt.
- **Ask questions** → answer from KB/codebase. If you don't know, say so.
- **Raise concerns** → discuss trade-offs with options and pros/cons

Continue until the developer is satisfied.

### 3. Write

When agreed:

1. Write section to SPEC.md under `## Technical Specification`
2. Update STATE.md: section status → `Written`
3. Add Change Log entry to SPEC.md
4. **KB Seeding (greenfield):** If the decision fills a gap in an empty KB doc,
   update that KB doc + INDEX.md + README.md. Log which KB docs were seeded.

### 4. Review

Immediately after writing, verify what was written:

- Does it contradict other completed sections in this SPEC?
- Does it align with KB reality (architecture, coding standards, existing patterns)?
- Does it reference real codebase artifacts (not hallucinated paths/classes)?
- Is it concrete enough for implementation (no vague "appropriate pattern" language)?

**Grade the section:**

| Grade | Meaning | Action |
|-------|---------|--------|
| **A** | Solid. Consistent with everything. | Mark `Complete` in STATE.md. Next section. |
| **B** | Minor gap. One small clarification needed. | Flag to developer, quick fix, mark Complete. |
| **C** | Issue found. Contradicts another section or KB. | Back to Propose with findings. |

```
✅ Data Model section written and verified — consistent with architecture.md
   and coding-standards.md. Moving to Feature Flow.
```

or:

```
⚠️ Data Model section has an issue: the index strategy contradicts what's
in coding-standards.md §3.2 (composite indices discouraged). Let me re-propose...
```

### Continue or Finish

- More Pending sections → Propose next one (step 1)
- All sections Complete:
  - Set STATUS to `Ready` in STATE.md
  - Print summary with all completed sections
  - `/aid-specify` on this feature now enters **REVIEW** (step 4 on all sections)

---

## State 5: REVIEW (re-run on completed feature)

The spec was completed previously. Re-run enters **the same loop at step 4** —
reviewing all sections against current reality.

### Load Current Context

Same as INITIALIZE Step 1: SPEC.md, REQUIREMENTS.md, KB docs, codebase.

### Review All Sections

For each section in SPEC.md, run step 4 of the loop against current state:

1. **KB drift** — SPEC references KB content that changed?
2. **Requirements drift** — Requirements changed since spec was written?
3. **Codebase drift** — Code changed (renamed, refactored by another feature)?
4. **Missing sections** — New conditional sections should now be activated?
5. **Stale content** — Section contradicts what now exists?

### Grade Overall

| Grade | Meaning | Action |
|-------|---------|--------|
| **A** | Current. No drift. | Print summary, done. |
| **B** | Minor drift. 1–3 small updates. | List findings, fix inline. |
| **C** | Significant drift. Sections need rewrite. | List findings, re-enter loop for affected sections. |
| **D** | Major drift. Core assumptions invalidated. | Recommend `--reset`. |

```
Reviewing {work}/{feature} against current KB and codebase...

**Grade: {grade}**

{findings and options}
```

For B/C: re-enter the loop (Propose → Discuss → Write → Review) for affected sections.
When all resolved, set status back to Ready.

---

## Handling Outcomes During Discussion

### KB is Wrong or Incomplete

**Simple fix:** Fix the KB document directly, note in STATE.md Change Log.

**Needs re-discovery:** Add Q&A entry to `.aid/knowledge/DISCOVERY-STATE.md`,
add Loopback entry to STATE.md, continue with non-blocked sections.

### Requirements are Wrong or Incomplete

**Simple fix:** Fix REQUIREMENTS.md and SPEC.md directly, add Change Log entries.

**Needs re-interview:** Add Q&A entry to `.aid/{work}/INTERVIEW-STATE.md`,
add Loopback entry to STATE.md.

### Spike Needed (State 3)

1. Update STATE.md: `**Status:** Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in SPEC.md, resume loop.

### Blocked (State 4)

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

### Feature Split

Create new feature folder(s), redistribute SPEC.md content, add Change Log entries, continue.

### Feature Merge

Merge content into target, delete current folder, exit.

---

## Conversation Style

**Do:**
- Propose concrete solutions based on what exists
- Reference specific files, classes, patterns
- Explain trade-offs when multiple approaches exist
- Push back if the developer contradicts KB patterns
- Admit when you don't know something

**Don't:**
- Ask generic questions — propose based on KB
- Generate walls of spec without discussion
- Move to next section without clear agreement
- Be a yes-machine — if you see a problem, say so

**The rhythm:**
```
Agent: "Based on {KB}, I propose {concrete approach}."
Dev:   "Actually, we should do X because Y."
Agent: "Good point. That means we also need Z. Updated approach..."
Dev:   "Yeah, works."
Agent: [writes] [reviews: ✅ consistent] [next section]
```
