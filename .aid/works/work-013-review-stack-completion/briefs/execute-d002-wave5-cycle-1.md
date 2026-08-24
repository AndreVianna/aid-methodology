ARTIFACTS UNDER REVIEW:
  Five tasks in one wave, one of them cancelled. Cycle 1, so ONE unlabelled list.

    - tests/canonical/test-review-recall.sh
    - tests/canonical/test-review-cost-meter.sh
    - tests/canonical/test-criterion-oracles.sh
    - canonical/skills/aid-deploy/references/state-verifying.md
    - canonical/skills/aid-summarize/references/state-fix.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-034/CLASSIFICATION.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-039/STATE.yml

  The other six converted skill-reference files took the identical mechanical edit; spot-check one
  rather than reading all six.

  Which task owns what: 034 the conversions and CLASSIFICATION.md; 039 the cancellation; 040 the
  recall suite; 044 the OB01-OB04 block in test-criterion-oracles.sh; 047 the CM20-CM23 block in
  test-review-cost-meter.sh.

CONTEXT:
  Wave 5 of delivery-002, work-013. Each task's ACs are in its DETAIL.md.

  The thing to attack hardest is task-039, because it SHIPPED NOTHING.

  Its AC-1 says it ships only if task-036's measurement justifies it, and is otherwise closed as
  `Canceled` with that measurement quoted in its notes -- never left Pending, never silently
  dropped. I judged the justification absent and cancelled it. **Judge that call independently.**
  Read task-036's RESEARCH.md, the delivery BLUEPRINT's ten gate criteria, and Q10's status, and
  decide whether the evidence really is absent or whether I took an easy exit. A task cancelled
  when it should have shipped is a gap dressed as a decision, and it is exactly the kind of thing
  a gate exists to catch.

  Second: all three suites must be able to FAIL. A suite that cannot go red is the failure mode
  this whole delivery is about. Mutation-test each rather than reading its assertions.

  Third: task-034's canary claims zero literal ledger paths survive in the instruction surface,
  against 31 recorded in task-026. Two remain and are classified as documentation. Check that
  classification -- if either is actually executed, the canary is reporting zero while the defect
  survives.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in all five DETAIL.md files, including the two conditional ones.** task-039's and
      task-040's ACs both branch on whether a prior task shipped; verify the right branch was taken.
    - **Mutation-test all three suites.** Break what each protects; confirm red; restore.
    - **NFR-1**: grade.sh md5 against 0d87371d1bdbf165fa386f8c5b7286e5.
    - **No live data touched by any suite.** The cost-meter cases polluted the real measurement tsv
      with five rows on their first run and now pass --data; verify no suite writes outside a temp
      dir, and that the tsv carries no probe rows.
    - Anything task-048 or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - **Apply the why-line and provenance-token contract to your own ledger.**
  - A task acceptance criterion is cited as `task-NNN AC-N`, counting TOP-LEVEL checkboxes.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 144.
  - Whether Q10 or Q11 should be answered one way or another -- both are the owner's.
  - task-048, and all of delivery-001.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave5.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave5.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
