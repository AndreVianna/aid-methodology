---
name: aid-create-ticket
description: >
  On-demand utility skill that files one new ticket via whatever issue-tracker connector the
  project has registered, or the host tool's own tracker MCP when none is catalogued. Parses
  `--connector <stem>`, `--level epic|story|task`, and `--parent <ref>` flags in any order ahead
  of a free-text `<description>` (create has no leading-token connector heuristic), resolves the
  connector via the shared ladder, composes the new-ticket payload (fixing level and parent by
  precedence, defaulting neither silently), resolves the canonical tier to the tracker's concrete
  issue-type at runtime via a non-destructive read (graceful degradation when the tracker has no
  matching type), previews the exact payload, and gates on one in-run AskUserQuestion confirm --
  which also carries the epic|story|task pick when the level is neither explicit nor inferable --
  before filing. Returns the new `<connector-stem>:<external-id>` only after the user confirms;
  nothing is filed, and no local file is ever written, before that.
allowed-tools: Read, Glob, Grep, AskUserQuestion
argument-hint: "[--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>"
---

# Create Ticket

`/aid-create-ticket` files a new ticket in a catalogued (or host-owned) issue tracker after
previewing the exact payload and gaining an explicit confirm. It is one of three peer, on-demand
ticket skills — alongside `/aid-read-ticket` and `/aid-update-ticket` — that give AID users a
tool-agnostic way to interact with whatever tracker their project has integrated
(feature-001-dedicated-ticket-skills SPEC.md).

