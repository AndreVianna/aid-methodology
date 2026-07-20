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

## `pt023-connectors/`
Five committed `.aid/connectors/*.md` descriptors (task-023, feature-007-connectors-list)
-- `github.md` (mcp), `jira.md` (api, credentialed), `build-host.md` (ssh, endpoint-only /
auth none), `public-docs.md` (api, auth none), `ci-runner.md` (cli, endpoint-only / auth
none). `url` and `ssh-key` were dropped by the feature-007 schema simplification -- `api` is
now the only credentialed connector type; ssh/cli are endpoint-only (auth forced none).
Confirmed byte-identical to `write-connector.sh`'s own real output; used as a shared golden
fixture set by both
`dashboard/reader/tests/test_task023_list_management_parity.py` (parser cross-twin parity)
and `dashboard/server/tests/test_task023_list_management_round_trips.py` (real-writer
round-trip / DM-1 serializer assertions).

## `pt023-external-sources/`
Three committed `.aid/knowledge/external-sources.md` states (task-023,
feature-010-external-sources-list) — `placeholder-only.md` (discovery seed, no real
entries), `single-entry.md` (one real source), `multi-entry.md` (three real sources plus a
hand-authored trailing note in the `## Sources` body, exercising byte-preservation of
non-managed content). Shared by the same two consumers as `pt023-connectors/` above.

## Consumers
- `tests/canonical/test-dashboard-parity.sh` (PT-1 byte-parity, runs in CI; `FIXTURE_FULL` / `FIXTURE_EMPTY`)
- `dashboard/server/tests/test_server_py.py` (server SIGTERM/route smoke)
- `dashboard/reader/tests/test_task023_list_management_parity.py` (`pt023-connectors/`, `pt023-external-sources/`)
- `dashboard/server/tests/test_task023_list_management_round_trips.py` (`pt023-connectors/`, `pt023-external-sources/`)

It is also handy for **previewing the dashboard locally**:
`python3 dashboard/server/server.py --root dashboard/server/tests/fixtures/pt1-aid --host 127.0.0.1 --port 8787`
