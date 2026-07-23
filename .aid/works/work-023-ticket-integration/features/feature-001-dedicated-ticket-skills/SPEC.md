# Dedicated Ticket-Tracker Skills

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Feature identified from REQUIREMENTS.md §5 FR-1, FR-2, FR-3, FR-4, FR-5, FR-6; §4 | /aid-define |
| 2026-07-22 | Cross-ref cycle-1 FIX: added the create-grammar leading-token disambiguation to the create AC (FR-2) | /aid-define (cross-reference) |
| 2026-07-22 | Technical Specification authored (INITIALIZE + CONTINUE): skill anatomy, per-skill state machines, shared connector-resolution reference, grammar, write-safety, testing | /aid-specify |
| 2026-07-22 | Specify REVIEW cycle-1 FIX: restructured under the mandated core headings (Data Model / Feature Flow / Layers & Components) + standard conditional sections; added AskUserQuestion to allowed-tools; reworded the confirm as an in-invocation gate (not PAUSE) + cited state-machine-chaining.md; decided the create-grammar `--connector` override (no longer deferred); added a general MCP-failure policy; acknowledged the no-mcp-issue-tracker-preset reality | /aid-specify (review-fix) |
| 2026-07-22 | Enhancement (owner change request): --level (epic\|story\|task, no default → ask at confirm gate; tier resolved to tracker issue-type at runtime) + --parent (native hierarchy) added to aid-create-ticket; flag grammar | /aid-specify |
| 2026-07-22 | Re-gate cycle-1 FIX: deferred level_map (no descriptor-schema change); dropped create leading-token heuristic (flag grammar); corrected gitlab/issue-tracker catalog claim; fixed create MCP call-count | /aid-specify (review-fix) |

## Source

- REQUIREMENTS.md §5 FR-1, FR-2, FR-3, FR-4, FR-5, FR-6; §4 Scope

## Description

Give AID users three explicit, user-invoked commands to interact with whatever ticket or issue
tracker their project has integrated — `/aid-read-ticket` to fetch and display a ticket's fields,
`/aid-create-ticket` to file a new ticket, and `/aid-update-ticket` to change a ticket's
description, append a comment, or set its status. The commands are tool-agnostic: they never name
a specific tracker, and instead resolve which tracker to use through AID's existing connector
layer. When no connector is explicitly named, the skill scans for a single registered
issue-tracker connector and uses it silently, asks the user to choose when there is more than one,
falls back to the host tool's own tracker integration, and otherwise tells the user none was
found. Reading is non-destructive and never prompts; anything that changes a tracker item always
shows a preview of exactly what will be sent and waits for explicit confirmation before writing.
Together these three commands become the single sanctioned way any outward tracker interaction is
started.

## User Stories

- As an AID adopter/developer, I want to read a ticket's fields on demand so that I can see its
  current state without leaving my workflow or touching the tracker's UI.
- As an AID adopter/developer, I want to file a new ticket from AID after previewing exactly what
  will be sent so that nothing reaches the tracker without my explicit go-ahead.
- As an AID adopter/developer, I want to update a ticket's description, add a comment, or change
  its status through one predictable command so that I control every outward change.
- As a project lead/PM, I want every tracker write to be user-initiated and previewed so that the
  tracker never receives a silent or unexpected edit.
- As an AID methodology maintainer, I want the tracker binding to come only from the registered
  connector so that the skills stay tool-agnostic and work against any integrated tracker.

## Priority

Must

## Acceptance Criteria

- [ ] Given a project with a resolvable issue-tracker connector, when the user runs
  `/aid-read-ticket PROJ-123` (or `/aid-read-ticket jira:PROJ-123`), then the ticket's fields are
  displayed, no external write is performed, and no confirmation prompt is shown.
- [ ] Given the user runs `/aid-create-ticket`, when a preview of exactly what will be sent is
  shown and the user explicitly confirms, then the new ticket is filed and the new
  `<connector-stem>:<external-id>` is returned — and only then. The **level** is never silently
  defaulted: absent `--level` and with none inferable from the description, the confirm gate
  requires an explicit `epic|story|task` pick; an inferred level is surfaced for confirmation; and
  the canonical tier is shown **resolved to the tracker's concrete issue-type** in the preview
  (with graceful degradation noted when the tracker lacks that tier). An optional `--parent <ref>`
  (or an inferred parent) is shown in the preview and linked via the provider's native hierarchy
  best-effort (noted when the tracker has none). The `--connector`/`--level`/`--parent` flags may
  precede the free-text description in **any order**; the connector comes from `--connector` or the
  resolution ladder (create has no leading-token heuristic), and the whole non-flag remainder is
  the description.
