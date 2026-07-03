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
#   6  uninstall with no manifest

Set-StrictMode -Version Latest

# Enable TLS 1.2 for HTTPS. Windows PowerShell 5.1 (.NET Framework) can default to
# SSL3/TLS1.0, which GitHub/npm/pypi reject -> downloads fail. Harmless on PS7/.NET Core.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

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
$script:_CopyCountFailed   = 0

# Module-level prune counter. Reset by Invoke-PruneToolDirs before each prune pass.
$script:_PruneRemoved = 0

# Module-level project-provisioning state (work-007). Reset by Install-AidTool.
$script:_SeededSettings  = $false
$script:_GitignoreAction = 'unchanged'
# Settings format stamp. MUST equal bin/aid AID_SUPPORTED_FORMAT / bin/aid.ps1
# AidSupportedFormat. Used to stamp a seeded settings.yml so the format gate is quiet.
$script:_AidSupportedFormat = 1

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

# Get-RootDir <tool> - return the tool's install-tree root dir name (relative to
# the project root). The AID-own subtree lives at <root>/aid/ (e.g. .claude/aid/).
# Mirrors the per-tool dispatch in Install-AidTool and the bash _root_dir helper.
function script:Get-RootDir {
    param([string]$Tool)
    switch ($Tool) {
        'claude-code' { return '.claude' }
        'codex'       { return '.codex' }
        'cursor'      { return '.cursor' }
        'copilot-cli' { return '.github' }
        'antigravity' { return '.agent' }
        default       { return '' }
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
        try {
            Copy-Item -LiteralPath $Src -Destination $Dst -Force -ErrorAction Stop
        } catch {
            [Console]::Error.WriteLine("ERROR: AidInstallCore: copy failed: $Dst -- $_")
            $script:_CopyCountFailed++
            return
        }
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

    # File exists and differs -> always overwrite (work-007).
    # AID-owned files track the bundle, which is the source of truth, so an
    # add/update must bring them current. $Force is retained in the signature for
    # back-compat and bash<->PS parity but no longer gates this overwrite:
    # skip-on-diff silently left stale files behind on in-place upgrades. User-owned
    # root agent files (CLAUDE.md/AGENTS.md) never reach Copy-AidFile -- they are
    # handled by Copy-RootAgentFile, which keeps its own force gating.
    try {
        Copy-Item -LiteralPath $Src -Destination $Dst -Force -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: copy failed: $Dst -- $_")
        $script:_CopyCountFailed++
        return
    }
    $script:_CopyCountUpdated++
    if ($AidVerbose) { Write-Host "Updated: $Dst" }
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
# Root agent file region update (Pillar 3)
# ---------------------------------------------------------------------------

# script:Test-AidHeadingStem <line>
# Returns $true when the line is an AID-managed section heading (by stem match).
# Stems matched: Knowledge Base, Review output format, Permissions,
#                Tracking discipline.
# Tolerates a trailing parenthetical suffix e.g. " (global)" or " (IMPERATIVE)".
# Identical logic to the bash is_aid_heading awk function.
function script:Test-AidHeadingStem {
    param([string]$Line)
    if (-not $Line.StartsWith('## ')) { return $false }
    $stem = $Line.Substring(3)  # strip "## "
    # Strip trailing parenthetical: " (anything)"
    $stem = $stem -replace ' \([^)]*\)$', ''
    # Stems must cover EVERY "## " heading in the shipped AID:BEGIN/END region
    # (Tracking discipline, Knowledge Base, Workflow, Review output format,
    # Permissions). A missing stem duplicates that section on C2 migration
    # (work-007: Workflow was omitted). Parity with bash is_aid_heading.
    switch ($stem) {
        'Knowledge Base'       { return $true }
        'Workflow'             { return $true }
        'Review output format' { return $true }
        'Permissions'          { return $true }
        'Tracking discipline'  { return $true }
        default                { return $false }
    }
}

# script:Get-AidMarkedRegion <filePath>
# Extracts the AID:BEGIN..AID:END region (inclusive of marker lines) from a file.
# Returns a single string with LF line endings (matching bash awk extraction).
function script:Get-AidMarkedRegion {
    param([string]$FilePath)
    $lines = [System.IO.File]::ReadAllLines($FilePath)
    $found = $false
    $region = [System.Text.StringBuilder]::new()
    foreach ($line in $lines) {
        if (-not $found -and $line -eq '<!-- AID:BEGIN -->') {
            $found = $true
        }
        if ($found) {
            [void]$region.Append($line)
            [void]$region.Append("`n")
            if ($line -eq '<!-- AID:END -->') { break }
        }
    }
    return $region.ToString()
}

# script:Copy-RootAgentFile <src> <dst> <tool> <force> [manifest] [aidVerbose]
#
# Updates the root agent file (CLAUDE.md / AGENTS.md) using in-place region
# semantics.  Never writes a backup/sidecar file under any branch.
#
# Algorithm:
#   A. Dst absent              -> write full source (markers included).
#   B. Dst has AID:BEGIN/END   -> replace only the marked region; preserve all
#                                 content outside the markers verbatim.
#   C. Dst has no markers      -> migrate:
#      C1. Sha matches recorded manifest sha -> clean rewrite to full marked source.
#      C2. Sha mismatch        -> excise known AID-managed sections by stem match
#                                 (Knowledge Base, Review output format,
#                                 Permissions, Tracking discipline -- tolerating
#                                 trailing parenthetical suffix on the heading)
#                                 and re-insert them wrapped in AID:BEGIN/END
#                                 markers in place; preserve ## Project /
#                                 ## Project Overview and all other user content.
#                                 No backup file is ever written.
#
# Sets $script:_CORE_ROOT_AGENT_STATUS = 'owned' always (the .aid-new /
# pending-merge path is eliminated; all divergence is resolved in-place).
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
    $srcSha = Get-Sha256File -FilePath $Src
    $dstDir = [System.IO.Path]::GetDirectoryName($Dst)

    # ------------------------------------------------------------------
    # Branch A: destination absent -> write full source.
    # ------------------------------------------------------------------
    if (-not (Test-Path $Dst -PathType Leaf)) {
        if ($dstDir -and -not (Test-Path $dstDir -PathType Container)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountCopied++
        if ($AidVerbose) { Write-Host "Copied: $Dst" }
        return 0
    }

    $diskSha = Get-Sha256File -FilePath $Dst

    # Identical on disk -> nothing to do.
    if ($diskSha -eq $srcSha) {
        $script:_CopyCountUpToDate++
        if ($AidVerbose) { Write-Host "Up to date: $Dst" }
        return 0
    }

    # ------------------------------------------------------------------
    # Branch B: destination already has AID:BEGIN/END markers.
    # Replace only the marked region; preserve everything outside verbatim.
    # ------------------------------------------------------------------
    $dstLines = [System.IO.File]::ReadAllLines($Dst)
    $hasMarkers = $false
    foreach ($line in $dstLines) {
        if ($line -eq '<!-- AID:BEGIN -->') { $hasMarkers = $true; break }
    }

    if ($hasMarkers) {
        # Extract the marked region from source (inclusive of marker lines).
        $srcRegion = script:Get-AidMarkedRegion -FilePath $Src

        # Rebuild dst: lines before the marker, then new region, then lines after.
        $tmpPath = Join-Path $dstDir (".aid-root-agent." + [System.IO.Path]::GetRandomFileName())
        try {
            $sb = [System.Text.StringBuilder]::new()
            $inAid = $false
            $printedRegion = $false
            foreach ($line in $dstLines) {
                if ($line -eq '<!-- AID:BEGIN -->') {
                    if (-not $printedRegion) {
                        [void]$sb.Append($srcRegion)
                        $printedRegion = $true
                    }
                    $inAid = $true
                    continue
                }
                if ($inAid -and $line -eq '<!-- AID:END -->') {
                    $inAid = $false
                    continue
                }
                if ($inAid) { continue }
                [void]$sb.Append($line)
                [void]$sb.Append("`n")
            }
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
            [System.IO.File]::WriteAllBytes($tmpPath, $bytes)
            Move-Item -LiteralPath $tmpPath -Destination $Dst -Force
        } catch {
            if (Test-Path $tmpPath -PathType Leaf) {
                Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
            }
            throw
        }

        $script:_CopyCountUpdated++
        if ($AidVerbose) { Write-Host "Updated: $Dst (region replaced)" }
        return 0
    }

    # ------------------------------------------------------------------
    # Branch C: destination has no markers -- migration path.
    # ------------------------------------------------------------------

    # Read recorded sha from manifest (the sha AID last wrote to this file).
    $recordedSha = ''
    if ($Manifest -and (Test-Path $Manifest -PathType Leaf)) {
        $fname = [System.IO.Path]::GetFileName($Dst)
        $recordedSha = Read-ManifestRootAgent -ManifestPath $Manifest -Tool $Tool -FileName $fname
    }

    # C1: sha still matches the AID-recorded value -> clean rewrite.
    if ($recordedSha -and ($diskSha -eq $recordedSha)) {
        Copy-Item -LiteralPath $Src -Destination $Dst -Force
        $script:_CopyCountUpdated++
        if ($AidVerbose) { Write-Host "Updated: $Dst (migrated: clean rewrite)" }
        return 0
    }

    # C2: sha mismatch (user has edited the file) -> excise AID sections by
    # stem match and re-insert as a marked region.
    #
    # AID section stems to excise (exact heading stem; tolerate trailing
    # parenthetical like " (global)" or " (IMPERATIVE)"):
    #   ## Knowledge Base
    #   ## Review output format
    #   ## Permissions
    #   ## Tracking discipline
    #
    # A section runs from its "## Stem..." heading line until the next "## "
    # heading (exclusive) or end-of-file.
    #
    # The new marked region (from the source) is inserted at the position of
    # the first excised section.  All other content (## Project, user sections)
    # is preserved verbatim.

    # Extract the new marked region from source.
    $newRegion = script:Get-AidMarkedRegion -FilePath $Src

    $tmpPath = Join-Path $dstDir (".aid-root-agent." + [System.IO.Path]::GetRandomFileName())
    try {
        $sb = [System.Text.StringBuilder]::new()
        $inAidSection = $false
        $regionInserted = $false

        foreach ($line in $dstLines) {
            if ($line.StartsWith('## ')) {
                if (script:Test-AidHeadingStem -Line $line) {
                    # Start suppressing this AID section.
                    $inAidSection = $true
                    # Insert the new marked region at the first AID section position.
                    if (-not $regionInserted) {
                        [void]$sb.Append($newRegion)
                        $regionInserted = $true
                    }
                    continue
                } else {
                    # A non-AID heading ends any current AID section suppression.
                    $inAidSection = $false
                }
            }
            if ($inAidSection) { continue }
            [void]$sb.Append($line)
            [void]$sb.Append("`n")
        }

        # No AID section existed to anchor the region (a brownfield file with no
        # prior AID content) -> append the marked region at end of file. Without
        # this the AID block would be silently dropped and the file never gains
        # AID instructions. Mirrors the END block in bin/aid (aid-install-core.sh).
        if (-not $regionInserted) {
            [void]$sb.Append("`n")
            [void]$sb.Append($newRegion)
            $regionInserted = $true
        }

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
        [System.IO.File]::WriteAllBytes($tmpPath, $bytes)
        Move-Item -LiteralPath $tmpPath -Destination $Dst -Force
    } catch {
        if (Test-Path $tmpPath -PathType Leaf) {
            Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
        }
        throw
    }

    $script:_CopyCountUpdated++
    if ($AidVerbose) { Write-Host "Updated: $Dst (migrated: AID sections re-wrapped in markers)" }
    return 0
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
        if ($toolData -and $toolData.PSObject.Properties['paths'] -and $toolData.paths) {
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
        if ($toolData -and $toolData.PSObject.Properties['version'] -and $toolData.version) { return [string]$toolData.version }
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
        # Guard root_agent_files: absent on old-format manifests; PSObject.Properties['key'] is
        # safe under Set-StrictMode -Version Latest unlike direct property access.
        $raf = if ($toolData -and $toolData.PSObject.Properties['root_agent_files']) { $toolData.root_agent_files } else { $null }
        if ($raf) {
            foreach ($entry in $raf) {
                if ($entry.PSObject.Properties['path'] -and $entry.path -eq $FileName) {
                    $sha = if ($entry.PSObject.Properties['sha256']) { $entry.sha256 } else { '' }
                    return $sha
                }
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
        $raf = if ($toolData -and $toolData.PSObject.Properties['root_agent_files']) { $toolData.root_agent_files } else { $null }
        if ($raf) {
            foreach ($entry in $raf) {
                if ($entry.PSObject.Properties['path'] -and $entry.path -eq $FileName) {
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
    # Guard via PSObject.Properties['key'] -- Set-StrictMode -Version Latest (active in this module)
    # throws PropertyNotFoundException on direct access of absent properties.  Old-format manifests
    # (schema:1) have no root-level installed_at; new-format ones (manifest_version:1) do.
    $topInstalledAt = $now
    if ($existingData -and $existingData.PSObject.Properties['installed_at'] -and $existingData.installed_at) {
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
                # Guard per-tool properties: old manifests lack root_agent_files; use
                # PSObject.Properties['key'] check before direct access (StrictMode-safe).
                $tP  = if ($t.PSObject.Properties['paths'] -and $t.paths) { [System.Collections.Generic.List[string]]($t.paths) } else { [System.Collections.Generic.List[string]]::new() }
                $tR  = [System.Collections.Generic.List[hashtable]]::new()
                $tRaf = if ($t.PSObject.Properties['root_agent_files']) { $t.root_agent_files } else { $null }
                if ($tRaf) {
                    foreach ($e in $tRaf) {
                        $ePath   = if ($e.PSObject.Properties['path'])   { $e.path }   else { '' }
                        $eSha256 = if ($e.PSObject.Properties['sha256']) { $e.sha256 } else { '' }
                        $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
                        if ($ePath) { $tR.Add(@{ path = $ePath; sha256 = $eSha256; status = $st }) }
                    }
                }
                $toolsMap[$tid] = @{
                    Version       = if ($t.PSObject.Properties['version'] -and $t.version) { [string]$t.version } else { '' }
                    InstalledAt   = if ($t.PSObject.Properties['installed_at'] -and $t.installed_at) { $t.installed_at } else { $now }
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
    if ($existingTool -and $existingTool.PSObject.Properties['installed_at'] -and $existingTool.installed_at) {
        $toolInstalledAt = $existingTool.installed_at
    }

    # De-duplicate paths (union, preserving order: existing first, then new).
    $seenPaths   = [System.Collections.Generic.HashSet[string]]::new()
    $mergedPaths = [System.Collections.Generic.List[string]]::new()
    if ($existingTool -and $existingTool.PSObject.Properties['paths'] -and $existingTool.paths) {
        foreach ($p in $existingTool.paths) {
            if ($seenPaths.Add($p)) { $mergedPaths.Add($p) }
        }
    }
    foreach ($p in $Paths) {
        if ($p -and $seenPaths.Add($p)) { $mergedPaths.Add($p) }
    }

    # Merge root_agent_files: update or add per path.
    $rafMap = [System.Collections.Specialized.OrderedDictionary]::new()
    $existingRaf = if ($existingTool -and $existingTool.PSObject.Properties['root_agent_files']) { $existingTool.root_agent_files } else { $null }
    if ($existingRaf) {
        foreach ($e in $existingRaf) {
            $ePath   = if ($e.PSObject.Properties['path'])   { $e.path }   else { '' }
            $eSha256 = if ($e.PSObject.Properties['sha256']) { $e.sha256 } else { '' }
            $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
            if ($ePath) { $rafMap[$ePath] = @{ path = $ePath; sha256 = $eSha256; status = $st } }
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
    # Guard all per-tool property accesses via PSObject.Properties['key'] (StrictMode-safe).
    $toolsMap = [System.Collections.Specialized.OrderedDictionary]::new()
    if ($data.tools) {
        $data.tools.PSObject.Properties | ForEach-Object {
            $tid = $_.Name
            if ($tid -ne $Tool) {
                $t  = $_.Value
                $tP = if ($t.PSObject.Properties['paths'] -and $t.paths) { [System.Collections.Generic.List[string]]($t.paths) } else { [System.Collections.Generic.List[string]]::new() }
                $tR = [System.Collections.Generic.List[hashtable]]::new()
                $tRaf = if ($t.PSObject.Properties['root_agent_files']) { $t.root_agent_files } else { $null }
                if ($tRaf) {
                    foreach ($e in $tRaf) {
                        $ePath   = if ($e.PSObject.Properties['path'])   { $e.path }   else { '' }
                        $eSha256 = if ($e.PSObject.Properties['sha256']) { $e.sha256 } else { '' }
                        $st = if ($e.PSObject.Properties['status']) { $e.status } else { 'owned' }
                        if ($ePath) { $tR.Add(@{ path = $ePath; sha256 = $eSha256; status = $st }) }
                    }
                }
                $toolsMap[$tid] = @{
                    Version        = if ($t.PSObject.Properties['version'] -and $t.version) { [string]$t.version } else { '' }
                    InstalledAt    = if ($t.PSObject.Properties['installed_at'] -and $t.installed_at) { $t.installed_at } else { '' }
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

    $topIat = if ($data.PSObject.Properties['installed_at'] -and $data.installed_at) { $data.installed_at } else { ([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')) }
    $topVer = if ($data.PSObject.Properties['aid_version'] -and $data.aid_version) { $data.aid_version } else { '0.0.0' }

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
#   projects:
# (three comment lines + schema line + projects line with no items).
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
            "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).",
            "# Holds ONLY the base folders of projects this CLI install manages. Per-project name and",
            "# description come from .aid/settings.yml; version/tools from the manifest, at render time.",
            "schema: 1",
            "projects:"
        )
        [System.IO.File]::WriteAllText($tmp, (($seedLines) -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tmp -Destination $reg -Force -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        [Console]::Error.WriteLine("WARN: aid: could not install registry seed at ${reg}: $_")
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# Orphan prune (Pillar 2 - R7)
# ---------------------------------------------------------------------------

# Invoke-PruneToolDirs <target> <tool> <manifestPathSet>
#
# Removes stale AID-owned files from the tool's scoped directories AFTER a
# fresh install/update.  Prune basis = aid- prefix + new-manifest membership.
# Reads NO previous manifest; compares against the path set just written.
#
# Parameters:
#   Target          - the repo root (absolute path)
#   Tool            - canonical tool id
#   ManifestPathSet - HashSet[string] of new-manifest paths (for O(1) lookup)
#
# Tool-native dirs (agents/, skills/, rules/):
#   (a) aid-prefixed FILE not in the manifest set -> remove
#   (b) aid-prefixed DIRECTORY with NO files in the manifest set -> remove dir
#       (kept when ANY of its files appear in the set)
#   Non-aid-prefixed entries are never touched (user content).
#
# AID-own subtree (aid/ inside the tool root):
#   (c) any FILE under aid/ not in the manifest set -> remove
#   (d) now-empty aid/ subdirs pruned after file removals
#
# Scoping (R1): copilot-cli walks only .github/{agents,skills,aid}, never .github root.
# Never removes directories outside the tool's scoped AID directories.
function Invoke-PruneToolDirs {
    param(
        [string]$Target,
        [string]$Tool,
        [System.Collections.Generic.HashSet[string]]$ManifestPathSet,
        [bool]$AidVerbose = $false
    )

    $script:_PruneRemoved = 0

    # -----------------------------------------------------------------------
    # Helper: Invoke-PruneNativeDir <nativeDirAbs>
    # Walk one tool-native directory; apply rules (a) and (b).
    # <nativeDirAbs> is absolute (e.g. C:\repo\.claude\agents).
    # -----------------------------------------------------------------------
    $pruneNativeDir = {
        param([string]$NDir)
        if (-not (Test-Path $NDir -PathType Container)) { return }

        # Enumerate immediate aid-prefixed children of the native dir.
        $children = @(Get-ChildItem -LiteralPath $NDir -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -like 'aid-*' })
        foreach ($child in $children) {
            $childRel = $child.FullName.Substring($Target.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/'

            if ($child -is [System.IO.FileInfo]) {
                # Rule (a): aid-prefixed file not in manifest -> remove.
                if (-not $ManifestPathSet.Contains($childRel)) {
                    Remove-Item -LiteralPath $child.FullName -Force
                    $script:_PruneRemoved++
                    if ($AidVerbose) { Write-Host "Pruned: $($child.FullName)" }
                }
            } elseif ($child -is [System.IO.DirectoryInfo]) {
                # Rule (b): aid-prefixed dir -> keep only if any file inside is in manifest.
                $hasLive = $false
                $members = @(Get-ChildItem -LiteralPath $child.FullName -Recurse -File -ErrorAction SilentlyContinue)
                foreach ($m in $members) {
                    $mRel = $m.FullName.Substring($Target.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/'
                    if ($ManifestPathSet.Contains($mRel)) {
                        $hasLive = $true
                        break
                    }
                }
                if (-not $hasLive) {
                    Remove-Item -LiteralPath $child.FullName -Recurse -Force
                    $script:_PruneRemoved++
                    if ($AidVerbose) { Write-Host "Pruned dir: $($child.FullName)" }
                }
            }
        }
    }

    # -----------------------------------------------------------------------
    # Helper: Invoke-PruneAidSubtree <aidRootAbs>
    # Walk the aid/ subtree; apply rule (c) and prune empty subdirs (d).
    # <aidRootAbs> is absolute (e.g. C:\repo\.claude\aid).
    # -----------------------------------------------------------------------
    $pruneAidSubtree = {
        param([string]$ADir)
        if (-not (Test-Path $ADir -PathType Container)) { return }

        # Rule (c): remove files not in manifest.
        $files = @(Get-ChildItem -LiteralPath $ADir -Recurse -File -ErrorAction SilentlyContinue)
        foreach ($f in $files) {
            $fRel = $f.FullName.Substring($Target.Length).TrimStart([char]'\', [char]'/') -replace '\\', '/'
            if (-not $ManifestPathSet.Contains($fRel)) {
                Remove-Item -LiteralPath $f.FullName -Force
                $script:_PruneRemoved++
                if ($AidVerbose) { Write-Host "Pruned: $($f.FullName)" }
            }
        }

        # Rule (d): prune now-empty subdirs (deepest first, skip the root itself).
        $subdirs = @(Get-ChildItem -LiteralPath $ADir -Recurse -Directory -ErrorAction SilentlyContinue)
        # Sort deepest first (longest path first by ordinal).
        # Guard: pipeline over an empty @() returns $null on PowerShell; [System.Array]::Sort($null)
        # throws "Value cannot be null" (reproduces on pwsh when the dir has no subdirectories,
        # e.g. cursor/antigravity idempotent re-run after retired roots are already gone).
        if ($subdirs.Count -gt 0) {
            $subdirPaths = [string[]]($subdirs | ForEach-Object { $_.FullName })
            [System.Array]::Sort($subdirPaths, [System.StringComparer]::Ordinal)
            [System.Array]::Reverse($subdirPaths)
            foreach ($dp in $subdirPaths) {
                if (Test-Path $dp -PathType Container) {
                    $rem = @(Get-ChildItem -LiteralPath $dp -ErrorAction SilentlyContinue) | Select-Object -First 1
                    if (-not $rem) {
                        Remove-Item -LiteralPath $dp -Force
                        if ($AidVerbose) { Write-Host "Pruned dir: $dp" }
                    }
                }
            }
        }
    }

    # -----------------------------------------------------------------------
    # Per-tool scoping: which native dirs + which aid/ root to walk.
    # NOTE: Do NOT use the Uninstall-AidTool $aidDirs map (~line 1314) here --
    #       that map points copilot-cli at the .github ROOT (forbidden by R1).
    #       Scope is the R1-compliant set: .github/{agents,skills,aid} only.
    # -----------------------------------------------------------------------
    # Per-tool scoping: new layout (work-005/delivery-001).
    # Codex unified under .codex/; cursor and antigravity no longer ship rules/.
    switch ($Tool) {
        'claude-code' {
            & $pruneNativeDir (Join-Path $Target '.claude\agents')
            & $pruneNativeDir (Join-Path $Target '.claude\skills')
            & $pruneAidSubtree (Join-Path $Target '.claude\aid')
        }
        'codex' {
            # New unified layout: everything under .codex/ (agents, skills, aid).
            & $pruneNativeDir (Join-Path $Target '.codex\agents')
            & $pruneNativeDir (Join-Path $Target '.codex\skills')
            & $pruneAidSubtree (Join-Path $Target '.codex\aid')
        }
        'cursor' {
            # rules/ dir removed from new layout; agents/skills/aid remain.
            & $pruneNativeDir (Join-Path $Target '.cursor\agents')
            & $pruneNativeDir (Join-Path $Target '.cursor\skills')
            & $pruneAidSubtree (Join-Path $Target '.cursor\aid')
        }
        'copilot-cli' {
            # R1: scope to .github/{agents,skills,aid} ONLY -- never .github root.
            & $pruneNativeDir (Join-Path $Target '.github\agents')
            & $pruneNativeDir (Join-Path $Target '.github\skills')
            & $pruneAidSubtree (Join-Path $Target '.github\aid')
        }
        'antigravity' {
            # rules/ dir removed from new layout; agents/skills/aid remain.
            & $pruneNativeDir (Join-Path $Target '.agent\agents')
            & $pruneNativeDir (Join-Path $Target '.agent\skills')
            & $pruneAidSubtree (Join-Path $Target '.agent\aid')
        }
    }

    if ($script:_PruneRemoved -gt 0) {
        if (-not $AidVerbose) { Write-Host "  $($script:_PruneRemoved) stale AID file(s) pruned" }
    }
}

# ---------------------------------------------------------------------------
# Retired-root migration sweep (FR7/FR7a)
# ---------------------------------------------------------------------------

# Invoke-MigrateRetiredLayout <target> <tool> [aidVerbose]
#
# Complete-replacement migration: removes AID-owned content from the static
# list of retired AID roots that no longer exist in the new bundle layout.
# Called from Install-AidTool BEFORE Invoke-PruneToolDirs (same aid update pass).
#
# Retired roots swept per tool:
#   codex:       .agents\                     (split layout retired)
#   cursor:      .cursor\rules\               (rules dir retired)
#   antigravity: .agent\rules\                (rules dir retired)
#
# Ownership markers applied (content-isolation.md rules 1+2):
#   Marker 1: filename starts with "aid-" (tool-native dir files)
#   Marker 2: lives inside an "aid\" subtree
#
# Marker 3 (AID:BEGIN/END region in root files) is NOT touched here;
# that is handled by Copy-RootAgentFile exclusively.
#
# User content (no marker) is NEVER removed.
# Idempotent: a no-op when the retired path is already absent.
# Sets $script:_MigrateRetiredCount with the count of items removed.
function Invoke-MigrateRetiredLayout {
    param(
        [string]$Target,
        [string]$Tool,
        [bool]$AidVerbose = $false,
        [bool]$ListOnly = $false   # $true = dry-run enumeration only (no removals)
    )

    $script:_MigrateRetiredCount = 0

    # Determine whether a file is AID-owned (markers 1 or 2).
    $isAidOwned = {
        param([System.IO.FileInfo]$File)
        # Marker 1: filename starts with "aid-".
        if ($File.Name -like 'aid-*') { return $true }
        # Marker 2: lives inside an "aid" folder (any ancestor named "aid").
        $dir = $File.Directory
        while ($dir -ne $null -and $dir.FullName -ne $Target -and $dir.FullName -ne $dir.Root.FullName) {
            if ($dir.Name -eq 'aid') { return $true }
            $dir = $dir.Parent
        }
        return $false
    }

    # Sweep one retired root directory: move AID-owned files to trash, prune empty
    # dirs, then remove the retired root itself if now empty.
    # In ListOnly mode: enumerate would-be-moved files, make no changes.
    $sweepRetiredRoot = {
        param([string]$RDir)
        if (-not (Test-Path $RDir -PathType Container)) { return }

        $trashBase = Join-Path $Target (Join-Path '.aid' '.trash')

        # Walk all files; move (or collect) AID-owned ones.
        $files = @(Get-ChildItem -LiteralPath $RDir -Recurse -File -ErrorAction SilentlyContinue |
                   Sort-Object FullName)
        foreach ($f in $files) {
            if (& $isAidOwned $f) {
                if ($ListOnly) {
                    # Emit path via Write-Output so the caller can capture with $(...).
                    Write-Output $f.FullName
                    $script:_MigrateRetiredCount++
                } else {
                    # Compute relative path from $Target and move to trash.
                    $rel = $f.FullName.Substring($Target.Length).TrimStart([char]'\', [char]'/')
                    $dest = Join-Path $trashBase $rel
                    $destDir = Split-Path $dest -Parent
                    New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue | Out-Null
                    Move-Item -LiteralPath $f.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
                    $script:_MigrateRetiredCount++
                    if ($AidVerbose) { Write-Host "Trashed: $($f.FullName) -> $dest" }
                }
            }
        }

        if ($ListOnly) { return }

        # Prune now-empty subdirs (deepest first).
        $subdirs = @(Get-ChildItem -LiteralPath $RDir -Recurse -Directory -ErrorAction SilentlyContinue)
        # Guard: pipeline over an empty @() returns $null on PowerShell; [System.Array]::Sort($null)
        # throws "Value cannot be null" when the retired root has no subdirectories (e.g. cursor
        # .cursor/rules/ contains only files, no nested dirs; or on idempotent re-run when the dir
        # is already absent). Mirrors bash rm -rf / rmdir which silently no-op on absent paths.
        if ($subdirs.Count -gt 0) {
            $subPaths = [string[]]($subdirs | ForEach-Object { $_.FullName })
            [System.Array]::Sort($subPaths, [System.StringComparer]::Ordinal)
            [System.Array]::Reverse($subPaths)
            foreach ($dp in $subPaths) {
                if (Test-Path $dp -PathType Container) {
                    $rem = @(Get-ChildItem -LiteralPath $dp -ErrorAction SilentlyContinue) | Select-Object -First 1
                    if (-not $rem) {
                        Remove-Item -LiteralPath $dp -Force -ErrorAction SilentlyContinue
                        if ($AidVerbose) { Write-Host "Retired dir: $dp" }
                    }
                }
            }
        }

        # Remove the retired root itself if now empty.
        if (Test-Path $RDir -PathType Container) {
            $rem = @(Get-ChildItem -LiteralPath $RDir -ErrorAction SilentlyContinue) | Select-Object -First 1
            if (-not $rem) {
                Remove-Item -LiteralPath $RDir -Force -ErrorAction SilentlyContinue
                if ($AidVerbose) { Write-Host "Retired root dir: $RDir" }
            }
        }
    }

    switch ($Tool) {
        'codex' {
            # Retired root: .agents\ (old split layout -- skills\ + aid\ lived here).
            & $sweepRetiredRoot (Join-Path $Target '.agents')
        }
        'cursor' {
            # Retired root: .cursor\rules\ (rules dir no longer in new layout).
            & $sweepRetiredRoot (Join-Path $Target '.cursor\rules')
        }
        'antigravity' {
            # Retired root: .agent\rules\ (rules dir no longer in new layout).
            & $sweepRetiredRoot (Join-Path $Target '.agent\rules')
        }
        # claude-code and copilot-cli have no retired roots in this migration.
    }

    if (-not $ListOnly -and $script:_MigrateRetiredCount -gt 0) {
        Write-Host "  $($script:_MigrateRetiredCount) retired AID file(s) moved to .aid/.trash/"
    }
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
# Project-level provisioning (work-007): required runtime file + VCS hygiene.
# Parity with bash seed_settings_yml / update_gitignore. Both idempotent.
# ---------------------------------------------------------------------------

# AID-managed .gitignore region markers (must match the bash _AID_GI_* strings).
$script:_AidGiBegin = "# >>> AID managed -- do not edit (aid add/update maintains this block) >>>"
$script:_AidGiEnd   = "# <<< AID managed <<<"

# Get-AidGitignoreBlock - return the AID-managed block as a single LF-joined
# string (markers inclusive), NO trailing newline (matches bash contract).
function script:Get-AidGitignoreBlock {
    $lines = @(
        $script:_AidGiBegin,
        ".aid/.temp/",
        ".aid/.trash/",
        ".aid/.heartbeat/",
        ".aid/generated/",
        ".aid/knowledge/.cache/",
        ".aid/knowledge/.manual-checklist.json",
        ".aid/knowledge/.spot-check-facts.txt",
        $script:_AidGiEnd
    )
    return ($lines -join "`n")
}

# Initialize-AidSettingsFile <target> <tool>
# Seed <target>\.aid\settings.yml from the tool's just-installed template when it
# does not already exist. NEVER overwrites existing settings.yml (user config).
# Not manifest-tracked. Sets $script:_SeededSettings.
function script:Initialize-AidSettingsFile {
    param([string]$Target, [string]$Tool)
    $script:_SeededSettings = $false
    $root = script:Get-RootDir -Tool $Tool
    if (-not $root) { return }
    $aidDir = Join-Path $Target '.aid'
    $dst  = Join-Path $aidDir 'settings.yml'
    $tmpl = Join-Path (Join-Path (Join-Path (Join-Path $Target $root) 'aid') 'templates') 'settings.yml'
    if (Test-Path $dst -PathType Leaf) { return }          # never clobber user config
    # Template absent -> surface it (work-007 C5): a silent skip re-triggers the
    # "no settings.yml" class and the format gate would then warn forever.
    if (-not (Test-Path $tmpl -PathType Leaf)) {
        [Console]::Error.WriteLine("WARN: AidInstallCore: settings template missing ($tmpl); .aid/settings.yml not seeded for '$Tool'.")
        return
    }
    if (-not (Test-Path $aidDir -PathType Container)) {
        New-Item -ItemType Directory -Path $aidDir -Force | Out-Null
    }
    # Seed from template, STAMPING format_version as the first line if absent, so
    # the settings-format gate stays quiet. Byte-faithful (raw-byte prepend, no
    # text round-trip) so the install tree is byte-identical to the bash seed
    # (test-install-parity.sh diff -r covers .aid/settings.yml).
    $tmplBytes = [System.IO.File]::ReadAllBytes($tmpl)
    $tmplText  = [System.Text.Encoding]::UTF8.GetString($tmplBytes)
    if ($tmplText -match '(?m)^format_version:') {
        [System.IO.File]::WriteAllBytes($dst, $tmplBytes)
    } else {
        $fv = [System.Text.Encoding]::UTF8.GetBytes("format_version: $($script:_AidSupportedFormat)`n")
        [System.IO.File]::WriteAllBytes($dst, [byte[]]($fv + $tmplBytes))
    }
    $script:_SeededSettings = $true
}

# Update-AidGitignore <target>
# Ensure <target>\.gitignore carries the AID-managed region with the current
# transient .aid/ exclusions. Creates if absent; else strips any existing AID
# region, preserves user content, appends a fresh region with a single blank-line
# separator. Idempotent. Sets $script:_GitignoreAction to created|updated|unchanged.
function script:Update-AidGitignore {
    param([string]$Target)
    $script:_GitignoreAction = 'unchanged'
    $gi = Join-Path $Target '.gitignore'
    $block = script:Get-AidGitignoreBlock

    if (-not (Test-Path $gi -PathType Leaf)) {
        [System.IO.File]::WriteAllText($gi, $block + "`n", [System.Text.UTF8Encoding]::new($false))
        $script:_GitignoreAction = 'created'
        return
    }

    $existing = [System.IO.File]::ReadAllText($gi)
    $normalized = ($existing -replace "`r`n", "`n") -replace "`r", "`n"
    $srcLines = $normalized -split "`n"

    # Strip any existing AID region.
    $kept = [System.Collections.Generic.List[string]]::new()
    $inBlk = $false
    foreach ($ln in $srcLines) {
        if ($ln -eq $script:_AidGiBegin) { $inBlk = $true; continue }
        if ($inBlk -and $ln -eq $script:_AidGiEnd) { $inBlk = $false; continue }
        if ($inBlk) { continue }
        $kept.Add($ln)
    }
    # Trim trailing blank lines.
    while ($kept.Count -gt 0 -and $kept[$kept.Count - 1] -match '^[ \t]*$') {
        $kept.RemoveAt($kept.Count - 1)
    }

    $sb = [System.Text.StringBuilder]::new()
    foreach ($ln in $kept) { [void]$sb.Append($ln); [void]$sb.Append("`n") }
    if ($kept.Count -gt 0) { [void]$sb.Append("`n") }
    [void]$sb.Append($block); [void]$sb.Append("`n")
    $newContent = $sb.ToString()

    if ($newContent -eq $normalized) {
        $script:_GitignoreAction = 'unchanged'
    } else {
        [System.IO.File]::WriteAllText($gi, $newContent, [System.Text.UTF8Encoding]::new($false))
        $script:_GitignoreAction = 'updated'
    }
}

# ---------------------------------------------------------------------------
# High-level Install-AidTool
# ---------------------------------------------------------------------------

# Install-AidTool <stagingDir> <tool> <target> <version> [force] [aidVerbose]
# Returns:
#   0 - success (all files installed or up-to-date)
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

    # Reset per-tool copy counters.
    $script:_CopyCountCopied   = 0
    $script:_CopyCountUpToDate = 0
    $script:_CopyCountUpdated  = 0
    $script:_CopyCountSkipped  = 0
    $script:_CopyCountFailed   = 0
    # Reset project-provisioning state (work-007).
    $script:_SeededSettings  = $false
    $script:_GitignoreAction = 'unchanged'

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
            # New unified layout: .codex\ only (agents, skills, aid all under .codex\).
            # .agents\ is the RETIRED split layout -- handled by Invoke-MigrateRetiredLayout.
            $codexDir  = Join-Path $StagingDir '.codex'
            if (Test-Path $codexDir -PathType Container) {
                Copy-AidDir -SrcDir $codexDir -DstDir (Join-Path $Target '.codex') -Force $Force -AidVerbose $AidVerbose
                & $collectPaths $codexDir $StagingDir $installPaths
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

    # Abort loudly if any AID-owned file failed to copy -- do NOT proceed to
    # write a manifest that records a partial install as success (work-007 C4).
    if ($script:_CopyCountFailed -gt 0) {
        throw "AidInstallCore: $($script:_CopyCountFailed) file(s) failed to copy for '$Tool'. Install aborted (incomplete)."
    }

    # Handle root agent file via in-place region update (Pillar 3).
    $rootSrc = Join-Path $StagingDir $rootAgentFile
    $rootDst = Join-Path $Target $rootAgentFile

    if (Test-Path $rootSrc -PathType Leaf) {
        $script:_CORE_ROOT_AGENT_STATUS = 'owned'
        script:Copy-RootAgentFile -Src $rootSrc -Dst $rootDst -Tool $Tool -Force $Force `
            -Manifest $manifest -AidVerbose $AidVerbose | Out-Null

        $incSha = Get-Sha256File -FilePath $rootSrc
        $rootEntries.Add("$rootAgentFile|$incSha|$($script:_CORE_ROOT_AGENT_STATUS)")

        # Include root agent path in paths list (status is always 'owned' now).
        $installPaths.Add($rootAgentFile)
    }

    # Manifest-seam entry gate (PLAN risk #3, delivery-001->002 seam).
    # Runs BEFORE Write-AidManifest so a contaminated bundle never writes to disk.
    # Assert that the new bundle's path set does NOT contain any retired roots.
    # If a retired path leaked into the new manifest, fail loudly -- do not prune
    # against a contaminated manifest (content-isolation cornerstone).
    $retiredRoots = @('.agents/', '.cursor/rules/', '.agent/rules/')
    foreach ($rr in $retiredRoots) {
        foreach ($p in $installPaths) {
            $pNorm = $p -replace '\\', '/'
            if ($pNorm.StartsWith($rr, [System.StringComparison]::Ordinal)) {
                [Console]::Error.WriteLine("ERROR: aid-install-core: manifest-seam violation: retired root '$rr' leaked into the new bundle manifest (path: $p). Aborting install to protect user content.")
                return 1
            }
        }
    }

    # Write manifest (merge).
    Write-AidManifest -ManifestPath $manifest -Tool $Tool -Version $Version `
        -Paths @($installPaths) -RootEntries @($rootEntries)

    # Retired-root migration sweep (FR7/FR7a).
    # Remove AID-owned content from retired layout dirs BEFORE the normal prune,
    # so that old .agents\, .cursor\rules\, .agent\rules\ trees are cleaned up.
    # A non-zero rc from Install-AidTool is treated as a mid-commit failure (caller
    # prints the "re-run to heal" message); this function returns 0 (WARN-not-fail).
    Invoke-MigrateRetiredLayout -Target $Target -Tool $Tool -AidVerbose $AidVerbose

    # Prune stale AID-owned files (Pillar 2, R7).
    # Build a HashSet from the new manifest path set for O(1) lookup.
    $pruneSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($p in $installPaths) { $pruneSet.Add($p) | Out-Null }
    Invoke-PruneToolDirs -Target $Target -Tool $Tool -ManifestPathSet $pruneSet -AidVerbose $AidVerbose

    # Write version marker.
    Write-VersionMarker -Target $Target -Version $Version

    # Project-level provisioning (work-007): seed required settings.yml and
    # maintain the .gitignore AID region. Both idempotent; safe per-tool.
    script:Initialize-AidSettingsFile -Target $Target -Tool $Tool
    script:Update-AidGitignore -Target $Target

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

    # Report project-level provisioning actions (work-007; always shown).
    if ($script:_SeededSettings) { Write-Host "  Created .aid/settings.yml from template" }
    switch ($script:_GitignoreAction) {
        'created' { Write-Host "  Created .gitignore with AID exclusions" }
        'updated' { Write-Host "  Updated .gitignore AID exclusions" }
    }

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
            # Guard all per-tool property accesses via PSObject.Properties['key'] first.
            # Set-StrictMode -Version Latest (active in this module) throws
            # PropertyNotFoundException when accessing a missing property directly
            # (e.g. $t.root_agent_files on pre-work-005 manifests that lack it).
            # PSObject.Properties['key'] returns $null safely for absent properties.
            $ver = if ($t.PSObject.Properties['version']) { [string]$t.version } else { '' }
            # Determine root agent file for this tool.
            $rootAgent = switch ($tid) {
                'claude-code' { 'CLAUDE.md' }
                default       { 'AGENTS.md' }
            }
            # Read root agent status from manifest.
            $rootStatus = ''
            $rafEntries = if ($t.PSObject.Properties['root_agent_files']) { $t.root_agent_files } else { $null }
            if ($rafEntries) {
                foreach ($entry in $rafEntries) {
                    if ($entry.PSObject.Properties['path'] -and ($entry.path -eq $rootAgent)) {
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
        if ($data.PSObject.Properties['aid_version'] -and $data.aid_version) { $aidVersion = $data.aid_version }
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
    'Invoke-AidProvisionSharedStateHome',
    'Invoke-PruneToolDirs'
)
