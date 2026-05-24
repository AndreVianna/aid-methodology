# task-016: Implement 4 lite-path sub-paths in State L1 (CONDENSED-INTAKE)

**Type:** IMPLEMENT

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-014

**Scope:**
- Branch State L1 logic on `Sub-path` value read from `## Triage`.
- LITE-BUG-FIX: prompt for bug-title, bug-description, reproduction-steps, intended-behavior; emit work-root `SPEC.md` with reproduction + intended-behavior + task list only (no Specify-equivalent block).
- LITE-DOC: prompt for doc-title, doc-purpose, outline-bullets; emit single-task delivery with `SPEC.md` = document outline.
- LITE-REFACTOR: prompt for before/after sketch + scope + AC; emit standard lite-path SPEC.
- LITE-FEATURE: like LITE-REFACTOR + extra explicit AC elicitation slots.
- Each sub-path emits `tasks/task-NNN.md` files in the 6-section flat shape; per-task state via work `STATE.md ## Tasks Status` (per work-003 FR2).

**Acceptance Criteria:**
- [ ] Each of the 4 sub-paths produces execution-ready output: work-root `SPEC.md` + at least one `tasks/task-NNN.md`.
- [ ] Sub-path-specific SPEC shapes match the SPEC's Sub-path-table contract.
- [ ] No per-feature `SPEC.md`, no separate `PLAN.md`, no feature folders (lite shape).
- [ ] Emitted work-root `SPEC.md` + `tasks/task-NNN.md` files validate against the lite-path shape (correct sections, correct flat 6-section task shape). (End-to-end /aid-execute runnability is verified by task-018, not here.)
- [ ] Unit tests for each sub-path's prompt set + emission.
- [ ] All §6 quality gates pass.
