# State: LITE-REVIEW (L3)

Runs after TASK-BREAKDOWN (L2). This is the lite path's single pre-execution
quality gate — it validates the task set against the work-root `SPEC.md` using
the universal grading rubric before handing off to `aid-execute`.

**Agent:** Dispatch `aid-reviewer` (override `subagent_type`, clean context). This
is adversarial validation, not interview work.

> This gate is *pre-execution* quality of the plan. It is distinct from FR2's
> *post-execution* per-delivery quality gate (run by `aid-execute`).

---

## Idempotency check

Read `STATE.md ## Lifecycle History`. If it contains a `LITE-REVIEW complete`
entry, this state is already done — skip to LITE-DONE.

Print: `[State: LITE-REVIEW] Sub-path: {Sub-path}`
Print before dispatch: `[State: LITE-REVIEW] Dispatching aid-reviewer for lite-path pre-execution gate.`

---

## Dispatch

The aid-reviewer writes findings to `.aid/.temp/review-pending/interview-<work>-lite.md`
per `.claude/aid/templates/reviewer-ledger-schema.md` (ONE markdown table, no narrative).

```
▶ aid-reviewer starting
Read `references/state-lite-review.md` for the full review process.
✓ aid-reviewer done — or ✗ aid-reviewer failed: {reason}
```

After aid-reviewer returns, run grade.sh on the ledger:

```bash
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/interview-<work>-lite.md
```

---

## Review process (aid-reviewer)

### Step 1: Load context

Read:
- Work-root `SPEC.md` — for `## Goal`, `## Context`, `## Acceptance Criteria`,
  `## Tasks`, `## Execution Graph`
- All `tasks/task-NNN/SPEC.md` files (directly under the work folder — no `deliveries/`,
  no `delivery-001/` folder)
- `STATE.md ## Triage` — for `Sub-path`
- `../../../templates/grading-rubric.md` — the universal grading rubric
- `.aid/knowledge/INDEX.md` — for KB context if relevant

### Step 2: Write findings to ledger and grade

Evaluate the task set against the work-root `SPEC.md` using the universal rubric.
For the lite path, the key checks are:

| Check | Criterion |
|-------|-----------|
| Coherent breakdown | Every task is a single reviewable unit; types are not mixed |
| Traceability | Every task traces to at least one `## Acceptance Criteria` entry |
| Testable criteria | Each task's AC is concrete and verifiable (not vague) |
| Graph completeness | No gaps in the Execution Graph; every task with dependencies lists them |
| Sub-path contract | SPEC.md shape matches the sub-path's required shape (see CONDENSED-INTAKE) |
| Scope fit | Task count is within the sub-path's expected range (1–2 for BUG-FIX, 1 for DOC, 1–3 for REFACTOR, 1–5 for FEATURE) |

Write findings to `.aid/.temp/review-pending/interview-<work>-lite.md` per
`.claude/aid/templates/reviewer-ledger-schema.md`. The table is the entire file content
— no headers, no narrative. Each issue is one row with Severity and Status: Pending.

The grade is computed by the orchestrator via grade.sh (not assigned by the aid-reviewer
directly).

### Step 3: Present findings

Present findings to the user:

```
[LITE-REVIEW] Grade: {grade}

{If grade >= minimum:}
Task set is ready for execution. All checks passed.

{If grade < minimum:}
Issues found:

  [{severity}] {finding} — affects: {task-NNN or SPEC.md section}
  ...

Recommended action: {loopback to L1 | loopback to L2}
  - Context wrong (Goal/Context/AC issues) → loopback to CONDENSED-INTAKE (L1)
  - Breakdown wrong (task structure/graph issues) → loopback to TASK-BREAKDOWN (L2)

[1] Proceed despite findings (override — record in lifecycle)
[2] Fix {L1 context issues} — loopback to CONDENSED-INTAKE
[3] Fix {L2 breakdown issues} — loopback to TASK-BREAKDOWN
[4] Escalate to full path
```

**Minimum grade:** read from `bash .claude/aid/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A` if it
exists, otherwise apply the rubric's default minimum.

Wait for user response.

### Step 4: Record grade

Write the review result to the work-root `STATE.md ## Delivery Gate` section (a lite work
has no `delivery-001/` folder — the work IS the delivery, so its gate is authored directly
in the work-root STATE.md; see `work-state-template.md`):

```markdown
## Delivery Gate

- **Reviewer Tier:** Small
- **Grade:** {grade}
- **Issue List:** {comma-separated [HIGH]/[CRITICAL] findings, or "none"}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}
```

### Step 5: Handle response

- **Grade >= minimum (or [1] override):**
  - Add lifecycle entry: `| {today} | LITE-REVIEW complete — Grade: {grade} | /aid-describe LITE-REVIEW |`
  - Advance to LITE-DONE.

- **[2] Loopback to CONDENSED-INTAKE:**
  - Add lifecycle entry: `| {today} | LITE-REVIEW loopback → CONDENSED-INTAKE — {reason} | /aid-describe LITE-REVIEW |`
  - Exit. Detection will route to CONDENSED-INTAKE on next run (SPEC.md sections will be rewritten).

- **[3] Loopback to TASK-BREAKDOWN:**
  - Delete the `tasks/` folder contents directly under the work folder (task folders are
    regenerated by L2; there is no `deliveries/` or `delivery-001/` folder to delete).
  - Reset the work-root STATE.md `## Delivery Lifecycle` + `## Delivery Gate` sections
    to placeholders (regenerated by L2).
  - Reset `## Tasks` and `## Execution Graph` in work-root SPEC.md to placeholder rows.
  - Add lifecycle entry: `| {today} | LITE-REVIEW loopback → TASK-BREAKDOWN — {reason} | /aid-describe LITE-REVIEW |`
  - Exit. Detection will route to TASK-BREAKDOWN on next run (tasks/ absent or empty).

- **[4] Escalate:**
  - Invoke `references/lite-to-full-escalation.md` (lite→full escalation procedure).
    Pass current state name (`LITE-REVIEW`) and all captured info: the work-root
    `SPEC.md`, all task files in `tasks/task-NNN/SPEC.md`, and the review
    grade + findings just recorded in the work-root `STATE.md ## Delivery Gate`.
  - Exit LITE-REVIEW after escalation completes.

---

## Advance

**CHAIN** → [State: LITE-DONE] (continue inline).

---

## Unit-testable cases

| Input | Expected output |
|-------|----------------|
| Grade >= minimum | work-root `STATE.md ## Delivery Gate` written; lifecycle entry `LITE-REVIEW complete`; advance to LITE-DONE |
| Grade < minimum, user selects loopback to L1 | Lifecycle entry with reason; exit (next run enters CONDENSED-INTAKE) |
| Grade < minimum, user selects loopback to L2 | tasks/ reset; work-root STATE.md `## Delivery Lifecycle` + `## Delivery Gate` reset to placeholders; SPEC.md Tasks+Graph reset; lifecycle entry; exit (next run enters TASK-BREAKDOWN) |
| Grade < minimum, user selects [1] override | Grade recorded in work-root STATE.md `## Delivery Gate`; lifecycle entry notes override; advance to LITE-DONE |
| User selects [4] Escalate | `lite-to-full-escalation.md` invoked; SPEC.md + tasks/ + grade carried; `Path: escalated` written; REQUIREMENTS.md seeded; exit LITE-REVIEW; next state = CONTINUE |
| LITE-REVIEW already complete in lifecycle | Skip; advance to LITE-DONE (idempotent) |
