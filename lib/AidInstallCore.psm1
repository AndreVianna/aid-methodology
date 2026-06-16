#Requires -Version 5.1
# AidInstallCore.psm1 - Shared PowerShell install-core module for the AID installer.
#
# Purpose:
#   Importable module of pure functions used by install.ps1 (PowerShell bootstrap)
#   and any future in-language caller.  No top-level side effects when imported -
#   every function is defined here; nothing executes at import time.
#
# Provides:
#   Get-Sha256File <path>                        - hex sha256 of file (returns string)
#   Normalize-Tool <id>                          - canonical lower-case-hyphen tool id
#   Detect-Tool <target>                         - detected tool id; throws on 0 or >1
#   Resolve-AidVersion                           - latest GitHub release version; throws on fail
#   Fetch-Tarball <tool> <ver> <destDir>         - download + verify tarball; throws on error
#   Extract-Tarball <tarball> <destDir>          - extract (flat root); throws on fail
#   Verify-BundleChecksum <tarball>              - verify sibling SHA256SUMS if present
#   Copy-AidFile <src> <dst> [force] [aidVerbose]  - copy semantics; per-file output when verbose
#   Copy-AidDir <srcDir> <dstDir> [force] [aidVerbose] - recursive copy via Copy-AidFile
#   Install-AidTool <staging> <tool> <target> <version> [force] [aidVerbose]
#                                                - full install for one tool (copy + manifest)
#   Read-ManifestToolPaths <manifest> <tool>     - array of paths from tools.<tool>.paths
#   Read-ManifestToolVersion <manifest> <tool>   - version string for named tool
#   Read-ManifestRootAgent <manifest> <tool> <fname>
#                                                - sha256 from root_agent_files entry (or empty)
#   Read-ManifestRootAgentStatus <manifest> <tool> <fname>
#                                                - status field from root_agent_files entry
#   Read-ManifestTools <manifest>                - [string[]] tool ids (keys of tools object)
#   Write-AidManifest <manifest> <tool> <version> <paths> <rootEntries>
#                                                - atomic write/merge of manifest JSON
#   Remove-ManifestTool <manifest> <tool>        - removes a tool section from manifest
#   Test-ManifestExists <manifest>               - returns $true when manifest exists/parseable
#   Uninstall-AidTool <manifest> <tool> <target> [aidVerbose] - manifest-driven removal
#   Write-VersionMarker <target> <version>       - writes <target>/.aid/.aid-version
#
# Verbose mode:
#   Pass -AidVerbose $true to Install-AidTool / Uninstall-AidTool / Copy-AidFile /
#   Copy-AidDir to enable per-file Copied:/Up to date:/Updated:/Removed: lines.
#   Default (false): only per-tool summary line.  WARN lines always show.
#
# Exit codes (from install.ps1):
#   0  success
#   1  generic runtime failure
#   2  usage error
#   3  network / fetch failure
#   4  checksum mismatch
#   5  protect-on-diff blocked (without -Force)
#   6  uninstall with no manifest

Set-StrictMode -Version Latest

# Guard against being imported more than once.
# Use Get-Variable with -ErrorAction SilentlyContinue to avoid strict-mode failure on first load.
$_aidLoadedVar = Get-Variable -Name '_AID_INSTALL_CORE_LOADED' -Scope Global -ErrorAction SilentlyContinue
if ($_aidLoadedVar -and $_aidLoadedVar.Value -eq $true) { return }
Set-Variable -Name '_AID_INSTALL_CORE_LOADED' -Value $true -Scope Global

# Module-level per-tool copy counters. Reset by Install-AidTool before each tool.
$script:_CopyCountCopied   = 0
$script:_CopyCountUpToDate = 0
$script:_CopyCountUpdated  = 0
$script:_CopyCountSkipped  = 0

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

$script:AID_REPO_SLUG    = "AndreVianna/aid-methodology"
$script:AID_API_BASE     = "https://api.github.com/repos/$($script:AID_REPO_SLUG)"
$script:AID_DOWNLOAD_BASE = "https://github.com/$($script:AID_REPO_SLUG)/releases/download"

$script:AID_TOOLS = @('claude-code', 'codex', 'cursor', 'copilot-cli', 'antigravity')

# Root agent file per tool.
function script:Get-RootAgentFile {
    param([string]$Tool)
    switch ($Tool) {
        'claude-code' { return 'CLAUDE.md' }
        default       { return 'AGENTS.md' }
    }
}

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

# Get-Sha256File <path> - return lower-case hex sha256 of file content.
function Get-Sha256File {
    param([string]$FilePath)
    $hash = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash
    return $hash.ToLower()
}

# ---------------------------------------------------------------------------
# Tool-id normalization + detection
# ---------------------------------------------------------------------------

# Normalize-Tool <input> - return canonical id or $null on unknown.
# Accepts canonical ids (case-insensitive) and PascalCase aliases.
# All forms normalize via ToLower() mapping:
#   claude-code / claudecode / ClaudeCode  -> 'claude-code'
#   codex / Codex                          -> 'codex'
#   cursor / Cursor                        -> 'cursor'
#   copilot-cli / copilotcli / CopilotCli -> 'copilot-cli'
#   antigravity / Antigravity             -> 'antigravity'
function Normalize-Tool {
    param([string]$Raw)
    switch ($Raw.ToLower()) {
        'claude-code'   { return 'claude-code' }
        'claudecode'    { return 'claude-code' }
        'codex'         { return 'codex' }
        'cursor'        { return 'cursor' }
        'copilot-cli'   { return 'copilot-cli' }
        'copilotcli'    { return 'copilot-cli' }
        'antigravity'   { return 'antigravity' }
        default {
            Write-Error "ERROR: AidInstallCore: unknown tool id: $Raw (valid: claude-code, codex, cursor, copilot-cli, antigravity)" -ErrorAction Continue
            return $null
        }
    }
}

# Detect-Tool <target> - auto-detect installed host tool from tree markers.
# Returns canonical id.  Writes error message to stderr and returns $null on ambiguous (>1) or none (0).
function Detect-Tool {
    param([string]$TargetPath)
    $found = [System.Collections.Generic.List[string]]::new()

    if (Test-Path (Join-Path $TargetPath '.claude') -PathType Container) {
        $found.Add('claude-code')
    }
    # codex: .codex or .agents dir
    if ((Test-Path (Join-Path $TargetPath '.codex') -PathType Container) -or
        (Test-Path (Join-Path $TargetPath '.agents') -PathType Container)) {
        $found.Add('codex')
    }
    if (Test-Path (Join-Path $TargetPath '.cursor') -PathType Container) {
        $found.Add('cursor')
    }
    # copilot-cli: .github with AID copilot subtree (.github/agents/ or .github/skills/)
    $githubPath = Join-Path $TargetPath '.github'
    if ((Test-Path $githubPath -PathType Container) -and
        ((Test-Path (Join-Path $githubPath 'agents') -PathType Container) -or
         (Test-Path (Join-Path $githubPath 'skills') -PathType Container))) {
        $found.Add('copilot-cli')
    }
    if (Test-Path (Join-Path $TargetPath '.agent') -PathType Container) {
        $found.Add('antigravity')
    }

    if ($found.Count -eq 1) {
        return $found[0]
    } elseif ($found.Count -eq 0) {
        [Console]::Error.WriteLine("ERROR: cannot auto-detect host tool; pass --tool <name>")
        return $null
    } else {
        $list = $found -join ', '
        [Console]::Error.WriteLine("ERROR: ambiguous host tool (found: $list); pass --tool <name>")
        return $null
    }
}

