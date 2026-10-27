# Site rework benchmark: observation notes

The same request, from the same commit, run twice: plain Claude (no AID) and today's AID full chain (`/aid-describe`).
Request: rework `site/` completely; check every page against the current skills and processes; modern, professional
diagrams and layout, accessible to every level and to screen-reader and keyboard users; cut the machinery to what a
static site needs; no deploy. Model `claude-sonnet-5-5`; AID's helpers use the models their definitions name.

## Plain run

| Measure | Value |
|---|---|
| Time | 24.6 min, 2 user turns |
| Cost | about $11.50 |
| Helper agents | 7 |
| Result (graded) | builds (62 pages); 0 stale command names, 3 invented ones (`/aid-add-api`, `/aid-change-ui`, `/aid-tool`); 0 broken links; 34 pages with serious accessibility issues (27 before); generator code 11,289 -> 278 lines, site tests 30,917 -> 0 |
| Noticed and left alone | real bugs outside the site (chat node, stale README lines) |

## AID run: timeline

| Clock (UTC, approx.) | Phase | Total cost | Notes |
|---|---|---|---|
| 18:15 | describe: name question, interview, requirements approved | $0.75 | asked in numbered-choice form; `/aid-define` not chained, the user must type it |
| 18:20 | define: 6 features proposed and accepted | $2.14 | "six features is a good size" |
| 18:26-19:07 | specify: 6 specs, cross-reference cycles, reviews | ~$36 | 14 helper agents by 19:07 |
| 19:07-20:30 | plan and detail: 4 deliveries, 49 tasks, review cycles | ~$56 | stopped on the maintainer's usage limit at 20:29 |
| 21:24-22:16 | detail finished after resume; task list reviewed | ~$65 | |
| 22:16-22:48 | execute, delivery 1: tasks 1-3 done, task 4 cut off | $86.97 | the last turn alone cost $22.29 with 19 helper agents |
| 22:48-23:00 | resumed (my driver stopped it wrongly); task 4 done | $86.97+ | delivery 1 = 4 tasks: a facts script plus a test helper and a test suite |
| 23:00-23:16 | delivery 1 gate passed (grade A); delivery 2 started, task 5 done | n/a mid-turn | the gate's recorded timestamp is 2026-10-27T01:00:00Z, two hours in the future: an invented value in the state file |
| 23:16-23:32 | delivery 2: tasks 6-8 done (page cut-over with redirects, a shared diagram component, three pipeline diagrams) | n/a mid-turn | pace about 3 tasks per 15 min; 8 of 49 done |
| 23:32-23:50 | delivery 2: tasks 9-10 done (diagrams D3-D9) | n/a mid-turn | task 9's review caught two wrong facts in the diagrams and they were fixed in a second commit: a real, result-changing finding. Task 9 also removed an image ("Iron Man") the request did not mention |
| 23:50-00:08 | delivery 2: tasks 11-14 done (glossary anchors and audit, Home / What is AID / Install / first-work pages audited and rewritten) | n/a mid-turn | task 13 needed a second, fix commit (the home page's full path must start at discover for existing code): another review catch on content. Task 12 added an "audit-checks helper": more test machinery |

## AID run: red tape observed so far

- Planning documents: REQUIREMENTS.md 2,675 lines, PLAN.md 429, a site audit 199, 12 briefs, 49 task DETAIL.md
  files (5,202 lines). About 8,500 lines before the first line of site code; the site's own content is 9,090 lines.
- Review cycles on documents: specify 2 cycles, cross-reference 2 cycles, plan 2 cycles, detail 2 cycles plus a fix
  brief. Grades seen in the session: D, D+, C, C+, B+, A, A+ (details to be read from the transcript).
- State writes: 44 writer calls before execute, 52 by task 4. The work's `lifecycle_history` still holds only its
  template row ("Work created", 2026-01-01): the tracking the rules demand is not actually kept.
- `review-cost.tsv` records one row, with zero bytes.
- Delivery 4 plans "lean tests" after delivery 3 cuts the machinery: tests are cut and re-added in one work.

## AID run: planning phase, analysed (site-run-analysis-planning.md)

- Planning cost about $84 (7.3 times the plain run's whole job) and 3 h 13 min of active time; 42 helper runs
  (24 writers, 18 reviewers); about 89,000 words of planning text.
- 18 reviews and 8 fix runs found 98 problems. Only about 5 would have changed the published site. The rest: 25
  checks or limits AID wrote for itself that could not run, 22 bookkeeping, 17 contradictions between its own
  documents, 15 missing coverage, 11 wording, 8 wrong claims about the repo.
- 11 helpers were cut off when the main agent ended a turn; 8-20% of helper spend was lost or redone.
- 6 approvals, all answered "take your recommendation": no information gained. Describe asked no interview question.
- Invented: numeric limits (300 lines, 60%, 150 KB), dropping release notes, removing copy buttons and the font.
  Scope creep: KB updates, a "safety proof" feature. Weakened: skill pages cut to facts, their diagrams deleted rather
  than redrawn. "Lean tests" re-add about 40 checks and two dependencies the requirements had listed for removal.

## Still to record

- Execute: per-task cost and time, review cycles per task, findings by type, fix rounds, gates.
- End result, graded like the plain run; cohesion with the request; a blind design review of both sites.
