# Reviewer brief -- aid-plan work-003, cycle 2 (fix of rows 1-18)

ARTIFACTS UNDER REVIEW:
  VERIFY (full):
    - .aid/works/work-003-full-aid-restructure/PLAN.md (whole file: Common Gate, 14 delivery stanzas with Waves, Delivery Order, Toolchain and Branching, Cross-Cutting Risks)
    - .aid/works/work-003-full-aid-restructure/deliveries/delivery-001..014/STATE.yml (seeded, Pending-Spec)
    - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11 Feature 001-009 sections incl. their Technical Specifications (the features the plan assigns)
    - .aid/works/work-003-full-aid-restructure/known-issues.md
    - .aid/works/work-003-full-aid-restructure/STATE.yml qa Q1-Q119 (maintainer decisions; Q104 and Q111-Q119 shape this plan)

  HUNT (scoped):
    - .aid/works/work-003-full-aid-restructure/PLAN.md (rewritten as a whole for rows 1-15: all of it is in HUNT)
    - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md, only the spec edits for rows 16-18: F001 SG-04 (about L799-800, L941); F008 NM-01/NM-05 instruction-only exceptions (about L5514, L5516) and their pointers in F004 FINISH (about L2441) and F008 CLOSE (about L5215-5216); F004 re-pointed suites list (about L2917-2922)
    - STATE.yml qa Q120-Q121
  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
PLAN.md for work-003 with 14 deliveries; re-review against the current feature sections. This project is AID itself (markdown skills, bash/PowerShell scripts, tests, site), and it installs itself, so the plan also states which toolchain builds each delivery (Q111, Q114, Q119), that every delivery is built directly on the work-003 branch (Q112, Q118), and how split features cut their suites (Q113, Q115, Q117).

  Reviewer self-check: If CONTEXT contains task-breakdown concerns or per-task
  acceptance criteria, flag it as an OOS observation and bound your review to
  PLAN.md deliverable sequencing only.

SCOPE: whole-plan   # one of: per-deliverable | whole-plan
  per-deliverable: Grade ONE newly-written delivery against its dependencies +
                   the standalone-functional criterion. Re-grade preceding
                   deliveries only if this one introduces a sequencing conflict.
  whole-plan:      Re-grade all deliveries against the current REQUIREMENTS.md.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity → grade table)
  Grade PLAN.md deliverables for:
    - Each delivery is functional on its own (independently usable + testable)
    - Dependencies flow one direction (no cycles)
    - Every Ready feature is assigned to a delivery OR explicitly Deferred
    - Sequence respects KB architecture (no delivery requires a not-yet-built dependency)
    - Cross-cutting risks only if real
    - Known-issues from `.aid/works/work-003-full-aid-restructure/known-issues.md` Critical/High addressed (fix-first delivery or sequenced)

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
  - Per-task breakdown — that's /aid-detail's domain (a delivery has no "tasks" yet at /aid-plan time)
  - feature technical-specification content — that's /aid-specify's grade
  - REQUIREMENTS.md content — that's /aid-describe's grade
  - KB document accuracy — route KB-source findings to /aid-discover Q&A
  - Execution Graph for tasks (added later by /aid-detail)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/plan-work-003.md`. Do NOT count toward severity totals
  or grade. Note the routing destination (PLAN | SPEC | KB | REQUIREMENTS) in
  Description/Evidence so the coordinating skill can write the cross-phase Q&A entry.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/work-003-full-aid-restructure/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (PLAN | SPEC | KB | REQUIREMENTS)
  - Output location: `.aid/.temp/review-pending/plan-work-003.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`
  - The aid-reviewer NEVER edits PLAN.md — only grades and lists issues

LEDGER LIFECYCLE: Read `.aid/.temp/review-pending/plan-work-003.md` if it exists. For each existing row: verify on disk, update Status (Pending->Fixed if resolved; Fixed->Recurred if regressed). Append new findings with Status: Pending. Output per `.aid/runtime/templates/reviewer-ledger-schema.md` -- ONE table, no narrative. Then run `bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/plan-work-003.md` and include the grade.

CYCLE 2 (fix of rows 1-18): re-check every existing ledger row (rows 1-18 were marked Fixed by the orchestrator -- verify each against the files; set Recurred if not; row 19 stays OOS, routed to the KB). Hunt for new findings ONLY in HUNT. Guard 2 and the F002 cross-feature review ran in cycle 1 and are not repeated, except that a spec edit for rows 16-18 must stay consistent with every feature that cites it.

Also check, for this plan specifically: each split part (F002 engine/sweep, F004 parts 1/2, F009 a/b/c, final documentation) stands alone and is testable alone with its own suite group; each delivery's Waves follow real dependencies; every AC owned by a feature is gated by exactly the delivery that builds it; the toolchain each delivery is built with can actually build it (today's /aid-detail and /aid-execute for 001-008 up to the migration task, the main conversation for the end of 008 and all of 009, the new /aid-execute from 010); and no delivery needs something a later one builds.

WHAT TO REPORT (maintainer rule, FR-21): report ONLY issues that affect the work -- a delivery that cannot be built or tested as planned, a gate criterion that would fail on the real files, or a contradiction with another part of the plan, a feature spec, or a maintainer decision. Exact counts, word-for-word comparisons and wording/cosmetic points are NOT findings.
