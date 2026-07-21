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
  - `_aid_scan_roots()` — canonical `<root>`, else whole-machine. **Windows drive enumeration
    (design sub-step for this task):** detect Windows via the same `uname -s` MINGW*/MSYS*/CYGWIN*
    idiom `bin/aid` already uses (`_dc_is_windows`, ~:1128) and shell out to the always-present
    `powershell.exe -NoProfile -Command` running `[System.IO.DriveInfo]::GetDrives()` filtered on
    `DriveType` (Fixed by default; `Network`/`Removable` opt-in) — the SAME classifier task-002's
    pwsh twin uses natively, so classification is identical by construction (AC-2); follow the
    existing bash→Windows-tool shell-out pattern (`MSYS_NO_PATHCONV=1`, ~:1151-1159) and map each
    `X:\` to its MSYS `/x/` form for the walk. On Unix there is NO drive enumeration — the single
    root is `/`. Do NOT use `wmic logicaldisk` (deprecated / absent on current Windows 11).
  - `_aid_scan_walk()` — recursive pruned walk that emits `.aid/` candidate roots and honors the
    heavy/cache prune-set (basename-anywhere), the OS/system set (root-only), unreadable-skip,
    symlink guard, and `--depth`.
- Add TWO shared name-set constants (the single source task-002's pwsh twin must match
  byte-for-byte): `_AID_SCAN_PRUNE_DIRS` (NFR-2, heavy/cache — matched by BASENAME at any depth)
  and `_AID_SCAN_SYSTEM_DIRS` (NFR-3, OS/system — matched ROOT-ONLY, i.e. only as an immediate
  child of a drive/filesystem root, so an ordinary `dev/`/`run/` subfolder is never falsely pruned).
- Wire `scan` into the `_cmd_projects` action `case` and the top-level `projects` dispatch action
  list (`list|add|remove|scan|help`, ~:3265). EXTEND the `_cmd_projects` while-loop (~:2510-2527)
  to ACCEPT the scan-specific flags — `--dry-run`, `--include-network`, `--include-removable`
  (valueless) and `--depth <n>` (consumes its value, `shift 2`) — and route them to the `scan`
  dispatch; GATE them to `scan` (a scan-specific flag passed to `list`/`add`/`remove` is a usage
  error, exit 2). Without this edit the loop's `-*` arm rejects them before scan runs. Add the
  `aid projects scan …` lines to `_aid_usage projects`.
- **Tier forcing (FR-9):** in `_cmd_projects_scan`, before registering each candidate, set
  `_AID_TIER_OVERRIDE="--local"` (force USER tier) unless the user passed `--shared` (then
  `"--shared"`); NEVER leave the auto-rule to choose, so a global install can never elevate via
  `_aid_priv_run`→`sudo` on an out-of-`$HOME` project. This is a documented USE of the existing
  override convention (~:1517-1523); `_aid_resolve_tier` is reused unchanged.
- Reuse UNCHANGED (do not reimplement): `_aid_is_project_dir`, `_registry_read_raw_union`,
  `_aid_resolve_tier`, `registry_register`, `_aid_project_state`. Register-only: never call
  `_aid_scaffold_bare_project`, `_aid_migrate_repo`, or any manifest/tool writer.

**Acceptance Criteria:**
- [ ] `aid projects scan <root>` over a fixture tree registers each folder that contains a `.aid/`
  and it then appears in `aid projects list`; no host tool is installed and no file inside the
  discovered `.aid/` is created or modified (AC-1, NFR-7).
- [ ] With no `<root>`, `_aid_scan_roots` yields the local FIXED drives (or `/` on Unix) and
  excludes network + removable drives unless `--include-network` / `--include-removable` is given
  (AC-2, AC-9).
- [ ] A non-directory `<root>` exits 2; a non-integer `--depth` (e.g. `--depth abc`) AND a negative
  `--depth` (e.g. `--depth -1`) each exit 2 (`<n>` must be a non-negative integer); `--depth <n>`
  prevents any directory deeper than `n` levels below the root from being visited (AC-3).
- [ ] `--dry-run` prints the would-register list, leaves the target `registry.yml` byte-unchanged
  (absent stays absent), and exits 0 (AC-4).
- [ ] A project already in the registry is reported as already-registered and not duplicated
  (set-insert idempotent across re-runs); a folder with no `.aid/` is neither scaffolded nor
  registered (AC-5).
- [ ] Each discovered project's version is reported via `_aid_project_state` (semver with any
  `-beta.N` suffix, or `untracked` for a missing/invalid manifest, never an error) (AC-6).
- [ ] The final summary prints the newly-registered and already-registered counts plus one
  `path  version  action` line per project; a long scan emits at least one progress line to stderr
  (AC-7, NFR-6).
- [ ] Over a fixture with an unreadable directory, a `node_modules`/`.git`/known-cache directory
  matched by basename at any depth (NFR-2), an OS/system-named directory at a scan root (skipped)
  plus the same name nested deeper as an ordinary subfolder (NOT pruned) (NFR-3), and a
  directory-symlink cycle, the walk skips the unreadable directory and continues, does not descend
  into the basename-matched heavy/cache directories, skips only the root-level OS/system directory
  while still discovering the project under the deeper same-named subfolder, and terminates
  (AC-8, NFR-1..NFR-4).
- [ ] A discovered project is auto-registered in the USER tier because scan forced
  `_AID_TIER_OVERRIDE="--local"` before calling `registry_register`; with a simulated global install
  and an out-of-`$HOME` path, the default (and `--local`) run triggers NO `sudo`/`_aid_priv_run`
  shared-dir probe, while `--shared` takes the shared-tier path exactly as `aid projects add --shared`
  (AC-13, FR-9).
- [ ] Exit code is 0 on a completed scan and 2 on a usage/argument error (including a scan-specific
  flag passed to `list`/`add`/`remove`); the summary goes to stdout and diagnostics/progress to
  stderr (AC-11 bash side).
- [ ] `aid projects -h` documents the `scan` action, its flags, and its default whole-machine
  scope (AC-12 bash side).
- [ ] All section-6 quality gates pass.
