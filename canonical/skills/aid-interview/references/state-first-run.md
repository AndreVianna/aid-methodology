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

**See `references/interview-loop.md`** for the loop body (shared between FIRST-RUN and CONTINUE).

**Advance:** Next state is `CONTINUE` — when interview sections are all Complete or N/A the router advances to COMPLETION; between turns the user re-invokes `/aid-interview`. Run `/aid-interview again` to continue.
