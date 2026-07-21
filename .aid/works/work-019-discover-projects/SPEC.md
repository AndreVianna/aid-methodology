# Machine Scan to Discover and Register AID Projects

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | SPEC authored from REQUIREMENTS.md | /aid-update-cli |
| 2026-07-21 | GATE cycle-1 fixes (reviewer findings resolved) | /aid-update-cli |
| 2026-07-21 | Scope-model redesign: default = user home, `--path <folder>`, `--all` (replaced whole-machine default; positional `<root>` removed) — Description/ACs/Feature Flow/Layers/CLI-contract updated | /aid-update-cli |
| 2026-07-21 | Scan-behavior rules: NFR-9 per-folder order + subtree prune, NFR-10 canonicalize/dedupe, NFR-2 +`obj`/`bin`/`logs` (case-insensitive), `_AID_SCAN_MAX_DEPTH` hard cap, FR-5 no-change-skip + state-home guard; new AC-14/15/16 | /aid-update-cli |
| 2026-07-21 | GATE cycle-2 fixes: NFR-3 system-dir skip scoped to `--all` only; NFR-5 scoped to Windows drive model + Unix disclosed limitation; internal rule-shorthand removed | /aid-update-cli |

## Source

- REQUIREMENTS.md §1 Objective, §2 Problem Statement — feature intent
- REQUIREMENTS.md §4 Scope — in/out boundaries
- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-10)
- REQUIREMENTS.md §6 Non-Functional Requirements (NFR-1..NFR-10, guardrails)
- REQUIREMENTS.md §8 Assumptions & Dependencies — reused helpers, open points
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-16)
- REQUIREMENTS.md §10 Priority

## Description

Add an `aid` CLI subcommand (working name `aid projects scan`) that crawls the
local filesystem, finds every folder that contains a `.aid/` directory, and
registers each in the machine project registry — the same registry
`aid projects list` / `aid projects add` use. It is register-only: it never
installs, updates, or migrates a project, and it never writes inside a project's
`.aid/`. For each discovered project it reports the version read from that
project's manifest. By default it scans the user's HOME directory (`$HOME`;
`%USERPROFILE%` on Windows) with guardrails that keep the crawl safe and
terminating; `--path <folder>` narrows it to one subtree, `--all` widens it to the
whole machine (all local fixed drives on Windows; `/` on Unix — the only mode that
enumerates drives), and `--dry-run` previews the registrations without writing
anything.

## User Stories

- As an AID CLI user, I want to run one command that finds and registers every
  `.aid/` project on my machine, so that I do not have to visit each folder and run
  `aid projects add` by hand.
- As an AID CLI user, I want the scan to report each project's version without
  changing anything, so that I can decide later what to update with `aid update`.
- As an AID CLI user, I want a `--dry-run` and a `--path <folder>` narrowing option,
  so that I can preview the result and scan just one tree quickly, and an `--all` flag
  when I really do want the whole machine.
- As an AID maintainer, I want the Bash and PowerShell twins to behave identically
  under the parity suite, so that discovery works the same on every host.

## Priority

Must.

## Acceptance Criteria

- [ ] **AC-1 (FR-1).** Given a folder `P` with `P/.aid/` present, when
  `aid projects scan` runs, then `P` is registered and appears in
  `aid projects list`; no tool was installed and no file inside `P/.aid/` changed.
- [ ] **AC-2 (FR-2).** Given no scope argument, scan scans the user HOME directory
  (`$HOME`; `%USERPROFILE%` on Windows) with NO drive enumeration; given `--all`, scan
  enumerates local FIXED drives only on Windows (network + removable excluded by
  default) and walks from `/` on Unix; both twins classify drives identically.
- [ ] **AC-3 (FR-3).** Given `aid projects scan --path <folder>` with a directory
  `<folder>`, only that subtree is scanned; a non-directory `--path` exits 2 (there is
  no positional `<root>` form); `--all` together with `--path` exits 2 (mutually
  exclusive); `--depth <n>` bounds recursion to `n` levels, and BOTH a non-integer
  `--depth` (e.g. `--depth abc`) and a negative `--depth` (e.g. `--depth -1`) exit 2
  (`<n>` must be a non-negative integer), identically on both twins.
- [ ] **AC-4 (FR-4).** Given `--dry-run`, scan prints what it would register, leaves
  the target `registry.yml` byte-unchanged, and exits 0.
