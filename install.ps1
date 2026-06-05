#Requires -Version 5.1
# install.ps1 — AID installer bootstrap (PowerShell 5.1+).
#
# Purpose:
#   Install, update, or uninstall the AID (AI-Driven Development) methodology
#   files into a target repository.  Parses CLI params, imports the shared install
#   core module (lib/AidInstallCore.psm1), then dispatches install/update/uninstall
#   across the five canonical tool layouts.  Designed for non-interactive use
#   (irm | iex, CI) — no interactive prompts.
#
# Usage:
#   .\install.ps1 [-Tool <name[,name...]>] [-Version <v>] [-FromBundle <path>]
#                 [-Force] [-Verbose] [-TargetDirectory <dir>]
#       Install AID into the target directory (default: current directory).
#
#   .\install.ps1 -Update [-Tool <name[,...]>] [-Version <v>] [-FromBundle <path>]
#                 [-Force] [-Verbose] [-TargetDirectory <dir>]
#       Re-install / update an existing AID installation to the given or latest version.
#
#   .\install.ps1 -Uninstall [-Tool <name[,...]>] [-Verbose] [-TargetDirectory <dir>]
#       Remove AID-installed files (manifest-driven).
#
#   .\install.ps1 -Help
#       Print this help and exit 0.
#
# Parameters:
#   -Tool <name>[,...]     Host tool(s) to install.  Canonical ids: claude-code, codex,
#                          cursor, copilot-cli, antigravity.  PascalCase aliases accepted:
#                          ClaudeCode, Codex, Cursor, CopilotCli, Antigravity.
#                          Comma-list installs multiple tools.  Omit to auto-detect from
#                          target dir.
#   -Version <v>           Pin to a specific release version (e.g. 0.7.0 or v0.7.0).
#                          Mutually exclusive with -FromBundle.
#   -FromBundle <path>     Offline install from a pre-downloaded tarball (single -Tool) or
#                          a directory of tarballs (comma-list).  No network.
#   -Force                 Overwrite files that exist and differ, including root agent files.
#   -Verbose               Print per-file Copied:/Up to date:/Updated:/Removed: lines.
#                          Default: concise per-tool summary only.
#   -Update                Re-install over an existing AID setup (refresh to version/latest).
#   -Uninstall             Manifest-driven removal.  -Tool limits to that tool; without it,
#                          removes all installed tools.
#   -TargetDirectory <dir> Install root (default: current directory).
#   -Help                  Print this help and exit 0.
#
# Environment variables (installer options — take effect when the explicit param is NOT given):
#   AID_TOOL       — equivalent to -Tool <value>.  Accepts a comma-list.
#                    Useful for piped invocations: $env:AID_TOOL='claude-code'; irm … | iex
#                    Precedence: explicit -Tool > $env:AID_TOOL > auto-detect.
#   AID_VERSION    — equivalent to -Version <value>.
#                    Precedence: explicit -Version > $env:AID_VERSION > resolve latest.
#   AID_TARGET     — equivalent to -TargetDirectory <dir>.
#                    Precedence: explicit -TargetDirectory > $env:AID_TARGET > cwd.
#   AID_FORCE      — set to '1' or 'true' to enable -Force.
#                    Precedence: explicit -Force > $env:AID_FORCE.
#   AID_VERBOSE    — set to '1' to enable -Verbose (per-file output).
#                    Precedence: explicit -Verbose > $env:AID_VERBOSE.
#
# Environment variables (bootstrap/lib fetch — existing):
#   AID_LIB_PATH   — absolute path to AidInstallCore.psm1 to import directly (overrides
#                    sibling detection and remote fetch; useful for tests and vendored use).
#   AID_LIB_BASE   — base URL prefix for the remote module fetch when the lib is not beside
#                    the script (piped/irm|iex case).  Defaults to the raw GitHub URL for
#                    the resolved release tag.  When set, SHA256SUMS is fetched from the
#                    parent directory of AID_LIB_BASE (one dir up from lib/).
#   AID_SUMS_URL   — override URL for SHA256SUMS used during lib checksum verification.
#                    Useful for tests.  When unset, derived from the release tag URL.
#   AID_LIB_VERSION — pin the lib fetch to a specific release version (avoids API call).
#   AID_INSECURE_SKIP_LIB_VERIFY — set to '1' to skip lib checksum verification for the
#                    remote-fetch path.  INSECURE — for restricted test environments only.
#                    Default is fail-closed: SHA256SUMS must be fetchable and the hash must
#                    match.  Do not set in production.
#
# Trust model: irm|iex trusts the GitHub repo at the resolved pinned tag (fail-closed:
#   SHA256SUMS must be fetchable and hash must match before the lib is imported; exit 3 if
#   SHA256SUMS unreachable or entry missing; exit 4 on mismatch).  Offline -FromBundle
#   installs remain the recommended verify-before-install path for air-gapped and
#   high-security adopters.
#
# Exit codes:
#   0   success
#   1   generic runtime failure
#   2   usage error (unknown param, bad args, ambiguous tool, missing target, etc.)
#   3   network / fetch failure
#   4   checksum verification failed
#   5   protect-on-diff blocked a root agent file (-Force was not given)
#   6   uninstall with no manifest (nothing installed)

