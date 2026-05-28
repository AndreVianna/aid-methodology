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
  - 2026-05-27: Cycle-3 REVIEW results written (post-cycle-2 FIX validation)
---

# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** In Progress
> **Current Grade:** E+
> **User Approved:** no
> **Last KB Review:** 2026-05-27 (cycle-3)
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
| None provided | — | — | No external documentation registered for cycle-1, cycle-2, or cycle-3 |

## KB Documents Status

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Reviewed | D | 2026-05-27 | [HIGH] Folder tree (lines 39-87) is stale snapshot: 5+ values wrong (tests/canonical=6 not 5, tests/skills/ still cited, README=374 not 388, CLAUDE.md=118 not 25, run_generator=86 not 87) yet CORRECT values stated elsewhere in same doc — internal contradiction missed by cycle-2 sweep |
| 2 | external-sources.md | Reviewed | A- | 2026-05-27 | [MINOR] minimal one-sentence body (unchanged); [MINOR] empty contracts — same as cycle-2, no regression |
| 3 | architecture.md | Reviewed | C | 2026-05-27 | [MEDIUM] methodology 1,071 vs 1,070 (3 places); [MEDIUM] folder tree run_generator 86 vs 87 (internal contradiction with line 180 "87-line"); [LOW] inline T3 line counts (P1 violation) but ACCURATE |
| 4 | technology-stack.md | Reviewed | B- | 2026-05-27 | [LOW] inline T3 line counts (Languages + Dev Tools tables) — all ACCURATE against disk; no factual errors. Major improvement vs cycle-2 (was E) |
| 5 | module-map.md | Reviewed | D+ | 2026-05-27 | [HIGH] tests/skills/lite-subpaths.sh still cited as live (line 281) — dir deleted; [LOW] FM contract Python file count accurate |
| 6 | coding-standards.md | Reviewed | D+ | 2026-05-27 | [HIGH] tests/skills/ cite at line 345 ("two skill-level e2e tests live at tests/skills/<test-name>.sh") — dir deleted. Major improvement vs cycle-2 (was E) |
| 7 | schemas.md | Reviewed | A- | 2026-05-27 | [LOW] FM contract accurate; [MINOR] cite to aid-discover SKILL.md line range OK. Major improvement vs cycle-2 (was E+) |
| 8 | pipeline-contracts.md | Reviewed | B+ | 2026-05-27 | [MEDIUM] line 56 still says "Writes 16 KB docs" — actual 15; [LOW] verify-claims.sh correctly referenced as deleted. Major improvement vs cycle-2 (was E+) |
| 9 | integration-map.md | Reviewed | B- | 2026-05-27 | [LOW] run_generator.py "(86 lines)" at line 183 — actual 87; [LOW] inline T3 line counts. Major improvement vs cycle-2 (was E+) |
| 10 | domain-glossary.md | Reviewed | C | 2026-05-27 | [MEDIUM] glossary stats line 364: "~195 (per metrics.md)" but metrics says 172 — wrong attribution + drift; [MEDIUM] internal self-contradiction line 16 "1,071-line spec" vs line 365 "(1,070 lines)" |
| 11 | test-landscape.md | Reviewed | A | 2026-05-27 | Cycle-2 FIX rewrite landed — 5 suites accurate, 235 tests counted, FM contracts match disk. Excellent improvement (was E-) |
| 12 | tech-debt.md | Reviewed | D | 2026-05-27 | [HIGH] H4 three-way severity disagreement (summary High, row Medium, header MEDIUM); [HIGH] count summary still disagrees with metrics.md (6/6/5 vs 12/14/11 — cycle-2 CC8 unresolved); [MEDIUM] M2 RESOLVED but still counted; [MINOR] H5 verify-claims reference acceptable historical |
| 13 | infrastructure.md | Reviewed | B- | 2026-05-27 | [MEDIUM] PR merge dates 152-156 (T4 carryover); [LOW] inline T3 line counts in build pipeline table all ACCURATE. Major improvement vs cycle-2 (was E+) |
| 14 | repo-presentation.md | Reviewed | D+ | 2026-05-27 | [MEDIUM] README=374 (actual 388, cycle-2 carryover); [MEDIUM] methodology=1,071 (actual 1,070, cite to wrong line); [MINOR] T4 markers borderline acceptable |
| 15 | feature-inventory.md | Reviewed | A- | 2026-05-27 | Cycle-2 glyph fix landed — all 11 rows use emoji checkmark; [LOW] intent vs legend wording drift (Deferred vs Pending/In Progress); [MINOR] empty contracts |

