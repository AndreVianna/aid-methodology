# task-017: Change+Refactor family -- catalog rows + change-refactor.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-015

**Scope:**
- Add 25 rows to `canonical/aid/templates/shortcut-catalog.yml`: 13 canonical (`aid-change` bare + 11 artifact suffixes + `aid-refactor` bare) + 12 `aid-update-*` aliases (`alias_of` the change mirror; `update` == `change`). `aid-refactor` is bare with NO alias and no artifact suffixes. default_type: change mirrors create (`config -> CONFIGURE`, `data-model -> MIGRATE`, rest IMPLEMENT); `refactor -> REFACTOR`.
- Create `canonical/aid/templates/shortcut-scaffolding/change-refactor.md`: change inherits `create.md`'s per-artifact task chains (same count/types, modify-framed) + change-specific CAPTURE (current shape/behavior, target, the new acceptance criteria, rationale); refactor CAPTURE + templates (rename -> single REFACTOR; restructure -> REFACTOR + TEST; performance -> REFACTOR + TEST with measured baseline/target). Do not duplicate the artifact matrix; defer artifact specifics to `create.md`.
- Generate the 25 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 25 rows/dirs added (13 canonical + 12 aid-update); `aid-refactor` bare (no alias/suffix); aid-change per-artifact mapping mirrors create (AC-1 G5 subset; AC-4 refactor-bare).
- [ ] `change-refactor.md` inherits create.md's artifact chains modify-framed + the refactor rename/restructure/performance templates.
- [ ] Aliases carry the same `{verb=change, artifact}` binding as their mirror.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
