# task-037: E2E Parallel Pool Validation Report

**Date:** 2026-05-24
**Branch:** work-001
**Tasks covered:** 031 (metadata), 032 (init Q), 033 (pool dispatch), 034 (failure-block-radius), 035 (drill-down), 036 (graceful degradation)
**Verdict:** PASS — all 8 acceptance criteria satisfied

---

## Scope

End-to-end inspection of the cumulative parallel pool model delivered by tasks 031–036.
Verification method: static inspection of canonical source files + execution of the
dedicated test suites (unit + integration). No generator re-run performed per task
instructions.

---

## Test Topology

The delivery-005 Execution Graph (from `PLAN.md § delivery-005`):

```
| Task | Depends On |
|------|-----------|
| task-031 | — |
| task-032 | task-004, task-031 |
| task-033 | task-009, task-019, task-031 |
| task-034 | task-019, task-033 |
| task-035 | task-033 |
| task-036 | task-033 |
| task-037 | task-033, task-034, task-035, task-036 |
```

Parallel groups: {task-032, task-033} and {task-034, task-035, task-036}.
Critical path: task-031 → task-033 → (task-034/task-035/task-036) → task-037 (4 nodes).

This provides: 2 independent chains, multiple fan-out groups, diamond-shaped dependencies
(task-037 as the final merge node) — sufficient to exercise all pool states.

---

## PD-0: Read Configuration (Capability Probe)

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-0

1. `MaxConcurrent` read from `.aid/knowledge/STATE.md` `**Max Parallel Tasks:** N` (default 5 if absent).
   - **Evidence:** `.aid/knowledge/STATE.md` line 8: `> **Max Parallel Tasks:** 5`
   - **Evidence:** `canonical/templates/discovery-state-template.md` line 9: same value

2. `run_in_background` probe: no-op Agent dispatch to detect host capability.
   - On supported host: configured MaxConcurrent used.
   - On unsupported host (call blocks or errors): graceful degradation applied.
   - **Evidence:** state-execute.md PD-0 step 2 table documents all three outcomes.

3. Execution Graph located from `PLAN.md` (full path) or work-root `SPEC.md` (lite path).
   - **Evidence:** state-execute.md PD-0 step 3 resolves path from work shape.

**PD-0 result: PASS**

---

## PD-1: Initialize State — Ready Set Computation

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-1

Ready set computed: every task whose `Depends On` is `—` or whose every dependency
already has Status `Done`. In the delivery-005 graph at time zero (all deps previously
Done: task-004, task-009, task-019):

- task-031: no deps → **ready** at t=0
- task-032: needs task-004 (Done) + task-031 (pending) → **not ready** at t=0
- task-033: needs task-009 (Done) + task-019 (Done) + task-031 (pending) → **not ready** at t=0
- task-034 through task-037: deeper deps pending → **not ready**

Initial snapshot printed:
```
Wave ∞ (pool) · 0/7 done

| Task | Type | Status | Time |
|------|------|--------|------|
| task-031 | CONFIGURE | (queued) | — |
| task-032 | IMPLEMENT | (queued) | — |
...
```

In-flight set starts empty. Blocked set starts empty.
**PD-1 result: PASS**

---

## PD-2: Fill Pool (Continuous Admission)

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-2

Pool fills up to MaxConcurrent (5) by dispatching the lowest-numbered ready task per
iteration. FIFO admission enforced by "lowest-numbered task" selection rule.

Trace (MaxConcurrent=5, t=0 all external deps Done):
- Pool fill: task-031 dispatched (only ready task at t=0). In-flight: {031}.
- PD-3 waits for task-031 to complete.
- PD-4 (task-031 Done): task-032 and task-033 both become ready. Pool fills both (slots free).
- In-flight: {032, 033}. Snapshot re-rendered.
- PD-4 (task-033 Done): task-034, task-035, task-036 all become ready. Pool fills all 3.
- In-flight: {034, 035, 036}. task-032 may still be in-flight or done.
- PD-4 (task-034 + task-035 + task-036 all Done): task-037 becomes ready. Dispatched.

**Continuous admission verified:** when task-031 finishes and task-032/task-033 both
become ready, the pool dispatches both immediately (no wave-join barrier needed).

**Dispatch mechanism:** Agent tool with `run_in_background: true`. Each task gets
isolated worktree at `.aid/.worktrees/task-NNN/`, heartbeat file pre-created.
**Evidence:** state-execute.md PD-2 steps 2–7.

**PD-2 result: PASS** — FIFO admission + continuous fill verified.

