#Requires -Version 5.1
# install.ps1 - AID installer bootstrap (PowerShell 5.1+).
#
# Purpose:
#   Bootstrap / install the persistent global `aid` CLI and (optionally) add
#   an AID profile to the current project in a single command.
#
# Usage:
#   .\install.ps1
#       Install the global aid CLI into $AID_HOME (%LOCALAPPDATA%\aid by default)
#       and wire PATH.  No project install - run 'aid add <tool>' afterwards.
#
#   .\install.ps1 <subcommand> [args]
#       Bootstrap the CLI (if not already installed), then immediately run
#       'aid <subcommand> [args]' in the current directory.
#       Subcommands: status add remove update version help
#       Examples:
#         .\install.ps1 add codex -FromBundle .\aid-codex-v0.7.0.tar.gz
#         .\install.ps1 status
#
#   .\install.ps1 -UninstallCli [-Force]
#       Remove the global aid CLI (PATH wiring + $AID_HOME).  Fallback for
#       when 'aid' is not yet on PATH.
#
#   .\install.ps1 -Help
#       Print this help and exit 0.
#
# Parameters:
#   -Version <v>           Pin to a specific release version (e.g. 0.7.0 or v0.7.0).
#                          Mutually exclusive with -FromBundle.
#   -FromBundle <path>     Offline install from a pre-downloaded tarball (single tool) or
#                          a directory of tarballs (comma-list).  No network.
#   -Force                 Overwrite files that exist and differ, including root agent files.
#   -Verbose               Print per-file Copied:/Up to date:/Updated:/Removed: lines.
#                          Default: concise per-tool summary only.
#   -UninstallCli          Remove the global aid CLI (PATH wiring + $AID_HOME).
#   -NoPath                Skip PATH wiring during bootstrap (new mode only).
#   -Help                  Print this help and exit 0.
#
# Environment variables (installer options):
#   AID_TOOL       - tool arg for 'aid add' (bootstrap convenience mode).
#   AID_VERSION    - equivalent to -Version.
#   AID_TARGET     - equivalent to -TargetDirectory.
#   AID_FORCE      - set to '1' or 'true' to enable -Force.
#   AID_VERBOSE    - set to '1' to enable -Verbose.
#   AID_NO_PATH    - set to '1' to skip PATH wiring (same as -NoPath).
#
# Environment variables (bootstrap/lib fetch):
#   AID_HOME       - override global install dir (default: %LOCALAPPDATA%\aid).
#   AID_LIB_PATH   - absolute path to AidInstallCore.psm1 (test override or vendored).
#   AID_LIB_BASE   - base URL prefix for remote module fetch.
#   AID_SUMS_URL   - override URL for SHA256SUMS verification.
#   AID_LIB_VERSION - pin the lib fetch to a specific release version.
#   AID_INSECURE_SKIP_LIB_VERIFY - set to '1' to skip lib checksum (INSECURE).
#   AID_CLI_BUNDLE_URL  - direct URL for the CLI bundle tarball (test/override).
#   AID_CLI_BUNDLE_BASE - base URL for CLI bundle fetch (default: release download base).
#
# Exit codes:
#   0   success
#   1   generic runtime failure
#   2   usage error (unknown param, bad args, ambiguous tool, missing target, etc.)
#   3   network / fetch failure
#   4   checksum verification failed
#   6   uninstall with no manifest (nothing installed)
#   7   aid status: no AID install in cwd

[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Version          = '',
    [string]$FromBundle       = '',
    [switch]$Force,
    [switch]$UninstallCli,
    # -Uninstall (without "Cli") is a removed legacy flag.  Declared here - but never
    # acted on - purely so PowerShell's parameter-prefix matching does not silently
    # alias a stray "-Uninstall" to -UninstallCli; see the mode-detection block below,
    # which routes it to USAGE_ERROR instead.
    [switch]$Uninstall,
    [switch]$NoPath,
    [switch]$Help,
    # Catch-all for unknown/positional parameters: with PositionalBinding disabled,
    # every bare word (subcommand, tool name, ...) and any unrecognised flag (the
    # removed -Tool/-Update/-TargetDirectory, etc.) lands here -> exit 2 (usage error)
    # unless the first word is a known subcommand.
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$RemainingArgs  = @()
)

# Treat unhandled exceptions as fatal exit 1.
$ErrorActionPreference = 'Stop'

# Enable TLS 1.2 for HTTPS. Windows PowerShell 5.1 (.NET Framework) can default to
# SSL3/TLS1.0, which GitHub/npm/pypi reject -> downloads fail. Harmless on PS7/.NET Core.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

# ---------------------------------------------------------------------------
# Piped-mode detection.
#
# When invoked as a real script file (`pwsh -File install.ps1` or `.\install.ps1`),
# $PSCommandPath / $MyInvocation.MyCommand.Path is set.
# When invoked via `irm <url> | iex` or `& ([scriptblock]::Create(...))`, the script
# runs inside the caller's runspace and $PSCommandPath is empty.
#
# In piped mode, calling `exit <N>` terminates the HOST session (closes the user's
# terminal).  Instead we set $global:LASTEXITCODE and throw a private sentinel
# exception that unwinds cleanly to the outermost catch block, which then returns.
#
# NOTE: bash install.sh does NOT need this guard - `curl | bash` runs in a subshell
# so `exit` is correct there.  This asymmetry is intentional: the goal (host/terminal
# survives) is the same; the mechanism differs because PowerShell `iex` runs in-process.
# ---------------------------------------------------------------------------
$script:_PipedMode = [string]::IsNullOrEmpty($PSCommandPath)

# Private sentinel type for clean unwind in piped mode.
# We use a uniquely-named string to avoid collisions.
$script:_SentinelTag = '__AidInstallExit__'

# script:Exit-Install <code>
# In file mode  : calls `exit <code>` (process exit, returns the code to the caller).
# In piped mode : sets $global:LASTEXITCODE = <code> and throws the sentinel exception
#                 so the host session survives.  The outermost try/catch catches it and
#                 returns cleanly.
function script:Exit-Install {
    param([int]$Code)
    if ($script:_PipedMode) {
        $global:LASTEXITCODE = $Code
        throw "$($script:_SentinelTag)$Code"
    } else {
        exit $Code
    }
}

# ---------------------------------------------------------------------------
# Locate the directory containing this script.
# When piped via irm | iex, $MyInvocation.MyCommand.Path is null/empty - guard.
# ---------------------------------------------------------------------------
$script:_InstallPs1Path = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($script:_InstallPs1Path)) {
    $ScriptDir = (Get-Location).Path
} else {
    $ScriptDir = Split-Path -Parent $script:_InstallPs1Path
}
$LibDir = Join-Path $ScriptDir 'lib'