# ---------------------------------------------------------------------------
# Version resolution (online)
# ---------------------------------------------------------------------------

# Resolve-AidVersion - fetch the latest release tag from GitHub API.
# Returns the version without leading 'v'.  Returns $null on failure.
function Resolve-AidVersion {
    $url = "$($script:AID_API_BASE)/releases/latest"
    $headers = @{}
    $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $env:GH_TOKEN } else { '' }
    if ($token) {
        $headers['Authorization'] = "Bearer $token"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        $tag = $response.tag_name
        if (-not $tag) {
            [Console]::Error.WriteLine("ERROR: AidInstallCore: could not parse tag_name from GitHub API response")
            return $null
        }
        # Strip leading 'v'
        return $tag -replace '^v', ''
    } catch {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to fetch $url : $_")
        return $null
    }
}

# ---------------------------------------------------------------------------
# Fetch + extract (online mode)
# ---------------------------------------------------------------------------

# Fetch-Tarball <tool> <version> <destDir>
# Downloads the tarball + SHA256SUMS into destDir and verifies.
# Returns $true on success, $false on failure.
function Fetch-Tarball {
    param(
        [string]$Tool,
        [string]$Version,
        [string]$DestDir
    )
    $filename  = "aid-$Tool-v$Version.tar.gz"
    $url       = "$($script:AID_DOWNLOAD_BASE)/v$Version/$filename"
    $sumsUrl   = "$($script:AID_DOWNLOAD_BASE)/v$Version/SHA256SUMS"
    $tarball   = Join-Path $DestDir $filename
    $sumsFile  = Join-Path $DestDir 'SHA256SUMS'

    $headers = @{}
    $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $env:GH_TOKEN } else { '' }
    if ($token) {
        $headers['Authorization'] = "Bearer $token"
    }

    [Console]::Error.WriteLine("Fetching $filename ...")
    try {
        Invoke-WebRequest -Uri $url -OutFile $tarball -Headers $headers -UseBasicParsing -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to download $url : $_")
        return $false
    }

    # Fetch SHA256SUMS (best-effort).
    try {
        Invoke-WebRequest -Uri $sumsUrl -OutFile $sumsFile -Headers $headers -UseBasicParsing -ErrorAction Stop
        if (-not (Invoke-VerifyChecksum -Tarball $tarball -SumsFile $sumsFile)) {
            return $false
        }
    } catch {
        [Console]::Error.WriteLine("WARN: AidInstallCore: SHA256SUMS not available for v$Version; skipping checksum verification")
    }

    return $true
}

# Invoke-VerifyChecksum <tarball> <sumsFile>
# Returns $true if checksum matches; $false otherwise.
function script:Invoke-VerifyChecksum {
    param([string]$Tarball, [string]$SumsFile)
    $filename = [System.IO.Path]::GetFileName($Tarball)

    $expected = ''
    foreach ($line in [System.IO.File]::ReadAllLines($SumsFile)) {
        # Format: "<hash>  <filename>" or "<hash> *<filename>"
        if ($line -match '^\s*([0-9a-fA-F]+)\s+[* ]?' + [regex]::Escape($filename) + '$') {
            $expected = $matches[1].ToLower()
            break
        }
    }

    if (-not $expected) {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: $filename not found in SHA256SUMS")
        return $false
    }

    $actual = Get-Sha256File -FilePath $Tarball
    if ($actual -ne $expected) {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: checksum mismatch for $filename : expected $expected, got $actual")
        return $false
    }
    [Console]::Error.WriteLine("Checksum OK: $filename")
    return $true
}

# Verify-BundleChecksum <tarball>
# Checks for a sibling SHA256SUMS file.  No-op if absent; returns $false on mismatch.
function Verify-BundleChecksum {
    param([string]$Tarball)
    # Resolve to absolute path if needed (handles relative paths).
    $absPath = if ([System.IO.Path]::IsPathRooted($Tarball)) { $Tarball } else {
        Join-Path (Get-Location).Path $Tarball
    }
    $dir = [System.IO.Path]::GetDirectoryName($absPath)
    $sumsFile = Join-Path $dir 'SHA256SUMS'
    if (-not (Test-Path $sumsFile -PathType Leaf)) {
        return $true
    }
    return (Invoke-VerifyChecksum -Tarball $absPath -SumsFile $sumsFile)
}

