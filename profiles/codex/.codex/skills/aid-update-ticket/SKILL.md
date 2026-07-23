---
name: aid-update-ticket
description: >
  On-demand write skill that mutates exactly ONE named part of an existing ticket in whatever
  issue-tracker connector resolves for it: `aid-update-ticket <part> [<connector>:]<ticket-id>
  <content>` where `part` is the closed enum `description | comment | status`. `description`
  REPLACES the field, `comment` APPENDS a new comment, `status` SETS the ticket's state.
  Resolves the connector via the shared ticket-resolution ladder, loads whatever context the
  named part needs (status: the ticket's available transitions; description: its current value
  for a before/after preview; comment: nothing), composes the exact mutation, and shows it in an
  in-invocation `AskUserQuestion` confirm before the single host-MCP write. A `status` target is
  validated against the tracker's available transitions when the MCP can enumerate them (a
  mismatch lists the valid options and stops before the confirm gate); when transitions cannot be
  enumerated, the transition is attempted and the tracker's own error is surfaced verbatim on
  rejection. Never writes silently, and an MCP failure never leaves a partial write.
allowed-tools: Read, Glob, Grep, AskUserQuestion
argument-hint: "<part> [<connector>:]<ticket-id> <content>"
---

# Update Ticket

`aid-update-ticket <part> [<connector>:]<ticket-id> <content>` mutates **one** named part of an
existing ticket in whatever issue-tracker connector resolves for it — `description` (REPLACE),
`comment` (APPEND), or `status` (SET) — after showing the user the exact change and waiting for
explicit confirmation. It is the third of the three peer ticket-tracker skills alongside
`aid-read-ticket` (fetch/display, non-destructive) and `aid-create-ticket` (file a new ticket).

**Absent from the mandatory pipeline flow.** Like `aid-query-kb` and `aid-set-connector`, this is
an optional, on-demand utility skill — no phase gate references it, no `shortcut-catalog.yml`
entry, no `work-NNN` scaffold, no per-skill `STATE.md`; it is invoked directly by name
(`features/feature-001-dedicated-ticket-skills/SPEC.md` § Layers & Components, decision 2).

