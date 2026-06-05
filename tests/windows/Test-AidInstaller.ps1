#Requires -Version 5.1
# Test-AidInstaller.ps1 — Native PowerShell integration test for the AID installer.
#
# Runs entirely via pwsh or Windows PowerShell 5.1.  No Pester dependency.
# Self-contained: defines its own Assert / Assert-Match / Assert-FileLF helpers.
# Exit codes: 0 = all pass, 1 = any fail.
#
# Coverage:
#   T01  Per-project install via install.ps1 -Tool -FromBundle -TargetDirectory
#   T02  Install tree exists, manifest + version files present
#   T03  Manifest is LF-only, no UTF-8 BOM (byte-level assertion)
#   T04  .aid-version is LF-only, no UTF-8 BOM
#   T05  Manifest JSON parses; contains tool + "status":"owned"
#   T06  Idempotent re-install (exit 0; "up to date" in output)
#   T07  aid status (via installed bin/aid.ps1) shows the tool
#   T08  CLI bootstrap: install.ps1 with no args + AID_HOME copies bin/lib/VERSION
#   T09  aid add codex (from bootstrap) installs codex into project
#   T10  aid status after add shows codex
#   T11  aid remove codex removes it
#   T12  aid uninstall removes the project AID install
#   T13  Manifest stays LF/no-BOM after all CLI operations
#   T14  protect-on-diff: user-owned root-agent → .aid-new + exit 5
#   T15  -Force overrides protect-on-diff
#   T16  Uninstall removes install roots (dirs actually GONE)
#   T17  Uninstall with no manifest → exit 6
#
# Windows-only guards:
#   Assertions involving $env:LOCALAPPDATA (AID_HOME default) are skipped when
#   that variable is absent (i.e. on pwsh-on-Linux smoke runs) but are active
#   on real Windows runners in CI.
#
# Usage:
#   pwsh -NoProfile -File tests/windows/Test-AidInstaller.ps1
#
# REPO_ROOT is inferred from this file's location: tests/windows/ -> two levels up.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# Locate repo root.
# ---------------------------------------------------------------------------
$_ScriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { (Get-Location).Path }
$RepoRoot   = (Resolve-Path (Join-Path $_ScriptDir '../..')).Path

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------
$script:_Pass   = 0
$script:_Fail   = 0
$script:_Errors = [System.Collections.Generic.List[string]]::new()

function script:RecordPass { param([string]$Label); $script:_Pass++ }

function script:RecordFail {
    param([string]$Label, [string]$Why)
    $script:_Fail++
    $msg = "  FAIL: $Label -- $Why"
    $script:_Errors.Add($msg)
    Write-Host $msg
}

function Assert {
    param([bool]$Condition, [string]$Label, [string]$Why = 'condition was false')
    if ($Condition) { script:RecordPass $Label } else { script:RecordFail $Label $Why }
}

function Assert-Eq {
    param([string]$Actual, [string]$Expected, [string]$Label)
    if ($Actual -eq $Expected) { script:RecordPass $Label }
    else { script:RecordFail $Label "expected '$Expected' got '$Actual'" }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Label)
    if ($Haystack.IndexOf($Needle, [System.StringComparison]::Ordinal) -ge 0) { script:RecordPass $Label }
    else { script:RecordFail $Label "pattern not found: '$Needle'" }
}

function Assert-NotContains {
    param([string]$Haystack, [string]$Needle, [string]$Label)
    if ($Haystack.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) { script:RecordPass $Label }
    else { script:RecordFail $Label "unexpected pattern found: '$Needle'" }
}

function Assert-Match {
    param([string]$Value, [string]$Pattern, [string]$Label)
    if ($Value -match $Pattern) { script:RecordPass $Label }
    else { script:RecordFail $Label "value did not match pattern '$Pattern'" }
}

# Assert-FileLF: reads raw bytes; fails if any 0x0D (CR) or UTF-8 BOM (EF BB BF).
function Assert-FileLF {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path -PathType Leaf)) {
        script:RecordFail "$Label" "file does not exist: $Path"
        return
    }
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)

    # BOM check.
    $hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    if ($hasBom) { script:RecordFail "$Label (no-BOM)" "file has UTF-8 BOM (EF BB BF): $Path" }
    else         { script:RecordPass "$Label (no-BOM)" }

    # CR check — count manually to avoid Where-Object scalar/array ambiguity.
    $crCount = 0
    foreach ($b in $bytes) { if ($b -eq 0x0D) { $crCount++ } }
    if ($crCount -gt 0) { script:RecordFail "$Label (LF-only)" "file contains $crCount CR byte(s) (CRLF): $Path" }
    else                { script:RecordPass "$Label (LF-only)" }
}

