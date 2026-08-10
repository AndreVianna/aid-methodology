# task-024: Throwaway local dogfood render that makes the nine new skills invocable

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-024/STATE.md.
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

**Depends on:** task-014

**Scope:**
- Source: BLUEPRINT § Notes, *How the behavioral criteria above are exercised*. Gate criteria
  8 and 9 require running the new skills, but the render to the five profiles is deferred to
  delivery-003, so at this gate the skills exist only under `canonical/` and are invocable
  from no profile. The prescribed execution path is a **local render into the dogfood tree,
  run as a throwaway and not committed**.
- **This task exists because that render is shared state, not per-task setup.** The later
  tasks that need invocable skills are this task's descendants in the dependency graph, up to
  task-025 (PLAN § *Execution Graph*); no list of them is kept here, because a list kept in
  two places is a list that drifts. Bundling the render into each of them would (a) make any
  two of them unschedulable in parallel -- each render overwrites `profiles/` and `.claude/`
  wholesale and each revert wipes the other's -- and (b) multiply an expensive step by the
  number of consumers, which is what made task-015 oversized in the first place. Cutting it
  once, here, removes both: the render is produced by **exactly one** task, consumed
  read-only by its descendants, and reverted by **exactly one** (task-025).
- Run, in this order (REQUIREMENTS C-5): `build-shortcut-skills.py`, then the **full**
  `run_generator.py` -- never a partial render -- then resync the dogfood `.claude/` from
  `profiles/claude-code/`.
- **Record the pre-render state** so task-025 can restore it, **as content rather than as a
  commit**: the `git status --porcelain profiles/ .claude/ .cursor/` output (expected empty)
  and the `sha256sum` manifest of the three trees, written to this task's STATE.md notes. The
  HEAD sha is recorded only as provenance, **never as a restoration target**.
- **What the manifest is, and what it is not.** It is a record of the *working tree* at wave
  13, and the restoration target it defines is *"tracked content equal to **current** `HEAD`,
  render-generated untracked files removed"* -- **not** "these exact bytes". The distinction
  is load-bearing because several tasks commit between this one and task-025, and one of
  them -- **task-009 -- commits a tracked file inside these very trees**: `.claude/skills/release-aid/SKILL.md` (feature-001 AC-7/AC-8). That one
  path is named because it is the only committed artifact anywhere under the three trees, and
  it is a path, not a population. Restoring the manifest bytes literally would revert that
  delivered work.
  Restoring to current `HEAD` preserves it by construction, and needs no enumeration to stay
  correct if a later pass adds another committer. The manifest's remaining job is a
  **cross-check**: after task-025 restores, every path in it must match except those a commit
  in between legitimately changed -- today exactly one, the path above.
- **Every task that commits while this render is live stages explicit paths only.** The render
  sits uncommitted in `profiles/`, `.claude/` and `.cursor/` from this wave until task-025, so
  a `git add -A`, `git add .` or `git commit -a` in any committing task would commit it, which
  BLUEPRINT § Notes and REQUIREMENTS C-5 forbid. Every task that commits inside this window
  carries the bound as its own acceptance criterion; this bullet is where the rule is stated
  once.
- **Nothing produced here is committed.** The rendered `profiles/`, `.claude/` and `.cursor/`
  trees are working-tree state only, live for the duration of waves this task gates, and are
  reverted by task-025 before the delivery gate. delivery-003 owns the committed render, and
  runs it once against the settled canonical tree.
- Out of scope: committing any part of the render; editing `canonical/` (the nine skills and
  their catalog rows are already authored by task-010..task-014); and the byte-identity gate,
  which is delivery-003's.

**Acceptance Criteria:**
- [ ] `build-shortcut-skills.py` runs first and overwrites no hand-authored body:
      `git diff --exit-code canonical/skills/aid-*-{roadmap,mvp,backlog}/` is clean
      afterwards (feature-003 V2, re-confirmed at the point the render consumes the catalog)
- [ ] The **full** `run_generator.py` is run, never a partial render (C-5), and the dogfood
      `.claude/` is resynced from `profiles/claude-code/` afterwards
- [ ] All nine new skills are present and invocable in the dogfood tree:
      `ls -d .claude/skills/aid-{design,create,update}-{roadmap,mvp,backlog}` returns 9
- [ ] The three feature-002 templates reached every profile:
      `find profiles -path '*/aid/templates/design-folder-readme.md' | wc -l` captured to a
      variable -> `5`, likewise for `design-seed.md` and `design-lifecycle.md`
      (feature-002 §7 B2 part (a); part (b) is task-016's)
- [ ] **Configuration is idempotent**, evidenced by a command that can actually produce the
      evidence: capture
      `find profiles .claude .cursor -type f -print0 | sort -z | xargs -0 sha256sum` to a
      file, re-run `build-shortcut-skills.py` and the full `run_generator.py`, capture it
      again, and `diff` the two captures -> empty. `git status --porcelain` is **not** the
      oracle here: it emits two status characters and a path per line and no content hash, so
      it cannot witness byte-identity
- [ ] **No plaintext secrets** are introduced: the render adds no file under
      `.aid/connectors/.secrets/` and no credential-bearing path
- [ ] The pre-render state is recorded in this task's STATE.md notes as **content** -- the
      pre-render `git status --porcelain profiles/ .claude/ .cursor/` output plus the
      `sha256sum` manifest of the three trees -- so task-025 can restore from that record
      without re-deriving it. The HEAD sha is recorded as provenance only and is **not** a
      restoration target
- [ ] The note recording the manifest **states the restoration target in words** -- tracked
      content equal to current `HEAD`, render-generated untracked files removed -- and names
      the one committed path that lies inside these trees,
      `.claude/skills/release-aid/SKILL.md`. A note that records only bytes hands task-025 an
      instruction that reverts task-009's commit
- [ ] Nothing is committed: `git diff --cached --name-only` is empty at the end of this task
- [ ] All section-6 quality gates pass
