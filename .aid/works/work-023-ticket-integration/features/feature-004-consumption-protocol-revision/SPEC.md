# Consumption-Protocol Revision & Traceability Preservation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Feature identified from REQUIREMENTS.md §5 FR-10, FR-11; §4 | /aid-define |
| 2026-07-22 | Technical Specification authored | /aid-specify |
| 2026-07-22 | Review cycle-1 FIX: nearest-ancestor reframed as consumer-less inheritance/traceability (E4↔E6 reconciled); worked example made id-based per feature-001 grammar | /aid-specify (review-fix) |

## Source

- REQUIREMENTS.md §5 FR-10, FR-11; §4 Scope

## Description

Revise the shared `consumption-protocol.md` reference so it matches the new single-surface model
while keeping the internal traceability intact. The automated capabilities — filing a ticket,
mirroring a status transition, and posting a comment — are removed from the wired-seams model.
What remains is the `ticket_ref` multi-level linkage and its nearest-ancestor resolution, kept as a
local-link mechanism. The protocol is restated so that reads may be delegated by any seam through
`/aid-read-ticket` and all writes flow through the dedicated ticket skills. Internal `ticket_ref`
traceability is preserved and is only ever populated from a ref the user supplied — never
auto-created or auto-discovered — and the state and spec templates that carry `ticket_ref` are left
unchanged, so a project with no `ticket_ref` and no connector behaves exactly as it did before.

## User Stories

- As an AID methodology maintainer, I want the consumption protocol to describe only reads-via-the-
  read-skill and writes-via-the-dedicated-skills so that the shared reference matches the retired
  and rerouted seams.
- As an AID adopter/developer, I want `ticket_ref` links to keep working from the refs I supply so
  that traceability between AID work and tracker items is preserved without any silent auto-linking.
- As a project lead/PM, I want a project with no connector and no `ticket_ref` to behave identically
  to before so that adopting nothing tracker-related changes nothing.

## Priority

Must

## Acceptance Criteria

- [ ] Given the change is complete, when a project carries no `ticket_ref` and no connector, then
  its behavior is identical to before (silent skip), and `ticket_ref` local traceability is
  preserved and only ever populated from a user-supplied ref.
- [ ] Given `consumption-protocol.md` is revised, when it is reviewed, then no automated
  file/mirror/comment seam remains, the `ticket_ref` linkage and nearest-ancestor resolution are
  retained, and reads are documented to delegate to `/aid-read-ticket` while writes go via the
  dedicated skills.

---

## Technical Specification

> Grounded in `architecture.md` ("Load-Bearing Boundaries" — the connectors registry is a
> **CATALOG, not a connection manager**; the `canonical/` → `profiles/` render boundary),
> `authoring-conventions.md` ("Citation Rule (Durable Anchors)"; "Signature Exception" P1(d)-SIG;
> "Content Isolation"), the artifact under revision
> `canonical/aid/templates/connectors/consumption-protocol.md`, and the four LOCAL-LINK carriers it
> references (`work-state-template.md`, `delivery-state-template.md`, `task-state-template.md`,
> `specs/spec-template.md`). This feature edits **exactly one** `canonical/` file — the shared
> consumption reference — and changes **no** state/spec template, **no** seam file, and **no** KB
> doc; rendering the edit to the five profiles + the dogfood `.claude/` resync is feature-005. All
> edits are authored in `canonical/` (the single editable source). Citations use durable anchors
> (heading + grep-recoverable lead string); FR-10 records the three write-seam sites as
> `:48` / `:134` / `:160-163` as-of-authoring, but those line numbers drift on the next edit above
> them, so the edits below are keyed to durable anchors, not lines.

### Data Model

**No schema change. The `ticket_ref` LOCAL-LINK is preserved unchanged (FR-11) — this is the firm
invariant of the whole feature.** The scalar, its `<connector-stem>:<external-id>` grammar, its
multi-level linkage, and its nearest-ancestor inheritance semantics all survive the revision intact;
the only thing removed is that rule's former automated outward-write consumer — `aid-execute`'s
status-mirror (Feature Flow, E4/E5/E7). Post-revision the rule has **no automated outward-writing
caller**; it is retained as the link's inheritance/traceability semantics for readers (and available
should a future feature add a consumer).

