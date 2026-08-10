# task-022: Byte-discipline verification of the `## MVP` region split

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-022/STATE.md.
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

**Depends on:** task-016

**Scope:**
- Source specs: `features/feature-003-planning-artifact-skills/SPEC.md` §8 rows **V7** and
  **V8**, and `features/feature-002-design-lifecycle-machinery/SPEC.md` §7 row **E3** (which
  is the same case as V8). These back REQUIREMENTS **AC-6a** and BLUEPRINT gate criterion 8's
  region half.
- **Why this is its own task, and what its edges enforce.** Both rows bind **both** mvp verbs
  and both roadmap verbs. feature-003 §4 states it directly: *"`update` is a writer too, and
  the table above grants it the power to create the region, so an oracle that exercises only
  `create` leaves the more dangerous writer untested."* `/aid-update-roadmap` and
  `/aid-update-mvp` are authored in **task-014**, reached transitively through task-016; and
  the `task-016` edge additionally serialises this task behind every other consumer of the
  shared rendered tree, so no two tasks in the delivery write `profiles/` / `.claude/` or
  `.aid/knowledge/roadmap.md` concurrently.
- **Execution path**: task-024 has already produced the throwaway local render, so the
  skills are invocable. This task **renders nothing and reverts nothing**; task-025 reverts
  the render once every consumer is done.
- **Where the checks run, stated because the oracle names repository paths.** Both V7 and V8
  are `git diff`-based and their SPEC text names `.aid/knowledge/roadmap.md`, so they are run
  **against this repository's own working tree**, on the `roadmap.md` task-015 committed --
  a `mktemp -d` fixture is not a git work tree and would make `git diff -U0` meaningless.
  The task therefore **mutates that one file and restores it**: capture the committed blob,
  run the five authored runs, make the assertions, then
  `git checkout -- .aid/knowledge/roadmap.md`. Restoration is an acceptance criterion below,
  and the serialising edge is what makes the mutate-and-restore safe.
- **V7 -- `## MVP` preserved by its neighbour.** Capture the `## MVP` byte range, then run
  `/aid-update-roadmap` in **F-full** and `/aid-create-roadmap` in **F-horizons-empty**, then
  compare: bytes identical. Each run must have written outside the region -- the fixtures
  below exist so that neither verb exits by routing.
- **V8 (= feature-002 E3) -- mvp writes only its section.** Run `/aid-update-mvp` in
  **F-full** and `/aid-create-mvp` in **F-no-MVP**; `git diff -U0 .aid/knowledge/roadmap.md`
  touches only lines inside the `## MVP` range -- including leaving the `## Contents` index
  alone, which holds because `/aid-create-roadmap` carried the `MVP` entry from creation and
  F-no-MVP keeps that entry.
- Also assert the region's extent rule as feature-002 §3c states it: the range runs from the
  `## MVP` heading to the next heading of level 2 or shallower, or EOF, with `###` entries
  belonging to the region -- so a `###` entry added inside the MVP is inside the diff, and a
  change to `## Now` is outside it.
- **Record, for each of the five authored runs, the allocated work folder and the
  confirmed absence of a `phase:` value in its `STATE.md`**, into this task's STATE.md notes,
  **then remove those work folders and their worktrees**. V23's nine-skill sweep is
  aggregated in task-023 from these records; the state itself does not survive this task, so
  capturing it before teardown is this task's obligation, and so is the teardown --
  `.aid/works/` is tracked, not ignored.
