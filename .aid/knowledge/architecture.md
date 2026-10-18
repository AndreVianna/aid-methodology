---
kb-category: primary
source: hand-authored
objective: How the AID system is built and why it is shaped this way — its dual product/dogfood anatomy, the canonical→profiles→release render-and-distribute architecture, and the six-phase gated process architecture (pipeline, skill state machines, agent dispatch).
summary: Read this to understand HOW AID hangs together as both a runnable CLI installer and a process methodology — the boundaries, the source-of-truth flow, the pipeline, and the invariants a change must never break.
sources:
  - docs/aid-methodology.md
  - canonical/
  - profiles/
  - .claude/skills/generate-profile/scripts/run_generator.py
  - release.sh
  - lib/aid-install-core.sh
  - README.md
tags: [C1, architecture, pipeline, render-pipeline, state-machine, agent-dispatch, dogfood]
see_also: [project-structure.md, technology-stack.md, decisions.md, module-map.md]
owner: architect
audience: [architect, developer]
review-criteria: []  # nothing is true of this doc alone -- the global level and the
                     # kb-doc level cover it. Its version invariant is already stated as
                     # VERSION lockstep rather than a literal, so it needs no criterion of
                     # its own to keep it from drifting.
---

# Architecture

> **Source:** aid-discover (Phase 1)
> **Status:** Complete

## Contents

