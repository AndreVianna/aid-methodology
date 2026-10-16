# Reviewer brief -- aid-detail work-003, full review cycle 1, part E

ARTIFACTS UNDER REVIEW:
  - .aid/works/work-003-full-aid-restructure/deliveries/delivery-012..014/tasks/task-*/DETAIL.md and STATE.yml (your SLICE: review every task here in full)
  - .aid/works/work-003-full-aid-restructure/PLAN.md (whole file: G0, "Testing before the resync", "Toolchain and Branching", every stanza, every `### delivery-NNN Execution Graph`)
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md § 11, the features your slice's deliveries build (see PLAN.md stanzas)
  - .aid/works/work-003-full-aid-restructure/STATE.yml qa Q104, Q111-Q139
  - The task files of the deliveries just BEFORE and just AFTER your slice, read only at the interfaces: what your slice's tasks assume an earlier delivery left, and what a later delivery expects your slice to leave

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
Re-review of all tasks for work-003 (AID restructuring itself; v4.0.0; 14 deliveries, 359 tasks) after PLAN/SPEC changes. This is the one full review cycle the maintainer set (Q136); six reviewers split it, and their ledgers are merged.

  Reviewer self-check: If CONTEXT discusses how tasks will be executed (agent
  choice, branching, parallelism details beyond what's in the Execution Graph),
  flag it as an OOS observation and bound your review to task files + the
  Execution Graph for this delivery only.

SCOPE: whole-list   # one of: per-deliverable | whole-list
  per-deliverable: Grade the task list for ONE delivery just written.
  whole-list:      Re-grade all task files against current PLAN.md + feature sections.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity → grade table)
  Grade tasks for:
    - Each task has exactly ONE Type (no mixing)
    - Task size fits one agent session
    - Every task traces back to a feature SPEC + delivery
    - Acceptance Criteria are concrete + testable
    - Dependencies declared correctly (Execution Graph valid; no cycles; no missing edges)
    - Type-specific default criteria included where applicable
    - Sequence respects natural ordering (RESEARCH/DESIGN before IMPLEMENT; TEST after; etc.)
    - Quality gate cascade present (REQUIREMENTS §6 inherited; feature-specific gates added)

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
  - feature technical-specification content — that's /aid-specify's grade
  - PLAN.md deliverable sequencing — that's /aid-plan's grade
  - KB document accuracy — route KB-source findings to /aid-discover Q&A
  - Execution detail (which agent, what branch) — /aid-execute owns runtime decisions
  - Tasks belonging to other deliveries (at per-deliverable scope)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/detail-work-003-full-E.md`. Do NOT count toward severity totals
  or grade. Note the routing destination (PLAN | SPEC | KB) in Description/Evidence.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/work-003-full-aid-restructure/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (TASK | PLAN | SPEC | KB)
  - Output location: `.aid/.temp/review-pending/detail-work-003-full-E.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill detail --key minimum_grade --default A`
  - The aid-reviewer NEVER edits task files — only grades and lists issues

LEDGER LIFECYCLE: write ONE table at `.aid/.temp/review-pending/detail-work-003-full-E.md` per `.aid/runtime/templates/reviewer-ledger-schema.md` (7 columns, no narrative). The per-delivery light-review ledgers in `.aid/.temp/review-pending/detail-work-003-delivery-*.md` are history: do not re-file a row they mark Fixed unless it has regressed (then file it new, citing the old row). Then run `bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/detail-work-003-full-E.md`.

SLICE E -- deliveries 012 to 014. Review every task in the slice in full against the rubric, the general rules below, PLAN.md and the specs. Then check the interfaces with the neighbouring deliveries: a file, suite, key, skill or path your slice uses must exist when it runs; one your slice removes or renames must not be used later without being re-pointed.

GENERAL RULES the tasks were written under (each a valid finding when broken): Q106/G11 same-task suite updates; G1 generated pages re-rendered, never hand-edited, counts and sync:docs; G2 sweeps own every skill from a full listing; G3 "nowhere" criteria hold at the task's end; G4 a dependency path for every needed order; G12 a direct edge for every same-file pair; G5 site generator re-run plus site npm test; G6 a deleting/moving task owns every suite (tests/, site/, SUITES) that reads the file; G7 move vs content owner; G8/G13 post-resync regeneration listed in the last task's gate-session block; G9 findings bullet; G10 copy-reading suites run in the scratch copy; G14 a new skill folder starts with SKILL.md and roster entry; G15 post-migration paths for 010-014; G16/Q139 010-014 research as a reviewed non-task step; G17 KB `sources:` fixed in the deleting task; G18 retired skill pages git rm'd; G19 site generator sources fixed on rename/retire; the KB-coexistence block on DOCUMENT tasks.

WHAT TO REPORT (maintainer rule, FR-21): report ONLY issues that affect the work -- a task that cannot be built or verified as written, a missing owner, a wrong or missing dependency, or a contradiction with the plan, a spec, another task or a maintainer decision. Exact counts, word-for-word comparisons and wording/cosmetic points are NOT findings. Do not edit any task, plan or spec file. Another agent may be reviewing other slices at the same time.
