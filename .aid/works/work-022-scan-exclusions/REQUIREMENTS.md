# Requirements

- **Name:** Scan Directory Exclusions And User-Configurable Prune Set
- **Description:** Expand the built-in directory-prune sets used by `aid projects scan` in both CLI twins and add a user-level, additively-merged exclusions config, so a HOME-default or `--all` scan on a real dev machine stops registering tool-cache, build, IDE, and OS directories as false-positive AID projects.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Initial capture (shortcut: aid-change-cli) | /aid-change-cli |

## 1. Objective

Make `aid projects scan` produce clean results on a real machine. Today the built-in
directory-prune set is too small, so a HOME-default or `--all` scan walks tens of
thousands of tool-cache/build/IDE/OS folders and registers false positives (a live run
registered 142 false positives, all under `AppData\Local\Temp` test-fixture directories
plus one under `AppData\Local\uv\cache\git-v0\checkouts`). Two coordinated fixes: (1)
expand the two built-in prune tiers in both twins, kept byte-identical; and (2) make the
Tier-A prune set user-configurable via a new user-level exclusions config that the scan
additively merges with the built-in defaults.

## 2. Problem Statement

`aid projects scan` (added in work-019) crawls the filesystem for `.aid/` project
markers and registers each. Its Tier-A heavy/cache prune set (`_AID_SCAN_PRUNE_DIRS` /
`$script:AidScanPruneDirs`) covers only 20 common names, and its Tier-B OS/system set
(`_AID_SCAN_SYSTEM_DIRS` / `$script:AidScanSystemDirs`) covers a handful of Windows/Unix
roots. On a real developer machine this misses the large modern surface of tool caches
(uv/pip/npm/pnpm/yarn/nuget), build outputs (`.next`, `.turbo`, coverage), IDE/AI-tool
state (`.vscode`, `.idea`, `.cursor`, `.claude`), version-manager homes (`.pyenv`,
`.nvm`, `.rustup`), browser/webview caches, OS profile roots (`AppData`, `Library`), and
temp trees — so the walk descends into them, wastes time, and registers `.aid/` markers
that testing fixtures and tool checkouts leave behind. The prune set is also hardcoded:
a user who knows their own machine has no way to add a name without editing the CLI.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID CLI user | Runs `aid projects scan` on a personal or shared dev machine | Accurate discovery with no false positives; a way to add machine-specific exclusions without editing the CLI |
| AID maintainer | Maintains the two CLI twins (`bin/aid`, `bin/aid.ps1`) | The two name sets stay byte-identical; parity + guardrail tests prove identical behavior |
| Tech writer / docs owner | Keeps the CLI reference current | Scan exclusions + the new config file are documented in the CLI reference and release ledger |

## 4. Scope

### In Scope

- Expand the Tier-A (heavy/cache/build, any-depth, all-modes) built-in prune set in
  both twins with the additions enumerated in §5, kept byte-identical.
- Expand the Tier-B (OS/system, `--all`-only, root-only) built-in set in both twins with
  the additions enumerated in §5, kept byte-identical.
- Add a user-level exclusions config file under the CLI state home, seeded with the
  expanded Tier-A defaults, read once per scan and additively merged (extend-only,
  case-insensitive union, deduped) with the built-in Tier-A set.
- A hardcoded built-in Tier-A fallback used when no config file exists.
- Parity + guardrail tests and CLI-reference / install-help / release-tracking doc
  updates.

### Out of Scope

- **Honoring `.gitignore` during the walk** — a different matching problem (per-tree,
  pattern-based); a possible future `--respect-gitignore` flag, not this change.
- **Making Tier-B (OS/system) user-configurable** — Tier B stays built-in only; it is the
  dangerous root-only OS set and is not exposed for user edits.
- **Disabling a built-in default via config** — user config is extend-only (see §5);
  removing a curated default is not supported (possible future negation syntax).
- **Glob / substring / suffix matching** — matching stays EXACT-basename, case-insensitive.
  Accepted un-fixable gaps (documented, not addressed): `cmake-build-*` and `*.egg-info`
  (varying prefix/suffix, no exact basename); the Go module cache `~/go/pkg/mod` (sits
  outside `.cache`/`AppData`, and `go`/`pkg` are too collision-prone to add).
