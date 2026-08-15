# task-003: The optional `oracle:` key and its exit contract

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

**Depends on:** -- (none)

**Scope:**
- `canonical/aid/templates/kb-authoring/frontmatter-schema.md`: declare `oracle:` as an OPTIONAL key on a `review-criteria:` entry.
- State the full contract: value is a repo-root-relative path outside `canonical/`; stdout carries `VIOLATION <path> <reason>` and `UNDECIDED <path> <reason>` lines, sorted; exit 0 = no violation among decided files (UNDECIDED lines are not a failure); exit 1 = at least one VIOLATION; exit 2 = could not run at all; any other exit, a 60s timeout overrun, or exit 1 with no VIOLATION line is treated as exit 2 and reported as degradation.
- State that absence of the key is never a defect, and that a `kind: exclude` criterion has nothing to run.

**Acceptance Criteria:**
- [ ] `oracle:` is documented as optional, with absence explicitly not a defect (AC-5)
- [ ] All five exit outcomes are stated, including the 60-second timeout and the malformed exit-1 case
- [ ] The per-FILE nature of coverage is explicit: an oracle reports per path and never collapses the criterion to one word
- [ ] The value's placement rule (repo-root-relative, outside `canonical/`) is stated
- [ ] No existing declared criterion is modified -- this is a pure addition
- [ ] All REQUIREMENTS.md §6 quality gates pass
