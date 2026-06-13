# task-057: CLI parity + registry side-effect tests — extend `test-aid-cli-parity.sh` (register/unregister + spawn-seam) + ASCII gate

**Type:** TEST

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-049, task-055

**Scope:**
- Extend the hand-maintained-`bin/aid` test pipeline (R10) for the d008 CLI changes — the registry side-effect (task-049), the spawn-seam relocation (task-047), and the `--remote` re-target (task-055). NOT render-drift / `run_generator.py` (those do not touch `bin/aid`/`bin/aid.ps1`).
- **`test-aid-cli-parity.sh` extension (Bash↔PowerShell):** assert identical exit codes + messages across runtimes for:
  - `aid add` first-tool **register** / `aid remove` last-tool **unregister**; idempotent no-ops (2nd tool add, `update` of an already-registered repo, remove-one-of-several); `aid remove self` registry-with-tree removal.
  - the DM-1 registry file shape after each op (paths-only, CAN-1 form, atomic-write integrity) is identical across Bash + PS.
  - the spawn-seam: `aid dashboard start <runtime>` spawns `$AID_HOME/dashboard/server/server.{py,mjs}` with `$AID_HOME` (not single `--root`) — identical grammar/help/exit-codes both runtimes.
  - the `--remote` re-target preserves the delivery-003 clear-fail / never-public / idempotent-teardown behavior over the new page (parity-identical).
- **ASCII-only gate:** `test-ascii-only.sh` passes on the edited `bin/aid` + `bin/aid.ps1` (MEMORY "ASCII-only PowerShell scripts" — Windows ANSI-codepage mis-parse risk).
- **Manifest-boundary + atomic-write unit coverage:** the DD-4 first/last-tool boundary off the manifest's existence and the DD-3 `mktemp`+`mv` torn-write safety (a simulated concurrent-add race never yields a half-written file).
- Tests run on both runtimes where the runtime is present (skip-if-absent posture); assertions mirrored Bash↔PowerShell.

**Acceptance Criteria:**
- [ ] `test-aid-cli-parity.sh` asserts identical exit codes/messages across Bash + PowerShell for register/unregister, the idempotent no-ops, `aid remove self`, the spawn-seam relocation, and the `--remote` re-target; a deliberately divergent message/exit makes the parity test **fail**.
- [ ] The registry file shape after each op (paths-only DM-1, CAN-1 form, atomic integrity) is asserted identical across runtimes; the DD-3 atomic write is proven torn-write-safe under a simulated concurrent add.
- [ ] The DD-4 manifest-boundary (first-tool register / last-tool unregister) is unit-covered; `update` of a registered repo and remove-one-of-several are proven registry no-ops.
- [ ] `test-ascii-only.sh` passes on `bin/aid` + `bin/aid.ps1`; vendored copies are in sync (refresh asserted or CI-relied).
- [ ] Tests pass on both runtimes (skip-if-absent); existing CLI/parity suites stay green.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
