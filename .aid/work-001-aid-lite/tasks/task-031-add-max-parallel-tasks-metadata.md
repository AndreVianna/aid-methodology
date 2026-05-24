# task-031: Add `**Max Parallel Tasks:**` metadata to discovery-state-template + project STATE.md

**Type:** CONFIGURE

**Source:** feature-009-parallel-task-execution → delivery-005

**Depends on:** —

**Scope:**
- Add `**Max Parallel Tasks:** N` metadata line to `canonical/templates/discovery-state-template.md` top-of-file metadata block (same shape as `**Heartbeat Interval:**`).
- Add the same line to existing project `.aid/knowledge/STATE.md` with default value `5`.
- Generator re-renders the template into install trees.

**Acceptance Criteria:**
- [ ] `canonical/templates/discovery-state-template.md` has the new metadata line.
- [ ] Project `.aid/knowledge/STATE.md` has `**Max Parallel Tasks:** 5`.
- [ ] Generator re-renders template byte-identically into install trees.
- [ ] Existing tooling that reads STATE.md metadata continues to work (additive).
- [ ] Configuration is idempotent.
- [ ] All §6 quality gates pass.
