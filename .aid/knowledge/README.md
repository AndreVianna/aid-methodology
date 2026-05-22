# Knowledge Base — AID

> AI-Integrated Development methodology — structured AI-assisted software lifecycle from discovery to production monitoring.

## Project Info

| Property | Value |
|----------|-------|
| **Type** | Brownfield |
| **Initialized** | 2026-05-21 |
| **Minimum Grade** | A+ |
| **External Sources** | 8 web sources (vendor docs for Claude Code, Claude Agent SDK, Codex CLI + docs, Cursor Rules + MCP, Copilot CLI, Antigravity) |
| **Inventory pre-pass** | 353 files, 49,226 lines (`project-index.md`) |
| **Discovery posture** | Brownfield dogfood — this repo IS the AID methodology being discovered by AID itself |

## Completeness

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
| infrastructure.md | ✅ Populated | 229 | aid-discover (quality) | No deployed infra. Distribution = git clone only; install via `setup.sh` / `setup.ps1`. ❌ Both installers **CONFIRMED to omit** copying `codex/.agents/` (per DISCOVERY-STATE Q70 + tech-debt H6 — verified via static analysis, patch trivial). |
| feature-inventory.md | ✅ Populated | 62 | aid-discover (orchestrator) | 18 features from user-confirmed Q-FEATURES — **12 ✅ Shipped, 6 ⚠️ Partial** (cross-linked to blocking Q-IDs). |
| host-tools-matrix.md ⭐ | ✅ Populated (extension) | 144 | aid-discover (orchestrator) | **KB extension** — per-host-tool feature parity matrix. Outside the standard 16-doc state machine; downstream skills don't read it but reviewers + maintainers do. Consolidates per-tool content scattered across integration-map / tech-debt / coding-standards / external-sources. |

## Project-Type Adaptation Notes

This is **not a typical development project.** It is a methodology + tooling repository that ships install payloads for multiple AI coding tools. Three of the 16 standard KB documents are awkward fits and have been **adapted** rather than dropped (downstream skills depend on the 16-doc shape):

- **`api-contracts.md`** — no HTTP / RPC / GraphQL / queue surface exists. The doc was reframed as "host-tool frontmatter contracts (agent files, SKILL.md, CLAUDE.md / AGENTS.md, settings.json, `.mdc` rules) + internal AID artifact schemas."
- **`ui-architecture.md`** — no traditional user-facing UI. The doc covers the single HTML artifact AID emits (the `aid-summarize` Knowledge Base viewer) — its single-file offline shape, theming, lightbox, breadcrumb scrollspy, and profile-driven section templates.
- **`test-landscape.md`** — no test suite. The doc documents the runtime validation scripts shipped with `aid-summarize` (validate-html, validate-links, validate-diagrams via Mermaid CLI, contrast-check) plus the methodology's inherited quality gates, and is explicit about the gaps (no CI, no triplication-drift checker, no end-to-end smoke test).

**Two standard docs got the most natural fit** because the methodology repo *is* full of these concepts:

- **`domain-glossary.md`** — 150 AID-specific terms (lifecycle phases, artifacts, roles, quality concepts, task types, triplication terminology, knowledge-summary state machine). Most term-dense KB doc in the set.
- **`module-map.md`** — modules are the **skills**, **agents**, **templates**, and **install trees** — not Java packages or Python modules. Triplication relationships are the dominant structure.

**One KB extension added:** `host-tools-matrix.md` (per-tool feature parity table). Sits outside the standard 16-doc state machine, so downstream skills (`aid-interview`, `aid-specify`, `aid-plan`) won't fail looking for it; it exists for the reviewer and maintainers. Consolidates content scattered across `integration-map.md` + `tech-debt.md` + `coding-standards.md` + `external-sources.md` so adopters and contributors don't have to assemble per-tool parity from four sources.

**No documents were removed.** The 16-doc shape is load-bearing for `aid-interview`, `aid-specify`, and `aid-plan`.

## Revision History

| Date | Phase | Description |
|------|-------|-------------|
| 2026-05-21 | aid-init | Initialized (brownfield), 8 external web sources registered, `.aid/templates/knowledge-summary/` installed. |
| 2026-05-21 | aid-discover (GENERATE) | Project index built (353 files); scout produced project-structure.md + enriched external-sources.md; 4 specialist agents populated 13 KB docs in parallel; 44 Q&A entries consolidated + 1 Required Features question injected. Grade pending review. |
| 2026-05-21 | aid-discover (pre-REVIEW hygiene) | User-directed pre-grade cleanup: corrected 4 count discrepancies in README/INDEX (domain-glossary 115→146 terms; security 16→21 findings with revised severity split; data-model 23→15 artifact sections; integration-map 13→12 sections). Added Project-Type Adaptation section documenting why 3 standard docs are reframed and none were removed. |
| 2026-05-21 | aid-discover (pre-REVIEW extension) | User-directed: added `host-tools-matrix.md` as a project-type-specific KB extension outside the standard 16-doc shape. Consolidates per-host-tool feature parity from existing docs into a single matrix with 10 cross-linked known divergences/bugs. |
| 2026-05-21 | aid-discover (FIX cycle 1) | Applied all 51 Q&A resolutions to KB docs. Major changes: (1) **feature-inventory.md populated** with 18 features from user-confirmed Q-FEATURES (lifts CRITICAL from F). (2) `architecture.md` phase-count drift fixed per Q16 — canonical 10-SKILL taxonomy (Init + 8 dev + Summarize), updated pipeline diagram. (3) `technology-stack.md` §12 Build/Lint commands populated with real commands; Node 18 + Sonnet tier flipped from "inferred" to "verified". (4) `tech-debt.md` stale CLAUDE.md claims corrected; added H6 (Codex installer bug Q70 CONFIRMED), H7 (Monitor templates Q8 promoted to HIGH), M6 (Cursor Terminal/Bash Q52); added 29-row Resolution Roadmap mapping every Q-ID to actionable items. (5) `project-structure.md`, `module-map.md`, `data-model.md`, `domain-glossary.md` count drifts fixed; canonical KB taxonomy (16 standard + 3 meta + 1 generated + extensions) documented. (6) `security-model.md` §1.2 diff-claim, §1.3 wrong-file-cite, §2.4 "only agent" contradiction all corrected. (7) `infrastructure.md` + `host-tools-matrix.md` updated to mark Q70 + Q52 as CONFIRMED. (8) `external-sources.md` Trust Model section added per Q80. (9) 13 stale `.scout/architect/analyst/integrator/quality-questions.tmp` references replaced with `DISCOVERY-STATE.md` across 6 KB docs. Awaiting re-review. |