function Assert-FileExists { param([string]$Path, [string]$Label); Assert (Test-Path $Path -PathType Leaf) $Label "file does not exist: $Path" }
function Assert-DirExists  { param([string]$Path, [string]$Label); Assert (Test-Path $Path -PathType Container) $Label "directory does not exist: $Path" }
function Assert-DirGone    { param([string]$Path, [string]$Label); Assert (-not (Test-Path $Path)) $Label "path still exists: $Path" }

# ---------------------------------------------------------------------------
# Resolve pwsh executable for sub-invocations.
# On Windows: prefer pwsh.exe (PS 7+), fall back to powershell.exe (PS 5.1).
# On Linux/macOS (smoke run): use the running executable.
# ---------------------------------------------------------------------------
function script:Find-PwshExe {
    # Prefer pwsh from the same home as the running instance.
    $pwshCand = Join-Path $PSHOME 'pwsh.exe'
    if (Test-Path $pwshCand -PathType Leaf) { return $pwshCand }
    # Check PATH.
    $cmd = Get-Command 'pwsh' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # Fallback: powershell.exe (Windows PowerShell 5.1).
    $ps5Cand = Join-Path $PSHOME 'powershell.exe'
    if (Test-Path $ps5Cand -PathType Leaf) { return $ps5Cand }
    # Last resort: use the running ps executable.
    return $PSVersionTable.PSVersion.ToString() -replace '.*', ''   # not useful; handled below
}

# Resolve now, before any tests run.
$PwshExe = $null
$pwshCandH = Join-Path $PSHOME 'pwsh.exe'
if (Test-Path $pwshCandH -PathType Leaf) { $PwshExe = $pwshCandH }
if (-not $PwshExe) {
    $cmd = Get-Command 'pwsh' -ErrorAction SilentlyContinue
    if ($cmd) { $PwshExe = $cmd.Source }
}
if (-not $PwshExe) {
    $ps5Cand = Join-Path $PSHOME 'powershell.exe'
    if (Test-Path $ps5Cand -PathType Leaf) { $PwshExe = $ps5Cand }
}
if (-not $PwshExe) {
    # pwsh-on-Linux: $PSHOME/pwsh is the binary (no .exe).
    $pwshLinux = Join-Path $PSHOME 'pwsh'
    if (Test-Path $pwshLinux -PathType Leaf) { $PwshExe = $pwshLinux }
}
if (-not $PwshExe) {
    Write-Host "ERROR: cannot locate pwsh or powershell executable for sub-invocations"
    exit 1
}

# ---------------------------------------------------------------------------
# Temp directory + cleanup
# ---------------------------------------------------------------------------
$TmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aid-win-test-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TmpRoot -Force | Out-Null

