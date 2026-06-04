# task-003: Installer verification suite

**Type:** TEST

**Source:** work-002-auto-installer → delivery-001

**Depends on:** task-002

**Scope:**
- Add test coverage for the task-002 installer following the repo's existing bash
  test-suite convention: `tests/canonical/test-*.sh`, sourcing `tests/lib/assert.sh`,
  discovered by `tests/run-all.sh`. PowerShell-path tests SKIP-exit-0 when `pwsh` is
  absent, per the established `test-setup-ps1.sh` contract
  (`infrastructure.md`, `test-landscape.md`).
- Cases must cover:
  - Fresh install installs the correct tree without a full clone.
  - Re-run updates and records the pinned version.
  - Uninstall removes exactly the installed files, leaving the repo pre-install-clean.
  - Auto-detect picks the right host tool; the override flag overrides it.
  - Online vs offline install modes.
  - Bash / PowerShell parity for platform-independent logic.
- Must pass under CI (`canonical-tests` / `generator-selftests` jobs).

**Acceptance Criteria:**
- [ ] Tests cover fresh install, update + version recording, and clean uninstall. (verifies SPEC AC-1, AC-3, AC-7)
- [ ] Tests cover host-tool auto-detect and override-flag behavior. (verifies SPEC AC-4)
- [ ] Tests cover both online and offline modes. (verifies SPEC AC-8)
- [ ] Tests follow the existing `tests/canonical/` convention and are discovered by `tests/run-all.sh`; PowerShell tests skip cleanly when `pwsh` is absent. (verifies SPEC AC-5)
- [ ] The suite passes in CI (`canonical-tests` / `generator-selftests`), contributing to the SPEC quality-gate criterion.
- [ ] All applicable quality gates pass — universal grading rubric, enforced per task by `/aid-execute`.
