# task-030: End-to-end recipes TEST

**Type:** TEST

**Source:** feature-011-recipes → delivery-004

**Depends on:** task-024, task-026, task-027, task-028, task-029

**Scope:**
- Run `/aid-interview` against each of the 5 seed recipes (pick recipe + fill all slots + emit + verify).
- For each: verify work-root `SPEC.md` + tasks/task-NNN.md files emitted correctly with substituted slots.
- For each: verify `/aid-execute task-001 work-NNN` runs successfully against the emitted output.
- Verify escalation (recipe → standard-lite) preserves slot values.
- Verify `{!{` escape: write a recipe with literal `{!{example-slot}}` in the body; verify emitted output contains literal `{{example-slot}}`.
- Capture results in `.aid/work-001-aid-lite/test-reports/task-030-recipes-e2e.md`.

**Acceptance Criteria:**
- [ ] All 5 seed recipes successfully instantiated end-to-end (~30-60 seconds of user time each).
- [ ] Each emitted work passes /aid-execute task-001 dry-run.
- [ ] Escalation preserves all slot values + chains correctly to standard-lite path.
- [ ] `{!{` escape works as documented.
- [ ] All 6 ACs from feature-011 § Acceptance Criteria verified.
- [ ] Tests deterministic + clean setup/teardown.
- [ ] All §6 quality gates pass.
