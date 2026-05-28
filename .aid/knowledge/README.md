# Knowledge Base — AID

> **Project:** AID — AI Integrated Development
> **Discovery cycle:** 1 (initial post-reset)
> **Last KB review:** 2026-05-27 (cycle-1 GENERATE)
> **Status:** 14 active KB documents (16 generated in cycle-1; 2 removed in Q3 FIX — security-model merged into coding-standards, ui-architecture deleted pending repo-presentation.md authoring in Phase B; 2 renamed: data-model → schemas, api-contracts → pipeline-contracts).

Read [`INDEX.md`](INDEX.md) first for a one-paragraph summary of each KB doc.

## Completeness

| # | Document | Status | Lines | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | [project-structure.md](project-structure.md) | Populated | 318 | 2026-05-27 | discovery-scout cycle-1 |
| 2 | [external-sources.md](external-sources.md) | Populated | 3 | 2026-05-27 | no external docs provided |
| 3 | [architecture.md](architecture.md) | Populated | 326 | 2026-05-27 | discovery-architect cycle-1 |
| 4 | [technology-stack.md](technology-stack.md) | Populated | 186 | 2026-05-27 | discovery-architect cycle-1 |
| 5 | [module-map.md](module-map.md) | Populated | 297 | 2026-05-27 | discovery-analyst cycle-1 |
| 6 | [coding-standards.md](coding-standards.md) | Populated | 457 | 2026-05-27 | discovery-analyst cycle-1 |
| 7 | [schemas.md](schemas.md) | Populated | 457 | 2026-05-27 | discovery-analyst cycle-1 (was data-model.md) |
| 8 | [pipeline-contracts.md](pipeline-contracts.md) | Populated | 566 | 2026-05-27 | discovery-integrator cycle-1 (was api-contracts.md) |
| 9 | [integration-map.md](integration-map.md) | Populated | 362 | 2026-05-27 | discovery-integrator cycle-1 |
| 10 | [domain-glossary.md](domain-glossary.md) | Populated | 353 | 2026-05-27 | discovery-integrator cycle-1 — 195 terms |
| 11 | [test-landscape.md](test-landscape.md) | Populated | 114 | 2026-05-27 | discovery-quality cycle-1 |
| 12 | ~~security-model.md~~ | Removed | — | 2026-05-27 | Content extracted to coding-standards.md §11 (Q3 FIX) |
| 13 | [tech-debt.md](tech-debt.md) | Populated | 255 | 2026-05-27 | discovery-quality cycle-1 — 1 Critical |
| 14 | [infrastructure.md](infrastructure.md) | Populated | 222 | 2026-05-27 | discovery-quality cycle-1 |
| 15 | ~~ui-architecture.md~~ | Removed | — | 2026-05-27 | Deleted in Q3 FIX; repo-presentation.md authored in Phase B |
| 16 | [feature-inventory.md](feature-inventory.md) | Template | 25 | 2026-05-27 | orchestrator template-copy; populated during Q&A→FIX |

**Meta-documents:**
- [STATE.md](STATE.md) — Discovery-area state ledger (Q&A, Review History, Calibration Log)
- [INDEX.md](INDEX.md) — Auto-generated per-doc summaries (regenerate via `bash .claude/scripts/kb/build-index.sh`)

## Revision History

| # | Date | Cycle | Action | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-27 | cycle-1 | GENERATE complete | All 16 KB docs populated post-`--reset`. Scout 11m17s + 4-parallel wave 14m29s (tail = analyst) = ~25m total. Next: REVIEW. |
