# PM-Tool Automated-Write Retirement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Feature identified from REQUIREMENTS.md §5 FR-7, FR-6; §4 | /aid-define |
| 2026-07-22 | Cross-ref cycle-1 FIX: added the no-ticket-analog carve-out (aid-deploy Release / Epic / Sprint-link removed outright, no suggestion); AC reframed to a per-site check + expanded illustrative signature set | /aid-define (cross-reference) |
| 2026-07-22 | Technical Specification authored | /aid-specify |
| 2026-07-22 | Review cycle-1 FIX: suggestion made conditional on a catalogued issue-tracker connector (silent when none) — AC-10/NFR-3; corrected the "(optional)" precedent quote; Testing reframed to dogfood+review; state-*.md nit | /aid-specify (review-fix) |
| 2026-07-22 | Review cycle-2 FIX: suggestion-gate reworded type-agnostic (any issue-tracker connector); dropped false parity claim with feature-001 step-2 (mcp-only); added nudge-vs-act rationale | /aid-specify (review-fix) |

## Source

- REQUIREMENTS.md §5 FR-7, FR-6; §4 Scope

## Description

Retire the older "PM-Tool" generation of automated tracker writes — the writes that fire off the
`infrastructure.md § Project Management` guidance embedded in other skills. Today several pipeline
skills silently create or mutate tracker items on the user's behalf: `aid-describe` creates an
Epic, `aid-detail` creates Tickets/Work-Items, `aid-plan` creates Sprint/Iteration entries,
`aid-execute` updates a ticket to In Progress/Done and adds a comment, `aid-deploy` creates a
Release and marks tickets Done/Closed, and `aid-monitor` creates tickets for BUG tasks. This
feature removes every one of those automated writes. Where a removed write has a ticket-scoped
analog it is replaced with a printed suggestion to invoke the appropriate dedicated ticket skill
(status changes / mark-Done-Closed → `/aid-update-ticket status`; create ticket/epic/work-item/
bug-ticket → `/aid-create-ticket`) — mirroring the existing "never auto-invoked" HANDOFF pattern
already used by `aid-report`/`aid-research`. Where a removed action has no ticket-scoped analog —
`aid-deploy`'s "Create a Release in the PM tool" and "Link the release to the Epic", and any
link-to-Sprint/Epic hierarchy action — it is removed outright with no suggestion, because a
Release/Epic/Sprint is not a ticket and AID's own Deploy State already records the release. After
this change no skill silently touches a tracker through the PM-Tool path; the only outward writes
are the ones the user starts via the dedicated skills.

## User Stories

- As an AID adopter/developer, I want no skill to create or change a tracker item behind my back
  so that I always know when and why the tracker was touched.
- As a project lead/PM, I want the pipeline to suggest a tracker action rather than perform it
  silently so that every outward change stays user-initiated.
- As an AID methodology maintainer, I want the duplicated, tool-coupled PM-Tool write generation
  removed entirely so that there is one coherent integration model and no silent double-writes.

## Priority

Must

## Acceptance Criteria

- [ ] Given the retirement is complete, when each of the six FR-7 sites is checked per-site (not
  only grepped) and the tree is grepped for the automated-write signatures, then zero remain — the
  illustrative (non-exhaustive) signature set includes "create an Epic", "create Tickets/Work
  Items", "create Sprint/Iteration", "update … ticket to In Progress/Done", "add comment to
  ticket", "mark as Done/Closed", "Create a Release in the PM tool", "create tickets for BUG",
  and "link … Epic".
- [ ] Given a removed write has a ticket-scoped analog, when the site is reviewed, then a printed
  dedicated-skill suggestion is left in its place; and given a removed action has no analog
  (Release / Epic / Sprint-link), then it is removed outright with no suggestion.

---

## Technical Specification

> Grounded in `architecture.md` (skill state-machine model; the canonical→profiles single-source render invariant; "the connectors registry is a CATALOG — not a connection manager"), `authoring-conventions.md` (Prose Over Scripts; Content Isolation; "Resolved Items Leave No Trace" — a removed item leaves no tombstone; P1(d) durable-anchor citations), `state-machine-chaining.md` ("The four advance types" — CHAIN / PAUSE-FOR-USER-DECISION), the shipped "never auto-invoked" HANDOFF precedent — both `aid-report/SKILL.md` and `aid-research/SKILL.md` carry `## State: HANDOFF  (optional; printed suggestions only)` with `**Advance:** HANDOFF (optional) then DONE` (an *optional* printed suggestion, not an unconditional emission) — and the FR-7 audit site list (REQUIREMENTS.md §7 Constraints). This feature is a **pure retraction** of the older PM-TOOL automated-write generation: it deletes prose from six existing skill files and, where a ticket-scoped analog exists, replaces the removed write with a printed dedicated-skill suggestion mirroring that HANDOFF precedent. All edits are authored in **`canonical/`** (the single editable source per the single-source invariant); the `.claude/` + five `profiles/*` copies are build output re-rendered by feature-005 — feature-002 hand-edits none of them.

