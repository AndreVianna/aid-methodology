# /aid-detail — Reviewer Dispatch Brief Template

Loaded by `/aid-detail` REVIEW state (per-deliverable in Step 3 of The Loop;
whole-task-list on re-run). Renders the brief passed to the `aid-reviewer`
sub-agent. Follows `.github/aid/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}`, `{{CONTEXT}}`, `{{SCOPE}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT discusses how tasks will be executed (agent
  choice, branching, parallelism details beyond what's in the Execution Graph),
  flag it as an OOS observation and bound your review to task files + the
  Execution Graph for this delivery only.

SCOPE: {{SCOPE}}   # one of: per-deliverable | whole-list
  per-deliverable: Grade the task list for ONE delivery just written.
  whole-list:      Re-grade all task files against current PLAN.md + SPECs.

RUBRIC: .github/aid/templates/grading-rubric.md (universal severity → grade table)
  Grade tasks for:
    - Each task has exactly ONE Type (no mixing)
    - Task size fits one agent session
    - Every task traces back to a feature SPEC + delivery
    - Acceptance Criteria are concrete + testable
    - Dependencies declared correctly (Execution Graph valid; no cycles; no missing edges)
    - Type-specific default criteria included where applicable
    - Sequence respects natural ordering (RESEARCH/DESIGN before IMPLEMENT; TEST after; etc.)
    - Quality gate cascade present (REQUIREMENTS §6 inherited; feature-specific gates added)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then the
  artifact's own `review-criteria:` frontmatter; most specific wins on an id collision.
  Resolution is defined in .github/aid/templates/kb-authoring/review-rubric.md
  (section: Resolving review criteria); the type registry and the criteria table live in
  .aid/knowledge/authoring-conventions.md. This brief deliberately does NOT restate them.
  - Cite the criterion `id` as a prefix in the ledger's Description cell (7 columns, no
    new column). A finding citing no id, or an id resolving nowhere, is itself a defect.
  - A `kind: exclude` criterion binds you: reporting it is a defect in the review.
  - **If a criterion carries an `oracle:`, RUN it -- do not re-read the criterion to
    reach the same verdict.** Invoke it from the repository root under a 60-second
    timeout. It reports per FILE: exit 0 means no violation among the files it decided,
    exit 1 means at least one `VIOLATION <path>` line, exit 2 (or any other exit, a
    timeout, or exit 1 with no VIOLATION line) means it could not decide.
  - **`UNDECIDED <path>` lines are normal, not a failure.** Take the decided files as
    settled and judge only the undecided remainder by reading.
  - **A missing, non-executable, crashing, timed-out or malformed oracle DEGRADES that
    criterion to reading, and you record that the degradation happened.** Never let a
    degraded oracle read as a pass, and never file it as a violation -- "I could not
    tell" is neither.
  - One finding per `VIOLATION` line: the criterion `id` as the Description prefix, the
    invocation and that line in Evidence. Seven columns, unchanged.
  - If the severity came from a file-level override, record the resolved severity and the
    overriding file's `why` in the Evidence cell.

OUT OF SCOPE (do NOT grade against):
  - SPEC.md content — that's /aid-specify's grade
  - PLAN.md deliverable sequencing — that's /aid-plan's grade
  - KB document accuracy — route KB-source findings to /aid-discover Q&A
  - Execution detail (which agent, what branch) — /aid-execute owns runtime decisions
  - Tasks belonging to other deliveries (at per-deliverable scope)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/detail-{work}.md`. Do NOT count toward severity totals
  or grade. Note the routing destination (PLAN | SPEC | KB) in Description/Evidence.

DELIVERABLES:
  - Findings format: severity-tagged + source-tagged (TASK | PLAN | SPEC | KB)
  - Output location: `.aid/.temp/review-pending/detail-{work}.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .github/aid/scripts/grade.sh; minimum resolved via
    `bash .github/aid/scripts/config/read-setting.sh --skill detail --key minimum_grade --default A`
  - The aid-reviewer NEVER edits task files — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — at per-deliverable scope: the task DETAIL.md files just written for
  delivery-NNN (`.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`) + the Execution
  Graph section just appended to PLAN.md. At whole-list scope: every
  `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (all deliveries) + the full PLAN.md.
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    (per-deliverable) Tasks for delivery-NNN of work-NNN; feature SPECs:
                      feature-NNN-{name}, ...
    (whole-list)      Re-review of all tasks for work-NNN after PLAN/SPEC changes.
  ```
  Do NOT include the aid-architect's working notes or prior cycle grades.
- `{{SCOPE}}` — literal `per-deliverable` or `whole-list`.

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the aid-reviewer then can't grade
what it doesn't know about.
