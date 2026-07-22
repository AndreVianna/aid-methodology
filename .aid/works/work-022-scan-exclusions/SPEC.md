# Scan Directory Exclusions And User-Configurable Prune Set

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | SPEC authored from REQUIREMENTS.md (shortcut: aid-change-cli) | /aid-change-cli |

## Source

- REQUIREMENTS.md §1 Objective, §2 Problem Statement — feature intent
- REQUIREMENTS.md §4 Scope — in/out boundaries + accepted gaps
- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-8)
- REQUIREMENTS.md §6 Non-Functional Requirements (NFR-1..NFR-6)
- REQUIREMENTS.md §7 Constraints, §8 Assumptions & Dependencies
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-13)
- REQUIREMENTS.md §10 Priority

## Description

`aid projects scan` crawls the filesystem for `.aid/` project markers and registers each
in the machine project registry. Its directory-prune sets are too small, so a real-machine
scan descends into tool-cache/build/IDE/OS trees and registers false positives. This change
(1) expands both built-in prune tiers in the two CLI twins, kept byte-identical, and (2)
adds a user-level `scan-config.yml` at the CLI state home, seeded with the expanded Tier-A
defaults, that the scan reads once and additively merges (extend-only, case-insensitive
union) with the built-in Tier-A set. Tier B (the dangerous root-only OS set) stays
built-in only. Everything else about the scan — flags, scope model, tier forcing, dedupe,
symlink/max-depth guards, register-only contract — is unchanged.

## User Stories

- As an AID CLI user, I want `aid projects scan` to skip tool-cache, build, IDE, and OS
  directories, so it stops registering false-positive projects on my real machine.
- As an AID CLI user, I want to add my own machine-specific directory names to the prune
  set without editing the CLI, so an unusual local cache tree is excluded too.
- As an AID maintainer, I want the two twins' prune sets and config parsing to stay
  byte-identical and proven by the parity suite, so discovery behaves the same on every host.

## Priority

Must.

## Acceptance Criteria

- [ ] Given both twins, when their Tier-A sets are compared, then each contains the current
  20 names plus every §5 Tier-A addition, byte-identical across twins. (AC-1)
- [ ] Given both twins, when their Tier-B sets are compared, then each contains the current
  set plus every §5 Tier-B addition, byte-identical across twins. (AC-2)
- [ ] Given a fixture directory named `node_modules`/`.pnpm-store`/`.pytest_cache`/`.next`/
  `.vscode`/`.cursor`/`.pyenv`/`cache`/`tmp`/`AppData`/`User Data` with a stray `.aid/`
  inside, when a HOME-default scan runs, then the subtree is pruned and the stray `.aid/`
  is not registered. (AC-3)
- [ ] Given an `--all` root with an immediate child named `ProgramData`/`PerfLogs`/
  `Windows.old`/`$WinREAgent`, when scanned, then the child is pruned root-only; the same
  name deeper, or under HOME-default/`--path`, is NOT pruned by Tier B. (AC-4)
- [ ] Given a directory named `build`/`bin`/`.vscode` that DOES contain a valid `.aid/`,
  when scanned, then it IS discovered (is-project check precedes name-prune). (AC-5)
- [ ] Given no `scan-config.yml`, when a non-`--dry-run` scan runs, then a `scan-config.yml`
  is seeded beside `registry.yml` with `schema: 1` + a `prune_dirs:` block list of the
  expanded Tier-A defaults; under `--dry-run` no file is created. (AC-6)
- [ ] Given a `scan-config.yml` adding a non-built-in name, when scanned over a tree
  containing that directory + stray `.aid/`, then it is pruned; built-in defaults still
  prune. (AC-7)
- [ ] Given a `scan-config.yml` repeating a built-in name, when scanned, then behavior is
  unchanged (deduped union, no error). (AC-8)
- [ ] Given no / unreadable / `prune_dirs`-less config, when scanned, then exit 0 using the
  built-in set with no config error. (AC-9)
