# Requirements

- **Name:** Connectors — lifecycle + consumption
- **Description:** Make catalogued connectors first-class: add on-demand skills to manage a single connector (`aid-set-connector` / `aid-unset-connector`) **and** wire the pipeline skills/agents to actually *consume* catalogued connectors during a run.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-11 | Initial interview started | /aid-describe |
| 2026-07-11 | Requirements drafted from design session; scope unified (lifecycle + consumption) | /aid-describe |

## 1. Objective

Turn the connector catalog from a discovery-only, `aid-discover`-authored registry into a
first-class capability with two halves:
- **Lifecycle:** manage a single connector on demand — without re-running `aid-discover`.
- **Consumption:** let AID skills/agents actually leverage a catalogued connector mid-pipeline.

## 2. Problem Statement

- **Lifecycle gap:** connector authoring lives *only* in `aid-discover`'s ELICIT step, which
  runs once per discovery cycle. Adding/updating/removing one connector today requires either a
  heavyweight `aid-discover --reset` (a whole discovery cycle) or hand-running the connector
  scripts. There is no single-purpose entry point.
- **Consumption gap:** nothing consumes connectors. The `## Connectors` protocol is *documented*
  ("catalog, not connection manager") but no skill/agent reads the catalog, resolves a secret,
  or calls the tool. There isn't even a `secret_reference`→value resolver.
- **Pointer bug:** the `## Connectors` context-file section exists only in the dogfood root
  `CLAUDE.md`; it is **missing from all 5 shipped profile context files**, though the installer
  already allowlists the region.

## 3. Users & Stakeholders

- AID adopters/maintainers managing a project's external tools (owner: Andre Vianna).
- Pipeline agents that will consume connectors — primarily `aid-researcher`, `aid-developer`.

## 4. Scope

### In Scope

