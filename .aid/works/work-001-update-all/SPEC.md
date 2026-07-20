# Bulk CLI Update Across Registered Projects

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-20 | SPEC authored from REQUIREMENTS.md | /aid-update-cli |

## Source

- REQUIREMENTS.md §1 — Objective (download-once, apply-per-project via `--from-bundle`)
- REQUIREMENTS.md §2 — Problem Statement (N redundant downloads; building blocks already exist)
- REQUIREMENTS.md §4 — Scope (reuse `--from-bundle`; both twins; registry read-only)
- REQUIREMENTS.md §5 — Functional Requirements FR1–FR9 (including the SPEC-deferred decisions in FR1/FR2/FR3/FR7/FR8)
- REQUIREMENTS.md §6 — Non-Functional Requirements (download-once efficiency; twin parity)
- REQUIREMENTS.md §7 — Constraints (reuse `--from-bundle`; twin parity; registry format unchanged)
- REQUIREMENTS.md §9 — Acceptance Criteria AC1–AC10
- REQUIREMENTS.md §10 — Priority (Must)

## Description

`aid update` today reaches exactly one project — the current directory or `--target <dir>`
(`bin/aid:3197-3202`, `bin/aid:3419-3578`) — and every such run downloads the tool
package again (`fetch_tarball` inside `_prepare_tool_staging_aid`, `bin/aid:3400-3411`).
A maintainer with several registered AID projects therefore updates them one `cd` at a
time, re-downloading the same artifact once per project.

This change adds a **bulk update capability** to `aid update`: a single invocation that
walks every registered AID project and brings each to the target version, downloading the
tool package(s) **exactly once** into a shared cache and applying that cache to each
project through the **existing** `--from-bundle` directory path. It composes three
building blocks that already exist and are unused for this purpose — registry enumeration
(`_registry_read_raw_union`, `bin/aid:1481-1498`, the same source `aid projects list`
reads), the download path (`resolve_version`/`fetch_tarball`, `lib/aid-install-core.sh:186,219`),
and the `--from-bundle <dir>` apply branch (`bin/aid:3367-3399`) — into one command:
enumerate → download once → apply-from-cache to each. No new install or download mechanism
is introduced, and the existing single-project `aid update`, `aid update self`, and
`--dry-run` behavior are unchanged.

## User Stories

- As an AID CLI maintainer with several registered projects on one machine, I want to
  update all of them to the current version in a single command so that I no longer have
  to `cd` into each project and run `aid update` separately.
- As that maintainer on a slow or metered link, I want the tool package downloaded once
  and reused across every project so that N projects cost one download, not N.
- As that maintainer, I want one project's update failure to be isolated — reported, not
  fatal — so that the remaining projects still update and I get a clear end-of-run summary
  of what succeeded, was skipped, and failed.

## Priority

Must

## Acceptance Criteria

- [ ] Given 3 registered projects, when the bulk update runs for one version, then the
  tool package is downloaded exactly once into the cache folder and each of the 3 projects
  is updated from that cached bundle with no per-project re-download (observed
  `fetch_tarball` invocations for a given `(tool, version)` == 1). *(→ REQUIREMENTS AC1)*
- [ ] Given the registry records projects P1..Pn, when the bulk update runs, then exactly
  those projects — as enumerated by the same source `aid projects list` reads — are
  visited, and none outside the registry. *(→ REQUIREMENTS AC2)*
- [ ] Given 3 registered projects where P2's update fails, when the bulk update runs, then
  P1 and P3 are still updated, the summary reports P2 as failed, and the command exits
  non-zero. *(→ REQUIREMENTS AC3)*
- [ ] Given `--dry-run`, when the bulk update runs, then it prints the per-project plan
  (projects, resolved version, files that would change) and performs no per-project
  install/commit and no destination writes — the shared cache may still be fetched once so
  the plan is accurate — exiting 0. *(→ REQUIREMENTS AC4)*
- [ ] Given the run completes, then a summary reports the counts of updated / skipped /
  failed projects. *(→ REQUIREMENTS AC5)*
