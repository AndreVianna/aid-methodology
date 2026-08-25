ARTIFACTS UNDER REVIEW:
  VERIFY (full -- re-check every existing ledger row against this):
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/RECORD.md

  HUNT (scoped -- NEW findings only here):
    - the rewritten why-line screen block
    - the new cost-meter double-count baseline section

CYCLE 2 -- ONE ROW (do not re-litigate what you passed):
  Row 1 [MEDIUM] -- the why-line block was a python heredoc of pseudocode with an elided '...' in
    the path, and did not run. FIX: replaced with a single-line awk that produces the same
    rows=5 why-line=2 and can be pasted verbatim. Paste it and run it. Confirm the count is right
    by an INDEPENDENT method too -- read the five rows of that ledger yourself and decide which
    carry a why-line, because an awk regex agreeing with itself proves only that it ran.

    The record now also says, in that section, why the one-liner form was chosen. Judge whether
    that admission is accurate.

  Also added, from your OOS row 2: the cost-meter double count is now pinned as a baseline for
  gate criterion 5, with the two review-cost.tsv rows and the arithmetic (84934 = 2 x 42467,
  against a cycle-1 surface of 42034, so it is one path double-counted rather than a re-read).
  This is beyond task-026's listed scope. Judge whether adding it was right, and whether the
  arithmetic and the inference from it are correct -- if the doubling has some other explanation,
  say so, because task-045 and task-047 will build on this reading.

  Re-run EVERY command in the record. I get ten reproducing plus the deliberately historical base
  commit. Confirm independently.

  Read the existing ledger at .aid/.temp/review-pending/execute-d002-wave1.md FIRST. Update row 1
  in place. Append any genuinely NEW finding in the HUNT region as a Pending row.

CONTEXT:
  Wave 1 of delivery-002, work-013. task-026 is CONFIGURE: it records this delivery's own base
  commit and re-measures every baseline the ten gate criteria will be graded against.

  It produces no code. Its entire value is whether the recorded numbers are TRUE and REPRODUCIBLE
  at this commit, so treat every pasted command as a claim and re-run it.

  Three things to know.

  First, the acceptance criteria FORBID copying a baseline from the SPEC -- the SPEC's own why-line
  figure had already moved between approval and execution. So check not just that each number is
  right, but that it was plausibly measured rather than transcribed. If any figure matches a stale
  SPEC value rather than the current tree, that is the defect the AC was written for.

  Second, this delivery has its OWN base, distinct from delivery-001's. Confirm the recorded SHA is
  actually HEAD at the time this task committed, and that it is a literal SHA rather than a branch
  name -- delivery-001 recorded a branch and the command later failed in a fresh checkout.

  Third, AC-4 says this task edits nothing under canonical/. Verify against its commit, not against
  the working tree.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifact listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every one of task-026's five ACs, verified by running its command.**
    - **Reproducibility.** Re-run every command in the record. A number that does not reproduce is
      a finding whose severity is what a later task would get wrong by trusting it.
    - **Completeness against the scope.** The scope names four things: the base, the recorded-output
      section, the why-line screen, and the suite/selector/literal-path baselines. A baseline the
      later criteria will need but which is absent is a finding now, not at the gate.
    - **Whether the fingerprinting actually serves NFR-1.** The record md5s grade.sh and the ledger
      schema, and says grade.sh must still hash the same at the gate while the schema must not.
      Judge whether that is the right pair of claims.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter. Registry and criteria table:
  .aid/knowledge/authoring-conventions.md.
  - RECORD.md is a work artifact but is NOT one of G-14/G-15's four named kinds, so those do not
    reach it. Say so rather than inventing an id.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - The why-line gap itself (rows=5 why-line=2). Closing it is feature-003's job, not this task's.
  - All 22 remaining delivery-002 tasks, and all of delivery-001.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave1.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave1.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
