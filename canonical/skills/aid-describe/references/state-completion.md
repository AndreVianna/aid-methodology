# State: COMPLETION

All sections are Complete or N/A in STATE.md `## Interview State`; run quality check, KB hydration, and present requirements for approval.

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

### Step 3: Compose and Confirm Identity Header

Before presenting the approval summary, compose the work's **Name** and **Description**
and present them to the user for confirmation. These values will be written into the
`- **Name:**` / `- **Description:**` block in `REQUIREMENTS.md` (placed immediately after
the `# Requirements` H1, before `## Change Log`).

**How to compose:**

- **Name** — derive a concise, human-readable title from the work's subject. It must be
  Title Case and must not end with a period. It should be short enough to serve as a
  dashboard work-overview title (e.g. "AID Live Dashboard", "Order Processing Refactor").
  Do NOT use the raw `work_id` slug as the Name.
- **Description** — write exactly one sentence that summarises what the work delivers and
  why, derived from the body of `## 1. Objective`. It is NOT the Objective text verbatim,
  and it is NOT free-form authored independently. Compose it by distilling the Objective
  into one sentence (the agent writes this sentence; the user confirms it).

**Present to the user:**

```
Before I present the summary, here are the identity fields I will write into
REQUIREMENTS.md:

- **Name:** {composed Title Case name}
- **Description:** {one sentence derived from ## 1. Objective}

Do these look right, or would you like to adjust either?

[1] Looks good
[2] Adjust Name: ___
[3] Adjust Description: ___
```

Process feedback:
- **[1]:** proceed with the composed values.
- **[2] / [3]:** accept the user's correction and update the relevant value. Confirm once
  more before proceeding.

Once confirmed, write the two lines into `.aid/works/{work}/REQUIREMENTS.md`, replacing the
`*(pending)*` seeds:

```
- **Name:** {confirmed name}
- **Description:** {confirmed description}
```

This write must leave the block in the **exact parse format** the reader expects:
`^\s*-\s*\*\*Name:\*\*\s*(.+)` and `^\s*-\s*\*\*Description:\*\*\s*(.+)`. No trailing
period on the Name; Description is one sentence ending with a period.

**This step is mandatory at COMPLETION** (not optional, not skippable). If `## 1. Objective`
is `*(pending)*` or absent, ask the user for a one-sentence description before proceeding.

### Step 4: Present Summary

**G2 whole-picture read-back (elicitation-engine.md Invariant 8):** this step fulfils
the requirement that the assembled intent be reflected back to the user before approval;
surface any re-confirmable assumptions (advisor-stance.md Rule G1b) here so the user
can revisit them.

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

### Step 5: Process Approval Response

- **[1] Approved:**
  - Set `**Interview State:** Approved` in STATE.md `## Interview State`
  - Add Change Log entry in REQUIREMENTS.md: `| {today} | Interview complete — approved | /aid-describe |`
  - Add Review History entry in STATE.md `## Interview State`
  - Update `.aid/knowledge/INDEX.md` and `.aid/knowledge/README.md`
    if they exist
  - If a catalogued `issue-tracker` connector exists in `.aid/connectors/` → print a suggestion:
    "Consider filing an epic-type ticket for this work — run `/aid-create-ticket --level epic
    <description>`." Optional, user-initiated, never auto-invoked; silent (no output) if no
    issue-tracker connector is catalogued.
  - Print: `✅ Requirements approved.`
  - Emit pipeline pause signal (silent state-write — no output, no gate):
    ```
    bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
    bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "Requirements approved — run /aid-define {work} to decompose into features"
    bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ```
  - Print the pause reason and resume command: `[Pause] Requirements approved. Run /aid-define {work} to decompose into features.` and exit (this state is **PAUSE-FOR-USER-DECISION** — does NOT auto-chain).

- **[2] Additional consideration:**
  - Incorporate into relevant section(s) of REQUIREMENTS.md
  - Update STATE.md `## Interview State` section statuses if needed
  - Return to Interview Loop for any new gaps

**Advance:** **PAUSE-FOR-USER-DECISION** (contracted checkpoint per feature-002 SPEC IQ9 resolution 2026-05-24) — on approval, print the pause reason + resume command and exit. Run `/aid-define {work}` to decompose approved requirements into features. Do NOT chain — this is the only explicit no-auto-advance contract in the AID methodology.
