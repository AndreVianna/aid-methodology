# Connectors — Lifecycle + MCP-First Consumption

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-11 | SPEC authored from REQUIREMENTS.md (lite path) | /aid-describe → hand-driven lite |
| 2026-07-11 | GATE cycle-1 fixes (single-stem reconcile, secret/gitignore ordering, multi-level ticket linkage, byte-identity test, write-zone, term binding) | GATE fix (ledger work-004-spec.md) |
| 2026-07-11 | GATE fix — `ticket_ref` resolution order corrected to `task → feature → delivery → work` (KB-consistent) | GATE fix (ledger work-004-spec.md) |
| 2026-07-11 | GATE fix — field name `source_ref` → `ticket_ref`; feature carrier is SPEC only (no feature STATE) | GATE fix (ledger work-004-spec.md) |

## Source

- `REQUIREMENTS.md` §1 Objective, §4 Scope, §5 Functional Requirements (FR1–FR7), §9 Acceptance Criteria, §Resolved Decisions.

## Description

Add two on-demand skills to manage the connector catalog incrementally — **`aid-set-connector`**
(upsert) and **`aid-unset-connector`** (remove) — so a connector can be added/updated/removed
**without re-running `aid-discover`**; and wire the pipeline to **consume host-provided MCP
connectors** at defined lifecycle seams. Orchestration over the existing connector plumbing —
**no new scripts** (the only net-new logic is markdown: a single-stem reconcile mode + the
consumption protocol).

## User Stories

- As a maintainer, I run `aid-set-connector Jira mcp` and get a `jira` connector catalogued without touching discovery.
- As a maintainer, I re-run `aid-set-connector Jira api` and the same connector is updated (type changed, secret captured) — and my other connectors are untouched.
- As a maintainer, I run `aid-unset-connector Jira` and that connector + its secret are gone; nothing else changes.
- As a developer, when a Jira MCP is connected and the work is linked to a ticket, `aid-execute` reflects task-state changes onto **that** ticket.

## Priority

Must. Hard dependency on the **v2.1 connectors subsystem (work-002)** shipping first — until it does,
there is no connector catalog in the field for these skills to manage or consume.

## Acceptance Criteria

- **AC1** — `aid-set-connector Jira mcp` creates `.aid/connectors/jira.md` (`connection_type: mcp`,
  `auth_method: none`, **no** `secret_reference`) and a matching `INDEX.md` row, **without invoking `aid-discover`**.
- **AC2** — Re-running `aid-set-connector Jira api` **upserts the same `jira` descriptor** (type → `api`,
  api question-set, secret captured via `connector-secret write`); `INDEX.md` reflects the new row. Works on
  a **fresh repo** — the `.secrets/` gitignore precondition is established *before* the secret write (AC10).
- **AC3** — In-place type transition reconciles the secret **as set-skill logic** (not the reused ELICIT
  reconcile, which purges only on REMOVE): `api → mcp`/`none` **purges** the orphaned secret
  (`connector-secret purge`); `→ api`/aid-managed captures one.
- **AC4** — Field-only re-`set` (same type) does **not** re-prompt for the secret; `--rotate-secret` or an
  `auth_method` change does.
- **AC5** — `aid-unset-connector Jira` removes the descriptor, purges its secret, drops the `INDEX.md` row;
  a second run is a clean no-op (idempotent).
- **AC6 (no collateral)** — With ≥2 connectors catalogued, `aid-set-connector` / `aid-unset-connector` on
  **one** stem leave **every other** connector's descriptor + secret untouched (single-stem reconcile —
  never a whole-registry diff). *This is the guard against the R0–R5 `persisted ∖ declared` REMOVE trap.*
- **AC7** — `aid-discover` ELICIT still authors/reconciles connectors with **no behavior change**
  (regression), now via the shared reconcile reference in **bulk mode**.
- **AC8** — The `## Connectors` section is present in **all 5 profile context files**, and the four
  `AGENTS.md` remain **byte-identical** to each other afterward (`test-agents-md-invariant.sh`).
- **AC9 (linkage)** — A ticket can be linked at **any lifecycle level** — work, feature, delivery, and/or
  task — via a `ticket_ref` scalar (`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`) in that unit's
  STATE/SPEC. A seam resolves the **nearest** ref by AID containment (`work ⊃ delivery ⊃ task`, `work ⊃
  feature`; a delivery groups ≥1 feature): `delivery → work`; `feature → work`; and for a **task**,
  `task → its owning (SPEC-traced) feature → its delivery → work` — the feature (the task's specific
  subject) outranks the delivery, which bundles several features; a task tracing to no single feature skips
  the feature level (`task → delivery → work`). Then it acts via the linked connector's host MCP. Testable:
  a task with `ticket_ref: jira:PROJ-45` (or inheriting from feature, else delivery, else work) + a `jira`
  MCP connector → an `In Progress` transition posts to `PROJ-45`.
