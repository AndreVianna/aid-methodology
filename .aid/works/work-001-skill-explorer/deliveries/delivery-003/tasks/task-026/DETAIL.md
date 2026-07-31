# task-026: Inline `## State:` extractor

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-026. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-026/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-020, task-021, task-023

**Scope:**
- Create `site/scripts/lib/flow-graph/extract-inline.mjs` -- the inline `## State:` shape (D2).
- Each `^##\s+State:\s+(NAME)` heading is a node, in document order. A trailing parenthetical gloss in the heading is stripped from `name` and kept as a label candidate.
- `provenance` is the heading line through the end of its lead paragraph, `sourceKind: 'skill'`; `detail` is the full section range, heading line to the line before the next `## ` heading or `---` rule. Both ranges come from the **shared section reader in `source.mjs`** (task-020), which this extractor consumes rather than reimplements -- the same helper `extract-dispatch.mjs` uses for `inline` Detail cells and the engine derivation uses for the engine's `below` cells.
- Edges come from the section's `**Advance:**` block via the shared parser, plus rules 7 and 8 (back-reference and re-entry).
- A state with no `**Advance:**` line and no outgoing back-reference is an exit with `advanceType: 'UNSPECIFIED'` -- this is how `aid-review`'s `DONE` terminates.

**Acceptance Criteria:**
- [ ] Every `^##\s+State:\s+(NAME)` heading becomes exactly one node, in document order, with `order` assigned by position.
- [ ] A heading's trailing parenthetical gloss is stripped from `name` and retained as a label candidate.
- [ ] `provenance` covers heading-through-lead-paragraph and `detail` covers the full section, ending at the line before the next `## ` heading or `---` rule.
- [ ] Both ranges are obtained from the shared section reader exported by `source.mjs`; this module contains no private section-reading implementation, verified by grep.
- [ ] A state with no `**Advance:**` line and no outgoing back-reference is an exit with `advanceType: 'UNSPECIFIED'`; `aid-review`'s `DONE` is that case.
- [ ] Rules 7 and 8 are applied through `advance.mjs`, not reimplemented here.
- [ ] Every node's `provenance.excerpt` equals the live slice of its cited `canonical/` file.
- [ ] Unit tests exist for each step, including the gloss strip and the no-advance exit; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
