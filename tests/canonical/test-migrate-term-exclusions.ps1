# test-migrate-term-exclusions.ps1 -- PowerShell-twin coverage for the work-014
# term-exclusions migration (Invoke-MigrateTermExclusions in lib/AidInstallCore.psm1).
# Invoked by test-migrate-term-exclusions-ps1.sh (which gates on pwsh availability).
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mod = Import-Module (Join-Path $repo 'lib\AidInstallCore.psm1') -Force -PassThru 3>$null

$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Output "  PASS: $name" } else { Write-Output "  FAIL: $name"; $script:fail++ }
}
function New-TxFixture([bool]$withFile) {
    $t = Join-Path ([System.IO.Path]::GetTempPath()) ('mtx-' + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $t '.aid\knowledge') -Force | Out-Null
    Set-Content -Path (Join-Path $t '.aid\settings.yml') -Value "discovery:`n  closure:`n    max_rounds: 4`n  doc_set:`n    - README.md|skill-self|required`n" -NoNewline
    if ($withFile) {
        Set-Content -Path (Join-Path $t '.aid\knowledge\.term-exclusions.md') -Value "# Term exclusions`n`n- In Progress`n- dry-run`n" -NoNewline
    }
    return $t
}

# MTP01: file present -> inject under discovery + retire
$t1 = New-TxFixture $true
& $mod { param($p) script:Invoke-MigrateTermExclusions -Target $p } $t1 6>$null | Out-Null
$s1 = Get-Content (Join-Path $t1 '.aid\settings.yml') -Raw
Check 'MTP01a term_exclusions key injected' ($s1 -match '(?m)^  term_exclusions:')
Check 'MTP01b term with spaces preserved'  ($s1 -match '(?m)^    - In Progress$')
Check 'MTP01c old file retired to .trash'  (Test-Path (Join-Path $t1 '.aid\.trash\knowledge\.term-exclusions.md'))
Check 'MTP01d original file removed'        (-not (Test-Path (Join-Path $t1 '.aid\knowledge\.term-exclusions.md')))

# MTP02: file absent -> gate no-ops, settings untouched
$t2 = New-TxFixture $false
$before = Get-Content (Join-Path $t2 '.aid\settings.yml') -Raw
& $mod { param($p) script:Invoke-MigrateTermExclusions -Target $p } $t2 6>$null | Out-Null
$after = Get-Content (Join-Path $t2 '.aid\settings.yml') -Raw
Check 'MTP02a settings unchanged (gate)'   ($before -eq $after)
Check 'MTP02b no term_exclusions injected' (-not ($after -match 'term_exclusions'))

Remove-Item $t1, $t2 -Recurse -Force -ErrorAction SilentlyContinue

Write-Output '=== Summary ==='
if ($fail -gt 0) { Write-Output "  Tests failed: $fail"; exit 1 }
Write-Output '  Tests passed: 6'
Write-Output '  Tests failed: 0'
Write-Output 'All tests passed.'
