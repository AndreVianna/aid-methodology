# Delivery BLUEPRINT -- delivery-024: Seeded-defect corpus

> **Delivery:** delivery-024
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-10

---

## Objective

Give every later recall figure a denominator. A corpus of reviewable artifacts,
each carrying a **known, catalogued** defect set, with each seeded defect naming the rule that
should catch it. Scoped as a distinct unit because it depends on nothing and must exist **before**
the precision work lands -- a baseline taken after the change is not a baseline.

## Scope

- A fixture corpus under `tests/` covering the reviewable artifact classes the rubric
  index routes, one fixture per class at minimum.
- A **defect catalogue** pairing each seeded defect with the rule ID expected to catch it. This is
  the artifact the recall fraction divides by, so it is the deliverable of record, not the fixtures.
- Defects seeded **per rule**, not per artifact, so a rule with no fixture shows up as a hole in the
  corpus rather than as a silence (`FR-H1`).
- The corpus is fixture-owned: it builds its own inputs and reads no work folder, per the transient
  work-folder rule in `CLAUDE.md`.

Carries `FR-H1`. Feature owner `feature-009`, whose SPEC does not yet exist -- see
`PLAN.md § Open at Plan`.

**Out of scope:** measuring anything. Running a review over the corpus and reporting a fraction is
delivery-027. This delivery ships the corpus and the catalogue and asserts nothing about reviewer
behaviour.

## Gate Criteria

- [ ] A defect catalogue exists and every entry names the rule ID expected to catch it
- [ ] **Every rule set reachable by a kind-A artifact class has at least one fixture**, class routes
      and family fallbacks alike. Checked by joining the catalogue against `review-rubrics/INDEX.md`'s
      routing table and its resolution order; a reachable rule set with no fixture is a failure of this
      criterion, because unmeasured is not the same as clean. **Bounded to kind A deliberately:** the
      index states only kind A needs rule rows, so `SETTINGS` (kind D), `STATE` (kind C) and
      `INDEX`/`METRICS`/`PROJECT-INDEX` (kind B) have no rule to name and cannot carry a catalogue row
      at all -- asserting over them would make this criterion permanently unsatisfiable. The bound is
      specified in `features/feature-009-review-effectiveness/SPEC.md § 2b`
- [ ] Each seeded defect is independently addressable -- the catalogue identifies it precisely enough
      that a review either found *that* defect or did not, with no judgment call at scoring time
- [ ] The corpus builds its own fixtures and reads nothing under `.aid/works/`
- [ ] Adding the corpus changes no grade `grade.sh` computes for any existing ledger
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-027

## Notes

**Why this is first of the 2026-08-10 set.** `REQUIREMENTS.md § 10` puts group H fifth
because `FR-H1` depends on nothing while `FR-H2` needs a built subsystem. The group straddles the
order deliberately.

**Why the catalogue and not the fixtures is the deliverable.** A fixture with an uncatalogued defect
is worse than no fixture: it makes recall look lower than it is and gives no way to tell a miss from
a mis-seed. The catalogue is what makes a miss attributable.
