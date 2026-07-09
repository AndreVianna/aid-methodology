---
kb-category: meta
source: generated
objective: Discovery-area run-state ledger — the Knowledge Base's review/grade history, approval state, pending Q&A, and visual-summary status for this project.
summary: Read this for the KB's current grade, approval state, open questions, and summarization status — the process/run-state behind the knowledge docs, not knowledge content itself. One STATE.md per `.aid/knowledge/`.
tags: [meta, state, run-state, review-history, qa, approval]
see_also: [README.md, INDEX.md]
owner: skill-self
audience: [developer, architect]
---

# Discovery State

> **Source:** aid-config (creates) · aid-discover + aid-summarize (update)
> **Status:** Approved
> **Current Grade:** A+
> **User Approved:** yes
> **Last KB Review:** 2026-07-09
> **Last Summary:** 2026-06-28

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
| Human Grade | A+ (V1 visual gate PASS -- Playwright-rendered + screenshot-validated; validate-visuals 4/4 T1-T4 clear; contrast both themes PASS) |
| User Approved | yes (2026-06-28; orchestrator-validated during the doc-reconcile PR) |
| Last Run | 2026-06-28 |
| Output | .aid/dashboard/kb.html (198882 bytes, 4172 lines, 21 sections) |
| Mermaid Version | — (retired in D-012; pre-rendered inline SVG only) |
| Mermaid Cached | — |

**Doc-Set Source:** .aid/settings.yml discovery.doc_set
**Doc-Set Count:** 19 of 19
**Domain:** hybrid:methodology-tooling+software-cli
**Domain Source:** .aid/knowledge/STATE.md ## Discovery Domain
**Overall Grade:** A+ (Machine) — Human pending
**Writeback Status:** pending (orchestrator does WRITEBACK)
**Minimum Grade:** A+
**Visual-Gate Note:** validate-visuals.mjs SKIPPED (Playwright not installed in the summarize package); V1 visual gate must be run by the orchestrator. 4 inline-SVG diagrams pre-rendered.

### Findings (last validation — 2026-06-28 forced KB-refresh run)
- Machine (AUTO_POOL): 68/68 — COV 15/15 (19 docs), L1 52/52, L2 0/0, H1 0 errors, A1-A5 all pass, C1/C2 22/22 contrast both themes, S2 offline pass, NM no-Mermaid-engine pass. 0 findings.
- Human (MANUAL_POOL): not yet run; pending orchestrator.
- Spot-check-facts: 6 OK / 4 MISS — MISS items are noise patterns (fragment matching: "1 files", "10 skills", "2 modules", "256 checks"); not invented claims.
- Stale refs eliminated: 0 aid-interview-as-skill references remain; 14 skills (10 pipeline + 4 on-demand); aid-describe/aid-define, seasoned-analyst engine, greenfield seed, conformance check all present.

## Q&A (Pending)

> Open questions about KB facts, raised by any skill, awaiting human input or downstream resolution. Each entry: ID, category, impact, suggested answer (if inferrable), status.

### Q1

- **Category:** Inventory / terminology
- **Impact:** Medium
- **Status:** Answered
- **Context:** `canonical/skills/` contains 14 skill directories (aid-config, aid-deploy, aid-describe, aid-define, aid-detail, aid-discover, aid-execute, aid-housekeep, aid-monitor, aid-plan, aid-query-kb, aid-specify, aid-summarize, aid-update-kb). `README.md` uses both "12-skill pipeline" (header) and "13 skills · 5 groups" (diagram caption); `docs/repository-structure.md` says "12 skill definitions". The counts disagree across sources.
- **Suggested:** 14 skill directories exist; "12-skill pipeline" likely counts only pipeline-positioned skills and excludes one off-pipeline/setup skill. Confirm the canonical phrasing so KB docs use one consistent count.
- **Answer:** USER DECISION: state "14 skills" consistently (the disk fact, matches canonical/skills/). README's "12-skill pipeline" is a source-doc inconsistency, out of discovery scope. FIX: ensure all KB docs use 14.
- **Applied to:** capability-inventory.md, architecture.md, module-map.md, project-structure.md (verify "14 skills" consistency in FIX)

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
- **Answer:** USER CONFIRMED: the capability set is complete and correct (14 skills = 10 pipeline + 4 on-demand, CLI installer, 5-profile distribution). FIX still addresses M2-003 (add per-capability module/script mapping or explicit cross-ref to module-map.md).
- **Applied to:** capability-inventory.md (M2-003 mapping refinement in FIX)

