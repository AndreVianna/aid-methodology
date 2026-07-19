# Test-InstallProvisioning.ps1 — focused parity tests for the work-007 installer
# behaviors in lib/AidInstallCore.psm1 (PowerShell twin of
# tests/canonical/test-install-provisioning.sh). Sources the module directly and
# exercises the three changed behaviors in module scope — no tarball, fast:
#
#   1. Copy-AidFile overwrite-on-diff (AID-owned files always track the bundle)
#   2. Initialize-AidSettingsFile     (seed-if-missing; never clobber user config)
#   3. Update-AidGitignore            (create/append/update AID region; idempotent)
#
# Exit: 0 all pass / 1 any fail.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$psm = Join-Path $repoRoot (Join-Path 'lib' 'AidInstallCore.psm1')

# Parse check
$tokens = $null; $perrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($psm, [ref]$tokens, [ref]$perrors) | Out-Null
if ($perrors.Count -gt 0) { $perrors | ForEach-Object { Write-Host "PARSE ERROR: $_" }; exit 1 }
Write-Host "parse: OK"

$mod = Import-Module $psm -PassThru -Force
$tmp = Join-Path $env:TEMP ("aidprov_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$fails = 0
function Check($name, $cond) {
    if ($cond) { Write-Host "  PASS: $name" }
    else { Write-Host "  FAIL: $name"; $script:fails++ }
}

$results = & $mod {
    param($tmp)
    $out = [System.Collections.Generic.List[object]]::new()
    function rec($n, $c) { $out.Add([pscustomobject]@{ name = $n; cond = [bool]$c }) }
    $script:ci = 0
    function newd([string]$base) { $script:ci++; $d = Join-Path $base "d$($script:ci)"; New-Item -ItemType Directory -Path $d -Force | Out-Null; return $d }

    # CP2: differing dst, force=$false -> overwritten (skip-on-diff removed)
    $d = newd $tmp
    Set-Content -LiteralPath "$d\src" -Value "new" -NoNewline
    Set-Content -LiteralPath "$d\dst" -Value "old" -NoNewline
    $script:_CopyCountUpdated = 0; $script:_CopyCountSkipped = 0
    Copy-AidFile -Src "$d\src" -Dst "$d\dst" -Force $false
    rec "CP2 differing dst overwritten w/o -Force" ((Get-Content -LiteralPath "$d\dst" -Raw) -eq "new")
    rec "CP2b UPDATED counter" ($script:_CopyCountUpdated -eq 1)
    rec "CP2c nothing skipped" ($script:_CopyCountSkipped -eq 0)

    # CP3: identical -> up to date, not rewritten
    $d = newd $tmp
    Set-Content -LiteralPath "$d\src" -Value "same" -NoNewline
    Set-Content -LiteralPath "$d\dst" -Value "same" -NoNewline
    $script:_CopyCountUpToDate = 0; $script:_CopyCountUpdated = 0
    Copy-AidFile -Src "$d\src" -Dst "$d\dst" -Force $false
    rec "CP3 identical up-to-date" ($script:_CopyCountUpToDate -eq 1 -and $script:_CopyCountUpdated -eq 0)

    # SE1: seed settings when missing
    $t = newd $tmp
    New-Item -ItemType Directory -Path "$t\.claude\aid\templates" -Force | Out-Null
    Set-Content -LiteralPath "$t\.claude\aid\templates\settings.yml" -Value "project:`n  name: <project-name>`n"
    script:Initialize-AidSettingsFile -Target $t -Tool 'claude-code'
    rec "SE1 settings seeded" (Test-Path "$t\.aid\settings.yml")
    rec "SE1b seeded flag" ($script:_SeededSettings -eq $true)
    $se1 = Get-Content -LiteralPath "$t\.aid\settings.yml" -Raw
    rec "SE1c seeded from template" ($se1 -match '<project-name>')
    rec "SE1d format_version stamped" ($se1 -match '(?m)^format_version: 3')
    rec "SE1e format_version first line" (((Get-Content -LiteralPath "$t\.aid\settings.yml" -TotalCount 1)) -eq 'format_version: 3')

    # SE2: never clobber existing user config
    $t = newd $tmp
    New-Item -ItemType Directory -Path "$t\.claude\aid\templates" -Force | Out-Null
    Set-Content -LiteralPath "$t\.claude\aid\templates\settings.yml" -Value "project:`n  name: <project-name>`n"
    New-Item -ItemType Directory -Path "$t\.aid" -Force | Out-Null
    Set-Content -LiteralPath "$t\.aid\settings.yml" -Value "project:`n  name: MyRealProject`n"
    script:Initialize-AidSettingsFile -Target $t -Tool 'claude-code'
    $c = Get-Content -LiteralPath "$t\.aid\settings.yml" -Raw
    rec "SE2 user config preserved" ($c -match 'MyRealProject')
    rec "SE2b no clobber" ($c -notmatch '<project-name>')
    rec "SE2c flag not set" ($script:_SeededSettings -eq $false)

    # GI1: create with AID region + patterns
    $t = newd $tmp
    script:Update-AidGitignore -Target $t
    $gi = Get-Content -LiteralPath "$t\.gitignore" -Raw
    rec "GI1 created" (Test-Path "$t\.gitignore")
    rec "GI1b action=created" ($script:_GitignoreAction -eq 'created')
    rec "GI1c has temp" ($gi -match [regex]::Escape('.aid/.temp/'))
    rec "GI1d has cache" ($gi -match [regex]::Escape('.aid/knowledge/.cache/'))

    # GI2: idempotent
    $snap = Get-Content -LiteralPath "$t\.gitignore" -Raw
    script:Update-AidGitignore -Target $t
    rec "GI2 action=unchanged" ($script:_GitignoreAction -eq 'unchanged')
    rec "GI2b byte-identical" ((Get-Content -LiteralPath "$t\.gitignore" -Raw) -eq $snap)

    # GI3: preserve user content, append region
    $t = newd $tmp
    Set-Content -LiteralPath "$t\.gitignore" -Value "# my rules`nnode_modules/`n*.log`n"
    script:Update-AidGitignore -Target $t
    $gi = Get-Content -LiteralPath "$t\.gitignore" -Raw
    rec "GI3 user preserved" ($gi -match 'node_modules/')
    rec "GI3b region appended" ($gi -match [regex]::Escape('.aid/.temp/'))
    rec "GI3c action=updated" ($script:_GitignoreAction -eq 'updated')

    # GI4: stale region replaced in place, user content untouched, single region
    $t = newd $tmp
    $stale = "# top`nbuild/`n`n# >>> AID managed -- do not edit (aid add/update maintains this block) >>>`n.aid/OLD-STALE/`n# <<< AID managed <<<`n`ndist/`n"
    Set-Content -LiteralPath "$t\.gitignore" -Value $stale
    script:Update-AidGitignore -Target $t
    $gi = Get-Content -LiteralPath "$t\.gitignore" -Raw
    rec "GI4 stale removed" ($gi -notmatch 'OLD-STALE')
    rec "GI4b current present" ($gi -match [regex]::Escape('.aid/.heartbeat/'))
    rec "GI4c top preserved" ($gi -match 'build/')
    rec "GI4d bottom preserved" ($gi -match 'dist/')
    rec "GI4e one region" ((([regex]::Matches($gi, 'AID managed -- do not edit')).Count) -eq 1)

    # GI5: CRLF file -> second run unchanged, bytes preserved (C3 idempotency)
    $t = newd $tmp
    [System.IO.File]::WriteAllText("$t\.gitignore", "# user`r`nnode_modules/`r`n")
    script:Update-AidGitignore -Target $t
    $snapBytes = [System.IO.File]::ReadAllBytes("$t\.gitignore")
    script:Update-AidGitignore -Target $t
    rec "GI5 CRLF second run unchanged" ($script:_GitignoreAction -eq 'unchanged')
    $nowBytes = [System.IO.File]::ReadAllBytes("$t\.gitignore")
    rec "GI5b CRLF bytes preserved" (@(Compare-Object $snapBytes $nowBytes -SyncWindow 0).Count -eq 0)

    # C1: C2 migration must NOT duplicate ## Workflow
    $d = newd $tmp
    $src = "# CLAUDE.md`n<!-- AID:BEGIN -->`n## Tracking discipline`ntrack`n## Knowledge Base`nkb`n## Workflow`nnew workflow`n## Review output format`nrev`n## Permissions`nperms`n<!-- AID:END -->`n"
    [System.IO.File]::WriteAllText("$d\src.md", $src)
    $dst = "# CLAUDE.md`n## Project`nmy project`n## Workflow`nold workflow`n## Permissions`nold perms`n"
    [System.IO.File]::WriteAllText("$d\dst.md", $dst)
    script:Copy-RootAgentFile -Src "$d\src.md" -Dst "$d\dst.md" -Tool 'claude-code' -Force $false | Out-Null
    $res = Get-Content -LiteralPath "$d\dst.md" -Raw
    rec "C1 exactly one ## Workflow (no duplicate)" ((([regex]::Matches($res, '(?m)^## Workflow')).Count) -eq 1)
    rec "C1b user ## Project preserved" ($res -match 'my project')
    rec "C1c region markers inserted" ($res -match '<!-- AID:BEGIN -->')

    # CONN: is_aid_heading (Test-AidHeadingStem) recognizes ## Connectors
    # (task-003); C2 migration must NOT duplicate it (mirrors C1 above;
    # task-004 adds this heading to the shipped managed region).
    $d = newd $tmp
    $srcConn = "# CLAUDE.md`n<!-- AID:BEGIN -->`n## Tracking discipline`ntrack`n## Knowledge Base`nkb`n## Connectors`nnew connectors`n## Workflow`nnew workflow`n## Review output format`nrev`n## Permissions`nperms`n<!-- AID:END -->`n"
    [System.IO.File]::WriteAllText("$d\src.md", $srcConn)
    $dstConn = "# CLAUDE.md`n## Project`nmy project`n## Connectors`nold connectors`n## Permissions`nold perms`n"
    [System.IO.File]::WriteAllText("$d\dst.md", $dstConn)
    script:Copy-RootAgentFile -Src "$d\src.md" -Dst "$d\dst.md" -Tool 'claude-code' -Force $false | Out-Null
    $resConn = Get-Content -LiteralPath "$d\dst.md" -Raw
    rec "CONN1 exactly one ## Connectors (no duplicate)" ((([regex]::Matches($resConn, '(?m)^## Connectors')).Count) -eq 1)
    rec "CONN1b user ## Project preserved" ($resConn -match 'my project')
    rec "CONN1c region markers inserted" ($resConn -match '<!-- AID:BEGIN -->')

    return $out
} $tmp

foreach ($r in $results) { Check $r.name $r.cond }
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
if ($fails -gt 0) { Write-Host "Tests failed: $fails"; exit 1 } else { Write-Host "All PS provisioning tests passed."; exit 0 }
