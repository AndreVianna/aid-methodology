# task-014: PyPI wrapper test suite + vendored-payload parity

**Type:** TEST

**Source:** feature-004-pypi-installer-cli → delivery-003

**Depends on:** task-013

**Scope:**
- Author the PyPI wrapper tests per feature-004 §S9, mirroring feature-003's cases one-for-one (Python idiom), and integrate them with `tests/run-all.sh` conventions (Bash driver for shell-out cases; stdlib-only Python for wrapper logic; skip-if-tool-absent).
- Cover TW01–TW08: flag forwarding (Unix verbatim, incl. comma-lists + trailing positional); flag translation (Windows path via monkeypatched `os.name`/`platform.system` + stub `pwsh`, asserting `-Tool/-Version/-FromBundle/-Force/-Update/-Uninstall/-TargetDirectory`); exit-code propagation 0–6; shell-resolution errors → exit 1 with the expected message; vendored-payload presence + **byte-identity** to repo-root sources at build time (drift gate, R2); `pyproject.toml` version == the `VERSION` file at build time (TW08 version-guard, symmetric with npm's AM09); end-to-end through the real vendored bootstrap (`--from-bundle <fixture> --tool codex --target <tmp>`, asserting the same result as `test-install.sh`); `--help` passthrough.
- PowerShell parity exercised via the skip-if-no-`pwsh` pattern (real `pwsh -File` on CI where present); keep network `/latest` stubbed/skipped.

**Acceptance Criteria:**
- [ ] TW01–TW08 pass; the suite skips cleanly when the relevant runtime is absent and runs for real on CI where `python`/`pwsh`/`bash` are present (TW06's `--from-bundle` e2e exercises `bash`).
- [ ] TW02 asserts the Windows-path flag translation to `-Tool/-Version/-FromBundle/-Force/-Update/-Uninstall/-TargetDirectory` via the monkeypatched `os.name`/`platform.system` + stub `pwsh` (mirroring npm's AM06).
- [ ] TW03 asserts verbatim propagation of exit codes 0–6 (including the protect-on-diff default 5); TW04 asserts the exit-1 no-shell error on both Unix and Windows paths.
- [ ] TW05 asserts the wheel/`_vendor/` payload contains `install.sh`, `install.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1` and that they are **byte-identical** to the repo-root sources at build time.
- [ ] TW06 proves a real `--from-bundle` install through the vendored bootstrap matches `test-install.sh`'s result (delegation is real, not mocked).
- [ ] TW08 asserts `pyproject.toml` version == the `VERSION` file at build time (version-guard, symmetric with npm's AM09).
- [ ] All §6 quality gates pass.