# ---------------------------------------------------------------------------
# Usage helper (prints the header block as plain text).
# ---------------------------------------------------------------------------
function Show-Usage {
    # Extract lines 2..65 of this script (the header comment), strip leading '# '.
    # Use $script:_InstallPs1Path captured at load time to avoid $MyInvocation scoping issues.
    # When piped ($script:_InstallPs1Path is null), emit a minimal usage stub (FR9 parity
    # with install.sh piped-stub).
    if ([string]::IsNullOrEmpty($script:_InstallPs1Path)) {
        Write-Host "install.ps1 - AID installer bootstrap (PowerShell 5.1+)."
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  .\install.ps1                              Install global aid CLI"
        Write-Host "  .\install.ps1 <subcommand> [args]           Bootstrap + run aid <subcmd>"
        Write-Host "  .\install.ps1 -UninstallCli [-Force]        Remove global aid CLI"
        Write-Host "  .\install.ps1 -Help                         Print this help"
        Write-Host ""
        Write-Host "Subcommands: status add remove update version help"
        Write-Host ""
        Write-Host "Exit codes: 0 success, 1 failure, 2 usage error, 3 network error,"
        Write-Host "            4 checksum mismatch, 6 no manifest, 7 not an AID project"
        Write-Host ""
        Write-Host "Full docs: https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md"
        return
    }
    $lines = Get-Content -LiteralPath $script:_InstallPs1Path -ErrorAction SilentlyContinue
    if ($lines) {
        $lines[1..64] | ForEach-Object { $_ -replace '^# ?', '' } | Write-Host
    }
}

# ---------------------------------------------------------------------------
# Error helper.
# ---------------------------------------------------------------------------
function script:Fail {
    param([string]$Message, [int]$Code = 1)
    [Console]::Error.WriteLine("ERROR: install.ps1: $Message")
    script:Exit-Install $Code
}

# ---------------------------------------------------------------------------
# Outermost try/catch: wraps all logic so that in piped mode the sentinel
# exception is caught here and we return cleanly instead of killing the host.
# In file mode script:Exit-Install calls `exit` directly so this catch is
# never reached for normal exits.
# ---------------------------------------------------------------------------
try {

# ---------------------------------------------------------------------------
# -Help
# ---------------------------------------------------------------------------
if ($Help) {
    Show-Usage
    script:Exit-Install 0
}

# ---------------------------------------------------------------------------
# Resolve AID_VERBOSE: set from -Verbose common param ($VerbosePreference) or
# from $env:AID_VERBOSE.  Explicit -Verbose flag takes precedence.
# ---------------------------------------------------------------------------
$script:_AidVerbose = $false
if ($VerbosePreference -eq 'Continue') {
    $script:_AidVerbose = $true
} elseif ($env:AID_VERBOSE -eq '1') {
    $script:_AidVerbose = $true
}

# ---------------------------------------------------------------------------
# Apply env-var fallbacks for installer options.
# Precedence: explicit param > env var > auto-detect/default.
# ---------------------------------------------------------------------------
if (-not $Version -and $env:AID_VERSION) { $Version = $env:AID_VERSION }
if (-not $Force -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) {
    $Force = [switch]$true
}

# ---------------------------------------------------------------------------
# _AID_HOME_PRESET: snapshot whether AID_HOME was pre-set in the environment
# BEFORE install.ps1 ever defaults it.  This mirrors install.sh's
# _AID_HOME_PRESET="${AID_HOME:-}" captured before the first AID_HOME default.
# A real Administrator install.ps1 invocation (no AID_HOME in env) leaves this
# empty -> the provisioning hook runs.  A test that pins AID_HOME=<throwaway>
# leaves this non-empty -> the hook is skipped, protecting %ProgramData%\aid.
# Capture here before any script:Resolve-AidHome call that reads $env:AID_HOME.
# ---------------------------------------------------------------------------
$script:_AidHomePreset = if ($env:AID_HOME) { $env:AID_HOME } else { '' }

# ---------------------------------------------------------------------------
# Test-AidAdminPs1: returns $true when the current process has Administrator
# (or root-equivalent) elevation.  On Windows uses WindowsPrincipal;
# on non-Windows (Linux/macOS under pwsh) falls back to id -u == 0.
# ---------------------------------------------------------------------------
function script:Test-AidAdminPs1 {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $prin = [System.Security.Principal.WindowsPrincipal]$id
        return $prin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        # Non-Windows (Linux/macOS) - fall back to id -u.
        try {
            $uid = (& id -u 2>$null)
            return ($uid -eq '0')
        } catch {
            return $false
        }
    }
}

# ---------------------------------------------------------------------------
# Import the shared install core.
# Resolution order (first match wins):
#   1. AID_LIB_PATH env var - absolute path to the psm1 file (test override or vendored).
#   2. Sibling lib/AidInstallCore.psm1 - present when invoked as a local file.
#   3. Remote fetch (piped execution) - fix #12:
#      a. Resolve the release version (from -Version flag or GitHub API latest).
#      b. Fetch the lib from the IMMUTABLE release tag raw URL (not master).
#      c. Fetch SHA256SUMS from the same release tag.
#      d. Verify the lib's sha256 against SHA256SUMS - exit 4 on mismatch.
#      e. Import the verified module.
#      AID_LIB_BASE / AID_SUMS_URL env overrides allow hermetic tests without network.
# ---------------------------------------------------------------------------
$script:_AidTmpLibDir = $null
$script:_RemoteResolvedVer = ''   # set during remote lib-fetch; reused by CLI bundle fetch
$script:_RemoteSumsFile    = ''   # path to fetched SHA256SUMS; reused by CLI bundle fetch
$script:_AidCliBundleTmpDir = $null

