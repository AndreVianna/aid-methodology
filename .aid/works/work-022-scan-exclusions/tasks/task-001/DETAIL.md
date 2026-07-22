# task-001: Expand both twins' prune sets and add the user-level config read, merge, and seed

[!NOTE]
This is the TASK-LEVEL DETAIL.md — the IMMUTABLE DEFINITION for this task in a flattened (Lite)
work. Written once; not a state file. This flattened work has NO per-task `STATE.md`; each task's
mutable cells live in the work-root `STATE.md § ## Delivery Lifecycle → ### Tasks lifecycle`.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-022-scan-exclusions -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Edit `bin/aid` `_AID_SCAN_PRUNE_DIRS` (~:2948) and `bin/aid.ps1`
  `$script:AidScanPruneDirs` (~:2115): append every REQUIREMENTS §5 Tier-A addition on top
  of the current 20, in the same order in both twins, quoting spaced entries (`"User Data"`
  / `'User Data'`, `"Code Cache"` / `'Code Cache'`, `"Service Worker"` / `'Service Worker'`).
- Edit `bin/aid` `_AID_SCAN_SYSTEM_DIRS` (~:2955) and `bin/aid.ps1`
  `$script:AidScanSystemDirs` (~:2123): append every §5 Tier-B addition, single-quoting
  leading-`$` entries (`'$WinREAgent'`, `'$WINDOWS.~BT'`, `'$WINDOWS.~WS'`) and spaced
  entries (`"Temporary Internet Files"` / `'Temporary Internet Files'`). Preserve the
  header-comment byte-identity mandate (`bin/aid` ~:2939-2941 / `bin/aid.ps1` ~:2106-2108).
- Add the user-level config read + additive merge in both twins per SPEC § Layers &
  Components: resolve `scan-config.yml` at the state home with the registry-style
  primary/fallback + per-user collapse; line-scan its `prune_dirs:` block list with the
  same idiom used for `registry.yml` (`_registry_read_repos` / `Get-RegistryRepos`); union
  it case-insensitively (deduped) with the built-in Tier-A set; compute the merged set ONCE
  in `_cmd_projects_scan` / `Invoke-AidProjectsScan` and have the walk's step (c) test the
  merged set (via bash dynamic scoping / a new pwsh walk parameter). Built-in set is the
  hardcoded fallback when the config is absent/unreadable/`prune_dirs`-less.
- Seed `scan-config.yml` with the expanded Tier-A defaults on the first non-`--dry-run`
  scan when absent, best-effort (WARN-and-continue), idempotent (never overwrite), never
  under `--dry-run`, via the atomic-write idiom `registry_register` uses.
- Do NOT change scan flags, scope model, tier forcing, dedupe, symlink/max-depth guards,
  the register-only contract, `_AID_SCAN_MAX_DEPTH`=40, or Tier-B's `--all`-only root-only
  gating. Do NOT add any per-directory fork or per-directory file read.

**Acceptance Criteria:**
- [ ] Both twins' Tier-A sets equal the current 20 names plus every §5 Tier-A addition, in
  the same order, byte-identical across twins. (AC-1)
- [ ] Both twins' Tier-B sets equal the current set plus every §5 Tier-B addition, byte-
  identical across twins. (AC-2)
- [ ] The is-project check still precedes the name-prune, so a `build`/`bin`/`.vscode`
  directory containing a valid `.aid/` is still discovered. (AC-5)
- [ ] A non-`--dry-run` scan with no config seeds `$AID_STATE_HOME/scan-config.yml` with
  `schema: 1` + a `prune_dirs:` block of the expanded Tier-A defaults; a `--dry-run` scan
  creates no file; an existing config is never overwritten. (AC-6)
- [ ] The effective Tier-A set is the case-insensitive deduped union of the built-in set
  and the config `prune_dirs:` entries; a non-built-in entry prunes, a repeated built-in is
  deduped, and a missing/unreadable/`prune_dirs`-less config falls back to the built-in set
  with exit 0 and no config error. (AC-7, AC-8, AC-9)
- [ ] Both twins resolve the config from the state home (registry-style primary/fallback +
  per-user collapse), parse `prune_dirs:` identically (including a spaced `- Code Cache`),
  and the config is read + merged exactly once per run with no per-directory fork. (AC-10,
  AC-11, FR-8)
- [ ] `ps51-compat-check.ps1` passes on the edited `bin/aid.ps1`; the bash arrays remain
  valid with spaced entries quoted. (AC-12)
- [ ] All section-6 quality gates pass.
