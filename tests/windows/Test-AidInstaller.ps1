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
#   T12  aid remove (no arg, -Force) removes the project AID install
#   T13  Manifest stays LF/no-BOM after all CLI operations
#   T14  root-agent in-place update (branch C2: marker-less sha-mismatch -> excise + re-wrap)
#   T15  root-agent in-place update (branch B: dst has AID:BEGIN/END -> replace region only)
#   T16  Uninstall removes install roots (dirs actually GONE)
#   T17  Uninstall with no manifest → exit 6
#   T45  prune: stale aid-prefixed file removed on update; user file untouched
#   T37  aid projects help / -h → exit 0 + usage strings
#   T38  aid projects list renders registered project + ASCII * cwd marker
#   T39  aid projects add registers existing .aid/ project (tools untouched)
#   T40  aid projects add non-.aid/ path → exit 2 + error message
#   T41  aid projects add idempotent (double add → single registry entry)
#   T42  aid projects remove unregisters / repairs stale entry / idempotent no-op
#
# Old-layout migration acceptance (AC5 + AC8 -- mirrors task-012 bash Gates 10-13):
#   T49  Codex old-layout: .agents/ retired AID trees gone; new .codex/{agents,aid} present;
#        user-file.txt byte-identical; tools.codex.version uniform; HOME/USERPROFILE pinned
#   T50  Cursor old-layout: .cursor/rules/ retired aid-*.mdc gone; new .cursor/{agents,aid}
#        present; user .mdc byte-identical; AGENTS.md user lines outside region preserved;
#        tools.cursor.version uniform; HOME/USERPROFILE pinned
#   T51  Antigravity old-layout: .agent/rules/ retired aid-*.md gone; new .agent/{agents,aid}
#        present; user file byte-identical; AGENTS.md user lines preserved;
#        tools.antigravity.version uniform; HOME/USERPROFILE pinned
#   T52  Idempotency: second aid update on a migrated old-layout repo (codex) is a no-op;
#        retired dirs absent; manifest version stable; witness file sha256 unchanged;
#        user file still byte-identical; HOME/USERPROFILE pinned
#   T53  Escape canary: real USERPROFILE/HOME was never touched by any T49-T52 fixture run
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

# Run-AidPs1Home: like Run-AidPs1 but forces $HOME inside the child pwsh so the
# per-user .update-check cache read ($HOME/.aid/.update-check, FR10) is hermetic
# and never touches the real user home. Used by the self-update-preamble tests (T46).
function Run-AidPs1Home {
    param([string]$AidHome, [string]$FakeHome, [string[]]$AidArgs)
    $aidPs1Path = Join-Path $AidHome 'bin' 'aid.ps1'
    if (-not (Test-Path $aidPs1Path -PathType Leaf)) {
        $aidPs1Path = Join-Path $RepoRoot 'bin' 'aid.ps1'
    }
    $savedHome = $env:AID_HOME
    $savedLib  = $env:AID_LIB_PATH
    $savedUP   = $env:USERPROFILE
    $savedEH   = $env:HOME
    $savedHD   = $env:HOMEDRIVE
    $savedHP   = $env:HOMEPATH
    $env:AID_HOME     = $AidHome
    $env:AID_LIB_PATH = $LocalLibPath
    # Redirect the child pwsh's automatic $HOME to the throwaway via every env var it
    # consults to derive it: $env:HOME on Unix; $env:HOMEDRIVE+$env:HOMEPATH (then
    # $env:USERPROFILE) on Windows. -File (not -Command) so aid.ps1 self-locates its
    # code home from $PSCommandPath correctly.
    $env:HOME        = $FakeHome
    $env:USERPROFILE = $FakeHome
    $env:HOMEDRIVE   = (Split-Path -Qualifier $FakeHome)
    $env:HOMEPATH    = (Split-Path -NoQualifier $FakeHome)
    $outLines = & $PwshExe -NoProfile -File $aidPs1Path @AidArgs 2>&1
    $script:_LastRC  = $LASTEXITCODE
    $script:_LastOut = ($outLines | ForEach-Object { [string]$_ }) -join "`n"
    $script:_LastOut = [System.Text.RegularExpressions.Regex]::Replace($script:_LastOut, $_AnsiPattern, '')
    $env:AID_HOME     = $savedHome
    $env:AID_LIB_PATH = $savedLib
    $env:USERPROFILE  = $savedUP
    $env:HOME         = $savedEH
    $env:HOMEDRIVE    = $savedHD
    $env:HOMEPATH     = $savedHP
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

# Re-add codex for the remove (all) test.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT09)

# T12: aid remove (no arg) with -Force to skip prompt.
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('remove', '-Force', '-Target', $ProjT09)
Assert-Eq      "$($script:_LastRC)" '0' 'T12a aid remove -Force (all) → exit 0'
Assert-Contains $script:_LastOut 'Uninstall complete.' 'T12b remove banner'
Assert-DirGone (Join-Path $ProjT09 '.codex') 'T12c .codex/ gone after remove'

# T13: Manifest and version files are LF/no-BOM after all CLI operations.
$ProjT13 = Join-Path $TmpRoot 'project-t13'
New-Item -ItemType Directory -Path $ProjT13 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('add', 'claude-code', '-FromBundle', $FixClaudeCode, '-Target', $ProjT13)
Assert-FileLF (Join-Path $ProjT13 '.aid' '.aid-manifest.json') 'T13a manifest after aid add'
Assert-FileLF (Join-Path $ProjT13 '.aid' '.aid-version')       'T13b .aid-version after aid add'
Assert-FileLF (Join-Path $AidHomeT08 'VERSION')                'T13c AID_HOME/VERSION'
Write-Host ""

# ===========================================================================
# T14-T15: root-agent in-place region update (replaces old protect-on-diff)
# ===========================================================================
Write-Host "=== T14-T15: root-agent in-place region update ==="

# T14: Branch C2 - marker-less sha-mismatch (user-edited CLAUDE.md, no AID:BEGIN/END).
# New behavior: AID sections excised by stem match, re-wrapped in AID:BEGIN/END in-place.
# Exit 0 always. No .aid-new written. Manifest status is 'owned'.
$ProjT14 = Join-Path $TmpRoot 'project-t14'
New-Item -ItemType Directory -Path $ProjT14 -Force | Out-Null

# Write a user-owned CLAUDE.md that contains AID-managed sections inline (no markers) plus
# user-specific content.  The installer must excise the AID sections, re-wrap them in
# AID:BEGIN/END, and preserve the user content (## Project block).
$userClaudeContent = "# CLAUDE.md`n`n## Project`nMy project description.`n`n## Tracking discipline`nOld tracking text.`n`n## Knowledge Base`nOld KB text.`n`n## Review output format`nOld review text.`n`n## Permissions`nOld perms text.`n"
$userClaudeBytes = [System.Text.Encoding]::UTF8.GetBytes($userClaudeContent)
[System.IO.File]::WriteAllBytes((Join-Path $ProjT14 'CLAUDE.md'), $userClaudeBytes)

Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT14)
Assert-Eq "$($script:_LastRC)" '0' 'T14a root-agent in-place update (C2) -> exit 0'

# No .aid-new must exist under any branch.
Assert (-not (Test-Path (Join-Path $ProjT14 'CLAUDE.md.aid-new'))) `
    'T14b no .aid-new written' '.aid-new must not exist (new behavior: in-place only)'

$updatedContent14 = Get-Content -LiteralPath (Join-Path $ProjT14 'CLAUDE.md') -Raw
# AID region must be wrapped in markers now.
Assert-Contains $updatedContent14 '<!-- AID:BEGIN -->' 'T14c CLAUDE.md now has AID:BEGIN marker'
Assert-Contains $updatedContent14 '<!-- AID:END -->'   'T14d CLAUDE.md now has AID:END marker'
# User content (## Project section) must be preserved.
Assert-Contains $updatedContent14 'My project description.' 'T14e user ## Project content preserved'

# Manifest status must be 'owned' (pending-merge path eliminated).
$m14 = Get-Content -LiteralPath (Join-Path $ProjT14 '.aid' '.aid-manifest.json') -Raw
Assert-Contains $m14 '"owned"' 'T14f manifest status is owned (not pending-merge)'

# T15: Branch B - destination already has AID:BEGIN/END markers.
# Install into a project where CLAUDE.md already has AID markers + user content outside them.
# Installer must replace only the marked region, preserve everything outside, exit 0.
$ProjT15 = Join-Path $TmpRoot 'project-t15'
New-Item -ItemType Directory -Path $ProjT15 -Force | Out-Null

# Write a CLAUDE.md with AID:BEGIN/END markers and extra user content outside the region.
$markedClaudeContent = "# CLAUDE.md`n`n## Project`nUser project section.`n`n<!-- AID:BEGIN -->`n## Tracking discipline`nOLD tracking content that will be replaced.`n<!-- AID:END -->`n`n## Extra User Section`nUser-added content after the AID region.`n"
$markedClaudeBytes = [System.Text.Encoding]::UTF8.GetBytes($markedClaudeContent)
[System.IO.File]::WriteAllBytes((Join-Path $ProjT15 'CLAUDE.md'), $markedClaudeBytes)

Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT15)
Assert-Eq "$($script:_LastRC)" '0' 'T15a root-agent in-place update (B) -> exit 0'

# No .aid-new must exist.
Assert (-not (Test-Path (Join-Path $ProjT15 'CLAUDE.md.aid-new'))) `
    'T15b no .aid-new written (branch B)' '.aid-new must not exist'

$updatedContent15 = Get-Content -LiteralPath (Join-Path $ProjT15 'CLAUDE.md') -Raw
# Markers must be present.
Assert-Contains $updatedContent15 '<!-- AID:BEGIN -->' 'T15c AID:BEGIN marker present after region update'
Assert-Contains $updatedContent15 '<!-- AID:END -->'   'T15d AID:END marker present after region update'
# Content outside the marked region must be preserved.
Assert-Contains $updatedContent15 'User project section.'  'T15e user content before region preserved'
Assert-Contains $updatedContent15 'User-added content after the AID region.' 'T15f user content after region preserved'
# The OLD AID content inside the region must have been replaced by the new profile content.
Assert (-not ($updatedContent15 -like '*OLD tracking content that will be replaced.*')) `
    'T15g old AID region content replaced' 'old region content must be gone after update'
Write-Host ""

# ===========================================================================
# T47: Branch C2 - marker-less file with NO AID sections to anchor the region.
# A pure brownfield user CLAUDE.md (no AID:BEGIN/END, none of the AID heading
# stems). The AID region must still be injected (appended at end), with user
# content preserved. Regression: the region was silently dropped because it was
# only ever inserted at an AID heading position that did not exist here.
# ===========================================================================
Write-Host "=== T47: root-agent region injected into pure-user file (no AID sections) ==="

$ProjT47 = Join-Path $TmpRoot 'project-t47'
New-Item -ItemType Directory -Path $ProjT47 -Force | Out-Null
$userOnlyContent = "# CLAUDE.md`n`n## My Project`nMy own instructions, nothing from AID.`n"
[System.IO.File]::WriteAllBytes((Join-Path $ProjT47 'CLAUDE.md'),
    [System.Text.Encoding]::UTF8.GetBytes($userOnlyContent))

Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT47)
Assert-Eq "$($script:_LastRC)" '0' 'T47a install into pure-user CLAUDE.md -> exit 0'
$updatedContent47 = Get-Content -LiteralPath (Join-Path $ProjT47 'CLAUDE.md') -Raw
Assert-Contains $updatedContent47 '<!-- AID:BEGIN -->' 'T47b AID region injected (BEGIN) - not dropped'
Assert-Contains $updatedContent47 '<!-- AID:END -->'   'T47c AID region injected (END)'
Assert-Contains $updatedContent47 'My own instructions, nothing from AID.' 'T47d user content preserved'
Assert (-not (Test-Path (Join-Path $ProjT47 'CLAUDE.md.aid-new'))) `
    'T47e no .aid-new written' '.aid-new must not exist'
Write-Host ""

# ===========================================================================
# T48: manifest-only repo (aid add, no settings.yml) -- v1.1.1 regression.
# A repo with .aid-manifest.json but no settings.yml: `aid update` must synthesize a
# stamped settings.yml (era-b via the manifest marker) so the format gate stops warning
# on every run. Before the fix the migrate bailed ("not a candidate") and the WARN recurred.
# ===========================================================================
Write-Host "=== T48: manifest-only repo gets a stamped settings.yml on update ==="

$ProjT48 = Join-Path $TmpRoot 'project-t48'
New-Item -ItemType Directory -Path (Join-Path $ProjT48 '.aid') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $ProjT48 '.aid' '.aid-manifest.json'),
    '{"manifest_version":1,"aid_version":"1.0.0","installed_at":"2026-01-01T00:00:00Z","tools":{"claude-code":{"version":"1.0.0","installed_at":"2026-01-01T00:00:00Z","paths":[],"root_agent_files":[]}}}')
Assert (-not (Test-Path (Join-Path $ProjT48 '.aid' 'settings.yml'))) `
    'T48a precondition: manifest-only repo has no settings.yml' 'settings.yml must be absent'

$savedNoUpdT48 = $env:AID_NO_UPDATE_CHECK
$env:AID_NO_UPDATE_CHECK = '1'
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('update', '-FromBundle', $FixClaudeCode, '-Target', $ProjT48)
Assert-FileExists (Join-Path $ProjT48 '.aid' 'settings.yml') 'T48b settings.yml synthesized by update (era-b via manifest)'
$s48 = Get-Content -LiteralPath (Join-Path $ProjT48 '.aid' 'settings.yml') -Raw
Assert-Contains $s48 'format_version: 1' 'T48c format_version: 1 stamped'
# Second update: the gate must no longer warn (stamp current now).
Run-AidPs1 -AidHome $AidHomeT08 -AidArgs @('update', '-FromBundle', $FixClaudeCode, '-Target', $ProjT48)
Assert-NotContains $script:_LastOut 'older format' 'T48d no recurring older-format WARN after stamp'
$env:AID_NO_UPDATE_CHECK = $savedNoUpdT48
Write-Host ""

# ===========================================================================
# T45: prune - stale aid-prefixed file removed on update; user file untouched
# ===========================================================================
Write-Host "=== T45: prune (stale aid-prefixed file removed, user file kept) ==="

$ProjT45 = Join-Path $TmpRoot 'project-t45'
New-Item -ItemType Directory -Path $ProjT45 -Force | Out-Null

# First install to get a proper baseline manifest.
Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT45)
Assert-Eq "$($script:_LastRC)" '0' 'T45-pre install claude-code -> exit 0'

# Plant a stale aid-prefixed file in .claude/skills/ (simulating a file from an older profile
# version that the new profile no longer ships).
$stalePath45 = Join-Path $ProjT45 '.claude' 'skills' 'aid-stale-old-skill.md'
$staleBytes45 = [System.Text.Encoding]::UTF8.GetBytes("# stale old skill`n")
[System.IO.File]::WriteAllBytes($stalePath45, $staleBytes45)