- [ ] Given `--version <v>`, when the bulk update runs, then the single cached download is
  version `v` and every visited project is updated to `v`. *(→ REQUIREMENTS AC6)*
- [ ] Given a registered project whose `.aid/` no longer exists on disk, when the bulk
  update runs, then that entry is skipped (non-fatal), is reflected in the summary, and the
  remaining projects still update. *(→ REQUIREMENTS AC7)*
- [ ] Given identical inputs, when the bulk update runs via `bin/aid` and via `bin/aid.ps1`,
  then observable behavior (enumeration, download-once, failure isolation, reporting, exit
  code) matches — verified by `tests/canonical/test-aid-cli-parity.sh`. *(→ REQUIREMENTS AC8)*
- [ ] Given a registry recording N > 1 projects, when the maintainer runs `aid update all`,
  then the bulk update path is invoked — the `all` reserved word is consumed before the
  non-`self` positional rejection (`bin/aid:3189-3195`) so it is not treated as an unknown
  positional — and the run enumerates the registry (a dry-run prints a plan for every
  registered project and exits 0, not a usage error). *(→ REQUIREMENTS AC9)*
- [ ] Given N > 1 registered projects and a stale CLI, when a real (non-dry-run) bulk update
  runs, then the self-update preamble (`_aid_update_self_if_stale`) executes at most once for
  the whole run — the parent runs it once before enumeration and each child self-skips it via
  the `--from-bundle` guard (`bin/aid:503`), not once per project; under `--dry-run` it runs
  zero times. *(→ REQUIREMENTS AC10)*

---

## Technical Specification

> Added by `/aid-specify`. The `cli` artifact activates **no** conditional sections beyond
> the mandatory three (`create.md § SPEC`: `cli` → "none (mandatory three only)"); the
> command-signature / help-text / output-behavior slots live inside Feature Flow and
> Layers & Components below.

### Data Model

No persistent schema changes. This change only **reads** the projects registry via the
existing reader and writes into a **transient** cache directory; it mutates no on-disk
format.

- **Registry (read-only).** `$AID_STATE_HOME/registry.yml` and the `$HOME/.aid/registry.yml`
  fallback tier are read through the existing union reader (`bin/aid:1481-1498`); the YAML
  list-item schema, managed exclusively by `aid projects add`/`remove`, is not modified.
  Per KB `integration-map.md`, the projects/connectors registry is a **catalog** — read-only
  on this path — so the constraint in REQUIREMENTS §7 (registry format unchanged) is
  structurally honored: the bulk path never opens the registry for write.
- **Per-run bundle cache (transient).** A single ephemeral directory holds one
  `aid-<tool>-v<version>.tar.gz` per distinct tool for the run, plus the `SHA256SUMS`
  written alongside by `fetch_tarball` (`lib/aid-install-core.sh:219-225`). Its contents
  make it a valid `--from-bundle <dir>` directory (the bundle branch scans
  `aid-<tool>-v*.tar.gz` and re-runs `verify_bundle_checksum`, `bin/aid:3367-3399`). It is
  created at the start of the run and destroyed on exit (see Feature Flow); it is not a
  persisted store.
- **Manifest (read-only, per project).** Each visited project's tool set is read from its
  `.aid/.aid-manifest.json` via `manifest_list_tools` (as the single-project path already
  does at `bin/aid:3291`); the manifest is not written by the parent (the child apply
  writes it, unchanged from today).

### Feature Flow

Invocation surface (decision D1): **`aid update all`** — a positional subcommand mirroring
the existing `aid update self`. Resulting usage line:

```
aid update all [--version <v>] [--dry-run] [--force]
```

The bulk run is a **parent driver** that composes the existing single-project reach as a
per-project **child** invocation:

