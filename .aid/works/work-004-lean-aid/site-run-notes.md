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

## AID run: red tape observed so far

- Planning documents: REQUIREMENTS.md 2,675 lines, PLAN.md 429, a site audit 199, 12 briefs, 49 task DETAIL.md
  files (5,202 lines). About 8,500 lines before the first line of site code; the site's own content is 9,090 lines.
- Review cycles on documents: specify 2 cycles, cross-reference 2 cycles, plan 2 cycles, detail 2 cycles plus a fix
  brief. Grades seen in the session: D, D+, C, C+, B+, A, A+ (details to be read from the transcript).
- State writes: 44 writer calls before execute, 52 by task 4. The work's `lifecycle_history` still holds only its
  template row ("Work created", 2026-01-01): the tracking the rules demand is not actually kept.
- `review-cost.tsv` records one row, with zero bytes.
- Delivery 4 plans "lean tests" after delivery 3 cuts the machinery: tests are cut and re-added in one work.

## Still to record

- Execute: per-task cost and time, review cycles per task, findings by type, fix rounds, gates.
- End result, graded like the plain run; cohesion with the request; a blind design review of both sites.
