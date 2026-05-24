# State: COMPLETION

All sections are Complete or N/A in STATE.md `## Interview Status`; run quality check, KB hydration, and present requirements for approval.

### Step 1: Quality Check

Before presenting for approval, verify:
- [ ] All "Must" requirements in §5 have acceptance criteria in §9
- [ ] No contradictions between sections
- [ ] Scope (§4) is consistent with Functional Requirements (§5)
- [ ] Constraints (§7) don't conflict with requirements

If issues found, ask the user to clarify instead of approving.

### Step 2: KB Hydration

The interview captured project knowledge that belongs in the Knowledge Base — not just
in REQUIREMENTS.md. Before approval, populate KB docs from what was learned.

Read `references/kb-hydration.md` for the full process.

In summary:
1. **Extract** — scan REQUIREMENTS.md and write substantive content into each KB document
   (technology-stack.md, coding-standards.md, architecture.md, infrastructure.md, etc.)
2. **Gap check** — identify KB docs still empty where the user likely has answers
3. **Ask** — for each gap the user would reasonably know, ask ONE question at a time
   (same interactive pattern as the interview). If the user says "skip", respect it.
4. **Update meta** — refresh README.md completeness table, INDEX.md summaries,
   `.aid/knowledge/STATE.md` (KB section), and REQUIREMENTS.md change log

**This step is mandatory.** Do not skip it even if the user seems eager to approve.
The KB is consumed by all downstream phases — empty KB docs force specify/detail/execute
to guess.

After hydration is complete, proceed to the summary.

### Step 3: Present Summary

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

### Step 4: Process Response

- **[1] Approved:**
  - Set `**Interview Status:** Approved` in STATE.md `## Interview Status`
  - Add Change Log entry in REQUIREMENTS.md: `| {today} | Interview complete — approved | /aid-interview |`
  - Add Review History entry in STATE.md `## Interview Status`
  - Update `.aid/knowledge/INDEX.md` and `.aid/knowledge/README.md`
    if they exist
  - If `infrastructure.md § Project Management` defines a tool → create an Epic for this work
  - Print: `✅ Requirements approved. Proceeding to feature decomposition...`
  - **Immediately proceed to State 5 (Feature Decomposition) in the same run.**

- **[2] Additional consideration:**
  - Incorporate into relevant section(s) of REQUIREMENTS.md
  - Update STATE.md `## Interview Status` section statuses if needed
  - Return to Interview Loop for any new gaps

**Advance:** Next state is `FEATURE-DECOMPOSITION` — on approval, print `Next: [State: FEATURE-DECOMPOSITION] — run /aid-interview again` and exit (or proceed immediately per Step 4 above).
