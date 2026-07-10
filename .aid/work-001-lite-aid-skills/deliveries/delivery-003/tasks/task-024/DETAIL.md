# task-024: Document family scaffold test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-003

**Depends on:** task-023

**Scope:**
- Fixture: `aid-document-decision` produces a flattened work whose `tasks/task-001/DETAIL.md` is `DOCUMENT`-typed with a Scope requiring the Context -> Decision -> Alternatives -> Consequences ADR structure; halts pre-Execute (FR-10).
- Second fixture: `aid-document-runbook` asserts the trigger -> diagnostic -> remediation -> escalation shape -- proving the suffix selects the correct archetype.

**Acceptance Criteria:**
- [ ] document-decision -> DOCUMENT/ADR structure; document-runbook -> runbook structure; suffix selects the archetype (AC-1/AC-4); both halt pre-Execute.
- [ ] Test is deterministic with clean setup/teardown; covers feature-010 ACs.
- [ ] All §6 quality gates pass.
