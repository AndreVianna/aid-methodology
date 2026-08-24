ARTIFACTS UNDER REVIEW:
  One task, and it is the delivery's closing evidence. Cycle 1, so ONE unlabelled list.

    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/RECORD.md
    - .aid/works/work-013-review-stack-completion/REQUIREMENTS.md

  Only the FR-B6 row of REQUIREMENTS.md is in scope; task-025 corrected it and nothing else there.

  Readable to verify a claim, NOT graded: task-010's CORRECTION.md, grade.sh, grade-summary.sh,
  the brief corpus under briefs/, and review-cost.tsv.

CONTEXT:
  Wave 10 of delivery-001, work-013, and the last task in the delivery. task-025 is a TEST task
  whose product is evidence: all twelve gate criteria recorded, every count reproducing.

  This is the record the delivery gate will be read from, so a false line here is worse than a
  false line anywhere else in the work -- it is the thing a later reader trusts instead of
  re-deriving. Treat every claim as a claim.

  Three things to know.

  First, criterion 8 is recorded as RECORDED AS DECLINED, not MET. FR-B6 is a SHOULD the owner
  declined. Judge whether recording a decline as a distinct third label is right, or whether it
  softens a criterion that should read as unmet.

  Second, task-025 CORRECTED FR-B6's stated reasoning in REQUIREMENTS.md. That row argued from
  `grep -c 'GRADE="F"'` returning 0 that grade.sh cannot emit F. Verify for yourself that the grep
  is accurate AND the inference false, and that task-010 had already established this -- because
  the claim being made is that a requirement in this work contradicted a finding the same work had
  made. If that characterisation is overstated, say so.

  Third, AC-6 required every count to reproduce, and two did not. One was a deliberate historical
  capture; the other, `git rev-parse work-003`, FAILED outright in a fresh checkout. Judge whether
  the repair is right and whether the record is honest about having needed one.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every one of task-025's eight ACs, verified by running its command.**
    - **Every command in RECORD.md re-run.** Do not sample. A command that does not reproduce, or
      that only reproduces on a machine that happens to have a local branch, is a finding.
    - **Every criterion's label matches its evidence.** A section labelled MET whose evidence does
      not establish it is the worst defect available here.
    - **The base diff claim.** NFR-1 says do not change grade.sh's counting logic or the 7-column
      schema. The record claims the only difference from the base is a file-mode bit. Verify.
    - **The brief-shape claim** over all briefs, and that the cost-meter row named is the first
      dispatch after task-009 reached Done.
    - **The corrected FR-B6 numbers**: twelve dependents, and the two blockers as now stated.
    - Anything the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - REQUIREMENTS.md under `.aid/works/` now matches `G-14` and `G-15`'s membership test. Apply
    them: this is the first review in which those criteria reach a real artifact, and if they are
    unusable in practice that is a finding worth more than any single row here.
  - RECORD.md is NOT in that membership set (it is not one of the four named kinds), so G-14/G-15
    do not reach it. Say so rather than inventing an id.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - Whether FR-B6 should have been declined -- that was the owner's call.
  - Everything in REQUIREMENTS.md except the FR-B6 row.
  - All of delivery-002.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave10.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave10.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
