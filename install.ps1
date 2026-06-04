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
#                 [-Force] [-TargetDirectory <dir>]
#       Install AID into the target directory (default: current directory).
#
#   .\install.ps1 -Update [-Tool <name[,...]>] [-Version <v>] [-FromBundle <path>]
#                 [-Force] [-TargetDirectory <dir>]
#       Re-install / update an existing AID installation to the given or latest version.
#
#   .\install.ps1 -Uninstall [-Tool <name[,...]>] [-TargetDirectory <dir>]
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
#   -Update                Re-install over an existing AID setup (refresh to version/latest).
#   -Uninstall             Manifest-driven removal.  -Tool limits to that tool; without it,
#                          removes all installed tools.
#   -TargetDirectory <dir> Install root (default: current directory).
#   -Help                  Print this help and exit 0.
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
# Locate the directory containing this script.
# ---------------------------------------------------------------------------
$script:_InstallPs1Path = $MyInvocation.MyCommand.Path
$ScriptDir = Split-Path -Parent $script:_InstallPs1Path
$LibDir    = Join-Path $ScriptDir 'lib'

# ---------------------------------------------------------------------------
# Usage helper (prints the header block as plain text).
# ---------------------------------------------------------------------------
function Show-Usage {
    # Extract lines 2..49 of this script (the header comment), strip leading '# '.
    # Use $script:_InstallPs1Path captured at load time to avoid $MyInvocation scoping issues.
    $lines = Get-Content -LiteralPath $script:_InstallPs1Path -ErrorAction SilentlyContinue
    if ($lines) {
        $lines[1..48] | ForEach-Object { $_ -replace '^# ?', '' } | Write-Host
    }
}

# ---------------------------------------------------------------------------
# Error helper.
# ---------------------------------------------------------------------------
function script:Fail {
    param([string]$Message, [int]$Code = 1)
    [Console]::Error.WriteLine("ERROR: install.ps1: $Message")
    exit $Code
}

# ---------------------------------------------------------------------------
# -Help
# ---------------------------------------------------------------------------
if ($Help) {
    Show-Usage
    exit 0
}

# ---------------------------------------------------------------------------
# Unknown parameters → exit 2 (usage error, FR9 parity with bash exit 2).
# ---------------------------------------------------------------------------
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    [Console]::Error.WriteLine("ERROR: install.ps1: unknown parameter: $($RemainingArgs[0])")
    [Console]::Error.WriteLine("Run with -Help for usage information.")
    exit 2
}

# ---------------------------------------------------------------------------
# Import the shared install core.
# ---------------------------------------------------------------------------
$CoreModule = Join-Path $LibDir 'AidInstallCore.psm1'
if (-not (Test-Path $CoreModule -PathType Leaf)) {
    script:Fail "Shared install core not found: $CoreModule" 1
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
    exit 2
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
        if (-not (Verify-BundleChecksum -Tarball $tarball)) { exit 4 }
        # Extract version from filename: aid-<tool>-v<version>.tar.gz
        $tbase = [System.IO.Path]::GetFileName($tarball)
        $script:ResolvedVersion = $tbase -replace "^aid-$CurrentTool-v", '' -replace '\.tar\.gz$', ''
        if (-not $script:ResolvedVersion) { $script:ResolvedVersion = if ($CurrentVersion) { $CurrentVersion } else { 'unknown' } }
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { exit 1 }
    } else {
        # Online mode.
        if (-not $CurrentVersion) {
            $script:ResolvedVersion = Resolve-AidVersion
            if (-not $script:ResolvedVersion) { exit 3 }
        } else {
            $script:ResolvedVersion = $CurrentVersion
        }
        $dlDir = Join-Path $StagingBase ("download-$CurrentTool-" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $dlDir -Force | Out-Null
        if (-not (Fetch-Tarball -Tool $CurrentTool -Version $script:ResolvedVersion -DestDir $dlDir)) { exit 3 }
        $tarball = Join-Path $dlDir "aid-$CurrentTool-v$($script:ResolvedVersion).tar.gz"
        if (-not (Extract-Tarball -Tarball $tarball -DestDir $toolStaging)) { exit 1 }
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
                Write-Host "--- $t ---"
                Prepare-ToolStaging -CurrentTool $t -CurrentVersion $Version -CurrentBundle $FromBundle
                $rc = Install-AidTool -StagingDir $script:StagingDir -Tool $t -Target $Target `
                         -Version $script:ResolvedVersion -Force ([bool]$Force)
                if ($rc -eq 5) {
                    $overallBlocked = $true
                } elseif ($rc -ne 0) {
                    exit $rc
                }
            }

            Write-Host ""
            if ($overallBlocked) {
                Write-Host "Install complete with warnings: one or more root agent files were not overwritten."
                Write-Host "Review the *.aid-new file(s) and merge, or re-run with --force to overwrite."
                exit 5
            }
            Write-Host "Done. AID $($script:ResolvedVersion) installed into: $Target"
            exit 0
        }

        'uninstall' {
            $manifestPath = Join-Path $Target (Join-Path '.aid' '.aid-manifest.json')
            if (-not (Test-ManifestExists -ManifestPath $manifestPath)) {
                [Console]::Error.WriteLine("ERROR: install.ps1: no manifest at $Target/.aid/.aid-manifest.json; nothing to uninstall")
                exit 6
            }

            foreach ($t in $toolList) {
                Write-Host ""
                Write-Host "--- uninstall $t ---"
                $rc = Uninstall-AidTool -ManifestPath $manifestPath -Tool $t -Target $Target
                if ($rc -eq 6) { exit 6 }
                if ($rc -ne 0) { exit $rc }
            }

            Write-Host ""
            Write-Host "Uninstall complete."
            exit 0
        }
    }
} finally {
    Remove-StagingBase
}
