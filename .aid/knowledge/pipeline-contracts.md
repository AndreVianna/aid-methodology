---
kb-category: primary
source: hand-authored
objective: The typed artifact contracts and state-machine transitions between AID pipeline phases — what each phase consumes, produces, and gates on.
summary: Read this before changing any skill, artifact template, or phase hand-off. It is the workflow + contract layer of the AID methodology — the phase-to-phase data contracts, the on-disk work hierarchy, the per-skill state machines, the grading gate, and the eleven feedback loops.
sources:
  - docs/aid-methodology.md
  - canonical/skills/
  - canonical/aid/templates/work-state-template.md
  - canonical/aid/templates/grading-rubric.md
  - canonical/aid/templates/requirements.md
  - canonical/aid/templates/delivery-spec-template.md
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
  - 2026-06-25: Initial generation (aid-discover brownfield deep-dive / Integrator lane)
---

# Pipeline Contracts

> **Source:** aid-discover (brownfield deep-dive — Integrator)
> **Status:** Complete
> **Last Updated:** 2026-06-25

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
- [Change Log](#change-log)

---

## How the Pipeline Works

AID is a six-phase sequential pipeline with formal feedback loops. Each phase is a skill
(a slash command resolving to a `SKILL.md` state machine). The human approves every phase
transition — the pipeline never auto-advances. CONFIRMED: `docs/aid-methodology.md`
("## 1. The Pipeline", "Between phases, the human gives the OK to advance").

Two contract facts shape every hand-off:

- **Artifacts are typed markdown files under `.aid/`.** Each phase reads named files from a
  prior phase and writes named files for the next. The file name and location are the
  contract — downstream skills navigate by convention, never by search.
- **Two paths exist.** The *full path* runs every numbered phase; the *lite path* (routed by
  the Interview's TRIAGE state for small, single-target work) collapses Specify + Plan +
  Detail into Interview and emits tasks directly. CONFIRMED: `docs/aid-methodology.md`
  ("## 4. The Phases", "Lite Path").

---

## Phase Input/Output Contracts

The mandatory pipeline is six numbered phases; `aid-config` precedes it (bootstrap) and
`aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`, `aid-query-kb`, `aid-update-kb`
are off-pipeline or optional. CONFIRMED: `docs/aid-methodology.md` ("Skill Inventory" table).

| # | Phase (skill) | Consumes | Produces | Gate |
|---|---------------|----------|----------|------|
| — | `aid-config` (bootstrap) | user metadata (greenfield/brownfield, name, min grade) | `.aid/` scaffold · KB placeholders · context file (`CLAUDE.md`/`AGENTS.md`) · seeded `STATE.md` · `settings.yml` | none (setup) |
| 1 | `aid-discover` (full path; brownfield) | repository source · `project-index.md` pre-pass · confirmed `discovery.doc_set` | the confirmed KB doc-set · `INDEX.md` · `README.md` · discovery-area `STATE.md` grade/Q&A | deterministic grade ≥ minimum + human approval |
| 2 | `aid-interview` | `.aid/knowledge/` · user answers | full path: `REQUIREMENTS.md` + per-feature `SPEC.md` stubs · lite path: work-root `SPEC.md` + `tasks/` | grade ≥ minimum + human approval |
| 3 | `aid-specify` (full path only) | a feature `SPEC.md` (requirements side) · `REQUIREMENTS.md` · KB · codebase | `## Technical Specification` appended to the feature `SPEC.md` | per-section grade ≥ minimum |
| 4 | `aid-plan` (full path only) | feature `SPEC.md` files marked `Ready` · `REQUIREMENTS.md` · KB | `PLAN.md` (ordered deliveries) | grade ≥ minimum |
| 5 | `aid-detail` (full path only) | `PLAN.md` · feature `SPEC.md` · KB | per-task `SPEC.md` files + execution graph appended to `PLAN.md` | grade ≥ minimum |
| 6 | `aid-execute` | task `SPEC.md` (with Type) · `PLAN.md` · feature `SPEC.md` · `INDEX.md` · `known-issues.md` (if present) | reviewed/graded artifacts to grade ≥ minimum; results in delivery/task `STATE.md` | per-task quick-check + delivery-gate grade ≥ minimum |

CONFIRMED by the per-phase deep-dives in `docs/aid-methodology.md` ("## 4. The Phases") and
the artifact table ("## 7. Artifacts Reference").

Greenfield projects skip phase 1 (no existing system) and enter at Interview; a minimal KB is
populated from interview answers. CONFIRMED: `docs/aid-methodology.md` ("The Full Path").

---

## The On-Disk Work Hierarchy

Each Interview creates a *work* — a self-contained scope unit under `.aid/`. The live
hierarchy (after the work-hierarchy migration) nests deliveries and tasks; this is the
authoritative shape downstream skills and the dashboard read.

```
.aid/
  knowledge/                                  # shared KB (from Discovery) — one per project
  work-NNN-{slug}/
    STATE.md                                  # work-area run-state (DERIVED rollups + Q&A)
    REQUIREMENTS.md                           # full path only
    features/feature-NNN-{name}/
      SPEC.md                                 # requirements side (Interview) + tech spec (Specify)
      STATE.md                                # feature-level state
    PLAN.md                                   # full path only (Detail appends the execution graph)
    delivery-NNN/
      STATE.md                                # delivery lifecycle + gate + delivery-scoped Q&A
      tasks/task-NNN/
        SPEC.md                               # the task definition (Type, Source, Depends on, Scope, AC)
        STATE.md                              # mutable task cells (State, Review, Elapsed, Notes)
    IMPEDIMENT-task-NNN.md                     # written by Execute on an unresolved contradiction
    packages/package-NNN-{slug}.md             # written by Deploy
    DEPLOYMENT-STATE.md · MONITOR-STATE.md     # written by Deploy / Monitor
```

CONFIRMED: `canonical/aid/templates/work-state-template.md` (`delivery-NNN/STATE.md` and
`delivery-NNN/tasks/task-NNN/STATE.md` blocks) and direct listing of
`.aid/work-001-kb-skills-improvement/` (sixteen `delivery-NNN/` dirs each with `STATE.md`).

UNCERTAIN / drift flag: `docs/aid-methodology.md` ("## 7. Artifacts Reference") still
describes the flatter shape `.aid/{work}/tasks/task-NNN.md`. The live skills + template use
the nested `delivery-NNN/tasks/task-NNN/SPEC.md`. Recorded as a Q&A entry (doc drift, Low
impact) — not silently reconciled here.

The lite path omits `features/`, `REQUIREMENTS.md`, and `PLAN.md`: it writes one work-root
`SPEC.md` plus tasks directly. CONFIRMED: `docs/aid-methodology.md` ("Lite-path workspace").

---

## Typed Artifact Contracts

Each artifact is a markdown file with a required shape. The shape — not just the file name —
is the contract a producing phase must satisfy and a consuming phase relies on.

| Artifact | Produced by | Consumed by | Required shape (load-bearing fields) | Lifecycle |
|----------|-------------|-------------|--------------------------------------|-----------|
| KB doc-set | Discover | all phases | per-doc frontmatter (`kb-category`, `source`, `objective`, `summary`, `sources`, `tags`, `audience`, `owner`) + `# Title` + content + `## Change Log` | living |
| `INDEX.md` | config/Discover/Interview | all phases | one 2–3 line summary row per KB doc | regenerated, never hand-maintained |
| `STATE.md` (discovery area) | config/Discover/Summarize | Discover (resume), all phases | grade, Q&A (Pending), review & summarization history, calibration log | living |
| `REQUIREMENTS.md` | Interview (full) | Specify, Plan | `## Change Log` + 10 numbered sections (Objective … Priority) | frozen after approval, rev-tracked |
| feature `SPEC.md` | Interview + Specify | Plan, Detail, Execute | `## Change Log` · Source · Description · User Stories · Priority · Acceptance Criteria · `## Technical Specification` (Specify) | living |
| work-root `SPEC.md` (lite) | Interview (lite) | Execute | consolidated requirements + technical context, no `features/` | living |
| `PLAN.md` | Plan | Detail, Deploy | `## Deliverables` (ordered, each with What/Features/Depends on/Priority) + execution graph (Detail) + `## Revision History` | living, rev-tracked |
| task `SPEC.md` | Detail (full) or Interview (lite) | Execute | Type ∈ {RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE} · Source · Depends on · Scope · Acceptance Criteria | rev-tracked if amended |
| `IMPEDIMENT-task-NNN.md` | Execute | Specify, Detail, Discover | Summary · Type ∈ {wrong-assumption, missing-dependency, architecture-conflict, kb-gap} · Options · Recommendation | closed when resolved |
| `package-NNN-{slug}.md` | Deploy | Monitor, stakeholders | deliveries included · verification results · environment · release notes | one per shipped release |
| `MONITOR-STATE.md` | Monitor | Execute (bugs), Discover (CRs) | Last Run · Active Findings (Classification/Severity/Evidence/Routing) · Resolved Findings | living |

CONFIRMED by the template files under `canonical/aid/templates/` and the artifact reference
in `docs/aid-methodology.md` ("Core Artifacts" and "Templates Reference").

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
| `aid-discover` | GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE |
| `aid-interview` (full) | 7 states: interview states 1–4 (open / Q&A mode / continue / completion gate) → 5 Feature Decomposition → 6 Cross-Reference → 7 Done |
| `aid-interview` (lite) | TRIAGE → CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW → LITE-DONE |
| `aid-specify` | per-section universal loop: Propose → Discuss → Write → Review (re-run enters at Review) |
| `aid-plan` | universal loop applied per delivery: Propose → Discuss → Write → Review |
| `aid-detail` | universal loop per delivery producing task files → build execution graph |
| `aid-execute` | per-task universal loop (read type → execute → gates → reviewer dispatch → grade → fix/loopback) inside a parallel pool |
| `aid-deploy` | package selection → final verification → package record → packaging → doc routing → status update |
| `aid-monitor` | Observe → Classify → Analyze → Propose → Act |
| `aid-housekeep` | PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE |
| `aid-update-kb` | ANALYZE → APPLY → REVIEW → APPROVAL → DONE |

CONFIRMED: per-skill `SKILL.md` files under `canonical/skills/`; the lite/housekeep/update
sequences additionally in `docs/glossary.md` ("aid-housekeep", "aid-update-kb").

The **universal loop** (Propose, then Discuss, then Write, then Review) is shared by every full-path
design phase. Re-running a completed phase re-enters at Review and re-grades existing content
against current reality — the same loop handles creation and maintenance. CONFIRMED:
`docs/aid-methodology.md` ("The universal loop").

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

---

## Feedback Loop Contracts

The pipeline is sequential by default; eleven formal loops let a downstream phase revise an
upstream artifact. Each loop produces a formal record — a Q&A entry in a `STATE.md`, an
`IMPEDIMENT-task-NNN.md`, or a `MONITOR-STATE.md` finding — never a silent workaround.
CONFIRMED: `docs/aid-methodology.md` ("## 6. Feedback Loops").

| Loop | From | To | Trigger | Record |
|------|------|----|---------|--------|
| L1 | Interview | Discover | an answer reveals the KB is wrong/incomplete | Q&A in `.aid/knowledge/STATE.md` |
| L2 | Specify | Discover | spec exposes insufficient subsystem understanding | Q&A in `.aid/knowledge/STATE.md` |
| L3 | Plan | Discover | codebase more complex than the KB captured | Q&A in `.aid/knowledge/STATE.md` |
| L4 | Plan | Specify | KB complete but a SPEC is ambiguous/contradictory | Q&A in the feature `STATE.md` |
| L5 | Detail | Plan | plan too vague to decompose into tasks | flag on the under-specified deliverable |
| L6 | Execute | Discover / Specify / Detail | an assumption does not hold | `IMPEDIMENT-task-NNN.md` (routed by Type) |
| L7 | Execute Review | any upstream phase | reviewer finds TASK/SPEC/KB-sourced issues | source-tagged issue → loopback |
| L8 | Deploy | Execute | final verification (build+tests+lint) fails | routed back to `/aid-execute` |
| L9 | Monitor | Interview (bug) | finding classified BUG → LITE-BUG-FIX | `MONITOR-STATE.md` finding |
| L10 | Monitor | Interview (CR) | finding classified Change Request | `MONITOR-STATE.md` finding |
| L11 | any phase | Discover | KB found wrong/incomplete/stale | targeted re-discovery Q&A |

The IMPEDIMENT routing (L6) is by Type: `kb-gap` routes to Discover, `architecture-conflict`
to Specify, `missing-dependency` to Detail, and `wrong-assumption` to a task/SPEC update.
CONFIRMED:
`docs/aid-methodology.md` ("Loop 6").

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

- The methodology doc (`docs/aid-methodology.md`) describes the older flat task layout
  (`.aid/{work}/tasks/task-NNN.md`) while the live skills and `work-state-template.md` use the
  nested `delivery-NNN/tasks/task-NNN/SPEC.md` shape. Doc drift — see the Q&A entry. LIKELY a
  prose-simplification lag, not a behavioral disagreement, but not reconciled here.
- The skill/recipe counts disagree across sources ("12-skill pipeline" vs 13 skill dirs; "51"
  vs 52 recipes). Tracked as discovery Q&A (Q1/Q2). Counts here defer to those Q&As.

---

## Conventions

> How this project adds or changes a pipeline boundary.

- **A new phase/skill** is authored once in `canonical/skills/<name>/SKILL.md` as a state
  machine (states advance one invocation at a time), then rendered into the five profiles.
  Never edit `profiles/` directly.
- **A new artifact type** gets a template under `canonical/aid/templates/`, a fixed location
  under `.aid/{work}/`, and an entry in the artifact reference. Downstream skills find it by
  convention (fixed path), never by search.
- **A new feedback path** must produce a formal record (Q&A entry, IMPEDIMENT file, or
  MONITOR finding) with a revision trail — never an inline silent fix.

---

## Contracts

> The structural shapes a change MUST satisfy at a phase boundary.

- **Task contract:** every task `SPEC.md` declares a `Type` from the eight-type enum, a
  `Source`, `Depends on` (`— (none)` for the first), `Scope`, and `Acceptance Criteria`. The
  executor and the reviewer both bind to the Type; changing the enum breaks both.
- **Grade contract:** reviewers emit bracketed `[SEVERITY]`/`[SOURCE]` tags only; `grade.sh`
  computes the letter. Any consumer of the grade depends on the deterministic mapping in
  `grading-rubric.md` — adding a severity tier or changing the dominance rule is a breaking
  change to every grading skill.
- **State-file contract:** run-state (grades, Q&A, history, rollups) lives in the area's
  `STATE.md`; the dashboard and `/aid-execute` read these files to track a pipeline. Artifact
  files alone are not trackable. Renaming or restructuring `STATE.md` sections breaks the
  dashboard reader (see [integration-map.md](integration-map.md)).
- **Compatibility rule:** artifact templates evolve additively — new optional sections/fields
  are safe; removing or renaming a load-bearing field is breaking and requires updating every
  producing and consuming skill in lockstep.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial pipeline-contract mapping (Integrator deep-dive) |
