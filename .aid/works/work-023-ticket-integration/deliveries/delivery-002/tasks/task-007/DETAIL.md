# task-007: Reroute the connector read seams to /aid-read-ticket

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** REFACTOR

**Source:** work-023-ticket-integration -> delivery-002

**Depends on:** task-006

**Scope:**
- Reroute the pure-read CONNECTORS seams (feature-003 §Feature-Flow (a) + the two agent defs) so each delegates the fetch to `/aid-read-ticket` instead of re-implementing its own scan -> confirm -> fetch, editing `canonical/` only; each keeps the LOCAL-LINK `ticket_ref` it already records; a user-supplied ref is the authorization and reads are non-destructive, so no extra prompt is added:
  - `canonical/skills/aid-describe/references/state-first-run.md` -- "1e. Connector awareness -- record a source ticket's `ticket_ref` (optional)" (records at work).
  - `canonical/skills/aid-specify/references/state-initialize.md` -- "Step 3b: Connector awareness -- record this feature's `ticket_ref` (optional)" (records the `**Ticket:**` line at feature).
  - `canonical/aid/templates/shortcut-engine.md` -- "Step 4b: Connector awareness -- record a source ticket's `ticket_ref` (optional)" (`aid-fix` + all sibling shortcuts).
  - `canonical/skills/aid-query-kb/SKILL.md` -- "Step 2c -- Connector enrichment (optional)".
  - `canonical/agents/aid-developer/AGENT.md` -- the `## What You Do` bullet beginning `Consult .aid/connectors/INDEX.md` -> re-point to the single shared read recipe `/aid-read-ticket` embodies (a dispatched sub-agent cannot issue a host slash command; reference the shared `ticket-resolution.md` ladder + MCP-first read, no divergent inline re-implementation).
  - `canonical/agents/aid-researcher/AGENT.md` -- the same `Consult .aid/connectors/INDEX.md` bullet.
- Each seam names `/aid-read-ticket` as the fetch surface and carries NO inline direct-fetch recipe of its own (the "request the connection from the host tool's own MCP" step is removed at the seam). No file gains a new `allowed-tools` / `tools` grant. Advance types unchanged.
- EXCLUDES the two dual-anchor files (`aid-plan/references/first-run-loop.md` Step 4c and `aid-review/SKILL.md`), which carry BOTH a read-reroute and a write-reroute -- both are owned by task-008 so each dual-anchor file stays within one task.

**Acceptance Criteria:**
- [ ] Each of the four pure-read seam anchors + the two agent bullets routes its fetch through `/aid-read-ticket` and re-implements no direct host-MCP fetch (AC-9).
- [ ] Each rerouted read seam preserves its existing `ticket_ref` LOCAL-LINK recording (FR-11) and adds no confirm prompt (reads are non-destructive) (AC-9).
- [ ] No file gains a new `allowed-tools` / `tools` grant (feature-003 §Layers).
- [ ] NFR-3: a project with no `issue-tracker` connector and no `ticket_ref` silent-skips each rerouted seam identically to before.
- [ ] Edits are authored in `canonical/` only; the reroute targets exist because delivery-001 landed first (PLAN.md ordering). The reroute is a same-behavior structural change (the seam still reads a ticket; only where the recipe lives moves), so REFACTOR's no-behavior-change intent holds for the read side.
- [ ] All section-6 quality gates pass.
