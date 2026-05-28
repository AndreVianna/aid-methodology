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
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Domain Glossary

> Terms mined from `methodology/aid-methodology.md` (1,070-line spec),
> `docs/glossary.md`, `CLAUDE.md`, `canonical/skills/*/SKILL.md` frontmatter and bodies,
> `canonical/agents/*/AGENT.md`, `canonical/EMISSION-MANIFEST.md`,
> `canonical/templates/*.md`, `canonical/scripts/**/*.sh`, and the work-state template.
>
> The AID repo has its own dense vocabulary — phases, states, work types, sub-paths,
> traceability layers, rubric tiers, and integration mechanisms — that any agent
> operating in this repo must know. Each entry cites `path:line` evidence.

---

## Core Methodology

| Term | Definition (inferred from usage) | Source |
|------|----------------------------------|--------|
| **AID** | "AI Integrated Development" — a structured methodology for building/maintaining software with AI agents; 8 phases in 5 groups, every phase co-executed by human + AI. | `methodology/aid-methodology.md:1`, `CLAUDE.md:5`, `docs/glossary.md:9` |
| **Iron Man Model** | The human-AI collaboration philosophy: AI is the suit (amplifies capability); human is the pilot (sets direction, decisions). Human never leaves the cockpit. | `methodology/aid-methodology.md:13`, `docs/glossary.md:17` |
| **Director** | Role — the human. Sets direction, makes decisions, reviews artifacts, approves phase transitions. Orchestrates, doesn't code. | `methodology/aid-methodology.md:115` |
| **Orchestrator** | Role — an AI agent (or human). Manages the pipeline: spawns agents, routes feedback loops, enforces quality gates, maintains KB. | `methodology/aid-methodology.md:116` |
| **Specialist** | Role — an AI coding agent. Executes tasks within defined scope. Reports impediments rather than working around them. | `methodology/aid-methodology.md:117` |
| **Phase Gate** | Human decision point between phases. The human reviews phase output and approves advancement. "OK?" is the gate. | `docs/glossary.md:15` |
| **Determinism Test** | "Can you write a complete set of rules to validate the outcome?" If yes, automate fully; if no, keep a human in the loop. Used to decide automation depth per phase. | `docs/glossary.md:76` |
| **Brownfield** | An existing codebase with history, technical debt, and undocumented knowledge. Discovery phase is designed for brownfield. | `docs/glossary.md:72`, `canonical/templates/settings.yml:17` |
| **Greenfield** | A new project with no existing code. Runs `aid-config` first, then skips Discovery, starts at Interview. | `docs/glossary.md:74`, `methodology/aid-methodology.md:270-271` |
| **SDD** | "Spec-Driven Development" — a methodology where specs drive code generation. AID contains SDD as a subset and extends it with discovery, two-level planning, feedback loops, and post-deployment phases. | `docs/glossary.md:70` |

---

## Pipeline Phases (the 8)

| Term | Group | Skill | Definition | Source |
|------|-------|-------|------------|--------|
| **Discover** | Prepare | `aid-discover` | Phase 1 — Understand the existing system; produces the KB. State machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE. | `methodology/aid-methodology.md:244-273`, `canonical/skills/aid-discover/SKILL.md:7` |
| **Interview** | Define | `aid-interview` | Phase 2 — Gather requirements one question at a time; produces REQUIREMENTS.md + per-feature SPEC.md (requirements side). | `methodology/aid-methodology.md:289-339`, `canonical/skills/aid-interview/SKILL.md:1-30` |
| **Specify** | Define | `aid-specify` | Phase 3 — Technical refinement per feature; agent acts as tech lead, proposes solutions, writes Technical Specification into SPEC.md. | `methodology/aid-methodology.md:341-368` |
| **Plan** | Map | `aid-plan` | Phase 4 — Sequence features into deliverables, each a functional MVP. Plan answers ONE question: order + standalone-functionality. | `methodology/aid-methodology.md:378-400` |
| **Detail** | Map | `aid-detail` | Phase 5 — Decompose each deliverable into PR-sized typed tasks. "Ultimate breakdown." | `methodology/aid-methodology.md:402-426` |
| **Execute** | Execute | `aid-execute` | Phase 6 — Execute a task per its Type; built-in two-tier review (per-task quick-check + per-delivery gate). One branch per delivery. | `methodology/aid-methodology.md:436-469` |
| **Deploy** | Deliver | `aid-deploy` | Phase 7 — Bundle deliveries into a release; final verification (build + tests + lint); ship per `infrastructure.md § Deployment`. Routes KB-affecting discoveries to Discovery (never edits KB directly). | `methodology/aid-methodology.md:479-497` |
| **Monitor** | Deliver | `aid-monitor` | Phase 8 — Observe production; classify findings (BUG/CR/Infra/No Action); route. The short path (BUG → Execute) skips spec/plan. | `methodology/aid-methodology.md:499-520` |

---

## Non-Phase Skills

| Term | Skill | Definition | Source |
|------|-------|------------|--------|
| **Config** | `aid-config` | Bootstrap skill; runs once before the pipeline. Creates `.aid/settings.yml` + 16 KB doc scaffolds + `AGENTS.md`/`CLAUDE.md` + `INDEX.md` placeholders + `DISCOVERY-STATE.md`. | `docs/glossary.md:23`, `methodology/aid-methodology.md:276-279` |
| **Summarize** | `aid-summarize` | Optional read-only skill; generates `knowledge-summary.html` from approved KB. Idempotent. WCAG-AA accessibility-first. | `methodology/aid-methodology.md:278-279`, `canonical/skills/aid-summarize/SKILL.md:1-30` |
| **Generate** | `aid-generate` | Maintainer-only skill; renders `canonical/` → 3 profile install trees. Wrapped by `run_generator.py`. | `.claude/skills/aid-generate/SKILL.md:1-20` |

