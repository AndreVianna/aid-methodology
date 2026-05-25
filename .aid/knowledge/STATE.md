# Discovery State

> **Status:** Cycle-19 adversarial re-grade — **C+** (Needs Improvement). Cycle-18 FIX-pass landed Pass 5A-5L cleanly across primary docs: 596/548 disappear, "(line cite stripped...)" tombstones gone, .gitignore "single line" claims swept, run_generator.py = 84 / setup.sh = 162 / setup.ps1 = 157 / IMPEDIMENT.md = 116 unified in architecture/coding-standards/module-map/technology-stack/infrastructure/project-structure. Pass rate climbed from 62% (cycle-18) to **84%** (cycle-19). But: tech-debt.md M5 "258 lines (9.6% over 500)" still mathematically FALSE; tech-debt.md M1 + security-model.md §1.2 still have **structurally-broken nested-parenthetical headers** treating the deleted settings..json as a present file; module-map.md L48 aggregate counts STILL "wildly wrong" (cycle-18 deferred — disk 92 .md + 6 .sh vs claim "7 refs + 2 scripts"); module-map.md L66 count vs enumeration off-by-1 + 2 scripts omitted; INDEX.md + README.md NOT refreshed (still cite 20 features, triplication, x 4 trees, "Markdown 249 files", work-001 "Requirements approved" when CLAUDE.md confirms SHIPPED); feature-inventory.md L48 Status Summary still totals 14+6=20 when table has 25 rows; api-contracts.md L344+L358 + data-model.md L201 + domain-glossary.md L86 still cite IMPEDIMENT.md as 118/119; project-index.md L209 still cites discovery-reviewer 381; tech-debt.md L57+L319 still cite run_generator.py 83.
> **Minimum Grade:** A+
> **Current Grade:** C+
> **User Approved:** yes (2026-05-21) — **stale; predates work-001/work-002/work-003 deploys**
> **Heartbeat Interval:** 1 minute
> **Max Parallel Tasks:** 5
> **Last KB Review:** 2026-05-25 (cycle 19, post-cycle-18 FIX adversarial re-grade)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary.

