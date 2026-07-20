# task-001: Add `aid update all` bulk-update subcommand across both CLI twins

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

**Source:** work-001-update-all -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Extend the existing `aid update` command with a new bulk surface
  `aid update all [--version <v>] [--dry-run] [--force]`, implemented in BOTH
  twins in the same change to preserve parity (SPEC § Layers & Components / KB
  `coding-standards.md` cross-platform-twins convention): a new `_cmd_update_all`
  in the bash twin (`bin/aid`) and a new `Invoke-AidUpdateAll` in the PowerShell
  twin (`bin/aid.ps1`). Every edit to one twin is mirrored in the other.
- Intercept the `all` reserved word alongside the existing `update self` intercept
  (`bin/aid:2970-3052`, `bin/aid.ps1:2803-2825`) -- before the generic add/remove/update
  flag loop and before the non-`self` positional rejection (`bin/aid:3189-3195`).
- Reject `--target` when combined with `all` (registry supplies the targets): fail
  with a usage error, exit 2.
- On a real run, invoke the CLI self-update preamble (`_aid_update_self_if_stale` /
  `Invoke-AidUpdateSelfIfStale`) exactly once, at the top, before enumeration. Introduce
  NO new sentinel or bulk-specific env var: each child is invoked with `--from-bundle
  <cache>` (see the per-project loop below), and the EXISTING self-update guard already
  short-circuits on that bundle (`bin/aid:503` -- `[[ -n "${_AID_FROM_BUNDLE:-}" ]] &&
  return 0`; the PowerShell twin `bin/aid.ps1:535` -- `if ($FromBundle) { return }`), so
  every child self-skips its own preamble with no bulk-specific flag. This is the
  "at most once per bulk run" mechanism -- parent runs it once, children self-skip via
  the existing bundle guard. Skip the preamble entirely under `--dry-run`.
- Resolve the single run version once -- `--version <v>` pinned (leading `v` stripped),
  else `resolve_version` -- governing the whole run.
- Create a transient per-run cache via `mktemp -d` with an EXIT trap that destroys it
  on exit (mirroring the single-project `_AID_STAGING_BASE` pattern).
- Enumerate projects from the RAW registry union reader (`_registry_read_raw_union` /
  `Get-RegistryRawUnion`) -- the exact source `aid projects list` reads.
- Per-project loop (continue-on-error): skip (non-fatal) any project whose `.aid/` is
  absent on disk; populate the cache download-once via a presence-guarded
  `fetch_tarball <tool> <version> <cache>` per distinct `(tool, version)`; apply via a
  child `aid update --target <repo> --from-bundle <cache> [--force] [--dry-run]`
  invocation (the existing `--from-bundle` directory branch, no new fetch); record each
  outcome (exit 0 -> updated, non-zero -> failed).
- Print an end-of-run summary listing per-project outcomes and the counts
  `N updated, M skipped, K failed`; exit 0 on all-success or dry-run, exit 1 if any
  project failed (skips alone do not fail the run).
- Leave the existing single-project `aid update` (cwd / `--target`), `aid update self`,
  `--from-bundle`, and `--dry-run` behavior unchanged; introduce no new install,
  download, or registry-write mechanism.

**Acceptance Criteria:**
- [ ] Given 3 registered projects updated to one version, `fetch_tarball` is invoked
  exactly once per `(tool, version)` and each of the 3 projects is applied from the
  shared cache with no per-project re-download. *(SPEC AC1)*
- [ ] The projects visited are exactly those the raw registry union reader records --
  the same source `aid projects list` reads -- and none outside the registry are
  touched. *(SPEC AC2)*
- [ ] Given 3 registered projects where P2's child update fails, P1 and P3 are still
  updated, P2 is recorded as failed, the run does not abort, and the command exits
  non-zero. *(SPEC AC3)*
- [ ] Given `--dry-run`, the run prints the per-project plan (projects, resolved version,
  files that would change), performs no destination writes, and exits 0. *(SPEC AC4)*
- [ ] On completion the run prints a summary reporting the counts of updated / skipped /
  failed projects. *(SPEC AC5)*
- [ ] Given `--version <v>`, the single cached download is version `v` and every visited
  project is updated to `v`. *(SPEC AC6)*
- [ ] Given a registered project whose `.aid/` no longer exists on disk, that entry is
  skipped (non-fatal), reflected in the summary, and the remaining projects still update.
  *(SPEC AC7)*
- [ ] `--target` supplied with `all` fails with a usage error (exit 2), and the existing
  single-project `aid update` / `aid update self` / `--from-bundle` / `--dry-run` behavior
  is left unchanged. *(SPEC § Feature Flow step 2, § Layers & Components)*
- [ ] Both twins implement the identical behavior in this change -- `bin/aid`
  `_cmd_update_all` and `bin/aid.ps1` `Invoke-AidUpdateAll` mirror each edit (parity
  implementation; verification is task-002). *(SPEC AC8 -- implementation half)*
- [ ] `aid update all` is consumed as a reserved subcommand: the `all` word is intercepted
  alongside the `update self` intercept, BEFORE the non-`self` positional rejection
  (`bin/aid:3189-3195`), so it is never treated as an unknown positional / rejected as a
  usage error; the bulk path is invoked and enumerates the registry (a dry-run prints a
  per-project plan for every registered project and exits 0). *(SPEC AC9)*
- [ ] The CLI self-update preamble runs at most once per bulk run -- the parent runs it
  once before enumeration and each child self-skips it via the EXISTING `--from-bundle`
  guard (`bin/aid:503` -- `[[ -n "${_AID_FROM_BUNDLE:-}" ]] && return 0`; twin
  `bin/aid.ps1:535`), not once per project -- and runs zero times under `--dry-run`.
  *(SPEC AC10)*
- [ ] All section-6 quality gates pass.
