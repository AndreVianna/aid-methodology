#Requires -Version 5.1
<#
.SYNOPSIS
    Dedicated frontmatter accessor for the tool/integration registry under
    `.aid/connectors/` (PowerShell twin of connector-registry.sh).

.DESCRIPTION
    Realizes feature-001's "Integration Store Placement and Schema" registry
    accessor contract. NOT a reuse of read-setting.ps1-style dotted-path
    resolution (KI-001): descriptor fields are one-per-line YAML frontmatter,
    not `.aid/settings.yml` `section.key` pairs. feature-005's connectors
    INDEX.md builder is the primary consumer.

    Two operations:
      list                  -- one line per `.aid/connectors/*.md` descriptor
                                stem (sorted), excluding `INDEX.md` and the
                                non-descriptor `.gitignore` file / `.secrets/`
                                directory.
      read <Stem> <Field>   -- print the frontmatter value of <Field> from
                                `.aid/connectors/<Stem>.md` to stdout.

.PARAMETER Op
    Operation: 'list' or 'read'.

.PARAMETER Stem
    Descriptor filename stem (required for 'read').

.PARAMETER Field
    Frontmatter field name (required for 'read').

.PARAMETER Root
    Connectors registry root directory. Default: .aid/connectors

.EXAMPLE
    pwsh -NoProfile -File connector-registry.ps1 list

.EXAMPLE
    pwsh -NoProfile -File connector-registry.ps1 read github connection_type

.NOTES
    ASCII-only output. PowerShell twin of connector-registry.sh; behavior-equal.
    Exit codes:
      0  success (list: zero or more stems printed; read: value printed)
      1  read: descriptor not found, or field absent from its frontmatter
      2  argument error (bad/missing operation, missing Stem/Field)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Op,

    [Parameter(Position=1)]
    [string]$Stem,

    [Parameter(Position=2)]
    [string]$Field,

    [string]$Root = '.aid/connectors'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'connector-registry.ps1'

# Diagnostic writer -- writes directly to the stderr stream and does NOT rely on
# Write-Error, whose non-terminating-vs-terminating behavior is governed by
# $ErrorActionPreference: with 'Stop' in effect (set above), Write-Error becomes
# a terminating error that aborts the script BEFORE a following `exit $Code`
# line runs, silently collapsing every custom exit code to PowerShell's default
# (1). [Console]::Error.WriteLine is unaffected by $ErrorActionPreference, so
# the intended exit code is always reached.
function Write-Diagnostic {
    param([string]$Msg)
    [Console]::Error.WriteLine("${ScriptName}: ${Msg}")
}

# ---------------------------------------------------------------------------
# Get-AidConnectorList -- one stem per `.aid/connectors/*.md` descriptor,
# excluding INDEX.md and dotfiles (.gitignore); .secrets/ is a directory so it
# is never matched by the file filter below. Returns an empty array (never
# $null) when RootDir does not exist.
# ---------------------------------------------------------------------------
function Get-AidConnectorList {
    param([string]$RootDir)
    if (-not (Test-Path -LiteralPath $RootDir -PathType Container)) {
        return ,@()
    }
    $files = Get-ChildItem -LiteralPath $RootDir -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'INDEX.md' -and -not $_.Name.StartsWith('.') } |
        Sort-Object Name
    $stems = @()
    foreach ($f in $files) {
        $stems += [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    }
    return ,$stems
}

# ---------------------------------------------------------------------------
# Read-AidConnectorField -- single-line YAML scalar from the FIRST frontmatter
# block, with one pair of surrounding quotes stripped. Same first-block scoping
# as the Bash twin's read_field: a body-level thematic-break `---` never
# re-enters frontmatter mode. Returns $null when the field is absent.
# ---------------------------------------------------------------------------
function Read-AidConnectorField {
    param([string]$DescriptorFile, [string]$FieldName)
    $lines = Get-Content -LiteralPath $DescriptorFile -Encoding UTF8
    $inFm = $false
    $lineNum = 0
    $pattern = '^' + [regex]::Escape($FieldName) + ':'
    foreach ($line in $lines) {
        $lineNum++
        if ($line -eq '---') {
            $inFm = -not $inFm
            if ($lineNum -gt 1 -and -not $inFm) { break }
            continue
        }
        if ($inFm -and $line -match $pattern) {
            $value = $line -replace ('^' + [regex]::Escape($FieldName) + ':\s*'), ''
            $value = $value.TrimEnd()
            $value = $value -replace '^["'']', ''
            $value = $value -replace '["'']$', ''
            return $value
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if ($Op -ne 'list' -and $Op -ne 'read') {
    Write-Diagnostic "unknown operation: $Op (expected list|read)"
    exit 2
}

if ($Op -eq 'read') {
    if ([string]::IsNullOrEmpty($Stem) -or [string]::IsNullOrEmpty($Field)) {
        Write-Diagnostic "'read' requires <stem> <field>"
        exit 2
    }
}

if ($Op -eq 'list') {
    $stems = Get-AidConnectorList -RootDir $Root
    foreach ($s in $stems) { Write-Output $s }
    exit 0
}

# read
$descriptor = Join-Path $Root "$Stem.md"
if (-not (Test-Path -LiteralPath $descriptor -PathType Leaf)) {
    Write-Diagnostic "descriptor not found: $descriptor"
    exit 1
}

$value = Read-AidConnectorField -DescriptorFile $descriptor -FieldName $Field
if ([string]::IsNullOrEmpty($value)) {
    Write-Diagnostic "field '$Field' not found in $descriptor"
    exit 1
}

Write-Output $value
exit 0
