# Delivery BLUEPRINT -- delivery-007: Criteria-gap interrupt

> **Delivery:** delivery-007
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make "there is no rule to judge this by" an expressible, actionable outcome of a review instead of
an invitation to invent a criterion. The reviewer records a gap, the calling skill asks once, and
the answer is durable so a refusal is never re-asked.

## Scope

- `check-gaps.sh` (the pre-grade gate) and `gap-register.sh` (promote, resolved-keys, depth), split
  because a linter and a state writer cannot share one exit-code alphabet.
- The `## Criteria Gaps` register in the work and discovery state templates, plus the companion
  `Impact: Required` Q&A entry for KB scope.
- Type 1 / Type 2 findings and the three `[GAP:*]` discriminators.
- Routing (canon vs one-time), the batched ask, restricted mode and the depth limit of 2.
- The greenfield criteria-versus-evidence split -- one behavioural change only.
- Retirement of the inline-check-enumeration licence and of the interim `OOS` rule-citation
  exemption.

**Out of scope:** the 18-site gate wiring (delivery-008).

## Gate Criteria

- [ ] An artifact whose standard is undefined produces a Type 2 gap and no invented finding (AC-4)
- [ ] An ungrounded finding is unwritable at every status
- [ ] A "no" answer is recorded durably and a re-run does not re-ask (AC-5)
- [ ] The register survives the halt: neither register file is gitignored
- [ ] The same gap twice raises a loop flag, and a still-pending gap re-raised does not (AC-10)
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-006
- **Blocks:** delivery-008, delivery-009, delivery-021

## Notes

**Spine delivery.** The halt is `PAUSE-FOR-USER-ACTION`, an existing advance type -- no new
state-machine pattern is introduced.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The gap register |
| task-002 | IMPLEMENT | 2 | gap-register.sh |
| task-003 | IMPLEMENT | 2 | check-gaps.sh |
| task-004 | IMPLEMENT | 3 | Gap semantics and routing |
| task-005 | IMPLEMENT | 3 | AGENT.md: the gap outcome |
