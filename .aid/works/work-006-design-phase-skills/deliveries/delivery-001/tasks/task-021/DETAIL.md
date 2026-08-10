# task-021: This repository's `backlog.md` instance and its registration

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-021/STATE.md.
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

**Depends on:** task-015

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §3b, §6b, §8 V15;
  feature-001 §1e and §6 step 4. REQUIREMENTS CC-2 makes the registration an **effect of
  running the skill**, so this task runs the skills rather than hand-writing the document or
  the entries.
- **Two reasons this is its own task, and neither is arbitrary.** Sizing: each authored run
  allocates a `work-NNN` folder and executes feature-002 §3e's full-verify loop (mechanical
  grounding check, clean-context `aid-reviewer` dispatch writing a ledger,
  `grade.sh --explain`, 3-cycle circuit breaker). And **shared mutable state**: this task and
  task-015 both append to `.aid/settings.yml`'s `knowledge.doc_set` list and both add a row
  to `.aid/knowledge/README.md`'s Completeness table **and increment its doc-set count line**.
  Two concurrent increments of one count corrupt it, so the `task-015` edge is a
  serialisation edge, not merely an ordering preference.
- **How the skills are invocable** (BLUEPRINT § Notes): task-024 has already run
  `build-shortcut-skills.py` and the full `run_generator.py` and resynced the dogfood
  `.claude/`. This task **renders nothing and reverts nothing** -- it reads that tree.
  delivery-003 owns the committed render (C-5: one full run, never a partial).
- Run, in order: `/aid-design-backlog`, `/aid-create-backlog` -- **two authored runs**: both *realize*, so both allocate a
  `work-NNN` folder. Neither is a routing exit or a refusal.
- **Record, for each of the two runs, the work folder it allocated and that its `STATE.md`
  carries no `phase:` value**, into this task's STATE.md notes -- the V23 evidence task-023
  aggregates -- **then remove both work folders and their worktrees.** `.aid/works/` is
  tracked, not ignored, so a leftover allocation makes the tree dirty for every downstream
  task. This task owns the runs it makes; task-025 carries only the backstop assertion.
- **Commit the outputs only**: `.aid/knowledge/backlog.md`, the one `.aid/settings.yml`
  `knowledge.doc_set` line, and `.aid/knowledge/README.md`'s one Completeness row plus its
  incremented doc-set count.
- Nothing is promoted without explicit per-item confirmation (feature-003 §5), so the
  document may be created with no items. **Record the outcome either way** -- how many
  `tech-debt.md` rows the confirm gate promoted, and their ids -- because task-020's V18 and
  V20 need to know whether this repository's own id sets are non-empty or whether it must
  construct a fixture to keep those rows able to fail. The `## Unreleased` items are **not**
  migrated here; that is task-018.
- Out of scope: the render (task-024) and its revert (task-025); `roadmap.md` and its
  `## MVP` section (task-015); the behavioral verification sweeps (task-016, task-022,
  task-023); the `## Unreleased` content migration (task-018); the item-uniqueness rows V18
  and V20, which are task-020's because they must read the KB in its final state; and the
  generated summaries (task-019, delivery-003).

**Acceptance Criteria:**
- [ ] **V15, the `backlog.md` half.** Absent `backlog.md` -> `/aid-create-backlog` -> the
      file exists and carries its four `create`-time headings (`## Contents`,
      `## Next Release`, `## Prioritized`, `## Gotchas`); `git diff .aid/settings.yml` shows
      **exactly one** added line, byte-equal to `    - backlog.md|skill-self|required`;
      `README.md`'s Completeness table gains **exactly one** row whose `Status` cell is the
      literal `Created (skill-self)`; and its doc-set count line increments by 1. A run that
      creates the document but skips either surface fails; so does one that writes
      `conditional`
- [ ] The `## Contents` index is the house link form over exactly the document's three
      content sections, matching the form `roadmap.md` uses (§3a, §3b)
- [ ] **V14**: `bash canonical/aid/scripts/kb/kb-actback-task.sh check --doc-set <resolved TSV>
      --kb-dir .aid/knowledge` emits `| backlog.md | Gotchas | present |` and no `absent` row
      for `backlog.md`. Task-008's C7 arm is what makes this check live, so it can fail
- [ ] **V11**, `backlog.md`'s half: `lint-frontmatter.sh --root .aid/knowledge --verbose`
      exits 0 with no `[FM-MISSING]`/`[FM-INVALID]` naming `backlog.md` **and** `backlog.md`
      not on a `SKIP` line
- [ ] **V12** (feature-001 AC-5), `backlog.md`'s half:
      `grep -nE '^## (Change Log|Revision History)|^changelog:|work-[0-9]{3}|\.aid/works/' .aid/knowledge/backlog.md`
      returns no match
- [ ] **V13**: `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge`
      exits 0 -- no `Location` cell written as `path:LINE`
- [ ] **V5**, this task's artifact: `.aid/design/backlog.md` is present before `create` and
      absent after
- [ ] Every promoted row, if any, is a **move**: it is absent from `tech-debt.md` afterwards
      and carries its original `ID` unchanged, so V18's `comm -12` compares like with like
- [ ] The promotion outcome is recorded in this task's STATE.md notes -- the count of
      promoted rows and their ids, or an explicit zero -- so task-020 can tell whether V18
      and V20 are able to fail against this repository or need a fixture
- [ ] Each of the two runs has its allocated work folder recorded, with the confirmed absence
      of a `phase:` value in that work's `STATE.md` -- the V23 evidence task-023 aggregates
- [ ] **The authored-run count is two, and it is recorded: a third means a step was run that
      this task does not own, one means the other was dropped.** Both realize, so both
      allocate a work folder; this task performs no routing exit and no refusal
- [ ] **Both `work-NNN` folders these runs allocated are removed, and their worktrees with
      them**, after the evidence is captured: `git status --porcelain .aid/works/` shows no
      folder this task created, and no stray worktree remains registered
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left -- this task neither renders nor reverts. `.aid/knowledge/kb.html` is unmodified
- [ ] **The commit stages explicit paths only.** This task commits inside the window in which
      task-024's render sits uncommitted in `profiles/`, `.claude/` and `.cursor/`, so
      `git diff --cached --name-only` immediately before the commit lists exactly
      `.aid/knowledge/backlog.md`, `.aid/settings.yml`, `.aid/knowledge/README.md` and --
      only if a promotion occurred -- `.aid/knowledge/tech-debt.md`, and no wildcard staging
      form (`git add -A`, `git add .`, `git add -u`, `git commit -a`) is used (task-024
      § Scope states the rule; every task that commits while the render is live carries the same bound)
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
