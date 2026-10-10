# task-026: Packages and bootstrap installers on the shared release

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

**Type:** IMPLEMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-17

**Depends on:** task-012, task-013, task-015

**Scope:**
- `packages/npm/scripts/vendor.js` and `packages/pypi/scripts/vendor.py`: unchanged in shape (same
  vendored file set: `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd`, `lib/aid-install-core.sh`,
  `lib/AidInstallCore.psm1`); confirm they vendor the updated `lib/` and `bin/`, and change them
  only if a path they copy moved.
- `install.sh` and `install.ps1`: only the usage examples change (search:
  `--from-bundle ./aid-codex-v` and `-FromBundle .\aid-codex-v`) -- a release staging directory
  instead of a single tarball; a single-artifact path still works because the CLI uses its directory.
- `tests/canonical/test-npm-installer.sh` and `tests/canonical/test-pypi-installer.sh`: build their
  release fixtures with `tests/lib/bundle.sh`, re-key layout assertions, and assert the vendored
  `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1` match `lib/` by sha256.
- Version lockstep (`VERSION`, `packages/npm/package.json`, `packages/pypi/pyproject.toml`, the
  manifest `aid_version`) is unchanged.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-npm-installer.sh` and `HOME=$(mktemp -d) bash tests/canonical/test-pypi-installer.sh` exit `0`, each including a `PASS:` line for the sha256 match of both vendored libs against `lib/`.
- [ ] `git diff --stat` of this task shows no change to the vendored file list in `vendor.js` or `vendor.py` (the copy-pair arrays are unchanged).
- [ ] `bash install.sh --help` and the `install.ps1` header show the staging-directory form of `--from-bundle` / `-FromBundle`.
- [ ] `bash canonical/aid/scripts/release/check-version-sync.sh` and `bash tests/canonical/test-version-sync.sh` exit `0`.
- [ ] All section-6 quality gates pass.
