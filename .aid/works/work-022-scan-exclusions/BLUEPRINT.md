# Delivery BLUEPRINT -- delivery-001: Expanded scan prune sets + user-configurable exclusions

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md — the IMMUTABLE DEFINITION for this delivery of a
flattened single-delivery (Lite) work. It is not a state file; the delivery's mutable
lifecycle/gate state lives in the work-root `STATE.md` (`## Delivery Lifecycle` / `## Delivery
Gate`), not here.

> **Delivery:** delivery-001
> **Work:** work-022-scan-exclusions
> **Created:** 2026-07-22

---

## Objective

Eliminate the false-positive project registrations `aid projects scan` produces on a real
developer machine by expanding the two built-in directory-prune tiers (Tier A heavy/cache,
Tier B OS/system) in both CLI twins — kept byte-identical — and by adding a machine-level
`scan-config.yml` that users can extend with their own directory names, additively merged
(extend-only) with the built-in Tier-A defaults. Scoped as one delivery because the twin
edits, the config merge, its tests, and its docs are a single indivisible behavior change.

## Scope

- Expand `_AID_SCAN_PRUNE_DIRS` / `$script:AidScanPruneDirs` (Tier A) and
  `_AID_SCAN_SYSTEM_DIRS` / `$script:AidScanSystemDirs` (Tier B) per REQUIREMENTS §5, byte-
  identical across `bin/aid` and `bin/aid.ps1`.
- Add the user-level `scan-config.yml` at the CLI state home: first-run seeding with the
  expanded Tier-A defaults, once-per-run read, additive case-insensitive-deduped merge with
  the built-in Tier-A set, hardcoded built-in fallback when absent.
- Parity + guardrail tests in `tests/canonical/test-aid-cli-parity.sh`.
- Documentation: CLI reference, install help, and the release-tracking `## Unreleased`.

**Out of scope:** honoring `.gitignore` (`--respect-gitignore` is possible future work);
making Tier B user-configurable; disabling a built-in default via config; glob/substring
matching; the accepted un-fixable gaps (`cmake-build-*`, `*.egg-info`, Go `~/go/pkg/mod`);
any change to scan flags, scope model, tier forcing, dedupe, or the register-only contract.

## Gate Criteria

- [ ] Both twins' Tier-A sets contain the current 20 names plus every REQUIREMENTS §5
  Tier-A addition, byte-identical (same names, same order). (AC-1)
- [ ] Both twins' Tier-B sets contain the current set plus every §5 Tier-B addition, byte-
  identical. (AC-2)
- [ ] A HOME-default scan prunes any new Tier-A-named directory at any depth and does not
  register a stray `.aid/` beneath it. (AC-3)
- [ ] A new Tier-B name prunes only as an immediate child of an `--all` drive/filesystem
  root, and is NOT pruned deeper or under HOME-default/`--path`. (AC-4)
- [ ] A directory named `build`/`bin`/`.vscode` that contains a valid `.aid/` is still
  discovered (is-project check precedes name-prune). (AC-5)
- [ ] A non-`--dry-run` scan with no config seeds `scan-config.yml` (`schema: 1` +
  `prune_dirs:` block of the expanded Tier-A defaults) beside `registry.yml`; a `--dry-run`
  scan creates no file. (AC-6)
- [ ] A `prune_dirs:` entry that is not a built-in default is pruned in addition to the
  built-ins (extend-only union). (AC-7)
- [ ] A `prune_dirs:` entry repeating a built-in name changes nothing (deduped union, no
  error). (AC-8)
- [ ] A missing / unreadable / `prune_dirs`-less config yields exit 0 using the built-in
  set with no config error. (AC-9)
- [ ] Given an identical config + fixture, both twins read the same entries (including a
  spaced `- Code Cache`), produce the identical discovered set, and exit identically;
  `test-aid-cli-parity.sh` asserts it. (AC-10)
- [ ] The config is read and the merged prune set computed exactly once per run, with no
  per-directory fork introduced. (AC-11)
- [ ] `ps51-compat-check.ps1` passes on the edited `bin/aid.ps1`; the bash arrays remain
  valid with spaced entries quoted. (AC-12)
- [ ] CLI reference (`cli.mdx`) + `docs/install.md` scan help document the exclusion
  behavior and `scan-config.yml`; `.aid/knowledge/release-tracking.md` `## Unreleased` has
  a `[CHANGE]` entry. (AC-13)
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Expand both twins' Tier-A + Tier-B built-in prune sets and add the user-level config read, merge, and seed |
| task-002 | TEST | Parity + guardrail tests for the expanded prune sets and the config merge |
| task-003 | DOCUMENT | Document scan exclusions + `scan-config.yml` in the CLI reference, install help, and release ledger |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-change-cli (change, artifact 'cli').

Grounding: `bin/aid` scan code ~:2932-3317 (constants ~:2948/2955/2961, membership test
`_aid_scan_name_in_set` ~:2971, walk `_aid_scan_walk_node` ~:3081, orchestrator
`_cmd_projects_scan` ~:3186); `bin/aid.ps1` scan code ~:2099-2433
(`$script:AidScanPruneDirs`/`AidScanSystemDirs`/`AidScanMaxDepth` ~:2115/2123/2130,
`Test-AidScanNameInSet` ~:2136, walk ~:2225, orchestrator `Invoke-AidProjectsScan` ~:2333).
State-home derivation `bin/aid` ~:65-71 / `bin/aid.ps1` ~:100-103; registry line-scan
`_registry_read_repos` ~:1466 / `Get-RegistryRepos` ~:1574 and union ~:1485/1596 are the
parsing + resolution precedents reused for `scan-config.yml`. Additive-merge semantics
mirror `discovery.term_exclusions`. See SPEC.md Data Model / Feature Flow / Layers &
Components / Configuration / Migration Plan.
