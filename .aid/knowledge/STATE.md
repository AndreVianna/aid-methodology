# Discovery State

> **Status:** Approved (re-grade pending after cycle-17 review identified massive post-work-001-merge drift)
> **Minimum Grade:** A+
> **Current Grade:** D (cycle-17 adversarial post-work-001-merge review, 2026-05-25) — the work-001 thin-router refactor (PR #13) cut ALL 10 SKILL.md bodies by 30-77% but the KB was not refreshed; every line-count citation across 12+ KB docs is now wrong. New post-merge artifacts (5 recipes, 4 new canonical scripts, 2 e2e runners, 5 task-NNN test reports, ~22 new skill `references/state-*.md` files, `dispatch-protocol-checklist.md`) are completely unmentioned. CLAUDE.md still carries `(pending discovery)` placeholders. Cycle-15 self-attestation grade A is **refuted**.
> **User Approved:** yes (2026-05-21) — **stale; predates work-001/work-002/work-003 deploys**
> **Heartbeat Interval:** 1 minute
> **Max Parallel Tasks:** 5
> **Last KB Review:** 2026-05-25 (cycle 17, post-work-001-merge adversarial)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary.

## Cycle-17 Per-Document Grades

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| project-structure.md | C+ | Below minimum | [HIGH] aid-discover/SKILL.md L99/L277 cites 548 lines (disk=258). [MEDIUM] L29/L52/L213 cite run_generator.py 82 lines (disk=84). [LOW] L218 docs/glossary.md=80 lines unverified. [MINOR] L194/L199 knowledge-summary script lists not refreshed for new work-001 scripts. |
| external-sources.md | D | Below minimum | [HIGH] L61 SKILL.md=596 (disk=258). [HIGH] L78 Codex SKILL.md=548 (disk=258). [HIGH] L93 Cursor SKILL.md=548 (disk=258). [HIGH] L60 discovery-reviewer.md=381 (disk=405). [MEDIUM] 8 vendor URLs "Pending fetch" since 2026-05-21 still unfetched. |
| architecture.md | D- | Below minimum | [CRITICAL] §7.2 table L549-558: ALL 10 SKILL.md line counts wrong by 30-77% (aid-init 531 vs 119; aid-discover 596 vs 258; aid-interview 527 vs 357; aid-specify 442 vs 207; aid-plan 360 vs 208; aid-detail 417 vs 77; aid-execute 512 vs 279; aid-deploy 359 vs 147; aid-monitor 333 vs 223; aid-summarize 545 vs 233). [HIGH] §2.2 L174-175 cites 596 lines (disk=258). [HIGH] L282-288 Pattern 3 cites 596 (disk=258). [HIGH] L177 setup.sh=161 (disk=162); setup.ps1=156 (disk=157). [MEDIUM] L541 still cites "DISCOVERY-STATE.md Q2" (pre-FR2). [MEDIUM] L611 still cites "9 phases" / loop-count narrative obsolete. |
| technology-stack.md | D- | Below minimum | [CRITICAL] L25 methodology=1,158 (disk=1,071, off by 87). [CRITICAL] L184 settings..json typo file referenced as present — project-structure.md L272 says cleaned up. [HIGH] L66 writeback-state.sh "139 canonical / 173 per-profile" (disk shows canonical=173 single value). [HIGH] L196 + L353 ".gitignore: one line .aid/" (disk=44 lines, no bare .aid/). [MEDIUM] L17 markdown 249 files (project-structure.md says 472). [MEDIUM] L48 shell 43 files, 5,490 lines (project-structure.md says 76 files, 13,957 lines). [LOW] L254 run_generator.py 83 lines (disk=84). [MEDIUM] §12.0 worker-script table omits 4 NEW work-001 scripts (complexity-score.sh, compute-block-radius.sh, test-pool-dispatch.sh, writeback-task-status.sh). |
| module-map.md | E | Below minimum | [CRITICAL] Module 2 L49 ALL 10 SKILL.md line counts wrong (4,212 total claimed, disk=2,108 — off by 100%). [CRITICAL] L64-73 per-skill table all 10 wrong. [CRITICAL] L85/L101/L117 Modules 3/4/5 cite 4,412 total — same drift propagated 4x. [CRITICAL] L134 discovery-reviewer/AGENT.md 381 (disk=405). [HIGH] L315 Canonical-to-Profile row cites 548 four times (disk=258). [HIGH] L48 "32 across 10 skill folders ... 7 references/*.md" (disk shows aid-discover alone has 9 references; aid-execute 6; aid-detail 4; aid-deploy 5 — total much higher). [HIGH] L51 "the only embedded scripts" is FALSE (aid-interview now has 4 scripts incl. parse-recipe.sh). |
| coding-standards.md | D | Below minimum | [HIGH] L24 "aid-discover/SKILL.md is 596 lines in all 4 locations" (disk=258). [HIGH] L47 example "SKILL.md (596 lines)" (disk=258). [HIGH] L49 "wc -l aid-discover/SKILL.md returns 596" (disk=258). [HIGH] L396 cites pre-canonical 244/453/1078/1090 narrative — should be retired. [MEDIUM] L440 cycle-11 change log entry references 548 lines (now 258). [MEDIUM] L49 run_generator.py 83 lines (disk=84). [HIGH] No section documenting the thin-router/state-*.md decomposition convention introduced by work-001 (see Q201). |
| data-model.md | C+ | Below minimum | [MEDIUM] L22 discovery-state-template.md "85 lines" unverified. [MEDIUM] L24 work-state-template.md "116 lines" unverified. [MEDIUM] Recipes catalog (work-001) not in §1 artifact inventory. [MEDIUM] Test reports (.aid/work-NNN/test-reports/) not in §1 inventory. |
| api-contracts.md | D+ | Below minimum | [HIGH] L48 "discovery-reviewer.md 381 lines" (disk canonical=405). [HIGH] L70 "596 lines each for aid-discover" (disk=258). [HIGH] L205 "596 lines each" (disk=258). [MEDIUM] No recipe-file format contract (see Q204). [LOW] L94 cited aid-discover SKILL.md:533-542 — SKILL.md is now only 258 lines total. |
| integration-map.md | C+ | Below minimum | [MEDIUM] L21 "profiles/claude-code/.claude/ (64 files)" — project-structure.md says profiles/claude-code/=113 files. [MEDIUM] L60 discovery-reviewer.toml 314 unverified. [LOW] L75 architect.toml=39 lines unverified. [MEDIUM] No section for recipes (new integration surface). |
| domain-glossary.md | D+ | Below minimum | [HIGH] L140 "Skill body drift" entry cites "596 lines across all 3 trees" (disk=258). [HIGH] L164 "Worktree" entry cites cwd `.claude\worktrees\aid-init` (current cwd is repo root). [HIGH] L157 "Triplication" definition still says "with no propagation tooling" (RETIRED post-work-002). [MEDIUM] L133/L134/L151 cite DISCOVERY-STATE.md / task-NNN-STATE.md (retired per FR2). [MEDIUM] L148 task-template.md "(142 lines)" unverified. [LOW] Missing terms for work-001: thin-router, recipe, lite path, two-tier review, parallel pool dispatch, block radius, complexity score, delivery gate. |
| test-landscape.md | D | Below minimum | [CRITICAL] L10 "353 files, 49,226 lines; 70.6% Markdown" — disk per project-structure.md L267 says 631 files, 90,011 lines (100% off). [HIGH] No mention of 4 new test scripts (test-compute-block-radius.sh, test-pool-dispatch.sh, test-delivery-gate-aggregate.sh, test-writeback-task-status.sh) shipped under canonical/templates/scripts/. [HIGH] No mention of 2 e2e runner scripts in .aid/work-001/test-reports/. [HIGH] L126 "aid-discover 548 lines, 9.6% over 500-line guideline" — disk=258, now well UNDER guideline (M5 narrative obsolete). [MEDIUM] L31 "only file matching *test* is template" — FALSE (now multiple test-*.sh scripts). |
| security-model.md | C+ | Below minimum | [MEDIUM] L31-37 cites .claude/settings.json content with 6 entries — needs re-verification post-work-001. [MEDIUM] L53-62 settings..json double-dot analysis stale (project-structure.md L272 says cleaned up). [MEDIUM] L60 discovery-reviewer.md "381 lines" (disk canonical=405). [LOW] L69 operator.toml 38 lines unverified. [LOW] L74 developer.toml 17 lines unverified. [LOW] Recipes pattern introduces new prompt-injection surface — not assessed. |
| tech-debt.md | D | Below minimum | [HIGH] H1 L22 "548 lines four times" (disk=258 four times). [HIGH] L65-73 H4 4-way duplication math obsolete — canonical/templates/scripts/ now has 10 distinct scripts (4 new work-001 ones); needs full refresh. [HIGH] M5 (line-count guideline) "aid-discover/SKILL.md 596 lines, 19.2% over 500-line target" — disk=258, now well UNDER. M5 should be RETIRED. [HIGH] Thin-router refactor (work-001 feature-002) achieved exactly what H3/H4/M5 wanted (smaller bodies, better decomposition) — none of this reflected in tech-debt narrative. [MEDIUM] No mention of work-001 deliverables resolving multiple debt items. |
| infrastructure.md | C | Below minimum | [MEDIUM] L31 run_generator.py "~83 lines" (disk=84). [MEDIUM] L40 setup.sh "Bash, 161 lines" (disk=162). [MEDIUM] L58 setup.ps1 "PowerShell, 156 lines" (disk=157). [MEDIUM] L275 "aid-discover/SKILL.md and 3 profile copies = 548 lines" (disk=258). [LOW] L25 branch "master" — current branch is work-001 per git status (clarify default branch vs current branch). |
| ui-architecture.md | C+ | Below minimum | [HIGH] L24 aid-summarize SKILL.md "430 / 436 / 436 lines" (disk shows 233 across all 4 trees, no drift). [MEDIUM] L17 "25 files" — project-structure.md L192-194 says ~30 files. [MEDIUM] L32 html-skeleton.html 101 lines unverified. [MEDIUM] L101/L319 still cite "DISCOVERY-STATE.md Q14" (pre-FR2 name; cycle-12 finding was supposed to be fixed). |
| feature-inventory.md | E | Below minimum | [CRITICAL] No work-001 features in 20-item inventory. Work-001 shipped (per task prompt): feature-002 (thin-router), feature-004 (two-tier review), feature-005 (parallel pool dispatch), feature-009 (lite path), plus 5 production recipes — none listed. Inventory should be ~24-25. [HIGH] L18 methodology=1,158 (disk=1,071). [HIGH] L36 FR1 heartbeat row cites per-skill marker counts (aid-deploy=6, aid-discover=6, etc.) — most markers now in references/state-*.md not in SKILL.md. [MEDIUM] L43 "14 Shipped" needs recount. |
| INDEX.md | D+ | Below minimum | [HIGH] L11 "Markdown (249 files), Shell (43)" contradicts project-structure.md L234-235 (472 / 76). [HIGH] L17 "151 alphabetically-sorted terms" — count correct but term-list itself missing work-001 terms (thin-router, recipe, lite-path, etc.). [MEDIUM] L10 "8 patterns identified" needs recount post-work-001. [MEDIUM] L23 "20 features" — should be ~24-25. [MEDIUM] No Active Works section here (only in README). |
| README.md | D | Below minimum | [HIGH] L20 project-structure.md row "SKILL.md 548-line parity verified" (disk parity at 258). [HIGH] L26 coding-standards.md row "§1.3 rewritten around canonical-generator (548-everywhere)" stale. [MEDIUM] L23 architecture.md "619 lines" (disk=620). [MEDIUM] L27 data-model.md "494 lines" (disk=498). [MEDIUM] L31 work-001-aid-lite "4 features specified" — work-001 SHIPPED per task prompt (PR #13 merged); status stale. [MEDIUM] No work-001 row in revision history. |
| host-tools-matrix.md | C | Below minimum | [HIGH] L38 aid-discover "548 / 548 / 548" (disk=258). [HIGH] L94 "596 lines across all 3 trees" (disk=258). [HIGH] L39-46 per-skill line counts claim drift between trees (Claude 477 / Codex 694 / Cursor 698 etc.) — all 3 trees are byte-identical at the smaller post-thin-router values. [HIGH] L67 "Codex/Cursor inline → 2.4× line count" narrative is RETIRED. [HIGH] L122 "~17,600 lines = ~36% of 49,226-line repo" — disk shows 90,011 lines (README L13). |
| CLAUDE.md (project root) | F | Below minimum | [CRITICAL] L4 `<!-- AID-DISCOVER — Replace with project name and one-line description -->` placeholder PRESENT. [CRITICAL] L5 `(pending discovery)` placeholder PRESENT despite Discovery being Approved since 2026-05-21. [HIGH] L29 `<!-- AID-DISCOVER — Replace with key conventions summary -->` placeholder PRESENT. [MEDIUM] L8-15 generic KB pointer; no project-specific architecture summary. [MEDIUM] No mention of run_generator.py / canonical-generator workflow. [MEDIUM] No `## Build & Test` section. |

## Cycle-17 Findings — Summary by Severity

**CRITICAL (7):**
1. **architecture.md §7.2 line-count table** — all 10 entries wrong by 30-77%. Agents reading this canonical table will believe SKILL.md is 2-3x its actual size.
2. **module-map.md Modules 2/3/4/5** — total of 4,212/4,412 SKILL.md lines; disk total = 2,108. 50% drift propagated 4x.
3. **technology-stack.md L25** — methodology=1,158 lines; disk=1,071. Contradicts project-structure.md L13 (which has correct 1,071).
4. **technology-stack.md L184** — claims `.claude/settings..json` double-dot typo exists; project-structure.md L272 says cleaned up. Self-contradictory KB.
5. **test-landscape.md L10** — "353 files, 49,226 lines" matches a pre-work-002 inventory; current disk = 631 files / 90,011 lines.
6. **feature-inventory.md** — missing all 5 work-001 features (thin-router, two-tier review, parallel pool, lite path, recipes).
7. **CLAUDE.md** — `(pending discovery)` placeholder still present; this is the project-context file every Claude Code session loads first.

**HIGH (35+):** see per-doc table. Bulk are SKILL.md line-count citations broken by thin-router refactor; also missing-work-001-artifact mentions across multiple docs.

**MEDIUM (25+):** stale FR2 file-name references, stale .gitignore claims, missing work-001 artifacts in data-model/api-contracts/integration-map, missing domain-glossary terms.

**LOW/MINOR (10+):** off-by-1 line counts (162 vs 161, 84 vs 83), un-spot-checked specific files.

## Cycle-17 Verification Spot-Checks (45 checks, post-work-001-merge)

| # | Claim | Source | Verified | Evidence |
|---|-------|--------|----------|----------|
| C17-1 | canonical/skills/aid-init/SKILL.md = 531 lines | architecture.md L549 | FALSE | disk=119 (77% smaller after thin-router) |
| C17-2 | canonical/skills/aid-discover/SKILL.md = 596 lines | architecture.md L550 + coding-standards L24/L47/L49 + 6 other docs | FALSE | disk=258 (57% smaller) |
| C17-3 | canonical/skills/aid-interview/SKILL.md = 527 lines | architecture.md L551 + module-map L66 | FALSE | disk=357 (32% smaller) |
| C17-4 | canonical/skills/aid-specify/SKILL.md = 442 lines | architecture.md L552 + module-map L67 | FALSE | disk=207 (53% smaller) |
| C17-5 | canonical/skills/aid-plan/SKILL.md = 360 lines | architecture.md L553 + module-map L68 | FALSE | disk=208 (42% smaller) |
| C17-6 | canonical/skills/aid-detail/SKILL.md = 417 lines | architecture.md L554 + module-map L69 | FALSE | disk=77 (81% smaller — most dramatic) |
| C17-7 | canonical/skills/aid-execute/SKILL.md = 512 lines | architecture.md L555 + module-map L70 | FALSE | disk=279 (46% smaller) |
| C17-8 | canonical/skills/aid-deploy/SKILL.md = 359 lines | architecture.md L556 + module-map L71 | FALSE | disk=147 (59% smaller) |
| C17-9 | canonical/skills/aid-monitor/SKILL.md = 333 lines | architecture.md L557 + module-map L72 | FALSE | disk=223 (33% smaller) |
| C17-10 | canonical/skills/aid-summarize/SKILL.md = 545 lines | architecture.md L558 + ui-architecture L24 | FALSE | disk=233 (57% smaller) |
| C17-11 | All 3 profile trees byte-identical to canonical | module-map L85 + multiple | TRUE | canonical=2,108; claude-code=2,108; codex=2,108; cursor=2,108 |
| C17-12 | methodology/aid-methodology.md = 1,158 lines | technology-stack L25 + feature-inventory L18 | FALSE | disk=1,071 |
| C17-13 | methodology/aid-methodology.md = 1,071 lines | architecture.md L171 + project-structure.md L13/L30/L51/L212 | TRUE | disk=1,071 (architecture/project-structure correct; technology-stack/feature-inventory wrong) |
| C17-14 | canonical/agents/discovery-reviewer/AGENT.md = 381 lines | api-contracts L48 + external-sources L60 + security-model L60 | FALSE | disk=405 |
| C17-15 | run_generator.py = 83 lines | technology-stack L254 + coding-standards L49 + tech-debt L22 + module-map L23 | FALSE | disk=84 |
| C17-16 | run_generator.py = 82 lines | project-structure.md L29/L52/L213 | FALSE | disk=84 |
| C17-17 | setup.sh = 161 lines | architecture.md L177 + infrastructure.md L40 + multiple | FALSE | disk=162 |
| C17-18 | setup.ps1 = 156 lines | architecture.md L177 + infrastructure.md L58 | FALSE | disk=157 |
| C17-19 | canonical/templates/knowledge-summary/scripts/writeback-state.sh = 173 lines | project-structure.md L60 | TRUE | disk=173 |
| C17-20 | canonical/templates/scripts/grade.sh = 141 lines | technology-stack.md L58 + multiple | TRUE | disk=141 |
| C17-21 | canonical/templates/scripts/build-project-index.sh = 368 lines | many | TRUE | disk=368 |
| C17-22 | canonical/templates/scripts/verify-kb-claims.sh exists | project-structure.md L58 | TRUE | disk=356 lines, present |
| C17-23 | NEW: canonical/templates/scripts/complexity-score.sh (work-001) | KB silence | TRUE | disk=209 lines, unmentioned in any KB doc |
| C17-24 | NEW: canonical/templates/scripts/compute-block-radius.sh (work-001) | KB silence | TRUE | disk=293 lines, unmentioned |
| C17-25 | NEW: canonical/templates/scripts/test-pool-dispatch.sh (work-001) | KB silence | TRUE | disk=153 lines, unmentioned |
| C17-26 | NEW: canonical/templates/scripts/writeback-task-status.sh (work-001) | KB silence | TRUE | disk=627 lines (largest new), unmentioned |
| C17-27 | NEW: canonical/recipes/ (5 recipes + README) | KB silence | TRUE | add-crud-endpoint.md, add-unit-test.md, bug-fix.md, method-refactor.md, write-release-note.md, README.md — zero KB references |
| C17-28 | NEW: .claude/recipes/ catalog | KB silence | TRUE | same 6 files; runner is canonical/skills/aid-interview/scripts/parse-recipe.sh — unmentioned |
| C17-29 | NEW: aid-discover/references/state-*.md (6 NEW files) | KB silence | TRUE | state-{approval,done,fix,generate,q-and-a,review}.md — module-map L48 says "7 references/*.md" but disk shows 9 |
| C17-30 | NEW: aid-deploy/references/state-*.md (5 NEW files) | KB silence | TRUE | state-{idle,packaging,re-run,selecting,verifying}.md — unmentioned |
| C17-31 | NEW: aid-detail/references/state-*.md (4 NEW files) | KB silence | TRUE | execution-graph-generation.md, first-run.md, review.md, task-decomposition.md |
| C17-32 | NEW: aid-execute/references/state-*.md (5 NEW files) | KB silence | TRUE | state-{delivery-gate,execute,fix,re-run,review}.md |
| C17-33 | NEW: aid-interview/scripts/{parse-recipe,test-*}.sh (4 NEW scripts) | KB silence | TRUE | module-map L51 says aid-discover scripts are "the only embedded scripts" — FALSE |
| C17-34 | NEW: canonical/templates/dispatch-protocol-checklist.md | KB silence | TRUE | present, unmentioned in KB |
| C17-35 | .gitignore is "single line .aid/" | technology-stack L196/L353 + architecture L19/L200 | FALSE | disk=44 lines, no bare .aid/ |
| C17-36 | domain-glossary.md = 151 terms | domain-glossary L6 + INDEX L17 + README L30 | TRUE | grep -c = 151 |
| C17-37 | feature-inventory.md = 20 features (completeness) | feature-inventory L43 + INDEX L23 + README L35 | TRUE on count, WRONG on completeness | disk has 20 rows but missing work-001 features (~4-5) |
| C17-38 | tech-debt.md HIGH count = 8 (4 OPEN + 4 RETIRED) | tech-debt + INDEX L20 | TRUE on count, STALE on labels | M5 should now be RETIRED (thin-router resolves it) |
| C17-39 | CLAUDE.md has no "(pending discovery)" placeholder | task prompt expectation | FALSE | L5 has "(pending discovery)"; L4 + L29 have AID-DISCOVER placeholders |
| C17-40 | profiles/claude-code/.claude/skills/aid-discover/SKILL.md byte-identical to canonical | module-map L75 | TRUE | both = 258 lines |
| C17-41 | aid-discover/references/agent-prompts.md = 142 lines | module-map L50/L65 + architecture L282 + coding-standards L47 | TRUE | disk=142 (survives thin-router) |
| C17-42 | aid-discover/references/document-expectations.md = 121 lines | module-map L65 + coding-standards L47 | TRUE | disk=121 |
| C17-43 | aid-discover/references/reviewer-prompt.md = 75 lines | module-map L65 + coding-standards L47 | TRUE | disk=75 |
| C17-44 | aid-init/SKILL.md cited as 513 lines / 6 markers in feature-inventory FR1 row | feature-inventory L36 | STALE | disk=119; marker counts almost certainly shifted post-thin-router |
| C17-45 | canonical/agents/discovery-reviewer/README.md README cite "106 lines" by module-map L135 | module-map L135 | (not re-verified) | needs spot-check |

**Cycle-17 spot-check summary:** 45 checks. **22 FALSE on disk** (49% failure rate — all SKILL.md line-count and file-existence claims invalidated). **13 TRUE confirmations** (29%). **8 TRUE-but-narrative-STALE** (18% — number is right but surrounding context is broken). **2 not re-verified** (4%).

**Pass rate: 13/45 = 29%.**

## Cross-Cutting Concerns (cycle-17)

1. **Root cause is the same as cycle-14:** a major shape-changing patch (this time work-001 thin-router PR #13) landed without a parallel KB line-count refresh. Cycle-14's recommendation ("rephrase all KB docs to use stable phrasings like 'byte-identical across canonical + 3 profile trees' without hard-coded numbers") was NOT applied.

2. **Drift magnitude is unprecedented.** Pre-cycle-14, subagent-visibility-patch grew skills by ~10%. Cycle-17's thin-router refactor SHRUNK skills by 30-77%. aid-detail: 417→77 (81% smaller); aid-init: 513→119 (77% smaller); aid-discover: 596→258 (57% smaller).

3. **Self-contradictions are everywhere.** technology-stack.md L25 says methodology=1,158; project-structure.md L13 says 1,071 (correct). technology-stack.md L196 + architecture.md L19/L200 say `.gitignore` is "1 line .aid/"; project-structure.md L41/L274 correctly say 44 lines. Reader cannot tell which doc to trust.

4. **Work-001 deliverables completely invisible.** 5 production recipes, 4 new canonical scripts (~1,282 lines total), 2 e2e runners, 22+ new state-*.md reference files, dispatch-protocol-checklist.md — zero KB docs mention any of these. feature-inventory.md still lists 20 features; should be ~24-25.

5. **CLAUDE.md is unfit for purpose.** Still says `(pending discovery)` despite Discovery being Approved since 2026-05-21. Every Claude Code session opens with placeholder text. Most user-visible bug.

6. **Cycle-15 self-attestation grade A is refuted.** Cycle-15 verified content correctness using grep + verify-kb-claims.sh (which doesn't check inline-prose SKILL.md line counts). Same failure mode as cycle-13 (refuted by cycle-14).

7. **Inventory metric base is wrong everywhere downstream.** test-landscape.md L10 still uses 353/49,226 (pre-work-002); host-tools-matrix.md L122 still uses 49,226. Cascade of incorrect denominators on every "% of repo" calculation.

8. **The `references/state-*.md` decomposition pattern that thin-router introduced is the new standard but has no KB coverage.** coding-standards.md §1.3 talks about generic "references/*.md for long-form prompts" but doesn't capture the state-specific decomposition convention (one file per state machine state). This is a real authoring convention contributors need to know.

## Q&A

> Cycle-17 adds Q200-Q204 for genuine information gaps that cannot be resolved from code alone.

### Q190-Q193
- (preserved from prior cycles — Q190 KB-F1 done; Q191 KB-F2 done; Q192 infrastructure §3.1.1 done; Q193 feature-inventory rows added)

### Q200: [Recipes: High] What is the runtime trigger for the recipes catalog?
**Status:** Answered (cycle-17 FIX — auto-resolved from repo)
**Answer:** Recipes are consumed by `aid-interview` State TRIAGE Step 5a (`canonical/skills/aid-interview/references/state-triage.md`). Trigger: Path=lite AND `recipe.applies-to == workType OR == '*'`. Only aid-interview loads recipes (not aid-execute). Recipes are authored in `canonical/recipes/` (maintainer-side); `run_generator.py` propagates to all 3 profile trees; `setup.sh`/`setup.ps1` copies to user projects (path varies by profile — `.claude/recipes/`, `.codex/recipes/`, or `.cursor/recipes/`). See `api-contracts.md ## Recipe File Schema` + `integration-map.md ## Recipes Catalog` (added by cycle-17 FIX).
**Applied to:** api-contracts.md, integration-map.md, data-model.md, CLAUDE.md.
**Context:** Cycle-17 verified `canonical/recipes/` exists with 5 recipes + README, and `canonical/skills/aid-interview/scripts/parse-recipe.sh` exists (with 3 test files: test-lite-subpaths.sh, test-lite-to-full-escalation.sh, test-parse-recipe.sh), but no KB doc explains: which skill(s) load recipes (aid-interview only? also aid-execute?), what triggers recipe lookup vs the full feature-SPEC path, who authors recipes (maintainers vs adopters), and where recipes live in an installed project (.claude/recipes/ in dogfood — does setup.sh propagate to user projects?). Recipes are a NEW user-facing capability with no KB documentation.
**Suggested:** aid-interview likely consults canonical/recipes/ during requirements gathering for known patterns (CRUD, refactor, etc.); whether setup.sh propagates recipes to user projects needs verification by reading setup.sh post-merge.

### Q201: [Thin-Router: High] What is the canonical reference for the thin-router skill pattern?
**Status:** Answered (cycle-17 FIX — auto-resolved from repo)
**Answer:** New `coding-standards.md §10 Thin-Router SKILL.md Convention` documents the pattern: when SKILL.md grows past ~200 lines, extract per-state bodies to `references/state-{name}.md`; SKILL.md becomes a state-machine router with Dispatch table (3-form Advance contract). Naming patterns: state-keyed (aid-discover, aid-interview, aid-execute, aid-specify, aid-summarize), step-keyed (aid-init), section-keyed (aid-plan, aid-detail), mode-keyed (aid-deploy). State-id format UPPERCASE with hyphens (CR6). The canonical normative source is `.aid/work-001-aid-lite/features/feature-002-skill-footprint-refactor/SPEC.md`.
**Applied to:** coding-standards.md, CLAUDE.md.
**Context:** Work-001 feature-002 shipped a major architectural shift — SKILL.md bodies shrunk to "thin routers" (aid-detail: 417→77; aid-discover: 596→258; aid-init: 513→119) with logic moved to `references/state-*.md` files (one per state-machine state). This is a real pattern that contributors must follow for new skills, but coding-standards.md §1.3 only mentions generic "references/*.md for long-form prompts". The state-machine decomposition convention is unwritten.
**Suggested:** Add a new convention section to coding-standards.md: "Thin-Router SKILL.md Convention" — when SKILL.md grows large, extract per-state logic into `references/state-{state-name}.md` files; SKILL.md becomes a router with state-table and per-state delegate references; preserve frontmatter + pre-flight + state-table in SKILL.md.

### Q202: [Work Status: Medium] Is work-001-aid-lite shipped or still in progress?
**Status:** Answered (cycle-17 FIX — auto-resolved from repo)
**Answer:** work-001-aid-lite is **SHIPPED** as of 2026-05-25 (PR #13 merged). All 37 tasks Done per `.aid/work-001-aid-lite/STATE.md`. The 5 features are: feature-002 (thin-router refactor), feature-004 (two-tier review), feature-005 (lite path + type-aware sub-paths), feature-009 (parallel pool execution), feature-011 (recipes catalog). All shipped; live test suites pass (297/297).
**Applied to:** feature-inventory.md (rows 21-25 added), CLAUDE.md, README.md (Active Works table — pending follow-up update if needed).
**Context:** Task prompt context says "PR #13 merged" and lists 5 work-001 features as shipped. README.md L30 says "Requirements approved · 4 features specified". The .aid/work-001-aid-lite/STATE.md was modified per git status. The truth needs adjudication so feature-inventory.md and README.md can be reconciled.
**Suggested:** Read .aid/work-001-aid-lite/STATE.md head + .aid/work-001-aid-lite/packages/ to determine ship status, then update feature-inventory.md (add ~4-5 rows for shipped features) and README.md Active Works table.

### Q203: [Test Reports: Medium] Should test-landscape.md cover the new work-001 test infrastructure?
**Status:** Answered (cycle-17 FIX — auto-resolved from repo)
**Answer:** Yes. New `test-landscape.md ## Canonical Script Tests` section enumerates all 7 test scripts: 5 canonical helper tests (`test-writeback-task-status.sh`, `test-delivery-gate-aggregate.sh`, `test-compute-block-radius.sh`, `test-pool-dispatch.sh`, `test-parse-recipe.sh`) + 2 e2e runners (`e2e-two-tier-runner.sh`, `e2e-lite-path-runner.sh`). Aggregate 297 tests pass on master HEAD as of 2026-05-25. The prior "no traditional test suite" TL;DR was correct for application-level testing but misleading post-work-001; the canonical helpers DO have a real test suite now.
**Applied to:** test-landscape.md.
**Context:** Work-001 shipped 4 new test scripts under canonical/templates/scripts/ (test-compute-block-radius.sh, test-pool-dispatch.sh, test-delivery-gate-aggregate.sh, test-writeback-task-status.sh — totaling ~1,565 lines) plus 2 e2e runner scripts in .aid/work-001-aid-lite/test-reports/. These are real harness tests of canonical scripts, distinct from the runtime validation scripts already documented. test-landscape.md "TL;DR" still says "no traditional test suite" — this is now FALSE.
**Suggested:** Add §X "Canonical Script Tests" to test-landscape.md documenting the 4 test-*.sh files (what they test, how to invoke, where output lands) + the 2 e2e runners.

### Q204: [Recipes Format: Medium] What is the recipe-file schema contract?
**Status:** Answered (cycle-17 FIX — auto-resolved from repo)
**Answer:** Recipe schema is now documented in `api-contracts.md ## Recipe File Schema`. Required YAML front-matter: `name` (kebab string), `applies-to` (kebab workType or `"*"` quoted), `slot-count` (integer), `task-count` (integer). Body: `## spec` block + `## tasks` block (lowercase headers); slot placeholders `{{slot-name}}` (POSIX-ERE `[a-z][a-z0-9-]*`); escape `{!{` for literal `{{`. Validated by `parse-recipe.sh --validate` (113 tests pass).
**Applied to:** api-contracts.md.
**Context:** 5 recipe files exist under canonical/recipes/ (add-crud-endpoint.md, add-unit-test.md, bug-fix.md, method-refactor.md, write-release-note.md). api-contracts.md §AID artifact schemas covers REQUIREMENTS / SPEC / STATE / TASK but no recipe schema. parse-recipe.sh + 3 test files imply the schema is well-defined; just undocumented in the KB.
**Suggested:** Read 2-3 recipe files + parse-recipe.sh to extract the recipe schema (sections, frontmatter if any, required vs optional fields, how steps are encoded), then add a §X to api-contracts.md.

---

## Cycle-17 FIX-Pass Summary (2026-05-25)

**Trigger:** Cycle-17 reviewer found Grade D — 7 CRITICAL + 35+ HIGH + 25+ MEDIUM. 45 spot-checks, 22 FALSE (49% failure rate). Root cause: work-001 thin-router refactor shrank SKILL.md bodies by 30-77%, invalidating line-count cites across 12+ KB docs.

**Orchestrator FIX-pass applied:**

| Pass | Scope | Count |
|------|-------|-------|
| 1A   | Skill SKILL.md line-count regex (context-aware, all 10 skills, all wrong → right values) | 162 replacements across 14 KB docs |
| 1B   | Exact-string fixes (methodology 1158→1071, .gitignore content, settings..json retirement, writeback-state 139→173, IMPEDIMENT 118→116, setup.sh/ps1 161→162/156→157, task-template 142→19, repo-size 49,226→90,011 lines) | 24 replacements |
| 1C   | module-map.md per-skill table — full rewrite with disk-truth line counts + new thin-router references list per skill | 1 table rewrite |
| 1D   | module-map.md aggregate totals (4,212/4,412/4,412 → 2,108 total) + per-skill breakdown sums | 5 replacements |
| 2A   | CLAUDE.md — full rewrite (was `(pending discovery)` placeholder, now 6,248 bytes with Build & Test, Architecture, Skills/Agents, Conventions sections) | full doc |
| 2B   | feature-inventory.md — added 5 work-001 feature rows (21-25): thin-router, two-tier review, lite path, parallel pool, recipes catalog | 5 new rows |
| 2C   | coding-standards.md §10 Thin-Router SKILL.md Convention — new normative section documenting Dispatch table 3-form Advance contract, naming patterns (state/step/section/mode-keyed), state-id format CR6 | new section |
| 2D   | test-landscape.md ## Canonical Script Tests — enumerates 7 test scripts (5 canonical helper + 2 e2e runners) with 297 aggregate tests; corrects misleading "no traditional test suite" claim | new section |
| 3A   | api-contracts.md ## Recipe File Schema — full YAML front-matter + body contract + escape syntax + caller flow | new section |
| 3B   | data-model.md — added canonical/recipes/ artifact entry (cardinality, lifecycle, schema xref, validation) | new entry |
| 3C   | integration-map.md ## Recipes Catalog — producer/consumer/helper/propagation/escalation map | new section |
| 3D   | Q200-Q204 marked Answered (auto-resolved from repo by FIX pass; no user input needed) | 5 Q&A entries |

**Total: ~200+ mechanical replacements + 7 new authored sections + 5 Q&A resolutions.**

**Remaining items NOT in this FIX pass (deferrable):**
- README.md Active Works table — needs minor update to reflect work-001 SHIPPED status (text-only edit; not a CRITICAL)
- KB cross-cutting "Project Status" page — would be useful but is a NEW doc, not a FIX of existing drift
- New Q-entries from cycle-18 if reviewer finds anything we missed

**Recommended next action:** re-run `/aid-discover` to enter REVIEW state for fresh cycle-18 adversarial grade.

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2-15 | 2026-05-21 to 2026-05-23 | (D- to A+ to C to A) | aid-discover cycles 2-15 | Cycle-14 reviewer found 8 HIGH from subagent-visibility-patch; cycle-15 orchestrator self-attestation Grade A. |
| 16 | 2026-05-23 | A | orchestrator self-attestation post cycle-14 fix-pass | Applied 19 line-count drift fixes; fixed false .gitignore claim; verify-kb-claims.sh exit 0. Self-attestation only. |
| 17 | 2026-05-25 | **D** | post-work-001-merge fresh adversarial (clean-context) | PR #13 work-001 thin-router refactor invalidated KB line counts across 12+ docs by 30-77%. 7 NEW CRITICAL · 35+ NEW HIGH · 25+ NEW MEDIUM · 10+ NEW LOW/MINOR. Worst-affected: architecture.md §7.2 (ALL 10 line counts wrong), module-map.md Modules 2/3/4/5 (totals off by 100%), feature-inventory.md (missing all 5 work-001 features), CLAUDE.md still has (pending discovery) placeholder. New work-001 artifacts (5 recipes, 4 canonical scripts, ~22 state-*.md references, 2 e2e runners, dispatch-protocol-checklist.md) completely unmentioned. 5 new Q-entries (Q200-Q204) added. 45 spot-checks, 22 FALSE (49% failure rate), 13 TRUE (29% pass rate). RECOMMENDATION: targeted FIX pass — line-count sweep via wc -l, add work-001 features to feature-inventory, clean CLAUDE.md placeholders, add thin-router convention section to coding-standards. Then re-review. |
