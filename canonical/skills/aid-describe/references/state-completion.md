# State: COMPLETION

All sections are Complete or N/A in STATE.md `## Interview State`; run quality check, KB hydration, and present requirements for approval.

### Step 1: Quality Check

Before presenting for approval, verify:
- [ ] All "Must" requirements in §5 have acceptance criteria in §9
- [ ] **Every criterion in §9 names an observable** — a command and its expected
      result, a file and its content, a count, a threshold, or a user-visible
      behaviour plus how to reproduce it. A judgment criterion must state what is
      judged and against what standard. Anything nothing could falsify is not a
      criterion; send it back rather than approving it
      (`.aid/runtime/templates/requirements/requirements-template.md
      § Verifiable Acceptance Criteria`)
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
   and `.aid/knowledge/STATE.md` (KB section)

**This step is mandatory.** Do not skip it even if the user seems eager to approve.
The KB is consumed by all downstream phases — empty KB docs force specify/detail/execute
to guess.

After hydration is complete, proceed to the summary.

### Step 3: Compose and Confirm Identity Header

Before presenting the approval summary, compose the work's **Name** and **Description**
and present them to the user for confirmation. These values will be written into the
`- **Name:**` / `- **Description:**` block in `REQUIREMENTS.md` (placed immediately after
the `# Requirements` H1, before `## 1. Objective`).

**How to compose:**

- **Name** — derive a concise, human-readable title from the work's subject. It must be
  Title Case and must not end with a period. It should be short enough to serve as a
  dashboard work-overview title (e.g. "AID Live Dashboard", "Order Processing Refactor").
  Do NOT use the raw `work_id` slug as the Name.
- **Description** — write exactly one sentence that summarises what the work delivers and
  why, derived from the body of `## 1. Objective`. It is NOT the Objective text verbatim,
  and it is NOT free-form authored independently. Compose it by distilling the Objective
  into one sentence (the agent writes this sentence; the user confirms it).

**Present to the user**, as one question in the protocol's form. Record it first with
`bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Requirements --impact Medium --context '<the question, as shown>' --suggested 'Looks good' --asked-by aid-describe --step COMPLETION` (it prints the question's id), and record the answer with `--answer --id <id> --state <Answered|Skipped> --value '<the answer>' --applied-to 'REQUIREMENTS.md identity block'` once it comes:

```text
Requirements -- question 1 of 1 -- importance: medium
Shall I write this Name and Description at the top of REQUIREMENTS.md?
  Name: {composed Title Case name}
  Description: {one sentence derived from ## 1. Objective}
Why I ask: they are the work's title and summary on the dashboard.
My recommendation: write them as shown -- they come straight from the objective.
  1. Write them as shown (recommended)
  2. Change the Name or the Description (tell me which)
Or answer in your own words, or ask me to explain.
```

Process feedback:
- **Write as shown:** proceed with the composed values.
- **A change:** accept the user's correction and update the relevant value. Confirm once
  more before proceeding (a new question, in the same form).

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

The identity question is put to the user through the question protocol. It blocks the work, so this step
pauses on it until the user answers; Step 4 (Present Summary) follows, inside this step, once the identity
fields are confirmed and written.

### Step 4: Present Summary

**G2 whole-picture read-back (elicitation-engine.md Invariant 8):** this step fulfils
the requirement that the assembled intent be reflected back to the user before approval;
surface any re-confirmable assumptions (advisor-stance.md Rule G1b) here so the user
can revisit them.

Show the summary first:

```
I believe I have enough information. Here's a summary:

**Objective:** [1-2 sentences from §1]
**Problem:** [1-2 sentences from §2]
**Key features:** [bullet list of must-haves from §5]
**Main constraints:** [bullet list from §7]
**Target users:** [list from §3]
```

Then ask the approval, as one question in the protocol's form. It blocks the work, so this step pauses on it
(`.aid/runtime/templates/skill-steps.md`, part 3). Record it first with
`bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-describe --step COMPLETION --covers 'the requirements REQUIREMENTS.md, with the small decisions confirmed here'`
(it prints the question's id), bring the step detail up to date with `--step` (done: summary shown; waiting for that id), and set the lifecycle to `Paused-Awaiting-Input` and the pause reason to that open question through the writer. Include the small decisions recorded `Assumed` so far, to be confirmed in this one approval.

```text
Requirements -- question 1 of 1 -- importance: high
Are the requirements above ready for the next phase?
Why I ask: approval lets the work move on to the feature breakdown; nothing moves on without it.
My recommendation: approve -- the summary matches what we settled and the quality check passed.
  1. Approve (recommended)
  2. Not yet -- there is something more to consider (tell me what)
Or answer in your own words, or ask me to explain.
```

An approval cannot be skipped: the step stays paused, with this step saved, until the user approves or adds a
consideration. Once it is answered, record the answer with `--answer --id <id> --state Answered --value '<Approved, or the consideration>' --applied-to 'REQUIREMENTS.md'` and set the lifecycle back to `Running` through the writer. Step 5 (Process Approval Response) follows, inside this step.

### Step 5: Process Approval Response

- **Approved:**
  - Set `**Interview State:** Approved` in STATE.md `## Interview State`
  - Add Review History entry in STATE.md `## Interview State`
  - Update `.aid/knowledge/INDEX.md` and `.aid/knowledge/README.md`
    if they exist
  - If a catalogued `issue-tracker` connector exists in `.aid/connectors/` → print a suggestion:
    "Consider filing an epic-type ticket for this work — run `/aid-create-ticket --level epic
    <description>`." Optional, user-initiated, never auto-invoked; silent (no output) if no
    issue-tracker connector is catalogued.
  - Print: `✅ Requirements approved.`
  - Bring the step detail up to date, so a later `/aid-describe` does not run COMPLETION again from the top (silent state-write, no output; a failed write stops the run):
    ```
    bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill aid-describe --name COMPLETION --detail 'done: requirements approved; next /aid-define {work}'
    ```
  - Record the pause through the writer (silent state-write, no output; a failed write stops the run):
    ```
    bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
    bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "Requirements approved — run /aid-define {work} to decompose into features"
    bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ```
  - Name the next skill in one plain line: `/aid-define {work}` decomposes the approved requirements into features. Then end the step with the HALT case of the advance line below; it does NOT auto-chain.

- **A consideration:**
  - Incorporate into relevant section(s) of REQUIREMENTS.md
  - Update STATE.md `## Interview State` section statuses if needed
  - End the step with the CHAIN case of the advance line below, which returns to the interview loop for any new gaps

On approval, name `/aid-define {work}` as the next skill in one plain line. Do not chain into it: this checkpoint needs an explicit user decision.

**Advance:** **CHAIN** → [State: CONTINUE] when the user adds a consideration; **HALT** when the user approves the requirements.
