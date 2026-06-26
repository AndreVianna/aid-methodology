# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** Approved
> **Current Grade:** A+
> **User Approved:** yes
> **Last KB Review:** 2026-06-25
> **Last Summary:** 2026-06-25

This is the single state file for the **Discovery area** — persistent project knowledge: the Knowledge Base + the visual summary. One STATE.md per project's `.aid/knowledge/` directory. Absorbs what used to be `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`.

> **Project-level settings** (minimum grade, heartbeat interval, max parallel tasks,
> etc.) live in `.aid/settings.yml`, not here. STATE.md is for run-state only —
> per-area review history, Q&A, current-cycle grade snapshots. Resolve any
> configured value via:
> `bash .claude/aid/scripts/config/read-setting.sh --skill <name> --key <key> --default <fallback>`

## Discovery Domain

- **Domain:** hybrid:methodology-tooling+software-cli
- **Measured signals:** languages=Markdown(1823)/Shell(327)/Python(56)/JS(40)/HTML/YAML/PowerShell/TS; notable-files=packages/npm/package.json, packages/pypi/pyproject.toml, install.sh, .github/workflows/{test,release,installer-tests,docs}.yml; dirs=bin/, lib/, canonical/, profiles/, dashboard/, docs/, site/, examples/, tests/; concepts=aid-* skills, agent definitions, templates, canonical→5-profile render trees, CLI installer
- **Proposed:** hybrid:methodology-tooling+software-cli (dominant skill/agent/template/prompt mass = methodology-tooling; substantial installer = bin/+lib/+npm/pypi packaging+install.sh = software-cli)
- **Decision rationale:** measured -> proposed hybrid:methodology-tooling+software-cli -> confirmed
- **Confirmed:** yes
- **Re-classified:** 2026-06-25 (run 1)

## Discovery Triage

- **Path:** brownfield-large
- **Measured:** source-files=455, source-LOC=217449, dirs=24, concepts=375
- **Proposed:** brownfield-large (tripped: large_min_source_loc, large_min_concepts)
- **Decision rationale:** measured -> proposed brownfield-large -> confirmed
- **Re-triaged:** 2026-06-25 (run 1)

## External Documentation

| Path | Type | Accessible | Notes |
|------|------|------------|-------|
| {/path/to/docs or "None provided"} | {file/directory} | {✅/❌} | {brief note} |

## KB Documents Status

> One row per document in the project's **confirmed doc-set** (`discovery.doc_set` in
> `.aid/settings.yml`, resolved at aid-discover Step 0d from the project's domain). The set is
> **domain-driven and varies per project** — do NOT hardcode a fixed doc list here. This table
> is seeded empty and populated by aid-discover during GENERATE (Step 6) from the resolved
> doc-set; when no doc-set is declared yet, the default 15-doc seed applies.

| # | Document | Status | Grade | Last Reviewed | Notes |
|---|----------|--------|-------|---------------|-------|
| 1 | project-structure.md | Generated | A+ | 2026-06-25 | C1 · scout |
| 2 | external-sources.md | Generated | A+ | 2026-06-25 | meta · scout (none provided) |
| 3 | architecture.md | Generated | A+ | 2026-06-25 | C1 · architecture |
| 4 | technology-stack.md | Generated | A+ | 2026-06-25 | C0 · architecture |
| 5 | module-map.md | Generated | A+ | 2026-06-25 | C2 · analyst |
| 6 | coding-standards.md | Generated | A+ | 2026-06-25 | C3 · analyst |
| 7 | authoring-conventions.md | Generated | A+ | 2026-06-25 | C3 · analyst (custom) |
| 8 | artifact-schemas.md | Generated | A+ | 2026-06-25 | C5 · analyst (custom) |
| 9 | pipeline-contracts.md | Generated | A+ | 2026-06-25 | C2 · integrator |
| 10 | integration-map.md | Generated | A+ | 2026-06-25 | C2 · integrator |
| 11 | domain-glossary.md | Generated | A+ | 2026-06-25 | C4 · integrator (29 grounded) |
| 12 | test-landscape.md | Generated | A+ | 2026-06-25 | C6 · quality |
| 13 | quality-gates.md | Generated | A+ | 2026-06-25 | C6 · quality (custom) |
| 14 | tech-debt.md | Generated | A+ | 2026-06-25 | C7 · quality (9 items) |
| 15 | infrastructure.md | Generated | A+ | 2026-06-25 | C8 · quality |
| 16 | release-tracking.md | Restored | — | 2026-06-25 | C8 · skill-self (hand-authored release ledger; content preserved from prior KB) |
| 17 | capability-inventory.md | Generated | A+ | 2026-06-25 | C9 · skill-self |
| 18 | decisions.md | Generated | A+ | 2026-06-25 | D · architecture (18 decisions) |
| 19 | README.md | Generated | A+ | 2026-06-25 | meta · skill-self |