## Cycle-19 Per-Document Grades

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| project-structure.md | B | Below minimum | [LOW] L209 still cites discovery-reviewer "381 lines" (disk profile=402, canonical=405); reflects 2026-05-23 generation pre-thin-router. [LOW] Templates section may omit some new e2e runners / dispatch-protocol-checklist. |
| external-sources.md | C | Below minimum | [HIGH] L61 absurd `258 (... was 258 ... was 258)` three-identical-258s parenthetical; L78+L93 same pattern. [MEDIUM] 8 vendor URLs still Pending fetch from 2026-05-21. |
| architecture.md | B+ | Below minimum | [LOW] L288 "at 258 lines still exceeds the 500-line target" — 258 < 500 is NOT over. Same false claim as tech-debt M5. [LOW] L606 cites discovery-architect/AGENT.md "172 lines" (disk=196, off by 24). [MINOR] L335 + L538-539 run_generator.py 84 + setup.sh 162 + setup.ps1 157 all match disk. |
| technology-stack.md | C+ | Below minimum | [HIGH] L322 still says "all three trees ship 548 lines for aid-discover/SKILL.md (verified cycle 11)" — disk=258 in all 3 trees. Cycle-18 missed this. [MEDIUM] L184 settings..json sentence retains broken grammar. [MEDIUM] L17 Markdown 249 files vs project-structure.md 472 — contradiction. [MEDIUM] L48 Shell 43 files vs 76 — contradiction. [MINOR] L265 run_generator.py 84; setup.sh 162; setup.ps1 157. |
| module-map.md | D+ | Below minimum | [HIGH] L48 aggregate "32 across 10 skill folders: 10 SKILL + 10 README + 7 references/*.md + 2 scripts/*.sh" — DISK: canonical/skills/ has **92 .md + 6 .sh**. Off by ~13x on refs, 3x on scripts. Same as cycle-18; FIX deferred. [HIGH] L51 "the only embedded scripts" FALSE — aid-interview/scripts/ has 4 scripts. [HIGH] L66 text says "13 state-*.md" then enumerates 12 names — disk=12; count claim FALSE. [HIGH] L66 lists only 2 of 4 aid-interview scripts. [MEDIUM] L196 templates inventory omits recipes/, dispatch-protocol-checklist.md, long-wait-protocol.md, subagent-heartbeat-protocol.md, recipe-template.md, delivery-issues.md. |
| coding-standards.md | B | Below minimum | [LOW] L24 + L47 + L49 disk-truth. [LOW] L398 run_generator.py 84. [LOW] L295 "writeback-state.sh lacks -h/--help" still contradicts test-landscape L194 (Q191 done). [LOW] L440 retains stale 244/453/1078/1090/548 historical citations. [MINOR] §10 Thin-Router Convention added BELOW Revision History (acceptable). |
| data-model.md | B- | Below minimum | [LOW] L201 cites IMPEDIMENT.md "(1-119)" — disk=116. [LOW] L24 + L121 work-state-template 137 (Pass 5D landed). [LOW] §canonical/recipes/ added AFTER Revision History (acceptable). |
| api-contracts.md | C+ | Below minimum | [MEDIUM] L344 + L358 still cite IMPEDIMENT.md "(118 lines)" + "IMPEDIMENT.md:114-118" — disk=116. Pass 5K only fixed architecture.md. [LOW] L13 setup.sh 162 + setup.ps1 157. [LOW] L70 + L205 Pass 5B cleared 596 cites; aid-discover correctly 258. |
| integration-map.md | C+ | Below minimum | [MEDIUM] L21 profiles/claude-code/.claude/ "(64 files)" vs project-structure.md "113 files" contradiction. [MEDIUM] L60 discovery-reviewer.toml "(314 lines)" — disk=399. [MEDIUM] L75 architect.toml "(39 lines)" — disk=62. [MEDIUM] L110+L179 "353 files inventoried" — disk=631. [LOW] L170 .gitignore now correct (Pass 5H). |
| domain-glossary.md | C+ | Below minimum | [MEDIUM] L86 IMPEDIMENT.md "(1-118)" — disk=116. [MEDIUM] L140 "Skill body drift" entry internally muddled (cycle-11 narrative + post-canonical truth blended). [MEDIUM] No new term for recipe / parse-recipe.sh / compute-block-radius / writeback-task-status / dispatch-protocol-checklist despite cycle-17/18 FIX adding these elsewhere. |
| test-landscape.md | B- | Below minimum | [LOW] L10 "631 files, 90,011 lines (pre-merge baseline)" — confusing label. [LOW] L31 "only file matching *test* is template" but L209-211 lists 7 test scripts — narrative contradiction within doc. [LOW] L126 "aid-discover (258 lines, 9.6% over 500-line guideline)" — 258 < 500, FALSE. [LOW] L209-211 Canonical Script Tests correctly enumerates 297 tests. |
| security-model.md | D+ | Below minimum | [HIGH] §1.2 header L51 + body L53 STRUCTURALLY BROKEN — header reads as non-sentence; L53 then says ".claude/settings.json (the ... was removed) exists alongside .claude/settings.json" — same file alongside itself. L57 diff command compares deleted file. L62 [LOW] still claims "Filename typo committed to repo" for file that doesn't exist. Cycle-18 deferred. [LOW] L249 .gitignore correctly 47 lines (Pass 5H). |
| tech-debt.md | D | Below minimum | [HIGH] M5 entire premise FALSE: L190-198 says "aid-discover violates Under 500 lines — actual 258 lines (9.6% over)". 258 < 500 — NO violation. M5 should be RETIRED. [HIGH] L198 still cites "548 vs 500 is a modest overage". [HIGH] M1 (L136) header identical structural break to security-model §1.2; L138 body "It is committed" and L142 effort "git rm .claude/settings..json" — file doesn't exist. [MEDIUM] L57 + L319 "~83 lines of Python in run_generator.py" — disk=84 (Pass 5E missed tech-debt). |
| infrastructure.md | B | Below minimum | [LOW] L25 "Current branch per git status: master" — current is kb-cycle-17-fix; stale. [LOW] L29 + L52 + L274 run_generator.py 84 (Pass 5E). [LOW] L207 .gitignore 47 lines (Pass 5H). [LOW] L40 + L58 setup.sh 162 + setup.ps1 157. [LOW] L196 doc dates 2026-05-23 — further deploys not reflected. |
| ui-architecture.md | A- | Pass | [MINOR] L286 cites .aid/knowledge/SUMMARY-STATE.md — RETIRED per FR2. [MINOR] L18 "25 files per project-structure.md:170-172" vs project-structure.md L194 "~30 files". L24 aid-summarize 233. Otherwise solid. |
| feature-inventory.md | C+ | Below minimum | [HIGH] L48 Status Summary "Shipped (no known issues) | 14 | Features 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 17, 19, 20" — table has 25 rows including 21-25 all Shipped. [HIGH] L49 "Partial | 6" — 14+6=20 but table has 25. Math wrong. [HIGH] L65 narrative "The 20-item inventory" — disk has 25. [LOW] L32 setup.sh 162 + setup.ps1 157 (Pass 5F). [LOW] L38-42 rows 21-25 disk-truth (writeback-task-status.sh 627, complexity-score.sh 209, compute-block-radius.sh 293, test-pool-dispatch.sh 153, parse-recipe.sh 540). |
| STATE.md (META) | B | Below minimum | [MINOR] This doc is now the cycle-19 review; preserves cycle-18 Q205-Q208 verbatim. Adds Q209-Q211 for new gaps. |
| INDEX.md | D+ | Below minimum | [HIGH] L8 "per-tool triplication pattern" — should reference canonical-generator. [HIGH] L10 "triplicated payloads" — RETIRED. [HIGH] L11 "Markdown (249 files), Shell (43)" — project-structure says 472/76. [HIGH] L12 "skills (x 4 trees), agents (x 4 trees), templates (x 4 trees)" — stale post-canonical-generator framing. [HIGH] L13 "(quadruplicate) cross-tree update rule" — RETIRED. [HIGH] L23 "20 features" — disk=25. [HIGH] L30 work-001-aid-lite "Requirements approved · 4 features specified" — CLAUDE.md L83-86 + git confirm SHIPPED. [HIGH] No row for canonical/recipes/ or work-001 scripts. Cycle-18 deferred. |
| README.md | D+ | Below minimum | [HIGH] L13 "(project-index.md, regenerated 2026-05-23)" — not refreshed for work-001/002/003 deltas. [HIGH] L26 module-map.md row missing recipes catalog. [HIGH] L35 "20 features ... 14 Shipped, 6 Partial" — disk=25. [MEDIUM] L65 Revision History "Net result: 7 CRITICAL to 0" — overtaken by cycle-17 D-grade. [MEDIUM] No row reflecting work-001/work-002/work-003 SHIPPED. Cycle-18 deferred. |
| host-tools-matrix.md | B- | Below minimum | [MEDIUM] L122 "~17,600 lines = ~36% of the 90,011-line repo repository total" — "repo repository" double-noun residual from cycle-18 typo fix (Pass 5I cleared "sitory" but missed "repo repository"). [MEDIUM] L143 "linked Q&A entry in DISCOVERY-STATE.md" — RETIRED per FR2. [LOW] L38 aid-discover 258 in all columns (Pass 5B). [LOW] L46 aid-summarize 233 (Pass 5L). [LOW] L94 still mentions "post subagent-visibility-patch". |
| CLAUDE.md (project root) | A | Pass | [MINOR] L8 methodology 1,071. [MINOR] L43-49 test counts 69+18+17+7+113+35+38 = 297. Build commands runnable. Full rewrite landed. |

