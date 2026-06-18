#Requires -Version 5.1
<#
.SYNOPSIS
    Idempotent monolithic -> hierarchy migration helper (PowerShell twin).

.DESCRIPTION
    Converts a monolithic work-NNN-{name}/ layout (single STATE.md + tasks/*.md)
    into the work-004 uniform unit hierarchy:

      work-NNN-{name}/
        STATE.md                          (rewritten: AUTHORED header + DERIVED placeholders)
        tasks/                            (legacy flat files retained as-is for reference)
        delivery-NNN/
          SPEC.md                         (delivery definition)
          STATE.md                        (delivery authored lifecycle + gate + Q&A + derived tasks view)
          tasks/
            task-NNN/
              SPEC.md                     (task definition -- from legacy tasks/task-NNN.md)
              STATE.md                    (task mutable cells + findings + dispatch log)

    IDEMPOTENT: if any per-task STATE.md already exists, the entire work is skipped (no-op).

    Delivery resolution:
      Each task is placed under the delivery parsed from the task's **Source:** line:
        **Source:** work-NNN-{name} -> delivery-NNN
      The pattern delivery-[0-9]+ is matched (same parse as writeback-state.sh).
      Tasks with no parseable token default to delivery-001 with a WARNING emitted.

    Scope discipline (SD-6): runs ONLY on the path passed as -WorkDir.
    Does NOT scan $HOME or any real works automatically.

.PARAMETER WorkDir
    Absolute or relative path to the monolithic work folder.

.PARAMETER DryRun
    Print what would be done without writing files.

.EXAMPLE
    pwsh -NoProfile -File migrate-work-hierarchy.ps1 -WorkDir tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test

.NOTES
    ASCII-only output. PowerShell twin of migrate-work-hierarchy.sh.
    Exit codes: 0=ok, 1=bad dir, 2=no STATE.md, 3=no tasks, 4=verify failure.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$WorkDir,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'migrate-work-hierarchy.ps1'
$Warnings = [System.Collections.Generic.List[string]]::new()

function Log { param([string]$Msg) Write-Host "${ScriptName}: ${Msg}" }
function Warn { param([string]$Msg)
    Write-Warning "${ScriptName}: ${Msg}"
    $Warnings.Add($Msg)
}
function Die { param([string]$Msg, [int]$Code = 1)
    Write-Error "${ScriptName}: ERROR: ${Msg}"
    exit $Code
}

# Pad integer to 3 digits.
function Pad3 { param([int]$N) return $N.ToString('D3') }

# ---------------------------------------------------------------------------
# Delivery token resolution (same parse as writeback-state.sh)
# ---------------------------------------------------------------------------

function Resolve-DeliveryToken {
    param([string]$TaskFile)
    $content = Get-Content -LiteralPath $TaskFile -Raw -Encoding UTF8
    $sourceLine = ($content -split "`n" | Where-Object { $_ -match '^\*\*Source:\*\*' } | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($sourceLine)) { return $null }

    if ($sourceLine -match 'delivery-(\d+)') {
        $rawNum = [int]$Matches[1]
        if ($rawNum -eq 0) { return $null }
        return $rawNum
    }
    return $null
}

# ---------------------------------------------------------------------------
# Section extractors
# ---------------------------------------------------------------------------

function Get-BetweenH2 {
    param([string[]]$Lines, [string]$Heading)
    $target = "## $Heading"
    $inside = $false
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        if ($line -eq $target) { $inside = $true; continue }
        if ($inside -and $line -match '^## ') { break }
        if ($inside) { $result.Add($line) }
    }
    return ,$result.ToArray()
}

function Get-TaskFindings {
    param([string[]]$StateLines, [string]$TaskId)
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Quick Check Findings'
    $heading = "### $TaskId"
    $inside = $false
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $section) {
        if ($inside -and $line -match '^###') { break }
        if ($inside) { $result.Add($line) }
        if ($line -eq $heading) { $inside = $true }
    }
    # Trim leading blank lines.
    while ($result.Count -gt 0 -and [string]::IsNullOrWhiteSpace($result[0])) {
        $result.RemoveAt(0)
    }
    return ,$result.ToArray()
}

function Get-TaskDispatches {
    param([string[]]$StateLines, [string]$TaskId)
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Dispatches'
    $heading = "### $TaskId"
    $inside = $false
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $section) {
        if ($inside -and $line -match '^###') { break }
        if ($inside) {
            # Skip header/separator rows and blank lines (caller prints the header).
            if ($line -match '^\|\s*Date\s*\|') { continue }
            if ($line -match '^\|[-| ]+\|') { continue }
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $result.Add($line)
        }
        if ($line -eq $heading) { $inside = $true }
    }
    return ,$result.ToArray()
}

function Get-DeliveryGate {
    param([string[]]$StateLines, [int]$DeliveryNum)
    $padded = Pad3 $DeliveryNum
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Delivery Gates'
    $heading = "### delivery-$padded"
    $inside = $false
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $section) {
        if ($inside -and $line -match '^###') { break }
        if ($inside) { $result.Add($line) }
        if ($line -eq $heading) { $inside = $true }
    }
    # Trim leading blank lines.
    while ($result.Count -gt 0 -and [string]::IsNullOrWhiteSpace($result[0])) {
        $result.RemoveAt(0)
    }
    return ,$result.ToArray()
}

function Get-DeliveryQA {
    param([string[]]$StateLines, [int]$DeliveryNum)
    $padded = "delivery-$(Pad3 $DeliveryNum)"
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Cross-phase Q&A'
    $result = [System.Collections.Generic.List[string]]::new()
    $block = [System.Collections.Generic.List[string]]::new()
    $matchD = $false
    $inBlock = $false
    foreach ($line in $section) {
        if ($line -match '^### Q\d') {
            if ($matchD -and $block.Count -gt 0) {
                $result.AddRange($block)
            }
            $block = [System.Collections.Generic.List[string]]::new()
            $block.Add($line)
            $matchD = $false
            $inBlock = $true
            continue
        }
        if ($inBlock) {
            $block.Add($line)
            if ($line.Contains($padded)) { $matchD = $true }
        }
        # Lines before first ### Q are preamble -- skip.
    }
    if ($matchD -and $block.Count -gt 0) { $result.AddRange($block) }
    return ,$result.ToArray()
}

function Get-WorkQA {
    param([string[]]$StateLines)
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Cross-phase Q&A'
    $result = [System.Collections.Generic.List[string]]::new()
    $block = [System.Collections.Generic.List[string]]::new()
    $hasDelivery = $false
    $inBlock = $false
    foreach ($line in $section) {
        if ($line -match '^### Q\d') {
            if (-not $hasDelivery -and $inBlock -and $block.Count -gt 0) {
                $result.AddRange($block)
            }
            $block = [System.Collections.Generic.List[string]]::new()
            $block.Add($line)
            $hasDelivery = $false
            $inBlock = $true
            continue
        }
        if ($inBlock) {
            $block.Add($line)
            if ($line -match 'delivery-\d') { $hasDelivery = $true }
        }
        # Preamble (before first ### Q) skipped.
    }
    if (-not $hasDelivery -and $inBlock -and $block.Count -gt 0) {
        $result.AddRange($block)
    }
    return ,$result.ToArray()
}

function Get-TaskRowFields {
    param([string[]]$StateLines, [string]$TaskId)
    $section = Get-BetweenH2 -Lines $StateLines -Heading 'Tasks Status'
    if ($section.Count -eq 0) {
        $section = Get-BetweenH2 -Lines $StateLines -Heading 'Tasks State'
    }
    foreach ($line in $section) {
        if ($line -match '^\|') {
            # Split by '|' gives 0-based array:
            # [0]=""  [1]=# (task-NNN)  [2]=Task title  [3]=Type  [4]=Wave  [5]=Status  [6]=Review  [7]=Elapsed  [8]=Notes  [9]=""
            $cells = $line -split '\|' | ForEach-Object { $_.Trim() }
            for ($i = 0; $i -lt $cells.Count; $i++) {
                if ($cells[$i] -eq $TaskId) {
                    # $i is the index of the # column (task-NNN value).
                    # Status is at $i+4, Review=$i+5, Elapsed=$i+6, Notes=$i+7
                    $st = if ($cells.Count -gt ($i + 4)) { $cells[$i + 4].Trim() } else { 'Pending' }
                    $rv = if ($cells.Count -gt ($i + 5)) { $cells[$i + 5].Trim() } else { '--' }
                    $el = if ($cells.Count -gt ($i + 6)) { $cells[$i + 6].Trim() } else { '--' }
                    $nt = if ($cells.Count -gt ($i + 7)) { $cells[$i + 7].Trim() } else { '--' }
                    return @{ State = $st; Review = $rv; Elapsed = $el; Notes = $nt }
                }
            }
        }
    }
    return @{ State = 'Pending'; Review = '--'; Elapsed = '--'; Notes = '--' }
}

# ---------------------------------------------------------------------------
# File writers
# ---------------------------------------------------------------------------

function Write-TaskState {
    param(
        [string]$OutFile,
        [string]$TaskId, [int]$DeliveryNum, [string]$WorkName,
        [string]$State, [string]$Review, [string]$Elapsed, [string]$Notes,
        [string[]]$Findings, [string[]]$Dispatches
    )
    $pd = Pad3 $DeliveryNum
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Task State -- $TaskId")
    $lines.Add('')
    $lines.Add("> **Task:** $TaskId")
    $lines.Add("> **Delivery:** delivery-$pd")
    $lines.Add("> **Work:** $WorkName")
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Task State')
    $lines.Add('')
    $lines.Add("<!-- AUTHORED -- written ONLY by ``writeback-state.sh --task-id NNN --field State --value VALUE``.")
    $lines.Add("     State enum (closed; single source of truth):")
    $lines.Add("       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled")
    $lines.Add("     SD-2 ordering (most-advanced wins on reconcile):")
    $lines.Add("       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending -->")
    $lines.Add('')
    $lines.Add("- **State:** $State")
    $lines.Add("- **Review:** $Review")
    $lines.Add("- **Elapsed:** $Elapsed")
    $lines.Add("- **Notes:** $Notes")
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Quick Check Findings')
    $lines.Add('')
    $lines.Add("<!-- AUTHORED -- written by ``writeback-state.sh --task-id NNN --findings ...`` -->")
    $lines.Add('')
    if ($null -ne $Findings -and $Findings.Count -gt 0) {
        foreach ($f in $Findings) { $lines.Add($f) }
        # Trim trailing blank lines from findings block.
        while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
            $lines.RemoveAt($lines.Count - 1)
        }
    } else {
        $lines.Add('_none_')
    }
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Dispatch Log')
    $lines.Add('')
    $lines.Add('<!-- AUTHORED -- appended by the dispatcher on subagent completion. -->')
    $lines.Add('')
    $lines.Add('| Date | Agent | ETA Band | Actual | Outcome |')
    $lines.Add('|------|-------|----------|--------|---------|')
    if ($null -ne $Dispatches -and $Dispatches.Count -gt 0) {
        foreach ($d in $Dispatches) { $lines.Add($d) }
    }
    [System.IO.File]::WriteAllLines($OutFile, $lines, [System.Text.Encoding]::ASCII)
}

function Write-DeliverySpec {
    param(
        [string]$OutFile,
        [int]$DeliveryNum, [string]$WorkName,
        [hashtable[]]$TaskRows
    )
    $pd = Pad3 $DeliveryNum
    $today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Delivery SPEC -- delivery-$pd")
    $lines.Add('')
    $lines.Add("> **Delivery:** delivery-$pd")
    $lines.Add("> **Work:** $WorkName")
    $lines.Add("> **Created:** $today")
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Objective')
    $lines.Add('')
    $lines.Add('(Migrated from monolithic work STATE.md -- populate from PLAN.md or work SPEC.md.)')
    $lines.Add('')
    $lines.Add('## Scope')
    $lines.Add('')
    $lines.Add('(Migrated -- see work PLAN.md or REQUIREMENTS.md for full scope.)')
    $lines.Add('')
    $lines.Add('**Out of scope:** --')
    $lines.Add('')
    $lines.Add('## Gate Criteria')
    $lines.Add('')
    $lines.Add('(Migrated -- see original delivery gate block below for the gate outcome.)')
    $lines.Add('')
    $lines.Add('- [ ] All tasks in this delivery complete.')
    $lines.Add('- [ ] All section-6 quality gates pass.')
    $lines.Add('')
    $lines.Add('## Tasks')
    $lines.Add('')
    $lines.Add('| Task | Type | Title |')
    $lines.Add('|------|------|-------|')
    if ($null -ne $TaskRows -and $TaskRows.Count -gt 0) {
        foreach ($r in $TaskRows) { $lines.Add("| $($r.Id) | $($r.Type) | $($r.Title) |") }
    } else {
        $lines.Add('| _none_ | | |')
    }
    $lines.Add('')
    $lines.Add('## Dependencies')
    $lines.Add('')
    $lines.Add('- **Depends on:** -- (none)')
    $lines.Add('- **Blocks:** -- (none)')
    $lines.Add('')
    $lines.Add('## Notes')
    $lines.Add('')
    $lines.Add('Migrated by migrate-work-hierarchy.ps1 from monolithic layout.')
    [System.IO.File]::WriteAllLines($OutFile, $lines, [System.Text.Encoding]::ASCII)
}

function Write-DeliveryState {
    param(
        [string]$OutFile,
        [int]$DeliveryNum, [string]$WorkName,
        [string[]]$GateBlock, [string[]]$QaBlock, [string]$Lifecycle
    )
    $pd = Pad3 $DeliveryNum
    $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Delivery State -- delivery-$pd")
    $lines.Add('')
    $lines.Add("> **Delivery:** delivery-$pd")
    $lines.Add("> **Work:** $WorkName")
    $lines.Add("> **Branch:** aid/work-NNN-delivery-$pd  (fill in work number)")
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Delivery Lifecycle')
    $lines.Add('')
    $lines.Add('<!-- AUTHORED -- SD-8 enum; independently authored (SD-9). -->')
    $lines.Add('')
    $lines.Add("- **State:** $Lifecycle")
    $lines.Add("- **Updated:** $now")
    $lines.Add('- **Block Reason:** --')
    $lines.Add('- **Block Artifact:** --')
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Delivery Gate')
    $lines.Add('')
    $lines.Add("<!-- AUTHORED -- written via ``writeback-state.sh --delivery-id NNN --block ...``. -->")
    $lines.Add('')
    if ($null -ne $GateBlock -and $GateBlock.Count -gt 0) {
        foreach ($g in $GateBlock) { $lines.Add($g) }
        # Trim trailing blank lines from gate block.
        while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
            $lines.RemoveAt($lines.Count - 1)
        }
    } else {
        $lines.Add('- **Reviewer Tier:** --')
        $lines.Add('- **Grade:** Pending')
        $lines.Add('- **Issue List:** --')
        $lines.Add('- **Timestamp:** --')
    }
    $lines.Add('')
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('## Cross-phase Q&A')
    $lines.Add('')
    $lines.Add('<!-- AUTHORED -- delivery-scoped Q&A (SD-5); single writer: this delivery branch. -->')
    $lines.Add('')
    if ($null -ne $QaBlock -and $QaBlock.Count -gt 0) {
        foreach ($q in $QaBlock) { $lines.Add($q) }
        # Ensure trailing blank line before separator.
        if ($lines[$lines.Count - 1] -ne '') { $lines.Add('') }
    } else {
        $lines.Add('_none_')
        $lines.Add('')
    }
    $lines.Add('---')
    $lines.Add('')
    $lines.Add('<!-- DERIVED / READ-ONLY VIEWS')
    $lines.Add('     The Tasks State section below is assembled at READ TIME from per-task STATE.md files.')
    $lines.Add('     It is NEVER written directly into this file. -->')
    $lines.Add('')
    $lines.Add('## Tasks State')
    $lines.Add('')
    $lines.Add('<!-- DERIVED -- read-only rollup from tasks/task-NNN/STATE.md at read time. Never written here. -->')
    $lines.Add('')
    $lines.Add('| # | Task | Type | Wave | State | Review | Elapsed | Notes |')
    $lines.Add('|---|------|------|------|-------|--------|---------|-------|')
    $lines.Add('| _derived_ | | | | | | | |')
    [System.IO.File]::WriteAllLines($OutFile, $lines, [System.Text.Encoding]::ASCII)
}

function Rewrite-WorkState {
    param([string]$SrcFile, [string]$DstFile, [string[]]$WorkQA)
    $srcLines = Get-Content -LiteralPath $SrcFile -Encoding UTF8
    $out = [System.Collections.Generic.List[string]]::new()
    $skip = $false
    $derivedEmitted = $false

    $droppedSections = @(
        '## Tasks Status', '## Tasks State',
        '## Delivery Gates', '## Cross-phase Q&A',
        '## Quick Check Findings', '## Dispatches',
        '## Calibration Log'
    )

    foreach ($line in $srcLines) {
        if ($droppedSections -contains $line) {
            $skip = $true
            continue
        }
        if ($line -eq '## Lifecycle History') {
            if ($skip -and -not $derivedEmitted) {
                $skip = $false
                $derivedEmitted = $true
                Emit-DerivedBlock -Lines $out -WorkQA $WorkQA
            }
            $out.Add($line)
            continue
        }
        if (-not $skip) { $out.Add($line) }
    }

    # If Lifecycle History was never encountered, emit derived block at end.
    if (-not $derivedEmitted) {
        $out.Add('')
        Emit-DerivedBlock -Lines $out -WorkQA $WorkQA
    }

    [System.IO.File]::WriteAllLines($DstFile, $out, [System.Text.Encoding]::ASCII)
}

function Emit-DerivedBlock {
    param([System.Collections.Generic.List[string]]$Lines, [string[]]$WorkQA)
    $Lines.Add('## Tasks State')
    $Lines.Add('')
    $Lines.Add('<!-- DERIVED -- read-only; assembled from delivery-NNN/tasks/task-NNN/STATE.md at read time. Never written here. -->')
    $Lines.Add('')
    $Lines.Add('| # | Task | Type | Wave | State | Review | Elapsed | Notes |')
    $Lines.Add('|---|------|------|------|-------|--------|---------|-------|')
    $Lines.Add('| _derived_ | | | | | | | |')
    $Lines.Add('')
    $Lines.Add('## Plan / Deliveries')
    $Lines.Add('')
    $Lines.Add('<!-- DERIVED -- read-only rollup from delivery-NNN/STATE.md at read time. Never written here. -->')
    $Lines.Add('')
    $Lines.Add('| Delivery | State | Tasks | Notes |')
    $Lines.Add('|----------|-------|-------|-------|')
    $Lines.Add('| _derived_ | | | |')
    $Lines.Add('')
    $Lines.Add('## Delivery Gates')
    $Lines.Add('')
    $Lines.Add('<!-- DERIVED -- union of delivery-NNN/STATE.md ## Delivery Gate blocks at read time. Never written here. -->')
    $Lines.Add('')
    $Lines.Add('_See delivery-NNN/STATE.md for each delivery gate block._')
    $Lines.Add('')
    $Lines.Add('## Cross-phase Q&A')
    $Lines.Add('')
    $Lines.Add('<!-- DERIVED (delivery-scoped entries) + AUTHORED (work-owner entries only).')
    $Lines.Add('     Delivery-scoped Q&A lives in delivery-NNN/STATE.md (SD-5).')
    $Lines.Add('     Work-owner Q&A below was not delivery-scoped in the legacy file. -->')
    $Lines.Add('')
    if ($null -ne $WorkQA -and $WorkQA.Count -gt 0) {
        foreach ($q in $WorkQA) { $Lines.Add($q) }
        if ($Lines[$Lines.Count - 1] -ne '') { $Lines.Add('') }
    }
}

# ---------------------------------------------------------------------------
# Main migration logic
# ---------------------------------------------------------------------------

# Resolve work dir.
$WorkDir = Resolve-Path -LiteralPath $WorkDir | Select-Object -ExpandProperty Path
$WorkName = Split-Path -Leaf $WorkDir

Log "Migrating: $WorkDir"

# Input validation.
if (-not (Test-Path -LiteralPath $WorkDir -PathType Container)) {
    Die "'$WorkDir' is not a directory." 1
}
$stateFile = Join-Path $WorkDir 'STATE.md'
if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
    Die "'$stateFile' not found." 2
}
$tasksDir = Join-Path $WorkDir 'tasks'
if (-not (Test-Path -LiteralPath $tasksDir -PathType Container)) {
    Die "'$tasksDir' not found." 3
}

# Gather task files.
$taskFiles = Get-ChildItem -LiteralPath $tasksDir -Filter 'task-*.md' | Sort-Object Name
if ($taskFiles.Count -eq 0) {
    Die "No task files found in '$tasksDir'." 3
}

# IDEMPOTENCY CHECK.
$existing = @(Get-ChildItem -LiteralPath $WorkDir -Recurse -Filter 'STATE.md' |
    Where-Object { $_.FullName -match '[/\\]delivery-\d+[/\\]tasks[/\\]task-\d+[/\\]STATE\.md' })
if ($existing.Count -gt 0) {
    Log "IDEMPOTENT: hierarchy already present in '$WorkName'. No-op."
    exit 0
}

Log "Tasks found: $($taskFiles.Count)"

# Read STATE.md lines once.
$stateLines = Get-Content -LiteralPath $stateFile -Encoding UTF8

# ---------------------------------------------------------------------------
# Pass 1: resolve delivery placement for each task.
# ---------------------------------------------------------------------------
$taskDelivery = @{}   # task_id -> delivery_number
$taskTitle    = @{}   # task_id -> title
$taskType     = @{}   # task_id -> type
$allDeliveries = [System.Collections.Generic.List[int]]::new()

foreach ($tf in $taskFiles) {
    $taskId = $tf.BaseName

    $deliveryNum = Resolve-DeliveryToken -TaskFile $tf.FullName
    if ($null -eq $deliveryNum) {
        Warn "Task '${taskId}': no parseable delivery token in Source line -- defaulting to delivery-001"
        Log "  [WARNING] Task ${taskId}: no parseable delivery token; defaulted to delivery-001"
        $deliveryNum = 1
    }
    $taskDelivery[$taskId] = $deliveryNum

    $content = Get-Content -LiteralPath $tf.FullName -Encoding UTF8
    $typeLine = $content | Where-Object { $_ -match '^\*\*Type:\*\*' } | Select-Object -First 1
    if ($typeLine) {
        $taskType[$taskId] = ($typeLine -replace '^\*\*Type:\*\*\s*', '').Trim()
    } else {
        $taskType[$taskId] = '--'
    }

    $titleLine = $content | Where-Object { $_ -match "^# $taskId" } | Select-Object -First 1
    if ($titleLine) {
        $taskTitle[$taskId] = ($titleLine -replace "^# ${taskId}:\s*", '').Trim()
    } else {
        $taskTitle[$taskId] = '(no title)'
    }

    if (-not $allDeliveries.Contains($deliveryNum)) {
        $allDeliveries.Add($deliveryNum)
    }
}

Log "Deliveries detected: $($allDeliveries -join ' ')"

# ---------------------------------------------------------------------------
# Pass 2: create per-task directories with SPEC.md + STATE.md.
# ---------------------------------------------------------------------------
foreach ($tf in $taskFiles) {
    $taskId = $tf.BaseName
    $deliveryNum = $taskDelivery[$taskId]
    $pd = Pad3 $deliveryNum
    $taskDestDir = Join-Path $WorkDir "delivery-$pd\tasks\$taskId"

    Log "Creating $taskDestDir/"

    if (-not $DryRun) {
        [void](New-Item -ItemType Directory -Path $taskDestDir -Force)
    }

    # task SPEC.md -- verbatim copy.
    if (-not $DryRun) {
        Copy-Item -LiteralPath $tf.FullName -Destination (Join-Path $taskDestDir 'SPEC.md')
    } else {
        Log "DRY-RUN: would copy $($tf.FullName) -> $taskDestDir\SPEC.md"
    }

    # Extract mutable cells.
    $fields = Get-TaskRowFields -StateLines $stateLines -TaskId $taskId
    $findings  = Get-TaskFindings   -StateLines $stateLines -TaskId $taskId
    $dispatches = Get-TaskDispatches -StateLines $stateLines -TaskId $taskId

    if (-not $DryRun) {
        Write-TaskState `
            -OutFile (Join-Path $taskDestDir 'STATE.md') `
            -TaskId $taskId -DeliveryNum $deliveryNum -WorkName $WorkName `
            -State $fields.State -Review $fields.Review `
            -Elapsed $fields.Elapsed -Notes $fields.Notes `
            -Findings $findings -Dispatches $dispatches
    } else {
        Log "DRY-RUN: would write $taskDestDir\STATE.md"
    }
}

# ---------------------------------------------------------------------------
# Pass 3: create per-delivery directories with SPEC.md + STATE.md.
# ---------------------------------------------------------------------------
foreach ($deliveryNum in $allDeliveries) {
    $pd = Pad3 $deliveryNum
    $deliveryDir = Join-Path $WorkDir "delivery-$pd"
    Log "Creating $deliveryDir/"

    if (-not $DryRun) {
        [void](New-Item -ItemType Directory -Path $deliveryDir -Force -ErrorAction SilentlyContinue)
    }

    # Build task rows for this delivery.
    $taskRows = @()
    foreach ($tf in $taskFiles) {
        $tid = $tf.BaseName
        if ($taskDelivery[$tid] -eq $deliveryNum) {
            $taskRows += @{ Id = $tid; Type = $taskType[$tid]; Title = $taskTitle[$tid] }
        }
    }

    if (-not $DryRun) {
        Write-DeliverySpec `
            -OutFile (Join-Path $deliveryDir 'SPEC.md') `
            -DeliveryNum $deliveryNum -WorkName $WorkName `
            -TaskRows $taskRows
    } else {
        Log "DRY-RUN: would write $deliveryDir\SPEC.md"
    }

    $gateBlock = Get-DeliveryGate -StateLines $stateLines -DeliveryNum $deliveryNum
    $qaBlock   = Get-DeliveryQA  -StateLines $stateLines -DeliveryNum $deliveryNum

    # Derive SD-8 lifecycle.
    $hasTasksD = $taskRows.Count -gt 0
    if (-not $hasTasksD) {
        $lifecycle = 'Pending-Spec'
    } elseif ($gateBlock.Count -eq 0) {
        $lifecycle = 'Executing'
    } else {
        $gradeLine = $gateBlock | Where-Object { $_ -match '^\- \*\*Grade:\*\*' } | Select-Object -First 1
        if ($gradeLine) {
            $gradeVal = ($gradeLine -replace '^\- \*\*Grade:\*\*\s*', '').Trim()
        } else {
            $gradeVal = ''
        }
        if ($gradeVal -eq 'Pending' -or [string]::IsNullOrWhiteSpace($gradeVal)) {
            $lifecycle = 'Executing'
        } else {
            $lifecycle = 'Done'
        }
    }

    if (-not $DryRun) {
        Write-DeliveryState `
            -OutFile (Join-Path $deliveryDir 'STATE.md') `
            -DeliveryNum $deliveryNum -WorkName $WorkName `
            -GateBlock $gateBlock -QaBlock $qaBlock -Lifecycle $lifecycle
    } else {
        Log "DRY-RUN: would write $deliveryDir\STATE.md"
    }
}

# ---------------------------------------------------------------------------
# Pass 4: verify per-unit files, then rewrite work STATE.md.
# ---------------------------------------------------------------------------
Log "Verifying per-unit files..."

if (-not $DryRun) {
    foreach ($tf in $taskFiles) {
        $taskId = $tf.BaseName
        $pd = Pad3 $taskDelivery[$taskId]
        $specFile  = Join-Path $WorkDir "delivery-$pd\tasks\$taskId\SPEC.md"
        $stateF    = Join-Path $WorkDir "delivery-$pd\tasks\$taskId\STATE.md"
        if (-not (Test-Path -LiteralPath $specFile) -or (Get-Item $specFile).Length -eq 0) {
            Die "Verification: '$specFile' is missing or empty." 4
        }
        if (-not (Test-Path -LiteralPath $stateF) -or (Get-Item $stateF).Length -eq 0) {
            Die "Verification: '$stateF' is missing or empty." 4
        }
    }
    foreach ($deliveryNum in $allDeliveries) {
        $pd = Pad3 $deliveryNum
        $specFile = Join-Path $WorkDir "delivery-$pd\SPEC.md"
        $stateF   = Join-Path $WorkDir "delivery-$pd\STATE.md"
        if (-not (Test-Path -LiteralPath $specFile) -or (Get-Item $specFile).Length -eq 0) {
            Die "Verification: '$specFile' is missing or empty." 4
        }
        if (-not (Test-Path -LiteralPath $stateF) -or (Get-Item $stateF).Length -eq 0) {
            Die "Verification: '$stateF' is missing or empty." 4
        }
    }
}

Log "Verification passed. Rewriting work STATE.md..."

$workQA = Get-WorkQA -StateLines $stateLines

if (-not $DryRun) {
    Rewrite-WorkState -SrcFile $stateFile -DstFile $stateFile -WorkQA $workQA
} else {
    Log "DRY-RUN: would rewrite $stateFile with derived-view placeholders"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Log "Migration complete: $WorkName"
Log "  Deliveries created: $($allDeliveries.Count) ($($allDeliveries -join ' '))"
Log "  Tasks migrated: $($taskFiles.Count)"

if ($Warnings.Count -gt 0) {
    Log "  Warnings ($($Warnings.Count)):"
    foreach ($w in $Warnings) { Log "    [WARNING] $w" }
} else {
    Log "  Warnings: none"
}
