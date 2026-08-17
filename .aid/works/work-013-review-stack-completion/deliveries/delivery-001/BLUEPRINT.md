# Delivery BLUEPRINT -- delivery-001: The Single, Watched Stack

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.yml.

> **Delivery:** delivery-001
> **Work:** work-013-review-stack-completion
> **Created:** 2026-08-17

---

## Objective

AID already has a working review stack — criteria that cascade from global to type to file, a
7-column findings ledger, scoped VERIFY/HUNT cycles with a cost meter, and a single `/aid-review`
skill paired with a single `aid-reviewer` agent. A canceled redesign built a rival to each of
those pieces, and while those rivals are not on this branch they remain reachable through an open
pull request and through shipped prose that still describes the rival shape. Separately, six
things the stack should watch are unwatched: the project's own settings file has no check that
runs on its own, the frontmatter linter has no proven runtime gate, the generated `kb.html` is
checked for having been built but never read, delivery blueprints and specify reviews are off the
standard ledger and grading path, citation accuracy is checked for KB docs but not for the
artifacts a work produces, and a second grading backend still coexists with the one that produces
the letter grade. This delivery makes the existing stack the only review system and closes those
blind spots, so that everything the next delivery measures is measured on a stack that is single
and watched. It is scoped as one unit because its two features are both `Must`, are ordered
T1 → T2, and their one shared file — `reviewer-dispatch.md`, formally in feature-001's scope and
assigned to feature-002 through FR-B7's routed finding — is edited in different sections, so task
order resolves it at no cost.

## Scope

- **feature-001-single-review-path-alignment** — close or strip the rival redesign PR; correct
  shipped prose that still describes an 8-column `Rule` ledger or catalog routing; migrate the
  genuinely useful checks out of the abandoned catalog (recovered from git history) into the
  criteria cascade as declared `review-criteria:` entries; close with a recorded four-layer audit
  proving every review-skill reference resolves.
- **feature-002-coverage-gate-completion** — a mechanical gate for `.aid/settings.yml`; the
  frontmatter lint proven wired as a runtime gate; an agent content review for `kb.html`;
  `BLUEPRINT.md` and specify review on the 7-column + `grade.sh` path; citation and quote checks
  covering work artifacts, not only KB docs; one grading backend for the letter grade (SHOULD);
  and no artifact anywhere authoring an in-document history section.

**Out of scope:** feature-003-severity-and-recall-measurement (delivery-002 — it edits
`reviewer-ledger-schema.md`, which feature-001 requires unchanged). Building or merging a rival
review loader, a second review skill family, or an 8-column `Rule` ledger. Changing `grade.sh`
counting logic or the 7-column schema. Re-opening the canceled predecessor work's delivery SPECs.
Answering Q1–Q9 — each is recorded, and each feature states what it does regardless.

## Gate Criteria

- [ ] `ls -d canonical/skills/*review*/` returns exactly one directory and
      `ls -d canonical/agents/*review*/` exactly one; `bash scripts/checks/review-path-audit.sh`
      prints `RESULT PASS` and exits `0`, with all four layers printing measurement beside
      expectation. All three outputs recorded with the delivery. *(FR-A1, FR-A5; §9 AC-8)*
- [ ] `gh pr view 185 --json state` → `CLOSED`, and `git rev-parse work-003` still resolves so the
      migration source survives; `grep -rn 'rubric catalog' canonical tests scripts docs .aid/knowledge`
      → `0`; the three-spelling 7-column grep (`-e 7-column -e '7 columns' -e 'seven columns'`)
      → `2` in each of the six per-skill briefs and `1` in `/aid-review`. *(FR-A2, FR-A4; §9 AC-1)*
- [ ] Every migrated catalog check has a `review-criteria:` row in
      `.aid/knowledge/authoring-conventions.md` under a **new** id, with Applies-to / Kind /
      Severity / Why populated and the allocation recorded; `grep -rn 'review-rubrics' canonical
      tests scripts docs .aid/knowledge` → `0`. Admitting zero rows is a valid outcome **only** if
      the per-row screening table for all 85 rows is recorded. *(FR-A3; §9 AC-6)*
- [ ] A real pipeline review dispatch occurring **after the last feature-001 task reaches `Done`**
      leaves a brief at `.aid/works/{work}/briefs/<scope>-cycle-<N>.md` and a matching row in
      `review-cost.tsv`. The "after T1" ordering is enforced by the execution graph, not by a gate.
      *(NFR-5 parts 2–3; §9 AC-2)*
