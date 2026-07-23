---
name: aid-read-ticket
description: >
  On-demand, non-destructive ticket read. `aid-read-ticket [<connector>:]<ticket-id>` parses the
  ref (an optional `<stem>:` prefix plus the tracker's own id), resolves which issue-tracker
  connector answers it via the shared connector-resolution ladder (explicit override; a single
  catalogued issue-tracker connector used silently; a choice asked when two or more are
  catalogued; the host tool's own tracker MCP as fallback; a "no issue-tracker connector found."
  notice otherwise), fetches the ticket through the host tool's own MCP -- AID resolves no
  credential and stores none -- and displays its fields. Never writes, locally or to the
  tracker, and never shows a confirmation prompt; a failed, not-found, unauthorized, or
  unavailable fetch surfaces the tracker's error verbatim and exits without side effects.
allowed-tools: Read, Glob, Grep, AskUserQuestion
argument-hint: "[<connector>:]<ticket-id>"
---

# Read Ticket

`aid-read-ticket [<connector>:]<ticket-id>` fetches and displays one ticket's fields from
whatever issue tracker the project has integrated. It is tool-agnostic — it never names a
specific tracker, and instead resolves which one to use through AID's connector layer.

**Not a numbered pipeline phase.** Optional, on-demand utility skill, a peer of `aid-query-kb` /
`aid-set-connector` — no phase gate references it, no `shortcut-catalog.yml` entry, no
`work-NNN` scaffold, no `STATE.md` of its own.

**Single-shot, no confirm.** One pass: parse → resolve → fetch → display → exit. Reading is
non-destructive (feature-001 AC-1) — it never prompts for a write, regardless of how many
connectors are catalogued. The connector-choice `AskUserQuestion` (State 2, below), when it
fires, is a resolution branch, never a write-confirmation gate.

---

## Shared reference — read this first

The connector-resolution ladder, the `[<connector>:]<ticket-id>` grammar-parse rule, and the
write-preview/confirm conventions all live once, in
[`.codex/aid/templates/connectors/ticket-resolution.md`](../../aid/templates/connectors/ticket-resolution.md)
— the single shared home for all three ticket skills (`aid-read-ticket`, `aid-create-ticket`,
`aid-update-ticket`). This `SKILL.md` implements that reference by pointer only; nothing below
re-describes the ladder's own validation logic, the grammar's own tokenizing rule, or the confirm
convention — it only names which of the reference's outcomes this skill's own states route to.

- **Ladder:** `ticket-resolution.md § Connector-Resolution Ladder`.
- **Grammar:** `ticket-resolution.md § Grammar-Parse Conventions` — the `aid-read-ticket` row.
- **Confirm gate:** `ticket-resolution.md § Write Preview + Confirm Gate` — states plainly that
  `read` never prompts; there is no gate to implement here.

---

## Pre-flight

Confirm exactly one positional argument was supplied. If `/aid-read-ticket` is invoked with no
argument (or an empty/whitespace-only one), print the `argument-hint` usage line and exit without
fetching anything — the `aid-query-kb` pre-flight pattern; `ticket-resolution.md`'s "Missing/empty
required args" rule:

```
Usage: aid-read-ticket [<connector>:]<ticket-id>
Example: aid-read-ticket PROJ-123
Example: aid-read-ticket jira:PROJ-123
```

---

## States

### State 1 — PARSE-ARGS

Parse the single argument per `ticket-resolution.md § Grammar-Parse Conventions`, "read/update
ref" rule: the token contains a `:` → split on the **first** `:` (the stem before it selects the
connector; the remainder is `<external-id>`). Otherwise the whole token is `<external-id>` and
the connector is left to be resolved by the ladder (State 2).

**Advance:** CHAIN → State 2 (RESOLVE-CONNECTOR).

### State 2 — RESOLVE-CONNECTOR

Resolve which connector answers this fetch by running `ticket-resolution.md § Connector-Resolution
Ladder`, first match wins. This state names only which ladder outcome applies — the ladder's own
catalog/tag-validation mechanics and `INDEX.md` scan details live solely in that file:

- **Explicit stem (from State 1).** Always overrides the scan below — validated per the ladder's
  Step 1 → State 3 on success, or STOP and report an unknown/ineligible stem (no silent
  fall-through).
- **No explicit stem, one catalogued match.** The ladder's Step 2 scan finds exactly one `mcp` +
  `issue-tracker` connector → use it silently → State 3.
- **No explicit stem, two or more catalogued matches.** The ladder's Step 2 scan finds two or
  more → `AskUserQuestion` lists the candidate stems (this skill's **only** use of
  `AskUserQuestion` — a connector pick, never a write confirm, since read has no write to
  confirm) → State 3 once answered.
- **Nothing catalogued.** The ladder's Step 3 → request the host tool's own issue-tracker MCP →
  State 3 if one is available.
