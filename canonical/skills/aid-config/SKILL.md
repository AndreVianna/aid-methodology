---
name: aid-config
description: >
  View or update AID pipeline settings. Use this skill when you need to see how the pipeline
  is configured, or change one setting such as the project name, its type, or the minimum
  grade. A bare invocation creates `.aid/settings.yml` from the template on the first run, prints
  every value in a table and walks the settings in groups, one question at a time. Passing a key --
  `/aid-config` name -- views and updates that one setting interactively.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit
argument-hint: "(none) view all and walk the settings  |  <key> view+update one (e.g., name, minimum_grade)"
---

# AID Project Configuration

`/aid-config` reads and writes `.aid/settings.yml` — the single source of truth
for AID pipeline settings (grades, heartbeat, project identity).

**Two modes, nothing else.** The walk is the bare invocation; the single-key mode is unchanged.

| Invocation | What it does |
|---|---|
| `/aid-config` | Walk mode. On first run (no `settings.yml`), copy the template into place first. Show all settings as a table, then walk them in groups, one question per message. |
| `/aid-config <key>` | Show the current value of `<key>`; prompt for new (with suggestions + always a free-form option); validate; write in place. |

Examples: `/aid-config name`, `/aid-config minimum_grade`,
`/aid-config source_control`.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

---

## Pre-flight

- ✅ `Default` or `Auto-accept edits` → proceed
- ❌ `Plan mode` → STOP. This skill writes files.

---

## Mode 1 — Show all settings and walk them (`/aid-config`)

### Step 1: Ensure `.aid/settings.yml` exists

If `.aid/settings.yml` is missing:
- Create `.aid/` directory if absent (do NOT touch `.aid/knowledge/` or other subdirs).
- Copy `.aid/runtime/templates/settings.yml` → `.aid/settings.yml` verbatim.
- Print: `Created .aid/settings.yml from template.`

### Step 2: Render the table

Read `.aid/settings.yml`. Print a table with these columns:
`Key | Value`

Order: `name`, `description`, `type`, `source_control`, `minimum_grade`, `heartbeat_interval`.

If any value matches a `<placeholder>` pattern (e.g., `<project-name>`), append ` ⚠ unset` after the value.

### Step 3: Walk the settings

The walk covers all six settings, so every one is decided or skipped on purpose, not only the ones that
are still `⚠ unset`. A setting that is set and sensible is asked with its current value as the
recommendation: option 1 is `Keep current value: <value> (recommended)`, followed by the other valid
suggestions. A setting that is `⚠ unset` is never offered `Keep current value` (that would keep a
placeholder): for `type`, `source_control`, `minimum_grade` and `heartbeat_interval` the recommendation is
a suggestion from the Suggestions table; for `name` and `description` it is a value read from the project
when one is available (for `name`, the title of the project's README, or the subject of an existing
description, read first; the project folder's name only when it is not a generic name such as `project`,
`app`, `src` or `repo`. For `description`, the first line of the README, or an existing description), with the source
named in `My recommendation`. When nothing usable can be read, say so plainly and ask for the user's own
words, with no numbered option (question-protocol Rule 5.1). A
setting skipped in an earlier run is asked again on its own entry (see below).

After the table, walk the settings straight away, with no break between a go-ahead (if one was asked) and the
first group, because they are one subject. Group them by subject, most important first, **3 to 5 questions
per group**, one question per message and one topic per question. Each question is shown in the form of
Mode 2 Step 4 (the same Suggestions table; a set value that is kept is option 1, `Keep current value:
<value> (recommended)`).

| Group | Settings, in order | Importance |
|---|---|---|
| 1. Project identity | `name` (high), `description` (high), `type` (high) | high |
| 2. Pipeline behaviour | `source_control` (medium), `minimum_grade` (medium), `heartbeat_interval` (low) | medium |

`n` and `m` in the form count the questions of the whole walk (`question 1 of 6`).

- **Record each question** before it is shown and its reply right after, in the project file
  `.aid/STATE.yml`, exactly as Mode 2 Step 4 sets (`writeback-state.sh --project --ask`, then `--project
  --answer`). A setting whose last entry is `Skipped` is asked again on that same entry: write no new
  `--ask`, and answer the open entry by its id (`--project --answer --id Q<n>`) when the user replies,
  so the entry closes as `Answered` (or stays `Skipped` when the user skips again). A non-zero exit stops
  the skill at once.