# Plant a user (non-aid-prefixed) file in .claude/skills/ - must NOT be pruned.
$userPath45 = Join-Path $ProjT45 '.claude' 'skills' 'my-custom-skill.md'
$userBytes45 = [System.Text.Encoding]::UTF8.GetBytes("# user custom skill`n")
[System.IO.File]::WriteAllBytes($userPath45, $userBytes45)

# Re-run install (update) - the new profile does not include aid-stale-old-skill.md,
# so prune must remove it; my-custom-skill.md has no aid- prefix so it must survive.
Run-Install @('-Tool', 'claude-code', '-FromBundle', $FixClaudeCode, '-TargetDirectory', $ProjT45)
Assert-Eq "$($script:_LastRC)" '0' 'T45a update install -> exit 0'

Assert (-not (Test-Path $stalePath45 -PathType Leaf)) `
    'T45b stale aid-prefixed file pruned after update' 'stale aid-* file must be removed by prune'
Assert (Test-Path $userPath45 -PathType Leaf) `
    'T45c user (non-aid-prefixed) file untouched by prune' 'user file must survive prune'
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
# T18-T19: bare aid.ps1 (no args) → dashboard landing screen
# ===========================================================================
Write-Host "=== T18-T19: bare aid.ps1 dashboard ==="

# T18: dir with .aid/ fixture → exit 0, header + friendly no-tools message + usage block.
# Per decision #5: bare aid in a dir with NO .aid/ shows the offer-and-exit-0 path.
# To keep testing the dashboard landing we provide a minimal .aid/ fixture so the
# repo-command path renders the header, description, no-tools message, and usage block.
$AidHomeT18 = Join-Path $TmpRoot 'aid-home-t18'
$AidBinT18  = Join-Path $AidHomeT18 'bin'
$AidLibT18  = Join-Path $AidHomeT18 'lib'
New-Item -ItemType Directory -Path $AidBinT18 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT18 -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1')       -Destination (Join-Path $AidBinT18 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath -Destination (Join-Path $AidLibT18 'AidInstallCore.psm1') -Force
# Write a VERSION file so the header can read the CLI version.
$verBytes = [System.Text.Encoding]::UTF8.GetBytes("$Ver`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT18 'VERSION'), $verBytes)

$ProjT18 = Join-Path $TmpRoot 'project-t18'
New-Item -ItemType Directory -Path $ProjT18 -Force | Out-Null
# Add minimal .aid/ fixture so bare aid enters the dashboard (not the no-.aid/ offer path).
New-Item -ItemType Directory -Path (Join-Path $ProjT18 '.aid') -Force | Out-Null
$settingsBytes18 = [System.Text.Encoding]::UTF8.GetBytes("format_version: 1`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT18 '.aid' 'settings.yml'), $settingsBytes18)

# Run bare aid.ps1 (no args) from ProjT18 as cwd (so '.' resolves to an empty project dir).
$savedHome18 = $env:AID_HOME
$savedLib18  = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT18
$env:AID_LIB_PATH = $LocalLibPath
Push-Location $ProjT18
$outLines18 = & $PwshExe -NoProfile -File (Join-Path $AidBinT18 'aid.ps1') 2>&1
$rc18 = $LASTEXITCODE
Pop-Location
$out18 = ($outLines18 | ForEach-Object { [string]$_ }) -join "`n"
$out18 = [System.Text.RegularExpressions.Regex]::Replace($out18, $_AnsiPattern, '')
$env:AID_HOME     = $savedHome18
$env:AID_LIB_PATH = $savedLib18

Assert-Eq     "$rc18"    '0'  'T18a bare aid.ps1 with .aid/ fixture → exit 0'
Assert-Contains $out18 "AID v$Ver"                        'T18b dashboard: header contains AID v<ver>'
Assert-Contains $out18 'AI Integrated Development'        'T18c dashboard: header contains description tag'
Assert-Contains $out18 'Install, update, and manage AID'  'T18d dashboard: description line'
Assert-Contains $out18 'yet'                              'T18e dashboard: friendly no-tools message'
Assert-Contains $out18 'aid add'                          'T18f dashboard: usage block contains aid add'

# T19: project with tool → exit 0, installed tool visible in dashboard.
$AidHomeT19 = Join-Path $TmpRoot 'aid-home-t19'
$AidBinT19  = Join-Path $AidHomeT19 'bin'
$AidLibT19  = Join-Path $AidHomeT19 'lib'
New-Item -ItemType Directory -Path $AidBinT19 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT19 -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1')       -Destination (Join-Path $AidBinT19 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath -Destination (Join-Path $AidLibT19 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT19 'VERSION'), $verBytes)

$ProjT19 = Join-Path $TmpRoot 'project-t19'
New-Item -ItemType Directory -Path $ProjT19 -Force | Out-Null

# Install codex into ProjT19 first.
Run-AidPs1 -AidHome $AidHomeT19 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT19)
Assert-Eq "$($script:_LastRC)" '0' 'T19-pre add codex → exit 0'

# Now run bare aid.ps1 (no args) with ProjT19 as current working directory.
$savedHome19 = $env:AID_HOME
$savedLib19  = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT19
$env:AID_LIB_PATH = $LocalLibPath
Push-Location $ProjT19
$outLines19 = & $PwshExe -NoProfile -File (Join-Path $AidBinT19 'aid.ps1') 2>&1
$rc19 = $LASTEXITCODE
Pop-Location
$out19 = ($outLines19 | ForEach-Object { [string]$_ }) -join "`n"
$out19 = [System.Text.RegularExpressions.Regex]::Replace($out19, $_AnsiPattern, '')
$env:AID_HOME     = $savedHome19
$env:AID_LIB_PATH = $savedLib19

Assert-Eq       "$rc19"    '0'                         'T19a bare aid.ps1 with tool → exit 0'
Assert-Contains  $out19   "AID v$Ver"                  'T19b dashboard with tool: header'
Assert-Contains  $out19   'Installed tools (in'        'T19c dashboard with tool: installed tools section'
Assert-Contains  $out19   'codex'                      'T19d dashboard with tool: codex listed'
Assert-Contains  $out19   'aid add'                    'T19e dashboard with tool: usage block'
Write-Host ""

# ===========================================================================
# T20-T24: collapse-when-uniform display (new behaviour)
# ===========================================================================
Write-Host "=== T20-T24: collapse-when-uniform display ==="

# Provision a fresh AID_HOME for T20+.
$AidHomeT20 = Join-Path $TmpRoot 'aid-home-t20'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT20 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT20 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT20 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT20 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT20 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# T20: uniform case — two tools at the same version, ref == version.
# → header "all at v<V>:", per-tool lines have ONLY the tool name.
$ProjT20 = Join-Path $TmpRoot 'project-t20'
New-Item -ItemType Directory -Path $ProjT20 -Force | Out-Null

Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('add', 'claude-code', '-FromBundle', $FixClaudeCode, '-Target', $ProjT20)
Assert-Eq  "$($script:_LastRC)" '0' 'T20-pre1 add claude-code → exit 0'
Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT20)
Assert-Eq  "$($script:_LastRC)" '0' 'T20-pre2 add codex → exit 0'

Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('status', '-Target', $ProjT20)
Assert-Eq  "$($script:_LastRC)" '0' 'T20a uniform status → exit 0'
Assert-Contains $script:_LastOut "all at v$Ver" 'T20b uniform: header contains "all at v<V>"'
Assert-Contains $script:_LastOut 'claude-code'  'T20c uniform: claude-code listed'
Assert-Contains $script:_LastOut 'codex'        'T20d uniform: codex listed'
# Per-tool lines must NOT contain the version string (collapsed into header).
$toolLines20 = $script:_LastOut -split "`n" | Where-Object { $_ -match '^\s+(claude-code|codex)\s*$' }
foreach ($tl in $toolLines20) {
    Assert-NotContains $tl "v$Ver" "T20e uniform: no per-line version in '$tl'"
}
# Root agent not shown for owned tools.
Assert-NotContains $script:_LastOut 'AGENTS.md'  'T20f uniform: no AGENTS.md shown (owned)'
Assert-NotContains $script:_LastOut 'CLAUDE.md'  'T20g uniform: no CLAUDE.md shown (owned)'
Write-Host ""

# T21: uniform-behind case — tool version < ref version.
# Patch manifest so both tools appear at v0.0.1.
$ProjT21 = Join-Path $TmpRoot 'project-t21'
New-Item -ItemType Directory -Path $ProjT21 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT21)

$mPathT21 = Join-Path $ProjT21 '.aid' '.aid-manifest.json'
$mDataT21 = Get-Content -LiteralPath $mPathT21 -Raw | ConvertFrom-Json
$mDataT21.tools.PSObject.Properties | ForEach-Object { $_.Value.version = '0.0.1' }
# Re-serialize and write.
$mJsonT21 = ($mDataT21 | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($mPathT21, $mJsonT21 + "`n")

Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('status', '-Target', $ProjT21)
Assert-Eq      "$($script:_LastRC)" '0'       'T21a uniform-behind status → exit 0'
Assert-Contains $script:_LastOut 'all at v0.0.1' 'T21b uniform-behind: "all at v0.0.1" in header'
Assert-Contains $script:_LastOut 'update'         'T21c uniform-behind: update hint present'
Assert-Contains $script:_LastOut "v$Ver"           'T21d uniform-behind: ref version in hint'
Write-Host ""

# T22: divergent case — two tools at different versions.
$ProjT22 = Join-Path $TmpRoot 'project-t22'
New-Item -ItemType Directory -Path $ProjT22 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('add', 'claude-code', '-FromBundle', $FixClaudeCode, '-Target', $ProjT22)
Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('add', 'codex',       '-FromBundle', $FixCodex,      '-Target', $ProjT22)

# Patch claude-code to an older version.
$mPathT22 = Join-Path $ProjT22 '.aid' '.aid-manifest.json'
$mDataT22 = Get-Content -LiteralPath $mPathT22 -Raw | ConvertFrom-Json
$mDataT22.tools.'claude-code'.version = '0.1.0'
$mJsonT22 = ($mDataT22 | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($mPathT22, $mJsonT22 + "`n")

Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('status', '-Target', $ProjT22)
Assert-Eq         "$($script:_LastRC)" '0' 'T22a divergent status → exit 0'
Assert-NotContains $script:_LastOut 'all at v'   'T22b divergent: no "all at v" header'
Assert-Contains    $script:_LastOut 'v0.1.0'     'T22c divergent: claude-code version shown'
Assert-Contains    $script:_LastOut "v$Ver"      'T22d divergent: codex version shown'
Assert-Contains    $script:_LastOut 'update'     'T22e divergent: update hint for stale tool'
# codex is at ref, so no update hint on its line.
$codexLine22 = $script:_LastOut -split "`n" | Where-Object { $_ -match '\bcodex\b' } | Select-Object -First 1
if ($codexLine22) {
    Assert-NotContains $codexLine22 'update' 'T22f divergent: no update hint for current codex'
}
Write-Host ""

# T23: aid status empty dir → exit 0 + offer message (decision #5 new behavior).
$ProjT23 = Join-Path $TmpRoot 'project-t23'
New-Item -ItemType Directory -Path $ProjT23 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT20 -AidArgs @('status', '-Target', $ProjT23)
Assert-Eq "$($script:_LastRC)" '0' 'T23 empty dir status → exit 0 (offer-and-exit, new behavior)'
Assert-Contains $script:_LastOut 'no AID project here' 'T23b empty dir status prints offer message'
Write-Host ""

# T24: parity — Bash uniform output == PS1 uniform output (key header line).
# Build a separate Bash-capable AID_HOME.
$AidHomeT24 = Join-Path $TmpRoot 'aid-home-t24'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT24 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT24 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid')        -Destination (Join-Path $AidHomeT24 'bin' 'aid')          -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1')    -Destination (Join-Path $AidHomeT24 'bin' 'aid.ps1')      -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot 'lib' 'aid-install-core.sh') `
          -Destination (Join-Path $AidHomeT24 'lib' 'aid-install-core.sh') -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT24 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT24 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

$ProjT24 = Join-Path $TmpRoot 'project-t24'
New-Item -ItemType Directory -Path $ProjT24 -Force | Out-Null
Run-AidPs1 -AidHome $AidHomeT24 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT24)
Assert-Eq "$($script:_LastRC)" '0' 'T24-pre PS1 add codex → exit 0'

Run-AidPs1 -AidHome $AidHomeT24 -AidArgs @('status', '-Target', $ProjT24)
$ps1HeaderT24 = $script:_LastOut -split "`n" | Where-Object { $_ -match 'Installed tools' } | Select-Object -First 1

Assert-Contains $ps1HeaderT24 "all at v$Ver" 'T24a PS1 uniform header contains "all at v<V>"'
Write-Host ""

# ===========================================================================
# T25-T30: Update check + aid update self (hermetic — no real network)
# ===========================================================================
Write-Host "=== T25-T30: Update check + aid update self ==="

# Helper: write a fake "releases/latest" JSON file to a temp path.
# Returns the file:// URL string.
function New-FakeReleaseJson {
    param([string]$Dir, [string]$Version)
    $path = Join-Path $Dir 'latest.json'
    $json = "{`"tag_name`":`"v$Version`",`"name`":`"v$Version`"}`n"
    [System.IO.File]::WriteAllText($path, $json)
    return "file:///$($path -replace '\\', '/')"
}

# Provision a fresh AID_HOME for T25+.
$AidHomeT25 = Join-Path $TmpRoot 'aid-home-t25'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT25 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT25 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT25 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT25 'lib' 'AidInstallCore.psm1') -Force

# T25: NEWER version available → notice shown on bare aid.ps1 (dashboard).
# Force installed version to 0.1.0 so any published version is newer.
[System.IO.File]::WriteAllText((Join-Path $AidHomeT25 'VERSION'), "0.1.0`n")

$JsonDirT25 = Join-Path $TmpRoot 'json-t25'
New-Item -ItemType Directory -Path $JsonDirT25 -Force | Out-Null
$checkUrlT25 = New-FakeReleaseJson -Dir $JsonDirT25 -Version '9.9.9'