- **AC10** — The new skills write **only** within `.aid/connectors/` (write-zone confinement, matching
  ELICIT's P7 exemption), and `connector-secret write` is never invoked before the `.secrets/` gitignore
  precondition holds.
- **AC11** — `/generate-profile` renders clean; dogfood byte-identity + connector-twin PS-parity + PS 5.1 lanes stay green.

## Technical Specification

### Data Model

- **Descriptor** (`.aid/connectors/<stem>.md`) + frozen schema (`connection_type ∈ mcp|api|ssh|url|cli`,
  `auth_method`, `secret_reference`, `preset`, KB-style routing fields): **unchanged** (feature-001
  contract). Identity = the tool stem; **exactly one `connection_type` per stem**. `INDEX.md` and
  `.secrets/` unchanged.
- **Reconcile — two modes** (documented in the extracted `reconcile.md`):
  - **bulk** (ELICIT): reconciles the whole *declared* set against the *persisted* registry —
    REMOVE = stems in `persisted ∖ declared`. This is ELICIT's existing R0–R5 logic, relocated verbatim.
  - **single-stem** (set/unset): operates on **exactly the one target stem** — ADD/UPDATE for `set`,
    REMOVE for `unset`. It **never** diffs against the rest of the registry, so other connectors are
    never classified REMOVE and never touched. `build-connectors-index` then rebuilds `INDEX.md` from
    whatever descriptors remain on disk (inherently correct after a targeted op). Single-stem is the
    only net-new reconcile behavior.
- **Ticket linkage (net-new, multi-level).** A `ticket_ref` scalar links a lifecycle unit to an external
  tracker item — form `<connector-stem>:<external-id>` (e.g. `jira:PROJ-123`), tying the link to a
  catalogued connector. It may be set at **any** level as the work needs: **work** (STATE frontmatter),
  **feature** (feature SPEC), **delivery** (delivery STATE frontmatter), and/or **task** (task STATE /
  flattened `### Tasks lifecycle`). **Resolution — nearest by AID containment** (`work ⊃ delivery ⊃ task`
  and `work ⊃ feature`; a delivery groups ≥1 feature): a unit uses its own `ticket_ref` if present, else
  inherits — `delivery → work`; `feature → work`; and for a **task** `task → its owning (SPEC-traced)
  feature → its delivery → work` (feature outranks delivery, since a delivery bundles multiple features
  while the feature is the task's specific subject; a task tracing to no single feature skips the feature
  level). The **descriptor** schema is unchanged — `ticket_ref` is a *lifecycle-unit* field, never a
  connector field.

### Feature Flow

**`aid-set-connector <tool> <type>` (upsert, single-stem):**
1. Resolve `<tool>` → descriptor stem; read `preset-catalog.md` for defaults, or treat as custom.
2. Branch on `<type>` to select the **config question-set** (table below), prefilled from the preset.
3. Classify the single stem: ADD (absent) vs UPDATE (present, incl. a type change). **No whole-registry diff.**
4. **Ensure the `.secrets/` gitignore precondition** (`.aid/connectors/.gitignore` ignores `.secrets/`)
   *before* any secret write — so a fresh, off-pipeline repo does not fail-closed (`connector-secret` exit 4).
5. Author/overwrite the descriptor for that stem. **Secret reconcile (set-skill logic):** into aid-managed
   with a credential ⇒ `connector-secret write`; type changed to `mcp`/`none` ⇒ `connector-secret purge`
   the orphaned secret; same-type field-only update ⇒ leave the secret unless `--rotate-secret` or
   `auth_method` changed.
6. Run the shared reconcile in **single-stem mode** for this stem → `build-connectors-index` rebuilds `INDEX.md`.

| `<type>` | Config questions | Secret |
|---|---|---|
| `mcp` | name (+ optional informational endpoint); `auth_method: none` | none (host owns auth) |
| `api` / `url` | endpoint + `auth_method` (none/token/pat/oauth) | capture unless `none` |
| `ssh` | host/endpoint + `ssh-key` | key |
| `cli` | command/endpoint | usually none |

**`aid-unset-connector <tool>` (remove, single-stem):** resolve stem → shared reconcile **single-stem
REMOVE** (`connector-secret purge` → delete the one descriptor) → `build-connectors-index`. Never diffs
the registry; an absent stem is a clean no-op (idempotent).

**Consumption seam (MCP-first), generic shape:** at a wired seam the agent scans `INDEX.md`; for a
relevant `connection_type: mcp` connector it uses the **host tool's MCP** (AID resolves nothing, stores
no credential). Ingest seams (`aid-describe`/`aid-specify`/`aid-plan`/`aid-fix`) record a `ticket_ref` at
the level they create (work / feature / delivery / task); target seams (`aid-execute`) resolve the
**nearest** `ticket_ref` for the unit they act on and post to that ticket. aid-managed connectors are out
of scope for consumption here.