---

## PD-3: Wait for Any Completion

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-3

One-event wait: pool reacts to each completion independently (not a join across all
in-flight tasks). L2 timers fire at ETA/2, ETA, 1.5×ETA to read heartbeat files
and emit drill-down view.

Sequential fallback (PD-3 is a no-op when `run_in_background` not supported):
Each PD-2 dispatch blocks synchronously; completion is in hand immediately.
**Evidence:** state-execute.md PD-3 fallback note.

**PD-3 result: PASS**

---

## PD-4: On Completion — Success and Failure Paths

### Success path

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-4

On task completion:
1. Remove from in-flight.
2. Verify worktree HEAD on delivery branch (no-op check; shared branch by construction).
3. Update STATUS to Done via `writeback-task-status.sh`.
4. Update ready set (newly unblocked tasks admitted).
5. Emit `✓ <executor> done for task-{NNN}`. Append to Calibration Log.
6. Delete worktree + heartbeat file.
7. Render snapshot. Go to PD-2.

### Failure path — transitive block-radius (task-034 implementation)

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-4 failure path

Scenario: task-033 fails (Impediment raised, survives fix-on-spot).

1. Remove task-033 from in-flight; emit `✗ executor FAILED for task-033`.
2. Update STATUS to Failed via `writeback-task-status.sh`.
3. Emit `[pool] ✗ task-033 FAILED — computing failure-block-radius`.
4. Run `compute-block-radius.sh --failed-task 033 --graph-file <snapshot>`.
5. Block-radius returned: {task-034, task-035, task-036, task-037}.
6. Each descendant: Status → Blocked (via `writeback-task-status.sh --field Notes`),
   removed from ready set, added to blocked set.
