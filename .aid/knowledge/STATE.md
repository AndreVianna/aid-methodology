# Discovery State

> **Status:** Cycle-22 adversarial re-grade — **C+** (Needs Improvement). Cycle-21 parallel-FIX wave (commit `c38a31e`) EFFECTIVE on ~85% of dispatched scope. **VERIFIED ON DISK:** feature-inventory L30 + L32 reclassified ✅ Shipped (Q70/H6 RETIRED); L48 "22 ✅ Shipped, 3 ⚠️ Partial" with explicit ID enum; L57+L59 cross-ref updated to "RESOLVED 2026-05-22"; L69 Notes "Q70 verification CLOSED". README L35 "**22 ✅ Shipped, 3 ⚠️ Partial**" matches feature-inventory. INDEX.md L23 "22 ✅ Shipped, 3 ⚠️ Partial" matches (orchestrator post-agent reconciliation landed). Host-tools-matrix L122 "repo repository" typo GONE. Coding-standards L378 "(85 + 137 lines respectively)" ✓. Api-contracts L278 "(85 lines)" ✓. Ui-architecture L286 STATE.md `## Knowledge Summary Status` ✓. **NEW HIGH cycle-22 finding (scope-miss, not legacy):** host-tools-matrix.md Section 5 Row 1 (L92) still classifies Q70 as **HIGH "CONFIRMED — patch tracked in tech-debt.md H6"**, AND Section 2 cells L49 (setup.sh) + L50 (setup.ps1) still say "❌ **CONFIRMED BUG (Q70)**" / "❌ **CONFIRMED same Q70 omission**" — but Q70/H6 was RESOLVED 2026-05-22 per tech-debt.md L100 (H6 RETIRED), infrastructure.md L68, INDEX.md L21, feature-inventory.md L30/L32/L57/L59, AND disk-truth (setup.sh L145 `copy_dir "$SCRIPT_DIR/profiles/codex/.agents" "$TARGET/.agents"`; setup.ps1 L140 `Copy-Dir-Safe -SrcDir (Join-Path $ScriptDir "profiles\codex\.agents") -DstDir (Join-Path $Target ".agents")`). 6-doc internal contradiction (5 KB docs + setup-script disk truth all agree RESOLVED; host-tools-matrix says CONFIRMED in 3 sites). The cycle-21 wave's host-tools-matrix dispatch scope was "retired-vocab + typo only" — did NOT include the Section 5 row-1 status refresh or Section 2 capability-cell refresh. **Disk-truth check:** domain-glossary 161 terms verified (`grep -c "^| \*\*"` = 161); SKILL.md aid-deploy=147/aid-detail=77/aid-discover=307/aid-execute=279/aid-init=119/aid-interview=357/aid-monitor=223/aid-plan=208/aid-specify=207/aid-summarize=233 (2,157 total); methodology=1071, run_generator=84, setup.sh=162, setup.ps1=157, IMPEDIMENT=116, work-state-template=137, discovery-state-template=85, parse-recipe=540 (located at canonical/skills/aid-interview/scripts/), discovery-reviewer/AGENT=405 — all match prompt assertions. Recipes catalog: 5 recipe .md files + README + .gitkeep ✓. verify-kb-claims.sh exits 0 (all checks passed; README line-count drifts: 0; Spot-check drifts: 0; tech-debt HIGH=8 MEDIUM=6 LOW=8). **Net cycle-22 result:** cycle-21 wave RESOLVED most of its declared scope (~85%) — feature-inventory cross-doc cascade closed, README count cascade closed, sibling-doc line-count contradictions cleared, INDEX.md reconciliation landed. 1 surviving HIGH (host-tools-matrix.md 3-site Q70 status — not in cycle-21 dispatch scope). 1 MEDIUM (host-tools-matrix L64 "DISCOVERY-STATE Q52" retired vocab missed). 1 LOW (host-tools-matrix L137 "Q3 / Q72" — Q3 already RESOLVED elsewhere in same doc). 2 MINOR (glossary L168 + L173 retired-filename refs without "retired" qualifier).
> **Minimum Grade:** A+
> **Current Grade:** C+ (post-cycle-21-parallel-FIX cycle-22 adversarial re-grade)
> **User Approved:** yes (2026-05-21) — **stale; predates work-001/work-002/work-003 deploys + cycles 17-22**
> **Heartbeat Interval:** 1 minute
> **Max Parallel Tasks:** 5
> **Last KB Review:** 2026-05-25 (cycle 22, post-cycle-21-parallel-FIX adversarial re-grade)
> **Last Summary:** 2026-05-21
> **Project Type:** Brownfield

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary.

## Cycle-22 Per-Document Grades

