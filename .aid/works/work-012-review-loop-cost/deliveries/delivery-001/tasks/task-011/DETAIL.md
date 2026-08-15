# task-011: Pass the specify gate a requirements slice, not the whole document

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

**Depends on:** task-008, task-009

> The dependency on task-009 is a **file-collision serialisation, not a logical need**: both tasks edit `canonical/skills/aid-specify/references/reviewer-brief.md` -- task-009 to render the two artifact sets, this task to render the requirements slice. They are logically independent and would otherwise be a parallel pair, but a shared file makes them a sequence. Recorded so a later reader does not "optimise" it back into the same wave.

**Scope:**
- `canonical/skills/aid-specify/references/state-initialize.md` -- the `### Step 1: Load Full Context` item reading '**REQUIREMENTS.md** -- full requirements for cross-reference'.
- `canonical/skills/aid-specify/references/state-review.md` -- the line 'Same as INITIALIZE Step 1'.
- `canonical/skills/aid-specify/references/reviewer-brief.md` -- render the slice.
- The slice is derived from the feature SPEC's own `## Source` section, which names the REQUIREMENTS sections and criteria the feature traces to.
- Authored instruction only.

**Acceptance Criteria:**
- [ ] Both sites pass only the traced slice; neither passes the whole `REQUIREMENTS.md`
- [ ] The slice's derivation is stated as reading the feature SPEC's `## Source`, not a hand-maintained map
- [ ] A feature whose `## Source` names no requirements section surfaces as a defect rather than silently yielding an empty slice
- [ ] The byte reduction is measurable on a real feature, for AC-9's figure in task-015
- [ ] All REQUIREMENTS.md §6 quality gates pass
