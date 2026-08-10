# task-059: The catalog's own three stale count comments, each re-derived from the file

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-059/STATE.md.
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

**Depends on:** task-058

**Scope:**
- Source: BLUEPRINT § Scope, second bullet, and BLUEPRINT criterion **6** -- *"The catalog's own
  three stale count comments are corrected, each against a count taken from the file rather than from
  this checkbox"*. delivery-001 and delivery-002 handed these here deliberately, so that three
  features do not collide on one file (feature-003 SPEC § *Verification*, V28).
- **The three sites, each re-derived at execution time rather than trusted from this file.** They are
  comments, not assertions, so the corrections are ordinary edits and the derivations are the oracle:
  the `repurpose` field contract (`shortcut-catalog.yml:108-109`, *"24 rows carry `repurpose:
  true`"*), the G4 create-family section header (`:145`, *"16 canonical rows"*) and the G5
  change-and-refactor section header (`:234`, *"15 canonical `aid-update*` rows"*).
- **Why this task exists at all, stated so nobody looks for an oracle that does not exist.** No other
  task in this delivery can see these three lines. `check-skill-counts.mjs`'s `CLAIMS` array matches
  none of their phrasings, and task-069's stage-2 replay reaches the `repurpose` comment -- it scans
  the moving quantities -- but **not** the other two, whose digits are `16` and `15` and are not among
  the quantities the replay scans. So the correction and its own derivation are the whole mechanism.
- **The parenthetical row-location clauses inside two of the three headers are part of the edit.**
  `:145-147` says *"16 canonical rows (12 in this section; `aid-create-test` in G7,
  `aid-create-document` and `aid-create-diagram` in G8, `aid-create-dashboard` in G11)"*, and
  `:234-235` the analogous split for `aid-update*`. The seven new `aid-create-*` rows and seven new
  `aid-update-*` rows land in these sections, so the total moves **and** the "12 in this section"
  operand does. A correction that moves only the leading figure leaves the parenthetical
  self-contradicting.
- **What must not move.** The `3 classic re-registered pipeline skills` figure and every phrasing of
  the **`shortcuts` (emitting)** quantity. All thirty-six rows this work adds are `repurpose: true`,
  so the emitting quantity stays **34** and `classicRepurposed` stays **3**. Over-application is this
  delivery's most likely error mode; a sweep that moved either figure would corrupt a correct
  statement.
- **This is the last task that writes the catalog before the render**, which is why it sits here: the
  catalog renders as verbatim bytes to all five profiles (`shortcut-catalog.yml:11-13`), so a comment
  corrected after task-060 would leave five stale copies and fail the freshness oracle.
- Out of scope: the `:12` count comment in `build-shortcut-skills.py`, which is task-051's because
  that task is the file's single writer; every count-bearing surface outside this file (task-062,
  task-065 through task-069); and any change to a row -- this task edits comments only.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 6, site 1 -- the `repurpose` field contract.**
      `grep -c '^    repurpose: true$' canonical/aid/templates/shortcut-catalog.yml` captured to a
      variable -> `60`, and the comment at `:108-109` states that figure. The derivation is recorded
      beside the edit, not just the result
- [ ] **BLUEPRINT criterion 6, site 2 -- the G4 create-family header.**
      `grep -c '^  - name: aid-create' canonical/aid/templates/shortcut-catalog.yml` captured to a
      variable -> `23`, the header at `:145` states it, **and** its parenthetical re-states the
      in-section count and the out-of-section rows consistently -- verified by counting the
      `^  - name: aid-create` rows that fall inside the G4 block against those that do not
- [ ] **BLUEPRINT criterion 6, site 3 -- the G5 update-family header.**
      `grep -c '^  - name: aid-update' canonical/aid/templates/shortcut-catalog.yml` captured to a
      variable -> `22`, the header at `:234` states it, and its parenthetical is made consistent the
      same way
- [ ] **The negative half: nothing that must not move, moved.** With
      `C=canonical/aid/templates/shortcut-catalog.yml`, `grep -n '\b34\b' "$C"` and
      `grep -n 'classic' "$C"` produce output identical to the same commands against
      `git show HEAD:canonical/aid/templates/shortcut-catalog.yml`, and no phrasing of the
      **`shortcuts` (emitting)** quantity anywhere in the file was edited
- [ ] **No row changed, only comments.** `git diff HEAD -- canonical/aid/templates/shortcut-catalog.yml`
      shows every changed line beginning with optional whitespace then `#`; no line matching
      `^  - name:`, `^    verb:`, `^    artifact:`, `^    alias_of:`, `^    default_type:`,
      `^    group:`, `^    intent:` or `^    repurpose:` appears in the diff on either side
- [ ] **The catalog still parses and still validates.**
      `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` exits 0 and
      prints `OK:`, and `bash tests/canonical/test-catalog-dirs-parity.sh` is green with
      `git diff master -- tests/canonical/test-catalog-dirs-parity.sh` empty
- [ ] Accuracy verified against the current codebase: each of the three line numbers is re-resolved
      against the file as it stands before the edit is made, and the resolved numbers are recorded
- [ ] Nothing outside the declared write moves:
      `git diff --exit-code -- tests/ site/ canonical/skills/ docs/ .aid/knowledge/` is clean, and
      `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at the start of
      this task
- [ ] All section-6 quality gates pass
