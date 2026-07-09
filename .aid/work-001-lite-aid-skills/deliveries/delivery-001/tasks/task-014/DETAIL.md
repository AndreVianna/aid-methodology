# task-014: aid-fix family scaffold + halt proof

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-011, task-013

**Scope:**
- Add a canonical fixture test. `aid-fix` on a `vulnerability` description produces a flattened work with `### Security Specs` activated and `tasks/` `001` IMPLEMENT -> `002` TEST (exploit-closed), halting pre-Execute (FR-10). A `defect`-kind fixture asserts the base 2-task shape and that `aid-fix` stays bare (AC-4).
- This also serves as feature-003's engine smoke: a representative `verb x artifact` run produces the full flattened artifact set (REQUIREMENTS + SPEC + PLAN + tasks in the feature-001 shapes) and halts pre-Execute -- proving FR-3/FR-4/FR-6/FR-10 without executing.

**Acceptance Criteria:**
- [ ] vulnerability fixture: `### Security Specs` + `001` IMPLEMENT -> `002` TEST (exploit-closed); halts pre-Execute.
- [ ] defect fixture: base 2-task shape; `aid-fix` stays bare (AC-4).
- [ ] Doubles as the engine smoke: full flattened REQUIREMENTS/SPEC/PLAN/tasks produced, no execution (feature-003 engine-smoke).
- [ ] Test is deterministic with clean setup/teardown; covers feature-008 + feature-003 engine-smoke ACs.
- [ ] All §6 quality gates pass.
