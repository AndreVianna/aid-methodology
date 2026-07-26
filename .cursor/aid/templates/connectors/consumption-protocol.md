# Connector Consumption Protocol (MCP-First)

> Shared reference for **consumption** — how a pipeline seam (a skill state, or a dispatched
> agent) uses an already-catalogued connector at runtime. This is the counterpart to
> [`reconcile.md`](reconcile.md) (which governs how a connector gets ADDED/UPDATED/REMOVED from
> `.aid/connectors/`): reconcile owns the catalog's lifecycle, this protocol owns what a seam does
> with a catalogued entry once it exists. Every seam listed in "Wired seams" below implements this
> protocol by a **short, additive pointer** to this file — none of them re-describe the recipe
> inline, and none of them are restructured to adopt it. A wired seam consumes a catalogued
> connector for **reads only**, delegating the read to `/aid-read-ticket`, and **never** files,
> comments on, or transitions a ticket — every outward write flows through the dedicated
> `/aid-create-ticket` / `/aid-update-ticket` skills.
>
> **MCP-first, by design (OD-Q1).** Consumption here is scoped to **tool-managed (`connection_type:
> mcp`) connectors only**. A seam requests the connection from the **host tool's own MCP/plugin** —
> AID resolves nothing and stores no credential for it (matches the root `## Connectors` context-file
> section and `preset-catalog.md`'s Q10 management-mode split). **aid-managed consumption**
> (`api`/`ssh`/`cli` — resolving `secret_reference` when the type carries one (`api` only) and
> making a live call) is explicitly **out of scope** here; the descriptor still exists for
> discovery/audit (an agent may read it,
> cite it, or point a human at it), but no seam in this protocol resolves its secret or calls out to
> it. A `connector-secret resolve` primitive + the security pass that would need to accompany
> aid-managed consumption is a follow-up (`SPEC.md § Out of Scope / Deferred`).
>
> This is a `canonical/` artifact: it ships and installs byte-identically into every profile's
> `.claude/aid/templates/connectors/` (or equivalent per-tool) install tree, alongside
> [`reconcile.md`](reconcile.md) and [`preset-catalog.md`](preset-catalog.md).

## The seam recipe (generic shape)

Every wired seam below follows the same four-step recipe. A seam that finds nothing at Step 1 or
Step 2 simply **skips silently** — connector consumption is always optional, never a precondition
a seam blocks on.

1. **Scan the catalog.** Read `.aid/connectors/INDEX.md` (the same `@.aid/connectors/INDEX.md`
   context-file pointer every profile's root context file carries). Look for a row whose **Type**
   column is `mcp` and whose purpose matches what the seam needs (e.g. an issue-tracker connector
   when the seam is reading a ticket; `preset-catalog.md`'s `tags` column — e.g.
   `issue-tracker` — is the same purpose-matching signal ELICIT already uses).
2. **Confirm via the descriptor.** Open the matched `.aid/connectors/<stem>.md` and confirm
   `connection_type: mcp`. No match, or a match whose `connection_type` is anything else
   (`api`/`ssh`/`cli`) → this protocol does not apply; the seam proceeds without connector
   interaction (aid-managed consumption is out of scope here, per the header note above).
3. **Request the connection from the host tool.** Never from AID's own descriptor fields — the
   descriptor's `endpoint` (if present) is **informational only** (`preset-catalog.md`'s Q10
   contract), never a launch/wire command. The agent asks the host tool's own MCP/plugin for the
   named target (e.g. "the Jira MCP") and uses whatever tool surface that connection exposes.
   AID resolves no credential and stores none for this call.
4. **Read, then stop.** Read through the host MCP only, delegating that read to
   `/aid-read-ticket` rather than re-implementing a fetch; the seam never files, comments on, or
   transitions a ticket — every outward write flows through `/aid-create-ticket` /
   `/aid-update-ticket`. Never persist anything host-MCP-specific back into `.aid/connectors/` —
   the descriptor and `INDEX.md` are catalog metadata, not a cache of live tool state.

## Multi-level `ticket_ref` linkage

A `ticket_ref` scalar links **one lifecycle unit** to **one external tracker item**, tying the
link to a catalogued connector stem:

```
ticket_ref: "<connector-stem>:<external-id>"     # e.g. jira:PROJ-123
```

`<connector-stem>` MUST name a stem catalogued under `.aid/connectors/` (the same stem
`connector-registry.sh read <stem> <field>` addresses); `<external-id>` is whatever identifier
that connector's target tool uses for the item (a Jira key, a GitHub issue number, ...). `ticket_ref`
is a **lifecycle-unit field, never a connector-descriptor field** — the descriptor schema
(`name`/`connection_type`/`endpoint`/`auth_method`/`secret_reference`/`preset`/routing fields) is
completely unchanged by this protocol; nothing here adds a field to `.aid/connectors/<stem>.md`.

**Settable at any level, always optional.** `ticket_ref` may be set at **work**, **feature**,
**delivery**, and/or **task** — independently, and none of them are required. A unit that carries
no `ticket_ref` of its own simply inherits one via the resolution rule below; a unit whose entire
containment chain carries no `ticket_ref` anywhere resolves to **nothing**, and every seam treats
that exactly like "no relevant MCP connector found" (Step 2 of the seam recipe above) — skip
silently, no error. Readers/dashboard ignore the field entirely when absent (backward-compatible;
no required-field semantics change anywhere it is added).

**Where it lives, per level** (coordinate with the in-flight `work-003-state-schema` frontmatter
conventions — these are the same frontmatter blocks that work touches):

| Level | Carrier | Field |
|---|---|---|
| Work | `STATE.md` frontmatter (`work-state-template.md`) | `ticket_ref` |
| Feature | `SPEC.md` body (`specs/spec-template.md`) — SPEC.md carries no frontmatter block | `**Ticket:**` line |
| Delivery | `STATE.md` frontmatter (`delivery-state-template.md`) — full path only (a flattened work's single delivery uses the work-root `STATE.md`'s own `ticket_ref`, per the flattened `## Delivery Lifecycle` promotion `work-state-template.md` already documents) | `ticket_ref` |
| Task | `STATE.md` frontmatter (`task-state-template.md`) — **full path only**. The flattened layout (no per-task `STATE.md`, the `### Tasks lifecycle` table instead) carries no separate task-level `ticket_ref` of its own; resolution for a flattened task passes straight through to its delivery/work levels, which do carry the scalar. | `ticket_ref` |

## Nearest-ancestor resolution

Nearest-ancestor resolution is the **inheritance/traceability semantics** of the link — a
lifecycle unit without its own `ticket_ref` inherits the **nearest** ancestor's effective ref by
AID containment (`work ⊃ delivery ⊃ task`, `work ⊃ feature`; a delivery groups ≥1 feature). A unit
uses its **own** `ticket_ref` when present; otherwise it inherits, per unit type:

| Resolving for... | Chain (own → ancestor → ... → work) |
|---|---|
| Delivery | `delivery → work` |
| Feature | `feature → work` |
| Task | `task → its owning (SPEC-traced) feature → its delivery → work` |

**Why feature outranks delivery for a task.** A delivery bundles several features; the feature is
the task's specific subject. A `PLAN.md` deliverable groups features by shippable increment, not by
subject matter — inheriting the delivery's `ticket_ref` first would attribute a task to whichever
tracker item happens to cover the *whole delivery*, when the *feature* it actually implements may
have its own, more specific one. So the feature — the narrower, more specific ancestor — is
consulted first; the delivery, the broader one, only if the feature has none.

**"Owning feature" — SPEC-traced, not just co-located.** A task's owning feature is the one its
`DETAIL.md` traces to (via its `Source`/`Depends on` lineage back through `PLAN.md`'s deliverable
entry to a specific `feature-NNN-{name}/SPEC.md`) — never merely "some feature in the same delivery."
**A task tracing to no single feature skips the feature level entirely**: a flattened Lite work has
no `features/` folder at all (a single implicit feature — feature-level `ticket_ref` for a Lite work
lives nowhere, since there is no `SPEC.md` other than the work-root one, which is inherited via the
work level instead), and even in a full-path work a task that legitimately spans multiple features
(rare — most tasks trace to exactly one) has no single feature to consult, so resolution for that
task is `task → its delivery → work` instead — the delivery is used because it is still a genuine
ancestor of the task, unlike an ambiguous choice among several sibling features.

**Terminal case.** If every level in the chain is absent (own field empty and every ancestor's
field empty, all the way to work), resolution yields **no ticket** — the seam skips connector
interaction for this unit (same silent-skip behavior as an unmatched connector).

## Wired seams

Every seam below implements the recipe above via a **short, additive step or section** that
**points to this file** — no seam re-describes the recipe inline, and none of the pointers change
any existing behavior; a work with zero catalogued connectors and zero `ticket_ref` values behaves
identically to before this protocol existed.

| Seam | Role | What it does |
|---|---|---|
| `aid-describe` | Ingest | When the interview's originating context names a source ticket (e.g. a Monitor-routed finding, or the human names one), read it **via `/aid-read-ticket`** and record `ticket_ref` at the **work** level it just created. |
| `aid-specify` | Ingest | When specifying a feature whose requirements trace to a source ticket, read it **via `/aid-read-ticket`** and record `ticket_ref` at the **feature** level (the `SPEC.md` it is authoring). |
| `aid-plan` | Ingest | When a deliverable being written corresponds to (or the user names) an external tracker item, record its `ticket_ref` at the **delivery** level (the `delivery-NNN/STATE.md`, or the work-root `STATE.md` for a flattened work, it is creating). |
| `aid-fix` (and the shared shortcut engine every other shortcut delegates to) | Ingest | When the description this run captures names, or clearly originates from, a filed ticket, record its `ticket_ref` at the **work** level `INTAKE` just allocated. |
| `aid-query-kb` | Enrich | May enrich an answer by reading a linked ticket's status/fields **via `/aid-read-ticket`** when the question concerns a linked tracker item; purely additive to its existing KB/codebase/in-flight-work context sources. |
| `aid-researcher` (agent) | Enrich | May consult `.aid/connectors/INDEX.md` and, for a relevant `mcp` connector, gather additional evidence for a RESEARCH task or a broad `aid-query-kb` dispatch by reading the linked ticket **via `/aid-read-ticket`** — the same read-heavy, evidence-cited discipline it already applies to KB/codebase sources. |
| `aid-developer` (agent) | Enrich | May consult `.aid/connectors/INDEX.md` and, for a relevant `mcp` connector, pull additional context for an IMPLEMENT/TEST/REFACTOR/CONFIGURE/MIGRATE task by reading the linked ticket's latest description/comments **via `/aid-read-ticket`** before implementing — read-only enrichment; never a substitute for the TASK file's own Scope/Acceptance Criteria. |

**Ingest vs. enrich, restated.** An **ingest** seam runs early in the pipeline (Describe/Define/Specify/
Plan/the shortcut engine's INTAKE) and *records* a `ticket_ref` at the level it is creating, sourced
from a **user-supplied ref** to a ticket that already exists externally, delegating any read to
`/aid-read-ticket`. `aid-query-kb`/`aid-researcher`/`aid-developer` *enrich* an answer or an
investigation from a connector's live data **via `/aid-read-ticket`**, without recording or
resolving a `ticket_ref` of their own. **No seam performs an outward write** — filing, commenting,
and status transitions are the dedicated skills' job.

## Worked example (nearest-ancestor resolution)

A task carries no `ticket_ref` of its own, but its owning feature does:
`ticket_ref: jira:PROJ-45`. A `jira` connector is catalogued with `connection_type: mcp`.

1. Per this protocol's resolution rule: the task's own `ticket_ref` is absent → its owning
   (SPEC-traced) feature has `jira:PROJ-45` → resolution stops there (nearest ancestor found). By
   nearest-ancestor, the task's **effective** `ticket_ref` resolves to `jira:PROJ-45` — the
   traceability link a reader/dashboard shows for the task.
2. **No automated caller acts on this resolution** — there is no seam that resolves
   nearest-ancestor and then writes anything outward.
3. When someone wants that ticket's live fields, they run the **id-based**
   `/aid-read-ticket jira:PROJ-45` (feature-001's locked grammar `[<connector>:]<ticket-id>` —
   there is **no** unit-scoped invocation mode), which scans `INDEX.md` → `jira` row, Type `mcp` →
   confirms `.aid/connectors/jira.md` carries `connection_type: mcp` → requests the Jira
   connection from the host tool's own MCP → fetches and displays the ticket's fields.
4. **No outward write occurs** — no status transition and no comment are posted to `PROJ-45`; a
   change there would be a user-initiated `/aid-update-ticket`.

If the task's feature instead carried no `ticket_ref`, resolution would continue to the task's
delivery, then to the work; if none of those carried one either, resolution yields **no effective
ticket** (terminal case) — there is nothing to read.