- [ ] **AC-5 (FR-5).** A project already registered is not added twice, is reported
  as already-registered/skipped, and its existing registry record is UNCHANGED (no
  re-tier, no version rewrite, no reordering); a folder with no `.aid/` is never
  scaffolded or registered.
- [ ] **AC-6 (FR-6).** A discovered project with `"aid_version"` reports that version
  (a `-beta.N` suffix preserved); a `.aid/` with no valid manifest reports `untracked`
  without erroring.
- [ ] **AC-7 (FR-7, NFR-6).** A completed scan reports the newly-registered count, the
  already-registered count, and one path+version+action line per project; a long scan
  emits at least one progress line to stderr.
- [ ] **AC-8 (NFR-1..NFR-4).** Over a fixture tree with an unreadable directory, a
  heavy/cache directory (`node_modules`/`.git`/`obj`/`bin`/`logs`/cache) matched by
  basename (case-insensitively) at any depth in ALL modes (NFR-2), a top-level `dev`/`run`
  folder directly under the HOME-default/`--path` scan root holding a project — which MUST
  be DESCENDED and the project FOUND (NFR-3 system set is `--all`-only, so it is NOT
  pruned here) — a directory-symlink cycle, and a pathologically deep directory chain,
  scan skips the unreadable directory and continues, does not descend into the
  basename-matched heavy/cache directories, DESCENDS the top-level `dev`/`run` under
  HOME/`--path` and discovers the project inside, and TERMINATES in every case (the
  symlink cycle via the NFR-4 guard, the deep chain via the hard `_AID_SCAN_MAX_DEPTH`
  cap, independent of `--depth`). The NFR-3 root-only skip (`--all` only, at a true
  filesystem/drive root such as `/proc`/`C:\Windows`) is asserted under the AC-2/AC-9
  `--all` mocked-root classifier.
- [ ] **AC-9 (NFR-5).** On WINDOWS `--all`, network and removable drives are excluded by
  default and included only with `--include-network` / `--include-removable`. On UNIX
  `--all`, the walk descends all mounts under `/` (network/removable NOT auto-excluded —
  documented limitation, §4) and those two flags are accepted-but-inert with a one-line
  stderr note. On both platforms the flags apply to `--all` only — passing either WITHOUT
  `--all` exits 2. Both twins behave identically per platform.
- [ ] **AC-10 (FR-8, NFR-7).** For the same fixture tree, `bin/aid` and `bin/aid.ps1`
  produce identical discovery/registration results and identical exit codes, and no
  file under any discovered project's `.aid/` is created or modified;
  `tests/canonical/test-aid-cli-parity.sh` asserts this.
- [ ] **AC-11 (NFR-8).** Exit code is 0 on a completed scan and 2 on a usage error;
  result goes to stdout and diagnostics to stderr; the PowerShell twin passes
  `ps51-compat-check.ps1`.
- [ ] **AC-12 (FR-10).** `aid projects -h` documents the new subcommand, its flags
  (`--path`, `--all`, `--dry-run`, `--depth`, `--include-network`,
  `--include-removable`, `--local`/`--shared`, `--verbose`), and its scope model (home
  by default; `--path <folder>` for a specific folder; `--all` for the whole machine)
  with byte-identical user-visible text on both twins; every user-facing CLI doc that
  enumerates the `projects` actions lists the new action;
  `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[NEW]` entry; and the
  final name reflects the approval-gate confirmation across help, docs, and tests.
- [ ] **AC-13 (FR-9).** On a GLOBAL install, a discovered project OUTSIDE `$HOME` is
  auto-registered in the USER tier with NO privilege elevation (no `sudo`, no
  `_aid_priv_run` shared-dir probe) because scan forced `_AID_TIER_OVERRIDE="--local"`
  (Bash) / `Resolve-AidTier -TierOverride '--local'` (PowerShell); `--shared` takes the
  shared path exactly as `aid projects add --shared`; both twins force/honor the tier
  identically.
- [ ] **AC-14 (NFR-9).** A valid project `P` with a nested `.aid/` (or a whole
  nested project) under it is registered exactly once and the nested `.aid/` is NOT
  separately discovered (subtree pruned); a project whose OWN folder name is an
  exclusion (`bin`/`obj`/`logs`) IS still discovered (the `.aid/` check precedes
  name-based pruning); both twins behave identically.
- [ ] **AC-15 (NFR-10).** The same real project reachable more than once (a
  directory symlink to an already-walked project, or an overlapping/`.`-`..` path) is
  canonicalized and registered EXACTLY ONCE; both twins dedupe identically.
