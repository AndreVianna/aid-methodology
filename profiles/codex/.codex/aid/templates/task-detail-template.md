# task-NNN: {Title}

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.yml (full path)
or, on a flattened Lite work, the work-root STATE.yml's `tasks_lifecycle` mapping.
Shape: 6 sections matching .codex/aid/templates/delivery-plans/task-template.md.

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

**Type:** RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE

**Source:** feature-NNN-{name} -> delivery-NNN -> AC-N[, AC-N]
<!-- The AC-N ids are the acceptance criteria in that feature SPEC which this task
     implements. At least one is required: a task implementing no stated criterion
     is undeclared scope or unnecessary work. On the flattened Lite layout there is
     no features/ folder, so cite the work instead:
     work-NNN-{slug} -> delivery-001 -> AC-N. -->

**Depends on:** task-NNN [, task-NNN] | -- (none)

**Scope:**
- {What this task produces or modifies -- depends on Type. Specific and bounded. One type per task; never mix types.}

**Acceptance Criteria:**
<!-- Each criterion names an observable: a command and its expected result, a file
     and its expected content, a count derived from disk, a measurable threshold,
     or a user-visible behaviour plus how to reproduce it. Judgment criteria are
     allowed but must state what is judged and against what standard. Full rule:
     .codex/aid/templates/requirements/requirements-template.md
     § Verifiable Acceptance Criteria. -->
- [ ] {Criterion 1 -- names an observable}
- [ ] {Criterion 2 -- names an observable}
- [ ] All section-6 quality gates pass
