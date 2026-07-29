# /aid-execute — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.cursor/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `executable` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade the artifacts a task or delivery produced for:
    - Every acceptance criterion in the task DETAIL is met, individually verified
    - Build, lint and the declared test suites are green
    - Conventions from the KB are followed for the language in hand
    - No declared architectural boundary is crossed
    - New behaviour is covered by a test that would fail if it regressed
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - The task's own scope definition (that is /aid-detail's grade)
  - Other tasks in the same delivery, unless the manifest names them
  - Pre-existing defects outside the artifacts under review
  - KB document accuracy -- route to /aid-discover Q&A
```
