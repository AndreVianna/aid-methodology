# Reviewer brief -- aid-detail work-003, full review cycle 2 (verify, Q140)

Repo root: /home/user/aid-methodology/.claude/worktrees/work-003-full-aid-restructure (branch work-003).

VERIFY (full): every row of `.aid/.temp/review-pending/detail-work-003.md` (40 rows, all marked Fixed by the orchestrator). Check each fix on disk in the named task files, PLAN.md and REQUIREMENTS.md; set Recurred if it is absent or does not resolve the finding. Each row's Evidence starts with its slice tag [part A..X].

HUNT (scoped): only what the cycle-1 fixes changed:
- the spec edits: F006 PL-06 (narrowed for aid-execute), F008 § 3 Writer (fork unchanged) and its Files row removal, F004 Migration KB list (README.md), F005 readers of § 9 tables, F009 CONTRIBUTING.md in the final pass and DN-01;
- PLAN.md: "Testing before the resync" (the work-folder-only rule), "The hold (for Q139's order)", the gate-session bullet, the switch table row for 010-013, the delivery-010 and -014 scope lines, the Execution Graph tables and wave-maps (run `bash .aid/runtime/scripts/execute/derive-waves.sh .aid/works/work-003-full-aid-restructure/PLAN.md --check`);
- in task files: the new test-step rule, the "Checks and judgments" bullet on sample tasks, the new edges, the hold steps in tasks 287, 310, 337, 352, and the tasks named in the rows.
Use `git show 0cd93387 --stat` and `git show 0cd93387 -- <file>` to see exactly what changed. Do not hunt outside these.

Rubric, criteria resolution, ledger format and grading: as in .aid/works/work-003-full-aid-restructure/briefs/detail-full-cycle-1-X.md (same rubric, same general rules G1-G19, Q106-Q139). Ledger: update `.aid/.temp/review-pending/detail-work-003.md` in place (Fixed -> Recurred where needed; append new rows Pending). Then run `bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/detail-work-003.md`.

WHAT TO REPORT (FR-21): only issues that affect the work -- a fix that does not hold, a task that cannot be built or verified, a missing owner or dependency, or a contradiction with the plan, a spec or a maintainer decision. No wording/cosmetic findings. Do not edit any task, plan or spec file.
