ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against these):
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-003/FINDINGS.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-005/FINDINGS.md

  HUNT (scoped -- look for NEW findings only here):
    - the same two files: task-003's proposal table and its new correction section, and
      task-005's AID rows, its DEF-07 row, its outcome tally and its new correction section.

  Derivation: all three ledger rows name those two files, so VERIFY is both in full. `git diff`
  over the fix shows only those two changed; nothing else in wave 2 was touched.

CYCLE 2 -- WHAT THE FIX CHANGED (verify the three rows; do not re-litigate them):
  Row 1 [MEDIUM] -- task-003's proposal table priced KB-09 and KB-10 as `Step 2`, the catalog's
    deferral placeholder, not a severity. FIX: KB-09 is HIGH and KB-10 is MEDIUM, each with the
    consequence named in a correction section. The two remaining "Step 2" strings are inside the
    EVIDENCE column, citing the catalog's own two-step mechanism -- those are citations, not
    severities, and were deliberately kept. Confirm that distinction rather than counting matches.
  Row 2 [MEDIUM] -- task-005 used "covered by the agent body", a fifth outcome outside the declared
    set. FIX: AID-01..04 are now `admit` (file-placement properties, enforced in the agent body but
    not citable, so admitting them is what creates an id) and AID-05..06 are `rubric-owned` (they
    check an algorithm, not a file property). One surviving occurrence of the phrase is in the
    correction section, quoting the retired wording.
  Row 3 [MEDIUM] -- task-005 marked DEF-07 out of scope while its own Attachable cell conceded `*`
    works. FIX: DEF-07 is `rubric-owned` -- the objection is redundancy with G-01/G-02, not
    attachability -- and the Attachable cell now reads "Yes, at `*`".

  ONE THING THE CYCLE-1 REVIEW MISSED, found while fixing, and worth your check: task-005's outcome
  tally summed to 28 against a 29-row corpus. It had no `admit` line at all, so DEF-06 -- the single
  row that screen admits, and the document's own headline finding -- was counted nowhere. The tally
  is now 5 + 0 + 3 + 21 = 29 and matches the per-row outcomes. Verify by deriving the counts from
  the rows yourself rather than reading the tally.

  Read the existing ledger at .aid/.temp/review-pending/execute-d001-wave2.md FIRST. Update the
  three rows' Status in place -- do not delete them, do not rewrite Severity or Description. Append
  any genuinely NEW finding in the HUNT region as a new Pending row.

CONTEXT:
  Wave 2 of delivery-001, work-013. Five tasks ran: task-002 (remove rubric-catalog framing from
  the dispatch protocol and fix a dead reference in the reviewer agent), task-003/004/005 (screen
  the 85 rule rows of the abandoned catalog, from git history, into admit / covered / rubric-owned
  / needs-a-new-type), and task-007 (write the four-layer single-path audit script).

  The three screening tasks ran CONCURRENTLY and proposed ids from the SAME namespace without
  seeing each other. Their proposals therefore collide by construction -- that is expected, and
  reconciling them is task-006's job in wave 3, not a defect here. What IS a defect is a screening
  outcome that is wrong on the evidence.

  Generated trees were re-rendered and the two dogfood trees resynced after task-002.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS
  observation and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade wave 2 for:
    - Acceptance-criteria satisfaction: each of the five tasks' criteria, met or not, checked
      against disk rather than against the task's own claim.
    - Factual accuracy: RE-RUN every number. The screening documents cite counts from
      `git show 8b9e62021:...`; the script's header cites a re-derivation; task-002 cites
      before/after greps. A number that does not reproduce is a finding.
    - The audit script actually working: run it. Confirm it prints measurement beside expectation,
      exits 0, is byte-identical across two runs, and that its vacuity guards genuinely fire
      (zero refs extracted, zero review-family refs) rather than being claimed.
    - Screening soundness: spot-check outcomes against the evidence. An `admit` for a row already
      covered by a current criterion, or a `needs a new type` for a row that plainly attaches to
      `*`, is a finding. The three documents disagreeing about the SAME row would be a finding.
    - Scope discipline: task-002 must not have touched the in-document changelog or the bootstrap
      exemption section (those are task-022's), and no task may have hand-edited a generated tree.
    - Render parity: the generated trees and the two dogfood trees match their canonical sources.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Resolution is defined in
  .cursor/aid/templates/kb-authoring/review-rubric.md; the registry and criteria table live in
  .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a
    defect in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
    A missing or crashing oracle DEGRADES the criterion to reading, and you record that.
  - `scripts/checks/*.sh` and files under `.aid/works/**` resolve to no registry type. Where no
    declared criterion reaches a real defect, report it and say so plainly in Evidence. Do not
    invent an id.

OUT OF SCOPE (do NOT grade against):
  - Id collisions BETWEEN the three screening documents -- task-006 reconciles them by design.
  - The other 20 tasks of delivery-001 and all of delivery-002.
  - The task breakdown itself, the SPECs, the BLUEPRINT and PLAN.md -- all already gated.
  - Whether the owner's answered questions were right; they are settled.
  - The audit script's test suite -- that is task-008, not yet written.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, noting the routing destination.
  They do NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave2.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`. Read it first if it exists.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - After writing it, run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave2.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
