# Reviewer brief -- aid-specify Feature 009, cycle 7 (fix of rows 13-15, then review)

ARTIFACTS UNDER REVIEW:
  VERIFY (full):
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 009 (whole feature section incl. #### Technical Specification; plus the §4/§5/§6/§9 entries it cites)
  HUNT (scoped):
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 009 #### Technical Specification -- only the parts changed for rows 13-15 (commit 1abdc4da; `git show 1abdc4da` lists them): The catalog skip rule and check-intent.md § The merged catalog; Writer; Routing kind hook (taken_by filter, callers incl. aid-review/aid-research/aid-report and /aid-orchestrate); Files and layout rows for check-intent.md, brainstorm start.md and the three skills; AS-03, AS-09, DN-03; the identity search's test-folder exclusions (re-run it); sample 009-19; traceability note
  - Research basis (read-only, for checking the spec matches the decisions): .aid/works/work-003-full-aid-restructure/research/non-software-domains.md sections 0 and 7

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
REQUIREMENTS.md §11 / Feature 009 in work-003-full-aid-restructure, the last feature. Written after the maintainer settled Q99-Q104, then extended for domain readiness by Q107-Q110 (STATE.yml qa: identity "software first, not software only"; exactly the 7 small changes and no pack in v4.0.0; one KB roadmap entry "Beyond software" with the nine later items); earlier qa entries also bind (verbs name skills; users never need to run skills but can; FULL/LITE = approval depth; lite has one approval before building; the agent proposes, the user disposes; Q96 skills pass to the close). Features 001-008 are approved (Ready) and binding: do not file findings against them, only contradictions of Feature 009 with them, and check that every row they address to Feature 009 is met. Intended edits outside Feature 009 (verify they are minimal and consistent): Feature 001 work-type list (investigation), routing rule (plain words to the action skill), phase table row; SS-02, SS-04, SS-09, ID-03, ID-04, KB-01, EX-06 scoped to while the retired files exist; Feature 007 IMPEDIMENT exemption wording. As the last feature, the deferred-tests list and both exempt lists must end empty. This project is AID itself (markdown skills, bash/PowerShell scripts).

  Reviewer self-check: If CONTEXT contains downstream phase concerns (planning,
  task breakdown, execution), flag it as an OOS observation and bound your
  review to the feature-section subsections listed in ARTIFACTS.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity → grade table)
  Grade ONE feature's `#### Technical Specification` for:
    - Consistency with the KB (architecture, module-map, coding-standards, schemas)
    - Internal coherence (schemas ↔ feature flow ↔ layers ↔ acceptance criteria)
    - Codebase reality (does the proposed integration touch the modules it claims?)
    - Testability (acceptance criteria are concrete + verifiable)
    - Spec discipline (no implementation prose; design decisions captured)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .aid/runtime/templates/kb-authoring/review-rubric.md
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

OUT OF SCOPE (do NOT grade against):
  - Other features in the same work (only the named feature is under review)
  - PLAN.md sequencing (that's /aid-plan's grade)
  - Task breakdown (that's /aid-detail's grade)
  - KB document accuracy (route KB-source findings to /aid-discover Q&A — they
    are observations for the upstream skill, not penalties here)
  - REQUIREMENTS.md content (route findings to /aid-describe Q&A)
  - Any part of REQUIREMENTS.md OUTSIDE the slice this feature traces to. The brief
    carries only that slice, taken from the feature SPEC's `## Source`; the rest of the
    document is not under review here and re-reading it once per feature per cycle is
    the cost this bound exists to remove.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/specify-work-003-feature-009.md`. Do NOT count toward severity
  totals or grade. Note the routing destination (CODE | SPEC | KB | REQUIREMENTS)
  in Description/Evidence so the coordinating skill can write the cross-phase Q&A entry.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/work-003-full-aid-restructure/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (CODE | SPEC | KB | REQUIREMENTS)
  - Output location: `.aid/.temp/review-pending/specify-work-003-feature-009.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`
  - The aid-reviewer NEVER edits the SPEC — only grades and lists issues

LEDGER LIFECYCLE: Read `.aid/.temp/review-pending/specify-work-003-feature-009.md` if it exists; verify existing rows; append new findings with Status: Pending. ONE markdown table per `.aid/runtime/templates/reviewer-ledger-schema.md`. Then run `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/specify-work-003-feature-009.md` and include the grade.
Also check: owned ACs (AC-20, AC-30, AC-31, AC-45) traceable; consistent with Q99-Q104 and with Features 001-008 (work creation only via the gate's --create; the work record as the only resume source; question protocol; shared exempt list; deferred list).

CYCLE 7 (fix of rows 13-15, then review): re-check every existing ledger row (rows 13-15 were marked Fixed by the orchestrator -- verify each; set Recurred if not). Hunt for new findings ONLY in the HUNT parts. Check in particular that the skip rule and the general hook agree with every reader the spec names, that AS-09 as rewritten would pass on the files as the spec leaves them, and that the identity search still finds every identity file it must.

WHAT TO REPORT (maintainer rule, FR-21): report ONLY issues that affect the work -- a step that cannot be built, a check that would fail on the real files, or a contradiction with another part of the spec, an approved feature, or a maintainer decision. Exact counts, word-for-word comparisons and wording/cosmetic points are NOT findings.
