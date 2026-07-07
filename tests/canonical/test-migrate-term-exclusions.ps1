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

# MTP03 (Copilot #125): discovery: header with a trailing comment
$t3 = Join-Path ([System.IO.Path]::GetTempPath()) ('mtx-' + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $t3 '.aid\knowledge') -Force | Out-Null
Set-Content -Path (Join-Path $t3 '.aid\settings.yml') -Value "discovery: # runtime-written keys`n  closure:`n    max_rounds: 4`n" -NoNewline
Set-Content -Path (Join-Path $t3 '.aid\knowledge\.term-exclusions.md') -Value "- In Progress`n- dry-run`n" -NoNewline
& $mod { param($p) script:Invoke-MigrateTermExclusions -Target $p } $t3 6>$null | Out-Null
$s3 = Get-Content (Join-Path $t3 '.aid\settings.yml') -Raw
Check 'MTP03a single discovery: header (no EOF duplicate)' (([regex]::Matches($s3, '(?m)^discovery:')).Count -eq 1)
Check 'MTP03b term_exclusions injected under commented discovery:' ($s3 -match '(?m)^  term_exclusions:')

# MTP04 (Copilot #125): term_exclusions under ANOTHER section must not cause a false skip
$t4 = Join-Path ([System.IO.Path]::GetTempPath()) ('mtx-' + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $t4 '.aid\knowledge') -Force | Out-Null
Set-Content -Path (Join-Path $t4 '.aid\settings.yml') -Value "other:`n  term_exclusions:`n    - unrelated`ndiscovery:`n  closure:`n    max_rounds: 4`n" -NoNewline
Set-Content -Path (Join-Path $t4 '.aid\knowledge\.term-exclusions.md') -Value "- In Progress`n" -NoNewline
& $mod { param($p) script:Invoke-MigrateTermExclusions -Target $p } $t4 6>$null | Out-Null
$s4 = Get-Content (Join-Path $t4 '.aid\settings.yml') -Raw
Check 'MTP04a discovery.term_exclusions injected despite other.term_exclusions' ($s4 -match '(?m)^    - In Progress$')
Check 'MTP04b both sections keep a term_exclusions' (([regex]::Matches($s4, '(?m)^  term_exclusions:')).Count -eq 2)
Check 'MTP04c file retired (terms safely placed)' (Test-Path (Join-Path $t4 '.aid\.trash\knowledge\.term-exclusions.md'))

# MTP05 (Copilot #125): terms present but no settings.yml -> preserve file, do not retire
$t5 = Join-Path ([System.IO.Path]::GetTempPath()) ('mtx-' + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $t5 '.aid\knowledge') -Force | Out-Null
Set-Content -Path (Join-Path $t5 '.aid\knowledge\.term-exclusions.md') -Value "- In Progress`n" -NoNewline
& $mod { param($p) script:Invoke-MigrateTermExclusions -Target $p } $t5 6>$null | Out-Null
Check 'MTP05a file preserved when settings.yml absent' (Test-Path (Join-Path $t5 '.aid\knowledge\.term-exclusions.md'))
Check 'MTP05b nothing moved to trash' (-not (Test-Path (Join-Path $t5 '.aid\.trash\knowledge\.term-exclusions.md')))

Remove-Item $t1, $t2, $t3, $t4, $t5 -Recurse -Force -ErrorAction SilentlyContinue

Write-Output '=== Summary ==='
if ($fail -gt 0) { Write-Output "  Tests failed: $fail"; exit 1 }
Write-Output '  Tests passed: 13'
Write-Output '  Tests failed: 0'
Write-Output 'All tests passed.'