try {

# ---------------------------------------------------------------------------
# Read VERSION from repo root (do NOT hardcode).
# ---------------------------------------------------------------------------
$VersionFile = Join-Path $RepoRoot 'VERSION'
if (-not (Test-Path $VersionFile -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: VERSION file not found at $VersionFile")
    exit 1
}
$Ver = (Get-Content -LiteralPath $VersionFile -Raw).Trim()
Write-Host "Test suite : AID native PowerShell installer tests"
Write-Host "Repo root  : $RepoRoot"
Write-Host "Version    : $Ver"
Write-Host "pwsh exe   : $PwshExe"
Write-Host "Temp dir   : $TmpRoot"
Write-Host ""

# ---------------------------------------------------------------------------
# Paths to scripts under test.
# ---------------------------------------------------------------------------
$InstallPs1   = Join-Path $RepoRoot 'install.ps1'
$LocalLibPath = Join-Path $RepoRoot 'lib' 'AidInstallCore.psm1'

if (-not (Test-Path $InstallPs1 -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: install.ps1 not found at $InstallPs1")
    exit 1
}

# ---------------------------------------------------------------------------
# Helper: build a flat-root fixture tarball for one tool from profiles/<tool>/.
# Excludes README.md + emission-manifest.jsonl.
# Output: $DestDir/aid-<tool>-v<ver>.tar.gz
# ---------------------------------------------------------------------------
function Build-FixtureTarball {
    param([string]$Tool, [string]$DestDir)
    $profileDir = Join-Path $RepoRoot 'profiles' $Tool
    if (-not (Test-Path $profileDir -PathType Container)) {
        [Console]::Error.WriteLine("ERROR: profile dir not found: $profileDir")
        exit 1
    }
    $tarball = Join-Path $DestDir "aid-$Tool-v$Ver.tar.gz"

    # Collect files, excluding README.md and emission-manifest.jsonl.
    $filePaths = [System.Collections.Generic.List[string]]::new()
    $items = @(Get-ChildItem -LiteralPath $profileDir -Recurse -File -Force -ErrorAction SilentlyContinue)
    foreach ($item in $items) {
        if ($item.Name -eq 'README.md' -or $item.Name -eq 'emission-manifest.jsonl') { continue }
        $rel = $item.FullName.Substring($profileDir.Length).TrimStart([char]'\', [char]'/')
        $filePaths.Add("./$($rel -replace '\\', '/')")
    }

    # Write file list (LF-separated, UTF-8 no-BOM).
    $filelistPath = Join-Path $DestDir "filelist-$Tool.txt"
    $listBytes    = [System.Text.Encoding]::UTF8.GetBytes(($filePaths -join "`n"))
    [System.IO.File]::WriteAllBytes($filelistPath, $listBytes)

    $tarArgs = @('-czf', $tarball, '--no-recursion', '-C', $profileDir, '-T', $filelistPath)
    & tar @tarArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("ERROR: failed to build fixture tarball for $Tool (tar exit $LASTEXITCODE)")
        exit 1
    }
    Remove-Item -LiteralPath $filelistPath -Force -ErrorAction SilentlyContinue
    return $tarball
}

# ---------------------------------------------------------------------------
# Helpers: invoke install.ps1 or aid.ps1 as a sub-process.
# Output (stdout+stderr merged) → $script:_LastOut (ANSI stripped).
# Exit code                     → $script:_LastRC.
# AID_LIB_PATH is set to the local lib so no remote fetch is needed.
# ---------------------------------------------------------------------------
$script:_LastOut = ''
$script:_LastRC  = 0

$_AnsiPattern = '\x1b\[[0-9;]*[mK]'

function Run-Install {
    param([string[]]$InstArgs)
    $savedLib = $env:AID_LIB_PATH
    $env:AID_LIB_PATH = $LocalLibPath
    $outLines = & $PwshExe -NoProfile -File $InstallPs1 @InstArgs 2>&1
    $script:_LastRC  = $LASTEXITCODE
    $script:_LastOut = ($outLines | ForEach-Object { [string]$_ }) -join "`n"
    $script:_LastOut = [System.Text.RegularExpressions.Regex]::Replace($script:_LastOut, $_AnsiPattern, '')
    $env:AID_LIB_PATH = $savedLib
}

function Run-AidPs1 {
    param([string]$AidHome, [string[]]$AidArgs)
    $aidPs1Path = Join-Path $AidHome 'bin' 'aid.ps1'
    # Fallback to repo bin/aid.ps1 if not yet installed in AidHome.
    if (-not (Test-Path $aidPs1Path -PathType Leaf)) {
        $aidPs1Path = Join-Path $RepoRoot 'bin' 'aid.ps1'
    }
    $savedHome = $env:AID_HOME
    $savedLib  = $env:AID_LIB_PATH
    $env:AID_HOME     = $AidHome
    $env:AID_LIB_PATH = $LocalLibPath
    $outLines = & $PwshExe -NoProfile -File $aidPs1Path @AidArgs 2>&1
    $script:_LastRC  = $LASTEXITCODE
    $script:_LastOut = ($outLines | ForEach-Object { [string]$_ }) -join "`n"
    $script:_LastOut = [System.Text.RegularExpressions.Regex]::Replace($script:_LastOut, $_AnsiPattern, '')
    $env:AID_HOME     = $savedHome
    $env:AID_LIB_PATH = $savedLib
}

# ---------------------------------------------------------------------------
# Build fixture tarballs for the tools used in tests.
# ---------------------------------------------------------------------------
$FixtureDir = Join-Path $TmpRoot 'fixtures'
New-Item -ItemType Directory -Path $FixtureDir -Force | Out-Null

Write-Host "Building fixture tarballs..."
$FixClaudeCode = Build-FixtureTarball 'claude-code' $FixtureDir
$FixCodex      = Build-FixtureTarball 'codex'       $FixtureDir
Write-Host "  claude-code: $FixClaudeCode"
Write-Host "  codex      : $FixCodex"
Write-Host ""

# ===========================================================================
# T01-T07: Per-project install via install.ps1 -Tool -FromBundle -TargetDirectory
# ===========================================================================
Write-Host "=== T01-T07: Per-project install ==="

$ProjT01 = Join-Path $TmpRoot 'project-t01'
New-Item -ItemType Directory -Path $ProjT01 -Force | Out-Null

Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT01)
Assert-Eq "$($script:_LastRC)" '0' 'T01 install claude-code → exit 0'

# T02: Install tree exists.
Assert-DirExists  (Join-Path $ProjT01 '.claude')                     'T02a .claude/ created'
Assert-FileExists (Join-Path $ProjT01 'CLAUDE.md')                   'T02b CLAUDE.md created'
Assert-FileExists (Join-Path $ProjT01 '.aid' '.aid-manifest.json')   'T02c manifest exists'
Assert-FileExists (Join-Path $ProjT01 '.aid' '.aid-version')         'T02d .aid-version exists'

# T03: Manifest bytes are LF-only, no BOM.
Assert-FileLF (Join-Path $ProjT01 '.aid' '.aid-manifest.json') 'T03 manifest'

# T04: .aid-version bytes are LF-only, no BOM.
Assert-FileLF (Join-Path $ProjT01 '.aid' '.aid-version') 'T04 .aid-version'

# T05: Manifest JSON parses; contains claude-code tool + "status":"owned".
$mPathT05 = Join-Path $ProjT01 '.aid' '.aid-manifest.json'
if (Test-Path $mPathT05 -PathType Leaf) {
    $mRaw = Get-Content -LiteralPath $mPathT05 -Raw
    try {
        $mObj = $mRaw | ConvertFrom-Json
        Assert ($mObj.tools.PSObject.Properties.Name -contains 'claude-code') `
            'T05a manifest contains claude-code' 'claude-code not in manifest.tools'
        Assert-Contains $mRaw '"status": "owned"' 'T05b manifest status:owned'
        Assert-Contains $mRaw '"manifest_version"' 'T05c manifest has manifest_version'
    } catch {
        script:RecordFail 'T05 manifest JSON parse' "exception: $_"
    }
} else {
    script:RecordFail 'T05 manifest parse' 'manifest file missing, cannot parse'
}

# T06: Idempotent re-install → exit 0 + "up to date".
Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT01)
Assert-Eq    "$($script:_LastRC)" '0' 'T06a idempotent re-install → exit 0'
Assert-Contains $script:_LastOut 'up to date' 'T06b idempotent shows "up to date"'

# T07: aid status shows the tool.
# Provision a minimal AID_HOME from the repo's own bin/ so no bootstrap network call.
$AidHomeT07 = Join-Path $TmpRoot 'aid-home-t07'
$AidBinT07  = Join-Path $AidHomeT07 'bin'
$AidLibT07  = Join-Path $AidHomeT07 'lib'
New-Item -ItemType Directory -Path $AidBinT07 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT07 -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') -Destination (Join-Path $AidBinT07 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath -Destination (Join-Path $AidLibT07 'AidInstallCore.psm1') -Force

Run-AidPs1 -AidHome $AidHomeT07 -AidArgs @('status', '-Target', $ProjT01)
Assert-Eq "$($script:_LastRC)" '0' 'T07a aid status → exit 0'
Assert-Contains $script:_LastOut 'claude-code' 'T07b aid status lists claude-code'
Write-Host ""

# ===========================================================================
# T08-T13: CLI bootstrap (disk path) + aid add/status/remove/uninstall lifecycle
# ===========================================================================
Write-Host "=== T08-T13: CLI bootstrap + full lifecycle ==="

# T08: install.ps1 with no args + AID_HOME set → bootstrap from repo disk.
# AID_NO_PATH=1 to skip PATH wiring (avoids registry writes in test).
$AidHomeT08  = Join-Path $TmpRoot 'aid-home-t08'
$savedHome   = $env:AID_HOME
$savedNoPath = $env:AID_NO_PATH
$savedLib    = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT08
$env:AID_NO_PATH  = '1'
$env:AID_LIB_PATH = $LocalLibPath

$outLines08 = & $PwshExe -NoProfile -File $InstallPs1 2>&1
$rc08 = $LASTEXITCODE
$out08 = ($outLines08 | ForEach-Object { [string]$_ }) -join "`n"
$out08 = [System.Text.RegularExpressions.Regex]::Replace($out08, $_AnsiPattern, '')

$env:AID_HOME     = $savedHome
$env:AID_NO_PATH  = $savedNoPath
$env:AID_LIB_PATH = $savedLib

Assert-Eq "$rc08" '0' 'T08a CLI bootstrap → exit 0'
Assert-FileExists (Join-Path $AidHomeT08 'bin' 'aid.ps1')                    'T08b aid.ps1 in AID_HOME/bin'
Assert-FileExists (Join-Path $AidHomeT08 'lib' 'AidInstallCore.psm1')        'T08c AidInstallCore.psm1 in AID_HOME/lib'
Assert-FileExists (Join-Path $AidHomeT08 'VERSION')                           'T08d VERSION in AID_HOME'

# aid.cmd is present on Windows only (repo ships bin/aid.cmd).
if (Test-Path (Join-Path $RepoRoot 'bin' 'aid.cmd') -PathType Leaf) {
    Assert-FileExists (Join-Path $AidHomeT08 'bin' 'aid.cmd') 'T08e aid.cmd in AID_HOME/bin (Windows)'
}

# T09: aid add codex.
$ProjT09 = Join-Path $TmpRoot 'project-t09'
New-Item -ItemType Directory -Path $ProjT09 -Force | Out-Null

Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT09)
Assert-Eq "$($script:_LastRC)" '0' 'T09a aid add codex → exit 0'
Assert-DirExists  (Join-Path $ProjT09 '.codex')                   'T09b .codex/ created'
Assert-FileExists (Join-Path $ProjT09 'AGENTS.md')                'T09c AGENTS.md created'
Assert-FileExists (Join-Path $ProjT09 '.aid' '.aid-manifest.json') 'T09d manifest created'

# T10: aid status shows codex.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('status', '-Target', $ProjT09)
Assert-Eq      "$($script:_LastRC)" '0' 'T10a aid status → exit 0'
Assert-Contains $script:_LastOut 'codex' 'T10b status lists codex'

# T11: aid remove codex.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('remove', 'codex', '-Target', $ProjT09)
Assert-Eq      "$($script:_LastRC)" '0' 'T11a aid remove codex → exit 0'
Assert-DirGone (Join-Path $ProjT09 '.codex') 'T11b .codex/ removed'

# Re-add codex for the uninstall test.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT09)

# T12: aid uninstall.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('uninstall', '-Target', $ProjT09)
Assert-Eq      "$($script:_LastRC)" '0' 'T12a aid uninstall → exit 0'
Assert-Contains $script:_LastOut 'Uninstall complete.' 'T12b uninstall banner'
Assert-DirGone (Join-Path $ProjT09 '.codex') 'T12c .codex/ gone after uninstall'

# T13: Manifest and version files are LF/no-BOM after all CLI operations.
$ProjT13 = Join-Path $TmpRoot 'project-t13'
New-Item -ItemType Directory -Path $ProjT13 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('add', 'claude-code', '-FromBundle', $FixClaudeCode, '-Target', $ProjT13)
Assert-FileLF (Join-Path $ProjT13 '.aid' '.aid-manifest.json') 'T13a manifest after aid add'
Assert-FileLF (Join-Path $ProjT13 '.aid' '.aid-version')       'T13b .aid-version after aid add'
Assert-FileLF (Join-Path $AidHomeT08 'VERSION')                'T13c AID_HOME/VERSION'
Write-Host ""

# ===========================================================================
# T14-T15: protect-on-diff
# ===========================================================================
Write-Host "=== T14-T15: protect-on-diff ==="

# T14: user-owned CLAUDE.md → .aid-new created, exit 5, original preserved.
$ProjT14 = Join-Path $TmpRoot 'project-t14'
New-Item -ItemType Directory -Path $ProjT14 -Force | Out-Null

$userClaudeBytes = [System.Text.Encoding]::UTF8.GetBytes("User-owned CLAUDE.md -- not from AID`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT14 'CLAUDE.md'), $userClaudeBytes)

Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT14)
Assert-Eq "$($script:_LastRC)" '5' 'T14a protect-on-diff → exit 5'
Assert-FileExists (Join-Path $ProjT14 'CLAUDE.md.aid-new') 'T14b CLAUDE.md.aid-new written'

$origContent = Get-Content -LiteralPath (Join-Path $ProjT14 'CLAUDE.md') -Raw
Assert-Contains $origContent 'User-owned' 'T14c original CLAUDE.md not overwritten'

$m14 = Get-Content -LiteralPath (Join-Path $ProjT14 '.aid' '.aid-manifest.json') -Raw
Assert-Contains $m14 'pending-merge' 'T14d manifest status is pending-merge'

# .aid-new is a Copy-Item of the LF profile source — must be LF/no-BOM.
Assert-FileLF (Join-Path $ProjT14 'CLAUDE.md.aid-new') 'T14e .aid-new is LF/no-BOM'

# T15: -Force overrides protect-on-diff.
$ProjT15 = Join-Path $TmpRoot 'project-t15'
New-Item -ItemType Directory -Path $ProjT15 -Force | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $ProjT15 'CLAUDE.md'), $userClaudeBytes)

Run-Install @('-Tool', 'claude-code', '-Force', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT15)
Assert-Eq "$($script:_LastRC)" '0' 'T15a -Force protect-on-diff → exit 0'
Assert (-not (Test-Path (Join-Path $ProjT15 'CLAUDE.md.aid-new'))) `
    'T15b no .aid-new with -Force' '.aid-new should not exist'

$forcedContent = Get-Content -LiteralPath (Join-Path $ProjT15 'CLAUDE.md') -Raw
Assert (-not ($forcedContent -like '*User-owned*')) `
    'T15c user content overwritten by -Force' 'user content still present after -Force'
Write-Host ""

# ===========================================================================
# T16: Uninstall removes install roots (dirs actually GONE)
# ===========================================================================
Write-Host "=== T16: Uninstall removes dirs ==="

$ProjT16 = Join-Path $TmpRoot 'project-t16'
New-Item -ItemType Directory -Path $ProjT16 -Force | Out-Null
Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT16)
Assert-DirExists (Join-Path $ProjT16 '.claude') 'T16-pre .claude/ present before uninstall'