$ProjT25 = Join-Path $TmpRoot 'project-t25'
New-Item -ItemType Directory -Path $ProjT25 -Force | Out-Null
# Add minimal .aid/ fixture so bare aid enters the dashboard (not the no-.aid/ offer path),
# enabling the update-notice to render (per decision #5 / PS029-A pattern).
New-Item -ItemType Directory -Path (Join-Path $ProjT25 '.aid') -Force | Out-Null
$settingsBytes25 = [System.Text.Encoding]::UTF8.GetBytes("format_version: 1`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT25 '.aid' 'settings.yml'), $settingsBytes25)

$savedHome25 = $env:AID_HOME; $savedLib25 = $env:AID_LIB_PATH
$env:AID_HOME             = $AidHomeT25
$env:AID_LIB_PATH         = $LocalLibPath
$env:AID_NO_UPDATE_CHECK  = '0'
$env:AID_UPDATE_CHECK_URL = $checkUrlT25
Push-Location $ProjT25
$outLines25 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT25 'bin' 'aid.ps1') 2>&1
$rc25 = $LASTEXITCODE
Pop-Location
$out25 = ($outLines25 | ForEach-Object { [string]$_ }) -join "`n"
$out25 = [System.Text.RegularExpressions.Regex]::Replace($out25, $_AnsiPattern, '')
$env:AID_HOME             = $savedHome25
$env:AID_LIB_PATH         = $savedLib25
$env:AID_NO_UPDATE_CHECK  = $null
$env:AID_UPDATE_CHECK_URL = $null

Assert-Eq      "$rc25"  '0'                               'T25a bare aid.ps1 newer version → exit 0'
Assert-Contains $out25  'A newer aid CLI is available'    'T25b notice: "A newer aid CLI is available"'
Assert-Contains $out25  'v9.9.9'                          'T25c notice: latest version shown'
Assert-Contains $out25  'v0.1.0'                          'T25d notice: current version shown'
Assert-Contains $out25  'aid update self'                 'T25e notice: "aid update self" mentioned'
Write-Host ""

# T26: SAME version → no notice.
$AidHomeT26 = Join-Path $TmpRoot 'aid-home-t26'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT26 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT26 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT26 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT26 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllText((Join-Path $AidHomeT26 'VERSION'), "$Ver`n")

$JsonDirT26 = Join-Path $TmpRoot 'json-t26'
New-Item -ItemType Directory -Path $JsonDirT26 -Force | Out-Null
$checkUrlT26 = New-FakeReleaseJson -Dir $JsonDirT26 -Version $Ver

$ProjT26 = Join-Path $TmpRoot 'project-t26'
New-Item -ItemType Directory -Path $ProjT26 -Force | Out-Null

$savedHome26 = $env:AID_HOME; $savedLib26 = $env:AID_LIB_PATH
$env:AID_HOME             = $AidHomeT26
$env:AID_LIB_PATH         = $LocalLibPath
$env:AID_NO_UPDATE_CHECK  = '0'
$env:AID_UPDATE_CHECK_URL = $checkUrlT26
Push-Location $ProjT26
$outLines26 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT26 'bin' 'aid.ps1') 2>&1
$rc26 = $LASTEXITCODE
Pop-Location
$out26 = ($outLines26 | ForEach-Object { [string]$_ }) -join "`n"
$out26 = [System.Text.RegularExpressions.Regex]::Replace($out26, $_AnsiPattern, '')
$env:AID_HOME             = $savedHome26
$env:AID_LIB_PATH         = $savedLib26
$env:AID_NO_UPDATE_CHECK  = $null
$env:AID_UPDATE_CHECK_URL = $null

Assert-Eq          "$rc26"  '0'                              'T26a same version → exit 0'
Assert-NotContains  $out26  'A newer aid CLI is available'   'T26b same version: no notice'
Write-Host ""

# T27: AID_NO_UPDATE_CHECK=1 → no notice.
$AidHomeT27 = Join-Path $TmpRoot 'aid-home-t27'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT27 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT27 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT27 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT27 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllText((Join-Path $AidHomeT27 'VERSION'), "0.1.0`n")

$ProjT27 = Join-Path $TmpRoot 'project-t27'
New-Item -ItemType Directory -Path $ProjT27 -Force | Out-Null

$savedHome27 = $env:AID_HOME; $savedLib27 = $env:AID_LIB_PATH
$env:AID_HOME             = $AidHomeT27
$env:AID_LIB_PATH         = $LocalLibPath
$env:AID_NO_UPDATE_CHECK  = '1'
Push-Location $ProjT27
$outLines27 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT27 'bin' 'aid.ps1') 2>&1
$rc27 = $LASTEXITCODE
Pop-Location
$out27 = ($outLines27 | ForEach-Object { [string]$_ }) -join "`n"
$out27 = [System.Text.RegularExpressions.Regex]::Replace($out27, $_AnsiPattern, '')
$env:AID_HOME             = $savedHome27
$env:AID_LIB_PATH         = $savedLib27
$env:AID_NO_UPDATE_CHECK  = $null

Assert-Eq          "$rc27" '0'                            'T27a opt-out: exit 0'
Assert-NotContains  $out27 'A newer aid CLI is available' 'T27b opt-out: no notice'
Write-Host ""

# T28: Failing check URL → command still exits 0 (fail-silent).
$AidHomeT28 = Join-Path $TmpRoot 'aid-home-t28'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT28 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT28 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT28 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT28 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllText((Join-Path $AidHomeT28 'VERSION'), "0.1.0`n")

$ProjT28 = Join-Path $TmpRoot 'project-t28'
New-Item -ItemType Directory -Path $ProjT28 -Force | Out-Null

$savedHome28 = $env:AID_HOME; $savedLib28 = $env:AID_LIB_PATH
$env:AID_HOME             = $AidHomeT28
$env:AID_LIB_PATH         = $LocalLibPath
$env:AID_NO_UPDATE_CHECK  = '0'
$env:AID_UPDATE_CHECK_URL = 'file:///no/such/path/does-not-exist.json'
Push-Location $ProjT28
$outLines28 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT28 'bin' 'aid.ps1') 2>&1
$rc28 = $LASTEXITCODE
Pop-Location
$out28 = ($outLines28 | ForEach-Object { [string]$_ }) -join "`n"
$out28 = [System.Text.RegularExpressions.Regex]::Replace($out28, $_AnsiPattern, '')
$env:AID_HOME             = $savedHome28
$env:AID_LIB_PATH         = $savedLib28
$env:AID_NO_UPDATE_CHECK  = $null
$env:AID_UPDATE_CHECK_URL = $null

Assert-Eq "$rc28" '0' 'T28 failing check URL → exit 0 (fail-silent)'
Write-Host ""

# T29: Notice shown on 'aid status' (not just dashboard).
$AidHomeT29 = Join-Path $TmpRoot 'aid-home-t29'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT29 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT29 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT29 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT29 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllText((Join-Path $AidHomeT29 'VERSION'), "0.1.0`n")

$JsonDirT29 = Join-Path $TmpRoot 'json-t29'
New-Item -ItemType Directory -Path $JsonDirT29 -Force | Out-Null
$checkUrlT29 = New-FakeReleaseJson -Dir $JsonDirT29 -Version '9.9.9'

$ProjT29 = Join-Path $TmpRoot 'project-t29'
New-Item -ItemType Directory -Path $ProjT29 -Force | Out-Null
# Install codex so status exits 0.
Run-AidPs1 -AidHome $AidHomeT29 -AidArgs @('add', 'codex', '-FromBundle', $FixCodex, '-Target', $ProjT29)
Assert-Eq "$($script:_LastRC)" '0' 'T29-pre add codex → exit 0'

$savedHome29 = $env:AID_HOME; $savedLib29 = $env:AID_LIB_PATH
$env:AID_HOME             = $AidHomeT29
$env:AID_LIB_PATH         = $LocalLibPath
$env:AID_NO_UPDATE_CHECK  = '0'
$env:AID_UPDATE_CHECK_URL = $checkUrlT29
$outLines29 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT29 'bin' 'aid.ps1') `
                  'status' '-Target' $ProjT29 2>&1
$rc29 = $LASTEXITCODE
$out29 = ($outLines29 | ForEach-Object { [string]$_ }) -join "`n"
$out29 = [System.Text.RegularExpressions.Regex]::Replace($out29, $_AnsiPattern, '')
$env:AID_HOME             = $savedHome29
$env:AID_LIB_PATH         = $savedLib29
$env:AID_NO_UPDATE_CHECK  = $null
$env:AID_UPDATE_CHECK_URL = $null

Assert-Eq      "$rc29" '0'                            'T29a aid status with newer version → exit 0'
Assert-Contains $out29 'A newer aid CLI is available' 'T29b aid status shows notice'
Write-Host ""

# T30: aid update self — prints 'Updating the aid CLI...' then relays exit code.
# Use a non-existent URL so Invoke-RestMethod fails immediately → exit 3.
$AidHomeT30 = Join-Path $TmpRoot 'aid-home-t30'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT30 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT30 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT30 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT30 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllText((Join-Path $AidHomeT30 'VERSION'), "$Ver`n")

$savedHome30 = $env:AID_HOME; $savedLib30 = $env:AID_LIB_PATH
$env:AID_HOME            = $AidHomeT30
$env:AID_LIB_PATH        = $LocalLibPath
$env:AID_NO_UPDATE_CHECK = '1'
$env:AID_INSTALL_URL     = 'https://nonexistent.invalid/install.ps1'
$outLines30 = & $PwshExe -NoProfile -File (Join-Path $AidHomeT30 'bin' 'aid.ps1') `
                  'update' 'self' 2>&1
$rc30 = $LASTEXITCODE
$out30 = ($outLines30 | ForEach-Object { [string]$_ }) -join "`n"
$out30 = [System.Text.RegularExpressions.Regex]::Replace($out30, $_AnsiPattern, '')
$env:AID_HOME            = $savedHome30
$env:AID_LIB_PATH        = $savedLib30
$env:AID_NO_UPDATE_CHECK = $null
$env:AID_INSTALL_URL     = $null

Assert-Contains $out30 'Updating the aid CLI' 'T30a update self prints update message'
Assert-Eq "$rc30" '3' 'T30b update self with bad URL → exit 3'
Write-Host ""

# ===========================================================================
# T31-T34: Upgrade regression — stale lib gets replaced on re-bootstrap
# ===========================================================================
Write-Host "=== T31-T34: Upgrade regression (stale lib replaced on re-bootstrap) ==="

# T31: Bootstrap over an existing install with a stale AidInstallCore.psm1 refreshes it.
# Seed AID_HOME with an old aid.ps1 + a lib stub that does NOT contain Get-AidStatusBody.
$AidHomeT31 = Join-Path $TmpRoot 'aid-home-t31'
$AidBinT31  = Join-Path $AidHomeT31 'bin'
$AidLibT31  = Join-Path $AidHomeT31 'lib'
New-Item -ItemType Directory -Path $AidBinT31 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT31 -Force | Out-Null

