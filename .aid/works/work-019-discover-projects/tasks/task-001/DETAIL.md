# task-001: Implement the scan subcommand in the Bash twin (`bin/aid`)

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

**Depends on:** -- (none)

**Scope:**
- Add the scan command to `bin/aid` (the reference twin): `_cmd_projects_scan()` orchestrating
  parse → roots → pruned walk → dedupe → register → report, per SPEC.md `### Feature Flow`.
- Add helpers `_aid_scan_roots()` and `_aid_scan_walk()`:
  - `_aid_scan_roots()` — resolve scan roots by scope: **default (no scope flag)** = the user
    HOME directory (reuse the `${HOME}` idiom `bin/aid` already uses for state-home/tier —
    `~:64-69`, `_aid_resolve_tier` `~:1531`; on Windows Git-Bash `${HOME}` maps to the user
    profile / `%USERPROFILE%`), a single subtree with NO drive enumeration; **`--path <folder>`** =
    that canonical folder (replaces the former positional `<root>`), again NO drive enumeration;
    **`--all`** = whole-machine, the ONLY mode that enumerates drives. **`--all` Windows drive
    enumeration (design sub-step for this task):** detect Windows via the same `uname -s`
    MINGW*/MSYS*/CYGWIN* idiom `bin/aid` already uses (`_dc_is_windows`, ~:1128) and shell out to
    the always-present `powershell.exe -NoProfile -Command` running
    `[System.IO.DriveInfo]::GetDrives()` filtered on `DriveType` (Fixed by default;
    `Network`/`Removable` opt-in) — the SAME classifier task-002's pwsh twin uses natively, so
    classification is identical by construction (AC-2); follow the existing bash→Windows-tool
    shell-out pattern (`MSYS_NO_PATHCONV=1`, ~:1151-1159) and map each `X:\` to its MSYS `/x/`
    form for the walk. Do NOT use `wmic logicaldisk` (deprecated / absent on current Windows 11).
    **`--all` on Unix (NFR-5):** there is NO drive-letter model — the single root is `/` and the
    walk descends all mounts under it; network/removable mounts are NOT auto-excluded (documented
    §4 limitation), and `--include-network` / `--include-removable` are accepted-but-inert and emit
    a one-line stderr note (Windows-only-effective). `--path` and `--all` are mutually exclusive
    (usage error, exit 2).
  - `_aid_scan_walk()` — recursive walk emitting CANONICAL `.aid/` project roots, with a FIXED
    per-folder order applied to EACH folder `D` (NFR-9 — a per-folder order, NOT a
    prune-decision made about a child before entering it): (a) if `D` is unreadable → skip +
    continue (NFR-1); (b) ELSE if `D` is a valid `.aid/` project (`_aid_is_project_dir`) → emit
    it as a candidate (canonicalized via the `cd … && pwd -P` idiom `bin/aid` already uses at
    `~:92-93`, NFR-10) and PRUNE its WHOLE subtree — do NOT recurse into ANY child (incl.
    `.aid/`), so a project nested inside another project is never separately found (NFR-9); (c) ELSE
    if `D`'s basename matches the heavy/cache set (anywhere, case-insensitive — NFR-2, applied in
    ALL modes) → PRUNE `D` (do not recurse); (c2) ELSE **only under `--all`**, if `D` is an
    immediate child of a filesystem/drive root matching the OS/system set (root-only — NFR-3) →
    PRUNE `D` (this set is NOT applied under the HOME default or `--path`, so a top-level `~/dev` /
    `<--path>/dev` is descended and any project inside it discovered); (d) ELSE recurse into `D`'s
    children (symlink guard, and BOTH the `--depth` cap and the hard `_AID_SCAN_MAX_DEPTH` cap),
    applying (a)-(d) to each. The (b)-before-(c) order FOR THE SAME FOLDER means a project whose OWN
    folder name is an exclusion (`bin`/`obj`/`logs`) is STILL discovered (NFR-9).
- Add THREE shared constants (the single source task-002's pwsh twin must match byte-for-byte):
  `_AID_SCAN_PRUNE_DIRS` (NFR-2, heavy/cache/build — matched by BASENAME at any depth,
  CASE-INSENSITIVELY, in ALL modes; MUST include the new `obj`, `bin`, `logs` alongside
  `node_modules`, `.git`, `.hg`, `.svn`, `.venv`, `venv`, `__pycache__`, `target`, `dist`, `build`,
  `.gradle`, `.m2`, `.cargo`, `.npm`, `.cache`, `vendor`, `Pods`); `_AID_SCAN_SYSTEM_DIRS` (NFR-3,
  OS/system — applied ONLY under `--all`, ROOT-ONLY i.e. only as an immediate child of a
  filesystem/drive root; NOT applied under the HOME default or `--path`, so a top-level `~/dev`/
  `run` is never falsely pruned); and `_AID_SCAN_MAX_DEPTH` (NFR-4, a large hard recursion ceiling
  DISTINCT from and INDEPENDENT of the user `--depth`, guaranteeing termination on a pathological
  tree).
- Wire `scan` into the `_cmd_projects` action `case` and the top-level `projects` dispatch action
  list (`list|add|remove|scan|help`, ~:3265). EXTEND the `_cmd_projects` while-loop (~:2510-2527)
  to ACCEPT the scan-specific flags — `--all`, `--dry-run`, `--include-network`,
  `--include-removable` (valueless) and `--path <folder>` / `--depth <n>` (each consumes its
  value, `shift 2`) — and route them to the `scan` dispatch. `--path` REPLACES the former
  positional `<root>` (there is no positional argument). Enforce argument validation (usage error,
  exit 2): `--path` together with `--all` (mutually exclusive), and `--include-network` /
  `--include-removable` WITHOUT `--all` (they extend the `--all` drive set only). GATE the
  scan-specific flags to `scan` (a scan-specific flag passed to `list`/`add`/`remove` is a usage
  error, exit 2). Without this edit the loop's `-*` arm rejects them before scan runs. Add the
  `aid projects scan …` lines to `_aid_usage projects`.
- **Tier forcing (FR-9):** in `_cmd_projects_scan`, before registering each candidate, set
  `_AID_TIER_OVERRIDE="--local"` (force USER tier) unless the user passed `--shared` (then
  `"--shared"`); NEVER leave the auto-rule to choose, so a global install can never elevate via
  `_aid_priv_run`→`sudo` on an out-of-`$HOME` project. This is a documented USE of the existing
  override convention (~:1517-1523); `_aid_resolve_tier` is reused unchanged.
- **Dedupe + register-only writes (NFR-10 / FR-5):** in `_cmd_projects_scan`, hold a run-scoped set
  of canonical keys so each real project is considered once (NFR-10); read the registry ONCE via
  `_registry_read_raw_union` (SPEC step 3) and call `registry_register` ONLY for candidates NOT
  already in that set — an already-registered project is skipped with ZERO change to its record
  (no re-tier / version rewrite / reorder). Reuse `registry_register` UNCHANGED (its internal
  `sort -u` handles final dedupe); do NOT reimplement the writer to batch — per-new-project
  registration is the chosen approach.
- Reuse UNCHANGED (do not reimplement): `_aid_is_project_dir`, `_registry_read_raw_union`,
  `_aid_resolve_tier`, `registry_register`, `_aid_project_state`. Register-only: never call
  `_aid_scaffold_bare_project`, `_aid_migrate_repo`, or any manifest/tool writer.

**Acceptance Criteria:**
- [ ] `aid projects scan --path <folder>` over a fixture tree registers each folder that contains a
  `.aid/` and it then appears in `aid projects list`; no host tool is installed and no file inside
  the discovered `.aid/` is created or modified (AC-1, NFR-7).
- [ ] With no scope flag, `_aid_scan_roots` yields the user HOME directory (`$HOME`;
  `%USERPROFILE%` on Windows) with no drive enumeration; with `--all` on Windows it yields the local
  FIXED drives and excludes network + removable unless `--include-network` / `--include-removable`
  is given; with `--all` on Unix it yields `/` and walks all mounts (network/removable NOT
  auto-excluded; `--include-network`/`--include-removable` inert + one-line stderr note);
  `--include-network`/`--include-removable` WITHOUT `--all` exit 2 on both platforms (AC-2, AC-9).
- [ ] A non-directory `--path` exits 2 (there is no positional `<root>`); `--path` together with
  `--all` exits 2 (mutually exclusive); a non-integer `--depth` (e.g. `--depth abc`) AND a negative
  `--depth` (e.g. `--depth -1`) each exit 2 (`<n>` must be a non-negative integer); `--depth <n>`
  prevents any directory deeper than `n` levels below the root from being visited (AC-3).
- [ ] `--dry-run` prints the would-register list, leaves the target `registry.yml` byte-unchanged
  (absent stays absent), and exits 0 (AC-4).
- [ ] A project already in the registry is reported as already-registered and not duplicated
  (set-insert idempotent across re-runs), and its existing registry record is left UNCHANGED — no
  re-tier, no version rewrite, no reordering; a folder with no `.aid/` is neither scaffolded
  nor registered (AC-5).
- [ ] Each discovered project's version is reported via `_aid_project_state` (semver with any
  `-beta.N` suffix, or `untracked` for a missing/invalid manifest, never an error) (AC-6).
- [ ] The final summary prints the newly-registered and already-registered counts plus one
  `path  version  action` line per project; a long scan emits at least one progress line to stderr
  (AC-7, NFR-6).
- [ ] Over a fixture with an unreadable directory, a `node_modules`/`.git`/`obj`/`bin`/`logs`/
  known-cache directory matched by basename (case-insensitively) at any depth in ALL modes (NFR-2),
  a top-level `dev`/`run` folder directly under the HOME-default/`--path` scan root holding a
  project (NFR-3 system set is `--all`-only, so this MUST be DESCENDED and the project FOUND, NOT
  pruned), a directory-symlink cycle, and a pathologically deep chain, the walk skips the unreadable
  directory and continues, does not descend into the basename-matched heavy/cache directories,
  DESCENDS the top-level `dev`/`run` under HOME/`--path` and discovers the project inside, and
  TERMINATES in every case (symlink cycle via the guard, deep chain via the hard
  `_AID_SCAN_MAX_DEPTH` cap, independent of `--depth`); and under `--all` (mocked root set) an
  OS/system-named immediate child of a true filesystem/drive root IS skipped (AC-8, NFR-1..NFR-4).
- [ ] A discovered project is auto-registered in the USER tier because scan forced
  `_AID_TIER_OVERRIDE="--local"` before calling `registry_register`; with a simulated global install
  and an out-of-`$HOME` path, the default (and `--local`) run triggers NO `sudo`/`_aid_priv_run`
  shared-dir probe, while `--shared` takes the shared-tier path exactly as `aid projects add --shared`
  (AC-13, FR-9).
- [ ] Exit code is 0 on a completed scan and 2 on a usage/argument error (including a scan-specific
  flag passed to `list`/`add`/`remove`); the summary goes to stdout and diagnostics/progress to
  stderr (AC-11 bash side).
- [ ] `aid projects -h` documents the `scan` action, its flags (`--path`, `--all`, `--dry-run`,
  `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`, `--verbose`), and
  its scope model (home by default; `--path <folder>`; `--all` for the whole machine)
  (AC-12 bash side).
- [ ] The walk prunes a found project's whole subtree: a `.aid/` (or whole project) nested inside a
  discovered project is NOT separately registered, while a project whose OWN folder name is an
  exclusion (`bin`/`obj`/`logs`) IS still discovered because the `_aid_is_project_dir` check
  precedes name-based pruning (AC-14, NFR-9).
- [ ] The same real project reached more than once (a directory symlink to an already-walked
  project, or an overlapping/`.`-`..` path) is canonicalized (`cd … && pwd -P`) and registered
  EXACTLY ONCE (AC-15, NFR-10).
- [ ] The CLI's own state home (`$HOME/.aid` / `$AID_STATE_HOME`) is never registered, and only a
  path whose `.aid/` is a directory passing `_aid_is_project_dir` is registered (AC-16, FR-5).
- [ ] All section-6 quality gates pass.
