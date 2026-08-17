ARTIFACTS UNDER REVIEW:
  - .aid/works/work-013-review-stack-completion/PLAN.md
      (the delivery-002 stanza only -- the rest of PLAN.md was graded A+ at the
       delivery-001 pass and is readable here, not gradeable)
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/BLUEPRINT.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-002/STATE.yml

  Readable to verify a claim, NOT graded here: the feature SPEC delivery-002 assigns
  (feature-003-severity-and-recall-measurement), the delivery-001 BLUEPRINT, and REQUIREMENTS.md.

  Cycle 1, so this is ONE unlabelled list.

CONTEXT:
  delivery-002 of work-013 just written; preceding delivery: delivery-001 (The Single, Watched
  Stack), already graded A+ at its own per-deliverable pass. delivery-002 is the terminal
  delivery.

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
    - Dependencies satisfied: delivery-002 depends on delivery-001, so every input feature-003
      needs must be produced by delivery-001 or already exist. The dependency is claimed to be
      HARD rather than ordering -- test that claim.
    - Standalone-functional: is delivery-002 usable and testable on its own, without delivery-002?
    - Gate criteria are concrete and independently testable, and each names what it discharges.
      A criterion that cannot fail, or that no command can decide, is a finding.
    - Coverage: every acceptance criterion in feature-003's SPEC is reachable by some gate
      criterion here, or is explicitly and correctly out of scope. feature-003 has NINE.
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
  - delivery-001, its BLUEPRINT and its two features -- already graded at their own passes.
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
