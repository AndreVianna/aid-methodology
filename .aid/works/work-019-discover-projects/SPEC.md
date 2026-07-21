# Machine Scan to Discover and Register AID Projects

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | SPEC authored from REQUIREMENTS.md | /aid-update-cli |

## Source

- REQUIREMENTS.md §1 Objective, §2 Problem Statement — feature intent
- REQUIREMENTS.md §4 Scope — in/out boundaries
- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-10)
- REQUIREMENTS.md §6 Non-Functional Requirements (NFR-1..NFR-8, guardrails)
- REQUIREMENTS.md §8 Assumptions & Dependencies — reused helpers, open points
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-13)
- REQUIREMENTS.md §10 Priority

## Description

Add an `aid` CLI subcommand (working name `aid projects scan`) that crawls the
local filesystem, finds every folder that contains a `.aid/` directory, and
registers each in the machine project registry — the same registry
`aid projects list` / `aid projects add` use. It is register-only: it never
installs, updates, or migrates a project, and it never writes inside a project's
`.aid/`. For each discovered project it reports the version read from that
project's manifest. By default it scans the whole machine (all local fixed drives
on Windows; `/` on Unix) with guardrails that keep the crawl safe and terminating;
a `<root>` argument narrows it to one subtree, and `--dry-run` previews the
registrations without writing anything.

## User Stories

- As an AID CLI user, I want to run one command that finds and registers every
  `.aid/` project on my machine, so that I do not have to visit each folder and run
  `aid projects add` by hand.
- As an AID CLI user, I want the scan to report each project's version without
  changing anything, so that I can decide later what to update with `aid update`.
- As an AID CLI user, I want a `--dry-run` and a `<root>` narrowing option, so that
  I can preview the result and scan just one tree quickly.
- As an AID maintainer, I want the Bash and PowerShell twins to behave identically
  under the parity suite, so that discovery works the same on every host.

## Priority

Must.

## Acceptance Criteria

- [ ] **AC-1 (FR-1).** Given a folder `P` with `P/.aid/` present, when
  `aid projects scan` runs, then `P` is registered and appears in
  `aid projects list`; no tool was installed and no file inside `P/.aid/` changed.
- [ ] **AC-2 (FR-2).** Given no `<root>`, scan enumerates local FIXED drives only on
  Windows (network + removable excluded by default) and walks from `/` on Unix; both
  twins classify drives identically.
- [ ] **AC-3 (FR-3).** Given `aid projects scan <root>` with a directory `<root>`,
  only that subtree is scanned; a non-directory `<root>` exits 2; `--depth <n>` bounds
  recursion to `n` levels, and BOTH a non-integer `--depth` (e.g. `--depth abc`) and a
  negative `--depth` (e.g. `--depth -1`) exit 2 (`<n>` must be a non-negative integer),
  identically on both twins.
- [ ] **AC-4 (FR-4).** Given `--dry-run`, scan prints what it would register, leaves
  the target `registry.yml` byte-unchanged, and exits 0.
- [ ] **AC-5 (FR-5).** A project already registered is not added twice and is reported
  as already-registered/skipped; a folder with no `.aid/` is never scaffolded or
  registered.
- [ ] **AC-6 (FR-6).** A discovered project with `"aid_version"` reports that version
  (a `-beta.N` suffix preserved); a `.aid/` with no valid manifest reports `untracked`
  without erroring.
- [ ] **AC-7 (FR-7, NFR-6).** A completed scan reports the newly-registered count, the
  already-registered count, and one path+version+action line per project; a long scan
  emits at least one progress line to stderr.
- [ ] **AC-8 (NFR-1..NFR-4).** Over a fixture tree with an unreadable directory, a
  heavy/cache directory (`node_modules`/`.git`/cache) matched by basename at any depth
  (NFR-2), an OS/system-named directory at a scan root (skipped) plus the same name
  nested deeper as an ordinary subfolder (NOT pruned) (NFR-3), and a directory-symlink
  cycle, scan skips the unreadable directory and continues, does not descend into the
  basename-matched heavy/cache directories, skips only the root-level OS/system
  directory (still discovering the project under the deeper same-named subfolder), and
  terminates.
- [ ] **AC-9 (NFR-5).** Network and removable drives are excluded by default and
  included only with `--include-network` / `--include-removable`.
- [ ] **AC-10 (FR-8, NFR-7).** For the same fixture tree, `bin/aid` and `bin/aid.ps1`
  produce identical discovery/registration results and identical exit codes, and no
  file under any discovered project's `.aid/` is created or modified;
  `tests/canonical/test-aid-cli-parity.sh` asserts this.
