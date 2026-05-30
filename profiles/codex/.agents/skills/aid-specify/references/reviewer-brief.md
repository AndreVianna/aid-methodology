# /aid-specify — Reviewer Dispatch Brief Template

Loaded by `/aid-specify` REVIEW state. Renders the brief passed to the
`reviewer` sub-agent. Follows `.agents/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}` and `{{CONTEXT}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT contains downstream phase concerns (planning,
  task breakdown, execution), flag it as an OOS observation and bound your
  review to the SPEC.md sections listed in ARTIFACTS.

RUBRIC: .agents/templates/grading-rubric.md (universal severity → grade table)
  Grade ONE feature's SPEC.md technical specification for:
    - Consistency with the KB (architecture, module-map, coding-standards, schemas)
    - Internal coherence (schemas ↔ feature flow ↔ layers ↔ acceptance criteria)
    - Codebase reality (does the proposed integration touch the modules it claims?)
    - Testability (acceptance criteria are concrete + verifiable)
    - Spec discipline (no implementation prose; design decisions captured)

OUT OF SCOPE (do NOT grade against):
  - Other features in the same work (only the named feature is under review)
  - PLAN.md sequencing (that's /aid-plan's grade)
  - Task breakdown (that's /aid-detail's grade)
  - KB document accuracy (route KB-source findings to /aid-discover Q&A — they
    are observations for the upstream skill, not penalties here)
  - REQUIREMENTS.md content (route findings to /aid-interview Q&A)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/specify-{feature}.md`. Do NOT count toward severity
  totals or grade. Note the routing destination (CODE | SPEC | KB | REQUIREMENTS)
  in Description/Evidence so the orchestrator can write the cross-phase Q&A entry.

DELIVERABLES:
  - Findings format: severity-tagged + source-tagged (CODE | SPEC | KB | REQUIREMENTS)
  - Output location: `.aid/.temp/review-pending/specify-{feature}.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .agents/scripts/grade.sh; minimum resolved via
    `bash .agents/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`
  - The reviewer NEVER edits the SPEC — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — the feature's `SPEC.md` path plus the section list under
  review (or "full SPEC" if all sections complete).
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    SPEC.md for feature-NNN-{name} in work-NNN-{name}. All sections marked Complete
    in the work STATE.md `## Features Status` row. This is the final review pass
    before the feature is marked Ready.
  ```
  Do NOT include the architect's working notes, prior REVIEW cycle grades, or
  references to downstream skills.

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the reviewer then can't grade
what it doesn't know about.
