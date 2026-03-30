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

Copy the template from `../../templates/interview-state.md` to
`.aid/{work}/INTERVIEW-STATE.md`.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../../templates/requirements.md` to
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

Read `references/interview-strategies.md` for question priority logic, KB inference,
quality gates, and UI-aware probing.

In summary: (1) Infer from KB first — suggest answers with source references, don't fill
silently. (2) Pick the most critical gap. (3) Deepen Partial sections. (4) When all
sections addressed → State 4.

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

Requirements are approved. Decompose Functional Requirements (§5) into discrete,
independently implementable features with SPEC.md files.

Read `references/feature-decomposition.md` for the full decomposition process
(analyze, propose, create folders, update meta-documents).

---

## State 6: CROSS-REFERENCE & REFINE

Requirements approved and features created. Validates REQUIREMENTS.md against KB
documents and codebase, grades findings, and creates Q&A entries for issues.

Read `references/cross-reference.md` for the full cross-reference validation process
(load context, cross-reference, grade, present findings, create Q&A, wrap up).

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