- **Neither available.** The ladder's Step 4 → notify the user, verbatim:
  ```
  no issue-tracker connector found.
  ```
  and exit (AC-6).

**Advance:** CHAIN → State 3 (FETCH) once a connector resolves; STOP/exit on the unknown-stem or
notify branches above.

### State 3 — FETCH

Per `consumption-protocol.md`'s MCP-first recipe (pointed to by `ticket-resolution.md § MCP-first
consumption`): request the connection from the **host tool's own MCP/plugin** for the resolved
connector's target tracker, and fetch `<external-id>`'s fields. AID resolves no credential and
stores none for this call — this is the skill's single external call, and it is a read.

**MCP-call failure policy.** A failed / not-found / unauthorized / unavailable call surfaces the
tracker's own error **verbatim** and exits non-destructively — never retry silently, never fall
back to a different connector, never fabricate a placeholder result (feature-001 § Feature Flow,
"MCP-call failure policy").

**Advance:** CHAIN → State 4 (DISPLAY) on success; STOP/exit on failure per the policy above.

### State 4 — DISPLAY

Render exactly the fields the tracker returned — never invent one it did not supply. A compact
fielded summary, e.g.:

```
<connector-stem>:<external-id> — <title>
Status: <status>    Assignee: <assignee>

<description>

<comments, if any>
```

Exit 0. Nothing is written locally or remotely anywhere in this flow — the only side effect in
the whole run is State 3's single read.

---

## Dispatch table

| Condition | Path | Result |
|---|---|---|
| No/empty argument | Pre-flight | Usage line printed; exit |
| Explicit `<connector>:` stem given | State 2, explicit-stem branch | Validated stem used, or STOP on an unknown/ineligible stem |
| Zero catalogued `issue-tracker` connectors | State 2, host-MCP / notify branches | Host tool's own tracker MCP attempted; else the notify string, then exit |
| Exactly one catalogued `issue-tracker` connector | State 2, single-match branch | Used silently |
| Two or more catalogued `issue-tracker` connectors | State 2, multi-match branch | `AskUserQuestion` asks which |
| Fetch succeeds | State 3 → 4 | Fields displayed |
| Fetch fails (not-found / unauthorized / unavailable) | State 3 | Tracker's error surfaced verbatim; exit |

---

## Constraints

- **Non-destructive, always.** No `Write`/`Edit` tool is declared or ever needed — this skill
  persists nothing in the repo and performs no external write of any kind.
  `allowed-tools: Read, Glob, Grep, AskUserQuestion` is the complete set; the host-MCP fetch tool
  itself is requested at runtime per `consumption-protocol.md`, never statically declared here.
- **No confirmation prompt, ever.** `AskUserQuestion` fires only for the 2+-connector "which
  connector" branch in State 2; it never gates the fetch — there is nothing to confirm, because
  read never writes.
- **No ladder/grammar/confirm re-description.** Everything about resolving a connector, parsing
  `[<connector>:]<ticket-id>`, or the write-preview/confirm convention is owned by
  `ticket-resolution.md`; this file only points to it and names which outcome applies where.
- **No work folder.** `/aid-read-ticket` does not create `.aid/works/work-*/` directories or a
  `STATE.md` of its own.
- **Content isolation.** `aid-` prefix (satisfied by the skill name); the shared reference this
  skill points to lives under the `aid/` template subtree.

---

## Worked examples

(Restates `ticket-resolution.md § Worked Examples` in this skill's own terms — no new behavior.)

- **Single catalogued tracker.** `/aid-read-ticket PROJ-123` — no `:` in the argument → State 1
  takes the whole token as `<external-id>`; State 2's scan finds exactly one `mcp` +
  `issue-tracker` connector → uses it silently; State 3 fetches via the host MCP; State 4
  displays the fields. No prompt anywhere (AC-1).
- **Explicit connector.** `/aid-read-ticket jira:PROJ-123` — State 1 splits on the first `:` →
  stem `jira`, id `PROJ-123`; State 2 validates `jira` is catalogued and tagged `issue-tracker`
  (overriding any scan) → State 3 fetches → State 4 displays.
- **Two catalogued trackers.** With `linear` and `jira-mcp` both catalogued `issue-tracker`
  connectors and no explicit stem → State 2 asks via `AskUserQuestion` which to use; once
  answered, State 3/4 proceed exactly as above.
- **Not found.** `/aid-read-ticket PROJ-999`, where `PROJ-999` does not exist on the resolved
  tracker → State 3's fetch returns a not-found error → the tracker's error is surfaced verbatim
  and the skill exits; no fields are displayed, nothing is retried.
- **No connector at all.** No `issue-tracker` connector catalogued and the host tool has no
  tracker MCP of its own → State 2's Step 4 notifies `"no issue-tracker connector found."` and
  exits (AC-6).
