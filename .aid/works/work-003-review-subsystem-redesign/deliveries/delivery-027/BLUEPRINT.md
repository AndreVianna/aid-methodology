# Delivery BLUEPRINT -- delivery-027: Recall measurement

> **Delivery:** delivery-027
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-10

---

## Objective

Give the grade a denominator. Report the fraction of seeded defects a review pass
finds, per rule set as well as overall, and record the baseline a later drop is measured against.
Scoped last because it measures the shape that actually ships.

## Scope

- The measurement: run the review over delivery-024's corpus and report the found
  fraction, **per rule set** and overall (`FR-H2`). An aggregate alone is out -- it hides a rule that
  never fires.
- The series `tests/recall-baseline.tsv`, created and appended by `recall-measure.sh` itself -- one
  run-stamped row per rule set **and the OVERALL line**, per run, so it needs no other writer and no
  per-close duty. The SPEC states which lines are persisted and why; this Scope does not restate it.
- `FR-H3`'s regression rule: a review obligation with no specified threshold. `recall-measure.sh` prints
  the new figure beside that rule set's prior runs and a reviewer judges
  (`feature-009`'s SPEC § 3 step 5).
- `AC-16`: every **in-domain** rule set reports a figure, and none reports zero fixtures. The domain is
  the predicate in `features/feature-009-review-effectiveness/SPEC.md § 2b`, which is where it is
  defined; this line does not restate it.

Carries `FR-H2`, `FR-H3` and `AC-16`. Feature owner `feature-009`.

**Out of scope:** gating on the figure. `FR-H2` is explicit that this is a measurement, not a gate: it states
what recall **is**. `FR-H3` makes a regression a defect to be justified, which is a review
obligation, not a `grade.sh` threshold. Turning recall into a pass/fail bar would need a second
arithmetic, which `FR-F6` forbids.

## Gate Criteria

- [ ] **Both terms of `FR-H2` are produced: a figure per rule set AND an overall figure.** Each line
      carries the lane terms that apply to it -- the judgment-lane fraction and, where the rule set has
      script-decided rules, the script-lane assertion count. A rule set with no script-decided rule
      prints `--` for that term, never `0/0`, which would read as a measured zero. The terms are printed
      side by side and never blended: a blend would be the second grading arithmetic `FR-F6` retires,
      and would hide which lane moved
- [ ] **No rule set reports zero fixtures**, over the in-domain set of `SPEC.md § 2b`. Joined against
      the corpus catalogue; an in-domain rule set with no fixture fails this criterion rather than
      reporting an empty pass
- [ ] The baseline is recorded where a later run can compare against it, and the comparison is
      reproducible from the recorded inputs -- which are the catalogue and the ledger, the only two
      files the figure is computed from
- [ ] The figure describes the **merged** `/aid-review` that delivery-022 ships, not a skill being
      replaced
- [ ] A miss is attributable: for each missed seeded defect the report names the coverage worklist
      item that should have caught it, which is what delivery-026 makes possible
- [ ] `FR-F6` respected -- no second grading arithmetic and no override channel; the recall figure is
      reported alongside the grade, never folded into it
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-022, delivery-024, delivery-026
- **Blocks:** -- (none)

## Notes

**Why all three upstreams are real, not defensive.** delivery-024 supplies the
denominator. delivery-022 merges the two review skills, so measuring earlier would describe a shape
being replaced. delivery-026 makes a coverage row per-claim, without which a miss is unattributable
-- you would know a defect was missed but not which pass should have caught it, which is the figure's
whole diagnostic value.

**Known risk, and what actually answers it.** A figure first taken this late cannot be attributed to any
one delivery. `PLAN.md § Cross-Cutting Risks` row 6 records the risk. What answers it is **Lane A
breaking the build from `delivery-024`'s close onward**: a script rule that stops catching its seeded
defect fails CI at that close, not here. An earlier draft had a Lane A *series* accumulating from 024
instead; that was deleted as inert -- Lane A's expected value is fixed at 1.0 and a failure breaks the
build, so every pre-027 row would have been the same constant. `feature-009`'s SPEC § 7 states this, and
records that it corrects `STATE.md` Q31's mitigation wording.
