# task-023: Behavioral verification of the `update` contract across the nine skills

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-023/STATE.md.
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

**Depends on:** task-022

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §8 rows **V17, V21,
  V22, V23, V24, V27**. These back BLUEPRINT gate criteria 8 (the sequence's third step),
  9 (V24's sole-producer half) and 11. Every row here needs a skill authored in **task-014**,
  reached transitively through task-022 -- the edge, not the numbering, is what makes the
  ordering enforceable. The same edge serialises this task behind every other consumer of the
  shared rendered tree and of `.aid/knowledge/roadmap.md`.
- **Execution path**: task-024 has already produced the throwaway local render, so the skills
  are invocable. This task **renders nothing and reverts nothing**; task-025 reverts the
  render, and this task is one of its ancestors.
- **Fixture policy -- two projects, set up once, reused by every row. This is what keeps the
  task inside one agent session.** The expensive unit here is an authored skill run: each
  allocates a `work-NNN` folder and executes feature-002 §3e's full-verify loop (mechanical
  grounding check, clean-context `aid-reviewer` dispatch writing a ledger,
  `grade.sh --explain`, 3-cycle breaker). An earlier draft let **each row build its own
  project from zero**, which is what multiplied the count past what one session holds. The
  fix is not to split the task -- the six rows are one contract and splitting them would
  duplicate the fixtures again -- but to declare the fixtures once:

  | Fixture | Built by | Rows that use it |
  |---|---|---|
  | **F-bare** -- a scratch project with no `roadmap.md` and no `backlog.md`, created under `mktemp -d` and **`git init`-ed with a baseline commit**, so the `git status` oracles below are meaningful rather than exit-128 | copied, then **one `design`-stage run** inside it -- load-bearing, because feature-003 §8 defines V24's fixture as *"a project that has run only `design` and `update` skills"*, and a project with no run at all satisfies that vacuously | V17 (three routing exits, which write nothing and terminate immediately -- no realizing run and no verify loop), then V24 over that same project after the `design` run and the V17 exits |
  | **the working tree** -- this repository, with `roadmap.md` and `backlog.md` already created by task-015 and task-021; already a git work tree | already exists; **one `/aid-design-roadmap` run** to put a seed back in `.aid/design/`, without which V27's CC-3 seed clause is vacuous on every arm | V27 (one `update` run per artifact = 3, the roadmap arm consuming that seed), V21 (a **second** invocation of one of those same three = 1), V22 (inspection of the outputs V27 produced -- no run of its own) |

  **Total authored runs: six** -- three for V27, V21's repeat, F-bare's one `design` run and
  the working tree's one `design` run -- alongside three terminate-immediately routing exits.
  Every row below names the fixture it uses, and no row's stated precondition is left to a
  fixture that does not supply it: that is the property this table exists to make checkable,
  and the run count is its falsifier -- a seventh run means a row built its own state.
- **Where each row runs, and why.** V17 and V24 run in **F-bare**; they need an *absent*
  destination, which the working tree does not have. V27, V21 and V22 run **against this
  repository's own working tree**, because V27's oracle is `git diff` over the destination
  document and a bare `mktemp -d` directory is not a git work tree. Those runs mutate
  **three** repository documents, not two: `.aid/knowledge/roadmap.md`,
  `.aid/knowledge/backlog.md`, **and `.aid/knowledge/tech-debt.md`** -- because
  `/aid-update-backlog` carries the power to promote confirmed `tech-debt.md` rows and delete
  them there in the same run (task-014 § Scope; feature-003 §5). All three are restored with
  `git checkout --` afterwards, which is an acceptance criterion below. The runs also write
  **`.aid/design/`** -- the seed the `/aid-design-roadmap` run below places there for V27's
  CC-3 half -- which `/aid-update-roadmap` is supposed to consume; that path is restored too,
  and is declared in this task's `rw-sets` line (PLAN § *Shared-state safety, and why the
  serialisation exists*).
- **V27 -- `update` produces a revision.** For each of roadmap, mvp and backlog, after its
  `create` has run: change one thing via the `update` skill; `git diff` over the destination
  is **non-empty** and every hunk falls inside that skill's owned region. This is AC-1's third
  step, which no other row asserts.