- **Directory names deliberately excluded from the built-in defaults** (considered, rejected —
  recorded here so a later maintainer does not re-add them): `packages` (collides with the
  JS/TS monorepo `packages/<name>` convention — excluding it would hide real sibling projects);
  `site-packages` (always nested inside an already-pruned `.venv`/`venv`, so redundant); and
  `go` / `pkg` (too collision-prone with real Go project and top-level directory names — the
  reason the `~/go/pkg/mod` gap above stays accepted rather than closed). Adding any of these
  to a built-in default is a regression, not an enhancement.
- **No change to scan flags, scope model, tier forcing, dedupe, symlink/max-depth guards,
  or the register-only contract** from work-019 — this change only grows the prune sets
  and adds the config merge.

## 5. Functional Requirements

- **FR-1 — Expand Tier-A built-in set (both twins, byte-identical).** Add the following
  names to `_AID_SCAN_PRUNE_DIRS` (bash) and `$script:AidScanPruneDirs` (pwsh), on top of
  the current 20 (`node_modules .git .hg .svn obj bin logs target dist build .venv venv
  __pycache__ .gradle .m2 .cargo .npm .cache vendor Pods`):
  - VCS: `.bzr` `_darcs` `CVS`
  - Package caches: `.nuget` `.pnpm-store` `.yarn` `bower_components` `npm-cache`
    `.mypy_cache` `.pytest_cache` `.tox` `.eggs` `.ruff_cache` `.ipynb_checkpoints`
    `.ivy2` `.bundle`
  - Build outputs: `.next` `.nuxt` `.output` `.svelte-kit` `.parcel-cache` `.turbo`
    `.angular` `coverage` `.nyc_output` `htmlcov`
  - Editors: `.vscode` `.vs` `.idea` `.zed`
  - AI tools: `.cursor` `.claude` `.codex` `.windsurf` `.antigravity`
  - Eclipse: `.metadata` `.settings` `.p2` `.eclipse`
  - Version managers: `.pyenv` `.rbenv` `.nvm` `.rustup` `.dotnet` `.sdkman` `.jenv`
    `.asdf` `.volta` `mise` `.goenv` `.phpenv`
  - Generic cache: `cache` `caches` `CacheStorage`
  - Temp: `tmp` `temp` `.tmp` `.temp`
  - OS profile roots (promoted to Tier A): `AppData` (Windows), `Library` (macOS)
  - macOS volume junk: `.Trash` `.Trashes` `.Spotlight-V100` `.fseventsd`
    `.DocumentRevisions-V100`
  - Browser/webview caches: `User Data` `EBWebView` `WebView2Cache` `GPUCache`
    `Code Cache` `Service Worker` `IndexedDB` `DawnCache` `Crashpad` `GrShaderCache`
    `ShaderCache` `D3DSCache` (entries with spaces must be quoted in both twins)
  - Also: `log` (singular)
- **FR-2 — Expand Tier-B built-in set (both twins, byte-identical).** Add to
  `_AID_SCAN_SYSTEM_DIRS` / `$script:AidScanSystemDirs`, on top of the current set (`proc
  sys dev run Windows "Program Files" "Program Files (x86)" $Recycle.Bin "System Volume
  Information"`):
  - Windows: `ProgramData` `$WinREAgent` `$WINDOWS.~BT` `$WINDOWS.~WS` `Recovery`
    `PerfLogs` `Windows.old` `MSOCache` `"Temporary Internet Files"` `Recycled` `RECYCLER`
  - Linux: `Trash`
- **FR-3 — User-level exclusions config file.** Introduce a config file `scan-config.yml`
  living beside `registry.yml` under the CLI state home (`$AID_STATE_HOME` / `~/.aid`),
  containing a top-level `prune_dirs:` YAML block list. The scan seeds it with the
  expanded Tier-A defaults on the first real (non-`--dry-run`) run when it is absent
  (best-effort, WARN-and-continue on failure; never created under `--dry-run`).
- **FR-4 — Additive merge (extend-only).** On each scan the effective Tier-A prune set is
  the case-insensitive **union** of the built-in Tier-A set and any `prune_dirs:` entries
  read from the config file, deduped. User entries EXTEND the built-in set; they cannot
  disable a built-in default. Names already built-in are deduped harmlessly.
- **FR-5 — Hardcoded built-in fallback.** When no config file exists (or it is
  unreadable, or carries no `prune_dirs:` key), the scan uses exactly the built-in
  expanded Tier-A set. The scan never errors on a missing or malformed config.
