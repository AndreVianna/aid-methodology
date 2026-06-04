# task-011: Final work-level delivery gate (enum sweep, catalog count, validate loop, byte-identical render)

**Type:** TEST

**Source:** delivery-001 (all features) → delivery-001

**Depends on:** task-002, task-003, task-004, task-005, task-006, task-007, task-008, task-009, task-010

**Scope:**
- Run the work-level exit gate after every edit has landed, asserting the whole lite-path redesign is consistent:
  - **AC1 enum sweep = zero.** Context-aware sweep for `small-new-feature`, `small-refactor`, `single-doc` across all canonical files returns nothing (excluding `.claude/templates/reviewer-ledger-schema.md`, which is out of scope).
  - **No LITE-DOC survives** anywhere in the canonical tree or KB.
  - **Catalog count = 51.** `ls canonical/recipes/*.md | grep -v README | wc -l` = 51; the 4 renamed-away old names and `write-release-note.md` are gone.
  - **Naming-convention grep = 51.** Every recipe basename matches `^(add|change|fix|improve|bump|rename)-`.
  - **`--validate` loop clean.** The loop over all 51 recipes prints `OK: all checks passed` with no `WARN` for each.
  - **Smoke test green.** `bash tests/canonical/test-parse-recipe.sh` exits 0 and reports "Tests passed: 113" or more.
  - **Byte-identical render.** `/aid-generate` re-renders the canonical change to all 5 install trees (`antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`) byte-identical (deterministic verify passes).
- This is verification only — it makes no content edit; any failure routes back to the owning task.

**Acceptance Criteria:**
- [ ] The context-aware enum sweep returns zero hits (reviewer-ledger-schema.md excluded) and no `LITE-DOC` token survives.
- [ ] `ls canonical/recipes/*.md | grep -v README | wc -l` = 51 and the naming-convention grep = 51.
- [ ] The `--validate` loop reports `OK: all checks passed` with no `WARN` for all 51 recipes.
- [ ] `bash tests/canonical/test-parse-recipe.sh` exits 0 and reports "Tests passed: 113" or more.
- [ ] `/aid-generate` produces byte-identical recipes across all 5 install trees (deterministic verify passes).
- [ ] All §6 quality gates pass.
