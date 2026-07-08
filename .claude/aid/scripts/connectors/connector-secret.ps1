#Requires -Version 5.1
<#
.SYNOPSIS
    Write/purge a connector's secret value in the local file store
    (PowerShell twin of connector-secret.sh).

.DESCRIPTION
    The single home for ALL `.aid/connectors/.secrets/` I/O (feature-003
    "Local Auth Registration"). Exposes BOTH operations the connector-secret
    twin owns, per feature-003 SPEC.md "Layers & Components": feature-003
    owns this twin and defines BOTH `write` and `purge` -- feature-006 does
    NOT define its own purge twin; on REMOVE it CALLS this script's `purge`
    op instead.

      write <Stem> [-Root <dir>]  -- no-echo capture of a secret value and an
                                      exact-bytes, owner-only (best-effort ACL)
                                      write to `<Root>/.secrets/<Stem>`. Prints
                                      ONLY the `file:<Root>/.secrets/<Stem>`
                                      reference to stdout -- never the value.
      purge <Stem> [-Root <dir>]  -- idempotent delete of
                                      `<Root>/.secrets/<Stem>`. A missing file
                                      is a clean no-op success. Prints nothing
                                      to stdout; silent on contents.

.PARAMETER Op
    Operation: 'write' or 'purge'.

.PARAMETER Stem
    Connector key -- a bare filename stem (no path separator, no '..').

.PARAMETER Root
    Connectors registry root directory. Default: .aid/connectors

.EXAMPLE
    pwsh -NoProfile -File connector-secret.ps1 write github

.EXAMPLE
    "my-token" | pwsh -NoProfile -File connector-secret.ps1 write github   # automation/CI

.EXAMPLE
    pwsh -NoProfile -File connector-secret.ps1 purge github

