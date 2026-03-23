---
name: aid-interview
description: >
  Adaptive requirements gathering through conversational interview. First run
  builds REQUIREMENTS.md incrementally. Subsequent runs cross-reference against
  KB, grade, and ask targeted questions to resolve gaps and contradictions.
allowed-tools: Read, Grep, Terminal, Write, Edit, Task
argument-hint: "[--reset] clear REQUIREMENTS.md and restart"
---

# Adaptive Requirements Gathering

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time
conversation. Builds `knowledge/REQUIREMENTS.md` incrementally — each answer updates the
document immediately.

**First run:** Conversational interview from scratch.
**Subsequent runs:** Cross-reference REQUIREMENTS.md against KB, grade, ask targeted
questions to resolve gaps/contradictions. User decides when to stop re-running.

## ⚠️ Pre-flight Check

**Before starting, verify the agent mode allows file writes.**

If the current mode restricts operations to read-only, the interview cannot update REQUIREMENTS.md.

- ✅ Agent mode allows edits → Proceed.
- ❌ Read-only / planning mode → **STOP.** Tell the user: "Interview needs to write files. Please switch to a mode that allows edits, then re-run `/aid-interview`."

## Arguments

| Argument | Effect |
|----------|--------|
| `--reset` | Delete `knowledge/REQUIREMENTS.md` and restart the interview from scratch. |

---

## Entry Point

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

### Detection Logic

1. If `--reset` → delete `knowledge/REQUIREMENTS.md` and start fresh → **Step 1**
2. If `knowledge/REQUIREMENTS.md` does NOT exist → **Step 1** (First Run)
3. If `knowledge/REQUIREMENTS.md` exists → **Step 2** (Cross-Reference & Refine)

---

## Step 1: First Run — Conversational Interview

This happens only when REQUIREMENTS.md does not exist.

### 1a. Read KB (if it exists)

Check for `knowledge/INDEX.md`. If it exists, read it to understand what's already known
about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create the REQUIREMENTS.md scaffold

Create `knowledge/REQUIREMENTS.md` with the following template:

```markdown
# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| {today} | Initial interview started | /aid-interview |

## 1. Objective
*(pending)*

## 2. Problem Statement
*(pending)*

## 3. Users & Stakeholders
*(pending)*

## 4. Scope
### In Scope
*(pending)*

### Out of Scope
*(pending)*

## 5. Functional Requirements
*(pending)*

## 6. Non-Functional Requirements
*(pending)*

## 7. Constraints
*(pending)*

## 8. Assumptions & Dependencies
*(pending)*

## 9. Acceptance Criteria
*(pending)*

## 10. Priority
*(pending)*
```

### 1c. Ask the opening question

**The first question is always the same, regardless of brownfield or greenfield:**

```
What are we building? Tell me the goal and what success looks like.
```

Wait for the user's response.

### 1d. Record the answer

Update `knowledge/REQUIREMENTS.md` — fill in **Section 1 (Objective)** with the user's
response, in their own words. Remove the `*(pending)*` marker.

If the answer also touches other sections (e.g., the user mentions specific users or
constraints unprompted), fill those sections too.

### 1e. Continue the interview loop

After recording the first answer, continue asking questions one at a time:

#### Assess the current state

For each section, classify it as:
- **Complete** — has substantive content, confirmed by user
- **Partial** — has some content but gaps remain
- **Pending** — still shows `*(pending)*` or is empty

#### Decide what to ask next

**Priority order:**

1. **Infer from KB** — If a Pending/Partial section can be answered from KB documents,
   **do NOT fill it silently.** Ask with a suggested answer and source reference:
   ```
   [From: knowledge/{source-document}.md]

   {Your question about this section}

   Based on the codebase analysis: {inferred content}

   [1] Accept this
   [2] Not applicable
   [3] Your answer: ___
   ```
   Only update REQUIREMENTS.md after the user responds.

2. **Ask about the most critical gap** — Among remaining Pending/Partial sections,
   pick the one that:
   - Depends on the least other information (can be answered now)
   - Unblocks the most other sections
   - Is most relevant given what the user has already said

3. **Deepen a Partial section** — If no sections are fully Pending but some are Partial,
   ask a follow-up to complete them.

