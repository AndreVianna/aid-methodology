---
name: aid-config
description: >
  View or update AID pipeline settings. Bare invocation shows all values in a
  table; first run auto-creates .aid/settings.yml from the template. Pass a
  dotted key (e.g., /aid-config project.name) to view + update one setting
  interactively.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, AskUserQuestion
argument-hint: "(none) view all  |  <dotted.key> view+update one (e.g., project.name, review.minimum_grade)"
---

# AID Project Configuration

`/aid-config` reads and writes `.aid/settings.yml` — the single source of truth
for AID pipeline settings (grades, parallelism, heartbeat, project identity).

**Two modes, nothing else.**

| Invocation | What it does |
|---|---|
| `/aid-config` | Show all settings as a table. On first run (no `settings.yml`), copy the template into place first, then show. |
| `/aid-config <dotted.key>` | Show the current value of `<dotted.key>`; prompt for new (with suggestions + always a free-form option); validate; write in place. |

Examples: `/aid-config project.name`, `/aid-config review.minimum_grade`,
`/aid-config discover.minimum_grade` (per-skill override).

---

## Pre-flight

- ✅ `Default` or `Auto-accept edits` → proceed
- ❌ `Plan mode` → STOP. This skill writes files.

---

## Mode 1 — Show all settings (`/aid-config`)

### Step 1: Ensure `.aid/settings.yml` exists

If `.aid/settings.yml` is missing:
- Create `.aid/` directory if absent (do NOT touch `.aid/knowledge/` or other subdirs).
- Copy `.claude/templates/settings.yml` → `.aid/settings.yml` verbatim.
- Print: `Created .aid/settings.yml from template.`

### Step 2: Render the table

Read `.aid/settings.yml`. Print a table with these columns:
`Section | Key | Value`

Order: project (name, description, type), tools (installed), review (minimum_grade), execution (max_parallel_tasks), traceability (heartbeat_interval), then any per-skill override sections present.

If any value matches a `<placeholder>` pattern (e.g., `<project-name>`), append ` ⚠ unset` after the value.

### Step 3: Suggest commands for unset values + the general update form

After the table, ALWAYS print the line:
```
Run /aid-config <dotted.key> to update any value.
```

If ANY rows were marked `⚠ unset`, ALSO emit a copy-pasteable command per unset row, so the user can act without having to assemble the dotted key themselves:

```
N values unset. To set them:
  /aid-config project.name
  /aid-config project.description
```

Exit. No prompt; no further interaction.

---

## Mode 2 — View/update one key (`/aid-config <dotted.key>`)

### Step 1: Validate the key argument

Accepted dotted keys:
- `project.name`, `project.description`, `project.type`
- `tools.installed`
- `review.minimum_grade`
- `execution.max_parallel_tasks`
- `traceability.heartbeat_interval`
- `<skill>.minimum_grade` where `<skill>` ∈ {discover, summary, interview, specify, plan, detail, execute, deploy, monitor}

If the key doesn't match: print `❌ Unknown key: <key>` + the accepted list + exit.

### Step 2: Ensure `.aid/settings.yml` exists

Same as Mode 1 Step 1.

### Step 3: Read current value

Run:
```bash
bash .claude/scripts/config/read-setting.sh --path <key> --default '(unset)'
```

Print: `Current value of <key>: <value>`.

### Step 4: Prompt for new value

Use `AskUserQuestion` with 2–3 suggestion options (per the Suggestions table below) PLUS the standard `Other` free-form option that's always offered. Also offer a `Keep current value` option so the user can exit without change.

### Step 5: Validate

Per the Validation table below. If invalid: print the validation error + re-prompt (loop back to Step 4).

### Step 6: Save in place

Read `.aid/settings.yml` into memory. Replace the line containing `<key>` with the new value, preserving surrounding lines and inline comments. Use a same-directory temp file + `mv -f` for crash-safety (POSIX atomic rename), but no lock-dir mutex — `aid-config` is interactive single-user; concurrent writes are not a real failure mode.

For per-skill overrides on a skill section that doesn't yet exist (e.g., setting `discover.minimum_grade: A+` when no `discover:` block exists), append a new block:
```yaml

discover:
  minimum_grade: A+
```
at the end of the file.

### Step 7: Confirm

Print: `✓ <key>: <old> → <new>` and exit.

---

## Validation table

| Key | Valid values |
|---|---|
| `project.name` | Non-empty string, no whitespace |
| `project.description` | Non-empty single-line string (NO newlines — settings.yml uses inline YAML scalars) |
| `project.type` | `brownfield` or `greenfield` |
| `tools.installed` | List of `claude-code` / `codex` / `cursor` (at least one). Input formats: comma-separated, bracketed YAML inline (`[claude-code, codex]`), or newline-separated. Whitespace around items ignored. |
| `review.minimum_grade` | Regex `^[A-F][+-]?$`. E-grades are accepted but rarely useful as a floor. |
| `execution.max_parallel_tasks` | Positive integer |
| `traceability.heartbeat_interval` | Positive integer (minutes). `0` disables heartbeat. |
| `<skill>.minimum_grade` | Same regex as `review.minimum_grade`. |

---

## Suggestions table (for Mode 2 AskUserQuestion)

| Key | Suggestions |
|---|---|
| `project.name` | (no defaults — user types their own) |
| `project.description` | (no defaults — user types their own) |
| `project.type` | `brownfield`, `greenfield` |
| `tools.installed` | `[claude-code]`, `[claude-code, codex]`, `[claude-code, codex, cursor]` |
| `review.minimum_grade` | `A+`, `A`, `B+` |
| `execution.max_parallel_tasks` | `1`, `3`, `5`, `8` |
| `traceability.heartbeat_interval` | `0` (disabled), `1`, `5` |
| `<skill>.minimum_grade` | `A+`, `A`, `A-` |

Always include a `Keep current value` option and let `AskUserQuestion`'s built-in `Other` field handle free-form input.

---

## How consumer skills read settings

Consumer skills (`/aid-discover`, `/aid-execute`, etc.) resolve their settings using this order:

1. **Per-skill override key** (e.g., `discover.minimum_grade`) — use if present
2. **Global category default** (e.g., `review.minimum_grade`) — use otherwise
3. **Hardcoded skill default** — use only if `.aid/settings.yml` is missing entirely

The canonical resolution helper is `.claude/scripts/config/read-setting.sh`. Consumer skills invoke:

```bash
bash .claude/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A
```

---

## Schema reference

Canonical schema: `.claude/templates/settings.yml`. Top-level sections + per-skill overrides as described in the tables above.
