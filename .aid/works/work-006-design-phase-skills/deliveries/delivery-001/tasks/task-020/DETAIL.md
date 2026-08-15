# task-020: Seed-immobility and registration audit for the Knowledge Base doc-set change

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-020/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-025

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` AC-3 and §5 rows 1, 4,
  5, 6, 7, 8, 9. Run at the point where every feature-001 and feature-003 edit has landed,
  because *"the seed did not move"* is only a true statement about the **delivery** once
  nothing else is going to move it. This backs BLUEPRINT gate criterion 5.
- Run the six oracles AC-3 names, **unmodified**:
  `tests/canonical/test-kb-template-authoring-standard.sh` (AS06's `TEMPLATE_COUNT == 14`),
  `test-doc-set-read.sh` (T02), `test-doc-set-mapping.sh` (T02),
  `test-domain-doc-matrix.sh` (MT01/MT02/MT06/MT17),
  `test-spine-depth-coverage.sh` (SD04/SD05/SD07), and `npx vitest run gen-reference` from
  `site/` -- five bash suites and one vitest spec.
- Assert `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`. The clean-diff
  is scoped to **the suite scripts, never the files under test**: `domain-doc-matrix.md` and
  `document-expectations.md` are inputs those suites read and are edited by this delivery, so
  a diff assertion over "their files" would be unsatisfiable by construction.
- Re-run the registration oracles as a set now that all four surfaces are occupied:
  AC-2 (**in the narrowed form task-007 fixes** --
  `find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' \)`
  returns nothing, which is what AC-2's criterion text actually says; the SPEC's printed
  `find canonical …` form is unsatisfiable here because `-iname` matches the six
  `canonical/skills/aid-*-{roadmap,backlog}` directory names feature-003 legitimately
  creates -- plus 8 matrix rows per document),
  AC-4 (the anchor-scoped ownership-map `awk` + `grep -c` -> `0`),
  AC-10 (the extract-and-eval loop over both `_dim_of_filename` twins),
  AC-12 (the counted conditional rows and the prose tally agree),
  AC-5 (the direct C-3 grep over the two instances).
- Reconcile feature-001 §5's fifteen rows. **Discharged inside delivery-001**, each with the
  task that owns it: row 1 (no test script moved) here; rows 2 and **3** (doctrine amended,
  canonical and dogfood) in task-006; rows 4 and 8 (matrix rows, matrix self-tallies) in
  task-007; row 6 (dimension map resolves) in task-008; row 5 (expectations blocks) in
  task-017; row 7 (not in the ownership map) here; row 9 (C-3 compliance of the two
  instances) in task-015 and task-021; row 10's hand-edited and script-regenerated conjuncts
  in task-018 and task-019; **row 11** (release flow rewired) and **row 12** (dead Change Log
  instruction gone) in task-009; row 13's canonical half in task-017; row 14 (index
  regenerated) in task-019.
- **Genuinely deferred, and only these three**: row 10's `kb.html` conjunct and row 13's
  five-render half and row 15 (render parity) -- all to **delivery-003**. Rows 3, 11 and 12
  are **not** deferred; classifying them as such would hand them to a delivery that does not
  own them and let them fall through entirely.
- **Also run here: feature-003 V18 and V20**, the item-uniqueness rows. They belong at this
  point and nowhere earlier, for two reasons. **They read the KB in its final state:** V18
  compares the `ID` column of `.aid/knowledge/tech-debt.md` against `.aid/knowledge/backlog.md`,
  and task-018's migration writes into `backlog.md`, so a run scheduled beside that write
  would race its own input. **And they must be able to fail:** feature-003 §8 lists V18 among
  the six rows that "would catch a real regression", on the stated ground that "the id is
  carried unchanged on promotion" -- which holds only if at least one promotion exists. Read
  task-021's recorded promotion outcome first: if this repository's own `backlog.md` carries
  no promoted row, construct a fixture copy of `tech-debt.md` + `backlog.md` in which one
  promotion has been performed and run both rows against it as well, so neither id set is
  empty. Record both set sizes.
- Out of scope: editing any test script or adding any assertion id -- that is the failure this
  task exists to **detect** (feature-001 AC-3), which is ground enough on its own. Not the
  `coverage-parity` re-bootstrap: this delivery already mints roughly 36 new assertion ids
  with no script edit (four per catalog row at
  `tests/canonical/test-catalog-dirs-parity.sh:126-141`, times the nine rows tasks 010-014
  add), so that re-bootstrap is scheduled in delivery-003 regardless (PLAN § Cross-Cutting
  Risks, risk 1). Also out of scope: re-running any behavioral row already discharged in
  task-016, task-022 or task-023.

**Acceptance Criteria:**
- [ ] All six oracles green **unmodified**, and
      `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` clean. If any of
      them needed *editing*, the conditional decision was not implemented -- that is what
      feature-001 §5 row 1 calls load-bearing
- [ ] Counts are read from each script's own summary line ("Tests passed: N"), never from
      grep over stdout, which undercounts on hang or timeout
- [ ] `gen-reference.test.mjs`'s `toHaveLength(14)` over KB doc templates is unchanged, and
      its five `toHaveLength` calls are all still the values they hold today -- none of the
      three quantities moves in this work
- [ ] AC-2, AC-4, AC-10, AC-12 and AC-5 oracles each return the value their SPEC states, and
      the returned values are recorded rather than summarized
- [ ] Every feature-001 §5 row is accounted for: evaluated here, evaluated in an earlier
      task named by number, or deferred to a delivery named by number -- none silently
      dropped (TEST default: all acceptance criteria from the source feature covered).
      Exactly three conjuncts are deferred, all to delivery-003; a reconciliation that
      defers rows 3, 11 or 12 is wrong and fails this criterion
- [ ] **V18**: `comm -12` over the `ID` column of `tech-debt.md` and `backlog.md` is empty,
      **and both id sets are non-empty**, with their sizes recorded. A run in which either
      set is empty does not satisfy this row -- the intersection would be trivially empty and
      the row could not fail
- [ ] **V20**: for every id in `tech-debt.md` union `backlog.md`,
      `grep -Fc "<id>" .aid/knowledge/roadmap.md` -> `0`, with the size of the id set
      recorded. An empty id set does not satisfy this row either
- [ ] Both rows are evaluated against the KB **after** task-018's migration and task-019's
      regeneration -- the final state -- and never beside a concurrent writer of `backlog.md`
- [ ] Tests are deterministic and setup/teardown is clean: no suite leaves a residue, and
      `git status --porcelain` is identical before and after the run; any V18/V20 fixture is
      created under `mktemp -d` and removed on exit including on failure
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean -- delivery-003 owns the
      committed render (C-5)
- [ ] All section-6 quality gates pass
