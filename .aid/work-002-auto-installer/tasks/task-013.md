# task-013: PyPI wrapper package (`aid-installer`) — vendor-and-spawn CLI

**Type:** IMPLEMENT

**Source:** feature-004-pypi-installer-cli → delivery-003

**Depends on:** task-003, task-005

**Scope:**
- Author the PyPI package per feature-004 §S1/§S2: a repo-root `pyproject.toml` (PEP 621 + hatchling backend), `name = "aid-installer"`, `version` == `VERSION`, `requires-python = ">=3.8"`, `dependencies = []`, two console scripts `aid` and `aid-installer` → `aid_installer.__main__:main`, and `[tool.hatch.build.targets.wheel]` shipping `aid_installer/_vendor/**`.
- Lay out `aid_installer/` with `__init__.py`, `__main__.py`, and `_vendor/` containing verbatim copies of feature-001's `install.sh`, `install.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`.
- Implement `main()` (pure stdlib) symmetric with feature-003 per §S3/§S4/§S5: `argparse` pass-through (`parse_known_args`), `importlib.resources`/`Path(__file__).parent` vendor resolution, platform-shell selection (Unix → `bash install.sh`; Windows → the canonical `pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1`, fallback `powershell`), the same Unix→PowerShell flag-translation table, `subprocess.run(argv, check=False)` with inherited stdio, and verbatim exit-code propagation (`sys.exit(returncode)`).
- Originate only two pre-spawn errors: the missing-shell error (**exit 1** — missing interpreter = runtime/environment error, matching feature-003's npm wrapper and feature-001's 1 = generic runtime convention) and a wrapper-level usage error (**exit 2**); forward `-h|--help` to the bootstrap; do NOT validate `--tool`/mutual-exclusion (the bootstrap is the single validator). Declare (not implement) the FR10 `pyproject.toml ⇆ VERSION` edge for feature-005.

**Acceptance Criteria:**
- [ ] `pipx run aid-installer` (and `pipx run --spec aid-installer aid`) with auto-detect or `--tool` installs/updates AID by spawning the vendored bootstrap, with the same result as the other channels; the package contains zero install logic.
- [ ] Flags forward verbatim to `bash install.sh` on Unix and translate to `install.ps1` `-Param` spellings on the Windows path (table identical to feature-003); the Windows spawn argv (`-NoProfile -ExecutionPolicy Bypass -File`) is byte-identical to the npm wrapper's.
- [ ] Exit codes 0–6 propagate unchanged; a missing `bash` (Unix) or `pwsh`/`powershell` (Windows) exits **1** with the documented stderr message (matching feature-003's npm wrapper).
- [ ] `pyproject.toml` declares the **default** package name `aid-installer` and the **default** `requires-python = ">=3.8"` floor (the SPEC-flagged defaults), `version` == `VERSION`, and the wheel bundles `aid_installer/_vendor/` byte-identical to the repo-root bootstrap sources.
- [ ] All §6 quality gates pass.
