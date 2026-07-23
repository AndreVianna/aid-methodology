# Delivery BLUEPRINT -- delivery-002: Retire & consolidate automated ticket integration

> **Delivery:** delivery-002
> **Work:** work-023-ticket-integration
> **Created:** 2026-07-22

---

## Objective

Collapse both generations of automated tracker interaction onto the single sanctioned surface the
delivery-001 skills provide. This delivery retires the older PM-TOOL automated writes across the six
FR-7 sites (feature-002), rewires the newer CONNECTORS read/write seams onto `/aid-read-ticket` /
`/aid-update-ticket` / `/aid-create-ticket` -- removing `aid-execute`'s auto status-mirror, splitting
`aid-plan`'s Step 4c (retire the outward-file half, keep + reroute the record half), and routing the
three human-gated comment writes through `/aid-update-ticket` (feature-003) -- and revises the shared
`consumption-protocol.md` so it describes the read-delegates / writes-via-dedicated-skills model
(feature-004). The three features ship as one increment because FR-6's "single outward surface / no
silent writes" holds only when both generations retire together, and feature-004's protocol doc
describes exactly the model feature-003 implements. After this delivery no skill or agent reaches a
tracker on its own.

## Scope

**In scope:**
- **feature-002-pm-tool-write-retirement** -- retire every `infrastructure.md § Project Management`
  driven write across the six sites (`aid-describe/references/state-completion.md`,
  `aid-detail/references/task-decomposition.md`, `aid-plan/SKILL.md`, `aid-execute/SKILL.md`,
  `aid-deploy/references/state-packaging.md` Step 8, `aid-monitor/references/state-route.md`);
  ticket-scoped analogs -> printed dedicated-skill suggestion (gated on a catalogued issue-tracker
  connector; silent when none); no-analog actions (Release / Sprint-create / link-to-Sprint-or-Epic)
  removed outright.
- **feature-003-connector-seam-consolidation** -- reroute the six CONNECTORS read seams + the two
  agent defs to `/aid-read-ticket`; remove `aid-execute`'s `state-execute.md` Connector-Mirroring
  section outright; split `aid-plan` `first-run-loop.md` Step 4c (outward-file branch -> printed
  `/aid-create-ticket` suggestion; record-for-existing half kept + rerouted via `/aid-read-ticket`);
  reroute the `aid-review` (PUBLISH + INTAKE label), `aid-research`, `aid-report` comment writes
  through `/aid-update-ticket comment`.
- **feature-004-consumption-protocol-revision** -- edit
  `canonical/aid/templates/connectors/consumption-protocol.md` (E1-E7): remove the automated
  file/mirror/comment capability, delete the `aid-execute` Target row, restate reads as delegating
  to `/aid-read-ticket` and writes via the dedicated skills; keep the `ticket_ref` multi-level
  linkage + nearest-ancestor resolution.

**Out of scope:** authoring the three skills or the shared `ticket-resolution.md` (feature-001 /
delivery-001, a hard prerequisite); the KB / discovery-guidance edits and the render +
byte/path-parity + CLI-parity gate (feature-005 / delivery-003). No change to the four
`ticket_ref`-carrying templates (`work-state-template.md`, `delivery-state-template.md`,
`task-state-template.md`, `specs/spec-template.md` -- FR-11 invariant), the connector-descriptor
schema, the catalog lifecycle, `grade.sh`, or the CLI. All edits authored in `canonical/` only.

## Gate Criteria