- [ ] Given an identical config + fixture, when both twins scan, then they read the same
  entries (including a spaced `- Code Cache`), produce the identical discovered set, and
  exit identically; `test-aid-cli-parity.sh` asserts it. (AC-10)
- [ ] Given the walk, when profiled, then the config is read + merged set computed exactly
  once per run, with no per-directory fork introduced. (AC-11)
- [ ] Given the edited twins, when `ps51-compat-check.ps1` runs, then it passes; bash arrays
  remain valid with spaced entries quoted. (AC-12)
- [ ] Given the change ships, when the CLI reference / install help / release-tracking are
  read, then the exclusion behavior + `scan-config.yml` are documented and `## Unreleased`
  carries a `[CHANGE]` entry. (AC-13)

---

## Technical Specification

> Grounded by reading `bin/aid` ~:60-99, ~:1460-1528, ~:2932-3317 and `bin/aid.ps1`
> ~:86-133, ~:1572-1616, ~:2099-2433. Reference KB: `module-map.md` (CLI module),
> `architecture.md § the CLI installer`, `coding-standards.md` (shell/PowerShell
> conventions, exit codes, cross-platform), `technology-stack.md` (bash-4 / pwsh-5.1).

### Data Model

Three shapes, one of them new.

**1. Tier-A built-in prune set (edit).** `bin/aid` global constant
`readonly -a _AID_SCAN_PRUNE_DIRS` (~:2948) and `bin/aid.ps1`
`Set-Variable -Name AidScanPruneDirs -Option Constant -Scope Script` (~:2115). Matched by
BASENAME at ANY depth, CASE-INSENSITIVELY, in ALL scan modes (home default, `--path`,
`--all`). The membership test is `_aid_scan_name_in_set` (~:2971, bash `${var,,}` builtin
lowercase — no fork) / `Test-AidScanNameInSet` (~:2136, `StringComparison.OrdinalIgnoreCase`).
Current 20 entries:

```
node_modules .git .hg .svn obj bin logs target dist build
.venv venv __pycache__ .gradle .m2 .cargo .npm .cache vendor Pods
```

Expanded set = current 20 + every §5 Tier-A addition (the additions span VCS, package
caches, build outputs, editors, AI tools, Eclipse, version managers, generic cache, temp,
OS profile roots, macOS volume junk, browser/webview caches, and `log`; REQUIREMENTS §5 is
the authoritative name list). The two twins'
arrays MUST list the same names in the same order (the header-comment byte-identity
mandate at `bin/aid` ~:2939-2941 / `bin/aid.ps1` ~:2106-2108). Entries with internal
spaces (`User Data`, `Code Cache`, `Service Worker`) are double-quoted in bash and
single-quoted in pwsh; there is no leading-`$` entry in Tier A.

**2. Tier-B built-in system set (edit).** `bin/aid` `readonly -a _AID_SCAN_SYSTEM_DIRS`
(~:2955) / `bin/aid.ps1` `AidScanSystemDirs` (~:2123). Applied ONLY under `--all` and
ONLY as an immediate child of a filesystem/drive root (walk step c2: `_is_all -eq 1 &&
_depth -eq 1`, `bin/aid` ~:3139 / `bin/aid.ps1` ~:2286). Current set:

```
proc sys dev run Windows "Program Files" "Program Files (x86)" $Recycle.Bin "System Volume Information"
```

Expanded set = current + §5 Tier-B additions. Windows entries with a leading `$`
(`$WinREAgent`, `$WINDOWS.~BT`, `$WINDOWS.~WS`) and internal spaces (`Temporary Internet
Files`) must be single-quoted in bash (to suppress variable expansion) and single-quoted
in pwsh; byte-identical name lists across twins. Tier B is NOT user-configurable.

**3. User-level scan config `scan-config.yml` (new).** A YAML file living beside
`registry.yml` under the CLI state home. Same simple shape as `registry.yml` (a `schema:`
marker + a top-level block list), so the twins reuse the identical line-scan parser:

