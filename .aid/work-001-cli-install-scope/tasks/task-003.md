# task-003: Global /var/lib/aid provisioning — helper, install hooks, runtime fallback (bash)

**Type:** IMPLEMENT

**Source:** feature-002-global-state-provisioning → delivery-001

**Depends on:** task-001

**Scope:**
- Apply feature-002 "Affected components" table (bash/curl/npm sites). Disjoint region from task-005; stage only own hunks (`git add -p`; never `git add` wholesale) and push via explicit `HEAD:branch` refspec (shared-checkout hazard).
  - `lib/aid-install-core.sh` — **New** `_provision_shared_state_home <shared-home>`: create dir + `chmod 0755`, seed empty `registry.yml` (`0644`, atomic temp+`mv -f`, **no-clobber**) using the exact schema (`schema: 1` + empty `repos:`, `bin/aid:1216-1223`), every filesystem mutation routed through `_aid_priv_run`. Best-effort: returns non-zero on declined elevation without aborting the caller.
  - `packages/npm/scripts/postinstall.js` — install-time PRIMARY hook: `var sharedHome = process.env.AID_SHARED_STATE_HOME || '/var/lib/aid';` then a branch guarded by `process.getuid && process.getuid()===0` **and** `!existsSync(path.join(sharedHome,'registry.yml'))` → `mkdirSync(sharedHome,{mode:0o755})` + seed `0644` no-clobber, inside the existing `try/catch` (`:31`/`:61-67`) so failure stays non-fatal.
  - `install.sh:66` — new early capture `_AID_HOME_PRESET="${AID_HOME:-}"` immediately after `set -uo pipefail`, before the first `AID_HOME="${AID_HOME:-${HOME}/.aid}"` default (`:577`).
  - `install.sh` BOOTSTRAP (after `:820`) and CONVENIENCE (before the `exec` at `:1065`) — add `if [[ "$(id -u)" -eq 0 && -z "$_AID_HOME_PRESET" ]]; then _provision_shared_state_home "${AID_SHARED_STATE_HOME:-/var/lib/aid}"; fi`. Best-effort; install does not abort on non-zero.
  - `bin/aid` `registry_register` (`:1202-1235` after the task-001 `AID_STATE_HOME` rename) — non-prompting FALLBACK: never-elevate ensure-exists `_aid_priv_run "" mkdir -p "$AID_STATE_HOME"` + never-elevate seed; shared-tier commit `_aid_priv_run "" mv -f "$tmp" "$reg"`; on failure **degrade** to `~/.aid` + one `WARN:` + `return 0`. Never sudo-prompt on a routine `aid add`.
  - `bin/aid` `registry_unregister` (`:1241-1273`) — atomic-commit via the same never-elevate path; degrade to user tier on failure.
  - pipx packaging — **no change** (per-user by construction; documented as such).
- Consume `AID_STATE_HOME`, `_aid_priv_run`, and the `AID_SHARED_STATE_HOME` seam verbatim (defined by task-001 / PR #78); define no new resolution or elevation logic.

**Acceptance Criteria:**
- [ ] `_provision_shared_state_home <SH>` creates `<SH>` mode `0755`, seeds `<SH>/registry.yml` mode `0644` with `schema: 1` and empty `repos:`, is atomic + no-clobber, routes every mutation through `_aid_priv_run`, and returns non-zero without aborting on declined elevation.
- [ ] npm postinstall provisions only when `getuid()===0` AND the seed is absent (skips for non-root / pre-existing), honors `AID_SHARED_STATE_HOME`, and stays non-fatal inside the existing try/catch.
- [ ] `install.sh` captures `_AID_HOME_PRESET` at `:66`; the BOOTSTRAP + CONVENIENCE guards `[[ id -u -eq 0 && -z $_AID_HOME_PRESET ]]` provision via the `AID_SHARED_STATE_HOME` seam and never abort the install.
- [ ] Runtime fallback uses the empty-probe `_aid_priv_run ""` form (no sudo prompt on `aid add`), and on a failed shared write degrades to `~/.aid/registry.yml` + one `WARN:` + `return 0` with the host command still completing.
- [ ] Per-user install never calls `_provision_shared_state_home` and never produces a `/var/lib/aid` path (shared==user==`~/.aid`).
- [ ] The five install manifests stay lockstep on provisioning behavior + file set; `install.sh` and `lib/aid-install-core.sh` are ASCII-only (postinstall.js stays ASCII for parity).
- [ ] All §6 quality gates pass.