- [ ] Every cycle-2+ brief carries the two labelled `VERIFY` and `HUNT` lists and every cycle-1
      brief carries the single unlabelled list, shown by the cited grep over the brief files.
      *(NFR-5 part 1; the gap Q10 closed)*
- [ ] Each of the five T2 gates fires, by a fixture that fails before and passes after or by a
      before/after measurement: the settings gate including a **zero-keys case that exits 1**; the
      frontmatter lint wired at runtime and added to CI, with `FL19` gaining a checked-count
      assertion; the `kb.html` content review catching the live `STATE.md`×15 / `STATE.yml`×0
      defect; a blueprint ledger scope going `0` → `≥1`; the citation lint opening every nested
      `.md` instead of only the depth-1 files. *(FR-B1–FR-B5; §9 AC-3 — re-worded first if Q6
      redefines "per-section")*
- [ ] The corrected three-form, heading-anchored history sweep over the authored trees returns
      only the classified Keep rows; `AS03`/`AS03b` widened to all 76 template files exit `0`; and
      `## Change Log` in `site/src/data` drops `73` → `2` **by regeneration**, never by hand-edit.
      *(FR-B7; §9 AC-7)*
- [ ] **SHOULD** — `grep -oE '"[A-F][+-]?"' canonical/aid/scripts/summarize/grade-summary.sh |
      sort -u | wc -l` → `11` before and `0` after; `grep -c 'Machine Grade:'` → `1` before, `0`
      after; `state-validate.md` still runs `grade.sh --explain` on the 7-column ledger. If Q5
      resolves against conversion this is recorded as **declined by owner decision**, not silently
      dropped. *(FR-B6; §9 AC-3 conditional tail)*
- [ ] Each new script cites the measured re-derivation it removes: `review-path-audit.sh`
      reproduces the naive `7` versus guarded `1` dangling-reference figures, and the settings gate
      reproduces the `39` / `68` / `29` / `28` counts and the `26 × --default A` / `2 × --default A+`
      split. *(NFR-3; §9 AC-5)*
- [ ] `git diff <recorded-base> HEAD -- canonical/aid/scripts/grade.sh
      canonical/aid/templates/reviewer-ledger-schema.md` touches **neither counting logic nor
      column shape**, where the base is the branch tip written into the delivery record before any
      edit, not `master`; `verify_deterministic.py` → PASS; and the render diff over `profiles/`,
      `.claude/`, `.cursor/`, `site/src/data/` and `site/src/content/docs/skills/` contains only
      generator-written paths. *(NFR-1, NFR-2; §9 AC-11)*
- [ ] Every count in this delivery's artifacts carries the command that produced it, and re-running
      that command reproduces the number. *(NFR-4; §9 AC-12)*
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ — `aid-detail` fills this table.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** -- (no delivery). One **external prerequisite**: pull request #185 must be
  closed or stripped of the rival redesign. That is an owner action, not a task in this delivery
  (`gh pr view 185 --json state` returns `OPEN` as of 2026-08-17), and gate criterion 2 fails
  while it remains open.
- **Blocks:** delivery-002

## Notes

- **Answer Q5 and Q6 before `/aid-detail`.** Q5 decides whether the SHOULD criterion is satisfied
  or recorded as declined; Q6 decides the wording of the FR-B4 criterion. Q3 and Q2 change task
  count inside this delivery but not its boundary.
- **Criterion ids are owed.** The feature SPECs deliberately allocate none, because `aid-reviewer`
  treats an invented id as itself a defect. This delivery needs ids for the migrated catalog rows
  and for any `kb.html` and work-artifact criteria.
- **One ambiguity to settle at Detail:** feature-002's routed findings claim the in-document
  changelog in `reviewer-dispatch.md` is inherited into FR-B7's scope, but that file is not in
  feature-002's in-scope table. Both features sit in this delivery, so it is a one-line ownership
  clarification, not a boundary question. Note the corrected sweep does not catch it — the section
  is a dated `## Bootstrap exemption` heading.
- **`oracle:` may be unreachable.** The criteria table's header is six columns with no oracle cell,
  and feature-001 defers the table-shape change. If no screened row is mechanically decidable, that
  half of FR-A3 is discharged as *not applicable, stated* — recorded, never skipped.
