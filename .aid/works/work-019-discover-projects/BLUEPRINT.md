# Delivery BLUEPRINT -- delivery-001: Machine Scan to Discover and Register AID Projects

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md — the IMMUTABLE DEFINITION for this delivery of a
flattened single-delivery (Lite) work. It is not a state file; the delivery's mutable
lifecycle/gate state lives in the work-root `STATE.md` (`## Delivery Lifecycle` / `## Delivery
Gate`), not here.

> **Delivery:** delivery-001
> **Work:** work-019-discover-projects
> **Created:** 2026-07-21

---

## Objective

Deliver a new `aid` CLI subcommand (working name `aid projects scan`) that finds every folder
containing a `.aid/` directory within a chosen scope — the user's home directory by default, a
specific folder with `--path`, or the whole machine with `--all` — and registers each in the
project registry — register-only, idempotent, and guardrailed — while reporting each project's
version and never modifying anything inside a discovered project. It ships in both CLI twins
(`bin/aid` and `bin/aid.ps1`), behavior-identical, and is proven by the cross-platform parity
suite.

## Scope

In scope for this delivery (see SPEC.md `## Technical Specification`):

- The new subcommand in both twins: home-directory default scope, `--path <folder>` narrowing,
  `--all` whole-machine scope (fixed drives on Windows, `/` on Unix — the only mode that
  enumerates drives; `--path` and `--all` mutually exclusive), `--depth`, `--dry-run`,
  `--include-network`/`--include-removable` (which extend `--all` only), `--local`/`--shared`,
  `--verbose`, `-h`.
- Guardrails: unreadable-dir skip; heavy/cache/build pruning (basename-anywhere set, now
  including `obj`/`bin`/`logs`, matched case-insensitively — NFR-2) applied in ALL modes, and an
  OS/system-dir skip (root-only set) applied ONLY under `--all` at true filesystem/drive roots —
  NOT at the HOME-default or `--path` root, so a top-level `~/dev` is descended (NFR-3); symlink-loop
  guard PLUS a hard `_AID_SCAN_MAX_DEPTH` recursion cap (independent of `--depth`) guaranteeing
  termination (NFR-4); a FIXED per-folder evaluation order that checks for a project BEFORE
  name-pruning and prunes a found project's whole subtree (NFR-9); canonicalize-and-dedupe so each
  real project registers once (NFR-10); Windows `--all` network/removable exclusion by default (a
  Windows drive-letter concept — on Unix `--all` walks all mounts under `/` and the include-flags
  are inert-with-note; NFR-5); progress output; write-confinement to the registry only;
  already-registered projects skipped with NO record change (FR-5); and USER-tier forcing so a bulk
  scan never elevates (FR-9).
- Reuse of the existing registration path and version reader (no schema or format change);
  registry writes reuse `registry_register` / `Registry-Register` unchanged and touch it only for
  NEW projects (no batched-write reimplementation).
- Parity + guardrail test coverage in `tests/canonical/test-aid-cli-parity.sh`.
- Updated `aid projects -h` help text and user-facing docs.

**Out of scope:** updating/installing/migrating any discovered project (updates stay on-demand
via `aid update`); scaffolding a `.aid/` for a folder that has none; any registry/manifest
schema change; a remote/network crawl; changing the `aid-discover` SKILL or the "Discover"
pipeline phase; a user-extensible/configurable exclusion list — the prune name-sets are built-in
and fixed for v1 (no `.aid/settings.yml` key, no `--exclude` flag); discovering an AID project
nested INSIDE another AID project (a found project's subtree is pruned, so nested projects are
intentionally not separately discovered — deliberate NFR-9 limitation); and a Unix
network/removable mount classifier (drive-type exclusion is Windows-only; on Unix `--all` the NFS/
removable mounts under `/` are not auto-excluded — NFR-5 documented limitation).

## Gate Criteria

Each criterion is concrete and independently testable; it maps one SPEC.md Acceptance Criterion
onto a delivery gate check. The grade.sh pass uses these as the rubric.

- [ ] A folder with `.aid/` present is registered by the scan and appears in `aid projects list`,
  with no host tool installed and no file inside its `.aid/` changed (AC-1).
- [ ] With no scope argument, the scan scans the user HOME directory (`$HOME`;
  `%USERPROFILE%` on Windows) with no drive enumeration; with `--all`, it enumerates local FIXED
  drives only on Windows (network + removable excluded) and walks from `/` on Unix, and both twins
  classify drives identically (AC-2).
- [ ] `aid projects scan --path <folder>` scans only that subtree; a non-directory `--path` exits
  2 (there is no positional `<root>`); `--path` together with `--all` exits 2 (mutually exclusive);
  `--depth <n>` bounds recursion and BOTH a non-integer and a negative `--depth` exit 2
  (`<n>` must be a non-negative integer), identically on both twins (AC-3).
- [ ] `--dry-run` prints the would-register list, leaves the target `registry.yml` byte-unchanged,
  and exits 0 (AC-4).
- [ ] An already-registered project is not duplicated, is reported as already-registered, and its
  existing registry record is unchanged (no re-tier, version rewrite, or reorder); a folder
  with no `.aid/` is neither scaffolded nor registered (AC-5).
- [ ] A discovered project's manifest version (with any `-beta.N` suffix) is reported verbatim, and
  a `.aid/` with no valid manifest is reported as `untracked` without error (AC-6).