- [ ] Given the user runs `/aid-update-ticket {description|comment|status} …`, when the user
  previews and confirms, then only the named part is mutated; and when the part is `status`, the
  target state is validated against the tool's available transitions (an invalid target lists the
  valid options).
- [ ] Given no explicit connector is supplied, when exactly one `issue-tracker` connector is
  registered, then the skill uses it silently; and when two or more are registered, then the skill
  asks the user which to use.
- [ ] Given the user supplies an explicit `<connector>` — a `<stem>:` prefix (read/update) or the
  `--connector <stem>` flag (create) — when the skill resolves the connector, then the explicit
  selector always overrides the connector scan.
- [ ] Given no registered `issue-tracker` connector, when the skill resolves the connector, then
  the host tool's own MCP is attempted; and if none is available, then the user is notified
  "no issue-tracker connector found."

---

## Technical Specification

> Grounded in `architecture.md` (skill state-machine model; canonical→profiles render; connectors = catalog, not a connection manager), `authoring-conventions.md` (prose-over-scripts; content isolation; P1(d)-SIG inline contracts), `connectors/consumption-protocol.md` (MCP-first consumption), and `state-machine-chaining.md` (Advance types; "questions belong in AskUserQuestion"). All artifacts are authored in **`canonical/`** (the single editable source) and rendered to the five profiles by feature-005; the `.claude/` copies are build output.

### Data Model

**No schema changes.** The three skills persist nothing in the repo; they read/write the external tracker through the host MCP. The `ticket_ref` LOCAL-LINK already exists in the state/spec templates and is untouched here (its preservation is feature-004/FR-11). No migration.

### Feature Flow

Each skill is a single-invocation prose state machine (**prose-over-scripts** — the logic is arg-parse + a catalog scan + host-MCP consumption; no bash warranted): read makes a single host-MCP fetch and update a single write (after any non-destructive LOAD-CONTEXT read), while create makes **two** calls — a non-destructive issue-type query at LEVEL-RESOLVE, then the file call at FILE. A write (create/update) gates on an in-invocation `AskUserQuestion` confirm **before** the MCP write call — a within-run question, **not** a `PAUSE-FOR-USER-DECISION` (which per `state-machine-chaining.md` exits and resumes on re-invocation); the skill never exits mid-run.

- **aid-read-ticket:** `PARSE-ARGS → RESOLVE-CONNECTOR (see External Integrations) → FETCH (host MCP) → DISPLAY`. Non-destructive; no confirm (AC-1).
- **aid-create-ticket:** `PARSE-ARGS → RESOLVE-CONNECTOR → COMPOSE → LEVEL-RESOLVE → CONFIRM → FILE (host MCP) → RETURN-REF (new <stem>:<external-id>)` (AC-2, FR-2a, FR-2b). **COMPOSE** builds the new-ticket payload from `<description>` and fixes two attributes by precedence, **defaulting neither silently**: the canonical **level** — explicit `--level` › description-inferred (e.g. "this epic…", "bug:") › **unset**; and the **parent** — `--parent <ref>` › description-inferred ("under PROJ-123") › none. **LEVEL-RESOLVE** queries the tracker's available issue-types via the host MCP and maps the canonical tier to the tracker's concrete type (see External Integrations); it is a non-destructive read, so it runs before the gate — to feed the preview when the tier is known, and (when the tier is still unset) to offer the pick against the tracker's real types. **CONFIRM** is the single in-run `AskUserQuestion` gate: when the level is unset/uninferable its pick **is** the `epic|story|task` selection (**folded into this gate**, not a separate pre-prompt); a description-inferred level is surfaced for explicit confirmation; and the preview always shows the concrete **resolved issue-type** (or the graceful-degradation note when the tracker lacks that tier) plus any **parent** link (or a no-hierarchy note) before `[1] File it · [2] Edit · [3] Cancel`. **FILE** writes via the host MCP and sets the provider's native parent link best-effort — only after confirm. Because the whole exchange (including the level pick) is inline `AskUserQuestion`, CONFIRM is a **CHAIN** advance, never a `PAUSE` (`state-machine-chaining.md` § "The four advance types", CHAIN — user interaction that is "fully `AskUserQuestion`-based" is asked and answered inline).
- **aid-update-ticket:** `PARSE-ARGS → RESOLVE-CONNECTOR → LOAD-CONTEXT → COMPOSE → CONFIRM (AskUserQuestion, showing the exact change) → WRITE (host MCP)`. LOAD-CONTEXT per part: `status` → fetch available transitions (Security Specs); `description` → fetch current value for a before/after preview; `comment` → none. `description` **replaces** · `comment` **appends** · `status` **sets** (AC-3).
- **MCP-call failure policy (all three skills):** a failed / not-found / unauthorized / unavailable host-MCP call surfaces the tracker's error verbatim and exits **non-destructively** — a create/update never partial-writes, and a not-found ticket on read/update is reported and the skill exits. (This is the general error path, beyond the narrow status-enumeration case in Security Specs.)

