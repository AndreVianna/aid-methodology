# task-008: d001 test migration — /var/lib/aid provisioning assertions (AID_SHARED_STATE_HOME seam)

**Type:** TEST

**Source:** feature-002-global-state-provisioning → delivery-001

**Depends on:** task-003, task-007

**Scope:**
- Add the feature-002 provisioning assertions to the registry suites in `tests/canonical/` (feature-002 Testing 1-9). All sandboxed via the `AID_SHARED_STATE_HOME` seam (`export AID_SHARED_STATE_HOME=<tmp>/shared`, also passed as the `_provision_shared_state_home` argument) so no site ever touches the real `/var/lib`. HOME- and AID_HOME-pinned, escape canary retained.
  - Provision helper creates the dir (`0755`) + empty `0644` `registry.yml` (`schema: 1`, zero `repos:` items), with `_aid_priv_run` stubbed to run directly in the sandbox.
  - Seed is no-clobber (pre-existing repo entry survives re-run).
  - Per-user collapse: per-user scope never calls `_provision_shared_state_home`, creates no `/var/lib/aid`-equivalent, writes to `~/.aid/registry.yml`.
  - npm install-time hook: `getuid`→0 + `AID_SHARED_STATE_HOME=<tmp>/shared` provisions the sandbox seed; non-zero uid provisions nothing; pre-existing seed is no-clobber.
  - curl `install.sh` guard: `AID_HOME` unset in env + `id -u`→0 → `_AID_HOME_PRESET` empty, guard passes, `<tmp>/shared` provisioned; env-pin `AID_HOME=<throwaway>` → `_AID_HOME_PRESET` non-empty, guard short-circuits.
  - Runtime fallback never prompts: global scope with `$SHARED` non-writable + `sudo` present → empty-probe `_aid_priv_run ""` path (no `sudo` invocation via a sudo stub that fails the test if called), degrades to `~/.aid/registry.yml` + one `WARN:`.
  - Best-effort degrade leaves no temp leak; missing shared dir degrades to user tier.
  - ASCII-only guard over `install.sh` + `lib/aid-install-core.sh` (reuse existing CI check).

**Acceptance Criteria:**
- [ ] Provision-helper, no-clobber-seed, and per-user-collapse assertions pass against the `AID_SHARED_STATE_HOME` sandbox seam; the real `/var/lib` is never touched.
- [ ] npm install-time hook and curl `_AID_HOME_PRESET` guard assertions cover root-provisions / non-root-skips / env-pin-skips / no-clobber.
- [ ] Runtime fallback asserts the empty-probe path (no `sudo` invocation), the `~/.aid` degrade + single `WARN:`, no temp leak, and host-command completion.
- [ ] HOME-/AID_HOME-pin + escape canary retained on every provisioning/encounter test.
- [ ] `tests/run-all.sh` stays green HOME-pinned at the d001 boundary with these assertions added.
- [ ] All §6 quality gates pass.
