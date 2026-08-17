ARTIFACTS UNDER REVIEW:
  VERIFY (full -- re-check every existing ledger row against this):
    - canonical/aid/scripts/kb/kb-citation-lint.sh
    - tests/canonical/test-kb-citation-lint.sh
    - .github/workflows/test.yml

  HUNT (scoped -- NEW findings only here):
    - the -L change and the zero-file exit-2 path
    - the new CL11 and CL12 cases
    - the reworded workflow and script comments

CYCLE 2 -- WHAT THE FIX CHANGED (verify these three; do not re-litigate them):
  Row 3 [MEDIUM] symlinked root gave a silent false clean. FIX, in two parts. `find` now takes
    `-L`, so a symlinked root is followed. AND, as a class, opening ZERO files is now exit 2
    rather than a clean bill -- every route to zero is a mistake (mistyped root, docs nested
    below --depth, symlink not followed), and 'clean' versus 'looked nowhere' are otherwise the
    same exit code. Exit 2 not 1, because the caller pointed it somewhere wrong.

    Attack the class fix specifically. Is exit 2 right, or does it break a legitimate caller --
    the new CI loop over .aid/works/*/, a genuinely empty KB, a first run before any doc exists?
    The CI step carries `|| true`, but check whether anything else calls this script and would
    now break. Then confirm the KB invocation is STILL untouched: 23 opened, exit 0, stdout
    byte-identical.

  Rows 1+2 [MINOR] the comments said 3 of 106; the tree holds 107. FIX: the comments now
    describe the ratio and quote no count, on the grounds that the figure moves with every task
    and a stale number is worse than none. Check no stale count survives anywhere, and judge
    whether dropping the number loses something worth keeping.

  Read the existing ledger at .aid/.temp/review-pending/execute-d001-wave7.md FIRST. Update the
  three rows' Status in place. Append any genuinely NEW finding in the HUNT region as a Pending
  row. task-012 was verified clean in cycle 1; re-check only where this fix could disturb it.

CONTEXT:
  Wave 7 of delivery-001, work-013. Each task's ACs are in its DETAIL.md under
  .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-NNN/.

  Two things to know.

  First, task-019's central claim is a measurement, not a behaviour: run over a work root at
  the DEFAULT depth the lint opens 3 files out of 106 and returns exit 0, and that verdict is
  byte-identical to a genuinely clean run. The whole point of the change is that the OPENED
  COUNT, not the verdict, is what distinguishes them. Its AC says so explicitly. So verify the
  counts, and check that the tests assert counts rather than verdicts.

  Second, the new work-artifact CI step is deliberately NON-BLOCKING and WILL report ~63
  violations today. That is not an oversight. The work-artifact corpus is not bounded yet --
  that is task-020, which is out of scope here -- and gating before bounding would either block
  honest reviewer ledgers (whose Evidence cells cite file:line legitimately) or require
  exempting so much that the gate means nothing. Judge whether non-blocking is the right call
  and whether the step's comment justifies it honestly. If you think it should gate now, argue it.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS
  observation and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in both DETAIL.md files, verified by running its command.**
    - **Truth of every measured number** in a comment, a doc or the commit. Re-derive them:
      3 vs 106 opened, 63 violations, 23 opened for the KB, and the mutation counts.
    - task-012: mutation-test the SCRIPT and confirm the suite catches each break. Try to find a
      defect in settings-schema-check.sh that the eleven fixtures would miss.
    - task-019: the default MUST still be depth 1 -- a change there silently rescopes every
      existing caller. Confirm the KB invocation opens the same files, returns the same verdict,
      and that its STDOUT is unchanged. Then attack the new option: a depth that is negative,
      zero, huge, non-numeric, or given twice; a root that is a symlink; a root with no .md at all.
    - task-019 AC-4: a ledger `Line` cell must not be flagged, and a bare citation in prose must
      still be. Test both, and try to find a third shape that is mis-classified either way.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Registry:
  .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a
    defect in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - Shell scripts, test suites and workflow YAML resolve to no registry type. Where no declared
    criterion reaches a real defect, report it and say so in Evidence. Do not invent an id.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142; a 14th is a finding.
  - The ~63 work-artifact citation violations themselves, and whether they should be fixed.
    That corpus question is task-020's.
  - PR #185 being open.
  - Tasks 020, 021, 025 and all of delivery-002.
  - The generated render and root install trees as artifacts in their own right -- but DO check
    they are in step with canonical.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They
  do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave7.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave7.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