- [ ] **PM-TOOL retirement (feature-002):** each of the six FR-7 sites is confirmed retired per-site
  (not only grepped) and a grep across the six skill dirs for the automated-write signatures
  ("create an Epic", "create Tickets/Work Items", "create Sprint/Iteration", "update ... ticket to
  In Progress/Done", "add comment to ticket", "mark as Done/Closed", "Create a Release in the PM
  tool", "create tickets for BUG", "link ... Epic") plus the guard signatures ("If infrastructure.md
  § Project Management defines a tool", "If PM tool configured", "If no PM tool -> skip") returns
  zero. (AC-7)
- [ ] **Retirement disposition (feature-002):** where a removed write has a ticket-scoped analog a
  printed dedicated-skill suggestion is left in its place -- optional / user-initiated (mirroring the
  `aid-report`/`aid-research` HANDOFF wording) and gated on a catalogued `issue-tracker` connector
  (silent, byte-identical to pre-change, when none) so a no-tracker project is unchanged (NFR-3);
  no-analog actions (Release-create, Sprint/Iteration-create, link-to-Sprint/Epic) are removed
  outright with no suggestion. (AC-7)
- [ ] **No auto-writes remain (feature-003):** `aid-execute` no longer auto-mirrors status
  (`state-execute.md` Connector-Mirroring section deleted outright; the local `writeback-state.sh`
  State-Write Protocol untouched); `aid-plan` no longer auto-files a tracker item (Step 4c outward-file
  branch -> printed `/aid-create-ticket` suggestion; its record-for-existing half preserved and
  rerouted via `/aid-read-ticket`); those outward actions occur only via the dedicated skills. (AC-8)
- [ ] **All reads delegate (feature-003):** every remaining ticket READ in another skill or agent --
  the six read-seam anchors (`aid-describe` 1e, `aid-specify` 3b, `aid-plan` Step 4c record-half,
  `shortcut-engine` 4b, `aid-query-kb` 2c, `aid-review` REVIEW "Gather evidence") + the
  `aid-developer` / `aid-researcher` agent bullets -- routes through `/aid-read-ticket` and none
  re-implements a direct host-MCP fetch. (AC-9)
- [ ] **Comment writes consolidated (feature-003):** the three human-gated comment writes
  (`aid-review` PUBLISH-on-approval + the INTAKE tentative-delivery label; `aid-research` HANDOFF;
  `aid-report` HANDOFF) are rerouted through `/aid-update-ticket comment`, stay user-authorized, and
  are never auto-invoked.
- [ ] **consumption-protocol.md revised (feature-004):** no automated file/mirror/comment seam
  remains (the `aid-execute` Target row is gone; the "Read or write through the host MCP" line is
  gone; a `mirror` grep returns 0; the Worked-example section describes a read, not a status mirror);
  the `ticket_ref` multi-level linkage + nearest-ancestor resolution are retained (containment-chains
  table + "Why feature outranks delivery" rationale byte-identical apart from E4's reframed opener);
  reads are documented to delegate to `/aid-read-ticket` and writes to the dedicated skills. (AC-11)
- [ ] **Traceability preserved (feature-004):** `ticket_ref` is preserved and only ever populated
  from a user-supplied ref (never auto-created/auto-discovered); the four `ticket_ref`-carrying
  templates are unchanged; a project with no `issue-tracker` connector and no `ticket_ref` behaves
  identically to before (silent skip at every edited seam -- NFR-3). (AC-10)
- [ ] All edits authored in `canonical/` only -- no `profiles/*` or dogfood `.claude/` hand-edits
  (those render ONCE in delivery-003); byte/path-parity is NOT this delivery's gate.
- [ ] All section-6 quality gates pass (`minimum_grade` A+).

## Tasks

_none yet_ (aid-detail fills this later)

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001 (the three skills + the shared `ticket-resolution.md` MUST land first
  -- feature-003/004 reroute onto targets that do not exist until feature-001 ships; otherwise the
  rerouted pointers dangle)
- **Blocks:** delivery-003 (the terminal render must run over these canonical edits)

## Notes

- **Cross-Cutting Risk R2 (PLAN.md).** Three skills -- `aid-describe`, `aid-plan`, `aid-execute` --
  carry BOTH generations at distinct anchors (e.g. `aid-plan/SKILL.md` PM-TOOL Sprint write is
  feature-002; `first-run-loop.md` Step 4c CONNECTORS create/register is feature-003; `aid-execute/SKILL.md`
  PM-TOOL update is feature-002; `state-execute.md` Connector Mirroring is feature-003). Coordinate
  the two retirements within this delivery so both signature classes are cleared and the `aid-plan`
  Step 4c split is applied exactly once. The delivery reviewer verifies both classes together.
- Grep `canonical/` only (never `.claude/`, which is render output) and re-verify each signature
  against disk before editing (fix-everywhere: grep the class, don't fix only a cited line).
- No `issue-tracker` connector is catalogued for THIS repo, so the delivery's own `ticket_ref` is `--`.
