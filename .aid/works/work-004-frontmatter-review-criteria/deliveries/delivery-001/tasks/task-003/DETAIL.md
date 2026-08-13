# task-003: Severity reconciliation to a single authority

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** task-002

**Scope:**
- Make `canonical/aid/templates/grading-rubric.md § Issue Severities` the single severity authority.
- Rewrite the two independent definitions to **cite** it rather than restate the five levels:
  `canonical/agents/aid-reviewer/AGENT.md § Severity Classification` and
  `canonical/aid/templates/reviewer-ledger-schema.md § Severity values`.
- Record, in `authoring-conventions.md`'s level-2 tables, that per-type severity (what a kind costs in a
  class of document) lives beside its criterion (C3), while the letter-grade machinery stays in
  `grading-rubric.md` / `quality-gates.md` (C6).

**Acceptance Criteria:**
- [ ] Exactly one severity definition remains (in `grading-rubric.md`); the other two surfaces cite it,
      adding no fourth definition.
- [ ] No per-type severity is duplicated between `authoring-conventions.md` (C3) and
      `quality-gates.md`/`grading-rubric.md` (C6); they cross-reference.
- [ ] Additive/localized (NFR-3); no new mechanism (C-1). All §6 quality gates pass.