### Data Model

**No schema changes.** feature-002 removes prose instructions from skill state-machine docs; it defines, reads, and persists no data. The `ticket_ref` LOCAL-LINK and every state/spec template are untouched (their preservation is FR-11 / feature-004). No connector-descriptor, catalog, or `settings.yml` change. Nothing stored is migrated (see Migration Plan).

### Feature Flow

The "flow" is a **per-site retraction procedure**, applied once to each of the six FR-7 sites. Each site today is (or contains) a PM-TOOL write block guarded by `If infrastructure.md § Project Management defines a tool: … / If no PM tool → skip`. The procedure:

1. **Remove the guard together with the automated write.** Delete the `If infrastructure.md § Project Management defines a tool:` conditional and every outward-write bullet it guards (plus any progress/timing scaffolding that framed the write). Removing the guard *is* what neutralizes it — no dormant path survives (see Migration Plan). Per "Resolved Items Leave No Trace," the write is deleted outright, not commented out or tombstoned.
2. **Classify each removed action** against the two authoritative analog sets, then either replace it with a printed suggestion or remove it outright:
   - **Ticket-scoped analog exists → printed suggestion** (never auto-invoked): create ticket / **epic** / work-item / bug-ticket → `/aid-create-ticket`; status change / mark Done-Closed → `/aid-update-ticket status`; add a comment → `/aid-update-ticket comment`.
   - **No ticket-scoped analog → remove outright, no suggestion:** a **Release**, a **Sprint/Iteration**, or any **link-to-Sprint/Epic** hierarchy action. Rationale (decided here, not deferred): an **Epic is fileable as an epic-type ticket** → it takes the create analog; but a **link** to an Epic/Sprint, and a **Sprint/Iteration or Release itself**, are board/version constructs, not tickets → no analog. AID's own `## Deploy State` already records the release (FR-7).
3. **Suggestion emission and shape.** The suggestion is **conditional** and **optional** — matching the real precedent (`aid-report`/`aid-research` are `## State: HANDOFF  (optional; printed suggestions only)` / `**Advance:** HANDOFF (optional) then DONE`, i.e. printed suggestions the user *may* act on, never auto-invoked). It is emitted **only when at least one catalogued `issue-tracker`-tagged connector exists** in `.aid/connectors/`, regardless of its `connection_type`. When **no** issue-tracker connector is catalogued at all, the site **prints nothing** — a true silent skip, behaviorally identical (byte-for-byte in output terms) to the pre-change `If no PM tool → skip`, which satisfies AC-10 ("a work with no `ticket_ref` and no connector behaves identically to before") and NFR-3 ("every seam silently skips … identical to pre-change behavior"). The suggestion never re-introduces the removed `infrastructure.md § Project Management` guard; it re-keys off the connectors catalog instead.
   - **Type-agnostic by design (nudge vs. act).** This gate is deliberately **broader** than feature-001's resolution-ladder step 2, which filters on **Type = `mcp` AND tag = `issue-tracker`** to decide whether a *live MCP call* is possible. This gate only decides whether to **nudge**: the presence of *any* registered issue-tracker connector (including an `api`-typed Jira/GitLab preset) means the user tracks work in an external tracker, so a pointer to the dedicated skill is apt — even if that connector is not itself live-consumable. Resolving mcp-vs-api, choosing among multiple connectors, and emitting the "registered but not live-consumable" / "no issue-tracker connector found" runtime messages are all handled *inside* the dedicated skill (feature-001 AC-4/AC-5/AC-6), never re-implemented at these sites. AC-10's silent-skip is unaffected: **no `issue-tracker` connector at all → no suggestion.**

Advance types are unchanged at every site (`state-machine-chaining.md` "The four advance types"): sections that carried `**Advance:** CHAIN` keep CHAIN when they survive as a suggestion; aid-describe keeps its Step-5 PAUSE-FOR-USER-DECISION; sites removed outright drop the block without adding any new advance. No site adds a HANDOFF *state* — the suggestions are printed lines inside the existing state, exactly as in `aid-report`/`aid-research`.

