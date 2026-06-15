# task-015: Bootstrap assertions — stamp + register on first encounter, no scan (AC9)

**Type:** TEST

**Source:** feature-005-bootstrap-and-test-migration → delivery-003

**Depends on:** task-013

**Scope:**
- Add the new bootstrap assertions (feature-005 Testing "New bootstrap assertions" + "Carry-forward" + "Tier coverage"). HOME-pinned (throwaway `HOME`) with the escape canary, per the AID-scan-safety memory note.
  - **First-encounter:** on first encounter of a stamp-less repo via `cd <repo>` + repo-command + `aid update` — assert (a) `format_version: 1` is written into `.aid/settings.yml`, (b) the repo is registered in the (user-tier, collapsed) `registry.yml`, (c) **no filesystem scan** occurs (a canary planted outside the throwaway `HOME` is untouched). Directly verifies AC9 / FR9.
  - **Carry-forward:** a second encounter of an already-stamped repo neither re-prompts nor re-writes the stamp.
  - **Tier coverage:** non-global collapse (user==shared==`~/.aid`) asserted by default; at least one simulated global install asserts the shared tier via an `AID_STATE_HOME`/`AID_SHARED_STATE_HOME`-overridden "pretend-global" throwaway (preferred option (a) — exercises the two-tier union read without a root-provisioned `/var/lib/aid`).
- bash + ps1 in lockstep where the parity suites apply. No production code edits.

**Acceptance Criteria:**
- [ ] First-encounter assertion proves `format_version: 1` written + repo registered + no scan (canary outside throwaway `HOME` untouched), satisfying AC9.
- [ ] Carry-forward assertion proves a second encounter neither re-prompts nor re-writes the stamp.
- [ ] Tier-coverage asserts the non-global collapse by default and the shared tier via the pretend-global seam (no real `/var/lib/aid` required in CI).
- [ ] Throwaway `HOME` + escape canary present on every bootstrap/encounter test.
- [ ] All §6 quality gates pass.
