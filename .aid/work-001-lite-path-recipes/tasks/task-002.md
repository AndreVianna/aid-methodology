# task-002: Retarget old enum references across the Knowledge Base

**Type:** REFACTOR

**Source:** feature-001-taxonomy-and-recipe-schema → delivery-001

**Depends on:** task-001

**Scope:**
- Replace every old work-type/enum token (`small-new-feature`, `small-refactor`, `single-doc`) with the new 3-value enum (`bug-fix`, `new-feature`, `refactor`) across the Knowledge Base reference docs:
  - `.aid/knowledge/schemas.md:180` and `:369`.
  - `.aid/knowledge/pipeline-contracts.md:608`.
  - `.aid/knowledge/domain-glossary.md:147` (the `workType` enum term), `:150`, `:151`.
- Add a dated `changelog:` front-matter entry to each KB file edited (schemas.md, pipeline-contracts.md, domain-glossary.md) recording the work-001 feature-001 enum collapse 4→3.
- Do NOT touch the LITE-DOC sub-path rows or the Seed Catalog / Recipe terms — those are owned by task-004 / task-010 respectively.

**Acceptance Criteria:**
- [ ] No `small-new-feature`, `small-refactor`, or `single-doc` token remains at schemas.md:180/369, pipeline-contracts.md:608, or domain-glossary.md:147/150/151.
- [ ] The `workType` enum term in domain-glossary.md:147 lists exactly `bug-fix`, `new-feature`, `refactor`.
- [ ] Each of the three edited KB files carries a dated `changelog:` entry attributing the enum change to work-001 feature-001.
- [ ] No line owned by task-004 (LITE-DOC: domain-glossary.md:146/149, schemas.md:181) is modified by this task.
- [ ] All §6 quality gates pass.
