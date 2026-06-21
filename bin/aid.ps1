#Requires -Version 5.1
# aid.ps1 - AID CLI dispatcher (PowerShell side).
#
# Purpose:
#   Persistent global command installed at $AID_CODE_HOME\bin\aid.ps1.  Parses
#   subcommands and dispatches to the shared install-core engine located at
#   $AID_CODE_HOME\lib\AidInstallCore.psm1.  Operates on the current working
#   directory (-Target / AID_TARGET overrides).
#
# Usage:
#   aid                              Show the dashboard
#   aid -h | --help                  Show help
#   aid version                      Print the CLI version
#   aid status                       Show AID state of the current project
#   aid add <tool>[,...]             Add tool(s) to the current project
#   aid update [self]                Update to latest; inside repo = CLI + all tools; 'self' = CLI only
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
# AID_CODE_HOME: self-locate the read-only code payload (parent of bin/).
# NEVER overridden by an env var. Error-out if unresolvable (Q1 fail-safe).
# ---------------------------------------------------------------------------
$script:_AidSelfPath = $MyInvocation.MyCommand.Path
if (-not [string]::IsNullOrEmpty($script:_AidSelfPath) -and (Test-Path $script:_AidSelfPath -PathType Leaf)) {
    # bin/aid.ps1 -> parent of bin/ = AID_CODE_HOME
    $script:_AidCodeHome = Split-Path -Parent (Split-Path -Parent $script:_AidSelfPath)
} else {
    [Console]::Error.WriteLine("ERROR: aid: cannot locate the AID code payload (AID_CODE_HOME unresolved). Re-run the AID bootstrap to repair.")
    script:Exit-Aid 1
}

# ---------------------------------------------------------------------------
# Scope derivation: global iff AID_CODE_HOME is not writable by the current
# user. Mirrors bash: [[ ! -w "$AID_CODE_HOME" && "$(id -u)" -ne 0 ]].
# No install-time marker -- writability of the code payload is the sole test.
# AID_STATE_HOME: mutable state home, env-overridable via AID_HOME.
# ---------------------------------------------------------------------------
$script:_AidCodeHomeWritable = $false
try {
    $_aidWriteTestFile = Join-Path $script:_AidCodeHome ('.aid-write-test.' + [System.IO.Path]::GetRandomFileName())
    [System.IO.File]::WriteAllText($_aidWriteTestFile, '')
    Remove-Item -LiteralPath $_aidWriteTestFile -Force -ErrorAction SilentlyContinue
    $script:_AidCodeHomeWritable = $true
} catch {
    $script:_AidCodeHomeWritable = $false
}

if ($script:_AidCodeHomeWritable) {
    $script:_AidScope     = 'user'
    $script:_AidStateHome = if ($env:AID_HOME) { $env:AID_HOME } else { Join-Path $HOME '.aid' }
} else {
    $script:_AidScope     = 'global'
    $script:_AidStateHome = if ($env:AID_HOME) { $env:AID_HOME } else {
        if ($env:AID_SHARED_STATE_HOME) {
            $env:AID_SHARED_STATE_HOME
        } elseif ($env:ProgramData) {
            Join-Path $env:ProgramData 'aid'
        } else {
            Join-Path $HOME '.aid'
        }
    }
}

