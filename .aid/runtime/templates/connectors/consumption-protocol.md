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
> aid-managed consumption is deferred.
>
> This is a `canonical/` artifact: it ships and installs byte-identically into every profile's
> `.aid/runtime/templates/connectors/` install tree, alongside
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

## Work sources (`sources:`)

A work's tracker items, files, documents and links are entries of **one** list: the work's
`sources:` in its `STATE.yml` (`work-state-template.yml`). It is the only place a work records an
external link. No unit below the work carries one: a feature, a delivery or a task holds no link of
its own, and a feature's `REQUIREMENTS.md § 11` section carries no `**Ticket:**` line. A work's
entries reach that work only. Project sources (`.aid/connectors/INDEX.md`,
`.aid/knowledge/external-sources.md`) are never listed in it: every work uses them when needed,
unattached.

Each entry carries five fields:

```yaml
sources:
  - ref: 'jira:PROJ-123'   # connector-stem:id, a URL, or a repo-relative path
    kind: ticket           # ticket | issue | document | link | file
    added: '2026-10-14T10:00:00Z'
    phase: Planning        # phase when it entered
    effect: 'answered Q4, Q6; raised Q9'
```

- `ref` names the source: `<connector-stem>:<external-id>` for a tracker item (the stem is one
  catalogued under `.aid/connectors/`, the id is whatever that tracker uses for the item), a URL, or
  a repo-relative path.
- `kind` is one of the closed values `ticket | issue | document | link | file`.
- `added` is the ISO-8601 UTC time the source entered the work; `phase` is the phase the work was in
  at that time.
- `effect` says what applying the source did, for example `answered Q4, Q6; raised Q9`.

An entry is appended when a source is pulled in, at any phase, and has a single writer: the work's
active branch.

### Write-backs (`write_backs:`)

On the user's request only, the agent writes the work's information back to a source through
`/aid-update-ticket` (preview and confirm, as for any ticket write). Each write adds one entry to the
top-level `write_backs:` list. The list sits beside `sources:`, not inside it, so every key stays
within three levels:

```yaml
write_backs:
  - at: '2026-10-15T09:00:00Z'
    source: 'jira:PROJ-123'            # the sources[].ref written to
    part: attachment                   # the /aid-update-ticket part written
    files: 'REQUIREMENTS.md, PLAN.md'  # one comma-separated string
```

- `at` is the ISO-8601 UTC time of the write; `source` is the `sources[].ref` it was written to.
- `part` is the `/aid-update-ticket` part used: `description`, `comment`, `status` or `attachment`.
- `files` names the files attached, as one comma-separated string. It is set for `attachment` only
  (usually `REQUIREMENTS.md`).

### Finding the work's ticket

A seam that needs the work's tracker item (to read it through `/aid-read-ticket`) takes the first
`sources:` entry whose `kind` is `ticket` and whose `ref` is `<connector-stem>:<external-id>`. An
entry of any other kind is never read as a ticket.

**Terminal case.** A work with no such entry resolves to **no ticket**. The seam then skips
connector interaction silently, the same as an unmatched connector: there is nothing to read.

## Wired seams

Every seam below implements the recipe above via a **short, additive step or section** that
**points to this file** — no seam re-describes the recipe inline, and none of the pointers change
any existing behavior; a work with zero catalogued connectors and no `sources:` ticket behaves
identically to before this protocol existed.

| Seam | Role | What it does |
|---|---|---|
| `aid-describe` | Ingest | When the interview's originating context names a source ticket (e.g. a Monitor-routed finding, or the human names one), read it **via `/aid-read-ticket`** and add its `sources:` entry to the work it just created. |
| `aid-specify` | Ingest | When specifying a feature whose requirements trace to a source ticket, read it **via `/aid-read-ticket`** and add its `sources:` entry to the work. The feature section gets no link of its own. |
| `aid-plan` | Ingest | When a deliverable being written corresponds to (or the user names) an external tracker item, add its `sources:` entry to the work's `STATE.yml`. |
| `aid-fix` (and the shared shortcut engine every other shortcut delegates to) | Ingest | When the description this run captures names, or clearly originates from, a filed ticket, add its `sources:` entry to the work `INTAKE` just allocated. |
| `aid-ask` | Enrich | May enrich an answer by reading a linked ticket's status/fields **via `/aid-read-ticket`** when the question concerns a linked tracker item; purely additive to its existing KB/codebase/in-flight-work context sources. |
| `aid-researcher` (agent) | Enrich | May consult `.aid/connectors/INDEX.md` and, for a relevant `mcp` connector, gather additional evidence for a RESEARCH task or a broad `aid-ask` dispatch by reading the linked ticket **via `/aid-read-ticket`** — the same read-heavy, evidence-cited discipline it already applies to KB/codebase sources. |
| `aid-developer` (agent) | Enrich | May consult `.aid/connectors/INDEX.md` and, for a relevant `mcp` connector, pull additional context for an IMPLEMENT/TEST/REFACTOR/CONFIGURE/MIGRATE task by reading the linked ticket's latest description/comments **via `/aid-read-ticket`** before implementing — read-only enrichment; never a substitute for the TASK file's own Scope/Acceptance Criteria. |

**Ingest vs. enrich, restated.** An **ingest** seam runs early in the pipeline (Describe/Define/Specify/
Plan/the shortcut engine's INTAKE) and *adds* a `sources:` entry to the work it is creating or
working in, sourced from a **user-supplied ref** to a ticket that already exists externally,
delegating any read to `/aid-read-ticket`. `aid-ask`/`aid-researcher`/`aid-developer` *enrich* an
answer or an investigation from a connector's live data **via `/aid-read-ticket`**, without adding
a `sources:` entry of their own. **No seam performs an outward write** — filing, commenting,
attaching and status transitions are the dedicated skills' job.

## Worked example (work sources)

A work's `sources:` list holds `ref: 'jira:PROJ-45'` with `kind: ticket`, and a `jira` connector is
catalogued with `connection_type: mcp`.

1. Per this protocol's "Finding the work's ticket" rule: the first `kind: ticket` entry is
   `jira:PROJ-45`, so the seam's ticket is `jira:PROJ-45`, on the connector stem `jira`.
2. **No automated caller acts on this resolution** — there is no seam that picks the ticket and then
   writes anything outward.
3. When someone wants that ticket's live fields, they run the **id-based**
   `/aid-read-ticket jira:PROJ-45` (feature-001's locked grammar `[<connector>:]<ticket-id>` —
   there is **no** work-scoped invocation mode), which scans `INDEX.md` → `jira` row, Type `mcp` →
   confirms `.aid/connectors/jira.md` carries `connection_type: mcp` → requests the Jira
   connection from the host tool's own MCP → fetches and displays the ticket's fields.
4. **No outward write occurs** — no status transition and no comment are posted to `PROJ-45`; a
   change there would be a user-initiated `/aid-update-ticket`, and a record of it would be a
   `write_backs:` entry.

If the work's `sources:` held no `kind: ticket` entry, there would be nothing to read: the terminal
case, a silent skip.