- [ ] **AC-11 (NFR-8).** Exit code is 0 on a completed scan and 2 on a usage error;
  result goes to stdout and diagnostics to stderr; the PowerShell twin passes
  `ps51-compat-check.ps1`.
- [ ] **AC-12 (FR-10).** `aid projects -h` documents the new subcommand, its flags,
  and its default whole-machine scope with byte-identical user-visible text on both
  twins; every user-facing CLI doc that enumerates the `projects` actions lists the
  new action; `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[NEW]`
  entry; and the final name reflects the approval-gate confirmation across help, docs,
  and tests.
- [ ] **AC-13 (FR-9).** On a GLOBAL install, a discovered project OUTSIDE `$HOME` is
  auto-registered in the USER tier with NO privilege elevation (no `sudo`, no
  `_aid_priv_run` shared-dir probe) because scan forced `_AID_TIER_OVERRIDE="--local"`
  (Bash) / `Resolve-AidTier -TierOverride '--local'` (PowerShell); `--shared` takes the
  shared path exactly as `aid projects add --shared`; both twins force/honor the tier
  identically.

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
  candidate is held as a tuple `{ path, tier, version, action }` where
  `action ∈ { registered, already-registered, would-register }`. This drives the
  §Feature Flow summary report only; it is not written to disk (contrast the
  registry line-item, which is the only persisted output).

A discovered project is a filesystem path `P` such that `P/.aid/` is a directory AND
`_aid_is_project_dir(P)` / `Test-AidIsProjectDir(P)` is true — i.e. `P/.aid` does not
resolve to the CLI state home (`$AID_STATE_HOME` or `$HOME/.aid`), which is excluded
by construction so the CLI's own state directory is never registered as a project.

### Feature Flow

