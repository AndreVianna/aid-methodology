# task-010: Update the catalog inventories (README Seed Catalog + KB Seed Catalog term)

**Type:** DOCUMENT

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-005, task-006, task-007, task-008, task-009

**Scope:**
- Replace the `canonical/recipes/README.md` `## Seed Catalog` section (~lines 24–38, currently a 5-row "ships five recipes" table) with a **51-recipe** inventory rendered as grouped sub-tables matching the four manifest groups (add/change pairs, bug-fix, refactor-only, cross-type), with a count header ("The catalog ships 51 recipes across 4 groups") and the reworded note that `add-test-coverage` is the single `*` cross-type recipe (replacing `add-unit-test`). Do NOT touch the YAML front-matter field table / valid-`applies-to`-values table / `summary:` field doc (~lines 48–80) — those are task-001's.
- Update `.aid/knowledge/domain-glossary.md:168` Seed Catalog term: replace the 5-file enumeration with the 51-recipe definition (4 groups: 40 add/change pairs across 11 target-kind families, 7 bug-fix, 3 refactor-only, 1 cross-type), pointing at `recipes/README.md` `## Seed Catalog`. Add a dated `changelog:` front-matter entry recording the catalog expansion to 51 (5 seed recipes migrated + 46 new names; 47 files newly created on disk).
- Do NOT touch the `workType` enum (line 147), `applies-to` term, `Recipe`/`Slot`/`Slot escape` terms, or LITE-* rows — those are task-002 / task-004.
- **[Scope correction — feature-002 inventory miss]** Rewrite the README `## How Recipes Are Discovered by \`/aid-interview\` Triage` section (~lines 331–394) from the OLD menu-based triage (T1 breadth / T2 size / T3 type + deterministic routing rule + auto-selected sub-path) to the **description-first** flow (free-form work description → agent infers work-type + best-matching recipe via `summary:` → single confirmation turn → conservative routing), consistent with `canonical/skills/aid-interview/references/state-triage.md`. Remove every `T1`/`T2`/`T3` menu reference and the eliminated `LITE-DOC` sub-path (incl. README ~line 346 and the line ~458 recipe-offer diagram); the recipe-offer/discovery mechanics (filter `applies-to == workType OR *`) stay. The surviving sub-paths are `{LITE-BUG-FIX, LITE-REFACTOR, LITE-FEATURE}`.
- **[Scope correction]** Update the README worked examples to migrated recipe names: the "Full Example (bug-fix recipe)" (~line 156) → `fix-application`; the "Multi-Task Example (add-crud-endpoint shape)" (~line 234) → `add-api-endpoint`. (Body content may stay illustrative; just the recipe-id labels/headers must not name a non-existent recipe.)

**Acceptance Criteria:**
- [ ] The README `## Seed Catalog` section reflects 51 recipes in four grouped sub-tables with a 51-count header; `add-test-coverage` is named as the single `*` cross-type recipe.
- [ ] The README field table / valid-`applies-to`-values table / `summary:` doc (task-001's ranges) are unchanged by this task.
- [ ] domain-glossary.md:168 Seed Catalog term states 51 recipes across the 4 groups and points at the README; a dated `changelog:` entry records the expansion.
- [ ] No old recipe basename (`bug-fix`, `method-refactor`, `add-crud-endpoint`, `add-unit-test`, `write-release-note`) appears as a current catalog entry, worked-example header, or triage example in README or glossary.
- [ ] The README triage section describes the description-first flow; `grep -nE '\bT[123]\b|LITE-DOC' canonical/recipes/README.md` returns ZERO (no old-menu or eliminated-sub-path tokens remain anywhere in README).
- [ ] All §6 quality gates pass.
