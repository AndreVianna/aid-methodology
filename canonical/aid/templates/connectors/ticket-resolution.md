# Ticket Resolution Reference (Connector Ladder, Grammar, Confirm Gate)

> Shared reference for the three dedicated ticket-tracker skills — `aid-read-ticket`,
> `aid-create-ticket`, and `aid-update-ticket` (each authored under
> `canonical/skills/aid-<name>/SKILL.md` by a later delivery-001 task; see
> `features/feature-001-dedicated-ticket-skills/SPEC.md`). Each skill's `SKILL.md`
> implements this reference by a **short, additive pointer** — none of the three
> re-describe the connector-resolution ladder, the grammar-parse rules, or the write
> preview/confirm-gate convention inline (SPEC.md § Layers & Components, "Shared
> reference (DRY, decision 1)"). This is the single, DRY home for all three — the
> same pattern [`shortcut-engine.md`](../shortcut-engine.md) and
> [`consumption-protocol.md`](consumption-protocol.md) already establish for their
> own callers.
>
> **Scope boundary.** This file owns *how a ticket skill resolves a connector, parses
> its own grammar, and gates a write* — never *how a seam consumes an already-resolved
> connector at runtime* (that recipe is [`consumption-protocol.md`](consumption-protocol.md)'s
> job; this file points to it rather than restating it) and never the connector
> catalog's own add/update/remove lifecycle (that is [`reconcile.md`](reconcile.md)'s
> job).
>
> This is a `canonical/` artifact: it ships and installs byte-identically into every
> profile's `.claude/aid/templates/connectors/` (or equivalent per-tool) install tree,
> alongside [`consumption-protocol.md`](consumption-protocol.md),
> [`reconcile.md`](reconcile.md), and [`preset-catalog.md`](preset-catalog.md).

## Connector-Resolution Ladder

All three skills resolve which connector to use the same way — REQUIREMENTS.md FR-4,
first match wins:

1. **Explicit `<connector>`.** Read/update take a `<stem>:` prefix on the ticket ref
   (`[<connector>:]<ticket-id>`); create takes the `--connector <stem>` flag. Either
   form **always overrides** the scan below. Validate the named stem is catalogued
   under `.aid/connectors/` **and** tagged `issue-tracker` in its own descriptor
   frontmatter (see Step 2's tag check) — an unknown stem, or a stem that exists but
   is not tagged `issue-tracker`, is an error: STOP and report it (no silent
   fall-through to the scan).
2. **Scan `.aid/connectors/INDEX.md`.** Read the index table (`Connector | Type |
   Endpoint | Auth | Secret Ref | Summary` — the index carries no `tags` column of
   its own) and shortlist every row whose **Type** is `mcp`. For each shortlisted row,
   open its descriptor `.aid/connectors/<stem>.md` and confirm its frontmatter `tags:`
   list includes `issue-tracker` — the same purpose-match signal
   `consumption-protocol.md § "The seam recipe (generic shape)"` Step 1 uses (a
   preset's `tags` column, `preset-catalog.md`, is the same signal ELICIT already
   applies when a connector is first catalogued).
   - **Exactly one** `mcp` + `issue-tracker` match → **use it silently**, no prompt.
   - **Two or more** → ask the user which via `AskUserQuestion`, listing the
     candidate stems (their descriptor `name`, not just the raw stem).
3. **None catalogued** → request the **host tool's own** issue-tracker MCP
   (host-owned; AID wires nothing — same MCP-first posture as
   `consumption-protocol.md`).
4. **Neither available** → notify the user, verbatim:
   ```
   no issue-tracker connector found.
   ```
   and exit (REQUIREMENTS.md AC-6). A bare `<ticket-id>` with no prefix (read/update)
   follows this same ladder to pick the connector.

### MCP-first consumption (pointer)

Once a connector resolves, the actual fetch/file/update runs through
[`consumption-protocol.md`](consumption-protocol.md)'s MCP-first recipe: request the
connection from the **host tool's own MCP/plugin** — AID resolves no credential and
stores none for it. This file does not restate that recipe; it only decides *which*
connector reaches it.

### `api` / `ssh` / `cli` fall-through

A registered connector whose `connection_type` is anything other than `mcp` is **not**
live-consumable by these skills (REQUIREMENTS.md FR-5, out of scope: "Live consumption
of aid-managed `api`/`ssh`/`cli` connectors"). Step 2 above skips it (its Type is not
`mcp`), so resolution falls through to Step 3/4. **When such a connector is the
*only* `issue-tracker` match**, tell the user it is registered but not
live-consumable (MCP-first; `api`/`ssh`/`cli` consumption is the deferred follow-up)
before falling through — so the user is not left wondering why a catalogued
connector was never used.

### Catalog reality (acknowledged)

The shipped `preset-catalog.md` presets yield **no** `mcp` `issue-tracker` connector
today: the only `issue-tracker`-tagged preset is `jira`, which is `api`-typed;
`gitlab` and the `mcp`-typed `github` are both tagged `source-host`, not
`issue-tracker`. So Step 2's silent-single-match path activates once a user registers
a **custom `mcp` issue-tracker** connector (e.g. an Atlassian/Jira or GitHub-issues
MCP, via `aid-set-connector`) — the intended day-one usage. Until then, resolution
reaches Step 3 (host MCP) or Step 4 (notify). This is expected, not a defect.

## Grammar-Parse Conventions

Deterministic parsing shared by all three skills (REQUIREMENTS.md FR-1/FR-2/FR-3;
SPEC.md § API Contracts):

| Skill | Grammar (`argument-hint`) | Tokens |
|---|---|---|
| `aid-read-ticket` | `[<connector>:]<ticket-id>` | optional `stem:` prefix + one id token |
| `aid-create-ticket` | `[--connector <stem>] [--level epic\|story\|task] [--parent <ref>] <description>` | optional connector/level/parent flags (any order) + free-text description |
| `aid-update-ticket` | `<part> [<connector>:]<ticket-id> <content>` | `part` ∈ `{description, comment, status}` + `[stem:]id` ref + free-text content |

Parse rules:

- **read/update ref:** contains a `:` → split on the **first** `:` (`<stem>` selects
  the connector, remainder = `<external-id>`); else the whole token is the id and the
  connector is resolved by the ladder above.
- **update:** the first whitespace token is `part` — a **closed enum**; anything else
  is rejected with the `argument-hint` usage line. The second token is the ref.
  Everything after that is `<content>` — free text, may contain spaces/colons, **never
  re-parsed**.
- **create flags + description** (no bare-leading-token connector heuristic): up to
  three optional flags — **`--connector <stem>`**, **`--level <tier>`**,
  **`--parent <ref>`** — may appear in **any order** before the trailing free-text
  `<description>`. Flags are parsed regardless of position; once consumed, the
  **whole non-flag remainder is the `<description>` verbatim** (flags are never
  re-parsed out of the description body, so a description may itself contain the word
  "level", a `PROJ-1`-shaped token, or a word matching a catalogued stem, without
  being mis-read as a flag).
  - **`--connector <stem>`** selects the connector directly; absent, the connector
    comes from the ladder above. Create has **no bare-leading-token heuristic** —
    unlike read/update's `[<connector>:]<ticket-id>` colon form, a description that
    legitimately begins with a stem-matching word is never mis-read as a selector.
  - **`--level <tier>`** takes the closed canonical enum `epic|story|task`
    (case-insensitive) **or** a quoted literal provider-type passthrough (e.g.
    `--level "Sub-task"`, which skips synonym resolution entirely — see Level
    Resolution below). A bare value that is neither a tier nor quoted is **rejected
    with the usage line**. Optional, **no default** — see Write Preview + Confirm
    Gate.
  - **`--parent <ref>`** takes one ticket ref (`[<stem>:]<external-id>`, resolved on
    the same connector); optional — see Parent Resolution below.
- **Missing/empty required args** (no `<description>` after the flags on create; no
  `<part>`/ref/content on update; no ref on read) → print the `argument-hint` usage
  line and exit (the `aid-query-kb` pre-flight pattern).

## Write Preview + Confirm Gate

- **`read` never prompts.** It is non-destructive — fetch, display, done (AC-1).
- **`create`/`update` always preview before writing.** Show the user the **exact**
  payload that will be sent, then gate on a single in-invocation `AskUserQuestion`
  confirm **before** the MCP write call (REQUIREMENTS.md NFR-2; SPEC.md § Security
  Specs). No skill ever writes to a tracker without this explicit confirm.
- **This is a CHAIN advance, never `PAUSE-FOR-USER-DECISION`.** Per
  [`../state-machine-chaining.md`](../state-machine-chaining.md) § "The four advance
  types", a transition whose user interaction is "fully `AskUserQuestion`-based" (asked
  and answered inline, same turn) is CHAIN — the skill never exits mid-run to collect
  this answer. The confirm question is asked and answered within the same invocation
  that goes on to perform the write.