---

## Knowledge Base (KB)

| Term | Definition | Source |
|------|------------|--------|
| **Knowledge Base / KB** | `.aid/knowledge/` — 14 active standard markdown documents + 3 meta-documents + 1 generated pre-pass (started as 16; security-model merged into coding-standards §11; ui-architecture pending repo-presentation.md replacement). The gravitational center of AID — every phase reads from it; any phase can update it. | `methodology/aid-methodology.md:123-125`, `docs/glossary.md:11` |
| **INDEX.md** | Meta — 2-3 line summary of every KB document; included in every task context for self-serve KB navigation. | `methodology/aid-methodology.md:131`, `methodology/aid-methodology.md:185-221` |
| **README.md (KB)** | Meta — tracks completeness status (Complete / Partial / Missing) per KB document. | `methodology/aid-methodology.md:132`, `methodology/aid-methodology.md:154-167` |
| **DISCOVERY-STATE.md** | Meta — discovery grade, Q&A entries, review history. Pre-FR2 name; post-FR2 consolidated into `.aid/knowledge/STATE.md`. | `methodology/aid-methodology.md:133`, `canonical/templates/discovery-state-template.md` |
| **project-index.md** | Generated — file-inventory pre-pass for discovery sub-agents (1,148 lines in this repo). Built by `build-project-index.sh`. | `methodology/aid-methodology.md:134`, `project-structure.md` |
| **15 KB docs (the active set)** | `project-structure.md`, `external-sources.md`, `architecture.md`, `technology-stack.md`, `module-map.md`, `coding-standards.md`, `schemas.md` (was `data-model.md`), `pipeline-contracts.md` (was `api-contracts.md`), `integration-map.md`, `domain-glossary.md`, `test-landscape.md`, `tech-debt.md`, `infrastructure.md`, `repo-presentation.md` (NEW — replaced `ui-architecture.md` per Q3), `feature-inventory.md`. Removed: `security-model.md` (content in `coding-standards.md §11`), `ui-architecture.md` (replaced by `repo-presentation.md` in cycle-1 Phase B). | `methodology/aid-methodology.md:136-151` |
| **Tier 1 / Tier 2 / Tier 3 (context economy)** | Tier 1 = INDEX.md (always loaded). Tier 2 = one KB doc on demand. Tier 3 = exact `path:line` via citation. "RAG by convention" — no embeddings/vector DB. | `methodology/aid-methodology.md:211-219` |
| **Context Feeding Strategy** | The protocol by which agents are given KB context: always include INDEX.md; orchestrator pre-selects 2-4 relevant KB docs; agent self-serves additional docs via INDEX. | `methodology/aid-methodology.md:179-219` |
| **Path:line citation** | Every factual KB claim carries an inline `path:line` reference. Anchors facts to source. Enables Tier 3 jump. | `methodology/aid-methodology.md:101` (Hallucination row) |

---

## Workspace / Artifacts

| Term | Definition | Source |
|------|------------|--------|
| **Work** | A self-contained scope unit at `.aid/work-NNN-{name}/`. One interview = one work. Multiple works coexist; each has its own requirements + features; all share the KB. | `methodology/aid-methodology.md:295-312` |
| **Feature** | A discrete capability inside a work. Lives at `.aid/{work}/features/feature-NNN-{name}/` with its own `SPEC.md`. Created by `aid-interview` Feature Decomposition state. | `methodology/aid-methodology.md:303-310` |
| **Delivery / Deliverable** | A subset of features grouped by `aid-plan` such that the group is a standalone-functional MVP. One branch per delivery (`aid/delivery-NNN`). | `methodology/aid-methodology.md:380-395`, `canonical/skills/aid-execute/SKILL.md:53-57` |
| **Task** | The atomic unit produced by `aid-detail`. `task-NNN.md` — 6 sections (Title, Type, Source, Depends on, Scope, Acceptance Criteria). One task = one agent session = one PR. | `methodology/aid-methodology.md:419-421`, `canonical/skills/aid-execute/SKILL.md:28-34` |
| **Package** | A release artifact bundling one or more completed deliveries. `package-NNN-{name}.md` per shipped package. | `methodology/aid-methodology.md:482-494` |
| **REQUIREMENTS.md** | The product-of-Interview document; one per work (full path only). Frozen after approval (rev-tracked). Holds Objective / Problem / Scope / FRs / NFRs / Constraints / Acceptance / Priority. | `methodology/aid-methodology.md:328`, `methodology/aid-methodology.md:337` |
| **SPEC.md (per-feature)** | Per-feature spec; requirements side (from Interview) + technical side (from Specify). | `methodology/aid-methodology.md:303-310` |
| **SPEC.md (work-root, lite path)** | A single consolidated work-root SPEC.md in lite path (no features/ folder, no REQUIREMENTS.md, no PLAN.md). | `canonical/skills/aid-interview/SKILL.md:48-61` |
| **PLAN.md** | The product-of-Plan document; ordered deliverables + optional cross-cutting risks + deferred features + Execution Graph (appended by Detail). | `methodology/aid-methodology.md:395`, `methodology/aid-methodology.md:421` |
| **known-issues.md** | Living issue log per work; created when the first issue is registered. Read by Plan, Execute, Deploy, Monitor. | `methodology/aid-methodology.md:698` |
| **MONITOR-STATE.md** | The product-of-Monitor file: last-run log + active findings + resolved findings. | `methodology/aid-methodology.md:50`, `methodology/aid-methodology.md:519-520` |
| **IMPEDIMENT-task-NNN.md** | Written by `aid-execute` when it discovers an assumption that doesn't hold. Has Type (wrong-assumption / missing-dependency / architecture-conflict / kb-gap), Options, Recommendation. The human decides. | `canonical/templates/feedback-artifacts/IMPEDIMENT.md:1-60`, `methodology/aid-methodology.md:663-680` |
| **Q&A entry** | Universal loopback artifact appended to a STATE file. Schema (Style A): `### Q{N}` + sub-bullets `Category`, `Impact`, `Status`, `Context`, `Suggested`, `Answer` (per `coding-standards.md §12`). | `methodology/aid-methodology.md:652-661`, `coding-standards.md §12` |
| **Revision History / Change Log** | Inline rev-tracking table on every artifact. Distinct from process state. | `methodology/aid-methodology.md:638-648`, `canonical/templates/work-state-template.md:11` |

