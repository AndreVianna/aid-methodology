# task-010: Structural verification of the retire + consolidate + revise edits

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

**Type:** TEST

**Source:** work-023-ticket-integration -> delivery-002

**Depends on:** task-009

**Scope:**
- Structural verification of the retire + consolidate + revise edits (feature-002 / feature-003 / feature-004 §Testing), grepping `canonical/` only (never `.claude/`, which is render output):
  - **AC-7 (feature-002):** per-site retirement check (all six sites); zero-signature grep (PM-TOOL write signatures + the guard signatures -> 0); suggestion-shape + conditionality (correct dedicated skill named; optional / user-initiated; gated on a catalogued `issue-tracker` connector, silent when none; no re-introduced PM guard).
  - **AC-8 (feature-003):** `state-execute.md` has no "## Connector Mirroring" section and no outward-mirror signature; `first-run-loop.md` Step 4c carries the printed `/aid-create-ticket` suggestion and no `create/register it via a catalogued issue-tracker connector` outward-file signature; outward create/mirror actions occur only via the dedicated skills.
  - **AC-9 (feature-003):** each of the six read-seam anchors + the two agent bullets (incl. aid-plan Step 4c's record half) names `/aid-read-ticket` and carries no inline direct-fetch recipe of its own.
  - **AC-11 (feature-004):** `consumption-protocol.md` -- `grep -i mirror` -> 0; the `aid-execute` Target row is gone; the linkage + nearest-ancestor sections are retained; reads-delegate / writes-route stated inline.
  - **AC-10 / NFR-3:** a fixture project with no `issue-tracker` connector and no `ticket_ref` exercises each edited seam and confirms silent-skip (no error, no prompt, output byte-identical to pre-change); `ticket_ref` only ever from a user-supplied ref.
- Per feature-002 §Testing these six prose edits are "Not machine-tested (by design) -- dogfooding + human/AI review only": verification is mechanical grep spot-checks + per-site human/AI review, NOT a new `run-all.sh` suite. Any structural helper script authored lives under `tests/canonical/` and MUST NOT reference any `.aid/works/work-023*` path (work-folder-transience rule).

**Acceptance Criteria:**
- [ ] AC-7 verified: per-site retirement confirmed for all six sites; the zero-signature grep across the six skill dirs (write + guard signatures) returns zero; dispositions match the feature-002 §Feature-Flow table.
- [ ] AC-8 verified: no aid-execute status-mirror and no aid-plan auto-file remain; outward create/mirror/comment occur only via the dedicated skills.
- [ ] AC-9 verified: every remaining read seam + both agent bullets (incl. aid-plan Step 4c record half) delegate to `/aid-read-ticket` with no inline direct fetch.
- [ ] AC-11 verified: `consumption-protocol.md` has no automated file/mirror/comment seam; linkage + nearest-ancestor retained; reads-delegate / writes-route documented.
- [ ] AC-10 / NFR-3 verified: a no-connector / no-`ticket_ref` fixture silent-skips every edited seam (byte-identical to pre-change); `ticket_ref` is only ever from a user-supplied ref.
- [ ] Verification runs against `canonical/` only (not render output); any helper script lives under `tests/canonical/` and does not depend on `.aid/works/work-023*`; checks are deterministic. Byte/path-parity is delivery-003's gate, not asserted here. All section-6 quality gates pass.
