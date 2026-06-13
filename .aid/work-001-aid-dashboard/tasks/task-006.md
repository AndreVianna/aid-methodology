# task-006: M3 tests — `Status` enum validation

**Type:** TEST

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-004, task-005

**Scope:**
- Extend `tests/canonical/test-writeback-state.sh` with `--field Status` enum-validation cases (feature-001 §4 M3).
- Cover: each of the 7 enum members accepted; the `_none yet_` placeholder row accepted; an arbitrary out-of-enum string rejected with a nonzero exit; the six today-produced strings still accepted (C4 no-regression).
- Deterministic, clean per-case setup/teardown against a scratch STATE.md `## Tasks Status` fixture.

**Acceptance Criteria:**
- [ ] Tests assert all 7 `TaskStatus` members + the `_none yet_` placeholder are accepted, and an out-of-enum value is rejected with a nonzero exit.
- [ ] Tests assert the six legacy producer strings still validate (no observable behavior change, C4).
- [ ] Tests cover the source AC (the typed `Status` column is deterministically consumable by feature-002).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean per-case setup/teardown and cover the source ACs; run green under `tests/run-all.sh`; FULL generator build passes.