---

## Task Types (8 — drive both Execute behavior + reviewer criteria)

| Term | Definition | Source |
|------|------------|--------|
| **RESEARCH** | Investigate, compare options, document findings. May skip branch isolation if only `.aid/` artifacts. | `methodology/aid-methodology.md:443`, `canonical/skills/aid-execute/SKILL.md:70-71` |
| **DESIGN** | Mockups, wireframes, UI prototypes, interaction flows. | `methodology/aid-methodology.md:444` |
| **IMPLEMENT** | Write code + unit tests. | `methodology/aid-methodology.md:445` |
| **TEST** | Integration, E2E, UI, load tests. | `methodology/aid-methodology.md:446` |
| **DOCUMENT** | ADRs, API docs, runbooks, diagrams. May skip branch isolation. | `methodology/aid-methodology.md:447` |
| **MIGRATE** | Data migration scripts, schema changes. | `methodology/aid-methodology.md:448` |
| **REFACTOR** | Restructure code without changing behavior. | `methodology/aid-methodology.md:449` |
| **CONFIGURE** | Config files, CI/CD, environment setup. | `methodology/aid-methodology.md:450` |

---

## Lite Path / Sub-Paths (feature-005)

| Term | Definition | Source |
|------|------------|--------|
| **Lite Path** | Collapsed Interview → Specify → Plan → Detail into a single condensed flow; emits one work-root `SPEC.md` + `tasks/` (no features/, no REQUIREMENTS.md, no PLAN.md). | `canonical/skills/aid-interview/SKILL.md:48-61` |
| **Full Path** | The standard pipeline — all four design phases run separately, REQUIREMENTS.md + per-feature SPEC.md + PLAN.md + tasks/. | `canonical/templates/work-state-template.md:17-19` |
| **Triage** | The 2-3 question deterministic routing state inside `aid-interview` (T1 = breadth, T2 = size, T3 = type). Conservative — any "large" signal routes to FULL. | `canonical/skills/aid-interview/references/state-triage.md:1-100` |
| **workType** | The kebab-normalized type from T3: `bug-fix | small-refactor | single-doc | small-new-feature`. | `canonical/skills/aid-interview/references/state-triage.md:75-81` |
| **LITE-BUG-FIX** | Sub-path for `bug-fix` workType. Typically 1 IMPLEMENT task (fix + regression test). | `canonical/skills/aid-interview/references/state-task-breakdown.md:58-63` |
| **LITE-DOC** | Sub-path for `single-doc` workType. Exactly 1 DOCUMENT task. | `canonical/skills/aid-interview/references/state-task-breakdown.md:58-63` |
| **LITE-REFACTOR** | Sub-path for `small-refactor` workType. 1–3 REFACTOR + TEST tasks. | `canonical/skills/aid-interview/references/state-task-breakdown.md:58-63` |
| **LITE-FEATURE** | Sub-path for `small-new-feature` workType. 1–5 IMPLEMENT + TEST + DOCUMENT tasks. | `canonical/skills/aid-interview/references/state-task-breakdown.md:58-63` |
| **CONDENSED-INTAKE (L1)** | Lite-path sub-path-specific slot-fill conversational interview; written by `interviewer`. | `canonical/skills/aid-interview/SKILL.md:21-23` |
| **TASK-BREAKDOWN (L2)** | Lite-path state — `architect` proposes typed task breakdown directly from work-root SPEC. | `canonical/skills/aid-interview/references/state-task-breakdown.md:1-10` |
| **LITE-REVIEW (L3)** | Lite-path pre-execution gate — `reviewer` adversarially validates the task set against SPEC. | `canonical/skills/aid-interview/SKILL.md:24` |
| **LITE-DONE (L4)** | Lite-path terminal — hand-off prompt to `/aid-execute`. | `canonical/skills/aid-interview/SKILL.md:25` |
| **Escalated** | Path state where a work started on lite and was promoted to full mid-flight. `STATE.md ## Escalation Carry` block preserves slot answers + decisions to avoid re-asking. | `canonical/skills/aid-interview/SKILL.md:181-194`, `canonical/templates/work-state-template.md:26-43` |

---

## Recipes (FR8 / feature-011)

| Term | Definition | Source |
|------|------------|--------|
| **Recipe** | Pre-filled lite-path template at `canonical/recipes/<name>.md`. YAML front-matter + body with `## spec` + `## tasks` blocks + `{{slot}}` placeholders. Eliminates redundant interview for recurring patterns. | `canonical/recipes/README.md:1-20` |
| **Slot** | `{{slot-name}}` placeholder in a recipe body. Lexical rule: `[a-z][a-z0-9-]*`. Substituted at render via `parse-recipe.sh --render`. | `canonical/recipes/README.md:82-95` |
| **Slot escape** | `{!{` in recipe body — rewritten to literal `{{` at emit time (so recipes can quote slot syntax without triggering it). | `canonical/recipes/README.md:98-100` |
| **applies-to** | Recipe front-matter field — which `workType` this recipe matches (or `*` for cross-type). | `canonical/recipes/README.md:65-77` |
| **Seed Catalog (5 recipes)** | `bug-fix.md`, `method-refactor.md`, `add-crud-endpoint.md`, `add-unit-test.md`, `write-release-note.md`. | `canonical/recipes/README.md:26-39` |

