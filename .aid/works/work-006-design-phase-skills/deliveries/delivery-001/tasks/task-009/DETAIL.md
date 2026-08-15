# task-009: `release-aid` drain rewired onto `backlog.md`

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-009/STATE.md.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-012, task-023

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §4b (AC-7, AC-8);
  feature-003 §5's second transition row, which names `release-aid` as its owner. Reach is
  **dogfood only** -- `.claude/skills/release-aid/SKILL.md` is repo-local and absent from
  `canonical/skills/`.
- **Ordered after task-012 for content, and after task-023 for shared state. Both edges are
  load-bearing.**
  - *task-012 (content):* the rewritten § 3.1 keys the drain on two things task-012 fixes and
    nothing else defines -- the section name `## Next Release` (task-012 authors it as *"the
    committed slice `release-aid` drains"*) and the `Title` column as the key the drain
    matches on, since release-note bullets carry no id. Authoring these instructions before
    `backlog.md`'s shape exists would let the two disagree with no oracle catching it. This
    edge also places the task after feature-002's whole commit block, which gate criterion
    2's diff range requires.
  - *task-023 (shared state):* **this task writes a tracked file inside the shared render
    tree** -- `.claude/skills/release-aid/SKILL.md` is under `.claude/`, is tracked
    (`git ls-files` returns it) and is not ignored (`git check-ignore` exits 1). The tasks
    that read those three trees as a whole are the Readers column of PLAN's
    `profiles/` + `.claude/` + `.cursor/` row. The `023` edge is chosen because task-023 is the
    **last** such reader that is not already this task's ancestor through the `012` edge;
    ordering after it clears every one of them at once. This task also reads `canonical/` as a whole
    (`git diff --exit-code -- canonical/`), which task-013 and task-014 write under. The
    task-023 edge places this task after the last of them. Note what does **not** happen:
    task-024's render is additive on that path -- the dogfood `.claude/skills/` carries
    `release-aid` and `generate-profile` over and above the profile's set -- so the render
    never overwrites this file. The hazard is read/write, not data loss, and the edge
    settles both.
- **Stage exactly one path, and never a wildcard.** This task runs at derived wave 19, inside
  the window in which task-024's throwaway five-profile render sits **uncommitted** in
  `profiles/`, `.claude/` and `.cursor/`. It is the only task in the delivery that commits a
  file inside those trees, so it is also the only one whose natural `git add` reaches them.
  The commit stages `.claude/skills/release-aid/SKILL.md` and nothing else -- never
  `git add -A`, `git add .`, `git add -u` or `git commit -a`, any of which would commit the
  render that BLUEPRINT § Notes and REQUIREMENTS C-5 forbid committing here and that task-025
  exists to revert. Every other task that commits while the render is live carries the same
  bound in its own criteria; task-024 § Scope states the rule once.
- Rewrite § 3.1 (*Release notes / changelog ledger*) of **Step 3 -- Update documentation &
  release notes**: instead of renaming `## Unreleased` to the version heading and opening a
  fresh empty one, read the committed items from `.aid/knowledge/backlog.md` §
  `## Next Release`, write a new `release-tracking.md` version section from them, and remove
  them from `backlog.md`. `backlog.md` is the source, **never `roadmap.md`** -- the roadmap
  works at a coarser granularity and holds no items.
- Remove § 3.1's dead instruction to *"add a row to the file's trailing `## Change Log`
  table"* -- PR #183 deleted that table (AC-8).
- Restate § 3.1's sanity check (*"Unreleased holds already-shipped items"*) against
  `backlog.md`'s committed slice.
- Step 4: the staging line that adds `.aid/knowledge/release-tracking.md` also stages
  `.aid/knowledge/backlog.md`.
- Step 9: replace the *"the next run starts from a clean Unreleased"* close-out check with
  a verification that the drained items are absent from `backlog.md` and present in the new
  `release-tracking.md` version section.
- The skill keeps **no** explanatory mention of the retired section: it is an instruction
  set for the *next* release, not a history, and that record lives in `release-tracking.md`'s
  own version sections. That is what makes AC-7's zero-count reachable rather than aspirational.
- Out of scope: the adopter-facing counterpart, which is a **documented manual step** in
  `document-expectations.md` § `### backlog.md` (task-017), since adopters receive no
  `release-aid`; giving that drain an executable canonical home, which is out of scope
  work-wide and **transferred to `.aid/knowledge/tech-debt.md` by task-017**, which writes
  the inventory row -- "routed to tech-debt" is a transfer only when a task performs it, and
  task-017 is that task; and the one-time retirement of `## Unreleased` from
  `release-tracking.md` itself, which needs `backlog.md` to exist and is task-018.

**Acceptance Criteria:**
- [ ] AC-7 oracle: `grep -c Unreleased .claude/skills/release-aid/SKILL.md` -> `0` (it is
      `4` today), **and** `grep -n 'backlog.md' .claude/skills/release-aid/SKILL.md` names it
      inside § 3.1 as the drain source
- [ ] AC-8 oracle: `grep -c 'Change Log' .claude/skills/release-aid/SKILL.md` -> `0` (it is
      `1` today). The count form is used rather than a line anchor because the removal itself
      shifts every subsequent line
- [ ] feature-003 V19's textual half:
      `grep -c 'roadmap.md' .claude/skills/release-aid/SKILL.md` -> `0`
- [ ] Step 4's `git add` list and Step 9's close-out check each name `.aid/knowledge/backlog.md`
- [ ] `git diff --exit-code -- canonical/` is clean for this task -- `release-aid` has no
      canonical counterpart, which is precisely why AC-9's adopter path is a separately-owned
      documented step
- [ ] The rewritten § 3.1 describes a **move**: items removed from `backlog.md` in the same
      run they are added to the new version section, matching feature-003 §5's move-not-copy
      rule so V18 stays checkable
- [ ] The drain's section name and matched key are taken from `backlog.md`'s shape **as
      task-012 authored it**, not paraphrased:
      `grep -c '## Next Release' .claude/skills/release-aid/SKILL.md` -> `>= 1` with the
      string byte-equal to the heading `/aid-create-backlog`'s body writes, and § 3.1 names
      the `Title` column as the key it matches on
- [ ] **The commit stages exactly one path**: `git diff --cached --name-only` immediately
      before it returns the single line `.claude/skills/release-aid/SKILL.md`, and no
      wildcard staging form (`git add -A`, `git add .`, `git add -u`, `git commit -a`) is
      used. The render is live and uncommitted throughout this task's window, so a wildcard
      add commits it
- [ ] After the commit, `git status --porcelain profiles/ .claude/ .cursor/` reports
      **exactly what task-024 left, minus the now-committed
      `.claude/skills/release-aid/SKILL.md`** -- the render's own entries are all still
      present and uncommitted. It is not asserted clean: the render is live at this wave by
      design, and a clean result here would mean the render had been committed
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
