# Measurements

Runs of `tests/measure/measure.py` on the maintainer's machine, model `claude-sonnet-5-5`, AID as on `master`
(v3.1.3). One run each so far.

## Plain request (no slash command), 2026-10-26

| Scenario | AID | Cost | Seconds | Agent turns | Cache write tokens | Cache read tokens | Output tokens | Dispatches | Writer calls | Code files changed | Tests |
|---|---|---|---|---|---|---|---|---|---|---|---|
| fix | yes | $0.37 | 23 | 12 | 38,316 | 358,204 | 2,131 | 0 | 0 | 4 | pass |
| fix | no | $0.22 | 30 | 11 | 20,679 | 189,462 | 3,232 | 0 | 0 | 3 | pass |
| feature | yes | $0.20 | 20 | 16 | 35,715 | 267,119 | 2,580 | 0 | 0 | 3 | pass |
| feature | no | $0.09 | 15 | 11 | 14,902 | 133,922 | 1,690 | 0 | 0 | 2 | pass |

With a plain request the agent ran no AID process. AID's cost here is its always-loaded context: about 17-21k
more tokens written to cache per session, re-read on every turn, so 1.7-2.2 times the cost.

## Typed `/aid-fix`, same bug, 2026-10-26

Turn 1 was the request; turn 2 ("Yes, go ahead") was still running after 30 minutes when the harness stopped it.
Totals from the run's own session logs (main session plus 15 sub-agent logs):

| Measure | `/aid-fix` (unfinished) | Plain request, no AID |
|---|---|---|
| Time | over 31 minutes, not finished | 30 seconds |
| Code changed | none (the engine plans; building is a separate `/aid-execute`) | 3 files, tests pass |
| Sub-agent dispatches | 15 | 0 |
| Assistant messages | 433 | 11 agent turns |
| Output tokens | 503,818 | 3,232 |
| Cache read tokens | 20,695,768 | 189,462 |
| Cache write tokens | 1,752,272 | 20,679 |
| Writer calls | 11 | 0 |
| Files produced | REQUIREMENTS.md, STATE.yml, 2 task DETAIL.md files, in a new worktree | the fix |
| Cost | ESTIMATE about $24 or more (see below) | $0.22 measured |

Cost basis: the plain AID run's measured $0.37 is matched by $0.30 per million cache-read tokens, $6 per million
cache-write tokens and $15 per million output tokens; the same rates on the `/aid-fix` totals give about $24.
Sub-agents on a pricier model would raise it. So the typed skill path cost on the order of 100 times the plain
request and over 60 times the time, and had not changed any code when it was stopped.
