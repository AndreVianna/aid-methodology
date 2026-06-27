# Task State -- task-081

> **Task:** task-081
> **Delivery:** delivery-014
> **Work:** work-001-kb-skills-improvement

---

## Task State

- **State:** Done
- **Review:** Pending
- **Elapsed:** ~40m
- **Notes:** |
  Implementation complete. Files changed:
  - `canonical/aid/scripts/kb/kb-actback-task.sh` -- replaced `_doc_expects_class` with
    `_dim_owns_class` (dimension-keyed, single-sourced from concern-model.md owning-table);
    added `_dim_of_filename` resolver (sourced from domain-doc-matrix.md, covers all 8
    curated domains, 57 filenames); replaced filename-profile task selector with
    dimension-aware C9-seeded selector (priority C5->C2->C3->C9); updated `_run_check`
    to call dimension resolver + `_dim_owns_class` per doc.
  - `canonical/aid/templates/kb-authoring/concern-model.md` -- added
    "Owning-table restated in spine-dimension terms" subsection (the single-source table
    the script encodes, with MUST-NOT-edit-independently note).
  - `canonical/skills/aid-discover/references/doc-set-resolve.md` -- added "Dimension
    recovery" subsection: TSV stays 3-field; dimension recovered via `_dim_of_filename`;
    unknown/custom filenames -> "" safe degradation.
  - `canonical/skills/aid-discover/references/reviewer-prompt-actback.md` -- four-class
    table updated to reference spine dimensions (C1/C4->Invariants; C2->all three;
    C3->Conventions; C5->Conventions/Contracts; C7->Gotchas).
  - `tests/canonical/test-actback-task.sh` -- updated AT04 body text to C3-seeded
    "Make a change that must follow the project's conventions."; AT05 to C9-seeded
    "Add a new capability of the kind catalogued in feature-inventory.md."; AT06 to
    "Add a new entry point to the project." (all 28 tests pass).
  Software-seed delta (6 new rows on empty KB): project-structure.md|Invariants;
  module-map.md|Contracts; pipeline-contracts.md|Invariants; integration-map.md|Conventions;
  integration-map.md|Invariants; schemas.md|Conventions. Task shape stays `contract`.
  Off-software sanity (data-ml): task=contract (data-schemas.md C5), never "endpoint".
  Off-software sanity (design): task=contract (design-tokens.md C5), never "endpoint".
  Also fixed `tests/canonical/fixtures/kb-essence/actback/actback-pass-kb/knowledge/schemas.md`
  by adding `## Conventions` section (C5 owns Conventions per D-013/concern-model.md;
  the pass-kb must be fully sufficient under the new owning-table).
  Actback-task 28/0; actback-fixtures 14/0.
  Build: VERIFY pass; DBI 557/0; ASCII pass; SD13 159/0.

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** _none yet_

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
