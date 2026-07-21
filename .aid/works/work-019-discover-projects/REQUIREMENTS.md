# Requirements

- **Name:** Machine Scan to Discover and Register AID Projects
- **Description:** Add an `aid` CLI subcommand that searches the machine for folders containing a `.aid/` directory and registers each as a project without modifying any of them

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | Initial capture (shortcut: aid-update-cli) | /aid-update-cli |
| 2026-07-21 | GATE cycle-1 fixes (reviewer findings resolved) | /aid-update-cli |
| 2026-07-21 | Scope-model redesign: default = user home, `--path <folder>`, `--all` (replaced whole-machine default; positional `<root>` removed) | /aid-update-cli |
| 2026-07-21 | Scan-behavior rules: NFR-9 (per-folder eval order + project-subtree prune), NFR-10 (canonicalize + dedupe), NFR-2 +`obj`/`bin`/`logs` (case-insensitive), NFR-4 hard depth cap; FR-5 no-change-on-skip + real-project/state-home | /aid-update-cli |
| 2026-07-21 | GATE cycle-2 fixes: NFR-3 system-dir skip scoped to `--all` only (HOME/`--path` roots descended); NFR-5 network/removable scoped to Windows drive model + Unix disclosed limitation; Change Logs refreshed; internal rule-shorthand removed | /aid-update-cli |

## 1. Objective

Add a new `aid` CLI command that finds AID projects on the machine and adds them
to the project registry in one pass. By default it scans the user's HOME directory
(the safe, common case); `--all` widens the search to the whole machine and
`--path <folder>` targets a specific folder instead. Today a project only enters the
registry when the user runs `aid projects add` inside it (or a tool op registers it
on-encounter). After cloning a machine, reinstalling the CLI, or adopting AID
across many existing repos, the user must visit each folder by hand. The new
command automates the "find them all and register them" step. It is
**register-only**: it never installs, updates, or migrates a project; it reports
each discovered project's version so the user can decide what to update later with
the existing `aid update` command.

## 2. Problem Statement

The registry (`aid projects list`) is only ever populated one folder at a time.
There is no way to say "find all my AID projects and track them." On a machine
with many repos this is tedious and error-prone, and a freshly reinstalled CLI
starts with an empty registry even though `.aid/` projects already exist on disk.
The user wants a single command that crawls a chosen scope — the user's home
directory by default, the whole machine with `--all`, or a specific folder with
`--path` — detects `.aid/` roots, and registers each — surfacing versions but
changing nothing inside the projects.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID CLI user / developer | Runs `aid` across many local repos | One command to find and register every `.aid/` project; a clear report of what was found and each project's version; confidence that nothing inside the projects was touched |
| AID maintainer | Owns `bin/aid`, `bin/aid.ps1`, and the parity suite | A behavior-identical Bash/PowerShell twin pair that reuses the existing registration and version-reading helpers, guarded by the parity suite |

## 4. Scope

### In Scope

- A new `aid` CLI subcommand (working name `aid projects scan`; §5 FR-1 — final
  name confirmed at the approval gate) that:
  - Scans the user's home directory by default; a specific folder's subtree with
    `--path <folder>`; or all accessible folders (the whole machine) with `--all`.
  - Detects folders containing a `.aid/` directory and registers each in the
    machine project registry, reusing the existing registration path.
  - Reports each discovered project's version (reusing the existing per-project
    version reader).
  - Supports a `--dry-run` preview that writes nothing.
- Guardrails for a safe, terminating machine scan (§6).
- Both CLI twins (`bin/aid` and `bin/aid.ps1`), behavior-identical, plus parity
  and guardrail test coverage and updated help text.

### Out of Scope

- Updating, installing, migrating, or otherwise modifying any discovered project
  (updates remain on-demand via the existing `aid update` command — never triggered
  by this command).
- Scaffolding a bare `.aid/` for a folder that has none (that is `aid projects add`'s
  behavior; this command only registers folders that ALREADY contain a `.aid/`).
- Any change to the registry file schema, the manifest schema, or the version-string
  format.
- A network/remote crawl or a service; this is a local-filesystem scan only.
- Changing the meaning of the existing `aid-discover` SKILL or the "Discover" pipeline
  phase.
