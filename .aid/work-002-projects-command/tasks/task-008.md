# task-008: Windows-native tests for `aid projects`

**Type:** TEST

**Source:** feature-001-projects-command → delivery-002

**Depends on:** task-007

**Scope:** Add new `T<NN>` test IDs to `tests/windows/Test-AidInstaller.ps1` (the Windows-native suite; runs only on windows-latest CI, not in `run-all.sh`) covering `aid projects` on PowerShell:
- `list` renders registered projects with state + ASCII `*` cwd marker;
- `add` registers an existing `.aid/` project / rejects a non-`.aid/` path / idempotent;
- `remove` unregisters / repairs stale / idempotent;
- `help` / `-h`.
- Follow the suite's existing `T<NN>` numbering convention; ASCII-only.

**Acceptance Criteria:**
- [ ] New `T<NN>` IDs exercise list/add/remove/help on Windows-native PowerShell with observable assertions.
- [ ] The new `T<NN>` IDs **pass on windows-latest CI** (PowerShell behavior is gated only there); the suite also parses under pwsh on Linux (parse-check) before push.
- [ ] All §6 quality gates pass.