4. **All sections addressed** → Proceed to **Step 3** (Completion).

#### Ask ONE question per turn

```
Got it — so the core problem is [summary of what you know so far].

[Your question about the next gap]
```

**Rules:**
- ONE question per turn. Never batch.
- Use the user's language, not jargon they haven't used.
- If the user gave direction ("focus on security"), pivot to that area.
- If an answer contradicts the KB, flag it: "The codebase shows X, but you're saying Y — which should we go with?"
- Short context before the question (1-2 sentences max). Don't recite everything back.

#### Update REQUIREMENTS.md after each answer

1. Update the relevant section(s)
2. Remove `*(pending)*` markers from sections that now have content
3. If the answer touches multiple sections, update all of them

**Write immediately.** Do not batch updates.

#### Update meta-documents

After updating REQUIREMENTS.md, check if these need updating:
- `knowledge/INDEX.md` — add or update the REQUIREMENTS.md entry
- `knowledge/README.md` — add REQUIREMENTS.md to completeness table if not present

Only update if the file exists and needs changes. Don't create files that don't exist yet.

#### Loop

Keep going until the user stops responding or all sections are addressed. The "one at a
time" rule means one question per turn in the conversation, not one question per invocation.

When all sections are Complete or N/A → proceed to **Step 3** (Completion).

---

## Step 2: Cross-Reference & Refine

This runs when REQUIREMENTS.md already exists (second or subsequent `/aid-interview` run).
It validates the requirements against the full KB and codebase.

### 2a. Load context

1. Read `knowledge/REQUIREMENTS.md`
2. Read `knowledge/INDEX.md` (if it exists)
3. Read ALL KB documents listed in INDEX.md

### 2b. Cross-reference

For each section of REQUIREMENTS.md, check against the KB:

1. **Contradictions** — Does the requirement conflict with what the KB shows?
   - Example: Requirement says "no message queue" but KB shows RabbitMQ plugins exist
   - Example: Requirement says "Java 17" but KB shows modules compiled with Java 11

2. **Gaps** — Is there information in the KB that the requirements should address but don't?
   - Example: KB shows security concerns but requirements have no security section
   - Example: KB shows complex data model but requirements don't mention migration

3. **Missing evidence** — Does the requirement make claims that can't be verified in KB?
   - Use `Grep` to search the actual codebase for evidence
   - Example: Requirement says "3 search endpoints" — verify in codebase how many actually exist

4. **Staleness** — Has the KB been updated since the last interview that changes anything?
   - Check Change Log dates vs KB document dates

### 2c. Grade

Assign a grade based on the **number of questions** generated by the cross-reference:

| Grade | Questions | Meaning |
|-------|-----------|---------|
| **A** | 0 | Requirements are consistent with KB. No additional questions. |
| **B** | 1–3 | Small gaps or refinements needed. |
| **C** | 4–7 | Significant gaps or contradictions to resolve. |
| **D** | 8+ | Serious consistency problems. |

**The grade reflects the state of the document at the START of the run.** Do NOT re-grade
after answering questions. The user runs `/aid-interview` again to get the new grade.

### 2d. Present findings

Show the grade and findings to the user:

```
[Cross-Reference Review — Grade: {grade}]

I cross-referenced REQUIREMENTS.md against the full Knowledge Base ({N} documents)
and the codebase.

**Contradictions found:** {count}
{list each with: requirement section, KB source, what conflicts}

**Gaps found:** {count}
{list each with: what's missing, where in KB it was found}

**Unverified claims:** {count}
{list each with: the claim, what was searched, what was found}

{If grade is A:}
No issues found. Requirements are consistent with the Knowledge Base.

{If grade is B, C, or D:}
I have {N} questions to resolve these. Let's go through them one at a time.
```

### 2e. Ask targeted questions

For each finding (contradiction, gap, or unverified claim), ask ONE question at a time:

```
[{Finding type}: {brief description}]
[From: knowledge/{source-document}.md]

{Explanation of what was found}

{Your question to resolve it}

[1] {Suggested resolution based on evidence}
[2] Not applicable / Skip
[3] Your answer: ___
```

