# task-025: Reverted local render and a working tree restored to its pre-render state

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-025/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-019, task-023

**Scope:**
- Source: BLUEPRINT § Notes -- *"Whichever path a task takes, it must leave
  `git status --porcelain profiles/ .claude/ .cursor/` clean at this gate -- delivery-003 owns
  the committed render (C-5: one full run, never a partial)."* This task is that obligation's
  owner. It is the **single** reverter, as task-024 is the single renderer; every task that
  consumed the render is one of its ancestors, so no revert can land while a consumer is
  still reading the tree.
- Revert the throwaway render task-024 produced across `profiles/`, `.claude/` and `.cursor/`:
  **tracked files restored to current `HEAD`, render-generated untracked files removed.**
- **The restoration target is current `HEAD`, never task-024's manifest bytes.** task-024
  recorded a `sha256sum` manifest of the three trees at wave 13, but that manifest is a record
  of the *working tree at that moment*, not the target. Tasks commit between task-024 and this
  one, and one of them commits a tracked file **inside these trees**: task-009 writes
  `.claude/skills/release-aid/SKILL.md` (feature-001 AC-7/AC-8). Restoring the manifest bytes
  literally would revert that delivered work; restoring to current `HEAD` preserves it by
  construction and stays correct without an enumeration to maintain. The manifest is used as a
  **cross-check** only: after the restore, every path in it matches except those a commit in
  between legitimately changed -- today exactly the one path above, and any residual mismatch
  is a defect of this task rather than an expected difference.
- Restore any Knowledge Base file a verification task mutated and did not restore.
  **task-022 mutates and restores `.aid/knowledge/roadmap.md` only**; task-023 mutates and
  restores **three** -- `roadmap.md`, `backlog.md` **and `tech-debt.md`**, the third because
  `/aid-update-backlog` carries the power to promote confirmed `tech-debt.md` rows and delete
  them there in the same run (task-023 § Scope). Both tasks carry their own restoration
  criteria, so this task's job there is to **confirm** rather than repair -- but a residue
  found is repaired here, and recorded, rather than left for the delivery gate to discover.
- **Backstop the work-folder cleanup, without owning it.** Tasks 015, 021, 022 and 023 each
  allocate `work-NNN` folders and worktrees through the Work Initiation Gate, and each is
  required to remove its own after capturing the `phase:` evidence. `.aid/works/` is tracked,
  not ignored (`.gitignore` lists two specific folders only), so a leftover is a dirty tree
  rather than a harmless artifact. This task asserts none survive, and removes any that do.
- Remove `.aid/knowledge/graph.html` if task-019's `/aid-graph` run left it: it has never
  existed in git history, is neither tracked nor ignored, and leaving it makes the tree dirty
  for delivery-003's own render.
- **Committed outputs are not touched -- and the guard is stated over paths, not over a task
  list.** Everything committed between task-024 and this task stays exactly as committed: `roadmap.md`, `backlog.md`, `.aid/settings.yml`, `.aid/knowledge/README.md`,
  `document-expectations.md`, `tech-debt.md`, `release-tracking.md`, `INDEX.md`,
  `relationships.md` -- **and `.claude/skills/release-aid/SKILL.md`, the one committed
  deliverable that lies inside a tree this task restores.** It is called out by name because
  every other committed path is outside the three trees, so only this one can be destroyed by
  a wholesale restore. Stating the guard over the **paths** rather than over the committers is
  what makes it survive a later pass adding a seventh committer. This task reverts
  **working-tree scaffolding**, never delivered work.
- Out of scope: delivery-003's committed render and the byte-identity gate; and the
  seed-immobility and registration audit, which is task-020 and runs after this task so that
  it audits a clean tree.

**Acceptance Criteria:**
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is **empty** -- the BLUEPRINT's
      standing requirement at this gate, and delivery-003's precondition
- [ ] The restored state matches **current `HEAD`**, never task-024's manifest bytes and never
      an absolute commit: `git diff --exit-code -- profiles/ .claude/ .cursor/` is clean and no
      untracked file remains under any of the three. **No conjunct is stated on the HEAD sha
      itself** -- several tasks commit between task-024 and this task, so HEAD has advanced
      by design, and an unchanged-sha assertion would be
      unsatisfiable. The same rule binds every restoration criterion in this delivery: name the
      content and the current tip, never a sha captured earlier or a commit that has not
      happened yet
- [ ] **task-009's committed file survives this teardown**, which the criterion above already
      implies and this one makes falsifiable on its own:
      `git diff --exit-code HEAD -- .claude/skills/release-aid/SKILL.md` is clean **and**
      `grep -c Unreleased .claude/skills/release-aid/SKILL.md` is still `0`. A restore that
      put the file back to its wave-13 bytes would leave that count at `4` and silently undo
      feature-001 AC-7/AC-8
- [ ] The manifest cross-check is run and its result recorded: every path in task-024's
      `sha256sum` manifest matches after the restore **except** those changed by a commit
      landed in between -- today exactly `.claude/skills/release-aid/SKILL.md`. Any other
      mismatch is a defect of this task, not an expected difference
- [ ] `git status --porcelain .aid/knowledge/` shows no modification to `roadmap.md`,
      `backlog.md` or `tech-debt.md` beyond what their committers landed -- those are the
      Writers columns of the three matching rows in PLAN's shared-resource table, not a list
      kept here. `tech-debt.md` is among them because task-023 mutates and restores it too, and
      `git ls-files .aid/knowledge/graph.html` returns nothing with the path absent from the
      working tree
- [ ] **`git status --porcelain .aid/works/` reports no `work-NNN-*` folder created by any
      verification run**, and `git worktree list` registers no worktree those runs created.
      Any residue is removed here and recorded -- the per-task cleanup belongs to the
      `.aid/works/` Writers column of PLAN's shared-resource table; this criterion is the
      backstop that makes a missed one visible rather than silent
- [ ] **Configuration is idempotent**: re-running this task's restore on an
      already-restored tree changes nothing and exits successfully
- [ ] **No plaintext secrets**: nothing under `.aid/connectors/.secrets/` is created,
      modified or deleted
- [ ] No committed artifact is reverted: `git diff --exit-code HEAD -- .aid/knowledge/
      .aid/settings.yml canonical/ .claude/skills/release-aid/SKILL.md` is clean, so the
      delivery's actual work survives this teardown intact. The fourth path is in the list
      because it is the only committed deliverable that lies **inside** a tree this task
      restores wholesale -- a guard scoped to the first three would not see it
- [ ] All section-6 quality gates pass
