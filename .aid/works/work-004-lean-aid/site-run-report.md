# Site rework through today's AID: run report

One run of today's full AID pipeline (`/aid-describe` to the last delivery gate) on one request: rework the product
site `site/` completely, check every page against the current skills, give it a modern, accessible look, and cut its
machinery. Driven headless by `tests/measure/repo_task.py`; every question got the reply "Yes, go ahead. Take your
recommendation for anything else." Model `claude-sonnet-5-5` for the main session; helpers used the models their
agent files name (Opus, Sonnet, Haiku). All times are UTC, 26-27 October 2026.

Sources: the run's session transcript (1 main session, 151 helper sessions, every message with its timestamp and
token counts) and the git history of the result branch `work-004-site-aid` (79 commits).

## How cost is counted

| Figure | Value | What it is |
|---|---|---|
| Reported by the CLI | $135.07 | The session's own running total. Too low: it misses two turns that were killed (a driver time limit and a container restart), which covered most of delivery 2 |
| Priced from tokens at list prices | $316.31 | Every message priced at list rates (Sonnet $3/$15, Opus $5/$25, Haiku $1/$5 per million input/output tokens, cache reads at 10%, cache writes at 125%) |
| Calibration ratio | 0.564 | At 22:48, before any turn was killed, the CLI reported $86.97 where the list-price count gave $154.33 |
| **Best estimate** | **about $178** | List-price count × 0.564. Used in every "estimated $" column below |

For comparison, the plain run (no AID, same request, same commit): **$11.52 and 24.6 minutes**.

## Summary

| Measure | Value |
|---|---|
| Wall-clock time | 18:09 to 06:06, 11 h 57 min |
| Active time (pauses over 10 minutes removed) | about 11 h 10 min |
| Of that, lost to incidents | about 45 min (see "Incidents") |
| Estimated cost | about $178 (15.5 times plain) |
| Helper sessions | 151: 24 architect, 69 reviewer, 39 developer, 19 tech writer |
| Tasks | 49, all Done |
| Commits | 79 (49 task, 15 task-fix, 8 gate-fix, 7 state) |
| User replies | 6 approvals during the run, all "take your recommendation", plus driver "go on" turns |

## Time and cost by phase

| Phase | Start | End | Wall | Active | Helpers | List $ | Estimated $ | Share |
|---|---|---|---|---|---|---|---|---|
| Describe (requirements) | 18:09 | 18:13 | 4 min | 4 min | 0 | 1.46 | 0.82 | 0.5% |
| Define (6 features) | 18:13 | 18:19 | 6 min | 6 min | 2 | 2.24 | 1.26 | 0.7% |
| Specify (6 specs) | 18:19 | 19:25 | 66 min | 66 min | 17 | 65.35 | 36.83 | 20.7% |
| Plan (4 deliveries) | 19:25 | 19:41 | 16 min | 16 min | 4 | 8.08 | 4.55 | 2.6% |
| Detail (49 tasks) | 19:41 | 22:11 | 150 min | 101 min | 19 | 71.63 | 40.36 | 22.6% |
| **Planning subtotal** | | | **4 h 02 min** | **3 h 13 min** | **42** | **148.76** | **83.83** | **47.0%** |
| Execute, delivery 1 (tasks 1-4) | 22:11 | 23:06 | 55 min | 55 min | 9 | 9.22 | 5.20 | 2.9% |
| Execute, delivery 2 (tasks 5-23) | 23:06 | 02:50 | 224 min | 224 min | 44 | 91.38 | 51.49 | 28.9% |
| Execute, delivery 3 (tasks 24-35) | 02:50 | 04:24 | 95 min | 95 min | 27 | 39.28 | 22.13 | 12.4% |
| Execute, delivery 4 (tasks 36-49) | 04:24 | 06:03 | 99 min | 99 min | 29 | 25.75 | 14.51 | 8.1% |
| **Execute subtotal** | | | **7 h 53 min** | **7 h 53 min** | **109** | **165.63** | **93.33** | **52.4%** |
| Closing (the run asked "merge or PR?" and the driver kept answering) | 06:03 | 06:06 | 3 min | 3 min | 0 | 1.91 | 1.08 | 0.6% |
| **Total** | 18:09 | 06:06 | **11 h 57 min** | **11 h 10 min** | **151** | **316.31** | **178.24** | 100% |

Detail's 49 inactive minutes are the maintainer's usage-limit stop (20:22 to 21:12).

## Where the money went

