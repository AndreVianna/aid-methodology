# task-072: One whole-roster description sweep -- mutual negative routing and triggering quality

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-072/STATE.md.
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

**Type:** TEST

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-071

**Scope:**
- Source: REQUIREMENTS **AC-8** and **AC-12** (whose five checks are cited, not restated),
  **NFR-4**, FR-11 **CC-9**, and `features/feature-006-integration-and-close-out/SPEC.md` §8a with its
  §10 *Routing sweep* row. It closes BLUEPRINT criterion **11** -- *"The mutual-negative-routing sweep
  runs over the **complete** pair set and is reported per pair and per direction"* -- and it is the
  verification half of AC-12.
- **It is one sweep over one file set, not two passes over the same 112 files.** REQUIREMENTS AC-12 says
  so directly: it extends feature-006's whole-set pair check *"from routing-completeness to triggering
  quality over the whole roster"*, and *"the two are one sweep over one file set, so they are closed
  together rather than in two passes"*. The authoring was task-051 and task-052 through task-058; this
  is the single verification pass over their output.
- **This task writes nothing.** It runs after task-071 so that it audits the finished, rendered,
  regenerated tree. Every row reads committed content.
- **The pair set is read, not restated.** FR-11 **CC-9** settles ownership and the per-pair assignment
  is tabled once, in **feature-005 §6c (The AC-8 pair set)**. Read both at execution time; a fourth copy
  of that table would drift exactly as the third did. Report **one row per pair per direction** -- "the
  sweep passed" is not evidence, which is the whole reason the check is deferred here rather than the
  authorship.
- **Why the whole pair set can only be verified here.** Whichever feature owns a side under CC-9, no
  pair is checkable until every side exists -- and a pair whose owning feature never wrote its side
  **fails here as a defect**, which is the point of deferring the check.
- **The AC-12 half runs over all 112, both strata, with the stratum recorded per skill.** The
  partition is re-derived from disk rather than carried from this file: a directory under
  `canonical/skills/` with no catalog row is curated (18); a row with `repurpose: true` is hand-authored
  (60); every other row is generated (34). 18 + 60 = the 78 hand-authored, and 78 + 34 = 112.
- **The five checks, in the form the report takes.** Check 1 is a measurement per skill. Check 2 is three
  greps per skill over the **extracted description block**, never over the whole file -- a generated
  doorway's body legitimately carries `VERB=`, `ARTIFACT=` and the engine path, and `aid-describe`,
  `aid-deploy`, `aid-monitor`, `aid-graph`, `aid-housekeep` and `aid-update-kb` legitimately carry a
  relocated `State machine:` line in their bodies. Check 3 is a property of the generator, asserted at
  its source. Check 4 is a reviewer read per skill. Check 5 is a re-assertion of the byte-identity gate
  plus the emitting-count negative.
- **The regression this sweep is most likely to find is a lost neighbour name**, because seventy-eight
  descriptions were rewritten after their routing was authored and closed. Both directions of every pair
  are checked, and a description that names a neighbour its table does **not** assign is reported too --
  the check runs in both directions, as delivery-002's task-049 ran it over the sides that delivery
  wrote.
- **Three instruments are named so a sweep does not reach for the wrong one.**
  `tests/canonical/test-catalog-dirs-parity.sh` is the oracle for name/directory/frontmatter parity and
  is count-agnostic. `tests/canonical/check-skill-counts.mjs` is the oracle for counts and is
  task-069's. Neither is an oracle for description **quality**, which is not mechanically decidable in
  full -- `test-graph-skill-registration.sh:162` says so in its own comment -- so checks 4 and the
  trigger-clause conjunct are recorded as reviewer verdicts with the text quoted, not as greps
  pretending to be judgements.