```yaml
# scan-config.yml - user-level directory-prune list for `aid projects scan`.
# Names here are ADDED to the CLI's built-in exclusion set (case-insensitive,
# EXACT basename, matched at any depth). Extend-only: a built-in default cannot
# be removed here. One `- <name>` per line. Names with spaces need no quotes.
schema: 1
prune_dirs:
  - node_modules
  - .git
  # ... the full expanded Tier-A defaults, seeded on first run ...
  - Code Cache
  - Service Worker
```

- **Location / resolution (FR-8).** Primary `$AID_STATE_HOME/scan-config.yml`; when
  `$AID_STATE_HOME != $HOME/.aid` (global install), also read the
  `$HOME/.aid/scan-config.yml` fallback tier and UNION both — mirroring `_registry_read_union`
  / `Get-RegistryUnion` (`bin/aid` ~:1485-1502; `bin/aid.ps1` ~:1596-1616), including their
  per-user collapse (when the two paths are equal, single-tier read, no double-read).
  `$AID_STATE_HOME` is derived once at startup (`bin/aid` ~:65-71:
  `AID_STATE_HOME="${AID_HOME:-${HOME}/.aid}"` user / `/var/lib/aid` global; `bin/aid.ps1`
  ~:100-107: `$script:_AidStateHome` = `$HOME/.aid` user / `Join-Path $env:ProgramData 'aid'`
  (i.e. `$ProgramData\aid`) global — the pwsh twin's global default is NOT `/var/lib/aid`).
- **Schema field:** `schema: 1` (mirrors `registry.yml` DM-1). `prune_dirs:` is a block
  list of directory basenames.
- **Merge (FR-4, extend-only):** effective Tier-A set = built-in `_AID_SCAN_PRUNE_DIRS` ∪
  `prune_dirs` entries, deduped case-insensitively. No entry can DISABLE a built-in default.
- **Fallback (FR-5):** if the file is absent, unreadable, or has no `prune_dirs:` key, the
  effective set is exactly the built-in expanded Tier-A set; no error is raised.
- **Read-only during walk:** `prune_dirs` is parsed ONCE per run; the merged set is
  materialized once (NFR-1). The file is written only by the first-run seeder (below).

No change to the registry file schema, the manifest, or `settings.yml`.

### Feature Flow

```
aid projects scan [--path <folder>|--all] [--dry-run] [--depth N] ...   (flags unchanged)
        │
        ▼
 (1) parse args/flags                                            (unchanged — work-019)
        │
        ▼
 (2) resolve scan roots (_aid_scan_roots / Get-AidScanRoot)      (unchanged)
        │
        ▼
 (3) read registry ONCE into a set                               (unchanged)
        │
        ▼
 (3b) NEW — resolve effective Tier-A prune set, ONCE:
        merged = built-in _AID_SCAN_PRUNE_DIRS
               ∪ read_prune_dirs($AID_STATE_HOME/scan-config.yml
                                 [+ $HOME/.aid/scan-config.yml fallback tier])
        (case-insensitive dedupe; absent/unreadable/no-key ⇒ built-in only)   (FR-4/FR-5)
        store merged in a run-scoped variable the walk reads
        │
        ▼
 (3c) NEW — seed scan-config.yml when absent AND not --dry-run:
        write "# header\nschema: 1\nprune_dirs:\n  - <built-in defaults>"
        best-effort: WARN-and-continue on write failure; never overwrite an
        existing file; never write under --dry-run                    (FR-3/NFR-3)
        │
        ▼
 (4) for each root: recursive walk; per-folder FIXED order (NFR-9, unchanged EXCEPT
     step (c) now tests the MERGED set):
        ├─ (a) unreadable  ─► skip                                            (NFR-1)
        ├─ (b) is-project  ─► CANDIDATE + prune subtree      (precedes (c); AC-5)
        ├─ (c) basename ∈ MERGED Tier-A set (any depth, all modes) ─► prune   (FR-1/FR-4)
        ├─ (c2) --all only, depth 1, basename ∈ Tier-B set ─► prune           (FR-2)
        └─ (d) else recurse (symlink guard, --depth, _AID_SCAN_MAX_DEPTH=40)
        │
        ▼
 (5) register NEW candidates only / would-register under --dry-run   (unchanged)
        │
        ▼
 (6) progress to stderr; (7) summary to stdout; exit 0 / 2           (unchanged)
```

Key flow rules:

- **One read, one merge (NFR-1/AC-11).** Step 3b reads `scan-config.yml` and builds the
  merged array exactly once — the same "read the registry ONCE" discipline (`bin/aid`
  ~:3227-3233) and once-canonicalized state-home paths (`bin/aid` ~:3247-3249). The walk's
  step (c) tests the merged array with the existing fork-free `_aid_scan_name_in_set` /
  `Test-AidScanNameInSet`; no fork or file read is added per directory.
- **Passing the merged set to the walk.** In bash the merged array is a `local` of
  `_cmd_projects_scan`, visible to `_aid_scan_walk_node` via bash dynamic scoping and
  inheritance into each root's process-substitution subshell (the same mechanism already
  used for `_scan_dir_count`, `_scan_state_home_canon`; see `bin/aid` ~:3084-3087,
  ~:3241-3258). In pwsh it is threaded as a new parameter on `Invoke-AidScanWalk` /
  `Invoke-AidScanWalkNode` (like `-Candidates` / `-StateHomeCanon`, `bin/aid.ps1`
  ~:2225-2234, ~:2302-2303).
