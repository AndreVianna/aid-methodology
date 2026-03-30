---
name: aid-interview
description: >
  Adaptive requirements gathering through conversational interview. First run
  builds REQUIREMENTS.md incrementally. Subsequent runs cross-reference against
  KB, grade, and ask targeted questions to resolve gaps and contradictions.
  Final step decomposes functional requirements into discrete feature files.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[work-001] resume work  [--reset work-001] clear and restart  [--features work-001] re-run feature decomposition"
---

# Adaptive Requirements Gathering

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time
conversation. Builds REQUIREMENTS.md incrementally — each answer updates the document
immediately.

**Workspace structure:**
```
.aid/
  knowledge/           ← shared KB (populated by /aid-discover)
  work-001-name/       ← one work = one interview cycle
    INTERVIEW-STATE.md ← process (section status, Q&A, grade, review history)
    REQUIREMENTS.md    ← product (clean document, only project information)
    features/          ← product (one folder per feature, created after approval)
      feature-001-name/
        SPEC.md        ← product (technical specification, added by /aid-specify)
        STATE.md       ← process (specification state)
```

**First run:** Conversational interview from scratch.
**Subsequent runs (before approval):** Resume interview for incomplete sections.
**After approval:** Feature decomposition from functional requirements.
**After features created:** Cross-reference REQUIREMENTS.md against KB, grade, ask questions.
**Loopback:** Process Q&A injected by downstream phases (e.g., `/aid-specify`).

## ⚠️ Pre-flight Checks

### Check 1: Verify Workspace Exists

Check if `.aid/` directory exists. If it doesn't:
```
⚠️ AID workspace not found. Run /aid-init first to set up the project.
```
Exit. Do not proceed.

### Check 2: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user to switch out of Plan Mode.

## Arguments

| Argument | Effect |
|----------|--------|
| `work-NNN` | Work on the specified work item. |
| `--reset work-NNN` | Delete the work folder and restart from scratch. |
| `--features work-NNN` | Re-run feature decomposition for this work even if features exist. |
| *(no argument)* | Task routing (see below). |

---

## Task Routing

When no work ID is provided:

### No tasks exist

If `.aid/` has no `work-*` directories:

1. Ask for a short name for this work:
   ```
   What's a short name for this work? (e.g., "user-auth", "reporting", "api-v2")
   ```
2. Create `.aid/work-001-{name}/`
3. Proceed to State Detection with this work.

### Tasks exist

If `.aid/` has one or more `work-*` directories:

```
Existing works:
  work-001-user-auth   [Status: Approved, 3 features]
  work-002-reporting   [Status: In Progress, §5 Partial]

[1] Continue work-001-user-auth
[2] Continue work-002-reporting
[3] Create new work
```

Wait for response:
- **Continue existing:** proceed to State Detection for that work
- **Create new:** ask for name, create `work-{N+1}-{name}/`, proceed

**Shortcut:** If only one work exists and it's not yet Approved, go directly to it
without asking.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

All paths below are relative to `.aid/{work}/`.

```plaintext
State 1: No INTERVIEW-STATE.md                                    → FIRST RUN
State 2: INTERVIEW-STATE has Pending Q&A entries                   → Q&A mode
State 3: INTERVIEW-STATE Status: In Progress, sections incomplete  → CONTINUE INTERVIEW
State 4: INTERVIEW-STATE Status: In Progress, all sections done    → COMPLETION & APPROVAL
State 5: INTERVIEW-STATE Status: Approved, no feature folders      → FEATURE DECOMPOSITION
State 6: INTERVIEW-STATE Status: Approved, feature folders exist   → CROSS-REFERENCE
```

**Detection logic:**

1. If `--reset` → delete the work folder → recreate → proceed as State 1
2. Check for `INTERVIEW-STATE.md` in the work folder
3. If missing → **State 1: FIRST RUN**
4. If exists:
   a. Check `## Pending Q&A` section for entries with `**Status:** Pending`
   b. If Pending entries exist → **State 2: Q&A**
   c. Read `**Status:**` field at top of file
   d. If Status is `In Progress`:
      - Read Section Status table
      - If any section is `Pending` or `Partial` → **State 3: CONTINUE INTERVIEW**
      - If all sections are `Complete` or `N/A` → **State 4: COMPLETION & APPROVAL**
   e. If Status is `Approved`:
      - If `--features` flag provided → **State 5: FEATURE DECOMPOSITION**
      - Check if `features/` directory exists and contains `feature-*` subdirectories
      - If no feature folders → **State 5: FEATURE DECOMPOSITION**
      - If feature folders exist → **State 6: CROSS-REFERENCE**