# Seed a stale aid.ps1 (empty placeholder).
$stalePs1Bytes = [System.Text.Encoding]::UTF8.GetBytes("#Requires -Version 5.1`n# stale`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidBinT31 'aid.ps1'), $stalePs1Bytes)

# Seed a stale lib that does NOT export Get-AidStatusBody.
$staleModBytes = [System.Text.Encoding]::UTF8.GetBytes("# stale module — missing Get-AidStatusBody`nfunction Stale-Fn { }`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidLibT31 'AidInstallCore.psm1'), $staleModBytes)

# Seed an old VERSION.
[System.IO.File]::WriteAllText((Join-Path $AidHomeT31 'VERSION'), "0.0.1`n")

# Re-bootstrap over the stale install (disk path, no network).
$savedHome31  = $env:AID_HOME
$savedNoPath31 = $env:AID_NO_PATH
$savedLib31   = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT31
$env:AID_NO_PATH  = '1'
$env:AID_LIB_PATH = $LocalLibPath

$outLines31 = & $PwshExe -NoProfile -File $InstallPs1 2>&1
$rc31 = $LASTEXITCODE
$out31 = ($outLines31 | ForEach-Object { [string]$_ }) -join "`n"
$out31 = [System.Text.RegularExpressions.Regex]::Replace($out31, $_AnsiPattern, '')

$env:AID_HOME     = $savedHome31
$env:AID_NO_PATH  = $savedNoPath31
$env:AID_LIB_PATH = $savedLib31

Assert-Eq "$rc31" '0' 'T31a re-bootstrap over stale install → exit 0'

$installedLibContent31 = ''
$installedLibPath31 = Join-Path $AidLibT31 'AidInstallCore.psm1'
if (Test-Path $installedLibPath31 -PathType Leaf) {
    $installedLibContent31 = Get-Content -LiteralPath $installedLibPath31 -Raw
}
Assert-Contains $installedLibContent31 'Get-AidStatusBody' `
    'T31b re-bootstrap: installed lib now contains Get-AidStatusBody sentinel'
Assert-Eq (Get-Content -LiteralPath (Join-Path $AidHomeT31 'VERSION') -Raw).Trim() $Ver `
    'T31c re-bootstrap: VERSION updated to current'
Write-Host ""

# T32: Post-copy verify catches a deliberately-corrupted/empty lib source.
# Pass a bad AID_LIB_PATH (empty file) → installer must exit non-zero with clear error.
$AidHomeT32   = Join-Path $TmpRoot 'aid-home-t32'
$BadLibT32    = Join-Path $TmpRoot 'bad-lib-t32.psm1'
# Empty lib: no sentinel, no functions.
[System.IO.File]::WriteAllBytes($BadLibT32, [byte[]]@())

$savedHome32   = $env:AID_HOME
$savedNoPath32 = $env:AID_NO_PATH
$savedLib32    = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT32
$env:AID_NO_PATH  = '1'
$env:AID_LIB_PATH = $BadLibT32

$outLines32 = & $PwshExe -NoProfile -File $InstallPs1 2>&1
$rc32 = $LASTEXITCODE
$out32 = ($outLines32 | ForEach-Object { [string]$_ }) -join "`n"
$out32 = [System.Text.RegularExpressions.Regex]::Replace($out32, $_AnsiPattern, '')

$env:AID_HOME     = $savedHome32
$env:AID_NO_PATH  = $savedNoPath32
$env:AID_LIB_PATH = $savedLib32

Assert ($rc32 -ne 0) 'T32a corrupted lib (empty) → installer exits non-zero' "expected non-zero exit, got $rc32"
Assert-Contains $out32 'Get-AidStatusBody' `
    'T32b corrupted lib: error message mentions sentinel Get-AidStatusBody'
Assert-Contains $out32 'installer could not refresh' `
    'T32c corrupted lib: error message says installer could not refresh'
Write-Host ""

# T33: Stale-core dispatcher guard (aid.ps1).
# Point aid.ps1 at an AID_HOME whose lib is a stub missing Get-AidStatusBody.
# The dispatcher must print the clear 'stale core' error and exit 1.
$AidHomeT33 = Join-Path $TmpRoot 'aid-home-t33'
$AidBinT33  = Join-Path $AidHomeT33 'bin'
$AidLibT33  = Join-Path $AidHomeT33 'lib'
New-Item -ItemType Directory -Path $AidBinT33 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT33 -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') -Destination (Join-Path $AidBinT33 'aid.ps1') -Force

# Stub lib that loads without error but does NOT define Get-AidStatusBody.
$stubModBytes = [System.Text.Encoding]::UTF8.GetBytes("# stub module — no Get-AidStatusBody`nfunction Stub-Fn { }`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidLibT33 'AidInstallCore.psm1'), $stubModBytes)
[System.IO.File]::WriteAllText((Join-Path $AidHomeT33 'VERSION'), "$Ver`n")

$ProjT33 = Join-Path $TmpRoot 'project-t33'
New-Item -ItemType Directory -Path $ProjT33 -Force | Out-Null

$savedHome33 = $env:AID_HOME
$env:AID_HOME = $AidHomeT33
Push-Location $ProjT33
$outLines33 = & $PwshExe -NoProfile -File (Join-Path $AidBinT33 'aid.ps1') 2>&1
$rc33 = $LASTEXITCODE
Pop-Location
$out33 = ($outLines33 | ForEach-Object { [string]$_ }) -join "`n"
$out33 = [System.Text.RegularExpressions.Regex]::Replace($out33, $_AnsiPattern, '')
$env:AID_HOME = $savedHome33

Assert ($rc33 -ne 0) 'T33a dispatcher with stale-core lib → exits non-zero' "expected non-zero exit, got $rc33"
Assert-Contains $out33 'failed to load the CLI core' `
    'T33b dispatcher stale-core: error says failed to load the CLI core'
Assert-Contains $out33 'reinstall' `
    'T33c dispatcher stale-core: error says reinstall'
Write-Host ""

# T34: After a successful re-bootstrap, bare aid.ps1 (dashboard) exits 0
# (no "term not recognized" error from the refreshed lib).
$AidHomeT34 = Join-Path $TmpRoot 'aid-home-t34'
$AidBinT34  = Join-Path $AidHomeT34 'bin'
$AidLibT34  = Join-Path $AidHomeT34 'lib'
New-Item -ItemType Directory -Path $AidBinT34 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT34 -Force | Out-Null

# Seed a stale install.
$stalePs1Bytes34 = [System.Text.Encoding]::UTF8.GetBytes("#Requires -Version 5.1`n# stale`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidBinT34 'aid.ps1'), $stalePs1Bytes34)
$staleModBytes34 = [System.Text.Encoding]::UTF8.GetBytes("# stale module`nfunction Stale-Fn { }`n")
[System.IO.File]::WriteAllBytes((Join-Path $AidLibT34 'AidInstallCore.psm1'), $staleModBytes34)
[System.IO.File]::WriteAllText((Join-Path $AidHomeT34 'VERSION'), "0.0.1`n")

# Re-bootstrap.
$savedHome34  = $env:AID_HOME
$savedNoPath34 = $env:AID_NO_PATH
$savedLib34   = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT34
$env:AID_NO_PATH  = '1'
$env:AID_LIB_PATH = $LocalLibPath
$outLines34 = & $PwshExe -NoProfile -File $InstallPs1 2>&1
$rc34bs = $LASTEXITCODE
$env:AID_HOME     = $savedHome34
$env:AID_NO_PATH  = $savedNoPath34
$env:AID_LIB_PATH = $savedLib34
Assert-Eq "$rc34bs" '0' 'T34a re-bootstrap for dashboard test → exit 0'

# Run bare aid.ps1 (dashboard) → should succeed with the fresh lib.
$ProjT34 = Join-Path $TmpRoot 'project-t34'
New-Item -ItemType Directory -Path $ProjT34 -Force | Out-Null
# Add minimal .aid/ fixture so bare aid enters the dashboard path (not the no-.aid/ offer path),
# enabling T34c to assert the landing header renders correctly (per decision #5).
New-Item -ItemType Directory -Path (Join-Path $ProjT34 '.aid') -Force | Out-Null
$settingsBytes34 = [System.Text.Encoding]::UTF8.GetBytes("format_version: 1`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT34 '.aid' 'settings.yml'), $settingsBytes34)

$savedHome34b = $env:AID_HOME
$savedLib34b  = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT34
$env:AID_LIB_PATH = $LocalLibPath
Push-Location $ProjT34
$outLines34b = & $PwshExe -NoProfile -File (Join-Path $AidBinT34 'aid.ps1') 2>&1
$rc34 = $LASTEXITCODE
Pop-Location
$out34 = ($outLines34b | ForEach-Object { [string]$_ }) -join "`n"
$out34 = [System.Text.RegularExpressions.Regex]::Replace($out34, $_AnsiPattern, '')
$env:AID_HOME     = $savedHome34b
$env:AID_LIB_PATH = $savedLib34b

Assert-Eq "$rc34" '0' 'T34b bare aid.ps1 after re-bootstrap → exit 0 (no stale-core error)'
Assert-Contains $out34 'AID v' 'T34c dashboard header present after re-bootstrap'
Write-Host ""

# ===========================================================================
# T35: Dot-source load path — Get-AidStatusBody is available in script scope
# Verifies that the cache-proof dot-source path in aid.ps1 exposes the function
# so it is callable from within the dispatcher's script scope.
# ===========================================================================
Write-Host "=== T35: Dot-source load exposes Get-AidStatusBody ==="

$AidHomeT35 = Join-Path $TmpRoot 'aid-home-t35'
$AidBinT35  = Join-Path $AidHomeT35 'bin'
$AidLibT35  = Join-Path $AidHomeT35 'lib'
New-Item -ItemType Directory -Path $AidBinT35 -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT35 -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') -Destination (Join-Path $AidBinT35 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath -Destination (Join-Path $AidLibT35 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT35 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# Verify that the dot-source approach in aid.ps1 makes Get-AidStatusBody available:
# run `aid.ps1 version` (which loads the lib) and confirm exit 0.
# More directly: verify the lib is dot-sourceable in a fresh PS scope and the function exists.
$probe35 = & $PwshExe -NoProfile -Command @"
`$env:AID_HOME     = '$AidHomeT35'
`$env:AID_NO_UPDATE_CHECK = '1'
`$libPath = '$AidLibT35\AidInstallCore.psm1'
`$libRaw = Get-Content -LiteralPath `$libPath -Raw -ErrorAction Stop
function Export-ModuleMember { param([Parameter(ValueFromRemainingArguments=`$true)]`$args) }
. ([scriptblock]::Create(`$libRaw))
if (Get-Command 'Get-AidStatusBody' -ErrorAction SilentlyContinue) {
    Write-Host 'Get-AidStatusBody: FOUND'
    exit 0
} else {
    Write-Host 'Get-AidStatusBody: MISSING'
    exit 1
}
"@ 2>&1
$rc35 = $LASTEXITCODE
$out35probe = ($probe35 | ForEach-Object { [string]$_ }) -join "`n"

Assert-Eq "$rc35" '0' 'T35a dot-source exposes Get-AidStatusBody → exit 0'
Assert-Contains $out35probe 'Get-AidStatusBody: FOUND' 'T35b Get-AidStatusBody visible after dot-source'

# Also verify bare aid.ps1 (dashboard) exits 0, confirming dispatch works end-to-end.
$ProjT35 = Join-Path $TmpRoot 'project-t35'
New-Item -ItemType Directory -Path $ProjT35 -Force | Out-Null
# Add minimal .aid/ fixture so bare aid enters the dashboard path (not the no-.aid/ offer path),
# enabling T35d to assert the landing header renders (per decision #5).
New-Item -ItemType Directory -Path (Join-Path $ProjT35 '.aid') -Force | Out-Null
$settingsBytes35 = [System.Text.Encoding]::UTF8.GetBytes("format_version: 1`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT35 '.aid' 'settings.yml'), $settingsBytes35)

$savedHome35 = $env:AID_HOME
$savedLib35  = $env:AID_LIB_PATH
$env:AID_HOME            = $AidHomeT35
$env:AID_LIB_PATH        = $LocalLibPath
$env:AID_NO_UPDATE_CHECK = '1'
Push-Location $ProjT35
$outLines35 = & $PwshExe -NoProfile -File (Join-Path $AidBinT35 'aid.ps1') 2>&1
$rc35d = $LASTEXITCODE
Pop-Location
$out35 = ($outLines35 | ForEach-Object { [string]$_ }) -join "`n"
$out35 = [System.Text.RegularExpressions.Regex]::Replace($out35, $_AnsiPattern, '')
$env:AID_HOME            = $savedHome35
$env:AID_LIB_PATH        = $savedLib35
$env:AID_NO_UPDATE_CHECK = $null

Assert-Eq     "$rc35d" '0'     'T35c bare aid.ps1 with dot-source → exit 0 (no cache-error)'
Assert-Contains $out35 "AID v$Ver" 'T35d dashboard header present (dot-source load path)'
Write-Host ""

# ===========================================================================
# T36: sha256 installer verify — truncated dest lib fails, correct dest passes
# Confirms that the new sha256 post-copy verify in install.ps1 catches a
# corrupted/truncated installed lib (mismatch source ≠ dest).
# ===========================================================================
Write-Host "=== T36: sha256 installer verify catches truncated install ==="

# T36a: Good install (correct source) → verify passes (exit 0 on full bootstrap).
# This is implicitly tested by T08/T31 already.  Re-confirm with a direct hash check.
$AidHomeT36 = Join-Path $TmpRoot 'aid-home-t36'
New-Item -ItemType Directory -Path $AidHomeT36 -Force | Out-Null

$savedHome36  = $env:AID_HOME
$savedNoPath36 = $env:AID_NO_PATH
$savedLib36   = $env:AID_LIB_PATH
$env:AID_HOME     = $AidHomeT36
$env:AID_NO_PATH  = '1'
$env:AID_LIB_PATH = $LocalLibPath

$outLines36a = & $PwshExe -NoProfile -File $InstallPs1 2>&1
$rc36a = $LASTEXITCODE

$env:AID_HOME     = $savedHome36
$env:AID_NO_PATH  = $savedNoPath36
$env:AID_LIB_PATH = $savedLib36

Assert-Eq "$rc36a" '0' 'T36a good install → sha256 verify passes (exit 0)'

# Verify the installed lib sha256 matches the source.
$installedLib36 = Join-Path $AidHomeT36 'lib' 'AidInstallCore.psm1'
if (Test-Path $installedLib36 -PathType Leaf) {
    $srcHash36  = (Get-FileHash -LiteralPath $LocalLibPath   -Algorithm SHA256).Hash
    $destHash36 = (Get-FileHash -LiteralPath $installedLib36 -Algorithm SHA256).Hash
    Assert-Eq "$destHash36" "$srcHash36" 'T36b installed lib sha256 matches source'
} else {
    script:RecordFail 'T36b installed lib sha256 matches source' "installed lib not found: $installedLib36"
}

# T36c: Tamper: truncate the installed lib AFTER install, then attempt to use it via
# the dispatcher (aid.ps1).  Aid should reject it with the "failed to load" error.
# (The sha256 verify in install.ps1 runs at install time, not at dispatch time.)
# We test dispatch resilience by putting a truncated lib in AID_HOME and running aid.ps1.
$AidHomeT36c = Join-Path $TmpRoot 'aid-home-t36c'
$AidBinT36c  = Join-Path $AidHomeT36c 'bin'
$AidLibT36c  = Join-Path $AidHomeT36c 'lib'
New-Item -ItemType Directory -Path $AidBinT36c -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibT36c -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') -Destination (Join-Path $AidBinT36c 'aid.ps1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT36c 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# Write a deliberately-truncated lib: has the sentinel in a comment but no actual function.
# This simulates a partial download that passed the old grep-based check.
$truncatedLib36 = "# AidInstallCore.psm1`n# Contains Get-AidStatusBody in this comment only`nfunction Stub-Fn { }`n"
[System.IO.File]::WriteAllBytes((Join-Path $AidLibT36c 'AidInstallCore.psm1'),
    [System.Text.Encoding]::UTF8.GetBytes($truncatedLib36))

$ProjT36c = Join-Path $TmpRoot 'project-t36c'
New-Item -ItemType Directory -Path $ProjT36c -Force | Out-Null

$savedHome36c = $env:AID_HOME
$env:AID_HOME = $AidHomeT36c
Push-Location $ProjT36c
$outLines36c = & $PwshExe -NoProfile -File (Join-Path $AidBinT36c 'aid.ps1') 2>&1
$rc36c = $LASTEXITCODE
Pop-Location
$out36c = ($outLines36c | ForEach-Object { [string]$_ }) -join "`n"
$out36c = [System.Text.RegularExpressions.Regex]::Replace($out36c, $_AnsiPattern, '')
$env:AID_HOME = $savedHome36c

Assert ($rc36c -ne 0) 'T36c truncated lib in AID_HOME → aid dispatcher exits non-zero' `
    "expected non-zero exit from aid.ps1 with truncated lib, got $rc36c"
Assert-Contains $out36c 'failed to load the CLI core' `
    'T36d truncated lib: aid.ps1 reports failed to load the CLI core'
Write-Host ""

# ===========================================================================
# T37-T42: aid projects command (list / add / remove / help)
# Mirrors the bash REG-P0x contract in the Windows-native PS suite.
# All tests pin AID_HOME to isolated temp dirs so registry writes never touch
# the developer's real $HOME/.aid.  The fallback tier ($HOME/.aid/registry.yml)
# is read-only for these tests (not written to); assertions are path-specific,
# so any pre-existing real entries are benign.
# ===========================================================================
Write-Host "=== T37-T42: aid projects (list / add / remove / help) ==="

# Provision a shared AID_HOME for the projects tests (T37-T42).
$AidHomeTP = Join-Path $TmpRoot 'aid-home-projects'
$AidBinTP  = Join-Path $AidHomeTP 'bin'
$AidLibTP  = Join-Path $AidHomeTP 'lib'
New-Item -ItemType Directory -Path $AidBinTP -Force | Out-Null
New-Item -ItemType Directory -Path $AidLibTP -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidBinTP 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidLibTP 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeTP 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# Helper: invoke aid.ps1 for projects tests with an isolated AID_HOME.
# Captures stdout+stderr merged into $script:_LastOut and $script:_LastRC.
function Run-AidProjects {
    param([string]$AidHome, [string[]]$AidArgs, [string]$FromDir = '')
    $savedHome = $env:AID_HOME
    $savedLib  = $env:AID_LIB_PATH
    $savedNoUpd = $env:AID_NO_UPDATE_CHECK
    $env:AID_HOME            = $AidHome
    $env:AID_LIB_PATH        = $LocalLibPath
    $env:AID_NO_UPDATE_CHECK = '1'
    $aidPs1Path = Join-Path $AidHome 'bin' 'aid.ps1'
    if (-not (Test-Path $aidPs1Path -PathType Leaf)) {
        $aidPs1Path = Join-Path $RepoRoot 'bin' 'aid.ps1'
    }
    if ($FromDir -and (Test-Path $FromDir -PathType Container)) {
        Push-Location $FromDir
        $outLines = & $PwshExe -NoProfile -File $aidPs1Path @AidArgs 2>&1
        $script:_LastRC = $LASTEXITCODE
        Pop-Location
    } else {
        $outLines = & $PwshExe -NoProfile -File $aidPs1Path @AidArgs 2>&1
        $script:_LastRC = $LASTEXITCODE
    }
    $script:_LastOut = ($outLines | ForEach-Object { [string]$_ }) -join "`n"
    $script:_LastOut = [System.Text.RegularExpressions.Regex]::Replace($script:_LastOut, $_AnsiPattern, '')
    $env:AID_HOME            = $savedHome
    $env:AID_LIB_PATH        = $savedLib
    $env:AID_NO_UPDATE_CHECK = $savedNoUpd
}

# ---------------------------------------------------------------------------
# T37: aid projects help / -h -> exit 0 + usage strings.
# ---------------------------------------------------------------------------
Write-Host "--- T37: aid projects help ---"

Run-AidProjects -AidHome $AidHomeTP -AidArgs @('projects', 'help')
Assert-Eq    "$($script:_LastRC)" '0' 'T37a aid projects help -> exit 0'
Assert-Contains $script:_LastOut 'aid projects' 'T37b help output contains "aid projects"'
Assert-Contains $script:_LastOut 'list'          'T37c help output mentions list'
Assert-Contains $script:_LastOut 'add'           'T37d help output mentions add'
Assert-Contains $script:_LastOut 'remove'        'T37e help output mentions remove'

Run-AidProjects -AidHome $AidHomeTP -AidArgs @('projects', '-h')
Assert-Eq    "$($script:_LastRC)" '0' 'T37f aid projects -h -> exit 0'
Assert-Contains $script:_LastOut 'aid projects' 'T37g -h output contains "aid projects"'
Write-Host ""

# ---------------------------------------------------------------------------
# T38: aid projects list renders registered projects with state and * marker.
# Setup: register one .aid/ project, run list from that project dir -> * marker.
# ---------------------------------------------------------------------------
Write-Host "--- T38: aid projects list ---"

$ProjT38 = Join-Path $TmpRoot 'project-t38'
New-Item -ItemType Directory -Path $ProjT38 -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT38 '.aid') -Force | Out-Null
# Give it a manifest so state resolves to a version.
$manifestT38 = @{
    aid_version    = $Ver
    tools          = @{ codex = @{ version = $Ver } }
    manifest_version = 1
} | ConvertTo-Json -Depth 5
$manifestBytesT38 = [System.Text.Encoding]::UTF8.GetBytes($manifestT38 + "`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT38 '.aid' '.aid-manifest.json'), $manifestBytesT38)

# Register the project via aid projects add.
Run-AidProjects -AidHome $AidHomeTP -AidArgs @('projects', 'add', $ProjT38)
Assert-Eq "$($script:_LastRC)" '0' 'T38-pre add project -> exit 0'
Assert-Contains $script:_LastOut 'registered' 'T38-pre add output confirms registration'

# List from the registered project dir -> * marker expected.
Run-AidProjects -AidHome $AidHomeTP -AidArgs @('projects', 'list') -FromDir $ProjT38
Assert-Eq "$($script:_LastRC)" '0' 'T38a aid projects list from registered cwd -> exit 0'
Assert-Contains $script:_LastOut $ProjT38   'T38b list output contains registered project path'
Assert-Contains $script:_LastOut '* '       'T38c list: ASCII * marker present for cwd'

# Verify the * is on the line that contains the project path (not just a legend line).
$starLineT38 = ($script:_LastOut -split "`n") | Where-Object {
    $_.IndexOf('* ', [System.StringComparison]::Ordinal) -ge 0 -and
    $_.IndexOf($ProjT38, [System.StringComparison]::Ordinal) -ge 0
} | Select-Object -First 1
Assert ($null -ne $starLineT38 -and $starLineT38 -ne '') `
    'T38d list: * and project path on the same line' `
    'no line containing both * and the registered project path'

# The state column must contain a recognizable value (version, untracked, or no-aid).
# Since we installed a manifest with a version number, expect the version.
Assert-Contains $script:_LastOut $Ver 'T38e list: version in state column for tracked project'
Write-Host ""

# ---------------------------------------------------------------------------
# T39: aid projects add registers an existing .aid/ project.
# ---------------------------------------------------------------------------
Write-Host "--- T39: aid projects add (register) ---"

# Provision a fresh AID_HOME so the registry is isolated from T38.
$AidHomeT39 = Join-Path $TmpRoot 'aid-home-t39'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT39 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT39 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT39 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT39 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT39 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

$ProjT39 = Join-Path $TmpRoot 'project-t39'
New-Item -ItemType Directory -Path $ProjT39 -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT39 '.aid') -Force | Out-Null
# Sentinel file: tools must be untouched by projects add.
$sentinelT39Bytes = [System.Text.Encoding]::UTF8.GetBytes("sentinel`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT39 '.aid' 'sentinel.txt'), $sentinelT39Bytes)

Run-AidProjects -AidHome $AidHomeT39 -AidArgs @('projects', 'add', $ProjT39)
Assert-Eq "$($script:_LastRC)" '0' 'T39a aid projects add existing .aid/ project -> exit 0'
Assert-Contains $script:_LastOut 'registered' 'T39b add output confirms registration'

# Registry file must contain the project path.
$regT39 = Join-Path $AidHomeT39 'registry.yml'
Assert-FileExists $regT39 'T39c registry.yml created after add'
$regContT39 = Get-Content -LiteralPath $regT39 -Raw -ErrorAction SilentlyContinue
Assert-Contains "$regContT39" $ProjT39 'T39d registry.yml contains the registered project path'

# Sentinel file must be untouched (projects add does NOT modify tools).
Assert-FileExists (Join-Path $ProjT39 '.aid' 'sentinel.txt') 'T39e tools untouched: sentinel.txt still present'
Write-Host ""

# ---------------------------------------------------------------------------
# T40: aid projects add non-.aid/ path -> exit 2, error message.
# ---------------------------------------------------------------------------
Write-Host "--- T40: aid projects add non-.aid/ path ---"

$ProjT40NoAid = Join-Path $TmpRoot 'project-t40-noaid'
New-Item -ItemType Directory -Path $ProjT40NoAid -Force | Out-Null
# No .aid/ directory created.

Run-AidProjects -AidHome $AidHomeT39 -AidArgs @('projects', 'add', $ProjT40NoAid)
Assert-Eq "$($script:_LastRC)" '2' 'T40a add non-.aid/ path -> exit 2'
Assert-Contains $script:_LastOut 'not an AID project' 'T40b error message mentions "not an AID project"'
Write-Host ""

# ---------------------------------------------------------------------------
# T41: aid projects add idempotent -> same project twice, single registry entry.
# ---------------------------------------------------------------------------
Write-Host "--- T41: aid projects add idempotent ---"

# Add the T39 project a second time -> should succeed (exit 0) with no duplicate.
Run-AidProjects -AidHome $AidHomeT39 -AidArgs @('projects', 'add', $ProjT39)
Assert-Eq "$($script:_LastRC)" '0' 'T41a add same project twice -> exit 0 (idempotent)'

# Count '  - ' lines in registry to confirm single entry.
$regContT41 = Get-Content -LiteralPath $regT39 -Raw -ErrorAction SilentlyContinue
$entryCountT41 = 0
foreach ($ln in ($regContT41 -split "`n")) {
    if ($ln -match '^\s+-\s+') { $entryCountT41++ }
}
Assert ($entryCountT41 -eq 1) 'T41b idempotent: exactly one registry entry after double add' `
    "expected 1 entry, found $entryCountT41"
Write-Host ""

# ---------------------------------------------------------------------------
# T42: aid projects remove unregisters / repairs stale / idempotent.
# ---------------------------------------------------------------------------
Write-Host "--- T42: aid projects remove ---"

# Provision a fresh AID_HOME for T42 to avoid T39 state leaking.
$AidHomeT42 = Join-Path $TmpRoot 'aid-home-t42'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT42 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT42 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT42 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT42 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT42 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

$ProjT42 = Join-Path $TmpRoot 'project-t42'
New-Item -ItemType Directory -Path $ProjT42 -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT42 '.aid') -Force | Out-Null
$sentinelT42Bytes = [System.Text.Encoding]::UTF8.GetBytes("sentinel`n")
[System.IO.File]::WriteAllBytes((Join-Path $ProjT42 '.aid' 'sentinel.txt'), $sentinelT42Bytes)
$regT42 = Join-Path $AidHomeT42 'registry.yml'

# Pre-register.
Run-AidProjects -AidHome $AidHomeT42 -AidArgs @('projects', 'add', $ProjT42)
Assert-Eq "$($script:_LastRC)" '0' 'T42-setup pre-register project -> exit 0'

# (a) Remove unregisters; tools/files untouched.
Run-AidProjects -AidHome $AidHomeT42 -AidArgs @('projects', 'remove', $ProjT42)
Assert-Eq "$($script:_LastRC)" '0' 'T42a aid projects remove -> exit 0'
$regContT42a = Get-Content -LiteralPath $regT42 -Raw -ErrorAction SilentlyContinue
Assert-NotContains "$regContT42a" $ProjT42 'T42b remove: project path absent from registry after remove'
# Sentinel file must still exist (projects remove does NOT touch tools).
Assert-FileExists (Join-Path $ProjT42 '.aid' 'sentinel.txt') 'T42c tools untouched: sentinel.txt still present after remove'

# (b) Stale entry repair: manually write a non-existent path and remove it by path.
$stalePathT42 = Join-Path $TmpRoot 'stale-t42-does-not-exist'
# Append the stale entry to the registry.
$existingRegT42 = if (Test-Path $regT42 -PathType Leaf) {
    Get-Content -LiteralPath $regT42 -Raw
} else {
    "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).`n# Holds ONLY the base folders of projects this CLI install manages.`n# description come from .aid/settings.yml; version/tools from the manifest, at render time.`nschema: 1`nprojects:`n"
}
$staleLineBytes = [System.Text.Encoding]::UTF8.GetBytes($existingRegT42 + "  - $stalePathT42`n")
[System.IO.File]::WriteAllBytes($regT42, $staleLineBytes)
$regContT42b_pre = Get-Content -LiteralPath $regT42 -Raw -ErrorAction SilentlyContinue
Assert-Contains "$regContT42b_pre" $stalePathT42 'T42d stale entry written to registry'

Run-AidProjects -AidHome $AidHomeT42 -AidArgs @('projects', 'remove', $stalePathT42)
Assert-Eq "$($script:_LastRC)" '0' 'T42e remove stale/missing entry -> exit 0 (repair stale)'
$regContT42b_post = Get-Content -LiteralPath $regT42 -Raw -ErrorAction SilentlyContinue
Assert-NotContains "$regContT42b_post" $stalePathT42 'T42f stale entry removed from registry'

# (c) Idempotent: remove a path not in registry -> no-op message, exit 0.
$absentPathT42 = Join-Path $TmpRoot 'absent-t42-not-registered'
Run-AidProjects -AidHome $AidHomeT42 -AidArgs @('projects', 'remove', $absentPathT42)
Assert-Eq "$($script:_LastRC)" '0' 'T42g remove absent path -> exit 0 (idempotent no-op)'
Assert-Contains $script:_LastOut 'was not registered' 'T42h no-op: "was not registered" message emitted'
Write-Host ""

# ---------------------------------------------------------------------------
# T43: state-home exclusion -- running aid.ps1 from a dir whose .aid/ IS the
# CLI state home must give the "aid add" offer, no registration, no "older format".
# Mirror of bash REG-SH regression tests (BUG-1).
# ---------------------------------------------------------------------------
Write-Host "--- T43: state-home exclusion (BUG-1 regression) ---"

$AidHomeT43 = Join-Path $TmpRoot 'aid-home-t43'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT43 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT43 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT43 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT43 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT43 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# Create a fake HOME with .aid/ that acts as the state home (no settings.yml -- not a project).
$FakeHomeT43  = Join-Path $TmpRoot 'fake-home-t43'
$FakeAidT43   = Join-Path $FakeHomeT43 '.aid'
New-Item -ItemType Directory -Path $FakeAidT43 -Force | Out-Null
# Populate state home: only registry.yml (what a state home holds).
[System.IO.File]::WriteAllText((Join-Path $FakeAidT43 'registry.yml'), "schema: 1`nprojects:`n")

# Run bare aid.ps1 from FakeHomeT43 where FakeHomeT43/.aid IS the state home.
# AID_HOME is the state-home override the CLI honors (-> _AidStateHome = FakeAidT43);
# the code home is self-located from the aid.ps1 path (AidHomeT43), independent of
# AID_HOME. This makes the state-home exclusion match via _AidStateHome on every
# platform (PowerShell's automatic $HOME is %USERPROFILE% on Windows and would NOT
# track $env:HOME, so the prior AID_HOME=code-home + $env:HOME setup only worked on
# Linux).
$savedHomeT43    = $env:HOME
$savedAidHomeT43 = $env:AID_HOME
$savedSHT43      = $env:AID_STATE_HOME
$savedNoUpdT43   = $env:AID_NO_UPDATE_CHECK
$env:AID_HOME            = $FakeAidT43
$env:AID_STATE_HOME      = $FakeAidT43
$env:AID_NO_UPDATE_CHECK = '1'
if ($env:HOME -ne $null) { $env:HOME = $FakeHomeT43 }
Push-Location $FakeHomeT43
$t43Lines = & $PwshExe -NoProfile -File (Join-Path $AidHomeT43 'bin' 'aid.ps1') 2>&1
$t43RC    = $LASTEXITCODE
Pop-Location
$env:HOME            = $savedHomeT43
$env:AID_HOME        = $savedAidHomeT43
$env:AID_STATE_HOME  = $savedSHT43
$env:AID_NO_UPDATE_CHECK = $savedNoUpdT43

$t43Out = ($t43Lines | ForEach-Object { [string]$_ }) -join "`n"
$t43Out = [System.Text.RegularExpressions.Regex]::Replace($t43Out, $_AnsiPattern, '')

Assert-Eq    "$t43RC" '0'                   'T43a bare aid.ps1 from state-home dir -> exit 0'
Assert-Contains    $t43Out 'no AID project here' 'T43b bare aid.ps1 from state-home: aid add offer shown'
Assert-NotContains $t43Out 'older format'        'T43c bare aid.ps1 from state-home: no older-format WARN'
Assert-NotContains $t43Out 'Registered'          'T43d bare aid.ps1 from state-home: no registration'

Write-Host ""

# ---------------------------------------------------------------------------
# T44: format-gate manifest guard (BUG-3 regression).
# "WARN: older format ... Run: aid update" fires ONLY for tracked repos
# (manifest present). Untracked repos (.aid/ present, no manifest) stay silent.
# Mirror of bash REG-FG regression tests.
# ---------------------------------------------------------------------------
Write-Host "--- T44: format-gate manifest guard (BUG-3 regression) ---"

$AidHomeT44 = Join-Path $TmpRoot 'aid-home-t44'
New-Item -ItemType Directory -Path (Join-Path $AidHomeT44 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $AidHomeT44 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $AidHomeT44 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $AidHomeT44 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $AidHomeT44 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))
$AidStateT44 = Join-Path $TmpRoot 'aid-state-t44'
New-Item -ItemType Directory -Path $AidStateT44 -Force | Out-Null

# T44a/b: untracked repo -- .aid/ present, NO manifest.
# aid.ps1 status must NOT print "older format" WARN.
$UntrackedT44 = Join-Path $TmpRoot 'fg-untracked-t44'
New-Item -ItemType Directory -Path (Join-Path $UntrackedT44 '.aid') -Force | Out-Null
$settingsUntrackedT44 = "project:`n  name: untracked-t44`n  type: brownfield`ntools:`n  installed: []`n"
[System.IO.File]::WriteAllText((Join-Path $UntrackedT44 '.aid' 'settings.yml'), $settingsUntrackedT44)
# No .aid/.aid-manifest.json -- this is the untracked case.

$savedAidHomeT44 = $env:AID_HOME
$savedSHT44      = $env:AID_STATE_HOME
$savedNoUpdT44   = $env:AID_NO_UPDATE_CHECK
$env:AID_HOME            = $AidHomeT44
$env:AID_STATE_HOME      = $AidStateT44
$env:AID_NO_UPDATE_CHECK = '1'
Push-Location $UntrackedT44
$t44aLines = & $PwshExe -NoProfile -File (Join-Path $AidHomeT44 'bin' 'aid.ps1') status 2>&1
Pop-Location
$env:AID_HOME            = $savedAidHomeT44
$env:AID_STATE_HOME      = $savedSHT44
$env:AID_NO_UPDATE_CHECK = $savedNoUpdT44

$t44aOut = ($t44aLines | ForEach-Object { [string]$_ }) -join "`n"
$t44aOut = [System.Text.RegularExpressions.Regex]::Replace($t44aOut, $_AnsiPattern, '')
Assert-NotContains $t44aOut 'older format' 'T44a aid.ps1 status in untracked repo: no older-format WARN'

# T44b/c: tracked old-format repo -- manifest present, no format_version stamp.
# aid.ps1 status MUST print "older format ... Run: aid update".
$TrackedT44 = Join-Path $TmpRoot 'fg-tracked-t44'
New-Item -ItemType Directory -Path (Join-Path $TrackedT44 '.aid') -Force | Out-Null
$settingsTrackedT44 = "project:`n  name: tracked-t44`n  type: brownfield`ntools:`n  installed: []`n"
[System.IO.File]::WriteAllText((Join-Path $TrackedT44 '.aid' 'settings.yml'), $settingsTrackedT44)
$manifestContentT44 = '{"manifest_version":1,"aid_version":"1.0.0","tools":{"claude-code":{"version":"1.0.0"}}}'
[System.IO.File]::WriteAllText((Join-Path $TrackedT44 '.aid' '.aid-manifest.json'), $manifestContentT44)

$savedAidHomeT44b = $env:AID_HOME
$savedSHT44b      = $env:AID_STATE_HOME
$savedNoUpdT44b   = $env:AID_NO_UPDATE_CHECK
$env:AID_HOME            = $AidHomeT44
$env:AID_STATE_HOME      = $AidStateT44
$env:AID_NO_UPDATE_CHECK = '1'
Push-Location $TrackedT44
$t44bLines = & $PwshExe -NoProfile -File (Join-Path $AidHomeT44 'bin' 'aid.ps1') status 2>&1
Pop-Location
$env:AID_HOME            = $savedAidHomeT44b
$env:AID_STATE_HOME      = $savedSHT44b
$env:AID_NO_UPDATE_CHECK = $savedNoUpdT44b

$t44bOut = ($t44bLines | ForEach-Object { [string]$_ }) -join "`n"
$t44bOut = [System.Text.RegularExpressions.Regex]::Replace($t44bOut, $_AnsiPattern, '')
Assert-Contains $t44bOut 'older format' 'T44b aid.ps1 status in tracked old-format repo: WARN older format printed'

Write-Host ""

# ---------------------------------------------------------------------------
# T46: self-update-if-stale preamble parity with bin/aid (Bash/PS1 parity bug).
#
# 'aid update [<tool>]' runs a self-update-if-stale preamble (Invoke-AidUpdateSelfIfStale)
# that compares the installed CLI VERSION against the cached latest in
# $HOME/.aid/.update-check (line 2). The PowerShell twin must match bin/aid:
#   (a) BUNDLE BYPASS: --from-bundle never phones the channel to self-update.
#   (b) SEMVER GUARD: only self-update when installed is STRICTLY OLDER than cached
#       latest -- a newer installed (unreleased dev build) is never downgraded.
# Regression for the Windows-only bug where installed 1.1.0 vs stale cache 1.0.0
# wrongly printed "CLI is not current ... self-updating".
#
# Hermetic: AID_SKIP_SELF_INSTALL=1 makes the actual self-update a no-op (the
# preamble's decision line still prints first), AID_NO_UPDATE_CHECK=1 suppresses
# the background fetch, the target is a non-project dir (update exits 6 after the
# preamble -- no network, no prompt), and $HOME is forced to a throwaway so the
# planted .update-check cache is read instead of the real user's.
# ---------------------------------------------------------------------------
Write-Host "--- T46: self-update-if-stale preamble (bundle bypass + semver guard) ---"

function script:New-AidCodeHomeT46 {
    param([string]$Dir, [string]$Version)
    New-Item -ItemType Directory -Path (Join-Path $Dir 'bin') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Dir 'lib') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
              -Destination (Join-Path $Dir 'bin' 'aid.ps1') -Force
    Copy-Item -LiteralPath $LocalLibPath `
              -Destination (Join-Path $Dir 'lib' 'AidInstallCore.psm1') -Force
    [System.IO.File]::WriteAllText((Join-Path $Dir 'VERSION'), "$Version`n")
}

