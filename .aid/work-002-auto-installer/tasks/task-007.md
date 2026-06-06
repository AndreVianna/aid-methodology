# task-007: Cross-platform install parity verification (end-to-end)

**Type:** TEST

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-001, task-004, task-006

**Scope:**
- Add end-to-end parity coverage that installs the **same release artifact** (via `--from-bundle` fixtures built by task-001) through both `install.sh` and `install.ps1` into separate temp targets and asserts the two produce equivalent results.
- Assert byte-identical installed trees (sha256 per file), byte-identical manifest JSON, identical `.aid/.aid-version`, identical message strings, and identical exit codes across the Bash and PowerShell paths for: fresh install, update, uninstall, protect-on-diff (exit 5), and uninstall safety.
- Gate the PowerShell leg on `pwsh` presence (skip cleanly when absent, consistent with task-006), and ensure the CI `canonical-tests` job (which asserts `pwsh` present) exercises the real parity comparison.

**Acceptance Criteria:**
- [ ] Installing the same fixture tarball through `install.sh` and `install.ps1` yields byte-identical installed trees (per-file sha256), byte-identical manifest JSON, and identical `.aid/.aid-version`.
- [ ] Message strings and exit codes (0–6, including the protect-on-diff default exit 5) match across both bootstraps for fresh-install / update / uninstall / protect-on-diff / uninstall-safety scenarios.
- [ ] The parity suite skips the PowerShell leg cleanly when `pwsh` is absent and runs the full comparison where `pwsh` is present (CI exercises it for real).
- [ ] All §6 quality gates pass.
