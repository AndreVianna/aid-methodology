# task-008: M5 — wire pause/block signals

**Type:** IMPLEMENT

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-007

**Scope:**
- Wire pause/block signals into the `## Pipeline Status` block (feature-001 §4 M5):
  - Write `Lifecycle: Paused-Awaiting-Input` + `Pause Reason` on a pending Q&A / PAUSE-FOR-USER-ACTION / PAUSE-FOR-USER-DECISION transition (`state-machine-chaining.md:41-63` consumers); approvals are a kind of input (`**User Approved:** no` at a gate maps here).
  - Write `Lifecycle: Blocked` + `Block Reason` + `Block Artifact` on an IMPEDIMENT (the flat `IMPEDIMENT-task-NNN.md` path per task-001), a `## Tasks Status` row `Status = Failed`, or a sub-minimum `## Delivery Gates` grade — in `aid-execute`'s impediment path.
- Use the same `--pipeline` locked helper; add no new prompt/gate; preserve the existing pause/resume + impediment flows exactly (C4).
- Re-run the FULL `run_generator.py`; manually confirm pause/resume + impediment flows are unchanged.

**Acceptance Criteria:**
- [ ] A pending-Q&A / PAUSE transition writes `Lifecycle: Paused-Awaiting-Input` + a `Pause Reason`; resuming (input answered/approved) returns the block to `Running` (feature-001 §3 SM).
- [ ] An IMPEDIMENT / `Status = Failed` / sub-min gate writes `Lifecycle: Blocked` + `Block Reason` + `Block Artifact` (the flat IMPEDIMENT path); resolution returns to `Running`.
- [ ] The on-disk block now deterministically exposes every FR16 derivation primitive (feature-001 AC2); no inference needed by a reader.
- [ ] The existing pause/resume and impediment flows are observably unchanged (no new prompt/gate/output) — C4 holds.
- [ ] FULL generator re-run; no render-drift; `verify_deterministic.py` exits 0.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit/integration tests for the pause/block emit points added; existing tests pass; FULL generator build passes (behavior-preservation walk-through is task-009).
