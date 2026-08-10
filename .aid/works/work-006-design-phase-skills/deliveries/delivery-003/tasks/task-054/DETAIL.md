# task-054: Twelve `document`-family and `query` descriptions

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-054/STATE.md.
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

**Depends on:** task-053

**Scope:**
- Source: REQUIREMENTS **AC-12** (cited, not restated) and FR-11 **CC-9**, which owns the pair
  routing this slice must preserve.
- **Slice 3 of 7.** The twelve hand-authored (`repurpose: true`) rows of the `document` family plus
  the single `query` row: `aid-create-document`, `aid-update-document`, `aid-create-diagram`,
  `aid-document` and its seven genre siblings (`-decision`, `-architecture`, `-guideline`,
  `-standard`, `-runbook`, `-tutorial`, `-changelog`), and `aid-ask`.
- **Two of the twelve were edited by delivery-002 and must not be un-edited.** task-027 wrote the
  `document` pair's seed reads and its routing clause into
  `canonical/skills/aid-create-document/SKILL.md` and
  `canonical/skills/aid-update-document/SKILL.md`, and task-028 narrowed
  `canonical/skills/aid-document/SKILL.md`. Each of those descriptions now names
  `/aid-design-document` as its route, and delivery-002's BLUEPRINT criterion 9 plus its task-049
  already closed on that. A rewrite here that drops the name reopens a closed criterion.
- **The seven genre siblings share one shape, and that is what makes this slice one session.** Each
  delegates to `/aid-create-document` with a genre hint, so the rewrite is a single trigger-clause
  template instantiated seven times with the genre named -- not seven independent authoring
  decisions. The three non-siblings (`aid-create-document`, `aid-update-document`,
  `aid-create-diagram`) and `aid-ask` are authored individually.
- **`aid-ask` is the longest in this slice and is a genuine reallocation case**, not a trim: its
  description carries the query contract at length while the body restates it. The description keeps
  the outcome and the trigger; the contract stays in the body.
- **What a rewrite may not silently drop.** Every neighbour name carried as a negative route under
  CC-9 -- for this slice that includes the `document` trio's mutual routing, which feature-005 §7c
  assigned and delivery-002's task-049 verified in both directions. Compare each description's set of
  `/aid-` names before and after.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the other six slices; and the whole-roster verification (task-072), which is
  where the pair matrix is reported per pair and per direction.

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the twelve.** Each extracted `description:` block is
      **<= 1024** characters, contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no arrow-separated state transition sequence, and names the user-facing outcome
      before any AID-internal vocabulary (a reviewer read, all twelve quoted in full)
- [ ] **Every one of the twelve states when to use the skill**, in AC-12's imperative form, recorded
      per skill with the clause quoted. For the seven genre siblings the trigger names the genre,
      which is the whole reason a sibling exists rather than a flag on `/aid-create-document`
- [ ] **delivery-002's three shipped edits survive.** In each of
      `canonical/skills/aid-create-document/SKILL.md`,
      `canonical/skills/aid-update-document/SKILL.md` and
      `canonical/skills/aid-document/SKILL.md`, `grep -c '/aid-design-document'` over the extracted
      description block captured to a variable is `>= 1`. A rewrite that dropped it would silently
      reopen delivery-002's BLUEPRINT criterion 9
- [ ] **No other negative route was lost.** For each of the twelve, the sorted set of
      `/aid-`-prefixed names in the description is compared with the same set from
      `git show HEAD:canonical/skills/<name>/SKILL.md`; every difference is an addition or a removal
      recorded with its reason. `HEAD`, not `master`, for the three delivery-002 edited: `master`
      predates their routing clauses, so a `master` baseline would report the clause as an addition
      and hide a regression
- [ ] **The genre siblings still delegate**, which is the property their bodies carry and their
      descriptions summarise: for each of the seven, `grep -c 'aid-create-document'` over the whole
      `SKILL.md` captured to a variable is `>= 1`
- [ ] **Only the twelve moved.** `git diff --name-only HEAD -- canonical/skills/` at the end of this
      task lists exactly the twelve `SKILL.md` files this slice owns
- [ ] **Frontmatter shape is intact on all twelve** -- block delimiters, all four keys, `name:`
      equal to the directory -- and `tests/canonical/test-frontmatter-lint.sh` plus
      `tests/canonical/test-catalog-dirs-parity.sh` are green with
      `git diff master -- tests/canonical/test-catalog-dirs-parity.sh` empty
- [ ] Accuracy verified against the current codebase: every path and assertion id in this task's
      record is re-resolved against the tree as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