| Document | Grade | Status | Issues |
|----------|-------|--------|--------|
| project-structure.md | A- | Pass | [MINOR-mechanical-deferrable] L7 cycle-11 project-index baseline; stable. |
| external-sources.md | A | Pass | L60=405 ✓, L61=307 ✓, L75=62 ✓, L76=399 ✓, L78=307 ✓, L93=307 ✓ all disk-verified. 8 vendor URLs still Pending fetch (deferred per Q80). |
| architecture.md | A | Pass | Solid. All cycle-19 structural rewrites preserved (Pattern 3/5/7 canonical-generator framed). |
| technology-stack.md | B+ | Below minimum | [MINOR-mechanical-deferrable] L17 file count cycle-11 vintage. Build/Lint Commands runnable. |
| module-map.md | B | Below minimum | [MEDIUM-mechanical-deferrable] L150 discovery-reviewer.md "(378)" — disk profile=402 (24-line drift); L318 "(~314 TOML)" — disk codex.toml=399 (85-line drift). Cycle-21 wave scope did not include. |
| coding-standards.md | A | Pass | **Cycle-21 wave RESOLVED.** L378 "(85 + 137 lines respectively)" ✓ — sibling-doc alignment with data-model.md achieved. |
| data-model.md | A | Pass | L22/L24/L51 all cite discovery-state-template (85 lines) + work-state-template (137 lines) — disk-true and self-consistent. |
| api-contracts.md | A | Pass | **Cycle-21 wave RESOLVED.** L278 "(85 lines)" ✓ — sibling-doc alignment with data-model.md. Recipe File Schema (L409-449) accurate against parse-recipe.sh. |
| integration-map.md | B | Below minimum | [MEDIUM-mechanical-deferrable] L21 64 files, L39 353-file inventory, L63 ≈80 files all cycle-11 baseline (disk: 194/631/196). Not in cycle-21 dispatch scope. |
| domain-glossary.md | A- | Pass | 161 terms verified (`grep -c "^| \*\*"` = 161). 10 work-001 entries (Recipe L138, parse-recipe L125, Thin-Router L159, Two-Tier L166, Delivery gate L57, Pool dispatch L130, compute-block-radius L48, writeback-task-status L176, complexity-score L41, dispatch-protocol-checklist L63) all semantically accurate against source scripts/docs. [MINOR] L168 "User Approved" cites "[[DISCOVERY-STATE.md]]" + L173 "Work" cites "[[INTERVIEW-STATE.md]]" — both retired filenames per FR2; entries lack inline "retired/legacy" qualifier (unlike L165 "Triplication" which correctly says "retired pattern — superseded by canonical-generator"). |
| test-landscape.md | A- | Pass | L209-211 enumeration of 7 test scripts + 297-test total accurate (69+18+17+7+113+35+38=297). Test Commands runnable. |
| security-model.md | A- | Pass | §1.2 HISTORICAL framing preserved. 21-finding split (1H+4M+4L+12I) consistent (verify-kb-claims confirms HIGH=1 MEDIUM=4 LOW=4 INFO=12). |
| tech-debt.md | A- | Pass | H6 RETIRED past-tense framing preserved (L100). L57 run_generator.py "~84 lines" matches disk. verify-kb-claims confirms HIGH=8 MEDIUM=6 LOW=8 totals. |
| infrastructure.md | B+ | Below minimum | [MINOR-mechanical-deferrable] L25 "Current branch per git status: master" — actually `kb-cycle-17-fix` per `git branch --show-current`. L68 "Both installers correctly copy `.agents/` in the Codex branch as of 2026-05-22" ✓. |
| ui-architecture.md | A | Pass | **Cycle-21 wave RESOLVED.** L286 STATE.md `## Knowledge Summary Status` ✓. |
| feature-inventory.md | A | Pass | **Cycle-21 wave RESOLVED 4 HIGH cascades.** L30 (Feature #13) ✅ Shipped — installer bug RESOLVED 2026-05-22 (Q70/H6 RETIRED) ✓. L32 (Feature #15) ✅ Shipped — Q70/H6 RESOLVED 2026-05-22 ✓. L31 (Feature #14) + L35 (Feature #18) vocab refreshed to "canonical-generator workflow" / "retired manual-update rule" ✓. L48 "22 ✅ Shipped, 3 ⚠️ Partial" with explicit ID enum ✓. L49 Partial = Features 10, 14, 18 ✓. L57+L59 Per-Feature Health updated to "RESOLVED 2026-05-22 — H6 RETIRED" ✓. L69 Notes "Q70 verification CLOSED" ✓. |
| STATE.md (META) | B+ | Below minimum | [MINOR] Preserves cycles 17-21 Review History rows + Q&A entries Q190-Q217. Adds Q218 for new cycle-22 HIGH gap. |
| INDEX.md | A | Pass | **Cycle-21 orchestrator reconciliation LANDED.** L23 "**22 ✅ Shipped, 3 ⚠️ Partial**" matches feature-inventory L48 + README L35. L8 canonical-generator framing ✓; L13 canonical-generator-rendered ✓; L17 domain-glossary 161 terms ✓; L21 Codex `.agents/` copy bug RESOLVED 2026-05-22 ✓; L30 work-001 SHIPPED 5 features ✓. |
| README.md | A- | Pass | **Cycle-21 wave RESOLVED feature count cascade.** L35 "**22 ✅ Shipped, 3 ⚠️ Partial**" matches feature-inventory L48 ✓. L30 domain-glossary "**161 terms**" ✓. L20-36 line counts substantially refreshed. verify-kb-claims reports "README line-count drifts: 0". L65 Revision History "Net result: 7 CRITICAL to 0" overtaken but framed historically. |
| host-tools-matrix.md | D+ | Below minimum | [HIGH] **NEW cycle-22 finding — UNREFRESHED Q70 status (3 sites).** Section 5 Row 1 (L92) Severity=HIGH Status="**CONFIRMED — patch tracked in `tech-debt.md H6`**" Q&A=Q70 — but Q70/H6 RESOLVED 2026-05-22 per tech-debt L100 + infrastructure L68 + INDEX L21 + feature-inventory L30/L32/L57/L59 + setup.sh L145 + setup.ps1 L140. Section 2 cells L49 (setup.sh row) "❌ **CONFIRMED BUG (Q70)**" and L50 (setup.ps1 row) "❌ **CONFIRMED same Q70 omission** as `setup.sh` (lines 137-141)" — same 3-site contradiction. 6-doc internal contradiction. Cycle-21 wave's host-tools-matrix dispatch (retired-vocab + typo) DID NOT include the Section 5 row-1 status refresh or Section 2 capability-cell refresh. [MEDIUM] L64 "Per DISCOVERY-STATE Q52" — retired vocab per FR2 (should be `.aid/knowledge/STATE.md` Q52); cycle-21 sweep enumerated L88+L93+L143 + L5/L95/L134/L142 but L64 not enumerated. [LOW] L137 Section 7 "still-unresolved cross-tree-sync question from **Q3 / Q72**" — but Q3 is RESOLVED per Section 2 row 3 + Section 5 row 3 of the same document (internal contradiction within same file, 3 lines apart). |
| CLAUDE.md (project root) | A | Pass | Solid full rewrite. L8 methodology 1,071 OK. L43-49 test suite enumeration (69+18+17+7+113+35+38=297) verified TRUE. L78-82 Recipes catalog accurate. L83-85 L1+L2+L3 visibility narrative accurate. Thin-Router architectural summary matches coding-standards §10. [MINOR-mechanical-deferrable] L65 "Total skill body lines: 2,108" — actual disk sum is 2,157. |

## Cycle-22 Findings — Summary by Severity

**CRITICAL (0):** None. SKILL.md / canonical script line counts 100% match disk per orchestrator pre-flight cleanup. Recipe schema accurate. Domain-glossary 161 terms verified. verify-kb-claims exits 0. Cycle-21 wave's primary dispatch targets (feature-inventory cross-doc cascade, README feature count, host-tools-matrix retired-vocab + typo, coding-standards/api-contracts/ui-architecture mop-ups, INDEX reconciliation) ALL verified resolved on disk.

**HIGH (1):**
1. `host-tools-matrix.md` Section 5 Row 1 (L92) + Section 2 cells L49 + L50 still classify Q70/H6 as Severity=HIGH Status="CONFIRMED BUG" — but Q70/H6 was RESOLVED 2026-05-22 per 5 sibling primary docs (tech-debt L100 H6 RETIRED, infrastructure L68, INDEX L21, feature-inventory L30/L32/L57/L59) AND disk-truth (setup.sh L145 invokes `copy_dir profiles/codex/.agents`; setup.ps1 L140 invokes `Copy-Dir-Safe ... profiles\codex\.agents`). 6-doc internal contradiction. Cycle-21 wave's host-tools-matrix scope was retired-vocab + typo only — DID NOT include the Section 5 row-1 status migration or Section 2 cell-status refresh. Adopter agents reading host-tools-matrix.md for parity / risk will get a stale CONFIRMED HIGH BUG narrative for an issue that has been RESOLVED for 3+ days.

**MEDIUM (1):**
- `host-tools-matrix.md` L64 "Per DISCOVERY-STATE Q52" — retired vocab per FR2 (should be `.aid/knowledge/STATE.md` Q52). Cycle-21 retired-vocab sweep missed this site.

**LOW (1):**
- `host-tools-matrix.md` Section 7 L137 "the still-unresolved cross-tree-sync question from **Q3 / Q72**" — but Q3 is RESOLVED per Section 2 row 3 + Section 5 row 3 of the same document. Internal contradiction within the same file.

**MINOR (2):**
- `domain-glossary.md` L168 "User Approved" cites "[[DISCOVERY-STATE.md]]" + L173 "Work" cites "[[INTERVIEW-STATE.md]]" — both retired filenames per FR2. Entries lack inline "retired/legacy" qualifier (unlike L165 "Triplication" which correctly says "retired").
- `host-tools-matrix.md` L142 "the canonical-generator manifest → 5-way" — minor framing residual (vocab partly modernized but blurs the canonical-generator's single-source role with the "5-way" multiplier; not a contradiction, just imprecise).

**[MINOR-mechanical-deferrable] (NOT counted against grade per prompt):**
- `module-map.md` L150 discovery-reviewer.md "(378)" — disk=402; L318 "(~314)" — disk=399.
- `integration-map.md` L21/L39/L63 file counts cycle-11 baseline (disk: 194/631/196).
- `infrastructure.md` L25 "Current branch: master" — actually `kb-cycle-17-fix`.
- `technology-stack.md` L17 Markdown file count cycle-11 vintage.
- `CLAUDE.md` (project root) L65 "2,108 total" — disk sum is 2,157.

## Cycle-22 Verification Spot-Checks (12 checks — SEMANTIC focus)

| # | Claim | Source | Verified | Evidence |
|---|-------|--------|----------|----------|
| C22-1 | feature-inventory L30 (Feature #13) reclassified to ✅ Shipped citing Q70/H6 RETIRED 2026-05-22 | feature-inventory.md L30 | TRUE | "✅ Shipped — installer bug RESOLVED 2026-05-22 (Q70/H6 RETIRED): `setup.sh` and `setup.ps1` both correctly copy `profiles/codex/.agents/`..." Cycle-21 wave 8A landed. |
| C22-2 | feature-inventory L48 Status Summary "22 ✅ Shipped, 3 ⚠️ Partial" with explicit ID enum | feature-inventory.md L48-49 | TRUE | L48 lists 22 IDs; L49 Partial = "Features 10, 14, 18". Internally consistent. |
| C22-3 | README.md L35 feature-inventory cell reads "22 ✅ Shipped, 3 ⚠️ Partial" | README.md L35 | TRUE | "**25 features** (...) **22 ✅ Shipped, 3 ⚠️ Partial**". Cycle-21 wave 8B landed. |
| C22-4 | INDEX.md L23 feature count "22 ✅ Shipped, 3 ⚠️ Partial" (cycle-21 orchestrator post-agent reconciliation) | INDEX.md L23 | TRUE | "**22 ✅ Shipped, 3 ⚠️ Partial** (cross-linked to Q-IDs; cycle-20 reclassified #16 Shipped post-canonical-generator; cycle-21 reclassified #13 + #15 Shipped post-Q70/H6 RESOLVED)." Reconciliation landed. |
| C22-5 | host-tools-matrix Section 5 Row 1 (Codex setup bug) status refreshed from CONFIRMED to RESOLVED per cycle-21 cascade | host-tools-matrix.md L92 | FALSE — UNREFRESHED | L92 still says "❌ ... CONFIRMED via reviewer static-analysis spot-check. \| HIGH \| **CONFIRMED — patch tracked in `tech-debt.md H6`** \| **Q70**". Cycle-21 wave host-tools-matrix scope did NOT include Section 5 status refresh. 6-doc contradiction. |
| C22-6 | host-tools-matrix Section 2 cells L49 + L50 refreshed from "❌ CONFIRMED BUG" to "✅ Ships" per cycle-21 cascade | host-tools-matrix.md L49-50 | FALSE — UNREFRESHED | L49: "❌ **CONFIRMED BUG (Q70)** — copies `profiles/codex/.codex/` + `AGENTS.md` but omits `profiles/codex/.agents/` (skills + templates). Patch trivial; tracked as `tech-debt.md H6`."; L50: "❌ **CONFIRMED same Q70 omission** as `setup.sh` (lines 137-141)." Same root contradiction with disk-truth. |
| C22-7 | host-tools-matrix L122 "repo repository" typo fixed per cycle-21 mop-up | host-tools-matrix.md L122 | TRUE | "Total estimated 4-way duplicated content:** ~17,600 lines = ~36% of the 90,011-line repository total (post work-001 merge)." Typo absent. |
| C22-8 | host-tools-matrix retired-vocab sweep — DISCOVERY-STATE / DISCOVERY-GRADE / additional-info references migrated to STATE.md | host-tools-matrix.md grep | PARTIAL | L143 "linked Q&A entry in `.aid/knowledge/STATE.md`" ✓ (refreshed). L64 still "Per DISCOVERY-STATE Q52" — missed by sweep. L88 + L93 also refreshed. Mixed: 1 site missed. |
| C22-9 | coding-standards.md L378 sibling-doc alignment with data-model — "(85 + 137 lines respectively)" | coding-standards.md L378 | TRUE | "Canonical templates** for area STATE files: `canonical/templates/{discovery,work}-state-template.md` (85 + 137 lines respectively)." Matches data-model L22/L24/L51. |
| C22-10 | api-contracts.md L278 sibling-doc alignment — discovery-state-template "(85 lines)" | api-contracts.md L278 | TRUE | "Source-of-truth template: `canonical/templates/discovery-state-template.md` (85 lines)." Matches data-model L22. |
| C22-11 | ui-architecture.md L286 Mermaid Version reference uses STATE.md `## Knowledge Summary Status` (cycle-21 mop-up) | ui-architecture.md L286 | TRUE | "Tracked at `.aid/knowledge/STATE.md` (`## Knowledge Summary Status` section) as `**Mermaid Version:**`, ..." |
| C22-12 | domain-glossary 161 terms verified; 10 work-001 entries semantically accurate against source scripts | domain-glossary.md L6 + L41/L48/L57/L63/L125/L130/L138/L159/L166/L176 vs canonical scripts | TRUE | `grep -c "^| \*\*"` = 161. complexity-score 209-line tier thresholds ✓; compute-block-radius 293-line BFS ✓; parse-recipe 540 lines with 5 modes ✓; writeback-task-status 627 lines ✓; Recipe 5-recipe catalog ✓; Two-Tier matches state-review.md + state-delivery-gate.md ✓. |

**Cycle-22 spot-check summary:** 12 checks. **9 TRUE / 2 FALSE-unrefreshed (both on host-tools-matrix) / 1 PARTIAL = 75% pass on cycle-21 wave-landing-verification.**

**Pass-rate framing:** The cycle-21 parallel-FIX wave was effective on its 4 dispatched scopes for feature-inventory (4/4 sites refreshed correctly), README (full refresh including line counts — verify-kb-claims confirms 0 README drifts), INDEX (orchestrator post-agent reconciliation landed at L23), coding-standards mop-up (1/1), api-contracts mop-up (1/1), ui-architecture mop-up (1/1), and host-tools-matrix on the retired-vocab + typo subscope (~7/8 sites). However: the host-tools-matrix dispatch SCOPE did not include Section 5 Row 1 status refresh or Section 2 capability-table cell refresh — these are the largest remaining HIGH cascade. The dispatch scope was defined by VOCABULARY surface (cheapest wins), not by SEMANTIC contradiction surface (worst issue dominates).

## Cross-Cutting Concerns (cycle-22)

1. **The cycle-21 parallel-FIX wave's per-doc agent dispatch pattern remains EFFECTIVE within its declared scope (~85% landing).** The pattern recurs from cycle-20: dispatch scopes are sized by VOCABULARY/COSMETIC surface (cheapest wins) instead of by SEMANTIC contradiction surface (worst issue dominates). The host-tools-matrix.md dispatch was scoped to "retired-vocab + typo" — but the largest HIGH on host-tools-matrix is the Section 5 + Section 2 Q70 "CONFIRMED BUG" status contradicting 5 sibling primary docs + setup-script disk truth.

2. **host-tools-matrix.md remains the stalest primary doc relative to current sibling primaries.** Three sites (L49, L50, L92) still classify Q70/H6 as CONFIRMED HIGH BUG when 5 other docs + setup-script disk truth all confirm RESOLVED 2026-05-22.

3. **Sibling-doc line-count contradictions CLEARED.** Cycle-21 mop-up 8D/8E/8F closed the 3 remaining sibling contradictions (coding-standards L378, api-contracts L278, ui-architecture L286). 0 pending sibling-doc disagreements on canonical template line counts or retired state-file references.

4. **INDEX.md / README.md / feature-inventory.md now mutually consistent on feature counts (22/3) — 3-doc meta-doc reconciliation closed.** This was the largest cycle-21 cascade target and it landed.

5. **Cycle-22 introduces no new mechanical-drift findings beyond the pre-existing [MINOR-mechanical-deferrable] set inherited from cycles 17-21.** All asserted disk truths (SKILL.md line counts, canonical scripts, methodology, templates, installer .agents copy) verified TRUE on disk in this re-grade. verify-kb-claims.sh exits 0 (README drifts: 0; spot-check drifts: 0).

## Q&A

> Cycle-22 preserves Q190-Q217 from cycles 18-21. Q212-Q217 marked Answered by cycle-21 parallel-FIX wave (verified TRUE on disk in this re-grade — see Per-Document Grades table). Adds Q218 for cycle-22 new gap (host-tools-matrix Section 5 + Section 2 Q70 status unrefreshed).

### Q190-Q217
- (preserved from cycles 18-21; Q212-Q217 confirmed Answered by cycle-21 parallel-FIX wave commit `c38a31e`)

### Discovery — Review Cycle 5 (cycle-22 adversarial re-grade)

### Q218: [Knowledge Base: High] Should host-tools-matrix.md Section 5 Row 1 (Codex setup bug) be reclassified from Severity=HIGH Status="CONFIRMED — patch tracked in tech-debt.md H6" to Status="RESOLVED 2026-05-22 (H6 RETIRED)" — and should Section 2 capability-table cells L49 (setup.sh row) + L50 (setup.ps1 row) be refreshed from "❌ CONFIRMED BUG (Q70)" to "✅ Ships — Codex .agents/ copy added per H6 fix"?

**Status:** Pending
**Context:** Q70/H6 was RESOLVED 2026-05-22 per 5 sibling primary docs (tech-debt.md L100 "H6 — ... RETIRED 2026-05-22"; infrastructure.md L68 "Both installers correctly copy `.agents/` in the Codex branch as of 2026-05-22"; INDEX.md L21 "Codex `.agents/` copy bug RESOLVED 2026-05-22"; feature-inventory.md L30 + L32 + L57 + L59) AND disk-truth (setup.sh L145 `copy_dir "$SCRIPT_DIR/profiles/codex/.agents" "$TARGET/.agents"`; setup.ps1 L140 `Copy-Dir-Safe -SrcDir (Join-Path $ScriptDir "profiles\codex\.agents") -DstDir (Join-Path $Target ".agents")`).

However, host-tools-matrix.md still asserts the bug in 3 sites:
- **L49** (Section 2, capability-table row "setup.sh installer"): "❌ **CONFIRMED BUG (Q70)** — copies `profiles/codex/.codex/` + `AGENTS.md` but omits `profiles/codex/.agents/` (skills + templates). Patch trivial; tracked as `tech-debt.md H6`."
- **L50** (Section 2, capability-table row "setup.ps1 installer"): "❌ **CONFIRMED same Q70 omission** as `setup.sh` (lines 137-141)."
- **L92** (Section 5 Row 1, Known Divergences and Bugs): "❌ `setup.sh` / `setup.ps1` Codex branches copy `profiles/codex/.codex/` + `AGENTS.md` but **omit** `profiles/codex/.agents/` ... CONFIRMED via reviewer static-analysis spot-check. | HIGH | **CONFIRMED — patch tracked in `tech-debt.md H6`** | **Q70**"

6-doc internal contradiction. Adopter agents reading host-tools-matrix.md to assess parity / risk will get a stale CONFIRMED HIGH BUG narrative for an issue RESOLVED 3+ days ago.

The cycle-21 parallel-FIX wave's host-tools-matrix scope was defined as "retired-vocab + typo only" — Section 5 Row 1 status migration and Section 2 capability-cell refresh were NOT in dispatch scope. As a result, the most-cascade-prone HIGH on host-tools-matrix remained unrefreshed.

**Suggested:**
1. Section 2 L49 (setup.sh): change `❌ **CONFIRMED BUG (Q70)** — copies ...` to `✅ Ships — copies `profiles/codex/.codex/` + `profiles/codex/.agents/` + `AGENTS.md` per H6 fix 2026-05-22 (setup.sh L145).`
2. Section 2 L50 (setup.ps1): change `❌ **CONFIRMED same Q70 omission**...` to `✅ Ships — equivalent to setup.sh (setup.ps1 L140).`
3. Section 5 Row 1 (L92): change Status column from `**CONFIRMED — patch tracked in `tech-debt.md H6`**` to `**RESOLVED 2026-05-22 (H6 RETIRED per tech-debt.md L100)**`; consider moving the row to a "Section 5b — Resolved Divergences" subsection so adopters see active-vs-historical bug surface clearly.
4. While in host-tools-matrix, also fix L64 "Per DISCOVERY-STATE Q52" → "Per `.aid/knowledge/STATE.md` Q52" (retired vocab missed by cycle-21 sweep); and reconcile L137 internal contradiction "Q3 / Q72" where Q3 is already RESOLVED per Section 2 row 3 + Section 5 row 3 of same doc (drop Q3 from the L137 justification).

**Applied to:** host-tools-matrix.md (proposed); pending Pass-9 dispatch.

---

## Cycle-22 FIX-Pass Recommendation

**Trigger:** Cycle-22 reviewer found Grade **C+** — pass rate 75% on cycle-21 wave-landing-verification; 1 surviving HIGH (host-tools-matrix Q70 status in 3 sites), 1 MEDIUM (host-tools-matrix L64 retired vocab), 1 LOW (host-tools-matrix L137 internal Q3 contradiction), 2 MINOR. 0 CRITICAL.

**Targeted Pass-9 cleanup (~15-25 minutes — 1 tech-writer agent):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 9A | host-tools-matrix.md: refresh Section 2 L49 + L50 (setup.sh/setup.ps1 capability cells: ❌ CONFIRMED → ✅ Ships per H6 fix); refresh Section 5 Row 1 L92 (Severity HIGH CONFIRMED → RESOLVED 2026-05-22, optionally move to "Resolved Divergences" subsection); fix L64 "DISCOVERY-STATE Q52" → "STATE.md Q52"; reconcile L137 Section 7 "Q3 / Q72" (drop Q3 since it's RESOLVED elsewhere in same doc) (Q218) | 5 sites |

**Targeted Pass-9 mop-up (additional ~5 min):**

| Sub-pass | Scope | Estimated count |
|----------|-------|-----------------|
| 9B | domain-glossary.md L168 "User Approved" entry: add inline "(per FR2 now `.aid/knowledge/STATE.md`)" qualifier; L173 "Work" entry: add "(per FR2 now `.aid/{work}/STATE.md`)" qualifier matching L165 "Triplication" retired-pattern framing | 2 sites |

**Expected post-Pass-9 grade:** A- (target). Pass 9A closes the only remaining HIGH (host-tools-matrix Q70 status — fully reconciles the 6-doc contradiction). Pass 9B closes the 2 MINOR retired-vocab glossary entries. To reach A+: also refresh integration-map.md file counts (cycle-11 baseline → current 194/631/196), module-map.md L150 + L318 agent line counts, infrastructure.md L25 branch citation, CLAUDE.md L65 "2,108" → "2,157" — but these are [MINOR-mechanical-deferrable] per orchestrator pre-flight rule and NOT blocking.

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-21 | Pending | aid-discover (GENERATE) | Initial generation pass. |
| 2-15 | 2026-05-21 to 2026-05-23 | (D- to A+ to C to A) | aid-discover cycles 2-15 | Cycle-14 reviewer found 8 HIGH from subagent-visibility-patch; cycle-15 orchestrator self-attestation Grade A. |
| 16 | 2026-05-23 | A | orchestrator self-attestation post cycle-14 fix-pass | Applied 19 line-count drift fixes; fixed false .gitignore claim; verify-kb-claims.sh exit 0. Self-attestation only. |
| 17 | 2026-05-25 | **D** | post-work-001-merge fresh adversarial (clean-context) | PR #13 work-001 thin-router refactor invalidated KB line counts across 12+ docs by 30-77%. 7 NEW CRITICAL · 35+ NEW HIGH · 25+ NEW MEDIUM · 10+ NEW LOW/MINOR. Pass rate 29%. Triggered cycle-17 FIX-pass. |
| 18 | 2026-05-25 | **D** | post-cycle-17-FIX re-grade | Cycle-17 FIX-pass cleared dominant SKILL.md drift. Pass rate 29%→62%. CLAUDE.md fully rewritten (A). Recipes catalog, Thin-Router convention, Canonical Script Tests sections added. 3 CRITICAL residual + 35+ HIGH survive. Triggered cycle-18 Pass 5A-5L FIX-pass. |
| 19 | 2026-05-25 | **C+** | post-cycle-18-FIX re-grade | Cycle-18 Pass 5A-5L was BROADLY EFFECTIVE: 3 CRITICAL aid-discover 596/548 cites GONE; 7 tombstones GONE; .gitignore unified; run_generator.py = 84 unified across 8 docs; methodology/installers/templates unified. Pass rate 62%→84%. 0 CRITICAL surviving; 14 HIGH surviving. 3 new Q-entries added (Q209-Q211). |
| 20 | 2026-05-25 | **B** | post-cycle-19-FIX + new-workflow re-grade | Cycle-19 structural rewrites SHIPPED + orchestrator pre-flight cleanup swept ALL primary disk-truth (SKILL.md = disk for all 10 skills, 2,157 total). Feature-inventory 25 items with correct 19+6=25 math. Recipes catalog confirmed. api-contracts Recipe File Schema verified. 0 CRITICAL. 10 surviving HIGH (INDEX.md 7 stale + glossary missing 10 work-001 + external-sources L61 + feature-inventory #16). Triggered cycle-20 parallel-FIX wave. |
| 21 | 2026-05-25 | **C+** | post-cycle-20-parallel-FIX re-grade | Cycle-20 wave (4 agents, commit `a75ae66`) VERIFIED on 4 dispatch targets: INDEX 7 narratives; glossary 161 terms + 10 work-001 entries; external-sources L61/L75/L76; feature-inventory #16. 0 CRITICAL. 5 surviving HIGH (feature-inventory #13/#15 still ⚠️ Partial citing Q70; #14+#18 retired-vocab; README L35 stale 14/6; host-tools-matrix 6+ retired-vocab sites). 3 MEDIUM (coding-standards L378 sibling-doc; host-tools L122 typo; ui-architecture L286 SUMMARY-STATE). 3 LOW. 6 MINOR. Pass rate 75% on cycle-20-landing. 3 new Q-entries added (Q215-Q217). Triggered cycle-21 parallel-FIX wave. |
| 22 | 2026-05-25 | **C+** | post-cycle-21-parallel-FIX re-grade | Cycle-21 parallel-FIX wave (commit `c38a31e`, 4 tech-writer agents + orchestrator post-agent reconciliation) VERIFIED EFFECTIVE on ~85% of dispatched scope: feature-inventory #13/#15 reclassified ✅ Shipped (Q70/H6 RETIRED) + #14/#18 vocab refreshed; README L35 "22 ✅ Shipped, 3 ⚠️ Partial" matching feature-inventory L48 + 14 KB-doc line counts refreshed (verify-kb-claims reports 0 README drifts); host-tools-matrix L122 "repo repository" typo fixed + 7/8 retired-vocab sites updated; coding-standards L378 "(85 + 137)" sibling-doc alignment; api-contracts L278 "(85)" sibling-doc alignment; ui-architecture L286 SUMMARY-STATE.md → STATE.md `## Knowledge Summary Status`; INDEX.md L23 reconciled to "22 ✅ Shipped, 3 ⚠️ Partial" via orchestrator post-agent reconciliation. 0 CRITICAL. **1 surviving HIGH (NEW, scope-miss not legacy):** host-tools-matrix.md Section 5 Row 1 (L92) + Section 2 cells (L49+L50) still classify Q70/H6 as **HIGH "CONFIRMED BUG"** — 6-doc internal contradiction (5 KB docs + setup-script disk truth all agree RESOLVED 2026-05-22; host-tools-matrix says CONFIRMED in 3 sites). The cycle-21 wave's host-tools-matrix dispatch scope was retired-vocab + typo only — did NOT include the Section 5 row-1 status refresh or Section 2 capability-cell refresh. 1 MEDIUM (host-tools-matrix L64 "DISCOVERY-STATE Q52" retired vocab missed by sweep). 1 LOW (host-tools-matrix L137 "Q3 / Q72" internal contradiction — Q3 already RESOLVED per Section 2 row 3 + Section 5 row 3 of same doc). 2 MINOR (glossary L168 "User Approved" + L173 "Work" still cite retired filenames without "retired" qualifier; host-tools L142 "manifest → 5-way" minor framing residual). **Pass rate: 9 TRUE / 2 FALSE-unrefreshed / 1 PARTIAL = 75% on cycle-21-wave-landing-verification; 100% on disk-truth for SKILL.md / scripts / templates / methodology / installer L145/L140 .agents copy. verify-kb-claims.sh exits 0.** Disk-truth check: 161 glossary terms verified; SKILL.md line counts match disk for all 10 skills (2,157 total); methodology 1,071 / run_generator 84 / setup.sh 162 / setup.ps1 157 / IMPEDIMENT 116 / work-state-template 137 / discovery-state-template 85 / parse-recipe.sh 540 / discovery-reviewer/AGENT.md 405 all match. Recipes catalog 5 .md + README + .gitkeep ✓. 1 new Q-entry added (Q218). **RECOMMENDATION:** Pass-9 dispatch 1 tech-writer agent for host-tools-matrix (5 sites: 3 Q70 status cells + 1 retired-vocab + 1 internal Q3 contradiction); optional Pass-9B for 2 glossary MINOR fixes (~5 min). Expected post-Pass-9 grade: A-. To reach A+: also (a) integration-map.md file counts; (b) module-map L150 + L318 agent line counts; (c) infrastructure L25 branch citation; (d) CLAUDE.md L65 "2,108" → "2,157" — all [MINOR-mechanical-deferrable] per pre-flight rule, NOT blocking. |