---

## Two-Tier Review (feature-004)

| Term | Definition | Source |
|------|------------|--------|
| **Quick-Check** | Per-task fast review by Small-tier `reviewer`; NO grade loop; HIGH+ findings deferred to delivery gate. | `canonical/skills/aid-execute/SKILL.md:140`, `canonical/scripts/execute/writeback-task-status.sh:17-18` (Quick Check Findings section) |
| **Delivery Gate** | Per-delivery full review by `reviewer` (tier = complexity score); full review/fix/review loop with `grade.sh`. | `canonical/skills/aid-execute/SKILL.md:144` |
| **Complexity Score (Small / Medium / Large)** | Computed by `complexity-score.sh` from task count, depth, risk, consults — selects reviewer tier for the delivery gate. Thresholds: Low=6, High=14 default. | `canonical/scripts/execute/complexity-score.sh:14-32` |

---

## Parallel Pool Dispatch (feature-009)

| Term | Definition | Source |
|------|------------|--------|
| **Pool Dispatch** | The PD-0..PD-6 model used by `aid-execute` in delivery mode — continuous parallel pool replaces the serial task loop. | `canonical/skills/aid-execute/SKILL.md:193-211` |
| **MaxConcurrent** | The pool's parallel capacity — sourced from `.aid/settings.yml` `execution.max_parallel_tasks` (default 5). | `canonical/templates/settings.yml:44`, `canonical/skills/aid-execute/SKILL.md:200` |
| **Wait-for-any-completion** | Pool scheduling primitive — pool waits for any single task to finish before slotting the next. | `canonical/skills/aid-execute/SKILL.md:193-211` |
| **Failure Block Radius** | The transitive descendants of a failed task — all are marked Blocked. Computed by `compute-block-radius.sh` via BFS. | `canonical/scripts/execute/compute-block-radius.sh:1-58` |
| **Graceful Degradation** | When the host doesn't support `run_in_background: true`, pool falls back to MaxConcurrent=1 (sequential). User-visible notice + Calibration Log entry. | `canonical/skills/aid-execute/SKILL.md:198-211` |
| **Capability Probe (PD-0)** | The early pool step that detects whether the host supports backgrounded dispatch. | `canonical/skills/aid-execute/SKILL.md:194-197` |
| **EXECUTE-WAVE** | The named state inside `aid-execute` where pool dispatch runs. Includes AC4 Sub-unit Drill-down (re-rendered snapshot after each sub-unit transition). | `canonical/skills/aid-execute/SKILL.md:212-221` |
| **Sub-unit** | A subdivision of an EXECUTE-WAVE step (e.g., per-task progress within a wave). Drives the AC4 drill-down snapshot. | `canonical/skills/aid-execute/SKILL.md:213-221` |

---

## Subagent Visibility (work-003 traceability — always-on)

| Term | Definition | Source |
|------|------------|--------|
| **L1 ETA Bracket Pair** | `▶ <agent> starting (~LOW-HIGH)` / `✓ <agent> done in <actual>` — bracket on every long-running dispatch. ETAs from `rough-time-hints.md`. | `canonical/templates/long-wait-protocol.md:38-49` |
| **L2 Check-In Timers** | Three backgrounded `sleep && echo` Bash dispatches at `LOW/2`, `LOW`, `1.5×LOW` minutes — each fires an in-narration check-in. Each must be its OWN `run_in_background: true` call (no `&` chaining). | `canonical/skills/aid-discover/SKILL.md:89-95`, `canonical/templates/long-wait-protocol.md:41-49` |
| **L3 Heartbeat File** | `.aid/.heartbeat/<agent>-<unix-ts>.txt` — pre-created by dispatcher; subagent overwrites every N minutes; single line pipe-delimited; deleted on completion. | `canonical/templates/subagent-heartbeat-protocol.md:39-115` |
| **Calibration Log** | Per-work `STATE.md ## Calibration Log` section — every dispatch appends `\| YYYY-MM-DD \| agent \| task-id \| ETA-band \| actual \| notes \|`. Always-on, never optional. | `canonical/skills/aid-discover/SKILL.md:104-107` |
| **Dispatches sub-column** | Per-task sub-column in `STATE.md ## Tasks Status` — records each dispatch attempt for the task. Always-on. | `canonical/skills/aid-discover/SKILL.md:106-108` |
| **heartbeat_interval** | `.aid/settings.yml` `traceability.heartbeat_interval` (integer minutes; default 1; `0` disables). | `canonical/templates/settings.yml:49-50`, `canonical/templates/subagent-heartbeat-protocol.md:20-37` |

---

## State Machine / FR2 Area-STATE

| Term | Definition | Source |
|------|------------|--------|
| **State Machine (per-skill)** | Every `aid-*` skill exits after one state and re-enters on the next slash-command invocation (no auto-advance per IQ9). Each SKILL.md has a Dispatch table = state machine. | `canonical/skills/aid-discover/SKILL.md:54-59`, `coding-standards.md §8d` |
| **FILESYSTEM IS THE ONLY SOURCE OF TRUTH** | Every state-detection block opens with this — skills never trust conversation memory; always read disk. | `canonical/skills/aid-execute/SKILL.md:112`, `canonical/skills/aid-discover/SKILL.md:128` |
| **State Entry Line** | The `[State: NAME] — <description>` print + "you are here" ASCII state-map emitted on every state entry. | `canonical/skills/aid-discover/SKILL.md:166-200` |
| **Dispatch Table** | The canonical state-machine table in every thin-router SKILL.md (State / Detail / Worker / Advance columns). The three Advance forms: Unconditional, Halt, Conditional. | `canonical/skills/aid-execute/SKILL.md:137-148`, `coding-standards.md §8d` |
| **FR2 Area-STATE Consolidation** | The per-work `STATE.md` is the per-area state hub; legacy per-feature `STATE.md` + per-task `STATE.md` files are RETIRED. | `coding-standards.md §7e`, `canonical/templates/work-state-template.md:9` |
| **Thin-Router SKILL.md Convention** | When SKILL.md grows past ~200 lines, extract per-state bodies into `references/state-{name}.md`; keep router as Dispatch table + Pre-flight + State Detection. Caps at ~360 lines. | `coding-standards.md §7b`, `project-structure.md:228-244` |

