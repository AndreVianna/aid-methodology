# task-048: Reverted local render and a working tree restored to its pre-render state

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-048/STATE.md.
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

**Type:** CONFIGURE

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-044, task-045, task-046, task-047

**Scope:**
- Source: BLUEPRINT § Notes -- the throwaway local render is *"**not committed**, with
  `git status --porcelain profiles/ .claude/ .cursor/` clean at this gate"*. This task is that
  obligation's owner. It is the **single** reverter, as task-039 is the single renderer; every task
  that consumed the render is one of its ancestors, so no revert can land while a consumer is still
  reading the tree. Its four dependencies are the four leaves of the scratch-project fan -- the last
  consumers.
- Revert the throwaway render task-039 produced across `profiles/`, `.claude/` and `.cursor/`:
  **tracked files restored to current `HEAD`, render-generated untracked files removed.**
- **The restoration target is current `HEAD`, never task-039's manifest bytes.** task-039 recorded a
  `sha256sum` manifest of the three trees, but that manifest is a record of the *working tree at that
  moment*, not the target. One tracked deliverable already lies **inside** these trees:
  `.claude/skills/release-aid/SKILL.md`, committed by delivery-001 (feature-001 AC-7/AC-8). Restoring
  the manifest bytes literally would revert delivered work; restoring to current `HEAD` preserves it
  by construction and stays correct without an enumeration to maintain. The manifest is used as a
  **cross-check** only: after the restore, every path in it matches except those a commit in between
  legitimately changed, and any residual mismatch is a defect of this task rather than an expected
  difference.
- **Remove any `canonical/skills/` residue the build helper left.** task-039 ran
  `build-shortcut-skills.py`, which writes `SKILLS_ROOT / <name> / "SKILL.md"` for every
  non-`repurpose` row (`:363-377`). All thirty-six rows this work adds are `repurpose: true`, so the
  helper's output should be byte-identical and there should be nothing to remove -- but the tree is
  declared as this task's write so that a residue is **repaired here** rather than discovered by the
  delivery gate.
- **Confirm, rather than repair, the Knowledge Base restorations the behavioral tasks own.** task-040
  mutates and restores `architecture.md` and `decisions.md`; task-041 `technology-stack.md` and
  `decisions.md`; task-042 `test-landscape.md` and `quality-gates.md`; task-043
  `infrastructure.md`. Each carries its own restoration criterion, so this task's job there is to
  **confirm** -- but a residue found is repaired here, and recorded, rather than left for the gate to
  discover. The document set is the Writers column of the matching rows in PLAN's shared-resource
  table, not a list maintained here.
- **Backstop the work-folder and seed cleanup, without owning it.** task-040 through task-047 each
  allocate `work-NNN` folders -- the first four in this repository's tracked `.aid/works/`, the last
  four inside their own `mktemp -d` scratch projects -- and each is required to remove its own after
  capturing the `phase:` evidence. `.aid/works/` is tracked, not ignored, so a leftover is a dirty
  tree rather than a harmless artifact. This task asserts none survive and removes any that do; the
  same holds for any seed left under `.aid/design/`.
- **Committed outputs are not touched, and the guard is stated over paths, not over a task list.**
  Everything committed by task-026 through task-038 stays exactly as committed -- the twenty-seven
  new skill directories and their rows in `canonical/aid/templates/shortcut-catalog.yml`, the engine
  edit, the two `document` bodies, the four shipped descriptions, and the two `kb-authoring` doctrine
  files -- **and `.claude/skills/release-aid/SKILL.md`, the one committed deliverable that lies
  inside a tree this task restores wholesale.** It is called out by name because every other
  committed path is outside the three trees, so only this one can be destroyed by a wholesale
  restore. Stating the guard over the **paths** rather than over the committers is what makes it
  survive a later pass adding another committer. This task reverts **working-tree scaffolding**,
  never delivered work.
- Out of scope: delivery-003's committed render, the byte-identity gate and the `coverage-parity`
  re-bootstrap; every count-bearing surface, `check-skill-counts.mjs` included; and the static
  verification sweep, which is task-049 and runs **after** this task so that it audits a clean tree.

**Acceptance Criteria:**
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is **empty** -- the BLUEPRINT's standing
      requirement at this gate, and delivery-003's precondition
- [ ] The restored state matches **current `HEAD`**, never task-039's manifest bytes and never an
      absolute commit: `git diff --exit-code -- profiles/ .claude/ .cursor/` is clean and no untracked
      file remains under any of the three. **No conjunct is stated on the HEAD sha itself** -- tasks
      committed between task-039 and this task, so HEAD has advanced by design and an unchanged-sha
      assertion would be unsatisfiable
- [ ] **delivery-001's committed file survives this teardown**, which the criterion above already
      implies and this one makes falsifiable on its own:
      `git diff --exit-code HEAD -- .claude/skills/release-aid/SKILL.md` is clean **and**
      `grep -c Unreleased .claude/skills/release-aid/SKILL.md` captured to a variable is still `0`. A
      restore that put the file back to its pre-render bytes would silently undo feature-001
      AC-7/AC-8
- [ ] The manifest cross-check is run and its result recorded: every path in task-039's `sha256sum`
      manifest matches after the restore **except** those changed by a commit landed in between. Any
      other mismatch is a defect of this task, not an expected difference
- [ ] `git diff --exit-code HEAD -- canonical/skills/` is clean and no untracked file remains under
      it -- the build helper left no residue, or the residue was removed here and recorded
- [ ] The six mutated Knowledge Base documents are back at `HEAD`:
      `git diff --exit-code HEAD -- .aid/knowledge/architecture.md .aid/knowledge/technology-stack.md .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md .aid/knowledge/infrastructure.md .aid/knowledge/decisions.md`
      is clean. Each behavioral task carries its own restoration criterion, so a repair made here is
      **recorded as a residue found**, not treated as this task's routine work
- [ ] `git diff --exit-code HEAD -- .aid/design/` is clean with no untracked file under it, and
      `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` is clean -- no behavioral run
      created a document in this repository, so CC-2's registration path never fired here
- [ ] **`git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by any behavioral
      run**, and `git worktree list` registers no worktree those runs created. Any residue is removed
      here and recorded -- the per-task cleanup belongs to the `.aid/works/` Writers column of PLAN's
      shared-resource table; this criterion is the backstop that makes a missed one visible rather
      than silent
- [ ] **Configuration is idempotent**: re-running this task's restore on an already-restored tree
      changes nothing and exits successfully
- [ ] **No plaintext secrets**: nothing under `.aid/connectors/.secrets/` is created, modified or
      deleted
- [ ] No committed artifact is reverted:
      `git diff --exit-code HEAD -- canonical/ .aid/knowledge/ .aid/settings.yml .claude/skills/release-aid/SKILL.md`
      is clean, so the delivery's actual work -- the twenty-seven skill directories, their catalog
      rows, the engine edit, the two `document` bodies, the four shipped descriptions and the two
      doctrine files -- survives this teardown intact. The fourth path is in the list because it is
      the only committed deliverable that lies **inside** a tree this task restores wholesale; a
      guard scoped to the first three would not see it
- [ ] Nothing new is committed by this task: `git diff --cached --name-only` is empty at the end, and
      `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] All section-6 quality gates pass
