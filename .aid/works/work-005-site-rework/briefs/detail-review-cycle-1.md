ARTIFACTS UNDER REVIEW:
  .aid/works/work-005-site-rework/PLAN.md
  The task folders of YOUR delivery (named in your prompt): every `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` and `STATE.yml` in it.

CONTEXT:
Working directory (git worktree; stay inside it): /tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework
Detail phase of work-005-site-rework: 49 tasks across 4 deliveries (001: task-001..004, 002: task-005..023, 003: task-024..035, 004: task-036..049) were just written from PLAN.md and the Technical Specifications in `.aid/works/work-005-site-rework/REQUIREMENTS.md` section 11. The Execution Graph and wave-maps in PLAN.md are derived from the tasks' Depends on fields (derive-waves --check passes). Four reviewers run in parallel, one per delivery; you review your delivery's tasks against PLAN.md, the specs and the real repo, and flag cross-delivery contradictions you can see from your side (name the other task).

SCOPE: whole-list (your delivery's tasks, graded as a list)

RUBRIC: .aid/runtime/templates/grading-rubric.md; task rules in `.claude/skills/aid-detail/references/task-decomposition.md` (types, one type per task, small, format, quality). Check:
  - Format: all 6 sections + the execution-protocol note; STATE.yml seeded (state Pending, review --, elapsed --, notes --); Source names feature, delivery and at least one AC id that the feature owns (section 9 / PLAN); Depends on lists real task ids (no forward cycle).
  - Coverage: every spec step and gate item PLAN.md assigns to your delivery is owned by exactly one task (none lost, none duplicated); no task does work PLAN.md assigns to another delivery.
  - Executability: each task fits one agent session; scope names exact files and spec step ids that exist; every acceptance criterion is a command with expected output or a file fact (an observable that can fail); commands are valid (syntax, paths, export names, flags) against the specs and the repo; nothing is used before an earlier task creates it.
  - Safety: every task forbids deploying, publishing, pushing, tagging, `npm publish`, network other than npm install, edits under `canonical/` and outside the AC-13 allowed paths.
  - Ordering rules from PLAN.md Notes and the specs (e.g. Feature 005 step 1 first; 003 before 005 config edit; 004 styles before 005 step 6) are respected by Depends on.
  Verify read-only; do not run npm install or a build.

OUT OF SCOPE: redesign of the specs or the plan (log as OOS rows), KB accuracy.

DELIVERABLES:
  Ledger path is in your prompt: ONE markdown table, 7 columns, no narrative, per .aid/runtime/templates/reviewer-ledger-schema.md; severity CRITICAL|HIGH|MEDIUM|LOW|MINOR; Status Pending (or OOS). Then run `bash .aid/runtime/scripts/grade.sh <ledger>` and return the grade, severity counts and a one-line gist per open row of MEDIUM or higher. Never edit tasks, PLAN.md, REQUIREMENTS.md or STATE.yml.
