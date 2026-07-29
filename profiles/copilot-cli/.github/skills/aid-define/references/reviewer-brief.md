# /aid-define — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.github/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `definition` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade a work's REQUIREMENTS.md and its feature decomposition for:
    - Every requirement carries an explicit modality (MUST / SHOULD / COULD)
    - Every acceptance criterion is decidable without asking the author
    - Requirements trace to a stated need; features trace to requirements
    - No feature straddles two requirements, and none is orphaned
    - Internal consistency -- counts and named sets agree across the document
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - SPEC.md content (that is /aid-specify's grade)
  - Delivery sequencing (that is /aid-plan's grade)
  - KB document accuracy -- route to /aid-discover Q&A
  - Implementation feasibility -- a requirement is not graded on how hard it is
```
