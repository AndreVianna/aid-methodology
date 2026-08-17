ARTIFACTS UNDER REVIEW:
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-001/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-002/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-003/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-004/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-005/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-006/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-007/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-008/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-009/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-010/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-011/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-012/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-013/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-014/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-015/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-016/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-017/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-018/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-019/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-020/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-021/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-022/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-023/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-024/DETAIL.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-025/DETAIL.md

      (the 25 task definition files -- the whole delivery-001 task set)
  - the matching tasks/task-0NN/STATE.yml files, for seeded shape only

  Readable to verify a claim, NOT graded here: the delivery-001 BLUEPRINT, PLAN.md, the two
  feature SPECs, REQUIREMENTS.md, and the `qa` sequence in the work STATE.yml.

  Cycle 1, so this is ONE unlabelled list.

CONTEXT:
  Tasks for delivery-001 of work-013; feature SPECs: feature-001-single-review-path-alignment,
  feature-002-coverage-gate-completion. Both SPECs are gated A+, and the delivery BLUEPRINT with
  its twelve gate criteria is gated A+.

  All eleven Q&A entries are now Answered, and five of them CHANGED the work after the SPECs were
  written. The task set is built on the answers, not on the SPECs alone: FR-B6 is DECLINED so no
  conversion task exists; FR-B4 is narrowed to BLUEPRINT.md so no per-section mechanism is built;
  kb.html gets a standalone check with no registry type; change logs are already removed
  repo-wide, so FR-B7 is largely landed and its proof needs a fixture rather than a live
  before/after. Judging a task against stale SPEC wording where an answer superseded it would be
  a defect in the review -- check the answers first.

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
    - Coverage: every one of the BLUEPRINT's twelve gate criteria reached by at least one task.
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
  - delivery-002 and feature-003 -- a later per-deliverable pass.
  - The BLUEPRINT, PLAN.md, the SPECs and REQUIREMENTS.md themselves; all are already gated.
  - The Q&A answers as decisions -- they are settled. Showing a task CONTRADICTS one is valuable.
  - Whether two deliveries was right, and whether three features was right.
  - Execution order at runtime, worktree mechanics, and anything aid-execute owns.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, noting the routing destination
  in Description/Evidence. They do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/detail.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`. Read it first if it exists; append new
    findings as Status: Pending.
  - The ledger is the ENTIRE file: ONE markdown table, 7 columns, no headers, no narrative.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/detail.md`
  - Minimum grade: A (`read-setting.sh --skill detail --key minimum_grade --default A`).
  - You NEVER edit a task file -- you grade and list.
