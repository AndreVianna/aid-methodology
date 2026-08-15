# task-007: Oracle behaviour and coverage measurement

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

**Type:** TEST

**Source:** work-012-review-loop-cost -> delivery-001

**Depends on:** task-005, task-006

**Scope:**
- A canonical suite over the oracle contract, plus the AC-11 coverage measurement.
- Fixture corpora for: a clean corpus, an untyped file outside the template tree, a double-typed file, a missing oracle, a non-executable oracle, an oracle exiting 1 with no VIOLATION line, and an oracle that overruns the timeout.

**Acceptance Criteria:**
- [ ] AC-5: a criterion with no `oracle:` produces no finding -- asserted as a positive control
- [ ] AC-6: exit 0 on a clean corpus; non-zero naming the file on an untyped or double-typed one
- [ ] AC-7: byte-identical output across two runs of an unchanged tree
- [ ] AC-8: a missing or non-executable oracle degrades to reading AND the degradation is reported
- [ ] Exit 1 with no VIOLATION line, and a timeout overrun, are each treated as degradation rather than as a finding
- [ ] AC-11: the decided-versus-undecided counts over the real corpus are measured and recorded, with the re-derivation they replace named
- [ ] Tests are deterministic with clean setup/teardown
- [ ] All REQUIREMENTS.md §6 quality gates pass