```
aid projects scan [<root>] [--dry-run] [--depth N]
                  [--include-network] [--include-removable]
                  [--local|--shared] [--verbose]
          │
          ▼
 (1) parse args/flags  ──► bad flag / scan-only flag on a non-scan action /
                          non-dir <root> / non-int OR negative --depth ⇒ exit 2
          │
          ▼
 (2) determine scan roots
        <root> given ─────────► single canonical subtree (fast path)
        no <root> ────────────► whole machine:
                                   Windows: local FIXED drives only
                                     (bash: shell out to powershell.exe running
                                      [System.IO.DriveInfo]::GetDrives() — the SAME
                                      classifier the pwsh twin uses natively; map
                                      "X:\" ⇒ "/x/" for the MSYS walk)
                                   Unix:    "/"  (no drive enumeration)
                                 (network + removable excluded unless opted in)
          │
          ▼
 (3) read registry ONCE into a set  ◄── _registry_read_raw_union / Get-RegistryRawUnion
          │
          ▼
 (4) for each root: recursive walk with pruning
        ├─ skip OS/system dirs ROOT-ONLY  (NFR-3, root-only name-set)
        ├─ prune heavy/cache dirs by BASENAME at any depth (NFR-2, shared name-set)
        ├─ skip unreadable dir + continue (NFR-1)
        ├─ do not follow dir symlinks     (NFR-4, loop guard)
        ├─ stop at --depth N if set       (FR-3)
        └─ on a dir D containing D/.aid/ that passes is-project-dir ⇒ CANDIDATE
                (never traverse INTO the .aid/ directory itself)
          │
          ▼
 (5) for each CANDIDATE
        ├─ version ◄── _aid_project_state / Get-AidProjectState   (FR-6)
        ├─ in registry set?  ── yes ─► action=already-registered (skip; no dup)  (FR-5)
        └─ no ─► tier: FORCE user via override — _AID_TIER_OVERRIDE="--local"
                       (bash) / Resolve-AidTier -TierOverride '--local' (pwsh),
                       unless the user passed --shared (then '--shared'); NEVER the
                       auto-rule, so a global install never elevates      (FR-9)
                  │
                  ├─ --dry-run ─► action=would-register  (NO write)          (FR-4)
                  └─ else       ─► registry_register / Registry-Register     (FR-5)
                                    (idempotent, atomic; WARN-not-fail on write error)
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

### Layers & Components

The command lands in the two CLI entrypoints; all reused helpers already live there
(the registry/version/tier/is-project helpers are defined in `bin/aid` and
`bin/aid.ps1` themselves — the install-core libs provide install/fetch/manifest logic
and need **no change** for this feature). Reference: `module-map.md` (CLI module),
`architecture.md § the CLI installer`, `coding-standards.md`.

**Bash — `bin/aid`:**

| Element | Kind | Notes |
|---|---|---|
| `_cmd_projects_scan()` | new | Orchestrates parse → roots → walk → dedupe → register → report. Sibling of `_cmd_projects_list/add/remove`. **Tier forcing (FR-9):** before registering, sets `_AID_TIER_OVERRIDE="--local"` (force user) unless the user passed `--shared` (then `"--shared"`); NEVER leaves the auto-rule to pick, so a global install can never elevate via `_aid_priv_run`→`sudo`. The override is a documented USE of the existing convention (`bin/aid` ~:1517-1523); `_aid_resolve_tier` itself is unchanged. |
| `_aid_scan_roots()` | new helper | Enumerates scan roots: `<root>`, else whole-machine. **Windows drive enumeration (FR-2/NFR-5):** the bash twin runs under Git-Bash/MSYS/Cygwin — detect via the same `uname -s` MINGW*/MSYS*/CYGWIN* idiom `bin/aid` already uses (`_dc_is_windows`, ~:1128) and shell out to the always-present `powershell.exe -NoProfile -Command` running `[System.IO.DriveInfo]::GetDrives()` filtered on `DriveType` (Fixed by default; `Network`/`Removable` opt-in) — the SAME classifier the pwsh twin uses natively, so drive classification is identical-by-construction (AC-2), following the repo's existing bash→Windows-tool shell-out pattern (`netstat`/`taskkill` with `MSYS_NO_PATHCONV=1`, ~:1151-1159). Each returned `X:\` is mapped to its MSYS `/x/` form for the walk. On Unix there is NO drive enumeration — the single root is `/`. (Legacy `wmic logicaldisk` is NOT used: `wmic` is deprecated and absent on current Windows 11.) |
| `_aid_scan_walk()` | new helper | Recursive/iterative pruned walk emitting candidate `.aid/` roots; honors the heavy/cache prune-set (basename-anywhere), the OS/system set (root-only), unreadable-skip, symlink guard, `--depth`. |
| `_AID_SCAN_PRUNE_DIRS` | new constant | Heavy/cache name-set (NFR-2), matched by BASENAME at ANY depth. Byte-identical across twins. |
| `_AID_SCAN_SYSTEM_DIRS` | new constant | OS/system name-set (NFR-3), matched ROOT-ONLY — only as an immediate child of a scan root (a drive/filesystem root `C:\`/`/` in whole-machine mode; the immediate children of `<root>` under a `<root>` scan) — so an ordinary `dev/`/`run/` subfolder nested below the top level is never falsely pruned. Byte-identical across twins. |
| `_cmd_projects` parse loop + dispatch | edit | Add `scan` to the action `case` (`list\|add\|remove\|scan\|help`); EXTEND the `_cmd_projects` while-loop (`bin/aid` ~:2510-2527) to ACCEPT the scan-specific flags — `--dry-run`, `--include-network`, `--include-removable` (valueless) and `--depth <n>` (consumes its value, `shift 2`) — routing them into the `scan` dispatch. These flags are GATED to `scan`: passing one to `list`/`add`/`remove` is a usage error (exit 2). Without this edit the loop's `-*` arm rejects them before scan runs. |
| top-level `projects` dispatch | edit | Add `scan` to the recognized action-word list (`bin/aid` ~:3265). Scan flags after the action word already flow into `_PROJ_ARGS` and are parsed by `_cmd_projects`. |
| `_aid_usage projects` | edit | Add the `aid projects scan …` usage lines. |
| Reused unchanged | — | `_aid_is_project_dir`, `_registry_read_raw_union`, `_aid_resolve_tier`, `registry_register`, `_aid_project_state`. |

**PowerShell — `bin/aid.ps1` (mirror; every reused helper already mirrored):**

| Element | Kind | Notes |
|---|---|---|
| `Invoke-AidProjectsScan` | new | Mirror of `_cmd_projects_scan` (approved-verb `Invoke-Aid…` naming). **Tier forcing (FR-9):** computes `$tierOverride = if ($shared) { '--shared' } else { '--local' }` and passes it to `Resolve-AidTier -TierOverride $tierOverride` for every candidate — so the default is USER tier and the auto-rule never runs. (No global tier var exists in the pwsh twin; the override is the `-TierOverride` parameter already threaded through `Invoke-AidProjectsAdd`/`Resolve-AidTier`.) `Resolve-AidTier`/`Registry-Register` are unchanged. |
| `Get-AidScanRoot` (roots) + walk helper | new | Roots via `[System.IO.DriveInfo]::GetDrives()` filtered to `DriveType -eq 'Fixed'` (network=`Network`, removable=`Removable` excluded by default; opt-in flags include them) — the same enumeration the bash twin shells out to, so classification is identical (AC-2); recursive pruned walk. |
| `$script:AidScanPruneDirs` | new constant | Heavy/cache name-set (NFR-2), matched by BASENAME at any depth; byte-identical to the Bash `_AID_SCAN_PRUNE_DIRS`. |
| `$script:AidScanSystemDirs` | new constant | OS/system name-set (NFR-3), matched ROOT-ONLY; byte-identical to the Bash `_AID_SCAN_SYSTEM_DIRS`. |
| `Invoke-AidProjects` parse loop + switch | edit | Add `'scan'` case → `Invoke-AidProjectsScan`; EXTEND the `Invoke-AidProjects` parse loop (`bin/aid.ps1` ~:2073-2090) to ACCEPT `--dry-run`, `--include-network`, `--include-removable` and `--depth <n>` (consume the value token) and route them to `scan`. GATED to `scan`: passing one to `list`/`add`/`remove` is a usage error (`Exit-Aid 2`). Without this the loop's `^-` arm rejects them. Kept byte-behavior-identical to the bash loop. |
| top-level `projects` dispatch | edit | Add `'scan'` to the recognized action-word list (`bin/aid.ps1` ~:3235). Flags after the action word flow into `$_ProjArgs` and are parsed by `Invoke-AidProjects`. |
| `Show-AidUsage 'projects'` | edit | Add the `aid projects scan …` usage lines (ASCII-only). |
| Reused unchanged | — | `Test-AidIsProjectDir`, `Get-RegistryRawUnion`, `Resolve-AidTier`, `Registry-Register`, `Get-AidProjectState`. |

**Tests — `tests/canonical/test-aid-cli-parity.sh`:** a new `PAR`-prefixed block that
exercises scan over a fixture tree via the `<root>` fast path (walk/prune/dedupe/
dry-run/version) on both twins and asserts identical results, identical exit codes, and
no writes inside any project `.aid/`. It does NOT crawl the real machine (slow,
non-deterministic, and a test-isolation hazard); whole-machine drive enumeration is
covered by asserting the roots/drive-classifier excludes network+removable given a known
drive set. Reference: `test-landscape.md` (this suite is the CLI-twin CI gate).

<!-- Conditional section — CLI command-surface, activated for a `cli` artifact. -->

### Command Surface & CLI Contract

- **Invocation (working name):** `aid projects scan [<root>] [flags]` — a fourth
  action under the existing `projects` group (alongside `list`/`add`/`remove`). It
  reuses the group's dispatch, flag-parsing, and `-h` surface, EXTENDED so the shared
  `projects` parse loop accepts the scan-specific flags below and routes them to the
  `scan` action; a scan-specific flag passed to `list`/`add`/`remove` is a usage error
  (exit 2). Both twins extend their parse loop identically (see § Layers & Components).
- **Positional:** `<root>` (optional) — a directory to scan instead of the whole
  machine.
- **Flags:**
  - `--dry-run` — preview; write nothing (FR-4).
  - `--depth <n>` — cap recursion at `n` levels below each root; `<n>` must be a
    non-negative integer. A non-integer OR negative `<n>` is a usage error (exit 2)
    (FR-3).
  - `--include-network` — include network drives (default: excluded) (NFR-5).
  - `--include-removable` — include removable drives (default: excluded) (NFR-5).
  - `--local` / `--shared` — tier override with identical semantics to
    `aid projects add`. Scan FORCES the USER tier by default (it sets the override to
    `--local` internally) so a bulk scan never elevates; `--local` is the explicit
    form of that default, and `--shared` opts into the shared tier exactly as
    `aid projects add --shared` (FR-9).
  - `--verbose` — extra per-project / per-root detail.
  - `-h` / `--help` — the `projects` usage block.
- **Exit codes** (shared scheme, `coding-standards.md § Exit Codes`): `0` — scan
  completed (including "found nothing" and `--dry-run`); `2` — usage/argument error
  (unknown flag, scan-specific flag on a non-scan action, non-directory `<root>`,
  non-integer OR negative `--depth`). A registry write failure follows the existing
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
