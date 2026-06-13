# task-026: feature-005 tests — never-funnel guard, clear-fail, idempotent teardown, parity, ASCII

**Type:** TEST

**Source:** feature-005-secure-remote-exposure → delivery-003

**Depends on:** task-025

**Scope:**
- Implement the feature-005 test scenarios (T-1..T-9) with `tailscale` STUBBED (a PATH shim) so the suite runs without a live tailnet: T-1 expose with stub present+logged-in (asserts `tailscale serve --bg <port>` on the stub's recorded argv, prints handle + URL, exit 0); T-2 expose→teardown (reverts the same port's serve mapping, not a blind `reset` when other mappings exist, exit 0); T-3 `--remote` with no `tailscale` / not-logged-in → expose exit 10, feature-004 surfaces exit 10, server local, `record.remote=false`; T-5 malformed/empty + double teardown → exit 0 idempotent; T-6 non-loopback target → exit 11; T-7 `tailscale serve` fails (stub nonzero) → exit 12 + revert.
- T-4 NEVER-FUNNEL guard (SEC-1): grep `bin/aid` + `bin/aid.ps1` exposure helpers contain NO `funnel` token; the stub `tailscale` fails the test if ever invoked with `funnel`.
- T-8 Bash vs PowerShell parity for T-1/T-3/T-5 (extend `test-aid-cli-parity.sh`). T-9 ASCII-only guard (incl. the SEC-2 reminder string) — `test-ascii-only.sh`.
- Deterministic; clean setup/teardown (remove the stub, tear down any serve state in the stub's record).

**Acceptance Criteria:**
- [ ] T-1/T-2/T-3/T-5/T-6/T-7 pass with the exact exit codes (0/10/11/12/13) and the asserted `tailscale` argv (serve, never funnel; the `--https=443 off` revert form).
- [ ] T-4 never-funnel guard: no `funnel` token in either launcher's exposure helpers, and the stub fails the test if `funnel` is ever called (SEC-1 structural never-public).
- [ ] T-3 clear-fail/never-public: expose exit 10 → feature-004 user-facing exit 10, server stays local, `record.remote=false` (the feature-004 T-11 contract from this side).
- [ ] T-8 parity (Bash vs PowerShell identical exit codes + handle shape + messages) and T-9 ASCII-only both pass.
- [ ] Idempotent teardown (T-5) is asserted (double/malformed → exit 0, no error).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown (stub removed, no residual serve state) and cover the source ACs (T-1..T-9); run green under `tests/run-all.sh`; build passes.
