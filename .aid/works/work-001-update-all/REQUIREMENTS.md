# Requirements

- **Name:** Bulk CLI Update Across Registered Projects
- **Description:** Add a bulk option to `aid update` that updates every registered AID project from a single cached package download, applying each via the existing `--from-bundle` path

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-20 | Initial capture (shortcut: aid-update-cli) | /aid-update-cli |

## 1. Objective

Add an "all" option to the `aid update` CLI command that walks every registered
AID project and applies the update to each one in a single invocation. To avoid
re-downloading the tool package(s) once per project, download the package a
single time into a cached folder and apply the update to each project from that
cache using the existing `--from-bundle` option.

This is a **change** to the existing `aid update` command surface (verb:
`change`, artifact: `cli`); it modifies the update command's behavior/intent by
adding a new capability, and it does not create a new command from scratch. The
current single-project reach and the semantics of `--from-bundle` stay as they
are (see §4 Out of Scope).

## 2. Problem Statement

Today `aid update` operates on exactly one project: the current directory, or
`--target <dir>` (`bin/aid` lines 3197-3202, 3419-3578). A maintainer with
several registered AID projects must `cd` into each one and run `aid update`
separately. Each of those runs downloads the tool package(s) again (`fetch_tarball`
via `_prepare_tool_staging_aid`, `bin/aid` lines 3400-3411), so updating N
projects means N redundant downloads of the same artifact — wasteful and slow,
especially on a metered or slow link. There is no single command to bring all
registered projects to the current version, and no way to reuse one download
across them.

The building blocks to fix this already exist and are unused for this purpose:
the CLI already knows every registered project (`_registry_read_raw_union`,
`bin/aid` lines 1481-1498 — the same source `aid projects list` reads), it
already iterates that registry for the post-`update self` migration sweep
(`bin/aid` line 3003), and `--from-bundle <dir>` already applies a pre-downloaded
bundle to a project without hitting the network (`_prepare_tool_staging_aid`
directory branch, `bin/aid` lines 3367-3399). What is missing is a command that
composes them: enumerate → download once → apply-from-cache to each.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID CLI maintainer / developer | A developer running the `aid` CLI who has multiple AID projects registered (via `aid projects add`) on one machine | Update all registered projects to the current version in one command, without re-downloading the package per project, and without silently skipping or corrupting any project when one fails |

## 4. Scope

### In Scope

- A new **bulk update capability** on `aid update` that applies the update to
  every registered project in a single invocation.
- **Download-once-to-cache:** the tool package(s) are fetched exactly once per
  run into a single cache/staging folder.
- **Per-project apply via the EXISTING `--from-bundle`:** each registered
  project is updated by driving the existing tool-update path with the shared
  cache directory as its bundle — reusing the directory-bundle branch that
  already scans for `aid-<tool>-v*.tar.gz` and checksum-verifies each
  (`bin/aid` lines 3367-3399).
- **Both twins:** the capability is implemented in `bin/aid` (bash) and
  `bin/aid.ps1` (PowerShell) with behavior parity.

### Out of Scope

- Changing the behavior of the existing single-project `aid update` (cwd /
  `--target`) reach.
- Changing the semantics of `--from-bundle` itself (its tarball/dir contract,
  checksum verification, or version derivation).
- Changing the `aid projects` commands (`list` / `add` / `remove`) or the
  on-disk registry format (`registry.yml`).
- `aid update self` (CLI self-update) mechanics beyond deciding when the
  existing self-update preamble runs during a bulk run (see §5).
- Any new install/download mechanism parallel to `--from-bundle` and the
  existing `fetch_tarball`/`resolve_version` download path.

## 5. Functional Requirements

**FR1 — Bulk invocation.** `aid update` gains a way to request "update every
registered project" in one command. *(Deferred to SPEC: the exact surface —
`aid update all` positional subcommand vs. `aid update --all` flag. Note the
current code rejects ANY non-`self` positional on `aid update` at `bin/aid`
lines 3189-3195; SPEC must reconcile this if a positional `all` form is chosen.
State captured as the capability, not the syntax.)*

**FR2 — Enumerate registered projects.** The bulk update visits exactly the
projects the registry records — the same source `aid projects list` reads: the
deduped union of `$AID_STATE_HOME/registry.yml` and the `$HOME/.aid/registry.yml`
fallback tier (`_registry_read_raw_union`, `bin/aid` lines 1481-1498 — the reader
`aid projects list` uses, per the comment at `bin/aid` line 1479; PowerShell twin
`Get-RegistryRawUnion` at `bin/aid.ps1` ~line 1441). *(Deferred to SPEC: whether
to reuse the `.aid/`-present quiet-prune variant `_registry_read_union` (`bin/aid`
lines 1455-1472) or the raw union `aid projects list` reads
(`_registry_read_raw_union`, lines 1481-1498).)*

