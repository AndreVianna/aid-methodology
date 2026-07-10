# task-015: Create family -- catalog rows + create.md scaffolding

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-002

**Depends on:** task-008, task-009

**Scope:**
- Add 24 rows to `canonical/aid/templates/shortcut-catalog.yml`: 12 canonical `aid-create[-artifact]` (bare + api, ui, theme, cli, data-model, data-pipeline, messaging, integration, job, config, infra) + 12 `aid-add-*` aliases (`alias_of` the create mirror; `add` == `create`). default_type: IMPLEMENT for all except `config -> CONFIGURE` and `data-model -> MIGRATE`.
- Create `canonical/aid/templates/shortcut-scaffolding/create.md`: per-artifact SPEC-section activation + minimal CAPTURE slots + task-breakdown chains per the feature-006 matrix (api = IMPLEMENT + IMPLEMENT + TEST; data-model = MIGRATE + IMPLEMENT + TEST; ui/cli/messaging/integration/job/data-pipeline = IMPLEMENT + TEST; theme/infra/bare = single IMPLEMENT; config = single CONFIGURE).
- Generate the 24 skill dirs via `build-shortcut-skills.py`.

**Acceptance Criteria:**
- [ ] 24 rows added (12 create + 12 aid-add aliases) and 24 dirs generated (name == dir, `aid-` prefix, delegate to engine); `config -> CONFIGURE`, `data-model -> MIGRATE`, rest IMPLEMENT (AC-1 G4 subset).
- [ ] `create.md` defines each artifact's SPEC activation + CAPTURE + task chain per feature-006 (AC-4 create-expansion).
- [ ] Aliases carry the same `{verb=create, artifact}` binding as their canonical mirror.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
