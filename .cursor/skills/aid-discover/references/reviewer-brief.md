# /aid-discover — Reviewer brief sections

The brief itself, the invocation manifest, the out-of-scope policy, the deliverables and the
derive-from-disk rule all live in
[`.cursor/aid/templates/reviewer-brief-template.md`](../../../aid/templates/reviewer-brief-template.md).

This file carries **only the two sections that are genuinely per-skill.** Everything else was
previously copied here and in five sibling briefs, and had drifted — five of the six still advertised
the retired source tags.

**Rule set:** `KB` — resolved via `review-rubrics/INDEX.md`, not asserted here.

## RUBRIC_BODY

```
  Grade the Knowledge Base documents produced by discovery for:
    - Every load-bearing claim is grounded in a durable, resolving citation
    - No drift-prone value -- nothing that goes stale without anyone editing the file
    - The document holds one concern and does not duplicate another's
    - Frontmatter is complete and valid
    - Claims agree with the source code they describe
```

## OUT_OF_SCOPE

```
OUT OF SCOPE (do NOT grade against):
  - Product code quality -- the KB describes it, it does not own it
  - Work documents (REQUIREMENTS, SPEC, PLAN) -- other skills grade those
  - Anything outside the doc set resolved for this run
```
