# Lite → Full Escalation

Shared procedure invoked from any lite-path state (CONDENSED-INTAKE, TASK-BREAKDOWN,
LITE-REVIEW, LITE-DONE) when the user or agent determines the work is too complex
for the lite path.

**Trigger:** user types `/aid-interview escalate`, or selects an escalate option
presented by the current lite-path state.

**Reverse not implemented.** There is no full → lite escalation path (per FR1 scope).

---

## Step 1: Collect escalation rationale

Ask the user ONE follow-up question (skip if rationale was already given as part of the
escalate selection):

```
Why escalate to full path?
(e.g., "scope is broader than expected", "too many features discovered",
"need full REQUIREMENTS.md and feature decomposition")
```

Wait for the user's response. Record it as `{escalation-rationale}`.

---

## Step 2: Collect all captured slot values

Gather every piece of information already collected in the current lite-path sub-path
session. This includes:

- All question slots answered in CONDENSED-INTAKE (e.g., `bug-title`, `bug-description`,
  `reproduction-steps`, `intended-behavior`, `doc-title`, `doc-purpose`, `outline-bullets`,
  `scope`, `before-sketch`, `after-sketch`, `ac`, `feature-title`, `goal`, `ac-1`,
  `ac-additional`)
- Work-root `SPEC.md` content (if CONDENSED-INTAKE was completed)
- Task files in `tasks/` (if TASK-BREAKDOWN was completed)
- Review grade and findings (if LITE-REVIEW was completed)

---

## Step 3: Write `## Escalation Carry` block to STATE.md

Append the following section to `STATE.md` (after `## Triage`, before `## Interview Status`
if that section exists, otherwise at the end of the Triage block):

```markdown
## Escalation Carry

> Written by lite→full escalation. Full-path interview reads this section to seed
> REQUIREMENTS.md without re-asking questions already answered.

- **Escalated from:** {current state name} (Sub-path: {Sub-path value})
- **Escalated at:** {YYYY-MM-DDTHH:MM:SSZ}
- **Escalation rationale:** {escalation-rationale}

### Captured Slot Values

{For each slot answered in CONDENSED-INTAKE, write:}
- **{slot-name}:** {slot-value}

{If no slots were answered (escalation happened before any sub-path questions):}
- (no slots captured — escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

{If work-root SPEC.md exists:}
- **SPEC.md:** present — contains `## Goal`, `## Context`, `## Acceptance Criteria`
  (use to seed REQUIREMENTS.md §§ Objective, Functional Requirements, Acceptance Criteria)

{If tasks/ folder contains task files:}
- **tasks/:** {N} task files present — use as candidate tasks when PLAN.md is created

{If LITE-REVIEW grade was recorded:}
- **LITE-REVIEW grade:** {grade} — recorded for reference; does not carry over to full-path gate
```

**Write immediately. Do not batch.**

---

## Step 4: Update `## Triage` in STATE.md

Rewrite the `## Triage` block as follows:

```markdown
## Triage

- **Path:** escalated
- **Decision rationale:** {original decision rationale} → escalated to full — {escalation-rationale}
```

Rules:
- `Path` changes from `lite` to `escalated`.
- `Work Type`, `Sub-path`, `Sub-path (auto)`, `Override`, and `Recipe` fields are **absent**
  (removed, not written as "n/a") — same contract as the TRIAGE-step [3] escalation from
  task-015.
- Preserve the original `Decision rationale` text and append the escalation clause.

**Write immediately after Step 3.**

---

## Step 5: Ensure REQUIREMENTS.md scaffold exists

If `.aid/{work}/REQUIREMENTS.md` does not exist, create it by copying
`../../templates/requirements.md` and adding the first Change Log entry:

```
| {today} | Interview restarted — escalated from lite path ({Sub-path}) | /aid-interview escalation |
```

If `REQUIREMENTS.md` already exists (unlikely at lite-path stage), add only the Change
Log entry.

---

## Step 6: Ensure `## Interview Status` scaffold exists in STATE.md

If `STATE.md` does not have an `## Interview Status` section (lite-path works omit it),
insert the standard scaffold from `../../templates/work-state-template.md`:

```markdown
## Interview Status

**Status:** In Progress · **Grade:** Pending

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Pending | — |
| 2 | Problem Statement | Pending | — |
| 3 | Users & Stakeholders | Pending | — |
| 4 | Scope | Pending | — |
| 5 | Functional Requirements | Pending | — |
| 6 | Non-Functional Requirements | Pending | — |
| 7 | Constraints | Pending | — |
| 8 | Assumptions & Dependencies | Pending | — |
| 9 | Acceptance Criteria | Pending | — |
| 10 | Priority | Pending | — |
```

