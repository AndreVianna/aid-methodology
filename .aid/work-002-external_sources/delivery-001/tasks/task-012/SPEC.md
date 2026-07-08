# task-012: INDEX builder determinism and registry accessor tests

**Type:** TEST

**Source:** work-002-external_sources -> delivery-001

**Depends on:** task-005, task-001

**Scope:**
- Deterministic tests for task-005's INDEX builder: two runs over an identical descriptor set are byte-identical (no timestamp); zero descriptors yield a header-only `INDEX.md`; a row's `Secret Ref` is `—` when `auth_method: none`.
- Deterministic tests for task-001's accessor: `list` returns the descriptor stems excluding `INDEX.md` / `.gitignore` / `.secrets/`; `read <stem> <field>` returns the frontmatter value; a missing field / descriptor exits non-zero.

**Acceptance Criteria:**
- [ ] Tests are deterministic with clean setup/teardown over a fixture `.aid/connectors/` tree
- [ ] Byte-identity of the regenerated `INDEX.md` on unchanged input is asserted (the property feature-006 idempotence relies on)
- [ ] Accessor `list` / `read` behavior and its non-zero error paths are covered
- [ ] Covers the source-feature ACs (AC-5 machine-readable registry; AC-8 cross-platform)
- [ ] All §6 quality gates pass