# ---------------------------------------------------------------------------
# Test-AidIsProjectDir <Dir>
# Return $true iff <Dir> has a .aid/ subdirectory AND that subdirectory is NOT
# the CLI state home.  Excludes the state home from "is project" classification
# so running 'aid' from $HOME (or any dir whose .aid/ == _AidStateHome) does not
# falsely auto-register or trigger the format gate.
#
# Guard: resolves <Dir>\.aid to a canonical path and compares against both
# Resolve-Path($script:_AidStateHome) and Resolve-Path($HOME\.aid).
# Mirror of bash _aid_is_project_dir.
# ---------------------------------------------------------------------------
function script:Test-AidIsProjectDir {
    param([string]$Dir)
    $aidSub = Join-Path $Dir '.aid'
    if (-not (Test-Path $aidSub -PathType Container)) { return $false }
    # Resolve .aid/ to canonical real path (tolerates non-existent intermediate).
    $aidReal  = try { (Resolve-Path -LiteralPath $aidSub -ErrorAction Stop).Path } catch { $aidSub }
    # Resolve both state-home candidates.
    $shReal   = try { (Resolve-Path -LiteralPath $script:_AidStateHome -ErrorAction Stop).Path } catch { $script:_AidStateHome }
    $hdAid    = Join-Path $HOME '.aid'
    $hdReal   = try { (Resolve-Path -LiteralPath $hdAid -ErrorAction Stop).Path } catch { $hdAid }
    # Compare using OrdinalIgnoreCase to handle Windows path normalization.
    if ([string]::Equals($aidReal, $shReal, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($aidReal, $hdReal, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# C1': Per-repo format stamp constant.
# The current .aid/ layout version. Bumped ONLY on a breaking layout change,
# never on every CLI release. Defined exactly once; all comparisons read this.
# Integer must equal the bash AID_SUPPORTED_FORMAT in bin/aid.
# ---------------------------------------------------------------------------
Set-Variable -Name AidSupportedFormat -Value 1 -Option Constant -Scope Script

# ---------------------------------------------------------------------------
# Import the shared install core from AID_CODE_HOME\lib\.
# ---------------------------------------------------------------------------
$script:_CoreModule = Join-Path $script:_AidCodeHome 'lib' | Join-Path -ChildPath 'AidInstallCore.psm1'
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
            Write-Host 'aid remove [<tool>[,<tool>...]] [-Force] [-Verbose] [-Target <dir>]'
            Write-Host 'aid remove self [-Force] [-DryRun]'
            Write-Host '  Remove tool(s) from the current project (manifest-driven).'
            Write-Host '  No args: remove ALL AID from the project (asks for confirmation).'
            Write-Host '  self: COMPLETELY remove the aid CLI, channel-aware (asks for confirmation):'
            Write-Host '        npm -> npm uninstall -g | pypi -> pipx uninstall | curl -> rm $AID_CODE_HOME + unwire PATH.'
            Write-Host '        On Windows, elevation is the caller''s responsibility (no sudo).'
            Write-Host '  -DryRun: print the exact command(s) it would run, then exit (no changes).'
        }
        'update' {
            Write-Host 'aid update [-Version <v>] [-FromBundle <path>] [-Force] [-DryRun] [-Target <dir>]'
            Write-Host 'aid update self [-FromBundle <path>] [-DryRun]'
            Write-Host '  Update to latest.'
            Write-Host '  Outside an AID repo: updates the CLI only (no-op if already latest).'
            Write-Host '  Inside an AID repo: updates the CLI first, then ALL installed tools to one version.'
            Write-Host '  No per-tool selection -- any tool positional is an error (use "self" only).'
            Write-Host '  self: COMPLETELY update the aid CLI, channel-aware:'
            Write-Host '        npm -> npm i -g | pypi -> pipx upgrade | curl -> re-bootstrap install.ps1.'
            Write-Host '        On Windows, elevation is the caller''s responsibility (no sudo).'
            Write-Host '  -Version <v>:        pin ALL tools (and CLI) to version v.'
            Write-Host '  -FromBundle <path>:  install from a local artifact instead of @latest'
            Write-Host '        (npm .tgz | pypi .whl | curl release-staging dir with install.ps1).'
            Write-Host '  -DryRun: print the full plan (tools updated, files copied, paths pruned) and exit.'
        }
        'version' {
            Write-Host 'aid version'
            Write-Host '  Print the installed aid CLI version and exit 0.'
        }
        'dashboard' {
            Write-Host 'aid dashboard start <node|python> [--remote] [--port <n>]'
            Write-Host 'aid dashboard stop'
            Write-Host '  Start or stop the machine-level pipeline dashboard (serves all registered projects).'
            Write-Host '  <node|python>  select the server runtime to launch.'
            Write-Host '  --remote       also expose it to authorized users over a private channel (never public);'
            Write-Host '                 fails clearly if that mechanism is unavailable -- never binds publicly.'
            Write-Host '  --port <n>     listen port on 127.0.0.1 (default 8787).'
            Write-Host "  The dashboard binds to 127.0.0.1 only. 'stop' is idempotent and also tears down --remote."
            Write-Host '  Works from any directory (not tied to the current project).'
        }
        'projects' {
            Write-Host 'aid projects [list] [--local|--shared] [--verbose]'
            Write-Host 'aid projects add  [<path>] [--local|--shared]'
            Write-Host 'aid projects remove [<path>]'
            Write-Host '  List, register, or unregister AID projects in the registry.'
            Write-Host '  list (default): show all registered projects with state, tools, and tier.'
            Write-Host '    The current directory is marked with "*" in the leading marker column.'
            Write-Host '    Unregistered cwd with .aid/ present is shown as a footnote.'
            Write-Host '  add [path=cwd]: register a project (requires .aid/ to exist); tracking only,'
            Write-Host '    no tools are installed.  Idempotent.  Prints the tier written.'
            Write-Host '  remove [path=cwd]: unregister a project from the registry; no files removed.'
            Write-Host '    Works on stale/missing/no-aid entries.  Idempotent.'
            Write-Host '  --local   force user tier for add'
            Write-Host '  --shared  force shared tier for add'
            Write-Host '  --verbose print extra detail'
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
            Write-Host '  aid update [self]                Update to latest; inside repo = all tools'
            Write-Host '  aid remove [<tool>... | self]    Remove; no arg = ALL AID from project'
            Write-Host '  aid dashboard start|stop ...     Start/stop the local dashboard'
            Write-Host '  aid projects [list|add|remove]   List/register/unregister AID projects'
            Write-Host "  aid <command> -h | --help        Per-command help"
            Write-Host ''
            Write-Host 'Flags: -FromBundle, -Version, -Force, -DryRun, -Target, -Verbose'
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
# Throttle: re-fetches at most once per 24h; cache in $HOME\.aid\.update-check (FR10: always per-user).
# Opt-out: $env:AID_NO_UPDATE_CHECK = '1'
# Test hook: $env:AID_UPDATE_CHECK_URL overrides the fetch URL (and bypasses throttle).
function script:Invoke-AidUpdateCheck {
    # Opt-out.
    if ($env:AID_NO_UPDATE_CHECK -eq '1') { return }

    # Read installed version.
    $verFile = Join-Path $script:_AidCodeHome 'VERSION'
    if (-not (Test-Path $verFile -PathType Leaf)) { return }
    $installedVersion = (Get-Content -LiteralPath $verFile -Raw -ErrorAction SilentlyContinue).Trim()
    if (-not $installedVersion) { return }

    # FR10: .update-check is always per-user ($HOME/.aid), never AID_STATE_HOME.
    # This ensures a routine version check never writes into /var/lib/aid on a
    # root-owned global install and never triggers elevation.
    $cacheFile    = Join-Path $HOME (Join-Path '.aid' '.update-check')
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
        # `aid update self` is now channel-aware and self-contained (it runs the
        # right package manager + applies migrations), so point at it for every
        # channel instead of a per-channel manual command.
        Write-Host "A newer aid CLI is available: v$latestVersion (you have v$installedVersion). Run: aid update self"
    }
}

# Invoke-AidUpdateSelf
# Channel-aware, self-contained CLI self-update.  Returns the exit code (does NOT call Exit-Aid).
# Reads the channel from AID_INSTALL_CHANNEL (injected by the npm/pypi shims).
# Honors $script:_SelfFromBundle (a local CLI artifact: npm .tgz / pypi .whl / curl bundle dir)
# and $script:_SelfDryRun.  On Windows there is no sudo -- if a privileged location is not
# writable, the underlying tool (npm/pipx) will surface its own error; callers elevate their
# own shell.  Dry-run prints "+ <command>" lines and returns 0 without making changes.
# Callers are responsible for calling Exit-Aid after the update completes.
function script:Invoke-AidUpdateSelf {
    # AID_SKIP_SELF_INSTALL: the package manager already (re)installed the CLI
    # (postinstall) and only wants the post-update step to run. Skip the
    # re-install step.
    if ($env:AID_SKIP_SELF_INSTALL -eq '1') { return 0 }
    $channel = $env:AID_INSTALL_CHANNEL
    $bundle  = $script:_SelfFromBundle
    $dryRun  = $script:_SelfDryRun

    switch ($channel) {
        'npm' {
            $npmCmd = Get-Command 'npm' -ErrorAction SilentlyContinue
            if (-not $npmCmd) {
                [Console]::Error.WriteLine("ERROR: aid: npm not found; cannot update the npm-channel CLI")
                return 3
            }
            $pkg = if ($bundle) { $bundle } else { 'aid-installer@latest' }
            if ($dryRun) {
                Write-Host "+ npm install -g $pkg"
                return 0
            }
            Write-Host 'Updating the aid CLI (npm channel)...'
            & npm install -g $pkg
            return $LASTEXITCODE
        }
        'pypi' {
            $pipxCmd = Get-Command 'pipx' -ErrorAction SilentlyContinue
            if (-not $pipxCmd) {
                [Console]::Error.WriteLine("ERROR: aid: pipx not found; cannot update the pypi-channel CLI")
                return 3
            }
            if ($dryRun) {
                if ($bundle) {
                    Write-Host "+ pipx install --force $bundle"
                } else {
                    Write-Host '+ pipx upgrade aid-installer'
                }
                return 0
            }
            Write-Host 'Updating the aid CLI (pypi/pipx channel)...'
            if ($bundle) {
                & pipx install --force $bundle
            } else {
                & pipx upgrade aid-installer
            }
            return $LASTEXITCODE
        }
    }

    # curl / default channel -- re-bootstrap install.ps1.
    Write-Host 'Updating the aid CLI...'
    if ($bundle) {
        # --from-bundle <dir> on the curl channel: a release-staging dir that
        # carries install.ps1 + the CLI bundle + SHA256SUMS. Run it offline.
        $installScript = Join-Path ($bundle.TrimEnd('/\')) 'install.ps1'
        if (Test-Path $installScript -PathType Leaf) {
            if ($dryRun) {
                $bundleNorm = $bundle.TrimEnd('/\')
                Write-Host "+ `$env:AID_CLI_BUNDLE_BASE='file://$bundleNorm'; `$env:AID_LIB_BASE='file://$bundleNorm'; & '$installScript'"
                return 0
            }
            $bundleNorm = $bundle.TrimEnd('/\')
            $env:AID_CLI_BUNDLE_BASE = "file://$bundleNorm"
            $env:AID_LIB_BASE        = "file://$bundleNorm"
            & $installScript
            return $LASTEXITCODE
        }
        [Console]::Error.WriteLine("ERROR: aid: -FromBundle <dir> for the curl channel must contain install.ps1 (got: $bundle)")
        return 2
    }
    $url = $script:_AidInstallUrl
    if ($dryRun) {
        Write-Host "+ irm $url | iex"
        return 0
    }
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
# (OQ-6 resolved simplest-correct: compare installed $AID_CODE_HOME/VERSION against
# the cached .update-check latest; if stale -> call Invoke-AidUpdateSelf; if
# current or unknown -> silent no-op).
#
# Safety notes (no re-bootstrap/loop hazard):
#   - Called only on 'update [<tool>]', not 'update self' or 'add'.
#   - WARN-not-fail: self-update failure is logged; tool-install continues (NFR12).
function script:Invoke-AidUpdateSelfIfStale {
    param([string]$FromBundle = '')

    # Offline / explicit bundle install: when the caller supplied a local bundle, do NOT
    # phone the package channel to self-update. The bundle is the source of truth for this
    # install; reaching out to the registry would defeat an air-gapped or pre-release
    # install (and could replace the running CLI behind the user's back). Mirrors bin/aid.
    if ($FromBundle) { return }

    # Read installed version from the code payload (read-only).
    $verFile = Join-Path $script:_AidCodeHome 'VERSION'
    $installed = ''
    if (Test-Path $verFile -PathType Leaf) {
        $installed = (Get-Content $verFile -Raw).Trim()
    }
    if (-not $installed) { return }  # no installed version known -> skip

    # Read cached latest version from per-user .update-check (FR10: always $HOME/.aid).
    $cacheFile = Join-Path $HOME (Join-Path '.aid' '.update-check')
    $cachedLatest = ''
    if (Test-Path $cacheFile -PathType Leaf) {
        $lines = Get-Content $cacheFile -ErrorAction SilentlyContinue
        if ($lines -and $lines.Count -ge 2) {
            $cachedLatest = ($lines[1]).Trim()
        }
    }
    if (-not $cachedLatest) { return }  # no cached latest known -> skip (no network call here)

    # Skip if already current (string equality fast-path).
    if ($installed -eq $cachedLatest) { return }

    # Only self-update when the installed CLI is strictly OLDER than the cached latest.
    # A newer installed version (e.g. an unreleased dev build) must never be downgraded
    # to "latest". Parse both as [version]; if either is unparseable, skip conservatively.
    # Mirrors the `sort -V` guard in bin/aid (never downgrade).
    $installedVer = $null
    $latestVer = $null
    if (-not ([version]::TryParse($installed, [ref]$installedVer)) -or
        -not ([version]::TryParse($cachedLatest, [ref]$latestVer))) {
        return  # unparseable version -> conservatively skip (never risk a downgrade)
    }
    if ($installedVer -ge $latestVer) { return }  # installed >= latest -> nothing to do

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

    # Step 5: Print FR18 ACL-grant guidance to STDERR (informational only).
    $srcPlaceholder = '<you@example.com>'
    $dstPlaceholder = if ($nodeShort)    { $nodeShort }    else { '<this-host>' }

    [Console]::Error.WriteLine('')
    [Console]::Error.WriteLine('Remote exposure is UP (tailnet-private). Every device on your tailnet can now reach this host.')
    [Console]::Error.WriteLine('To restrict access to only you, add a deny-by-default ACL grant in the tailnet policy file:')
    [Console]::Error.WriteLine('  https://login.tailscale.com/admin/acls/file')
    [Console]::Error.WriteLine("  {`"grants`":[{`"src`":[`"$srcPlaceholder`"],`"dst`":[`"$dstPlaceholder`"],`"ip`":[`"tcp:443`"]}]}")
    [Console]::Error.WriteLine("Note: granted identities see all registered project paths/names. See 'aid dashboard --help'.")
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

    $verb = if ($DcArgs -and $DcArgs.Count -gt 0) { $DcArgs[0] } else { '' }
    $rest = [string[]]@(if ($DcArgs -and $DcArgs.Count -gt 1) { $DcArgs[1..($DcArgs.Count - 1)] } else { @() })

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

    if ($verb -eq 'start') {
        script:Invoke-DcStart -Runtime $dcRuntime -Port $dcPort -Remote $dcRemote -Verbose $dcVerbose
    } else {
        script:Invoke-DcStop -Verbose $dcVerbose
    }
}

function script:Invoke-DcStart {
    param([string]$Runtime, [int]$Port, [bool]$Remote, [bool]$Verbose)

    # Step 1: validate runtime.
    if ([string]::IsNullOrEmpty($Runtime)) {
        [Console]::Error.WriteLine('ERROR: aid: dashboard start requires a runtime: node or python (e.g. aid dashboard start python)')
        script:Exit-Aid 2
    }
    if ($Runtime -ne 'node' -and $Runtime -ne 'python') {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown runtime '$Runtime' (expected: node or python)")
        script:Exit-Aid 2
    }

    # pid/log live in the per-user state home (.temp), always writable.
    # FR10 precedent: always per-user $HOME/.aid, never AID_STATE_HOME on global installs.
    $pidFile = Join-Path $HOME (Join-Path '.aid' (Join-Path '.temp' 'dashboard.pid'))
    $logFile = Join-Path $HOME (Join-Path '.aid' (Join-Path '.temp' 'dashboard.log'))

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
    # <assets> = $AID_CODE_HOME/dashboard (the co-vendored server+reader unit in the install tree).
    $assetsDir = Join-Path $script:_AidCodeHome 'dashboard'
    if ($Runtime -eq 'python') {
        $entryPoint = Join-Path $assetsDir (Join-Path 'server' 'server.py')
    } else {
        $entryPoint = Join-Path $assetsDir (Join-Path 'server' 'server.mjs')
    }
    if (-not (Test-Path $entryPoint -PathType Leaf)) {
        [Console]::Error.WriteLine("ERROR: aid: dashboard: the dashboard server is missing from the install tree ($Runtime entry-point not found at $entryPoint); run 'aid update' or reinstall aid")
        script:Exit-Aid 7
    }

    # Ensure log dir exists (per-user state home, always writable).
    $tempDir = Join-Path $HOME (Join-Path '.aid' '.temp')
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
    # under AID_STATE_HOME; export AID_HOME=AID_STATE_HOME so the server resolves the
    # registry via its legacy AID_HOME env var (delivery-008 seam).
    $env:AID_HOME = $script:_AidStateHome
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
    param([bool]$Verbose)

    $pidFile = Join-Path $HOME (Join-Path '.aid' (Join-Path '.temp' 'dashboard.pid'))

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
# C4': Get-AidRepoFormat <Repo>
# Read the format_version stamp from <Repo>/.aid/settings.yml.
# Greps the FIRST ^format_version: line, replicates the era-a closure strip
# logic inline (prefix strip, trim, inline # comment strip, quote-unwrap),
# validates as ^\d+$; returns the integer.
# Collapses absent/empty/non-integer/malformed/negative to 0 (legacy default).
# Never returns a value > sup from a garbled stamp (fail-safe).
# Defined here (before dispatch) so it is available to status/bare-aid/update.
# ---------------------------------------------------------------------------
function script:Get-AidRepoFormat {
    param([string]$Repo)
    $settingsFile = Join-Path $Repo (Join-Path '.aid' 'settings.yml')
    if (-not (Test-Path $settingsFile -PathType Leaf)) { return 0 }
    # First-match read (parity with duplicate-line policy).
    $rawLine = $null
    foreach ($ln in (Get-Content -LiteralPath $settingsFile -Encoding utf8 -ErrorAction SilentlyContinue)) {
        if ($ln -match '^format_version:') { $rawLine = $ln; break }
    }
    if (-not $rawLine) { return 0 }
    # Replicate the era-a closure strip logic inline (column-0 key variant).
    # Step 1: strip the "format_version:" prefix.
    $val = $rawLine -replace '^format_version:', ''
    # Step 2: strip one optional leading space (the colon-space separator).
    if ($val.StartsWith(' ')) { $val = $val.Substring(1) }
    # Step 3: strip inline # comment (first " #" to end of line).
    $commentIdx = $val.IndexOf(' #')
    if ($commentIdx -ge 0) { $val = $val.Substring(0, $commentIdx) }
    # Step 4: quote-unwrap (double then single).
    $val = $val.Trim('"').Trim("'")
    # Step 5: full trim (remaining whitespace).
    $val = $val.Trim()
    # Step 6: validate non-negative integer; collapse anything else to 0.
    if ($val -match '^\d+$') { return [int]$val }
    return 0
}

# ---------------------------------------------------------------------------
# C5': Invoke-AidFormatGate <Repo>
# 3-way classify <Repo>'s format stamp vs $AidSupportedFormat:
#   repo > sup  -> refuse (stderr, return 1, no .aid/ write)
#   repo < sup  -> warn + offer aid update (stdout, return 0, non-blocking)
#   repo == sup -> silent (return 0)
# AID_NO_MIGRATE=1 suppresses the warn+offer notice only; never the refuse.
# Defined here (before dispatch) so it is available to status/bare-aid/update.
# ---------------------------------------------------------------------------
function script:Invoke-AidFormatGate {
    param([string]$Repo)
    $repoFmt = script:Get-AidRepoFormat -Repo $Repo
    $sup = $script:AidSupportedFormat
    if ($repoFmt -gt $sup) {
        [Console]::Error.WriteLine("ERROR: aid: project format $repoFmt is newer than this CLI supports ($sup). Upgrade the aid CLI to operate on this project.")
        return 1
    }
    if ($repoFmt -lt $sup) {
        $manifestPath = Join-Path $Repo (Join-Path '.aid' '.aid-manifest.json')
        if ($env:AID_NO_MIGRATE -ne '1' -and (Test-Path $manifestPath -PathType Leaf)) {
            Write-Host "WARN: aid: this project uses an older format (v${repoFmt}; current: v${sup}). Run: aid update"
        }
        return 0
    }
    # repo == sup: silent.
    return 0
}

# ---------------------------------------------------------------------------
# Registry helpers (DR-1 / FF-1 / FR29 -- PS twin of Bash registry_register /
# registry_unregister).  Implements DM-1 schema, DD-3 Move-Item -Force atomic
# write, DD-REG-FMT line-scan (no YAML library).
# Defined here (before the sentinel try block) so they are available to the
# dispatch handlers (status, bare-aid, update-tool) that call them.
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

# Get-RegistryUnion
# Return the deduped sort-unique union of the primary tier ($script:_AidStateHome/
# registry.yml, which honors the AID_HOME override via the startup scope derivation)
# and, when $script:_AidStateHome differs from $HOME/.aid, also the $HOME/.aid/
# registry.yml fallback tier.  Prunes stale entries quietly: a path is emitted only
# if its .aid/ sub-directory still exists.  Never writes or mutates any registry file.
#
# Per-user collapse: when $script:_AidStateHome == $HOME/.aid the two paths are the
# same file -- the union degenerates to a single-tier read (no double-read, no elevation).
# Mirror of bash _registry_read_union.
function script:Get-RegistryUnion {
    $primaryReg  = Join-Path $script:_AidStateHome 'registry.yml'
    $userDotAid  = Join-Path $HOME '.aid'
    $fallbackReg = Join-Path $userDotAid 'registry.yml'

    $raw = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    # Primary tier (always read).
    foreach ($p in (script:Get-RegistryRepos -RegPath $primaryReg)) {
        if ($p) { [void]$raw.Add($p) }
    }

    # Fallback tier only when paths differ (global install).
    $primaryNorm  = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $fallbackNorm = [System.IO.Path]::GetFullPath($userDotAid)
    if ($primaryNorm -ne $fallbackNorm) {
        foreach ($p in (script:Get-RegistryRepos -RegPath $fallbackReg)) {
            if ($p) { [void]$raw.Add($p) }
        }
    }

    # Quiet-prune: emit only paths whose .aid/ still exists.
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($p in ($raw | Sort-Object)) {
        $aidDir = Join-Path $p '.aid'
        if (Test-Path $aidDir -PathType Container) {
            $result.Add($p)
        }
    }
    return $result.ToArray()
}

# Get-RegistryRawUnion
# Like Get-RegistryUnion but WITHOUT the .aid/ quiet-prune.
# Returns EVERY registered path including paths whose .aid/ is absent or the
# directory does not exist.  Used by 'aid projects list' to render no-aid/missing
# states.  Never writes or mutates any registry file on read.
#
# Per-user collapse: when AID_STATE_HOME == $HOME/.aid, the single-tier read
# preserves registry-file order (no sort), mirroring bash.  When paths differ
# (global install), the deduped union of primary + fallback is sort-unique.
# Mirror of bash _registry_read_raw_union.
function script:Get-RegistryRawUnion {
    $primaryReg  = Join-Path $script:_AidStateHome 'registry.yml'
    $userDotAid  = Join-Path $HOME '.aid'
    $fallbackReg = Join-Path $userDotAid 'registry.yml'

    $primaryNorm  = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $fallbackNorm = [System.IO.Path]::GetFullPath($userDotAid)
    $perUser      = ($primaryNorm -eq $fallbackNorm)

    $result = [System.Collections.Generic.List[string]]::new()

    if ($perUser) {
        # Per-user collapse: single-tier; preserve registry-file order (no sort).
        foreach ($p in (script:Get-RegistryRepos -RegPath $primaryReg)) {
            if ($p) { $result.Add($p) }
        }
    } else {
        # Distinct paths: sort-unique union of primary and fallback.
        # Use SortedSet with Ordinal comparer to match bash `sort -u` (bytewise, uppercase-first).
        $raw = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($p in (script:Get-RegistryRepos -RegPath $primaryReg)) {
            if ($p) { [void]$raw.Add($p) }
        }
        foreach ($p in (script:Get-RegistryRepos -RegPath $fallbackReg)) {
            if ($p) { [void]$raw.Add($p) }
        }
        foreach ($p in $raw) {
            $result.Add($p)
        }
    }

    return $result.ToArray()
}

# Resolve-AidTier <CanonPath> [-TierOverride <string>]
# Deterministic, non-interactive tier selection for 'aid projects add' (FR6/AC6).
# Returns "user" or "shared".
#
# Auto rule:
#   - Returns "user" if _AidScope != "global" (per-user install), OR if the
#     path is under $HOME (any install type).
#   - Otherwise (global install AND path outside $HOME): returns "shared".
#
# Override via -TierOverride:
#   ""         no override, use auto rule (default)
#   "--local"  force "user" regardless of install type/path
#   "--shared" force "shared"; but on a per-user install (AID_STATE_HOME == ~/.aid)
#              there is no separate shared tier -- returns "user" and prints a
#              one-line notice to stderr.
#
# Never prompts; never blocks; always returns normally.
# Mirror of bash _aid_resolve_tier.
function script:Resolve-AidTier {
    param(
        [string]$CanonPath,
        [string]$TierOverride = ''
    )

    # Detect per-user install (no separate shared tier).
    $userDotAid  = Join-Path $HOME '.aid'
    $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $userNorm    = [System.IO.Path]::GetFullPath($userDotAid)
    $perUser     = ($primaryNorm -eq $userNorm)

    # Handle explicit override flags.
    switch ($TierOverride) {
        '--local' { return 'user' }
        '--shared' {
            if ($perUser) {
                [Console]::Error.WriteLine('no shared tier under a per-user install; using user tier')
                return 'user'
            }
            return 'shared'
        }
    }

    # Auto rule: user if per-user install OR path is under $HOME.
    $inHome = $CanonPath.StartsWith($HOME + [System.IO.Path]::DirectorySeparatorChar) -or
              $CanonPath -eq $HOME

    if ($script:_AidScope -ne 'global' -or $inHome) {
        return 'user'
    }
    return 'shared'
}

# Get-AidProjectState <Path>
# Return the state of an AID project directory:
#   "missing"   -- the directory does not exist
#   "no-aid"    -- directory exists but has no .aid/ subdirectory
#   "untracked" -- .aid/ exists but no .aid/.aid-manifest.json is present
#   "vX.Y.Z"   -- tracked; semver version string from .aid/.aid-manifest.json
#                  (key "aid_version"), falling back to .aid/.aid-version
# Never errors; always returns normally.
# Mirror of bash _aid_project_state.
function script:Get-AidProjectState {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) { return 'missing' }
    $aidDir = Join-Path $Path '.aid'
    if (-not (Test-Path $aidDir -PathType Container)) { return 'no-aid' }
    $manifest = Join-Path $aidDir '.aid-manifest.json'
    $verFile   = Join-Path $aidDir '.aid-version'
    if (Test-Path $manifest -PathType Leaf) {
        $content = Get-Content -LiteralPath $manifest -Raw -Encoding utf8 -ErrorAction SilentlyContinue
        if ($content -and $content -match '"aid_version"\s*:\s*"([^"]*)"') {
            $raw = $Matches[1]
            if ($raw -match '([0-9]+\.[0-9]+\.[0-9]+[^\s]*)') {
                return $Matches[1]
            }
        }
    }
    if (Test-Path $verFile -PathType Leaf) {
        $vfContent = Get-Content -LiteralPath $verFile -Raw -Encoding utf8 -ErrorAction SilentlyContinue
        if ($vfContent -and $vfContent -match '([0-9]+\.[0-9]+\.[0-9]+[^\s]*)') {
            return $Matches[1]
        }
    }
    return 'untracked'
}

# Get-AidProjectTools <Path>
# Return a comma-separated list of tool names installed in an AID project, as
# recorded in <path>/.aid/.aid-manifest.json under the "tools" object.
# Returns empty string when the manifest is absent or has no tools.
#
# Mirrors the canonical bash awk extractor (lib/aid-install-core.sh:~1019):
#   /"tools"/{found=1} found && /^    "[a-z]/{gsub(/[^a-zA-Z0-9_.-]/,"",$1); if ($1!="") print $1}
# Scans the whole file once found=1 -- no break condition -- so ALL tool names
# at exactly 4-space indent with a lowercase-initial key are collected.
# Does NOT use a closing-brace break (the bash awk doesn't either), avoiding
# the premature-exit bug that fires on each tool's own closing "    }".
# Mirror of bash _aid_project_tools.
function script:Get-AidProjectTools {
    param([string]$Path)
    $manifest = Join-Path $Path '.aid' '.aid-manifest.json'
    if (-not (Test-Path $manifest -PathType Leaf)) { return '' }
    $lines = Get-Content -LiteralPath $manifest -Encoding utf8 -ErrorAction SilentlyContinue
    if (-not $lines) { return '' }
    # Mirrors: /"tools"/{found=1} found && /^    "[a-z]/{...}
    $found = $false
    $tools = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($line in $lines) {
        if ($line -match '"tools"') { $found = $true; continue }
        if ($found -and $line -match '^    "[a-z]') {
            # Strip everything except [a-zA-Z0-9_.-] from the key token (mirrors gsub).
            # The key is the first "word" on the line: characters up to the first non-key char.
            if ($line -match '^    "([^"]+)"') {
                $raw = $Matches[1]
                # gsub(/[^a-zA-Z0-9_.-]/,"",$1) -- keep only identifier chars
                $toolName = [regex]::Replace($raw, '[^a-zA-Z0-9_.\-]', '')
                if ($toolName -and -not $tools.Contains($toolName)) {
                    [void]$tools.Add($toolName)
                }
            }
        }
    }
    # sort -u (bytewise ordinal, matching bash): use SortedSet with Ordinal comparer.
    $sortedTools = [System.Collections.Generic.SortedSet[string]]::new($tools, [System.StringComparer]::Ordinal)
    return ($sortedTools -join ',')
}

# Get-WhichTierHolds <Path>
# Returns "user" or "shared" based on which registry file contains the path.
# Falls back to Resolve-AidTier if the path is not found in either.
# Mirror of bash _which_tier_holds.
function script:Get-WhichTierHolds {
    param([string]$Path)
    $primaryReg = Join-Path $script:_AidStateHome 'registry.yml'
    $userReg    = Join-Path $HOME '.aid' 'registry.yml'

    $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $userNorm    = [System.IO.Path]::GetFullPath((Join-Path $HOME '.aid'))

    if ($primaryNorm -ne $userNorm) {
        # Global install: check shared/primary first.
        if ((script:Get-RegistryRepos -RegPath $primaryReg) -contains $Path) {
            return 'shared'
        }
        if ((script:Get-RegistryRepos -RegPath $userReg) -contains $Path) {
            return 'user'
        }
    } else {
        # Per-user: single file.
        if ((script:Get-RegistryRepos -RegPath $primaryReg) -contains $Path) {
            return 'user'
        }
    }
    # Fallback: derive from tier resolution.
    return (script:Resolve-AidTier -CanonPath $Path)
}

# Invoke-AidProjectsList [Verbose]
# Render the raw union as an aligned table: marker, path, state, tools, tier.
# Marks cwd with "*"; footnotes unregistered AID cwd.
# Mirror of bash _cmd_projects_list.
function script:Invoke-AidProjectsList {
    param([bool]$Verbose = $false)

    # Canonical cwd.
    $cwd = (Resolve-Path -LiteralPath '.' -ErrorAction SilentlyContinue).Path
    if (-not $cwd) { $cwd = (Get-Location).Path }

    $paths = @(script:Get-RegistryRawUnion)

    # Column header.
    Write-Host ('{0,-2}  {1,-45}  {2,-10}  {3,-20}  {4}' -f ' ', 'PATH', 'STATE', 'TOOLS', 'TIER')
    Write-Host ('{0,-2}  {1,-45}  {2,-10}  {3,-20}  {4}' -f '--', '----', '-----', '-----', '----')

    $cwdRegistered = $false
    foreach ($entry in $paths) {
        $state  = script:Get-AidProjectState  -Path $entry
        $tools  = script:Get-AidProjectTools  -Path $entry
        $tier   = script:Get-WhichTierHolds   -Path $entry
        $marker = '  '
        if ($entry -eq $cwd) {
            $marker = '* '
            $cwdRegistered = $true
        }
        $toolsDisplay = if ($tools) { $tools } else { '-' }
        Write-Host ('{0,-2}  {1,-45}  {2,-10}  {3,-20}  {4}' -f $marker, $entry, $state, $toolsDisplay, $tier)
        if ($Verbose) {
            $regSrc = if ($tier -eq 'shared' -and
                ([System.IO.Path]::GetFullPath($script:_AidStateHome) -ne [System.IO.Path]::GetFullPath((Join-Path $HOME '.aid')))) {
                Join-Path $script:_AidStateHome 'registry.yml'
            } else {
                Join-Path $HOME '.aid' 'registry.yml'
            }
            Write-Host ('      registry: {0}' -f $regSrc)
        }
    }

    if ($paths.Count -eq 0) {
        Write-Host '(no projects registered)'
    }

    # Footnote: unregistered AID cwd (only when cwd is a real project, not the state home).
    if (-not $cwdRegistered -and (script:Test-AidIsProjectDir -Dir $cwd)) {
        Write-Host ''
        Write-Host "(here) -- not registered; run 'aid projects add'"
    }

    # Legend.
    if ($paths.Count -gt 0) {
        Write-Host ''
        Write-Host '* = current directory'
    }
}

# Invoke-AidProjectsAdd [RawPath] [TierOverride] [Verbose]
# Register a project path (default: cwd) in the deterministic tier.
# Mirror of bash _cmd_projects_add.
function script:Invoke-AidProjectsAdd {
    param(
        [string]$RawPath    = '.',
        [string]$TierOverride = '',
        [bool]  $Verbose    = $false
    )

    # Canonicalize.
    $resolvedAdd = Resolve-Path -LiteralPath $RawPath -ErrorAction SilentlyContinue
    $canon = if ($resolvedAdd) { $resolvedAdd.Path } else { $null }
    if (-not $canon) {
        [Console]::Error.WriteLine("ERROR: aid projects add: path does not exist: $RawPath")
        script:Exit-Aid 2
    }

    # Require a real AID project (.aid/ present AND not the CLI state home).
    if (-not (script:Test-AidIsProjectDir -Dir $canon)) {
        [Console]::Error.WriteLine("ERROR: aid projects add: '$canon' is not an AID project; run 'aid add <tool>' first.")
        script:Exit-Aid 2
    }

    # Resolve tier.
    $tier = script:Resolve-AidTier -CanonPath $canon -TierOverride $TierOverride

    # Register (idempotent). Suppress Registry-Register's own Write-Host output so we
    # emit a single consolidated message instead; stderr (WARN lines) flows through.
    script:Registry-Register -Repo $canon -Tier $tier 6>$null
    Write-Host ("aid projects: '$canon' registered in $tier tier.")
    if ($Verbose) {
        $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
        $userNorm    = [System.IO.Path]::GetFullPath((Join-Path $HOME '.aid'))
        $regFile = if ($tier -eq 'shared' -and $primaryNorm -ne $userNorm) {
            Join-Path $script:_AidStateHome 'registry.yml'
        } else {
            Join-Path $HOME '.aid' 'registry.yml'
        }
        Write-Host ("aid projects: registry file: $regFile")
    }
}

# Invoke-AidProjectsRemove [RawPath] [Verbose]
# Unregister a project path (default: cwd); no .aid/ required (repair stale).
# Mirror of bash _cmd_projects_remove.
function script:Invoke-AidProjectsRemove {
    param(
        [string]$RawPath = '.',
        [bool]  $Verbose = $false
    )

    # Canonicalize without requiring the directory to exist.
    $resolvedRem = Resolve-Path -LiteralPath $RawPath -ErrorAction SilentlyContinue
    $canon = if ($resolvedRem) { $resolvedRem.Path } else { $null }
    if (-not $canon) {
        # Directory absent (stale entry); use raw path as-is.
        $canon = $RawPath
    }

    # Check if registered before unregistering (for idempotency message).
    $primaryReg = Join-Path $script:_AidStateHome 'registry.yml'
    $userReg    = Join-Path $HOME '.aid' 'registry.yml'
    $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $userNorm    = [System.IO.Path]::GetFullPath((Join-Path $HOME '.aid'))
    $found = $false
    if ((script:Get-RegistryRepos -RegPath $primaryReg) -contains $canon) {
        $found = $true
    } elseif ($primaryNorm -ne $userNorm) {
        if ((script:Get-RegistryRepos -RegPath $userReg) -contains $canon) {
            $found = $true
        }
    }

    script:Registry-Unregister -Repo $canon
    if (-not $found) {
        Write-Host ("aid projects: '$canon' was not registered (nothing to remove).")
    } elseif ($Verbose) {
        Write-Host ("aid projects: removed '$canon' from registry.")
    }
}

# Invoke-AidProjects [Action] [RemArgs]
# Orchestrates list/add/remove/help for the project registry.
# Mirror of bash _cmd_projects.
function script:Invoke-AidProjects {
    param(
        [string]  $Action  = 'list',
        [string[]]$RemArgs = @()
    )

    $pathArg      = ''
    $tierOverride = ''
    $verbose      = $false

    # Parse remaining args.
    $i = 0
    while ($i -lt $RemArgs.Count) {
        $a = $RemArgs[$i]
        switch ($a) {
            { $_ -in @('-h', '--help', '-Help') } { $Action = 'help'; break }
            '--local'   { $tierOverride = '--local'; break }
            '--shared'  { $tierOverride = '--shared'; break }
            '--verbose' { $verbose = $true; $script:_AidVerbose = $true; break }
            { $_ -match '^-' } {
                [Console]::Error.WriteLine("ERROR: aid projects: unknown flag: $a (see 'aid projects -h')")
                script:Exit-Aid 2
                break
            }
            default {
                if (-not $pathArg) { $pathArg = $a }
            }
        }
        $i++
    }

    $resolvedPath = if ($pathArg) { $pathArg } else { '.' }

    switch ($Action) {
        'list'   { script:Invoke-AidProjectsList   -Verbose $verbose }
        'add'    { script:Invoke-AidProjectsAdd    -RawPath $resolvedPath -TierOverride $tierOverride -Verbose $verbose }
        'remove' { script:Invoke-AidProjectsRemove -RawPath $resolvedPath -Verbose $verbose }
        'help'   { script:Show-AidUsage 'projects'; script:Exit-Aid 0 }
        default  {
            [Console]::Error.WriteLine("ERROR: aid projects: unknown action: $Action (expected: list, add, remove, help)")
            script:Exit-Aid 2
        }
    }
}

# Invoke-AidCwdClassify <Target>
# C-table: classify the cwd repo and perform register-on-encounter.
# Called before repo commands (status, update [tool]) when .aid/ exists.
# Checks if already registered (union read); if not, picks tier and registers.
# Returns always (registration is best-effort; never blocks the host command).
# Mirror of bash _aid_cwd_classify.
function script:Invoke-AidCwdClassify {
    param([string]$Target)

    $canonTarget = (Resolve-Path -LiteralPath $Target -ErrorAction SilentlyContinue).Path
    if (-not $canonTarget) { $canonTarget = $Target }

    # Check if already registered in the union.
    $isRegistered = $false
    foreach ($regP in (script:Get-RegistryUnion)) {
        if ($regP -eq $canonTarget) { $isRegistered = $true; break }
    }

    if (-not $isRegistered) {
        # Not registered -- pick tier deterministically via Resolve-AidTier (FR7: no prompt).
        $regTier = script:Resolve-AidTier -CanonPath $canonTarget
        try { script:Registry-Register -Repo $canonTarget -Tier $regTier } catch {}
    }
}

# Invoke-AidCwdNoAidOffer <Target>
# C-table last row: .aid/ absent -- print offer + optional non-git note, exit 0.
# No hard refuse (decision #5): missing .aid/ is an offer, not an error.
# Mirror of bash _aid_cwd_no_aid_offer.
function script:Invoke-AidCwdNoAidOffer {
    param([string]$Target)

    $canon = (Resolve-Path -LiteralPath $Target -ErrorAction SilentlyContinue).Path
    if (-not $canon) { $canon = $Target }

    Write-Host 'no AID project here -- set it up? (aid add)'
    # Non-git note (decision #5): a non-git dir can use AID; .aid/ just won't be
    # version-controlled if git is absent.
    $gitOut = $null
    try { $gitOut = & git -C $canon rev-parse --git-dir 2>&1 } catch {}
    if ($LASTEXITCODE -ne 0 -or -not $gitOut) {
        Write-Host "Note: $canon is not a git repository -- .aid/ will not be version-controlled."
    }
    script:Exit-Aid 0
}

# Register a canonical repo path in the registry.yml (set-insert, idempotent).
# Prints one line on a real change; silent on no-op.  Prints WARN on failure; never
# throws (host-tool op is never blocked -- NFR10 / DD-3 / CLI-1).
#
# Tier param: 'user' (default) or 'shared'.
#
# USER tier (default): primary target is $script:_AidStateHome/registry.yml (honors
# AID_HOME override via startup scope derivation).  If AID_STATE_HOME is not user-
# writable AND is a different path from $HOME/.aid, degrades to $HOME/.aid/registry.yml
# with a WARN (fire-and-continue; never blocks the host command).  Per-user collapse:
# when AID_STATE_HOME == $HOME/.aid the two are the same file -- single-tier, no fallback.
#
# SHARED tier: writes to $script:_AidStateHome/registry.yml directly (no elevation
# wrapper on Windows -- the underlying tool surfaces its own access error; callers
# elevate their own shell).  If the write fails or the shared dir is not writable,
# DEGRADES to skip + WARN + return (matching bash _aid_priv_run-declined contract;
# SPEC AC6 / decision #2).  Per-user install (AID_STATE_HOME == ~/.aid): shared-tier
# argument is treated as user-tier (same file, no elevation needed).
# Defined before the sentinel try block so it is available to bare-aid, status, and
# Invoke-AidCwdClassify (all of which call it before any later def would be reached).
function script:Registry-Register {
    param([string]$Repo, [string]$Tier = 'user')

    # Per-user collapse: AID_STATE_HOME == $HOME/.aid -> shared-tier is user-tier (same file).
    $userDotAid  = Join-Path $HOME '.aid'
    $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $userNorm    = [System.IO.Path]::GetFullPath($userDotAid)
    $perUser     = ($primaryNorm -eq $userNorm)

    # Helper: test writability of a directory.
    $testWritable = {
        param([string]$dir)
        if (-not (Test-Path $dir -PathType Container)) { return $false }
        $probe = Join-Path $dir ('.aid-write-probe.' + [System.IO.Path]::GetRandomFileName())
        try { [System.IO.File]::WriteAllText($probe, ''); Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue; return $true } catch { return $false }
    }

    # Helper: write registry content to a file (temp+mv atomic).
    $writeRegistry = {
        param([string]$regPath, [string[]]$repos)
        $dir = Split-Path $regPath -Parent
        if (-not (Test-Path $dir -PathType Container)) {
            try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch {}
        }
        $tmp = Join-Path $dir ("registry.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
        try {
            $lns = [System.Collections.Generic.List[string]]::new()
            $lns.Add("# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).")
            $lns.Add("# Holds ONLY the base folders of projects this CLI install manages. Per-project name and")
            $lns.Add("# description come from .aid/settings.yml; version/tools from the manifest, at render time.")
            $lns.Add("schema: 1")
            $lns.Add("projects:")
            foreach ($p in ($repos | Where-Object { $_ } | Sort-Object -Unique)) { $lns.Add("  - $p") }
            Set-Content -LiteralPath $tmp -Value $lns.ToArray() -Encoding utf8NoBOM -ErrorAction Stop
            Move-Item -LiteralPath $tmp -Destination $regPath -Force -ErrorAction Stop
            return $true
        } catch {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            return $false
        }
    }

    # ------ SHARED tier -------------------------------------------------------
    if ($Tier -eq 'shared' -and -not $perUser) {
        # Shared write: attempt directly (no elevation wrapper on Windows).
        # If the shared dir is not writable, degrade: skip + WARN + return (0-equivalent).
        $sharedRegDir = $script:_AidStateHome
        if (-not (Test-Path $sharedRegDir -PathType Container)) {
            try { New-Item -ItemType Directory -Path $sharedRegDir -Force | Out-Null } catch {}
        }
        if (-not (& $testWritable $sharedRegDir)) {
            [Console]::Error.WriteLine("WARN: aid: shared registry write declined or unavailable; project not registered in shared tier ($sharedRegDir\registry.yml)")
            return
        }
        $sharedReg = Join-Path $sharedRegDir 'registry.yml'
        $existing  = @(script:Get-RegistryRepos -RegPath $sharedReg)
        if ($existing -contains $Repo) {
            if ($script:_AidVerbose) { Write-Host "Registry: $Repo already registered in shared tier (no-op)." }
            return
        }
        $ok = & $writeRegistry $sharedReg ($existing + @($Repo))
        if (-not $ok) {
            [Console]::Error.WriteLine("WARN: aid: could not update the shared project registry ($sharedReg): write failed")
            return
        }
        Write-Host "Registered $Repo with the AID CLI (shared registry)."
        return
    }

    # ------ USER tier (default) or per-user collapse -------------------------
    # Primary: $script:_AidStateHome (honors AID_HOME override via startup scope derivation).
    # Fallback: $HOME/.aid (when AID_STATE_HOME is not writable and is a different path).
    # Never-elevate: empty probe.
    if (-not (Test-Path $script:_AidStateHome -PathType Container)) {
        try { New-Item -ItemType Directory -Path $script:_AidStateHome -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    $writeDir = $null
    if (& $testWritable $script:_AidStateHome) {
        $writeDir = $script:_AidStateHome
    } else {
        # AID_STATE_HOME not writable; degrade to $HOME/.aid (user fallback).
        if (-not (Test-Path $userDotAid -PathType Container)) {
            try { New-Item -ItemType Directory -Path $userDotAid -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        # Degrade is the designed global-install behavior -- silent by default; shown under verbose.
        if ($script:_AidVerbose) {
            [Console]::Error.WriteLine("WARN: aid: could not write to state home $($script:_AidStateHome); using $userDotAid\registry.yml")
        }
        $writeDir = $userDotAid
    }
    $writeReg = Join-Path $writeDir 'registry.yml'
    $existing  = @(script:Get-RegistryRepos -RegPath $writeReg)
    # Idempotent: already registered -> silent no-op.
    if ($existing -contains $Repo) {
        if ($script:_AidVerbose) { Write-Host "Registry: $Repo already registered (no-op)." }
        return
    }
    $ok = & $writeRegistry $writeReg ($existing + @($Repo))
    if (-not $ok) {
        [Console]::Error.WriteLine("WARN: aid: could not update the machine project registry ($writeReg): write failed")
        return
    }
    Write-Host "Registered $Repo with the AID CLI."
}

# Unregister a canonical repo path from the registry.yml (set-remove, idempotent).
# Called only when the repo manifest is now gone (last tool removed).
# Prints one line on a real change; silent on no-op.  Prints WARN on failure; never throws.
#
# Tier-aware: removes from tier(s) where the entry is found.  Scope-aware resolution
# mirrors Registry-Register: primary=$script:_AidStateHome, fallback=$HOME/.aid.
# Per-user install (AID_STATE_HOME == $HOME/.aid): both paths are the same -- single write.
# Defined before the sentinel try block (symmetric with Registry-Register above).
function script:Registry-Unregister {
    param([string]$Repo)

    $userDotAid  = Join-Path $HOME '.aid'
    $primaryNorm = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $userNorm    = [System.IO.Path]::GetFullPath($userDotAid)
    $perUser     = ($primaryNorm -eq $userNorm)

    $sharedReg   = Join-Path $script:_AidStateHome 'registry.yml'
    $userReg     = Join-Path $userDotAid 'registry.yml'

    # Helper: test writability of a directory.
    $testW = {
        param([string]$dir)
        if (-not (Test-Path $dir -PathType Container)) { return $false }
        $probe = Join-Path $dir ('.aid-write-probe.' + [System.IO.Path]::GetRandomFileName())
        try { [System.IO.File]::WriteAllText($probe, ''); Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue; return $true } catch { return $false }
    }

    # Helper: rewrite registry removing $Repo (atomic temp+mv).
    $rewriteReg = {
        param([string]$regPath, [string[]]$current)
        $dir = Split-Path $regPath -Parent
        $tmp = Join-Path $dir ("registry.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
        try {
            $remaining = $current | Where-Object { $_ -ne $Repo } | Sort-Object -Unique
            $lns = [System.Collections.Generic.List[string]]::new()
            $lns.Add("# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).")
            $lns.Add("# Holds ONLY the base folders of projects this CLI install manages. Per-project name and")
            $lns.Add("# description come from .aid/settings.yml; version/tools from the manifest, at render time.")
            $lns.Add("schema: 1")
            $lns.Add("projects:")
            if ($remaining) { foreach ($p in $remaining) { $lns.Add("  - $p") } }
            Set-Content -LiteralPath $tmp -Value $lns.ToArray() -Encoding utf8NoBOM -ErrorAction Stop
            Move-Item -LiteralPath $tmp -Destination $regPath -Force -ErrorAction Stop
            return $true
        } catch {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            return $false
        }
    }

    $foundAny = $false

    # --- PRIMARY TIER ($AID_STATE_HOME) ---
    if (& $testW $script:_AidStateHome) {
        $ex = @(script:Get-RegistryRepos -RegPath $sharedReg)
        if ($ex -contains $Repo) {
            $foundAny = $true
            $ok = & $rewriteReg $sharedReg $ex
            if (-not $ok) {
                [Console]::Error.WriteLine("WARN: aid: could not update the machine project registry ($sharedReg): write failed")
                return
            }
        }
    } else {
        # AID_STATE_HOME not writable: check/operate on fallback $HOME/.aid tier.
        if (-not (Test-Path $userDotAid -PathType Container)) {
            try { New-Item -ItemType Directory -Path $userDotAid -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        $ex = @(script:Get-RegistryRepos -RegPath $userReg)
        if ($ex -contains $Repo) {
            $foundAny = $true
            # Degrade is the designed global-install behavior -- silent by default; shown under verbose.
            if ($script:_AidVerbose) {
                [Console]::Error.WriteLine("WARN: aid: could not write to state home $($script:_AidStateHome); using $userReg")
            }
            $ok = & $rewriteReg $userReg $ex
            if (-not $ok) {
                [Console]::Error.WriteLine("WARN: aid: could not update the machine project registry ($userReg): write failed")
                return
            }
        }
    }

    # --- FALLBACK / SECONDARY TIER ($HOME/.aid, global install only) ---
    # When AID_STATE_HOME is writable and != $HOME/.aid, also check if the entry
    # exists in $HOME/.aid (e.g. was registered when AID_STATE_HOME was non-writable).
    if (-not $perUser -and (& $testW $script:_AidStateHome)) {
        $fbEx = @(script:Get-RegistryRepos -RegPath $userReg)
        if ($fbEx -contains $Repo) {
            $foundAny = $true
            if (-not (Test-Path $userDotAid -PathType Container)) {
                try { New-Item -ItemType Directory -Path $userDotAid -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
            }
            if (& $testW $userDotAid) {
                $ok = & $rewriteReg $userReg $fbEx
                if (-not $ok) {
                    [Console]::Error.WriteLine("WARN: aid: could not update the machine project registry ($userReg): write failed")
                }
            } else {
                [Console]::Error.WriteLine("WARN: aid: could not write to registry at $userReg (not writable); unregister skipped")
            }
        }
    }

    if (-not $foundAny) {
        if ($script:_AidVerbose) { Write-Host "Registry: $Repo not in registry (no-op)." }
        return
    }
    Write-Host "Unregistered $Repo from the AID CLI."
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
    # C-table: if cwd is not an AID project -> offer (no hard refuse, decision #5); exit 0.
    # Test-AidIsProjectDir excludes the CLI state home from "is project" classification.
    if (-not (script:Test-AidIsProjectDir -Dir '.')) {
        script:Invoke-AidCwdNoAidOffer -Target '.'
        # Invoke-AidCwdNoAidOffer always calls Exit-Aid 0.
    }
    # C-table register-on-encounter (best-effort, never blocks bare aid).
    script:Invoke-AidCwdClassify -Target '.'

    # Block 1 + 2: Header + description.
    $cliVersion = 'unknown'
    $verFile = Join-Path $script:_AidCodeHome 'VERSION'
    if (Test-Path $verFile -PathType Leaf) {
        $cliVersion = (Get-Content -LiteralPath $verFile -Raw).Trim()
    }
    Write-Host "AID v$cliVersion - AI Integrated Development"
    Write-Host "Install, update, and manage AID across your projects."

    # C6': format gate for cwd repo (.aid/ is guaranteed present here -- the
    # non-project case is intercepted above via Invoke-AidCwdNoAidOffer;
    # register-on-encounter already ran via Invoke-AidCwdClassify).
    # Test-AidIsProjectDir guards the state-home exclusion (double-check).
    if (script:Test-AidIsProjectDir -Dir '.') {
        $gateRc = script:Invoke-AidFormatGate -Repo '.'
        if ($gateRc -ne 0) { script:Exit-Aid $gateRc }
    }

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
    $versionFile = Join-Path $script:_AidCodeHome 'VERSION'
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

    # C-table: if target is not an AID project -> offer (no hard refuse, decision #5); exit 0.
    # Test-AidIsProjectDir excludes the CLI state home from "is project" classification.
    if (-not (script:Test-AidIsProjectDir -Dir $statusTarget)) {
        script:Invoke-AidCwdNoAidOffer -Target $statusTarget
        # Invoke-AidCwdNoAidOffer always calls Exit-Aid 0.
    }
    # C-table register-on-encounter (best-effort, never blocks status).
    script:Invoke-AidCwdClassify -Target $statusTarget
    # C6': format gate for status target (only when target is a real project).
    $gateRc = script:Invoke-AidFormatGate -Repo $statusTarget
    if ($gateRc -ne 0) { script:Exit-Aid $gateRc }

    $rc = Get-AidStatus -Target $statusTarget
    # Update check notice appended after status output (non-blocking).
    script:Invoke-AidUpdateCheck
    script:Exit-Aid $rc
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
    } elseif ((Test-Path $dsA -PathType Leaf) -or (Test-Path $dsB -PathType Leaf) -or (Test-Path $dsC -PathType Leaf) -or (Test-Path (Join-Path $aidDir '.aid-manifest.json') -PathType Leaf)) {
        # Era-b: KB-state present, OR a tracked repo (manifest present) with no
        # settings.yml yet (the `aid add`-only state). Synthesize a fresh stamped
        # settings.yml so the format gate stops warning and the repo is brought
        # current. Mirrors bin/aid. Without the manifest clause such repos warn
        # forever and are never stamped.
        $era = 'b'
    } else {
        return 0   # bare .aid/ (no settings.yml, no KB state, no manifest) -- not a candidate
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
        $htmlSrc = Join-Path $script:_AidCodeHome 'dashboard' | Join-Path -ChildPath 'home.html'
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
    # FR7 never-elevate: resolve tier deterministically; if shared but the shared
    # dir is not writable, degrade silently to user (mirrors bash _aid_migrate_repo).
    # ------------------------------------------------------------------
    try {
        $_migTier = script:Resolve-AidTier -CanonPath $Repo
        # Degrade: shared + non-writable shared dir -> user (never-elevate in migrate).
        if ($_migTier -eq 'shared') {
            $testW = { param([string]$d)
                if (-not (Test-Path $d -PathType Container)) { return $false }
                $probe = Join-Path $d ('.aid-write-probe.' + [System.IO.Path]::GetRandomFileName())
                try { [System.IO.File]::WriteAllText($probe, ''); Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue; return $true } catch { return $false }
            }
            if (-not (& $testW $script:_AidStateHome)) { $_migTier = 'user' }
        }
        script:Registry-Register -Repo $Repo -Tier $_migTier
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

    # --- C3': format_version ensure-key step (top-of-file column-0 prepend) ---
    # If a ^format_version: line is present, replace it in-place (IDIOM-A).
    # If absent, prepend format_version: <sup> at index 0 above project:.
    $fvIdx = -1
    for ($fi = 0; $fi -lt $lines.Count; $fi++) {
        if ($lines[$fi] -match '^format_version:') { $fvIdx = $fi; break }
    }
    if ($fvIdx -ge 0) {
        # Key present: replace with canonical value (IDIOM-A).
        & $replaceLine $fvIdx "format_version: $($script:AidSupportedFormat)"
    } else {
        # Key absent: prepend at index 0 (new top-of-file col-0 insert above project:).
        $lines.Insert(0, "format_version: $($script:AidSupportedFormat)")
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
    # C2': format_version stamp is the FIRST line (before project:).
    [void]$sb.Append("format_version: $($script:AidSupportedFormat)`n")
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

# Script-scope vars consumed by Invoke-AidUpdateSelf (reset here before each parse).
$script:_SelfFromBundle = ''
$script:_SelfDryRun     = $false

# ---------------------------------------------------------------------------
# update (with 'self' subarg -> update self)
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'update') {
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'self') {
        # Consume any flags after 'self'.
        $script:_SelfFromBundle = ''
        $script:_SelfDryRun     = $false
        $remIdx = 1
        while ($remIdx -lt $script:_RemArgs.Count) {
            $a = $script:_RemArgs[$remIdx]
            switch ($a) {
                { $_ -in @('-Force', '--force', '-y') }      { }  # no-op for update self
                { $_ -in @('-DryRun', '--dry-run') }         { $script:_SelfDryRun = $true }
                { $_ -in @('-h', '--help', '-Help') }        { script:Show-AidUsage 'update'; script:Exit-Aid 0 }
                { $_ -in @('-FromBundle', '--from-bundle') } {
                    $remIdx++
                    if ($remIdx -ge $script:_RemArgs.Count) {
                        script:Fail-Aid '-FromBundle requires a value' 2
                    }
                    $script:_SelfFromBundle = $script:_RemArgs[$remIdx]
                }
                default { script:Fail-Aid "unknown flag for 'update self': $a" 2 }
            }
            $remIdx++
        }
        $usRc = script:Invoke-AidUpdateSelf
        if ($usRc -ne 0) { script:Exit-Aid $usRc }
        # Post-update: registry-driven migration (feature-004).
        # Iterate Get-RegistryUnion -- NO scan -- with All/Yes/No/Cancel per-repo
        # consent walk.  Unregistered repos are caught lazily by the per-repo stamp.
        # No .migrated marker is written (removed; stamp in settings.yml is the record).
        # dry-run: the install step already printed its command; skip migration silently.
        if (-not $script:_SelfDryRun) {
            $usAutoYes = ($env:AID_MIGRATE_YES -eq '1')
            $usRepos = @(script:Get-RegistryUnion)
            if ($usRepos.Count -eq 0) {
                Write-Host 'No registered projects to migrate.'
            } else {
                # Determine interactive mode: AID_MIGRATE_YES=1 is the explicit opt-in for
                # auto-yes.  Non-interactive without opt-in -> no migration (per SPEC).
                $usAutoYesFinal = $usAutoYes -or ($env:AID_MIGRATE_YES -eq '1')
                $usIsInteractive = [Environment]::UserInteractive
                if (-not $usAutoYesFinal -and -not $usIsInteractive) {
                    Write-Host 'Skipping project migration (non-interactive; set AID_MIGRATE_YES=1 to opt in).'
                } else {
                    $usMigrateAll    = $false
                    $usMigrateCancel = $false
                    foreach ($usRepo in $usRepos) {
                        if ($usMigrateCancel) { break }
                        if ($usMigrateAll -or $usAutoYesFinal) {
                            $usAnswer = 'y'
                        } else {
                            Write-Host -NoNewline "Migrate project $usRepo? [All/Yes/No/Cancel] "
                            try { $usAnswer = Read-Host } catch { $usAnswer = '' }
                        }
                        switch -Regex ($usAnswer) {
                            '^[Aa](ll|LL)?$' {
                                $usMigrateAll = $true
                                try { script:Invoke-AidMigrateRepo -Repo $usRepo } catch {
                                    [Console]::Error.WriteLine("WARN: aid: migration failed for ${usRepo}: $_")
                                }
                            }
                            '^[Yy](es|ES)?$' {
                                try { script:Invoke-AidMigrateRepo -Repo $usRepo } catch {
                                    [Console]::Error.WriteLine("WARN: aid: migration failed for ${usRepo}: $_")
                                }
                            }
                            '^[Cc](ancel|ANCEL)?$' {
                                $usMigrateCancel = $true
                                Write-Host 'Migration cancelled.'
                            }
                            default {
                                Write-Host "Skipped: $usRepo"
                            }
                        }
                    }
                }
            }
        }
        script:Exit-Aid 0
    }
    # Fall through to shared add/update handler below.
}

# ---------------------------------------------------------------------------
# remove (with 'self' subarg -> remove self)
# Channel-aware, self-contained CLI removal. npm/pypi installs are owned by the
# package manager, so removing only $AID_HOME left the wrapper + bin shim behind.
# Now each channel does the COMPLETE removal:
#   npm  -> npm uninstall -g aid-installer   (package + vendored tree + shim)
#   pypi -> pipx uninstall aid-installer     (venv + entry point)
#   curl -> Remove-Item $AID_CODE_HOME + unwire PATH
# On Windows there is no sudo -- callers elevate their own shell if needed.
# Honors -DryRun.
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'remove') {
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'self') {
        # Parse flags after 'self'.
        $rsForce  = $false
        $rsNoPath = $false
        $rsDryRun = $false
        $remIdx   = 1
        while ($remIdx -lt $script:_RemArgs.Count) {
            $a = $script:_RemArgs[$remIdx]
            switch ($a) {
                { $_ -in @('-Force', '--force', '-y') }          { $rsForce  = $true }
                { $_ -in @('-NoPath', '--no-path', '/nopath') }  { $rsNoPath = $true }
                { $_ -in @('-DryRun', '--dry-run') }             { $rsDryRun = $true }
                { $_ -in @('-h', '--help', '-Help') }            { script:Show-AidUsage 'remove'; script:Exit-Aid 0 }
                default { script:Fail-Aid "unknown flag for 'remove self': $a" 2 }
            }
            $remIdx++
        }

        # Env-var fallback for force.
        if (-not $rsForce -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) {
            $rsForce = $true
        }

        $channel = $env:AID_INSTALL_CHANNEL
        $aidHome = $script:_AidCodeHome

        # Channel-aware description of what will be removed (NFR transparency).
        $what = switch ($channel) {
            'npm'  { "the npm global package 'aid-installer' (npm uninstall -g)" }
            'pypi' { "the pipx app 'aid-installer' (pipx uninstall)" }
            default { "$aidHome and its PATH wiring" }
        }

        if (-not $rsForce -and -not $rsDryRun) {
            # Skip prompt when non-interactive.
            $isInteractive = [Environment]::UserInteractive -and [Console]::In -ne [System.IO.TextReader]::Null
            if (-not $isInteractive) {
                $rsForce = $true
            } else {
                Write-Host -NoNewline "Remove the aid CLI -- ${what}? [y/N] "
                $answer = Read-Host
                if ($answer -notin @('y', 'Y', 'yes', 'YES')) {
                    Write-Host "Aborted."
                    script:Exit-Aid 0
                }
            }
        }

        $partial = $false

        switch ($channel) {
            'npm' {
                $npmCmd = Get-Command 'npm' -ErrorAction SilentlyContinue
                if (-not $npmCmd) {
                    [Console]::Error.WriteLine("ERROR: aid: npm not found; cannot remove the npm-channel CLI")
                    script:Exit-Aid 3
                }
                if ($rsDryRun) {
                    Write-Host '+ npm uninstall -g aid-installer'
                } else {
                    & npm uninstall -g aid-installer
                    if ($LASTEXITCODE -ne 0) { $partial = $true }
                }
            }
            'pypi' {
                $pipxCmd = Get-Command 'pipx' -ErrorAction SilentlyContinue
                if (-not $pipxCmd) {
                    [Console]::Error.WriteLine("ERROR: aid: pipx not found; cannot remove the pypi-channel CLI")
                    script:Exit-Aid 3
                }
                if ($rsDryRun) {
                    Write-Host '+ pipx uninstall aid-installer'
                } else {
                    & pipx uninstall aid-installer
                    if ($LASTEXITCODE -ne 0) { $partial = $true }
                }
            }
            default {
                # curl / default channel -- the _AidCodeHome tree + User PATH wiring.
                if ($rsDryRun) {
                    if (-not $rsNoPath) {
                        Write-Host "+ (unwire $aidHome\bin from your User PATH)"
                    }
                    Write-Host "+ Remove-Item -Recurse -Force $aidHome"
                } else {
                    # Remove PATH wiring.
                    if (-not $rsNoPath) {
                        $binDir = Join-Path $aidHome 'bin'
                        try { script:Remove-AidFromPath -BinDir $binDir } catch { $partial = $true }
                    }

                    # Remove _AidCodeHome directory.
                    if (Test-Path $aidHome -PathType Container) {
                        try {
                            Remove-Item -LiteralPath $aidHome -Recurse -Force -ErrorAction Stop
                        } catch {
                            [Console]::Error.WriteLine("ERROR: aid: failed to remove $aidHome : $_")
                            $partial = $true
                        }
                    }
                }
            }
        }

        if ($rsDryRun) { script:Exit-Aid 0 }

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
# projects
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'projects') {
    # Check for -h/--help as first arg before dispatching.
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -in @('-h', '--help', '-Help')) {
        script:Show-AidUsage 'projects'
        script:Exit-Aid 0
    }

    # Determine sub-action (first positional or default "list").
    # Scan through leading flags to find the action word; unknown positionals are
    # rejected here so errors surface before entering Invoke-AidProjects.
    $_ProjAction = 'list'
    $_ProjArgs   = [System.Collections.Generic.List[string]]::new()
    $remIdx = 0
    while ($remIdx -lt $script:_RemArgs.Count) {
        $a = $script:_RemArgs[$remIdx]
        switch ($a) {
            { $_ -in @('list', 'add', 'remove', 'help') } {
                $_ProjAction = $a
                $remIdx++
                while ($remIdx -lt $script:_RemArgs.Count) {
                    $_ProjArgs.Add($script:_RemArgs[$remIdx])
                    $remIdx++
                }
                break
            }
            { $_ -in @('-h', '--help', '-Help') } {
                script:Show-AidUsage 'projects'
                script:Exit-Aid 0
                break
            }
            { $_ -in @('--local', '--shared', '--verbose') } {
                $_ProjArgs.Add($a)
                break
            }
            { $_ -match '^-' } {
                # Unknown flag: pass through to Invoke-AidProjects for rejection.
                $_ProjArgs.Add($a)
                break
            }
            default {
                [Console]::Error.WriteLine("ERROR: aid projects: unknown action: $a (expected: list, add, remove, help)")
                script:Exit-Aid 2
            }
        }
        $remIdx++
    }
    script:Invoke-AidProjects -Action $_ProjAction -RemArgs $_ProjArgs.ToArray()
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
$_AidDryRun      = $false
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
        '^(-NoPath|--no-path)$'   { break <# bootstrap-only; silently ignore here #> }
        '^(-DryRun|--dry-run)$'   { $_AidDryRun = $true; break }
        '^(-h|--help|-Help)$'     { script:Show-AidUsage $SUBCMD; script:Exit-Aid 0 }
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

# FR10: 'update' no longer accepts a per-tool positional (other than 'self' which
# was already consumed above).  Any non-flag positional on 'aid update' is a usage error.
if ($SUBCMD -eq 'update' -and $_AidToolArg) {
    [Console]::Error.WriteLine("ERROR: aid update: unexpected argument: '$_AidToolArg'")
    [Console]::Error.WriteLine("       'aid update' updates all installed tools -- no per-tool selection.")
    [Console]::Error.WriteLine("       Use 'aid update self' to update the CLI only.")
    [Console]::Error.WriteLine("       See 'aid update -h' for usage.")
    script:Exit-Aid 2
}

if (-not $_AidTarget) { $_AidTarget = '.' }

# Validate target directory.
if (-not (Test-Path $_AidTarget -PathType Container)) {
    script:Fail-Aid "target directory does not exist: $_AidTarget" 2
}
$_AidTarget = (Resolve-Path -LiteralPath $_AidTarget).Path

# ---- FR10: 'update' outside an AID repo -> update the CLI only (not offer-and-exit) ----
# Outside a repo: delegates to the CLI-only update path; no tool loop.
# Inside a repo: fall through to the full tool-update pass below.
# Test-AidIsProjectDir excludes the CLI state home from "is project" classification.
if ($SUBCMD -eq 'update') {
    if (-not (script:Test-AidIsProjectDir -Dir $_AidTarget)) {
        # FR10 outside-repo: update the CLI only; no tool loop.
        $updCliVer = ''
        $updVerFile = Join-Path $script:_AidCodeHome 'VERSION'
        if (Test-Path $updVerFile -PathType Leaf) {
            $updCliVer = (Get-Content -LiteralPath $updVerFile -Raw -ErrorAction SilentlyContinue).Trim()
        }
        # Check if already latest using cached update-check result (no network call).
        $updCacheFile = Join-Path $HOME (Join-Path '.aid' '.update-check')
        $updCachedLatest = ''
        if (Test-Path $updCacheFile -PathType Leaf) {
            $updLines = Get-Content -LiteralPath $updCacheFile -ErrorAction SilentlyContinue
            if ($updLines -and $updLines.Count -ge 2) { $updCachedLatest = $updLines[1].Trim() }
        }
        if ($updCliVer -and $updCachedLatest -and ($updCliVer -eq $updCachedLatest)) {
            Write-Host "CLI is current (v$updCliVer)"
            script:Exit-Aid 0
        }
        script:Invoke-AidUpdateSelfIfStale -FromBundle $_AidFromBundle
        script:Exit-Aid 0
    }
}

# C6': format gate for the update repo path (only when target is a real project;
# an add to a fresh repo with no .aid/ falls through normally).
if ($SUBCMD -eq 'update' -and (script:Test-AidIsProjectDir -Dir $_AidTarget)) {
    $gateRc = script:Invoke-AidFormatGate -Repo $_AidTarget
    if ($gateRc -ne 0) { script:Exit-Aid $gateRc }
}

# ---- Self-update-if-needed preamble (FF-3 / CLI-2 / task-079) --------------
# For 'update' inside an AID repo only (not 'add', not 'update self').
# Ensures the CLI is current before the per-repo tool-update runs.  WARN-not-fail.
if ($SUBCMD -eq 'update') {
    script:Invoke-AidUpdateSelfIfStale -FromBundle $_AidFromBundle
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
    switch ($SUBCMD) {
        { $_ -in @('add', 'update') } {
            # B-table (for 'add'): writability pre-check BEFORE any .aid/ is created.
            # Decision #3: never elevate .aid/ creation -- error if folder is not writable.
            if ($SUBCMD -eq 'add') {
                $_aidTargetWritable = $false
                $_wProbe = Join-Path $_AidTarget ('.aid-write-probe.' + [System.IO.Path]::GetRandomFileName())
                try { [System.IO.File]::WriteAllText($_wProbe, ''); Remove-Item -LiteralPath $_wProbe -Force -ErrorAction SilentlyContinue; $_aidTargetWritable = $true } catch {}
                if (-not $_aidTargetWritable) {
                    [Console]::Error.WriteLine("ERROR: aid: add: target directory is not writable: $_AidTarget")
                    [Console]::Error.WriteLine("ERROR: aid: add: AID will not create a root-owned .aid/ -- fix folder permissions and retry.")
                    script:Exit-Aid 1
                }
            }

            # ---------------------------------------------------------------------------
            # FR11: aid add version selection (same-version invariant).
            # First-tool  (no existing tools in manifest): install at the CLI version.
            # Additional-tool (manifest already has >=1 tool): install at the EXISTING
            # tools' version to keep the repo uniform.  add does NOT force a repo-wide
            # update.  -Version on add must apply to ALL tools or error (mixed-version
            # repo would result if the requested version differs from the existing one).
            # ---------------------------------------------------------------------------
            if ($SUBCMD -eq 'add') {
                $_fr11CliVer = ''
                $fr11VerFile = Join-Path $script:_AidCodeHome 'VERSION'
                if (Test-Path $fr11VerFile -PathType Leaf) {
                    $_fr11CliVer = (Get-Content -LiteralPath $fr11VerFile -Raw -ErrorAction SilentlyContinue).Trim()
                }
                $_fr11ExistingVer = ''
                if (Test-Path $_AidManifest -PathType Leaf) {
                    $fr11FirstTool = (Get-ManifestToolList -ManifestPath $_AidManifest | Select-Object -First 1)
                    if ($fr11FirstTool) {
                        $_fr11ExistingVer = Read-ManifestToolVersion -ManifestPath $_AidManifest -Tool $fr11FirstTool.Id
                    }
                }

                if ($_AidVersionArg) {
                    # -Version on add: validate it won't create a mixed-version repo.
                    if ($_fr11ExistingVer -and $_AidVersionArg -ne $_fr11ExistingVer) {
                        [Console]::Error.WriteLine("ERROR: aid add: -Version $_AidVersionArg would create a mixed-version repo.")
                        [Console]::Error.WriteLine("       Existing tools are at v$_fr11ExistingVer. Either:")
                        [Console]::Error.WriteLine("         - Omit -Version to install at the repo version (v$_fr11ExistingVer), or")
                        [Console]::Error.WriteLine("         - Run 'aid update -Version $_AidVersionArg' first to advance the whole repo.")
                        script:Exit-Aid 2
                    }
                    # -Version provided and no conflict: apply to all tools (passed through to staging).
                } elseif ($_fr11ExistingVer) {
                    # Additional-tool: pin staging to the existing repo version (not the CLI version).
                    $_AidVersionArg = $_fr11ExistingVer
                    # Skew notice when CLI is ahead of the repo version.
                    if ($_fr11CliVer) {
                        $fr11PartsA = $_fr11ExistingVer -split '\.'
                        $fr11PartsB = $_fr11CliVer      -split '\.'
                        $fr11IsLt   = $false
                        for ($fr11i = 0; $fr11i -lt 3; $fr11i++) {
                            $fr11rA = if ($fr11i -lt $fr11PartsA.Count) { $fr11PartsA[$fr11i] } else { '0' }
                            $fr11rB = if ($fr11i -lt $fr11PartsB.Count) { $fr11PartsB[$fr11i] } else { '0' }
                            if ($fr11rA -match '^(\d+)') { $fr11vA = [int]$Matches[1] } else { $fr11vA = 0 }
                            if ($fr11rB -match '^(\d+)') { $fr11vB = [int]$Matches[1] } else { $fr11vB = 0 }
                            if ($fr11vA -lt $fr11vB) { $fr11IsLt = $true; break }
                            if ($fr11vA -gt $fr11vB) { break }
                        }
                        if ($fr11IsLt) {
                            Write-Host "repo is at v$_fr11ExistingVer; new tool(s) installed at v$_fr11ExistingVer to keep the repo uniform. Run 'aid update' to advance all tools to v$_fr11CliVer."
                        }
                    }
                } else {
                    # First-tool: pin to CLI version (bundle supplies its own version; skip if so).
                    if (-not $_AidFromBundle -and $_fr11CliVer) {
                        $_AidVersionArg = $_fr11CliVer
                    }
                }
            }

            # C-table (for 'update'): register-on-encounter.
            # The missing-.aid/ case was already intercepted above (pre-resolve-tools).
            if ($SUBCMD -eq 'update') {
                script:Invoke-AidCwdClassify -Target $_AidTarget
            }

            # ---------------------------------------------------------------------------
            # FR10 Stage-all-first atomicity (task-009):
            # PHASE 1: Stage ALL tools (resolve version, fetch, checksum-verify, extract
            #          to temp) BEFORE any destination write.  A failure here aborts with
            #          zero destination mutation.
            # ---------------------------------------------------------------------------
            $stageMap     = [System.Collections.Generic.Dictionary[string,string]]::new()
            $stageVersion = ''

            foreach ($t in $_AidTools) {
                script:Prepare-AidToolStaging -Tool $t -Version $_AidVersionArg -Bundle $_AidFromBundle
                $stageMap[$t] = $script:_DispStagingDir
                if (-not $stageVersion) { $stageVersion = $script:_DispResolvedVersion }
            }

            # ---------------------------------------------------------------------------
            # FR10 -DryRun: print the plan and exit with no writes.
            # ---------------------------------------------------------------------------
            if ($_AidDryRun) {
                Write-Host "--- aid $SUBCMD -DryRun plan (no writes) ---"
                Write-Host "Target: $_AidTarget"
                Write-Host "Version: $(if ($stageVersion) { $stageVersion } else { '<current>' })"
                foreach ($t in $_AidTools) {
                    Write-Host ""
                    Write-Host "Tool: $t"
                    $dryStaging = $stageMap[$t]
                    $dryFiles = @(Get-ChildItem -LiteralPath $dryStaging -Recurse -File -ErrorAction SilentlyContinue |
                                  Sort-Object FullName)
                    foreach ($df in $dryFiles) {
                        $rel = $df.FullName.Substring($dryStaging.Length).TrimStart([char]'\', [char]'/')
                        Write-Host "  copy: $rel -> $_AidTarget"
                    }
                    # List files that would be MOVED TO TRASH by the retired-root migration sweep
                    # (marker 1: aid-* prefix; marker 2: inside an aid\ subtree).
                    # Uses ListOnly=$true mode of Invoke-MigrateRetiredLayout (no writes).
                    # The function emits paths via Write-Output; capture then display.
                    $dryRemovePaths = @(Invoke-MigrateRetiredLayout -Target $_AidTarget -Tool $t -ListOnly $true)
                    if ($dryRemovePaths.Count -gt 0) {
                        Write-Host "  Would MOVE TO TRASH (retired-layout migration):"
                        foreach ($rp in $dryRemovePaths) {
                            Write-Host "  move to trash: $rp"
                        }
                    }
                }
                Write-Host ""
                Write-Host "--- end dry-run plan ---"
                script:Exit-Aid 0
            }

            # ---------------------------------------------------------------------------
            # PHASE 2: Commit all staged tools.
            # If any commit fails, exit non-zero with a re-run-to-heal message.
            # aid update is idempotent: re-running drives every tool to the target version.
            # ---------------------------------------------------------------------------
            foreach ($t in $_AidTools) {
                Write-Host ""
                Write-Host "Installing $t v$stageVersion -> $_AidTarget"
                $rc = Install-AidTool -StagingDir $stageMap[$t] -Tool $t -Target $_AidTarget `
                         -Version $stageVersion -Force ([bool]$_AidForce) `
                         -AidVerbose $script:_AidVerbose
                if ($rc -ne 0) {
                    Write-Host ""
                    [Console]::Error.WriteLine("ERROR: aid $SUBCMD failed mid-commit for tool '$t' (rc=$rc).")
                    [Console]::Error.WriteLine("       The repo may be at mixed versions. Re-run 'aid update' to heal.")
                    script:Exit-Aid $rc
                }
            }

            Write-Host ""
            Write-Host "Done. AID $stageVersion installed into: $_AidTarget"

            # B-table (for 'add'): tier-aware registration after successful install.
            # Decision #3 (unwritable) already handled above with error+abort.
            if ($SUBCMD -eq 'add') {
                # FR7: deterministic, non-interactive tier selection via Resolve-AidTier.
                $_btabTier = script:Resolve-AidTier -CanonPath $_AidTarget
                script:Registry-Register -Repo $_AidTarget -Tier $_btabTier
            } else {
                # 'update': C-table register-on-encounter already ran above.
                # The post-install register is idempotent; route via user tier.
                script:Registry-Register -Repo $_AidTarget -Tier 'user'
            }

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