**Pre-seed from Escalation Carry:**

After inserting the scaffold, mark sections that can be inferred from carried slot values:

| Carried slot(s) | Sections to pre-seed as Partial |
|---|---|
| `goal` / `bug-description` / `doc-purpose` / `before-sketch` | § 1 Objective, § 2 Problem Statement |
| `scope` / `feature-title` / `bug-title` / `doc-title` | § 4 Scope |
| `ac` / `ac-1` / `ac-additional` / `intended-behavior` | § 9 Acceptance Criteria |
| `outline-bullets` | § 5 Functional Requirements |

For each pre-seeded section, set Status = `Partial` and Last Updated = {today}.

---

## Step 7: Seed REQUIREMENTS.md from carried slot values

Write the inferred content into `REQUIREMENTS.md` for each pre-seeded section.
Use the slot values as a starting point — the full-path interview will deepen them.

| Carried slot(s) | Target REQUIREMENTS.md section | Seed content |
|---|---|---|
| `feature-title` / `bug-title` / `doc-title` / `scope` | § Objective | "Lite-path title: {title}. Escalated to full path — see § Context for details." |
| `goal` / `bug-description` / `doc-purpose` / `before-sketch` | § Problem Statement | Slot value verbatim, prefixed with "Captured before escalation: " |
| `scope` | § Scope | Slot value verbatim |
| `ac` / `ac-1` / `ac-additional` / `intended-behavior` | § Acceptance Criteria | Slot values as checklist items, prefixed "[lite-carry]" |
| `outline-bullets` | § Functional Requirements | Slot value verbatim |

**Write immediately. Mark each seeded section in `## Interview Status` as `Partial`.**

---

## Step 8: Add Lifecycle History entry

Add to `STATE.md ## Lifecycle History`:

```
| {today} | Escalated from {current-state} to full path — {escalation-rationale} | /aid-interview escalation |
```

---

## Step 9: Print escalation summary and exit

```
Escalated to full path.

Captured info preserved in STATE.md ## Escalation Carry.
REQUIREMENTS.md seeded from {N} slot(s): {slot names}.

Next: [State: CONTINUE] — run /aid-interview again
```

The state detection in `SKILL.md` reads `**Path:** escalated` as equivalent to `full` and
routes to CONTINUE (State 3), where the carried answers are visible in REQUIREMENTS.md
and `## Escalation Carry`.

---

## State Detection contract (escalated path)

`SKILL.md` State Detection step (f) reads:

> If `**Path:** full` (or `escalated`) — route through full-path detection

This means `Path: escalated` causes State Detection to enter the full-path branch, reading
`## Interview Status` to determine whether to enter CONTINUE, COMPLETION, etc. Because
Step 6 above ensures `## Interview Status` exists with `In Progress` status and some
`Partial` sections, the first post-escalation invocation always enters **State 3: CONTINUE**.

---

## Unit-testable cases

| Trigger state | Slots carried | Expected STATE.md outcome | Expected REQUIREMENTS.md | Next state |
|---|---|---|---|---|
| CONDENSED-INTAKE (no questions answered yet) | none | `## Escalation Carry` with "(no slots captured)"; `Path: escalated` | Scaffold created; no sections pre-seeded (all Pending) | CONTINUE |
| CONDENSED-INTAKE (LITE-BUG-FIX, 2 of 4 questions answered) | `bug-title`, `bug-description` | Carry block lists both slots; §1 Objective + §2 Problem Statement pre-seeded as Partial | §Objective + §Problem Statement seeded | CONTINUE |
| CONDENSED-INTAKE (LITE-FEATURE, all 5 questions answered) | all 5 slots | All 5 slots in carry; SPEC.md artifact listed; §1/2/4/9 pre-seeded as Partial | 4 sections seeded | CONTINUE |
| TASK-BREAKDOWN (user selects [3] Escalate) | SPEC.md present + tasks/ present | Carry block: SPEC.md + N task files noted; `Path: escalated` | Seeded from SPEC.md content | CONTINUE |
| LITE-REVIEW (user selects [4] Escalate) | SPEC.md present + tasks/ present + grade recorded | Carry block: SPEC.md + tasks + grade; `Path: escalated` | Seeded from SPEC.md content | CONTINUE |
| LITE-DONE (user selects escalate after hand-off) | SPEC.md Ready + tasks/ present | Same as LITE-REVIEW case; SPEC.md status reset to Draft | Seeded from SPEC.md content | CONTINUE |