function script:New-AidFakeHomeT46 {
    param([string]$Dir, [string]$CachedLatest)
    New-Item -ItemType Directory -Path (Join-Path $Dir '.aid') -Force | Out-Null
    # .update-check: line 1 = timestamp (ignored), line 2 = cached latest version.
    [System.IO.File]::WriteAllText((Join-Path $Dir '.aid' '.update-check'), "0`n$CachedLatest`n")
}

# Target: a project (.aid/settings.yml, NO manifest) so 'aid update' reaches the
# self-update preamble, then exits cleanly (no manifest -> nothing to install ->
# exit 6) without any network or prompt. A non-project dir would exit even earlier
# ("set it up?"), before the preamble.
$ProjT46 = Join-Path $TmpRoot 'proj-t46'
New-Item -ItemType Directory -Path (Join-Path $ProjT46 '.aid') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $ProjT46 '.aid' 'settings.yml'),
    "project:`n  name: proj-t46`n  type: brownfield`ntools:`n  installed: []`n")
$BundleDirT46 = Join-Path $TmpRoot 'bundle-dir-t46'
New-Item -ItemType Directory -Path $BundleDirT46 -Force | Out-Null

$savedSkipT46 = $env:AID_SKIP_SELF_INSTALL
$savedNoUpdT46 = $env:AID_NO_UPDATE_CHECK
$savedNoMigT46 = $env:AID_NO_MIGRATE
$env:AID_SKIP_SELF_INSTALL = '1'
$env:AID_NO_UPDATE_CHECK   = '1'
$env:AID_NO_MIGRATE        = '1'