---

## Grading / Review

| Term | Definition | Source |
|------|------------|--------|
| **Universal Grading Rubric** | One rubric across the pipeline: severity tags `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` → grade computed deterministically by `grade.sh`. Worst severity dominates the letter; count sets modifier. | `methodology/aid-methodology.md:324`, `canonical/scripts/grade.sh:100-126` |
| **Grade scale** | `A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F`. E band = critical-severity present. F = non-functional. | `canonical/skills/aid-discover/SKILL.md:161-162`, `canonical/scripts/grade.sh:109-126`, `canonical/templates/settings.yml:58-61` |
| **minimum_grade** | The REVIEW exit criterion (default `A`). Per-skill overrides possible (`<skill>.minimum_grade`). | `canonical/templates/settings.yml:37-38, 53-81` |
| **Severity tag** | `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` — reviewer assigns; script computes grade. | `canonical/agents/reviewer/AGENT.md:36-37, 54-60` |
| **Source tag** | `[CODE] [TASK] [SPEC] [KB] [ARCHITECTURE]` — reviewer tags issue origin; drives loopback routing. | `canonical/agents/reviewer/AGENT.md:36` |
| **Reviewer-Dispatch Protocol** | The 5-section brief contract for every reviewer dispatch: ARTIFACTS UNDER REVIEW / CONTEXT / RUBRIC / OUT OF SCOPE / OUT-OF-SCOPE FINDINGS POLICY / DELIVERABLES. Enforces scope discipline. | `canonical/templates/reviewer-dispatch.md:1-80` |
| **CONTEXT discipline** | "CONTEXT describes what the artifact IS. Does NOT describe what downstream consumers do with it." Prevents scope leak in reviewer briefs. | `canonical/templates/reviewer-dispatch.md:68-72` |
| **Out-of-Scope Observations** | Reviewer ledger section for stray findings; logged but excluded from severity counts. Does NOT affect grade. | `canonical/templates/reviewer-dispatch.md:36-39` |
| **Two-Grade Gate** (summarize) | `aid-summarize` requires BOTH Machine Grade AND Human Grade ≥ minimum. Overall = lower of the two. V1=0 forces Human Grade = F. | `canonical/skills/aid-summarize/SKILL.md:7-8`, `canonical/scripts/summarize/run-validators.sh:19-26` |
| **AUTO_POOL (summarize)** | Auto-checkable criteria pool: `D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2` (73 pts max). | `canonical/scripts/summarize/run-validators.sh:20` |
| **MANUAL_POOL (summarize)** | Manual-checkable criteria pool: `K1 K2 V1` (30 pts max). | `canonical/scripts/summarize/run-validators.sh:21` |
| **V1 visual gate** | Mandatory human visual check in `aid-summarize`. V1=0 forces Human Grade = F. | `canonical/scripts/summarize/run-validators.sh:26` |

---

## Feedback Loops (the 11 named loops)

| Term | Definition | Source |
|------|------------|--------|
| **Loop 1 — Interview→Discovery** | Q&A entry to DISCOVERY-STATE → targeted discovery → KB update → interview resumes. | `methodology/aid-methodology.md:566-570` |
| **Loop 2 — Specify→Discovery** | Specify pauses → Q&A → discovery → resume. | `methodology/aid-methodology.md:572-576` |
| **Loop 3 — Plan→Discovery** | Plan reveals codebase complexity → Q&A → discovery → resume. | `methodology/aid-methodology.md:578-582` |
| **Loop 4 — Plan→Specify** | KB OK but SPEC ambiguous → feature `STATE.md` Q&A → spec revision. | `methodology/aid-methodology.md:584-588` |
| **Loop 5 — Detail→Plan** | Plan too vague to decompose → Plan revises → Detail resumes. | `methodology/aid-methodology.md:590-594` |
| **Loop 6 — Execute→Discovery / Specify / Detail** | IMPEDIMENT routed by Type. | `methodology/aid-methodology.md:596-600` |
| **Loop 7 — Execute Review→upstream** | CODE auto-fixed; TASK/SPEC/KB issues escalate. | `methodology/aid-methodology.md:602-606` |
| **Loop 8 — Deploy→Execute** | Deploy verification fails → back to Execute. | `methodology/aid-methodology.md:608-612` |
| **Loop 9 — Monitor→Execute** | BUG classification → new task → Execute → Deploy. The "short path." | `methodology/aid-methodology.md:616-620` |
| **Loop 10 — Monitor→Discover** | Change Request → Q&A → full new cycle. | `methodology/aid-methodology.md:622-626` |
| **Loop 11 — Any→Discovery** | Cross-cutting targeted re-discovery — KB is always the return target; "the loop that makes the Knowledge Base the gravitational center." | `methodology/aid-methodology.md:630-634` |
| **Targeted re-discovery** | Re-entry to Discovery that fills a specific gap; never a full redo. | `methodology/aid-methodology.md:272`, `methodology/aid-methodology.md:632-634` |
| **Bug Path (short)** | Monitor → Execute → Deploy. Skips spec/plan because spec is already correct. | `methodology/aid-methodology.md:234`, `methodology/aid-methodology.md:516` |
| **Change Request Path (full cycle)** | Monitor → Discover → ... full pipeline restart. | `methodology/aid-methodology.md:235`, `methodology/aid-methodology.md:622-626` |