[CmdletBinding()]
param(
    [string]$Tool             = '',
    [string]$Version          = '',
    [string]$FromBundle       = '',
    [switch]$Force,
    [switch]$Update,
    [switch]$Uninstall,
    [string]$TargetDirectory  = '',
    [switch]$Help,
    # Catch-all for unknown parameters: any unrecognised flag → exit 2 (usage error).
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$RemainingArgs  = @()
)

# Treat unhandled exceptions as fatal exit 1.
$ErrorActionPreference = 'Stop'

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
# NOTE: bash install.sh does NOT need this guard — `curl | bash` runs in a subshell
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
# When piped via irm | iex, $MyInvocation.MyCommand.Path is null/empty — guard.
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
    # Extract lines 2..86 of this script (the header comment), strip leading '# '.
    # Use $script:_InstallPs1Path captured at load time to avoid $MyInvocation scoping issues.
    # When piped ($script:_InstallPs1Path is null), emit a minimal usage stub (FR9 parity
    # with install.sh piped-stub).
    if ([string]::IsNullOrEmpty($script:_InstallPs1Path)) {
        Write-Host "install.ps1 — AID installer bootstrap (PowerShell 5.1+)."
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  .\install.ps1 [-Tool <name>[,...]] [-Version <v>] [-FromBundle <path>]"
        Write-Host "                [-Force] [-Verbose] [-TargetDirectory <dir>]"
        Write-Host "  .\install.ps1 -Update  [...params...]"
        Write-Host "  .\install.ps1 -Uninstall [-Tool <name>[,...]] [-TargetDirectory <dir>]"
        Write-Host "  .\install.ps1 -Help"
        Write-Host ""
        Write-Host "Key parameters:"
        Write-Host "  -Tool <name>[,...]      Tool id: claude-code, codex, cursor, copilot-cli, antigravity"
        Write-Host "  -Version <v>            Pin to release version (e.g. 0.7.0)"
        Write-Host "  -FromBundle <path>      Offline install from pre-downloaded tarball"
        Write-Host "  -Force                  Overwrite differing files including root agent files"
        Write-Host "  -Verbose                Print per-file detail (default: concise summary)"
        Write-Host "  -TargetDirectory <dir>  Install root (default: current directory)"
        Write-Host ""
        Write-Host "Env vars: AID_TOOL, AID_VERSION, AID_TARGET, AID_FORCE, AID_VERBOSE"
        Write-Host "  (equivalent to the params; params take precedence)"
        Write-Host ""
        Write-Host "Exit codes: 0 success, 1 failure, 2 usage error, 3 network error,"
        Write-Host "            4 checksum mismatch, 5 protect-on-diff blocked, 6 no manifest"
        Write-Host ""
        Write-Host "Full docs: https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md"
        return
    }
    $lines = Get-Content -LiteralPath $script:_InstallPs1Path -ErrorAction SilentlyContinue
    if ($lines) {
        $lines[1..85] | ForEach-Object { $_ -replace '^# ?', '' } | Write-Host
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
# Unknown parameters → exit 2 (usage error, FR9 parity with bash exit 2).
# ---------------------------------------------------------------------------
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    [Console]::Error.WriteLine("ERROR: install.ps1: unknown parameter: $($RemainingArgs[0])")
    [Console]::Error.WriteLine("Run with -Help for usage information.")
    script:Exit-Install 2
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
if (-not $Tool    -and $env:AID_TOOL)    { $Tool    = $env:AID_TOOL }
if (-not $Version -and $env:AID_VERSION) { $Version = $env:AID_VERSION }
if (-not $TargetDirectory -and $env:AID_TARGET) { $TargetDirectory = $env:AID_TARGET }
if (-not $Force -and ($env:AID_FORCE -eq '1' -or $env:AID_FORCE -eq 'true')) {
    $Force = [switch]$true
}

# ---------------------------------------------------------------------------
# Import the shared install core.
# Resolution order (first match wins):
#   1. AID_LIB_PATH env var — absolute path to the psm1 file (test override or vendored).
#   2. Sibling lib/AidInstallCore.psm1 — present when invoked as a local file.
#   3. Remote fetch (piped execution) — fix #12:
#      a. Resolve the release version (from -Version flag or GitHub API latest).
#      b. Fetch the lib from the IMMUTABLE release tag raw URL (not master).
#      c. Fetch SHA256SUMS from the same release tag.
#      d. Verify the lib's sha256 against SHA256SUMS — exit 4 on mismatch.
#      e. Import the verified module.
#      AID_LIB_BASE / AID_SUMS_URL env overrides allow hermetic tests without network.
# ---------------------------------------------------------------------------
$script:_AidTmpLibDir = $null

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
    # AID_INSECURE_SKIP_LIB_VERIFY=1 is an explicit opt-out — must be deliberately set.
    # Default: fail closed if SHA256SUMS is unreachable OR entry is missing OR hash mismatches.
    if ($env:AID_INSECURE_SKIP_LIB_VERIFY -eq '1') {
        [Console]::Error.WriteLine("WARN: install.ps1: AID_INSECURE_SKIP_LIB_VERIFY=1 set — skipping lib checksum verification (INSECURE)")
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
    }
}
Import-Module $CoreModule -Force -DisableNameChecking