**Meta-documents:**

| Document | Status | Grade | Notes |
|----------|--------|-------|-------|
| INDEX.md | Reviewed | A- | Cycle-2 INDEX regenerated — meta docs now show declared intents; [LOW] feature-inventory entry wording drift; [LOW] cosmetic self-entry |
| README.md | Reviewed | C+ | [MEDIUM] top-level "Discovery cycle: 1 (initial post-reset)" stale (cycle-3 now); [MEDIUM] all 14 Completeness table line counts stale vs metrics.md; FM landed (cycle-2 Q22) |
| STATE.md (this file) | Reviewed | B- | [MEDIUM] Current Grade D+ pre-cycle-3 (updated this cycle); FM landed (cycle-2 Q22); structural integrity sound |
| metrics.md (generated) | Reviewed | B | [LOW] glossary term count 172 vs disk 195 (build script regex undercounts); [MEDIUM] feature-inventory Shipped=12 vs body=11 (build script over-counts checkmarks). Generator ran cleanly; AUTO-GEN marker present |

## Knowledge Summary Status

| Field | Value |
|-------|-------|
| Profile | — (no summarize run yet on cycle-1, cycle-2, or cycle-3) |
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

> Issues found during cycle-3 REVIEW state. Severity tags drive grade.sh.
> Full per-doc breakdown in `.aid/.temp/review-pending/discovery.md`.
> Cycle-3 trajectory: cycle-1 E+ → cycle-2 E- → cycle-3 D. Two cycle-2 cascade
> failures (CC1 CLAUDE.md cite + CC2 verify-claims.sh) are now CLEAN. New
> cycle-3 issues centered on: (a) project-structure.md folder-tree block missed
> in cycle-2 sweep; (b) two surviving stale tests/skills/ cites; (c) tech-debt
> self-count vs metrics still unreconciled; (d) widespread P1 T3 inline
> violations (line counts) — mostly ACCURATE but principle-violating.

### project-structure.md (D)
- [HIGH] Folder tree block (lines 39-87) is stale snapshot: 5+ values wrong (tests/canonical "6 suites" vs actual 5; tests/skills/ entry vs deleted dir; README "374 lines" vs 388; CLAUDE.md "118 lines" vs 25; run_generator.py "86 lines" vs 87) — all CORRECTLY stated elsewhere in same doc (lines 121, 125, 191, 319). Internal contradiction; one block missed by cycle-2 FIX sweep
- [MEDIUM] Line 134: "methodology/aid-methodology.md | 1,071" — actual 1,070

### coding-standards.md (D+)
- [HIGH] Line 345: "The two skill-level e2e tests live at tests/skills/<test-name>.sh." — tests/skills/ deleted cycle-1 per Q6; this citation teaches the wrong location

### module-map.md (D+)
- [HIGH] Line 281: "recipe behavior is exercised by tests/canonical/parse-recipe.sh and tests/skills/lite-subpaths.sh" — second file deleted cycle-1; teaches the wrong location

### tech-debt.md (D)
- [HIGH] Three-way H4 severity disagreement: summary count line 32 puts H4 in High; row line 47 says "Medium" in Risk column; section header line 247 says "[MEDIUM] H4"
- [HIGH] Summary count line 30-34 disagrees with metrics.md 68-72: tech-debt says C=1/H=6/M=6/L=5; metrics says H=12/M=14/L=11. Carryover from cycle-2 CC8 — counting methodology unreconciled
- [MEDIUM] Line 50: M2 marked "RESOLVED" but still in MEDIUM count at line 33 ("M1, M2 (resolved), M3, M4, M5, M6")
- [MINOR] Line 47 H5 location field: "verify-claims" reference acceptable historical scope marker

