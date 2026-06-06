# task-012: npm wrapper test suite + packaging smoke (`test-npm-installer.sh`)

**Type:** TEST

**Source:** feature-003-npm-installer-cli → delivery-002

**Depends on:** task-011

**Scope:**
- Author `tests/canonical/test-npm-installer.sh` per feature-003 §S8: a thin Bash driver invoking `node` with stub scripts (no test framework, no npm devDependency), **SKIPping (exit 0) when `node` is absent**, auto-discovered by `tests/run-all.sh`.
- Cover AM01–AM09: arg passthrough (Unix); spaces/metachars as single argv; passthrough of each mode (`--update`, `--uninstall`, `--from-bundle`, `--force`, comma-list `--tool`); exit-code relay for 0–6; `--help` forwarding; platform selection via `AID_INSTALLER_PLATFORM=win32` test override (asserting the `-Tool`/`-Version`/… translation) with `bash` as default; missing-shell error → exit 1; packaging smoke (`npm pack --dry-run`/`files` parse asserts the allowlist includes the bootstrap + `VERSION` + bin and excludes `tests/`/`.aid/`); local `package.json` version == `VERSION` guard.
- Add one happy-path end-to-end smoke (real `install.sh` via `--from-bundle <fixture>` against a temp target) to prove the wrapper reaches a real bootstrap; keep network `/latest` paths stubbed/skipped.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-npm-installer.sh` is auto-discovered, SKIPs cleanly when `node` is absent, and passes the full AM01–AM09 case set.
- [ ] AM06 asserts the Windows-path flag translation via the `AID_INSTALLER_PLATFORM=win32` override; AM04 asserts exit-code relay for each of 0–6 (including the protect-on-diff default 5).
- [ ] AM08 packaging smoke confirms the published set includes the vendored bootstrap + `VERSION` + `bin/aid-installer.js` and excludes `tests/`/`.aid/`; AM09 confirms `package.json` version == `VERSION`.
- [ ] AM05 asserts `-h|--help` is forwarded to the bootstrap (the wrapper relays help, does not originate it).
- [ ] AM07 asserts a missing platform shell produces the wrapper-originated error → exit 1.
- [ ] One E2E smoke proves a real `--from-bundle` install lands the tool tree + manifest via the wrapper.
- [ ] All §6 quality gates pass.