- **Write a setting only after its answer**, by Mode 2 Steps 5 to 7 (validate, save in place, confirm).
  A `Keep current value` answer or a skip writes nothing.
- **Offer a break when the subject changes**: between group 1 and group 2, and again before the last
  group of retried skipped settings when there is one, each time in one plain line that decides nothing
  (`Identity is done. Take a break, or go on to the pipeline settings?`; `Take a break, or go on to the
  settings you skipped?`). The user may stop there; the answers already given stay. There is no break
  between the go-ahead and the first group.
- **Skipped questions are offered again at the end**, once, in the same form, as a last group, on their
  own entries. A question skipped twice stays `Skipped` in `.aid/STATE.yml`, and the next `/aid-config`
  run walks that setting again on the same entry.
- At the end print the table again, and the line `Run /aid-config <key> to update any single value.`

Exit.

---

## Mode 2 — View/update one key (`/aid-config <key>`)

### Step 1: Validate the key argument

Accepted keys:
- `name`
- `description`
- `type`
- `source_control`
- `minimum_grade`
- `heartbeat_interval`

If the key doesn't match: print `❌ Unknown key: <key>` + the accepted list + exit.

### Step 2: Ensure `.aid/settings.yml` exists

Same as Mode 1 Step 1.

### Step 3: Read current value

Run:
```bash
bash .aid/runtime/scripts/config/read-setting.sh --path <key> --default '(unset)'
```

Print: `Current value of <key>: <value>`.

### Step 4: Prompt for new value

Ask for the new value for ALL keys, in plain text through the question protocol, with:
- A `Keep current value` option (shows the current value), only when the value is set; never for a
  `⚠ unset` placeholder
- 2–3 suggestion options from the Suggestions table below, the recommended one first

The options are numbered in the question. The closing line always lets the user type a value of their
own, ask for an explanation, or skip the question.

For free-text-natural keys (`name`, `description`), the Suggestions table has no fixed defaults. When the
value is set, the options are `Keep current value` and, if the project shows a better one, that value. When it
is `⚠ unset`, there is no `Keep current value`: recommend a value read from the project and name where it came
from, or, when none can be read, ask for the user's own words with no numbered option.

Show each question in the protocol's form (one question per message):

```text
Settings -- question {n} of {m} -- importance: {high|medium|low}
New value for <key>?
Why I ask: {what the setting controls, in one short reason}
My recommendation: {the suggested value, and why}
  1. {the recommended value} (recommended)
  2. {another suggestion}
  3. Keep current value: {current value}
Or answer in your own words (type a value of your own), ask me to explain, or skip this question.
```

**Recording.** This skill keeps no work record, so each question it asks is recorded in the project
file `.aid/STATE.yml` (`.aid/runtime/templates/question-protocol.md` § Where each record lives).
Before the question is shown:
`bash .aid/runtime/scripts/execute/writeback-state.sh --project --ask --category Settings --impact <High|Medium|Low> --context '<the question>' --suggested '<the recommendation>' --asked-by aid-config`,
which prints the question's id. Right after the answer:
`bash .aid/runtime/scripts/execute/writeback-state.sh --project --answer --id Q<n> --state <Answered|Skipped> --value '<the answer>' --applied-to 'setting <key>'`.
Choosing `Keep current value` is an `Answered` question whose `--applied-to` says the setting is unchanged. A re-prompt after a failed
validation (Step 5) is a new question, recorded the same way. A non-zero exit stops the skill at once.

### Step 5: Validate

Per the Validation table below. If invalid: print the validation error + re-prompt (loop back to Step 4).

### Step 6: Save in place

Read `.aid/settings.yml` into memory. `settings.yml` is a flat file — every user-editable
key is a top-level scalar (`<key>: <value>`), no section nesting. Replace the top-level line
for `<key>` if one is present; otherwise append a new top-level `<key>: <value>` line at the
end of the file. Preserve all other lines and inline comments exactly as they are. Use a
same-directory temp file + `mv -f` for crash-safety (POSIX atomic rename), but no lock-dir
mutex — `aid-config` is interactive single-user; concurrent writes are not a real failure mode.

