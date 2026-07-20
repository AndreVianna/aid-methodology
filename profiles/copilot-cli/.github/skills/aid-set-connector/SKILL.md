---
name: aid-set-connector
description: >
  On-demand, off-pipeline upsert into the connector catalog. `aid-set-connector <tool> <type>`
  creates `.aid/connectors/<stem>.md` when the stem is absent, or updates that SAME descriptor in
  place when present (including an in-place connection_type transition) -- never invokes
  /aid-discover. Branches on <type> (mcp|api|ssh|cli) to ask the matching config
  question-set, prefilled from .github/aid/templates/connectors/preset-catalog.md when <tool>
  matches a preset; the user confirms or edits. Reconciles the secret (connector-secret
  write/purge) per set-skill logic and runs reconcile.md's single-stem mode, so every OTHER
  catalogued connector is left byte-for-byte untouched.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, AskUserQuestion
argument-hint: "<tool> <type> [--rotate-secret]  -- e.g. aid-set-connector Jira mcp   (type: mcp|api|ssh|cli)"
---

# Set Connector

`aid-set-connector <tool> <type>` upserts **one** connector into `.aid/connectors/` without
touching any other catalogued connector and without requiring — or triggering — an
`/aid-discover` cycle. It is the incremental, single-tool counterpart to `aid-discover`'s ELICIT
step (`.github/skills/aid-discover/references/state-elicit.md` Step E2): use it to add a
connector between discovery cycles, or to change an existing one's type or fields.

**Absent from the mandatory pipeline flow.** Like `/aid-config` and `/aid-housekeep`, this is an
optional, on-demand skill — no phase gate references it, and it never invokes `/aid-discover`.

**Keyed by `<tool>` → one descriptor, one mutable `connection_type` per stem.** Re-running this
skill against a stem that already exists **updates that same descriptor in place** — including
when `<type>` differs from what's on disk (a type transition). That is still a single UPDATE,
never a remove-then-add pair.

---

## Pre-flight

- `Default` or `Auto-accept edits` → proceed.
- `Plan mode` → STOP. This skill writes files under `.aid/connectors/`.
- Requires exactly two positional arguments: `<tool>` `<type>`. One optional trailing flag:
  `--rotate-secret` (forces a fresh secret capture on an otherwise field-only, same-type,
  same-`auth_method` update — Step 5).

### Step 0: Validate arguments

1. Fewer than 2 positional arguments → print and exit non-zero:
   ```
   Usage: aid-set-connector <tool> <type>   (type: mcp | api | ssh | cli)
   Example: aid-set-connector Jira mcp
   ```
2. `<type>` MUST be one of the closed enum `mcp | api | ssh | cli` (feature-001 Data Model,
   `.aid/work-002-external_sources/features/feature-001-integration-store-placement/SPEC.md`
   "Data Model"). An unrecognized value is **refused, not coerced** — e.g. `db` is not a value:
   ```
   Unknown type: <type>   (expected one of: mcp, api, ssh, cli)
   ```
   exit non-zero.
3. Any flag other than `--rotate-secret` is unknown:
   ```
   Unknown argument: <flag>
   Usage: aid-set-connector <tool> <type> [--rotate-secret]
   ```
   exit non-zero.

From here on, `$TOOL` names the resolved `<tool>` argument and `$TYPE` the resolved `<type>`
argument (already validated above) — used as shell variables in the bash snippets below, never as
literal angle-bracket text.

---

## Step 1: Resolve `<tool>` → descriptor stem; read the preset catalog

