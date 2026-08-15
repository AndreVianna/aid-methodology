# task-005: G-07 selector-partition oracle

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

**Depends on:** task-004

**Scope:**
- `scripts/checks/g07-selector-partition.sh` -- creating the `scripts/checks/` directory, which does not yet exist.
- Parse the registry's `Match` column, enumerate the in-scope corpus under `LC_ALL=C`, apply selectors in table order with first-match-wins.
- Emit `VIOLATION <path>` for a file matching zero rows, `UNDECIDED <path>` for a file inside an `<inexpressible>` row's path bound.
- Bash + awk only (NFR-2).

**Acceptance Criteria:**
- [ ] Exits 0 on the current corpus, with `UNDECIDED` lines for the files under `canonical/aid/templates/` and none elsewhere
- [ ] Exits 1 naming the file on a fixture corpus containing an untyped file OUTSIDE `canonical/aid/templates/` -- the path bound must not soften a real orphan to UNDECIDED
- [ ] Two runs over an unchanged tree produce byte-identical stdout (AC-7, NFR-3)
- [ ] Reports the decided and undecided counts, which are AC-11's evidence
- [ ] Classification of the current corpus is identical to the pre-task-004 prose reading -- the formalisation changed representation, not meaning
- [ ] All REQUIREMENTS.md §6 quality gates pass
