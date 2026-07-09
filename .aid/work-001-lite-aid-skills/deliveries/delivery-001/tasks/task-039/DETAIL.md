# task-039: aid-execute reads the new paths + delivery-gate criteria mis-wire fix

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-036

**Scope:**
- Edit `canonical/skills/aid-execute/SKILL.md`: every `delivery-NNN/tasks/task-NNN/SPEC.md` task-def read (the `§ Check 1`/`§ Check 2` reads, the Inputs list, the Workspace diagram `SPEC.md <- PRIMARY INPUT` line, the completion checklist `Task Type read correctly from …`) -> `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; the Workspace diagram `delivery-NNN/` -> `deliveries/delivery-NNN/`. Leave the `features/{feature}/SPEC.md` architectural-spec read UNCHANGED (that is the **feature** spec); DROP the parallel "or work-root SPEC.md (lite path)" wording (the short-path resolution is feature-001's, not here).
- Edit `canonical/skills/aid-execute/references/state-execute.md`: the `delivery-NNN/` task-def paths -> `deliveries/delivery-NNN/…/DETAIL.md`.
- Edit `canonical/skills/aid-execute/references/state-delivery-gate.md`: (1) `§ Gate Reviewer Inputs` — `All delivery-NNN/tasks/task-NNN/SPEC.md files` -> `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; (2) THE MIS-WIRE FIX — `§ Delivery-level acceptance criteria` currently reads `Full path: from PLAN.md (the delivery's acceptance criteria block)`; repoint it to `from the delivery's BLUEPRINT.md § Gate Criteria` (the file that actually declares them; `PLAN.md` has no such per-delivery block); (3) `§ Step 1: SCORE` risk-scan path -> `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`.
- A-10 clean switch: no surviving `delivery-NNN/SPEC.md` or task `SPEC.md` read path in any aid-execute file.

**Acceptance Criteria:**
- [ ] aid-execute reads task definitions from `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` — SKILL.md Check 1/2, Inputs, Workspace diagram + completion checklist; `state-execute.md`; `state-delivery-gate.md` Gate Reviewer Inputs + Step 1 SCORE risk-scan all repointed (AC-16 / FR-16).
- [ ] Delivery-gate mis-wire fixed: `state-delivery-gate.md § Delivery-level acceptance criteria` reads from the delivery's `BLUEPRINT.md § Gate Criteria` (not a `PLAN.md` block) (AC-16 gate-criteria half / FR-16).
- [ ] The `features/{feature}/SPEC.md` architectural-spec read is unchanged; the "or work-root SPEC.md (lite path)" wording is dropped (short-path is feature-001's).
- [ ] No surviving `delivery-NNN/SPEC.md` or task `SPEC.md` read path in any aid-execute file (grep; A-10).
- [ ] `aid-execute` re-reviewed >= A+ (AC-7 subset); renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