# Extract-Tarball <tarball> <destDir>
# Extracts into destDir.  feature-002 S2.3 guarantees a flat-root tarball.
# Asserts the flat-root contract and fails loudly when violated.
# Returns $true on success.
function Extract-Tarball {
    param([string]$Tarball, [string]$DestDir)

    if (-not (Test-Path $DestDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    # Try tar.exe first (Windows 10 1803+, also available on Linux/macOS with pwsh).
    $tarExe = (Get-Command 'tar' -ErrorAction SilentlyContinue)
    if ($tarExe) {
        try {
            $listOutput = @(& tar -tzf $Tarball 2>&1)
            if ($LASTEXITCODE -ne 0) {
                [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to list tarball contents: $Tarball")
                return $false
            }

            # Assert flat-root contract: first entry must not be a bare directory
            # (pattern: "topdir/" with no sub-separators before the trailing slash).
            $firstMember = $listOutput | Where-Object { $_ -match '\S' } | Select-Object -First 1
            if ($firstMember -match '^[^/]+/$') {
                [Console]::Error.WriteLine("ERROR: AidInstallCore: tarball has a wrapping top-level directory ('$firstMember') - expected flat-root per feature-002 S2.3 contract: $Tarball")
                return $false
            }

            & tar -xzf $Tarball -C $DestDir 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to extract $Tarball")
                return $false
            }
            return $true
        } catch {
            [Console]::Error.WriteLine("ERROR: AidInstallCore: tar extraction failed: $_")
            return $false
        }
    }

    # Expand-Archive fallback (zip only - for .tar.gz this is a limitation;
    # documented fallback per SPEC Artifact-consumption contract).
    # For tar.gz on old Windows without tar.exe we use a workaround via .NET GZipStream.
    [Console]::Error.WriteLine("WARN: AidInstallCore: tar not found; attempting Expand-Archive fallback (zip only)")
    try {
        Expand-Archive -Path $Tarball -DestinationPath $DestDir -Force
        return $true
    } catch {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: Expand-Archive fallback failed: $_")
        return $false
    }
}

# ---------------------------------------------------------------------------
# Copy semantics
# ---------------------------------------------------------------------------

# Copy-AidFile <src> <dst> [force] [aidVerbose]
# Handles NON-root-agent files only.
# Per-file lines emitted only when AidVerbose=$true.
# Increments module-level counters: $script:_CopyCountCopied, _CopyCountUpToDate,
#   _CopyCountUpdated, _CopyCountSkipped (caller resets before loop).
function Copy-AidFile {
    param(
        [string]$Src,
        [string]$Dst,
        [bool]$Force = $false,
        [bool]$AidVerbose = $false
    )
    $dstDir = [System.IO.Path]::GetDirectoryName($Dst)
    if ($dstDir -and -not (Test-Path $dstDir -PathType Container)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    if (-not (Test-Path $Dst -PathType Leaf)) {
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountCopied++
        if ($AidVerbose) { Write-Host "Copied: $Dst" }
        return
    }

    # Compare via SHA256.
    $srcHash = Get-Sha256File -FilePath $Src
    $dstHash = Get-Sha256File -FilePath $Dst

    if ($srcHash -eq $dstHash) {
        $script:_CopyCountUpToDate++
        if ($AidVerbose) { Write-Host "Up to date: $Dst" }
        return
    }

    # File exists and differs.
    if ($Force) {
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountUpdated++
        if ($AidVerbose) { Write-Host "Updated: $Dst" }
    } else {
        $script:_CopyCountSkipped++
        if ($AidVerbose) { Write-Host "Skipped (differs; use --force): $Dst" }
    }
}

# Copy-AidDir <srcDir> <dstDir> [force] [aidVerbose]
# Recursively copies a directory tree, file by file (preserving empty dirs).
function Copy-AidDir {
    param(
        [string]$SrcDir,
        [string]$DstDir,
        [bool]$Force = $false,
        [bool]$AidVerbose = $false
    )

    # Create directory structure first.
    $dirs = Get-ChildItem -LiteralPath $SrcDir -Recurse -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $rel = $dir.FullName.Substring($SrcDir.Length).TrimStart([char]'\', [char]'/')
        $dstSub = Join-Path $DstDir $rel
        if (-not (Test-Path $dstSub -PathType Container)) {
            New-Item -ItemType Directory -Path $dstSub -Force | Out-Null
        }
    }

    # Copy files in ordinal (byte-order) sorted order - matching Bash's `find | sort -z`.
    # Use [System.Array]::Sort with StringComparer.Ordinal for byte-identical path ordering.
    $fileItems = @(Get-ChildItem -LiteralPath $SrcDir -Recurse -File -ErrorAction SilentlyContinue)
    if ($fileItems.Count -gt 0) {
        $filePaths = [string[]]($fileItems | ForEach-Object { $_.FullName })
        [System.Array]::Sort($filePaths, [System.StringComparer]::Ordinal)
        foreach ($fp in $filePaths) {
            $rel = $fp.Substring($SrcDir.Length).TrimStart([char]'\', [char]'/')
            $dst = Join-Path $DstDir $rel
            Copy-AidFile -Src $fp -Dst $dst -Force $Force -AidVerbose $AidVerbose
        }
    }
}

# ---------------------------------------------------------------------------
# Protect-on-diff (FR11) for root agent files
# ---------------------------------------------------------------------------

# script:Copy-RootAgentFile <src> <dst> <tool> <force> [manifest] [aidVerbose]
# Implements the FR11 algorithm.
# Returns:
#   0 - success (copied/up-to-date/updated/forced)
#   5 - protect-on-diff blocked (written .aid-new instead)
#
# Sets $script:_CORE_ROOT_AGENT_STATUS = 'owned' | 'pending-merge'.
# Increments module-level counters $script:_CopyCount* just like Copy-AidFile.
function script:Copy-RootAgentFile {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Tool,
        [bool]$Force = $false,
        [string]$Manifest = '',
        [bool]$AidVerbose = $false
    )

    $script:_CORE_ROOT_AGENT_STATUS = 'owned'
    $incSha = Get-Sha256File -FilePath $Src

    if (-not (Test-Path $Dst -PathType Leaf)) {
        # Step 2: Destination absent -> copy.
        $dstDir = [System.IO.Path]::GetDirectoryName($Dst)
        if ($dstDir -and -not (Test-Path $dstDir -PathType Container)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountCopied++
        if ($AidVerbose) { Write-Host "Copied: $Dst" }
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        return 0
    }

    $diskSha = Get-Sha256File -FilePath $Dst

    if ($diskSha -eq $incSha) {
        # Step 3: Identical -> up to date.
        $script:_CopyCountUpToDate++
        if ($AidVerbose) { Write-Host "Up to date: $Dst" }
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        return 0
    }

    # Check manifest for AID-owned sha.
    $recordedSha = ''
    if ($Manifest -and (Test-Path $Manifest -PathType Leaf)) {
        $fname = [System.IO.Path]::GetFileName($Dst)
        $recordedSha = Read-ManifestRootAgent -ManifestPath $Manifest -Tool $Tool -FileName $fname
    }

    if ($recordedSha -and ($diskSha -eq $recordedSha)) {
        # Step 4: AID owns it -> overwrite.
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountUpdated++
        if ($AidVerbose) { Write-Host "Updated: $Dst" }
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        return 0
    }

    # Step 5: Someone else owns it.
    if ($Force) {
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountUpdated++
        if ($AidVerbose) { Write-Host "Updated: $Dst (forced over existing)" }
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        return 0
    }

    # Without -Force: write .aid-new.
    Copy-Item -LiteralPath $Src -Destination "$Dst.aid-new" -Force
    # WARN always shows regardless of AidVerbose.
    [Console]::Error.WriteLine("WARN: $Dst exists and was not written by AID; wrote incoming version to $Dst.aid-new - review and merge, or re-run with --force to overwrite")
    $script:_CORE_ROOT_AGENT_STATUS = 'pending-merge'
    return 5
}

# ---------------------------------------------------------------------------
# Manifest - JSON reader/writer
# ---------------------------------------------------------------------------

# Read-ManifestToolPaths <manifest> <tool>
# Returns an array of paths from tools.<tool>.paths.
function Read-ManifestToolPaths {
    param([string]$ManifestPath, [string]$Tool)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return @() }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        $toolData = if ($data.tools -and ($data.tools.PSObject.Properties.Name -contains $Tool)) { $data.tools.$Tool } else { $null }
        if ($toolData -and $toolData.paths) {
            return @($toolData.paths)
        }
    } catch {}
    return @()
}

# Read-ManifestToolVersion <manifest> <tool>
# Returns the version string for the named tool.
function Read-ManifestToolVersion {
    param([string]$ManifestPath, [string]$Tool)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return '' }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        $toolData = if ($data.tools -and ($data.tools.PSObject.Properties.Name -contains $Tool)) { $data.tools.$Tool } else { $null }
        if ($toolData -and $toolData.version) { return $toolData.version }
    } catch {}
    return ''
}

# Read-ManifestRootAgent <manifest> <tool> <fname>
# Returns the sha256 for the root agent file entry (empty if not present).
function Read-ManifestRootAgent {
    param([string]$ManifestPath, [string]$Tool, [string]$FileName)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return '' }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        $toolData = if ($data.tools -and ($data.tools.PSObject.Properties.Name -contains $Tool)) { $data.tools.$Tool } else { $null }
        if ($toolData -and $toolData.root_agent_files) {
            foreach ($entry in $toolData.root_agent_files) {
                if ($entry.path -eq $FileName) { return $entry.sha256 }
            }
        }
    } catch {}
    return ''
}

