---
kb-category: primary
source: hand-authored
intent: |
  Authoritative glossary of AID-specific terms mined from the methodology spec, skill
  frontmatter, agent definitions, templates, and scripts. Covers phase names (Discover through
  Monitor), role names (Director, Orchestrator, Specialist), pipeline concepts (Phase Gate,
  Lite Path, Two-Tier Review, Pool Dispatch), work-type taxonomy, traceability layers (L1–L3),
  and rubric tiers. Read this when any AID term is unfamiliar.
contracts: []
changelog:
  - 2026-06-09: aid-ask added (11->12 user-facing skills) via /aid-housekeep KB-DELTA.
  - 2026-06-03: work-001 feature-003 — recipe catalog expanded to 51 (5 seed recipes migrated + 46 new recipe names authored; 47 files newly created on disk since the write-release-note split adds a second new file); Seed Catalog term updated to 51-recipe definition across 4 groups.
  - 2026-06-03: work-001 feature-002 — TRIAGE rewritten description-first; LITE-DOC sub-path eliminated; documentation/report work folds under LITE-FEATURE (add-docs/add-report) and LITE-REFACTOR (change-docs/change-report); Triage + workType glossary terms updated to description-first flow.
  - 2026-06-03: work-001 feature-001 — lite work-type enum collapsed 4→3 (single-doc eliminated); workType term enum updated to {bug-fix | new-feature | refactor}; LITE-REFACTOR source updated small-refactor→refactor; LITE-FEATURE source updated small-new-feature→new-feature.
  - 2026-06-03: methodology v3.2 — Deploy/Monitor recast from numbered phases 7/8 to optional end-of-pipeline Deliver skills; AID term updated to "6 numbered development phases"; updated source anchors to the renamed spec headings (`#### Deploy … — optional` / `#### Monitor … — optional`). Loops 9/10 + Bug/CR Path terms re-pointed Monitor → Interview (bug via LITE-BUG-FIX; CR as new/changed requirements).
  - 2026-06-03: housekeep run-state relocation (PR #51) — corrected the "Housekeep Status" term: the run-state block now lives in the project-level `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (transient/gitignored), not a work-area STATE.md.
  - 2026-06-03: aid-housekeep merge (PR #49) — added "Housekeep / KB-drift reconciliation" (the optional off-pipeline /aid-housekeep skill) and "Housekeep Status" (the work-area run-state block) terms; left "Pre-flight Cleanup" (the distinct /aid-discover orchestrator-only KB sweep) unchanged
  - 2026-06-01: work-001-add-providers merge (PRs #42/#43/#44) — profile count 3→5; updated Generate/Profile/Install Tree/Dogfood Tree/Quadruple Mirror terms to 5-profile reality; added copilot-agent format, antigravity-rule format, native Agent Skills mapping, rules_frontmatter trigger-dialect, Option-A AGENTS.md collision
  - 2026-05-31: delivery-002 — added three terms: "declared doc-set", "default seed set", "doc-set derivation (propose→confirm)"
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Domain Glossary

> Terms mined from `docs/aid-methodology.md` (the methodology spec),
> `docs/glossary.md`, `CLAUDE.md`, `canonical/skills/*/SKILL.md` frontmatter and bodies,
> `canonical/agents/*/AGENT.md`, `canonical/EMISSION-MANIFEST.md`,
> `canonical/templates/*.md`, `canonical/scripts/**/*.sh`, and the work-state template.
>
> The AID repo has its own dense vocabulary — phases, states, work types, sub-paths,
> traceability layers, rubric tiers, and integration mechanisms — that any agent
> operating in this repo must know. Each entry cites durable-anchor evidence — a
> file path plus a grep-recoverable symbol, heading, or distinctive string (no line
> numbers, which drift).

---

## Core Methodology

| Term | Definition (inferred from usage) | Source |
|------|----------------------------------|--------|
| **AID** | "AI Integrated Development" — a structured methodology for building/maintaining software with AI agents; 6 numbered development phases in 5 groups (delivery and summary skills optional), every phase co-executed by human + AI. | `docs/aid-methodology.md` `# AID — AI Integrated Development`, `CLAUDE.md` `## Project`, `docs/glossary.md` `**AID (AI Integrated Development):**` |
| **Iron Man Model** | The human-AI collaboration philosophy: AI is the suit (amplifies capability); human is the pilot (sets direction, decisions). Human never leaves the cockpit. | `docs/aid-methodology.md` `### The Iron Man Model: Human-in-the-Middle`, `docs/glossary.md` `**Iron Man Model:**` |
| **Director** | Role — the human. Sets direction, makes decisions, reviews artifacts, approves phase transitions. Orchestrates, doesn't code. | `docs/aid-methodology.md` `### The Iron Man Model: Human-in-the-Middle` |
| **Orchestrator** | Role — an AI agent (or human). Manages the pipeline: spawns agents, routes feedback loops, enforces quality gates, maintains KB. | `docs/aid-methodology.md` `## 5. The Agent Model` |
| **Specialist** | Role — an AI coding agent. Executes tasks within defined scope. Reports impediments rather than working around them. | `docs/aid-methodology.md` `## 5. The Agent Model` |
| **Phase Gate** | Human decision point between phases. The human reviews phase output and approves advancement. "OK?" is the gate. | `docs/glossary.md` `**Phase Gate:**` |
| **Determinism Test** | "Can you write a complete set of rules to validate the outcome?" If yes, automate fully; if no, keep a human in the loop. Used to decide automation depth per phase. | `docs/glossary.md` `**Determinism Test:**` |
| **Brownfield** | An existing codebase with history, technical debt, and undocumented knowledge. Discovery phase is designed for brownfield. | `docs/glossary.md` `**Brownfield:**`, `canonical/templates/settings.yml` `type: brownfield` |
| **Greenfield** | A new project with no existing code. Runs `aid-config` first, then skips Discovery, starts at Interview. | `docs/glossary.md` `**Greenfield:**`, `docs/aid-methodology.md` `#### \`aid-config\` — Bootstrap (not a numbered phase)` |
| **SDD** | "Spec-Driven Development" — a methodology where specs drive code generation. AID contains SDD as a subset and extends it with discovery, two-level planning, feedback loops, and post-deployment phases. | `docs/glossary.md` `**SDD (Spec-Driven Development):**` |

---

## Pipeline Phases (the 8)

| Term | Group | Skill | Definition | Source |
|------|-------|-------|------------|--------|
| **Discover** | Prepare | `aid-discover` | Phase 1 — Understand the existing system; produces the KB. State machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE. | `docs/aid-methodology.md` `#### Phase 1: Discover`, `canonical/skills/aid-discover/SKILL.md` `State-machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE` |
| **Interview** | Define | `aid-interview` | Phase 2 — Gather requirements one question at a time; produces REQUIREMENTS.md + per-feature SPEC.md (requirements side). | `docs/aid-methodology.md` `#### Phase 2: Interview`, `canonical/skills/aid-interview/SKILL.md` `# Adaptive Requirements Gathering` |
| **Specify** | Define | `aid-specify` | Phase 3 — Technical refinement per feature; agent acts as tech lead, proposes solutions, writes Technical Specification into SPEC.md. | `docs/aid-methodology.md` `#### Phase 3: Specify` |
| **Plan** | Map | `aid-plan` | Phase 4 — Sequence features into deliverables, each a functional MVP. Plan answers ONE question: order + standalone-functionality. | `docs/aid-methodology.md` `#### Phase 4: Plan` |
| **Detail** | Map | `aid-detail` | Phase 5 — Decompose each deliverable into PR-sized typed tasks. "Ultimate breakdown." | `docs/aid-methodology.md` `#### Phase 5: Detail` |
| **Execute** | Execute | `aid-execute` | Phase 6 — Execute a task per its Type; built-in two-tier review (per-task quick-check + per-delivery gate). One branch per delivery. | `docs/aid-methodology.md` `#### Phase 6: Execute` |
| **Deploy** | Deliver | `aid-deploy` | Optional (end-of-pipeline Deliver skill, not a numbered phase) — Bundle deliveries into a release; final verification (build + tests + lint); ship per `infrastructure.md § Deployment`. Routes KB-affecting discoveries to Discovery (never edits KB directly). | `docs/aid-methodology.md` `#### Deploy (`aid-deploy`) — optional` |
| **Monitor** | Deliver | `aid-monitor` | Optional (end-of-pipeline Deliver skill, not a numbered phase) — Observe production; classify findings (BUG/CR/Infra/No Action); route to Interview. The short path (BUG → Interview LITE-BUG-FIX → Execute) skips spec/plan. | `docs/aid-methodology.md` `#### Monitor (`aid-monitor`) — optional` |

---

## Non-Phase Skills

| Term | Skill | Definition | Source |
|------|-------|------------|--------|
| **Config** | `aid-config` | Bootstrap skill; runs once before the pipeline. Creates `.aid/settings.yml` + KB doc scaffolds (from the default seed set templates) + `AGENTS.md`/`CLAUDE.md` + `INDEX.md` placeholders + `DISCOVERY-STATE.md`. The exact scaffold count matches the default seed (varies if templates are added/removed from `canonical/templates/knowledge-base/`). | `docs/glossary.md` `**aid-config:**`, `docs/aid-methodology.md` `#### \`aid-config\` — Bootstrap (not a numbered phase)` |
| **Summarize** | `aid-summarize` | Optional read-only skill; generates `knowledge-summary.html` from approved KB. Idempotent. WCAG-AA accessibility-first. | `docs/aid-methodology.md` `#### \`aid-summarize\` — Optional KB Viewer (not a numbered phase)`, `canonical/skills/aid-summarize/SKILL.md` `# Knowledge Base Visual Summary` |
| **Housekeep / KB-drift reconciliation** | `aid-housekeep` | Optional, **on-demand** skill that is **OFF the mandatory pipeline** (not in the phase→skill mapping; no phase gate references it — REQUIREMENTS.md FR6). Reconciles drift across three gated jobs in strict order on a dedicated `aid/housekeep-*` branch (one commit per stage, never pushes): **KB-DELTA** (re-discover KB docs that drifted from the repo since the last KB approval — synthesizes an `**Impact:** Required` Q&A entry to drive `/aid-discover`'s targeted re-discovery), **SUMMARY-DELTA** (regenerate the visual summary via `/aid-summarize` if the KB changed), **CLEANUP** (sweep stale `.aid/` work-area artifacts). State machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE; re-entrant (a stalled run resumes at the stalled stage). Distinct from "Pre-flight Cleanup" (which is a `/aid-discover` orchestrator-only KB sweep). | `canonical/skills/aid-housekeep/SKILL.md` `# Knowledge Base Housekeeping` + `**Absent from the mandatory pipeline flow.**`, `canonical/skills/aid-housekeep/references/state-kb-delta.md` `## Step 4 — Synthesize an Impact: Required Q&A entry + invoke /aid-discover` |
| **Generate** | `generate-profile` | Maintainer-only skill; renders `canonical/` → 5 profile install trees (claude-code, codex, cursor, copilot-cli, antigravity). Wrapped by `run_generator.py`. | `.claude/skills/generate-profile/SKILL.md` `# AID Install-Tree Generator`, `profiles/*.toml` (5 profiles) |

> **Skill enumeration (post aid-ask):** 12 user-facing skills (`aid-config`, `aid-discover`,
> `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy`,
> `aid-monitor`, `aid-summarize`, `aid-housekeep`, `aid-ask`) + maintainer-only `generate-profile`.
> Of these `aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`, and `aid-ask` are
> optional, non-required skills (not numbered phases): `aid-deploy`/`aid-monitor` are optional
> end-of-pipeline Deliver skills; `aid-housekeep` is off the mandatory pipeline (no phase gate
> references it); and `aid-ask` is an off-pipeline, read-only Q&A skill (`allowed-tools: Read,
> Glob, Grep, Agent` — no write). Source: `find canonical/skills -maxdepth 1 -type d`.

---

## Knowledge Base (KB)

| Term | Definition | Source |
|------|------------|--------|
| **Knowledge Base / KB** | `.aid/knowledge/` — a set of active markdown documents whose count varies by project (driven by the declared doc-set) + 2 meta-documents (README, STATE) + 1 generated (INDEX) + 1 generated pre-pass (metrics + project-index in .aid/generated/). The gravitational center of AID — every phase reads from it; any phase can update it. | `docs/aid-methodology.md` `## 3. The Knowledge Base`, `docs/glossary.md` `**Knowledge Base (KB):**` |
| **declared doc-set** | The project-specific list of KB documents for a discovery run, declared in `.aid/settings.yml` `discovery.doc_set` as a YAML block-list of pipe-delimited `filename\|owner\|presence[:when]` entries. Drives which agents are dispatched and what filenames they produce. When absent, the default seed set is used. | `canonical/skills/aid-discover/references/doc-set-resolve.md` `## Schema: discovery.doc_set in .aid/settings.yml` |
| **default seed set** | The canonical default KB doc-set, synthesized by `synth_default_seed` from `canonical/templates/knowledge-base/*.md` using the §2.2 ownership map when `discovery.doc_set` is absent from settings.yml. Backward-compatible: an unmodified settings.yml yields the canonical standard set. | `canonical/skills/aid-discover/references/doc-set-resolve.md` `## synth_default_seed` |
| **doc-set derivation (propose→confirm)** | Step 0d of the GENERATE state — a PAUSE-FOR-USER-DECISION checkpoint where the orchestrator infers a proposed doc-set from the project-index file inventory (as a diff against the default seed) and presents it to the user for confirmation or editing before dispatch begins. Accepting the default writes nothing to settings.yml (absent-section-means-default-seed invariant). | `canonical/skills/aid-discover/references/state-generate.md` `### Step 0d: Propose & Confirm Doc-Set` |
| **INDEX.md** | Meta — 2-3 line summary of every KB document; included in every task context for self-serve KB navigation. | `docs/aid-methodology.md` `├── INDEX.md`, `docs/aid-methodology.md` `# Knowledge Base Index — {Project Name}` |
| **README.md (KB)** | Meta — tracks completeness status (Complete / Partial / Missing) per KB document. | `docs/aid-methodology.md` `├── README.md`, `docs/aid-methodology.md` `### Completeness Is Tracked` |
| **DISCOVERY-STATE.md** | Meta — discovery grade, Q&A entries, review history. Pre-FR2 name; post-FR2 consolidated into `.aid/knowledge/STATE.md`. | `docs/aid-methodology.md` `├── STATE.md`, `canonical/templates/discovery-state-template.md` |
| **project-index.md** | Generated — file-inventory pre-pass for discovery sub-agents (~1,148 lines in this repo). Built by `build-project-index.sh`. | `docs/aid-methodology.md` `├── project-index.md`, `.aid/knowledge/project-structure.md` `← pre-built file inventory` |
| **active KB docs (this repo)** | For this repo (post-Q3 FIX): `project-structure.md`, `external-sources.md`, `architecture.md`, `technology-stack.md`, `module-map.md`, `coding-standards.md`, `schemas.md` (was `data-model.md`), `pipeline-contracts.md` (was `api-contracts.md`), `integration-map.md`, `domain-glossary.md`, `test-landscape.md`, `tech-debt.md`, `infrastructure.md`, `repo-presentation.md` (NEW — replaced `ui-architecture.md` per Q3), `feature-inventory.md`. The count varies by project; the active set for any project is the confirmed declared doc-set from the most recent GENERATE run. | `canonical/skills/aid-discover/references/doc-set-resolve.md` `## synth_default_seed`, `canonical/skills/aid-discover/references/state-generate.md` `### Step 0d: Propose & Confirm Doc-Set` |
| **Tier 1 / Tier 2 / Tier 3 (context economy)** | Tier 1 = INDEX.md (always loaded). Tier 2 = one KB doc on demand. Tier 3 = exact `path:line` via citation. "RAG by convention" — no embeddings/vector DB. | `docs/aid-methodology.md` `Tier 3 — an exact repository location, via citation` |
| **Context Feeding Strategy** | The protocol by which agents are given KB context: always include INDEX.md; orchestrator pre-selects 2-4 relevant KB docs; agent self-serves additional docs via INDEX. | `docs/aid-methodology.md` `### Context Feeding Strategy` |
| **Path:line citation** | Every factual KB claim carries an inline `path:line` reference. Anchors facts to source. Enables Tier 3 jump. | `docs/aid-methodology.md` `**Hallucination**` row |

---

## Workspace / Artifacts

| Term | Definition | Source |
|------|------------|--------|
| **Work** | A self-contained scope unit at `.aid/work-NNN-{name}/`. One interview = one work. Multiple works coexist; each has its own requirements + features; all share the KB. | `docs/aid-methodology.md` `#### Phase 2: Interview` |
| **Feature** | A discrete capability inside a work. Lives at `.aid/{work}/features/feature-NNN-{name}/` with its own `SPEC.md`. Created by `aid-interview` Feature Decomposition state. | `docs/aid-methodology.md` `#### Phase 2: Interview` |
| **Delivery / Deliverable** | A subset of features grouped by `aid-plan` such that the group is a standalone-functional MVP. One branch per delivery (`aid/{work}-delivery-NNN`). | `docs/aid-methodology.md` `#### Phase 4: Plan`, `canonical/skills/aid-execute/SKILL.md` `One branch per delivery. All tasks in a delivery share the same branch.` |
| **Task** | The atomic unit produced by `aid-detail`. `task-NNN.md` — 6 sections (Title, Type, Source, Depends on, Scope, Acceptance Criteria). One task = one agent session = one PR. | `docs/aid-methodology.md` `#### Phase 5: Detail`, `canonical/skills/aid-execute/SKILL.md` `Read \`task-NNN.md\`. It has 6 sections:` |
| **Package** | A release artifact bundling one or more completed deliveries. `package-NNN-{name}.md` per shipped package. | `docs/aid-methodology.md` `#### Deploy (`aid-deploy`) — optional` |
| **REQUIREMENTS.md** | The product-of-Interview document; one per work (full path only). Frozen after approval (rev-tracked). Holds Objective / Problem / Scope / FRs / NFRs / Constraints / Acceptance / Priority. | `docs/aid-methodology.md` `### Templates Reference`, `docs/aid-methodology.md` `**REQUIREMENTS.md template:**` |
| **SPEC.md (per-feature)** | Per-feature spec; requirements side (from Interview) + technical side (from Specify). | `docs/aid-methodology.md` `### Templates Reference`, `docs/aid-methodology.md` `**Feature SPEC.md template:**` |
| **SPEC.md (work-root, lite path)** | A single consolidated work-root SPEC.md in lite path (no features/ folder, no REQUIREMENTS.md, no PLAN.md). | `canonical/skills/aid-interview/SKILL.md` `A lite work has **no \`features/\` folder` |
| **PLAN.md** | The product-of-Plan document; ordered deliverables + optional cross-cutting risks + deferred features + Execution Graph (appended by Detail). | `docs/aid-methodology.md` `### Templates Reference`, `docs/aid-methodology.md` `**PLAN.md template:**` |
| **known-issues.md** | Living issue log per work; created when the first issue is registered. Read by Plan, Execute, Deploy, Monitor. | `docs/aid-methodology.md` `### Core Artifacts` |
| **MONITOR-STATE.md** | The product-of-Monitor file: last-run log + active findings + resolved findings. | `docs/aid-methodology.md` `### Templates Reference`, `docs/aid-methodology.md` `**MONITOR-STATE.md template:**` |
| **IMPEDIMENT-task-NNN.md** | Written by `aid-execute` when it discovers an assumption that doesn't hold. Has Type (wrong-assumption / missing-dependency / architecture-conflict / kb-gap), Options, Recommendation. The human decides. | `canonical/templates/feedback-artifacts/IMPEDIMENT.md` `# Impediment — task-NNN`, `docs/aid-methodology.md` `# Impediment — task-NNN` |
| **Q&A entry** | Universal loopback artifact appended to a STATE file. Schema (Style A): `### Q{N}` + sub-bullets `Category`, `Impact`, `Status`, `Context`, `Suggested`, `Answer` (per `coding-standards.md §12`). | `docs/aid-methodology.md` `### Q{N}`, `coding-standards.md §12` |
| **Revision History / Change Log** | Inline rev-tracking table on every artifact. Distinct from process state. | `docs/aid-methodology.md` `### The Revision Trail`, `canonical/templates/work-state-template.md` `keep their inline \`## Change Log\` sections` |

---

## Task Types (8 — drive both Execute behavior + reviewer criteria)

| Term | Definition | Source |
|------|------------|--------|
| **RESEARCH** | Investigate, compare options, document findings. May skip branch isolation if only `.aid/` artifacts. | `docs/aid-methodology.md` `**RESEARCH** — investigate, compare options`, `canonical/skills/aid-execute/SKILL.md` `RESEARCH and DOCUMENT tasks may not need a branch` |
| **DESIGN** | Mockups, wireframes, UI prototypes, interaction flows. | `docs/aid-methodology.md` `**DESIGN** — mockups, wireframes` |
| **IMPLEMENT** | Write code + unit tests. | `docs/aid-methodology.md` `**IMPLEMENT** — write code + unit tests` |
| **TEST** | Integration, E2E, UI, load tests. | `docs/aid-methodology.md` `**TEST** — integration, E2E, UI, load tests` |
| **DOCUMENT** | ADRs, API docs, runbooks, diagrams. May skip branch isolation. | `docs/aid-methodology.md` `**DOCUMENT** — ADRs, API docs, runbooks` |
| **MIGRATE** | Data migration scripts, schema changes. | `docs/aid-methodology.md` `**MIGRATE** — data migration scripts` |
| **REFACTOR** | Restructure code without changing behavior. | `docs/aid-methodology.md` `**REFACTOR** — restructure code without changing behavior` |
| **CONFIGURE** | Config files, CI/CD, environment setup. | `docs/aid-methodology.md` `**CONFIGURE** — config files, CI/CD` |

---

## Lite Path / Sub-Paths (feature-005)

| Term | Definition | Source |
|------|------------|--------|
| **Lite Path** | Collapsed Interview → Specify → Plan → Detail into a single condensed flow; emits one work-root `SPEC.md` + `tasks/` (no features/, no REQUIREMENTS.md, no PLAN.md). | `canonical/skills/aid-interview/SKILL.md` `A lite work has **no \`features/\` folder` |
| **Full Path** | The standard pipeline — all four design phases run separately, REQUIREMENTS.md + per-feature SPEC.md + PLAN.md + tasks/. | `canonical/templates/work-state-template.md` `- **Path:** lite | full` |
| **Triage** | Description-first routing state inside `aid-interview`: the agent asks for a free-form work description, infers `workType + best-matching recipe` from it, and presents one confirmation turn. A confident single-recipe match routes to the lite path; an ambiguous, multi-target, or no-match description routes to full. Conservative — any signal short of one confirmed recipe routes full. | `canonical/skills/aid-interview/references/state-triage.md` `# State: TRIAGE` |
| **workType** | The kebab-normalized internal work type inferred by the TRIAGE agent from the user's description: `bug-fix | new-feature | refactor`. Never presented as a menu — derived by agent inference and recorded in `STATE.md ## Triage`. | `canonical/skills/aid-interview/references/state-triage.md` `# State: TRIAGE` |
| **LITE-BUG-FIX** | Sub-path for `bug-fix` workType. Typically 1 IMPLEMENT task (fix + regression test). | `canonical/skills/aid-interview/references/state-task-breakdown.md` `| LITE-BUG-FIX |` |
| **LITE-REFACTOR** | Sub-path for `refactor` workType. 1–3 REFACTOR + TEST tasks. Documentation/report revision work (`change-docs`/`change-report` recipes) also routes here — the single task is typed DOCUMENT. | `canonical/skills/aid-interview/references/state-task-breakdown.md` `| LITE-REFACTOR |` |
| **LITE-FEATURE** | Sub-path for `new-feature` workType. 1–5 IMPLEMENT + TEST + DOCUMENT tasks. New documentation/report work (`add-docs`/`add-report` recipes) also routes here — the typical single task is typed DOCUMENT. | `canonical/skills/aid-interview/references/state-task-breakdown.md` `| LITE-FEATURE |` |
| **CONDENSED-INTAKE (L1)** | Lite-path sub-path-specific slot-fill conversational interview; written by `aid-interviewer`. | `canonical/skills/aid-interview/SKILL.md` `| L1 CONDENSED-INTAKE |` |
| **TASK-BREAKDOWN (L2)** | Lite-path state — `aid-architect` proposes typed task breakdown directly from work-root SPEC. | `canonical/skills/aid-interview/references/state-task-breakdown.md` `# State: TASK-BREAKDOWN (L2)` |
| **LITE-REVIEW (L3)** | Lite-path pre-execution gate — `aid-reviewer` adversarially validates the task set against SPEC. | `canonical/skills/aid-interview/SKILL.md` `| L3 LITE-REVIEW |` |
| **LITE-DONE (L4)** | Lite-path terminal — hand-off prompt to `/aid-execute`. | `canonical/skills/aid-interview/SKILL.md` `| L4 LITE-DONE |` |
| **Escalated** | Path state where a work started on lite and was promoted to full mid-flight. `STATE.md ## Escalation Carry` block preserves slot answers + decisions to avoid re-asking. | `canonical/skills/aid-interview/SKILL.md` `\`Path: escalated\` is treated identically to \`Path: full\``, `canonical/templates/work-state-template.md` `## Escalation Carry` |

---

## Recipes (FR8 / feature-011)

| Term | Definition | Source |
|------|------------|--------|
| **Recipe** | Pre-filled lite-path template at `canonical/recipes/<name>.md`. YAML front-matter + body with `## spec` + `## tasks` blocks + `{{slot}}` placeholders. Eliminates redundant interview for recurring patterns. | `canonical/recipes/README.md` `# AID Recipes Catalog` |
| **Slot** | `{{slot-name}}` placeholder in a recipe body. Lexical rule: `[a-z][a-z0-9-]*`. Substituted at render via `parse-recipe.sh --render`. | `canonical/recipes/README.md` `### Slot Syntax` |
| **Slot escape** | `{!{` in recipe body — rewritten to literal `{{` at emit time (so recipes can quote slot syntax without triggering it). | `canonical/recipes/README.md` `**Escape sequence for literal \`{{\`:**` |
| **applies-to** | Recipe front-matter field — which `workType` this recipe matches (or `*` for cross-type). | `canonical/recipes/README.md` `Valid \`applies-to\` values:` |
| **Seed Catalog (51 recipes)** | 51 recipes across 4 groups: (1) 40 add/change pairs across 11 target-kind families (`new-feature`/`refactor`); (2) 7 bug-fix recipes (`fix-application`, `fix-infrastructure`, `fix-api`, `fix-ui`, `fix-integration`, `fix-regression`, `fix-security`); (3) 3 refactor-only recipes (`improve-performance`, `bump-dependency`, `rename-symbol`); (4) 1 cross-type recipe (`add-test-coverage`, `applies-to: *`). All 51 follow the `add-X`/`change-X`/`fix-X` naming convention. | `canonical/recipes/README.md` `## Seed Catalog` |

---

## Two-Tier Review (feature-004)

| Term | Definition | Source |
|------|------------|--------|
| **Quick-Check** | Per-task fast review by Small-tier `aid-reviewer`; NO grade loop; HIGH+ findings deferred to delivery gate. | `canonical/skills/aid-execute/SKILL.md` `| REVIEW | \`references/state-review.md\``, `canonical/scripts/execute/writeback-state.sh` `mode_findings()` (Quick Check Findings section) |
| **Delivery Gate** | Per-delivery full review by `aid-reviewer` (tier = complexity score); full review/fix/review loop with `grade.sh`. | `canonical/skills/aid-execute/SKILL.md` `| DELIVERY-GATE | \`references/state-delivery-gate.md\`` |
| **Complexity Score (Small / Medium / Large)** | Computed by `complexity-score.sh` from task count, depth, risk, consults — selects reviewer tier for the delivery gate. Thresholds: Low=6, High=14 default. | `canonical/scripts/execute/complexity-score.sh` `Default Low Threshold = 6; High Threshold = 14` |

---

## Parallel Pool Dispatch (feature-009)

| Term | Definition | Source |
|------|------------|--------|
| **Pool Dispatch** | The PD-0..PD-6 model used by `aid-execute` in delivery mode — continuous parallel pool replaces the serial task loop. | `canonical/skills/aid-execute/SKILL.md` `**Delivery-mode pool dispatch (FR6):**` |
| **MaxConcurrent** | The pool's parallel capacity — sourced from `.aid/settings.yml` `execution.max_parallel_tasks` (default 5). | `canonical/templates/settings.yml` `max_parallel_tasks: 5`, `canonical/skills/aid-execute/SKILL.md` `falls back to` |
| **Wait-for-any-completion** | Pool scheduling primitive — pool waits for any single task to finish before slotting the next. | `canonical/skills/aid-execute/SKILL.md` `**Delivery-mode pool dispatch (FR6):**` |
| **Failure Block Radius** | The transitive descendants of a failed task — all are marked Blocked. Computed by `compute-block-radius.sh` via BFS. | `canonical/scripts/execute/compute-block-radius.sh` `BFS transitive-descendant computation for FR6` |
| **Graceful Degradation** | When the host doesn't support `run_in_background: true`, pool falls back to MaxConcurrent=1 (sequential). User-visible notice + Calibration Log entry. | `canonical/skills/aid-execute/SKILL.md` `**Graceful degradation:**` |
| **Capability Probe (PD-0)** | The early pool step that detects whether the host supports backgrounded dispatch. | `canonical/skills/aid-execute/SKILL.md` `the \`run_in_background\` capability` |
| **EXECUTE-WAVE** | The named state inside `aid-execute` where pool dispatch runs. Includes AC4 Sub-unit Drill-down (re-rendered snapshot after each sub-unit transition). | `canonical/skills/aid-execute/SKILL.md` `### EXECUTE-WAVE: AC4 Sub-unit Drill-down` |
| **Sub-unit** | A subdivision of an EXECUTE-WAVE step (e.g., per-task progress within a wave). Drives the AC4 drill-down snapshot. | `canonical/skills/aid-execute/SKILL.md` `### EXECUTE-WAVE: AC4 Sub-unit Drill-down` |

---

## Subagent Visibility (work-003 traceability — always-on)

| Term | Definition | Source |
|------|------------|--------|
| **L1 ETA Bracket Pair** | `▶ <agent> starting (~LOW-HIGH)` / `✓ <agent> done in <actual>` — bracket on every long-running dispatch. ETAs from `rough-time-hints.md`. | `canonical/templates/long-wait-protocol.md` `### Step 2 — Emit opening bracket + arm 3 timers` |
| **L2 Check-In Timers** | Three backgrounded `sleep && echo` Bash dispatches at `LOW/2`, `LOW`, `1.5×LOW` minutes — each fires an in-narration check-in. Each must be its OWN `run_in_background: true` call (no `&` chaining). | `canonical/skills/aid-discover/SKILL.md` `DO NOT chain timers with \`&\` inside a single wrapper Bash call.`, `canonical/templates/long-wait-protocol.md` `Then arm THREE backgrounded shell timers` |
| **L3 Heartbeat File** | `.aid/.heartbeat/<agent>-<unix-ts>.txt` — pre-created by dispatcher; subagent overwrites every N minutes; single line pipe-delimited; deleted on completion. | `canonical/templates/subagent-heartbeat-protocol.md` `## Orchestrator-side responsibilities (dispatcher)` |
| **Calibration Log** | Per-work `STATE.md ## Calibration Log` section — every dispatch appends `\| YYYY-MM-DD \| agent \| task-id \| ETA-band \| actual \| notes \|`. Always-on, never optional. | `canonical/skills/aid-discover/SKILL.md` `Both are mandatory per work-003 traceability` |
| **Dispatches sub-column** | Per-task sub-column in `STATE.md ## Tasks Status` — records each dispatch attempt for the task. Always-on. | `canonical/skills/aid-discover/SKILL.md` `update the task's \`## Dispatches\` sub-column` |
| **heartbeat_interval** | `.aid/settings.yml` `traceability.heartbeat_interval` (integer minutes; default 1; `0` disables). | `canonical/templates/settings.yml` `heartbeat_interval: 1`, `canonical/templates/subagent-heartbeat-protocol.md` `## Configuration` |

---

## State Machine / FR2 Area-STATE

| Term | Definition | Source |
|------|------------|--------|
| **State Machine (per-skill)** | Every `aid-*` skill exits after one state and re-enters on the next slash-command invocation (no auto-advance per IQ9). Each SKILL.md has a Dispatch table = state machine. | `canonical/skills/aid-discover/SKILL.md` `aid-discover  ▸ one step per run`, `coding-standards.md §8d` |
| **FILESYSTEM IS THE ONLY SOURCE OF TRUTH** | Every state-detection block opens with this — skills never trust conversation memory; always read disk. | `canonical/skills/aid-execute/SKILL.md` `**FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**`, `canonical/skills/aid-discover/SKILL.md` `ALWAYS read actual files on disk.` |
| **State Entry Line** | The `[State: NAME] — <description>` print + "you are here" ASCII state-map emitted on every state entry. | `canonical/skills/aid-discover/SKILL.md` `aid-discover  ▸ you are here` |
| **Dispatch Table** | The canonical state-machine table in every thin-router SKILL.md (State / Detail / Worker / Advance columns). The three Advance forms: Unconditional, Halt, Conditional. | `canonical/skills/aid-execute/SKILL.md` `| State | Detail | Worker | Advance |`, `coding-standards.md §8d` |
| **FR2 Area-STATE Consolidation** | The per-work `STATE.md` is the per-area state hub; legacy per-feature `STATE.md` + per-task `STATE.md` files are RETIRED. | `coding-standards.md §7e`, `canonical/templates/work-state-template.md` `This is the single state file for **this work**` |
| **Housekeep Status** | The `## Housekeep Status` run-state block in the **project-level, transient** run-state file `.aid/.temp/HOUSEKEEP_STATE_<YYYYMMDDHHMM>.md` (gitignored; created on a fresh run, removed at DONE) — NOT a work-area STATE.md (`/aid-housekeep` is project maintenance). Written/read exclusively by `housekeep-state.sh`. Key-value shape (one `**Field:** value` per line — NOT a table; grep-recoverable), nine fields: `State`, `Stage Status`, `Branch`, `Mode`, `Stall Reason`, `Last Run`, `KB Stage`, `Summary Stage`, `Cleanup Stage`. The three stage-gate fields (each `passed | skipped | stalled | running | —`) drive the six-row resume table (`--resume`); `Mode` ∈ `full | cleanup-only`. Do NOT confuse with the discovery-area `STATE.md` or with "Pre-flight Cleanup". | `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (path resolved by `canonical/skills/aid-housekeep/SKILL.md` `## State Detection`), `canonical/scripts/housekeep/housekeep-state.sh` (`VALID_FIELDS`, `mode_resume()`) |
| **Thin-Router SKILL.md Convention** | When SKILL.md grows past ~200 lines, extract per-state bodies into `references/state-{name}.md`; keep router as Dispatch table + Pre-flight + State Detection. Caps at ~360 lines. | `coding-standards.md §7b`, `.aid/knowledge/project-structure.md` `Thin-Router (≤~360 lines)` |

---

## Grading / Review

| Term | Definition | Source |
|------|------------|--------|
| **Universal Grading Rubric** | One rubric across the pipeline: severity tags `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` → grade computed deterministically by `grade.sh`. Worst severity dominates the letter; count sets modifier. | `docs/aid-methodology.md` `#### Phase 2: Interview`, `canonical/scripts/grade.sh` `Apply the rubric: worst severity dominates, count determines the modifier.` |
| **Grade scale** | `A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F`. E band = critical-severity present. F = non-functional. | `canonical/skills/aid-discover/SKILL.md` `**Grade ordering** (highest to lowest):`, `canonical/scripts/grade.sh` `modifier_for_count()`, `canonical/templates/settings.yml` `# Valid grade values: A+, A, A-` |
| **minimum_grade** | The REVIEW exit criterion (default `A`). Per-skill overrides possible (`<skill>.minimum_grade`). | `canonical/templates/settings.yml` `review:` block + `# Optional per-skill overrides` |
| **Severity tag** | `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` — reviewer assigns; script computes grade. | `canonical/agents/aid-reviewer/AGENT.md` `## Severity Classification` |
| **Source tag** | `[CODE] [TASK] [SPEC] [KB] [ARCHITECTURE]` — reviewer tags issue origin; drives loopback routing. | `canonical/agents/aid-reviewer/AGENT.md` `## What You Do` |
| **Reviewer-Dispatch Protocol** | The 5-section brief contract for every reviewer dispatch: ARTIFACTS UNDER REVIEW / CONTEXT / RUBRIC / OUT OF SCOPE / OUT-OF-SCOPE FINDINGS POLICY / DELIVERABLES. Enforces scope discipline. | `canonical/templates/reviewer-dispatch.md` `## The brief structure` |
| **CONTEXT discipline** | "CONTEXT describes what the artifact IS. Does NOT describe what downstream consumers do with it." Prevents scope leak in reviewer briefs. | `canonical/templates/reviewer-dispatch.md` `#### CONTEXT discipline (the rule)` |
| **Out-of-Scope (OOS) findings** | Stray reviewer findings logged as `Status: OOS` rows in the 7-column ledger (not a separate section); excluded from severity counts and grade, with the routing destination noted in Description/Evidence. | `canonical/templates/reviewer-dispatch.md` `OUT-OF-SCOPE FINDINGS POLICY:` |
| **Two-Grade Gate** (summarize) | `aid-summarize` requires BOTH Machine Grade AND Human Grade ≥ minimum. Overall = lower of the two. V1=0 forces Human Grade = F. | `canonical/skills/aid-summarize/SKILL.md` `APPROVAL requires BOTH grades >= minimum.`, `canonical/scripts/summarize/grade-summary.sh` `Machine Grade  — auto-verifiable checks only` |
| **AUTO_POOL (summarize)** | Auto-checkable criteria pool: `D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2` (73 pts max). | `canonical/scripts/summarize/grade-summary.sh` `AUTO_POOL = D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2` |
| **MANUAL_POOL (summarize)** | Manual-checkable criteria pool: `K1 K2 V1` (30 pts max). | `canonical/scripts/summarize/grade-summary.sh` `MANUAL_POOL = K1 K2 V1` |
| **V1 visual gate** | Mandatory human visual check in `aid-summarize`. V1=0 forces Human Grade = F. | `canonical/scripts/summarize/grade-summary.sh` `V1 (human visual gate) is MANDATORY: V1=0 forces Human Grade = F.` |

---

## Feedback Loops (the 11 named loops)

| Term | Definition | Source |
|------|------------|--------|
| **Loop 1 — Interview→Discovery** | Q&A entry to DISCOVERY-STATE → targeted discovery → KB update → interview resumes. | `docs/aid-methodology.md` `**Loop 1: Interview → Discovery` |
| **Loop 2 — Specify→Discovery** | Specify pauses → Q&A → discovery → resume. | `docs/aid-methodology.md` `**Loop 2: Specify → Discovery` |
| **Loop 3 — Plan→Discovery** | Plan reveals codebase complexity → Q&A → discovery → resume. | `docs/aid-methodology.md` `**Loop 3: Plan → Discovery` |
| **Loop 4 — Plan→Specify** | KB OK but SPEC ambiguous → feature `STATE.md` Q&A → spec revision. | `docs/aid-methodology.md` `**Loop 4: Plan → Specify` |
| **Loop 5 — Detail→Plan** | Plan too vague to decompose → Plan revises → Detail resumes. | `docs/aid-methodology.md` `**Loop 5: Detail → Plan` |
| **Loop 6 — Execute→Discovery / Specify / Detail** | IMPEDIMENT routed by Type. | `docs/aid-methodology.md` `**Loop 6: Execute → Discovery / Specify / Detail` |
| **Loop 7 — Execute Review→upstream** | CODE auto-fixed; TASK/SPEC/KB issues escalate. | `docs/aid-methodology.md` `**Loop 7: Execute Review → Any Upstream Phase` |
| **Loop 8 — Deploy→Execute** | Deploy verification fails → back to Execute. | `docs/aid-methodology.md` `**Loop 8: Deploy → Execute` |
| **Loop 9 — Monitor→Interview** | BUG classification → Interview LITE-BUG-FIX triage → new task → Execute. The "short path." | `docs/aid-methodology.md` `**Loop 9: Monitor → Interview (Bug Path)` |
| **Loop 10 — Monitor→Interview** | Change Request → Interview (new/changed requirements) → full pipeline. | `docs/aid-methodology.md` `**Loop 10: Monitor → Interview (Change Request Path)` |
| **Loop 11 — Any→Discovery** | Cross-cutting targeted re-discovery — KB is always the return target; "the loop that makes the Knowledge Base the gravitational center." | `docs/aid-methodology.md` `**Loop 11: Any Phase → Discovery (Targeted Re-Discovery)` |
| **Targeted re-discovery** | Re-entry to Discovery that fills a specific gap; never a full redo. Triggered by a Pending Q&A entry with `**Impact:** Required` naming the docs to refresh; also driven on-demand by `/aid-housekeep`'s KB-DELTA stage (off-pipeline). | `docs/aid-methodology.md` `**Loop 11: Any Phase → Discovery (Targeted Re-Discovery)`, `canonical/skills/aid-discover/SKILL.md` `## Targeted Discovery (Re-entry)`, `canonical/skills/aid-housekeep/references/state-kb-delta.md` `## Step 4` |
| **Bug Path (short)** | Monitor → Interview (LITE-BUG-FIX) → Execute. Skips spec/plan because spec is already correct. | `docs/aid-methodology.md` `#### Post-Production Loops (9–10)`, `docs/aid-methodology.md` `#### Monitor (`aid-monitor`) — optional` |
| **Change Request Path (full cycle)** | Monitor → Interview → ... full pipeline from Interview. | `docs/aid-methodology.md` `#### Post-Production Loops (9–10)`, `docs/aid-methodology.md` `**Loop 10: Monitor → Interview (Change Request Path)` |

---

## Agents (22) & Tiers

| Term | Definition | Source |
|------|------------|--------|
| **Tier (Large / Medium / Small)** | Model size tier per agent. Maps to Claude (Opus/Sonnet/Haiku), Codex (gpt-5.5/gpt-5.4/gpt-5.4-mini), Cursor, Copilot CLI (claude-opus-4.8/sonnet-4.6/haiku-4.5), Antigravity (gemini-3-pro high/low, gemini-3-flash). | `profiles/claude-code.toml` `[model_tiers]`, `profiles/codex.toml` `[model_tiers.large]`, `profiles/copilot-cli.toml` `[model_tiers]`, `profiles/antigravity.toml` `[model_tiers.large]` |
| **Large-tier (4 agents)** | aid-interviewer, aid-architect, aid-researcher, aid-reviewer. | `.aid/knowledge/architecture.md` `## §3 Three-tier agent dispatch` |
| **Medium-tier (4 agents)** | aid-developer, aid-operator, aid-orchestrator, aid-tech-writer. | `.aid/knowledge/architecture.md` `## §3 Three-tier agent dispatch` |
| **Small-tier (1 agent)** | aid-clerk. | `.aid/knowledge/architecture.md` `## §3 Three-tier agent dispatch` |

---

## Distribution / Generator

| Term | Definition | Source |
|------|------------|--------|
| **canonical/** | Single source of truth for all install-tree content. Never edit profile trees directly — edit canonical and run `run_generator.py`. | `coding-standards.md §7a`, `.aid/knowledge/project-structure.md` `← SINGLE SOURCE OF TRUTH for all install-tree content` |
| **Profile** | A host-tool target spec — `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}.toml` (5). Defines output_root, frontmatter schema, model tiers, filename_map, capabilities. | `profiles/claude-code.toml` `[layout]`, `profiles/copilot-cli.toml` `[layout]`, `profiles/antigravity.toml` `[layout]` |
| **Install Tree** | One of the 5 per-profile output directories: `profiles/claude-code/.claude/`, `profiles/codex/{.codex,.agents}/`, `profiles/cursor/.cursor/`, `profiles/copilot-cli/.github/`, `profiles/antigravity/.agent/`. | `canonical/EMISSION-MANIFEST.md` `## Filename and Location`, `profiles/copilot-cli.toml` `[layout]`, `profiles/antigravity.toml` `[layout]` |
| **Dogfood Tree** | The top-level `.claude/` in this repo — AID applied to itself. Byte-identical body content to the claude-code profile output. NOT subject to KB claims (KB covers the 6-tree set: canonical + 5 profile trees). | `canonical/skills/aid-discover/SKILL.md` `this is the **dogfood install**`, `.aid/knowledge/project-structure.md` `**Dogfood \`.claude/\` tree.**` |
| **Emission Manifest** | `{profile}/emission-manifest.jsonl` — the authoritative safety boundary for pure-mirror deletion. JSONL records of (`profile`, `src`, `dst`, `sha256`), sorted by `dst`, LF endings, sentinel first line. | `canonical/EMISSION-MANIFEST.md` `# Emission Manifest — Design Specification` |
| **Pure-Mirror Deletion** | The generator's safety rule: only files in the previous manifest's `removed_dst` set are deleted; files outside any manifest are NEVER touched. | `canonical/EMISSION-MANIFEST.md` `## Safety-Boundary Semantics` |
| **Sentinel (manifest)** | The reserved first line `{"_manifest_version": 1}` enabling future schema evolution. | `canonical/EMISSION-MANIFEST.md` `## Versioning Sentinel` |
| **VERIFY (deterministic)** | The strict byte-identity verification — re-runs generator and asserts identical output (`verify_deterministic.py`). | `.aid/knowledge/project-structure.md` `verify_deterministic.py`, `.claude/skills/generate-profile/SKILL.md` `### VERIFY (deterministic) (hard gate)` |
| **VERIFY (advisory)** | The advisory verification — non-blocking warnings (`verify_advisory.py`). | `.aid/knowledge/project-structure.md` `verify_advisory.py`, `.claude/skills/generate-profile/SKILL.md` `### VERIFY (advisory) (advisory)` |
| **AC2** | The "byte-identical re-run" guarantee — re-running generator on unchanged inputs produces byte-identical install tree + byte-identical manifest. | `canonical/EMISSION-MANIFEST.md` `## Ordering` |
| **Split-root layout (Codex)** | Codex profile has TWO output roots: `profiles/codex/.codex/agents/` (TOML) + `profiles/codex/.agents/{skills,scripts,recipes,templates}/`. One manifest covers both. | `profiles/codex.toml` `Two-root layout: agents under agents_root`, `canonical/EMISSION-MANIFEST.md` `For Codex (split layout:` |
| **Filename map** | Per-profile substitution dictionary for canonical placeholders (`project_context_file`, `reviewer_output_file`, `open_questions_file`). | `profiles/claude-code.toml` `[filename_map]`, `profiles/codex.toml` `[filename_map]` |
| **Asset Kind** | A category of canonical source (agents / skills / templates / recipes / scripts) — each maps to an install-tree sub-directory per profile. | `canonical/EMISSION-MANIFEST.md` `## Asset Kinds` |
| **Passthrough Renderer** | Renderer that emits files without format conversion or frontmatter injection (e.g., recipes). | `canonical/EMISSION-MANIFEST.md` `passthrough renderer — no` |
| **Agent format** | `[agent].format` value selecting how `render_agents` emits a sub-agent. One of `markdown | toml | copilot-agent | antigravity-rule` (`_KNOWN_AGENT_FORMATS`). | `.claude/skills/generate-profile/scripts/aid_profile.py` `_KNOWN_AGENT_FORMATS` |
| **`copilot-agent` format** | Copilot CLI agent-format value: emits AID sub-agents as `.github/agents/*.agent.md` with `name/description/tools/model` frontmatter (`Bash`→`shell` via `[tool_names]`). | `profiles/copilot-cli.toml` `format = "copilot-agent"`, `profiles/copilot-cli/.github/agents/aid-architect.agent.md` |
| **`antigravity-rule` format** | Antigravity agent-format value: reshapes AID sub-agents into `.agent/rules/*.md` with `trigger:`-style frontmatter (personas → `trigger: always_on`). Reuses the new-agent-format branch; NOT copilot-agent output. | `profiles/antigravity.toml` `format = "antigravity-rule"`, `profiles/antigravity/.agent/rules/aid-reviewer.md` |
| **Native Agent Skills mapping** | For Copilot CLI and Antigravity, AID skills are emitted as the host's **native** skills primitive — folder copies at `.github/skills/<slug>/SKILL.md` (Copilot) / `.agent/skills/<slug>/SKILL.md` (Antigravity) via the existing `render_skills` pass, no `emit_as` knob, preserving canonical frontmatter verbatim ([data]). | `profiles/copilot-cli.toml` `[skill]`, `profiles/antigravity.toml` `[skill]` |
| **`rules_frontmatter` trigger-dialect** | Gated `[extras] rules_frontmatter = "trigger"` knob (Antigravity): `_render_cursor_extras` strips the source `.mdc` frontmatter and regenerates `trigger:/description/globs` keys from `RuleEntry` fields (`always_apply=true`→`trigger: always_on`; `false`→`trigger: glob` + globs). Default `None` (cursor) → verbatim copy → cursor byte-identical. Decoupled from `[agent].format`. | `profiles/antigravity.toml` `[extras]` `rules_frontmatter = "trigger"`, `.claude/skills/generate-profile/scripts/aid_profile.py` `rules_frontmatter` |
| **`RuleEntry.output_filename`** | Per-rule `[[extras.rules]] output_filename` enabling a `.mdc`→`.md` rename for methodology rules (Antigravity emits `.md`; cursor leaves it unset → source name preserved → cursor byte-identical). | `profiles/antigravity.toml` `[[extras.rules]]` `output_filename = "aid-methodology.md"`, `.claude/skills/generate-profile/scripts/aid_profile.py` `output_filename` |
| **MCP omission ([omit])** | All profiles emit no MCP config — no `[mcp]` table in any profile TOML because the repo ships zero MCP servers; Copilot CLI specifically omits `mcp-config.json`. | `profiles/copilot-cli.toml` `No [mcp] table`, `profiles/antigravity.toml` `No [mcp] table` |
| **Invariant root `AGENTS.md` (FR12)** | The four AGENTS.md-writing tools (Codex, Cursor, Copilot CLI, Antigravity) now ship a **byte-identical** root `AGENTS.md`, so installing a second AGENTS.md-writing tool is up-to-date rather than a collision. This replaced the former Option-A last-installed-wins collision dance (the old `setup.sh`/`setup.ps1` `AGENTS_COLLISION` survivor handler, removed with those installers). Claude Code uses `CLAUDE.md` and is exempt. A CI guard asserts the four profile copies are identical. | `tests/canonical/test-agents-md-invariant.sh` (byte-identity guard); `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md` |
| **`aid` CLI** | The persistent global end-user installer — a Bash dispatcher (`bin/aid`) on macOS/Linux/WSL/git-bash and a PowerShell dispatcher (`bin/aid.ps1`, with `bin/aid.cmd` shim) on Windows, backed by the shared install cores `lib/aid-install-core.sh` / `lib/AidInstallCore.psm1`. Bootstrapped once per machine via `install.sh` / `install.ps1` (or the npm/PyPI `aid-installer` packages), then invoked per project: `aid add/update/remove <tool>`, `aid status`, `aid version`. `aid add` fetches+verifies the matching release tarball (or installs offline via `--from-bundle <tar>`), copies the profile subtree, applies FR11 protect-on-diff, and records `.aid/.aid-manifest.json`. (Replaced the former `setup.sh`/`setup.ps1` clone+run menu installers, which were removed.) | `bin/aid` `_aid_usage`, `lib/aid-install-core.sh` `install_tool`, `install.sh`, `.aid/knowledge/infrastructure.md` `## Install Pipeline` |
| **FR11 protect-on-diff** | When `aid add`/`aid update` would overwrite a root agent file (`CLAUDE.md` / `AGENTS.md`) that the user authored or modified themselves, the incoming version is written as `<file>.aid-new` for review (exit 5, WARN) rather than overwritten silently; `--force` overrides. AID ownership is tracked by the recorded sha256 in the manifest's `root_agent_files` entry. | `lib/aid-install-core.sh` `_copy_root_agent_file` (the `.aid-new` write + WARN), `docs/install.md` `## Protect-on-diff for root agent files` |

---

## Settings & Configuration

| Term | Definition | Source |
|------|------------|--------|
| **.aid/settings.yml** | Single source of truth for AID pipeline settings (grades, parallelism, heartbeat, project identity). Managed by `/aid-config`. | `canonical/templates/settings.yml` `project:` block |
| **review.minimum_grade** | Global REVIEW exit criterion (default `A`). | `canonical/templates/settings.yml` `review:` block |
| **execution.max_parallel_tasks** | Pool dispatch capacity (default 5). | `canonical/templates/settings.yml` `max_parallel_tasks: 5` |
| **traceability.heartbeat_interval** | Heartbeat cadence in minutes (default 1; `0` disables). | `canonical/templates/settings.yml` `heartbeat_interval: 1` |
| **Per-skill override** | `<skill>.minimum_grade` (e.g., `discover.minimum_grade: A+`) — overrides global. | `canonical/templates/settings.yml` `# Optional per-skill overrides` |
| **Resolution order (read-setting.sh skill mode)** | Per-skill override → `review.<key>` → script `--default` → exit 1. | `canonical/scripts/config/read-setting.sh` `Skill mode: try per-skill override; fall back to review.<key>; fall back to --default` |
| **read-setting.sh Skill Mode** | `--skill X --key Y --default V` — applies override resolution. | `canonical/scripts/config/read-setting.sh` `--skill X --key Y     # Resolves X.Y if present, else review.Y, else default` |
| **read-setting.sh Path Mode** | `--path A.B --default V` — direct dotted-path lookup, no override resolution. | `canonical/scripts/config/read-setting.sh` `--path A.B            # Direct dotted-path lookup, no override resolution` |

---

## Repository / Workflow Conventions

| Term | Definition | Source |
|------|------------|--------|
| **Single-Branch Work** | For ANY `work-NNN`, commit to ONE persistent branch (off master); no per-task worktrees or branches. Root cause of PR #12 losing 63 commits. | `coding-standards.md §7f`; `tech-debt.md H1` history |
| **work-NNN branch convention** | Persistent `work-NNN` branch (off master); PR `work-NNN → master` when ready. | user-memory `project_work-branch-convention.md` |
| **aid/housekeep-* branch** | The dedicated branch `/aid-housekeep` operates on (created off master via `git switch -c`, or reused on resume). One commit per stage; the skill never pushes. Distinct from `aid/{work}-delivery-NNN` (Execute) and `work-NNN` branches. | `canonical/scripts/housekeep/branch-commit.sh` (`aid/housekeep-<slug>`, "Never runs `git push`"), `canonical/skills/aid-housekeep/SKILL.md` `aid/housekeep-*` |
| **Pre-flight Cleanup** | Orchestrator-only KB sweep before reviewer dispatch — line-count drift, off-by-1, ghost references, path/citation hygiene. These are housekeeping items; never grade them. Distinct from the `/aid-housekeep` skill (an optional off-pipeline drift-reconciliation skill — see "Housekeep / KB-drift reconciliation"). | `canonical/skills/aid-discover/SKILL.md` `## ⚠️ Pre-flight Cleanup (orchestrator-only — never grade these)` |
| **Quadruple Mirror** | The file-multiplication effect: each unique canonical helper script now has 7 byte-identical copies: canonical + dogfood `.claude/` + 5 profile trees (claude-code, codex, cursor, copilot-cli, antigravity). Inflates file counts. (Name predates the 3→5 profile growth; copy count is now 7, not 4.) | `.aid/knowledge/project-structure.md` `**Quadruple mirror.**`, `profiles/*.toml` (5 profiles) |
| **Cycle (discovery)** | One full pass through GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL. KB authoring uses cycle numbering. | `STATE.md ## Review History` |
| **Pass (discovery cycle internals)** | A sub-iteration inside a cycle. | `STATE.md ## Review History` |

---

## Universal Loop Cycle (Specify / Plan / Detail / Specify-section)

| Term | Definition | Source |
|------|------------|--------|
| **PROPOSE** | Step 1 of the universal loop — agent proposes a concrete solution grounded in KB / codebase / SPEC. | `docs/aid-methodology.md` `#### Phase 3: Specify`, `canonical/skills/aid-specify/SKILL.md` `1. PROPOSE  → agent proposes (grounded in KB, codebase, SPEC)` |
| **DISCUSS** | Step 2 — developer validates, adjusts, redirects. Agent pushes back on contradictions, presents trade-offs. | `docs/aid-methodology.md` `#### Phase 3: Specify` |
| **WRITE** | Step 3 — the agreed content is written to the target artifact. | `docs/aid-methodology.md` `#### Phase 3: Specify` |
| **REVIEW** | Step 4 — agent verifies what was written against KB / codebase reality. Pass → next section. Fail → back to PROPOSE. | `docs/aid-methodology.md` `#### Phase 3: Specify` |
| **Re-run = enter at step 4** | Re-running a design-phase skill enters at REVIEW with existing content — the same loop handles both creation and maintenance. | `docs/aid-methodology.md` `**Re-run = enter at step 4 with existing content.**`, `canonical/skills/aid-specify/SKILL.md` `**Re-run = enter at step 4 with existing content.**` |

---

## Miscellaneous Domain Vocabulary

| Term | Definition | Source |
|------|------------|--------|
| **Adversarial Reviewer** | `aid-reviewer` is structurally adversarial to the developer — never grades its own work. Separation prevents bias. | `canonical/agents/aid-reviewer/AGENT.md` `You are adversarial to the Developer by design.`, `docs/aid-methodology.md` `**Oversights**` row |
| **Clean Context** | The reviewer is dispatched in a clean context (no chat history with the executor) — guarantees independent assessment. | `canonical/skills/aid-execute/SKILL.md` `Grading task output against acceptance criteria with a clean-context reviewer.` |
| **Hypothesis vs Knowledge (specs)** | "A spec written before implementation is a hypothesis. A spec revised after implementation is knowledge." | `docs/aid-methodology.md` `**2. Specs Are Living Documents**` |
| **Spec-as-Hypothesis** | Treats SPEC.md as a living artifact with formal revision protocols — every change is tracked, justified, approved. | `docs/aid-methodology.md` `**Drift**` row, `docs/aid-methodology.md` `**2. Specs Are Living Documents**` |
| **Spike** | A pause in `aid-specify` for investigation; records what needs research. | `docs/aid-methodology.md` `#### Phase 3: Specify`, `canonical/skills/aid-specify/SKILL.md` `SPIKE / BLOCKED are loopback states that return to CONTINUE` |
| **Execution Graph** | Dependency + parallel-wave tables appended to PLAN.md by Detail. Drives `aid-execute` task ordering + pool dispatch. | `docs/aid-methodology.md` `#### Phase 5: Detail`, `canonical/skills/aid-execute/SKILL.md` `Execution follows the **Execution Graph** in PLAN.md.` |
| **Wave** | A group of tasks that can be executed in parallel (no inter-dependencies). Drives EXECUTE-WAVE pool dispatch. | `canonical/templates/work-state-template.md` `## Tasks Status` |
| **Failure Tolerance** | EXECUTE-WAVE policy for handling failed sub-units — see `state-execute-drilldown.md` `### Failure Tolerance`. | `canonical/skills/aid-execute/SKILL.md` `\`references/state-execute-drilldown.md\`` |
| **Circuit Breaker** | The Execute review loop's safety stop: if grade hasn't improved (same or worse) after 3 consecutive cycles, halt. | `docs/aid-methodology.md` `Circuit breaker if the grade has not improved` |
| **Stale-Check** | The `aid-summarize` state that compares `LAST_KB_CHANGE_DATE` vs `LAST_SUMMARY_DATE` to decide whether to regenerate the HTML. | `canonical/skills/aid-summarize/SKILL.md` `STALE-CHECK first (always):` |
| **Knowledge Summary** | The single self-contained `.aid/knowledge/knowledge-summary.html` produced by `aid-summarize`. Offline, light/dark, accessible, Mermaid-rendered. | `canonical/skills/aid-summarize/SKILL.md` `Generates a single self-contained \`knowledge-summary.html\`` |
| **Profile (summarize)** | One of `auto | web-app | library | cli | microservices | data-pipeline | agentic-pipeline` — drives section-template selection for the knowledge-summary HTML. | `canonical/skills/aid-summarize/SKILL.md` `| \`--profile X\` | Force a specific profile.` |
| **Target diagrams** | Per-profile minimum diagram count for the knowledge-summary; if actual < target, grade capped at C+. | `canonical/scripts/summarize/grade-summary.sh` `If actual diagram count < target, grade is capped at C+.` |
| **WCAG AA** | The accessibility floor for knowledge-summary HTML output (color contrast, keyboard nav, semantic markup). | `canonical/skills/aid-summarize/SKILL.md` `meets` + `WCAG AA contrast in both themes.` |
| **Lightbox** | Click-to-expand modal for diagrams in the knowledge-summary HTML. Implemented in `canonical/templates/knowledge-summary/lightbox.js` (359 lines). | `canonical/skills/aid-summarize/SKILL.md` `keyboard-accessible click-to-expand lightboxes`, `.aid/knowledge/project-structure.md` `lightbox.js 359 lines` |
| **Plan Mode (Claude Code)** | A read-only mode that blocks file writes. Pre-flight checks in writing skills detect and abort. | `canonical/skills/aid-discover/SKILL.md` `Tell user to press \`Shift+Tab\` to exit Plan Mode`, `canonical/skills/aid-execute/SKILL.md` `### Check 4: Verify Not in Plan Mode` |
| **Auto-Accept Edits** | Claude Code mode that allows writes without confirmation. Compatible with AID skills. | `canonical/skills/aid-execute/SKILL.md` `### Check 4: Verify Not in Plan Mode` |
| **`--reset` flag** | Universal flag on aid-* skills — clears the artifact set the skill owns and restarts from scratch. | `canonical/skills/aid-discover/SKILL.md` `Clear entire \`.aid/knowledge/\` directory and restart from scratch.`, `canonical/skills/aid-interview/SKILL.md` `| \`--reset work-NNN\` |`, etc. |
| **`--grade X` flag** | Universal flag — overrides the minimum acceptable grade for this skill. Persisted to STATE.md / settings.yml. | `canonical/skills/aid-discover/SKILL.md` `Set minimum acceptable grade.`, `canonical/skills/aid-summarize/SKILL.md` `| \`--grade X\` | Override the minimum acceptable grade.` |
| **`--cleanup-only` flag (housekeep)** | `/aid-housekeep` flag that jumps straight to the CLEANUP stage (sets `**Mode:** cleanup-only`), bypassing KB-DELTA + SUMMARY-DELTA; any `--grade X` is then ignored. | `canonical/skills/aid-housekeep/SKILL.md` `## Arguments` (`--cleanup-only`) |
| **`--non-functional` (grade.sh)** | Flag that forces grade = F (build/run failed or produced no usable output). | `canonical/scripts/grade.sh` `--non-functional` |
| **STATE.md Q&A (Pending)** | The section in `.aid/knowledge/STATE.md` (Discovery area STATE) where loopback questions from downstream phases accumulate until Discover's Q-AND-A state resolves them. Also where `/aid-housekeep` KB-DELTA writes its synthesized `**Impact:** Required` entry. | `canonical/skills/aid-discover/SKILL.md` `If any Pending with \`**Impact:** Required\` → **Q-AND-A**`, `canonical/skills/aid-housekeep/references/state-kb-delta.md` `## Step 4` |
| **Cross-phase Q&A** | The `STATE.md ## Cross-phase Q&A (Pending)` section on work `STATE.md` — consolidated open questions across all phases of one work. | `canonical/templates/work-state-template.md` `## Cross-phase Q&A (Pending)` |
| **Escalation Carry** | The `STATE.md ## Escalation Carry` block written by lite→full escalation; preserves slot values + decisions to avoid re-asking during CONTINUE. | `canonical/templates/work-state-template.md` `## Escalation Carry`, `canonical/skills/aid-interview/SKILL.md` `The \`## Escalation Carry\`` |
| **DELIVERY-GATE** | The Execute state where the delivery-gate reviewer runs (full review/fix loop with `grade.sh` determinism). | `canonical/skills/aid-execute/SKILL.md` `| DELIVERY-GATE | \`references/state-delivery-gate.md\`` |
| **Quick Check Findings** | The `STATE.md ## Quick Check Findings` section where per-task quick-check HIGH+ findings accumulate for the delivery gate aggregator. | `canonical/scripts/execute/writeback-state.sh` `Write/replace the ### task-NNN block under ## Quick Check Findings` |
| **Delivery Gates** | The `STATE.md ## Delivery Gates` section where per-delivery review verdicts are recorded. | `canonical/scripts/execute/writeback-state.sh` `Write/replace the ### delivery-NNN block under ## Delivery Gates` |
| **delivery-NNN-issues.md** | Per-delivery issue log inside the work directory. Append-only via `writeback-state.sh --delivery-id NNN --append-issue`. | `canonical/scripts/execute/writeback-state.sh` `Append a single issue row to the delivery's delivery-NNN-issues.md.` |
| **Sentinel-File Lock** | The concurrency primitive used by `writeback-state.sh` and `parse-recipe.sh --render`: `set -o noclobber` + atomic create + sleep-poll retry. | `canonical/scripts/execute/writeback-state.sh` `Uses a sentinel-file lock (set -o` |
| **AID Workspace** | `.aid/` — the runtime root for all KB + work artifacts. Gitignore convention varies (committed vs ignored is user choice). | `canonical/skills/aid-interview/SKILL.md` `AID workspace not found. Run /aid-config first` |
| **Run** | One invocation of an aid-* slash command. Each run advances one state (no auto-advance). | `canonical/skills/aid-discover/SKILL.md` `each \`/aid-discover\` invocation drives the state machine until it hits a natural pause point` |
| **One question at a time** | Interview discipline — never batch multiple questions in a single turn. User-memory rule `feedback_one-question-at-a-time.md`. | `docs/aid-methodology.md` `#### Phase 2: Interview`, user memory |
| **Wait for responses** | When the user says wait or has open questions, do NOT proceed on assumed intent. User-memory rule `feedback_wait-when-told.md`. | user memory |
| **Subjective-Issue Collaboration** | For human-detected/subjective issues: expose → propose → ask; never fix autonomously. User-memory rule. | user memory `feedback_subjective-issue-collaboration.md` |
| **No Effort-Dodging** | Do what is asked or give a concrete specific reason; never vague hand-waves, never defer doable work. User-memory rule. | user memory `feedback_no-effort-dodging.md` |
| **rough-time-hints.md** | The current measured ETA table per subagent operation class. Source of L1 ETA bands. | `canonical/skills/aid-discover/SKILL.md` `Look up ETA** in \`canonical/templates/rough-time-hints.md\``, `.aid/knowledge/project-structure.md` `rough-time-hints.md` |

---

## Glossary Statistics

- **Total terms defined:** ~209 (across 16 categorical groups above; +5 housekeep terms added in the aid-housekeep / PR #49 update — "Housekeep / KB-drift reconciliation", "Housekeep Status", "aid/housekeep-* branch", "`--cleanup-only` flag (housekeep)", and the targeted-re-discovery/Q&A cross-references; +9 distribution terms added in the work-001-add-providers update; counted by row audit of this document)
- **Primary sources:** `docs/aid-methodology.md` (the methodology spec), `docs/glossary.md`, 12 user-facing canonical SKILL.md files (+ maintainer-only generate-profile), 9 canonical AGENT.md files, `canonical/EMISSION-MANIFEST.md` (152 lines), `canonical/templates/{settings.yml, work-state-template.md, subagent-heartbeat-protocol.md, long-wait-protocol.md, reviewer-dispatch.md, feedback-artifacts/IMPEDIMENT.md}`, helper scripts under `canonical/scripts/` (config/, execute/, housekeep/, interview/, kb/, summarize/)
- **Every entry cites at least one durable-anchor source** (file path + grep-recoverable symbol/heading/string, no line numbers). ⚠️ Inferred-from-code annotations are explicit where used.