# ---------------------------------------------------------------------------
# Determine mode.
# ---------------------------------------------------------------------------
$Mode = 'install'  # install | update | uninstall
if ($Uninstall) { $Mode = 'uninstall' }
elseif ($Update) { $Mode = 'update' }

# ---------------------------------------------------------------------------
# Validation.
# ---------------------------------------------------------------------------

# -FromBundle and -Version are mutually exclusive.
if ($FromBundle -and $Version) {
    script:Fail "-FromBundle and -Version are mutually exclusive" 2
}

# Uninstall does not accept -FromBundle or -Version.
if ($Mode -eq 'uninstall') {
    if ($FromBundle) { script:Fail "-FromBundle is not valid with -Uninstall" 2 }
    if ($Version)    { script:Fail "-Version is not valid with -Uninstall" 2 }
}

# Target defaults to current directory.
if (-not $TargetDirectory) { $TargetDirectory = '.' }

# Resolve and validate target.
if (-not (Test-Path $TargetDirectory -PathType Container)) {
    script:Fail "target directory does not exist: $TargetDirectory" 2
}
$Target = (Resolve-Path $TargetDirectory).Path

# Strip leading 'v' from version.
if ($Version) { $Version = $Version -replace '^v', '' }

# ---------------------------------------------------------------------------
# Resolve tool list.
# ---------------------------------------------------------------------------
function Resolve-ToolList {
    param([string]$RawTool, [string]$TargetDir, [string]$CurrentMode)

    $result = [System.Collections.Generic.List[string]]::new()

    if (-not $RawTool) {
        if ($CurrentMode -eq 'uninstall') {
            # No -Tool for uninstall → all tools in manifest.
            $mpath = Join-Path $TargetDir (Join-Path '.aid' '.aid-manifest.json')
            if (-not (Test-Path $mpath -PathType Leaf)) { return $result }
            try {
                $data = Get-Content -LiteralPath $mpath -Raw | ConvertFrom-Json
                if ($data.tools) {
                    $data.tools.PSObject.Properties | ForEach-Object { $result.Add($_.Name) }
                }
            } catch {}
            return $result
        }
        # Auto-detect.
        $detected = Detect-Tool -TargetPath $TargetDir
        if (-not $detected) { return $null }
        $result.Add($detected)
        return $result
    }

    # Split on comma.
    $rawList = $RawTool -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($t in $rawList) {
        $canonical = Normalize-Tool -Raw $t
        if (-not $canonical) { return $null }
        $result.Add($canonical)
    }
    return $result
}

$toolList = Resolve-ToolList -RawTool $Tool -TargetDir $Target -CurrentMode $Mode
if ($null -eq $toolList) {
    script:Exit-Install 2
}

if ($toolList.Count -eq 0 -and $Mode -eq 'uninstall') {
    script:Fail "uninstall: no manifest found at $Target/.aid/.aid-manifest.json (exit 6)" 6
}

# ---------------------------------------------------------------------------
# Staging area management.
# ---------------------------------------------------------------------------
$StagingBase = $null

