# task-036: Implement graceful-degradation for hosts without background_execution

**Type:** IMPLEMENT

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-033

**Scope:**
- At delivery start, read host capability flag `background_execution` from work-002's profile registry.
- If absent or false: set effective MaxConcurrent = 1 (sequential dispatch); user-configured MaxConcurrent becomes informational only.
- Emit single info log line at delivery start: `[degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1`.
- No Impediment raised (degradation is not an error).
- Pool loop falls through to sequential dispatch behaviorally (still uses the pool loop; effective concurrency = 1).

**Acceptance Criteria:**
- [ ] On host with background_execution: pool uses configured MaxConcurrent.
- [ ] On host without: pool uses effective MaxConcurrent=1; info log emitted.
- [ ] Pool loop's correctness preserved under sequential dispatch (no degenerate behavior).
- [ ] User-configured MaxConcurrent is read and logged even when overridden by degradation.
- [ ] No Impediment / error on degraded host.
- [ ] Unit tests with a mock capability flag set to false.
- [ ] All §6 quality gates pass.