### Q7

- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Answered
- **Context:** /aid-housekeep (KB-DELTA) reconciled the repo against the KB and found drift in 15 docs, driven by the work-002 **connectors** subsystem merged since the 2026-06-28 baseline (PR #133), plus accumulated release drift (v1.1.1→v2.0.6) and the delivery-folder relocation (PR #132). The connectors model to encode: the registry is a **catalog** (lists what agents can use + how), NOT a connection manager (Q10) — `mcp`=tool-managed (host tool provides MCP/plugin + handles auth; AID stores no credential, wires nothing) vs `api|ssh|url|cli`=aid-managed (AID records a descriptor + a local git-ignored secret resolved at use-time via `secret_reference` env:/file:/keychain:); home `.aid/connectors/`; delivery-002 (MCP host wiring) WITHDRAWN. Per-doc corrections:
    - **capability-inventory.md** — add connectors-catalog capability + `connectors/` script area; reflect aid-discover ELICIT external-source/tool-integration capture (source: generated → refresh).
    - **module-map.md** — add `connectors/` area row (connector-registry / build-connectors-index / connector-secret twins) + connector test coverage; wire ELICIT→`.aid/connectors/`+external-sources in the dependency graph; update frontmatter `contracts` area list.
    - **integration-map.md** — add a Connectors section (catalog model, `.aid/connectors/` home, tool-managed-MCP vs aid-managed-descriptor, `.mcp.json`, `secret_reference` resolution, `.gitguardian.yaml` scanning); refresh Last-Updated.
    - **decisions.md** — add D19: connectors "catalog, not connection-manager" (Q10) + tool-managed/aid-managed authority split + delivery-002-WITHDRAWN rationale.
    - **artifact-schemas.md** — add schema sections: connector descriptor, `preset-catalog.md`, `.aid/connectors/INDEX.md`, `.mcp.json`, `secret_reference` format.
    - **test-landscape.md** — update suite count 82→105; add a Connectors suite family (registry, build-index, connector-secret + ps1 + ac3-leak-sweep, twins-ps1-parity, reconcile-scenarios).
    - **architecture.md** — rephrase the version invariant to assert VERSION *lockstep* rather than hard-coding a number (P1; actual VERSION=2.0.6); add ELICIT as the Discover phase's first state; add `connectors/` script area + a connectors-subsystem note.
    - **infrastructure.md** — version 1.1.1→2.0.6 (assert-not-hardcode); add `.gitguardian.yaml` (secret scanning), `.mcp.json`, connector `.secrets/` home.
    - **pipeline-contracts.md** — add ELICIT outputs to the Discover phase-I/O + typed-artifact tables (`external-sources.md` population + `.aid/connectors/` registry).
    - **domain-glossary.md** — add connector vocabulary (Connector, Connector Registry, Preset / Preset-Catalog, tool-managed vs aid-managed, `secret_reference`); broaden the MCP entry beyond "Playwright MCP"; correct "14 standard docs"→15-doc default seed.
    - **coding-standards.md** — add `.aid/connectors/` to the kb-authoring-P7 discovery write-zone list; add a connector secret-handling security convention (`secret_reference` + git-ignored `.secrets/`).
    - **authoring-conventions.md** — add `forward-authored` to the frontmatter `source:` enum; set the seed count to 15 (CONFIRMED: `canonical/aid/templates/knowledge-base/*.md`=15).
    - **project-structure.md** — version 1.1.1→2.0.6 (assert-not-hardcode); add `.aid/connectors/` to the `.aid/` tree; de-pin the env-specific root path; refresh the stale "12-skill" README quote (→14).
    - **technology-stack.md** — set version to 2.0.6 consistently (prose "2.0.0" and hints "1.1.1" both wrong); re-measure the Shell/file count (connector scripts added).
    - **release-tracking.md** — add to `## Unreleased`: connectors subsystem (PR #133) + delivery-folder relocation (PR #132).
  Also (source-confirmed, no user question): correct the changelog provenance "work-001-add-deliveries-folder task-001" → the actual **PR #132** (branch `change-delivery`, 2026-07-08) in artifact-schemas.md, domain-glossary.md, pipeline-contracts.md, tech-debt.md. Confirmed-current (no change): external-sources.md, quality-gates.md, tech-debt.md (except the provenance line).
- **Suggested:** SURGICAL edits by the doc-owning agents (add/update only the listed items; preserve existing structure; ground every connectors claim in the cited source). Then regenerate INDEX.md/README.md, reset `**Grade:**` to Pending, REVIEW → APPROVAL (min grade A+).
- **Answer:** User approved the full-refresh scope. Applied 2026-07-09 via /aid-housekeep KB-DELTA: four aid-tech-writer cluster agents (architecture / analyst / integrator / quality) surgically refreshed the sub-agent-owned docs; the orchestrator authored capability-inventory.md, release-tracking.md, project-structure.md and regenerated INDEX.md + README.md. Source-confirmed corrections to the original plan: (1) the default seed is **14 standard docs + README (meta) = 15 seed files**, so "14 standard docs" is CORRECT — reverted an over-correction to "15 standard"; (2) `.mcp.json` is the host tool's own MCP config, **NOT** a connector artifact (grep: zero `canonical/` refs) — documented as a boundary, not wired into the catalog; (3) connector test suites = **8** (not 7); (4) provenance = **PR #132 (branch change-delivery)**. Grade reset to Pending for the REVIEW gate.
- **Applied to:** all 15 drifted docs (architecture, technology-stack, decisions, module-map, coding-standards, authoring-conventions, artifact-schemas, pipeline-contracts, integration-map, domain-glossary, test-landscape, infrastructure, capability-inventory, release-tracking, project-structure) + tech-debt.md (provenance line) + INDEX.md & README.md regenerated. external-sources.md / quality-gates.md unchanged (confirmed current).

## Review History

> One row per /aid-discover review cycle. Append-only.

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-06-25 | C | /aid-discover | Initial generation. Panel(full): 0 CRIT/0 HIGH/4 MED/2 LOW. Essence PASS · Assertiveness PASS. Grade C < A -> FIX needed. |
| 2 | 2026-06-25 | A+ | /aid-discover (FIX) | 6/6 findings Fixed, 0 new. Grade A+ >= A. Essence PASS · Assertiveness PASS -> Ready. |
| 3 | 2026-06-25 | A+ | /aid-discover (APPROVAL) | User approved. KB ready for the Interview phase. |
| 4 | 2026-07-09 | A+ | /aid-housekeep KB-DELTA (aid-reviewer) | Connectors + release-drift refresh (15 docs, PR #133/#132). 0 findings (C0/H0/M0/L0); all 7 re-verify calls confirmed (seed 14-standard/15-files, .mcp.json non-artifact, 8 suites, D19, version de-hardcoded, ELICIT, connector model); grounded in preset-catalog.md + state-elicit.md. Awaiting user approval. |
| 5 | 2026-07-09 | A+ | /aid-housekeep KB-DELTA (APPROVAL) | User directed proceed → approved the connectors + release-drift refresh. Closure re-verified before commit; committed on branch aid/housekeep-2026-07-09. |

## Summarization History

> One row per /aid-summarize run. Append-only.

| # | Date | Grade | Profile | Mermaid | Output | Notes |
|---|------|-------|---------|---------|--------|-------|
| 1 | 2026-06-28 | A+ | hybrid:methodology-tooling+software-cli | none (retired) | .aid/dashboard/kb.html (198882 bytes, 21 sections) | Forced KB-refresh regen after the work-001 doc reconcile. Machine A+ (68/68); Human A+ (V1 Playwright-rendered + screenshot-validated, validate-visuals 4/4 T1-T4, contrast both themes). Reflects the aid-describe/aid-define split (14 skills), the seasoned-analyst engine (NFR-7), greenfield forward-authored inversion, and the conformance check. |

| 2 | 2026-06-25 | A+ | hybrid:methodology-tooling+software-cli | 18 of 18 docs | kb.html (177780 bytes) | Initial generation (domain-driven 18-doc KB; Machine A+/Human A+; V1 Playwright-validated) |
| 3 | 2026-06-28 | A+ (Machine) | hybrid:methodology-tooling+software-cli | 19 of 19 docs | kb.html (198882 bytes, 4172 lines, 21 sections) | Forced KB-refresh: aid-interview split to aid-describe/aid-define; 14 skills (was 13); seasoned-analyst engine + greenfield seed + conformance check added. Machine A+ 68/68; Human pending orchestrator. |

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
