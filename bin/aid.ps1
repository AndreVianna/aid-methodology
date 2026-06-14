#Requires -Version 5.1
# aid.ps1 - AID CLI dispatcher (PowerShell side).
#
# Purpose:
#   Persistent global command installed at $AID_HOME\bin\aid.ps1.  Parses
#   subcommands and dispatches to the shared install-core engine located at
#   $AID_HOME\lib\AidInstallCore.psm1.  Operates on the current working
#   directory (-Target / AID_TARGET overrides).
#
# Usage:
#   aid                              Show the dashboard
#   aid -h | --help                  Show help
#   aid version                      Print the CLI version
#   aid status                       Show AID state of the current project
#   aid add <tool>[,...]             Add tool(s) to the current project
#   aid update [<tool>... | self]    Update to latest; no arg = all tools; 'self' = the aid CLI
#   aid remove [<tool>... | self]    Remove; no arg = ALL AID from project; 'self' = the aid CLI
#   aid <command> -h | --help        Per-command help
#
# Flags (shared across subcommands where applicable):
#   -FromBundle <path>   Offline install from a pre-downloaded tarball / dir.
#   -Version <v>         Pin to a specific release version (e.g. 0.7.0).
#   -Force               Overwrite differing files / skip confirmation prompts.
#   -Target <dir>        Project root (default: current directory).
#   -Verbose             Print per-file detail (default: concise summary).
#   -NoPath              (bootstrap / update self only) Skip PATH wiring.

# ---------------------------------------------------------------------------
# Bootstrap URL - single place to update when the branch merges to master.
# Override with $env:AID_INSTALL_URL for tests.
# ---------------------------------------------------------------------------
$script:_AidInstallUrl = if ($env:AID_INSTALL_URL) { $env:AID_INSTALL_URL } else {
    'https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1'
}

# ---------------------------------------------------------------------------
# Piped-mode / terminal-survival guard.
# When invoked via scriptblock or iex, calling exit <N> kills the host.
# Use the same sentinel-throw pattern as install.ps1.
# ---------------------------------------------------------------------------
$script:_PipedMode = [string]::IsNullOrEmpty($PSCommandPath)
$script:_SentinelTag = '__AidDispatcherExit__'

function script:Exit-Aid {
    param([int]$Code)
    if ($script:_PipedMode) {
        $global:LASTEXITCODE = $Code
        throw "$($script:_SentinelTag)$Code"
    } else {
        exit $Code
    }
}

# ---------------------------------------------------------------------------
# Locate $AID_HOME.  The installed dispatcher lives at $AID_HOME\bin\aid.ps1.
# ---------------------------------------------------------------------------
$script:_AidSelfPath = $MyInvocation.MyCommand.Path
if (-not [string]::IsNullOrEmpty($script:_AidSelfPath)) {
    $script:_AidHome = $env:AID_HOME
    if (-not $script:_AidHome) {
        # bin/aid.ps1 -> parent of bin/ = AID_HOME
        $script:_AidHome = Split-Path -Parent (Split-Path -Parent $script:_AidSelfPath)
    }
} else {
    $script:_AidHome = if ($env:AID_HOME) { $env:AID_HOME } else {
        if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'aid' } else { Join-Path $HOME '.aid' }
    }
}

