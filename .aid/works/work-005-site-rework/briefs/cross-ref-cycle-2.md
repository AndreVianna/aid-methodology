ARTIFACTS UNDER REVIEW:

  VERIFY (full) - re-check EVERY existing ledger row against these:
  .aid/works/work-005-site-rework/REQUIREMENTS.md

  HUNT (scoped) - look for NEW findings ONLY in what the fix changed:
  .aid/works/work-005-site-rework/REQUIREMENTS.md

CONTEXT:
Cycle 1 graded D+ (13 rows). The requirements author fixed the findings in REQUIREMENTS.md: FR-2 (`--check` flag), FR-8 (four groups, group d = accessibility rules plus structure assertions), FR-9, FR-10 (all KB statements about the site), new FR-12 (content sources, no network), NFR-3, NFR-4, NFR-5, section 4 In Scope, section 8, AC-2, AC-4, AC-5, AC-13, AC-14, new AC-15, and Features 002, 004, 005, 006 plus the build-order note. This is cycle 2: mark each existing row Fixed or Recurred, then hunt for new issues only in the changed text. Re-check that every FR maps to >=1 feature and every AC (AC-1..AC-15) is owned by exactly one feature.

RUBRIC: .aid/runtime/templates/grading-rubric.md. Same criteria and OUT OF SCOPE list as `.aid/works/work-005-site-rework/briefs/cross-ref-cycle-1.md`; read that file for them.

DELIVERABLES:
- Update the existing ledger `.aid/.temp/review-pending/interview-work-005-cross-ref.md` per `.aid/runtime/templates/reviewer-ledger-schema.md` (one table, 7 columns, no narrative). Then run `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/interview-work-005-cross-ref.md` and return the grade, counts by severity and any new user questions.
- Do NOT edit REQUIREMENTS.md or STATE.yml.
