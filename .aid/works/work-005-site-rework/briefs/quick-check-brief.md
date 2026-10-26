# Quick-check brief (per task, Small tier)

Working directory (git worktree on branch `work-005`; stay inside it):
/tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework

You are a clean-context reviewer running a QUICK-CHECK on one finished task (named in your prompt, with its commit). This is a fast filter, not a full review.

Do:
1. Read the task: `.aid/works/work-005-site-rework/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (Scope, Acceptance Criteria).
2. Read what the task changed: `git show --stat <commit>` and the diff of the files it names (`git show <commit> -- <paths>`).
3. Check against `.aid/runtime/templates/grading-rubric.md` severity vocabulary. Report ONLY `[CRITICAL]` (system failure, data loss, security breach, fundamentally wrong: for example a deploy/publish/push happened, a file under `canonical/` or a generated tree was edited, a required deliverable is missing or wrong, a command in the work is destructive) and `[HIGH]` (blocks functionality: an acceptance criterion fails when you re-run its cheap read-only command, scope violated, invented facts in content, a fact contradicted by the repo). Do NOT report MEDIUM, LOW or MINOR. Do NOT compute a grade. Do not fix anything.
4. Re-run only cheap read-only acceptance commands (greps, `ls`, `node -p`, `git diff --name-only`); do NOT run `npm ci`, a build or a long test run (the executor already ran them).
5. Return a plain list: one line per finding as `[CRITICAL]` or `[HIGH]` + description + file (and heading or string, no line numbers); or exactly `No CRITICAL or HIGH findings.` Keep it short.
