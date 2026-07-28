# Delivery BLUEPRINT -- delivery-006: Ledger substrate

> **Delivery:** delivery-006
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Replace whole-file ledger rewrites with a surgical row-update helper, and extend the ledger to carry
three row kinds. This removes the truncation hazard where a reviewer re-emits every prior row on
each checkpoint, and cuts per-checkpoint output by 20-30x.

## Scope

- `canonical/aid/scripts/review/writeback-ledger.sh`: append-finding, append-unit, append-gap,
  set-status, get-status; script-assigned row IDs; the sentinel lock; CRLF and trailing-newline
  invariance; grade-verification default-on.
- Mechanical AC-3 enforcement: a finding row with no rule ID is rejected.
- The three row kinds (findings, `U-NNN` coverage, `G-NNN` gaps) in the schema, with the coverage
  row's `art=` and `rs=` digests.
- The schema and documentation migration, and the `aid-discover` merge rule excluding coverage and
  gap rows from the panel merge.

**Out of scope:** the actor half of the ledger lifecycle -- who updates Status (delivery-009); gap
semantics and routing (delivery-007).

## Gate Criteria

- [ ] Adding coverage and gap rows does not change the grade, nor the `--explain` breakdown, for the
      same findings (AC-9)
- [ ] A finding row with no rule ID is rejected
- [ ] `--set-status` leaves every other row byte-identical, and never renumbers
- [ ] `--append-gap` is idempotent on its key and increments a recurrence counter
- [ ] No heredoc ledger write survives anywhere in the tree
- [ ] Five-profile render parity re-verified, including that the new `review/` directory is emitted
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-005
- **Blocks:** delivery-007

## Notes

**Spine delivery.** Emission of the new `review/` script directory must be confirmed **by
rendering** -- the manifests were stale before delivery-001 fixed them, so the directory mapping
cannot be assumed live.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | writeback-ledger.sh |
| task-002 | IMPLEMENT | 2 | Three row kinds |
| task-003 | CONFIGURE | 2 | Emit the review/ script directory |
| task-004 | IMPLEMENT | 2 | AGENT.md: the write mechanism |
| task-005 | MIGRATE | 3 | Retire the heredoc write |