## Cycle-19 Findings — Summary by Severity

**CRITICAL (0):**
All cycle-18 CRITICAL items have been resolved by Pass 5B: aid-discover 596/548 line claims removed from architecture.md L175, api-contracts.md L70+L205, host-tools-matrix.md L38+L46. Cycle-19 finds NO surviving CRITICAL issues.

**HIGH (~14):**
1. `module-map.md` L48 aggregate counts wildly wrong (claim "7 references + 2 scripts" vs disk 92 .md + 6 .sh). Cycle-18 explicitly deferred; cycle-19 confirms unchanged.
2. `module-map.md` L51 "only embedded scripts" FALSE — aid-interview has 4 scripts.
3. `module-map.md` L66 enumerates 12 state-*.md but text says "13" (disk=12).
4. `technology-stack.md` L322 still claims "all three trees ship 548 lines for aid-discover/SKILL.md (verified cycle 11)" — cycle-18 missed this site.
5. `tech-debt.md` M5 entire premise FALSE: "258 lines (9.6% over 500-line target)" — 258 < 500.
6. `tech-debt.md` M1 header structurally broken; body treats settings..json as present file with effort "git rm".
7. `security-model.md` §1.2 header + body structurally broken — same pattern as tech-debt M1.
8. `external-sources.md` L61 absurd `258 (... was 258 ... was 258)` redundant parenthetical; L78+L93 same.
9. `feature-inventory.md` L48 Status Summary 14+6=20 vs table 25 rows.
10. `feature-inventory.md` L65 narrative "20-item inventory" vs disk 25 rows.
11. `INDEX.md` summaries cite stale primary content: triplication, x 4 trees, 20 features, 249 markdown files.
12. `INDEX.md` L30 work-001-aid-lite "Requirements approved" — CLAUDE.md confirms SHIPPED.
13. `README.md` L35 cites "20 features" — disk has 25.
14. `README.md` Completeness table stale to cycle-11 status text.

**MEDIUM (~10):**
- `api-contracts.md` L344+L358 IMPEDIMENT.md "118 lines" + ":114-118" (disk=116).
- `data-model.md` L201 IMPEDIMENT.md "(1-119)" (disk=116).
- `domain-glossary.md` L86 IMPEDIMENT.md "(1-118)" (disk=116).
- `project-index.md` L209 discovery-reviewer "381 lines" (disk=405; project-index not in primary 16 KB docs but referenced from KB).
- `tech-debt.md` L57 + L319 run_generator.py "~83 lines" (disk=84).
- `domain-glossary.md` L140 narrative awkward post-canonical-generator.
- `integration-map.md` L21 64 files vs 113 contradiction with project-structure.md.
- `integration-map.md` L60 discovery-reviewer.toml 314 (disk=399).
- `integration-map.md` L75 architect.toml 39 (disk=62).
- `integration-map.md` L110+L179 "353 files inventoried" (disk=631).

