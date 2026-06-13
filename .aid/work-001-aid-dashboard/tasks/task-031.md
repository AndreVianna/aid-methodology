# task-031: feature-007 reader extension LC-KR — populate rich KbModel

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-005

**Depends on:** task-013

**Scope:**
- Extend feature-002's read-only reader (LC-KR, both runtimes) to populate the rich `KbModel` at `model.repo.kb_state` (feature-007 DM-1), REPLACING the thin `KbStateRef` while RETAINING the three hook fields verbatim (`doc_count`, `summary_approved`, `last_summary_date`) so feature-006's KB card keeps working unchanged.
- KR-1: parse `.aid/knowledge/README.md ## Completeness` rows (`# | Document | Status | Last Reviewed | Notes`) → `docs[]` (`KbDoc`: name, category from the doc's own `kb-category:` frontmatter defaulting `primary`/null, literal `status`, `last_reviewed`, `notes`).
- KR-3: parse `.aid/knowledge/STATE.md ## Knowledge Summary Status` `**Field:**` lines → `summary` (`KbSummaryStatus`: approved/grades/dates/last-run/last-reviewed-KB). KR-4: stat `knowledge-summary.html` → `output_present`/`output_size`.
- KR-5: compute INDEX freshness via the cheap deterministic proxy (DD-3) → `index` (`KbIndexFreshness` fresh/stale/unknown): compare `### [name]` INDEX entries vs non-dot `*.md` under `.aid/knowledge/` (the `build-kb-index.sh` doc-selection rule) + per-doc intent-line when cheaply available; NO per-poll shell-out to `build-kb-index.sh` (NFR4); `null` absent KB.
- Stay inside the audited read-only / no-LLM reader; best-effort + null-tolerant (missing field → null + `parse_warning`, never throws, NFR7). Status read literally, never re-derived.

**Acceptance Criteria:**
- [ ] `model.repo.kb_state` is a `KbModel` (or `null` when no `.aid/knowledge/`) with the three hook fields retained verbatim and the `docs`/`index`/`summary` sub-objects populated (feature-007 DM-1).
- [ ] `docs[]` maps the README `## Completeness` rows literally (status copied verbatim, unknown literal tolerated); the summary panel fields parse from `STATE.md ## Knowledge Summary Status` best-effort (missing → null + `parse_warning`).
- [ ] INDEX freshness uses the cheap proxy (doc-set + intent-line), reports fresh/stale/unknown, and does NOT shell out to `build-kb-index.sh` per poll (NFR4; KI-007 subset-of-CI semantics).
- [ ] LC-KR adds only reads inside the read-only reader — the no-write self-check still holds and now covers LC-KR; no agent/LLM (NFR2/NFR7).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit tests for the new KB sub-parser public behavior added; existing reader tests pass; build passes (the `schema_version` bump + parity is task-034/036).
