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

Next step: /aid-execute task-001 {work-NNN-name}
```

The `{work-NNN-name}` work id is appended to the `/aid-execute` command so that
multi-work `.aid/` directories resolve unambiguously.

---

## Advance

Terminal state. No further state advance. The user's next step is:

```
/aid-execute task-001 {work-NNN-name}
```

---

## Unit-testable cases

| Input | Expected output |
|-------|----------------|
| LITE-DONE reached for LITE-BUG-FIX, 1 task | SPEC.md Status=Ready; lifecycle entry; hand-off printed with task-001 |
| LITE-DONE reached for LITE-FEATURE, 3 tasks | SPEC.md Status=Ready; lifecycle entry; hand-off prints task-001/002/003 |
| LITE-DONE entry already in lifecycle | Prints hand-off again; exits (idempotent) |
