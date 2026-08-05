# task-003: feature-002 Stage 2a -- the parametric frame-time response surface

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-003/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** RESEARCH

**Source:** feature-002-graph-rendering-research -> delivery-001 (Wave 1)

**Depends on:** -- (none)

**Scope:**
- feature-002 D2b and D4, unblocked by Stage 1: `research/rendering-stage1-webgl-probe.md` records
  L1/L2/L3 all passing on a software rasteriser, so the WebGL-under-headless precondition is met
  and no escalation from D1a fires.
- Measure frame time against the five axes D2b names — node count, edge count, maximum degree,
  category count (including D4a's fourteen-category filtering case, which feature-001 Open Item 11
  routed here) and hover-label count — using D4b's headless frame-time predicate.
- Fixtures are self-built by D3's generator and are `relationships.md` files in the delivered
  ten-column shape, not a bespoke JSON graph (FR-3, AC-10).
- Produces D4's per-measurand verdicts and the response surface Stage 2b (task-010) then applies to
  a derived bench. The harness is throwaway; nothing from it ships.

**Acceptance Criteria:**
- [ ] Per-measurand verdicts recorded for all five axes, each with the conditions it was measured
      under
- [ ] **AC-S3 respected: no bench size is stated, anywhere in the output.** That is this feature's
      own named failure mode
- [ ] Every fixture is a ten-column `relationships.md`; no fixture depends on this repository's own
      Knowledge Base (FR-8a — the derivation is a portable procedure, not a property of this repo)
- [ ] The frame-time predicate used is D4b's, cited by section, not a re-invented one
- [ ] The harness is declared throwaway and no part of it is added to `canonical/` or `tests/`
- [ ] Node.js >= 20 floor honoured (C-5); browser absence degrades with an actionable message
- [ ] Written to `deliveries/delivery-001/research/`
- [ ] All section-6 quality gates pass
