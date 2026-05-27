# aid-config — State: VIEW

```
[State: VIEW] — Showing current settings; select a key to update or exit.
aid-config  ▸ you are here
  [✓ INIT ] → [● VIEW ] → [ UPDATE ] → [ PERSIST ] → [ DONE ]
```

Render the current `.aid/settings.yml`, grouped by section. Highlight any key
whose value is a placeholder (e.g., `<project-name>`) so the user knows what
needs attention.

Then prompt: select a key to update, or exit.

---

## Step 1: Render the current settings

Read `.aid/settings.yml`. Print grouped by section with a stable numeric index
so the user can select by number.

Example output:

```
Current .aid/settings.yml:

[project]
  1.  name             my-project
  2.  description      A short project description.
  3.  type             brownfield

[tools]
  4.  installed        [claude-code, codex]

[review]
  5.  minimum_grade    A

[execution]
  6.  max_parallel_tasks   5

[traceability]
  7.  heartbeat_interval   1 minute(s)

[per-skill overrides — currently none]

──────────────────────────────────────────────
Select a number to update, or type 'exit' to leave settings unchanged.
```

If any value matches `<...>` (placeholder pattern), append `⚠️ unset` after it
on the same line so the user knows it needs attention.

If `--show` was passed, print the rendered settings + exit (skip the prompt; do
NOT advance to UPDATE).

---

## Step 2: Prompt for selection

Use the AskUserQuestion tool (or inline prompt) to ask:

```
Select a key to update by number, OR type:
  - 'add' to add a per-skill override (discover, summary, interview, specify, plan, detail, execute, deploy, monitor)
  - 'exit' to leave settings unchanged and return to terminal
```

Wait for user input.

---

## Step 3: Route based on input

| Input | Action |
|---|---|
| Number `1`-`N` matching a rendered key | Capture key path (e.g., `project.name`) → advance to UPDATE state |
| `add` | Prompt: which skill? List the 9 skill names; capture choice → advance to UPDATE state with `<skill>.minimum_grade` as the target key |
| `exit` | Print `✅ No changes. Run /aid-config again any time.` → advance to DONE |
| invalid | Re-print menu + re-prompt |

---

## Advance

For UPDATE: print
```
Next: [State: UPDATE] — run /aid-config again to enter the new value for <key>.
```
And record the target key in a brief breadcrumb (e.g., `.aid/.temp/aid-config-pending.txt`
containing the single line `key: project.name`). Exit.

For DONE: see `state-done.md`.

---

## Why a `.temp` breadcrumb?

Per the principle that each skill invocation is ONE state transition + exit, we
need a tiny piece of inter-invocation state to remember "which key the user
selected in VIEW for the UPDATE state to operate on." The breadcrumb is:

- Path: `.aid/.temp/aid-config-pending.txt`
- Format: single line `key: <dotted-path>`
- Lifecycle: written on VIEW → UPDATE advance; consumed + deleted on UPDATE → PERSIST advance

If the breadcrumb is missing when UPDATE state is detected, fall back to asking
the user which key (per VIEW Step 2 prompt).