- **A user-extensible / configurable exclusion list (v1 constraint).** The
  heavy/cache prune name-set (NFR-2) and the OS/system name-set (NFR-3) are BUILT-IN and
  FIXED for v1: there is no `.aid/settings.yml` key and no `--exclude` flag to add,
  remove, or override pruned names. This is a deliberate v1 boundary, not an oversight.
- **Unix network/removable mount exclusion (documented limitation, NFR-5).** Drive-type
  exclusion is a Windows drive-letter concept. On Unix `--all` the walk descends every
  mount reachable under `/` (system dirs still skipped at `/` per NFR-3); NFS/CIFS/
  removable mounts (`/media`, `/mnt`, …) are NOT auto-classified or excluded, and
  `--include-network` / `--include-removable` are Windows-only-effective (accepted-inert
  with a one-line stderr note on Unix). A Unix mount classifier is out of scope for v1.
- **Discovering an AID project nested INSIDE another AID project (deliberate
  limitation, NFR-9).** Once a folder is identified as a project (it contains a valid
  `.aid/`), its ENTIRE subtree is pruned and never searched, so an AID project located
  within another AID project's directory is intentionally NOT separately discovered or
  registered. (This is distinct from a project merely nested *below* a name-excluded or
  OS-named folder but NOT inside a project, which IS still discovered — see NFR-3.)

## 5. Functional Requirements

- **FR-1 — New subcommand.** Provide a new `aid` CLI subcommand (working name
  `aid projects scan`) that searches the machine for folders containing a `.aid/`
  subdirectory and registers each as a project. It is register-only and MUST NOT
  update, install, or migrate any project.
- **FR-2 — Default scope: the user home directory.** With no scope argument the
  command scans the user's HOME directory (`$HOME`; `%USERPROFILE%` on Windows) —
  NOT the whole machine. It reuses the SAME home resolution the twins already use
  for state-home and tier decisions (`${HOME}` in `bin/aid`; `$HOME` in
  `bin/aid.ps1`, which on Windows resolves from the user profile). No drive
  enumeration occurs for the default; a single known subtree is walked. Behavior is
  identical (parity) across the Bash and PowerShell twins.
