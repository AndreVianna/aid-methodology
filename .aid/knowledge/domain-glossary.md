---
kb-category: primary
source: hand-authored
objective: AID's project-specific vocabulary — the load-bearing native concepts (Concept Spine) and the supporting lexicon, defined as THIS project uses them.
summary: Read this to use AID's own words correctly. The spine holds the concepts the methodology is built on (Canonical, Profile, Work, Delivery, Task, Execution Graph, Knowledge Base, Emission Manifest, AID_HOME, …); the lexicon disambiguates run-state, dashboard, install, and authoring terms. Definitions are project-specific, not generic.
sources:
  - docs/aid-methodology.md
  - docs/glossary.md
  - canonical/
  - canonical/EMISSION-MANIFEST.md
  - canonical/skills/aid-describe/references/state-triage.md
  - canonical/skills/aid-describe/references/elicitation-engine.md
  - canonical/skills/aid-describe/references/state-describe-seed.md
  - bin/aid
  - dashboard/reader/models.py
  - .claude/skills/generate-profile/scripts/render.py
tags: [C4, glossary, vocabulary, terminology, concept-spine]
see_also: [pipeline-contracts.md, integration-map.md, architecture.md]
owner: architect
audience: [developer, architect, pm]
intent: |
  Project-specific vocabulary with definitions. Disambiguates terms that mean something
  particular in AID; the canonical reference for naming. Concept Spine + supporting lexicon.
contracts: []
changelog:
  - 2026-06-27: aid-describe/aid-define split — rekeyed Triage to /aid-describe; added Seasoned-Analyst Engine, Describe / Define, Forward-Authored Seed, and Conformance Check spine concepts; strengthened Concept Spine (ubiquitous-language alias / greenfield seed keystone)
  - 2026-06-25: Initial generation (aid-discover brownfield deep-dive / Integrator owns the concept spine)
---

# Domain Glossary

> **Source:** aid-discover (brownfield deep-dive — Integrator owns the Concept Spine)
> **Status:** Complete
> **Last Updated:** 2026-06-27

AID's "domain" is software-development methodology and its installer tooling. This glossary
documents what AID's own words mean *in this project* — not their generic industry sense. An
agent that treats "Delivery" as a shipment, or "Profile" as a user profile, will build the
wrong thing. The **Concept Spine** holds the load-bearing native concepts; the **Lexicon**
holds the supporting run-state, dashboard, install, and authoring vocabulary. Terminal-state
accounting for every harvested candidate concept lives in
`.aid/generated/spine-todo.md`.

## Contents

