---
name: aid-update-ticket
description: >
  Change exactly one part of an existing ticket in the project's issue tracker. Use this
  skill when a ticket needs its description replaced, a comment added, its status moved, or
  files attached: `part` is the closed enum `description | comment | status | attachment`, and
  one invocation touches one of them. It resolves which tracker owns the ticket, loads whatever
  the named part needs, composes the exact mutation, and shows it to you for confirmation before
  the single write. A status target is checked against the tracker's available transitions when
  those can be listed, and a mismatch stops before the confirmation gate. An attachment is
  previewed file by file before the confirmation gate, and a tracker that cannot hold it stops
  the run with the workable options. It never writes silently, and a failed write never leaves a
  partial one.
allowed-tools: Read Glob Grep AskUserQuestion
argument-hint: "<description | comment | status | attachment> [<connector>:]<ticket-id> <content>"
---

# Update Ticket

`aid-update-ticket <part> [<connector>:]<ticket-id> <content>` mutates **one** named part of an
existing ticket in whatever issue-tracker connector resolves for it — `description` (REPLACE),
`comment` (APPEND), `status` (SET), or `attachment` (ATTACH the files the user picks) — after
showing the user the exact change and waiting for explicit confirmation. It is the third of the
three peer ticket-tracker skills alongside `aid-read-ticket` (fetch/display, non-destructive) and
`aid-create-ticket` (file a new ticket).

**Absent from the mandatory pipeline flow.** Like `aid-ask` and `aid-set-connector`, this is
an optional, on-demand utility skill — no phase gate references it, no `shortcut-catalog.yml`
entry, no `work-NNN` scaffold, no per-skill `STATE.yml`; it is invoked directly by name.

