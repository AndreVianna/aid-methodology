#Requires -Version 5.1
<#
.SYNOPSIS
    Deterministic connectors INDEX.md builder (PowerShell twin of
    build-connectors-index.sh).

.DESCRIPTION
    Regenerates `.aid/connectors/INDEX.md` from connector descriptor
    frontmatter, realizing feature-001's frozen "Connectors INDEX.md contract"
    (work-002-external_sources): columns Connector | Type | Endpoint | Auth |
    Secret Ref | Summary, its own source:/generator:/intent:/contracts:
    frontmatter, a single flat table -- NOT a KB doc (no kb-category:, no
    primary/meta/extension grouping, no ../knowledge/ cross-links).

    DETERMINISTIC: emits no run timestamp and no dated field anywhere in its
    output (KI-010), so two runs over an identical descriptor set produce a
    byte-identical INDEX.md -- the property feature-006's reconcile
    idempotence relies on. Behavior-equal to build-connectors-index.sh.

    Triggered by feature-002 (author), feature-004 (wire), and feature-006
    (reconcile) after any descriptor add/update/remove; this script only
    builds the index.

    Zero descriptors (including a -Root that does not exist yet) is NOT an
    error: writes a header-only INDEX.md (frontmatter + table header, zero
    rows) so the `@.aid/connectors/INDEX.md` context pointer never dangles.

.PARAMETER Root
    Connector descriptor directory. Default: .aid/connectors

.PARAMETER OutputPath
    Output INDEX.md path. Default: .aid/connectors/INDEX.md

.EXAMPLE
    pwsh -NoProfile -File build-connectors-index.ps1

.EXAMPLE
    pwsh -NoProfile -File build-connectors-index.ps1 -Root .aid/connectors -OutputPath .aid/connectors/INDEX.md

.NOTES
    ASCII-only source; WinPS-5.1-compatible. PowerShell twin of
    build-connectors-index.sh; behavior-equal.
    Exit codes: 0 success (incl. zero descriptors), 1 argument error, 2 I/O error.
