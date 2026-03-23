#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetDirectory,

    [Alias('ForceOverwrite')]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Validate target directory
if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
    Write-Error "Directory '$TargetDirectory' does not exist."
    exit 1
}

$Target = (Resolve-Path $TargetDirectory).Path

# Menu state
$selected = @{ 1 = $false; 2 = $false; 3 = $false }

function Get-ToolName($id) {
    switch ($id) {
        1 { return "Claude Code" }
        2 { return "Codex" }
        3 { return "Cursor" }
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "Select tools to install into: $Target"
    Write-Host ""
    foreach ($i in 1, 2, 3) {
        $mark = if ($selected[$i]) { "x" } else { " " }
        Write-Host ("  [{0}] [{1}] {2}" -f $i, $mark, (Get-ToolName $i))
    }
    Write-Host "  [4] Done"
    Write-Host ""
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Selection"
    switch ($choice) {
        { $_ -in '1','2','3' } {
            $k = [int]$choice
            $selected[$k] = -not $selected[$k]
        }
        '4' { break }
        default { Write-Host "Invalid choice. Enter 1, 2, 3, or 4." }
    }
    if ($choice -eq '4') { break }
}

$any = ($selected.Values | Where-Object { $_ }) -ne $null
if (-not $any) {
    Write-Host "Nothing selected. Exiting."
    exit 0
}

# Copy helper: new=copy, identical=skip, different=ask (or overwrite with -Force)
function Copy-Item-Safe {
    param(
        [string]$Src,
        [string]$Dst
    )
    $dstDir = Split-Path -Parent $Dst
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    if (Test-Path $Dst) {
        $srcHash = (Get-FileHash -Path $Src -Algorithm MD5).Hash
        $dstHash = (Get-FileHash -Path $Dst -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  Up to date: $Dst"
            return
        }
        if ($Force) {
            Copy-Item -Path $Src -Destination $Dst -Force
            Write-Host "  Updated: $Dst"
        } else {
            $answer = Read-Host "Overwrite '$Dst'? (files differ) [y/N]"
            if ($answer -match '^[yY]') {
                Copy-Item -Path $Src -Destination $Dst -Force
                Write-Host "  Updated: $Dst"
            } else {
                Write-Host "  Skipped: $Dst"
            }
        }
        return
    }
    Copy-Item -Path $Src -Destination $Dst -Force
    Write-Host "  Copied: $Dst"
}

# Copy directory recursively, file by file (preserves empty dirs)
function Copy-Dir-Safe {
    param(
        [string]$SrcDir,
        [string]$DstDir
    )
    # Create directory structure first
    $dirs = Get-ChildItem -Path $SrcDir -Recurse -Directory
    foreach ($dir in $dirs) {
        $rel = $dir.FullName.Substring($SrcDir.Length).TrimStart('\','/')
        $target = Join-Path $DstDir $rel
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }
    }
    # Then copy files
    $files = Get-ChildItem -Path $SrcDir -Recurse -File
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($SrcDir.Length).TrimStart('\','/')
        $dst = Join-Path $DstDir $rel
        Copy-Item-Safe -Src $file.FullName -Dst $dst
    }
}

Write-Host ""
Write-Host "Installing selected tools..."
Write-Host ""

# AGENTS.md is shared across all tools — copy once
Write-Host "--- AGENTS.md ---"
Copy-Item-Safe -Src (Join-Path $ScriptDir "claude-code\AGENTS.md") -Dst (Join-Path $Target "AGENTS.md")

# Claude Code
if ($selected[1]) {
    Write-Host "--- Claude Code ---"
    Copy-Dir-Safe -SrcDir (Join-Path $ScriptDir "claude-code\.claude") -DstDir (Join-Path $Target ".claude")
    Copy-Item-Safe -Src (Join-Path $ScriptDir "claude-code\CLAUDE.md") -Dst (Join-Path $Target "CLAUDE.md")
}

# Codex
if ($selected[2]) {
    Write-Host "--- Codex ---"
    Copy-Dir-Safe -SrcDir (Join-Path $ScriptDir "codex\.codex") -DstDir (Join-Path $Target ".codex")
}

# Cursor
if ($selected[3]) {
    Write-Host "--- Cursor ---"
    Copy-Dir-Safe -SrcDir (Join-Path $ScriptDir "cursor\.cursor") -DstDir (Join-Path $Target ".cursor")
}

Write-Host ""
Write-Host "Done. Files installed into: $Target"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run /aid-init to scaffold the Knowledge Base structure and project placeholders."
Write-Host "  2a. Brownfield (existing code): Run /aid-discover to analyze the codebase and fill in the KB."
Write-Host "  2b. Greenfield (new project):   Run /aid-interview to start requirements gathering."