- **`create`'s confirm gate folds in the level pick.** When the level is neither
  explicit (`--level`) nor inferable from the description, the pick **is** part of
  this same gate — an `epic|story|task` choice presented alongside the payload
  preview, never a separate pre-write prompt (SPEC.md § Feature Flow, § Security
  Specs: "no new silent behavior and no new write"). A description-inferred level is
  surfaced here too, for explicit confirmation — never silently applied. The preview
  always shows the **concrete resolved issue-type** (or the graceful-degradation note
  — see Level Resolution) and any **parent** link (or a no-hierarchy note — see
  Parent Resolution), followed by:
  ```
  [1] File it · [2] Edit · [3] Cancel
  ```
- **`update`'s confirm gate shows the exact change** for whichever `<part>` is being
  mutated: `description` — before/after; `comment` — the text being appended;
  `status` — the target transition (validated against the tracker's available
  transitions first; an invalid target lists the valid options and the gate is never
  reached for that attempt).

## Level Resolution (create only)

Canonical tier `epic | story | task` (broad → granular) resolved to the tracker's
**real issue-type at runtime** (REQUIREMENTS.md FR-2a):

- **Determination precedence, no silent default:** (1) explicit `--level`; (2) else
  inferred from the description (e.g. "this epic…", "bug:") and surfaced at the
  confirm gate for confirmation; (3) else **unset** — the confirm gate requires an
  explicit pick.
- **Tier → type mapping, once a level is known or being resolved:** query the
  tracker's available issue-types via the host MCP, then match by an **ordered
  synonym set, first available wins**:
  - `epic` → Epic / Initiative / Feature / Theme…
  - `story` → Story / User-Story / Issue / Requirement…
  - `task` → Task / Sub-task / To-do / Chore…
- **Quoted literal passthrough** (`--level "Sub-task"`) **skips synonym-matching
  entirely** and requests that exact provider type verbatim — the escape hatch for
  finer per-tracker control.
- **Graceful degradation:** a tracker whose type set matches no tier (e.g. a flat
  tracker such as GitHub Issues, with no native issue-type field) files a **plain
  issue** and optionally applies a `type:<tier>` label; the confirm preview shows the
  concrete resolved type, or, on degradation, a note such as "filed as a plain issue
  — this tracker has no `<tier>` type" — the outcome is never silent.
- **No persistent per-connector override.** A `level_map`-style descriptor field is a
  deferred follow-up (would require a connector-descriptor schema change, out of
  scope here); the runtime synonym match plus the literal passthrough cover the need
  without it.