**Shared reference.** The connector-resolution ladder, the grammar-parse rules, the write
preview/confirm-gate convention, Level Resolution, and Parent Resolution this skill uses are all
described **once**, in
[`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md). This `SKILL.md`
never restates any of that — each state below points to the relevant section instead.

**Absent from the mandatory pipeline flow.** Like `/aid-query-kb` and `/aid-set-connector`, this is
an optional, on-demand utility skill outside the Discover-Execute flow: no phase gate references
it, no `shortcut-catalog.yml` entry, no `work-NNN` scaffold, no `STATE.md` of its own — invoked
directly by name.

**State-machine chaining:** each `/aid-create-ticket` invocation drives the state machine —
`PARSE-ARGS → RESOLVE-CONNECTOR → COMPOSE → LEVEL-RESOLVE → CONFIRM → FILE → RETURN-REF` — until
it hits a natural pause point per
[`.agent/aid/templates/state-machine-chaining.md`](../../aid/templates/state-machine-chaining.md).
CONFIRM's `AskUserQuestion` exchange is fully inline, so it is a **CHAIN** advance, never
`PAUSE-FOR-USER-DECISION` — a single invocation runs every state through to `RETURN-REF` (or an
earlier stop/cancel) without exiting mid-run to collect an answer.

**Read-only until CONFIRM.** `RESOLVE-CONNECTOR`, `COMPOSE`, and `LEVEL-RESOLVE` only ever read —
the tracker's issue-type list is queried (a non-destructive read), never written. Nothing about
the level, the parent, or the rest of the payload reaches the tracker until the user explicitly
confirms at `CONFIRM`; `FILE` is the only state that writes, and it writes exactly once, right
after that confirm (feature-001 SPEC.md § Security Specs).

**Writes no local file.** This skill's only external effect is the host-MCP ticket file (`FILE`
state, gated behind confirm) — there is no `Write`/`Edit` tool in `allowed-tools`, and no file
under this repo is ever touched (the three ticket skills persist nothing locally — feature-001
SPEC.md § Layers & Components).

---

## Pre-flight

Confirm at least one argument was supplied. A bare `/aid-create-ticket` with nothing after it —
no flags, no description — prints the usage line and exits without entering `PARSE-ARGS`:

```
Usage: /aid-create-ticket [--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>
Example: /aid-create-ticket --level story --parent PROJ-12 "Add pagination to the /orders list"
```

---

## States

### State 1 — PARSE-ARGS

Parse the invocation per
[`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) § "Grammar-Parse
Conventions" — the `aid-create-ticket` grammar row and its "create flags + description" rule: up
to three optional flags — `--connector <stem>`, `--level <tier>`, `--parent <ref>` — may appear in
**any order** before the trailing free-text `<description>`. Flags are parsed regardless of
position; once they are consumed, the **whole non-flag remainder is the `<description>` verbatim**
— never re-parsed, so a description may itself contain the word "level", a `PROJ-1`-shaped token,
or a word matching a catalogued stem without being mis-read as a flag. **Create has no
bare-leading-token connector heuristic** — unlike `aid-read-ticket`/`aid-update-ticket`'s
`[<connector>:]<ticket-id>` colon form, the connector here comes only from `--connector` or the
resolution ladder (next state).

Per-flag handling:

- **`--connector <stem>`** — capture the stem verbatim; validated once the ladder runs
  (`RESOLVE-CONNECTOR`), not here.
- **`--level <tier>`** — accepts the closed canonical enum `epic|story|task` (case-insensitive) OR
  a quoted literal provider-type passthrough (e.g. `--level "Sub-task"`, which later skips
  synonym-matching entirely — `LEVEL-RESOLVE`). A bare value that is **neither** one of the three
  tiers **nor** quoted is rejected — print the usage line (below) and exit; never guess, never
  silently drop the flag. `--level` is optional and carries **no default** — omitting it means the
  level is either inferred from the description or asked at `CONFIRM` (never assumed here).
- **`--parent <ref>`** — capture one ticket ref (`[<stem>:]<external-id>`) verbatim; cross-checked
  against the resolved connector in the next state, resolved fully in `COMPOSE`.
- **Missing `<description>`** after the flags are consumed (nothing left, or only whitespace) —
  print the usage line and exit:
  ```
  Usage: /aid-create-ticket [--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>
  Example: /aid-create-ticket --level story --parent PROJ-12 "Add pagination to the /orders list"
  ```

**Advance:** → State: RESOLVE-CONNECTOR (continue inline).

### State 2 — RESOLVE-CONNECTOR

Resolve which connector to use via the shared
[`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) §
"Connector-Resolution Ladder" — first match wins, exactly as read/update use it: explicit
`--connector <stem>` (validated `issue-tracker`; an unknown/ineligible stem stops the run, no
silent fall-through) → the sole catalogued `mcp`+`issue-tracker` match (silent) or an
`AskUserQuestion` among two-or-more → the host tool's own issue-tracker MCP → the verbatim
`no issue-tracker connector found.` notify-and-exit. This state does not re-describe the ladder
further than that; `$CONNECTOR` now holds whichever stem it resolves to, for every later state.

**Cross-tracker parent check (fold-in of Parent Resolution's same-connector rule).** If
`PARSE-ARGS` captured a `--parent <stem>:<ref>` whose `<stem>` names a **different** catalogued
connector than `$CONNECTOR` just resolved to, this is a cross-tracker link the skill cannot make
(ticket-resolution.md § "Parent Resolution (create only)"): surface **"parent must be on the same tracker as the
new ticket"** and stop here — before `COMPOSE`, before `CONFIRM` — `--parent`'s stem is never
treated as a `--connector` override, and `$CONNECTOR` is never silently switched to match it. A
bare `--parent <external-id>` (no stem), or one whose stem matches `$CONNECTOR`, has no ambiguity
and proceeds.

**Advance:** → State: COMPOSE (continue inline).

### State 3 — COMPOSE

Build the new-ticket payload from `<description>`. Fix two attributes by precedence, **defaulting
neither silently** (feature-001 SPEC.md § Feature Flow):

- **Level:** explicit `--level` › description-inferred (e.g. "this epic…", "bug:") › **unset**. A
  description-inferred level is only a *candidate* here — it is surfaced for explicit confirmation
  at `CONFIRM`, never silently applied.
- **Parent:** `--parent <ref>` › description-inferred ("under PROJ-123") › **none**. Resolved on
  `$CONNECTOR` (the same-tracker rule was already enforced in `RESOLVE-CONNECTOR` above — see
  [`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) § "Parent
  Resolution (create only)" for the full rationale).

Assemble the draft payload: a title/summary derived from `<description>`, the level (a tier, a
quoted literal, or unset), and the parent ref (or none). Nothing is sent anywhere yet.

**Advance:** → State: LEVEL-RESOLVE (continue inline).

### State 4 — LEVEL-RESOLVE

A **non-destructive** host-MCP issue-type query — it runs before the gate precisely because it
only reads (feature-001 SPEC.md § Security Specs: "no new silent behavior and no new write"). Per
[`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) § "Level Resolution
(create only)":

- **Quoted literal passthrough** (`--level "Sub-task"`) skips synonym-matching entirely — the exact
  provider type is requested verbatim; no tier mapping is attempted.
- **Otherwise**, query the tracker's available issue-types via the host MCP
  (`consumption-protocol.md`'s recipe — the host owns the call) and map the canonical tier to the
  tracker's concrete type by the **ordered synonym set, first available wins** the shared reference
  defines (this state does not re-list it).
- **Graceful degradation:** no tier match anywhere in the tracker's type set (e.g. a flat tracker
  such as GitHub Issues with no native issue-type field) → plan to file a **plain issue**,
  optionally with a `type:<tier>` label; carry the degradation note forward for the preview
  ("filed as a plain issue — this tracker has no `<tier>` type").
- **When the level is still unset** after `COMPOSE` (no explicit `--level`, none inferable), this
  query still runs — its result feeds `CONFIRM`'s pick with the tracker's **real** available types,
  so the user chooses among real options instead of guessing blind.
- No persistent per-connector `level_map` override exists (deferred — would need a
  connector-descriptor schema change, out of scope here); this runtime synonym match plus the
  literal passthrough are the whole mechanism.

**Advance:** → State: CONFIRM (continue inline).

### State 5 — CONFIRM

A single in-run `AskUserQuestion` exchange (one tool call, never two prompts across turns) per
[`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) § "Write Preview +
Confirm Gate" — a **CHAIN** advance, never `PAUSE-FOR-USER-DECISION`
(`state-machine-chaining.md` — fully `AskUserQuestion`-based exchanges are asked and answered
inline). It carries up to two parts, both resolved within this same call:

- **Level pick** (only when the level is still unset after `COMPOSE` — no explicit `--level` and
  none inferable from the description): an `epic | story | task` choice, presented against the
  tracker's real available issue-types just queried at `LEVEL-RESOLVE`. **This is the confirm
  gate's own level pick — there is no separate pre-write prompt.** A description-inferred level is
  instead surfaced in the payload preview below, for explicit confirmation, not re-asked as a fresh
  pick.
- **Payload confirm** (always): the **exact** payload that will be sent — `$CONNECTOR`, the
  description, the **concrete resolved issue-type** (or the graceful-degradation note from
  `LEVEL-RESOLVE`), and the parent link (or a no-hierarchy / no-parent note from `COMPOSE`) —
  followed by:
  ```
  [1] File it · [2] Edit · [3] Cancel
  ```

**No silent level default, ever:** if the level is unset or uninferable, the pick above is
mandatory before `[1] File it` can be chosen — there is no path from `COMPOSE`/`LEVEL-RESOLVE`
straight to `FILE` that skips this gate.

**Advance:** `[1] File it` → State: FILE (continue inline). `[2] Edit` → State: COMPOSE (continue
inline, with the user's requested change folded into the payload). `[3] Cancel` → halt; nothing is
sent, nothing is filed.

### State 6 — FILE

Reached **only** after an explicit `[1] File it` confirm. Writes via the host MCP
(`consumption-protocol.md`'s recipe):

1. File the ticket with the resolved issue-type (or the degraded plain-issue + optional
   `type:<tier>` label).
2. Set the provider's **native** parent link, **best-effort**
   (ticket-resolution.md § "Parent Resolution (create only)"): a tracker with no hierarchy concept, or a link the
   provider rejects, is **reported, not fatal** — the create still succeeds; only the missing link
   is noted.

A failed / not-found / unauthorized / unavailable host-MCP call surfaces the tracker's error
**verbatim** and exits **non-destructively** — never a partial write (feature-001 SPEC.md § Feature
Flow, MCP-call failure policy).

**Advance:** → State: RETURN-REF (continue inline).

### State 7 — RETURN-REF

Return the new **`<connector-stem>:<external-id>`** — only now, after `FILE` succeeded. If the
parent link could not be applied (`FILE`'s best-effort note), restate that alongside the new ref so
the outcome is never silent.

**Advance:** → halt.

---

## Worked examples

See [`ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md) § "Worked
Examples" for full walkthroughs of: an ambiguous-connector + unset-level create (the level pick
folds into `CONFIRM`, the resolved concrete type and the parent link both show in the preview), and
a cross-tracker `--parent` that stops before the gate with "parent must be on the same tracker as
the new ticket". This `SKILL.md` does not duplicate those examples.

---

## Write-zone

This skill's **only** external effect is the host-MCP ticket file at `FILE`, gated behind the
`CONFIRM` state's explicit `[1] File it` — never before it. It never writes to `.aid/connectors/`,
never invokes `/aid-discover` or `/aid-set-connector`, and (having no `Write`/`Edit` tool) never
touches any file under this repo.

---

## Constraints

- **No silent level default.** Absent `--level` and nothing inferable from the description means
  the `epic|story|task` pick is mandatory at `CONFIRM` — never assumed, never defaulted.
- **Tier → tracker-type resolution is always shown.** The preview always carries either the
  concrete resolved issue-type or the graceful-degradation note; the outcome is never silent.
- **Parent linking is best-effort, never fatal.** A missing hierarchy or a rejected link is noted
  in the preview/return, and the create still succeeds.
- **Same-tracker parent only.** A `--parent` naming a different catalogued connector than the one
  resolved for the new ticket stops the run before `CONFIRM` — it is never silently resolved by
  switching connectors.
- **No write before confirm.** `RESOLVE-CONNECTOR`, `COMPOSE`, and `LEVEL-RESOLVE` are reads only;
  `FILE` is the sole write, gated behind the single `CONFIRM` exchange.
- **Grammar is deterministic.** Flags parse in any order; the whole non-flag remainder is the
  description verbatim; create has no bare-leading-token connector heuristic (unlike
  read/update's `[<connector>:]<ticket-id>` colon form).
