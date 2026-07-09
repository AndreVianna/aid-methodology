# Requirements

- **Name:** AID Lite Shortcut Skills
- **Description:** A verb-first set of ~45 Lite-path "shortcut" skills (`aid-{verb}[-{artifact}]`) plus the pipeline restructuring that makes them the sole lite entry — `/aid-describe` reduced to full-path-only, a new `/aid-triage` router, and removal of the now-unused recipe catalog — so a user who knows their change-type goes straight to a fully-graded flattened lite work while an unsure user is routed by `/aid-triage`.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Initial interview started | /aid-describe |
| 2026-07-07 | Curated-list build broadened to a cross-discipline landscape (software dev + data/analytics + design/UX + reporting/docs + PM/ops); online research dispatched to derive major activity groups before finalizing the skill list | /aid-describe |
| 2026-07-07 | Research complete (report: research/digital-project-activities.md). Derived a 12-group cross-discipline activity taxonomy (lean-8 cut noted). Key findings: (1) the 12 groups mirror AID's own pipeline phases; (2) the current recipe catalog is build/change/fix-only and over-decomposed by artifact noun; (3) the non-software groups the stakeholder wanted (Discover, Design, Operate, Analyze, Govern) have zero Lite-recipe coverage but largely map to existing pipeline skills | /aid-describe (aid-researcher) |
| 2026-07-07 | Scope narrowed to activity groups G3–G11; clean-slate verb-first, artifact-parameterized design. Finalized skill verbs: aid-prototype (G3), aid-create/aid-add (G4), aid-change/aid-update + aid-refactor (G5), aid-fix (G6), aid-test (G7), aid-document (G8), aid-deploy [re-purpose] (G9), aid-monitor [re-purpose] (G10), aid-report (G11) | /aid-describe |
| 2026-07-07 | aid-refactor confirmed as distinct G5 skill. Artifact-type taxonomy confirmed (11 product types); ownership boundary adopted (test→aid-test, doc→aid-document, report→aid-report). Naming scheme /aid-{verb}[-{artifact}]; aid-fix/aid-refactor stay bare. 3-agent consensus + judge merge produced the catalog | /aid-describe |
| 2026-07-07 | Stakeholder refinements: added `theme` suffix (ui=structure/theme=style); aid-test-experiment → bare `aid-experiment`; aid-document-adr → `aid-document-decision`; G8 split into 8 doc archetypes; aid-report-dashboard → `aid-show-dashboard`. Catalog → 45 canonical / 24 aliases (aid-add-*/aid-update-*) | /aid-describe |
| 2026-07-07 | Added FR-6…FR-11 (§5.5): flattened single-feature/single-delivery lite work (REQUIREMENTS+SPEC+PLAN+tasks/, no features/ or delivery-NNN/); traverses Describe→Detail ONLY (not Execute); halts at a user-approval gate; every generated document passes its Grading Gate. Difference from full path is lightweight capture, not fewer artifacts | /aid-describe |
| 2026-07-07 | Interview complete — approved | /aid-describe |
| 2026-07-07 | Feature decomposition (aid-define): 12 features created (feature-001…012), by-activity-group frame. Cross-reference (aid-reviewer) graded **D+** vs the live **A+** gate — 10 findings; coverage clean (all FR/AC mapped) | /aid-define |
| 2026-07-07 | **MAJOR SCOPE CHANGE (user-directed).** Resolving cross-reference finding ① (recipe consolidation vs. not breaking aid-describe), the stakeholder chose the "rewrite route" + the full three-part split — folding the previously-deferred "Phase 2" into this work: (1) **`/aid-describe` → full-path-only** (lite path + TRIAGE removed); (2) new **`/aid-triage` router** (extracts today's triage; routes unsure users to full or a shortcut); (3) **recipe catalog REMOVED** (not consolidated) — per-work-type knowledge migrates into the shortcut skills; the "profile" term is dropped (collided with the spine "Profile"). Findings ①② mooted; ④⑤⑥⑧ recorded as spec-phase open items (A-6…A-9); added AC-12 (NFR-5 speed metric), AC-13 (triage routing), AC-14 (aid-describe full-only). Reworked §1–§10 | /aid-define |
| 2026-07-07 | Cross-reference re-run after the scope change graded B+ → 2 trivial findings fixed (AC-5/FR-14 broadened to name the orphaned work-state-template surfaces; feature-001 wording "remain unchanged"→"no regression") → scoped confirm cleared **A+**. Define phase DONE; ready for /aid-specify | /aid-define (aid-reviewer) |
| 2026-07-08 | **STRUCTURE/NAMING AMENDMENT (user-directed, during /aid-detail).** Adopt one artifact-naming convention across BOTH paths — feature=`SPEC.md`, delivery=`BLUEPRINT.md`, task=`DETAIL.md` — and group full-path deliveries under `deliveries/`. Short path: `BLUEPRINT.md` at root (holds GATE CRITERIA — resolves the flat gate-criteria gap), delivery lifecycle+gate + per-task lifecycle promoted into work `STATE.md`, task folders `DETAIL.md`-only (no per-task STATE.md). Adds the **full-path pipeline rename** to scope (FR-16: shipped aid-plan/detail/execute + templates + dashboard readers + tests) and fixes the shipped delivery-gate criteria mis-wire (gate reads `BLUEPRINT.md § GATE CRITERIA`). Added FR-15/16/17 + AC-15/16/17; reworked §4/§5.5/§5.7. Triggers a cascade: re-cascade specify→plan→detail for the rename + restructure the dogfood artifacts, re-gating A+ | /aid-detail (user amendment) |

## 1. Objective

Let a user who already knows the kind of change they want make it **without** the `aid-describe`
interview or triage: they invoke a dedicated verb-first **shortcut skill** (`aid-{verb}[-{artifact}]`)
that takes them directly down a streamlined **Lite path**, producing a fully-graded, flattened
single-feature/single-delivery work (REQUIREMENTS → SPEC → PLAN → tasks) that halts for approval
before execution.

To make this coherent, the work also **restructures the front of the pipeline** so the shortcut
skills become the *sole* lite entry: `/aid-describe` is reduced to the full path only, a new
`/aid-triage` skill routes users who are unsure, and the now-unused recipe catalog is removed. The
result is three clean entry points — know-full → `/aid-describe`; know-shortcut → the shortcut skill;
unsure → `/aid-triage`.

## 2. Problem Statement

Today the only entry into the Lite path is `aid-describe`, which runs the D1 opener plus an adaptive
triage to infer work-type and recipe before routing. For a user who already knows exactly what they
intend (e.g. "fix a bug", "add tests"), that triage is unnecessary friction — there is no way to go
straight to Lite-path scaffolding. Compounding this, `aid-describe` today carries *three* jobs at once
(full interview, lite path, and triage routing), and its lite behavior is coupled to a large,
over-fragmented recipe catalog — making the front of the pipeline harder to evolve than it should be.

## 3. Users & Stakeholders

- **Primary users — AID adopters who know their change-type.** Developers/teams using the AID
  methodology through any of the five host tools (Claude Code, Codex, Cursor, Copilot CLI,
  Antigravity) who already know the kind of work they're doing and want to go straight down the
  Lite path via the matching shortcut skill.
- **Secondary users — AID maintainers (dogfooding).** These skills ship as part of the AID toolkit
  and are used by the maintainers on AID itself (`.claude/` dogfood).
- **Unsure users — routed, not stranded.** Users who don't know which path or skill fits run the new
  **`/aid-triage`**, which suggests the right entry (full path via `/aid-describe`, or a specific
  shortcut). `/aid-describe` no longer performs this routing.
- **Decision-maker / owner.** The AID project owner (this interview's stakeholder).

## 4. Scope

### In Scope

- A **clean-slate, verb-first set of ~45 Lite-path shortcut skills** (§5.1), designed against the
  digital-project activity taxonomy (`research/digital-project-activities.md`), scoped to activity
  groups **G3–G11**. Each is named `aid-<verb>` and takes the artifact type as a **parameter/suffix**.
- The **Lite-path adjustments** required to support (a) direct entry from these skills and (b) the
  flattened single-feature/single-delivery work structure (§5.5) — including how `/aid-execute` and
  the dashboard state readers consume it.
- **`/aid-describe` → full-path only** (§5.6, FR-12): remove its lite path and its TRIAGE routing.
- **New `/aid-triage` router** (§5.6, FR-13): extract today's triage into a standalone skill that
  suggests the right entry for unsure users.
- **Remove the recipe catalog** (§5.6, FR-14): with `/aid-describe` full-only, nothing consumes the
  recipes — delete them and migrate the per-work-type scaffolding knowledge **into** the shortcut
  skills. (Replaces the earlier "recipe consolidation" scope.)
- **Full-path pipeline structural rename** (§5.7, FR-15/FR-16): adopt one artifact-naming convention
  across **both** paths — feature=`SPEC.md`, delivery=`BLUEPRINT.md`, task=`DETAIL.md` — and group
  full-path deliveries under `deliveries/`. Refactors the shipped `aid-plan`/`aid-detail`/`aid-execute`,
  the delivery/task templates, both dashboard reader twins, and existing tests. (Scope expansion,
  2026-07-08; also fixes the shipped delivery-gate criteria mis-wire.)

### Out of Scope

- **G1 Discover & Research** and **G2 Define & Specify** — served by the front-end pipeline skills
  (`aid-discover` / `aid-describe` / `aid-define` / `aid-specify`); the shortcuts don't cover them.
- **G12 Plan, Govern & Steer** — meta/governance layer; not part of this work.
- **Execution itself** — the shortcut skills stop after Detail (FR-10); running the tasks is a
  separate, user-initiated `/aid-execute`.

*(The previously-deferred "Phase 2" — `aid-describe` full-only + `aid-triage` — is now **in scope**
per the 2026-07-07 scope change; see §5.6.)*

## 5. Functional Requirements

### 5.1 The shortcut skill set (verb-first, artifact-parameterized)

Verb-first skills; the artifact type is a **suffix/parameter**. Each is invoked directly, enters the
**Lite path**, and produces the flattened work (§5.5). Produced by 3-agent consensus + judge merge,
then refined with the stakeholder. **45 canonical skills; 24 alias forms.** (The pipeline
restructuring — `aid-describe`, `aid-triage`, recipe removal — is separate; see §5.6.)

**G3 — Prototype**

| Command | Alias | Intent |
|---|---|---|
| `aid-prototype` | — | Build a low-fidelity working model to validate direction before full build. |
| `aid-prototype-ui` | — | Wireframe / mock a UI + interaction flow (structure) to validate UX direction. |

**G4 — Create** *(alias family `aid-add-*` mirrors every form)*

| Command | Intent |
|---|---|
| `aid-create` | Create a new artifact from scratch; bare = internal code (module/interface/type) + any type without a suffix. |
| `aid-create-api` | Create an API endpoint / middleware (contract, handler, validation). |
| `aid-create-ui` | Create UI **structure** — component, control, layout, page. |
| `aid-create-theme` | Create UI **style** — colors, typography, spacing, design tokens, theming. |
| `aid-create-cli` | Create a CLI command / automation script. |
| `aid-create-data-model` | Create an entity/schema (+ migration). |
| `aid-create-data-pipeline` | Create an ETL / ingestion / orchestration pipeline. |
| `aid-create-messaging` | Create a message / event / queue + handler. |
| `aid-create-integration` | Create a third-party / external-system integration. |
| `aid-create-job` | Create a scheduled / background job. |
| `aid-create-config` | Create a config option / feature flag / rule. |
| `aid-create-infra` | Provision infrastructure (container / IaC resource). |

**G5 — Change** *(alias family `aid-update-*` mirrors every form)* **+ Refactor**

| Command | Intent |
|---|---|
| `aid-change` | Modify an existing artifact's behavior/intent (new acceptance criteria); bare = internal code + residual. |
| `aid-change-api` … `aid-change-infra` | Same 11 artifact suffixes as `aid-create` (api, ui, theme, cli, data-model, data-pipeline, messaging, integration, job, config, infra). |
| `aid-refactor` | Restructure/optimize code **without changing behavior** (absorbs rename-symbol, improve-performance). Bare. |

**G6 — Fix**

| Command | Intent |
|---|---|
| `aid-fix` | Diagnose and correct a defect / regression / incident / vulnerability. Bare. |

**G7 — Test & Experiment**

| Command | Intent |
|---|---|
| `aid-test` | Author/extend/run functional tests (unit/integration/e2e) + model evaluation. Bare default. |
| `aid-test-security` | Security verification (SAST/DAST/fuzz/dependency audit). |
| `aid-test-performance` | Benchmark / load / stress testing against thresholds. |
| `aid-test-data-quality` | Data-quality checks (schema, freshness, completeness) on a dataset/pipeline. |
| `aid-experiment` | Design, run, and analyze a controlled experiment / A-B test (hypothesis → variants → metric → significance). Bare. |

**G8 — Document** *(8 archetypes, no aliases — each has a distinct document shape)*

| Command | Intent |
|---|---|
| `aid-document` | Author/update a general doc — Diátaxis how-to / reference / explanation, or a status/progress report. Bare default. |
| `aid-document-decision` | Record a technical/architecture decision (ADR): context → decision → alternatives → consequences. |
| `aid-document-architecture` | Describe system architecture — components, boundaries, interactions, diagrams (C4 / arc42). |
| `aid-document-guideline` | Author an advisory recommended-practice: principle → rationale → do/don't examples. |
| `aid-document-standard` | Author a mandatory standard: rule → scope → compliance/enforcement → exceptions. |
| `aid-document-runbook` | Author an operational runbook/playbook: trigger → diagnostic → remediation → escalation. |
| `aid-document-tutorial` | Author a learning-oriented tutorial (pedagogical, worked example for a newcomer). |
| `aid-document-changelog` | Author/update a changelog / release notes. |

**G9 — Deploy · G10 — Monitor · G11 — Analyze / Show**

| Command | Intent |
|---|---|
| `aid-deploy` | Ship an artifact to its target environment/audience (promote → verify → rollback). Bare. Re-purpose existing pipeline skill. |
| `aid-monitor` | Run / observe / sustain a live asset (SLOs, observability, toil, capacity). Bare. Re-purpose existing pipeline skill. |
| `aid-report` | Analyze data/usage and communicate insight (EDA, metrics, A-B analysis). Bare. |
| `aid-show-dashboard` | Build a durable dashboard / BI view (data source → visualization → publish/refresh). *(Name flagged: overlaps AID's "Dashboard" concept — retained per stakeholder preference; revisit if it causes confusion.)* |

**Aliases (24 forms):** `aid-add-*` (12, mirrors all `aid-create*`) and `aid-update-*` (12, mirrors
all `aid-change*`) — the only aliases in the catalog.

### 5.2 Common behavior (every shortcut skill)

- FR-1: Invocable directly by name (`/aid-<verb> [artifact-type] [description]`), no interview/triage first.
- FR-2: Creates the `.aid/work-NNN-<name>/` work folder and STATE.md scaffold.
- FR-3: Authors the collapsed lifecycle documents — `REQUIREMENTS.md` + `SPEC.md` + `PLAN.md` — for the work (see §5.5).
- FR-4: Generates the executable task set as `tasks/task-NNN/` folders (flattened — **no** `delivery-NNN/`), ready for `/aid-execute` **after user approval** (the skill stops before Execute — see §5.5 FR-10).
- FR-5: Accepts the artifact type as a parameter and adapts the information capture + spec/task shape accordingly.

### 5.3 Artifact-type dimension (the noun axis)

The verb is the skill; the **artifact type is a required parameter/suffix**. The scaffolding knowledge
for each `verb × artifact-type` (what spec shape, what tasks) lives **inside the skills** — there is no
separate recipe/"profile" catalog (the old recipes are removed; see FR-14). Confirmed product artifact
types (parameterize `aid-create` / `aid-change`; `aid-fix` / `aid-refactor` stay bare):

| # | Artifact suffix | Covers (former recipe territory, now skill-internal) |
|---|---|---|
| 1 | **api** | api-endpoint, api-middleware |
| 2 | **ui** (structure) | ui-component, ui-endpoint (page) |
| 3 | **theme** (style) | ui-style (+ design tokens / theming) |
| 4 | **cli** | cli-command (+ automation script) |
| 5 | **data-model** | entity, schema (+ migration) |
| 6 | **data-pipeline** | *(new — ETL/ingestion/orchestration)* |
| 7 | **messaging** | message, queue, event-handler |
| 8 | **integration** | integration |
| 9 | **job** | job |
| 10 | **config** | config-option, feature-flag, rule |
| 11 | **infra** | container (+ IaC resource) |

**Internal code has no suffix** — `interface`, `member`, module, and the rename territory are the
domain of **bare `aid-create` / `aid-change`** (a `-code` suffix collides with the bare verb).

**Ownership boundary (adopted):** these belong wholly to their dedicated verb, not to `aid-create`:
**test → `aid-test`**, **experiment → `aid-experiment`**, **doc/content → `aid-document`**,
**report/dashboard → `aid-report` / `aid-show-dashboard`**.

### 5.4 Skill naming scheme

Skills are named **`/aid-{verb}[-{artifact}]`** — artifact suffix optional. Aliases allowed
(`aid-add` = `aid-create`; `aid-update` = `aid-change`). `aid-fix` and `aid-refactor` remain **bare**
(no artifact-suffixed variants): `aid-fix` = fix an issue/bug; `aid-refactor` = change/optimize/clean a
codebase without changing functionality. The full catalog is locked (§5.1).

### 5.5 Lite-path work structure — flattened single-feature / single-delivery

Every shortcut skill produces a **collapsed definition-phase** lite work. It **traverses the
definition phases — Describe → Define → Specify → Plan → Detail (NOT Execute)** — and emits the full
document set, **flattened to a single feature and a single delivery**, with **no `features/` folder and
no `delivery-NNN/` folder**:

```
.aid/work-NNN-<name>/
  STATE.md            work state + PROMOTED ## Delivery Lifecycle + ## Delivery Gate + ### Tasks lifecycle
  REQUIREMENTS.md     the requirements (10 sections, fast-captured)
  SPEC.md             the single feature spec                       (no features/ folder)
  PLAN.md             the single delivery plan (top-level ## Execution Graph)
  BLUEPRINT.md        the single delivery definition — objective, scope, GATE CRITERIA, task deps
  tasks/
    task-001/DETAIL.md    (6-section task def; NO per-task STATE.md — task state lives in STATE.md ### Tasks lifecycle)
    task-002/DETAIL.md
    ...
```

*(Naming: feature def = `SPEC.md`, delivery def = `BLUEPRINT.md`, task def = `DETAIL.md` — see §5.7 FR-15.)*

- **FR-6 (no skipped phases):** the skill produces the *full* artifact set — `REQUIREMENTS.md`,
  `SPEC.md` (single feature), `PLAN.md` + `BLUEPRINT.md` (single delivery), and one `DETAIL.md` per task
  under `tasks/`. It does not skip Define/Specify/Plan/Detail; it collapses them.
- **FR-7 (difference is capture, not artifacts):** what differs from the full path is the
  **information capture** — the work type is known upfront (verb + artifact), so the skill captures the
  minimum needed to fill each document rather than running multi-feature decomposition, per-phase
  interviews, or multi-delivery planning. **Objective: cut the red tape / bureaucracy of the full path
  while keeping its structured, traceable outputs.**
- **FR-8 (flattening rules):** exactly one feature ⇒ `SPEC.md` at the work root (no `features/`);
  exactly one delivery ⇒ its definition is `BLUEPRINT.md` at the work root and its lifecycle/gate **plus
  the per-task lifecycle are promoted into the work `STATE.md`** (`## Delivery Lifecycle`,
  `## Delivery Gate`, `### Tasks lifecycle`); tasks live at `tasks/task-NNN/DETAIL.md` with **no per-task
  `STATE.md`** (single delivery = single writer). No `deliveries/`/`delivery-NNN/` folder. The delivery's
  GATE CRITERIA live in `BLUEPRINT.md § GATE CRITERIA` (this is where the flat delivery gate reads them).
- **FR-9 (Lite-path adjustment):** this flattened layout differs from today's lite layout (work-root
  `SPEC.md` + `delivery-001/tasks/…`, no `REQUIREMENTS.md`/`PLAN.md`/`BLUEPRINT.md`). Adjusting the Lite
  path — and how `/aid-execute` and the dashboard state readers consume the flattened single-delivery
  layout (incl. the promoted `STATE.md` blocks and the `DETAIL.md` task files) — is in scope.
- **FR-10 (approval gate before execution):** the skill **stops after Detail** — it never executes. The
  produced documents MUST be **validated and approved by the user before any execution**. Execution is a
  separate, user-initiated `/aid-execute` run (human-gated-advancement invariant — the pipeline never
  auto-advances).
- **FR-11 (grading gate per document):** each generated document — `REQUIREMENTS.md`, `SPEC.md`,
  `PLAN.md`, `BLUEPRINT.md`, and each task `DETAIL.md` — MUST pass its phase's **Grading Gate**: a dispatched
  `aid-reviewer` writes the 7-column ledger, `grade.sh` computes the grade, and the document must clear
  the resolved `minimum_grade` via the REVIEW→FIX loop before the FR-10 approval gate. The shortcut
  removes information-capture red tape, **not** the quality gates.

### 5.6 Pipeline restructuring (the cutover)

To make the shortcut skills the *sole* lite entry and to unblock recipe removal, this work restructures
the front of the pipeline. These three changes are coupled (do them together or leave a routing hole):

- **FR-12 (`/aid-describe` → full-path only):** `/aid-describe` is reduced to the full-path interview.
  Its **lite path** (CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW) and its **TRIAGE routing state**
  are removed; it no longer reads the recipe catalog. Its full-path interview behavior is otherwise
  preserved.
- **FR-13 (new `/aid-triage` router):** a new skill for the "I don't know which path/skill" case. It
  captures a short description and **suggests** the right entry — the full path via `/aid-describe`, or a
  specific shortcut from the catalog. It is largely the **extraction** of `/aid-describe`'s former TRIAGE
  logic into a standalone skill. It routes/suggests only; it does not run the interview or scaffold work.
- **FR-14 (recipe catalog removed):** the `canonical/aid/recipes/` catalog is **deleted** — with
  `/aid-describe` full-only, nothing consumes it. The per-work-type scaffolding knowledge the recipes
  encoded migrates **into** the shortcut skills. No separate recipe/"profile" catalog is reintroduced
  under a new name (whether the skills share a lightweight internal reference is a `/aid-specify`
  implementation detail — see A-2, A-6). Any recipe-specific machinery (`parse-recipe.sh` and its tests)
  is retired/updated accordingly. The **shared `work-state-template.md`** carries a `**Recipe:**` field
  and a lite Path-Selection block (Path / Work-Type `bug-fix|new-feature|refactor` / `LITE-*` sub-paths)
  that this change orphans (lite + triage leave `aid-describe`; recipes are gone) — these template
  surfaces are removed/updated for the verb-first model as part of FR-14.

**Resulting user entry model:** (1) knows they want the **full path** → `/aid-describe`; (2) knows the
**specific change-type** → the matching `aid-<verb>[-<artifact>]` shortcut; (3) **unsure** → `/aid-triage`.

### 5.7 Work-artifact naming + full-path structure (both paths)

The three definition documents were all `SPEC.md` (feature, delivery, task) — an ambiguity that
collided in the dashboard readers. A consistent naming convention now applies to **both** paths:

| Definition | File | (was) |
|---|---|---|
| Feature | `SPEC.md` | — (unchanged) |
| Delivery | `BLUEPRINT.md` | delivery `SPEC.md` |
| Task | `DETAIL.md` | task `SPEC.md` |

- **FR-15 (artifact naming, both paths):** feature definitions are `SPEC.md`, delivery definitions
  `BLUEPRINT.md`, task definitions `DETAIL.md`. Resolves the `SPEC.md` overload and gives the flat
  delivery gate a criteria home (`BLUEPRINT.md § GATE CRITERIA`).

**Full-path work structure** (the existing full pipeline adopts the rename + a `deliveries/` group):

```
.aid/work-NNN-<name>/
  STATE.md
  REQUIREMENTS.md
  features/feature-NNN-<name>/SPEC.md
  PLAN.md                     deliverables + per-delivery #### Execution Graph
  deliveries/
    delivery-NNN/
      BLUEPRINT.md            objective, scope, GATE CRITERIA, tasks, deps
      STATE.md                delivery lifecycle + Delivery Gate + Q&A + Tasks State (DERIVED)
      tasks/task-NNN/{DETAIL.md, STATE.md}
```

- **FR-16 (full-path pipeline rename — in scope):** the existing full-path pipeline is refactored to the
  structure above — delivery `SPEC.md` → `BLUEPRINT.md`, task `SPEC.md` → `DETAIL.md`, and delivery
  folders grouped under `deliveries/`. This touches the shipped `aid-plan`, `aid-detail`, `aid-execute`,
  the delivery/task templates, both dashboard reader twins, and the existing canonical tests — a
  **pipeline-wide structural rename** beyond the original "lite-path adjustments" (deliberate scope
  expansion, 2026-07-08). It also fixes the shipped delivery-gate criteria mis-wire (gate now reads
  `BLUEPRINT.md § GATE CRITERIA`, not a non-existent PLAN.md block). Per **A-10** this is a clean
  switch — the consumers/tests adopt the new layouts and drop the old; no migration, no dual old/new
  support, no MIGRATE tasks.
- **FR-17 (short-path promotions):** in the flat short path (§5.5) the single delivery's `BLUEPRINT.md`
  sits at the work root; its lifecycle/gate and the per-task lifecycle are promoted into the work
  `STATE.md` (`## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle`); task folders hold
  only `DETAIL.md` (no per-task `STATE.md`).

## 6. Non-Functional Requirements

- **NFR-1 (single source of truth):** all skills authored in `canonical/skills/`, rendered to the five
  profiles via the full `run_generator.py`; the VERIFY byte-compare + `render-drift` CI must stay green.
  Rendered/dogfood/vendored copies are never hand-edited.
- **NFR-2 (content isolation):** every skill carries the `aid-` prefix; any scripts/templates live under
  the `aid/` subtree.
- **NFR-3 (polyglot parity):** identical behavior across all five host tools; only model-tier/format
  differ per profile.
- **NFR-4 (prose-first):** skill logic is authored as SKILL.md state-machine prose; a script is added
  only for real, reused, deterministic logic.
- **NFR-5 (speed & discoverability — the whole point):** a user must guess the right skill name
  first-try (consistent verb-first scheme), and invoking a shortcut must be materially faster (fewer
  prompts/turns) than going through the full interview — that speed *is* the value. (Measured by AC-12.)
- **NFR-6 (quality-gate compliance):** each new/changed skill passes an `aid-reviewer` review at grade ≥
  the resolved `minimum_grade` (live gate: **A+**) before shipping.
- **NFR-7 (no regression, with intended changes named):** the existing skills **not** named in §5.6 and
  the full-path pipeline are preserved. `/aid-describe` is **deliberately** reduced to full-only and its
  triage **moved** to `/aid-triage` — so the full/lite routing *capability* is preserved (relocated), not
  lost; and re-purposing `aid-deploy`/`aid-monitor` must keep their current pipeline role working.
- **NFR-8 (maintenance scale):** ~45 skills + the router must not multiply maintenance cost — favor
  shared machinery (one direct-entry mechanism; skills sharing common scaffolding logic) over bespoke
  per-skill implementations.
- **NFR-9 (shipped-script hygiene):** any shipped scripts are LF-only (`.sh`) / ASCII-only (PowerShell),
  with Bash↔PowerShell parity.
- **NFR-10 (human-gated):** no auto-advance; the mandatory approval gate before execution (FR-10) is
  preserved.

## 7. Constraints

- **C-1:** Edit `canonical/` only; render with the full `run_generator.py` into
  `.claude`/`.codex`/`.cursor`/`.github`/`.agent`; re-sync the dogfood `.claude/`.
- **C-2:** Conform to the skill state-machine model (`SKILL.md` + `references/state-*.md`) and the
  agent-dispatch model (reviewer tier ≥ executor; writer never grades own work).
- **C-3:** Reuse existing Lite-path machinery and templates where possible (work-state / requirements /
  spec / plan templates, `state-machine-chaining.md`). The `aid-describe` refactor must preserve its
  full-path interview engine (elicitation-engine, calibration, NFR-7 question envelope) intact.
- **C-4:** Recipe **removal** (FR-14) must respect the emission-manifest / pure-mirror-deletion boundary
  (deleting recipe files from `canonical/` → the generator removes them from the profiles) and keep the
  canonical test suites green (retire/replace `parse-recipe` tests; dogfood byte-identity).
- **C-5:** Honor the invariants — version lockstep, LF+ASCII, polyglot parity, human-gated advancement.
- **C-6:** `aid-deploy` and `aid-monitor` already exist (Deliver-group pipeline skills); re-purposing
  them must not break their current role.
- **C-7:** No name collisions. New shortcut verbs + `aid-triage` are free; `aid-deploy`/`aid-monitor` are
  deliberate re-purposes; `aid-describe` is deliberately **modified** (not a collision). Existing
  `aid-config`/`discover`/`define`/`specify`/`plan`/`detail`/`execute`/`housekeep`/`query-kb`/`update-kb`/
  `summarize` and maintainer `generate-profile` are untouched.
- **C-8:** The flattened lite layout (§5.5) must remain consumable by `/aid-execute` and the dashboard
  state readers.

## 8. Assumptions & Dependencies

- **A-1:** Target output is a flattened lite work covering Describe→Detail only, user-approved before any
  execution (FR-6/FR-10).
- **A-2 (OPEN — spec-phase decision):** *implementation topology* — whether the 45 named forms are 45
  separate `SKILL.md` directories, or a smaller set of verb skills that take the artifact as a parameter
  with the `-{artifact}` forms as thin alias/entry points. Requirements fix the user-facing naming +
  behavior; the file topology is deferred to `/aid-specify`. Materially affects NFR-8.
- **A-3:** With `/aid-describe` full-only (FR-12), the recipe catalog has no consumer and is removed
  (FR-14); the per-work-type scaffolding knowledge migrates into the shortcut skills — **not** into a
  renamed catalog.
- **A-4:** `aid-deploy` / `aid-monitor` exist and can be re-purposed.
- **A-5:** `/aid-triage` (FR-13) is largely the extraction of `/aid-describe`'s existing TRIAGE state;
  the routing logic already exists and is relocated, reducing net-new design risk.
- **A-6 (OPEN — spec-phase, from cross-ref finding ④):** do the non-code groups (prototype / experiment /
  report / show-dashboard) require task types beyond `/aid-execute`'s fixed 8-type enum + delivery gate,
  or do they map onto existing types? If new types are needed, that is a pipeline-contract change to
  scope in `/aid-specify`.
- **A-7 (OPEN — spec-phase, from finding ⑤):** reconcile FR-11's per-document grading gates with NFR-5's
  "materially faster" — e.g. lightweight/batched reviews for the small flattened docs — in `/aid-specify`.
- **A-8 (OPEN — spec-phase, from finding ⑥):** where do delivery-scoped state fields (gate grade,
  delivery lifecycle, per-delivery git branch) live once `delivery-NNN/` is removed? Resolve in
  feature-001 / `/aid-specify`.
- **A-9 (OPEN — spec-phase, from finding ⑧):** reconcile `aid-deploy`/`aid-monitor`'s opposite pipeline
  lifecycle positions with a uniform shortcut-entry model in `/aid-specify`.
- **A-10 (no migration / no backward-compatibility — user directive 2026-07-08):** ALL structural &
  naming changes (FR-15/16/17) apply to **future works only**. Existing works are NOT migrated, and the
  shipped `aid-execute` / dashboard readers / tests need **not** support the pre-rename nested
  `delivery-NNN/SPEC.md` layout — they simply switch to the two new layouts (full-path
  `deliveries/…/BLUEPRINT.md`+`DETAIL.md`, and short-path flattened). This removes all MIGRATE-type work,
  any dual old/new code path, and the mixed-vintage reader fixtures — the consumers support only the two
  new current layouts.
- **D-1:** Depends on the generator (`run_generator.py`) + emission manifests and CI jobs (`render-drift`,
  `kb-hygiene`, `cli-parity`).
- **D-2:** `/aid-describe`'s current TRIAGE state (routing + the recipe slot-fill precedent) is the source
  material for both `/aid-triage` (FR-13) and the shortcut skills' direct-entry mechanism.
- **D-3:** Depends on the existing lifecycle templates (work-state, requirements, spec, plan) and the task
  file schema.

## 9. Acceptance Criteria

- **AC-1:** All 45 canonical shortcut skills exist in `canonical/skills/`, each with a valid SKILL.md
  state machine and the `aid-` prefix; the 24 aliases (`aid-add-*`, `aid-update-*`) resolve correctly.
- **AC-2:** Invoking a shortcut (with optional artifact + description) creates a **flattened lite work**
  (`REQUIREMENTS.md` + `SPEC.md` + `PLAN.md` + `tasks/task-NNN/`) — no `features/`, no `delivery-NNN/` —
  without any interview/triage.
- **AC-3:** The skill runs **Describe→Detail only** and halts at the approval gate; no execution happens
  until the user approves and separately runs `/aid-execute` (FR-10).
- **AC-4:** The artifact suffix/parameter drives the correct scaffolding (spec shape + task set); `aid-fix`
  / `aid-refactor` stay bare; `aid-create` / `aid-change` expand across the 11 artifact suffixes.
- **AC-5:** The recipe catalog is **removed** — `canonical/aid/recipes/` is deleted, no skill, script,
  **or shared template** still references it (including the `work-state-template.md` `Recipe` field +
  lite Path-Selection block, which are removed/updated for the verb-first model), recipe-specific tests
  are retired/replaced, and `render-drift` is green after the deletion.
- **AC-6:** `run_generator.py` renders every skill (shortcuts + `aid-triage` + refactored `aid-describe`)
  to all five profiles; VERIFY + `render-drift` CI green; the dogfood `.claude/` is byte-identical.
- **AC-7:** Each new/changed skill scores ≥ the resolved `minimum_grade` (A+) under `aid-reviewer`.
- **AC-8:** `/aid-execute` and the dashboard state readers correctly consume the flattened single-delivery
  layout.
- **AC-9:** No regression in skills **not** named in §5.6 or the full-path pipeline; `tests/run-all.sh`
  green.
- **AC-10:** `/aid-describe` is reduced to full-path-only (its lite path + TRIAGE state removed, recipe
  reads gone) **and** `/aid-triage` exists and covers the routing that `/aid-describe` used to do — i.e.
  the full/lite routing capability is preserved, relocated to `/aid-triage`.
- **AC-11:** Every generated document (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, and each
  task `DETAIL.md`) has passed its Grading Gate at ≥ `minimum_grade` before the FR-10 approval gate is
  reached.
- **AC-12 (NFR-5 measurability):** for a representative change, invoking a shortcut reaches the approved
  task set in materially fewer prompts/turns than the full `/aid-describe` interview would for the same
  work; and a user can derive the correct skill name from {verb}+{artifact} without consulting docs
  (validated on a small skill-name-guessing sample).
- **AC-13 (`/aid-triage` routing):** given a free-form description, `/aid-triage` suggests the correct
  entry — the full path via `/aid-describe` for broad/ambiguous work, or the specific matching shortcut
  for a known change-type.
- **AC-14 (`/aid-describe` full-only):** running `/aid-describe` goes straight into the full-path
  interview — there is no lite branch and no triage prompt; an unsure user is directed to `/aid-triage`.
- **AC-15 (artifact naming, both paths):** no `SPEC.md` names a delivery or a task anywhere — delivery
  definitions are `BLUEPRINT.md`, task definitions are `DETAIL.md`, feature definitions remain `SPEC.md`;
  a grep over produced works confirms the convention holds in both the full and short layouts.
- **AC-16 (full-path structure + gate-criteria fix):** the full path produces
  `deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`; `aid-plan`/
  `aid-detail`/`aid-execute`, the templates, both dashboard reader twins, and the existing tests resolve
  the new paths (no reference to the old `delivery-NNN/SPEC.md` / task `SPEC.md`); the delivery gate reads
  its criteria from `BLUEPRINT.md § GATE CRITERIA`; `tests/run-all.sh` + `render-drift` green.
- **AC-17 (short-path promotions):** a shortcut-produced flat work has `BLUEPRINT.md` at the root, the
  `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` blocks in the work `STATE.md`, and
  `tasks/task-NNN/DETAIL.md` with no per-task `STATE.md`; both reader twins render it correctly.

## 10. Priority

*(Proposed sequencing — MoSCoW + phasing. Pending stakeholder confirmation.)*

- **Must — Phase 1 (foundation):** the Lite-path adjustment — the flattened single-feature/single-delivery
  structure (§5.5) + the shared direct-entry mechanism + the approval gate + the per-document grading
  gates. Nothing else can ship without this.
- **Must — Phase 2 (high-frequency pilot cohort):** `aid-fix`, `aid-refactor`, `aid-create` (+`-api`,
  `-ui`), `aid-change` (+`-api`, `-ui`), `aid-test`. (Pilot vs. breadth is a *delivery* split **within**
  the create/change/test families — those features are Must because they contain pilot skills; their
  remaining suffixes ship in Phase 3.)
- **Should — Phase 3 (breadth):** the remaining `aid-create`/`aid-change` artifact suffixes, the
  `aid-document` family, `aid-prototype`, `aid-experiment`, `aid-report` / `aid-show-dashboard`.
- **Must — Cutover (after shortcuts exist):** `/aid-describe` → full-only (FR-12) + new `/aid-triage`
  (FR-13) + recipe removal (FR-14). Sequenced last because it removes the old lite entry — the shortcuts
  must be in place first so no capability gap exists during the switch.
- **Could:** re-purpose `aid-deploy` / `aid-monitor` as shortcuts.
