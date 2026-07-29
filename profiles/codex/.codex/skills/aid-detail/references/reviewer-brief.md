# /aid-detail — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.codex/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `definition` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade the task DETAIL.md files for a work for:
    - Every task has a valid Type from the closed enum, and a scope a single agent can execute
    - Every acceptance criterion is decidable and bound to the task's own scope
    - Dependencies are acyclic and reference tasks that exist
    - Every delivery gate criterion is discharged by at least one task
    - No task carries implementation prose the SPEC should own
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - SPEC.md content (that is /aid-specify's grade)
  - Delivery sequencing (that is /aid-plan's grade)
  - The code a task will produce -- it does not exist yet
  - KB document accuracy -- route to /aid-discover Q&A
```