function script:Cleanup-CliBundleTmp {
    if ($script:_AidCliBundleTmpDir -and (Test-Path $script:_AidCliBundleTmpDir -PathType Container)) {
        Remove-Item -LiteralPath $script:_AidCliBundleTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Fetch-And-Verify-CliBundlePs1 <resolvedVer> [<localSumsFile>]
# Fetches aid-cli-v<resolvedVer>.tar.gz, verifies sha256 against SHA256SUMS,
# extracts to a temp dir, sets $script:_AidCliBundleExtractDir.
# Honors AID_CLI_BUNDLE_URL, AID_CLI_BUNDLE_BASE, AID_INSECURE_SKIP_LIB_VERIFY.
# Exit codes via script:Exit-Install: 3 = fetch failure, 4 = checksum mismatch.
$script:_AidCliBundleExtractDir = $null

function script:Fetch-And-Verify-CliBundlePs1 {
    param([string]$ResolvedVer, [string]$LocalSumsFile = '')

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("aid-clibundle-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $script:_AidCliBundleTmpDir = $tmpDir

    $bundleFilename = "aid-cli-v$ResolvedVer.tar.gz"
    $bundleFile = Join-Path $tmpDir $bundleFilename

    # Resolve the CLI bundle URL.
    $bundleUrl = ''
    if ($env:AID_CLI_BUNDLE_URL) {
        $bundleUrl = $env:AID_CLI_BUNDLE_URL
    } else {
        $defaultBundleBase = "https://github.com/AndreVianna/aid-methodology/releases/download/v$ResolvedVer"
        $bundleBase = if ($env:AID_CLI_BUNDLE_BASE) { $env:AID_CLI_BUNDLE_BASE } else { $defaultBundleBase }
        $bundleUrl = "$bundleBase/$bundleFilename"
    }

    [Console]::Error.WriteLine("Fetching CLI bundle from $bundleUrl ...")
    try {
        Invoke-WebRequest -Uri $bundleUrl -OutFile $bundleFile -UseBasicParsing -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("ERROR: install.ps1: failed to fetch CLI bundle from $bundleUrl : $_")
        script:Exit-Install 3
    }

    # Checksum verification.
    if ($env:AID_INSECURE_SKIP_LIB_VERIFY -eq '1') {
        [Console]::Error.WriteLine("WARN: install.ps1: AID_INSECURE_SKIP_LIB_VERIFY=1 - skipping CLI bundle checksum verification (INSECURE)")
    } else {
        $localSums = $LocalSumsFile
        if (-not $localSums -or -not (Test-Path $localSums -PathType Leaf)) {
            # Fetch SHA256SUMS now.
            $sumsUrl = if ($env:AID_SUMS_URL) {
                $env:AID_SUMS_URL
            } elseif ($env:AID_LIB_BASE) {
                $parentBase = $env:AID_LIB_BASE -replace '/lib/?$', ''
                "$parentBase/SHA256SUMS"
            } elseif ($env:AID_CLI_BUNDLE_BASE) {
                "$($env:AID_CLI_BUNDLE_BASE)/SHA256SUMS"
            } else {
                "https://github.com/AndreVianna/aid-methodology/releases/download/v$ResolvedVer/SHA256SUMS"
            }
            $localSums = Join-Path $tmpDir 'SHA256SUMS'
            [Console]::Error.WriteLine("Fetching SHA256SUMS from $sumsUrl ...")
            try {
                Invoke-WebRequest -Uri $sumsUrl -OutFile $localSums -UseBasicParsing -ErrorAction Stop
            } catch {
                [Console]::Error.WriteLine("ERROR: install.ps1: could not fetch SHA256SUMS from $sumsUrl; refusing to install unverified CLI bundle (fail-closed)")
                [Console]::Error.WriteLine("ERROR: install.ps1: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)")
                script:Exit-Install 3
            }
        }

        $bundleHash = (Get-FileHash -LiteralPath $bundleFile -Algorithm SHA256).Hash.ToLower()
        $expectedHash = ''
        foreach ($line in [System.IO.File]::ReadAllLines($localSums)) {
            if ($line -match "^\s*([0-9a-fA-F]{64})\s+[* ]?$([regex]::Escape($bundleFilename))$") {
                $expectedHash = $matches[1].ToLower()
                break
            }
        }
        if (-not $expectedHash) {
            [Console]::Error.WriteLine("ERROR: install.ps1: $bundleFilename not found in SHA256SUMS; refusing to install unverified CLI bundle (fail-closed)")
            [Console]::Error.WriteLine("ERROR: install.ps1: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)")
            script:Exit-Install 3
        } elseif ($bundleHash -ne $expectedHash) {
            [Console]::Error.WriteLine("ERROR: install.ps1: checksum mismatch for ${bundleFilename}: expected $expectedHash, got $bundleHash")
            script:Exit-Install 4
        } else {
            [Console]::Error.WriteLine("Checksum OK: $bundleFilename")
        }
    }

    # Extract the bundle.
    $extractDir = Join-Path $tmpDir 'extracted'
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    try {
        # tar is available on Windows 10 1803+ and all modern Linux/macOS.
        $tarArgs = @('-xzf', $bundleFile, '-C', $extractDir)
        & tar @tarArgs
        if ($LASTEXITCODE -ne 0) { throw "tar exited $LASTEXITCODE" }
    } catch {
        [Console]::Error.WriteLine("ERROR: install.ps1: failed to extract CLI bundle: $_")
        script:Exit-Install 1
    }
    $script:_AidCliBundleExtractDir = $extractDir
}

$aidLibPath = $env:AID_LIB_PATH
if ($aidLibPath) {
    if (-not (Test-Path $aidLibPath -PathType Leaf)) {
        script:Fail "AID_LIB_PATH set but file not found: $aidLibPath" 1
    }
    $CoreModule = $aidLibPath
} elseif (Test-Path (Join-Path $LibDir 'AidInstallCore.psm1') -PathType Leaf) {
    $CoreModule = Join-Path $LibDir 'AidInstallCore.psm1'
} else {
    # Remote fetch with pinned tag + checksum verification (fix #12).
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("aid-libfetch-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $script:_AidTmpLibDir = $tmpDir
    $CoreModule = Join-Path $tmpDir 'AidInstallCore.psm1'

    # Resolve version to pin.  Resolution order:
    #   1. AID_LIB_VERSION env var (test/override; avoids API call).
    #   2. -Version flag.
    #   3. GitHub API latest.
    $resolvedVer = ''
    if ($env:AID_LIB_VERSION) { $resolvedVer = $env:AID_LIB_VERSION -replace '^v', '' }
    elseif ($Version)          { $resolvedVer = $Version -replace '^v', '' }
    if (-not $resolvedVer) {
        $apiUrl = 'https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest'
        $headers = @{}
        $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $env:GH_TOKEN } else { '' }
        if ($token) { $headers['Authorization'] = "Bearer $token" }
        try {
            $apiResp = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction Stop
            $resolvedVer = ($apiResp.tag_name -replace '^v', '')
        } catch {
            script:Fail "Failed to resolve latest release version from $apiUrl : $_" 3
        }
        if (-not $resolvedVer) {
            script:Fail "Could not parse tag_name from GitHub API response for $apiUrl" 3
        }
    }

    # Build lib URL: raw GitHub at pinned tag (not master).
    $defaultLibBase = "https://raw.githubusercontent.com/AndreVianna/aid-methodology/v$resolvedVer/lib"
    $aidLibBase = if ($env:AID_LIB_BASE) { $env:AID_LIB_BASE } else { $defaultLibBase }
    $libUrl = "$aidLibBase/AidInstallCore.psm1"

    # SHA256SUMS URL: from the release assets (same tag).
    $defaultSumsUrl = "https://github.com/AndreVianna/aid-methodology/releases/download/v$resolvedVer/SHA256SUMS"
    $sumsUrl = if ($env:AID_SUMS_URL) {
        $env:AID_SUMS_URL
    } elseif ($env:AID_LIB_BASE) {
        # Derive from parent directory of AID_LIB_BASE (strip trailing /lib or /lib/).
        $parentBase = $env:AID_LIB_BASE -replace '/lib/?$', ''
        "$parentBase/SHA256SUMS"
    } else {
        $defaultSumsUrl
    }

    [Console]::Error.WriteLine("Fetching install core from $libUrl ...")
    try {
        Invoke-WebRequest -Uri $libUrl -OutFile $CoreModule -UseBasicParsing -ErrorAction Stop
    } catch {
        script:Fail "Failed to fetch install core from $libUrl : $_" 3
    }

    # Verify checksum (fix #12, fix #14: fail-closed).
    # AID_INSECURE_SKIP_LIB_VERIFY=1 is an explicit opt-out - must be deliberately set.
    # Default: fail closed if SHA256SUMS is unreachable OR entry is missing OR hash mismatches.
    if ($env:AID_INSECURE_SKIP_LIB_VERIFY -eq '1') {
        [Console]::Error.WriteLine("WARN: install.ps1: AID_INSECURE_SKIP_LIB_VERIFY=1 set - skipping lib checksum verification (INSECURE)")
    } else {
        $sumsFile = Join-Path $tmpDir 'SHA256SUMS'
        $sumsOk = $false
        try {
            [Console]::Error.WriteLine("Fetching SHA256SUMS from $sumsUrl ...")
            Invoke-WebRequest -Uri $sumsUrl -OutFile $sumsFile -UseBasicParsing -ErrorAction Stop
            $sumsOk = $true
        } catch {
            [Console]::Error.WriteLine("ERROR: install.ps1: could not fetch SHA256SUMS from $sumsUrl; refusing to import unverified lib (fail-closed)")
            [Console]::Error.WriteLine("ERROR: install.ps1: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)")
            script:Exit-Install 3
        }

        if (-not $sumsOk -or -not (Test-Path $sumsFile -PathType Leaf)) {
            [Console]::Error.WriteLine("ERROR: install.ps1: could not fetch SHA256SUMS from $sumsUrl; refusing to import unverified lib (fail-closed)")
            [Console]::Error.WriteLine("ERROR: install.ps1: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)")
            script:Exit-Install 3
        }

        $libHash = (Get-FileHash -LiteralPath $CoreModule -Algorithm SHA256).Hash.ToLower()
        $expectedHash = ''
        foreach ($line in [System.IO.File]::ReadAllLines($sumsFile)) {
            if ($line -match '^\s*([0-9a-fA-F]{64})\s+[* ]?AidInstallCore\.psm1$') {
                $expectedHash = $matches[1].ToLower()
                break
            }
        }
        if (-not $expectedHash) {
            [Console]::Error.WriteLine("ERROR: install.ps1: AidInstallCore.psm1 not found in SHA256SUMS from $sumsUrl; refusing to import unverified lib (fail-closed)")
            [Console]::Error.WriteLine("ERROR: install.ps1: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)")
            script:Exit-Install 3
        } elseif ($libHash -ne $expectedHash) {
            [Console]::Error.WriteLine("ERROR: install.ps1: checksum mismatch for AidInstallCore.psm1: expected $expectedHash, got $libHash")
            script:Exit-Install 4
        } else {
            [Console]::Error.WriteLine("Checksum OK: AidInstallCore.psm1")
        }
        # Cache the fetched SHA256SUMS path and resolved version for CLI bundle reuse.
        $script:_RemoteSumsFile    = $sumsFile
    }
    # Expose the resolved version for CLI bundle fetch.
    $script:_RemoteResolvedVer = $resolvedVer
}
Import-Module $CoreModule -Force -DisableNameChecking

# ---------------------------------------------------------------------------
# AID_HOME resolution helper - cross-platform (Windows/Linux/macOS).
# Windows: %LOCALAPPDATA%\aid; Unix: ~/.aid (mirrors Bash default).
# ---------------------------------------------------------------------------
function script:Resolve-AidHome {
    if ($env:AID_HOME) { return $env:AID_HOME }
    if ($env:LOCALAPPDATA) { return Join-Path $env:LOCALAPPDATA 'aid' }
    return Join-Path $HOME '.aid'
}

# ---------------------------------------------------------------------------
# Dual-mode disambiguation (mirrors install.sh logic).
#
# Modes (mutually exclusive, detected from parameters):
#   BOOTSTRAP      - no args (or only recognized bootstrap params: -Version,
#                    -FromBundle, -Force, -Verbose, -NoPath) -> install CLI + wire PATH
#   CONVENIENCE    - first positional in $RemainingArgs is a known subcommand
#   UNINSTALL_CLI  - -UninstallCli switch present
#   USAGE_ERROR    - an unrecognized parameter, or a first positional that is not
#                    a known subcommand (e.g. -Tool, -Update, -Uninstall,
#                    -TargetDirectory are no longer recognized parameters)
#
# Priority order:
#   1. -UninstallCli                       -> UNINSTALL_CLI
#   2. -Uninstall (removed legacy flag)    -> USAGE_ERROR
#   3. First positional = known subcommand -> CONVENIENCE
#   4. First positional = unrecognized parameter or unknown word -> USAGE_ERROR
#   5. AID_TOOL env-var + no positional    -> CONVENIENCE
#   6. No args / only recognized bootstrap params -> BOOTSTRAP
#
# ($RemainingArgs works because [CmdletBinding(PositionalBinding=$false)] above
# disables automatic positional binding of -Version/-FromBundle, so bare words
# like a subcommand or tool name always fall through to $RemainingArgs instead
# of being silently consumed by those named parameters.)
# ---------------------------------------------------------------------------

function script:Test-KnownSubcmd {
    param([string]$w)
    return ($w -in @('status', 'add', 'remove', 'update', 'version', 'help'))
}

$script:_InstallMode    = 'BOOTSTRAP'
$script:_AidToolEnvOnly = $false

$_firstPositional = if ($RemainingArgs -and $RemainingArgs.Count -gt 0) { $RemainingArgs[0] } else { '' }

if ($UninstallCli) {
    $script:_InstallMode = 'UNINSTALL_CLI'
} elseif ($Uninstall) {
    $script:_InstallMode = 'USAGE_ERROR'
    $_firstPositional = '-Uninstall'
} elseif ($_firstPositional) {
    if (script:Test-KnownSubcmd $_firstPositional) {
        $script:_InstallMode = 'CONVENIENCE'
    } else {
        $script:_InstallMode = 'USAGE_ERROR'
    }
} elseif ($env:AID_TOOL) {
    # AID_TOOL env-var only -> CONVENIENCE (synthesise 'add $AID_TOOL').
    $script:_InstallMode = 'CONVENIENCE'
    $script:_AidToolEnvOnly = $true
}

if ($script:_InstallMode -eq 'USAGE_ERROR') {
    Show-Usage
    script:Fail "unrecognized parameter or argument: $_firstPositional" 2
}

# ---------------------------------------------------------------------------
# UNINSTALL_CLI mode - remove the global aid CLI (fallback path).
# ---------------------------------------------------------------------------
if ($script:_InstallMode -eq 'UNINSTALL_CLI') {
    $ucForce  = [bool]$Force
    $ucNoPath = [bool]$NoPath
    if (-not $ucForce -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) { $ucForce = $true }
    if (-not $ucNoPath -and $env:AID_NO_PATH -eq '1') { $ucNoPath = $true }

    $aidHome = script:Resolve-AidHome

    if (-not $ucForce) {
        Write-Host "This will remove the aid CLI from $aidHome and the PATH wiring."
        Write-Host "Per-project AID installs are NOT affected."
        $ans = Read-Host "Confirm? [y/N]"
        if ($ans -notin @('y', 'Y')) {
            Write-Host "Cancelled."
            script:Exit-Install 0
        }
    }

    $ucPartial = $false

    # Remove PATH wiring.
    if (-not $ucNoPath) {
        $ucBinDir = Join-Path $aidHome 'bin'
        $ucCurrentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($ucCurrentPath) {
            $ucParts   = $ucCurrentPath -split ';' | Where-Object { $_ -and $_.Trim() -ne $ucBinDir }
            $ucNewPath = $ucParts -join ';'
            if ($ucNewPath -ne $ucCurrentPath) {
                try {
                    [Environment]::SetEnvironmentVariable('Path', $ucNewPath, 'User')
                    Write-Host "PATH wiring removed (User scope): $ucBinDir"
                } catch {
                    [Console]::Error.WriteLine("WARN: install.ps1: failed to remove PATH wiring: $_")
                    $ucPartial = $true
                }
            }
        }
    }

    # Remove $AID_HOME directory.
    if (Test-Path $aidHome -PathType Container) {
        try {
            Remove-Item -LiteralPath $aidHome -Recurse -Force -ErrorAction Stop
        } catch {
            [Console]::Error.WriteLine("ERROR: install.ps1: failed to remove $aidHome : $_")
            $ucPartial = $true
        }
    }

    if ($ucPartial) {
        Write-Host "aid CLI partially removed. Check the messages above for what remained."
        script:Exit-Install 1
    }

    Write-Host "aid CLI removed. Per-project AID installs are unaffected; run 'aid uninstall' in a project before removing the CLI if you also want to remove those."
    script:Exit-Install 0
}

# ---------------------------------------------------------------------------
# BOOTSTRAP mode - install the global aid CLI and wire PATH.
# ---------------------------------------------------------------------------
if ($script:_InstallMode -eq 'BOOTSTRAP') {
    $bsNoPath = [bool]$NoPath
    if (-not $bsNoPath -and $env:AID_NO_PATH -eq '1') { $bsNoPath = $true }

    $aidHome = script:Resolve-AidHome

    # Determine CLI version from VERSION file beside install.ps1.
    $bsCliVersion = $Version -replace '^v', ''
    if (-not $bsCliVersion) {
        if (-not [string]::IsNullOrEmpty($script:_InstallPs1Path)) {
            $vf = Join-Path (Split-Path -Parent $script:_InstallPs1Path) 'VERSION'
            if (Test-Path $vf -PathType Leaf) {
                $bsCliVersion = (Get-Content -LiteralPath $vf -Raw).Trim()
            }
        }
        if (-not $bsCliVersion) { $bsCliVersion = '0.0.0' }
    }

    # Locate aid.ps1 (beside install.ps1 in bin/).
    # When absent (piped/iex execution), fetch the CLI bundle from the release.
    $bsAidPs1 = $null
    $bsCliBundleExtract = $null
    if (-not [string]::IsNullOrEmpty($script:_InstallPs1Path)) {
        $bsAidPs1 = Join-Path (Split-Path -Parent $script:_InstallPs1Path) 'bin' | Join-Path -ChildPath 'aid.ps1'
    }
    if (-not $bsAidPs1 -or -not (Test-Path $bsAidPs1 -PathType Leaf)) {
        # Piped bootstrap: aid.ps1 not beside install.ps1 - fetch CLI bundle.
        # Version resolution: prefer cached value from remote lib-fetch; fall back to
        # AID_LIB_VERSION env var or -Version parameter (so local-lib-path installs work too).
        $bsResolvedVer = $script:_RemoteResolvedVer
        if (-not $bsResolvedVer -and $env:AID_LIB_VERSION) { $bsResolvedVer = $env:AID_LIB_VERSION -replace '^v', '' }
        if (-not $bsResolvedVer -and $bsCliVersion -and $bsCliVersion -ne '0.0.0') { $bsResolvedVer = $bsCliVersion }
        if (-not $bsResolvedVer) {
            script:Fail "Cannot determine release version for CLI bundle fetch; set AID_LIB_VERSION or -Version." 3
        }
        script:Fetch-And-Verify-CliBundlePs1 -ResolvedVer $bsResolvedVer -LocalSumsFile $script:_RemoteSumsFile
        $bsCliBundleExtract = $script:_AidCliBundleExtractDir
        $bsAidPs1 = Join-Path $bsCliBundleExtract 'bin' | Join-Path -ChildPath 'aid.ps1'
        # Use version from bundle's VERSION file.
        $bsBundleVer = Join-Path $bsCliBundleExtract 'VERSION'
        if (Test-Path $bsBundleVer -PathType Leaf) {
            $bsCliVersion = (Get-Content -LiteralPath $bsBundleVer -Raw).Trim()
        }
    }

    # Locate aid.cmd (beside aid.ps1).
    $bsAidCmd = Join-Path (Split-Path -Parent $bsAidPs1) 'aid.cmd'

    # Install into $AID_HOME.
    $bsBinDir = Join-Path $aidHome 'bin'
    $bsLibDir = Join-Path $aidHome 'lib'
    New-Item -ItemType Directory -Path $bsBinDir -Force | Out-Null
    New-Item -ItemType Directory -Path $bsLibDir -Force | Out-Null

    # Clean-replace: remove stale files before copying so upgrades never leave old bits.
    foreach ($bsStaleFile in @(
        (Join-Path $bsBinDir 'aid.ps1'),
        (Join-Path $bsBinDir 'aid.cmd'),
        (Join-Path $bsBinDir 'aid'),
        (Join-Path $bsLibDir 'AidInstallCore.psm1')
    )) {
        if (Test-Path $bsStaleFile -PathType Leaf) {
            Remove-Item -LiteralPath $bsStaleFile -Force -ErrorAction SilentlyContinue
        }
    }

    Copy-Item -LiteralPath $bsAidPs1 -Destination (Join-Path $bsBinDir 'aid.ps1') -Force
    if (Test-Path $bsAidCmd -PathType Leaf) {
        Copy-Item -LiteralPath $bsAidCmd -Destination (Join-Path $bsBinDir 'aid.cmd') -Force
    }

    # Determine the lib source.
    $bsLibSrc = $CoreModule
    if ($bsCliBundleExtract) {
        $bsAidBash = Join-Path $bsCliBundleExtract 'bin' | Join-Path -ChildPath 'aid'
        if (Test-Path $bsAidBash -PathType Leaf) {
            Copy-Item -LiteralPath $bsAidBash -Destination (Join-Path $bsBinDir 'aid') -Force
        }
        $bsBundleLib = Join-Path $bsCliBundleExtract 'lib' | Join-Path -ChildPath 'AidInstallCore.psm1'
        if (Test-Path $bsBundleLib -PathType Leaf) {
            $bsLibSrc = $bsBundleLib
        }
    }

    # Install the dashboard server+reader unit. The curated file set is read from the
    # single-source manifest dashboard/MANIFEST (shared with install.sh, vendor.js,
    # vendor.py and release.sh; guarded by tests/canonical/test-dashboard-manifest.sh) --
    # never a copy hand-maintained here -- so no source file (home.html, io_bounds.py, ...)
    # is silently omitted from the irm|iex + bundle channel (the H1 lockstep failure).
    # Source: beside install.ps1 (repo checkout) or the extracted CLI bundle (piped bootstrap).
    $bsDashSrc = $null
    if ($bsCliBundleExtract) {
        $bsDashSrc = Join-Path $bsCliBundleExtract 'dashboard'
    } elseif (-not [string]::IsNullOrEmpty($script:_InstallPs1Path)) {
        $bsDashSrc = Join-Path (Split-Path -Parent $script:_InstallPs1Path) 'dashboard'
    }
    if ($bsDashSrc -and (Test-Path $bsDashSrc -PathType Container)) {
        $bsDashManifest = Join-Path $bsDashSrc 'MANIFEST'
        $bsDashFiles = @()
        if (Test-Path $bsDashManifest -PathType Leaf) {
            foreach ($bsLine in (Get-Content -LiteralPath $bsDashManifest -Encoding utf8)) {
                $bsLine = ($bsLine -replace '#.*$', '').Trim()
                if ($bsLine) { $bsDashFiles += ($bsLine -replace '/', '\') }
            }
        }
        if ($bsDashFiles.Count -gt 0) {
            # Clean-replace the dashboard unit so upgrades never leave old server bits.
            $bsDashDest = Join-Path $aidHome 'dashboard'
            if (Test-Path $bsDashDest -PathType Container) {
                Remove-Item -LiteralPath $bsDashDest -Recurse -Force -ErrorAction SilentlyContinue
            }
            foreach ($bsDf in $bsDashFiles) {
                $bsDfSrc = Join-Path $bsDashSrc $bsDf
                $bsDfDst = Join-Path $bsDashDest $bsDf
                if (Test-Path $bsDfSrc -PathType Leaf) {
                    New-Item -ItemType Directory -Path (Split-Path -Parent $bsDfDst) -Force | Out-Null
                    Copy-Item -LiteralPath $bsDfSrc -Destination $bsDfDst -Force
                }
            }
        }
    }

    # Pre-copy sanity: verify the source lib contains the required sentinel function.
    # This catches a bad AID_LIB_PATH (empty file, truncated download, wrong file).
    $bsLibSrcContent = Get-Content -LiteralPath $bsLibSrc -Raw -Encoding utf8 -ErrorAction SilentlyContinue
    if (-not ($bsLibSrcContent -match 'Get-AidStatusBody')) {
        script:Fail "installer could not refresh the CLI core at ${bsLibDest}; the source lib at ${bsLibSrc} does not contain the expected function 'Get-AidStatusBody'. Close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall." 1
    }

    # Write lib via temp file then rename-replace (avoids PS module-lock issues on upgrades).
    $bsLibDest = Join-Path $bsLibDir 'AidInstallCore.psm1'
    $bsLibTmp  = Join-Path $bsLibDir ('AidInstallCore.psm1.install-tmp-' + [System.IO.Path]::GetRandomFileName())
    try {
        Copy-Item -LiteralPath $bsLibSrc -Destination $bsLibTmp -Force -ErrorAction Stop
        Move-Item  -LiteralPath $bsLibTmp -Destination $bsLibDest -Force -ErrorAction Stop
    } catch {
        if (Test-Path $bsLibTmp -PathType Leaf) {
            Remove-Item -LiteralPath $bsLibTmp -Force -ErrorAction SilentlyContinue
        }
        script:Fail "installer could not refresh the CLI core at ${bsLibDest}; close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall. Detail: $_" 1
    }

    # Post-copy verify: sha256 of installed lib must match the source we copied from.
    # A string-grep (the previous approach) passes stale/partial files that contain the
    # sentinel in a comment earlier in the file.  Hash comparison is exact.
    $bsSrcHash  = (Get-FileHash -LiteralPath $bsLibSrc  -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    $bsDestHash = (Get-FileHash -LiteralPath $bsLibDest -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    if ($bsSrcHash -ne $bsDestHash -or -not $bsSrcHash) {
        script:Fail "installer could not refresh the CLI core at ${bsLibDest}; sha256 mismatch between source and installed copy (source: $bsSrcHash, installed: $bsDestHash). Close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall." 1
    }

    $bsBytes = [System.Text.Encoding]::UTF8.GetBytes("$bsCliVersion`n")
    [System.IO.File]::WriteAllBytes((Join-Path $aidHome 'VERSION'), $bsBytes)

    Write-Host "aid CLI v$bsCliVersion installed to $aidHome."

    # Install-time PRIMARY provisioning hook (feature-002 Windows parity).
    # Guard: Administrator elevation AND no pre-set AID_HOME in env (same logic as
    # install.sh: id -u == 0 && -z _AID_HOME_PRESET).
    # When both hold, provision %ProgramData%\aid (or $env:AID_SHARED_STATE_HOME override).
    # Best-effort: a failure is WARN-only; the install still completes.
    if ((script:Test-AidAdminPs1) -and ([string]::IsNullOrEmpty($script:_AidHomePreset))) {
        $bsSharedHome = if ($env:AID_SHARED_STATE_HOME) { $env:AID_SHARED_STATE_HOME } elseif ($env:ProgramData) { Join-Path $env:ProgramData 'aid' } else { '' }
        if ($bsSharedHome) {
            try {
                $null = Invoke-AidProvisionSharedStateHome -SharedHome $bsSharedHome
            } catch {
                [Console]::Error.WriteLine("WARN: install.ps1: shared state provisioning failed (non-fatal): $_")
            }
        }
    }

    # Wire PATH (User scope, idempotent dedup on ';'-split).
    if (-not $bsNoPath) {
        $bsCurrentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if (-not $bsCurrentPath) { $bsCurrentPath = '' }
        $bsParts = $bsCurrentPath -split ';' | Where-Object { $_ -and $_.Trim() }
        if ($bsParts -contains $bsBinDir) {
            # Already present - only update in-process.
            if ($env:Path -notmatch [regex]::Escape($bsBinDir)) {
                $env:Path = "$bsBinDir;$($env:Path)"
            }
            Write-Host "PATH already wired: $bsBinDir"
        } else {
            $bsNewParts = @($bsBinDir) + @($bsParts)
            $bsNewPath  = $bsNewParts -join ';'
            $bsSafeLimit = 2000
            if ($bsNewPath.Length -gt $bsSafeLimit) {
                Write-Host "WARN: aid: User PATH would exceed $bsSafeLimit chars. Skipping automatic PATH wiring."
                Write-Host "Add `"$bsBinDir`" to your PATH manually via System Properties > Environment Variables."
            } else {
                [Environment]::SetEnvironmentVariable('Path', $bsNewPath, 'User')
                $env:Path = "$bsBinDir;$($env:Path)"
                Write-Host "PATH wiring added (User scope): $bsBinDir"
                Write-Host "Open a new shell, or the PATH is already active in this session."
            }
        }
    } else {
        Write-Host "Add `"$bsBinDir`" to your PATH manually."
    }

    Write-Host ""
    Write-Host "Then: aid add <tool>    (e.g. aid add codex)"
    script:Exit-Install 0
}

# ---------------------------------------------------------------------------
# CONVENIENCE mode - bootstrap CLI if needed, then exec 'aid.ps1 <subcmd> ...'.
# ---------------------------------------------------------------------------
if ($script:_InstallMode -eq 'CONVENIENCE') {
    $convNoPath = [bool]$NoPath
    if (-not $convNoPath -and $env:AID_NO_PATH -eq '1') { $convNoPath = $true }

    $aidHome = script:Resolve-AidHome
    $convAidPs1 = Join-Path $aidHome 'bin' | Join-Path -ChildPath 'aid.ps1'

    # Build subcommand args for aid.ps1.
    # $RemainingArgs contains positional args (subcommand + tool names) and any flags that
    # install.ps1 doesn't recognize (-Target, etc. - forwarded verbatim; aid.ps1 parses its
    # own -Target/--target).  Named parameters that install.ps1 DID consume ($FromBundle,
    # $Version, $Force, $VerbosePreference) must be reconstructed so aid.ps1 receives the
    # full argument list.  Bootstrap-only flags (-NoPath) are excluded.
    $convSubcmdArgs = [System.Collections.Generic.List[string]]::new()

    foreach ($a in $RemainingArgs) { $convSubcmdArgs.Add($a) }
    if ($FromBundle) { $convSubcmdArgs.Add('-FromBundle'); $convSubcmdArgs.Add($FromBundle) }
    if ($Version)    { $convSubcmdArgs.Add('-Version');    $convSubcmdArgs.Add($Version)    }
    if ($Force)      { $convSubcmdArgs.Add('-Force') }
    if ($VerbosePreference -eq 'Continue') { $convSubcmdArgs.Add('-Verbose') }

    if ($script:_AidToolEnvOnly -and $convSubcmdArgs.Count -eq 0) {
        # AID_TOOL env-var only, no other args -> synthesise 'add <AID_TOOL>'.
        $convSubcmdArgs.Add('add')
        $convSubcmdArgs.Add($env:AID_TOOL)
    }

    # Bootstrap the CLI if not already present.
    if (-not (Test-Path $convAidPs1 -PathType Leaf)) {
        $convBinSrc = $null
        $convCliBundleExtract = $null
        if (-not [string]::IsNullOrEmpty($script:_InstallPs1Path)) {
            $convBinSrc = Join-Path (Split-Path -Parent $script:_InstallPs1Path) 'bin' | Join-Path -ChildPath 'aid.ps1'
        }
        if (-not $convBinSrc -or -not (Test-Path $convBinSrc -PathType Leaf)) {
            # Piped bootstrap: fetch CLI bundle.
            $convBundleVer = $script:_RemoteResolvedVer
            if (-not $convBundleVer -and $env:AID_LIB_VERSION) { $convBundleVer = $env:AID_LIB_VERSION -replace '^v', '' }
            if (-not $convBundleVer -and $convCliVer -and $convCliVer -ne '0.0.0') { $convBundleVer = $convCliVer }
            if (-not $convBundleVer) {
                script:Fail "Cannot determine release version for CLI bundle fetch; set AID_LIB_VERSION." 3
            }
            script:Fetch-And-Verify-CliBundlePs1 -ResolvedVer $convBundleVer -LocalSumsFile $script:_RemoteSumsFile
            $convCliBundleExtract = $script:_AidCliBundleExtractDir
            $convBinSrc = Join-Path $convCliBundleExtract 'bin' | Join-Path -ChildPath 'aid.ps1'
        }
        $convAidCmd = Join-Path (Split-Path -Parent $convBinSrc) 'aid.cmd'

        $convCliVer = '0.0.0'
        if ($convCliBundleExtract) {
            $cvf = Join-Path $convCliBundleExtract 'VERSION'
            if (Test-Path $cvf -PathType Leaf) {
                $convCliVer = (Get-Content -LiteralPath $cvf -Raw).Trim()
            }
        } elseif (-not [string]::IsNullOrEmpty($script:_InstallPs1Path)) {
            $vf = Join-Path (Split-Path -Parent $script:_InstallPs1Path) 'VERSION'
            if (Test-Path $vf -PathType Leaf) {
                $convCliVer = (Get-Content -LiteralPath $vf -Raw).Trim()
            }
        }

        $convBinDir = Join-Path $aidHome 'bin'
        $convLibDir = Join-Path $aidHome 'lib'
        New-Item -ItemType Directory -Path $convBinDir -Force | Out-Null
        New-Item -ItemType Directory -Path $convLibDir -Force | Out-Null

        # Clean-replace: remove stale files before copying so upgrades never leave old bits.
        foreach ($convStaleFile in @(
            (Join-Path $convBinDir 'aid.ps1'),
            (Join-Path $convBinDir 'aid.cmd'),
            (Join-Path $convBinDir 'aid'),
            (Join-Path $convLibDir 'AidInstallCore.psm1')
        )) {
            if (Test-Path $convStaleFile -PathType Leaf) {
                Remove-Item -LiteralPath $convStaleFile -Force -ErrorAction SilentlyContinue
            }
        }

        Copy-Item -LiteralPath $convBinSrc -Destination (Join-Path $convBinDir 'aid.ps1') -Force
        if (Test-Path $convAidCmd -PathType Leaf) {
            Copy-Item -LiteralPath $convAidCmd -Destination (Join-Path $convBinDir 'aid.cmd') -Force
        }

        # Determine the lib source.
        $convLibSrc = $CoreModule
        if ($convCliBundleExtract) {
            $convBundleLib = Join-Path $convCliBundleExtract 'lib' | Join-Path -ChildPath 'AidInstallCore.psm1'
            if (Test-Path $convBundleLib -PathType Leaf) {
                $convLibSrc = $convBundleLib
            }
            $convBundleBash = Join-Path $convCliBundleExtract 'bin' | Join-Path -ChildPath 'aid'
            if (Test-Path $convBundleBash -PathType Leaf) {
                Copy-Item -LiteralPath $convBundleBash -Destination (Join-Path $convBinDir 'aid') -Force
            }
        }

        # Pre-copy sanity: verify the source lib contains the required sentinel function.
        # This catches a bad AID_LIB_PATH (empty file, truncated download, wrong file).
        $convLibDest = Join-Path $convLibDir 'AidInstallCore.psm1'
        $convLibSrcContent = Get-Content -LiteralPath $convLibSrc -Raw -Encoding utf8 -ErrorAction SilentlyContinue
        if (-not ($convLibSrcContent -match 'Get-AidStatusBody')) {
            script:Fail "installer could not refresh the CLI core at ${convLibDest}; the source lib at ${convLibSrc} does not contain the expected function 'Get-AidStatusBody'. Close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall." 1
        }

        # Write lib via temp file then rename-replace (avoids PS module-lock issues on upgrades).
        $convLibTmp  = Join-Path $convLibDir ('AidInstallCore.psm1.install-tmp-' + [System.IO.Path]::GetRandomFileName())
        try {
            Copy-Item -LiteralPath $convLibSrc -Destination $convLibTmp -Force -ErrorAction Stop
            Move-Item  -LiteralPath $convLibTmp -Destination $convLibDest -Force -ErrorAction Stop
        } catch {
            if (Test-Path $convLibTmp -PathType Leaf) {
                Remove-Item -LiteralPath $convLibTmp -Force -ErrorAction SilentlyContinue
            }
            script:Fail "installer could not refresh the CLI core at ${convLibDest}; close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall. Detail: $_" 1
        }

        # Post-copy verify: sha256 of installed lib must match the source we copied from.
        # A string-grep (the previous approach) passes stale/partial files that contain the
        # sentinel in a comment earlier in the file.  Hash comparison is exact.
        $convSrcHash  = (Get-FileHash -LiteralPath $convLibSrc  -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        $convDestHash = (Get-FileHash -LiteralPath $convLibDest -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($convSrcHash -ne $convDestHash -or -not $convSrcHash) {
            script:Fail "installer could not refresh the CLI core at ${convLibDest}; sha256 mismatch between source and installed copy (source: $convSrcHash, installed: $convDestHash). Close any running 'aid' or PowerShell using it and re-run, or delete ${aidHome} and reinstall." 1
        }

        $convBytes = [System.Text.Encoding]::UTF8.GetBytes("$convCliVer`n")
        [System.IO.File]::WriteAllBytes((Join-Path $aidHome 'VERSION'), $convBytes)

        Write-Host "aid CLI v$convCliVer installed to $aidHome."

        # Install-time PRIMARY provisioning hook (feature-002 Windows parity).
        # Guard: Administrator elevation AND no pre-set AID_HOME in env.
        # Best-effort: a failure is WARN-only; the install still completes.
        if ((script:Test-AidAdminPs1) -and ([string]::IsNullOrEmpty($script:_AidHomePreset))) {
            $convSharedHome = if ($env:AID_SHARED_STATE_HOME) { $env:AID_SHARED_STATE_HOME } elseif ($env:ProgramData) { Join-Path $env:ProgramData 'aid' } else { '' }
            if ($convSharedHome) {
                try {
                    $null = Invoke-AidProvisionSharedStateHome -SharedHome $convSharedHome
                } catch {
                    [Console]::Error.WriteLine("WARN: install.ps1: shared state provisioning failed (non-fatal): $_")
                }
            }
        }

        # Wire PATH (idempotent).
        if (-not $convNoPath) {
            $cpCurrentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            if (-not $cpCurrentPath) { $cpCurrentPath = '' }
            $cpParts = $cpCurrentPath -split ';' | Where-Object { $_ -and $_.Trim() }
            if ($cpParts -notcontains $convBinDir) {
                $cpNewParts = @($convBinDir) + @($cpParts)
                $cpNewPath  = $cpNewParts -join ';'
                if ($cpNewPath.Length -le 2000) {
                    [Environment]::SetEnvironmentVariable('Path', $cpNewPath, 'User')
                    $env:Path = "$convBinDir;$($env:Path)"
                    Write-Host "PATH wiring added (User scope): $convBinDir"
                }
            } elseif ($env:Path -notmatch [regex]::Escape($convBinDir)) {
                $env:Path = "$convBinDir;$($env:Path)"
            }
        }
    }

    # Exec 'aid.ps1 <subcmd> ...' directly.
    $env:AID_HOME = $aidHome
    & $convAidPs1 @convSubcmdArgs
    script:Exit-Install $LASTEXITCODE
}

} catch {
    # In piped mode, script:Exit-Install throws the sentinel string to unwind cleanly.
    # Catch it here, suppress it, and return - the host session survives.
    # Any other exception is re-thrown so PowerShell's normal error handling applies.
    $msg = "$_"
    if ($msg.StartsWith($script:_SentinelTag)) {
        # Clean unwind - $global:LASTEXITCODE was already set by script:Exit-Install.
        return
    }
    # Unhandled exception in piped mode: set exit code 1, emit the error, and return.
    if ($script:_PipedMode) {
        $global:LASTEXITCODE = 1
        [Console]::Error.WriteLine("ERROR: install.ps1: unhandled exception: $_")
        return
    }
    # File mode: re-throw so PowerShell's default error display fires.
    throw
}
