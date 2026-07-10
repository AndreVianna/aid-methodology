# task-009: build-shortcut-skills.py maintainer build helper

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-007, task-008

**Scope:**
- Create `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` (maintainer-only; NOT shipped, like `run_generator.py`): read `canonical/aid/templates/shortcut-catalog.yml`, emit/refresh the thin-doorway `canonical/skills/aid-<name>/SKILL.md` dirs. Each doorway carries minimal frontmatter (`name` == dir; `description` with the `State machine:` line delegating to the engine; `allowed-tools`; `argument-hint`) plus a body that binds the row's `{verb, artifact}` and delegates to `canonical/aid/templates/shortcut-engine.md`.
- SKIP `repurpose: true` rows (aid-deploy/aid-monitor are hand-authored fat skills -- never generate or overwrite those dirs).
- After any catalog edit the maintainer runs this helper then the FULL `run_generator.py` (never a partial render).

**Acceptance Criteria:**
- [ ] Running the helper generates a valid thin doorway per non-repurpose catalog row (name == dir, `aid-` prefix, binds `{verb, artifact}`, delegates to the engine).
- [ ] `repurpose: true` rows are skipped (no dir generated/overwritten).
- [ ] Lives under `.claude/skills/generate-profile/scripts/` (maintainer-only; not under `canonical/`, so it never ships).
- [ ] All existing tests still pass.
- [ ] All §6 quality gates pass.
