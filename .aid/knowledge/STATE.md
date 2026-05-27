# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** In Progress
> **Current Grade:** E+
> **User Approved:** no
> **Last KB Review:** 2026-05-27
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
| None provided | — | — | No external documentation registered for cycle-1 |

## KB Documents Status

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [LOW] 1148-vs-1149 drift; [LOW] 405-vs-402 drift |
| 2 | external-sources.md | Reviewed | D+ | 2026-05-27 | [HIGH] FM-MISSING (3-line file still needs frontmatter) |
| 3 | architecture.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] skill-line-count drift unresolved; [LOW] rendered cite |
| 4 | technology-stack.md | Reviewed | D+ | 2026-05-27 | [HIGH] FM-MISSING; [LOW] T3 churn (script line counts duplicated) |
| 5 | module-map.md | Reviewed | A | 2026-05-27 | Frontmatter OK; contracts well-formed; no findings |
| 6 | coding-standards.md | Reviewed | A | 2026-05-27 | Frontmatter OK; exemplary cited evidence; no findings |
| 7 | data-model.md | Reviewed | A | 2026-05-27 | Frontmatter OK; 16-section structural inventory verifiable; no findings |
| 8 | api-contracts.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 5-vs-6-section count contradiction |
| 9 | integration-map.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 1148-vs-1149 cite; [LOW] legacy DISCOVERY-STATE.md mixing |
| 10 | domain-glossary.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 3-way acronym conflict; [MEDIUM] 150-vs-195 term count; [LOW] IQ-vs-Q convention |
| 11 | test-landscape.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 297-unverifiable test count |
| 12 | security-model.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 5-vs-6 sub-agent count |
| 13 | tech-debt.md | Reviewed | D+ | 2026-05-27 | [HIGH] FM-MISSING; H1 known-issue correctly captured |
| 14 | infrastructure.md | Reviewed | D+ | 2026-05-27 | [HIGH] FM-MISSING; all CLAUDE.md cites verified accurate |
| 15 | ui-architecture.md | Reviewed | D | 2026-05-27 | [HIGH] FM-MISSING; [MEDIUM] 2-vs-3 token files count |
| 16 | feature-inventory.md | Reviewed | E | 2026-05-27 | [HIGH] template-only (placeholder row); [HIGH] zero features inventoried |

**Meta-documents:**

| Document | Status | Grade | Notes |
|----------|--------|-------|-------|
| INDEX.md | Reviewed | E | [HIGH] stale vs .aid/generated/INDEX.md; [HIGH] 67% no-intent due to FM-MISSING propagation |
| README.md | Reviewed | B+ | [LOW] "All 16 populated" overstates (feature-inventory is Template) |
| STATE.md (this file) | Reviewed | C | [MEDIUM] placeholders unfilled; [MEDIUM] Status:Pending contradicts README:Populated; [MEDIUM] Q&A schema variance |

## Knowledge Summary Status

| Field | Value |
|-------|-------|
| Profile | — (no summarize run yet on cycle-1) |
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

> Issues found during REVIEW state, cycle-1. Severity tags drive grade.sh.
> Full per-doc breakdown in `.aid/.temp/review-pending/discovery.md`.

### project-structure.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [LOW] Line 29 says project-index.md is 1149 lines; actual is 1148
- [LOW] Line 256 says discovery-reviewer.md is 402 lines; actual is 405

### external-sources.md (D+)
- [HIGH] [FM-MISSING] 3-line file still needs frontmatter per kb-authoring/frontmatter-schema.md:6-7

### architecture.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Skill-body line count: CLAUDE.md says 2108, canonical sums to 2230 — doc flags but does not resolve
- [LOW] Rendered-vs-canonical aid-config size cited (190 vs 176) without path to rendered copy

### technology-stack.md (D+)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [LOW] Development Tools table duplicates T3 metric data from module-map.md and metrics.md (P1 violation: drift-prone)

### module-map.md (A)
- (none)

### coding-standards.md (A)
- (none)

### data-model.md (A)
- (none)

### api-contracts.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] api-contracts.md:99-110 says "EXACTLY 5 sections" then lists 6 items (load-bearing protocol contract contradicts itself)

### integration-map.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Line 54 cites project-index.md as 1149 lines; actual is 1148 (inherits drift from project-structure.md:29)
- [LOW] Loop 1-11 table at lines 291-302 uses legacy "DISCOVERY-STATE.md" alongside current STATE.md terminology

