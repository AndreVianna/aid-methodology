---
kb-category: primary
source: generated
objective: Inventory of what AID does for its users — the methodology capabilities (pipeline phases and on-demand skills) plus the CLI installer and multi-tool distribution.
summary: The catalogue of AID's user-facing capabilities. AID is a methodology delivered as a multi-profile CLI installer, so its "features" are the workflow skills its users invoke — both the full pipeline and the direct-entry shortcut Lite path — the CLI that installs and maintains it, and the distribution that ships it to five host agent tools. Populated by Discovery; refined during Q&A + FIX.
sources:
  - .claude/skills/
  - CLAUDE.md
  - bin/
  - profiles/
tags: [C9, capabilities, features, inventory, skills, shortcuts, cli]
see_also: [architecture.md, pipeline-contracts.md, module-map.md, integration-map.md]
owner: skill-self
audience: [developer, product]
---

# Capability Inventory

What AID does for the people who use it. AID (AI Integrated Development) is a
full-lifecycle methodology for building software with AI agents, **delivered as a
multi-profile CLI installer**. Its capabilities fall into five groups:

1. The **pipeline skills** — the full-path lifecycle phases a user drives.
2. The **direct-entry shortcut skills** — the fast **Lite path**: name a single, known
   change and one autonomous run carries it from intake to an approval gate. A
   suggest-only router (`/aid-triage`) points the user at the right entry when unsure.
3. The **on-demand skills** — optional jobs run outside the linear pipeline.
4. The **CLI installer** — how AID gets onto a repository and stays current.
5. The **multi-tool distribution** — the same capabilities rendered for five host agents.

> Term note: a *skill* is a user-invocable command (e.g. `/aid-discover`); each lives in
> its own directory under the host tool's skills folder. See `domain-glossary.md`.

## Index

