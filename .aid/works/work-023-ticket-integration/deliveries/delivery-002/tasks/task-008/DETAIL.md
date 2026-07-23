# task-008: Retire/reroute the connector write seams + dual-anchor files

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

**Depends on:** task-007

**Scope:**
- Edit the CONNECTORS write seams + the two dual-anchor files (feature-003 §Feature-Flow (b)(c)(d)), `canonical/` only; re-verify each signature against disk before editing:
  - (b) `canonical/skills/aid-execute/references/state-execute.md` -- DELETE the "## Connector Mirroring (`ticket_ref`, optional)" section outright (the nearest-`ticket_ref` resolution + the outward status mirror). The mandatory local `writeback-state.sh` State-Write Protocol is UNTOUCHED. aid-execute then performs zero outward tracker writes (AC-8).
  - (c) `canonical/skills/aid-plan/references/first-run-loop.md` -- SPLIT "4c. Connector awareness -- record this delivery's `ticket_ref` (optional)", applied EXACTLY ONCE (PLAN.md R2): retire the outward "the team wants one filed for it -> create/register it via a catalogued issue-tracker connector" branch -> a printed `/aid-create-ticket` suggestion ("then re-record its ref"); KEEP + reroute the record-for-existing half via `/aid-read-ticket`, recording `ticket_ref` at the delivery level (AC-8 + the AC-9 record-half).
  - (d) `canonical/skills/aid-review/SKILL.md` -- REVIEW-state "Gather evidence" fetch clause (`an issue-tracker MCP to fetch a ticket`) -> `/aid-read-ticket` (AC-9 dual-file read half); PUBLISH-on-approval `a ticket comment via the MCP connector` -> `/aid-update-ticket comment` delivery (the PRESENT-FINDINGS human gate is unchanged); the INTAKE fast-path `ticket comment via an MCP connector` tentative-delivery label -> name `/aid-update-ticket`.
  - (d) `canonical/skills/aid-research/SKILL.md` -- HANDOFF "a source ticket (MCP connector, connectors/consumption-protocol.md)" suggestion clause -> `/aid-update-ticket comment` (printed suggestion only; "Human final say before any commit" preserved).
  - (d) `canonical/skills/aid-report/SKILL.md` -- HANDOFF "comment on a source ticket" suggestion -> `/aid-update-ticket comment` (printed suggestion only).
- Comment writes stay user-authorized and are never auto-invoked. No file gains a new `allowed-tools` grant. Advance types unchanged.

**Acceptance Criteria:**
- [ ] aid-execute no longer auto-mirrors status: the "## Connector Mirroring" section is deleted outright and no outward-mirror signature remains; the local `writeback-state.sh` State-Write Protocol is intact (AC-8).
- [ ] aid-plan Step 4c no longer auto-files a tracker item (the outward-file branch is a printed `/aid-create-ticket` suggestion) and its record-for-existing half is preserved + rerouted via `/aid-read-ticket` at the delivery level; the split is applied exactly once (AC-8 / AC-9; PLAN.md R2).
- [ ] The three human-gated comment writes (aid-review PUBLISH + the INTAKE label; aid-research HANDOFF; aid-report HANDOFF) route through `/aid-update-ticket comment`, stay user-authorized, and are never auto-invoked (feature-003 §Feature-Flow (d)).
- [ ] The aid-review REVIEW fetch clause routes through `/aid-read-ticket` with no inline direct fetch (AC-9 dual-file read half).
- [ ] A grep across the CONNECTORS seams confirms outward create/mirror/comment actions occur ONLY via the dedicated skills (AC-8); NFR-3 silent-skip preserved on a no-connector/no-`ticket_ref` project.
- [ ] This task INTENTIONALLY removes automated behavior (the `aid-execute` Connector-Mirroring section is deleted outright; the `aid-plan` Step 4c outward-file/create-register branch is retired), so REFACTOR's "no behavior change" / "tests pass before AND after" defaults are SUPERSEDED here -- this is a deliberate behavioral retirement, and correctness is verified by this task's own removal/reroute ACs above plus the delivery-002 TEST (task-010), not by "behavior identical before/after". (The comment-write reroutes and the read-half rerouting are behavior-preserving; the override applies to the mirror/auto-file retirement.)
- [ ] Edits are authored in `canonical/` only; the reroute targets exist because delivery-001 landed first. All section-6 quality gates pass.
