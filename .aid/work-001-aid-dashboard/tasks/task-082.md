# task-082: TEST — cross-manager trigger + Bash↔PS parity + ASCII + vendor-refresh §6 gates 1-3, 9

**Type:** TEST

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-076, task-079, task-080

**Scope:**
- Author the **gate-suite** tests for the migration surface, covering §6 gates 1-3 (ASCII / parity /
  vendor-refresh) and §6 gate 9 (cross-manager trigger). No production file is modified.
- **§6 gate 9 — cross-manager trigger (TEST):** with `$AID_HOME/VERSION` advanced past `$AID_HOME/.migrated`:
  (a) an **interactive** sentinel run triggers the FF-2 scan **once** and advances the marker; (b) a
  **second** run at the same version does **NOT** re-trigger (SEC-6 no-loop steady state); (c) a
  **non-interactive** run without the opt-in **defers** (annotates, marker unchanged); (d) with
  `AID_MIGRATE_YES=1` it migrates and advances the marker. Explicitly exercise the **pypi-no-postinstall
  sentinel-only path** (R16 — `AID_INSTALL_CHANNEL=pypi`, no postinstall, sentinel is the sole trigger) and
  the **npm-postinstall path** (the `package.json` postinstall entry from task-080 → no-TTY annotate+defer).
  Assert `AID_NO_MIGRATE=1` disables the trigger entirely.
- **§6 gate 2 — Bash↔PowerShell parity (TEST):** extend `tests/canonical/test-aid-cli-parity.sh` for the
  new migration surface — `bin/aid` and `bin/aid.ps1` produce **identical exit codes + messages** for: the
  era-a/era-b SETTINGS branches, the All/Yes/No/Cancel prompt wording (CLI-1), the declined-repo advisory,
  the WARN-not-fail lines, the `aid update` per-repo output (CLI-2), and the sentinel annotate/defer
  message (R17).
- **§6 gate 1 — ASCII-only (TEST):** `tests/canonical/test-ascii-only.sh` passes for the edited `bin/aid` +
  `bin/aid.ps1` + the new node postinstall entry — all prompt wording / advisories / WARN text are ASCII
  (MEMORY "ASCII-only PowerShell scripts"; Windows ANSI-codepage hazard).
- **§6 gate 3 — vendor-refresh (TEST):** running `node packages/npm/scripts/vendor.js` +
  `python3 packages/pypi/scripts/vendor.py` re-vendors the edited `bin/aid`/`bin/aid.ps1` **and** the new
  `dashboard/home.html`; assert `dashboard/home.html` is present in **both** manifests' copy lists and
  lands at the vendored `$AID_HOME/dashboard/home.html` path (the source task-076 added). Assert it is
  **NOT** render-drift — `bin/aid`, `bin/aid.ps1`, and `dashboard/home.html` are **absent** from
  `canonical/EMISSION-MANIFEST.md` (C8 — hand-maintained, not `run_generator.py`). Confirm task-076's
  `dashboard/home.html` == `.aid/dashboard/home.html` equality gate passes (R20).
- Tests are read-only on `.aid/`; any server stays bound to `127.0.0.1`.

**Acceptance Criteria:**
- [ ] §6 gate 9: interactive sentinel fires once + advances the marker; a second same-version run no-ops
      (SEC-6); a non-interactive run without the opt-in defers (marker stale); `AID_MIGRATE_YES=1` migrates
      + advances; the **pypi-no-postinstall sentinel-only path** and the npm-postinstall path are both
      exercised (R16); `AID_NO_MIGRATE=1` disables the trigger.
- [ ] §6 gate 2: `test-aid-cli-parity.sh` is extended and passes — Bash↔PS identical exit codes + messages
      for the era-a/era-b branches, All/Yes/No/Cancel wording, declined advisory, WARN lines, `aid update`
      output, and the sentinel annotate/defer message (R17).
- [ ] §6 gate 1: `test-ascii-only.sh` passes for `bin/aid` + `bin/aid.ps1` + the node postinstall entry
      (all prompt/advisory/WARN text ASCII).
- [ ] §6 gate 3: a vendor run re-vendors `bin/aid`/`bin/aid.ps1` + `dashboard/home.html`; `dashboard/home.html`
      is asserted present in both manifests and at `$AID_HOME/dashboard/home.html`, **absent** from
      `EMISSION-MANIFEST.md` (not render-drift, C8); the task-076 source↔copy equality gate passes (R20).
- [ ] No production file is changed by this task; read-only on `.aid/`; any server bound to `127.0.0.1`.
