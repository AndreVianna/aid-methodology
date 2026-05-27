# aid-config — State: UPDATE

```
[State: UPDATE] — Prompt for new value + validate; then PERSIST writes to disk.
aid-config  ▸ you are here
  [✓ INIT ] → [✓ VIEW ] → [● UPDATE ] → [ PERSIST ] → [ DONE ]
```

Operate on the key the user selected in VIEW state (recorded in
`.aid/.temp/aid-config-pending.txt`). Show the current value, valid options,
and the canonical default. Prompt for new value, validate it, then advance to
PERSIST.

---

## Step 1: Read the pending key

Read `.aid/.temp/aid-config-pending.txt`. Extract the `key:` line.

**If invoked via the quick-set form** (`/aid-config KEY=VALUE` per SKILL.md
"Quick-set form"), the dispatcher skips VIEW and there is no pending-file
breadcrumb. The positional arg is delivered as the skill's argument string
(`$1` in bash, or the equivalent in the host's slash-command runtime).
Parse it directly:

```bash
# Slash-command invocation: /aid-config review.minimum_grade=A-
#   → arg = "review.minimum_grade=A-"
if [[ -n "${1:-}" && "$1" == *=* ]]; then
  KEY="${1%%=*}"     # left of first '=' → dotted key path
  VALUE="${1#*=}"    # right of first '=' → value (preserves embedded '=' in value)
  # Skip Step 3 prompt (value is already known); go straight to Step 4 validation
  # with KEY and VALUE bound.
fi
```

If `$1` is absent AND the breadcrumb file is missing, fall back to asking
the user which key (per VIEW state Step 2).

---

## Step 2: Show context for the key

For the selected key, print:

```
Updating: <key-path>

Current value:   <current-value-from-settings.yml>
Canonical default: <default-from-.claude/templates/settings.yml>
Valid values:    <see table below>
```

### Validation table

| Key path | Valid values | Canonical default |
|---|---|---|
| `project.name` | non-empty string, no spaces | `<project-name>` (placeholder) |
| `project.description` | non-empty single-line string (NO newlines — settings.yml uses inline YAML scalars; multi-line input must be reformatted or rejected) | `<project-description>` (placeholder) |
| `project.type` | `brownfield` or `greenfield` | `brownfield` |
| `tools.installed` | list of `claude-code` / `codex` / `cursor` (at least one). Accepted input formats: comma-separated (`claude-code,codex`), bracketed YAML inline (`[claude-code, codex]`), or newline-separated. Whitespace around items ignored. Each item must match `^[a-z][a-z0-9-]+$` and be one of the canonical 3. | `[claude-code]` |
| `review.minimum_grade` | regex `^[A-F][+-]?$` | `A` |
| `execution.max_parallel_tasks` | positive integer | `5` |
| `traceability.heartbeat_interval` | positive integer (minutes) | `1` |
| Per-skill override (`<skill>.minimum_grade`) | regex `^[A-F][+-]?$`, OR `remove` to delete the override | (no default — when removed, falls back to `review.minimum_grade`) |

---

## Step 3: Prompt for new value

Use AskUserQuestion or inline prompt:

```
Enter new value for <key-path>, OR type:
  - 'default' to reset to canonical default
  - 'remove' (per-skill overrides only) to delete this override
  - 'back' to return to VIEW without changing
```

Wait for user input.

---

## Step 4: Validate

Validate per the table above. Specific checks:

- **Grade values** — must match `^[A-F][+-]?$`. Reject `A++` or `Z-` etc.
- **Integers** — must be positive integers. Reject `0`, negatives, decimals.
- **`tools.installed`** — must contain at least one of `claude-code`, `codex`, `cursor`. Reject unknown tools.
- **`project.type`** — must be exactly `brownfield` or `greenfield`.
- **String fields** — non-empty, no leading/trailing whitespace.
- **`project.description`** — additionally, MUST NOT contain newlines. The
  settings.yml schema serializes the description as an inline YAML scalar
  (`description: <text>` on one line). Multi-line input corrupts the YAML.
  If the user pastes a multi-line value, reject with: "project.description
  must be single-line. Got <N> lines. Please consolidate or shorten."

If invalid, print the validation error and re-prompt (loop back to Step 3).

---

## Step 5: Stage the change

Write the validated new value to a staging file at
`.aid/.temp/aid-config-staged.txt`:

```
key: <key-path>
new_value: <validated-new-value>
```

The PERSIST state reads this staging file and applies the change atomically.

Delete the pending breadcrumb (`.aid/.temp/aid-config-pending.txt`).

---

## Special handling: `back`

If the user typed `back`:

- Delete `.aid/.temp/aid-config-pending.txt`
- Do NOT write `.aid/.temp/aid-config-staged.txt`
- Print `↩ Returning to settings view (no change).`
- Advance to VIEW state (next `/aid-config` invocation will re-render)

Exit.

---

## Advance

For staged change:
```
Next: [State: PERSIST] — run /aid-config again to write the change to disk.
```

For `back`:
```
Next: [State: VIEW] — run /aid-config again to view settings.
```

Exit.