**Shared reference — implemented here, not restated.** The connector-resolution ladder, this
skill's own grammar row, and the write preview/confirm-gate convention all live once in
[`.aid/runtime/templates/connectors/ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md)
(the same DRY home `aid-read-ticket` and `aid-create-ticket` point to). This file never
re-describes the ladder or the generic confirm convention inline — it only spells out the parts of
the contract that are specific to *this* skill: the `description | comment | status | attachment`
mutation semantics, per-part `LOAD-CONTEXT`, `status` transition validation, and the attachment
tool-limit stop.

**No repo write, ever.** `allowed-tools` carries no `Write`/`Edit` — this skill persists nothing
locally. The only write it ever performs is the single host-MCP mutation call at `WRITE`, and only
after an explicit confirm. An attached file is read here for its preview; it is never copied.

---

## Pre-flight

- Confirm the invocation shape before anything else. Fewer than three whitespace-separated
  pieces (missing `<part>`, missing the ref, or no `<content>` after it) → print the usage line
  and exit (`ticket-resolution.md` § "Grammar-Parse Conventions" — the `aid-ask` pre-flight
  pattern):
  ```
  Usage: aid-update-ticket <description | comment | status | attachment> [<connector>:]<ticket-id> <content>
  Example: aid-update-ticket status jira:PROJ-9 "In Progress"
  ```
- `<part>` MUST be one of the **closed enum** `description | comment | status | attachment`. Anything
  else — a typo, a synonym, an unsupported word — is **rejected with the same usage line above**,
  never coerced and never guessed at. This check runs before any connector resolution or MCP call.

---

## States

### State 1 — PARSE-ARGS

Parse per `ticket-resolution.md` § "Grammar-Parse Conventions" (the `aid-update-ticket` row): the
first whitespace token is `<part>` (closed enum, already validated at Pre-flight); the second
token is the ref, still in its raw `[<connector>:]<ticket-id>` shape; **everything after that is
`<content>`**, taken **verbatim** — it may itself contain spaces or colons, and is **never
re-parsed** for flags or further structure. For `attachment`, CONTENT is the list of files the
user picks (repo-relative paths, separated by spaces or commas); it is split only at LOAD-CONTEXT.

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
| `attachment` | Each file named in CONTENT, read through `Read` for its **preview**: the file name, its size, and its first lines. A file that does not exist, or a CONTENT that names no file, stops the run before COMPOSE: the skill names what is missing and asks which files the user means (`AskUserQuestion`), with a recommendation and a free-text answer allowed, never guessing a path. |

A not-found / unauthorized / unavailable host-MCP call at this state is the general MCP-failure
policy below: surface the tracker's error verbatim and exit non-destructively — the run never
reaches COMPOSE/CONFIRM/WRITE for that attempt.

**A failed fetch is not the same thing as "this tracker can't enumerate transitions."** For
`status`, the host MCP explicitly reporting that transition-enumeration is unsupported (a
capability gap, not an error) is a *different*, expected outcome — see Status Validation below,
which is the only place that distinction matters.

### State 4 — COMPOSE

Build the payload that CONFIRM will preview and WRITE will send. COMPOSE never assembles a
mutation for any other part:

- **`description` → REPLACES.** The new value is **CONTENT** verbatim. The preview pairs
  LOAD-CONTEXT's fetched current value (**before**) against **CONTENT** (**after**).
- **`comment` → APPENDS.** The payload is one new comment whose body is **CONTENT** verbatim —
  nothing existing is read, replaced, or removed.
- **`status` → SETS.** The target state is **CONTENT** verbatim (e.g. `"In Progress"`, `"Done"`).
  Validate before previewing — see Status Validation immediately below.
- **`attachment` → ATTACHES.** The payload is the list of files LOAD-CONTEXT previewed, added to
  the ticket as attachments. Nothing already on the ticket is read, replaced, or removed. Before
  this payload is shown, the tracker's attachment capability is checked (see the tool-limit stop
  below).

#### Status Validation

1. LOAD-CONTEXT returned an enumerable transitions list → compare **CONTENT** against it.
   - **Match** → COMPOSE proceeds; CONFIRM will preview the validated target transition.
   - **No match** → **list the valid targets and stop.** The run ends here — CONFIRM is **never
     reached** for this attempt; no confirm question is even asked.
2. The host MCP could not enumerate transitions for this tracker (a capability gap, not an error)
   → **graceful fallback**: proceed to CONFIRM with **CONTENT** shown as the requested,
   **unvalidated** target, then attempt the transition at WRITE. If the tracker itself rejects it,
   surface **its own error verbatim** at that point — this is the one path where a rejection can
   surface only after the confirm, because there was no earlier read to validate against.

#### Attachment Tool Limit

An attachment is the one part whose tracker may not be able to hold what is written: the host MCP
may expose no attachment call, cap the file size, deny the permission, or take only some of the
files. The skill does not pick a workaround itself. The limit shows in one of three ways:

- **Known up front.** Before CONFIRM, the skill asks the host MCP whether the connection can attach
  files, and it cannot, or a previewed file is over the tracker's stated cap. The run **stops**
  before CONFIRM and does not attach a part of the files.
- **Unknown up front.** The host MCP cannot say whether it can attach. The skill does not stop
  early: it goes on to CONFIRM as normal and tries the attach at WRITE; a failed attach is a tool
  limit, handled as below.
- **Found at WRITE.** The attach is refused (permission denied, size cap) or takes only some of the
  files. This takes the same stop. The files that did go in stay attached.

The stop, for every case:

1. **Tell the user** which limit applies, in the tracker's own words, and which files it blocks.
   After a partial attach, say which files went in and which did not.
2. **Offer the workable options**, each stated plainly, and give one **recommendation**:
   - (a) post a comment (`comment` part) that names each blocked file's repo path and quotes its key
     lines — this keeps the content visible to the tracker's readers;
   - (b) leave the blocked files recorded in the work only, with no write-back to the tracker;
   - (c) the user attaches the blocked files in the tracker by hand, and the skill does nothing further.
   The recommendation is (a) when the blocked files are small enough to quote in a comment, and (c)
   when they are not.
3. **Wait for the user's choice** under the question protocol: one question, its reason, the
   recommendation, the valid options only, and a free-text answer allowed. The run never runs an
   option the user did not pick, and never retries a blocked file. A chosen option (a) is a fresh
   `comment` mutation and goes through COMPOSE and CONFIRM as one.

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
- **`attachment`** → each file's name, size and preview from LOAD-CONTEXT, so the user sees exactly
  what will be attached.

Close with the shared reference's confirm-gate button row, reused **verbatim**
(`ticket-resolution.md` § "Write Preview + Confirm Gate"):

```
[1] File it · [2] Edit · [3] Cancel
```

- **`[1] File it`** → proceed to WRITE.
- **`[2] Edit`** → collect a revised **CONTENT** for the same **PART**/**REF** and re-run
  COMPOSE → Status Validation (if applicable) → CONFIRM against it — still inline, still CHAIN.
  For `attachment`, a revised CONTENT re-runs LOAD-CONTEXT's preview as well.
- **`[3] Cancel`** → exit. No MCP call is made.

### State 6 — WRITE

Only after an explicit `[1] File it` — perform the single mutation call through the connector
resolved at RESOLVE-CONNECTOR, per
[`consumption-protocol.md`](../../aid/templates/connectors/consumption-protocol.md)'s MCP-first
recipe: request the connection from the host tool's own MCP/plugin; AID resolves no credential and
stores none. One call, matching PART's semantics (replace the description / add the comment /
apply the transition / attach the files). On success, confirm the change to the user (the field now
set, the comment posted, the new state, or the files attached).

**MCP-failure policy (general, all parts).** A failed / not-found / unauthorized / unavailable
WRITE call surfaces the tracker's error verbatim and exits **non-destructively** — no partial
write. For `attachment`, a refusal or a partial attach is a tool limit instead: it takes the
Attachment Tool Limit stop above, which names the files that did not go in and does not retry
them. This is distinct from — and, for `status`, can only be reached *after* — the Status
Validation branch above, which can already have stopped the run before CONFIRM was ever asked.

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
- **Attachment, workable.** `/aid-update-ticket attachment jira:PROJ-9 REQUIREMENTS.md` → PARSE-ARGS:
  PART=`attachment`, CONTENT=`REQUIREMENTS.md` → LOAD-CONTEXT reads the file and previews its name,
  size and first lines → the tool check passes → CONFIRM shows that preview and
  `[1] File it · [2] Edit · [3] Cancel` → confirmed → WRITE attaches the file.
- **Attachment, tool limit.** The same invocation against a tracker whose MCP cannot hold
  attachments → the run stops before CONFIRM, names the limit, and offers options (a), (b) and (c)
  with the recommendation; the user picks one, and nothing is written until that choice runs.
- **Reject: bad part.** `/aid-update-ticket close jira:PROJ-9 "wontfix"` → `close` is not in
  `{description, comment, status, attachment}` → Pre-flight prints the usage line and exits; nothing
  is parsed further, no connector is resolved, no MCP call is ever made.

---

## Write-zone

This skill makes exactly **one** external write per invocation — the single host-MCP mutation call
at WRITE, and only after an explicit CONFIRM. It writes **nothing** to the repo: no `Write`/`Edit`
tool is declared; `.aid/connectors/` is only ever read (`Read`/`Glob`/`Grep`, to resolve the
connector via `INDEX.md` and the matched descriptor's `tags:`); the files an attachment names are
only ever read for their preview; no local file, cache, or `STATE.yml` is ever touched. The work's
`write_backs:` entry for an attachment is recorded by the caller that asked for the write-back, not
by this skill.

---

## Constraints

- **Closed `part` enum.** `description | comment | status | attachment` only — anything else is
  rejected with the usage line at Pre-flight, before any connector resolution or MCP call.
- **Content is never re-parsed.** Once `<part>` and the ref are consumed, the entire remainder is
  CONTENT verbatim — it may contain spaces or colons; no flag-like or connector-like substring
  inside it is ever extracted back out. The one exception is `attachment`, whose CONTENT is split
  into file paths at LOAD-CONTEXT and never re-read for any other structure.
- **Only the named part is mutated.** `description` REPLACES, `comment` APPENDS, `status` SETS,
  `attachment` ATTACHES — COMPOSE never touches any other part of the ticket.
- **No silent write.** CONFIRM is mandatory for all four parts; WRITE never runs without an
  explicit `[1] File it`.
- **Status is validated when it can be.** A `status` target is checked against the tracker's
  available transitions whenever the MCP can enumerate them; a mismatch stops the run before
  CONFIRM. When transitions cannot be enumerated, the attempt proceeds and any rejection is
  surfaced verbatim — never silently swallowed, never silently retried.
- **Attachments are previewed and never partial.** Every file is previewed before CONFIRM. When the
  tracker cannot hold the files, the run stops and offers the options; it never picks one, and it
  never attaches some of the files and not others.
- **Non-destructive failure.** Any MCP error (at RESOLVE-CONNECTOR, LOAD-CONTEXT, or WRITE)
  surfaces the tracker's message verbatim and exits without a partial write.
- **No repo writes.** `Write`/`Edit` are absent from `allowed-tools`; this skill persists nothing
  locally.
