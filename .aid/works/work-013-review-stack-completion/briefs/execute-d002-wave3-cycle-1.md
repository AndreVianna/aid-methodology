ARTIFACTS UNDER REVIEW:
  Four tasks in one wave. Cycle 1, so this is ONE unlabelled list.

    - canonical/aid/templates/reviewer-ledger-schema.md
    - canonical/agents/aid-reviewer/AGENT.md
    - .aid/knowledge/authoring-conventions.md
    - canonical/aid/templates/reviewer-dispatch.md
    - canonical/skills/aid-specify/references/reviewer-brief.md
    - tests/canonical/fixtures/recall-corpus/CATALOGUE.md
    - tests/canonical/fixtures/recall-corpus/seed-ledger.md

  The other five per-skill reviewer-brief.md files took the identical mechanical edit; spot-check
  one rather than reading all six. The 20 fixture files under recall-corpus/defects/ are content
  addressed by the catalogue; read them as the catalogue's rows require, not one by one.

  Which task owns what: task-028 the schema, the agent and the conventions doc; task-032 the six
  briefs plus the placeholder registration; task-045 the coverage-unit section of the dispatch
  protocol; task-037 the corpus.

CONTEXT:
  Wave 3 of delivery-002, work-013. Each task's ACs are in its own DETAIL.md.

  This is the wave the two deliveries were split for. task-028 edits
  `reviewer-ledger-schema.md` -- the file delivery-001's feature-001 required UNCHANGED. So NFR-1
  is the sharpest thing here and it has two halves: the seven-column shape must not move, and
  `grade.sh` must not be touched at all. Its recorded md5 baseline is
  `0d87371d1bdbf165fa386f8c5b7286e5` in the delivery-002 RECORD.

  Four things to attack.

  First, task-028's AC-2 requires the paragraph a suite reads by exact string to be BYTE-IDENTICAL,
  with the contract going in the column rows instead. Four literals are pinned by
  `test-scoped-review-cycles.sh`. Verify each still resolves AND that the surrounding paragraph is
  unchanged -- `git diff` the file and look at what moved, do not just grep for the strings.

  Second, task-037's corpus. Its AC-1 demands every signature appear in its fixture and NOWHERE
  ELSE in the repository, asserted per row rather than spot-checked. Re-run that assertion yourself
  across all 20. Its AC-3 demands EXACTLY ONE pair sharing a class and signature, with only one of
  the two named by a ledger row. An earlier draft of this corpus had three accidental twin pairs;
  check the fix did not leave a fourth somewhere.

  Third, task-045 quotes a measurement as its trigger -- a re-read ratio of 2.02 and an exact
  doubling. Re-derive both from `review-cost.tsv`. If the arithmetic is right but the INFERENCE is
  wrong -- if the doubling has an explanation other than one path on both lists -- say so, because
  task-046 and task-047 build on this reading.

  Fourth, task-032 claims all ten measured sites are converted and no second substitution
  mechanism was introduced. Verify the count independently from `git show HEAD~1:`.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in all four DETAIL.md files, verified by running its command.** Do not sample.
    - **NFR-1, both halves.** grade.sh untouched by md5 against the recorded baseline; the column
      shape unmoved; the pinned literals byte-identical.
    - **Truth of every measured number.** Re-derive them.
    - task-028: is the why-line contract actually usable? You are about to write a ledger under it.
      If the form is ambiguous or the provenance tokens do not cover a case you hit, that is a
      finding worth more than any wording nit -- and you are the first reviewer bound by it.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the artifact satisfies, then its own `review-criteria:` frontmatter.
  - **Apply the new contract to your own ledger for this review**: every row carries a why-line in
    Description and a severity-provenance token in Evidence. You are its first user; report the
    experience as a finding if it does not work.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - `review-recall.sh` and `test-severity-why-line.sh` -- not yet written; task-038 and task-029.
  - The remaining 14 delivery-002 tasks, and all of delivery-001.
  - The generated render and root install trees as artifacts in their own right -- but DO check
    they are in step with canonical.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d002-wave3.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d002-wave3.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