- **The seed half of V27 gets a fixture, rather than an "if one was present" that no fixture
  satisfies.** CC-3 (feature-003 §4, *"A routed seed still gets consumed"*) makes `update`
  consume a `.aid/design/` seed when one is present. In this repository's working tree no seed
  survives -- task-015's and task-021's `create` runs consumed theirs, which is exactly what
  V5 asserts -- so the clause would be **vacuously true for all three arms**. So the
  **roadmap arm is preceded by one `/aid-design-roadmap` run in the working tree**, which
  writes `.aid/design/roadmap.md`; `/aid-update-roadmap` then runs against a seed that is
  really there, and the seed's absence afterwards is a real assertion. The other two arms run
  with no seed and the clause is recorded as **inapplicable** there, by name, rather than
  passing silently. That design run brings this task's authored runs from five to **six**, and
  it is the only run added.
- **`.aid/design/` is restored too.** The design run above writes into a tracked directory
  task-001 created, so if `/aid-update-roadmap` fails to consume the seed the file is left
  behind as a dirty tree for task-025 and delivery-003. Restoration is an acceptance criterion
  below, and a surviving seed is a **V27 failure** rather than something to clean up quietly.
- **V17 -- absent destination.** For each of the three `update` skills: it routes to **the
  absent document's owner** and writes nothing.
- **V21 -- asked every run (FR-8).** Re-invoke **one of V27's three `update` runs** a second
  time -- the row needs two invocations in one project, not a project of its own. Run 2's
  transcript contains the derived-outputs question; after run 1 no file appeared beyond the
  destination and the outputs the user named; and no stored list exists.
- **V22 -- no tracking metadata (REQUIREMENTS AC-7).** Inspect **the outputs V27's runs
  already produced**; each generated non-KB output carries no frontmatter backlink field and
  no skill-attribution line. No run of its own.
- **V24 -- absent is clean, the skill-side half.** Assert over **F-bare after V17's three
  routing exits** -- a project on which only `design` and `update` skills have run: no
  `roadmap.md`, no `backlog.md`, no `knowledge.doc_set` entry for either. It reuses V17's
  fixture rather than building one. This row needs the `update` skills by construction, which
  is why it lives here and not in task-016. The gate-side assertion is feature-001 AC-4's,
  against a fixture KB, and is task-020's.
- **V23 -- `phase` not driven, aggregated from records rather than from live state.**
  The assertion covers **all nine** skills -- a number fixed by the feature, not by this
  task -- but most of the work folders live inside scratch projects their own tasks tear down.
  So every task that runs one of the nine skills **records the allocated work folder and the
  confirmed absence of a `phase:` value into its own STATE.md notes before teardown**, and this
  task aggregates those records. Every invocation contributes a record, non-realizing ones
  included: allocation happens at INTAKE, ahead of the GUARD refusal and the REALIZE routing
  exit, so a refusal or a routing exit has an allocated work folder like any other run
  (`design-lifecycle.md § Skill shape -- Allocation` and its binding table; feature-002 §3e,
  with REQUIREMENTS FR-3 as the recorded tiebreaker). Nine-of-nine coverage still rests on the
  `create` verbs exercised by task-015 and task-021, because those are the runs that reach the
  verbs at all -- not because task-016's refusal and routing exit allocate nothing. An earlier
  revision said they did; that premise was false against both the contract and the shipped
  skills, and it was corrected here and in task-016 rather than by changing allocation
  behaviour. Reading the live state here is not possible and is not attempted.
- **feature-003 V19's deferred runtime half, with a named evaluator.** The drain's behavior
  at tag time cannot be exercised inside this work -- it needs a real release cut. Its
  evaluator is **`release-aid`'s own Step 9 close-out check**, rewritten in task-009 to
  verify that the drained items are absent from `backlog.md` and present in the new
  `release-tracking.md` version section. So BLUEPRINT gate criterion 6's behavioral half has
  a scheduled evaluator -- the first `/release-aid` run after this work merges, checking
  itself -- rather than an unowned event. Its textual half was closed in task-009.
- Out of scope: the render (task-024) and its revert (task-025); the `## MVP`
  byte-discipline rows V7 and V8 (task-022); every `design`/`create`-stage row (task-016);
  V18 and V20, which read the KB in its final state and are task-020's; and authoring any new
  test script or bash assertion id -- on **feature-001 AC-3**'s ground alone (the suite scripts
  stay untouched), not on any `coverage-parity` ground: this delivery already mints roughly 36
  new ids without a script edit, so that re-bootstrap is scheduled in delivery-003 regardless.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that
      produced it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **V17** is run for all three `update` skills, and each routes to the **absent
      document's owner**: `/aid-create-roadmap` for both `/aid-update-roadmap` and
      `/aid-update-mvp`, `/aid-create-backlog` for `/aid-update-backlog`, with
      `git status --porcelain .aid/knowledge/` empty. A transcript naming `/aid-create-mvp`
      for the mvp case fails this criterion
