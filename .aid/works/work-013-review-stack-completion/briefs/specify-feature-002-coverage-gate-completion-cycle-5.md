ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against this):
    - .aid/works/work-013-review-stack-completion/features/feature-002-coverage-gate-completion/SPEC.md

  HUNT (scoped -- look for NEW findings only here):
    - the same file, the single table row for `S2` in the § FR-B6 severity mapping -- the
      region the cycle-4 FIX touched (grouped rows split into one row per check id).

  Derivation: all twelve ledger rows name this one file, so VERIFY is the file in full. The
  FIX is a one-cell edit; nothing else changed.

CYCLE 5 -- WHAT THE FIX CHANGED (verify rows 13-14; rows 1-12 are already Fixed):
  Rows 13-14 [MINOR] -- two sibling cells were not verbatim: A4/A5 were lower-cased inside a
    grouped cell, and C1/C2 were collapsed into one invented combined name. FIX: the grouped
    rows are SPLIT so every row now carries exactly one check id with its verbatim CHECK_NAMES
    value. This closes the class rather than the two reported instances. Decide each Fixed or
    Recurred, and check the whole table for any remaining non-verbatim or grouped cell.

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
