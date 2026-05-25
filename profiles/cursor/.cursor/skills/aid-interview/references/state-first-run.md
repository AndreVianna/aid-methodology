# State: FIRST-RUN

This state runs only when STATE.md `## Interview Status` does not exist in the work folder; it creates the scaffolding so that TRIAGE can ask the 3 path-determination questions before the conversational interview begins.

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

---

**Advance:** Next state is `TRIAGE` — after scaffolding is complete, triage determines the path (lite or full) before the conversational interview begins. Print `Next: [State: TRIAGE] — run /aid-interview again` and exit.
