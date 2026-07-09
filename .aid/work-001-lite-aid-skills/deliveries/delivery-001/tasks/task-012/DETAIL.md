# task-012: Gate + halt + batching test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-011, task-013

**Scope:**
- Add a gate-integration test asserting the engine GATE resolves minimum_grade via `read-setting.sh --skill <shortcut> --key minimum_grade --default A+`, drives `grade.sh` over the two named ledger scopes, and loops REVIEW->FIX until >= A+ (reusing grade.sh's own unit tests for the computation).
- Halt proof: after both passes clear, the engine terminates at APPROVAL-HALT with no branch created and no task past `Pending`.
- Batching assertion: exactly two reviewer dispatches / two ledgers for a representative work (not one-per-document), while all four documents individually clear the floor.
- Use `/aid-fix` (task-013) as the representative work vehicle.

**Acceptance Criteria:**
- [ ] minimum_grade resolves to A+ via read-setting.sh; grade.sh drives the two ledger scopes; the loop clears >= A+.
- [ ] Halt proof: no branch, no task past Pending (FR-10/AC-3).
- [ ] Exactly two reviewer dispatches / two ledgers (A-7 batching); all four documents clear the floor (AC-11).
- [ ] Test is deterministic with clean setup/teardown; covers feature-004 ACs.
- [ ] All §6 quality gates pass.
