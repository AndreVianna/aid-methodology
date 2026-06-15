# task-009: d001 test migration — format stamp + fail-safe gate assertions (constant parity, refuse/offer/malformed)

**Type:** TEST

**Source:** feature-003-per-repo-format-stamp → delivery-001

**Depends on:** task-005, task-006, task-007

**Scope:**
- Add the feature-003 stamp + fail-safe gate assertions (feature-003 Testing 1-7), bash + ps1 in lockstep. HOME-pinned per the migration-safety rule.
  - **Constant parity (Q3):** assert the integer in `bin/aid`'s `AID_SUPPORTED_FORMAT` equals `bin/aid.ps1`'s `$AidSupportedFormat` and both equal `1` (new assertion in `test-aid-cli-parity.sh`).
  - **Stamp written on migrate:** after `aid __migrate-repo` / the era-b synthesizer runs on a fixture repo, `.aid/settings.yml` contains top-level `format_version: 1` — both era-a (repair) and era-b (synthesize) fixtures (extend `test-aid-migrate.sh` / `test-aid-cli-parity.sh`).
  - **Round-trip:** a repo stamped `1` with sup=`1` → gate silent, operates, no rewrite.
  - **Refuse-on-newer:** `format_version: 2` → bare `aid`/`status` exits non-zero with the refuse message and performs **no** write to `.aid/` (assert byte/mtime identity of settings.yml) — `test-aid-migrate.sh` + `test-aid-cli-ps1.sh`.
  - **Offer-on-older/absent:** `format_version: 0`, no-key, and era-b-only (no settings.yml) fixtures → warn+offer line, command still operates (exit 0).
  - **Malformed value:** `abc` / `1.5` / empty → classified `0` (needs-migration), never newer; command operates (guards refuse-vs-migrate direction).
  - **bash/ps1 behavioral parity:** refuse/offer/silent outcomes match across both entrypoints for the same fixtures (`test-aid-cli-ps1.sh` / `test-aid-cli-parity.sh`).
- Keep HOME-pin + escape canary on every migration/encounter test. No production code edits.

**Acceptance Criteria:**
- [ ] Constant-parity assertion: `bin/aid` and `bin/aid.ps1` both expose the format constant `= 1` and CI fails on drift.
- [ ] Stamp-on-migrate, round-trip, refuse-on-newer (no `.aid/` write), offer-on-older/absent, and malformed→0 assertions all present and passing on both bash and ps1 fixtures.
- [ ] Refuse path asserts byte/mtime-identity of `.aid/settings.yml` (no mutation on a newer-format repo).
- [ ] HOME-pin + escape canary retained on every migration/encounter test.
- [ ] `tests/run-all.sh` is green HOME-pinned at the d001 boundary with these assertions added (bash side; ps1 parity on the Windows CI runner).
- [ ] All §6 quality gates pass.
