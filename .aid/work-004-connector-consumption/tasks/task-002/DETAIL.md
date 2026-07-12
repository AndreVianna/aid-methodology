# task-002: aid-set-connector skill (per-type question-sets, secret reconcile, gitignore precondition, single-stem)

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** task-001

**Scope:**
- Author `canonical/skills/aid-set-connector/SKILL.md` — `aid-set-connector <tool> <type>`: an
  **upsert** keyed by `<tool>` (one descriptor, one **mutable** `connection_type` per stem),
  **single-stem**, on-demand / off-pipeline (never invokes or requires `aid-discover`).
- **Feature flow:** (1) resolve `<tool>` → descriptor stem, reading `preset-catalog.md` for
  defaults or treating as custom; (2) branch on `<type>` to select the per-type config
  question-set, prefilled from the preset; (3) classify the single stem ADD (absent) vs UPDATE
  (present, incl. a type change) with **no whole-registry diff**; (4) ensure the `.secrets/`
  gitignore precondition (`.aid/connectors/.gitignore` ignores `.secrets/`) **before** any secret
  write; (5) author/overwrite the descriptor + run secret reconcile (set-skill logic); (6) run the
  shared `reconcile.md` **single-stem** mode → `build-connectors-index` rebuilds `INDEX.md`.
- **`references/`:**
  - per-type question-sets: `mcp` = name + optional informational endpoint, `auth_method: none`,
    no secret; `api`/`url` = endpoint + `auth_method` (none/token/pat/oauth), capture secret unless
    `none`; `ssh` = host/endpoint + ssh-key; `cli` = command/endpoint (usually none).
  - secret-reconcile rules (set-skill logic, distinct from ELICIT's REMOVE-only purge): into
    aid-managed with a credential ⇒ `connector-secret write`; type changed to `mcp`/`none` ⇒
    `connector-secret purge` the orphaned secret; same-type field-only update ⇒ leave the secret
    unless `--rotate-secret` or `auth_method` changed.
  - the `.secrets/` gitignore precondition (fresh-repo fail-closed avoidance).
  - the single-stem reconcile pointer to `reconcile.md`.
- **Write-zone:** only `.aid/connectors/` (P7 exemption, matching ELICIT). Reuses existing scripts
  only (`connector-registry`, `connector-secret`, `build-connectors-index`); **no new scripts**.

**Acceptance Criteria:**
- [ ] `aid-set-connector Jira mcp` on a stem-absent repo creates `.aid/connectors/jira.md`
  (`connection_type: mcp`, `auth_method: none`, **no** `secret_reference`) + a matching `INDEX.md`
  row, without invoking `aid-discover` (traces to AC1).
- [ ] Re-running `aid-set-connector Jira api` upserts the **same** `jira` descriptor (type → `api`,
  api question-set, secret captured via `connector-secret write`) and rewrites its `INDEX.md` row;
  works on a fresh repo because the `.secrets/` gitignore precondition is established before the
  secret write (traces to AC2, AC10).
- [ ] An in-place type transition reconciles the secret as set-skill logic: `api → mcp`/`none`
  purges the orphaned secret; `→ api`/aid-managed captures one (traces to AC3).
- [ ] A field-only re-`set` at the same type does not re-prompt for the secret; `--rotate-secret`
  or an `auth_method` change does (traces to AC4).
- [ ] With ≥2 connectors catalogued, `aid-set-connector` on one stem leaves every other connector's
  descriptor + secret untouched (single-stem reconcile via `reconcile.md`, never a whole-registry
  diff) (traces to AC6).
- [ ] The skill writes only within `.aid/connectors/`, and `connector-secret write` is never
  invoked before the `.secrets/` gitignore precondition holds (traces to AC10).
- [ ] All section-6 quality gates pass.