- The scalar's definition and level table stay as authored in `consumption-protocol.md`
  "## Multi-level `ticket_ref` linkage" (lead: "A `ticket_ref` scalar links **one lifecycle unit**
  to **one external tracker item**") — **unedited**. It remains a lifecycle-unit field only; the
  connector-descriptor schema (`name`/`connection_type`/`endpoint`/`auth_method`/
  `secret_reference`/`preset`/routing) is untouched, as that section already states.
- The resolution rule in `consumption-protocol.md` "## Nearest-ancestor resolution" — the
  containment chains table (`delivery → work`; `feature → work`;
  `task → owning feature → delivery → work`), the "Why feature outranks delivery for a task"
  rationale, the "'Owning feature' — SPEC-traced" paragraph, and the "Terminal case" silent-skip —
  is **retained verbatim** except its one-sentence framing opener (E4).

**The four templates that carry `ticket_ref` are NOT touched by this feature** (FR-11). Firm
invariant, with the exact carrier + durable anchor in each:

| Template (`canonical/aid/templates/…`) | `ticket_ref` carrier (durable anchor) | Status |
|---|---|---|
| `work-state-template.md` | frontmatter `ticket_ref:` key + the body note "Optional `ticket_ref` scalar (frontmatter, top-level, both layouts)" | unchanged |
| `delivery-state-template.md` | frontmatter `ticket_ref:` key + the body note "Optional `ticket_ref` (frontmatter): links this delivery" | unchanged |
| `task-state-template.md` | frontmatter `ticket_ref:` key + the body note "Optional `ticket_ref` (frontmatter, full-path only)" | unchanged |
| `specs/spec-template.md` | the SPEC body line "> **Ticket:** {connector-stem}:{external-id}" + its `<!-- OPTIONAL ticket_ref -->` comment | unchanged |

Each of those four notes already points readers to `consumption-protocol.md` for the
nearest-ancestor + MCP-first contract; because that contract's *linkage/resolution* half is
preserved, the templates' pointers stay accurate with no template edit. (The templates keep citing
`consumption-protocol.md` by path — a durable pointer, not a line — so the revision does not break
them.)

### Feature Flow

The revision is a **bounded, enumerated set of in-place edits** to `consumption-protocol.md`. FR-10
cites three write-seam anchors; the fix-everywhere sweep covers the **complete class** of
"a wired seam itself reads-or-writes the tracker" prose (four further sites), so the revised doc is
internally consistent — not just the three cited lines patched. Seven edits, E1–E7:

**E1 — Intro blockquote: retire the "mirror is additive-on-top" framing.**
Anchor: the opening blockquote clause "Every seam listed in 'Wired seams' below implements this
protocol by a **short, additive pointer** to this file … and none of them are restructured to adopt
it (existing behavior is preserved; this is new, optional behavior layered on top)." Keep the
"short, additive pointer" model; **replace** the parenthetical write-implying clause with the new
single-surface model: a wired seam consumes a catalogued connector for **reads only**, delegating
the read to `/aid-read-ticket`, and **never** files, comments on, or transitions a ticket — every
outward write flows through the dedicated `/aid-create-ticket` / `/aid-update-ticket` skills
(feature-001).

**E2 — Seam recipe Step 1: drop "filing" from the purpose example.**
Anchor: "## The seam recipe (generic shape)" Step 1, lead "Scan the catalog", phrase
"an issue-tracker connector when the seam is **reading or filing** a ticket". Change to
"…when the seam is **reading** a ticket" — the generic recipe is a read path; filing is the
`/aid-create-ticket` skill's job, not a seam's.

