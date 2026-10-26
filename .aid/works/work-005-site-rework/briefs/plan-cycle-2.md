ARTIFACTS UNDER REVIEW:

  VERIFY (full) - re-check EVERY existing ledger row against these:
  .aid/works/work-005-site-rework/PLAN.md

  HUNT (scoped) - look for NEW findings ONLY in what the fix changed:
  .aid/works/work-005-site-rework/PLAN.md

CONTEXT:
Working directory (git worktree; stay inside it): /tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework
Cycle 2 of the whole-plan review. Cycle 1 graded D+ (ledger `.aid/.temp/review-pending/plan-whole-plan.md`). A fixer edited PLAN.md (delivery-001 step order; delivery-002 changelog-link handling, link check, node:fs check; delivery-003 link check, Tabs, deleted-paths and slug checks; delivery-004 page-markup rule and AC-13 gate; concrete quality-gate command lists; Risks 2 and 4) and added one sentence to Feature 001's sidebar paragraph in REQUIREMENTS.md (section 11). Read `.aid/works/work-005-site-rework/briefs/plan-cycle-1.md` for the rubric, scope and out-of-scope list (unchanged). Mark each existing row Fixed or Recurred (keep rows). Hunt new issues in the changed text only: new commands must be valid (check syntax, paths, export names against the specs in REQUIREMENTS.md section 11), no gate may cite something its delivery cannot yet provide, no contradiction with the specs' own ordering rules.

DELIVERABLES: update the same ledger (7 columns, one table, no narrative, per .aid/runtime/templates/reviewer-ledger-schema.md), run `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/plan-whole-plan.md`, return the grade, open counts by severity, and a one-line gist per open row. Never edit PLAN.md, REQUIREMENTS.md or STATE.yml.
