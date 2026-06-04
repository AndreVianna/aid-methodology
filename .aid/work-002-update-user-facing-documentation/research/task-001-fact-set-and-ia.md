# task-001: Drift Audit + Information Architecture Design

**Work:** work-002-update-user-facing-documentation
**Task type:** RESEARCH
**Produced by:** task-001 researcher
**Date:** 2026-06-03
**Consumed by:** task-002 through task-006

---

## 1. Corrected Fact-Set (Drift Table)

### 1.1 README.md

| # | Doc | Location/line | Stale claim (current text) | Correct fact | KB/source citation |
|---|-----|---------------|---------------------------|--------------|-------------------|
| R1 | README.md | line 7 | "It ships as an install bundle for **three AI coding tools** (Claude Code, OpenAI Codex CLI, Cursor)" | Now ships for **five tools**: Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot CLI, Antigravity | `architecture.md` § "5 rendered install trees"; `domain-glossary.md` "Profile" |
| R2 | README.md | line 181 | "applied consistently across **all three install bundles**" | Five install bundles | Same as R1 |
| R3 | README.md | line 297 | "select the tools you use (Claude Code, Codex, Cursor) and install" | Menu has five tools: Claude Code, Codex, Cursor, GitHub Copilot CLI, Antigravity; Done = option 6 | `architecture.md` § "Install-time data flow"; `setup.sh` print_menu |
| R4 | README.md | line 299 | "Copy the tool directory into your project root — `profiles/claude-code/.claude/`, `profiles/codex/.codex/` + `profiles/codex/.agents/`, or `profiles/cursor/.cursor/`" | Also: `profiles/copilot-cli/.github/` for Copilot CLI; `profiles/antigravity/.agent/` for Antigravity | `architecture.md` § "Install Tree"; `domain-glossary.md` "Install Tree" |
| R5 | README.md | line 322 | "`.claude/`, `.codex/` + `.agents/`, or `.cursor/` (depending on the tools you picked)" | Also `.github/` (Copilot CLI) and `.agent/` (Antigravity) | Same as R4 |
| R6 | README.md | line 328 | "One or more host AI tools: **Claude Code**, **OpenAI Codex CLI**, or **Cursor**" | All five: Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot CLI, Antigravity | Same as R1 |
| R7 | README.md | lines 213–217 (agent tier table) | Two-column table with Anthropic and OpenAI only | Five tools; Cursor maps the same tiers as Claude Code; Copilot CLI uses scalar slugs; Antigravity uses Gemini-3 lineage | `architecture.md` § "Three-tier agent dispatch"; `domain-glossary.md` "Tier" |
| R8 | README.md | lines 362–373 (repo structure tree) | Lists `skills/`, `agents/`, `templates/`, `claude-code/ · codex/ · cursor/` at root | These paths do not exist at root. Correct: `canonical/` (source), `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/` (render output) | `project-structure.md` § "Top-Level Directory Tree"; verified with `ls` |
| R9 | README.md | lines 378–379 (nav table) | `skills/README.md`, `agents/README.md` — broken paths | Neither `skills/` nor `agents/` exists at root. Skills live at `canonical/skills/` (source) / `profiles/{tool}/.claude/skills/` (installed). Agents at `canonical/agents/` | Same as R8 |
| R10 | README.md | (no entry) | No mention of AID lite path | The lite path is a first-class capability: `aid-interview` has a TRIAGE state routing small work through LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths, each emitting a work-root SPEC.md + tasks/ directly (no features/, no PLAN.md) | `domain-glossary.md` § "Lite Path / Sub-Paths"; `architecture.md` skill inventory |
| R11 | README.md | (no entry) | No mention of `aid-housekeep` | `aid-housekeep` is the 11th user-facing skill (optional/on-demand, off-pipeline): KB-DELTA → SUMMARY-DELTA → CLEANUP on an `aid/housekeep-*` branch | `architecture.md` § "Skill inventory"; `domain-glossary.md` "Housekeep" |
| R12 | README.md | (no entry) | No mention of recipes | 5 pre-filled lite-path recipe templates in `canonical/recipes/` (bug-fix, method-refactor, add-crud-endpoint, add-unit-test, write-release-note). Shape: YAML frontmatter + `## spec` block + `## tasks` block + `{{slot}}` placeholders; substituted by `parse-recipe.sh`. | `domain-glossary.md` line 164 § "Recipe"; `canonical/recipes/bug-fix.md`; `canonical/recipes/README.md` |

**Additional drift in README.md (beyond known list):**

| # | Location/line | Stale claim | Correct fact | Source |
|---|---------------|-------------|--------------|--------|
| R13 | line 102 (pipeline table row for Discover) | "the 16-document Knowledge Base" | 14 standard KB documents | `canonical/templates/knowledge-base/` (14 files); `architecture.md` § "Project Type" |
| R14 | line 267 (AID vs. SDD table) | "First-class Discovery phase + 16-document KB" | 14-document KB | Same as R13 |
| R15 | line 7 | "a **10-skill pipeline**" | **11-skill pipeline** — aid-housekeep is the 11th user-facing skill (`ls -d canonical/skills/aid-* | wc -l` = 11) | `architecture.md` § "Skill inventory"; `canonical/skills/` (11 dirs confirmed) |
| R16 | line 61 | "AID is **10 skills**" | AID is **11 skills** — same correction as R15 | Same as R15 |
| R17 | line 365 | "docs for all 10 skills" | docs for all **11 skills** | Same as R15 |

