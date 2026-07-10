# task-027: aid-triage router skill

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-007

**Scope:**
- Create `canonical/skills/aid-triage/` -- a standalone router (NOT one of the 45 shortcut skills; it carries NO `shortcut-catalog.yml` row; it reads the catalog): `SKILL.md` (frontmatter `name: aid-triage`; `description` with `State machine: INTAKE -> CLASSIFY -> SUGGEST -> HALT`; `allowed-tools: Read, Glob, Grep` -- no Write/Edit; `argument-hint`), `references/state-classify.md` (workType heuristic + `shortcut-catalog.yml` `{verb, artifact}`+`intent` match), `references/state-suggest.md` (reflect-back straw-man + `[1]/[2]/[3]` menu).
- EXTRACT the reflect-back turn (`state-triage.md` Step 3) and the workType heuristic (`state-triage.md` Step 2a) BEFORE feature-002 (task-030) deletes `state-triage.md`; rewrite the recipe-match half to a catalog-`intent` match. Broad/ambiguous -> `/aid-describe`; suggest canonical `name` only (never an `alias_of`).
- Suggest-only: no interview, no scaffold, no work folder, no STATE.md (FR-13).

**Acceptance Criteria:**
- [ ] `aid-triage` created (SKILL.md + state-classify.md + state-suggest.md); INTAKE->CLASSIFY->SUGGEST->HALT; reads `shortcut-catalog.yml`; suggests the correct entry (matching shortcut or `/aid-describe` for broad/ambiguous) (AC-13/FR-13).
- [ ] Suggest-only: `allowed-tools` excludes Write/Edit; no work folder/STATE created (FR-13).
- [ ] Reflect-back turn + workType heuristic extracted from `state-triage.md` before its deletion (AC-10 routing relocated).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
