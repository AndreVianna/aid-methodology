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
  walk helper. The walk MUST mirror `_aid_scan_walk`'s FIXED per-folder order on each folder `D`
  (NFR-9): (a) `D` unreadable → skip (NFR-1); (b) ELSE `D` is-project (`Test-AidIsProjectDir`) →
  emit CANONICAL candidate (`Resolve-Path` / `[System.IO.Path]::GetFullPath`, the idiom the pwsh
  twin already uses at `~:129-133`, NFR-10) and PRUNE `D`'s whole subtree — no recursion into
  ANY child (NFR-9); (c) ELSE `D`'s basename in the prune set (anywhere, case-insensitive — NFR-2,
  ALL modes) → PRUNE `D`; (c2) ELSE **only under `--all`**, `D` an immediate child of a
  filesystem/drive root in the OS/system set (root-only — NFR-3) → PRUNE `D` (NOT applied under the
  HOME default or `--path`, so a top-level `~/dev`/`<--path>/dev` is descended); (d) ELSE recurse
  into `D`'s children (symlink guard, `--depth`, and the hard `$script:AidScanMaxDepth` cap),
  applying (a)-(d) to each. The (b)-before-(c) order FOR THE SAME FOLDER keeps an exclusion-named
  project (`bin`/`obj`/`logs`) discoverable (NFR-9).
- Resolve scan roots by scope, mirroring task-001's bash helper: **default (no scope flag)** = the
  user HOME directory (reuse the `$HOME` idiom the pwsh twin already uses for state-home/tier —
  `~:99-108`, `Resolve-AidTier` `~:1667`; native Windows PowerShell derives `$HOME` from the user
  profile / `%USERPROFILE%`), NO drive enumeration; **`--path <folder>`** = that folder (replaces
  the former positional `<root>`), NO drive enumeration; **`--all`** = whole-machine. On WINDOWS via
  `[System.IO.DriveInfo]::GetDrives()` filtered to `DriveType -eq 'Fixed'`, excluding `Network` and
  `Removable` drives unless `--include-network` / `--include-removable` is given. On UNIX (PowerShell
  Core) `--all` walks from `/` (all mounts); DriveType filtering is Windows-only, network/removable
  are NOT auto-excluded (documented §4 limitation), and `--include-network`/`--include-removable`
  are accepted-but-inert + emit a one-line stderr note (NFR-5). `--path` and `--all` are mutually
  exclusive (usage error, `Exit-Aid 2`).
- Add THREE constants BYTE-IDENTICAL to task-001's Bash constants: `$script:AidScanPruneDirs`
  (NFR-2, heavy/cache/build — matched by basename at any depth, CASE-INSENSITIVELY; MUST include
  the new `obj`, `bin`, `logs`; mirrors `_AID_SCAN_PRUNE_DIRS`), `$script:AidScanSystemDirs`
  (NFR-3, OS/system — applied ONLY under `--all`, ROOT-ONLY, case-insensitively; NOT applied under
  HOME/`--path`; mirrors `_AID_SCAN_SYSTEM_DIRS`), and `$script:AidScanMaxDepth` (NFR-4, the hard
  recursion ceiling distinct from `--depth`, mirrors `_AID_SCAN_MAX_DEPTH`).
- Wire `'scan'` into the `Invoke-AidProjects` switch and the top-level `projects` dispatch action
  list (`bin/aid.ps1` ~:3235); add the `aid projects scan …` lines to `Show-AidUsage 'projects'`
  (ASCII-only). EXTEND the `Invoke-AidProjects` parse loop (~:2073-2090) to ACCEPT `--all`,
  `--dry-run`, `--include-network`, `--include-removable` and `--path <folder>` / `--depth <n>`
  (consume the value token) and route them to `scan`. `--path` REPLACES the former positional
  `<root>` (there is no positional argument). Enforce the same argument validation as the bash
  twin (usage error, `Exit-Aid 2`): `--path` together with `--all` (mutually exclusive), and
  `--include-network` / `--include-removable` WITHOUT `--all` (they extend the `--all` drive set
  only). GATE the scan-specific flags to `scan` (a scan-specific flag on `list`/`add`/`remove` is a
  usage error, `Exit-Aid 2`) — without this the loop's `^-` arm rejects them; keep the loop
  byte-behavior-identical to the bash twin. Flags use the same double-dash spelling as the existing
  `projects` group (`--path`, `--all`, `--dry-run`, `--depth`, `--include-network`,
  `--include-removable`, `--local`/`--shared`, `--verbose`).
- **Tier forcing (FR-9):** in `Invoke-AidProjectsScan`, compute
  `$tierOverride = if ($shared) { '--shared' } else { '--local' }` and pass it to
  `Resolve-AidTier -TierOverride $tierOverride` for every candidate — default is USER tier and the
  auto-rule never runs. (The pwsh twin has no global tier var; `-TierOverride` is the existing
  parameter threaded through `Invoke-AidProjectsAdd`/`Resolve-AidTier`.) Mirrors task-001's bash
  forcing behavior exactly.
