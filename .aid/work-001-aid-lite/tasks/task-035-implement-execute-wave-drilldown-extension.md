# task-035: Implement EXECUTE-WAVE drill-down extension for pool model

**Type:** IMPLEMENT

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-033

**Scope:**
- Extend the existing EXECUTE-WAVE sub-unit drill-down (introduced by FR1 / work-003 feature-001 AC4) to render pool state.
- Reuse existing icon vocabulary verbatim: `✓ done`, `● running`, `✗ failed`, `(queued)`.
- Supplement with `⊘ blocked` for tasks downstream of a Failed ancestor.
- Add a single counts summary line: `done / in-flight / queued / blocked / failed`.
- FR1's `▶/✓` bracket pairs continue to mark each per-task dispatch + completion.

**Acceptance Criteria:**
- [ ] Drill-down shows one `● running` row per in-flight task (up to MaxConcurrent).
- [ ] Drill-down shows `(queued)` for ready tasks waiting for a slot.
- [ ] Drill-down shows `⊘ blocked` for tasks downstream of a Failed ancestor.
- [ ] Counts summary line accurate and updated on every completion event.
- [ ] Existing FR1 icon vocabulary preserved (no glyph replacement; only `⊘` is new).
- [ ] Manual verification with a 5-task delivery: icons render correctly in the terminal.
- [ ] Unit tests for the snapshot generator with synthetic pool states.
- [ ] All §6 quality gates pass.
