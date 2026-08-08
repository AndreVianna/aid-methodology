# Delivery BLUEPRINT -- delivery-017: Quote check and citation wiring

> **Delivery:** delivery-017
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Add the attributed-quote check and wire the citation lint where authoring happens, so a citation
defect is caught before a reviewer is dispatched rather than after a review cycle is paid for.

## Scope

- The attributed-quote check: a string presented as verbatim from a named file must appear in that
  file, with emphasis normalisation, which is mandatory -- without it the check's first two outputs
  on this repository's own specs are both false positives.
- The `aid-deep-review` RESOLVE gate, one site covering every definition skill plus `aid-review` plus
  the shortcut engine.
- The CI step: no workflow references the citation lint today, so this delivery adds it. (The KB claim that it already ran was corrected by delivery-002.)
- The gate rows in `quality-gates.md`, and the durable-citation convention in the authoring
  principles -- including that a quote which must survive the check should be a short fragment from
  a single source line.
- FR-G4's count-claim rule row in the Definition family file.

**Out of scope:** the count-claim re-runner; the table-cell and unattributed-prose citation forms,
which no regex reaches and which the deep reviewer covers instead.

## Gate Criteria

- [ ] A quote present in its source passes; one absent fails; one differing only in markdown
      emphasis passes -- the third is the assertion that keeps the check usable
- [ ] An unattributed quote is advisory and does not change the exit code, so the coverage boundary
      is reported rather than hidden
- [ ] The RESOLVE gate runs before any dispatch, and blocks it on exit 1
- [ ] The citation lint runs in CI
- [ ] AC-14 holds on fixtures failing in both directions
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-002, delivery-004, delivery-012
- **Blocks:** -- (none)

## Notes

**Spine delivery.** It extends the script delivery-002 ships, hence the dependency on it. The
convention it lands is the one this work learned the hard way: a long verbatim quotation drifts on
every hand-edit, so quote short and paraphrase openly.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The attributed-quote check |
| task-002 | CONFIGURE | 2 | RESOLVE gate and CI step |
| task-003 | DOCUMENT | 2 | Gate rows and the citation convention |
| task-004 | IMPLEMENT | 1 | The count-claim rule row |