**LOW/MINOR (~14):** Pre-existing cycle-18 surviving cosmetic line-count drifts, stale "cycle-11 refresh 2026-05-23" pin dates, structural ordering (cycle-17 additions after Revision History), `host-tools-matrix.md` "repo repository" double-noun residual from cycle-18 typo fix.

## Cycle-19 Verification Spot-Checks (32 checks)

| # | Claim | Source | Verified | Evidence |
|---|-------|--------|----------|----------|
| C19-1 | canonical/skills/aid-init/SKILL.md = 119 lines | CLAUDE.md L65 + architecture.md L549 + module-map.md L64 | TRUE | disk=119 (wc -l) |
| C19-2 | canonical/skills/aid-discover/SKILL.md = 258 lines | architecture.md L283/L550 + module-map.md L65 + coding-standards.md L24 | TRUE | disk=258 |
| C19-3 | canonical/skills/aid-interview/SKILL.md = 357 lines | architecture.md L551 + module-map.md L66 | TRUE | disk=357 |
| C19-4 | canonical/skills/aid-specify/SKILL.md = 207 lines | architecture.md L552 + module-map.md L67 | TRUE | disk=207 |
| C19-5 | canonical/skills/aid-plan/SKILL.md = 208 lines | architecture.md L553 + module-map.md L68 | TRUE | disk=208 |
| C19-6 | canonical/skills/aid-detail/SKILL.md = 77 lines | architecture.md L554 + module-map.md L69 | TRUE | disk=77 |
| C19-7 | canonical/skills/aid-execute/SKILL.md = 279 lines | architecture.md L555 + module-map.md L70 | TRUE | disk=279 (canonical only — .claude profile shows 351 due to thin-router divergence; canonical is authoritative source) |
| C19-8 | canonical/skills/aid-deploy/SKILL.md = 147 lines | architecture.md L556 + module-map.md L71 | TRUE | disk=147 (canonical only — .claude profile shows 206 due to local edits ahead of canonical) |
| C19-9 | canonical/skills/aid-monitor/SKILL.md = 223 lines | architecture.md L557 + module-map.md L72 | TRUE | disk=223 |
| C19-10 | canonical/skills/aid-summarize/SKILL.md = 233 lines | architecture.md L558 + module-map.md L73 + ui-architecture.md L24 | TRUE | disk=233 (canonical); .claude profile = 230 (-3 drift) |
| C19-11 | methodology/aid-methodology.md = 1,071 lines | CLAUDE.md L8 + architecture.md L171 + project-structure.md L13 + feature-inventory.md L18 + module-map.md L33 | TRUE | disk=1,071 |
| C19-12 | run_generator.py = 84 lines | architecture.md L335 + coding-standards.md L49/L398 + module-map.md L23 + technology-stack.md L265 + infrastructure.md L29/L52/L274 + project-structure.md L29/L52 | TRUE | disk=84 (Pass 5E successfully unified) |
| C19-13 | tech-debt.md L57 + L319 cite run_generator.py "~83 lines" | tech-debt.md L57 + L319 | FALSE | disk=84 (Pass 5E missed tech-debt) |
| C19-14 | setup.sh = 162 lines | architecture.md L21/L177/L538 + project-structure.md L35/L55 + infrastructure.md L40/L42 + module-map.md L271 + api-contracts.md L13 + integration-map.md L172 + feature-inventory.md L32 + INDEX.md L21 + technology-stack.md L56 | TRUE | disk=162 |
| C19-15 | setup.ps1 = 157 lines | architecture.md L539 + project-structure.md L36/L55 + infrastructure.md L58/L60 + module-map.md L271 + api-contracts.md L13 + feature-inventory.md L32 + INDEX.md L21 + technology-stack.md L86 | TRUE | disk=157 |
| C19-16 | canonical/agents/discovery-reviewer/AGENT.md = 405 lines | (referenced from KB) | TRUE | disk=405 |
| C19-17 | project-index.md L209 cites discovery-reviewer/AGENT.md = 381 lines | project-index.md L209 | FALSE | disk=405; project-index is cycle-11 inventory, not refreshed (cite is 24 lines stale) |
| C19-18 | canonical/templates/work-state-template.md = 137 lines | data-model.md L24/L121 + architecture.md + module-map.md | TRUE | disk=137 (Pass 5D successfully unified) |
| C19-19 | IMPEDIMENT.md = 116 lines | architecture.md L319/L443 | TRUE in architecture.md (Pass 5K landed) | disk=116 |
| C19-20 | api-contracts.md L344 cites IMPEDIMENT.md "118 lines"; L358 cites ":114-118" | api-contracts.md L344+L358 | FALSE | disk=116; Pass 5K only fixed architecture.md, missed api-contracts |
| C19-21 | data-model.md L201 cites IMPEDIMENT.md "(1-119)" | data-model.md L201 | FALSE | disk=116 |
| C19-22 | domain-glossary.md L86 cites IMPEDIMENT.md "(1-118)" | domain-glossary.md L86 | FALSE | disk=116 |
| C19-23 | .gitignore = 47 lines, no bare ".aid/" entry | infrastructure.md L207 + security-model.md L249 + project-structure.md L41 + integration-map.md L170 + technology-stack.md L196 | TRUE | disk=47 (Pass 5H successfully unified; all 4 docs now correct) |
| C19-24 | .claude/skills/ byte-identical to canonical/skills/ post-thin-router | (user prompt assertion) | FALSE | aid-deploy .claude=206 vs canonical=147; aid-execute .claude=351 vs canonical=279; aid-interview .claude=347 vs canonical=357; aid-summarize .claude=230 vs canonical=233; aid-generate exists only in .claude. See Q210. |
| C19-25 | canonical/skills/aid-discover/SKILL.md = 258 across canonical + 3 profile trees | architecture.md L283 + module-map.md L315 | TRUE | disk=258 in all 4 locations |
| C19-26 | canonical/recipes/ contains 5 recipes + README + .gitkeep | data-model.md + integration-map.md + api-contracts.md + CLAUDE.md L79-82 | TRUE | disk: 5 recipe .md + README.md + .gitkeep |
| C19-27 | .claude/recipes/ contains 5 recipes + README (no .gitkeep) | (CLAUDE.md implied) | TRUE | disk: 5 recipe .md + README.md (no .gitkeep) |
| C19-28 | canonical/templates/dispatch-protocol-checklist.md exists | (referenced from CLAUDE.md indirectly) | TRUE | disk: exists, 48 lines |
| C19-29 | canonical/skills/aid-deploy/references/state-re-run.md exists | module-map.md L71 | TRUE | disk: exists, 18 lines |
| C19-30 | canonical/skills/aid-interview/references/ has 12 state-*.md files | module-map.md L66 says "13 state-*.md" with 12 names enumerated | FALSE on count | disk: 12 state-*.md files. Module-map says 13 — count is wrong by 1. |
| C19-31 | canonical/skills/aid-interview/scripts/ has 4 scripts | module-map.md L66 lists only 2 (parse-recipe + test-parse-recipe) | PARTIALLY FALSE | disk has 4: parse-recipe.sh, test-parse-recipe.sh, test-lite-subpaths.sh, test-lite-to-full-escalation.sh. Module-map omits 2. |
| C19-32 | canonical/skills/ aggregate: 92 .md files + 6 .sh scripts | module-map.md L48 says "7 references + 2 scripts" | FALSE | disk: 92 .md files, 6 .sh scripts. Off by 13x on references and 3x on scripts. Cycle-18 deferred; cycle-19 confirms STILL WRONG. |

