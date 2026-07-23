# Delivery BLUEPRINT -- delivery-001: Dedicated ticket skills

> **Delivery:** delivery-001
> **Work:** work-023-ticket-integration
> **Created:** 2026-07-22

---

## Objective

Deliver the three explicit, tool-agnostic, user-invoked ticket commands -- `/aid-read-ticket`
(fetch + display a ticket's fields), `/aid-create-ticket` (file a new ticket), and
`/aid-update-ticket` (replace description / append comment / set status) -- as standalone-functional
`canonical/` skill state machines, together with the shared connector-resolution ladder
(`canonical/aid/templates/connectors/ticket-resolution.md`) they all consume. These three skills
become the single sanctioned surface through which any outward tracker interaction is started; every
read is authorized by an explicit user-supplied ref and every write previews-and-confirms before it
reaches the tracker. This delivery is the dependency foundation: features 002-004 (delivery-002)
reroute existing seams onto these skills and cannot land until the skills and the shared ladder
exist.

## Scope

**In scope (feature-001-dedicated-ticket-skills):**
- Three peer skills authored under `canonical/skills/` -- `aid-read-ticket/`, `aid-create-ticket/`,
  `aid-update-ticket/` -- each a `SKILL.md` prose state machine (+ `references/state-*.md` as
  needed) with frontmatter (`name`; one-pass `description`; `allowed-tools: Read, Glob, Grep,
  AskUserQuestion`; `argument-hint` = the grammar line) and the Feature-Flow states.
- The shared reference `canonical/aid/templates/connectors/ticket-resolution.md` -- the
  resolution ladder + grammar-parse + confirm conventions, DRY, pointed to by each `SKILL.md`.
- The locked grammar (FR-1/FR-2/FR-3), connector-resolution ladder (FR-4), MCP-first consumption
  (FR-5), the create `--level` (no default; ask at confirm gate) / `--parent` behavior (FR-2a/2b),
  and the write-preview/confirm gate (NFR-2).
- Structural / parse-level tests (`tests/canonical/test-ticket-skills-*.sh`, in the run-all glob).

**Out of scope:** retracting PM-TOOL writes (feature-002 / delivery-002); rerouting existing seams
or removing `aid-execute`'s status-mirror (feature-003 / delivery-002); revising
`consumption-protocol.md` (feature-004 / delivery-002); the KB / discovery-guidance edits and the
render + byte/path-parity gate (feature-005 / delivery-003). Live consumption of
`api`/`ssh`/`cli` connectors (deferred follow-up). No connector-descriptor schema change; no
per-connector `level_map`.

## Gate Criteria

- [ ] The three skills exist as `canonical/` `SKILL.md` state machines with the required frontmatter
  (incl. `AskUserQuestion` in `allowed-tools`, `argument-hint` = the grammar line) and the
  Feature-Flow states; each points to the shared `ticket-resolution.md`, which exists and describes
  the ladder once (no inline re-description). (AC-1..AC-6 anatomy)
- [ ] `/aid-read-ticket [<connector>:]<ticket-id>` fetches via the resolved connector's host MCP and
  displays the ticket's fields; performs **no** external write; shows **no** confirmation prompt. (AC-1)
- [ ] `/aid-create-ticket` files a ticket **only after** a preview of exactly what will be sent and
  an explicit user confirm, then returns the new `<connector-stem>:<external-id>`; the **level** is
  never silently defaulted (absent `--level` and uninferable -> the confirm gate requires an explicit
  `epic|story|task` pick; an inferred level is surfaced for confirmation; the canonical tier is shown
  resolved to the tracker's concrete issue-type, with a graceful-degradation note when the tracker
  lacks that tier); an optional `--parent` (or inferred parent) is shown in the preview and linked
  best-effort via the provider's native hierarchy (noted when none); `--connector`/`--level`/`--parent`
  may precede the free-text description in any order, and create has no bare-leading-token connector
  heuristic. (AC-2, FR-2a, FR-2b)
- [ ] `/aid-update-ticket {description|comment|status} [<connector>:]<ticket-id> <content>` mutates
  **only** the named part after preview + confirm (`description` replaces, `comment` appends,
  `status` sets); a `status` target is validated against the tool's available transitions and an
  invalid target lists the valid options. (AC-3)
- [ ] Connector-resolution ladder: with exactly one `issue-tracker` connector and no explicit
  connector the skill uses it silently; with two or more it asks which; an explicit `<connector>`
  (a `<stem>:` prefix for read/update or `--connector <stem>` for create) always overrides the scan;
  with none catalogued the host tool's own MCP is attempted; with neither available the user is
  notified `"no issue-tracker connector found."` (AC-4, AC-5, AC-6)
- [ ] Structural / parse-level tests pass: grammar cases (read `id` and `stem:id`; update `part`
  enum accept/reject; create `--connector`/`--level` accept-reject/quoted-passthrough/`--parent`,
  flags in any order); resolution-ladder branch coverage (0 / 1 / 2+ connectors, explicit override,
  `api` fall-through, the notify string); confirm gate present in create/update, absent in read.
- [ ] All section-6 quality gates pass (`minimum_grade` resolves to the project floor A+).

## Tasks

_none yet_ (aid-detail fills this later)

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** -- (none) -- foundation delivery
- **Blocks:** delivery-002 (features 002-004 reroute onto these skills + the shared
  `ticket-resolution.md`, which do not exist until this delivery ships)

## Notes

- All edits are authored in `canonical/` (the single editable source); the `.claude/` + five
  `profiles/*` copies are build output re-rendered ONCE by delivery-003 (feature-005) -- this
  delivery hand-edits none of them, and byte/path-parity is NOT this delivery's gate (see PLAN.md
  Cross-Cutting Risk R3).
- No `mcp` `issue-tracker` preset ships today (the only `issue-tracker`-tagged preset, `jira`, is
  `api`-typed), so the silent-single-match path activates once a user registers a custom `mcp`
  tracker; until then resolution reaches the host-MCP / notify rungs. This is expected, not a defect.
- There is no `issue-tracker` connector catalogued for THIS repo (`.aid/connectors/INDEX.md` empty),
  so the delivery's own `ticket_ref` is `--` (no ticket filed for it).
