ARTIFACTS UNDER REVIEW:
  One task. Cycle 1, so ONE unlabelled list.

    - tests/canonical/test-ledger-isolation.sh
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-035/ATTEMPTS.md

  Readable to verify a claim, NOT graded: reviewer-dispatch.md's preflight, the two state-fix.md
  files, .github/workflows/test.yml, and .gitignore.

CONTEXT:
  Wave 6 of delivery-002, work-013. task-035 is the proof that a new review cycle cannot reach the
  previous cycle's ledger -- the requirement FR-C2 exists for, and the one whose original form was
  defeated the first time it was tested because it was a request rather than a constraint.

  Two things to attack.

  First, the honesty of the claim. The record says plainly that the design closes the NAMING, not
  the filesystem, and that the structural claim rests on the CI hygiene step rather than on
  .gitignore. Judge whether that is accurate or whether it either overclaims or hides behind a
  disclaimer. If the isolation is weaker than stated, say so; if it is STRONGER than stated and the
  record undersells it, say that too.

  Second, whether the three attempts are worth anything. Attempts 1 and 2 are greps -- they assert
  that no instruction NAMES a prior ledger. That is a real property but it is nominal. Attempt 3 is
  the structural one. Judge whether attempts 1 and 2 earn their place or are theatre, and whether
  attempt 3 actually demonstrates what it claims.

  Its AC requires the attempts to target a path a PRIOR CYCLE ACTUALLY USED. Verify that
  execute-d002-wave1.md is such a path and not a convenient fiction.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in task-035's DETAIL.md, verified by running its command.**
    - **Mutation-test it.** Remove the preflight and confirm LI03 goes red. A suite that cannot
      fail is the failure this delivery exists to close.
    - **The source tree must be untouched** -- LI04 asserts it; verify independently.
    - **Every command in ATTEMPTS.md re-run.** Its exit codes are the evidence.
    - Anything task-048 or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - **Apply the why-line and provenance-token contract to your own ledger.**
  - A task acceptance criterion is cited as `task-NNN AC-N`, counting TOP-LEVEL checkboxes.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 145.
  - Whether the filesystem SHOULD be sandboxed -- that is a design question beyond this work.
  - task-048, and all of delivery-001.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave6.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave6.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