Print the detected state: `[{work}: {FIRST RUN|Q&A|CONTINUE|COMPLETION|FEATURES|CROSS-REFERENCE}]`

---

## State 1: FIRST RUN

This happens only when INTERVIEW-STATE.md does not exist in the work folder.

### 1a. Read KB (if it exists)

Check for `.aid/knowledge/INDEX.md`. If it exists, read it to understand what's
already known about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create INTERVIEW-STATE.md

Copy the template from `../templates/interview-state.md` to
`.aid/{work}/INTERVIEW-STATE.md`.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../templates/requirements.md` to
`.aid/{work}/REQUIREMENTS.md`.
Add the first Change Log entry: `| {today} | Initial interview started | /aid-interview |`

**Note:** Sections are empty — no placeholder markers. The INTERVIEW-STATE.md tracks
which sections have been filled.

### 1d. Ask the opening question

**The first question is always the same:**

```
What are we building? Tell me the goal and what success looks like.
```

Wait for the user's response.

### 1e. Record and continue

After each answer:

1. Update the relevant section(s) in REQUIREMENTS.md
2. Update the Section Status table in INTERVIEW-STATE.md:
   - `Pending` → `Partial` (some content) or `Complete` (fully addressed)
   - Update `Last Updated` column with today's date
3. If the answer touches multiple sections, update all of them
4. Follow the **Interview Loop** below to decide what to ask next

**Write immediately after each answer. Do not batch.**

---

## Interview Loop

This loop runs during State 1 (First Run) and State 3 (Continue Interview).

### Assess current state

Read INTERVIEW-STATE.md Section Status table. For each section:
- **Complete** — has substantive content, confirmed by user
- **Partial** — has some content but gaps remain
- **Pending** — empty
- **N/A** — not applicable to this project

### Decide what to ask next

**Priority order:**

1. **Infer from KB** — If a Pending/Partial section can be answered from KB documents,
   **do NOT fill it silently.** When `feature-inventory.md` has content, use it to
   understand what already exists and probe for interactions/dependencies with the new work.
   Ask with a suggested answer and source reference:
   ```
   [From: .aid/knowledge/{source-document}.md]

   {Your question about this section}

   Based on the codebase analysis: {inferred content}

   [1] Accept this
   [2] Not applicable
   [3] Your answer: ___
   ```
   Only update REQUIREMENTS.md after the user responds.

   **Quality gates inference:** When working on §6 Non-Functional Requirements, proactively
   ask about these project-level baselines (if not already covered):
   - **Unit test minimum** — coverage target for new code? (e.g., "all public methods",
     "80% line coverage", "critical paths only")
   - **Linting standard** — which linter and ruleset? (e.g., "ESLint + Airbnb", "Checkstyle
     with Sun conventions", "default analyzer warnings-as-errors")
   - **Build policy** — zero warnings required? Specific compiler flags?

   These become the project baseline. `/aid-specify` may add feature-specific requirements
   on top, and `/aid-detail` concretizes them per task.

   **UI-aware inference:** If `.aid/knowledge/ui-architecture.md` exists and has real content
   (not "backend-only"), proactively ask about these topics when working on §6 Non-Functional
   Requirements (if not already covered):
   - Target devices and browsers (desktop, tablet, mobile — which combinations?)
   - Accessibility requirements (WCAG level? Keyboard navigation? Screen reader support?)
   - Internationalization/localization needs (languages? RTL? Date/number formats?)
   - Responsive behavior expectations (mobile-first? Specific breakpoints?)
   - Design specs or Figma references (existing design system? Brand guidelines?)
   - Offline behavior expectations (PWA? Service workers? Graceful degradation?)

2. **Most critical gap** — Among remaining Pending/Partial sections, pick the one that:
   - Depends on the least other information (can be answered now)
   - Unblocks the most other sections
   - Is most relevant given what the user has already said

3. **Deepen Partial sections** — If no sections are fully Pending but some are Partial,
   ask a follow-up to complete them.

4. **All sections addressed** → State 4 (Completion & Approval).

### Rules

- **ONE question per turn.** Never batch.
- Use the user's language, not jargon they haven't used.
- If the user gave direction ("focus on security"), pivot to that area.
- If an answer contradicts the KB, flag it:
  "The codebase shows X, but you're saying Y — which should we go with?"
- Short context before the question (1-2 sentences max). Don't recite everything back.
- If a section is genuinely N/A for this project, mark it `N/A` in INTERVIEW-STATE.md
  and move on.

### Update after each answer

1. Update the relevant section(s) in REQUIREMENTS.md
2. Update Section Status in INTERVIEW-STATE.md
3. If the change is significant, add a Change Log entry in REQUIREMENTS.md
4. If applicable, update `.aid/knowledge/INDEX.md` and
   `.aid/knowledge/README.md`

---

## State 2: Q&A Mode

INTERVIEW-STATE.md has entries in `## Pending Q&A` with `**Status:** Pending`.

