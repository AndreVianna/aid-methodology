# task-036: Rename delivery + task definition templates to BLUEPRINT/DETAIL

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Rename `canonical/aid/templates/delivery-spec-template.md` -> `canonical/aid/templates/delivery-blueprint-template.md`: retitle the H1 and `[!NOTE]` from "Delivery SPEC" / "DELIVERY-LEVEL SPEC.md" to "Delivery BLUEPRINT" / "DELIVERY-LEVEL BLUEPRINT.md"; KEEP the `## Gate Criteria` section verbatim (this is `BLUEPRINT.md § GATE CRITERIA` — the delivery gate reads it); update its two internal task-def path references ("full SPEC.md at tasks/task-NNN/SPEC.md" and "detailed design belongs in task SPEC.md files") to `tasks/task-NNN/DETAIL.md`.
- Rename `canonical/aid/templates/task-spec-template.md` -> `canonical/aid/templates/task-detail-template.md`: retitle the H1 / `[!NOTE]` from "Task SPEC" / "TASK-LEVEL SPEC.md" to "Task DETAIL" / "TASK-LEVEL DETAIL.md"; the 6-section body (`**Type:** / **Source:** / **Depends on:** / **Scope:** / **Acceptance Criteria:**`) is byte-unchanged (schema stable; only filename + title move).
- Base-name decision (resolves the feature-015 design-note flag): KEEP the `delivery-`/`task-` scoping prefix — the files are `delivery-blueprint-template.md` and `task-detail-template.md` (not bare `blueprint-template.md`/`detail-template.md`); every downstream consumer path (tasks 037–041) matches these exact base-names.
- A-10 clean switch: no old-named template file retained, no alias, no duplicate.

**Acceptance Criteria:**
- [ ] `delivery-blueprint-template.md` exists and the old `delivery-spec-template.md` is gone; its H1/`[!NOTE]` read "Delivery BLUEPRINT" / "DELIVERY-LEVEL BLUEPRINT.md"; `## Gate Criteria` preserved; both internal task-def path refs point to `tasks/task-NNN/DETAIL.md` (FR-15/FR-16).
- [ ] `task-detail-template.md` exists and the old `task-spec-template.md` is gone; its H1/`[!NOTE]` read "Task DETAIL" / "TASK-LEVEL DETAIL.md"; the 6-section body is byte-unchanged (AC-15).
- [ ] No `delivery-spec-template.md` or `task-spec-template.md` remains anywhere under `canonical/` (grep-clean; A-10 no old path).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood `.claude/` byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
