---
kb-category: meta
source: hand-authored
intent: |
  Discovery-area state ledger: Q&A history, per-cycle Review History, per-doc
  KB Documents Status, Calibration Log of sub-agent dispatches. The runtime
  state hub for /aid-discover. Not part of the reviewed knowledge surface
  (kb-category: meta).
contracts: []
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-2 FIX Phase B (Q22)
---

# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** In Progress
> **Current Grade:** D+
> **User Approved:** no
> **Last KB Review:** 2026-05-27 (cycle-2)
> **Last Summary:** —

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. One STATE.md per project's `.aid/knowledge/` directory. Absorbs what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.

> **Project-level settings** (minimum grade, heartbeat interval, max parallel tasks,
> etc.) live in `.aid/settings.yml`, not here. STATE.md is for run-state only —
> per-area review history, Q&A, current-cycle grade snapshots. Resolve any
> configured value via:
> `bash .claude/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

## External Documentation

| Path | Type | Accessible | Notes |
|------|------|------------|-------|
| None provided | — | — | No external documentation registered for cycle-1 or cycle-2 |

## KB Documents Status

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Reviewed | D | 2026-05-27 | [MEDIUM] 4 line-count drifts (project-index 1148, CLAUDE 25, README 388, run_generator 87, discovery-reviewer 387, 17→15 KB templates) |
| 2 | external-sources.md | Reviewed | A- | 2026-05-27 | [LOW] minimal content (1 sentence body); [MINOR] empty contracts; otherwise clean |
| 3 | architecture.md | Reviewed | E | 2026-05-27 | [CRITICAL] 4 dead CLAUDE.md cites + verify-claims.sh in folder tree; [HIGH] T3 skill-count drift (sum 2,230 vs actual 2,242); [MEDIUM] 17→15 templates; [MEDIUM] ".aid/ gitignored" misleading |
| 4 | technology-stack.md | Reviewed | E | 2026-05-27 | [CRITICAL] verify-claims.sh as Lint Command + 695-line claim (file gone); [CRITICAL] pool-dispatch.sh in test list (deleted); 297/297 contract unreachable |
| 5 | module-map.md | Reviewed | E | 2026-05-27 | [CRITICAL] verify-claims.sh documented as live (line 192) + 17→15 template count + dead STANDARD_KB_FILES cite |
| 6 | coding-standards.md | Reviewed | E | 2026-05-27 | [CRITICAL] 9 verify-claims.sh exemplar cites + 11 dead CLAUDE.md cites including all CONFIRMED conventions. Most-degraded doc in cycle-2 |
| 7 | schemas.md | Reviewed | E+ | 2026-05-27 | [CRITICAL] verify-claims.sh cited as authoritative contract source (2 places); [HIGH] FM contract says "exactly 16" docs but disk = 18 + body says 14 (self-contradiction); [MEDIUM] Style B Q&A schema (Q15 canonicalized A) |
| 8 | pipeline-contracts.md | Reviewed | E+ | 2026-05-27 | [CRITICAL] entire verify-claims.sh CLI section dead; [HIGH] "EXACTLY 5 sections" then lists 6 (cycle-1 carryover); [HIGH] Style B Q&A contract |
| 9 | integration-map.md | Reviewed | E+ | 2026-05-27 | [CRITICAL] 2 dead CLAUDE.md cites including ## Architecture bullet 7; [HIGH] project-index 1148-vs-1149 drift persists from cycle-1 |
| 10 | domain-glossary.md | Reviewed | D | 2026-05-27 | [CRITICAL] verify-claims.sh cite + dead glossary stats (~150 terms vs actual 195 vs metrics 172); [HIGH] Style B Q&A schema; [LOW] T4 commit-message ref |
| 11 | test-landscape.md | Reviewed | E- | 2026-05-27 | [CRITICAL] tests/skills/ dir does not exist; pool-dispatch.sh deleted; FM contract "6 + 2 suites" both wrong (actual 5 + 0); 297/297 unreachable. Worst doc in cycle-2 |
| 12 | tech-debt.md | Reviewed | E+ | 2026-05-27 | [CRITICAL] 9 dead CLAUDE.md cites (H1/H2 evidence base broken); [HIGH] count summary doesn't match metrics.md tally; [HIGH] H4 marked HIGH but resolved per own narrative; [HIGH] T3 metrics inlined (P1 violation) |
| 13 | infrastructure.md | Reviewed | E+ | 2026-05-27 | [CRITICAL] 7 dead CLAUDE.md cites incl Source Control + L1/L2/L3 evidence; [HIGH] PR-merge dates inlined (T4 ban); [MEDIUM] M1 stale (work-002 write was eliminated) |
| 14 | repo-presentation.md | Reviewed | D | 2026-05-27 | [HIGH] README.md section-line-cites stale (374-line claim vs actual 388); [HIGH] T3+T4 inline (methodology version + line count); [MINOR] empty contracts |
| 15 | feature-inventory.md | Reviewed | D+ | 2026-05-27 | [HIGH] uses `✓` (check) not `✅` (emoji) — build-metrics.sh therefore reports Shipped=0 from this doc; [MINOR] empty contracts (could declare 11-total) |

**Meta-documents:**

| Document | Status | Grade | Notes |
|----------|--------|-------|-------|
| INDEX.md | Reviewed | C+ | [HIGH] 2 entries show "no intent: declared" (README + STATE) due to meta-doc FM-MISSING propagation |
| README.md | Reviewed | D+ | [HIGH] [FM-MISSING] no YAML frontmatter; [HIGH] doc-count "15 active" contradicts schemas.md "16 standard" and on-disk 18 |
| STATE.md (this file) | Reviewed | D+ | [HIGH] [FM-MISSING] no YAML frontmatter; otherwise structurally sound for cycle-2 |
| metrics.md (generated) | Reviewed | C+ | [HIGH] feature-inventory parser broken (glyph mismatch — reports 0 Shipped); [MEDIUM] glossary term count 172 vs reality 195 |

## Knowledge Summary Status

| Field | Value |
|-------|-------|
| Profile | — (no summarize run yet on cycle-1 or cycle-2) |
| Profile Source | — |
| Profile Confidence | n/a |
| Theme | — |
| Machine Grade | — |
| Human Grade | — |
| User Approved | no |
| Last Run | — |
| Output | — |
| Mermaid Version | — |
| Mermaid Cached | — |

## Issues

> Issues found during cycle-2 REVIEW state. Severity tags drive grade.sh.
> Full per-doc breakdown in `.aid/.temp/review-pending/discovery.md`.
> Cycle-2 dominated by two CASCADE failures: (1) CLAUDE.md collapse (118→25 lines)
> orphaned ~40 KB cites; (2) verify-claims.sh deletion not propagated, leaving
> 18+ dead refs across 6 docs. See ledger Notes section for the diagnosis.

### project-structure.md (D)
- [MEDIUM] Line 45/256/80,121/81,122/84: 5 line-count drifts (project-index 1148 not 1149; discovery-reviewer 387 not 402; README 388 not 374; CLAUDE.md 25 not 118; run_generator 87 not 86)
- [LOW] T4 snapshot date inline (acceptable for generated-from-inventory doc; flagged for tracking)

### external-sources.md (A-)
- [LOW] One-sentence body; could be expanded with registration procedure
- [MINOR] empty contracts: [] (cosmetic, default-empty)

### architecture.md (E)
- [CRITICAL] 4 dead CLAUDE.md cites: :48-55 (line 90), :104-106 (line 113), :52-55 (line 125), :108-110 (line 168) — all past CLAUDE.md EOF (25 lines)
- [CRITICAL] Folder tree line 58 lists deleted verify-claims.sh under kb/
- [HIGH] Inline T3 skill-line-counts (lines 134-137) with stated sum 2,230 vs actual 2,242
- [HIGH] "CLAUDE.md:55 claims 2,108 total skill-body lines" (lines 139-143, 315-318) — claim doesn't exist; fictitious citation
- [MEDIUM] Folder tree line 53 says "17 KB templates" — actual 15
- [MEDIUM] 3 cites to run_generator.py "86 lines" — actual 87
- [MEDIUM] Line 86 says ".aid/ runtime KB scaffold (mostly gitignored)" — wrong for THIS repo (AID dogfoods, .aid/ is committed)

### technology-stack.md (E)
- [CRITICAL] Lint Commands section invokes verify-claims.sh as live command (lines 117-118)
- [CRITICAL] Lint Commands lists `bash tests/canonical/pool-dispatch.sh # 7 tests` — script deleted in cycle-1
- [CRITICAL] Development Tools table cites verify-claims.sh as 695 lines, "the largest source file" — file gone
- [HIGH] "297/297 expected" contract (line 175) — unreachable post-Q6 cleanup
- [MEDIUM] run_generator.py "86 lines" — actual 87