**FR3 — Download once into a cache folder.** The tool package(s) for the run are
downloaded exactly once into a single cache/staging directory, not re-fetched
per project. *(Deferred to SPEC: the exact cache-dir location — e.g. a per-run
temp dir vs. a persistent path under the state home.)*

**FR4 — Apply per project via the existing `--from-bundle`.** Each registered
project is updated by invoking the existing tool-update path pointed at the
shared cache directory as its bundle, reusing the directory-bundle branch that
scans for `aid-<tool>-v*.tar.gz` and runs `verify_bundle_checksum` on each
(`bin/aid` lines 3367-3399). No new install mechanism is introduced.

**FR5 — Per-project result reporting.** For each project, report its outcome
(e.g. updated / skipped / failed), and print a run summary at the end with the
counts (N updated, M skipped, K failed).

**FR6 — Failure isolation (continue-on-error).** A failure updating one project
MUST NOT abort the run: the bulk update continues with the remaining projects,
records the failure in that project's result and the summary, and exits non-zero
if any project failed. This deliberately differs from the single-project reach,
which exits immediately on a mid-commit failure (`bin/aid` lines 3544-3551).

**FR7 — Interaction with existing flags.**
- `--version <v>`: pins the single cached download — and therefore every project
  — to version `v`. *(Deferred to SPEC: how this composes with the fact that the
  bulk path internally applies from a cache/bundle, given `--from-bundle` and
  `--version` are mutually exclusive on the single-project reach at `bin/aid`
  lines 3237-3240 — here `--version` selects what gets downloaded once, it is
  not a user-supplied `--from-bundle`.)*
- `--dry-run`: prints the plan for every registered project (which projects, the
  resolved version, files that would change). The shared cache may still be
  populated once (a `fetch_tarball` into the transient cache) so the plan is
  accurate, but NO per-project install/commit and NO destination writes occur —
  mirroring the single-project dry-run, which likewise stages the download to a
  temp dir before printing the plan and exiting with no writes (`bin/aid` lines
  3496-3534), extended across the registry.
- `--force`: passed through to each per-project apply (overwrite differing
  files).
- `--target <dir>`: not meaningful in bulk mode (the registry supplies the
  targets). *(Deferred to SPEC: reject with a usage error vs. ignore.)*

**FR8 — CLI self-update in bulk mode.** Define that the existing
self-update-if-stale preamble (`bin/aid` lines 3222, 3231) runs at most once for
the whole bulk run, not once per project. *(Deferred to SPEC: exact placement.)*

**FR9 — Twin parity.** The capability is implemented in both `bin/aid` and
`bin/aid.ps1` (`-All` / bulk surface mirroring the bash form) with identical
observable behavior, per the CLI parity convention enforced by
`tests/canonical/test-aid-cli-parity.sh`.

## 6. Non-Functional Requirements

- **Efficiency (the core NFR):** for a run over N registered projects, the tool
  package for a given version is downloaded **exactly once**, not N times — the
  per-project apply reads from the shared cache with no additional network
  fetch. This is the explicit motivation for the feature and is directly
  testable (fetch/download invocation count == 1 for a single-version run over
  N > 1 projects).
- **Cross-platform parity:** behavior must match between the bash twin
  (`bin/aid`) and the PowerShell twin (`bin/aid.ps1`); neither may diverge in
  enumeration, download-once behavior, failure isolation, or reporting (see
  `coding-standards.md` on cross-platform twins; enforced by
  `tests/canonical/test-aid-cli-parity.sh`).
- Security, reliability targets beyond the existing download-integrity
  guarantees (checksum verification, already inherited via `--from-bundle`):
  N/A.

## 7. Constraints

- **Reuse `--from-bundle`.** The per-project apply MUST go through the existing
  `--from-bundle` directory-bundle path (`bin/aid` lines 3367-3399); do NOT add
  a parallel install/copy mechanism.
- **Twin parity.** Any change to `bin/aid` must be mirrored in `bin/aid.ps1`;
  the pair is verified by `tests/canonical/test-aid-cli-parity.sh` (see KB
  `coding-standards.md`).
- **Registry format unchanged.** The bulk update only *reads* the registry via
  the existing registry-union reader (`_registry_read_union` /
  `_registry_read_raw_union`); the `registry.yml` schema (YAML list
  items, managed exclusively by `aid projects add`/`remove`) is not modified
  (see KB `integration-map.md` — the connectors/project registry is a catalog,
  read-only on this path).