These may come from:
- Cross-reference analysis (State 6)
- Loopback from downstream phases (e.g., `/aid-specify` injected a question)
- Review findings

### Step 1: Load and Filter

Read `## Pending Q&A` section. Collect all entries with `**Status:** Pending`.

**Before presenting each question, filter:**

1. **Already answered in REQUIREMENTS.md?** → Set status to `Answered`, fill answer,
   cite the section. Skip to next.
2. **Answered in KB?** → Set status to `Answered`, fill answer, cite KB document. Skip.
3. **Inferrable from context?** → Keep but ensure `**Suggested:**` answer exists.

After filtering, sort remaining Pending by impact: **High → Medium → Low**.

If zero remain: `[Q&A] All questions resolved from existing material.` and exit.

Print: `[Q&A] {N} questions for user input.`

### Step 2: Ask One at a Time

For each Pending question:

```
IQ{N}: [{Category}: {Impact}] {question text}

Context: {why this matters}
Source: {who injected this — /aid-specify feature-001, cross-reference, etc.}

Suggested: {suggestion if present}

[1] Skip / Not applicable
[2] Accept suggestion (only if Suggested exists)
[3] Your answer: ___
```

**Wait for the user's response before asking the next.**

### Step 3: Record

Based on the user's response, update the entry in INTERVIEW-STATE.md:

- **[1] Skip:** Set `**Status:** Skipped`
- **[2] Accept suggestion:** Set `**Status:** Answered`, copy suggestion to `**Answer:**`
- **[3] Answer:** Set `**Status:** Answered`, record text in `**Answer:**`

**Write immediately.** Also update REQUIREMENTS.md with the answer content where relevant.

If the answer affects a feature that already exists, update that feature's SPEC.md too
and add a Change Log entry.

### Step 4: Continue Until Done

When all questions addressed:
`[Q&A] Complete. {answered} answered, {skipped} skipped.`

---

## State 3: CONTINUE INTERVIEW

Resume the conversational interview. Same logic as State 1 — assess sections, ask next
question, update files. The Interview Loop section above applies.

Read INTERVIEW-STATE.md section status table to know where to continue.
Read REQUIREMENTS.md to know what's already captured.

---

## State 4: COMPLETION & APPROVAL

All sections are `Complete` or `N/A` in INTERVIEW-STATE.md.

### Step 1: Quality Check

Before presenting for approval, verify:
- [ ] All "Must" requirements in §5 have acceptance criteria in §9
- [ ] No contradictions between sections
- [ ] Scope (§4) is consistent with Functional Requirements (§5)
- [ ] Constraints (§7) don't conflict with requirements

If issues found, ask the user to clarify instead of approving.

### Step 2: Present Summary

```
I believe I have enough information. Here's a summary:

**Objective:** [1-2 sentences from §1]
**Problem:** [1-2 sentences from §2]
**Key features:** [bullet list of must-haves from §5]
**Main constraints:** [bullet list from §7]
**Target users:** [list from §3]

Is there anything else we should consider, or are the requirements ready?

[1] Approved — requirements are ready
[2] Additional consideration: ___
```

### Step 3: Process Response

