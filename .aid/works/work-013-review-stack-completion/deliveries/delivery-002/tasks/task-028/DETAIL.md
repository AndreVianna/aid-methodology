# task-028: The why-line contract inside the fixed seven columns

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

**Source:** work-013-review-stack-completion -> delivery-002

**Depends on:** task-027

**Scope:**
- `canonical/aid/templates/reviewer-ledger-schema.md`: narrow the Description column's ban on explanation so it admits the consequence clause, and state the severity-provenance tokens the Evidence column carries.
- `canonical/agents/aid-reviewer/AGENT.md`: state the why-line and the divergence record beside the severity rules already there.
- `.aid/knowledge/authoring-conventions.md`: the same contract, stated for authors.
- Re-run the full generator in the same commit.

**Acceptance Criteria:**
- [ ] The why-line form and every provenance token resolve by grep in the schema.
- [ ] The paragraph a suite reads by exact string is **byte-identical** — the contract goes in the column rows, not in the pinned text; both pinned literals still resolve at their recorded lines.
- [ ] The ledger header row still yields exactly one match, and the severity and status enums and the status table are unchanged.
- [ ] `canonical/aid/scripts/grade.sh` is not opened by this task at all — NFR-1's sharpest edge is that the why-line costs the grading script nothing.
- [ ] The generator is re-run in the same commit, `verify_deterministic.py` reports PASS, and the render diff contains only generator-written paths.
- [ ] All section-6 quality gates pass
