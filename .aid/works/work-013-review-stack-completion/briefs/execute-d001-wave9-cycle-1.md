ARTIFACTS UNDER REVIEW:
  One task. Cycle 1, so this is ONE unlabelled list.

    - .aid/knowledge/authoring-conventions.md
    - canonical/aid/templates/kb-authoring/review-rubric.md
    - canonical/agents/aid-reviewer/AGENT.md
    - canonical/skills/aid-specify/references/reviewer-brief.md
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-021/SCOPE-CHANGE.md

  The other five per-skill reviewer-brief.md files took the identical edit; spot-check one rather
  than reading all six.

  Readable to verify a claim, NOT graded: task-020's RESEARCH.md, the g07 oracle, and
  spec-template.md.

  Also in the diff, NOT independently graded: the profiles/ render and the two root install trees.

CONTEXT:
  Wave 9 of delivery-001, work-013. task-021's ACs are in its DETAIL.md.

  Three things to know, and the third is the one to attack hardest.

  First, task-021 was BUILT NARROWER THAN WRITTEN, on the owner's explicit decision. Its scope
  line says "add the registry row so work artifacts resolve to a type"; no registry row was added
  and they still resolve to no type. The reasoning and the owner's choice are recorded in
  SCOPE-CHANGE.md. Judge whether the deviation is justified AND whether it is recorded honestly --
  including that it CORRECTS task-020, whose recommended mechanism (per-file frontmatter) turned
  out to be impossible because none of the four artifacts carries frontmatter.

  Second, an honest extension is claimed: both pre-existing file-class rows are `kind: exclude`
  and the two new ones are `kind: validate`, so the preamble was generalised. Judge whether that
  is a legitimate reading of the form or a stretch dressed up as one.

  Third, and most important: DECLARING CRITERIA IS INERT UNLESS A REVIEWER RESOLVES THEM. The
  claim is that the documented resolution procedure had no step for the file-class form at all --
  meaning G-05 and G-06 were ALREADY unreachable by it -- and that step 1 wrongly asserted the
  registry always resolves, which would make a reviewer file a spurious finding against every work
  artifact. Verify that claim about the PRIOR state from git, then verify the fix actually closes
  it. If the wiring does not work, the criteria are decoration and this task achieved nothing.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in task-021's DETAIL.md, verified by running its command.** Note AC-1 says the
      oracle is recorded before AND after with both counts stated -- check both were actually run,
      not asserted.
    - **The partition really is untouched.** Re-run the before/after yourself via git stash.
    - **The ids collide with nothing.** Re-derive the namespace.
    - **G-15 is a criterion with a severity and a why, not prose.** Judge whether MEDIUM is right
      relative to the table's other severities, and whether the `why` explains rather than repeats.
    - **The wiring, end to end.** Would a reviewer dispatched against
      `.aid/works/**/features/*/SPEC.md`, following ONLY the documented procedure, now resolve
      G-14 and G-15 and NOT file a spurious no-type finding? Walk it as if you were that reviewer.
    - **No cell contains a pipe**, per the table's own rule, and the new rows carry the same fields
      as every other row.
    - Anything task-025 or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then any file-class row whose membership test
  the file satisfies, then the artifact's own `review-criteria:` frontmatter. Registry and criteria
  table: .aid/knowledge/authoring-conventions.md.
  - NOTE: the resolution procedure itself is under review this wave. Resolve using the procedure as
    it now stands, and if following it produces a wrong answer, that IS the finding.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - SCOPE-CHANGE.md is a work artifact: it resolves to no type, and G-14/G-15 do not reach it --
    their membership test names four artifact kinds and this is not one. Say so rather than
    inventing an id for it.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - Whether the 46 citation violations in this work's feature SPECs should now be fixed.
  - task-025 and all of delivery-002.
  - The generated render and root install trees as artifacts in their own right -- but DO check
    they are in step with canonical.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave9.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave9.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