- **[1] Approved:**
  - Set `**Status:** Approved` in INTERVIEW-STATE.md
  - Add Change Log entry in REQUIREMENTS.md: `| {today} | Interview complete — approved | /aid-interview |`
  - Add Review History entry in INTERVIEW-STATE.md
  - Update `.aid/knowledge/INDEX.md` and `.aid/knowledge/README.md`
    if they exist
  - If `infrastructure.md § Project Management` defines a tool → create an Epic for this work
  - Print: `✅ Requirements approved. Proceeding to feature decomposition...`
  - **Immediately proceed to State 5 (Feature Decomposition) in the same run.**

- **[2] Additional consideration:**
  - Incorporate into relevant section(s) of REQUIREMENTS.md
  - Update INTERVIEW-STATE.md section statuses if needed
  - Return to Interview Loop for any new gaps

---

## State 5: FEATURE DECOMPOSITION

Requirements are approved. Decompose Functional Requirements into discrete features.

### Step 1: Analyze

Read REQUIREMENTS.md (in the work folder), focusing on:
- §5 Functional Requirements — primary source for features
- §4 Scope — boundaries (in scope / out of scope)
- §9 Acceptance Criteria — distribute to features
- §10 Priority — feature priority

If KB exists, also read `.aid/knowledge/INDEX.md` and relevant KB documents
to understand existing features/modules that may influence decomposition.

### Step 2: Propose Feature List

```
Based on the functional requirements, I've identified {N} features:

| # | Folder Name | Description | Source | Priority |
|---|-------------|-------------|--------|----------|
| 1 | feature-001-{name} | {one-line description} | §5.x, §7.x | Must |
| 2 | feature-002-{name} | {one-line description} | §5.x | Must |
| 3 | feature-003-{name} | {one-line description} | §5.x | Should |
| ... | ... | ... | ... | ... |

Does this decomposition look right?

[1] Approve as-is
[2] Adjust — tell me what to change (add, remove, merge, split, rename)
```

**Feature decomposition rules:**
- Each feature should be independently implementable
- Feature names use kebab-case (for folder names)
- Every functional requirement from §5 must map to at least one feature
- Features that are too large to implement in one sprint should be split
- Related requirements that form a single user journey should be one feature
- Priority comes from §10 or context in REQUIREMENTS.md

### Step 3: Process Response

- **[1] Approve:** Create feature folders (Step 4)
- **[2] Adjust:** Modify the list per user feedback. Present again. Repeat until approved.

### Step 4: Create Feature Folders

Create `features/` directory inside the work folder if it doesn't exist.

For each approved feature, create `features/feature-{NNN}-{name}/SPEC.md` using the
template from `../templates/feature.md`. Fill in:

- **Title:** feature name (human-readable)
- **Change Log:** `| {today} | Feature identified from REQUIREMENTS.md {source sections} | /aid-interview |`
- **Source:** relevant REQUIREMENTS.md section references
- **Description:** synthesized from §5 in stakeholder language
- **User Stories:** extracted or synthesized from REQUIREMENTS.md, using user types from §3
- **Priority:** from §10 or context (Must / Should / Could)
- **Acceptance Criteria:** from §9 mapped to this feature, or synthesized from §5
- **Technical Specification:** leave as template placeholder (added by /aid-specify)

### Step 5: Update Meta-Documents

1. Add Review History entry in INTERVIEW-STATE.md:
   `| {N} | {today} | — | Feature Decomposition | {N} features created |`
2. Update `.aid/knowledge/INDEX.md` if it exists — add work/features reference
3. Update `.aid/knowledge/README.md` if it exists — add work to revision history

Print:
```
✅ Feature decomposition complete. {N} features created in {work}/features/:

{list each: feature-001-name/, feature-002-name/, ...}

Next steps:
- Review the feature SPEC.md files if desired
- Run /aid-specify {work}/feature-001 to begin technical specification
```

---

## State 6: CROSS-REFERENCE & REFINE

Requirements approved and features created.

**Ask first:** _"Requirements are approved and features are defined. Do you want to run
a cross-reference validation against the KB? Is there something specific to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the validation.
If user says no → print status summary and stop.

Validate against KB and codebase.

### 6a. Load Context

