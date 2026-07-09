---
kb-category: primary
source: hand-authored
objective: How the AID system is built and why it is shaped this way — its dual product/dogfood anatomy, the canonical→profiles→packages render-and-distribute architecture, and the six-phase gated process architecture (pipeline, skill state machines, agent dispatch).
summary: Read this to understand HOW AID hangs together as both a runnable CLI installer and a process methodology — the boundaries, the source-of-truth flow, the pipeline, and the invariants a change must never break.
sources:
  - docs/aid-methodology.md
  - canonical/
  - profiles/
  - .claude/skills/generate-profile/scripts/run_generator.py
  - canonical/EMISSION-MANIFEST.md
  - README.md
tags: [C1, architecture, pipeline, render-pipeline, state-machine, agent-dispatch, dogfood]
see_also: [project-structure.md, technology-stack.md, decisions.md, module-map.md]
owner: architect
audience: [architect, developer]
intent: |
  How this system is built and why it is shaped this way: the dual product/dogfood
  repository, the canonical→profiles→packages render-and-distribute architecture, and
  the gated process architecture (six-phase pipeline, skill state machines, agent dispatch).
  Read this to understand HOW the system hangs together — not WHAT each module does.
contracts: []
changelog:
  - 2026-07-09: Housekeep KB-DELTA refresh — connectors subsystem + release-drift refresh (added ELICIT as Discover's first state, added `connectors/` to the script-area list, rephrased the Version-lockstep invariant to stop hard-coding a version number, added a connectors-registry boundary note)
  - 2026-06-28: Reconciled Phase 2 to the aid-interview split (aid-describe 2a / aid-define 2b); added the seasoned-analyst elicitation engine, the greenfield forward-authoring inversion, and the build conformance check; skill count 13 -> 14
  - 2026-06-25: Initial discovery (aid-discover — architect deep-dive)
---

# Architecture

> **Source:** aid-discover (Phase 1)
> **Status:** Complete
> **Last Updated:** 2026-07-09

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
- [Change Log](#change-log)

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
agents, templates, recipes) plus the **render/install machinery** that distributes it.

---

## The Two Faces (Product vs Dogfood)

The single most important thing a newcomer must grasp: this repository is **simultaneously
the product's source AND a live AID installation of itself**. This is a SYNTHESIS concept —
no single coined token names it; it is the load-bearing shape of the whole repo.

| Face | Where it lives | What it is |
|------|----------------|-----------|
| **Product** | `canonical/`, `profiles/`, `packages/`, `bin/`, `lib/`, `install.sh`, `install.ps1` | The installable AID toolkit + the CLI that installs it. |
| **Dogfood** | `.claude/` (a rendered claude-code profile) + `.aid/` (pipeline state + this Knowledge Base) | AID *installed into AID* — the maintainers use AID to build AID. |

CONFIRMED. `project-structure.md` (search: "The repo dogfoods itself") and
`docs/aid-methodology.md` describe the dual nature; `.aid/settings.yml` records
`project.type: brownfield`.

**Consequence for any change:** the same logical file frequently exists in many physical
copies — `canonical/` (the source) → five `profiles/` (rendered) → `.claude/` (the dogfood
render) → `packages/npm/` and `packages/pypi/.../_vendor/` (vendored for publish). Editing
a rendered or vendored copy is a defect; edit `canonical/` and re-render. CONFIRMED via
`project-structure.md` (search: "Heavy, deliberate file duplication").

---

## Load-Bearing Boundaries

The boundaries are not class/layer boundaries (this is not an OO app). They are
**source-of-truth boundaries** and **process boundaries**:

| Boundary | Rule | Why it falls here |
|----------|------|-------------------|
| `canonical/` vs `profiles/` | `canonical/` is the only editable source; `profiles/` is generated build output. | One source compiled to five tool dialects keeps the five host tools in lockstep. |
| `profiles/` vs `packages/` | `packages/` vendors `bin/`, `lib/`, `dashboard/` for publication; it does not author logic. | Publication channels (npm/PyPI) wrap, never fork, the engine. |
| Product (`canonical/`,`bin/`,`lib/`) vs Dogfood (`.aid/`,`.claude/`) | Dogfood state is real working state, never product source. | The repo eats its own cooking without contaminating the shipped artifact. |
| Executor agent vs Reviewer agent | The agent that writes never grades its own work; reviewer tier >= executor tier. | Adversarial separation is the quality mechanism (see Agent Dispatch). |
| `.aid/knowledge/` (KB) vs `.aid/work-NNN-*/` (works) | The KB is shared, cross-work, living; a work is one scoped unit. | One KB, many works — institutional memory outlives any single work. |
| `.aid/connectors/` (registry) vs host-tool config | The connectors registry is a CATALOG — it lists the connections available to a repo's agents and how to use them; it is not a connection manager and does not wire any host tool's config. | Host tools (Claude Code, Codex, Cursor, …) already own their own MCP servers and auth for what they provide; AID records only what it itself manages. |

CONFIRMED. The canonical/profiles rule is stated in `docs/aid-methodology.md` (search:
"single source of truth — never edit profiles/ directly"); the reviewer/executor rule in
`docs/aid-methodology.md` (search: "the agent that writes never grades its own work"); the
connectors catalog model in `canonical/skills/aid-discover/references/state-elicit.md` (search:
"Q10: AID writes, wires, and manages no host tool's MCP configuration") and
`canonical/aid/templates/connectors/preset-catalog.md` (search: "Management mode").

---

## Build & Distribute Architecture (canonical -> profiles -> packages)

This is the architecture that makes AID a *product*. It is a SYNTHESIS concept — a
"render-and-vendor compile pipeline" — spread across several files with no single token.

**The flow:**

1. `canonical/` holds the single source: `skills/` (14), `agents/` (9),
   `aid/{scripts,templates,recipes}`. CONFIRMED via directory listing.
2. `python .claude/skills/generate-profile/scripts/run_generator.py` renders the source
   into the five `profiles/*` install trees, one per `profiles/*.toml`. CONFIRMED in
   `run_generator.py` (search: "render all profiles from canonical, then verify").
3. Each render is bounded by a per-profile **emission manifest**
   (`<profile>/emission-manifest.jsonl`) — a JSONL list of every emitted file with its
   sha256. The diff of the previous vs current manifest is the *only* set of paths the
   generator may delete (pure-mirror deletion). CONFIRMED in `canonical/EMISSION-MANIFEST.md`
   (search: "authoritative safety boundary").
4. A **VERIFY (deterministic)** gate re-renders into scratch and byte-compares against the
   committed trees; any mismatch is a hard failure. CONFIRMED in `run_generator.py`
   (search: "VERIFY (deterministic): PASS") and `docs/aid-methodology.md` (search: "A
   VERIFY (deterministic) gate re-renders all five profiles").
5. CI enforces the boundary: the `render-drift` job re-runs the generator and fails if
   `profiles/` has uncommitted drift. CONFIRMED in `.github/workflows/test.yml` (search:
   "profiles/ is out of sync with canonical/").
6. `packages/npm/` and `packages/pypi/` vendor `bin/`, `lib/`, `dashboard/` (via
   `scripts/vendor.js` / `scripts/vendor.py`) and publish the same `aid` CLI. CONFIRMED in
   `packages/npm/package.json` (search: "prepack") and `packages/pypi/pyproject.toml`
   (search: "tool.hatch.build.hooks.custom").

**Render output shape** (per `canonical/EMISSION-MANIFEST.md`, "Asset Kinds"):

| Canonical source | Rendered destination (per profile root) |
|------------------|-----------------------------------------|
| `canonical/agents/<a>/AGENT.md` | `<root>/agents/aid-<a>.md` (markdown) OR `<root>/agents/*.toml` (Codex) |
| `canonical/skills/` | `<root>/skills/` |
| `canonical/aid/scripts/` | `<root>/aid/scripts/` |
| `canonical/aid/templates/` | `<root>/aid/templates/` |
| `canonical/aid/recipes/` | `<root>/aid/recipes/` (passthrough markdown) |

The five profile roots: `.claude/` (Claude Code), `.codex/` (Codex), `.cursor/` (Cursor),
`.github/` (Copilot CLI), `.agent/` (Antigravity). CONFIRMED in `docs/aid-methodology.md`
(search: "The Five Profiles") and `profiles/*.toml`.

**Note:** the generator/`generate-profile` skill is **maintainer-only** — it lives in
`.claude/skills/generate-profile/` and is NOT one of the 14 shipped user-facing skills in
`canonical/skills/`. CONFIRMED: `canonical/skills/` contains 14 dirs, none named
`generate-profile`.

---

## Process Architecture: The Six-Phase Pipeline

AID's other architecture is a **process**: a linear, human-gated pipeline of phases with
formal feedback loops. The pipeline is the methodology's backbone.

**The six numbered phases** (CONFIRMED in `docs/aid-methodology.md` §1 "The Pipeline" and
its "Skill Inventory" table):

```
Discover -> Describe/Define (2a/2b) -> Specify -> Plan -> Detail -> Execute
```

These six map onto skills (Phase 1-6) and sit inside **five skill groups** (Prepare,
Define, Map, Execute, Deliver). Phase 2 (Describe → Define) is realized by **two** skills —
`aid-describe` (2a) and `aid-define` (2b) — after the `aid-interview` split (see "The
Describe → Define Phase" below); every other numbered phase is one skill. Several lifecycle labels
from everyday SDLC talk — Init, Implement, Review, Test, Track, Triage — are **not numbered
phases**; the table below maps each label to what it really is (CONFIRMED in
`docs/aid-methodology.md` "Skill Inventory" and the `canonical/skills/` listing — 14
user-facing skills):

| Workflow label | Skill(s) | Numbered phase? | What it really is |
|----------------|----------|-----------------|-------------------|
| Discover | `aid-discover` | **Phase 1** | Brownfield only; builds the KB. (`aid-summarize` is an optional viewer here.) |
| Describe | `aid-describe` | **Phase 2a** | Describe (2a) half: TRIAGE (routes full vs lite) + adaptive interview + COMPLETION + lite path + greenfield KB seed. Driven by the seasoned-analyst engine; the `aid-interviewer` AGENT (unchanged) does the dialogue. |
| Define | `aid-define` | **Phase 2b** | Decomposition half: feature decomposition + cross-reference (full path only); hands off to Specify. |
| Specify | `aid-specify` | **Phase 3** | Full path only. |
| Plan | `aid-plan` | **Phase 4** | Full path only. |
| Detail | `aid-detail` | **Phase 5** | Full path only. |
| Execute | `aid-execute` | **Phase 6** | 8 task types; graded review loop. |
| Init | `aid-config` | No (bootstrap) | Run once; scaffolds `.aid/` + KB placeholders. |
| Implement | `aid-execute` | No | One of Execute's 8 task types (IMPLEMENT), not a phase. |
| Review | (inside `aid-execute`) | No | A state of the Execute loop (EXECUTE -> REVIEW -> FIX -> DONE), not a phase. |
| Test | `aid-execute` | No | A task type (TEST) inside Execute, not a phase. |
| Deploy | `aid-deploy` | No (optional Deliver) | On-demand Deliver-group skill; not a numbered phase. |
| Track / Monitor | `aid-monitor` | No (optional Deliver) | On-demand observe -> classify -> route; not a numbered phase. ("Track" has no separate referent.) |
| Triage | `aid-describe` TRIAGE state; `aid-monitor` classify | No | A routing state, not a separate phase or skill. |

Off-pipeline / on-demand skills: `aid-housekeep` (KB drift reconciliation),
`aid-query-kb` (Q&A + gap capture), `aid-update-kb` (targeted KB delta), `aid-summarize`
(HTML KB viewer). CONFIRMED in `docs/aid-methodology.md` "Skill Inventory".

**Two paths through the pipeline** (CONFIRMED in `docs/aid-methodology.md` §4 "TRIAGE
Routing"):

- **Full path** — Discover -> Describe (2a) -> Define (2b) -> Specify -> Plan -> Detail ->
  Execute. For broad, multi-target, or ambiguous work.
- **Lite path** — Describe lite (CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW) ->
  Execute. Skips Define/Specify/Plan/Detail. The default for small, single-target work. A
  lite work can escalate to full mid-flight (`Path: escalated`).

**Eleven formal feedback loops** let any phase revise an upstream artifact (8 within
development, 2 from production, 1 cross-cutting). CONFIRMED in `docs/aid-methodology.md` §6
"The Eleven Loops". The cross-cutting Loop 11 (Any phase -> Discover, targeted
re-discovery) is what makes the KB the gravitational center in practice.

### Phase 2 (Describe → Define): Describe (2a) + Define (2b)

Phase 2 (Describe → Define) is realized by **two chained skills**, not one. The former
`aid-interview` SKILL was split; the `aid-interviewer` AGENT keeps its name (only the skill
split). CONFIRMED: `canonical/skills/` has `aid-describe/` and `aid-define/` and no
`aid-interview/`; `canonical/agents/aid-interviewer/` is unchanged.

- **`aid-describe` (Phase 2a)** — TRIAGE + adaptive interview + COMPLETION, the lite path, and
  (greenfield) the KB seed. State machine: FIRST-RUN -> Q-AND-A -> TRIAGE ->
  {full: CONTINUE -> [greenfield: DESCRIBE-SEED ->] COMPLETION (pauses -> `/aid-define`) |
  lite: CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW -> LITE-DONE}. CONFIRMED in
  `canonical/skills/aid-describe/SKILL.md` (frontmatter `State machine:` + the Dispatch table).
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
  CONFIRMED via `.claude/aid/templates/state-machine-chaining.md`.
- Trivial state/arg work is done in SKILL.md prose, not bash. Only non-trivial,
  reused, deterministic operations are extracted to `canonical/aid/scripts/` (grouped by
  phase: `kb/`, `execute/`, `interview/`, `housekeep/`, `connectors/`, `summarize/`, `release/`,
  `migrate/`, `config/`). CONFIRMED via the `canonical/aid/scripts/` subtree.

---

## Agent / Sub-Agent Dispatch Model

A skill (driven by the host tool) dispatches **specialist sub-agents** to do the work. AID
defines **9 agents across 3 model tiers**. CONFIRMED: `canonical/agents/` holds exactly 9
(aid-architect, aid-clerk, aid-developer, aid-interviewer, aid-operator, aid-orchestrator,
aid-researcher, aid-reviewer, aid-tech-writer) and `docs/aid-methodology.md` §5.

| Tier | Agents | Role |
|------|--------|------|
| Large (4) | aid-interviewer, aid-architect, aid-researcher, aid-reviewer | Highest-stakes judgment: requirements, architecture, KB authoring, adversarial review. |
| Medium (4) | aid-developer, aid-operator, aid-orchestrator, aid-tech-writer | Production workhorses: implement, release, route, document. |
| Small (1) | aid-clerk | Mechanical extract/format/glob. |

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
  -> run_generator.py  (render per profiles/*.toml)
  -> profiles/<tool>/  (+ emission-manifest.jsonl per profile)
  -> VERIFY (deterministic) byte-compare gate
  -> packages/{npm,pypi} vendor + publish
```
CONFIRMED in `run_generator.py` and `docs/aid-methodology.md` "The build pipeline".

**2. Install flow (get AID into a user repo):**
```
curl|bash install.sh  (or irm|iex install.ps1, or npm i -g, or pipx install)
  -> bootstraps the persistent `aid` CLI (~/.aid or %LOCALAPPDATA%\aid)
  -> `aid add <tool>` in a repo
  -> lib/aid-install-core.sh copies the rendered profile into .claude/ | .codex/ | .cursor/ | .github/ | .agent/
  -> writes/updates the root context file (CLAUDE.md or AGENTS.md, in-place between AID:BEGIN/END markers)
```
CONFIRMED in `README.md` "Install" and `docs/aid-methodology.md` §10.

**3. Pipeline flow (use AID on a project):**
```
/aid-config -> /aid-discover -> KB in .aid/knowledge/
  -> /aid-describe (TRIAGE) -> work in .aid/work-NNN-*/
  -> [full] /aid-define -> /aid-specify -> /aid-plan -> /aid-detail -> /aid-execute
  -> [lite] /aid-execute
  -> optional /aid-deploy -> /aid-monitor
  (any phase -> Q&A entry in a STATE.md -> targeted re-discovery)
```
CONFIRMED in `README.md` "Quick Start" and `docs/aid-methodology.md` §4.

---

## Entry Points

CONFIRMED in `project-structure.md` "Entry Points" and file headers:

1. Installer bootstrap — `install.sh` / `install.ps1`.
2. The CLI — `bin/aid` (Bash) / `bin/aid.ps1` + `bin/aid.cmd` (Windows).
3. Package wrappers — `packages/npm/bin/` and `packages/pypi/aid_installer/__main__.py`.
4. User-facing skills — `/aid-*` slash commands resolving to installed `SKILL.md` files.
5. Dashboard servers — `dashboard/server/server.mjs` (Node) / `dashboard/server/server.py`.
6. The maintainer build — `run_generator.py`; the release runbook — `release.sh`.
7. The website — `site/` (independent Astro build).

---

## Doc-vs-Code Discrepancies

Documented as reality + flagged; NOT silently reconciled (see `.scout-questions.tmp`):

1. **Skill count (reconciled).** `canonical/skills/` has **14** directories (the `aid-interview`
   skill was split into `aid-describe` + `aid-define`); `README.md`, `docs/aid-methodology.md`,
   and the site docs now consistently say "14 skills" -- the prior 12-/13-skill drift is resolved.
2. **Recipe count/path.** `docs/aid-methodology.md` and `docs/repository-structure.md` say
   "51 recipes" at `canonical/recipes/`; reality is **52** files at `canonical/aid/recipes/`
   (note the `aid/` segment). Logged as Q2 / Q5.
3. **EMISSION-MANIFEST.md lists 3 profiles, reality is 5.** `canonical/EMISSION-MANIFEST.md`
   tables enumerate only claude-code/codex/cursor; the live generator globs all five
   `profiles/*.toml` (copilot-cli and antigravity were added later). The doc predates two
   profiles. Logged as Q6. UNCERTAIN whether the design spec should be refreshed (a
   tech-writer task, out of scope for discovery).

---

## Invariants

What a change must never break (each stated as a hard rule + where enforced):

- **Single source of truth:** AID content MUST be edited in `canonical/` only; `profiles/`
  is generated. Enforced by the `render-drift` CI job (`.github/workflows/test.yml`, search:
  "profiles/ is out of sync with canonical/") and the VERIFY byte-compare gate.
- **Pure-mirror deletion boundary:** the generator MUST delete only paths present in the
  previous emission manifest but absent from the current one; files outside any manifest are
  never touched. Enforced in `run_generator.py` + `canonical/EMISSION-MANIFEST.md` (search:
  "Files outside any manifest").
- **Reviewer tier >= executor tier; writer never grades own work.** Enforced by skill
  dispatch and stated in `docs/aid-methodology.md` (search: "never grades its own work").
- **Human-gated advancement:** the pipeline MUST NOT auto-advance; the human approves every
  phase transition. Enforced by skill state machines (one invocation = one state).
  `docs/aid-methodology.md` (search: "The pipeline never auto-advances").
- **Deterministic grade:** the letter grade MUST be computed by `grade.sh` from bracketed
  severity tags, never hand-picked by the reviewer. Enforced in
  `.claude/aid/scripts/grade.sh` + `.claude/aid/templates/grading-rubric.md`.
- **Forward-authored design is never auto-overwritten:** a greenfield `source: forward-authored`
  KB doc is the design contract; the `/aid-housekeep` Conformance Lane FLAGS code↔design
  divergence for human reconciliation but never rewrites the doc from as-built code (authority
  stays design -> code). Enforced in
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` (search: "flag, never overwrite").
- **Content isolation:** all AID-delivered content MUST be namespaced (skills/agents carry
  the `aid-` prefix; scripts/templates/recipes live under an `aid/` subtree); root context
  files are updated in-place only between `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers.
  Enforced by the installer + manifests. `README.md` (search: "Content isolation").
- **Version lockstep:** the single `VERSION` string MUST stay in sync across
  `packages/npm/package.json`, `packages/pypi/pyproject.toml`, and `.aid/.aid-version` (see
  `VERSION` for the current value). Enforced by
  `.claude/aid/scripts/release/check-version-sync.sh`.
- **Polyglot parity:** behavior implemented in Bash (`lib/aid-install-core.sh`) MUST match
  the PowerShell equivalent (`lib/AidInstallCore.psm1`). Enforced by
  `tests/canonical/test-aid-cli-parity.sh`.
- **LF + ASCII in shipped scripts:** committed `.sh` files MUST be LF-only; shipped
  PowerShell MUST be ASCII-only (Windows ANSI-codepage mis-parses non-ASCII no-BOM). Enforced
  by the `kb-hygiene` CI job and `tests/canonical/ps51-compat-check.ps1`.

---

## Gotchas

Non-obvious traps a change will trip (cannot be inferred from the code alone):

- **Editing a rendered/vendored copy does nothing.** The same file exists in `canonical/`,
  five `profiles/`, `.claude/`, and both `packages/.../_vendor/`. Edit `canonical/` then run
  `run_generator.py`; otherwise CI `render-drift` fails or your change is silently
  overwritten on next render. CONFIRMED `project-structure.md` "Heavy, deliberate file
  duplication".
- **After any `canonical/` edit, run the FULL `run_generator.py`** — not a per-script
  renderer — or CI render-drift fails on stale emission manifests. (Project memory:
  render-drift-full-generator.)
- **INDEX.md is generated.** Never hand-edit `.aid/knowledge/INDEX.md`; regenerate via
  `canonical/aid/scripts/kb/build-kb-index.sh` (not the `.claude/` copy) or the KB-hygiene CI
  check fails on the embedded script path.
- **The 5 install manifests must move in lockstep on the dashboard file set** — npm, pypi,
  and the three vendored copies; dropping one file from one manifest ships a broken install.
- **`generate-profile` is maintainer-only** and lives only in `.claude/skills/` — do not look
  for it in `canonical/skills/` (the 14 shipped skills).
- **Heavy CI gates run only on `master`** (tests/run-all.sh + the Astro site build); feature
  branches skip them. Run `tests/run-all.sh` (HOME-pinned) + the site build locally before
  claiming green. (Project memory: master-ci-only-on-master.)

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial discovery — product/dogfood anatomy, render-and-distribute architecture, six-phase process architecture, skill/agent dispatch, invariants, gotchas. |
| 1.1 | 2026-06-26 | manual | Corrected the process-architecture model: six numbered phases (Discover→Execute), not "12 phases". Init/Implement/Review/Test/Track/Triage reframed as bootstrap / task-types / states / optional Deliver skills, not phases. |
| 1.2 | 2026-06-28 | manual | Reconciled the Interview phase to the `aid-interview` split: Phase 2a `aid-describe` (triage + interview + lite + greenfield seed) / Phase 2b `aid-define` (feature decomposition + cross-reference). Added the seasoned-analyst elicitation engine, the greenfield forward-authoring inversion, and the build conformance check. Skill count 13 -> 14. |
| 1.3 | 2026-06-28 | tech-writer | Relabeled Phase 2 from "Interview" to "Describe → Define" throughout; section heading renamed to "Phase 2 (Describe → Define)"; pipeline sequence updated to Describe/Define (2a/2b). |
| 1.4 | 2026-07-09 | tech-writer | Housekeep KB-DELTA refresh: connectors subsystem + release-drift refresh — added ELICIT as Discover's first state, added `connectors/` to the script-area list, rephrased the Version-lockstep invariant to stop hard-coding a version number, and added a connectors-registry boundary row (catalog model, not a connection manager). |
