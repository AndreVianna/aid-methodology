# task-006: aid-plan — create delivery folders (SPEC.md + STATE.md); derived deliveries view

**Type:** REFACTOR

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Update `canonical/skills/aid-plan/` so each delivery from PLAN.md produces `delivery-NNN/SPEC.md` (delivery definition: scope, included tasks, gate criteria) + `delivery-NNN/STATE.md` (delivery lifecycle + gate block placeholder + `## Cross-phase Q&A` slot + derived task rollup, per SD-5).
- **Author the delivery's INDEPENDENT lifecycle (SD-8/SD-9).** aid-plan writes the initial delivery-state enum value `Pending-Spec` into `delivery-NNN/STATE.md` at creation; the enum `Pending-Spec | Specified | Executing | Gated | Done | Blocked` is the delivery's OWN authored state, NOT a derivation of its task rollup. A delivery may be created with ZERO tasks (e.g. a SPIKE delivery that defines a sibling delivery to be specified later) and must render correctly at `Pending-Spec` with no tasks. `aid-specify` later advances it to `Specified`; aid-execute advances the rest (task-007).
- Keep `PLAN.md` as the execution-graph home (unchanged role); the work `STATE.md` `## Plan / Deliveries` view becomes DERIVED from the delivery `STATE.md` files (aid-plan does NOT write delivery rows into the work STATE.md).
- Ensure the delivery folder is created before aid-detail nests tasks under it (cross-skill ordering note).
- Regenerate profile copies via the full generator. ASCII-only.

**Acceptance Criteria:**
- [ ] aid-plan creates `delivery-NNN/{SPEC.md,STATE.md}` per delivery; delivery SPEC.md captures scope+gate criteria; delivery STATE.md carries the independent lifecycle enum (initial `Pending-Spec`) + gate slot + `## Cross-phase Q&A` slot + derived task rollup.
- [ ] A delivery created with zero tasks renders correctly at `Pending-Spec` (the SD-9 SPIKE-defines-sibling scenario); delivery state is authored, not derived from the task rollup.
- [ ] PLAN.md retains the execution graph; `## Plan / Deliveries` is a derived view (aid-plan writes no delivery rows into the work STATE.md).
- [ ] Skill + profile copies regenerated (full generator); render-drift clean; ASCII-only.
- [ ] All §6 quality gates pass.
