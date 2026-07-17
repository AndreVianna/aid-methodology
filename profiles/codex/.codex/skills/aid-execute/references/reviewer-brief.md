# /aid-execute — Reviewer Dispatch Brief Template

Loaded by `/aid-execute` REVIEW + DELIVERY-GATE states. Renders the brief passed
to the `aid-reviewer` sub-agent. Follows `.codex/aid/templates/reviewer-dispatch.md`.

Two dispatch points share this template (`{{MODE}}` distinguishes them):

- **per-task REVIEW** — Small-tier quick-check, HIGH+ findings deferred to delivery gate (FR2)
- **per-delivery DELIVERY-GATE** — full review/fix/review loop, tier = delivery complexity

`{{ARTIFACTS}}`, `{{CONTEXT}}`, `{{MODE}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT references the executor's working notes,
  prior cycle grades, or fixes already applied, flag it as an OOS observation
  and bound your review to ARTIFACTS only. The reviewer-≠-executor invariant
  requires clean context.

MODE: {{MODE}}   # one of: per-task | per-delivery
  per-task:      Small-tier quick-check. Surface CRITICAL/HIGH/MEDIUM/LOW/MINOR.
                 HIGH and above are deferred to the delivery gate per FR2.
                 Do NOT block the task on HIGH; record and continue.
  per-delivery:  Full quality gate. Aggregate across all tasks in the delivery.
                 The delivery as a whole must reach the minimum grade.

RUBRIC: .codex/aid/templates/grading-rubric.md (universal severity → grade table)
  - Grade is COMPUTED by .codex/aid/scripts/grade.sh, not judged
  - Worst issue dominates per the rubric
  - Task-Type-specific checks: see references/reviewer-guide.md for per-Type checklists
    (RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE)

OUT OF SCOPE (do NOT grade against):
  - The executor agent's process or working notes
  - Code outside the task's stated Scope (other deliveries, other tasks)
  - KB documents (route KB-source findings to /aid-discover Q&A, not into this grade)
  - SPEC re-grading (route SPEC-source findings to /aid-specify, not into this grade)
  - Tasks marked Done in prior cycles unless this task explicitly modified them

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table (per-delivery), or
  in the task row's review history (per-task). Do NOT count toward severity totals
  or the grade. Note the routing destination (KB, SPEC, TASK) in Description/Evidence
  so the orchestrator can write the loopback Q&A.

DELIVERABLES:
  - Findings format: severity-tagged + source-tagged list (CODE | TASK | SPEC | KB)
  - Output location:
      per-task:     `.aid/works/{work}/STATE.md ## Tasks State` row for this task
      per-delivery: `.aid/.temp/review-pending/execute-delivery-{N}.md` then aggregated
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .codex/aid/scripts/grade.sh; minimum resolved via
    `bash .codex/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`
  - The reviewer NEVER fixes anything — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — at per-task scope: the files/artifacts the executor produced
  (diff list + new files). At per-delivery scope: the full delivery branch
  diff + every task's STATE.md row + the PLAN.md delivery section.
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    (per-task)     task-NNN of type {Type} produced these artifacts; AC list lives in task-NNN.md.
    (per-delivery) delivery-NNN aggregates tasks {NNN..MMM}; this is the post-execution
                   quality gate before merge to main.
  ```
  Do NOT include "we already fixed X", prior grades, or branch history.
- `{{MODE}}` — literal `per-task` or `per-delivery`.

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the reviewer then can't grade
what it doesn't know about.
