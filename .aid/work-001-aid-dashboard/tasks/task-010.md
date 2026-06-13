# task-010: feature-002 reader core — read_repo + Locator + Parsers (levels 0-3, normalized path)

**Type:** IMPLEMENT

**Source:** feature-002-state-reader-foundation → delivery-001

**Depends on:** task-001

**Scope:**
- Implement the read-only reader's public entry point `read_repo(aid_root) -> RepoModel` (feature-002 Feature Flow) — a single pure, idempotent filesystem pass; no write, no lock, no agent (NFR2/NFR7).
- LC-1 Locator: resolve the `.aid/` root, enumerate `work-NNN-*/` dirs (retention = folder persistence, FR12), stat the manifest + KB; structurally exclude `.aid/.temp/`/`.aid/.heartbeat/` (the work-glob is exactly `.aid/work-NNN-*/`).
- LC-2 Parsers (levels 0-3, normalized path): parse `.aid/.aid-manifest.json` (+`.aid/.aid-version`) → `ToolInfo` (DM-2); parse `.aid/settings.yml project.name` + stat `.aid/knowledge/` → `RepoInfo` + thin `KbStateRef` hook (DM-3); per work, read `STATE.md` once and parse the NORMALIZED `## Pipeline Status` block + typed `## Tasks Status` rows (skip `_none yet_`) + `## Cross-phase Q&A (Pending)` pending Q&A → `WorkModel`/`TaskModel`/`pending_inputs` (DM-4/DM-5); assemble `ReadMeta` (DM-7).
- Import the enum vocabularies from feature-001's `work-state-template.md` as the single source of truth (DM-6), plus the reader-only `Unknown`/`Phase` sentinels; never invent a parallel vocabulary.
- Implement once per runtime alongside its server (feature-003 LC-S) — but this task delivers the reader logic; the normalized derivation (SM-2 preferred path returns the `Lifecycle` literal verbatim) is included, the fallback adapter is task-011.

**Acceptance Criteria:**
- [ ] `read_repo(aid_root)` produces a normalized `RepoModel` covering levels 0-3 without modifying any file (NFR2); a zero-work repo returns `works=[]`; an absent `.aid/` returns an empty model + `parse_warning` (feature-002 AC1).
- [ ] Multiple work folders each appear as a `WorkModel`; retention follows folder persistence (FR12/AC2).
- [ ] The normalized path: when a work's `## Pipeline Status` block is present, its `Lifecycle` literal is returned verbatim with `source_mode=normalized`; the typed `Status` enum + `Unknown` sentinel are handled (DM-6); the `_none yet_` row is skipped.
- [ ] The reader is read-only by construction (no write/append/lock primitive in the module) and invokes no agent/LLM (NFR2/NFR7) — enforced by a self-check (the "no write primitive" assertion, finalized in task-012).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit tests for the new public functions (`read_repo`, locator, parsers) added (fixture suite is task-012); existing tests pass; build passes.