**Per-site disposition (all six, decided — not deferred):**

| # | Site (canonical, short) | Removed automated write | Disposition |
|---|---|---|---|
| 1 | aid-describe · state-completion | create an Epic for this work | **Suggest** `/aid-create-ticket` (file an epic-type ticket) |
| 2 | aid-detail · task-decomposition | create Tickets/Work Items; link each to Sprint/Epic | **Mixed** — suggest `/aid-create-ticket` for the create half; **remove outright** the link-to-Sprint/Epic bullet |
| 3 | aid-plan · SKILL | create Sprint/Iteration entries; map deliveries to Sprints | **Remove outright** (whole section) — a Sprint/Iteration is not a ticket; no suggestion |
| 4 | aid-execute · SKILL | update ticket In Progress / Done; add comment | **Suggest** `/aid-update-ticket status` (In Progress → Done) + `/aid-update-ticket comment` |
| 5 | aid-deploy · state-packaging Step 8 | Create a Release; mark tickets Done/Closed; link release to Epic | **Mixed** — suggest `/aid-update-ticket status` for mark-Done/Closed; **remove outright** the Release-create + link-to-Epic bullets |
| 6 | aid-monitor · state-route | create tickets for BUG tasks; link to Sprint/Epic | **Mixed** — suggest `/aid-create-ticket` for the BUG-ticket create half; **remove outright** the link-to-Sprint/Epic bullet + the ▶/✓ PM-tool timing scaffolding |

### Layers & Components

Six existing `canonical/` files, each edited at one durable, greppable anchor. No new file. **No frontmatter / `allowed-tools` change** at any site: a printed suggestion is plain prose output requiring no tool, and the removed writes carried no static tool declaration either — the host-MCP write capability they assumed is exactly what is being removed. (Two of the six are `SKILL.md` — aid-plan, aid-execute; the other four live under `references/` — three `state-*.md` plus `task-decomposition.md`.)

| # | File (canonical) | Durable anchor | Removed write signature(s) |
|---|---|---|---|
| 1 | `canonical/skills/aid-describe/references/state-completion.md` | `### Step 5: Process Approval Response` → the `[1] Approved` bullet `create an Epic for this work` | "create an Epic" |
| 2 | `canonical/skills/aid-detail/references/task-decomposition.md` | `## Project Management Sync (conditional)` | "create Tickets/Work Items", "Link each ticket to the corresponding Sprint … and Epic" |
| 3 | `canonical/skills/aid-plan/SKILL.md` | `## Project Management Sync (conditional)` | "create Sprint/Iteration entries", "Map deliveries to Sprints" |
| 4 | `canonical/skills/aid-execute/SKILL.md` | `## Project Management Sync (conditional)` | "update corresponding ticket to In Progress", "update ticket to Done", "add comment to ticket" |
| 5 | `canonical/skills/aid-deploy/references/state-packaging.md` | `### Step 8: Project Management Sync (conditional)` | "Create a Release in the PM tool", "mark as Done/Closed", "Link the release to the corresponding Epic" |
| 6 | `canonical/skills/aid-monitor/references/state-route.md` | `### Step 6: Update State` → the PM-tool block (`If PM tool configured (infrastructure.md § Project Management)`) | "Create tickets for BUG tasks", "Link to existing Sprint/Epic", + the ▶/✓ timing-hint scaffolding |

All six were re-verified against disk in `canonical/` (a tree grep of the guard + write signatures returned exactly these six sites, no more — see Testing).

### Migration Plan

**None — pure removal, no stored artifact changes.** No data to migrate, no schema version, no back-compat shim. Two points worth stating explicitly:

- **The `infrastructure.md § Project Management` branch guard is removed/neutralized at each site.** Because the site-level `If … defines a tool: …` conditional is deleted together with the write it guarded, no dormant code path survives: a project that *has* a PM tool configured in its `infrastructure.md` no longer fires any automated write. There is no toggle, no migration flag, and nothing to un-configure. feature-002 does **not** edit the `infrastructure.md` KB template itself — that template records *which* tracker a project uses (kept per FR-11/NFR-3) and carries **no literal `Project Management` heading** (the guard reference was always a soft by-role reference, not a hard heading link); re-framing the KB/discovery-guidance prose (FR-13) is feature-005's scope.
- **Backward compatibility (AC-10 / NFR-3).** A project with **no catalogued `issue-tracker` connector** must behave *identically to before* — the pre-change sites already ended in `If no PM tool → skip` (no output). The retirement preserves that exactly: the replacement suggestion is emitted **only when an `issue-tracker` connector is catalogued** in `.aid/connectors/` (§ Feature Flow step 3); with none catalogued, the site prints nothing — a true silent skip, so a no-tracker/no-`ticket_ref` project sees output byte-identical to pre-change (AC-10, NFR-3). The suggestion therefore appears **exactly for the projects the old automated write would have acted on** (a tracker is configured), now as an optional, user-initiated pointer instead of a silent write — satisfying the FR-7 mandate to leave a printed suggestion where an analog exists *without* adding any new output to a no-tracker project.

