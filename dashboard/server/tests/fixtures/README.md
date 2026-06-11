# Dashboard test fixtures (PT-1 parity)

**Permanent test data — not work-scoped.** These fixtures back the cross-runtime
byte-parity guarantee for the dual-runtime dashboard servers and must stay committed
(CI runs against them). They are intentionally located beside the dashboard code they
guard, not in the work folder, because they outlive any single work.

## `pt1-aid/`
A synthetic `.aid/` tree exercising every reader path in one snapshot:
- `work-001-running-parallel` — Running, parallel In-Progress tasks across waves
- `work-002-paused` — Paused-Awaiting-Input (+ a pending Q&A)
- `work-003-blocked` — Blocked, with an `IMPEDIMENT-task-005.md` artifact
- `work-004-completed` — Completed
- `work-005-fallback` — no typed `## Pipeline Status` block (fallback derivation)
- `.aid-manifest.json` — carries literal **U+2028 / U+2029** in `aid_version` (mandatory
  per R7: proves both runtimes escape line/paragraph separators to the canonical form).

## `pt1-no-aid/`
A directory with **no** `.aid/` — the empty-repo case.

## Consumers
- `tests/canonical/test-dashboard-parity.sh` (PT-1 byte-parity, runs in CI; `FIXTURE_FULL` / `FIXTURE_EMPTY`)
- `dashboard/server/tests/test_server_py.py` (server SIGTERM/route smoke)

It is also handy for **previewing the dashboard locally**:
`python3 dashboard/server/server.py --root dashboard/server/tests/fixtures/pt1-aid --host 127.0.0.1 --port 8787`
