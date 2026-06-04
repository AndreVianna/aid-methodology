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
  - 2026-06-01: cycle-9 post-merge re-discovery for work-001-add-providers (PRs #42/#43/#44) — banner, completeness table, and revision history updated for the 3→5 profile reality
  - 2026-06-03: cycle-10 targeted re-discovery via /aid-housekeep — KB-delta refresh for the new aid-housekeep skill (10→11 user-facing skills) + housekeep scripts + 5 new test suites (18→24); 9 docs refreshed
---

# Knowledge Base — AID

> **Project:** AID — AI Integrated Development
> **Discovery cycle:** 10 (targeted re-discovery via /aid-housekeep KB-DELTA — KB refreshed for the new optional `aid-housekeep` skill (10→11 user-facing skills), the `canonical/scripts/housekeep/` helpers, and 5 new test suites (18→24); 9 docs refreshed, FIX complete, awaiting re-REVIEW)
> **Last KB review:** 2026-06-01 (cycle-9 REVIEW — graded D- pre-FIX: 3→5 profile drift across ~13 docs; FIX applied; cycle-10 re-REVIEW pending)
> **Status:** 15 active KB documents (unchanged doc-set — `aid-housekeep` is a *skill*, not a KB doc, like the providers before it; 16 originally generated in cycle-1; 2 deleted in Q3 FIX — `security-model.md` merged into `coding-standards.md §11`, `ui-architecture.md` replaced by `repo-presentation.md`; 2 renamed: `data-model.md → schemas.md`, `api-contracts.md → pipeline-contracts.md`).

Read [`INDEX.md`](INDEX.md) first for a one-paragraph summary of each KB doc.

## Completeness

> Per-doc line counts (T3) are not pinned here — they live in `.aid/generated/project-index.md` (coding-standards.md §9a).

| # | Document | Status | Last Reviewed | Notes |
|---|----------|--------|---------------|-------|
| 1 | [project-structure.md](project-structure.md) | Populated | 2026-06-03 | discovery-scout + cycle-10 §9a T3-strip; aid-housekeep (11 skills, scripts/housekeep/, 18→24 suites); stripped all hardcoded file/line counts → pointer to project-index.md |
| 2 | [external-sources.md](external-sources.md) | Populated | 2026-05-28 | no external docs provided; unchanged in cycle-9 (vendor convs were feature inputs, not discovery sources) |
| 3 | [architecture.md](architecture.md) | Populated | 2026-06-03 | discovery-architect; cycle-10 aid-housekeep (11-skill inventory table, on-demand data-flow + entry-point); §9a fixes (three→five trees, setup line counts stripped, branch de-pinned) |
| 4 | [technology-stack.md](technology-stack.md) | Populated | 2026-06-03 | cycle-10 §9a T3-strip — removed the file/line-count tables (Languages, Dev-Tools, Config) → pointer to project-index.md; branch de-pinned. (cycle-9: 12 .py, 5 host tools) |
| 5 | [module-map.md](module-map.md) | Populated | 2026-06-03 | discovery-analyst; cycle-10 aid-housekeep (11→12 total skills, aid-housekeep module row, new §4f scripts/housekeep/) |
| 6 | [coding-standards.md](coding-standards.md) | Populated | 2026-06-03 | discovery-analyst; cycle-9 §7a/§7d byte-identity 3→5 profiles / 7-tree; cycle-10 fix (10→11 user-facing skills) |
| 7 | [schemas.md](schemas.md) | Populated | 2026-06-01 | discovery-analyst; cycle-9 post-merge update (agent.format enum, RuleEntry.output_filename, ExtrasConfig.rules_frontmatter, manifest profile enum) |
| 8 | [pipeline-contracts.md](pipeline-contracts.md) | Populated | 2026-06-03 | discovery-integrator; cycle-10 aid-housekeep (new /aid-housekeep API section, 3 housekeep script CLIs, Housekeep Status block, Q&A handshake) |
| 9 | [integration-map.md](integration-map.md) | Populated | 2026-06-03 | discovery-integrator; cycle-10 aid-housekeep (11 dirs, skill enumeration, State-File R/W row, git-using-skill row) |
| 10 | [domain-glossary.md](domain-glossary.md) | Populated | 2026-06-03 | discovery-integrator; cycle-10 aid-housekeep terms (Housekeep/KB-drift reconciliation, Housekeep Status, aid/housekeep-* branch, --cleanup-only); removed stale kb-overhaul term |
| 11 | [test-landscape.md](test-landscape.md) | Populated | 2026-06-03 | discovery-quality; cycle-10 aid-housekeep (18→24 suites; 5 test-housekeep-* sections + test-complexity-score; 1:1 disk mapping verified) |
| 12 | [tech-debt.md](tech-debt.md) | Populated | 2026-06-03 | discovery-quality; cycle-10 fix — stale "18 suites" → 24, de-pinned count per §9a, Last Updated refreshed. (cycle-9: 4 LOW work-001 residuals) |
| 13 | [infrastructure.md](infrastructure.md) | Populated | 2026-06-03 | discovery-quality; cycle-10 §9a fixes — setup line counts stripped, branch de-pinned, stale merge-history removed, branch-protection reconciled live (Q27) |
| 14 | [repo-presentation.md](repo-presentation.md) | Populated | 2026-06-03 | discovery-architect; cycle-10 aid-housekeep (pipeline-10 vs installed-11 distinction; skill-counts subsection) |
| 15 | [feature-inventory.md](feature-inventory.md) | Populated | 2026-06-03 | orchestrator; cycle-10 aid-housekeep (11th user-facing skill row + engineering work-item) |

**Removed in cycle-1 FIX Phase A (Q3):**
- ~~`security-model.md`~~ — content extracted to `coding-standards.md §11 Security-By-Design Conventions` (gitignore policy, shell `set -euo pipefail` discipline, agent-permission allowlist pattern); dedicated security doc is contortion for a non-runtime methodology repo
- ~~`ui-architecture.md`~~ — content was implementation detail of the KB-viewer (belongs in `aid-summarize` README); replaced by `repo-presentation.md` whose actual scope is the GitHub repo's documentation surface

**Meta-documents:**
- [STATE.md](STATE.md) — Discovery-area state ledger (Q&A, Review History, Calibration Log)
- [INDEX.md](INDEX.md) — Auto-generated per-doc summaries (regenerate via `bash canonical/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`)

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
| 14 | 2026-05-28 | cycle-6 | REVIEW complete | 11 findings (0C / 2H / 2M / 3L / 4MIN). Test-count cascade fix from cycle-5 landed cleanly; 4 NEW drift items found in sweep-gaps: project-structure.md test-files table (38/39 → 113/69), domain-glossary.md "16 KB doc scaffolds" + "14 active standard", README.md cycle-3 banner staleness. |
| 15 | 2026-05-28 | cycle-6 | FIX complete | 4 reviewer-flagged + 3 orchestrator-caught variants of same root cause (14 vs 15 active KB docs); coding-standards/module-map/project-structure cardinality reconciled with explicit "14 standard-set + 1 custom = 15 active" language. |
| 16 | 2026-05-28 | cycle-7 | REVIEW complete | 7 findings (0C / 0H / 0M / 4L / 3MIN). **Target HIT: 0 HIGH / 0 MEDIUM.** All cycle-6 fixes landed cleanly. 30 spot-checks, 30 verified-TRUE. Remaining LOWs all carryover/build-script issues (metrics.md regex bugs, tech-debt PR snapshot, infrastructure branch-protection unknown). MINORs cosmetic. Grade: B (computed by grade.sh; raw output was E+ due to summary-line tag-string parse bug; tech-debt M7 logged). |
| 17 | 2026-06-01 | cycle-9 | REVIEW complete (post-merge) | Re-discovery triggered by work-001-add-providers merge (PRs #42/#43/#44). discovery-reviewer graded the pre-merge KB against current code: **D-** (35 findings: 0C / 15H / 12M / 8L / 0MIN) — the 3→5 profile root error cascading across ~13 docs + missing coverage of the 2 new providers, 2 new formats, schema additions, collision handler, 2 emitter test suites. Q23-Q25 added (vendor-confirmation residuals → recorded as LOW tech-debt). |
| 18 | 2026-06-01 | cycle-9 | FIX complete (post-merge) | 5 discovery sub-agents (architect/analyst/integrator/quality/scout) updated their owned docs in parallel to the 5-profile reality, disk-verified, durable anchors; orchestrator updated feature-inventory + project-structure global snapshot (regenerated to 1,518/209,599) + README; regenerated `.aid/generated/project-index.md` + INDEX.md. Awaiting cycle-9 re-REVIEW to confirm return to A. |
| 19 | 2026-06-03 | cycle-10 | Targeted re-discovery complete (via /aid-housekeep) | KB-DELTA drift: the new optional `aid-housekeep` skill (10→11 user-facing) + `canonical/scripts/housekeep/` (3 scripts) + 5 `test-housekeep-*.sh` suites (18→24) never reached the KB after PR #49. 5 discovery sub-agents refreshed their owned docs in parallel (architect: architecture+repo-presentation; analyst: module-map; scout: project-structure; integrator: integration-map+pipeline-contracts+domain-glossary; quality: test-landscape) — disk-verified, durable anchors, ~3.5–13m each; orchestrator authored feature-inventory + regenerated INDEX.md + README. Awaiting cycle-10 re-REVIEW. |
| 20 | 2026-06-03 | cycle-11 | Targeted re-discovery complete (via /aid-housekeep) | KB-DELTA drift from the **work-001 lite-path restructure** (PR #56, on top of work-002 docs PR #55): description-first TRIAGE; 4→3 work-type taxonomy (`single-doc`/`LITE-DOC` eliminated); 51-recipe catalog (5 old recipes gone); new `summary:` recipe field. work-001's own KB update was partial (only domain-glossary fully; schemas + pipeline-contracts missed the `summary:` field). 5 discovery sub-agents refreshed their owned docs in parallel (analyst: schemas+module-map; integrator: pipeline-contracts+integration-map; architect: architecture; scout: project-structure; quality: test-landscape) — disk-verified, ~22s–3m each; orchestrator fixed feature-inventory + repo-presentation + the missed `project-structure ## Recipes` table + regenerated INDEX.md + README. Awaiting cycle-11 re-REVIEW. |