Derive the stem exactly as ELICIT does (feature-002's slug rule) — lowercase, non-alphanumeric
runs collapsed to `-`, no leading/trailing `-`:

```bash
STEM=$(echo "$TOOL" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
```

Read `.github/aid/templates/connectors/preset-catalog.md` (LLM-read from disk, same as ELICIT's
"Preset vs. custom declaration") and look for the row whose `preset-id` equals `$STEM`:

- **Match found → preset declaration.** Prefill `name` from the row's `name` column, `tags` from
  its `tags` column (if present), and set `preset: <preset-id>`. Whether the row's *other* columns
  (`endpoint-template`, `auth_method`, `secret_reference-form`) are usable depends on whether the
  row's own `connection_type` matches the `<type>` argument — see "Preset vs. custom, and the
  type-mismatch case" in [`references/question-sets.md`](references/question-sets.md). **`<type>`
  (the CLI argument) is always the descriptor's `connection_type` — the preset row never overrides
  it**, even when the two disagree (e.g. `aid-set-connector Jira mcp` against Jira's `api`-typed
  preset row — AC1).
- **No match → custom declaration.** `name` defaults to `<tool>` as given; `preset: custom`; no
  field is prefilled beyond the per-type defaults in Step 2.

---

## Step 2: Branch on `<type>` — ask the config question-set

Per [`references/question-sets.md`](references/question-sets.md), present the question-set for the
resolved `<type>`, prefilled per Step 1 (ADD) or from the on-disk descriptor when the type is
unchanged from what's on disk (UPDATE, same type). Ask via `AskUserQuestion` — **do not use the
`preview` field** (it switches the UI to a layout that suppresses the auto-injected `Other`
free-text option); use `description` only, so a suggestion plus free-form `Other` are both always
available. Resolve: `name`, `endpoint` (required for `api`/`ssh`/`cli`; optional and
informational-only for `mcp`), `auth_method` (forced `none` for `mcp`/`ssh`/`cli` — `api` is the
only type that is ever asked and may resolve to `token`/`pat`/`oauth`), and — only for `api` with a
non-`none` result — the `secret_reference` FORM (default `file:.aid/connectors/.secrets/$STEM`).

`tags` / `audience` are **never prompted** — auto-derived exactly as ELICIT does: the preset row's
`tags` column when present, else `[connector, <type>]`; `audience` always `[developer, architect]`.

Hold the resolved `auth_method` in `$NEW_AUTH` (forced `none` for `mcp`/`ssh`/`cli`, chosen for
`api` only) — Step 5b's decision procedure compares `$TYPE`/`$NEW_AUTH` (this run's result) against
`$OLD_TYPE`/`$OLD_AUTH` (Step 3, on-disk).

---

## Step 3: Classify — ADD vs UPDATE (single stem only)

```bash
if [ -f ".aid/connectors/${STEM}.md" ]; then
  CLASS=UPDATE
  OLD_TYPE=$(bash .github/aid/scripts/connectors/connector-registry.sh read "$STEM" connection_type --root .aid/connectors)
  OLD_AUTH=$(bash .github/aid/scripts/connectors/connector-registry.sh read "$STEM" auth_method --root .aid/connectors)
else
  CLASS=ADD
  OLD_TYPE=""
  OLD_AUTH=""
fi
```

Per [`.github/aid/templates/connectors/reconcile.md`](../../aid/templates/connectors/reconcile.md)
§ "Single-stem mode" Step S1: **UPDATE includes a type change** — `$STEM` already existing with a
*different* on-disk `connection_type` than this run's `<type>` is still one UPDATE, never a
REMOVE-then-ADD pair. No stem other than `$STEM` is enumerated, read, or touched anywhere in this
skill — **no whole-registry diff, ever** (AC6).

---

## Step 4: Ensure the `.secrets/` gitignore precondition — BEFORE any write under `.aid/connectors/`

Run this unconditionally, on both ADD and UPDATE, regardless of whether `$STEM` ends up needing a
secret — before the descriptor is written (Step 5) and before `connector-secret.sh` is ever
invoked:

```bash
mkdir -p .aid/connectors
if [ ! -f .aid/connectors/.gitignore ]; then
  printf '%s\n' '.secrets/' > .aid/connectors/.gitignore
fi
```

