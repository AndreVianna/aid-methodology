# Discovery State

> **Status:** Cycle-21 adversarial re-grade — **C+** (Needs Improvement). Post-cycle-20 parallel-FIX wave (commit `a75ae66`, 4 tech-writer agents) was EFFECTIVE on 4 specific targets (INDEX.md 7-stale-narrative refresh, domain-glossary 10 work-001 entries, external-sources L61/L75/L76, feature-inventory #16 narrative) — all verified TRUE on disk. However, the wave did NOT cascade to derivative meta-docs (README.md L35 still says "14 ✅ Shipped, 6 ⚠️ Partial" while INDEX.md/feature-inventory now agree on 20/5/25) and did NOT update Feature #13 (Codex install bundle) / Feature #15 (Installer scripts) which BOTH still say "⚠️ Partial — installer omits `.agents/` copy (Q70 CONFIRMED bug)" while INDEX.md L21 + tech-debt H6 + infrastructure.md L68 all confirm Q70/H6 RESOLVED 2026-05-22 (4 days ago). This is a 3-doc internal contradiction. Additionally, host-tools-matrix.md still embeds retired vocabulary in 6+ sites ("triplication", "DISCOVERY-STATE.md", "DISCOVERY-GRADE.md", "triplicate-updates rule"). Coding-standards.md L378 cites "(83 + 82 lines respectively)" but data-model.md L22/L24/L51 cite "(85 lines)" / "(137 lines)" — internal contradiction. Disk-truth check: domain-glossary 161 terms verified (`grep -c "^| \*\*"` = 161). Glossary's Recipe/parse-recipe/Two-Tier Review/Pool dispatch/Delivery gate/etc. entries are accurate against parse-recipe.sh + state-review.md + state-delivery-gate.md + canonical scripts (verified by reading both). External-sources L61=307, L75=62, L76=399, L78=307, L93=307 — internal contradiction RESOLVED. INDEX.md L8 "canonical-generator output", L13 "canonical-generator-rendered", L21 "Codex `.agents/` copy bug RESOLVED 2026-05-22", L23 "20 ✅ Shipped, 5 ⚠️ Partial", L30 work-001 SHIPPED 5 features — all 7 cycle-20 wave targets verified. SKILL.md disk truth: aid-deploy=147, aid-detail=77, aid-discover=307, aid-execute=279, aid-init=119, aid-interview=357, aid-monitor=223, aid-plan=208, aid-specify=207, aid-summarize=233 (total 2,157). methodology=1071, run_generator.py=84, setup.sh=162, setup.ps1=157, parse-recipe.sh=540 — all match disk. **Net cycle-21 result:** semantic-shape claims 100% accurate (glossary, INDEX, recipe schema, two-tier model, pool dispatch); but 3 NEW semantic-doc-contradictions surfaced that cycle-20 wave's per-doc agent isolation missed (feature-inventory #13/#15 status, README count summary, coding-standards template line counts).
> **Minimum Grade:** A+
> **Current Grade:** C+ (post-cycle-21 adversarial re-grade)
> **User Approved:** yes (2026-05-21) — **stale; predates work-001/work-002/work-003 deploys + cycles 17-21**
> **Heartbeat Interval:** 1 minute
> **Max Parallel Tasks:** 5
> **Last KB Review:** 2026-05-25 (cycle 21, post-cycle-20-parallel-FIX adversarial re-grade)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary.

## Cycle-21 Per-Document Grades

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| project-structure.md | A- | Pass | [MINOR-mechanical-deferrable] L7 cycle-11 project-index baseline; stable. |
| external-sources.md | A | Pass | Cycle-20 wave RESOLVED: L61=307, L75=62, L76=399, L78=307, L93=307. Internal contradiction GONE. 8 vendor URLs still Pending fetch (deferred per Q80). |
| architecture.md | A | Pass | Solid. All cycle-19 structural rewrites preserved (Pattern 3/5/7 canonical-generator framed; Pattern 3 §M5 RESOLVED). |
| technology-stack.md | B+ | Below minimum | [MEDIUM-mechanical-deferrable] L17 file count cycle-11 vintage. Build/Lint Commands runnable. |
| module-map.md | B | Below minimum | [MEDIUM-mechanical-deferrable] L150 discovery-reviewer.md "(378)" — disk profile=402 (24-line drift). L318 "(~314 TOML)" — disk codex.toml=399 (85-line drift). Cycle-20 wave scope missed. |
| coding-standards.md | C+ | Below minimum | [MEDIUM] L378 "(83 + 82 lines respectively)" — disk: 85 + 137. Internal contradiction with data-model.md L22/L24/L51 which cite (85) / (137). Sibling-primary disagreement on the same canonical template artifact. §10 Thin-Router Convention (L442-475) is comprehensive and accurate. §9 Canonical-Generator Authoring Rule is solid. |
| data-model.md | A | Pass | L22/L24/L51 all cite discovery-state-template (85 lines) + work-state-template (137 lines) — consistent within doc, disk-true. |
| api-contracts.md | B+ | Below minimum | [LOW] L278 still cites discovery-state-template "(83 lines)" — disk=85; contradicts data-model.md L22 (85). Sibling-doc inconsistency. Recipe File Schema (L409-449) verified ACCURATE against parse-recipe.sh L1-58 (argument modes, exit codes 0-8, YAML schema, `{!{` escape, slot-lex `[a-z][a-z0-9-]*` all match). |
| integration-map.md | B | Below minimum | [MEDIUM-mechanical-deferrable] L21 64 files, L39 353-file inventory, L63 ≈80 files all cycle-11 baseline (disk: 194/631/196). Cycle-20 wave scope did not include this doc. |
| domain-glossary.md | A | Pass | **Cycle-20 wave SHIPPED 10 NEW work-001 entries.** Disk-verified 161 terms via `grep -c "^| \*\*"` = 161. All 10 entries (Recipe, parse-recipe, Thin-Router, Two-Tier Review, Delivery gate, Pool dispatch, compute-block-radius, writeback-task-status, complexity-score, dispatch-protocol-checklist) alphabetically positioned, with `[[wikilink]]` cross-refs. Entry descriptions verified accurate against parse-recipe.sh, state-review.md, state-delivery-gate.md, dispatch-protocol-checklist.md, complexity-score.sh, compute-block-radius.sh, writeback-task-status.sh. [LOW] writeback-task-status.sh cite `:1-40` clips a 627-line script (better range:1-60); same for compute-block-radius.sh `:1-45` for 293-line; same for complexity-score.sh `:1-34` for 209-line. Header citations are technically fine. |
| test-landscape.md | A- | Pass | L209-211 enumeration of 7 test scripts + 297-test total accurate (69+18+17+7+113+35+38=297). Test Commands runnable. |
| security-model.md | A- | Pass | §1.2 HISTORICAL framing preserved post-cycle-19. 21-finding split (1H+4M+4L+12I) consistent. |
| tech-debt.md | A- | Pass | M5 RESOLVED + M1 RETIRED past-tense framing preserved. L57 run_generator.py "~84 lines" matches disk. |
| infrastructure.md | B+ | Below minimum | [LOW-mechanical-deferrable] L25 "Current branch per git status: master" — actually `kb-cycle-17-fix` per prompt. |
| ui-architecture.md | B+ | Below minimum | [MEDIUM] L286 SUMMARY-STATE.md ref still present per cycle-20 reviewer — retired per FR2 (folded into STATE.md `## Knowledge Summary Status`). |
| feature-inventory.md | C+ | Below minimum | [HIGH] **Internal contradiction with sibling primaries.** Feature #13 (L30) status still says "⚠️ Partial — installer omits `.agents/` copy (DISCOVERY-STATE Q70 CONFIRMED bug)" but INDEX.md L21 confirms "RESOLVED 2026-05-22 (Q70/H6)" + tech-debt.md L106 + infrastructure.md L68 confirm both installers correctly copy `.agents/`. Same problem with Feature #15 (L32): "⚠️ Partial — Codex branch omits `.agents/` copy (Q70 CONFIRMED)". [HIGH] Feature #14 (L31) still cites "CONTRIBUTING.md omits Cursor from triplication rule (Q72)" — triplication RETIRED per coding-standards §9. [MEDIUM] Status Summary L49 still lists #13 and #15 under Partial citing Q70 — same root contradiction. [LOW] Feature #18 (L35) cites "triplication rule omits Cursor" — same retired-vocab issue. |
| STATE.md (META) | B+ | Below minimum | [MINOR] This doc preserves cycles 17-20 Review History rows + cycle-19 Q&A entries Q209-Q214. Adds Q215-Q217 for new cycle-21 gaps. |
| INDEX.md | A | Pass | **Cycle-20 wave RESOLVED all 7 stale narratives.** L8 "canonical-generator output" ✓; L13 "canonical-generator-rendered" ✓; L21 "Codex `.agents/` copy bug RESOLVED 2026-05-22" ✓; L23 "20 ✅ Shipped, 5 ⚠️ Partial" ✓; L30 work-001 "Shipped (PR #13, 2026-05-25 — 5 features ...)" ✓. |
| README.md | C | Below minimum | [HIGH] L35 still says "**14 ✅ Shipped, 6 ⚠️ Partial**" — INDEX.md L23 + feature-inventory L48 now both say 20/5/25. README Completeness table is stale on feature-inventory's status summary. L30 domain-glossary cell says "**161 terms**" — accurate post-cycle-20. [MEDIUM-mechanical-deferrable] L20-36 Completeness table line counts cycle-11 vintage. [LOW] L65 Revision History "Net result: 7 CRITICAL to 0" — overtaken by cycles 17-20. |
| host-tools-matrix.md | C | Below minimum | [HIGH] **5+ retired-vocabulary sites NOT touched by cycle-20 wave.** L5 cites "tech-debt.md H1/H3 (triplication drift)" — H1 RETIRED. L88 "DISCOVERY-STATE.md" — retired per FR2. L93 "DISCOVERY-GRADE.md ... DISCOVERY-STATE.md ... additional-info.md" — all retired per FR2. L95 "triplication rule ... quadruplicate" — RETIRED per coding-standards §9. L134 "(triplication → 5-way)" — retired. L142 "triplicate-updates rule" — RETIRED. L143 "DISCOVERY-STATE.md" — retired. [MEDIUM] L122 "repo repository" double-noun typo (cycle-20 wave scope missed). |
| CLAUDE.md (project root) | A | Pass | Solid full rewrite. L8 methodology 1,071 OK. L43-49 test suite enumeration (69+18+17+7+113+35+38=297) verified TRUE. L78-82 Recipes catalog accurate. L83-85 L1+L2+L3 visibility narrative accurate. Thin-Router architectural summary matches coding-standards §10 exactly. [MINOR-mechanical-deferrable] L65 "Total skill body lines: 2,108" — actual disk sum is 2,157 (49-line drift from cycle-19 aid-discover orchestrator-protocol additions). |

## Cycle-21 Findings — Summary by Severity

**CRITICAL (0):** No CRITICAL issues. SKILL.md / canonical script line counts 100% match disk per orchestrator pre-flight cleanup. Recipe schema accurate. Domain-glossary 161 terms verified. INDEX.md row summaries refreshed.

**HIGH (5):**
1. `feature-inventory.md` Feature #13 (Codex install bundle, L30) classified ⚠️ Partial citing "Q70 CONFIRMED bug; setup.sh:142-145 and setup.ps1:137-141" — but INDEX.md L21 + tech-debt H6 + infrastructure.md L68 all confirm Q70/H6 RESOLVED 2026-05-22. 3-doc internal contradiction.
2. `feature-inventory.md` Feature #15 (Installer scripts, L32) classified ⚠️ Partial citing "Codex branch omits `.agents/` copy (Q70 CONFIRMED)" — same contradiction as #13.
3. `feature-inventory.md` Feature #14 (L31) + Feature #18 (L35) cite "CONTRIBUTING.md omits Cursor from triplication rule (Q72)" — triplication is RETIRED per coding-standards §9 (now canonical-generator); the vocabulary is wrong for current architecture.
4. `README.md` L35 feature-inventory cell still says "**14 ✅ Shipped, 6 ⚠️ Partial**" — INDEX.md L23 + feature-inventory L48 now both say 20/5/25. README Completeness table is stale on feature-inventory's status summary (the cycle-20 wave updated INDEX + feature-inventory + glossary but did NOT cascade to README).
5. `host-tools-matrix.md` 5+ retired-vocabulary sites (L5 triplication drift, L88 DISCOVERY-STATE.md, L93 DISCOVERY-GRADE.md / DISCOVERY-STATE.md / additional-info.md, L95 triplication rule ... quadruplicate, L134 triplication → 5-way, L142 triplicate-updates rule, L143 DISCOVERY-STATE.md) — all retired per work-002 + FR2.

**MEDIUM (3):**
- `coding-standards.md` L378 "(83 + 82 lines respectively)" — disk: 85 + 137. Sibling-doc contradiction with `data-model.md`.
- `host-tools-matrix.md` L122 "repo repository" double-noun typo.
- `ui-architecture.md` L286 SUMMARY-STATE.md ref still present (retired per FR2).

**LOW (3):**
- `api-contracts.md` L278 still cites discovery-state-template "(83 lines)" — disk=85; sibling-doc inconsistency with data-model.md L22 (85).
- `domain-glossary.md` script-citation ranges clip the actual doc block beyond first ~40 lines. Header citations technically fine.
- `feature-inventory.md` Feature #18 (L35) cites same retired triplication rule.

**MINOR (~6):** Various cosmetic / 1-2 line residual drifts.

**[MINOR-mechanical-deferrable] (NOT counted against grade per prompt):**
- `module-map.md` L150 discovery-reviewer.md "(378)" — disk=402; L318 "(~314)" — disk=399.
- `integration-map.md` L21/L39/L63 file counts cycle-11 baseline.
- `infrastructure.md` L25 "Current branch: master" — actually `kb-cycle-17-fix`.
- `README.md` L20-36 Completeness table line counts cycle-11 vintage.
- `technology-stack.md` L17 Markdown file count cycle-11 vintage.
- `CLAUDE.md` L65 "2,108 total" — disk sum is 2,157.

## Cycle-21 Verification Spot-Checks (12 checks — SEMANTIC focus)

| # | Claim | Source | Verified | Evidence |
|---|-------|--------|----------|----------|
| C21-1 | domain-glossary.md has 161 terms (post-cycle-20 wave; was 151) | domain-glossary.md L6 | TRUE | `grep -c "^| \*\*" .aid/knowledge/domain-glossary.md` = 161. Disk-verified. |
| C21-2 | domain-glossary.md L41 complexity-score.sh entry correctly describes 209-line script with tier-thresholds Low=6/High=14 | domain-glossary.md L41 vs complexity-score.sh | TRUE | wc -l = 209. Tier thresholds + outputs match. |
| C21-3 | domain-glossary.md L48 compute-block-radius.sh entry correctly describes 293-line BFS script with exit codes 0/2 | domain-glossary.md L48 vs compute-block-radius.sh | TRUE | wc -l = 293. BFS semantics verified. |
| C21-4 | domain-glossary.md L125 parse-recipe.sh entry correctly describes all 5 argument modes + exit codes + POSIX-portability + `{!{` escape | domain-glossary.md L125 vs parse-recipe.sh L1-58 | TRUE | Script header L9-58 documents exactly the 5 modes (--list/--validate/--render/--spec/--tasks), exit codes 0-8, POSIX-portable note, `{!{` escape — all match glossary entry. |
| C21-5 | domain-glossary.md L138 Recipe entry correctly describes 5 seed recipes + YAML schema + lexical rule + TRIAGE Step 5a integration | domain-glossary.md L138 vs canonical/recipes/ + state-triage.md | TRUE | 5 recipe files exist + README. Schema fields match parse-recipe.sh expectations. |
| C21-6 | domain-glossary.md L166 Two-Tier Review entry correctly describes Tier 1 (Small reviewer, quick-check, no grade loop, CRITICAL fix-on-spot, HIGH deferred) + Tier 2 (Delivery gate, full reviewer, grade loop max 3 cycles) | domain-glossary.md L166 vs state-review.md L5-18 + state-delivery-gate.md | TRUE | state-review.md L5-18 documents exactly the Tier 1 behavior. state-delivery-gate.md confirms Tier 2 flow. |
| C21-7 | domain-glossary.md L63 dispatch-protocol-checklist.md entry correctly describes L1/L2/L3 protocol | domain-glossary.md L63 vs dispatch-protocol-checklist.md | TRUE | Checklist L1-47 documents the three-layer protocol: L1 ETA from rough-time-hints.md, L2 3 timed sleep echoes, L3 heartbeat file `HEARTBEAT_FILE`+`HEARTBEAT_INTERVAL` — all match glossary. |
| C21-8 | external-sources.md L61=307 / L78=307 / L93=307 (internal contradiction RESOLVED post-cycle-20 wave) | external-sources.md L61 + L78 + L93 | TRUE | All three sites correctly say "307 lines". Cycle-20 wave fix verified. |
| C21-9 | external-sources.md L75=62 (architect.toml) + L76=399 (discovery-reviewer.toml) | external-sources.md L75 + L76 vs disk | TRUE | wc -l profiles/codex/.codex/agents/architect.toml = 62 ✓ + discovery-reviewer.toml = 399 ✓. Cycle-20 wave fix verified. |
| C21-10 | INDEX.md L21 "Codex `.agents/` copy bug RESOLVED 2026-05-22" — cross-verified with feature-inventory L30 / L32 / L57 / L59 which still cite "Q70 CONFIRMED bug" | INDEX.md L21 vs feature-inventory.md L30 + L32 + L57 + L59 | INTERNAL CONTRADICTION | INDEX.md correctly says RESOLVED. feature-inventory.md Feature #13 (L30) + Feature #15 (L32) + Per-Feature Health (L57+L59) ALL still cite Q70 as "CONFIRMED bug". 3 sites in feature-inventory contradict INDEX + tech-debt H6 + infrastructure L68. Cycle-20 wave only updated #16; missed #13/#15. |
| C21-11 | README.md L35 feature-inventory cell "14 ✅ Shipped, 6 ⚠️ Partial" vs INDEX.md L23 "20 ✅ Shipped, 5 ⚠️ Partial" vs feature-inventory L48 "20 / 5" | README.md L35 vs INDEX.md L23 + feature-inventory.md L48 | INTERNAL CONTRADICTION | README is the 3rd meta-doc; cycle-20 wave dispatched 4 agents (INDEX + 3 primaries) — but did NOT include README. Result: README L35 still cycle-11 vintage. Single META-DOC contradiction (3-way). |
| C21-12 | host-tools-matrix.md retired-vocab sites (L5 "triplication drift", L88+L143 "DISCOVERY-STATE.md", L93 "DISCOVERY-GRADE.md", L95 "triplication rule", L122 "repo repository", L134+L142 "triplication") | host-tools-matrix.md vs canonical/templates/discovery-state-template.md + coding-standards §9 | TRUE — 6 SITES STALE | All 6 vocabulary residuals confirmed present. coding-standards §9 says "the old 'Triplicate Updates' rule is RETIRED" + FR2 retires DISCOVERY-STATE.md. Cycle-20 wave did not include host-tools-matrix in dispatch list. |

**Cycle-21 spot-check summary:** 12 checks. **9 TRUE / 2 INTERNAL CONTRADICTION / 1 TRUE-but-stale-vocab = 75% pass on semantic claims about cycle-20 wave landing; 25% reveals new sibling-doc contradiction surfaces that the wave's per-doc agent isolation missed.**

**Pass-rate framing:** The cycle-20 parallel-FIX wave was effective on its 4 specific dispatch targets (INDEX, glossary, external-sources, feature-inventory #16) — 100% pass rate on those targets. However, the wave's per-doc isolation pattern (4 tech-writer agents each scoped to a single doc) failed to cascade refresh to derivative meta-docs (README missed) and sibling features within the same doc (#13/#15 missed; #14/#18 missed for retired-vocab). The 5 HIGH findings are NEW post-cycle-20 surfaces, not legacy cycle-19 residuals.

## Cross-Cutting Concerns (cycle-21)

1. **The cycle-20 parallel-FIX wave's per-doc agent dispatch pattern is INSUFFICIENT for cross-doc cascade refreshes.** When a primary doc's narrative changes (Codex bug RESOLVED), 3+ sibling docs all need to update (INDEX + feature-inventory + README). The cycle-20 wave dispatched 1 agent per doc; this missed (a) cross-doc cascades (Codex bug RESOLVED in INDEX but Partial in feature-inventory #13/#15), and (b) intra-doc multi-site refreshes (feature-inventory updated #16 but missed #13/#14/#15/#18 which all carried the same retired-vocab/stale-status pattern).

2. **README.md is now the stalest meta-doc.** INDEX.md was refreshed in cycle-20; glossary was refreshed in cycle-20; external-sources was refreshed in cycle-20. README L35 "14 ✅ Shipped, 6 ⚠️ Partial" + L20-36 line counts cycle-11 vintage. README is the OLDEST meta-doc relative to current primaries — single largest meta-doc residual.

3. **host-tools-matrix.md retains pre-work-002 + pre-FR2 vocabulary in 6+ sites.** Adopter agents reading host-tools-matrix.md (a KB extension explicitly scoped to per-host-tool feature parity) will get a pre-2026-05-22 vocabulary in a 2026-05-25 KB. The contradictions are SEMANTIC (vocabulary describing the current architecture) not COSMETIC (typos).

4. **Sibling-doc line-count contradictions persist.** coding-standards L378 (83+82) vs data-model L22/L24/L51 (85+137); api-contracts L278 (83) vs data-model L22 (85). 2 sibling-primary disagreements on the same canonical template artifact.

5. **Cycle-20 wave was EFFECTIVE on its 4 dispatch targets but did not cover the full propagation graph.** All 4 dispatched docs verified post-fix on disk: INDEX.md 7 narratives ✓, glossary 161 terms with 10 new entries ✓, external-sources 3 line counts ✓, feature-inventory #16 narrative ✓. None of the 4 targets has a residual issue from the wave itself; the residuals are in 3 other docs that should have been dispatched but were not.

## Q&A

> Cycle-21 preserves Q190-Q214 from cycles 18-20. Q212-Q214 marked Answered by cycle-20 parallel-FIX wave (verified TRUE on disk in this re-grade). Adds Q215-Q217 for cycle-21 new gaps.

### Q190-Q214
- (preserved from cycles 18-20; Q212-Q214 confirmed Answered by cycle-20 parallel-FIX wave commit `a75ae66`)

### Discovery — Review Cycle 4 (cycle-21 adversarial re-grade)

### Q215: [Knowledge Base: High] Should Feature #13 (Codex install bundle) and Feature #15 (Installer scripts) in feature-inventory.md be reclassified from ⚠️ Partial to ✅ Shipped, given that Q70 / H6 (the only cited "CONFIRMED bug") was RESOLVED 2026-05-22?

**Status:** Pending
**Context:** Feature-inventory.md L30 (Feature #13) and L32 (Feature #15) both classify the respective features as ⚠️ Partial. The blocking citation for both is "Q70 CONFIRMED bug; setup.sh:142-145 and setup.ps1:137-141" (Feature #13) / "Codex branch omits `.agents/` copy (Q70 CONFIRMED)" (Feature #15).

However, **three sibling primary docs assert this issue is RESOLVED:**
- INDEX.md L21: "Codex `.agents/` copy bug RESOLVED 2026-05-22 (Q70/H6 — both installers now correctly copy `profiles/codex/.agents/`)."
- tech-debt.md L106: H6 RETIRED — "Resolution (work-002-canonical-generator / task-001 + task-002 + task-030): copy_dir profiles/codex/.agents added to setup.sh Codex branch ... H6 is retired".
- infrastructure.md L68: "Both installers correctly copy `.agents/` in the Codex branch as of 2026-05-22 (task-030 smoke test passed)".

Feature-inventory.md is the only doc still asserting the bug is open.

**Suggested:** Reclassify both Features #13 and #15 from ⚠️ Partial to ✅ Shipped. Update Status Summary L48 to enumerate 22 IDs (add 13 + 15) and L49 to enumerate 3 Partial IDs (Features 10, 14, 18). Update Per-Feature Health cross-ref to retire the Q70 cite under #13 / #15. If residual minor gaps remain for #15 (Q79 dry-run/prune, Q1 version-print), add a separate "⚠️ Enhancements Pending" subsection rather than ⚠️ Partial status.

**Applied to:** feature-inventory.md (proposed); pending FIX-pass dispatch.

### Q216: [Knowledge Base: High] Should README.md L35 (and L20-36 Completeness table broadly) be refreshed against current primaries, given that the cycle-20 parallel-FIX wave updated INDEX/glossary/external-sources/feature-inventory but did NOT update README?

**Status:** Pending
**Context:** README.md is one of 4 meta-docs (alongside INDEX.md, CLAUDE.md, STATE.md). The cycle-20 parallel-FIX wave dispatched 4 tech-writer agents — but to 3 primaries + 1 meta-doc (INDEX). README was not in the dispatch list. Result: README L35 feature-inventory cell says "**14 ✅ Shipped, 6 ⚠️ Partial**" while INDEX.md L23 + feature-inventory L48 now both say 20/5/25. Single-site 6-feature contradiction.

Additionally, README L20-36 Completeness table line counts (project-structure 280, architecture 619, etc.) are mostly cycle-11 vintage and have shifted post-cycle-17/18/19/20 FIX-passes. Several are correct post-cycle-20 (domain-glossary 187 ✓, feature-inventory 69 ✓); others need disk verification.

The natural agent-reader landing on README first will get stale counts before reading individual primaries. The README is a top-of-funnel meta-doc; staleness there is worse than staleness in deep primaries.

**Suggested:** Dispatch a tech-writer agent for README.md scoped to (a) refresh L35 feature-inventory cell to "20 ✅ Shipped, 5 ⚠️ Partial" matching INDEX, (b) refresh L20-36 Completeness table line counts against current `wc -l` of all 16 primaries + 1 extension, (c) add Revision History rows for cycles 17-20 + work-001 SHIPPED PR #13, (d) update L65 "Net result: 7 CRITICAL to 0" framing now overtaken by cycles 17-20.

**Applied to:** README.md (proposed); pending FIX-pass dispatch.

### Q217: [Knowledge Base: High] Should host-tools-matrix.md be refreshed to retire pre-work-002 ("triplication") and pre-FR2 ("DISCOVERY-STATE.md", "DISCOVERY-GRADE.md") vocabulary?

**Status:** Pending
**Context:** host-tools-matrix.md was not in the cycle-20 parallel-FIX wave dispatch list. As a result, it retains pre-work-002 + pre-FR2 vocabulary in 6+ sites:
- L5: cites "tech-debt.md H1/H3 (triplication drift)" — H1 is RETIRED per tech-debt.md (canonical-generator replaced triplication).
- L88: "linked Q&A entry in DISCOVERY-STATE.md" — DISCOVERY-STATE.md is RETIRED per FR2 (now `.aid/knowledge/STATE.md`).
- L93: "writes to DISCOVERY-GRADE.md + open-questions.md while Claude Code / Cursor write to DISCOVERY-STATE.md + additional-info.md" — all 4 cited filenames are RETIRED per FR2.
- L95: "documents triplication rule as ... omits Cursor entirely. The discipline is actually quadruplicate" — discipline is now canonical-generator (single source); triplication/quadruplicate vocab is RETIRED per coding-standards §9.
- L122: "repo repository" double-noun typo (cycle-19 deferred residual; cycle-20 wave scope missed).
- L134: "(triplication → 5-way)" — RETIRED vocab.
- L142: "the triplicate-updates rule, with Q34/Q72 corrections in mind" — RETIRED per coding-standards §9 (now Canonical-Generator Authoring Rule).
- L143: "linked Q&A entry in DISCOVERY-STATE.md" — RETIRED per FR2.

Adopter agents reading host-tools-matrix.md will get a pre-2026-05-22 vocabulary in a 2026-05-25 KB. The contradictions are SEMANTIC (vocabulary describing the current architecture) not COSMETIC.

**Suggested:** Dispatch a tech-writer agent for host-tools-matrix.md scoped to vocabulary refresh: triplication → canonical-generator-rendered + per-tool surface; quadruplicate → 3-profile-tree-from-single-canonical; DISCOVERY-STATE.md → `.aid/knowledge/STATE.md` (Discovery area); DISCOVERY-GRADE.md → STATE.md ## KB Documents Status; additional-info.md → STATE.md ## Q&A. Fix L122 "repo repository" typo. Cross-link to coding-standards §9 + §8.5 for normative current vocabulary.

**Applied to:** host-tools-matrix.md (proposed); pending FIX-pass dispatch.

---

## Cycle-21 FIX-Pass Recommendation

**Trigger:** Cycle-21 reviewer found Grade **C+** — pass rate 75% on semantic claims about cycle-20 wave landing; 25% reveals new sibling-doc contradictions. 5 surviving HIGH issues (primarily feature-inventory #13/#15 internal contradiction with INDEX/tech-debt/infrastructure + README.md stale-cascade + host-tools-matrix retired-vocab), 3 MEDIUM, 3 LOW, ~6 MINOR. 0 CRITICAL.

**Targeted Pass-8 cleanup (~30-45 minutes — 3 tech-writer agents in parallel):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 8A | feature-inventory.md: reclassify Feature #13 + #15 ⚠️ Partial → ✅ Shipped (Q70/H6 RESOLVED); refresh Feature #14 + #18 retired-vocab citations (triplication → canonical-generator); refresh Status Summary L48 → 22 Shipped + 3 Partial; refresh Per-Feature Health table L56-61 (retire Q70 from #13/#15) (Q215) | 8 sites |
| 8B | README.md: refresh L35 feature-inventory cell (14/6 → 20/5 or 22/3 per 8A); refresh L20-36 Completeness table line counts against current `wc -l`; add Revision History rows for cycles 17-20 + work-001 SHIPPED PR #13; update L65 "Net result" narrative (Q216) | 16+ sites |
| 8C | host-tools-matrix.md: vocabulary refresh — triplication → canonical-generator-rendered (L5, L95, L134, L142); DISCOVERY-STATE/DISCOVERY-GRADE/additional-info.md → STATE.md (L88, L93, L143); fix L122 "repo repository" typo (Q217) | 7-8 sites |

**Targeted Pass-8 mop-up (additional ~15 min):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 8D | coding-standards.md L378 "(83 + 82 lines respectively)" → "(85 + 137 lines respectively)" — sibling-doc alignment with data-model.md | 1 site |
| 8E | api-contracts.md L278 "(83 lines)" → "(85 lines)" — sibling-doc alignment with data-model.md | 1 site |
| 8F | ui-architecture.md L286 SUMMARY-STATE.md → STATE.md ## Knowledge Summary Status | 1 site |

**Expected post-Pass-8 grade:** A- (target) — Pass 8A closes the largest HIGH (feature-inventory #13/#15 internal contradiction). Pass 8B closes the README stale-cascade HIGH. Pass 8C closes the host-tools-matrix retired-vocab HIGH. 8D-8F close the sibling-doc inconsistencies. Combined: 5 HIGH + 3 MEDIUM + 3 LOW resolved. Residual mechanical-deferrable [MINOR] line counts not blocking. To reach A+: also (a) refresh integration-map.md file counts (cycle-11 baseline → current 194/631/196); (b) module-map.md L150 + L318 agent line counts; (c) project-index.md regeneration; (d) infrastructure.md L25 branch citation; (e) CLAUDE.md L65 "2,108" → "2,157".

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2-15 | 2026-05-21 to 2026-05-23 | (D- to A+ to C to A) | aid-discover cycles 2-15 | Cycle-14 reviewer found 8 HIGH from subagent-visibility-patch; cycle-15 orchestrator self-attestation Grade A. |
| 16 | 2026-05-23 | A | orchestrator self-attestation post cycle-14 fix-pass | Applied 19 line-count drift fixes; fixed false .gitignore claim; verify-kb-claims.sh exit 0. Self-attestation only. |
| 17 | 2026-05-25 | **D** | post-work-001-merge fresh adversarial (clean-context) | PR #13 work-001 thin-router refactor invalidated KB line counts across 12+ docs by 30-77%. 7 NEW CRITICAL · 35+ NEW HIGH · 25+ NEW MEDIUM · 10+ NEW LOW/MINOR. Pass rate 29%. Triggered cycle-17 FIX-pass. |
| 18 | 2026-05-25 | **D** | post-cycle-17-FIX re-grade | Cycle-17 FIX-pass cleared dominant SKILL.md drift in primary docs. Pass rate 29%→62%. CLAUDE.md fully rewritten (A). Recipes catalog, Thin-Router convention, Canonical Script Tests sections added. But: 3 CRITICAL residual drifts survive cycle-17. 35+ HIGH issues. Triggered cycle-18 Pass 5A-5L FIX-pass. |
| 19 | 2026-05-25 | **C+** | post-cycle-18-FIX re-grade | Cycle-18 Pass 5A-5L was BROADLY EFFECTIVE: all 3 CRITICAL aid-discover 596/548 cites GONE; all 7 "(line cite stripped...)" tombstones GONE; .gitignore claims unified to "47 lines" across 4 docs; run_generator.py = 84 unified across 8 docs; setup.sh + setup.ps1 unified; work-state-template unified; discovery-reviewer 381 → 405 in 3 docs; methodology 1,158 → 1,071 fixed. Pass rate 62%→84%. **0 CRITICAL surviving.** But 14 HIGH surviving. 3 new Q-entries added (Q209-Q211). |
| 20 | 2026-05-25 | **B** | post-cycle-19-FIX + new-workflow re-grade | Cycle-19 structural rewrites SHIPPED + orchestrator pre-flight cleanup swept ALL primary disk-truth: SKILL.md line counts 100% correct (canonical=disk for all 10 skills, 2,157 total); methodology/run_generator.py/setup.sh/setup.ps1/IMPEDIMENT/work-state-template/discovery-reviewer-AGENT/parse-recipe/.gitignore all match disk. Feature-inventory 25 items with correct 19+6=25 math. Recipes catalog confirmed. api-contracts Recipe File Schema verified ACCURATE. 0 CRITICAL. 10 surviving HIGH (INDEX.md 7 sites stale + domain-glossary missing 10 work-001 terms + external-sources L61 contradiction + feature-inventory #16 obsolete). Pass rate 53% disk-truth / 100% semantic. Triggered cycle-20 parallel-FIX wave. |
| 21 | 2026-05-25 | **C+** | post-cycle-20-parallel-FIX re-grade | Cycle-20 parallel-FIX wave (4 tech-writer agents, commit `a75ae66`) VERIFIED EFFECTIVE on its 4 dispatch targets: INDEX.md 7 stale narratives REFRESHED; domain-glossary 161 terms with 10 NEW work-001 entries (verified by `grep -c "^| \*\*" = 161` + read-through of all 10 entries against parse-recipe.sh / state-review.md / state-delivery-gate.md / dispatch-protocol-checklist.md / complexity-score.sh / compute-block-radius.sh / writeback-task-status.sh — 100% semantic accuracy); external-sources L61/L75/L76 RESOLVED (307/62/399 — internal contradiction GONE); feature-inventory #16 narrative REFRESHED ✅ Shipped post-canonical-generator. 0 CRITICAL. **5 surviving HIGH (NEW, not legacy):** (1+2) feature-inventory.md Feature #13 + #15 still ⚠️ Partial citing "Q70 CONFIRMED bug" — contradicts INDEX.md L21 + tech-debt H6 + infrastructure L68 all confirming RESOLVED 2026-05-22; 3-doc internal contradiction; cycle-20 wave dispatched feature-inventory but only updated #16, missed #13/#15; (3) feature-inventory Features #14+#18 cite RETIRED "triplication rule" vocab; (4) README.md L35 still "14 ✅ Shipped, 6 ⚠️ Partial" while INDEX + feature-inventory now both 20/5/25; (5) host-tools-matrix.md 6+ retired-vocab sites (L5+L95+L134+L142 triplication; L88+L93+L143 DISCOVERY-STATE.md/DISCOVERY-GRADE.md/additional-info.md; L122 repo-repository typo). 3 MEDIUM (coding-standards L378 sibling-doc contradiction with data-model; host-tools-matrix L122 typo; ui-architecture L286 retired-state-file ref). 3 LOW (api-contracts L278 sibling-doc inconsistency; domain-glossary script-citation ranges; feature-inventory #18 triplication vocab). 6 MINOR. **Pass rate: 75% on cycle-20-wave-landing-verification; 100% on disk-truth claims for SKILL.md / scripts / templates / methodology / installers; INTERNAL CONTRADICTION on cross-doc cascades (Codex bug RESOLVED in 3 docs, Partial in 1; feature count 20/5 in 2 docs, 14/6 in 1).** 3 new Q-entries added (Q215-Q217). **RECOMMENDATION:** Pass-8 dispatch 3 tech-writer agents in parallel (8A feature-inventory cross-doc cascade for #13/#15 reclass + #14/#18 vocab; 8B README full refresh against current primaries; 8C host-tools-matrix vocabulary modernization). 8D/8E/8F mop-up sibling-doc inconsistencies. Expected post-Pass-8 grade: A-. To reach A+: also refresh integration-map cycle-11 file counts + module-map L150/L318 agent line counts + project-index.md regeneration + CLAUDE.md "2,108"→"2,157". |
