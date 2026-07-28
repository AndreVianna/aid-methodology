# Delivery BLUEPRINT -- delivery-015: One grading backend

> **Delivery:** delivery-015
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make `grade.sh` the only producer of a letter grade in AID. Today a second, weighted-points model
grades the knowledge summary on a percentage ladder, and ten of its points are dead weight that can
never fail.

## Scope

- The 14 scored checks re-expressed as `SUMMARY` rule rows with severity anchors; the two
  unconditionally-passing checks deleted.
- `grade-summary.sh` gutted and renamed `emit-summary-findings.sh` -- it emits ledger rows and
  computes no grade.
- `manual-checklist.sh` de-scored to an answer recorder; the checklist artifact becomes a
  precondition, not a score carrier.
- The two binary ratio verdicts retired in favour of the conservative rules beside them; the
  visual-gate verdict split three ways, with `--non-functional` reserved for "nothing usable".
- An unanswered checklist stops producing a grade of `F` and instead pauses.
- The two-grade model removed from 13 surfaces.

**Out of scope:** `grade.sh` itself -- no change of any kind; back-converting historical two-grade
values.

## Gate Criteria

- [ ] Exactly one component produces a letter grade (NFR-7); no second grade function survives
- [ ] `grade.sh` is byte-identical to its pre-delivery state
- [ ] The two-grade model appears on no surface
- [ ] An unanswered checklist produces a pause, not a grade
- [ ] The retired ratio conditions no longer appear
- [ ] The rewritten test suite reduces no assertion, so coverage parity stays clean
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-004, delivery-008
- **Blocks:** delivery-016

## Notes

**Spine delivery**, and the largest in the work. Its coverage tightening is deliberate and shipped
un-softened: one unreferenced doc moves the summary from a passing grade to a failing one.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | SUMMARY rule rows |
| task-002 | REFACTOR | 2 | emit-summary-findings.sh |
| task-003 | REFACTOR | 2 | De-score the manual checklist |
| task-004 | IMPLEMENT | 2 | Retire the binary verdicts |
| task-005 | MIGRATE | 3 | Remove the two-grade model |
| task-006 | TEST | 4 | NFR-7: one grade producer |