- [Concept Spine](#concept-spine)
- [Lexicon — Pipeline Run-State](#lexicon--pipeline-run-state)
- [Lexicon — Dashboard Reader](#lexicon--dashboard-reader)
- [Lexicon — Install and CLI](#lexicon--install-and-cli)
- [Lexicon — Build, Render and Install Mechanics](#lexicon--build-render-and-install-mechanics)
- [Lexicon — KB Authoring](#lexicon--kb-authoring)
- [Lexicon — UI Components and Identity](#lexicon--ui-components-and-identity)
- [Abbreviations and Acronyms](#abbreviations--acronyms)
- [Terms with Specific Domain Meanings](#terms-with-specific-domain-meanings)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## Concept Spine

> The project's native load-bearing concepts. Each is grounded from source artifacts and means
> only what it means in AID.

### Canonical

**Definition-as-used-here:** The `canonical/` directory — the single source of truth for every
piece of content AID installs (skills, agents, templates, recipes, scripts). Content is
authored once here and rendered into the five `profiles/` install trees; `profiles/` is build
output and is never hand-edited. "Canonical" is the authority, not merely "standard."

**Relates-to:** Profile (canonical is rendered into profiles), Emission Manifest (declares what
canonical emits per profile), Knowledge Base (KB templates live under `canonical/aid/templates/`).

**sources:**
- `docs/glossary.md` ("Canonical") — "the single source of truth … Never edit `profiles/` directly"
- `canonical/EMISSION-MANIFEST.md` — declares the canonical→profile emission

### Profile

**Definition-as-used-here:** One of the five rendered, host-tool-specific install trees AID
targets (Claude Code, Codex CLI, Cursor, GitHub Copilot CLI, Antigravity). All five carry
byte-identical skill/agent *bodies*; only the install root, context-file name, and agent
format differ. Not a user profile or a config profile.

**Relates-to:** Canonical (the source profiles are rendered from), Emission Manifest (drives
per-profile emission), AGENTS.md/CLAUDE.md (the per-profile context file).

**sources:**
- `docs/aid-methodology.md` ("The Five Profiles") — the five-row profile table
- `profiles/` — five subtrees plus per-profile `<profile>.toml` render config

### Work

**Definition-as-used-here:** A self-contained unit of scope created by one Describe → Define pair (Phase 2 —
the `aid-describe`→`aid-define` pair), living at `.aid/work-NNN-{slug}/`. Each work owns its own
requirements, features, plan, deliveries, and tasks while sharing the project-wide Knowledge Base.
Multiple works coexist (e.g. one per client request). "Work" is the top-level pipeline scope
container, not a generic job.

**Relates-to:** Delivery (a work is sequenced into deliveries), Knowledge Base (shared across
works), Task (the leaf unit inside a work), Describe / Define (the skill pair that creates a work).

**sources:**
- `docs/aid-methodology.md` ("Each interview creates a *work*")
- `canonical/aid/templates/work-state-template.md` — the work `STATE.md` shape

### Delivery

**Definition-as-used-here:** An ordered, independently shippable MVP grouping of features
within a work, numbered `delivery-NNN`. Plan decides what goes in each delivery and in what
order; Execute runs one git branch per delivery and gates each with a delivery-gate review. A
delivery is a strategy-level unit (the "what ships when"), distinct from a Task (the
tactical unit). Not a deployment/shipment event.

**Relates-to:** Work (deliveries belong to a work), Task (a delivery contains tasks),
Delivery Gate (the per-delivery review gate), Execution Graph (sequences tasks within/across
deliveries).

**sources:**
- `docs/aid-methodology.md` ("## 4 … Phase 4: Plan", "Branch isolation … `aid/{work}-delivery-NNN`")
- `canonical/aid/templates/work-state-template.md` (`delivery-NNN/STATE.md` block)

### Task

**Definition-as-used-here:** The leaf unit of execution: one agent session = one PR = one human
review. Every task carries a `Type` from a fixed eight-value enum (RESEARCH, DESIGN, IMPLEMENT,
TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE); the Type drives both how the executor works and
how the reviewer evaluates it. A task is defined by a `task-NNN/SPEC.md` and tracked by a
sibling `STATE.md`.

**Relates-to:** Delivery (tasks live under a delivery), Execution Graph (orders tasks into
waves), TaskStatus (the dashboard enum tracking a task's lifecycle).

**sources:**
- `docs/aid-methodology.md` ("The eight task types are")
- `canonical/aid/templates/work-state-template.md` (`delivery-NNN/tasks/task-NNN/STATE.md`)

### Execution Graph

**Aliases:** Wave, Max Concurrent

**Definition-as-used-here:** The dependency-and-parallel-wave plan Detail appends to `PLAN.md`:
per-delivery tables of task precedence and the "waves" of tasks that can run in parallel.
Execute consumes it to drive the parallel pool and to compute which dependents a failed task
blocks. It is a data structure expressed as tables, not a rendered diagram.

**Relates-to:** Task (the graph's nodes), Delivery (graphs are per-delivery), Wave (a set of
tasks with no unmet dependencies), Max Concurrent (pool capacity bounding a wave).

**sources:**
- `canonical/skills/aid-detail/references/execution-graph-generation.md` ("Build Execution Graph")
- `docs/aid-methodology.md` ("plus an execution graph (dependency and parallel-wave tables)")

### Knowledge Base

**Aliases:** kb-category

**Definition-as-used-here:** The `.aid/knowledge/` collection of structured markdown documents
that holds the living understanding of a project — the gravitational center of AID (not the
spec, not the code). Default seed of 14 standard documents plus meta-documents (INDEX, README,
STATE); the set is configurable per project via `discovery.doc_set`. Every phase reads it; any
phase can trigger a targeted update to it.

**Relates-to:** Canonical (KB templates ship from canonical), Concept Spine (a section of
`domain-glossary.md`), Declared Doc-Set (the configurable document set).

**sources:**
- `docs/aid-methodology.md` ("## 3. The Knowledge Base")
- `docs/glossary.md` ("Knowledge Base (KB)")

### Concept Spine

**Aliases:** Ubiquitous Language, Declared Concept-Spine

**Definition-as-used-here:** The section of `domain-glossary.md` (this section) that holds a
project's native load-bearing concepts, each grounded with a definition-as-used-here, a
relates-to linkage, and grep-recoverable `sources:` anchors. In **brownfield** it is *extracted*
— seeded from `candidate-concepts.md` and closed by the discovery closure loop (every candidate
concept must reach a terminal state: grounded here, or dismissed in `spine-todo.md`). In
**greenfield** it is *declared up front*: the concept-spine / ubiquitous language is the
MANDATORY keystone element of the forward-authored KB seed (DESCRIBE-SEED element 1) — the work
is not done until it can be explained using only defined native terms plus general knowledge
(the C4 stopping bar).

**Relates-to:** Knowledge Base (the spine lives in a KB doc), Candidate Concepts (the brownfield
harvest the spine grounds), Forward-Authored Seed (the greenfield seed whose keystone this is),
Seasoned-Analyst Engine (which elicits the declared spine).

**sources:**
- `canonical/aid/templates/knowledge-base/domain-glossary.md` ("## Concept Spine")
- `.aid/generated/candidate-concepts.md` — the harvested candidates the brownfield spine must close
- `canonical/skills/aid-describe/references/state-describe-seed.md` ("Declared concept-spine / ubiquitous language … MANDATORY")

### Emission Manifest

**Aliases:** EmissionManifest

**Definition-as-used-here:** The declaration (`canonical/EMISSION-MANIFEST.md`, modeled in the
renderer as `EmissionManifest`) of exactly which files the profile renderer emits for each
profile. It is the contract the VERIFY gate byte-checks the rendered `profiles/` against, so
`canonical/` always remains the source of truth.

**Relates-to:** Canonical (what is emitted), Profile (emitted per profile), the render pipeline
(`run_generator.py` / `render.py`).

**sources:**
- `canonical/EMISSION-MANIFEST.md` — the manifest itself
- `.claude/skills/generate-profile/scripts/render.py` (imports `EmissionManifest`)

### AidInstallCore

**Aliases:** Aid Install Core, `aid-install-core.sh`, `AidInstallCore.psm1`

**Definition-as-used-here:** The shared install/update/remove engine the bootstrap installers
source — Bash (`lib/aid-install-core.sh`) and PowerShell (`lib/AidInstallCore.psm1`). It holds
the in-place root-agent region replacement, the diff-aware copy, and channel logic so `install.sh`/`install.ps1` and the
package shims stay behaviorally identical across platforms.

**Relates-to:** Profile (what it installs), AID_HOME (where it installs state). (Root-agent
collisions are resolved by in-place `AID:BEGIN/END` region replacement; the older protect-on-diff
policy was retired in v1.1.0 — see `decisions.md` D11.)

**sources:**
- `lib/aid-install-core.sh` — the Bash install/update/remove engine
- `lib/AidInstallCore.psm1` — the PowerShell engine

### AID_HOME

**Aliases:** state home, AID_STATE_HOME, AidStateHome, Aid State Home, aid state home

**Definition-as-used-here:** The mutable per-machine AID state home — `${HOME}/.aid` for a
normal user install (or `/var/lib/aid` for a shared install), overridable via the `AID_HOME`
environment variable. It holds machine state such as `registry.yml`. Distinct from the install
*code* home (the shipped tree, self-located independently of `AID_HOME`).

**Relates-to:** AidInstallCore (installs into it), Dashboard Server (resolves the registry from
it), Install channel (recorded alongside it).

**sources:**
- `bin/aid` (`AID_STATE_HOME="${AID_HOME:-${HOME}/.aid}"`)
- `dashboard/server/server.mjs` (header "AID_HOME (state home) resolution for registry.yml")

### Recipe

**Aliases:** Slot

**Definition-as-used-here:** A pre-filled lite-path template for a recurring change pattern,
under `canonical/aid/recipes/`, named by the change it makes (`add-X` / `change-X` / `fix-X`
plus a few verbs). TRIAGE matches a free-form work description to a recipe by reading each
recipe's one-line `summary:`. Body = frontmatter (`name`, `applies-to`, `slot-count`,
`task-count`, `summary`) + `## spec` + `## tasks` + `{{slot}}` placeholders substituted by
`parse-recipe.sh`. A shortcut for known patterns, not a quality bypass — it produces the same
typed, reviewed task set.

**Relates-to:** Lite Path (recipes drive it), Slot (recipe placeholder), TRIAGE (matches the
recipe), Task (what a recipe emits).

**sources:**
- `docs/glossary.md` ("Recipe")
- `canonical/aid/scripts/interview/parse-recipe.sh` — the slot substitutor

### Canonical-Source Render-and-Vendor Pipeline

**Aliases:** render pipeline, the render pipeline

**Definition-as-used-here:** AID's defining build model: author once in `canonical/`, render to
five byte-identical `profiles/` via `run_generator.py`, prove correctness with the VERIFY
byte-compare gate, then vendor `bin/`/`lib/`/`dashboard/` into the npm and PyPI wrappers and
tarball per-profile bundles for GitHub Releases. The chain runs from `canonical/` to the
rendered `profiles/`, then into the `packages/` wrappers, then to the user install.

**Relates-to:** Canonical (the source), Profile (the rendered targets), Emission Manifest (the
emit contract), Polyglot Parity Obligation (why parity matters across the chain).

**sources:**
- `docs/aid-methodology.md` ("The build pipeline")
- `canonical/EMISSION-MANIFEST.md` — the emit/safety boundary

### Dual-Face Dogfood Repository

**Definition-as-used-here:** This repository has two faces: the *product*
(`canonical/`->`profiles/`->`packages/`) and the *dogfood install* (`.claude/` rendered
profile + `.aid/` pipeline state/KB) where AID is used to build AID. The `.aid/` content is
real working state, not example data.

**Relates-to:** Canonical (the product face), Profile (the rendered dogfood face), Knowledge
Base (the dogfood KB you are reading).

**sources:**
- `project-structure.md` ("The dogfood install")
- `.aid/settings.yml` (`project.name: AID`, `project.type: brownfield`)

### Polyglot Parity Obligation

**Definition-as-used-here:** Because AID must install through both Bash and PowerShell hosts
and ship via both npm and PyPI, the same logic is implemented in multiple languages that MUST
stay behaviorally identical -- `aid-install-core.sh` mirrors `AidInstallCore.psm1`;
`server.mjs` is a byte-parity sibling of `server.py`. Parity is enforced by tests, never
assumed.

**Relates-to:** AidInstallCore (the mirrored install engine), Dashboard Server (the mirrored
servers), Profile (per-host rendering).

**sources:**
- `project-structure.md` ("polyglot by design")
- `dashboard/server/server.mjs` (header "Byte-parity sibling of server.py")

### Human-Gated Phase Advancement

**Definition-as-used-here:** The rule that the pipeline never auto-advances -- a human approves
every phase transition (the "OK?" gate, the Iron Man model's pilot-in-the-cockpit). This is
distinct from the deterministic grade gate (which is *computed*): this is the human checkpoint
*between* phases.

**Relates-to:** Grade (the computed gate it complements), Feedback Loop (what a human may
trigger at a gate), Knowledge Base (the human approves KB output too).

**sources:**
- `docs/aid-methodology.md` ("Between phases, the human gives the OK to advance")
- `docs/glossary.md` ("Phase Gate")

### Grade

**Definition-as-used-here:** A letter score *computed* deterministically by `grade.sh` from the
`[SEVERITY]` tags a reviewer emits — never hand-picked. The reviewer only classifies issues; the
grade follows automatically (worst severity dominates, the count within it sets the modifier). A
phase or delivery passes only when the grade meets the resolved `minimum_grade`.

**Relates-to:** Delivery Gate (where a grade gates a delivery), Human-Gated Phase Advancement (the
computed gate the human approval complements), Task (each reviewed task carries a grade).

**sources:**
- `canonical/aid/templates/grading-rubric.md` — "Grade is **deterministic** — calculated from issue count and severity"
- `canonical/aid/scripts/grade.sh` — the grade computation

### Describe / Define

**Aliases:** aid-describe, aid-define, the Interview split

**Definition-as-used-here:** The two skills that together perform Phase 2 (Describe → Define). **`aid-describe`**
(Phase 2a) gathers requirements through the seasoned-analyst interview and runs TRIAGE — it
produces the approved `REQUIREMENTS.md` on the full path (or a work-root `SPEC.md` + task
hierarchy on the lite path), and on greenfield authors the forward-authored KB seed
(DESCRIBE-SEED). **`aid-define`** (Phase 2b, full path only) begins from the approved
`REQUIREMENTS.md` and decomposes it into per-feature `SPEC.md` stubs (FEATURE-DECOMPOSITION),
then cross-references them against the KB and codebase (CROSS-REFERENCE). This pair replaced the
single former `aid-interview` skill — `aid-describe` is renamed-and-scoped to "describe the work,"
`aid-define` to "define the features."

**Relates-to:** Triage (the opening state of `aid-describe`), Seasoned-Analyst Engine (drives
`aid-describe`'s interview), Forward-Authored Seed (authored by `aid-describe` DESCRIBE-SEED),
Work (the unit this pair creates).

**sources:**
- `canonical/skills/aid-describe/SKILL.md` — "Conversational requirements gathering … handoff to /aid-define"
- `canonical/skills/aid-define/SKILL.md` — "Feature decomposition … from an approved REQUIREMENTS.md (produced by /aid-describe)"
- `docs/aid-methodology.md` ("Phase 2: Describe → Define (`aid-describe` → `aid-define`)")

### Seasoned-Analyst Engine

**Aliases:** elicitation engine, D1 opener, NFR-7 envelope, five-step selector

**Definition-as-used-here:** The deterministic interview driver inside `aid-describe`
(`references/elicitation-engine.md`): **one** fixed D1 opener (the only fixed turn) followed by a
five-step next-move selector that runs every subsequent turn — STOP-CHECK, GAP-SELECTION (from a
gap inventory, by precedence), MOVE-SELECTION (from the move playbook), CALIBRATION-SHAPING (depth),
and ENVELOPE + EMIT. It is consumed (never re-implemented) by both TRIAGE (over the route-deciding
5-signal gap inventory) and DESCRIBE-SEED (over the 5-element seed gap inventory) via a
three-parameter contract: gap inventory / stop predicate / record sink. One question per turn,
never batched.

**Relates-to:** Triage (consumes the engine to route), Forward-Authored Seed (consumes the engine
to author the seed), NFR-7 envelope (the per-emission wrapper), Concept Spine (the keystone the
engine elicits in greenfield).

**sources:**
- `canonical/skills/aid-describe/references/elicitation-engine.md` ("D1 Fixed Opener", "Adaptive Loop")
- `canonical/skills/aid-describe/references/advisor-stance.md` ("The Envelope Template")

### NFR-7 Suggested-Answer + Rationale

**Aliases:** NFR-7, advisor stance, Suggested/Why envelope, straw-man reflect-back

**Definition-as-used-here:** The non-negotiable shape of every question the seasoned-analyst
engine emits: a context line, the question, a concrete **`Suggested:`** value (a real straw-man
answer — never blank, never "-"), and a grounded **`Why:`** rationale (why that suggestion fits,
tied to the user's prior words, the KB, or expert judgment). A bare, suggestion-less question is a
malformed emission; a pre-emit self-check rejects any turn missing `Suggested:` or `Why:`. The
engine recommends as a real expert rather than punting with "it depends," surfacing its answer as
a `Suggested:` the user can knowingly accept or override.

**Relates-to:** Seasoned-Analyst Engine (which wraps every emission in this envelope), Triage (its
route-confirmation turn is an NFR-7 straw-man), Forward-Authored Seed (its conflict-surfacing and
seed questions are NFR-7-wrapped).

**sources:**
- `canonical/skills/aid-describe/references/advisor-stance.md` ("The Envelope Template", "Suggested:", "Why:")
- `canonical/skills/aid-describe/references/elicitation-engine.md` ("no bare, suggestion-less question is ever emitted")

### Triage

**Definition-as-used-here:** The opening state of `/aid-describe` (after FIRST-RUN scaffolding,
before the conversational interview) that routes a work down either the *full* path (every
numbered phase) or the *lite* path (a condensed phase set, same artifacts), and matches a
free-form work description to a Recipe. It is **engine-driven**: the seasoned-analyst engine
draws out the route-deciding signals over a **5-signal gap inventory** (scope size/shape →
full-vs-lite; work-type → lite sub-path; target-artifact identity → recipe match; behavior/flow
span → secondary sizing; KB anchoring → sharper sizing), halting as soon as full-vs-lite is
decided AND recipe confidence resolves to single-clear-winner / several-plausible / none. A
confident, user-confirmed single recipe match routes to lite automatically; any signal short of
that routes full.

**Relates-to:** Lite Path (where triage routes small work), Recipe (what triage matches against),
Work (the unit triage classifies), Seasoned-Analyst Engine (which draws out the route-deciding
signals), Describe / Define (Triage is `aid-describe`'s opening state).

**sources:**
- `canonical/skills/aid-describe/references/state-triage.md` ("Engine-driven analyst triage", "Triage gap inventory")
- `docs/aid-methodology.md` — "`/aid-describe`'s TRIAGE routes small work to the lite path automatically"
- `canonical/aid/scripts/interview/parse-recipe.sh` — the recipe matcher triage drives

### Lite Path

**Definition-as-used-here:** The TRIAGE-routed condensed pipeline for small, single-target work:
the same typed, reviewed artifacts as the full path but with phases collapsed (Specify+Plan+Detail
fold into `aid-describe`'s lite-path task breakdown). It is a shortcut for known patterns, not a
quality bypass.

**Relates-to:** Triage (what routes work here), Recipe (what drives a lite run), Task (what a lite
run still emits).

**sources:**
- `docs/aid-methodology.md` — "lite path<br/>small, single-target"
- `docs/glossary.md` — the lite/full path distinction

### Forward-Authored Seed

**Aliases:** forward-authored, greenfield inversion, design-authoritative seed, KB seed

**Definition-as-used-here:** The greenfield KB-seed that `aid-describe`'s DESCRIBE-SEED state
authors from elicited intent **before any code exists** — the **inversion** of the brownfield
default. In brownfield, code is the source of truth and the KB *describes* it (extracted). In
greenfield, the design is authored first and **IS** the source of truth: code is built to CONFORM
to it (authority direction is design→code until a human reconciles drift). Seed docs carry
`source: forward-authored` (the third `source:` enum value), are design-authoritative, and the
freshness check folds them to `current` (source-drift N/A) rather than flagging them stale. The
seed is the **5-element doc-set** — concept-spine/ubiquitous-language (`domain-glossary.md`,
mandatory) + intended architecture (`architecture.md`, mandatory) + conventions
(`coding-standards.md`, deferrable) + tech-stack (`technology-stack.md`, deferrable) + decisions
(`decisions.md`, conditional, ADR-immutable with supersession) — kept minimal (intent, not
inventory).

**Relates-to:** Concept Spine (the seed's mandatory keystone element), Seasoned-Analyst Engine
(which elicits the seed), Conformance Check (the code→design check that later verifies the design),
Knowledge Base (where the seed docs live), Describe / Define (`aid-describe` authors the seed).

**sources:**
- `canonical/skills/aid-describe/references/state-describe-seed.md` ("Gap Inventory -- 5-Element Seed Model", "source: forward-authored")
- `canonical/aid/templates/kb-authoring/frontmatter-schema.md` ("`forward-authored` | Authored from intent before code exists")
- `canonical/aid/scripts/kb/kb-freshness-check.sh` (`forward-authored` short-circuit to `current`)

### Conformance Check

**Aliases:** code→design conformance, design conformance, conformance verification

**Definition-as-used-here:** The (feature-005) check that verifies as-built **code conforms to the
design-authoritative forward-authored KB seed** — the inverse direction from brownfield freshness.
Because a `source: forward-authored` doc is design→code authoritative, the f007 freshness check
explicitly does NOT flag it as stale when a source changes (it folds to `current`); detecting where
the code has *diverged* from the design — and flagging that divergence for **deliberate human
reconciliation** rather than silently overwriting the design with as-built — is the conformance
check's job, a distinct concern from freshness.

**Relates-to:** Forward-Authored Seed (the design contract it checks against), Knowledge Base (the
seed docs are the authority), Feedback Loop (divergence is reconciled deliberately, not silently).

**sources:**
- `canonical/aid/scripts/kb/kb-freshness-check.sh` ("the inverse code->design conformance check is feature-005 work, not f007")
- `canonical/aid/templates/kb-authoring/frontmatter-schema.md` ("code->design divergence is detected by feature-005's separate conformance check, NOT by f007")

### Feedback Loop

**Definition-as-used-here:** A formal pathway for a downstream phase to revise upstream artifacts,
producing a traceable record (a Q&A entry in a STATE file, an IMPEDIMENT file, or a Monitor
finding) rather than a silent rewrite. AID defines eleven named feedback loops; they are the design
answer to drift, not a failure mode.

**Relates-to:** Human-Gated Phase Advancement (a human may trigger a loop at a gate), Knowledge
Base (the artifact a loop most often revises), Grade (a failing grade can open a loop).

**sources:**
- `docs/glossary.md` — "A formal pathway for a downstream phase to revise upstream artifacts"
- `docs/aid-methodology.md` — "AID defines eleven named feedback loops"

### Dashboard

**Aliases:** dashboard server, the dashboard, Summary Stage

**Definition-as-used-here:** AID's one runtime component — a read-only, loopback-only local web
view that parses `.aid/` pipeline state and the Knowledge Base across repos and serves them as
HTML (the dashboard *server* is the Node/Python process; the *Summary Stage* of `aid-housekeep`
regenerates the visual KB summary it presents). It writes nothing and runs no LLM.

**Relates-to:** Pipeline State (what the dashboard reads), Task Status (a view it renders),
Knowledge Base (the other surface it presents).

**sources:**
- `dashboard/README.md` — "the AID dashboard component"
- `dashboard/reader/models.py` — the read-only models the dashboard serves

### Pipeline State

**Aliases:** Phase Transition, Calibration Log, Documents Status

**Definition-as-used-here:** The authored run-state of a work, tracked in its `STATE.md`: the
current phase and lifecycle, the recorded *phase transitions* between phases, the *calibration log*
(agent ETA-band vs actual runtime), and — in the discovery area — the *documents status* table of
KB-doc completeness. It is the single-writer truth the dashboard reads.

**Relates-to:** Work (whose state this is), Delivery State (the per-delivery counterpart),
Human-Gated Phase Advancement (what advances it).

**sources:**
- `canonical/aid/templates/work-state-template.md` — "Pipeline State, Triage, Escalation Carry, Interview State, Lifecycle History"
- `canonical/aid/templates/discovery-state-template.md` — the discovery-area state ledger

### Task Status

**Aliases:** Tasks State, TaskStatus, Task Detail

**Definition-as-used-here:** A task's lifecycle status and its derived views: the `TaskStatus`
enum the dashboard reader assigns, the `Tasks State` rollup section unioned across per-task
`STATE.md` files, and the `Task Detail` per-task view. The rollup is read-time derived, never
hand-written.

**Relates-to:** Task (whose status this is), Execution Graph (which orders the tasks), Dashboard
(which renders these views).

**sources:**
- `dashboard/reader/models.py` — "class TaskStatus(str, Enum)"
- `canonical/aid/templates/work-state-template.md` — the `Tasks State` rollup

### Delivery Gate

**Aliases:** Delivery Gates, Delivery State, Quick Check Findings

**Definition-as-used-here:** The per-delivery review gate recorded in `delivery-NNN/STATE.md`: it
aggregates the deferred `Quick Check Findings` accumulated by Small-tier in-task quick checks and
requires the delivery's `grade.sh` grade to meet the minimum before the delivery ships. The
`Delivery State` is the surrounding delivery lifecycle block.

**Relates-to:** Delivery (what the gate guards), Grade (what the gate requires), Task (whose quick
checks feed it).

**sources:**
- `canonical/aid/templates/work-state-template.md` — "## Delivery Gates"
- `docs/aid-methodology.md` — the two-tier review design feeding the gate

### Candidate Concepts

**Aliases:** Ranked Candidates

**Definition-as-used-here:** The salience-ordered table of harvested + synthesis terms
(`candidate-concepts.md`) that the discovery closure loop must drive to a terminal state — each
either grounded in the Concept Spine or dismissed. The `Ranked Candidates` heading is the table
itself.

**Relates-to:** Concept Spine (which grounds the candidates), Knowledge Base (where the spine
lives).

**sources:**
- `.aid/generated/candidate-concepts.md` — "## Ranked Candidates"
- `canonical/aid/scripts/kb/harvest-coined-terms.sh` — the harvester that emits them

---

## Lexicon — Pipeline Run-State

> Vocabulary for the `STATE.md` run-state ledgers (not load-bearing spine concepts).

| Term | Meaning here | Source |
|------|--------------|--------|
| Pipeline State | The `## Pipeline State` section of a work `STATE.md` tracking phase/lifecycle | `canonical/aid/templates/work-state-template.md` |
| Phase Transition | A recorded move from one phase to the next; logged in `STATE.md` | `canonical/aid/templates/work-state-template.md` |
| Delivery State | The `delivery-NNN/STATE.md` lifecycle + gate block | `canonical/aid/templates/work-state-template.md` |
| Delivery Gate(s) | The per-delivery delivery-gate review block in `delivery-NNN/STATE.md` | `canonical/aid/templates/work-state-template.md` ("## Delivery Gate") |
| Tasks State / Task Status | The derived per-task status rollup in a `STATE.md` | `dashboard/reader/models.py` (`class TaskStatus`) |
| Task Detail | A single task's detailed state view (dashboard/reader) | `dashboard/reader/models.py` (`class TaskModel`) |
| In Progress | A lifecycle status value used in state ledgers and the dashboard | `dashboard/reader/models.py` (`class Lifecycle`) |
| User Approved | The human-approval flag a phase gate writes into `STATE.md` | `canonical/aid/templates/discovery-state-template.md` |
| Documents Status | The discovery `STATE.md` table of KB-doc completeness per doc | `canonical/aid/templates/discovery-state-template.md` |
| Calibration Log | The `STATE.md` table recording agent ETA-band vs actual runtime | `canonical/aid/templates/work-state-template.md` |
| Quick Check Findings | High findings from the Small-tier in-task quick-check, accumulated for the delivery gate | `docs/aid-methodology.md` ("The two-tier review design") |
| State Detection | A skill re-entrancy mechanism: detect the stalled state and resume there | `canonical/skills/aid-deploy/SKILL.md` |
| Seed Authoring | The `## Seed Authoring` STATE.md block tracking DESCRIBE-SEED progress (elements authored, coherence check, review grade) | `canonical/skills/aid-describe/references/state-describe-seed.md` ("## Seed Authoring") |
| Summary Stage | The SUMMARY-DELTA stage of `aid-housekeep` (regenerate the visual summary) | `canonical/aid/scripts/housekeep/housekeep-state.sh` |
| Change Log | The mandatory last section of every KB/artifact doc recording revisions | `canonical/aid/templates/feature-inventory.md` |

---

## Lexicon — Dashboard Reader

> Models the read-only dashboard parses `.aid/` state into. See [integration-map.md](integration-map.md).

| Term | Meaning here | Source |
|------|--------------|--------|
| RepoInfo | Per-repo identity + KB-state reference model (DM-3 Level 1) | `dashboard/reader/models.py` (`class RepoInfo`) |
| RepoModel / WorkModel | The assembled per-repo / per-work model the API serves | `dashboard/reader/models.py` (`class WorkModel`) |
| TaskStatus | Enum of a task's lifecycle status in the reader | `dashboard/reader/models.py` (`class TaskStatus`) |
| WorkById / Work By Id | Dashboard lookup of a work by its id | `dashboard/server/tests/test_index_html.py` |
| DM-1 / DM-2 | The repo-model envelope (`/r/<id>/api/model`) and home model (`/api/home`) | `dashboard/server/server.mjs` (header "DM-1 envelope", "DM-2 model") |

---

## Lexicon — Install and CLI

> Vocabulary of the `aid` CLI, the installers, and the distribution channels.

| Term | Meaning here | Source |
|------|--------------|--------|
| AID_INSTALL_CHANNEL | Records which bootstrap channel installed the CLI (curl/npm/pypi); read by `aid update self` | `bin/aid` (`channel="${AID_INSTALL_CHANNEL:-}"`) |
| Aid Update Self If Stale | The CLI self-update-if-stale routine | `tests/windows/Test-AidInstaller.ps1` |
| Protect-on-diff | **Retired** install policy (removed v1.1.0): formerly wrote `<file>.aid-new` + exit 5 when a root-agent file was non-AID. Superseded by in-place `AID:BEGIN/END` region replacement, which preserves user content without a sidecar | `decisions.md` D11; `lib/aid-install-core.sh` (`_copy_root_agent_file`) |
| TargetDirectory / NoPath / No Profile | Install-core parameters/sentinels for the destination and tool selection | `docs/install.md`; `bin/aid` |
| AidVersion / AidStatusBody / AidSupportedFormat | CLI/PowerShell status structures and the supported-format enum | `dashboard/server/server.mjs` (`AidVersion`); `install.ps1` (`AidStatusBody`); `tests/canonical/test-aid-cli-parity.sh` |
| sha256 / File Hash | Release-artifact integrity (the `SHA256SUMS` published with bundles) | `docs/install.md`; `release.sh` |
| dry-run | A mode that assembles artifacts but performs no network/destructive I/O | `release.sh` (`--dry-run`); `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` |
| Max Concurrent | The parallel-pool capacity (`execution.max_parallel_tasks`, default 5) | `.aid/settings.yml`; `docs/aid-methodology.md` ("Max Concurrent") |
| wave | A set of tasks with no unmet dependencies that run in parallel | `canonical/skills/aid-detail/references/execution-graph-generation.md` |

---

## Lexicon — Build, Render and Install Mechanics

| Term | Meaning here | Source |
|------|--------------|--------|
| VERIFY (deterministic) gate | Re-renders all five profiles to a scratch dir and byte-compares against committed `profiles/`; any mismatch is a hard failure | `docs/aid-methodology.md` ("A VERIFY (deterministic) gate"); `.claude/skills/generate-profile/scripts/verify_deterministic.py` |
| pure-mirror deletion | The generator's deletion pass — remove files in the previous emission manifest but absent from the current one; the manifest is the safety boundary | `canonical/EMISSION-MANIFEST.md` ("authoritative safety boundary … pure-mirror"); `.claude/skills/generate-profile/scripts/run_generator.py` |
| RAG by convention | AID's retrieval model: fixed-shape KB + `INDEX.md`, no vector DB — agents navigate three tiers: the always-loaded INDEX, then one KB document on demand, then a cited file-and-symbol anchor | `docs/aid-methodology.md` ("RAG by convention") |
| format_version (per-repo stamp) | The schema-version stamp (in `settings.yml` + a per-repo migration marker) the CLI reads to migrate older installs | `bin/aid`; `.aid/settings.yml` (`format_version`) |
| block-radius | The BFS-computed set of tasks transitively depending on a failed task; all are marked Blocked | `canonical/aid/scripts/execute/compute-block-radius.sh` |
| protect-on-diff | **Retired** install collision policy (removed v1.1.0; superseded by in-place `AID:BEGIN/END` region replacement) — see the Install-and-CLI lexicon entry | `decisions.md` D11 |

---

## Lexicon — KB Authoring

| Term | Meaning here | Source |
|------|--------------|--------|
| kb-category | The frontmatter field tagging a KB doc's role (`primary`/`meta`/…) | `canonical/aid/scripts/kb/build-kb-index.sh` |
| source (frontmatter field) | The doc's production mode — `hand-authored` \| `forward-authored` \| `generated`; `forward-authored` marks a design-authoritative greenfield seed doc | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` ("### `source:`") |
| Ranked Candidates | The salience-ordered candidate-concepts table | `.aid/generated/candidate-concepts.md` ("## Ranked Candidates") |
| Term / Term Name / Unique Term | Glossary-tooling labels for a candidate/grounded term | `canonical/aid/scripts/kb/build-metrics.sh`; `canonical/skills/aid-discover/references/agent-prompts.md` ("Unique Term") |
| summary (recipe / frontmatter field) | A one-line description; TRIAGE reads a recipe's `summary:` to match work | `docs/glossary.md` ("summary (recipe field)") |
| dashboard | The read-only local web view of `.aid/` state across repos | `dashboard/README.md` |

---

## Lexicon — UI Components and Identity

| Term | Meaning here | Source |
|------|--------------|--------|
| VersionBadge | Astro site component rendering the current AID version | `site/src/components/VersionBadge.astro` |
| CardGrid / Card Grid | Astro site layout component (card grid) | `site/.astro/data-store.json` |
| LifecycleBadge / Lifecycle Badge | Dashboard/site badge component for lifecycle status | `dashboard/server/tests/test_index_html.py` |
| PipelineDiagram | Site component rendering the pipeline diagram | `site/src/data/__tests__/ac13-version-injection.test.ts` |
| GitHub | The host platform: source repo, Releases, and Actions CI/CD | `release.sh`; `.github/workflows/` |
| AndreVianna | The maintainer/owner handle; the bot push identity is `AndreVianna-AI` | `.github/workflows/release.yml` |
| codex | The Codex CLI host tool / its render profile | `profiles/codex.toml` |

---

## Abbreviations & Acronyms

| Abbreviation | Full Form | Context |
|--------------|-----------|---------|
| AID | AI Integrated Development | the project/methodology |
| KB | Knowledge Base | `.aid/knowledge/` |
| CR | Change Request | Monitor classification (vs BUG) |
| SDD | Spec-Driven Development | the methodology AID extends |
| MCP | Model Context Protocol | Playwright MCP for visual validation |
| CLI | Command-Line Interface | the persistent `aid` command |
| CI/CD | Continuous Integration / Delivery | the four GitHub Actions workflows |
| MVP | Minimum Viable Product | each Delivery is an MVP |
| PD | Parallel Dispatch | Execute's continuous parallel-pool model |
| BFS | Breadth-First Search | computes a failed task's transitive block radius |
| DM-1 / DM-2 / DM-3 | Data Model levels | dashboard server/reader envelopes |
| SEC-1..4 | Security invariants | dashboard server (loopback-only, read-only, no LLM) |
| NFR-7 | Suggested-answer + rationale invariant | every interview-engine question carries `Suggested:` + `Why:` |

---

## Terms with Specific Domain Meanings

> Standard terms that mean something particular in AID.

| Term | Industry meaning | Meaning here |
|------|------------------|--------------|
| Canonical | "standard / conventional" | the `canonical/` source-of-truth tree; the authority over `profiles/` |
| Profile | a user/config profile | one of the five rendered host-tool install trees |
| Delivery | a deployment/shipment | an ordered, independently shippable MVP grouping of features within a work |
| Work | a generic job/effort | a self-contained pipeline scope unit at `.aid/work-NNN-*/` |
| Wave | an ocean wave / release wave | a parallel batch of dependency-ready tasks in the Execution Graph |
| Grade | an academic mark assigned by a person | a value *computed* deterministically by `grade.sh` from severity tags, never hand-picked |
| Lite | "lightweight version" | the TRIAGE-routed condensed path for small work — same artifacts, fewer phases |
| Forward-authored | (no common meaning) | a KB doc authored from intent *before code exists*; design-authoritative (design→code), the greenfield seed |
| Conformance | generic standards-compliance | verifying as-built code matches the design-authoritative forward-authored seed (code→design) |

---

## Invariants

> Conceptual rules about the vocabulary that an agent must not violate.

- **Canonical is the only source of truth.** `profiles/` is rendered output; editing it
  directly (instead of `canonical/` + re-render) violates the model and the VERIFY gate.
- **One Work per Describe → Define pair.** A work owns its requirements/features/deliveries/tasks; multiple
  works share one Knowledge Base. Never fold two scopes into one work.
- **Delivery ≠ Task.** Delivery is the strategy unit (what ships, in what order); Task is the
  tactical unit (one session/PR). Plan sequences deliveries; Detail decomposes them into tasks.
- **A Grade is computed, never judged.** Reviewers emit `[SEVERITY]` tags only; the letter
  comes from `grade.sh`. "Pick a grade" is never a valid action.
- **The reviewer never grades its own work.** The reviewer's tier is always ≥ the executor's,
  in a clean context.
- **The KB is the gravitational center.** Not the spec, not the code — when they disagree, the
  KB is updated through a feedback loop, not silently bypassed.
- **Greenfield inverts the authority direction.** A `forward-authored` seed doc is
  design→code authoritative: code is built to conform to it, and divergence is reconciled
  deliberately (the conformance check), never silently overwritten with as-built.
- **No bare interview question.** Every seasoned-analyst-engine emission carries a concrete
  `Suggested:` and a grounded `Why:` (NFR-7); a suggestion-less question is malformed.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial glossary: 16 spine concepts grounded + supporting lexicon (Integrator owns the spine) |
| 1.1 | 2026-06-25 | aid-discover (closure 5b) | Closure loop: promoted 9 load-bearing concepts to spine headings (Grade, Triage, Lite Path, Feedback Loop, Dashboard, Pipeline State, Task Status, Delivery Gate, Candidate Concepts) and added synonym Aliases on 7 existing concepts so the self-containment oracle resolves every used term |
| 1.2 | 2026-06-27 | work-001-aid-interview-improvements | aid-describe/aid-define split: rekeyed Triage to `/aid-describe` (engine-driven 5-signal gap inventory); added Describe / Define, Seasoned-Analyst Engine, NFR-7 Suggested-Answer + Rationale, Forward-Authored Seed, and Conformance Check spine concepts; strengthened Concept Spine (ubiquitous-language alias + greenfield seed keystone); added `source`/`Seed Authoring` lexicon rows, NFR-7 acronym, forward-authored/conformance domain terms, and two greenfield invariants |
| 1.3 | 2026-06-28 | tech-writer | Relabeled Phase 2 from "Interview" to "Describe → Define": updated Work definition, Describe/Define entry, source citation, and the One-Work-per invariant. |
