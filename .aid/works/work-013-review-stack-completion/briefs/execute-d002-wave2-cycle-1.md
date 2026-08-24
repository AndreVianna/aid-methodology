ARTIFACTS UNDER REVIEW:
  Four tasks in one wave. Cycle 1, so this is ONE unlabelled list.

    - tests/canonical/test-criterion-oracles.sh
    - tests/canonical/test-scoped-review-cycles.sh
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-027/SWEEP.md
    - canonical/aid/templates/reviewer-dispatch.md
    - canonical/skills/aid-execute/references/state-fix.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-036/RESEARCH.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/STATE.yml

  Which task owns what: task-027 the two suites and SWEEP.md; task-031 reviewer-dispatch.md;
  task-041 state-fix.md; task-036 RESEARCH.md and the Q10 entry in STATE.yml.

  Also in the diff, NOT independently graded: the profiles/ render and the two root install trees.

CONTEXT:
  Wave 2 of delivery-002, work-013. Each task's ACs are in its own DETAIL.md under
  .aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-NNN/.

  Four things to attack, in rough order of what would hurt most if wrong.

  First, task-027's RESIDUE. Its AC requires the remaining instances of the same class to be
  recorded as a NON-ZERO residue with their route -- the class reported, not quietly narrowed to
  whatever got fixed. The sweep found three raw hits and classified two as false positives on the
  grounds that they are fixture paths written into temp roots rather than real dependencies.
  **Check that classification yourself.** If either "false positive" is actually a real
  dependency, the residue is understated and the sweep did the exact thing its AC forbids.

  Second, task-031's preflight must FAIL rather than warn on the cycle-1 case, and must be an
  ADDITION ahead of the metering step rather than a substitution for it. Confirm all three
  components of the dispatch mandate still resolve. Also judge the stated test for which literal
  paths were parameterised and which were deliberately kept -- "executed versus read". If that
  distinction is wrong, some path was changed or kept for a bad reason.

  Third, task-041 adds commit trailers. Its AC-3 says NOTHING is added to the per-task findings
  structure and the artifact schema must show no change. Verify by diff, not by reading the claim.

  Fourth, task-036 is RESEARCH and its central claim is that the re-derivation the script removes
  is WRONG by default, not merely tedious -- the naive row count and the status-aware count
  disagree on real ledgers. Re-derive that on ledgers of your own choosing, not only the three it
  picked. If they agree everywhere else, the claim is cherry-picked and the NFR-3 justification
  collapses.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in all four DETAIL.md files, verified by running its command.** Do not sample.
    - **Truth of every measured number** in a doc, a comment or the commit. Re-derive them.
    - task-027: run the selector before and after by checking out the prior commit if needed;
      confirm the control case and both suites' assertion counts.
    - task-036: the floor must be a number produced by a command, and "the script does not merge"
      must be recorded as admissible with its discharge wording. Judge whether the corpus size of
      20 is argued or merely asserted.
    - task-036: NO criterion id may be allocated. Verify the namespace is unchanged at 39, and that
      Q10 PARSES as YAML rather than merely appearing in a grep.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - SWEEP.md, RESEARCH.md and STATE.yml are work artifacts outside G-14/G-15's four named kinds,
    so those do not reach them. Say so rather than inventing an id.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - Whether Q10 should route to tech debt or a criterion -- that is the owner's call, and the task
    is required NOT to settle it.
  - The remaining 18 delivery-002 tasks, and all of delivery-001.
  - The generated render and root install trees as artifacts in their own right -- but DO check
    they are in step with canonical.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave2.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave2.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
