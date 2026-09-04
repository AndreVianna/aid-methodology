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
#   aid --version | -V               Print the CLI version and exit (same as 'aid version')
#   aid version                      Print the CLI version
#   aid status                       Show AID state of the current project
#   aid add <tool>[,...]             Add tool(s) to the current project
#   aid update [self|all]            Update to latest; inside repo = CLI + all tools; 'self' = CLI only;
#                                    'all' = bulk-update every registered project (see 'aid update -h')
#   aid remove [<tool>... | self]    Remove; no arg = ALL AID from project; 'self' = the aid CLI
#   aid projects [list|add|remove|scan|help] [path|N] [--local|--shared] [--verbose]
#                                    List (numbered from 1), register, unregister, or scan;
#                                    remove accepts a list number (<N>) or a <path>
#                                    scan: 'aid projects scan -h' for its own flags
#   aid <command> -h | --help        Per-command help
#
# Flags (shared across subcommands where applicable):
#   -FromBundle <path>   Offline install from a pre-downloaded tarball / dir.
#   -Version <v>         (add/remove/update only) Pin to a specific release version (e.g. 0.7.0).
#   -Force               Overwrite differing files / skip confirmation prompts.
#   -Target <dir>        Project root (default: current directory).
#   -Verbose             Print per-file detail (default: concise summary).
#   -NoPath              (bootstrap / update self only) Skip PATH wiring.
#
# Top-level-only flag (bare, no value, handled before subcommand dispatch):
#   --version | -V         Print the CLI version and exit 0. Distinct from the
#                          subcommand -Version <v> pin flag above.

# ---------------------------------------------------------------------------
# Bootstrap URL - single place to update when the branch merges to master.
# Override with $env:AID_INSTALL_URL for tests.
# ---------------------------------------------------------------------------

# Enable TLS 1.2 for HTTPS. Windows PowerShell 5.1 (.NET Framework) can default to
# SSL3/TLS1.0, which GitHub/npm/pypi reject -> downloads fail. Harmless on PS7/.NET Core.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

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
# NOTE (work-007 C6): the install-time settings seed also stamps this value. On a
# bump, update ALL carriers together: this line, bin/aid AID_SUPPORTED_FORMAT, and
# lib/AidInstallCore.psm1 $script:_AidSupportedFormat (the PS seed's source).
# ---------------------------------------------------------------------------
# format 2 (was 1): eliminated the per-repo .aid/dashboard/ folder -- home.html is now
# served from the CLI, and kb.html moved to .aid/knowledge/kb.html (aid migrate relocates).
# format 3 (was 2): settings.yml flattened -- top-level name/description/type/
# source_control/minimum_grade/heartbeat_interval + a knowledge: block; the installed
# tools + AID version now live only in the manifest (.aid/.aid-manifest.json).
# format 4 (was 3): work-tree state files are YAML STATE.yml, not markdown
# STATE.md -- every .aid/works/*/STATE.md (and, on the full layout, every
# deliveries/*/STATE.md and deliveries/*/tasks/*/STATE.md) is rewritten in place
# and the .md deleted. Performed by the STATE.md -> STATE.yml FORMAT-4
# CONVERSION step in _aid_migrate_repo (task-008 / SPEC.md SS L-6 step 2).
Set-Variable -Name AidSupportedFormat -Value 4 -Option Constant -Scope Script

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
            Write-Host 'aid update all [-Version <v>] [-DryRun] [-Force]'
            Write-Host '  Update to latest.'
            Write-Host '  Outside an AID project: updates the CLI only (no-op if already latest).'
            Write-Host '  Inside an AID project: updates the CLI first, then ALL installed tools to one version.'
            Write-Host '  No per-tool selection -- any tool positional is an error (use "self" or "all" only).'
            Write-Host '  self: COMPLETELY update the aid CLI, channel-aware:'
            Write-Host '        npm -> npm i -g | pypi -> pipx upgrade | curl -> re-bootstrap install.ps1.'
            Write-Host '        On Windows, elevation is the caller''s responsibility (no sudo).'
            Write-Host '  all: bulk-update EVERY registered project (see "aid projects list") to one'
            Write-Host '        version -- downloads the tool package(s) once and applies the shared'
            Write-Host '        cache to each project via the existing -FromBundle path; continues past'
            Write-Host '        a per-project failure and prints an end-of-run summary. Does not accept'
            Write-Host '        -Target (the registry supplies the targets).'
            Write-Host '  -Version <v>:        pin ALL tools (and CLI) to version v.'
            Write-Host '  -FromBundle <path>:  install from a local artifact instead of @latest'
            Write-Host '        (npm .tgz | pypi .whl | curl release-staging dir with install.ps1).'
            Write-Host '  -DryRun: print the full plan (tools updated, files copied, paths pruned) and exit.'
        }
        'version' {
            Write-Host 'aid version'
            Write-Host '  Print the installed aid CLI version and exit 0.'
        }
        'chat' {
            Write-Host 'aid chat register --name <n> [--tool <t>]     register this session'
            Write-Host 'aid chat open    --name <n> --channel <c>     open a channel and join it'
            Write-Host 'aid chat join    --name <n> --channel <c>     join an open channel'
            Write-Host 'aid chat leave   --name <n>                   leave; closes it if you were last'
            Write-Host 'aid chat list    --name <n>                   the open channels this hub knows'
            Write-Host 'aid chat send    --name <n> --body <text> [--key <k>] [--whisper-to <m>] [--mention <m>]'
            Write-Host '                 [--reply-to <key>] [--correlation-id <id>]'
            Write-Host 'aid chat inbox   --name <n> [--cursor <c>]    messages after your position'
            Write-Host 'aid chat ack     --name <n> --cursor <c>      advance your acknowledged position'
            Write-Host 'aid chat roster  --name <n>                   who else is on this hub, and who is free'
            Write-Host 'aid chat connect --name <n> --target <t>      pull one named agent into YOUR channel'
            Write-Host 'aid chat subscribe --name <n> [--host-timeout <s>] [--follow]'
            Write-Host '                 hold ONE wait for an arriving message or connect outcome.'
            Write-Host '                 --host-timeout <s> MUST be the same number as the host stop'
            Write-Host '                 hook timeout you configured; the block is'
            Write-Host '                 min(long-poll default, s - margin). Omit it and the block'
            Write-Host '                 falls back to a short value rather than inheriting any'
            Write-Host '                 platform default. --follow re-arms instead of returning.'
            Write-Host '                 Spends no model tokens: it blocks in a process, not a prompt.'
            Write-Host 'aid chat hook    --tool <claude-code|cursor> [--timeout <s>] [--check]'
            Write-Host '                 print the stop-hook block to paste, with the node path, install'
            Write-Host '                 path and both timeout numbers filled in from this machine; or'
            Write-Host '                 --check to read an installed one back and report what is wrong.'
            Write-Host '                 It WRITES NOTHING: AID writes no host tool configuration.'
            Write-Host 'aid chat show                                  machines, sessions, channels, members,'
            Write-Host '                 per-member unread depth and idle time (operator)'
            Write-Host 'aid chat audit   [--limit <n>]                  what happened, never what was said:'
            Write-Host '                 a whisper appears with its parties and no body (operator)'
            Write-Host 'aid chat evict   --name <n>                     remove a session from its channel (operator)'
            Write-Host 'aid chat retention [--set <key>=<value>]        show or set retention policy (operator)'
            Write-Host 'aid chat peers   [--add|--remove --machine <host[:port]>] [--discover]'
            Write-Host '                 list, add or remove peer hubs (operator). Naming an address is'
            Write-Host '                 the GUARANTEED path and needs no network feature; --discover is'
            Write-Host '                 best-effort broadcast on top and may legitimately find nobody.'
            Write-Host 'aid chat reap    --name <n> | --name --all     give a session up for gone (operator)'
            Write-Host '  --name may be omitted when AID_CHAT_SESSION is set.'
            Write-Host '  --cursor on inbox RE-READS from that point and moves neither position.'
            Write-Host '  Exit 14 means the node refused a well-formed request; the reason is the first'
            Write-Host '  word on stderr (solo_channel, no_channel, already_in_channel, overflow, ...).'
            Write-Host ''
            Write-Host 'aid chat node start [--port <n>]'
            Write-Host 'aid chat node stop'
            Write-Host 'aid chat node status'
            Write-Host '  Start, stop or query the local agent chat node (the hub).'
            Write-Host '  The node serves every session on this machine, whichever tool hosts each one.'
            Write-Host '  --port <n>  listen port on 127.0.0.1 (default 8812; 0 picks a free port).'
            Write-Host '  Requires a Node runtime (>= 22.13.0); exits 9 with an explicit message if absent.'
            Write-Host '  start on an already-running node exits 8 and changes nothing.'
        }
        'dashboard' {
            Write-Host 'aid dashboard start <node|python> [--remote] [--allow-writes] [--port <n>]'
            Write-Host 'aid dashboard stop'
            Write-Host '  Start or stop the machine-level pipeline dashboard (serves all registered projects).'
            Write-Host '  <node|python>  select the server runtime to launch.'
            Write-Host '  --remote       also expose it to authorized users over a private channel (never public);'
            Write-Host '                 fails clearly if that mechanism is unavailable -- never binds publicly.'
            Write-Host '  --allow-writes opt in to interactive writes. On loopback writes are always enabled'
            Write-Host '                 (this flag is then accepted but redundant, no error); under --remote the'
            Write-Host '                 dashboard is read-only unless this flag is also given.'
            Write-Host '  --port <n>     listen port on 127.0.0.1 (default 8787).'
            Write-Host "  The dashboard binds to 127.0.0.1 only. 'stop' is idempotent and also tears down --remote."
            Write-Host '  Works from any directory (not tied to the current project).'
        }
        'projects' {
            Write-Host 'aid projects [list] [--local|--shared] [--verbose]'
            Write-Host 'aid projects add  [<path>] [--local|--shared]'
            Write-Host 'aid projects remove [<path>|<N>]'
            Write-Host 'aid projects scan [--path <folder>|--all] [--dry-run] [--depth <n>]'
            Write-Host '                  [--include-network] [--include-removable] [--local|--shared] [--verbose]'
            Write-Host '  List, register, unregister, or scan for AID projects in the registry.'
            Write-Host '  list (default): show all registered projects, numbered from 1, with state,'
            Write-Host '    tools, and tier.'
            Write-Host '    The current directory is marked with "*" in the leading marker column.'
            Write-Host '    Unregistered cwd with .aid/ present is shown as a footnote.'
            Write-Host '  add [path=cwd]: register a project. If the folder is not yet an AID project,'
            Write-Host '    it is initialized as a bare project (.aid/ with no tools installed).'
            Write-Host '    Idempotent.  Prints the tier written.'
            Write-Host '  remove [path=cwd|<N>]: unregister a project from the registry; no files removed.'
            Write-Host "    <N> (all-digits) targets the Nth row from 'aid projects list'; N < 1 or"
            Write-Host '    N greater than the registered count errors to stderr with exit 2.  A <path>'
            Write-Host '    that does not resolve to a currently-registered project now errors (exit 2)'
            Write-Host '    instead of the prior idempotent no-op.'
            Write-Host '  scan: crawl the filesystem for folders containing a .aid/ and register each'
            Write-Host '    (register-only -- never installs/updates/migrates; never writes inside a'
            Write-Host "    discovered project's .aid/). Reports each discovered project's version."
            Write-Host '    Scope (default: home; the ONLY mode that enumerates drives is --all):'
            Write-Host '      (no flag)         scan the user HOME directory ($HOME / %USERPROFILE%)'
            Write-Host "      --path <folder>   scan only that folder's subtree (not a directory: exit 2)"
            Write-Host '      --all             scan the whole machine: Windows local FIXED drives'
            Write-Host '                        (network/removable excluded by default); Unix from /'
            Write-Host '    --path and --all are mutually exclusive (exit 2).'
            Write-Host '    --dry-run          preview; write nothing; exit 0'
            Write-Host '    --depth <n>        cap recursion at <n> levels below each root; <n> must be a'
            Write-Host '                       non-negative integer (non-integer or negative: exit 2)'
            Write-Host '    --include-network    (--all only) include network drives (Windows); Unix:'
            Write-Host '                          accepted but inert (drive-type filtering is Windows-only)'
            Write-Host '    --include-removable  (--all only) include removable drives (Windows); Unix:'
            Write-Host '                          accepted but inert (drive-type filtering is Windows-only)'
            Write-Host '    --include-network/--include-removable without --all: exit 2'
            Write-Host "    --local/--shared force the tier exactly as in 'aid projects add'; scan"
            Write-Host '      FORCES the user tier by default so a bulk scan never elevates privileges.'
            Write-Host '  --local   force user tier for add/scan'
            Write-Host '  --shared  force shared tier for add/scan'
            Write-Host '  --verbose print extra detail'
        }
        default {
            Write-Host 'aid - AID CLI'
            Write-Host ''
            Write-Host 'Usage:'
            Write-Host '  aid                              Show the dashboard'
            Write-Host '  aid -h | --help                  Show this help'
            Write-Host '  aid --version | -V               Print the CLI version and exit (same as "aid version")'
            Write-Host '  aid version                      Print the CLI version'
            Write-Host '  aid status                       Show AID state of the current project'
            Write-Host '  aid add <tool>[,...]             Add tool(s) to the current project'
            Write-Host '  aid update [self|all]            Update to latest; inside a project = all tools;'
            Write-Host '                                    "all" bulk-updates every registered project'
            Write-Host '  aid remove [<tool>... | self]    Remove; no arg = ALL AID from project'
            Write-Host '  aid dashboard start|stop ...     Start/stop the local dashboard'
            Write-Host '  aid projects [list|add|remove|scan]  List/register/unregister/scan AID projects'
            Write-Host "  aid <command> -h | --help        Per-command help"
            Write-Host ''
            Write-Host 'Flags: -FromBundle, -Version <v> (add/remove/update only -- pins a release), -Force, -DryRun, -Target, -Verbose'
            Write-Host 'Top-level --version / -V takes NO value and prints the CLI version (distinct from the -Version <v> pin above).'
            Write-Host "Run 'aid <command> -h' for details."
        }
    }
}