Note: the Mermaid KB diagram at line 130 (`Standard["14 standard KB docs…"]`) is already correct.

---

### 1.2 methodology/aid-methodology.md

| # | Doc | Location/line | Stale claim (current text) | Correct fact | KB/source citation |
|---|-----|---------------|---------------------------|--------------|-------------------|
| M1 | methodology | lines 912–913 (§6 pipeline Mermaid diagram) | `Dep["7 · aid-deploy"]:::del` and `Mon["8 · aid-monitor"]:::del` with `classDef del` (solid fill, no dash) and a solid arrow `Exe --> Dep --> Mon` | `aid-deploy` and `aid-monitor` are optional end-of-pipeline Deliver skills, NOT numbered phases 7/8. They should be dashed-style optional nodes, not solid numbered phase nodes, with dashed optional arrows from Execute (not a linear mandatory chain). Reference the correct §4 feedback-loop diagram at line 530 which already uses the right dashed-optional style. | `architecture.md` § "Skill inventory"; `domain-glossary.md` "Deploy"; architecture changelog 2026-06-03 "methodology v3.2" |
| M2 | methodology | line 1075 (footer) | `*AID V3.1 — May 2026*` | Version 3.2 — June 2026 (the header at line 5 already reads `*Version 3.2 — June 2026*`; the footer is stale) | methodology line 5 |
| M3 | methodology | line 117 (Roles table) | "An AI coding agent (Claude Code, Codex, or similar)" for Specialist | Now five host tools: Claude Code, Codex CLI, Cursor, GitHub Copilot CLI, Antigravity | `architecture.md` § "5 rendered install trees" |
| M4 | methodology | (entire document) | No documentation of the AID lite path (TRIAGE → LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths) as a first-class workflow | Lite path is a shipped feature: `aid-interview` TRIAGE state (T1/T2/T3 questions) routes small work through condensed Interview→tasks/ directly, emitting a work-root SPEC.md + `tasks/` (no features/, no REQUIREMENTS.md, no PLAN.md) | `domain-glossary.md` § "Lite Path / Sub-Paths"; `feature-inventory.md` row 3 |
| M5 | methodology | (entire document) | No documentation of `aid-housekeep` skill | `aid-housekeep` is the 11th user-facing skill, optional/on-demand, off the mandatory pipeline. State machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE on an `aid/housekeep-*` branch | `architecture.md` § "Skill inventory"; `domain-glossary.md` "Housekeep" |
| M6 | methodology | (entire document) | No documentation of recipes (5 lite-path templates) | `canonical/recipes/` ships 5 seed recipes. Shape: YAML frontmatter + `## spec` block + `## tasks` block + `{{slot}}` placeholders, substituted by `parse-recipe.sh` | `domain-glossary.md` line 164 § "Recipe"; `canonical/recipes/bug-fix.md` |
| M7 | methodology | (entire document) | No documentation of declared doc-set mechanism (propose→confirm Step 0d in aid-discover) | Discovery doc-set is project-configurable via `.aid/settings.yml` `discovery.doc_set`; Step 0d is a propose→confirm checkpoint before dispatch; default seed synthesized from canonical templates | `domain-glossary.md` § "declared doc-set", "doc-set derivation" |
| M8 | methodology | (entire document) | Agent tier table in § "The Agent Model" covers only Anthropic and OpenAI providers | Five profiles, each mapping Large/Medium/Small differently: Claude Code (Opus/Sonnet/Haiku), Codex (gpt-5.5/gpt-5.4/gpt-5.4-mini), Cursor (same tier aliases as Claude Code), Copilot CLI (scalar slugs), Antigravity (Gemini-3 lineage) | `architecture.md` § "Three-tier agent dispatch"; `domain-glossary.md` "Tier" |

**Additional drift in methodology (beyond known list):**

| # | Location/line | Stale claim | Correct fact | Source |
|---|---------------|-------------|--------------|--------|
| M9 | § "Not Every Document Is Required" (line 169) | Line 169 already reads: "fixed core — **14 standard documents** ... and a project may add extension documents beyond the core" — the project-configurability nuance is partially present. The gap is that `.aid/settings.yml` `discovery.doc_set` (the mechanism) is not mentioned, and the tone implies 14 is a mandatory hard count rather than a configurable default. PARTIAL COVERAGE — task-003 should add a one-sentence mention of `discovery.doc_set` rather than rewriting this passage. | `methodology/aid-methodology.md` line 169 (confirmed via `sed -n '169p'`); `domain-glossary.md` "declared doc-set" |

No further drift found in methodology beyond the above.

---

