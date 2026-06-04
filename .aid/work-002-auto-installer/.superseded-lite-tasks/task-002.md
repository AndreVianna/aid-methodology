# task-002: Installer for the chosen mechanism

**Type:** IMPLEMENT

**Source:** work-002-auto-installer → delivery-001

**Depends on:** task-001

**Scope:**
- Implement the bootstrap entry point(s) for the mechanism selected in task-001, on both
  the bash and PowerShell paths. One cohesive installer surface delivering:
  - **(a) Install / update** the correct rendered profile tree into a target repo at a
    pinned AID version, without cloning the full AID repo. Trees per host tool:
    claude-code `.claude/`, codex `.agents/`(+`.codex/`), cursor `.cursor/`,
    copilot-cli `.github/`+root `AGENTS.md`, antigravity `.agent/`+root `AGENTS.md`.
  - **(b) Host-tool auto-detection** with an explicit override flag.
  - **(c) Version recording** in the target repo so updates are reproducible.
  - **(d) Uninstall** command that cleanly removes all AID-installed files, leaving the
    repo as it was pre-install.
  - **(e) Online and offline modes** — online fetches the pinned release from the remote;
    offline installs from a pre-downloaded bundle/archive with no network.
- Reuse/extend the existing `setup.sh` / `setup.ps1` patterns and the Option-A `AGENTS.md`
  last-installed-wins collision handling where applicable (`infrastructure.md`).
- Does NOT modify the canonical → profiles render pipeline (out of scope).
- Deliverables (a)–(e) share one IMPLEMENT type and form one coherent installer surface;
  each maps to its own acceptance criterion below and is independently reviewable. If
  task-001's chosen mechanism makes any deliverable large enough to warrant its own unit,
  honor the SPEC re-plan checkpoint (split or escalate) before starting.

**Acceptance Criteria:**
- [ ] Running the one-command installer installs or updates the correct profile tree at a pinned version without a full repo clone. (SPEC AC-1)
- [ ] Host tool is auto-detected when unspecified; an explicit override flag is honored; failure to detect produces a clear prompt/error. (SPEC AC-4)
- [ ] The installed AID version is recorded in the target repo. (SPEC AC-7)
- [ ] An uninstall command removes exactly the AID-installed files, leaving the repo pre-install-clean. (SPEC AC-3)
- [ ] Both online (remote fetch) and offline (pre-downloaded bundle) install modes work. (SPEC AC-8)
- [ ] Bash and PowerShell paths are both implemented (cross-platform). (SPEC AC-5)
- [ ] Dependency footprint matches the task-001 recommendation and stays minimal unless explicitly justified. (SPEC AC-6)
- [ ] All applicable quality gates pass — universal grading rubric, enforced per task by `/aid-execute`.