- [ ] A completed scan reports newly-registered and already-registered counts plus one
  path+version+action line per project, and a long scan emits at least one progress line to
  stderr (AC-7).
- [ ] Over a fixture tree with an unreadable directory, a heavy/cache/build directory
  (incl. `obj`/`bin`/`logs`) matched by basename case-insensitively at any depth in ALL modes
  (NFR-2), and a top-level `dev`/`run` folder directly under the HOME-default/`--path` scan root
  holding a project — which MUST be DESCENDED and the project FOUND because the NFR-3 system set is
  `--all`-only (NOT pruned at a HOME/`--path` root) — plus a directory-symlink cycle and a
  pathologically deep chain, the scan skips the unreadable directory and continues, does not descend
  into the basename-matched heavy/cache directories, DESCENDS the top-level `dev`/`run` and discovers
  the project inside, and terminates in every case (symlink cycle via the guard, deep chain via the
  hard `_AID_SCAN_MAX_DEPTH` cap); separately, under `--all` an OS/system-named immediate child of a
  true root (`/proc`/`C:\Windows`) IS skipped (AC-8).
- [ ] On Windows `--all`, network and removable drives are excluded by default and included only
  with `--include-network` / `--include-removable`; on Unix `--all` the walk descends all mounts
  under `/` (network/removable NOT auto-excluded — documented limitation) and those flags are
  accepted-but-inert with a one-line note; on both platforms the flags apply to `--all` only, and
  passing either without `--all` exits 2 (AC-9).
- [ ] For the same fixture tree, `bin/aid` and `bin/aid.ps1` produce identical discovery/
  registration results and identical exit codes, no file under any project's `.aid/` is created or
  modified, and `tests/canonical/test-aid-cli-parity.sh` asserts it (AC-10).
- [ ] The subcommand exits 0 on completion and 2 on a usage error, prints result to stdout and
  diagnostics to stderr, and the PowerShell twin passes `ps51-compat-check.ps1` (AC-11).
- [ ] `aid projects -h` documents the new subcommand, its flags (`--path`, `--all`, `--dry-run`,
  `--depth`, `--include-network`, `--include-removable`, `--local`/`--shared`, `--verbose`), and
  its scope model (home by default; `--path <folder>` for a specific folder; `--all` for the whole
  machine) with byte-identical user-visible text on both twins; every user-facing CLI doc that
  enumerates the `projects` actions lists the new action; `.aid/knowledge/release-tracking.md`
  `## Unreleased` carries a `[NEW]` entry; and the shipped name reflects the approval-gate
  confirmation across help, docs, and tests (AC-12).
- [ ] On a global install, a discovered project outside `$HOME` is auto-registered in the USER tier
  with no privilege elevation (no `sudo`/`_aid_priv_run` shared-dir probe) because scan forced the
  `--local` tier override; `--shared` takes the shared path exactly as `aid projects add --shared`,
  and both twins force/honor the tier identically (AC-13).
- [ ] A found project's subtree is pruned so a `.aid/` (or whole project) nested inside a discovered
  project is NOT separately registered, while a project whose OWN folder name is an exclusion
  (`bin`/`obj`/`logs`) IS still discovered (the `.aid/` check precedes name-based pruning); both
  twins identical (AC-14).
- [ ] The same real project reachable more than once (symlink to an already-walked project, or an
  overlapping/`.`-`..` path) is canonicalized and registered exactly once; both twins dedupe
  identically (AC-15).
- [ ] The CLI's own state home (`$HOME/.aid` / `$AID_STATE_HOME`) is never registered, and only
  paths whose `.aid/` is a directory passing `_aid_is_project_dir` / `Test-AidIsProjectDir` are
  registered; both twins identical (AC-16).
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement the scan subcommand in the Bash twin (`bin/aid`) |
| task-002 | IMPLEMENT | Mirror the scan subcommand in the PowerShell twin (`bin/aid.ps1`) |
| task-003 | TEST | Parity + guardrail coverage in `tests/canonical/test-aid-cli-parity.sh` |
| task-004 | DOCUMENT | Help text, user docs, and release-tracking entry |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-update-cli (change, artifact 'cli').

The two IMPLEMENT tasks are split as Bash-reference (task-001) then PowerShell-mirror (task-002),
matching the codebase's own "Mirror of bash …" twin relationship. Per the twin-parity convention
(`coding-standards.md § Conventions` — "change BOTH twins in the same commit"), both are expected
to land together in the delivery so parity is never split across a release; the split is a
decomposition of work, not a licence to ship one twin without the other. RESEARCH/DESIGN are folded
into the SPEC and into task-001's scope. The command name, flags, the two prune name-sets (heavy/cache
matched by basename anywhere in ALL modes vs. OS/system matched root-only and applied ONLY under
`--all`), and the guardrails are settled in the SPEC. Drive enumeration happens ONLY under `--all` (the default scans the user home directory and
`--path` scans a single named folder — neither enumerates drives), and it is named for BOTH twins:
the pwsh twin uses `[System.IO.DriveInfo]::GetDrives()` natively, and the bash twin (which runs
under Git-Bash/MSYS/Cygwin on Windows) shells out to the always-present `powershell.exe` running
that SAME classifier, so classification is identical by construction. Concretising that bash shell-out is an explicit design
sub-step within task-001 (the reference twin), not a separate RESEARCH/DESIGN task — keeping this small,
well-scoped CLI change at four tasks.
