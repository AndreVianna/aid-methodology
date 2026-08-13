# Delivery BLUEPRINT -- delivery-002: Populate -- the exceptions pass across the trees

> **Delivery:** delivery-002
> **Work:** work-004-frontmatter-review-criteria
> **Created:** 2026-08-13

---

## Objective

With the mechanism in place (delivery-001), walk the corpus and give each file its declaration only
where its type does not already cover it. This is an exceptions pass, not a population pass: most files
end with nothing, and that is the intended result. It is a distinct delivery because it can only run
once the schema, the type registry, and the readers exist -- and because deleting the dead READMEs and
correcting the stale KB declarations is the concrete payoff the mechanism was built to enable.

## Scope

Feature-002, all 7 technical-spec sections:

- Delete the 20 internal READMEs (`canonical/skills/*/README.md` + `canonical/agents/*/README.md`),
  **after** relocating the `aid-clerk` caller contract into `aid-clerk/AGENT.md` and fixing the
  `state-execute.md` pointer, and **after** removing all three `MONITOR_README` assertions
  (`DMR00c`/`DMR03c`/`DMR03d`) with the `aid-monitor` README.
- Walk the 290-file population; type each file; write a `review-criteria:` block **only** where a file
  has a criterion or exclusion its type does not cover.
- Correct the 8 in-scope `contracts: []` KB docs; verify the 8 that already declare; give
  `capability-inventory.md` and `release-tracking.md` their explicit dispositions.
- Perform the on-disk data rename of the 18 field-bearing KB docs and the 4 test fixtures.

**Out of scope:** authoring the schema/criteria lists or the readers (delivery-001); any render, dogfood
resync, guard retirement, or front-face edit (delivery-003).

## Gate Criteria

- [ ] The 20 READMEs are deleted, with the `aid-clerk` contract relocated and all 3 `aid-monitor` test
      assertions removed; no dangling pointer to a deleted README remains in a shipping file.
- [ ] Every one of the 290 files resolves to exactly one document type; none untyped; the three buckets
      sum to 290 (159 + 123 + 8).
- [ ] No authored `review-criteria:` block restates a global or type-level criterion; every authored
      entry is derivable from the repo alone (NFR-5).
- [ ] The 8 in-scope `contracts: []` docs declare real criteria or state why they have none; the 8 that
      declare are verified against disk.
- [ ] The on-disk rename touches only the 18 field-bearing KB docs (+ 4 fixtures); no KB doc gains the
      key in the drift sense.
- [ ] **AC-2 proof** passes in a disposable worktree for a file this delivery populated.
- [ ] No new mechanism added (C-1); no render performed (C-2).
- [ ] All section-6 quality gates pass.

## Tasks

*Defined by `/aid-detail`.*

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-003

## Notes

Delete before authoring -- never write a declaration into a file about to be removed. The derived trees
remain stale after this delivery; the single render is delivery-003.
