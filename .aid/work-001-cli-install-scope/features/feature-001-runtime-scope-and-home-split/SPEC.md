# Runtime Scope Detection and CODE/STATE Home Split

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR1, FR2, FR8, FR10), §4, §9 (AC1, AC4, AC6 partial, AC7, AC8, AC10), §10 (Priority 1) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): orphan-helper removal, ps1 range, prose | /aid-specify |
| 2026-06-15 | Seam consistency: global AID_STATE_HOME honors AID_SHARED_STATE_HOME (runtime+install unified) | /aid-specify |
| 2026-06-15 | Doc-hygiene: retire stale feature-007/008 refs (provisioning = feature-002; Windows-global deferral has no allocated feature) | /aid-plan |

## Source

- REQUIREMENTS.md §5 (FR1 Runtime scope detection, FR2 CODE/STATE decoupling, FR8 Retire marker + scan, FR10 Per-user update-check cache)
- REQUIREMENTS.md §4 Scope (in-scope: runtime scope detection, CODE/STATE decoupling, marker/scan retirement, `.update-check` relocation)
- REQUIREMENTS.md §9 (AC1, AC4, AC6 partial [per-user state-home resolution], AC7, AC8, AC10)
- REQUIREMENTS.md §10 Priority 1 (root-cause bug fix)
- Design note §3.2 (install scope + home split), §3.4 (no machine marker), §6 (touch points)

## Description

This is the root-cause fix for the v1.0→v1.1 dogfood failure. Today the CLI
conflates the read-only code payload and the machine's mutable state under a
single self-located `AID_HOME`; on a root-owned global install that home is not
writable by an unprivileged `aid`, so migration state cannot persist and the CLI
re-prompts migration on every run.

This feature reworks how `aid` figures out where it is installed and where it is
allowed to write. It derives the install **scope** (global vs per-user) at runtime
from whether the code payload directory is writable — no install-time marker is
recorded. It then resolves two separate homes: a read-only **code home** (where
`lib/`, `dashboard/` source and `VERSION` live) and a mutable **state home**
(`~/.aid` for per-user installs, `/var/lib/aid` for global installs), with the
existing `AID_HOME` environment variable now overriding the state home only. As
part of the same rework, it removes the legacy machine-level `.migrated` marker
and the `$HOME`-walking repo scan that caused the wrong-`$HOME` / missed-repos
problem, and it relocates the advisory `.update-check` cache to the per-user
`~/.aid` so refreshing it never requires elevation. All of this is applied with
behavioral parity across `bin/aid` (bash) and `bin/aid.ps1` (PowerShell).

## User Stories

- As an **end user running `aid` on a root-owned npm-global install**, I want
  read-only commands like `aid status` to work without a permission-denied error
  and without re-prompting migration every time, so that an unprivileged install
  is usable.
- As an **AID maintainer**, I want code location and state location resolved
  independently (with `AID_HOME` redirecting state only) so that the HOME-pinned
  canonical test suite stays green and the install model is coherent.
- As an **end user on any install**, I want the update-check to never trigger a
  `sudo` prompt, so that a routine version check is friction-free.
- As an **upgrader from v1.0/v1.1**, I want the obsolete machine marker and
  whole-`$HOME` scan gone, so the migration re-prompt loop cannot recur.

## Priority

Must (Priority 1 — root-cause bug fix)

## Acceptance Criteria

- [ ] Given a root-owned npm-global install, when an unprivileged user runs
  `aid status` in a repo, then it operates with no permission-denied error and
  does not re-prompt migration on every run (AC1).
- [ ] Given the CLI is invoked, when it resolves its homes, then `AID_CODE_HOME`
  (self-located, read-only) and `AID_STATE_HOME` resolve independently, and
  setting `AID_HOME` redirects only the state home (never code) (AC4).
- [ ] Given the CLI resolves scope, when the payload root is not writable by the
  current user, then scope is **global** (state home `/var/lib/aid`); otherwise
  **per-user** (state home `~/.aid`); no install-time scope marker is written (FR1, AC6 partial).
- [ ] Given the canonical test suite runs HOME-pinned, when it pins `AID_HOME` to
  a throwaway directory, then state is redirected there and the suite passes (AC4).
- [ ] Given the codebase, when inspected, then `_aid_check_migrate_sentinel`, the
  `$AID_HOME/.migrated` marker write, and the `$HOME`-walking `_aid_scan_for_repos`
  are removed, and no code path reintroduces a machine-level migration marker (AC7).
