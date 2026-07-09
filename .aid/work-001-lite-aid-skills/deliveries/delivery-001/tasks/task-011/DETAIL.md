# task-011: Engine GATE + APPROVAL-HALT prose

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-008

**Scope:**
- Add the GATE + APPROVAL-HALT states to `canonical/aid/templates/shortcut-engine.md`. GATE runs TWO batched Grading-Gate passes: Pass 1 (REQUIREMENTS + SPEC + PLAN + the work-root `BLUEPRINT.md`) to `.aid/.temp/review-pending/shortcut-<work>-defn.md`; Pass 2 (every `tasks/task-NNN/DETAIL.md`) to `shortcut-<work>-tasks.md`. Each pass is a REVIEW -> GRADE -> FIX loop using the canonical 7-column ledger, `aid-reviewer` dispatched in clean context with an inline 5-section brief (per `reviewer-dispatch.md` One-off reviews -- no shared `reviewer-brief.md`), and `grade.sh`.
- Resolve the floor via `read-setting.sh --skill <shortcut> --key minimum_grade --default A+` (the shortcut path's built-in default is A+); loop until each document is >= A+.
- Record each cleared grade in the work-root `STATE.md` `## Lifecycle History` (append-only; distinct from the post-execution `## Delivery Gate`).
- APPROVAL-HALT: present the flattened work and STOP -- no branch, no execution; Pipeline State `Paused-Awaiting-Input`, `## Delivery Lifecycle` State `Specified`.
- Reuse `grade.sh`, `aid-reviewer`, `reviewer-ledger-schema.md`, `reviewer-dispatch.md`, `read-setting.sh` as-is (no new files).

**Acceptance Criteria:**
- [ ] GATE resolves minimum_grade via `read-setting.sh ... --default A+`, runs the two batched passes over the two named ledger scopes, and loops REVIEW->FIX until each document clears >= A+ (AC-11/FR-11).
- [ ] APPROVAL-HALT stops after Detail: no branch created, no task executes; Pipeline `Paused-Awaiting-Input`, Delivery Lifecycle `Specified` (AC-3/FR-10).
- [ ] Definition-phase grades recorded in the work-root `## Lifecycle History` (not the `## Delivery Gate`).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
