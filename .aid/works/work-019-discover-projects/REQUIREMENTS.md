# Requirements

- **Name:** Machine Scan to Discover and Register AID Projects
- **Description:** Add an `aid` CLI subcommand that searches the machine for folders containing a `.aid/` directory and registers each as a project without modifying any of them

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | Initial capture (shortcut: aid-update-cli) | /aid-update-cli |

## 1. Objective

Add a new `aid` CLI command that finds every AID project on the machine and adds
it to the project registry in one pass. Today a project only enters the registry
when the user runs `aid projects add` inside it (or a tool op registers it
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
The user wants a single command that crawls the machine, detects `.aid/` roots,
and registers each — surfacing versions but changing nothing inside the projects.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID CLI user / developer | Runs `aid` across many local repos | One command to find and register every `.aid/` project; a clear report of what was found and each project's version; confidence that nothing inside the projects was touched |
| AID maintainer | Owns `bin/aid`, `bin/aid.ps1`, and the parity suite | A behavior-identical Bash/PowerShell twin pair that reuses the existing registration and version-reading helpers, guarded by the parity suite |

## 4. Scope

### In Scope

- A new `aid` CLI subcommand (working name `aid projects scan`; §5 FR-1 — final
  name confirmed at the approval gate) that:
  - Scans the whole machine by default, or a single subtree when a `<root>` is given.
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

## 5. Functional Requirements

- **FR-1 — New subcommand.** Provide a new `aid` CLI subcommand (working name
  `aid projects scan`) that searches the machine for folders containing a `.aid/`
  subdirectory and registers each as a project. It is register-only and MUST NOT
  update, install, or migrate any project.
- **FR-2 — Whole-machine default scope.** With no `<root>` argument, the command
  scans the whole machine: on Windows it enumerates every local FIXED drive
  (`C:\`, `D:\`, …); on Unix it walks from `/`. Behavior is identical (parity)
  across the Bash and PowerShell twins.
- **FR-3 — Narrowing.** `aid projects scan <root>` scans only that subtree (fast
  path). A `<root>` that is not an existing directory is a usage error (exit 2).
  An optional `--depth <n>` caps recursion at `n` levels below each scan root;
  `<n>` MUST be a non-negative integer — a non-integer OR negative `--depth` value
  (e.g. `--depth abc`, `--depth -1`) is a usage error (exit 2). Both twins reject
  the same set of `--depth` values identically (parity).
- **FR-4 — Dry run.** `--dry-run` lists the projects that WOULD be registered and
  makes zero writes to any registry file, exiting 0.
- **FR-5 — Register-only and idempotent.** Registration reuses the EXISTING path
  (`registry_register` + `_aid_resolve_tier` in Bash; `Registry-Register` +
  `Resolve-AidTier` in PowerShell) — the same `registry.yml` the `aid projects add` /
  `aid projects list` commands use. A project already in the registry is skipped
  (set-insert idempotent; no duplicates). A folder without a `.aid/` is never
  scaffolded and never registered. No project's `.aid/` is ever modified.
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
  whole-machine scan can never trigger privilege elevation. It does this by setting
  the existing tier-override before it registers each project — `_AID_TIER_OVERRIDE="--local"`
  in Bash / `Resolve-AidTier -TierOverride '--local'` in PowerShell — instead of
  leaving the tier to the auto-rule. This matters because the auto-rule
  (`_aid_resolve_tier` / `Resolve-AidTier`) returns the SHARED tier whenever the
  install is global AND the discovered path is outside `$HOME` (the common case for
  a whole-machine crawl), and the shared branch of `registry_register` probes the
  shared dir through `_aid_priv_run` → `sudo` — a real elevation prompt the scan
  must never provoke. The forcing is a USE of the existing override API; the tier
  helpers themselves are reused unchanged. `--shared` remains available and, when
  explicitly passed, is honored exactly as `aid projects add --shared` (override set
  to `--shared`); `--local` and the default both resolve to the USER tier. (§8
  records the resolved decision; the user still sees and may override the forced
  tier at the approval gate.)
- **FR-10 — Documentation & help output.** The shipped `aid projects -h` help
  documents the new subcommand, all of its flags (`--dry-run`, `--depth`,
  `--include-network`, `--include-removable`, `--local`/`--shared`, `--verbose`),
  and its default whole-machine scope, with byte-identical user-visible text across
  the two twins. Every user-facing CLI doc that enumerates the `projects` actions
  (README / CLI reference) lists the new action alongside `list`/`add`/`remove`, and
  a `[NEW]` entry is added to `.aid/knowledge/release-tracking.md` `## Unreleased`.
  The final subcommand name confirmed at the approval gate is applied consistently
  across help text, docs, and test identifiers.

## 6. Non-Functional Requirements

Guardrails — all are load-bearing and MUST hold on both twins with identical
classification (parity):

- **NFR-1 — Never abort on an unreadable directory.** A permission-denied or
  otherwise unreadable directory is skipped; the scan continues.
- **NFR-2 — Prune heavy/irrelevant trees (match by basename ANYWHERE).** Well-known
  heavy or irrelevant directories are pruned (not descended) wherever they occur in
  the tree — the match is on the directory's BASENAME at ANY depth: version-control
  object stores and common language/package caches — including `node_modules`,
  `.git`, `.hg`, `.svn`, `.venv`, `venv`, `__pycache__`, `target`, `dist`, `build`,
  `.gradle`, `.m2`, `.cargo`, `.npm`, `.cache`, `vendor`, `Pods`. These names are a
  heavy/cache set distinct from the OS/system set in NFR-3, and the set is a single
  shared list, byte-identical across the two twins.
- **NFR-3 — Skip OS/system trees (match ROOT-ONLY).** OS/system directories are
  skipped ONLY at the TOP LEVEL of a scan root — i.e. as an immediate child of a scan
  root. In the whole-machine default a scan root IS a drive/filesystem root (`C:\` on
  Windows, `/` on Unix), so this targets true OS locations such as `C:\Windows` and
  `/proc`; under a `<root>` scan it is the immediate children of `<root>`. The same
  name deeper in the tree (e.g. an ordinary `dev/` or `run/` subfolder inside a
  project) is NOT pruned. The root-only names are: on Windows, `Windows`,
  `Program Files`, `Program Files (x86)`, `$Recycle.Bin`, `System Volume Information`;
  on Unix, `proc`, `sys`, `dev`, `run` (i.e. `/proc`, `/sys`, `/dev`, `/run`). This is
  a second shared list, separate from the NFR-2 heavy/cache set and byte-identical
  across the two twins, so an ordinary `dev/`/`run/` subfolder nested below the top
  level is never falsely pruned.
- **NFR-4 — Symlink-loop guard.** The walk does not follow directory symlinks (or
  otherwise guards against revisiting a real path), so a symlink cycle can never
  cause an infinite loop; the scan always terminates.
- **NFR-5 — Skip network + removable drives by default.** Network and removable
  drives are excluded from the default whole-machine scan; `--include-network` and
  `--include-removable` opt them back in. Drive-type classification is identical
  across twins.
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
- **Open point for the approval gate — whole-machine scan cost.** A first-run
  whole-machine crawl of large disks can take minutes even with pruning; `<root>` is
  the fast path and progress output is the mitigation. Whether a full crawl should
  ask for confirmation, or honor an `AID_SCAN_ROOT` override, is deferred to the gate.
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
- **AC-2 (FR-2).** Given no `<root>` argument, when scan runs, then on Windows it
  enumerates local FIXED drives only (network + removable excluded by default) and on
  Unix walks from `/`; the Bash and PowerShell twins classify drives identically.
- **AC-3 (FR-3).** Given `aid projects scan <root>`, when `<root>` is a directory,
  then only that subtree is scanned; when `<root>` is not a directory, exit 2 with a
  usage error. Given `--depth <n>`, no directory deeper than `n` levels below the
  root is visited; a non-integer `--depth` value (e.g. `--depth abc`) AND a negative
  `--depth` value (e.g. `--depth -1`) each exit 2 — `<n>` must be a non-negative
  integer, and both twins reject the identical set.
- **AC-4 (FR-4).** Given `--dry-run`, when scan runs over a fixture tree, then it
  prints the projects it WOULD register, the target `registry.yml` is byte-unchanged
  (or absent stays absent), and it exits 0.
- **AC-5 (FR-5).** Given a project already registered, when scan runs (and when it is
  re-run), then that project is not added twice and is reported as
  already-registered/skipped; given a folder with no `.aid/`, scan neither scaffolds
  nor registers it.
- **AC-6 (FR-6).** Given a discovered project whose manifest carries
  `"aid_version": "X.Y.Z"` (optionally `-beta.N`), scan reports that version verbatim;
  given a `.aid/` with no valid manifest, scan reports `untracked` and does not error.
- **AC-7 (FR-7, NFR-6).** Given a completed scan, the final summary reports the
  newly-registered count, the already-registered count, and one path+version+action
  line per discovered project; a long scan emits at least one progress line to stderr.
- **AC-8 (NFR-1..NFR-4).** Given a fixture tree containing an unreadable directory, a
  heavy/cache directory (`node_modules`/`.git`/known-cache) matched by basename at any
  depth (NFR-2), an OS/system-named directory both at a scan root (must be skipped)
  and one nested deeper as an ordinary subfolder (must NOT be pruned) (NFR-3), and a
  directory-symlink cycle, when scan runs, then it skips the unreadable directory and
  continues, does not descend into the basename-matched heavy/cache directories, skips
  only the root-level OS/system directory while still discovering a project under the
  deeper same-named subfolder, and terminates (no infinite loop).
- **AC-9 (NFR-5).** Given a machine with network and/or removable drives, scan
  excludes them by default and includes them only when `--include-network` /
  `--include-removable` is passed.
- **AC-10 (FR-8, NFR-7).** Given the same fixture tree, `bin/aid` and `bin/aid.ps1`
  produce identical discovery/registration results and identical exit codes, and in
  every case no file under any discovered project's `.aid/` is created or modified;
  `tests/canonical/test-aid-cli-parity.sh` asserts this.
- **AC-11 (NFR-8).** The subcommand uses exit code 0 on a completed scan and 2 on a
  usage/argument error, prints its result to stdout and diagnostics to stderr, and the
  PowerShell twin passes `ps51-compat-check.ps1` (ASCII-only, 5.1-compatible).
- **AC-12 (FR-10).** The shipped help (`aid projects -h`) documents the new
  subcommand, its flags (`--dry-run`, `--depth`, `--include-network`,
  `--include-removable`, `--local`/`--shared`, `--verbose`), and its default
  whole-machine scope with byte-identical user-visible text across both twins; every
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

## 10. Priority

Must. This is the sole feature of the work; all §5 functional requirements and §6
guardrails are Must for the single delivery.
