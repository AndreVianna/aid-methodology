ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against this):
    - .aid/works/work-013-review-stack-completion/features/feature-002-coverage-gate-completion/SPEC.md

  HUNT (scoped -- look for NEW findings only here):
    - the same file, the single table row for `S2` in the § FR-B6 severity mapping -- the
      only text the cycle-3 FIX touched (one cell, one parenthetical removed).

  Derivation: all twelve ledger rows name this one file, so VERIFY is the file in full. The
  FIX is a one-cell edit; nothing else changed.

CYCLE 4 -- WHAT THE FIX CHANGED (verify row 12; rows 1-11 are already Fixed):
  Row 12 [MINOR] -- the "Name in grade-summary.sh" cell for S2 read "Offline render
    (CDN-free assertion)" while CHECK_NAMES[S2] is "Offline render". FIX: the parenthetical
    is removed, so the cell now reproduces the script value exactly. Decide Fixed or Recurred.

  Read the existing ledger at .aid/.temp/review-pending/specify-feature-002.md FIRST. Update
  Status in place; do not delete rows or rewrite Severity/Description.

CONTEXT:
  SPEC.md for feature-002-coverage-gate-completion in work-013-review-stack-completion.
  This is the closing verification cycle. The gate already reads A; this cycle exists to
  close the last Pending row rather than ship a dirty ledger.

  Reviewer self-check: bound your review to the artifact listed. Downstream-phase concerns
  are OOS observations.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  For row 12, the only question is whether the cell now matches CHECK_NAMES[S2] in
  canonical/aid/scripts/summarize/grade-summary.sh exactly. Check the other names in the
  same table too, since a fix in one cell is the moment a sibling cell drifts unnoticed.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own frontmatter; most
  specific wins on an id collision. Note that `.aid/works/**/SPEC.md` resolves to no row in
  the type registry, so where no declared criterion reaches a real defect, report it and say
  so in Evidence rather than inventing an id.

OUT OF SCOPE (do NOT grade against):
  - The other two features' SPEC files and REQUIREMENTS.md -- readable to verify a claim.
  - Q1-Q11, already recorded.
  - The owner's settled decisions, and the three-feature decomposition.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger. They do not count toward the grade.

DELIVERABLES:
  - Update `.aid/.temp/review-pending/specify-feature-002.md` in place. ONE 7-column table,
    no narrative.
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/specify-feature-002.md`
  - Minimum grade: A. You never edit the SPEC.
