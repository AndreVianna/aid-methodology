# task-005: Deterministic connectors INDEX.md builder twin

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- New Bash+PowerShell twin under `canonical/aid/scripts/connectors/` that regenerates `.aid/connectors/INDEX.md` from descriptor frontmatter, implementing feature-001's frozen INDEX contract: columns `Connector | Type | Endpoint | Auth | Secret Ref | Summary`; its own `source: generated` / `generator:` / `intent:` / `contracts:` frontmatter; a single flat table (no KB grouping, no `../knowledge/` cross-links).
- Accepts `--root` / `--output` (the `build-kb-index.sh` shape) but is a SEPARATE script; emits NO run timestamp so regeneration on unchanged input is byte-identical (KI-010) — the property feature-006's idempotence relies on.
- On zero descriptors, emits a header-only `INDEX.md` (never deletes it) so the `@.aid/connectors/INDEX.md` context pointer never dangles.

**Acceptance Criteria:**
- [ ] Two builder runs over an identical descriptor set produce a byte-identical `INDEX.md` (no run timestamp)
- [ ] Output matches feature-001's INDEX contract (columns, own frontmatter, single flat table, `—` in Secret Ref when `auth_method: none`)
- [ ] Zero-descriptor input yields a header-only `INDEX.md`, not a deletion
- [ ] Both twins are behavior-equal; shipped PowerShell is WinPS-5.1-compatible and ASCII-only
- [ ] Unit tests cover the builder (including determinism + empty case); all existing tests still pass; build passes
- [ ] All §6 quality gates pass
