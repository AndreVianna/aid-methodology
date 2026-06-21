# State: LITE-DONE (L4)

Terminal state for the lite path. Sets the work-root `SPEC.md` to `Ready` status,
records final lifecycle state, and prints the hand-off prompt to `/aid-execute`.

No dispatch — this state runs inline (no agent override needed).

---

## Idempotency check

Read `STATE.md ## Lifecycle History`. If it contains a `LITE-DONE` entry, the
hand-off is already complete. Print the hand-off prompt again and exit.

Print: `[State: LITE-DONE]`

---

## Step 0: Verify and compose identity block (MANDATORY GATE)

**This step is mandatory at LITE-DONE (not optional, not skippable).**

Read the work-root `SPEC.md` identity block (the lines immediately after the `# {title}` H1).
Check for `- **Name:**` and `- **Description:**`. The gate fails (must be fixed now) if either:

- The line is absent from the SPEC, OR
- Its value is still `*(pending)*`.

If either condition holds, compose the missing field(s) now from the SPEC itself:

- **Name** — derive a concise Title-Case title from the SPEC `# {H1}` title (no trailing period;
  NOT the `work_id` slug; strip any ` — Refactor` / ` — Bug Fix` suffixes that are already
  described by the sub-path). Write it as: `- **Name:** {composed Name}`
- **Description** — derive exactly one sentence from the SPEC `## Goal` body (distilled from the
  problem/objective; no trailing period). Write it as: `- **Description:** {composed Description}`

Parse format that the reader expects (exact):
- Name line: `^\s*-\s*\*\*Name:\*\*\s*(.+)` (case-insensitive); captured group is the value.
- Description line: `^\s*-\s*\*\*Description:\*\*\s*(.+)` (case-insensitive); captured group is the value.

Write the composed value(s) into `SPEC.md` immediately (update the file before proceeding to Step 1).
The value must be a real composed string — `*(pending)*` is **never** acceptable at LITE-DONE.

---

## Step 1: Set SPEC.md status to Ready

Update the work-root `SPEC.md` metadata block:

```markdown
- **Status:** Ready
```

(Change `Draft` → `Ready`.)

---

## Step 2: Record lifecycle completion

Add entry to `STATE.md ## Lifecycle History`:

```
| {today} | LITE-DONE — lite path complete; {N} tasks ready | /aid-interview LITE-DONE |
```

Also update the work state header in STATE.md (the `> **State:**` line):

```
> **State:** Interview Complete
> **Phase:** Interview
```

---

## Step 3: Print hand-off

```
Lite path complete for {work-NNN-name}. {N} tasks ready in delivery-001/.
Work descriptor:     .aid/{work-NNN-name}/SPEC.md
Delivery descriptor: .aid/{work-NNN-name}/delivery-001/SPEC.md

Sub-path completed: {Sub-path}

Tasks ready:
  task-001 [{Type}] — {title}    (.aid/{work-NNN-name}/delivery-001/tasks/task-001/SPEC.md)
  task-002 [{Type}] — {title}    ← only if present
  ...

Next step: /aid-execute {work-NNN-name} task-001

[E] Escalate to full path instead (e.g., scope revealed too broad for lite execution)
```

Wait for user response. If the user types `E`, `escalate`, or `/aid-interview escalate`:
escalate (see below). Otherwise, the session ends — no further state machine advance.

---

## Escalation from LITE-DONE

Although LITE-DONE is the terminal lite-path state, the user may still escalate after
seeing the hand-off (e.g., they realize the task list is too broad for lite execution).

When escalation is triggered from LITE-DONE:

1. Reset `SPEC.md` status back to `Draft` (reverse the Step 1 change that set it to
   `Ready`) before invoking the escalation procedure — the full path will manage
   SPEC.md status independently.
2. Invoke `references/lite-to-full-escalation.md`. Pass current state name (`LITE-DONE`)
   and all captured info: the work-root `SPEC.md`, all task files in
   `delivery-001/tasks/task-NNN/SPEC.md`, and the `LITE-REVIEW` grade (if recorded
   in `delivery-001/STATE.md ## Delivery Gate`).

The `{work-NNN-name}` work id leads the `/aid-execute` command so that
multi-work `.aid/` directories resolve unambiguously.

---

## Advance

Terminal state. No further state advance. The user's next step is:

```
/aid-execute {work-NNN-name} task-001
```

---

## Unit-testable cases

| Input | Expected output |
|-------|----------------|
| LITE-DONE reached for LITE-BUG-FIX, 1 task | Step 0 passes (Name+Description already set); SPEC.md Status=Ready; lifecycle entry; hand-off printed with task-001 |
| LITE-DONE reached for LITE-FEATURE, 3 tasks | Step 0 passes; SPEC.md Status=Ready; lifecycle entry; hand-off prints task-001/002/003 |
| SPEC.md has `*(pending)*` Name at LITE-DONE | Step 0 composes Name from H1 and writes it before setting Status=Ready |
| SPEC.md missing Description at LITE-DONE | Step 0 composes Description from ## Goal body and writes it |
| LITE-DONE entry already in lifecycle | Prints hand-off again; exits (idempotent) |
| User selects [E] Escalate at LITE-DONE | SPEC.md reset to Draft; `lite-to-full-escalation.md` invoked; SPEC.md + delivery-001/tasks/ + LITE-REVIEW grade carried; `Path: escalated` written; REQUIREMENTS.md seeded; next state = CONTINUE |