## Knowledge Summary Status

| Field | Value |
|-------|-------|
| Profile | hybrid:methodology-tooling+software-cli |
| Profile Source | auto-detected (aid-discover) |
| Profile Confidence | high |
| Theme | default |
| Machine Grade | A+ (grade-summary AUTO_POOL 68/68) |
| Human Grade | A+ (manual-checklist 30/30: K1 10 / K2 15 / V1 5) |
| User Approved | yes (2026-06-25) |
| Last Run | 2026-06-25 |
| Output | .aid/dashboard/kb.html (177780 bytes, 3856 lines, 20 sections) |
| Mermaid Version | — (retired in D-012; pre-rendered inline SVG only) |
| Mermaid Cached | — |

**Doc-Set Source:** .aid/settings.yml discovery.doc_set
**Doc-Set Count:** 18 of 18
**Domain:** hybrid:methodology-tooling+software-cli
**Domain Source:** .aid/knowledge/STATE.md ## Discovery Domain
**Overall Grade:** A+ (= min of Machine A+, Human A+)
**Writeback Status:** ok
**Minimum Grade:** A
**Visual-Gate Note:** validate-visuals.mjs SKIPPED (Playwright not installed in the summarize package); V1 visual gate performed by the agent via the Playwright MCP in a real headless browser — both themes legible, 4 inline-SVG diagrams render correctly, theme toggle + lightbox (open/Esc-close) verified, expanded lightbox view legible. Only console message is a benign favicon.ico 404.

### Findings (last validation)
- Machine (AUTO_POOL): 68/68 — COV 15/15, L1/L2, H1, A1-A5, C1/C2 (22/22 contrast both themes), S2 offline, NM no-Mermaid-engine. 0 findings.
- Human (MANUAL_POOL): 30/30 — K1 completeness (all 18 doc-set docs as 20 sections), K2 facts grounded (spot-check MISS all false positives), V1 visual gate PASS (Playwright-validated).

## Q&A (Pending)

> Open questions about KB facts, raised by any skill, awaiting human input or downstream resolution. Each entry: ID, category, impact, suggested answer (if inferrable), status.

### Q1

- **Category:** Inventory / terminology
- **Impact:** Medium
- **Status:** Answered
- **Context:** `canonical/skills/` contains 13 skill directories (aid-config, aid-deploy, aid-detail, aid-discover, aid-execute, aid-housekeep, aid-interview, aid-monitor, aid-plan, aid-query-kb, aid-specify, aid-summarize, aid-update-kb). `README.md` uses both "12-skill pipeline" (header) and "13 skills · 5 groups" (diagram caption); `docs/repository-structure.md` says "12 skill definitions". The counts disagree across sources.
- **Suggested:** 13 skill directories exist; "12-skill pipeline" likely counts only pipeline-positioned skills and excludes one off-pipeline/setup skill. Confirm the canonical phrasing so KB docs use one consistent count.
- **Answer:** USER DECISION: state "13 skills" consistently (the disk fact, matches canonical/skills/). README's "12-skill pipeline" is a source-doc inconsistency, out of discovery scope. FIX: ensure all KB docs use 13.
- **Applied to:** capability-inventory.md, architecture.md, module-map.md, project-structure.md (verify "13 skills" consistency in FIX)

