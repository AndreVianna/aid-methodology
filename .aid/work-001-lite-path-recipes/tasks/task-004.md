# task-004: Fold the LITE-DOC sub-path out of the lite path

**Type:** REFACTOR

**Source:** feature-002-description-first-triage → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Remove the LITE-DOC sub-path (documentation work now folds into the add/change recipes under `new-feature` / `refactor`) across all consumers:
  - `canonical/skills/aid-interview/references/state-condensed-intake.md` — delete the LITE-DOC body (~lines 209–295), its slot row, and its unit case.
  - `canonical/skills/aid-interview/references/state-task-breakdown.md` — remove the LITE-DOC references at lines 53, 61, and 192.
  - `canonical/skills/aid-interview/SKILL.md:228` — reword to drop the LITE-DOC mention.
  - `canonical/templates/delivery-plans/work-state-template.md:19` — remove the LITE-DOC sub-path row.
  - `.aid/knowledge/schemas.md:181` — remove the orphaned LITE-DOC schema reference.
  - `.aid/knowledge/domain-glossary.md:146` and `:149` — remove the LITE-DOC terms.
- Serialized after task-002 because both edit `.aid/knowledge/domain-glossary.md` and `.aid/knowledge/schemas.md` (at different lines): task-002 owns the enum lines, task-004 owns the LITE-DOC lines.

**Acceptance Criteria:**
- [ ] No `LITE-DOC` token survives in state-condensed-intake.md, state-task-breakdown.md, SKILL.md, work-state-template.md, schemas.md, or domain-glossary.md.
- [ ] The LITE-DOC body, slot row, and unit case are removed from state-condensed-intake.md; no orphaned reference to them remains.
- [ ] The enum lines task-002 edited (schemas.md:180/369, domain-glossary.md:147/150/151) are unchanged by this task.
- [ ] `bash tests/canonical/test-parse-recipe.sh` exits 0 and reports "Tests passed: 113" or more.
- [ ] All §6 quality gates pass.
