---
name: aid-interview
description: >
  Adaptive requirements gathering through conversational interview. Builds
  requirements.md incrementally by asking one question at a time, adapting to
  user responses and existing KB. Loop: assess gaps → ask/infer → update → repeat.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--reset] clear requirements.md and restart"
---

# Adaptive Requirements Gathering

Gather requirements from a human stakeholder through adaptive, one-question-at-a-time
conversation. Builds `knowledge/requirements.md` incrementally — each answer updates the
document immediately. The interview adapts based on existing KB, previous answers, and
user direction.

**This is a loop, not a state machine.** Each `/aid-interview` run continues where the last
left off. The document grows until complete.

## ⚠️ Pre-flight Check

**Before starting, verify you are NOT in Plan Mode.**

Plan Mode restricts all operations to read-only — the interview cannot update requirements.md.

**How to check:** Look at the permission indicator in your Claude Code interface (bottom of screen).
- ✅ `Default` or `Auto-accept edits` → Proceed.
- ❌ `Plan mode` → **STOP.** Tell the user: "Interview needs to write files. Please press `Shift+Tab` to switch out of Plan Mode, then re-run `/aid-interview`."

## Arguments

| Argument | Effect |
|----------|--------|
| `--reset` | Clear `knowledge/requirements.md` and restart the interview from scratch. |

---

## Entry Point

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read the actual files on disk.

### Detection Logic

1. If `--reset` → delete `knowledge/requirements.md` and start fresh
2. If `knowledge/requirements.md` does NOT exist → **FIRST RUN** (Step 1)
3. If `knowledge/requirements.md` exists → **CONTINUATION** (Step 2)

---

## Step 1: First Run — The Opening Question

This happens only once, on the very first run.

### 1a. Read KB (if it exists)

Check for `knowledge/INDEX.md`. If it exists, read it to understand what's already known
about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create the requirements.md scaffold

Create `knowledge/requirements.md` with the following template. All sections start as
`*(pending)*` — they'll be filled incrementally as the interview progresses.

```markdown
# Requirements

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

Update `knowledge/requirements.md` — fill in **Section 1 (Objective)** with the user's
response, in their own words. Remove the `*(pending)*` marker.

If the answer also touches other sections (e.g., the user mentions specific users or
constraints unprompted), fill those sections too.

Proceed to Step 2.

---

## Step 2: The Interview Loop

This is the core of the interview. It runs on every `/aid-interview` after the first.

### 2a. Assess the current state

Read `knowledge/requirements.md`. For each section, classify it as:

- **Complete** — has substantive content, confirmed by user
- **Partial** — has some content but gaps remain
- **Pending** — still shows `*(pending)*` or is empty

Read the KB (if it exists) to check what can be inferred.

### 2b. Decide what to do next

**Priority order for the next action:**

1. **Infer from KB** — If a Pending/Partial section can be answered from KB documents,
   **do NOT fill it silently.** Instead, ask the question with a suggested answer and
   source reference, similar to Q&A mode in Discovery:
   ```
   [From: knowledge/{source-document}.md]

   {Your question about this section}

   Based on the codebase analysis: {inferred content}

   [1] Accept this
   [2] Not applicable
   [3] Your answer: ___
   ```
   Only update requirements.md after the user responds. This prevents hallucinated
   inferences from silently entering the requirements.

2. **Ask about the most critical gap** — Among remaining Pending/Partial sections,
   pick the one that:
   - Depends on the least other information (can be answered now)
   - Unblocks the most other sections
   - Is most relevant given what the user has already said

3. **Deepen a Partial section** — If no sections are fully Pending but some are Partial,
   ask a follow-up to complete them.

4. **Confirm and close** — If all sections are Complete or Inferred, proceed to Step 3.

### 2c. Ask ONE question

Formulate a clear, specific question. Show understanding of previous answers:

```
Got it — so the core problem is [summary of what you know so far].

[Your question about the next gap]
```

**Rules:**
- ONE question per run. Never batch.
- Use the user's language, not jargon they haven't used.
- If the user gave direction ("focus on security"), pivot to that area.
- If an answer contradicts the KB, flag it: "The codebase shows X, but you're saying Y — which should we go with?"
- Short context before the question (1-2 sentences max). Don't recite everything back.

Wait for the user's response.

### 2d. Update requirements.md

After each answer:
1. Update the relevant section(s) in `knowledge/requirements.md`
2. Remove `*(pending)*` markers from sections that now have content
3. If the answer touches multiple sections, update all of them
4. If the answer opens new questions, note them mentally for next iteration

**Write immediately.** Do not batch updates.

### 2e. Update meta-documents

After updating requirements.md, check if these need updating:
- `knowledge/INDEX.md` — add or update the requirements.md entry
- `knowledge/README.md` — add requirements.md to completeness table if not present

Only update if the file exists and needs changes. Don't create files that don't exist yet.

### 2f. Loop

After updating, go back to Step 2a. Assess, decide, ask, update. Repeat.

**Each `/aid-interview` run should handle multiple questions** — keep going until the user
stops responding or all sections are addressed. The "one at a time" rule means one question
per turn in the conversation, not one question per command invocation.

---

## Step 3: Completion Check

When all sections are Complete or N/A (no `*(pending)*` markers, no Partial sections):

### 3a. Present summary

Show a brief summary of the requirements:

```
I believe I have enough information. Here's a summary:

**Objective:** [1-2 sentences]
**Key features:** [bullet list of must-haves]
**Main constraints:** [bullet list]
**Target users:** [list]

Is there anything else we should consider, or are the requirements ready
for the next phase?

[1] Approved — requirements are ready
[2] Additional consideration: ___
```

### 3b. Process response

- **User chose [1] (Approved):**
  - Add `<!-- Status: Approved -->` at the top of requirements.md
  - Update INDEX.md and README.md to reflect completion
  - Update CLAUDE.md and AGENTS.md if they have requirement placeholders
  - Print: `✅ Interview complete. Requirements approved. Proceed with /aid-specify.`

- **User provided additional consideration [2]:**
  - Incorporate the feedback into the relevant section(s)
  - Return to Step 2 to address any new gaps
  - Print: `[Interview] Noted. Let me address that...`

---

## Targeted Interview (Re-entry)

When a GAP.md or downstream phase triggers re-interview for a specific area:

1. Read the GAP.md to understand what's missing
2. Read current `knowledge/requirements.md`
3. Ask targeted questions ONLY about the gap
4. Update requirements.md with new information
5. Remove the `<!-- Status: Approved -->` marker (requirements changed)
6. Update INDEX.md and README.md
7. Report completion to the calling phase

---

## Brownfield vs Greenfield

**The skill handles both automatically.** The difference:

- **Brownfield (KB exists):** Many technical sections can be answered from KB documents.
  The interview focuses on "what do you want to change/add?" Questions come with suggested
  answers and source references, so the user confirms or corrects rather than starting
  from scratch. Faster, but nothing is assumed without user confirmation.

- **Greenfield (no KB):** Everything comes from the user. The interview is longer and
  covers more ground. No suggested answers available — all questions are open-ended.

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
- [ ] requirements.md is indexed in INDEX.md and tracked in README.md
- [ ] No `*(pending)*` markers remain in approved document
