# task-005: Migrate the 5 existing recipes (no loss) + retarget the smoke-test Units 15–19

**Type:** MIGRATE

**Source:** feature-003-recipe-catalog → delivery-001

**Depends on:** task-001

**Scope:**
- Migrate the 5 existing seed recipes to the new schema/naming convention with **no loss of capability** — each is a file rename + `name:` co-rename + `applies-to:` retarget + `summary:` addition, preserving every existing slot and task (`slot-count`/`task-count` invariant):
  - `method-refactor.md` → `change-member.md` (`name:` co-rename; `applies-to: small-refactor` → `refactor`; add `summary:`; 5 slots / 1 task unchanged).
  - `add-crud-endpoint.md` → `add-api-endpoint.md` (`name:` co-rename; `applies-to: small-new-feature` → `new-feature`; add `summary:`; matches the feature-003 SPEC exemplar; 6 slots / 3 tasks unchanged).
  - `bug-fix.md` → `fix-application.md` (`name:` co-rename; `applies-to:` **stays `bug-fix`** — workType value unchanged, only the recipe id renames; add `summary:`; 4 slots / 1 task unchanged).
  - `add-unit-test.md` → `add-test-coverage.md` (`name:` co-rename; `applies-to: "*"` stays quoted; add `summary:`; 4 slots / 1 task unchanged).
  - `write-release-note.md` → **split into** `add-docs.md` + `add-report.md` (two new files, both `applies-to: new-feature`, both carry `summary:`); **remove** the old `write-release-note.md`. Release-note capability folds into `add-docs` (its canonical example); `add-report` is its sibling.
- For each migrated/split recipe, update the in-body `**Source:**` metadata line and the `## Revision History` "Created from recipe `<id>`" cell from the old id to the new id (do NOT rename slot tokens).
- Update `tests/canonical/test-parse-recipe.sh` Units 15–19 recipe-filename references (SEED_FILE path, banner, ~lines 25–29 comment header, both `assert_*` strings) per the old→new map: Unit 15 `bug-fix.md`→`fix-application.md`; **Unit 16 `write-release-note.md`→`add-docs.md`** (old file removed by the split); Unit 17 `method-refactor.md`→`change-member.md`; Unit 18 `add-crud-endpoint.md`→`add-api-endpoint.md`; Unit 19 `add-unit-test.md`→`add-test-coverage.md`. Do NOT touch the enum-token fixtures at lines 145/205 (task-001).

**Acceptance Criteria:**
- [ ] `method-refactor.md`, `add-crud-endpoint.md`, `bug-fix.md`, `add-unit-test.md`, and `write-release-note.md` no longer exist; `change-member.md`, `add-api-endpoint.md`, `fix-application.md`, `add-test-coverage.md`, `add-docs.md`, and `add-report.md` exist.
- [ ] In every migrated file `name:` equals the new basename, `applies-to:` is on the 3-value enum (or quoted `"*"` for `add-test-coverage`), `fix-application` carries `applies-to: bug-fix`, and a `summary:` line is present; slot/task counts are unchanged from the source recipe.
- [ ] `bash canonical/scripts/interview/parse-recipe.sh --validate` prints `OK: all checks passed` with no `WARN` on each migrated/split recipe.
- [ ] `tests/canonical/test-parse-recipe.sh` Units 15–19 reference the new filenames (Unit 16 → `add-docs.md`); lines 145/205 are unchanged by this task.
- [ ] `bash tests/canonical/test-parse-recipe.sh` exits 0 and reports "Tests passed: 113" or more.
- [ ] All §6 quality gates pass.
