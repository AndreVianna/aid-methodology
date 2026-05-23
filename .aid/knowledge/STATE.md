# Discovery State

> **Status:** Approved
> **Minimum Grade:** A+
> **Current Grade:** A+
> **User Approved:** yes (2026-05-21)
> **Last KB Review:** 2026-05-21 (cycle 10, final independent review)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. Consolidates what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md` per FR2 (work-003-traceability).

## KB Documents Status

| Document | Status | Lines | Source | Notes |
|----------|--------|-------|--------|-------|
| project-structure.md | ✅ Populated | 263 | aid-discover (scout) | Top-level layout, key files, the per-tool triplication pattern (claude-code / codex / cursor), skills + agents inventories, anomalies. |
| external-sources.md | ✅ Populated (URLs registered, web fetch deferred) | 145 | aid-init + scout | 8 vendor doc URLs + a per-vendor cross-reference mapping each external source to local repo directories. |
| architecture.md | ✅ Populated | 587 | aid-discover (architect) | Two-level architecture (10-SKILL pipeline per user-confirmed Q16: 1 setup [Init] + 8 dev + 1 optional [Summarize]; + repo structure with 3 triplicated install trees), 8 patterns (skills as state machines, sub-agent dispatch, reference decomposition, KB as gravitational center, spec-as-hypothesis, deterministic grading, triplicated payloads, 3-tier agent model), doc-vs-code parity spot-checks. |
| technology-stack.md | ✅ Populated | 352 | aid-discover (architect) | Multi-language tooling repo (Markdown / Shell / PowerShell / JS / CSS / HTML / TOML / JSON); no package manager, no build system, no CI workflows. |
| ui-architecture.md | ✅ Populated | 319 | aid-discover (architect) | The `aid-summarize` HTML viewer — single-file offline HTML, light/dark theme via CSS variables, inline Mermaid, lightbox, breadcrumb scrollspy, profile-driven section templates. |
| module-map.md | ✅ Populated | 425 | aid-discover (analyst) | 14 modules (methodology spec, skills × 4 trees, agents × 4 trees, templates × 4 trees, knowledge-summary bundle, installers, examples, reference docs); triplication relationships + Mermaid dependency graph. Notes that the 6 discovery sub-agent READMEs are pending authoring per Q18. |
| coding-standards.md | ✅ Populated | 407 | aid-discover (analyst) | 10 convention areas (SKILL.md frontmatter, agent frontmatter per tool, Cursor `.mdc`, KB headers, template placeholders, shell idioms, markdown, filenames, triplicate-updates rule) + "Conventions NOT enforced" gap list. |
| data-model.md | ✅ Populated | 527 | aid-discover (analyst) | 15 pipeline-artifact sections (§2.1–§2.15 — some grouping related files like DEPLOYMENT-STATE + package, MONITOR-STATE + track-report). Per-artifact schemas, cardinality matrix, Mermaid dataflow across the methodology phases. |
| api-contracts.md | ✅ Populated | 458 | aid-discover (integrator) | No HTTP/RPC/queue surface. 14 schema contracts: host-tool frontmatter (Claude Code agent / SKILL.md / CLAUDE.md / settings.json; Codex TOML agent / SKILL.md / AGENTS.md; Cursor `.mdc` / agent / SKILL.md / AGENTS.md) + internal AID artifact schemas + breaking-change risk. |
| integration-map.md | ✅ Populated | 267 | aid-discover (integrator) | 12 integration sections: 6 host AI tools (Claude Code + Codex + Cursor live; Copilot + Antigravity future; Claude Agent SDK separate), MCP + Hooks ecosystems (both unused — registered for future), 4 local runtimes (Node, mmdc, Bash/PS, Git). Mermaid topology + per-skill API consumption matrix. |
| domain-glossary.md | ✅ Populated | 175 | aid-discover (integrator) | **150 terms** (markdown table rows; verified via `grep -c "^| \*\*"` post-cycle-3 — earlier 146 figure was pre-FIX-pass before 4 new entries were added for Knowledge Base Meta-Document, Knowledge Base Extension, Project Index, and Haiku tier per Q102 + Q36 resolutions). Covers lifecycle, phases, stages, artifacts, roles, quality, task types, tooling, triplication, knowledge-summary state machine. Alphabetical with `[[wikilink]]` cross-refs. |
| test-landscape.md | ✅ Populated | 186 | aid-discover (quality) | Zero traditional tests; the only "tests" are user-runtime validation scripts (`aid-summarize` validate-html/links/diagrams/contrast). 6 documented gaps (3 HIGH: no CI, no triplication-drift checker, no smoke test). |
| security-model.md | ✅ Populated | 305 | aid-discover (quality) | 21 severity-tagged findings: 1 HIGH (all 6 discovery sub-agents share bypassPermissions+background — corrected from "only discovery-reviewer"), 4 MEDIUM (hardcoded Maven path in Codex `developer.toml`; discovery-reviewer KB-append authority; no supply-chain verification; prompt-injection via fetched URLs), 4 LOW, 12 INFO. 0 CRITICAL. |
| tech-debt.md | ✅ Populated | 423 | aid-discover (quality) | **20 items: 7 HIGH** (H1 triplication drift; H2 no CI/manifest/version; H3 no drift checker; H4 ~17,600 lines of 4-way duplication = 36% of repo; H5 CONTRIBUTING omits Cursor; H6 Codex installer .agents/ omission CONFIRMED; H7 Monitor templates missing CONFIRMED), **6 MEDIUM** (incl. new M6 Cursor Terminal/Bash internal inconsistency); 7 LOW. Plus 29-row Resolution Roadmap (R1–R29) mapping every Q-ID to actionable items. Notable: all 22 agents tier-consistent across the 3 install trees (May 2026 migration applied). |
| infrastructure.md | ✅ Populated | 229 | aid-discover (quality) | No deployed infra. Distribution = git clone only; install via `setup.sh` / `setup.ps1`. ❌ Both installers **CONFIRMED to omit** copying `profiles/codex/.agents/` (per DISCOVERY-STATE Q70 + tech-debt H6 — verified via static analysis, patch trivial). |
| feature-inventory.md | ✅ Populated | 62 | aid-discover (orchestrator) | 18 features from user-confirmed Q-FEATURES — **12 ✅ Shipped, 6 ⚠️ Partial** (cross-linked to blocking Q-IDs). |
| host-tools-matrix.md ⭐ | ✅ Populated (extension) | 144 | aid-discover (orchestrator) | **KB extension** — per-host-tool feature parity matrix. Outside the standard 16-doc state machine; downstream skills don't read it but reviewers + maintainers do. Consolidates per-tool content scattered across integration-map / tech-debt / coding-standards / external-sources. |

## Knowledge Summary Status

**Profile:** cli (pipeline-focused)
**Profile Source:** user-specified (via AskUserQuestion)
**Profile Confidence:** low (auto-detect tied; user picked cli, then directed a pipeline-first rebuild)
**Theme:** default
**Minimum Grade:** A+
**Minimum Grade Source:** DISCOVERY-STATE.md
**Machine Grade:** A+ (73/73 — all AUTO_POOL checks pass; D2 verified via mmdc render)
**Human Grade:** A+ (30/30 — K1 10/10, K2 15/15, V1 visual gate 5/5)
**Overall Grade:** A+ (= min of Machine A+, Human A+)
**User Approved:** yes (2026-05-21)
**Last Run:** 2026-05-21
**Trigger Reason:** initial
**Output:** .aid/knowledge/knowledge-summary.html
**Output Size:** ~3.39 MB (5,058 lines)
**Diagrams:** 9 (Fig 1 pipeline · Fig 2 KB taxonomy · Fig 3 RAG context economy · Fig 4 agent tiers · Fig 5 skill→agent dispatch · Fig 6 Discover state machine · Fig 7 Discover phase IO · Fig 8 artifact dataflow · Fig 9 triplicated install bundles) — numbered 1-9 in document order
**Mermaid Version:** 11.15.0
**Mermaid Cached:** .aid/knowledge/.cache/mermaid.min.js (sha256: 70137e77bb273bb2ef972b86e8b0400cca8be53cb25bfc45911a186dc98665de)
**Last Reviewed KB Date:** 2026-05-21
**Last Summary Date:** 2026-05-21
**Writeback Status:** ok

## Findings (final — two-grade model)

### Machine Grade — AUTO_POOL 73/73 → A+
D1 20/20 · D2 10/10 (mmdc render) · L1 5/5 · L2 5/5 · H1 5/5 (html-validate) · A1 5/5 · A2 3/3 · A3 5/5 (auto-detected) · A4 2/2 · A5 3/3 · C1 4/4 · C2 4/4 · S2 2/2.

### Human Grade — MANUAL_POOL 30/30 → A+
K1 KB completeness 10/10 (Full) · K2 facts grounded 15/15 (Full) · V1 human visual gate 5/5 (Pass — user-confirmed A+ after multi-round visual inspection).

### Diagram count
9 / 4 (cli profile `target_diagrams`) — above the per-profile floor.

## Visual inspection (V1 gate) — issues found and resolved

1. **Dark-mode diagram contrast** — teal node text was unreadable. Three root causes fixed: (a) teal fill too light for white text → dark teal `#0E4D4A`; (b) Mermaid label `<p>` inheriting the page's muted color → `.nodeLabel * { color: inherit }`; (c) that CSS scoped to `.mermaid` so the lightbox clone reverted → unscoped the selector. Final: white-on-dark-teal 9.6:1, all 22 node classes pass WCAG AA in both themes + the expanded lightbox.
2. **FIG6 (Discover state machine)** — literal `\n` rendered as text (stateDiagram-v2 needs `<br/>`). Fixed; an automated D1 guard for literal `\n` was added to `validate-diagrams.mjs`; repo-wide audit found no other occurrence.
3. **FIG1 (pipeline)** — added the 4-group structure (Define / Map / Execute / Deliver) from the methodology README + `architecture.md`; then simplified to forward-flow-only (removed feedback-loop and KB clutter); Init + Summarize moved into the Define group (provisional).
4. **NEW Figure 3 — RAG / 3-tier context economy** — the KB's progressive-disclosure design was a partial KB gap; closed by expanding `architecture.md` Pattern 4, then represented as a new diagram. Tracked: DISCOVERY-STATE Q180.
5. **Figure renumbering** — figures were numbered by build-constant index, not document order; renumbered 1-9 in reading order.