This is the same precondition write `reconcile.md`'s bulk mode performs before its first
ADD/UPDATE (§ "Bulk mode" Step R3) — reused here so a fresh, off-pipeline repo (no prior
`/aid-discover` cycle, no `.aid/connectors/` directory yet) does not fail-closed on its very first
`connector-secret write` (`connector-secret.sh` exit code 4 — "fail-closed ignore-precondition
failure"). This ordering is load-bearing for AC2/AC10: never call `connector-secret write`/`purge`
before this step has run.

---

## Step 5: Author the descriptor + reconcile the secret (set-skill logic)

### 5a. Write the descriptor

Author (ADD) or overwrite in place (UPDATE) `.aid/connectors/${STEM}.md` via `reconcile.md`'s
["Write one descriptor"](../../aid/templates/connectors/reconcile.md) step — same frontmatter
fields (`name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference` when applicable,
`preset`, `objective`, `summary`, `tags`, `audience`), same body shape (a `# <Name>` heading, a
`> Connection: ... · Mode: ... · Auth: ...` summary line, 1–2 lines of human guidance), same
management-mode branch — here driven by the `<type>` CLI argument rather than ELICIT's
preset/custom branch. `objective`/`summary` are composed from the preset row's `notes` column when
Step 1 matched one (adapted to whichever management mode `<type>` resolves to), or freshly composed
for a custom declaration — mirroring the worked `github.md` (tool-managed) / `m365.md`
(aid-managed) examples in feature-001's SPEC.

**Unlike bulk mode, single-stem UPDATE has no separate NO-OP class** (`reconcile.md`'s Step S1
table only has ADD/UPDATE/REMOVE): the descriptor is (over)written on every UPDATE, even a
field-identical re-run. What Step 5b below gates is the **secret** call, not the descriptor write.

### 5b. Reconcile the secret — set-skill logic

This is **set-skill logic**, distinct from `reconcile.md`'s own bulk-mode UPDATE (which never
purges a secret on a field edit — only REMOVE purges in bulk mode) and distinct from
`aid-unset-connector`'s REMOVE-only purge. Full decision procedure + rationale:
[`references/secret-reconcile.md`](references/secret-reconcile.md). Summary:

| Situation | Secret action |
|---|---|
| ADD, aid-managed result with `auth_method != none` | `connector-secret write $STEM` |
| ADD, `mcp` or `auth_method: none` | none — no secret question, no script call |
| UPDATE, new result is `mcp` or `auth_method: none`, **and** `$OLD_AUTH != none` (orphaned secret) | `connector-secret purge $STEM` |
| UPDATE, new result is `mcp` or `auth_method: none`, and `$OLD_AUTH` was already `none` | none |
| UPDATE, new result is credentialed aid-managed, type changed (`$OLD_TYPE != $TYPE`) | `connector-secret write $STEM` |
| UPDATE, same type, `auth_method` changed | `connector-secret write $STEM` |
| UPDATE, same type, same `auth_method`, `--rotate-secret` given | `connector-secret write $STEM` |
| UPDATE, same type, same `auth_method`, no `--rotate-secret` | none — leave the stored secret untouched |

`connector-secret write`/`purge` apply only when `secret_reference` uses the `file:` form (the
default). For `env:`/`keychain:` forms, never invoke the script — no local value is stored by AID
for those forms (resolved externally at use-time); only the reference literal is written into the
descriptor.

---

## Step 6: Single-stem reconcile → rebuild `INDEX.md`

Run [`reconcile.md`](../../aid/templates/connectors/reconcile.md) § "Single-stem mode (set/unset)"
Step S3 — the same deterministic builder invocation as bulk mode, over whatever is currently on
disk:

```bash
bash .github/aid/scripts/connectors/build-connectors-index.sh \
  --root .aid/connectors --output .aid/connectors/INDEX.md
```

