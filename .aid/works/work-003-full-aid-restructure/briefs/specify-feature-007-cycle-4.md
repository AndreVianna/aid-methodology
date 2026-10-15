# Reviewer brief -- aid-specify Feature 007, cycle 4

ARTIFACTS UNDER REVIEW:
  VERIFY (full):
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 007 (whole feature section incl. #### Technical Specification; plus the §4/§5/§6/§9 entries it cites)
  HUNT (scoped):
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 007 #### Technical Specification -- only the parts changed for rows 9-10: NEXT's 'What comes next' routing rule and its pointers (give-up paragraph, step-table NEXT and DELIVERY rows, DELIVERY's last-delivery line, the writer sentence); simplify-guard.sh made bash-only and its unit test

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
REQUIREMENTS.md §11 / Feature 007 in work-003-full-aid-restructure. Written after the maintainer settled Q76-Q80 (STATE.yml qa); earlier qa entries also bind (one worktree and branch per work; milestones required at each delivery end and the whole build, optional per wave; real blockers and KB conflicts stop building; verification = review cycle, simplification only after it, scoped re-verify only if it changed something; every correction is a build approved before push; never merge, never delete the remote branch; CI/CD ends at PR merge into pipeline.parent_branch; isolated unit tests and a full suite at the end; FULL/LITE = approval depth). Features 001-006 are approved (Ready) and binding: do not file findings against them, only contradictions of Feature 007 with them, and check that every row they address to Feature 007 in 'What other features must provide' is met. Feature 008 is not yet specified: rows Feature 007 addresses to it are expectations, not findings. This project is AID itself (markdown skills, bash/PowerShell scripts).

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
  `.aid/.temp/review-pending/specify-work-003-feature-007.md`. Do NOT count toward severity
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
  - Output location: `.aid/.temp/review-pending/specify-work-003-feature-007.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`
  - The aid-reviewer NEVER edits the SPEC — only grades and lists issues

LEDGER LIFECYCLE: Read `.aid/.temp/review-pending/specify-work-003-feature-007.md` if it exists; verify existing rows; append new findings with Status: Pending. ONE markdown table per `.aid/runtime/templates/reviewer-ledger-schema.md`. Then run `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/specify-work-003-feature-007.md` and include the grade.
Also check: owned ACs (AC-26, AC-32, AC-33, AC-34) traceable; consistent with Q76-Q80 and with Features 001-006 (work creation only via the gate's --create; the work record as the only resume source; question protocol; shared exempt list; deferred list).

CYCLE 4: re-check every existing ledger row (rows 9-10 were marked Fixed by the orchestrator -- verify; set Recurred if not). Hunt for new findings ONLY in the HUNT parts. canonical/aid/templates/skill-steps.md is created by Feature 002's build; its absence from today's tree is not a finding.

WHAT TO REPORT (maintainer rule, FR-21): report ONLY issues that affect the work -- a step that cannot be built, a check that would fail on the real files, or a contradiction with another part of the spec, an approved feature, or a maintainer decision. Exact counts, word-for-word comparisons and wording/cosmetic points are NOT findings.
