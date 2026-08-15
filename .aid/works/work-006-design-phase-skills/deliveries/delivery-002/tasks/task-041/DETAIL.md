# task-041: Brownfield stack lifecycle, and the version that lands in the C0 doc

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-041/STATE.md.
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

**Depends on:** task-040

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V4** (this
  task's share), **V5** (stack), **V8**, **V9**'s `/aid-create-stack` clause, **V10**'s **positive**
  half, **V19**, **V21** and **V25**'s behavioral half. It closes BLUEPRINT criteria 4 and 5 for the
  `stack` artifact.
- **Execution path:** task-039's throwaway render is already live; this task **renders nothing and
  reverts nothing**. It runs against this repository's own `.aid/`, where
  `.aid/knowledge/technology-stack.md` is **255 lines** with `source: hand-authored` (`:3`) -- the
  populated as-built destination the row is about -- and restores every document it touches.
- **It follows task-040 rather than running beside it** for one concrete reason: both allocate
  `work-NNN` folders in the shared, tracked `.aid/works/` tree and both write seeds into the shared
  `.aid/design/`. Two concurrent allocators in one tree is the hazard the serialisation prevents;
  the two artifacts' KB destinations are disjoint, the trees are not.
- **Four authored runs, in this order, and no fifth**, the same sequence task-040 establishes:
  1. `/aid-design-stack` -> writes `.aid/design/stack.md`, `## Open questions` **empty**, its
     `## Destination` naming **two** destinations -- this project's C0 doc and its D doc (§5, §7d).
  2. `/aid-create-stack` -> realizes into the populated C0 doc and deletes the seed (V5).
  3. `/aid-update-stack` with **no seed** -> V8(a).
  4. `/aid-update-stack` with a fixture seed present -> V8(b). The step-4 seed is written by hand in
     `design-seed.md`'s shape with a known `## Current direction`, **before** run 4 begins.
- **The seed names a test framework and its version, and that is a fixture requirement shared with
  task-042.** V10 is one row measured on two diffs: here the version string must **appear** in the
  C0 doc's diff; in task-042 it must appear in **neither** C6 document's diff. So this task's
  `## Current direction` names a specific test framework **and** its version, and records that exact
  string into this task's STATE.md notes so task-042 can seed the same one. Without the shared
  string the row is vacuous -- each half would be measured against a different framework.
- **`decisions.md` is a declared destination here, not an admitted side effect.** `/aid-design-stack`
  records the D doc as its second destination and `/aid-create-stack` writes the rejected
  alternatives there when the seed's `## Options considered` carries one (§7d). The step-1 seed
  **does** carry a rejected alternative, so the D-doc write is expected rather than conditional in
  this task, and `.aid/knowledge/decisions.md` is restored to `HEAD` at the end. In this repository
  the D doc is already present and declared `required` (`.aid/settings.yml:58`;
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md:322`), so nothing is created and CC-2's
  registration path does not fire.
- **Restore, and record before restoring**, exactly as task-040 states it: the two KB documents
  return to current `HEAD`, `.aid/design/` returns to its committed content, and every `work-NNN`
  folder and worktree is removed **after** its `phase:`-absence evidence reaches this task's
  STATE.md notes.
- Out of scope: the readiness gate, the seed-absent refusal, `source: generated` and the repeat
  `create` (task-044); the absent-destination creation path (task-045); FR-8's asking and the lane
  divergence (task-046); the other three artifacts; authoring any test script under `tests/` or
  adding any bash assertion id (feature-001 AC-3); and the `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V4, this task's share:** after run 1,
      `git status --porcelain .aid/knowledge/ .github/` is **empty** and `.aid/design/stack.md`
      exists
- [ ] **feature-004 V5 -- brownfield realization for `stack`:** after run 2,
      `test ! -f .aid/design/stack.md` is **true** and
      `git diff --stat .aid/knowledge/technology-stack.md` is **non-empty**
- [ ] **feature-004 V9, the `/aid-create-stack` clause:** `git diff --name-only .aid/knowledge/`
      after run 2 lists the **C0** doc, **plus the D doc** -- the seed carried a rejected
      alternative, so it appears -- and **never** a C1, C6 or C8 doc. Writing into another
      *artifact's* destination is the failure; the D doc is not another artifact's destination,
      because no skill in this feature owns it
- [ ] **feature-004 V10, the positive half:** the version string the step-1 seed named appears in
      the C0 doc's diff, and that exact string is recorded into this task's STATE.md notes for
      task-042 to seed. task-042 asserts the negative half over both C6 documents
- [ ] **feature-004 V8(a):** run 3, with `.aid/design/stack.md` absent, completes and leaves the C0
      doc's diff non-empty relative to the state after run 2 -- no refusal and no complaint about a
      missing seed
- [ ] **feature-004 V8(b):** run 4 leaves `test ! -f .aid/design/stack.md` **true** and the C0 doc's
      diff carrying that fixture seed's `## Current direction` content
- [ ] **feature-004 V19:** `git diff` on the C0 doc and on the D doc shows no change to either
      file's `source:` or `approved_at_commit:` line, and
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` is green after each writing run
- [ ] **feature-004 V21 / AC-11:** after each of runs 2, 3 and 4, the `## Contents` `comm -3`
      set-comparison returns empty in **both** directions over `.aid/knowledge/technology-stack.md`,
      and over `.aid/knowledge/decisions.md` for any run that wrote it
- [ ] **feature-004 V25's behavioral half:** for each of the four authored runs,
      `grep -c '^phase: .' ` over that run's allocated work `STATE.md` captured to a variable is
      `0`, recorded into STATE.md notes **before** the work folder is removed
- [ ] The step-4 seed is established **before** run 4 begins and its `## Open questions` is empty, so
      run 4 is not a readiness-gate test. Verified by inspecting the seed at fixture-build time
- [ ] **Restoration:**
      `git diff --exit-code HEAD -- .aid/knowledge/technology-stack.md .aid/knowledge/decisions.md`
      is clean; `git diff --exit-code HEAD -- .aid/design/` is clean with no untracked file left
      under it; `git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by these
      runs and `git worktree list` registers none of their worktrees. The target is **current
      `HEAD`**
- [ ] `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` is clean -- no document was
      created, so CC-2's registration path did not fire -- and
      `git status --porcelain profiles/ .claude/ .cursor/` is **identical before and after** the
      task
- [ ] Nothing is committed and no `git add -A` / `git add .` / `git add -u` / `git commit -a` is used
      while task-039's render is live: `git diff --cached --name-only` is empty at the end
- [ ] Tests are deterministic and setup/teardown is clean: **four** authored runs and no fifth; two
      executions over the same inputs produce the same outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
