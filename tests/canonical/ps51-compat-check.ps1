# ps51-compat-check.ps1 - AST-based Windows PowerShell 5.1 compatibility lint.
#
# The shipped AID PowerShell (install.ps1, bin/aid.ps1, lib/AidInstallCore.psm1)
# declares "#Requires -Version 5.1" and the docs advertise "PowerShell 5.1+".
# This lint parses each file's AST and fails (exit 1) on any 6.0/7-only construct
# that would break or misbehave on Windows PowerShell 5.1.
#
# Catches the classes PSScriptAnalyzer's PSUseCompatible* rules MISS:
#   - 3-argument Join-Path (-AdditionalChildPath is 6+)
#   - 7-only -Encoding names on write cmdlets (utf8NoBOM / utf8BOM / ansi / oem)
#   - Split-Path -LeafBase / -Extension (6+)
#   - ConvertFrom-Json -AsHashtable / -Depth (6+)
#   - ForEach-Object -Parallel (7)
#   - cmdlets absent in 5.1 (Start-ThreadJob, Get-Error, Test-Json, Join-String, ConvertFrom-Markdown)
#   - 7-only Invoke-WebRequest/RestMethod params (-SkipCertificateCheck/-Authentication/-SslProtocol/...)
#   - ternary / null-coalescing / null-conditional / pipeline-chain operators
#   - $IsWindows/$IsLinux/$IsMacOS/$IsCoreCLR/$PSStyle (do not exist in 5.1; throw under StrictMode)
#   - a file that does web calls but never sets TLS 1.2 (5.1 default rejects modern HTTPS)
#
# Usage:  pwsh -NoProfile -File ps51-compat-check.ps1 <repo-root>
# Exit:   0 = clean, 1 = incompatibilities found (printed).

param([string]$RepoRoot = '.')

$ErrorActionPreference = 'Stop'
$files = @('install.ps1', 'bin/aid.ps1', 'lib/AidInstallCore.psm1')
# Connector PowerShell twins (work-002) ship under canonical/aid/scripts/connectors/ and must
# stay Windows PowerShell 5.1-compatible; glob the directory so every connector twin -- and any
# future one added there -- is guarded automatically, not just a hardcoded list.
$connectorsDir = Join-Path $RepoRoot 'canonical/aid/scripts/connectors'
if (Test-Path $connectorsDir) {
    Get-ChildItem -Path $connectorsDir -Filter '*.ps1' -ErrorAction SilentlyContinue |
        Sort-Object Name |
        ForEach-Object { $files += ('canonical/aid/scripts/connectors/' + $_.Name) }
}
$bad7enc   = @('utf8NoBOM', 'utf8BOM', 'ansi', 'oem')
$absent51  = @('Start-ThreadJob', 'Get-Error', 'Test-Json', 'Join-String', 'ConvertFrom-Markdown')
$web7param = @('SkipCertificateCheck', 'Authentication', 'SslProtocol', 'SkipHeaderValidation', 'MaximumRetryCount', 'RetryIntervalSec')
$findings  = New-Object System.Collections.Generic.List[string]

function Add-Finding($file, $line, $msg) { $findings.Add(("  {0}:{1}  {2}" -f $file, $line, $msg)) }

foreach ($rel in $files) {
    $path = Join-Path $RepoRoot $rel
    if (-not (Test-Path $path)) { $findings.Add("  MISSING FILE: $rel"); continue }
    $tok = $null; $err = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path), [ref]$tok, [ref]$err)

    $hasWeb = $false
    $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object {
        $name = $_.GetCommandName(); if (-not $name) { return }
        $ln = $_.Extent.StartLineNumber
        $els = $_.CommandElements
        $named = ($els | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] }).Count
        $pos = $els.Count - 1 - $named
        $params = $els | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] }

        if ($name -eq 'Join-Path' -and $pos -ge 3) { Add-Finding $rel $ln "3-arg Join-Path (use nested 'Join-Path (Join-Path a b) c')" }
        if ($name -eq 'Split-Path') { foreach ($p in $params) { if ($p.ParameterName -in 'LeafBase', 'Extension') { Add-Finding $rel $ln "Split-Path -$($p.ParameterName) (6+)" } } }
        if ($name -in 'Set-Content', 'Add-Content', 'Out-File', 'Export-Csv') {
            for ($i = 0; $i -lt $els.Count; $i++) {
                if ($els[$i] -is [System.Management.Automation.Language.CommandParameterAst] -and $els[$i].ParameterName -eq 'Encoding') {
                    $v = if ($els[$i].Argument) { $els[$i].Argument.Extent.Text } elseif ($i + 1 -lt $els.Count) { $els[$i + 1].Extent.Text } else { '' }
                    if ($bad7enc -contains ($v -replace "['""]", "")) { Add-Finding $rel $ln "7-only -Encoding $v (use [IO.File]::WriteAllText + UTF8Encoding(`$false))" }
                }
            }
        }
        if ($name -eq 'ConvertFrom-Json') { foreach ($p in $params) { if ($p.ParameterName -in 'AsHashtable', 'Depth') { Add-Finding $rel $ln "ConvertFrom-Json -$($p.ParameterName) (6+)" } } }
        if ($name -in 'ForEach-Object', '%') { foreach ($p in $params) { if ($p.ParameterName -eq 'Parallel') { Add-Finding $rel $ln "ForEach-Object -Parallel (7)" } } }
        if ($absent51 -contains $name) { Add-Finding $rel $ln "cmdlet '$name' absent in 5.1" }
        if ($name -in 'Invoke-WebRequest', 'Invoke-RestMethod') {
            $hasWeb = $true
            foreach ($p in $params) { if ($web7param -contains $p.ParameterName) { Add-Finding $rel $ln "7-only web param -$($p.ParameterName)" } }
        }
    }

    $ast.FindAll({ param($n) $n.GetType().Name -in 'TernaryExpressionAst', 'PipelineChainAst' }, $true) | ForEach-Object {
        Add-Finding $rel $_.Extent.StartLineNumber "$($_.GetType().Name -replace 'Ast$','') operator (7)"
    }
    ($tok | Where-Object { $_.Kind -in 'QuestionQuestion', 'QuestionDot', 'AndAnd', 'OrOr' }) | ForEach-Object {
        Add-Finding $rel $_.Extent.StartLineNumber "operator token '$($_.Kind)' (7)"
    }
    $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -in 'IsWindows', 'IsLinux', 'IsMacOS', 'IsCoreCLR', 'PSStyle' }, $true) | ForEach-Object {
        Add-Finding $rel $_.Extent.StartLineNumber "auto-var `$$($_.VariablePath.UserPath) (does not exist in 5.1; throws under StrictMode)"
    }

    if ($hasWeb) {
        $raw = Get-Content -Raw -LiteralPath (Resolve-Path $path)
        if ($raw -notmatch 'Tls12') { Add-Finding $rel 0 "file makes web calls but never sets TLS 1.2 (5.1 default rejects modern HTTPS)" }
    }
}

if ($findings.Count -gt 0) {
    Write-Output "WinPS 5.1 incompatibilities found ($($findings.Count)):"
    $findings | ForEach-Object { Write-Output $_ }
    exit 1
}
Write-Output "OK: shipped PowerShell is Windows PowerShell 5.1-compatible (AST lint, 0 findings)"
exit 0