**E3 — Seam recipe Step 4: restate the WRITE line as read-only (FR-10 `:48`).**
Anchor: "## The seam recipe (generic shape)" Step 4, lead "**Act, then stop.**" — current text
"Read or write through the host MCP only for the one operation the seam needs (read a ticket's
fields; file a new ticket; post a status/comment)." **Replace** with a read-only step (rename lead
to "**Read, then stop.**"): a seam reads through the host MCP only, and **delegates that read to
`/aid-read-ticket`** rather than re-implementing a fetch; it never files, comments on, or
transitions a ticket — every outward write flows through `/aid-create-ticket` /
`/aid-update-ticket` (feature-001). **Keep** the trailing sentence unchanged ("Never persist
anything host-MCP-specific back into `.aid/connectors/` — the descriptor and `INDEX.md` are catalog
metadata, not a cache of live tool state.").

**E4 — Nearest-ancestor resolution: reframe the opener as consumer-less inheritance semantics.**
Anchor: "## Nearest-ancestor resolution" opening sentence "A **target seam** (one that **acts** on
a unit, e.g. `aid-execute` acting on a task) resolves the **nearest** `ticket_ref` by AID
containment …". **Replace only that opening sentence** with an inheritance-semantics framing that
names no caller: "Nearest-ancestor resolution is the **inheritance/traceability semantics** of the
link — a lifecycle unit without its own `ticket_ref` inherits the **nearest** ancestor's effective
ref by AID containment (`work ⊃ delivery ⊃ task`, `work ⊃ feature`; a delivery groups ≥1 feature)."
Everything after it (the "A unit uses its **own** `ticket_ref` when present; otherwise it inherits,
per unit type:" lead-in, the chains table, the "Why feature outranks delivery" rationale, the
SPEC-traced-owning-feature paragraph, the terminal silent-skip case) is **unchanged** — the
mechanism is preserved verbatim (FR-11). **Honest outcome:** the rule's *only* former automated
consumer was `aid-execute`'s status-mirror, now removed (FR-9), so **post-revision it has no
automated outward-writing caller**; it is retained purely as the link's inheritance semantics for
readers/traceability (and available should a future feature add a consumer). The enrich seams do
**not** resolve nearest-ancestor — they take an explicit ref and resolve/record nothing of their own
(this makes E4 agree with E6 and the pre-revision baseline, where only the removed `aid-execute`
Target row ever resolved).

**E5 — Wired seams table: delete the `aid-execute` Target row; delegate the read rows (FR-10 `:134`).**
Anchor: "## Wired seams" table.
- **Delete** the row `| aid-execute | Target | … mirrors this task's STATE.md/### Tasks lifecycle
  State transitions … to that ticket via the host MCP … |` in full — the automatic status-mirror is
  retired (FR-9). "Target" ceases to be a role in this doc; only **Ingest** and **Enrich** remain.
