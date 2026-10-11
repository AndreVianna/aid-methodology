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
#   Resolve-AidVersion                           - release version to install; throws on fail.
#                                                   CLI-version-aware: a pre-release running CLI
#                                                   prefers the newest pre-release release, else
#                                                   falls back to the latest stable; a stable CLI
#                                                   always resolves the latest stable (unchanged).
#   Test-AidPrerelease <version>                 - true when <version> matches a pre-release shape
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
#   Read-AidUpgradeRecovery <target>              - validates and reads v3 upgrade recovery state
#   Write-AidUpgradeRecovery <target> <tools> <retired> - atomically writes v3 recovery state
#   Clear-AidUpgradeRecovery <target>              - removes completed v3 recovery state
#   Test-AidOwnedPath <target> <path>              - path-based v3 legacy ownership predicate
#   Invoke-RetireV3Layout <target> <tools>         - archives v3-owned paths before fresh install
#   Read-ManifestTools <manifest>                - [string[]] tool ids (keys of tools object)
#   Write-AidManifest <manifest> <tool> <version> <paths> <rootEntries>
#                                                - atomic write/merge of manifest JSON
#   Remove-ManifestTool <manifest> <tool>        - removes a tool section from manifest
#   Test-ManifestExists <manifest>               - returns $true when manifest exists/parseable
#   Uninstall-AidTool <manifest> <tool> <target> [aidVerbose] - manifest-driven removal
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

# v3-upgrade flag read by Install-AidShared. bin/aid.ps1 (dot-sourced) re-assigns it per run;
# initialised here so an Import-Module caller (install.ps1) never reads an unset variable.
$script:_AidV3Upgrade = $false

# Module-level prune counter for shared-layout prune accounting.
$script:_PruneRemoved = 0

# Module-level project-provisioning state (work-007). Reset by Install-AidTool.
$script:_SeededSettings  = $false
$script:_GitignoreAction = 'unchanged'
# Settings format stamp. MUST equal bin/aid AID_SUPPORTED_FORMAT / bin/aid.ps1
# AidSupportedFormat. Used to stamp a seeded settings.yml so the format gate is quiet.
$script:_AidSupportedFormat = 5  # format 5: shared skills and runtime layout

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

$script:AID_REPO_SLUG    = "AndreVianna/aid-methodology"
$script:AID_API_BASE     = "https://api.github.com/repos/$($script:AID_REPO_SLUG)"
$script:AID_DOWNLOAD_BASE = "https://github.com/$($script:AID_REPO_SLUG)/releases/download"
# Endpoint overrides (tests / local fixture server) are honored ONLY when
# AID_ALLOW_ENDPOINT_OVERRIDE is 1 or true -- same gate as the bash twin.
if ($env:AID_ALLOW_ENDPOINT_OVERRIDE -eq '1' -or $env:AID_ALLOW_ENDPOINT_OVERRIDE -eq 'true') {
    if ($env:AID_API_BASE) { $script:AID_API_BASE = $env:AID_API_BASE }
    if ($env:AID_DOWNLOAD_BASE) { $script:AID_DOWNLOAD_BASE = $env:AID_DOWNLOAD_BASE }
}

$script:AID_TOOLS = @('claude-code', 'codex', 'cursor', 'copilot-cli', 'antigravity')

# Root agent file per tool.
function script:Get-RootAgentFile {
    param([string]$Tool)
    return 'AGENTS.md'
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
    # codex: .codex only; legacy .agents/aid is handled by clean-slate update.
    if (Test-Path (Join-Path $TargetPath '.codex') -PathType Container) {
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
        [Console]::Error.WriteLine("ERROR: cannot auto-detect host tool; specify the tool explicitly (e.g. 'aid add <name>')")
        return $null
    } else {
        $list = $found -join ', '
        [Console]::Error.WriteLine("ERROR: ambiguous host tool (found: $list); specify the tool explicitly (e.g. 'aid add <name>')")
        return $null
    }
}

# ---------------------------------------------------------------------------
# Version resolution (online)
# ---------------------------------------------------------------------------

# Test-AidPrerelease <Version> - mirror of the bash twin's _aid_is_prerelease
# (itself mirroring canonical/aid/scripts/release/check-version-sync.sh's
# _is_prerelease() / .github/workflows/release.yml -- kept in sync
# deliberately, do not invent a divergent regex here). True when <Version>
# (bare semver, no leading 'v') matches a pre-release shape: an alpha/beta/
# preview/pre/rc/a/b/c suffix (e.g. '2.2.3b1'), or a SemVer '-' pre-release tag.
function Test-AidPrerelease {
    param([string]$Version)
    $re = '^[0-9]+\.[0-9]+\.[0-9]+([._-]?(alpha|beta|preview|pre|rc|a|b|c)[0-9]*|-[0-9A-Za-z.-]+)$'
    return [bool]([regex]::IsMatch($Version, $re))
}

# Get-AidFirstPrereleaseTag <ListResponse> - given a deserialized GitHub
# /releases list (array of release objects, newest first), returns the
# tag_name of the FIRST entry whose .prerelease is $true (the newest
# pre-release). Returns $null when none is found.
function script:Get-AidFirstPrereleaseTag {
    param($ListResponse)
    foreach ($rel in @($ListResponse)) {
        if ($rel.prerelease -eq $true -and $rel.tag_name) {
            return $rel.tag_name
        }
    }
    return $null
}

# Resolve-AidVersion - fetch the release tag to install from the GitHub API.
# Returns the version without leading 'v'.  Returns $null on failure.
#
# CLI-version-aware (release-v2.2.3b1): when the RUNNING CLI itself is a
# pre-release (its own $AID_CODE_HOME/VERSION matches Test-AidPrerelease),
# prefer the newest pre-release release from the GitHub releases LIST; fall
# back to the latest stable (/releases/latest) when no pre-release exists, or
# when the list fetch itself fails (fail-safe -- never hard-error the update
# because of the beta lookup). A stable-CLI install is unaffected: always
# /releases/latest, unchanged.
#
# $script:_AidCodeHome is set by the CALLING script (bin/aid.ps1); this module
# is dot-sourced into that script's own scope for the update reach (never
# Import-Module'd there), so the variable is visible here. Guarded via
# Get-Variable (rather than a bare reference) so a hypothetical standalone
# Import-Module caller -- which would NOT share that scope -- degrades safely
# to "CLI version unknown" (treated the same as stable: unchanged /latest).
function Resolve-AidVersion {
    $url = "$($script:AID_API_BASE)/releases/latest"
    $headers = @{}
    $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $env:GH_TOKEN } else { '' }
    if ($token) {
        $headers['Authorization'] = "Bearer $token"
    }

    $cliVersion = ''
    $codeHomeVar = Get-Variable -Name '_AidCodeHome' -Scope Script -ErrorAction SilentlyContinue
    if ($codeHomeVar -and $codeHomeVar.Value) {
        $verFile = Join-Path $codeHomeVar.Value 'VERSION'
        if (Test-Path $verFile -PathType Leaf) {
            $cliVersion = (Get-Content -LiteralPath $verFile -Raw -ErrorAction SilentlyContinue).Trim()
        }
    }

    if ($cliVersion -and (Test-AidPrerelease $cliVersion)) {
        $listUrl = "$($script:AID_API_BASE)/releases"
        try {
            $listResponse = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get -ErrorAction Stop
            $preTag = script:Get-AidFirstPrereleaseTag -ListResponse $listResponse
            if ($preTag) {
                return $preTag -replace '^v', ''
            }
        } catch {
            # No pre-release found / list fetch failed -- fall through to the
            # stable /releases/latest lookup below (fail-safe).
        }
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

# script:Get-AidRemoteFile <uri> <outFile> <headers> - download one file. file:// URIs
# (the endpoint-override fixture form; curl reads them in the bash twin) are copied
# from the local path because Invoke-WebRequest rejects the 'file' scheme.
function script:Get-AidRemoteFile {
    param([string]$Uri, [string]$OutFile, $Headers)
    if ($Uri.StartsWith('file://', [System.StringComparison]::OrdinalIgnoreCase)) {
        $local = ([System.Uri]$Uri).LocalPath
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { throw "file not found: $local" }
        Copy-Item -LiteralPath $local -Destination $OutFile -Force -ErrorAction Stop
        return
    }
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Headers $Headers -UseBasicParsing -ErrorAction Stop
}

# Fetch-Tarball <tool> <version> <destDir>
# Downloads the tarball + SHA256SUMS into destDir and verifies.
# Returns $true on success, $false on failure.
function Fetch-AidArtifact {
    param(
        [ValidateSet('shared','tool')][string]$Kind,
        [string]$Tool,
        [string]$Version,
        [string]$DestDir
    )
    $filename  = if ($Kind -eq 'shared') { "aid-shared-v$Version.tar.gz" } else { "aid-$Tool-v$Version.tar.gz" }
    $url       = "$($script:AID_DOWNLOAD_BASE)/v$Version/$filename"
    $sumsUrl   = "$($script:AID_DOWNLOAD_BASE)/v$Version/SHA256SUMS"
    $tarball   = Join-Path $DestDir $filename
    $sumsFile  = Join-Path $DestDir 'SHA256SUMS'

    $headers = @{}
    $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $env:GH_TOKEN } else { '' }
    if ($token) {
        $headers['Authorization'] = "Bearer $token"
    }

    if ($Kind -eq 'tool') { [Console]::Error.WriteLine("Fetching $filename ...") }
    try {
        script:Get-AidRemoteFile -Uri $url -OutFile $tarball -Headers $headers
    } catch {
        $statusCode = 0
        try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
        if ($Kind -eq 'shared' -and $statusCode -eq 404) {
            [Console]::Error.WriteLine("release v$Version has no shared payload -- it predates the shared layout and cannot be installed by this CLI; omit --version or use an older aid CLI")
            return $false
        }
        [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to download $url : $_")
        return $false
    }

    # Fetch SHA256SUMS -- fail-closed. Every published release (release.sh Step 6:
    # "Emit SHA256SUMS") ships a SHA256SUMS asset alongside every tarball, so a
    # fetch failure, a 404, or an empty response means the release is broken or
    # the request was tampered with/redirected -- never a legitimate "older
    # release without SHA256SUMS". Refuse to install an unverified tarball
    # rather than warn-and-proceed.
    try {
        script:Get-AidRemoteFile -Uri $sumsUrl -OutFile $sumsFile -Headers $headers
    } catch {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: could not fetch SHA256SUMS from $sumsUrl; refusing to install unverified tarball (fail-closed)")
        return $false
    }
    if (-not (Test-Path $sumsFile -PathType Leaf) -or (Get-Item -LiteralPath $sumsFile).Length -eq 0) {
        [Console]::Error.WriteLine("ERROR: AidInstallCore: SHA256SUMS from $sumsUrl was empty; refusing to install unverified tarball (fail-closed)")
        return $false
    }
    if (-not (Invoke-VerifyChecksum -Tarball $tarball -SumsFile $sumsFile)) {
        return $false
    }

    return $true
}

function Fetch-Tarball {
    param([string]$Tool, [string]$Version, [string]$DestDir)
    return (Fetch-AidArtifact -Kind tool -Tool $Tool -Version $Version -DestDir $DestDir)
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

function Expand-AidPayload {
    param([string]$Tarball, [string]$DestDir)
    $tarExe = Get-Command 'tar' -ErrorAction SilentlyContinue
    if (-not $tarExe) { [Console]::Error.WriteLine('ERROR: AidInstallCore: tar is required to safely extract payloads'); return $false }
    try {
        $members = @(& tar -tzf $Tarball 2>$null)
        if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to list payload: $Tarball"); return $false }
        foreach ($member in $members) {
            $name = [string]$member
            if ([System.IO.Path]::IsPathRooted($name) -or $name -match '^[A-Za-z]:' -or $name -match '(^|[/\\])\.\.([/\\]|$)' -or $name -match '\\') {
                [Console]::Error.WriteLine("ERROR: AidInstallCore: unsafe payload member: $name"); return $false
            }
        }
        $verbose = @(& tar -tvzf $Tarball 2>$null)
        if ($LASTEXITCODE -ne 0 -or @($verbose | Where-Object { $_ -match '^[lh]' }).Count -gt 0) {
            [Console]::Error.WriteLine("ERROR: AidInstallCore: payload links are not allowed: $Tarball"); return $false
        }
        if (-not (Test-Path -LiteralPath $DestDir -PathType Container)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }
        & tar -xzf $Tarball -C $DestDir 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine("ERROR: AidInstallCore: failed to extract payload: $Tarball"); return $false }
        return $true
    } catch { [Console]::Error.WriteLine("ERROR: AidInstallCore: payload extraction failed: $_"); return $false }
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
# Descriptor reader, .aid/.trash/ moves and guarded copy (twins of the bash primitives)
# ---------------------------------------------------------------------------

# Read-AidKvConf <path>
# Returns "key=value" strings in file order (a repeated key is a list). Split at the
# FIRST '='; '#' lines, blank lines and lines without '=' are ignored. Never evaluated.
# Throws, naming the file, on a non-ASCII byte, a CR, or an unreadable file.
function Read-AidKvConf {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "AidInstallCore: descriptor not readable: $Path"
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    foreach ($b in $bytes) {
        if ($b -gt 127 -or $b -eq 13) {
            throw "AidInstallCore: descriptor must be ASCII with LF line endings only: $Path"
        }
    }
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $text.Split("`n")) {
        if ($line -eq '') { continue }
        if ($line.StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        if ($line.IndexOf('=') -le 0) { continue }
        $out.Add($line)
    }
    return ,$out.ToArray()
}

# Move-AidToTrash <root> <file> [<utcStamp>]
# Moves <file> (under <root>) to <root>/.aid/.trash/<relative path> under the same
# collision policy as trash_file: absent -> move; identical bytes -> remove the source;
# different bytes -> rename the occupant to <dest>.<stamp>, or the first unused
# <dest>.<stamp>.N (N = 1, 2, ...), then move the source in. Throws, source untouched,
# when the file is outside <root> or a step fails. <utcStamp> defaults to UTC now.
function Move-AidToTrash {
    param(
        [string]$Root,
        [string]$File,
        [string]$UtcStamp = ''
    )
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([char]'\', [char]'/')
    $srcFull = [System.IO.Path]::GetFullPath($File)
    $prefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $srcFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "AidInstallCore: trash source is outside the project root: $File"
    }
    if (-not (Test-Path -LiteralPath $srcFull -PathType Leaf)) {
        throw "AidInstallCore: trash source is not a regular file: $File"
    }
    $rel = $srcFull.Substring($prefix.Length)
    if ($UtcStamp -eq '') {
        $UtcStamp = [System.DateTime]::UtcNow.ToString('yyyyMMdd\THHmmss\Z', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $dest = Join-Path (Join-Path (Join-Path $rootFull '.aid') '.trash') $rel
    $destDir = [System.IO.Path]::GetDirectoryName($dest)
    if (-not (Test-Path -LiteralPath $destDir -PathType Container)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (Test-Path -LiteralPath $dest -PathType Container) {
        throw "AidInstallCore: trash destination is a directory: $dest"
    }
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        if ((Get-Sha256File -FilePath $srcFull) -eq (Get-Sha256File -FilePath $dest)) {
            Remove-Item -LiteralPath $srcFull -Force
            return
        }
        $cand = "$dest.$UtcStamp"
        $n = 0
        while (Test-Path -LiteralPath $cand) {
            $n++
            $cand = "$dest.$UtcStamp.$n"
        }
        try {
            Move-Item -LiteralPath $dest -Destination $cand -ErrorAction Stop
        } catch {
            throw "AidInstallCore: could not rotate trash entry $dest; source kept: $File"
        }
    }
    try {
        Move-Item -LiteralPath $srcFull -Destination $dest -ErrorAction Stop
    } catch {
        throw "AidInstallCore: could not move $File to $dest"
    }
}

# Copy-AidFileGuarded <src> <dst> [<recordedSha256>] [<root>] [<aidVerbose>]
# Twin of copy_file_guarded. Counters match Copy-AidFile.
#   absent -> copy (copied); identical -> leave (up to date);
#   differing and not drifted -> overwrite, no trash entry (updated);
#   differing and drifted -> Move-AidToTrash, then copy (updated).
# Drifted: the sha256 differs from <recordedSha256>, or none is recorded (empty).
function Copy-AidFileGuarded {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$RecordedSha256 = '',
        [string]$Root = '',
        [bool]$AidVerbose = $false
    )
    if ($Root -eq '') { $Root = $PWD.Path }
    $dstDir = [System.IO.Path]::GetDirectoryName($Dst)
    if ($dstDir -and -not (Test-Path -LiteralPath $dstDir -PathType Container)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Dst -PathType Leaf)) {
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

    $srcHash = Get-Sha256File -FilePath $Src
    $dstHash = Get-Sha256File -FilePath $Dst
    if ($srcHash -eq $dstHash) {
        $script:_CopyCountUpToDate++
        if ($AidVerbose) { Write-Host "Up to date: $Dst" }
        return
    }

    $drifted = $false
    if ($RecordedSha256 -eq '' -or $dstHash -ne $RecordedSha256.ToLower()) { $drifted = $true }
    if ($drifted) {
        try {
            Move-AidToTrash -Root $Root -File $Dst
        } catch {
            [Console]::Error.WriteLine("ERROR: AidInstallCore: drifted file left in place, not overwritten: $Dst -- $_")
            $script:_CopyCountFailed++
            return
        }
        if ($AidVerbose) { Write-Host "Trashed: $Dst" }
    }
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

# Fixed LF root-context regions. These are install-core constants, never payload files.
$script:_AidAgentsPointerRegion = "<!-- AID:BEGIN -->`n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->`n@.aid/runtime/rules.md`nBefore acting, read and follow ``.aid/runtime/rules.md`` (AID rules).`n<!-- AID:END -->`n"
$script:_AidClaudeImportRegion = "<!-- AID:BEGIN -->`n@AGENTS.md`n<!-- AID:END -->`n"

# Repairs one fixed root region while preserving all bytes outside it.
function script:Repair-AidRootRegion {
    param([string]$File, [string]$Region, [string]$Root = '')
    if ($Root -eq '') { $Root = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($File)) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $regionBytes = $encoding.GetBytes($Region)
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        $dir = [System.IO.Path]::GetDirectoryName($File)
        if ($dir -and -not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes($File, $regionBytes)
        return
    }
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($File))
    $chunks = [regex]::Matches($text, '[^\n]*\n|[^\n]+$') | ForEach-Object { $_.Value }
    $expected = $Region.Split("`n") | Where-Object { $_ -ne '' }
    $values = @($chunks | ForEach-Object { $_.TrimEnd("`n").TrimEnd("`r") })
    $managed = @{}
    foreach ($line in $expected) { $managed[$line] = $true }
    $positions = @(); for ($i=0; $i -lt $values.Count; $i++) { if ($managed.ContainsKey($values[$i])) { $positions += $i } }
    if ($positions.Count -eq 0) {
        $suffix = if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { "`n" } else { '' }
        [System.IO.File]::WriteAllBytes($File, $encoding.GetBytes($text + $suffix + $Region)); return
    }
    $startCount = 0
    for ($i=0; $i -le $values.Count-$expected.Count; $i++) {
        $match = $true
        for ($j=0; $j -lt $expected.Count; $j++) { if ($values[$i+$j] -cne $expected[$j]) { $match=$false; break } }
        if ($match) { $startCount++ }
    }
    if ($startCount -eq 1 -and $positions.Count -eq $expected.Count) { return }
    Move-AidToTrash -Root $Root -File $File
    $sb = New-Object System.Text.StringBuilder
    $inserted = $false
    foreach ($i in 0..($chunks.Count-1)) {
        if ($managed.ContainsKey($values[$i])) {
            if (-not $inserted) { [void]$sb.Append($Region); $inserted=$true }
        } else { [void]$sb.Append($chunks[$i]) }
    }
    if (-not $inserted) { [void]$sb.Append($Region) }
    [System.IO.File]::WriteAllBytes($File, $encoding.GetBytes($sb.ToString()))
}

function script:Invoke-EnsureClaudeMdRegion {
    param([string]$File = (Join-Path $PWD.Path 'CLAUDE.md'), [string]$Root = '')
    script:Repair-AidRootRegion -File $File -Region $script:_AidClaudeImportRegion -Root $Root
    return ([System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($script:_AidClaudeImportRegion))).Replace('-', '').ToLowerInvariant())
}

function script:Invoke-RemoveClaudeMdRegion {
    param([string]$File, [string]$RecordedSha256, [string]$Root = '')
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { return }
    if ($Root -eq '') { $Root = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($File)) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($File))
    $linePattern = '(?m)^<!-- AID:(?:BEGIN|END) -->(?=\r?$)'
    $markers = [regex]::Matches($text, $linePattern)
    $begins = @($markers | Where-Object { $_.Value -ceq '<!-- AID:BEGIN -->' })
    $ends = @($markers | Where-Object { $_.Value -ceq '<!-- AID:END -->' })
    if ($begins.Count -ne 1 -or $ends.Count -ne 1 -or $begins[0].Index -ge $ends[0].Index) { return }
    $begin = $begins[0]; $end = $ends[0]
    $start = $begin.Index
    $finish = $end.Index + $end.Length
    if ($finish + 2 -le $text.Length -and $text.Substring($finish, 2) -ceq "`r`n") { $finish += 2 }
    elseif ($finish -lt $text.Length -and $text.Substring($finish, 1) -ceq "`n") { $finish++ }
    $matchText = $text.Substring($start, $finish - $start)
    $canonical = $matchText.Replace("`r`n", "`n")
    $regionSha = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new($encoding.GetBytes($canonical))) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($regionSha -ne $RecordedSha256) { Move-AidToTrash -Root $Root -File $File }
    $rest = $text.Remove($start, $finish - $start)
    if ($rest.Trim().Length -eq 0) { Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue }
    else { [System.IO.File]::WriteAllBytes($File, $encoding.GetBytes($rest)) }
}