### Layers & Components

Three peer skills authored under `canonical/skills/`, each a `SKILL.md` state machine (+ `references/state-*.md` as needed):

| Skill dir (canonical) | Role |
|---|---|
| `canonical/skills/aid-read-ticket/` | fetch + display a ticket |
| `canonical/skills/aid-create-ticket/` | file a new ticket |
| `canonical/skills/aid-update-ticket/` | mutate description / comment / status |

- **Shared reference (DRY, decision 1):** the resolution ladder + grammar-parse + confirm conventions live once in a new shared template `canonical/aid/templates/connectors/ticket-resolution.md`; each `SKILL.md` points to it by a short additive pointer (the pattern skills already use for `shortcut-engine.md` / `consumption-protocol.md`). The three skills never re-describe the ladder inline.
- **Classification (decision 2):** on-demand utility skills, peers of `aid-query-kb` / `aid-set-connector` — **no `shortcut-catalog.yml` entry, no `work-NNN` scaffold, no per-skill STATE.md**; invoked directly by name.
- **SKILL.md frontmatter (each):** `name`; `description` (one-pass summary, `aid-query-kb` style); `allowed-tools: Read, Glob, Grep, AskUserQuestion` — Read/Glob/Grep scan `.aid/connectors/INDEX.md`; **`AskUserQuestion`** drives the connector-choice prompt and the create/update confirm (the create confirm also carries the `epic|story|task` **level pick** when the level is neither explicit nor inferable — Feature Flow) (declared because the peers that gate on a choice — `aid-set-connector`, `aid-config` — declare it); the host-MCP tools are requested at runtime per `consumption-protocol.md`, not statically declared; **no `Write`/`Edit`** (the skills persist nothing in the repo — `ticket_ref` recording is done by the ingest seams, not here). `argument-hint` = the grammar line (API Contracts).
- **Content isolation:** `aid-` prefix (satisfied by the names); the shared reference lives under the `aid/` template subtree.

### API Contracts (command grammar — P1(d)-SIG, stated inline)

| Skill | `argument-hint` | Tokens |
|---|---|---|
| `aid-read-ticket` | `[<connector>:]<ticket-id>` | optional `stem:` prefix + one id token |
| `aid-create-ticket` | `[--connector <stem>] [--level epic\|story\|task] [--parent <ref>] <description>` | optional connector/level/parent flags (any order) + free-text description |
| `aid-update-ticket` | `<part> [<connector>:]<ticket-id> <content>` | `part` ∈ `{description, comment, status}` + `[stem:]id` ref + free-text content |

