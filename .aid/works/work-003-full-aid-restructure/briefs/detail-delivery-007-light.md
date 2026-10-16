# Reviewer brief -- aid-detail work-003 delivery-007, light review (Q136)

ARTIFACTS UNDER REVIEW:
  - .aid/works/work-003-full-aid-restructure/deliveries/delivery-007/tasks/task-*/DETAIL.md (24 files: task-161 to task-184) and their STATE.yml
  - .aid/works/work-003-full-aid-restructure/analysis/detail-proposal-delivery-007.md (the delivery's derived execution graph and settled decisions; PLAN.md's Execution Graph is written only after all deliveries are detailed)
  - .aid/works/work-003-full-aid-restructure/PLAN.md: the delivery-007 stanza, Common Gate G0, "Testing before the resync (Q131)", "Toolchain and Branching"
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 005 (its Technical Specification)
  - .aid/works/work-003-full-aid-restructure/STATE.yml qa Q104, Q111-Q136 (maintainer decisions)

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
Tasks for delivery-007 of work-003 (AID restructuring itself; v4.0.0); feature sections: feature-005 specification-business-and-technical. Deliveries 001-009 are built directly by the main conversation, one task at a time (Q127).

  Reviewer self-check: If CONTEXT discusses how tasks will be executed (agent
  choice, branching, parallelism details beyond what's in the Execution Graph),
  flag it as an OOS observation and bound your review to task files + the
  Execution Graph for this delivery only.

SCOPE: per-deliverable   # one of: per-deliverable | whole-list
  per-deliverable: Grade the task list for ONE delivery just written.
  whole-list:      Re-grade all task files against current PLAN.md + feature sections.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity → grade table)
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
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .aid/runtime/templates/kb-authoring/review-rubric.md
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
  - feature technical-specification content — that's /aid-specify's grade
  - PLAN.md deliverable sequencing — that's /aid-plan's grade
  - KB document accuracy — route KB-source findings to /aid-discover Q&A
  - Execution detail (which agent, what branch) — /aid-execute owns runtime decisions
  - Tasks belonging to other deliveries (at per-deliverable scope)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/detail-work-003-delivery-007.md`. Do NOT count toward severity totals
  or grade. Note the routing destination (PLAN | SPEC | KB) in Description/Evidence.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/work-003-full-aid-restructure/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (TASK | PLAN | SPEC | KB)
  - Output location: `.aid/.temp/review-pending/detail-work-003-delivery-007.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill detail --key minimum_grade --default A`
  - The aid-reviewer NEVER edits task files — only grades and lists issues

LEDGER LIFECYCLE: Read `.aid/.temp/review-pending/detail-work-003-delivery-007.md` if it exists; verify existing rows; append new findings with Status: Pending. ONE table per `.aid/runtime/templates/reviewer-ledger-schema.md`. Then run `bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/detail-work-003-delivery-007.md` and include the grade.

LIGHT REVIEW (maintainer rule Q136): one pass over this delivery's tasks only. A full whole-list review runs once at the end. Check, for this delivery: every PLAN stanza item and gate criterion has an owning task; nothing is used before a task creates it; each task has one type and fits one session; every acceptance criterion is checkable; every suite asserting a file a task rewrites is updated in that same task (Q106); no task runs run_generator.py in the live tree (the resync is a delivery step); the test step follows "Testing before the resync". Cross-delivery contradictions are for the final full review -- log them as OOS (route TASK) if you see one.

WHAT TO REPORT (maintainer rule, FR-21): report ONLY issues that affect the work -- a task that cannot be built or verified as written, a missing owner for a plan or spec item, a wrong dependency, or a contradiction with the plan, the spec or a maintainer decision. Exact counts, word-for-word comparisons and wording/cosmetic points are NOT findings.
