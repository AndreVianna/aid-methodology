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
| 00:08-00:25 | delivery 2: tasks 14-15 done (first-work, shortcuts and Guides pages) | n/a mid-turn | both tasks needed a fix commit after review: one wrong claim about the shortcut engine, and a Guides rewrite that had dropped real facts (dashboard worktree merge, PyPI publishing condition). Pattern so far: on content tasks the review catches real errors about half the time |
| 00:25-00:43 | delivery 2: tasks 16-17 done (Concepts landing, pipeline, KB and Agents pages) | n/a mid-turn | task 16 took three commits (page, two diagram corrections, then review fixes); task 17 two. 6 of the last 8 content tasks needed at least one fix commit |
| 00:49 | resumed again: my driver allowed 2 h per turn, and AID ran tasks 5-18 inside one turn | unknown | a killed turn reports no cost; that turn's cost will be estimated from the transcript tokens |
| 00:49-01:00 | delivery 2: task 18 done, task 19 in review (feedback loops, AID vs SDD, case studies, FAQ) | n/a mid-turn | task 18 needed a redraw of a diagram "with sourced facts only": the first version had unsourced claims |
| 01:00-01:17 | delivery 2: task 19 done, task 20 in review (FAQ, Reference overview, CLI commands, KB documents) | n/a mid-turn | task 19 needed a fix commit after review; pace has slowed to about 1 task per 15 min on the bigger audit tasks |
| 01:17-01:34 | delivery 2: tasks 20-21 done, task 22 in review (CLI, artifacts, repository structure, Contact) | n/a mid-turn | tasks 20 and 21 each needed a fix commit after review; content tasks with a fix commit so far: 10 of 14 |
| 01:38 | the cloud container restarted and killed the run (22 tasks done, task 23 in progress); resumed in the same session | unknown | a second killed turn whose cost must be estimated from the transcript |
| 01:38-01:50 | after the restart the first turn only reported progress (22 of 49) and ended; the driver said go on | $87.19 reported | the reported session total does not include the two killed turns (tasks 5-22): the real spend is higher and will be estimated from tokens |
| 01:50-02:10 | stuck on task 23: each turn the main agent resumed the task's helper by message, then ended its turn, and the helper was stopped with it (cut off 3 times, nothing committed). Driver restarted at 02:10 telling it to wait for its helpers | $87.57 reported | design point: AID hands work to background helpers and ends the turn; whenever the session ends (headless run, closed window, restart), the helpers die and their work is redone. Same cause as the 11 helpers lost in planning |
| 02:10-02:26 | task 23 (delivery 2's gate checks) done and recorded; the delivery 2 gate reviewer started | $93.27 reported | the turn still ended with "I'm waiting for its verdict": told to wait for helpers, it still handed off and ended the turn |
| 02:26-02:43 | delivery 2 gate review found more mismatches after all the per-task reviews; two gate fix commits (diagrams against the skills, pages against the code) | $93.27+ | the per-task reviews did not catch everything: cross-page consistency only shows when the delivery is checked as a whole. This turn kept working instead of ending |
| 02:43-02:59 | delivery 2 gate passed; delivery 3 (new look and machinery cut) started: tasks 24-26 done (design tokens and stylesheet, header, social links and copy buttons) | $93.27+ | it wrote "executor brief lessons" between deliveries: more process text. Pace back to 3 tasks per 15 min while it works in one turn |
| 02:59-03:15 | delivery 3: tasks 27-32 done (version from VERSION, network-free changelog, old generators, flow data and legacy tests deleted, generated pages made hand-written, no-JavaScript contact form) | $93.27+ | the machinery cut happened here; fastest stretch so far, 5-6 tasks in 15 min |
| 03:15-03:32 | delivery 3: tasks 32-34 done (contact forms, dependencies pruned and lockfile regenerated, keyboard check and responsive screenshots) | $93.27+ | task 32 needed three commits; the last fixed the contact link's subject encoding, the very defect the planning review had already flagged: knowing about it in the spec did not stop the build from getting it wrong first |
| 03:32-03:49 | delivery 3: task 35 (gate checks) done; delivery 3 gate review running | $93.27+ | 35 of 49 done; delivery 4 ("lean tests, workflow and safety proof", 14 tasks) is next |

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