1. Read REQUIREMENTS.md (in the work folder)
2. Read INTERVIEW-STATE.md
3. Read `.aid/knowledge/INDEX.md` (if exists)
4. Read ALL KB documents listed in INDEX.md
5. Read all SPEC.md files in the work's `features/` subdirectories

### 6b. Cross-Reference

For each section of REQUIREMENTS.md, check against KB:

1. **Contradictions** — Requirement conflicts with KB evidence
2. **Gaps** — KB reveals things requirements should address but don't
3. **Missing evidence** — Requirements make claims that can't be verified
   (use `Grep` and `Glob` to search the actual codebase)
4. **Staleness** — KB updated since interview, affecting requirements
5. **Feature alignment** — Do feature SPEC.md files still match REQUIREMENTS.md?

### 6c. Grade

Use the universal rubric (`../templates/grading-rubric.md`). Classify each finding
by severity (Minor/Low/Medium/High/Critical). Grade is calculated — worst issue dominates.

Compare to minimum grade from `.aid/knowledge/DISCOVERY-STATE.md`.

**Update `**Grade:**` in INTERVIEW-STATE.md.**

### 6d. Present Findings

```
[Cross-Reference — Grade: {grade}]

Checked REQUIREMENTS.md against {N} KB documents and {M} features.

**Contradictions:** {count}
**Gaps:** {count}
**Unverified claims:** {count}
**Feature alignment issues:** {count}

{details for each}

{If grade ≥ minimum:}
No blocking issues found. Requirements are consistent with the Knowledge Base.

{If grade < minimum:}
I have {N} questions to resolve these. Let's go through them one at a time.
```

### 6e. Create Q&A Entries and Ask

For each finding, add a Q&A entry in INTERVIEW-STATE.md `## Pending Q&A`:

```markdown
### IQ{N}: [{Category}: {Impact}]

**Question:** {text}
**Context:** {why this matters, what evidence was found}
**Source:** /aid-interview (cross-reference)
**Suggested:** {answer if inferrable from KB/code, or "—"}
**Status:** Pending
```

Then present them one at a time using State 2 (Q&A mode) logic.

After each answer:
1. Update REQUIREMENTS.md
2. Update affected feature SPEC.md if the answer changes a feature
3. Add Change Log entries where content changed

### 6f. Wrap Up

After all questions answered:

1. Add Review History entry in INTERVIEW-STATE.md
2. Add Change Log entry in REQUIREMENTS.md
3. Print: `✅ Cross-reference complete. Run /aid-interview again to verify.`

---

## Targeted Interview (Loopback Re-entry)

When a downstream phase (e.g., `/aid-specify`) needs clarification on requirements:

1. The calling phase writes Q&A entries directly to the work's INTERVIEW-STATE.md
   in the `## Pending Q&A` section
2. Next `/aid-interview {work}` run detects Pending Q&A → enters State 2 (Q&A mode)
3. Questions are presented to the user one at a time
4. Answers are recorded in INTERVIEW-STATE.md and REQUIREMENTS.md
5. Feature SPEC.md files are updated if the answer affects a specific feature

**Q&A entry format for downstream phases to write:**

```markdown
### IQ{N}: [{Category}: {Impact}]

**Question:** {question text}
**Context:** {why this matters — what the downstream phase found}
**Source:** {calling phase, e.g., /aid-specify work-001/feature-001}
**Suggested:** {answer if inferrable, or "—"}
**Status:** Pending
```

---

## Brownfield vs Greenfield

The skill handles both automatically:

- **Brownfield (KB exists):** Many sections can be pre-filled from KB. Questions come
  with suggestions and source references. Cross-reference is thorough.
- **Greenfield (no KB):** Everything comes from the user. Interview is longer.
  Cross-reference has limited material — may be grade A by default.

---

## Question Design Principles

1. **Start wide, narrow down.** Objective → Scope → Details → Constraints.
2. **Follow the energy.** User excited about feature X? Explore it first.
3. **Don't interrogate.** Acknowledge what they said before asking the next thing.
4. **Respect "I don't know."** Mark as assumption, move on.
5. **Respect "not applicable."** Mark N/A, move on.
6. **Capture the WHY.** "Real-time updates" is a feature. "Traders lose money on
   stale data" is a requirement. Push for the why.
7. **Use concrete examples.** "Walk me through what a user would do when..." produces
   better requirements than "What are the functional requirements?"
