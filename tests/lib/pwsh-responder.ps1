#!/usr/bin/env pwsh
# pwsh-responder.ps1 -- warm long-lived PowerShell "responder" for the parity
# suite's pwsh session-batching (work-024 delivery-003, feature-004 / FR-4).
#
# Purpose:
#   Read framed requests from stdin and, for each, run a target script
#   (bin/aid.ps1) ONCE in a FRESH child runspace in FILE mode, capture its
#   combined output + exit code faithfully, and write a framed response to
#   stdout. One warm process serves the whole suite, so the ~158 loop-driven
#   `pwsh -File aid.ps1` cold starts collapse to a SINGLE engine bootstrap.
#
# Loaded (NOT dot-sourced, NOT a test): tests/lib/pwsh-batch.sh spawns it as
#   pwsh -NoProfile -File tests/lib/pwsh-responder.ps1
# It is not a glob-discovered test-*.sh canonical suite and exposes no imports.
#
# Mechanism (grounded by task-015 spike + local capture probes, pwsh 7.6.3):
#   - FILE mode `& '<aidPath>' @args` in a [powershell]::Create() child runspace
#     => $PSCommandPath is set, bin/aid.ps1 _PipedMode=false, AID_CODE_HOME
#     self-locates; the parent responder survives the child `exit`.
#   - Exit code recovered via the child runspace's $LASTEXITCODE session proxy
#     (the mechanism task-015 selected; GREEN on CI pwsh 7.x + local Windows).
#   - Output capture is faithful + REAL-TIME interleaved without a custom PSHost:
#     [Console]::Out/[Console]::Error are redirected into ONE per-request buffer
#     (catches bin/aid.ps1's 127 direct [Console]::Error writes), and Write-Host
#     (212 uses) + Out-Host (the `update all` child-stdout pass-through) are
#     shadowed by proxies that funnel into [Console]::Out -- so all channels land
#     in one ordered buffer, reproducing a cold `pwsh -File ... 2>&1` merge order.
#   - Fresh child runspace per request created AFTER the per-request env is set,
#     so its automatic $HOME re-derives from the pinned env (Risk R2); requests
#     are serialized and env is saved+restored, so nothing bleeds between calls.
#
# Wire protocol (line-framed; a value is the rest-of-line after its keyword, so
# paths with spaces survive; nonce terminator cannot be spoofed by output):
#   Request (stdin):
#     CALL | PING              frame head
#     NONCE <nonce>            per-request random token; echoed in the terminator
#     CWD <path>               caller $PWD (applied via Set-Location)      [CALL]
#     AID <path>               absolute path to aid.ps1                    [CALL]
#     ENV <name> <value>       zero+; per-request environment override     [CALL]
#     ARG <token>              zero+; ordered aid.ps1 argument             [CALL]
#     GO                       end of frame
#   Response (stdout):
#     <raw combined output bytes>
#     <nonce> <exit-code>      terminator line (own line; nonce = un-spoofable)
#
# Exit codes: 0 on clean stdin EOF (session stop). Does not call exit otherwise.
#
# ASCII-only + LF. In-box .NET only (no Add-Type).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Capture the REAL stdout/stderr writers ONCE, before any per-request Console
# redirect, so a framed response is always written to the real channel even
# while [Console]::Out is redirected into a per-request capture buffer.
$script:RealOut = [Console]::Out
$script:RealErr = [Console]::Error

# Proxy functions injected into every child runspace. Write-Host (212 uses in
# bin/aid.ps1) and Out-Host (the `update all` child-stdout pass-through, aid.ps1
# :748) are funneled into [Console]::Out -- which the responder redirects into
# the per-request buffer -- in REAL TIME, interleaved with the 127 direct
# [Console]::Error writes. This reproduces a cold `pwsh -File ... 2>&1` merge
# order without a custom PSHost (verified against the mixed-stream capture probe).
$script:Proxy = @'
function Write-Host {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
        [System.Object[]] $Object,
        [switch] $NoNewline,
        [System.Object] $Separator = ' ',
        [System.ConsoleColor] $ForegroundColor,
        [System.ConsoleColor] $BackgroundColor
    )
    $text = ($Object -join $Separator)
    if ($NoNewline) { [Console]::Out.Write($text) } else { [Console]::Out.WriteLine($text) }
}
function Out-Host {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)] [System.Object] $InputObject,
        [switch] $Paging
    )
    process {
        if ($null -ne $InputObject) {
            if ($InputObject -is [string]) { [Console]::Out.WriteLine($InputObject) }
            else { [Console]::Out.Write(($InputObject | Out-String -Width 4096)) }
        }
    }
}
'@