### module-map.md (E)
- [CRITICAL] §4b verify-claims.sh entry (line 192) documents deleted script as live
- [CRITICAL] §5a "17 files" templates count + dead STANDARD_KB_FILES cite (line 265) — actual 15 files
- [CRITICAL] coding-standards.md context cite to verify-claims.sh:21-25 still in domain-glossary.md:76

### coding-standards.md (E)
- [CRITICAL] Nine separate verify-claims.sh exemplar citations (lines 70, 134, 163, 175, 191, 245, 377, 420, 491) — convention doc's authority undermined when readers can't find the cited examples
- [CRITICAL] Eleven dead CLAUDE.md citations (lines 81, 287, 328, 336, 349, 353, 389, 444, 449, 452, 453) including CONFIRMED-tagged conventions: "Never edit profiles" (CLAUDE.md:48-50), "Thin-router decomposition" (CLAUDE.md:51-56), "Area-STATE FR2" (CLAUDE.md:57-59), "Single-branch work" (CLAUDE.md:60-63), "Calibration Log" (CLAUDE.md:79-83). All past EOF.

### schemas.md (E+)
- [CRITICAL] §3 line 89: "Exactly 16 rows ... per verify-claims.sh:102-119 STANDARD_KB_FILES" — dead cite
- [CRITICAL] §5 line 157: "verified by verify-claims.sh" — dead
- [HIGH] FM contract: "Discovery STATE.md tracks exactly 16 standard KB documents" — FALSE; KB has 18 docs on disk; body says 14 active; three-way contradiction
- [MEDIUM] §3 Q&A schema (line 91) shows Style B; Q15 canonicalized Style A

### pipeline-contracts.md (E+)
- [CRITICAL] Entire `### bash canonical/scripts/kb/verify-claims.sh` section (lines 295-306) documents deleted script as live CLI contract — 4 path:line cites all dead
- [HIGH] §2 line 116-125: "EXACTLY 5 sections in this order" then lists 6 (cycle-1 carryover, never fixed)
- [HIGH] §Q&A Entry Contract (lines 478-493) uses Style B; Q15 canonicalized Style A; cross-doc contradiction with coding-standards.md §12

