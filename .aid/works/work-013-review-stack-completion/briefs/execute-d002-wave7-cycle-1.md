ARTIFACTS UNDER REVIEW:
  One task, closing the delivery and the work. Cycle 1, so ONE unlabelled list.

    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/RECORD.md

  Readable to verify a claim, NOT graded: every file a recorded command names, the delivery
  BLUEPRINT's ten gate criteria, and task-026's recorded baselines.

CONTEXT:
  Wave 7 of delivery-002, work-013 -- the last task of the last delivery. This record is what the
  delivery gate is read from, and after it there is no later task to catch a false line.

  Three things to attack.

  First, criterion 1 is a measurement that CORRECTED ITSELF mid-task, and the correction is the
  substance of the criterion. Run unmasked, the screen said 5 of 6 post-contract rows failed the
  why-line contract. Masked correctly it says 5 of 6 comply and 1 is malformed. **Re-derive both
  numbers yourself.** If the masked figure is wrong, the delivery is claiming compliance it does
  not have; if the unmasked one was actually right, a real finding was talked away.

  Second, NFR-1 is the delivery's sharpest constraint and criterion 8 claims it held absolutely --
  an EMPTY diff on grade.sh in a delivery whose purpose was editing the schema beside it. Verify.

  Third, criterion 9 claims every count carries its command and reproduces. The record now splits
  into a HISTORICAL baselines section, whose figures deliberately no longer reproduce because the
  delivery moved them, and a current gate-criteria section where all nine do. **Judge that split.**
  It is either an honest distinction or a place to hide a stale number, and the difference is
  whether each historical figure is genuinely one the delivery was supposed to change.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifact listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in task-048's DETAIL.md, verified by running its command.**
    - **Every command in the gate-criteria section re-run.** Do not sample. A false line here is
      worse than anywhere else in the work: it is what a later reader trusts instead of re-deriving.
    - **Every criterion's label matches its own evidence.** Ten sections, all MET. A section
      labelled MET whose evidence does not establish it is the most serious defect available.
    - **The malformed row.** Criterion 1 reports one ledger row with an unescaped pipe and records
      it rather than repairing it. Judge whether recording is right, and whether "the content may
      well carry a why-line" is an honest hedge or an evasion.
    - Anything the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - **Apply the why-line and provenance-token contract to your own ledger, and ESCAPE ANY PIPE
    inside a cell.** Criterion 1 is about exactly this failure; a malformed row in the ledger that
    reviews it would be its own counter-example.
  - A task acceptance criterion is cited as `task-NNN AC-N`, counting TOP-LEVEL checkboxes.
  - RECORD.md is a work artifact outside G-14/G-15's four named kinds, so those do not reach it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 145.
  - Q10 and Q11, both open and both the owner's.
  - task-039's cancellation -- upheld at the wave-5 gate.
  - All of delivery-001.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave7.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave7.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