- [Project Type](#project-type)
- [The Two Faces (Product vs Dogfood)](#the-two-faces-product-vs-dogfood)
- [Load-Bearing Boundaries](#load-bearing-boundaries)
- [Build & Distribute Architecture (canonical -> profiles -> packages)](#build--distribute-architecture-canonical---profiles---packages)
- [Process Architecture: The Six-Phase Pipeline](#process-architecture-the-six-phase-pipeline)
- [Skill State-Machine Model](#skill-state-machine-model)
- [Agent / Sub-Agent Dispatch Model](#agent--sub-agent-dispatch-model)
- [The Knowledge Base as the Center](#the-knowledge-base-as-the-center)
- [Data Flow (the three real paths)](#data-flow-the-three-real-paths)
- [Entry Points](#entry-points)
- [Doc-vs-Code Discrepancies](#doc-vs-code-discrepancies)
- [Invariants](#invariants)
- [Gotchas](#gotchas)

---

## Project Type

AID is **not a runtime application**. It is two things bound into one repository:

1. **A methodology** — a full software-development lifecycle, defined as prose state
   machines (skills) and role definitions (agents), shipped as installable content.
2. **A polyglot CLI installer** — the `aid` command that drops that methodology into a
   user's repo for whichever AI coding tool they use.

CONFIRMED. `README.md` (search: "A full-lifecycle methodology for building software with
AI agents") and `docs/aid-methodology.md` (search: "A Complete Methodology for AI
Integrated Software Development"). The installable nature is confirmed by `bin/aid`,
`install.sh`, and the npm/PyPI wrappers under `packages/`.

There is no single "main()". AID has several distinct entry points (see
[Entry Points](#entry-points)). The center of gravity is **content** (markdown skills,
agents, templates) plus the **render/install machinery** that distributes it.

---

## The Two Faces (Product vs Dogfood)

The single most important thing a newcomer must grasp: this repository is **simultaneously
the product's source AND a live AID installation of itself**. This is a SYNTHESIS concept —
no single coined token names it; it is the load-bearing shape of the whole repo.

| Face | Where it lives | What it is |
|------|----------------|-----------|
| **Product** | `canonical/`, `profiles/`, `packages/`, `bin/`, `lib/`, `install.sh`, `install.ps1` | The installable AID toolkit + the CLI that installs it. |
| **Dogfood** | The CLI-installed trees `.agents/skills/`, the `.claude/skills/` mirror, `.aid/runtime/`, `.claude/agents/` and `.cursor/agents/`, plus `.aid/` (pipeline state + this Knowledge Base) | AID *installed into AID* — the maintainers use AID to build AID. |

CONFIRMED. `project-structure.md` (search: "The repo dogfoods itself") and
`docs/aid-methodology.md` describe the dual nature; `.aid/settings.yml` records
`project.type: brownfield`.

**Consequence for any change:** the same logical file frequently exists in many physical copies -- `canonical/` (the source) → the release payload and the five `profiles/<tool>/` agent trees (rendered) → the dogfood installed trees (`.agents/skills/`, `.claude/skills/`, `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`) → `packages/npm/` and `packages/pypi/.../_vendor/` (vendored for publish). Editing an installed or vendored copy is a defect; edit `canonical/`, re-render, and resync the dogfood install. CONFIRMED via `project-structure.md` (search: "Heavy, deliberate file duplication").

---

## Load-Bearing Boundaries

The boundaries are not class/layer boundaries (this is not an OO app). They are
**source-of-truth boundaries** and **process boundaries**:

| Boundary | Rule | Why it falls here |
|----------|------|-------------------|
| `canonical/` vs `profiles/` | `canonical/` is the only editable source; `profiles/<tool>/` holds generated agent trees only. | One agent source rendered to five tool dialects keeps the five host tools in lockstep. Skills and runtime are never rendered; release.sh copies them verbatim. |
| `profiles/` vs `packages/` | `packages/` vendors `bin/`, `lib/`, `dashboard/` for publication; it does not author logic. | Publication channels (npm/PyPI) wrap, never fork, the engine. |
| Product (`canonical/`,`bin/`,`lib/`) vs Dogfood (`.aid/`,`.agents/`,`.claude/`,`.cursor/`) | Dogfood state is real working state, never product source. | The repo eats its own cooking without contaminating the shipped artifact. |
| Executor agent vs Reviewer agent | The agent that writes never grades its own work; reviewer tier >= executor tier. | Adversarial separation is the quality mechanism (see Agent Dispatch). |
| `.aid/knowledge/` (KB) vs the tracked work folders (works) | The KB is shared, cross-work, living; a work is one scoped unit. | One KB, many works — institutional memory outlives any single work. |
| `.aid/connectors/` (registry) vs host-tool config | The connectors registry is a CATALOG — it lists the connections available to a repo's agents and how to use them; it is not a connection manager and does not wire any host tool's config. | Host tools (Claude Code, Codex, Cursor, …) already own their own MCP servers and auth for what they provide; AID records only what it itself manages. |

CONFIRMED. The canonical/profiles rule is stated in `docs/aid-methodology.md` (search:
"single source of truth — never edit profiles/ directly"); the reviewer/executor rule in
`docs/aid-methodology.md` (search: "the agent that writes never grades its own work"); the
connectors catalog model in `canonical/skills/aid-discover/references/state-elicit.md` (search:
"Q10: AID writes, wires, and manages no host tool's MCP configuration") and
`canonical/aid/templates/connectors/preset-catalog.md` (search: "Management mode").

---

## Build & Distribute Architecture (canonical -> payload -> profiles -> release)

This is the architecture that makes AID a *product*. It is a SYNTHESIS concept — a
"render-and-release pipeline" — spread across several files with no single token.

**The flow:**

1. `canonical/` holds the single source: `skills/` (112 skill directories), `agents/` (8 agent
   directories) and `aid/{scripts,templates,rules.md}`. CONFIRMED via directory listing.
2. `python .claude/skills/generate-profile/scripts/run_generator.py` renders the agents into the five
   `profiles/<tool>/` trees, one per `profiles/*.toml`. Each tree is wiped and regenerated in full on
   every run; the generator renders agents only. A profile TOML keeps only per-tool data: the agent
   root directory, the root-file selection, agent tool names, `[model_tiers]`, `[capabilities]` and the
   skill-mirror list. CONFIRMED in `run_generator.py` (`shutil.rmtree` of each profile output, then
   `render_profile`).
3. The same run then executes VERIFY (deterministic), a byte-compare re-render, and VERIFY (advisory),
   and resyncs this repo's own install through the CLI (`sync_dogfood.py`). CONFIRMED in
   `run_generator.py`.
4. `bash release.sh` packages the release, with `SHA256SUMS` covering every artifact:
   - `aid-shared-v<V>.tar.gz`: `skills/` (copied from `canonical/skills/`) and `runtime/` (copied from
     `canonical/aid/`, `rules.md` included), plus `aid-payload.conf`. One payload serves every tool.
   - `aid-<tool>-v<V>.tar.gz`, one per tool (five): `aid-tool.conf` and the `<root>/agents/` tree of that
     profile. No per-tool artifact holds skills or runtime.
   - `aid-cli-v<V>.tar.gz`: the CLI (`bin/`, `lib/`).
   Artifacts keep plain names with no wrapper directory. CONFIRMED in `release.sh`
   (`build_shared_payload`, `build_tool_artifact`).
5. `release.sh --stage-only --out <dir>` stages the same artifacts from the working tree, skipping the
   clean-tree, tag, render, render-drift and network checks. `tests/lib/bundle.sh`
   (`aid_test_stage_bundle`) uses it to build hermetic test bundles, and the dogfood resync installs
   from the same staging. CONFIRMED in the `release.sh` header and `sync_dogfood.py` header.
6. CI enforces the boundary: the `render-drift` job re-runs the generator and fails if `profiles/` has
   uncommitted drift. CONFIRMED in `.github/workflows/test.yml` (search: "profiles/ is out of sync with canonical/").
7. `packages/npm/` and `packages/pypi/` vendor `bin/`, `lib/`, `dashboard/` (via `packages/npm/scripts/vendor.js` /
   `packages/pypi/scripts/vendor.py`) and publish the same `aid` CLI. CONFIRMED in `packages/npm/package.json` (search:
   "prepack") and `packages/pypi/pyproject.toml` (search: "tool.hatch.build.hooks.custom").

**Installed shape.** This is what `aid add` places in a user repo. This repo's dogfood install has the
same shape, and `.aid/.aid-manifest.json` (format 3) records every entry.

| Installed path | Comes from | Placed for |
|----------------|------------|------------|
| `.agents/skills/aid-*/` | `aid-shared` `skills/` | every tool |
| `.claude/skills/aid-*/` (byte-identical mirror, CLI-owned, no symlinks) | `aid-shared` `skills/` | Claude Code, whose profile declares the mirror |
| `.aid/runtime/scripts/`, `.aid/runtime/templates/`, `.aid/runtime/rules.md` | `aid-shared` `runtime/` | every tool |
| `.aid/runtime/host.conf` | written by the CLI (worktree root for this host) | every tool |
| `aid-*` agent files under the tool root (`.claude/agents/`, `.codex/agents/`, `.cursor/agents/`, `.github/agents/`, `.agent/agents/`) | that tool's artifact | that tool |
| `AGENTS.md`: `AID:BEGIN`/`AID:END` region whose body is a SESSION START block (the first action is a Read of `.aid/runtime/rules.md`) plus the rules summary bullets lifted from the `AID:SUMMARY` block of the installed rules (no `@` line) | CLI | every tool |
| `CLAUDE.md`: `AID:BEGIN`/`AID:END` region with the same body as the `AGENTS.md` region plus one `@.aid/runtime/rules.md` import line (the same inline rules text as `AGENTS.md`, no `@` line, under `rules_inline`); no `@AGENTS.md`, so each root file carries the rules alone | CLI | Claude Code only |

**Lifecycle rules** (implemented in `lib/aid-install-core.sh`: `install_shared`, `manifest_remove_tool`,
`prune_shared`, `drift_report`):

- **Shared entries are reference-counted.** Each shared entry (the skills, the runtime, each mirror, the
  `AGENTS.md` region, the `CLAUDE.md` region) records the tools that use it, the AID version it was written
  at and the sha256 of each file. `aid remove <tool>` removes that tool's own files and its name from every
  entry's user list; an entry is removed only when that list is empty.
- **Drift is detected and repaired.** `aid status` reports each modified, missing or extra `aid-*` file by
  path, and compares each mirror with `.agents/skills/`. `aid add` and `aid update` repair drift by moving
  the drifted file to `.aid/.trash/<original path>` and rewriting it from the verified payload.
- **One AID version per repo.** The manifest carries one top-level `aid_version`, and `aid update` moves
  every installed tool to it together.
## Process Architecture: The Six-Phase Pipeline

AID's other architecture is a **process**: a linear, human-gated pipeline of phases with
formal feedback loops. The pipeline is the methodology's backbone.

**The six numbered phases** (CONFIRMED in `docs/aid-methodology.md` §1 "The Pipeline" and
its "Skill Inventory" table):

```
Discover -> Describe/Define (2a/2b) -> Specify -> Plan -> Detail -> Execute
```

These six map onto skills (Phase 1-6), organized into **four skill groups** (Support,
Knowledge Base Maintenance, Definition, Execution). Groups organize the skills; they are
not a running order (the numbered phases carry the sequence). Phase 2 (Describe → Define) is realized by **two** skills —
`aid-describe` (2a) and `aid-define` (2b) — after the `aid-interview` split (see "The
Describe → Define Phase" below); every other numbered phase is one skill. Several lifecycle labels
from everyday SDLC talk — Init, Implement, Review, Test, Track, Triage — are **not numbered
phases**; the table below maps each label to what it really is (CONFIRMED in
`docs/aid-methodology.md` "Skill Inventory" and the `canonical/skills/` listing — **112 skill
directories**: 18 curated pipeline / on-demand / supporting skills (the `/aid-orchestrate`
intake among them) and the 94-row shortcut catalog's skills — 34 verb-first direct-entry
shortcut doorways plus 60 hand-authored `repurpose` skills):

| Workflow label | Skill(s) | Numbered phase? | What it really is |
|----------------|----------|-----------------|-------------------|
| Discover | `aid-discover` | **Phase 1** | Brownfield only; builds the KB. (`aid-summarize` is an optional viewer here.) |
| Describe | `aid-describe` | **Phase 2a** | Describe (2a) half, **full path only**: adaptive interview + COMPLETION + (greenfield) KB seed. It does not triage or emit lite work. Driven by the seasoned-analyst engine; the `aid-interviewer` AGENT does the dialogue. |
| Define | `aid-define` | **Phase 2b** | Decomposition half: feature decomposition + cross-reference (full path only); hands off to Specify. |
| Specify | `aid-specify` | **Phase 3** | Full path only. |
| Plan | `aid-plan` | **Phase 4** | Full path only. |
| Detail | `aid-detail` | **Phase 5** | Full path only. |
| Execute | `aid-execute` | **Phase 6** | 8 task types; graded review loop. |
| Init | `aid-config` | No (bootstrap) | Run once; scaffolds `.aid/` + KB placeholders. |
| Implement | `aid-execute` | No | One of Execute's 8 task types (IMPLEMENT), not a phase. |
| Review | (inside `aid-execute`) | No | A state of the Execute loop (EXECUTE -> REVIEW -> FIX -> DONE), not a phase. |
| Test | `aid-execute` | No | A task type (TEST) inside Execute, not a phase. |
| Deploy | `aid-deploy` | No (Definition shortcut path) | On-demand optional shortcut path in the Definition group; not a numbered phase. |
| Track / Monitor | `aid-monitor` | No (Definition shortcut path) | On-demand observe -> classify -> route; not a numbered phase. ("Track" has no separate referent.) Routes findings out: bug -> `/aid-fix`, change request -> a new work through `/aid-orchestrate`. |
| Triage | the skill guide in `rules.md` with `/aid-orchestrate` as its intake | No | Reads a plain request by its meaning and matches it to a skill, or answers a project question from the KB; it writes nothing itself. The former standalone suggest-only router is folded into the skill guide. Monitor still classifies its own findings. |
| Design | 22 `aid-design[-<artifact>]` skills + `aid-brainstorm` | No (pre-build stage) | Develops an idea into a **design seed** under `.aid/design/`; writes no code and no KB document. `create` realizes the seed, `update` revises what `create` committed. |
| Shortcut (Lite path) | 34 `aid-<verb>[-<artifact>]` skills + the shared shortcut engine | No (collapses Describe→Detail) | Verb-first direct-entry doorways (`/aid-fix`, `/aid-create-api`, …) that delegate to `canonical/aid/templates/shortcut-engine.md` (INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT). The autonomous Lite path — enter by naming your change. |


**The `design` stage and the shared lifecycle contract.** `design` is a pre-build grid verb
ordered `design -> create -> update`. Its 22 rows cover every artifact carrying a `create`/`update`
pair, plus a bare `/aid-design` catch-all, and all of them **bind one shared contract** rather than
restating it -- `canonical/aid/templates/design-lifecycle.md`, which fixes the seed shape, the
allocation step, the verify depth and the `design` invariant (a `design` skill writes its seed and
nothing else). That single binding is what keeps 36 skills consistent without 36 copies of the
rules, and it is why adding an artifact to the grid is a catalog row plus a thin body rather than a
new state machine. `/aid-brainstorm` sits beside the grid as an exploratory doorway with no
`create` counterpart.

Knowledge Base Maintenance group (on-demand, off the numbered pipeline): `aid-housekeep`
(KB drift reconciliation), `aid-ask` (Q&A + gap capture),
`aid-update-kb` (targeted KB delta), `aid-summarize` (HTML KB viewer) — alongside
`aid-discover` (Phase 1). CONFIRMED in `docs/aid-methodology.md` "Skill Inventory".

**Entry points, two paths** (CONFIRMED in `docs/aid-methodology.md` §1 "Three Doors In"
and §4 "The Phases"):

- **Full path** — `/aid-describe` (2a) -> `/aid-define` (2b) -> `/aid-specify` -> `/aid-plan` ->
  `/aid-detail` -> `/aid-execute` (brownfield enters at `/aid-discover` first). For broad,
  multi-target, or ambiguous work.
- **Lite path** — a verb-first **shortcut** (`/aid-fix`, `/aid-create-api`, …) drives the shared
  **shortcut engine** (`canonical/aid/templates/shortcut-engine.md`): INTAKE -> CAPTURE -> SPEC ->
  PLAN -> DETAIL -> GATE -> APPROVAL-HALT. The engine collapses Describe->Detail into one fast,
  mostly-autonomous run (it never skips a phase — it collapses the information capture within each),
  grades every generated document at GATE, then halts for approval before `/aid-execute`. The
  default for a known, single-target change.
- **Plain request.** Say what you want in your own words. The skill guide in `.aid/runtime/rules.md` matches it to one skill, or the agent answers a project question from the KB with sources and starts no work. `/aid-orchestrate` then finds or creates the work, sizes it (lite or full) and picks its phases.

CONFIRMED in `canonical/aid/templates/shortcut-engine.md`, `canonical/aid/rules.md` (`## Handling a request`), `canonical/skills/aid-orchestrate/SKILL.md`,
and `docs/aid-methodology.md` §4.

**Eleven formal feedback loops** let any phase revise an upstream artifact (8 within
development, 2 from production, 1 cross-cutting). CONFIRMED in `docs/aid-methodology.md` §6
"The Eleven Loops". The two production loops now run out to the entry layer (L9 Monitor ->
`/aid-fix`, L10 Monitor -> `/aid-orchestrate`; see `.aid/knowledge/pipeline-contracts.md`). The
cross-cutting Loop 11 (Any phase -> Discover, targeted re-discovery) is what makes the KB the
gravitational center in practice.

### Phase 2 (Describe → Define): Describe (2a) + Define (2b)

Phase 2 (Describe → Define) is realized by **two chained skills**, not one. The former
`aid-interview` SKILL was split; the `aid-interviewer` AGENT keeps its name (only the skill
split). CONFIRMED: `canonical/skills/` has `aid-describe/` and `aid-define/` and no
`aid-interview/`; `canonical/agents/aid-interviewer/` is unchanged.

- **`aid-describe` (Phase 2a)** — adaptive interview + COMPLETION and (greenfield) the KB seed,
  **full path only** (no TRIAGE, no lite states — the plain-request intake lives in `/aid-orchestrate`).
  State machine: FIRST-RUN -> Q-AND-A -> CONTINUE ->
  {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> `/aid-define`]. CONFIRMED in
  `canonical/skills/aid-describe/SKILL.md` (frontmatter `State machine:`).
- **`aid-define` (Phase 2b)** — feature decomposition + cross-reference, from an approved
  `REQUIREMENTS.md`. State machine: FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE (hands off
  to `/aid-specify`). CONFIRMED in `canonical/skills/aid-define/SKILL.md`.

**Seasoned-analyst elicitation engine.** The full-path interview is no longer free-form:
`aid-describe` drives it through a deterministic engine
(`canonical/skills/aid-describe/references/elicitation-engine.md`) — one fixed D1 "what + why"
opener plus a five-step next-move selector run every turn (STOP-CHECK -> GAP-SELECTION ->
MOVE-SELECTION -> CALIBRATION-SHAPING -> ENVELOPE+EMIT). Invariant NFR-7: every emitted
question carries a concrete `Suggested:` answer and a grounded `Why:` rationale (no bare
question). Calibration reads the user's level (`Unknown | Expert | Mixed | Novice`) every turn
and shapes depth; the advisor stance recommends but never decides silently. CONFIRMED in
`elicitation-engine.md`, `move-playbook.md`, `calibration.md`, `advisor-stance.md` under
`canonical/skills/aid-describe/references/`.

**Greenfield forward-authoring (the inversion).** On a greenfield project `aid-describe`'s
DESCRIBE-SEED state forward-authors a 5-element KB seed from elicited intent — concept-spine
(`domain-glossary.md`) + intended architecture (`architecture.md`) + conventions
(`coding-standards.md`) + tech stack (`technology-stack.md`) + decisions (`decisions.md`) —
written to `.aid/knowledge/` stamped `source: forward-authored`. THE INVERSION: in greenfield
the **docs are the source of truth and code conforms**, the opposite of brownfield where code
is truth and Discover extracts the KB. CONFIRMED in
`canonical/skills/aid-describe/references/state-describe-seed.md` ("Record Sink").

**Build conformance check (flag-not-overwrite).** Because greenfield design docs lead the
code, `/aid-housekeep`'s KB-DELTA stage carries a **Conformance Lane**: it shadow-extracts an
as-built KB from the current code and diffs it against the `source: forward-authored` design
docs (code -> design direction). Divergences (`placeholder-resolved` / `code-ahead` /
`contradiction`) are FLAGGED for human reconciliation via a Required Q&A entry; the design doc
is NEVER auto-overwritten with as-built. CONFIRMED in
`canonical/skills/aid-housekeep/references/state-kb-delta.md` ("Conformance Lane",
"Invariant -- flag, never overwrite").

---

## Skill State-Machine Model

Each skill is a **prose-defined state machine**, not a script. One invocation advances one
state; the pipeline never auto-advances (human approves each transition — a SYNTHESIS
concept, "human-gated phase advancement"; see Invariants).

- A skill's entry file is `canonical/skills/<name>/SKILL.md`; per-state behavior lives in
  `canonical/skills/<name>/references/state-*.md`. CONFIRMED via the directory inventory
  (e.g. `aid-discover/references/state-generate.md`, `state-review.md`, `state-fix.md`).
- Example — Discover runs ELICIT -> GENERATE -> REVIEW -> Q-AND-A -> FIX -> APPROVAL -> DONE
  (ELICIT captures external sources and tool integrations before GENERATE runs). CONFIRMED in
  `canonical/skills/aid-discover/SKILL.md` (search: "State-machine: ELICIT → GENERATE → REVIEW
  → Q-AND-A → FIX → APPROVAL → DONE").
- State machines are *chained* across skills (a DONE state hands off to the next skill).
  CONFIRMED via `canonical/aid/templates/state-machine-chaining.md`.
- Trivial state/arg work is done in SKILL.md prose, not bash. Only non-trivial,
  reused, deterministic operations are extracted to `canonical/aid/scripts/` (grouped by
  phase: `kb/`, `execute/`, `housekeep/`, `connectors/`, `summarize/`, `release/`,
  `migrate/`, `config/`). CONFIRMED via the `canonical/aid/scripts/` subtree.

---

## Agent / Sub-Agent Dispatch Model

A skill (driven by the host tool) dispatches **specialist sub-agents** to do the work. AID
defines **8 agents across 3 model tiers**. CONFIRMED: `canonical/agents/` holds exactly 8
(aid-architect, aid-clerk, aid-developer, aid-interviewer, aid-operator,
aid-researcher, aid-reviewer, aid-tech-writer) and `docs/aid-methodology.md` §5. The orchestrator sub-agent is retired: the main conversation orchestrates, guided by the skill guide in `rules.md` and `/aid-orchestrate`, and has no agent row.

| Tier | Agents | Role |
|------|--------|------|
| Large (1) | aid-architect | Highest-stakes reasoning where depth pays off: architecture, design decomposition, task breakdown. |
| Medium (6) | aid-developer, aid-operator, aid-tech-writer, aid-interviewer, aid-researcher, aid-reviewer | Workhorses: implement, release, document, interview, research/KB authoring, adversarial review. |
| Small (1) | aid-clerk | Mechanical extract/format/glob. |

These are **default** tiers, not fixed ceilings. A dispatch site picks the
model tier **and** reasoning effort from the task's difficulty via
`canonical/aid/templates/agent-dispatch-tiering.md`, defaulting low and escalating the
hard minority to `large` + `high`/`xhigh`. Effort is a second, independent lever
(often better than switching tiers) and defaults below the host `high` for routine and
retrieval-heavy work; `aid-researcher` in particular runs at `low` effort (research
depth does not aid retrieval). `aid-interviewer`, `aid-researcher`, and `aid-reviewer`
default to Medium; escalation restores Large where the executor or the review
genuinely needs it.

**The dispatch invariant:** the reviewer's tier is always >= the executor's tier, and the
reviewer runs in a clean context after the executor finishes (never sees the executor's
reasoning). CONFIRMED in `docs/aid-methodology.md` (search: "reviewer tier ≥ executor
tier" and "invoked in a clean context after the executor's output is complete").

**Tier -> model mapping** is declared per profile in `profiles/<tool>.toml` under
`[model_tiers]` and rendered into each install tree; bodies are byte-identical across
profiles, only model names and agent format differ. CONFIRMED in
`profiles/claude-code.toml` (search: "[model_tiers]") and `docs/aid-methodology.md` "Tier
Mapping per Profile".

**Discovery fan-out:** Discover dispatches a pre-scan `aid-researcher` (alone), then a pool
of parallel `aid-researcher` instances (one per confirmed doc-set scope), then an
`aid-reviewer` for adversarial grading. This pool replaced the five former discovery-*
agents. CONFIRMED in `docs/aid-methodology.md` (search: "replaces the former five separate
discovery-* agents").

---

## The Knowledge Base as the Center

The KB (`.aid/knowledge/`) is the gravitational center — every phase reads it, any phase
can revise it. CONFIRMED in `docs/aid-methodology.md` §3.

- **Shape:** a default seed of 14 standard docs + 3 meta docs (INDEX, STATE, README) + a
  generated `project-index.md` pre-pass + optional project-specific extensions declared via
  `discovery.doc_set` in `.aid/settings.yml`. CONFIRMED in `docs/aid-methodology.md`
  (search: "14-document standard set is the configurable default seed").
- **Retrieval = RAG by convention** (3 tiers, cheapest first): Tier 1 INDEX.md (always
  loaded) -> Tier 2 one KB doc on demand -> Tier 3 exact `path:line` citation. No vectors,
  no embeddings. CONFIRMED in `docs/aid-methodology.md` (search: "RAG by convention").
- **Fixed shape, variable depth:** `artifact-schemas.md` always holds schemas, `tech-debt.md`
  always holds debt — downstream skills navigate by convention, not search. CONFIRMED
  (search: "Convention beats search").
- **Forward-authored seeds (greenfield):** on a greenfield project the KB is not extracted
  from code but **forward-authored** by `aid-describe` DESCRIBE-SEED and stamped
  `source: forward-authored` — the docs are the source of truth and code conforms (see "The
  Describe → Define Phase" above).

---

## Data Flow (the three real paths)

There is no single request flow. The three load-bearing flows are:

**1. Render flow (build the product):**
```
canonical/ (edit here)
  -> run_generator.py  (wipe and regenerate profiles/<tool>/ agent trees, per profiles/*.toml)
  -> VERIFY (deterministic) byte-compare gate
  -> release.sh  (aid-shared: skills/ + runtime/; aid-<tool>: agents; aid-cli; SHA256SUMS)
  -> packages/{npm,pypi} vendor + publish
```
CONFIRMED in `run_generator.py`, `release.sh` and `docs/aid-methodology.md` "The build pipeline".

**2. Install flow (get AID into a user repo):**
```
curl|bash install.sh  (or irm|iex install.ps1, npm i -g, or pipx install)
  -> bootstraps the persistent `aid` CLI (~/.aid or %LOCALAPPDATA%\aid)
  -> `aid add <tool>` in a repo
  -> fetches aid-shared-v<V> and aid-<tool>-v<V>, verified against SHA256SUMS
  -> lib/aid-install-core.sh places .agents/skills/aid-*, the Claude Code .claude/skills mirror,
     .aid/runtime/, the tool's agents, the AGENTS.md region and (Claude Code only) the CLAUDE.md region
  -> records the install in .aid/.aid-manifest.json (format 3, shared entries with users and sha256)
```
CONFIRMED in `README.md` "Install", `docs/aid-methodology.md` §10 and `lib/aid-install-core.sh`.

**3. Pipeline flow (use AID on a project):**
```
/aid-config -> /aid-discover -> KB in .aid/knowledge/
  -> choose an entry:
       full  : /aid-describe -> /aid-define -> /aid-specify -> /aid-plan -> /aid-detail
       lite  : /aid-<verb>[-<artifact>] shortcut -> shortcut engine
                 (INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT)
       plain request: the skill guide in rules.md -> /aid-orchestrate sizes it and picks an entry
  -> work in its tracked work folder  -> approval halt -> /aid-execute   (numbered sequence ends here)
  separate on-demand paths (own entry, not sequential): /aid-deploy, /aid-monitor
       (Monitor: bug -> /aid-fix; change request -> /aid-orchestrate)
  (any phase -> Q&A entry in a STATE.md -> targeted re-discovery)
```
CONFIRMED in `README.md` "Quick Start", `docs/aid-methodology.md` §4, and
`canonical/skills/aid-monitor/references/state-route.md`.

---

## Entry Points

CONFIRMED in `project-structure.md` "Entry Points" and file headers:

1. Installer bootstrap — `install.sh` / `install.ps1`.
2. The CLI — `bin/aid` (Bash) / `bin/aid.ps1` + `bin/aid.cmd` (Windows).
3. Package wrappers — `packages/npm/bin/` and `packages/pypi/aid_installer/__main__.py`.
4. User-facing skills — `/aid-*` slash commands resolving to installed `SKILL.md` files.
5. Dashboard servers — `dashboard/server/server.mjs` (Node) / `dashboard/server/server.py`.
6. The maintainer build — `run_generator.py`; the release runbook — `release.sh`.
7. The website — `site/` (Astro build; independent of the CLI, but it DOES consume
   `canonical/` at build time via `gen-reference.mjs` and `gen-skills.mjs` — see module-map.md
   § Dependency Graph. The third generator, `sync-docs.mjs`, reads `docs/` only).

---

## Doc-vs-Code Discrepancies

Documented as reality + flagged; NOT silently reconciled (see `.scout-questions.tmp`):

1. **Skill count (reconciled).** `canonical/skills/` has **112** directories — 18 curated
   pipeline / on-demand / supporting skills plus the 94-row shortcut catalog's skills (34 verb-first
   direct-entry shortcut doorways + 60 hand-authored `repurpose` skills). `README.md`,
   `docs/aid-methodology.md`, `docs/repository-structure.md` and `docs/glossary.md` all state this
   taxonomy, so the doc-vs-code gap this item tracked stays closed. It cannot silently reopen:
   `tests/canonical/test-doc-counts.sh` re-derives the figures from `canonical/skills/`,
   `canonical/agents/` and `canonical/aid/templates/shortcut-catalog.yml`, then asserts every
   public-facing surface against them on each CI run. The prior 12-/13-/14-skill drift is resolved.
---

## Invariants

What a change must never break (each stated as a hard rule + where enforced):

- **Single source of truth:** AID content MUST be edited in `canonical/` only. The `profiles/<tool>/` agent
  trees are generated, and the installed skills, runtime and mirrors are copies of `canonical/` that only
  the CLI writes. Enforced by the `render-drift` CI job (`.github/workflows/test.yml`, search:
  "profiles/ is out of sync with canonical/") and the VERIFY byte-compare gate.
- **Deletion boundary:** the generator wipes only the `profiles/<tool>/` trees it renders, and the CLI
  prunes only files its install manifest records (`.aid/.aid-manifest.json`). Non-`aid-*` entries in
  `.agents/skills/` and in each mirror are never read, written or pruned. The one exception is
  `.aid/runtime/`, which the CLI owns: an unrecorded file there is pruned, except the runtime-local paths
  (`node_modules/` under `.aid/runtime/`). Enforced in `run_generator.py` and `lib/aid-install-core.sh`
  (`prune_shared`).
- **Reviewer tier >= executor tier; writer never grades own work.** Enforced by skill
  dispatch and stated in `docs/aid-methodology.md` (search: "never grades its own work").
- **Human-gated advancement:** the pipeline MUST NOT auto-advance; the human approves every
  phase transition. Enforced by skill state machines (one invocation = one state).
  `docs/aid-methodology.md` (search: "The pipeline never auto-advances").
- **Deterministic grade:** the letter grade MUST be computed by `grade.sh` from bracketed
  severity tags, never hand-picked by the reviewer. Enforced in
  `canonical/aid/scripts/grade.sh` + `canonical/aid/templates/grading-rubric.md`.
- **Forward-authored design is never auto-overwritten:** a greenfield `source: forward-authored`
  KB doc is the design contract; the `/aid-housekeep` Conformance Lane FLAGS code↔design
  divergence for human reconciliation but never rewrites the doc from as-built code (authority
  stays design -> code). Enforced in
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` (search: "flag, never overwrite").
- **Content isolation:** all AID-delivered content MUST be namespaced. Skills are `aid-*` directories under
  `.agents/skills/` and under each declared skill mirror (`.claude/skills/`); the runtime lives under
  `.aid/runtime/`; agent files carry the `aid-` prefix inside each tool's agents directory. Root files are
  updated in place only between `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers: the `AGENTS.md`
  region for every tool (a SESSION START block plus the rules summary; the rules live in `.aid/runtime/rules.md`) and, while Claude Code is installed,
  the `CLAUDE.md` region (the same body plus the `@.aid/runtime/rules.md` import; the inline rules text under `rules_inline`). Enforced by the installer and manifests, by the
  content-isolation checks in `canonical/agents/aid-reviewer/AGENT.md`, and by `tests/canonical/test-multitool-isolation.sh`.
- **Version lockstep:** the single `VERSION` string MUST stay in sync across
  `packages/npm/package.json`, `packages/pypi/pyproject.toml`, and the `aid_version` key in
  `.aid/.aid-manifest.json` (see `VERSION` for the current value; the standalone
  `.aid/.aid-version` marker file is retired). Enforced by
  `canonical/aid/scripts/release/check-version-sync.sh`.
- **Polyglot parity:** behavior implemented in Bash (`lib/aid-install-core.sh`) MUST match
  the PowerShell equivalent (`lib/AidInstallCore.psm1`). Enforced by
  `tests/canonical/test-aid-cli-parity.sh`. The same parity rule binds the dashboard's
  Python/Node reader twins (`dashboard/reader/reader.py` / `dashboard/server/reader.mjs`): both
  parse the `STATE.yml` subset through one structured parse and MUST return field-identical
  payloads, and neither may raise a `parse_warning` a converted work does not warrant. Enforced
  by the shared cross-runtime YAML-subset conformance corpus
  (`dashboard/reader/tests/state_yaml_conformance_corpus.py`, run by both
  `test_state_yaml_conformance.py` and `test_state_yaml_conformance_node.py`) and the
  cross-format characterization suites (`test_task011_golden_master.py`,
  `test_task011_reconcile.py`, `test_flattened_layout_parity.py`).
- **LF + ASCII in shipped scripts:** committed `.sh` files MUST be LF-only; shipped
  PowerShell MUST be ASCII-only (Windows ANSI-codepage mis-parses non-ASCII no-BOM). Enforced
  by the `kb-hygiene` CI job and `tests/canonical/ps51-compat-check.ps1`.

---

## Gotchas

Non-obvious traps a change will trip (cannot be inferred from the code alone):

- **Editing an installed or vendored copy does nothing.** The same file exists in `canonical/`, in the
  release payload, in `profiles/<tool>/` (agents only), in the dogfood installed trees (`.agents/skills/`,
  `.claude/skills/`, `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`) and in `packages/.../_vendor/`.
  Edit `canonical/`, run `run_generator.py` for any agent change, and resync the dogfood install. An edit
  made directly in an installed copy is moved to `.aid/.trash/` by the next `aid update`, and an edit made
  in a profile tree is overwritten by the next generator run and fails CI `render-drift`. CONFIRMED
  `project-structure.md` "Heavy, deliberate file duplication".
- **After any `canonical/` edit, run the FULL `run_generator.py`** — not a per-script
  renderer — or CI render-drift fails on a stale profile tree. (Project memory:
  render-drift-full-generator.)
- **INDEX.md is generated.** Never hand-edit `.aid/knowledge/INDEX.md`; regenerate it with
  `bash .aid/runtime/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`.
  The `canonical/aid/scripts/kb/` copy embeds the same path, so either copy regenerates the same file. The
  KB-hygiene CI check fails when the committed INDEX.md is stale.
- **The 5 install manifests must move in lockstep on the dashboard file set** — npm, pypi,
  and the three vendored copies; dropping one file from one manifest ships a broken install.
- **Worktree root is per host.** No skill names a worktree root. `worktree-lifecycle.sh` reads
  `worktree_root` from `.aid/runtime/host.conf`: `.claude/worktrees/` while Claude Code is installed (its
  worktree tool only switches between worktrees under that folder), otherwise `.aid/.worktrees/`. The
  neutral root is covered by the `.gitignore` managed block.
- **Installed skills and runtime need LF.** The CLI keeps a managed `.gitattributes` block that forces LF on
  `.agents/skills/aid-*/**`, the Claude mirror, `.aid/runtime/**` and every tool's `<root>/agents/aid-*`
  agent files. Without it, a `core.autocrlf=true` checkout turns every
  installed file modified and breaks the `.sh` runtime.
- **Old layouts do not mix.** `aid add` refuses a repo that holds v3 legacy evidence and points to
  `aid update`, which runs a clean-slate upgrade: the old AID paths move to `.aid/.trash/`. A project whose
  manifest is a valid format 3 is a v4 project and has no path evidence: `aid update` keeps its manifest tool
  set, `aid add` accepts it, and any legacy-looking path found there (a retired per-tool AID folder
  restored by a branch switch, or a user's own `aid-*` skill folder under a tool root) is left untouched
  and reported by one warning. A CLI from before
  the shared layout cannot drive the shared layout, so the release notes name the CLI version each release
  requires.
- **`generate-profile` is maintainer-only** and lives only in `.claude/skills/` — do not look
  for it in `canonical/skills/` (the 112 shipped skills).
- **Heavy CI gates run only on `master`** (tests/run-all.sh + the Astro site build); feature
  branches skip them. Run `tests/run-all.sh` (HOME-pinned) + the site build locally before
  claiming green. (Project memory: master-ci-only-on-master.)