- **FR-3 — Scope selection (`--path`, `--all`) and depth (`--depth`).** There is no
  positional argument.
  - **`--path <folder>`** scans that folder's subtree instead of home (the fast
    path). This REPLACES the former positional `<root>`. A `--path` value that is
    not an existing directory is a usage error (exit 2).
  - **`--all`** scans ALL accessible folders (the whole machine): on Windows it
    enumerates every local FIXED drive (`C:\`, `D:\`, …); on Unix it walks from `/`.
    This is the ONLY mode that enumerates drives (network + removable excluded unless
    opted in — NFR-5).
  - **`--all` and `--path` are mutually exclusive** — one names a single subtree, the
    other enumerates everything; passing both is a usage error (exit 2).
  - **`--depth <n>`** caps recursion at `n` levels below each scan root; `<n>` MUST be
    a non-negative integer — a non-integer OR negative `--depth` value (e.g.
    `--depth abc`, `--depth -1`) is a usage error (exit 2). Both twins reject the same
    set of `--depth` values identically (parity).
  All scope/flag classification is identical (parity) across the Bash and PowerShell
  twins.
- **FR-4 — Dry run.** `--dry-run` lists the projects that WOULD be registered and
  makes zero writes to any registry file, exiting 0.
- **FR-5 — Register-only and idempotent.** Registration reuses the EXISTING path
  (`registry_register` + `_aid_resolve_tier` in Bash; `Registry-Register` +
  `Resolve-AidTier` in PowerShell) — the same `registry.yml` the `aid projects add` /
  `aid projects list` commands use. A project already in the registry is SKIPPED with
  ZERO change to its existing record — no re-tier, no version rewrite, no reordering of
  the registry (set-insert idempotent; no duplicates). A folder without a `.aid/` is
  never scaffolded and never registered. No project's `.aid/` is ever modified. A
  candidate is registered ONLY if its `.aid/` is a DIRECTORY that passes the existing
  project-dir check (`_aid_is_project_dir` / `Test-AidIsProjectDir`), and the CLI's own
  state home (`$HOME/.aid` / `$AID_STATE_HOME`) is NEVER registered as a project (the
  is-project-dir check excludes it by construction).
- **FR-6 — Version detection.** For each discovered project, report its version by
  reusing the existing per-project state reader (`_aid_project_state` in Bash;
  `Get-AidProjectState` in PowerShell), which reads `aid_version` from
  `<proj>/.aid/.aid-manifest.json` and accepts a `-beta.N` suffix. A project with no
  valid manifest is reported as `untracked` (never an error).
- **FR-7 — Report and progress.** On completion the command prints a summary: the
  count of newly-registered projects, the count of already-registered (skipped)
  projects, and a per-project line carrying the project path, its version, and the
  action taken. During a long scan it emits periodic progress so the run is not
  silent.
- **FR-8 — Both twins, behavior-identical.** The command is implemented in BOTH
  `bin/aid` and `bin/aid.ps1` with identical behavior (subcommand name, flags,
  drive/prune classification, output shape, and exit codes), enforced by the parity
  suite `tests/canonical/test-aid-cli-parity.sh`.
- **FR-9 — Tier: force user by default (no elevation on a bulk scan).** For every
  auto-registered discovered project, the scan FORCES the USER tier so a
  bulk scan can never trigger privilege elevation. It does this by setting
  the existing tier-override before it registers each project — `_AID_TIER_OVERRIDE="--local"`
  in Bash / `Resolve-AidTier -TierOverride '--local'` in PowerShell — instead of
  leaving the tier to the auto-rule. This matters because the auto-rule
  (`_aid_resolve_tier` / `Resolve-AidTier`) returns the SHARED tier whenever the
  install is global AND the discovered path is outside `$HOME` (which the home
  default avoids, but a `--path` outside home or an `--all` crawl can reach), and the
  shared branch of `registry_register` probes the
  shared dir through `_aid_priv_run` → `sudo` — a real elevation prompt the scan
  must never provoke. The forcing is a USE of the existing override API; the tier
  helpers themselves are reused unchanged. `--shared` remains available and, when
  explicitly passed, is honored exactly as `aid projects add --shared` (override set
  to `--shared`); `--local` and the default both resolve to the USER tier. (§8
  records the resolved decision; the user still sees and may override the forced
  tier at the approval gate.)
- **FR-10 — Documentation & help output.** The shipped `aid projects -h` help
  documents the new subcommand, all of its flags (`--path`, `--all`, `--dry-run`,
  `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`,
  `--verbose`), and its scope model (home by default; `--path <folder>` for a
  specific folder; `--all` for the whole machine), with byte-identical user-visible
  text across the two twins. Every user-facing CLI doc that enumerates the `projects` actions
  (README / CLI reference) lists the new action alongside `list`/`add`/`remove`, and
  a `[NEW]` entry is added to `.aid/knowledge/release-tracking.md` `## Unreleased`.
  The final subcommand name confirmed at the approval gate is applied consistently
  across help text, docs, and test identifiers.

## 6. Non-Functional Requirements

Guardrails — all are load-bearing and MUST hold on both twins with identical
behavior (classification, walk order, and dedupe alike) (parity):

- **NFR-1 — Never abort on an unreadable directory.** A permission-denied or
  otherwise unreadable directory is skipped; the scan continues.
- **NFR-2 — Prune heavy/irrelevant trees (match by basename ANYWHERE,
  case-insensitive).** Well-known heavy or irrelevant directories are pruned (not
  descended) wherever they occur in the tree — the match is on the directory's BASENAME
  at ANY depth and is CASE-INSENSITIVE (so `Build`, `OBJ`, `Logs` match too): version-
  control object stores and common language/package/build caches — including
  `node_modules`, `.git`, `.hg`, `.svn`, `.venv`, `venv`, `__pycache__`, `target`,
  `dist`, `build`, `obj`, `bin`, `logs`, `.gradle`, `.m2`, `.cargo`, `.npm`, `.cache`,
  `vendor`, `Pods`. These names are a heavy/cache set distinct from the OS/system set in
  NFR-3, and the set is a single shared list, byte-identical (and matched
  case-insensitively) across the two twins. Because the `.aid/` project check precedes
  name-based pruning (NFR-9), a project whose OWN folder name is one of these (e.g.
  a repo literally named `bin`, `obj`, or `logs` that contains a valid `.aid/`) is STILL
  discovered; only NON-project folders with these names are pruned.
- **NFR-3 — Skip OS/system trees (`--all` only, match ROOT-ONLY).** The OS/system set
  is applied ONLY under `--all`, and only at the TOP LEVEL of an `--all` scan root —
  i.e. as an immediate child of a drive/filesystem root (`C:\` on Windows, `/` on Unix),
  targeting true OS locations such as `C:\Windows` and `/proc`. It is NOT applied under
  the HOME default or `--path`: a top-level `~/dev` (the ubiquitous `~/dev` projects
  convention) or `<--path>/dev` MUST be descended into normally so a project inside it
  is discovered — only a true filesystem-root child under `--all` is skipped. (The
  basename-anywhere NFR-2 heavy/cache set still applies in ALL modes — HOME default,
  `--path`, and `--all`; only THIS root-only system set is `--all`-scoped.) The same
  name deeper in the tree is likewise never pruned by this set. The root-only names are:
  on Windows, `Windows`, `Program Files`, `Program Files (x86)`, `$Recycle.Bin`,
  `System Volume Information`; on Unix, `proc`, `sys`, `dev`, `run` (i.e. `/proc`,
  `/sys`, `/dev`, `/run`). This is a second shared list, separate from the NFR-2
  heavy/cache set, byte-identical and matched case-insensitively across the two twins.
- **NFR-4 — Guaranteed termination (symlink guard + hard depth cap).** The walk does
  not follow directory symlinks (or otherwise guards against revisiting a real path),
  so a symlink cycle can never cause an infinite loop. In addition, the walk enforces a
  HARD maximum recursion depth — a large built-in constant (`_AID_SCAN_MAX_DEPTH` /
  `$script:AidScanMaxDepth`), byte-identical across the twins and DISTINCT FROM and
  INDEPENDENT OF the user-facing `--depth` cap — so that even a pathologically deep (or
  adversarially crafted) tree always terminates. The scan therefore always terminates
  regardless of on-disk structure.
- **NFR-5 — Network + removable drives (Windows `--all` drive model; excluded by
  default).** Drive enumeration and drive-type classification are a WINDOWS concept
  (drive letters + `DriveType`), engaged ONLY under `--all`. On WINDOWS `--all`, network
  and removable drives are excluded from the enumerated FIXED-drive set by default;
  `--include-network` and `--include-removable` add them back. On UNIX `--all` there are
  no drive letters — the walk starts at `/` and descends every mount reachable under it
  (with the NFR-3 system-dir skip still applying at `/`); network/removable mounts (NFS,
  CIFS, `/media`, `/mnt`, …) are NOT auto-classified or excluded — a documented
  limitation (§4 Out of Scope). Consequently `--include-network` / `--include-removable`
  are Windows-only-effective: on Unix they are ACCEPTED but INERT, and the command emits
  a one-line note to stderr that drive-type filtering is Windows-only (never a silent
  no-op). On BOTH platforms these two flags still require `--all` — passing either
  WITHOUT `--all` is a usage error (exit 2). Behavior is identical across the two twins
  on each platform (Windows: both extend the drive set; Unix: both walk all mounts under
  `/` and both print the note).
- **NFR-6 — Progress, not silence.** A long scan emits periodic progress to stderr
  (current root/drive and a running count) so it is never silent.
- **NFR-7 — Write confinement.** The command writes ONLY the machine registry file
  (`registry.yml`, via the reused registration path). It never creates or modifies
  any file inside a discovered project's `.aid/` (register-only). A `--dry-run`
  writes nothing at all.
- **NFR-8 — Coding-standards conformance.** The command follows
  `coding-standards.md`: the shared exit-code scheme (0 success, 2 usage/argument
  error), result to stdout / diagnostics to stderr, and — for the PowerShell twin —
  Windows-PowerShell-5.1 compatibility and ASCII-only source (enforced by
  `ps51-compat-check.ps1`).
- **NFR-9 — Per-folder evaluation order and project-subtree pruning.** At each folder
  `D` the walk applies a FIXED order (identical across twins), and it is this per-folder
  order — not a decision made about a child before entering it — that is normative:
  (1) if `D` is unreadable, skip it and continue (NFR-1); (2) ELSE if `D` is a valid
  `.aid/` project (is-project-dir), register/skip it (FR-5) and PRUNE ITS ENTIRE
  SUBTREE — do NOT recurse into ANY child (`.aid/` or otherwise); (3) ELSE if `D`'s
  BASENAME matches the NFR-2 heavy/cache set (anywhere, case-insensitive, ALL modes) —
  OR (ONLY under `--all`) `D` is an immediate child of a filesystem/drive root whose
  basename matches the NFR-3 OS/system set — PRUNE `D` (do not recurse); (4) ELSE recurse
  into `D`'s children (skipping directory symlinks per NFR-4, and stopping at the
  `--depth` and hard `_AID_SCAN_MAX_DEPTH` caps), applying this SAME order to each child. Two consequences follow and are load-bearing:
  (a) an AID project located INSIDE another AID project's tree is NOT separately
  discovered (a project's own contents are never searched — the deliberate §4
  limitation); (b) because the project-check in step (2) precedes the name-based pruning in step
  (3) FOR THE SAME FOLDER, a project whose OWN folder name matches an exclusion (e.g. a
  repo named `bin`/`obj`/`logs`) IS still discovered. Both twins implement this order
  identically (parity).
- **NFR-10 — Canonicalize and dedupe within a run.** Each discovered project is
  resolved to its real, ABSOLUTE (canonical) path before it is registered (reusing each
  twin's existing canonicalizer — `cd … && pwd -P` in Bash, `Resolve-Path` /
  `[System.IO.Path]::GetFullPath` in PowerShell), and the run dedupes on that canonical
  key so the SAME project reached more than once (overlapping consideration, a `.`/`..`
  path, or a symlink the NFR-4 guard would otherwise expose) is registered AT MOST ONCE.
  Both twins canonicalize and dedupe identically (parity).

## 7. Constraints

- Must land in BOTH language twins in the same delivery (the twin-parity convention:
  `coding-standards.md § Conventions` "change BOTH twins in the same commit"); parity
  is test-enforced, not generated.
- Must reuse the existing registry file schema (`schema: 1`, `projects:` list of
  canonical base-folder paths) and the existing version reader — no schema or format
  changes.
- The PowerShell twin must remain Windows-PowerShell-5.1 compatible and ASCII-only
  (`coding-standards.md § PowerShell Conventions`).

## 8. Assumptions & Dependencies

- The registry and version-reading helpers referenced in FR-5/FR-6 exist in
  `bin/aid` and `bin/aid.ps1` today and are reused unchanged (confirmed:
  `_registry_read_raw_union`, `registry_register`, `_aid_resolve_tier`,
  `_aid_project_state`, `_aid_is_project_dir`; and the PowerShell mirrors
  `Get-RegistryRawUnion`, `Registry-Register`, `Resolve-AidTier`,
  `Get-AidProjectState`, `Test-AidIsProjectDir`).
- KB context: `.aid/knowledge/architecture.md` (CLI installer anatomy),
  `module-map.md` (CLI module + parity coverage), `coding-standards.md` (exit codes,
  cross-platform twin rules), `test-landscape.md` (the parity suite is the CI gate for
  the CLI twins).
- **Open point for the approval gate — command name.** The user's tentative name
  `discover` collides with two existing meanings (the `aid-discover` SKILL for
  connector discovery via ELICIT, and the first pipeline PHASE "Discover"). The SPEC
  proposes `aid projects scan` with alternatives and a recommendation; the final
  name is the user's to confirm at the approval gate (§5 FR-1).
- **RESOLVED — `--all` scan cost (explicit opt-in, accepted).** A first-run `--all`
  crawl of large disks can take minutes even with pruning. Because `--all` is an
  EXPLICIT opt-in — the default scope is the much smaller home directory, and
  `--path` is the fast narrowing path — that cost is acceptable: the user asked for
  the full crawl. Progress output (NFR-6) is the mitigation; no confirmation prompt
  is required.
- **RESOLVED (approval-gate visible) — tier on a global install.** The design
  question "auto-tier vs. forced user tier" is settled in the design: FR-9 FORCES
  the USER tier for auto-registered discovered projects (by setting the existing
  `_AID_TIER_OVERRIDE="--local"` / `Resolve-AidTier -TierOverride '--local'` before
  each registration), because the auto-rule would otherwise select the SHARED tier
  for out-of-`$HOME` projects on a global install and the shared branch of
  `registry_register` probes via `_aid_priv_run` → `sudo` — the elevation FR-9
  forbids. `--shared` (explicit) still selects the shared path, exactly as
  `aid projects add --shared`. This is a firm design decision, not a deferred
  question; it remains visible to the user at the approval gate, who may override
  the forced default there.

## 9. Acceptance Criteria

- **AC-1 (FR-1).** Given a folder `P` on disk with `P/.aid/` present, when
  `aid projects scan` runs, then `P` is registered in the machine registry and
  appears in `aid projects list`; no host tool was installed and no file inside
  `P/.aid/` changed.
- **AC-2 (FR-2).** Given no scope argument, when scan runs, then it scans the user
  HOME directory (`$HOME`; `%USERPROFILE%` on Windows) and performs NO drive
  enumeration. Given `--all`, then on Windows it enumerates local FIXED drives only
  (network + removable excluded by default) and on Unix walks from `/`; the Bash and
  PowerShell twins classify drives identically.
- **AC-3 (FR-3).** Given `aid projects scan --path <folder>`, when `<folder>` is a
  directory, then only that subtree is scanned; when `<folder>` is not a directory,
  exit 2 with a usage error (there is no positional `<root>` form). Given both `--all`
  and `--path`, exit 2 (mutually exclusive). Given `--depth <n>`, no directory deeper
  than `n` levels below the root is visited; a non-integer `--depth` value (e.g.
  `--depth abc`) AND a negative `--depth` value (e.g. `--depth -1`) each exit 2 —
  `<n>` must be a non-negative integer, and both twins reject the identical set.
- **AC-4 (FR-4).** Given `--dry-run`, when scan runs over a fixture tree, then it
  prints the projects it WOULD register, the target `registry.yml` is byte-unchanged
  (or absent stays absent), and it exits 0.
- **AC-5 (FR-5).** Given a project already registered, when scan runs (and when it is
  re-run), then that project is not added twice, is reported as
  already-registered/skipped, and its existing registry record is UNCHANGED — no
  re-tier, no version rewrite, no reordering; given a folder with no `.aid/`, scan
  neither scaffolds nor registers it.
- **AC-6 (FR-6).** Given a discovered project whose manifest carries
  `"aid_version": "X.Y.Z"` (optionally `-beta.N`), scan reports that version verbatim;
  given a `.aid/` with no valid manifest, scan reports `untracked` and does not error.
- **AC-7 (FR-7, NFR-6).** Given a completed scan, the final summary reports the
  newly-registered count, the already-registered count, and one path+version+action
  line per discovered project; a long scan emits at least one progress line to stderr.
- **AC-8 (NFR-1..NFR-4).** Given a fixture tree containing an unreadable directory, a
  heavy/cache directory (`node_modules`/`.git`/`obj`/`bin`/`logs`/known-cache) matched
  by basename (case-insensitively) at any depth in ALL modes (NFR-2), a top-level
  `dev`/`run` folder directly under the HOME-default / `--path` scan root that holds a
  project (NFR-3 — the system set is `--all`-only, so this folder MUST be DESCENDED and
  the project inside FOUND, NOT pruned), a directory-symlink cycle, and a pathologically
  deep chain of directories, when scan runs, then it skips the unreadable directory and
  continues, does not descend into the basename-matched heavy/cache directories,
  DESCENDS into the top-level `dev`/`run` under HOME/`--path` and discovers the project
  inside it, and TERMINATES in every case — the symlink cycle via the NFR-4 symlink
  guard and the deep chain via the hard `_AID_SCAN_MAX_DEPTH` cap (independent of
  `--depth`). Separately, under `--all` (against the mocked filesystem/drive-root set of
  AC-2/AC-9) an OS/system-named immediate child of a true root (`/proc`, `C:\Windows`) IS
  skipped — the only mode in which the NFR-3 set applies.
- **AC-9 (NFR-5).** On WINDOWS `--all` with network and/or removable drives present,
  scan excludes them from the enumerated FIXED set by default and includes them only when
  `--include-network` / `--include-removable` is passed. On UNIX `--all`, the walk
  descends all mounts under `/` (network/removable NOT auto-excluded — documented
  limitation, §4), and `--include-network` / `--include-removable` are accepted-but-inert
  with a one-line stderr note (Windows-only-effective). On BOTH platforms these two flags
  apply to `--all` only: passing either WITHOUT `--all` is a usage error (exit 2). Both
  twins behave identically on each platform.
- **AC-10 (FR-8, NFR-7).** Given the same fixture tree, `bin/aid` and `bin/aid.ps1`
  produce identical discovery/registration results and identical exit codes, and in
  every case no file under any discovered project's `.aid/` is created or modified;
  `tests/canonical/test-aid-cli-parity.sh` asserts this.
- **AC-11 (NFR-8).** The subcommand uses exit code 0 on a completed scan and 2 on a
  usage/argument error, prints its result to stdout and diagnostics to stderr, and the
  PowerShell twin passes `ps51-compat-check.ps1` (ASCII-only, 5.1-compatible).
- **AC-12 (FR-10).** The shipped help (`aid projects -h`) documents the new
  subcommand, its flags (`--path`, `--all`, `--dry-run`, `--depth`,
  `--include-network`, `--include-removable`, `--local`/`--shared`, `--verbose`), and
  its scope model (home by default; `--path <folder>` for a specific folder; `--all`
  for the whole machine) with byte-identical user-visible text across both twins; every
  user-facing CLI doc that enumerates the `projects` actions lists the new action;
  `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[NEW]` entry; and
  the final subcommand name reflects the user's approval-gate confirmation, applied
  consistently across help, docs, and tests.
- **AC-13 (FR-9).** Given a GLOBAL CLI install and a discovered project OUTSIDE
  `$HOME`, when scan auto-registers it (no `--shared`), then the project is registered
  in the USER tier and the run triggers NO privilege elevation — no `sudo`, no
  shared-dir probe via `_aid_priv_run` — because the scan forced
  `_AID_TIER_OVERRIDE="--local"` (Bash) / `Resolve-AidTier -TierOverride '--local'`
  (PowerShell) before registering. Given `--shared` explicitly, the shared-tier path
  is taken exactly as `aid projects add --shared`; `--local` and the default both
  resolve to the USER tier; both twins force and honor the tier identically (parity).
- **AC-14 (NFR-9).** Given a fixture where (a) a valid project `P` contains a
  nested `.aid/` (or a whole nested project) somewhere under `P`, and (b) a project
  whose OWN folder name is an excluded name (e.g. `bin`/`obj`/`logs`) sits at a place
  the walk reaches, when scan runs, then `P` is registered exactly once and the nested
  `.aid/` under `P` is NOT separately discovered or registered (its subtree was pruned),
  while the exclusion-named project IS discovered and registered (the `.aid/` check
  precedes name-based pruning); both twins behave identically.
- **AC-15 (NFR-10).** Given a fixture where the same real project is reachable more
  than once (e.g. a directory symlink that points at an already-walked real project, or
  an overlapping/`.`-`..` path), when scan runs, then that project is canonicalized and
  registered EXACTLY ONCE (no duplicate registry line); both twins dedupe identically.
- **AC-16 (FR-5).** Given a scan whose tree includes the CLI's own state home
  (`$HOME/.aid` / `$AID_STATE_HOME`) and a path whose `.aid` is NOT a valid project dir,
  when scan runs, then the state home is NEVER registered as a project and only paths
  whose `.aid/` is a directory passing `_aid_is_project_dir` / `Test-AidIsProjectDir`
  are registered; both twins apply the check identically.

## 10. Priority

Must. This is the sole feature of the work; all §5 functional requirements and §6
guardrails are Must for the single delivery.
