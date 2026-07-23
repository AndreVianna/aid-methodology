# task-006: Retire the six PM-TOOL automated-write sites

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

**Depends on:** -- (none in-delivery; runs after delivery-001 per PLAN.md ordering, so the three ticket skills + shared `ticket-resolution.md` exist as the suggestion targets)

**Scope:**
- Apply the per-site retraction procedure (feature-002 §Feature Flow) to the six FR-7 sites, editing `canonical/` only; re-verify each signature against disk before editing (grep the class, don't fix only a cited line):
  1. `canonical/skills/aid-describe/references/state-completion.md` -- Step 5 `[1] Approved` bullet `create an Epic for this work` -> SUGGEST `/aid-create-ticket` (file an epic-type ticket).
  2. `canonical/skills/aid-detail/references/task-decomposition.md` -- `## Project Management Sync (conditional)` -> MIXED: SUGGEST `/aid-create-ticket` for the create half; REMOVE OUTRIGHT the link-each-to-Sprint/Epic bullet.
  3. `canonical/skills/aid-plan/SKILL.md` -- `## Project Management Sync (conditional)` -> REMOVE OUTRIGHT the whole Sprint/Iteration section (a Sprint/Iteration is not a ticket; no suggestion).
  4. `canonical/skills/aid-execute/SKILL.md` -- `## Project Management Sync (conditional)` -> SUGGEST `/aid-update-ticket status` (In Progress -> Done) + `/aid-update-ticket comment`.
  5. `canonical/skills/aid-deploy/references/state-packaging.md` -- `### Step 8: Project Management Sync (conditional)` -> MIXED: SUGGEST `/aid-update-ticket status` for mark-Done/Closed; REMOVE OUTRIGHT the Create-a-Release + link-to-Epic bullets.
  6. `canonical/skills/aid-monitor/references/state-route.md` -- `### Step 6: Update State` PM-tool block -> MIXED: SUGGEST `/aid-create-ticket` for the BUG-ticket create half; REMOVE OUTRIGHT the link-to-Sprint/Epic bullet + the `▶/✓` PM-tool timing scaffolding.
- Remove the `If infrastructure.md § Project Management defines a tool: ... / If no PM tool -> skip` guard TOGETHER with each write (no dormant path survives; "Resolved Items Leave No Trace" -- delete outright, no tombstone).
- Each surviving suggestion is optional / user-initiated (mirroring the `aid-report`/`aid-research` HANDOFF wording), GATED on at least one catalogued `issue-tracker`-tagged connector in `.aid/connectors/` (silent -- byte-identical to pre-change output -- when none), re-keys off the connectors catalog, and never re-introduces the PM guard. Advance types unchanged at every site; no site adds a HANDOFF state.
- Excludes the CONNECTORS-generation signatures (aid-execute's `state-execute.md` mirror; aid-plan `first-run-loop.md` Step 4c) -- a different signature class owned by task-007/008.

**Acceptance Criteria:**
- [ ] Each of the six FR-7 sites is retired at its named anchor per the feature-002 §Feature-Flow disposition table (per-site check, not only grepped); the automated-write bullets and their guard are gone (AC-7).
- [ ] A grep across the six skill dirs for the automated-write signatures ("create an Epic", "create Tickets/Work Items", "create Sprint/Iteration", "Map deliveries to Sprints", "update ... ticket to In Progress/Done", "add comment to ticket", "mark as Done/Closed", "Create a Release in the PM tool", "create tickets for BUG", "link ... Epic") plus the guard signatures ("If infrastructure.md § Project Management defines a tool", "If PM tool configured", "If no PM tool -> skip") returns zero (AC-7).
- [ ] Where a removed write has a ticket-scoped analog a printed dedicated-skill suggestion is left in its place -- optional / user-initiated and gated on a catalogued `issue-tracker` connector (silent when none); no-analog actions (Release-create, Sprint/Iteration-create, link-to-Sprint/Epic) are removed outright with no suggestion (AC-7).
- [ ] A project with no catalogued `issue-tracker` connector sees output byte-identical to pre-change at every retired site (NFR-3 / AC-10).
- [ ] Edits are authored in `canonical/` only (no `profiles/*` or dogfood `.claude/` hand-edit); the behavior change (writes retired) is intentional, so REFACTOR's "no behavior change" / "tests pass before AND after" defaults are superseded by the FR-7 retirement criteria above (verification is per-site review + zero-signature grep -- task-010).
- [ ] All section-6 quality gates pass.
