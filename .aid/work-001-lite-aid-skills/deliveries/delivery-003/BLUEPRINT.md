# Delivery BLUEPRINT -- delivery-003: Breadth Families

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-001-lite-aid-skills
> **Created:** 2026-07-08

---

## Objective

Complete the shortcut catalog with the remaining (Should/breadth) families: `aid-prototype` (G3),
the eight `aid-document-*` archetypes (G8), and `aid-report` + `aid-show-dashboard` (G11). These
round out the cross-discipline coverage (design, documentation, analysis) so a user can reach any
in-scope activity group via a shortcut. (The test/experiment family is Must and ships in
delivery-002.)

## Scope

- feature-005-prototype-family — `aid-prototype`, `aid-prototype-ui`
- feature-010-document-family — the 8 document archetypes
- feature-011-analyze-and-report-family — `aid-report`, `aid-show-dashboard`

**Out of scope:** the test/experiment family (moved to delivery-002) and the cutover
(delivery-004). `/aid-describe`'s lite path still exists during this delivery.

## Gate Criteria

- [ ] All family dirs exist (catalog↔dirs parity), each scaffolding a correct flattened Lite work
      with the family's default task-type (prototype→DESIGN, report→RESEARCH, dashboard→IMPLEMENT,
      document→DOCUMENT).
- [ ] The ownership boundary holds: doc → the `aid-document-*` archetypes; analytical
      report/dashboard → `aid-report`/`aid-show-dashboard`.
- [ ] `render-drift` CI green; all section-6 quality gates pass.

## Tasks

_none yet_ — filled by `/aid-detail`.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-004

## Notes

Independent of delivery-002; may run in parallel with it once delivery-001 lands.
