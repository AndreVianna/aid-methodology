# task-012: feature-002 reader tests against fixture repos

**Type:** TEST

**Source:** feature-002-state-reader-foundation → delivery-001

**Depends on:** task-011

**Scope:**
- Build checked-in fixture `.aid/` repos and a test suite (lives in `tests/` alongside the reader, feature-002 / feature-003 PT-1 test-landscape) exercising `read_repo` end to end.
- Fixtures cover: a `Running` work with parallel tasks (multiple waves), a `Paused-Awaiting-Input` (pending Q&A), a `Blocked` with a flat IMPEDIMENT, a `Completed`, a fallback-`source_mode` work (no `## Pipeline Status` block), a normalized work (block present), and an empty/no-`.aid/` case.
- Assert: exactly one lifecycle per work (FR16); enumeration = retention (FR12); `_none yet_` skipped → empty `tasks`; `source_mode` recorded correctly; `fallback_works` populated; `parse_warnings` on a malformed/torn STATE.md without aborting the pass.
- Add the read-only self-check: assert the reader module contains no write/append/lock primitive and no agent/LLM import (NFR2/NFR7, feature-002 LC-R self-check pattern).
- Deterministic, clean setup/teardown (fixtures are read-only inputs).

**Acceptance Criteria:**
- [ ] Each fixture work derives exactly one lifecycle matching its intended state (FR16/AC3), via both the normalized and fallback paths.
- [ ] The self-check asserts the reader has no write primitive and no agent/LLM call path (NFR2/NFR7) — enforceable in CI, not just prose.
- [ ] `source_mode`/`fallback_works`/`parse_warnings`/`bytes_read` are asserted; a malformed STATE.md yields a `parse_warning` + best-effort `WorkModel` and never aborts the pass (feature-002 AC1/AC4).
- [ ] The suite covers feature-002 AC1-AC4 (levels 1-3 + level-0 hook, retention, single-lifecycle, fallback tracking).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean per-case setup/teardown and cover the source ACs; run green under `tests/run-all.sh`; build passes.
