# Delivery BLUEPRINT -- delivery-008: Gap gate wiring

> **Delivery:** delivery-008
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make "no grade while a criteria gap is open" mechanical rather than conventional, at every place in
the tree that computes a grade. Scoped separately because it is the largest file count in its
feature and the smallest per-file change, and because its oracle is a tree-wide sweep.

## Scope

- `check-gaps.sh` inserted before every `grade.sh` invocation, at all 18 sites -- including the Lite
  path's shortcut engine, whose omission would let every shortcut skill grade over an open gap, and
  the two machine-validator sites whose call is a cheap exit-0 invariant.
- The prose grade call in `reviewer-ledger-schema.md` that the totality sweep does not see.

**Out of scope:** any change to `grade.sh` itself.

## Gate Criteria

- [ ] Every file invoking `grade.sh` mentions `check-gaps.sh` at an earlier line -- total over a
      mechanically derived file set, so a site added later fails automatically
- [ ] The gate fires on an open criteria gap and only on one: non-blocking and evidence gaps pass
- [ ] `grade.sh` is byte-unchanged (NFR-1)
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-007
- **Blocks:** delivery-015

## Notes

**Spine delivery.** The totality oracle is deliberately exclusion-list-free: it derives its file set
rather than enumerating it, so it keeps working as the tree changes.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | MIGRATE | 1 | Wire the gate at every grade site |
| task-002 | TEST | 2 | The totality oracle |