#>
[CmdletBinding()]
param(
    [string]$Root = '.aid/connectors',
    [string]$OutputPath = '.aid/connectors/INDEX.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'build-connectors-index.ps1'

# Em dash used for Secret Ref when auth_method: none (feature-001 contract).
# Built from a code point, never embedded as a literal byte, so the SOURCE
# file stays ASCII-only per coding-standards.md; only the generated .md
# OUTPUT carries the character.
$EmDash = [string][char]0x2014

function Write-Diagnostic {
    param([string]$Msg)
    [Console]::Error.WriteLine("${ScriptName}: ${Msg}")
}

# ---------------------------------------------------------------------------
# Get-AidFrontmatterField -- single-line YAML scalar from the FIRST
# frontmatter block, with one pair of surrounding quotes stripped. Same
# first-block scoping as build-connectors-index.sh's `ef`: a body-level
# thematic-break `---` is never re-entered as frontmatter. Returns '' when
# the field is absent.
# ---------------------------------------------------------------------------
function Get-AidFrontmatterField {
    param([string[]]$Lines, [string]$FieldName)
    $inFm = $false
    $lineNum = 0
    $pattern = '^' + [regex]::Escape($FieldName) + ':'
    foreach ($line in $Lines) {
        $lineNum++
        if ($line -eq '---') {
            $inFm = -not $inFm
            if ($lineNum -gt 1 -and -not $inFm) { return '' }
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
    return ''
}

# ---------------------------------------------------------------------------
# Protect-AidTableCell -- escape a literal table-cell pipe so it cannot break
# the row (same as build-connectors-index.sh's `esc`).
# ---------------------------------------------------------------------------
function Protect-AidTableCell {
    param([string]$Value)
    return ($Value -replace '\|', '\|')
}

# ---------------------------------------------------------------------------
# Collect descriptor files: *.md, excluding INDEX.md and dotfiles, sorted by
# name (== by stem, since every descriptor lives directly under $Root). A
# non-existent $Root is NOT an error -- treated as zero descriptors, mirroring
# connector-registry.ps1's Get-AidConnectorList non-existent-root behavior.
# ---------------------------------------------------------------------------
$descriptors = @()
if (Test-Path -LiteralPath $Root -PathType Container) {
    $files = Get-ChildItem -LiteralPath $Root -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'INDEX.md' -and -not $_.Name.StartsWith('.') } |
        Sort-Object Name
    foreach ($f in $files) { $descriptors += $f }
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir -PathType Container)) {
    try {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    } catch {
        Write-Diagnostic "cannot create output dir: $outDir"
        exit 2
    }
}

# ---------------------------------------------------------------------------
# Render one row per descriptor.
# ---------------------------------------------------------------------------
$rows = New-Object System.Collections.Generic.List[string]

foreach ($f in $descriptors) {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8

    $name = Get-AidFrontmatterField -Lines $lines -FieldName 'name'
    if ([string]::IsNullOrEmpty($name)) { $name = $stem }

    $ctype = Get-AidFrontmatterField -Lines $lines -FieldName 'connection_type'
    if ([string]::IsNullOrEmpty($ctype)) { $ctype = ' ' }

    $endpoint = Get-AidFrontmatterField -Lines $lines -FieldName 'endpoint'
    if ([string]::IsNullOrEmpty($endpoint)) { $endpoint = ' ' }

    $auth = Get-AidFrontmatterField -Lines $lines -FieldName 'auth_method'
    $secref = Get-AidFrontmatterField -Lines $lines -FieldName 'secret_reference'

    $summary = Get-AidFrontmatterField -Lines $lines -FieldName 'summary'
    if ([string]::IsNullOrEmpty($summary)) { $summary = ' ' }

    $authCell = ' '
    if (-not [string]::IsNullOrEmpty($auth)) { $authCell = Protect-AidTableCell $auth }

    # Secret Ref: em dash when auth_method: none (feature-001 contract), or
    # when secret_reference is absent (malformed descriptor -- keep the table
    # well-formed rather than emit a blank cell).
    $secrefCell = $EmDash
    if ($auth -ne 'none' -and -not [string]::IsNullOrEmpty($secref)) {
        $secrefCell = Protect-AidTableCell $secref
    }

    $nameCell = Protect-AidTableCell $name
    $ctypeCell = Protect-AidTableCell $ctype
    $endpointCell = Protect-AidTableCell $endpoint
    $summaryCell = Protect-AidTableCell $summary

    $rows.Add("| [$nameCell]($stem.md) | $ctypeCell | $endpointCell | $authCell | $secrefCell | $summaryCell |")
}

# ---------------------------------------------------------------------------
# Compose the file. Frontmatter carries no dated/timestamped field (KI-010):
# source: generated / generator: / intent: / contracts: only (feature-001's
# frozen "own frontmatter" contract) -- no kb-category:, no changelog:. The
# body is title + single flat table only: feature-005 explicitly does not add
# a consumption-contract preamble here (that documentation lives in the
# `## Connectors` context-file section, not in this generated file).
# ---------------------------------------------------------------------------
$outLines = New-Object System.Collections.Generic.List[string]
$outLines.Add('---')
$outLines.Add('source: generated')
$outLines.Add('generator: build-connectors-index')
$outLines.Add('intent: |')
$outLines.Add('  Routing table for the tool/integration registry under .aid/connectors/,')
$outLines.Add('  regenerated from connector descriptor frontmatter after any')
$outLines.Add('  add/update/remove/wire (feature-002 author, feature-004 wire, feature-006')
$outLines.Add('  reconcile trigger this builder; feature-005 owns it). An agent reaches this')
$outLines.Add('  file via the "## Connectors" context-file pointer, then opens the specific')
$outLines.Add('  descriptor.')
$outLines.Add('contracts:')
$outLines.Add('  - "One row per connector descriptor under .aid/connectors/"')
$outLines.Add('---')
$outLines.Add('')
$outLines.Add('# Connectors Index')
$outLines.Add('')
$outLines.Add('| Connector | Type | Endpoint | Auth | Secret Ref | Summary |')
$outLines.Add('|-----------|------|----------|------|------------|---------|')
foreach ($r in $rows) { $outLines.Add($r) }

$content = ($outLines -join "`n") + "`n"
[System.IO.File]::WriteAllText($OutputPath, $content, [System.Text.UTF8Encoding]::new($false))

$size = (Get-Item -LiteralPath $OutputPath).Length
$lineCount = $outLines.Count
Write-Output "OK: Wrote $OutputPath ($size bytes, $lineCount lines)"
exit 0
