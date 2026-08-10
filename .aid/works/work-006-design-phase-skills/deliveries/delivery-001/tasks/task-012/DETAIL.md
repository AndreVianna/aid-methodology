# task-012: `/aid-create-backlog`, the `backlog.md` shape, and the item-promotion mechanism

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-012/STATE.md.
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

**Depends on:** task-011

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §3b, §3d, §5, §6b
  (its `/aid-create-backlog` row), §6d; REQUIREMENTS CC-1, CC-2. It inherits the registration
  idiom and the class-1 `create` contract exactly as task-011 fixed them, and it depends
  transitively on task-008's `_dim_of_filename` C7 arm and task-007's matrix rows.
- Author `canonical/skills/aid-create-backlog/SKILL.md` plus its catalog row (`verb: create`,
  `artifact: backlog`, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`,
  `repurpose: true`, §1's `intent` verbatim).
- **The body fixes `backlog.md`'s shape**: §3b's frontmatter values (`kb-category: primary`,
  `source: hand-authored`, `sources: []`, plus `objective:`, `summary:`, `tags`, `see_also`,
  `owner: architect`, `audience`); the `# Backlog` title; a one-paragraph preamble stating
  the promotion criterion; `## Contents` in the same house link form; `## Next Release` (the
  committed slice `release-aid` drains); `## Prioritized`; and `## Gotchas`.
- **`## Gotchas` is required, on a mechanical trigger**: task-008's C7 arm makes
  `_dim_owns_class(C7, Gotchas)` true, so the operational-structure presence check emits
  `| backlog.md | Gotchas | absent |` on every run until the section exists. Its content is
  the traps of working the backlog itself -- the id is inherited on promotion and re-minting
  it breaks the move audit; parking an item in `## Next Release` is a commitment because
  that section is drained at tag time; an item is moved, never copied.
- **The item schema** -- one ID-keyed table per item section, seven columns:
  `ID` (carried unchanged from `tech-debt.md` on promotion; for an item born in the backlog,
  minted in whatever form the project's own inventory already uses, taking the next unused
  ordinal; never re-minted, never reused, never renumbered);
  `Tag` (`[NEW]` | `[CHANGE]` | `[FIX]`, seeded from the promoted row's `Type` where the
  project's vocabulary determines it and otherwise **asked** at the same confirm gate --
  a proposed default is always presented, and no row is written with an empty `Tag`);
  `Title` (the key the drain matches on, since release-note bullets carry no id);
  `Definition & done-condition`; `Location` (a durable anchor -- path plus a
  grep-recoverable symbol or heading, never `path:LINE`); `Risk if not done`;
  `Priority` (`P1`/`P2`/`P3`).
- **The item flow (§5)**: promotion `tech-debt.md` -> `backlog.md` happens when an item is
  **accepted into the plan** -- an explicit human decision at a per-item confirm gate, not a
  property readable off the row (every live inventory row already carries a definition and a
  priority, so a literal reading would promote the whole inventory on the first run). Column
  mapping: `Description` -> `Definition & done-condition`, `Location` -> `Location`,
  `Risk` -> `Risk if not done`, `Priority` -> `Priority`, `Type` **consumed** to seed `Tag`
  then dropped, `Effort` dropped. **Move, not copy**: the promoted row is deleted from
  `tech-debt.md` in the same run, as a whole-row deletion keyed on `ID`, never a rewrite of
  another row or of the file's prose. Nothing moves into or out of `roadmap.md`.
- **§5 has a second column-mapping arm and the body must carry it too: the release-note
  bullet.** Added by the owner's resolution of work `STATE.md` Q7 (*shape (a),
  derive-from-shipped*), it covers an item that is already built and merely unreleased --
  `Definition & done-condition` = the bullet's own text with the done-condition read as
  *shipped, pending tag*; `Location` = the durable anchor the bullet already names;
  `Risk if not done` = *ships untagged / absent from the next release notes*;
  `Priority` = `P1`. **There is no exemption arm**: a row from this source carries all seven
  columns like every other row. The body states both arms, because task-018's one-off
  `## Unreleased` migration writes into the very table this body defines, and a body that
  knows only the `tech-debt.md` arm defines a schema the migration cannot satisfy.
- Class-1 `create` behavior and registration as task-011 fixed them, with
  `backlog.md|skill-self|required` and Concern `C7`.
- Out of scope: this repository's `.aid/knowledge/backlog.md` instance (task-021); the
  `update` counterpart (task-014); the release drain, whose instructions are task-009's and
  whose one-time migration is task-018; and the catalog count comments (delivery-003).

**Acceptance Criteria:**
- [ ] V1/V3 for this row: directory and row exist, all eight fields present,
      `default_type: DOCUMENT`, `group: G4`; V2 -- `build-shortcut-skills.py` overwrites no
      body
- [ ] AC-6's premise holds for `backlog.md`: the body states its frontmatter values, its four
      headings and all seven item columns with their rules, leaving nothing to the author's
      invention
- [ ] `## Gotchas` is authored as a required section carrying real C7 delta-value content,
      not a placeholder -- V14's `| backlog.md | Gotchas | present |` is the oracle it must be
      able to satisfy
- [ ] The promotion path is move-not-copy: the body deletes the promoted row from
      `tech-debt.md` in the **same run** that adds it to `backlog.md`, keyed on the unchanged
      `ID`, so V18's `comm -12` over the two id sets stays a well-defined check
- [ ] No row may be written with an empty `Tag`; where `Type` does not determine the value,
      the body asks at the same per-item confirm gate that authorizes the promotion
- [ ] The body states **both** of §5's column-mapping arms -- the `tech-debt.md` promotion
      and the release-note bullet -- and states that neither is exempt from any of the seven
      columns. A body carrying only the promotion arm defines a schema task-018's migration
      cannot satisfy, which is the failure this criterion exists to catch
- [ ] The `Location` rule forbids the bare `path:LINE` form, which `kb-citation-lint.sh`
      exits 1 on (V13's precondition)
- [ ] The registration step writes exactly one `doc_set` line, byte-equal to
      `    - backlog.md|skill-self|required`, and exactly one README Completeness row with
      `Status` = `Created (skill-self)`
- [ ] V25 for this skill: the `description` names `/aid-update-backlog`
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean, and no count comment
      inside `shortcut-catalog.yml` is edited
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
