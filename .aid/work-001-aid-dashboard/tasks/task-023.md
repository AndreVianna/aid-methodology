# task-023: feature-004 CLI tests — start/stop/stale/usage/runtime/port + --remote clear-fail + parity + ASCII

**Type:** TEST

**Source:** feature-004-cli-dashboard-control → delivery-002

**Depends on:** task-022

**Scope:**
- Implement the feature-004 test scenarios (T-1..T-13) as deliverables: T-1/T-2 start python/node (child spawned, bound `127.0.0.1:8787`, correct `dashboard.pid`, exit 0, URL printed); T-3 second start → exit 8; T-4 stop after start (child gone, record+logfile removed, exit 0); T-5 stop with nothing running → exit 0 idempotent; T-6 crash-then-restart stale reclaim; T-7 usage errors (bad/missing runtime, unknown flag, bad `--port`) → exit 2; T-8 runtime absent (PATH stub) → exit 9; T-9 port-in-use → exit 3; T-11 `--remote` with no mechanism (stub) → exit 10, server local, `record.remote=false`.
- T-10 regression: bare `aid` + `aid version/status` byte-identical to pre-change (C4 guard).
- T-12 Bash vs PowerShell parity for T-1/T-3/T-4/T-5/T-7 — extend `tests/canonical/test-aid-cli-parity.sh` (identical exit codes + messages).
- T-13 ASCII-only guard — `bin/aid` + `bin/aid.ps1` still pass `tests/canonical/test-ascii-only.sh`.
- Deterministic; stub the runtime/port where needed; clean setup/teardown (kill any spawned child, remove records).

**Acceptance Criteria:**
- [ ] T-1..T-9 + T-11 pass with the exact exit codes (0/2/3/7/8/9/10) and ASCII messages from CLI-2/CLI-3; the spawned child binds `127.0.0.1` only.
- [ ] T-10 confirms bare `aid` + `aid version/status` output is byte-identical to pre-change (C4).
- [ ] T-12 parity: Bash and PowerShell produce identical exit codes + messages for T-1/T-3/T-4/T-5/T-7 (extended `test-aid-cli-parity.sh`).
- [ ] T-13: both launchers pass the ASCII-only gate.
- [ ] The `--remote` clear-fail/never-public contract (T-11) is asserted; the real expose path is feature-005's tests.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown (no leaked listening child/record) and cover the source ACs (T-1..T-13); run green under `tests/run-all.sh`; build passes.
