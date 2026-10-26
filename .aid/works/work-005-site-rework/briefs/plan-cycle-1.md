ARTIFACTS UNDER REVIEW:
  .aid/works/work-005-site-rework/PLAN.md
  .aid/works/work-005-site-rework/REQUIREMENTS.md
  .aid/works/work-005-site-rework/deliveries/delivery-001/STATE.yml
  .aid/works/work-005-site-rework/deliveries/delivery-002/STATE.yml
  .aid/works/work-005-site-rework/deliveries/delivery-003/STATE.yml
  .aid/works/work-005-site-rework/deliveries/delivery-004/STATE.yml

CONTEXT:
Working directory (git worktree; stay inside it): /tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework
PLAN.md for work-005-site-rework with 4 deliveries, first review. Features 001-006 in REQUIREMENTS.md section 11 are Ready (each has a Technical Specification with explicit ordering rules and numbered steps).

SCOPE: whole-plan

RUBRIC: .aid/runtime/templates/grading-rubric.md
  Grade PLAN.md for:
    - Each delivery is standalone-functional (site/ builds and is usable) and its gate can pass using only what is delivered by then; gate criteria are concrete commands with expected results (cited ACs satisfiable by that delivery)
    - Dependencies flow one direction, no cycles; the orderings the specs demand are respected (read each spec's Migration Plan / Feature Flow / Notes for "before", "after", "together with" rules; check the plan's step splits against them, including the early move of tests/dist.mjs and the split of Feature 005 steps and Feature 004 files)
    - Every Ready feature and every spec step is assigned exactly once (no step lost, none duplicated across deliveries)
    - Every AC (AC-1..AC-15) is owned by a gate in the delivery where it can first be proven; no gate cites an AC its delivery cannot satisfy yet
    - Risks are real and mitigations concrete; delivery STATE.yml files match the template (delivery_state Pending-Spec)
  Verify claims read-only against the repo (paths, commands). Do not run npm install or a build.

OUT OF SCOPE: task breakdown (aid-detail), technical redesign of the specs (log disagreements with a spec as OOS rows), KB accuracy.

DELIVERABLES:
  Ledger `.aid/.temp/review-pending/plan-whole-plan.md`: ONE markdown table, 7 columns, no narrative, per .aid/runtime/templates/reviewer-ledger-schema.md; severity CRITICAL|HIGH|MEDIUM|LOW|MINOR; Status Pending (or OOS). Then run `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/plan-whole-plan.md` and return the grade, severity counts and a one-line gist per open row of MEDIUM or higher. Never edit PLAN.md, specs, REQUIREMENTS.md or STATE.yml.
