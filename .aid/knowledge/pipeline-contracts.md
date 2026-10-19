---
kb-category: primary
source: hand-authored
objective: The typed artifact contracts and state-machine transitions between AID pipeline phases — what each phase consumes, produces, and gates on.
summary: Read this before changing any skill, artifact template, or phase hand-off. It is the workflow + contract layer of the AID methodology — the entry doors, the phase-to-phase data contracts, the on-disk work hierarchy (full + flattened Lite), the per-skill state machines, the grading gate, and the eleven feedback loops.
sources:
  - docs/aid-methodology.md
  - canonical/skills/
  - canonical/aid/templates/work-state-template.yml
  - canonical/aid/templates/grading-rubric.md
  - canonical/aid/templates/requirements.md
  - canonical/aid/templates/task-detail-template.md
  - canonical/aid/templates/shortcut-engine.md
  - .aid/settings.yml
tags: [C2, pipeline, contracts, phases, artifacts, state-machines, feedback-loops]
see_also: [integration-map.md, architecture.md, domain-glossary.md, artifact-schemas.md]
owner: architect
audience: [developer, architect]
review-criteria:
  - id: F-01
    kind: validate
    criterion: >
      Every loopback row names a skill that exists as a directory under `canonical/skills/`.
    severity: HIGH
    why: >
      These rows are the routing table an agent follows at a phase boundary, so a row naming a
      skill that does not exist dead-ends the run rather than failing visibly here.
---

# Pipeline Contracts

> **Source:** aid-discover (brownfield deep-dive — Integrator)
> **Status:** Complete

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

---

## How the Pipeline Works

AID is a sequential pipeline of skills with formal feedback loops. Each skill is a slash command
resolving to a `SKILL.md` state machine. A work moves through five phases: Definition, Specification,
Planning, Building and CI. `aid-describe` is Definition; `aid-define` and `aid-specify` are
Specification; `aid-plan` and `aid-detail` are Planning; `aid-execute` is Building; CI closes the work.
On brownfield projects `aid-discover` prepares the Knowledge Base before them (not a work phase). The human approves every
phase transition — the pipeline never auto-advances. CONFIRMED: `docs/aid-methodology.md`
("## 1. The Pipeline", "Between phases, the human gives the OK to advance").

Two contract facts shape every hand-off:

- **Artifacts are typed markdown files under `.aid/`.** Each phase reads named files from a
  prior phase and writes named files for the next. The file name and location are the
  contract — downstream skills navigate by convention, never by search.
- **Entry doors, two paths.** The first door is a *plain request*: the agent reads it by its meaning against the skill guide in `.aid/runtime/rules.md` (`canonical/aid/rules.md` § Handling a request), and `/aid-orchestrate` checks the reading and sizes it before any work exists, then finds, resumes or creates the work. A request either reaches a skill, is answered as a project question from the KB (no work created), or carries on with no AID workflow. A typed `/aid-<skill>` always wins. The *full path* runs every pipeline skill, from `/aid-describe` through `/aid-execute`, and is entered by `/aid-describe` (broad or new-project work). The *flattened Lite path* is entered by naming the change with a verb-first **shortcut** (`/aid-<verb>[-<artifact>]`, e.g. `/aid-fix`, `/aid-create-api`) — each shortcut is a thin doorway into the shared **shortcut engine** (`shortcut-engine.md`) that collapses `/aid-describe` through `/aid-detail` (Definition, Specification and Planning) into one fast, mostly-autonomous run. `/aid-describe` is **full-path only** — it no longer triages or emits Lite work. CONFIRMED: `docs/aid-methodology.md` ("## 4. The Phases", "The Lite Path: Direct-Entry Shortcuts"); `canonical/aid/rules.md` (`## Handling a request`, `## Skill guide`); `canonical/skills/aid-orchestrate/SKILL.md`; `canonical/aid/templates/shortcut-engine.md`; `canonical/skills/aid-describe/SKILL.md` (frontmatter `State machine:` — no TRIAGE/lite states).

---

## Phase Input/Output Contracts

