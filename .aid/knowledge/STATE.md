# Discovery State

> **Status:** Cycle-20 adversarial re-grade — **B** (Needs Improvement). Post-cycle-19 FIX-passes + cycle-20 orchestrator pre-flight cleanup. Mechanical drift (line counts, off-by-1s, aggregates) has been broadly swept by the orchestrator pre-flight: SKILL.md line counts (canonical=disk: aid-discover 307, aid-interview 357, aid-deploy 147, aid-execute 279, aid-detail 77, aid-init 119, aid-monitor 223, aid-plan 208, aid-specify 207, aid-summarize 233; total 2,157 — all verified TRUE on disk); methodology=1071, run_generator.py=84, setup.sh=162, setup.ps1=157, IMPEDIMENT.md=116, work-state-template.md=137, discovery-state-template.md=85, parse-recipe.sh=540, discovery-reviewer/AGENT.md=405, .gitignore=47 — all match disk. Tech-debt M5 + M1 + security-model §1.2 now structurally correct (RESOLVED / RETIRED past-tense framing). Feature-inventory has 25 features with correct 19+6=25 Status Summary. Recipes catalog (5 + README + .gitkeep) confirmed at `canonical/recipes/`. Recipe schema in api-contracts.md matches parse-recipe.sh actual behavior (validated by reading both). 297-test canonical-helper suite correctly catalogued in test-landscape.md L209-211 + CLAUDE.md L43-49. **Semantic-quality residuals:** INDEX.md row summaries are STALE relative to refreshed primaries (still cite "triplication", "(quadruplicate)", "14 Shipped 6 Partial" when feature-inventory shows 19/6/25; still says installers omit `.agents/` which was RESOLVED 2026-05-22; still says work-001 "Requirements approved" when CLAUDE.md confirms SHIPPED via PR #13 with 5 features). Domain-glossary is MISSING all work-001 terms (Recipe, parse-recipe, thin-router, two-tier-review, delivery-gate, pool-dispatch, compute-block-radius, writeback-task-status, complexity-score) — 0 hits for any of those terms despite api-contracts.md + module-map.md + feature-inventory.md + CLAUDE.md all referring to them. External-sources.md L61 still says aid-discover "258 lines" while L78+L93 correctly say 307 — internal contradiction. Host-tools-matrix.md L122 still has "repo repository" double-noun residual. Host-tools-matrix.md L143 still cites DISCOVERY-STATE.md (retired). Infrastructure.md L25 "Current branch: master" stale (actually kb-cycle-17-fix per prompt). Module-map.md L150 cites discovery-reviewer.md "(378)" vs disk 402; L318 cites discovery-reviewer.toml "(~314)" vs disk 399. External-sources.md L75-76 cites architect.toml "(39 lines)" vs disk 62; discovery-reviewer.toml "(314)" vs disk 399.
> **Minimum Grade:** A+
> **Current Grade:** B
> **User Approved:** yes (2026-05-21) — **stale; predates work-001/work-002/work-003 deploys + cycle-17/18/19/20 FIX-passes**
> **Heartbeat Interval:** 1 minute
> **Max Parallel Tasks:** 5
> **Last KB Review:** 2026-05-25 (cycle 20, post-cycle-19 FIX + new-workflow re-grade)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary.

## Cycle-20 Per-Document Grades

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| project-structure.md | A- | Pass | [MINOR] L7 cites project-index.md "631 files / 90,011 lines" (cycle-11 baseline; mechanical drift, orchestrator scope). [MINOR] L33 ".aid/" gitignore claim correct (`.aid/.heartbeat/` only, KB tracked). Solid post-cycle-19. |
| external-sources.md | C+ | Below minimum | [HIGH] L61 says aid-discover "258 lines (post-work-001 thin-router refactor)" — disk is **307** (post cycle-19 orchestrator-protocol additions); L78+L93 correctly say 307 → internal contradiction WITHIN external-sources.md. [HIGH] L75 architect.toml "(39 lines)" — disk=**62** (Codex tier mapping added). [HIGH] L76 discovery-reviewer.toml "(314 lines)" — disk=**399** (~27% off). [MEDIUM] 8 vendor URLs still Pending fetch from 2026-05-21. |
| architecture.md | A | Pass | [MINOR] L171 methodology=1071 OK. L283 aid-discover 307 lines OK. L335 run_generator.py 84 OK. L443 IMPEDIMENT.md 116 OK. L538-539 setup.sh 162 + setup.ps1 157 OK. L606 cites discovery-architect "172 lines" — disk=172 OK. Pattern 3+5+7 all canonical-generator framed. Pattern 3 §M5 reframed as RESOLVED. Solid. |
| technology-stack.md | B | Below minimum | [MEDIUM] L17 "Markdown 249 files, 33,022 lines" — disk Markdown count is much higher post-work-001 merge (mechanical, orchestrator-scope deferrable but causes downstream-doc INDEX.md staleness). [MINOR] L48 "Shell 43 files" similarly stale. [MINOR] L66 writeback-state.sh "139 (canonical)/173 (per-profile)" — exists only at `canonical/templates/knowledge-summary/scripts/writeback-state.sh`, not at `canonical/templates/scripts/`. Path is correctly qualified in test-landscape.md L194. |
| module-map.md | B+ | Below minimum | [MEDIUM] L150 cites profile discovery-reviewer.md "(378 lines)" — disk=**402** (Pass 5C-style residual; canonical=405, profile=402 with rendering trim). [MEDIUM] L318 cites profiles/codex/.codex/agents/discovery-reviewer.toml "(~314 TOML)" — disk=**399** (~27% off). [MINOR] L48 now says "92 across 10 skill folders: 10 SKILL + 10 README + 72 references/*.md + 6 scripts/*.sh" — counts now match disk (canonical/skills has 92 .md + 6 .sh; cycle-19 deferred issue is RESOLVED). [MINOR] L66 enumerates exactly 12 state-*.md names + all 4 aid-interview scripts (parse-recipe.sh, test-parse-recipe.sh, test-lite-subpaths.sh, test-lite-to-full-escalation.sh) OK. |
| coding-standards.md | A- | Pass | [MINOR] L24 aid-discover SKILL.md 307 lines OK. L378 cites discovery+work state templates "(83+82 lines respectively)" — disk: discovery=85, work=137. Off by 2 + 55. [MINOR] L398 run_generator.py 84 OK. §10 Thin-Router Convention (lines 442-475) is comprehensive, accurate, and helpful for downstream phases. |
| data-model.md | A- | Pass | [MINOR] L22 cites discovery-state-template "(85 lines)" OK. L24 work-state-template "(137 lines)" OK. L201 IMPEDIMENT.md "(116 lines)" OK. L51 says "discovery-state-template.md (85 lines)" + work-state-template.md (137 lines) — both correct. Recipe-related artifacts not yet inventoried but recipes are template-shape, not data-model schema; OK as omission. |
| api-contracts.md | A- | Pass | [LOW] L278 cites discovery-state-template "(83 lines)" — disk=**85**; data-model.md L22 says 85. Internal contradiction with sibling doc. [MINOR] L48 cites discovery-reviewer.md "(405 lines)" — canonical=405 OK (uses canonical line as authoritative, OK). L70 aid-discover 307 OK. L205 aid-discover 307 OK. L344+L358 IMPEDIMENT.md 116 OK (Pass 6A successfully unified). Recipe File Schema section (lines 409-449) is comprehensive and ACCURATE against `parse-recipe.sh` (verified by reading both: argument modes, exit codes, YAML schema, `{!{` escape, slot-lex rule `[a-z][a-z0-9-]*` all match). |
| integration-map.md | B- | Below minimum | [MEDIUM] L21 "profiles/claude-code/.claude/ (64 files)" — disk=**194** files. [MEDIUM] L39 "353-file inventory (project-index.md)" — project-index.md was regenerated 2026-05-23 to 631 files; cycle-11 baseline. [MEDIUM] L63 "profiles/cursor/.cursor/ (≈80 files)" — disk=**196** files. These are project-index.md→narrative propagations that did not refresh post work-002/work-003 merges. [LOW] L170 .gitignore correct (47 lines). |
| domain-glossary.md | C | Below minimum | [HIGH] **Missing all work-001 terms.** `grep -i "recipe\|parse-recipe\|complexity-score\|writeback-task-status\|compute-block-radius\|dispatch-protocol-checklist\|thin-router\|two-tier\|delivery-gate"` returns **zero matches** across all 177 lines. Despite api-contracts.md L409+ documenting Recipe File Schema, module-map.md L48 enumerating thin-router scripts, feature-inventory.md L21/L22/L23/L24/L25 listing all 5 work-001 features, and CLAUDE.md L68/L78/L82 building usage on these concepts. The glossary is stuck at cycle-11 vocabulary. [LOW] L86 IMPEDIMENT.md "(1-116)" — correct OK. [LOW] L88 task-NNN-STATE.md entry references `canonical/templates/work-state-template.md:1-30` — work-state is 137 lines, citation `:1-30` clips state-template content. [LOW] L113 MONITOR-STATE.md "Template not present" — narrative is correct (deferred per FR2 OQ-3). |
| test-landscape.md | A- | Pass | [MINOR] L10 "631 files, 90,011 lines (pre-merge baseline)" — explicit pin acknowledged. [MINOR] L31 "only file matching *test* is the KB template" — contradicted by L209-211 listing 7 test scripts; this is a NEW section added post-test-suite-ship. Acceptable as section-7-is-update narrative. L209-211 + L212 "297 tests pass" verified correct (69+18+17+7+113+35+38=297). Test Commands section L70-89 has runnable commands. |
| security-model.md | A- | Pass | [MINOR] §1.2 (lines 51-65) now correctly HISTORICAL framing: "file removed 2026-05-25", "analysis below is preserved as a record". Past-tense throughout. The remaining residual is L51 header itself still reads as a complex parenthetical, which is acceptable and clear. [MINOR] L62 still says "[LOW] **Filename typo committed to repo.**" — past-tense rewrite would be cleaner. L249 .gitignore 47 lines OK. L298-300 finding counts (1 HIGH + 4 MEDIUM + 4 LOW + 12 INFO = 21) correctly maintained. |
| tech-debt.md | A- | Pass | [MINOR] M5 (lines 194-208) now correctly RESOLVED 2026-05-25 (work-001 thin-router); status note at L196 explains "well under 500-line guideline". M1 (lines 136-146) now correctly RETIRED 2026-05-25 with HISTORICAL framing. Status summary at L330 says "HIGH: 4 open" + 4 retired/resolved; the math 4+4=8 matches the "8 ###[HIGH] lines" claim at L336. L57+L319 still cite run_generator.py "~83 lines" — disk=84 (1-line residual). L274 methodology 1,071 OK. |
| infrastructure.md | B+ | Below minimum | [LOW] L25 "Current branch per git status: master" — stale; the prompt indicates branch is `kb-cycle-17-fix` (orchestrator-scope deferrable but flagged). [LOW] L29 + L52 + L274 run_generator.py 84 OK. L40+L42 setup.sh 162 OK. L58+L60 setup.ps1 157 OK. L207 .gitignore 47 lines OK. L179 aid-monitor 223 OK. L275 cites aid-discover 307 lines OK. L196 doc dates 2026-05-23 — further deploys not reflected (minor staleness). |
| ui-architecture.md | B+ | Below minimum | [MEDIUM] L286 still references ".aid/knowledge/SUMMARY-STATE.md" as the active file tracking Mermaid Version/Fetched/Cached — RETIRED per FR2 (absorbed into `.aid/knowledge/STATE.md ## Knowledge Summary Status`). [LOW] L319 cites DISCOVERY-STATE.md (per FR2 pre-FR2 was) — acceptable with retro-annotation. L316 aid-summarize 233 OK. |
| feature-inventory.md | B+ | Below minimum | [MEDIUM] Feature #16 (Per-tool agent definitions) description still claims "per-agent BODY divergence (line-count drift) across trees, especially for the 6 discovery sub-agents (claude `.md` 153-381 lines vs codex `.toml` 127-314 lines). Cause: Claude Code uses `references/` decomposition; Codex/Cursor inline. Propagation script pending per Q3 / Q73." — this is OBSOLETE narrative post-canonical-generator (work-002 SHIPPED). The 22 agents are now generated from `canonical/` with per-profile rendering; minor delta (canonical 405 vs profile 402 vs codex.toml 399 for discovery-reviewer) is intentional generator output, not "drift pending propagation script". [LOW] L48 Status Summary "Shipped 19 + Partial 6 = 25" math correct OK. L19+L23+L24+L25 features 19-22-25 correctly added. [MINOR] L21 OK adds Thin-Router Skill Footprint properly. |
| STATE.md (META) | B+ | Below minimum | [MINOR] This doc preserves cycle-19 Q&A entries Q209-Q211. Adds Q212-Q214 for new gaps. |
| INDEX.md | C | Below minimum | [HIGH] L8 "per-tool triplication pattern" — RETIRED narrative (canonical-generator); project-structure.md L65 calls it "Generator + Profile Architecture (replaces the pre-2026-05-22 Triplication Pattern)". [HIGH] L11 "Markdown (~482 files post work-001 merge), Shell (43)" — orchestrator says "~482" but technology-stack.md L17 says 249; disk is 976 (`.md` excluding `.git`). Inconsistent. [HIGH] L13 "(quadruplicate) cross-tree update rule" — RETIRED (coding-standards.md §9 says "the old 'Triplicate Updates' rule is RETIRED"). [HIGH] L18 "no triplication-drift checker" — RETIRED concept; should be "no canonical-vs-generator-output parity check" (test-landscape.md HIGH gap 2). [HIGH] L21 "⚠️ Both installers likely omit copying profiles/codex/.agents/" — RESOLVED 2026-05-22 per tech-debt.md H6 + infrastructure.md L68 "Both installers correctly copy `.agents/`". This is a stale CONFIRMED-BUG claim that contradicts 2 sibling primary docs. [HIGH] L23 "14 ✅ Shipped, 6 ⚠️ Partial" — feature-inventory.md L48 says **19 Shipped, 6 Partial, 25 total**. INDEX is 5 features behind. [HIGH] L30 work-001-aid-lite "Requirements approved · 4 features specified" — CLAUDE.md L60-86 + git history confirm SHIPPED via PR #13 with 5 features (002, 004, 005, 009, 011). INDEX shows work-001 as pre-execute when work-001 is post-deploy. |
| README.md | C+ | Below minimum | [MEDIUM] L13 "(project-index.md, regenerated 2026-05-23)" — not refreshed for work-001/002/003 deltas; cycle-19 deferred. [MEDIUM] L20-36 Completeness table line counts mostly stale (project-structure 280, architecture 619, technology-stack 389, etc.) — these are cycle-11 vintage and have shifted post cycle-17/18/19 FIX-passes. [LOW] L25 module-map.md "(415 lines)" disk-truth check needed. [LOW] L35 feature-inventory "(69 lines)" — disk=70 (1-line drift). [LOW] L36 host-tools-matrix "(144 lines)" — disk-truth check needed. [MINOR] L65 Revision History "Net result: 7 CRITICAL to 0" — overtaken by cycle-17 D-grade + cycle-18/19/20 sweeps. No row reflecting work-001 SHIPPED (PR #13). |
| host-tools-matrix.md | B- | Below minimum | [MEDIUM] L122 still has "repo repository" double-noun typo (orchestrator pre-flight missed). [MEDIUM] L143 still mentions "linked Q&A entry in DISCOVERY-STATE.md" — RETIRED per FR2 (should be `STATE.md`). [LOW] L134 "(triplication → 5-way)" should be "(canonical + N profiles)". Otherwise sound. |
| CLAUDE.md (project root) | A | Pass | [MINOR] L8 methodology 1,071 OK. L9-11 canonical/ → 3 profiles narrative correct. L43-49 test suite enumeration (69+18+17+7+113+35+38=297) verified correct. L61-65 Thin-Router Skills narrative + total 2,108 — disk total is 2,157 (49-line drift; CLAUDE.md cites "2,108" which matches feature-inventory.md L38 "4,467→2,108 reduction" — but disk is 2,157 due to cycle-19 orchestrator-protocol additions to aid-discover bringing it 258→307). Minor 49-line drift, but framed as "(was 4,467 pre-refactor — 53% reduction)". L78-82 Recipes catalog narrative accurate. L83-85 L1+L2+L3 visibility narrative accurate. Build commands runnable. Full rewrite remains solid. |

## Cycle-20 Findings — Summary by Severity

**CRITICAL (0):**
All cycle-19 surviving CRITICAL items have been resolved (none surfaced cycle-19 either). Cycle-20 finds NO CRITICAL issues. Disk-truth verification for SKILL.md / canonical script line counts is **100% correct** post-orchestrator-pre-flight: aid-discover 307, aid-interview 357, aid-deploy 147, aid-execute 279, etc. — all 10 skills match disk perfectly.

**HIGH (~10):**
1. `INDEX.md` L8 "triplication pattern" still cited (retired by canonical-generator narrative shift across project-structure / architecture / coding-standards / module-map primaries).
2. `INDEX.md` L11 "Markdown (~482)" contradicts technology-stack.md L17 "249" — orchestrator pre-flight set this number directly but downstream KB does not match.
3. `INDEX.md` L13 "(quadruplicate)" — retired per coding-standards.md §9.
4. `INDEX.md` L21 "Both installers likely omit copying profiles/codex/.agents/" — RESOLVED 2026-05-22 per tech-debt H6 + infrastructure L68; INDEX still asserts the bug.
5. `INDEX.md` L23 "14 Shipped, 6 Partial" — feature-inventory says 19/6/25.
6. `INDEX.md` L30 work-001 "Requirements approved · 4 features specified" — CLAUDE.md + git confirm SHIPPED, 5 features.
7. `domain-glossary.md` MISSING all work-001 terminology (Recipe, parse-recipe, thin-router, two-tier-review, delivery-gate, pool-dispatch, compute-block-radius, writeback-task-status, complexity-score, dispatch-protocol-checklist) — zero hits across 177 lines despite extensive usage in 4+ primary docs.
8. `external-sources.md` L61 aid-discover "258 lines" — disk=307; L78+L93 correctly 307 (internal contradiction).
9. `external-sources.md` L75 architect.toml "(39)" — disk=62; L76 discovery-reviewer.toml "(314)" — disk=399 (~27% drift).
10. `feature-inventory.md` Feature #16 narrative "per-agent BODY divergence ... Propagation script pending per Q3 / Q73" — OBSOLETE; canonical-generator (work-002 SHIPPED) supersedes.

**MEDIUM (~7):**
- `module-map.md` L150 discovery-reviewer.md "(378)" — disk profile=402; L318 "(~314)" — disk codex.toml=399.
- `integration-map.md` L21 "64 files" — disk=194 for `profiles/claude-code/.claude/`.
- `integration-map.md` L39 "353-file inventory" — project-index.md regenerated 2026-05-23 to 631.
- `integration-map.md` L63 "(≈80 files)" — disk=196 for `profiles/cursor/.cursor/`.
- `ui-architecture.md` L286 cites RETIRED SUMMARY-STATE.md.
- `host-tools-matrix.md` L122 "repo repository" double-noun typo (cycle-19 deferred).
- `host-tools-matrix.md` L143 cites RETIRED DISCOVERY-STATE.md.

**LOW (~9):**
- `api-contracts.md` L278 + `data-model.md` L22 + `coding-standards.md` L378 sibling-doc inconsistency on discovery-state-template line count (83 vs 85; disk=85; +2 in 2 docs).
- `coding-standards.md` L378 work-state-template "(82)" — disk=137 (55-line drift; cycle-19 missed); same line, separate error.
- `tech-debt.md` L57 + L319 run_generator.py "~83" — disk=84 (Pass 5E missed; 1-line residual).
- `infrastructure.md` L25 "Current branch: master" — actually `kb-cycle-17-fix` per prompt.
- `domain-glossary.md` L88 task-NNN-STATE.md citation `:1-30` clips work-state template (137 lines).
- `README.md` L20-36 Completeness table line counts mostly stale cycle-11 vintage.
- `README.md` L65 "Net result: 7 CRITICAL to 0" — pre-cycle-17 vintage.
- `security-model.md` L62 still phrased as "[LOW] Filename typo committed to repo" rather than HISTORICAL past-tense.
- `host-tools-matrix.md` L134 "(triplication → 5-way)" — retired vocabulary.

**MINOR (~12):** Various cosmetic / 1-2 line / single-cite residual drifts.

## Cycle-20 Verification Spot-Checks (15 checks — SEMANTIC focus)

| # | Claim | Source | Verified | Evidence |
|---|-------|--------|----------|----------|
| C20-1 | api-contracts.md Recipe File Schema (lines 409-449) accurately describes parse-recipe.sh | api-contracts.md L409-449 vs parse-recipe.sh L1-60 | TRUE | All claimed argument modes (--list, --validate, --render, --spec, --tasks, -h/--help), exit codes (0-8), YAML schema fields (name/applies-to/slot-count/task-count), `{!{` escape, slot-lex `[a-z][a-z0-9-]*` POSIX-ERE all confirmed in script header and bug-fix.md sample recipe. |
| C20-2 | feature-inventory.md L25 Recipes Catalog cites parse-recipe.sh "(540 lines)" + test-parse-recipe.sh "(113 assertions)" | feature-inventory.md L25 | TRUE | wc -l: parse-recipe.sh=540. Test count claim 113 cross-verified by test-landscape.md L208 "113 tests". |
| C20-3 | CLAUDE.md L65 "Total skill body lines: 2,108 across 10 skills (was 4,467 pre-refactor — 53% reduction)" | CLAUDE.md L65 | FALSE on disk total | wc -l of canonical/skills/aid-*/SKILL.md sums to **2,157** (not 2,108). 2,108 reflects post-feature-002 thin-router landing; the +49 lines come from cycle-19 orchestrator-protocol additions to aid-discover (258→307). 53% reduction claim "(4,467→2,108)" is the feature-002 SPEC math, preserved as historical. Minor drift but framed historically. |
| C20-4 | module-map.md L48 aggregate "92 across 10 skill folders + 6 scripts/*.sh" | module-map.md L48 | TRUE | `find canonical/skills -name "*.md" \| wc -l` = 92; `find canonical/skills -name "*.sh" \| wc -l` = 6. Cycle-19 deferred issue is RESOLVED. |
| C20-5 | module-map.md L150 discovery-reviewer.md "(378 lines)" | module-map.md L150 | FALSE | wc -l profiles/claude-code/.claude/agents/discovery-reviewer.md = **402**. Canonical AGENT.md = 405. Profile is rendered with 3-line frontmatter trim. Citation is 24 lines stale. |
| C20-6 | feature-inventory.md L48 Status Summary 19 Shipped + 6 Partial = 25 | feature-inventory.md L48 | TRUE | Table has 25 rows (1-25). L48 enumerates 19 IDs: "1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 17, 19, 20, 21, 22, 23, 24, 25" (19 IDs). L49 Partial = 6 (Features 10, 13, 14, 15, 16, 18). 19+6=25. OK |
| C20-7 | tech-debt.md M5 RESOLVED 2026-05-25 (work-001 thin-router) | tech-debt.md L194-208 | TRUE | Past-tense framing "Status: Post-work-001 PR #13 thin-router refactor reduced aid-discover/SKILL.md from 596 lines to 307 lines". Status row at L330 "HIGH: 4 open" no longer includes M5. OK |
| C20-8 | tech-debt.md M1 RETIRED 2026-05-25 (file removed) | tech-debt.md L136-146 | TRUE | "M1 — `.claude/settings..json` filename typo — **RETIRED 2026-05-25 (file removed)**" + HISTORICAL section preserved as record. OK Verified disk: `.claude/settings..json` does NOT exist. |
| C20-9 | security-model.md §1.2 structural correctness post-cycle-19 FIX | security-model.md L51-65 | TRUE | Header "1.2 The `.claude/settings..json` Double-Dot File — **HISTORICAL (file removed 2026-05-25)**" + L52-53 "Status: The double-dot file was removed... analysis below is preserved as a record." Past-tense throughout. [LOW] L62 marker preserved with note. Minor: L62 wording still present-tense "Filename typo committed" but in context clearly historical. |
| C20-10 | INDEX.md L21 still says "⚠️ Both installers likely omit copying profiles/codex/.agents/" | INDEX.md L21 | CONTRADICTORY | tech-debt.md L106 says "Resolution (work-002-canonical-generator / task-001 + task-002 + task-030): copy_dir profiles/codex/.agents added to setup.sh Codex branch ... H6 is retired" + infrastructure.md L68 says "Both installers correctly copy .agents/ in the Codex branch as of 2026-05-22 (task-030 smoke test passed)". INDEX is 3 days stale. |
| C20-11 | INDEX.md L30 work-001-aid-lite status "Requirements approved · 4 features specified" | INDEX.md L30 vs CLAUDE.md L75-86 + git | FALSE | CLAUDE.md confirms work-001 SHIPPED via PR #13 with 5 features (002 thin-router, 004 two-tier-review, 005 lite-path, 009 parallel-pool, 011 recipes). feature-inventory.md rows 21-25 all marked Shipped. Disk `.aid/work-001-aid-lite/features/` has 5 subdirs. INDEX shows pre-SHIP status. |
| C20-12 | domain-glossary.md MISSING work-001 terms (Recipe, thin-router, etc.) | domain-glossary.md (177 lines) | TRUE — MISSING | `grep -i "recipe\|parse-recipe\|thin-router\|two-tier\|delivery-gate\|compute-block-radius\|writeback-task-status\|complexity-score\|dispatch-protocol-checklist"` returns ZERO matches. Despite api-contracts.md §Recipe File Schema (lines 409-449), CLAUDE.md L78-86 explaining recipes + lite-path + thin-router, module-map.md L48 enumerating all these scripts, and feature-inventory.md L21-25 documenting all 5 work-001 features. Glossary stuck at cycle-11 vocab. |
| C20-13 | tech-debt.md L57 + L319 cite run_generator.py "~83 lines" | tech-debt.md L57 + L319 | FALSE | disk=84 (Pass 5E missed tech-debt 2 cite sites, cycle-19 finding survives cycle-20). |
| C20-14 | external-sources.md L61 aid-discover "258 lines" vs L78+L93 "307 lines" | external-sources.md L61 vs L78 vs L93 | INTERNAL CONTRADICTION | L61: "258 lines (post-work-001 thin-router refactor; ... pre-thin-router was 596)". L78: "307 lines (post-work-001 thin-router refactor + cycle-19 orchestrator-protocol additions)". L93: "307 lines". Disk=307. L61 is single-site stale. |
| C20-15 | external-sources.md L75-76 architect.toml "(39)" / discovery-reviewer.toml "(314)" | external-sources.md L75 + L76 | FALSE | wc -l: architect.toml = 62 (off by 23); discovery-reviewer.toml = 399 (off by 85, ~27%). Cycle-11 vintage; not updated post-canonical-generator render-changes. |

**Cycle-20 spot-check summary:** 15 checks. **8 TRUE / 5 FALSE / 1 INTERNAL CONTRADICTION / 1 PARTIAL-FALSE = 53% pass on disk-truth claims; 100% pass on semantic-shape claims (Recipe schema, M5 RESOLVED, M1 RETIRED, security-model §1.2 past-tense, feature-inventory math).**

**Pass-rate framing:** The semantic claims (what the docs SAY about how things WORK) are nearly entirely correct. The disk-truth claims (specific line counts and file counts) are where the remaining ~47% failures concentrate. Per the orchestrator's new-workflow contract, mechanical drift is OUT OF SCOPE — but these residuals are surfaced as low-cost cleanup targets for future cycles.

## Cross-Cutting Concerns (cycle-20)

1. **The orchestrator's pre-flight cleanup was EFFECTIVE for primary disk-truth (SKILL.md line counts, methodology, run_generator.py, setup.sh/ps1, IMPEDIMENT.md, work-state-template, parse-recipe.sh, discovery-reviewer/AGENT.md, .gitignore) — but the META-DOCUMENT LAYER (INDEX.md, README.md) was NOT refreshed against the corrected primaries.** This is the single largest residual: INDEX.md row summaries are essentially cycle-11 vintage and disagree with their corresponding primary docs on (a) "triplication" vs canonical-generator, (b) Codex installer bug status (RESOLVED 5x days ago), (c) feature counts (14/6/20 vs 19/6/25), (d) work-001 status (pre-SHIP vs SHIPPED). README.md Completeness table is similarly stale.

2. **DOMAIN-GLOSSARY is a coverage gap.** All work-001 vocabulary (Recipe, parse-recipe, thin-router, two-tier-review, delivery-gate, pool-dispatch, compute-block-radius, writeback-task-status, complexity-score, dispatch-protocol-checklist) is MISSING despite being heavily used in 4+ sibling primary docs + CLAUDE.md. A downstream agent invoking `aid-execute` on a recipe-instantiated work has no glossary entry to disambiguate "lite-path" vs "recipe" vs "thin-router-skill". This is a [HIGH] coverage gap from the perspective of agents using the KB.

3. **EXTERNAL-SOURCES has 3 single-site stale numbers** (aid-discover 258 vs 307; architect.toml 39 vs 62; discovery-reviewer.toml 314 vs 399). The contradiction between L61 (258) and L78+L93 (307) within the same doc is the most jarring.

4. **MODULE-MAP per-profile-tree agent line counts are cycle-11 vintage** (discovery-reviewer.md 378 vs 402; discovery-reviewer.toml 314 vs 399). The canonical AGENT.md line cite (405) is correct everywhere.

5. **INTEGRATION-MAP install-tree file counts are STALE** (64 vs 194 for `.claude/`; 80 vs 196 for `.cursor/`; 353 vs 631 for project-index). These were cycle-11 baseline; post-work-002 + work-003 file count grew substantially.

6. **FEATURE-INVENTORY Feature #16 still carries obsolete narrative** about per-agent body line drift "pending propagation script per Q3/Q73" — Q3/Q73 was RESOLVED by canonical-generator (work-002 SHIPPED). The description should be rewritten to acknowledge that the 405/402/399 spread is intentional generator output (per-profile rendering trim), not unmanaged drift.

7. **SECURITY-MODEL §1.2 + TECH-DEBT M1 + M5** are now properly past-tense / HISTORICAL — cycle-19 deferred items DONE. OK

8. **API-CONTRACTS Recipe File Schema** is a complete, accurate, verifiable contract that a downstream agent could implement against. OK

## Q&A

> Cycle-20 preserves Q190-Q211 from cycles 18-19 (all marked Answered or Pending per prior cycles). Adds Q212-Q214 for new gaps surfaced by this review.

### Q190-Q211
- (preserved from cycle-18 / cycle-19 — Q190-Q204 historical; Q205-Q208 cycle-18 retrospective; Q209-Q211 cycle-19 retrospective)

### Discovery — Review Cycle 3 (cycle-20 adversarial re-grade)

### Q212: [Knowledge Base: High] When were INDEX.md row summaries last refreshed against their primary docs?
**Status:** Pending
**Context:** The orchestrator's pre-flight cleanup (cycle-20) corrected primary disk-truth across the 16 KB docs + technology-stack + tech-debt + security-model. However, INDEX.md row summaries (.aid/knowledge/INDEX.md lines 8-24) remain at cycle-11 vintage and disagree with their corresponding primaries on multiple semantic claims:
- L8 "per-tool triplication pattern" — project-structure.md L65 calls this RETIRED in favor of "Generator + Profile Architecture (replaces the pre-2026-05-22 Triplication Pattern)".
- L13 coding-standards summary still mentions "(quadruplicate) cross-tree update rule" — coding-standards.md §9 explicitly RETIRES that rule.
- L21 infrastructure summary "⚠️ Both installers likely omit copying profiles/codex/.agents/" — tech-debt.md L106 + infrastructure.md L68 confirm RESOLVED 2026-05-22 (task-030 smoke test passed).
- L23 feature-inventory summary "14 ✅ Shipped, 6 ⚠️ Partial" — feature-inventory.md L48 says 19/6/25.
- L30 work-001-aid-lite "Requirements approved · 4 features specified" — CLAUDE.md L60-86 + git history (PR #13) + feature-inventory.md L21-25 confirm SHIPPED with 5 features.

INDEX.md is the agent-self-service navigation layer (per architecture.md Pattern 4 §progressive-disclosure tier 1). Stale summaries route agents to the wrong primary, or set the wrong expectation about what they will find.

**Suggested:** Add an INDEX.md refresh step to the orchestrator's pre-flight cleanup contract. After primary-doc corrections, re-derive the INDEX summary for each modified doc from the primary's first paragraph + key headings. The 5 staleness sites (L8 triplication, L11 file counts, L13 quadruplicate, L21 installer bug, L23+L30 work-001 + feature counts) are mechanical-derivative and could be auto-regenerated.

### Q213: [Knowledge Base: High] Should domain-glossary.md be extended with work-001 terminology (Recipe, parse-recipe, thin-router, two-tier-review, delivery-gate, pool-dispatch, compute-block-radius, writeback-task-status, complexity-score, dispatch-protocol-checklist)?
**Status:** Pending
**Context:** All 5 work-001 features (002 thin-router, 004 two-tier-review, 005 lite-path, 009 parallel-pool, 011 recipes) SHIPPED 2026-05-25 via PR #13. The terminology is heavily used in:
- `canonical/skills/aid-interview/SKILL.md` + `references/state-triage.md` + `references/state-lite-*.md` (recipe + lite-path)
- `canonical/skills/aid-execute/SKILL.md` + `references/state-execute.md` + `references/state-review.md` + `references/state-delivery-gate.md` (two-tier-review + pool dispatch + delivery-gate)
- `canonical/templates/scripts/{writeback-task-status,complexity-score,compute-block-radius,test-pool-dispatch}.sh`
- `canonical/templates/dispatch-protocol-checklist.md`
- `canonical/recipes/*.md` (5 seed recipes + README)
- `api-contracts.md` §Recipe File Schema (line 409+)
- `feature-inventory.md` L21-25
- `CLAUDE.md` L60-86 (architectural overview built on these primitives)

But `domain-glossary.md` (177 lines, 151 alphabetical terms) returns ZERO `grep -i` matches for any of these terms. A downstream agent invoking `aid-execute` on a recipe-instantiated lite-path work has no glossary entry to disambiguate `delivery-gate` vs `quick-check` vs `task-NNN-STATE.md` (RETIRED). Coverage gap relative to current methodology surface.

**Suggested:** Add ~10 new entries at next FIX-cycle, alphabetically inserted with `[[wikilink]]` cross-refs to existing entries (e.g., Recipe links to [[parse-recipe]] + [[lite-path]] + [[aid-interview]]; thin-router links to [[SKILL.md]] + [[reference-file decomposition]]; two-tier-review links to [[Grade]] + [[Quality Gate]] + [[Reviewer]]). Use api-contracts.md §Recipe Schema + work-001 feature SPECs as authoritative source.

### Q214: [Knowledge Base: Medium] How should feature-inventory.md Feature #16 narrative be updated post-canonical-generator?
**Status:** Pending
**Context:** Feature #16 ("Per-tool agent definitions, 22 agents × 3 trees = 66 agent files") currently asserts:
> ⚠️ Partial — per-agent BODY divergence (line-count drift) across trees, especially for the 6 discovery sub-agents (claude `.md` 153-381 lines vs codex `.toml` 127-314 lines). Cause: Claude Code uses `references/` decomposition; Codex/Cursor inline. Propagation script pending per Q3 / Q73.

This narrative is OBSOLETE post-work-002 (canonical-generator SHIPPED 2026-05-22):
- The "propagation script pending per Q3/Q73" — Q3/Q73 was RESOLVED by `run_generator.py`.
- The "Claude Code uses references/, Codex/Cursor inline" — RETIRED. All 3 profile trees ship the same `references/` siblings post-generator.
- The "153-381 vs 127-314 lines" — present-day disk shows canonical AGENT.md 405 → profile .md 402 → codex .toml 399 (a 6-line spread accounted for by frontmatter rendering, NOT body divergence).

The residual question: is Feature #16 still ⚠️ Partial because the 6-line spread is acceptable generator output (= ✅ Shipped) or is it because per-agent rendering still has unintended differences (= ⚠️ Partial)?

**Suggested:** Update Feature #16 status to ✅ Shipped with a rewrite: "All 22 agents emitted from `canonical/agents/{name}/AGENT.md` by `run_generator.py` with per-profile rendering. Codex bodies +/-3% line count vs canonical (frontmatter trim + TOML wrapping). All 3 profile trees identical at the body level (verified by render-equivalence test). Drift detection enforced by `verify_deterministic.py`."

---

## Cycle-20 FIX-Pass Recommendation

**Trigger:** Cycle-20 reviewer found Grade **B** — pass rate 53% on disk-truth claims, 100% on semantic-shape claims. 10 surviving HIGH issues (primarily INDEX.md staleness + domain-glossary coverage gap + 3 single-site stale numbers in external-sources), 7 MEDIUM, 9 LOW, ~12 MINOR. 0 CRITICAL.

**Targeted Pass-7 cleanup (mechanical, ~30 minutes):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 7A | INDEX.md row-summary refresh: L8 triplication → canonical-generator; L11 Markdown count update; L13 (quadruplicate) → (canonical-edit + generator); L18 triplication-drift → canonical-vs-output-parity; L21 installer-bug WARNING removed; L23 14/6/20 → 19/6/25; L30 work-001 SHIPPED with 5 features | 7 sites |
| 7B | external-sources.md L61 aid-discover 258 → 307; L75 architect.toml 39 → 62; L76 discovery-reviewer.toml 314 → 399 | 3 sites |
| 7C | tech-debt.md L57 + L319 run_generator.py 83 → 84 | 2 sites |
| 7D | module-map.md L150 discovery-reviewer.md 378 → 402; L318 discovery-reviewer.toml 314 → 399 | 2 sites |
| 7E | integration-map.md L21 64 → 194; L39 353 → 631; L63 ≈80 → ≈196 | 3 sites |
| 7F | host-tools-matrix.md L122 "repo repository" → "repo"; L143 DISCOVERY-STATE.md → STATE.md; L134 triplication → 5-way → canonical + N profiles | 3 sites |
| 7G | ui-architecture.md L286 SUMMARY-STATE.md → STATE.md ## Knowledge Summary Status | 1 site |
| 7H | infrastructure.md L25 branch master → kb-cycle-17-fix (or "varies per worktree; verify via git status") | 1 site |
| 7I | coding-standards.md L378 "(83+82)" → "(85+137)" | 1 site |
| 7J | api-contracts.md L278 discovery-state-template 83 → 85 | 1 site |
| 7K | README.md Completeness table line-count refresh against current primaries | 16 sites |

**Authored rewrites (~1-2h):**

| Sub-pass | Scope | Approach |
|----------|-------|----------|
| 7L | domain-glossary.md ~10 new entries for work-001 terminology (Q213) | Add alphabetically with `[[wikilink]]` cross-refs. Source: api-contracts.md §Recipe Schema + work-001 feature SPECs |
| 7M | feature-inventory.md Feature #16 narrative refresh post-canonical-generator (Q214) | Update Status to ✅ Shipped or document why ⚠️ Partial still applies |
| 7N | Refresh `.aid/knowledge/project-index.md` via `bash canonical/templates/scripts/build-project-index.sh --root . --output .aid/knowledge/project-index.md` | Regenerate to reflect post-work-001-merge file count + line totals; cascades to integration-map / technology-stack / module-map / data-model line-count baseline |

**Expected post-Pass-7 grade:** A- (target) — 7A alone (INDEX.md refresh) eliminates 7 HIGH issues; 7L (glossary) closes the last coverage gap. To reach A+, also: refresh `project-index.md` (7N), resolve Q210 (`.claude/` divergence from canonical for 5 skills), and complete cycle-19 Q209/Q211 (tech-debt M5 RESOLVED OK, M1 RETIRED OK — both done; Q211 settings..json pattern past-tense — security-model §1.2 done OK, tech-debt M1 done OK).

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2-15 | 2026-05-21 to 2026-05-23 | (D- to A+ to C to A) | aid-discover cycles 2-15 | Cycle-14 reviewer found 8 HIGH from subagent-visibility-patch; cycle-15 orchestrator self-attestation Grade A. |
| 16 | 2026-05-23 | A | orchestrator self-attestation post cycle-14 fix-pass | Applied 19 line-count drift fixes; fixed false .gitignore claim; verify-kb-claims.sh exit 0. Self-attestation only. |
| 17 | 2026-05-25 | **D** | post-work-001-merge fresh adversarial (clean-context) | PR #13 work-001 thin-router refactor invalidated KB line counts across 12+ docs by 30-77%. 7 NEW CRITICAL · 35+ NEW HIGH · 25+ NEW MEDIUM · 10+ NEW LOW/MINOR. Pass rate 29%. Triggered cycle-17 FIX-pass. |
| 18 | 2026-05-25 | **D** | post-cycle-17-FIX re-grade | Cycle-17 FIX-pass cleared dominant SKILL.md drift in primary docs. Pass rate 29%→62%. CLAUDE.md fully rewritten (A). Recipes catalog, Thin-Router convention, Canonical Script Tests sections added. But: 3 CRITICAL residual drifts survive cycle-17 (architecture.md L175 "596 lines"; api-contracts.md L70+L205 "596 lines each"; host-tools-matrix.md L38 "548 lines"). 35+ HIGH issues. Triggered cycle-18 Pass 5A-5L FIX-pass. |
| 19 | 2026-05-25 | **C+** | post-cycle-18-FIX re-grade | Cycle-18 Pass 5A-5L was BROADLY EFFECTIVE: all 3 CRITICAL aid-discover 596/548 cites GONE; all 7 "(line cite stripped...)" tombstones GONE; .gitignore "single line .aid/" claims unified to "47 lines" across 4 docs; run_generator.py = 84 unified across 8 docs; setup.sh = 162 + setup.ps1 = 157 unified across 8 docs; work-state-template = 137 unified across 4 docs; discovery-reviewer 381 → 405 in 3 docs; methodology 1,158 → 1,071 fixed; concatenation typo fixed; IMPEDIMENT.md 118 → 116 in architecture.md. Pass rate 62%→84%. **0 CRITICAL surviving.** But 14 HIGH surviving. 3 new Q-entries added (Q209-Q211). Triggered cycle-19 Pass-6 (mechanical) + cycle-19 structural rewrites for tech-debt M5/M1 + security-model §1.2. |
| 20 | 2026-05-25 | **B** | post-cycle-19-FIX + new-workflow re-grade | Cycle-19 structural rewrites SHIPPED: tech-debt M5 RESOLVED past-tense (work-001 thin-router → 307 lines < 500 guideline); tech-debt M1 RETIRED past-tense (file removed 2026-05-25); security-model §1.2 HISTORICAL framing. Orchestrator pre-flight cleanup (new workflow) swept ALL primary disk-truth: SKILL.md line counts 100% correct (canonical=disk for all 10 skills, 2,157 total); methodology/run_generator.py/setup.sh/setup.ps1/IMPEDIMENT/work-state-template/discovery-reviewer-AGENT/parse-recipe/.gitignore all match disk. Feature-inventory 25 items with correct 19+6=25 math. Recipes catalog confirmed. api-contracts Recipe File Schema verified ACCURATE against parse-recipe.sh actual behavior. **0 CRITICAL.** 10 surviving HIGH (cycle-20): (1-7) INDEX.md row summaries STALE on 7 sites — triplication retired, Markdown count wrong, quadruplicate retired, Codex installer bug RESOLVED 3+days ago, feature count 14/6/20 vs disk 19/6/25, work-001 "Requirements approved" vs disk SHIPPED via PR #13; (8) domain-glossary.md MISSING all work-001 vocabulary (Recipe, parse-recipe, thin-router, two-tier-review, delivery-gate, pool-dispatch, compute-block-radius, writeback-task-status, complexity-score, dispatch-protocol-checklist) — 0 hits; (9) external-sources.md L61 "258 lines" internal contradiction with L78+L93 "307 lines"; L75-76 architect.toml 39 (disk=62) + discovery-reviewer.toml 314 (disk=399); (10) feature-inventory Feature #16 narrative obsolete (cites Q3/Q73 RESOLVED, "propagation script pending"). 7 MEDIUM: integration-map file counts (64 vs 194; 80 vs 196; 353 vs 631); module-map L150+L318 discovery-reviewer line cites; ui-architecture L286 retired SUMMARY-STATE; host-tools-matrix L122 "repo repository" + L143 DISCOVERY-STATE. 9 LOW/9 MINOR mostly cosmetic + 1-line drifts. 3 new Q-entries added (Q212-Q214). **PASS RATE: 53% on disk-truth, 100% on semantic-shape.** **RECOMMENDATION:** Pass-7 mechanical sweep (~30 min: 7A-7K, ~40 sites — INDEX.md refresh alone closes 7 HIGH) + Pass-7 authored content (~1-2h: 7L domain-glossary new entries, 7M feature-inventory #16 narrative refresh, 7N project-index.md regeneration). Expected post-Pass-7 grade: A-. To reach A+: resolve Q210 (.claude/ canonical divergence), refresh project-index baseline cascades. |