---

## Agents (22) & Tiers

| Term | Definition | Source |
|------|------------|--------|
| **Tier (Large / Medium / Small)** | Model size tier per agent. Maps to Claude (Opus/Sonnet/Haiku), Codex (gpt-5.5/gpt-5.4/gpt-5.4-mini), Cursor. | `profiles/claude-code.toml:38-41`, `profiles/codex.toml:43-55` |
| **Large-tier (10 agents)** | architect, reviewer, interviewer, security, discovery-{scout, architect, analyst, integrator, quality, reviewer}. | `.aid/knowledge/project-structure.md:252` |
| **Medium-tier (9 agents)** | orchestrator, researcher, developer, operator, data-engineer, performance, devops, tech-writer, ux-designer. | `.aid/knowledge/project-structure.md:253` |
| **Small-tier (3 agents)** | simple-extractor, simple-formatter, simple-glob. | `.aid/knowledge/project-structure.md:254` |
| **Discovery sub-agents (5)** | Scout, Architect, Analyst, Integrator, Quality — orchestrated in parallel by `aid-discover`. Each owns specific KB docs. | `canonical/skills/aid-discover/references/agent-prompts.md:1-143` |
| **discovery-reviewer** | Grades discovery output adversarially. Largest agent file (387 lines). | `canonical/agents/discovery-reviewer/AGENT.md` |

---

## Distribution / Generator

