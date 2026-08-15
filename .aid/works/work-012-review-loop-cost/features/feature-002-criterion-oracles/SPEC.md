# Criterion Oracles

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-8–FR-13, §9 AC-5–AC-8 and AC-11, §6 NFR-1 | /aid-define |
| 2026-08-15 | **FR-9 and FR-11 given explicit criteria.** A coverage sweep found both carried only by the range "FR-8 to FR-13" in `## Source` and demanded by nothing — FR-11's ledger mapping had no criterion anywhere in the work. This is the `tech-debt.md` W5-10 class (an obligation no artifact owns), caught here rather than by an executor mid-build | /aid-define |

## Source

- REQUIREMENTS.md §5 FR-8 to FR-13 (the `oracle:` key, its runner, and the worked example)
- REQUIREMENTS.md §6 NFR-1 (the exit criterion this feature is measured against),
  NFR-2 (bash + awk on the core path), NFR-3 (determinism)
- REQUIREMENTS.md §9 AC-5, AC-6, AC-7, AC-8, AC-11
- REQUIREMENTS.md §8 (a criterion entry tolerates unknown keys, so this is an addition
  rather than a migration)
- STATE.yml Q-01 (what justifies an oracle), Q-02 (where one lives), Q-04 (when one is written)

## Description

Today every criterion is re-decided by a reviewer reading it, on every cycle, forever. For
a genuinely semantic criterion that is unavoidable. For a mechanically decidable one it is
both waste and a reliability problem — the same criterion gets re-derived by hand each
cycle, expensively, and not always to the same answer.

This feature adds **one optional key** to a `review-criteria:` entry, naming an executable
check. A criterion carrying one is decided by *running* it: cheap, deterministic, and
identical every cycle. A criterion without one behaves exactly as it does today.

Three properties make it safe to add:

- **Absence is never a defect.** Most criteria will never carry the key, and that is the
  correct outcome, not an omission to be fixed.
- **Failure degrades rather than lies.** An oracle that is missing, not executable, or that
  crashes falls back to the existing read-based judgment and reports that it did. It never
  silently passes and never silently fails the criterion.
- **It is a pure addition.** A criterion entry already tolerates unknown keys, so no
  criterion already declared has to change.

`G-07` is the worked example, and deliberately so: it is the criterion whose evaluation
needs the whole corpus, which makes it the worst case for feature-003's scoping — and
therefore the best demonstration that an oracle removes the problem rather than dodging it.

**This feature is where NFR-1 bites.** Every oracle is a script, so this is the executable
surface the work adds by design. The exit criterion is not "add nothing" but "replace
something recurring, and measure the trade" — which is why AC-11 is an acceptance criterion
of this feature and not a footnote.

## User Stories

- As a reviewer, I want a mechanically decidable criterion answered by running a check, so
  that my cycles go to judgment instead of to re-deriving the same answer.
- As the repo owner, I want each oracle to name the recurring work it removes, so that
  added machinery is a trade I can audit rather than one I have to trust.
- As an author declaring a criterion, I want to declare it without owning a script, so that
  the absence of an oracle never blocks me.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-5** Given a criterion with no `oracle:` key, when it is reviewed, then it
      produces no finding and grades exactly as it does today. Absence is not a defect.
- [ ] **AC-6** Given a corpus where every in-scope markdown file resolves to exactly one
      registry type, when `G-07`'s oracle runs, then it exits 0; and given a corpus
      containing an untyped or double-typed file, then it exits non-zero and names the
      offending file.
- [ ] **AC-7** Given an unchanged tree, when `G-07`'s oracle runs twice, then its output is
      byte-identical (NFR-3).
- [ ] **AC-8** Given a criterion whose oracle is missing or not executable, when it is
      reviewed, then the criterion is judged by reading and the degradation is reported in
      the ledger (FR-12).
- [ ] **AC-11** Given each oracle shipped, when the work closes, then that oracle names the
      recurring re-derivation it replaces and the measured per-cycle cost of it, and the
      work reports the net trade. An oracle with no recorded replacement is not shipped.
- [ ] **FR-9** Given a criterion that carries an oracle, when it is decided, then it is
      decided by RUNNING the oracle — a reviewer re-reading the criterion to reach the same
      verdict is the waste this feature removes.
- [ ] **FR-11** Given an oracle verdict, when it is recorded, then it lands in the existing
      7-column ledger with the criterion `id` as a `Description` prefix and the oracle's
      invocation and output in `Evidence` — no new column, and no change to the shape
      `grade.sh` parses (C-3).
- [ ] Given an `oracle:` value, when it is resolved, then it resolves from the repository
      root and the oracle lives outside `canonical/` — so no oracle enters the render chain
      (Q-02, NFR-5).
- [ ] Given a criterion that a reviewer has re-derived only once, when authoring is
      considered, then no oracle is written yet: the trigger is a SECOND re-derivation
      (Q-04, FR-10). `G-07` is exempt — its recurrence is already on record in L5.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
