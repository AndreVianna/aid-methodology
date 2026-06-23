# task-020: lint scope-predicate widening + ASCII-guard wiring + AID-CI strict assertion

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-003

**Depends on:** task-003 (delivery-001), task-018

**Scope:**
- **Widen the lint's in-scope predicate (the SINGLE shipped-lint edit).** In
  `canonical/aid/scripts/kb/lint-frontmatter.sh` (the f001/task-001 script), change the in-scope
  predicate from `kb-category in {primary, extension} AND source: == hand-authored` to
  `kb-category in {primary, extension} AND source: != generated` -- so `host-tool-capabilities.md`
  (`source: promoted from work-local research (...)`) and any future promoted doc is covered ([SPIKE-M1]
  resolved: widen the predicate). **RETAIN the day-one pre-migration soft-skip clause** (the predicate
  that SKIPs a doc carrying NONE of `{objective,summary,sources,tags,see_also,owner,audience}`) --
  NFR-7, [SPIKE-M5] RESOLVED. Do NOT delete the soft-skip; do NOT change the required-field/shape
  checks or the `[FM-MISSING]`/`[FM-INVALID]` tags (f001). This is the ONLY change to the shipped
  lint -- AID's hardness comes from migrating its whole corpus (task-022), not from removing the
  soft-skip.
- **Wire the ASCII guard.** Add `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` to
  `tests/canonical/test-ascii-only.sh`'s `SHIPPED_SCRIPTS` allow-list (alongside the existing
  `migrate-work-hierarchy.sh`). Confirm the script's seeded literals are ASCII ([SPIKE-M6] -- the f002
  `[.!?]`/`[A-Z]`/`...` literals are ASCII, so the guard does not red CI).
- **Add the AID-CI-local strict assertion.** In `.github/workflows/test.yml` (the `kb-hygiene` job,
  AID-repo-local), add a strict check asserting every AID `primary`/`extension` KB doc carries the
  required fields (`objective`/`summary`/`sources`) -- guarding against an un-migrated doc sneaking
  into AID's repo (which the retained shipped soft-skip would silently pass). The `meta` and
  `source: generated` scope skips REMAIN. This is **AID-repo-specific, NOT a change to the shipped
  lint script**. It is enabled here but only becomes green once AID's corpus is migrated -- task-022
  performs the corpus migration + INDEX regen and lands it in the SAME commit/PR as this assertion so
  AID's CI never observes the strict check over un-migrated AID docs ([SPIKE-M3] order-of-operations).
- Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py` and
  commit the regenerated `profiles/` (the edited lint is canonical; its rendered copies must refresh --
  render-drift, [[render-drift-full-generator]]).
- **Boundary:** this task OWNS the lint scope-widen, the ASCII-guard wiring, and the AID-CI strict
  assertion. It does NOT author the schema / soft-skip clause / required-field+shape checks / `[FM-*]`
  tags (f001, task-001), the migration script (task-018), its test suite (task-019), the glossary
  content (task-021), or the dogfood corpus run + INDEX regen (task-022).

**Acceptance Criteria:**
- [ ] `lint-frontmatter.sh`'s in-scope predicate is `kb-category in {primary, extension} AND source:
  != generated`; `host-tool-capabilities.md` is now in scope; `meta` + `source: generated` docs stay
  out of scope.
- [ ] The pre-migration soft-skip clause is RETAINED verbatim (a doc carrying none of the new fields
  is still skipped); the required-field/shape checks and the `[FM-MISSING]`/`[FM-INVALID]` tags are
  unchanged -- the predicate widening is the only edit to the shipped lint.
- [ ] `migrate-kb-frontmatter.sh` is added to `test-ascii-only.sh`'s `SHIPPED_SCRIPTS`; the ASCII
  guard passes over the new script.
- [ ] `.github/workflows/test.yml` `kb-hygiene` job gains an AID-CI-local strict assertion that every
  AID `primary`/`extension` KB doc carries `objective`/`summary`/`sources`; it is NOT a change to the
  shipped lint; `meta` + `source: generated` remain skipped.
- [ ] Edit canonical only; `run_generator.py` re-run and regenerated `profiles/` committed
  (render-drift green); no rendered copy hand-edited.
- [ ] All section-6 quality gates pass.