# --- T46a: positive control -- dev-BEHIND, non-bundle -> preamble MUST fire.
# Proves the planted cache is actually read (guards against a trivial false pass).
$AidHomeT46Behind = Join-Path $TmpRoot 'aid-home-t46-behind'
script:New-AidCodeHomeT46 -Dir $AidHomeT46Behind -Version '1.0.0'
$FakeHomeT46Newer = Join-Path $TmpRoot 'fakehome-t46-newer'
script:New-AidFakeHomeT46 -Dir $FakeHomeT46Newer -CachedLatest '1.1.0'

Run-AidPs1Home -AidHome $AidHomeT46Behind -FakeHome $FakeHomeT46Newer `
    -AidArgs @('update', '-Target', $ProjT46)
Assert-Contains $script:_LastOut 'CLI is not current' `
    'T46a positive control (installed 1.0.0 < cached 1.1.0, non-bundle): preamble self-update fires'

# --- T46b: dev-AHEAD, non-bundle -> preamble MUST NOT fire (semver guard).
# This is the Windows bug: string-inequality wrongly treated 1.1.0 != 1.0.0 as stale.
$AidHomeT46Ahead = Join-Path $TmpRoot 'aid-home-t46-ahead'
script:New-AidCodeHomeT46 -Dir $AidHomeT46Ahead -Version '1.1.0'
$FakeHomeT46Older = Join-Path $TmpRoot 'fakehome-t46-older'
script:New-AidFakeHomeT46 -Dir $FakeHomeT46Older -CachedLatest '1.0.0'

Run-AidPs1Home -AidHome $AidHomeT46Ahead -FakeHome $FakeHomeT46Older `
    -AidArgs @('update', '-Target', $ProjT46)
Assert-NotContains $script:_LastOut 'CLI is not current' `
    'T46b semver guard (installed 1.1.0 >= cached 1.0.0): no spurious self-update (never downgrade)'

# --- T46c: bundle bypass -- dev-BEHIND + cache newer (would fire) BUT --from-bundle.
# Mirrors bin/aid: a bundle install never phones the channel to self-update.
Run-AidPs1Home -AidHome $AidHomeT46Behind -FakeHome $FakeHomeT46Newer `
    -AidArgs @('update', '--from-bundle', $BundleDirT46, '-Target', $ProjT46)
Assert-NotContains $script:_LastOut 'CLI is not current' `
    'T46c bundle bypass (--from-bundle): no self-update even when cache is newer'

$env:AID_SKIP_SELF_INSTALL = $savedSkipT46
$env:AID_NO_UPDATE_CHECK   = $savedNoUpdT46
$env:AID_NO_MIGRATE        = $savedNoMigT46

Write-Host ""


# ===========================================================================
# T49-T53: Old-layout migration acceptance (AC5 + AC8)
#
# These gates mirror task-012 bash Gates 10-13.  They build a real
# pre-work-005 old-layout repo (retired .agents\, .cursor\rules\,
# .agent\rules\ AID content) and run `aid update` (via aid.ps1 /
# AidInstallCore.psm1, -FromBundle for offline/deterministic operation)
# asserting:
#   (AC5) Retired AID trees are GONE; new layout present; user content
#         byte-identical (Get-FileHash SHA256).
#   (AC8) tools.*.version is uniform after migration (no mixed-version).
#   Idempotency: second `aid update` is a no-op.
#
# Every fixture run pins $HOME / $env:USERPROFILE to a throwaway via
# Run-AidPs1Home, so the migration scanner never touches the real user home.
# T53 is an escape canary that confirms the real USERPROFILE was untouched.
# ===========================================================================
Write-Host "=== T49-T53: Old-layout migration acceptance ==="

# ---------------------------------------------------------------------------
# Snapshot the real USERPROFILE (canary baseline) BEFORE any fixture run.
# ---------------------------------------------------------------------------
$_T49_REAL_UP = $env:USERPROFILE
if (-not $_T49_REAL_UP) { $_T49_REAL_UP = $env:HOME }
# Snapshot the .aid dirs that exist in the real user home right now.
$_T49_CANARY_BEFORE = ''
if ($_T49_REAL_UP -and (Test-Path $_T49_REAL_UP -PathType Container)) {
    try {
        $items = @(Get-ChildItem -LiteralPath $_T49_REAL_UP -Recurse -Depth 6 `
            -Filter '.aid' -Directory -ErrorAction SilentlyContinue)
        $_T49_CANARY_BEFORE = ($items | ForEach-Object { $_.FullName } | Sort-Object) -join "`n"
    } catch { $_T49_CANARY_BEFORE = '' }
}

# ---------------------------------------------------------------------------
# Build fixture tarballs for codex, cursor, antigravity (offline bundles).
# Reuse the existing Build-FixtureTarball helper (already defined above).
# ---------------------------------------------------------------------------
$MigFixtureDir = Join-Path $TmpRoot 'mig-fixtures'
New-Item -ItemType Directory -Path $MigFixtureDir -Force | Out-Null

Write-Host "Building migration fixture tarballs..."
$MigFixCodex      = Build-FixtureTarball 'codex'      $MigFixtureDir
$MigFixCursor     = Build-FixtureTarball 'cursor'     $MigFixtureDir
$MigFixAntigrav   = Build-FixtureTarball 'antigravity' $MigFixtureDir
Write-Host "  codex      : $MigFixCodex"
Write-Host "  cursor     : $MigFixCursor"
Write-Host "  antigravity: $MigFixAntigrav"
Write-Host ""

# Shared AID_HOME for all migration tests (reuse AidHomeT08 pattern).
$MigAidHome = Join-Path $TmpRoot 'aid-home-mig'
New-Item -ItemType Directory -Path (Join-Path $MigAidHome 'bin') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $MigAidHome 'lib') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'bin' 'aid.ps1') `
          -Destination (Join-Path $MigAidHome 'bin' 'aid.ps1') -Force
Copy-Item -LiteralPath $LocalLibPath `
          -Destination (Join-Path $MigAidHome 'lib' 'AidInstallCore.psm1') -Force