### repo-presentation.md (D+)
- [MEDIUM] Line 44: "Source: README.md:1-374 (374 lines)" — actual 388. Subsequent section line-cites in table at lines 51-61 likely also stale (derived from 374-line assumption). Cycle-2 carryover
- [MEDIUM] Line 196: "full document is 1,071 lines per project-structure.md:57" — actual 1,070; cite-to-wrong-line as well
- [MINOR] Line 202: "Version: 3.1 — May 2026" — T4 inline (acceptable per rubric exception)

### architecture.md (C)
- [MEDIUM] Lines 31, 173, 293: "methodology/aid-methodology.md, 1,071 lines" — actual 1,070 (3 occurrences)
- [MEDIUM] Line 84 vs 180: folder tree says "(86 lines)"; later line says "87-line glue" — internal contradiction (actual 87)
- [LOW] Lines 127, 136: "Total skill body lines: 2,242" — accurate against metrics.md; inline T3 P1 violation

### domain-glossary.md (C)
- [MEDIUM] Line 364: "Total terms defined: ~195 (per metrics.md generated count)" — metrics.md says 172; wrong attribution + 3-way mismatch (body ~195, attribution per metrics, metrics says 172)
- [MEDIUM] Line 16 vs 365: "1,071-line spec" vs "(1,070 lines)" — internal contradiction
- [LOW] Line 77: project-index.md "(1,148 lines)" — accurate; inline T3

### integration-map.md (B-)
- [LOW] Line 183: "run_generator.py ← entrypoint (86 lines)" — actual 87
- [LOW] Lines 67, 185-194: inline T3 line counts all accurate against project-structure.md

### infrastructure.md (B-)
- [MEDIUM] Lines 152-156: "Recent merge history" PR dates inline (T4 carryover from cycle-2; may be load-bearing context)
- [LOW] Lines 89-100: build pipeline table inlines T3 line counts × 10 rows — all ACCURATE; P1 violation

### pipeline-contracts.md (B+)
- [MEDIUM] Line 56: "Writes 16 KB docs + STATE.md + INDEX.md" — actual 15 primary docs post-Q3
- [LOW] Lines 311-312: build-project-index.sh "(368 lines per project-structure.md:153)" — accurate; inline T3

### technology-stack.md (B-)
- [LOW] Inline T3 line counts in Languages + Dev Tools tables — all ACCURATE; P1 violations

### test-landscape.md (A)
- (clean — full rewrite landed cycle-2; no residual issues)

### schemas.md (A-)
- (clean — major improvement vs cycle-2; FM contract accurate; cite to aid-discover SKILL.md OK)

### external-sources.md (A-)
- [MINOR] One-sentence body unchanged (acceptable)
- [MINOR] Empty contracts (cosmetic)

### feature-inventory.md (A-)
- [LOW] Intent says "(Shipped / Partial / Deferred)" — legend says "Shipped / Partial / Pending / In Progress" — wording drift
- [MINOR] Empty contracts

### INDEX.md (A-)
- [LOW] Line 73: feature-inventory entry wording drift (Deferred vs Pending)
- [LOW] Lines 27-33: cosmetic self-entry (build-index.sh includes own output)

### README.md (C+)
- [MEDIUM] Lines 16-17: "Discovery cycle: 1 (initial post-reset)" + "Last KB review: 2026-05-27 (cycle-1 REVIEW · post-FIX awaiting cycle-2)" — stale; cycle-3 in progress
- [MEDIUM] Lines 26-40: All 14 Completeness table line counts stale vs metrics.md (project-structure 334 vs 329, architecture 343 vs 333, coding-standards 544 vs 563, etc.)

### STATE.md (B-)
- [MEDIUM] Current Grade D+ stale (now D per cycle-3 — updated this cycle)
- (otherwise structurally sound; FM landed cycle-2 Q22)

