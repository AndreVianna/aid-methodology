# Plan — `aid projects` command

> **Work:** work-002-projects-command
> **Source of truth:** `REQUIREMENTS.md` (A+) + `features/feature-001-projects-command/SPEC.md` (A+).
> **Dogfood:** AID applied to its own repo.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-16 | Initial plan: 2 deliverables, reader-before-writer coupling | /aid-plan |
| 2026-06-16 | Revised after SPEC A+ review: readers key-agnostic (coupling dropped); writer flip coordinated across platforms for parity; task graph reworked (key-flip + broken-assertion-update tasks) | /aid-plan |
| 2026-06-16 | A+ PLAN-gate fixes: task-001 expanded to full de-"repo" terminology sweep (~16 user-facing strings) + 3-line comment; task-002 full PAR057 inventory (incl. O16 byte-compare); corrected vacuous Windows-assert claim; cwd-classify partitioned to task-005 | /aid-plan |

## Overview

One feature, sequenced into **two deliverables**, each a standalone-functional MVP, with every dependency satisfied by a prior delivery:

- **delivery-001** — the bash `aid projects` command, fully working on Linux/macOS, *plus the both-key read tolerance in all three readers (bash, PowerShell, Python)*.
- **delivery-002** — PowerShell command parity, the Windows test suite, cross-platform parity tests, and docs.

### The writer-flip coordination — how it is resolved

The registry key migrates `repos:` → `projects:`. Two facts shape the sequencing (both verified against `master`):

1. **Readers are key-agnostic — there is NO reader-before-writer coupling.** Bash `_registry_read_repos` (`bin/aid:1297`), PowerShell `Get-RegistryRepos` (`bin/aid.ps1:1236`), and Python `load_registry` (`server.py:61` `_ITEM`) all parse list **items** by regex and ignore the section key, so they read `projects:` and legacy `repos:` identically with no change. The writer flip cannot break any reader on any platform.
2. **The flip must still be coordinated across bash + PowerShell to preserve parity.** `tests/canonical/test-aid-cli-parity.sh` compares bash vs PowerShell `registry.yml` output **byte-for-byte** (PAR057-O16, `:1010`); if bash writers emitted `projects:` while PowerShell still emitted `repos:`, that assertion would fail in the gap. So **all writers + the user-facing string sweep (bash + core + PowerShell) land together in one foundational task in delivery-001**, with the broken parity/registry/provisioning assertions updated in the same delivery. (The Windows-native suite `Test-AidInstaller.ps1` has **no** registry key/header assertion, so the flip breaks nothing there — the binding cross-platform assertion is the parity byte-compare, not a Windows-suite assert.)

Result: delivery-001 unifies the key everywhere (parity intact, no reader break) and ships the bash command; delivery-002 adds the PowerShell `projects` command. The PowerShell *command* (not the writer key) is what defers to delivery-002.

## Deliverables

### delivery-001: coordinated key flip + bash `aid projects` MVP

- **What it delivers:** (1) The registry key unified to `projects:` across **all** writers (bash + core + PowerShell) in one foundational change, with the seed header comment de-"repo"-ed and every existing key/header assertion updated (registry, provisioning, parity, Windows suites) — parity stays green, no reader breaks (readers are key-agnostic). (2) A fully working `aid projects [list|add|remove|help]` on bash hosts: `list` reads the **raw** union (no prune) and renders each project's live state (`vX.Y.Z`/`untracked`/`no-aid`/`missing`), tools (from each manifest), tier, and an ASCII `*` "you are here" marker; `add`/`remove` manage tracking only (never tools), with deterministic by-location tier selection (per-user collapse / global / `--local`/`--shared` / degrade); the interactive cwd-classify prompt is replaced by the rule (dashboard stays never-elevate). No "repo/repos" in the bash user-facing surface.
- **Covers:** FR1, FR2 (key flip all writers + seed comment), FR3, FR4, FR5, FR6, FR7 (bash), FR9 (bash); AC1–AC7 (bash), AC10 (bash), AC11 (code-adjacent header/usage). AC8/AC9 partial (bash + parity-assertion updates + Windows-assertion updates).
- **Depends on:** PR #83 baseline (merged).
- **Standalone-functional:** `aid projects` is complete and usable on Linux/macOS; the registry is `projects:`-keyed everywhere; parity and all suites green.

### delivery-002: PowerShell command parity + Windows/parity tests + docs

- **What it delivers:** `Invoke-AidProjects` (list/add/remove/help) + `Get-RegistryRawUnion` + `Resolve-AidTier` in PowerShell, mirroring bash behavior/output/exit codes (ASCII `*` marker); `Invoke-AidCwdClassify` reconciled to the rule; PS usage/help updated. New Windows-native and cross-platform parity tests cover the `projects` command; release notes + KB count-drift reconciled. (PS *writers* already flipped in delivery-001.)
- **Covers:** FR8, FR7/FR9 (PS); AC8 (command parity + ASCII), AC9 (projects parity + Windows projects tests), AC10 (PS help), AC11 (release-tracking + housekeep reconcile).
- **Depends on:** delivery-001 (the rule, output shape, raw-read semantics, unified key).
- **Standalone-functional:** Full cross-platform parity; Windows users get `aid projects`.

