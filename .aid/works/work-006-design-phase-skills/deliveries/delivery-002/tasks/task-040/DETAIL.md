# task-040: Brownfield architecture lifecycle exercised against this repository's populated C1 doc

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-040/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-039

**Scope:**
- Source specs: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V4** (this
  task's share), **V5** (architecture), **V8**, **V17** (the `hand-authored` half), **V19**,
  **V21** and **V25**'s behavioral half; and
  `features/feature-002-design-lifecycle-machinery/SPEC.md` §7 row **E2**, which that spec labels
  a manual run *"behavioral; feature-004 owns the skill"* and delivery-001's task-016 forwards
  here by name. It closes BLUEPRINT criteria 4 and 5 for the `architecture` artifact.
- **Execution path** (BLUEPRINT § Notes): task-039 has already produced the throwaway local render,
  so the twenty-seven skills are invocable. This task **renders nothing and reverts nothing** -- it
  reads that tree, and task-048 reverts it once every consumer is done.
- **These runs happen against this repository's own `.aid/`, deliberately, and every document they
  touch is restored here.** feature-004 AC-3 and feature-002 E2 are both scoped to *"this
  repository as it stands"*, and the state that makes the row meaningful is exactly this
  repository's: `.aid/knowledge/architecture.md` is **515 lines** with `source: hand-authored`
  (`:3`). A scratch project cannot supply a populated as-built C1 document without reconstructing
  one, so the run is real and the mutation is undone -- the same mutate-and-restore device
  delivery-001's task-022 and task-023 used, with this task carrying its own restoration criteria
  and task-048 backstopping rather than repairing.
- **Four authored runs, in this order, and no fifth.**
  1. `/aid-design-architecture` -> writes `.aid/design/architecture.md` in `design-seed.md`'s
     shape, with its `## Destination` naming this project's C1 doc and its `## Open questions`
     **empty**, so nothing in this task tests the readiness gate (task-044 owns that).
  2. `/aid-create-architecture` -> realizes into the C1 doc although it is populated, and deletes
     the seed. This run **is** V5, AC-3's architecture case, and feature-002 E2.
  3. `/aid-update-architecture` with **no seed present** -> V8(a).
  4. `/aid-update-architecture` with a seed present -> V8(b).
- **The step-4 seed is a fixture edit, not a second `design` run.** After step 3, the executor
  writes `.aid/design/architecture.md` by hand in `design-seed.md`'s shape with a known
  `## Current direction`. What an authored `/aid-design-*` run happens to put in that section is not
  under the executor's control, so a precondition defined as *"the run leaves it saying X"* would be
  unreachable. This is a fixture built **before** step 4 begins; a row that repairs its own
  precondition once it has started fails the criteria below.
- **Restore, and record before restoring.** Every KB document these runs touch is returned to
  current `HEAD`; `.aid/design/` is returned to its committed content; every `work-NNN` folder and
  worktree the four runs allocated is removed **after** its `phase:`-absence evidence is captured
  into this task's STATE.md notes. The record is written before the teardown that destroys it.
- **The D doc is admitted and restored rather than asserted absent.** feature-004 §7b forbids
  `/aid-create-architecture` from writing rejected alternatives into the C1 doc and §7d routes a
  choice-not-taken to the project's **D** doc, while §5's destination table names a second
  destination only for `stack`. The two readings differ on whether an architecture run may write
  `.aid/knowledge/decisions.md`, and Detail does not settle a spec question: this task therefore
  **declares `decisions.md` as a write and restores it**, and asserts nothing about whether the run
  touched it. feature-004 V9 makes no architecture claim, so no oracle is weakened by this choice.
- Out of scope: the readiness gate, the seed-absent refusal, `source: generated` and the repeat
  `create` (task-044); the absent-destination creation path and its registration, and V17's
  `forward-authored` half (task-045); FR-8's asking and the Conformance-Lane divergence (task-046);
  the other three artifacts (task-041, task-042, task-043); authoring any test script under `tests/`
  or adding any bash assertion id -- the ground is **feature-001 AC-3**; and the
  `coverage-parity` re-bootstrap, which is a CI-only run owned by delivery-003.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** -- no row is reported as covered without its oracle and result (TEST default: all
      acceptance criteria from the source feature covered)
- [ ] **feature-004 V4, this task's share:** after run 1,
      `git status --porcelain .aid/knowledge/ .github/` is **empty** and
      `.aid/design/architecture.md` exists. The oracle is scoped to those two paths and makes no
      claim that the seed is the only new file, because feature-002 §2d binds every `design`-stage
      skill to acquire `.aid/design/` and its `README.md` on first use
- [ ] **feature-004 V5 / AC-3 / feature-002 E2 -- the brownfield realization.** After run 2, both
      halves hold: `test ! -f .aid/design/architecture.md` is **true**, and
      `git diff --stat .aid/knowledge/architecture.md` is **non-empty**. A `create` that refuses
      because the destination is populated fails both halves. Recorded together with the run's own
      transcript line showing it did not refuse
- [ ] **feature-004 V8(a):** run 3, with `.aid/design/architecture.md` **absent**, completes and
      leaves `git diff --stat .aid/knowledge/architecture.md` non-empty relative to the state after
      run 2 -- it neither refuses nor names a missing seed. An `update` that requires a seed fails
      here
- [ ] **feature-004 V8(b):** run 4, with the fixture seed present, leaves
      `test ! -f .aid/design/architecture.md` **true** and the C1 doc's diff carrying that seed's
      `## Current direction` content. (a) alone would be satisfied by an `update` that ignores
      seeds, (b) alone by one that demands them; both are required
- [ ] **feature-004 V17, the `hand-authored` half:** across runs 2 and 4,
      `git diff .aid/knowledge/architecture.md` shows **no change to the `source:` line** -- it was
      `hand-authored` at `:3` before and is `hand-authored` after. The `forward-authored` half is
      task-045's
- [ ] **feature-004 V19:** `git diff .aid/knowledge/architecture.md` shows no change to the
      `approved_at_commit:` line, and `bash canonical/aid/scripts/kb/lint-frontmatter.sh` is green
      after each writing run
- [ ] **feature-004 V21 / AC-11:** after each of runs 2, 3 and 4, the `## Contents` set-comparison
      returns empty in **both** directions over `.aid/knowledge/architecture.md` --
      `comm -3` of the sorted `^## ` heading set (minus `Contents`) against the sorted `## Contents`
      link-text set. **Not** `AS02`, which is a bare existence check and template-scoped besides
- [ ] **feature-004 V25's behavioral half:** for each of the four authored runs,
      `grep -c '^phase: .' ` over that run's allocated work `STATE.md` captured to a variable is
      `0`, and the evidence is written into this task's STATE.md notes **before** the work folder is
      removed. A teardown that destroys the record before it is written fails this criterion
- [ ] The step-4 seed is established **before** run 4 begins, by writing it in `design-seed.md`'s
      shape with a known `## Current direction`, and its `## Open questions` is empty so that run 4
      is not a readiness-gate test. Verified by inspecting the seed at fixture-build time, not
      inferred from the run's outcome
- [ ] **Restoration -- the working tree ends where it started.**
      `git diff --exit-code HEAD -- .aid/knowledge/architecture.md .aid/knowledge/decisions.md` is
      clean; `git diff --exit-code HEAD -- .aid/design/` is clean with no untracked file left under
      it; `git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by these runs
      and `git worktree list` registers none of their worktrees. The target is **current `HEAD`**,
      never a sha captured earlier
- [ ] **Nothing outside this task's declared writes is touched:**
      `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` is clean -- no document was
      created, so CC-2's registration path did not fire (every C1/C0/C6/C8 destination and
      `decisions.md` are already declared members at `.aid/settings.yml:41-59`) -- and
      `git status --porcelain profiles/ .claude/ .cursor/` is **identical before and after** the
      task. It neither renders nor reverts
- [ ] Nothing is committed by this task, and no `git add -A` / `git add .` / `git add -u` /
      `git commit -a` is used while task-039's render is live:
      `git diff --cached --name-only` is empty at the end
- [ ] Tests are deterministic and setup/teardown is clean: **four** authored runs and no fifth; a
      fifth means a row built a project of its own instead of using the sequence above. Two
      executions over the same inputs produce the same outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