- [Pipeline skills (the lifecycle)](#pipeline-skills-the-lifecycle)
- [Requirements-gathering capabilities (deep dive)](#requirements-gathering-capabilities-deep-dive)
- [Direct-entry shortcuts & the Lite fast path](#direct-entry-shortcuts--the-lite-fast-path)
- [On-demand skills](#on-demand-skills)
- [CLI installer capabilities](#cli-installer-capabilities)
- [Multi-tool distribution](#multi-tool-distribution)
- [External connections & tool integrations (connector catalog)](#external-connections--tool-integrations-connector-catalog)
- [Where each capability lives (parts it touches)](#where-each-capability-lives-parts-it-touches)
- [What AID does NOT do](#what-aid-does-not-do)
- [Open items](#open-items)
- [Change Log](#change-log)

## Pipeline skills (the lifecycle)

AID's pipeline is **six numbered phases** — Discover → Describe/Define (2a/2b) → Specify → Plan →
Detail → Execute. Each phase produces verifiable artifacts and passes a quality gate
before the next begins; the user drives each by invoking its skill. The Describe → Define phase
is realized by **two skills run in sequence**: `/aid-describe` (Phase 2a, gather
requirements) then `/aid-define` (Phase 2b, decompose into features). (Other lifecycle
labels — Init, Implement, Review, Test, Track, Triage — are **not** numbered phases:
Init is the `aid-config` bootstrap, Implement/Test are Execute task types, Review is an
Execute state, Track is the optional `/aid-monitor` skill's role, and Triage is the
standalone `/aid-triage` router skill.)

| Capability | Skill | What it does for the user |
|------------|-------|---------------------------|
| Configure the pipeline | `/aid-config` | View or set project settings; scaffolds `.aid/settings.yml` and the KB state file. |
| Discover an existing project | `/aid-discover` | Analyzes a repository and builds the Knowledge Base, with a built-in review→Q&A→fix→approval gate. Its **ELICIT** state also captures external documentation sources and tool integrations (the connector catalog — see [External connections & tool integrations](#external-connections--tool-integrations-connector-catalog)). |
| Gather requirements | `/aid-describe` (Phase 2a) | Adaptive one-question-at-a-time interview driven by the seasoned-analyst elicitation engine, producing `REQUIREMENTS.md` (the full-path entry only — routing moved to `/aid-triage`), and (greenfield) forward-authors a KB seed. See [Requirements-gathering capabilities](#requirements-gathering-capabilities-deep-dive) below. |
| Decompose into features | `/aid-define` (Phase 2b) | Decomposes the approved `REQUIREMENTS.md` into discrete feature folders with `SPEC.md` stubs, then cross-references the requirements and feature boundaries against the KB and codebase. |
| Specify a feature | `/aid-specify` | Collaboratively writes a technical `SPEC.md`, one feature at a time. |
| Plan deliveries | `/aid-plan` | Sequences feature specs into deliverables, each a functional MVP building on the last. |
| Break down into tasks | `/aid-detail` | Decomposes deliverables into small, typed, dependency-ordered tasks with an execution graph, emitting a `DETAIL.md` per task (the delivery definition is `BLUEPRINT.md`). |
| Execute a task | `/aid-execute` | Runs a task by type (Implement/Test/Refactor/etc.) with a built-in review→fix loop; one git branch per delivery. |
| Ship a release | `/aid-deploy` | Packages completed deliveries, verifies the combined build, generates release notes. |
| Observe production | `/aid-monitor` | Interprets telemetry, classifies findings, and routes them back into the pipeline: bugs to `/aid-fix`, change requests to `/aid-triage`, infrastructure to ops. |

> The "Init / Review / Test / Track / Triage" labels are **not numbered phases**: Init is the
> `aid-config` bootstrap; Review (a state) and Test (a task type) run inside `/aid-execute`;
> Track is the optional `/aid-monitor` skill's classify/route role; and Triage is the
> standalone `/aid-triage` router skill. The exact label→skill mapping is documented in
> `pipeline-contracts.md`.

## Requirements-gathering capabilities (deep dive)

Phase 2a (`/aid-describe`) is more than a scripted question list. Three capabilities
distinguish it; the first two ship inside `/aid-describe`, the third is the downstream
guarantee that `/aid-housekeep` provides for greenfield work.

### Seasoned-analyst elicitation engine (NFR-7)

`/aid-describe`'s interview is driven by a **seasoned-analyst elicitation engine**
(`canonical/skills/aid-describe/references/`): one fixed D1 opener plus a deterministic
five-step next-move selector that chooses the next question each turn, drawing on a
playbook of ten elicitation moves and calibrating to the user's expertise. Every
question is wrapped in the **NFR-7 envelope** — a suggested answer plus its rationale,
with anti-anchoring guards so the suggestion informs without distorting the answer.

| Capability | What it does for the user |
|------------|---------------------------|
| Adaptive next-question selection | A five-step next-move selector (stop check → gap selection → move selection → calibration → NFR-7 envelope + emit) picks the most useful next question instead of a fixed script (`elicitation-engine.md`, `move-playbook.md` "Gap-Type to Move Firing Table"). |
| Expertise calibration | Reads and asks about the user's expertise, then shapes question depth and vocabulary to match (`calibration.md`). |
| Advisory suggested answers (NFR-7) | Every question carries a suggested-answer + rationale envelope and five advisor moves, with anti-anchoring / assumption-flagging guards (`advisor-stance.md` "NFR-7 Question-Envelope Contract"). |
| Coherence checking | Cross-checks the gathered answers for contradictions before handoff (`coherence-check.md`). |

### Greenfield KB seed (forward-authored inversion)

For a greenfield project (no existing KB), `/aid-describe` forward-authors a
**five-element Knowledge Base seed** from the gathered intent — concept-spine
(domain glossary) + architecture + conventions + tech-stack + decisions — each doc
stamped `source: forward-authored` (`canonical/skills/aid-describe/references/state-describe-seed.md`).
This **inverts** the usual relationship: the design docs become the source of truth and
the code is expected to conform to them, instead of the KB being extracted from
existing code.

### Build conformance check (code → design, flag-not-overwrite)

Because a forward-authored seed is design-authoritative, `/aid-housekeep` runs a
**Conformance Lane** (`canonical/skills/aid-housekeep/references/state-kb-delta.md`
"Conformance Lane") over `source: forward-authored` docs: it compares as-built code
against each design doc in the **code → design** direction and **flags any divergence
for human reconciliation — never auto-overwriting the design** with the as-built
reality (the NFR-5 carve). A shadow extraction (via the `output_root` dispatch
parameter in `canonical/skills/aid-discover/references/agent-prompts.md` "Dispatch
Parameter: output_root") produces the as-built view without touching the real KB.

## Direct-entry shortcuts & the Lite fast path

For a single, well-scoped change the user need not walk the whole pipeline. AID ships
**64 verb-first direct-entry "shortcut" skills** (e.g. `/aid-fix`, `/aid-create-api`,
`/aid-change-cli`) plus a suggest-only router, `/aid-triage`. Naming a change with a
shortcut enters the **Lite path**: one fast, mostly-autonomous run that collapses the five
definition phases (Describe → Define → Specify → Plan → Detail) into a single pass, then
halts for approval. It never executes — `/aid-execute` remains a separate, user-initiated
run.

### The shortcut engine

Every shortcut is a thin doorway that binds `{verb, artifact}` and delegates to a shared
engine (`canonical/aid/templates/shortcut-engine.md`), state machine
`INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT`.

| Property | Behavior |
|----------|----------|
| Collapses, never skips | Runs all five definition phases in one pass, collapsing the information capture within each rather than dropping any. |
| Autonomous | CAPTURE/SPEC/PLAN/DETAIL run with no per-phase human checkpoint (unlike the full path's per-phase loops); the only interactive moments are a rare CAPTURE gap-question and the terminal APPROVAL-HALT. |
| Graded | **GATE** mechanically grades every generated document (A+ / project minimum) before halting. |
| Flattened Lite work | Emits the full artifact set at the work root — no `deliveries/` / `delivery-NNN/` nesting; the sole delivery's gate + Q&A are promoted into the work `STATE.md`. |
| Fresh work each run | Each invocation allocates a brand-new `work-NNN`; there is no cross-session resume. |

Family-specific SPEC/PLAN/DETAIL scaffolding lives in
`canonical/aid/templates/shortcut-scaffolding/<family>.md`; the invocation catalog (canonical
names + thin aliases, one row per typed entry) is
`canonical/aid/templates/shortcut-catalog.yml`.

### Shortcut families

The **94-row catalog** (58 canonical names + 36 thin aliases) generates **64** verb-first
thin-doorway shortcut directories via `build-shortcut-skills.py`; the other **30** rows are
`repurpose: true` — hand-authored skills the build helper never generates or overwrites
(`aid-review`/`aid-audit`, `aid-research`/`aid-investigate`/`aid-spike`, `aid-report`,
`aid-prototype`/`aid-prototype-ui`, `aid-design`, the document family, the `aid-test`
run-siblings, plus the re-registered `aid-deploy`, `aid-monitor`, `aid-query-kb`, and `aid-ask`).
Every one of the 94 rows owns its own `canonical/skills/<name>/` directory. Each verb family
targets an artifact archetype:

| Verb family | Shortcuts (canonical) | Alias family |
|-------------|-----------------------|--------------|
| create | `aid-create` + `-api`, `-cli`, `-config`, `-data-model`, `-data-pipeline`, `-infra`, `-integration`, `-job`, `-messaging`, `-theme`, `-ui` | `aid-add-*` mirrors each |
| change | `aid-change` + the same artifact suffixes | `aid-update-*` mirrors each |
| fix | `aid-fix` | — |
| refactor | `aid-refactor` | — |
| remove / deprecate / migrate | `aid-remove`, `aid-deprecate`, `aid-migrate` (v2.1.0 coverage-gap follow-on) | `aid-delete` mirrors `aid-remove` |
| test / experiment | `aid-test`, `-security`, `-performance`, `-data-quality`; `aid-experiment` | — |
| prototype | `aid-prototype`, `aid-prototype-ui` | — |
| document | `aid-document`, `-architecture`, `-changelog`, `-decision`, `-guideline`, `-runbook`, `-standard`, `-tutorial` | — |
| report + dashboard | `aid-report`; `aid-create-dashboard` / `aid-change-dashboard` | `aid-add`/`aid-update`/`aid-show-dashboard` mirror the dashboard pair |
| review / research | `aid-review`, `aid-research` (v2.1.0 coverage-gap follow-on) | `aid-audit` mirrors `aid-review`; `aid-investigate`/`aid-spike` mirror `aid-research` |

(`/aid-deploy`, `/aid-monitor`, `/aid-query-kb`, and `/aid-ask` are now `repurpose` catalog rows —
counted among the 94, each owning its own directory, though hand-authored rather than
engine-generated doorways.)

### The `/aid-triage` router

`/aid-triage` (`canonical/skills/aid-triage/SKILL.md`) is a **stateless, write-free,
suggest-only** router — `INTAKE → CLASSIFY → SUGGEST → HALT`. It captures one free-form
description, infers work-type and scope, then suggests exactly one next step and stops: the
matching canonical shortcut for a known single change, or the full path `/aid-describe` for
anything broad, multi-activity, or ambiguous (the conservative default). It reads
`shortcut-catalog.yml` to resolve to a canonical (non-alias) name; it writes nothing, creates
no work folder, and dispatches no sub-agent. It is the extraction of `/aid-describe`'s former
TRIAGE routing into its own skill; `/aid-monitor` also routes change-request findings to it.

## On-demand skills

Optional jobs run outside the linear pipeline, when the user needs them.

| Capability | Skill | What it does for the user |
|------------|-------|---------------------------|
| Ask the KB a question | `/aid-query-kb` (friendly alias: `/aid-ask`) | Answers a free-form question grounded in the KB, the live code, and in-flight work; cites sources or names the gap. |
| Targeted KB update | `/aid-update-kb` | Applies a described change to the KB through the same review/approval gate as discovery. |
| Housekeeping | `/aid-housekeep` | Re-discovers changed KB docs, runs the conformance check over forward-authored docs, regenerates the visual summary, and sweeps stale work artifacts. |
| Visual KB summary | `/aid-summarize` | Generates a single-file `kb.html` — a visually rich, newcomer-friendly view of the Knowledge Base. |

## CLI installer capabilities

AID installs into a repository as content (skills, agents, scripts, templates) namespaced
under an `aid-` prefix and isolated from user content. The CLI (entry point under `bin/`)
provides:

| Capability | What it does for the user |
|------------|---------------------------|
| Install | Adds AID content to a repository (and a per-machine AID state home). |
| Update | Brings an installed repository up to the current AID version. |
| Remove | Cleans AID content back out. |
| Dashboard | Serves a local web dashboard that reads work-tracking state across repositories. |

Distribution channels: npm (`packages/npm`), PyPI (`packages/pypi`), and a GitHub release
bundle. See `infrastructure.md` for the release and version-sync mechanics.

## Multi-tool distribution

The same capabilities are authored once in `canonical/` and rendered into five host-agent
install profiles, so a user on any of these tools gets the identical methodology:

| Profile | Host agent tool |
|---------|-----------------|
| `claude-code` | Claude Code |
| `codex` | Codex |
| `cursor` | Cursor |
| `copilot-cli` | GitHub Copilot CLI |
| `antigravity` | Antigravity |

The render-and-distribute architecture (canonical → profiles → packages) is described in
`architecture.md`; the build mechanics in `module-map.md`.

## External connections & tool integrations (connector catalog)

AID keeps a **catalog** of the external connections available to a repo's agents — it is a
listing, not a connection manager. It records *what* is reachable and *how to use it*, so an
agent knows which sources and tool integrations exist and how to invoke each. The catalog lives
in `.aid/connectors/` (descriptor files + a generated `INDEX.md` + a git-ignored `.secrets/`),
is populated during `/aid-discover`'s **ELICIT** state, and is reconciled (add / update /
remove) on re-discovery.

Each connection is one of two modes, derived from its `connection_type`:

| Mode | connection_type | Auth & consumption |
|------|-----------------|--------------------|
| tool-managed | `mcp` | The host tool (Claude Code, Codex, Cursor, …) already provides an MCP/plugin for the target; the agent **requests it from the host tool**, which handles auth. AID stores no credential and wires nothing. |
| aid-managed | `api` / `ssh` / `url` / `cli` | A connection the host tool does not provide (e.g. a REST API when no MCP exists). AID records a connect-sufficient descriptor + a **local, git-ignored** credential the agent resolves at use-time via `secret_reference` (`env:` / `file:` / `keychain:`). |

Agents read the catalog via `.aid/connectors/INDEX.md`; the `connector-registry` /
`build-connectors-index` / `connector-secret` script twins under
`canonical/aid/scripts/connectors/` back it. AID does **not** wire host MCP configs (the
MCP-host-wiring delivery was withdrawn).

## Where each capability lives (parts it touches)

Each capability maps to the parts that implement it (full anatomy in `module-map.md`):

| Capability group | Parts / modules it touches |
|------------------|----------------------------|
| Pipeline + on-demand skills | `.claude/skills/<skill>/` (SKILL.md + references) backed by per-area helper scripts under `canonical/aid/scripts/` (`config/`, `connectors/`, `execute/`, `housekeep/`, `kb/`, `migrate/`, `release/`, `summarize/`); each skill dispatches `canonical/agents/*` sub-agents. See module-map.md "toolkit plane" + per-area script table. |
| Requirements-gathering deep dive | `/aid-describe`'s `references/` engine corpus (`elicitation-engine.md`, `move-playbook.md`, `calibration.md`, `advisor-stance.md`, `coherence-check.md`, `state-describe-seed.md`) + the `aid-housekeep` Conformance Lane. See module-map.md "aid-describe elicitation engine" + "Conformance Lane". |
| Direct-entry shortcuts & Lite path | 64 thin `canonical/skills/aid-<verb>[-<artifact>]/SKILL.md` doorways + the `/aid-triage` router, all delegating to `canonical/aid/templates/shortcut-engine.md`; family scaffolding in `canonical/aid/templates/shortcut-scaffolding/<family>.md`; invocation catalog `canonical/aid/templates/shortcut-catalog.yml` (built into skill dirs by `generate-profile/scripts/build-shortcut-skills.py`). |
| External connections & tool integrations | `.aid/connectors/` (descriptors + generated `INDEX.md` + git-ignored `.secrets/`), populated by `/aid-discover` ELICIT; backed by `canonical/aid/scripts/connectors/` (`connector-registry`, `build-connectors-index`, `connector-secret` bash+PowerShell twins) and the `canonical/aid/templates/connectors/preset-catalog.md` presets. See module-map.md "connectors". |
| CLI installer (install/update/remove) | `bin/` entry point + `lib/aid-install-core.sh`; `install.sh` / `install.ps1`; the 5 install manifests. See module-map.md "distribution plane". |
| Dashboard | `dashboard/server/` (multi-repo server) + `dashboard/reader/` (STATE.md parser). See module-map.md "observation plane". |
| Multi-tool distribution | `canonical/` → `profiles/*` rendered by the `generate-profile` skill (`run_generator.py`) → `packages/npm` + `packages/pypi`. See module-map.md "render plane". |

## What AID does NOT do

- It is not a runtime framework or library you import into an application — it is a
  process methodology plus the tooling that installs and runs it.
- It does not host services or store project data remotely; the dashboard runs locally.

## Open items

- **Skill count.** AID ships **108 skill directories** under `canonical/skills/`: **14 curated
  skills** (the pipeline-phase, on-demand, and `/aid-triage` router skills that are *not* in the
  shortcut catalog) plus the **94-row shortcut catalog**'s skills (58 canonical names + 36
  aliases) — **64** engine-generated verb-first direct-entry shortcut doorways plus **30**
  hand-authored `repurpose` skills, each of the 94 owning its own directory. `README.md` states
  this taxonomy; the prior 12-/13-/14-skill drift is superseded.

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-25 | Initial generation during /aid-discover (domain hybrid:methodology-tooling+software-cli). |
| 1.1 | 2026-06-28 | work-001-aid-interview-improvements: split `/aid-interview` into `/aid-describe` (2a) + `/aid-define` (2b); added seasoned-analyst elicitation engine (NFR-7), greenfield forward-authored KB seed, and build-conformance-check capabilities; skill count 13 → 14 (10 pipeline + 4 on-demand). |
| 1.2 | 2026-06-28 | Relabeled Phase 2 from "Interview" to "Describe → Define"; pipeline sequence updated to Describe/Define (2a/2b). |
| 1.3 | 2026-07-09 | work-002 connectors subsystem (PR #133): added the "External connections & tool integrations (connector catalog)" capability, the `connectors/` script area, the connector-catalog capability-lives row, and the `/aid-discover` ELICIT external-source/tool-integration capture. Refreshed by /aid-housekeep KB-DELTA. |
| 1.4 | 2026-07-09 | work-001 lite-skills refresh — added the "Direct-entry shortcuts & the Lite fast path" capability group (67 shortcuts, shortcut engine, families, `shortcut-catalog.yml`) and the `/aid-triage` router; corrected `/aid-describe` to full-path-only (routing moved to `/aid-triage`); re-pointed `/aid-monitor` routing (bug → `/aid-fix`, change request → `/aid-triage`); updated skill count 14 → 82; completed the section index. |
| 1.5 | 2026-07-09 | v2.1.0 coverage-gap follow-on — added the `remove`/`deprecate`/`migrate` (G5, + `aid-delete` alias) and `review`/`research` (G11, + `aid-audit`/`aid-investigate`/`aid-spike` aliases) shortcut families to the families table; restored `/aid-ask` as `/aid-query-kb`'s friendly-named alias; updated counts throughout: skill count 82 → 92 (15 classic incl. `aid-ask` + `/aid-triage` + 76 shortcuts), catalog 69-row (45 canonical + 24 aliases) → 80-row (51 canonical + 29 aliases), repurpose rows 2 → 4 (`aid-deploy`/`aid-monitor`/`aid-query-kb`/`aid-ask`). |
