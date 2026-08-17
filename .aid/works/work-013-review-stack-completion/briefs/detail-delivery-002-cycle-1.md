ARTIFACTS UNDER REVIEW:
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-026/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-027/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-028/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-029/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-030/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-031/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-032/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-033/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-034/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-035/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-036/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-037/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-038/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-039/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-040/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-041/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-042/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-043/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-044/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-045/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-046/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-047/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-048/DETAIL.md

      (the 23 task definition files -- the whole delivery-002 task set)
  - the matching tasks/task-0NN/STATE.yml files, for seeded shape only

  Readable to verify a claim, NOT graded here: the delivery-002 BLUEPRINT, PLAN.md,
  feature-003's SPEC, REQUIREMENTS.md, the `qa` sequence, and delivery-001's 25 task files
  (whose shape this set follows).

  Cycle 1, so this is ONE unlabelled list.

CONTEXT:
  Tasks for delivery-002 of work-013; feature SPEC: feature-003-severity-and-recall-measurement.
  The SPEC is gated A+, and the delivery BLUEPRINT with its ten gate criteria is gated A+.
  delivery-001's 23-task set passed its own gate at A+ and this set follows its shape.

  NFR-1 is the sharpest constraint on this delivery: it EDITS reviewer-ledger-schema.md, the file
  delivery-001's feature-001 required unchanged. The why-line must live inside the existing seven
  columns and the grading script must not be touched. Judge whether the task set actually
  guarantees that or merely asserts it.

  All eleven Q&A entries are Answered. Three bear on this delivery: Q1 fixed the base ref to the
  work's own base commit; Q8 requires AC-9 be measured BOTH by a command and by reading the rows
  it flags; Q9 confirmed the two synthesized criteria, now AC-13 and AC-14 in §9, so they are no
  longer provisional. Judging a task against stale SPEC wording where an answer superseded it
  would be a defect in the review -- check the answers first.

  The SPEC's own baseline figures have moved since approval: the head it recorded is stale and
  one of its measured provenance figures no longer reproduces. task-026 therefore re-measures
  rather than quotes. Verify that the task set does not copy a stale number anywhere.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns (execute, deploy), flag it as
  an OOS observation and bound your review to the task files listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade the task set for:
    - Sequence integrity: does each task have what it needs from its predecessors? Is anything
      used before it is created? Any forward or circular dependency?
    - Type discipline: exactly one type per task, no task mixing types, types matching what the
      task actually produces. A task titled as a restatement of its type is a defect.
    - Size: does each task plausibly fit one agent session? Name any that does not.
    - Criteria: concrete and testable, and decidable by a command or a fixture. A criterion that
      cannot fail is a defect.
    - Coverage: every one of the BLUEPRINT's ten gate criteria reached by at least one task.
      Report any gate criterion no task discharges.
    - Scope fidelity: the task set does what the SPECs and the Q&A answers say, and does not
      invent work neither authorised.
    - Factual accuracy: RE-RUN the measured claims the tasks cite. Several tasks state a
      before-value (grep counts, exit codes, file counts). A stated before-value that does not
      reproduce is a defect, because the task's own proof depends on it.
    - No new decisions: Detail slices what Plan and Specify already decided. A task making a
      fresh design decision is a defect.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Resolution is defined in
  .cursor/aid/templates/kb-authoring/review-rubric.md; the registry and criteria table live in
  .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell. An id resolving nowhere is a
    defect in the review.
  - A `kind: exclude` criterion binds you: reporting it is a defect.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout rather than re-reading it.
    `UNDECIDED <path>` is normal; a missing or crashing oracle DEGRADES the criterion to reading
    and you record the degradation.
  - Note: files under `.aid/works/**` resolve to NO row in the type registry. Where no declared
    criterion reaches a real defect, report it and say so plainly in Evidence. Do not invent an
    id, and do not suppress the finding for want of one.

OUT OF SCOPE (do NOT grade against):
  - delivery-001, its BLUEPRINT and its 25 tasks -- already gated at A+.
  - The BLUEPRINT, PLAN.md, the SPECs and REQUIREMENTS.md themselves; all are already gated.
  - The Q&A answers as decisions -- they are settled. Showing a task CONTRADICTS one is valuable.
  - Whether two deliveries was right, and whether three features was right.
  - Execution order at runtime, worktree mechanics, and anything aid-execute owns.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, noting the routing destination
  in Description/Evidence. They do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/detail-delivery-002.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`. Read it first if it exists; append new
    findings as Status: Pending.
  - The ledger is the ENTIRE file: ONE markdown table, 7 columns, no headers, no narrative.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/detail-delivery-002.md`
  - Minimum grade: A (`read-setting.sh --skill detail --key minimum_grade --default A`).
  - You NEVER edit a task file -- you grade and list.