## Manual Notes

Visual inspection ran over multiple rounds; user confirmed satisfaction with grade A+. The `/aid-summarize` grading system itself was overhauled this session (two-grade Machine/Human model; mandatory V1 visual gate; per-profile `target_diagrams`; real jsdom/mmdc D2 render check; A3 auto-detection; literal-`\n` D1 guard; H1 tidy/html-validate cascade). See DISCOVERY-STATE Q180 and tech-debt H8.


---

> **Audit trail follows.** The sections below preserve the full Discovery-area history as it accumulated across 10 review cycles, /aid-summarize gap-finding passes, and /aid-interview cross-reference staleness findings. Section names retain their original form for traceability with prior commits.

## External Documentation

Registered web sources (see `external-sources.md` for full details + per-vendor local cross-reference):

1. Anthropic — Claude Code docs (https://docs.claude.com/en/docs/claude-code/overview)
2. Anthropic — Claude Agent SDK docs (https://docs.claude.com/en/api/agent-sdk/overview)
3. OpenAI — Codex CLI (https://github.com/openai/codex)
4. OpenAI — Codex developer docs (https://developers.openai.com/codex/)
5. Cursor — Rules & Agents docs (https://docs.cursor.com/context/rules-for-ai)
6. Cursor — MCP & Hooks docs (https://docs.cursor.com/context/model-context-protocol)
7. GitHub Copilot CLI docs (https://docs.github.com/en/copilot)
8. Google Antigravity docs (https://antigravity.google/docs — URL to confirm)

Web fetching deferred. Each vendor's local cross-reference (which directory in *this* repo implements that vendor's patterns) has been documented in `external-sources.md §Local Cross-Reference`.

## Issues

**Cycle 10 review — script-anchored + 25 manual spot-checks; the cycle-8 Q170 FIX is verified to have held cleanly on disk.**

`bash templates/scripts/verify-kb-claims.sh` (v8 foreground run, exit 0): **896/896 citations valid, 0 missing files, 0 line-out-of-range, 0 README line-count drifts, 0 spot-check drifts.** Ground-truth pane: domain-glossary=150 terms, tech-debt=7H/6M/7L/20 total, security-model=1H/4M/4L/12I/21 total.

**Cycle-8 Q170 FIX disk-verification (this cycle 10 review):**

| Site | Cycle-9 finding | Disk state (cycle 10) | Outcome |
|------|-----------------|------------------------|---------|
| `api-contracts.md:52, 58, 455` | "11 skills" | "all 10 skills" / "1 of 10 skills" / "7 of 10 skills" | FIXED |
| `domain-glossary.md:136` | "11 skills (10 pipeline + 1 optional)" | "10 SKILL.md files per install tree" | FIXED |
| `integration-map.md:21, 25, 49, 63` | "22 agents + 11 skills" / "11 skill folders" | "22 agents + 10 skills" / "10 skill folders" / "10 skills" | FIXED |
| `module-map.md:64` | "23 (11 SKILL.md + 9 references + 3 scripts + README)" | "24 (10 SKILL.md + 11 references + 2 scripts + README) — verified `find` = 24" | FIXED + breakdown verified |
| `module-map.md:97, 114` | "13 (11 SKILL.md + 1 references + 1 README)" | "12 (10 SKILL.md + 1 references/kb-hydration + 1 README) — verified `find` = 12" | FIXED + breakdown verified |
| `project-structure.md:238, 240, 241` | "11 skills" in table | "10 skills" in table | FIXED |
| `project-structure.md:244` | "11 entries" | "10 entries (9 aid-* folders incl. tombstone + top-level README.md) — verified `ls skills/` = 10" | FIXED |

**Cross-doc consistency:** all 14 cycle-9-flagged sites now report 10 SKILL files; the 4 module-map subfile breakdowns now match disk-verified `find` counts (claude-code=24, codex=12, cursor=12); the 7 docs that already said "10" (architecture.md, data-model.md, feature-inventory.md, host-tools-matrix.md, INDEX.md, tech-debt.md, technology-stack.md) remain correct. Direct grep: `grep -nE "11 [Ss]kill" .aid/knowledge/*.md | grep -v DISCOVERY-STATE` returns **0 matches**.

**Script-anchored ground truth (this cycle):**

| Claim | Source | Verified | Method |
|-------|--------|----------|--------|
| 896/896 valid citations, 0 broken, 0 out-of-range | verify-kb-claims.sh v8 | YES | exit 0; foreground re-run |
| 0 README line-count drifts (17/17 docs match disk) | verify-kb-claims.sh v8 | YES | column scan vs wc -l |
| 0 spot-check drifts | verify-kb-claims.sh v8 | YES | terms/severities all match |
| domain-glossary = 150 terms | script + manual `grep -c "^\| \*\*"` | YES | both report 150 |
| tech-debt = 7H/6M/7L/20 | script + manual `grep -cE "^### \["` | YES | total=20 |
| security-model = 1H/4M/4L/12I/21 | script + manual `grep -cE "^\["` | YES | total=21 |

### Per-Document Grades

| Document | Grade | Status | Notes |
|----------|-------|--------|-------|
| architecture.md | A+ | Pass | §2.1 L53 "10 SKILL.md files total"; L111 "10 SKILL files"; L169 spec at 1,158 lines verified. Zero issues. |
| technology-stack.md | A+ | Pass | §5 component-css.css "642 lines × 4 copies" VERIFIED (4 × 642 = 2,568 disk). §3.4 Node 18+ VERIFIED via check-preflight.sh:87-96. Zero issues. |
| ui-architecture.md | A+ | Pass | §1 html-skeleton.html "101 lines" VERIFIED (wc -l = 101); §1 lightbox.js "359 lines" VERIFIED. §1 aid-summarize line counts (430/436/436) consistent with disk. Zero issues. |
| module-map.md | A+ | Pass | L64/L97/L114 all correctly reflect disk-verified subfile breakdowns (claude=24, codex=12, cursor=12). Q170 FIX held cleanly. Zero issues. |
| coding-standards.md | A+ | Pass | §2.2 L120 Sonnet tier VERIFIED post-Q36. §2.3 L131 VERIFIED post-cycle-7 (Q151). Zero issues. |
| data-model.md | A+ | Pass | "10 SKILL files" consistent (Q131 fix held). Zero issues. |
| api-contracts.md | A+ | Pass | L52/L58/L455 — Q170 FIX held: "all 10 skills" / "1 of 10 skills" / "7 of 10 skills". Zero issues. |
| integration-map.md | A+ | Pass | L21/L25/L49/L63 — Q170 FIX held: "22 agents + 10 skills" across all rows. Zero issues. |
| domain-glossary.md | A+ | Pass | L82 Haiku standalone (Q152), L136 "10 SKILL.md files per install tree" (Q170), L171 narrative coherent (Q160). 150 terms verified. Zero issues. |
| test-landscape.md | A+ | Pass | §1 "353 files, 49,226 lines" matches project-index.md. Zero issues. |
| security-model.md | A+ | Pass | L290 + L292-299 Summary table 1H+4M+4L+12I=21 matches script. Q141 fix held. Zero issues. |
| tech-debt.md | A+ | Pass | L356-360 Metrics 7H/6M/7L=20 VERIFIED. M6 Cursor 6 Bash + 13 Terminal VERIFIED. Zero issues. |
| infrastructure.md | A+ | Pass | §3.4 Node.js 18+ VERIFIED. §9 Q125 fix held. §7 Codex installer omission CONFIRMED. Zero issues. |
| feature-inventory.md | A+ | Pass | L29 "10 SKILL.md packages"; L41-42 Status Summary 12 Shipped / 6 Partial self-consistent. Zero issues. |
| host-tools-matrix.md | A+ | Pass | L22/L25 "10 skills"; L80-82 tier counts 10+9+3=22 VERIFIED. Zero issues. |
| project-structure.md | A+ | Pass | L238/L240/L241 "10 skills" (Q170 FIX held). L244 "10 entries" — `ls skills/` = 10 VERIFIED. L147 Q150 fix held. Zero issues. |
| INDEX.md | A+ | Pass | L17 "150 terms"; L20 "20 items: 7 HIGH"; L23 "12 Shipped, 6 Partial"; "10 SKILL files" — all VERIFIED. Zero issues. |
| README.md | A+ | Pass | 17-row completeness table: 0 line-count drifts (script). Q140 propagation held. Zero issues. |
| CLAUDE.md (worktree root) | A+ | Pass | L68 + L77 "10 SKILL files". 0 (pending discovery) placeholders. Zero issues. |
| external-sources.md | A+ | Pass | L137-145 Trust Model per Q80. Zero issues. |

**Counts:** 0 CRITICAL, 0 HIGH, 0 MEDIUM, 0 LOW, ~21 MINOR (stylistic / formatting only — do not affect A+).

## Verification Spot-Checks

| # | Claim | Document | Verified | Evidence |
|---|-------|----------|----------|----------|
| 1 | Script reports 896/896 valid citations, 0 broken, 0 README drifts, 0 spot-check drifts | ground truth | Yes | verify-kb-claims.sh v8 foreground, exit 0 |
| 2 | domain-glossary.md term count = 150 | INDEX L17, README L30, glossary | Yes | `grep -c "^\| \*\*"` = 150; script confirms |
| 3 | tech-debt.md severity counts HIGH=7, MEDIUM=6, LOW=7, TOTAL=20 | tech-debt L356-360, INDEX L20, README L33 | Yes | `grep -cE "^### \["` = 20; script 7/6/7 |
| 4 | security-model.md severity counts 1H+4M+4L+12I=21 | security-model L292-299 | Yes | `grep -cE "^\["` = 21; script 1/4/4/12 |
| 5 | README line-count column: all 17 docs match disk | README L20-36 | Yes | Script: 17 OK, 0 drifts |
| 6 | Claude Code agent tier counts: 3 haiku + 10 opus + 9 sonnet = 22 | host-tools-matrix L80-82 | Yes | `grep -E "^model:" profiles/claude-code/.claude/agents/*.md` = 3+10+9 |
| 7 | Codex agent tier counts: 3 mini + 9 5.4 + 10 5.5 = 22 | host-tools-matrix L80-82 | Yes | `grep -E "^model = " profiles/codex/.codex/agents/*.toml` = 9+3+10 |
| 8 | Cursor tools Bash count = 6, Terminal count = 13 (M6) | tech-debt M6 | Yes | `grep -lE "tools:.*Bash"` = 6; `grep -lE "tools:.*Terminal"` = 13 |
| 9 | Claude Code has 10 SKILL.md (no 11 anywhere) | api/integration/module/project-structure | Yes | `find profiles/claude-code/.claude/skills -name SKILL.md` = 10 |
| 10 | Codex has 10 SKILL.md | integration-map L49 | Yes | `find profiles/codex/.agents/skills -name SKILL.md` = 10 |
| 11 | Cursor has 10 SKILL.md | integration-map L63, module-map L114 | Yes | `find profiles/cursor/.cursor/skills -name SKILL.md` = 10 |
| 12 | `ls skills/` = 10 entries (9 aid-* + README) | project-structure L244 | Yes | matches; entries: aid-correct, aid-deploy, aid-detail, aid-discover, aid-execute, aid-interview, aid-monitor, aid-plan, aid-specify, README.md |
| 13 | profiles/claude-code/.claude/skills total files = 24 | module-map L64 | Yes | `find profiles/claude-code/.claude/skills -type f` = 24; 10 SKILL + 11 references + 2 scripts + 1 README |
| 14 | profiles/codex/.agents/skills total files = 12 | module-map L97 | Yes | `find` = 12; 10 SKILL + 1 references/kb-hydration + 1 README |
| 15 | profiles/cursor/.cursor/skills total files = 12 | module-map L114 | Yes | `find` = 12; 10 SKILL + 1 references/kb-hydration + 1 README |
| 16 | `grep -nE "11 [Ss]kill" .aid/knowledge/*.md \| grep -v DISCOVERY-STATE` = 0 matches | cross-doc systemic check | Yes | confirms cycle-8 Q170 FIX held cleanly across all KB |
| 17 | methodology/aid-methodology.md = 1,158 lines | architecture L169, module-map L32 | Yes | `wc -l` = 1158 |
| 18 | setup.sh=161, setup.ps1=156, build-project-index.sh=368, grade.sh=141 | infrastructure, technology-stack | Yes | `wc -l` matches |
| 19 | component-css.css 642 × 4 copies = 2,568 lines | technology-stack §5; host-tools-matrix L114 | Yes | `wc -l` confirms 642 per file × 4 copies |
| 20 | templates/knowledge-base/ has 17 files (no ui-architecture.md) | project-structure L147 | Yes | `ls templates/knowledge-base/` = 17; grep for ui-architecture returns nothing |
| 21 | Worktree CLAUDE.md has 0 (pending discovery) placeholders | meta | Yes | grep -c = 0 |
| 22 | DISCOVERY-STATE.md Q-entries before this cycle = 75; highest Q-ID = Q170 | meta | Yes | grep -cE "^### Q[0-9]+" = 75 |
| 23 | html-skeleton.html = 101 lines | ui-architecture L32 | Yes | `wc -l` = 101 |
| 24 | lightbox.js = 359 lines | ui-architecture; domain-glossary L105 | Yes | `wc -l` = 359 |
| 25 | KB has 21 files (16 standard + 3 meta + 1 generated + 1 extension) | project-structure | Yes | `ls .aid/knowledge/*.md` = 21 |

**Spot-check summary:** 25 verified, 0 drift. Every previously-flagged systemic issue (Q140, Q141, Q150, Q151, Q152, Q160, Q170) verified held cleanly on disk.

## Cross-Cutting Concerns

1. **Q170 FIX (cycle-8 turn) verified held cleanly across all 14 narrative sites + 4 module-map subfile breakdowns + project-structure L244.** The "11 skills" systemic error that dominated cycle-9 is fully resolved: cycle-10 disk-grep confirms 0 occurrences of `11 [Ss]kill` anywhere in the KB (excluding DISCOVERY-STATE which documents the history). Module-map.md L64/L97/L114 now state disk-verified subfile breakdowns (claude=24, codex=12, cursor=12) matching `find` output. project-structure.md L244 now correctly states "10 entries (9 aid-* folders incl. tombstone + top-level README.md)" matching `ls skills/ | wc -l` = 10. The 7 docs that already said "10" remain correct; the 5 docs that previously said "11" are corrected. Cross-doc consistency: complete.

2. **Script-anchor stability remains the dominant positive signal.** v8 run: 896/896 citations valid, 0 README drifts, 0 spot-check drifts. The script-verified ground truth (domain-glossary=150 terms, tech-debt=7H/6M/7L/20, security-model=1H/4M/4L/12I/21) matches every cross-doc summary in INDEX.md and README.md. All prior FIXes (Q160 cycle-8 turn, Q152 cycle-6 turn, Q151 cycle-6 turn, Q150 cycle-6 turn, Q170 cycle-8 turn) verified held.

3. **Script-detectable invariants stable across 10 cycles:**
   - Every `file.ext:NN` citation resolves to a real file at expected line range: 896/896.
   - README.md line-count column matches `wc -l`: 17/17.
   - Spot-check counts (domain-glossary terms, tech-debt severities, security-model severities) match disk-grep: 0 drift.

4. **Quality trajectory:** D- (cycle 1) → D (cycles 2-3) → C (cycle 4) → C-disputed (cycle 5) → B+ (cycle 6) → A- (cycle 7) → A (cycle 8) → C+ (cycle 9 — regression discovered, not introduced) → **A+ (cycle 10 — Q170 FIX verified held)**. Net state: 0 CRITICAL, 0 HIGH, 0 MEDIUM, 0 LOW, ~21 MINOR stylistic. **Strict rubric: worst severity = MINOR (cosmetic only), zero count-level issues = A+.**

5. **Recommendation: APPROVE the KB for the next AID phase (Interview).** The KB has met the A+ minimum-grade bar set in the project metadata. The skills-count load-bearing fact is now consistent at "10 SKILL.md per install tree" across all 19 KB docs. Downstream skills (`aid-interview`, `aid-specify`, `aid-plan`) will read consistent inputs. Script verification provides a regression-detection floor — future drift will be caught by `templates/scripts/verify-kb-claims.sh`.

6. **No (pending discovery) placeholders in worktree CLAUDE.md** (0 occurrences; 91 lines).

7. **File count stable at 21 in `.aid/knowledge/`** (16 standard + 3 meta + 1 generated + 1 extension).

8. **Categories of bugs the script still cannot detect (informational, not blockers):**
   - (a) narrative-reasoning errors that maintain correct citation counts (e.g., Q170-style off-by-one narrative drift) — recommend extending the script with a per-tree skills-count assertion to catch this family;
   - (b) alphabetic ordering inside table-based glossaries (Q152 — resolved);
   - (c) self-referential consistency between similar sections within the same document (Q151 — resolved).

## Q&A

> 75 total Q&A entries before this cycle. Cycle-10 review found 0 new issues requiring user input. Adding no new Q-entries this cycle.
>
> Resolution status:
> - Answered: 74.
> - Skipped (duplicate): 5.
> - Pending: 0.

### Q-FEATURES
- Category: Features
- Impact: Required
- Status: Answered
- Context: feature-inventory.md was empty (template only).
- Question: What is the canonical feature inventory for AID at the current version?
- Answer: User-confirmed canonical 18-item AID feature inventory (via AskUserQuestion 2026-05-21).
- Applied to: feature-inventory.md (full population in FIX pass).

---

### Q1
- Category: Versioning
- Impact: High
- Status: Answered
- Answer: User-confirmed: adopt SemVer + VERSION file + git tags + RELEASING.md.
- Applied to: infrastructure.md section 1, tech-debt.md NEW HIGH item, new RELEASING.md.

### Q2
- Category: Distribution
- Impact: High
- Status: Answered
- Answer: User-confirmed: git-clone primary; tagged GitHub Releases. Claude Code + Codex + Cursor first-class only.
- Applied to: infrastructure.md, host-tools-matrix.md, README.md.

### Q3
- Category: Build / Cross-Tree Sync
- Impact: High
- Status: Answered
- Answer: Auto-resolution: write tools/propagate-skills.sh and .py + CI drift-check.
- Applied to: tech-debt.md H1 + H3, host-tools-matrix.md.

### Q4
- Category: CI / Quality
- Impact: High
- Status: Answered
- Answer: Auto-resolution: add minimal CI workflow with shellcheck, markdownlint, link-check, structural parity test, schema validation.
- Applied to: tech-debt.md H2, infrastructure.md, test-landscape.md.

### Q5
- Category: Tool Support Roadmap
- Impact: High
- Status: Answered
- Answer: User-confirmed: Claude Code + Codex + Cursor first-class only. Copilot + Antigravity aspirational.
- Applied to: README.md, CONTRIBUTING.md, docs/faq.md, host-tools-matrix.md.

### Q6
- Category: Features
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: delete skills/aid-correct/ + templates/reports/correction-template.md.
- Applied to: tech-debt.md L1, project-structure.md Anomaly #6.

### Q7
- Category: Process / Repository Hygiene
- Impact: Medium
- Status: Answered
- Answer: Confirmed typo. Action: git rm .claude/settings..json.
- Applied to: tech-debt.md M1, security-model.md.

### Q8
- Category: Documentation
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: author both missing templates (MONITOR-STATE.md + track-report-template.md).
- Applied to: data-model.md, tech-debt.md M2, two new template files.

### Q9
- Category: Architecture
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: document Codex .codex/ + .agents/ split rationale.
- Applied to: api-contracts.md, integration-map.md, profiles/codex/README.md.

### Q10
- Category: Release Process
- Impact: Medium
- Status: Answered
- Answer: User-confirmed: adopt RELEASING.md runbook with Conventional Commits.
- Applied to: new RELEASING.md.

### Q11
- Category: Project Management
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: GitHub Issues + Discussions; add .github/ templates.
- Applied to: tech-debt.md NEW item.

### Q12
- Category: Testing
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: shell unit tests + structural test + dogfood CI smoke test.
- Applied to: tech-debt.md H2, test-landscape.md.

### Q13
- Category: Branching
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: trunk-based; branch naming convention; squash-with-Conventional-Commits merge.
- Applied to: CONTRIBUTING.md, infrastructure.md.

### Q14
- Category: UI / Knowledge Summary
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: CSS is source of truth; design-tokens.md is descriptive doc.
- Applied to: ui-architecture.md, tech-debt.md NEW item.

### Q15
- Category: Permissions / Security
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: move to .claude/settings.local.json + gitignore.
- Applied to: .gitignore, security-model.md.


---

### Q16
- Category: Methodology / Documentation
- Impact: High
- Status: Answered
- Answer: User-confirmed: 1 Init + 8 dev phases + 1 optional Summarize = 10 SKILL files total.
- Applied to: architecture.md, methodology/aid-methodology.md, README.md, domain-glossary.md, skills/README.md.

### Q17
- Category: Methodology / Documentation
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: add explicit Loop 11 (Any phase to aid-discover).
- Applied to: architecture.md, methodology/aid-methodology.md.

### Q18
- Category: Documentation / Discovery Agents
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: add 6 READMEs under agents/discovery-*/README.md.
- Applied to: tech-debt.md NEW item, module-map.md.

---

### Q30
- Category: Triplication Drift
- Impact: High
- Status: Answered
- Answer: Auto-resolution: standardize on Claude Code/Cursor filenames — DISCOVERY-STATE.md + additional-info.md.
- Applied to: api-contracts.md, integration-map.md, tech-debt.md NEW item.

### Q31
- Category: Missing Templates
- Impact: High
- Status: Skipped (DUPLICATE of Q8).

### Q32
- Category: Templates Architecture
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: lift state-file templates to canonical templates/ root.
- Applied to: data-model.md, tech-debt.md.

### Q33
- Category: KB Conventions
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: define closed Status enum.
- Applied to: coding-standards.md, all 16 KB doc headers, new templates/CONVENTIONS.md.

### Q34
- Category: Documentation Drift
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: update CONTRIBUTING.md to quadruplicate rule with correct dotted paths.
- Applied to: CONTRIBUTING.md, coding-standards.md.

### Q35
- Category: Convention Enforcement
- Impact: Medium
- Status: Skipped (SUBSUMED by Q4).

### Q36
- Category: Sample Coverage
- Impact: Low
- Status: Answered
- Answer: VERIFIED — all Sonnet-tier agents use gpt-5.4/medium.
- Applied to: coding-standards.md, data-model.md.

---

### Q50
- Category: Conventions
- Impact: Medium
- Status: Answered
- Answer: Intentional — install payloads are first-run templates; repo file is steady-state.
- Applied to: api-contracts.md, skills/aid-init/README.md.

### Q51
- Category: Conventions
- Impact: Medium
- Status: Answered
- Answer: Intentional — Codex CLI has no equivalent harness hints.
- Applied to: api-contracts.md, coding-standards.md, host-tools-matrix.md.

### Q52
- Category: Conventions
- Impact: Medium
- Status: Answered
- Answer: Audit all 22 Cursor agents, rename Bash to Terminal. Cycle-6 re-verified: 6 files use Bash, 13 use Terminal.
- Applied to: api-contracts.md, host-tools-matrix.md, tech-debt.md M6.

### Q53
- Category: Conventions
- Impact: High
- Status: Answered
- Answer: Auto-resolution: sync templates/reports/discovery-state-template.md with rich shape.
- Applied to: api-contracts.md, tech-debt.md, templates/reports/discovery-state-template.md.

### Q54
- Category: Infrastructure
- Impact: Low
- Status: Answered
- Answer: Node 18+ — VERIFIED via check-preflight.sh:87-96.
- Applied to: technology-stack.md, infrastructure.md, tech-debt.md.

### Q55
- Category: Infrastructure
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: add Mermaid CLI install note to README + aid-summarize README.
- Applied to: README.md, aid-summarize/README.md, technology-stack.md.

---

### Q70
- Category: Infrastructure
- Impact: High
- Status: Answered
- Answer: CONFIRMED BUG — promote to HIGH. Patch: add copy_dir profiles/codex/.agents to Codex branch in both setup.sh and setup.ps1.
- Applied to: infrastructure.md, tech-debt.md H6, host-tools-matrix.md.

### Q71
- Category: Infrastructure
- Impact: Medium
- Status: Answered
- Answer: User-confirmed: master is the only branch; feature branches short-lived.
- Applied to: infrastructure.md.

### Q72
- Category: Process
- Impact: High
- Status: Answered
- Answer: Same as Q34 — quadruplicate rule.

### Q73
- Category: Quality
- Impact: High
- Status: Answered
- Answer: Auto-resolution: propagation script (Q3 resolution).

### Q74
- Category: Security
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: add .github/CODEOWNERS for elevated agents.
- Applied to: security-model.md, tech-debt.md, new .github/CODEOWNERS.

### Q75
- Category: Security
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: add tools/redact-kb.sh script.
- Applied to: security-model.md, tech-debt.md (deferred item).

### Q76
- Category: Process
- Impact: Medium
- Status: Skipped (DUPLICATE of Q6).

### Q77
- Category: Quality
- Impact: Medium
- Status: Skipped (DUPLICATE of Q8).

### Q78
- Category: Security
- Impact: Low
- Status: Skipped (DUPLICATE of Q7).

### Q79
- Category: Infrastructure
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: add setup.sh --dry-run + --prune modes.
- Applied to: infrastructure.md, tech-debt.md.

### Q80
- Category: Security
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: document trust assumption in external-sources.md.
- Applied to: external-sources.md (NEW Trust Model section), security-model.md.

### Q81
- Category: Process
- Impact: Low
- Status: Answered
- Answer: Intentional — 3 install templates carry placeholders; repo-root is steady-state.
- Applied to: tech-debt.md, api-contracts.md.

### Q82
- Category: Quality
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: align all 3 install-template variants to Cursor shape.
- Applied to: api-contracts.md, host-tools-matrix.md.


---

## Discovery — Review Cycle 1

### Q100
- Category: Documentation / Counts
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: extend build-project-index.sh to emit Canonical Counts section.
- Applied to: tech-debt.md NEW item, templates/scripts/build-project-index.sh.

### Q101
- Category: Reviewer Snapshot Lifecycle
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: add post-cycle reconcile pass to discovery-reviewer prompt.
- Applied to: profiles/claude-code/.claude/agents/discovery-reviewer.md prompt.

### Q102
- Category: KB Conventions
- Impact: Low
- Status: Answered
- Answer: 16 standard + 3 meta + 1 generated + extensions.
- Applied to: domain-glossary.md, README.md Project-Type Adaptation.

### Q103
- Category: Reviewer Methodology
- Impact: Low
- Status: Answered
- Answer: Auto-resolution: add INFO to rubric as non-counted severity.
- Applied to: templates/grading-rubric.md, security-model.md (sanctioned).

### Q104
- Category: Process / Self-Validation
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: extend Review History rows with Docs Modified column.

### Q105
- Category: Process / Tooling
- Impact: Medium
- Status: Answered
- Answer: Auto-resolution: author templates/scripts/verify-kb-claims.sh. IMPLEMENTED 2026-05-21 — first run 898/898 valid citations, 0 drifts. Cycle-7/8/9/10 re-runs: 896-897 valid, 0 drifts.
- Applied to: new templates/scripts/verify-kb-claims.sh, tech-debt.md.

---

## Discovery — Review Cycle 2

### Q110
- Category: Counts / Drift
- Impact: Medium
- Status: Answered
- Context: domain-glossary count drift (150 actual vs 146 claimed in 3 places).
- Answer: Fixed in FIX cycle 2.
- Applied to: INDEX.md, README.md.

### Q111
- Category: Counts / Drift
- Impact: Medium
- Status: Answered
- Context: tech-debt count drift (423 lines / 7 HIGH actual vs 354 / 5 HIGH claimed).
- Answer: Fixed in FIX cycle 2.
- Applied to: INDEX.md, README.md.

### Q112
- Category: Feature Inventory Bookkeeping
- Impact: Low
- Status: Answered (propagation completed cycle 5 per Q140)
- Context: Status Summary off-by-2 (10/8 headline vs 12/6 enumeration). Body of feature-inventory.md fixed to 12 Shipped + 6 Partial. INDEX.md L23 + README.md L35 retained stale 10/8 headline until cycle-5 FIX.
- Answer: Body-only fix in cycle 2 FIX; INDEX + README propagation landed cycle-5 FIX per Q140.
- Applied to: feature-inventory.md (body); INDEX.md + README.md headline updated cycle-5 per Q140.

### Q113
- Category: Tier Mapping Error
- Impact: Medium
- Status: Answered (FIX introduced new error — see Q120)
- Context: host-tools-matrix.md tier table.
- Answer: Cycle 2 FIX corrected one error but introduced another. See Q120.
- Applied to: host-tools-matrix.md (corrected in cycle 3).

### Q114
- Category: Missing Template
- Impact: Medium
- Status: Answered
- Context: templates/knowledge-base/ui-architecture.md does NOT exist at canonical root.
- Answer: Flagged in module-map.md, data-model.md, architecture.md. Install-tree variants acknowledged in cycle 3 per Q126.
- Applied to: module-map.md, data-model.md, architecture.md.

### Q115
- Category: Reviewer Snapshot / additional-info.md
- Impact: Low
- Status: Answered
- Context: discovery-reviewer agent prompts still reference additional-info.md despite Q&A consolidation.
- Answer: Out-of-scope for KB FIX cycle; tracked as R12.

---

## Discovery — Review Cycle 3

### Q120
- Category: Tier Mapping Error (REGRESSION)
- Impact: High
- Status: Answered
- Context: Cycle 2 Q113 fix introduced a NEW error: 4 of 6 discovery-* in Sonnet row.
- Answer: CONFIRMED REGRESSION — fixed in FIX cycle 3. Re-verified cycle 6+: tier table is correct.
- Applied to: host-tools-matrix.md (corrected).

### Q121
- Category: Counts / Drift (NEW propagation)
- Impact: Medium
- Status: Answered (PARTIAL — see Q130)
- Context: security-model.md summary count drift across 3 docs.
- Answer: Fixed in cycle 3 FIX. Cycle 10 hygiene re-verified counts to 1H/4M/4L/12I. BUT a stale duplicate INFO 9 row remained at L300 — see Q130.
- Applied to: security-model.md, INDEX.md, README.md.

### Q122
- Category: Counts / Drift (intra-doc contradiction)
- Impact: Medium
- Status: Answered
- Context: tech-debt.md L356-358 metrics section had HIGH=5 AND HIGH=7.
- Answer: Fixed cycle 3. Re-verified cycle 6+: only HIGH 7 present in Metrics. Clean.
- Applied to: tech-debt.md Metrics section.

### Q123
- Category: Intra-doc Contradiction
- Impact: Medium
- Status: Answered
- Context: README.md L48 146 terms vs L30 150 terms.
- Answer: Fixed cycle 3. Re-verified cycle 6+: both rows now say 150. Clean.
- Applied to: README.md L48.

### Q124
- Category: Counts / Drift
- Impact: Low
- Status: Answered
- Context: README.md L35 feature-inventory line count.
- Answer: Verified cycle 6+: README says 62, wc -l returns 62. Self-consistent.
- Applied to: (no change needed).

### Q125
- Category: Stale Snapshot
- Impact: Low
- Status: Answered
- Context: infrastructure.md section 9 stale byte-count listing.
- Answer: Fixed cycle 3. Re-verified cycle 6+: section 9 now contains pointer note. Clean.
- Applied to: infrastructure.md.

### Q126
- Category: Framing / Incomplete Information
- Impact: Low
- Status: Answered
- Context: module-map/data-model/architecture flag ui-architecture.md as missing without noting install-tree stubs exist.
- Answer: Fixed cycle 3. Re-verified cycle 6+: all 3 docs acknowledge install-tree variants. Clean.
- Applied to: module-map.md Module 10, data-model.md, architecture.md Pattern 4.

---

## Discovery — Review Cycle 4

### Q130
- Category: Counts / Drift (intra-doc contradiction)
- Impact: Medium
- Status: Answered
- Context: security-model.md Summary table had duplicate INFO N rows (12 + stale 9).
- Answer: Fixed in cycle 4 FIX. Re-verified cycle 6+: only one INFO row at L298. Clean.
- Applied to: security-model.md Summary table.

### Q131
- Category: Stale Phase-Count References
- Impact: Medium
- Status: Answered
- Context: data-model.md L9 / L422 / L527 + INDEX.md L10 11 phases survivals.
- Answer: Fixed in cycle 4 FIX. Re-verified cycle 6+: 11-phase references gone, all 4 sites say 10 SKILL files. Clean.
- Applied to: data-model.md L9, L422, L527; INDEX.md architecture row.

### Q132
- Category: Meta-doc Misclassification
- Impact: Medium
- Status: Answered
- Context: CLAUDE.md L77 16 documents + 4 meta-docs stale per Q102 canonical taxonomy.
- Answer: Fixed in cycle 4 FIX. Re-verified cycle 6+: L77 says 16 standard KB documents + 3 meta-docs + 1 generated pre-pass + extensions outside the standard 16. Clean.
- Applied to: CLAUDE.md (worktree root) Pattern 4 paragraph.

### Q133
- Category: Stale Filename References
- Impact: Low
- Status: Answered
- Context: security-model.md L151 + L159 stale additional-info.md references.
- Answer: Fixed L151 + L159 in cycle 4 FIX. Cycle-5 FIX completed by fixing L303 per Q141.
- Applied to: security-model.md L151 + L159 (cycle 4); L303 (cycle 5 per Q141).

---

## Discovery — Review Cycle 6 (new questions from cycle-6 review)

### Q140
- Category: Counts / Drift (propagation incomplete — Q112 follow-up)
- Impact: Medium
- Status: Answered
- Context: feature-inventory.md body table has 12 Shipped + 6 Partial = 18 but INDEX.md L23 + README.md L35 said 10 Shipped, 8 Partial.
- Answer: Fixed in cycle-5 FIX. INDEX L23 + README L35 now say 12 Shipped, 6 Partial. Cycle-7/8/9/10 verified.
- Applied to: INDEX.md L23, README.md L35.

### Q141
- Category: Stale Filename References (Q133 follow-up)
- Impact: Low
- Status: Answered
- Context: Q133 cycle-4 FIX missed a third additional-info.md reference at security-model.md L303.
- Answer: Fixed in cycle-5 FIX. L303 reframed to Q102/Q115 reference. Cycle-7/8/9/10 verified.
- Applied to: security-model.md L303.


---

## Discovery — Review Cycle 7 (new questions from cycle-7 review)

### Q150
- Category: Counts / Narrative Error
- Impact: Medium
- Status: Answered
- Context: project-structure.md L147 narrative had two factual errors introduced by cycle-5 FIX rewrite.
- Answer: Fixed in FIX cycle 6. L147 rewrite removed false "project-structure.md template also missing" claim and de-double-counted INDEX.md. Corrected: 17 files = 15 KB-doc templates + 2 meta-doc templates. Cycle-8/9/10 verified.
- Applied to: project-structure.md L147.

### Q151
- Category: Convention Drift Disclosure (parallel construction)
- Impact: Low
- Status: Answered
- Context: coding-standards.md §2.3 L131 still said "Not re-read this pass" while §2.2 had been updated to VERIFIED.
- Answer: Fixed in FIX cycle 6. §2.3 L131 updated to VERIFIED post-cycle-7 with direct read of profiles/cursor/.cursor/agents/architect.md:1-7. Cycle-8/9/10 verified.
- Applied to: coding-standards.md §2.3 L131.

### Q152
- Category: Alphabetic Ordering
- Impact: Low
- Status: Answered (introduced Q160 narrative back-reference bug — resolved in cycle 8 FIX)
- Context: domain-glossary.md L120 Haiku tier entry alphabetically misplaced.
- Answer: Fixed in FIX cycle 6. Haiku tier relocated from L120 to L82 (between Greenfield and Hook). Single occurrence verified. Cycle-8/9/10 verified relocation held. The L171 narrative back-reference was updated in cycle 8 FIX per Q160.
- Applied to: domain-glossary.md (Haiku tier relocated L120 → L82).


---

## Discovery — Review Cycle 8 (new questions from cycle-8 review)

### Q160
- Category: Narrative Back-Reference (regression introduced by Q152 FIX)
- Impact: Low
- Status: Answered
- Context: domain-glossary.md L171 Cross-Reference Notes bullet said "Haiku tier appears in the tier table but not as a standalone glossary entry above" — but the cycle-6 FIX (Q152) relocated the standalone entry from L120 to L82. The L171 narrative became stale.
- Suggested: Either delete the L171 bullet or rewrite it as a navigation note. Option chosen: rewrite.
- Question: Delete or rewrite the now-stale L171 narrative back-reference?
- Answer: Fixed in cycle 8 FIX turn. Updated L171 to "Haiku tier appears both in the tier table AND as a standalone glossary entry above (alphabetized at the H-section per DISCOVERY-STATE Q152 cycle-6 fix). The standalone entry is the canonical reference; this cross-reference note is preserved for navigation continuity." Cycle-9/10 verified.
- Applied to: domain-glossary.md L171.


---

## Discovery — Review Cycle 9 (new questions from this review)

### Q170
- Category: Counts / Cross-Doc Inconsistency (systemic skills-count error)
- Impact: Medium
- Status: Answered
- Context: 5 KB documents at 14 narrative sites claim AID has "11 skills" — disk verification (cycle 9) confirms only **10 SKILL.md files** exist per install tree.
- Answer: Fixed in cycle 8 FIX turn. Bulk sed + individual Edit replacements across the 14 sites + 4 module-map subfile breakdowns + project-structure.md L244. Cycle-10 verified: `grep -nE "11 [Ss]kill" .aid/knowledge/*.md | grep -v DISCOVERY-STATE` returns 0 matches. Disk `find` counts confirm subfile breakdowns (claude=24 total = 10 SKILL + 11 references + 2 scripts + 1 README; codex=12; cursor=12). `ls skills/` = 10 confirms project-structure L244.
- Applied to: `api-contracts.md` L52/L58/L455; `domain-glossary.md` L136; `integration-map.md` L21/L25/L49/L63; `project-structure.md` L238/L240/L241/L244; `module-map.md` L64/L97/L114.

---

## Gaps found during /aid-summarize visual inspection (2026-05-21)

### Q180
- Category: KB Completeness — under-documented design concept
- Impact: Medium
- Status: Answered
- Context: During the human visual-inspection (V1) gate of `/aid-summarize`, the user observed that the Knowledge Base's **RAG / progressive-disclosure structure** was not represented. Investigation: the three mechanisms WERE each documented separately — Tier 1 (INDEX.md always loaded, ~200-500 tokens) and Tier 2 (one KB doc on demand) at `architecture.md:291`; Tier 3 (inline `path:line` citations → exact repo location) at `coding-standards.md §4.4`. But the KB did NOT present them as a unified, deliberate **3-tier context-economy model** — Tier 3 was framed only as an accuracy/sourcing convention, not as a context-navigation layer, and the "why" (keep the agent's context lean; never bulk-load the repo) was stated only for Tier 1. A genuine partial KB gap for a load-bearing design concept.
- Answer: Fixed in this turn. Expanded `architecture.md` Pattern 4 ("The Knowledge Base as gravitational center") with a new subsection **"Progressive disclosure — the 3-tier context-economy model"** that unifies the three already-documented mechanisms into one explicit design: Tier 1 INDEX.md (always loaded) → Tier 2 specific KB doc (on demand, fixed-shape navigation) → Tier 3 exact repo `path:line` (via citation, never bulk-loaded). No invented facts — pure synthesis of `architecture.md:291` + `coding-standards.md §4.4`. The `/aid-summarize` HTML summary gained a new Figure 3 ("RAG-by-convention — the 3-tier context economy") in §3 representing it.
- Applied to: `.aid/knowledge/architecture.md` Pattern 4 (new "Progressive disclosure" subsection).

## KB staleness found during /aid-interview cross-reference (2026-05-22)

### Q181
- Category: KB Staleness — abolished artifacts
- Impact: High
- Status: Answered
- Context: The cross-reference validation of work-001-aid-lite (`/aid-interview` State 6, 2026-05-22) found that the Knowledge Base — generated 2026-05-21 and approved A+ the same day — references AID artifacts and templates that were **abolished after KB approval** by the subsequent methodology-correctness cleanup. Stale references to the non-existent `DETAIL.md`, `GAP.md`, `DELIVERY-{id}.md`, `REVIEW.md`, `TEST-REPORT.md`, `additional-info.md`, and the deleted `detail-template.md` / `delivery-template.md` / `review-template.md` / `test-report-template.md` / `correction-template.md` span 12 KB docs — including whole schema sections (`api-contracts.md` §`GAP.md` schema; `data-model.md` §2.6 `DETAIL.md`), artifact tables (`architecture.md`, `module-map.md`), glossary terms (`domain-glossary.md`: DETAIL.md, GAP.md, REVIEW.md, TEST-REPORT.md, DELIVERY), plus `feature-inventory.md`, `project-structure.md`, `coding-standards.md`, `technology-stack.md`, `test-landscape.md`, and the generated `project-index.md` and `knowledge-summary.html`. A downstream phase (e.g. `/aid-specify`) reading this KB would design against phantom artifacts.
- Suggested: Re-run `/aid-discover` (a full `--reset` re-discovery is cleanest given the breadth) against the current post-cleanup codebase, then `/aid-summarize` to regenerate `knowledge-summary.html`. Current canonical AID artifact model to discover against: no `DETAIL.md` (task decomposition + execution graph live in `PLAN.md`); no `GAP.md` (KB/upstream gaps use Q&A entries in STATE files); no `REVIEW.md` / `TEST-REPORT.md` (review/test outcomes live in `task-NNN-STATE.md`); no `DELIVERY-{id}.md` (deliveries are sections in `PLAN.md`); no `additional-info.md` (consolidated into DISCOVERY-STATE `## Q&A`).
- Question: Re-discover the KB now (recommended — before `/aid-specify` runs for work-001-aid-lite) or defer?
- Answer: Resolved 2026-05-22 by a targeted surgical re-sync — not `--reset` (that would have destroyed the A+ KB and its 181-entry Q&A / 24-cycle history to fix artifact references). 12 KB docs were corrected to the current artifact model (no `DETAIL.md` / `GAP.md` / `REVIEW.md` / `TEST-REPORT.md` / `DELIVERY-{id}.md` / `additional-info.md`; `task-NNN.md` follows the 6-section template; `PLAN.md` holds the execution graph; review/test outcomes live in `task-NNN-STATE.md`). `project-index.md` regenerated via `build-project-index.sh`. Verified by re-grep (only intentional negations and this file's own history remain) and spot-reads of the schema rewrites. `knowledge-summary.html` was NOT regenerated — it is generated output; run `/aid-summarize` to refresh it.
- Applied to: api-contracts.md, architecture.md, data-model.md, domain-glossary.md, feature-inventory.md, module-map.md, project-structure.md, technology-stack.md, test-landscape.md, coding-standards.md, tech-debt.md, project-index.md.

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2 | 2026-05-21 | — | aid-discover (pre-REVIEW hygiene + extension) | Pre-grade cleanup + host-tools-matrix.md extension. |
| 3 | 2026-05-21 | D- | aid-discover (REVIEW cycle 1) | 1 CRITICAL, 5 HIGH, 6 new Q-entries (Q100-Q105). |
| 4 | 2026-05-21 | D- | aid-discover (Q&A) | 51 Q&A entries resolved. |
| 5 | 2026-05-21 | D- | aid-discover (FIX cycle 1) | Applied all 51 resolutions. |
| 6 | 2026-05-21 | D | aid-discover (REVIEW cycle 2) | 0 CRITICAL, 4 HIGH, 6 new Q-entries (Q110-Q115). |
| 7 | 2026-05-21 | D | aid-discover (Q&A + FIX cycle 2) | All 6 auto-answered, 4 HIGH count drifts fixed inline. |
| 8 | 2026-05-21 | D | aid-discover (REVIEW cycle 3) | 0 CRITICAL, 1 HIGH (Q120 regression), 7 new Q-entries (Q120-Q126). |
| 9 | 2026-05-21 | D | aid-discover (Q&A + FIX cycle 3) | All 7 auto-answered, 6 inline corrections applied. |
| 10 | 2026-05-21 | D | aid-discover (pre-grade hygiene sweep) | Comprehensive count-verification sweep. |
| 11 | 2026-05-21 | C | aid-discover (REVIEW cycle 4) | 0 CRITICAL, 0 HIGH, 4 MEDIUM (Q130-Q133). |
| 12 | 2026-05-21 | C | aid-discover (Q&A + FIX cycle 4) | All 4 Q130-Q133 auto-answered and FIXED. |
| 13 | 2026-05-21 | C (DISPUTED) | aid-discover (orchestrator note) | Cycle-5 + cycle-5b reviewer hallucinations confirmed. Re-dispatching with grep-first instruction. |
| 14 | 2026-05-21 | C | aid-discover (FIX cycle 5 + R29 implementation) | Authored templates/scripts/verify-kb-claims.sh. First run: 898/898 valid citations, 0 drifts. |
| 15 | 2026-05-21 | B+ | aid-discover (REVIEW cycle 6) | 0 CRITICAL, 0 HIGH, 2 MEDIUM (Q140), 8 LOW (incl. Q141), 22 MINOR. 37 spot-checks. 2 new Q-entries. |
| 16 | 2026-05-21 | B+ | aid-discover (Q&A + FIX cycle 5) | Q140 + Q141 both fixed. 8 LOWs from cycle-6 addressed. project-structure L147 KB-templates count enumeration introduced NEW errors — see cycle 7 Q150. |
| 17 | 2026-05-21 | A- | aid-discover (REVIEW cycle 7) | 0 CRITICAL, 0 HIGH, 1 MEDIUM (Q150), 2 LOW carryover (Q151, Q152), ~25 MINOR. 26 spot-checks. 3 new Q-entries. |
| 18 | 2026-05-21 | A- | aid-discover (Q&A + FIX cycle 6) | Q150 + Q151 + Q152 all fixed. project-structure L147 rewritten, coding-standards §2.3 verified, Haiku relocated L120 to L82. Verification script v6: 897/898 valid, 0 drifts. Awaiting cycle 8 review. |
| 19 | 2026-05-21 | A | aid-discover (REVIEW cycle 8) | 0 CRITICAL, 0 HIGH, 0 MEDIUM, 1 LOW (Q160 — narrative back-reference regression introduced by Q152 FIX). ~21 MINOR. 26 spot-checks. 1 new Q-entry (Q160). |
| 20 | 2026-05-21 | A | aid-discover (Q&A + FIX cycle 7) | Q160 auto-answered and FIXED. domain-glossary.md L171 updated to reflect post-Q152 state. |
| 21 | 2026-05-21 | C+ | aid-discover (REVIEW cycle 9) | 0 CRITICAL, 0 HIGH, 5 MEDIUM (single systemic root: "11 skills" claim contradicts disk-verified 10 SKILL.md per install tree, manifests across api-contracts.md, domain-glossary.md, integration-map.md, module-map.md, project-structure.md at 14 narrative sites + 2 secondary breakdown errors), 0 LOW, ~21 MINOR. 24 spot-checks. 1 new Q-entry (Q170). |
| 22 | 2026-05-21 | C+ (pending re-review) | aid-discover (Q&A + FIX cycle 8) | Q170 auto-answered. FIX: corrected the 14 "11 skills" sites + 4 module-map subfile breakdowns + project-structure L244 entry count, all to disk-verified canonical "10 SKILL.md per install tree" (per Q16). Bulk sed-replace + 5 targeted Edits. Disk re-verification all green. |
| 23 | 2026-05-21 | **A+** | aid-discover (REVIEW cycle 10 — THIS REVIEW) | **0 CRITICAL, 0 HIGH, 0 MEDIUM, 0 LOW, ~21 MINOR (cosmetic only).** 25 spot-checks (all verified, 0 drift). 0 new Q-entries. verify-kb-claims.sh v8 foreground run: 896/896 valid citations, 0 README drifts, 0 spot-check drifts. **All cycle-9 Q170 FIX sites verified held cleanly on disk** (14 narrative sites + 4 module-map subfile breakdowns + project-structure L244 entry count). `grep -nE "11 [Ss]kill" .aid/knowledge/*.md \| grep -v DISCOVERY-STATE` returns 0 matches. Cross-doc consistency: complete. **Strict rubric per templates/grading-rubric.md: worst severity = MINOR (cosmetic only), zero count-level issues = A+.** **APPROVED for next AID phase (Interview).** KB meets the A+ minimum-grade bar set in project metadata. Skills-count load-bearing fact is now consistent at "10 SKILL.md per install tree" across all 19 KB docs. Downstream skills (aid-interview, aid-specify, aid-plan) will read consistent inputs. Script verification provides a regression-detection floor for future drift. |
| 24 | 2026-05-21 | A+ (USER APPROVED) | aid-discover (APPROVAL) | User explicitly approved the KB for the next AID phase (Interview) via AskUserQuestion. `**User Approved:**` flipped to `yes`. State machine transitions to DONE. KB is ready for downstream phases (`/aid-interview`, `/aid-specify`, `/aid-plan`, etc.). |
| 25 | 2026-05-22 | A+ (re-sync) | /aid-interview (cross-reference) | Targeted re-sync after the methodology-correctness cleanup abolished DETAIL.md / GAP.md / REVIEW.md / TEST-REPORT.md / correction-template and the delivery/detail/review/test-report templates. 12 KB docs corrected to the current artifact model; project-index.md regenerated. Surgical correction — A+ content and the full Q&A history preserved (no --reset). See Q181. knowledge-summary.html pending a /aid-summarize refresh. |

## Summarization History

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | 2026-05-21 | A+ | cli (pipeline-focused) | 11.15.0 | knowledge-summary.html (~3.39 MB, 9 diagrams) | Initial generation. Overall A+ = Machine A+ (73/73) + Human A+ (30/30: K1 completeness 10 · K2 facts 15 · V1 human visual gate 5). The aid-summarize grading system was overhauled this session (two-grade model, mandatory V1 visual gate, per-profile diagram counts, real D2 render check, A3 auto-detection, literal-`\n` D1 guard) — see DISCOVERY-STATE Q180 and tech-debt H8. Visual inspection (V1) ran multiple rounds: dark-mode contrast, FIG6 line-breaks, FIG1 grouping + forward-flow simplification, new Figure 3 (RAG / 3-tier context economy). |
