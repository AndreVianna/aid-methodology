ARTIFACTS UNDER REVIEW:
  - .aid/knowledge/authoring-conventions.md
  - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/RECORD.md
  - tests/canonical/test-review-path-audit.sh

  Readable to verify a claim, NOT graded: the task-006 and task-008 DETAIL.md files whose criteria
  these discharge, the three FINDINGS.md screens task-006 reconciled, `scripts/checks/review-path-audit.sh`
  (task-007's, already gated), and the KB.

  Cycle 1, so this is ONE unlabelled list.

CONTEXT:
  Wave 3 of delivery-001, work-013. Two tasks ran.

  task-006 reconciled the ~22 admits proposed independently by three concurrent screens — whose ids
  collided by construction — into one allocation, and wrote them into the criteria cascade. It
  reports 19 rows written after 3 merges, taking the namespace from 18 to 37.

  task-008 wrote the test suite for the four-layer audit script, reporting 16 assertions.

  One thing found during this wave that bears on how you measure: exported `AID_*` state-file
  overrides hijack the test suites' own path resolution. With three exported, `run-all.sh` reported
  17 of 140 failing; with `env -u` clearing them, 13 of 140. **Run the suite with
  `env -u AID_STATE_FILE -u AID_TASK_STATE_FILE -u AID_DELIVERY_STATE_FILE`** or your baseline
  comparison is meaningless. The hazard and the 13-of-140 baseline are recorded in RECORD.md.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade wave 3 for:
    - **The allocation is sound.** Every new criterion id is unique, sits in an existing scope
      prefix, and reuses NO catalog id — the catalog's `KB-01` and the current `KB-01` are different
      rules, so a reused number would make a ledger row cite something else. Re-derive the namespace
      and check for duplicates yourself.
    - **The merges are defensible.** Three pairs were merged as "the same check". Read both sides of
      each merge in the FINDINGS files and judge whether they really are one rule.
    - **The rows are usable as criteria.** Each has every column populated, a severity from the
      five-band scale, and a why naming a consequence. A row a reviewer could not act on is a finding.
    - **The ledger records what was allocated**, so a later reader can trace each id to the catalog
      row it replaces.
    - **The oracle discharge** — FR-A3's `oracle:` half — is either recorded as not-applicable with
      a reason, or routed. Silently dropping it is a finding.
    - **The suite actually tests the script.** Run it. Then confirm it is not vacuous: the four
      failure cases must genuinely fail, not merely be asserted to.
    - **No new suite failures.** Compare against the 13-of-140 baseline, measured clean.
    - Factual accuracy throughout: RE-RUN every count. A number that does not reproduce is a finding.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Resolution is defined in
  .cursor/aid/templates/kb-authoring/review-rubric.md; the registry and criteria table live in
  .aid/knowledge/authoring-conventions.md — which is itself under review here, so resolve against
  it as it now stands.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it. A
    missing or crashing oracle DEGRADES the criterion to reading, and you record that.
  - `tests/**` and files under `.aid/works/**` resolve to no registry type. Where no declared
    criterion reaches a real defect, report it and say so in Evidence. Do not invent an id.

OUT OF SCOPE (do NOT grade against):
  - `scripts/checks/review-path-audit.sh` itself — task-007's, gated at A+ in wave 2. Report a bug
    in it as an OOS row rather than as a finding against this wave.
  - The three FINDINGS screens — gated in wave 2. Their *reconciliation* is in scope; their
    screening outcomes are not.
  - The 20 remaining tasks of delivery-001 and all of delivery-002.
  - The 13 pre-existing suite failures.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, noting the routing destination.
  They do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave3.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave3.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