- [ ] **V27** is run for all three artifacts, and for each the diff is non-empty **and**
      wholly inside the skill's owned region
- [ ] **V27's seed half is non-vacuous on at least one arm**: the roadmap arm is preceded by a
      `/aid-design-roadmap` run, so `.aid/design/roadmap.md` **exists** when
      `/aid-update-roadmap` starts and is **absent** when it finishes (CC-3). The mvp and
      backlog arms are recorded as *inapplicable -- no seed present*, named rather than
      reported as passing. An "if one was present" result on all three arms fails this
      criterion
- [ ] **`.aid/design/` is left as committed**: `git status --porcelain .aid/design/` is empty
      at the end of the task. A surviving `.aid/design/roadmap.md` is a **V27 failure**, not a
      cleanup item, and is reported as such before it is removed
- [ ] **V21**: run 2's transcript contains the derived-outputs question, and
      `grep -rnE 'derived|outputs' .aid/settings.yml` finds no stored list. A body that asks
      only on the first run fails
- [ ] **V22**: `grep -nE 'aid-(create|update)-(roadmap|mvp|backlog)|source_doc:|generated_by:'`
      over each generated non-KB output returns no match
- [ ] **V23**: for each of the nine skills, the work its run allocated carries no `phase:`
      value -- `grep -n '^phase:' .aid/works/<work>/STATE.md` absent or empty, asserted at
      the time of the run and carried here as a record. **No conjunct is added on
      `canonical/aid/templates/work-state-template.md`**: feature-003 V23 replaced that diff
      outright as *"which this feature never touches and which therefore could not fail"*,
      and feature-002 G2(a) keeps it only beside a failing half and labels it vacuous. The
      failing half lives in task-003's G2(b) grep over the shipped contract
- [ ] **V24**: on a design-and-update-only project there is no `roadmap.md`, no `backlog.md`
      and no `knowledge.doc_set` entry for either -- `create` is the sole producer
- [ ] The V23 evidence spans **all nine** skills, assembled from the STATE.md run records of
      every task that ran one of the nine. A sweep over three
      skills passes vacuously, and a claim that reads live scratch state fails outright --
      that state no longer exists by the time this task runs
- [ ] **All three mutated documents are restored** after V27:
      `git diff --exit-code -- .aid/knowledge/roadmap.md .aid/knowledge/backlog.md .aid/knowledge/tech-debt.md`
      is clean at the end of the task, so each matches current `HEAD`. `tech-debt.md` is
      included because `/aid-update-backlog` may delete a promoted row from it in the same
      run. The restoration target is stated as content against the current tip, not against
      an enumerated commit set: task-018's migration and task-017's tech-debt rows both land
      *after* this task and are not part of the state restored here
- [ ] **Every `work-NNN` folder this task allocates in the working tree is removed, and its
      worktree with it.** The V27 and V21 runs allocate through the Work Initiation Gate
      (`worktree-lifecycle.sh create`), so each leaves a `.aid/works/work-NNN-*/` folder and
      a worktree; `.aid/works/` is tracked, not ignored, so a leftover makes the tree dirty
      for task-025 and delivery-003. `git status --porcelain .aid/works/` shows no folder
      this task created, and no stray worktree remains registered. Record the ids removed,
      after the `phase:` evidence has been captured from them
- [ ] **F-bare is a git work tree**: created under `mktemp -d`, then `git init` plus a
      baseline commit, before any oracle that shells out to `git` runs inside it. V17's
      `git status --porcelain .aid/knowledge/` assertion returns empty only in a work tree --
      outside one `git status` exits 128, which is not "empty" and would be misread as a pass
- [ ] Tests are deterministic and setup/teardown is clean: every scratch project is created
      under `mktemp -d` and removed on exit including on failure; two runs over one input
      produce identical outcomes
- [ ] **The authored-run count is six, and it is recorded** -- three V27 `update` runs, V21's
      repeat, F-bare's `design` run and the working tree's `design` run. **A seventh means a
      row built its own state instead of using the fixture the § Scope table assigns it; a
      fifth means a row was dropped.** The three routing exits are **non-realizing
      invocations** -- they write nothing to their destination, leave their seed in place and
      run no verify loop, so they are counted separately. They do still allocate (allocation
      precedes the routing exit), so each owes a work-folder + no-`phase:` record like any
      other invocation
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left -- this task neither renders nor reverts -- and
      `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
