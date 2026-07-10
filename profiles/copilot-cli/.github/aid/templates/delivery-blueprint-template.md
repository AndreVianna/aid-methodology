# Delivery BLUEPRINT -- delivery-NNN: {Title}

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-NNN
> **Work:** work-NNN-{name}
> **Created:** {YYYY-MM-DD}

---

## Objective

{One paragraph: what this delivery achieves and why it is scoped as a distinct unit.}

## Scope

{What is IN scope for this delivery -- bounded list of deliverables. Reference features or
requirements by name where applicable.}

**Out of scope:** {anything explicitly excluded from this delivery to avoid scope creep.}

## Gate Criteria

{The ordered acceptance criteria the delivery gate will evaluate. Each criterion must be
concrete and independently testable. The grade.sh pass uses these as the rubric.}

- [ ] {Criterion 1 -- concrete and testable}
- [ ] {Criterion 2 -- concrete and testable}
- [ ] All section-6 quality gates pass

## Tasks

{Brief listing of tasks that belong to this delivery. Each task has a full DETAIL.md at
tasks/task-NNN/DETAIL.md. This section provides a navigational overview only.}

| Task | Type | Title |
|------|------|-------|
| task-NNN | {TYPE} | {Title} |

## Dependencies

{Other deliveries or external prerequisites this delivery depends on, or -- (none).}

- **Depends on:** delivery-NNN | -- (none)
- **Blocks:** delivery-NNN | -- (none)

## Notes

{Any design notes, constraints, or references relevant to this delivery that are not captured
in the gate criteria. Keep brief; detailed design belongs in task DETAIL.md files.}
