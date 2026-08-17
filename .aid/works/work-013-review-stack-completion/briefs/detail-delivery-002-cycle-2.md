ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against these):
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-030/DETAIL.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-039/DETAIL.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-040/DETAIL.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-042/DETAIL.md

  HUNT (scoped -- look for NEW findings only here):
    - the four files above, plus .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-033/DETAIL.md, whose scope was widened by the same fix.

  Derivation: the three ledger rows name task-030, task-039, task-040 and task-042, so VERIFY is
  those four in full. task-033 joins HUNT because the fix also changed it, in response to the
  scope gap the cycle-1 reviewer raised as undecided rather than as a row.

CYCLE 2 -- WHAT THE FIX CHANGED (verify the three rows; do not re-litigate them):
  Row 1 [LOW] -- task-039 and task-040 said the task "closes as not-applicable", which is not a
    value in the closed state enum. FIX: both now close as `Canceled`, the enum's value for
    explicitly abandoned work, quoting the measurement or discharge in `notes`, and both state
    they are never left Pending. Decide Fixed or Recurred.
  Row 2 [LOW] -- task-042 referred to "the suite that already owns the seeded-defect harness",
    which names no existing suite. FIX: it now names `tests/canonical/test-scoped-review-cycles.sh`
    explicitly AND states that suite's existing harness builds a different fixture set from the
    recall catalogue, so the corpus handling must be added rather than assumed. Decide Fixed or
    Recurred.
  Row 3 [MINOR] -- task-030's fourth criterion asked the record to "name what a weaker check would
    have missed", which is judgment, not a command. FIX: it now requires each check listed by name
    with its command and output, plus the selector count -- all decidable. Decide Fixed or Recurred.

  ALSO FIXED, and in HUNT rather than in a row: the cycle-1 reviewer recorded as undecided that
  the update-kb REVIEW-step sites might fall outside task-033's scope, which would make task-034's
  zero-canary unreachable. task-033's scope now names them explicitly as in scope for its
  classification. Judge whether that closes the gap, and whether task-034's canary is now
  achievable as written.

  Read the existing ledger at .aid/.temp/review-pending/detail-delivery-002.md FIRST. Update the
  three rows' Status in place -- do not delete them, do not rewrite Severity or Description.
  Append any genuinely NEW finding in the HUNT region as a new Pending row.

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