The mandatory pipeline is the work phases Definition, Specification, Planning, Building and CI, with `aid-discover` preparing the KB before them on brownfield projects; `aid-config` precedes it (bootstrap) and
`aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`, `aid-ask`,
`aid-update-kb` are off-pipeline or optional. The 34 verb-first shortcuts are direct-entry skills, and `/aid-orchestrate` is the plain-request intake; both sit outside the numbered pipeline (the shortcuts drive the shortcut engine; the intake only routes). CONFIRMED: `docs/aid-methodology.md` ("Skill
Inventory" table, "§4 The Phases").

| Phase | Skill | Consumes | Produces | Gate |
|---|---------------|----------|----------|------|
| — | `aid-config` (bootstrap) | user metadata (greenfield/brownfield, name, min grade) | `.aid/` scaffold · KB placeholders · context file (`CLAUDE.md`/`AGENTS.md`) · seeded `STATE.yml` · `settings.yml` | none (setup) |
| — (KB preparation, not a work phase) | `aid-discover` (brownfield) | repository source · `project-index.md` pre-pass · confirmed `discovery.doc_set` | the confirmed KB doc-set · `INDEX.md` · `README.md` · discovery-area `STATE.md` grade/Q&A · ELICIT E1: `## External Documentation` in `.aid/knowledge/STATE.md` (population signal into `external-sources.md`, written by Scout) · ELICIT E2: `.aid/connectors/` registry (descriptors + `INDEX.md`) | deterministic grade ≥ minimum + human approval |
| Definition | `aid-describe` (full path only) | `.aid/knowledge/` · user answers | approved `REQUIREMENTS.md` (+ greenfield: a forward-authored KB seed in `.aid/knowledge/`) | grade ≥ minimum + human approval |
| Specification | `aid-define` (full path only) | approved `REQUIREMENTS.md` · KB · codebase | one `### Feature NNN` section per feature under `REQUIREMENTS.md § 11` + cross-reference Q&A | grade ≥ minimum + human approval |
| Specification | `aid-specify` (full path only) | a feature's `§ 11` section (requirements side) · the `§ 5`/`§ 9` slice it cites · KB · codebase | `#### Technical Specification` appended to that feature section | per-section grade ≥ minimum |
| Planning | `aid-plan` (full path only) | `§ 11` feature sections marked `Ready` · `REQUIREMENTS.md` · KB | `PLAN.md` — ordered deliveries, each stanza carrying that delivery's definition (objective/scope/gate criteria) + delivery `STATE.yml` (`Pending-Spec`) | grade ≥ minimum |
| Planning | `aid-detail` (full path only) | `PLAN.md` · the `§ 11` feature sections · KB | per-task `DETAIL.md` files + execution graph appended to `PLAN.md` | grade ≥ minimum |
| Building | `aid-execute` | task `DETAIL.md` (with Type) · `PLAN.md` · the requirements SLICE the task cites (`slice-requirements.sh`) · `INDEX.md` · `known-issues.md` (if present) | reviewed/graded artifacts to grade ≥ minimum; results in delivery/task `STATE.yml` | per-task quick-check + delivery-gate grade ≥ minimum |
| CI | none; `/aid-orchestrate` closes the work | all tasks `Done` | the work marked `Completed` | all tasks `Done` |

CONFIRMED by the per-phase deep-dives in `docs/aid-methodology.md` ("## 4. The Phases"),
the artifact table ("Skill Inventory"), and the `aid-describe` / `aid-define`
`SKILL.md` files (frontmatter `State machine:` + State Detection blocks). The **flattened Lite
path** collapses further, to two artifact types at the work root: the shortcut engine authors
`REQUIREMENTS.md` (CAPTURE, then SPEC writes its `§ 11` feature section) and
`tasks/task-NNN/DETAIL.md` (DETAIL). Its PLAN state writes nothing — one feature and one
delivery means no sequencing decision to record — see the On-Disk Work Hierarchy below. CONFIRMED: `canonical/aid/templates/shortcut-engine.md` (CAPTURE/SPEC/PLAN/DETAIL steps);
`docs/aid-methodology.md` ("Skill Inventory" shortcut row, "The Lite Path").

Greenfield projects skip `aid-discover` (no existing system) and enter at `aid-describe` (Definition). Instead of
"a minimal KB", `aid-describe`'s DESCRIBE-SEED state **forward-authors** a 5-element KB seed
(concept-spine + intended architecture + conventions + tech stack + decisions) into
`.aid/knowledge/`, stamped `source: forward-authored` — the docs are authored as the source of
truth before any code exists. CONFIRMED:
`canonical/skills/aid-describe/references/state-describe-seed.md` ("Record Sink");
`docs/aid-methodology.md` ("The Full Path").

---

## The On-Disk Work Hierarchy

A *work* is a self-contained scope unit under `.aid/`. The shape diverges by path. On the
**full path** (via `/aid-describe` → the pipeline skills) deliveries are nested under a
`deliveries/` parent (mirroring `features/`). On the **flattened Lite path** (via a verb-first
shortcut → the shortcut engine) there is exactly one delivery and **no `deliveries/` folder at
all** — the work IS the delivery, and the delivery's definition, lifecycle, gate, and task
cells are authored directly at the work root.

**Full path:**

```
.aid/
  knowledge/                                  # shared KB (from Discovery) — one per project
  works/
    work-NNN-{slug}/
      STATE.yml                                 # work-area run-state (DERIVED rollups + Q&A)
      REQUIREMENTS.md                           # full path only; § 11 holds one
                                                #   `### Feature NNN` section per feature:
                                                #   definition (aid-define) + tech spec (aid-specify)
      PLAN.md                                   # full path only; each `### delivery-NNN`
                                                #   stanza IS that delivery's definition
                                                #   (objective/scope/gate criteria).
                                                #   aid-detail appends the execution graph
      deliveries/delivery-NNN/
        STATE.yml                               # delivery lifecycle + gate + delivery-scoped Q&A
        tasks/task-NNN/
          DETAIL.md                             # the task definition (Type, Source, Depends on, Scope, AC)
          STATE.yml                             # mutable task cells (State, Review, Elapsed, Notes)
      IMPEDIMENT-task-NNN.md                     # written by aid-execute on an unresolved contradiction
      packages/package-NNN-{slug}.md             # written by Deploy
      DEPLOYMENT-STATE.md · MONITOR-STATE.md     # written by Deploy / Monitor
```

**Flattened Lite path** (no `deliveries/`, no `delivery-NNN/` folder, and no per-task `STATE.yml`):

```
.aid/
  knowledge/                                  # shared KB (from Discovery) — one per project
  works/
    work-NNN-{slug}/
      STATE.yml                                 # work-area run-state; ALSO carries the sole
                                                 # delivery's `delivery_lifecycle` key (with its
                                                 # `tasks_lifecycle` mapping) / `delivery_gate` key /
                                                 # `qa` key (AUTHORED directly)
      REQUIREMENTS.md                           # shortcut engine CAPTURE; § 11 gains the single
                                                #   feature section at SPEC, § 9 carries the
                                                #   delivery's gate criteria. No SPEC.md and no
                                                #   PLAN.md: one feature and one delivery leaves
                                                #   nothing to sequence, and the execution graph
                                                #   derives from each **Depends on:** field
      tasks/task-NNN/
        DETAIL.md                               # the task definition — IMMUTABLE, no sibling STATE.yml;
                                                 # mutable cells live in STATE.yml's `tasks_lifecycle` mapping
      IMPEDIMENT-task-NNN.md                     # written by aid-execute on an unresolved contradiction
      packages/package-NNN-{slug}.md             # written by Deploy
      DEPLOYMENT-STATE.md · MONITOR-STATE.md     # written by Deploy / Monitor
```

CONFIRMED: `canonical/aid/templates/work-state-template.yml` (`deliveries/delivery-NNN/STATE.yml`
blocks for the full path; the AUTHORED `delivery_lifecycle` / `tasks_lifecycle` /
`delivery_gate` keys for the single-delivery flattened work) and
`canonical/aid/templates/delivery-state-template.yml` (a full-path-only header note; the
flattened work authors the same keys directly in its work-root STATE.yml). The `§ 11` feature
sections are written by `aid-define` FEATURE-DECOMPOSITION, not by the interview half --
CONFIRMED: `canonical/skills/aid-define/SKILL.md`.

The flattened Lite path omits `deliveries/` and `delivery-NNN/`, and creates **no per-task
`STATE.yml`**: the shortcut engine writes work-root `REQUIREMENTS.md` plus one
`tasks/task-NNN/DETAIL.md` per task, and each task's mutable
cells are authored into the work-root `STATE.yml`'s `tasks_lifecycle` mapping (targeted by
`writeback-state.sh`'s auto-detected flat-layout branch). CONFIRMED:
`canonical/aid/templates/shortcut-engine.md` ("emits `tasks/task-NNN/DETAIL.md` … no per-task
`STATE.yml`"); `canonical/aid/scripts/execute/writeback-state.sh` (flattened-layout `--task-id`
targets `tasks_lifecycle.task-NNN.<field>` in the work-root `STATE.yml`).

---

## Typed Artifact Contracts

Each artifact is a markdown file with a required shape. The shape — not just the file name —
is the contract a producing phase must satisfy and a consuming phase relies on.

| Artifact | Produced by | Consumed by | Required shape (load-bearing fields) | Lifecycle |
|----------|-------------|-------------|--------------------------------------|-----------|
| KB doc-set | `aid-discover` (brownfield) / `aid-describe` DESCRIBE-SEED (greenfield seed) | all phases | per-doc frontmatter (`kb-category`, `source`, `objective`, `summary`, `sources`, `tags`, `audience`, `owner`) + `# Title` + content | living |
| `INDEX.md` | config, `aid-discover` or `aid-describe` | all phases | one 2–3 line summary row per KB doc | regenerated, never hand-maintained |
| `STATE.md` (discovery area) | config, `aid-discover` or `aid-summarize` | `aid-discover` (resume), all phases | grade, Q&A (Pending), review & summarization history, calibration log; ELICIT (State 0) additionally writes `## Discovery Elicitation` (Sources/Tools/Tools step/Skipped/Resolved) and `## External Documentation` (Path/Type/Accessible/Notes, one row per declared source — E1) | living |
| `.aid/connectors/` registry | `aid-discover` ELICIT (State 0, Step E2) | all phases (agents requesting a declared integration) | one `<stem>.md` descriptor per connector (`name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference` [aid-managed only], `preset`, `objective`, `summary`, `tags`, `audience`) + generated `INDEX.md` | living, reconciled (add/update/remove) each ELICIT cycle |
| `REQUIREMENTS.md` | `aid-describe` (full) or shortcut engine CAPTURE (flattened Lite) | `aid-define`, `aid-specify`, `aid-plan` (full); SPEC/PLAN/DETAIL (engine) | 10 numbered sections (Objective … Priority) | frozen after approval; history in git |
| feature section (`REQUIREMENTS.md § 11`) | `aid-define` + `aid-specify` | `aid-plan`, `aid-detail`, `aid-execute` | Description · User Stories · Priority · cited `§ 5 FR-N` / `§ 9 AC-N` · `#### Technical Specification` | one section per feature |
| `PLAN.md` | `aid-plan` (full) or shortcut engine PLAN (flattened Lite) | `aid-detail`, `aid-deploy` | `## Deliverables` (ordered, each with What/Features/Depends on/Priority) + execution graph (`aid-detail`) | living; history in git |
| delivery stanza (`PLAN.md` `### delivery-NNN`) | `aid-plan` (full path) | `aid-detail`, `aid-execute`, `aid-deploy` | Objective · Scope / Out of scope · **Gate Criteria** · Notes | one stanza per delivery; the Lite path has no plan |
| task `DETAIL.md` | `aid-detail` (full) or shortcut engine DETAIL (flattened Lite) | `aid-execute` | `Type` ∈ {RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE} · Source · Depends on · Scope · Acceptance Criteria | immutable (rev-tracked if amended) |
| `IMPEDIMENT-task-NNN.md` | `aid-execute` | `aid-specify`, `aid-detail`, `aid-discover` | Summary · Type ∈ {wrong-assumption, missing-dependency, architecture-conflict, kb-gap} · Options · Recommendation | closed when resolved |
| `package-NNN-{slug}.md` | `aid-deploy` | Monitor, stakeholders | deliveries included · verification results · environment · release notes | one per shipped release |
| `MONITOR-STATE.md` | Monitor | the fix request through `rules.md` § Handling a request (bugs), `/aid-orchestrate` (CRs) | Last Run · Active Findings (Classification/Severity/Evidence/Routing) · Resolved Findings | living |

CONFIRMED by the template files under `canonical/aid/templates/` and the artifact reference
in `docs/aid-methodology.md` ("Skill Inventory" and "§4 The Phases"). The delivery definition's
shape is CONFIRMED by `aid-plan/SKILL.md` § Output; the task `DETAIL.md`
shape: `canonical/aid/templates/task-detail-template.md`. The ELICIT-produced rows
(`## Discovery Elicitation` / `## External Documentation` / `.aid/connectors/` registry) are
CONFIRMED: `canonical/skills/aid-discover/references/state-elicit.md` ("Step E1: External
SOURCES branch", "Step E2: Tool INTEGRATIONS branch", "Step E3: Record and chain").

The eight task **Types** are the central executor/reviewer contract: the Type drives both how
the executor works and how the reviewer evaluates the task. CONFIRMED:
`docs/aid-methodology.md` ("The eight task types are").

---

## Per-Skill State Machines

Every skill that runs a process moves through its steps by one shared rule set,
`canonical/aid/templates/skill-steps.md`. A skill keeps only its own step table (its steps, the
reference file that does each step, the worker, and the advance word) and a fallback detection
from its artifacts. No skill restates how to move; each one cites that file. The steps of a skill
are its states: one run of a skill carries the work through as many steps as its advance words
allow, and it stops only at an `ASK`, a `WAIT`, a `PASS` or `CALL` that hands the work on, or a `HALT`.

### Advance words

Every step ends with exactly one advance ending on its `**Advance:**` line: one advance word, or
`ASK then HALT`, which is one composite ending and not two words. A line that names only its next
step is a `CHAIN`. The step a line names is a step of the same skill's table, by its name, never a
part of a step. A step that has already read the user's answer may branch on one `CHAIN` line: one
named step per case, and `HALT when ...` for the case on which the run ends. The words are internal
and never shown to the user.

| Word | Meaning |
|------|---------|
| `CHAIN` | Go on to the next step now, in the same run. Used when nothing is for the user to decide at that point. |
| `ASK` | Stop for the user through the question protocol (`canonical/aid/templates/question-protocol.md`). A question may come at any point of a step; a blocking one pauses the step where it stands, and the step stays saved. At the end of a step, `ASK` pauses there and names the one next step, which the work goes on to, and which is saved then, once every question is answered or skipped. Used only when no write that depends on the answer remains in the step. A resumed work asks its open questions first, then continues the same step. |
| `ASK then HALT` | The run ends with a question that blocks the work, such as which skill to run next. The question stays open and any resume shows it first; once it is answered or skipped, the run ends as `HALT` does. |
| `WAIT` | The user must act outside the conversation. Say what, plainly, and stop. The step stays saved and its detail says what is waited for; once the user says it is done, the work goes on to the step the line names. |
| `PASS` | End of this skill's process. Hand the work to the next skill and start it in the same turn. |
| `CALL` | In the middle of this skill's process. Hand the work to another skill, then come back to this step when it finishes. |
| `HALT` | This run is finished: after returning to an open call, if there is one; otherwise the run ends. |

### The work record

The work record is the set of `STATE.yml` keys that say where a work is: `intent.reading` (its
type), `active_skill`, `step` and `step_detail`. It is the only thing that
decides where a work continues, in the gate, in `/aid-orchestrate` and inside every skill. `phase`
is a display label, shown to the user and on the dashboard; it never routes or resumes a work.

- **Phase values** are the five names `Definition`, `Specification`, `Planning`, `Building` and `CI`.
  Preparation is not a work phase: the Knowledge Base's own state records it.
- **One writer.** Only `canonical/aid/scripts/execute/writeback-state.sh` writes the record, and
  every write is one locked write that leaves the file untouched on failure. The gate
  (`canonical/aid/templates/work-initiation-gate.md` § 3a) is the only creator of a work's
  `STATE.yml`, through the writer's create mode, before it hands the new work back.
- **When it is written:** at creation; at each step entry, before any work in that step; at every
  hand-off and return; at every re-route; and at finish. A non-zero exit from any record write stops
  the skill at once and the agent says so in one plain line (fail-closed).
- **Finishing clears the saved skill.** Setting the lifecycle to `Completed` or `Canceled` also sets
  `active_skill` to `none` and clears `step` and `step_detail` in the same locked write.

### Steps, questions and hand-offs

Each step runs the same parts, in this order:

1. **Enter.** The main conversation writes the step (`--step --skill <skill> --name <STEP>`) before
   doing or dispatching any of the step's work.
2. **Work.** Inline, or by a worker. A worker returns its open questions to the main conversation;
   it never asks them.
3. **Questions, at any point.** The main conversation may ask a question at any point of a step. A
   blocking question pauses the step where it stands: the record keeps the step saved, its detail says
   what is done and which question is open, and the lifecycle is `Paused-Awaiting-Input`. A session that
   resumes asks the open questions first, then continues the same step.
   **`ASK`** is that pause at the end of a step. The finished step stays saved while the question is
   open; each question is recorded and asked. Once every question is answered or skipped, the step is
   finished, and the work goes on to the step the line names, which is then saved with `--step`. When
   the next step depends on the answer, the line names the one step that reads it, and that step may
   branch on one `CHAIN` line. An approval cannot be skipped: it stays open, and its step stays
   paused, until the user approves or declines. Every other question may be skipped.
4. **`PASS`.** If the approvals table requires an approval at this point for the work's depth, `ASK`
   it first. Then one locked write hands the work to the next skill and its entry step, with
   `--returns no` and the phase when the phase changes; the next skill starts in the same turn.
5. **`CALL`.** Record what is done, then one locked write appends a `handoffs` entry with
   `--returns yes` (the hand-off's from-skill, from-step and from-detail, and the reason) and moves the
   work to the called skill's entry step. The phase does not change.
6. **`HALT`.** With an open call, `--handoff-return` restores the caller's skill, step and detail,
   and the caller continues at that step. Calls nest, and the newest call returns first. Without an
   open call, the run ends.

A hand-off writes the target skill and its entry step in the same write, so a work never has a
skill without a step, even when a hand-off is interrupted.

### Resume and recovery

Resume is decided by the record alone. The first thing a resumed session does is run
`writeback-state.sh --check`, which writes nothing, prints one line per problem and exits 9 when
there is one. The gate's resume table (`work-initiation-gate.md` § 3b) then routes:

- a finished work (`Completed` or `Canceled`) is reported as finished, and the session stops;
- a record that `--check` reports as missing or inconsistent goes to recovery;
- any other open work continues at its saved `active_skill` and `step`. With an open call, it continues
  inside the called skill.

A skill's own artifact detection never routes a work. A skill starting fresh on a work (through a
`PASS`, a `CALL`, or a typed command for another skill) uses detection only to decide how far its
entry step goes. A resumed skill uses detection only to validate the saved step against what is on
disk. A mismatch goes to recovery, never to a silent re-route.

Recovery never repairs on its own. The agent tells the user what `--check` found and proposes the
whole repaired record (the type, the skill and the step) as one confirmation question, with its
recommendation. Only after the user confirms, or corrects a part in the same answer, does it run
`--repair`. That write requires `--reading` when the record has none, and appends a
`lifecycle_history` entry that names the old and the new record. After one confirmed repair the
record is complete and `--check` passes.

### Per-skill steps

The table lists each skill's steps in order, as its `SKILL.md` and `references/` files name them. Every
skill follows the rules above, and each step's advance word is on that step's `**Advance:**` line.

| Skill | Steps (in order) |
|-------|------------------|
| `aid-discover` | ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE. Builds the Knowledge Base; no work phase. |
| `aid-describe` (full) | FIRST-RUN → Q-AND-A → CONTINUE → [greenfield: DESCRIBE-SEED →] COMPLETION. COMPLETION is `ASK` then `HALT`, naming `/aid-define`. |
| `aid-define` | FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE. DONE is `ASK` then `HALT`; a requirements-level change is named in one plain line. |
| `aid-specify` | Per-section universal loop: Propose → Discuss → Write → Review. A re-run enters at Review. |
| `aid-plan` | Universal loop applied per delivery: Propose → Discuss → Write → Review. |
| `aid-detail` | Universal loop per delivery, producing the task files, then the execution graph. |
| `aid-execute` | Per-task loop inside a parallel pool: read type → execute → gates → reviewer dispatch → grade → fix or loopback. |
| `aid-orchestrate` | No step table. Numbered steps run in the main conversation: project question, check the reading, size it, show the reading, then hand an action-skill reading to its skill (which creates the work), or find or create the work, or cancel or close it, and hand over the first phase. |
| Shortcut skills (`/aid-<verb>[-<artifact>]`, shared `shortcut-engine.md`) | INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT. The engine runs the Definition-to-Planning path as one autonomous run and never executes. |
| `aid-deploy` | Package selection → final verification → package record → packaging → doc routing → status update. |
| `aid-monitor` | Observe → Classify → Analyze → Propose → Act. |
| `aid-housekeep` | PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE. |
| `aid-update-kb` | ANALYZE → SCOPE → CONFIRM → APPLY → REVIEW → APPROVAL → DONE. The CONFIRM step precedes any edit; the FIX loop sits inside REVIEW. |

A skill that drives a phase sets it through the writer with `--phase`; an on-demand skill that
drives none sets no phase, and the work's current phase stays.

The **universal loop** (Propose, then Discuss, then Write, then Review) is shared by every full-path
design step. Re-running a completed step re-enters at Review and re-grades existing content against
current reality, so the same loop handles creation and maintenance. The flattened Lite path does NOT
use the universal loop: the shortcut engine runs CAPTURE/SPEC/PLAN/DETAIL without a per-step human
checkpoint (the only interactive moments are a rare CAPTURE gap-question and the terminal
APPROVAL-HALT), and quality is enforced once at GATE. CONFIRMED: `docs/aid-methodology.md` ("The
universal loop", "The Lite Path: Direct-Entry Shortcuts").

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
  (`REQUIREMENTS.md` / `PLAN.md` + each `DETAIL.md`) mechanically
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
| L1 | Definition (`aid-describe`) | KB (`aid-discover`) | an answer reveals the KB is wrong/incomplete | Q&A in `.aid/knowledge/STATE.md` |
| L2 | Specification (`aid-specify`) | KB (`aid-discover`) | spec exposes insufficient subsystem understanding | Q&A in `.aid/knowledge/STATE.md` |
| L3 | Planning (`aid-plan`) | KB (`aid-discover`) | codebase more complex than the KB captured | Q&A in `.aid/knowledge/STATE.md` |
| L4 | Planning (`aid-plan`) | Specification (`aid-specify`) | KB complete but a SPEC is ambiguous/contradictory | Q&A in the feature `STATE.md` |
| L5 | Planning (`aid-detail`) | Planning (`aid-plan`) | plan too vague to decompose into tasks | flag on the under-specified deliverable |
| L6 | Building (`aid-execute`) | KB (`aid-discover`) / Specification (`aid-specify`) / Planning (`aid-detail`) | an assumption does not hold | `IMPEDIMENT-task-NNN.md` (routed by Type) |
| L7 | Building (`aid-execute` review) | any upstream phase | reviewer finds TASK/SPEC/KB-sourced issues | source-tagged issue → loopback |
| L8 | `aid-deploy` (its own work) | Building (`aid-execute`) | final verification (build+tests+lint) fails | routed back to `/aid-execute` |
| L9 | Monitor | fix request through `rules.md` § Handling a request (plain request, no typed skill) | finding classified BUG | `MONITOR-STATE.md` finding |
| L10 | Monitor | `/aid-orchestrate` (plain request through `rules.md` § Handling a request) | finding classified Change Request | `MONITOR-STATE.md` finding |
| L11 | any phase | KB (`aid-discover`) | KB found wrong/incomplete/stale | targeted re-discovery Q&A |

The IMPEDIMENT routing (L6) is by Type: `kb-gap` routes to KB (`aid-discover`), `architecture-conflict`
to Specification (`aid-specify`), `missing-dependency` to Planning (`aid-detail`), and `wrong-assumption` to a task/SPEC update.
CONFIRMED: `docs/aid-methodology.md` ("Loop 6"). The Monitor re-points (L9/L10) are CONFIRMED:
`canonical/skills/aid-monitor/SKILL.md` (bugs back as a fix request, change requests as a new-work request, both through `rules.md` § Handling a request).

### The `design -> create -> update` artifact lifecycle (on-demand, off the numbered pipeline)

Thirty-six skills share one contract, `canonical/aid/templates/design-lifecycle.md`. They **bind**
it rather than restating it, so the rules below live in one file and the bodies stay thin.

**None of the thirty-six declares a `phase:`.** They are on-demand skills in the same shape
`/aid-design` and `/aid-prototype` already have, so they carry no phase membership and none routes
to `/aid-execute`. C-1's closed `phase:` enum is **not** extended by this family, and no contract
below implies it was.

| Stage | Precondition | Writes | Refuses when |
|-------|--------------|--------|--------------|
| `design` | none -- the shape is still open | `.aid/design/<artifact>.md`, and nothing else | -- |
| `create` | a ready seed exists | the destination artifact; on first creation, its registration too | one of exactly three conditions, below |
| `update` | the destination already carries committed content | the named revision only | the destination is `source: generated` |

**`create` has exactly three refusal conditions and no fourth:** no seed at
`.aid/design/<artifact>.md`; the seed's `## Open questions` still unresolved with no
`--override-open-questions` supplied; or the destination's frontmatter reading
`source: generated`, which means a registered build script owns that content. Whatever the
destination already holds is **never itself** a reason to refuse -- an as-built document is the
normal case these skills are for.

**A repeat `create` never halts with nothing done.** Every part of the seed that is new is
written; each part that would overwrite content an earlier run of the same lifecycle committed is
named and **routed** to `update`. The seed is deleted only when everything its `## Destination`
named was written -- otherwise it stays in place carrying just the unrealized parts, which
`update` then consumes.

**Registration happens in the creating run, never later and never by another skill.** When
`create` creates a document it appends one `.aid/settings.yml` `knowledge.doc_set` entry
`<file>|<owner>|required` -- the owner taken from the document's matrix row, never a blanket
`skill-self` -- and one `.aid/knowledge/README.md` Completeness row, incrementing that file's
doc-set count. Both use the append-block idiom and both must succeed in the same run.

**Frontmatter invariants.** A document `create` creates gets `source: forward-authored` and
`sources: []`; a document that already existed keeps its `source:` value unchanged, and `update`
never rewrites a production mode. `approved_at_commit:` is never written and never restamped by
either verb -- it is generator-written on approval, and these skills are not that generator.

**`update` asks every run which derived outputs to update alongside the one it is writing, and
stores the answer nowhere** -- no frontmatter backlink, no manifest, no registry, no state carried
between runs. The question is asked afresh each time, and no tracking metadata is written into any
output it touches.

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

- The former layout-shape drift (the flat `.aid/works/{work}/tasks/task-NNN.md` layout) is
  resolved: `docs/aid-methodology.md` describes the nested full-path
  `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` shape and the flattened Lite
  `tasks/task-NNN/DETAIL.md` shape (no per-task state file on that path), matching the live
  skills and templates. A separate, narrower drift is open: `docs/aid-methodology.md` was not
  part of the state-file YAML conversion and still names the per-work-tree state file
  `STATE.md` throughout; the live templates and scripts
  (`canonical/aid/templates/work-state-template.yml` /
  `delivery-state-template.yml` / `task-state-template.yml`,
  `canonical/aid/scripts/execute/writeback-state.sh`) are the current source of truth and name it
  `STATE.yml`.
- The skill taxonomy is **112 skill directories** under `canonical/skills/`: 18 curated
  pipeline/on-demand/supporting skills (including `aid-read-ticket`, `aid-create-ticket`,
  `aid-update-ticket`) + the 94-row shortcut catalog's skills, every row a canonical
  name — 34 verb-first direct-entry shortcut doorways (generated from
  `shortcut-catalog.yml`) plus 60 hand-authored `repurpose` skills. The alias model is
  retired: `alias_of` is required but always `null`, so no row is a synonym of another. <!-- count-history -->
  Re-derive both figures rather than trusting this prose — `ls -1d canonical/skills/*/`
  and `grep -c '^  - name:' canonical/aid/templates/shortcut-catalog.yml`. The recipe system
  (`canonical/aid/recipes/`, `parse-recipe.sh`, `{{slot}}` placeholders) was removed and
  replaced by the shortcut engine + `shortcut-scaffolding/<family>.md`; the prior "51 vs 52
  recipes" count drift is closed. Agents (8) and KB doc types (14) are the other counts.

---

## Conventions

> How this project adds or changes a pipeline boundary.

- **A new phase/skill** is authored once in `canonical/skills/<name>/SKILL.md` as a state
  machine (its steps follow `canonical/aid/templates/skill-steps.md`), then shipped in the shared
  payload and installed to `.agents/skills/aid-*` for every tool. Never edit an installed copy. A new verb-first shortcut is added as a row in
  `canonical/aid/templates/shortcut-catalog.yml` and regenerated — the shortcut doorway is a
  thin delegate to `shortcut-engine.md`, never a hand-authored state machine.
- **A new artifact type** gets a template under `canonical/aid/templates/`, a fixed location
  under `.aid/works/{work}/`, and an entry in the artifact reference. Downstream skills find it by
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
- **State-file contract:** run-state (grades, Q&A, history, rollups) for a work/delivery/task
  lives in that area's `STATE.yml` (the discovery/KB area's ledger is the one exception and
  stays `STATE.md`, `kb-category: meta`); the dashboard and `/aid-execute` read these files to
  track a pipeline. Artifact files alone are not trackable. On the flattened Lite path there is
  no per-task `STATE.yml` — each task's cells live in the work-root `STATE.yml`'s
  `tasks_lifecycle` mapping. Renaming or restructuring a `STATE.yml` key breaks the dashboard
  reader (see [integration-map.md](integration-map.md)).
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
- **Phase order is fixed.** On the full path a work runs Definition (`aid-describe`)
  -> Specification (`aid-define`, `aid-specify`) -> Planning (`aid-plan`, `aid-detail`) -> Building (`aid-execute`)
  -> CI, with `aid-discover` preparing the KB first on brownfield projects. The flattened Lite path
  (via the shortcut engine) collapses Definition through Planning into one autonomous run and hands
  off to Building, but never reorders the phases.
- **Forward-authored design is never auto-overwritten.** The conformance check flags
  code↔design divergence for the human; authority stays design -> code until the human
  explicitly evolves the design (see the Feedback Loop Contracts conformance subsection).
- **Contract fields evolve additively** -- removing or renaming a load-bearing field is a
  lockstep break (see the `## Contracts` Compatibility rule).
- **Work folders are transient; no permanent artifact depends on a specific one.**
  `.aid/works/work-NNN-*/` holds disposable per-work pipeline state and may be pruned once
  the work ships (see the On-Disk Work Hierarchy above). No permanent artifact -- product
  code, `canonical/` content (or its host render), tests, docs/site, the Knowledge
  Base, settings/schemas, or the agent-context files -- may reference, assert against, embed,
  or otherwise depend on the contents of a specific work folder: tests build their own
  fixtures, and the KB never cites a work folder as a source. Pipeline skills and scripts
  that create, read, or update work folders as their live runtime state (Execute, Deploy,
  Monitor, the dashboard reader) are the intended operators of that state, not a dependency,
  and are exempt.
- **A derived constant is a dependency even though it does not look like one.** The rule
  above catches dependencies a reader can SEE -- a path, a citation, a fixture read from
  disk. A number measured from a work folder and then hardcoded into a permanent artifact
  is the same dependency with the link removed: a threshold tuned against one work's
  artifacts, a ratio taken from one work's documents, a default sized from one work's task
  count. It survives the pruning that would have exposed it, and what it loses is not
  correctness but CHECKABILITY -- nobody can re-derive it, confirm it still holds, or tell
  what would make it wrong. The same applies to a generated file whose inputs came from a
  work folder: the output is durable, its provenance is not.
  Two ways to discharge it, and one of them must hold. Either the derivation is
  reproducible from durable inputs -- so re-running it is a real check -- or the
  measurement is recorded INLINE beside the constant in enough detail to re-do by hand:
  the raw quantities, what was counted, and when. A bare number with a work id in a comment
  satisfies neither, because the work id is the dangling pointer this rule exists to
  prevent.
