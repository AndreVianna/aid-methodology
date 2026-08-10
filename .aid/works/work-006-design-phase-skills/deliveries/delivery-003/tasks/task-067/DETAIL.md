# task-067: The test landscape and the tech-debt figures brought to the finished roster

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-067/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-066

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §7's Knowledge Base table, rows
  `test-landscape.md` and `tech-debt.md`. It closes two more of the documents named in BLUEPRINT
  criterion **9** and carries their share of criterion **4**.
- **`test-landscape.md` records what task-062 and task-063 actually changed**, which is the only place
  in the Knowledge Base those edits are described: all four `DMR*` assertion keys including `DMR32` and
  why its expected value is a sentence rather than a zero; the two *count-agnostic by design* notes and
  which suite each belongs to; and the `tests/coverage-baseline.tsv` re-bootstrap with its new row
  shape -- 95 each of `CDP{i}a`/`b`/`c`, 94 `CDP{i}d`, **34** each of `e`/`f`/`g`, 144 rows added.
- **The `e`/`f`/`g` figure is written as a count, not as a key-set identity.** `CDP{i}` is indexed by
  the row's position in the catalog, so inserting rows mid-file shifts indices and changes *which*
  indices carry `e`/`f`/`g` while leaving the size at 34. A sentence claiming the key sets are identical
  would be false, and this is the document a future reader would trust.
- **`tech-debt.md` carries two live figures and one closure that is not this task's.** `W1-11`'s
  machine-derived half states the corpus total in a phrasing the count guard reads (*"today 76
  skills"*) -- that moves to **112**. Its `:160` sidecar figure (*"all 76 sidecars"*) is mode **M2**, a
  bare `sidecars` noun no `CLAIMS` regex matches, and is guard-blind. **The `kb.html` half of `W1-11` is
  NOT closed here** -- it closes in task-071, when the regeneration actually lands, and `W1-2`'s
  hand-measured per-shape populations stay open regardless.
- **Do not close a debt item this work did not resolve, and do not delete an item's record from the
  wrong place.** A resolved item is removed from the inventory and its detail; an item with a surviving
  half stays, with the surviving half stated. `W1-11` has two survivors today (`kb.html`, and `W1-2`'s
  prose populations); after task-071 it has one.
- **`tech-debt.md` is a living inventory, which is why it is refreshed here rather than left to a final
  summary pass.** Unlike `INDEX.md` and `kb.html`, it is a source, not a summary of sources.
- **The per-quantity delta binds.** Directories 76 -> **112**; catalog rows and canonical names 58 ->
  **94**; `repurpose` rows 24 -> **60**; aliases **0**; **`shortcuts` (emitting) 34, unchanged**;
  `curatedOnly` **18**; `classicRepurposed` **3**.
- **Two authoring rules bind, both already enforced.** No `work-NNN` reference and no work-folder path
  (`AS03c`) -- which matters more here than anywhere else, because `tech-debt.md` is where the twelve
  `W1-*` items were migrated to precisely so they would survive their work folders being pruned -- and
  no `## Change Log` section or `changelog:` field (`AS03`, `AS03b`). And no current count inside a
  dated bullet or a `| N | YYYY-MM-DD |` row (`check-skill-counts.mjs:216-219`).
- Out of scope: the documents task-065 and task-066 own; every `docs/` and `site/` surface (task-068);
  `check-skill-counts.mjs` and the stage-2 replay (task-069); `INDEX.md` (task-070); and the `kb.html`
  regeneration together with `W1-11`'s `kb.html`-half closure, both task-071's.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 9 -- `test-landscape.md` describes what changed under `tests/`, not just
      that something did.** It names all four `DMR*` keys with their new values, states why `DMR32`'s
      expected value is a paired sentence rather than a bare zero, names both *count-agnostic by design*
      notes with the suite each belongs to, and records the coverage-baseline re-bootstrap. A reviewer
      read, recorded with the added passage quoted
- [ ] **The baseline row shape is stated as counts and the index-shift caveat is stated with it.**
      `test-landscape.md` gives 95 / 95 / 95 for `CDP{i}a`/`b`/`c`, 94 for `d`, **34** each for `e`/`f`/`g`
      and 144 rows added, and says explicitly that the `e`/`f`/`g` claim is about counts because
      `CDP{i}` is positional. A sentence claiming key-set identity fails this criterion
- [ ] **`tech-debt.md`'s two live figures moved.** `W1-11`'s guard-readable corpus figure states
      **112**, and its `:160` sidecar figure states **112**; both are recorded as a triple -- quantity,
      before, after
- [ ] **`W1-11`'s `kb.html` half is still open here, and the record says so with its owner.**
      `grep -c 'kb.html' ` over the `W1-11` entry captured to a variable is `>= 1`, the entry still
      names `kb.html` as a survivor, and this task's record states that task-071 closes it. Closing it
      here would claim a regeneration that has not happened
- [ ] **`W1-2` is untouched and still open.** `git diff HEAD -- .aid/knowledge/tech-debt.md` shows no
      change to the `W1-2` row, and no item other than `W1-11` was edited
- [ ] **BLUEPRINT criterion 4's share -- every count line in these two states its own quantity's new
      value**, recorded as a triple per figure
- [ ] **The negative half.** In these two documents no phrasing of the **`shortcuts` (emitting)**
      quantity moved off **34**, no `curatedOnly` figure off **18**, no `classicRepurposed` figure off
      **3**, and no alias figure off **0** -- asserted by diffing the matching lines against
      `git show HEAD:` per file, with every difference explained
- [ ] **The guard is run over these two and its report recorded**: every line it reports is either fixed
      here or recorded with the task that owns it
- [ ] **No history apparatus and no work reference was introduced.** Per file,
      `grep -cE 'work-[0-9]{3}'` captured to a variable -> `0`, `grep -c '^## Change Log'` -> `0`, no
      `changelog:` field; `AS03`, `AS03b` and `AS03c` are green. The `W1-*` items still carry no work id,
      which is the property their migration into this file existed to create
- [ ] **No current count was written into a dated bullet or dated table row** -- the guard's own count of
      `HISTORY_SHAPES`-skipped lines carrying a count is still **0**
- [ ] **Only these two documents moved.** `git diff --name-only HEAD -- .aid/knowledge/` lists exactly
      `test-landscape.md` and `tech-debt.md`
- [ ] Accuracy verified against the current codebase: every line number and assertion key cited in this
      task's record is re-resolved against the file as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- canonical/ tests/ site/ docs/ profiles/ .claude/ .cursor/` is clean
- [ ] All section-6 quality gates pass
