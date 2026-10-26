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