function script:Repair-AidInlineRootRegion {
    param([string]$File, [string]$Region, [string]$Root)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        [System.IO.File]::WriteAllBytes($File, $encoding.GetBytes($Region)); return
    }
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($File))
    $begin = '<!-- AID:BEGIN -->'; $end = '<!-- AID:END -->'
    $linePattern = '(?m)^<!-- AID:(?:BEGIN|END) -->(?=\r?$)'
    $markers = [regex]::Matches($text, $linePattern)
    $begins = @($markers | Where-Object { $_.Value -ceq $begin })
    $ends = @($markers | Where-Object { $_.Value -ceq $end })
    if ($begins.Count -eq 1 -and $ends.Count -eq 1 -and $begins[0].Index -lt $ends[0].Index) {
        $beginMarker = $begins[0]; $endMarker = $ends[0]
        $beginLineEnd = $beginMarker.Index + $beginMarker.Length
        if ($text.Substring($beginLineEnd, 2) -ceq "`r`n") { $innerStart = $beginLineEnd + 2 }
        elseif ($text.Substring($beginLineEnd, 1) -ceq "`n") { $innerStart = $beginLineEnd + 1 }
        else { script:Repair-AidRootRegion -File $File -Region $Region -Root $Root; return }
        $replacement = $Region.Substring($Region.IndexOf("`n") + 1)
        $replacement = $replacement.Substring(0, $replacement.LastIndexOf($end))
        $updated = $text.Substring(0, $innerStart) + $replacement + $text.Substring($endMarker.Index)
        [System.IO.File]::WriteAllBytes($File, $encoding.GetBytes($updated)); return
    }
    script:Repair-AidRootRegion -File $File -Region $Region -Root $Root
}

function script:Copy-RootAgentFile {
    param([string]$Src, [string]$Dst, [string]$Tool, [bool]$Force=$false, [string]$Manifest='', [bool]$AidVerbose=$false)
    $root = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($Dst))
    $hadDst = Test-Path -LiteralPath $Dst -PathType Leaf
    $beforeSha = if ($hadDst) { Get-Sha256File -FilePath $Dst } else { '' }
    $inline = $false
    $conf = Join-Path ([System.IO.Path]::GetDirectoryName($Src)) 'aid-tool.conf'
    if (Test-Path -LiteralPath $conf -PathType Leaf) { $inline = @(Get-Content -LiteralPath $conf | Where-Object { $_ -ceq 'rules_inline=true' }).Count -gt 0 }
    if ($Manifest -and (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
        try {
            $manifestData = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
            foreach ($entry in $manifestData.tools.PSObject.Properties) {
                $inlineProperty = $entry.Value.PSObject.Properties['rules_inline']
                if ($inlineProperty -and $inlineProperty.Value -eq $true) { $inline = $true; break }
            }
        } catch {}
    }
    if ($inline) {
        $rulesPath = Join-Path (Join-Path $root '.aid') 'runtime/rules.md'
        if (-not (Test-Path -LiteralPath $rulesPath -PathType Leaf)) { throw "AidInstallCore: rules_inline requested but runtime rules are missing: $rulesPath" }
        $rules = [System.IO.File]::ReadAllText($rulesPath, (New-Object System.Text.UTF8Encoding($false)))
        $region = "<!-- AID:BEGIN -->`n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->`n" + $rules + "<!-- AID:END -->`n"
        script:Repair-AidInlineRootRegion -File $Dst -Region $region -Root $root
    } else { script:Repair-AidRootRegion -File $Dst -Region $script:_AidAgentsPointerRegion -Root $root }
    $script:_CORE_ROOT_AGENT_STATUS = 'owned'
    if ($inline) { $managedRegion = $region } else { $managedRegion = $script:_AidAgentsPointerRegion }
    $script:_CORE_ROOT_AGENT_REGION_SHA = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($managedRegion))) -Algorithm SHA256).Hash.ToLowerInvariant()
    $script:_CORE_ROOT_AGENT_FILE_SHA = Get-Sha256File -FilePath $Dst
    if (-not $hadDst) { $script:_CopyCountCopied++; if ($AidVerbose) { Write-Host "Copied: $Dst" } }
    elseif ($beforeSha -eq $script:_CORE_ROOT_AGENT_FILE_SHA) { $script:_CopyCountUpToDate++; if ($AidVerbose) { Write-Host "Up to date: $Dst" } }
    else { $script:_CopyCountUpdated++; if ($AidVerbose) { Write-Host "Updated: $Dst" } }
    return 0
}

# Manifest - JSON reader/writer
# ---------------------------------------------------------------------------

