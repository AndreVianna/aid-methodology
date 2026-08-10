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
- The recorded baseline, and the rule that a later drop is a defect in the review subsystem to be
  justified or reverted (`FR-H3`).
- `AC-16`: every rule set reports a figure, and none reports zero fixtures.

Carries `FR-H2`, `FR-H3` and `AC-16`. Feature owner `feature-009` -- see
`PLAN.md § Open at Plan`.

**Out of scope:** gating on the figure. `FR-H2` is explicit that this is a measurement, not a gate: it states
what recall **is**. `FR-H3` makes a regression a defect to be justified, which is a review
obligation, not a `grade.sh` threshold. Turning recall into a pass/fail bar would need a second
arithmetic, which `FR-F6` forbids.

## Gate Criteria

- [ ] A per-rule-set recall figure is reported, not only an overall one
- [ ] **No rule set reports zero fixtures.** Joined against the corpus catalogue; a rule set with no
      fixture fails this criterion rather than reporting an empty pass
- [ ] The baseline is recorded where a later run can compare against it, and the comparison is
      reproducible from the recorded inputs
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

**Known risk, and the mitigation is in the plan.** The baseline arrives after 26 deliveries have
changed the reviewer, so a low figure cannot be attributed to any one of them. `PLAN.md
§ Cross-Cutting Risks` row 6 records this: the measurement runs at every delivery close from 024
onward, so a series exists before the number matters.