Parse rules (deterministic):
- **read/update ref:** contains a `:` → split on the first `:` (`<stem>` selects the connector, remainder = `<external-id>`); else the whole token is the id and the connector is resolved by the ladder (External Integrations).
- **update:** the first whitespace token is `part` (closed enum — reject anything else with the usage line); the second token is the ref; everything after is `<content>` (free text, may contain spaces/colons — never re-parsed).
- **create flags & description (resolves FR-2 / FR-2a / FR-2b / Q2 — decided here, not deferred):** create takes up to three optional flags — **`--connector <stem>`**, **`--level <tier>`**, **`--parent <ref>`** — in **any order** before the trailing free-text `<description>`. Flags are parsed regardless of position; once they are consumed the **whole non-flag remainder is the `<description>`** verbatim (flags are never re-parsed out of the description body, so a description may itself contain the word "level", a `PROJ-1`-shaped token, or a word that matches a catalogued stem). Per flag:
  - **`--connector <stem>`** selects the connector; absent the flag the connector is resolved by the FR-4 ladder (External Integrations). Create has **no bare-leading-token connector heuristic** — unlike read/update, which keep their `[<connector>:]<ticket-id>` colon form, create's connector comes only from `--connector` or the ladder, so a description that legitimately begins with a stem-matching word is never mis-read as a selector.
  - **`--level <tier>`** takes the **closed canonical enum `epic|story|task`** (case-insensitive) **or** a quoted literal provider-type passthrough (`--level "Sub-task"`). A bare value that is neither one of the three tiers nor quoted is **rejected with the usage line**; a quoted value is passed through verbatim as a literal tracker type (bypassing synonym resolution — External Integrations). `--level` is **optional and has no default** — when omitted the level is inferred from the description or asked at the confirm gate (Feature Flow).
  - **`--parent <ref>`** takes one ticket ref (`[<stem>:]<external-id>`, resolved on the same connector); optional. A parent may instead be inferred from the description ("under PROJ-123"); `--parent` wins when both are present.
- Missing/empty required args (no `<description>` after the flags) → print the `argument-hint` usage line and exit (the `aid-query-kb` pre-flight pattern).

### External Integrations

Connector resolution — the shared `ticket-resolution.md` ladder (first match wins), consumed MCP-first:

1. **Explicit `<connector>`** (read/update prefix; create `--connector` flag) → validate it names a catalogued connector tagged `issue-tracker`; an unknown/ineligible stem → error out (no silent fall-through).
2. **Scan `.aid/connectors/INDEX.md`** for rows whose Type is `mcp` **and** whose tags include `issue-tracker` (the same purpose-match `consumption-protocol.md` uses): exactly one → **use it silently**; two or more → `AskUserQuestion` listing the candidate stems.
3. **None catalogued** → request the **host tool's own** issue-tracker MCP (host-owned; AID wires nothing).
4. **Neither available** → notify `"no issue-tracker connector found."` and exit (AC-6).

- **MCP-first (FR-5):** the fetch/file/update is performed by requesting the connection from the host tool's own MCP per `consumption-protocol.md`; **AID resolves no credential and stores none**.
- **Level resolution (create only, FR-2a) — canonical tier → tracker issue-type at runtime.** Once the connector resolves, `aid-create-ticket` queries the tracker's available issue-types through the host MCP (`consumption-protocol.md` § "The seam recipe (generic shape)" step 3 — "Request the connection from the host tool"; the host owns the call) and maps the canonical tier to a concrete type by an **ordered synonym set, first available wins**: `epic` → Epic / Initiative / Feature / Theme…; `story` → Story / User-Story / Issue / Requirement…; `task` → Task / Sub-task / To-do / Chore…. Resolution precedence: (a) a **quoted literal passthrough** (`--level "Sub-task"`) **skips synonym-matching entirely** and requests that exact provider type — the escape hatch for finer per-tracker control; (b) otherwise the ordered synonym set decides. A **persistent per-connector tier→type override is a deferred follow-up** — it would require a new connector-descriptor field, which REQUIREMENTS §4 puts out of scope and which the Data Model's "No schema changes" rules out here (same deferral posture as the api-consumption / no-mcp-preset realities); the literal passthrough covers the exact-control need in the meantime. **Graceful degradation:** a tracker whose type set matches no tier — e.g. a flat tracker such as GitHub Issues, which has no native issue-type field — files a **plain issue** and optionally applies a `type:<tier>` label; the confirm preview shows the **concrete resolved type** (or the "filed as a plain issue — this tracker has no `<tier>` type" degradation note), so the outcome is never silent. As with the ladder above, no `mcp` `issue-tracker` preset ships today (see Catalog reality), so this path activates once a user registers a custom `mcp` tracker; until then create reaches the host-MCP / notify rungs like read/update.
- **Parent resolution (create only, FR-2b) — best-effort native hierarchy.** A `--parent <ref>` (or a description-inferred parent) is resolved on the **same** connector, then linked via the provider's **native** hierarchy — Jira parent / epic-link, Azure Boards parent-child, GitHub sub-issue, … — **best-effort**: a tracker with no hierarchy concept (or a link the provider rejects) is **noted in the preview and does not fail the create** (the ticket is still filed; the missing link is reported, not fatal). The parent is shown in the preview and applied **only** as part of the post-confirm FILE write.
- **`api`/`ssh`/`cli` fall-through:** a registered connector whose `connection_type` ≠ `mcp` is not live-consumable in this feature; step 2 skips it (Type ≠ `mcp`), so resolution continues to step 3/4. When such a connector is the *only* `issue-tracker` match, tell the user it is registered but not live-consumable (MCP-first; api consumption is the deferred follow-up) before falling through.
- **Catalog reality (acknowledged):** the shipped `preset-catalog.md` presets yield **no** `mcp` `issue-tracker` today — the **only** `issue-tracker`-tagged preset is `jira`, which is `api`-typed; `gitlab` and the `mcp`-typed `github` are both tagged `source-host`, not `issue-tracker`. So the "silent single-match" path (step 2) activates once a user registers a **custom `mcp` issue-tracker** connector — e.g. an Atlassian/Jira or GitHub-issues MCP — which is the intended day-one usage; until then resolution reaches step 3 (host MCP) or step 4 (notify). This is expected, not a defect.

