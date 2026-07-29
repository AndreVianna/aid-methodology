# /aid-plan — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.agent/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `definition` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade PLAN.md and the delivery BLUEPRINTs for:
    - Every delivery has a stated objective, scope and gate criteria
    - Dependencies are acyclic, and every Blocks field agrees with its Depends on
    - Each gate criterion is decidable -- a reader can say met or not met
    - Every requirement is covered by at least one delivery
    - Sequencing respects the declared dependencies and priority order
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - SPEC.md content (that is /aid-specify's grade)
  - Task-level breakdown (that is /aid-detail's grade)
  - Implementation detail inside a delivery
  - KB document accuracy -- route to /aid-discover Q&A
```
