# task-024: Windows installer suite and installer-tests workflow on the shared layout

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-16

**Depends on:** task-012, task-013, task-015

**Scope:**
- `tests/windows/Test-AidInstaller.ps1`: stop building tool tarballs from `profiles/<tool>/`; take
  a release staging directory produced by `release.sh --stage-only` (passed in by the workflow);
  re-key layout assertions; add the AC-9 (reference-counted remove), AC-10 (drift detected and
  repaired) and AC-13 (clean-slate upgrade from a v3 layout for every tool) scenarios as worded in
  REQUIREMENTS.md § 9.
- `.github/workflows/installer-tests.yml`: replace the inline codex fixture-tarball builds (search:
  "build codex fixture tarball") with a `bash release.sh --stage-only --out <dir>` step whose output
  the Windows and smoke steps consume.
- The suite stays ASCII-only and PS 5.1-compatible.
- `tests/windows/Test-InstallProvisioning.ps1` (task-set review row 27): re-key its settings-stamp checks (`SE1d`, `SE1e`, today `format_version: 4`) to the v4 stamp `format_version: 5`, and any template-path check to `.aid/runtime/templates/settings.yml`.

**Acceptance Criteria:**
- [ ] `tests/windows/Test-AidInstaller.ps1` passes on Windows (the `installer-tests` workflow's Windows job, or a local Windows PowerShell 5.1 run), with named cases for the AC-9, AC-10 and AC-13 scenarios.
- [ ] `grep -cE "profiles[\\\\/]" tests/windows/Test-AidInstaller.ps1` prints `0`, and `.github/workflows/installer-tests.yml` contains a `release.sh --stage-only` step and no tarball build from `profiles/`.
- [ ] `bash tests/canonical/test-ascii-only.sh` and `bash tests/canonical/test-ps51-compat.sh` exit `0`.
- [ ] Where `pwsh` exists, `pwsh -NoProfile -File tests/windows/Test-InstallProvisioning.ps1` exits 0 and its `SE1d` / `SE1e` records pass with `format_version: 5`.
- [ ] All section-6 quality gates pass.
