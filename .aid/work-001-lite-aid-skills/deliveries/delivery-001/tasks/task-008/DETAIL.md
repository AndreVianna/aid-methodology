# task-008: shortcut-engine.md state machine + capture/scaffolding/default-type rules

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-001, task-007

**Scope:**
- Create `canonical/aid/templates/shortcut-engine.md` -- the single shared engine. Author the state machine INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL (Describe/Define/Specify/Plan/Detail collapsed; NOT Execute): INTAKE parses `{verb, artifact, description}`, looks up the catalog row for `default_type`/group, allocates `work-NNN`, scaffolds `STATE.md` (Pipeline State only); CAPTURE authors the terse-but-complete `REQUIREMENTS.md`; SPEC authors the single work-root `SPEC.md` (feature-001 shape); PLAN authors the single work-root `PLAN.md` **and** the work-root `BLUEPRINT.md` (the single delivery definition, incl. its `## GATE CRITERIA`); DETAIL emits `tasks/task-NNN/DETAIL.md` (bold `**Type:**`, `**Source:** work-NNN-<name> -> delivery-001`; **NO per-task `STATE.md`**) + the `## Execution Graph` table, and promotes each task cell into the work-root `STATE.md § ### Tasks lifecycle` (alongside the promoted `## Delivery Lifecycle`/`## Delivery Gate` blocks). Per the feature-001/003 amended flat layout (A-10 clean switch).
- Encode the capture-minimization rules (bounded minimal-slot fill; escalate only for a load-bearing unknown) and the per-family scaffolding-reference consult at `canonical/aid/templates/shortcut-scaffolding/<family>.md` (keyed by `{verb, artifact}`).
- Encode the A-6 default-type mapping table (no enum change). Authoring states dispatch `aid-architect` (Large).
- GATE + APPROVAL-HALT are added into this same file by task-011 (feature-004).

**Acceptance Criteria:**
- [ ] Engine defines INTAKE/CAPTURE/SPEC/PLAN/DETAIL with capture-minimization + the scaffolding-consult + the default-type mapping; writes REQUIREMENTS/SPEC/PLAN + the work-root `BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` (no per-task `STATE.md`; task cells promoted into the work-root `STATE.md § ### Tasks lifecycle`) in the feature-001 flattened shape (FR-1..FR-7).
- [ ] No feature decomposition / no multi-delivery / no interview-triage; authoring dispatched to `aid-architect` (Large).
- [ ] Renders verbatim to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass.
- [ ] All §6 quality gates pass.
