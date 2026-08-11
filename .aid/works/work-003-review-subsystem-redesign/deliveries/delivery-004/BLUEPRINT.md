# Delivery BLUEPRINT -- delivery-004: Rubric catalog

> **Delivery:** delivery-004
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Give the reviewer a per-artifact-class rule set so severity becomes a lookup against a declared
rule rather than a judgment call. This is what makes the canonical scale usable rather than merely
consistent.

## Scope

- The catalog skeleton: `review-rubrics/INDEX.md`, the rule-row schema, the Rule ID format, the nine
  artifact classes, the six families, and the routing table.
- The per-class rule sets, including the `SUMMARY` class with its content-truth rows (required by
  feature-007's amendment) and the `Definition` family file that carries FR-G4's count-claim rule.
- The content-isolation rule relocation, and the retirement of the phantom `content-isolation.md`
  citation.
- `aid-reviewer/AGENT.md`: the standing KB-convention checks section removed; the source-tag mandate
  replaced by the rule-ID requirement.

**Out of scope:** the eighth ledger column (delivery-005); the checklists absorbed from the retired
`reviewer-guide.md` arrive with delivery-014's feature.

## Gate Criteria

- [ ] Every artifact class routes to exactly one rule set
- [ ] Every rule row carries an evidence anchor, a severity anchor and a named tag
- [ ] Every rule's `Criterion` resolves: the cited file exists and the quoted anchor is greppable
- [ ] `review-rubrics/summary.md` carries content-truth rows, not only Presentation-family rows
- [ ] `git diff` on `AGENT.md` touches only this delivery's declared regions
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-003
- **Blocks:** delivery-005, delivery-014, delivery-015, delivery-016, delivery-017, delivery-019, delivery-028

## Notes

**Spine delivery.** The widest fan-out in the work -- **six** later deliveries name it directly
(005, 014, 015, 016, 017, 019), by the `Blocks` field above and `PLAN.md § Dependency graph`.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | Catalog skeleton and routing |
| task-002 | IMPLEMENT | 2 | Per-class rule sets |
| task-003 | REFACTOR | 3 | Relocate the content-isolation rule |
| task-004 | IMPLEMENT | 3 | AGENT.md: cite a rule, not a source tag |
| task-005 | TEST | 3 | Catalog integrity suite |