| Term | Definition | Source |
|------|------------|--------|
| **canonical/** | Single source of truth for all install-tree content. Never edit profile trees directly — edit canonical and run `run_generator.py`. | `coding-standards.md §7a`, `project-structure.md:41-48` |
| **Profile** | A host-tool target spec — `profiles/{claude-code,codex,cursor}.toml`. Defines output_root, frontmatter schema, model tiers, filename_map, capabilities. | `profiles/claude-code.toml:1-65`, `profiles/codex.toml:1-78` |
| **Install Tree** | One of the per-profile output directories: `profiles/claude-code/.claude/`, `profiles/codex/{.codex,.agents}/`, `profiles/cursor/.cursor/`. | `canonical/EMISSION-MANIFEST.md:14-22` |
| **Dogfood Tree** | The top-level `.claude/` in this repo — AID applied to itself. Byte-identical body content to the claude-code profile output. NOT subject to KB claims (KB only covers the 4-tree set: canonical + 3 profile trees). | `canonical/skills/aid-discover/SKILL.md:45-47`, `.aid/knowledge/project-structure.md:296-298` |
| **Emission Manifest** | `{profile}/emission-manifest.jsonl` — the authoritative safety boundary for pure-mirror deletion. JSONL records of (`profile`, `src`, `dst`, `sha256`), sorted by `dst`, LF endings, sentinel first line. | `canonical/EMISSION-MANIFEST.md:1-152` |
| **Pure-Mirror Deletion** | The generator's safety rule: only files in the previous manifest's `removed_dst` set are deleted; files outside any manifest are NEVER touched. | `canonical/EMISSION-MANIFEST.md:70-83` |
| **Sentinel (manifest)** | The reserved first line `{"_manifest_version": 1}` enabling future schema evolution. | `canonical/EMISSION-MANIFEST.md:57-67` |
| **VERIFY-4a** | The strict byte-identity verification — re-runs generator and asserts identical output (`verify_deterministic.py`, 515 lines). | `.aid/knowledge/project-structure.md:109`, `.aid/knowledge/project-structure.md:133` |
| **VERIFY-4b** | The advisory verification — non-blocking warnings (`verify_advisory.py`, 343 lines). | `.aid/knowledge/project-structure.md:134` |
| **AC2** | The "byte-identical re-run" guarantee — re-running generator on unchanged inputs produces byte-identical install tree + byte-identical manifest. | `canonical/EMISSION-MANIFEST.md:46-50` |
| **Split-root layout (Codex)** | Codex profile has TWO output roots: `profiles/codex/.codex/agents/` (TOML) + `profiles/codex/.agents/{skills,scripts,recipes,templates}/`. One manifest covers both. | `profiles/codex.toml:10-18`, `canonical/EMISSION-MANIFEST.md:24-27` |
| **Filename map** | Per-profile substitution dictionary for canonical placeholders (`project_context_file`, `reviewer_output_file`, `open_questions_file`). | `profiles/claude-code.toml:48-53`, `profiles/codex.toml:61-66` |
| **Asset Kind** | A category of canonical source (agents / skills / templates / recipes / scripts) — each maps to an install-tree sub-directory per profile. | `canonical/EMISSION-MANIFEST.md:105-115` |
| **Passthrough Renderer** | Renderer that emits files without format conversion or frontmatter injection (e.g., recipes). | `canonical/EMISSION-MANIFEST.md:117-130` |
| **setup.sh / setup.ps1** | End-user installers (Bash / PowerShell). Interactive menu to choose tools; diff-aware copy (`new=copy, identical=skip, different=ask`). | `setup.sh:1-100`, `.aid/knowledge/project-structure.md:111` |

---

## Settings & Configuration

| Term | Definition | Source |
|------|------------|--------|
| **.aid/settings.yml** | Single source of truth for AID pipeline settings (grades, parallelism, heartbeat, project identity). Managed by `/aid-config`. | `canonical/templates/settings.yml:1-11` |
| **review.minimum_grade** | Global REVIEW exit criterion (default `A`). | `canonical/templates/settings.yml:37-38` |
| **execution.max_parallel_tasks** | Pool dispatch capacity (default 5). | `canonical/templates/settings.yml:44` |
| **traceability.heartbeat_interval** | Heartbeat cadence in minutes (default 1; `0` disables). | `canonical/templates/settings.yml:49-50` |
| **Per-skill override** | `<skill>.minimum_grade` (e.g., `discover.minimum_grade: A+`) — overrides global. | `canonical/templates/settings.yml:54-81` |
| **Resolution order (read-setting.sh skill mode)** | Per-skill override → `review.<key>` → script `--default` → exit 1. | `canonical/scripts/config/read-setting.sh:212-232` |
| **read-setting.sh Skill Mode** | `--skill X --key Y --default V` — applies override resolution. | `canonical/scripts/config/read-setting.sh:14-19` |
| **read-setting.sh Path Mode** | `--path A.B --default V` — direct dotted-path lookup, no override resolution. | `canonical/scripts/config/read-setting.sh:21-26` |

---

## Repository / Workflow Conventions

| Term | Definition | Source |
|------|------------|--------|
| **Single-Branch Work** | For ANY `work-NNN`, commit to ONE persistent branch (off master); no per-task worktrees or branches. Root cause of PR #12 losing 63 commits. | `coding-standards.md §7f`; `tech-debt.md H1` history |
| **work-NNN branch convention** | Persistent `work-NNN` branch (off master); PR `work-NNN → master` when ready. | user-memory `project_work-branch-convention.md` |
| **Pre-flight Cleanup** | Orchestrator-only KB sweep before reviewer dispatch — line-count drift, off-by-1, ghost references, path/citation hygiene. These are housekeeping items; never grade them. | `canonical/skills/aid-discover/SKILL.md:31-52` |
| **Quadruple Mirror** | Each unique canonical helper script has 4 byte-identical copies: canonical + dogfood `.claude/` + 3 profile trees. Inflates file counts. | `.aid/knowledge/project-structure.md:296` |
| **kb-overhaul branch** | The current working branch in this repo (per git status). Off master. | git status, `.aid/knowledge/project-structure.md:14` |
| **Cycle (discovery)** | One full pass through GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL. KB authoring uses cycle numbering. | `STATE.md ## Review History` |
| **Pass (discovery cycle internals)** | A sub-iteration inside a cycle. | `STATE.md ## Review History` |

---

## Universal Loop Cycle (Specify / Plan / Detail / Specify-section)

| Term | Definition | Source |
|------|------------|--------|
| **PROPOSE** | Step 1 of the universal loop — agent proposes a concrete solution grounded in KB / codebase / SPEC. | `methodology/aid-methodology.md:349-353`, `canonical/skills/aid-specify/SKILL.md:27-33` |
| **DISCUSS** | Step 2 — developer validates, adjusts, redirects. Agent pushes back on contradictions, presents trade-offs. | `methodology/aid-methodology.md:349-353` |
| **WRITE** | Step 3 — the agreed content is written to the target artifact. | `methodology/aid-methodology.md:349-353` |
| **REVIEW** | Step 4 — agent verifies what was written against KB / codebase reality. Pass → next section. Fail → back to PROPOSE. | `methodology/aid-methodology.md:349-353` |
| **Re-run = enter at step 4** | Re-running a design-phase skill enters at REVIEW with existing content — the same loop handles both creation and maintenance. | `methodology/aid-methodology.md:356`, `canonical/skills/aid-specify/SKILL.md:35` |

---

## Miscellaneous Domain Vocabulary

| Term | Definition | Source |
|------|------------|--------|
| **Adversarial Reviewer** | The reviewer is structurally adversarial to the developer — never grades its own work. Separation prevents bias. | `canonical/agents/reviewer/AGENT.md:7-8, 48`, `methodology/aid-methodology.md:104` |
| **Clean Context** | The reviewer is dispatched in a clean context (no chat history with the executor) — guarantees independent assessment. | `canonical/skills/aid-execute/SKILL.md:90` (REVIEW state) |
| **Hypothesis vs Knowledge (specs)** | "A spec written before implementation is a hypothesis. A spec revised after implementation is knowledge." | `methodology/aid-methodology.md:86-88` |
| **Spec-as-Hypothesis** | Treats SPEC.md as a living artifact with formal revision protocols — every change is tracked, justified, approved. | `methodology/aid-methodology.md:102`, `methodology/aid-methodology.md:86-88` |
| **Spike** | A pause in `aid-specify` for investigation; records what needs research. | `methodology/aid-methodology.md:367`, `canonical/skills/aid-specify/SKILL.md:8` |
| **Execution Graph** | Dependency + parallel-wave tables appended to PLAN.md by Detail. Drives `aid-execute` task ordering + pool dispatch. | `methodology/aid-methodology.md:421`, `canonical/skills/aid-execute/SKILL.md:39, 175-180` |
| **Wave** | A group of tasks that can be executed in parallel (no inter-dependencies). Drives EXECUTE-WAVE pool dispatch. | `canonical/templates/work-state-template.md:81-85` |
| **Failure Tolerance** | EXECUTE-WAVE policy for handling failed sub-units — references `state-execute.md § EXECUTE-WAVE Drill-down`. | `canonical/skills/aid-execute/SKILL.md:218-221` |
| **Circuit Breaker** | The Execute review loop's safety stop: if grade hasn't improved (same or worse) after 3 consecutive cycles, halt. | `methodology/aid-methodology.md:460` |
| **Stale-Check** | The `aid-summarize` state that compares `LAST_KB_CHANGE_DATE` vs `LAST_SUMMARY_DATE` to decide whether to regenerate the HTML. | `canonical/skills/aid-summarize/SKILL.md:70-80` |
| **Knowledge Summary** | The single self-contained `.aid/knowledge/knowledge-summary.html` produced by `aid-summarize`. Offline, light/dark, accessible, Mermaid-rendered. | `canonical/skills/aid-summarize/SKILL.md:1-30` |
| **Profile (summarize)** | One of `auto | web-app | library | cli | microservices | data-pipeline` — drives section-template selection for the knowledge-summary HTML. | `canonical/skills/aid-summarize/SKILL.md:14, 51` |
| **Target diagrams** | Per-profile minimum diagram count for the knowledge-summary; if actual < target, grade capped at C+. | `canonical/scripts/summarize/run-validators.sh:28-34` |
| **WCAG AA** | The accessibility floor for knowledge-summary HTML output (color contrast, keyboard nav, semantic markup). | `canonical/skills/aid-summarize/SKILL.md:21-22` |
| **Lightbox** | Click-to-expand modal for diagrams in the knowledge-summary HTML. Implemented in `canonical/templates/knowledge-summary/lightbox.js` (359 lines). | `canonical/skills/aid-summarize/SKILL.md:20-22`, `.aid/knowledge/project-structure.md:279` |
| **Plan Mode (Claude Code)** | A read-only mode that blocks file writes. Pre-flight checks in writing skills detect and abort. | `canonical/skills/aid-discover/SKILL.md:26-27`, `canonical/skills/aid-execute/SKILL.md:47-48` |
| **Auto-Accept Edits** | Claude Code mode that allows writes without confirmation. Compatible with AID skills. | `canonical/skills/aid-execute/SKILL.md:47` |
| **`--reset` flag** | Universal flag on aid-* skills — clears the artifact set the skill owns and restarts from scratch. | `canonical/skills/aid-discover/SKILL.md:65-66`, `canonical/skills/aid-interview/SKILL.md:88-89`, etc. |
| **`--grade X` flag** | Universal flag — overrides the minimum acceptable grade for this skill. Persisted to STATE.md / settings.yml. | `canonical/skills/aid-discover/SKILL.md:64-67`, `canonical/skills/aid-summarize/SKILL.md:50` |
| **`--non-functional` (grade.sh)** | Flag that forces grade = F (build/run failed or produced no usable output). | `canonical/scripts/grade.sh:51-54` |
| **STATE.md Q&A (Pending)** | The section in `.aid/knowledge/STATE.md` (Discovery area STATE) where loopback questions from downstream phases accumulate until Discover's Q-AND-A state resolves them. | `canonical/skills/aid-discover/SKILL.md:155-159` |
| **Cross-phase Q&A** | The `STATE.md ## Cross-phase Q&A (Pending)` section on work `STATE.md` — consolidated open questions across all phases of one work. | `canonical/templates/work-state-template.md:95-100` |
| **Escalation Carry** | The `STATE.md ## Escalation Carry` block written by lite→full escalation; preserves slot values + decisions to avoid re-asking during CONTINUE. | `canonical/templates/work-state-template.md:26-43`, `canonical/skills/aid-interview/SKILL.md:181-194` |
| **DELIVERY-GATE** | The Execute state where the delivery-gate reviewer runs (full review/fix loop with `grade.sh` determinism). | `canonical/skills/aid-execute/SKILL.md:144` |
| **Quick Check Findings** | The `STATE.md ## Quick Check Findings` section where per-task quick-check HIGH+ findings accumulate for the delivery gate aggregator. | `canonical/scripts/execute/writeback-task-status.sh:17-18` |
| **Delivery Gates** | The `STATE.md ## Delivery Gates` section where per-delivery review verdicts are recorded. | `canonical/scripts/execute/writeback-task-status.sh:20-23` |
| **delivery-NNN-issues.md** | Per-delivery issue log inside the work directory. Append-only via `writeback-task-status.sh --delivery-id NNN --append-issue`. | `canonical/scripts/execute/writeback-task-status.sh:26-28` |
| **Sentinel-File Lock** | The concurrency primitive used by `writeback-task-status.sh` and `parse-recipe.sh --render`: `set -o noclobber` + atomic create + sleep-poll retry. | `canonical/scripts/execute/writeback-task-status.sh:6-9` |
| **AID Workspace** | `.aid/` — the runtime root for all KB + work artifacts. Gitignore convention varies (committed vs ignored is user choice). | `canonical/skills/aid-interview/SKILL.md:74` |
| **Run** | One invocation of an aid-* slash command. Each run advances one state (no auto-advance). | `canonical/skills/aid-discover/SKILL.md:19` |
| **One question at a time** | Interview discipline — never batch multiple questions in a single turn. User-memory rule `feedback_one-question-at-a-time.md`. | `methodology/aid-methodology.md:331`, user memory |
| **Wait for responses** | When the user says wait or has open questions, do NOT proceed on assumed intent. User-memory rule `feedback_wait-when-told.md`. | user memory |
| **Subjective-Issue Collaboration** | For human-detected/subjective issues: expose → propose → ask; never fix autonomously. User-memory rule. | user memory `feedback_subjective-issue-collaboration.md` |
| **No Effort-Dodging** | Do what is asked or give a concrete specific reason; never vague hand-waves, never defer doable work. User-memory rule. | user memory `feedback_no-effort-dodging.md` |
| **rough-time-hints.md** | The current measured ETA table per subagent operation class. Source of L1 ETA bands. | `canonical/skills/aid-discover/SKILL.md:81-82`, `.aid/knowledge/project-structure.md:282` |

---

## Glossary Statistics

- **Total terms defined:** ~195 (across 16 categorical groups above; counted by row audit of this document — `metrics.md` generator undercounts at 172 due to regex mismatch with `✓` status markers)
- **Primary sources:** `methodology/aid-methodology.md` (1,070 lines), `docs/glossary.md` (76 lines), 11 canonical SKILL.md files, 22 canonical AGENT.md files, `canonical/EMISSION-MANIFEST.md` (152 lines), `canonical/templates/{settings.yml, work-state-template.md, subagent-heartbeat-protocol.md, long-wait-protocol.md, reviewer-dispatch.md, feedback-artifacts/IMPEDIMENT.md}`, helper scripts under `canonical/scripts/`
- **Every entry cites at least one `path:line` source.** ⚠️ Inferred-from-code annotations are explicit where used.
