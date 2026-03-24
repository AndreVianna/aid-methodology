---
name: aid-specify
description: >
  Technical specification through conversational refinement, one feature at a time.
  The agent acts as a tech lead — reads KB, Requirements, and codebase, proposes
  technical solutions, and builds the spec collaboratively with the developer.
  Writes to SPEC.md in the feature folder.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit
argument-hint: "task-001/feature-001 (required)  [--reset] clear technical spec for this feature"
---

# Technical Specification — Conversational Refinement

Specify the technical implementation of a single feature through conversational refinement
with the developer. The agent reads the KB, Requirements, codebase, and existing feature
SPEC.md, then proposes technical solutions section by section. The developer discusses,
corrects, and approves each section.

**The agent is a tech lead, not an interviewer.** It proposes concrete solutions grounded
in the existing architecture. The developer validates, redirects, or deepens the discussion.

**One feature at a time.** The feature path is a required argument.

**Workspace structure:**
```
aid-workspace/
  knowledge/               ← shared KB
  task-001-name/
    REQUIREMENTS.md
    features/
      feature-001-name/
        SPEC.md            ← product (requirements + technical specification)
        STATE.md           ← process (section status, Q&A, loopbacks)
```

---

## ⚠️ Pre-flight Checks

### Check 1: Feature Path Required

If no feature path was provided, list available features across all tasks:

```
Usage: /aid-specify task-001/feature-001

Available features:
  task-001-user-auth/feature-001-login        [No STATE — not started]
  task-001-user-auth/feature-002-password      [In Discussion — 2/5 sections]
  task-002-reporting/feature-001-dashboard     [Ready ✅]
```

Scan all `aid-workspace/task-*/features/feature-*/` directories.
For each, check if STATE.md exists and show status. Exit.

**Shortcut:** If only one task exists, accept bare `feature-001` and resolve automatically.

### Check 2: Feature Exists

Resolve the feature path using **prefix matching** (glob):
- `feature-001` → match `aid-workspace/{task}/features/feature-001-*/SPEC.md`
- `task-001/feature-002` → match `aid-workspace/task-001-*/features/feature-002-*/SPEC.md`

The user provides the numeric prefix (`feature-001`, `task-001/feature-002`); the agent
resolves it against the actual folder name which includes the kebab-case suffix.

**If zero matches:** 
```
Feature not found matching {input} in aid-workspace/
Run /aid-interview to create features from requirements.
```
Exit.

**If multiple matches:** List them and ask the user to be more specific. Exit.

**If exactly one match:** Use that path. Print: `[Resolved: {full-path}]`

### Check 3: Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

---

## Arguments

| Argument | Effect |
|----------|--------|
| `task-NNN/feature-NNN` | **Required.** Path to the feature to specify. |
| `feature-NNN` | Shortcut when only one task exists. |
| `--reset` | Clear the `## Technical Specification` section from SPEC.md and delete STATE.md. Restart from scratch. |

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**

All paths relative to `aid-workspace/{task}/features/{feature}/`.

```plaintext
State 1: No STATE.md                                       → INITIALIZE
State 2: STATE.md exists, Status: In Discussion             → CONTINUE
State 3: STATE.md exists, Status: Spike Needed              → SPIKE INFO
State 4: STATE.md exists, Status: Blocked (loopback pending)→ BLOCKED
State 5: STATE.md exists, Status: Ready                     → DONE
```

Print: `[{task}/{feature}: {STATE}]`

---

## State 1: INITIALIZE

No STATE.md exists. First run for this feature.

### Step 1: Load Full Context

Read ALL of these before making any proposal:

1. **SPEC.md** — the feature's requirements side (description, user stories, acceptance criteria)
2. **`aid-workspace/{task}/REQUIREMENTS.md`** — full requirements for cross-reference
3. **`aid-workspace/knowledge/INDEX.md`** — then read specific KB documents relevant to
   this feature:
   - Always read: `architecture.md`, `technology-stack.md`, `coding-standards.md`,
     `module-map.md`, `data-model.md`
   - Read if relevant: `api-contracts.md`, `integration-map.md`, `security-model.md`,
     `domain-glossary.md`, `test-landscape.md`, `infrastructure.md`
   - **Greenfield note:** If KB documents contain only the init template placeholder
     (`❌ Pending`), treat them as empty — no existing architecture to reference. The
     agent proposes from scratch based on REQUIREMENTS.md and discussion with the
     developer. Technical decisions made during specification will be written back to
     the KB (see **KB Seeding** in Discussion Loop → Write).