[System.IO.File]::WriteAllBytes((Join-Path $MigAidHome 'VERSION'),
    [System.Text.Encoding]::UTF8.GetBytes("$Ver`n"))

# Throwaway fake-home for all migration fixture runs (reuses Run-AidPs1Home).
$MigFakeHome = Join-Path $TmpRoot 'mig-fake-home'
New-Item -ItemType Directory -Path $MigFakeHome -Force | Out-Null

# Helper: write a minimal pre-work-005 manifest (era-b shape; old version).
function Write-OldManifest {
    param([string]$ManifestPath, [string]$Tool, [string]$OldVer = '0.7.0')
    $json = "{`"schema`":1,`"tools`":{`"$Tool`":{`"version`":`"$OldVer`",`"status`":`"active`",`"installed_at`":`"2025-01-01T00:00:00Z`",`"paths`":[]}}}`n"
    [System.IO.File]::WriteAllText($ManifestPath, $json)
}

# Helper: write a minimal settings.yml (era-a, no format_version stamp).
function Write-OldSettings {
    param([string]$SettingsPath, [string]$Tool)
    $yml = "project:`n  name: OldLayoutFixture`n  description: Pre-work-005 old layout`n  type: brownfield`n`ntools:`n  installed:`n    - $Tool`n`nreview:`n  minimum_grade: A`n`nexecution:`n  max_parallel_tasks: 5`n`ntraceability:`n  heartbeat_interval: 1`n"
    [System.IO.File]::WriteAllText($SettingsPath, $yml)
}

# Helper: run 'aid update --from-bundle <dir> --target <repo>' via aid.ps1,
# with $HOME / $env:USERPROFILE pinned to a throwaway (migration-scan safety).
# Captures output in $script:_LastOut and exit code in $script:_LastRC.
function Run-MigUpdate {
    param([string]$BundleFile, [string]$TargetRepo)
    # Derive the bundle directory from the tarball path (aid update takes a dir).
    $bundleDir = Split-Path -Parent $BundleFile
    Run-AidPs1Home -AidHome $MigAidHome -FakeHome $MigFakeHome `
        -AidArgs @('update', '-FromBundle', $bundleDir, '-Target', $TargetRepo)
}

# ===========================================================================
# T49: Codex old-layout fixture (mirrors bash Gate 10)
#
# Fixture: pre-work-005 codex repo with:
#   .agents\skills\aid-orchestrator.md  (AID content, marker 1: aid- prefix)
#   .agents\aid\shared.md               (AID content, marker 2: inside aid\)
#   .agents\user-file.txt               (USER content: no AID marker)
#   .codex\agents\aid-orchestrator.toml (old split agents dir)
#   AGENTS.md -- no AID:BEGIN/END region (aid update installs it fresh)
#
# Asserts (AC5):
#   T49-02  .agents\skills\aid-orchestrator.md GONE
#   T49-03  .agents\aid\shared.md GONE
#   T49-04  No remaining aid-owned content under .agents\
#   T49-05  New .codex\agents\ present
#   T49-06  New .codex\aid\ present
#   T49-07  .codex\agents\ contains aid-*.toml files
#   T49-08  user-file.txt byte-identical (SHA256)
# Asserts (AC8):
#   T49-09  manifest exists
#   T49-10  tools.codex.version == $Ver (uniform)
# ===========================================================================
Write-Host "--- T49: Codex old-layout migration ---"

$ProjT49 = Join-Path $TmpRoot 'project-t49'
New-Item -ItemType Directory -Path (Join-Path $ProjT49 '.agents' 'skills') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT49 '.agents' 'aid') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT49 '.codex' 'agents') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT49 '.aid') -Force | Out-Null

# AID-owned content under retired .agents\ (marker 1: aid- prefix).
[System.IO.File]::WriteAllText((Join-Path $ProjT49 '.agents' 'skills' 'aid-orchestrator.md'),
    "old codex orchestrator skill`n")
# AID-owned content under .agents\ (marker 2: inside aid\ subdir).
[System.IO.File]::WriteAllText((Join-Path $ProjT49 '.agents' 'aid' 'shared.md'),
    "old shared aid config`n")
# USER content: no AID marker -- must survive byte-identical.
$T49UserContent = "USER-FILE-T49-SENTINEL`n"
[System.IO.File]::WriteAllText((Join-Path $ProjT49 '.agents' 'user-file.txt'), $T49UserContent)
$T49UserHashBefore = (Get-FileHash -LiteralPath (Join-Path $ProjT49 '.agents' 'user-file.txt') `
    -Algorithm SHA256).Hash

# Old .codex\agents\ split (aid- prefix -- will be replaced by new layout).
[System.IO.File]::WriteAllText((Join-Path $ProjT49 '.codex' 'agents' 'aid-orchestrator.toml'),
    "old codex agent toml`n")

Write-OldManifest -ManifestPath (Join-Path $ProjT49 '.aid' '.aid-manifest.json') -Tool 'codex'
Write-OldSettings -SettingsPath (Join-Path $ProjT49 '.aid' 'settings.yml') -Tool 'codex'

Run-MigUpdate -BundleFile $MigFixCodex -TargetRepo $ProjT49
Assert-Eq "$($script:_LastRC)" '0' 'T49-01 aid update on codex old-layout -> exit 0'

# AC5-a: retired .agents\ AID-owned content GONE.
Assert (-not (Test-Path (Join-Path $ProjT49 '.agents' 'skills' 'aid-orchestrator.md') -PathType Leaf)) `
    'T49-02 (AC5) .agents\skills\aid-orchestrator.md removed (AID-owned, marker 1)' `
    'aid-orchestrator.md must be removed by retired-root sweep'
Assert (-not (Test-Path (Join-Path $ProjT49 '.agents' 'aid' 'shared.md') -PathType Leaf)) `
    'T49-03 (AC5) .agents\aid\shared.md removed (AID-owned, marker 2)' `
    'shared.md must be removed by retired-root sweep'
$T49AidRemains = @(Get-ChildItem -LiteralPath (Join-Path $ProjT49 '.agents') -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'aid-*' -or ($_.FullName -match '[\\/]aid[\\/]') })
Assert ($T49AidRemains.Count -eq 0) `
    'T49-04 (AC5) .agents\ has no remaining AID-owned content' `
    "found $($T49AidRemains.Count) AID-owned item(s) still under .agents\"

# AC5-b: new .codex\ unified layout present.
Assert-DirExists (Join-Path $ProjT49 '.codex' 'agents') 'T49-05 (AC5) new .codex\agents\ present'
Assert-DirExists (Join-Path $ProjT49 '.codex' 'aid')    'T49-06 (AC5) new .codex\aid\ present'
Assert-DirExists (Join-Path $ProjT49 '.codex' 'skills') 'T49-06b (AC5) new .codex\skills\ present'
$T49NewAgents = @(Get-ChildItem -LiteralPath (Join-Path $ProjT49 '.codex' 'agents') `
    -Filter 'aid-*.toml' -File -ErrorAction SilentlyContinue)
Assert ($T49NewAgents.Count -gt 0) `
    'T49-07 (AC5) .codex\agents\ contains aid-*.toml files from new bundle' `
    '.codex\agents\ should contain aid-*.toml files'

# AC5-c: user-file.txt byte-identical (SHA256).
Assert-FileExists (Join-Path $ProjT49 '.agents' 'user-file.txt') `
    'T49-08a (AC5) user-file.txt still exists under .agents\'
$T49UserHashAfter = (Get-FileHash -LiteralPath (Join-Path $ProjT49 '.agents' 'user-file.txt') `
    -Algorithm SHA256).Hash
Assert-Eq "$T49UserHashAfter" "$T49UserHashBefore" `
    'T49-08b (AC5) user-file.txt SHA256 byte-identical (user content untouched)'

# AC8: tools.codex.version == $Ver (uniform).
$T49ManifestPath = Join-Path $ProjT49 '.aid' '.aid-manifest.json'
Assert-FileExists $T49ManifestPath 'T49-09 (AC8) manifest exists after aid update'
if (Test-Path $T49ManifestPath -PathType Leaf) {
    $T49ManObj = Get-Content -LiteralPath $T49ManifestPath -Raw | ConvertFrom-Json
    $T49Ver = $T49ManObj.tools.codex.version
    Assert-Eq "$T49Ver" "$Ver" 'T49-10 (AC8) tools.codex.version == current version (uniform)'
}
Write-Host ""

# ===========================================================================
# T50: Cursor old-layout fixture (mirrors bash Gate 11)
#
# Fixture: pre-work-005 cursor repo with:
#   .cursor\rules\aid-architect.mdc  (AID content, marker 1: aid- prefix)
#   .cursor\rules\aid-clerk.mdc      (AID content, marker 1: aid- prefix)
#   .cursor\rules\my.mdc             (USER content: no aid- prefix)
#   AGENTS.md with AID:BEGIN..END + user lines outside the region
#
# Asserts (AC5):
#   T50-02  .cursor\rules\aid-architect.mdc GONE
#   T50-03  .cursor\rules\aid-clerk.mdc GONE
#   T50-04  New .cursor\agents\ present
#   T50-05  New .cursor\aid\ present
#   T50-06  .cursor\agents\ contains aid-*.md files
#   T50-07  .cursor\rules\my.mdc exists
#   T50-08  .cursor\rules\my.mdc SHA256 byte-identical
#   T50-09  AGENTS.md exists
#   T50-10  USER-LINE-BEFORE-REGION preserved
#   T50-11  USER-LINE-AFTER-REGION preserved
#   T50-12  AID:BEGIN marker present
#   T50-13  AID:END marker present
# Asserts (AC8):
#   T50-14  manifest exists
#   T50-15  tools.cursor.version == $Ver (uniform)
# ===========================================================================
Write-Host "--- T50: Cursor old-layout migration ---"

$ProjT50 = Join-Path $TmpRoot 'project-t50'
New-Item -ItemType Directory -Path (Join-Path $ProjT50 '.cursor' 'rules') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT50 '.aid') -Force | Out-Null

# AID-owned content under retired .cursor\rules\ (marker 1: aid- prefix).
[System.IO.File]::WriteAllText((Join-Path $ProjT50 '.cursor' 'rules' 'aid-architect.mdc'),
    "old cursor architect rule`n")
[System.IO.File]::WriteAllText((Join-Path $ProjT50 '.cursor' 'rules' 'aid-clerk.mdc'),
    "old cursor clerk rule`n")
# USER content: no AID marker -- must survive byte-identical.
$T50UserContent = "USER-CURSOR-MY-RULE-SENTINEL`n"
[System.IO.File]::WriteAllText((Join-Path $ProjT50 '.cursor' 'rules' 'my.mdc'), $T50UserContent)
$T50UserHashBefore = (Get-FileHash -LiteralPath (Join-Path $ProjT50 '.cursor' 'rules' 'my.mdc') `
    -Algorithm SHA256).Hash

# AGENTS.md: AID:BEGIN..END region + user lines outside it.
$T50AgentsContent = "# AGENTS.md`n`n## My Project Notes`nUSER-LINE-BEFORE-REGION`n`n<!-- AID:BEGIN -->`n## Old AID section (will be replaced by migration)`nThis is old AID content inside the region.`n<!-- AID:END -->`n`n## My Custom Section`nUSER-LINE-AFTER-REGION`n"
[System.IO.File]::WriteAllText((Join-Path $ProjT50 'AGENTS.md'), $T50AgentsContent)

Write-OldManifest -ManifestPath (Join-Path $ProjT50 '.aid' '.aid-manifest.json') -Tool 'cursor'
Write-OldSettings -SettingsPath (Join-Path $ProjT50 '.aid' 'settings.yml') -Tool 'cursor'

Run-MigUpdate -BundleFile $MigFixCursor -TargetRepo $ProjT50
Assert-Eq "$($script:_LastRC)" '0' 'T50-01 aid update on cursor old-layout -> exit 0'

# AC5-a: retired .cursor\rules\ AID-owned files GONE.
Assert (-not (Test-Path (Join-Path $ProjT50 '.cursor' 'rules' 'aid-architect.mdc') -PathType Leaf)) `
    'T50-02 (AC5) .cursor\rules\aid-architect.mdc removed (AID-owned, marker 1)' `
    'aid-architect.mdc must be removed by retired-root sweep'
Assert (-not (Test-Path (Join-Path $ProjT50 '.cursor' 'rules' 'aid-clerk.mdc') -PathType Leaf)) `
    'T50-03 (AC5) .cursor\rules\aid-clerk.mdc removed (AID-owned, marker 1)' `
    'aid-clerk.mdc must be removed by retired-root sweep'

# AC5-b: new .cursor\ unified layout present.
Assert-DirExists (Join-Path $ProjT50 '.cursor' 'agents') 'T50-04 (AC5) new .cursor\agents\ present'
Assert-DirExists (Join-Path $ProjT50 '.cursor' 'aid')    'T50-05 (AC5) new .cursor\aid\ present'
Assert-DirExists (Join-Path $ProjT50 '.cursor' 'skills') 'T50-05b (AC5) new .cursor\skills\ present'
$T50NewAgents = @(Get-ChildItem -LiteralPath (Join-Path $ProjT50 '.cursor' 'agents') `
    -Filter 'aid-*.md' -File -ErrorAction SilentlyContinue)
Assert ($T50NewAgents.Count -gt 0) `
    'T50-06 (AC5) .cursor\agents\ contains aid-*.md files from new bundle' `
    '.cursor\agents\ should contain aid-*.md files'

# AC5-c: user .cursor\rules\my.mdc byte-identical (SHA256).
Assert-FileExists (Join-Path $ProjT50 '.cursor' 'rules' 'my.mdc') `
    'T50-07 (AC5) .cursor\rules\my.mdc (user content) still exists'
$T50UserHashAfter = (Get-FileHash -LiteralPath (Join-Path $ProjT50 '.cursor' 'rules' 'my.mdc') `
    -Algorithm SHA256).Hash
Assert-Eq "$T50UserHashAfter" "$T50UserHashBefore" `
    'T50-08 (AC5) .cursor\rules\my.mdc SHA256 byte-identical (user content untouched)'

# AC5-d: user lines outside AID:BEGIN..END in AGENTS.md preserved.
Assert-FileExists (Join-Path $ProjT50 'AGENTS.md') 'T50-09 (AC5) AGENTS.md still exists'
$T50AgentsAfter = Get-Content -LiteralPath (Join-Path $ProjT50 'AGENTS.md') -Raw -ErrorAction SilentlyContinue
Assert-Contains "$T50AgentsAfter" 'USER-LINE-BEFORE-REGION' 'T50-10 (AC5) AGENTS.md: user line BEFORE region preserved'
Assert-Contains "$T50AgentsAfter" 'USER-LINE-AFTER-REGION'  'T50-11 (AC5) AGENTS.md: user line AFTER region preserved'
Assert-Contains "$T50AgentsAfter" '<!-- AID:BEGIN -->'       'T50-12 (AC5) AGENTS.md: AID:BEGIN marker present after region merge'
Assert-Contains "$T50AgentsAfter" '<!-- AID:END -->'         'T50-13 (AC5) AGENTS.md: AID:END marker present after region merge'

# AC8: tools.cursor.version == $Ver (uniform).
$T50ManifestPath = Join-Path $ProjT50 '.aid' '.aid-manifest.json'
Assert-FileExists $T50ManifestPath 'T50-14 (AC8) manifest exists after aid update'
if (Test-Path $T50ManifestPath -PathType Leaf) {
    $T50ManObj = Get-Content -LiteralPath $T50ManifestPath -Raw | ConvertFrom-Json
    $T50Ver = $T50ManObj.tools.cursor.version
    Assert-Eq "$T50Ver" "$Ver" 'T50-15 (AC8) tools.cursor.version == current version (uniform)'
}
Write-Host ""

# ===========================================================================
# T51: Antigravity old-layout fixture (mirrors bash Gate 12)
#
# Fixture: pre-work-005 antigravity repo with:
#   .agent\rules\aid-architect.md    (AID content, marker 1: aid- prefix)
#   .agent\rules\aid-clerk.md        (AID content, marker 1: aid- prefix)
#   .agent\rules\my-team-rules.md    (USER content: no AID marker)
#   AGENTS.md with AID:BEGIN..END + user lines outside the region
#
# Asserts (AC5):
#   T51-02  .agent\rules\aid-architect.md GONE
#   T51-03  .agent\rules\aid-clerk.md GONE
#   T51-04  New .agent\agents\ present
#   T51-05  New .agent\aid\ present
#   T51-06  .agent\agents\ contains aid-*.md files
#   T51-07  .agent\rules\my-team-rules.md exists
#   T51-08  .agent\rules\my-team-rules.md SHA256 byte-identical
#   T51-09  AGENTS.md: user line BEFORE region preserved
#   T51-10  AGENTS.md: user line AFTER region preserved
#   T51-11  AGENTS.md: AID:BEGIN present
#   T51-12  AGENTS.md: AID:END present
# Asserts (AC8):
#   T51-13  manifest exists
#   T51-14  tools.antigravity.version == $Ver (uniform)
# ===========================================================================
Write-Host "--- T51: Antigravity old-layout migration ---"

$ProjT51 = Join-Path $TmpRoot 'project-t51'
New-Item -ItemType Directory -Path (Join-Path $ProjT51 '.agent' 'rules') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjT51 '.aid') -Force | Out-Null

# AID-owned content under retired .agent\rules\ (marker 1: aid- prefix).
[System.IO.File]::WriteAllText((Join-Path $ProjT51 '.agent' 'rules' 'aid-architect.md'),
    "old antigravity architect rule`n")
[System.IO.File]::WriteAllText((Join-Path $ProjT51 '.agent' 'rules' 'aid-clerk.md'),
    "old antigravity clerk rule`n")
# USER content: no AID marker -- must survive byte-identical.
$T51UserContent = "USER-AGENT-RULES-SENTINEL`n"
[System.IO.File]::WriteAllText((Join-Path $ProjT51 '.agent' 'rules' 'my-team-rules.md'), $T51UserContent)
$T51UserHashBefore = (Get-FileHash -LiteralPath (Join-Path $ProjT51 '.agent' 'rules' 'my-team-rules.md') `
    -Algorithm SHA256).Hash

# AGENTS.md: AID:BEGIN..END region + user content outside.
$T51AgentsContent = "# AGENTS.md`n`nUSER-ANTIGRAVITY-LINE-BEFORE`n`n<!-- AID:BEGIN -->`n## Old AID agents section`nSome old AID content.`n<!-- AID:END -->`n`nUSER-ANTIGRAVITY-LINE-AFTER`n"
[System.IO.File]::WriteAllText((Join-Path $ProjT51 'AGENTS.md'), $T51AgentsContent)

Write-OldManifest -ManifestPath (Join-Path $ProjT51 '.aid' '.aid-manifest.json') -Tool 'antigravity'
Write-OldSettings -SettingsPath (Join-Path $ProjT51 '.aid' 'settings.yml') -Tool 'antigravity'

Run-MigUpdate -BundleFile $MigFixAntigrav -TargetRepo $ProjT51
Assert-Eq "$($script:_LastRC)" '0' 'T51-01 aid update on antigravity old-layout -> exit 0'

# AC5-a: retired .agent\rules\ AID-owned files GONE.
Assert (-not (Test-Path (Join-Path $ProjT51 '.agent' 'rules' 'aid-architect.md') -PathType Leaf)) `
    'T51-02 (AC5) .agent\rules\aid-architect.md removed (AID-owned, marker 1)' `
    'aid-architect.md must be removed by retired-root sweep'
Assert (-not (Test-Path (Join-Path $ProjT51 '.agent' 'rules' 'aid-clerk.md') -PathType Leaf)) `
    'T51-03 (AC5) .agent\rules\aid-clerk.md removed (AID-owned, marker 1)' `
    'aid-clerk.md must be removed by retired-root sweep'

# AC5-b: new .agent\ unified layout present.
Assert-DirExists (Join-Path $ProjT51 '.agent' 'agents') 'T51-04 (AC5) new .agent\agents\ present'
Assert-DirExists (Join-Path $ProjT51 '.agent' 'aid')    'T51-05 (AC5) new .agent\aid\ present'
Assert-DirExists (Join-Path $ProjT51 '.agent' 'skills') 'T51-05b (AC5) new .agent\skills\ present'
$T51NewAgents = @(Get-ChildItem -LiteralPath (Join-Path $ProjT51 '.agent' 'agents') `
    -Filter 'aid-*.md' -File -ErrorAction SilentlyContinue)
Assert ($T51NewAgents.Count -gt 0) `
    'T51-06 (AC5) .agent\agents\ contains aid-*.md files from new bundle' `
    '.agent\agents\ should contain aid-*.md files'

# AC5-c: user .agent\rules\my-team-rules.md byte-identical (SHA256).
Assert-FileExists (Join-Path $ProjT51 '.agent' 'rules' 'my-team-rules.md') `
    'T51-07 (AC5) .agent\rules\my-team-rules.md (user content) still exists'
$T51UserHashAfter = (Get-FileHash -LiteralPath (Join-Path $ProjT51 '.agent' 'rules' 'my-team-rules.md') `
    -Algorithm SHA256).Hash
Assert-Eq "$T51UserHashAfter" "$T51UserHashBefore" `
    'T51-08 (AC5) .agent\rules\my-team-rules.md SHA256 byte-identical (user content untouched)'

# AC5-d: user lines outside AGENTS.md region preserved.
$T51AgentsAfter = Get-Content -LiteralPath (Join-Path $ProjT51 'AGENTS.md') -Raw -ErrorAction SilentlyContinue
Assert-Contains "$T51AgentsAfter" 'USER-ANTIGRAVITY-LINE-BEFORE' 'T51-09 (AC5) AGENTS.md: user line BEFORE region preserved'
Assert-Contains "$T51AgentsAfter" 'USER-ANTIGRAVITY-LINE-AFTER'  'T51-10 (AC5) AGENTS.md: user line AFTER region preserved'
Assert-Contains "$T51AgentsAfter" '<!-- AID:BEGIN -->'             'T51-11 (AC5) AGENTS.md: AID:BEGIN marker present'
Assert-Contains "$T51AgentsAfter" '<!-- AID:END -->'               'T51-12 (AC5) AGENTS.md: AID:END marker present'

# AC8: tools.antigravity.version == $Ver (uniform).
$T51ManifestPath = Join-Path $ProjT51 '.aid' '.aid-manifest.json'
Assert-FileExists $T51ManifestPath 'T51-13 (AC8) manifest exists after aid update'
if (Test-Path $T51ManifestPath -PathType Leaf) {
    $T51ManObj = Get-Content -LiteralPath $T51ManifestPath -Raw | ConvertFrom-Json
    $T51Ver = $T51ManObj.tools.antigravity.version
    Assert-Eq "$T51Ver" "$Ver" 'T51-14 (AC8) tools.antigravity.version == current version (uniform)'
}
Write-Host ""

# ===========================================================================
# T52: Idempotency -- second aid update on migrated old-layout repo (mirrors bash Gate 13)
#
# Reuses the T49 (codex) project fixture post-migration: run aid update a second
# time and assert that sha256 of relevant files is unchanged.
#
# Asserts:
#   T52-01  second aid update -> exit 0
#   T52-02  .agents\skills\ remains absent (no resurrection)
#   T52-03  tools.codex.version still == $Ver
#   T52-04  new-layout witness file sha256 unchanged
#   T52-05  user-file.txt SHA256 still byte-identical
# ===========================================================================
Write-Host "--- T52: Idempotency -- second aid update on migrated old-layout (codex) ---"

# Snapshot manifest and witness file sha256 before the second run.
$T52ManifestSha1 = if (Test-Path (Join-Path $ProjT49 '.aid' '.aid-manifest.json') -PathType Leaf) {
    (Get-FileHash -LiteralPath (Join-Path $ProjT49 '.aid' '.aid-manifest.json') -Algorithm SHA256).Hash
} else { '' }

$T52WitnessFile = $null
$T52WitnessSha1 = ''
$T52CandidateAgents = @(Get-ChildItem -LiteralPath (Join-Path $ProjT49 '.codex' 'agents') `
    -Filter 'aid-*.toml' -File -ErrorAction SilentlyContinue | Sort-Object Name)
if ($T52CandidateAgents.Count -gt 0) {
    $T52WitnessFile = $T52CandidateAgents[0].FullName
    $T52WitnessSha1 = (Get-FileHash -LiteralPath $T52WitnessFile -Algorithm SHA256).Hash
}

# Run second aid update (same bundle, same target).
Run-MigUpdate -BundleFile $MigFixCodex -TargetRepo $ProjT49
Assert-Eq "$($script:_LastRC)" '0' 'T52-01 second aid update on migrated codex repo -> exit 0'

# .agents\skills\ must remain absent (no resurrection).
Assert (-not (Test-Path (Join-Path $ProjT49 '.agents' 'skills') -PathType Container)) `
    'T52-02 .agents\skills\ remains absent after second update (idempotent, no resurrection)' `
    '.agents\skills\ must not reappear after second update'

# tools.codex.version still == $Ver.
if (Test-Path (Join-Path $ProjT49 '.aid' '.aid-manifest.json') -PathType Leaf) {
    $T52ManObj = Get-Content -LiteralPath (Join-Path $ProjT49 '.aid' '.aid-manifest.json') -Raw | ConvertFrom-Json
    Assert-Eq "$($T52ManObj.tools.codex.version)" "$Ver" `
        'T52-03 tools.codex.version still correct after second update (idempotent)'
}

# New-layout witness file sha256 unchanged (files are up-to-date, no re-copy).
if ($T52WitnessFile -and $T52WitnessSha1) {
    $T52WitnessSha2 = (Get-FileHash -LiteralPath $T52WitnessFile -Algorithm SHA256).Hash
    Assert-Eq "$T52WitnessSha2" "$T52WitnessSha1" `
        'T52-04 new-layout witness file sha256 unchanged after second update (idempotent)'
} else {
    # T49-07 would have caught a missing agent file; skip here.
    script:RecordPass 'T52-04 new-layout witness file check skipped (no agent file -- T49-07 would catch)'
}

# User-file.txt SHA256 still byte-identical after second update.
Assert-FileExists (Join-Path $ProjT49 '.agents' 'user-file.txt') `
    'T52-05a user-file.txt still exists after second update'
if (Test-Path (Join-Path $ProjT49 '.agents' 'user-file.txt') -PathType Leaf) {
    $T52UserHashAfter2 = (Get-FileHash -LiteralPath (Join-Path $ProjT49 '.agents' 'user-file.txt') `
        -Algorithm SHA256).Hash
    Assert-Eq "$T52UserHashAfter2" "$T49UserHashBefore" `
        'T52-05b user-file.txt SHA256 still byte-identical after second update (user content untouched)'
}
Write-Host ""

# ===========================================================================
# T53: Escape canary -- real USERPROFILE/HOME untouched by T49-T52 fixture runs
#
# Confirms that every Run-MigUpdate call (which uses Run-AidPs1Home) properly
# isolated $HOME / $env:USERPROFILE to the MigFakeHome throwaway, and the real
# user home gained no new .aid directories during the fixture runs above.
# ===========================================================================
Write-Host "--- T53: Escape canary -- real HOME/USERPROFILE untouched ---"

$_T53_CANARY_AFTER = ''
if ($_T49_REAL_UP -and (Test-Path $_T49_REAL_UP -PathType Container)) {
    try {
        $items = @(Get-ChildItem -LiteralPath $_T49_REAL_UP -Recurse -Depth 6 `
            -Filter '.aid' -Directory -ErrorAction SilentlyContinue)
        $_T53_CANARY_AFTER = ($items | ForEach-Object { $_.FullName } | Sort-Object) -join "`n"
    } catch { $_T53_CANARY_AFTER = '' }
}

Assert ($_T53_CANARY_AFTER -eq $_T49_CANARY_BEFORE) `
    'T53 escape canary: real USERPROFILE/HOME gained no .aid dirs during T49-T52 fixture runs' `
    "real HOME blast surface: new .aid dirs appeared under $_T49_REAL_UP during migration test runs"

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