### 1.3 docs/glossary.md

| # | Doc | Location/line | Stale claim (current text) | Correct fact | KB/source citation |
|---|-----|---------------|---------------------------|--------------|-------------------|
| G1 | glossary.md | line 11 | "**16 standard** markdown documents (plus 3 meta-documents)" for Knowledge Base | **14 standard** KB documents (plus 3 meta-documents: INDEX, README, STATE). The 16-doc count predates removal of the security model and ui-architecture docs from the standard template set. | `canonical/templates/knowledge-base/` (14 files excluding README); `architecture.md` § "Project Type" |
| G2 | glossary.md | line 23 (aid-config entry) | "scaffolds the `.aid/knowledge/` directory with **16 empty KB document templates**" | 14 KB document templates | Same as G1 |
| G3 | glossary.md | line 23 (aid-config entry) | "Also creates `AGENTS.md`, `CLAUDE.md`, **`DISCOVERY-STATE.md`**, `README.md`, and `INDEX.md` placeholders" | `DISCOVERY-STATE.md` is a pre-FR2 name — post-FR2 area-STATE consolidation, the discovery-area state file is `.aid/knowledge/STATE.md`. `DISCOVERY-STATE.md` no longer exists as a separate file. | `domain-glossary.md` "DISCOVERY-STATE.md" entry (notes pre-FR2); `architecture.md` § "Area-STATE consolidation (FR2)" |
| G4 | glossary.md | line 31 | "Knowledge Base (**16 documents**)" in Discover phase row | Knowledge Base (14 standard documents) | Same as G1 |
| G5 | glossary.md | line 48 (Q&A entry definition) | "Appended to a STATE file (`DISCOVERY-STATE.md`, `INTERVIEW-STATE.md`, or a feature's `STATE.md`)" | Post-FR2: discovery-area STATE is `.aid/knowledge/STATE.md`; work-area STATE is `.aid/{work}/STATE.md`; feature STATE is `.aid/{work}/features/{feature}/STATE.md`. `DISCOVERY-STATE.md` and `INTERVIEW-STATE.md` are pre-FR2 names — retired. | `domain-glossary.md` "DISCOVERY-STATE.md"; `coding-standards.md §7e`; `architecture.md` § "Area-STATE consolidation" |
| G6 | glossary.md | (entire document) | No mention of AID lite path | Lite path is a first-class workflow with 4 workType sub-paths (LITE-BUG-FIX, LITE-DOC, LITE-REFACTOR, LITE-FEATURE), condensed Interview→tasks/ flow, and recipes catalog | `domain-glossary.md` § "Lite Path / Sub-Paths" |
| G7 | glossary.md | (entire document) | No mention of `aid-housekeep` | 11th user-facing skill, optional/on-demand, off-pipeline | `domain-glossary.md` "Housekeep" |
| G8 | glossary.md | (entire document) | No enumeration of install profiles; three tools implied by context | Five install profiles: Claude Code, Codex, Cursor, GitHub Copilot CLI, Antigravity | `architecture.md` § "5 rendered install trees" |

**Additional drift in glossary.md (beyond known list):** None beyond the items above.

---

### 1.4 docs/faq.md

| # | Doc | Location/line | Stale claim (current text) | Correct fact | KB/source citation |
|---|-----|---------------|---------------------------|--------------|-------------------|
| F1 | faq.md | line 44 | "The **16 standard** markdown documents … project structure, external sources, architecture, technology stack, module map, coding standards, **data model**, **API contracts**, integration map, domain glossary, test landscape, **security model**, tech debt, infrastructure, **UI architecture**, and feature inventory" | **14 standard** documents. Stale names: "data model" → `schemas.md`; "API contracts" → `pipeline-contracts.md`; "security model" → removed from standard set; "UI architecture" → removed (the `ui-architecture.md` name is retired; `repo-presentation.md` is a project-specific KB extension for this repo, not a standard template) | `canonical/templates/knowledge-base/` (verified 14 files) |
| F2 | faq.md | line 44 | Path `../templates/knowledge-base/` in the link | This path does not exist at root (`templates/` does not exist at root). Canonical templates live at `canonical/templates/knowledge-base/` | `ls /home/andre.vianna/projects/AID/templates/` — does not exist |
| F3 | faq.md | line 23 (how to start) | "Init scaffolds the Knowledge Base structure (**16 empty templates**)" | 14 templates | Same as F1 |
| F4 | faq.md | line 28 (What AI tools) | "Claude Code, OpenAI Codex, Cursor, GitHub Copilot, Windsurf, Aider, or custom agents" | The five installed profiles are: Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot CLI, Antigravity. Windsurf and Aider are not supported profiles. The "any agent that can read files" statement is directionally true but should lead with the five supported profiles. | `architecture.md` § "5 rendered install trees" |
| F5 | faq.md | (entire FAQ) | No mention of AID lite path | Lite path with TRIAGE routing, 4 sub-paths, and recipes is a first-class capability worth documenting in the FAQ | `domain-glossary.md` § "Lite Path / Sub-Paths" |
| F6 | faq.md | (entire FAQ) | No mention of `aid-housekeep` | On-demand KB maintenance skill | `domain-glossary.md` "Housekeep" |

