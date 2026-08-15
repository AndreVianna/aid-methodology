# task-015: This repository's `roadmap.md` instance, its `## MVP` section and its registration

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-015/STATE.md.
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

**Depends on:** task-024

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §3a, §3c, §6b, §8 V15;
  feature-001 §1e (*"`roadmap.md` and `backlog.md` themselves -- feature-003 creates them,
  including this repo's instances"*) and §6 step 4. REQUIREMENTS CC-2 makes the registration
  an **effect of running the skill**, so this task runs the skills rather than hand-writing
  the document or the entries.
- **Scoped to `roadmap.md` alone, and it performs no render.** Two things made the earlier
  form of this task oversized, and only one of them was the run count. The other -- the real
  cause -- was that it carried a **five-profile render of its own**, which is shared setup
  rather than this task's work. That render is now task-024's, produced once for the whole
  delivery and consumed read-only here; task-025 reverts it. What remains is four authored
  runs against an already-invocable dogfood tree.
- `roadmap` and `mvp` stay together because they cannot be separated: V9's second half
  requires `/aid-create-mvp` to run against the `roadmap.md` `/aid-create-roadmap` has just
  written, and `git diff --numstat` must show that insertion as a pure insertion.
  `backlog.md`'s two runs are task-021's, which also serialises the `.aid/settings.yml` and
  `.aid/knowledge/README.md` count writes the two instances share.
- **How the skills are invocable** (BLUEPRINT § Notes): task-024 has already run
  `build-shortcut-skills.py` and the full `run_generator.py` and resynced the dogfood
  `.claude/`. This task **renders nothing and reverts nothing** -- it reads that tree. Invoking
  the bodies from `canonical/` by hand is not the path: it does not exercise the render-time
  path rewriter, so it cannot back the acquisition-rule clause of gate criterion 2.
- Run, in order: `/aid-design-roadmap`, `/aid-create-roadmap`, `/aid-design-mvp`,
  `/aid-create-mvp` -- **four authored runs**: each *realizes*, so each allocates a
  `work-NNN` folder and executes feature-002 §3e's full-verify loop. None is a routing exit or
  a refusal, so all four produce a work folder to record.
- **Record, for each of the four runs, the work folder it allocated and that its `STATE.md`
  carries no `phase:` value**, into this task's STATE.md notes. V23 is a nine-skill sweep and
  its evidence is produced here; task-023 aggregates the records rather than re-reading state
  this task's own teardown would have destroyed.
- **Then tear those work folders down -- this task owns them.** Each run allocates through
  the Work Initiation Gate (`enumerate-works.sh`, then `worktree-lifecycle.sh create` on new
  work), so four `.aid/works/work-NNN-*/` folders and their worktrees appear in the working
  tree. `.aid/works/` is **tracked, not ignored** (`.gitignore` lists two specific folders
  only), so leaving them makes the tree dirty for every downstream task and for
  delivery-003's render. Remove each after its `phase:` evidence has been captured. The same
  obligation binds task-021 and task-023 for the runs they own; task-025 carries the
  backstop assertion, not the cleanup.
- **Capture the intermediate state** after `/aid-create-roadmap` alone and before
  `/aid-create-mvp` runs: the forward `- [MVP](#mvp)` index entry with no `## MVP` heading.
  That state is asserted deliberately (V10) and is transient by construction -- it ends the
  first time `/aid-create-mvp` runs, and `/aid-*-roadmap` is forbidden from creating the
  section precisely so the window closes only by the owner's hand.
- **Commit the outputs only**: `.aid/knowledge/roadmap.md` (with its `## MVP` section), the
  one `.aid/settings.yml` `knowledge.doc_set` line, and `.aid/knowledge/README.md`'s one
  Completeness row plus its incremented doc-set count.
- Out of scope: **the render (task-024) and its revert (task-025)** -- this task must leave
  the rendered trees exactly as it found them; **`backlog.md`'s instance and its registration
  (task-021)**; the behavioral verification of the `design`/`create` skills (task-016), of
  the `## MVP` region (task-022) and of the `update` contract (task-023); the `## Unreleased`
  content migration into `## Next Release` (task-018, which needs `backlog.md` to exist); and
  `INDEX.md`, `relationships.md` and `kb.html`, which are summaries refreshed after the KB
  stops moving (task-019 and delivery-003).

**Acceptance Criteria:**
- [ ] **V15, the `roadmap.md` half.** Absent `roadmap.md` -> `/aid-create-roadmap` ->
      the file exists and carries its four `create`-time headings (`## Contents`, `## Now`,
      `## Next`, `## Later`); `git diff .aid/settings.yml` shows **exactly one** added line,
      byte-equal to `    - roadmap.md|skill-self|required`; `README.md`'s Completeness table
      gains **exactly one** row whose `Status` cell is the literal `Created (skill-self)`;
      and its doc-set count line increments by 1. A run that creates the document but skips
      either surface fails; so does one that writes `conditional`. The `backlog.md` half is
      task-021's
- [ ] **V9**: after `/aid-create-roadmap`, `grep -n '^## '` over `roadmap.md` is Contents,
      Now, Next, Later in that order, and the `## Contents` entries are the house link form
      of exactly those names plus `MVP`. After `/aid-create-mvp`: Contents, MVP, Now, Next,
      Later, and `git diff --numstat` shows **0 deletions** -- a pure insertion
- [ ] **V10**: at the intermediate state, `grep -c '^- \[MVP\](#mvp)$' .aid/knowledge/roadmap.md`
      -> `1`, with no `## MVP` heading present
- [ ] **V11**, `roadmap.md`'s half: `bash canonical/aid/scripts/kb/lint-frontmatter.sh
      --root .aid/knowledge --verbose` exits 0 with no `[FM-MISSING]`/`[FM-INVALID]` naming
      `roadmap.md` **and** `roadmap.md` not on a `SKIP` line -- the linter soft-skips a doc
      carrying none of the new fields, so the second half is what keeps this non-vacuous
- [ ] **V12** (feature-001 AC-5), `roadmap.md`'s half:
      `grep -nE '^## (Change Log|Revision History)|^changelog:|work-[0-9]{3}|\.aid/works/' .aid/knowledge/roadmap.md`
      returns no match. Not `AS03`/`AS03b`/`AS03c`, which are template-scoped and can never
      see a document with no template
- [ ] **V13**: `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge`
      exits 0
- [ ] `kb-actback-task.sh check` reports no `absent` operational-structure row for
      `roadmap.md` -- D owns none of the four operational-guidance classes, so the check
      neither expects nor reports `## Gotchas` for it (§3d). V14's `backlog.md` conjunct is
      task-021's
- [ ] **V5**, this task's two artifacts: the `roadmap` and `mvp` seeds are present before
      their `create` and absent after
- [ ] Each of the four runs has its allocated work folder recorded, with the confirmed
      absence of a `phase:` value in that work's `STATE.md` -- the V23 evidence this task
      produces and task-023 aggregates
- [ ] **The authored-run count is four, and it is recorded: a fifth means a step was run that
      this task does not own, a third means one was dropped.** All four realize, so all four
      allocate a work folder; this task performs no routing exit and no refusal, and a run
      that turns out to be non-realizing fails its own row before it reaches this count
- [ ] **Every `work-NNN` folder these four runs allocated is removed, and its worktree with
      it**, after the evidence above is captured: `git status --porcelain .aid/works/` shows
      no folder this task created, and no stray worktree remains registered. `.aid/works/` is
      tracked, so a leftover is a dirty tree, not a harmless artifact
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left -- this task neither renders nor reverts, so the rendered trees are byte-identical
      to task-024's recorded output before and after. `.aid/knowledge/kb.html` is unmodified
- [ ] **The commit stages explicit paths only.** This task commits inside the window in which
      task-024's render sits uncommitted in `profiles/`, `.claude/` and `.cursor/`, so
      `git diff --cached --name-only` immediately before the commit lists exactly
      `.aid/knowledge/roadmap.md`, `.aid/settings.yml` and `.aid/knowledge/README.md`, and no
      wildcard staging form (`git add -A`, `git add .`, `git add -u`, `git commit -a`) is used
      (task-024 § Scope states the rule; every task that commits while the render is live carries the same bound)
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
