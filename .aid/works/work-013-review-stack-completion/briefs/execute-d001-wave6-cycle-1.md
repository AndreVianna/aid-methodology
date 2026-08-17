ARTIFACTS UNDER REVIEW:
  Five tasks in one wave. Cycle 1, so this is ONE unlabelled list.

    - scripts/checks/settings-schema-check.sh
    - .aid/knowledge/tech-debt.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-014/CORRECTION.md
    - tests/canonical/test-frontmatter-lint.sh
    - tests/canonical/test-kb-html-claims-check.sh
    - canonical/skills/aid-specify/references/state-review.md
    - canonical/skills/aid-specify/references/state-done.md
    - .aid/knowledge/artifact-schemas.md
    - .github/workflows/test.yml

  Which task owns what: task-011 the settings check; task-014 tech-debt.md and its CORRECTION;
  task-015 test-frontmatter-lint.sh and the workflow step name; task-017 the kb.html fixture
  suite; task-018 the two aid-specify references and the BLUEPRINT section of artifact-schemas.md.

  Also in the diff, NOT independently graded: the profiles/ render and the two root install trees,
  which are generator output and byte-copies of it.

CONTEXT:
  Wave 6 of delivery-001, work-013. Each task's ACs are in its own DETAIL.md under
  .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-NNN/. Read them.

  Three things to know.

  First, task-014 went beyond its stated scope and recorded why in CORRECTION.md. Its scope said
  "only the citation form changes -- do not reword the surrounding rows". Fixing the citations
  meant reading what they pointed at, and two rows had gone false: W5-12's documented exit code
  now matches the code, and W5-6's item (2) cited a template that was migrated to .yml and no
  longer ships the thing described. W5-12 was deleted and W5-6 item (2) removed, on the authority
  of tech-debt.md's own preamble ("Only currently-open debt is listed; resolved items are
  removed"). Judge that call. If deleting a debt row was wrong, or if either row is in fact still
  open, say so plainly -- this is the finding I would most like you to overturn if it is wrong.

  Second, task-015 and task-017 are both about the same failure shape: a check that examines
  nothing looking identical to a check that passed. Attack the guards, not the prose.

  Third, task-011 adds a script, so NFR-3 binds it: the header must cite a re-derivation that
  actually reproduces. Re-run every number in it.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in every DETAIL.md, verified by running its command.** Five tasks; do not sample.
    - **Truth of every measured number** in a header, a comment, a doc or a commit. Re-derive them.
    - task-014: is the citation lint genuinely clean, does every new anchor resolve by grep, and is
      every surviving claim in the rewritten W5-6 row still true? Check the deletion call.
    - task-015: mutation-test it. Point the suite's KB root at an all-skipped tree and confirm it
      now fails. If it still passes, the guard is decorative.
    - task-017: mutation-test the script and confirm the suite catches it. Try to find a defect the
      five fixtures would miss.
    - task-011: exercise every exit path, including the zero-key one. Try to make it pass a
      malformed file or fail a valid one.
    - task-018: does the new blueprint review actually hang together -- ledger scope, dispatch,
      grade call, cleanup -- or is it prose that names a path nothing creates? Is the Lite path
      genuinely untouched?
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Registry: .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - Shell scripts, test suites and workflow YAML resolve to no registry type. Where no declared
    criterion reaches a real defect, report it and say so in Evidence. Do not invent an id.
  - tech-debt.md IS a KB doc and the KB rules bind it: no work reference, durable anchors, and the
    citation lint must stay at 0.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 141; a 14th is a finding.
  - PR #185 being open.
  - Tasks 012, 019, 020, 021, 025 and all of delivery-002.
  - The generated render and root install trees as artifacts in their own right -- but DO check they
    are in step with canonical, since a stale render is a real defect.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave6.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave6.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
