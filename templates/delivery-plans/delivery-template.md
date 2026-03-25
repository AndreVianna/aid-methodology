# DELIVERY-{id}: {Name}

> **Status:** Not Started | In Progress | Testing | Complete
> **Source:** aid-plan (Phase 4) + aid-detail (Phase 5)
> **PLAN.md reference:** Deliverable {n}

---

## Summary

{One paragraph. What this delivery is, what it proves, and why it's a natural increment.}

---

## Scope

**User stories included:**
- US-{id}: {title}
- US-{id}: {title}

**Tasks included:**
- task-{id}: {title}
- task-{id}: {title}

**Out of scope (deferred to DELIVERY-{n+1}):**
- {feature or story deferred with reason}

---

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| DELIVERY-{id} must be complete | Predecessor | {Complete / In Progress} |
| {External dependency} | External | {status} |

---

## Success Criteria

> Measurable criteria for calling this delivery complete.

- [ ] All tasks complete with green build
- [ ] All unit tests pass
- [ ] All acceptance criteria in included user stories verified
- [ ] Integration tests pass
- [ ] TEST-REPORT.md verdict: PASS or PASS WITH NOTES
- [ ] {domain-specific criterion — e.g., "Grade A quality gate passes for all 3 brands"}
- [ ] KB updated with any new discoveries
- [ ] PR created and described

---

## Test Scenarios

> High-level scenarios that prove this delivery works. These drive the Test phase.

| ID | Scenario | Type | Expected Outcome |
|----|----------|------|-----------------|
| TS-{id}-01 | {description} | {Unit / Integration / E2E / Manual} | {expected result} |
| TS-{id}-02 | {description} | {type} | {expected result} |

---

## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| {risk description} | {High/Med/Low} | {High/Med/Low} | {mitigation action} |

---

## Completion Record

> Filled in when delivery is complete.

**Completed:** {date}
**Branch:** {branch name}
**PR:** #{pr number}
**Review grade:** {A+ through F}
**Test verdict:** {PASS / PASS WITH NOTES}
**Tasks completed:** {n}/{n}
**Tests added:** {n unit / n integration / n E2E}
