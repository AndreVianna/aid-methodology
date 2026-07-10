# task-002: Dual-format frontmatter read in both reader twins + tests

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-001

**Scope:**
- Update both reader twins — Python `dashboard/reader/*.py` (parsers.py, derivation.py,
  reader.py, models.py) and Node `dashboard/server/reader.mjs` — to read machine-parsed
  STATE fields from the frontmatter block **first**, falling back to the legacy prose
  parsers when frontmatter is absent (dual-format / back-compat tolerant read). Reuse the
  existing `parse_doc_frontmatter` / `parseDocFrontmatter` technique and the `SourceMode`
  (Normalized→Fallback→Mixed) machinery — no third-party YAML dependency introduced.
- **`SourceMode` is per-*work* today** (on `WorkModel`/`ParsedWork`, keyed off `## Pipeline
  State`); it is NOT wired to the KB path — `KbStateRef` has no `source_mode` and
  `parse_kb_state` never touches it. This task must **extend** SourceMode onto the KB surface
  (add the field + wire `parse_kb_state`/`_parse_kb_summary_approval`), not toggle an existing wire.
- **Honor the post-merge reader reality:** accept both section spellings `## Pipeline (State|Status)`,
  `## Tasks (State|Status)`, `## Features (State|Status)`, and the flat/Lite layout
  (`_detect_flat`, promoted `## Delivery Lifecycle` + `### Tasks lifecycle` + singular
  `## Delivery Gate`). The frontmatter fallback must degrade to whichever prose section name is present.
- **`parse_doc_frontmatter` is a per-KB-*doc* freshness tool today** (only callers in
  `derivation.py`; never run on STATE.md). Reuse the *algorithm*; there is no existing
  STATE.md→frontmatter path to hook. (The KB `STATE.md` already carries a frontmatter block with
  zero machine keys, so this is additive.)
- Route any new git-fed field (e.g. an approval/baseline commit-ish) through v2.1.0's hardened
  helpers (`--end-of-options` git calls, `read_bytes_bounded`); do not re-invent input handling.
- `dashboard/` is the reader's own source of truth (NOT under `canonical/`/`profiles/`); edit it
  directly. Vendoring to the packages + installed CLI is task-003.
- **Register any new reader module** (e.g. a `state_schema.py`) in `dashboard/MANIFEST` — or it
  silently won't vendor and `tests/canonical/test-dashboard-manifest.sh` goes red.
- Update/add reader unit tests and cross-twin parity tests (Python + Node) covering new-format,
  legacy-format, and mixed inputs; preserve twin byte-parity behavior. **Migrate the existing
  reader fixtures** (`pt1h-kb-approved`, `test_task064_kb_status.py`, `test_task066_kb_parity.py`)
  in THIS change, or the suite keeps passing against a form the product no longer emits.

**Acceptance Criteria:**
- [ ] Both twins read every machine-parsed field from frontmatter when present, and fall back to legacy prose when absent — verified by tests for all three input shapes (traces to BLUEPRINT gate criteria #1, #6).
- [ ] `SourceMode` is extended onto the KB path (`KbStateRef.source_mode` + wired parse); the KB-approval waterfall reads it (traces to gate criteria #3).
- [ ] The reader honors both `State|Status` section spellings and the flat/Lite layout (traces to gate criteria #4).
- [ ] Any new reader module is registered in `dashboard/MANIFEST`; `test-dashboard-manifest.sh` passes (traces to gate criteria #4, #8).
- [ ] Cross-twin parity test passes: Python and Node produce identical results for the same fixtures (traces to gate criteria #3).
- [ ] Reader fixtures (`pt1h-kb-approved`, `test_task064/066`) migrated in this change; new + existing reader/parity tests pass (traces to gate criteria #9).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
