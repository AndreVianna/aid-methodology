# task-019: Regeneration of the two script-generated Knowledge Base summaries

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-019/STATE.md.
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

**Depends on:** task-017, task-018

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §4a's carrier table,
  §5 rows 10 and 14, and §6 **step 6**. Last of feature-001's steps, because a summary is
  refreshed once the documents it summarizes have stopped moving.
- Regenerate `.aid/knowledge/INDEX.md` with
  `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`.
  It composes each row from the doc's own `objective:` / `summary:` frontmatter and stamps a
  DO-NOT-EDIT line, so it is **regenerated, never hand-edited** -- a hand edit is reverted by
  the next run. The duplicated `release-tracking.md` summary is the carrier the `##
  Unreleased` migration reaches through this run, and `roadmap.md` and `backlog.md` acquire
  their rows here.
- Regenerate `.aid/knowledge/relationships.md` via `/aid-graph`, clearing the three
  `kb:release-tracking.md#unreleased` rows.
- **`/aid-graph` produces a second artifact, and it is accounted for here rather than left
  loose.** Its own body declares it builds *"`.aid/knowledge/relationships.md` **and**
  `.aid/knowledge/graph.html`"*, so the run leaves a third file behind. The repository's own
  precedent settles its disposition without a new decision: `relationships.md` is tracked,
  `kb.html` is tracked, and `.aid/knowledge/graph.html` has **never existed in git history**
  (`git log --all -- .aid/knowledge/graph.html` returns nothing) and is neither tracked nor
  ignored today (`git check-ignore` exits 1, and `ls .aid/knowledge/*.html` returns `kb.html`
  only). It is therefore **not committed** by this task, and feature-001 §1d's carrier table
  -- which lists only `relationships.md` for `/aid-graph` -- is consistent with that.
- **`kb.html` is explicitly NOT regenerated here.** It is the one summary whose regeneration
  is an authored `/aid-summarize` run rather than a script -- the last recorded full GENERATE
  took ~24 minutes, and its automated visual check does not run at all, so the gate is an
  orchestrator step. A final-state summary is refreshed **once**, after the roster settles,
  so it runs exactly once in delivery-003, and feature-001 AC-6's `kb.html` conjunct is
  evaluated there (PLAN § Cross-Cutting Risks, risk 5; BLUEPRINT gate criterion 6).
- Out of scope: any hand edit to any of the three generated files; any change to the
  documents they are generated from -- if a row comes out wrong, the fix belongs in the
  source document's frontmatter, not in the summary.

**Acceptance Criteria:**
- [ ] `grep -c Unreleased .aid/knowledge/INDEX.md` -> `0` -- the duplicated
      `release-tracking.md` summary is composed from the frontmatter task-018 rewrote
- [ ] `grep -c 'release-tracking.md#unreleased' .aid/knowledge/relationships.md` -> `0`
      (three rows today)
- [ ] `INDEX.md` carries one row for `roadmap.md` and one for `backlog.md`, each showing the
      `objective:` and `summary:` those documents declare -- no row reads
      *"(no objective declared)"*
- [ ] feature-001 §5 row 14: re-running `build-kb-index.sh` immediately afterwards leaves no
      diff
- [ ] `.aid/knowledge/kb.html` is **unmodified** and still carries its eight `Unreleased`
      occurrences on seven lines. Clearing them is delivery-003's single `/aid-summarize`
      re-run; hand-patching the file here would be the second authored run this delivery
      exists to avoid
- [ ] `.aid/knowledge/graph.html` is **not added to the index**: `git ls-files
      .aid/knowledge/graph.html` returns nothing after the run, matching the repository's
      standing state for that path. The run's tracked output is `relationships.md` alone
- [ ] `git status --porcelain .aid/knowledge/` shows changes only to `INDEX.md` and
      `relationships.md` in the tracked set -- no other KB document is touched by a
      regeneration
- [ ] `git diff --exit-code -- .aid/knowledge/STATE.md` is clean
- [ ] **The commit stages explicit paths only.** This task commits inside the window in which
      task-024's render sits uncommitted in `profiles/`, `.claude/` and `.cursor/`, so
      `git diff --cached --name-only` immediately before the commit lists exactly
      `.aid/knowledge/INDEX.md` and `.aid/knowledge/relationships.md`, and no wildcard staging
      form (`git add -A`, `git add .`, `git add -u`, `git commit -a`) is used (task-024
      § Scope states the rule; every task that commits while the render is live carries the same bound). The
      wildcard risk is sharpest here because this task's own tool writes new files
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left, before and after this task -- it neither renders nor reverts, and a wildcard add
      would show up here as the render's entries disappearing from the output
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