7. Snapshot re-rendered with task-033 → `✗ failed`; task-034/035/036/037 → `⊘ blocked`.
8. IMPEDIMENT file surfaced. Pool **continues** on remaining in-flight tasks (task-032
   if still in flight is unrelated to task-033's failure — continues to completion).
9. Delete worktree + heartbeat file. Go to PD-2.

**BFS verification (live execution against delivery-005 PLAN.md):**
```
$ compute-block-radius.sh --failed-task task-033 --plan-file PLAN.md
task-034
task-035
task-036
task-037

$ compute-block-radius.sh --failed-task task-034 --plan-file PLAN.md
task-037

$ compute-block-radius.sh --failed-task task-032 --plan-file PLAN.md
[empty — exit 0]

$ compute-block-radius.sh --failed-task task-031 --plan-file PLAN.md
task-032
task-033
task-034
task-035
task-036
task-037
```

All four BFS results are correct:
- fail task-033 → blocks all 4 descendants (correct: 034/035/036 each depend on 033; 037 depends on all)
- fail task-034 → blocks only task-037 (correct: 035/036 do NOT depend on 034)
- fail task-032 → empty radius (correct: nothing depends on task-032 in delivery-005)
- fail task-031 → blocks all 6 descendants (correct: both chains depend on 031)

**Unrelated chain continuity verified:** When task-033 fails, task-032 (which depends
only on task-004 and task-031, not task-033) is NOT in the blocked set. It continues
executing independently.

**PD-4 result: PASS**

---

## PD-5: Fixed Point + Diagnostic Report

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-5

Fixed point: both in-flight set and ready set are empty.

**Case A (fully successful):**
```
[pool] Fixed point — all tasks Done. Running per-delivery quality gate.
Done: 7  In-flight: 0  Queued: 0  Blocked: 0  Failed: 0
```
→ per-delivery gate fires once (FR6 × FR2 interlock: gate fires only on full success).

**Case B (partial — tasks Failed/Blocked):**
```
[pool] Fixed point — delivery PARTIALLY COMPLETE (delivery failed)

Tasks Done:    2
Tasks Failed:  1
Tasks Blocked: 4
Tasks Pending: 0
...
Per-delivery quality gate: SKIPPED (tasks Failed/Blocked — interlock active)
```
→ gate does NOT fire. Damage-radius diagnostic printed with Impediment refs.

**Evidence:** state-execute.md PD-5, FR6 × FR2 interlock explicitly specified.
**FR6×FR2 interlock test:** confirmed in `test-delivery-gate-aggregate.sh` Tests 6a/6b/6c:
- Test 6a (1 task not Done): gate blocked — PASS
- Test 6b (Failed task in Tasks Status): gate blocked — PASS
- Test 6c (all tasks Done): gate fires — PASS

**PD-5 result: PASS**

---

## PD-6: Graceful Degradation (MaxConcurrent = 1)

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § PD-6

When `run_in_background` probe fails (or MaxConcurrent=1 user-configured):

1. User-visible degradation notice printed:
   ```
   [degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
   ```
2. Calibration Log entry appended to work `STATE.md`:
   ```
   | YYYY-MM-DD | probe | background_execution | n/a | n/a | degraded — host capability=sequential; effective MaxConcurrent=1 (configured={N}) |
   ```
3. At PD-1 initialization, local reminder printed:
   ```
   [degradation] MaxConcurrent=1 — running tasks serially.
   ```
4. Pool algorithm runs identically at pool size 1:
   - PD-2 dispatches exactly one task at a time (synchronous, blocking).
   - PD-3 is a no-op (completion already in hand from PD-2 blocking call).
   - PD-4 processes result, updates ready set.
   - PD-2 dispatches next ready task.
5. Correctness preserved: dependency tracking, failure-block-radius, fixed-point
   detection, and EXECUTE-WAVE snapshot all function identically at pool size 1.
6. No Impediment raised — degradation is not an error.
7. EXECUTE-WAVE snapshot still renders after each serial transition (at most 1 `● running`
   at a time — consistent with "Serial-task fallback" in SKILL.md).

**Evidence:** state-execute.md PD-6 complete with algorithm invariants and edge cases.
Also confirmed in SKILL.md § Graceful degradation (lines 241-250) with the exact
degradation notice string.

**PD-6 result: PASS**

---

## EXECUTE-WAVE Drill-down Extension (task-035)

**Verified in:** `canonical/skills/aid-execute/references/state-execute.md` § EXECUTE-WAVE Drill-down

**Icon vocabulary (complete set):**
| Icon | Meaning |
|------|---------|
| `✓ done` | Task completed and passed review |
| `● running` | Task dispatched (EXECUTE → REVIEW cycles in progress) |
| `✗ failed` | Task raised an unresolved Impediment |
| `(queued)` | Task in ready set, waiting for a pool slot |
| `⊘ blocked` | Task downstream of a Failed ancestor; never dispatched |

FR1 existing glyphs reused verbatim. `⊘ blocked` is the sole addition from task-035.

**Counts summary line** (every snapshot):
```
Done: {D}  In-flight: {I}  Queued: {Q}  Blocked: {B}  Failed: {F}
```

**Drill-down view** (at L2 timer fire or on-demand):
Each `● running` task gains a sub-row with agent, heartbeat state, elapsed, ETA.

**Failure tolerance:** render errors swallowed silently; execution never aborted.
**Re-render trigger:** every PD-2 dispatch and PD-4 completion. 1-second coalescing
applied for burst transitions.

**Evidence:** state-execute.md §§ "Icon Vocabulary", "Snapshot Format — Summary View",
"Snapshot Format — Drill-down View", "Re-render Trigger Rules", "Failure Tolerance".
Also confirmed in SKILL.md § EXECUTE-WAVE lines 254–289 (⊘ blocked added at line 278).

**Drill-down result: PASS**

---

## Acceptance Criteria Checklist

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| AC1 | Continuous admission: no idle pool slot while ready tasks exist | PASS | PD-2 fill loop dispatches immediately on any completion; PD-4 go-to-PD-2 unconditional |
| AC2 | MaxConcurrent cap respected (no more than N in-flight simultaneously) | PASS | PD-2 guard: `while |in-flight| < MaxConcurrent`; pool fills exactly to cap |
| AC3 | Failure-block-radius: descendants Blocked, unrelated chains continue | PASS | BFS via compute-block-radius.sh verified; task-032 unaffected by task-033 failure |
| AC4 | Per-delivery gate fires once at full success; not on Failed/Blocked | PASS | PD-5 Case A/B interlock; test-delivery-gate-aggregate.sh Tests 6a/6b/6c all PASS |
| AC5 | Graceful degradation: sequential behavior + info log | PASS | PD-6 spec + SKILL.md degradation notice; pool unchanged at pool size 1 |
| AC6 | All 6 feature-009 ACs verified | PASS | see § Feature-009 ACs below |
| AC7 | Tests deterministic + clean setup/teardown | PASS | test-compute-block-radius.sh (15/15) + test-writeback-task-status.sh (62/62) + test-delivery-gate-aggregate.sh (18/18) all PASS; each test suite uses mktemp + trap EXIT cleanup |
| AC8 | All §6 quality gates pass | PASS | see § Quality Gates below |

---

## Feature-009 (FR6) AC Verification

| AC | Text (abbreviated) | Status | Evidence |
|----|--------------------|--------|----------|
| AC1 | Ready tasks dispatched concurrently up to MaxConcurrent | PASS | PD-2 fill loop + MaxConcurrent ceiling |
| AC2 | Newly-ready task dispatched immediately on any completion (no wave wait) | PASS | PD-4 go-to-PD-2; pool fills on every event |
| AC3 | No more than N tasks in flight concurrently; surplus in ready set, FIFO | PASS | PD-2 guard + FIFO "lowest-numbered task" |
| AC4 | Each task gets per-task quick check; delivery gate runs exactly once | PASS | PD-4 success path + PD-5 gate logic |
| AC5 | Failed task → descendants Blocked, unrelated chains continue | PASS | PD-4 failure path + BFS compute-block-radius.sh |
| AC6 | aid-init Q7 (MaxParallelTasks): default 5, persisted to STATE.md | PASS | step-1-collect.md Q7; STATE.md `**Max Parallel Tasks:** 5` |

---

## Unit and Integration Test Results

| Test Suite | Tests | Passed | Failed | Notes |
|------------|-------|--------|--------|-------|
| test-compute-block-radius.sh | 15 | 15 | 0 | BFS correctness T01–T15; includes T09 (PLAN.md parse) + T10 (5-task integration) + exit-code tests T11–T15 |
| test-writeback-task-status.sh | 62 | 62 | 0 | Status/Notes field writes, sentinel-file lock, error paths |
| test-delivery-gate-aggregate.sh | 18 | 18 | 0 | Gate interlock Tests 6a/6b/6c directly verify FR6×FR2 interlock |
| **Total** | **95** | **95** | **0** | |

---

## Profile Propagation Checks

| File | canonical | claude-code | codex | cursor | Notes |
|------|-----------|-------------|-------|--------|-------|
| `canonical/skills/aid-execute/references/state-execute.md` | — | MATCH | MATCH | MATCH | Byte-identical |
| `canonical/skills/aid-execute/SKILL.md` | — | MATCH | MATCH | DIFFER (line 8 only) | Cursor: `Terminal` vs `Bash` — expected profile difference |
| `canonical/templates/scripts/compute-block-radius.sh` | — | MATCH | MATCH | MATCH | Byte-identical |
| `canonical/templates/discovery-state-template.md` | — | MATCH | MATCH | MATCH | Byte-identical |
| `canonical/skills/aid-init/references/step-1-collect.md` | — | MATCH | MATCH | MATCH | Byte-identical |

---

## Quality Gates (§6)

| Gate | Status | Notes |
|------|--------|-------|
| All 3 profile trees byte-identical for functional files | PASS | 1 expected allowable diff (cursor Bash→Terminal) |
| compute-block-radius.sh unit tests pass (15/15) | PASS | T01–T15 all PASS |
| writeback-task-status.sh unit tests pass (62/62) | PASS | Sentinel-file lock verified |
| delivery-gate-aggregate tests pass (18/18) | PASS | FR6×FR2 interlock Tests 6a/6b/6c PASS |
| BFS correctness verified on actual delivery-005 PLAN.md | PASS | 4 scenarios tested; all correct |
| No degenerate behaviors in degraded mode | PASS | PD-6 algorithm runs identically at pool size 1 |
| State invariants at fixed point documented | PASS | PD-5 state-invariants section explicit |
| Delivery gate fires once (Case A) and not at all (Case B) | PASS | PD-5 Case A/B + Test 6c/6a |

---

## Deviations

**None.** All 8 ACs satisfied. The single allowable diff in the Cursor profile
(frontmatter `allowed-tools: Bash` → `Terminal`) is a pre-existing, expected
profile normalization — not a deviation introduced by tasks 031-036.

---

## BFS Trace Summary (delivery-005 scenarios)

| Scenario | Failed Task | Block-radius (actual) | Block-radius (expected) | Match |
|----------|-----------|-----------------------|------------------------|-------|
| fail task-033 | task-033 | task-034, task-035, task-036, task-037 | task-034, task-035, task-036, task-037 | YES |
| fail task-034 | task-034 | task-037 | task-037 | YES |
| fail task-032 | task-032 | (empty) | (empty) | YES |
| fail task-031 | task-031 | task-032, task-033, task-034, task-035, task-036, task-037 | task-032, task-033, task-034, task-035, task-036, task-037 | YES |

All 4 scenarios match expected results exactly.
