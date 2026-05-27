# /aid-plan — Reviewer Dispatch Brief Template

Loaded by `/aid-plan` REVIEW state (per-deliverable in Step 4 of The Loop; whole-plan
on re-run). Renders the brief passed to the `reviewer` sub-agent. Follows
`.cursor/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}`, `{{CONTEXT}}`, `{{SCOPE}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT contains task-breakdown concerns or per-task
  acceptance criteria, flag it as an OOS observation and bound your review to
  PLAN.md deliverable sequencing only.

SCOPE: {{SCOPE}}   # one of: per-deliverable | whole-plan
  per-deliverable: Grade ONE newly-written delivery against its dependencies +
                   the standalone-functional criterion. Re-grade preceding
                   deliveries only if this one introduces a sequencing conflict.
  whole-plan:      Re-grade all deliveries against current SPECs + REQUIREMENTS.

RUBRIC: .cursor/templates/grading-rubric.md (universal severity → grade table)
  Grade PLAN.md deliverables for:
    - Each delivery is functional on its own (independently usable + testable)
    - Dependencies flow one direction (no cycles)
    - Every Ready feature is assigned to a delivery OR explicitly Deferred
    - Sequence respects KB architecture (no delivery requires a not-yet-built dependency)
    - Cross-cutting risks only if real
    - Known-issues from `.aid/{work}/known-issues.md` Critical/High addressed (fix-first delivery or sequenced)

OUT OF SCOPE (do NOT grade against):
  - Per-task breakdown — that's /aid-detail's domain (a delivery has no "tasks" yet at /aid-plan time)
  - SPEC.md internal content — that's /aid-specify's grade
  - REQUIREMENTS.md content — that's /aid-interview's grade
  - KB document accuracy — route KB-source findings to /aid-discover Q&A
  - Execution Graph for tasks (added later by /aid-detail)

OUT-OF-SCOPE FINDINGS POLICY:
  Log to `## Out-of-Scope Observations` in `.aid/.temp/review-pending/plan-{work}.md`.
  Do NOT count toward severity totals or grade. Tag with the routing destination
  so the orchestrator can write the cross-phase Q&A entry.

DELIVERABLES:
  - Findings format: severity-tagged + source-tagged (PLAN | SPEC | KB | REQUIREMENTS)
  - Output location: `.aid/.temp/review-pending/plan-{work}.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .cursor/scripts/grade.sh; minimum resolved via
    `bash .cursor/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`
  - The reviewer NEVER edits PLAN.md — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — at per-deliverable scope: the `PLAN.md` deliverable section
  just written + the feature SPECs assigned to it. At whole-plan scope:
  full `PLAN.md` + all feature SPECs.
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    (per-deliverable) delivery-NNN of work-NNN just written; preceding deliveries:
                      delivery-NNN..MMM (titles).
    (whole-plan)      PLAN.md for work-NNN with N deliveries; re-review against
                      current SPECs.
  ```
  Do NOT include the architect's working notes, prior REVIEW cycle grades, or
  references to /aid-detail/aid-execute.
- `{{SCOPE}}` — literal `per-deliverable` or `whole-plan`.
