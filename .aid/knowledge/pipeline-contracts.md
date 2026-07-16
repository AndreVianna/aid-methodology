---
kb-category: primary
source: hand-authored
objective: The typed artifact contracts and state-machine transitions between AID pipeline phases — what each phase consumes, produces, and gates on.
summary: Read this before changing any skill, artifact template, or phase hand-off. It is the workflow + contract layer of the AID methodology — the three entry doors, the phase-to-phase data contracts, the on-disk work hierarchy (full + flattened Lite), the per-skill state machines, the grading gate, and the eleven feedback loops.
sources:
  - docs/aid-methodology.md
  - canonical/skills/
  - canonical/aid/templates/work-state-template.md
  - canonical/aid/templates/grading-rubric.md
  - canonical/aid/templates/requirements.md
  - canonical/aid/templates/delivery-blueprint-template.md
  - canonical/aid/templates/task-detail-template.md
  - canonical/aid/templates/shortcut-engine.md
  - .aid/settings.yml
tags: [C2, pipeline, contracts, phases, artifacts, state-machines, feedback-loops]
see_also: [integration-map.md, architecture.md, domain-glossary.md, artifact-schemas.md]
owner: architect
audience: [developer, architect]
intent: |
  The typed data contracts between AID pipeline phases — artifact hand-offs, state-machine
  transitions, the grading gate, and the feedback loops. Read this when modifying a skill,
  an artifact template, or any phase boundary.
contracts: []
changelog:
  - 2026-07-09: work-001 lite-skills refresh -- rewrote the entry model (three doors -- verb-first shortcut / /aid-triage / /aid-describe) and the flattened Lite path (shared shortcut engine INTAKE->CAPTURE->SPEC->PLAN->DETAIL->GATE->APPROVAL-HALT producing work-root REQUIREMENTS.md/SPEC.md/PLAN.md/BLUEPRINT.md + tasks/task-NNN/DETAIL.md, no per-task STATE.md); renamed delivery def to BLUEPRINT.md and task def to DETAIL.md; bound L9 -> /aid-fix and L10 -> /aid-triage; removed the recipe system and aid-describe's TRIAGE/lite states; skill taxonomy now 82 directories.
  - 2026-06-28: Relabeled Phase 2 from "Interview" to "Describe → Define" throughout (Phase 2 label now "Describe → Define" in all prose).
  - 2026-06-28: Reconciled Phase 2 to the aid-interview split (aid-describe 2a + aid-define 2b); rewrote the Phase-2 state-machine model; added the greenfield forward-authoring entry + the conformance feedback; skill count 13 -> 14
  - 2026-06-25: Initial generation (aid-discover brownfield deep-dive / Integrator lane)
---

# Pipeline Contracts

> **Source:** aid-discover (brownfield deep-dive — Integrator)
> **Status:** Complete
> **Last Updated:** 2026-07-09

This project's "pipeline" is the AID methodology itself: a sequence of skills that hand
typed markdown artifacts from one phase to the next, each phase gated by a human and a
deterministic grade. This document is the contract layer of that pipeline — not an HTTP/API
surface. (AID exposes almost no network API; the one runtime HTTP surface, the dashboard
server, is documented in [integration-map.md](integration-map.md).)

## Contents