**Additional drift in faq.md (beyond known list):** None beyond the items above.

---

### 1.5 examples/README.md and example subdirectories

| # | Doc | Location/line | Stale claim (current text) | Correct fact | KB/source citation |
|---|-----|---------------|---------------------------|--------------|-------------------|
| E1 | examples/README.md | entire file | Three examples framed as anonymized real-world case studies (brownfield-enterprise, desktop-app, data-pipeline) with no tutorial step-by-step structure | Per SPEC work-002: all three are to be rebuilt from scratch as tutorial-style worked examples: 1 greenfield, 1 brownfield full-path, 1 brownfield lite-path | SPEC.md § "Before (current problems)"; § "After (desired state)" |
| E2 | examples/README.md | entire file | Examples do not demonstrate the lite path, recipes, `aid-housekeep`, or the five-profile install surface | New examples must cover the greenfield path (skips discovery), brownfield full path (all six phases), and brownfield lite path (condensed TRIAGE → LITE sub-path) | SPEC.md § "After (desired state)" |

**Additional drift in existing example subdirectories:**

- **examples/brownfield-enterprise/**: Factually accurate for what it describes (Discovery scenario). The KB doc list references `schemas.md` (correct current name) — no naming-level drift found. Does not need fact-correction before deletion; deletion is the action.
- **examples/desktop-app/**: Content is accurate. The "P1/P2/P3+" priority labels for review issues are not standard AID severity tags (`[CRITICAL]`/`[HIGH]`/etc.) — LIKELY a minor inconsistency, not a blocker. Does not need fact-correction before deletion.
- **examples/data-pipeline/**: Content is accurate for the scenario described. No significant structural drift found.

---

## 2. Current-State Reference Summary

### 2.1 Canonical Pipeline (phases in order)

Six numbered development phases, organized into five groups:

| Group | # | Skill | What it produces |
|-------|---|-------|-----------------|
| **1 · Prepare** | Init (unnumbered) | `aid-config` | `.aid/` scaffold, KB placeholders (14 templates + meta), `CLAUDE.md`/`AGENTS.md`, `STATE.md` seeds |
| **1 · Prepare** | 1 | `aid-discover` | 14-standard-document Knowledge Base; `project-index.md` pre-pass; `STATE.md` discovery grade/Q&A |
| **1 · Prepare** | Opt (unnumbered) | `aid-summarize` | `knowledge-summary.html` — offline KB viewer; idempotent |
| **2 · Define** | 2 | `aid-interview` | `REQUIREMENTS.md` + per-feature `SPEC.md` stubs (full path) OR work-root `SPEC.md` + `tasks/` (lite path) |
| **2 · Define** | 3 | `aid-specify` | Technical spec added to each feature's `SPEC.md` (full path only; lite path skips this phase) |
| **3 · Map** | 4 | `aid-plan` | `PLAN.md` — features sequenced into deliveries (full path only; lite path skips) |
| **3 · Map** | 5 | `aid-detail` | Typed, PR-sized `task-NNN.md` files + execution graph (full path only; lite path skips) |
| **4 · Execute** | 6 | `aid-execute` | Implemented + reviewed code to grade ≥ minimum; 8 task types; pool dispatch |
| **5 · Deliver** | Opt (end-of-pipeline) | `aid-deploy` | Release package; `package-NNN.md`; `DEPLOYMENT-STATE.md` |
| **5 · Deliver** | Opt (end-of-pipeline) | `aid-monitor` | `MONITOR-STATE.md`; classified findings → Interview (bugs) or Interview (CRs) |

**Off-pipeline (on-demand):** `aid-housekeep` — KB-DELTA → SUMMARY-DELTA → CLEANUP on `aid/housekeep-*` branch. Not in the phase→skill mapping. (11th user-facing skill.)

Sources: `architecture.md` § "Skill inventory"; `domain-glossary.md` § "Pipeline Phases".

### 2.2 Lite vs. Full Path Distinction

**Full path** (triggered by large/complex work signal in TRIAGE): `aid-interview` produces `REQUIREMENTS.md` + `features/` folder with per-feature `SPEC.md` stubs. Then `aid-specify` → `aid-plan` → `aid-detail` → `aid-execute`.

**Lite path** (triggered by small work signal in TRIAGE — T1 breadth ≤ 2 features, T2 size ≤ a few days, T3 workType ∈ {bug-fix, small-refactor, single-doc, small-new-feature}): Interview is condensed. `aid-interview` emits a work-root `SPEC.md` + `tasks/` directly, with no `features/` folder, no `REQUIREMENTS.md`, no `PLAN.md`. Sub-paths:

| workType | Sub-path | Output |
|----------|----------|--------|
| `bug-fix` | LITE-BUG-FIX | Typically 1 IMPLEMENT task (fix + regression test) |
| `small-refactor` | LITE-REFACTOR | 1–3 REFACTOR + TEST tasks |
| `single-doc` | LITE-DOC | Exactly 1 DOCUMENT task |
| `small-new-feature` | LITE-FEATURE | 1–5 IMPLEMENT + TEST + DOCUMENT tasks |

Lite path also includes **recipes**: 5 pre-filled templates at `canonical/recipes/` (bug-fix, method-refactor, add-crud-endpoint, add-unit-test, write-release-note). Shape: YAML frontmatter + `## spec` block + `## tasks` block + `{{slot}}` placeholders, substituted by `parse-recipe.sh`. Eliminates redundant interview for recurring patterns.

Escalation: a lite work may be escalated to full mid-flight. `Path: escalated` is treated as `Path: full`; `## Escalation Carry` block preserves slot answers.

Sources: `domain-glossary.md` § "Lite Path / Sub-Paths"; `domain-glossary.md` § "Recipes".

### 2.3 Agent Roster + Tiers

22 specialist agents across three model tiers:

| Tier | Agents (10/9/3) | Maps to (Claude Code) | Maps to (Codex) |
|------|-----------------|----------------------|-----------------|
| **Large** (10) | architect, reviewer, interviewer, security; discovery-scout, discovery-architect, discovery-analyst, discovery-integrator, discovery-quality, discovery-reviewer | Claude Opus | GPT-5.5 high reasoning |
| **Medium** (9) | orchestrator, researcher, developer, operator, data-engineer, performance, devops, tech-writer, ux-designer | Claude Sonnet | GPT-5.4 medium reasoning |
| **Small** (3) | simple-extractor, simple-formatter, simple-glob | Claude Haiku | GPT-5.4-mini low reasoning |

All five profiles (Claude Code, Codex, Cursor, Copilot CLI, Antigravity) map these three tiers to their respective models. Reviewer tier ≥ Executor tier invariant enforced everywhere.

Sources: `architecture.md` § "Three-tier agent dispatch"; `domain-glossary.md` § "Agents (22) & Tiers".

### 2.4 Five Profiles

| # | Profile | Output root | Agent format | Install dir |
|---|---------|-------------|--------------|-------------|
| 1 | Claude Code | `.claude/` | markdown | `profiles/claude-code/` |
| 2 | Codex CLI | `.codex/agents/` + `.agents/` | TOML | `profiles/codex/` |
| 3 | Cursor | `.cursor/` | markdown + `.mdc` rules | `profiles/cursor/` |
| 4 | GitHub Copilot CLI | `.github/` | `copilot-agent` (`.agent.md` frontmatter) | `profiles/copilot-cli/` |
| 5 | Antigravity | `.agent/` | `antigravity-rule` (`trigger:` frontmatter) | `profiles/antigravity/` |

All five contain byte-identical skill/agent bodies; only wrapper format differs per tool. Context file: Claude Code → `CLAUDE.md`; Codex/Cursor/Copilot CLI/Antigravity → `AGENTS.md`. When ≥2 AGENTS.md-writing tools are selected, Option-A collision: last-write-wins (highest-numbered tool).

Sources: `architecture.md` § "Folder Structure"; `domain-glossary.md` § "Distribution / Generator".

### 2.5 Canonical → Render → Install Architecture

```
canonical/  (single source of truth — never edit profiles/ directly)
  ├── skills/        (11 user-facing skills)
  ├── agents/        (22 agents)
  ├── templates/     (KB templates, document templates)
  ├── recipes/       (5 lite-path seed recipes)
  └── scripts/       (helper scripts by phase)
        │
        ▼  python run_generator.py
        │  (renders per profiles/*.toml — 5 profiles)
        │
profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/
  (byte-identical install trees, format-adapted per profile)
        │
        ▼  setup.sh / setup.ps1  (end-user installer)
        │  (interactive menu: 5 tools + Done; diff-aware copy)
        │
/path/to/user-project/
  {.claude/ | .codex/+.agents/ | .cursor/ | .github/ | .agent/}
```

VERIFY (deterministic) gate (`verify_deterministic.py`) runs after every render to confirm byte-identity. VERIFY (advisory) runs non-blocking checks. Sources: `architecture.md` § "Single-source compilation"; `infrastructure.md`.

### 2.6 KB Document Set (Canonical 14 Standard Docs)

`architecture.md`, `coding-standards.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `schemas.md`, `tech-debt.md`, `technology-stack.md`, `test-landscape.md`.

Plus 3 meta-documents: `INDEX.md`, `README.md`, `STATE.md`.
Plus 1 generated pre-pass: `project-index.md` (in `.aid/generated/`).

Count is **project-configurable** via `discovery.doc_set` in `.aid/settings.yml`; 14 is the default seed. Sources: `canonical/templates/knowledge-base/` (14 files); `domain-glossary.md` § "Knowledge Base".

---

## 3. Hand-Maintained vs. Generated Docs

| Doc | Maintained how | Must NOT hand-edit? | Evidence |
|-----|----------------|---------------------|---------|
| `README.md` | Hand-authored | No — hand-edit is the correct method | No AUTO-GENERATED marker; not emitted by any generator script. Hand-edit for task-002. |
| `methodology/aid-methodology.md` | Hand-authored | No — hand-edit is correct | No AUTO-GENERATED marker; not produced by any generator. `repo-presentation.md`: "not regenerated by the build system — it is hand-authored and lives at a fixed path." |
| `methodology/images/2-comparison.png` | Hand-authored (binary) | No — must be regenerated by task-003 author (new diagram needed) | Image file; no generator script for these images |
| `methodology/images/3-ironman.png` | Hand-authored (binary) | No — may be reused or replaced by task-003 author | Image file |
| `docs/glossary.md` | Hand-authored | No — hand-edit for task-002 | No AUTO-GENERATED marker |
| `docs/faq.md` | Hand-authored | No — hand-edit for task-002 | No AUTO-GENERATED marker |
| `examples/README.md` | Hand-authored | No — rebuild from scratch for task-004/005/006 | No AUTO-GENERATED marker |
| `examples/brownfield-enterprise/**` | Hand-authored | No — obsolete, to be deleted | No generator |
| `examples/desktop-app/**` | Hand-authored | No — obsolete, to be deleted | No generator |
| `examples/data-pipeline/**` | Hand-authored | No — obsolete, to be deleted | No generator |
| `profiles/{tool}/` (rendered trees) | AUTO-GENERATED by `run_generator.py` | YES — never hand-edit; edit `canonical/` and re-run generator | `coding-standards.md §7a`; `CONTRIBUTING.md`; `canonical/EMISSION-MANIFEST.md` |
| `.aid/knowledge/INDEX.md` | AUTO-GENERATED by `build-kb-index.sh` | YES — regenerate with the script | `INDEX.md` header: `<!-- AUTO-GENERATED 2026-06-03T18:55:08Z by canonical/scripts/kb/build-kb-index.sh -->` |
| `.aid/knowledge/project-structure.md` (KB doc, listed in §2.6) | AUTO-GENERATED by `build-project-index.sh` — distinct from `.aid/generated/project-index.md` (line-count pre-pass written by `aid-discover`) | YES | `project-structure.md` frontmatter: `source: generated` |

**Conclusion for writing tasks:** All user-facing docs (`README.md`, `methodology/`, `docs/`, `examples/`) are hand-authored and must be edited directly by the appropriate writing task. No user-facing doc is generator-produced. The profile install trees (`profiles/`) are generator output and must NOT be touched by this documentation work.

---

## 4. Obsolete Example Directories

All three existing example directories are **obsolete and slated for complete replacement** by tasks 004–006:

| Directory | Status | Why obsolete | Maps to new example |
|-----------|--------|-------------|---------------------|
| `examples/desktop-app/` | OBSOLETE — delete when replacement is written | Greenfield scenario framed as case study, not tutorial-style; no lite path; pre-dates 5-profile install | task-004: **greenfield worked example** |
| `examples/brownfield-enterprise/` | OBSOLETE — delete when replacement is written | Brownfield Discovery scenario framed as case study; full path only; pre-dates 5-profile install | task-005: **brownfield full-path worked example** |
| `examples/data-pipeline/` | OBSOLETE — delete when replacement is written | Multi-agent pipeline framed as case study; not structured as a tutorial; no lite path | task-006: **brownfield lite-path worked example** |

**Mapping to the new three worked examples:**

| New example | Tutorial focus | Replaces |
|-------------|----------------|---------|
| Greenfield (task-004) | New project; skips Discovery; `aid-config` → `aid-interview` → TRIAGE → full path through `aid-execute` | `examples/desktop-app/` |
| Brownfield full-path (task-005) | Existing codebase; `aid-discover` → full pipeline through `aid-execute`; shows KB-driven spec | `examples/brownfield-enterprise/` |
| Brownfield lite-path (task-006) | Existing codebase; `aid-interview` → TRIAGE → LITE sub-path; shows condensed flow and optionally recipes | `examples/data-pipeline/` |

Removal timing: delete the obsolete dirs when writing the new ones (within tasks 004/005/006). No stale example set should survive after all three tasks are complete, per SPEC AC.

---

## 5. Information Architecture / Reading Path Proposal

### 5.1 Audience Split

| Surface | Primary audience | Job |
|---------|-----------------|-----|
| `README.md` | Adopter (evaluating, installing) | Understand AID in one scan; decide to install; run the first slash command |
| `docs/glossary.md` | Practitioner (actively using AID) | Look up a term quickly |
| `docs/faq.md` | Adopter + Practitioner | Answer "how do I...?" and "why does AID...?" questions |
| `methodology/aid-methodology.md` | Learner / Blog reader | Deep understanding of philosophy, each skill, each agent, comparison with alternatives |
| `examples/` | Adopter + Learner | See AID applied step-by-step to a realistic scenario |

### 5.2 Target Reading Path

```
(Entry)
README.md
  → "What is AID?" (overview + philosophy)
  → "The Pipeline" (what the skills do — full path + lite path)
  → "Using AID in your own project" (install + first run)
  → Navigation links →

  ↓ (for ongoing use)
docs/faq.md           ← "I have a question about X"
docs/glossary.md      ← "I don't know what Y means"

  ↓ (for depth)
methodology/aid-methodology.md
  → Philosophy (why Waterfall + AI)
  → Knowledge Base in depth
  → Each phase in depth (full path + lite path)
  → Feedback loops
  → Artifacts reference
  → Pipeline visual (v3.2 correct shape)
  → Case studies (same scenarios as examples/, narrative form)
  → Comparison with SDD
  → Adoption guide

  ↓ (for hands-on learning)
examples/
  → examples/README.md  (index: 3 scenarios; which to read first)
  → examples/greenfield/            (tutorial, step-by-step)
  → examples/brownfield-full-path/  (tutorial, step-by-step)
  → examples/brownfield-lite-path/  (tutorial, step-by-step)
```

### 5.3 Target File Structure

Proposed layout after the refactor (tasks 002–006):

```
README.md                           ← Adopter entry point (rewrite: task-002)
docs/
  glossary.md                       ← Practitioner reference (rewrite: task-002)
  faq.md                            ← Adopter + Practitioner Q&A (rewrite: task-002)
methodology/
  aid-methodology.md                ← Learner/blog narrative (rewrite: task-003)
  images/
    pipeline-diagram.png            ← Regenerated: correct v3.2 pipeline (task-003)
    comparison-sdd.png              ← Regenerated or reused (task-003)
    ironman.png                     ← Reuse or regenerate (task-003)
examples/
  README.md                         ← Examples index (rewrite: task-004)
  greenfield/
    README.md                       ← Tutorial: greenfield worked example (task-004)
    [supporting files as needed]
  brownfield-full-path/
    README.md                       ← Tutorial: brownfield full-path (task-005)
    [supporting files as needed]
  brownfield-lite-path/
    README.md                       ← Tutorial: brownfield lite-path (task-006)
    [supporting files as needed]

DELETED (one per task):
  examples/desktop-app/             ← Deleted by task-004
  examples/brownfield-enterprise/   ← Deleted by task-005
  examples/data-pipeline/           ← Deleted by task-006
```

### 5.4 Per-Artifact Job Description

**README.md** (task-002): Brief, direct. Sections: What is AID (3 convictions + Iron Man + 6-phase pipeline overview), Why AID (failure mode table), The Pipeline (Mermaid flowchart — correct v3.2 shape: 6 numbered phases + optional deploy/monitor as dashed nodes), Lite Path (one paragraph: what it is, when it applies, how to invoke), Install (setup.sh / setup.ps1 with all 5 tools in the menu), First run (ordered slash commands), What gets installed (5 profile directories), Runtime requirements, Versioning, Repository structure (actual paths: `canonical/`, `profiles/`, `docs/`, `examples/`, `methodology/`). Navigation table: where to go for what. No deep content — links to methodology for depth, links to examples for hands-on.

**docs/glossary.md** (task-002): Term → definition, one sentence to two short paragraphs. Must add: Lite Path, TRIAGE, workType, LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE, Recipe, Slot, aid-housekeep, declared doc-set, five profiles. Must correct: KB count (14 not 16), STATE file names (`.aid/knowledge/STATE.md` not `DISCOVERY-STATE.md`). Remove stale terms: `DISCOVERY-STATE.md` and `INTERVIEW-STATE.md` as standalone file names.

**docs/faq.md** (task-002): Q&A pairs organized by section (General / Adoption / Technical). Must add: What is the lite path? When should I use it? What are recipes? What does aid-housekeep do? What AI tools does AID support (5 profiles)? Must correct: KB doc count (14) and doc names (schemas.md, pipeline-contracts.md), broken link to `../templates/knowledge-base/`, 5-tool menu reference.

**methodology/aid-methodology.md** (task-003): Long-form blog narrative. Deep per-skill/per-agent coverage. Must add: lite path as first-class concept (§3 Interview extended with TRIAGE + 4 sub-paths + work-root SPEC output + escalation); recipes (§3 or §5 Artifacts Reference); aid-housekeep (§3 as off-pipeline skill, not mandatory); declared doc-set concept (§2 Knowledge Base); all five profiles with their tier mappings. Must fix: §6 pipeline diagram (deploy/monitor as optional/unnumbered with dashed arrows); footer version (`AID V3.2 — June 2026`); Specialist role definition (5 tools). Regenerate images to match v3.2 pipeline shape.

**examples/README.md** (task-004): Index of three examples with one-paragraph synopsis + key takeaway per scenario + which path it demonstrates (full vs. lite).

**examples/greenfield/** (task-004): Tutorial style. Step-by-step: problem statement → `/aid-config` → `/aid-interview` (shows TRIAGE deciding full path) → `/aid-specify` → `/aid-plan` → `/aid-detail` → `/aid-execute`. Explains each step's purpose before showing its output.

**examples/brownfield-full-path/** (task-005): Tutorial style. Step-by-step: existing codebase → `/aid-config` → `/aid-discover` → KB artifacts → `/aid-interview` → TRIAGE (routes to FULL) → through `/aid-execute`. Explains how the KB drives the spec (brownfield value prop).

**examples/brownfield-lite-path/** (task-006): Tutorial style. Step-by-step: existing codebase with a small, well-scoped change → `/aid-interview` → TRIAGE (routes to LITE, e.g., LITE-BUG-FIX or LITE-FEATURE) → work-root SPEC.md → tasks/ → `/aid-execute`. Optionally shows a recipe shortcut. Explains what is skipped and why.

### 5.5 Concrete Action List (Wave-2 Writing Tasks)

**task-002 — README + docs/**
1. Rewrite README.md: update title block to include all 5 tools; fix pipeline Mermaid (5-profile install, v3.2 shape with optional deploy/monitor); add Lite Path section; fix all 3-tool references to 5-tool (lines 7, 181, 297, 322, 328); fix repository structure tree (actual paths: `canonical/`, `profiles/`, `docs/`, `examples/`, `methodology/`); fix nav table links (remove broken `skills/`, `agents/` paths); update agent tier table (all 5 profiles); fix pipeline table rows R13/R14 (16-document → 14-document).
2. Rewrite docs/glossary.md: fix KB count (14); fix STATE file names; add lite path terms; add profiles list; add recipes; add aid-housekeep.
3. Rewrite docs/faq.md: fix KB count + doc names + broken link; add lite path FAQ; add housekeep FAQ; update tool list to 5 profiles; fix template path reference.

**task-003 — methodology/aid-methodology.md**
1. Fix §6 pipeline diagram: make deploy/monitor optional nodes (no numbers 7/8, dashed arrows matching the §4 feedback-loop diagram's style).
2. Add lite path to §3 Interview: TRIAGE, 4 sub-paths, work-root SPEC.md output, escalation.
3. Add recipes (§3 under Interview or §5 Artifacts Reference).
4. Add aid-housekeep to §3 (off-pipeline skill, not mandatory flow).
5. Add declared doc-set concept to §2 Knowledge Base.
6. Expand agent tier table to cover all 5 profiles.
7. Update §1 Roles: Specialist is "Claude Code, Codex CLI, Cursor, GitHub Copilot CLI, Antigravity, or similar."
8. Fix footer: `AID V3.2 — June 2026`.
9. Regenerate images to match v3.2 pipeline shape (deploy/monitor optional).

**task-004 — Greenfield example**
1. Delete `examples/desktop-app/` entirely.
2. Create `examples/greenfield/README.md` (tutorial, step-by-step).
3. Create supporting files as needed.
4. Write/update `examples/README.md` index entry for greenfield.

**task-005 — Brownfield full-path example**
1. Delete `examples/brownfield-enterprise/` entirely.
2. Create `examples/brownfield-full-path/README.md` (tutorial, step-by-step).
3. Create supporting files as needed.
4. Write/update `examples/README.md` index entry.

**task-006 — Brownfield lite-path example**
1. Delete `examples/data-pipeline/` entirely.
2. Create `examples/brownfield-lite-path/README.md` (tutorial, step-by-step, TRIAGE → LITE sub-path).
3. Create supporting files as needed.
4. Write/update `examples/README.md` index entry.

---

## Appendix A: Drift Items by Severity

**CRITICAL (factually wrong + misleads adopters):**
- R1/R2/R3/R5/R6: README says three tools (Claude Code/Codex/Cursor) — five tools ship today
- R8/R9: README repo structure tree lists non-existent paths (`skills/`, `agents/`, `templates/`, `claude-code/`)
- R13/R14 + G1/G2/G4/F1/F3: multiple docs say 16 KB docs/templates — correct count is 14
- F2: FAQ links to `../templates/knowledge-base/` — path does not exist at root
- G3/G5: glossary uses pre-FR2 file names `DISCOVERY-STATE.md` and `INTERVIEW-STATE.md` — retired post-FR2
- M1: methodology §6 pipeline diagram shows deploy/monitor as numbered phases 7/8 with solid mandatory arrow — they are optional (no numbers, dashed)

**HIGH (missing critical feature documentation):**
- R10/M4/G6/F5: lite path completely absent from README, methodology, glossary, FAQ
- R11/M5/G7/F6: aid-housekeep absent from all docs
- R12/M6: recipes absent from all docs
- M7: declared doc-set mechanism absent from methodology
- R7/M8: agent tier table incomplete (only 2 of 5 profiles shown)
- M2: methodology footer version stale (V3.1 instead of V3.2)

**MEDIUM (partially correct, needs update):**
- R4/R5: manual install instructions list only 3 of 5 profile dirs
- M3: Specialist role definition lists only Claude Code and Codex
- F4: FAQ tool list mixes installed profiles with generic tool names (Windsurf, Aider)
- F1: FAQ names stale KB docs (data model, API contracts, security model, UI architecture)

---

*All evidence in this document cites file paths confirmed by direct file read or shell `ls`/`grep` during this research session. Confidence level: CONFIRMED for all drift items above.*
