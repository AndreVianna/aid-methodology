ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against this):
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/RECORD.md

  HUNT (scoped -- look for NEW findings only here):
    - the three regions the fix touched: the pasted `gh pr view` line, criterion 2's summary label,
      and the three-spelling grep block that now carries its producing command.

CYCLE 2 -- WHAT THE FIX CHANGED (verify the three rows; do not re-litigate them):
  Row 1 [MINOR] -- the pasted PR line said "work-013: rebuild the review subsystem" where the real
    title says "work-003". FIX: the line is now the literal output of the command, captured by
    running it rather than retyped. Re-run `gh pr view 185 --json state,title --jq '.state + " -- " + .title'`
    and compare character for character.
  Row 2 [MINOR] -- criterion 2 opened with "PARTLY MET", softer than criterion 1's "MET." FIX: it
    now opens "**UNMET.**" and says explicitly that it fails the gate, and why a skimmed summary
    label must not soften the body.
  Row 3 [MINOR] -- the three-spelling count table had no producing command, against the record's own
    standard. FIX: the loop that produces it is now printed above the table. Run it and confirm it
    yields exactly the table's numbers.

  Read the existing ledger at .aid/.temp/review-pending/execute-d001-wave4.md FIRST. Update the
  three rows' Status in place -- do not delete them, do not rewrite Severity or Description. Append
  any genuinely NEW finding in the HUNT region as a new Pending row.

CONTEXT:
  Wave 4 of delivery-001, work-013 — a single task. task-009 is the recorded closing audit that
  shuts the T1 boundary: every one of the 16 feature-002 tasks depends on it, which is how AC-2's
  "a real dispatch after T1" is enforced by the execution graph rather than by a gate.

  It runs commands and records their output; it changes no code. Its whole value is whether the
  recorded evidence is TRUE and REPRODUCIBLE, so treat every pasted command as a claim to re-run.

  task-009 reports gate criterion 2 as UNMET because pull request #185 is still open, and states
  that closing it is an owner action no task performs. Recording an unmet criterion honestly is the
  correct outcome, not a defect — but verify the state is what it says.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifact listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade the recorded evidence for:
    - **Reproducibility.** Re-run every command pasted into the two sections. Output that does not
      reproduce is a finding, and its severity is what an executor would get wrong by trusting it.
    - **Honesty about the unmet half.** Criterion 2 must be recorded as unmet, with the owner action
      named, and must not be dressed up as partially satisfied in a way a gate would read as passing.
    - **Completeness.** Both criteria's required evidence is present — the audit and its exit code,
      the two globs, the zero-greps, the three-spelling greps, the cascade-loader grep, the PR state,
      and that the migration source still resolves.
    - **The reasoning attached to the evidence is sound** — particularly the claim that the globs are
      a regression check rather than the test, and the single-spelling grep warning.
    - No claim in the record that a later task or the gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. The registry and criteria table live in
  .aid/knowledge/authoring-conventions.md — note it now carries 37 criteria after wave 3.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - Files under `.aid/works/**` resolve to no registry type. Where no declared criterion reaches a
    real defect, report it and say so in Evidence. Do not invent an id.

OUT OF SCOPE (do NOT grade against):
  - The audit script and its suite — gated in waves 2 and 3.
  - The fact that PR #185 is open. That is the owner's action; grading it as this task's failure
    would be wrong. What IS in scope is whether task-009 recorded it accurately.
  - The other 21 tasks of delivery-001 and all of delivery-002.
  - The 13 pre-existing suite failures.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave4.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave4.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
