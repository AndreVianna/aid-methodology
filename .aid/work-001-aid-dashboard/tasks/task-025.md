# task-025: LC-2 PowerShell twin in bin/aid.ps1

**Type:** IMPLEMENT

**Source:** feature-005-secure-remote-exposure → delivery-003

**Depends on:** task-024, task-022

**Scope:**
- Implement `Invoke-AidRemoteExpose` / `Invoke-AidRemoteTeardown` in the hand-maintained root `bin/aid.ps1` — the byte-behavior twin of the Bash LC-EXP-B helpers (LC-EXP-P): same handle shape (`tailscale-serve:<port>`), same exit codes (0/10/11/12 expose; 0/13 teardown), same user-visible strings, same FR18 grant-guidance text.
- Shell out to the same cross-platform `tailscale` verbs (`serve --bg <port>`, `serve status --json`, `serve --bg --https=443 off`, `status --json`) — no platform-specific exposure logic (NFR5).
- Wire it into the PowerShell `--remote` path (replacing the task-022 clear-fail stub on this side so the success path works when Tailscale is present).
- ASCII-only; never funnel, never bind/widen a socket, never edit the policy file. Refresh vendored copies via the vendor step.

**Acceptance Criteria:**
- [ ] The PowerShell expose/teardown behave identically to the Bash side: same handle shape, same exit codes, same messages, same FR18 grant guidance.
- [ ] On Tailscale present+logged-in, `--remote` brings up `serve` (never funnel), records `remote=true` + the handle, and prints the private URL; on absence/failure it exits 10/11/12 with the server staying local-only (SEC-1/SEC-3/C1).
- [ ] `teardown` reverts the single 443 frontend and is idempotent (exit 0) / warns exit 13, matching Bash.
- [ ] No `funnel` token in the PowerShell exposure helpers (SEC-1); no socket bind/widen, no policy-file edit.
- [ ] `bin/aid.ps1` passes the ASCII-only gate.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: CLI tests for the PowerShell helpers added (full suite + parity is task-026); existing tests pass; build passes.