### metrics.md (B, generated/build-verify)
- [MEDIUM] Lines 82-83: Feature inventory "Shipped | 12 | Partial | 1" — body has 11 ✅ rows only; build script over-counts stray checkmarks in narrative bullets
- [LOW] Line 76: Term count 172 vs disk 195 (carryover from cycle-2; build script regex undercounts)
- (Generator ran cleanly 2026-05-28T01:44:15Z; AUTO-GENERATED marker present)

## Cross-Cutting Concerns

- **CC1 — CLEAN [resolved cycle-3 verification]:** CLAUDE.md cite cascade from cycle-2 is fully resolved. Only valid cites remain (`CLAUDE.md:5`, `CLAUDE.md:1-25`). Cycle-2 FIX Phase A landed correctly.
- **CC2 — CLEAN [resolved cycle-3 verification]:** verify-claims.sh deletion cascade is fully resolved. All live citations removed. Remaining mentions are correct narrative ("was deleted in cycle-1", "deletion follow-up").
- **CC3 [NEW, HIGH]:** Two surviving stale `tests/skills/` cites in coding-standards.md:345 + module-map.md:281. Directory deleted cycle-1 but these citations teach the wrong location. Cycle-2 FIX swept primary docs but missed these two.
- **CC4 [NEW, HIGH]:** project-structure.md folder tree block (lines 39-87) is a stale snapshot block missed by cycle-2 sweep. 5+ values wrong; all CORRECT in prose elsewhere in same doc (e.g., line 121 says CLAUDE.md=25). Block needs full refresh.
- **CC5 [carryover from cycle-2 CC8, HIGH]:** tech-debt.md self-count (HIGH=6, MEDIUM=6, LOW=5) still disagrees with metrics.md tally (HIGH=12, MEDIUM=14, LOW=11). Counting methodology not reconciled. tech-debt counts table rows; metrics counts every body-tag occurrence (fix recipes carry inline severity tags). Either tech-debt summary needs a counting-methodology footnote OR build-metrics.sh needs scope-restriction.
- **CC6 [MEDIUM]:** Methodology line count drift: 1,071 cited in architecture.md (×3), domain-glossary.md (line 16), project-structure.md:134, repo-presentation.md:196. Actual 1,070. 5+ inline occurrences need either bulk-update or migration to metrics.md.
- **CC7 [MEDIUM]:** run_generator.py line count drift: 86 cited in architecture.md:84 (folder tree), integration-map.md:183, project-structure.md:84 (folder tree). Actual 87. 3+ occurrences; some docs contain BOTH 86 and 87 internally (architecture.md line 180 says "87-line glue").
- **CC8 [MEDIUM]:** README=374 cited in repo-presentation.md:44 + project-structure.md:80 (folder tree). Actual 388. Carryover from cycle-2.
- **CC9 [MEDIUM]:** Widespread P1 T3 inline violations (line counts inlined throughout primary docs). Most are ACCURATE against disk but principle-violating per tier-model.md T3 "banned from primary docs". Should defer to metrics.md only.
- **CC10 [MEDIUM]:** README.md (KB meta-doc) status fields fully stale: top-level cycle banner says "cycle 1 (initial post-reset)"; Completeness table line counts never re-synced after cycle-1 snapshot. Per rubric §Spot-Check Snapshot, meta-doc top-level fields must reflect latest cycle reality.

## Verification Spot-Checks

