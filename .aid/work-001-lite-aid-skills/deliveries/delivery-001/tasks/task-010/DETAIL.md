# task-010: Catalog-to-dirs parity test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-009, task-013

**Scope:**
- Add a canonical parity test (the render-drift analog for the generated dirs): every `shortcut-catalog.yml` row maps to exactly one `canonical/skills/<name>/SKILL.md` whose frontmatter `name` == dir == row `name` and carries the `aid-` prefix; no orphan dir, no orphan row.
- For thin-doorway rows, assert the body binds the row's `{verb, artifact}` and delegates to the engine; for `repurpose: true` rows, assert only dir-exists + name-match + `aid-` prefix (pre-existing fat skills).
- Scope in this delivery = the fix-family row(s) (`/aid-fix` name == its dir); the invariant is count-agnostic. The full 69-row count assertion lives in task-035.

**Acceptance Criteria:**
- [ ] Every catalog row maps to one skill dir (name == dir, `aid-` prefix); no orphans (AC-1 mechanical proof).
- [ ] Thin-doorway body binds `{verb, artifact}` + delegates to the engine; repurpose rows exempted to dir/name/prefix only.
- [ ] Passes for the fix-family rows; count-agnostic invariant.
- [ ] Test is deterministic with clean setup/teardown.
- [ ] All §6 quality gates pass.