- **Dedupe + register-only writes (NFR-10 / FR-5):** hold a run-scoped set of canonical keys so each
  real project is considered once (NFR-10); read the registry ONCE via `Get-RegistryRawUnion` and
  call `Registry-Register` ONLY for candidates NOT already in that set — an already-registered
  project is skipped with ZERO change to its record. Reuse `Registry-Register` UNCHANGED; do NOT
  reimplement the writer to batch — per-new-project registration is the chosen approach.
  Mirrors task-001 exactly.
- Reuse UNCHANGED (do not reimplement): `Test-AidIsProjectDir`, `Get-RegistryRawUnion`,
  `Resolve-AidTier`, `Registry-Register`, `Get-AidProjectState`. Register-only: never call the
  scaffold/migrate/manifest writers.

**Acceptance Criteria:**
- [ ] For the same fixture tree used in task-001, `bin/aid.ps1` registers each `.aid/` folder, dedupes
  already-registered projects (skipped with ZERO change to their record — no
  re-tier/rewrite/reorder), reports versions (`untracked` for a missing/invalid manifest), previews under `--dry-run`
  without writing, and produces the same summary shape — matching the Bash twin
  (AC-1, AC-4, AC-5, AC-6, AC-7).
- [ ] With no scope flag the roots helper yields the user HOME directory (`$HOME`;
  `%USERPROFILE%` on Windows) with no drive enumeration, matching the Bash twin (AC-2).
  `$script:AidScanPruneDirs` (heavy/cache/build, basename-anywhere, case-insensitive, ALL modes,
  incl. `obj`/`bin`/`logs`), `$script:AidScanSystemDirs` (OS/system, `--all`-only + root-only), and
  `$script:AidScanMaxDepth` (hard depth cap) are each byte-identical to the Bash
  `_AID_SCAN_PRUNE_DIRS` / `_AID_SCAN_SYSTEM_DIRS` / `_AID_SCAN_MAX_DEPTH`. A top-level `dev`/`run`
  under a HOME/`--path` root is DESCENDED (system set is `--all`-only, so not pruned there), and only
  under `--all` is an OS/system child of a true filesystem/drive root skipped (NFR-3). On Windows
  `--all` the drive classifier excludes `Network`/`Removable` by default and includes them only with
  the opt-in flags; on Unix `--all` the walk descends all mounts under `/` and the opt-in flags are
  inert + emit a one-line note; `--include-network` / `--include-removable` WITHOUT `--all` exit 2 on
  both platforms (AC-2, AC-8, AC-9).
- [ ] A non-directory `--path` exits 2 (there is no positional `<root>`); `--path` together with
  `--all` exits 2 (mutually exclusive); a non-integer `--depth` AND a negative `--depth` each exit 2
  (`<n>` must be a non-negative integer); `--depth <n>` bounds the walk depth — identical to the Bash
  twin (AC-3).
- [ ] `Invoke-AidProjectsScan` forces the USER tier by passing `-TierOverride '--local'` to
  `Resolve-AidTier` by default (auto-rule never runs), so a simulated global install + out-of-`$HOME`
  path registers in the user tier with no elevation; `--shared` takes the shared path exactly as
  `aid projects add --shared` — matching the Bash twin (AC-13, FR-9).
- [ ] Exit code is 0 on a completed scan and 2 on a usage error (including a scan-specific flag passed
  to `list`/`add`/`remove`); result to stdout, diagnostics/progress to stderr; the twin passes
  `tests/canonical/ps51-compat-check.ps1` (ASCII-only, WinPS 5.1 compatible) (AC-11 pwsh side).
- [ ] `aid projects -h` documents the `scan` action, its flags (`--path`, `--all`, `--dry-run`,
  `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`, `--verbose`), and its
  scope model (home by default; `--path <folder>`; `--all` for the whole machine) in the PowerShell
  twin (AC-12 pwsh side).
- [ ] No file under any discovered project's `.aid/` is created or modified by the PowerShell twin
  (register-only; only the machine `registry.yml` changes on a real run) (NFR-7).
- [ ] The walk prunes a found project's whole subtree (a nested `.aid/` / nested project is NOT
  separately registered) while an exclusion-named project (`bin`/`obj`/`logs`) IS still discovered —
  identical to the Bash twin (AC-14, NFR-9).
- [ ] The same real project reached more than once (a directory symlink to an already-walked
  project, or an overlapping/`.`-`..` path) is canonicalized (`Resolve-Path`/`GetFullPath`) and
  registered EXACTLY ONCE — identical to the Bash twin (AC-15, NFR-10).
- [ ] The CLI's own state home (`$HOME/.aid` / `$AID_STATE_HOME`) is never registered, and only a
  path whose `.aid/` is a directory passing `Test-AidIsProjectDir` is registered — identical to the
  Bash twin (AC-16, FR-5).
- [ ] All section-6 quality gates pass.
