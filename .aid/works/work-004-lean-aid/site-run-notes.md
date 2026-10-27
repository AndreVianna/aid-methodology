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
| Result (graded) | builds (62 pages); 0 stale command names, 3 invented ones (`/aid-add-api`, `/aid-change-ui`, `/aid-tool`); 0 broken links; 0 pages with serious accessibility issues (first graded 34: a grader timing error, see Grading correction); generator code 11,289 -> 278 lines, site tests 30,917 -> 0 |
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
| 03:49-04:06 | delivery 3 gate found two more problems, fixed in two commits: pipe tables were not rendering in the MDX pages, and the header, footer link and contact wording | $114.40 reported | the turn that ran from delivery 2's gate to here cost $21.13 with 30 helper runs, and again ended on "I'm waiting for its verdict". The table bug is a real, visible defect found only by checking the built result |
| 04:06-04:22 | still in delivery 3's gate: a third gate fix (code broken mid-word in table cells) | $114.40+ | the gate is iterating: three fix commits so far, each a real visual defect |
| 04:22-04:39 | delivery 3 gated (grade A+); delivery 4 started: tasks 36-37 add an accessibility test and a colour-contrast test | $114.40+ | the re-adding of tests has begun, right after the machinery cut |
| 04:39-04:56 | delivery 4: tasks 38-39 done (build and link tests; page and component fixes for what the new suite found) | $114.40+ | the new accessibility and link tests found real defects in pages that delivery gates had graded A and A+: the automated checks caught what the reviews missed |
| 04:56-05:13 | delivery 4: tasks 40-44 done (keyboard check and screenshots re-recorded, reduction measured, docs workflow edited, KB documents updated) | $114.40+ | 44 of 49 done. Scope creep landing: KB documents (test landscape, module map, architecture, glossary, project card) edited, which the request never asked for |
| 05:13-05:30 | delivery 4: tasks 45-48 done (more KB documents, KB debt register, site audit completed, a commit just for state writes); task 49 in progress | $114.40+ | 48 of 49. Four of the last five tasks were KB edits or bookkeeping (task 48 exists only to commit state files) |
| 05:30-05:47 | all 49 tasks done (task 49: delivery 4 gate checks and a final sweep of AC-1 to AC-15); the delivery 4 gate review is running | $114.40+ | 79 commits in all |
| 05:47-06:03 | delivery 4 gated (grade A+, one gate fix); the work ended asking the user to merge or open a pull request | $134.43 reported | the closing message asked "merge or PR?"; my driver answered it 32 more times at $0.02 each before I stopped it at 06:07 |

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

## AID run: cost estimate

The reported session total misses the two turns that were killed. Pricing every helper and main-session message from
the transcripts (152 files, 4,593 messages; Sonnet, Opus and Haiku list prices) gives $309.52 by 05:48, half of it on
Opus helpers. Calibrated against the reported total at 22:48 (reported $86.97 against $154.33 token-priced, ratio
0.56), the best estimate of the whole run is **about $175**, with the reported $114 a floor and $310 a ceiling.

Final, from the one session transcript (330 files, 151 helper runs), with Opus priced at its own rate: $314 token-priced
($186 helpers: architect $64, reviewer $64, tech writer $33, developer $25; $69 main session at Sonnet rates); the
reported total is $135.07; calibrated, **about $176**. Active time about 10.5 h (18:15 to 06:03, less the 55-minute
usage-limit stop), against 24.6 min plain.

## AID run: execute phase

- 49 tasks, 49 Done; 79 commits: 49 task commits, 15 fix commits on tasks, 8 delivery-gate fix commits, 7 state commits.
- 13 of 49 tasks needed a fix commit after review (10 of 14 content-audit tasks). Gates: delivery 1 none, delivery 2
  four fix cycles, delivery 3 three, delivery 4 one. Every gate fix was a real defect (wrong diagram facts, pages
  against code, tables not rendering, code split mid-word).
- Work folder at the end: 16,513 lines of paperwork for a site whose content is 4,132 lines.

## Grading correction (both runs)

The first plain grade counted 34 pages with serious accessibility issues; all were one rule, scrollable code blocks
not focusable, and the site's own script fixes it a moment after load. The grader now waits 300 ms and skips redirect
pages; its command scan no longer counts file names (`aid-claude-code-vX.Y.Z`, `<tool>/aid-tool.conf`); test files are
counted in `tests/` folders too. Both sites were re-graded with the fixed grader.

## Result, graded

| Measure | Plain | AID |
|---|---|---|
| Builds | yes, 62 pages | yes, 74 pages (5 are redirects from old addresses) |
| Command names | 2 invented (`/aid-add-api`, `/aid-change-ui`), 0 stale | 0 invented, 0 stale |
| Broken internal links | 0 | 0 |
| Pages with serious accessibility issues | 0 of 61 | 0 of 68 |
| Script lines (generators) | 278 (from 11,289) | 271 |
| Test lines | 213 | 619 (build, links, accessibility, contrast, facts) |
| Content lines | 7,048 | 4,132 |
| npm scripts / dependencies | 6 / 4 | 8 / 8 |
| Files changed outside `site/` | 6 (5 docs, CI workflow), uncommitted | 11 (10 Knowledge Base, CI workflow), plus 79 work-folder files |
| Cost | about $11.50 | about $176 (reported $135, ceiling $314) |
| Time | 24.6 min | about 10.5 h |

## Blind design review (independent agent; A = plain, B = AID)

| Criterion | Plain | AID | Reason, short |
|---|---|---|---|
| Modern look and polish | 8 | 6 | plain made a new hero home, cards and logo; AID mostly kept the old theme |
| Diagrams | 6 | 7 | plain drew steps as HTML cards (sequence only); AID drew 10 real diagrams, each with a text version, some dense |
| Layout and navigation | 7 | 7 | plain reorganised; AID kept the old structure |
| Readability | 5 | 7 | plain's raw tables break key pages; AID's skill pages became fact stubs |
| Phone | 7 | 7 | |
| Keyboard and screen reader | 8 | 8 | both: skip link, focus outline, contrast 5.7:1 or better |
| Visible defects | 3 | 8 | plain: 42 tables render as raw `\| --- \|` text on 11 pages; AID: minor diagram crowding |
| Rework compared with the old site | 9 | 5 | plain is a redesign; AID is the old site cleaned up |

Verdict: AID slightly better as shipped (no broken rendering); plain clearly better once its tables are fixed. The
reviewer also called `/aid-triage` stale on both sites: wrong, it is a skill at the starting commit.
Note: plain's broken tables are the same defect AID's delivery 3 gate found and fixed in its own site; my grader has no
check for it, so the automatic grade missed it on plain.
