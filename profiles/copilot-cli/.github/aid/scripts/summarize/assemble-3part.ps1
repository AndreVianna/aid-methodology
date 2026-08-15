# assemble-3part.ps1 -- assemble final kb.html from Part1 + Part2 (no Mermaid engine).
#
# CHANGE 7 (FR-51): The Mermaid engine embed was REMOVED in D-012. This script
#   previously required -Mermaid (mandatory). The -Mermaid parameter is now
#   retired; the script concatenates Part1 + Part2 only. Inline SVG visuals are
#   pre-rendered at build time -- no runtime diagram engine needed.
#
# DETERMINISM (Change 6 / FR-50):
#   When -Manifest FILE is supplied the script records the manifest path in its
#   output so callers can verify Part1 was assembled with the same manifest.
#   Part1 itself must be built with assemble.sh --manifest for full determinism;
#   this script performs the final byte-level concatenation regardless.
#   Same Part1 + Part2 -> same output (reproducible + auditable, FR-50).
#
# Usage: assemble-3part.ps1 -Part1 X -Part2 Z -Output W [-Manifest FILE]

param(
    [Parameter(Mandatory)] [string]$Part1,
    [Parameter(Mandatory)] [string]$Part2,
    [Parameter(Mandatory)] [string]$Output,
    [string]$Manifest = ""
)

$ErrorActionPreference = 'Stop'

foreach ($f in @($Part1, $Part2)) {
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
    + [System.IO.File]::ReadAllBytes($Part2)
[System.IO.File]::WriteAllBytes($Output, $buffer)

$size = (Get-Item -LiteralPath $Output).Length
if ($Manifest -ne "") {
    Write-Host "Wrote $Output ($size bytes; manifest: $Manifest)"
} else {
    Write-Host "Wrote $Output ($size bytes)"
}