**Shared reference — implemented here, not restated.** The connector-resolution ladder, this
skill's own grammar row, and the write preview/confirm-gate convention all live once in
[`.codex/aid/templates/connectors/ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md)
(the same DRY home `aid-read-ticket` and `aid-create-ticket` point to). This file never
re-describes the ladder or the generic confirm convention inline — it only spells out the parts of
the contract that are specific to *this* skill: the `description | comment | status` mutation
semantics, per-part `LOAD-CONTEXT`, and `status` transition validation.

**No repo write, ever.** `allowed-tools` carries no `Write`/`Edit` — this skill persists nothing
locally. The only write it ever performs is the single host-MCP mutation call at `WRITE`, and only
after an explicit confirm.

---

## Pre-flight

- Confirm the invocation shape before anything else. Fewer than three whitespace-separated
  pieces (missing `<part>`, missing the ref, or no `<content>` after it) → print the usage line
  and exit (`ticket-resolution.md` § "Grammar-Parse Conventions" — the `aid-query-kb` pre-flight
  pattern):
  ```
  Usage: aid-update-ticket <part> [<connector>:]<ticket-id> <content>
  Example: aid-update-ticket status jira:PROJ-9 "In Progress"
  ```
- `<part>` MUST be one of the **closed enum** `description | comment | status`. Anything else —
  a typo, a synonym, an unsupported word — is **rejected with the same usage line above**, never
  coerced and never guessed at. This check runs before any connector resolution or MCP call.

---

## States

### State 1 — PARSE-ARGS

Parse per `ticket-resolution.md` § "Grammar-Parse Conventions" (the `aid-update-ticket` row): the
first whitespace token is `<part>` (closed enum, already validated at Pre-flight); the second
token is the ref, still in its raw `[<connector>:]<ticket-id>` shape; **everything after that is
`<content>`**, taken **verbatim** — it may itself contain spaces or colons, and is **never
re-parsed** for flags or further structure.

Hold three values across the remaining states: **PART** (the validated enum value), **REF** (the
raw ref token, colon-split by RESOLVE-CONNECTOR below), and **CONTENT** (the untouched free-text
remainder).

### State 2 — RESOLVE-CONNECTOR

Apply `ticket-resolution.md` § "Connector-Resolution Ladder" to **REF**, exactly as it shares
between read and update: **REF** contains a `:` → split on the **first** `:` (the stem selects the
connector; the remainder is the external ticket id); else the whole token is the external id and
the connector comes from the ladder (explicit override → exactly-one-silent → two-or-more-ask →
host tool's own MCP → the `"no issue-tracker connector found."` notify + exit). This skill does not
restate the four-step ladder or the `api`/`ssh`/`cli` fall-through note — see the shared reference
for the full procedure.

### State 3 — LOAD-CONTEXT

No write happens in this state; what gets fetched depends entirely on **PART**:

| PART | LOAD-CONTEXT fetch |
|---|---|
| `status` | The ticket's **available transitions** from its current state, via the host MCP — feeds the Status Validation step in COMPOSE below. |
| `description` | The ticket's **current** description value, via the host MCP — feeds the before/after preview in COMPOSE below. |
| `comment` | Nothing. An append needs no prior read. |

A not-found / unauthorized / unavailable host-MCP call at this state is the general MCP-failure
policy below: surface the tracker's error verbatim and exit non-destructively — the run never
reaches COMPOSE/CONFIRM/WRITE for that attempt.

**A failed fetch is not the same thing as "this tracker can't enumerate transitions."** For
`status`, the host MCP explicitly reporting that transition-enumeration is unsupported (a
capability gap, not an error) is a *different*, expected outcome — see Status Validation below,
which is the only place that distinction matters.

### State 4 — COMPOSE

Build the payload that CONFIRM will preview and WRITE will send. COMPOSE never assembles a
mutation for either of the other two parts:

- **`description` → REPLACES.** The new value is **CONTENT** verbatim. The preview pairs
  LOAD-CONTEXT's fetched current value (**before**) against **CONTENT** (**after**).
- **`comment` → APPENDS.** The payload is one new comment whose body is **CONTENT** verbatim —
  nothing existing is read, replaced, or removed.
- **`status` → SETS.** The target state is **CONTENT** verbatim (e.g. `"In Progress"`, `"Done"`).
  Validate before previewing — see Status Validation immediately below.

#### Status Validation (`features/feature-001-dedicated-ticket-skills/SPEC.md` § Security Specs, decision 4)

1. LOAD-CONTEXT returned an enumerable transitions list → compare **CONTENT** against it.
   - **Match** → COMPOSE proceeds; CONFIRM will preview the validated target transition.
   - **No match** → **list the valid targets and stop.** The run ends here — CONFIRM is **never
     reached** for this attempt; no confirm question is even asked.
2. The host MCP could not enumerate transitions for this tracker (a capability gap, not an error)
   → **graceful fallback**: proceed to CONFIRM with **CONTENT** shown as the requested,
   **unvalidated** target, then attempt the transition at WRITE. If the tracker itself rejects it,
   surface **its own error verbatim** at that point — this is the one path where a rejection can
   surface only after the confirm, because there was no earlier read to validate against.

### State 5 — CONFIRM

A single in-invocation confirm, asked and answered inline before WRITE — the skill never exits
mid-run to collect this answer (`ticket-resolution.md` § "Write Preview + Confirm Gate";
[`state-machine-chaining.md`](../../aid/templates/state-machine-chaining.md) § "The four advance
types" — a transition whose user interaction is fully `AskUserQuestion`-based is CHAIN). Show the
**exact** change for whichever PART is being mutated:

- **`description`** → the before/after pair from COMPOSE.
- **`comment`** → the exact text being appended.
- **`status`** → the target transition — either validated (Status Validation branch 1) or
  explicitly flagged as an unvalidated attempt (branch 2), so the user always knows which case
  they are confirming.

Close with the shared reference's confirm-gate button row, reused **verbatim**
(`ticket-resolution.md` § "Write Preview + Confirm Gate"):

```
[1] File it · [2] Edit · [3] Cancel
```

- **`[1] File it`** → proceed to WRITE.
- **`[2] Edit`** → collect a revised **CONTENT** for the same **PART**/**REF** and re-run
  COMPOSE → Status Validation (if applicable) → CONFIRM against it — still inline, still CHAIN.
- **`[3] Cancel`** → exit. No MCP call is made.

### State 6 — WRITE

Only after an explicit `[1] File it` — perform the single mutation call through the connector
resolved at RESOLVE-CONNECTOR, per
[`consumption-protocol.md`](../../aid/templates/connectors/consumption-protocol.md)'s MCP-first
recipe: request the connection from the host tool's own MCP/plugin; AID resolves no credential and
stores none. One call, matching PART's semantics (replace the description / add the comment /
apply the transition). On success, confirm the change to the user (the field now set, the comment
posted, or the new state).

**MCP-failure policy (general, all parts).** A failed / not-found / unauthorized / unavailable
WRITE call surfaces the tracker's error verbatim and exits **non-destructively** — no partial
write (`features/feature-001-dedicated-ticket-skills/SPEC.md` § Feature Flow, "MCP-call failure
policy"). This is distinct from — and, for
`status`, can only be reached *after* — the Status Validation branch above, which can already have
stopped the run before CONFIRM was ever asked.

---

## Worked examples

- **Comment append.** `/aid-update-ticket comment jira:PROJ-9 "Retested on staging, still
  reproduces."` → PARSE-ARGS: PART=`comment`, REF=`jira:PROJ-9`, CONTENT=`"Retested on staging,
  still reproduces."` → RESOLVE-CONNECTOR: explicit `jira:` stem, validated `issue-tracker` →
  LOAD-CONTEXT: none (comment needs no read) → COMPOSE: append payload = CONTENT → CONFIRM shows
  the exact comment text + `[1] File it · [2] Edit · [3] Cancel` → confirmed → WRITE posts the
  comment.
- **Description replace.** `/aid-update-ticket description PROJ-12 "Pagination now uses
  cursor-based paging; see PROJ-9 for the root cause."` with exactly one catalogued
  `issue-tracker` connector → RESOLVE-CONNECTOR: no `:` prefix → ladder scan finds the one match,
  used silently → LOAD-CONTEXT fetches the current description → COMPOSE pairs it against the new
  text → CONFIRM shows the before/after → confirmed → WRITE replaces the description field.
- **Status, valid transition.** `/aid-update-ticket status jira:PROJ-9 "In Progress"` →
  LOAD-CONTEXT fetches PROJ-9's available transitions, which include `In Progress` → COMPOSE
  validates the match → CONFIRM previews the validated transition → confirmed → WRITE applies it.
- **Status, invalid transition** (`ticket-resolution.md`'s own worked example). `/aid-update-ticket
  status jira:PROJ-9 "Done"` where PROJ-9's current state has no direct transition to `Done` →
  LOAD-CONTEXT's transitions list does not include `Done` → the valid options are listed and the
  run stops **before** the confirm gate is ever reached.
- **Status, tracker can't enumerate transitions.** `/aid-update-ticket status linear:LIN-4 "Done"`
  against a connector whose MCP surface has no transitions-list capability → LOAD-CONTEXT reports
  "not enumerable" (not an error) → COMPOSE takes the graceful-fallback branch → CONFIRM previews
  `"Done"` as an unvalidated, attempted target → confirmed → WRITE attempts it; if the tracker
  rejects it, its own error is surfaced verbatim at that point — never before.
- **Reject: bad part.** `/aid-update-ticket close jira:PROJ-9 "wontfix"` → `close` is not in
  `{description, comment, status}` → Pre-flight prints the usage line and exits; nothing is parsed
  further, no connector is resolved, no MCP call is ever made.

---

## Write-zone

This skill makes exactly **one** external write per invocation — the single host-MCP mutation call
at WRITE, and only after an explicit CONFIRM. It writes **nothing** to the repo: no `Write`/`Edit`
tool is declared; `.aid/connectors/` is only ever read (`Read`/`Glob`/`Grep`, to resolve the
connector via `INDEX.md` and the matched descriptor's `tags:`); no local file, cache, or `STATE.md`
is ever touched.

---

## Constraints

- **Closed `part` enum.** `description | comment | status` only — anything else is rejected with
  the usage line at Pre-flight, before any connector resolution or MCP call.
- **Content is never re-parsed.** Once `<part>` and the ref are consumed, the entire remainder is
  CONTENT verbatim — it may contain spaces or colons; no flag-like or connector-like substring
  inside it is ever extracted back out.
- **Only the named part is mutated.** `description` REPLACES, `comment` APPENDS, `status` SETS —
  COMPOSE never touches either of the other two parts of the ticket.
- **No silent write.** CONFIRM is mandatory for all three parts; WRITE never runs without an
  explicit `[1] File it`.
- **Status is validated when it can be.** A `status` target is checked against the tracker's
  available transitions whenever the MCP can enumerate them; a mismatch stops the run before
  CONFIRM. When transitions cannot be enumerated, the attempt proceeds and any rejection is
  surfaced verbatim — never silently swallowed, never silently retried.
- **Non-destructive failure.** Any MCP error (at RESOLVE-CONNECTOR, LOAD-CONTEXT, or WRITE)
  surfaces the tracker's message verbatim and exits without a partial write.
- **No repo writes.** `Write`/`Edit` are absent from `allowed-tools`; this skill persists nothing
  locally.