- [ ] **AC-16 (FR-5).** The CLI's own state home (`$HOME/.aid` / `$AID_STATE_HOME`)
  is NEVER registered, and only paths whose `.aid/` is a directory passing
  `_aid_is_project_dir` / `Test-AidIsProjectDir` are registered; both twins apply the
  check identically.

---

## Technical Specification

### Data Model

No persistent schema changes. The command reuses existing shapes:

- **Registry file (unchanged).** `<state-home>/registry.yml` with
  `schema: 1` and a `projects:` YAML list of canonical base-folder paths, one
  `  - <path>` line per project. This is the exact file `_registry_read_repos` /
  `Get-RegistryRepos` parse and `registry_register` / `Registry-Register` write.
  A "registered project" is just one line-item path in this list. Scan adds paths;
  it never alters the schema, comment header, or any other field.

- **Manifest version field (read-only).** Each discovered project's version comes
  from `<proj>/.aid/.aid-manifest.json` key `aid_version` (semver, optional
  `-beta.N` suffix), read by the existing `_aid_project_state` / `Get-AidProjectState`.
  Their closed return set is `missing | no-aid | untracked | vX.Y.Z`; a discovered
  `.aid/` root resolves to `untracked` (no/invalid manifest) or the semver string.
  Scan never writes the manifest.

- **In-memory discovery record (transient, not persisted).** During a run each
  candidate is held as a tuple `{ canon_path, tier, version, action }` keyed on its
  CANONICAL absolute path (NFR-10) where
  `action ∈ { registered, already-registered, would-register }`. A run-scoped set of
  canonical keys dedupes candidates so the same real project is recorded once (NFR-10);
  the same set carries the once-read registry membership for O(1) already-registered
  detection (step 3). This drives the §Feature Flow summary report only; it is not
  written to disk (contrast the registry line-item, which is the only persisted output).

A discovered project is a filesystem path `P` such that `P/.aid/` is a DIRECTORY AND
`_aid_is_project_dir(P)` / `Test-AidIsProjectDir(P)` is true — i.e. `P/.aid` does not
resolve to the CLI state home (`$AID_STATE_HOME` or `$HOME/.aid`), which is excluded
by construction so the CLI's own state directory is never registered as a project
(FR-5/AC-16). Once `P` is identified as a project, its ENTIRE subtree is pruned — the
project's own contents (including `P/.aid/` and any nested project under `P`) are never
searched (NFR-9) — so a project nested inside another project is not separately discovered.

### Feature Flow

