# task-042: Brownfield testing-strategy lifecycle across both C6 documents

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-042/STATE.md.
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

**Depends on:** task-041

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §11 rows **V4** (this
  task's share), **V5** (testing-strategy), **V8**, **V9**'s `/aid-create-testing-strategy` clause,
  **V10**'s **negative** half, **V19**, **V21** and **V25**'s behavioral half, with §7e as the
  content rule and §8's two-C6-document split as the destination shape. It closes BLUEPRINT criteria
  4 and 5 for the `testing-strategy` artifact.
- **Execution path:** task-039's throwaway render is live; this task **renders nothing and reverts
  nothing**. It runs against this repository's own `.aid/`, whose C6 concern is realized by **two**
  documents -- `.aid/knowledge/test-landscape.md` (**555** lines, `source: hand-authored` at `:3`)
  and `.aid/knowledge/quality-gates.md` (**394** lines, `source: hand-authored` at `:3`) -- and
  restores both. Two C6 docs in one project is a deliberate split the hybrid composition rule
  permits explicitly (`canonical/aid/templates/kb-authoring/domain-doc-matrix.md:366-368`), and the
  split line is the one `quality-gates.md`'s own `summary:` already draws
  (`.aid/knowledge/quality-gates.md:5`).
- **It follows task-041** because both allocate `work-NNN` folders in the shared `.aid/works/` tree
  and both write into the shared `.aid/design/`, and because **V10's two halves must name the same
  framework and version**: task-041 recorded that exact string into its STATE.md notes, and this
  task seeds it.
- **Four authored runs, in this order, and no fifth**, the sequence task-040 establishes:
  1. `/aid-design-testing-strategy` -> writes `.aid/design/testing-strategy.md`, `## Open questions`
     **empty**, its `## Destination` naming the C6 test-landscape half and the gate-policy half
     **separately**, and its `## Current direction` naming the **same test framework and version**
     task-041's seed named.
  2. `/aid-create-testing-strategy` -> realizes into **both** populated C6 documents and deletes the
     seed (V5).
  3. `/aid-update-testing-strategy` with **no seed** -> V8(a).
  4. `/aid-update-testing-strategy` with a fixture seed present -> V8(b); that seed is written by
     hand in `design-seed.md`'s shape **before** run 4 begins.
- **Nothing is created, so CC-2's registration path does not fire here, and that is checked rather
  than assumed.** `quality-gates.md` is already present and already declared
  `quality-gates.md|aid-researcher-quality|required` (`.aid/settings.yml:53`), which is exactly what
  feature-004 §3b would write -- §8b is the reasoning. The creation-and-registration path is
  task-045's, on a scratch project that lacks the document.
- **Restore, and record before restoring**, as task-040 states it: both C6 documents return to
  current `HEAD`, `.aid/design/` returns to its committed content, and every `work-NNN` folder and
  worktree is removed **after** its `phase:`-absence evidence reaches this task's STATE.md notes.
- Out of scope: the readiness gate, the seed-absent refusal, `source: generated` and the repeat
  `create` (task-044); creating `quality-gates.md` and registering it (task-045); FR-8's asking and
  the lane divergence (task-046); any edit to
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` -- task-034 landed the two conditional
  rows and this task only reads them; authoring any test script under `tests/` or adding any bash
  assertion id (feature-001 AC-3); and the `coverage-parity` re-bootstrap.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced
      it** (TEST default: all acceptance criteria from the source feature covered)
- [ ] **feature-004 V4, this task's share:** after run 1,
      `git status --porcelain .aid/knowledge/ .github/` is **empty** and
      `.aid/design/testing-strategy.md` exists
- [ ] **feature-004 V5 -- brownfield realization for `testing-strategy`:** after run 2,
      `test ! -f .aid/design/testing-strategy.md` is **true** and
      `git diff --stat .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md` is
      **non-empty** -- both documents, since this artifact owns two
- [ ] **feature-004 V9, the `/aid-create-testing-strategy` clause:**
      `git diff --name-only .aid/knowledge/` after run 2 lists **`test-landscape.md` and
      `quality-gates.md`** and **not** the C8 doc. A run that names only one of the two C6 documents
      fails
- [ ] **feature-004 V10, the negative half:** the framework version string task-041 recorded appears
      in **neither** C6 document's diff. A version in a C6 doc is a duplicate that will drift (§4
      row 2), and this is the half that catches it. The positive half was task-041's
- [ ] **§4 row 1 holds from the C6 side:** the test doc's CI section gains only the **test-lane
      mapping** -- which suites run in which lane -- and the diff states **no** stage, trigger,
      environment or promotion rule, pointing at the C8 doc for the pipeline instead
- [ ] **feature-004 V8(a):** run 3, with `.aid/design/testing-strategy.md` absent, completes and
      leaves both C6 diffs non-empty relative to the state after run 2 -- no refusal and no complaint
      about a missing seed
- [ ] **feature-004 V8(b):** run 4 leaves `test ! -f .aid/design/testing-strategy.md` **true** and
      the destination diff carrying that fixture seed's `## Current direction` content
- [ ] **feature-004 V19:** `git diff` on both C6 documents shows no change to either file's
      `source:` or `approved_at_commit:` line, and
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` is green after each writing run
- [ ] **feature-004 V21 / AC-11:** after each of runs 2, 3 and 4, the `## Contents` `comm -3`
      set-comparison returns empty in **both** directions over **each** of
      `.aid/knowledge/test-landscape.md` and `.aid/knowledge/quality-gates.md`
- [ ] **feature-004 V25's behavioral half:** for each of the four authored runs,
      `grep -c '^phase: .' ` over that run's allocated work `STATE.md` captured to a variable is
      `0`, recorded into STATE.md notes **before** the work folder is removed
- [ ] The step-4 seed is established **before** run 4 begins and its `## Open questions` is empty
- [ ] **Nothing is created and nothing is registered:**
      `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` is clean, and
      `grep -c 'quality-gates.md|aid-researcher-quality|required' .aid/settings.yml` captured to a
      variable is still `1` -- exactly the entry that was there at `:53` before the task, neither
      duplicated nor rewritten
- [ ] **Restoration:**
      `git diff --exit-code HEAD -- .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md`
      is clean; `git diff --exit-code HEAD -- .aid/design/` is clean with no untracked file left
      under it; `git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by these
      runs and `git worktree list` registers none of their worktrees. The target is **current
      `HEAD`**
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is **identical before and after** the
      task; nothing is committed and no `git add -A` / `git add .` / `git add -u` / `git commit -a`
      is used while task-039's render is live
- [ ] Tests are deterministic and setup/teardown is clean: **four** authored runs and no fifth; two
      executions over the same inputs produce the same outcomes
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
