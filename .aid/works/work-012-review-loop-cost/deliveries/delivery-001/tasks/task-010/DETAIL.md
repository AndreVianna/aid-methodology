# task-010: Guard 2: contradiction pass on cycle 1 of each multi-artifact review

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml.

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

**Type:** IMPLEMENT

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-008

**Scope:**
- `canonical/aid/templates/reviewer-dispatch.md`: declare the cross-document contradiction pass as a phase-level activity, run on CYCLE 1 of any review whose ARTIFACTS span more than one artifact.
- Its three invocation sites: `canonical/skills/aid-define/references/state-cross-reference.md`, `canonical/skills/aid-plan/references/review-deliverables.md`, `canonical/skills/aid-detail/references/review.md`.
- `aid-specify` gets NO invocation -- it dispatches per artifact, so no single specify review could see a cross-feature contradiction; its specs are covered at `aid-plan`'s review.
- Authored instruction only.

**Acceptance Criteria:**
- [ ] The pass is declared once in `reviewer-dispatch.md` and invoked at exactly the three named sites
- [ ] Each invocation is pinned to cycle 1, so the pass runs once per phase by construction with no last-artifact detection
- [ ] `aid-specify` carries no Guard 2 invocation, and the reason is recorded where a reader would otherwise add one
- [ ] The pass itself is unchanged in substance -- only its cadence moves (NFR-4: no guarantee traded for cost)
- [ ] The residual window (a contradiction introduced by the pass's own fix) is stated and routed to FR-6's final full pass
- [ ] All REQUIREMENTS.md §6 quality gates pass
