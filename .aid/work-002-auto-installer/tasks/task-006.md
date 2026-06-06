# task-006: PowerShell installer test suite (`test-install-ps1.sh`)

**Type:** TEST

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-005

**Scope:**
- Author `tests/canonical/test-install-ps1.sh` per feature-001 §Testing-approach: a thin `pwsh` wrapper that **SKIPs (exit 0) when `pwsh` is absent** (mirroring the `test-setup-ps1.sh` pattern), auto-discovered by `tests/run-all.sh`.
- On Linux CI exercise the platform-independent paths (arg parsing, detection, manifest JSON shape parity, message-string parity, `--from-bundle` extract via `tar`) and assert the **same** message strings + exit codes as the Bash suite, enforcing FR9 parity.
- Remove/rename the legacy `test-setup-ps1.sh`.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-install-ps1.sh` is auto-discovered, SKIPs cleanly (exit 0) when `pwsh` is absent, and runs the parity assertions when `pwsh` is present.
- [ ] The suite asserts byte-identical message strings, exit codes (incl. the protect-on-diff default exit 5), and manifest JSON shape versus the Bash `test-install.sh`.
- [ ] `tests/canonical/test-setup-ps1.sh` is removed/renamed (the legacy PowerShell setup suite no longer runs).
- [ ] All §6 quality gates pass.