### domain-glossary.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Line 18 defines AID as "AI-Integrated Development" but CLAUDE.md:5 says "Agentic Implementation Discipline" and settings.yml:16 says "AI Integrated Development" and user-memory says "Agent Integrated Development" — three-way conflict not flagged
- [MEDIUM] Line 351 says "~150 terms"; actual count = 195
- [LOW] Q&A schema cited as IQ{N} but actual STATE.md uses Q{N}

### test-landscape.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Line 111 notes 73 tests are uninvocable but does not surface the locally-runnable count (~224/297) — users cannot verify the 297/297 claim

### security-model.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Authorization table lists 6 discovery-* entries; module-map.md and project-structure.md count 5 discovery sub-agents (excluding discovery-reviewer); terminology inconsistent

### tech-debt.md (D+)
- [HIGH] [FM-MISSING] No YAML frontmatter present (the canonical template has frontmatter; the deployed copy does not)
- [LOW] H1 correctly verified (e2e runners missing from disk)

### infrastructure.md (D+)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- All CLAUDE.md citations verified accurate

### ui-architecture.md (D)
- [HIGH] [FM-MISSING] No YAML frontmatter present
- [MEDIUM] Lines 102/109 say "two files that must stay in sync" but table immediately lists THREE files (design-tokens.md, component-css.css, mermaid-init.js)

### feature-inventory.md (E)
- [HIGH] [FM-PARTIAL] Frontmatter present but document is template-only (placeholder row at line 25)
- [HIGH] Zero features inventoried; metrics.md:96-97 reports false-positive Shipped=2/Partial=2 from legend block

### INDEX.md (E)
- [HIGH] STALE: `.aid/knowledge/INDEX.md` (4687 bytes, 2026-05-27T19:30:58Z) differs from `.aid/generated/INDEX.md` (4753 bytes, 2026-05-27T20:01:25Z) — generated copy has README.md entry; knowledge copy does not
- [HIGH] 12 of 18 entries show "*(no intent: declared)*" — cannot fulfill stated purpose for 67% of KB

### README.md (B+)
- [LOW] Line 6 claims "All 16 canonical KB documents populated" but feature-inventory.md is Template-only (acknowledged in row 29 but overstated in prose)

### STATE.md (C)
- [MEDIUM] Template placeholders unfilled at lines 8, 22, 49-59 (Last Summary, External Documentation row, Knowledge Summary Status fields)
- [MEDIUM] KB Documents Status (lines 27-43) marks all 16 docs Status=Pending, contradicting README.md:14-29 (all Populated)
- [MEDIUM] Q&A entries use ### Q1 / sub-bullets schema; methodology spec / work-state-template uses ### IQ1: [Category: Impact] inline — two Q&A schemas now coexist in codebase
- [LOW] Review History row 140-141 still has template placeholder `{YYYY-MM-DD}`

## Cross-Cutting Concerns

- **CC1 [HIGH]:** Frontmatter missing on 12 of 16 primary KB docs (already counted per-doc above; here for visibility)
- **CC2 [HIGH]:** INDEX.md stale relative to generator output (two-copy drift)
- **CC3 [MEDIUM]:** Project acronym defined four different ways (CLAUDE.md / settings.yml / domain-glossary.md / user-memory)
- **CC4 [MEDIUM]:** project-index.md cited as 1149 lines; actual = 1148 (drift in project-structure.md:29 → integration-map.md:54)
- **CC5 [MEDIUM]:** discovery-reviewer.md cited as 402 lines; actual = 405 (drift in project-structure.md:256 → domain-glossary.md:240)
- **CC6 [MEDIUM]:** "5 sub-agents" vs "6 discovery-* agents" terminology inconsistent across module-map / integration-map / security-model
- **CC7 [MEDIUM]:** feature-inventory.md empty + metrics.md reports false counts (2 Shipped, 2 Partial from legend block matches)
- **CC8 [LOW]:** domain-glossary.md says ~150 terms; actual = 195 (also wrong in metrics.md)

## Verification Spot-Checks

> 30 spot-checks performed; 26 verified-true, 4 verified-false. Full list in
> `.aid/.temp/review-pending/discovery.md` § Verification Spot-Checks. Failed
> checks below:

