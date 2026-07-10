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
- **Surface the newly-captured fields + fix the pipeline label.** Read from the frontmatter:
  `pipeline.path` → `work_path` (stop inferring it via `_detect_flat`); `pipeline.initiator` →
  a display **kind** (map the shortcut skill → verb via `shortcut-catalog.yml`); plus new model
  fields for `started`, `minimum_grade`, work-level `user_approved`, and KB `kb_status`/`kb_grade`/
  `last_kb_review`/`last_summary`. Fix the dashboard label at `dashboard/home.html:1397` so the lite
  summary reads e.g. **"Lite path: Refactor → 8 Tasks"** (from `pipeline.initiator`) and **drops the
  redundant word** when the kind is unknown instead of printing "Lite". Retire the fragile `created`
  "Work created"-row scrape in favor of the `started` scalar.
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
- [ ] `work_path` is read from `pipeline.path` (not `_detect_flat`); `started`/`minimum_grade`/work-level `user_approved`/KB `kb_status`/`kb_grade`/`last_kb_review`/`last_summary` are exposed on the reader models (traces to gate criteria #13).
- [ ] The dashboard lite-path label renders the real kind from `pipeline.initiator` (e.g. "Lite path: Refactor → 8 Tasks") and drops the redundant word when unknown — "Lite path: Lite" no longer appears (traces to gate criteria #14).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
