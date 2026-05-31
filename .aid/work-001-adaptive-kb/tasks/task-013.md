# task-013: Register delivery-002 (declared doc-set) in the KB + resolve H5

**Type:** DOCUMENT

**Source:** feature-004-declared-doc-set → delivery-002

**Depends on:** task-009, task-012

**Scope:**
- Update the authored KB docs to reflect the now-merged declared-doc-set mechanism (verify each claim against the edited canonical files):
  - `.aid/knowledge/architecture.md`: the discovery flow now resolves a declared doc-set and runs a propose→confirm step (Step 0d); the doc-set/count is no longer fixed (varies by project).
  - `.aid/knowledge/schemas.md`: the new `discovery.doc_set` shape in `.aid/settings.yml` (pipe-delimited `filename|owner|presence`, no-comma-in-fields constraint).
  - `.aid/knowledge/pipeline-contracts.md`: the `settings.yml` contract gains `discovery.doc_set`; the declared-set → dispatch contract (mapping honors the set).
  - `.aid/knowledge/domain-glossary.md`: new terms — "declared doc-set", "default seed set", "doc-set derivation (propose→confirm)".
  - `.aid/knowledge/test-landscape.md`: add the F4 canonical suites (read, mapping, propose-confirm); keep the count non-hardcoded.
  - `.aid/knowledge/coding-standards.md`: only if it documents settings/list conventions — note the pipe-delimited-list-in-settings convention.
  - `.aid/knowledge/tech-debt.md`: **mark H5 RESOLVED** — move it out of the open list to the changelog/resolved record (what/when/why), consistent with how prior items were closed.
- Regenerate `INDEX.md` via `build-kb-index.sh` + refresh generated KB indexes (refresh-all).

**Acceptance Criteria:**
- [ ] `architecture.md`, `schemas.md`, `pipeline-contracts.md`, `domain-glossary.md`, `test-landscape.md` accurately describe the declared-doc-set mechanism (verified against canonical).
- [ ] `tech-debt.md` shows H5 as RESOLVED (removed from the open inventory; closure recorded), and the open-item count/severity tallies updated.
- [ ] `INDEX.md` regenerated; generated KB indexes current; no stale "fixed 14/16 doc-set" claims remain anywhere in the KB.
- [ ] DOCUMENT default criterion: accuracy verified against the current (post-delivery-002) codebase.