| # | Claim | Doc | Verified | Evidence |
|---|-------|-----|----------|----------|
| 21 | project-index.md = 1149 lines | project-structure.md:29, integration-map.md:54 | NO | `wc -l .aid/generated/project-index.md` = 1148 |
| 22 | discovery-reviewer.md = 402 lines | project-structure.md:256, domain-glossary.md:240 | NO | `wc -l canonical/agents/discovery-reviewer/AGENT.md` = 405 |
| 24 | Mermaid fetch is version-pinned + SHA-verified | (dispatcher claim about scout) | NO | `grep EXPECTED_SHA256 canonical/scripts/summarize/fetch-mermaid.sh` returns nothing; SHA computed after download |
| 27 | 297/297 expected tests | CLAUDE.md:42 | NO unverifiable | 73 tests from missing `.aid/work-001-aid-lite/` runners; locally-runnable ~224 |
| 30 | domain-glossary.md ~150 terms | domain-glossary.md:351 | NO | Actual = 195 terms (`grep -c "^\| \*\*"` ) |

Verified-true (sample):
- Python 3.11+ at `.claude/skills/aid-generate/scripts/harness.py:15`
- PowerShell 5.1+ at `setup.ps1:1` (`#Requires -Version 5.1`)
- 22 agents (verified via `ls canonical/agents/ | wc -l`)
- 10 user-facing skills (verified via `ls canonical/skills/ | wc -l`)
- 5 recipes + README (verified via `ls canonical/recipes/`)
- 16 STANDARD_KB_FILES (verified via `sed -n 102,119p canonical/scripts/kb/verify-claims.sh`)
- methodology/aid-methodology.md = 1071 lines
- verify-claims.sh = 695 lines
- writeback-task-status.sh = 627 lines
- state-execute.md = 629 lines
- harness.py = 756 lines
- profile.py = 550 lines
- setup.sh = 162 lines
- Skill canonical sum = 2230 lines (architecture.md acknowledges drift vs CLAUDE.md's 2108)
- settings.yml minimum_grade default at line 38
- settings.yml heartbeat_interval at line 50
- `.aid/work-001-aid-lite/` missing (tech-debt.md H1 correct)
- `.aid/work-002-canonical-generator/` missing (tech-debt.md M1 correct)
- project-index.md Total files = 1077 (header)
- 12 of 16 primary docs lack frontmatter (verified per-doc)
- `.aid/knowledge/INDEX.md` stale vs `.aid/generated/INDEX.md` (verified via diff)

## Q&A (Pending)

> Open questions from cycle-1 GENERATE (Q1-Q10) + cycle-1 REVIEW (Q11+). Renumbered from scout-local Q-S{N} to canonical Q{N}.

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
- **Context:** AID is expanded FOUR different ways in the codebase:
  (1) `CLAUDE.md:5` = "Agentic Implementation Discipline"
  (2) `.aid/settings.yml:16` = "AI Integrated Development"
  (3) `domain-glossary.md:18` = "AI-Integrated Development" (hyphenated)
  (4) User memory `project_aid-acronym.md` body = "AI Integrated Development" (memory INDEX line previously said "Agent Integrated Development" — corrected in this session)
  Downstream skills, README, and any new contributor will pick a different one. tech-debt.md M2 captures only #1 vs #2; this is broader.
- **Suggested (corrected from reviewer's stale read):** Canonical = "AI Integrated Development" per `.aid/settings.yml:16` + user-memory body.
- **Answer:** **AID = "AI Integrated Development" (no hyphen).** Per user confirmation (2026-05-27). FIX state actions: (1) `CLAUDE.md:5` — replace "Agentic Implementation Discipline" → "AI Integrated Development"; (2) `domain-glossary.md:18` — remove hyphen ("AI-Integrated Development" → "AI Integrated Development"); (3) Grep entire repo for "Agentic Implementation Discipline", "Agent Integrated Development", "AI-Integrated Development" (hyphenated) and replace each with canonical; (4) Update `methodology/aid-methodology.md` if it carries any variant; (5) Update profile-tree mirrors (`profiles/{claude-code,codex,cursor}/`) so they pick up the canonical via render; (6) Update `tech-debt.md` M2 to mark resolved.

### Q12
- **Category:** KB-Generator
- **Impact:** Medium
- **Status:** Answered
- **Context:** `.aid/knowledge/INDEX.md` is generated by `bash .claude/scripts/kb/build-index.sh --root .aid/knowledge --output .aid/generated/INDEX.md` (per its own header line 16). The default output is `.aid/generated/INDEX.md`, NOT `.aid/knowledge/INDEX.md`. Two copies now exist on disk, with different timestamps and contents (the knowledge/ copy lacks the README.md entry the generated/ copy has).
- **Suggested:** Either (a) Have `build-index.sh` also write to `.aid/knowledge/INDEX.md` so the two stay in sync, (b) Delete `.aid/knowledge/INDEX.md` and point all consumers at `.aid/generated/INDEX.md`, or (c) Document explicitly which one is canonical.
- **Answer:** **Single copy at `.aid/knowledge/INDEX.md`.** Per user (2026-05-27). Co-located with the docs it indexes (RAG pattern). FIX state actions: (1) Update `build-index.sh` default output from `.aid/generated/INDEX.md` to `.aid/knowledge/INDEX.md`; (2) Update `verify-claims.sh` GEN-MISSING registry to expect INDEX.md at `.aid/knowledge/INDEX.md` (or remove from registry since it's now co-located with primary docs); (3) Delete `.aid/generated/INDEX.md`; (4) Update `generated-files.txt` registry to drop the `.aid/generated/INDEX.md` line; (5) Grep skills + state-*.md references for `.aid/generated/INDEX.md` and replace with `.aid/knowledge/INDEX.md`.

### Q13
- **Category:** Feature-Inventory
- **Impact:** High
- **Status:** Answered
- **Context:** `.aid/knowledge/feature-inventory.md` contains a single placeholder row `*(populated during Discovery Q&A + FIX)*` at line 25. README.md correctly marks it as "Template" in the table. But `build-metrics.sh` matches against the legend block (lines 17-21) and reports "Shipped=2, Partial=2" in `.aid/generated/metrics.md:96-97`. The metric is meaningless because the table is empty, but downstream code reads it.
- **Suggested:** Populate feature-inventory.md from CLAUDE.md `## Architecture` bullets + the 10 user-facing skills as discrete "features". Use a status of ✅ Shipped for everything in the current canonical/ tree.
- **Answer:** **10 user-facing skills as features.** Per user (2026-05-27). FIX state actions: (1) Populate `feature-inventory.md` table with one row per user-facing skill: `aid-config`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy`, `aid-monitor`, `aid-summarize` — all with status `✓ Shipped`; (2) Add a separate row or footnote for `aid-generate` (maintainer-only, also Shipped); (3) Each row should cite the skill's `.claude/skills/<skill>/SKILL.md` source. **Important context note from user:** They have independently cleaned up CLAUDE.md to remove incorrect/stale info — FIX state actions touching CLAUDE.md must re-read the file first; do not rely on prior content cached in agent contexts.

### Q14
- **Category:** Frontmatter
- **Impact:** High
- **Status:** Answered
- **Context:** 12 of 16 primary KB docs lack the required YAML frontmatter (`kb-category`, `source`, `intent`, etc. per `canonical/templates/kb-authoring/frontmatter-schema.md:14-26`). The 4 that have it (module-map, coding-standards, data-model, feature-inventory) appear to be ones authored from the template. The other 12 either pre-date the schema or had it stripped during a recent rewrite. INDEX.md as a result shows "*(no intent: declared)*" for 12 of 18 entries. This is the single biggest blocker to KB usefulness.
- **Suggested:** Add frontmatter to all 12 missing docs. Use the schema template as the source; cycle each through review.
- **Answer:** Pure FIX action, no user-decision needed — accept Suggested. FIX state will dispatch tech-writer agents (one per missing doc, parallel) to add `kb-category`, `source`, `intent` frontmatter per schema. The 4 that already have FM (module-map, coding-standards, data-model, feature-inventory) are the template for the other 12.

### Q15
- **Category:** STATE-Schema
- **Impact:** Medium
- **Status:** Answered
- **Context:** Two Q&A entry schemas now exist in the codebase: (1) `### Q1` with sub-bullets for Category / Impact / Status / Context / Suggested (this STATE.md's style); (2) `### IQ1: [Category: Impact]` inline followed by Question / Context / Source / Suggested / Status (the methodology spec / work-state-template.md style). Both are valid and used. Should the canonical schema be one or the other? Currently downstream skills must support both.
- **Suggested:** Pick one canonical schema (probably the methodology spec's IQ-style, since it is more compact and inline-grep-able) and update `canonical/templates/discovery-state-template.md` to match. Migrate existing STATE.md entries via a one-time script.
- **Answer:** **Canonical = Style A** (`### Q{N}` + sub-bullets). Per user (2026-05-27). FIX state actions: (1) Update `canonical/templates/work-state-template.md` to use Style A for the `## Cross-phase Q&A` section; (2) Update `methodology/aid-methodology.md` Q&A spec to use Style A; (3) Update `aid-interview` skill body + references to emit Style A on Q&A injection from downstream phases; (4) Document Style A in `coding-standards.md` as the canonical Q&A schema (with example block); (5) No existing-entry migration needed (this cycle's STATE.md already uses Style A; aid-interview hasn't been run on a real work-item recently).

### Q16
- **Category:** Methodology / Doc-Set
- **Impact:** High
- **Status:** Answered
- **Context:** Q3's resolution (rename 2 + delete 1 + delete-and-replace 1) effectively customizes the canonical 16-doc KB set for this repo. Currently the methodology spec, `aid-discover` skill (verify-claims expected-doc list), and `canonical/templates/knowledge-base/` template-set all assume a rigid 16-doc set. After Q3 lands, this repo will have a 15-doc set with 2 renamed and 1 replaced. The methodology should support this flexibility as a first-class feature instead of treating it as drift.
- **Suggested:** Decide whether this is (a) a one-off carve-out for the AID repo itself, or (b) a methodology-level change.
- **Answer:** **(b) Methodology-level change.** Per user (2026-05-27): "If the methodology assumes a rigid 16-doc set, we need to change that. That is like a default set that could be changed by the user. We could add or remove new docs to better represent the content of the repo. The methodology should be flexible to adapt to the intent and content of the project. The INDEX.md is the aggregator, the true representation of the content of the KB." Action: this Discovery cycle's FIX state (a) captures the user's principle in `coding-standards.md` (or `methodology.md` if more appropriate) AND (b) **adds a tech-debt.md entry**: "Methodology change — flexible KB doc-set. Scope: redesign methodology spec to treat 16-doc list as default, add `discovery.kb_docs:` section to `.aid/settings.yml` schema, rewrite `aid-discover` state-detection + verify-claims to read declared list, update `canonical/templates/knowledge-base/` from 'mandatory templates' to 'default templates + sub-folder for custom'. Pick up via `/aid-interview` when prioritized — work-NNN assignment happens then." Cycle-1 FIX still uses the 15-doc post-Q3 set as a one-time carve-out until the larger refactor ships. **Do NOT reserve a work-NNN number here** — Discovery defers that to /aid-interview.

### Q17
- **Category:** Test-Refactor
- **Impact:** Medium
- **Status:** Answered
- **Context:** Per Q6's answer, cycle-1 FIX state cleans up obvious test cruft (delete 3, keep 5). User also requested a broader refactor of the remaining 5 tests toward clean-code patterns and clearer names. Current names describe the SCRIPT under test, not the BEHAVIOR being asserted. Bash test patterns vary across the suites; some use plain `[[ ]]`, others have helper functions. No shared test-utility module.
- **Suggested:** Decide whether to (a) do the refactor inline during cycle-1 FIX, or (b) capture as separate `work-NNN-test-refactor` work item.
- **Answer:** **(b) Separate work-NNN (recommended).** Per user (2026-05-27). Cycle-1 FIX scope stays as Q6 (delete 3 + keep 5, no rename). The broader refactor is captured as a **tech-debt.md entry**: "Test-refactor toward clean-code patterns. Scope: rename convention (`<behavior-under-test>_test.sh` or bats migration), shared test-utility extraction (assertions, setup/teardown, common fixtures), consistent failure messages, optional aggregator script if warranted. Pick up via `/aid-interview` when prioritized — work-NNN assignment happens then." **Do NOT reserve a work-NNN number here** — Discovery defers that to /aid-interview.

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-27 | E+ | /aid-discover | Initial cycle-1 REVIEW. 0 [CRITICAL], 16 [HIGH], 11 [MEDIUM], 11 [LOW]. Blockers: FM-MISSING on 12 docs, INDEX.md two-copy drift, feature-inventory template-only. **Grade discrepancy:** reviewer wrote D- but `bash .claude/scripts/grade.sh .aid/.temp/review-pending/discovery.md` computes E+ deterministically — per "grade is calculated, not judged" contract, E+ is authoritative. Reviewer's per-doc grades preserved as judgment but overall grade snapped to grade.sh output. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | — | — | — | — | — | No summarize run on cycle-1 (Discovery still in REVIEW) |

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
