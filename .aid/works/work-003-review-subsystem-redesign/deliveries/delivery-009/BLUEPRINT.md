# Delivery BLUEPRINT -- delivery-009: Review resume

> **Delivery:** delivery-009
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make an interrupted review resumable, and move status reconciliation off the reviewer. Today two
documents tell a cycle-N reviewer to read the prior ledger and update Status while a third forbids
exactly that -- and in the one skill that already uses scratch ledgers, the input is deleted before
it is read. This delivery is the repair.

## Scope

- The per-attempt scratch ledger versus the durable canonical ledger; the two modes (resume vs new
  cycle) selected by one `test -f`.
- Orchestrator-owned reconciliation, joining scratch to canonical on `(Doc, Rule)`, with the
  coverage guard that distinguishes "examined and not found" from "never reached".
- `plan-resume.sh` and `--list-units`; invalidation on artifact or rule-set digest change.
- The three interruption types, including generalising the stop signal to non-task reviews.
- The inherited ledger-schema lifecycle rewrite, discharged as an explicit acceptance criterion.

**Out of scope:** the two review skills themselves (delivery-012).

## Gate Criteria

- [ ] A resumed review re-examines no `Examined` unit and skips no `Unexamined` one -- asserted as a
      partition, so it fails in both directions (AC-6)
- [ ] A review killed mid-unit re-examines only the interrupted unit (AC-7)
- [ ] A criterion change invalidates exactly the affected units, with a negative control proving it
      does not invalidate on any filesystem change (AC-8)
- [ ] Resume never moves the grade: the `--explain` breakdown is byte-identical before and after
- [ ] The orphaned lifecycle strings no longer survive in the schema, checked by content anchor
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-007
- **Blocks:** delivery-011, delivery-012, delivery-020, delivery-026

## Notes

**Spine delivery.** It discharges a debt feature-003 handed over in writing; the orphan-recurrence
check is a grep for surviving strings, not line numbers.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | plan-resume.sh and --list-units |
| task-002 | IMPLEMENT | 2 | Scratch ledgers and the two modes |
| task-003 | IMPLEMENT | 2 | AGENT.md and README: cycles and resume |
| task-004 | IMPLEMENT | 1 | Generalise the stop signal |
| task-005 | MIGRATE | 3 | The FR-D5 migration |
| task-006 | TEST | 4 | The resume oracle |
