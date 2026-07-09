# task-001: Relocate delivery-folder layout across canonical + KB (nest full, flatten lite), then re-render

**Type:** REFACTOR

**Source:** work-001-add-deliveries-folder → delivery-001

**Depends on:** — (none)

**Scope:**
- **Full-path nesting** — update every canonical creator/reader so full-path deliveries live at
  `work-NNN/deliveries/delivery-NNN/`: aid-plan (`first-run-loop.md`, `SKILL.md`,
  `review-deliverables.md`, `reviewer-brief.md`), aid-detail delivery-hierarchy generation
  (`task-decomposition.md`, `first-run.md`, `execution-graph-generation.md`, `review.md`,
  `reviewer-brief.md`, `SKILL.md`).
- **Lite-path flatten** — update the aid-describe lite path — **including `aid-describe/SKILL.md`**
  (its State Detection + Dispatch logic keys off `delivery-001/tasks/`: "delivery-001/tasks/ absent
  → TASK-BREAKDOWN", "writes delivery-001/ hierarchy") plus `state-task-breakdown.md`, recipe-emit
  scaffold in `state-triage.md`, `state-condensed-intake.md`, `state-lite-*` refs — to emit tasks
  directly at `work-NNN/tasks/task-NNN/` — **no `deliveries/` and no `delivery-001/` folder** for
  lite works. Relocate the single delivery's **gate result +
  delivery-scoped Q&A** to the **work-root `STATE.md`** (author them there for lite; the tasks
  rollup derives from `work-NNN/tasks/*`).
- **Readers/traversers** — aid-execute (`state-execute.md`, `state-review.md`,
  `state-delivery-gate.md`, `reviewer-brief.md`, `README.md`, `SKILL.md`), aid-deploy
  (`state-packaging.md`, `state-selecting.md`, `README.md`), aid-housekeep, aid-monitor:
  traverse the correct location per path, and gate a **lite** work at the **work level** (no
  delivery-001 close). Grep broadly (`delivery-\d`, `delivery-*`, `delivery-NNN`, traversal globs).
- **Templates** — work-state (make the lite gate/Q&A/tasks-rollup home explicit), delivery-spec,
  delivery-state, task-spec, task-state, package, delivery-issues, `delivery-plans/task-template`,
  lite-spec.
- **Scripts** — `writeback-state.sh`, `complexity-score.sh`, `compute-block-radius.sh`;
  `migrate-work-hierarchy.sh/.ps1` emitted target string only (code edit, NOT a new data migration).
- **aid-architect agent boilerplate.**
- **KB docs** — `project-structure.md`, `artifact-schemas.md`, `pipeline-contracts.md`
  (describe both layouts: full-nested and lite-flat).
- **Leave `PLAN.md` at `work-NNN/PLAN.md`** and **leave `delivery-NNN-issues.md` as a work-root
  sibling file** — do not relocate either; do not let the grep-clean false-flag `delivery-NNN-issues.md`.
- Re-render all 5 profiles via `generate-profile`; resync dogfood `.claude/` from
  `profiles/claude-code/`; confirm `test-dogfood-byte-identity` passes.
- Grep-clean the methodology side (canonical + profiles + dogfood + KB): zero lingering flat
  `work-NNN/delivery-NNN/` folder-location references.

**Acceptance Criteria:**
- [ ] Full path emits delivery folders at `work-NNN/deliveries/delivery-NNN/` (never flat at the work root). *(SPEC AC 1)*
- [ ] Lite path emits tasks at `work-NNN/tasks/task-NNN/` — no `deliveries/`, no `delivery-NNN/`. *(SPEC AC 3)*
- [ ] For lite works, the single gate result + delivery Q&A are authored in the work-root `STATE.md`; tasks rollup derives from `work-NNN/tasks/*`. *(SPEC AC 4)*
- [ ] `PLAN.md` remains at `work-NNN/PLAN.md`; `delivery-NNN-issues.md` remains a work-root sibling file. *(SPEC AC 2)*
- [ ] Pipeline consumers (aid-detail, aid-execute, aid-deploy, aid-housekeep, aid-monitor) traverse the correct location per path; aid-execute gates a lite work at the work level. *(SPEC AC 5)*
- [ ] Templates, scripts, agent boilerplate, and KB docs reflect both layouts; `migrate-work-hierarchy` target updated (no new data migration). *(SPEC AC 7)*
- [ ] `generate-profile` re-renders all 5 profiles; dogfood resynced from `profiles/claude-code/`; `test-dogfood-byte-identity` passes. *(SPEC AC 9)*
- [ ] Grep-clean (methodology side): no lingering old flat `work-NNN/delivery-NNN/` references. *(SPEC AC 10)*
- [ ] All project quality gates pass.
