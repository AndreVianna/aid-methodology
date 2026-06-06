# task-004: Install / update / uninstall flow docs

**Type:** DOCUMENT

**Source:** work-002-auto-installer → delivery-001

**Depends on:** task-002

**Scope:**
- Document the new one-command install, update, and uninstall flow for adopters: the
  command(s), host-tool auto-detect + override flag, version pinning/update behavior,
  and both online and offline modes.
- Update the user-facing surface (e.g. `README.md` install/runtime section and any
  `docs/` install guidance per `repo-presentation.md`) to reflect the chosen mechanism,
  replacing the "clone repo + run `setup.sh` / `setup.ps1`" instructions where superseded.
- No code changes.

**Acceptance Criteria:**
- [ ] The documented one-command install flow is described accurately for the chosen mechanism. (SPEC AC-1)
- [ ] The host-tool override flag and auto-detect behavior are documented. (SPEC AC-4)
- [ ] Both online and offline install modes are documented. (SPEC AC-8)
- [ ] Superseded clone+setup.sh/setup.ps1 instructions are updated or removed where the new flow replaces them.
- [ ] All applicable quality gates pass — universal grading rubric, enforced per task by `/aid-execute`.
