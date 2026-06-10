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

Also update the work STATUS header in STATE.md (the `> **Status:**` line):

```
> **Status:** Interview Complete
> **Phase:** Interview
```

---

## Step 3: Print hand-off

```
Lite path complete for {work-NNN-name}. {N} tasks ready in tasks/.
Delivery descriptor: .aid/{work-NNN-name}/SPEC.md

Sub-path completed: {Sub-path}

Tasks ready:
  task-001 [{Type}] — {title}
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
   and all captured info: the work-root `SPEC.md`, all task files in `tasks/`, and the
   `LITE-REVIEW` grade (if recorded in `STATE.md ## Delivery Gates`).

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
| LITE-DONE reached for LITE-BUG-FIX, 1 task | SPEC.md Status=Ready; lifecycle entry; hand-off printed with task-001 |
| LITE-DONE reached for LITE-FEATURE, 3 tasks | SPEC.md Status=Ready; lifecycle entry; hand-off prints task-001/002/003 |
| LITE-DONE entry already in lifecycle | Prints hand-off again; exits (idempotent) |
| User selects [E] Escalate at LITE-DONE | SPEC.md reset to Draft; `lite-to-full-escalation.md` invoked; SPEC.md + tasks/ + LITE-REVIEW grade carried; `Path: escalated` written; REQUIREMENTS.md seeded; next state = CONTINUE |
