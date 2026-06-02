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
---

# Knowledge Base — AID

> **Project:** AID — AI Integrated Development
> **Discovery cycle:** 9 (post-merge re-discovery for work-001-add-providers, PRs #42/#43/#44 — KB refreshed from the pre-merge 3-profile system to the current 5-profile reality; FIX complete, awaiting re-REVIEW)
> **Last KB review:** 2026-06-01 (cycle-9 REVIEW — graded D- pre-FIX: 3→5 profile drift across ~13 docs; FIX applied)
> **Status:** 15 active KB documents (unchanged doc-set — the 2 new providers are *code* profiles, not KB docs; 16 originally generated in cycle-1; 2 deleted in Q3 FIX — `security-model.md` merged into `coding-standards.md §11`, `ui-architecture.md` replaced by `repo-presentation.md`; 2 renamed: `data-model.md → schemas.md`, `api-contracts.md → pipeline-contracts.md`).

Read [`INDEX.md`](INDEX.md) first for a one-paragraph summary of each KB doc.

## Completeness

| # | Document | Status | Lines | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | [project-structure.md](project-structure.md) | Populated | 352 | 2026-06-01 | discovery-scout; cycle-9 post-merge update (5 profiles, 7-copy mirror, 18 suites, regenerated global snapshot 1,518/209,599) |
| 2 | [external-sources.md](external-sources.md) | Populated | 15 | 2026-05-28 | no external docs provided; unchanged in cycle-9 (vendor convs were feature inputs, not discovery sources) |
| 3 | [architecture.md](architecture.md) | Populated | 394 | 2026-06-01 | discovery-architect; cycle-9 post-merge update (5 install trees, 4 agent formats, Option-A collision, two Bash remaps) |
| 4 | [technology-stack.md](technology-stack.md) | Populated | 215 | 2026-06-01 | discovery-architect; cycle-9 post-merge update (12 .py, 27 TOML, 5 host tools, 2 new profile configs) |
| 5 | [module-map.md](module-map.md) | Populated | 320 | 2026-06-01 | discovery-analyst; cycle-9 post-merge update (12 scripts, 4 format branches + helpers, 2 emitter tests, RuleEntry/ExtrasConfig) |
| 6 | [coding-standards.md](coding-standards.md) | Populated | 603 | 2026-06-01 | discovery-analyst; cycle-9 §7a/§7d byte-identity scope 3→5 profiles / 7-tree |
| 7 | [schemas.md](schemas.md) | Populated | 527 | 2026-06-01 | discovery-analyst; cycle-9 post-merge update (agent.format enum, RuleEntry.output_filename, ExtrasConfig.rules_frontmatter, manifest profile enum) |
| 8 | [pipeline-contracts.md](pipeline-contracts.md) | Populated | 646 | 2026-06-01 | discovery-integrator; cycle-9 post-merge update (5-profile render contract + Copilot/Antigravity mapping notes) |
| 9 | [integration-map.md](integration-map.md) | Populated | 427 | 2026-06-01 | discovery-integrator; cycle-9 post-merge update (5 host-tool trees, 2 mapping subsections, Option-A collision) |
| 10 | [domain-glossary.md](domain-glossary.md) | Populated | 381 | 2026-06-01 | discovery-integrator; cycle-9 +9 terms (copilot-agent/antigravity-rule formats, native skills, rules_frontmatter, collision); 6-tree/7-copy |
| 11 | [test-landscape.md](test-landscape.md) | Populated | 417 | 2026-06-01 | discovery-quality; cycle-9 byte-identity 3→5 profiles, SU12-17/SPS05-08 + 2 emitter self-tests |
| 12 | [tech-debt.md](tech-debt.md) | Populated | 76 | 2026-06-01 | discovery-quality; cycle-9 +4 LOW work-001 residuals (Copilot slug, Antigravity model-id, empty tool_names, ps1 pwsh-skip). (Was 428L pre resolved-debt purge) |
| 13 | [infrastructure.md](infrastructure.md) | Populated | 252 | 2026-06-01 | discovery-quality; cycle-9 setup menu 1-5/Done=6 + Option-A collision; canonical→5-profiles pipeline |
| 14 | [repo-presentation.md](repo-presentation.md) | Populated | 321 | 2026-06-01 | discovery-scout; cycle-9 five profiles, 6-option install menu, collision bullet |
| 15 | [feature-inventory.md](feature-inventory.md) | Populated | 50 | 2026-06-01 | orchestrator; cycle-9 `/aid-generate` three→five install trees |

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
