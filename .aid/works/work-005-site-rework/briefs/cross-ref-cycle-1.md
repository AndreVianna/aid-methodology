ARTIFACTS UNDER REVIEW:
  .aid/works/work-005-site-rework/REQUIREMENTS.md
  (includes § 11 Features: six `### Feature NNN` sections)

CONTEXT:
REQUIREMENTS.md was just approved and 6 features were decomposed from §5 Functional Requirements. This is the cross-reference pass that validates requirements + feature boundaries against the KB and codebase before any feature reaches /aid-specify.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity -> grade table)
Grade REQUIREMENTS.md + feature decomposition for:
- Internal consistency (objective <-> functional requirements <-> acceptance criteria)
- Consistency with the KB (architecture, technology-stack, test-landscape, project-structure)
- Codebase reality: claims about `site/` (generators, ~50 test files, 37 skills in canonical/skills, docs/ source, fetch-release-data, docs.yml) must be true; check with Grep/Glob/Bash (read-only)
- Feature decomposition completeness: every §5 FR maps to >=1 feature; every §9 AC is owned by exactly one feature
- Feature boundary clarity (no mixing, no overlap)
- Gaps that warrant Q&A back to the user (record as Pending Q&A, not findings)

Cycle 1 also runs the cross-document contradiction pass (Guard 2): see .aid/runtime/templates/reviewer-dispatch.md, section "The cross-document contradiction pass (Guard 2)".

DECLARED REVIEW CRITERIA: resolve per .aid/runtime/templates/kb-authoring/review-rubric.md (section "Resolving review criteria") and .aid/knowledge/authoring-conventions.md. A work artifact under .aid/works/ resolves to NO document type; that is not a finding. Cite the criterion id as a prefix in the Description cell when one applies. If a criterion has an `oracle:`, run it (60 s timeout, from repo root); a broken oracle degrades to reading and you record that.

OUT OF SCOPE (do NOT grade against):
- `#### Technical Specification` placeholders (/aid-specify has not run)
- PLAN.md sequencing, task breakdown
- KB document accuracy (log as OOS observations)
- Interview process quality
Log OOS findings as Status: OOS rows in the same ledger; they do not count toward the grade.

DELIVERABLES:
- Ledger: append rows (Status: Pending) to `.aid/.temp/review-pending/interview-work-005-cross-ref.md`. Read it first if it exists. ONE table, 7 columns, no narrative, per .aid/runtime/templates/reviewer-ledger-schema.md. Severity-tagged and source-tagged (REQUIREMENTS | FEATURE | KB).
- After writing, run: `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/interview-work-005-cross-ref.md` and put the grade in your return message.
- Pending Q&A for the user: do NOT edit STATE.yml; list them in your return message as short questions with impact; the orchestrator writes them.
- NEVER edit REQUIREMENTS.md. Grade and list only.
- Minimum grade: A (`bash .aid/runtime/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`).
