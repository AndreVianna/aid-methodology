# Single Review Path Alignment

## Source

- REQUIREMENTS.md §4 Scope — T1 Align
- REQUIREMENTS.md §5 Functional Requirements — FR-A1, FR-A2, FR-A3, FR-A4, FR-A5
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-5
- REQUIREMENTS.md §7 Constraints, §8 Assumptions & Dependencies
- REQUIREMENTS.md §9 Acceptance Criteria — AC-1, AC-2, AC-5, AC-6, AC-8, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 1

## Description

AID already has a working review stack: criteria that cascade from global to type to
file, a 7-column findings ledger, scoped VERIFY/HUNT cycles with a cost meter, and a
single `/aid-review` skill paired with a single `aid-reviewer` agent. A canceled
redesign built a rival to each of those pieces. Those rivals are not in this branch,
but they remain reachable — through an open pull request, and through prose in the
shipped docs that still describes the rival shape.

This feature makes the existing stack the only review system, and proves it rather than
asserting it. Three things happen. Any pull request that would land a rival loader, a
second review skill, or an 8-column ledger is closed or stripped. Every place the
shipped documentation still describes the rival shape is corrected to the law that
actually runs. And the genuinely useful checks that only ever existed inside the
abandoned catalog are lifted out of git history and given a home in the cascade as
declared criteria — the checks come across, the catalog machinery does not.

It closes with an audit, not a claim: a named command whose output shows that every
reference to a review skill, in every dispatch table and every chain target, resolves to
a skill that exists on disk. That output is recorded with the delivery.

This feature goes first because everything the next two measure is measured on this
stack.

## User Stories

- As a pipeline skill, I want exactly one way to dispatch a review, so that a REVIEW state does not have to choose between two review systems that disagree.
- As the reviewer agent, I want criteria to come from the cascade and nowhere else, so that I never have to reconcile a catalog index against a file's own declaration.
- As a maintainer, I want a rival review system to be unable to land through an old pull request, so that the stack I keep rendering into five install profiles stays single.
- As a maintainer, I want the useful checks from the abandoned catalog kept as cascade criteria, so that the work that went into them is not lost with the machinery that carried them.
- As the owner, I want the closing audit to be a command and its output, so that "the stack is single" is something I can re-run rather than something I am told.

## Priority

Must

## Acceptance Criteria

> Each criterion carries the modality of the requirement it discharges. A criterion that
> reads MUST here is MUST because its source requirement is, not by default.

- [ ] **MUST** — Given the aligned stack, when `ls -d canonical/skills/*review*/` and `ls -d canonical/agents/*review*/` are run, then each returns exactly one directory, and the FR-A5 audit command's output shows every review-skill reference, dispatch-table entry and CHAIN target resolving to a skill that exists on disk; both outputs are recorded with the delivery. *(discharges FR-A1, FR-A5; §9 AC-8)*
- [ ] **MUST** — Given the rival redesign pull request, when it is closed or stripped, then it contains no rival loader, no second review skill and no 8-column `Rule` path; and `aid-reviewer` resolves criteria from the cascade only while `/aid-review` and every per-skill brief describe the 7-column ledger, evidenced by the greps and their output. *(discharges FR-A2, FR-A4; §9 AC-1)*
- [ ] **MUST** — Given a check that existed only in the abandoned catalog and is worth keeping, when it is migrated, then it has a cascade `review-criteria:` (or `oracle:`) home cited by id, and no live `review-rubrics/` loader remains. *(discharges FR-A3; §9 AC-6)*
- [ ] **MUST** — Given a real pipeline review dispatch after this feature closes, when the reviewer is dispatched, then a brief file exists on disk and a matching row exists in `review-cost.tsv`. *(discharges NFR-5; §9 AC-2)*
- [ ] **MUST** — Given a script proposed by this feature, when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
