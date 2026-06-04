# task-001: Collapse `applies-to` enum 4→3 and add `summary:` across recipe schema docs + test fixtures

**Type:** REFACTOR

**Source:** feature-001-taxonomy-and-recipe-schema → delivery-001

**Depends on:** — (none)

**Scope:**
- Replace the 4-value `applies-to` enum (`small-new-feature`, `small-refactor`, `single-doc`, `*` + `bug-fix`) with the 3-value enum `{ bug-fix, new-feature, refactor }` plus the `*` cross-type wildcard, and introduce the `summary:` front-matter field, across the recipe **schema docs**:
  - `canonical/recipes/README.md` — the YAML front-matter **field table**, the **valid-`applies-to`-values table**, and add the `summary:` field row/doc (the feature-001-owned line ranges, ~lines 48–80; do NOT touch the `## Seed Catalog` table at ~lines 24–38, which is task-010).
  - `canonical/templates/recipe-template.md` — make two edits: **(a)** in the **"Valid `applies-to` values" comment block (~lines 88–93)**, rename the enum tokens (`small-refactor` → `refactor`, `small-new-feature` → `new-feature`) and **delete the `single-doc` line** entirely, leaving exactly `bug-fix`, `new-feature`, `refactor`, and `*`; and **(b)** add the `summary:` field in field order (`name`, `applies-to`, `slot-count`, `task-count`, `summary`) to **both** the front-matter example **and** the YAML front-matter **fields table at ~lines 81–86** (per feature-001 SPEC line 120).
  - `canonical/templates/work-state-template.md:18` — the work-type/enum reference (drop `single-doc`; rename `small-refactor`→`refactor`, `small-new-feature`→`new-feature`; do NOT touch line 19's Sub-path enum, which is task-004).
- Update the **test fixtures** in `tests/canonical/test-parse-recipe.sh:145` and `:205` — both `small-new-feature` literals → `new-feature` (the enum-token fixtures feature-001 owns; this does NOT touch the Units 15–19 recipe-filename refs owned by task-005).

**Acceptance Criteria:**
- [ ] The `applies-to` valid-values documentation lists exactly `bug-fix`, `new-feature`, `refactor`, and `*` — no `small-new-feature`, `small-refactor`, or `single-doc` token remains in the **ranges this task edits** (README valid-values + field tables + T3→workType mapping + front-matter examples; recipe-template; work-state-template:18; test fixtures). The README `## Seed Catalog` tokens (~lines 24–38) are **task-010's** scope and are intentionally left for it; the work-level zero-token sweep is task-011's gate.
- [ ] The README field table and recipe-template both document a `summary:` field, placed last in front-matter order after `task-count`; in `canonical/templates/recipe-template.md` the `summary:` line is present in **both** the front-matter example **and** the fields table (~lines 81–86).
- [ ] A context-aware enum search over `canonical/templates/recipe-template.md` (the "Valid `applies-to` values" comment block and the front-matter example) returns **zero** old tokens (`small-refactor`, `small-new-feature`, `single-doc`), so task-011's AC1 sweep cannot fail on this file.
- [ ] `tests/canonical/test-parse-recipe.sh:145` and `:205` carry `new-feature` (not `small-new-feature`); no other line of that file is changed by this task.
- [ ] `work-state-template.md:18` references the 3-value enum.
- [ ] `bash tests/canonical/test-parse-recipe.sh` exits 0 and reports "Tests passed: 113" or more.
- [ ] All §6 quality gates pass.