**A. Lifecycle skills** (authored in `canonical/`, rendered to 5 profiles + dogfood via `/generate-profile`):
- **`aid-set-connector <tool> <type>`** — **upsert** a connector, keyed by `<tool>`.
  - `<tool>` = name / preset-id (e.g. `Jira`) — the connector identity; **exactly one type per tool**.
  - `<type>` = `connection_type` ∈ `mcp|api|ssh|url|cli` — the connector's single, **mutable** type,
    which also **selects the configuration question-set** (each type asks only for the fields it needs).
  - Absent tool ⇒ create; existing tool ⇒ update. **Changing the type updates the same connector**
    (re-runs that type's config questions and reconciles its secret — see FR2).
  - Example: **`aid-set-connector Jira mcp`** (mcp ⇒ descriptor only, no secret).
- **`aid-unset-connector <tool>`** — remove a connector (purge secret, rebuild `INDEX.md`); idempotent.
- Factor the **R0–R5 reconcile** out of `state-elicit.md` into a **shared reference** used by
  `aid-discover` ELICIT (bulk) and both new skills (single); ELICIT behavior unchanged.

**B. Consumption wiring** *(MCP-first — see Resolved Decisions)*:
- Fix the `## Connectors` profile context-pointer bug (all 5 profile context files).
- Add a shared **consumption-protocol** reference the skills point to.
- Wire the lifecycle seams: `aid-describe`/`aid-specify` (read source tickets), `aid-plan`/`aid-fix`
  (create tickets), `aid-execute` (mirror `STATE.md` transitions → ticket), `aid-query-kb` (enrich),
  and `aid-researcher`/`aid-developer` (connector-awareness).

### Out of Scope

- Opening/wiring live connections — AID stays a **catalog, not a connection manager**.
- Moving the connector catalog into `settings.yml` (decided: keep `.aid/connectors/`).
- A standalone `list` skill — read is covered by `INDEX.md` + dashboard + `connector-registry list`.
- **aid-managed *consumption*** (`api`/`ssh`/`url`/`cli`) and the `connector-secret resolve` primitive —
  deferred to a follow-up (MCP-first only here). *Lifecycle* (set/unset) still supports **all** types;
  only *consumption* is MCP-first.

## 5. Functional Requirements

- **FR1** — `aid-set-connector <tool> <type>` upserts a descriptor **keyed by `<tool>`** (one
  descriptor, one `connection_type` per tool). `<type>` sets the connector's type **and drives the
  config question-set**: `mcp` ⇒ name + optional informational endpoint, `auth_method: none`, no
  secret; `api`/`url` ⇒ endpoint + `auth_method` (+ secret unless `none`); `ssh` ⇒ host + ssh-key;
  `cli` ⇒ command. Presets prefill defaults; the user confirms/edits.
- **FR2** — Type/secret reconcile on `set`: changing `<type>` updates the connector **in place**.
  Transition **into** an aid-managed type (or an `auth_method` needing a credential) ⇒ capture the
  secret; transition **to** `mcp`/`none` ⇒ **purge** the now-orphaned secret. Field-only updates
  within the same type do **not** re-prompt; rotation is opt-in (**OD-2**: `--rotate-secret` and/or
  auto-prompt on `auth_method` change).
- **FR3** — `aid-unset-connector <tool>` removes the descriptor, purges its secret, rebuilds `INDEX.md`; idempotent.
- **FR4** — Both skills run the shared reconcile (ADD/UPDATE/NO-OP/REMOVE) + deterministic `INDEX.md`
  rebuild; `aid-discover` ELICIT is refactored to reuse it with **no behavior change**.
- **FR5** — Both skills are on-demand / off-pipeline; they never require or trigger a discovery cycle,
  and respect the P7 write-zone (`.aid/connectors/` only) + secret fail-closed posture
  (gitignore check, `umask 077`, path confinement).
- **FR6** *(consumption)* — Add the `## Connectors` section to all 5 profile context files; add the
  shared consumption-protocol reference.
- **FR7** *(consumption)* — Wire the named seams to leverage connectors via the **host tool's MCP**
  (`connection_type: mcp`). aid-managed consumption is out of scope (see Resolved Decisions).

## 6. Non-Functional Requirements

- Any new script logic ships as **bash + PowerShell twins** (parity-tested); Windows PS 5.1 compatible.
- `INDEX.md` regeneration stays **deterministic** (no timestamps) so reconcile doesn't churn.
- **No secret leakage** into logs, STATE, or the descriptor (only the `secret_reference` pointer is stored).
- `/generate-profile` renders clean; dogfood byte-identity + twin-parity + PS5.1 CI lanes stay green.

## 7. Constraints

- Source of truth is `canonical/`; changes render to 5 profiles + dogfood `.claude/` via `/generate-profile`.
- Profile context files (`CLAUDE.md`/`AGENTS.md`) are hand-maintained + installer-propagated (not canonical-rendered).
- The connector subsystem (work-002) is **currently UNRELEASED** — it ships in **v2.1**. This is a hard
  dependency: nothing here has field value until v2.1 ships and adopters `aid update`.

## 8. Assumptions & Dependencies

- Depends on the connectors subsystem (work-002 / PR #133) shipping in v2.1.
- Reuses the existing scripts: `connector-registry`, `connector-secret`, `build-connectors-index`.
- Consumption has field value only where the host tool has the relevant MCP connected (e.g. a Jira MCP).

## 9. Acceptance Criteria

- `aid-set-connector Jira mcp` creates `.aid/connectors/jira.md` (type `mcp`, no secret) + an `INDEX.md`
  row, **without running `aid-discover`**.
- Re-running `aid-set-connector Jira api` **upserts** — updates the type and captures the secret.
- `aid-unset-connector Jira` removes the descriptor, purges the secret, drops the `INDEX.md` row; a second
  run is a clean no-op.
- `aid-discover` ELICIT still authors/reconciles connectors unchanged (regression).
- *(consumption)* a wired skill leverages a catalogued **MCP** connector end-to-end — e.g. `aid-execute`
  updates the linked Jira ticket via the host Jira MCP.
- `/generate-profile` renders clean; twin-parity + PS5.1 lanes green.

## 10. Priority

Sequence with the **v2.1** connectors release (Half-1 must ship first). Lifecycle skills are the
near-term, independently-shippable piece; consumption wiring follows.

---

## Resolved Decisions

- **OD-Q1 → MCP-first.** Consumption wires **host-provided MCP** connectors only. aid-managed
  (`api`/`ssh`/`url`/`cli`) *consumption* + a `connector-secret resolve` primitive + a security pass
  are **out of scope** (clean follow-up work).
- **OD-1 → no `list` skill** — read is `INDEX.md` + dashboard + `connector-registry list`.
- **OD-2 → secret rotation on `set` is opt-in:** `--rotate-secret` and/or auto-prompt when
  `auth_method` changes; field-only updates never re-prompt.
- **Path → Lite**; catalog stays in `.aid/connectors/`; one type per tool.
