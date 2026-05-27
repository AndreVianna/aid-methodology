---
name: aid-config
description: >
  Initialize an AID project AND manage pipeline settings ongoingly — the single
  source of truth for grades, parallelism, heartbeat, project metadata.
  First run scaffolds .aid/ + writes settings.yml from defaults.
  Subsequent runs: --show prints the current settings; KEY=VALUE (e.g.,
  /aid-config review.minimum_grade=A-) sets one value; bare invocation
  enters interactive VIEW → UPDATE → PERSIST flow.
  State machine: PRE-FLIGHT → (INIT | INIT-SETTINGS | VIEW) → UPDATE → PERSIST → VIEW → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
argument-hint: "[--show] view only · [--reset] rewrite settings.yml from defaults · [KEY=VALUE] quick-set one key (e.g., review.minimum_grade=A-)"
---

# AID Project Configuration

`/aid-config` is the **single skill for AID pipeline configuration** — both the
initial scaffold (first run, no `.aid/` yet) AND ongoing setting changes
(any run thereafter).

**Single source of truth.** All AID pipeline configuration lives in
`.aid/settings.yml`. Every other skill (`/aid-discover`, `/aid-execute`,
`/aid-summarize`, etc.) reads its settings from this file at invocation time.

**This is a conversational skill** in INIT and UPDATE states (asks questions
and waits for answers); in VIEW state it renders the current settings and
prompts the user to select a key to update or exit.

**Workspace structure after INIT:**
```
{ProjectFolder}/
  AGENTS.md
  .aid/
    settings.yml              ← the source of truth, managed by /aid-config
    knowledge/
      STATE.md
      (...16 KB docs, INDEX.md, README.md)
```

---

## ⚠️ Pre-flight Checks

### Check 0: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed
- ❌ `Plan mode` → STOP. Tell user to switch. `/aid-config` writes files — Plan mode will block all writes.

### Check 1: --reset Confirmation (if flag passed)

If `--reset` was passed and `.aid/settings.yml` exists, confirm:

```
⚠️ --reset will rewrite .aid/settings.yml from defaults.
Your current settings will be LOST. The .aid/ directory structure
(knowledge/, work-*/) is NOT touched. Continue? [y/N]
```

If confirmed, delete `.aid/settings.yml` so PRE-FLIGHT detection routes to INIT-SETTINGS.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH** — determine state from disk, not from memory.

Inspect after pre-flight:

| Filesystem | Argument | State |
|---|---|---|
| `.aid/` does NOT exist | (any) | **INIT** (first-time scaffold) |
| `.aid/` exists AND `.aid/settings.yml` does NOT exist | (any) | **INIT-SETTINGS** (write defaults; existing project gaining settings.yml) |
| `.aid/settings.yml` exists | `KEY=VALUE` | **UPDATE** (quick-set form — skip VIEW; set the single key, then PERSIST) |
| `.aid/settings.yml` exists | `--show` | **VIEW** (read-only) |
| `.aid/settings.yml` exists | (bare) | **VIEW** (interactive; user can choose to update or exit) |

**Quick-set form:** if the positional arg matches `<dotted.key>=<value>` (e.g.,
`review.minimum_grade=A-`), the dispatcher skips VIEW and routes straight to
UPDATE with the parsed key/value, then PERSIST. Validates the same as
interactive UPDATE. Returns to DONE without re-rendering VIEW.

Print the state-entry line + "you are here" map (see each state-detail file).

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| INIT          | `references/state-init.md`          | inline | → VIEW |
| INIT-SETTINGS | `references/state-init-settings.md` | inline | → VIEW |
| VIEW          | `references/state-view.md`          | inline | → UPDATE (user selects a key) / → DONE (user exits) |
| UPDATE        | `references/state-update.md`        | inline | → PERSIST |
| PERSIST       | `references/state-persist.md`       | inline | → VIEW |
| DONE          | `references/state-done.md`          | inline | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from the matching state-detail file.
When a state completes (other than DONE), print `Next: [State: {NEXT}] — run /aid-config again` and exit.
For DONE, print summary and halt — no next-state line.

---

## Settings schema reference

Canonical schema: `.agents/templates/settings.yml`. Top-level sections:

| Section | Keys | Purpose |
|---|---|---|
| `project` | `name`, `description`, `type` | Project identity (description is the sole source of truth — not duplicated in CLAUDE.md/AGENTS.md) |
| `tools` | `installed` | Which AI host tools have AID installed (claude-code / codex / cursor) |
| `review` | `minimum_grade` | Global default grade bar for every skill's REVIEW state |
| `execution` | `max_parallel_tasks` | /aid-execute + /aid-deploy parallelism (work-001 feature-009 pool capacity) |
| `traceability` | `heartbeat_interval` | Long-running sub-agent heartbeat cadence in minutes (work-003) |

**Per-skill overrides:** any top-level key whose name matches a skill
(`discover`, `summary`, `interview`, `specify`, `plan`, `detail`, `execute`,
`deploy`, `monitor`) can carry `minimum_grade:` to override
`review.minimum_grade` for that skill only. Default to absent
(use the global value).

---

## How other skills read settings

Consumer skills (`/aid-discover`, `/aid-execute`, etc.) resolve their settings
using this order:

1. **Per-skill override key** (e.g., `discover.minimum_grade`) — use if present
2. **Global category default** (e.g., `review.minimum_grade`) — use otherwise
3. **Hardcoded skill default** — use only if `.aid/settings.yml` is missing entirely

A helper script `.agents/scripts/config/read-setting.sh` (authored alongside
this skill) provides the canonical resolution logic. Consumer skills invoke:

```bash
bash .agents/scripts/config/read-setting.sh --skill discover --key minimum_grade
# → prints A (or A+, A-, etc.) depending on settings.yml + overrides
```

---

## Quality Checklist

- [ ] `.aid/settings.yml` exists and parses as valid YAML
- [ ] All required top-level sections present (project, tools, review, execution, traceability)
- [ ] `project.name` not equal to `<project-name>` placeholder
- [ ] `tools.installed` non-empty
- [ ] `review.minimum_grade` is a valid grade (`[A-F][+-]?`)
- [ ] CLAUDE.md or AGENTS.md created (per `tools.installed` selection)
- [ ] CLAUDE.md / AGENTS.md project-context section does NOT include a description field
  (per single-source-of-truth — description lives only in settings.yml)
- [ ] `.aid/knowledge/` scaffolded with 16 KB templates + STATE.md + README.md
  (only on first INIT; not on subsequent VIEW/UPDATE runs). INDEX.md is
  *generated* by `build-index.sh` in Step 4 — not hand-authored.
- [ ] `.gitignore` updated per Q8 choice (`.aid/.heartbeat/` MUST be ignored
  per the heartbeat protocol; aid-config offers to append on confirmation)
