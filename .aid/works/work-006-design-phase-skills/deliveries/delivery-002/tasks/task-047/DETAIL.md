# task-047: The engine read proved additive against a `master`-engine baseline

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-047/STATE.md.
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

**Depends on:** task-043

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §8 row **V14** (absent seed
  ⇒ unchanged behavior) with §4a's three bounding properties, closing its **AC-7** and
  REQUIREMENTS **AC-10** -- the one criterion in this work that is about **shipped behavior of
  existing skills**. It also carries the behavioral half of BLUEPRINT criterion 3, which V12's grep
  establishes only statically.
- **Every run happens in a scratch project under `mktemp -d`, never against this repository's own
  `.aid/`.** It writes no path under `.aid/knowledge/`, `.aid/design/`, `.aid/settings.yml` or
  `.aid/works/` in the working tree, which is what makes it schedulable beside task-044, task-045 and
  task-046. It **renders nothing and reverts nothing**; task-039 owns the render and task-048 the
  revert.
- **The baseline is reconstructed from `master`, and that is the whole design of this task.**
  feature-005 §8 V14 says the baseline *"must be **captured first** -- the slot set is agent judgment
  (`canonical/aid/templates/shortcut-engine.md:388-397`), not a recorded artifact, so there is nothing
  to compare against after the fact"*. This task runs after the engine edit has landed, so "first" is
  achieved by **running the unedited engine first**, not by having run it earlier: the baseline copy's
  `.claude/aid/templates/shortcut-engine.md` is overwritten with
  `git show master:profiles/claude-code/.claude/aid/templates/shortcut-engine.md` -- the **rendered**
  engine from `master`, so install paths are already rewritten and the two runs differ in exactly the
  two hunks task-026 added and in nothing else.
- **Fixture policy -- one baseline, four fresh copies.** Each copy is created under `mktemp -d` and
  `git init`-ed with a baseline commit, because `git status --porcelain` returns a real result only
  inside a work tree; each carries this repository's rendered dogfood `.claude/` copied in.
  - **F-noseed-master** -- no `.aid/design/` at all, engine replaced by `master`'s rendered copy.
  - **F-noseed-head** -- no `.aid/design/` at all, engine as this branch renders it.
  - **F-seed-api** -- engine as this branch renders it, plus `.aid/design/api.md` in
    `design-seed.md`'s shape with a distinctive `## Current direction`.
  - **F-seed-document** -- engine as this branch renders it, plus `.aid/design/document.md` in the
    same shape with its own distinctive `## Current direction`.
- **Four runs, each carried only as far as CAPTURE Step 3 and then abandoned.** Nothing downstream of
  CAPTURE is under test -- the engine's later states author REQUIREMENTS through DETAIL and would make
  each run an entire Lite work -- so each run is stopped once its minimal slot set is stated, and the
  scratch copy is discarded. The runs, in this order, because run 1 is the baseline:
  1. `/aid-create-api` in F-noseed-master -- record the CAPTURE minimal slot set verbatim.
  2. `/aid-create-api` in F-noseed-head -- record it again and compare.
  3. `/aid-create-api` in F-seed-api -- the seed is loaded as prior context.
  4. `/aid-create-document` in F-seed-document -- the **hand-authored** half of the same read, since
     `aid-create-document` is a `repurpose: true` G8 collapse skill and never executes the engine
     (feature-005 §4b). This is what makes the read reach all **fourteen** paired artifacts rather
     than thirteen.
- **The three properties §4a fixes are what runs 2 through 4 measure**: **conditional** (run 2 --
  absent seed leaves behavior byte-identical), **non-mutating** (runs 3 and 4 -- the seed is not
  edited, moved or deleted), and **additive** (run 2 again -- no existing bullet, rule or state
  transition changed its effect).
- Out of scope: the twelve foundation skills' behavior (task-040 through task-046); the greppable half
  of V12 and the diff-shape row V13, which are task-026's, task-027's and task-049's; any change to
  the engine or to either `document` body -- this task reads them; authoring any test script under
  `tests/` or adding any bash assertion id (feature-001 AC-3); and the `coverage-parity`
  re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **The baseline is captured before the comparison run, and from `master`'s rendered engine.**
      Run 1 precedes run 2, and F-noseed-master's `.claude/aid/templates/shortcut-engine.md` is
      byte-identical to `git show master:profiles/claude-code/.claude/aid/templates/shortcut-engine.md`
      -- asserted by `diff`, before run 1 starts. A baseline taken from the **canonical** master file
      instead would carry unrewritten `canonical/...` paths and would differ from the run-2 engine in
      more than the two hunks under test
- [ ] **feature-005 V14 / AC-7 / REQUIREMENTS AC-10 -- absent seed ⇒ unchanged behavior.** Neither
      scratch project has a `.aid/design/` directory at all, and the CAPTURE minimal slot set recorded
      in run 2 is **identical** to run 1's. Both slot sets are recorded verbatim in this task's
      STATE.md notes, because the slot set is agent judgment and a "they matched" claim with no
      transcript is unfalsifiable
- [ ] **Run 2 exercised the guard's empty-`{artifact}` half is *not* claimed here.** `/aid-create-api`
      carries `artifact: api`, so run 2 tests the absent-**file** fallback only. The
      empty-`{artifact}` fallback is asserted statically by task-026's criterion over the bullet's own
      text; stating it as behaviorally covered here would be false
- [ ] **BLUEPRINT criterion 3, the seed-present half, behaviorally**: in run 3 the
      `/aid-create-api` doorway loads `.aid/design/api.md` as prior context -- the run's own output
      cites that seed's distinctive `## Current direction` -- and the slot set is narrowed relative to
      run 2 rather than replaced. The seed is an input, never a substitute for the write-up
- [ ] **Non-mutating, in both directions of the read**: after run 3, `.aid/design/api.md` is
      **byte-identical** to the fixture and still in place; after run 4, `.aid/design/document.md` is
      **byte-identical** and still in place. `git status --porcelain .aid/design/` inside each scratch
      copy shows no modification and no deletion
- [ ] **Run 4 reaches the hand-authored half**: `/aid-create-document` loads
      `.aid/design/document.md` as prior context before drafting, which is the read task-027 added
      because that pair never executes the engine. Without run 4 the read would be demonstrated for
      thirteen of the fourteen paired artifacts
- [ ] Each run is stopped at CAPTURE Step 3 and its copy discarded; **four** runs and no fifth, and no
      run is allowed to proceed into the engine's authoring states. A run that scaffolds a whole Lite
      work has left this task's subject
- [ ] Each baseline copy is a git work tree (`git init` plus a baseline commit) **before** its run, so
      an empty `git status --porcelain` inside it is a real result rather than an exit-128 misread
- [ ] **This task mutates no shared tree:** `git status --porcelain` over `.aid/knowledge/`,
      `.aid/design/`, `.aid/settings.yml`, `.aid/works/`, `profiles/`, `.claude/` and `.cursor/` is
      **identical before and after** the task; in particular the repository's own
      `.claude/aid/templates/shortcut-engine.md` is untouched -- only the scratch copies are
      overwritten. `git diff --cached --name-only` is empty, with no `git add -A` / `git add .` /
      `git add -u` / `git commit -a` used while task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: every copy lives under `mktemp -d` and is
      removed on exit **including on failure**; two executions over the same inputs produce identical
      outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