```
aid projects scan [--path <folder>] [--all] [--dry-run] [--depth N]
                  [--include-network] [--include-removable]
                  [--local|--shared] [--verbose]
          │
          ▼
 (1) parse args/flags  ──► bad flag / scan-only flag on a non-scan action /
                          non-dir --path / --all together with --path /
                          --include-network|--include-removable without --all /
                          non-int OR negative --depth ⇒ exit 2
          │
          ▼
 (2) determine scan roots
        default (no scope) ───► user HOME ($HOME / %USERPROFILE%); NO drive enum
        --path <folder> ──────► single canonical subtree (fast path); NO drive enum
        --all ────────────────► whole machine (the ONLY mode that enumerates drives):
                                   Windows: local FIXED drives only — network +
                                     removable excluded unless --include-network /
                                     --include-removable (bash: shell out to
                                     powershell.exe running
                                     [System.IO.DriveInfo]::GetDrives() — the SAME
                                     classifier the pwsh twin uses natively; map
                                     "X:\" ⇒ "/x/" for the MSYS walk)
                                   Unix:    "/" — walk all mounts (no drive-letter
                                     model; --include-network/--include-removable are
                                     inert + emit a one-line stderr note; NFS/removable
                                     NOT excluded — NFR-5 documented limitation)
          │
          ▼
 (3) read registry ONCE into a set  ◄── _registry_read_raw_union / Get-RegistryRawUnion
          │
          ▼
 (4) for each root: recursive walk; at EACH folder D apply this FIXED order
     (NFR-9) — the order is per-folder, NOT a decision about a child made
     before entering it:
        ├─ (a) D unreadable? ─► skip + continue                          (NFR-1)
        ├─ (b) ELSE D a valid .aid/ project (is-project-dir)?    (FR-5 / AC-16)
        │        └─ YES ─► CANDIDATE (canonicalize, NFR-10) + PRUNE D's WHOLE
        │                  subtree — do NOT recurse into ANY child of D
        │                  (a project's contents, incl. nested projects, are
        │                   never searched)                              (NFR-9)
        ├─ (c) ELSE D's BASENAME in heavy/cache set (anywhere, case-insens.,
        │        ALL modes) ─► PRUNE D (do not recurse)                  (NFR-2)
        ├─ (c2) ELSE under --all ONLY: D an immediate child of a filesystem/
        │        drive root in OS/system set ─► PRUNE D                  (NFR-3)
        │        (NOT applied under HOME default or --path — a top-level
        │         ~/dev or <--path>/dev is descended normally)
        └─ (d) ELSE recurse into D's children — skipping dir symlinks (NFR-4)
               and stopping at --depth N and hard _AID_SCAN_MAX_DEPTH
               (FR-3 / NFR-4) — applying (a)-(d) to each child
     (order matters: the project-check (b) precedes name-pruning (c) FOR THE SAME
      folder, so a project whose OWN name is bin/obj/logs is STILL found — NFR-9)
          │
          ▼
 (5) for each CANDIDATE (deduped on canonical path — NFR-10, registered once)
        ├─ version ◄── _aid_project_state / Get-AidProjectState   (FR-6)
        ├─ in registry set?  ── yes ─► action=already-registered (skip; NO change
        │                              to the existing record — no re-tier / rewrite /
        │                              reorder)                              (FR-5)
        └─ no ─► tier: FORCE user via override — _AID_TIER_OVERRIDE="--local"
                       (bash) / Resolve-AidTier -TierOverride '--local' (pwsh),
                       unless the user passed --shared (then '--shared'); NEVER the
                       auto-rule, so a global install never elevates      (FR-9)
                  │
                  ├─ --dry-run ─► action=would-register  (NO write)          (FR-4)
                  └─ else       ─► registry_register / Registry-Register     (FR-5)
                                    (reused writer, idempotent, atomic; only NEW
                                     projects write; WARN-not-fail on error) (FR-5)
                                    action=registered
          │
          ▼
 (6) periodic progress to stderr during (4)/(5)                              (NFR-6)
          │
          ▼
 (7) final summary to stdout: N registered, N already-registered,
     one "path  version  action" line each                                   (FR-7)
          │
          ▼
     exit 0   (usage errors already exited 2 at step 1/3)                     (AC-11)
```

Key flow rules:

- The registry set is read once (step 3) so dedupe is O(1) per candidate and no
  registry file is re-read mid-walk.
- **Register-only:** the only write is `registry_register` in step 5 (real run). No
  `_aid_scaffold_bare_project`, no `_aid_migrate_repo`, no manifest/tool write is ever
  called — this is the crucial divergence from `aid projects add`, which scaffolds a
  bare `.aid/` for a non-project path and may migrate an existing one. Scan registers
  ONLY folders that already contain a valid `.aid/` and touches nothing inside them
  (NFR-7).
- **Dry-run** takes the identical path except step 5's write is replaced by recording
  `would-register`; the summary is otherwise identical, so a user can trust the preview.
- **Registry-write minimization (FR-5):** the walk collects candidates and the once-read
  registry set (step 3) means only genuinely NEW projects reach a write; already-
  registered ones are pure reads. Writes reuse the tested `registry_register` /
  `Registry-Register` unchanged (register-only, idempotent). The writer is per-path, so
  a single batched write would require reimplementing its read-merge-`sort -u`-write
  logic; that reimplementation is explicitly NOT done (see § Layers & Components), so the
  chosen approach is a per-NEW-project `registry_register` call — correct and reusing the
  hardened writer, at the cost of one write per new project.
- **Project-subtree pruning (NFR-9):** once a folder is a project, its subtree is not
  searched, so an AID project nested inside another AID project's tree is intentionally
  NOT discovered (a stated §4 limitation). A project merely nested BELOW a name-excluded
  or OS-named folder (but not inside a project) is still discovered (NFR-3).
- **Canonicalize + dedupe (NFR-10):** each candidate is resolved to its canonical
  absolute path and deduped on that key, so the same real project reached twice (symlink,
  overlap, `.`/`..`) is registered at most once.

### Layers & Components