- [ ] Given any scope (per-user or root-owned global), when the update-check
  refreshes, then it resolves to `~/.aid/.update-check` and never triggers an
  elevation / `sudo` prompt (AC10).
- [ ] Given both `bin/aid` and `bin/aid.ps1`, when the scope/home logic is
  changed, then they remain behaviorally equivalent and ASCII-only (AC8; NFR
  parity + ASCII-only).

> **Cross-cutting NFRs (apply to all ACs):** bash/ps1 parity (Windows has no
> `sudo`; scope detection still applies), ASCII-only shipped scripts (CI-enforced),
> no data loss / fail-safe, least-privilege (no `sudo` to read).
>
> **Dependency:** consumes `_aid_priv_run` (the writability probe) from PR #78,
> which is gated to merge to master first. This feature is the foundation the
> registry and provisioning features build on.

---

## Technical Specification

> **Scope of this feature.** This feature replaces the single self-located
> `AID_HOME` with a CODE/STATE split, derives install scope at runtime, relocates
> the `.update-check` cache, and **removes** the machine `.migrated` marker and the
> `$HOME`-walking scan. It is the root-cause slice (REQUIREMENTS §10 Priority 1:
> FR1, FR2, FR8, FR10; AC1, AC4, AC6-partial, AC7, AC8, AC10). The per-repo
> `format_version` stamp (FR3), the two-tier registry union/provisioning (FR4/FR7),
> the cwd-dispatch matrix (FR5), and registry-driven `update self` migration (FR6)
> are **out of scope here** and land in feature-002/feature-003. This feature must
> remove the marker/scan **without leaving a dangling caller** — the `update self`
> post-step that invoked the scan is stubbed to a no-op pending feature-003's
> registry-migration replacement.
>
> **Dependency (GIVEN).** `_aid_priv_run` (the writability probe / elevation helper,
> bash) and `Invoke-AidPrivRun` (ps1) ship in PR #78, gated to merge to master
> first (REQUIREMENTS §8). Line numbers cited below are **current-master**
> (pre-#78); after #78 merges, the resolution block grows and the cited offsets
> shift — re-anchor by symbol name, not by line.

### Approach — home resolution and scope derivation

Replace the single `AID_HOME` self-locate (`bin/aid:40-47`,
`bin/aid.ps1:55-68`) with two independent resolutions computed at startup,
before the install-core is sourced.

1. **`AID_CODE_HOME` (read-only, self-located, mandatory).**
   - bash: from `BASH_SOURCE[0]` resolve the real path (existing idiom at
     `bin/aid:43`: `cd "$(dirname "$_AID_SELF")" && pwd -P` then basename), and
     set `AID_CODE_HOME="$(dirname "$(dirname "$_AID_SELF_REAL")")"` (parent of
     `bin/`).
   - ps1: from `$MyInvocation.MyCommand.Path` (current `$script:_AidSelfPath`,
     `bin/aid.ps1:57`) take `Split-Path -Parent (Split-Path -Parent $path)`.
   - **`AID_CODE_HOME` is NEVER overridden by an env var.** The `${HOME}/.aid`
     bash fallback (`bin/aid:46`) and the `$env:LOCALAPPDATA/aid` ps1 fallback
     (`bin/aid.ps1:65-67`) are **removed**. Per carried **Q1**: if `BASH_SOURCE[0]`
     / `$MyInvocation.MyCommand.Path` cannot resolve a real payload root (empty,
     not a file, or the parent has no `lib/aid-install-core.sh`), the CLI **errors
     out** with a clear message and a non-zero exit — it does **not** fall back to
     a state dir. This is a fail-safe: a code home that silently points at a state
     dir would re-introduce the exact code/state conflation this feature exists to
     remove.
2. **Scope derivation (FR1, no marker).** `aid` is **global** iff `AID_CODE_HOME`
   is **not writable by the current user**, else **per-user**. Reuse the PR #78
   writability approach (`_aid_priv_run`'s probe; ps1 `Invoke-AidPrivRun`) — do
   **not** invent a second writability test. No install-time scope marker is read
   or written. On Windows there is no `sudo`; the writability test still applies
   (a non-writable payload dir ⇒ global), matching NFR parity.
3. **`AID_STATE_HOME` (mutable, scope-defaulted, env-overridable).**
   `AID_STATE_HOME="${AID_HOME:-<scope default>}"` where the default is
   `~/.aid` (per-user) or `${AID_SHARED_STATE_HOME:-/var/lib/aid}` (global). The
   legacy `AID_HOME` env var is **retained but now binds STATE only** — exactly
   the throwaway-dir redirect the HOME-pinned canonical suite already does.
   Setting `AID_HOME` never moves code resolution.

   **`AID_SHARED_STATE_HOME` is the single override for the shared/global state
   path.** The global-scope default is `${AID_SHARED_STATE_HOME:-/var/lib/aid}`,
   and this same override is honored **identically** by (1) this runtime
   resolution, (2) feature-002's install-time provisioning hooks (npm
   postinstall + curl `install.sh` + `_provision_shared_state_home`), and (3) the
   canonical test-sandbox seam. Pinning `AID_SHARED_STATE_HOME` once therefore
   redirects **both** the install-time provisioning path and the runtime
   resolution to the same location, so neither ever touches the real
   `/var/lib/aid`. The non-global default stays `~/.aid`, and `AID_HOME` still
   overrides STATE regardless of scope (it takes precedence over the
   `AID_SHARED_STATE_HOME` default for the global case). Consistent with design
   note §3.2 (`${AID_SHARED_STATE_HOME:-/var/lib/aid}` as the single source).

Resolution order on startup: resolve `AID_CODE_HOME` → (error-out per Q1 if
unresolved) → source `${AID_CODE_HOME}/lib/aid-install-core.sh` → derive scope
from `AID_CODE_HOME` writability → resolve `AID_STATE_HOME` from
`${AID_HOME:-<scope default>}` (global scope default
`${AID_SHARED_STATE_HOME:-/var/lib/aid}`; per-user `~/.aid`).

### On-disk state layout

| Path | Home | Mutability | Holds | Cited use |
|------|------|-----------|-------|-----------|
| `${AID_CODE_HOME}/lib/aid-install-core.sh` (`.../AidInstallCore.psm1`) | CODE | read-only | dispatch engine | `bin/aid:52`; `bin/aid.ps1:73` |
| `${AID_CODE_HOME}/VERSION` | CODE | read-only | installed CLI version | `bin/aid:168,350,1900,1940`; `bin/aid.ps1:187,380` |
| `${AID_CODE_HOME}/dashboard/` (server + `home.html` source) | CODE | read-only | vendored dashboard payload (copied **into** a repo's `.aid/dashboard/`) | `bin/aid:991,1331`; `bin/aid.ps1:862` |
| `${AID_STATE_HOME}/registry.yml` | STATE | mutable (global tier: privileged-written) | machine repo index | `bin/aid:1203,1242`; `bin/aid.ps1:1232,1267` (the `:1748` / `:1736` uses are inside the removed compliance helper) |
| `~/.aid/.update-check` | **always per-user** (NOT `AID_STATE_HOME`) | mutable, advisory | throttled update-check cache | `bin/aid:174,357`; `bin/aid.ps1:192,388` |

`.update-check` is pinned to `~/.aid` regardless of scope (FR10) so a routine
version check on a root-owned global install never writes into `/var/lib/aid`
and never triggers elevation. For a per-user install `AID_STATE_HOME == ~/.aid`,
so registry and the cache coexist in one dir (no behavioral change there).

> **Within this feature** the registry path is merely **repointed** from the old
> `AID_HOME` to `AID_STATE_HOME` (a string swap on the cited lines); the
> `/var/lib/aid` provisioning is feature-002 (FR7) and the two-tier union is
> feature-004 (FR4).
> Repointing alone is correct for both scopes today: per-user resolves to
> `~/.aid/registry.yml` (unchanged), global resolves to `/var/lib/aid/registry.yml`
> (writes will fail best-effort with a WARN until feature-002 provisions it — see
> Edge cases).

### Affected components

**`bin/aid` (bash):**

| Lines (current master) | Symbol / block | Change |
|------|------|--------|
| `40-47` | `AID_HOME` self-locate + `${HOME}/.aid` fallback | **Rewrite** → resolve `AID_CODE_HOME` (self-locate, no env override, error-out per Q1); derive scope from `AID_CODE_HOME` writability; resolve `AID_STATE_HOME="${AID_HOME:-<scope default>}"` (global default `${AID_SHARED_STATE_HOME:-/var/lib/aid}`, per-user `~/.aid`) |
| `52` | `_AID_CORE="${AID_HOME}/lib/..."` | Repoint → `AID_CODE_HOME` |
| `168,350,1900,1940` | `VERSION` reads | Repoint → `AID_CODE_HOME` |
| `544,587` | `aid_home="${AID_HOME:-${HOME}/.aid}"` (self-install staging at `:558` writes `VERSION`) | Repoint VERSION-write target → `AID_CODE_HOME`; drop the `${HOME}/.aid` inline fallback |
| `991,1331` | `dashboard/` source dir | Repoint → `AID_CODE_HOME` |
| `174,357` | `.update-check` cache file | Repoint → **`~/.aid`** (per-user cache, FR10), not `AID_STATE_HOME` |
| `1203,1242` | `registry.yml` (`registry_register` / `registry_unregister`) | Repoint → `AID_STATE_HOME` (the third use at `:1748` lived inside `_aid_check_repo_compliant`, which is removed below — no repoint needed) |
| `245-300` | `_aid_check_migrate_sentinel` + `_AID_MIGRATE_SENTINEL_FIRED` | **Remove** (FR8/AC7) |
| `1753-1768` | `_aid_write_migrated_marker` (+ `${AID_HOME}/.migrated`) | **Remove** (FR8/AC7) |
| `1673-1728` | `_aid_scan_for_repos` (`$HOME` walk) | **Remove** (FR8/AC7) |
| `1731-1751` | `_aid_check_repo_compliant` (incl. comment header) | **Remove** (FR8/AC7) — orphaned by the scan removal: its only callers are `_aid_scan_and_migrate:1816,1831`, which is itself removed below |
| `1770-1880` | `_aid_scan_and_migrate` | **Remove** (FR8/AC7) |
| `1916-1918` | `_aid_check_update` + `_aid_check_migrate_sentinel` (bare-`aid` dashboard) | Drop the sentinel call; keep `_aid_check_update` |
| `1976-1978` | same pair (status path) | Drop the sentinel call; keep `_aid_check_update` |
| `2003-2004` | `update self` post-step → `_aid_scan_and_migrate "$_US_MIGRATE_YES" "$_US_ROOT"` | **Replace with a no-op** (remove the call + its `--yes`/`--root` plumbing if otherwise unused), leaving no dangling caller. Registry-driven migration is feature-003. `update self` self-update mechanics (PR #78) are untouched. |

**`bin/aid.ps1` (PowerShell) — parity:**

| Lines (current master) | Symbol / block | Change |
|------|------|--------|
| `55-68` | `$script:_AidHome` self-locate + `$env:LOCALAPPDATA/aid` fallback | **Rewrite** → `$script:_AidCodeHome` (self-locate, no env override, error-out per Q1); scope from writability (`Invoke-AidPrivRun`); `$script:_AidStateHome = if ($env:AID_HOME) {$env:AID_HOME} else {<scope default>}` (global default honors `$env:AID_SHARED_STATE_HOME` else `/var/lib/aid`; per-user `$HOME/.aid`) |
| `73` | `$script:_CoreModule = ...lib\AidInstallCore.psm1` | Repoint → `_AidCodeHome` |
| `187,380` | `VERSION` reads | Repoint → `_AidCodeHome` |
| `862` | `$assetsDir = ...\dashboard` | Repoint → `_AidCodeHome` |
| `192,388` | `.update-check` cache | Repoint → per-user `~/.aid` (Windows: `$HOME/.aid`, see parity note) |
| `1232,1267` | `registry.yml` (register / unregister) | Repoint → `_AidStateHome` (the `:1736` use lived inside `Invoke-AidCheckRepoCompliant`, removed below — no repoint needed) |
| `283-335` | `Invoke-AidMigrateSentinel` + `$script:_AidMigrateSentinelFired` | **Remove** |
| `1744-1761` | `Write-AidMigratedMarker` (+ `.migrated`) | **Remove** |
| `1609-1704` (comment header through closing `}`) | `Invoke-AidScanForRepos` | **Remove** |
| `1706-1741` (comment header through closing `}`) | `Invoke-AidCheckRepoCompliant` | **Remove** — orphaned by the scan removal: its only callers are `Invoke-AidScanAndMigrate:1798,1813`, which is itself removed below |
| `1762-` (comment header to its end) | `Invoke-AidScanAndMigrate` | **Remove** |
| `1134`, `1204` | `Invoke-AidMigrateSentinel` call sites (bare `aid` / status, mirroring bash `1918/1978`) | Drop the call; keep `Invoke-AidUpdateCheck` |
| `1897` | `Invoke-AidScanAndMigrate -ApplyAllFlag ... -ScanRoot ...` post-update | **Replace with a no-op**, no dangling caller |

(On `bin/aid.ps1`, the old `$env:LOCALAPPDATA/aid` was a **code-home** fallback
and is removed (Q1); it is **not** repurposed as the Windows STATE default. See
the parity note below for the STATE-side Windows default.)

### Behavior / Flow

- **Bare `aid` / `aid status` / read-only commands.** Resolve homes → operate
  against the cwd repo. `_aid_check_update` still runs (reads/writes `~/.aid/.update-check`,
  never elevates). The removed sentinel no longer fires, so **no migration
  re-prompt** on any run (AC1).
- **Per-user install** (`AID_CODE_HOME` writable): scope=per-user; STATE=`~/.aid`;
  registry and cache both under `~/.aid`. Identical to today.
- **Root-owned global install** (`AID_CODE_HOME` = e.g. `/usr/lib/node_modules/aid-installer`,
  not writable): scope=global; STATE=`${AID_SHARED_STATE_HOME:-/var/lib/aid}`; cache stays `~/.aid/.update-check`.
  A read-only `aid status` writes nothing into the root-owned tree and never prompts
  for `sudo` (AC1, AC10).
- **`AID_HOME` set** (e.g. canonical suite throwaway): STATE redirects there;
  `AID_CODE_HOME` unaffected; code/`lib`/`VERSION` still load from the payload (AC4).

### Edge cases & fail-safes

1. **Self-locate failure (Q1).** `BASH_SOURCE[0]` empty/non-file, or
   `$MyInvocation.MyCommand.Path` empty (e.g. piped/`iex` invocation on ps1), or
   the resolved parent lacks `lib/aid-install-core.sh`/`AidInstallCore.psm1` →
   print `ERROR: aid: cannot locate the AID code payload (AID_CODE_HOME unresolved). Re-run the AID bootstrap to repair.` and exit non-zero. **No state-dir fallback.**
   (Note the existing `_AID_CORE`-missing guard at `bin/aid:53-56` / `bin/aid.ps1:74-77`
   becomes the second line of defence; the Q1 check is the first.)
2. **`AID_HOME` set to a non-writable dir.** It overrides STATE only. Mutable
   state writes (registry) are already best-effort (`registry_register` WARN-and-
   return-0, `bin/aid:1212-1233`); they degrade to skip+warn. No hard failure, no
   code-load impact.
3. **Half-migrated machine (marker removed mid-upgrade).** A box that still has a
   stale `${AID_HOME}/.migrated` (or `/var/lib/aid` not yet existing) upgrades to
   this build: the marker is simply **never read again** (the sentinel is gone),
   so it cannot trigger a re-prompt loop. The stale file is inert; cleanup is not
   required for correctness (a later housekeep may delete it). Backward-compat: no
   strand.
4. **Missing `/var/lib/aid` on a not-yet-provisioned global box (feature-002).**
   `AID_STATE_HOME=/var/lib/aid` may not exist. Read paths (registry read) treat
   absent as empty (`_registry_read_repos` returns nothing when the file is absent,
   `bin/aid:1192`). Write paths are best-effort and WARN. Read-only commands MUST
   still operate. This feature does **not** create `/var/lib/aid` (that is FR7 /
   feature-002); it must degrade gracefully until then.

### bash ↔ ps1 parity

- Both rewrite the resolution block identically: self-located **code** home (no
  env override, Q1 error-out), writability-derived scope, env-overridable **state**
  home.
- **No `sudo` on Windows** — scope still derives from `AID_CODE_HOME` writability;
  the privileged-write branch (shared registry) is feature-002/007, not exercised
  here. The writability probe is `_aid_priv_run` / `Invoke-AidPrivRun` (PR #78).
- **State default on Windows:** per-user → `$HOME/.aid` (matching the bash `~/.aid`
  so the `.update-check` and per-user registry paths are parallel); a global
  Windows state default is deferred with `/var/lib/aid` (no Windows global install
  path is provisioned in this feature) — spec the per-user path for parity and
  leave the global Windows default to a future installer-scope feature (deferred;
  no feature allocated in this work). The old `$env:LOCALAPPDATA/aid`
  was a **code** fallback and is removed (Q1); it is not repurposed as the state
  default.
- **ASCII-only** (CI-enforced, NFR): all new/edited lines in `bin/aid` and
  `bin/aid.ps1` use ASCII only (no smart quotes, no Unicode arrows).

### Testing

Unit / canonical assertions (HOME-pinned; suite must stay green — NFR
test-compat, AC8):

1. **Scope detection, both ways.** With `AID_CODE_HOME` writable → scope per-user,
   `AID_STATE_HOME=~/.aid`. With `AID_CODE_HOME` made read-only (chmod a payload
   fixture) → scope global, `AID_STATE_HOME=${AID_SHARED_STATE_HOME:-/var/lib/aid}`
   (assert the *resolved* value; do not require the dir to exist). Because the
   global default honors `AID_SHARED_STATE_HOME`, a canonical test sandboxes the
   global path **without root** by exporting `AID_SHARED_STATE_HOME=<tmp>/shared`
   and asserting the resolved `AID_STATE_HOME` equals `<tmp>/shared` (never the
   real `/var/lib/aid`). This is the same single seam feature-002's install hooks
   honor, so pinning it once redirects both runtime resolution and install
   provisioning.
2. **`AID_HOME` redirects STATE only.** Set `AID_HOME=<throwaway>`; assert
   `registry.yml` lands under the throwaway, while `lib/`, `VERSION`, and
   `dashboard/` still resolve under the payload (`AID_CODE_HOME`). This is the
   existing HOME-pin contract — confirm it passes post-split (AC4).
3. **`.update-check` always `~/.aid`.** With `AID_HOME` pointed elsewhere and
   scope forced global, assert the cache file path resolves to `~/.aid/.update-check`
   and that `aid status` triggers no elevation/`sudo` (AC10).
4. **Marker / scan absent (AC7).** Grep the shipped `bin/aid` + `bin/aid.ps1` for
   `_aid_check_migrate_sentinel`, `_aid_write_migrated_marker`, `_aid_scan_for_repos`,
   `_aid_check_repo_compliant`, `_aid_scan_and_migrate` (+ ps1 `Invoke-AidMigrateSentinel`,
   `Write-AidMigratedMarker`, `Invoke-AidScanForRepos`, `Invoke-AidCheckRepoCompliant`,
   `Invoke-AidScanAndMigrate`) and `.migrated` → assert **zero** matches. Assert no
   dangling caller (the `update self` post-step compiles and runs as a no-op).
5. **Q1 error-out.** Invoke `bin/aid` with `BASH_SOURCE`/self-path forced empty (or
   payload root lacking the core lib) → assert non-zero exit and the clear error,
   and that **no** `.aid` state dir is created as a side effect.
6. **Audit the suite for stale `$AID_HOME/lib`, `$AID_HOME/VERSION`, `$AID_HOME/.migrated`
   references** in `tests/canonical/*` (design note §6 "Test-suite migration risk")
   and repoint expectations to `AID_CODE_HOME` / removed-marker as part of this work.
   Migration/scan-touching tests must keep their `HOME`-pin + escape canary (real-repo
   safety — MEMORY: aid-scan-tests-must-pin-home).

Run `tests/run-all.sh` HOME-pinned locally before claiming green (heavy gates run
only on master; Windows/ps1 parity needs a Windows runner via CI).

### Backward compatibility

- **v1.0/v1.1 upgraders** where `$AID_HOME` was the payload dir: after the split,
  code still loads from the payload (now `AID_CODE_HOME`, self-located identically),
  and state moves to `~/.aid` (per-user) / `/var/lib/aid` (global). A user who had
  manually set `AID_HOME` to a custom dir now redirects STATE there only — code
  loads from the payload regardless, which is strictly more correct (it fixes the
  root-owned-state bug). No data migration is required by this feature: the
  registry path for a per-user install is unchanged (`~/.aid/registry.yml`); the
  inert stale `.migrated` is ignored (Edge case 3).
- **No hard failure on a missing stamp or missing shared home** (NFR backward-compat):
  the `format_version` stamp gate is feature-003, not introduced here; this feature
  only ensures the marker/scan removal cannot strand an in-flight upgrade.
