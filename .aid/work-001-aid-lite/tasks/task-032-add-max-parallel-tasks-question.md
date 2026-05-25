# task-032: Add Max Parallel Tasks question to aid-init

**Type:** IMPLEMENT

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** task-004, task-031

**Scope:**
- Insert new question 'Max Parallel Tasks' into aid-init's question sequence, positioned between Q6 (Heartbeat Interval) and the current Q7 (Commit AID Workspace).
- The new question becomes Q7; the existing Q7 renumbers to Q8.
- Question UX: offer default `5`; accept any positive integer; reject 0 or negative.
- Persist user-supplied value to `.aid/knowledge/STATE.md` as `**Max Parallel Tasks:** N`.

**Acceptance Criteria:**
- [ ] aid-init asks Max Parallel Tasks between Heartbeat Interval and Commit AID Workspace.
- [ ] Default of 5 offered; accepts any positive integer.
- [ ] 0 / negative / non-integer values rejected with clear error; question re-asked.
- [ ] Chosen value persisted to STATE.md metadata.
- [ ] Re-running aid-init reads existing value and offers it as default (idempotent on re-init).
- [ ] Unit tests for the input validation + persistence.
- [ ] All §6 quality gates pass.