The command lands in the two CLI entrypoints; all reused helpers already live there
(the registry/version/tier/is-project helpers are defined in `bin/aid` and
`bin/aid.ps1` themselves — the install-core libs provide install/fetch/manifest logic
and need **no change** for this feature). Reference: `module-map.md` (CLI module),
`architecture.md § the CLI installer`, `coding-standards.md`.

**Bash — `bin/aid`:**

| Element | Kind | Notes |
|---|---|---|
| `_cmd_projects_scan()` | new | Orchestrates parse → roots → walk → canonical-dedupe → register → report. Sibling of `_cmd_projects_list/add/remove`. **Tier forcing (FR-9):** before registering, sets `_AID_TIER_OVERRIDE="--local"` (force user) unless the user passed `--shared` (then `"--shared"`); NEVER leaves the auto-rule to pick, so a global install can never elevate via `_aid_priv_run`→`sudo`. The override is a documented USE of the existing convention (`bin/aid` ~:1517-1523); `_aid_resolve_tier` itself is unchanged. **Dedupe (NFR-10):** holds a run-scoped set of canonical keys so each real project is considered/registered once. **Register-only writes (FR-5):** compares each candidate against the once-read registry set (`_registry_read_raw_union`, step 3) so ONLY new projects call `registry_register`; an already-registered project is skipped with NO change to its record. Reuses `registry_register` UNCHANGED (per-path writer, internally `sort -u`); a single batched write is NOT implemented because it would require reimplementing that hardened read-merge-write, so the chosen approach is per-new-project registration. |
| `_aid_scan_roots()` | new helper | Enumerates scan roots by scope: **default (no scope)** = the user HOME directory (reuse the `${HOME}` idiom `bin/aid` already uses for state-home/tier — `~:64-69`, `_aid_resolve_tier` `~:1531`; on Windows Git-Bash `${HOME}` maps to the user profile), a single subtree with NO drive enumeration; **`--path <folder>`** = that canonical folder, again NO drive enumeration; **`--all`** = whole-machine (the ONLY mode that enumerates drives). **`--all` Windows drive enumeration (FR-3/NFR-5):** the bash twin runs under Git-Bash/MSYS/Cygwin — detect via the same `uname -s` MINGW*/MSYS*/CYGWIN* idiom `bin/aid` already uses (`_dc_is_windows`, ~:1128) and shell out to the always-present `powershell.exe -NoProfile -Command` running `[System.IO.DriveInfo]::GetDrives()` filtered on `DriveType` (Fixed by default; `Network`/`Removable` opt-in) — the SAME classifier the pwsh twin uses natively, so drive classification is identical-by-construction (AC-2), following the repo's existing bash→Windows-tool shell-out pattern (`netstat`/`taskkill` with `MSYS_NO_PATHCONV=1`, ~:1151-1159). Each returned `X:\` is mapped to its MSYS `/x/` form for the walk. Under `--all` on Unix the single root is `/`. (Legacy `wmic logicaldisk` is NOT used: `wmic` is deprecated and absent on current Windows 11.) `--path` and `--all` are mutually exclusive (usage error, exit 2). |
| `_aid_scan_walk()` | new helper | Recursive/iterative walk emitting CANONICAL `.aid/` project roots. FIXED per-folder order applied to each folder D (NFR-9): (a) D unreadable → skip+continue (NFR-1); (b) ELSE D is-project (`_aid_is_project_dir`) → emit candidate (canonicalized via `cd … && pwd -P`, NFR-10) and PRUNE D's whole subtree (no recursion into ANY child, incl. `.aid/` — NFR-9); (c) ELSE D's basename ∈ `_AID_SCAN_PRUNE_DIRS` (anywhere, case-insensitive — NFR-2, ALL modes) → PRUNE D; (c2) ELSE under `--all` ONLY, D an immediate child of a filesystem/drive root ∈ `_AID_SCAN_SYSTEM_DIRS` (root-only — NFR-3) → PRUNE D (NOT applied under HOME default or `--path`, so a top-level `~/dev` is descended); (d) ELSE recurse into D's children (symlink guard NFR-4, `--depth` and hard `_AID_SCAN_MAX_DEPTH` caps), applying (a)-(d) to each. Because (b) precedes (c) FOR THE SAME FOLDER, an exclusion-named project (`bin`/`obj`/`logs`) is still found (NFR-9). |
| `_AID_SCAN_PRUNE_DIRS` | new constant | Heavy/cache/build name-set (NFR-2), matched by BASENAME at ANY depth, CASE-INSENSITIVELY. Includes `node_modules`, `.git`, `.hg`, `.svn`, `.venv`, `venv`, `__pycache__`, `target`, `dist`, `build`, `obj`, `bin`, `logs`, `.gradle`, `.m2`, `.cargo`, `.npm`, `.cache`, `vendor`, `Pods`. Byte-identical across twins. |
| `_AID_SCAN_MAX_DEPTH` | new constant | Hard safety recursion-depth ceiling (NFR-4) — a large built-in integer, DISTINCT from and INDEPENDENT of the user `--depth`; guarantees termination on a pathologically deep tree. Byte-identical across twins. |
| `_AID_SCAN_SYSTEM_DIRS` | new constant | OS/system name-set (NFR-3), applied ONLY under `--all` and only ROOT-ONLY — i.e. as an immediate child of a drive/filesystem root (`C:\`/`/`). NOT applied under the HOME default or `--path`, so a top-level `~/dev` or `<--path>/dev` is descended and never falsely pruned. Byte-identical and case-insensitive across twins. |
| `_cmd_projects` parse loop + dispatch | edit | Add `scan` to the action `case` (`list\|add\|remove\|scan\|help`); EXTEND the `_cmd_projects` while-loop (`bin/aid` ~:2510-2527) to ACCEPT the scan-specific flags — `--all`, `--dry-run`, `--include-network`, `--include-removable` (valueless) and `--path <folder>` / `--depth <n>` (each consumes its value, `shift 2`) — routing them into the `scan` dispatch. `--path` REPLACES the former positional `<root>` (there is no positional). Argument validation (usage error, exit 2): `--path` + `--all` together (mutually exclusive), and `--include-network`/`--include-removable` WITHOUT `--all` (they modify `--all` only). These flags are GATED to `scan`: passing one to `list`/`add`/`remove` is a usage error (exit 2). Without this edit the loop's `-*` arm rejects them before scan runs. |
| top-level `projects` dispatch | edit | Add `scan` to the recognized action-word list (`bin/aid` ~:3265). Scan flags after the action word already flow into `_PROJ_ARGS` and are parsed by `_cmd_projects`. |
| `_aid_usage projects` | edit | Add the `aid projects scan …` usage lines. |
| Reused unchanged | — | `_aid_is_project_dir`, `_registry_read_raw_union`, `_aid_resolve_tier`, `registry_register`, `_aid_project_state`. |

**PowerShell — `bin/aid.ps1` (mirror; every reused helper already mirrored):**

| Element | Kind | Notes |
|---|---|---|
| `Invoke-AidProjectsScan` | new | Mirror of `_cmd_projects_scan` (approved-verb `Invoke-Aid…` naming). **Tier forcing (FR-9):** computes `$tierOverride = if ($shared) { '--shared' } else { '--local' }` and passes it to `Resolve-AidTier -TierOverride $tierOverride` for every candidate — so the default is USER tier and the auto-rule never runs. (No global tier var exists in the pwsh twin; the override is the `-TierOverride` parameter already threaded through `Invoke-AidProjectsAdd`/`Resolve-AidTier`.) `Resolve-AidTier`/`Registry-Register` are unchanged. **Dedupe (NFR-10):** run-scoped canonical-key set → each real project once. **Register-only writes (FR-5):** candidates compared against the once-read `Get-RegistryRawUnion` set so only NEW projects call `Registry-Register` (reused UNCHANGED); already-registered projects are skipped with NO record change; no batched-write reimplementation. |
| `Get-AidScanRoot` (roots) + walk helper | new | Roots by scope, mirroring the bash helper: **default** = the user HOME directory (reuse the `$HOME` idiom the pwsh twin already uses for state-home/tier — `~:99-108`, `Resolve-AidTier` `~:1667`; native Windows PowerShell derives `$HOME` from the user profile), NO drive enumeration; **`--path <folder>`** = that folder, NO drive enumeration; **`--all`** = whole-machine. On WINDOWS `--all`, enumerate via `[System.IO.DriveInfo]::GetDrives()` filtered to `DriveType -eq 'Fixed'` (network=`Network`, removable=`Removable` excluded by default; `--include-network`/`--include-removable` include them) — the same enumeration the bash twin shells out to, so classification is identical (AC-2). On UNIX (PowerShell Core) `--all` walks from `/` (all mounts); DriveType filtering is Windows-only and `--include-network`/`--include-removable` are inert + emit a one-line stderr note (NFR-5 documented limitation). `--path` and `--all` are mutually exclusive (usage error, `Exit-Aid 2`). The walk mirrors `_aid_scan_walk` byte-for-behavior — FIXED per-folder order on each folder D (NFR-9): (a) unreadable→skip (NFR-1); (b) ELSE is-project (`Test-AidIsProjectDir`)→emit CANONICAL candidate (`Resolve-Path`/`[System.IO.Path]::GetFullPath`, NFR-10) and PRUNE D's whole subtree (NFR-9); (c) ELSE D's basename ∈ `$script:AidScanPruneDirs` (anywhere, case-insensitive — NFR-2, ALL modes)→PRUNE D; (c2) ELSE under `--all` ONLY, D an immediate child of a filesystem/drive root ∈ `$script:AidScanSystemDirs` (root-only — NFR-3)→PRUNE D (NOT under HOME/`--path`); (d) ELSE recurse into D's children (symlink guard NFR-4, `--depth` and `$script:AidScanMaxDepth` caps), applying (a)-(d) to each. Because (b) precedes (c) for the same folder, an exclusion-named project is still found (NFR-9). |
| `$script:AidScanPruneDirs` | new constant | Heavy/cache/build name-set (NFR-2), matched by BASENAME at any depth, CASE-INSENSITIVELY; includes `obj`, `bin`, `logs` alongside the VCS/cache names; byte-identical to the Bash `_AID_SCAN_PRUNE_DIRS`. |
| `$script:AidScanSystemDirs` | new constant | OS/system name-set (NFR-3), applied ONLY under `--all`, ROOT-ONLY (immediate child of a drive/filesystem root); NOT applied under HOME/`--path`; case-insensitive; byte-identical to the Bash `_AID_SCAN_SYSTEM_DIRS`. |
| `$script:AidScanMaxDepth` | new constant | Hard safety recursion-depth ceiling (NFR-4), distinct from `--depth`; byte-identical to the Bash `_AID_SCAN_MAX_DEPTH`. |
| `Invoke-AidProjects` parse loop + switch | edit | Add `'scan'` case → `Invoke-AidProjectsScan`; EXTEND the `Invoke-AidProjects` parse loop (`bin/aid.ps1` ~:2073-2090) to ACCEPT `--all`, `--dry-run`, `--include-network`, `--include-removable` and `--path <folder>` / `--depth <n>` (consume the value token) and route them to `scan`. `--path` REPLACES the former positional `<root>`. Same usage-error validation as the bash twin: `--path` + `--all` together, and `--include-network`/`--include-removable` without `--all`, each `Exit-Aid 2`. GATED to `scan`: passing one to `list`/`add`/`remove` is a usage error (`Exit-Aid 2`). Without this the loop's `^-` arm rejects them. Kept byte-behavior-identical to the bash loop. |
| top-level `projects` dispatch | edit | Add `'scan'` to the recognized action-word list (`bin/aid.ps1` ~:3235). Flags after the action word flow into `$_ProjArgs` and are parsed by `Invoke-AidProjects`. |
| `Show-AidUsage 'projects'` | edit | Add the `aid projects scan …` usage lines (ASCII-only). |
| Reused unchanged | — | `Test-AidIsProjectDir`, `Get-RegistryRawUnion`, `Resolve-AidTier`, `Registry-Register`, `Get-AidProjectState`. |

**Tests — `tests/canonical/test-aid-cli-parity.sh`:** a new `PAR`-prefixed block that
exercises scan over a fixture tree via the `--path` fast path (walk/prune/dedupe/
dry-run/version) plus the zero-arg HOME default (with `$HOME`/`%USERPROFILE%` pinned at
the fixture root) on both twins and asserts identical results, identical exit codes, and
no writes inside any project `.aid/`. It does NOT crawl the real machine (slow,
non-deterministic, and a test-isolation hazard); `--all` drive enumeration is
covered by asserting the roots/drive-classifier excludes network+removable given a known
drive set. Reference: `test-landscape.md` (this suite is the CLI-twin CI gate).

<!-- Conditional section — CLI command-surface, activated for a `cli` artifact. -->

### Command Surface & CLI Contract

- **Invocation (working name):** `aid projects scan [flags]` — a fourth
  action under the existing `projects` group (alongside `list`/`add`/`remove`). It
  reuses the group's dispatch, flag-parsing, and `-h` surface, EXTENDED so the shared
  `projects` parse loop accepts the scan-specific flags below and routes them to the
  `scan` action; a scan-specific flag passed to `list`/`add`/`remove` is a usage error
  (exit 2). Both twins extend their parse loop identically (see § Layers & Components).
- **Positional:** none. The default scope (no scope flag) is the user HOME directory
  (`$HOME`; `%USERPROFILE%` on Windows). The former positional `<root>` is removed —
  its behavior is now the `--path <folder>` flag.
- **Flags:**
  - `--path <folder>` — scan `<folder>`'s subtree instead of home (the fast path;
    replaces the old positional). A non-directory `<folder>` is a usage error (exit 2).
    Mutually exclusive with `--all` (FR-3).
  - `--all` — scan ALL accessible folders (the whole machine): Windows FIXED drives;
    Unix from `/`. The ONLY mode that enumerates drives. Mutually exclusive with
    `--path` (FR-3).
  - `--dry-run` — preview; write nothing (FR-4).
  - `--depth <n>` — cap recursion at `n` levels below each root; `<n>` must be a
    non-negative integer. A non-integer OR negative `<n>` is a usage error (exit 2)
    (FR-3).
  - `--include-network` — (Windows `--all` only) include network drives in the
    enumerated `--all` drive set (default: excluded). Requires `--all` on both platforms;
    without `--all` it is a usage error (exit 2). On Unix it is accepted-but-inert and
    emits a one-line stderr note (drive-type filtering is Windows-only; NFR-5).
  - `--include-removable` — (Windows `--all` only) include removable drives in the
    enumerated `--all` drive set (default: excluded). Requires `--all` on both platforms;
    without `--all` it is a usage error (exit 2). On Unix it is accepted-but-inert and
    emits a one-line stderr note (drive-type filtering is Windows-only; NFR-5).
  - `--local` / `--shared` — tier override with identical semantics to
    `aid projects add`. Scan FORCES the USER tier by default (it sets the override to
    `--local` internally) so a bulk scan never elevates; `--local` is the explicit
    form of that default, and `--shared` opts into the shared tier exactly as
    `aid projects add --shared` (FR-9).
  - `--verbose` — extra per-project / per-root detail.
  - `-h` / `--help` — the `projects` usage block.
- **Exit codes** (shared scheme, `coding-standards.md § Exit Codes`): `0` — scan
  completed (including "found nothing" and `--dry-run`); `2` — usage/argument error
  (unknown flag, scan-specific flag on a non-scan action, non-directory `--path`,
  `--path` together with `--all`, `--include-network`/`--include-removable` without
  `--all`, non-integer OR negative `--depth`). A registry write failure follows the existing
  `registry_register` contract (WARN to stderr, fire-and-continue) and does not by
  itself fail the run — parity with `aid projects add`.
- **Output** (`coding-standards.md § Logging and Output`): the summary/result on
  stdout; progress and all diagnostics on stderr, so `aid projects scan … 1>result`
  captures only the report.

### Naming Proposal

The user's tentative name `discover` collides with two existing meanings — the
`aid-discover` SKILL (connector discovery via ELICIT) and the first pipeline PHASE
"Discover" — so a CLI subcommand named `discover` that discovers *projects* would be a
third meaning of the same word.

| Option | Form | Assessment |
|---|---|---|
| `aid projects scan` | subcommand under `projects` | **Recommended.** It is intrinsically a registry operation (bulk find-and-register), so it belongs beside `projects list/add/remove`; reuses the group's dispatch + usage + flag parsing (minimal new surface); and "scan" clearly means "search the filesystem," distinct from `add` (one path) and `list` (registry read). No collision with the SKILL or the phase. |
| `aid scan` | new top-level verb | Clean and short; the fallback if a top-level command is preferred. Adds a top-level command and one more thing to learn. |
| `aid projects discover` | subcommand | Keeps the user's word but scoped under `projects`; the "discover" overload is reduced but not eliminated. |
| `aid import` | top-level | Misleading — "import" implies copying content in; this only registers. Rejected. |
| `aid find` | top-level | Too generic; connotes search-and-print, not register. Rejected. |
| `aid discover` | top-level | The user's tentative name; three-way collision. Not recommended. |

**Recommendation:** `aid projects scan`, with `aid scan` as the fallback if a
top-level command is preferred. The final choice is the user's to confirm at the
approval gate. All artifacts use `aid projects scan` as a clearly-labeled WORKING NAME;
a rename is a trivial find/replace of the subcommand string, its dispatch case, its
usage lines, and its test identifiers.