| By role | Runs | List $ | Estimated $ | Share | What it did |
|---|---|---|---|---|---|
| Architect (Opus) | 24 | 107.15 | 60.39 | 33.9% | Wrote specs, plan and task files, and fixed review findings on them; all in planning |
| Reviewer (Opus, Sonnet, Haiku) | 69 | 82.06 | 46.25 | 25.9% | Document reviews in planning; a quick check per task; one gate review per delivery |
| Main session (Sonnet) | 1 | 69.10 | 38.94 | 21.8% | Orchestration: dispatching, state writes, commits, resuming helpers |
| Tech writer (Sonnet) | 19 | 33.16 | 18.69 | 10.5% | Page audits and rewrites, KB edits |
| Developer (Sonnet) | 39 | 24.89 | 14.03 | 7.9% | Code, diagrams, tests, fixes |

Only the tech writer and developer runs changed the site: **18% of the spend**. Planning documents and their reviews
took 47%, orchestration 22%.

| By model (helpers only) | List $ | Share of helper spend |
|---|---|---|
| Opus | 153.53 | 62% (all architect runs and the delivery 2, 3 and 4 gate reviews) |
| Sonnet | 84.80 | 34% |
| Haiku | 8.93 | 4% (the per-task quick checks) |

## Planning in detail

| Time | Helper run | Model | List $ |
|---|---|---|---|
| 18:15-18:19 | 2 cross-reference reviews of the requirements | Sonnet | 0.56 |
| 18:21-18:33 | Write specs, all six features | Opus | 7.99 |
| 18:34-18:44 | Specs written again, in three pairs (3 runs) | Opus | 15.49 |
| 18:44-18:57 | Specs 003-006 written again, one per run (4 runs) | Opus | 19.96 |
| 18:58-19:06 | Spec review, cycle 1 (3 runs) | Sonnet | 6.62 |
| 19:07-19:20 | Fix spec findings (2 runs) | Opus | 9.48 |
| 19:21-19:25 | Spec review, cycle 2 (3 runs), then fix the last two findings | Sonnet, Opus | 2.27 |
| 19:26-19:41 | Write the plan, review it, fix it, review again (4 runs) | Opus, Sonnet | 6.54 |
| 19:41-21:42 | Write task files: deliveries 1-2, delivery 1 again, delivery 2 three more times, then deliveries 3 and 4 (7 runs) | Opus | 32.03 |
| 21:44-21:55 | Task review, cycle 1 (4 runs) | Sonnet | 10.97 |
| 21:55-22:07 | Fix task findings (4 runs) | Opus | 16.97 |
| 22:07-22:11 | Task review, cycle 2 (4 runs) | Sonnet | 3.85 |

The specs were written three times over and delivery 2's tasks four times. A helper started near the end of a main
turn was stopped when the turn ended, and its work was redone. Estimated redone work: about $25-35 at list prices
($14-20 estimated).

## Execute in detail

| Delivery | Tasks | Time | Estimated $ | Tasks needing a fix commit | Gate review | Gate fix commits | Grade |
|---|---|---|---|---|---|---|---|
| 1: facts script and its tests | 4 | 55 min | 5.20 | 0 | 16 min, Sonnet, $1.19 list | 0 | A |
| 2: page cut-over, diagrams, page audits | 19 | 3 h 44 min | 51.49 | 10 | 40 min, Opus, $21.31 list | 4 | A+ |
| 3: new look, machinery cut | 12 | 1 h 35 min | 22.13 | 2 | 36 min, Opus, $13.56 list | 3 | A+ |
| 4: tests, workflow, KB edits | 14 | 1 h 39 min | 14.51 | 1 | 25 min, Opus, $11.50 list | 1 | A+ |

Every gate fix was a real defect the per-task checks had missed: diagram facts against the skills, pages against the
code, pipe tables not rendering, the header, code split mid-word in table cells, a spec sentence against the code.

### Per task (helper cost only: executor plus quick check plus any fix run; orchestration is not split per task)