function Initialize-StagingBase {
    $tmp = [System.IO.Path]::GetTempPath()
    $dir = Join-Path $tmp ("aid-install-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Remove-StagingBase {
    if ($StagingBase -and (Test-Path $StagingBase -PathType Container)) {
        Remove-Item -LiteralPath $StagingBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$StagingBase = Initialize-StagingBase

# Prepare-ToolStaging <tool> <version> <fromBundle>
# Populates $script:StagingDir and $script:ResolvedVersion.
$script:StagingDir       = ''
$script:ResolvedVersion  = ''

function Prepare-ToolStaging {
    param([string]$CurrentTool, [string]$CurrentVersion, [string]$CurrentBundle)

    $toolStaging = Join-Path $StagingBase ("staging-$CurrentTool-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $toolStaging -Force | Out-Null

    if ($CurrentBundle) {
        # Offline mode.
        $tarball = $CurrentBundle
        if (Test-Path $CurrentBundle -PathType Container) {
            # Directory of tarballs.
            $pattern = Join-Path $CurrentBundle "aid-$CurrentTool-v*.tar.gz"
            $found   = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $found) {
                script:Fail "no tarball found for tool '$CurrentTool' in bundle directory: $CurrentBundle" 1
            }
            $tarball = $found.FullName
        }
        if (-not (Test-Path $tarball -PathType Leaf)) {
            script:Fail "bundle file not found: $tarball" 1
        }
        # Verify sibling SHA256SUMS if present.
        if (-not (Verify-BundleChecksum -Tarball $tarball)) { script:Exit-Install 4 }
        # Extract version from filename: aid-<tool>-v<version>.tar.gz
        $tbase = [System.IO.Path]::GetFileName($tarball)
        $script:ResolvedVersion = $tbase -replace "^aid-$CurrentTool-v", '' -replace '\.tar\.gz$', ''
        if (-not $script:ResolvedVersion) { $script:ResolvedVersion = if ($CurrentVersion) { $CurrentVersion } else { 'unknown' } }
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { script:Exit-Install 1 }
    } else {
        # Online mode.
        if (-not $CurrentVersion) {
            $script:ResolvedVersion = Resolve-AidVersion
            if (-not $script:ResolvedVersion) { script:Exit-Install 3 }
        } else {
            $script:ResolvedVersion = $CurrentVersion
        }
        $dlDir = Join-Path $StagingBase ("download-$CurrentTool-" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $dlDir -Force | Out-Null
        if (-not (Fetch-Tarball -Tool $CurrentTool -Version $script:ResolvedVersion -DestDir $dlDir)) { script:Exit-Install 3 }
        $tarball = Join-Path $dlDir "aid-$CurrentTool-v$($script:ResolvedVersion).tar.gz"
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { script:Exit-Install 1 }
    }

    $script:StagingDir = $toolStaging
}

# ---------------------------------------------------------------------------
# Main dispatch.
# ---------------------------------------------------------------------------

try {
    $overallBlocked = $false

    switch ($Mode) {
        { $_ -in 'install', 'update' } {
            foreach ($t in $toolList) {
                Write-Host ""
                Prepare-ToolStaging -CurrentTool $t -CurrentVersion $Version -CurrentBundle $FromBundle
                Write-Host "Installing $t v$($script:ResolvedVersion) $([char]0x2192) $Target"
                $rc = Install-AidTool -StagingDir $script:StagingDir -Tool $t -Target $Target `
                         -Version $script:ResolvedVersion -Force ([bool]$Force) `
                         -AidVerbose $script:_AidVerbose
                if ($rc -eq 5) {
                    $overallBlocked = $true
                } elseif ($rc -ne 0) {
                    script:Exit-Install $rc
                }
            }

            Write-Host ""
            if ($overallBlocked) {
                Write-Host "Install complete with warnings: one or more root agent files were not overwritten."
                Write-Host "Review the *.aid-new file(s) and merge, or re-run with --force to overwrite."
                script:Exit-Install 5
            }
            Write-Host "Done. AID $($script:ResolvedVersion) installed into: $Target"
            script:Exit-Install 0
        }

        'uninstall' {
            $manifestPath = Join-Path $Target (Join-Path '.aid' '.aid-manifest.json')
            if (-not (Test-ManifestExists -ManifestPath $manifestPath)) {
                [Console]::Error.WriteLine("ERROR: install.ps1: no manifest at $Target/.aid/.aid-manifest.json; nothing to uninstall")
                script:Exit-Install 6
            }

            foreach ($t in $toolList) {
                Write-Host ""
                Write-Host "Uninstalling $t from $Target"
                $rc = Uninstall-AidTool -ManifestPath $manifestPath -Tool $t -Target $Target `
                         -AidVerbose $script:_AidVerbose
                if ($rc -eq 6) { script:Exit-Install 6 }
                if ($rc -ne 0) { script:Exit-Install $rc }
            }

            Write-Host ""
            Write-Host "Uninstall complete."
            script:Exit-Install 0
        }
    }
} finally {
    Remove-StagingBase
    if ($script:_AidTmpLibDir -and (Test-Path $script:_AidTmpLibDir -PathType Container)) {
        Remove-Item -LiteralPath $script:_AidTmpLibDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

} catch {
    # In piped mode, script:Exit-Install throws the sentinel string to unwind cleanly.
    # Catch it here, suppress it, and return — the host session survives.
    # Any other exception is re-thrown so PowerShell's normal error handling applies.
    $msg = "$_"
    if ($msg.StartsWith($script:_SentinelTag)) {
        # Clean unwind — $global:LASTEXITCODE was already set by script:Exit-Install.
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
