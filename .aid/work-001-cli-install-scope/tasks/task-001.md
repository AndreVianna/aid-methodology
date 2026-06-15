# task-001: CODE/STATE home split, scope derivation, marker/scan/sentinel removal (bash)

**Type:** IMPLEMENT

**Source:** feature-001-runtime-scope-and-home-split → delivery-001

**Depends on:** — (none)

**Scope:**
- `bin/aid` only. Apply feature-001 "Affected components (bash)" table verbatim:
  - `bin/aid:40-47` — **Rewrite** the single `AID_HOME` self-locate + `${HOME}/.aid` fallback into: resolve `AID_CODE_HOME` (self-located via `BASH_SOURCE[0]`, parent of `bin/`, **no env override**, error-out per Q1 if unresolvable or parent lacks `lib/aid-install-core.sh`); derive scope from `AID_CODE_HOME` writability reusing PR #78 `_aid_priv_run`'s probe (no second writability test); resolve `AID_STATE_HOME="${AID_HOME:-<scope default>}"` (global default `${AID_SHARED_STATE_HOME:-/var/lib/aid}`, per-user `~/.aid`).
  - Repoint to `AID_CODE_HOME`: `_AID_CORE` (`:52`), VERSION reads (`:168,350,1900,1940`), self-install VERSION-write target + drop inline fallback (`:544,587`/`:558`), `dashboard/` source (`:991,1331`).
  - Repoint `.update-check` (`:174,357`) to **`~/.aid`** (per-user, FR10) — never `AID_STATE_HOME`, never elevates.
  - Repoint `registry.yml` in `registry_register`/`registry_unregister` (`:1203,1242`) to `AID_STATE_HOME` (string swap only; provisioning + union are out of scope here).
  - **Remove** (FR8/AC7): `_aid_check_migrate_sentinel` + `_AID_MIGRATE_SENTINEL_FIRED` (`:245-300`), `_aid_write_migrated_marker` + `${AID_HOME}/.migrated` (`:1753-1768`), `_aid_scan_for_repos` (`:1673-1728`), `_aid_check_repo_compliant` (`:1731-1751`, orphaned), `_aid_scan_and_migrate` (`:1770-1880`).
  - Drop the sentinel call (keep `_aid_check_update`) at `:1916-1918` and `:1976-1978`.
  - `update self` post-step `_aid_scan_and_migrate` (`:2003-2004`) — **replace with a no-op**, remove the call + its `--yes`/`--root` plumbing if otherwise unused; leave no dangling caller. PR #78 self-update mechanics untouched.
- Re-anchor cited line offsets by symbol name (pre-#78 lines will have shifted after the merge).

**Acceptance Criteria:**
- [ ] `AID_CODE_HOME` self-locates with no env override; an unresolvable payload (empty `BASH_SOURCE`, missing `lib/aid-install-core.sh`) prints the clear Q1 error and exits non-zero with **no** state-dir fallback created.
- [ ] Scope is global iff `AID_CODE_HOME` is not user-writable (via `_aid_priv_run` probe, not a second test); `AID_STATE_HOME` resolves to `${AID_HOME:-<scope default>}` with global default `${AID_SHARED_STATE_HOME:-/var/lib/aid}` and per-user `~/.aid`; setting `AID_HOME` redirects STATE only, never code.
- [ ] `.update-check` resolves to `~/.aid/.update-check` regardless of scope and never triggers `sudo`/elevation.
- [ ] `grep` of `bin/aid` for `_aid_check_migrate_sentinel`, `_aid_write_migrated_marker`, `_aid_scan_for_repos`, `_aid_check_repo_compliant`, `_aid_scan_and_migrate`, and `.migrated` returns **zero** matches; the `update self` post-step is a no-op with no dangling caller and the file parses/runs.
- [ ] All new/edited `bin/aid` lines are ASCII-only.
- [ ] All §6 quality gates pass.
