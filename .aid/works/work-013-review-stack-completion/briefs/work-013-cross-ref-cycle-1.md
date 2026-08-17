ARTIFACTS UNDER REVIEW:
  - .aid/works/work-013-review-stack-completion/REQUIREMENTS.md
  - .aid/works/work-013-review-stack-completion/features/feature-001-single-review-path-alignment/SPEC.md
  - .aid/works/work-013-review-stack-completion/features/feature-002-coverage-gate-completion/SPEC.md
  - .aid/works/work-013-review-stack-completion/features/feature-003-severity-and-recall-measurement/SPEC.md

  This is cycle 1, so the list above is ONE unlabelled list. The VERIFY/HUNT split
  begins at cycle 2; definitions live in `reviewer-ledger-schema.md` section
  "Two sets from cycle 2".

CONTEXT:
  REQUIREMENTS.md was just approved and 3 features were decomposed from §5 Functional
  Requirements. This is the cross-reference pass that validates requirements + feature
  boundaries against the KB and codebase before any feature reaches /aid-specify.

  Descriptive only, and load-bearing for scope: the decomposition proposed three features
  (one per track T1/T2/T3) rather than the single feature the owner asked for, on the
  argument that a feature is atomic to a delivery and a single feature would leave no gate
  between T1 and T2 — which AC-2 ("after T1") and FR-A5 ("closes with a recorded audit")
  both require. That argument is itself in scope: if it is wrong, say so with evidence.

  Nine findings were already raised against these requirements and are recorded as Q1–Q9
  in `.aid/works/work-013-review-stack-completion/STATE.yml`. Read them first. Do NOT
  re-report a known one as a new finding; if you find one is wrong, say which and why.

  Reviewer self-check: If CONTEXT contains downstream-phase concerns (specify, plan,
  detail, execute), flag it as an OOS observation and bound your review to the
  REQUIREMENTS.md + feature SPEC.md files listed in ARTIFACTS.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity → grade table)
  Grade REQUIREMENTS.md + feature decomposition for:
    - Internal consistency (objective ↔ functional requirements ↔ acceptance criteria)
    - Consistency with the KB (architecture, technology-stack, integration-map)
    - Codebase reality (proposed integration points exist; no contradictions with
      what the code already does)
    - Feature decomposition completeness (every Must requirement maps to ≥1 feature)
    - Feature boundary clarity (no feature mixes unrelated concerns; no overlap)
    - Gaps that warrant Q&A back to the user (record as Pending Q&A, not findings)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then the
  artifact's own `review-criteria:` frontmatter; most specific wins on an id collision.
  Resolution is defined in .cursor/aid/templates/kb-authoring/review-rubric.md
  (section: Resolving review criteria); the type registry and the criteria table live in
  .aid/knowledge/authoring-conventions.md. This brief deliberately does NOT restate them.
  - Cite the criterion `id` as a prefix in the ledger's Description cell (7 columns, no
    new column). A finding citing no id, or an id resolving nowhere, is itself a defect.
  - A `kind: exclude` criterion binds you: reporting it is a defect in the review.
  - **If a criterion carries an `oracle:`, RUN it -- do not re-read the criterion to
    reach the same verdict.** Invoke it from the repository root under a 60-second
    timeout. It reports per FILE: exit 0 means no violation among the files it decided,
    exit 1 means at least one `VIOLATION <path>` line, exit 2 (or any other exit, a
    timeout, or exit 1 with no VIOLATION line) means it could not decide.
  - **`UNDECIDED <path>` lines are normal, not a failure.** Take the decided files as
    settled and judge only the undecided remainder by reading.
  - **A missing, non-executable, crashing, timed-out or malformed oracle DEGRADES that
    criterion to reading, and you record that the degradation happened.** Never let a
    degraded oracle read as a pass, and never file it as a violation -- "I could not
    tell" is neither.
  - One finding per `VIOLATION` line: the criterion `id` as the Description prefix, the
    invocation and that line in Evidence. Seven columns, unchanged.
  - If the severity came from a file-level override, record the resolved severity and the
    overriding file's `why` in the Evidence cell.

  Note on artifact type: a work-folder artifact under `.aid/works/` resolves to no row in
  the type registry, whose selectors cover `.aid/knowledge/`, `canonical/skills/`,
  `canonical/agents/` and `canonical/aid/templates/`. Where no declared criterion reaches
  a real defect, still report it, and say plainly in Evidence that no criterion declares
  it. Do not invent an id, and do not suppress the finding for want of one.

OUT OF SCOPE (do NOT grade against):
  - SPEC.md Technical Specification sections — /aid-specify hasn't run yet for
    these features; only the auto-generated feature scaffold is in scope here
  - PLAN.md sequencing (doesn't exist yet)
  - Task breakdown (doesn't exist yet)
  - KB document accuracy — route KB-source findings to /aid-discover Q&A as
    observations for the upstream skill
  - Interview process quality (whether the right questions were asked) — that's
    a meta concern, not graded here
  - The owner's settled decisions: master's review stack is law; track order T1 → T2 → T3;
    migrate catalog checks into the cascade; default-delete abandoned scripts. Grade only
    whether the artifacts state them accurately and consistently.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/interview-work-013-cross-ref.md`. Do NOT count toward
  severity totals or grade. Note the routing destination (KB, SPEC) in
  Description/Evidence so the orchestrator can write the cross-phase Q&A entry.

DELIVERABLES:
  - Append new findings as rows with Status: Pending to
    `.aid/.temp/review-pending/interview-work-013-cross-ref.md`. Read the existing file
    first if it exists. Output per `.cursor/aid/templates/reviewer-ledger-schema.md` --
    ONE table, no narrative. After writing the ledger, run:
    `bash .cursor/aid/scripts/grade.sh .aid/.temp/review-pending/interview-work-013-cross-ref.md`
    and include the grade in your return message.
  - Findings format: severity-tagged + source-tagged (REQUIREMENTS | FEATURE | KB)
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .cursor/aid/scripts/grade.sh; minimum resolved via
    `bash .cursor/aid/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`
  - Pending Q&A: propose user-facing questions in your return message. Do NOT write them
    to STATE.yml yourself -- the orchestrator owns that file on this branch.
  - The aid-reviewer NEVER edits REQUIREMENTS.md or SPEC scaffolds — only grades and lists issues

CROSS-DOCUMENT CONTRADICTION PASS (Guard 2, cycle 1 only):
  This review receives every artifact of the phase at once, which is the only vantage
  point from which a contradiction between two of them is visible. Run it here, on
  cycle 1, which makes it once per phase by construction. Definition:
  `reviewer-dispatch.md` section "The cross-document contradiction pass (Guard 2)".
  Specifically check: a claim in REQUIREMENTS.md against the feature SPEC that carries it;
  a requirement carried by two features; a requirement carried by none; and an acceptance
  criterion whose modality differs between §9 and the SPEC that inherited it.