### Security Specs

- **No silent outward interaction (NFR-2, FR-6):** `create`/`update` MUST render the **exact** payload and require an explicit `AskUserQuestion` confirm before the MCP write; `read` is non-destructive → no prompt.
- **Level pick & parent stay inside the existing confirm (FR-2a/FR-2b, NFR-2):** determining the level adds **no new silent behavior and no new write** — querying the tracker's available types and resolving the tier→type mapping are **non-destructive reads**, and when no tier is explicit or inferable the **existing** create confirm gate requires the `epic|story|task` pick (no default is ever assumed, and no separate pre-write prompt is added). The parent link is shown in the preview and applied **only** as part of the single post-confirm MCP write. Nothing about level or parent reaches the tracker before the user confirms.
- **Status-transition validation (decision 4, FR-3):** if the tracker MCP can enumerate the ticket's available transitions, validate the requested `status` against them and, on mismatch, list the valid targets and stop; if the MCP cannot enumerate transitions, attempt the transition and surface the tracker's own error verbatim.
- **Failure is non-destructive** (see Feature Flow's MCP-failure policy): an MCP error never leaves a partial write.
- **Credentials:** none — the host tool owns auth (`architecture.md` "connectors registry is a CATALOG"). The skills never read, store, or log a secret.

### Testing

Behavior tests fit `test-landscape.md` (a `tests/canonical/test-ticket-skills-*.sh` suite in the run-all glob). Because the host MCP + a live tracker are unavailable in CI, tests are **structural / parse-level**, not live-call:
- each `SKILL.md` carries the required frontmatter (incl. `AskUserQuestion` in `allowed-tools`) and the Feature-Flow states;
- grammar parse cases: read `id` and `stem:id`; update `part` enum accept/reject; create `--connector` flag (no leading-token heuristic — a description beginning with a stem-matching word stays wholly the description); create `--level` enum **accept** (`epic`/`story`/`task`, case-insensitive) / **reject** (a bare non-tier value → usage line) / quoted literal passthrough (`--level "Sub-task"`); create `--parent <ref>`; and **flags in any order** before the description (each of `--connector`/`--level`/`--parent` parsed regardless of position, with the whole non-flag remainder taken verbatim as the description);
- resolution-ladder branch coverage: 0 / 1 / 2+ `issue-tracker` connectors; explicit-override wins; `api`-type fall-through; the `"no issue-tracker connector found."` notify string;
- create level & parent behavior: **no `--level`** → the pick is carried on the confirm gate (never a silent default); a **description-inferred** level is surfaced for confirmation (not silently applied); **tier → tracker-type resolution** via the ordered synonym set (first available wins) with the quoted-literal passthrough override, and **graceful degradation** to a plain issue + optional `type:<tier>` label with the resolved type shown in the preview; **`--parent`** sets the native link when the tracker supports one and **falls back to a preview note** (create still succeeds) when it does not;
- confirm gate present in create/update, absent in read.

Byte/path-parity of the rendered copies is feature-005's gate, not duplicated here.

### Boundaries (this feature only)

feature-001 delivers **only** the three skills + the shared `ticket-resolution.md`. It does **not** retract PM-TOOL writes (feature-002), reroute existing seams (feature-003), revise `consumption-protocol.md` (feature-004), or update the KB / run the render (feature-005) — though the reroute/propagation features depend on these skills existing first. `api`/`ssh`/`cli` live consumption is out of scope (deferred).
