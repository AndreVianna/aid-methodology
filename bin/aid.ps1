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

# Invoke-AidUpdateSelf
# Re-runs the bootstrap in place.  Relays bootstrap exit code.
# AID_INSTALL_CHANNEL guard: npm/pypi channels print a package-manager hint
# and exit 0 instead of re-bootstrapping.
function script:Invoke-AidUpdateSelf {
    switch ($env:AID_INSTALL_CHANNEL) {
        'npm' {
            Write-Host 'Updating the aid CLI: run  npm i -g aid-installer@latest'
            script:Exit-Aid 0
            return
        }
        'pypi' {
            Write-Host 'Updating the aid CLI: run  pipx upgrade aid-installer  (or: pip install --user -U aid-installer)'
            script:Exit-Aid 0
            return
        }
    }
    Write-Host 'Updating the aid CLI...'
    $url = $script:_AidInstallUrl
    try {
        $scriptContent = (Invoke-RestMethod -Uri $url -ErrorAction Stop)
        & ([scriptblock]::Create($scriptContent))
        script:Exit-Aid $LASTEXITCODE
    } catch {
        [Console]::Error.WriteLine("ERROR: aid: update self failed: $_")
        script:Exit-Aid 3
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
    $dcTarget = (Resolve-Path $dcTarget).Path

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
    $spawnArgs = @($entryPoint, '--root', $Target, '--host', '127.0.0.1', '--port', "$Port")
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
        script:Exit-Aid 0
    }

    # Step 11: print success (local-only).
    Write-Host "Dashboard ($Runtime) running at http://127.0.0.1:${Port} -- stop with: aid dashboard stop"
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
    script:Exit-Aid $rc
}

# ---------------------------------------------------------------------------
# update (with 'self' subarg -> update self)
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'update') {
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'self') {
        # Consume any flags after 'self'.
        $remIdx = 1
        while ($remIdx -lt $script:_RemArgs.Count) {
            $a = $script:_RemArgs[$remIdx]
            switch ($a) {
                { $_ -in @('-Force', '--force', '-y') } { }  # no-op for update self
                { $_ -in @('-h', '--help', '-Help') }   { script:Show-AidUsage 'update'; script:Exit-Aid 0 }
                default { script:Fail-Aid "unknown flag for 'update self': $a" 2 }
            }
            $remIdx++
        }
        script:Invoke-AidUpdateSelf
        # Invoke-AidUpdateSelf always calls Exit-Aid.
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
$_AidTarget = (Resolve-Path $_AidTarget).Path

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
