# task-002: Mirror the scan subcommand in the PowerShell twin (`bin/aid.ps1`)

[!NOTE]
This is the TASK-LEVEL DETAIL.md — the IMMUTABLE DEFINITION for this task in a flattened (Lite)
work. Written once; not a state file. This flattened work has NO per-task `STATE.md`; each task's
mutable cells live in the work-root `STATE.md § ## Delivery Lifecycle → ### Tasks lifecycle`.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-019-discover-projects -> delivery-001

**Depends on:** task-001

**Scope:**
- Add `Invoke-AidProjectsScan` to `bin/aid.ps1` as a behavior-exact mirror of task-001's
  `_cmd_projects_scan` (approved-verb `Invoke-Aid…` naming), plus the roots helper and the pruned
  walk helper.
- Enumerate whole-machine roots via `[System.IO.DriveInfo]::GetDrives()` filtered to
  `DriveType -eq 'Fixed'`; exclude `Network` and `Removable` drives unless `--include-network` /
  `--include-removable` is given.
- Add TWO name-set constants BYTE-IDENTICAL to task-001's Bash sets: `$script:AidScanPruneDirs`
  (NFR-2, heavy/cache — matched by basename at any depth, mirrors `_AID_SCAN_PRUNE_DIRS`) and
  `$script:AidScanSystemDirs` (NFR-3, OS/system — matched ROOT-ONLY, mirrors `_AID_SCAN_SYSTEM_DIRS`).
- Wire `'scan'` into the `Invoke-AidProjects` switch and the top-level `projects` dispatch action
  list (`bin/aid.ps1` ~:3235); add the `aid projects scan …` lines to `Show-AidUsage 'projects'`
  (ASCII-only). EXTEND the `Invoke-AidProjects` parse loop (~:2073-2090) to ACCEPT `--dry-run`,
  `--include-network`, `--include-removable` and `--depth <n>` (consume the value token) and route
  them to `scan`, GATED to `scan` (a scan-specific flag on `list`/`add`/`remove` is a usage error,
  `Exit-Aid 2`) — without this the loop's `^-` arm rejects them; keep the loop byte-behavior-identical
  to the bash twin. Flags use the same double-dash spelling as the existing `projects` group
  (`--dry-run`, `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`,
  `--verbose`).
- **Tier forcing (FR-9):** in `Invoke-AidProjectsScan`, compute
  `$tierOverride = if ($shared) { '--shared' } else { '--local' }` and pass it to
  `Resolve-AidTier -TierOverride $tierOverride` for every candidate — default is USER tier and the
  auto-rule never runs. (The pwsh twin has no global tier var; `-TierOverride` is the existing
  parameter threaded through `Invoke-AidProjectsAdd`/`Resolve-AidTier`.) Mirrors task-001's bash
  forcing behavior exactly.
- Reuse UNCHANGED (do not reimplement): `Test-AidIsProjectDir`, `Get-RegistryRawUnion`,
  `Resolve-AidTier`, `Registry-Register`, `Get-AidProjectState`. Register-only: never call the
  scaffold/migrate/manifest writers.

**Acceptance Criteria:**
- [ ] For the same fixture tree used in task-001, `bin/aid.ps1` registers each `.aid/` folder, dedupes
  already-registered projects, reports versions (`untracked` for a missing/invalid manifest),
  previews under `--dry-run` without writing, and produces the same summary shape — matching the
  Bash twin (AC-1, AC-4, AC-5, AC-6, AC-7).
- [ ] `$script:AidScanPruneDirs` (heavy/cache, basename-anywhere) and `$script:AidScanSystemDirs`
  (OS/system, root-only) are each byte-identical to the Bash `_AID_SCAN_PRUNE_DIRS` /
  `_AID_SCAN_SYSTEM_DIRS`; the drive classifier excludes `Network`/`Removable` drives by default and
  includes them only with the opt-in flags (AC-2, AC-8, AC-9).
- [ ] A non-directory `<root>` exits 2; a non-integer `--depth` AND a negative `--depth` each exit 2
  (`<n>` must be a non-negative integer); `--depth <n>` bounds the walk depth — identical to the Bash
  twin (AC-3).
- [ ] `Invoke-AidProjectsScan` forces the USER tier by passing `-TierOverride '--local'` to
  `Resolve-AidTier` by default (auto-rule never runs), so a simulated global install + out-of-`$HOME`
  path registers in the user tier with no elevation; `--shared` takes the shared path exactly as
  `aid projects add --shared` — matching the Bash twin (AC-13, FR-9).
- [ ] Exit code is 0 on a completed scan and 2 on a usage error (including a scan-specific flag passed
  to `list`/`add`/`remove`); result to stdout, diagnostics/progress to stderr; the twin passes
  `tests/canonical/ps51-compat-check.ps1` (ASCII-only, WinPS 5.1 compatible) (AC-11 pwsh side).
- [ ] `aid projects -h` documents the `scan` action, its flags, and its default whole-machine scope
  in the PowerShell twin (AC-12 pwsh side).
- [ ] No file under any discovered project's `.aid/` is created or modified by the PowerShell twin
  (register-only; only the machine `registry.yml` changes on a real run) (NFR-7).
- [ ] All section-6 quality gates pass.