No `list`/diff against the rest of the registry ever runs (AC6) — the builder reads every
descriptor currently on disk, so every untouched connector's row regenerates unchanged and only
`$STEM`'s row is added or updated.

Print a one-line trace (mirrors `reconcile.md`'s Step R5 shape, singular — never print, log, or
write a secret value):
```
[aid-set-connector] <STEM>: <ADD|UPDATE> (<type>); secret <written|purged|unchanged>; INDEX regenerated.
```

Exit 0.

---

## Write-zone

This skill writes **only** within `.aid/connectors/` — the same P7 exemption ELICIT uses
(`.github/aid/templates/kb-authoring/principles.md` P7 "Exception (connector sub-phase)"):
`.aid/connectors/.gitignore`, `.aid/connectors/<stem>.md`, and, via `connector-secret.sh`,
`.aid/connectors/.secrets/<stem>`. It never touches `.aid/knowledge/`, never invokes
`/aid-discover`, and never writes any host tool's MCP configuration (STATE.md Q10 — AID is a
catalog, not a connection manager).

---

## Reused scripts (no new scripts)

| Script | Op used here | Purpose |
|---|---|---|
| `connector-registry.sh` | `read <stem> <field>` | Read the on-disk `connection_type`/`auth_method` on UPDATE (Step 3) |
| `connector-secret.sh` | `write <stem>` / `purge <stem>` | Capture/rotate or purge the one secret `$STEM`'s reconcile calls for (Step 5b) |
| `build-connectors-index.sh` | default | Rebuild `INDEX.md` from every descriptor on disk (Step 6) |

(PowerShell twins: `connector-registry.ps1`, `connector-secret.ps1`, `build-connectors-index.ps1`.)
No new script is introduced by this skill.

---

## Worked examples

- **`aid-set-connector Jira mcp`** on a stem-absent repo → Step 3 classifies ADD → Step 4
  establishes the gitignore precondition → Step 5a writes `.aid/connectors/jira.md`
  (`connection_type: mcp`, `auth_method: none`, no `secret_reference`) → Step 5b: `mcp` result, no
  secret call → Step 6 rebuilds `INDEX.md`. No `/aid-discover` invocation anywhere (AC1).
- **`aid-set-connector Jira api`** re-run against that same `jira` stem → Step 3 classifies UPDATE
  with `$OLD_TYPE=mcp` → Step 4 runs again (idempotent — the `.gitignore` already exists from the
  first run, so this is a no-op) → Step 5a overwrites `jira.md` in place (`connection_type: api`,
  `auth_method` per the api question-set, e.g. `token`) → Step 5b: type changed into a credentialed
  aid-managed type → `connector-secret write jira` → Step 6 rewrites `jira`'s `INDEX.md` row. Works
  on a fresh repo because Step 4 runs before Step 5b's secret write (AC2, AC10).
- **`aid-set-connector Jira mcp`** run a third time against the now-`api` `jira` stem → Step 3
  UPDATE with `$OLD_TYPE=api`, `$OLD_AUTH=token` → Step 5a overwrites to `connection_type: mcp`,
  `auth_method: none` → Step 5b: new result is `mcp` and `$OLD_AUTH != none` → `connector-secret
  purge jira` (orphaned secret disposed) (AC3).
- **`aid-set-connector Jira api`** re-run with no field changes at the same type → Step 3 UPDATE,
  `$OLD_TYPE`/`$OLD_AUTH` unchanged from this run's result → Step 5b: same type, same
  `auth_method`, no `--rotate-secret` → no secret call, no re-prompt. Adding `--rotate-secret`, or
  changing `auth_method` (e.g. `token` → `pat`), triggers a fresh `connector-secret write jira`
  instead (AC4).
- With `jira` and `github` both catalogued, any of the above acting on `jira` never enumerates,
  reads, or touches `github.md` or its secret (AC6) — Step 3/Step 6 operate on `$STEM` only.
