# task-004: M2 tests — `--pipeline` mode + concurrency cases

**Type:** TEST

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-003

**Scope:**
- Extend `tests/canonical/test-writeback-state.sh` (the existing 69-test suite, feature-001 §4 M2 / §5 risk row) with cases for the new `--pipeline` mode.
- Cover: each field write (`Lifecycle`/`Phase`/`Active Skill`/`Updated`), enum acceptance + rejection (out-of-enum value → nonzero exit), the conditional `Pause/Block Reason/Artifact` writes, and that no existing mode's behavior regressed.
- Add concurrency cases: the new mode reuses the sentinel lock, so assert concurrent `--pipeline` writes (and a `--pipeline` ∥ `--field` mix) do not corrupt the STATE.md or deadlock (feature-001 §5 race risk).
- Deterministic, with clean setup/teardown of a scratch STATE.md fixture per case.

**Acceptance Criteria:**
- [ ] Tests assert valid-enum writes succeed and out-of-enum `Lifecycle`/`Phase`/`Active Skill` values are rejected with a nonzero exit.
- [ ] Tests assert the conditional `Pause/Block` fields are written only for the matching `Lifecycle`.
- [ ] Concurrency cases assert the sentinel lock serializes concurrent `--pipeline` (and mixed-mode) writes with no torn/corrupt block and no deadlock.
- [ ] Tests cover the feature-001 AC: the on-disk block deterministically exposes the FR16 derivation primitives.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean per-case setup/teardown and cover the source ACs; run green under `tests/run-all.sh`; FULL generator build passes.
