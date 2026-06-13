# task-022: feature-004 PowerShell twin Invoke-AidDashboardCtl in bin/aid.ps1

**Type:** IMPLEMENT

**Source:** feature-004-cli-dashboard-control → delivery-002

**Depends on:** task-021

**Scope:**
- Implement `Invoke-AidDashboardCtl` in the hand-maintained root `bin/aid.ps1` — the byte-behavior twin of the Bash `_cmd_dashboard_ctl` (LC-CLI-P): same grammar, same exit codes, same user-visible messages, same `dashboard.pid` record format (feature-004 Layers).
- Windows spawn semantics: `Start-Process -FilePath <interp> -ArgumentList ... -PassThru -WindowStyle Hidden` (detached daemon); PID liveness via `Get-Process -Id`; clean kill via `Stop-Process -Id <pid>` then `-Force` (Feature Flow Windows arms). **Deviation (detach fix, post-Windows-CI):** `-RedirectStandardOutput/Error` are intentionally NOT used. `Start-Process` redirection forces full handle inheritance, so the long-lived server inherits and holds the caller's stdout/stderr pipe open and a capturing caller (the CI dashboard smoke: `$out = aid dashboard start 2>&1`) hangs forever. Omitting redirection selects ShellExecute — no caller-handle inheritance, true detach (the Windows analog of Bash `setsid`). Trade-off: the server's own stdout/stderr are not file-captured on Windows (readiness is verified by TCP poll, not the log). See `bin/aid.ps1` Step 7 KI + known-issues.md.
- Accept the dual-alias tokens the rest of `aid.ps1` accepts (`-Target/--target`, `-Verbose/--verbose`, `-h/--help`, `-Remote/--remote`, `-Port/--port`) — CLI-1.
- Add the mirror dispatch branch before the `add/remove/update` validation (`bin/aid.ps1:572`); add the help line + `dashboard` arm to `Show-AidUsage` (LC-3). `--remote` clear-fail stub (exit 10) matching the Bash side. Bare `aid` path (`bin/aid.ps1:385-406`) untouched (C4). ASCII-only (LC-4). `aid.cmd` is untouched (forwards to `aid.ps1`). Refresh vendored copies via the build vendor step.

**Acceptance Criteria:**
- [ ] `aid dashboard start node|python` / `stop` on PowerShell behaves identically to the Bash side: same exit codes (0/2/3/7/8/9/10), same ASCII messages, same `dashboard.pid` record fields.
- [ ] Windows process spawn/track/kill works (Start-Process / Get-Process / Stop-Process), bound `127.0.0.1`, no orphaned child after `stop`.
- [ ] `--remote` clear-fails exit 10 with the server still local-only and `record.remote=false` (SEC-2/C1), matching the Bash stub.
- [ ] Bare `aid` and the existing PowerShell subcommands are unchanged (C4); the `dashboard` branch is added before the add/remove/update validation; `aid.cmd` is unmodified.
- [ ] `bin/aid.ps1` passes the ASCII-only gate; the spawn path passes the literal `127.0.0.1` (SEC-1).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: CLI tests for the PowerShell handler added (full suite + parity is task-023); existing tests pass; build passes.
