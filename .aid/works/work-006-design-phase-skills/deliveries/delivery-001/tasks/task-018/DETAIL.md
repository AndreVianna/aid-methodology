# task-018: Retirement of `## Unreleased` and the move of its items into `backlog.md`

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-018/STATE.md.
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

**Type:** MIGRATE

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-009, task-023

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §4a (AC-6);
  REQUIREMENTS AC-4 and C-6 item 1 -- *"the only content migration in the work"*.
- **Ordered after task-023 by necessity, on two counts.** `backlog.md` is the destination
  and it does not exist until its `create` skill has run in task-021 (a transitive ancestor);
  and task-022 and task-023 both *mutate and restore* `.aid/knowledge/backlog.md` while
  verifying, so writing into it concurrently would collide with a restore. feature-001 §6
  places §4a at step 3, before feature-003's step 4; that ordering works for the *carriers*
  but not for the *content*, and the content half is what REQUIREMENTS AC-4 asserts. The
  carrier half that has no such dependency -- the `release-aid` rewire -- was taken in
  task-009.
- **Move** every item currently under `.aid/knowledge/release-tracking.md` § `## Unreleased`
  into `.aid/knowledge/backlog.md` § `## Next Release`, as rows of the seven-column item
  table task-012 fixed. The derivation is **feature-003 §5's release-note-bullet arm** --
  the second arm of its column mapping, added by the owner's resolution of work `STATE.md`
  Q7 (*shape (a), derive-from-shipped*). Every column is derived, none is invented:

  | Source | `backlog.md` column |
  |---|---|
  | -- | `ID`, minted per the **three constraints** below rather than by "the next unused ordinal", which is not single-valued on this repository's inventory |
  | The bullet's `[NEW]` / `[CHANGE]` / `[FIX]` marker | `Tag`, carried verbatim -- the drain re-tags nothing |
  | The bullet's leading feature name, or its first clause | `Title` |
  | The bullet's own text | `Definition & done-condition`, done-condition read as **shipped, pending tag** |
  | The durable anchor the bullet already names | `Location` -- path plus a grep-recoverable symbol or heading, never `path:LINE` |
  | -- | `Risk if not done`: **ships untagged / absent from the next release notes** |
  | -- | `Priority`: **`P1`** -- the `## Next Release` slice is the committed slice by definition |

  **No exemption arm exists and none may be introduced**: a migrated row carries all seven
  columns like every other row. Q7 rejected exempting them, because an exemption forks the
  row schema permanently and every later consumer -- the drain, V18, the C7 depth standard --
  would have to handle two shapes.
- **The `ID` rule, stated as constraints rather than as a value -- because "the next unused
  ordinal" is not single-valued here.** This repository's live `tech-debt.md` carries **two**
  id families, not one: `L4` in the inventory table, and a `W<series>-<ordinal>` family
  spanning `W1-1..W1-17`, `W4-3`, `W4-5` and `W5-1..W5-19`. So neither "the form" nor "the
  next ordinal" resolves. The three constraints that actually matter, all checkable:
  1. **Family:** use `W<series>-<ordinal>`, the form feature-003 §3b names as *"this
     repository's own instance"*. The `L<n>` family is a distinct legacy family and is
     **not** extended.
  2. **Uniqueness:** the id must collide with nothing anywhere in `tech-debt.md` -- the
     Debt Inventory table **and** the Detailed Debt Items section, which carries ids the
     table does not -- nor with anything in `backlog.md`. Verified by grep, not by eye.
  3. **No reuse:** a retired id is never reused and never renumbered, per `tech-debt.md`'s
     own closing rule (*"IDs are not renumbered, so the gap at `W1-4` is expected"*).
  Choosing a specific unused id inside those constraints is execution, not design. Record
  the ids chosen.
- Then **delete the `## Unreleased` section itself**, and remove every remaining prose
  description of it: the `objective:` and `summary:` frontmatter values and the body rule in
  the document's lede. The section-only removal is insufficient -- five further lines
  describe the section, which is why AC-6's oracle is a whole-file zero-count rather than a
  `## Unreleased` search.
- **Not touched**: `.aid/knowledge/STATE.md`, whose historical, append-only Q&A entry records
  what was true then -- AC-6 asserts a clean diff on it precisely so a repo-wide sweep cannot
  quietly eat it. And `.aid/knowledge/kb.html`, which is **neither dropped nor hand-patched**:
  it is regenerated by the single `/aid-summarize` re-run in delivery-003, where AC-6's
  `kb.html` conjunct is evaluated.
- Out of scope: `INDEX.md` and `relationships.md`, which are **regenerated**, never
  hand-edited -- a hand edit here is reverted by the next run (task-019).

**Acceptance Criteria:**
- [ ] AC-6, the carriers this task writes:
      `grep -c Unreleased .aid/knowledge/release-tracking.md` -> `0`. It is `6` today (lines
      4, 5, 18, 20, 21, 24), so a `## Unreleased`-only search would pass while five lines
      still described the section
- [ ] **Data integrity**: every item that was under `## Unreleased` appears **exactly once**
      in `backlog.md` § `## Next Release` and nowhere else; none is dropped, none is
      duplicated, and each keeps its release-note tag. The before/after item counts are
      recorded
- [ ] **Every migrated row carries all seven columns populated**, and each is traceable to
      the arm above rather than to the executor's judgement: `Tag` and `Title` read off the
      bullet, `Definition & done-condition` the bullet's own text with the done-condition
      *shipped, pending tag*, `Location` the anchor the bullet names, `Risk if not done`
      *ships untagged / absent from the next release notes*, `Priority` `P1`, and `ID` per
      the three constraints above. A row with an empty cell fails; so does one whose
      `Risk if not done` or `Priority` was composed rather than taken from the arm
- [ ] Each minted `ID` satisfies all three constraints: it is in the `W<series>-<ordinal>`
      family and never `L<n>`; `grep -c '<id>'` over the **whole** of
      `.aid/knowledge/tech-debt.md` (inventory table and Detailed Debt Items) and over
      `.aid/knowledge/backlog.md` shows it exactly once, in the new row; and it reuses no
      retired id. The ids chosen are recorded
- [ ] Each migrated row satisfies the item schema in full -- no empty `Tag`, no `path:LINE`
      `Location`, a `Priority` in the closed set -- so
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` still exits 0
- [ ] feature-003 V18 still holds after the move: `comm -12` over the `ID` column of
      `tech-debt.md` and of `backlog.md` is empty
- [ ] **Idempotent**: re-running the migration finds no `## Unreleased` section and makes no
      further change to either file
- [ ] **Reversible**: the change is confined to `.aid/knowledge/release-tracking.md` and
      `.aid/knowledge/backlog.md`, so reverting the commit restores both documents exactly;
      no other file is touched
- [ ] `git diff --exit-code -- .aid/knowledge/STATE.md` is clean, and
      `.aid/knowledge/kb.html` is unmodified
- [ ] **The commit stages explicit paths only.** This task commits inside the window in which
      task-024's render sits uncommitted in `profiles/`, `.claude/` and `.cursor/`, so
      `git diff --cached --name-only` immediately before the commit lists exactly
      `.aid/knowledge/release-tracking.md` and `.aid/knowledge/backlog.md` -- the same two
      paths the Reversible criterion above names -- and no wildcard staging form
      (`git add -A`, `git add .`, `git add -u`, `git commit -a`) is used (task-024 § Scope
      states the rule; every task that commits while the render is live carries the same bound)
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` reports **exactly** what task-024
      left, before and after this task -- it neither renders nor reverts, and a wildcard add
      would show up here as the render's entries disappearing from the output
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
