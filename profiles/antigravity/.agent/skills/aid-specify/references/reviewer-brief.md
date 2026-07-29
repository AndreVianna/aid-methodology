# /aid-specify — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.agent/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `definition` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade a feature's SPEC.md technical specification for:
    - Consistency with the KB (architecture, module-map, coding-standards, schemas)
    - Internal coherence (schemas <-> feature flow <-> layers <-> acceptance criteria)
    - Codebase reality -- does the proposed integration touch the modules it claims?
    - Testability -- acceptance criteria are concrete and verifiable
    - Spec discipline -- no implementation prose; design decisions captured
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - Other features in the same work -- only the named feature is under review
  - PLAN.md sequencing (that is /aid-plan's grade)
  - Task breakdown (that is /aid-detail's grade)
  - KB document accuracy -- route to /aid-discover Q&A
  - REQUIREMENTS.md content -- route to /aid-describe Q&A
```