### Q2

- **Category:** Documentation drift
- **Impact:** Medium
- **Status:** Answered
- **Context:** `docs/repository-structure.md` states recipes live at `canonical/recipes/` and number "51". Reality: `canonical/aid/recipes/` (note the `aid/` segment), 52 `.md` files. Same doc says "12 skill definitions" (see Q1).
- **Suggested:** The contributor doc is stale vs the current `canonical/aid/` layout; the KB documents the live reality. Confirm whether `docs/repository-structure.md` should be corrected (Tech-Writer task, out of scope for discovery).
- **Answer:** CONFIRMED from source: live reality is `canonical/aid/recipes/` with 52 `.md` files; the KB documents this. `docs/repository-structure.md` is stale SOURCE documentation; correcting it is a tech-writer task out of discovery scope. The drift is recorded in tech-debt.md (M3 stale-counts item). No KB change needed.
- **Applied to:** tech-debt.md (drift recorded); no KB correction needed (KB already correct)

### Q3

- **Category:** Repository hygiene
- **Impact:** Low
- **Status:** Answered
- **Context:** The repo root holds many loose image files (`kb-baseline-top.png`, `kb-dark.png`, `kb-lightbox.png`, `kb-mobile.png`, `kb-pipeline.png`, `kb-top-light.png`, and a `p3-*.png` series). They are not referenced as product assets and resemble scratch artifacts from summary/dashboard visual-validation work.
- **Suggested:** Working/scratch screenshots left at root, not intentional committed assets. Confirm whether to ignore, move, or remove them (housekeeping task, out of scope for discovery).
- **Answer:** USER DECISION: intentional committed assets — leave them; no cleanup. FIX: remove the tech-debt.md "loose PNGs" debt item (L5), since the user confirms they are intentional.
- **Applied to:** tech-debt.md (remove the loose-PNGs debt item in FIX)

### Q4

- **Category:** Documentation drift
- **Impact:** Low
- **Status:** Answered
- **Context:** `docs/aid-methodology.md` ("## 7. Artifacts Reference") describes the flat task layout `.aid/{work}/tasks/task-NNN.md`. The live skills + `canonical/aid/templates/work-state-template.md` use the nested shape `.aid/{work}/delivery-NNN/tasks/task-NNN/SPEC.md` (+ sibling `STATE.md`), confirmed by the on-disk `.aid/work-001-kb-skills-improvement/` tree. The two representations disagree.
- **Suggested:** Likely a prose-simplification lag in the user-facing methodology doc; the template + on-disk state agree, and pipeline-contracts.md documents the live nested shape as authoritative. Confirm whether `docs/aid-methodology.md` should be updated (Tech-Writer task, out of scope for discovery).
- **Answer:** CONFIRMED from source: the live skills, `canonical/aid/templates/work-state-template.md`, and the on-disk `.aid/work-001-*` tree all use the nested `delivery-NNN/tasks/task-NNN/` shape; pipeline-contracts.md documents it as authoritative. `docs/aid-methodology.md`'s flat shape is stale SOURCE documentation; updating it is a tech-writer task out of discovery scope. No KB change needed.
- **Applied to:** pipeline-contracts.md (documents live shape); no KB correction needed

### Q5

- **Category:** Documentation drift
- **Impact:** Low
- **Status:** Answered
- **Context:** `canonical/EMISSION-MANIFEST.md` ("Filename and Location", "Asset Kinds") enumerates only `claude-code`, `codex`, `cursor`. The live generator (`generate-profile/scripts/run_generator.py`) globs all `profiles/*.toml` — five profiles (the spec predates `copilot-cli` and `antigravity`). Five emission manifests are produced, not three.
- **Suggested:** The design spec is stale vs the five-profile reality; the KB documents the live reality. Confirm whether `canonical/EMISSION-MANIFEST.md` should be refreshed (Tech-Writer task, out of scope for discovery).
- **Answer:** CONFIRMED from source: the generator globs all `profiles/*.toml` (5 profiles) and emits 5 manifests; the KB documents 5 (architecture.md, infrastructure.md, capability-inventory.md). `canonical/EMISSION-MANIFEST.md` enumerating only 3 is a stale SOURCE spec; refreshing it is a tech-writer task out of discovery scope. No KB change needed.
- **Applied to:** architecture.md/infrastructure.md (document 5 profiles); no KB correction needed

