ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against these):
    - .aid/works/work-013-review-stack-completion/PLAN.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/BLUEPRINT.md

  HUNT (scoped -- look for NEW findings only here):
    - PLAN.md § "Why two, and not one or three", the shared-files paragraph
    - deliveries/delivery-001/BLUEPRINT.md § Dependencies

  Derivation: the two ledger rows name those two files, so VERIFY is both in full. The FIX
  touched exactly the two regions listed under HUNT; STATE.yml was not touched and carries no
  ledger row.

CYCLE 2 -- WHAT THE FIX CHANGED (verify both rows; do not re-litigate them):
  Row 1 [LOW] -- PLAN.md claimed feature-001 and feature-002 "share zero in-scope files", which
    is false and contradicted its own Risk 1. FIX: the paragraph now says the one shared file is
    `reviewer-dispatch.md`, edited by both in different sections, and that it is ORDERABLE rather
    than conflicting -- which is why the boundary goes between feature-002 and feature-003, where
    the tension is a contradiction (schema required unchanged vs edited) rather than an ordering.
    Decide Fixed or Recurred.
  Row 2 [MINOR] -- the BLUEPRINT's Dependencies said "-- (none)" while gate criterion 2 requires
    PR #185 closed. FIX: Dependencies now names it as an external prerequisite, an owner action
    rather than a task, with its measured state. Decide Fixed or Recurred.

  Read the existing ledger at .aid/.temp/review-pending/plan.md FIRST. Update those two rows'
  Status in place -- do not delete them, do not rewrite Severity or Description. Append any
  genuinely NEW finding in the HUNT regions as a new Pending row.

CONTEXT:
  delivery-001 of work-013 just written; no preceding deliveries. PLAN.md also carries a
  delivery-002 stanza, which is out of scope for this per-deliverable pass except where
  delivery-001's dependency declaration refers to it.

  The owner asked for ONE delivery "if possible". The plan proposes two, and PLAN.md records
  the reasoning: most of the argument that produced three FEATURES was tested against disk and
  found not to transfer to deliveries, leaving one argument (a single branch, gate and 3-cycle
  circuit breaker over all 23 criteria, against a demonstrated 6-cycle need). That reasoning is
  in scope: if it is wrong, or if the evidence behind it does not reproduce, say so.

  Nine of eleven Q&A entries in STATE.yml are Pending and five land inside this delivery. The
  plan deliberately does not answer them; it records which block /aid-detail. Recording is
  correct, answering would be a finding.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS
  observation and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade this deliverable for:
    - Dependencies satisfied: delivery-001 depends on nothing, so every input its features need
      must already exist or be an explicitly named owner action.
    - Standalone-functional: is delivery-001 usable and testable on its own, without delivery-002?
    - Gate criteria are concrete and independently testable, and each names what it discharges.
      A criterion that cannot fail, or that no command can decide, is a finding.
    - Coverage: every acceptance criterion in the two assigned feature SPECs is reachable by some
      gate criterion here, or is explicitly and correctly out of scope.
    - Consistency with the KB and with the feature SPECs; no contradiction between PLAN.md,
      BLUEPRINT.md and the SPECs.
    - Factual accuracy: RE-RUN the measured claims. PLAN.md and the BLUEPRINT cite counts, greps,
      file paths and git observations. A number that does not reproduce is a finding whose
      severity reflects what an executor would do wrong if they trusted it.
    - Artifact shape: BLUEPRINT.md against .cursor/aid/templates/delivery-blueprint-template.md
      (Objective, Scope + Out of scope, Gate Criteria ending in the section-6 line, Tasks nav
      table, Dependencies, Notes); STATE.yml against
      .cursor/aid/templates/delivery-state-template.yml, at delivery_state: Pending-Spec with a
      real `updated` timestamp, and no delivery rows written into the work STATE.yml (that view
      is DERIVED).

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Resolution is defined in
  .cursor/aid/templates/kb-authoring/review-rubric.md; the registry and criteria table live in
  .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell. An id resolving nowhere is
    itself a defect.
  - A `kind: exclude` criterion binds you: reporting it is a defect in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
    `UNDECIDED <path>` is normal. A missing, crashing or timed-out oracle DEGRADES that criterion
    to reading, and you record the degradation -- never as a pass, never as a violation.
  - Note: files under `.aid/works/**` resolve to NO row in the type registry. Where no declared
    criterion reaches a real defect, report it anyway and say so plainly in Evidence. Do not
    invent an id, and do not suppress the finding for want of one.

OUT OF SCOPE (do NOT grade against):
  - The delivery-002 stanza and feature-003 -- a later per-deliverable pass.
  - The feature SPECs themselves; all three are already gated at A+.
  - Q1-Q9 as questions: they are recorded, not resolved. Showing one is WRONG is valuable;
    re-raising one as a new finding is not.
  - The owner's settled decisions: the existing review stack is law; track order T1 -> T2 -> T3;
    migrate catalog checks into the cascade; default-delete abandoned scripts; and the choice of
    two deliveries over one, which the owner made after seeing the alternatives.
  - Task breakdown and sequencing -- /aid-detail has not run, and an empty Tasks table is correct.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, noting the routing destination
  in Description/Evidence. They do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/plan.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`. Read it first if it exists; append new
    findings as Status: Pending.
  - The ledger is the ENTIRE file: ONE markdown table, 7 columns, no headers, no narrative.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/plan.md`
  - Minimum grade: A
    (`read-setting.sh --skill plan --key minimum_grade --default A`).
  - You NEVER edit PLAN.md, the BLUEPRINT or any SPEC -- you grade and list.