### Testing

These six edits are **prose changes to prompt-driven skill state machines**, which `test-landscape.md` classifies as **"Not machine-tested (by design) — dogfooding + human/AI review only"**. There is no machine-test suite to add; AC-7 is verified by **dogfooding + human/AI review**, with a mechanical zero-signature grep as a spot-check the reviewer/developer runs by hand (not a `run-all.sh` test):

1. **Per-site retirement check (all six) — human/AI review.** For each Layers-&-Components row, confirm the automated-write bullets are gone at the named anchor and that the disposition matches the Feature-Flow table — a conditional dedicated-skill suggestion is **present** where an analog exists (sites 1; 2-create; 4; 5-mark-Done; 6-create) and **absent** (removed outright) for the no-analog actions (site 3 whole section; site 2 link; site 5 Release-create + link-Epic; site 6 link + timing scaffolding).
2. **Zero-signature grep (mechanical spot-check).** A reviewer/developer greps `canonical/skills/{aid-describe,aid-detail,aid-plan,aid-execute,aid-deploy,aid-monitor}/` for the automated-write signatures and confirms zero hits. Illustrative (non-exhaustive, per AC-7) signatures: `create an Epic`, `create Tickets/Work Items`, `create Sprint/Iteration`, `Map deliveries to Sprints`, `update … ticket to In Progress`, `update ticket to Done`, `add comment to ticket`, `mark as Done/Closed`, `Create a Release in the PM tool`, `create tickets for BUG`, `Link … Epic`; plus the guard/scaffolding signatures `If infrastructure.md § Project Management defines a tool`, `If PM tool configured`, `If no PM tool → skip`, and the `▶/✓ PM tool ticket creation` lines.
3. **Suggestion-shape + conditionality check — human/AI review.** Each surviving suggestion (a) names the correct dedicated skill (`/aid-create-ticket` for create; `/aid-update-ticket status|comment` for update), (b) is optional / user-initiated (mirroring the `aid-report`/`aid-research` HANDOFF wording), (c) is **gated on a catalogued `issue-tracker` connector** — present when one is catalogued in `.aid/connectors/`, **silent (no output) when none** so a no-tracker project is byte-identical to pre-change (AC-10/NFR-3), and (d) carries **no** re-introduced `infrastructure.md § Project Management` guard.

Scope caveats (acknowledged reality): (a) the grep is scoped to the six FR-7 skill sites — the phrase "project management tooling" legitimately survives in the `infrastructure.md` KB template's `objective:`/`summary:` (recording *which* tracker, not a write) and in the discovery guidance until FR-13/feature-005 re-frames it; those are not write signatures. (b) The CONNECTORS-generation writes (aid-execute's auto status-mirror in `state-execute.md`; aid-plan Step 4c's new-ticket-filing half) are a **different signature class** handled by feature-003 and are **not** part of feature-002's zero-claim. (c) Byte/path-parity of the rendered copies is feature-005's gate.

### Boundaries (this feature only)

feature-002 touches **only** the six FR-7 PM-TOOL write sites above, and only in `canonical/`. It does **not**:

- reroute the CONNECTORS read seams, remove aid-execute's auto status-mirror, or split aid-plan Step 4c (FR-8/FR-9 — **feature-003**, a different signature class);
- revise `consumption-protocol.md` (FR-10 — **feature-004**);
- update the KB or discovery guidance (`document-expectations.md`, the `infrastructure.md` framing — FR-13) or run the generator to re-emit `profiles/*` and resync dogfood `.claude/` (FR-12 — **feature-005**);
- add, edit, or change the schema of any connector, template, or state file (FR-11 preserved untouched).

All edits are authored in `canonical/` (the single editable source); the `.claude/` + five `profiles/*` renders remain build output, re-rendered and gated by **feature-005**. This SPEC describes edits to make at Execute; it changes no skill file itself.
