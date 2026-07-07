# Work State -- work-014-term-exclusions-migration

> **State:** Executing
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-06
> **User Approved:** yes

Adopter data-migration follow-up to work-013. work-013 moved discovery term exclusions
out of the KB dotfile `.aid/knowledge/.term-exclusions.md` into `.aid/settings.yml`
`discovery.term_exclusions`, but only for our repo. Existing adopters who update would
silently lose their confirmed exclusions (the new code reads `settings.yml`, which is empty
for them, and their old file becomes an ignored orphan). This adds a one-time migration to
the `aid update` path that carries their terms across, then retires the old file.

Ships together with work-013 in v2.0.6.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt)
- **Updated:** 2026-07-06

---

## Triage

- **Path:** lite
- **Work Type:** new-feature
- **Sub-path:** LITE-FEATURE
- **Decision rationale:** One-time installer data migration + bash/PS twin + tests; well-scoped, no pipeline needed.
- **Override:** no

---

## Design

- **Trigger:** auto-run on `aid update`, right after `_migrate_retired_layout` (line ~2187), so adopters get it with no manual step. bash function `_migrate_term_exclusions` in `lib/aid-install-core.sh` + PowerShell twin `Invoke-MigrateTermExclusions` in `lib/AidInstallCore.psm1`.
- **File-existence gate (owner requirement):** returns immediately when `.aid/knowledge/.term-exclusions.md` is absent -- an update with nothing to migrate does zero work.
- **Action when present:** parse `- <term>` lines; if `settings.yml` has no `term_exclusions:` key yet, inject `discovery.term_exclusions` (as the first child under `discovery:`, or append a `discovery:` block if absent); then retire the old file to `.aid/.trash/` (reversible, never committed).
- **Idempotent:** the retire step means a second run finds no file -> no-op; the `term_exclusions:`-already-present guard prevents double-injection on a hand-edited settings.
- **Tests:** bash cases in `tests/canonical/test-aid-migrate.sh`; PS cases in the Windows installer suite.

---

## Verification

- **Migration (bash):** `test-migrate-term-exclusions.sh` — 15/0 (inject-under-discovery, absent-file gate, idempotent re-run, append-when-no-discovery-section, no-double-inject).
- **Migration (PowerShell twin):** `test-migrate-term-exclusions-ps1.sh` → `.ps1` — 6/0 (inject + gate). Skips gracefully when pwsh is absent.
- **No install-flow regression:** bash `test-install-provisioning.sh` 41/0; Windows `Test-InstallProvisioning.ps1` all pass — the added `_migrate_term_exclusions` / `Invoke-MigrateTermExclusions` call is a no-op on a fresh install (no term file) and doesn't disturb settings/gitignore provisioning.
- **No profile regen needed:** the change is in the installer libs (`lib/*.sh`, `lib/*.psm1`), which are not part of the canonical→profile render; the dogfood `.claude/` tree is untouched.

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-06 | Work created | -- | Adopter migration for the work-013 term-exclusions relocation; branch `work-014-term-exclusions-migration` |
| 2026-07-06 | Implemented + verified | -- | bash `_migrate_term_exclusions` + PS `Invoke-MigrateTermExclusions`, auto-run on `aid update`, file-existence-gated; tests green (bash 15/0, PS 6/0, provisioning unbroken) |