## Execution Graph

### delivery-001

| Task | Type | Depends on | Parallel group |
|------|------|-----------|----------------|
| task-001 — Coordinated de-"repo" + key flip (bash + PS together): ALL writers (`bin/aid` ×6, `lib/aid-install-core.sh` ×1, `bin/aid.ps1` ×2, `lib/AidInstallCore.psm1` ×1) emit `projects:`; rewrite the full 3-line seed header comment; **sweep the ~16 user-facing "repo"→"project" message strings** (bash + PS) per the SPEC Terminology rule (retain "git repository", `__migrate-repo`, var names, JSON field). Readers unchanged (key-agnostic). | IMPLEMENT | — | A |
| task-002 — Update existing assertions broken by task-001: `test-registry.sh` (REG-U01d/U01f/U07c), `test-aid-provisioning.sh` (PRV-P02b/P02c), `test-aid-cli-parity.sh` (full set: PAR057-O07/O09/O12/O14/**O16 byte-compare**/S02/S03), plus any other assertion pinning a swept "repo" string (grep-complete: `grep -rn 'machine repo registry\|repos:' tests/` → 0). `Test-AidInstaller.ps1` has no key/header assertion (nothing to update there). HOME-pinned | TEST | task-001 | B |
| task-003 — bash helpers: `_registry_read_raw_union` (non-pruning), `_aid_resolve_tier`, `_aid_project_state` | IMPLEMENT | — | A (∥ task-001) |
| task-004 — bash `_cmd_projects` (list/add/remove/help) + dispatch block + `_aid_usage` + header comment; ASCII `*` marker | IMPLEMENT | task-003 | C |
| task-005 — bash reconcile auto-registration: cwd-classify prompt→`_aid_resolve_tier`, dashboard never-elevate, migrate side-effect | IMPLEMENT | task-003 | C (∥ task-004) |
| task-006 — ADD new units to `tests/canonical/test-registry.sh` (raw list + 4 states + add-rejects-non-aid + add/remove idempotent + remove-repairs-stale + tier per-user/global/override/degrade + legacy-`repos:` read + ASCII `*` marker); HOME-pinned + escape canary | TEST | task-004, task-005 | D |

**Can be done in parallel:** {task-001, task-003}; then {task-004, task-005}; task-002 after task-001.

### delivery-002

| Task | Type | Depends on | Parallel group |
|------|------|-----------|----------------|
| task-007 — PowerShell: `Get-RegistryRawUnion`, `Resolve-AidTier`, `Invoke-AidProjects` (list/add/remove/help) + dispatch + `Show-AidUsage`; reconcile `Invoke-AidCwdClassify`; ASCII `*` marker | IMPLEMENT | delivery-001 | E |
| task-008 — `tests/windows/Test-AidInstaller.ps1` new `T<NN>` IDs for `aid projects` (list/add/remove/help) | TEST | task-007 | F |
| task-009 — `tests/canonical/test-aid-cli-parity.sh` bash↔PS parity for `projects list/add/remove` | TEST | task-007 | F (∥ task-008) |
| task-010 — `.aid/knowledge/release-tracking.md` `[NEW] aid projects` (Unreleased, forward-looking; the feature is cross-platform-complete only after task-007); note KB "N commands" count-drift reconciliation deferred to `/aid-housekeep` | DOCUMENT | — | G (∥ E/F) |

**Can be done in parallel:** task-010 anytime; {task-008, task-009} after task-007.

## Branch Strategy

One branch per delivery (per aid-execute convention): `aid/work-002-projects-command-delivery-001`, `…-delivery-002`. The work-planning artifacts (this PLAN, REQUIREMENTS, SPEC, tasks, STATE) land via the work branch `aid/work-002-projects-command` and a PR to master.

## Release

Ships in the unified **1.2.0** release (one version, all tools) — NOT folded into 1.1.0. Cutting the release is out of scope for this work.

## Notes

- **Test isolation:** registry/migration code defaults its root to `$HOME`; every test firing it must `export HOME=<throwaway>` plus an escape canary (per repo convention), else it mutates the developer's real registry/repos.
- **Windows lockstep:** PowerShell behavior is gated ONLY by `tests/windows/Test-AidInstaller.ps1` on windows-latest CI; a green local `run-all.sh` does not cover it.
- **Count-drift:** adding a command leaves stale "N commands" counts across help/KB that CI does not catch; reconcile via `/aid-housekeep` (AC11), not inline (except the code-adjacent `bin/aid` header + usage, done in-task).
