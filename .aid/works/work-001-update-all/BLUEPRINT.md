# Delivery BLUEPRINT -- delivery-001: Bulk CLI Update Across Registered Projects

> **Delivery:** delivery-001
> **Work:** work-001-update-all
> **Created:** 2026-07-20

---

## Objective

Give an AID CLI maintainer a single command that updates every registered AID project to
the target version in one invocation, downloading the tool package(s) exactly once into a
shared per-run cache and applying that cache to each project through the existing
`--from-bundle` path. It is scoped as a distinct delivery because it composes three
building blocks that already exist (registry enumeration, the `resolve_version`/`fetch_tarball`
download path, and the `--from-bundle <dir>` apply branch) into one new parent-driver
command without introducing any new install or download mechanism, and without regressing
the existing single-project reach.

## Scope

- New bulk update surface `aid update all [--version <v>] [--dry-run] [--force]` — a
  positional subcommand mirroring the existing `aid update self`, intercepted before the
  non-`self` positional rejection.
- Enumerate exactly the projects the registry records — the same source `aid projects list`
  reads — via the existing raw union reader.
- Download-once-to-cache: for a given `(tool, version)`, `fetch_tarball` runs exactly once
  per run into a single ephemeral cache directory.
- Per-project apply through the EXISTING `--from-bundle <dir>` directory branch (no new
  install/copy mechanism); each project applied via a child `aid update --target <repo>
  --from-bundle <cache>` invocation.
- Failure isolation (continue-on-error) with per-project outcome reporting and an
  end-of-run summary (updated / skipped / failed counts); non-zero exit if any project failed.
- CLI self-update preamble runs at most once per bulk run (skipped under `--dry-run`).
- Implemented in both twins — `bin/aid` (bash) and `bin/aid.ps1` (PowerShell) — with
  behavior parity, per `tests/canonical/test-aid-cli-parity.sh`.

**Out of scope:** changing the behavior of the single-project `aid update` (cwd / `--target`)
reach; changing the semantics of `--from-bundle` itself (tarball/dir contract, checksum
verification, version derivation); changing the `aid projects` commands (`list` / `add` /
`remove`) or the on-disk `registry.yml` format; introducing a persistent cache (the per-run
cache is transient and destroyed on exit).

## Gate Criteria

- [ ] Given 3 registered projects updated to one version, `fetch_tarball` is invoked exactly once per `(tool, version)` and each of the 3 projects is applied from the shared cache with no per-project re-download. *(AC1)*
- [ ] The projects visited are exactly those the registry records — as enumerated by the same source `aid projects list` reads — and none outside the registry are touched. *(AC2)*
- [ ] Given 3 registered projects where P2's update fails, P1 and P3 are still updated, the summary reports P2 as failed, and the command exits non-zero. *(AC3)*
- [ ] Given `--dry-run`, the run prints the per-project plan (projects, resolved version, files that would change), performs no per-project install/commit and no destination writes (the shared cache may still be fetched once so the plan is accurate), and exits 0. *(AC4)*
- [ ] On completion, the run prints a summary reporting the counts of updated / skipped / failed projects. *(AC5)*
- [ ] Given `--version <v>`, the single cached download is version `v` and every visited project is updated to `v`. *(AC6)*
- [ ] Given a registered project whose `.aid/` no longer exists on disk, that entry is skipped (non-fatal), reflected in the summary, and the remaining projects still update. *(AC7)*
- [ ] Given identical inputs, `bin/aid` and `bin/aid.ps1` produce matching observable behavior (enumeration, download-once, failure isolation, reporting, exit code), verified by `tests/canonical/test-aid-cli-parity.sh`. *(AC8)*
- [ ] Given a registry recording N > 1 projects, running `aid update all` invokes the bulk update path (the `all` reserved word is consumed before the non-`self` positional rejection), enumerates the registry, and a dry-run prints a per-project plan for every registered project and exits 0 (not a usage error). *(AC9)*
- [ ] Given N > 1 registered projects and a stale CLI, the self-update preamble runs at most once for the whole bulk run (the parent runs it once; each child self-skips via the `--from-bundle` guard at `bin/aid:503`), not once per project; under `--dry-run` it runs zero times. *(AC10)*
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Add `aid update all` bulk-update subcommand across both CLI twins |
| task-002 | TEST | Verify bulk-update behavior and bash/pwsh twin parity via test-aid-cli-parity.sh |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-update-cli (change, artifact 'cli').
