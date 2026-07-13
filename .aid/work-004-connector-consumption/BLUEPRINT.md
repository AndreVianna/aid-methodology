# Delivery BLUEPRINT -- delivery-001: Connector Lifecycle + MCP-First Consumption

<!-- DELIVERY-LEVEL BLUEPRINT.md — the IMMUTABLE DEFINITION for delivery-001 of this flattened
     single-delivery work. The delivery gate reads its criteria from `## Gate Criteria` below
     (NOT from STATE.md). Task state lives in STATE.md `### Tasks lifecycle`. -->

> **Delivery:** delivery-001
> **Work:** work-004-connector-consumption
> **Created:** 2026-07-11

---

## Objective

The connector catalog is a discovery-only, `aid-discover`-authored registry: authoring lives only
in ELICIT (once per discovery cycle), and nothing in the pipeline consumes a catalogued connector.
This delivery makes catalogued connectors first-class on both halves. **Lifecycle:** two on-demand
skills — `aid-set-connector <tool> <type>` (upsert, single-stem) and `aid-unset-connector <tool>`
(remove, single-stem, idempotent) — manage one connector without re-running `aid-discover`, reusing
a shared reconcile reference factored out of ELICIT (bulk mode unchanged). **Consumption
(MCP-first):** a shared consumption-protocol reference plus wiring at named lifecycle seams so
agents leverage host-provided MCP connectors, with a multi-level `ticket_ref` scalar linking a work
/ feature / delivery / task to an external tracker item and a nearest-ancestor resolution contract.
It is orchestration over existing connector plumbing — no new scripts; the only net-new logic is
markdown (a single-stem reconcile mode + the consumption protocol) plus an optional `ticket_ref`
STATE/SPEC scalar.

## Scope

- **Shared reconcile (REFACTOR).** Extract the R0–R5 registry-reconcile from
  `aid-discover/references/state-elicit.md` into `canonical/aid/templates/connectors/reconcile.md`,
  documenting both the existing **bulk** mode (ELICIT) and the net-new **single-stem** mode
  (set/unset); refactor `state-elicit.md` to point at it with no ELICIT behavior change (task-001).
- **Lifecycle skills.** `canonical/skills/aid-set-connector/` (+ references: per-type
  question-sets, secret reconcile, gitignore precondition, single-stem reconcile) (task-002) and
  `canonical/skills/aid-unset-connector/` (task-003) — authored in `canonical/`, rendered via
  `/generate-profile`.
- **Consumption.** `canonical/aid/templates/connectors/consumption-protocol.md` (MCP-first + the
  multi-level `ticket_ref` linkage/resolution contract); the optional `ticket_ref` scalar added to
  the STATE/SPEC schema at every lifecycle unit; seam wiring in `aid-describe`/`aid-specify`/
  `aid-plan`/`aid-fix`/`aid-execute`/`aid-query-kb` + `aid-researcher`/`aid-developer` (task-004).
- **Profile context files.** Add the `## Connectors` section to all 5 profile context files;
  the four `AGENTS.md` stay byte-identical (task-005).
- **Distribution.** Register the two new skills for emission + run `/generate-profile`; standing
  render/parity/PS5.1 gates green (task-006).
- **Tests.** Canonical suites covering AC1–AC11 (task-007).

**Out of scope:** aid-managed **consumption** (`api`/`ssh`/`url`/`cli`), the `connector-secret
resolve` primitive, and a dedicated security pass (clean follow-up — OD-Q1); a standalone `list`
skill; moving the catalog into `settings.yml`; opening/wiring live connections (AID stays a catalog,
not a connection manager). *Lifecycle* (set/unset) still supports all types — only *consumption* is
MCP-first here.

## Gate Criteria

- [ ] `aid-set-connector Jira mcp` on a stem-absent repo creates `.aid/connectors/jira.md` (`connection_type: mcp`, `auth_method: none`, **no** `secret_reference`) + a matching `INDEX.md` row, **without invoking `aid-discover`** (AC1).
- [ ] Re-running `aid-set-connector Jira api` upserts the same `jira` descriptor (type → `api`, api question-set, secret captured via `connector-secret write`) and rewrites its `INDEX.md` row; on a fresh repo the `.secrets/` gitignore precondition is established **before** the secret write (AC2).
- [ ] An in-place type transition reconciles the secret as set-skill logic: `api → mcp`/`none` **purges** the orphaned secret (`connector-secret purge`); `→ api`/aid-managed captures one (AC3).
- [ ] A field-only re-`set` at the same type does **not** re-prompt for the secret; `--rotate-secret` or an `auth_method` change does (AC4).
- [ ] `aid-unset-connector Jira` removes the descriptor, purges its secret, and drops the `INDEX.md` row; a second run is a clean idempotent no-op (AC5).
- [ ] With ≥2 connectors catalogued, `aid-set-connector` / `aid-unset-connector` on **one** stem leave **every other** connector's descriptor + secret untouched (single-stem reconcile, never a whole-registry diff) (AC6).
- [ ] `aid-discover` ELICIT still authors/reconciles connectors with **no behavior change**, now via the shared `reconcile.md` reference in **bulk mode** (AC7).
- [ ] The `## Connectors` section is present in **all 5 profile context files**, and the four `AGENTS.md` remain **byte-identical** to each other afterward (`test-agents-md-invariant.sh` passes) (AC8).
- [ ] A `ticket_ref` scalar (`<connector-stem>:<external-id>`) can be set at work, feature, delivery, and/or task level; a seam resolves the **nearest** ref by AID containment (`task → owning (SPEC-traced) feature → delivery → work`; `delivery → work`; `feature → work`) and acts via the linked connector's host MCP — a task with `ticket_ref: jira:PROJ-45` (or inheriting) + a `jira` MCP connector posts an `In Progress` transition to `PROJ-45` (AC9).
- [ ] The new skills write **only** within `.aid/connectors/` (write-zone confinement), and `connector-secret write` is never invoked before the `.secrets/` gitignore precondition holds (AC10).
- [ ] `/generate-profile` renders clean; dogfood byte-identity + connector-twin PS-parity + PS 5.1 lanes stay green (AC11).
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Extract the shared `connectors/reconcile.md` (bulk + single-stem) and refactor `state-elicit.md` to reuse it |
| task-002 | IMPLEMENT | `aid-set-connector` skill (+ references: per-type question-sets, secret reconcile, gitignore precondition, single-stem) |
| task-003 | IMPLEMENT | `aid-unset-connector` skill |
| task-004 | IMPLEMENT | Consumption protocol + seam wiring + multi-level `ticket_ref` STATE/SPEC schema |
| task-005 | CONFIGURE | Add the `## Connectors` section to all 5 profile context files (AGENTS.md byte-identity) |
| task-006 | CONFIGURE | Register the two new skills for emission + run `/generate-profile` |
| task-007 | TEST | Canonical test suites covering AC1–AC11 |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Flattened Lite work; hand-driven dogfood (no shortcut-catalog row). Hard dependency on the v2.1
connectors subsystem (work-002) shipping first — until it does there is no connector catalog in the
field for these skills to manage or consume. The `ticket_ref` STATE/SPEC scalar coordinates with the
in-flight `work-003-state-schema` frontmatter conventions. Detailed design belongs in the task
DETAIL.md files.