**Cycle-19 spot-check summary:** 32 checks. **27 TRUE / 4 FALSE / 1 PARTIALLY-FALSE = 84% pass rate.** Up from cycle-18 baseline of 62%.

**The remaining 16% of failures are concentrated in:**
- module-map.md aggregate counts (Cycle-18 deferred — needs disk recount + table rewrite)
- IMPEDIMENT.md line cites in 3 docs missed by Pass 5K (api-contracts, data-model, domain-glossary)
- project-index.md and tech-debt.md secondary cite sites missed by Pass 5C/5E
- Dogfood `.claude/skills/` divergence from canonical for 5 skills — see Q210

## Cross-Cutting Concerns (cycle-19)

1. **Cycle-18 FIX-pass Pass 5A-5L was BROADLY EFFECTIVE.** Pass 5A stripped all "(line cite stripped...)" tombstones; Pass 5B cleared 596/548; Pass 5C fixed discovery-reviewer 381→405 in 3 docs; Pass 5D unified work-state-template 137 across 4 docs; Pass 5E unified run_generator.py 84 across 8 docs; Pass 5F unified setup.sh/ps1 162/157 across 8 docs; Pass 5G fixed methodology 1,158→1,071 in tech-debt; Pass 5H swept .gitignore "single line" claims; Pass 5I fixed concatenation typo; Pass 5K fixed IMPEDIMENT.md in architecture.md.

2. **But Pass 5K was INCOMPLETE.** IMPEDIMENT.md was unified from 118→116 only in architecture.md. Same drift survives in api-contracts.md L344+L358 (118 + :114-118), data-model.md L201 (1-119), domain-glossary.md L86 (1-118).