| # | Done at | Commits | List $ | Task |
|---|---|---|---|---|
| 1 | 22:16 | 1 | 0.34 | Site package scripts without build-time regeneration |
| 2 | 22:19 | 1 | 0.48 | Shared built-site test helper |
| 3 | 22:24 | 1 | 0.99 | Facts script and its committed pages |
| 4 | 22:49 | 1 | 0.94 | Facts check test suite |
| 5 | 23:11 | 1 | 1.50 | Methodology page split into the Concepts pages |
| 6 | 23:17 | 1 | 0.56 | Page-set cut-over: stubs removed, redirects, final sidebar |
| 7 | 23:25 | 1 | 0.50 | Shared diagram component |
| 8 | 23:32 | 1 | 1.46 | Pipeline diagrams D1, D2, D10 |
| 9 | 23:41 | 2 | 1.30 | Concepts diagrams D3-D6 (fix: two false facts) |
| 10 | 23:48 | 1 | 2.36 | Diagrams D7-D9 |
| 11 | 23:51 | 1 | 0.27 | Mermaid integration removed |
| 12 | 23:56 | 1 | 1.64 | Glossary anchors and audit, audit-checks helper |
| 13 | 00:02 | 2 | 1.35 | Home, What is AID, Install pages |
| 14 | 00:09 | 2 | 1.88 | First work and shortcuts pages |
| 15 | 00:21 | 2 | 5.72 | Guides pages (fix: restored dropped facts) |
| 16 | 00:33 | 3 | 3.73 | Concepts landing and pipeline pages |
| 17 | 00:42 | 2 | 2.32 | Knowledge Base and Agents pages |
| 18 | 00:54 | 2 | 2.88 | Feedback loops and AID-and-SDD pages (fix: diagram redrawn with sourced facts) |
| 19 | 01:03 | 2 | 2.73 | Case studies and FAQ pages |
| 20 | 01:17 | 2 | 6.11 | Reference overview, CLI, KB documents pages |
| 21 | 01:29 | 2 | 4.32 | Artifacts and repository structure pages |
| 22 | 01:32 | 1 | 1.04 | Contact pages, generated-page audit rows |
| 23 | 02:09 | 1 | 0.89 | Delivery 2 gate checks (stuck 30 min, see "Incidents") |
| 24 | 02:52 | 1 | 0.78 | Design tokens and stylesheet |
| 25 | 02:55 | 1 | 0.54 | One-row header |
| 26 | 02:57 | 1 | 0.24 | Social links, copy buttons |
| 27 | 03:02 | 2 | 0.96 | Tabs turned into sections |
| 28 | 03:05 | 1 | 0.58 | Version from VERSION, offline changelog |
| 29 | 03:07 | 1 | 0.19 | Skill node panel removed |
| 30 | 03:08 | 1 | 0.48 | Old generators, flow data, legacy tests deleted |
| 31 | 03:11 | 1 | 0.51 | Generated pages made hand-written |
| 32 | 03:26 | 3 | 1.31 | No-JavaScript contact form (two fixes, one for a defect the planning review had already flagged) |
| 33 | 03:18 | 1 | 0.29 | Dependencies pruned, lockfile regenerated |
| 34 | 03:23 | 1 | 0.83 | Keyboard check, responsive screenshots |
| 35 | 03:39 | 1 | 0.72 | Delivery 3 gate checks |
| 36 | 04:57 | 2 | 2.03 | Accessibility test suite |
| 37 | 04:38 | 1 | 1.08 | Contrast test |
| 38 | 04:40 | 1 | 0.58 | Build and link tests |
| 39 | 04:43 | 1 | 0.68 | Fixes for what the new tests found |
| 40 | 05:00 | 1 | 0.54 | Keyboard check and screenshots re-recorded |
| 41 | 05:03 | 1 | 0.58 | Reduction measured |
| 42 | 05:06 | 1 | 0.49 | Docs workflow edited (never run) |
| 43 | 05:08 | 1 | 0.52 | KB: test landscape |
| 44 | 05:11 | 1 | 0.76 | KB: module map, architecture |
| 45 | 05:13 | 1 | 0.63 | KB: stack, infrastructure |
| 46 | 05:16 | 1 | 1.06 | KB: debt register, KB sweep |
| 47 | 05:19 | 1 | 0.60 | Site audit completed |
| 48 | 05:21 | 1 | 0.25 | Commit of state files only |
| 49 | 05:37 | 1 | 1.64 | Delivery 4 gate checks, final criteria sweep |

The nine page-audit tasks (13-21) were the most expensive, $1.35-$6.11 each, and 7 of them needed a fix commit. Tasks
43-46 and 48 (KB edits and a state-only commit) were not asked for by the request.

## Incidents

| Time | What happened | Lost |
|---|---|---|
| 20:22-21:12 | The maintainer's usage limit stopped the run | 49 min (not counted as active) |
| 22:37-22:48 | My driver stopped the run by mistake; resumed | about 11 min |
| 00:47-00:50 | My driver's 2-hour turn limit killed a long turn; its cost went unreported | about 3 min |
| 01:32-01:39 | The cloud container restarted and killed the run; resumed | about 7 min |
| 01:39-02:09 | Stuck on task 23: each turn the main session resumed a helper and then ended its turn, which stopped the helper; nothing committed 3 times | about 30 min |
| 06:03-06:06 | The run ended by asking "merge or PR?"; the driver answered it 32 times | 3 min, $1.91 list |

## Compared with the plain run

| | Plain | AID | Ratio |
|---|---|---|---|
| Time | 24.6 min | about 11 h 10 min active | about 27× |
| Cost | $11.52 | about $178 | about 15.5× |
| Helper sessions | 7 | 151 | 22× |
| Result quality | two blind reviews: a tie overall (see `site-run-notes.md`) | | |

Where AID's extra spend paid off: the delivery gates and the checks of claims against the repo ($46 list for the
three Opus gate reviews, $9 for the per-task quick checks). Where it did not: planning documents rewritten and reviewed in
cycles (47% of the spend), and orchestration (22%).