1. **Intercept `all` early.** `bin/aid:2970-3052` already carries a dedicated `update self`
   intercept that consumes the reserved word and its flags *before* the generic
   add/remove/update flag loop and *before* the non-`self` positional rejection at
   `bin/aid:3189-3195`. A sibling `all` intercept in that same block routes to
   `_cmd_update_all` (bash) / `Invoke-AidUpdateAll` (ps1). This is what reconciles FR1's
   note that the current code rejects any non-`self` positional on `aid update`: `all`
   becomes a second reserved word consumed *before* that rejection ever runs, exactly as
   `self` is.
2. **Reject `--target` (decision D5).** If `--target` is present with `all`, fail with a
   usage error (exit 2): the registry supplies the targets, so a caller-supplied single
   target is a mistake, not an override.
3. **Self-update preamble once (decision/FR8).** On a real (non-dry-run) run, call
   `_aid_update_self_if_stale` (`bin/aid:482`) exactly once, at the top, before enumeration.
   Each child is invoked with `--from-bundle <cache>` (step 7c), which already short-circuits
   that preamble (`bin/aid:503` — `[[ -n "${_AID_FROM_BUNDLE:-}" ]] && return 0`; see Layers &
   Components), so no child re-runs it — guaranteeing "at most once per bulk run." Under
   `--dry-run`, the preamble is skipped (a self-update is a write; dry-run makes none —
   `aid update self --dry-run` remains the way to preview a CLI self-update).
4. **Resolve the single version once (decision D7 / FR7 version).** If `--version <v>` was
   given, the pinned version is `v` (leading `v` stripped as at `bin/aid:3235`); otherwise
   call `resolve_version` once (`lib/aid-install-core.sh:186`). This one value governs the
   whole run.
5. **Create the per-run cache (decision D2).** `mktemp -d` an ephemeral directory and
   register an EXIT trap to remove it — mirroring the single-project staging pattern
   (`_AID_STAGING_BASE`, `bin/aid:3322-3323`).
6. **Enumerate projects (decision D3 / FR2).** Read `_registry_read_raw_union`
   (`bin/aid:1481-1498`) — the exact source `aid projects list` reads — into the project
   list (AC2).
7. **Per-project loop (decision D4 — continue-on-error):**
   a. **Availability check (AC7).** If `<repo>/.aid` does not exist, record the project as
      **skipped** with a notice and continue (non-fatal). Using the *raw* union (not the
      quiet-prune `_registry_read_union`) is what makes this skip observable and reportable.
   b. **Populate cache download-once (AC1).** Read the project's manifest tools
      (`manifest_list_tools`). For each `(tool, pinned-version)` whose
      `aid-<tool>-v<version>.tar.gz` is **not already present** in the cache, call
      `fetch_tarball <tool> <version> <cache>` once. The presence guard is the download-once
      mechanism: the first project needing a tool downloads it; later projects find it
      cached. Under `--dry-run` the cache is still populated (identical to the single-project
      dry-run, which stages a download to temp at `bin/aid:3496-3504` before printing the
      plan) so the per-file plan is accurate — but no per-project install/commit or
      destination write occurs either way.
   c. **Apply via the existing `--from-bundle` (FR4).** Invoke the single-project reach as a
      child pointed at the shared cache:
      `aid update --target <repo> --from-bundle <cache> [--force] [--dry-run]`. The child's
      `_prepare_tool_staging_aid` takes the directory-bundle branch (`bin/aid:3367-3399`),
      scans the cache for each of its manifest tools, re-verifies the checksum, extracts,
      and commits — with **no network fetch** (satisfying the download-once NFR).
   d. **Record outcome (FR5/FR6).** Capture the child's exit code: 0 → **updated**;
      non-zero → **failed** (recorded, run continues to the next project — deliberately
      unlike the single-project path, which exits immediately on a mid-commit failure at
      `bin/aid:3544-3551`).
8. **Summary and exit code (decision D4 / AC3, AC5).** Print an end-of-run summary with the
   per-project outcomes and the counts `N updated, M skipped, K failed`. Exit 0 iff `K == 0`;
   exit 1 if any project failed. Skips alone do not fail the run (AC7 non-fatal).