### Step 7: Confirm

Print: `✓ <key>: <old> → <new>` and exit.

---

## Validation table

| Key | Valid values |
|---|---|
| `name` | Non-empty string, no whitespace |
| `description` | Non-empty single-line string (NO newlines — settings.yml uses inline YAML scalars) |
| `type` | `brownfield` or `greenfield` |
| `source_control` | `none`, `git`, `svn`, or `mercurial` |
| `minimum_grade` | Regex `^[A-F][+-]?$`. E-grades are accepted but rarely useful as a floor. |
| `heartbeat_interval` | Positive integer (minutes). `0` disables heartbeat. |

---

## Internal keys (producer-written — NOT user-configurable)

`/aid-config` deliberately does **not** expose these — they are absent from *Accepted keys*
(Mode 2 Step 1) **and** from the Validation table above. They are written and maintained
by pipeline producers, never by the user. Running `/aid-config knowledge` (or any
`knowledge.*` sub-path) is rejected as an unknown key (`❌ Unknown key`) — that is the
intended behavior, not a gap.

| Key | Owner / contract |
|---|---|
| `knowledge` | Nested block `{source: <default-branch>, last_update: <ISO-8601 commit date>, doc_set: [...], term_exclusions: [...]}`. `knowledge.source` (the branch compared for KB freshness) and `knowledge.last_update` are written by `aid-discover` (on KB approval, FR35) and `aid-housekeep` (re-stamp on KB-DELTA refresh, FR36); read by the dashboard reader for outdated-detection (feature-007 FF-A2). `knowledge.doc_set` and `knowledge.term_exclusions` are runtime-written by `aid-discover`; `knowledge.doc_set` is also appended (one entry per document created) by document-creating `create` skills -- `/aid-create-roadmap`, `/aid-create-backlog`, `/aid-create-architecture`, `/aid-create-stack`, `/aid-create-testing-strategy`, `/aid-create-cicd` -- in the same run that creates their document, using the same R13 append-block idiom. `/aid-create-mvp` is the one planning sibling that is **not** on this list: it writes no KB document, so it appends no entry. Absence-tolerant — a missing `knowledge` block means "no baseline recorded" and the reader stays `approved`. Producer write-path (R13): the first write is a multi-line nested block (`source:` + `last_update:` + `doc_set:` + `term_exclusions:`) via the append-block idiom; a later `last_update` re-stamp is a single-line replace of that nested line. |

---

## Suggestions table (for Mode 2 questions)

| Key | Suggestions |
|---|---|
| `name` | (no fixed defaults — a value read from the project, e.g. its README title; the folder name only when it is not generic, such as `project`, `app`, `src` or `repo`; else the user's own) |
| `description` | (no fixed defaults — a value read from the project, e.g. its README's first line; else the user's own) |
| `type` | `brownfield`, `greenfield` |
| `source_control` | `none`, `git`, `svn`, `mercurial` |
| `minimum_grade` | `A+`, `A`, `B+` |
| `heartbeat_interval` | `0` (disabled), `1`, `5` |

Always include a `Keep current value` option, unless the value is an unset placeholder (`⚠ unset`); the closing line of the question lets the user type a free-form value.

---

## How consumer skills read settings

Consumer skills (`/aid-discover`, `/aid-execute`, etc.) resolve `minimum_grade` using this order:

1. **`minimum_grade` in `.aid/settings.yml`** — use if present
2. **Hardcoded skill default** — use only if `.aid/settings.yml` is missing entirely, or the key is unset

The canonical resolution helper is `.aid/runtime/scripts/config/read-setting.sh`. Consumer skills invoke:

```bash
bash .aid/runtime/scripts/config/read-setting.sh --key minimum_grade --default A
```

---

## Schema reference

Canonical schema: `.aid/runtime/templates/settings.yml`. Flat top-level scalar keys
(`name`, `description`, `type`, `source_control`, `minimum_grade`, `heartbeat_interval`) as
described in the tables above. The `knowledge:` block is producer-written — see
*Internal keys* above, not user-configurable via this skill.