### Q6

- **Category:** Features
- **Impact:** Required
- **Status:** Answered
- **Context:** Discovery must confirm the project's capability/feature set is captured correctly. `capability-inventory.md` (C9) lists AID's capabilities by name (pipeline skills, on-demand skills, CLI, distribution) rather than asserting a single skill count (see Q1).
- **Suggested:** Confirm that `capability-inventory.md` correctly and completely captures what AID does for its users, or list any capability that is missing, miscategorized, or wrongly described.
- **Answer:** USER CONFIRMED: the capability set is complete and correct (13 skills = 9 pipeline + 4 on-demand, CLI installer, 5-profile distribution). FIX still addresses M2-003 (add per-capability module/script mapping or explicit cross-ref to module-map.md).
- **Applied to:** capability-inventory.md (M2-003 mapping refinement in FIX)

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-06-25 | C | /aid-discover | Initial generation. Panel(full): 0 CRIT/0 HIGH/4 MED/2 LOW. Essence PASS · Assertiveness PASS. Grade C < A -> FIX needed. |
| 2 | 2026-06-25 | A+ | /aid-discover (FIX) | 6/6 findings Fixed, 0 new. Grade A+ >= A. Essence PASS · Assertiveness PASS -> Ready. |
| 3 | 2026-06-25 | A+ | /aid-discover (APPROVAL) | User approved. KB ready for the Interview phase. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | {YYYY-MM-DD} | — | — | — | — | Initial run |

| 2 | 2026-06-25 | A+ | hybrid:methodology-tooling+software-cli | 18 of 18 docs | kb.html (177780 bytes) | Initial generation (domain-driven 18-doc KB; Machine A+/Human A+; V1 Playwright-validated) |

## Calibration Log

| Date | Agent | Task/Cycle | ETA-band | Actual | Notes |
|------|-------|-----------|----------|--------|-------|
| 2026-06-25 | aid-researcher (pre-scan) | GENERATE Step 1 | 9-13m | 3m49s | clean lint; 3 Q&A deferred |
| 2026-06-25 | aid-researcher (architecture) | GENERATE Steps 2-5 | 8-12m | 8m25s | 3 docs clean; 4 synth; Q6 |
| 2026-06-25 | aid-researcher (quality) | GENERATE Steps 2-5 | 11-15m | 9m25s | 4 docs clean; 9 debt items |
| 2026-06-25 | aid-researcher (analyst) | GENERATE Steps 2-5 | 12-18m | 12m46s | 4 docs clean; 20 spine-todo; FM-defect flagged |
| 2026-06-25 | aid-researcher (integrator) | GENERATE Steps 2-5 | 12-16m | 15m29s | 3 docs clean; glossary 16 concepts; spine OPEN=0 |
| 2026-06-25 | aid-architect (closure) | GENERATE Step 5b | 10-20m | 18m56s | CLOSED 2/2; 29 grounded; 80 dismissed; output(a)=0 |
| 2026-06-25 | aid-reviewer (M4 act-back) | REVIEW | 8-18m | 2m16s | PASS; STATED 42/42 |
| 2026-06-25 | aid-reviewer (M3 essence) | REVIEW | 8-18m | 2m29s | PASS; coverage 10/10 |
| 2026-06-25 | aid-reviewer (M1 correctness) | REVIEW | 8-18m | 4m06s | 3 MED |
| 2026-06-25 | aid-reviewer (M2 anatomy) | REVIEW | 8-18m | 4m16s | 1 MED 2 LOW |
| 2026-06-25 | aid-reviewer (re-review) | FIX | 2-3m | 1m20s | 6/6 Fixed; 0 new |
| 2026-06-25 | aid-tech-writer (summarize GENERATE) | summary | 15-30m | 24m20s | kb.html 178KB/20 sections; NM pass |
