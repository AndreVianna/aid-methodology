#!/usr/bin/env pwsh
# pwsh-exitcode-probe.ps1 -- task-015 spike driver (work-024 delivery-003,
# feature-004 "DETAIL's first gate", SPEC Risk R4). GATES tasks 016/017/018.
#
# Purpose:
#   Re-verify -- with a committed, reproducible probe, BEFORE the responder is
#   built -- the single most pwsh-version-sensitive behavior pwsh-responder.ps1
#   rests on: running a script in a FRESH child runspace in FILE mode via
#     [powershell]::Create().AddScript("& '<abs-path>' @args").Invoke()
#   (a) sets $PSCommandPath / $MyInvocation.MyCommand.Path in the child
#       (=> bin/aid.ps1 _PipedMode=false, AID_CODE_HOME self-locates, side-
#       stepping the deferred PS028-S piped-mode limitation, NO product change),
#   (b) lets the PARENT process survive the child's `exit`, and
#   (c) makes the child exit code recoverable from the child runspace via
#       $ps.Runspace.SessionStateProxy.PSVariable.GetValue('LASTEXITCODE').
#
# Usage:
#   pwsh -NoProfile -File tests/lib/pwsh-exitcode-probe.ps1
#
# Exit codes: 0 = GREEN (all three properties hold -> task-016 uses the
#   $LASTEXITCODE session-proxy read); 1 = RED (a property failed -> fall back
#   per the task-015 recommendation: custom-PSHost SetShouldExit, else the
#   transparent cold-start fallback for that host).
#
# NOT a glob-discovered test-*.sh canonical suite. ASCII-only + LF. In-box only.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Fail = 0
function Confirm-Property {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { Write-Output "PASS: $Label" }
    else { Write-Output "FAIL: $Label"; $script:Fail++ }
}

$childPath = Join-Path $PSScriptRoot 'pwsh-exitcode-probe-child.ps1'
Write-Output "pwsh version : $($PSVersionTable.PSVersion)"
Write-Output "platform     : $([System.Environment]::OSVersion.Platform)"
Write-Output "child        : $childPath"

# Invoke the child EXACTLY the way pwsh-responder.ps1 will: fresh child runspace,
# FILE mode `& '<path>' @args`, args supplied via AddArgument (populates $args).
$ps = [powershell]::Create()
[void]$ps.AddScript("& '" + ($childPath -replace "'", "''") + "' @args")
[void]$ps.AddArgument('probe-arg-1')
[void]$ps.AddArgument('probe arg 2 with spaces')
$out = $ps.Invoke()
$rc = $ps.Runspace.SessionStateProxy.PSVariable.GetValue('LASTEXITCODE')
$text = ($out -join "`n")
$ps.Dispose()

Write-Output "--- child output ---"
Write-Output $text
Write-Output "--- assertions ---"

# (i) self-location automatic variables are non-empty inside the child.
Confirm-Property ($text -match 'PSCommandPath=\[[^\]]+\]') `
    "(i) child `$PSCommandPath is non-empty (FILE mode => _PipedMode=false => AID_CODE_HOME self-locates)"
Confirm-Property ($text -match 'MyInvocationPath=\[[^\]]+\]') `
    "(i) child `$MyInvocation.MyCommand.Path is non-empty"

# (iii) the child exit code is recoverable via the session-proxy $LASTEXITCODE.
Confirm-Property ($rc -eq 3) "(iii) recovered `$LASTEXITCODE == 3 (got '$rc')"

# args (incl. spaces) survive the @args splat.
Confirm-Property ($text -match 'probe arg 2 with spaces') `
    "extra: args with spaces survive the @args splat"

# (ii) the parent process survived the child 'exit 3' -- reaching this line proves it.
Confirm-Property $true "(ii) parent process survived the child 'exit 3'"

if ($script:Fail -eq 0) {
    Write-Output "SPIKE RESULT: GREEN (all three load-bearing properties hold)"
    exit 0
}
Write-Output "SPIKE RESULT: RED ($($script:Fail) failed)"
exit 1
