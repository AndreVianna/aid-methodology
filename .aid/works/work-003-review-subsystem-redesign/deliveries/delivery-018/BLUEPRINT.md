# Delivery BLUEPRINT -- delivery-018: BLUEPRINT and specify-section reviews

> **Delivery:** delivery-018
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Grade two artifacts that are currently read but never graded: the delivery BLUEPRINT, and each
section of a SPEC as it is written. The per-section review today uses a bare-word severity
vocabulary that the grading rubric itself names as producing a silent pass.

## Scope

- `BLUEPRINT.md` added to the artifact set of the four reviews that already run, with `## Tasks`
  out of scope at Plan and in scope at Detail.
- `aid-detail` made to write the BLUEPRINT Tasks table -- without it, grading the BLUEPRINT lands a
  guaranteed-failing gate. A parity fix: the Lite path already does this.
- The per-section specify review gains a screener dispatch, the shared ledger, a gap check and a
  `grade.sh` call, and loses the bare-word severities.
- Two stale claims in the blueprint template corrected.

**Out of scope:** restructuring the per-section loop; the loop stays, and the review stays inline
rather than becoming a terminal hand-off.

## Gate Criteria

- [ ] The BLUEPRINT appears in all four artifact sets
- [ ] `aid-detail` writes the Tasks table, so the new gate is passable
- [ ] `## Tasks` is out of scope at Plan and in scope at Detail
- [ ] The per-section review writes to the same ledger the final review grades, and calls
      `grade.sh` behind the gap gate
- [ ] The bare-word severity vocabulary no longer appears
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-012
- **Blocks:** delivery-022

## Notes

**Spine delivery**, and the only `Should` in the work. It was numbered last of the original 18, but
the five deliveries added 2026-08-09 are all `Must` and are numbered after it, and `delivery-022`
(a `Must`) depends on it -- so the "every `Must` precedes it" property no longer holds and is not
claimed. What holds instead: this delivery depends only on `delivery-012`, so it is free to run as
soon as 012 closes, in parallel with the five `Must` deliveries 022 also waits on. It **can** be the
last of the six to finish and so **can** be 022's binding constraint -- nothing rules that out --
but nothing in the graph *forces* it late, so the `Should` adds no critical-path length the `Must`
set does not already impose. It makes the per-section pass feed the single grade arithmetic
instead of running a private one.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | aid-detail writes the Tasks table |
| task-002 | CONFIGURE | 2 | Grade the BLUEPRINT |
| task-003 | IMPLEMENT | 1 | The per-section specify review |
