# task-043: Brownfield cicd lifecycle, and the gate policy that stays out of the C8 doc

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-043/STATE.md.
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

**Depends on:** task-042

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V4** (this
  task's share), **V5** (cicd), **V8**, **V9**'s `/aid-create-cicd` clause, **V11**, **V19**,
  **V21** and **V25**'s behavioral half, with §7f as the content rule and §4 rows 1, 3 and 4 read
  from the C8 side. It closes BLUEPRINT criteria 4 and 5 for the `cicd` artifact and is the last of
  the four lifecycle tasks.
- **Execution path:** task-039's throwaway render is live; this task **renders nothing and reverts
  nothing**. It runs against this repository's own `.aid/`, where `.aid/knowledge/infrastructure.md`
  is **315** lines with `source: hand-authored` (`:3`) and realizes the template's
  `## Deployment Pipeline` as the live `## CI/CD Pipeline` (`:99`) -- which is precisely why §4
  states ownership over **topics** resolved to headings at DESIGN time rather than over literal
  template headings.
- **It follows task-042** because all four lifecycle tasks allocate `work-NNN` folders in the shared,
  tracked `.aid/works/` tree and write seeds into the shared `.aid/design/`.
- **Four authored runs, in this order, and no fifth**, the sequence task-040 establishes:
  1. `/aid-design-cicd` -> writes `.aid/design/cicd.md`, `## Open questions` **empty**, its
     `## Destination` naming this project's C8 doc, and its `## Current direction` **naming a
     blocking gate** -- which is the precondition V11 needs.
  2. `/aid-create-cicd` -> realizes into the populated C8 doc and deletes the seed (V5).
  3. `/aid-update-cicd` with **no seed** -> V8(a).
  4. `/aid-update-cicd` with a fixture seed present -> V8(b); that seed is written by hand in
     `design-seed.md`'s shape **before** run 4 begins.
- **V11 is the row this task exists to make falsifiable.** The step-1 seed names a blocking gate, so
  a `create` that copies the policy across the concern boundary has something to copy. The C8 diff
  must name the **stage** and **cite** the gate doc, and must contain no threshold, no
  blocking/advisory verdict and no waiver rule -- §4 row 4's non-owner half, whose owner is
  `/aid-*-testing-strategy` (task-036, exercised in task-042).
- **Nothing is created here, and `.github/` is not touched.** `infrastructure.md` is present and
  declared `infrastructure.md|aid-researcher-quality|required` (`.aid/settings.yml:55`), so CC-2's
  registration path does not fire; the absent-C8-document creation path is task-045's, on a scratch
  project. And §7f's production-config rule is opt-in per run: no run in this task asks for a
  workflow file, so no file under `.github/` changes.
- **Restore, and record before restoring**, as task-040 states it: the C8 document returns to current
  `HEAD`, `.aid/design/` returns to its committed content, and every `work-NNN` folder and worktree
  is removed **after** its `phase:`-absence evidence reaches this task's STATE.md notes.
- Out of scope: the readiness gate, the seed-absent refusal, `source: generated` and the repeat
  `create` (task-044); creating an absent C8 document and registering it (task-045); FR-8's asking
  and the Conformance-Lane divergence (task-046); emitting any workflow file; authoring any test
  script under `tests/` or adding any bash assertion id (feature-001 AC-3); and the
  `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V4, this task's share:** after run 1,
      `git status --porcelain .aid/knowledge/ .github/` is **empty** and `.aid/design/cicd.md`
      exists. The `.github/` conjunct is the one that fails if a `cicd` design edits a workflow file
- [ ] **feature-004 V5 -- brownfield realization for `cicd`:** after run 2,
      `test ! -f .aid/design/cicd.md` is **true** and
      `git diff --stat .aid/knowledge/infrastructure.md` is **non-empty**. With task-040, task-041
      and task-042, V5 now holds for all four artifacts
- [ ] **feature-004 V9, the `/aid-create-cicd` clause:** `git diff --name-only .aid/knowledge/`
      after run 2 lists the **C8** doc and **not** the C6 doc(s) -- neither `test-landscape.md` nor
      `quality-gates.md`
- [ ] **feature-004 V11:** the C8 diff **names the stage and cites the gate doc**, and
      `grep -niE 'threshold|blocks the merge|waive'` over that diff returns **nothing** (§4 row 4).
      The step-1 seed named a blocking gate, so this is a real negative rather than a vacuous one
- [ ] **§4 rows 1 and 3 hold from the C8 side:** the diff states no which-suites-run claim (C6) and
      no build-tool **version** (C0)
- [ ] **feature-004 V8(a):** run 3, with `.aid/design/cicd.md` absent, completes and leaves the C8
      diff non-empty relative to the state after run 2 -- no refusal and no complaint about a missing
      seed
- [ ] **feature-004 V8(b):** run 4 leaves `test ! -f .aid/design/cicd.md` **true** and the C8 diff
      carrying that fixture seed's `## Current direction` content. With task-040..task-042, V8 now
      holds in both directions for all four artifacts
- [ ] **feature-004 V19:** `git diff .aid/knowledge/infrastructure.md` shows no change to its
      `source:` or `approved_at_commit:` line, and
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` is green after each writing run
- [ ] **feature-004 V21 / AC-11:** after each of runs 2, 3 and 4, the `## Contents` `comm -3`
      set-comparison returns empty in **both** directions over `.aid/knowledge/infrastructure.md`
- [ ] **feature-004 V25's behavioral half:** for each of the four authored runs,
      `grep -c '^phase: .' ` over that run's allocated work `STATE.md` captured to a variable is
      `0`, recorded into STATE.md notes **before** the work folder is removed
- [ ] The step-4 seed is established **before** run 4 begins and its `## Open questions` is empty
- [ ] **Nothing is created, nothing registered, no workflow file emitted:**
      `git status --porcelain .aid/settings.yml .aid/knowledge/README.md .github/` is clean, and
      `grep -c 'infrastructure.md|aid-researcher-quality|required' .aid/settings.yml` captured to a
      variable is still `1`
- [ ] **Restoration:** `git diff --exit-code HEAD -- .aid/knowledge/infrastructure.md` is clean;
      `git diff --exit-code HEAD -- .aid/design/` is clean with no untracked file left under it;
      `git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by these runs and
      `git worktree list` registers none of their worktrees. The target is **current `HEAD`**
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is **identical before and after** the
      task; nothing is committed and no `git add -A` / `git add .` / `git add -u` / `git commit -a`
      is used while task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: **four** authored runs and no fifth; two
      executions over the same inputs produce the same outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