> 30 spot-checks performed; 23 verified-true, 7 verified-false. Full list (with
> evidence) in `.aid/.temp/review-pending/discovery.md` § Verification Spot-Checks.
> Major improvement vs cycle-2 (23 true vs cycle-2's 15 true).
> Failed checks excerpted below:

| # | Claim | Doc | Verified | Evidence |
|---|-------|-----|----------|----------|
| 2 | methodology = 1,071 lines | architecture (3x), domain-glossary, project-structure, repo-presentation | NO | wc -l methodology/aid-methodology.md = 1070 |
| 4 | run_generator.py = 86 lines | architecture.md:84, integration-map.md:183, project-structure.md:84 | NO | actual 87 |
| 6 | README.md = 374 lines | repo-presentation.md:44, project-structure.md:80 | NO | actual 388 |
| 12 | tests/skills/ still cited as live | coding-standards.md:345, module-map.md:281 | NO | dir deleted cycle-1; 2 primary docs still teach the path |
| 22 | Glossary term count = 172 (metrics) | metrics.md:76 | YES (metric value) | matches generator output but undercounts vs actual disk 195 |

Verified-true sample:
- CLAUDE.md = 25 lines ✓
- verify-claims.sh correctly all-narrative ✓
- KB has 15 primary + 3 meta = 18 docs ✓
- tests/canonical/ has 5 suites ✓
- tests/skills/ does not exist on disk ✓
- pool-dispatch.sh deleted ✓
- Skill body sum = 2,242 ✓
- discovery-reviewer.md = 387 lines ✓
- build-project-index.sh = 368 ✓
- grade.sh = 141 ✓
- recipes = 5 ✓
- settings.yml = 81 ✓
- Glossary term count = 195 (direct grep) ✓
- project-index.md = 1,148 lines ✓
- KB template count = 15 ✓
- INDEX.md FM + AUTO-GEN marker ✓
- metrics.md FM + AUTO-GEN marker ✓
- README.md (KB) has FM (cycle-2 Q22 landed) ✓
- STATE.md has FM (cycle-2 Q22 landed) ✓
- INDEX.md picks up README + STATE intents (cycle-2 cascade resolved) ✓

## Q&A (Pending)

> Open questions from cycle-1 (Q1-Q17), cycle-2 REVIEW (Q18-Q22). Cycle-3 added
> no new Q&A — all cycle-3 findings are mechanically resolvable from disk; no
> human input needed.

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
| 3 | 2026-05-27 | D | /aid-discover (cycle-3) | Cycle-3 REVIEW. 0 [CRITICAL], 5 [HIGH], 14 [MEDIUM], 16 [LOW], 7 [MINOR]. Grade UP 3 steps from cycle-2 (E- → D). Two CASCADE failures from cycle-2 are CLEAN: CC1 CLAUDE.md cite cascade fully resolved (only valid cites remain); CC2 verify-claims.sh fully resolved (no live cites, only correct narrative). NEW residue findings: (a) project-structure.md folder tree block (lines 39-87) is a stale snapshot missed by cycle-2 sweep — 5+ values wrong but CORRECT in same doc elsewhere; (b) 2 surviving stale tests/skills/ cites in coding-standards.md:345 + module-map.md:281; (c) tech-debt severity self-count vs metrics.md still unreconciled (cycle-2 CC8); (d) repo-presentation.md still says README=374; (e) methodology line count drift 1,071 vs 1,070 across 5+ docs; (f) run_generator.py 86 vs 87 across 3+ docs. Widespread P1 T3 inline violations (most ACCURATE but principle-violating). 30 spot-checks (23 true, 7 false). 0 new Q&A — all findings mechanically resolvable. Ledger at `.aid/.temp/review-pending/discovery.md`. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | — | — | — | — | — | No summarize run on cycle-1, cycle-2, or cycle-3 (Discovery still in REVIEW) |

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
| 2026-05-27 | discovery-reviewer | cycle-3 REVIEW | 15-25m | ~15m | inside band; 30 spot-checks (23 true, 7 false); 0 [CRITICAL] + 5 [HIGH] + 14 [MEDIUM] + 16 [LOW] + 7 [MINOR]; computed grade D per grade.sh (HIGH worst-tier + count 2-5); 0 new Q&A (all findings mechanically resolvable); cycle-2 CC1+CC2 cascades CLEAN; new residue: project-structure.md folder-tree block stale, 2 stale tests/skills/ cites, tech-debt count vs metrics unreconciled, widespread P1 T3 inline violations; ledger at `.aid/.temp/review-pending/discovery.md` |