.NOTES
    ASCII-only. WinPS-5.1-compatible. PowerShell twin of connector-secret.sh;
    behavior-equal. `ConvertFrom-SecureString -AsPlainText` is BANNED under
    WinPS 5.1 (pwsh-7-only; see the PowerShell Conventions section of
    `.aid/knowledge/coding-standards.md`) -- the plaintext is materialized in-process only via
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR / PtrToStringBSTR,
    and the BSTR is zeroed with ZeroFreeBSTR immediately after the write.

    No-echo capture: when a real interactive console is attached,
    `Read-Host -AsSecureString` reads with terminal echo off. When stdin is
    redirected ([Console]::IsInputRedirected -- automation, CI, or this
    script's own unit tests), `Read-Host -AsSecureString` cannot be used at
    all: it calls directly into the console API and hangs indefinitely
    instead of reading the redirected stream (verified empirically -- it does
    not throw, it blocks). In that case the value is read as plain text
    directly from the redirected stream ([Console]::In.ReadLine()) -- this is
    exactly the Bash twin's own behavior too, where `read -rs`'s echo
    suppression is a no-op once stdin is not a tty (there is no terminal left
    to echo back to). See tests/canonical/test-connector-secret-ps1.sh for the
    documented redirection pattern used to drive this script in tests.

    Exit codes:
      0  success (write: value stored, `file:` reference printed; purge:
         deleted, or already-absent no-op)
      1  generic runtime failure (e.g. empty secret entered, underlying I/O error)
      2  usage / argument error (bad/missing operation, missing Stem)
      3  path-confinement rejection: Stem contains '/', '\', or '..' -- checked
         BEFORE any read/write/delete; applies identically to write and purge
      4  write only: fail-closed ignore-precondition failure -- the committed
         `<Root>/.gitignore` does not ignore `.secrets/`. purge does not
         require this precondition.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Op,

    [Parameter(Position=1)]
    [string]$Stem,

    [string]$Root = '.aid/connectors'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'connector-secret.ps1'

# Diagnostic writer -- writes directly to the stderr stream and does NOT rely
# on Write-Error, whose non-terminating-vs-terminating behavior is governed by
# $ErrorActionPreference: with 'Stop' in effect (set above), Write-Error
# becomes a terminating error that aborts the script BEFORE a following
# `exit $Code` line runs, silently collapsing every custom exit code to
# PowerShell's default (1). [Console]::Error.WriteLine is unaffected by
# $ErrorActionPreference, so the intended exit code is always reached.
function Write-Diagnostic {
    param([string]$Msg)
    [Console]::Error.WriteLine("${ScriptName}: ${Msg}")
}

if ($Op -ne 'write' -and $Op -ne 'purge') {
    Write-Diagnostic "unknown operation: $Op (expected write|purge)"
    exit 2
}

if ([string]::IsNullOrEmpty($Stem)) {
    Write-Diagnostic "'$Op' requires <Stem>"
    exit 2
}

# ---------------------------------------------------------------------------
# Path confinement -- BEFORE any read/write/delete, identically for both ops.
# Stem is a filename stem ONLY; reject any path separator or a '..'
# occurrence outright (a strict substring check -- fail-closed over
# under-rejection is the correct trade-off for a delete-capable op).
# ---------------------------------------------------------------------------
if ($Stem.Contains('/') -or $Stem.Contains('\') -or $Stem.Contains('..')) {
    Write-Diagnostic "invalid stem '$Stem' -- must be a bare filename (no '/', '\', or '..')"
    exit 3
}

$SecretsDir = Join-Path $Root '.secrets'
$GitignoreFile = Join-Path $Root '.gitignore'
$Target = Join-Path $SecretsDir $Stem

# ---------------------------------------------------------------------------
# Test-AidGitignoreIgnoresSecrets -- $true iff FilePath has a line that
# ignores the `.secrets/` directory (feature-001's committed connectors-local
# `.aid/connectors/.gitignore`, sole entry `.secrets/`). Tolerates a leading
# `/` and a missing trailing `/` -- equivalent gitignore forms for the same
# directory. `\s` already matches a trailing `\r` (CRLF-authored file).
# ---------------------------------------------------------------------------
function Test-AidGitignoreIgnoresSecrets {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $false }
    $lines = Get-Content -LiteralPath $FilePath -Encoding UTF8
    foreach ($line in $lines) {
        if ($line -match '^\s*/?\.secrets/?\s*$') { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# purge -- idempotent delete. Test-Path returns $false (no error) when Target
# or any parent directory does not exist, so this is a clean no-op in that
# case; never reads the file first, so it stays silent on contents even in an
# error path.
# ---------------------------------------------------------------------------
if ($Op -eq 'purge') {
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        Remove-Item -LiteralPath $Target -Force
    }
    exit 0
}

# ---------------------------------------------------------------------------
# write
# ---------------------------------------------------------------------------

# Fail-closed ignore precondition -- BEFORE the first byte of any secret is
# written (feature-003 SPEC.md "Security Specs"). Checked before the prompt
# too, so a refusal never needlessly captures a secret it will not store.
if (-not (Test-AidGitignoreIgnoresSecrets -FilePath $GitignoreFile)) {
    Write-Diagnostic "refusing to write -- $GitignoreFile does not ignore .secrets/ (fail-closed)"
    exit 4
}

# Ensure the store directory exists.
if (-not (Test-Path -LiteralPath $SecretsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
}

# Best-effort owner-only ACL tightening -- non-fatal if unsupported (a
# non-Windows platform, or a filesystem that does not support ACLs); per
# feature-001 the git-ignore is the load-bearing guarantee everywhere, this is
# defense-in-depth only on Windows.
try {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls $SecretsDir /inheritance:r /grant:r "${currentUser}:(OI)(CI)F" 2>$null | Out-Null
} catch {}

# No-echo capture. See .NOTES above for the redirected-stdin fallback and why
# it is required (Read-Host -AsSecureString hangs, it does not throw, when
# stdin is redirected).
$Plain = $null
if ([Console]::IsInputRedirected) {
    $Plain = [Console]::In.ReadLine()
} else {
    [Console]::Error.Write("Enter secret value for ${Stem} (input hidden): ")
    $secure = Read-Host -AsSecureString
    [Console]::Error.WriteLine('')
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $Plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    Remove-Variable -Name secure -ErrorAction SilentlyContinue
}

if ([string]::IsNullOrEmpty($Plain)) {
    Write-Diagnostic 'no secret entered (empty input)'
    exit 1
}

# Exact-bytes write -- no BOM, no trailing newline. Avoid Set-Content/Out-File
# (they add a line terminator and/or a BOM); WriteAllText with a
# UTF8Encoding($false) writes the exact bytes and nothing else.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Target, $Plain, $utf8NoBom)

# Clear the in-memory secret immediately after the write returns, before
# anything is printed to stdout. (.NET strings are immutable -- dropping the
# only reference here just makes the value eligible for GC; the BSTR zeroing
# above is the load-bearing in-process wipe, not this.)
$Plain = $null
Remove-Variable -Name Plain -ErrorAction SilentlyContinue

Write-Output "file:$Target"
exit 0
