ARTIFACTS UNDER REVIEW:
  Seven tasks in one wave. Cycle 1, so this is ONE unlabelled list.

    - tests/review-cost-meter.sh
    - tests/review-recall.sh
    - tests/canonical/test-severity-why-line.sh
    - tests/canonical/test-scoped-review-cycles.sh
    - canonical/aid/templates/kb-authoring/frontmatter-schema.md
    - canonical/skills/aid-discover/references/state-fix.md
    - canonical/skills/aid-update-kb/references/state-review.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-030/NFR1-VERIFICATION.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-033/CLASSIFICATION.md
    - tests/canonical/fixtures/recall-corpus/CATALOGUE.md

  Which task owns what: 046 the cost meter; 038 review-recall.sh and the catalogue's new scope
  column; 029 the why-line suite; 042 the SW01-SW04 block in test-scoped-review-cycles.sh; 043 the
  frontmatter schema; 033 the two skill references and CLASSIFICATION.md; 030 NFR1-VERIFICATION.md.

  The two aid-discover/aid-update-kb state-done.md files took the same mechanical edit as
  state-fix.md; spot-check rather than reading both.

CONTEXT:
  Wave 4 of delivery-002, work-013 -- the widest wave of the delivery.

  Three things deserve the most hostility.

  First, task-030's NFR1-VERIFICATION.md is a claim that NOTHING BROKE. That is the easiest kind of
  document to write and the hardest to trust. Re-run every check in it. Its central claim is that
  `git diff <base> HEAD -- canonical/aid/scripts/grade.sh` is EMPTY.

  Second, task-046 changed a MEASUREMENT TOOL, which means every figure this work has recorded
  through it is now potentially two definitions mixed. The forward-only rule is recorded in the
  .meta sidecar. Judge whether that is sufficient or whether older rows are now silently
  misleading -- this is the one change in the wave that can corrupt evidence retroactively.

  Third, task-038 SHIPPED a script, so NFR-3 binds: its header must cite a re-derivation that
  reproduces, and the floor task-036 agreed in advance must actually be cleared. If the floor is not
  met the correct outcome was to ship nothing and record the discharge -- check which happened and
  whether it was the right call.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in all seven DETAIL.md files, verified by running its command.** Do not sample.
    - **NFR-1**: grade.sh md5 against 0d87371d1bdbf165fa386f8c5b7286e5, and the column shape.
    - **Truth of every measured number.** Re-derive them, especially the before/after pairs
      task-046 and task-030 quote.
    - **Mutation-test the two suites.** Break what each protects and confirm it goes red. A suite
      that cannot fail is the failure mode this whole delivery is about.
    - task-042: the residue-of-one step is the load-bearing one. Confirm a sweep that finds nothing
      cannot pass as a sweep that ran.
    - task-033: it claims classifying before touching found a passage that the conversion would
      have falsified. Verify that passage was really falsified and is really fixed.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - **Apply the why-line and provenance-token contract to your own ledger.** It is now in force.
  - A task acceptance criterion is cited as `task-NNN AC-N`, resolved by counting the TOP-LEVEL
    checkboxes under `**Acceptance Criteria:**` in that task's DETAIL.md.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 143.
  - Retiring update-kb's duplicated FIX loop -- task-033 names it as a follow-up on purpose.
  - Whether Q10's recall-regression route should be tech debt or a criterion -- owner's call.
  - The remaining 7 delivery-002 tasks, and all of delivery-001.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave4.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave4.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
