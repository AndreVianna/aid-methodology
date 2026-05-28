---
kb-category: meta
source: hand-authored
intent: |
  Knowledge Base completeness tracking + per-doc status + revision history
  for the AID project. Updated after every /aid-discover cycle to reflect
  current disk state. Not part of the reviewed knowledge surface (kb-category: meta).
contracts: []
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-2 FIX Phase B (Q22)
---

# Knowledge Base — AID

> **Project:** AID — AI Integrated Development
> **Discovery cycle:** 6 (post-FIX, awaiting cycle-7 REVIEW)
> **Last KB review:** 2026-05-28 (cycle-6 REVIEW complete)
> **Status:** 15 active KB documents (16 originally generated in cycle-1; 2 deleted in Q3 FIX — `security-model.md` merged into `coding-standards.md §11`, `ui-architecture.md` replaced by `repo-presentation.md` per Q3 user-decision; 2 renamed: `data-model.md → schemas.md`, `api-contracts.md → pipeline-contracts.md`).

Read [`INDEX.md`](INDEX.md) first for a one-paragraph summary of each KB doc.

## Completeness

| # | Document | Status | Lines | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | [project-structure.md](project-structure.md) | Populated | 328 | 2026-05-27 | discovery-scout cycle-1; FM added Phase B |
| 2 | [external-sources.md](external-sources.md) | Populated | 15 | 2026-05-27 | no external docs provided; FM added Phase B |
| 3 | [architecture.md](architecture.md) | Populated | 333 | 2026-05-27 | discovery-architect cycle-1; FM added Phase B |
| 4 | [technology-stack.md](technology-stack.md) | Populated | 203 | 2026-05-27 | discovery-architect cycle-1; FM added Phase B |
| 5 | [module-map.md](module-map.md) | Populated | 291 | 2026-05-27 | discovery-analyst cycle-1; FM since GENERATE |
| 6 | [coding-standards.md](coding-standards.md) | Populated | 563 | 2026-05-27 | discovery-analyst cycle-1; +87 lines in FIX Phase A/B (§11 Security-By-Design + §12 Q&A Schema) |
| 7 | [schemas.md](schemas.md) | Populated | 457 | 2026-05-27 | discovery-analyst cycle-1 (renamed from `data-model.md` in Q3 FIX); FM since GENERATE |
| 8 | [pipeline-contracts.md](pipeline-contracts.md) | Populated | 585 | 2026-05-27 | discovery-integrator cycle-1 (renamed from `api-contracts.md` in Q3 FIX); FM added Phase B |
| 9 | [integration-map.md](integration-map.md) | Populated | 374 | 2026-05-27 | discovery-integrator cycle-1; FM added Phase B |
| 10 | [domain-glossary.md](domain-glossary.md) | Populated | 366 | 2026-05-27 | discovery-integrator cycle-1 — 195 terms; FM added Phase B; acronym variants fixed Phase A |
| 11 | [test-landscape.md](test-landscape.md) | Populated | 190 | 2026-05-27 | discovery-quality cycle-1; full rewrite cycle-2 FIX; counts corrected to actual **235** total in cycle-5 FIX (read self-reported summary lines, not grep-count of PASS markers; parse-recipe takes ~150s so 60s timeout was killing it mid-run) |
| 12 | [tech-debt.md](tech-debt.md) | Populated | 407 | 2026-05-27 | discovery-quality cycle-1 + 7 new entries from Q-AND-A in Phase B; H4 severity reconciled cycle-3 FIX |
| 13 | [infrastructure.md](infrastructure.md) | Populated | 236 | 2026-05-27 | discovery-quality cycle-1; FM added Phase B |
| 14 | [repo-presentation.md](repo-presentation.md) | Populated | 305 | 2026-05-27 | NEW in Phase B (Q3 replacement for deleted `ui-architecture.md`) — 8 sections covering README, docs/, examples/, methodology spec, blog refs, install surface |
| 15 | [feature-inventory.md](feature-inventory.md) | Populated | 49 | 2026-05-27 | Phase B (Q13) — 10 user-facing skills + `aid-generate` maintainer-only footnote |

**Removed in cycle-1 FIX Phase A (Q3):**
- ~~`security-model.md`~~ — content extracted to `coding-standards.md §11 Security-By-Design Conventions` (gitignore policy, shell `set -euo pipefail` discipline, agent-permission allowlist pattern); dedicated security doc is contortion for a non-runtime methodology repo
- ~~`ui-architecture.md`~~ — content was implementation detail of the KB-viewer (belongs in `aid-summarize` README); replaced by `repo-presentation.md` whose actual scope is the GitHub repo's documentation surface