4. **Codebase** — Use `Grep` and `Glob` to explore relevant source code areas identified
   by KB documents. Understand what exists before proposing what to add. For greenfield
   projects with no codebase yet, skip this step.

### Step 2: Determine Applicable Sections

Based on the feature requirements, KB, and codebase analysis, determine which technical
sections apply.

**Core sections (always present unless truly N/A):**

| Section | Content |
|---------|---------|
| Data Model | Tables, columns, types, constraints, FKs, indices — or "no schema changes" |
| Feature Flow | Technical flowchart: request → service → repo → response |
| Layers & Components | What goes in each layer, dependencies, DI registrations |

**Conditional sections — activation rules:**

Each conditional section has two activation paths:
1. **Auto-activate** — obvious from KB + Requirements + codebase (don't ask, just include)
2. **Ask** — not obvious, use the default question to check with the developer

| Section | Auto-activate when... | Default question |
|---------|----------------------|------------------|
| API Contracts | KB or Requirements mention endpoints/API | Does this feature expose or modify any APIs? (REST, GraphQL, gRPC, WebSocket) |
| UI Specs | Requirements mention screens/UI | Does this feature include any user-facing screens or UI changes? |
| Events & Messaging | KB has queues/events or Requirements mention async | Does this feature involve asynchronous processing, events, or message queues? |
| DDD Analysis | KB or Requirements indicate DDD/bounded contexts | Does the project follow Domain-Driven Design? Should we define bounded contexts and aggregates? |
| BDD Scenarios | Requirements indicate BDD/Gherkin | Does the project use Behavior-Driven Development? Should we write Gherkin scenarios? |
| CQRS Specs | KB shows CQRS pattern | Does this feature use or introduce Command/Query separation? |
| State Machines | Requirements describe stateful workflows | Do any aspects of this feature involve stateful workflows with defined transitions? |
| Security Specs | Requirements mention auth/roles/permissions | Are there specific authentication, authorization, or permission requirements beyond basic auth? |
| Migration Plan | Brownfield + schema changes in Data Model | Does this feature change existing database schemas or require data migration? |
| Cache Strategy | Requirements mention performance/caching | Are there performance requirements that may need caching? |
| External Integrations | Requirements mention 3rd party services | Does this feature integrate with any external services or third-party APIs? |
| Batch/Jobs | Requirements mention scheduled processing | Does this feature include any scheduled jobs, batch processing, or background tasks? |
| Mobile Specs | Requirements target mobile platforms | Does this feature target mobile platforms? Any offline-first or platform-specific concerns? |
| Search/Indexing | Requirements mention search/complex filtering | Does this feature require full-text search, complex filtering, or search indexing? |
| AI Enhancements | Requirements mention AI/ML/LLM | Does this feature involve AI or machine learning? (prompts, RAG, agents, fine-tuning, models, cost/limits) |
| Telemetry & Tracking | Not obvious from context | Are there specific logging, auditing, alerting, or dashboard requirements for this feature? |
| Recovery Management | Not obvious from context | Are there disaster recovery, backup, or redundancy requirements? |
| Cloud Support | Requirements mention deploy/cloud | Does this feature have specific cloud provider requirements? |
| Hardware Requirements | Not obvious from context | Are there particular hardware considerations? (compute, memory, storage, GPU, network) |

### Step 3: Create STATE.md

Create `STATE.md` in the feature folder using the template from
`../templates/feature-state.md`. Fill in:

- **Started:** today's date
- **Activated Sections table:** add rows for each activated section (core and conditional)
  with Status `Pending` and Activation source (`core` or `auto` or `user-confirmed`)
- **Change Log:** `| {today} | Specify started, {N} sections activated | /aid-specify |`

### Step 4: Present Section Plan and Start Discussion

Present the activated sections and the ambiguous questions together:

```
I've analyzed {feature} against the KB and codebase. Here's what I think we need to specify:

**Core sections:**
- Data Model — {brief rationale}
- Feature Flow — {brief rationale}
- Layers & Components — {brief rationale}

**Also activated (based on context):**
- {Section} — {why: e.g., "KB shows REST API in module X"}
- {Section} — {why}

**Questions about additional sections:**
1. {default question for ambiguous section 1}
2. {default question for ambiguous section 2}
...

Does this look right? Answer the questions above, and tell me if I'm missing
or including something I shouldn't.
```

Process the developer's response:
- For each question answered → activate or skip the section, update STATE.md
- For any additional sections requested → add to STATE.md
- For any sections to remove → mark as N/A in STATE.md

**Then immediately begin the Discussion Loop for the first Pending section.**

---

## State 2: CONTINUE (In Discussion)

STATE.md exists, status is "In Discussion." Resume where we left off.

Read STATE.md. Find the first section with Status `Pending` or `In Discussion`.
Read SPEC.md to see what's already been written.

Continue with the **Discussion Loop** for that section.

---

## Discussion Loop

This is the core of the Specify phase. For each activated section, the agent proposes
a technical solution and discusses it with the developer.

### For each section (in order from STATE.md):

#### 1. Propose

Read the relevant KB documents and codebase for this section. Then propose:

```
### {Section Name}

Based on the KB and codebase, here's what I propose:

{Concrete technical proposal — not generic, grounded in what exists.
Reference specific KB documents, files, patterns, and conventions.
Use actual class names, table names, module names from the codebase.}

What do you think? Anything to adjust?
```

**Proposal quality rules:**
- Reference specific files, classes, patterns from the codebase
- Follow conventions from `coding-standards.md`
- Fit into the architecture from `architecture.md`
- Use domain terms from `domain-glossary.md`
- If the proposal requires changing something that exists, call it out explicitly

Update section status to `In Discussion` in STATE.md.

#### 2. Discuss

This is a free-form conversation. The developer may:

- **Agree** → write the section to SPEC.md, mark `Complete` in STATE.md
- **Adjust** → revise the proposal, present again
- **Redirect** → the developer has a different approach. Adapt.
- **Ask questions** → answer from KB/codebase/knowledge. If you don't know, say so.
- **Raise concerns** → discuss trade-offs. Present options with pros/cons.

**The discussion continues until the developer is satisfied with the section.**

#### 3. Write

When the developer agrees (explicitly or implicitly — "looks good", "yeah", "let's go"):

1. Write the section content to SPEC.md under `## Technical Specification`
2. Update STATE.md: section status → `Complete`
3. Add Change Log entry to SPEC.md
4. **KB Seeding (greenfield):** If the agreed technical decision fills a gap in a KB
   document that is empty or contains only the init placeholder (`❌ Pending`), update
   that KB document with the decision. Examples:
   - Data Model section agreed → update `aid-workspace/knowledge/data-model.md`
   - Technology stack chosen → update `aid-workspace/knowledge/technology-stack.md`
   - Architecture pattern decided → update `aid-workspace/knowledge/architecture.md`
   - API style agreed → update `aid-workspace/knowledge/api-contracts.md`
   
   Also update `aid-workspace/knowledge/INDEX.md` summaries and
   `aid-workspace/knowledge/README.md` status for any KB docs that changed.
   Add a Change Log entry to SPEC.md noting which KB docs were seeded.
   This is how greenfield projects build their KB incrementally through specification.
5. Move to the next Pending section

#### 4. Continue or Finish

After completing a section:
- If more Pending sections remain → propose the next one
- If all sections are `Complete`:
  - Set STATUS to `Ready` in STATE.md
  - Print summary (see **Completion** below)

---

## Handling Outcomes During Discussion

The discussion may reveal problems that go beyond this feature's specification.

### KB is Wrong or Incomplete

**If the fix is simple** (a version number, a wrong path, a missing class):
- Fix the KB document directly
- Note it in STATE.md Change Log

**If the fix requires re-discovery:**
- Add a Q&A entry to `aid-workspace/knowledge/DISCOVERY-STATE.md`:
  ```markdown
  ### Q{N}: [{Category}: {Impact}]
  - **Category:** {area}
  - **Impact:** High
  - **Status:** Pending
  - **Context:** During {task}/{feature} specification, developer noted {what}
  - **Suggested:** {suggestion or "—"}
  - **Question:** {what needs investigation}
  ```
- Add a Loopback entry to STATE.md
- Continue with other sections that are not blocked

### Requirements are Wrong or Incomplete

**If the fix is simple:** Fix REQUIREMENTS.md and SPEC.md directly, add Change Log entries.

**If the fix requires re-interview:**
- Add a Q&A entry to `aid-workspace/{task}/INTERVIEW-STATE.md`:
  ```markdown
  ### IQ{N}: [{Category}: {Impact}]

  **Question:** {question for the stakeholder}
  **Context:** During {task}/{feature} specification, developer noted {what}
  **Source:** /aid-specify {task}/{feature}
  **Suggested:** {suggestion or "—"}
  **Status:** Pending
  ```
- Add a Loopback entry to STATE.md

### Spike Needed

1. Update STATE.md:
   - Set `**Status:** Spike Needed`
   - Add Spike section with What/Why/Scope/Blocked Sections
2. Print spike details and exit

### Feature Needs to Be Split

1. Create new feature folder(s) in `aid-workspace/{task}/features/`
2. Create SPEC.md for each new feature using the template
3. Redistribute content from the original SPEC.md
4. Add Change Log entries to ALL affected files
5. Continue with the current (reduced) feature

### Feature Needs to Be Merged

1. Merge SPEC.md content into the target feature's SPEC.md
2. Delete the current feature folder (SPEC.md + STATE.md)
3. Add Change Log entry to the target
4. Exit

---

## State 3: SPIKE INFO

STATE.md has `**Status:** Spike Needed`.

1. Read the Spike section from STATE.md
2. Ask for spike results
3. Record in SPEC.md under `### Spike Results`
4. Update STATE.md: remove Spike section, set status back to `In Discussion`
5. Continue with Discussion Loop

---

## State 4: BLOCKED

STATE.md has `**Status:** Blocked` and Loopbacks with `Pending` status.

1. Check each Pending loopback — read the target STATE file
2. If Q&A entry is now `Answered` or `Applied` → resolve loopback, unblock sections
3. If all resolved → set STATUS to `In Discussion`, continue Discussion Loop
4. If still blocked → print blocking items with instructions, exit

---

## State 5: DONE

STATE.md has `**Status:** Ready`.

```
✅ {task}/{feature} specification is complete.

Sections specified: {list}

Ready for /aid-plan. Run /aid-specify {task}/{next-feature} for the next feature.
```

---

## Completion

When all sections are `Complete` in STATE.md:

1. Verify SPEC.md:
   - [ ] All activated sections have content under `## Technical Specification`
   - [ ] No placeholder text remaining
   - [ ] Change Log has entries for each section
   - [ ] Technical sections reference KB documents and codebase locations

2. Set STATE.md `**Status:** Ready`

3. Print summary with completed sections and any loopbacks triggered.

---

## Conversation Style

The agent acts as a **technical collaborator**, not an interviewer or a generator.

**Do:**
- Propose concrete solutions based on what exists in the codebase
- Reference specific files, classes, patterns, and conventions
- Explain trade-offs when multiple approaches exist
- Push back if the developer proposes something that contradicts KB patterns
- Ask follow-up questions when the developer's answer opens new technical questions
- Admit when you don't know or can't determine something from the codebase

**Don't:**
- Ask generic questions ("What technology do you want to use?") — propose based on KB
- Generate walls of specification without discussion
- Move to the next section without clear agreement
- Ignore contradictions between what the developer says and what the KB shows
- Be a yes-machine — if you see a problem with the developer's approach, say so

**The rhythm:**
```
Agent: [reads context] "I think this fits like {proposal}. Based on {KB evidence}."
Dev:   "Actually, we should do X because Y."
Agent: "Good point. That means we also need to change Z. Here's the updated approach..."
Dev:   "Yeah, that works."
Agent: [writes section] [moves to next]
```