### integration-map.md (E+)
- [CRITICAL] Line 358: cites `CLAUDE.md ## Architecture bullet 7` — no such section in current CLAUDE.md
- [CRITICAL] Line 375: `CLAUDE.md:35-36` cite — past EOF
- [HIGH] Line 66-68: project-index "1,149 lines" — actual 1,148 (cycle-1 finding #21 never fixed; persists)

### domain-glossary.md (D)
- [CRITICAL] Line 76: `verify-claims.sh:21-25` cite — file deleted
- [HIGH] Lines 100-101: Q&A entry schema uses Style B (`### IQ{N}: [Category: Impact]`) — Q15 canonicalized A
- [HIGH] Line 364: "Total terms defined: ~150" — actual 195 by direct count; metrics.md computes 172; three-way disagreement
- [MEDIUM] Line 253: discovery-reviewer "402 lines" — actual 387
- [MEDIUM] Line 365: CLAUDE.md "118 lines" — actual 25
- [LOW] Line 304: T4 commit-message ref ("cycle-25 A+ — Pass-11 verified")

### test-landscape.md (E-)
- [CRITICAL] Lines 8, 13, 47-48: `tests/skills/` directory and its 2 suites referenced — directory does not exist on disk
- [CRITICAL] Lines 44, 76, 112-117: pool-dispatch.sh referenced as live — deleted in cycle-1 per Q6
- [CRITICAL] FM contracts (lines 12-13): "6 suites in tests/canonical/" (actual 5) and "2 suites in tests/skills/" (dir absent) — both FALSE
- [CRITICAL] Lines 71, 99, 123, 127: "297/297 expected" — unreachable; max possible ~217 post-cleanup
- [HIGH] Line 64: inlines test:source ratio (T3 metric — belongs in metrics.md)
- [LOW] Multiple CLAUDE.md:46/47/52 cites also dead

### tech-debt.md (E+)
- [CRITICAL] 9 dead CLAUDE.md cites — including H1's load-bearing evidence (CLAUDE.md:48-49 for missing test runners) and H2's CLAUDE.md:52 ("no CI"). The case for the top two HIGHs is built on broken cites.
- [HIGH] Lines 30-34: severity summary count contradicts metrics.md tally (table-row vs section-header counting); reconcile
- [HIGH] H4 narrative says "Fixed in cycle-1" but still tagged HIGH in inventory (line 46) and counted in summary; should mark Resolved (cf. M2 pattern)
- [HIGH] Lines 416-419: T3 metrics inlined (TODO=9, files>500=4, ratio=1.29, PRs=0) — P1 violation
- [MEDIUM] Line 21: cite to template tech-debt.md:19-23 — off-by-2 (actual block starts at line 17)
- [MEDIUM] Line 50: M2 RESOLVED with date+commit SHA in body (T4 load-bearing per rubric exception; acceptable but flagged)

### infrastructure.md (E+)
- [CRITICAL] 7 dead CLAUDE.md cites (lines 67, 73, 149, 201, 223, 232, 236) — includes Source Control branch convention + L1/L2/L3 traceability evidence
- [HIGH] Lines 152-156: "Recent merge history" section with PR-merge dates — T4 ban (P1 violation)
- [MEDIUM] Line 119: "run_generator.py:76 writes to .aid/work-002-canonical-generator/" — tech-debt H4 documents the write was eliminated
- [MEDIUM] Line 88: run_generator.py "86 lines" — actual 87

### repo-presentation.md (D)
- [HIGH] Line 44: "README.md:1-374 (374 lines)" — actual 388; all subsequent section line-cites stale (table at lines 51-61)
- [HIGH] Lines 199-202: "Version: 3.1" + "1,071 lines" inline T3+T4 data
- [LOW] Lines 242-244: T4 marker "as of this KB document authoring"
- [MINOR] empty contracts

### feature-inventory.md (D+)
- [HIGH] Line 17 + body: uses `✓ Shipped` (U+2713 check mark) but tech-debt.md/metrics.md regex matches `✅` (U+2705 emoji). build-metrics.sh therefore reports Shipped=0/Partial=1 from this file (visible in metrics.md:80-85 — broken integer "0\n0"). Choose one glyph and propagate.
- [MINOR] empty contracts — could declare "10 user-facing skills + 1 maintainer-only = 11 total"

### INDEX.md (C+)
- [HIGH] Lines 35-41: README.md + STATE.md entries show "*(no intent: declared)*" — these meta docs have no YAML frontmatter on disk; INDEX faithfully reports the gap

### README.md (D+)
- [HIGH] [FM-MISSING] no YAML frontmatter present — per rubric §Spot-Check Snapshot check 1, meta docs must declare kb-category: meta
- [HIGH] Line 6: "15 active KB documents" — contradicts schemas.md "exactly 16" (which is itself wrong) and on-disk count of 18

### STATE.md (D+)
- [HIGH] [FM-MISSING] no YAML frontmatter — same as README

### metrics.md (C+, generated/build-verify)
- [HIGH] Feature-inventory section (lines 80-85) broken: "✅ Shipped | 0\n0 |" line-broken integer; build-metrics.sh glyph-mismatch with feature-inventory.md (#031)
- [MEDIUM] Line 76: "Term count: 172" — generator regex matches a subset of glossary entries; should align with the actual `^| **` glossary pattern (would yield 195)

## Cross-Cutting Concerns

- **CC1 [CRITICAL — root cause]:** CLAUDE.md collapsed from ~118 to 25 lines without cascade; ~40+ dead citations across 6 KB docs (architecture, coding-standards, integration-map, infrastructure, tech-debt, test-landscape). Includes load-bearing CONFIRMED conventions. ORCHESTRATOR ACTION: decide CLAUDE.md restoration vs cite-migration to methodology spec / coding-standards. OUT-OF-SCOPE per protocol — logged for visibility, excluded from per-doc severity counts.
- **CC2 [CRITICAL — cascade]:** verify-claims.sh deletion not propagated to KB body. 18+ broken cites across 6 docs. Tech-debt H6 documented the deletion intent but the FIX never landed. coding-standards.md alone has 9 stale exemplar cites.
- **CC3 [HIGH]:** KB doc count contradicts itself across 4 sources: schemas.md FM contract says "exactly 16"; README.md:6 says "15 active"; coding-standards.md:446 says "14 active"; on-disk = 18 (15 primary + 3 meta). Pick one and cascade.
- **CC4 [HIGH]:** Style A vs Style B Q&A schema unresolved across primary docs despite Q15 canonical decision. schemas.md §3, pipeline-contracts.md §Q&A, domain-glossary.md term entry all teach Style B. coding-standards.md §12 alone declares Style A canonical. Cycle-1 finding M5 (in tech-debt) acknowledges but didn't propagate.
- **CC5 [HIGH]:** test-landscape.md describes a phantom test universe (8 suites; 297 tests) — actual reality is 5 suites + tests/skills/ deleted + pool-dispatch.sh deleted. Doc rewrite needed, not just spot-fixes.
- **CC6 [HIGH]:** Feature-inventory glyph mismatch (✓ vs ✅) breaks build-metrics.sh. Visible in metrics.md as `Shipped | 0\n0`. Pick a glyph and align both file + script.
- **CC7 [MEDIUM]:** Multiple T3 line-count drifts cascade through docs: project-index.md 1148 vs 1149 (project-structure + integration-map); discovery-reviewer.md 387 vs 402 (project-structure + domain-glossary); README.md 388 vs 374 (project-structure + repo-presentation); CLAUDE.md 25 vs 118 (project-structure + domain-glossary); methodology 1070 vs 1071 (5+ places); run_generator.py 87 vs 86 (4+ places). Per P1 these should not be inline — propagate to metrics.md only.
- **CC8 [MEDIUM]:** tech-debt.md self-count (HIGH=6, MEDIUM=6, LOW=5) disagrees with metrics.md tally (HIGH=13, MEDIUM=13, LOW=11). The metrics file is correct; tech-debt should reconcile or footnote the counting methodology.

## Verification Spot-Checks

> 38 spot-checks performed; 15 verified-true, 23 verified-false. Full list (with
> evidence) in `.aid/.temp/review-pending/discovery.md` § Verification Spot-Checks.
> 7 version verifications performed (Python, PowerShell, Node, TOML, YAML +
> methodology line count + KB doc count). Failed checks excerpted below:

| # | Claim | Doc | Verified | Evidence |
|---|-------|-----|----------|----------|
| 6 | methodology = 1,071 lines | architecture.md, project-structure.md, repo-presentation.md, multiple | NO | `wc -l methodology/aid-methodology.md` = 1,070 |
| 7 | CLAUDE.md = 118 lines | project-structure.md, domain-glossary.md | NO | `wc -l CLAUDE.md` = 25 |
| 8 | README.md = 374 lines | project-structure.md, repo-presentation.md | NO | `wc -l README.md` = 388 |
| 9 | run_generator.py = 86 lines | architecture, technology-stack, infrastructure, project-structure | NO | `wc -l` = 87 |
| 10 | discovery-reviewer.md = 402 lines | project-structure.md, domain-glossary.md | NO | `wc -l canonical/agents/discovery-reviewer/AGENT.md` = 387 |
| 15 | verify-claims.sh exists | 18+ KB citations | NO | File deleted in cycle-1 per tech-debt H6 |
| 16 | Skill canonical sum = 2,108 (CLAUDE.md:55) | architecture, coding-standards | NO | CLAUDE.md:55 doesn't exist; actual sum = 2,242 |
| 17 | Skill canonical sum = 2,230 | architecture.md:137 | NO | Actual = 2,242 |
| 19 | KB has 16 docs | schemas.md:14 contract | NO | `ls .aid/knowledge/*.md` = 18 |
| 20 | Glossary has ~150 terms | domain-glossary.md:364 | NO | grep = 195; metrics = 172 |
| 22 | tests/skills/ has 2 suites | test-landscape.md | NO | Directory does not exist |
| 23 | pool-dispatch.sh exists | test-landscape.md, technology-stack.md | NO | Deleted in cycle-1 |
| 24 | 6 suites in tests/canonical/ | test-landscape.md FM contract | NO | Actual 5 |
| 25 | 297/297 expected tests | test-landscape, technology-stack | NO | Max ~217 post-cleanup |
| 28 | run_generator writes to work-002 | infrastructure.md:119 | NO | tech-debt H4 documents write was eliminated |
| 29 | verify-claims.sh = the lint enforcer | coding-standards.md:420 | NO | Script gone; P4 now enforced by discovery-reviewer per H6 |

Verified-true sample:
- Python 3.11+ at harness.py:15
- PowerShell 5.1+ at setup.ps1:1
- 22 agents (canonical/agents/)
- 10 user-facing skills (canonical/skills/)
- 5 recipes + README (canonical/recipes/)
- 11 Python files (10 in scripts/ + run_generator.py)
- aid-config 190 / aid-interview 357 / aid-detail 77 / grade.sh 141 / EMISSION-MANIFEST 152
- AID = "AI Integrated Development" (no hyphen) — Q11 fix landed correctly
- tests/README.md exists (per Q6 action #4)
- 16-letter grade scale (settings.yml:58)
- Feature-inventory uses ✓ (U+2713) — confirming the build-metrics.sh mismatch

## Q&A (Pending)

> Open questions from cycle-1 (Q1-Q17) + cycle-2 REVIEW (Q18-Q22).
> Cycle-1 entries preserved verbatim below for traceability.

### Q1
- **Category:** Documentation / Project-State
- **Impact:** High
- **Status:** Answered
- **Context:** `CLAUDE.md:35-36` lists two test-runner scripts as part of the canonical helper suite — `.aid/work-001-aid-lite/test-reports/e2e-two-tier-runner.sh` (35 tests) and `e2e-lite-path-runner.sh` (38 tests). Neither file appears in `.aid/generated/project-index.md` (1077 files, full inventory). If these are claimed quality gates and they do not exist on this branch, the documented test coverage (297/297) cannot be reproduced. Either the docs are stale or the scripts were lost during a branch operation (CLAUDE.md:118 notes PR #12 lost 63 commits during a worktree-sprawl incident — was this collateral damage?).
- **Suggested:** Confirm whether `.aid/work-001-aid-lite/` should be present. If retired, update `CLAUDE.md:35-36` to remove the dead references. If accidentally lost, recover from git history.
- **Answer:** **Structural error.** Per user (2026-05-27): "No canonical file should be in the work-* folder. That is a big mistake." The `.aid/work-*/` directories are for transient work-in-progress artifacts (PLAN.md, REQUIREMENTS.md, tasks/, features/), NOT for canonical test scripts. FIX state actions: (1) Remove `e2e-two-tier-runner.sh` (35) and `e2e-lite-path-runner.sh` (38) lines from `CLAUDE.md:35-36`; (2) Recompute the 297-total test claim (excluding the 73 phantom tests = 224 across 5 canonical/ suites); (3) If the e2e tests are actually wanted in the project, relocate to `tests/canonical/` or `tests/e2e/` — not a work-* folder. Also see [[work-folder-scope]] memory.

### Q2
- **Category:** Documentation / Project-State
- **Impact:** High
- **Status:** Answered
- **Context:** `run_generator.py:76,83` writes verify reports to `.aid/work-002-canonical-generator/verify-4a-report.json` and `verify-4b-report.json`. That directory is NOT present in the project index. The script will fail on a clean checkout (the parent directory does not exist and open with mode "w" on a missing parent throws). Inferred: maintainers must `mkdir -p` the directory before each run, or the script needs a `Path(...).parent.mkdir(exist_ok=True, parents=True)` guard.
- **Suggested:** Either (a) add the directory with a `.gitkeep` and document its purpose, (b) move the verify reports somewhere already-tracked, or (c) add `mkdir -p` logic to `run_generator.py`.
- **Answer:** **Drop the reports entirely.** Per user (2026-05-27): "Drop them and add a note to investigate later if there are more unnecessary reports, files, or logs being generated by the skills so we can eliminate the crud." Investigation showed: `run_verify`/`run_advisory` already accept `report_path=None` and skip the JSON write internally (`verify_deterministic.py:364-368`); `run_generator.py` is the only caller passing a path; the reports are write-only (script logic uses return values, not the file). FIX state actions: (1) Change `run_generator.py:76,83` to pass `report_path=None` (or omit the arg); (2) `--report-path` CLI arg stays on standalone invocations for debugging; (3) Add a tech-debt audit item for a project-wide skills/script crud audit (see tech-debt.md update). The original premise about mkdir failure was wrong — `verify_deterministic.py:366` already does `rp.parent.mkdir(parents=True, exist_ok=True)`. Also see [[no-crud-outputs]] memory.

### Q3
- **Category:** Discovery-Scope
- **Impact:** High
- **Status:** Answered
- **Context:** The repo is unusual: it ships NO application code, only a methodology + a 4-way-mirrored install bundle. Discovery is being run on the repo that defines discovery. Some standard KB docs (`api-contracts`, `data-model`, `ui-architecture`, `security-model` insofar as it covers a runtime app) will have nothing to say — there are no APIs, no data models, no runtime UI, no production attack surface. This is expected and not a defect.
- **Suggested:** Confirm with the user that these KB docs may be intentionally near-empty (or repurposed to describe the methodology contracts — e.g., `api-contracts.md` could document the canonical-to-render-to-install contract, `data-model.md` could document the KB shape and emission-manifest schema). Capture the decision before downstream sub-agents (analyst, integrator, quality) start.
- **Answer:** **Rename misleading + delete irrelevant + replace.** Per user (2026-05-27): "The KB must be a correct representation of the intent of the repo." FIX state actions:
  1. **Rename `api-contracts.md` → `pipeline-contracts.md`** — actual content is pipeline-component interfaces (skill ↔ subagent dispatch, script CLI signatures + exit codes, file-format contracts, render contract). Cascade: INDEX.md, README.md, verify-claims.sh expected-doc list, aid-discover sub-agent prompts (`discovery-integrator` agent owns), methodology spec, `canonical/templates/knowledge-base/api-contracts.md` template.
  2. **Rename `data-model.md` → `schemas.md`** — actual content is YAML/JSONL/markdown shape contracts (settings.yml, STATE.md sections, frontmatter, emission-manifest JSONL, recipe/task templates). Cascade: same files as #1, plus `discovery-analyst` agent ownership map.
  3. **Delete `ui-architecture.md` + write new `repo-presentation.md`** — current 320L content (KB-viewer architecture) is implementation detail that belongs in `aid-summarize` skill README. New doc describes how the methodology is *presented to users via the GitHub repo*: README structure, docs/ taxonomy, examples/ catalog, methodology spec link, blog references. Cascade: same as #1, plus `discovery-architect` ownership re-map.
  4. **Delete `security-model.md`** — for a non-runtime methodology repo, dedicated security doc is contortion. Relocate salvageable bullets: (a) secret hygiene/`.gitignore` policy → `coding-standards.md` as a bullet; (b) Mermaid CDN pin status → already in `tech-debt.md` C1; (c) agent-tools allowlist → already documented in agent definitions + `coding-standards.md`; (d) adopter-side permission contract → methodology spec. Cascade: same as #1, plus `discovery-quality` ownership re-map.
  5. **New follow-up Q16** captures the broader methodology change (canonical 16-doc set becomes a flexible default).

  Net cycle-end KB-doc count: 15 (was 16 — net delete 1 because `security-model.md` is deleted but `ui-architecture.md` is replaced 1:1 by `repo-presentation.md`).

### Q4
- **Category:** Build / Determinism
- **Impact:** Medium
- **Status:** Answered
- **Context:** The mirror-replication design implies that every helper-script change must be made in `canonical/scripts/` and propagated by `python run_generator.py`. There is no enforcement mechanism documented in the project index (no pre-commit hook, no CI gate per `CLAUDE.md:44`). A contributor who edits one of the 4 mirror copies directly will be silently overwritten on the next render. `CLAUDE.md:75-76` warns "Never edit `profiles/{claude-code,codex,cursor}/` directly" — but `.claude/` (the dogfood tree) is also a mirror per the same logic and is not in the warning list.
- **Suggested:** Confirm whether `.claude/` (dogfood) is in scope for the same do-not-hand-edit rule. If yes, update `CLAUDE.md:75-76` to include it. Consider whether a pre-commit hook should reject edits to any of the 4 mirror trees.
- **Answer:** **Keep .claude/ hand-editable (current behavior).** Per user (2026-05-27). The 4-tree byte-identity rule applies to canonical + 3 profile trees (claude-code, codex, cursor) only. `.claude/` is the dogfood install — conceptually identical to any user's `.claude/` after `setup.sh`, intentionally hand-editable so the maintainer can test changes without re-rendering. **Note:** The rule's home moved from `CLAUDE.md:75-76` (now removed in user's cleanup) to `coding-standards.md:328` — Q4 line-cite needs updating in FIX. No coding-standards change required; current wording is correct as-is.

### Q5
- **Category:** Distribution / Packaging
- **Impact:** Medium
- **Status:** Answered
- **Context:** End-user install is via `setup.sh` / `setup.ps1` (per `README.md:282-296`), not via a package manager. There is no semver/calver version source visible in the project index (no `VERSION` file, no `__version__` in Python, no `version =` in any TOML). It is unclear how end users learn that an upgrade is available, what version they have installed, or how AID itself is versioned.
- **Suggested:** Confirm versioning scheme + release process. If "git SHA = version" is the answer, document it; if there is a planned semver, add a `VERSION` file.
- **Answer:** **Not versioned yet — document as "continuous master".** Per user (2026-05-27). AID is methodology-in-development; explicit non-versioning is the honest position. FIX state actions: (1) Add a section to `README.md` (likely under "Installation" or a new "Versioning" subsection) explaining: "AID has no version yet; install pulls current `master`; re-run `setup.sh` to get updates."; (2) Add a tech-debt item `Versioning-scheme-when-stable` for when AID stabilizes enough to warrant formal releases; (3) Update `coding-standards.md` (or `tech-debt.md`) to clarify the "no version" stance so contributors don't add a VERSION file prematurely.

### Q6
- **Category:** Test-Tooling
- **Impact:** Medium
- **Status:** Answered
- **Context:** Tests are pure bash scripts (`tests/canonical/*.sh`, `tests/skills/*.sh`). 8 total: 6 in canonical/ + 2 in skills/. The project index shows no test runner.
- **Suggested:** Confirm whether a top-level test runner exists or whether the manual list is the actual contract. A `tests/run-all.sh` aggregator would reduce friction.
- **Answer:** **Cleanup + rename + clean-code refactor.** Per user (2026-05-27): cycle-1 FIX state actions: (1) **Delete** `tests/skills/lite-subpaths.sh` and `tests/skills/lite-to-full-escalation.sh` — both are doc-conformance checks pretending to be tests (verify state-*.md files contain specific text; break on doc rewrites; stay passing when underlying logic breaks). The skills/ folder itself can be removed. (2) **Delete** `tests/canonical/pool-dispatch.sh` — 3 assertions in 153 lines is ceremony, not testing; the "symbolic simulation" doesn't actually test dispatch behavior. (3) **Keep 5 remaining canonical/ tests** — they protect non-trivial deterministic bash logic where silent bugs are the alternative (settings resolution, task-status concurrency, recipe parsing, BFS failure cascade, delivery-gate integration). (4) **Add `tests/README.md`** listing what each kept suite covers + how to run individually. (5) **No aggregator** for now (5 hand-runnable suites is fine). **Plus follow-up:** Q17 captures the broader test-refactor toward clean-code patterns + clearer names. Net: 8 → 5 test files this cycle; longer-term refactor in a separate work item.

### Q7
- **Category:** Knowledge-Base
- **Impact:** Medium
- **Status:** Skipped
- **Context:** The KB output directory (`.aid/knowledge/`) currently contains only `STATE.md` (3629 bytes). The "16 standard KB docs" promised by the methodology (`README.md:114-145`) are not present. This is expected for a discovery cycle that has not run, but means the downstream agents have no prior KB to read — they are producing the KB from scratch on a repo whose own purpose is to enable such KB production. Cite-everything discipline must be especially tight to avoid circular fluff.
- **Suggested:** No action needed — flag for the orchestrator: this is the first KB cycle on this repo. Prior knowledge-summary artifacts (e.g., `.aid/knowledge/knowledge-summary.html` per git status) may be reference material but are not authoritative.
- **Answer:** Auto-skipped in Q-AND-A Step 1 — informational observation about cycle-1 state; no user-decision needed. The cycle has since completed GENERATE (all 16 docs populated) so the precondition described in Context no longer holds.

### Q8
- **Category:** Examples
- **Impact:** Low
- **Status:** Answered
- **Context:** `examples/` contains three case studies (`brownfield-enterprise/`, `data-pipeline/`, `desktop-app/`). Modification dates skew to March 2026 (3+ months stale relative to the current 2026-05-27 snapshot), and example sizes are small (~50-110 lines per file). It is unclear whether they are still authoritative or are demonstration-only.
- **Suggested:** Note their staleness; not a blocker for discovery. Discovery-architect or discovery-quality may want to flag for refresh in `tech-debt.md`.
- **Answer:** **Accept stale + add tech-debt entry.** Per user (2026-05-27). FIX state action: add a Medium-severity entry to `tech-debt.md`: "examples/ case studies (brownfield-enterprise, data-pipeline, desktop-app) are 3+ months stale (last touched March 2026). Refresh when methodology changes substantially (e.g., after Q3's KB-doc rename + Q11's acronym fix propagate). No refresh blocking this cycle."

### Q9
- **Category:** Generated-Artifacts
- **Impact:** Low
- **Status:** Answered
- **Context:** `.gitignore:39-47` excludes `.aid/knowledge/.cache/`, `.claude/worktrees/`, `.claude/settings.local.json`, and `.aid/.heartbeat/` — but does NOT exclude `.aid/` as a whole. The README (line 320) claims `.aid/` is appended to your project gitignore — the Knowledge Base stays out of git by default. The discrepancy is intentional for this repo (the KB is the deliverable here) but is worth noting so that contributors do not get confused.
- **Suggested:** Confirm in `CONTRIBUTING.md` or `CLAUDE.md` that this repo deliberately commits `.aid/knowledge/` because the KB IS part of the product. Otherwise, the README promise might mislead readers.
- **Answer:** Self-evident: `git ls-files | grep "^\.aid/" | wc -l` = 67 — `.aid/` IS deliberately committed in this repo because AID is dogfooding itself (the KB and work-artifacts are part of the product). Surfaced for FIX state to add a `CLAUDE.md` clarifying note so external contributors are not misled by the README's general-case guidance.

### Q10
- **Category:** External-Documentation
- **Impact:** Low
- **Status:** Answered
- **Context:** No external documentation paths were registered in the `STATE.md ## External Documentation` table for this discovery cycle (per orchestrator instructions). Per the agent-prompts spec, this is the no-docs variant. If the user has external design notes, blog drafts, internal Notion pages, or methodology comparison material on disk that should inform discovery, they have not been surfaced.
- **Suggested:** Re-confirm with the user that no external sources exist. If any exist (e.g., the blog post referenced by `README.md:374` at casuloailabs.com/blog/aid-methodology/), they could be added at Q&A time.
- **Answer:** **Confirmed: no external docs.** Per user (2026-05-27). All authoritative content lives in the repo. The blog post at casuloailabs.com/blog/aid-methodology/ is referenced from README but doesn't need to be re-ingested. Discovery is self-contained. No FIX action.

### Q11
- **Category:** Documentation / Acronym
- **Impact:** High
- **Status:** Answered
- **Context:** AID is expanded FOUR different ways in the codebase (cycle-1 detection).
- **Answer:** **AID = "AI Integrated Development" (no hyphen).** Per user confirmation (2026-05-27). Cycle-2 spot-check #30 confirms this fix landed correctly in CLAUDE.md:5, domain-glossary.md:31, settings.yml:16.

### Q12
- **Category:** KB-Generator
- **Impact:** Medium
- **Status:** Answered
- **Context:** Two-copy INDEX.md drift between `.aid/knowledge/INDEX.md` and `.aid/generated/INDEX.md`.
- **Answer:** **Single copy at `.aid/knowledge/INDEX.md`.** Per user (2026-05-27). Cycle-2 confirms `.aid/generated/INDEX.md` is gone; only `.aid/knowledge/INDEX.md` remains.

### Q13
- **Category:** Feature-Inventory
- **Impact:** High
- **Status:** Answered (partially landed — see Q21 follow-up)
- **Context:** feature-inventory.md was template-only in cycle-1.
- **Answer:** **10 user-facing skills as features.** Cycle-2 confirms feature-inventory.md is now populated with 11 rows (10 skills + 1 maintainer). However, glyph mismatch (`✓` vs `✅`) breaks build-metrics.sh tally — see new Q21.

### Q14
- **Category:** Frontmatter
- **Impact:** High
- **Status:** Answered (partially landed — see Q22 follow-up)
- **Context:** 12 of 16 primary KB docs lacked frontmatter in cycle-1.
- **Answer:** Cycle-2 confirms all 15 primary KB docs now have YAML frontmatter. Meta docs (README.md, STATE.md) still lack FM — see new Q22.

### Q15
- **Category:** STATE-Schema
- **Impact:** Medium
- **Status:** Answered (NOT cascaded — see Q19 follow-up)
- **Context:** Two Q&A schemas coexist; canonical decision = Style A.
- **Answer:** **Canonical = Style A** (`### Q{N}` + sub-bullets). Per user (2026-05-27). Cycle-2 finds the decision documented in coding-standards.md §12 but NOT propagated to schemas.md §3, pipeline-contracts.md §Q&A, or domain-glossary.md term entry — see new Q19.

### Q16
- **Category:** Methodology / Doc-Set
- **Impact:** High
- **Status:** Answered
- **Context:** Methodology assumes rigid 16-doc KB set; this repo needs 15.
- **Answer:** **(b) Methodology-level change.** Captured as tech-debt H5. Cycle-2 finds the doc-count contradiction is now WORSE: 4-way disagreement (14 / 15 / 16 / 18). See CC3.

### Q17
- **Category:** Test-Refactor
- **Impact:** Medium
- **Status:** Answered
- **Context:** Per Q6 cycle-1 cleaned 3 tests; broader refactor needed.
- **Answer:** **(b) Separate work-NNN (recommended).** Per user (2026-05-27). Captured as tech-debt M6. Cycle-2 confirms 5 suites remain on disk; test-landscape.md still describes the 8-suite pre-cleanup reality — see Q20.

## Discovery — Review Cycle 2

> New questions surfaced by cycle-2 REVIEW. Numbered Q18+.

### Q18
- **Category:** Documentation / CLAUDE.md
- **Impact:** High
- **Status:** Answered
- **Context:** Project-root CLAUDE.md was collapsed from ~118 lines to 25 lines (per cycle-2 spot-check #7), dropping all of `## Build & Test`, `## Architecture`, `## Skills`, `## Agents`, `## Conventions` sections. ~40+ KB citations to CLAUDE.md line numbers in 6 primary docs (architecture, coding-standards, integration-map, infrastructure, tech-debt, test-landscape) now point past EOF. CC1 of cycle-2. The KB cannot be repaired without a decision on what CLAUDE.md should contain.
- **Suggested:** Two options: (a) RESTORE long-form CLAUDE.md (most KB cites become valid again; methodology Architecture / Skills / Conventions become re-discoverable from the dogfood project-context file); (b) ACCEPT current minimalist CLAUDE.md and migrate cited-truth-source to coding-standards.md and methodology/aid-methodology.md (40+ KB cites need rewriting). Which is the intended steady state?
- **Answer:** **Keep minimalist + re-cite away from CLAUDE.md (option b).** Per user (2026-05-27): "CLAUDE.md should be reserved to its role of a memory file ... Information in the CLAUDE.md has the risk of becoming stale." Same principle applies to AGENTS.md. CLAUDE.md/AGENTS.md are pointers (loaded into every agent context); the KB is the source of truth. FIX state actions: (1) Sweep the 6 affected KB docs for `CLAUDE.md:NN-MM` style cites; (2) Re-cite each to the actual canonical-truth-source — methodology spec, KB doc (coding-standards.md, schemas.md, etc.), or source file in canonical/. NEVER update the CLAUDE.md line numbers — the fix is to re-cite away. (3) Add a new convention to `coding-standards.md` (or a kb-authoring principle): "KB docs MUST NOT cite CLAUDE.md or AGENTS.md by line number; cites go KB→KB or KB→source." (4) In a follow-up cleanup pass, audit AGENTS.md (Codex/Cursor profile) for any incoming KB cites — same principle. Memory saved as [[no-kb-cites-to-context-file]] for future-cycle prevention.

### Q19
- **Category:** Q&A Schema Cascade
- **Impact:** Medium
- **Status:** Answered
- **Context:** Q15 (cycle-1) canonicalized Style A (`### Q{N}` + sub-bullets). Cycle-2 finds: coding-standards.md §12 teaches Style A; but schemas.md §3 (line 91), pipeline-contracts.md "Q&A Entry Contract" (lines 478-493), and domain-glossary.md term entry (lines 100-101) all still teach Style B (`### IQ{N}: [Category: Impact]`). New readers will pick whichever doc they hit first.
- **Suggested:** Bulk-edit the 3 stragglers to align with coding-standards.md §12. This is a known-decision propagation, not a new question — should it instead be auto-applied in FIX without consultation?
- **Answer:** Auto-resolved in Q-AND-A Step 1 — propagation of an already-decided question (Q15). FIX state action: migrate schemas.md §3 + pipeline-contracts.md Q&A Entry Contract + domain-glossary.md Q&A term to Style A.

### Q20
- **Category:** test-landscape.md Rewrite Scope
- **Impact:** High
- **Status:** Answered
- **Context:** test-landscape.md describes 8 suites (6 canonical + 2 skill-level) and asserts 297 total tests. Reality post-Q6 cleanup: 5 canonical suites + 0 skill-level (tests/skills/ dir does not exist) + pool-dispatch.sh deleted = 5 suites totaling ~217 tests. Doc isn't drift — it's an outdated narrative. Plus the FM contract assertions (`6 suites`, `2 suites`) are FALSE on disk. Need a full rewrite, not spot-fixes.
- **Suggested:** Rewrite test-landscape.md from scratch to reflect current reality: 5 suites only, with updated test counts, updated test commands, and revised "297 expected" → "~217 expected" (or recompute exactly). Update FM contracts. Also update technology-stack.md Lint Commands. Confirm Q6's stated count (Q6 said "5 hand-runnable suites is fine" — confirms the reality but tech-debt's "297" hangover persists).
- **Answer:** Auto-resolved in Q-AND-A Step 1 — propagation of Q6's already-decided cleanup. FIX state actions: (1) rewrite test-landscape.md to reflect 5 canonical/ suites only with accurate test counts (recompute exact total by running each test or counting assertions); (2) update FM contracts to declare 5 suites; (3) update technology-stack.md Lint Commands section to drop pool-dispatch.sh + skill-level suites + "297 expected" claim; (4) update tech-debt.md if it carries the 297 hangover.

### Q21
- **Category:** Feature-Inventory Glyph
- **Impact:** Medium
- **Status:** Answered
- **Context:** feature-inventory.md (post-Q13) uses `✓` (U+2713 check mark) for Shipped status; build-metrics.sh regex matches `✅` (U+2705 emoji). Result: metrics.md reports "Shipped=0\n0" (broken integer) and "Partial=1" — a false reading propagated to downstream consumers. Two paths to fix: (a) update feature-inventory.md to use `✅` and align with other status-tracking docs; or (b) update build-metrics.sh regex to also match `✓`. Either works.
- **Suggested:** Pick (a) — `✅` is the more visually distinctive glyph and matches the convention in tech-debt.md status rows. Update legend at line 17 + all 11 rows + the maintainer-only footnote.
- **Answer:** Auto-resolved in Q-AND-A Step 1 — accept Suggested (option a). FIX action: update feature-inventory.md legend + all 11 rows + maintainer-only footnote from `✓` to `✅` to align with build-metrics.sh regex + other status-tracking docs.

### Q22
- **Category:** Meta-Doc Frontmatter
- **Impact:** Medium
- **Status:** Answered
- **Context:** README.md and STATE.md (the 2 hand-authored meta docs in `.aid/knowledge/`) have no YAML frontmatter. Per rubric §Spot-Check Snapshot check 1, meta docs should declare `kb-category: meta`. INDEX.md correctly shows them as "*(no intent: declared)*" — INDEX is faithfully reporting the gap, not introducing it. Q14 (cycle-1) added FM to 12 primary docs but skipped meta docs.
- **Suggested:** Add minimal FM to README.md (`kb-category: meta`, `source: hand-authored`, `intent:` brief) and STATE.md (same). Once added, INDEX.md will pick up the intents on next build-index.sh run.
- **Answer:** Auto-resolved in Q-AND-A Step 1 — accept Suggested. FIX action: add `kb-category: meta, source: hand-authored, intent: …` frontmatter to .aid/knowledge/README.md and .aid/knowledge/STATE.md. Regenerate INDEX.md after to pick up the intents.

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-27 | E+ | /aid-discover | Initial cycle-1 REVIEW. 0 [CRITICAL], 16 [HIGH], 11 [MEDIUM], 11 [LOW]. Blockers: FM-MISSING on 12 docs, INDEX.md two-copy drift, feature-inventory template-only. Grade snapped to grade.sh E+ output (reviewer wrote D-). |
| 2 | 2026-05-27 | E- | /aid-discover (cycle-2) | Cycle-2 REVIEW. 16 [CRITICAL], 24 [HIGH], 20 [MEDIUM], 5 [LOW], 8 [MINOR]. Grade WORSE than cycle-1 (E+ → E-). Two CASCADE failures dominate: (1) CLAUDE.md collapse 118→25 lines orphaned ~40 cites across 6 docs (CC1); (2) verify-claims.sh deletion not propagated to KB body, leaving 18+ dead refs across 6 docs (CC2). Cycle-1 FM-MISSING fix landed correctly (15/15 primary docs have FM); but meta docs (README, STATE) still lack FM. 38 spot-checks (15 true, 23 false). Reviewer-claimed grade E- matches grade.sh output (16 CRITICAL with count >5 = worst-with-minus modifier). 5 new Q&A entries appended (Q18-Q22). Ledger at `.aid/.temp/review-pending/discovery.md`. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | — | — | — | — | — | No summarize run on cycle-1 or cycle-2 (Discovery still in REVIEW) |

## Calibration Log

> Work-003 traceability: one row per dispatched sub-agent. Append-only. Format: `| date | agent | cycle | ETA band | actual | notes |`

| Date | Agent | Cycle | ETA | Actual | Notes |
|------|-------|-------|-----|--------|-------|
| 2026-05-27 | discovery-scout | cycle-1 GENERATE | 9-13m | 11m17s | inside band; produced project-structure (318 lines) + external-sources (no-docs variant) + .scout-questions.tmp (10 Q-S entries: 3H/4M/3L) |
| 2026-05-27 | discovery-architect | cycle-1 GENERATE | 8-12m | 9m34s | inside band; 3 docs: architecture (326L) + technology-stack (186L) + ui-architecture (320L) = 832L total; flagged 4 doc-vs-impl discrepancies |
| 2026-05-27 | discovery-quality | cycle-1 GENERATE | 11-15m | 9m34s | faster than band; 4 docs (744L total): test-landscape (114) + security-model (153) + tech-debt (255, 1C+3H+4M+3L) + infrastructure (222); flagged 5 doc-vs-reality discrepancies + corrected 2 dispatch-prompt errors |
| 2026-05-27 | discovery-integrator | cycle-1 GENERATE | 12-16m | 13m59s | inside band; 3 docs (1281L total, 395 citations): api-contracts (566L) + integration-map (362L) + domain-glossary (353L, 195 terms vs 80 target) |
| 2026-05-27 | discovery-analyst | cycle-1 GENERATE | 12-18m | 14m29s | inside band; 3 docs (1211L total): module-map (297L) + coding-standards (457L) + data-model (457L); T3 scrub clean; 2 inferred-only items tagged |
| 2026-05-27 | GENERATE-orchestrator | cycle-1 wrap-up | n/a | ~25m | Scout 11m17s + 4-parallel wave 14m29s tail (analyst). All 16 docs populated + INDEX.md generated (127L) + README.md generated (39L) + 10 Q&A consolidated from scout-questions.tmp. verify-claims exit 1 (drifts expected on first-pass; REVIEW will surface) |
| 2026-05-27 | discovery-reviewer | cycle-1 REVIEW | 15-25m | 11m57s | well under LOW; 30 spot-checks (26 verified, 4 failed); 16 HIGH (12 FM-MISSING + 2 INDEX + 2 feature-inventory) + 11 MEDIUM + 11 LOW; reviewer-claimed grade D-, grade.sh computed E+ (E+ authoritative); 5 new Q&A entries appended (Q11-Q15); ledger at `.aid/.temp/review-pending/discovery.md` (238L) |
| 2026-05-27 | discovery-reviewer | cycle-2 REVIEW | 15-25m | ~13m | inside band; 38 spot-checks (15 true, 23 false); 16 [CRITICAL] + 24 [HIGH] + 20 [MEDIUM] + 5 [LOW] + 8 [MINOR]; reviewer-claimed grade E-, matches grade.sh output (16 CRITICAL count > 5 → minus modifier); 5 new Q&A entries Q18-Q22; ledger at `.aid/.temp/review-pending/discovery.md`; cycle dominated by CLAUDE.md collapse (CC1) + verify-claims.sh deletion not cascaded (CC2) |