3. **Pass 5C was INCOMPLETE.** discovery-reviewer 381 was fixed in 3 docs but project-index.md L209 (the source-of-truth inventory) STILL cites 381 — meaning the next regeneration of summaries from project-index will re-propagate the stale number.

4. **Pass 5E was INCOMPLETE.** run_generator.py 84 lines was unified across 8 docs but tech-debt.md L57 + L319 still cite "~83 lines" (2 sites missed).

5. **Cycle-18 explicitly-deferred items remain unfixed (confirmed cycle-19):**
   - module-map.md L48 aggregate references/scripts count "wildly wrong" — disk 92 .md + 6 .sh vs claim 7+2.
   - security-model.md §1.2 structural rewrite needed — header + body still treat the deleted settings..json as present (12 lines of analysis on a non-file).
   - tech-debt.md M1 same structural break as security-model §1.2.
   - INDEX.md feature count "20" should be "25" + triplication/x4-trees/249 Markdown narrative refresh.
   - README.md Completeness table cycle-11 vintage including "20 features" and work-001 "Requirements approved" (work-001 SHIPPED per CLAUDE.md).
   - verify-kb-claims.sh pattern broadening (Q205) — still cannot catch in-narrative drifts.

6. **NEW mathematical contradiction surfaced:** tech-debt.md M5 says "258 lines (9.6% over)" the "Under 500 lines" guideline. 258 < 500 — there is NO violation. The whole M5 entry should be RETIRED, not perpetuated. Architecture.md L288 propagates the same false claim. This is a long-standing residual from pre-thin-router KB drift; the refactor inverted M5's mathematical premise.

7. **NEW disk truth surfaced:** The user's prompt asserted ".claude/skills/aid-*/SKILL.md byte-identical post-thin-router refactor" with specific line counts. Cycle-19 wc -l shows .claude profile has DIVERGENCE: aid-deploy 206 (canonical=147), aid-execute 351 (canonical=279), aid-interview 347 (canonical=357), aid-summarize 230 (canonical=233), aid-generate 261 (no canonical equivalent). The dogfood `.claude/` tree is AHEAD of `canonical/` in some skills and BEHIND in others — `run_generator.py` has not been re-run after recent canonical edits, OR there are live unmerged edits in the dogfood profile. The KB asserts byte-identity (e.g., architecture.md L283: "All three profile trees ship 258 lines each"); this is TRUE for aid-discover but FALSE for aid-deploy, aid-execute, aid-interview, aid-summarize in the dogfood `.claude/` tree. Production `profiles/{claude-code,codex,cursor}/` are not verified in this review (only `.claude/` dogfood was sampled). See Q210.

8. **Pass rate trajectory:** Cycle-17 = 29% → Cycle-18 = 62% → Cycle-19 = 84%. Real progress, but the **C+** grade reflects 14 surviving HIGH issues that are MOSTLY in the meta-document layer (INDEX, README, feature-inventory status summary) and 2-3 surviving structural rewrites (tech-debt M1/M5, security-model §1.2) that need authoring effort, not regex sweeps.

## Q&A

> Cycle-19 preserves Q190-Q208 from cycle-18 (all marked Answered or Pending per cycle-18). Adds Q209-Q211 for new gaps surfaced by this review.

### Q190-Q208
- (preserved from cycle-18 — Q190-Q204 historical; Q205-Q208 are cycle-18 retrospective entries)

### Discovery — Review Cycle 2 (cycle-19 adversarial re-grade)

