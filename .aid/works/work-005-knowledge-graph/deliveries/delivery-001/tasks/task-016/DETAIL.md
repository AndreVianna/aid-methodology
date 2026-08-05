# task-016: feature-009's table suite and the WCAG AA pass

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-016/STATE.md.
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

**Type:** TEST

**Source:** feature-009-accessible-table-view -> delivery-001 (Wave 2)

**Depends on:** task-015

**Scope:**
- The table suite for feature-009's criteria: D1's permutation property, D2's total sort order, D3's
  ten columns, D4's derived unlisted-nodes set, and the accessible-peer behaviours the view owes.
- Carries the **AC-7 table half** and the **AC-9 table half**. AC-9's reduced-motion clause is
  feature-008's and closes in task-018; AC-7's canvas half is task-018's too. Neither criterion
  closes here — the full close is task-022.
- The WCAG AA pass against `canonical/aid/templates/knowledge-graph/accessibility-checklist.md`.

**Acceptance Criteria:**
- [ ] Each shared criterion's own half is named as a half, with the co-owner and the closing task
      cited — no gate may read a half as a whole
- [ ] The AA pass is recorded checklist item by checklist item, with any item that cannot be asserted
      statically named and routed rather than skipped silently
- [ ] **Static assertions only in the suite that runs in CI.** Any runtime UI verification stays out
      of the required suite per `test-landscape.md` — work-017 shipped four broken edit surfaces past
      an A+ gate because static tests cannot see UI behaviour, and the remedy is an on-demand set,
      not a CI lane
- [ ] The `# COVERS:` manifest names `graph-table.js` so `select-suites.sh` selects this suite on a
      table edit
- [ ] The table is asserted usable with no drawing context, since that is what makes it the
      conforming alternate version (NFR-2)
- [ ] S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] Suite passes; total read from the script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