### Layers & Components

**New (authored in `canonical/`, rendered by `/generate-profile`):**
- `canonical/skills/aid-set-connector/SKILL.md` (+ `references/` for the per-type question-sets and the secret-reconcile rules).
- `canonical/skills/aid-unset-connector/SKILL.md`.
- `canonical/aid/templates/connectors/reconcile.md` — the reconcile **extracted** from `state-elicit.md`,
  documenting **both** the existing **bulk** mode (ELICIT) and the net-new **single-stem** mode (set/unset).
- `canonical/aid/templates/connectors/consumption-protocol.md` — the MCP-first "how a seam uses a connector" reference (incl. the multi-level `ticket_ref` linkage + nearest-ancestor resolution contract).

**Modified:**
- `canonical/skills/aid-discover/references/state-elicit.md` — E2 reconcile block replaced by a pointer to
  `reconcile.md` (bulk mode); behavior-preserving.
- **Consumption seams** — add a connector-awareness step referencing `consumption-protocol.md` to:
  `aid-describe`, `aid-specify` (read source ticket → record `ticket_ref` at the right level), `aid-plan`,
  `aid-fix` (create/register a ticket → record its `ticket_ref`), `aid-execute` (resolve the nearest
  `ticket_ref`; mirror `STATE.md` task-state transitions → that ticket), `aid-query-kb` (enrich); and to
  the `aid-researcher` + `aid-developer` agents.
- **STATE/SPEC schema (multi-level)** — add the optional `ticket_ref` scalar at every lifecycle unit that
  carries a STATE/SPEC: work STATE frontmatter, feature SPEC, delivery STATE frontmatter, task STATE
  (and the flattened `### Tasks lifecycle`); readers/dashboard ignore it when absent. Coordinate with the
  in-flight `work-003-state-schema` conventions.
- **Profile context files** — add the `## Connectors` section to all 5 (`profiles/*/CLAUDE.md|AGENTS.md`);
  the four `AGENTS.md` must stay byte-identical (feature-001 FR12). The installer managed-region allowlist
  already covers the `Connectors` stem (`lib/aid-install-core.sh` L567; `lib/AidInstallCore.psm1` L493).
- Skill manifests / profile emission lists — register the two new skills so `/generate-profile` emits them.

**Reused unchanged (no new scripts):** `connector-registry` (list/read), `connector-secret`
(write/purge — rotation = re-`write`), `build-connectors-index`.

### Out of Scope / Deferred

- aid-managed **consumption** (`api/ssh/url/cli`) + a `connector-secret resolve` primitive + a security pass — follow-up.
- A standalone `list` skill; moving the catalog to `settings.yml`; opening/wiring live connections.

### Distribution & Testing

- **Distribution:** edit `canonical/` → `/generate-profile` renders the 5 profile trees + dogfood `.claude/`;
  profile context files are hand-maintained + installer-propagated.
- **Tests (canonical suites):** set/unset behavior (AC1–AC5); **no-collateral single-stem** — with ≥2
  connectors, operating on one leaves the others' descriptor + secret intact (AC6); **fresh-repo gitignore
  precondition** ordering (AC2/AC10) + write-zone confinement (AC10); **ELICIT regression** — shared reconcile
  bulk-mode reuse, no behavior change (AC7); profile `## Connectors` presence **plus the four-`AGENTS.md`
  byte-identity invariant** (`test-agents-md-invariant.sh`, AC8); a linkage/consumption smoke check —
  `ticket_ref` → correct ticket (AC9); and the standing gates — `/generate-profile` deterministic + dogfood
  byte-identity + connector-twin PS-parity + PS 5.1 (AC11).

> **Note (script surface):** rotation is `connector-secret write` re-invoked; single-stem set/unset are
> targeted calls to the existing `write`/`purge` + `build-connectors-index` (no whole-registry diff); and
> consumption is MCP-only. So **no connector script changes** are required — new logic is confined to
> markdown skill/reference files + an optional `ticket_ref` STATE/SPEC scalar (multi-level).
