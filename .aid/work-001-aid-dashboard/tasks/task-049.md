# task-049: Registry side-effect in `bin/aid` + `bin/aid.ps1` — `aid add`/`aid remove` register/unregister (atomic, manifest-boundary)

**Type:** IMPLEMENT

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-047, task-048

**Scope:**
- Implement the **DR-1 registry side-effect** (FF-1, FR29/OQ6) as a **direct edit to the HAND-MAINTAINED root `bin/aid` (Bash) + `bin/aid.ps1` (PowerShell twin)** — NOT a `canonical/`→render artifact (R10). Both runtimes are byte-behavior twins.
- Add `registry_register(path)` / `registry_unregister(path)` (LC-REG writer half): read-modify-write the `$AID_HOME/registry.yml` `repos:` set under the **DD-3 atomic `mktemp`+`mv`** (PS twin `Move-Item -Force`), set-insert/set-remove idempotent, lazy-create the file with the DM-1 managed-by comment + `schema: 1` on first register. Resolve `$AID_HOME` exactly as `bin/aid:40-47` does; canonicalize the repo path by **CAN-1** (`cd && pwd`, no `-P`; the same `--target` form at `bin/aid:1255`).
- **Wire the success-tail hooks (DD-4 manifest boundary):**
  - `add|update` success seam (shared, `bin/aid:1431`/`:1452`): if the repo path is not yet in the registry → `registry_register(CAN-1(<repo>))`. Idempotent set-membership → a 2nd/3rd tool or an `update` of an already-registered repo is a NO-OP.
  - `remove` success seam (`bin/aid:1473`): if `<repo>/.aid/.aid-manifest.json` NO LONGER EXISTS (last tool gone, `aid-install-core.sh:1633`) → `registry_unregister(CAN-1(<repo>))`. `aid remove` (all tools) lands here too. `aid remove self` removes `$AID_HOME` wholesale → no per-repo step.
- **Host-tool behavior UNCHANGED (C4/OQ6):** the side-effect runs ONLY on the post-success path; adds no prompt, changes no install/uninstall exit code, never blocks the host-tool op. A registry-write failure prints `WARN: aid: could not update the machine repo registry (<path>): <reason>` and the command still exits with its host-tool result (NFR10). Concise change line on a real change (`Registered/Unregistered <repo> ...`), silent on a no-op, `--verbose` for detail.
- ASCII-only source both runtimes; refresh vendored copies via the prepack vendor step (do not hand-edit copies).

**Acceptance Criteria:**
- [ ] `aid add` first-tool registers `CAN-1(<repo>)`; a 2nd/3rd tool add and an `aid update` of an already-registered repo are registry NO-OPs; `aid remove` of the last tool unregisters (manifest-gone boundary); `aid remove` of one-of-several leaves the registry untouched; `aid remove self` removes the whole registry with `$AID_HOME` (FF-1/DD-4).
- [ ] The registry file matches DM-1 (managed-by comment, `schema: 1`, paths-only block-sequence, stored already in CAN-1 form); writes are atomic (`mktemp`+`mv` / `Move-Item -Force`) — a concurrent-add race never yields a half-written file (DD-3).
- [ ] Host-tool install/uninstall behavior is byte-unchanged on the success path (no new prompt, same exit codes); a registry-write failure degrades to a `WARN` + the host-tool result (NFR10), never a failed install.
- [ ] Bash and PowerShell are behavior-twins: identical path resolution, first/last-tool boundary, atomic write, and messages — `test-aid-cli-parity.sh` passes; both pass `test-ascii-only.sh`; vendored copies refreshed (NOT render-drift).
- [ ] Bare `aid` and `aid version/status/dashboard` are byte-unchanged.
- [ ] All §6 quality gates pass; IMPLEMENT default — unit/CLI tests for register/unregister + the manifest-boundary + idempotency added; existing tests pass (full parity suite is task-057).
