# task-021: feature-004 aid dashboard start/stop in bin/aid (Bash) + --remote clear-fail stub

**Type:** IMPLEMENT

**Source:** feature-004-cli-dashboard-control → delivery-002

**Depends on:** task-014, task-016, task-017

**Scope:**
- Implement `_cmd_dashboard_ctl` in the hand-maintained root `bin/aid` (Bash) — NOT a `canonical/`→render artifact (LC-4): the `dashboard start <node|python> [--remote] [--port <n>] [--target <dir>] [--verbose]` and `dashboard stop` verbs (CLI-1 grammar).
- `start` flow (Feature Flow): parse args; resolve target; check `.aid/`/assets; already-running guard via `.aid/.temp/dashboard.pid` (DM-1) with PID liveness re-verify (`kill -0`) + stale-record reclaim (DM-3); runtime-availability check; locate the LC-1 entry point (task-014; `server.py`/`server.mjs`); spawn via `setsid` bound to `127.0.0.1:<port>` (SEC-1, default 8787, DM-2); bounded readiness wait; write the PID record; print the local URL.
- `stop` flow: read record; absent/dead → "nothing to stop" exit 0 (idempotent, DM-3); tear down `--remote` first if present; kill the process group cleanly; remove record+logfile.
- `--remote` is a CLEAR-FAIL STUB here (exit 10, "mechanism not available; local server still running at http://127.0.0.1:<port>") — the real LC-2 expose is delivery-003 (task-024); the server is bound local-only BEFORE remote is attempted so a `--remote` failure NEVER binds public (SEC-2/C1).
- Add the `dashboard` dispatch branch before the `add|remove|update` validation (LC-3); add the help line + `dashboard)` help arm (CLI-4). Bare `aid`/`_cmd_dashboard` untouched (C4). Exit codes per CLI-2 (0/2/3/7/8/9/10). ASCII-only error/help text (LC-4). Refresh vendored copies via the prepack vendor step (do not hand-edit copies).

**Acceptance Criteria:**
- [ ] `aid dashboard start node|python` spawns the LC-1 server bound `127.0.0.1:<port>`, writes a correct `dashboard.pid` record, and prints the local URL (exit 0); `aid dashboard stop` kills the child + removes the record (exit 0).
- [ ] The already-running guard exits 8; a stale (dead-PID) record is reclaimed on `start`; `stop` with nothing running is idempotent exit 0; port-in-use exits 3; missing runtime exits 9; no `.aid/`/assets exits 7; usage errors exit 2 — all with the exact CLI-3 ASCII messages.
- [ ] `--remote` clear-fails with exit 10, leaving the server running local-only and `record.remote=false` — never a public bind (SEC-1/SEC-2/C1).
- [ ] Bare `aid` and `aid version/status/add/remove/update` are byte-for-byte unchanged (C4); the `dashboard` token now routes to the handler instead of the unknown-command arm.
- [ ] `bin/aid` passes the ASCII-only gate; the spawn path passes the literal `127.0.0.1` and contains no `0.0.0.0`/wildcard token (SEC-1).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/CLI tests for the new handler's public behavior added (full suite + parity is task-023); existing tests pass; build passes.