- Must not regress the existing single-project `aid update`, `aid update self`,
  or `--dry-run` behavior.

## 8. Assumptions & Dependencies

- The projects registry and its reader (`_registry_read_union` /
  `_registry_read_raw_union`, `bin/aid` lines 1455-1498; PowerShell twin
  ~line 1398) already exist and are the authoritative project source.
- `--from-bundle` with a directory argument already exists, scans for
  `aid-<tool>-v*.tar.gz`, and checksum-verifies each tarball
  (`_prepare_tool_staging_aid`, `bin/aid` lines 3367-3399).
- The download path (`resolve_version` / `fetch_tarball` in
  `lib/aid-install-core.sh`, invoked at `bin/aid` lines 3400-3411) is the
  package source for the single cached download.
- Iterating the whole registry in one command is an established pattern — the
  post-`update self` migration sweep already does it (`bin/aid` lines 2996-3045,
  iterating the registry at `bin/aid` line 3003) — so no new registry-iteration
  infrastructure is required.
- Per KB `capability-inventory.md` and `module-map.md`, `aid` is the multi-tool
  installer/CLI; this change lives in the CLI dispatcher module (`bin/aid`,
  `bin/aid.ps1`) atop the shared install core.

## 9. Acceptance Criteria

**AC1 — Download once, apply from cache (→ FR3, FR4).** Given 3 registered
projects, When the bulk update runs for one version, Then the tool package is
downloaded exactly once into the cache folder and each of the 3 projects is
updated from that cached bundle (no per-project re-download). *Testable:*
observed download/`fetch_tarball` invocations == 1.

**AC2 — Correct enumeration (→ FR2).** Given the registry records projects
P1..Pn, When the bulk update runs, Then exactly those projects — as enumerated
by the same source `aid projects list` reads — are visited, and none outside the
registry.

**AC3 — Failure isolation (→ FR6).** Given 3 registered projects where P2's
update fails, When the bulk update runs, Then P1 and P3 are still updated, the
summary reports P2 as failed, and the command exits non-zero.

**AC4 — Dry-run performs no writes (→ FR7 dry-run).** Given `--dry-run`, When the
bulk update runs, Then it prints the per-project plan (projects, version, files
that would change) and performs no per-project install/commit and no destination
writes — the shared cache may still be fetched once so the plan is accurate — and
exits 0.

**AC5 — Run summary (→ FR5).** Given the run completes, Then a summary reports
the counts of updated / skipped / failed projects.

**AC6 — Version pinning (→ FR7 version).** Given `--version <v>`, When the bulk
update runs, Then the single cached download is version `v` and every visited
project is updated to `v`.

**AC7 — Skip an unavailable project (→ FR2, FR6).** Given a registered project
whose `.aid/` no longer exists on disk, When the bulk update runs, Then that
entry is skipped (non-fatal) and reflected in the summary, and the remaining
projects still update. *(Note: `_registry_read_union` already quiet-prunes such
entries at `bin/aid` lines 1467-1471; SPEC confirms skip-vs-report.)*

**AC8 — Twin parity (→ FR9).** Given identical inputs, When the bulk update runs
via `bin/aid` and via `bin/aid.ps1`, Then observable behavior (enumeration,
download-once, failure isolation, reporting, exit code) matches — verified by
`tests/canonical/test-aid-cli-parity.sh`.

**AC9 — Bulk invocation surface (→ FR1).** Given a registry recording N > 1
projects, When the maintainer runs the bulk command (`aid update all`), Then the
bulk update path is invoked — the reserved word is consumed *before* the non-`self`
positional rejection (`bin/aid` lines 3189-3195), so it does not error as an
unknown positional — and the run enumerates the registry rather than acting on a
single project. *Testable:* `aid update all --dry-run` prints a per-project plan
for every registered project and exits 0 (not a usage error).

**AC10 — CLI self-update runs at most once per bulk run (→ FR8).** Given N > 1
registered projects and a stale CLI, When a real (non-dry-run) bulk update runs,
Then the self-update-if-stale preamble (`_aid_update_self_if_stale`) executes at
most once for the whole run — the parent runs it once before enumeration and each
per-project child self-skips it (the child is invoked with `--from-bundle`, which
short-circuits the preamble at `bin/aid` line 503) — not once per project.
*Testable:* the self-update logic is entered at most once across a bulk run over N
projects, and zero times under `--dry-run`.

## 10. Priority

Must