# Read-ManifestRootAgentStatus <manifest> <tool> <fname>
# Returns the status field ('owned' or 'pending-merge') for the root agent entry.
function Read-ManifestRootAgentStatus {
    param([string]$ManifestPath, [string]$Tool, [string]$FileName)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return '' }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        $toolData = if ($data.tools -and ($data.tools.PSObject.Properties.Name -contains $Tool)) { $data.tools.$Tool } else { $null }
        if ($toolData -and $toolData.root_agent_files) {
            foreach ($entry in $toolData.root_agent_files) {
                if ($entry.path -eq $FileName) {
                    if ($entry.PSObject.Properties['status']) { return $entry.status }
                    return 'owned'
                }
            }
        }
    } catch {}
    return ''
}

# Read-ManifestTools <manifest>
# Returns a [string[]] of installed tool ids (keys of the JSON "tools" object).
# Returns an empty array when the manifest is absent or has no tool keys.
# PS parity twin of bash manifest_list_tools (lib/aid-install-core.sh:1117).
# Used by Invoke-AidMigrateRepo for era-b tools.installed synthesis (task-077).
function Read-ManifestTools {
    param([string]$ManifestPath)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return @() }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        if ($data.tools) {
            $keys = @($data.tools.PSObject.Properties.Name)
            if ($keys.Count -gt 0) { return $keys }
        }
    } catch {}
    return @()
}

# ---------------------------------------------------------------------------
# Custom JSON serializer (2-space indent, LF newlines, byte-identical to
# Python's json.dump(data, f, indent=2) followed by f.write("\n")).
# ---------------------------------------------------------------------------

# script:Escape-JsonString <s> - escape a string for JSON embedding.
function script:Escape-JsonString {
    param([string]$s)
    $s = $s -replace '\\', '\\'
    $s = $s -replace '"',  '\"'
    $s = $s -replace "`n", '\n'
    $s = $s -replace "`r", '\r'
    $s = $s -replace "`t", '\t'
    return $s
}