- **FR-6 — Identical parse across twins.** Both twins parse `prune_dirs:` with the same
  simple line-scan idiom they already use for `registry.yml`'s `projects:` list (no YAML
  library, no `yq`), so entries — including those with internal spaces — are read
  identically on bash and PowerShell.
- **FR-7 — Preserve existing scan invariants.** Matching stays EXACT-basename,
  case-insensitive, no substring/glob. The is-project check still precedes the prune (a
  folder whose own name is a pruned name but which contains a valid `.aid/` is still
  discovered). Tier A applies at any depth in all modes; Tier B applies only under `--all`
  and only as an immediate child of a drive/filesystem root. `_AID_SCAN_MAX_DEPTH` /
  `$script:AidScanMaxDepth` stays 40. No scan flag, scope model, tier-forcing, dedupe, or
  symlink guard changes.
- **FR-8 — Config lives at the machine level, not per project.** Because
  `aid projects scan` is machine-wide, the config resolves from the CLI state home (the
  same home as `registry.yml`), NOT from any per-project `.aid/settings.yml`. Resolution
  mirrors the registry union: primary `$AID_STATE_HOME/scan-config.yml`, plus the
  `$HOME/.aid/scan-config.yml` fallback tier when the two paths differ (per-user collapse
  when they are equal).

## 6. Non-Functional Requirements

- **NFR-1 — No hot-path regression.** The config file is read and the merged set computed
  ONCE at scan start (like the once-read registry and the once-canonicalized state-home
  paths), never per directory. The per-directory membership test stays the fork-free
  case-insensitive comparison already in place (`${var,,}` in bash;
  `StringComparison.OrdinalIgnoreCase` in pwsh); no `printf|tr` or subshell per directory.
- **NFR-2 — Twin parity.** The two built-in name sets stay byte-identical (the existing
  header comment mandate), and the config-merge behavior is identical on both twins;
  `tests/canonical/test-aid-cli-parity.sh` proves it.
- **NFR-3 — Safe writes.** Config seeding is best-effort and WARN-and-continue on failure
  (mirroring `registry_register`'s fire-and-continue), is idempotent (writes only when the
  file is absent, never overwrites user edits), and never runs under `--dry-run` (a
  dry-run makes no writes at all, matching work-019 FR-4). The scan never writes inside any
  discovered project's `.aid/`.
- **NFR-4 — Forward compatibility.** Because the merge is additive union (not replace), a
  seeded config that predates a later CLI's larger built-in defaults is harmless — the
  newer built-ins are still applied. Existing scan behavior for un-configured machines is
  unchanged except for the larger built-in defaults.
- **NFR-5 — Cross-platform names.** Names with internal spaces (`User Data`, `Code Cache`,
  `Service Worker`, `Temporary Internet Files`) and leading `$` (`$Recycle.Bin`,
  `$WinREAgent`, `$WINDOWS.~BT`) are represented correctly in both twins' arrays (quoting /
  single-quoting) and, for Tier-A config entries, are read unquoted by the YAML block-list
  line-scan.
- **NFR-6 — PowerShell 5.1 compatibility.** The pwsh twin passes `ps51-compat-check.ps1`;
  the bash twin remains bash-4+ only (already required).

## 7. Constraints

- The header comment in both twins already mandates that the two name sets stay
  byte-identical — preserve it.
- No new runtime dependency: parse the config with the existing `registry.yml` line-scan
  idioms (`grep`/`sed` in bash; the `-match '^\s*-\s+(.+\S)\s*$'` regex in pwsh). No `yq`,
  no Python, no YAML library.
- The profile-level `read-setting.sh` reads a per-project `.aid/settings.yml` and is NOT
  usable here — the CLI twins are self-contained and must parse `scan-config.yml`
  themselves, at the machine-level state home.
- Author-only for this work: no production-code edits, no test runs (task DETAILs specify
  the implementation for the Execute phase).

## 8. Assumptions & Dependencies

- `aid projects scan` already exists and ships (work-019; v2.2.3-beta.2). This change
  extends it; the scan orchestrators, walk, roots, tier forcing, dedupe, and guards are
  unchanged except for the enlarged prune sets and the config merge.
- Reuses the existing `AID_STATE_HOME` derivation (`bin/aid` ~:65-71; `bin/aid.ps1`
  ~:100-103) and the `registry.yml` line-scan parsing (`_registry_read_repos` /
  `Get-RegistryRepos`).