- [How the Pipeline Works](#how-the-pipeline-works)
- [Phase Input/Output Contracts](#phase-inputoutput-contracts)
- [The On-Disk Work Hierarchy](#the-on-disk-work-hierarchy)
- [Typed Artifact Contracts](#typed-artifact-contracts)
- [Per-Skill State Machines](#per-skill-state-machines)
- [The Grading Gate Contract](#the-grading-gate-contract)
- [Feedback Loop Contracts](#feedback-loop-contracts)
- [Configuration Contract](#configuration-contract)
- [Known Issues](#known-issues)
- [Conventions](#conventions)
- [Contracts](#contracts)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## How the Pipeline Works

AID is a six-phase sequential pipeline with formal feedback loops. Each phase is a skill
(a slash command resolving to a `SKILL.md` state machine); Phase 2 (Describe → Define) is realized
by two chained skills, `aid-describe` (2a) and `aid-define` (2b). The human approves every
phase transition — the pipeline never auto-advances. CONFIRMED: `docs/aid-methodology.md`
("## 1. The Pipeline", "Between phases, the human gives the OK to advance").

Two contract facts shape every hand-off:

- **Artifacts are typed markdown files under `.aid/`.** Each phase reads named files from a
  prior phase and writes named files for the next. The file name and location are the
  contract — downstream skills navigate by convention, never by search.
- **Three entry doors, two paths.** The *full path* runs every numbered phase and is entered
  by `/aid-describe` (broad or new-project work). The *flattened Lite path* is entered by
  naming the change with a verb-first **shortcut** (`/aid-<verb>[-<artifact>]`, e.g. `/aid-fix`,
  `/aid-create-api`) — each shortcut is a thin doorway into the shared **shortcut engine**
  (`shortcut-engine.md`) that collapses Describe → Define → Specify → Plan → Detail into one
  fast, mostly-autonomous run. A third door, **`/aid-triage`**, is a stateless, write-free,
  *suggest-only* router: it points at the matching shortcut or at `/aid-describe`, then stops.
  `/aid-describe` is **full-path only** — it no longer triages or emits Lite work. CONFIRMED:
  `docs/aid-methodology.md` ("## 4. The Phases", "The Lite Path: Direct-Entry Shortcuts");
  `canonical/aid/templates/shortcut-engine.md`; `canonical/skills/aid-triage/SKILL.md`;
  `canonical/skills/aid-describe/SKILL.md` (frontmatter `State machine:` — no TRIAGE/lite states).

---

## Phase Input/Output Contracts

The mandatory pipeline is six numbered phases; `aid-config` precedes it (bootstrap) and
`aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`, `aid-query-kb` (+ its friendly
alias `aid-ask`), `aid-update-kb` are off-pipeline or optional. The 64 verb-first shortcuts and
`/aid-triage` are direct-entry skills that sit outside the numbered pipeline (the shortcuts
drive the shortcut engine; triage only suggests). CONFIRMED: `docs/aid-methodology.md` ("Skill
Inventory" table, "§4 The Phases").

| # | Phase (skill) | Consumes | Produces | Gate |
|---|---------------|----------|----------|------|
| — | `aid-config` (bootstrap) | user metadata (greenfield/brownfield, name, min grade) | `.aid/` scaffold · KB placeholders · context file (`CLAUDE.md`/`AGENTS.md`) · seeded `STATE.md` · `settings.yml` | none (setup) |
| 1 | `aid-discover` (full path; brownfield) | repository source · `project-index.md` pre-pass · confirmed `discovery.doc_set` | the confirmed KB doc-set · `INDEX.md` · `README.md` · discovery-area `STATE.md` grade/Q&A · ELICIT E1: `## External Documentation` in `.aid/knowledge/STATE.md` (population signal into `external-sources.md`, written by Scout) · ELICIT E2: `.aid/connectors/` registry (descriptors + `INDEX.md`) | deterministic grade ≥ minimum + human approval |
| 2a | `aid-describe` (full path only) | `.aid/knowledge/` · user answers | approved `REQUIREMENTS.md` (+ greenfield: a forward-authored KB seed in `.aid/knowledge/`) | grade ≥ minimum + human approval |
| 2b | `aid-define` (full path only) | approved `REQUIREMENTS.md` · KB · codebase | per-feature `SPEC.md` stubs in `features/` + cross-reference Q&A | grade ≥ minimum + human approval |
| 3 | `aid-specify` (full path only) | a feature `SPEC.md` (requirements side) · `REQUIREMENTS.md` · KB · codebase | `## Technical Specification` appended to the feature `SPEC.md` | per-section grade ≥ minimum |
| 4 | `aid-plan` (full path only) | feature `SPEC.md` files marked `Ready` · `REQUIREMENTS.md` · KB | `PLAN.md` (ordered deliveries) + per-delivery `BLUEPRINT.md` stubs (objective/scope/gate criteria) + delivery `STATE.md` (`Pending-Spec`) | grade ≥ minimum |
| 5 | `aid-detail` (full path only) | `PLAN.md` · feature `SPEC.md` · `BLUEPRINT.md` · KB | per-task `DETAIL.md` files + execution graph appended to `PLAN.md` | grade ≥ minimum |
| 6 | `aid-execute` | task `DETAIL.md` (with Type) · `PLAN.md` · feature `SPEC.md` · `BLUEPRINT.md` · `INDEX.md` · `known-issues.md` (if present) | reviewed/graded artifacts to grade ≥ minimum; results in delivery/task `STATE.md` | per-task quick-check + delivery-gate grade ≥ minimum |

CONFIRMED by the per-phase deep-dives in `docs/aid-methodology.md` ("## 4. The Phases"),
the artifact table ("Skill Inventory"), and the `aid-describe` / `aid-define`
`SKILL.md` files (frontmatter `State machine:` + State Detection blocks). The **flattened Lite
path** produces the same artifact *types* at the work root, collapsed: the shortcut engine
authors `REQUIREMENTS.md` (CAPTURE), a single work-root feature `SPEC.md` (SPEC), `PLAN.md` +
`BLUEPRINT.md` (PLAN), and `tasks/task-NNN/DETAIL.md` (DETAIL) — see the On-Disk Work Hierarchy
below. CONFIRMED: `canonical/aid/templates/shortcut-engine.md` (CAPTURE/SPEC/PLAN/DETAIL steps);
`docs/aid-methodology.md` ("Skill Inventory" shortcut row, "The Lite Path").

Greenfield projects skip phase 1 (no existing system) and enter at Describe (2a). Instead of
"a minimal KB", `aid-describe`'s DESCRIBE-SEED state **forward-authors** a 5-element KB seed
(concept-spine + intended architecture + conventions + tech stack + decisions) into
`.aid/knowledge/`, stamped `source: forward-authored` — the docs are authored as the source of
truth before any code exists. CONFIRMED:
`canonical/skills/aid-describe/references/state-describe-seed.md` ("Record Sink");
`docs/aid-methodology.md` ("The Full Path").

---

## The On-Disk Work Hierarchy

A *work* is a self-contained scope unit under `.aid/`. The shape diverges by path. On the
**full path** (via `/aid-describe` → the numbered phases) deliveries are nested under a
`deliveries/` parent (mirroring `features/`). On the **flattened Lite path** (via a verb-first
shortcut → the shortcut engine) there is exactly one delivery and **no `deliveries/` folder at
all** — the work IS the delivery, and the delivery's definition, lifecycle, gate, and task
cells are authored directly at the work root.

**Full path:**

```
.aid/
  knowledge/                                  # shared KB (from Discovery) — one per project
  work-NNN-{slug}/
    STATE.md                                  # work-area run-state (DERIVED rollups + Q&A)
    REQUIREMENTS.md                           # full path only
    features/feature-NNN-{name}/
      SPEC.md                                 # feature definition (Define) + tech spec (Specify)
      STATE.md                                # feature-level state
    PLAN.md                                   # full path only (Detail appends the execution graph)
    deliveries/delivery-NNN/
      BLUEPRINT.md                            # delivery definition (objective/scope/gate criteria/tasks)
      STATE.md                                # delivery lifecycle + gate + delivery-scoped Q&A
      tasks/task-NNN/
        DETAIL.md                             # the task definition (Type, Source, Depends on, Scope, AC)
        STATE.md                              # mutable task cells (State, Review, Elapsed, Notes)
    IMPEDIMENT-task-NNN.md                     # written by Execute on an unresolved contradiction
    packages/package-NNN-{slug}.md             # written by Deploy
    DEPLOYMENT-STATE.md · MONITOR-STATE.md     # written by Deploy / Monitor
```

**Flattened Lite path** (no `deliveries/`, no `delivery-NNN/` folder, and no per-task `STATE.md`):

```
.aid/
  knowledge/                                  # shared KB (from Discovery) — one per project
  work-NNN-{slug}/
    STATE.md                                  # work-area run-state; ALSO carries the sole
                                               # delivery's ## Delivery Lifecycle (with its
                                               # ### Tasks lifecycle table) / ## Delivery Gate /
                                               # ## Cross-phase Q&A (AUTHORED directly)
    REQUIREMENTS.md                           # shortcut engine CAPTURE
    SPEC.md                                   # single work-root feature spec (requirements + technical)
    PLAN.md                                   # single-delivery plan + execution graph
    BLUEPRINT.md                              # the sole delivery's definition, at the work root
    tasks/task-NNN/
      DETAIL.md                               # the task definition — IMMUTABLE, no sibling STATE.md;
                                               # mutable cells live in STATE.md ### Tasks lifecycle
    IMPEDIMENT-task-NNN.md                     # written by Execute on an unresolved contradiction
    packages/package-NNN-{slug}.md             # written by Deploy
    DEPLOYMENT-STATE.md · MONITOR-STATE.md     # written by Deploy / Monitor
```

CONFIRMED: `canonical/aid/templates/work-state-template.md` (`deliveries/delivery-NNN/STATE.md`
blocks for the full path; the AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` /
`## Delivery Gate` sections for the single-delivery flattened work) and
`canonical/aid/templates/delivery-state-template.md` / `delivery-blueprint-template.md`
(full-path-only header notes; the flattened work authors these directly in the work-root
STATE.md and a work-root `BLUEPRINT.md`). The `features/` folder is created by `aid-define` (2b)
FEATURE-DECOMPOSITION, not by the interview half — CONFIRMED: `canonical/skills/aid-define/SKILL.md`
("Workspace structure", "created by FEATURE-DECOMPOSITION").

The flattened Lite path omits `features/`, `deliveries/`, and `delivery-NNN/`, and creates **no
per-task `STATE.md`**: the shortcut engine writes work-root `REQUIREMENTS.md` + `SPEC.md` +
`PLAN.md` + `BLUEPRINT.md` plus one `tasks/task-NNN/DETAIL.md` per task, and each task's mutable
cells are authored into the work-root `STATE.md § ### Tasks lifecycle` table (targeted by
`writeback-state.sh`'s auto-detected flat-layout branch). CONFIRMED:
`canonical/aid/templates/shortcut-engine.md` ("emits `tasks/task-NNN/DETAIL.md` … no per-task
`STATE.md`"); `canonical/aid/scripts/execute/writeback-state.sh` (flattened-layout `--task-id`
targets `### Tasks lifecycle`); `docs/aid-methodology.md` ("Detail is skipped on the lite path …
with no per-task `STATE.md`").

---

## Typed Artifact Contracts

Each artifact is a markdown file with a required shape. The shape — not just the file name —
is the contract a producing phase must satisfy and a consuming phase relies on.

| Artifact | Produced by | Consumed by | Required shape (load-bearing fields) | Lifecycle |
|----------|-------------|-------------|--------------------------------------|-----------|
| KB doc-set | Discover (brownfield) / `aid-describe` DESCRIBE-SEED (greenfield seed) | all phases | per-doc frontmatter (`kb-category`, `source`, `objective`, `summary`, `sources`, `tags`, `audience`, `owner`) + `# Title` + content + `## Change Log` | living |
| `INDEX.md` | config/Discover/Describe | all phases | one 2–3 line summary row per KB doc | regenerated, never hand-maintained |
| `STATE.md` (discovery area) | config/Discover/Summarize | Discover (resume), all phases | grade, Q&A (Pending), review & summarization history, calibration log; ELICIT (State 0) additionally writes `## Discovery Elicitation` (Sources/Tools/Tools step/Skipped/Resolved) and `## External Documentation` (Path/Type/Accessible/Notes, one row per declared source — E1) | living |
| `.aid/connectors/` registry | `aid-discover` ELICIT (State 0, Step E2) | all phases (agents requesting a declared integration) | one `<stem>.md` descriptor per connector (`name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference` [aid-managed only], `preset`, `objective`, `summary`, `tags`, `audience`) + generated `INDEX.md` | living, reconciled (add/update/remove) each ELICIT cycle |
| `REQUIREMENTS.md` | `aid-describe` (full) or shortcut engine CAPTURE (flattened Lite) | Define, Specify, Plan (full); SPEC/PLAN/DETAIL (engine) | `## Change Log` + 10 numbered sections (Objective … Priority) | frozen after approval, rev-tracked |
| feature `SPEC.md` | `aid-define` + Specify | Plan, Detail, Execute | `## Change Log` · Source · Description · User Stories · Priority · Acceptance Criteria · `## Technical Specification` (Specify) | living |
| work-root `SPEC.md` (flattened Lite) | shortcut engine SPEC | engine PLAN/DETAIL, Execute | single consolidated feature spec (`# {Title}`, Change Log, Source, Description, Acceptance Criteria, `## Technical Specification`), no `features/` | living |
| `PLAN.md` | Plan (full) or shortcut engine PLAN (flattened Lite) | Detail, Deploy | `## Deliverables` (ordered, each with What/Features/Depends on/Priority) + execution graph (Detail) + `## Revision History` | living, rev-tracked |
| `BLUEPRINT.md` (delivery definition) | `aid-plan` / `aid-specify` (full, at `deliveries/delivery-NNN/`) or shortcut engine PLAN (flattened Lite, at work root) | Detail, Execute (delivery gate reads `## Gate Criteria`) | `## Objective` · `## Scope` (+ Out of scope) · `## Gate Criteria` (testable checkboxes; last = "All section-6 quality gates pass") · `## Tasks` (nav table) · `## Dependencies` · `## Notes` | immutable definition |
| task `DETAIL.md` | `aid-detail` (full) or shortcut engine DETAIL (flattened Lite) | Execute | `Type` ∈ {RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE} · Source · Depends on · Scope · Acceptance Criteria | immutable (rev-tracked if amended) |
| `IMPEDIMENT-task-NNN.md` | Execute | Specify, Detail, Discover | Summary · Type ∈ {wrong-assumption, missing-dependency, architecture-conflict, kb-gap} · Options · Recommendation | closed when resolved |
| `package-NNN-{slug}.md` | Deploy | Monitor, stakeholders | deliveries included · verification results · environment · release notes | one per shipped release |
| `MONITOR-STATE.md` | Monitor | `/aid-fix` (bugs), `/aid-triage` (CRs) | Last Run · Active Findings (Classification/Severity/Evidence/Routing) · Resolved Findings | living |

CONFIRMED by the template files under `canonical/aid/templates/` and the artifact reference
in `docs/aid-methodology.md` ("Skill Inventory" and "§4 The Phases"). The delivery `BLUEPRINT.md`
shape is CONFIRMED: `canonical/aid/templates/delivery-blueprint-template.md`; the task `DETAIL.md`
shape: `canonical/aid/templates/task-detail-template.md`. The ELICIT-produced rows
(`## Discovery Elicitation` / `## External Documentation` / `.aid/connectors/` registry) are
CONFIRMED: `canonical/skills/aid-discover/references/state-elicit.md` ("Step E1: External
SOURCES branch", "Step E2: Tool INTEGRATIONS branch", "Step E3: Record and chain").

The eight task **Types** are the central executor/reviewer contract: the Type drives both how
the executor works and how the reviewer evaluates the task. CONFIRMED:
`docs/aid-methodology.md` ("The eight task types are").

---

## Per-Skill State Machines

Every graded skill is a state machine: one invocation advances one state, then stops. No
auto-advance between states. CONFIRMED: `docs/aid-methodology.md` ("Discover runs as a state
machine … One invocation per state. No auto-advance").

| Skill | States (in order) |
|-------|-------------------|
| `aid-discover` | ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE |
| `aid-describe` (full, Phase 2a) | FIRST-RUN → Q-AND-A → CONTINUE → [greenfield: DESCRIBE-SEED →] COMPLETION (pauses → `/aid-define`) |
| `aid-define` (Phase 2b) | FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE (hands off → `/aid-specify`) |
| `aid-specify` | per-section universal loop: Propose → Discuss → Write → Review (re-run enters at Review) |
| `aid-plan` | universal loop applied per delivery: Propose → Discuss → Write → Review |
| `aid-detail` | universal loop per delivery producing task files → build execution graph |
| `aid-execute` | per-task universal loop (read type → execute → gates → reviewer dispatch → grade → fix/loopback) inside a parallel pool |
| `aid-triage` | INTAKE → CLASSIFY → SUGGEST → HALT (stateless, write-free, suggest-only) |
| shortcut skills (`/aid-<verb>[-<artifact>]`, shared `shortcut-engine.md`) | INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT (Describe→Detail collapsed & autonomous; never executes) |
| `aid-deploy` | package selection → final verification → package record → packaging → doc routing → status update |
| `aid-monitor` | Observe → Classify → Analyze → Propose → Act |
| `aid-housekeep` | PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE |
| `aid-update-kb` | ANALYZE → APPLY → REVIEW → APPROVAL → DONE |

CONFIRMED: per-skill `SKILL.md` files under `canonical/skills/` (`aid-describe/SKILL.md`
frontmatter `State machine:` + Dispatch table; `aid-define/SKILL.md`; `aid-triage/SKILL.md`);
`canonical/aid/templates/shortcut-engine.md` (the shared engine state machine); the
lite/housekeep/update sequences additionally in `docs/glossary.md` ("aid-housekeep",
"aid-update-kb"). **Phase 2 was one skill (`aid-interview`); it is now two:** the interview and
greenfield-seed states belong to `aid-describe` (2a) and feature-decomposition + cross-reference
belong to `aid-define` (2b). `aid-describe` no longer triages or emits Lite work — routing moved
to `/aid-triage` and Lite authoring moved to the shortcut engine. The `aid-interviewer` AGENT
was NOT renamed — only the skill split.

The **universal loop** (Propose, then Discuss, then Write, then Review) is shared by every full-path
design phase. Re-running a completed phase re-enters at Review and re-grades existing content
against current reality — the same loop handles creation and maintenance. The flattened Lite
path does NOT use the universal loop: the shortcut engine runs CAPTURE/SPEC/PLAN/DETAIL without
a per-state human checkpoint (the only interactive moments are a rare CAPTURE gap-question and
the terminal APPROVAL-HALT), and quality is enforced once at GATE. CONFIRMED:
`docs/aid-methodology.md` ("The universal loop", "The Lite Path: Direct-Entry Shortcuts").

**Execute parallel-pool contract:** in delivery mode Execute runs a continuous parallel pool
of up to `execution.max_parallel_tasks` tasks (default 5). A failed task blocks its transitive
dependents (BFS block-radius). If the host cannot dispatch in the background, the pool
degrades to sequential execution. CONFIRMED: `docs/aid-methodology.md` ("Parallel pool
dispatch"); `canonical/aid/scripts/execute/compute-block-radius.sh`; `.aid/settings.yml`
(`execution.max_parallel_tasks`).

---

## The Grading Gate Contract

Every phase that grades uses one deterministic rubric. The reviewer classifies each finding
by severity (`[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` / `[MINOR]`) and source
(`[CODE]` / `[TASK]` / `[SPEC]` / `[KB]`); it never assigns a letter grade. The grade is
*computed* by `grade.sh` from the bracketed severity tags — the worst severity present
dominates and the count within that tier sets the `+` / none / `-` modifier. The phase loops
until the computed grade meets the project minimum. CONFIRMED: `docs/aid-methodology.md`
("One grading rubric across the pipeline", "Review record format");
`canonical/aid/templates/grading-rubric.md`.

- **Grade scale:** A+ down to F, with an E band reserved for CRITICAL-severity findings.
  CONFIRMED: `.aid/settings.yml` (the `review.minimum_grade` comment listing
  `A+, A, … E+, E, E-, F`).
- **Minimum:** `review.minimum_grade` (global default `A`), with per-skill overrides (this
  project pins `summary.minimum_grade: A+`). CONFIRMED: `.aid/settings.yml`.
- **Reviewer-tier invariant:** the reviewer's model tier is always ≥ the executor's; the agent
  that writes never grades its own work. CONFIRMED: `docs/aid-methodology.md` ("## 5. The Agent
  Model"). See the agent tiers in [architecture.md](architecture.md).
- **Circuit breaker (Execute):** if the grade does not improve after 3 consecutive cycles,
  Execute stops. CONFIRMED: `docs/aid-methodology.md` ("Circuit breaker").
- **Two-tier review (Execute):** a Small-tier quick-check inside each task plus a delivery-gate
  full review-fix-review loop at the end of each delivery; High quick-check findings accumulate
  for the gate. CONFIRMED: `docs/aid-methodology.md` ("The two-tier review design").
- **Lite GATE:** the shortcut engine's GATE state grades every generated document
  (`REQUIREMENTS.md` / `SPEC.md` / `PLAN.md` / `BLUEPRINT.md` + each `DETAIL.md`) mechanically
  against the project minimum before the APPROVAL-HALT; it is the sole quality checkpoint on the
  Lite path. CONFIRMED: `canonical/aid/templates/shortcut-engine.md` (GATE state).

---

## Feedback Loop Contracts

The pipeline is sequential by default; eleven formal loops let a downstream phase revise an
upstream artifact. Each loop produces a formal record — a Q&A entry in a `STATE.md`, an
`IMPEDIMENT-task-NNN.md`, or a `MONITOR-STATE.md` finding — never a silent workaround.
CONFIRMED: `docs/aid-methodology.md` ("## 6. Feedback Loops").

| Loop | From | To | Trigger | Record |
|------|------|----|---------|--------|
| L1 | Describe (2a) | Discover | an answer reveals the KB is wrong/incomplete | Q&A in `.aid/knowledge/STATE.md` |
| L2 | Specify | Discover | spec exposes insufficient subsystem understanding | Q&A in `.aid/knowledge/STATE.md` |
| L3 | Plan | Discover | codebase more complex than the KB captured | Q&A in `.aid/knowledge/STATE.md` |
| L4 | Plan | Specify | KB complete but a SPEC is ambiguous/contradictory | Q&A in the feature `STATE.md` |
| L5 | Detail | Plan | plan too vague to decompose into tasks | flag on the under-specified deliverable |
| L6 | Execute | Discover / Specify / Detail | an assumption does not hold | `IMPEDIMENT-task-NNN.md` (routed by Type) |
| L7 | Execute Review | any upstream phase | reviewer finds TASK/SPEC/KB-sourced issues | source-tagged issue → loopback |
| L8 | Deploy | Execute | final verification (build+tests+lint) fails | routed back to `/aid-execute` |
| L9 | Monitor | `/aid-fix` (shortcut) | finding classified BUG | `MONITOR-STATE.md` finding |
| L10 | Monitor | `/aid-triage` | finding classified Change Request | `MONITOR-STATE.md` finding |
| L11 | any phase | Discover | KB found wrong/incomplete/stale | targeted re-discovery Q&A |

The IMPEDIMENT routing (L6) is by Type: `kb-gap` routes to Discover, `architecture-conflict`
to Specify, `missing-dependency` to Detail, and `wrong-assumption` to a task/SPEC update.
CONFIRMED: `docs/aid-methodology.md` ("Loop 6"). The Monitor re-points (L9/L10) are CONFIRMED:
`canonical/skills/aid-monitor/SKILL.md` ("bugs to /aid-fix, change requests to /aid-triage").

### Greenfield forward-authoring + the conformance feedback

Two design-first mechanisms extend the feedback model beyond the eleven loops:

- **Greenfield forward-authoring (entry, not a loop).** On a greenfield project the docs lead
  the code: `aid-describe`'s DESCRIBE-SEED state forward-authors the 5-element KB seed
  (`domain-glossary.md` + `architecture.md` + `coding-standards.md` + `technology-stack.md` +
  `decisions.md`) into `.aid/knowledge/`, each stamped `source: forward-authored`. The design
  IS the source of truth; downstream phases (`aid-specify`, `aid-plan`, `aid-execute`) read the
  seed unchanged. CONFIRMED: `canonical/skills/aid-describe/references/state-describe-seed.md`
  ("Record Sink", "Advance").
- **Build conformance check (code -> design, flag-not-overwrite).** `/aid-housekeep`'s KB-DELTA
  stage carries a **Conformance Lane**: it shadow-extracts an as-built KB from the current code
  and diffs it against the `source: forward-authored` design docs. Divergences
  (`placeholder-resolved` / `code-ahead` / `contradiction`) are FLAGGED for human reconciliation
  via a Required Q&A entry in `.aid/knowledge/STATE.md`; the design doc is NEVER auto-overwritten
  with as-built (authority stays design -> code until the human chooses to evolve the design via
  `/aid-discover` targeted re-entry). This is the inverse of the normal doc <- code direction.
  CONFIRMED: `canonical/skills/aid-housekeep/references/state-kb-delta.md` ("Conformance Lane",
  "Invariant -- flag, never overwrite").

---

## Configuration Contract

`.aid/settings.yml` is the single authoritative source every skill reads at invocation time
(via `read-setting.sh`). Skills MUST NOT hardcode values that exist here. CONFIRMED:
`.aid/settings.yml` (header "the AUTHORITATIVE source for all AID pipeline settings");
`canonical/aid/scripts/config/read-setting.sh`.

Load-bearing keys: `project.{name,description,type}`, `tools.installed`,
`review.minimum_grade` (+ per-skill overrides), `execution.max_parallel_tasks`,
`traceability.heartbeat_interval`, and `discovery.doc_set` (the project's KB document set).

---

## Known Issues

- No open pipeline-contract drift. The former methodology-doc drift (the flat
  `.aid/{work}/tasks/task-NNN.md` layout) is resolved: `docs/aid-methodology.md` now describes
  the nested full-path `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` shape and the flattened
  Lite `tasks/task-NNN/DETAIL.md` (no per-task `STATE.md`) shape, matching the live skills and
  templates.
- The skill taxonomy is now **108 skill directories** under `canonical/skills/`: 14 curated
  pipeline/on-demand/router skills + the 94-row shortcut catalog's skills (58 canonical + 36
  aliases) — 64 verb-first direct-entry shortcut doorways (generated from the 94-row
  `shortcut-catalog.yml`) plus 30 hand-authored `repurpose` skills — up from
  82 dirs / 67 shortcuts / a 69-row catalog before the v2.1.0 coverage-gap follow-on added the
  `remove`/`deprecate`/`migrate` + `review`/`research` families. The recipe system
  (`canonical/aid/recipes/`, `parse-recipe.sh`, `{{slot}}` placeholders) was removed and
  replaced by the shortcut engine + `shortcut-scaffolding/<family>.md`; the prior "51 vs 52
  recipes" count drift is closed. Agents (9) and KB doc types (14) are unchanged.

---

## Conventions

> How this project adds or changes a pipeline boundary.

- **A new phase/skill** is authored once in `canonical/skills/<name>/SKILL.md` as a state
  machine (states advance one invocation at a time), then rendered into the five profiles.
  Never edit `profiles/` directly. A new verb-first shortcut is added as a row in
  `canonical/aid/templates/shortcut-catalog.yml` and regenerated — the shortcut doorway is a
  thin delegate to `shortcut-engine.md`, never a hand-authored state machine.
- **A new artifact type** gets a template under `canonical/aid/templates/`, a fixed location
  under `.aid/{work}/`, and an entry in the artifact reference. Downstream skills find it by
  convention (fixed path), never by search.
- **A new feedback path** must produce a formal record (Q&A entry, IMPEDIMENT file, or
  MONITOR finding) with a revision trail — never an inline silent fix.

---

## Contracts

> The structural shapes a change MUST satisfy at a phase boundary.

- **Task contract:** every task `DETAIL.md` declares a `Type` from the eight-type enum, a
  `Source`, `Depends on` (`— (none)` for the first), `Scope`, and `Acceptance Criteria`. The
  executor and the reviewer both bind to the Type; changing the enum breaks both.
- **Grade contract:** reviewers emit bracketed `[SEVERITY]`/`[SOURCE]` tags only; `grade.sh`
  computes the letter. Any consumer of the grade depends on the deterministic mapping in
  `grading-rubric.md` — adding a severity tier or changing the dominance rule is a breaking
  change to every grading skill.
- **State-file contract:** run-state (grades, Q&A, history, rollups) lives in the area's
  `STATE.md`; the dashboard and `/aid-execute` read these files to track a pipeline. Artifact
  files alone are not trackable. On the flattened Lite path there is no per-task `STATE.md` —
  each task's cells live in the work-root `STATE.md § ### Tasks lifecycle`. Renaming or
  restructuring `STATE.md` sections breaks the dashboard reader (see
  [integration-map.md](integration-map.md)).
- **Forward-authored marker contract:** a greenfield seed doc carries `source: forward-authored`
  in its frontmatter; this marker is what routes the doc into the `/aid-housekeep` Conformance
  Lane (code -> design, flag-not-overwrite) instead of the normal doc <- code update lane.
  Dropping or changing the marker re-routes the doc and breaks the conformance check.
- **Compatibility rule:** artifact templates evolve additively — new optional sections/fields
  are safe; removing or renaming a load-bearing field is breaking and requires updating every
  producing and consuming skill in lockstep.

---

## Invariants

- **The pipeline never auto-advances.** Every phase transition requires explicit human
  approval (the "OK?" gate); a deterministic grade >= minimum is necessary but not sufficient
  -- both the grade gate and the human gate must pass. CONFIRMED in `docs/aid-methodology.md`
  ("## 1. The Pipeline").
- **Every inter-phase artifact is a typed markdown contract.** A phase consumes and produces
  the declared artifacts (see the Phase Input/Output Contracts table); a phase cannot start
  until its inputs exist and its predecessor's gate has passed.
- **Phase order is fixed.** The six numbered phases run Discover -> Describe/Define (Phase
  2a/2b) -> Specify -> Plan -> Detail -> Execute on the full path; the flattened Lite path (via
  the shortcut engine) collapses Describe through Detail into one autonomous run and hands off to
  Execute, but never reorders or renumbers the phases.
- **Forward-authored design is never auto-overwritten.** The conformance check flags
  code↔design divergence for the human; authority stays design -> code until the human
  explicitly evolves the design (see the Feedback Loop Contracts conformance subsection).
- **Contract fields evolve additively** -- removing or renaming a load-bearing field is a
  lockstep break (see the `## Contracts` Compatibility rule).

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial pipeline-contract mapping (Integrator deep-dive) |
| 1.1 | 2026-06-28 | manual | Reconciled Phase 2 to the `aid-interview` split: Phase 2a `aid-describe` (triage + interview + lite + greenfield seed) + Phase 2b `aid-define` (feature decomposition + cross-reference). Rewrote the Phase-2 state-machine model, added the greenfield forward-authoring entry + the conformance feedback, and updated the skill count to 14. |
| 1.2 | 2026-07-08 | PR #132 (branch `change-delivery`) | Delivery-folder layout rationalized: full path nests delivery folders under `deliveries/`; lite path drops the `delivery-001/` folder entirely (tasks live directly at `tasks/task-NNN/`; the sole delivery's gate + Q&A are AUTHORED in the work-root STATE.md). Rewrote the On-Disk Work Hierarchy section with separate full/lite diagrams and updated stale citations. |
| 1.3 | 2026-07-09 | housekeep KB-DELTA | Added ELICIT's outputs (E1 `## External Documentation` / E2 `.aid/connectors/` registry) to the Discover Phase-I/O row and the Typed Artifact Contracts table; corrected the 1.2 provenance to PR #132. |
| 1.4 | 2026-07-09 | work-001 lite-skills refresh | Rewrote the entry model (three doors: verb-first shortcut / `/aid-triage` / `/aid-describe`) and the flattened Lite path: the shared shortcut engine (`INTAKE→CAPTURE→SPEC→PLAN→DETAIL→GATE→APPROVAL-HALT`) authors work-root `REQUIREMENTS.md`/`SPEC.md`/`PLAN.md`/`BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` with **no per-task `STATE.md`** (cells live in `STATE.md § ### Tasks lifecycle`). Renamed the delivery definition to `BLUEPRINT.md` and the task definition to `DETAIL.md` across the phase table, artifact contracts, hierarchy trees, and state-machine table (fixing the deleted `delivery-spec-template.md` citation → `delivery-blueprint-template.md`); added a `BLUEPRINT.md` artifact-contract row. Removed `aid-describe`'s TRIAGE/lite states; added `/aid-triage` and the shortcut-engine state machines. Bound L9 → `/aid-fix` and L10 → `/aid-triage`. Retired the recipe system and the stale "14 skills / 51-52 recipes / methodology flat-layout" Known Issues; recorded the 82-directory taxonomy. |
| 1.5 | 2026-07-09 | v2.1.0 coverage-gap follow-on | Skill taxonomy 82 -> 92 directories (15 classic incl. restored `/aid-ask` + `/aid-triage` + 76 verb-first shortcuts, up from 67; catalog 69-row -> 80-row) for the new `remove`/`deprecate`/`migrate` (G5) and `review`/`research` (G11) shortcut families; updated the Phase Input/Output Contracts off-pipeline skill list and the Known Issues skill-count entry. |