# Read-ManifestToolPaths <manifest> <tool>
# Returns an array of paths from tools.<tool>.paths.
function Read-ManifestToolPaths {
    param([string]$ManifestPath, [string]$Tool)
    if (-not (Test-Path $ManifestPath -PathType Leaf)) { return @() }
    try {
        $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
        $toolData = if ($data.tools -and $data.tools.PSObject.Properties[$Tool]) { $data.tools.$Tool } else { $null }
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
        $toolData = if ($data.tools -and $data.tools.PSObject.Properties[$Tool]) { $data.tools.$Tool } else { $null }
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
        $toolData = if ($data.tools -and $data.tools.PSObject.Properties[$Tool]) { $data.tools.$Tool } else { $null }
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
        $toolData = if ($data.tools -and $data.tools.PSObject.Properties[$Tool]) { $data.tools.$Tool } else { $null }
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
            # Enumerate explicitly: `.PSObject.Properties.Name` is member enumeration, which
            # throws under Set-StrictMode -Version Latest when "tools" is an empty object.
            $keys = @(foreach ($p in $data.tools.PSObject.Properties) { $p.Name })
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

# script:Format-AidTimestamp - render a manifest timestamp back to ISO-8601 UTC.
#
# WHY THIS EXISTS (tech-debt W4-4). ConvertFrom-Json does NOT hand back the JSON
# *string* for a timestamp: it silently coerces an ISO-8601 value into a
# [System.DateTime]. Every "preserve the existing installed_at" read below therefore
# yields a DateTime, and string-interpolating that into the JSON writer renders it in
# the CURRENT CULTURE's short format -- '07/26/2026 17:19:24' on en-US -- destroying
# the very value it claims to preserve.
#
# It is a ONE-WAY RATCHET, which is what makes it insidious: an already-corrupted
# value parses back as a [String] and is then preserved faithfully forever. So the
# first PowerShell install/update degrades a stamp and every later run keeps the
# degraded form. AID's own dogfood manifest carried '2026-06-06T20:01:03Z' until an
# `aid update` rewrote it as '06/06/2026 20:01:03', where it sat for two months.
#
# Verified by experiment, not inferred:
#   '{"installed_at":"2026-07-26T17:19:24Z"}' | ConvertFrom-Json -> System.DateTime
#                                            -> interpolates '07/26/2026 17:19:24'
#   '{"installed_at":"06/06/2026 20:01:03"}'  | ConvertFrom-Json -> System.String
#                                            -> passes through unchanged
#   round-trip through this helper           -> '2026-07-26T17:19:24Z' (byte-exact)
#
# NOTE: `ConvertFrom-Json -AsHashtable` does NOT avoid the coercion (checked -- still
# System.DateTime), so switching the parser is not a fix.
#
# The bash writers are unaffected and need no lockstep change: bin/aid emits
# `date -u +%Y-%m-%dT%H:%M:%SZ`, and lib/aid-install-core.sh moves the value as text
# through json.load/sed and never re-renders it (both verified).
#
# A non-DateTime value is returned as a plain string untouched, so an already-correct
# ISO string and an already-corrupted one are both passed through as-is: this repairs
# what it can render and never invents a value.
function script:Format-AidTimestamp {
    param($Value)
    if ($null -eq $Value) { return '' }
    if ($Value -is [datetime]) { return $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
    if ($Value -is [datetimeoffset]) { return $Value.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ') }
    return [string]$Value
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
    [void]$sb.Append("  `"format_version`": 2,`n")
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
# Key order contract: format_version, aid_version, installed_at, tools;
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
        # Re-render: ConvertFrom-Json handed back a [DateTime], not the JSON string (W4-4).
        $topInstalledAt = script:Format-AidTimestamp $existingData.installed_at
    }

    # Build the tools map preserving existing tools, then adding/merging the current tool.
    # Use ordered dictionary so key order is deterministic.
    $toolsMap = [System.Collections.Specialized.OrderedDictionary]::new()

    # Preserve existing tools (other than the current one).
    $existingTools = if ($existingData -and $existingData.PSObject.Properties['tools']) { $existingData.tools } else { $null }
    if ($existingTools) {
        $existingTools.PSObject.Properties | ForEach-Object {
            $tid = $_.Name
            if ($tid -ne $Tool) {
                $t   = $_.Value
                # Guard per-tool properties: old manifests lack root_agent_files; use
                # PSObject.Properties['key'] check before direct access (StrictMode-safe).
                # Fill the list with Add(): `$tP = if (...) { $list }` sends the list through
                # the pipeline, which unrolls it -- a single-path tool would come back as a
                # bare [string] and blow up on .Count in script:Build-ManifestJson.
                $tP  = [System.Collections.Generic.List[string]]::new()
                if ($t.PSObject.Properties['paths'] -and $t.paths) {
                    foreach ($tPath in $t.paths) { $tP.Add([string]$tPath) }
                }
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
                    # Re-render: ConvertFrom-Json handed back a [DateTime] (W4-4).
                    InstalledAt   = if ($t.PSObject.Properties['installed_at'] -and $t.installed_at) { script:Format-AidTimestamp $t.installed_at } else { $now }
                    Paths         = $tP
                    RootAgentFiles = $tR
                }
            }
        }
    }

    # Existing data for the current tool.
    $existingTool = $null
    # Indexer lookup, not `.PSObject.Properties.Name -contains`: the latter is member
    # enumeration and throws under Set-StrictMode -Version Latest when "tools" is `{}`.
    if ($existingTools -and $existingTools.PSObject.Properties[$Tool]) {
        $existingTool = $existingTools.$Tool
    }

    # tool installed_at: preserve existing.
    $toolInstalledAt = $now
    if ($existingTool -and $existingTool.PSObject.Properties['installed_at'] -and $existingTool.installed_at) {
        # Re-render: ConvertFrom-Json handed back a [DateTime] (W4-4).
        $toolInstalledAt = script:Format-AidTimestamp $existingTool.installed_at
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

# ---------------------------------------------------------------------------
# Format-3 manifest (twin of the bash _manifest_write_v3_* writers and the
# manifest_read_shared / manifest_read_tool_files / manifest_read_host readers)
# ---------------------------------------------------------------------------

# script:Get-AidV3Field <fields> <index> - field value, or '' when absent.
function script:Get-AidV3Field {
    param([string[]]$Fields, [int]$Index)
    if ($Fields.Length -gt $Index) { return $Fields[$Index] }
    return ''
}

# script:Get-AidV3Scalar <scalars> <key> - scalar record value, or ''.
function script:Get-AidV3Scalar {
    param($Scalars, [string]$Key)
    if ($Scalars.ContainsKey($Key)) { return [string]$Scalars[$Key] }
    return ''
}

# script:Get-AidV3Users <csv> <where> - the named tools in AID_TOOLS order; throws on unknown.
function script:Get-AidV3Users {
    param([string]$Csv, [string]$Where)
    $named = New-Object System.Collections.Generic.List[string]
    foreach ($u in $Csv.Split(',')) {
        if ($u -eq '') { continue }
        if (-not ($script:AID_TOOLS -ccontains $u)) {
            throw "AidInstallCore: manifest model: unknown tool '$u' in $Where"
        }
        $named.Add($u)
    }
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($t in $script:AID_TOOLS) {
        if ($named.Contains($t)) { $out.Add($t) }
    }
    return ,$out.ToArray()
}

# script:Sort-AidOrdinal <items> - ordinal (byte-order) sorted copy as string[]; nulls dropped.
function script:Sort-AidOrdinal {
    param($Items)
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($i in @($Items)) {
        if ($null -ne $i) { $list.Add([string]$i) }
    }
    $arr = $list.ToArray()
    [System.Array]::Sort($arr, [System.StringComparer]::Ordinal)
    return ,$arr
}

# script:Build-AidV3Files <records> - sorted "path<TAB>sha256" records as [{path, sha256}].
function script:Build-AidV3Files {
    param($Records)
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($r in (script:Sort-AidOrdinal $Records)) {
        $p = $r.Split("`t")
        $od = [System.Collections.Specialized.OrderedDictionary]::new()
        $od['path'] = $p[0]
        $od['sha256'] = $p[1]
        $out.Add($od)
    }
    return ,$out.ToArray()
}

# script:ConvertTo-AidV3Json <value> <depth> - Python json.dump(indent=2) layout.
function script:ConvertTo-AidV3Json {
    param($Value, [int]$Depth)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) {
        if ($Value) { return 'true' }
        return 'false'
    }
    if ($Value -is [int]) { return ([string]$Value) }
    if ($Value -is [System.Collections.Specialized.OrderedDictionary]) {
        if ($Value.Count -eq 0) { return '{}' }
        $pad = ' ' * (2 * ($Depth + 1))
        $items = New-Object System.Collections.Generic.List[string]
        foreach ($k in $Value.Keys) {
            $items.Add($pad + '"' + (script:Escape-JsonString ([string]$k)) + '": ' + (script:ConvertTo-AidV3Json $Value[$k] ($Depth + 1)))
        }
        return ("{`n" + [string]::Join(",`n", $items.ToArray()) + "`n" + (' ' * (2 * $Depth)) + '}')
    }
    if ($Value -is [System.Collections.IList]) {
        if ($Value.Count -eq 0) { return '[]' }
        $pad = ' ' * (2 * ($Depth + 1))
        $items = New-Object System.Collections.Generic.List[string]
        foreach ($item in $Value) {
            $items.Add($pad + (script:ConvertTo-AidV3Json $item ($Depth + 1)))
        }
        return ("[`n" + [string]::Join(",`n", $items.ToArray()) + "`n" + (' ' * (2 * $Depth)) + ']')
    }
    return ('"' + (script:Escape-JsonString ([string]$Value)) + '"')
}

# Write-AidManifestV3 <manifestPath> <modelPath>
# Twin of manifest_write_v3. The model grammar is documented in the bash section
# (TAB-separated records). Writes atomically: UTF-8 without BOM, LF, trailing LF.
function Write-AidManifestV3 {
    param(
        [string]$ManifestPath,
        [string]$ModelPath
    )
    if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
        throw "AidInstallCore: manifest model not readable: $ModelPath"
    }
    $text = [System.IO.File]::ReadAllText($ModelPath, [System.Text.Encoding]::ASCII)

    $scalars = @{}
    $lists = @{}
    foreach ($line in $text.Split("`n")) {
        if ($line -eq '') { continue }
        $f = $line.Split("`t")
        $key = $f[0]
        $rec = $null
        if ($key -eq 'shared.mirror') {
            $rec = (script:Get-AidV3Field $f 1) + "`t" + (script:Get-AidV3Field $f 2) + "`t" + (script:Get-AidV3Field $f 3)
        } elseif ($key.StartsWith('tools.') -and $key.EndsWith('.mirror')) {
            $rec = script:Get-AidV3Field $f 1
        } elseif ($key.EndsWith('.file') -and ($key.StartsWith('tools.') -or $key -eq 'shared.skills.file' -or $key -eq 'shared.runtime.file')) {
            $rec = (script:Get-AidV3Field $f 1) + "`t" + (script:Get-AidV3Field $f 2)
        }
        if ($null -ne $rec) {
            if (-not $lists.ContainsKey($key)) { $lists[$key] = New-Object System.Collections.Generic.List[string] }
            $lists[$key].Add($rec)
        } else {
            $scalars[$key] = script:Get-AidV3Field $f 1
        }
    }

    $allKeys = @($scalars.Keys) + @($lists.Keys)
    foreach ($k in $allKeys) {
        if ($k.StartsWith('tools.')) {
            $t = $k.Substring(6).Split('.')[0]
            if (-not ($script:AID_TOOLS -ccontains $t)) {
                throw "AidInstallCore: manifest model ${ModelPath}: unknown tool '$t'"
            }
        }
    }

    $shared = [System.Collections.Specialized.OrderedDictionary]::new()
    foreach ($e in @('skills', 'runtime', 'agents_md', 'claude_md')) {
        $users = script:Get-AidV3Users (script:Get-AidV3Scalar $scalars "shared.$e.users") "shared.$e"
        if ($users.Count -eq 0) { continue }
        if ($e -eq 'skills' -or $e -eq 'runtime') {
            $keys = @('root', 'version', 'users', 'files')
        } elseif ($e -eq 'agents_md') {
            $keys = @('path', 'version', 'users', 'region_sha256', 'file_sha256')
        } else {
            $keys = @('path', 'version', 'users', 'region_sha256')
        }
        $ent = [System.Collections.Specialized.OrderedDictionary]::new()
        foreach ($k in $keys) {
            if ($k -eq 'users') {
                $ent['users'] = $users
            } elseif ($k -eq 'files') {
                $ent['files'] = script:Build-AidV3Files ($lists["shared.$e.file"])
            } else {
                $sk = "shared.$e.$k"
                if ($scalars.ContainsKey($sk)) { $ent[$k] = [string]$scalars[$sk] }
            }
        }
        $shared[$e] = $ent
    }

    $mrecs = (script:Sort-AidOrdinal ($lists['shared.mirror']))
    $seenDirs = New-Object System.Collections.Generic.HashSet[string]
    foreach ($r in $mrecs) {
        $d = $r.Split("`t")[0]
        if (-not $seenDirs.Add($d)) {
            throw "AidInstallCore: manifest model ${ModelPath}: duplicate shared.mirror directory"
        }
    }
    $mirrors = [System.Collections.Specialized.OrderedDictionary]::new()
    foreach ($r in $mrecs) {
        $p = $r.Split("`t")
        $us = script:Get-AidV3Users ($p[2]) "shared.mirror $($p[0])"
        if ($us.Count -eq 0) { continue }
        $m = [System.Collections.Specialized.OrderedDictionary]::new()
        $m['version'] = $p[1]
        $m['users'] = $us
        $mirrors[$p[0]] = $m
    }
    if ($mirrors.Count -gt 0) { $shared['mirrors'] = $mirrors }

    $tools = [System.Collections.Specialized.OrderedDictionary]::new()
    foreach ($t in $script:AID_TOOLS) {
        $pre = "tools.$t."
        $present = $false
        foreach ($k in $allKeys) {
            if ($k.StartsWith($pre, [System.StringComparison]::Ordinal)) { $present = $true }
        }
        if (-not $present) { continue }
        $ent = [System.Collections.Specialized.OrderedDictionary]::new()
        $ent['version'] = script:Get-AidV3Scalar $scalars ($pre + 'version')
        $ent['installed_at'] = script:Get-AidV3Scalar $scalars ($pre + 'installed_at')
        $ent['mirrors'] = script:Sort-AidOrdinal ($lists[$pre + 'mirror'])
        if ($scalars.ContainsKey($pre + 'worktree_root')) {
            $ent['worktree_root'] = [string]$scalars[$pre + 'worktree_root']
        }
        if ($scalars.ContainsKey($pre + 'rules_inline')) {
            if ($scalars[$pre + 'rules_inline'] -cne 'true') {
                throw "AidInstallCore: manifest model ${ModelPath}: rules_inline must be true ($t)"
            }
            $ent['rules_inline'] = $true
        }
        $files = script:Build-AidV3Files ($lists[$pre + 'file'])
        $ent['files'] = $files
        $paths = New-Object System.Collections.Generic.List[string]
        foreach ($fo in $files) { $paths.Add([string]$fo['path']) }
        $ent['paths'] = $paths.ToArray()
        $tools[$t] = $ent
    }

    $wr = script:Get-AidV3Scalar $scalars 'host.worktree_root'
    if ($wr -eq '') { $wr = '.aid/.worktrees' }
    $hostObj = [System.Collections.Specialized.OrderedDictionary]::new()
    $hostObj['worktree_root'] = $wr

    $top = [System.Collections.Specialized.OrderedDictionary]::new()
    $top['format_version'] = 3
    $top['aid_version'] = script:Get-AidV3Scalar $scalars 'aid_version'
    $top['installed_at'] = script:Get-AidV3Scalar $scalars 'installed_at'
    $top['host'] = $hostObj
    $top['shared'] = $shared
    $top['tools'] = $tools
    $json = (script:ConvertTo-AidV3Json $top 0) + "`n"

    $manifestDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
    if ($manifestDir -and -not (Test-Path -LiteralPath $manifestDir -PathType Container)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    $tmpPath = Join-Path $manifestDir (".manifest.tmp." + [System.IO.Path]::GetRandomFileName())
    try {
        [System.IO.File]::WriteAllBytes($tmpPath, [System.Text.Encoding]::UTF8.GetBytes($json))
        if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) { Remove-Item -LiteralPath $ManifestPath -Force }
        Move-Item -LiteralPath $tmpPath -Destination $ManifestPath -Force
    } catch {
        if (Test-Path -LiteralPath $tmpPath -PathType Leaf) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
        [Console]::Error.WriteLine("ERROR: AidInstallCore: manifest write failed: $_")
        throw
    }
}

# script:Read-AidManifestObject <path> - parsed manifest object, or $null when absent/unparseable.
function script:Read-AidManifestObject {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $obj = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        return $obj
    } catch {
        return $null
    }
}

# script:Get-AidJsonProp <obj> <name> - property value, or $null when absent (StrictMode-safe).
function script:Get-AidJsonProp {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    $p = $Obj.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

# Read-AidManifestShared <manifestPath>
# shared.* records in the model grammar (same records as manifest_read_shared).
function Read-AidManifestShared {
    param([string]$ManifestPath)
    $out = New-Object System.Collections.Generic.List[string]
    $root = script:Read-AidManifestObject -Path $ManifestPath
    $shared = script:Get-AidJsonProp $root 'shared'
    foreach ($e in @('skills', 'runtime', 'agents_md', 'claude_md')) {
        $ent = script:Get-AidJsonProp $shared $e
        if ($null -eq $ent) { continue }
        foreach ($p in $ent.PSObject.Properties) {
            if ($p.Name -eq 'users') {
                $out.Add("shared.$e.users`t" + [string]::Join(',', @($p.Value)))
            } elseif ($p.Name -eq 'files') {
                foreach ($f in @($p.Value)) {
                    $out.Add("shared.$e.file`t" + [string]$f.path + "`t" + [string]$f.sha256)
                }
            } else {
                $out.Add("shared.$e.$($p.Name)`t" + [string]$p.Value)
            }
        }
    }
    $mirrors = script:Get-AidJsonProp $shared 'mirrors'
    if ($null -ne $mirrors) {
        foreach ($p in $mirrors.PSObject.Properties) {
            $m = $p.Value
            $out.Add("shared.mirror`t" + $p.Name + "`t" + [string]$m.version + "`t" + [string]::Join(',', @($m.users)))
        }
    }
    return ,$out.ToArray()
}

# Read-AidManifestToolFiles <manifestPath> <tool>
# tools.<tool>.* records: mirror, worktree_root and rules_inline (only when declared), file.
function Read-AidManifestToolFiles {
    param([string]$ManifestPath, [string]$Tool)
    $out = New-Object System.Collections.Generic.List[string]
    $root = script:Read-AidManifestObject -Path $ManifestPath
    $tools = script:Get-AidJsonProp $root 'tools'
    $t = script:Get-AidJsonProp $tools $Tool
    if ($null -ne $t) {
        $mirrors = script:Get-AidJsonProp $t 'mirrors'
        if ($null -ne $mirrors) {
            foreach ($m in @($mirrors)) { $out.Add("tools.$Tool.mirror`t" + [string]$m) }
        }
        $wr = script:Get-AidJsonProp $t 'worktree_root'
        if ($null -ne $wr) { $out.Add("tools.$Tool.worktree_root`t" + [string]$wr) }
        $ri = script:Get-AidJsonProp $t 'rules_inline'
        if ($ri -eq $true) { $out.Add("tools.$Tool.rules_inline`ttrue") }
        $files = script:Get-AidJsonProp $t 'files'
        if ($null -ne $files) {
            foreach ($f in @($files)) {
                $out.Add("tools.$Tool.file`t" + [string]$f.path + "`t" + [string]$f.sha256)
            }
        }
    }
    return ,$out.ToArray()
}

# Read-AidManifestHost <manifestPath>
# host.worktree_root record (empty when the manifest has no host object).
function Read-AidManifestHost {
    param([string]$ManifestPath)
    $out = New-Object System.Collections.Generic.List[string]
    $root = script:Read-AidManifestObject -Path $ManifestPath
    $h = script:Get-AidJsonProp $root 'host'
    $wr = script:Get-AidJsonProp $h 'worktree_root'
    if ($null -ne $wr) { $out.Add("host.worktree_root`t" + [string]$wr) }
    return ,$out.ToArray()
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

    if ($data.PSObject.Properties['format_version'] -and $data.format_version -eq 3) {
        $toolProps = @($data.tools.PSObject.Properties | Where-Object { $_.Name -ne $Tool })
        if ($toolProps.Count -eq 0) { Remove-Item -LiteralPath $ManifestPath -Force; return }
        $data.tools.PSObject.Properties.Remove($Tool)
        $shared = script:Get-AidJsonProp $data 'shared'
        foreach ($name in @('skills','runtime','agents_md','claude_md')) {
            $entry = script:Get-AidJsonProp $shared $name
            if ($null -eq $entry) { continue }
            $usersProp = $entry.PSObject.Properties['users']
            if ($null -ne $usersProp) {
                $usersProp.Value = @($usersProp.Value | Where-Object { $_ -ne $Tool })
                if (@($usersProp.Value).Count -eq 0) {
                    if ($name -eq 'claude_md') { $shared.PSObject.Properties.Remove($name) }
                    else { $shared.PSObject.Properties.Remove($name) }
                }
            }
        }
        $mirrors = script:Get-AidJsonProp $shared 'mirrors'
        if ($null -ne $mirrors) {
            foreach ($p in @($mirrors.PSObject.Properties)) {
                $p.Value.users = @($p.Value.users | Where-Object { $_ -ne $Tool })
                if (@($p.Value.users).Count -eq 0) { $mirrors.PSObject.Properties.Remove($p.Name) }
            }
            if (@($mirrors.PSObject.Properties).Count -eq 0) { $shared.PSObject.Properties.Remove('mirrors') }
        }
        $remainingRoots = @($data.tools.PSObject.Properties | ForEach-Object {
            $p = $_.Value.PSObject.Properties['worktree_root']; if ($p -and $p.Value) { [string]$p.Value }
        } | Where-Object { $_ })
        $hostObj = script:Get-AidJsonProp $data 'host'
        if ($null -ne $hostObj) { $hostObj.worktree_root = if ($remainingRoots.Count -gt 0) { $remainingRoots[0] } else { '.aid/.worktrees' } }
        $json = ConvertTo-Json -InputObject $data -Depth 30
        [System.IO.File]::WriteAllText($ManifestPath, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
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
                    # Re-render: ConvertFrom-Json handed back a [DateTime] (W4-4).
                    InstalledAt    = if ($t.PSObject.Properties['installed_at'] -and $t.installed_at) { script:Format-AidTimestamp $t.installed_at } else { '' }
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

    # Re-render the preserved value: ConvertFrom-Json handed back a [DateTime] (W4-4).
    # The else-branch already emitted ISO-8601 correctly, which is what made the
    # corruption look intermittent -- a fresh stamp was fine, a preserved one was not.
    $topIat = if ($data.PSObject.Properties['installed_at'] -and $data.installed_at) { script:Format-AidTimestamp $data.installed_at } else { ([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')) }
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
        return ($null -ne $data.format_version) -or ($null -ne $data.manifest_version)
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
# Shared-layout prune (format 3)
# ---------------------------------------------------------------------------

function Invoke-PruneShared {
    param([string]$Target, [string]$PreviousManifest)
    $manifest = Join-Path $Target '.aid/.aid-manifest.json'
    $wanted = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $oldHashes = @{}
    $roots = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $previousRoots = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    if (Test-Path -LiteralPath $PreviousManifest -PathType Leaf) {
        foreach ($row in (Read-AidManifestShared -ManifestPath $PreviousManifest)) {
            $p = $row.Split("`t")
            if ($p[0] -eq 'shared.skills.file' -and $p.Count -ge 3) { $oldHashes[(Join-Path $Target ('.agents/skills/' + $p[1]))] = $p[2] }
            elseif ($p[0] -eq 'shared.runtime.file' -and $p.Count -ge 3) { $oldHashes[(Join-Path $Target ('.aid/runtime/' + $p[1]))] = $p[2] }
            elseif ($p[0] -eq 'shared.mirror' -and $p.Count -ge 2) { [void]$roots.Add($p[1]); [void]$previousRoots.Add($p[1]) }
        }
        foreach ($row in (Read-AidManifestShared -ManifestPath $PreviousManifest)) {
            $p=$row.Split("`t"); if ($p[0] -eq 'shared.skills.file' -and $p.Count -ge 3) {
                foreach ($mirror in $previousRoots) { $oldHashes[(Join-Path $Target (Join-Path $mirror ($p[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar)))] = $p[2] }
            }
        }
        foreach ($tool in (Read-ManifestTools -ManifestPath $PreviousManifest)) {
            foreach ($row in (Read-AidManifestToolFiles -ManifestPath $PreviousManifest -Tool $tool)) {
                $p = $row.Split("`t")
                if ($p.Count -ge 3 -and $p[0] -eq "tools.$tool.file") { $oldHashes[(Join-Path $Target ($p[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar))] = $p[2] }
            }
        }
    }
    $sharedRows = (Read-AidManifestShared -ManifestPath $manifest)
    foreach ($row in $sharedRows) { $p=$row.Split("`t"); if ($p[0] -eq 'shared.mirror' -and $p.Count -ge 2) { [void]$roots.Add($p[1]) } }
    foreach ($row in $sharedRows) {
        $p=$row.Split("`t")
        if ($p[0] -eq 'shared.skills.file' -and $p.Count -ge 2) {
            $rel=$p[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar
            [void]$wanted.Add((Join-Path $Target (Join-Path '.agents/skills' $rel)))
            foreach ($mirror in $roots) { [void]$wanted.Add((Join-Path $Target (Join-Path $mirror $rel))) }
        } elseif ($p[0] -eq 'shared.runtime.file' -and $p.Count -ge 2) {
            [void]$wanted.Add((Join-Path $Target (Join-Path '.aid/runtime' ($p[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar))))
        }
    }
    $scanRoots = @('.agents/skills', '.aid/runtime') + @($roots)
    foreach ($tool in (Read-ManifestTools -ManifestPath $manifest)) {
        $scanRoots += (script:Get-RootDir -Tool $tool) + '/agents'
        foreach ($row in (Read-AidManifestToolFiles -ManifestPath $manifest -Tool $tool)) {
            $p=$row.Split("`t"); if ($p.Count -ge 3 -and $p[0] -eq "tools.$tool.file") { [void]$wanted.Add((Join-Path $Target ($p[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar))) }
        }
    }
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    foreach ($root in $scanRoots | Select-Object -Unique) {
        $abs=Join-Path $Target ($root -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $abs -PathType Container)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $abs -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($root -eq '.aid/runtime' -and $f.FullName -match '[/\\]node_modules[/\\]') { continue }
            $rel=$f.FullName.Substring($abs.Length).TrimStart([char]'\',[char]'/')
            $first=$rel.Split([char[]]@('/', '\'))[0]
            if ($root -eq '.aid/runtime' -or $first -like 'aid-*') { $candidates.Add($f.FullName) }
        }
    }
    foreach ($path in $candidates) {
        if ($wanted.Contains($path)) { continue }
        $hash=Get-Sha256File -FilePath $path
        if ($oldHashes.ContainsKey($path) -and $oldHashes[$path] -eq $hash) { Remove-Item -LiteralPath $path -Force }
        else { Move-AidToTrash -Root $Target -File $path }
    }
    foreach ($root in $scanRoots | Select-Object -Unique) {
        $abs=Join-Path $Target ($root -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $abs -PathType Container)) { continue }
        $dirs=@(Get-ChildItem -LiteralPath $abs -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending)
        foreach ($d in $dirs) {
            $rel=$d.FullName.Substring($abs.Length).TrimStart([char]'\',[char]'/')
            if ($root -eq '.aid/runtime') { if ($d.FullName -match '[/\\]node_modules(?:[/\\]|$)') { continue } }
            else { $first=$rel.Split([char[]]@('/', '\'))[0]; if ($first -notlike 'aid-*') { continue } }
            if (-not (Get-ChildItem -LiteralPath $d.FullName -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $d.FullName -Force -ErrorAction SilentlyContinue }
        }
    }
}

# ---------------------------------------------------------------------------
# Retired-root migration sweep (FR7/FR7a)
# ---------------------------------------------------------------------------

# Invoke-MigrateRetiredLayout <target> <tool> [aidVerbose]
#
# Complete-replacement migration: removes AID-owned content from the static
# list of retired AID roots that no longer exist in the new bundle layout.
# Called from Install-AidTool as part of the retired-layout migration sweep.
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
                    # Move to <Target>/.aid/.trash/<rel> under the shared collision policy.
                    try {
                        Move-AidToTrash -Root $Target -File $f.FullName
                        $script:_MigrateRetiredCount++
                        if ($AidVerbose) { Write-Host "Trashed: $($f.FullName)" }
                    } catch {
                        [Console]::Error.WriteLine("ERROR: AidInstallCore: could not trash $($f.FullName): $_")
                    }
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
        'codex' { }
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

# Read-AidUpgradeRecovery <target> - strict reader for the v3 upgrade record.
function Read-AidUpgradeRecovery {
    param([string]$Target)
    $path = Join-Path $Target '.aid/.temp/v3-upgrade-tools.json'
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        $parent=Split-Path -Parent $path; $leaf=Split-Path -Leaf $path
        $entry=if (Test-Path -LiteralPath $parent -PathType Container) { Get-ChildItem -LiteralPath $parent -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ceq $leaf } | Select-Object -First 1 } else { $null }
        if (-not $entry) { return $null }
        throw "invalid recovery data at $path (must be a regular file)"
    }
    if (-not $item -or $item.PSIsContainer -or ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "invalid recovery data at $path (must be a regular file)"
    }
    try {
        $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        $value = $raw | ConvertFrom-Json -ErrorAction Stop
        $props = @($value.PSObject.Properties | ForEach-Object { $_.Name })
        if ($props.Count -ne 3 -or @($props | Where-Object { $_ -notin @('format_version','tools','retired') }).Count -gt 0) { throw 'schema' }
        if ([regex]::Matches($raw, '"format_version"').Count -ne 1 -or [regex]::Matches($raw, '"tools"').Count -ne 1 -or [regex]::Matches($raw, '"retired"').Count -ne 1) { throw 'duplicate fields' }
        if (($value.format_version -isnot [int] -and $value.format_version -isnot [long]) -or $value.format_version -ne 1 -or $value.retired -isnot [bool]) { throw 'types' }
        if ($value.tools -isnot [System.Array]) { throw 'tools must be an array' }
        $tools = @($value.tools)
        if ($tools.Count -eq 0 -or @($tools | Where-Object { $_ -isnot [string] -or $script:AID_TOOLS -cnotcontains $_ }).Count -gt 0) { throw 'tools' }
        if (@($tools | Select-Object -Unique).Count -ne $tools.Count) { throw 'duplicate tools' }
        $ordered = @($script:AID_TOOLS | Where-Object { $tools -ccontains $_ })
        if (($ordered -join "`t") -cne ($tools -join "`t")) { throw 'tool order' }
        return [pscustomobject]@{ tools=$tools; retired=$value.retired }
    } catch { throw "invalid recovery data at $path" }
}

function Write-AidUpgradeRecovery {
    param([string]$Target, [string[]]$Tools, [bool]$Retired)
    $path = Join-Path $Target '.aid/.temp/v3-upgrade-tools.json'
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $ordered = @($script:AID_TOOLS | Where-Object { $Tools -ccontains $_ })
    if ($ordered.Count -eq 0 -or ($ordered -join "`t") -cne ($Tools -join "`t")) { throw 'invalid recovery tools' }
    $json = '{"format_version":1,"tools":[' + (($ordered | ForEach-Object { '"' + $_ + '"' }) -join ',') + '],"retired":' + $Retired.ToString().ToLowerInvariant() + "}`n"
    $tmp = Join-Path $dir ('.v3-upgrade-tools.' + [System.IO.Path]::GetRandomFileName())
    [System.IO.File]::WriteAllBytes($tmp, [System.Text.Encoding]::ASCII.GetBytes($json))
    if (Test-Path -LiteralPath $path -PathType Leaf) { [System.IO.File]::Replace($tmp, $path, $null) }
    else { [System.IO.File]::Move($tmp, $path) }
}

function Clear-AidUpgradeRecovery {
    param([string]$Target)
    $path = Join-Path $Target '.aid/.temp/v3-upgrade-tools.json'
    if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
}

function Test-AidOwnedPath {
    param([string]$Target, [string]$Path)
    $rel = [System.IO.Path]::GetFullPath($Path).Substring(([System.IO.Path]::GetFullPath($Target).TrimEnd('\','/') + [System.IO.Path]::DirectorySeparatorChar).Length) -replace '\\','/'
    if ($rel -match '^\.agents/aid/.+' -or $rel -match '^\.(claude|codex|cursor|github|agent)/aid/.+' -or $rel -match '^\.(claude|codex|cursor|github|agent)/skills/aid-[^/]+/.+') { return $true }
    $base = $rel.Substring($rel.LastIndexOf('/') + 1)
    if ($base -like 'aid-*' -and ($rel -match '^\.(claude|codex|cursor|github|agent)/(skills|aid)/' -or $rel -match '^\.agents/aid/')) { return $true }
    # Retired v3 rules dirs (cursor, antigravity): aid-* files are AID-owned (marker 1).
    if ($base -like 'aid-*' -and $rel -match '^\.(cursor|agent)/rules/') { return $true }
    return $false
}

function Save-AidToTrash {
    param([string]$Root, [string]$File)
    $rootFull=[System.IO.Path]::GetFullPath($Root).TrimEnd('\','/'); $src=[System.IO.Path]::GetFullPath($File)
    $rel=$src.Substring($rootFull.Length).TrimStart('\','/'); $dest=Join-Path (Join-Path $rootFull '.aid/.trash') $rel
    $dir=Split-Path -Parent $dest; if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path -LiteralPath $dest -PathType Container) { throw "trash destination is a directory: $dest" }
    $tmp=Join-Path $dir ('.trash-copy.'+[System.IO.Path]::GetRandomFileName()); [System.IO.File]::Copy($src,$tmp,$false)
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        if ((Get-Sha256File -FilePath $src) -eq (Get-Sha256File -FilePath $dest)) { Remove-Item -LiteralPath $tmp -Force; return }
        $stamp=[System.DateTime]::UtcNow.ToString('yyyyMMdd\THHmmss\Z',[System.Globalization.CultureInfo]::InvariantCulture); $candidate="$dest.$stamp"; $n=0
        while (Test-Path -LiteralPath $candidate) { $n++; $candidate="$dest.$stamp.$n" }
        [System.IO.File]::Move($dest,$candidate)
    }
    [System.IO.File]::Move($tmp,$dest)
}

function Remove-AidLegacyRootRegion {
    param([string]$Target, [string]$Name)
    $path=Join-Path $Target $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $data=[System.IO.File]::ReadAllBytes($path); $begin=[System.Text.Encoding]::ASCII.GetBytes('<!-- AID:BEGIN -->'); $end=[System.Text.Encoding]::ASCII.GetBytes('<!-- AID:END -->')
    $begins=New-Object 'System.Collections.Generic.List[int]'; $ends=New-Object 'System.Collections.Generic.List[int]'
    for ($i=0; $i -lt $data.Length; $i++) {
        $matches=$i+$begin.Length -le $data.Length
        for ($j=0; $matches -and $j -lt $begin.Length; $j++) { if ($data[$i+$j] -ne $begin[$j]) { $matches=$false } }
        if ($matches -and ($i -eq 0 -or $data[$i-1] -eq 10) -and ($i+$begin.Length -eq $data.Length -or $data[$i+$begin.Length] -eq 10 -or $data[$i+$begin.Length] -eq 13)) { $begins.Add($i) }
        $matches=$i+$end.Length -le $data.Length
        for ($j=0; $matches -and $j -lt $end.Length; $j++) { if ($data[$i+$j] -ne $end[$j]) { $matches=$false } }
        if ($matches -and ($i -eq 0 -or $data[$i-1] -eq 10) -and ($i+$end.Length -eq $data.Length -or $data[$i+$end.Length] -eq 10 -or $data[$i+$end.Length] -eq 13)) { $ends.Add($i) }
    }
    if ($begins.Count -ne 1 -or $ends.Count -ne 1 -or $begins[0] -ge $ends[0]) { return $false }
    Save-AidToTrash -Root $Target -File $path
    $finish=$ends[0]+$end.Length
    if ($finish -lt $data.Length -and $data[$finish] -eq 13) { $finish++; if ($finish -lt $data.Length -and $data[$finish] -eq 10) { $finish++ } }
    elseif ($finish -lt $data.Length -and $data[$finish] -eq 10) { $finish++ }
    $rest=New-Object byte[] ($begins[0]+$data.Length-$finish)
    [Array]::Copy($data,0,$rest,0,$begins[0]); [Array]::Copy($data,$finish,$rest,$begins[0],$data.Length-$finish)
    if ([System.Text.Encoding]::UTF8.GetString($rest).Trim().Length -eq 0) { Remove-Item -LiteralPath $path -Force } else { [System.IO.File]::WriteAllBytes($path,$rest) }
    return $true
}

function Invoke-RetireV3Layout {
    param([string]$Target, [string[]]$Tools, [bool]$ListOnly = $false)
    $roots = @($Tools | ForEach-Object { switch ($_) { 'claude-code' { '.claude' } 'codex' { '.codex' } 'cursor' { '.cursor' } 'copilot-cli' { '.github' } 'antigravity' { '.agent' } } })
    $count = 0
    foreach ($root in $roots) {
        $dir = Join-Path $Target $root
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
        $files = @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction Stop | Sort-Object FullName)
        foreach ($file in $files) { if (Test-AidOwnedPath -Target $Target -Path $file.FullName) { if ($ListOnly) { Write-Output "  move to trash: $($file.FullName.Substring($Target.Length + 1) -replace '\\','/')" } else { Move-AidToTrash -Root $Target -File $file.FullName }; $count++ } }
        if (-not $ListOnly) { Get-ChildItem -LiteralPath $dir -Recurse -Directory -Force -ErrorAction Stop | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if (@(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } } }
    }
    if ($Tools -ccontains 'codex') { $dir=Join-Path $Target '.agents/aid'; if (Test-Path -LiteralPath $dir -PathType Container) { foreach ($file in @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction Stop | Sort-Object FullName)) { if ($ListOnly) { Write-Output "  move to trash: $($file.FullName.Substring($Target.Length + 1) -replace '\\','/')" } else { Move-AidToTrash -Root $Target -File $file.FullName }; $count++ }; if (-not $ListOnly) { Get-ChildItem -LiteralPath $dir -Recurse -Directory -Force -ErrorAction Stop | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object { if (@(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop } }; if (@(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $dir -Force -ErrorAction Stop } } } }
    if (-not $ListOnly) { if (Remove-AidLegacyRootRegion -Target $Target -Name 'AGENTS.md') { $count++ }; if (Remove-AidLegacyRootRegion -Target $Target -Name 'CLAUDE.md') { $count++ } }
    elseif ((Test-Path (Join-Path $Target 'AGENTS.md') -PathType Leaf) -or (Test-Path (Join-Path $Target 'CLAUDE.md') -PathType Leaf)) { Write-Output '  inspect root AID region: AGENTS.md / CLAUDE.md' }
    if (-not $ListOnly -and $count -gt 0) { Write-Host "$count old AID file(s) moved to .aid/.trash/ (safe to delete once you have checked them)" }
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
    param([string]$Target = (Get-Location).Path)
    $worktree = '.aid/.worktrees'
    $manifest = Join-Path $Target '.aid/.aid-manifest.json'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        $hostRows = (Read-AidManifestHost -ManifestPath $manifest)
        foreach ($row in $hostRows) { $p=$row.Split("`t"); if ($p.Count -ge 2 -and $p[0] -eq 'host.worktree_root') { $worktree=$p[1]; break } }
    }
    $lines = @(
        $script:_AidGiBegin,
        ".aid/.temp/",
        ".aid/.trash/",
        ".aid/.heartbeat/",
        ".aid/.control/",
        ".aid/generated/",
        ".aid/knowledge/.cache/",
        ".aid/.worktrees/"
    )
    if (-not $worktree.StartsWith('.aid/', [System.StringComparison]::Ordinal)) { $lines += ($worktree.TrimEnd('/') + '/') }
    $lines += '.aid/runtime/**/node_modules/'
    $lines += $script:_AidGiEnd
    return ($lines -join "`n")
}

function script:Write-AidHostConf {
    param([string]$Target, [string]$WorktreeRoot = '.aid/.worktrees')
    $path = Join-Path $Target '.aid/runtime/host.conf'
    $dir = [System.IO.Path]::GetDirectoryName($path)
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, "worktree_root=$WorktreeRoot`n", [System.Text.Encoding]::ASCII)
}

$script:_AidGaBegin = $script:_AidGiBegin
$script:_AidGaEnd = $script:_AidGiEnd
function script:Get-AidGitattributesBlock {
    return (@($script:_AidGaBegin, '.agents/skills/aid-*/** text eol=lf', '.claude/skills/aid-*/** text eol=lf', '.aid/runtime/** text eol=lf', $script:_AidGaEnd) -join "`n")
}

function script:Update-AidGitattributes {
    param([string]$Target)
    $path = Join-Path $Target '.gitattributes'
    $block = [System.Text.Encoding]::ASCII.GetBytes((script:Get-AidGitattributesBlock) + "`n")
    [byte[]]$old = [byte[]]@(); if (Test-Path -LiteralPath $path -PathType Leaf) { $old = [System.IO.File]::ReadAllBytes($path) }
    $begin = [System.Text.Encoding]::ASCII.GetBytes($script:_AidGaBegin)
    $end = [System.Text.Encoding]::ASCII.GetBytes($script:_AidGaEnd)
    $startAt = -1; $endAt = -1
    for ($i=0; $i -le $old.Length-$begin.Length; $i++) {
        $same=$true; for ($j=0; $j -lt $begin.Length; $j++) { if ($old[$i+$j] -ne $begin[$j]) { $same=$false; break } }
        if ($same -and ($i -eq 0 -or $old[$i-1] -eq 10 -or $old[$i-1] -eq 13)) { $startAt=$i; break }
    }
    if ($startAt -ge 0) {
        for ($i=$startAt; $i -le $old.Length-$end.Length; $i++) {
            $same=$true; for ($j=0; $j -lt $end.Length; $j++) { if ($old[$i+$j] -ne $end[$j]) { $same=$false; break } }
            if ($same) { $endAt=$i+$end.Length; break }
        }
        if ($endAt -ge 0 -and $endAt -lt $old.Length -and $old[$endAt] -eq 13) { $endAt++; if ($endAt -lt $old.Length -and $old[$endAt] -eq 10) { $endAt++ } }
        elseif ($endAt -ge 0 -and $endAt -lt $old.Length -and $old[$endAt] -eq 10) { $endAt++ }
    }
    if ($startAt -ge 0 -and $endAt -ge 0) {
        $new = New-Object byte[] ($startAt + $block.Length + $old.Length - $endAt)
        [Array]::Copy($old,0,$new,0,$startAt); [Array]::Copy($block,0,$new,$startAt,$block.Length); [Array]::Copy($old,$endAt,$new,$startAt+$block.Length,$old.Length-$endAt)
    } else {
        $sep = [System.Collections.Generic.List[byte]]::new()
        if ($old.Length -gt 0 -and $old[$old.Length-1] -ne 10 -and $old[$old.Length-1] -ne 13) { $sep.Add(10) }
        if ($old.Length -gt 0 -and ($old.Length -lt 2 -or $old[$old.Length-2] -ne 10)) { $sep.Add(10) }
        $new = New-Object byte[] ($old.Length + $sep.Count + $block.Length)
        [Array]::Copy($old,0,$new,0,$old.Length); if ($sep.Count -gt 0) { [Array]::Copy($sep.ToArray(),0,$new,$old.Length,$sep.Count) }; [Array]::Copy($block,0,$new,$old.Length+$sep.Count,$block.Length)
    }
    $sameBytes = ($old.Length -eq $new.Length)
    if ($sameBytes) { for ($i=0; $i -lt $old.Length; $i++) { if ($old[$i] -ne $new[$i]) { $sameBytes=$false; break } } }
    if (-not $sameBytes) { [System.IO.File]::WriteAllBytes($path,$new) }
}

# Initialize-AidSettingsFile <target> <tool>
# Seed <target>\.aid\settings.yml from the tool's just-installed template when it
# does not already exist. After a format-3 manifest commits, advance only an older
# format stamp while preserving every other settings byte.
# Not manifest-tracked. Sets $script:_SeededSettings.
function script:Initialize-AidSettingsFile {
    param([string]$Target, [string]$Tool)
    $script:_SeededSettings = $false
    $root = script:Get-RootDir -Tool $Tool
    if (-not $root) { return }
    $aidDir = Join-Path $Target '.aid'
    $dst  = Join-Path $aidDir 'settings.yml'
    $tmpl = Join-Path $Target '.aid/runtime/templates/settings.yml'
    if (Test-Path $dst -PathType Leaf) {
        $manifestPath = Join-Path $aidDir '.aid-manifest.json'
        if (Test-Path $manifestPath -PathType Leaf) {
            try { $manifestObject = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json } catch { $manifestObject = $null }
            if ($manifestObject -and $manifestObject.PSObject.Properties['format_version'] -and [int]$manifestObject.format_version -eq 3) {
                $bytes = [System.IO.File]::ReadAllBytes($dst)
                $start = if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { 3 } else { 0 }
                while ($start -lt $bytes.Length) {
                    $end = $start
                    while ($end -lt $bytes.Length -and $bytes[$end] -ne 10) { $end++ }
                    $contentEnd = $end
                    if ($contentEnd -gt $start -and $bytes[$contentEnd - 1] -eq 13) { $contentEnd-- }
                    $line = [System.Text.Encoding]::ASCII.GetString($bytes, $start, $contentEnd - $start)
                    $match = [System.Text.RegularExpressions.Regex]::Match($line, '^(format_version:[ \t]*["'']?)([0-9]+)')
                    if ($match.Success -and [int]$match.Groups[2].Value -lt 5) {
                        $stampOffset = $start + $match.Groups[1].Length
                        $digitsEnd = $stampOffset + $match.Groups[2].Length
                        $patched = New-Object 'System.Collections.Generic.List[byte]'
                        for ($i = 0; $i -lt $stampOffset; $i++) { $patched.Add($bytes[$i]) }
                        $patched.Add([byte]53)
                        for ($i = $digitsEnd; $i -lt $bytes.Length; $i++) { $patched.Add($bytes[$i]) }
                        [System.IO.File]::WriteAllBytes($dst, $patched.ToArray())
                        break
                    }
                    $start = $end + 1
                }
            }
        }
        return
    }
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
    $block = script:Get-AidGitignoreBlock -Target $Target

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

# Invoke-MigrateTermExclusions <target>
# One-time migration (work-014): carry user-confirmed term exclusions from the retired KB
# dotfile .aid\knowledge\.term-exclusions.md into settings.yml discovery.term_exclusions,
# then retire the file to .aid\.trash\. No-op when the file is absent.
function script:Invoke-MigrateTermExclusions {
    param([string]$Target)
    $kbFile = Join-Path $Target '.aid\knowledge\.term-exclusions.md'
    if (-not (Test-Path $kbFile -PathType Leaf)) { return }

    $settings = Join-Path $Target '.aid\settings.yml'

    $terms = [System.Collections.Generic.List[string]]::new()
    foreach ($ln in [System.IO.File]::ReadAllLines($kbFile)) {
        if ($ln -match '^\s*-\s+(.*)$') {
            $t = ($Matches[1] -replace '\s+#.*$', '').Trim()
            if ($t -ne '') { $terms.Add($t) }
        }
    }

    # Terms to preserve but no settings.yml to hold them: do NOT retire (would drop
    # the only copy). Leave the file for a later run.
    if ($terms.Count -gt 0 -and -not (Test-Path $settings -PathType Leaf)) { return }

    if ($terms.Count -gt 0) {
        $lines = ((([System.IO.File]::ReadAllText($settings)) -replace "`r`n", "`n") -replace "`r", "`n") -split "`n"

        # Does discovery.term_exclusions ALREADY exist? Scoped to the discovery section,
        # so a term_exclusions: under some OTHER section can't cause a false skip.
        # Match only the immediate child (exactly 2-space indent) -- the level
        # injection writes at -- so a deeper key (discovery.closure.term_exclusions)
        # cannot be mistaken for discovery.term_exclusions.
        $hasTe = $false; $inDisc = $false
        foreach ($ln in $lines) {
            if ($ln -match '^discovery:\s*(#.*)?$') { $inDisc = $true; continue }
            if ($inDisc -and $ln -match '^[^\s#]') { $inDisc = $false }
            if ($inDisc -and $ln -match '^  term_exclusions:') { $hasTe = $true }
        }

        if (-not $hasTe) {
            $blockLines = @('  term_exclusions:') + ($terms | ForEach-Object { "    - $_" })
            $out = [System.Collections.Generic.List[string]]::new()
            $inserted = $false
            foreach ($ln in $lines) {
                $out.Add($ln)
                # Match discovery: even with a trailing comment (discovery: # ...).
                if (-not $inserted -and $ln -match '^discovery:\s*(#.*)?$') {
                    foreach ($b in $blockLines) { $out.Add($b) }
                    $inserted = $true
                }
            }
            if (-not $inserted) {
                $out.Add('discovery:')
                foreach ($b in $blockLines) { $out.Add($b) }
            }
            [System.IO.File]::WriteAllText($settings, ($out -join "`n"), [System.Text.UTF8Encoding]::new($false))
        }
    }

    # Safe to retire now: terms (if any) are placed in discovery.term_exclusions,
    # already present there, or the file carried nothing to preserve.
    $dest = Join-Path $Target '.aid\.trash\knowledge\.term-exclusions.md'
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Move-Item -Path $kbFile -Destination $dest -Force
    Write-Host "  Migrated term exclusions to settings.yml; retired .aid/knowledge/.term-exclusions.md to .aid/.trash/"
}

# ---------------------------------------------------------------------------
# High-level Install-AidTool
# ---------------------------------------------------------------------------

# Install-AidTool <stagingDir> <tool> <target> <version> [force] [aidVerbose]
# Returns:
#   0 - success (all files installed or up-to-date)
#
# Side effects: writes <target>/.aid/.aid-manifest.json.
function Install-AidTool {
    param(
        [string]$StagingDir,
        [string]$Tool,
        [string]$Target,
        [string]$Version,
        [bool]$Force = $false,
        [bool]$AidVerbose = $false,
        [bool]$AddOnly = $false
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

    if ($AddOnly) {
        $agentRoot = Join-Path $StagingDir (Join-Path (script:Get-RootDir -Tool $Tool) 'agents')
        if (Test-Path -LiteralPath $agentRoot -PathType Container) {
            $files = @(Get-ChildItem -LiteralPath $agentRoot -Recurse -File | Sort-Object FullName)
            foreach ($f in $files) {
                $rel = ((script:Get-RootDir -Tool $Tool) + '/agents/' + $f.FullName.Substring($agentRoot.Length).TrimStart([char]'\',[char]'/')) -replace '\\','/'
                $recorded = ''
                foreach ($row in (Read-AidManifestToolFiles -ManifestPath $manifest -Tool $Tool)) {
                    $parts = $row.Split("`t")
                    if ($parts.Count -ge 3 -and $parts[0] -ceq "tools.$Tool.file" -and $parts[1] -ceq $rel) { $recorded = $parts[2]; break }
                }
                Copy-AidFileGuarded -Src $f.FullName -Dst (Join-Path $Target ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)) `
                    -RecordedSha256 $recorded -Root $Target -AidVerbose $AidVerbose
            }
        }
        if ($script:_CopyCountFailed -gt 0) { throw "AidInstallCore: $($script:_CopyCountFailed) file(s) failed to copy for '$Tool'. Install aborted (incomplete)." }
        $addTotal = $script:_CopyCountCopied + $script:_CopyCountUpToDate + $script:_CopyCountUpdated + $script:_CopyCountSkipped
        if ($addTotal -gt 0) {
            if ($script:_CopyCountUpToDate -eq $addTotal) { Write-Host "  up to date ($addTotal files)" }
            else { Write-Host "  $($script:_CopyCountCopied) installed, $($script:_CopyCountUpdated) updated, $($script:_CopyCountUpToDate) unchanged" }
        }
        return 0
    }

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

    # Write manifest (merge).
    Write-AidManifest -ManifestPath $manifest -Tool $Tool -Version $Version `
        -Paths @($installPaths) -RootEntries @($rootEntries)

    # Retired-root migration sweep (FR7/FR7a).
    # Remove AID-owned content from retired layout dirs BEFORE the normal prune,
    # so that old .agents\, .cursor\rules\, .agent\rules\ trees are cleaned up.
    # A non-zero rc from Install-AidTool is treated as a mid-commit failure (caller
    # prints the "re-run to heal" message); this function returns 0 (WARN-not-fail).
    Invoke-MigrateRetiredLayout -Target $Target -Tool $Tool -AidVerbose $AidVerbose

    # Project-level provisioning (work-007): seed required settings.yml and
    # maintain the .gitignore AID region. Both idempotent; safe per-tool.
    script:Initialize-AidSettingsFile -Target $Target -Tool $Tool
    script:Update-AidGitignore -Target $Target
    script:Update-AidGitattributes -Target $Target
    script:Invoke-MigrateTermExclusions -Target $Target

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

# Install-AidShared <shared staging> <target> <version> <tools> <stage map>
# Writes the shared placement, root context and one atomic format-3 manifest.
function Install-AidShared {
    param([string]$SharedStagingDir,[string]$Target,[string]$Version,[string[]]$NewTools,$StageMap,[bool]$Force=$false,[bool]$AidVerbose=$false,[string]$Phase='all')
    $manifest = Join-Path $Target (Join-Path '.aid' '.aid-manifest.json')
    $old = script:Read-AidManifestObject -Path $manifest
    $oldHashes = @{}
    foreach ($row in (Read-AidManifestShared -ManifestPath $manifest)) {
        $p = $row.Split("`t")
        if ($p.Count -ge 3 -and $p[0] -in @('shared.skills.file','shared.runtime.file')) { $oldHashes[$p[0] + ':' + $p[1]] = $p[2] }
    }
    $allToolsSet = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
    if (-not $script:_AidV3Upgrade) { foreach ($t in (Read-ManifestTools -ManifestPath $manifest)) { [void]$allToolsSet.Add($t) } }
    foreach ($t in $NewTools) { [void]$allToolsSet.Add($t) }
    $allTools = @($script:AID_TOOLS | Where-Object { $allToolsSet.Contains($_) })
    if ($Phase -notin @('finalize','update-finalize')) { $script:_CopyCountCopied=0; $script:_CopyCountUpToDate=0; $script:_CopyCountUpdated=0; $script:_CopyCountSkipped=0; $script:_CopyCountFailed=0 }
    $skillsRoot = Join-Path $SharedStagingDir 'skills'
    $runtimeRoot = Join-Path $SharedStagingDir 'runtime'
    $skills = @(Get-ChildItem -LiteralPath $skillsRoot -Recurse -File | Sort-Object FullName)
    if ($Phase -notin @('finalize','update-finalize')) { foreach ($f in $skills) {
        $rel = $f.FullName.Substring($skillsRoot.Length).TrimStart([char]'\',[char]'/') -replace '\\','/'
        if (-not $rel.StartsWith('aid-', [System.StringComparison]::Ordinal)) { continue }
        $dst = Join-Path $Target (Join-Path '.agents/skills' ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar))
        Copy-AidFileGuarded -Src $f.FullName -Dst $dst -RecordedSha256 $oldHashes["shared.skills.file:$rel"] -Root $Target -AidVerbose $AidVerbose
    } }
    $toolMeta=@{}; $mirrorUsers=@{}; $inline=$false; $claudeUsers=@()
    foreach ($tool in $allTools) {
        $mirrors=@(); $worktree=''; $rules=$false; $context=''
        if ($NewTools -contains $tool) {
            $conf=Join-Path $StageMap[$tool] 'aid-tool.conf'
            foreach ($line in (Read-AidKvConf -Path $conf)) {
                $k=$line.Substring(0,$line.IndexOf('=')); $v=$line.Substring($line.IndexOf('=')+1)
                switch ($k) { 'skill_mirror' { $mirrors += $v } 'worktree_root' { $worktree=$v } 'rules_inline' { if ($v -eq 'true') { $rules=$true } } 'context_import' { $context=$v } }
            }
        } else {
            $obj=script:Get-AidJsonProp (script:Get-AidJsonProp $old 'tools') $tool
            $mirrorValue=script:Get-AidJsonProp $obj 'mirrors'
            $mirrors=@(); if ($null -ne $mirrorValue) { $mirrors=@($mirrorValue) }
            $worktree=[string](script:Get-AidJsonProp $obj 'worktree_root')
            $rules=(script:Get-AidJsonProp $obj 'rules_inline') -eq $true
        }
        $toolMeta[$tool]=@{ mirrors=@($mirrors | Sort-Object -Unique); worktree=$worktree; rules=$rules; context=$context }
        if ($rules) { $inline=$true }
        if ($context -eq 'CLAUDE.md') { $claudeUsers += $tool }
        foreach ($mirror in $mirrors) {
            if (-not $mirrorUsers.ContainsKey($mirror)) { $mirrorUsers[$mirror]=@() }
            $mirrorUsers[$mirror] += $tool
            if ($Phase -notin @('finalize','update-finalize')) { foreach ($f in $skills) {
                $rel = $f.FullName.Substring($skillsRoot.Length).TrimStart([char]'\',[char]'/') -replace '\\','/'
                if (-not $rel.StartsWith('aid-', [System.StringComparison]::Ordinal)) { continue }
                $dst = Join-Path $Target (Join-Path ($mirror -replace '/', [System.IO.Path]::DirectorySeparatorChar) ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar))
                Copy-AidFileGuarded -Src $f.FullName -Dst $dst -RecordedSha256 $oldHashes["shared.skills.file:$rel"] -Root $Target -AidVerbose $AidVerbose
            } }
        }
    }
    if ($Phase -notin @('finalize','update-finalize')) { foreach ($f in @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File | Sort-Object FullName)) {
        $rel=$f.FullName.Substring($runtimeRoot.Length).TrimStart([char]'\',[char]'/') -replace '\\','/'
        $dst=Join-Path $Target (Join-Path '.aid/runtime' ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar))
        Copy-AidFileGuarded -Src $f.FullName -Dst $dst -RecordedSha256 $oldHashes["shared.runtime.file:$rel"] -Root $Target -AidVerbose $AidVerbose
    } }
    if ($script:_CopyCountFailed -gt 0) { throw "AidInstallCore: $($script:_CopyCountFailed) shared file(s) failed to copy." }
    if ($Phase -notin @('finalize','update-finalize')) {
        $copyTotal=$script:_CopyCountCopied+$script:_CopyCountUpToDate+$script:_CopyCountUpdated+$script:_CopyCountSkipped
        if ($copyTotal -gt 0 -and $script:_CopyCountUpToDate -eq $copyTotal) { Write-Host "  up to date ($copyTotal files)" } else { Write-Host "  $($script:_CopyCountCopied) copied, $($script:_CopyCountUpdated) updated, $($script:_CopyCountUpToDate) unchanged" }
        if ($Phase -eq 'payload') { return }
        if ($Phase -eq 'update-payload') {
            $worktreeTool = @($allTools | Where-Object { $toolMeta[$_].worktree } | Select-Object -First 1)
            $hostWorktree = if ($worktreeTool.Count -gt 0) { [string]$toolMeta[$worktreeTool[0]].worktree } else { '.aid/.worktrees' }
            script:Write-AidHostConf -Target $Target -WorktreeRoot $hostWorktree
            return
        }
    }
    $region=$script:_AidAgentsPointerRegion
    $worktree=(@($allTools | Where-Object { $toolMeta[$_].worktree }) | Select-Object -First 1)
    if ($worktree) { $hostWorktree=[string]$toolMeta[$worktree].worktree } else { $hostWorktree='.aid/.worktrees' }
    if ($Phase -ne 'update-finalize') { script:Write-AidHostConf -Target $Target -WorktreeRoot $hostWorktree }
    if ($inline) {
        $rulesText=[System.IO.File]::ReadAllText((Join-Path $Target '.aid/runtime/rules.md'),[System.Text.Encoding]::UTF8)
        $region="<!-- AID:BEGIN -->`n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->`n$rulesText<!-- AID:END -->`n"
    }
    $agentsPath=Join-Path $Target 'AGENTS.md'
    if ($inline) { script:Repair-AidInlineRootRegion -File $agentsPath -Region $region -Root $Target }
    else { script:Repair-AidRootRegion -File $agentsPath -Region $region -Root $Target }
    $utf8=New-Object System.Text.UTF8Encoding($false)
    $regionSha=(Get-FileHash -InputStream ([System.IO.MemoryStream]::new($utf8.GetBytes($region))) -Algorithm SHA256).Hash.ToLowerInvariant()
    $agentsSha=Get-Sha256File -FilePath $agentsPath
    $claudeSha=''
    if ($claudeUsers.Count -gt 0 -or (-not $script:_AidV3Upgrade -and (script:Get-AidJsonProp (script:Get-AidJsonProp $old 'shared') 'claude_md'))) {
        if (-not $script:_AidV3Upgrade) { $claudeUsers=@($script:AID_TOOLS | Where-Object { $claudeUsers -contains $_ -or @((script:Get-AidJsonProp (script:Get-AidJsonProp (script:Get-AidJsonProp $old 'shared') 'claude_md') 'users')) -contains $_ }) }
        $claudeSha=script:Invoke-EnsureClaudeMdRegion -File (Join-Path $Target 'CLAUDE.md') -Root $Target
    }
    $model=Join-Path $Target ('.manifest-model.'+[System.IO.Path]::GetRandomFileName())
    $records=New-Object System.Collections.Generic.List[string]
    $records.Add("aid_version`t$Version"); $records.Add("installed_at`t$(if ($old -and (script:Get-AidJsonProp $old 'installed_at')) { script:Get-AidJsonProp $old 'installed_at' } else { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') })")
    $records.Add("host.worktree_root`t$hostWorktree")
    $sharedRoots = @(
        @{ Name='skills'; Root='.agents/skills' },
        @{ Name='runtime'; Root='.aid/runtime' }
    )
    foreach ($entry in $sharedRoots) {
        $name=$entry.Name; $root=$entry.Root; $payload=Join-Path $SharedStagingDir $name
        $records.Add("shared.$name.root`t$root"); $records.Add("shared.$name.version`t$Version"); $records.Add("shared.$name.users`t$($allTools -join ',')")
        foreach ($f in @(Get-ChildItem -LiteralPath $payload -Recurse -File | Sort-Object FullName)) {
            $rel=$f.FullName.Substring($payload.Length).TrimStart([char]'\',[char]'/') -replace '\\','/'
            if ($name -eq 'skills' -and -not $rel.StartsWith('aid-',[System.StringComparison]::Ordinal)) { continue }
            $records.Add("shared.$name.file`t$rel`t$(Get-Sha256File -FilePath $f.FullName)")
        }
        if ($name -eq 'runtime') { $records.Add("shared.runtime.file`thost.conf`t$(Get-Sha256File -FilePath (Join-Path $Target '.aid/runtime/host.conf'))") }
    }
    $records.Add("shared.agents_md.path`tAGENTS.md"); $records.Add("shared.agents_md.version`t$Version"); $records.Add("shared.agents_md.users`t$($allTools -join ',')"); $records.Add("shared.agents_md.region_sha256`t$regionSha"); $records.Add("shared.agents_md.file_sha256`t$agentsSha")
    foreach ($mirror in @($mirrorUsers.Keys | Sort-Object)) { $users=@($script:AID_TOOLS | Where-Object { $mirrorUsers[$mirror] -contains $_ }); $records.Add("shared.mirror`t$mirror`t$Version`t$($users -join ',')") }
    if ($claudeSha) { $records.Add("shared.claude_md.path`tCLAUDE.md"); $records.Add("shared.claude_md.version`t$Version"); $records.Add("shared.claude_md.users`t$($claudeUsers -join ',')"); $records.Add("shared.claude_md.region_sha256`t$claudeSha") }
    $toolObjects=script:Get-AidJsonProp $old 'tools'
    foreach ($tool in $allTools) {
        $obj=script:Get-AidJsonProp $toolObjects $tool
        $entry=$toolMeta[$tool]
        $toolVersion=if ($NewTools -contains $tool) { $Version } else { [string](script:Get-AidJsonProp $obj 'version') }
        $installedAt=[string](script:Get-AidJsonProp $obj 'installed_at')
        if (-not $installedAt) { $installedAt=(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
        $records.Add("tools.$tool.version`t$toolVersion"); $records.Add("tools.$tool.installed_at`t$installedAt")
        foreach ($m in $entry.mirrors) { $records.Add("tools.$tool.mirror`t$m") }
        if ($entry.worktree) { $records.Add("tools.$tool.worktree_root`t$($entry.worktree)") }; if ($entry.rules) { $records.Add("tools.$tool.rules_inline`ttrue") }
        if ($NewTools -contains $tool) {
            $root=script:Get-RootDir -Tool $tool; $agents=Join-Path $StageMap[$tool] (Join-Path $root 'agents')
            foreach ($f in @(Get-ChildItem -LiteralPath $agents -Recurse -File | Sort-Object FullName)) {
                $rel=$root+'/agents/'+$f.FullName.Substring($agents.Length).TrimStart([char]'\',[char]'/') -replace '\\','/'
                $records.Add("tools.$tool.file`t$rel`t$(Get-Sha256File -FilePath $f.FullName)")
            }
        } else {
            foreach ($row in (Read-AidManifestToolFiles -ManifestPath $manifest -Tool $tool)) {
                $p=$row.Split("`t"); if ($p.Count -ge 3 -and $p[0] -eq "tools.$tool.file") { $records.Add("tools.$tool.file`t$($p[1])`t$($p[2])") }
            }
        }
    }
    [System.IO.File]::WriteAllLines($model,$records.ToArray(),[System.Text.Encoding]::ASCII)
    $previousManifest = Join-Path $Target ('.aid/.manifest-before-prune.' + [System.IO.Path]::GetRandomFileName())
    if ($Phase -in @('finalize', 'update-finalize') -and (Test-Path -LiteralPath $manifest -PathType Leaf)) { Copy-Item -LiteralPath $manifest -Destination $previousManifest -Force }
    try { Write-AidManifestV3 -ManifestPath $manifest -ModelPath $model } finally { Remove-Item -LiteralPath $model -Force -ErrorAction SilentlyContinue }
    if ($Phase -in @('finalize', 'update-finalize')) {
        try {
            Invoke-PruneShared -Target $Target -PreviousManifest $previousManifest
            script:Initialize-AidSettingsFile -Target $Target -Tool $NewTools[0]
            script:Update-AidGitignore -Target $Target
            script:Update-AidGitattributes -Target $Target
            script:Invoke-MigrateTermExclusions -Target $Target
        } finally { Remove-Item -LiteralPath $previousManifest -Force -ErrorAction SilentlyContinue }
    }
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

function script:Remove-AidGitattributesBlock {
    param([string]$Target)
    $path = Join-Path $Target '.gitattributes'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $begin = [System.Text.Encoding]::ASCII.GetBytes($script:_AidGaBegin)
    $end = [System.Text.Encoding]::ASCII.GetBytes($script:_AidGaEnd)
    $startAt = -1; $endAt = -1
    for ($i=0; $i -le $bytes.Length-$begin.Length; $i++) {
        $same=$true; for ($j=0; $j -lt $begin.Length; $j++) { if ($bytes[$i+$j] -ne $begin[$j]) { $same=$false; break } }
        if ($same -and ($i -eq 0 -or $bytes[$i-1] -eq 10 -or $bytes[$i-1] -eq 13)) { $startAt=$i; break }
    }
    if ($startAt -lt 0) { return }
    for ($i=$startAt; $i -le $bytes.Length-$end.Length; $i++) {
        $same=$true; for ($j=0; $j -lt $end.Length; $j++) { if ($bytes[$i+$j] -ne $end[$j]) { $same=$false; break } }
        if ($same) { $endAt=$i+$end.Length; break }
    }
    if ($endAt -lt 0) { return }
    if ($endAt -lt $bytes.Length -and $bytes[$endAt] -eq 13) { $endAt++; if ($endAt -lt $bytes.Length -and $bytes[$endAt] -eq 10) { $endAt++ } }
    elseif ($endAt -lt $bytes.Length -and $bytes[$endAt] -eq 10) { $endAt++ }
    $out = New-Object 'System.Collections.Generic.List[byte]'
    for ($i=0; $i -lt $startAt; $i++) { $out.Add($bytes[$i]) }
    for ($i=$endAt; $i -lt $bytes.Length; $i++) { $out.Add($bytes[$i]) }
    $onlyWhitespace = $true
    foreach ($b in $out) { if ($b -notin @(9,10,13,32)) { $onlyWhitespace=$false; break } }
    if ($onlyWhitespace) { Remove-Item -LiteralPath $path -Force }
    else { [System.IO.File]::WriteAllBytes($path, $out.ToArray()) }
}

function script:Remove-AidAgentsRegion {
    param([string]$Target, [string]$RecordedSha256)
    $path = Join-Path $Target 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    if ((Get-Sha256File -FilePath $path) -cne $RecordedSha256) {
        Write-Host 'Left in place (modified or not AID-owned): AGENTS.md'
        return
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $text = $encoding.GetString([System.IO.File]::ReadAllBytes($path))
    $markers = [regex]::Matches($text, '(?m)^<!-- AID:(?:BEGIN|END) -->(?=\r?$)')
    $begins = @($markers | Where-Object { $_.Value -ceq '<!-- AID:BEGIN -->' })
    $ends = @($markers | Where-Object { $_.Value -ceq '<!-- AID:END -->' })
    if ($begins.Count -ne 1 -or $ends.Count -ne 1 -or $begins[0].Index -ge $ends[0].Index) { return }
    $start=$begins[0].Index; $finish=$ends[0].Index+$ends[0].Length
    if ($finish+2 -le $text.Length -and $text.Substring($finish,2) -ceq "`r`n") { $finish+=2 }
    elseif ($finish -lt $text.Length -and $text.Substring($finish,1) -ceq "`n") { $finish++ }
    $rest=$text.Remove($start,$finish-$start)
    if ($rest.Trim().Length -eq 0) { Remove-Item -LiteralPath $path -Force }
    else { [System.IO.File]::WriteAllBytes($path,$encoding.GetBytes($rest)) }
}

function script:Update-AidRemoveManifestHashes {
    param([string]$ManifestPath,[string]$Target,[bool]$RefreshAgentsFileSha=$true)
    $data=script:Read-AidManifestObject -Path $ManifestPath
    if ($null -eq $data) { return }
    $agents=script:Get-AidJsonProp (script:Get-AidJsonProp $data 'shared') 'agents_md'
    $agentsPath=Join-Path $Target 'AGENTS.md'
    if ($agents -and (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
        $text=[System.IO.File]::ReadAllText($agentsPath,(New-Object System.Text.UTF8Encoding($false)))
        $match=[regex]::Match($text,'(?ms)^<!-- AID:BEGIN -->\r?\n.*?^<!-- AID:END -->(?:\r?\n|$)')
        if ($match.Success) {
            $canonical=$match.Value.Replace("`r`n","`n").Replace("`r","`n")
            $bytes=[System.Text.Encoding]::UTF8.GetBytes($canonical)
            $agents.region_sha256=(Get-FileHash -InputStream ([System.IO.MemoryStream]::new($bytes)) -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($RefreshAgentsFileSha) { $agents.file_sha256=Get-Sha256File -FilePath $agentsPath }
        }
    }
    $runtime=script:Get-AidJsonProp (script:Get-AidJsonProp $data 'shared') 'runtime'
    $hostPath=Join-Path $Target '.aid/runtime/host.conf'
    if ($runtime -and (Test-Path -LiteralPath $hostPath -PathType Leaf)) {
        foreach ($f in @($runtime.files)) {
            if ($f.path -ceq 'host.conf') { $f.sha256=Get-Sha256File -FilePath $hostPath; break }
        }
    }
    $json=ConvertTo-Json -InputObject $data -Depth 30
    [System.IO.File]::WriteAllText($ManifestPath,$json+"`n",(New-Object System.Text.UTF8Encoding($false)))
}

function script:Prune-AidEmptyDirs {
    param([string]$Path,[switch]$AidEntriesOnly,[switch]$RemoveRootIfEmpty)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
    $dirs=@(Get-ChildItem -LiteralPath $Path -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending)
    foreach ($dir in $dirs) {
        if ($AidEntriesOnly) {
            $rel=$dir.FullName.Substring($Path.Length).TrimStart([char]'\',[char]'/')
            $first=$rel.Split([char]'\',[char]'/')[0]
            if (-not $first.StartsWith('aid-', [System.StringComparison]::Ordinal)) { continue }
        }
        $relative=$dir.FullName.Substring($Path.Length).TrimStart([char]'\',[char]'/')
        if ($relative -match '(^|[\\/])node_modules([\\/]|$)') { continue }
        $child=Get-ChildItem -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $child) { Remove-Item -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue }
    }
    if ($RemoveRootIfEmpty) {
        $child=Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $child) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue }
    }
}

function script:Uninstall-AidToolV3 {
    param([string]$ManifestPath,[string]$Tool,[string]$Target,[bool]$AidVerbose=$false)
    $data=script:Read-AidManifestObject -Path $ManifestPath
    if ($null -eq $data) { return 6 }
    $shared=script:Get-AidJsonProp $data 'shared'
    $toolObj=script:Get-AidJsonProp (script:Get-AidJsonProp $data 'tools') $Tool
    if ($null -eq $toolObj) { return 0 }
    $toolRelPaths=@()
    foreach ($row in (Read-AidManifestToolFiles -ManifestPath $ManifestPath -Tool $Tool)) {
        $parts=$row.Split("`t"); if ($parts.Count -lt 3 -or $parts[0] -cne "tools.$Tool.file") { continue }
        $rel=$parts[1] -replace '/', [System.IO.Path]::DirectorySeparatorChar
        if ([System.IO.Path]::IsPathRooted($rel) -or $rel.Split([System.IO.Path]::DirectorySeparatorChar) -contains '..') { continue }
        $toolRelPaths+=$rel
        $full=Join-Path $Target $rel
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        if ($parts[2] -and (Get-Sha256File -FilePath $full) -ceq $parts[2]) { Remove-Item -LiteralPath $full -Force }
        else { Move-AidToTrash -Root $Target -File $full }
    }
    $toolRoot=script:Get-RootDir -Tool $Tool
    script:Prune-AidEmptyDirs -Path (Join-Path $Target (Join-Path $toolRoot 'agents')) -AidEntriesOnly
    # Like bash: walk each removed file's directory chain up to and including the tool root,
    # removing every directory that is now empty (rmdir semantics: a non-empty one stays).
    $rootFull=Join-Path $Target $toolRoot
    foreach ($rel in $toolRelPaths) {
        $pdir=Split-Path -Parent (Join-Path $Target $rel)
        while ($pdir -and $pdir -ne $Target -and ($pdir -eq $rootFull -or $pdir.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar))) {
            if ((Test-Path -LiteralPath $pdir -PathType Container) -and -not (Get-ChildItem -LiteralPath $pdir -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
                Remove-Item -LiteralPath $pdir -Force -ErrorAction SilentlyContinue
            }
            $pdir=Split-Path -Parent $pdir
        }
    }
    $agents=script:Get-AidJsonProp $shared 'agents_md'
    $agentsUsers=@(); if ($agents) { $agentsUsers=@($agents.users) }
    $agentsLeft=@($agentsUsers | Where-Object { $_ -ne $Tool })
    $agentsFileRefresh=$false
    $agentsPath=Join-Path $Target 'AGENTS.md'
    if ($agentsLeft.Count -gt 0 -and $agents -and (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
        $agentsFileRefresh=([string]$agents.file_sha256 -and (Get-Sha256File -FilePath $agentsPath) -ceq [string]$agents.file_sha256)
    }
    if ($agentsUsers.Count -gt 0 -and $agentsLeft.Count -eq 0) { script:Remove-AidAgentsRegion -Target $Target -RecordedSha256 ([string]$agents.file_sha256) }
    $claude=script:Get-AidJsonProp $shared 'claude_md'
    $claudeUsers=@(); if ($claude) { $claudeUsers=@($claude.users) }
    $claudeLeft=@($claudeUsers | Where-Object { $_ -ne $Tool })
    if ($claudeUsers.Count -gt 0 -and $claudeLeft.Count -eq 0) { script:Invoke-RemoveClaudeMdRegion -File (Join-Path $Target 'CLAUDE.md') -RecordedSha256 ([string]$claude.region_sha256) -Root $Target }

    foreach ($name in @('skills','runtime')) {
        $entry=script:Get-AidJsonProp $shared $name
        if ($null -eq $entry -or @($entry.users | Where-Object { $_ -ne $Tool }).Count -gt 0) { continue }
        $root=if ($name -eq 'skills') { '.agents/skills' } else { '.aid/runtime' }
        foreach ($f in @($entry.files)) {
            $rel=([string]$f.path) -replace '/', [System.IO.Path]::DirectorySeparatorChar
            if ([System.IO.Path]::IsPathRooted($rel) -or $rel.Split([System.IO.Path]::DirectorySeparatorChar) -contains '..') { continue }
            $full=Join-Path (Join-Path $Target $root) $rel
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            if ($f.sha256 -and (Get-Sha256File -FilePath $full) -ceq [string]$f.sha256) { Remove-Item -LiteralPath $full -Force }
            else { Move-AidToTrash -Root $Target -File $full }
        }
        script:Prune-AidEmptyDirs -Path (Join-Path $Target $root) -AidEntriesOnly:($name -eq 'skills')
    }
    $mirrors=script:Get-AidJsonProp $shared 'mirrors'
    if ($null -ne $mirrors) {
        foreach ($mp in @($mirrors.PSObject.Properties)) {
            if (@($mp.Value.users | Where-Object { $_ -ne $Tool }).Count -gt 0) { continue }
            $mirror=$mp.Name -replace '/', [System.IO.Path]::DirectorySeparatorChar
            foreach ($f in @((script:Get-AidJsonProp $shared 'skills').files)) {
                $rel=([string]$f.path) -replace '/', [System.IO.Path]::DirectorySeparatorChar
                $full=Join-Path (Join-Path $Target $mirror) $rel
                if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
                if ($f.sha256 -and (Get-Sha256File -FilePath $full) -ceq [string]$f.sha256) { Remove-Item -LiteralPath $full -Force }
                else { Move-AidToTrash -Root $Target -File $full }
            }
            script:Prune-AidEmptyDirs -Path (Join-Path $Target $mirror) -AidEntriesOnly
        }
    }
    Remove-ManifestTool -ManifestPath $ManifestPath -Tool $Tool
    if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
        $left=script:Read-AidManifestObject -Path $ManifestPath
        $wr=[string](script:Get-AidJsonProp (script:Get-AidJsonProp $left 'host') 'worktree_root')
        if (-not $wr) { $wr='.aid/.worktrees' }
        script:Write-AidHostConf -Target $Target -WorktreeRoot $wr
        $inline=$false
        foreach ($p in $left.tools.PSObject.Properties) { if ((script:Get-AidJsonProp $p.Value 'rules_inline') -eq $true) { $inline=$true; break } }
        if ($inline) {
            $rules=[System.IO.File]::ReadAllText((Join-Path $Target '.aid/runtime/rules.md'),[System.Text.Encoding]::UTF8)
            $region="<!-- AID:BEGIN -->`n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->`n$rules<!-- AID:END -->`n"
            script:Repair-AidInlineRootRegion -File (Join-Path $Target 'AGENTS.md') -Region $region -Root $Target
        } else { script:Repair-AidInlineRootRegion -File (Join-Path $Target 'AGENTS.md') -Region $script:_AidAgentsPointerRegion -Root $Target }
        script:Update-AidRemoveManifestHashes -ManifestPath $ManifestPath -Target $Target -RefreshAgentsFileSha $agentsFileRefresh
    } else {
        $settings=Join-Path (Split-Path -Parent $ManifestPath) 'settings.yml'
        if (Test-Path -LiteralPath $settings -PathType Leaf) { Remove-Item -LiteralPath $settings -Force }
        script:Remove-AidGitattributesBlock -Target $Target
        script:Prune-AidEmptyDirs -Path (Join-Path $Target '.aid/runtime') -RemoveRootIfEmpty
    }
    $toolDir = switch ($Tool) {
        'claude-code' { '.claude' }
        'codex' { '.codex' }
        'cursor' { '.cursor' }
        'copilot-cli' { '.github' }
        'antigravity' { '.agent' }
        default { '' }
    }
    if ($toolDir) {
        $fullToolDir=Join-Path $Target $toolDir
        if (Test-Path -LiteralPath $fullToolDir -PathType Container) {
            $remaining=Get-ChildItem -LiteralPath $fullToolDir -Force -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $remaining) { Remove-Item -LiteralPath $fullToolDir -Recurse -Force }
        }
    }
    return 0
}

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

    $manifestObject = script:Read-AidManifestObject -Path $ManifestPath
    if ((script:Get-AidJsonProp $manifestObject 'format_version') -eq 3) {
        return (script:Uninstall-AidToolV3 -ManifestPath $ManifestPath -Tool $Tool -Target $Target -AidVerbose $AidVerbose)
    }

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

    # If no manifest remains (last tool removed), remove the AID-provisioned
    # project files so a full uninstall leaves .aid/ clean (work-007).
    if (-not (Test-Path $ManifestPath -PathType Leaf)) {
        $aidMetaDir = [System.IO.Path]::GetDirectoryName($ManifestPath)
        # Remove the install-time-seeded settings.yml (symmetric with the seed).
        # Only fires when NO tools remain; a partial uninstall keeps it.
        $seededSettings = Join-Path $aidMetaDir 'settings.yml'
        if (Test-Path $seededSettings -PathType Leaf) {
            Remove-Item -LiteralPath $seededSettings -Force
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
            if ($raw -match '"(manifest_version|format_version)"') {
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

    # Check if manifest exists and has a manifest_version or format_version key.
    $manifestOk = $false
    if (Test-Path $manifest -PathType Leaf) {
        try {
            $raw = Get-Content -LiteralPath $manifest -Raw
            if ($raw -match '"(manifest_version|format_version)"') {
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

    if ((script:Get-AidJsonProp $data 'format_version') -eq 2) {
        Write-Host 'Layout: format 4 (pre-shared). Run: aid update'
        return 0
    }
    Get-AidDriftReport -Target $targetPath -ManifestPath $manifest

    return 0
}

# Get-AidDriftReport <target> <manifest> - report shared and tool-file drift without writes.
function Get-AidDriftReport {
    param([string]$Target, [string]$ManifestPath)
    $data = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $dShared = script:Get-AidJsonProp $data 'shared'
    $expected = @{}
    $skills = @(script:Get-AidJsonProp (script:Get-AidJsonProp $dShared 'skills') 'files')
    foreach ($item in $skills) { if ($item.path) { $expected[('.agents/skills/' + $item.path)] = [string]$item.sha256 } }
    foreach ($item in @(script:Get-AidJsonProp (script:Get-AidJsonProp $dShared 'runtime') 'files')) { if ($item.path) { $expected[('.aid/runtime/' + $item.path)] = [string]$item.sha256 } }
    $mirrors = @{}
    $dMirrors = script:Get-AidJsonProp $dShared 'mirrors'
    if ($dMirrors) { foreach ($name in @($dMirrors.PSObject.Properties.Name)) { $mirrors[$name] = $true } }
    $dTools = script:Get-AidJsonProp $data 'tools'
    if ($dTools) {
        foreach ($tool in $dTools.PSObject.Properties) {
            foreach ($name in @(script:Get-AidJsonProp $tool.Value 'mirrors')) { if ($name) { $mirrors[$name] = $true } }
            foreach ($item in @(script:Get-AidJsonProp $tool.Value 'files')) { if ($item.path) { $expected[[string]$item.path] = [string]$item.sha256 } }
        }
    }
    foreach ($mirror in $mirrors.Keys) { foreach ($item in $skills) { if ($item.path) { $expected[($mirror + '/' + $item.path)] = [string]$item.sha256 } } }
    $issues = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in $expected.Keys) {
        if ($path -match '^\.aid/runtime/(?:.*/)?node_modules(?:/|$)') { continue }
        $full = Join-Path $Target ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { $issues.Add(('missing:' + $path)); continue }
        if ($expected[$path]) {
            $actual = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actual -ne $expected[$path].ToLowerInvariant()) { $issues.Add(('modified:' + $path)) }
        }
    }
    foreach ($pair in @(@('agents_md', 'AGENTS.md'), @('claude_md', 'CLAUDE.md'))) {
        $entry = script:Get-AidJsonProp $dShared $pair[0]
        if (-not $entry) { continue }
        $full = Join-Path $Target $pair[1]
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { $issues.Add(('missing:' + $pair[1])); continue }
        $text = [IO.File]::ReadAllText($full)
        $match = [regex]::Match($text, '(?ms)^<!-- AID:BEGIN -->\r?\n.*?^<!-- AID:END -->(?:\r?\n|$)')
        if (-not $match.Success) { $issues.Add(('missing:' + $pair[1])); continue }
        $region = $match.Value -replace "`r`n", "`n" -replace "`r", "`n"
        $bytes = [Text.Encoding]::UTF8.GetBytes($region)
        $sha = [BitConverter]::ToString(([Security.Cryptography.SHA256]::Create()).ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
        if ($sha -ne [string]$entry.region_sha256) { $issues.Add(('modified:' + $pair[1])) }
    }
    foreach ($base in @('.agents/skills') + @($mirrors.Keys | Sort-Object)) {
        $folder = Join-Path $Target $base
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($entry in Get-ChildItem -LiteralPath $folder -Force | Where-Object { $_.Name -like 'aid-*' }) {
            $entryRel = $entry.Name
            if ($entry.PSIsContainer) {
                $prefix = $base + '/' + $entryRel + '/'
                $recorded = @($expected.Keys | Where-Object { $_.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) })
                if ($recorded.Count -eq 0) { $issues.Add(('extra:' + $base + '/' + $entryRel)) }
                foreach ($file in Get-ChildItem -LiteralPath $entry.FullName -File -Recurse -Force) {
                    $rel = $base + '/' + $file.FullName.Substring($folder.Length + 1).Replace('\', '/')
                    if (-not $expected.ContainsKey($rel)) { $issues.Add(('extra:' + $rel)) }
                }
            } else {
                $rel = $base + '/' + $entryRel
                if (-not $expected.ContainsKey($rel)) { $issues.Add(('extra:' + $rel)) }
            }
        }
    }
    $runtime = Join-Path $Target '.aid/runtime'
    if (Test-Path -LiteralPath $runtime -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $runtime -File -Recurse) {
            $relLocal = $file.FullName.Substring($runtime.Length + 1).Replace('\', '/')
            if ($relLocal -match '(^|/)node_modules(/|$)') { continue }
            $rel = '.aid/runtime/' + $relLocal
            if (-not $expected.ContainsKey($rel)) { $issues.Add(('extra:' + $rel)) }
        }
    }
    if ($issues.Count -eq 0) { Write-Host 'Shared files: clean'; return }
    $sorted = @($issues | Sort-Object { if ($_ -like 'modified:*') { '0' + $_.Substring(9) } elseif ($_ -like 'missing:*') { '1' + $_.Substring(8) } else { '2' + $_.Substring(6) } } -Unique)
    Write-Host 'Shared files'
    foreach ($line in $sorted) { $separator = $line.IndexOf(':'); Write-Host ($line.Substring(0, $separator) + ': ' + $line.Substring($separator + 1)) }
    Write-Host 'Run: aid update (drifted files are moved to .aid/.trash/ first)'
}

# Export only public functions (not script-scoped helpers).
Export-ModuleMember -Function @(
    'Get-Sha256File',
    'Normalize-Tool',
    'Detect-Tool',
    'Resolve-AidVersion',
    'Test-AidPrerelease',
    'Fetch-Tarball',
    'Fetch-AidArtifact',
    'Extract-Tarball',
    'Expand-AidPayload',
    'Verify-BundleChecksum',
    'Copy-AidFile',
    'Copy-AidDir',
    'Install-AidTool',
    'Install-AidShared',
    'Read-ManifestToolPaths',
    'Read-ManifestToolVersion',
    'Read-ManifestRootAgent',
    'Read-ManifestRootAgentStatus',
    'Read-ManifestTools',
    'Read-AidKvConf',
    'Move-AidToTrash',
    'Copy-AidFileGuarded',
    'Write-AidManifestV3',
    'Read-AidManifestShared',
    'Read-AidManifestToolFiles',
    'Read-AidManifestHost',
    'Read-AidUpgradeRecovery',
    'Write-AidUpgradeRecovery',
    'Clear-AidUpgradeRecovery',
    'Test-AidOwnedPath',
    'Invoke-RetireV3Layout',
    'Write-AidManifest',
    'Remove-ManifestTool',
    'Test-ManifestExists',
    'Uninstall-AidTool',
    'Get-ManifestToolList',
    'Get-AidStatusBody',
    'Get-AidStatus',
    'Get-AidDriftReport',
    'Invoke-AidProvisionSharedStateHome',
    'Invoke-PruneShared'
)
