# task-011: Discovery-guidance edit -- drop the PM "entity mapping" clause

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

**Type:** DOCUMENT

**Source:** work-023-ticket-integration -> delivery-003

**Depends on:** -- (none in-delivery; runs after delivery-002 per PLAN.md ordering)

**Scope:**
- In `canonical/skills/aid-discover/references/document-expectations.md`, the `### infrastructure.md` block's "Project Management section" investigation parenthetical currently reads `Project Management section -- tool or "none", access method, entity mapping if applicable`. Delete ONLY the `, entity mapping if applicable` clause, leaving `Project Management section -- tool or "none", access method` (feature-005 §Feature-Flow (a); AC-13).
- Keep the lead open question ("what project management tool is used (or say 'none')?") and the red flag ("Project Management section absent -- should explicitly say 'none' if no tool is used") verbatim; no other line in the `### infrastructure.md` block changes. Durable anchor: `document-expectations.md` `### infrastructure.md`, the "Project Management section" investigation slot.
- Authored in `canonical/` (this is a rendered source file; it is rendered to all five profiles by task-013's terminal render -- do NOT hand-edit `profiles/*` or the dogfood `.claude/` here).

**Acceptance Criteria:**
- [ ] `document-expectations.md` `### infrastructure.md` no longer contains `entity mapping`, and still contains `tool or "none"` + `access method`; no other line in that block changed (AC-13).
- [ ] The lead open question and the red flag are kept verbatim (feature-005 §Feature-Flow (a)).
- [ ] The edit is authored in `canonical/` only (rendered by task-013; byte/path-parity verified by task-014).
- [ ] Accuracy verified against the current on-disk `### infrastructure.md` block (DOCUMENT: accuracy-against-source).
- [ ] All section-6 quality gates pass.
