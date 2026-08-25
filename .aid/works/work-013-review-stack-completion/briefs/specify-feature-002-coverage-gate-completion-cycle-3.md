ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against these):
    - .aid/works/work-013-review-stack-completion/features/feature-002-coverage-gate-completion/SPEC.md

  HUNT (scoped -- look for NEW findings only here):
    - the same file, § FR-B6 severity mapping only -- the one region the cycle-2 FIX touched.

  Derivation: all eleven ledger rows name this one file, so VERIFY is the file in full. The
  cycle-2 FIX replaced exactly one block, the invented severity table in § FR-B6.

CYCLE 3 -- WHAT THE FIX CHANGED (verify rows 8-11; rows 1-7 are already Fixed):
  Rows 8-11 were all the same defect: the SPEC invented a severity table instead of citing the
  one that already exists at
  `canonical/skills/aid-summarize/references/state-validate.md` SS Translate Script Output to
  Schema Rows. FIX: the invented table is deleted and replaced by the declared mapping,
  reproduced verbatim with each check's real name from CHECK_NAMES in grade-summary.sh:227-243,
  plus an explicit note that D1/D2 carry no declared severity because both are trivially passed
  (Mermaid retired) and that allocating one is not this SPEC's to do. The error is recorded in
  the SPEC rather than silently deleted. Decide each of rows 8-11 Fixed or Recurred.

  Check specifically: COV [CRITICAL], L1/L2/H1/S2/NM [HIGH], A1-A5 and C1/C2 [MEDIUM], and that
  every check name now matches CHECK_NAMES. Confirm AUTO_POOL is the 15 ids at
  grade-summary.sh:201 and that the SPEC's claim about which are covered by the mapping is true.

  Read the existing ledger at .aid/.temp/review-pending/specify-feature-002.md FIRST. Update
  Status in place; do not delete rows or rewrite Severity/Description. Append any genuinely NEW
  finding in the HUNT region as a new Pending row.

CONTEXT:
  SPEC.md for feature-002-coverage-gate-completion in work-013-review-stack-completion.
  The technical specification was just written by aid-architect. This is the review pass
  before the feature is marked Ready.

  T2 Gaps — the six coverage gates plus the history-section rule (FR-B1..FR-B7). Q2, Q3, Q4, Q5 and Q6 are all Pending and all land on this feature; the SPEC must specify around them without answering them.

  Q1-Q11 are recorded in `.aid/works/work-013-review-stack-completion/STATE.yml`. Several are Pending and this SPEC deliberately does not resolve them. Do not report a
  deliberate non-resolution as a defect; do report it if the SPEC resolves one silently.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns (plan, detail,
  execute), flag it as an OOS observation and bound your review to the artifact listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade the technical specification for:
    - Factual accuracy against disk. Every count, path, command and claim must be true on
      this working tree. Re-run the commands; a number that does not reproduce is a finding.
      This is the heaviest weight: the SPEC makes many measured claims.
    - Internal consistency: technical half against the requirements half above it; no
      section contradicting another.
    - Grounding in the KB and the actual review stack (cascade, 7-column ledger,
      VERIFY/HUNT, cost meter, one `/aid-review`, one `aid-reviewer`).
    - Implementability: could an executor follow this without inventing a decision? A step
      that says what to achieve but not how to decide it is a finding.
    - Every acceptance criterion in the SPEC's requirements half is reachable by something
      in the technical half.
    - No rival mechanism designed or reintroduced; no change to `grade.sh` counting logic
      or the 7-column schema; no hand-edit of generated trees.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then the artifact's document type, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. Resolution is
  defined in .cursor/aid/templates/kb-authoring/review-rubric.md; the type registry and the
  criteria table live in .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell. A finding citing an id
    that resolves nowhere is itself a defect.
  - A `kind: exclude` criterion binds you: reporting it is a defect in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout rather than re-reading
    it. `UNDECIDED <path>` is normal. A missing, crashing or timed-out oracle DEGRADES that
    criterion to reading, and you record the degradation -- never as a pass, never as a
    violation.
  - Note: `.aid/works/**/SPEC.md` resolves to NO row in the type registry, whose selectors
    cover `.aid/knowledge/`, `canonical/skills/`, `canonical/agents/` and
    `canonical/aid/templates/`. Where no declared criterion reaches a real defect, still
    report it and say plainly in Evidence that no criterion declares it. Do not invent an
    id, and do not suppress the finding for want of one.

OUT OF SCOPE (do NOT grade against):
  - The other two features' SPEC files, and REQUIREMENTS.md itself -- readable to verify a
    claim, not gradeable here.
  - Q1-Q9, already recorded. Re-raising one as new is a defect in the review; showing one
    is WRONG is valuable.
  - The owner's settled decisions: the existing review stack is law; track order
    T1 -> T2 -> T3; migrate catalog checks into the cascade; default-delete abandoned
    scripts.
  - Whether three features was the right decomposition -- settled at the /aid-define gate.
  - Task breakdown and sequencing (aid-detail and aid-plan have not run).

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table. They do NOT count toward
  severity totals and do NOT affect the grade. Note the routing destination in
  Description/Evidence.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/specify-feature-002.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`. Read it first if it exists; for each
    existing row verify on disk and update Status (Pending->Fixed if resolved,
    Fixed->Recurred if regressed). Append new findings with Status: Pending.
  - The ledger is the ENTIRE file: ONE markdown table, 7 columns, no headers, no narrative.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/specify-feature-002.md`
  - Minimum grade: A (`read-setting.sh --skill specify --key minimum_grade --default A`).
  - You NEVER edit the SPEC -- you grade and list.
