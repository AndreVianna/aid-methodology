# Delivery SPEC -- delivery-002: Atomic aid update + Complete-Replacement Migration

> **Delivery:** delivery-002
> **Work:** work-005-profile-generator-simplify
> **Created:** 2026-06-20

---

## Objective

Deliver the install/CLI behavior that makes the new layout **safe to ship**: a single `aid update` that keeps all installed tools at one version (FR10, no per-tool selection; outside-repo = CLI only, inside = CLI then all tools), the same-version invariant across `aid add` / install (FR11), and a complete-replacement migration that retires the old layouts (`.agents/` → `.codex/`, drop `.cursor/rules/` + `.agent/rules/`) by marker-prune + retired-root sweep against the new version's manifest (FR7/FR7a), user content untouched, with bash + PowerShell parity. Atomicity is stage-all-first + idempotent re-run on failure.

## Scope

- **feature-003-atomic-aid-update** — `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1` (+ vendored copies), `bin/aid` + `bin/aid.ps1`; the single-`aid update` contract; FR11 add/install version selection; `_migrate_retired_layout` + the marker-prune re-point; the migration tests (`test-aid-migrate.sh`, `Test-AidInstaller.ps1`) on old-layout fixtures.

**Out of scope:** the generator + committed `profiles/*` trees + the per-version manifest emission (delivery-001 produces them); `release.sh` codex roots, docs/site/KB lockstep, the final acceptance gate (delivery-003). No release is cut from this delivery.

## Gate Criteria

- [ ] **AC8** — single `aid update`, all installed tools at one version; outside-repo updates the CLI only, inside-repo updates CLI then all tools; the five args behave as specified; no repo ends in a mixed-version state (incl. via `aid add` / install).
- [ ] **AC5** — old-layout installs (`.agents/`, `.cursor/rules/`, `.agent/rules/`) migrate by complete replacement on `aid update`: AID-owned orphans (by the 3 markers) absent from the new version's manifest are pruned; no stranded/duplicate trees; user content untouched; verified on old-layout fixtures.
- [ ] bash + PowerShell parity for every changed/added function; ASCII-only shipped scripts.
- [ ] Migration verified on an existing-(old-)layout fixture, not just a fresh install.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ -- aid-detail will fill this.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001 (the new layout + the per-version manifest/bundle path-set this delivery prunes against)
- **Blocks:** delivery-003

## Notes

- The 002→003 seam is the **manifest contract**: this delivery prunes against the staged bundle's path-set (the per-version manifest delivery-001 emits). Verify delivery-001's "new manifest omits retired paths" before building the prune.
- **Release-Safety Gate (PLAN.md):** may merge to master, but NO release until delivery-001+002+003 all merge.
