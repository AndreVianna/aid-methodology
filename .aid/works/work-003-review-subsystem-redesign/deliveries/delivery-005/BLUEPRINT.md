# Delivery BLUEPRINT -- delivery-005: The eighth column

> **Delivery:** delivery-005
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Add the `Rule` column to the reviewer ledger and migrate every schema reference tree-wide, so a
finding can cite the rule it violates. Scoped separately because the migration is broad and shallow
while the schema change is narrow and deep, and because its blast radius across the rendered trees
is the largest in the work.

## Scope

- The `Rule` column added to the ledger schema: eight columns, the `--` sentinel for non-finding
  rows, and the mixed-shape rule.
- The tree-wide migration of every "7-column" reference, including the five `grade.sh` comment lines
  that feature-002 claims.
- `aid-reviewer/AGENT.md`: the `description:` frontmatter and the worked example.
- Five-profile render parity.

**Out of scope:** `grade.sh`'s counting logic -- byte-unchanged apart from comments (NFR-1); the
row-kind extension (delivery-006).

## Gate Criteria

- [ ] No "7-column" reference survives in the migration set
- [ ] Existing 7-column ledgers remain readable; the test fixtures that prove NFR-5 are unchanged
- [ ] `grade.sh`'s guard, reads and branches are byte-unchanged
- [ ] The schema states that a finding row MUST carry a rule ID, and names
      `writeback-ledger.sh` as the writer that enforces it -- both greppable assertions, since
      `grade.sh` cannot enforce it under NFR-1
- [ ] `git diff` on `AGENT.md` touches only this delivery's declared regions
- [ ] Five-profile render parity re-verified
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-004
- **Blocks:** delivery-006

## Notes

**Enabling, not standalone-functional** -- the column exists but nothing populates it until
delivery-006. Placed early in the spine deliberately: it has the biggest blast radius, so a stall
here costs less than a stall later.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The Rule column in the schema |
| task-002 | MIGRATE | 2 | Seven to eight, tree-wide |
| task-003 | IMPLEMENT | 2 | AGENT.md: eight columns |
| task-004 | TEST | 3 | Column gates and NFR-5 |