function Read-Frame {
    # Read one request frame from stdin. Returns a hashtable, or $null on stdin
    # EOF (the signal that pwsh_session_stop closed the request channel).
    $stdin = [Console]::In
    $head = $stdin.ReadLine()
    while ($null -ne $head -and $head -ne 'CALL' -and $head -ne 'PING') {
        $head = $stdin.ReadLine()   # tolerate/skip any inter-frame noise
    }
    if ($null -eq $head) { return $null }

    $frame = @{
        Kind  = $head
        Nonce = ''
        Cwd   = ''
        Aid   = ''
        Env   = New-Object System.Collections.Generic.List[object]
        Args  = New-Object System.Collections.Generic.List[string]
    }
    while ($true) {
        $line = $stdin.ReadLine()
        if ($null -eq $line) { break }          # premature EOF
        if ($line -eq 'GO') { break }
        if ($line.StartsWith('NONCE ')) { $frame.Nonce = $line.Substring(6); continue }
        if ($line.StartsWith('CWD ')) { $frame.Cwd = $line.Substring(4); continue }
        if ($line -eq 'CWD') { $frame.Cwd = ''; continue }
        if ($line.StartsWith('AID ')) { $frame.Aid = $line.Substring(4); continue }
        if ($line.StartsWith('ENV ')) {
            $rest = $line.Substring(4)
            $sp = $rest.IndexOf(' ')
            if ($sp -lt 0) { [void]$frame.Env.Add(@($rest, '')) }
            else { [void]$frame.Env.Add(@($rest.Substring(0, $sp), $rest.Substring($sp + 1))) }
            continue
        }
        if ($line.StartsWith('ARG ')) { [void]$frame.Args.Add($line.Substring(4)); continue }
        if ($line -eq 'ARG') { [void]$frame.Args.Add(''); continue }
    }
    return $frame
}

function Invoke-Request {
    param([hashtable]$Frame)

    # --- per-request env: save current, then apply the overrides ------------
    $savedEnv = @{}
    foreach ($pair in $Frame.Env) {
        $name = [string]$pair[0]
        $val = [string]$pair[1]
        if (-not $savedEnv.ContainsKey($name)) {
            $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name)
        }
        [Environment]::SetEnvironmentVariable($name, $val)
    }

    # --- per-request cwd: save + apply the process-global .NET current dir --
    $savedCwd = [Environment]::CurrentDirectory
    if ($Frame.Cwd -ne '' -and (Test-Path -LiteralPath $Frame.Cwd)) {
        try { [Environment]::CurrentDirectory = $Frame.Cwd } catch {}
    }

    $buf = New-Object System.IO.StringWriter
    $rc = 0
    $successText = ''
    $ps = $null
    try {
        # FRESH child runspace, created AFTER the env is set so its automatic
        # $HOME re-derives from the per-request env (Risk R2).
        $ps = [powershell]::Create()

        # Belt-and-suspenders (SPEC Risk R2): also pin the runspace $HOME via the
        # session proxy. $HOME is read-only in pwsh 7 so the set throws; the
        # env-driven auto-derivation above is authoritative, this is guarded.
        try { $ps.Runspace.SessionStateProxy.SetVariable('HOME', [Environment]::GetEnvironmentVariable('HOME')) } catch {}

        if ($Frame.Cwd -ne '') {
            # [void]: SetLocation returns a PathInfo that would otherwise leak
            # into this function's output stream (and corrupt the result object).
            try { [void]$ps.Runspace.SessionStateProxy.Path.SetLocation($Frame.Cwd) } catch {}
        }

        [void]$ps.AddScript($script:Proxy + "`n& '" + ($Frame.Aid -replace "'", "''") + "' @args")
        foreach ($a in $Frame.Args) { [void]$ps.AddArgument($a) }

        [Console]::SetOut($buf)
        [Console]::SetError($buf)
        try {
            $out = $ps.Invoke()
            if ($null -ne $out -and $out.Count -gt 0) {
                $successText = ($out | Out-String -Width 4096)
            }
        } catch {
            # Unhandled terminating error inside the invoked script. bin/aid.ps1
            # reports expected errors via [Console]::Error (already captured);
            # this path only catches genuinely unexpected throws.
            [Console]::Error.WriteLine([string]$_.Exception.Message)
        } finally {
            [Console]::SetOut($script:RealOut)
            [Console]::SetError($script:RealErr)
        }

        $ev = $null
        try { $ev = $ps.Runspace.SessionStateProxy.PSVariable.GetValue('LASTEXITCODE') } catch {}
        if ($null -ne $ev) {
            try { $rc = [int]$ev } catch { $rc = 1 }
        } elseif ($ps.HadErrors) {
            $rc = 1                       # mirror `pwsh -File` on an errored fall-through
        } else {
            $rc = 0
        }
    } catch {
        # Runspace/host-level failure -> mirror a cold `-File` fatal (exit 1).
        try { [Console]::SetOut($script:RealOut) } catch {}
        try { [Console]::SetError($script:RealErr) } catch {}
        $buf.Write([string]$_.Exception.Message)
        $rc = 1
    } finally {
        if ($null -ne $ps) { try { $ps.Dispose() } catch {} }
    }

    # --- restore env + cwd (no bleed to the next serialized request) --------
    foreach ($name in $savedEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnv[$name])
    }
    try { [Environment]::CurrentDirectory = $savedCwd } catch {}

    return @{ Output = ($buf.ToString() + $successText); Rc = $rc }
}

# --- main loop -------------------------------------------------------------
while ($true) {
    $frame = Read-Frame
    if ($null -eq $frame) { break }        # stdin EOF -> session stop

    if ($frame.Kind -eq 'PING') {
        $script:RealOut.Write($frame.Nonce + ' 0' + "`n")
        $script:RealOut.Flush()
        continue
    }

    $result = Invoke-Request -Frame $frame
    $script:RealOut.Write($result.Output)
    $script:RealOut.Write("`n")            # guarantee the terminator is its own line
    $script:RealOut.Write($frame.Nonce + ' ' + [string]$result.Rc + "`n")
    $script:RealOut.Flush()
}

exit 0