`--dry-run` (FR7 dry-run / AC4): step 3 (self-update) is skipped; steps 4–7 run — so the
shared cache may still be fetched once (step 7b) to compute an accurate plan — but every
child is invoked with `--dry-run`, so each prints its per-project file plan and makes zero
per-project install/commit and zero destination writes (mirroring `bin/aid:3509-3534` per
project); the run exits 0.

`--force` (FR7 force): passed through verbatim to each child, which forwards it to
`install_tool` (`bin/aid:3544`) to overwrite differing files.

### Layers & Components

Per KB `module-map.md`, this change lives entirely in the **CLI dispatcher module**
(`bin/aid`, `bin/aid.ps1`) atop the shared install core (`lib/aid-install-core.sh`); no
other module is touched.

- **`bin/aid` (bash) — new `_cmd_update_all`.** Added alongside the existing `update self`
  intercept (`bin/aid:2970-3052`). Reuses, does not reimplement: `_registry_read_raw_union`
  (`:1481`), `manifest_list_tools` (`:3291`), `resolve_version`/`fetch_tarball`
  (`lib/aid-install-core.sh:186,219`), `_aid_update_self_if_stale` (`:482`), and the entire
  single-project apply path via a child `aid update --target <repo> --from-bundle <cache>`
  invocation (`:3419-3578`, whose `--from-bundle` branch is `:3367-3399`).
- **Child-preamble guard (FR8).** No new sentinel is needed. Each child is invoked with
  `--from-bundle <cache>` (Feature Flow step 7c), which sets `_AID_FROM_BUNDLE`; the
  self-update preamble already short-circuits on that
  (`_aid_update_self_if_stale`, `bin/aid:503` — `[[ -n "${_AID_FROM_BUNDLE:-}" ]] && return 0`),
  so every child self-skips `_aid_update_self_if_stale` via the existing bundle guard. The
  parent has already run the self-update once at the top of the run (step 3), so the CLI
  self-update runs at most once per bulk run without any bulk-specific flag. The PowerShell
  twin behaves identically: `Invoke-AidUpdateSelfIfStale` returns early on a bundle
  (`bin/aid.ps1:535`).
- **`bin/aid.ps1` (PowerShell twin) — new `Invoke-AidUpdateAll`.** Behavior-parity mirror.
  It reuses the twin's already-present equivalents: `Get-RegistryRawUnion`
  (`bin/aid.ps1:1441`, the raw variant `aid projects list` uses at `:1637`),
  `Invoke-AidUpdateSelfIfStale` (`:528`), and the `all` sibling of the `self` intercept
  (`bin/aid.ps1:2803-2825`, which already switches on `$script:_RemArgs[0] -eq 'self'`). The
  surface accepts both the PowerShell-style and POSIX-style spellings the twin already
  supports for other flags (`--dry-run`/`-DryRun`, `--force`/`-Force`/`-y`,
  `--version`/`-Version`), matching how `update self` flags are parsed at `:2811-2822`.
- **Twin parity (decision D6 / FR9 / AC8).** Both implementations must be observably
  identical in enumeration source, download-once behavior, failure isolation, summary
  format, and exit code, per the cross-platform-twins convention in KB `coding-standards.md`
  and enforced by `tests/canonical/test-aid-cli-parity.sh` (KB `test-landscape.md`). Any
  edit to `_cmd_update_all` must be mirrored in `Invoke-AidUpdateAll` in the same change.
- **Exit codes.** Follow KB `coding-standards.md` conventions already used on this path:
  `2` for the usage error (`--target` with `all`, matching the mutual-exclusion/usage exits
  at `bin/aid:3189`, `:3238`), `0` on all-success or dry-run, `1` when any project failed.
- **Download integrity.** Inherited unchanged — `fetch_tarball` verifies on download and the
  `--from-bundle` branch re-runs `verify_bundle_checksum` (`bin/aid:3380`), so the
  bulk path adds no new trust surface (KB `coding-standards.md`, download-integrity
  convention).
