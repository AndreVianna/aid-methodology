# task-013: d002 test migration — registry union, A/B/C dispatch, update-self registry migration

**Type:** TEST

**Source:** feature-004-two-tier-registry-and-dispatch → delivery-002

**Depends on:** task-011, task-012

**Scope:**
- Migrate the registry/dispatch suites that feature-004 changes so `tests/run-all.sh` stays green HOME-pinned at the d002 boundary (feature-004 Testing 1-8; feature-005 audit category C4). Bash + ps1 in lockstep. Throwaway `$HOME` and `$AID_STATE_HOME` per the AID-scan-safety memory note; escape canary retained.
  - **Union read** (`test-registry.sh`): user tier = repo A, shared tier = repo B → union {A, B}; a path in both tiers appears once.
  - **Per-user collapse:** `$AID_STATE_HOME == ~/.aid` → no shared read, result equals single-file read (re-anchor C4: `$AID_HOME/registry.yml` → `AID_STATE_HOME`; confirm non-global collapse; add a shared-tier case only where a global install is simulated via the `AID_STATE_HOME`/`AID_SHARED_STATE_HOME` seam).
  - **Best-effort write degrade:** unwritable shared tier + declining `_aid_priv_run` → `registry_register --shared` warns, returns 0, host command completes.
  - **NO scan anywhere (AC2):** assert `_aid_scan_for_repos` / `Invoke-AidScanForRepos` not defined/called; grep dispatch paths for any `$HOME`-walk; a canary repo outside the registry is never touched.
  - **`update self` migrates exactly registered repos (AC5):** register A and B, leave C unregistered; `update self --yes` → A and B stamped, C untouched.
  - **Dispatch-matrix rows:** table-driven cases for each A/B/C row — silent in-`~` register, global-outside-`~` shared-vs-user ask, unwritable-folder `aid add` error, missing-`.aid/` offer (exit 0, not error), non-git note, stale ⇒ offer-update.
  - **Prune-on-read:** register a repo, delete its `.aid/`, assert the union drops it quietly.
  - **Parity:** ps1 suite mirrors all cases; ASCII-only lint passes; byte-parity check retained.

**Acceptance Criteria:**
- [ ] Union-read, per-user-collapse, best-effort-write-degrade, no-scan, update-self-exactly-registered, dispatch-matrix-row, and prune-on-read assertions all present and passing.
- [ ] C4 registry-tier refs re-anchored on `AID_STATE_HOME` (with a simulated-global shared-tier case via the seam).
- [ ] No-scan assertion (AC2) confirms the scan symbols are absent and a canary repo outside the registry is untouched.
- [ ] Throwaway `$HOME`/`$AID_STATE_HOME` + escape canary retained; ps1 suite mirrors the bash cases; ASCII-only + byte-parity checks pass.
- [ ] `tests/run-all.sh` is green HOME-pinned at the d002 boundary (bash side; ps1 parity on the Windows CI runner).
- [ ] All §6 quality gates pass.