# ---------------------------------------------------------------------------
# Import the shared install core from $AID_HOME\lib\.
# ---------------------------------------------------------------------------
$script:_CoreModule = Join-Path $script:_AidHome 'lib' | Join-Path -ChildPath 'AidInstallCore.psm1'
if (-not (Test-Path $script:_CoreModule -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: aid: install core not found at $($script:_CoreModule). Re-run the AID bootstrap to repair.")
    script:Exit-Aid 1
}
# Load the core lib by dot-sourcing its content (NOT Import-Module - avoids PowerShell's
# module-analysis cache, which can serve a stale exported-command list across upgrades).
# Export-ModuleMember is a module-only cmdlet; shadow it with a local no-op so the lib's
# trailing Export-ModuleMember call is harmless when dot-sourced.
$_aidLibRaw = $null
try {
    $_aidLibRaw = Get-Content -LiteralPath $script:_CoreModule -Raw -Encoding utf8 -ErrorAction Stop
} catch {
    [Console]::Error.WriteLine("ERROR: aid: failed to read the CLI core from $($script:_CoreModule): $_")
    script:Exit-Aid 1
}
function Export-ModuleMember { param([Parameter(ValueFromRemainingArguments=$true)]$args) }
. ([scriptblock]::Create($_aidLibRaw))

# Defensive guard: verify the required core function was loaded via dot-source.
# If Get-AidStatusBody is still absent after dot-sourcing, the lib is genuinely
# broken or incomplete (not a cache issue - the file itself is the problem).
if (-not (Get-Command 'Get-AidStatusBody' -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine("ERROR: aid: failed to load the CLI core from $($script:_CoreModule). The file may be incomplete - reinstall with: irm $($script:_AidInstallUrl) | iex")
    script:Exit-Aid 1
}

# ---------------------------------------------------------------------------
# Usage helper.
# ---------------------------------------------------------------------------
function script:Show-AidUsage {
    param([string]$Sub = '')
    switch ($Sub) {
        'status' {
            Write-Host 'aid status [-Verbose] [-Target <dir>]'
            Write-Host '  Show AID state of the current project (default: cwd).'
            Write-Host '  Exit 7 when no AID install is found.'
        }
        'add' {
            Write-Host 'aid add <tool>[,<tool>...] [-Version <v>] [-FromBundle <path>]'
            Write-Host '                           [-Force] [-Verbose] [-Target <dir>]'
            Write-Host '  Add tool(s) to the current project.'
            Write-Host '  Tools: claude-code, codex, cursor, copilot-cli, antigravity'
        }
        'remove' {
            Write-Host 'aid remove [<tool>[,<tool>...] | self] [-Force] [-Verbose] [-Target <dir>]'
            Write-Host '  Remove tool(s) from the current project (manifest-driven).'
            Write-Host '  No args: remove ALL AID from the project (asks for confirmation).'
            Write-Host '  self: remove the aid CLI itself (asks for confirmation).'
        }
        'update' {
            Write-Host 'aid update [<tool>... | self] [-Version <v>] [-FromBundle <path>]'
            Write-Host '           [-Force] [-Verbose] [-Target <dir>]'
            Write-Host '  Update to latest. No args: update all installed tools.'
            Write-Host '  self: update the aid CLI itself.'
        }
        'version' {
            Write-Host 'aid version'
            Write-Host '  Print the installed aid CLI version and exit 0.'
        }
        'dashboard' {
            Write-Host 'aid dashboard start <node|python> [--remote] [--port <n>] [--target <dir>]'
            Write-Host 'aid dashboard stop                [--target <dir>]'
            Write-Host '  Start or stop the local pipeline dashboard for the current project.'
            Write-Host '  <node|python>  select the server runtime to launch.'
            Write-Host '  --remote       also expose it to authorized users over a private channel (never public);'
            Write-Host '                 fails clearly if that mechanism is unavailable -- never binds publicly.'
            Write-Host '  --port <n>     listen port on 127.0.0.1 (default 8787).'
            Write-Host "  The dashboard binds to 127.0.0.1 only. 'stop' is idempotent and also tears down --remote."
        }
        default {
            Write-Host 'aid - AID CLI'
            Write-Host ''
            Write-Host 'Usage:'
            Write-Host '  aid                              Show the dashboard'
            Write-Host '  aid -h | --help                  Show this help'
            Write-Host '  aid version                      Print the CLI version'
            Write-Host '  aid status                       Show AID state of the current project'
            Write-Host '  aid add <tool>[,...]             Add tool(s) to the current project'
            Write-Host '  aid update [<tool>... | self]    Update to latest; no arg = all tools'
            Write-Host '  aid remove [<tool>... | self]    Remove; no arg = ALL AID from project'
            Write-Host '  aid dashboard start|stop ...     Start/stop the local dashboard'
            Write-Host "  aid <command> -h | --help        Per-command help"
            Write-Host ''
            Write-Host 'Flags: -FromBundle, -Version, -Force, -Target, -Verbose'
            Write-Host "Run 'aid <command> -h' for details."
        }
    }
}

# ---------------------------------------------------------------------------
# Error helper.
# ---------------------------------------------------------------------------
function script:Fail-Aid {
    param([string]$Message, [int]$Code = 1)
    [Console]::Error.WriteLine("ERROR: aid: $Message")
    script:Exit-Aid $Code
}

# ---------------------------------------------------------------------------
# Update check (throttled, cached, non-blocking, opt-out).
# ---------------------------------------------------------------------------

# Invoke-AidUpdateCheck
# Compares installed CLI version against latest GitHub release.
# Prints ONE notice line when newer is available.  Fail-silent.
# Throttle: re-fetches at most once per 24h; cache in $AID_HOME\.update-check.
# Opt-out: $env:AID_NO_UPDATE_CHECK = '1'
# Test hook: $env:AID_UPDATE_CHECK_URL overrides the fetch URL (and bypasses throttle).
function script:Invoke-AidUpdateCheck {
    # Opt-out.
    if ($env:AID_NO_UPDATE_CHECK -eq '1') { return }

    # Read installed version.
    $verFile = Join-Path $script:_AidHome 'VERSION'
    if (-not (Test-Path $verFile -PathType Leaf)) { return }
    $installedVersion = (Get-Content -LiteralPath $verFile -Raw -ErrorAction SilentlyContinue).Trim()
    if (-not $installedVersion) { return }

    $cacheFile    = Join-Path $script:_AidHome '.update-check'
    $throttleSecs = 86400   # 24 hours
    try { $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } catch { return }

    # Determine URL and throttle behaviour.
    $checkUrl    = $env:AID_UPDATE_CHECK_URL
    $useThrottle = [string]::IsNullOrEmpty($checkUrl)
    if ($useThrottle) {
        $checkUrl = "https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest"
    }

    # Try to read cache.
    $cachedTs      = 0
    $cachedLatest  = ''
    if (Test-Path $cacheFile -PathType Leaf) {
        try {
            $lines = @(Get-Content -LiteralPath $cacheFile -ErrorAction SilentlyContinue)
            if ($lines.Count -ge 1) { $cachedTs     = [long]$lines[0] }
            if ($lines.Count -ge 2) { $cachedLatest = $lines[1].Trim() }
        } catch {}
    }

    # Decide whether to fetch.
    $latestVersion = ''
    $needFetch = $true
    if ($useThrottle -and $cachedLatest) {
        $age = $now - $cachedTs
        if ($age -lt $throttleSecs) {
            $needFetch     = $false
            $latestVersion = $cachedLatest
        }
    }

    if ($needFetch) {
        $body = ''
        try {
            # Support file:// URLs for hermetic tests (PowerShell web cmdlets don't
            # handle file://, so we strip the scheme and read the file directly).
            if ($checkUrl -match '^file:///?(.+)$') {
                $filePath = $matches[1]
                # On Windows file:///C:/path -> C:/path; on Linux file:///tmp/path -> /tmp/path
                if ($filePath -notmatch '^[A-Za-z]:') {
                    $filePath = '/' + $filePath.TrimStart('/')
                }
                $body = Get-Content -LiteralPath $filePath -Raw -ErrorAction Stop
            } else {
                $resp = Invoke-WebRequest -Uri $checkUrl -UseBasicParsing -TimeoutSec 2 `
                            -ErrorAction Stop
                $body = $resp.Content
            }
        } catch {
            return  # fail-silent
        }
        if ($body -match '"tag_name"\s*:\s*"([^"]+)"') {
            $tag = $matches[1] -replace '^v', ''
            $latestVersion = $tag
            # Update cache.
            try {
                [System.IO.File]::WriteAllText($cacheFile, "$now`n$latestVersion`n")
            } catch {}
        }
    }

    if (-not $latestVersion) { return }

    # Compare: notice only when latest > installed.
    # Inline semver comparison (mirrors script:Test-SemverLt from AidInstallCore.psm1
    # but kept local here since script:-scoped module functions are not callable across
    # the module boundary from the dispatcher script).
    $partsA = $installedVersion -split '\.'
    $partsB = $latestVersion    -split '\.'
    $isLt   = $false
    for ($i = 0; $i -lt 3; $i++) {
        $rawA = if ($i -lt $partsA.Count) { $partsA[$i] } else { '0' }
        $rawB = if ($i -lt $partsB.Count) { $partsB[$i] } else { '0' }
        if ($rawA -match '^(\d+)') { $va = [int]$matches[1] } else { $va = 0 }
        if ($rawB -match '^(\d+)') { $vb = [int]$matches[1] } else { $vb = 0 }
        if ($va -lt $vb) { $isLt = $true; break }
        if ($va -gt $vb) { break }
    }
    if ($isLt) {
        $updateCmd = switch ($env:AID_INSTALL_CHANNEL) {
            'npm'  { 'npm i -g aid-installer@latest' }
            'pypi' { 'pipx upgrade aid-installer  (or: pip install --user -U aid-installer)' }
            default { 'aid update self' }
        }
        Write-Host "A newer aid CLI is available: v$latestVersion (you have v$installedVersion). Run: $updateCmd"
    }
}

# ---------------------------------------------------------------------------
# Invoke-AidMigrateSentinel  (FF-4 / DM-3 / DD-1 / task-080)
# Version-sentinel lazy first-run migration trigger (PS twin of
# _aid_check_migrate_sentinel in bin/aid).
# Compares $AID_HOME/VERSION (installed) vs $AID_HOME/.migrated (last migrated).
# Fires the FF-2 machine scan once when they differ (version advanced or marker
# absent = never migrated).  Called at the same sites as Invoke-AidUpdateCheck.
# Opt-out: $env:AID_NO_MIGRATE = '1' -> skip entirely.
# No-loop: a script-scope flag ($script:_AidMigrateSentinelFired) prevents
# re-firing within the same run; update self bypasses this path.
# Non-interactive defer (RC-3): no TTY + no AID_MIGRATE_YES=1 -> annotate +
# defer (marker NOT advanced); Invoke-AidScanAndMigrate enforces the same on
# its no-TTY branch.
# ---------------------------------------------------------------------------
$script:_AidMigrateSentinelFired = $false

function script:Invoke-AidMigrateSentinel {
    # Opt-out.
    if ($env:AID_NO_MIGRATE -eq '1') { return }

    # No-loop guard: only fire once per process.
    if ($script:_AidMigrateSentinelFired) { return }

    # Read installed version.
    $verFile = Join-Path $script:_AidHome 'VERSION'
    if (-not (Test-Path $verFile -PathType Leaf)) { return }
    $sentinelInstalled = (Get-Content -LiteralPath $verFile -Raw -ErrorAction SilentlyContinue).Trim()
    if ([string]::IsNullOrEmpty($sentinelInstalled)) { return }

    # Read .migrated marker (absent = empty = never migrated -> treated as advanced).
    $sentinelMarker = ''
    $markerFile = Join-Path $script:_AidHome '.migrated'
    if (Test-Path $markerFile -PathType Leaf) {
        $sentinelMarker = (Get-Content -LiteralPath $markerFile -Raw -ErrorAction SilentlyContinue).Trim()
    }

    # DD-1 string inequality: if equal -> steady state, no trigger (SEC-6 no-loop).
    if ($sentinelInstalled -eq $sentinelMarker) { return }

    # Version advanced past last-migrated (or marker absent on first run after upgrade).
    $script:_AidMigrateSentinelFired = $true

    # Non-interactive + no opt-in -> annotate + defer (RC-3 / SEC-1).
    # Marker NOT advanced; the next interactive run re-triggers (FF-4 retrigger).
    $isTty = [Console]::IsInputRedirected -eq $false
    if ((-not $isTty) -and ($env:AID_MIGRATE_YES -ne '1')) {
        Write-Host "AID hint: AID upgraded to $sentinelInstalled; run 'aid update self' to migrate your repos."
        return
    }

    # Interactive OR non-interactive opt-in: run the FF-2 scan once.
    # Invoke-AidScanAndMigrate writes the DM-3 marker on completion.
    $sentinelApply = ($env:AID_MIGRATE_YES -eq '1')
    script:Invoke-AidScanAndMigrate -ApplyAllFlag $sentinelApply
}

# Invoke-AidUpdateSelf
# Re-runs the bootstrap in place.  Returns the exit code (does NOT call Exit-Aid).
# AID_INSTALL_CHANNEL guard: npm/pypi channels print a package-manager hint
# and return 0 instead of re-bootstrapping.
# Callers are responsible for calling Exit-Aid after the post-update scan.
function script:Invoke-AidUpdateSelf {
    switch ($env:AID_INSTALL_CHANNEL) {
        'npm' {
            Write-Host 'Updating the aid CLI: run  npm i -g aid-installer@latest'
            return 0
        }
        'pypi' {
            Write-Host 'Updating the aid CLI: run  pipx upgrade aid-installer  (or: pip install --user -U aid-installer)'
            return 0
        }
    }
    Write-Host 'Updating the aid CLI...'
    $url = $script:_AidInstallUrl
    try {
        $scriptContent = (Invoke-RestMethod -Uri $url -ErrorAction Stop)
        & ([scriptblock]::Create($scriptContent))
        return $LASTEXITCODE
    } catch {
        [Console]::Error.WriteLine("ERROR: aid: update self failed: $_")
        return 3
    }
}

# Invoke-AidUpdateSelfIfStale  (FF-3 preamble / CLI-2 / task-079)
# Self-update-if-needed preamble for the 'aid update [<tool>]' reach.
# Reuses Invoke-AidUpdateSelf channel logic gated by a skip-if-current check
# (OQ-6 resolved simplest-correct: compare installed $AID_HOME/VERSION against
# the cached .update-check latest; if stale -> call Invoke-AidUpdateSelf; if
# current or unknown -> silent no-op).
#
# Safety notes (no re-bootstrap/loop hazard):
#   - Called only on 'update [<tool>]', not 'update self' or 'add'.
#   - WARN-not-fail: self-update failure is logged; tool-install continues (NFR12).
function script:Invoke-AidUpdateSelfIfStale {
    $aidHome = $script:_AidHome

    # Read installed version.
    $verFile = Join-Path $aidHome 'VERSION'
    $installed = ''
    if (Test-Path $verFile -PathType Leaf) {
        $installed = (Get-Content $verFile -Raw).Trim()
    }
    if (-not $installed) { return }  # no installed version known -> skip

    # Read cached latest version from .update-check (line 2 of the cache file).
    $cacheFile = Join-Path $aidHome '.update-check'
    $cachedLatest = ''
    if (Test-Path $cacheFile -PathType Leaf) {
        $lines = Get-Content $cacheFile -ErrorAction SilentlyContinue
        if ($lines -and $lines.Count -ge 2) {
            $cachedLatest = ($lines[1]).Trim()
        }
    }
    if (-not $cachedLatest) { return }  # no cached latest known -> skip (no network call here)

    # Skip if already current (string equality).
    if ($installed -eq $cachedLatest) { return }

    # Stale: call the channel-appropriate self-update logic.
    # WARN-not-fail: failure must not abort the tool-update.
    Write-Host "aid update: CLI is not current (installed: $installed, available: $cachedLatest); self-updating before tool install..."
    try {
        $null = script:Invoke-AidUpdateSelf
    } catch {
        [Console]::Error.WriteLine("WARN: aid: self-update failed (continuing with tool install)")
    }
}

# ---------------------------------------------------------------------------
# PATH wiring helpers (Windows - User-scope registry).
# ---------------------------------------------------------------------------

# Add-AidToPath <binDir> [-NoPath]
# Idempotently wire binDir into the User PATH via [Environment]::SetEnvironmentVariable.
# Deduplicates on ';'-split.  Warns if path would exceed safe length.
# Updates $env:Path in-process so the convenience-chain first action works immediately.
function script:Add-AidToPath {
    param([string]$BinDir, [bool]$NoPath = $false)

    if ($NoPath) {
        Write-Host "Add `"$BinDir`" to your PATH manually."
        return
    }

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $currentPath) { $currentPath = '' }

    # Split on ';', filter empty, deduplicate while preserving order.
    $parts = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() }
    if ($parts -contains $BinDir) {
        # Already present - update in-process path and return silently.
        if ($env:Path -notmatch [regex]::Escape($BinDir)) {
            $env:Path = "$BinDir;$($env:Path)"
        }
        return
    }

    $newParts = @($BinDir) + @($parts)
    $newPath  = $newParts -join ';'

    # Safety guard: warn if exceeding ~2000 chars (Windows limit is 32767 but
    # practical registry/shell limit is much lower for User PATH).
    $safeLimit = 2000
    if ($newPath.Length -gt $safeLimit) {
        Write-Host "WARN: aid: User PATH would exceed $safeLimit chars. Skipping automatic PATH wiring."
        Write-Host "Add `"$BinDir`" to your PATH manually via System Properties > Environment Variables."
        return
    }

    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')

    # Update in-process immediately so the convenience-chain first action works.
    if ($env:Path -notmatch [regex]::Escape($BinDir)) {
        $env:Path = "$BinDir;$($env:Path)"
    }

    Write-Host "PATH wiring added (User scope): $BinDir"
    Write-Host "Open a new shell, or the PATH is already active in this session."
}

# Remove-AidFromPath <binDir>
# Remove binDir from User PATH idempotently.
function script:Remove-AidFromPath {
    param([string]$BinDir)

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $currentPath) { return }

    $parts   = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() -ne $BinDir }
    $newPath = $parts -join ';'

    if ($newPath -ne $currentPath) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "PATH wiring removed (User scope): $BinDir"
    }
}

# ---------------------------------------------------------------------------
# Remote exposure helpers (feature-005 / LC-EXP-P).
# SEC-1: These helpers invoke ONLY 'tailscale serve' (tailnet-only). The public
#        exposure verb is never used -- a bare grep for it returns nothing
#        anywhere in this file (structural never-public, C1).
# SEC-6: --remote exposes the CLI home (all registered repos, OQ5/DR-4): a
#        granted tailnet identity sees the full registered-repo list + each
#        repo's home.html/kb.html/api/model. This is the accepted OQ5 trade-off
#        -- a grantee is already a trusted operator of this host. The helpers
#        below, the bind, and the teardown are UNCHANGED; only what the port
#        serves changed (DR-2/task-047). Never-public (C1) and host/user-ACL
#        scoping (C3) hold exactly as before.
# ---------------------------------------------------------------------------

# Invoke-AidRemoteExpose -Port <n>
# Bring up tailscale serve (tailnet-only) for a loopback port.
# stdout (exit 0): two lines: handle (tailscale-serve:<port>) + https URL.
# stderr:          human messages, errors, FR18 ACL-grant guidance.
# exit:  0=ok  10=mechanism absent  11=non-loopback target  12=serve failed
function script:Invoke-AidRemoteExpose {
    param([int]$Port)

    # Step 1: Re-assert the loopback target (belt-and-suspenders, SEC-1).
    if ($Port -le 0) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: expose target must be 127.0.0.1 (got: $Port)")
        return 11
    }

    # Step 2a: availability -- tailscale on PATH?
    if (-not (Get-Command 'tailscale' -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: --remote requested but tailscale is not on PATH; --remote is unavailable")
        return 10
    }

    # Step 2b: availability -- node logged in and Running?
    $tsStatusOut = ''
    try { $tsStatusOut = (& tailscale status 2>&1) -join "`n" } catch { $tsStatusOut = '' }
    if ($tsStatusOut -match '(?i)(not running|logged out|Stopped|NeedsLogin|NoState|not logged in)') {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: --remote requested but tailscale is not running or not logged in (tailscale status: $tsStatusOut); --remote is unavailable")
        return 10
    }
    if ([string]::IsNullOrEmpty($tsStatusOut)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: --remote requested but tailscale status returned no output; --remote is unavailable")
        return 10
    }

    # Step 3: Bring up Serve (tailnet-only; the public exposure verb is never invoked -- SEC-1).
    $serveErr = ''
    $serveRc  = 0
    try {
        $serveErr = (& tailscale serve --bg $Port 2>&1) -join "`n"
        $serveRc  = $LASTEXITCODE
    } catch {
        $serveErr = "$_"
        $serveRc  = 1
    }
    if ($serveRc -ne 0) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: tailscale serve failed (rc=${serveRc}): $serveErr")
        # Revert: take down the 443 frontend mapping (if it was partially set).
        try { & tailscale serve --bg --https=443 off 2>&1 | Out-Null } catch {}
        return 12
    }

    # Step 4: Resolve the private URL from tailscale's Self.DNSName (the MagicDNS name).
    # NOTE: 'tailscale status --json' is PRETTY-PRINTED, so the regex tolerates whitespace
    # after the colon; '--peers=false' isolates Self so a peer DNSName is never picked up.
    # NEVER fall back to the machine hostname/FQDN here -- that is the local/corporate DNS
    # domain, not the tailnet, and would produce a non-working URL + wrong ACL src.
    $tsJson   = ''
    $nodeFqdn = ''
    try { $tsJson = (& tailscale status --json --peers=false 2>&1) -join "`n" } catch { $tsJson = '' }
    if ([string]::IsNullOrEmpty($tsJson)) {
        try { $tsJson = (& tailscale status --json 2>&1) -join "`n" } catch { $tsJson = '' }
    }
    if (-not [string]::IsNullOrEmpty($tsJson)) {
        # Scope the parse to the Self object so a peer DNSName can never be selected
        # regardless of JSON ordering. Find "Self" index, then "Peer" index after it;
        # use the substring between them (or from "Self" to end if no "Peer" present).
        $selfIdx = $tsJson.IndexOf('"Self"')
        $selfBlock = $tsJson
        if ($selfIdx -ge 0) {
            $peerIdx = $tsJson.IndexOf('"Peer"', $selfIdx + 1)
            if ($peerIdx -gt $selfIdx) {
                $selfBlock = $tsJson.Substring($selfIdx, $peerIdx - $selfIdx)
            } else {
                $selfBlock = $tsJson.Substring($selfIdx)
            }
        }
        if ($selfBlock -match '"DNSName"\s*:\s*"([^"]*)"') {
            $nodeFqdn = $matches[1] -replace '\.$', ''
        }
    }
    if ([string]::IsNullOrEmpty($nodeFqdn)) {
        # Defensive fallback: a *.ts.net host reported by 'tailscale serve status --json'.
        $serveJson = ''
        try { $serveJson = (& tailscale serve status --json 2>&1) -join "`n" } catch { $serveJson = '' }
        if (-not [string]::IsNullOrEmpty($serveJson)) {
            if ($serveJson -match '([a-z0-9-]+(\.[a-z0-9-]+)*\.ts\.net)') {
                $nodeFqdn = $matches[1]
            }
        }
    }
    if (-not [string]::IsNullOrEmpty($nodeFqdn)) {
        $privateUrl = "https://${nodeFqdn}/"
    } else {
        # Could not resolve the tailnet MagicDNS name. Do NOT fabricate a public-domain URL.
        $privateUrl = "(unresolved: run 'tailscale status' to find this host's .ts.net name)"
    }

    # Resolve display values for the ACL-grant guidance. The grant *src* is an identity only
    # you can choose (login/group/tag); a DNS domain is not a valid selector, so AID shows a
    # placeholder. The *dst* is THIS host's tailnet short-name.
    $nodeShort = ($nodeFqdn -split '\.')[0]
    if ([string]::IsNullOrEmpty($nodeShort) -and -not [string]::IsNullOrEmpty($tsJson)) {
        # Same Self-scoping applied to HostName extraction.
        $selfIdx2 = $tsJson.IndexOf('"Self"')
        $selfBlockHn = $tsJson
        if ($selfIdx2 -ge 0) {
            $peerIdx2 = $tsJson.IndexOf('"Peer"', $selfIdx2 + 1)
            if ($peerIdx2 -gt $selfIdx2) {
                $selfBlockHn = $tsJson.Substring($selfIdx2, $peerIdx2 - $selfIdx2)
            } else {
                $selfBlockHn = $tsJson.Substring($selfIdx2)
            }
        }
        if ($selfBlockHn -match '"HostName"\s*:\s*"([^"]*)"') {
            $nodeShort = $matches[1].ToLower()
        }
    }

    # Step 5: Print FR18 step-by-step ACL-grant guidance to STDERR (informational only).
    $srcPlaceholder = '<you@example.com>'
    $dstPlaceholder = if ($nodeShort)    { $nodeShort }    else { '<this-host>' }
    $urlPlaceholder = $privateUrl

    [Console]::Error.WriteLine('')
    [Console]::Error.WriteLine('Remote exposure is UP (tailnet-private). To restrict it to ONLY you (C3), add a')
    [Console]::Error.WriteLine('deny-by-default tailnet ACL grant -- without it, any tailnet device can reach this host.')
    [Console]::Error.WriteLine('Step 1. Open the tailnet policy file:')
    [Console]::Error.WriteLine('          https://login.tailscale.com/admin/acls/file')
    [Console]::Error.WriteLine('Step 2. Add this grant (replace the identity with yours or a group):')
    [Console]::Error.WriteLine("          {`"grants`":[{`"src`":[`"$srcPlaceholder`"],`"dst`":[`"$dstPlaceholder`"],`"ip`":[`"tcp:443`"]}]}")
    [Console]::Error.WriteLine('          (src = your identity/group; dst = THIS host only, never "*"; ip = the serve port.)')
    [Console]::Error.WriteLine('Step 3. Save. Tailscale is deny-by-default once any grant exists, so every other device is')
    [Console]::Error.WriteLine('        now denied.')
    [Console]::Error.WriteLine("Step 4. Verify from your laptop: open $urlPlaceholder -- it should load for you, and a")
    [Console]::Error.WriteLine('        non-authorized device should get connection-refused/forbidden.')
    [Console]::Error.WriteLine('(AID cannot edit your tailnet policy for you -- it is admin-plane, and the dashboard never')
    [Console]::Error.WriteLine("runs an agent/LLM at runtime. See 'aid dashboard' docs / feature-005 SEC-2.)")
    [Console]::Error.WriteLine('Note (SEC-6): the exposed surface is the CLI home -- all registered repos (paths/names) are')
    [Console]::Error.WriteLine('visible to the granted identities. This is the accepted trade-off (OQ5): grantees are trusted')
    [Console]::Error.WriteLine('operators of this host. Never-public and host/user-ACL scoping (C1/C3) are unchanged.')
    [Console]::Error.WriteLine('')

    # Step 6: Emit handle + URL on stdout, exit 0.
    Write-Output "tailscale-serve:$Port"
    Write-Output $privateUrl
    return 0
}

# Invoke-AidRemoteTeardown -Handle <s>
# Revert the tailscale serve mapping created by Invoke-AidRemoteExpose.
# exit: 0=ok/idempotent  13=revert warned
function script:Invoke-AidRemoteTeardown {
    param([string]$Handle = '')

    # Step 1: Parse the handle; malformed/empty -> idempotent exit 0.
    if ([string]::IsNullOrEmpty($Handle)) {
        return 0
    }
    if ($Handle -notmatch '^tailscale-serve:([0-9]+)$') {
        # Malformed handle -- nothing to tear down.
        return 0
    }
    # We don't use the port for teardown (we target the HTTPS:443 frontend, not the backend port).

    # Step 2: If tailscale is gone now -> WARN, exit 0.
    if (-not (Get-Command 'tailscale' -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("WARN: aid: dashboard: tailscale not found; cannot revert serve mapping (handle: $Handle)")
        return 0
    }

    # Step 3: Revert the HTTPS:443 frontend mapping (not a backend port off).
    $offErr = ''
    $offRc  = 0
    try {
        $offErr = (& tailscale serve --bg --https=443 off 2>&1) -join "`n"
        $offRc  = $LASTEXITCODE
    } catch {
        $offErr = "$_"
        $offRc  = 1
    }
    if ($offRc -ne 0) {
        # Fallback: check if serve status shows no other mappings; if so, reset.
        $srvStatus = ''
        try { $srvStatus = (& tailscale serve status 2>&1) -join "`n" } catch { $srvStatus = '' }
        $mappingCount = ([regex]::Matches($srvStatus, '(?:https?://|tcp://)') | Measure-Object).Count
        if ($mappingCount -le 1) {
            try { & tailscale serve reset 2>&1 | Out-Null } catch {}
            # After reset, exit 0 -- best effort.
            return 0
        }
        [Console]::Error.WriteLine("WARN: aid: dashboard: tailscale serve --https=443 off failed (rc=${offRc}): $offErr")
        return 13
    }

    # Step 4: exit 0 on clean revert.
    return 0
}

# ---------------------------------------------------------------------------
# Dashboard control (aid dashboard start|stop).
# ---------------------------------------------------------------------------
function script:Invoke-AidDashboardCtl {
    param([string[]]$DcArgs)

    $verb = if ($DcArgs.Count -gt 0) { $DcArgs[0] } else { '' }
    $rest = if ($DcArgs.Count -gt 1) { $DcArgs[1..($DcArgs.Count - 1)] } else { @() }

    # Top-level help.
    if ($verb -in @('-h', '--help', '-Help')) {
        script:Show-AidUsage 'dashboard'
        script:Exit-Aid 0
    }

    if ($verb -ne 'start' -and $verb -ne 'stop') {
        if ([string]::IsNullOrEmpty($verb)) {
            [Console]::Error.WriteLine('ERROR: aid: dashboard requires a verb: start or stop (e.g. aid dashboard start python)')
            script:Exit-Aid 2
        }
        [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown verb '$verb' (expected: start or stop)")
        script:Exit-Aid 2
    }

    # --- shared arg parsing ---
    $dcTarget  = ''
    $dcVerbose = $false
    $dcPort    = 8787
    $dcRemote  = $false
    $dcRuntime = ''

    $idx = 0
    if ($verb -eq 'start') {
        # First positional after verb is runtime (if not a flag).
        if ($rest.Count -gt 0 -and -not $rest[0].StartsWith('-')) {
            $dcRuntime = $rest[0]
            $idx = 1
        }
    }

    while ($idx -lt $rest.Count) {
        $a = $rest[$idx]
        switch ($a) {
            { $_ -in @('-h', '--help', '-Help') } {
                script:Show-AidUsage 'dashboard'
                script:Exit-Aid 0
            }
            { $_ -in @('-Target', '--target') } {
                $idx++
                if ($idx -ge $rest.Count) {
                    [Console]::Error.WriteLine('ERROR: aid: dashboard: --target requires a value')
                    script:Exit-Aid 2
                }
                $dcTarget = $rest[$idx]
            }
            { $_ -in @('-Verbose', '--verbose') } { $dcVerbose = $true }
            { $_ -in @('-Remote', '--remote') } {
                if ($verb -eq 'stop') {
                    [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown flag: $a")
                    script:Exit-Aid 2
                }
                $dcRemote = $true
            }
            { $_ -in @('-Port', '--port') } {
                if ($verb -eq 'stop') {
                    [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown flag: $a")
                    script:Exit-Aid 2
                }
                $idx++
                if ($idx -ge $rest.Count) {
                    [Console]::Error.WriteLine('ERROR: aid: dashboard: --port requires a value')
                    script:Exit-Aid 2
                }
                $portVal = $rest[$idx]
                if ($portVal -notmatch '^\d+$' -or [int]$portVal -lt 1024 -or [int]$portVal -gt 65535) {
                    [Console]::Error.WriteLine('ERROR: aid: dashboard: --port must be an integer in 1024..65535')
                    script:Exit-Aid 2
                }
                $dcPort = [int]$portVal
            }
            default {
                if ($a.StartsWith('-')) {
                    [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown flag: $a")
                    script:Exit-Aid 2
                }
                # Stray positional.
                [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown flag: $a")
                script:Exit-Aid 2
            }
        }
        $idx++
    }

    # Apply env-var fallback for target.
    if (-not $dcTarget -and $env:AID_TARGET) { $dcTarget = $env:AID_TARGET }
    if (-not $dcTarget) { $dcTarget = '.' }
    if (-not (Test-Path $dcTarget -PathType Container)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: target directory does not exist: $dcTarget")
        script:Exit-Aid 2
    }
    $dcTarget = (Resolve-Path -LiteralPath $dcTarget).Path

    if ($verb -eq 'start') {
        script:Invoke-DcStart -Runtime $dcRuntime -Port $dcPort -Remote $dcRemote -Target $dcTarget -Verbose $dcVerbose
    } else {
        script:Invoke-DcStop -Target $dcTarget -Verbose $dcVerbose
    }
}

function script:Invoke-DcStart {
    param([string]$Runtime, [int]$Port, [bool]$Remote, [string]$Target, [bool]$Verbose)

    # Step 1: validate runtime.
    if ([string]::IsNullOrEmpty($Runtime)) {
        [Console]::Error.WriteLine('ERROR: aid: dashboard start requires a runtime: node or python (e.g. aid dashboard start python)')
        script:Exit-Aid 2
    }
    if ($Runtime -ne 'node' -and $Runtime -ne 'python') {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown runtime '$Runtime' (expected: node or python)")
        script:Exit-Aid 2
    }

    # Step 3: check .aid/ exists.
    if (-not (Test-Path (Join-Path $Target '.aid') -PathType Container)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: no AID install found at $Target (run 'aid add <tool>' first)")
        script:Exit-Aid 7
    }

    $pidFile = Join-Path $Target (Join-Path '.aid' (Join-Path '.temp' 'dashboard.pid'))
    $logFile = Join-Path $Target (Join-Path '.aid' (Join-Path '.temp' 'dashboard.log'))

    # Step 4: already-running guard (stale-record reclaim included).
    if (Test-Path $pidFile -PathType Leaf) {
        $pidContent = Get-Content -LiteralPath $pidFile -Raw -ErrorAction SilentlyContinue
        $existingPid  = 0
        $existingPort = 0
        $existingRuntime = ''
        if ($pidContent -match '"pid"\s*:\s*(\d+)') { $existingPid = [int]$matches[1] }
        if ($pidContent -match '"port"\s*:\s*(\d+)') { $existingPort = [int]$matches[1] }
        if ($pidContent -match '"runtime"\s*:\s*"([^"]+)"') { $existingRuntime = $matches[1] }
        $procAlive = $false
        if ($existingPid -gt 0) {
            try { $null = Get-Process -Id $existingPid -ErrorAction Stop; $procAlive = $true } catch {}
        }
        if ($procAlive) {
            Write-Host "aid: dashboard already running (runtime $existingRuntime, http://127.0.0.1:${existingPort}); run 'aid dashboard stop' first."
            script:Exit-Aid 8
        } else {
            # Stale record: reclaim silently (or verbosely).
            if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: reclaiming stale record (pid $existingPid is dead)") }
            Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
            if (Test-Path $logFile -PathType Leaf) { Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue }
        }
    }

    # Step 5: check runtime on PATH.
    if ($Runtime -eq 'python') {
        $interp = 'python3'
        if (-not (Get-Command 'python3' -ErrorAction SilentlyContinue)) {
            [Console]::Error.WriteLine('ERROR: aid: dashboard: python3 not found on PATH (install it, or try: aid dashboard start node)')
            script:Exit-Aid 9
        }
    } else {
        $interp = 'node'
        if (-not (Get-Command 'node' -ErrorAction SilentlyContinue)) {
            [Console]::Error.WriteLine('ERROR: aid: dashboard: node not found on PATH (install it, or try: aid dashboard start python)')
            script:Exit-Aid 9
        }
    }

    # Step 6: locate the server entry point.
    # <assets> = $AID_HOME/dashboard (the co-vendored server+reader unit in the install tree).
    $assetsDir = Join-Path $script:_AidHome 'dashboard'
    if ($Runtime -eq 'python') {
        $entryPoint = Join-Path $assetsDir (Join-Path 'server' 'server.py')
    } else {
        $entryPoint = Join-Path $assetsDir (Join-Path 'server' 'server.mjs')
    }
    if (-not (Test-Path $entryPoint -PathType Leaf)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: the dashboard server is missing from the install tree ($Runtime entry-point not found at $entryPoint); run 'aid update' or reinstall aid")
        script:Exit-Aid 7
    }

    # Ensure log dir exists.
    $tempDir = Join-Path $Target (Join-Path '.aid' '.temp')
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Step 7: spawn the server child (detached daemon).
    # SEC-1: literal 127.0.0.1 -- never read from input/config/env.
    # WINDOWS/POWERSHELL: do NOT pass -RedirectStandardOutput/-RedirectStandardError here.
    # Start-Process WITH redirection uses full handle inheritance, so the long-lived server
    # inherits and holds open the caller's stdout/stderr pipe; a caller that captures our output
    # (e.g. `$out = aid dashboard start 2>&1`, as the CI smoke does) then HANGS forever waiting
    # for EOF. Omitting redirection makes Start-Process use ShellExecute, which does NOT inherit
    # the caller's handles (no hang) and fully detaches the daemon -- the Windows analog of the
    # Bash launcher's `setsid`. Trade-off: the server's own stdout/stderr are not file-captured on
    # Windows; readiness is verified by TCP poll (not the log), so start/stop/status are
    # behaviour-identical. (KI: Windows dashboard server log not captured; Bash captures it via
    # `setsid ... >"$log_file" 2>&1`.)
    # The multi-repo server (feature-010) serves every registered repo from the registry
    # under AID_HOME; AID_HOME is set in the child's environment explicitly so the server
    # resolves it via env-or-self-locate (delivery-008 refinement: no --aid-home flag).
    $env:AID_HOME = $script:_AidHome
    $spawnArgs = @($entryPoint, '--host', '127.0.0.1', '--port', "$Port")
    $proc = Start-Process -FilePath $interp `
        -ArgumentList $spawnArgs `
        -PassThru `
        -WindowStyle Hidden

    $childPid = $proc.Id

    if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: spawned $Runtime server (pid $childPid, port $Port)") }

    # Step 8: bounded readiness wait (~5s, poll TCP socket).
    $ready      = $false
    $attempts   = 0
    $maxAttempts = 50   # 50 x 0.1s = 5s
    while ($attempts -lt $maxAttempts) {
        # Check child is still alive.
        $childAlive = $false
        try { $null = Get-Process -Id $childPid -ErrorAction Stop; $childAlive = $true } catch {}
        if (-not $childAlive) {
            # Child exited early.
            [Console]::Error.WriteLine('ERROR: aid: dashboard: server failed to start (last log lines, if any):')
            if (Test-Path $logFile -PathType Leaf) {
                Get-Content -LiteralPath $logFile -Tail 10 -ErrorAction SilentlyContinue | ForEach-Object { [Console]::Error.WriteLine($_) }
                Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
            }
            script:Exit-Aid 3
        }
        # Try TCP connect to 127.0.0.1:<Port>.
        try {
            $tcpClient = [System.Net.Sockets.TcpClient]::new()
            $tcpClient.Connect('127.0.0.1', $Port)
            $tcpClient.Close()
            $ready = $true
            break
        } catch {}
        Start-Sleep -Milliseconds 100
        $attempts++
    }

    # Check if child is still alive even if not ready (timeout case).
    if (-not $ready) {
        $childAlive = $false
        try { $null = Get-Process -Id $childPid -ErrorAction Stop; $childAlive = $true } catch {}
        if (-not $childAlive) {
            [Console]::Error.WriteLine('ERROR: aid: dashboard: server failed to start (last log lines, if any):')
            if (Test-Path $logFile -PathType Leaf) {
                Get-Content -LiteralPath $logFile -Tail 10 -ErrorAction SilentlyContinue | ForEach-Object { [Console]::Error.WriteLine($_) }
                Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
            }
            script:Exit-Aid 3
        }
        # Timeout but pid alive: warn and continue.
        [Console]::Error.WriteLine("WARN: aid: dashboard: server started but not yet responding on :${Port}; check $logFile")
    }

    # Step 9: write dashboard.pid JSON record (DM-1).
    $startedAt = [System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    if (-not $startedAt) { $startedAt = 'unknown' }
    # String.Replace (literal) doubles each backslash for valid JSON on Windows paths.
    $pidJson = @"
{
  "schema": 1,
  "pid": $childPid,
  "runtime": "$Runtime",
  "port": $Port,
  "bind": "127.0.0.1",
  "remote": false,
  "remote_handle": null,
  "started_at": "$startedAt",
  "target": "$($Target.Replace('\', '\\'))",
  "logfile": "$($logFile.Replace('\', '\\'))"
}
"@
    [System.IO.File]::WriteAllText($pidFile, $pidJson)

    # Step 10: --remote: invoke Invoke-AidRemoteExpose; update record on success.
    if ($Remote) {
        # Capture all pipeline output; let stderr (guidance + errors) flow to the user.
        # Invoke-AidRemoteExpose emits handle+URL via Write-Output (strings) and the return
        # integer via 'return <n>' -- both land on the pipeline. We split by type.
        $rawOut = @(script:Invoke-AidRemoteExpose -Port $Port)
        $exposeRc     = 0
        $exposeHandle = ''
        $exposeUrl    = ''
        $strLines     = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $rawOut) {
            if ($item -is [int]) { $exposeRc = $item }
            elseif ($item -ne $null) { $strLines.Add([string]$item) }
        }
        if ($exposeRc -ne 0) {
            # All expose failures (10/11/12) map to user-facing exit 10.
            # dashboard stays local-only (server remains running).
            [Console]::Error.WriteLine("ERROR: aid: dashboard: --remote requested but the secure remote-exposure mechanism is not available on this host; the dashboard is NOT exposed. Local server still running at http://127.0.0.1:${Port}.")
            script:Exit-Aid 10
        }
        if ($strLines.Count -ge 1) { $exposeHandle = $strLines[0] }
        if ($strLines.Count -ge 2) { $exposeUrl    = $strLines[1] }
        # Update the record with remote=true and the handle.
        $pidJson2 = @"
{
  "schema": 1,
  "pid": $childPid,
  "runtime": "$Runtime",
  "port": $Port,
  "bind": "127.0.0.1",
  "remote": true,
  "remote_handle": "$exposeHandle",
  "started_at": "$startedAt",
  "target": "$($Target.Replace('\', '\\'))",
  "logfile": "$($logFile.Replace('\', '\\'))"
}
"@
        [System.IO.File]::WriteAllText($pidFile, $pidJson2)
        # Step 11 (remote success): print local URL + remote URL.
        Write-Host "Dashboard ($Runtime) running at http://127.0.0.1:${Port} -- stop with: aid dashboard stop"
        if ($exposeUrl -like 'https://*') {
            Write-Host "Remote (private): $exposeUrl"
        } else {
            Write-Host "Remote exposure is UP (tailnet-private), but the .ts.net URL could not be auto-detected -- run 'tailscale status' on this host to find it."
        }
        # DR-1 registry side-effect: auto-register the dashboard target repo (idempotent).
        script:Registry-Register -Repo $Target
        script:Exit-Aid 0
    }

    # Step 11: print success (local-only).
    Write-Host "Dashboard ($Runtime) running at http://127.0.0.1:${Port} -- stop with: aid dashboard stop"
    # DR-1 registry side-effect: auto-register the dashboard target repo (idempotent).
    script:Registry-Register -Repo $Target
    script:Exit-Aid 0
}

function script:Invoke-DcStop {
    param([string]$Target, [bool]$Verbose)

    $pidFile = Join-Path $Target (Join-Path '.aid' (Join-Path '.temp' 'dashboard.pid'))

    # Step 3: read record; absent or stale -> idempotent exit 0.
    if (-not (Test-Path $pidFile -PathType Leaf)) {
        Write-Host 'aid: dashboard: not running (nothing to stop).'
        script:Exit-Aid 0
    }

    $pidContent = Get-Content -LiteralPath $pidFile -Raw -ErrorAction SilentlyContinue
    $existingPid = 0
    $logFile     = ''
    if ($pidContent -match '"pid"\s*:\s*(\d+)') { $existingPid = [int]$matches[1] }
    if ($pidContent -match '"logfile"\s*:\s*"([^"]+)"') { $logFile = $matches[1] }

    $procAlive = $false
    if ($existingPid -gt 0) {
        try { $null = Get-Process -Id $existingPid -ErrorAction Stop; $procAlive = $true } catch {}
    }

    if (-not $procAlive) {
        if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: record exists but pid $existingPid is dead; cleaning up.") }
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        if ($logFile -and (Test-Path $logFile -PathType Leaf)) { Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue }
        Write-Host 'aid: dashboard: not running (nothing to stop).'
        script:Exit-Aid 0
    }

    # Step 4: --remote teardown (if the record says remote=true, call Invoke-AidRemoteTeardown).
    $existingRemote = ''
    $existingHandle = ''
    if ($pidContent -match '"remote"\s*:\s*(true|false)') { $existingRemote = $matches[1] }
    if ($pidContent -match '"remote_handle"\s*:\s*"([^"]*)"') { $existingHandle = $matches[1] }
    if ($existingRemote -eq 'true' -and -not [string]::IsNullOrEmpty($existingHandle)) {
        if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: tearing down remote exposure (handle: $existingHandle)") }
        $teardownRc = script:Invoke-AidRemoteTeardown -Handle $existingHandle
        if ($teardownRc -eq 13) {
            [Console]::Error.WriteLine('WARN: aid: dashboard: remote teardown reported a warning; continuing server shutdown')
        }
    }

    # Step 5: terminate the process cleanly.
    if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: sending Stop-Process to pid $existingPid") }
    try { Stop-Process -Id $existingPid -ErrorAction SilentlyContinue } catch {}

    # Wait up to ~5s for exit.
    $waited = 0
    while ($waited -lt 50) {
        $stillAlive = $false
        try { $null = Get-Process -Id $existingPid -ErrorAction Stop; $stillAlive = $true } catch {}
        if (-not $stillAlive) { break }
        Start-Sleep -Milliseconds 100
        $waited++
    }

    # Escalate to -Force if still alive.
    $stillAlive = $false
    try { $null = Get-Process -Id $existingPid -ErrorAction Stop; $stillAlive = $true } catch {}
    if ($stillAlive) {
        if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: escalating to Stop-Process -Force on pid $existingPid") }
        try { Stop-Process -Id $existingPid -Force -ErrorAction SilentlyContinue } catch {}
    }

    # Step 6: remove record and logfile, print success.
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    if ($logFile -and (Test-Path $logFile -PathType Leaf)) { Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue }
    Write-Host 'aid: dashboard stopped.'
    script:Exit-Aid 0
}

# ---------------------------------------------------------------------------
# Wrap everything in try/catch for terminal-survival in piped/iex mode.
# ---------------------------------------------------------------------------
try {

# ---------------------------------------------------------------------------
# Parse raw args.
# aid.ps1 is invoked by aid.cmd which forwards all args as positional strings.
# We parse manually to support both flag-style and positional style uniformly.
# ---------------------------------------------------------------------------
$script:_RawArgs = $args

# Resolve verbose from env var first (flag overrides below).
$script:_AidVerbose = ($env:AID_VERBOSE -eq '1')

# ---- Bare aid -> dashboard landing screen ----
if ($script:_RawArgs.Count -eq 0) {
    # Block 1 + 2: Header + description.
    $cliVersion = 'unknown'
    $verFile = Join-Path $script:_AidHome 'VERSION'
    if (Test-Path $verFile -PathType Leaf) {
        $cliVersion = (Get-Content -LiteralPath $verFile -Raw).Trim()
    }
    Write-Host "AID v$cliVersion - Agentic Iterative Development"
    Write-Host "Install, update, and manage AID across your repositories."

    # Block 3: Installed tools for cwd.
    Write-Host ""
    $null = Get-AidStatusBody -Target '.'

    # Block 4: Usage/help.
    Write-Host ""
    script:Show-AidUsage

    # Block 5: Update check notice (final line, non-blocking).
    script:Invoke-AidUpdateCheck
    # Block 6: Migration sentinel (FF-4 / DM-3 / task-080).
    script:Invoke-AidMigrateSentinel
    script:Exit-Aid 0
}

# ---- Early -h / --help ----
if ($script:_RawArgs[0] -in @('-h', '--help', '-Help', '/help', '/?')) {
    script:Show-AidUsage
    script:Exit-Aid 0
}

$SUBCMD = $script:_RawArgs[0]
$script:_RemArgs = @($script:_RawArgs | Select-Object -Skip 1)

# ---------------------------------------------------------------------------
# version
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'version') {
    $versionFile = Join-Path $script:_AidHome 'VERSION'
    if (Test-Path $versionFile -PathType Leaf) {
        Write-Host (Get-Content -LiteralPath $versionFile -Raw).Trim()
    } else {
        Write-Host "unknown (VERSION file not found at $versionFile)"
    }
    script:Exit-Aid 0
}

# ---------------------------------------------------------------------------
# help (bare 'aid help' still works as general help)
# ---------------------------------------------------------------------------
if ($SUBCMD -in @('help', '-h', '--help')) {
    script:Show-AidUsage
    script:Exit-Aid 0
}

# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'status') {
    $statusTarget  = ''
    $remIdx = 0
    while ($remIdx -lt $script:_RemArgs.Count) {
        $a = $script:_RemArgs[$remIdx]
        switch ($a) {
            { $_ -in @('-Target', '--target') } {
                $remIdx++
                if ($remIdx -ge $script:_RemArgs.Count) { script:Fail-Aid "-Target requires a value" 2 }
                $statusTarget = $script:_RemArgs[$remIdx]
            }
            { $_ -in @('-Verbose', '--verbose') } { $script:_AidVerbose = $true; $env:AID_VERBOSE = '1' }
            { $_ -in @('-h', '--help', '-Help') }  { script:Show-AidUsage 'status'; script:Exit-Aid 0 }
            default {
                if ($a.StartsWith('-')) {
                    script:Fail-Aid "unknown flag for status: $a" 2
                } else {
                    script:Fail-Aid "unexpected argument for status: $a" 2
                }
            }
        }
        $remIdx++
    }

    # Apply env-var fallback.
    if (-not $statusTarget -and $env:AID_TARGET) { $statusTarget = $env:AID_TARGET }
    if (-not $statusTarget) { $statusTarget = '.' }
    if ($script:_AidVerbose) { $env:AID_VERBOSE = '1' }

    $rc = Get-AidStatus -Target $statusTarget
    # Update check notice appended after status output (non-blocking).
    script:Invoke-AidUpdateCheck
    # Migration sentinel (FF-4 / DM-3 / task-080).
    script:Invoke-AidMigrateSentinel
    script:Exit-Aid $rc
}
# ---------------------------------------------------------------------------
# Registry helpers (DR-1 / FF-1 / FR29 -- PS twin of Bash registry_register /
# registry_unregister).  Implements DM-1 schema, DD-3 Move-Item -Force atomic
# write, DD-REG-FMT line-scan (no YAML library).
# ---------------------------------------------------------------------------

# Read the repos list from registry.yml (line-scan, no YAML parser).
# Returns [string[]] of canonical paths; empty array when file is absent.
function script:Get-RegistryRepos {
    param([string]$RegPath)
    if (-not (Test-Path $RegPath -PathType Leaf)) { return @() }
    $results = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-Content -LiteralPath $RegPath -Encoding utf8 -ErrorAction SilentlyContinue)) {
        if ($line -match '^\s*-\s+(.+\S)\s*$') {
            $results.Add($Matches[1])
        }
    }
    return $results.ToArray()
}

# Register a canonical repo path in $AidHome/registry.yml (set-insert, idempotent).
# Prints one line on a real change; silent on no-op.  Prints WARN on failure; never
# throws (host-tool op is never blocked -- NFR10 / DD-3 / CLI-1).
function script:Registry-Register {
    param([string]$Repo)
    $reg = Join-Path $script:_AidHome 'registry.yml'
    if (-not (Test-Path $script:_AidHome -PathType Container)) {
        New-Item -ItemType Directory -Path $script:_AidHome -Force | Out-Null
    }
    $existing = @(script:Get-RegistryRepos -RegPath $reg)
    # Idempotent: already registered -> silent no-op.
    if ($existing -contains $Repo) {
        if ($script:_AidVerbose) { Write-Host "Registry: $Repo already registered (no-op)." }
        return
    }
    $tmp = Join-Path $script:_AidHome ("registry.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $all = ($existing + @($Repo)) | Where-Object { $_ } | Sort-Object -Unique
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add("# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).")
        $lines.Add("# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/")
        $lines.Add("# description/version are read from each repo's own .aid/settings.yml at render time.")
        $lines.Add("schema: 1")
        $lines.Add("repos:")
        foreach ($p in $all) { $lines.Add("  - $p") }
        Set-Content -LiteralPath $tmp -Value $lines -Encoding utf8NoBOM -ErrorAction Stop
        Move-Item -LiteralPath $tmp -Destination $reg -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid: could not update the machine repo registry ($reg): $_")
        return
    }
    Write-Host "Registered $Repo with the AID CLI."
}

# Unregister a canonical repo path from $AidHome/registry.yml (set-remove, idempotent).
# Called only when the repo manifest is now gone (last tool removed).
# Prints one line on a real change; silent on no-op.  Prints WARN on failure; never throws.
function script:Registry-Unregister {
    param([string]$Repo)
    $reg = Join-Path $script:_AidHome 'registry.yml'
    if (-not (Test-Path $reg -PathType Leaf)) { return }
    $existing = @(script:Get-RegistryRepos -RegPath $reg)
    # Idempotent: not registered -> silent no-op.
    if ($existing -notcontains $Repo) {
        if ($script:_AidVerbose) { Write-Host "Registry: $Repo not in registry (no-op)." }
        return
    }
    $tmp = Join-Path $script:_AidHome ("registry.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $remaining = $existing | Where-Object { $_ -ne $Repo } | Sort-Object -Unique
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add("# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).")
        $lines.Add("# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/")
        $lines.Add("# description/version are read from each repo's own .aid/settings.yml at render time.")
        $lines.Add("schema: 1")
        $lines.Add("repos:")
        if ($remaining) { foreach ($p in $remaining) { $lines.Add("  - $p") } }
        Set-Content -LiteralPath $tmp -Value $lines -Encoding utf8NoBOM -ErrorAction Stop
        Move-Item -LiteralPath $tmp -Destination $reg -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid: could not update the machine repo registry ($reg): $_")
        return
    }
    Write-Host "Unregistered $Repo from the AID CLI."
}

# ---------------------------------------------------------------------------
# Invoke-AidMigrateRepo <repo>  (FF-1 / LC-MIG / task-077)
# Per-repo migration core -- PS twin of bash _aid_migrate_repo.
# Runs DETECT->SETTINGS->ADD->RELOCATE->REGISTER in order.
# Each step is WARN-not-fail: a step failure emits WARN and the next step runs.
# Always returns 0 (SEC-4 / NFR12).  <repo> is a canonical repo base folder.
# ---------------------------------------------------------------------------
function script:Invoke-AidMigrateRepo {
    param([string]$Repo)

    # ------------------------------------------------------------------
    # STEP 0 -- DETECT / QUALIFY (DD-6 / SEC-1) -- read-only.
    # ------------------------------------------------------------------
    $aidDir = Join-Path $Repo '.aid'
    if (-not (Test-Path $aidDir -PathType Container)) { return 0 }

    $settingsPath  = Join-Path $aidDir 'settings.yml'
    $kbDir         = Join-Path $aidDir 'knowledge'
    $dsA           = Join-Path $kbDir 'DISCOVERY_STATE.md'
    $dsB           = Join-Path $kbDir 'DISCOVERY-STATE.md'
    $dsC           = Join-Path $kbDir 'STATE.md'

    $era = ''
    if (Test-Path $settingsPath -PathType Leaf) {
        $era = 'a'
    } elseif ((Test-Path $dsA -PathType Leaf) -or (Test-Path $dsB -PathType Leaf) -or (Test-Path $dsC -PathType Leaf)) {
        $era = 'b'
    } else {
        return 0   # bare .aid/ -- not a candidate
    }

    $repoName  = Split-Path $Repo -Leaf
    $manifest  = Join-Path $aidDir '.aid-manifest.json'

    # ------------------------------------------------------------------
    # STEP 1 -- SETTINGS (DM-1 / task-074 contract)
    # ------------------------------------------------------------------
    if ($era -eq 'a') {
        try {
            script:Invoke-AidRepairSettingsEraA -SettingsFile $settingsPath -RepoName $repoName
        } catch {
            [Console]::Error.WriteLine("WARN: aid migrate: settings repair failed for ${settingsPath}: $_")
        }
    } else {
        try {
            script:Invoke-AidSynthesizeSettingsEraB -SettingsFile $settingsPath -RepoName $repoName -ManifestPath $manifest
        } catch {
            [Console]::Error.WriteLine("WARN: aid migrate: settings synthesis failed for ${settingsPath}: $_")
        }
    }

    # ------------------------------------------------------------------
    # STEP 2 -- ADD home.html (FR40 / RC-2) -- copy-when-absent only.
    # ------------------------------------------------------------------
    $dashDir   = Join-Path $aidDir 'dashboard'
    $htmlDest  = Join-Path $dashDir 'home.html'
    if (-not (Test-Path $htmlDest -PathType Leaf)) {
        $htmlSrc = Join-Path $script:_AidHome 'dashboard' | Join-Path -ChildPath 'home.html'
        if (Test-Path $htmlSrc -PathType Leaf) {
            try {
                if (-not (Test-Path $dashDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $dashDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $htmlSrc -Destination $htmlDest -ErrorAction Stop
            } catch {
                [Console]::Error.WriteLine("WARN: aid migrate: copy home.html failed for ${Repo}: $_")
            }
        } else {
            [Console]::Error.WriteLine("WARN: aid migrate: home.html source not found at ${htmlSrc} (continuing)")
        }
    }

    # ------------------------------------------------------------------
    # STEP 3 -- RELOCATE legacy summary (DM-4 / FR31) -- no-clobber mv.
    # ------------------------------------------------------------------
    $oldSummary = Join-Path $aidDir 'knowledge' | Join-Path -ChildPath 'knowledge-summary.html'
    $newSummary = Join-Path $dashDir 'kb.html'
    if ((Test-Path $oldSummary -PathType Leaf) -and (-not (Test-Path $newSummary -PathType Leaf))) {
        try {
            if (-not (Test-Path $dashDir -PathType Container)) {
                New-Item -ItemType Directory -Path $dashDir -Force | Out-Null
            }
            Move-Item -LiteralPath $oldSummary -Destination $newSummary -ErrorAction Stop
        } catch {
            [Console]::Error.WriteLine("WARN: aid migrate: relocate legacy summary failed for ${Repo}: $_")
        }
    }

    # ------------------------------------------------------------------
    # STEP 4 -- REGISTER (DM-2 / FR28) -- existing idempotent writer.
    # ------------------------------------------------------------------
    try {
        script:Registry-Register -Repo $Repo
    } catch {
        [Console]::Error.WriteLine("WARN: aid migrate: registry_register failed for ${Repo}: $_")
    }

    return 0
}

# script:Invoke-AidRepairSettingsEraA <SettingsFile> <RepoName>
# Era-a: validate/repair REQUIRED keys via targeted edits only.
# A valid file -> no write (idempotent).
function script:Invoke-AidRepairSettingsEraA {
    param([string]$SettingsFile, [string]$RepoName)
    if (-not (Test-Path $SettingsFile -PathType Leaf)) { throw "settings file not found" }

    $lines   = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $SettingsFile -Encoding utf8 -ErrorAction Stop)
    $changed = $false

    # ---- locate section header index ("^<sect>:\s*$") ----
    $findSection = {
        param([string]$sect)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^${sect}:\s*$") { return $i }
        }
        return -1
    }

    # ---- locate indented key index inside a section ----
    $findKeyInSection = {
        param([int]$sectIdx, [string]$key)
        for ($i = $sectIdx + 1; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i]
            if ($ln -match '^[a-zA-Z_]') { return -1 }
            if ($ln -match "^\s+${key}:") { return $i }
        }
        return -1
    }

    # ---- get scalar value from "  key: value" line ----
    $getScalarValue = {
        param([string]$ln, [string]$key)
        $v = ($ln -replace "^\s+${key}:\s*", '') -replace '\s*#.*$', ''
        $v = $v.Trim().Trim('"').Trim("'")
        return $v
    }

    # ---- insert a line after index ----
    $insertAfter = {
        param([int]$idx, [string]$newLine)
        $lines.Insert($idx + 1, $newLine)
        $changed = $true
    }

    # ---- append a block at EOF ----
    # Prepends a blank line so the new section is visually separated from the
    # preceding content (matching the template's blank-line-between-sections style).
    # Idempotency is preserved: on a 2nd run the section exists, so this path is skipped.
    $appendBlock = {
        param([string]$block)
        $lines.Add("")
        foreach ($bl in ($block -split "`n")) {
            $lines.Add($bl)
        }
        $changed = $true
    }

    # ---- replace single line (IDIOM-A) ----
    $replaceLine = {
        param([int]$idx, [string]$newLine)
        $lines[$idx] = $newLine
        $changed = $true
    }

    # --- project section ---
    $projIdx = & $findSection 'project'
    if ($projIdx -eq -1) {
        & $appendBlock "project:`n  name: ${RepoName}`n  description: <project-description>`n  type: brownfield"
        $changed = $true
    } else {
        $nameIdx = & $findKeyInSection $projIdx 'name'
        if ($nameIdx -eq -1) {
            & $insertAfter $projIdx "  name: ${RepoName}"; $changed = $true
        } else {
            $nv = & $getScalarValue $lines[$nameIdx] 'name'
            if ([string]::IsNullOrEmpty($nv)) { & $replaceLine $nameIdx "  name: ${RepoName}"; $changed = $true }
        }

        $descIdx = & $findKeyInSection $projIdx 'description'
        if ($descIdx -eq -1) {
            $nameIdx2 = & $findKeyInSection $projIdx 'name'
            $insAfterDesc = if ($nameIdx2 -ne -1) { $nameIdx2 } else { $projIdx }
            & $insertAfter $insAfterDesc '  description: <project-description>'; $changed = $true
        }

        $typeIdx = & $findKeyInSection $projIdx 'type'
        if ($typeIdx -eq -1) {
            $descIdx2 = & $findKeyInSection $projIdx 'description'
            $nameIdx3 = & $findKeyInSection $projIdx 'name'
            $insAfterType = if ($descIdx2 -ne -1) { $descIdx2 } elseif ($nameIdx3 -ne -1) { $nameIdx3 } else { $projIdx }
            & $insertAfter $insAfterType '  type: brownfield'; $changed = $true
        } else {
            $tv = & $getScalarValue $lines[$typeIdx] 'type'
            if ($tv -ne 'brownfield' -and $tv -ne 'greenfield') {
                & $replaceLine $typeIdx '  type: brownfield'; $changed = $true
            }
        }
    }

    # --- tools section ---
    $toolsIdx = & $findSection 'tools'
    if ($toolsIdx -eq -1) {
        & $appendBlock "tools:`n  installed: []"; $changed = $true
    } else {
        $instIdx = & $findKeyInSection $toolsIdx 'installed'
        if ($instIdx -eq -1) { & $insertAfter $toolsIdx '  installed: []'; $changed = $true }
    }

    # --- review section ---
    $revIdx = & $findSection 'review'
    if ($revIdx -eq -1) {
        & $appendBlock "review:`n  minimum_grade: A"; $changed = $true
    } else {
        $mgIdx = & $findKeyInSection $revIdx 'minimum_grade'
        if ($mgIdx -eq -1) {
            & $insertAfter $revIdx '  minimum_grade: A'; $changed = $true
        } else {
            $mv = & $getScalarValue $lines[$mgIdx] 'minimum_grade'
            if ($mv -notmatch '^[A-F][+-]?$') { & $replaceLine $mgIdx '  minimum_grade: A'; $changed = $true }
        }
    }

    # --- execution section ---
    $execIdx = & $findSection 'execution'
    if ($execIdx -eq -1) {
        & $appendBlock "execution:`n  max_parallel_tasks: 5"; $changed = $true
    } else {
        $mptIdx = & $findKeyInSection $execIdx 'max_parallel_tasks'
        if ($mptIdx -eq -1) {
            & $insertAfter $execIdx '  max_parallel_tasks: 5'; $changed = $true
        } else {
            $mv2 = & $getScalarValue $lines[$mptIdx] 'max_parallel_tasks'
            if ($mv2 -notmatch '^\d+$' -or [int]$mv2 -le 0) {
                & $replaceLine $mptIdx '  max_parallel_tasks: 5'; $changed = $true
            }
        }
    }

    # --- traceability section ---
    $traceIdx = & $findSection 'traceability'
    if ($traceIdx -eq -1) {
        & $appendBlock "traceability:`n  heartbeat_interval: 1"; $changed = $true
    } else {
        $hbIdx = & $findKeyInSection $traceIdx 'heartbeat_interval'
        if ($hbIdx -eq -1) {
            & $insertAfter $traceIdx '  heartbeat_interval: 1'; $changed = $true
        } else {
            $hv = & $getScalarValue $lines[$hbIdx] 'heartbeat_interval'
            if ($hv -notmatch '^\d+$') { & $replaceLine $hbIdx '  heartbeat_interval: 1'; $changed = $true }
        }
    }

    # Write only if changed (idempotent: no edit -> no write).
    if (-not $changed) { return }

    $sfDir = Split-Path $SettingsFile -Parent
    $tmp   = Join-Path $sfDir ("settings.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        Set-Content -LiteralPath $tmp -Value $lines.ToArray() -Encoding utf8NoBOM -ErrorAction Stop
        Move-Item -LiteralPath $tmp -Destination $SettingsFile -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw
    }
}

# script:Invoke-AidSynthesizeSettingsEraB <SettingsFile> <RepoName> <ManifestPath>
# Era-b: write fresh template-derived settings.yml (crash-safe temp+mv).
function script:Invoke-AidSynthesizeSettingsEraB {
    param([string]$SettingsFile, [string]$RepoName, [string]$ManifestPath)

    $toolIds = @(Read-ManifestTools -ManifestPath $ManifestPath)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("project:`n")
    [void]$sb.Append("  name: ${RepoName}`n")
    [void]$sb.Append("  description: <project-description>`n")
    [void]$sb.Append("  type: brownfield`n")
    [void]$sb.Append("`n")
    [void]$sb.Append("tools:`n")
    if ($toolIds.Count -eq 0) {
        [void]$sb.Append("  installed: []`n")
    } else {
        [void]$sb.Append("  installed:`n")
        foreach ($t in $toolIds) { [void]$sb.Append("    - ${t}`n") }
    }
    [void]$sb.Append("`n")
    [void]$sb.Append("review:`n")
    [void]$sb.Append("  minimum_grade: A`n")
    [void]$sb.Append("`n")
    [void]$sb.Append("execution:`n")
    [void]$sb.Append("  max_parallel_tasks: 5`n")
    [void]$sb.Append("`n")
    [void]$sb.Append("traceability:`n")
    [void]$sb.Append("  heartbeat_interval: 1`n")

    $sfDir   = Split-Path $SettingsFile -Parent
    if (-not (Test-Path $sfDir -PathType Container)) {
        New-Item -ItemType Directory -Path $sfDir -Force | Out-Null
    }
    $tmp = Join-Path $sfDir ("settings.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        # Write as UTF-8 NoBOM; use raw string to control LF line endings.
        $raw = $sb.ToString()
        [System.IO.File]::WriteAllText($tmp, $raw, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $SettingsFile -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw
    }
}


# ---------------------------------------------------------------------------
# Invoke-AidScanForRepos [<ScanRoot>]  (SCAN_FOR_AID_REPOS / SEC-2 / task-078)
# Enumerate candidate AID repo base folders under ScanRoot (default: $HOME).
# Bounded depth (5 levels), skips node_modules/.git, no symlink escape (SEC-2).
# Returns [string[]] of CAN-1-canonical repo base paths.
# ---------------------------------------------------------------------------
function script:Invoke-AidScanForRepos {
    param([string]$ScanRoot = '')

    if ([string]::IsNullOrEmpty($ScanRoot)) {
        $ScanRoot = $env:USERPROFILE
        if ([string]::IsNullOrEmpty($ScanRoot)) {
            $ScanRoot = $env:HOME
        }
        if ([string]::IsNullOrEmpty($ScanRoot)) { return @() }
    }

    # Canonicalize the scan root.
    try {
        $canonRoot = (Resolve-Path -LiteralPath $ScanRoot -ErrorAction Stop).Path
    } catch {
        [Console]::Error.WriteLine("WARN: aid scan: cannot access scan root '$ScanRoot' -- skipping")
        return @()
    }

    $results = [System.Collections.Generic.List[string]]::new()
    $skipDirs = @('node_modules', '.git')

    # BFS with depth cap (5 levels).
    # Use a queue of (path, depth) pairs.
    $queue = [System.Collections.Generic.Queue[object]]::new()
    $queue.Enqueue([pscustomobject]@{ Path = $canonRoot; Depth = 0 })

    while ($queue.Count -gt 0) {
        $item = $queue.Dequeue()
        $dir  = $item.Path
        $dep  = $item.Depth

        # Check for .aid subdirectory (DD-6 presence test).
        $aidDir = Join-Path $dir '.aid'
        if (Test-Path $aidDir -PathType Container) {
            $settingsPath = Join-Path $aidDir 'settings.yml'
            $kbDir        = Join-Path $aidDir 'knowledge'
            $ds1          = Join-Path $kbDir 'DISCOVERY_STATE.md'
            $ds2          = Join-Path $kbDir 'DISCOVERY-STATE.md'
            $ds3          = Join-Path $kbDir 'STATE.md'
            if ((Test-Path $settingsPath -PathType Leaf) -or
                (Test-Path $ds1 -PathType Leaf) -or
                (Test-Path $ds2 -PathType Leaf) -or
                (Test-Path $ds3 -PathType Leaf)) {
                # CAN-1 canonical: resolve without symlink expansion.
                try {
                    $canon = (Resolve-Path -LiteralPath $dir -ErrorAction Stop).Path
                } catch {
                    $canon = $dir
                }
                # Symlink-escape guard: must still be under the scan root.
                # Require exact-equality (root itself) OR starts-with(root + sep) so that a
                # sibling whose name shares a prefix (e.g. root C:\scan, sibling C:\scan-evil)
                # is correctly rejected -- mirrors Bash: case "${_canon_base}/" in "${_canon_root}/"*)
                $sep = [IO.Path]::DirectorySeparatorChar
                if (($canon -eq $canonRoot) -or
                    $canon.StartsWith($canonRoot + $sep, [System.StringComparison]::OrdinalIgnoreCase)) {
                    if (-not $results.Contains($canon)) {
                        $results.Add($canon)
                    }
                }
            }
        }

        # Recurse into subdirectories up to depth 5 (skip node_modules/.git).
        if ($dep -lt 5) {
            try {
                $children = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue
                foreach ($child in $children) {
                    if ($skipDirs -contains $child.Name) { continue }
                    # Skip symlinks that resolve outside the root (SEC-2).
                    # Same trailing-sep guard as the repo containment check above.
                    if ($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                        try {
                            $resolvedChild = (Resolve-Path -LiteralPath $child.FullName -ErrorAction Stop).Path
                            $sep = [IO.Path]::DirectorySeparatorChar
                            if (-not (($resolvedChild -eq $canonRoot) -or
                                $resolvedChild.StartsWith($canonRoot + $sep, [System.StringComparison]::OrdinalIgnoreCase))) {
                                continue  # symlink escapes root -- skip
                            }
                        } catch { continue }
                    }
                    $queue.Enqueue([pscustomobject]@{ Path = $child.FullName; Depth = $dep + 1 })
                }
            } catch { }
        }
    }

    return $results.ToArray()
}

# ---------------------------------------------------------------------------
# Invoke-AidCheckRepoCompliant <Repo>  (task-078 / FF-2 fast-path)
# Returns $true if the repo is fully compliant (no migration needed).
# Read-only (SEC-1).
# ---------------------------------------------------------------------------
function script:Invoke-AidCheckRepoCompliant {
    param([string]$Repo)
    $aidDir = Join-Path $Repo '.aid'
    if (-not (Test-Path $aidDir -PathType Container)) { return $false }

    $settingsPath = Join-Path $aidDir 'settings.yml'
    $kbDir        = Join-Path $aidDir 'knowledge'
    $ds1          = Join-Path $kbDir 'DISCOVERY_STATE.md'
    $ds2          = Join-Path $kbDir 'DISCOVERY-STATE.md'
    $ds3          = Join-Path $kbDir 'STATE.md'

    $isCandidate = (Test-Path $settingsPath -PathType Leaf) -or
                   (Test-Path $ds1 -PathType Leaf) -or
                   (Test-Path $ds2 -PathType Leaf) -or
                   (Test-Path $ds3 -PathType Leaf)
    if (-not $isCandidate) { return $false }

    # Step 2: home.html must be present.
    $homeHtml = Join-Path $aidDir 'dashboard' | Join-Path -ChildPath 'home.html'
    if (-not (Test-Path $homeHtml -PathType Leaf)) { return $false }

    # Step 4: must be registered.
    try {
        $canonRepo = (Resolve-Path -LiteralPath $Repo -ErrorAction Stop).Path
    } catch { return $false }
    $reg = Join-Path $script:_AidHome 'registry.yml'
    $existing = script:Get-RegistryRepos -RegPath $reg
    if ($existing -notcontains $canonRepo) { return $false }

    return $true
}

# ---------------------------------------------------------------------------
# Write-AidMigratedMarker  (DM-3 / task-078 / FF-2 completion)
# Write $AID_HOME/.migrated = trimmed $AID_HOME/VERSION (crash-safe).
# ---------------------------------------------------------------------------
function script:Write-AidMigratedMarker {
    $verFile = Join-Path $script:_AidHome 'VERSION'
    $marker  = Join-Path $script:_AidHome '.migrated'
    if (-not (Test-Path $verFile -PathType Leaf)) { return }
    $ver = (Get-Content -LiteralPath $verFile -Raw -ErrorAction SilentlyContinue).Trim()
    if ([string]::IsNullOrEmpty($ver)) { return }
    $tmp = $marker + '.aid-tmp.' + [System.IO.Path]::GetRandomFileName()
    try {
        [System.IO.File]::WriteAllText($tmp, ($ver + "`n"), [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $marker -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Invoke-AidScanAndMigrate  (FF-2 / CLI-1 / task-078)
# Machine-scan + All/Yes/No/Cancel consent walk. Called after Invoke-AidUpdateSelf.
# ApplyAllFlag: $true = --yes/AID_MIGRATE_YES=1 (preset All).
# ScanRoot: optional --root override.
# Always returns (exit code 0 per CLI-1/NFR12); DM-3 marker advanced only on
# completed (no Cancel) scan.
# ---------------------------------------------------------------------------
function script:Invoke-AidScanAndMigrate {
    param([bool]$ApplyAllFlag = $false, [string]$ScanRoot = '')

    $applyAll = $ApplyAllFlag
    if ($env:AID_MIGRATE_YES -eq '1') { $applyAll = $true }

    # RC-3 / SEC-1: non-interactive guard.
    $isTty = [Console]::IsInputRedirected -eq $false
    if ((-not $isTty) -and (-not $applyAll)) {
        Write-Host "AID machine scan: no TTY detected. Run 'aid update self' interactively to migrate repos."
        Write-Host "(Set AID_MIGRATE_YES=1 or use --yes to enable non-interactive migration.)"
        return
    }

    # Enumerate candidates (read-only).
    # Force array: @() prevents PowerShell from unwrapping a single-element result.
    $candidates = @(script:Invoke-AidScanForRepos -ScanRoot $ScanRoot)

    if ($candidates.Count -eq 0) {
        Write-Host "aid update self: no AID repos found to migrate."
        script:Write-AidMigratedMarker
        return
    }

    # Non-interactive + opt-in: annotate and migrate all.
    if ((-not $isTty) -and $applyAll) {
        Write-Host "AID machine scan (non-interactive, opt-in): $($candidates.Count) candidate(s) found."
        foreach ($repo in $candidates) {
            if (script:Invoke-AidCheckRepoCompliant -Repo $repo) { continue }
            Write-Host "  Migrating $repo..."
            try {
                $null = script:Invoke-AidMigrateRepo -Repo $repo
            } catch {
                [Console]::Error.WriteLine("WARN: aid: migration of $repo failed; continuing")
            }
        }
        script:Write-AidMigratedMarker
        return
    }

    # Interactive consent walk (FF-2 state machine / CLI-1 exact ASCII wording).
    $cancelled = $false
    foreach ($repo in $candidates) {
        if (script:Invoke-AidCheckRepoCompliant -Repo $repo) { continue }

        if ($applyAll) {
            try {
                $null = script:Invoke-AidMigrateRepo -Repo $repo
            } catch {
                [Console]::Error.WriteLine("WARN: aid: migration of $repo failed; continuing")
            }
        } else {
            $answered = $false
            while (-not $answered) {
                [Console]::Write("Migrate ${repo}? [A]ll / [Y]es / [N]o / [C]ancel: ")
                $ans = [Console]::ReadLine()
                if ($null -eq $ans) { $ans = 'C' }
                $ans = $ans.Trim()
                switch -CaseSensitive ($ans.ToUpper()) {
                    'A' {
                        $applyAll = $true
                        try {
                            $null = script:Invoke-AidMigrateRepo -Repo $repo
                        } catch {
                            [Console]::Error.WriteLine("WARN: aid: migration of $repo failed; continuing")
                        }
                        $answered = $true
                    }
                    'Y' {
                        try {
                            $null = script:Invoke-AidMigrateRepo -Repo $repo
                        } catch {
                            [Console]::Error.WriteLine("WARN: aid: migration of $repo failed; continuing")
                        }
                        $answered = $true
                    }
                    'N' {
                        Write-Host "Skipped ${repo}. Run 'aid update' inside that folder to migrate it later."
                        $answered = $true
                    }
                    'C' {
                        $cancelled = $true
                        $answered  = $true
                    }
                    default {
                        Write-Host "Please type A, Y, N, or C."
                    }
                }
            }
            if ($cancelled) { break }
        }
    }

    if (-not $cancelled) {
        script:Write-AidMigratedMarker
    }
}

# ---------------------------------------------------------------------------
# update (with 'self' subarg -> update self)
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'update') {
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'self') {
        # Consume any flags after 'self'.
        $usMigrateYes = $false
        $usRoot       = ''
        $remIdx = 1
        while ($remIdx -lt $script:_RemArgs.Count) {
            $a = $script:_RemArgs[$remIdx]
            switch ($a) {
                { $_ -in @('-Force', '--force', '-y') }      { }  # no-op for update self
                { $_ -in @('-Yes', '--yes') }                { $usMigrateYes = $true }  # RC-3 opt-in
                { $_ -in @('-h', '--help', '-Help') }        { script:Show-AidUsage 'update'; script:Exit-Aid 0 }
                '--root' {
                    $remIdx++
                    if ($remIdx -ge $script:_RemArgs.Count) {
                        script:Fail-Aid '--root requires a value' 2
                    }
                    $usRoot = $script:_RemArgs[$remIdx]
                }
                default { script:Fail-Aid "unknown flag for 'update self': $a" 2 }
            }
            $remIdx++
        }
        $usRc = script:Invoke-AidUpdateSelf
        if ($usRc -ne 0) { script:Exit-Aid $usRc }
        # ---- post-update machine scan (FF-2 / task-078) ----
        script:Invoke-AidScanAndMigrate -ApplyAllFlag $usMigrateYes -ScanRoot $usRoot
        script:Exit-Aid 0
    }
    # Fall through to shared add/update handler below.
}

# ---------------------------------------------------------------------------
# remove (with 'self' subarg -> remove self)
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'remove') {
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'self') {
        # Parse flags after 'self'.
        $rsForce  = $false
        $rsNoPath = $false
        $remIdx   = 1
        while ($remIdx -lt $script:_RemArgs.Count) {
            $a = $script:_RemArgs[$remIdx]
            switch ($a) {
                { $_ -in @('-Force', '--force', '-y') }       { $rsForce  = $true }
                { $_ -in @('-NoPath', '--no-path', '/nopath') } { $rsNoPath = $true }
                { $_ -in @('-h', '--help', '-Help') }         { script:Show-AidUsage 'remove'; script:Exit-Aid 0 }
                default { script:Fail-Aid "unknown flag for 'remove self': $a" 2 }
            }
            $remIdx++
        }

        # Env-var fallback for force.
        if (-not $rsForce -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) {
            $rsForce = $true
        }

        $aidHome = $script:_AidHome

        if (-not $rsForce) {
            # Skip prompt when non-interactive.
            $isInteractive = [Environment]::UserInteractive -and [Console]::In -ne [System.IO.TextReader]::Null
            if (-not $isInteractive) {
                $rsForce = $true
            } else {
                Write-Host -NoNewline "Remove the aid CLI from ${aidHome}? [y/N] "
                $answer = Read-Host
                if ($answer -notin @('y', 'Y', 'yes', 'YES')) {
                    Write-Host "Aborted."
                    script:Exit-Aid 0
                }
            }
        }

        $partial = $false

        # Remove PATH wiring.
        if (-not $rsNoPath) {
            $binDir = Join-Path $aidHome 'bin'
            try { script:Remove-AidFromPath -BinDir $binDir } catch { $partial = $true }
        }

        # Remove $AID_HOME directory.
        if (Test-Path $aidHome -PathType Container) {
            try {
                Remove-Item -LiteralPath $aidHome -Recurse -Force -ErrorAction Stop
            } catch {
                [Console]::Error.WriteLine("ERROR: aid: failed to remove $aidHome : $_")
                $partial = $true
            }
        }

        if ($partial) {
            Write-Host "aid CLI partially removed. Check the messages above for what remained."
            script:Exit-Aid 1
        }

        Write-Host "aid CLI removed. Per-project AID installs are unaffected; run 'aid remove' in a project before removing the CLI if you also want to remove those."
        script:Exit-Aid 0
    }
    # Fall through to shared remove handler below (may be 'remove' with no arg or with tool).
}


# ---------------------------------------------------------------------------
# dashboard
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'dashboard') {
    script:Invoke-AidDashboardCtl -DcArgs $script:_RemArgs
    script:Exit-Aid $LASTEXITCODE
}

# ---------------------------------------------------------------------------
# __migrate-repo (hidden, callable-core only -- task-077/081)
# ---------------------------------------------------------------------------
if ($SUBCMD -eq '__migrate-repo') {
    if ($script:_RemArgs.Count -lt 1) {
        [Console]::Error.WriteLine("ERROR: aid __migrate-repo requires a <repo> path argument")
        script:Exit-Aid 2
    }
    $_MigTarget = $script:_RemArgs[0]
    if (-not (Test-Path $_MigTarget -PathType Container)) {
        [Console]::Error.WriteLine("ERROR: aid __migrate-repo: not a directory: $_MigTarget")
        script:Exit-Aid 2
    }
    $_MigTarget = (Resolve-Path -LiteralPath $_MigTarget).Path
    script:Invoke-AidMigrateRepo -Repo $_MigTarget
    script:Exit-Aid 0
}

# ---------------------------------------------------------------------------
# add / remove / update - validate subcommand
# ---------------------------------------------------------------------------
if ($SUBCMD -notin @('add', 'remove', 'update')) {
    [Console]::Error.WriteLine("ERROR: aid: unknown command: $SUBCMD (see 'aid -h')")
    script:Exit-Aid 2
}

# ---------------------------------------------------------------------------
# Parse shared flags for add/remove/update.
# ---------------------------------------------------------------------------
$_AidToolArg     = ''
$_AidVersionArg  = ''
$_AidFromBundle  = ''
$_AidForce       = $false
$_AidRemoveForce = $false
$_AidTarget      = ''
$_AidPosTools    = [System.Collections.Generic.List[string]]::new()

$remIdx = 0
while ($remIdx -lt $script:_RemArgs.Count) {
    $a = $script:_RemArgs[$remIdx]
    switch -Regex ($a) {
        '^(-FromBundle|--from-bundle)$' {
            $remIdx++
            if ($remIdx -ge $script:_RemArgs.Count) { script:Fail-Aid "-FromBundle requires a value" 2 }
            $_AidFromBundle = $script:_RemArgs[$remIdx]
            break
        }
        '^(-Version|--version)$' {
            $remIdx++
            if ($remIdx -ge $script:_RemArgs.Count) { script:Fail-Aid "-Version requires a value" 2 }
            $_AidVersionArg = $script:_RemArgs[$remIdx]
            break
        }
        '^(-Force|--force|-y)$'  { $_AidForce = $true; $_AidRemoveForce = $true; break }
        '^(-Verbose|--verbose)$' { $script:_AidVerbose = $true; $env:AID_VERBOSE = '1'; break }
        '^(-Target|--target)$'  {
            $remIdx++
            if ($remIdx -ge $script:_RemArgs.Count) { script:Fail-Aid "-Target requires a value" 2 }
            $_AidTarget = $script:_RemArgs[$remIdx]
            break
        }
        '^(-NoPath|--no-path)$' { break <# bootstrap-only; silently ignore here #> }
        '^(-h|--help|-Help)$'   { script:Show-AidUsage $SUBCMD; script:Exit-Aid 0 }
        '^-' {
            script:Fail-Aid "unknown flag: $a" 2
        }
        default {
            # Positional: tool name(s) - comma-separated or space-separated.
            $_AidPosTools.Add($a)
            break
        }
    }
    $remIdx++
}

# Apply env-var fallbacks.
if (-not $_AidToolArg -and $_AidPosTools.Count -gt 0) { $_AidToolArg = $_AidPosTools -join ',' }
if (-not $_AidToolArg -and $env:AID_TOOL)             { $_AidToolArg = $env:AID_TOOL }
if (-not $_AidVersionArg -and $env:AID_VERSION)       { $_AidVersionArg = $env:AID_VERSION }
if (-not $_AidTarget -and $env:AID_TARGET)            { $_AidTarget = $env:AID_TARGET }
if (-not $_AidForce -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) {
    $_AidForce = $true
    $_AidRemoveForce = $true
}
if ($script:_AidVerbose) { $env:AID_VERBOSE = '1' }

if (-not $_AidTarget) { $_AidTarget = '.' }

# Validate target directory.
if (-not (Test-Path $_AidTarget -PathType Container)) {
    script:Fail-Aid "target directory does not exist: $_AidTarget" 2
}
$_AidTarget = (Resolve-Path -LiteralPath $_AidTarget).Path

# ---- Self-update-if-needed preamble (FF-3 / CLI-2 / task-079) --------------
# For 'update [<tool>]' only (not 'add', not 'update self').  Ensures the CLI
# is current before the per-repo migration runs (FR38 / OQ-6).  WARN-not-fail.
if ($SUBCMD -eq 'update') {
    script:Invoke-AidUpdateSelfIfStale
}

# Strip leading 'v' from version.
if ($_AidVersionArg) { $_AidVersionArg = $_AidVersionArg -replace '^v', '' }

# --from-bundle and --version are mutually exclusive.
if ($_AidFromBundle -and $_AidVersionArg) {
    script:Fail-Aid "-FromBundle and -Version are mutually exclusive" 2
}

# ---------------------------------------------------------------------------
# Manifest path.
# ---------------------------------------------------------------------------
$_AidManifest = Join-Path $_AidTarget (Join-Path '.aid' '.aid-manifest.json')

# ---------------------------------------------------------------------------
# For 'remove' with no tool arg: confirm then remove all.
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'remove' -and -not $_AidToolArg) {
    if (-not $_AidRemoveForce) {
        # Skip prompt when non-interactive.
        $isInteractive = [Environment]::UserInteractive -and [Console]::In -ne [System.IO.TextReader]::Null
        if (-not $isInteractive) {
            $_AidRemoveForce = $true
        } else {
            Write-Host -NoNewline "Remove ALL AID from ${_AidTarget}? [y/N] "
            $answer = Read-Host
            if ($answer -notin @('y', 'Y', 'yes', 'YES')) {
                Write-Host "Aborted."
                script:Exit-Aid 0
            }
        }
    }
    # Proceed: fall through to resolve all tools from manifest.
}

# ---------------------------------------------------------------------------
# Resolve tool list.
# ---------------------------------------------------------------------------
function script:Resolve-AidToolList {
    # Returns a [ref] result: sets $ResultRef.Value to $true (success) or $false (error).
    # On success, populates $OutList with tool ids (may be empty for update/remove
    # when no manifest exists).
    # On error (auto-detect failed, normalize failed), sets $ResultRef.Value to $false.
    param([string]$Raw, [string]$Subcmd, [string]$ManifestPath, [string]$TargetDir,
          [ref]$ResultRef, [System.Collections.Generic.List[string]]$OutList)

    if (-not $Raw) {
        if ($Subcmd -in @('update', 'remove')) {
            # No tool specified -> all tools in manifest.
            if (-not (Test-Path $ManifestPath -PathType Leaf)) {
                $ResultRef.Value = $true  # success, empty list = no manifest
                return
            }
            $tools = Get-ManifestToolList -ManifestPath $ManifestPath
            foreach ($t in $tools) { $OutList.Add($t.Id) }
            $ResultRef.Value = $true
            return
        }
        # Auto-detect for 'add'.
        $detected = Detect-Tool -TargetPath $TargetDir
        if ($null -eq $detected) { $ResultRef.Value = $false; return }
        $OutList.Add($detected)
        $ResultRef.Value = $true
        return
    }

    # Split on comma.
    $rawList = $Raw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($t in $rawList) {
        $canonical = Normalize-Tool -Raw $t
        if ($null -eq $canonical) { $ResultRef.Value = $false; return }
        $OutList.Add($canonical)
    }
    $ResultRef.Value = $true
}

$_AidToolsList = [System.Collections.Generic.List[string]]::new()
$_AidToolsOk   = [ref]$false
script:Resolve-AidToolList -Raw $_AidToolArg -Subcmd $SUBCMD `
    -ManifestPath $_AidManifest -TargetDir $_AidTarget `
    -ResultRef $_AidToolsOk -OutList $_AidToolsList

if (-not $_AidToolsOk.Value) {
    script:Exit-Aid 2
}

$_AidTools = $_AidToolsList

if ($_AidTools.Count -eq 0) {
    switch ($SUBCMD) {
        'remove' {
            [Console]::Error.WriteLine("ERROR: aid: no manifest at $_AidTarget\.aid\.aid-manifest.json (exit 6)")
            script:Exit-Aid 6
        }
        'update' {
            [Console]::Error.WriteLine("ERROR: aid: no manifest at $_AidTarget\.aid\.aid-manifest.json; nothing to update (exit 6)")
            script:Exit-Aid 6
        }
        'add' {
            [Console]::Error.WriteLine("ERROR: aid: cannot auto-detect host tool; pass tool name as argument (e.g. aid add codex)")
            script:Exit-Aid 2
        }
    }
}

# ---------------------------------------------------------------------------
# Staging area management.
# ---------------------------------------------------------------------------
$_AidStagingBase = Join-Path ([System.IO.Path]::GetTempPath()) ("aid-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $_AidStagingBase -Force | Out-Null

$script:_DispResolvedVersion = ''
$script:_DispStagingDir      = ''

function script:Prepare-AidToolStaging {
    param([string]$Tool, [string]$Version, [string]$Bundle)

    $toolStaging = Join-Path $_AidStagingBase ("staging-$Tool-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $toolStaging -Force | Out-Null

    if ($Bundle) {
        $tarball = $Bundle
        if (Test-Path $Bundle -PathType Container) {
            $pattern = Join-Path $Bundle "aid-$Tool-v*.tar.gz"
            $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $found) {
                [Console]::Error.WriteLine("ERROR: aid: no tarball found for tool '$Tool' in bundle directory: $Bundle")
                script:Exit-Aid 1
            }
            $tarball = $found.FullName
        }
        if (-not (Test-Path $tarball -PathType Leaf)) {
            [Console]::Error.WriteLine("ERROR: aid: bundle file not found: $tarball")
            script:Exit-Aid 1
        }
        if (-not (Verify-BundleChecksum -Tarball $tarball)) { script:Exit-Aid 4 }
        $tbase = [System.IO.Path]::GetFileName($tarball)
        $script:_DispResolvedVersion = $tbase -replace "^aid-$Tool-v", '' -replace '\.tar\.gz$', ''
        if (-not $script:_DispResolvedVersion) {
            $script:_DispResolvedVersion = if ($Version) { $Version } else { 'unknown' }
        }
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { script:Exit-Aid 1 }
    } else {
        if (-not $Version) {
            $script:_DispResolvedVersion = Resolve-AidVersion
            if (-not $script:_DispResolvedVersion) { script:Exit-Aid 3 }
        } else {
            $script:_DispResolvedVersion = $Version
        }
        $dlDir = Join-Path $_AidStagingBase ("download-$Tool-" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $dlDir -Force | Out-Null
        if (-not (Fetch-Tarball -Tool $Tool -Version $script:_DispResolvedVersion -DestDir $dlDir)) {
            script:Exit-Aid 3
        }
        $tarball = Join-Path $dlDir "aid-$Tool-v$($script:_DispResolvedVersion).tar.gz"
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { script:Exit-Aid 1 }
    }

    $script:_DispStagingDir = $toolStaging
}

# ---------------------------------------------------------------------------
# Dispatch to engine.
# ---------------------------------------------------------------------------
try {
    $overallBlocked = $false

    switch ($SUBCMD) {
        { $_ -in @('add', 'update') } {
            foreach ($t in $_AidTools) {
                Write-Host ""
                script:Prepare-AidToolStaging -Tool $t -Version $_AidVersionArg -Bundle $_AidFromBundle
                Write-Host "Installing $t v$($script:_DispResolvedVersion) -> $_AidTarget"
                $rc = Install-AidTool -StagingDir $script:_DispStagingDir -Tool $t -Target $_AidTarget `
                         -Version $script:_DispResolvedVersion -Force ([bool]$_AidForce) `
                         -AidVerbose $script:_AidVerbose
                if ($rc -eq 5) {
                    $overallBlocked = $true
                } elseif ($rc -ne 0) {
                    script:Exit-Aid $rc
                }
            }

            Write-Host ""
            if ($overallBlocked) {
                Write-Host "Install complete with warnings: one or more root agent files were not overwritten."
                Write-Host "Review the *.aid-new file(s) and merge, or re-run with -Force to overwrite."
                script:Exit-Aid 5
            }
            Write-Host "Done. AID $($script:_DispResolvedVersion) installed into: $_AidTarget"
            # DR-1 registry side-effect: register repo on first tool add/update (idempotent).
            script:Registry-Register -Repo $_AidTarget
            # FF-3 / CLI-2 / task-079: per-repo migration on the 'update' reach only.
            # Runs on the already-canonicalized $_AidTarget (Resolve-Path above).
            # The Registry-Register above already ran, so migration step 4 is an
            # idempotent no-op; steps 1-3 run per FF-1.  WARN-not-fail (NFR12):
            # migration never changes the tool-update exit code.
            if ($SUBCMD -eq 'update') {
                script:Invoke-AidMigrateRepo -Repo $_AidTarget
            }
            script:Exit-Aid 0
        }

        'remove' {
            if (-not (Test-ManifestExists -ManifestPath $_AidManifest)) {
                [Console]::Error.WriteLine("ERROR: aid: no manifest at $_AidTarget\.aid\.aid-manifest.json; nothing to uninstall")
                script:Exit-Aid 6
            }

            foreach ($t in $_AidTools) {
                Write-Host ""
                Write-Host "Uninstalling $t from $_AidTarget"
                $rc = Uninstall-AidTool -ManifestPath $_AidManifest -Tool $t -Target $_AidTarget `
                         -AidVerbose $script:_AidVerbose
                if ($rc -eq 6) { script:Exit-Aid 6 }
                if ($rc -ne 0) { script:Exit-Aid $rc }
            }

            Write-Host ""
            Write-Host "Uninstall complete."
            # DR-1 registry side-effect: unregister repo only when manifest is now gone (last tool removed).
            if (-not (Test-Path $_AidManifest -PathType Leaf)) {
                script:Registry-Unregister -Repo $_AidTarget
            }
            script:Exit-Aid 0
        }
    }
} finally {
    if (Test-Path $_AidStagingBase -PathType Container) {
        Remove-Item -LiteralPath $_AidStagingBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}

} catch {
    $msg = "$_"
    if ($msg.StartsWith($script:_SentinelTag)) {
        # Clean unwind in piped mode - $global:LASTEXITCODE already set.
        return
    }
    if ($script:_PipedMode) {
        $global:LASTEXITCODE = 1
        [Console]::Error.WriteLine("ERROR: aid: unhandled exception: $_")
        return
    }
    throw
}
