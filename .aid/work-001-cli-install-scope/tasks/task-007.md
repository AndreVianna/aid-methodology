# task-007: d001 test migration — fixture split, retired marker/scan/sentinel, home-split assertions

**Type:** TEST

**Source:** feature-001-runtime-scope-and-home-split → delivery-001

**Depends on:** task-001, task-002, task-005

**Scope:**
- Migrate the canonical suites that feature-001 breaks so `tests/run-all.sh` stays green HOME-pinned at the d001 boundary (feature-001 slice; feature-005 audit categories C1/C2/C3/C5). Bash + ps1 in lockstep.
  - **Fixture split (C1):** rework the conflated `new_aid_home()`-style payload+state dir into a CODE_HOME (`bin/aid` + `lib/` + `VERSION` + stub `dashboard/home.html`, self-located) + STATE_HOME (`AID_HOME=` throwaway, registry/state only) pair, in the suites that build it: `tests/canonical/test-aid-migrate.sh` (`new_aid_home()` l.56-67, `run_migrate()` l.72-79), `test-aid-dashboard-cli.sh`, `test-aid-remote.sh`, and the conflated invocation in `test-aid-cli.sh` (`AID_HOME`/`AID_LIB_PATH` sites) + `test-aid-cli-parity.sh` + `test-aid-cli-ps1.sh`. Add `new_code_home()` / `new_state_home()` helpers (shared `tests/canonical/lib/` helper if one exists — Glob to confirm before introducing).
  - **Retire marker/scan/sentinel (C2/C3):** delete/rewrite assertions for `.migrated`, `_aid_check_migrate_sentinel`, `_aid_write_migrated_marker`, `_aid_scan_for_repos`, `_aid_check_repo_compliant`, `_aid_scan_and_migrate` (+ ps1 twins) across `test-aid-migrate.sh`, `test-aid-cli-parity.sh`, and the "VERSION advanced → scan fires" / SEC-6 no-loop assertions.
  - **Rewrite `test-aid-migrate-trigger.sh`** to the lazy-stamp model: "on encounter, absent stamp → stamp written + offer"; **retain** the HOME pin (l.113) + escape canary (l.224-228).
  - **Home-split assertions (feature-001 Testing 1-6):** scope detection both ways (writable→per-user; chmod read-only payload→global with `AID_STATE_HOME=${AID_SHARED_STATE_HOME:-<tmp>/shared}`, asserting resolved value without requiring the dir); `AID_HOME` redirects STATE only (registry under throwaway, `lib`/`VERSION`/`dashboard` under CODE_HOME); `.update-check` always `~/.aid` + no elevation; Q1 error-out (forced-empty self-path → non-zero + clear error + no `.aid` side-effect); grep-zero marker/scan audit.
- Every migration/encounter test keeps `export HOME=<throwaway>` + escape canary (MEMORY: aid-scan-tests-must-pin-home). No production code edits.

**Acceptance Criteria:**
- [ ] The conflated `new_aid_home()`-style fixture is split into CODE_HOME + STATE_HOME across all suites that built it; code refs resolve via self-locate / `AID_CODE_HOME`, never via `AID_HOME`.
- [ ] Zero live assertions reference `.migrated` / `_aid_scan_for_repos` / `_aid_check_migrate_sentinel` / `_aid_write_migrated_marker` / `_aid_scan_and_migrate` (or ps1 twins); `test-aid-migrate-trigger.sh` asserts the lazy-stamp-on-encounter model.
- [ ] Scope-detection, `AID_HOME`-redirects-STATE-only, `.update-check`-always-`~/.aid`, and Q1-error-out assertions are present and pass.
- [ ] Every migration/encounter suite pins a throwaway `HOME` and retains its escape canary asserting the real repo tree is untouched.
- [ ] `tests/run-all.sh` is green HOME-pinned at the d001 boundary (bash side; ps1 parity validated on the Windows CI runner).
- [ ] All §6 quality gates pass.