# ---------------------------------------------------------------------------
# Version helper: single-source the CLI version via the VERSION-file read.
# Shared by the 'aid version' subcommand and the top-level bare --version/-V
# flag -- do NOT duplicate this literal read path elsewhere.
# ---------------------------------------------------------------------------
function script:Show-AidVersion {
    $versionFile = Join-Path $script:_AidCodeHome 'VERSION'
    if (Test-Path $versionFile -PathType Leaf) {
        Write-Host (Get-Content -LiteralPath $versionFile -Raw).Trim()
    } else {
        Write-Host "unknown (VERSION file not found at $versionFile)"
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
# Invoke-AidUpdateAll  (work-001-update-all / task-001)
# Bulk-update every registered AID project to one version from a single shared
# download.  Parent driver: resolves one version, downloads once per distinct
# tool into a transient cache, and applies it to each registered project via a
# per-project CHILD 'aid update -Target <repo> -FromBundle <cache>' process
# invocation (continue-on-error).  Reuses, does not reimplement:
# Get-RegistryRawUnion, Get-ManifestToolList, Resolve-AidVersion/Fetch-Tarball,
# Invoke-AidUpdateSelfIfStale, and the entire single-project apply path (its
# -FromBundle branch).  Mirror of bash _cmd_update_all.  See SPEC.md Feature Flow.
#
# -RemArgs: the tokens following the 'all' reserved word (-Version/-DryRun/-Force).
# Returns: 0 all-success or -DryRun; 1 if any project failed; 2 usage error;
# 3 version-resolution failure.
# ---------------------------------------------------------------------------
function script:Invoke-AidUpdateAll {
    param([string[]]$RemArgs = @())

    $uaVersionArg = ''
    $uaDryRun     = $false
    $uaForce      = $false

    $i = 0
    while ($i -lt $RemArgs.Count) {
        $a = $RemArgs[$i]
        switch -Regex ($a) {
            '^(-Version|--version)$' {
                $i++
                if ($i -ge $RemArgs.Count) { script:Fail-Aid "-Version requires a value" 2 }
                $uaVersionArg = $RemArgs[$i]
                break
            }
            '^(-DryRun|--dry-run)$' { $uaDryRun = $true; break }
            '^(-Force|--force|-y)$' { $uaForce  = $true; break }
            '^(-Target|--target)$' {
                script:Fail-Aid "'aid update all' does not accept -Target; it updates every registered project (see 'aid projects list')" 2
            }
            '^(-h|--help|-Help)$' {
                script:Show-AidUsage 'update'
                return 0
            }
            '^-' {
                script:Fail-Aid "unknown flag for 'update all': $a" 2
            }
            default {
                script:Fail-Aid "unexpected argument for 'update all': $a" 2
            }
        }
        $i++
    }

    # Resolve the single run version once (decision D7 / FR7 version) -- governs
    # the whole run.  Strip a leading 'v' from an explicit pin, same as the
    # single-project path.
    $uaRunVersion = if ($uaVersionArg) { $uaVersionArg -replace '^v', '' } else { '' }
    if (-not $uaRunVersion) {
        $uaRunVersion = Resolve-AidVersion
        if (-not $uaRunVersion) { return 3 }
    }

    # Self-update preamble EXACTLY once, before enumeration (decision/FR8).
    # Skipped entirely under -DryRun (a self-update is a write; dry-run makes none).
    if (-not $uaDryRun) {
        script:Invoke-AidUpdateSelfIfStale -FromBundle ''
    }

    # Per-run transient cache (mirrors the single-project $_AidStagingBase pattern).
    $uaCache = Join-Path ([System.IO.Path]::GetTempPath()) ('aid-update-all-' + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $uaCache -Force | Out-Null

    try {
        # Enumerate every registered project -- the exact source 'aid projects list'
        # reads (decision D3 / FR2 / AC2).
        $uaRepos = @(script:Get-RegistryRawUnion)

        Write-Host "aid update all: $($uaRepos.Count) registered project(s), target version $uaRunVersion"

        $uaFetchFailed = @{}   # tool -> $true once its download has failed this run
        $uaUpdated = [System.Collections.Generic.List[string]]::new()
        $uaSkipped = [System.Collections.Generic.List[string]]::new()
        $uaFailed  = [System.Collections.Generic.List[string]]::new()

        $uaHostExe = (Get-Process -Id $PID).Path

        foreach ($uaRepo in $uaRepos) {
            if (-not $uaRepo) { continue }

            # Availability check (AC7): skip (non-fatal) a project whose .aid/ is absent.
            $uaAidDir = Join-Path $uaRepo '.aid'
            if (-not (Test-Path $uaAidDir -PathType Container)) {
                $uaSkipped.Add($uaRepo)
                Write-Host "SKIP: $uaRepo (.aid/ not found)"
                continue
            }

            $uaManifest = Join-Path $uaAidDir '.aid-manifest.json'
            $uaTools = @(Get-ManifestToolList -ManifestPath $uaManifest | ForEach-Object { $_.Id })

            # Populate the shared cache download-once per distinct tool (AC1).
            $uaRepoFetchFailed = $false
            foreach ($uaTool in $uaTools) {
                if ($uaFetchFailed.ContainsKey($uaTool)) {
                    $uaRepoFetchFailed = $true
                    continue
                }
                $uaTarball = Join-Path $uaCache "aid-$uaTool-v$uaRunVersion.tar.gz"
                if (-not (Test-Path $uaTarball -PathType Leaf)) {
                    if (-not (Fetch-Tarball -Tool $uaTool -Version $uaRunVersion -DestDir $uaCache)) {
                        [Console]::Error.WriteLine("ERROR: aid update all: failed to download $uaTool v$uaRunVersion (continuing)")
                        $uaFetchFailed[$uaTool] = $true
                        $uaRepoFetchFailed = $true
                    }
                }
            }

            if ($uaRepoFetchFailed) {
                $uaFailed.Add($uaRepo)
                Write-Host "FAILED: $uaRepo (tool download failed)"
                continue
            }

            # Apply via the existing -FromBundle branch, through a CHILD 'aid update'
            # process (FR4) -- no new fetch/install mechanism.
            $uaChildArgs = @('-NoProfile', '-File', $script:_AidSelfPath, 'update', '-Target', $uaRepo, '-FromBundle', $uaCache)
            if ($uaForce)  { $uaChildArgs += '-Force' }
            if ($uaDryRun) { $uaChildArgs += '-DryRun' }

            Write-Host ""
            Write-Host "=== $uaRepo ==="
            # Route the child's stdout to the host (visible) rather than leaving it in
            # THIS function's success stream. The caller captures our return value
            # ($uaRc = Invoke-AidUpdateAll ...), so any success-stream output -- including
            # the child process's stdout -- is collected into $uaRc, making the function
            # return an Object[] instead of the intended scalar int exit code. Exit-Aid
            # then fails to bind [int]$Code ("Cannot convert System.Object[] to Int32").
            # Mirrors the bash twin, where the child inherits stdout and only the exit
            # status ($?) is the "return". Write-Host output is unaffected either way.
            & $uaHostExe @uaChildArgs | Out-Host
            $uaChildRc = $LASTEXITCODE

            # Record outcome (FR5/FR6): 0 -> updated; non-zero -> failed. Continue
            # regardless (decision D4 -- continue-on-error).
            if ($uaChildRc -eq 0) {
                $uaUpdated.Add($uaRepo)
            } else {
                $uaFailed.Add($uaRepo)
                Write-Host "FAILED: $uaRepo (exit $uaChildRc)"
            }
        }

        # End-of-run summary (decision D4 / AC3, AC5).
        Write-Host ""
        Write-Host "--- aid update all summary (version $uaRunVersion) ---"
        foreach ($r in $uaUpdated) { Write-Host "  updated: $r" }
        foreach ($r in $uaSkipped) { Write-Host "  skipped: $r (.aid/ not found)" }
        foreach ($r in $uaFailed)  { Write-Host "  failed: $r" }
        Write-Host "$($uaUpdated.Count) updated, $($uaSkipped.Count) skipped, $($uaFailed.Count) failed"

        if ($uaFailed.Count -gt 0) { return 1 }
        return 0
    } finally {
        if (Test-Path $uaCache -PathType Container) {
            Remove-Item -LiteralPath $uaCache -Recurse -Force -ErrorAction SilentlyContinue
        }
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
    [Console]::Error.WriteLine("Note: with --allow-writes, any granted identity can also modify this project's state.")
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
    $dcAllowWrites = $false
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
            { $_ -in @('-AllowWrites', '--allow-writes') } {
                if ($verb -eq 'stop') {
                    [Console]::Error.WriteLine("ERROR: aid: dashboard: unknown flag: $a")
                    script:Exit-Aid 2
                }
                $dcAllowWrites = $true
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
        script:Invoke-DcStart -Runtime $dcRuntime -Port $dcPort -Remote $dcRemote -AllowWrites $dcAllowWrites -Verbose $dcVerbose
    } else {
        script:Invoke-DcStop -Verbose $dcVerbose
    }
}

# ---------------------------------------------------------------------------
# Cross-platform process reaping for the dashboard server (start/stop).
# Mirror of the Bash launcher's _dc_is_windows / _dc_reap_port. On Windows the
# server is reached only through the python3.bat / node shim, so the recorded
# pid is the WRAPPER, not the detached native python.exe/node.exe server, and a
# plain Stop-Process (no tree) leaves it orphaned and still bound to the port --
# an old orphan then keeps serving stale in-memory code (pipelines look empty).
# Kill the whole native tree (taskkill /F /T) and, as a safety net, whatever
# still listens on the recorded port.
# 5.1-safe: the PS Core platform auto-vars are absent in Windows PowerShell 5.1; use $env:OS.
# ---------------------------------------------------------------------------
function script:Test-AidWindows {
    return ($env:OS -eq 'Windows_NT')
}

# Windows-only safety net: kill any process still LISTENING on 127.0.0.1:<Port>.
# Catches an older orphan whose wrapper pid had already exited. No-op on POSIX
# (the Stop-Process path in Invoke-DcStop already suffices there).
function script:Invoke-DcReapPort {
    param([int]$Port, [bool]$Verbose)
    if ($Port -le 0) { return }
    if (-not (script:Test-AidWindows)) { return }
    $lines = & netstat.exe -ano -p tcp 2>$null
    $seen = @{}
    foreach ($line in $lines) {
        if ($line -match "127\.0\.0\.1:$Port\s+\S+\s+LISTENING\s+(\d+)") {
            $rp = $matches[1]
            if ($rp -and $rp -ne '0' -and -not $seen.ContainsKey($rp)) {
                $seen[$rp] = $true
                if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: reaping orphaned server on :$Port (pid $rp)") }
                & taskkill.exe /F /T /PID $rp 2>$null | Out-Null
            }
        }
    }
}

function script:Invoke-DcStart {
    param([string]$Runtime, [int]$Port, [bool]$Remote, [bool]$AllowWrites, [bool]$Verbose)

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

    # Fail-safe write gate (Q1/NFR2/C3/AC8, feature-001 task-001):
    #   write_enabled = (loopback) OR (--remote AND --allow-writes).
    # Loopback is always write-enabled; --remote alone is read-only; --remote
    # --allow-writes is write-enabled; --allow-writes on loopback is accepted and
    # redundant (no error). The server only learns write_enabled via the spawn argv
    # below -- it is never read from request/config/env (SEC-1 posture unaffected).
    $writeEnabled = (-not $Remote) -or ($Remote -and $AllowWrites)

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
    if ($writeEnabled) { $spawnArgs += '--allow-writes' }
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
    $existingPort = 0
    $logFile     = ''
    if ($pidContent -match '"pid"\s*:\s*(\d+)') { $existingPid = [int]$matches[1] }
    if ($pidContent -match '"port"\s*:\s*(\d+)') { $existingPort = [int]$matches[1] }
    if ($pidContent -match '"logfile"\s*:\s*"([^"]+)"') { $logFile = $matches[1] }

    $procAlive = $false
    if ($existingPid -gt 0) {
        try { $null = Get-Process -Id $existingPid -ErrorAction Stop; $procAlive = $true } catch {}
    }

    if (-not $procAlive) {
        if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: record exists but pid $existingPid is dead; cleaning up.") }
        # Windows: the recorded pid is the cmd/.bat wrapper; even after it exits the
        # detached native server may still be alive and bound to the port. Reap it
        # by port before dropping the record.
        script:Invoke-DcReapPort -Port $existingPort -Verbose $Verbose
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

    # Step 5: terminate the server.
    if (script:Test-AidWindows) {
        # Windows: the recorded pid is the cmd/python3.bat (or node) WRAPPER; the
        # real server is a detached native python.exe/node.exe child that a plain
        # Stop-Process (no tree) cannot reach. Kill the whole native process tree
        # so the server does not survive as an orphan still bound to the port.
        if ($Verbose) { [Console]::Error.WriteLine("aid: dashboard: killing native process tree of $existingPid") }
        & taskkill.exe /F /T /PID $existingPid 2>$null | Out-Null
    } else {
        # POSIX: terminate the process cleanly.
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
    }

    # Safety net (Windows): if a server is still bound to the recorded port (an
    # older orphan whose wrapper had already exited), reap whatever still listens
    # on that port. No-op on POSIX.
    script:Invoke-DcReapPort -Port $existingPort -Verbose $Verbose

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
#                  (key "aid_version"). Every AID project has a manifest, so it
#                  is the single version source; a malformed value -> untracked.
# Never errors; always returns normally.
# Mirror of bash _aid_project_state.
function script:Get-AidProjectState {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Container)) { return 'missing' }
    $aidDir = Join-Path $Path '.aid'
    if (-not (Test-Path $aidDir -PathType Container)) { return 'no-aid' }
    $manifest = Join-Path $aidDir '.aid-manifest.json'
    if (Test-Path $manifest -PathType Leaf) {
        $content = Get-Content -LiteralPath $manifest -Raw -Encoding utf8 -ErrorAction SilentlyContinue
        if ($content -and $content -match '"aid_version"\s*:\s*"([^"]*)"') {
            $raw = $Matches[1]
            if ($raw -match '([0-9]+\.[0-9]+\.[0-9]+[^\s]*)') {
                return $Matches[1]
            }
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
    $manifest = Join-Path (Join-Path $Path '.aid') '.aid-manifest.json'
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
    $userReg    = Join-Path (Join-Path $HOME '.aid') 'registry.yml'

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

    # Pre-compute each project's state (version string) and size the STATE column to
    # the widest value (floor: the historical width of 10) so a long version -- e.g.
    # a pre-release "X.Y.Z-beta.N" -- never overflows a fixed field and shifts the
    # TOOLS/TIER columns out of alignment with the header. Mirror of bash _cmd_projects_list.
    $states = @($paths | ForEach-Object { script:Get-AidProjectState -Path $_ })
    $stateW = 10
    foreach ($s in $states) { if ($s.Length -gt $stateW) { $stateW = $s.Length } }
    $fmt = '{0,3}  {1,-2}  {2,-45}  {3,-' + $stateW + '}  {4,-20}  {5}'

    # Column header.
    Write-Host ($fmt -f '#', ' ', 'PATH', 'STATE', 'TOOLS', 'TIER')
    Write-Host ($fmt -f '---', '--', '----', '-----', '-----', '----')

    $cwdRegistered = $false
    $num = 0
    $idx = 0
    foreach ($entry in $paths) {
        $num++
        $state  = $states[$idx]
        $idx++
        $tools  = script:Get-AidProjectTools  -Path $entry
        $tier   = script:Get-WhichTierHolds   -Path $entry
        $marker = '  '
        if ($entry -eq $cwd) {
            $marker = '* '
            $cwdRegistered = $true
        }
        $toolsDisplay = if ($tools) { $tools } else { '-' }
        Write-Host ($fmt -f $num, $marker, $entry, $state, $toolsDisplay, $tier)
        if ($Verbose) {
            $regSrc = if ($tier -eq 'shared' -and
                ([System.IO.Path]::GetFullPath($script:_AidStateHome) -ne [System.IO.Path]::GetFullPath((Join-Path $HOME '.aid')))) {
                Join-Path $script:_AidStateHome 'registry.yml'
            } else {
                Join-Path (Join-Path $HOME '.aid') 'registry.yml'
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

# Invoke-AidScaffoldBareProject <Canon>
# Initialize a bare, tool-less AID project at <Canon> (mirror of bash
# _aid_scaffold_bare_project): create the .aid/ tree and a minimal settings.yml
# (format_version + aid_version + empty tools). Never clobbers an existing
# settings.yml. Written LF-only, no BOM -- byte-identical to the bash writer.
function script:Invoke-AidScaffoldBareProject {
    param([string]$Canon)
    $name = Split-Path $Canon -Leaf
    $fmt  = $script:AidSupportedFormat
    $ver  = ''
    $verFile = Join-Path $script:_AidCodeHome 'VERSION'
    if (Test-Path $verFile -PathType Leaf) {
        $ver = ((Get-Content -LiteralPath $verFile -Raw -Encoding utf8 -ErrorAction SilentlyContinue) -replace '\s','')
    }

    $sc = if (Test-Path (Join-Path $Canon '.git')) { 'git' } else { 'none' }

    $aidDir = Join-Path $Canon '.aid'
    foreach ($sub in @('connectors','knowledge','works')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $aidDir $sub) -ErrorAction SilentlyContinue | Out-Null
    }

    # Flat, user-owned settings.yml (the AID version + installed tools live in
    # the manifest, not here). format_version stamps the .aid/ layout.
    $settings = Join-Path $aidDir 'settings.yml'
    if (-not (Test-Path $settings -PathType Leaf)) {
        $lines = [System.Collections.Generic.List[string]]::new()
        [void]$lines.Add("format_version: $fmt")
        [void]$lines.Add('# .aid/settings.yml - AID pipeline configuration (user-owned project settings).')
        [void]$lines.Add('# Initialized by `aid projects add` for a tool-less project (no host tool yet).')
        [void]$lines.Add('# Run /aid-config to configure, or `aid add <tool>` to install a host tool.')
        [void]$lines.Add("name: $name")
        [void]$lines.Add('description: ""')
        [void]$lines.Add('type: brownfield')
        [void]$lines.Add("source_control: $sc")
        [void]$lines.Add('minimum_grade: A')
        [void]$lines.Add('heartbeat_interval: 1')
        $content = ($lines -join "`n") + "`n"
        [System.IO.File]::WriteAllText($settings, $content, (New-Object System.Text.UTF8Encoding($false)))
    }

    # Minimal AID-owned manifest: the single version source of truth. tools:{}
    # is populated when `aid add <tool>` installs a host tool.
    $manifest = Join-Path $aidDir '.aid-manifest.json'
    if (-not (Test-Path $manifest -PathType Leaf)) {
        $now = [System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        $mlines = [System.Collections.Generic.List[string]]::new()
        [void]$mlines.Add('{')
        [void]$mlines.Add('  "format_version": 2,')
        if ($ver) { [void]$mlines.Add("  `"aid_version`": `"$ver`",") }
        [void]$mlines.Add("  `"installed_at`": `"$now`",")
        [void]$mlines.Add('  "tools": {}')
        [void]$mlines.Add('}')
        $mcontent = ($mlines -join "`n") + "`n"
        [System.IO.File]::WriteAllText($manifest, $mcontent, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# Invoke-AidProjectsAdd [RawPath] [TierOverride] [Verbose]
# Register a project path (default: cwd) in the deterministic tier. If the folder
# is not yet an AID project, initialize a bare .aid/ (no tools) first.
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

    # If the folder is not yet an AID project, initialize a bare .aid/ (no tools)
    # rather than refusing. Test-AidIsProjectDir is also false when .aid/ resolves
    # to the CLI state home -- never scaffold/register that; distinguish it by the
    # presence of an existing .aid/ dir.
    if (-not (script:Test-AidIsProjectDir -Dir $canon)) {
        # Test-AidIsProjectDir is ALSO false when <dir>\.aid IS the CLI state home.
        # Refuse that explicitly (path compare, existence-agnostic -- mirrors the
        # guard in Test-AidIsProjectDir) so we never initialize $HOME\.aid or the
        # state home as a project. Otherwise the folder just has no .aid/ yet ->
        # initialize a bare, tool-less project.
        $caSub = Join-Path $canon '.aid'
        $caN = try { (Resolve-Path -LiteralPath $caSub -ErrorAction Stop).Path } catch { $caSub }
        $shN = try { (Resolve-Path -LiteralPath $script:_AidStateHome -ErrorAction Stop).Path } catch { $script:_AidStateHome }
        $hdSub = Join-Path $HOME '.aid'
        $hdN = try { (Resolve-Path -LiteralPath $hdSub -ErrorAction Stop).Path } catch { $hdSub }
        if ([string]::Equals($caN, $shN, [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($caN, $hdN, [System.StringComparison]::OrdinalIgnoreCase)) {
            [Console]::Error.WriteLine("ERROR: aid projects add: '$canon' is the AID state home, not a project.")
            script:Exit-Aid 2
        }
        script:Invoke-AidScaffoldBareProject -Canon $canon
        Write-Host ("aid projects: initialized a bare AID project at '$canon' (no tools; run 'aid add <tool>' to install a host tool).")
    } else {
        # Existing AID project: bring it current before registering. Refuse a
        # newer format than this CLI supports; migrate an older one (settings
        # flatten etc.), mirroring the format gate on other reaches.
        $repoFmt = script:Get-AidRepoFormat -Repo $canon
        if ($repoFmt -gt $script:AidSupportedFormat) {
            [Console]::Error.WriteLine("ERROR: aid projects add: '$canon' uses a newer AID format (v$repoFmt) than this CLI supports (v$($script:AidSupportedFormat)). Upgrade the aid CLI: aid update self.")
            script:Exit-Aid 1
        }
        # Migrate only a project that actually has a settings.yml (a bare .aid/
        # has nothing to migrate -- just register it).
        if ($repoFmt -lt $script:AidSupportedFormat -and (Test-Path (Join-Path (Join-Path $canon '.aid') 'settings.yml') -PathType Leaf)) {
            Write-Host "aid projects: '$canon' uses an older AID format (v$repoFmt); migrating to v$($script:AidSupportedFormat)..."
            try { $null = script:Invoke-AidMigrateRepo -Repo $canon 6>$null } catch {
                [Console]::Error.WriteLine("WARN: aid projects add: migration reported an issue for '$canon' (continuing)")
            }
        }
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
            Join-Path (Join-Path $HOME '.aid') 'registry.yml'
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

    $canon = $null

    if ($RawPath -match '^[0-9]+$') {
        # All-digits: always a 1-based index, never a path -- even if a folder of
        # that literal name exists (AC-13).
        $paths = @(script:Get-RegistryRawUnion)
        $count = $paths.Count
        # Parse as a 64-bit integer (matches bash's 64-bit `10#` arithmetic) via
        # TryParse so an all-digits value outside Int64 range (or otherwise
        # unparseable) routes to the same clean out-of-range error below instead
        # of leaking a native "Cannot convert ... to System.Int32"-style exception.
        [long]$n = 0
        if (-not [long]::TryParse($RawPath, [ref]$n)) {
            [Console]::Error.WriteLine("ERROR: aid projects: no project numbered $RawPath ($count registered)")
            script:Exit-Aid 2
        }
        if ($n -lt 1) {
            [Console]::Error.WriteLine("ERROR: aid projects: index must be a positive integer (>= 1): $RawPath")
            script:Exit-Aid 2
        }
        if ($n -gt $count) {
            [Console]::Error.WriteLine("ERROR: aid projects: no project numbered $n ($count registered)")
            script:Exit-Aid 2
        }
        $canon = $paths[$n - 1]
    } else {
        # Contains a non-digit: a path. Canonicalize without requiring existence.
        $resolvedRem = Resolve-Path -LiteralPath $RawPath -ErrorAction SilentlyContinue
        $canon = if ($resolvedRem) { $resolvedRem.Path } else { $null }
        if (-not $canon) {
            # Directory absent (stale entry); use raw path as-is.
            $canon = $RawPath
        }

        $primaryReg = Join-Path $script:_AidStateHome 'registry.yml'
        $userReg    = Join-Path (Join-Path $HOME '.aid') 'registry.yml'
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

        if (-not $found) {
            [Console]::Error.WriteLine("ERROR: aid projects: '$canon' is not registered (nothing to remove; see 'aid projects list')")
            script:Exit-Aid 2
        }
    }

    # $canon now names a currently-registered project; unregister it.
    script:Registry-Unregister -Repo $canon
    if ($Verbose) {
        Write-Host ("aid projects: removed '$canon' from registry.")
    }
}

# ---------------------------------------------------------------------------
# 'aid projects scan'  (work-019-discover-projects / task-002)
# Crawls the filesystem for folders containing a .aid/ and registers each in
# the machine project registry -- register-only (never scaffolds, updates,
# installs, or migrates; never writes inside a discovered project's .aid/).
# See SPEC.md (work-019-discover-projects) Data Model / Feature Flow / Layers.
#
# Byte-identical name sets (case-insensitive) mirror bin/aid's
# _AID_SCAN_PRUNE_DIRS / _AID_SCAN_SYSTEM_DIRS / _AID_SCAN_MAX_DEPTH (task-001)
# -- do not let the two twins diverge.
# ---------------------------------------------------------------------------

# NFR-2: heavy/cache/build directories, matched by BASENAME at ANY depth,
# CASE-INSENSITIVELY, in ALL scan modes (home default, --path, --all). A
# project whose OWN folder name is one of these is still discovered because
# the Test-AidIsProjectDir check (order step b) precedes this check (step c).
Set-Variable -Name AidScanPruneDirs -Option Constant -Scope Script -Value @(
    'node_modules', '.git', '.hg', '.svn', 'obj', 'bin', 'logs', 'target', 'dist', 'build',
    '.venv', 'venv', '__pycache__', '.gradle', '.m2', '.cargo', '.npm', '.cache', 'vendor', 'Pods',
    # VCS
    '.bzr', '_darcs', 'CVS',
    # Package caches
    '.nuget', '.pnpm-store', '.yarn', 'bower_components', 'npm-cache',
    '.mypy_cache', '.pytest_cache', '.tox', '.eggs', '.ruff_cache', '.ipynb_checkpoints',
    '.ivy2', '.bundle',
    # Build outputs
    '.next', '.nuxt', '.output', '.svelte-kit', '.parcel-cache', '.turbo', '.angular',
    'coverage', '.nyc_output', 'htmlcov',
    # Editors
    '.vscode', '.vs', '.idea', '.zed',
    # AI tools
    '.cursor', '.claude', '.codex', '.windsurf', '.antigravity',
    # Eclipse
    '.metadata', '.settings', '.p2', '.eclipse',
    # Version managers
    '.pyenv', '.rbenv', '.nvm', '.rustup', '.dotnet', '.sdkman', '.jenv', '.asdf', '.volta',
    'mise', '.goenv', '.phpenv',
    # Generic cache
    'cache', 'caches', 'CacheStorage',
    # Temp
    'tmp', 'temp', '.tmp', '.temp',
    # OS profile roots (promoted to Tier A)
    'AppData', 'Library',
    # macOS volume junk
    '.Trash', '.Trashes', '.Spotlight-V100', '.fseventsd', '.DocumentRevisions-V100',
    # Browser/webview caches
    'User Data', 'EBWebView', 'WebView2Cache', 'GPUCache', 'Code Cache', 'Service Worker',
    'IndexedDB', 'DawnCache', 'Crashpad', 'GrShaderCache', 'ShaderCache', 'D3DSCache',
    # Also
    'log'
)

# NFR-3: OS/system directories, applied ONLY under --all and ONLY as an
# immediate child of a filesystem/drive root (never under the HOME default or
# --path, and never deeper than one level below an --all scan root).
Set-Variable -Name AidScanSystemDirs -Option Constant -Scope Script -Value @(
    'proc', 'sys', 'dev', 'run',
    'Windows', 'Program Files', 'Program Files (x86)', '$Recycle.Bin', 'System Volume Information',
    # Windows
    'ProgramData', '$WinREAgent', '$WINDOWS.~BT', '$WINDOWS.~WS', 'Recovery', 'PerfLogs',
    'Windows.old', 'MSOCache', 'Temporary Internet Files', 'Recycled', 'RECYCLER',
    # Linux
    'Trash'
)

# NFR-4: hard recursion-depth ceiling, DISTINCT from and INDEPENDENT of the
# user-facing --depth cap -- guarantees termination on a pathological tree.
Set-Variable -Name AidScanMaxDepth -Option Constant -Scope Script -Value 40

# Test-AidScanNameInSet <Name> <Set>
# Case-insensitive exact-match membership test (OrdinalIgnoreCase, matching
# this file's other path/name comparisons -- see Test-AidIsProjectDir).
# Mirror of bash _aid_scan_name_in_set.
function script:Test-AidScanNameInSet {
    param([string]$Name, [string[]]$Set)
    foreach ($item in $Set) {
        if ([string]::Equals($Name, $item, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# Get-AidScanConfigPath
# Resolve the user-level scan-config.yml primary + fallback tier paths
# (FR-8), mirroring Get-RegistryUnion's primary/fallback + per-user-collapse
# pattern (~:1596-1626): primary = $script:_AidStateHome\scan-config.yml
# (honors the AID_HOME override via the startup scope derivation); fallback =
# $HOME\.aid\scan-config.yml. PerUser is $true when the two normalize to the
# same path (single-tier install -- no double-read).
# Mirror of bash's $_AID_SCAN_CONFIG constant + the primary/fallback pattern
# reused from _registry_read_union.
function script:Get-AidScanConfigPath {
    $userDotAid = Join-Path $HOME '.aid'
    $primary    = Join-Path $script:_AidStateHome 'scan-config.yml'
    $fallback   = Join-Path $userDotAid 'scan-config.yml'
    $primaryNorm  = [System.IO.Path]::GetFullPath($script:_AidStateHome)
    $fallbackNorm = [System.IO.Path]::GetFullPath($userDotAid)
    [PSCustomObject]@{
        Primary  = $primary
        Fallback = $fallback
        PerUser  = ($primaryNorm -eq $fallbackNorm)
    }
}

# Get-AidScanPruneDirFromConfig -ConfigPath <path>
# Single-file line-scan of the `prune_dirs:` block list out of ONE
# scan-config.yml, reusing the exact Get-RegistryRepos list-item regex
# ('^\s*-\s+(.+\S)\s*$', ~:1579) -- but scoped to the prune_dirs: block only:
# entered on the bare "prune_dirs:" line, left at the next non-indented line,
# so a sibling top-level key never leaks into the list scan. Only the
# leading "- " marker and trailing whitespace are stripped -- internal spaces
# survive, so "Code Cache" reads back intact. Returns [string[]], empty when
# the file is absent or has no prune_dirs: key (FR-5/FR-6/NFR-5).
# Mirror of bash _aid_scan_config_prune_dirs.
function script:Get-AidScanPruneDirFromConfig {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath -PathType Leaf)) { return @() }
    $results = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    foreach ($line in (Get-Content -LiteralPath $ConfigPath -Encoding utf8 -ErrorAction SilentlyContinue)) {
        if (-not $inBlock) {
            if ($line -match '^prune_dirs:\s*$') { $inBlock = $true }
            continue
        }
        if ($line -match '^\S') { $inBlock = $false; continue }
        if ($line -match '^\s*-\s+(.+\S)\s*$') {
            $results.Add($Matches[1])
        }
    }
    return $results.ToArray()
}

# Get-AidScanMergedPruneDirs
# Effective Tier-A prune set (FR-4): the case-insensitive deduped union of
# $script:AidScanPruneDirs and the user-level scan-config.yml prune_dirs:
# entries (primary tier, plus the fallback tier too when Get-AidScanConfigPath
# reports the two paths differ -- FR-8). Extend-only -- a config entry can
# never remove a built-in default; a repeated built-in is deduped harmlessly
# (AC-8). Built-ins are emitted first (their documented order), then any
# non-duplicate config entries in read order. Returns [string[]]; called ONCE
# by Invoke-AidProjectsScan (NFR-1) -- never re-read per directory.
# Mirror of bash _aid_scan_merge_prune_dirs.
function script:Get-AidScanMergedPruneDirs {
    $cfgPaths = script:Get-AidScanConfigPath
    $configEntries = [System.Collections.Generic.List[string]]::new()
    # @(...) forces array context (an empty-array `return` from a PS function
    # collapses to $null when captured bare), then [string[]] gives AddRange()
    # the concrete element type it needs (a bare object[] does not convert).
    $configEntries.AddRange([string[]]@(script:Get-AidScanPruneDirFromConfig -ConfigPath $cfgPaths.Primary))
    if (-not $cfgPaths.PerUser) {
        $configEntries.AddRange([string[]]@(script:Get-AidScanPruneDirFromConfig -ConfigPath $cfgPaths.Fallback))
    }

    $seen   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $merged = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $script:AidScanPruneDirs) {
        if ($seen.Add($item)) { $merged.Add($item) }
    }
    foreach ($item in $configEntries) {
        if ([string]::IsNullOrEmpty($item)) { continue }
        if ($seen.Add($item)) { $merged.Add($item) }
    }
    return $merged.ToArray()
}

# Set-AidScanConfigSeed
# First-run seed (FR-3/NFR-3): if the primary scan-config.yml is absent,
# write it with a header + `schema: 1` + a `prune_dirs:` block of the
# built-in expanded Tier-A defaults, via the SAME Move-Item -Force atomic-
# write idiom Registry-Register uses (~:2620-2643: write to a temp file in
# the same directory, then Move-Item -Force). Same primary/fallback DEGRADE
# too (~:2854-2867): if the primary's directory ($script:_AidStateHome) is
# absent/not writable -- e.g. a global/shared install such as $ProgramData
# \aid where the primary tier is not user-writable -- the seed degrades to
# $HOME\.aid\scan-config.yml instead of WARNing forever on every non--DryRun
# scan. Silent by default (visible under $script:_AidVerbose), matching
# Registry-Register. The READ side already unions the primary + $HOME\.aid
# fallback tiers (Get-AidScanMergedPruneDirs / Get-AidScanConfigPath), so a
# seed landing in the fallback is read back correctly.
# Best-effort: a mkdir/write/move failure at whichever tier is resolved
# prints one WARN to stderr and returns -- it never fails the scan.
# Idempotent -- never overwrites an existing file at whichever tier it
# resolves to, so a user's edits always survive. The caller MUST NOT invoke
# this under -DryRun (a dry-run scan makes no writes at all).
# Mirror of bash _aid_scan_seed_config.
function script:Set-AidScanConfigSeed {
    $cfgPaths = script:Get-AidScanConfigPath
    $primary  = $cfgPaths.Primary
    if (Test-Path -LiteralPath $primary -PathType Leaf) { return }

    # Helper: test writability of a directory (mirrors Registry-Register ~:2788-2793).
    $testWritable = {
        param([string]$dir)
        if (-not (Test-Path $dir -PathType Container)) { return $false }
        $probe = Join-Path $dir ('.aid-write-probe.' + [System.IO.Path]::GetRandomFileName())
        try { [System.IO.File]::WriteAllText($probe, ''); Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue; return $true } catch { return $false }
    }

    $dir = Split-Path $primary -Parent
    if (-not (Test-Path $dir -PathType Container)) {
        try { New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    $target = $null
    if (& $testWritable $dir) {
        $target = $primary
    } else {
        # Primary not writable (global/shared install); degrade to $HOME\.aid,
        # mirroring Registry-Register's user-tier degrade (~:2854-2867).
        $fallback = $cfgPaths.Fallback
        $fbDir = Split-Path $fallback -Parent
        if (-not (Test-Path $fbDir -PathType Container)) {
            try { New-Item -ItemType Directory -Path $fbDir -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
        if ($script:_AidVerbose) {
            [Console]::Error.WriteLine("WARN: aid: could not write to $dir; seeding $fallback instead")
        }
        $target = $fallback
    }

    # Idempotent at whichever tier resolved to -- never overwrite an existing file.
    if (Test-Path -LiteralPath $target -PathType Leaf) { return }

    $targetDir = Split-Path $target -Parent
    $tmp = Join-Path $targetDir ("scan-config.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $lns = [System.Collections.Generic.List[string]]::new()
        $lns.Add('# scan-config.yml -- user-level directory-prune list for "aid projects scan".')
        $lns.Add('# Names here are ADDED to the built-in exclusion set (case-insensitive, EXACT')
        $lns.Add('# basename, matched at any depth). Extend-only: a built-in default cannot be')
        $lns.Add('# removed here. One "- <name>" per line. Names with spaces need no quotes.')
        $lns.Add('schema: 1')
        $lns.Add('prune_dirs:')
        foreach ($n in $script:AidScanPruneDirs) { $lns.Add("  - $n") }
        [System.IO.File]::WriteAllText($tmp, (($lns.ToArray()) -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $target -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid: could not seed the scan exclusions config ($target): write failed")
    }
}

# Get-AidScanRoot -All <bool> -ScanPath <string> -IncludeNetwork <bool> -IncludeRemovable <bool>
# Resolves the scan roots by scope (FR-2/FR-3) and validates the scope/drive
# flags, exiting 2 on any usage error:
#   default (no scope flag)  -> the user HOME directory; NO drive enumeration
#   -ScanPath <folder>       -> that canonical folder; NO drive enumeration
#   -All                     -> whole machine; the ONLY mode that enumerates
#                                drives (Windows: local FIXED drives, network/
#                                removable excluded by default; Unix: "/")
# Returns an array of one canonical root path per element.
# Mirror of bash _aid_scan_roots.
function script:Get-AidScanRoot {
    param(
        [bool]$All = $false,
        [string]$ScanPath = '',
        [bool]$IncludeNetwork = $false,
        [bool]$IncludeRemovable = $false
    )

    if ($All -and $ScanPath) {
        [Console]::Error.WriteLine("ERROR: aid projects scan: --path and --all are mutually exclusive")
        script:Exit-Aid 2
    }
    if (-not $All -and ($IncludeNetwork -or $IncludeRemovable)) {
        [Console]::Error.WriteLine("ERROR: aid projects scan: --include-network / --include-removable require --all")
        script:Exit-Aid 2
    }

    if ($ScanPath) {
        if (-not (Test-Path -LiteralPath $ScanPath -PathType Container)) {
            [Console]::Error.WriteLine("ERROR: aid projects scan: --path is not a directory: $ScanPath")
            script:Exit-Aid 2
        }
        $canon = try { (Resolve-Path -LiteralPath $ScanPath -ErrorAction Stop).Path } catch { $ScanPath }
        return @($canon)
    }

    if ($All) {
        if (script:Test-AidWindows) {
            # Same classifier the bash twin shells out to powershell.exe for
            # ([System.IO.DriveInfo]::GetDrives() filtered on DriveType) -- run
            # natively here, so drive classification is identical-by-construction.
            $types = [System.Collections.Generic.List[string]]::new()
            [void]$types.Add('Fixed')
            if ($IncludeNetwork)   { [void]$types.Add('Network') }
            if ($IncludeRemovable) { [void]$types.Add('Removable') }
            $drives = @()
            try {
                $drives = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $types -contains $_.DriveType.ToString() } | ForEach-Object { $_.Name })
            } catch { $drives = @() }
            if ($drives.Count -eq 0) {
                [Console]::Error.WriteLine("WARN: aid projects scan: no fixed drives detected; nothing to scan under --all")
            }
            return $drives
        } else {
            # NFR-5: no drive-letter model on Unix -- the single root is "/",
            # and network/removable mounts are not auto-classified (documented
            # limitation); the two flags are accepted-but-inert here.
            if ($IncludeNetwork -or $IncludeRemovable) {
                [Console]::Error.WriteLine("aid projects scan: --include-network/--include-removable are Windows-only-effective (drive-type filtering is a Windows concept); on Unix --all already walks every mount under /.")
            }
            return @('/')
        }
    }

    # Default scope: the user HOME directory, no drive enumeration.
    $homeCanon = try { (Resolve-Path -LiteralPath $HOME -ErrorAction Stop).Path } catch { $HOME }
    return @($homeCanon)
}

# Invoke-AidScanWalkNode -Dir <dir> -Depth <depth-from-root> -IsAll <bool> -UserDepth <long>
# Internal recursive worker for Invoke-AidScanWalk. Applies the FIXED
# per-folder order (NFR-9) to <Dir>: (a) unreadable -> skip; (b) a valid
# .aid/ project -> emit the CANONICAL candidate and prune the whole subtree;
# (c) basename in the heavy/cache set (any depth, all modes) -> prune; (c2)
# under -All only, an immediate child of the scan root (depth 1) whose
# basename is in the OS/system set -> prune; (d) else recurse into children,
# skipping directory symlinks (NFR-4) and stopping at the user -Depth cap and
# the hard $script:AidScanMaxDepth ceiling. Appends one canonical candidate
# path per discovered project to the shared $Candidates list (avoids the
# pipeline-object overhead of Write-Output on a hot recursive path).
# Mirror of bash _aid_scan_walk_node.
function script:Invoke-AidScanWalkNode {
    param(
        [string]$Dir,
        [int]$Depth,
        [bool]$IsAll,
        [long]$UserDepth,
        [System.Collections.Generic.List[string]]$Candidates,
        [string]$StateHomeCanon,
        [string]$HomeAidCanon,
        [string[]]$PruneDirs
    )

    $script:_AidScanDirCount++
    if (($script:_AidScanDirCount % $script:_AidScanProgressStride) -eq 0) {
        [Console]::Error.WriteLine("aid projects scan: ...$($script:_AidScanDirCount) folder(s) examined so far (current: $Dir)")
    }

    # (a) Not a directory, or unreadable -- skip and continue (NFR-1). The
    # child-directory enumeration doubles as the readability probe: a denied
    # or vanished directory throws here and is treated as unreadable.
    if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return }
    $childNames = $null
    try {
        $childNames = [System.IO.Directory]::GetDirectories($Dir)
    } catch {
        return
    }

    # (b) A valid AID project -- emit the canonical candidate and PRUNE the
    # whole subtree (do not recurse into ANY child, incl. .aid/) (NFR-9).
    if (script:Test-AidIsProjectDir -Dir $Dir) {
        $canon = try { (Resolve-Path -LiteralPath $Dir -ErrorAction Stop).Path } catch { $Dir }
        $Candidates.Add($canon)
        return
    }

    # Never descend into the CLI's own state-home subtree: classification
    # alone excludes it as a PROJECT via step (b) above, but without this the
    # walk would still recurse INTO it, so a project nested inside
    # $HOME/.aid / $AID_STATE_HOME could still be discovered. Plain string
    # compare against the two canonical state-home paths computed ONCE by the
    # caller (Invoke-AidProjectsScan) -- $Dir is already canonical by
    # construction (built from an already-canonical root plus real,
    # non-symlink child names only -- symlinked children are never descended
    # into, see (d) below).
    if ([string]::Equals($Dir, $StateHomeCanon, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($Dir, $HomeAidCanon, [System.StringComparison]::OrdinalIgnoreCase)) {
        return
    }

    $base = Split-Path -Path $Dir -Leaf
    if ([string]::IsNullOrEmpty($base)) { $base = $Dir }   # a filesystem root itself, e.g. "C:\" or "/"

    # (c) Heavy/cache/build basename match -- any depth, all modes (NFR-2).
    # Tests the run-scoped MERGED set (built-in $script:AidScanPruneDirs
    # unioned with any user-level scan-config.yml prune_dirs: entries, FR-4)
    # computed ONCE by Invoke-AidProjectsScan and threaded down as -PruneDirs
    # -- NOT the built-in constant directly.
    if (script:Test-AidScanNameInSet -Name $base -Set $PruneDirs) {
        return
    }

    # (c2) -All only, root-only: an immediate child of the scan root whose
    # basename is an OS/system name (NFR-3). Never applied under the HOME
    # default or -ScanPath (any depth), so a top-level ~/dev or
    # <-ScanPath>/dev is descended normally.
    if ($IsAll -and $Depth -eq 1) {
        if (script:Test-AidScanNameInSet -Name $base -Set $script:AidScanSystemDirs) {
            return
        }
    }

    # (d) Recurse into children -- skipping directory symlinks (NFR-4) and
    # stopping at the user -Depth cap and the hard $script:AidScanMaxDepth cap.
    $nextDepth = $Depth + 1
    if ($UserDepth -ge 0 -and $nextDepth -gt $UserDepth) { return }
    if ($nextDepth -gt $script:AidScanMaxDepth) { return }

    foreach ($child in $childNames) {
        $attr = $null
        try { $attr = [System.IO.File]::GetAttributes($child) } catch { continue }
        if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        script:Invoke-AidScanWalkNode -Dir $child -Depth $nextDepth -IsAll $IsAll -UserDepth $UserDepth `
            -Candidates $Candidates -StateHomeCanon $StateHomeCanon -HomeAidCanon $HomeAidCanon -PruneDirs $PruneDirs
    }
}

# Invoke-AidScanWalk -Root <root> -IsAll <bool> -UserDepth <long> -StateHomeCanon <string> -HomeAidCanon <string> -PruneDirs <string[]>
# Entry point: walks <Root> (depth 0) and returns an array of CANONICAL
# discovered .aid/ project paths.
# Mirror of bash _aid_scan_walk.
function script:Invoke-AidScanWalk {
    param(
        [string]$Root,
        [bool]$IsAll,
        [long]$UserDepth,
        [string]$StateHomeCanon,
        [string]$HomeAidCanon,
        [string[]]$PruneDirs
    )
    $candidates = [System.Collections.Generic.List[string]]::new()
    script:Invoke-AidScanWalkNode -Dir $Root -Depth 0 -IsAll $IsAll -UserDepth $UserDepth `
        -Candidates $candidates -StateHomeCanon $StateHomeCanon -HomeAidCanon $HomeAidCanon -PruneDirs $PruneDirs
    return $candidates
}

# Invoke-AidProjectsScan
# Orchestrates parse -> roots -> pruned walk -> canonical-dedupe -> register
# -> report (SPEC.md Feature Flow). Register-only: the only write is
# Registry-Register on a genuinely NEW candidate; an already-registered
# candidate is left byte-unchanged (FR-5). -DryRun replaces the write with
# recording "would-register" (FR-4). Tier is FORCED to the user tier before
# registering, unless -Shared was explicitly given (FR-9).
# Mirror of bash _cmd_projects_scan.
function script:Invoke-AidProjectsScan {
    param(
        [string]$ScanPath          = '',
        [bool]  $All               = $false,
        [string]$Depth             = '',
        [bool]  $DryRun            = $false,
        [bool]  $IncludeNetwork    = $false,
        [bool]  $IncludeRemovable  = $false,
        [bool]  $Shared            = $false,
        [bool]  $Verbose           = $false
    )

    # -Depth must be a non-negative integer (AC-3).
    [long]$userDepth = -1
    if ($Depth -ne '') {
        if ($Depth -notmatch '^[0-9]+$') {
            [Console]::Error.WriteLine("ERROR: aid projects scan: --depth must be a non-negative integer: $Depth")
            script:Exit-Aid 2
        }
        [long]$parsedDepth = 0
        if (-not [long]::TryParse($Depth, [ref]$parsedDepth)) {
            [Console]::Error.WriteLine("ERROR: aid projects scan: --depth must be a non-negative integer: $Depth")
            script:Exit-Aid 2
        }
        $userDepth = $parsedDepth
    }

    # Resolve roots (validates -ScanPath/-All mutual exclusion, non-dir
    # -ScanPath, and include-flags-without-all; exits 2 on any usage error).
    $roots = @(script:Get-AidScanRoot -All $All -ScanPath $ScanPath -IncludeNetwork $IncludeNetwork -IncludeRemovable $IncludeRemovable)

    if ($Verbose) {
        [Console]::Error.WriteLine("aid projects scan: roots: $($roots -join ' ')")
    }

    # Read the registry ONCE (Feature Flow step 3) for O(1) already-registered
    # lookups; never re-read mid-walk.
    $regSeen = @{}
    foreach ($rp in (script:Get-RegistryRawUnion)) {
        if ($rp) { $regSeen[$rp] = $true }
    }

    # FR-3/NFR-3: seed scan-config.yml with the built-in Tier-A defaults on
    # the first real (non-dry-run) scan when it is absent -- best-effort,
    # idempotent, and never invoked under -DryRun (a dry-run scan makes no
    # writes at all). Then resolve the effective Tier-A set ONCE (FR-4/NFR-1):
    # the case-insensitive deduped union of the built-in set and any
    # scan-config.yml prune_dirs: entries; a missing/unreadable/prune_dirs-
    # less config falls back to exactly the built-in set (FR-5).
    if (-not $DryRun) { script:Set-AidScanConfigSeed }
    $mergedPruneDirs = script:Get-AidScanMergedPruneDirs

    # FR-9: force the user tier before registering, unless the caller already
    # forced -Shared explicitly; never leave the auto-rule to choose.
    $tierOverride = if ($Shared) { '--shared' } else { '--local' }

    # State-home canonical paths, computed ONCE here so Invoke-AidScanWalkNode
    # can prune the state home's subtree with a plain string compare -- never
    # registered as a project itself, and never DESCENDED INTO either.
    $scanStateHomeCanon = try { (Resolve-Path -LiteralPath $script:_AidStateHome -ErrorAction Stop).Path } catch { $script:_AidStateHome }
    $scanHomeAidCanon   = try { (Resolve-Path -LiteralPath (Join-Path $HOME '.aid') -ErrorAction Stop).Path } catch { Join-Path $HOME '.aid' }

    $scanSeen    = @{}   # run-scoped canonical-key dedupe (NFR-10)
    $reportLines = [System.Collections.Generic.List[string]]::new()
    $nNew        = 0
    $nExisting   = 0

    $script:_AidScanDirCount       = 0
    $script:_AidScanProgressStride = 200

    foreach ($root in $roots) {
        [Console]::Error.WriteLine("aid projects scan: scanning $root ...")
        $candidates = script:Invoke-AidScanWalk -Root $root -IsAll $All -UserDepth $userDepth `
            -StateHomeCanon $scanStateHomeCanon -HomeAidCanon $scanHomeAidCanon -PruneDirs $mergedPruneDirs
        foreach ($cand in $candidates) {
            if (-not $cand) { continue }
            # Dedupe within the run: the same real project reached more than
            # once (overlap, symlink, '.'/'..') is considered exactly once.
            if ($scanSeen.ContainsKey($cand)) { continue }
            $scanSeen[$cand] = $true

            $ver  = script:Get-AidProjectState -Path $cand
            $tier = script:Resolve-AidTier -CanonPath $cand -TierOverride $tierOverride

            if ($regSeen.ContainsKey($cand)) {
                $action = 'already-registered'
                $nExisting++
            } elseif ($DryRun) {
                $action = 'would-register'
                $nNew++
            } else {
                script:Registry-Register -Repo $cand -Tier $tier 6>$null
                $action = 'registered'
                $nNew++
            }
            if ($Verbose) {
                [Console]::Error.WriteLine("aid projects scan: $cand  tier=$tier  version=$ver  action=$action")
            }
            $reportLines.Add("$cand  $ver  $action")
        }
    }

    # Final summary (FR-7): counts to stdout, then one path/version/action
    # line per discovered project.
    Write-Host "aid projects scan: $nNew newly-registered, $nExisting already-registered."
    foreach ($line in $reportLines) {
        Write-Host $line
    }

    return 0
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
    # Scan-specific flags (work-019-discover-projects task-002): gated to the
    # 'scan' action below -- passing any of these to list/add/remove is a
    # usage error (exit 2).
    $scanPath             = ''
    $scanAll              = $false
    $scanDepth            = ''
    $scanDryRun           = $false
    $scanIncludeNetwork   = $false
    $scanIncludeRemovable = $false
    $scanFlagSeen         = $false

    # Parse remaining args.
    $i = 0
    while ($i -lt $RemArgs.Count) {
        $a = $RemArgs[$i]
        switch ($a) {
            { $_ -in @('-h', '--help', '-Help') } { $Action = 'help'; break }
            '--local'   { $tierOverride = '--local'; break }
            '--shared'  { $tierOverride = '--shared'; break }
            '--verbose' { $verbose = $true; $script:_AidVerbose = $true; break }
            '--path' {
                $i++
                if ($i -ge $RemArgs.Count) {
                    [Console]::Error.WriteLine("ERROR: aid projects: --path requires a value")
                    script:Exit-Aid 2
                }
                $scanPath = $RemArgs[$i]; $scanFlagSeen = $true
                break
            }
            '--all' { $scanAll = $true; $scanFlagSeen = $true; break }
            '--depth' {
                $i++
                if ($i -ge $RemArgs.Count) {
                    [Console]::Error.WriteLine("ERROR: aid projects: --depth requires a value")
                    script:Exit-Aid 2
                }
                $scanDepth = $RemArgs[$i]; $scanFlagSeen = $true
                break
            }
            '--dry-run'            { $scanDryRun = $true; $scanFlagSeen = $true; break }
            '--include-network'    { $scanIncludeNetwork = $true; $scanFlagSeen = $true; break }
            '--include-removable'  { $scanIncludeRemovable = $true; $scanFlagSeen = $true; break }
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

    # Gate scan-specific flags to the 'scan' action -- a scan-only flag passed
    # to list/add/remove is a usage error (Command Surface & CLI Contract).
    # Excludes "help": -h/--help (anywhere in the arg list) already overwrote
    # $Action to "help" above, and help must take precedence over this gate --
    # otherwise e.g. 'aid projects scan --dry-run -h' would hit this error
    # (exit 2) instead of showing usage (exit 0).
    if ($scanFlagSeen -and $Action -ne 'scan' -and $Action -ne 'help') {
        [Console]::Error.WriteLine("ERROR: aid projects: --path/--all/--depth/--dry-run/--include-network/--include-removable are scan-only flags (see 'aid projects scan -h')")
        script:Exit-Aid 2
    }
    # 'scan' has no positional <root> form (--path replaces it, FR-3); a
    # stray positional is a usage error rather than a silently-ignored value.
    if ($Action -eq 'scan' -and $pathArg) {
        [Console]::Error.WriteLine("ERROR: aid projects scan: unexpected argument: '$pathArg' (there is no positional <root> -- use --path <folder>)")
        script:Exit-Aid 2
    }

    $resolvedPath = if ($pathArg) { $pathArg } else { '.' }

    switch ($Action) {
        'list'   { script:Invoke-AidProjectsList   -Verbose $verbose }
        'add'    { script:Invoke-AidProjectsAdd    -RawPath $resolvedPath -TierOverride $tierOverride -Verbose $verbose }
        'remove' { script:Invoke-AidProjectsRemove -RawPath $resolvedPath -Verbose $verbose }
        'scan'   {
            $scanShared = ($tierOverride -eq '--shared')
            script:Invoke-AidProjectsScan -ScanPath $scanPath -All $scanAll -Depth $scanDepth -DryRun $scanDryRun `
                -IncludeNetwork $scanIncludeNetwork -IncludeRemovable $scanIncludeRemovable -Shared $scanShared -Verbose $verbose
        }
        'help'   { script:Show-AidUsage 'projects'; script:Exit-Aid 0 }
        default  {
            [Console]::Error.WriteLine("ERROR: aid projects: unknown action: $Action (expected: list, add, remove, scan, help)")
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
            [System.IO.File]::WriteAllText($tmp, (($lns.ToArray()) -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
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
            [System.IO.File]::WriteAllText($tmp, (($lns.ToArray()) -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
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

# ---- Early top-level --version / -V (bare, no value) ----
# Distinct from the subcommand -Version <v> pin flag parsed further below
# (add/remove/update). Only fires when it is the FIRST argument, so it never
# shadows the pin (which is only matched among the args AFTER the subcommand).
if ($script:_RawArgs[0] -in @('-V', '--version')) {
    script:Show-AidVersion
    script:Exit-Aid 0
}

$SUBCMD = $script:_RawArgs[0]
$script:_RemArgs = @($script:_RawArgs | Select-Object -Skip 1)

# ---------------------------------------------------------------------------
# version
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'version') {
    script:Show-AidVersion
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
    # STEP 2 -- ELIMINATE .aid/dashboard/ (format 2): relocate kb.html to
    # .aid/knowledge/ and remove the obsolete per-repo dashboard folder. home.html is
    # now served by the CLI (no per-repo copy). No-clobber; best-effort.
    # ------------------------------------------------------------------
    $dashDir      = Join-Path $aidDir 'dashboard'
    $knowledgeDir = Join-Path $aidDir 'knowledge'
    $kbNew        = Join-Path $knowledgeDir 'kb.html'
    $kbOld        = Join-Path $dashDir 'kb.html'
    if (Test-Path $kbOld -PathType Leaf) {
        if (-not (Test-Path $kbNew -PathType Leaf)) {
            # Proper place is free: relocate the misplaced kb.html into it.
            try {
                if (-not (Test-Path $knowledgeDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $knowledgeDir -Force | Out-Null
                }
                Move-Item -LiteralPath $kbOld -Destination $kbNew -ErrorAction Stop
            } catch {
                [Console]::Error.WriteLine("WARN: aid migrate: relocate kb.html failed for ${Repo}: $_")
            }
        } else {
            # Proper place already holds a kb.html (authoritative): drop the stale stray.
            Remove-Item -LiteralPath $kbOld -Force -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path $dashDir -PathType Container) {
        # Drop the now-obsolete home.html, then remove the folder only if it is empty.
        Remove-Item -LiteralPath (Join-Path $dashDir 'home.html') -ErrorAction SilentlyContinue
        $_dashLeft = @(Get-ChildItem -LiteralPath $dashDir -Force -ErrorAction SilentlyContinue)
        if ($_dashLeft.Count -eq 0) {
            Remove-Item -LiteralPath $dashDir -Force -ErrorAction SilentlyContinue
        } else {
            [Console]::Error.WriteLine("WARN: aid migrate: .aid/dashboard not empty for ${Repo}; left in place")
        }
    }

    # ------------------------------------------------------------------
    # STEP 3 -- RELOCATE legacy summary (DM-4 / FR31) -> .aid/knowledge/kb.html -- no-clobber mv.
    # ------------------------------------------------------------------
    $oldSummary = Join-Path $knowledgeDir 'knowledge-summary.html'
    if ((Test-Path $oldSummary -PathType Leaf) -and (-not (Test-Path $kbNew -PathType Leaf))) {
        try {
            if (-not (Test-Path $knowledgeDir -PathType Container)) {
                New-Item -ItemType Directory -Path $knowledgeDir -Force | Out-Null
            }
            Move-Item -LiteralPath $oldSummary -Destination $kbNew -ErrorAction Stop
        } catch {
            [Console]::Error.WriteLine("WARN: aid migrate: relocate legacy summary failed for ${Repo}: $_")
        }
    }

    # ------------------------------------------------------------------
    # STEP 3b -- RETIRE the redundant .aid/.aid-version marker (version now lives
    # in the manifest / settings.yml). Best-effort delete; idempotent.
    # ------------------------------------------------------------------
    Remove-Item -LiteralPath (Join-Path $aidDir '.aid-version') -Force -ErrorAction SilentlyContinue

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

    # ------------------------------------------------------------------
    # STEP 5 -- CONVERT-STATE (work-009-refactor task-008 / SPEC.md SS L-6
    # step 2). See the runbook/rollback/ordering header comment on
    # script:Sc-ConvertRepo below for the full contract. WARN-not-fail per
    # this function's own always-return-0 rule.
    # ------------------------------------------------------------------
    try {
        script:Sc-ConvertRepo -Repo $Repo
    } catch {
        [Console]::Error.WriteLine("WARN: aid migrate: state-format conversion step raised for ${Repo}: $_")
    }

    return 0
}

# ===========================================================================
# STATE.md -> STATE.yml FORMAT-4 CONVERSION  (task-008 / SPEC.md SS L-6 step 2)
# PowerShell twin of the Bash block directly above Invoke-AidMigrateRepo in
# bin/aid (search that file for the identical banner). Same runbook exactly:
#
# RUNBOOK -- ORDERING (binding, stated here AND in migrate-work-hierarchy.ps1's
# own header): hierarchy migration runs FIRST, format conversion SECOND.
# migrate-work-hierarchy.sh/.ps1 stay markdown-in / markdown-out (an ERA
# migration: monolithic single-STATE.md -> the per-unit hierarchy) and their
# output is exactly what this converter expects as its input -- a
# CURRENT-SHAPE (post-hierarchy) work tree, whose STATE.md files still carry
# the DERIVED placeholder sections but never a REAL DERIVED row. A work that
# still needs the hierarchy migration is detected here as the "DERIVED
# section holds real data" hard-error case below (SP-3): the remedy that
# error names is "run migrate-work-hierarchy, then re-run aid update".
#
# RUNBOOK -- ROLLBACK. No reverse (yml -> md) converter exists, and none is
# ever added -- that would reopen the dual-format window SPEC.md SS L-6
# rejects (a hard cutover, not a dual-read compatibility window).
#   - Per-FILE rollback (a conversion that fails verification mid-run): there
#     is nothing to roll back. The .yml is built in a same-directory temp
#     file, re-parsed and count-verified BEFORE the .md is ever touched; on
#     any verification failure the temp is discarded and the .md is left
#     exactly as it was (byte-unchanged) -- this fail-safe ordering IS the
#     rollback story for a single file.
#   - Per-REPO rollback (undoing an already-completed conversion): restore
#     the .md files from version control and roll the repo's
#     .aid/settings.yml format_version stamp back to its prior value. There
#     is no in-place "unconvert" operation -- VCS is the only supported path
#     back, which is why this is a hard cutover and not a compatibility
#     window.
#
# IDEMPOTENT: a work whose STATE.yml already exists is a no-op for that file.
# Re-running the whole step changes nothing for a fully converted repo. The
# one legitimate exception: a file the DERIVED guard previously refused
# converts on the NEXT run once its DERIVED row is resolved (by running the
# hierarchy migration) -- the intended remedy path, not an idempotency
# violation.
#
# SCOPE: every .aid/works/*/STATE.md, and -- on the full (non-flattened)
# layout, detected per work by the presence of a deliveries/ subfolder --
# every deliveries/*/STATE.md and deliveries/*/tasks/*/STATE.md.
#
# WARN-NOT-FAIL: every failure mode is reported via a "WARN: aid migrate: ..."
# line naming the file (and, for the DERIVED guard, the section and the
# remedy) and moves on to the next file; script:Sc-ConvertRepo never throws
# past Invoke-AidMigrateRepo, which always returns 0.
# ===========================================================================

function script:Sc-Trim {
    param([string]$S)
    return $S.Trim()
}

function script:Sc-HeadingLevel {
    param([string]$Line)
    if ($Line.StartsWith('### ')) { return 3 }
    if ($Line.StartsWith('## ')) { return 2 }
    return 0
}

# script:Sc-FindHeading TEXT START END -> the absolute index (into the
# script-scope $script:ScLines list) of the first line in [START,END) whose
# trimmed text equals TEXT exactly; -1 if not found.
function script:Sc-FindHeading {
    param([string]$Text, [int]$Start, [int]$End)
    for ($i = $Start; $i -lt $End; $i++) {
        if ((script:Sc-Trim $script:ScLines[$i]) -eq $Text) { return $i }
    }
    return -1
}

# script:Sc-SectionEnd START END -> index of the next heading at a level <=
# the heading level found AT index START (which must itself be a heading
# line); END if none.
function script:Sc-SectionEnd {
    param([int]$Start, [int]$End)
    $mlvl = script:Sc-HeadingLevel $script:ScLines[$Start]
    for ($i = $Start + 1; $i -lt $End; $i++) {
        $lvl = script:Sc-HeadingLevel $script:ScLines[$i]
        if ($lvl -gt 0 -and $lvl -le $mlvl) { return $i }
    }
    return $End
}

# script:Sc-TableRows START END -> sets $script:ScRows, one element per DATA
# row in [START,END); skips the header + separator row (the first two
# "|...|" lines) and drops a single remaining "_none yet_" placeholder row.
# Each row is a string with cells joined by ASCII 0x1F.
function script:Sc-TableRows {
    param([int]$Start, [int]$End)
    $rows = [System.Collections.Generic.List[string]]::new()
    $headerSeen = $false
    $sepSeen = $false
    for ($i = $Start; $i -lt $End; $i++) {
        $line = $script:ScLines[$i]
        if (-not ($line -match '^\s*\|.*\|\s*$')) { continue }
        if (-not $headerSeen) { $headerSeen = $true; continue }
        if (-not $sepSeen) { $sepSeen = $true; continue }
        $body = (script:Sc-Trim $line)
        if ($body.StartsWith('|')) { $body = $body.Substring(1) }
        if ($body.EndsWith('|')) { $body = $body.Substring(0, $body.Length - 1) }
        $cells = $body -split '\|'
        $joined = ($cells | ForEach-Object { (script:Sc-Trim $_) }) -join "`u{1F}"
        [void]$rows.Add($joined)
    }
    if ($rows.Count -eq 1) {
        $first = ($rows[0] -split "`u{1F}")[0]
        if ($first -eq '_none yet_') { $rows.Clear() }
    }
    $script:ScRows = $rows
}

# script:Sc-BulletValue START END LABEL -> the value of a
# "- **LABEL:** value" bullet line in [START,END); '' if not found.
function script:Sc-BulletValue {
    param([int]$Start, [int]$End, [string]$Label)
    $pattern = '^-\s*\*\*' + [regex]::Escape($Label) + ':\*\*\s*(.*)$'
    for ($i = $Start; $i -lt $End; $i++) {
        if ($script:ScLines[$i] -match $pattern) {
            return (script:Sc-Trim $Matches[1])
        }
    }
    return ''
}

# script:Sc-InterviewHeader START END -> sets $script:ScInterviewState /
# $script:ScInterviewGrade from a "**State:** X  **Grade:** Y" bold line;
# returns $false (both left '') if not found.
function script:Sc-InterviewHeader {
    param([int]$Start, [int]$End)
    $script:ScInterviewState = ''
    $script:ScInterviewGrade = ''
    for ($i = $Start; $i -lt $End; $i++) {
        if ($script:ScLines[$i] -match '^\*\*State:\*\*(.*)\*\*Grade:\*\*(.*)$') {
            $script:ScInterviewState = (script:Sc-Trim $Matches[1])
            $script:ScInterviewGrade = (script:Sc-Trim $Matches[2])
            return $true
        }
    }
    return $false
}

# script:Sc-IsPlaceholderItem ITEM -> $true iff ITEM is the TEMPLATE's own
# un-instantiated example row still sitting in a never-touched section (a
# literal '{...}' token) rather than real authored content -- the same
# construct the readers' own placeholder-skip treats as unfilled, not data.
function script:Sc-IsPlaceholderItem {
    param([string]$Item)
    return ($Item -match '\{[^}]*\}')
}

# script:Sc-IssueList START END -> sets $script:ScIssues, one severity-
# tagged string per issue, mirroring writeback-state.sh's own (pre-existing)
# parse_issue_list_block for the shape:
#   - **Issue List:** none | {first item inline}
#     {one further item per line, or nothing}
function script:Sc-IssueList {
    param([int]$Start, [int]$End)
    $issues = [System.Collections.Generic.List[string]]::new()
    $inList = $false
    for ($i = $Start; $i -lt $End; $i++) {
        $line = $script:ScLines[$i]
        if (-not $inList) {
            if ($line -match '^-\s*\*\*Issue\sList:\*\*\s*(.*)$') {
                $inList = $true
                $rest = $Matches[1]
                if ($rest -and $rest -ne 'none') {
                    $item = $rest
                    if ($item.StartsWith('- ')) { $item = $item.Substring(2) }
                    if ($item -and -not (script:Sc-IsPlaceholderItem $item)) { [void]$issues.Add($item) }
                }
            }
            continue
        }
        $trimmed = script:Sc-Trim $line
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($trimmed -eq '---') { continue }
        $item = $trimmed
        if ($item.StartsWith('- ')) { $item = $item.Substring(2) }
        if ($item -eq 'none') { continue }
        if (script:Sc-IsPlaceholderItem $item) { continue }
        [void]$issues.Add($item)
    }
    $script:ScIssues = $issues
}

# script:Sc-Findings START END -> sets $script:ScTier (scalar) and
# $script:ScFindings, mirroring writeback-state.sh's own (pre-existing)
# parse_findings_block for the shape:
#   - **Reviewer Tier:** Small
#   - **Findings:**
#     - [HIGH] description -- source:line -- Deferred-to-gate
function script:Sc-Findings {
    param([int]$Start, [int]$End)
    $script:ScTier = ''
    $findings = [System.Collections.Generic.List[string]]::new()
    for ($i = $Start; $i -lt $End; $i++) {
        $line = $script:ScLines[$i]
        if ($line -match '^-\s*\*\*Reviewer\sTier:\*\*\s*(.*)$') {
            # Strip a trailing "(...)" doc annotation -- the template's own
            # never-touched default line is literally "Small (quick check
            # always uses Small tier)"; the enum value is the bare token
            # before the parenthetical, which the real writer emits alone.
            $raw = $Matches[1]
            $parenIdx = $raw.IndexOf('(')
            if ($parenIdx -ge 0) { $raw = $raw.Substring(0, $parenIdx) }
            $script:ScTier = (script:Sc-Trim $raw)
            continue
        }
        if ($line -match '^-\s*\*\*Findings:\*\*\s*(.*)$') { continue }
        $trimmed = script:Sc-Trim $line
        if (-not $trimmed.StartsWith('- ')) { continue }
        $item = $trimmed.Substring(2)
        if ([string]::IsNullOrEmpty($item) -or $item -eq 'none') { continue }
        if (script:Sc-IsPlaceholderItem $item) { continue }
        [void]$findings.Add($item)
    }
    $script:ScFindings = $findings
}

# script:Sc-QaEntries START END -> sets $script:ScQa, one element per
# "### Q{N}" block in [START,END), each a \x1F-joined tuple: id,category,
# impact,state,context,suggested,answer,applied_to.
function script:Sc-QaEntries {
    param([int]$Start, [int]$End)
    $qa = [System.Collections.Generic.List[string]]::new()
    $qidx = [System.Collections.Generic.List[int[]]]::new()
    for ($i = $Start; $i -lt $End; $i++) {
        if ($script:ScLines[$i] -match '^###\s+Q(\d+)\s*$') {
            [void]$qidx.Add(@($i, [int]$Matches[1]))
        }
    }
    for ($k = 0; $k -lt $qidx.Count; $k++) {
        $qs = $qidx[$k][0]
        $qid = $qidx[$k][1]
        if ($k + 1 -lt $qidx.Count) { $qe = $qidx[$k + 1][0] } else { $qe = $End }
        $category  = script:Sc-BulletValue ($qs + 1) $qe 'Category'
        $impact    = script:Sc-BulletValue ($qs + 1) $qe 'Impact'
        $qstate    = script:Sc-BulletValue ($qs + 1) $qe 'State'
        $context   = script:Sc-BulletValue ($qs + 1) $qe 'Context'
        $suggested = script:Sc-BulletValue ($qs + 1) $qe 'Suggested'
        $answer    = script:Sc-BulletValue ($qs + 1) $qe 'Answer'
        $applied   = script:Sc-BulletValue ($qs + 1) $qe 'Applied to'
        [void]$qa.Add(($qid, $category, $impact, $qstate, $context, $suggested, $answer, $applied) -join "`u{1F}")
    }
    $script:ScQa = $qa
}

# script:Sc-YamlScalar VALUE -> the SPEC.md SS D-5-compliant scalar token for
# VALUE -- bare, single-quoted (embedded ' doubled), or double-quoted with
# the five-escape subset (\" \\ \n \r \t) when VALUE carries a literal
# newline/CR/tab.
function script:Sc-YamlScalar {
    param([string]$V)
    if ($V -match "[\n\r\t]") {
        $esc = $V
        $esc = $esc.Replace('\', '\\')
        $esc = $esc.Replace('"', '\"')
        $esc = $esc.Replace("`r", '\r')
        $esc = $esc.Replace("`n", '\n')
        $esc = $esc.Replace("`t", '\t')
        return '"' + $esc + '"'
    }
    if ([string]::IsNullOrEmpty($V)) { return "''" }
    if ($V -match '^[A-Za-z0-9_.+/-]+$') {
        $denyList = @('y','Y','yes','Yes','YES','n','N','no','No','NO','true','True','TRUE',
            'false','False','FALSE','on','On','ON','off','Off','OFF','null','Null','NULL','~')
        $isNumericLike = ($V -match '^[0-9]' -or $V -match '^[-+][0-9]')
        if (($denyList -notcontains $V) -and (-not $isNumericLike)) {
            return $V
        }
    }
    $q = $V.Replace("'", "''")
    return "'" + $q + "'"
}

# ---- AUTHORED-zone emitters. Each appends lines to $script:ScOut and, where
# the source is a list/table, records its row count into a $script:ScCnt*
# counter consumed by script:Sc-VerifyRoundtrip. ----

function script:Sc-EmitInterview {
    param([int]$Start, [int]$End)
    $hstate = 'Pending'; $hgrade = 'Pending'
    if (script:Sc-InterviewHeader $Start $End) {
        if ($script:ScInterviewState) { $hstate = $script:ScInterviewState }
        if ($script:ScInterviewGrade) { $hgrade = $script:ScInterviewGrade }
    }
    script:Sc-TableRows $Start $End
    $script:ScCntInterview = $script:ScRows.Count
    [void]$script:ScOut.Add('interview:')
    [void]$script:ScOut.Add('  state: ' + (script:Sc-YamlScalar $hstate))
    [void]$script:ScOut.Add('  grade: ' + (script:Sc-YamlScalar $hgrade))
    if ($script:ScRows.Count -eq 0) {
        [void]$script:ScOut.Add('  sections: []')
        return
    }
    [void]$script:ScOut.Add('  sections:')
    foreach ($row in $script:ScRows) {
        $c = $row -split "`u{1F}"
        [void]$script:ScOut.Add('    - id: ' + $c[0])
        [void]$script:ScOut.Add('      name: ' + (script:Sc-YamlScalar $c[1]))
        [void]$script:ScOut.Add('      state: ' + (script:Sc-YamlScalar $c[2]))
        [void]$script:ScOut.Add('      updated: ' + (script:Sc-YamlScalar $c[3]))
    }
}

function script:Sc-EmitLifecycleHistory {
    param([int]$Start, [int]$End)
    script:Sc-TableRows $Start $End
    $script:ScCntLfh = $script:ScRows.Count
    if ($script:ScRows.Count -eq 0) {
        [void]$script:ScOut.Add('lifecycle_history: []')
        return
    }
    [void]$script:ScOut.Add('lifecycle_history:')
    foreach ($row in $script:ScRows) {
        $c = $row -split "`u{1F}"
        [void]$script:ScOut.Add('  - date: ' + (script:Sc-YamlScalar $c[0]))
        [void]$script:ScOut.Add('    event: ' + (script:Sc-YamlScalar $c[1]))
        [void]$script:ScOut.Add('    grade: ' + (script:Sc-YamlScalar $c[2]))
        [void]$script:ScOut.Add('    notes: ' + (script:Sc-YamlScalar $c[3]))
    }
}

function script:Sc-EmitDeploy {
    param([int]$Start, [int]$End)
    script:Sc-TableRows $Start $End
    $script:ScCntDeploy = $script:ScRows.Count
    if ($script:ScRows.Count -eq 0) {
        [void]$script:ScOut.Add('deploy: []')
        return
    }
    [void]$script:ScOut.Add('deploy:')
    foreach ($row in $script:ScRows) {
        $c = $row -split "`u{1F}"
        [void]$script:ScOut.Add('  - delivery: ' + (script:Sc-YamlScalar $c[0]))
        [void]$script:ScOut.Add('    state: ' + (script:Sc-YamlScalar $c[1]))
        [void]$script:ScOut.Add('    pr: ' + (script:Sc-YamlScalar $c[2]))
        [void]$script:ScOut.Add('    kb_updated: ' + (script:Sc-YamlScalar $c[3]))
        [void]$script:ScOut.Add('    tag: ' + (script:Sc-YamlScalar $c[4]))
        [void]$script:ScOut.Add('    notes: ' + (script:Sc-YamlScalar $c[5]))
    }
}

function script:Sc-EmitDeliveryLifecycle {
    param([int]$Start, [int]$End)
    $updated = script:Sc-BulletValue $Start $End 'Updated'
    $blockReason = script:Sc-BulletValue $Start $End 'Block Reason'
    $blockArtifact = script:Sc-BulletValue $Start $End 'Block Artifact'
    if ([string]::IsNullOrEmpty($updated)) { $updated = '--' }
    if ([string]::IsNullOrEmpty($blockReason)) { $blockReason = '--' }
    if ([string]::IsNullOrEmpty($blockArtifact)) { $blockArtifact = '--' }
    [void]$script:ScOut.Add('delivery_lifecycle:')
    [void]$script:ScOut.Add('  updated: ' + (script:Sc-YamlScalar $updated))
    [void]$script:ScOut.Add('  block_reason: ' + (script:Sc-YamlScalar $blockReason))
    [void]$script:ScOut.Add('  block_artifact: ' + (script:Sc-YamlScalar $blockArtifact))
}

function script:Sc-EmitTasksLifecycle {
    param([int]$Start, [int]$End)
    script:Sc-TableRows $Start $End
    $script:ScCntTasksLc = $script:ScRows.Count
    if ($script:ScRows.Count -eq 0) {
        [void]$script:ScOut.Add('tasks_lifecycle: {}')
        return
    }
    [void]$script:ScOut.Add('tasks_lifecycle:')
    foreach ($row in $script:ScRows) {
        $c = $row -split "`u{1F}"
        [void]$script:ScOut.Add('  ' + $c[0] + ':')
        [void]$script:ScOut.Add('    state: ' + (script:Sc-YamlScalar $c[1]))
        [void]$script:ScOut.Add('    review: ' + (script:Sc-YamlScalar $c[2]))
        [void]$script:ScOut.Add('    elapsed: ' + (script:Sc-YamlScalar $c[3]))
        [void]$script:ScOut.Add('    notes: ' + (script:Sc-YamlScalar $c[4]))
        [void]$script:ScOut.Add('    display_name: ' + (script:Sc-YamlScalar $c[5]))
    }
}

function script:Sc-EmitDeliveryGate {
    param([int]$Start, [int]$End)
    script:Sc-IssueList $Start $End
    $script:ScCntIssues = $script:ScIssues.Count
    [void]$script:ScOut.Add('delivery_gate:')
    if ($script:ScIssues.Count -eq 0) {
        [void]$script:ScOut.Add('  issue_list: []')
        return
    }
    [void]$script:ScOut.Add('  issue_list:')
    foreach ($it in $script:ScIssues) {
        [void]$script:ScOut.Add('    - ' + (script:Sc-YamlScalar $it))
    }
}

function script:Sc-EmitQa {
    param([int]$Start, [int]$End)
    script:Sc-QaEntries $Start $End
    $script:ScCntQa = $script:ScQa.Count
    if ($script:ScQa.Count -eq 0) {
        [void]$script:ScOut.Add('qa: []')
        return
    }
    [void]$script:ScOut.Add('qa:')
    foreach ($row in $script:ScQa) {
        $c = $row -split "`u{1F}"
        [void]$script:ScOut.Add('  - id: ' + $c[0])
        [void]$script:ScOut.Add('    category: ' + (script:Sc-YamlScalar $c[1]))
        [void]$script:ScOut.Add('    impact: ' + (script:Sc-YamlScalar $c[2]))
        [void]$script:ScOut.Add('    state: ' + (script:Sc-YamlScalar $c[3]))
        [void]$script:ScOut.Add('    context: ' + (script:Sc-YamlScalar $c[4]))
        [void]$script:ScOut.Add('    suggested: ' + (script:Sc-YamlScalar $c[5]))
        [void]$script:ScOut.Add('    answer: ' + (script:Sc-YamlScalar $c[6]))
        [void]$script:ScOut.Add('    applied_to: ' + (script:Sc-YamlScalar $c[7]))
    }
}

# ---- DERIVED-zone guards (SP-3). ----

function script:Sc-GuardDerivedTable {
    param([string]$Md, [string]$Heading, [int]$Start, [int]$End)
    $h = script:Sc-FindHeading $Heading $Start $End
    if ($h -lt 0) { return $true }
    $hend = script:Sc-SectionEnd $h $End
    script:Sc-TableRows ($h + 1) $hend
    if ($script:ScRows.Count -gt 0) {
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: DERIVED section '$Heading' holds real data -- conversion refused for this file (nothing dropped). Remedy: run migrate-work-hierarchy on this work, then re-run 'aid update'.")
        return $false
    }
    return $true
}

function script:Sc-GuardDerivedNarrative {
    param([string]$Md, [string]$Heading, [int]$Start, [int]$End)
    $h = script:Sc-FindHeading $Heading $Start $End
    if ($h -lt 0) { return $true }
    $hend = script:Sc-SectionEnd $h $End
    $inComment = $false
    for ($i = $h + 1; $i -lt $hend; $i++) {
        $trimmed = script:Sc-Trim $script:ScLines[$i]
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($trimmed -eq '---') { continue }
        if ($inComment) {
            if ($trimmed.Contains('-->')) { $inComment = $false }
            continue
        }
        if ($trimmed.StartsWith('<!--')) {
            if (-not $trimmed.Contains('-->')) { $inComment = $true }
            continue
        }
        if ($trimmed -match '^_None yet') { continue }
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: DERIVED section '$Heading' holds real data -- conversion refused for this file (nothing dropped). Remedy: run migrate-work-hierarchy on this work, then re-run 'aid update'.")
        return $false
    }
    return $true
}

# script:Sc-ConvertWorkBody MD LAYOUT BSTART BEND -> populates $script:ScOut
# with the work-level AUTHORED-zone YAML lines; returns $false on a
# DERIVED-guard hard error (SP-3).
function script:Sc-ConvertWorkBody {
    param([string]$Md, [string]$Layout, [int]$BStart, [int]$BEnd)
    $script:ScOut = [System.Collections.Generic.List[string]]::new()

    $hI = script:Sc-FindHeading '## Interview State' $BStart $BEnd
    if ($hI -ge 0) {
        $hIEnd = script:Sc-SectionEnd $hI $BEnd
        script:Sc-EmitInterview ($hI + 1) $hIEnd
    } else {
        [void]$script:ScOut.Add('interview:')
        [void]$script:ScOut.Add('  state: Pending')
        [void]$script:ScOut.Add('  grade: Pending')
        [void]$script:ScOut.Add('  sections: []')
    }

    $hL = script:Sc-FindHeading '## Lifecycle History' $BStart $BEnd
    if ($hL -ge 0) {
        $hLEnd = script:Sc-SectionEnd $hL $BEnd
        script:Sc-EmitLifecycleHistory ($hL + 1) $hLEnd
    } else {
        [void]$script:ScOut.Add('lifecycle_history: []')
    }

    $hD = script:Sc-FindHeading '## Deploy State' $BStart $BEnd
    if ($hD -ge 0) {
        $hDEnd = script:Sc-SectionEnd $hD $BEnd
        script:Sc-EmitDeploy ($hD + 1) $hDEnd
    } else {
        [void]$script:ScOut.Add('deploy: []')
    }

    if ($Layout -eq 'flat') {
        $hDl = script:Sc-FindHeading '## Delivery Lifecycle' $BStart $BEnd
        if ($hDl -ge 0) {
            $hDlEnd = script:Sc-SectionEnd $hDl $BEnd
            script:Sc-EmitDeliveryLifecycle ($hDl + 1) $hDlEnd

            $hTl = script:Sc-FindHeading '### Tasks lifecycle' $hDl $hDlEnd
            if ($hTl -ge 0) {
                $hTlEnd = script:Sc-SectionEnd $hTl $hDlEnd
                script:Sc-EmitTasksLifecycle ($hTl + 1) $hTlEnd
            } else {
                [void]$script:ScOut.Add('tasks_lifecycle: {}')
            }
        } else {
            [void]$script:ScOut.Add('delivery_lifecycle:')
            [void]$script:ScOut.Add('  updated: --')
            [void]$script:ScOut.Add('  block_reason: --')
            [void]$script:ScOut.Add('  block_artifact: --')
            [void]$script:ScOut.Add('tasks_lifecycle: {}')
        }

        $hG = script:Sc-FindHeading '## Delivery Gate' $BStart $BEnd
        if ($hG -ge 0) {
            $hGEnd = script:Sc-SectionEnd $hG $BEnd
            script:Sc-EmitDeliveryGate ($hG + 1) $hGEnd
        } else {
            [void]$script:ScOut.Add('delivery_gate:')
            [void]$script:ScOut.Add('  issue_list: []')
        }

        $hQ = script:Sc-FindHeading '## Cross-phase Q&A' $BStart $BEnd
        if ($hQ -ge 0) {
            $hQEnd = script:Sc-SectionEnd $hQ $BEnd
            script:Sc-EmitQa ($hQ + 1) $hQEnd
        } else {
            [void]$script:ScOut.Add('qa: []')
        }
    }

    $derivedTableHeadings = @('## Features State', '## Plan / Deliveries', '## Tasks State', '## Calibration Log')
    foreach ($dh in $derivedTableHeadings) {
        if (-not (script:Sc-GuardDerivedTable $Md $dh $BStart $BEnd)) { return $false }
    }
    $derivedNarrativeHeadings = @('## Delivery Gates', '## Dispatches')
    foreach ($dh in $derivedNarrativeHeadings) {
        if (-not (script:Sc-GuardDerivedNarrative $Md $dh $BStart $BEnd)) { return $false }
    }
    if ($Layout -eq 'full') {
        if (-not (script:Sc-GuardDerivedNarrative $Md '## Cross-phase Q&A' $BStart $BEnd)) { return $false }
    }

    return $true
}

# script:Sc-ConvertDeliveryBody MD BSTART BEND -> populates $script:ScOut
# with the delivery-level AUTHORED-zone YAML lines (full layout only);
# returns $false on a DERIVED-guard hard error.
function script:Sc-ConvertDeliveryBody {
    param([string]$Md, [int]$BStart, [int]$BEnd)
    $script:ScOut = [System.Collections.Generic.List[string]]::new()

    $hDl = script:Sc-FindHeading '## Delivery Lifecycle' $BStart $BEnd
    if ($hDl -ge 0) {
        $hDlEnd = script:Sc-SectionEnd $hDl $BEnd
        script:Sc-EmitDeliveryLifecycle ($hDl + 1) $hDlEnd
    } else {
        [void]$script:ScOut.Add('delivery_lifecycle:')
        [void]$script:ScOut.Add('  updated: --')
        [void]$script:ScOut.Add('  block_reason: --')
        [void]$script:ScOut.Add('  block_artifact: --')
    }

    $hG = script:Sc-FindHeading '## Delivery Gate' $BStart $BEnd
    if ($hG -ge 0) {
        $hGEnd = script:Sc-SectionEnd $hG $BEnd
        script:Sc-EmitDeliveryGate ($hG + 1) $hGEnd
    } else {
        [void]$script:ScOut.Add('delivery_gate:')
        [void]$script:ScOut.Add('  issue_list: []')
    }

    $hQ = script:Sc-FindHeading '## Cross-phase Q&A' $BStart $BEnd
    if ($hQ -ge 0) {
        $hQEnd = script:Sc-SectionEnd $hQ $BEnd
        script:Sc-EmitQa ($hQ + 1) $hQEnd
    } else {
        [void]$script:ScOut.Add('qa: []')
    }

    if (-not (script:Sc-GuardDerivedTable $Md '## Tasks State' $BStart $BEnd)) { return $false }
    return $true
}

# script:Sc-ConvertTaskBody MD BSTART BEND -> populates $script:ScOut with
# the task-level AUTHORED-zone YAML lines (full layout only). No DERIVED
# section exists at this level, so nothing is guarded.
function script:Sc-ConvertTaskBody {
    param([string]$Md, [int]$BStart, [int]$BEnd)
    $script:ScOut = [System.Collections.Generic.List[string]]::new()

    $hQc = script:Sc-FindHeading '## Quick Check Findings' $BStart $BEnd
    $tier = 'Small'
    if ($hQc -ge 0) {
        $hQcEnd = script:Sc-SectionEnd $hQc $BEnd
        script:Sc-Findings ($hQc + 1) $hQcEnd
        if ($script:ScTier) { $tier = (script:Sc-Trim $script:ScTier) }
    } else {
        $script:ScFindings = [System.Collections.Generic.List[string]]::new()
    }
    $script:ScCntFindings = $script:ScFindings.Count
    [void]$script:ScOut.Add('quick_check:')
    [void]$script:ScOut.Add('  reviewer_tier: ' + (script:Sc-YamlScalar $tier))
    if ($script:ScFindings.Count -eq 0) {
        [void]$script:ScOut.Add('  findings: []')
    } else {
        [void]$script:ScOut.Add('  findings:')
        foreach ($it in $script:ScFindings) {
            [void]$script:ScOut.Add('    - ' + (script:Sc-YamlScalar $it))
        }
    }

    $hDp = script:Sc-FindHeading '## Dispatch Log' $BStart $BEnd
    if ($hDp -ge 0) {
        $hDpEnd = script:Sc-SectionEnd $hDp $BEnd
        script:Sc-TableRows ($hDp + 1) $hDpEnd
    } else {
        $script:ScRows = [System.Collections.Generic.List[string]]::new()
    }
    $script:ScCntDispatch = $script:ScRows.Count
    if ($script:ScRows.Count -eq 0) {
        [void]$script:ScOut.Add('dispatch_log: []')
    } else {
        [void]$script:ScOut.Add('dispatch_log:')
        foreach ($row in $script:ScRows) {
            $c = $row -split "`u{1F}"
            [void]$script:ScOut.Add('  - date: ' + (script:Sc-YamlScalar $c[0]))
            [void]$script:ScOut.Add('    agent: ' + (script:Sc-YamlScalar $c[1]))
            [void]$script:ScOut.Add('    eta_band: ' + (script:Sc-YamlScalar $c[2]))
            [void]$script:ScOut.Add('    actual: ' + (script:Sc-YamlScalar $c[3]))
            [void]$script:ScOut.Add('    outcome: ' + (script:Sc-YamlScalar $c[4]))
        }
    }
    return $true
}

# ---- Round-trip verification (SP-12). ----

function script:Sc-YamlIndent {
    param([string]$S)
    $trimmed = $S.TrimStart()
    return ($S.Length - $trimmed.Length)
}

# script:Sc-YamlBlockRange KEYTEXT -> @(start,end) (0-indexed, into the
# script-scope $script:ScYLines list). KEYTEXT is matched right-trimmed
# only (its OWN leading whitespace is significant -- pass it exactly as
# written, e.g. "  issue_list:"). @(-1,-1) if not found.
function script:Sc-YamlBlockRange {
    param([string]$KeyText)
    for ($i = 0; $i -lt $script:ScYLines.Count; $i++) {
        $raw = $script:ScYLines[$i]
        if ($raw.TrimEnd() -eq $KeyText) {
            $keyIndent = script:Sc-YamlIndent $raw
            for ($j = $i + 1; $j -lt $script:ScYLines.Count; $j++) {
                $jl = $script:ScYLines[$j]
                $jtrim = script:Sc-Trim $jl
                if ([string]::IsNullOrEmpty($jtrim)) { continue }
                if ($jtrim.StartsWith('#')) { continue }
                $jindent = script:Sc-YamlIndent $jl
                if ($jindent -le $keyIndent) { return @(($i + 1), $j) }
            }
            return @(($i + 1), $script:ScYLines.Count)
        }
    }
    return @(-1, -1)
}

function script:Sc-YamlCountDashItems {
    param([int]$Start, [int]$End)
    $c = 0
    for ($i = $Start; $i -lt $End; $i++) {
        if ((script:Sc-Trim $script:ScYLines[$i]).StartsWith('- ')) { $c++ }
    }
    return $c
}

function script:Sc-YamlCountMapChildren {
    param([int]$Start, [int]$End)
    $minIndent = [int]::MaxValue
    for ($i = $Start; $i -lt $End; $i++) {
        $t = script:Sc-Trim $script:ScYLines[$i]
        if ([string]::IsNullOrEmpty($t) -or $t.StartsWith('#')) { continue }
        $ind = script:Sc-YamlIndent $script:ScYLines[$i]
        if ($ind -lt $minIndent) { $minIndent = $ind }
    }
    $c = 0
    for ($i = $Start; $i -lt $End; $i++) {
        $raw = $script:ScYLines[$i]
        $t = script:Sc-Trim $raw
        if ([string]::IsNullOrEmpty($t)) { continue }
        $ind = script:Sc-YamlIndent $raw
        if ($ind -ne $minIndent) { continue }
        if ($t.EndsWith(':')) { $c++ }
    }
    return $c
}

# script:Sc-YamlBlockCount KEYTEXT -> the sequence-item count (or, for
# "tasks_lifecycle:", the mapping-child count) under KEYTEXT in
# $script:ScYLines; 0 for an inline "KEYTEXT []"/"{}" or an absent key.
function script:Sc-YamlBlockCount {
    param([string]$KeyText)
    foreach ($raw in $script:ScYLines) {
        $rtrimmed = $raw.TrimEnd()
        if ($rtrimmed -eq "$KeyText []" -or $rtrimmed -eq "$KeyText {}") { return 0 }
    }
    $range = script:Sc-YamlBlockRange $KeyText
    $start = $range[0]; $bend = $range[1]
    if ($start -lt 0) { return 0 }
    $ktTrim = script:Sc-Trim $KeyText
    if ($ktTrim -eq 'tasks_lifecycle:') {
        return script:Sc-YamlCountMapChildren $start $bend
    }
    return script:Sc-YamlCountDashItems $start $bend
}

# script:Sc-VerifyRoundtrip MD CANDIDATE LEVEL LAYOUT -> $true iff CANDIDATE
# (a) is entirely composed of recognized SS D-3 shapes and (b) reproduces,
# for every list/table this converter targeted at LEVEL, the exact
# row/entry count captured while reading MD (the $script:ScCnt* counters
# set by the emitters above).
function script:Sc-VerifyRoundtrip {
    param([string]$Md, [string]$Candidate, [string]$Level, [string]$Layout)
    $script:ScYLines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $Candidate -Encoding utf8 -ErrorAction Stop)

    for ($i = 0; $i -lt $script:ScYLines.Count; $i++) {
        $line = $script:ScYLines[$i]
        $trimmed = script:Sc-Trim $line
        if ([string]::IsNullOrEmpty($trimmed)) { continue }
        if ($line.Contains("`t")) {
            [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: candidate STATE.yml line $($i+1) has a tab; round-trip verification failed")
            return $false
        }
        $ind = script:Sc-YamlIndent $line
        if (($ind % 2) -ne 0) {
            [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: candidate STATE.yml line $($i+1) has odd indentation; round-trip verification failed")
            return $false
        }
        if ($trimmed.StartsWith('#')) { continue }
        if ($trimmed.StartsWith('- ') -or $trimmed -eq '-') { continue }
        if ($trimmed -match '^[A-Za-z0-9_.-]+:(\s.*)?$') { continue }
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: candidate STATE.yml line $($i+1) is not a recognized key/sequence line; round-trip verification failed")
        return $false
    }

    $ok = $true
    switch ($Level) {
        'work' {
            if ((script:Sc-YamlBlockCount '  sections:') -ne $script:ScCntInterview) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on interview.sections count")
            }
            if ((script:Sc-YamlBlockCount 'lifecycle_history:') -ne $script:ScCntLfh) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on lifecycle_history count")
            }
            if ((script:Sc-YamlBlockCount 'deploy:') -ne $script:ScCntDeploy) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on deploy count")
            }
            if ($Layout -eq 'flat') {
                if ((script:Sc-YamlBlockCount 'tasks_lifecycle:') -ne $script:ScCntTasksLc) {
                    $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on tasks_lifecycle count")
                }
                if ((script:Sc-YamlBlockCount '  issue_list:') -ne $script:ScCntIssues) {
                    $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on delivery_gate.issue_list count")
                }
                if ((script:Sc-YamlBlockCount 'qa:') -ne $script:ScCntQa) {
                    $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on qa count")
                }
            }
        }
        'delivery' {
            if ((script:Sc-YamlBlockCount '  issue_list:') -ne $script:ScCntIssues) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on delivery_gate.issue_list count")
            }
            if ((script:Sc-YamlBlockCount 'qa:') -ne $script:ScCntQa) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on qa count")
            }
        }
        'task' {
            if ((script:Sc-YamlBlockCount '  findings:') -ne $script:ScCntFindings) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on quick_check.findings count")
            }
            if ((script:Sc-YamlBlockCount 'dispatch_log:') -ne $script:ScCntDispatch) {
                $ok = $false; [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: round-trip mismatch on dispatch_log count")
            }
        }
    }
    return $ok
}

# script:Sc-ConvertFile MD YML LEVEL LAYOUT -> the per-file converter.
# Idempotent (no-op if YML already exists); fail-safe (the .md is deleted
# ONLY after the candidate .yml passes script:Sc-VerifyRoundtrip);
# WARN-not-fail (every failure path emits a WARN line and returns $false --
# the caller never propagates that past script:Sc-ConvertRepo, which
# always returns $true).
function script:Sc-ConvertFile {
    param([string]$Md, [string]$Yml, [string]$Level, [string]$Layout)

    if (-not (Test-Path -LiteralPath $Md -PathType Leaf)) { return $true }
    if (Test-Path -LiteralPath $Yml -PathType Leaf) { return $true }

    $script:ScLines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $Md -Encoding utf8 -ErrorAction Stop)

    $script:ScCntInterview = 0; $script:ScCntLfh = 0; $script:ScCntDeploy = 0; $script:ScCntTasksLc = 0
    $script:ScCntIssues = 0; $script:ScCntQa = 0; $script:ScCntFindings = 0; $script:ScCntDispatch = 0

    $n = $script:ScLines.Count
    if ($n -lt 2 -or $script:ScLines[0] -ne '---') {
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: no frontmatter fence found; skipped (STATE.md left in place)")
        return $false
    }
    $fmEnd = -1
    for ($i = 1; $i -lt $n; $i++) {
        if ($script:ScLines[$i] -eq '---') { $fmEnd = $i; break }
    }
    if ($fmEnd -lt 0) {
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: frontmatter block never closes; skipped (STATE.md left in place)")
        return $false
    }

    $fmLines = [System.Collections.Generic.List[string]]::new()
    for ($i = 1; $i -lt $fmEnd; $i++) { [void]$fmLines.Add($script:ScLines[$i]) }
    $bodyStart = $fmEnd + 1

    $converted = $true
    switch ($Level) {
        'work'     { $converted = script:Sc-ConvertWorkBody $Md $Layout $bodyStart $n }
        'delivery' { $converted = script:Sc-ConvertDeliveryBody $Md $bodyStart $n }
        'task'     { $converted = script:Sc-ConvertTaskBody $Md $bodyStart $n }
        default    {
            [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: unknown conversion level '$Level' (continuing)")
            $converted = $false
        }
    }
    if (-not $converted) { return $false }

    $tmp = Join-Path (Split-Path -Parent $Md) ('.state-convert.' + [System.IO.Path]::GetRandomFileName())
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $fmLines) { [void]$lines.Add($l) }
    [void]$lines.Add('')
    foreach ($l in $script:ScOut) { [void]$lines.Add($l) }
    try {
        [System.IO.File]::WriteAllText($tmp, (($lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
    } catch {
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: could not write candidate for ${Yml}: $_ (continuing)")
        return $false
    }

    if (-not (script:Sc-VerifyRoundtrip $Md $tmp $Level $Layout)) {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: failed round-trip verification; skipped (STATE.md left in place)")
        return $false
    }

    try {
        Move-Item -LiteralPath $tmp -Destination $Yml -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid migrate: ${Md}: could not write ${Yml}: $_ (continuing)")
        return $false
    }
    Remove-Item -LiteralPath $Md -Force -ErrorAction SilentlyContinue
    Write-Host "OK: aid migrate: ${Md} converted -> ${Yml}"
    return $true
}

# script:Sc-ConvertOneWork WORKDIR -> converts a single work's STATE.md and,
# on the full layout (a deliveries/ subfolder present), every
# deliveries/*/STATE.md and deliveries/*/tasks/*/STATE.md.
function script:Sc-ConvertOneWork {
    param([string]$WorkDir)
    $layout = 'flat'
    $deliveriesDir = Join-Path $WorkDir 'deliveries'
    if (Test-Path -LiteralPath $deliveriesDir -PathType Container) { $layout = 'full' }

    [void](script:Sc-ConvertFile (Join-Path $WorkDir 'STATE.md') (Join-Path $WorkDir 'STATE.yml') 'work' $layout)

    if ($layout -ne 'full') { return }

    Get-ChildItem -LiteralPath $deliveriesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $dd = $_.FullName
        [void](script:Sc-ConvertFile (Join-Path $dd 'STATE.md') (Join-Path $dd 'STATE.yml') 'delivery' $layout)

        $tasksDir = Join-Path $dd 'tasks'
        if (Test-Path -LiteralPath $tasksDir -PathType Container) {
            Get-ChildItem -LiteralPath $tasksDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $td = $_.FullName
                [void](script:Sc-ConvertFile (Join-Path $td 'STATE.md') (Join-Path $td 'STATE.yml') 'task' $layout)
            }
        }
    }
}

# script:Sc-ConvertRepo REPO -> the migration-engine STEP 5 entry point
# (called from Invoke-AidMigrateRepo). Converts every in-scope STATE.md
# under REPO/.aid/works/. Always succeeds (WARN-not-fail).
function script:Sc-ConvertRepo {
    param([string]$Repo)
    $worksDir = Join-Path (Join-Path $Repo '.aid') 'works'
    if (-not (Test-Path -LiteralPath $worksDir -PathType Container)) { return }
    Get-ChildItem -LiteralPath $worksDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        script:Sc-ConvertOneWork $_.FullName
    }
}

# script:Invoke-AidRepairSettingsEraA <SettingsFile> <RepoName>
# Era-a: settings.yml already exists (either the OLD nested schema, or the
# NEW flat schema from a prior run of this same function). Read every value
# tolerantly -- NEW flat top-level location first, else the OLD nested
# location, else the documented default -- then rewrite the file from
# scratch in the NEW flat schema (format_version 3).
# This is a full read-then-rewrite, not a targeted line-edit, so the
# function is naturally idempotent (re-running it on its own output
# reproduces byte-identical content) and flattens an old nested file in a
# single pass. Crash-safe: same-directory temp + Move-Item -Force; skips the
# write entirely when the rebuilt content equals the original (re-normalized
# to LF) content.
function script:Invoke-AidRepairSettingsEraA {
    param([string]$SettingsFile, [string]$RepoName)
    if (-not (Test-Path $SettingsFile -PathType Leaf)) { throw "settings file not found" }

    $lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $SettingsFile -Encoding utf8 -ErrorAction Stop)
    $origJoined = ($lines -join "`n") + "`n"

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

    # ---- get scalar value from a "key: value" or "  key: value" line ----
    # (\s* -- not \s+ -- so this also reads NEW-flat column-0 keys.)
    $getScalarValue = {
        param([string]$ln, [string]$key)
        $v = ($ln -replace "^\s*${key}:\s*", '') -replace '\s*#.*$', ''
        $v = $v.Trim().Trim('"').Trim("'")
        return $v
    }

    # ---- read a NEW-flat top-level "^key:<rest>" scalar. Sets $found.Value
    # when the key line is present at column 0 (value may be empty). ----
    $topScalar = {
        param([string]$key, [ref]$found)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^${key}:") {
                if ($found) { $found.Value = $true }
                return (& $getScalarValue $lines[$i] $key)
            }
        }
        if ($found) { $found.Value = $false }
        return ''
    }

    # ---- read an OLD-nested "<section>.<key>" scalar. Sets $found.Value
    # when both the section and the key are present. ----
    $nestedScalar = {
        param([string]$sect, [string]$key, [ref]$found)
        $sidx = & $findSection $sect
        if ($sidx -eq -1) { if ($found) { $found.Value = $false }; return '' }
        $kidx = & $findKeyInSection $sidx $key
        if ($kidx -eq -1) { if ($found) { $found.Value = $false }; return '' }
        if ($found) { $found.Value = $true }
        return (& $getScalarValue $lines[$kidx] $key)
    }

    # ---- trim surrounding whitespace + one layer of matching quotes ----
    $trimQuote = {
        param([string]$s)
        $s = $s.Trim()
        if ($s.Length -ge 2 -and $s.StartsWith('"') -and $s.EndsWith('"')) {
            $s = $s.Substring(1, $s.Length - 2)
        } elseif ($s.Length -ge 2 -and $s.StartsWith("'") -and $s.EndsWith("'")) {
            $s = $s.Substring(1, $s.Length - 2)
        }
        return $s
    }

    # ---- list reader: given a section index + key, return an array of items
    # (one per element). Supports inline "[a, b]" and block "- a" / "- b"
    # forms. Returns an empty array when the key is absent / resolves empty. ----
    $readListInSection = {
        param([int]$sectIdx, [string]$key)
        $kidx = & $findKeyInSection $sectIdx $key
        if ($kidx -eq -1) { return @() }
        $ln  = $lines[$kidx]
        $val = ($ln -replace "^\s*${key}:\s*", '') -replace '\s*#.*$', ''
        $val = $val.Trim()
        $items = @()
        if ($val -match '^\[.*\]$') {
            $inner = $val.Substring(1, $val.Length - 2)
            foreach ($it in ($inner -split ',')) {
                $clean = & $trimQuote $it
                if ($clean) { $items += $clean }
            }
        } elseif ([string]::IsNullOrEmpty($val)) {
            $keyIndent = $ln.Length - $ln.TrimStart().Length
            for ($i = $kidx + 1; $i -lt $lines.Count; $i++) {
                $bl = $lines[$i]
                if ($bl.Trim().Length -gt 0) {
                    $blIndent = $bl.Length - $bl.TrimStart().Length
                    if ($blIndent -le $keyIndent) { break }
                }
                if ($bl -match '^\s*-\s*(.+)$') {
                    $item = & $trimQuote $Matches[1]
                    if ($item) { $items += $item }
                }
            }
        }
        return $items
    }

    # ---- list resolver -- try (sectA,keyA) then (sectB,keyB); first
    # non-empty list wins; returns an empty array when neither has one. ----
    $resolveList = {
        param([string]$sectA, [string]$keyA, [string]$sectB, [string]$keyB)
        $sidx = & $findSection $sectA
        if ($sidx -ne -1) {
            $items = @(& $readListInSection $sidx $keyA)
            if ($items.Count -gt 0) { return $items }
        }
        $sidx = & $findSection $sectB
        if ($sidx -ne -1) {
            $items = @(& $readListInSection $sidx $keyB)
            if ($items.Count -gt 0) { return $items }
        }
        return @()
    }

    # ------------------------------------------------------------------
    # Resolve each REQUIRED top-level scalar: NEW-flat top-level location
    # wins, else the OLD-nested location, else the documented default.
    # A found-but-invalid value is treated the same as absent (repair).
    # ------------------------------------------------------------------

    # name: blank is not a valid name -- fall through to the next source.
    $name = & $topScalar 'name' ([ref]$null)
    if ([string]::IsNullOrEmpty($name)) {
        $name = & $nestedScalar 'project' 'name' ([ref]$null)
        if ([string]::IsNullOrEmpty($name)) { $name = $RepoName }
    }

    # description: presence (not non-emptiness) decides -- an explicit empty
    # description ("") is a valid final value, matching the target schema.
    $descFoundTop = $false
    $description = & $topScalar 'description' ([ref]$descFoundTop)
    if (-not $descFoundTop) {
        $descFoundNested = $false
        $description = & $nestedScalar 'project' 'description' ([ref]$descFoundNested)
        if (-not $descFoundNested) { $description = '' }
    }

    # type: must be brownfield|greenfield; else fall through / default.
    $type = & $topScalar 'type' ([ref]$null)
    if ($type -ne 'brownfield' -and $type -ne 'greenfield') {
        $type = & $nestedScalar 'project' 'type' ([ref]$null)
        if ($type -ne 'brownfield' -and $type -ne 'greenfield') { $type = 'brownfield' }
    }

    # source_control: top-level value if valid, else detect from .git presence.
    # <repo> is two levels above <repo>\.aid\settings.yml.
    $sourceControl = & $topScalar 'source_control' ([ref]$null)
    if ($sourceControl -ne 'none' -and $sourceControl -ne 'git' `
       -and $sourceControl -ne 'svn' -and $sourceControl -ne 'mercurial') {
        $repoDir = Split-Path (Split-Path $SettingsFile -Parent) -Parent
        if (Test-Path (Join-Path $repoDir '.git') -PathType Container) {
            $sourceControl = 'git'
        } else {
            $sourceControl = 'none'
        }
    }

    # minimum_grade: top-level, else review.minimum_grade, else default A.
    $minimumGrade = & $topScalar 'minimum_grade' ([ref]$null)
    if ($minimumGrade -notmatch '^[A-F][+-]?$') {
        $minimumGrade = & $nestedScalar 'review' 'minimum_grade' ([ref]$null)
        if ($minimumGrade -notmatch '^[A-F][+-]?$') { $minimumGrade = 'A' }
    }

    # heartbeat_interval: top-level, else traceability.heartbeat_interval, else 1.
    $heartbeatInterval = & $topScalar 'heartbeat_interval' ([ref]$null)
    if ($heartbeatInterval -notmatch '^\d+$') {
        $heartbeatInterval = & $nestedScalar 'traceability' 'heartbeat_interval' ([ref]$null)
        if ($heartbeatInterval -notmatch '^\d+$') { $heartbeatInterval = '1' }
    }

    # ------------------------------------------------------------------
    # Resolve the OPTIONAL knowledge block. knowledge.source/last_update fall
    # back to kb_baseline.branch/tip_date; doc_set/term_exclusions fall back
    # to discovery.doc_set/discovery.term_exclusions. The whole block is
    # omitted when none of the four sub-values are present.
    # ------------------------------------------------------------------
    $knSource = & $nestedScalar 'knowledge' 'source' ([ref]$null)
    if ([string]::IsNullOrEmpty($knSource)) { $knSource = & $nestedScalar 'kb_baseline' 'branch' ([ref]$null) }

    $knLastUpdate = & $nestedScalar 'knowledge' 'last_update' ([ref]$null)
    if ([string]::IsNullOrEmpty($knLastUpdate)) { $knLastUpdate = & $nestedScalar 'kb_baseline' 'tip_date' ([ref]$null) }

    $knDocSet = @(& $resolveList 'knowledge' 'doc_set' 'discovery' 'doc_set')
    $knTermExclusions = @(& $resolveList 'knowledge' 'term_exclusions' 'discovery' 'term_exclusions')

    $haveKnowledge = ((-not [string]::IsNullOrEmpty($knSource)) -or (-not [string]::IsNullOrEmpty($knLastUpdate)) `
        -or ($knDocSet.Count -gt 0) -or ($knTermExclusions.Count -gt 0))

    # ------------------------------------------------------------------
    # Build the NEW flat output, then write only if it differs from the
    # original (re-normalized) content.
    # ------------------------------------------------------------------
    $out = [System.Collections.Generic.List[string]]::new()
    [void]$out.Add("format_version: $($script:AidSupportedFormat)")
    [void]$out.Add("name: ${name}")
    if ([string]::IsNullOrEmpty($description)) {
        [void]$out.Add('description: ""')
    } else {
        [void]$out.Add("description: ${description}")
    }
    [void]$out.Add("type: ${type}")
    [void]$out.Add("source_control: ${sourceControl}")
    [void]$out.Add("minimum_grade: ${minimumGrade}")
    [void]$out.Add("heartbeat_interval: ${heartbeatInterval}")

    if ($haveKnowledge) {
        [void]$out.Add('')
        [void]$out.Add('knowledge:')
        if (-not [string]::IsNullOrEmpty($knSource)) { [void]$out.Add("  source: ${knSource}") }
        if (-not [string]::IsNullOrEmpty($knLastUpdate)) { [void]$out.Add("  last_update: ${knLastUpdate}") }
        if ($knDocSet.Count -gt 0) {
            [void]$out.Add('  doc_set:')
            foreach ($dsi in $knDocSet) { [void]$out.Add("    - ${dsi}") }
        }
        if ($knTermExclusions.Count -gt 0) {
            [void]$out.Add('  term_exclusions:')
            foreach ($tei in $knTermExclusions) { [void]$out.Add("    - ${tei}") }
        }
    }

    $newContent = (($out.ToArray()) -join "`n") + "`n"
    if ($newContent -eq $origJoined) { return }

    $sfDir = Split-Path $SettingsFile -Parent
    $tmp   = Join-Path $sfDir ("settings.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        [System.IO.File]::WriteAllText($tmp, $newContent, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $SettingsFile -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw
    }
}

# script:Invoke-AidSynthesizeSettingsEraB <SettingsFile> <RepoName> <ManifestPath>
# Era-b: write a fresh settings.yml (NEW flat schema, format_version 3) when
# none exists yet. name = <RepoName>; description = ""; type = brownfield;
# source_control = detected (.git present -> git, else none); minimum_grade
# = A; heartbeat_interval = 1. No knowledge block (nothing to carry forward).
# <ManifestPath> is accepted for call-site parity (tools/AID-version now live
# only in the manifest -- never written into settings) but is otherwise
# unused here. Crash-safe: same-directory temp + Move-Item -Force.
function script:Invoke-AidSynthesizeSettingsEraB {
    param([string]$SettingsFile, [string]$RepoName, [string]$ManifestPath)

    $repoDir = Split-Path (Split-Path $SettingsFile -Parent) -Parent
    $sourceControl = if (Test-Path (Join-Path $repoDir '.git') -PathType Container) { 'git' } else { 'none' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("format_version: $($script:AidSupportedFormat)`n")
    [void]$sb.Append("name: ${RepoName}`n")
    [void]$sb.Append("description: `"`"`n")
    [void]$sb.Append("type: brownfield`n")
    [void]$sb.Append("source_control: ${sourceControl}`n")
    [void]$sb.Append("minimum_grade: A`n")
    [void]$sb.Append("heartbeat_interval: 1`n")

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
    # Check for 'update all' as first positional arg (work-001-update-all / task-001).
    # Consumed here -- alongside 'self' -- BEFORE the generic add/remove/update flag
    # loop and BEFORE the non-'self' positional rejection (FR10, below), so 'all' is
    # never treated as an unknown positional (SPEC AC9).
    if ($script:_RemArgs.Count -gt 0 -and $script:_RemArgs[0] -eq 'all') {
        $uaRc = script:Invoke-AidUpdateAll -RemArgs @($script:_RemArgs | Select-Object -Skip 1)
        script:Exit-Aid $uaRc
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
# Chat node control (aid chat node start|stop|status) -- the PowerShell twin of
# _cmd_chat_ctl in bin/aid. Behaviour, messages and exit codes are the same by
# requirement, not by coincidence: the CLI parity gate compares them.
#
# Exit codes REUSE the established meanings rather than minting new ones:
#   8  the node is already running          (same as `aid dashboard start`)
#   9  no usable Node runtime on PATH       (same as the dashboard's runtime check)
#   2  usage error
#   1  runtime failure
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Chat message plane -- the PowerShell twin of _cmd_chat_plane in bin/aid.
# One HTTP call per verb into the one core; no rule and no SQL here.
# Exit codes: 0 ok | 14 the node refused a well-formed request | 2 usage | 1 runtime.
# ---------------------------------------------------------------------------
function script:Get-AidChatBaseUrl {
    $rtDir = if ($env:AID_CHAT_RUNTIME) { $env:AID_CHAT_RUNTIME } else { Join-Path $HOME '.aid\chat' }
    $portFile = Join-Path $rtDir 'hub.port'
    if (-not (Test-Path -LiteralPath $portFile -PathType Leaf)) { return $null }
    $p = (Get-Content -LiteralPath $portFile -Raw).Trim()
    if (-not $p) { return $null }
    return "http://127.0.0.1:$p"
}

# One place that turns the node's answer into output plus an exit code, so no verb invents its
# own convention. stdout carries the result; stderr carries the diagnostic.
function script:Invoke-AidChatCall {
    param([string]$Method, [string]$Path, [string]$Body = $null)

    $base = script:Get-AidChatBaseUrl
    if (-not $base) {
        [Console]::Error.WriteLine("ERROR: aid: chat: the node is not running; run 'aid chat node start' first.")
        return 1
    }
    try {
        # Bounded, for the same reason the Bash twin is: an address that accepts nothing must make the
        # command FAIL rather than stop. Invoke-WebRequest has no default timeout.
        $args = @{ Uri = "$base$Path"; Method = $Method; UseBasicParsing = $true; ErrorAction = 'Stop'
                   TimeoutSec = 30 }
        if ($Body) { $args.Body = $Body; $args.ContentType = 'application/json' }
        $resp = Invoke-WebRequest @args
        Write-Output $resp.Content
        return 0
    } catch [System.Net.WebException], [Microsoft.PowerShell.Commands.HttpResponseException] {
        $r = $_.Exception.Response
        if (-not $r) {
            [Console]::Error.WriteLine("ERROR: aid: chat: the node is not reachable; run 'aid chat node start' first.")
            return 1
        }
        $code = [int]$r.StatusCode
        $text = ''
        try {
            $sr = New-Object System.IO.StreamReader($r.GetResponseStream())
            $text = $sr.ReadToEnd()
        } catch { $text = '' }
        switch ($code) {
            409 {
                $reason = if ($text -match '"reason":"([^"]*)"') { $Matches[1] } else { 'refused' }
                $detail = if ($text -match '"detail":"([^"]*)"') { $Matches[1] } else { $null }
                # A retry hint is the one part of a refusal a caller must ACT on rather than
                # report, so it has to reach the caller -- otherwise the jitter exists in the node
                # and the livelock it prevents is still there for every agent using this surface.
                $retry  = if ($text -match '"retry_after_ms":([0-9]+)') { $Matches[1] } else { $null }
                $line = $reason
                if ($detail) { $line = "${line}: ${detail}" }
                if ($retry)  { $line = "${line} (retry after ${retry}ms)" }
                [Console]::Error.WriteLine($line)
                # Also on stdout as JSON, so a program can read it without parsing prose.
                Write-Output $text
                return 14
            }
            400 { [Console]::Error.WriteLine("ERROR: aid: chat: the request was malformed: $text"); return 2 }
            default { [Console]::Error.WriteLine("ERROR: aid: chat: the node answered ${code}: $text"); return 1 }
        }
    }
}

function script:ConvertTo-AidJsonString { param([string]$Value)
    if ($null -eq $Value) { return '' }
    return $Value.Replace('\', '\\').Replace('"', '\"').Replace("`n", '\n')
}

# One armed wait, and whatever it returns turned into one line of JSON on stdout. The PowerShell
# twin of _aid_chat_wait_once in bin/aid.
function script:Invoke-AidChatWaitOnce {
    param([string]$Name, [string]$HostTimeout)

    $base = script:Get-AidChatBaseUrl
    if (-not $base) {
        [Console]::Error.WriteLine("ERROR: aid: chat subscribe: the node is not running; run 'aid chat node start' first.")
        return 1
    }

    # READ BEFORE WAITING, for the same reason the adapter does: a message that arrived while this
    # session was busy is already in the store and is not going to "arrive" again. Going straight to
    # the wait would block, time out, and leave it unread until some later message happened to land
    # while this was listening -- which is the whole busy path silently missing.
    try {
        $pending = Invoke-WebRequest -Uri "$base/messages?name=$Name" -UseBasicParsing -ErrorAction Stop -TimeoutSec 30
        $pj = $pending.Content | ConvertFrom-Json
        if ($pj.messages -and $pj.messages.Count -gt 0) {
            # The same shape the Bash twin emits for a backlog read, field for field.
            $merged = [ordered]@{
                ok = $true; kind = 'message'; from_backlog = $true
                messages = $pj.messages; delivered_seq = $pj.delivered_seq; acked_seq = $pj.acked_seq
            }
            Write-Output ($merged | ConvertTo-Json -Compress -Depth 6)
            return 0
        }
    } catch {
        # A failed pending read is not fatal: fall through to the wait.
    }

    $q = "/wait?name=$Name"
    if ($HostTimeout) { $q = "$q&host_timeout=$HostTimeout" }
    try {
        # Generously bounded: the held wait is SUPPOSED to block, so this must exceed the node's own
        # block rather than compete with it.
        $resp = Invoke-WebRequest -Uri "$base$q" -UseBasicParsing -ErrorAction Stop -TimeoutSec 120
        $wake = $resp.Content | ConvertFrom-Json
        if ($wake.kind -eq 'message') {
            $inbox = (Invoke-WebRequest -Uri "$base/messages?name=$Name" -UseBasicParsing -ErrorAction Stop -TimeoutSec 30).Content | ConvertFrom-Json
            # EVERY field the server sent is carried, not a fixed list of them. Copying a chosen set
            # meant a field added to the wake -- `from_backlog`, say, or the next one -- would appear
            # in the Bash twin's output and silently not in this one, and an adapter reading the two
            # would behave differently on Windows for no reason it could see.
            $merged = [ordered]@{}
            foreach ($prop in $wake.PSObject.Properties) { $merged[$prop.Name] = $prop.Value }
            $merged['messages']      = $inbox.messages
            $merged['delivered_seq'] = $inbox.delivered_seq
            $merged['acked_seq']     = $inbox.acked_seq
            Write-Output ($merged | ConvertTo-Json -Compress -Depth 6)
        } else {
            Write-Output $resp.Content
        }
        return 0
    } catch {
        [Console]::Error.WriteLine("ERROR: aid: chat subscribe: the wait failed: $($_.Exception.Message)")
        return 1
    }
}

# The session name, when the caller did not give one -- the PowerShell twin of
# _aid_chat_default_name. See that function for why this exists: the rendered skill told an agent to
# pass a variable nothing set, so following it produced an empty name and an error.
function script:Get-AidChatDefaultName {
    if ($env:AID_CHAT_SESSION) { return $env:AID_CHAT_SESSION }
    $base = Split-Path -Leaf $PWD.Path
    # Keep it to what a name may contain, so a directory with spaces or punctuation still yields a
    # usable identity rather than a quoting problem for every later command.
    $base = ($base -replace '[^A-Za-z0-9._-]', '-').Trim('-')
    if (-not $base) { $base = 'session' }
    return $base
}

# `aid chat hook` -- the PowerShell twin. Generates the stop-hook block and checks an installed one,
# and like the Bash twin it WRITES NOTHING: AID writes no host tool's configuration.
function script:Invoke-AidChatHook {
    param([string[]]$HookArgs)

    $tool = ''; $timeout = 60; $action = 'print'
    for ($i = 0; $i -lt $HookArgs.Count; $i++) {
        switch ($HookArgs[$i]) {
            '--tool'    { $tool = $HookArgs[$i + 1]; $i++ }
            '--timeout' { $timeout = [int]$HookArgs[$i + 1]; $i++ }
            '--check'   { $action = 'check' }
            default {
                [Console]::Error.WriteLine("ERROR: aid: chat hook: unknown option '$($HookArgs[$i])'")
                return 2
            }
        }
    }
    if (-not $tool) { [Console]::Error.WriteLine('ERROR: aid: chat hook: --tool is required (claude-code | cursor)'); return 2 }
    if ($tool -notin @('claude-code', 'cursor')) {
        [Console]::Error.WriteLine("ERROR: aid: chat hook: no adapter ships for '$tool'; that host falls back to 'aid chat inbox'.")
        return 2
    }
    if ($timeout -lt 10) { [Console]::Error.WriteLine('ERROR: aid: chat hook: --timeout must be at least 10 seconds'); return 2 }

    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) { [Console]::Error.WriteLine('ERROR: aid: chat hook: no node on PATH; install Node (>= 22.13.0) first.'); return 1 }
    # The resolved path, because a PATH entry may be a shim that re-launches the real interpreter as a
    # child -- leaving the host watching a process unrelated to the one that blocks.
    $nodePath = ($nodeCmd.Source -replace '\\', '/')
    $adapter = (Join-Path $script:_AidCodeHome "chat-node/adapters/$tool.mjs") -replace '\\', '/'
    $cfg = if ($tool -eq 'claude-code') { Join-Path $HOME '.claude/settings.json' } else { Join-Path $HOME '.cursor/settings.json' }

    if (-not (Test-Path -LiteralPath $adapter -PathType Leaf)) {
        [Console]::Error.WriteLine("ERROR: aid: chat hook: adapter missing at $adapter; reinstall aid.")
        return 1
    }

    if ($action -eq 'check') {
        if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) {
            [Console]::Error.WriteLine("aid: chat hook: no hook installed -- $cfg does not exist.")
            [Console]::Error.WriteLine("  Run 'aid chat hook --tool $tool' and paste what it prints into that file.")
            return 1
        }
        $raw = Get-Content -LiteralPath $cfg -Raw
        $problems = @()
        if ($raw -notmatch [regex]::Escape("adapters/$tool.mjs")) {
            [Console]::Error.WriteLine("aid: chat hook: no chat stop hook found in $cfg.")
            [Console]::Error.WriteLine("  Run 'aid chat hook --tool $tool' and paste what it prints.")
            return 1
        }
        $flag  = [regex]::Match($raw, '--host-timeout\s+(\d+)')
        $field = [regex]::Match($raw, '"timeout"\s*:\s*(\d+)')
        if (-not $flag.Success)  { $problems += 'the command has no --host-timeout, so the adapter falls back to a short block' }
        if (-not $field.Success) { $problems += 'the hook has no "timeout" field, so the host uses its own default -- which is not measured' }
        if ($flag.Success -and $field.Success -and $flag.Groups[1].Value -ne $field.Groups[1].Value) {
            $problems += ("the numbers DISAGREE: timeout=" + $field.Groups[1].Value + " but --host-timeout=" + $flag.Groups[1].Value +
                          '. This fails silently -- no error, just a wake that never arrives')
        }
        if ($raw -match '"fail_closed"\s*:\s*true|"blocking"\s*:\s*true') {
            $problems += 'fail-closed is set; a hook that must succeed can freeze the session it belongs to'
        }
        if ($problems.Count -gt 0) {
            [Console]::Error.WriteLine('aid: chat hook: the installed hook has problems:')
            foreach ($p in $problems) { [Console]::Error.WriteLine("  - $p") }
            return 1
        }
        Write-Host "aid: chat hook: the hook in $cfg looks correct (timeout $($field.Groups[1].Value)s, matched on both sides)."
        return 0
    }

    $marginS   = [int](([int]($env:AID_CHAT_ADAPTER_MARGIN_MS | ForEach-Object { if ($_) { $_ } else { 5000 } })) / 1000)
    $longPollS = [int](([int]($env:AID_CHAT_LONG_POLL_MS | ForEach-Object { if ($_) { $_ } else { 30000 } })) / 1000)
    $block = $timeout - $marginS
    if ($block -gt $longPollS) { $block = $longPollS }

    Write-Host "# Paste the block below into:"
    Write-Host "#   $cfg"
    Write-Host '#'
    Write-Host "# Nothing writes it for you: AID writes no host tool's configuration, because a project-scoped"
    Write-Host '# config file is tracked in git and would put this hook into every contributor''s checkout.'
    Write-Host '#'
    Write-Host "# The two numbers are already matched. With timeout ${timeout}: the node blocks ${block}s, the adapter"
    Write-Host "# guards just under ${timeout}s, and your host gives up at ${timeout}s -- in that order."
    Write-Host '# There is no session name in the command: the adapter derives it from the working directory.'
    Write-Host '#'
    Write-Host '# Do NOT set this hook to fail closed. Its normal behaviour is to block and return with nothing.'
    if ($tool -eq 'claude-code') {
        Write-Host @"
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "timeout": $timeout,
            "command": "$nodePath $adapter --host-timeout $timeout"
          }
        ]
      }
    ]
  }
}
"@
    } else {
        Write-Host @"
{
  "hooks": {
    "stop": [
      {
        "command": "$nodePath $adapter --host-timeout $timeout",
        "timeout": $timeout
      }
    ]
  }
}
"@
    }
    Write-Host ""
    Write-Host "Then check it with:  aid chat hook --tool $tool --check"
    return 0
}

function script:Invoke-AidChatPlane {
    param([string]$Verb, [string[]]$PlaneArgs)

    $name = ''
    $body = ''; $channel = ''; $cursor = ''; $key = ''; $whisper = ''; $mention = ''; $tool = ''
    $replyTo = ''; $corr = ''; $target = ''; $hostTimeout = ''; $follow = $false
    $machine = ''; $peerAction = 'list'; $limit = ''; $setting = ''
    for ($i = 0; $i -lt $PlaneArgs.Count; $i++) {
        $needsValue = $true
        switch ($PlaneArgs[$i]) {
            '--name'       { $name    = $PlaneArgs[$i + 1] }
            '--body'       { $body    = $PlaneArgs[$i + 1] }
            '--channel'    { $channel = $PlaneArgs[$i + 1] }
            '--cursor'     { $cursor  = $PlaneArgs[$i + 1] }
            '--key'        { $key     = $PlaneArgs[$i + 1] }
            '--whisper-to' { $whisper = $PlaneArgs[$i + 1] }
            '--mention'    { $mention = $PlaneArgs[$i + 1] }
            '--target'     { $target  = $PlaneArgs[$i + 1] }
            '--host-timeout' { $hostTimeout = $PlaneArgs[$i + 1] }
            '--reply-to'   { $replyTo = $PlaneArgs[$i + 1] }
            '--correlation-id' { $corr = $PlaneArgs[$i + 1] }
            '--tool'       { $tool    = $PlaneArgs[$i + 1] }
            # A bare switch: it takes no value, so it must NOT consume the next argument. Handling
            # it inside the switch with $needsValue is what keeps that correct -- checking for it
            # after the index has already advanced would read the wrong element.
            '--follow'     { $follow  = $true; $needsValue = $false }
            '--machine'    { $machine = $PlaneArgs[$i + 1] }
            '--limit'      { $limit   = $PlaneArgs[$i + 1] }
            '--set'        { $setting = $PlaneArgs[$i + 1] }
            '--add'        { $peerAction = 'add';      $needsValue = $false }
            '--remove'     { $peerAction = 'remove';   $needsValue = $false }
            '--discover'   { $peerAction = 'discover'; $needsValue = $false }
            default {
                [Console]::Error.WriteLine("ERROR: aid: chat ${Verb}: unknown option '$($PlaneArgs[$i])'")
                return 2
            }
        }
        if ($needsValue) { $i++ }
    }
    # These are operator-facing and belong to no session -- except `evict`, which names the session
    # being removed.
    if ($Verb -in @('show', 'audit', 'retention') -and -not $name) { $name = 'operator' }
    # No name given: derive one, so the skill's commands work as written and the operator's hook line
    # is identical for every session.
    if (-not $name -and $Verb -ne 'peers') { $name = script:Get-AidChatDefaultName }
    # `peers` is operator-facing and belongs to no session, so it is exempt from the name rule.
    if (-not $name -and $Verb -ne 'peers') {
        [Console]::Error.WriteLine("ERROR: aid: chat ${Verb}: --name is required (or set AID_CHAT_SESSION)")
        return 2
    }
    $n = script:ConvertTo-AidJsonString $name

    switch ($Verb) {
        'register' {
            # Echoed when the name was DERIVED, so whoever ran this learns what identity they have.
            if (-not $env:AID_CHAT_SESSION) {
                [Console]::Error.WriteLine("aid: chat: registered as ${n} (derived from this directory; set AID_CHAT_SESSION or pass --name to choose)")
            }
            $t = if ($tool) { $tool } elseif ($env:AID_CHAT_TOOL) { $env:AID_CHAT_TOOL } else { 'unknown' }
            return script:Invoke-AidChatCall 'POST' '/session' `
                ('{"name":"' + $n + '","tool":"' + (script:ConvertTo-AidJsonString $t) + '","cwd":"' + (script:ConvertTo-AidJsonString $PWD.Path) + '"}')
        }
        'heartbeat' { return script:Invoke-AidChatCall 'POST' '/session/heartbeat' ('{"name":"' + $n + '"}') }
        'reap' {
            # Operator-facing: give a session up for gone now, or sweep every session already
            # past the reap threshold. The RULE lives in the node; the schedule is retention's.
            if ($name -eq '--all') { return script:Invoke-AidChatCall 'POST' '/session/reap' '{}' }
            return script:Invoke-AidChatCall 'POST' '/session/reap' ('{"name":"' + $n + '"}')
        }
        'open' {
            if (-not $channel) { [Console]::Error.WriteLine('ERROR: aid: chat open: --channel is required'); return 2 }
            return script:Invoke-AidChatCall 'POST' '/channel' ('{"name":"' + $n + '","channel":"' + (script:ConvertTo-AidJsonString $channel) + '"}')
        }
        'join' {
            if (-not $channel) { [Console]::Error.WriteLine('ERROR: aid: chat join: --channel is required'); return 2 }
            return script:Invoke-AidChatCall 'POST' '/channel/join' ('{"name":"' + $n + '","channel":"' + (script:ConvertTo-AidJsonString $channel) + '"}')
        }
        'leave' { return script:Invoke-AidChatCall 'POST' '/channel/leave' ('{"name":"' + $n + '"}') }
        'list'  { return script:Invoke-AidChatCall 'GET' ("/channels?name=$n") }
        'roster' { return script:Invoke-AidChatCall 'GET' ("/roster?name=$n") }
        'show'  { return script:Invoke-AidChatCall 'GET' '/status/detail' }
        'audit' {
            if ($limit) { return script:Invoke-AidChatCall 'GET' ("/audit?limit=$limit") }
            return script:Invoke-AidChatCall 'GET' '/audit'
        }
        'evict' { return script:Invoke-AidChatCall 'POST' '/evict' ('{"name":"' + $n + '"}') }
        'retention' {
            if (-not $setting) { return script:Invoke-AidChatCall 'GET' '/retention' }
            $parts = $setting -split '=', 2
            if ($parts.Count -ne 2) { [Console]::Error.WriteLine('ERROR: aid: chat retention: --set expects key=value'); return 2 }
            return script:Invoke-AidChatCall 'POST' '/retention' ('{"' + (script:ConvertTo-AidJsonString $parts[0]) + '":' + $parts[1] + '}')
        }
        'peers' {
            # Operator-facing, and the GUARANTEED discovery path: naming an address depends on no
            # network feature. --discover is best-effort on top and finds nothing on a network with
            # broadcast disabled, which is why it is never the only way to reach a peer.
            switch ($peerAction) {
                'add' {
                    if (-not $machine) { [Console]::Error.WriteLine('ERROR: aid: chat peers --add: --machine is required'); return 2 }
                    return script:Invoke-AidChatCall 'POST' '/peers' ('{"machine":"' + (script:ConvertTo-AidJsonString $machine) + '"}')
                }
                'remove' {
                    if (-not $machine) { [Console]::Error.WriteLine('ERROR: aid: chat peers --remove: --machine is required'); return 2 }
                    return script:Invoke-AidChatCall 'POST' '/peers/remove' ('{"machine":"' + (script:ConvertTo-AidJsonString $machine) + '"}')
                }
                'discover' { return script:Invoke-AidChatCall 'POST' '/peers/discover' '{}' }
                default    { return script:Invoke-AidChatCall 'GET' '/peers' }
            }
        }
        'subscribe' {
            # THE WAIT COSTS NO MODEL TOKENS, and that is a property of what this is rather than a
            # claim about it: a PowerShell function blocking on a web request. There is no model in
            # the path to spend anything.
            #
            # ONE WAIT PER INVOCATION by default, because the documented hook command is exactly
            # this line: the host fires its stop hook, this runs, it returns, and the host fires it
            # again next time. --follow is for a standalone subscriber that re-arms itself.
            do {
                $rc = script:Invoke-AidChatWaitOnce -Name $n -HostTimeout $hostTimeout
                if ($rc -ne 0) { return $rc }
            } while ($follow)
            return 0
        }
        'connect' {
            if (-not $target) { [Console]::Error.WriteLine('ERROR: aid: chat connect: --target is required'); return 2 }
            # No channel parameter: the channel is the one the caller is already in, which is why
            # a request always pulls a target into a conversation its asker is present in.
            return script:Invoke-AidChatCall 'POST' '/connect' ('{"name":"' + $n + '","target":"' + (script:ConvertTo-AidJsonString $target) + '"}')
        }
        'send' {
            if (-not $body) { [Console]::Error.WriteLine('ERROR: aid: chat send: --body is required'); return 2 }
            $payload = '{"name":"' + $n + '","body":"' + (script:ConvertTo-AidJsonString $body) + '"'
            if ($key)     { $payload += ',"idempotency_key":"' + (script:ConvertTo-AidJsonString $key) + '"' }
            if ($whisper) { $payload += ',"whisper_to":"' + (script:ConvertTo-AidJsonString $whisper) + '"' }
            if ($mention) { $payload += ',"mention":["' + (script:ConvertTo-AidJsonString $mention) + '"]' }
            if ($replyTo) { $payload += ',"reply_to":"' + (script:ConvertTo-AidJsonString $replyTo) + '"' }
            if ($corr)    { $payload += ',"correlation_id":"' + (script:ConvertTo-AidJsonString $corr) + '"' }
            $payload += '}'
            return script:Invoke-AidChatCall 'POST' '/messages' $payload
        }
        'inbox' {
            if ($cursor) { return script:Invoke-AidChatCall 'GET' ("/messages?name=$n&cursor=$cursor") }
            return script:Invoke-AidChatCall 'GET' ("/messages?name=$n")
        }
        'ack' {
            if (-not $cursor) { [Console]::Error.WriteLine('ERROR: aid: chat ack: --cursor is required'); return 2 }
            return script:Invoke-AidChatCall 'POST' '/messages/ack' ('{"name":"' + $n + '","cursor":' + $cursor + '}')
        }
        default { [Console]::Error.WriteLine("ERROR: aid: chat: unknown verb '$Verb'"); return 2 }
    }
}

function script:Invoke-AidChatCtl {
    param([string[]]$CcArgs)

    $action = if ($CcArgs.Count -ge 1) { $CcArgs[0] } else { '' }
    # The message-plane verbs are handled first; `node ...` is the lifecycle surface.
    if ($action -eq 'hook') {
        $hookArgs = @()
        if ($CcArgs.Count -gt 1) { $hookArgs = $CcArgs[1..($CcArgs.Count - 1)] }
        script:Exit-Aid (script:Invoke-AidChatHook -HookArgs $hookArgs)
    }
    if ($action -in @('register','heartbeat','open','join','leave','list','send','inbox','ack','reap','roster','connect','subscribe','peers','show','audit','evict','retention')) {
        $planeArgs = @()
        if ($CcArgs.Count -gt 1) { $planeArgs = $CcArgs[1..($CcArgs.Count - 1)] }
        script:Exit-Aid (script:Invoke-AidChatPlane -Verb $action -PlaneArgs $planeArgs)
    }
    $rest   = @()
    if ($action -eq 'node') {
        $action = if ($CcArgs.Count -ge 2) { $CcArgs[1] } else { '' }
        if ($CcArgs.Count -gt 2) { $rest = $CcArgs[2..($CcArgs.Count - 1)] }
    } elseif ($CcArgs.Count -gt 1) {
        $rest = $CcArgs[1..($CcArgs.Count - 1)]
    }

    if ($action -in @('', '-h', '--help')) { script:Show-AidUsage 'chat'; script:Exit-Aid 0 }
    if ($action -notin @('start', 'stop', 'status')) {
        [Console]::Error.WriteLine("ERROR: aid: chat: unknown action '$action' (expected a message verb, or: node start | node stop | node status)")
        script:Exit-Aid 2
    }

    $rtDir = if ($env:AID_CHAT_RUNTIME) { $env:AID_CHAT_RUNTIME } else { Join-Path $HOME '.aid\chat' }
    $pidFile  = Join-Path $rtDir 'hub.pid'
    $portFile = Join-Path $rtDir 'hub.port'

    $hubPid = $null
    if (Test-Path -LiteralPath $pidFile -PathType Leaf) {
        $hubPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    }
    # A recorded pid that is not alive is a STALE record, not a running node -- reclaiming it
    # silently is what makes `start` safe to run without checking first (FR-1.1).
    $alive = $false
    if ($hubPid) {
        $alive = [bool](Get-Process -Id ([int]$hubPid) -ErrorAction SilentlyContinue)
    }
    $port = ''
    if (Test-Path -LiteralPath $portFile -PathType Leaf) {
        $port = (Get-Content -LiteralPath $portFile -Raw).Trim()
    }

    switch ($action) {
        'status' {
            if ($alive) {
                Write-Host "aid: chat node running (pid $hubPid, http://127.0.0.1:$(if ($port) { $port } else { 'unknown' }))"
                script:Exit-Aid 0
            }
            if ($hubPid) { Write-Host "aid: chat node not running (stale record for pid $hubPid)" }
            else         { Write-Host 'aid: chat node not running' }
            script:Exit-Aid 0
        }
        'stop' {
            if (-not $alive) {
                Write-Host 'aid: chat node not running.'
                Remove-Item -LiteralPath $pidFile, $portFile -Force -ErrorAction SilentlyContinue
                script:Exit-Aid 0
            }
            Stop-Process -Id ([int]$hubPid) -ErrorAction SilentlyContinue
            $w = 0
            while ($w -lt 50 -and (Get-Process -Id ([int]$hubPid) -ErrorAction SilentlyContinue)) {
                Start-Sleep -Milliseconds 100; $w++
            }
            if (Get-Process -Id ([int]$hubPid) -ErrorAction SilentlyContinue) {
                Stop-Process -Id ([int]$hubPid) -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $pidFile, $portFile -Force -ErrorAction SilentlyContinue
            Write-Host 'aid: chat node stopped.'
            script:Exit-Aid 0
        }
        'start' {
            if ($alive) {
                Write-Host "aid: chat node already running (pid $hubPid, http://127.0.0.1:$(if ($port) { $port } else { 'unknown' })); run 'aid chat node stop' first."
                script:Exit-Aid 8
            }
            if ($hubPid) { Remove-Item -LiteralPath $pidFile, $portFile -Force -ErrorAction SilentlyContinue }

            # The Node prerequisite, checked BEFORE any side effect, with an actionable error
            # and never a stack trace (FR-7.7). The CLI itself is runtime-free, so a missing
            # runtime must fail only the component that needs one.
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                [Console]::Error.WriteLine('ERROR: aid: chat: the chat node requires a Node runtime and none was found on PATH.')
                [Console]::Error.WriteLine("       Install Node (>= 22.13.0) and re-run. Every other 'aid' command keeps working without it.")
                script:Exit-Aid 9
            }

            $entry = Join-Path $script:_AidCodeHome 'chat-node\server\hub.mjs'
            if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) {
                [Console]::Error.WriteLine("ERROR: aid: chat: the chat node is missing from the install tree (expected $entry). Reinstall aid.")
                script:Exit-Aid 7
            }

            $portArg = if ($env:AID_CHAT_PORT) { $env:AID_CHAT_PORT } else { '8812' }
            for ($i = 0; $i -lt $rest.Count; $i++) {
                if ($rest[$i] -eq '--port') {
                    if ($i + 1 -ge $rest.Count) { [Console]::Error.WriteLine('ERROR: aid: chat: --port requires a value'); script:Exit-Aid 2 }
                    $portArg = $rest[$i + 1]; $i++
                } else {
                    [Console]::Error.WriteLine("ERROR: aid: chat: unknown option '$($rest[$i])'"); script:Exit-Aid 2
                }
            }
            $portInt = 0
            if (-not [int]::TryParse($portArg, [ref]$portInt) -or
                ($portInt -ne 0 -and ($portInt -lt 1024 -or $portInt -gt 65535))) {
                [Console]::Error.WriteLine('ERROR: aid: chat: --port must be 0 or an integer in 1024..65535')
                script:Exit-Aid 2
            }

            New-Item -ItemType Directory -Path $rtDir -Force | Out-Null
            # Detached, so the node outlives the shell that started it (FR-1.2).
            Start-Process -FilePath 'node' -ArgumentList @($entry, '--port', $portArg) `
                -WindowStyle Hidden -RedirectStandardOutput (Join-Path $rtDir 'hub.log') `
                -RedirectStandardError (Join-Path $rtDir 'hub.err.log') | Out-Null
            $s = 0
            while ($s -lt 50 -and -not (Test-Path -LiteralPath $portFile -PathType Leaf)) {
                Start-Sleep -Milliseconds 100; $s++
            }
            if (Test-Path -LiteralPath $portFile -PathType Leaf) {
                $p = (Get-Content -LiteralPath $portFile -Raw).Trim()
                Write-Host "aid: chat node started (http://127.0.0.1:$p)"
                script:Exit-Aid 0
            }
            [Console]::Error.WriteLine("ERROR: aid: chat: the node did not report a listening port; see $(Join-Path $rtDir 'hub.log')")
            script:Exit-Aid 1
        }
    }
}

# ---------------------------------------------------------------------------
# dashboard
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'dashboard') {
    script:Invoke-AidDashboardCtl -DcArgs $script:_RemArgs
    script:Exit-Aid $LASTEXITCODE
}

# ---------------------------------------------------------------------------
# chat
# ---------------------------------------------------------------------------
if ($SUBCMD -eq 'chat') {
    script:Invoke-AidChatCtl -CcArgs $script:_RemArgs
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
            { $_ -in @('list', 'add', 'remove', 'scan', 'help') } {
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
                # Unknown flag (incl. scan-specific --path/--all/--dry-run/
                # --depth/--include-network/--include-removable): pass through
                # to Invoke-AidProjects for parsing/rejection.
                $_ProjArgs.Add($a)
                break
            }
            default {
                [Console]::Error.WriteLine("ERROR: aid projects: unknown action: $a (expected: list, add, remove, scan, help)")
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
                        [Console]::Error.WriteLine("ERROR: aid add: -Version $_AidVersionArg would create a mixed-version project.")
                        [Console]::Error.WriteLine("       Existing tools are at v$_fr11ExistingVer. Either:")
                        [Console]::Error.WriteLine("         - Omit -Version to install at the project version (v$_fr11ExistingVer), or")
                        [Console]::Error.WriteLine("         - Run 'aid update -Version $_AidVersionArg' first to advance the whole project.")
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
                            Write-Host "project is at v$_fr11ExistingVer; new tool(s) installed at v$_fr11ExistingVer to keep the project uniform. Run 'aid update' to advance all tools to v$_fr11CliVer."
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
                    [Console]::Error.WriteLine("       The project may be at mixed versions. Re-run 'aid update' to heal.")
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
