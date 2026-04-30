# concatenate.ps1 — assemble final knowledge-summary.html from parts.
# Usage: concatenate.ps1 -Part1 X -Mermaid Y -Part2 Z -Output W

param(
    [Parameter(Mandatory)] [string]$Part1,
    [Parameter(Mandatory)] [string]$Mermaid,
    [Parameter(Mandatory)] [string]$Part2,
    [Parameter(Mandatory)] [string]$Output
)

$ErrorActionPreference = 'Stop'

foreach ($f in @($Part1, $Mermaid, $Part2)) {
    if (-not (Test-Path -LiteralPath $f)) {
        Write-Error "Missing input: $f"
        exit 1
    }
    if ((Get-Item -LiteralPath $f).Length -le 0) {
        Write-Error "Empty input: $f"
        exit 1
    }
}

$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

# Use byte-level concat to avoid encoding/CRLF interpretation
$buffer = [System.IO.File]::ReadAllBytes($Part1) `
    + [System.IO.File]::ReadAllBytes($Mermaid) `
    + [System.IO.File]::ReadAllBytes($Part2)
[System.IO.File]::WriteAllBytes($Output, $buffer)

$size = (Get-Item -LiteralPath $Output).Length
Write-Host "Wrote $Output ($size bytes)"
