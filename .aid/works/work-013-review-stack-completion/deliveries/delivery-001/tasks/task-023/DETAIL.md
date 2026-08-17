# task-023: Template authoring-standard checks widened to the whole template tree

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

**Source:** work-013-review-stack-completion -> delivery-001

**Depends on:** task-009

**Scope:**
- `tests/canonical/test-kb-template-authoring-standard.sh`: widen the history-section corpus from the knowledge-base template subdirectory to every markdown file under `canonical/aid/templates/`.
- Add the fixture the widening needs, since the live before/after no longer exists.

**Acceptance Criteria:**
- [ ] The corpus size is asserted before and after with both `find … | wc -l` commands recorded — the narrow corpus is a small fraction of the wide one.
- [ ] A template-shaped fixture carrying a history section is caught by the wide corpus and missed by the narrow one, which is what proves the widening did something.
- [ ] The widened check exits `0` against the real tree, because the history sections were already removed — so the fixture, not the tree, is the proof.
- [ ] Baseline failure count unchanged.
- [ ] All section-6 quality gates pass