- **Fixture policy -- three working-tree states, because one state cannot make all four verbs
  write.** The four verbs are not symmetric: feature-003 §4's destination table (`SPEC.md`
  § *The destination rule is stated at the region level*) routes a `create` **to its `update`
  counterpart whenever its own owned region already carries committed content**, and a routing
  exit writes nothing. The `roadmap.md` task-015 committed has **both** the horizon sections
  and `## MVP` populated, so against it `/aid-create-roadmap` and `/aid-create-mvp` are
  **no-ops** -- and "bytes identical before and after" is satisfied by a run that never wrote,
  which is a vacuous pass, not a check. Each verb therefore runs in the state that table says
  makes it write:

  | Fixture (a working-tree state of `.aid/knowledge/roadmap.md`) | Produced by | Authored runs it carries |
  |---|---|---|
  | **F-full** -- exactly what task-015 committed: horizons populated, `## MVP` populated | already on disk; no edit | `/aid-update-roadmap` (V7's update half), `/aid-update-mvp` (V8's update half) |
  | **F-horizons-empty** -- F-full with the three horizon sections emptied, headings kept, `## MVP` left populated | a hand edit of the working copy | `/aid-create-roadmap` (V7's create half) -- table row *"document present, owned region empty/absent → Fills the horizon sections"*, so it writes for real while `## MVP` must survive untouched |
  | **F-no-MVP** -- F-full with the `## MVP` region deleted and **its `## Contents` entry kept** | a hand edit of the working copy, re-established between the two runs below | `/aid-create-mvp` (V8's create half) -- table row *"Creates `## MVP` at the anchor position"*; then, on a freshly re-established F-no-MVP, `/aid-update-mvp` for the region-creation case (feature-003 §4) |

  **Total authored runs: five**, not four -- the fifth is the region-creation case that had no
  fixture at all before. All five *realize*: the fixtures above exist precisely so that each
  verb writes rather than exiting by routing, so each of the five allocates a `work-NNN` folder
  and executes feature-002 §3e's full-verify loop. This task performs **no** non-realizing
  invocation -- no routing exit and no refusal -- which is why its work-folder criterion below
  can bind all five unconditionally. Fixtures are working-tree **edits**, not skill runs, so
  adding two states adds no run; only the fifth run does. The `## Contents` entry is retained
  in F-no-MVP deliberately: V8 asserts no hunk touches `## Contents`, which holds precisely
  because `/aid-create-roadmap` carried the `MVP` entry from creation, and deleting it with
  the region would make that conjunct unsatisfiable.
- **F-no-MVP is re-established between the two runs that use it**, because the first of them
  creates the region and would leave the second with nothing to create. Re-establishing is one
  more hand edit of the working copy, not a run.
- **The extent-rule check uses a control edit, not a sixth run.** The `###`-inside-MVP
  half is asserted on the diff `/aid-update-mvp` already produces in F-full; the
  `## Now`-is-outside half is asserted on a **hand edit** made as a control. Neither is a
  skill run, so neither enters the run count or the V23 evidence.
- Out of scope: the render (task-024) and its revert (task-025); the `update` contract's own
  obligations -- V17, V21, V22, V23, V24, V27 -- which are task-023's; every
  `design`/`create`-stage row, which is task-016's; and authoring any new test script or bash
  assertion id -- on **feature-001 AC-3**'s ground alone (the suite scripts stay untouched),
  not on any `coverage-parity` ground: this delivery already mints roughly 36 new ids without
  a script edit, so that re-bootstrap is scheduled in delivery-003 regardless.

**Acceptance Criteria:**
- [ ] **V7**: the captured `## MVP` byte range is identical before and after **both**
      `/aid-create-roadmap` and `/aid-update-roadmap`. Running only one of the two does not
      satisfy this row -- **and neither run may be a routing exit**: each is run in the fixture
      § Scope assigns it (`/aid-update-roadmap` in F-full, `/aid-create-roadmap` in
      F-horizons-empty) and each must show a **non-empty** `git diff` on
      `.aid/knowledge/roadmap.md` outside the `## MVP` range. A run that wrote nothing
      satisfies "bytes identical" vacuously and fails this criterion
- [ ] **V8 / E3**: for **both** `/aid-create-mvp` and `/aid-update-mvp`,
      `git diff -U0 .aid/knowledge/roadmap.md` shows hunks confined to lines between the
      `## MVP` heading and the next level-2 heading -- no hunk touches `## Contents`,
      `## Now`, `## Next` or `## Later`. Each is run in its assigned fixture
      (`/aid-update-mvp` in F-full, `/aid-create-mvp` in F-no-MVP) and each must show a
      **non-empty** diff inside the region; a routing exit fails this criterion for the same
      reason
- [ ] Both rows are byte comparisons, not inspection: the assertions are made on captured
      byte ranges and on `git diff` extents, and the captured ranges are recorded
- [ ] The extent rule is exercised, not assumed: a `###` entry written inside the MVP falls
      **inside** the asserted range, and a change made to `## Now` falls **outside** it. Both
      halves are assertions over diffs -- the first over `/aid-update-mvp`'s own F-full diff,
      the second over a **control hand edit** -- so neither is a skill run
- [ ] `/aid-update-mvp` creating the region on a `roadmap.md` that lacks it is exercised as
      its own case, and still writes only inside the region it creates (feature-003 §4). Its
      fixture is a **freshly re-established F-no-MVP** -- re-established because the preceding
      `/aid-create-mvp` run consumed that state -- and it is the **fifth** authored run,
      counted below
- [ ] **All acceptance criteria from the source feature covered** (TEST default): feature-003
      V7 and V8 and feature-002 E3 are each run and recorded with the command that produced
      them, and every other feature-003 §8 or feature-002 §7 row is named with the task or
      delivery that owns it -- none silently dropped
- [ ] Each of the **five authored runs** has its allocated work folder and the confirmed
      absence of a `phase:` value recorded before this task ends -- the V23 evidence task-023
      aggregates. The criterion binds all five because all five realize: each is run in the
      fixture § Scope assigns it precisely so that it writes, and the non-empty-diff conjuncts
      on V7 and V8 above are what make that checkable. Fixture edits and the control edit are
      not runs and are not recorded as such. **A sixth run means a row built its own state
      instead of using the fixture § Scope assigns it**, and a fourth means a row was
      dropped -- the count is the falsifier for the fixture table, not a decoration on it
- [ ] **Every `work-NNN` folder these runs allocated is removed, and its worktree with
      it**, after the evidence is captured: `git status --porcelain .aid/works/` shows no
      folder this task created, and no stray worktree remains registered
- [ ] Tests are deterministic and setup/teardown is clean: two runs over one input produce
      identical outcomes, and every allocation the runs make is removed on exit including on
      failure
- [ ] **`.aid/knowledge/roadmap.md` is restored**: `git diff --exit-code --
      .aid/knowledge/roadmap.md` is clean at the end of the task, so the file matches what
      task-015 committed byte for byte. This task deliberately mutates it and puts it back;
      an unrestored mutation would corrupt task-017's and task-019's inputs
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left -- this task neither renders nor reverts -- and
      `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