After each answer:
1. Update the relevant section in REQUIREMENTS.md
2. Add entry to the Change Log: `| {today} | {what changed} | /aid-interview (cross-reference) |`

### 2f. Wrap up

After all questions from this run are answered:

1. Update REQUIREMENTS.md with answers (already done per 2e)
2. Update INDEX.md with a **content summary only** — do NOT include the grade in INDEX.md
3. Print:
```
✅ Cross-reference complete. {N} questions resolved.
Run /aid-interview again to verify, or proceed with /aid-specify.
```

**Do NOT re-grade.** The grade was assigned at the start of this run (Step 2c) and reflects
the document's state BEFORE the questions were answered. The next run will produce the real
updated grade.

---

## Step 3: Completion (First Run Only)

When all sections are Complete or N/A during the first interview:

### 3a. Present summary

```
I believe I have enough information. Here's a summary:

**Objective:** [1-2 sentences]
**Key features:** [bullet list of must-haves]
**Main constraints:** [bullet list]
**Target users:** [list]

Is there anything else we should consider, or are the requirements ready?

[1] Approved — requirements are ready
[2] Additional consideration: ___
```

### 3b. Process response

- **User chose [1] (Approved):**
  - Add entry to Change Log: `| {today} | Interview complete — approved | /aid-interview |`
  - Update INDEX.md and README.md to reflect completion
  - Update .cursorrules if they have requirement placeholders
  - Print: `✅ Interview complete. Run /aid-interview again to cross-reference against KB, or proceed with /aid-specify.`

- **User provided additional consideration [2]:**
  - Incorporate the feedback into the relevant section(s)
  - Add entry to Change Log
  - Return to Step 1e to address any new gaps

---

## Targeted Interview (Re-entry)

When a GAP.md or downstream phase triggers re-interview for a specific area:

1. Read the GAP.md to understand what's missing
2. Read current `knowledge/REQUIREMENTS.md`
3. Ask targeted questions ONLY about the gap
4. Update REQUIREMENTS.md with new information
5. Add entry to Change Log: `| {today} | {what changed} | GAP.md re-entry |`
6. Update INDEX.md and README.md
7. Report completion to the calling phase

---

## Brownfield vs Greenfield

**The skill handles both automatically.** The difference:

- **Brownfield (KB exists):** Many technical sections can be answered from KB documents.
  The interview focuses on "what do you want to change/add?" Questions come with suggested
  answers and source references. Cross-reference (Step 2) is thorough — full KB available.

- **Greenfield (no KB):** Everything comes from the user. The interview is longer.
  Cross-reference (Step 2) has limited KB to check against — may be mostly A by default.

The interviewer doesn't need to know which mode it's in — the presence or absence of KB
documents naturally drives the behavior.

---

## Question Design Principles

1. **Start wide, narrow down.** Objective → Scope → Details → Constraints.
2. **Follow the energy.** If the user is excited about feature X, explore it before
   moving to boring infrastructure questions.
3. **Don't interrogate.** This is a conversation, not a deposition. Acknowledge what
   they said before asking the next thing.
4. **Respect "I don't know."** If the user doesn't know something, mark it as an
   assumption and move on. Don't pressure.
5. **Respect "not applicable."** Some sections genuinely don't apply to every project.
   Mark them as N/A and move on.
6. **Capture the WHY.** "We need real-time updates" is a feature. "Because traders lose
   money on stale data" is a requirement. Push for the why.
7. **Use concrete examples.** "Can you walk me through what a user would do when...?"
   produces better requirements than "What are the functional requirements?"

---

## Quality Checklist

- [ ] Every section is Complete, N/A, or explicitly deferred — nothing silently inferred
- [ ] Problem Statement uses the stakeholder's own words
- [ ] Functional requirements are specific enough to implement
- [ ] Non-functional requirements have measurable criteria where possible
- [ ] Assumptions are explicit — nothing is silently assumed
- [ ] Out of Scope is defined — prevents scope creep
- [ ] Acceptance criteria exist for priority features
- [ ] Technical context is consistent with KB (if brownfield)
- [ ] Change Log has entry for every modification
- [ ] REQUIREMENTS.md is indexed in INDEX.md and tracked in README.md
- [ ] No `*(pending)*` markers remain in approved document
