# Connector Seam Consolidation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Feature identified from REQUIREMENTS.md §5 FR-8, FR-9, FR-6; §4 | /aid-define |
| 2026-07-22 | Cross-ref cycle-1 FIX: split aid-plan Step 4c — added its record-ref-for-existing half to the read-reroute set; retire only its new-ticket-filing write (Q1) | /aid-define (cross-reference) |
| 2026-07-22 | Technical Specification authored | /aid-specify |
| 2026-07-22 | Review cycle-1 FIX: corrected file count (11); de-overclaimed the Wired-seams table; reclassified aid-review INTAKE/PUBLISH as write-reroutes; fixed state-execute quote | /aid-specify (review-fix) |

## Source

- REQUIREMENTS.md §5 FR-8, FR-9, FR-6; §4 Scope

## Description

Consolidate the newer "connectors" generation of tracker interactions onto the single sanctioned
surface. The connector-based read seams — in `aid-describe`, `aid-specify`, `aid-plan` (its Step 4c
record-`ticket_ref`-for-an-existing/named-item half), `aid-fix` and the shared shortcut engine,
`aid-query-kb`, `aid-review`, and the `aid-developer`/`aid-researcher` agents — stop re-implementing
their own fetch and instead delegate to `/aid-read-ticket`; because a user-supplied ref is the
authorization and reads are non-destructive, they need no extra prompt. On the write side,
`aid-execute`'s automatic status-mirror is removed; and `aid-plan`'s Step 4c is split — its outward
"file a new ticket" branch is retired (replaced by a printed `/aid-create-ticket` suggestion) while
its record-ref-for-an-existing-item half is preserved and rerouted through `/aid-read-ticket` — so
those outward transitions no longer happen on their own. The remaining human-gated comment writes —
in `aid-review` (on approval), `aid-research`, and `aid-report` — are rerouted through
`/aid-update-ticket` so there is exactly one write surface; they stay user-authorized and are never
auto-invoked. The result is a single, coherent connector model where every read goes through the
read skill and every write through the update/create skills.

## User Stories

- As an AID adopter/developer, I want every ticket read in the pipeline to go through one shared
  read command so that fetch behavior is consistent and I can see where a read came from.
- As an AID adopter/developer, I want `aid-execute` to stop mirroring status and `aid-plan` to stop
  auto-filing tickets so that tracker transitions only happen when I ask for them.
- As a project lead/PM, I want the human-gated comment writes to flow through one predictable
  update surface so that every comment posted to the tracker is user-authorized and previewed.
- As an AID methodology maintainer, I want the connector read/write seams unified onto the
  dedicated skills so that there is a single outward interaction surface with no re-implemented
  fetches or auto-writes.

## Priority

Must

## Acceptance Criteria

- [ ] Given the consolidation is complete, when `aid-execute` and `aid-plan` run, then
  `aid-execute` no longer auto-mirrors status and `aid-plan` no longer auto-files a new tracker
  item (its record-ref-for-an-existing-item half is preserved and rerouted via `/aid-read-ticket`);
  those outward actions occur only via `/aid-update-ticket` / `/aid-create-ticket`.