- Out of scope: authoring or fixing any description -- a finding here is reported, and its fix is a
  separate decision; the `SKILL.md` **body** size guidance, `argument-hint` placement and skill
  self-containment, all three placed out of scope by REQUIREMENTS §4's AC-12 bullet; and the pipeline
  sweep (task-073) and the grade floor (task-074).

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command or the quoted text
      that produced it** -- no row is reported as covered without its oracle and result (TEST default:
      all acceptance criteria from the source feature covered)
- [ ] **BLUEPRINT criterion 11 -- the pair set is complete and the report is per pair and per
      direction.** The pair set is read from FR-11 CC-9 and feature-005 §6c at execution time and
      recorded as a table of one row per pair with **two** direction columns; every cell states the
      literal neighbour name found and the file it was found in. A pair with an empty cell is a defect
      reported as such, not a gap noted in prose
- [ ] **The reverse direction is checked too**: no description names a neighbour that CC-9 and
      feature-005 §6c do not assign it, and any that does is reported with the pair it implies
- [ ] **The roster partition is re-derived from disk and the three strata sum correctly.** Curated
      directories with no catalog row captured to a variable -> `18`; rows with `repurpose: true` ->
      `60`; rows without -> `34`; and `18 + 60 + 34` -> `112`, matched against
      `ls -1d canonical/skills/*/ | wc -l`
- [ ] **AC-12 check 1 over all 112.** Every extracted `description:` block is **<= 1024** characters.
      The report gives the count over the cap (**0**), the maximum, the median and the mean, so a
      regression in distribution is visible and not only a breach
- [ ] **AC-12 check 2 over all 112, asserted over the extracted description block.** The count of
      descriptions containing `Direct-entry Lite-path shortcut` -> `0`; containing `VERB=` or
      `ARTIFACT=` -> `0`; containing an arrow-separated state transition sequence -> `0`. The report
      states explicitly that the assertion is over the description block and lists the skills whose
      **bodies** legitimately retain each form, so a reader cannot mistake the scope
- [ ] **AC-12 check 3 at its source.** The generated-doorway description is produced from the
      `frontmatter = (` assignment in
      `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` and leads with the row's
      `intent`; `build-shortcut-skills.py --check` exits 0 and prints `OK:`, so no generated description
      was hand-edited after generation
- [ ] **AC-12 check 4 over all 112**, as a reviewer verdict per skill with the description quoted: the
      user-facing outcome is named before any AID-internal vocabulary. Reported as a table with a
      verdict column, and every negative verdict named
- [ ] **Every one of the 112 states when to use the skill.** The count carrying an explicit trigger
      clause captured to a variable -> `112`, with the clause quoted per skill. Only **2** of 76 carried
      one before this work, so this is the criterion the whole sweep exists for
- [ ] **AC-12 check 5 -- the gate is green and the count did not move.**
      `bash tests/canonical/test-dogfood-byte-identity.sh` is green with **both** key sets reported
      (`DBI*` and `DBI-CUR*`); `node tests/canonical/check-skill-counts.mjs` exits 0 and reports **34**
      for `emitting shortcuts`; and no count-bearing assertion moved as a result of a description change
- [ ] **The descriptions reached the profiles, which is what makes the sweep adopter-visible.**
      `grep -rc 'Direct-entry Lite-path shortcut' profiles/ .claude/ .cursor/` captured to a variable ->
      `0`, and a witness from each stratum is compared between `canonical/` and all five profile roots
- [ ] **Judgement is reported as judgement.** The trigger-clause and check-4 rows are recorded as
      reviewer verdicts with quoted text, never as a grep standing in for a reading, and the record says
      which rows are mechanical and which are read
- [ ] This task writes nothing: `git status --porcelain` over `canonical/`, `tests/`, `site/`, `docs/`,
      `.aid/knowledge/`, `profiles/`, `.claude/` and `.cursor/` is **identical before and after**, and
      `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- every mechanical row is a grep, a
      measurement or a named suite over committed content, so two executions produce identical outcomes
      and there is nothing to tear down
- [ ] All section-6 quality gates pass
