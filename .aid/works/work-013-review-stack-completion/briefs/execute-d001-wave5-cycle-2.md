ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against this):
    - .aid/knowledge/artifact-schemas.md
    - canonical/aid/scripts/summarize/kb-html-claims-check.sh
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/RECORD.md

  HUNT (scoped -- NEW findings only in what the fix touched):
    artifact-schemas.md: the alias section's new kb_baseline paragraph, and the grade-domain
    modifier table that replaced the one-line rule.
    kb-html-claims-check.sh: TEMPLATE_DIR resolution, the --template-dir flag, and the
    missing-oracle exit path.
    RECORD.md criterion 10: the newly recorded root-install-tree note.

CYCLE 2 -- WHAT THE FIX CHANGED (verify these four; do not re-litigate them):
  Row 1 [HIGH] kb_baseline wrongly in "read but never stored". FIX: removed from that table. A new
    paragraph in the alias section states that the baseline IS stored, that kb_baseline and
    knowledge.{source,last_update} name the same FR35/FR36 write, and that the difference from a
    real alias is that read-setting.sh has no kb_baseline entry so the old spelling resolves to
    nothing. Verify each of those three claims separately -- especially the last, by probing
    --path kb_baseline.branch against the template.
  Row 2 [HIGH] "+ means exactly one finding" is false for the A band. FIX: replaced with an
    explicit table (no findings -> A+, 1-5 MINOR -> A, 6+ MINOR -> A-, 1 LOW -> B+) plus the general
    rule for B-E. Exercise grade.sh for EVERY row of that table.
  Row 3 [MEDIUM] root trees landed a commit late. NOT code-fixed -- recorded in RECORD.md
    criterion 10 with the cause (rsync absent, stderr redirected) and two rules. Judge whether
    recording is the right disposition and whether the note is accurate; parity itself must now be
    clean by diff.
  Row 4 [LOW] hardcoded template dir caused a silent class-1 skip from another cwd. FIX: resolved
    from BASH_SOURCE, a --template-dir flag added, and a missing dir now exits 2 with a message
    instead of skipping. Re-run the check from /tmp and confirm it still finds the STATE.md defect.

  Read the existing ledger at .aid/.temp/review-pending/execute-d001-wave5.md FIRST. Update the four
  rows' Status in place -- do not delete them, do not rewrite Severity or Description. Append any
  genuinely NEW finding in the HUNT region as a new Pending row.

  The other five tasks' ACs were verified clean in cycle 1; re-check them only where this fix could
  plausibly have disturbed them.

CONTEXT:
  Wave 5 of delivery-001, work-013 — the first wave past the T1 boundary that task-009 closed,
  so these are all feature-002 tasks. Each has its own ACs in its DETAIL.md; read them.

  Three things to know before you start.

  First, task-010 REFUSED one of its three scope lines and recorded why in CORRECTION.md. The
  line said to drop `F` from the documented grade domain because `grade.sh` cannot emit it. That
  premise is false — `grade.sh --non-functional` prints `F`, and quality-gates.md already documents
  it. Judge the refusal on its merits: is the premise genuinely false, is the substituted change
  (enumerate all sixteen values, name the E band, say F is flag-only) actually correct, and is
  refusing the right call versus executing it? If the refusal is wrong, say so plainly.

  Second, task-013 knowingly leaves CI red. It adds a kb-citation-lint step that fails today on 8
  live violations in tech-debt.md. task-014 fixes those and depends on task-013; both land in the
  same PR. Judge whether that sequencing is recorded honestly, not whether red CI is acceptable.

  Third, task-016's script went through three wrong designs before the current one, and the commit
  message says so. Judge only the script as it now stands.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifacts listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Every AC in every DETAIL.md, verified by running its command**, not by reading a claim.
      Six tasks; do not sample.
    - **Truth of every measured number** quoted in a doc, a comment or a commit. Re-derive them.
    - task-010's rewritten schema section: is it CORRECT? Probe the keys yourself against the
      template with read-setting.sh. The alias table claims to be closed — test a section prefix
      that is not in it. The "read but never stored" table claims specific effective defaults —
      check them against the consumers named.
    - task-016's script: does it do what its header says, is its oracle sound, and can each of its
      three claim classes actually fire? A class that cannot fire is dead weight and a finding.
      Try to make it produce a false positive or a false negative.
    - task-023's AS09/AS10: does the widening actually catch something the narrow corpus misses?
      Prove it by planting a history section, as the task claims to have done.
    - Anything a later task or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Registry: .aid/knowledge/authoring-conventions.md
  (37 criteria — task-016 asserts it did not change this file; verify that).
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - Shell scripts and workflow YAML resolve to no registry type. Where no declared criterion reaches
    a real defect, report it and say so in Evidence. Do not invent an id.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13; a 14th is a finding.
  - PR #185 being open.
  - Tasks 011, 012, 014, 015, 017-021, 025 and all of delivery-002.
  - The generated render and the root install trees as artifacts in their own right — but DO check
    they are in step with canonical, since a stale render is a real defect.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave5.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave5.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
