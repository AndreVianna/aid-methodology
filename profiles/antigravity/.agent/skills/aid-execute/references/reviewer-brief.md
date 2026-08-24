# /aid-execute — Reviewer Dispatch Brief Template

Loaded by `/aid-execute` REVIEW + DELIVERY-GATE states. Renders the brief passed
to the `aid-reviewer` sub-agent. Follows `.agent/aid/templates/reviewer-dispatch.md`.

Two dispatch points share this template (`{{MODE}}` distinguishes them):

- **per-task REVIEW** — Small-tier quick-check, HIGH+ findings deferred to delivery gate (FR2)
- **per-delivery DELIVERY-GATE** — full review/fix/review loop, tier = delivery complexity

`{{ARTIFACTS}}`, `{{CONTEXT}}`, `{{MODE}}` are filled at dispatch time.

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

RUBRIC: .agent/aid/templates/grading-rubric.md (universal severity → grade table)
  - Grade is COMPUTED by .agent/aid/scripts/grade.sh, not judged
  - Worst issue dominates per the rubric
  - Task-Type-specific checks: see references/reviewer-guide.md for per-Type checklists
    (RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .agent/aid/templates/kb-authoring/review-rubric.md
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
  - BEFORE dispatching: render this brief to
    `.aid/works/{work}/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged list (CODE | TASK | SPEC | KB)
  - Output location:
      per-task:     this task's `tasks_lifecycle` entry (flattened layout) or its
                     own per-task state file (full layout) -- never the DERIVED
                     `## Tasks State` view
      per-delivery: `.aid/.temp/review-pending/execute-delivery-{N}.md` then aggregated
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .agent/aid/scripts/grade.sh; minimum resolved via
    `bash .agent/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`
  - The reviewer NEVER fixes anything — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — at per-task scope: the files/artifacts the executor produced
  (diff list + new files). At per-delivery scope: the full delivery branch
  diff + the PLAN.md delivery section. Never a task's state file/row -- a
  state file is never listed in `{{ARTIFACTS}}`, at either scope
  (`reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`); the reviewer still
  writes its own outcome there, per the Output location below.
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
piped through `filter_reviewable_artifacts` and then filtered by the OUT OF
SCOPE list above (`reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`). Lists
built from memory of what was worked on tend to omit incidentally-touched
files; the reviewer then can't grade what it doesn't know about.
