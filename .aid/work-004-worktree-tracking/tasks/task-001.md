# task-001: Per-level STATE/SPEC template set + naming contract (state-not-status)

**Type:** DESIGN

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** — (none)

**Scope:**
- Split `canonical/templates/work-state-template.md` into a per-level template set:
  - a work-level `STATE.md` template (header + Pipeline State + Triage + Escalation Carry + Interview State + Lifecycle History [single-writer] + DERIVED views: Features State, Plan/Deliveries, Tasks State, Deploy State, Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches — mark each derived/union view explicitly as read-only);
  - a delivery-level `STATE.md` template carrying the delivery's INDEPENDENT lifecycle enum (SD-8: `Pending-Spec | Specified | Executing | Gated | Done | Blocked`, with a one-line note that this is authored, not derived from the task rollup — SD-9), the gate block, a `## Cross-phase Q&A` section (delivery-gate SPEC Q&A, moved off the work file per SD-5), and a DERIVED task rollup;
  - a task-level `STATE.md` template (the 4 mutable cells State/Review/Elapsed/Notes + per-task Quick Check Findings + per-task Dispatch Log);
  - a delivery-level + task-level `SPEC.md` template (definition slots). Reuse the existing `delivery-plans/task-template.md` 6-section shape as the task `SPEC.md`.
- Establish the naming contract: rename "status" → "state" in all section/field names (`## Tasks Status` → `## Tasks State`, `## Pipeline Status` → `## Pipeline State`, `## Features Status` → `## Features State`, `## Interview Status` → `## Interview State`, `## Deploy Status` → `## Deploy State`, per-task field `Status` → `State`). Closed enum VALUES unchanged (Pending | In Progress | In Review | Blocked | Done | Failed | Canceled). Document which views are DERIVED (read-only, never written).
- Encode the SD-2 state advancement ordering as an authoritative ordered list in a place both reader twins can reference (e.g. a comment block in the template + an inline list in schemas.md).
- This is a DESIGN task: produce the template files + the naming contract; it does NOT change skills or reader code (those are downstream tasks).

**Acceptance Criteria:**
- [ ] The per-level template files exist under `canonical/templates/` (work/delivery/task STATE.md + delivery/task SPEC.md), each marking DERIVED/union sections explicitly (work-level Tasks State, Plan/Deliveries, Delivery Gates, Cross-phase Q&A, Calibration, Dispatches).
- [ ] The delivery STATE.md template carries the SD-8 independent lifecycle enum (`Pending-Spec | Specified | Executing | Gated | Done | Blocked`) noted as authored-not-derived, plus a `## Cross-phase Q&A` section (delivery-scoped, single-writer).
- [ ] Every section/field name uses "state"; no "Status" section/field name remains in the new templates; enum values are byte-identical to the current set.
- [ ] The SD-2 ordering `Done > In Review > In Progress > Blocked > Failed > Pending` (Canceled just below Done) is written once as an authoritative ordered list with rationale.
- [ ] Templates are ASCII-only.
- [ ] All §6 quality gates pass.
