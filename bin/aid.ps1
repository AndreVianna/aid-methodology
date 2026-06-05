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
    'https://raw.githubusercontent.com/AndreVianna/aid-methodology/worktree-work-002-auto-installer/install.ps1'
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
            'npm'  { 'npm i -g @aid/installer@latest' }
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
            Write-Host 'Updating the aid CLI: run  npm i -g @aid/installer@latest'
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
