---
kb-category: primary
source: generated
objective: Inventory of what AID does for its users — the methodology capabilities (pipeline phases and on-demand skills) plus the CLI installer and multi-tool distribution.
summary: The catalogue of AID's user-facing capabilities. AID is a methodology delivered as a multi-profile CLI installer, so its "features" are the workflow skills its users invoke, the CLI that installs and maintains it, and the distribution that ships it to five host agent tools. Populated by Discovery; refined during Q&A + FIX.
sources:
  - .claude/skills/
  - CLAUDE.md
  - bin/
  - profiles/
tags: [C9, capabilities, features, inventory, skills, cli]
see_also: [architecture.md, pipeline-contracts.md, module-map.md, integration-map.md]
owner: skill-self
audience: [developer, product]
---

# Capability Inventory

What AID does for the people who use it. AID (AI Integrated Development) is a
full-lifecycle methodology for building software with AI agents, **delivered as a
multi-profile CLI installer**. Its capabilities fall into four groups:

1. The **pipeline skills** — the lifecycle phases a user drives.
2. The **on-demand skills** — optional jobs run outside the linear pipeline.
3. The **CLI installer** — how AID gets onto a repository and stays current.
4. The **multi-tool distribution** — the same capabilities rendered for five host agents.

> Term note: a *skill* is a user-invocable command (e.g. `/aid-discover`); each lives in
> its own directory under the host tool's skills folder. See `domain-glossary.md`.

## Index

- [Pipeline skills (the lifecycle)](#pipeline-skills-the-lifecycle)
- [Requirements-gathering capabilities (deep dive)](#requirements-gathering-capabilities-deep-dive)
- [On-demand skills](#on-demand-skills)
- [CLI installer capabilities](#cli-installer-capabilities)
- [Multi-tool distribution](#multi-tool-distribution)
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
Execute state, and Track/Triage are the optional `/aid-monitor` skill's role.)

| Capability | Skill | What it does for the user |
|------------|-------|---------------------------|
| Configure the pipeline | `/aid-config` | View or set project settings; scaffolds `.aid/settings.yml` and the KB state file. |
| Discover an existing project | `/aid-discover` | Analyzes a repository and builds the Knowledge Base, with a built-in review→Q&A→fix→approval gate. |
| Gather requirements | `/aid-describe` (Phase 2a) | Adaptive one-question-at-a-time interview driven by the seasoned-analyst elicitation engine, producing `REQUIREMENTS.md`; triages full vs. lite path, and (greenfield) forward-authors a KB seed. See [Requirements-gathering capabilities](#requirements-gathering-capabilities-deep-dive) below. |
| Decompose into features | `/aid-define` (Phase 2b) | Decomposes the approved `REQUIREMENTS.md` into discrete feature folders with `SPEC.md` stubs, then cross-references the requirements and feature boundaries against the KB and codebase. |
| Specify a feature | `/aid-specify` | Collaboratively writes a technical `SPEC.md`, one feature at a time. |
| Plan deliveries | `/aid-plan` | Sequences feature specs into deliverables, each a functional MVP building on the last. |
| Break down into tasks | `/aid-detail` | Decomposes deliverables into small, typed, dependency-ordered tasks with an execution graph. |
| Execute a task | `/aid-execute` | Runs a task by type (Implement/Test/Refactor/etc.) with a built-in review→fix loop; one git branch per delivery. |
| Ship a release | `/aid-deploy` | Packages completed deliveries, verifies the combined build, generates release notes. |
| Observe production | `/aid-monitor` | Interprets telemetry, classifies findings, and routes bugs / change requests back into the pipeline. |

> The "Init / Review / Test / Track / Triage" labels are **not numbered phases**: Init is the
> `aid-config` bootstrap; Review (a state) and Test (a task type) run inside `/aid-execute`;
> Track/Triage are the optional `/aid-monitor` skill's classify/route role. The exact
> label→skill mapping is documented in `pipeline-contracts.md`.

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

## On-demand skills

Optional jobs run outside the linear pipeline, when the user needs them.

| Capability | Skill | What it does for the user |
|------------|-------|---------------------------|
| Ask the KB a question | `/aid-query-kb` | Answers a free-form question grounded in the KB, the live code, and in-flight work; cites sources or names the gap. |
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

## Where each capability lives (parts it touches)

Each capability maps to the parts that implement it (full anatomy in `module-map.md`):

| Capability group | Parts / modules it touches |
|------------------|----------------------------|
| Pipeline + on-demand skills | `.claude/skills/<skill>/` (SKILL.md + references) backed by per-area helper scripts under `canonical/aid/scripts/` (`config/`, `kb/`, `execute/`, `release/`, `summarize/`, `interview/`, `housekeep/`); each skill dispatches `canonical/agents/*` sub-agents. See module-map.md "toolkit plane" + per-area script table. |
| Requirements-gathering deep dive | `/aid-describe`'s `references/` engine corpus (`elicitation-engine.md`, `move-playbook.md`, `calibration.md`, `advisor-stance.md`, `coherence-check.md`, `state-describe-seed.md`) + the `aid-housekeep` Conformance Lane. See module-map.md "aid-describe elicitation engine" + "Conformance Lane". |
| CLI installer (install/update/remove) | `bin/` entry point + `lib/aid-install-core.sh`; `install.sh` / `install.ps1`; the 5 install manifests. See module-map.md "distribution plane". |
| Dashboard | `dashboard/server/` (multi-repo server) + `dashboard/reader/` (STATE.md parser). See module-map.md "observation plane". |
| Multi-tool distribution | `canonical/` → `profiles/*` rendered by the `generate-profile` skill (`run_generator.py`) → `packages/npm` + `packages/pypi`. See module-map.md "render plane". |

## What AID does NOT do

- It is not a runtime framework or library you import into an application — it is a
  process methodology plus the tooling that installs and runs it.
- It does not host services or store project data remotely; the dashboard runs locally.

## Open items

- **Skill count.** AID has **14 skills** (the count of directories under
  `canonical/skills/`): 10 pipeline skills + 4 on-demand skills. `README.md`,
  `docs/aid-methodology.md`, and the site docs now state "14 skills" consistently
  (the prior 12-/13-skill drift is resolved).

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-25 | Initial generation during /aid-discover (domain hybrid:methodology-tooling+software-cli). |
| 1.1 | 2026-06-28 | work-001-aid-interview-improvements: split `/aid-interview` into `/aid-describe` (2a) + `/aid-define` (2b); added seasoned-analyst elicitation engine (NFR-7), greenfield forward-authored KB seed, and build-conformance-check capabilities; skill count 13 → 14 (10 pipeline + 4 on-demand). |
| 1.2 | 2026-06-28 | Relabeled Phase 2 from "Interview" to "Describe → Define"; pipeline sequence updated to Describe/Define (2a/2b). |