- [ ] Given the consolidation is complete, when any remaining ticket READ in another skill or agent
  runs (including `aid-plan`'s Step 4c record half), then it routes through `/aid-read-ticket` and
  none re-implements a direct fetch.

---

## Technical Specification

> Grounded in `architecture.md` (skill state-machine model; the `canonical/` → `profiles/` render;
> the connectors registry is a CATALOG, not a connection manager — "Load-Bearing Boundaries"),
> `authoring-conventions.md` (Prose Over Scripts; durable-anchor citations; the P1(d)-SIG inline-contract
> carve-out), `connectors/consumption-protocol.md` (the wired-seams MCP-first model this consolidates),
> and `state-machine-chaining.md` (the four advance types; "questions belong in `AskUserQuestion`"). The
> **authoritative site list** is REQUIREMENTS §5 FR-8/FR-9 (as amended by cross-reference cycle-1) plus
> the work's 2026-07-22 integration audit; `consumption-protocol.md`'s "Wired seams" table (8 rows) is
> **one input among them, not the complete list** — it omits `aid-review`/`aid-research`/`aid-report`
> (three files this feature edits per FR-8/FR-9) and is itself revised by feature-004. All edits are
> authored in **`canonical/`**
> (the single editable source) and rendered to the five profiles by feature-005; the `.claude/` copies
> are build output. **Hard dependency:** every reroute target — `/aid-read-ticket`, `/aid-update-ticket`,
> `/aid-create-ticket` and the shared `canonical/aid/templates/connectors/ticket-resolution.md` — is
> delivered by **feature-001**, which MUST land first; feature-003 rewires existing seams onto skills
> that do not exist until feature-001 ships (Boundaries).

### Data Model

**No schema changes.** feature-003 edits seam *prose* only — it adds, removes, and renames no field. The
`ticket_ref` LOCAL-LINK (its work/feature/delivery/task carriers per `consumption-protocol.md`
"Multi-level `ticket_ref` linkage", and the "Nearest-ancestor resolution" rule) is untouched here:
`ticket_ref` recording is **preserved** at every read seam that records it today (FR-11), and the
state/spec templates (`work-state-template.md`, `delivery-state-template.md`, `task-state-template.md`,
`specs/spec-template.md`) are not opened. Removing `aid-execute`'s status-mirror removes an outward
*write*, not the field it reads; `ticket_ref` stays a purely local link populated only from a
user-supplied ref, never auto-created or auto-discovered. Changing the `ticket_ref` carriers themselves
is feature-004's concern, not this one. No migration.

### Feature Flow

Each edited seam is a prose state (or an agent-role bullet); consolidation swaps *where a seam points*,
never how AID advances. Per `state-machine-chaining.md` "The four advance types", none of these edits
changes an `**Advance:**` type: a read reroute rides the Ingest/Enrich state that already runs
(FIRST-RUN / INITIALIZE / first-run-loop / INTAKE / Step 2c / REVIEW), and a write reroute rides the
existing HANDOFF or PUBLISH state. No new `PAUSE-FOR-USER-DECISION` is introduced — a `/aid-read-ticket`
delegation is a within-run, non-destructive fetch (feature-001 AC-1: reads never prompt), not a stop-and-resume.

**(a) Reroute the CONNECTORS read seams to `/aid-read-ticket`.** Today each read seam carries a short
additive pointer to `consumption-protocol.md`'s four-step recipe and performs the scan → confirm →
fetch itself. Each is re-pointed to **delegate the fetch to `/aid-read-ticket`** — the one skill that
owns the resolution ladder + MCP-first fetch (feature-001) — and then records the LOCAL-LINK it already
records. Because a user-supplied ref is the authorization and a read is non-destructive, the delegated
read runs with **no extra prompt** (FR-8, AC-9). For a *skill* seam this means the orchestrator issues
the read via `/aid-read-ticket` (resolution + fetch + display) and then writes `ticket_ref`; for an
*agent* seam it means referencing the single shared read recipe `/aid-read-ticket` embodies (see
External Integrations — a dispatched sub-agent cannot itself issue a host slash command). The read
seams (each cited by a durable anchor in Layers & Components):
- `aid-describe` "1e. Connector awareness — record a source ticket's `ticket_ref`" (records at **work**).
- `aid-specify` "Step 3b: Connector awareness — record this feature's `ticket_ref`" (records the
  `**Ticket:**` line at **feature**).
- `aid-plan` "4c. Connector awareness — record this delivery's `ticket_ref`", **record-half only** (see (c)).
- `shortcut-engine` "Step 4b: Connector awareness — record a source ticket's `ticket_ref`" (records at
  **work**; applies to `aid-fix` and every sibling shortcut the engine serves).
- `aid-query-kb` "Step 2c — Connector enrichment (optional)" (folds a ticket's live fields into an answer).
- `aid-review` REVIEW-state "Gather evidence" (the `an issue-tracker MCP to fetch a ticket` clause) —
  the *fetch* only; the INTAKE fast-path `ticket id (PROJ-45)` row edits a **delivery label** (a write
  target), covered under (d), not here.
- the `aid-developer` and `aid-researcher` agent definitions (the `Consult .aid/connectors/INDEX.md`
  enrichment bullet — read-only, never a substitute for the TASK/RESEARCH scope).

**(b) Remove `aid-execute`'s automatic status-mirror.** `state-execute.md` "## Connector Mirroring
(`ticket_ref`, optional)" is deleted in full — the section that resolves the nearest `ticket_ref` and
mirrors every `In Progress` / `In Review` / `Done` / `Failed` transition outward via the host MCP. The
mandatory local State-Write Protocol (`writeback-state.sh`) is untouched — the mirror was already
declared "Additive … never a substitute, never a precondition", so removing it changes no local write.
After this edit `aid-execute` performs **zero** outward tracker writes; a status change reaches a
tracker only when the user runs `/aid-update-ticket status` (AC-8). **Decision (decide-don't-defer):**
remove the section outright rather than convert it to a printed suggestion — a per-task, per-transition
status suggestion firing on every execute loop would be noise, and `aid-execute` has no single natural
HANDOFF moment to host one; the dedicated skill is the surface.

**(c) Split `aid-plan` Step 4c.** The current "4c. Connector awareness" step conflates two actions in one
sentence — *"If this deliverable corresponds to (or the user names) an external tracker item, **or the
team wants one filed for it, create/register it** via a catalogued issue-tracker connector … and record
`ticket_ref`."* The split:
- **Retire the outward write half** — the *"the team wants one filed for it → create/register it via a
  catalogued issue-tracker connector"* branch is removed and replaced by a **printed suggestion**:
  "to file a tracker item for this deliverable, run `/aid-create-ticket`, then re-record its ref."
  aid-plan never files a ticket on its own (AC-8), mirroring the `aid-report`/`aid-research`
  never-auto-invoked HANDOFF pattern.
- **Keep and reroute the record-for-existing half** — *"this deliverable corresponds to (or the user
  names) an external tracker item"* → **read it via `/aid-read-ticket`** and record `ticket_ref` at the
  **delivery** level (the `delivery-NNN/STATE.md`, or the work-root `STATE.md` for a flattened work). This
  half is an Ingest read + LOCAL-LINK, not an outward write, so it needs no confirm (FR-9, AC-9); the
  `ticket_ref` recording is preserved (FR-11).

**(d) Reroute the human-gated comment writes through `/aid-update-ticket`.** The three seams that can post
a comment to a source ticket are re-pointed at `/aid-update-ticket comment` so there is exactly one write
surface; they stay user-authorized and are **never auto-invoked**:
- `aid-review` "## State: PUBLISH  (only on approval)" — the `a ticket comment via the MCP connector`
  delivery method becomes a `/aid-update-ticket comment` delivery. The human gate is unchanged:
  PRESENT-FINDINGS already stops for approval before anything is posted (`state-machine-chaining.md`
  HALT/approval), and PUBLISH runs only on that approval; the outward write is now issued through the
  dedicated skill (which itself previews the exact payload — feature-001 AC-3) rather than a direct MCP
  call. The INTAKE fast-path "ticket comment via an MCP connector" tentative-delivery label is updated to
  name `/aid-update-ticket`.
- `aid-research` "## State: HANDOFF  (optional; printed suggestions only)" — the `a source ticket (MCP
  connector, connectors/consumption-protocol.md)` suggestion clause is re-pointed to
  `/aid-update-ticket comment` (still a printed suggestion the user must act on; "Human final say before
  any commit" is preserved).
- `aid-report` "## State: HANDOFF  (optional; printed suggestions only)" — the `comment on a source
  ticket` suggestion is re-pointed to `/aid-update-ticket comment` (printed suggestion only).

### Layers & Components

Three edit classes across **11 distinct canonical files** (13 seam edits — `first-run-loop.md` and
`aid-review/SKILL.md` each carry both a read-reroute and a write-reroute, so they appear in two tables
below), each cited by a durable, grep-recoverable anchor
(never a bare `file:line`, per `authoring-conventions.md` "Citation Rule"). No file gains a new
`allowed-tools` grant: the connector read/write tooling is fully encapsulated in the feature-001 skills,
so a seam that used to request a host-MCP connection at runtime now delegates that entirely; the two
agent defs keep their existing `tools:` line unchanged (review-lesson: declare the tools needed — here,
**none new**).

**Read seams (reroute → `/aid-read-ticket`):**

| Seam file (canonical) | Durable anchor |
|---|---|
| `skills/aid-describe/references/state-first-run.md` | "1e. Connector awareness — record a source ticket's `ticket_ref` (optional)" |
| `skills/aid-specify/references/state-initialize.md` | "Step 3b: Connector awareness — record this feature's `ticket_ref` (optional)" |
| `skills/aid-plan/references/first-run-loop.md` | "4c. Connector awareness — record this delivery's `ticket_ref` (optional)" (record-half only — see (c)) |
| `aid/templates/shortcut-engine.md` | "Step 4b: Connector awareness — record a source ticket's `ticket_ref` (optional)" (`aid-fix` + all sibling shortcuts) |
| `skills/aid-query-kb/SKILL.md` | "Step 2c — Connector enrichment (optional)" |
| `skills/aid-review/SKILL.md` | "## State: REVIEW" → "Gather evidence" (the `an issue-tracker MCP to fetch a ticket` clause) — the fetch only; the INTAKE label + PUBLISH comment are write-reroutes (Write seams table) |

**Write seams:**

| Seam file (canonical) | Durable anchor | Change |
|---|---|---|
| `skills/aid-execute/references/state-execute.md` | "## Connector Mirroring (`ticket_ref`, optional)" | remove the section outright (b) |
| `skills/aid-plan/references/first-run-loop.md` | "4c. Connector awareness — record this delivery's `ticket_ref` (optional)" | retire the create/register outward-write branch → printed `/aid-create-ticket` suggestion (c) |
| `skills/aid-review/SKILL.md` | "## State: PUBLISH  (only on approval)" (the `a ticket comment via the MCP connector` clause) **and** the INTAKE fast-path `ticket comment via an MCP connector` tentative-delivery label (the `ticket id (PROJ-45)` row) | reroute both → `/aid-update-ticket comment` (d) |
| `skills/aid-research/SKILL.md` | "## State: HANDOFF  (optional; printed suggestions only)" (the `a source ticket (MCP connector, connectors/consumption-protocol.md)` clause) | re-point suggestion → `/aid-update-ticket comment` (d) |
| `skills/aid-report/SKILL.md` | "## State: HANDOFF  (optional; printed suggestions only)" (the `comment on a source ticket` clause) | re-point suggestion → `/aid-update-ticket comment` (d) |

**Agent definitions (reroute → the `/aid-read-ticket` read behavior):**

| Agent def (canonical) | Durable anchor |
|---|---|
| `agents/aid-developer/AGENT.md` | the "## What You Do" bullet beginning `Consult .aid/connectors/INDEX.md` |
| `agents/aid-researcher/AGENT.md` | the "## What You Do" bullet beginning `Consult .aid/connectors/INDEX.md` |

**Hard dependency on feature-001.** Every anchor above is re-pointed at a target
(`/aid-read-ticket` / `/aid-update-ticket` / `/aid-create-ticket`, backed by the shared
`aid/templates/connectors/ticket-resolution.md`) that **feature-001 delivers**. feature-003 is
inert — and its rerouted pointers dangle — until feature-001 lands, so the delivery plan MUST sequence
feature-001 before feature-003.

### External Integrations

- **One outward surface, always via the feature-001 skills.** After this feature, no seam reaches a
  tracker on its own: every read delegates to `/aid-read-ticket`, and every outward write (comment, and
  by retirement no more auto status/auto-file) flows through `/aid-update-ticket` / `/aid-create-ticket`
  (FR-6). Internal `ticket_ref` recording is not an outward interaction and needs no validation.
- **MCP-first is unchanged.** The feature-001 skills consume the resolved connector MCP-first per
  `consumption-protocol.md` "The seam recipe (generic shape)" — request the connection from the host
  tool's own MCP; AID resolves no credential and stores none. Consolidation moves *where the recipe is
  invoked from* (a seam pointer) but not the recipe itself. aid-managed (`api`/`ssh`/`cli`) live
  consumption remains the deferred follow-up.
- **Agent delegation mechanism (decide-don't-defer + acknowledge reality).** A dispatched sub-agent
  cannot issue a host slash command, so "delegate to `/aid-read-ticket`" cannot mean an agent literally
  types the command. **Decision:** the `aid-developer` / `aid-researcher` bullets are re-pointed from
  `consumption-protocol.md`'s raw four-step recipe to **the single shared read recipe `/aid-read-ticket`
  embodies** (the `ticket-resolution.md` ladder + the MCP-first consumption step) — one fetch definition,
  no divergent inline re-implementation (AC-9). The enrichment stays optional and read-only; a
  user-supplied/linked ref is the authorization; no confirm.
- **Catalog reality (acknowledged).** The shipped `preset-catalog.md` presets yield **no** `mcp`
  `issue-tracker` connector today (Jira/GitLab presets are `api`-typed; the GitHub `mcp` preset is tagged
  `source-host`, not `issue-tracker`). Every rerouted read/write therefore silently skips on a project
  with no matching `mcp` connector and no `ticket_ref` — identical to pre-change behavior (NFR-3) — and
  activates once a user registers a custom `mcp` issue-tracker connector. This is expected, not a defect.

### Testing

Behavior tests are structural / per-site (the host MCP + a live tracker are unavailable in CI), fitting
`test-landscape.md` and grepping `canonical/` (not `.claude/`, which is render output). Two acceptance
criteria drive them:

- **AC-8 — no auto-writes remain.**
  - `state-execute.md` no longer contains the "## Connector Mirroring" section, nor any
    outward-mirror signature (illustrative, verbatim from disk: "mirror the same transition to that
    ticket via the host tool's MCP") — the section is deleted outright regardless; the local
    `writeback-state.sh` State-Write Protocol stays present and unconditional.
  - `first-run-loop.md` Step 4c no longer carries the `create/register it via a catalogued issue-tracker
    connector` outward-file signature; a printed `/aid-create-ticket` suggestion is present instead.
  - A grep across the CONNECTORS seams confirms outward create/mirror actions occur **only** via
    `/aid-update-ticket` / `/aid-create-ticket`.
- **AC-9 — every remaining read delegates to `/aid-read-ticket`.**
  - Per-site check (not just a grep): each of the six read-seam anchors + the two agent bullets names
    `/aid-read-ticket` as the fetch surface and carries **no** inline direct-fetch recipe of its own
    (i.e., the seam no longer describes "request the connection from the host tool's own MCP" as its own
    step — it points at `/aid-read-ticket`).
  - Includes `aid-plan` Step 4c's **record-half** (the kept branch routes through `/aid-read-ticket`).
- **NFR-3 regression:** a fixture project with no `issue-tracker` connector and no `ticket_ref` exercises
  each edited seam and confirms silent-skip (no error, no prompt) — behavior identical to before.

Byte/path-parity of the rendered `profiles/*` copies and the dogfood `.claude/` resync are **feature-005's**
gate (`test-dogfood-byte-identity`, CLI-parity), not duplicated here.

### Boundaries (this feature only)

feature-003 **only** rewires the CONNECTORS-generation seams onto the feature-001 skills (the read
reroutes, the `aid-execute` mirror removal, the `aid-plan` Step 4c split, the three comment-write
reroutes). It does **not**:
- retire the older PM-TOOL `infrastructure.md § Project Management` writes (`aid-describe` create-Epic,
  `aid-detail` create-Tickets, `aid-plan/SKILL.md` create-Sprint, `aid-execute/SKILL.md` PM-tool
  update, `aid-deploy` create-Release, `aid-monitor` create-BUG-tickets) — that is **feature-002**
  (FR-7). Note `aid-plan/SKILL.md`'s PM-TOOL Sprint write (feature-002) is distinct from
  `first-run-loop.md` Step 4c's CONNECTORS create/register (this feature);
- revise `consumption-protocol.md` (drop the automated file/mirror/comment capability; restate reads as
  delegating to `/aid-read-ticket`) — that is **feature-004** (FR-10);
- change the `ticket_ref` carriers or the state/spec templates — **feature-004** (FR-11);
- run the generator, re-emit `profiles/*`, resync dogfood `.claude/`, or gate byte/path-parity — that is
  **feature-005** (FR-12).

feature-003 depends on **feature-001** (the three skills + `ticket-resolution.md`) existing first;
its rerouted pointers are otherwise dangling references.
