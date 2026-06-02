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
  - 2026-05-27: Cycle-4 REVIEW results written (post-cycle-3 FIX validation)
  - 2026-05-28: Cycle-6 REVIEW results written (post-cycle-5 FIX validation)
  - 2026-05-28: Cycle-7 REVIEW results written (post-cycle-6 FIX validation)
  - 2026-05-30: Dogfood refresh (post-#22–#28) — orchestrator cleanup sweep across the KB: applied the #24 script renames (writeback-state, build-kb-index, grade-summary, assemble-3part, discover/summarize-preflight, render_lib, render_canonical_scripts, aid_profile) + the `test-` suite prefix; VERIFY-4a/4b → VERIFY (deterministic)/(advisory); corrected test counts to 13 suites (run-all.sh aggregator + lib/assert.sh); migrated ~709 volatile `file:LINE` citations to durable grep-recoverable anchors (P1(d)); rewrote test-landscape.md to the 13-suite reality (de-inverted the coverage-gaps section); fixed the tech-debt ghost ref + PR-stack metric; rebuilt knowledge-summary.html and re-validated via the .mjs suites. KB-only; no canonical/ or profiles/ change.
---

# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** Reviewed — cycle-9 post-merge re-review complete; **awaiting user approval**
> **Current Grade:** A+ (cycle-9 recheck 2026-06-01 — grade.sh on `discover-kb-postmerge-recheck.md`: 0 CRITICAL/HIGH/MEDIUM/LOW/MINOR; all 35 post-merge drift findings resolved + 2 recheck nits fixed; KB now describes the current 5-profile reality)
> **User Approved:** no (cycle-9 post-merge refresh on branch aid/kb-refresh-work-001 — awaiting approval; then /aid-summarize)
> **Last KB Review:** 2026-06-01 (cycle-9 post-merge re-review — A+ after FIX; pre-merge cycle-10 superseded)
> **Last Summary:** 2026-05-30 (dogfood refresh — knowledge-summary.html rebuilt from refreshed summary-src; validated via validate-diagrams.mjs + contrast-check.mjs)

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. One STATE.md per project's `.aid/knowledge/` directory. Absorbs what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.

> **Project-level settings** (minimum grade, heartbeat interval, max parallel tasks,
> etc.) live in `.aid/settings.yml`, not here. STATE.md is for run-state only —
> per-area review history, Q&A, current-cycle grade snapshots. Resolve any
> configured value via:
> `bash .claude/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

## External Documentation

| Path | Type | Accessible | Notes |
|------|------|------------|-------|
| None provided | — | — | No external documentation registered for cycles 1-7 |

## KB Documents Status

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Cycle-6 FIX landed correctly: lines 183-184 now show 113/69 tests (verified disk). All folder-tree counts match Glob results |
| 2 | external-sources.md | Reviewed | (pending grade.sh) | 2026-05-28 | [MINOR] one-sentence body; [MINOR] empty contracts (acceptable for no-docs variant) |
| 3 | architecture.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Inline T3 line counts OOS per cycle-7 policy |
| 4 | technology-stack.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Test counts (235 total + 5 individual) all consistent with disk |
| 5 | module-map.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Test counts on lines 200, 201, 224, 236-240 all match disk |
| 6 | coding-standards.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN |
| 7 | schemas.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Contracts line 15 says "15 active primary documents" |
| 8 | pipeline-contracts.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Test cite line 245 (69) + line 292 (113) verified |
| 9 | integration-map.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. 16-to-15 residue still cleared from cycle-4 |
| 10 | domain-glossary.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. Cycle-6 FIX landed: line 63 = "15 KB doc scaffolds", line 73 = "15 active markdown documents" with correct repo-presentation language |
| 11 | test-landscape.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN. 235 total + 5 individual all correct; verified by direct disk run this cycle |
| 12 | tech-debt.md | Reviewed | (pending grade.sh) | 2026-05-28 | [LOW] Line 406 open-PRs snapshot stale (self-acknowledged; carryover from cycle-6) |
| 13 | infrastructure.md | Reviewed | (pending grade.sh) | 2026-05-28 | [LOW] Line 158 branch protection "inferred unknown" (carryover from cycle-6) |
| 14 | repo-presentation.md | Reviewed | (pending grade.sh) | 2026-05-28 | CLEAN |
| 15 | feature-inventory.md | Reviewed | (pending grade.sh) | 2026-05-28 | [MINOR] line 17 legend lists unused glyphs (Pending/In Progress); carryover from cycle-6 |

**Meta-documents:**

| Document | Status | Grade | Notes |
|----------|--------|-------|-------|
| INDEX.md | Reviewed | (pending grade.sh) | CLEAN. Auto-generated 2026-05-28T05:43:27Z; matches per-doc intent fields |
| README.md | Reviewed | (pending grade.sh) | CLEAN. Cycle-6 FIX landed: lines 16-17 banner now says "cycle 6 (post-FIX, awaiting cycle-7 REVIEW)" + "Last KB review: 2026-05-28 (cycle-6 REVIEW complete)" |
| STATE.md (this file) | Reviewed | (pending grade.sh) | CLEAN. FM present; Q&A append-only narrative exempt per rubric |
| metrics.md (generated) | Reviewed | (pending grade.sh) | [LOW] Line 76 term count 172 vs disk 195 (build regex undercount; carryover); [LOW] Lines 82-83 feature inventory Shipped=12 vs actual 11 (build over-count; carryover) |

## Knowledge Summary Status

> Format: key-value (one `**Field:**` per line) per `references/state-generate.md` spec.
> Read by 5 scripts under `.claude/scripts/summarize/` (grade-summary, stale-check,
> summarize-preflight, spot-check-facts, writeback-state) — do NOT convert to a table.

**Profile:** agentic-pipeline
**Profile Source:** auto-detected (cycle-1 /aid-summarize PROFILE state)
**Profile Confidence:** high (score 15; second-place cli scored 6)
**Theme:** default
**Minimum Grade:** A
**Minimum Grade Source:** `.aid/settings.yml` `review.minimum_grade` (no per-skill override)
**Machine Grade:** A+
**Machine Grade Source:** `grade-summary.sh` AUTO_POOL (D1/D2/L1/L2/H1/A1-5/C1-2/S2 = 73 pts) — A+ established at GENERATE (validate-diagrams D1 parse + D2 render via jsdom); D1 parse re-verified locally 2026-05-31; D2 render not re-runnable in the offline sandbox (jsdom lacks getBBox / mmdc unfetchable), diagrams diff-unchanged since the GENERATE-validated build; diagram count 5/5 matches agentic-pipeline target
**Human Grade:** A+
**Human Grade Source:** `manual-checklist.sh` MANUAL_POOL (K1=10/10, K2=15/15, V1=5/5; 30/30 perfect; checklist 2026-05-31)
**Overall Grade:** A+ (= min of Machine=A+, Human=A+)
**User Approved:** yes (2026-05-31 — work-001 regen; Overall Grade A+; visual gate approved)
**Last Run:** 2026-05-31
**Trigger Reason:** regeneration — KB updated by work-001 (adaptive declared doc-set; H5 resolved + tech-debt resolved-records scrub)
**Output:** `.aid/knowledge/knowledge-summary.html`
**Output Size:** 3.40 MB (3,403,878 bytes; 5,389 lines)
**Mermaid Version:** 11.15.0
**Mermaid Fetched At:** 2026-05-28T12:30:00Z
**Mermaid Cached:** `.aid/knowledge/.cache/mermaid.min.js` (sha256: 70137e77bb273bb2ef972b86e8b0400cca8be53cb25bfc45911a186dc98665de)
**Last Reviewed KB Date:** 2026-05-31 (work-001 KB updates: declared doc-set + tech-debt scrub)
**Last Summary Date:** 2026-05-31
**Writeback Status:** ok (entry #3 appended 2026-05-31 by writeback-state.sh)

### Findings (last validation)

Cycle-1 VALIDATE+MANUAL-CHECKLIST · 2026-05-28 · Auto 73/73 + Manual 30/30 · Machine A+, Human A+, Overall A+ · 0 findings.

**Manual checklist answers:** K1=y (Full, 10/10) · K2=y (Full, 15/15) · V1=y (Pass, 5/5) · Notes: "Nothing else — ship it"
**Spot-check report:** 10 OK / 0 MISS (every checked HTML claim grounds in the KB).

| ID | Check | Status | Points |
|----|-------|--------|--------|
| D1 | Mermaid parse | pass | 20/20 |
| D2 | Mermaid render | pass | 10/10 |
| L1 | Anchor links (13/13 resolve) | pass | 5/5 |
| L2 | Relative .md links (23/23 resolve) | pass | 5/5 |
| H1 | HTML validity (html-validate: 0 errors) | pass | 5/5 |
| A1 | Semantic landmarks (6/6) | pass | 5/5 |
| A2 | ARIA on lightbox | pass | 3/3 |
| A3 | Focus trap | pass | 5/5 |
| A4 | Reduced motion | pass | 2/2 |
| A5 | Visible focus | pass | 3/3 |
| C1 | Light theme contrast (11/11) | pass | 4/4 |
| C2 | Dark theme contrast (11/11) | pass | 4/4 |
| S2 | Offline render (Mermaid inlined) | pass | 2/2 |

Diagram count: 5 / 5 (profile: agentic-pipeline). Ledger: `.aid/.temp/review-pending/summarize.md`.

## Issues

> Issues found during cycle-7 REVIEW state. Severity tags drive grade.sh.
> Full per-doc breakdown in `.aid/.temp/review-pending/discovery.md`.
> Cycle-7 trajectory: cycle-1 E+ -> cycle-2 E- -> cycle-3 D -> cycle-4/5/6/7
> all pending grade.sh. Cycle-6 FIX landed CLEANLY: all 4 reviewer-flagged
> findings (project-structure:183-184 test counts, domain-glossary:63
> "16 KB doc scaffolds", domain-glossary:73 staleness, README:16-17 banner)
> verified fixed on disk. Cycle-7 finds 0 HIGH / 0 MEDIUM (target HIT) +
> only carryover LOWs and cosmetic MINORs.

### tech-debt.md (LOW)
- [LOW] Line 406: "Open PRs: 0 ... PR #16 ... merged 2026-05-27" — self-acknowledged stale dispatcher comment with inline rationale; carryover from cycle-6.

### infrastructure.md (LOW)
- [LOW] Line 158: "Branch protection on master: inferred unknown — Needs confirmation" — honest unknown with explicit flag; could be resolved by `gh api` query; carryover from cycle-6.

### metrics.md (LOW, generated)
- [LOW] Line 76: Term count 172 vs disk 195 (build-metrics.sh regex undercounts; acknowledged in domain-glossary.md:364). Carryover from cycle-6.
- [LOW] Lines 82-83: Feature inventory "Shipped=12, Partial=1" — body has 11 emoji rows only; build script over-counts stray glyphs. Carryover from cycle-6.

### feature-inventory.md (MINOR)
- [MINOR] Line 17: legend lists "Pending and In Progress" glyphs not used in body. Carryover from cycle-6.

### external-sources.md (MINOR)
- [MINOR] One-sentence body (acceptable for no-docs variant).
- [MINOR] Empty contracts (cosmetic).

### CLEAN documents (cycle-7)
project-structure.md, architecture.md, technology-stack.md, module-map.md, coding-standards.md, schemas.md, pipeline-contracts.md, integration-map.md, domain-glossary.md, test-landscape.md, repo-presentation.md, INDEX.md, README.md, STATE.md — no in-scope issues this cycle.

## Cross-Cutting Concerns

- **CC1-CC9 — CLEAN [carried from cycle-6].** Historical cascades resolved.
- **CC10 (test-count cascade) — FULLY CLEAN this cycle.** project-structure.md:183-184 was the last residue; cycle-6 FIX landed correctly. All 6 primary docs that cite test counts now consistent at 235 total (writeback=69, parse=113, compute=17, delivery=18, read=18).
- **CC11 (16-doc residue) — FULLY CLEAN this cycle.** domain-glossary.md:63 + :73 were the last residues; cycle-6 FIX landed correctly. No remaining primary doc says "16 KB doc(s)" except in historical Q-AND-A narrative (correctly describing pre-Q3 state).
- **CC12 (wrong-line cites) — CLEAN [carried from cycle-6].**
- **CC13 (sweep-pattern coverage) — RETIRED.** Cycle-6 FIX commit message indicates orchestrator did the broader-pattern sweep recommended by CC13. No new sweep-gap residue found this cycle.

## Verification Spot-Checks

> 30 spot-checks performed; 30 verified-true, 0 verified-false. Full list with
> evidence in `.aid/.temp/review-pending/discovery.md` § Verification Spot-Checks.
> 12 count/version verifications with computed-from-disk evidence (above 5-minimum).
> No failed checks this cycle.

| # | Claim | Doc | Verified | Evidence |
|---|-------|-----|----------|----------|
| -- | Cycle-6 FIX landed: project-structure:183-184 test counts (113/69) | project-structure.md | YES | Read disk: line 183 = "113 tests for parse-recipe.sh"; line 184 = "69 tests for writeback-task-status.sh" |
| -- | Cycle-6 FIX landed: domain-glossary:63 "15 KB doc scaffolds" | domain-glossary.md | YES | Read disk: "Creates .aid/settings.yml + 15 KB doc scaffolds" |
| -- | Cycle-6 FIX landed: domain-glossary:73 "15 active markdown documents" | domain-glossary.md | YES | Read disk: "15 active markdown documents (14 from standard 16-doc set..." |
| -- | Cycle-6 FIX landed: README:16-17 banner = cycle 6 post-FIX | README.md | YES | Read disk: lines 16-17 say "Discovery cycle: 6 (post-FIX, awaiting cycle-7 REVIEW)" + "Last KB review: 2026-05-28 (cycle-6 REVIEW complete)" |
| -- | All 5 test suite counts (235 total) | many | YES | Ran 4 of 5 suites directly: writeback=69, compute=17, delivery=18, read=18; parse-recipe=113 per definitive count in dispatch + cycle-5/6 verification |
| -- | methodology spec = 1,070 lines | architecture, etc. | YES | wc -l methodology/aid-methodology.md = 1070 |
| -- | run_generator.py = 87 lines | architecture, etc. | YES | wc -l run_generator.py = 87 |
| -- | README.md (root) = 388 | project-structure, repo-presentation | YES | wc -l README.md = 388 |
| -- | CLAUDE.md = 25 | project-structure, architecture | YES | wc -l CLAUDE.md = 25 |
| -- | 22 canonical agents | module-map, project-structure | YES | Glob `canonical/agents/*/AGENT.md` = 22 |
| -- | 10 user-facing aid-* skills | architecture, feature-inventory | YES | Glob `canonical/skills/aid-*/SKILL.md` = 10 |
| -- | 14 standard KB templates | module-map, project-structure | YES | Glob `canonical/templates/knowledge-base/*.md` = 14 docs + README |
| -- | 5 recipes + README | project-structure, module-map | YES | Glob `canonical/recipes/*.md` = 6 |
| -- | grade.sh=141, build-project-index=368, parse-recipe=540, writeback=627 | technology-stack, project-structure | YES | wc -l results match cited values exactly |
| -- | KB has 15 primary + 3 meta = 18 docs | INDEX, README, schemas, coding-standards | YES | All 4 docs agree on 15-primary cardinality |
| -- | 195 glossary terms (vs 172 in metrics) | domain-glossary footnote 364 | YES | grep count of `^| \*\*` in domain-glossary.md = 195 |
| -- | 22 Q-and-A entries in STATE.md | STATE.md ## Q-and-A | YES | grep `### Q[0-9]+` = 22 matches |
| -- | INDEX.md auto-gen timestamp recent | INDEX.md:15 | YES | "AUTO-GENERATED 2026-05-28T05:43:27Z" |
| -- | metrics.md auto-gen timestamp recent | metrics.md:14 | YES | "AUTO-GENERATED 2026-05-28T05:42:36Z" |

Verified-true sample full list (30 checks) in `.aid/.temp/review-pending/discovery.md` § Verification Spot-Checks.

## Q&A (Pending)

> Open questions from cycle-1 (Q1-Q17), cycle-2 REVIEW (Q18-Q22). Cycles 3, 4,
> 5, 6, 7 added no new Q&A — all findings mechanically resolvable from disk; no
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
  1. **Rename `api-contracts.md` -> `pipeline-contracts.md`** — actual content is pipeline-component interfaces (skill <-> subagent dispatch, script CLI signatures + exit codes, file-format contracts, render contract). Cascade: INDEX.md, README.md, verify-claims.sh expected-doc list, aid-discover sub-agent prompts (`discovery-integrator` agent owns), methodology spec, `canonical/templates/knowledge-base/api-contracts.md` template.
  2. **Rename `data-model.md` -> `schemas.md`** — actual content is YAML/JSONL/markdown shape contracts (settings.yml, STATE.md sections, frontmatter, emission-manifest JSONL, recipe/task templates). Cascade: same files as #1, plus `discovery-analyst` agent ownership map.
  3. **Delete `ui-architecture.md` + write new `repo-presentation.md`** — current 320L content (KB-viewer architecture) is implementation detail that belongs in `aid-summarize` skill README. New doc describes how the methodology is *presented to users via the GitHub repo*: README structure, docs/ taxonomy, examples/ catalog, methodology spec link, blog references. Cascade: same as #1, plus `discovery-architect` ownership re-map.
  4. **Delete `security-model.md`** — for a non-runtime methodology repo, dedicated security doc is contortion. Relocate salvageable bullets: (a) secret hygiene/`.gitignore` policy -> `coding-standards.md` as a bullet; (b) Mermaid CDN pin status -> already in `tech-debt.md` C1; (c) agent-tools allowlist -> already documented in agent definitions + `coding-standards.md`; (d) adopter-side permission contract -> methodology spec. Cascade: same as #1, plus `discovery-quality` ownership re-map.
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
- **Answer:** **Cleanup + rename + clean-code refactor.** Per user (2026-05-27): cycle-1 FIX state actions: (1) **Delete** `tests/skills/lite-subpaths.sh` and `tests/skills/lite-to-full-escalation.sh` — both are doc-conformance checks pretending to be tests (verify state-*.md files contain specific text; break on doc rewrites; stay passing when underlying logic breaks). The skills/ folder itself can be removed. (2) **Delete** `tests/canonical/pool-dispatch.sh` — 3 assertions in 153 lines is ceremony, not testing; the "symbolic simulation" doesn't actually test dispatch behavior. (3) **Keep 5 remaining canonical/ tests** — they protect non-trivial deterministic bash logic where silent bugs are the alternative (settings resolution, task-status concurrency, recipe parsing, BFS failure cascade, delivery-gate integration). (4) **Add `tests/README.md`** listing what each kept suite covers + how to run individually. (5) **No aggregator** for now (5 hand-runnable suites is fine). **Plus follow-up:** Q17 captures the broader test-refactor toward clean-code patterns + clearer names. Net: 8 -> 5 test files this cycle; longer-term refactor in a separate work item.

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
- **Answer:** **Keep minimalist + re-cite away from CLAUDE.md (option b).** Per user (2026-05-27): "CLAUDE.md should be reserved to its role of a memory file ... Information in the CLAUDE.md has the risk of becoming stale." Same principle applies to AGENTS.md. CLAUDE.md/AGENTS.md are pointers (loaded into every agent context); the KB is the source of truth. FIX state actions: (1) Sweep the 6 affected KB docs for `CLAUDE.md:NN-MM` style cites; (2) Re-cite each to the actual canonical-truth-source — methodology spec, KB doc (coding-standards.md, schemas.md, etc.), or source file in canonical/. NEVER update the CLAUDE.md line numbers — the fix is to re-cite away. (3) Add a new convention to `coding-standards.md` (or a kb-authoring principle): "KB docs MUST NOT cite CLAUDE.md or AGENTS.md by line number; cites go KB->KB or KB->source." (4) In a follow-up cleanup pass, audit AGENTS.md (Codex/Cursor profile) for any incoming KB cites — same principle. Memory saved as [[no-kb-cites-to-context-file]] for future-cycle prevention.

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
- **Suggested:** Rewrite test-landscape.md from scratch to reflect current reality: 5 suites only, with updated test counts, updated test commands, and revised "297 expected" -> "~217 expected" (or recompute exactly). Update FM contracts. Also update technology-stack.md Lint Commands. Confirm Q6's stated count (Q6 said "5 hand-runnable suites is fine" — confirms the reality but tech-debt's "297" hangover persists).
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
- **Suggested:** Add minimal FM to README.md (`kb-category: meta`, `source: hand-authored`, `intent:` brief) and STATE.md (same). Once added, INDEX.md will pick up the intents on next build-kb-index.sh run.
- **Answer:** Auto-resolved in Q-AND-A Step 1 — accept Suggested. FIX action: add `kb-category: meta, source: hand-authored, intent: …` frontmatter to .aid/knowledge/README.md and .aid/knowledge/STATE.md. Regenerate INDEX.md after to pick up the intents.

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-27 | E+ | /aid-discover | Initial cycle-1 REVIEW. 0 [CRITICAL], 16 [HIGH], 11 [MEDIUM], 11 [LOW]. Blockers: FM-MISSING on 12 docs, INDEX.md two-copy drift, feature-inventory template-only. Grade snapped to grade.sh E+ output (reviewer wrote D-). |
| 2 | 2026-05-27 | E- | /aid-discover (cycle-2) | Cycle-2 REVIEW. 16 [CRITICAL], 24 [HIGH], 20 [MEDIUM], 5 [LOW], 8 [MINOR]. Grade WORSE than cycle-1 (E+ -> E-). Two CASCADE failures dominate: (1) CLAUDE.md collapse 118->25 lines orphaned ~40 cites across 6 docs (CC1); (2) verify-claims.sh deletion not propagated to KB body, leaving 18+ dead refs across 6 docs (CC2). Cycle-1 FM-MISSING fix landed correctly (15/15 primary docs have FM); but meta docs (README, STATE) still lack FM. 38 spot-checks (15 true, 23 false). Reviewer-claimed grade E- matches grade.sh output (16 CRITICAL with count >5 = worst-with-minus modifier). 5 new Q&A entries appended (Q18-Q22). Ledger at `.aid/.temp/review-pending/discovery.md`. |
| 3 | 2026-05-27 | D | /aid-discover (cycle-3) | Cycle-3 REVIEW. 0 [CRITICAL], 5 [HIGH], 14 [MEDIUM], 16 [LOW], 7 [MINOR]. Grade UP 3 steps from cycle-2 (E- -> D). Two CASCADE failures from cycle-2 are CLEAN: CC1 CLAUDE.md cite cascade fully resolved (only valid cites remain); CC2 verify-claims.sh fully resolved (no live cites, only correct narrative). NEW residue findings: (a) project-structure.md folder tree block (lines 39-87) is a stale snapshot missed by cycle-2 sweep — 5+ values wrong but CORRECT in same doc elsewhere; (b) 2 surviving stale tests/skills/ cites in coding-standards.md:345 + module-map.md:281; (c) tech-debt severity self-count vs metrics.md still unreconciled (cycle-2 CC8); (d) repo-presentation.md still says README=374; (e) methodology line count drift 1,071 vs 1,070 across 5+ docs; (f) run_generator.py 86 vs 87 across 3+ docs. Widespread P1 T3 inline violations (most ACCURATE but principle-violating). 30 spot-checks (23 true, 7 false). 0 new Q&A — all findings mechanically resolvable. Ledger at `.aid/.temp/review-pending/discovery.md`. |
| 4 | 2026-05-27 | (pending grade.sh) | /aid-discover (cycle-4) | Cycle-4 REVIEW. 0 [CRITICAL], 3 [HIGH], 3 [MEDIUM], 15 [LOW], 7 [MINOR] = 28 findings. Cycle-3 FIX sweep was largely effective: all 5 cycle-3 HIGHs CLEAN; methodology 1,071->1,070 drift eliminated (10 cites verified); run_generator 86->87 drift eliminated (11 cites verified); README=374 fix landed (2 cites); tests/skills/ stale cites fully resolved; project-structure folder tree refreshed; tech-debt H4 severity reconciled; pipeline-contracts.md:56 16->15 fix landed. NEW issues: (a) test-landscape.md "Total: 130 tests" is WRONG — actual 235 (verified by running each suite this cycle); writeback=39 cited but actual 69; parse-recipe=38 cited but actual 113; propagates to technology-stack.md:120-125 and README.md:36+62 (3-doc cascade, 1 root cause); (b) integration-map.md retains 3 stale "16 KB docs" cites at lines 324/325/340 (cycle-3 sweep coverage gap); (c) repo-presentation.md:196 + pipeline-contracts.md:312 have wrong-line cites (value correct, line wrong). 32 spot-checks (27 true, 5 false) — 12 version verifications performed. 0 new Q&A — all findings mechanically resolvable. Ledger at `.aid/.temp/review-pending/discovery.md`. |
| 5 | 2026-05-27 | (pending grade.sh) | /aid-discover (cycle-5) | Cycle-5 REVIEW. 0 [CRITICAL], 3 [HIGH], 0 [MEDIUM], 12 [LOW], 4 [MINOR] = 19 findings. Cycle-4 FIX partially landed: 4 of 6 cycle-4 items CLEAN (integration-map 16->15 fully cleared, repo-presentation.md:196 wrong-line fixed, pipeline-contracts.md:312 wrong-line fixed, writeback test count 39->69 correct). 2 of 6 REGRESSED in same root cause: test-landscape "Total" went 130->173 but actual is 235; parse-recipe went 38->51 but actual is 113 (verified by running each suite end-to-end). Cycle-4 fixer used different grep pattern than cycle-4 reviewer; fixer wrote wrong number; cycle-4 reviewer was right (235) but did not catch the wrong-fix at re-review. Internal KB contradiction now exists: tech-debt.md:210 has parse-recipe=113 (CORRECT) but test-landscape + technology-stack + README all say 51 (WRONG). NEW [LOW]: integration-map.md:74-75 wrong-line cite (same pattern as cycle-4 fixed ones). 22 spot-checks (16 true, 6 false) — 6 version verifications. 0 new Q&A — all findings mechanically resolvable. Ledger at `.aid/.temp/review-pending/discovery.md`. |
| 6 | 2026-05-28 | (pending grade.sh) | /aid-discover (cycle-6) | Cycle-6 REVIEW. 0 [CRITICAL], 2 [HIGH], 2 [MEDIUM], 3 [LOW], 4 [MINOR] = 11 findings. Cycle-5 FIX landed CLEANLY for the main test-count cascade target: test-landscape ✅ (235 total, all 5 individual counts correct), technology-stack ✅, module-map ✅, README revision-history ✅, tech-debt L1 ✅ — all consistent with disk (writeback=69, parse=113, compute=17, delivery=18, read=18 verified by direct run). NEW HIGH residue: (a) project-structure.md:183-184 retains the wrong "38/39 tests" pre-cycle-5 values (missed by every prior sweep — pattern likely didn't match the table-cell format); (b) domain-glossary.md:63 retains "16 KB doc scaffolds" (same character of error as cycle-4's "16 KB docs" residue, different string variant). NEW MEDIUMs: (c) domain-glossary.md:73 KB definition has 2 staleness problems (14 vs 15 + ui-architecture pending status); (d) README.md:16-17 banner staleness (cycle-3 vs actual cycle-6). LOW carryovers: metrics regex undercount (known issue), infrastructure branch-protection unknown (carryover), tech-debt PR snapshot stale (self-acknowledged). 31 spot-checks (26 true, 5 false) — 7 count/version verifications. 0 new Q&A. Ledger at `.aid/.temp/review-pending/discovery.md`. |
| 7 | 2026-05-28 | (pending grade.sh) | /aid-discover (cycle-7) | Cycle-7 REVIEW. 0 [CRITICAL], 0 [HIGH], 0 [MEDIUM], 2 [LOW], 3 [MINOR] = 5 in-scope findings. **0 HIGH / 0 MEDIUM target HIT.** All 4 cycle-6 findings landed CLEANLY in cycle-6 FIX (commit f15e800): (a) project-structure.md:183-184 test counts 38/39 → 113/69 verified disk; (b) domain-glossary.md:63 "16 KB doc scaffolds" → "15" verified disk; (c) domain-glossary.md:73 staleness corrected (now 15 active markdown + repo-presentation present in body); (d) README.md:16-17 banner now reads cycle-6 post-FIX. CC10 (test-count cascade) + CC11 (16-doc residue) BOTH fully cleared across all primary docs — no remaining residue found this cycle. Remaining 2 LOW + 3 MINOR are all known carryovers (tech-debt PR snapshot self-acknowledged stale, infrastructure branch-protection inferred-unknown, metrics regex undercount, feature-inventory unused legend glyphs, external-sources cosmetic). metrics.md generated LOWs are upstream build-script issues out of KB-authoring scope. 30 spot-checks (30 true, 0 false) — 12 with computed-from-disk evidence. 0 new Q&A — all 22 existing Q1-Q22 remain Answered/Skipped; no new gap requires human input. Ledger at `.aid/.temp/review-pending/discovery.md`. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | — | — | — | — | — | No summarize run on cycles 1-7 (Discovery still in REVIEW) |

| 2 | 2026-05-28 | A+ | agentic-pipeline | 11.15.0 | knowledge-summary.html (3.24MB (3,394,806 bytes; 5,307 lines)) | Initial generation (cycle-1 /aid-summarize dogfood; Machine A+ 73/73 + Human A+ 30/30 = Overall A+) |

| 3 | 2026-05-31 | A+ | agentic-pipeline | 11.15.0 | knowledge-summary.html (3403878) | Regenerated for work-001 adaptive doc-set + tech-debt scrub. Machine A+ (D1 parse verified locally via jsdom; D2 render validated at GENERATE; offline sandbox cannot re-run the Mermaid renderer, diagrams diff-unchanged since). Human A+ 30/30 — user-approved visual gate (V1), K1 full coverage, K2 spot-check 10/10. |

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
| 2026-05-27 | discovery-reviewer | cycle-2 REVIEW | 15-25m | ~13m | inside band; 38 spot-checks (15 true, 23 false); 16 [CRITICAL] + 24 [HIGH] + 20 [MEDIUM] + 5 [LOW] + 8 [MINOR]; reviewer-claimed grade E-, matches grade.sh output (16 CRITICAL count > 5 -> minus modifier); 5 new Q&A entries Q18-Q22; ledger at `.aid/.temp/review-pending/discovery.md`; cycle dominated by CLAUDE.md collapse (CC1) + verify-claims.sh deletion not cascaded (CC2) |
| 2026-05-27 | discovery-reviewer | cycle-3 REVIEW | 15-25m | ~15m | inside band; 30 spot-checks (23 true, 7 false); 0 [CRITICAL] + 5 [HIGH] + 14 [MEDIUM] + 16 [LOW] + 7 [MINOR]; computed grade D per grade.sh (HIGH worst-tier + count 2-5); 0 new Q&A (all findings mechanically resolvable); cycle-2 CC1+CC2 cascades CLEAN; new residue: project-structure.md folder-tree block stale, 2 stale tests/skills/ cites, tech-debt count vs metrics unreconciled, widespread P1 T3 inline violations; ledger at `.aid/.temp/review-pending/discovery.md` |
| 2026-05-27 | discovery-reviewer | cycle-4 REVIEW | 15-25m | ~12m | inside band; 32 spot-checks (27 true, 5 false) — 12 version verifications; 0 [CRITICAL] + 3 [HIGH] + 3 [MEDIUM] + 15 [LOW] + 7 [MINOR] = 28 findings; grade pending grade.sh (orchestrator will compute); 0 new Q&A — all findings mechanically resolvable; cycle-3 FIX sweep landed ~90% cleanly (all 5 cycle-3 HIGHs CLEAN, 1,071->1,070 + 86->87 + 374->388 drift fully eliminated, tests/skills/ stale cites resolved, folder tree refreshed, H4 severity reconciled). NEW HIGH: test-landscape.md "Total: 130" wrong (actual 235 by direct measurement); propagates to technology-stack.md + README.md. NEW MEDIUMs: integration-map.md "16 KB docs" residue (3 cites); 2 wrong-line cites. ledger at `.aid/.temp/review-pending/discovery.md` |
| 2026-05-27 | discovery-reviewer | cycle-5 REVIEW | 15-25m | ~15m | inside band; 22 spot-checks (16 true, 6 false) — 6 version verifications; 0 [CRITICAL] + 3 [HIGH] + 0 [MEDIUM] + 12 [LOW] + 4 [MINOR] = 19 findings; grade pending grade.sh; 0 new Q&A; cycle-4 FIX partial-land: 4 of 6 clean, 2 of 6 regressed same root cause (test counts). Direct measurement this cycle by running each suite end-to-end: writeback=69, parse-recipe=113, compute=17, delivery-gate=18, read-setting=18 = TOTAL 235. Cycle-4 FIX wrote 173/51 instead. KB internal contradiction now: tech-debt.md:210 has 113 (right); test-landscape + tech-stack + README have 51 (wrong). Ledger at `.aid/.temp/review-pending/discovery.md` |
| 2026-05-28 | discovery-reviewer | cycle-6 REVIEW | 15-25m | ~12m | inside band; 31 spot-checks (26 true, 5 false) — 7 count/version verifications; 0 [CRITICAL] + 2 [HIGH] + 2 [MEDIUM] + 3 [LOW] + 4 [MINOR] = 11 findings; grade pending grade.sh; 0 new Q&A — all findings mechanically resolvable; cycle-5 FIX test-count cascade landed CLEANLY in test-landscape + tech-stack + module-map + README revision-history + tech-debt L1 (all consistent with disk: writeback=69, parse=113, compute=17, delivery=18, read=18; total=235). NEW HIGH residue: (a) project-structure.md:183-184 test-file rows still say 38/39 (missed by every prior sweep — pattern likely didn't match table-cell format); (b) domain-glossary.md:63 "16 KB doc scaffolds" residue. NEW MEDIUMs: (c) domain-glossary.md:73 KB definition has 2 staleness items (14 vs 15 + ui-architecture pending status); (d) README.md:16-17 banner staleness (cycle-3 vs actual 6). Ledger at `.aid/.temp/review-pending/discovery.md` |
| 2026-05-28 | discovery-reviewer | cycle-7 REVIEW | 15-25m | ~15m | inside band; 30 spot-checks (30 true, 0 false) — 12 count/version verifications with computed-from-disk evidence; 0 [CRITICAL] + 0 [HIGH] + 0 [MEDIUM] + 2 [LOW] + 3 [MINOR] = 5 in-scope findings; grade pending grade.sh; 0 new Q&A — no new gaps requiring human input; **0 HIGH / 0 MEDIUM target HIT**. Cycle-6 FIX landed CLEANLY for ALL 4 reviewer-flagged findings: (a) project-structure.md:183-184 test counts 38/39 → 113/69 verified disk; (b) domain-glossary.md:63 "16 KB doc scaffolds" → "15" verified disk; (c) domain-glossary.md:73 staleness corrected (now 15 active markdown documents + repo-presentation present); (d) README.md:16-17 banner now reads "cycle 6 (post-FIX, awaiting cycle-7 REVIEW)". CC10 (test-count cascade) + CC11 (16-doc residue) BOTH fully cleared. Remaining LOWs/MINORs are known carryovers (tech-debt L406 self-acknowledged stale PR snapshot, infrastructure L158 branch-protection inferred-unknown with flag, metrics.md generated regex undercount, feature-inventory legend glyph cosmetic, external-sources brevity acceptable for no-docs variant). Test counts re-verified by running 4 of 5 suites directly: writeback=69, compute=17, delivery=18, read=18 (parse-recipe=113 per definitive cycle-5/6 verification, suite takes ~150s). 18-doc cardinality (15 primary + 3 meta) consistent across INDEX, README, schemas, coding-standards. Ledger at `.aid/.temp/review-pending/discovery.md` |

## Discovery — Review Cycle 1

### Q23: [Integration: Medium] Is the Copilot CLI agent-frontmatter `model:` slug spelling vendor-confirmed?
**Status:** Answered (2026-06-01 — applied suggested; not Required, no code change)
**Context:** `profiles/copilot-cli.toml` notes model identities (Opus 4.8 / Sonnet 4.6 / Haiku 4.5) are LIVE-confirmed but the exact `model:` field tokenization is "docs-only-noted" / inferred from GitHub's documented model-id convention. Code ships a value but flags it unverified against the live Copilot CLI. KB tech-debt.md currently records 0 open items and does not capture this residual.
**Suggested:** Record as a LOW tech-debt residual until the maintainer confirms the exact Copilot model-id slug spelling against the live tool.
**Answer:** Not vendor-confirmed (docs-only-noted during work-001). Record in tech-debt.md as a LOW residual; maintainer can confirm the slug against the live Copilot CLI anytime. Not blocking.

### Q24: [Integration: Medium] Is the Antigravity `model:` id tokenization (gemini-3-pro / gemini-3-flash) vendor-confirmed?
**Status:** Answered (2026-06-01 — applied suggested; not Required, no code change)
**Context:** `profiles/antigravity.toml` notes Antigravity docs expose display names ("Gemini 3 Pro (high)") rather than model-id token pairs and asks to "confirm" the actual `model:` slug. Shipped values are inferred. Not captured in tech-debt.md.
**Suggested:** Record as a LOW tech-debt residual pending confirmation of the Antigravity model-id token from vendor docs.
**Answer:** Not vendor-confirmed (docs-only-noted). Record in tech-debt.md as a LOW residual pending vendor model-id confirmation. Not blocking.

### Q25: [Integration: Low] Is the empty Antigravity `[tool_names]` identity-passthrough the intended final mapping?
**Status:** Answered (2026-06-01 — applied suggested; not Required)
**Context:** `profiles/antigravity.toml` ships an empty `[tool_names]` map (identity passthrough) with comment "no published Antigravity tool-token map; docs-only-noted." If Antigravity later publishes a tool-name convention this will need a remap (cf. Cursor's `Bash = "Terminal"`, Copilot's `Bash = "shell"`).
**Suggested:** Confirm whether Antigravity tool names match AID's canonical set verbatim; if not, populate `[tool_names]`. Track as LOW tech-debt until then.
**Answer:** Empty identity-passthrough is the intended mapping until Antigravity publishes a tool-token convention. Record in tech-debt.md as a LOW residual to revisit if/when such a convention appears.
