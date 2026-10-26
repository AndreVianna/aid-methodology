CYCLE 2 of the Detail review. Read `.aid/works/work-005-site-rework/briefs/detail-review-cycle-1.md` first: context, rubric, checks and out-of-scope list are unchanged. Also read `.aid/works/work-005-site-rework/briefs/detail-fix-brief.md` (the binding decisions the fixers applied).

ARTIFACTS UNDER REVIEW:

  VERIFY (full) - re-check EVERY existing ledger row of your delivery's cycle-1 ledger:
  .aid/works/work-005-site-rework/PLAN.md
  and the task folders of your delivery (every DETAIL.md in it)

  HUNT (scoped) - look for NEW findings ONLY in what the fixers changed (the task files of your delivery, and for delivery-003 the changed Depends on of task-027; the PLAN.md Execution Graph and wave-maps were re-derived from the tasks and `derive-waves.sh --check` passes).

For each existing row set Status Fixed or Recurred (keep rows). Hunt for new defects in the changed text, especially: acceptance commands that cannot pass or already pass before the work (quoting, backticks, placeholders left in commands, wrong paths or flags), a closing task that needs something only the delivery gate creates, cross-task contradictions introduced by moving work between tasks (for delivery-004: criteria moved from task-046 to task-043), and Depends on lines that no longer match the stated order.

DELIVERABLES: update your ledger (path in your prompt; 7 columns, one table, no narrative, per .aid/runtime/templates/reviewer-ledger-schema.md), run `bash .aid/runtime/scripts/grade.sh <ledger>`, return the grade, open counts by severity and a one-line gist per open row of MEDIUM or higher. Never edit tasks, PLAN.md, REQUIREMENTS.md or STATE.yml.
