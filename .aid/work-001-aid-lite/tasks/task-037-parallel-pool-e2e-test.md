# task-037: End-to-end parallel pool TEST

**Type:** TEST

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-033, task-034, task-035, task-036

**Scope:**
- Run `/aid-execute` against a sample delivery with parallel-eligible tasks (5+ tasks, 2 chains + 2 independent).
- Verify pool dispatches up to MaxConcurrent simultaneously (verified via dispatch timestamps).
- Verify continuous admission: when one task finishes early, the next ready task dispatches immediately without waiting for a wave.
- Run a variant with one task seeded to fail: verify failure-block-radius (descendants Blocked; unrelated chains continue).
- Verify per-delivery gate fires once after pool reaches fully successful fixed point.
- Verify gate does NOT fire when any task Failed/Blocked.
- Verify graceful degradation: run on a host with `background_execution=false`; verify sequential dispatch + info log.
- Capture results in `.aid/work-001-aid-lite/test-reports/task-037-parallel-pool-e2e.md`.

**Acceptance Criteria:**
- [ ] Continuous admission verified (no idle pool slot while ready tasks exist).
- [ ] MaxConcurrent cap respected (no more than N in-flight simultaneously).
- [ ] Failure-block-radius verified: descendants Blocked, unrelated continue.
- [ ] Per-delivery gate fires once at success; does not fire on Failed/Blocked.
- [ ] Graceful degradation produces correct sequential behavior + info log.
- [ ] All 6 ACs from feature-009 § Acceptance Criteria verified.
- [ ] Tests deterministic + clean setup/teardown.
- [ ] All §6 quality gates pass.