- This query is a **non-destructive read** (the tracker's issue-type list), so it runs
  **before** the confirm gate — feeding the preview when the tier is already known,
  and offering the pick against the tracker's real types when it is not.

## Parent Resolution (create only)

`--parent <ref>` (or a description-inferred parent, e.g. "under PROJ-123";
`--parent` wins when both are present) links the new ticket to a parent in the
**same** tracker via the provider's **native** hierarchy — Jira parent/epic-link,
Azure Boards parent-child, GitHub sub-issue, … — **best-effort** (REQUIREMENTS.md
FR-2b):

- A tracker with no hierarchy concept, or a link the provider rejects, is **noted in
  the preview and does not fail the create** — the ticket is still filed; the
  missing link is reported, not fatal.
- **The parent MUST resolve on the same connector as the new ticket — never a
  different one.** A bare `--parent <external-id>` (no stem) is simply the parent on
  the new ticket's own resolved connector — no ambiguity. A `--parent
  <stem>:<external-id>` whose stem **names a different catalogued connector** than
  the one the ladder already resolved for the new ticket is a cross-tracker link the
  skill cannot make: **surface it to the user** ("parent must be on the same tracker
  as the new ticket") and stop before the confirm gate — `--parent`'s stem is never
  treated as a `--connector` override for the new ticket, and the new ticket's
  resolved connector is never silently switched to match the parent's stem instead.
- Shown in the preview at the confirm gate; applied **only** as part of the
  post-confirm write — nothing about the parent link reaches the tracker before the
  user confirms.

## Consuming Skills

Each skill's own `SKILL.md` points here rather than re-describing any of the above:

| Skill | Uses this reference for |
|---|---|
| `aid-read-ticket` | Connector-Resolution Ladder; the read grammar row above. No confirm gate — reads never prompt. |
| `aid-create-ticket` | Connector-Resolution Ladder; the create grammar row; Write Preview + Confirm Gate; Level Resolution; Parent Resolution. |
| `aid-update-ticket` | Connector-Resolution Ladder; the update grammar row; Write Preview + Confirm Gate. |

## Worked Examples

- **Read, single catalogued tracker.** `/aid-read-ticket PROJ-123` — no `--connector`,
  no `:` prefix → ladder Step 2: exactly one `mcp` + `issue-tracker` connector
  catalogued → used silently → fetched via `consumption-protocol.md`'s host-MCP
  recipe → fields displayed. No prompt anywhere (AC-1).
- **Create, ambiguous connector, unset level.** `/aid-create-ticket --parent LIN-10
  "Fix pagination bug on the /orders list"` with two `issue-tracker` connectors
  catalogued (`linear`, `jira-mcp`) → ladder Step 2 finds two matches →
  `AskUserQuestion` asks which; say the user picks `linear` → the bare `--parent
  LIN-10` (no stem) resolves on that same, now-known connector — no ambiguity. No
  `--level` given and none inferable → the connector's available issue-types are
  queried → the confirm gate asks `epic|story|task`, shows the resolved concrete
  type once picked, and shows the `linear:LIN-10` parent link → user confirms →
  ticket filed, `linear:<new-id>` returned.
- **Create, parent on a different tracker (surfaced, not silently resolved).**
  `/aid-create-ticket --connector linear --parent jira-mcp:PROJ-9 "Add pagination"`
  → the new ticket's connector resolves to `linear` (explicit `--connector`), but
  `--parent`'s stem names `jira-mcp` — a **different** catalogued connector. This is
  a cross-tracker link the skill cannot make: the run stops **before** the confirm
  gate and tells the user "parent must be on the same tracker as the new ticket" —
  `--parent`'s stem never overrides the new ticket's own connector, and the new
  ticket's connector is never silently switched to `jira-mcp` to match the parent
  instead.
- **Update, invalid status transition.** `/aid-update-ticket status jira:PROJ-9
  "Done"` where `PROJ-9`'s current state has no direct transition to `Done` → the
  tracker's available transitions are queried, the requested target is not among
  them → the valid options are listed and the run stops **before** the confirm gate
  is ever reached (SPEC.md § Security Specs, decision 4).