- Additive-merge semantics mirror `discovery.term_exclusions` (an established
  extend-only, user-confirmed exclusion list), applied here to a machine-level file.
- Pruning `.cache` and `AppData` wholesale already subsumes `uv`/`pip`/most tool caches,
  so `uv` need not be named as its own entry.

## 9. Acceptance Criteria

- [ ] **AC-1 (FR-1).** Given both twins, when their Tier-A sets are compared, then each
  contains exactly the current 20 names plus every §5 Tier-A addition, and the two sets
  are byte-identical (same names, same order).
- [ ] **AC-2 (FR-2).** Given both twins, when their Tier-B sets are compared, then each
  contains the current set plus every §5 Tier-B addition, and the two sets are
  byte-identical.
- [ ] **AC-3 (FR-1, FR-7).** Given a fixture tree containing a directory named
  `node_modules`, `.pnpm-store`, `.pytest_cache`, `.next`, `.vscode`, `.cursor`, `.pyenv`,
  `cache`, `tmp`, `AppData`, or `User Data` (with a stray `.aid/` inside it), when a
  HOME-default scan runs, then that directory's subtree is pruned and the stray `.aid/`
  under it is NOT registered.
- [ ] **AC-4 (FR-2).** Given an `--all` scan whose root has an immediate child named
  `ProgramData`, `PerfLogs`, `Windows.old`, or `$WinREAgent`, when the scan runs, then
  that child is pruned as a root-only OS/system directory; given the SAME name deeper than
  one level, or under a HOME-default / `--path` scan, then it is NOT pruned by the Tier-B
  rule.
- [ ] **AC-5 (FR-7).** Given a directory literally named `build`, `bin`, or `.vscode` that
  DOES contain a valid `.aid/`, when a scan runs, then that directory IS discovered and
  registered (the is-project check precedes the name-based prune).
- [ ] **AC-6 (FR-3, FR-8, NFR-3).** Given no `scan-config.yml` at the state home, when a
  real (non-`--dry-run`) scan runs, then a `scan-config.yml` is created beside
  `registry.yml` containing a `schema: 1` line and a `prune_dirs:` block list of the
  expanded Tier-A defaults; given a `--dry-run` scan, then no `scan-config.yml` is created.
- [ ] **AC-7 (FR-4).** Given a `scan-config.yml` whose `prune_dirs:` list adds a
  user-specific name (e.g. `- my_big_cache`) that is NOT a built-in default, when a scan
  runs over a tree containing a `my_big_cache/` directory with a stray `.aid/` inside,
  then `my_big_cache/` is pruned and its `.aid/` is not registered; the built-in defaults
  still prune as well (extend-only union).
- [ ] **AC-8 (FR-4).** Given a `scan-config.yml` whose `prune_dirs:` repeats a built-in
  name (e.g. `- node_modules`), when a scan runs, then behavior is unchanged (the union is
  deduped case-insensitively; no error, no double-count).
- [ ] **AC-9 (FR-5).** Given a state home with no `scan-config.yml` (or an unreadable /
  `prune_dirs`-less one), when a scan runs, then it completes with exit 0 using exactly the
  built-in expanded Tier-A set and prints no error about the missing/malformed config.
- [ ] **AC-10 (FR-6, NFR-2).** Given an identical `scan-config.yml` and fixture tree, when
  both twins scan, then they read the same `prune_dirs:` entries (including a spaced entry
  such as `- Code Cache`), produce the identical discovered/registered set, and exit with
  identical codes; `tests/canonical/test-aid-cli-parity.sh` asserts this.
- [ ] **AC-11 (NFR-1).** Given the scan walk, when profiled, then the config is read and
  the merged prune set computed exactly once per run (not per directory), and no
  per-directory fork is introduced by the merge.
- [ ] **AC-12 (NFR-6).** Given the edited `bin/aid.ps1`, when `ps51-compat-check.ps1`
  runs, then it passes; given `bin/aid`, its constant arrays remain valid bash-4 arrays
  with spaced entries correctly quoted.
- [ ] **AC-13 (docs).** Given the change ships, when the CLI reference
  (`site/src/content/docs/reference/cli.mdx`) and `docs/install.md` scan help are read,
  then the exclusion behavior and the `scan-config.yml` config are documented; and
  `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[CHANGE]` entry.

## 10. Priority

Must.
