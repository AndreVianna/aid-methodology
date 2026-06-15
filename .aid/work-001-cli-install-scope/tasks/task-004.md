# task-004: Global shared-state provisioning — Windows parity (%ProgramData%\aid) (PowerShell)

**Type:** IMPLEMENT

**Source:** feature-002-global-state-provisioning → delivery-001

**Depends on:** task-002, task-003

**Scope:**
- PowerShell twin of task-003 per feature-002 "bash ↔ ps1 parity": `bin/aid.ps1`, `lib/AidInstallCore.psm1`, `install.ps1`.
  - Add the ps1 provisioning helper twin of `_provision_shared_state_home` in `lib/AidInstallCore.psm1` (create dir + seed `0644`-equivalent `registry.yml`, no-clobber, atomic).
  - Windows shared-state home = `%ProgramData%\aid` (`$env:ProgramData\aid`); per-user collapses to `$env:LOCALAPPDATA\aid` (the `bin/aid.ps1:66` per-user home). Honor an `AID_SHARED_STATE_HOME` equivalent seam for the test sandbox.
  - Install-time PRIMARY: a machine-wide (Administrator) `install.ps1` creates `%ProgramData%\aid` while holding elevation; per-user install skips and collapses.
  - Runtime FALLBACK: non-prompting best-effort ensure-exists in the ps1 register path; on a non-writable privileged location, degrade to `%LOCALAPPDATA%\aid` + WARN (no UAC re-prompt during routine `aid add`).
- Mirror the best-effort skip+warn+return-0 contract of the bash side; PR #78 ships no ps1 elevation wrapper, so the ps1 write is attempted directly and the underlying tool surfaces its own error.

**Acceptance Criteria:**
- [ ] ps1 provisioning helper creates the shared dir + no-clobber atomic seed (`schema: 1` + empty `repos:`) equivalently to task-003.
- [ ] Windows shared home is `%ProgramData%\aid`; per-user collapses to `%LOCALAPPDATA%\aid`; the test-sandbox seam redirects off the real path.
- [ ] Runtime fallback degrades to `%LOCALAPPDATA%\aid` + WARN with no UAC re-prompt on a routine `aid add`; the host command still completes.
- [ ] bash/ps1 contract parity (two-tier, best-effort degrade) holds; all touched ps1 scripts are ASCII-only.
- [ ] All §6 quality gates pass.
