# task-003: Installer managed-region Connectors heading-stem allowlist

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Add the `Connectors` heading stem to the managed-region heading allowlist in BOTH installer twins: the `is_aid_heading` awk function in `lib/aid-install-core.sh` and the parity `switch` in `lib/AidInstallCore.psm1`.
- This lets the in-place managed-region updater accept a `## Connectors` section (task-004) without duplicating it on the C2 (no-marker) migration path (documented precedent: work-007 "Workflow was omitted").

**Acceptance Criteria:**
- [ ] The `Connectors` stem is present in `is_aid_heading` (`aid-install-core.sh`) AND the parity PowerShell `switch` (`AidInstallCore.psm1`)
- [ ] Both twins are changed in the same unit; shipped PowerShell is WinPS-5.1-compatible and ASCII-only
- [ ] The C2 (no-marker) migration path does not duplicate the `## Connectors` section
- [ ] Unit/installer tests exercise the new stem; all existing tests still pass; build passes
- [ ] All §6 quality gates pass