# script:Build-ManifestJson - build the manifest JSON string with 2-space indent + LF + trailing LF.
# Parameters mirror Write-AidManifest internal state.
function script:Build-ManifestJson {
    param(
        [string]   $TopInstalledAt,
        [string]   $TopVersion,
        # Ordered list of [toolId, version, toolInstalledAt, paths[], rafEntries[]] tuples
        # represented as an ordered hashtable keyed by toolId.
        [System.Collections.Specialized.OrderedDictionary] $ToolsMap
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("{`n")
    [void]$sb.Append("  `"manifest_version`": 1,`n")
    [void]$sb.Append("  `"aid_version`": `"$(script:Escape-JsonString $TopVersion)`",`n")
    [void]$sb.Append("  `"installed_at`": `"$(script:Escape-JsonString $TopInstalledAt)`",`n")
    [void]$sb.Append("  `"tools`": {`n")

    $toolIds   = @($ToolsMap.Keys)
    $lastTool  = if ($toolIds.Count -gt 0) { $toolIds[$toolIds.Count - 1] } else { $null }

    foreach ($tid in $toolIds) {
        $t = $ToolsMap[$tid]
        [void]$sb.Append("    `"$tid`": {`n")
        [void]$sb.Append("      `"version`": `"$(script:Escape-JsonString $t.Version)`",`n")
        [void]$sb.Append("      `"installed_at`": `"$(script:Escape-JsonString $t.InstalledAt)`",`n")

        # paths array
        $paths = $t.Paths
        if ($paths -and $paths.Count -gt 0) {
            [void]$sb.Append("      `"paths`": [`n")
            for ($i = 0; $i -lt $paths.Count; $i++) {
                $comma = if ($i -lt $paths.Count - 1) { ',' } else { '' }
                [void]$sb.Append("        `"$(script:Escape-JsonString $paths[$i])`"$comma`n")
            }
            [void]$sb.Append("      ],`n")
        } else {
            [void]$sb.Append("      `"paths`": [],`n")
        }

        # root_agent_files array
        $raf = $t.RootAgentFiles
        if ($raf -and $raf.Count -gt 0) {
            [void]$sb.Append("      `"root_agent_files`": [`n")
            for ($i = 0; $i -lt $raf.Count; $i++) {
                $e     = $raf[$i]
                $comma = if ($i -lt $raf.Count - 1) { ',' } else { '' }
                # Multi-line object per entry (matching Python json.dump indent=2 output)
                [void]$sb.Append("        {`n")
                [void]$sb.Append("          `"path`": `"$(script:Escape-JsonString $e.path)`",`n")
                [void]$sb.Append("          `"sha256`": `"$(script:Escape-JsonString $e.sha256)`",`n")
                [void]$sb.Append("          `"status`": `"$(script:Escape-JsonString $e.status)`"`n")
                [void]$sb.Append("        }$comma`n")
            }
            [void]$sb.Append("      ]`n")
        } else {
            [void]$sb.Append("      `"root_agent_files`": []`n")
        }

        $toolComma = if ($tid -ne $lastTool) { ',' } else { '' }
        [void]$sb.Append("    }$toolComma`n")
    }

    [void]$sb.Append("  }`n")
    [void]$sb.Append("}`n")

    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Manifest writer
# ---------------------------------------------------------------------------

# Write-AidManifest <manifestPath> <tool> <version> <pathsArray> <rootEntriesArray>
#
# <pathsArray>       - array of relative POSIX paths.
# <rootEntriesArray> - array of "path|sha256|status" strings.
#
# Reads the existing manifest (if any), merges the tool entry, writes back atomically
# (via a temp file).  Creates <target>/.aid/ as needed.
# Key order contract: manifest_version, aid_version, installed_at, tools;
#   per-tool: version, installed_at, paths, root_agent_files;
#   root_agent_files entry: path, sha256, status.
# 2-space indent, LF newlines, trailing newline.
function Write-AidManifest {
    param(
        [string]$ManifestPath,
        [string]$Tool,
        [string]$Version,
        [string[]]$Paths,
        [string[]]$RootEntries
    )

    $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
    if ($manifestDir -and -not (Test-Path $manifestDir -PathType Container)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }

    $now = ([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))

    # Load existing manifest.
    $existingData = $null
    if (Test-Path $ManifestPath -PathType Leaf) {
        try {
            $existingData = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        } catch {
            $existingData = $null
        }
    }

    # Top-level installed_at: preserve existing.
    $topInstalledAt = $now
    if ($existingData -and $existingData.installed_at) {
        $topInstalledAt = $existingData.installed_at
    }

    # Build the tools map preserving existing tools, then adding/merging the current tool.
    # Use ordered dictionary so key order is deterministic.
    $toolsMap = [System.Collections.Specialized.OrderedDictionary]::new()

    # Preserve existing tools (other than the current one).
    if ($existingData -and $existingData.tools) {
        $existingData.tools.PSObject.Properties | ForEach-Object {
            $tid = $_.Name
            if ($tid -ne $Tool) {
                $t   = $_.Value
                $tP  = if ($t.paths) { [System.Collections.Generic.List[string]]($t.paths) } else { [System.Collections.Generic.List[string]]::new() }
                $tR  = [System.Collections.Generic.List[hashtable]]::new()
                if ($t.root_agent_files) {
                    foreach ($e in $t.root_agent_files) {
                        $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
                        $tR.Add(@{ path = $e.path; sha256 = $e.sha256; status = $st })
                    }
                }
                $toolsMap[$tid] = @{
                    Version       = if ($t.version) { $t.version } else { '' }
                    InstalledAt   = if ($t.installed_at) { $t.installed_at } else { $now }
                    Paths         = $tP
                    RootAgentFiles = $tR
                }
            }
        }
    }

    # Existing data for the current tool.
    $existingTool = $null
    if ($existingData -and $existingData.tools -and ($existingData.tools.PSObject.Properties.Name -contains $Tool)) {
        $existingTool = $existingData.tools.$Tool
    }

    # tool installed_at: preserve existing.
    $toolInstalledAt = $now
    if ($existingTool -and $existingTool.installed_at) {
        $toolInstalledAt = $existingTool.installed_at
    }

    # De-duplicate paths (union, preserving order: existing first, then new).
    $seenPaths   = [System.Collections.Generic.HashSet[string]]::new()
    $mergedPaths = [System.Collections.Generic.List[string]]::new()
    if ($existingTool -and $existingTool.paths) {
        foreach ($p in $existingTool.paths) {
            if ($seenPaths.Add($p)) { $mergedPaths.Add($p) }
        }
    }
    foreach ($p in $Paths) {
        if ($p -and $seenPaths.Add($p)) { $mergedPaths.Add($p) }
    }

    # Merge root_agent_files: update or add per path.
    $rafMap = [System.Collections.Specialized.OrderedDictionary]::new()
    if ($existingTool -and $existingTool.root_agent_files) {
        foreach ($e in $existingTool.root_agent_files) {
            $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
            $rafMap[$e.path] = @{ path = $e.path; sha256 = $e.sha256; status = $st }
        }
    }
    foreach ($entry in $RootEntries) {
        if (-not $entry) { continue }
        $parts = $entry -split '\|', 3
        $rpath = $parts[0]
        $rsha  = if ($parts.Count -gt 1) { $parts[1] } else { '' }
        $rst   = if ($parts.Count -gt 2) { $parts[2] } else { 'owned' }
        $rafMap[$rpath] = @{ path = $rpath; sha256 = $rsha; status = $rst }
    }
    $mergedRaf = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($key in $rafMap.Keys) { $mergedRaf.Add($rafMap[$key]) }

    # Add/overwrite current tool entry.
    $toolsMap[$Tool] = @{
        Version        = $Version
        InstalledAt    = $toolInstalledAt
        Paths          = $mergedPaths
        RootAgentFiles = $mergedRaf
    }

    # Build JSON string with exact 2-space indent, LF newlines, trailing LF.
    $json = script:Build-ManifestJson -TopInstalledAt $topInstalledAt -TopVersion $Version -ToolsMap $toolsMap

    # Write atomically via temp file.
    $tmpPath = Join-Path $manifestDir (".manifest.tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        [System.IO.File]::WriteAllBytes($tmpPath, $bytes)
        if (Test-Path $ManifestPath -PathType Leaf) { Remove-Item -LiteralPath $ManifestPath -Force }
        Move-Item -LiteralPath $tmpPath -Destination $ManifestPath -Force
    } catch {
        if (Test-Path $tmpPath -PathType Leaf) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
        [Console]::Error.WriteLine("ERROR: AidInstallCore: manifest write failed: $_")
        throw
    }
}

# Remove-ManifestTool <manifest> <tool>
# Removes a tool section from the manifest.  If no tools remain, removes the manifest.
function Remove-ManifestTool {
    param([string]$ManifestPath, [string]$Tool)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return }

    $data = $null
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    } catch {
        return
    }

    # Build tools map without the target tool.
    $toolsMap = [System.Collections.Specialized.OrderedDictionary]::new()
    if ($data.tools) {
        $data.tools.PSObject.Properties | ForEach-Object {
            $tid = $_.Name
            if ($tid -ne $Tool) {
                $t  = $_.Value
                $tP = if ($t.paths) { [System.Collections.Generic.List[string]]($t.paths) } else { [System.Collections.Generic.List[string]]::new() }
                $tR = [System.Collections.Generic.List[hashtable]]::new()
                if ($t.root_agent_files) {
                    foreach ($e in $t.root_agent_files) {
                        $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
                        $tR.Add(@{ path = $e.path; sha256 = $e.sha256; status = $st })
                    }
                }
                $toolsMap[$tid] = @{
                    Version        = if ($t.version) { $t.version } else { '' }
                    InstalledAt    = if ($t.installed_at) { $t.installed_at } else { '' }
                    Paths          = $tP
                    RootAgentFiles = $tR
                }
            }
        }
    }

    if ($toolsMap.Count -eq 0) {
        Remove-Item -LiteralPath $ManifestPath -Force
        return
    }

    $topIat = if ($data.installed_at) { $data.installed_at } else { ([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')) }
    $topVer = if ($data.aid_version) { $data.aid_version } else { '0.0.0' }

    $json = script:Build-ManifestJson -TopInstalledAt $topIat -TopVersion $topVer -ToolsMap $toolsMap

    $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
    $tmpPath = Join-Path $manifestDir (".manifest.tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        [System.IO.File]::WriteAllBytes($tmpPath, $bytes)
        if (Test-Path $ManifestPath -PathType Leaf) { Remove-Item -LiteralPath $ManifestPath -Force }
        Move-Item -LiteralPath $tmpPath -Destination $ManifestPath -Force
    } catch {
        if (Test-Path $tmpPath) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
        [Console]::Error.WriteLine("ERROR: AidInstallCore: manifest remove-tool write failed: $_")
        throw
    }
}

# Test-ManifestExists <manifest> - returns $true when manifest exists and is parseable.
function Test-ManifestExists {
    param([string]$ManifestPath)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return $false }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        return $null -ne $data.manifest_version
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Global shared-state provisioning (Windows parity of bash _provision_shared_state_home)
# ---------------------------------------------------------------------------

# Invoke-AidProvisionSharedStateHome <SharedHome>
# Create <SharedHome> and seed an empty registry.yml (no-clobber, atomic write).
# Windows shared-state home = $env:ProgramData\aid; resolved by the caller.
# Best-effort: returns $false on failure without aborting the caller.
# On Windows there is no sudo elevation wrapper in this PR -- writes are attempted
# directly; on failure the underlying error surfaces and we signal $false to the caller.
#
# The exact seed text matches the DM-1 schema used by the registry functions:
#   schema: 1
#   repos:
# (three comment lines + schema line + repos line with no items).
function Invoke-AidProvisionSharedStateHome {
    param([string]$SharedHome)

    # Step 1: create the shared-home dir if absent.
    if (-not (Test-Path $SharedHome -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $SharedHome -Force -ErrorAction Stop | Out-Null
        } catch {
            [Console]::Error.WriteLine("WARN: aid: could not create shared state home ${SharedHome}: $_")
            return $false
        }
    }

    # Step 2: seed registry.yml if absent (no-clobber).
    $reg = Join-Path $SharedHome 'registry.yml'
    if (Test-Path $reg -PathType Leaf) {
        return $true
    }

    # Write to a temp file next to the registry, then rename-replace (atomic on Windows).
    $tmp = Join-Path $SharedHome (".registry.aid-tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        $seedLines = @(
            "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).",
            "# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/",
            "# description/version are read from each repo's own .aid/settings.yml at render time.",
            "schema: 1",
            "repos:"
        )
        Set-Content -LiteralPath $tmp -Value $seedLines -Encoding utf8NoBOM -ErrorAction Stop
        Move-Item -LiteralPath $tmp -Destination $reg -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid: could not install registry seed at ${reg}: $_")
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# Version marker
# ---------------------------------------------------------------------------

# Write-VersionMarker <target> <version>
function Write-VersionMarker {
    param([string]$Target, [string]$Version)
    $aidDir = Join-Path $Target '.aid'
    if (-not (Test-Path $aidDir -PathType Container)) {
        New-Item -ItemType Directory -Path $aidDir -Force | Out-Null
    }
    $markerPath = Join-Path $aidDir '.aid-version'
    # Write with LF newline.
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$Version`n")
    [System.IO.File]::WriteAllBytes($markerPath, $bytes)
}

# ---------------------------------------------------------------------------
# High-level Install-AidTool
# ---------------------------------------------------------------------------

# Install-AidTool <stagingDir> <tool> <target> <version> [force] [aidVerbose]
# Returns:
#   0 - success (all files installed or up-to-date)
#   5 - at least one root agent file was protect-on-diff blocked
#
# Side effects: writes <target>/.aid/.aid-manifest.json and .aid/.aid-version.
function Install-AidTool {
    param(
        [string]$StagingDir,
        [string]$Tool,
        [string]$Target,
        [string]$Version,
        [bool]$Force = $false,
        [bool]$AidVerbose = $false
    )

    $manifest = Join-Path $Target (Join-Path '.aid' '.aid-manifest.json')
    $installPaths  = [System.Collections.Generic.List[string]]::new()
    $rootEntries   = [System.Collections.Generic.List[string]]::new()
    $blocked       = $false

    # Reset per-tool copy counters.
    $script:_CopyCountCopied   = 0
    $script:_CopyCountUpToDate = 0
    $script:_CopyCountUpdated  = 0
    $script:_CopyCountSkipped  = 0

    $rootAgentFile = script:Get-RootAgentFile -Tool $Tool

    # Helper: collect file paths from a directory, ordinal-sorted (matching Bash `find | sort -z`).
    $collectPaths = {
        param([string]$Dir, [string]$StripPrefix, [System.Collections.Generic.List[string]]$OutList)
        $items = @(Get-ChildItem -LiteralPath $Dir -Recurse -File -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            $fps = [string[]]($items | ForEach-Object { $_.FullName })
            [System.Array]::Sort($fps, [System.StringComparer]::Ordinal)
            foreach ($fp in $fps) {
                $rel = $fp.Substring($StripPrefix.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/'
                $OutList.Add($rel)
            }
        }
    }

    # Copy tool-specific directories.
    switch ($Tool) {
        'claude-code' {
            $claudeDir = Join-Path $StagingDir '.claude'
            if (Test-Path $claudeDir -PathType Container) {
                Copy-AidDir -SrcDir $claudeDir -DstDir (Join-Path $Target '.claude') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $claudeDir $StagingDir $installPaths
            }
        }
        'codex' {
            $codexDir  = Join-Path $StagingDir '.codex'
            $agentsDir = Join-Path $StagingDir '.agents'
            if (Test-Path $codexDir -PathType Container) {
                Copy-AidDir -SrcDir $codexDir -DstDir (Join-Path $Target '.codex') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $codexDir $StagingDir $installPaths
            }
            if (Test-Path $agentsDir -PathType Container) {
                Copy-AidDir -SrcDir $agentsDir -DstDir (Join-Path $Target '.agents') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $agentsDir $StagingDir $installPaths
            }
        }
        'cursor' {
            $cursorDir = Join-Path $StagingDir '.cursor'
            if (Test-Path $cursorDir -PathType Container) {
                Copy-AidDir -SrcDir $cursorDir -DstDir (Join-Path $Target '.cursor') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $cursorDir $StagingDir $installPaths
            }
        }
        'copilot-cli' {
            $githubDir = Join-Path $StagingDir '.github'
            if (Test-Path $githubDir -PathType Container) {
                Copy-AidDir -SrcDir $githubDir -DstDir (Join-Path $Target '.github') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $githubDir $StagingDir $installPaths
            }
        }
        'antigravity' {
            $agentDir = Join-Path $StagingDir '.agent'
            if (Test-Path $agentDir -PathType Container) {
                Copy-AidDir -SrcDir $agentDir -DstDir (Join-Path $Target '.agent') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $agentDir $StagingDir $installPaths
            }
        }
    }

    # Handle root agent file via FR11.
    $rootSrc = Join-Path $StagingDir $rootAgentFile
    $rootDst = Join-Path $Target $rootAgentFile

    if (Test-Path $rootSrc -PathType Leaf) {
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        $rafRc = script:Copy-RootAgentFile -Src $rootSrc -Dst $rootDst -Tool $Tool -Force $Force `
                     -Manifest $manifest -AidVerbose $AidVerbose
        if ($rafRc -eq 5) { $blocked = $true }

        $incSha = Get-Sha256File -FilePath $rootSrc
        $rootEntries.Add("$rootAgentFile|$incSha|$($script:_CORE_ROOT_AGENT_STATUS)")

        # Include root agent path in paths list only when owned (not pending-merge).
        if ($script:_CORE_ROOT_AGENT_STATUS -eq 'owned') {
            $installPaths.Add($rootAgentFile)
        }
    }

    # Write manifest (merge).
    Write-AidManifest -ManifestPath $manifest -Tool $Tool -Version $Version `
        -Paths @($installPaths) -RootEntries @($rootEntries)

    # Write version marker.
    Write-VersionMarker -Target $Target -Version $Version

    # Print concise install summary (always shown; per-file lines only when AidVerbose).
    $totalFiles = $script:_CopyCountCopied + $script:_CopyCountUpToDate + $script:_CopyCountUpdated + $script:_CopyCountSkipped
    if ($totalFiles -gt 0) {
        if ($script:_CopyCountCopied -gt 0 -and $script:_CopyCountUpToDate -eq 0 -and $script:_CopyCountUpdated -eq 0) {
            Write-Host "  $($script:_CopyCountCopied) files installed"
        } elseif ($script:_CopyCountUpToDate -gt 0 -and $script:_CopyCountCopied -eq 0 -and $script:_CopyCountUpdated -eq 0) {
            Write-Host "  up to date ($($script:_CopyCountUpToDate) files)"
        } else {
            $parts = [System.Collections.Generic.List[string]]::new()
            if ($script:_CopyCountUpdated -gt 0) { $parts.Add("$($script:_CopyCountUpdated) updated") }
            if ($script:_CopyCountCopied -gt 0)  { $parts.Add("$($script:_CopyCountCopied) installed") }
            if ($script:_CopyCountUpToDate -gt 0) { $parts.Add("$($script:_CopyCountUpToDate) unchanged") }
            Write-Host "  $($parts -join ', ')"
        }
    }

    if ($blocked) { return 5 }
    return 0
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

# Uninstall-AidTool <manifest> <tool> <target> [aidVerbose]
# Removes all files recorded under tools.<tool>.paths.
# Root agent files removed only when sha256 still matches.
# Returns 6 if manifest missing; 0 otherwise.
function Uninstall-AidTool {
    param(
        [string]$ManifestPath,
        [string]$Tool,
        [string]$Target,
        [bool]$AidVerbose = $false
    )

    if (-not (Test-ManifestExists -ManifestPath $ManifestPath)) { return 6 }

    $paths = Read-ManifestToolPaths -ManifestPath $ManifestPath -Tool $Tool

    if ($paths.Count -eq 0) {
        [Console]::Error.WriteLine("Nothing to uninstall for $Tool (no paths recorded)")
        Remove-ManifestTool -ManifestPath $ManifestPath -Tool $Tool
        return 0
    }

    $rootAgentFile = script:Get-RootAgentFile -Tool $Tool

    $uninstRemoved     = 0
    $uninstLeftInPlace = 0

    foreach ($p in $paths) {
        # Normalize path separators.
        $pNorm = $p -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $full = Join-Path $Target $pNorm

        if (-not (Test-Path $full)) {
            if ($AidVerbose) { Write-Host "Already absent: $full" }
            continue
        }

        # Root agent file -> apply FR11 uninstall check.
        $base = [System.IO.Path]::GetFileName($p)
        # Match: base name is root agent file AND path has no directory separator.
        if ($base -eq $rootAgentFile -and ($p -eq $rootAgentFile -or $p -replace '\\','/' -eq $rootAgentFile)) {
            $recordedSha = Read-ManifestRootAgent -ManifestPath $ManifestPath -Tool $Tool -FileName $rootAgentFile
            if ($recordedSha) {
                $diskSha = Get-Sha256File -FilePath $full
                if ($diskSha -ne $recordedSha) {
                    $uninstLeftInPlace++
                    # "Left in place" always shown (important for user awareness).
                    Write-Host "Left in place (modified or not AID-owned): $full"
                    continue
                }
            }
        }
        Remove-Item -LiteralPath $full -Force
        $uninstRemoved++
        if ($AidVerbose) { Write-Host "Removed: $full" }
    }

    # Print concise uninstall summary (always shown).
    if ($uninstRemoved -gt 0) {
        Write-Host "  $uninstRemoved files removed"
    }

    # Prune now-empty AID-owned dirs.
    $aidDirs = switch ($Tool) {
        'claude-code'  { @('.claude') }
        'codex'        { @('.codex', '.agents') }
        'cursor'       { @('.cursor') }
        'copilot-cli'  { @('.github') }
        'antigravity'  { @('.agent') }
        default        { @() }
    }

    foreach ($d in $aidDirs) {
        $fullDir = Join-Path $Target $d
        if (Test-Path $fullDir -PathType Container) {
            $remaining = Get-ChildItem -LiteralPath $fullDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $remaining) {
                Remove-Item -LiteralPath $fullDir -Recurse -Force
                if ($AidVerbose) { Write-Host "Removed dir: $fullDir" }
            }
        }
    }

    # Remove this tool from manifest.
    Remove-ManifestTool -ManifestPath $ManifestPath -Tool $Tool

    # If no manifest remains, remove version marker and .aid dir if empty.
    if (-not (Test-Path $ManifestPath -PathType Leaf)) {
        $aidMetaDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
        $versionMarker = Join-Path $aidMetaDir '.aid-version'
        if (Test-Path $versionMarker -PathType Leaf) {
            Remove-Item -LiteralPath $versionMarker -Force
        }
        if (Test-Path $aidMetaDir -PathType Container) {
            $rem = Get-ChildItem -LiteralPath $aidMetaDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $rem) {
                Remove-Item -LiteralPath $aidMetaDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    return 0
}

# ---------------------------------------------------------------------------
# CLI status helpers (additive - used by bin/aid.ps1 dispatcher)
# ---------------------------------------------------------------------------

# Get-ManifestToolList <manifestPath>
# Enumerates tools.<id> keys from the manifest.
# Returns a list of [PSCustomObject]@{Id=; Version=; RootAgent=; RootStatus=} objects.
# Returns an empty list when the manifest is absent.
function Get-ManifestToolList {
    param([string]$ManifestPath)
    $result = [System.Collections.Generic.List[psobject]]::new()
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return $result }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        if (-not $data.tools) { return $result }
        $data.tools.PSObject.Properties | ForEach-Object {
            $tid = $_.Name
            $t   = $_.Value
            $ver = if ($t.version) { $t.version } else { '' }
            # Determine root agent file for this tool.
            $rootAgent = switch ($tid) {
                'claude-code' { 'CLAUDE.md' }
                default       { 'AGENTS.md' }
            }
            # Read root agent status from manifest.
            $rootStatus = ''
            if ($t.root_agent_files) {
                foreach ($entry in $t.root_agent_files) {
                    if ($entry.path -eq $rootAgent) {
                        $rootStatus = if ($entry.PSObject.Properties['status']) { $entry.status } else { 'owned' }
                        break
                    }
                }
            }
            $result.Add([PSCustomObject]@{
                Id         = $tid
                Version    = $ver
                RootAgent  = $rootAgent
                RootStatus = $rootStatus
            })
        }
    } catch {}
    return $result
}

# ---------------------------------------------------------------------------
# Semver comparison helper
# ---------------------------------------------------------------------------

# script:Test-SemverLt <a> <b>
# Returns $true when version string a is strictly less than b.
# Splits on '.', compares major/minor/patch numerically.
# Non-numeric characters at the end of a segment are stripped.
function script:Test-SemverLt {
    param([string]$A, [string]$B)
    $partsA = $A -split '\.'
    $partsB = $B -split '\.'
    for ($i = 0; $i -lt 3; $i++) {
        $rawA = if ($i -lt $partsA.Count) { $partsA[$i] } else { '0' }
        $rawB = if ($i -lt $partsB.Count) { $partsB[$i] } else { '0' }
        # Strip non-numeric suffix.
        if ($rawA -match '^(\d+)') { $va = [int]$matches[1] } else { $va = 0 }
        if ($rawB -match '^(\d+)') { $vb = [int]$matches[1] } else { $vb = 0 }
        if ($va -lt $vb) { return $true }
        if ($va -gt $vb) { return $false }
    }
    return $false  # equal -> not less than
}

# ---------------------------------------------------------------------------
# Shared tool-list renderer (used by Get-AidStatusBody and Get-AidStatus)
# ---------------------------------------------------------------------------

# script:Invoke-RenderToolsBlock <manifestPath> <refVersion> <headerPrefix>
#
# Outputs the complete tools block to stdout via Write-Host:
#   - uniform:   "<headerPrefix> - all at v<V>[hint]:\n  <tool>\n..."
#   - divergent: "<headerPrefix>:\n  <tool>   v<ver>[hint]\n..."
# Root-agent annotation only when status != "owned".
function script:Invoke-RenderToolsBlock {
    param(
        [string]$ManifestPath,
        [string]$RefVersion,
        [string]$HeaderPrefix
    )

    $tools = Get-ManifestToolList -ManifestPath $ManifestPath

    if ($tools.Count -eq 0) {
        Write-Host "${HeaderPrefix}:"
        return
    }

    # Determine uniform vs divergent.
    $firstVer = $tools[0].Version
    $uniform = $true
    foreach ($t in $tools) {
        if ($t.Version -ne $firstVer) { $uniform = $false; break }
    }

    if ($uniform) {
        # Build update hint for header if tools are behind CLI.
        $hint = ''
        if ($RefVersion -and $firstVer -and (script:Test-SemverLt -A $firstVer -B $RefVersion)) {
            $hint = " (update -> v$RefVersion)"
        }
        Write-Host "$HeaderPrefix - all at v$firstVer${hint}:"
        foreach ($tool in $tools) {
            $rs = if ($tool.RootStatus) { $tool.RootStatus } else { 'owned' }
            $extra = ''
            if ($rs -ne 'owned' -and $rs) { $extra = '  (root pending merge)' }
            Write-Host "  $($tool.Id)$extra"
            if ($env:AID_VERBOSE -eq '1') {
                $paths = Read-ManifestToolPaths -ManifestPath $ManifestPath -Tool $tool.Id
                Write-Host "                 ($($paths.Count) files installed)"
            }
        }
    } else {
        # Divergent case.
        Write-Host "${HeaderPrefix}:"
        foreach ($tool in $tools) {
            $ver = $tool.Version
            $rs  = if ($tool.RootStatus) { $tool.RootStatus } else { 'owned' }
            $hint = ''
            if ($RefVersion -and $ver -and (script:Test-SemverLt -A $ver -B $RefVersion)) {
                $hint = "  (update -> v$RefVersion)"
            }
            $rootExtra = ''
            if ($rs -ne 'owned' -and $rs) { $rootExtra = '  (root pending merge)' }
            # Pad tool id to 14 chars (matches Bash `printf '  %-14s v%s'`).
            $paddedId = $tool.Id.PadRight(14)
            Write-Host "  $paddedId v$ver$hint$rootExtra"
            if ($env:AID_VERBOSE -eq '1') {
                $paths = Read-ManifestToolPaths -ManifestPath $ManifestPath -Tool $tool.Id
                Write-Host "                 ($($paths.Count) files installed)"
            }
        }
    }
}

# Get-AidStatusBody <target>
# Renders only the installed-tools block (no exit-7 logic, no project header).
# Prints:
#   Installed tools (in <dir>) - all at v<V>[hint]:   (uniform)
#   <per-tool lines (name-only when uniform)>
# OR (divergent):
#   Installed tools (in <dir>):
#   <per-tool lines with version + hint>
# OR (when no manifest):
#   No AID tools installed in <dir> yet - run 'aid add <tool>'.
# Returns: 0 always (caller decides how to handle missing manifest).
function Get-AidStatusBody {
    param([string]$Target = '.')

    $resolvedTarget = (Resolve-Path $Target -ErrorAction SilentlyContinue)
    if (-not $resolvedTarget) {
        Write-Host "No AID tools installed in $Target yet - run 'aid add <tool>'."
        return 0
    }
    $targetPath = $resolvedTarget.Path

    $manifest = Join-Path $targetPath (Join-Path '.aid' '.aid-manifest.json')

    $manifestOk = $false
    if (Test-Path $manifest -PathType Leaf) {
        try {
            $raw = Get-Content -LiteralPath $manifest -Raw
            if ($raw -match '"manifest_version"') {
                $manifestOk = $true
            }
        } catch {}
    }

    if (-not $manifestOk) {
        Write-Host "No AID tools installed in $targetPath yet - run 'aid add <tool>'."
        return 0
    }

    # Read CLI ref version from $env:AID_HOME/VERSION.
    $refVersion = ''
    $aidHome = $env:AID_HOME
    if ($aidHome) {
        $verFile = Join-Path $aidHome 'VERSION'
        if (Test-Path $verFile -PathType Leaf) {
            $refVersion = (Get-Content -LiteralPath $verFile -Raw).Trim()
        }
    }

    script:Invoke-RenderToolsBlock -ManifestPath $manifest -RefVersion $refVersion `
        -HeaderPrefix "Installed tools (in $targetPath)"

    return 0
}

# Get-AidStatus <target>
# Renders the "aid status" output for the AID project rooted at <target>.
# Output is byte-identical to the Bash aid_status function.
# Returns:
#   0 - manifest found; status printed to stdout.
#   7 - no manifest in <target>; message printed + returns 7.
function Get-AidStatus {
    param([string]$Target = '.')

    $resolvedTarget = (Resolve-Path $Target -ErrorAction SilentlyContinue)
    if (-not $resolvedTarget) {
        Write-Host "No AID install found in $Target. Run 'aid add <tool>' to install."
        return 7
    }
    $targetPath = $resolvedTarget.Path

    $manifest = Join-Path $targetPath (Join-Path '.aid' '.aid-manifest.json')

    # Check if manifest exists and has manifest_version key.
    $manifestOk = $false
    if (Test-Path $manifest -PathType Leaf) {
        try {
            $raw = Get-Content -LiteralPath $manifest -Raw
            if ($raw -match '"manifest_version"') {
                $manifestOk = $true
            }
        } catch {}
    }

    if (-not $manifestOk) {
        Write-Host "No AID install found in $targetPath. Run 'aid add <tool>' to install."
        return 7
    }

    # Read aid_version from manifest.
    $aidVersion = ''
    try {
        $data = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
        if ($data.aid_version) { $aidVersion = $data.aid_version }
    } catch {}

    # Read CLI ref version from $env:AID_HOME/VERSION.
    $refVersion = ''
    $aidHome = $env:AID_HOME
    if ($aidHome) {
        $verFile = Join-Path $aidHome 'VERSION'
        if (Test-Path $verFile -PathType Leaf) {
            $refVersion = (Get-Content -LiteralPath $verFile -Raw).Trim()
        }
    }

    # Emit header line - byte-identical format to Bash:
    # "AID <ver>  (project: <dir>)"
    Write-Host "AID $aidVersion  (project: $targetPath)"

    script:Invoke-RenderToolsBlock -ManifestPath $manifest -RefVersion $refVersion `
        -HeaderPrefix "Installed tools"

    return 0
}

# Export only public functions (not script-scoped helpers).
Export-ModuleMember -Function @(
    'Get-Sha256File',
    'Normalize-Tool',
    'Detect-Tool',
    'Resolve-AidVersion',
    'Fetch-Tarball',
    'Extract-Tarball',
    'Verify-BundleChecksum',
    'Copy-AidFile',
    'Copy-AidDir',
    'Install-AidTool',
    'Read-ManifestToolPaths',
    'Read-ManifestToolVersion',
    'Read-ManifestRootAgent',
    'Read-ManifestRootAgentStatus',
    'Read-ManifestTools',
    'Write-AidManifest',
    'Remove-ManifestTool',
    'Test-ManifestExists',
    'Uninstall-AidTool',
    'Write-VersionMarker',
    'Get-ManifestToolList',
    'Get-AidStatusBody',
    'Get-AidStatus',
    'Invoke-AidProvisionSharedStateHome'
)