- **Ingest rows keep their record-`ticket_ref` (LOCAL-LINK) role** but have their read verb
  delegated: `aid-describe` ("read it via a catalogued issue-tracker MCP connector and record
  `ticket_ref` at the **work** level") → "read it **via `/aid-read-ticket`** and record `ticket_ref`
  at the **work** level"; `aid-specify` ("read it via a catalogued MCP connector and record
  `ticket_ref` at the **feature** level") → "read it **via `/aid-read-ticket`** and record …". The
  `aid-plan` and `aid-fix` ingest rows (record-only, no explicit fetch verb) keep their
  record-`ticket_ref` role unchanged (their read half, where present, is rerouted by feature-003).
- **Enrich rows delegate the read** to `/aid-read-ticket` instead of naming a direct host-MCP call:
  `aid-query-kb` ("May consult a catalogued MCP connector to enrich an answer …") →
  "May enrich an answer by reading a linked ticket's status/fields **via `/aid-read-ticket`** …";
  `aid-researcher` and `aid-developer` ("… use the host tool's MCP to gather/pull …") → "… gather
  additional evidence / pull additional context by reading the linked ticket **via
  `/aid-read-ticket`** …" (still read-only enrichment, never a substitute for the TASK file).

**E6 — "Ingest vs. target, restated." paragraph: retitle and drop the target/mirror concept.**
Anchor: the bold lead "**Ingest vs. target, restated.**" (phrase "resolves + acts on whatever
`ticket_ref` is nearest, mirroring state it is producing back out to that ticket"). Retitle to
"**Ingest vs. enrich, restated.**" and rewrite: an **ingest** seam runs early
(Describe/Specify/Plan/the shortcut engine's INTAKE) and *records* a `ticket_ref` at the level it is
creating, sourced from a **user-supplied ref** to an already-existing external ticket, delegating
any read to `/aid-read-ticket`; `aid-query-kb` / `aid-researcher` / `aid-developer` *enrich* an
answer or investigation from a connector's live data **via `/aid-read-ticket`**, without recording
or resolving a `ticket_ref` of their own. **No seam performs an outward write** — filing,
commenting, and status transitions are the dedicated skills' job.

**E7 — Worked example: replace the mirror walkthrough with an id-based inheritance one (FR-10 `:160-163`).**
Anchor: "## Worked example (AC9)". **Retitle** to "## Worked example (nearest-ancestor
resolution)" — the "(AC9)" tag referenced the originating connectors work's acceptance criteria, not
work-023's, and goes stale once the mirror it demonstrated is removed (reality acknowledged).
**Replace** the five-step `aid-execute` status-mirror walkthrough with one that demonstrates the
**inheritance rule** over the same data (task with no own `ticket_ref`; owning SPEC-traced feature
carries `jira:PROJ-45`; a `jira` connector catalogued `connection_type: mcp`): by nearest-ancestor
the task's **effective** `ticket_ref` resolves to `jira:PROJ-45` (task own absent → owning feature →
stop) — the traceability link a reader/dashboard shows for the task. **No automated caller acts on
it** (the former `aid-execute` mirror is removed); when someone wants that ticket's live fields they
run the **id-based** `/aid-read-ticket jira:PROJ-45` (feature-001's locked grammar
`[<connector>:]<ticket-id>` — there is **no** unit-scoped invocation mode), which scans `INDEX.md`
→ jira row Type `mcp` → confirms `connection_type: mcp` → fetches and displays. **No outward write
occurs** — no status is mirrored and no comment is posted; a change would be a user-initiated
`/aid-update-ticket`. If every level in the chain were absent, resolution yields no effective ticket
(terminal case) and there is nothing to read.

Edits E3, E5, E7 discharge FR-10's three cited anchors; E1, E2, E4, E6 are the internal-consistency
sweep that makes "no seam writes / all reads delegate" hold across the whole document rather than at
three points only (fix-everywhere).

### API Contracts

The revised `consumption-protocol.md` MUST assert three load-bearing contracts **inline**
(P1(d)-SIG — an agent reads this doc to decide what a seam may do; the rules cannot be deferred to a
bare pointer):

1. **Read-delegation contract.** A wired seam (ingest or enrich) that needs a tracker item's fields
   **delegates the read to `/aid-read-ticket`**; no seam re-implements a direct host-MCP fetch. The
   read is authorized by an **explicit, user-supplied ref** (`[<connector>:]<ticket-id>` —
   feature-001's grammar); the seam does not resolve a ref of its own. Reads are non-destructive, so
   no seam-level confirm is required.
2. **Write-routing contract.** **No wired seam performs an outward write.** Filing a ticket,
   appending a comment, and setting a status flow **only** through the dedicated `/aid-create-ticket`
   and `/aid-update-ticket` skills (feature-001), each of which previews-and-confirms before writing.
   There is no automated file / mirror / comment path anywhere in this protocol.
3. **LOCAL-LINK contract.** `ticket_ref` is a local traceability link, populated **only from a
   user-supplied ref — never auto-created or auto-discovered**. Its multi-level linkage is
   **inheritable** per the nearest-ancestor rule (a unit without its own ref inherits its nearest
   ancestor's effective ref) — retained as the link's inheritance/traceability semantics, with **no
   automated outward-writing caller post-revision** (the former `aid-execute` mirror is removed). A
   work with no `ticket_ref` and no catalogued connector is a silent no-op at every seam — the seam
   recipe skips at Step 1/Step 2 exactly as before (backward compatibility, AC-10).

The MCP-first scope and the `api`/`ssh`/`cli`-out-of-scope note in the doc's header blockquote are
**unchanged** — this feature narrows the *operations* a seam may perform (read-only), not the
*connection model* (still tool-managed `mcp` only; aid-managed live consumption stays the deferred
follow-up).

### Layers & Components

Single edited file, everything else explicitly not-changed:

| Artifact | Change | Owner |
|---|---|---|
| `canonical/aid/templates/connectors/consumption-protocol.md` | E1–E7 (this feature) | **feature-004** |
| `work-state-template.md`, `delivery-state-template.md`, `task-state-template.md`, `specs/spec-template.md` | **not changed** (FR-11 invariant) | — |
| The seam files themselves (`aid-execute` mirror removal, read-seam reroutes, comment-write reroutes) | **not changed here** | feature-003 |
| KB project-management guidance + discovery guidance + render/propagation to `profiles/*` + dogfood resync | **not changed here** | feature-005 |

There is no schema, no script, and no runtime component in scope — the deliverable is prose edits to
one shared reference doc. The doc remains a `canonical/` artifact that ships byte-identically into
every profile's install tree; feature-005 performs that render (its byte/path-parity gate, not this
feature's).

### Testing

Doc-level / structural checks — there is no host MCP or live tracker to call, and the deliverable is
a reference doc.

**AC-11 — the revision itself:**
- **No automated file/mirror/comment seam remains.** `grep -i mirror consumption-protocol.md` → **0
  hits**; the `aid-execute` Target row is absent (grep for "| `aid-execute` |" → 0); the phrase
  "Read or write through the host MCP" is gone; the "## Worked example" section describes a read, not
  a status mirror. Every remaining file/comment/status mention names a **dedicated skill**
  (`/aid-create-ticket` / `/aid-update-ticket`), never a seam.
- **`ticket_ref` linkage + nearest-ancestor semantics retained.** "## Multi-level `ticket_ref`
  linkage" and "## Nearest-ancestor resolution" are still present; the containment chains table and
  the "Why feature outranks delivery" rationale are byte-identical to before (only E4's opener
  reframed to consumer-less inheritance semantics — no seam resolves nearest-ancestor, matching E6).
- **Reads delegate; writes route.** The doc states, inline, that seam reads delegate to
  `/aid-read-ticket` (recipe Step 4 + every ingest/enrich row + the "Ingest vs. enrich" paragraph)
  and that all writes go via the dedicated skills (intro + Step 4 + API Contracts).

**AC-10 — backward compatibility + no auto-linking:**
- A work with **no `ticket_ref` and no catalogued connector** behaves identically to before: the
  recipe's Step 1/Step 2 "skip silently" path is preserved, so every seam is a no-op — no error, no
  prompt, no output; the "Terminal case" (no ancestor carries a ref → no effective ticket) is
  likewise preserved as inheritance semantics.
- The doc asserts `ticket_ref` is populated **only from a user-supplied ref**, never auto-created or
  auto-discovered (LOCAL-LINK contract) — confirmable by grep for the "user-supplied" invariant in
  the ingest description and the API Contracts.

Byte/path parity of the rendered profile copies and the dogfood `.claude/` resync are **feature-005's
gate**, not duplicated here.

### Boundaries (this feature only)

feature-004 edits **only** `canonical/aid/templates/connectors/consumption-protocol.md` (E1–E7). It
does **not**:

- edit any seam file — removing the `aid-execute` mirror, rerouting the read seams through
  `/aid-read-ticket`, and rerouting the human-gated comment writes are **feature-003**
  (connector-seam consolidation); this feature only makes the shared reference *describe* the model
  those edits produce, and therefore **depends on feature-001** (the dedicated skills must exist to
  be referenced) and **coordinates with feature-003** (the doc must match the seams' new behavior);
- change any of the four `ticket_ref`-carrying templates (FR-11 invariant — Data Model);
- touch the KB project-management guidance, the discovery guidance, or run the render/propagation to
  `profiles/*` + the dogfood resync — those are **feature-005**;
- alter the connection model: MCP-first stays; live consumption of `api`/`ssh`/`cli` connectors
  remains the deferred follow-up already noted in the doc's header (out of scope, unchanged).
