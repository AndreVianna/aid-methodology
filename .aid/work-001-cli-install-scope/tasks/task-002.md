# task-002: CODE/STATE home split, scope derivation, marker/scan/sentinel removal (PowerShell parity)

**Type:** IMPLEMENT

**Source:** feature-001-runtime-scope-and-home-split → delivery-001

**Depends on:** task-001

**Scope:**
- `bin/aid.ps1` only — behavioral parity twin of task-001. Apply feature-001 "Affected components (PowerShell)" table verbatim:
  - `bin/aid.ps1:55-68` — **Rewrite** `$script:_AidHome` self-locate + `$env:LOCALAPPDATA/aid` fallback into `$script:_AidCodeHome` (self-locate via `$MyInvocation.MyCommand.Path`, **no env override**, error-out per Q1); scope from writability (`Invoke-AidPrivRun`); `$script:_AidStateHome = if ($env:AID_HOME) {$env:AID_HOME} else {<scope default>}` (global default honors `$env:AID_SHARED_STATE_HOME` else `/var/lib/aid`; per-user `$HOME/.aid`).
  - Repoint to `_AidCodeHome`: `_CoreModule` (`:73`), VERSION reads (`:187,380`), `$assetsDir` dashboard (`:862`).
  - Repoint `.update-check` (`:192,388`) to per-user `~/.aid` (Windows `$HOME/.aid`).
  - Repoint `registry.yml` register/unregister (`:1232,1267`) to `_AidStateHome`.
  - **Remove**: `Invoke-AidMigrateSentinel` + `$script:_AidMigrateSentinelFired` (`:283-335`), `Write-AidMigratedMarker` + `.migrated` (`:1744-1761`), `Invoke-AidScanForRepos` (`:1609-1704`), `Invoke-AidCheckRepoCompliant` (`:1706-1741`, orphaned), `Invoke-AidScanAndMigrate` (`:1762-end`).
  - Drop the `Invoke-AidMigrateSentinel` call (keep `Invoke-AidUpdateCheck`) at `:1134` and `:1204`.
  - `Invoke-AidScanAndMigrate` post-update at `:1897` — **replace with a no-op**, no dangling caller.
  - The old `$env:LOCALAPPDATA/aid` was a CODE-home fallback and is removed (Q1); it is **not** repurposed as the Windows STATE default (per-user STATE default is `$HOME/.aid`).
- Re-anchor cited offsets by symbol name post-#78.

**Acceptance Criteria:**
- [ ] `bin/aid.ps1` mirrors task-001 behavior: self-located `_AidCodeHome` (no env override, Q1 error-out), writability-derived scope, env-overridable `_AidStateHome` (`AID_HOME` redirects STATE only), `.update-check` always per-user `$HOME/.aid`.
- [ ] `grep` of `bin/aid.ps1` for `Invoke-AidMigrateSentinel`, `Write-AidMigratedMarker`, `Invoke-AidScanForRepos`, `Invoke-AidCheckRepoCompliant`, `Invoke-AidScanAndMigrate`, and `.migrated` returns **zero** matches; the post-update step is a no-op with no dangling caller.
- [ ] bash/ps1 parity holds (behaviorally equivalent to task-001) and all new/edited lines are ASCII-only.
- [ ] All §6 quality gates pass.
