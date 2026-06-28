# task-004: install-manifests lockstep suite (H1)

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-002

**Depends on:** -- (none)

**Scope:**
- Add a new canonical bash test suite `tests/canonical/test-install-manifests-lockstep.sh` that
  asserts the 5 install manifests agree on the dashboard file set (the 12-file set per
  feature-007 H1). It must FAIL when any one manifest diverges (missing/extra dashboard file) and
  PASS on the current agreeing tree.
- Wire it into the canonical suite runner so it executes in CI `test.yml` (PR-gated to master),
  consistent with how the other `tests/canonical/*.sh` suites are registered (e.g. `run-all.sh`).
- Follow the repo's bash test conventions (HOME-pinned where the suite touches `$HOME`/AID scan
  surfaces; ASCII-only; deterministic; clean setup/teardown).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-install-manifests-lockstep.sh` exists and asserts all 5 install manifests carry the same dashboard 12-file set. *(H1)*
- [ ] The suite FAILS (non-zero) when a manifest is mutated to drop or add a dashboard file, and PASSES on the unmodified tree (demonstrated, not asserted). *(H1)*
- [ ] The suite is registered in the canonical runner so it runs under `test.yml` on PRs to master. *(feature-007 CI-surface note)*
- [ ] Tests are deterministic with clean setup/teardown; HOME pinned if the suite reads `$HOME`/AID scan surfaces. *(TEST default + AID scan-tests-pin-HOME constraint)*
- [ ] All REQUIREMENTS.md §6 quality gates pass; local `tests/run-all.sh` (HOME-pinned) stays green.