Run-Install @('-Uninstall', '-Tool', 'claude-code', '-TargetDirectory', $ProjT16)
Assert-Eq "$($script:_LastRC)" '0' 'T16a uninstall → exit 0'
Assert-DirGone (Join-Path $ProjT16 '.claude') 'T16b .claude/ gone after uninstall'
Assert-DirGone (Join-Path $ProjT16 '.aid')    'T16c .aid/ gone after full uninstall'
Write-Host ""

# ===========================================================================
# T17: Uninstall with no manifest → exit 6
# ===========================================================================
Write-Host "=== T17: Uninstall with no manifest ==="

$ProjT17 = Join-Path $TmpRoot 'project-t17'
New-Item -ItemType Directory -Path $ProjT17 -Force | Out-Null
Run-Install @('-Uninstall', '-Tool', 'claude-code', '-TargetDirectory', $ProjT17)
Assert-Eq "$($script:_LastRC)" '6' 'T17 uninstall with no manifest → exit 6'
Write-Host ""

# ===========================================================================
# Summary
# ===========================================================================
Write-Host "=== Summary ==="
Write-Host "  Tests passed: $($script:_Pass)"
Write-Host "  Tests failed: $($script:_Fail)"
if ($script:_Fail -gt 0) {
    Write-Host ""
    Write-Host "Failed assertions:"
    foreach ($e in $script:_Errors) { Write-Host $e }
}

} finally {
    if (Test-Path $TmpRoot -PathType Container) {
        Remove-Item -LiteralPath $TmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($script:_Fail -gt 0) {
    Write-Host ""
    Write-Host "RESULT: FAIL ($($script:_Fail) assertion(s) failed)"
    exit 1
} else {
    Write-Host ""
    Write-Host "RESULT: PASS (all $($script:_Pass) assertions passed)"
    exit 0
}
