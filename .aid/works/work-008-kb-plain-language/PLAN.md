# Plan -- Plain-Language Knowledge Base Rewrite

> **Work:** work-008-kb-plain-language
> **Created:** 2026-08-11

---

## Deliverables

- **Delivery:** delivery-001 -- Plain-Language Knowledge Base Rewrite
- **What it delivers:** A Knowledge Base a junior professional can read, and a rule that keeps it
  that way. The 17 hand-authored primary and extension docs under `.aid/knowledge/` are reworded in
  plain language while every fact, contract, enum, table row, path, command, and citation they carry
  stays exactly as it was -- the knowledge does not move, only the wording. Alongside that, the
  plain-language expectation stops being advice: a new `kb-language-lint.sh` fails a doc that uses a
  coined term with no `domain-glossary.md` definition or whose `objective:`/`summary:` frontmatter
  breaks the readability bounds, and two named reviewer checks with stated severities cover the
  judgment residue no script can decide honestly.
- **Features:** feature-001-kb-plain-language   (the single feature; no `features/` folder)
- **Depends on:** -- (none)
- **Priority:** Must

---

## Execution Graph

<!-- Three orderings are forced by SPEC.md `#### Sequencing constraints` and are carried by the
     dependencies below: the enforcement mechanism (task-002 .. task-005) lands before any corpus
     rewrite; `domain-glossary.md` (task-006) settles the term set before the other 16 docs; the
     generated artifacts refresh last (task-014), and the whole-tree gate run is last of all
     (task-015). The six rewrite batches plus the authoring-conventions mirror are independent of
     each other once task-006 lands, so they share one wave. -->

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | -- (none) |
| task-002 | -- (none) |
| task-003 | task-002 |
| task-004 | task-002 |
| task-005 | task-002 |
| task-006 | task-001, task-004 |
| task-007 | task-006 |
| task-008 | task-006 |
| task-009 | task-006 |
| task-010 | task-006 |
| task-011 | task-006 |
| task-012 | task-006 |
| task-013 | task-004, task-006 |
| task-014 | task-005, task-007, task-008, task-009, task-010, task-011, task-012, task-013 |
| task-015 | task-003, task-014 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001, task-002 |
| 2 | task-003, task-004, task-005 |
| 3 | task-006 |
| 4 | task-007, task-008, task-009, task-010, task-011, task-012, task-013 |
| 5 | task-014 |
| 6 | task-015 |
