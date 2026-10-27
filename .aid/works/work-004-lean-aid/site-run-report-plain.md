# Site rework without AID (plain run): run report

The plain arm of the site benchmark, run before the AID arm, from the same commit (`71b16c35f`) and with the same
request: rework the product site `site/` completely, check every page against the current skills, give it a modern,
accessible look, and cut its machinery. AID was removed from the copy first (rules, skills, agents, runtime; the
Knowledge Base stayed as plain project documents). Driven headless by `tests/measure/repo_task.py`. Model
`claude-sonnet-5-5` for the main session and its helpers. All times are UTC, 26 October 2026.

Sources: the run's session transcript (1 main session, 7 helper sessions, every message with its timestamp and token
counts), the driver's record, and the result branch `work-004-site-plain` (the run left its changes uncommitted; they
were committed afterwards, unchanged, so they could be kept).

## How cost is counted

| Figure | Value | What it is |
|---|---|---|
| Reported by the CLI | **$11.52** | The session's own running total. Complete here: no turn was killed |
| Priced from tokens at list prices | $23.39 | Every message at list rates (Sonnet $3/$15 per million input/output tokens, cache reads at 10%, cache writes at 125%) |
| Ratio | 0.493 | Used only to split the reported $11.52 across stages in the "Estimated $" columns |

The list-price count overstates the CLI's figure in both runs (ratio 0.49 here, 0.56 in the AID run, which also used
Opus and Haiku). The two reports use the same list prices, so their list-price columns compare directly.

## Summary

| Measure | Value |
|---|---|
| Wall-clock time | 17:39:31 to 18:03:59, 24 min 28 s |
| Active time | 24 min 28 s (no pause over 10 minutes) |
| Of that, lost | about 5 min of waiting after the last helper had finished (see "Stages") |
| Cost | $11.52 |
| Helper sessions | 7, all general-purpose, all Sonnet, all started within 49 seconds of each other |
| User turns | 2: the request, and one "go on" from the driver |
| Questions asked / approvals | 0 / 0 |
| Commits | 0: it offered to commit when the maintainer was happy |
| Tokens (all sessions) | 337k output, 44.1M cache read, 1.36M cache write |
| Change | 248 files, +6,609 / -70,053 lines (5 `docs/` files and the docs workflow included) |

## Time and cost by stage

| Stage | Start | End | Time | Main session | Helpers | List $ | Estimated $ | Share |
|---|---|---|---|---|---|---|---|---|
| 1. Read the repo and plan | 17:39:31 | 17:43:20 | 3 min 49 s | 22 messages | 0 | 1.28 | 0.63 | 5.5% |
| 2. Build in parallel: 7 helpers write pages and data; the main session writes the theme, diagram components, generator and tests | 17:43:20 | 17:49:59 | 6 min 39 s (helpers ran to 17:54:40) | 21 messages | 7 | 20.02 | 9.86 | 85.6% |
| 3. Wait for the helpers | 17:49:59 | 17:59:57 | 9 min 58 s | 1 message | (running to 17:54:40) | 0.06 | 0.03 | 0.3% |
| 4. Build, test, fix (broken anchors, a generator bug, the lockfile, one stale claim in the docs) | 17:59:57 | 18:03:20 | 3 min 23 s | 22 messages | 0 | 1.69 | 0.83 | 7.2% |
| 5. Second turn ("go on"): one more stale claim fixed, final summary | 18:03:20 | 18:03:59 | 39 s | 4 messages | 0 | 0.33 | 0.16 | 1.4% |
| **Total** | 17:39:31 | 18:03:59 | **24 min 28 s** | **70 messages** | **7** | **23.39** | **11.52** | 100% |

Stage 3 was a polling loop that waited for the helpers' files. The last helper finished at 17:54:40, but the loop ran
on for about 5 more minutes until the agent stopped it.

## The seven helpers

| Helper | Start | End | Time | List $ | Estimated $ | What it wrote |
|---|---|---|---|---|---|---|
| Skills data A (21 skills) | 17:43:24 | 17:48:30 | 5 min 06 s | 2.30 | 1.13 | Per-skill facts for the generated skill pages |
| Skills and agents data B | 17:43:32 | 17:47:43 | 4 min 11 s | 1.72 | 0.85 | The other skills and the agents |
| Get started pages | 17:43:41 | 17:53:24 | 9 min 43 s | 2.03 | 1.00 | What is AID, install, first change, first project |
| Guides and KB pages | 17:43:51 | 17:51:41 | 7 min 50 s | 3.64 | 1.79 | Guides and the Knowledge Base page |
| CLI, settings, dashboard, chat pages | 17:43:58 | 17:54:40 | 10 min 42 s | 4.82 | 2.37 | Reference pages |
| Audit the methodology doc in place | 17:44:06 | 17:48:21 | 4 min 15 s | 1.61 | 0.79 | Fixes to `docs/aid-methodology.md` |
| Audit FAQ, glossary, repository docs | 17:44:13 | 17:49:39 | 5 min 26 s | 1.81 | 0.89 | Fixes to `docs/faq.md`, `docs/glossary.md` and others |
| **All helpers** | | | | **17.93** | **8.83** | 77% of the spend |

## Where the money went

| By role | List $ | Estimated $ | Share | What it did |
|---|---|---|---|---|
| Helpers (page and data writers, doc auditors) | 17.93 | 8.83 | 77% | Wrote the site's content and fixed stale repo docs |
| Main session | 5.46 | 2.69 | 23% | Read the repo, wrote the theme, components, generator and 15 checks, built, tested, fixed |

Almost all of the spend changed the site or its source documents. There were no planning documents, no review
helpers and no state files.

## What it did not do

| Gap | Effect on the result |
|---|---|
| It never looked at the rendered pages: the browser tool's permission was declined in the headless run, and it checked the HTML by script instead | 42 markdown tables render as raw text on 11 pages: the main visible defect both blind reviews found |
| No independent check of the helpers' claims against the repo | 3 stale statements copied from the repo's own outdated docs (impediment file name, citation rule, diagrams without a gate after every phase) |

## Compared with the AID run

| | Plain | AID | Ratio |
|---|---|---|---|
| Time | 24 min 28 s | about 11 h 10 min active | about 27× |
| Cost (CLI-based) | $11.52 | about $178 | about 15.5× |
| Cost at list prices | $23.39 | $316.31 | about 13.5× |
| Helper sessions | 7 | 151 | 22× |
| Questions and approvals | 0 | 6 approvals | |
| Share of spend that changed the site | about 100% | 18% | |
| Result quality | two blind reviews: a tie overall (see `site-run-notes.md`) | | |

The two gaps above are exactly what AID's delivery gates and claim checks caught in its own run. Both are cheap to
add: one look at the rendered result and one claims-against-repo pass.
