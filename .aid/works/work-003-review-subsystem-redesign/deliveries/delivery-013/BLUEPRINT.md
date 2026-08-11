# Delivery BLUEPRINT -- delivery-013: Modality enforcement

> **Delivery:** delivery-013
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make every requirement and acceptance criterion carry an explicit modality, so that how binding a
rule is, is written down rather than inferred from its tone.

**RE-STATED 2026-08-11 (`STATE.md` Q32).** This objective read: *"since the canonical severity scale's
first step reads it. Without this, step 1 of the scale has no input and severity falls back to
judgment."* Step 1 is retired and severity **is** judgment now, so that rationale is gone -- but the
objective survives it, which is why this delivery is re-stated rather than re-scoped. Modality is still
worth writing down, for a reason that never depended on the lookup: **an author who has not said
whether a rule is mandatory has usually not decided.** What changes is the consequence of a missing
tag -- it no longer blocks a grade (`FR-I5`), and the check moves to `aid-describe` (`FR-B5a`).

## Scope

- `lint-modality.sh`, gating on a missing or non-conforming modality tag.
- The four templates that author requirements and acceptance criteria.
- The four skill states that write them.
- The retroactive back-fill across existing work artifacts.

**Out of scope:** treating a missing modality as a review finding -- after delivery-007 it is a
criteria gap, and this lint is the authoring-time gate that stops it arising.

## Gate Criteria

- [ ] A requirement with no modality tag is rejected, and one with a non-conforming tag is rejected
- [ ] All four templates carry the modality field
- [ ] The back-fill leaves no untagged requirement or acceptance criterion in the tree
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-003
- **Blocks:** -- (none)

## Notes

**Free track** -- escapes the AGENT.md spine, so it is available work whenever the spine stalls.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | lint-modality.sh |
| task-002 | CONFIGURE | 2 | Wire the modality gate |
| task-003 | MIGRATE | 2 | Back-fill existing modalities |