- **Seeding is a write, so it obeys the dry-run and fire-and-continue rules.** Under
  `--dry-run` the scan makes NO writes (work-019 FR-4/AC-4) — the seeder is skipped. On a
  real run, the seeder writes only if the file is absent; a write failure emits a `WARN`
  to stderr and continues (mirroring `registry_register`'s contract, `bin/aid` ~:1751-1799)
  and does not fail the scan.
- **Extend-only, forward-compatible.** Because the merge is a union, a config seeded by an
  older CLI (missing names a newer CLI added to the built-in set) still gets the newer
  built-ins applied (NFR-4). A `prune_dirs` entry equal to a built-in is deduped (AC-8).
- **Tier B unchanged, root-only, `--all`-only.** The Tier-B expansion is purely additive
  to the built-in constant; step c2's gating (`_is_all && depth==1`) is untouched, so the
  new OS names prune only as immediate children of a drive/filesystem root under `--all`
  (AC-4).

### Layers & Components

All changes land in the two CLI entrypoints (KB `module-map.md` → CLI module). The
install-core libs, the profile `read-setting.sh`, and `settings.yml` need NO change.

**Bash — `bin/aid`:**

| Element | Kind | Notes |
|---|---|---|
| `_AID_SCAN_PRUNE_DIRS` (~:2948) | edit | Append every §5 Tier-A addition to the `readonly -a` array. Quote spaced entries (`"User Data"`, `"Code Cache"`, `"Service Worker"`). Keep byte-identical to the pwsh set. Update the header comment count if it names one. |
| `_AID_SCAN_SYSTEM_DIRS` (~:2955) | edit | Append every §5 Tier-B addition. Single-quote leading-`$` entries (`'$WinREAgent'`, `'$WINDOWS.~BT'`, `'$WINDOWS.~WS'`) and spaced entries (`"Temporary Internet Files"`). Byte-identical to the pwsh set. |
| `_AID_SCAN_CONFIG` | new constant/local | Resolves to `${AID_STATE_HOME}/scan-config.yml` (primary) with `${HOME}/.aid/scan-config.yml` fallback tier — reuse the exact primary/fallback + per-user-collapse pattern of `_registry_read_union` (~:1485-1496). |
| `_aid_scan_read_prune_dirs()` | new helper | Line-scans `prune_dirs:` block-list items from the config file(s), reusing the `registry.yml` idiom (`grep -E '^[[:space:]]*-[[:space:]]+'` + `sed` trim, cf. `_registry_read_repos` ~:1466-1472) — but scoped to the `prune_dirs:` block only (enter on the bare `prune_dirs:` line, leave at the next column-0 key), and NOT stripping internal spaces so `Code Cache` survives. Returns one name per line; empty when the file/key is absent. No `yq`. |
| `_aid_scan_merge_prune_dirs()` | new helper | Emits the case-insensitive deduped union of `_AID_SCAN_PRUNE_DIRS` and `_aid_scan_read_prune_dirs`. Called ONCE by `_cmd_projects_scan`; result stored in a run-scoped `local -a _scan_prune_dirs`. |
| `_aid_scan_seed_config()` | new helper | If the primary `scan-config.yml` is absent, writes the header + `schema: 1` + `prune_dirs:` block of the built-in defaults via the atomic-write idiom `registry_register` uses (temp file + move; `bin/aid` ~:1751-1799). Best-effort: WARN-and-continue on failure. Never called under `--dry-run`. |
| `_cmd_projects_scan()` (~:3186) | edit | After the once-read registry (step 3): call `_aid_scan_seed_config` unless `_dry_run -eq 1`; then set `local -a _scan_prune_dirs; readarray -t _scan_prune_dirs < <(_aid_scan_merge_prune_dirs)`. No other change to its orchestration. |
| `_aid_scan_walk_node()` (def ~:3081; step (c) body ~:3131) | edit | Step (c) tests `_aid_scan_name_in_set "$_base" "${_scan_prune_dirs[@]}"` (the merged run-scoped array) instead of the built-in `_AID_SCAN_PRUNE_DIRS` constant. `_scan_prune_dirs` reaches the walk via the same dynamic-scoping/subshell-inheritance path as `_scan_dir_count` / `_scan_state_home_canon`. Steps (a), (b), (c2), (d) are unchanged; step (b) still precedes (c) so AC-5 holds. |
| Reused unchanged | — | `_aid_scan_name_in_set` (fork-free membership), `_aid_scan_roots`, `_aid_scan_walk`, `_aid_is_project_dir`, `_registry_read_raw_union`, `_aid_resolve_tier`, `registry_register`, `_aid_project_state`. |

**PowerShell — `bin/aid.ps1` (mirror):**

| Element | Kind | Notes |
|---|---|---|
| `$script:AidScanPruneDirs` (~:2115) | edit | Append the same §5 Tier-A additions in the same order; single-quote spaced entries (`'User Data'`, `'Code Cache'`, `'Service Worker'`). Byte-identical to the bash set. |
| `$script:AidScanSystemDirs` (~:2123) | edit | Append the same §5 Tier-B additions; single-quote leading-`$` and spaced entries. Byte-identical to the bash set. |
| `Get-AidScanConfigPath` | new | `Join-Path $script:_AidStateHome 'scan-config.yml'` primary + `Join-Path (Join-Path $HOME '.aid') 'scan-config.yml'` fallback, with the `GetFullPath`-compare per-user collapse mirroring `Get-RegistryUnion` (~:1609-1615). |
| `Get-AidScanPruneDirFromConfig` | new | Line-scans the `prune_dirs:` block list reusing the registry regex `'^\s*-\s+(.+\S)\s*$'` (`Get-RegistryRepos` ~:1579), scoped to the `prune_dirs:` block; keeps internal spaces. Returns `[string[]]`, empty when absent. |
| `Get-AidScanMergedPruneDirs` | new | Case-insensitive deduped union of `$script:AidScanPruneDirs` + config entries (e.g. via a `HashSet[string]` with `OrdinalIgnoreCase`, like `Get-RegistryUnion`). Returns `[string[]]`, computed once. |
| `Set-AidScanConfigSeed` | new | Writes the seed file when absent, via the `Move-Item -Force` atomic-write idiom the registry writer uses; best-effort (`6>$null` / try-catch WARN-and-continue). Never under `-DryRun`. |
| `Invoke-AidProjectsScan` (~:2333) | edit | After the once-read registry: unless `$DryRun`, call `Set-AidScanConfigSeed`; then `$mergedPrune = Get-AidScanMergedPruneDirs` and pass it into `Invoke-AidScanWalk`. |
| `Invoke-AidScanWalk` / `Invoke-AidScanWalkNode` (~:2311, ~:2225) | edit | Add a `[string[]]$PruneDirs` parameter (threaded like `-Candidates`/`-StateHomeCanon`); step (c) tests `Test-AidScanNameInSet -Name $base -Set $PruneDirs`. Other steps unchanged. |
| Reused unchanged | — | `Test-AidScanNameInSet`, `Get-AidScanRoot`, `Test-AidIsProjectDir`, `Get-RegistryRawUnion`, `Resolve-AidTier`, `Registry-Register`, `Get-AidProjectState`. |

**Tests — `tests/canonical/test-aid-cli-parity.sh`:** extend the existing `PAR019` scan
block (or add a `PAR022` block) that pins `$HOME` / `$AID_STATE_HOME` at a fixture root
(and `USERPROFILE`/`HOMEDRIVE`/`HOMEPATH` for the native pwsh twin — the repo's
test-isolation rule) and asserts: the new Tier-A names prune at any depth in all modes; a
Tier-B name prunes only at `--all` depth-1; a `build`/`bin`/`.vscode` project is still
discovered; a seeded/edited `scan-config.yml` extends the prune set; both twins read an
identical config identically. Reference: KB `test-landscape.md` (this suite is the
CLI-twin CI gate) and `quality-gates.md`.

<!-- Conditional section — new user-level config file + first-run seeding. -->

### Configuration

- **File:** `scan-config.yml` at the CLI state home (`$AID_STATE_HOME`, i.e. `~/.aid` on a
  per-user install; on a global install `/var/lib/aid` for the bash twin and `$ProgramData\aid`
  for the pwsh twin, or the `AID_HOME` override) — beside `registry.yml`. Machine-level, NOT per-project (`aid projects scan` is
  machine-wide; there is no project cwd for it to key on) — this is the SPEC decision that
  resolves the REQUIREMENTS §4/§7 constraint.
- **Format:** YAML with a `schema: 1` marker and a `prune_dirs:` block list of directory
  basenames, one `- <name>` per line. Chosen over a bare newline list so it (a) matches the
  neighboring `registry.yml` shape (a `schema:` field + a block list), (b) is parseable by
  the exact line-scan idiom the twins already use for `registry.yml` — no new dependency,
  identical on both twins — and (c) leaves room for future keys under the same file.
- **Precedence:** built-in expanded Tier-A defaults are always the baseline; config
  `prune_dirs` entries are UNIONed on top (extend-only, deduped, case-insensitive). No
  config, or a config lacking `prune_dirs:`, yields exactly the built-in set.
- **Resolution across tiers:** primary `$AID_STATE_HOME/scan-config.yml` unioned with the
  `$HOME/.aid/scan-config.yml` fallback tier when the two differ (global install),
  collapsing to a single read when equal — identical to the registry union.
- **Not configurable:** Tier B (OS/system, root-only, `--all`-only) — kept built-in.

### Migration Plan

- **No data migration.** No existing on-disk artifact changes shape. `registry.yml`,
  `settings.yml`, and the manifest are untouched.
- **First-run seeding.** On the first real (non-`--dry-run`) scan after this ships, the
  scan creates `$AID_STATE_HOME/scan-config.yml` populated with the built-in expanded
  Tier-A defaults, giving the user a discoverable, editable knob. Idempotent — never
  overwrites an existing file, so a user's edits survive every later scan. Best-effort —
  a write failure is a `WARN` and the scan continues using the in-memory built-in set.
- **Backward compatibility.** Machines with no config behave exactly as before except for
  the larger built-in defaults. Because the merge is additive (never replace), a config
  seeded by an older CLI stays valid and forward-compatible (NFR-4). Rolling back the CLI
  leaves `scan-config.yml` in place as an inert, human-readable YAML file an older CLI
  simply ignores.
