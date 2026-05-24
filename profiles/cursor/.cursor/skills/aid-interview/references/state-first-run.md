# State: FIRST-RUN

This state runs only when STATE.md `## Interview Status` does not exist in the work folder; it creates the scaffolding and opens the conversation.

### 1a. Read KB (if it exists)

Check for `.aid/knowledge/INDEX.md`. If it exists, read it to understand what's
already known about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create or update STATE.md

Ensure `.aid/{work}/STATE.md` exists and has an `## Interview Status` section and a
`## Cross-phase Q&A` section. Copy from `../../templates/work-state-template.md` if
the file does not yet exist.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../../templates/requirements.md` to
`.aid/{work}/REQUIREMENTS.md`.
Add the first Change Log entry: `| {today} | Initial interview started | /aid-interview |`

**Note:** Sections are empty — no placeholder markers. The STATE.md `## Interview Status` tracks
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
2. Update the Section Status table in STATE.md `## Interview Status`:
   - `Pending` → `Partial` (some content) or `Complete` (fully addressed)
   - Update `Last Updated` column with today's date
3. If the answer touches multiple sections, update all of them
4. Follow the **Interview Loop** below to decide what to ask next

**Write immediately after each answer. Do not batch.**

---

## Interview Loop

This loop runs during State 1 (First Run) and State 3 (Continue Interview).

### Assess current state

Read STATE.md `## Interview Status` Section Status table. For each section:
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
- If a section is genuinely N/A for this project, mark it `N/A` in STATE.md `## Interview Status`
  and move on.

### Update after each answer

1. Update the relevant section(s) in REQUIREMENTS.md
2. Update Section Status in STATE.md `## Interview Status`
3. If the change is significant, add a Change Log entry in REQUIREMENTS.md
4. If applicable, update `.aid/knowledge/INDEX.md` and
   `.aid/knowledge/README.md`

**Advance:** Next state is `CONTINUE` — when interview sections are all Complete or N/A the router advances to COMPLETION; between turns the user re-invokes `/aid-interview`. Run `/aid-interview again` to continue.