### Q209: [Knowledge Base: High] Should tech-debt.md M5 ("aid-discover SKILL.md violates Under 500 lines") be RETIRED given disk = 258 < 500?
**Status:** Pending
**Context:** Post-thin-router refactor (work-001 PR #13), canonical/skills/aid-discover/SKILL.md is 258 lines (verified `wc -l`). The "Under 500 lines per skill (AgentSkills best practice)" guideline from CONTRIBUTING.md:97 is SATISFIED (258 < 500). But tech-debt.md M5 L190-198 still says "violates ... actual 258 lines (9.6% over)" — mathematically false. The same false premise propagates to architecture.md L288 ("at 258 lines still exceeds the 500-line target"). Either (a) the guideline target is different from 500 (and we should fix the doc), or (b) M5 should be marked RESOLVED with note "thin-router refactor brought all skills under 500 lines".
**Suggested:** Mark M5 as RESOLVED in cycle-19+ FIX pass. Update architecture.md L288 to acknowledge resolution. Update tech-debt §H/M/L category counts.

### Q210: [Knowledge Base: High] Why does the dogfood `.claude/skills/` tree diverge from `canonical/skills/` for 5 skills?
**Status:** Pending
**Context:** Disk `wc -l` 2026-05-25 shows:
- aid-deploy: .claude=206 / canonical=147 (.claude ahead by 59 lines)
- aid-execute: .claude=351 / canonical=279 (.claude ahead by 72 lines)
- aid-interview: .claude=347 / canonical=357 (.claude behind by 10 lines)
- aid-summarize: .claude=230 / canonical=233 (.claude behind by 3 lines)
- aid-generate: .claude=261 / canonical does not exist (.claude has skill not yet promoted to canonical)

KB asserts byte-identity across canonical + 3 profile trees (architecture.md L283, coding-standards.md L24, module-map.md L315). The user's prompt asserted disk truth "SKILL.md line counts (canonical/ + 3 profiles, byte-identical post-thin-router)" — this is true for aid-discover (258 everywhere) but contradicted by the 5 cases above. Either `run_generator.py` has not been re-run since recent edits, OR the dogfood `.claude/` has uncommitted local edits ahead of canonical.

**Suggested:** Run `python run_generator.py` and compare. If divergence persists, identify which tree is the source-of-truth (likely canonical/) and revert `.claude/` to generator output. If `.claude/` has intentional edits not yet upstreamed, promote them to `canonical/` first, then re-render.

### Q211: [Knowledge Base: Medium] Should the structurally-broken header pattern "X (the historical Y was removed; see Z) ... continues to describe X as present" be globally swept?
**Status:** Pending
**Context:** The injection of "(the historical double-dot typo file `.claude/settings..json` was removed; see `project-structure.md` Anomaly #2)" appears as a nested-parenthetical INSIDE the section header in 3 places: `security-model.md §1.2` ("### 1.2 The `.claude/settings.json` (the historical ... was removed ...) Double-Dot File"), `tech-debt.md M1` ("### [MEDIUM] M1 — `.claude/settings.json` (the historical ... was removed ...) filename typo"), `technology-stack.md` L184. After the header, the body continues to describe the file as if present (diff commands, "git rm" effort estimates, "is committed"). The intent was clearly to mark the section as obsolete; the result is an incoherent half-fix.

**Suggested:** Either (a) DELETE these 3 sections entirely with a single-line tombstone "M1 — RETIRED (file removed 2026-05-XX, see project-structure.md Anomaly #2 history)", or (b) rewrite each section to be past-tense throughout ("M1 was a typo committed at 2026-05-XX, removed 2026-05-XX, no longer applicable"). Current half-fix is worse than either alternative.

---

## Cycle-19 FIX-Pass Recommendation

**Trigger:** Cycle-19 reviewer found Grade **C+** — pass rate 84% (up from 62% cycle-18, 29% cycle-17). 14 surviving HIGH issues, 10 MEDIUM, ~14 LOW/MINOR. 0 CRITICAL — Pass 5A-5L cleared all 3 cycle-18 CRITICAL drifts.

**Targeted Pass-6 cleanup (mechanical, ~1-2h):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 6A | IMPEDIMENT.md 118/119 → 116 in api-contracts/data-model/domain-glossary | 3 sites |
| 6B | run_generator.py 83 → 84 in tech-debt.md L57+L319 | 2 sites |
| 6C | discovery-reviewer 381 → 405 in project-index.md L209 | 1 site |
| 6D | technology-stack.md L322 "548 lines for aid-discover" → 258 | 1 site |
| 6E | external-sources.md L61/L78/L93 strip redundant "was 258 ... was 258" parentheticals | 3 sites |
| 6F | feature-inventory.md L48 Status Summary count 14→19 (or whatever the 25-row reality is); L65 narrative "20-item" → "25-item" | 3 sites |
| 6G | INDEX.md row summaries refresh: triplication → canonical-generator; x 4 trees → canonical + 3 profiles; 20 features → 25; 249 Markdown → current count; work-001 "Requirements approved" → "SHIPPED" | 7 sites |
| 6H | README.md Completeness table refresh: cycle-11 status text → cycle-17/18/19; 20 features → 25; Active Works status updates | 6 sites |
| 6I | host-tools-matrix.md L122 "repo repository" → "repo"; L143 DISCOVERY-STATE.md → STATE.md | 2 sites |
| 6J | ui-architecture.md L286 SUMMARY-STATE.md → STATE.md | 1 site |
| 6K | tech-debt.md M5 + architecture.md L288: RETIRE M5 with disk-truth note (258 < 500) | 2 sites |

**Structural rewrites (NOT mechanical, ~2-3h authoring):**

| Sub-pass | Scope | Approach |
|----------|-------|----------|
| 6L | security-model.md §1.2 + tech-debt.md M1 settings..json structural half-fix | DELETE or rewrite past-tense (Q211) |
| 6M | module-map.md L48-51 aggregate counts + L66 enumeration | Recount disk (find canonical/skills -name *.md \| wc -l = 92; -name *.sh = 6); rewrite per-skill table to enumerate ALL files, not subset |

**Expected post-Pass-6 grade:** B+ to A- (target). To reach A+, also: refresh project-index.md (regenerate via `bash canonical/templates/scripts/build-project-index.sh`); resolve Q210 (run_generator.py + diff); revisit M5 retirement.

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2-15 | 2026-05-21 to 2026-05-23 | (D- to A+ to C to A) | aid-discover cycles 2-15 | Cycle-14 reviewer found 8 HIGH from subagent-visibility-patch; cycle-15 orchestrator self-attestation Grade A. |
| 16 | 2026-05-23 | A | orchestrator self-attestation post cycle-14 fix-pass | Applied 19 line-count drift fixes; fixed false .gitignore claim; verify-kb-claims.sh exit 0. Self-attestation only. |
| 17 | 2026-05-25 | **D** | post-work-001-merge fresh adversarial (clean-context) | PR #13 work-001 thin-router refactor invalidated KB line counts across 12+ docs by 30-77%. 7 NEW CRITICAL · 35+ NEW HIGH · 25+ NEW MEDIUM · 10+ NEW LOW/MINOR. Pass rate 29%. Triggered cycle-17 FIX-pass. |
| 18 | 2026-05-25 | **D** | post-cycle-17-FIX re-grade | Cycle-17 FIX-pass cleared dominant SKILL.md drift in primary docs. Pass rate 29%→62%. CLAUDE.md fully rewritten (A). Recipes catalog, Thin-Router convention, Canonical Script Tests sections added. But: 3 CRITICAL residual drifts survive cycle-17 (architecture.md L175 "596 lines"; api-contracts.md L70+L205 "596 lines each"; host-tools-matrix.md L38 "548 lines"). 35+ HIGH issues. Triggered cycle-18 Pass 5A-5L FIX-pass. |
| 19 | 2026-05-25 | **C+** | post-cycle-18-FIX re-grade | Cycle-18 Pass 5A-5L was BROADLY EFFECTIVE: all 3 CRITICAL aid-discover 596/548 cites GONE (Pass 5B); all 7 "(line cite stripped...)" tombstones GONE (Pass 5A); .gitignore "single line .aid/" claims unified to "47 lines" across 4 docs (Pass 5H); run_generator.py = 84 unified across 8 docs (Pass 5E); setup.sh = 162 + setup.ps1 = 157 unified across 8 docs (Pass 5F); work-state-template = 137 unified across 4 docs (Pass 5D); discovery-reviewer 381 → 405 in 3 docs (Pass 5C); methodology 1,158 → 1,071 fixed (Pass 5G); concatenation typo fixed (Pass 5I); IMPEDIMENT.md 118 → 116 in architecture.md (Pass 5K). Pass rate 62%→84%. **0 CRITICAL surviving.** But 14 HIGH surviving: (i) module-map.md L48 aggregate counts "wildly wrong" (cycle-18 deferred; disk 92 .md + 6 .sh vs claim 7+2); (ii) module-map.md L51 "only embedded scripts" FALSE (aid-interview has 4); (iii) module-map.md L66 count "13 state-*" vs 12 enumerated (disk=12); (iv) technology-stack.md L322 "548 lines for aid-discover" survived; (v) tech-debt.md M5 entire premise FALSE ("258 lines 9.6% over 500" — 258 < 500; architecture.md L288 propagates); (vi) tech-debt.md M1 + security-model.md §1.2 structurally-broken nested-parenthetical headers describing deleted settings..json as present; (vii) external-sources.md L61/L78/L93 "258 (... was 258 ... was 258)" absurd redundant parentheticals; (viii) feature-inventory.md L48 Status Summary 14+6=20 vs table 25 rows; L65 narrative "20-item" vs 25; (ix) INDEX.md + README.md NOT refreshed (still cite 20 features, triplication, x 4 trees, "Markdown 249 files", work-001 "Requirements approved"); (x) Pass 5K incomplete — IMPEDIMENT.md still 118/119 in api-contracts/data-model/domain-glossary; (xi) Pass 5C incomplete — project-index.md L209 still 381; (xii) Pass 5E incomplete — tech-debt.md L57+L319 still 83. NEW findings: dogfood `.claude/skills/` divergence from canonical for 5 skills (Q210); structurally-broken settings..json header pattern (Q211); M5 mathematical contradiction (Q209). 3 new Q-entries added (Q209-Q211). **RECOMMENDATION:** Pass-6 mechanical sweep (~1-2h: 6A-6K, ~30 sites) + Pass-6 structural rewrite (~2-3h: 6L-6M, security-model §1.2 + tech-debt M1 + module-map.md L48-66). Then refresh INDEX.md + README.md against current primaries. Expected post-Pass-6 grade: B+ to A-. |
