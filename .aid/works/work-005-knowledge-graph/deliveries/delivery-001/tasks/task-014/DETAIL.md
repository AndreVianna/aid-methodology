# task-014: feature-007's GV shell suite, and the view-suite rename

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-014/STATE.md.
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

**Source:** feature-007-graph-view-shell -> delivery-001 (Wave 2)

**Depends on:** task-013

**Scope:**
- **The rename, decided:** the shipped `tests/canonical/test-graph-view.sh` **becomes**
  feature-007's `tests/canonical/test-graph-view-shell.sh`, and its existing `GC01`-`GC04`
  assertion ids are **renamed** to free the `GC*` prefix for feature-008 (task-018). Its `GH*`,
  `GS*` and `GT*` ids stay as they are.
- Author the `GV*` series the SPEC names (`:1790`): `GraphModel` and the D2 loader (ten columns,
  stopping before the coverage notes), `LensState`, the `ViewModel` projection, the D5 palette
  contract, D6's four lenses and how they compose, D7's two node gestures, D8's `CONTROL_MANIFEST`
  bijection (`GV17`), D9's label shortening, and D10's coverage-predicate parity across the two
  runtimes (`GV02`, `GV04`, `GV08`).
- Carries the **AC-15 shell half** and the **AC-7 shell half**, each labelled a half with its
  co-owners named.

**Acceptance Criteria:**
- [ ] **CRITICAL — the rename is a coverage-parity event.** Renaming `GC01`-`GC04` will read as
      REMOVED ASSERTIONS to `tests/coverage-parity.sh`, which is **live and enforcing** and reports
      count-deltas. A pure rename requires a **baseline re-bootstrap**, NOT accept-list rows. Do the
      re-bootstrap and record that the delta is a rename, with the two TSVs compared by `comm` rather
      than by reading `added - reduced`
- [ ] The suite's `# COVERS:` manifest header is updated for the new filename and covered set
- [ ] Anything in `tests/canonical/select-suites.sh` that keys on the old filename is updated, so a
      view-template edit still selects this suite
- [ ] No assertion is lost in the rename: the pre-rename and post-rename assertion totals match,
      each read from the script's own summary line
- [ ] `GC*` is free of feature-007 ids afterwards, verified by grep over the renamed suite
- [ ] The `GV*` series is contiguous and collides with no sibling prefix
- [ ] AC-7 and AC-8a assertions are stated at `grouping: 'none'`, where the criterion's equality is
      well-posed — under `grouping: 'document'` a `structure` row collapses and the drawn count
      falls short by exactly the collapsed rows
- [ ] `GV26` asserts the obligation D3's `grouping` row states, with focus belonging to the
      `<select>` — an `<option>` takes no tab stop and never becomes `document.activeElement`
- [ ] The AC-15 and AC-7 shell halves are each labelled a half, naming feature-006, feature-008 and
      feature-009 as the respective co-owners
- [ ] S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
