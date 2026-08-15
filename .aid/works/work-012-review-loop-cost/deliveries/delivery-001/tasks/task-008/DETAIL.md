# task-008: Cycle-2-and-later split: verification set and hunt set

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

**Depends on:** task-007

**Scope:**
- **This is FR-3's task and the AC-1 measurement split point.** It is the FIRST feature-003 task by construction; nothing from feature-003 may precede it.
- `canonical/aid/templates/reviewer-ledger-schema.md`: split the cycle-N>=2 clause. Ledger verification stays FULL; new-finding discovery becomes SCOPED.
- `canonical/aid/templates/reviewer-dispatch.md`: `ARTIFACTS UNDER REVIEW` carries two labelled sets on cycles >= 2 -- the verification set and the hunt set -- and `RUBRIC` resolves criteria against the scoped surface.
- Define the hunt set: `git diff --name-only <previous-cycle-commit>..HEAD | filter_reviewable_artifacts`, expanded by mechanical cross-reference lookup over the three reference forms (backticked path, markdown link, in-page anchor).
- Define the verification set: every file in an existing ledger row's `Doc` column, widened to the full cycle-1 artifact set whenever any row's `Doc` is `--`.
- Define the fallback: no previous-cycle commit means the cycle is unscoped.
- Authored instruction only -- no executable surface.

**Acceptance Criteria:**
- [ ] Cycle 1 still reads everything; its behaviour is unchanged (FR-1)
- [ ] Ledger verification is stated as never scoped, and the `Doc: --` widening rule is present (AC-4)
- [ ] The hunt set's derivation reuses the EXISTING `filter_reviewable_artifacts` function rather than defining a second filter
- [ ] The cross-reference expansion is specified mechanically, with the prose-reference limitation stated and routed to FR-6's final full pass
- [ ] A scoped cycle cannot approve an artifact; only a full pass can (FR-6)
- [ ] The ledger keeps 7 columns and `grade.sh` is untouched (C-3)
- [ ] The commit landing this task is recorded, since it is the before/after boundary for AC-1
- [ ] All REQUIREMENTS.md §6 quality gates pass
