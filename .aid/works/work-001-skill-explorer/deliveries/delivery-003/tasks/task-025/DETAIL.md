# task-025: Dispatch-table extractor

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-025. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-025/STATE.md.
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
- Create `site/scripts/lib/flow-graph/extract-dispatch.mjs` -- the `## Dispatch` table shape (D1).
- Locate the D1 table. Each row is one node, in row order; the `State` cell gives `name`; `provenance` is that single row line in `SKILL.md` with `sourceKind: 'skill'`.
- When the `Detail` cell is a path to `references/state-*.md`, read that worker: its first prose sentence supplies a label candidate, its whole file range becomes `detail` with `sourceKind: 'worker'`, and its `**Advance:**` **block** refines the row's `Advance` -- the worker is more precise about conditions, but **the table remains the membership authority**. When the cell instead says `inline`, the matching `## State: NAME` section in the same file plays the worker's role, read through the **shared section reader in `source.mjs`** (task-020). That mixed shape is `aid-triage`'s, and it is why the section reader is shared rather than private to the inline extractor.
- Run the Advance-clause parser on the row cell, then on the worker's advance block, merging by `(from, to)` with worker conditions winning.
- A worker naming a state absent from the table produces a `warnings` entry and **no** edge, so the no-dangling invariant is preserved without a repair pass.
- Apply feature-003's label ladder in precedence order: the state section's `Purpose:` line remainder, then the worker doc's first prose sentence, then the lead paragraph of the matching inline `## State: NAME` section, then the state `name` title-cased. **A `Detail` cell is never itself a label candidate** -- it is either a path or a pointer word, and both make useless labels; rejecting it explicitly is what routes `aid-triage`'s states to the right candidates.

**Acceptance Criteria:**
- [ ] Nodes and edges come mechanically from the `State` and `Advance` columns, in row order, with only condition labels treated as best-effort.
- [ ] A `references/state-*.md` worker contributes its first prose sentence as a label candidate, its whole file range as `detail` with `sourceKind: 'worker'`, and its advance **block** as a refinement merged by `(from, to)` with worker conditions winning.
- [ ] An `inline` Detail cell binds the matching `## State: NAME` section **through the shared reader exported from `source.mjs`** -- this extractor contains no private section-reading implementation, verified by grep.
- [ ] A worker naming a state absent from the table yields a `warnings` entry and **no** edge; no dangling edge is ever produced and no repair pass exists.
- [ ] The label ladder is applied in precedence order and a `Detail` cell is never used as a label candidate.
- [ ] Every node carries `provenance` whose `excerpt` equals the live slice of its cited `canonical/` file.
- [ ] The extractor consumes the parser from `advance.mjs` unchanged and reimplements no clause splitting of its own.
- [ ] Unit tests exist for each step, including the worker-refinement merge and the `inline` binding; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
