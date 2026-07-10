# task-002: aid-execute flattened-layout branch

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-001

**Scope:**
- Add a flattened-layout branch to `canonical/skills/aid-execute/SKILL.md` + `references/state-execute.md` + `references/state-delivery-gate.md`, detected by: no `deliveries/` wrapper under the work root AND `tasks/task-NNN/DETAIL.md` present.
- Resolve, for the flattened branch: task definition at `.aid/{work}/tasks/task-NNN/DETAIL.md` (NO per-task `STATE.md`); Execution Graph at work-root `PLAN.md` `## Execution Graph`; feature/architectural spec at work-root `SPEC.md` (single feature); delivery lifecycle/gate + per-task state cells read+write at the work-root `STATE.md` (`## Delivery Lifecycle`/`## Delivery Gate` + the promoted `### Tasks lifecycle` cells, not per-task `STATE.md`); branch synthesized `aid/{work}-delivery-001`; SCORE risk-scan path `tasks/task-NNN/DETAIL.md`.
- Keep the nested full-path resolution unchanged (additive branch only, per AC-9).
- The execute-graph scripts (`compute-block-radius.sh`, `complexity-score.sh`) need no change here (they already parse the top-level graph) -- edits are the SKILL/reference prose paths only.

**Acceptance Criteria:**
- [ ] Given a flattened work (no `deliveries/` wrapper, `tasks/task-NNN/DETAIL.md` present), aid-execute resolves task/graph/spec/branch/lifecycle + SCORE path — reading per-task state cells from the work-root `STATE.md § ### Tasks lifecycle` (not per-task `STATE.md`) — without a `features/` or `deliveries/` folder (AC-8).
- [ ] The nested full-path pipeline resolution is unchanged (no regression; additive branch).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
