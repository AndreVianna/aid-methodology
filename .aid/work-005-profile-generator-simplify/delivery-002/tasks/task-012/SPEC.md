# task-012: Migration acceptance on old-layout fixtures (bash)

**Type:** TEST

**Source:** work-005-profile-generator-simplify -> delivery-002

**Depends on:** task-010, task-011

**Scope:**
- Extend `tests/canonical/test-aid-migrate.sh` with **old-layout fixtures** that reproduce a real pre-work-005 codex/cursor/antigravity install (NOT a fresh install):
  - codex `.agents/` + `.codex/agents/` split (the retired `.agents/skills` + `.codex/agents`),
  - `.cursor/rules/aid-*.mdc`,
  - `.agent/rules/aid-*.md`,
  - **user content** in each tree: a non-`aid-` file under `agents/`, a user `.cursor/rules/my.mdc`, and user lines outside the `AID:BEGIN/END` region of `AGENTS.md`.
- Run `aid update` against each fixture and assert (AC5 + AC8):
  - the retired AID trees (`.agents/`, `.cursor/rules/`, `.agent/rules/`) are **gone**,
  - the new `.codex/{agents,skills,aid}` layout is **present**,
  - **every user file is byte-identical** (the non-`aid-` file, `my.mdc`, the user lines of `AGENTS.md`),
  - `tools.*.version` are **uniform** (no mixed-version state).
- **HOME-pinning + escape canary are MANDATORY:** the migration scan defaults its root to `$HOME`, so the test MUST `export HOME=<throwaway>` (a temp dir, not the developer's real HOME) and assert an escape canary that the **real** HOME was untouched (snapshot the real HOME's `.aid` state before/after — never assume it is empty).
- This task covers the **bash** twin only (the canonical Linux suite). The PowerShell/Windows twin is task-013 (separate runner).
- Clean setup/teardown per fixture; deterministic (no network — use `--from-bundle` against a staged bundle).
- **Out of scope:** the engine/CLI implementation (task-009/010/011); the Windows PS twin assertions (task-013).

**Acceptance Criteria:**
- [ ] **AC5** and **AC8** are exercised on a real **OLD-layout** fixture (existing `.agents/` + `.cursor/rules/` + `.agent/rules/` install), not a fresh install.
- [ ] `HOME` is pinned to a throwaway dir for the migration run, AND an escape canary asserts the developer's real HOME was untouched.
- [ ] Post-`aid update`: retired AID trees are gone; the new `.codex/{agents,skills,aid}` is present.
- [ ] Every user file is byte-identical post-migration (non-`aid-` agent file, user `.cursor/rules/my.mdc`, user lines outside the `AID:BEGIN/END` region of `AGENTS.md`).
- [ ] `tools.*.version` are uniform after the migration (no mixed-version state).
- [ ] TEST defaults: tests are deterministic; clean setup/teardown; all acceptance criteria from feature-003 (AC5, AC8) covered.
- [ ] All §6 quality gates pass.