**Meta-documents:**
- [STATE.md](STATE.md) — Discovery-area state ledger (Q&A, Review History, Calibration Log)
- [INDEX.md](INDEX.md) — Auto-generated per-doc summaries (regenerate via `bash canonical/scripts/kb/build-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`)

## Revision History

| # | Date | Cycle | Action | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-27 | cycle-1 | GENERATE complete | All 16 KB docs populated post-`--reset`. Scout 11m17s + 4-parallel wave 14m29s (tail = analyst) = ~25m total. |
| 2 | 2026-05-27 | cycle-1 | REVIEW complete | discovery-reviewer 11m57s. Grade E+ (35 findings: 0C / 16H / 11M / 11L / 0MIN). 5 new Q&A (Q11-Q15). |
| 3 | 2026-05-27 | cycle-1 | Q-AND-A complete | 17 entries: 16 Answered + 1 Skipped. Q16/Q17 captured as tech-debt for future `/aid-interview` pickup (no work-NNN reserved per `feedback_no-work-NNN-reservation` memory). |
| 4 | 2026-05-27 | cycle-1 | FIX Phase A complete | commit 82a5bd5 — cross-file refactors: Q11 acronym, Q2 verify-reports dropped, Q6 3 test deletes + `tests/README.md`, Q12 INDEX single-copy, Q3 rename+delete cascade (50+ files via developer agent, 27m wall). |
| 5 | 2026-05-27 | cycle-1 | FIX Phase B complete | commit c5a3d3d — per-file content: 12 FM additions, `repo-presentation.md` NEW (306L), `feature-inventory.md` populated, `tech-debt.md` +7 entries, README+CLAUDE small additions, Q15 Style A canonical migration. ~6m wall (6 parallel agents). |
| 6 | 2026-05-27 | cycle-2 | REVIEW complete | discovery-reviewer ~13m. Grade D+ (computed by grade.sh; 16C / 24H / 20M / 5L / 8MIN findings). 5 new Q&A (Q18-Q22). CC1: CLAUDE.md collapsed; CC2: verify-claims.sh cascade not swept. |
| 7 | 2026-05-27 | cycle-2 | FIX Phase A complete | CLAUDE.md cite cascade swept (CC1); verify-claims.sh cite cascade swept (CC2); test-landscape.md rewritten (Q20); technology-stack.md updated. |
| 8 | 2026-05-27 | cycle-3 | REVIEW complete | discovery-reviewer ~12m. Grade E+ (computed by grade.sh; 0C / 5H / 14M / 16L / 7MIN findings). No new Q&A — all findings mechanically resolvable. Both cycle-2 cascades CLEAN; 5H residue + drift items. |
| 9 | 2026-05-27 | cycle-3 | FIX complete | Comprehensive proactive sweep: all 5 HIGHs + 10+ additional drift items fixed. test-landscape.md mistakenly set total to 130 (orchestrator grep-pattern undercounted; corrected to actual 235 in cycle-5 FIX after two failed correction attempts). README.md banner + revision history updated. |
| 10 | 2026-05-27 | cycle-4 | REVIEW complete | discovery-reviewer ~21m. 28 findings (0C / 3H / 3M / 15L / 7MIN). 3 HIGHs all cascade from one root cause (wrong test counts from cycle-3 sweep). The reviewer's claimed 235 total was CORRECT; my counter-claim of 173 was wrong (I confirmed it again in cycle-5 by running parse-recipe with a sufficient timeout). |
| 11 | 2026-05-27 | cycle-4 | FIX complete | Test-count cascade attempted-fixed to 173 — STILL WRONG (parse-recipe was timed-out at 60s so undercounted to 51; actual is 113). Repeat-mistake of the same root cause. integration-map.md "16 KB doc(s)" residue cleared in 3 places. repo-presentation + pipeline-contracts wrong-line cites corrected. |
| 12 | 2026-05-27 | cycle-5 | REVIEW complete | discovery-reviewer ~27m (cycle-5 verification discipline: re-run each suite). 19 findings (0C / 3H / 0M / 12L / 4MIN). 3 HIGHs all the same test-count root cause from cycle-3/cycle-4. **Reviewer was right both times.** 0 MEDIUM target hit. |
| 13 | 2026-05-27 | cycle-5 | FIX complete | Test-count cascade finally fixed to actual 235 (write=69, parse=113, compute=17, deliver=18, read=18). Verification method changed: read self-reported summary lines from each suite (not grep-count of PASS markers). Operational note added: parse-recipe needs ≥180s timeout. |
