---
title: 'Glossary'
description: 'This page defines the terms you meet in AID, so you can look up a word you do not know.'
sourceDoc: 'docs/glossary.md'
tableOfContents: { maxHeadingLevel: 2 }
---

This page defines the terms you meet in AID, so you can look up a word you do not know.

## Core Concepts

### AID

(AI Integrated Development.) A way to build and maintain software with AI agents. You and the AI work through numbered phases, from Discover to Execute. Skills run each phase, and you approve the result before the next one starts. Deploy and Monitor are optional paths outside the numbered phases.

### Knowledge Base

(KB.) A set of Markdown documents in `.aid/knowledge/` that records what your project is and how it works. It is the centre of AID, ahead of the spec and the code. You update it as the project changes. You can change the set of documents in `.aid/settings.yml` under `discovery.doc_set`. The standard documents describe architecture, conventions, modules, tests and similar topics. `INDEX.md`, `README.md` and `STATE.md` sit beside them as generated or process files.

### Feedback Loop

A formal way for a later phase to correct an earlier one. It leaves a record: a Q&A entry in a state file, an `IMPEDIMENT` file, or an `aid-monitor` finding.

### Phase Gate

A point between two phases where you decide. You read the output of the phase and approve it before the next phase starts.

### Iron Man Model

How you and the AI share the work. The AI is the suit and amplifies what you can do. You are the pilot, so you set the direction and make the decisions.

## Setup

### aid-config

The skill that shows or changes your AID settings, such as the project name or the minimum grade. Run `/aid-config` to see all settings, or `/aid-config <key>` to view and change one. It writes `.aid/settings.yml`. It is not a numbered phase.

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Knowledge Base Maintenance | The Knowledge Base |
| **Describe → Define** | Definition | Full path: `REQUIREMENTS.md`, with a `### Feature NNN` section per feature under § 11. Lite path (via a shortcut): the single `§ 11` section, written directly. |
| **Specify** | Definition | A technical specification added to each feature's section in `REQUIREMENTS.md § 11` (full path only) |
| **Plan** | Definition | `PLAN.md`: the delivery order, with one `### delivery-NNN` stanza per delivery (full path only) |
| **Detail** | Definition | `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`, the task definition (full path only) |
| **Execute** | Execution | Reviewed, graded work. Each task has a type (IMPLEMENT, TEST, RESEARCH, DESIGN, DOCUMENT, MIGRATE, REFACTOR or CONFIGURE) and goes through a review loop. |

> *Deploy and Monitor are **optional** delivery skills. You run each one on its own, when your project needs it. They are not numbered phases: the numbered sequence ends at Execute.*

## The Lite Path

### Lite Path

A shorter workflow for small, well-scoped work. You enter it by running a verb-first **shortcut**, such as `/aid-fix` or `/aid-create api`. Every shortcut hands over to the shared **shortcut engine**. The engine runs Describe, Define, Specify, Plan and Detail in one fast, mostly autonomous pass. It writes a flat set of files: `REQUIREMENTS.md` and `tasks/task-NNN/DETAIL.md` in the work folder, with no `features/` and no `deliveries/`. Then it stops and waits for your approval before `/aid-execute`.

### workType

A label that `/aid-triage` infers from your description. It is never a menu choice. The three values are `bug-fix`, `new-feature` and `refactor`. Adding a document counts as a `new-feature`, and changing one counts as a `refactor`. The label is a first guess. It only decides which shortcut groups `/aid-triage` checks first, and it is not a route of its own.

## Off-Pipeline Skills

### aid-housekeep

An on-demand skill that re-syncs a drifted Knowledge Base and its summary, and clears stale work artifacts. Run it when the project has drifted. Its states are PREFLIGHT, KB-DELTA, SUMMARY-DELTA, CLEANUP and DONE, with one commit per stage on an `aid/housekeep-*` branch. It is not a numbered phase.

### aid-ask

An on-demand skill that answers a free-form question about your project. It cites the Knowledge Base, the code and any work in flight. When those are not enough, it records the gap as a Query-Gap entry in the Q&A backlog, so the Knowledge Base can improve. Run it from any directory at any phase.

### aid-update-kb

An on-demand skill that applies one change you describe to the Knowledge Base. It works in its own git worktree. It shows you an Impact Map and a minimal Scope Plan, with a list of what it will not change. It edits only after you confirm. It then reviews the changed documents and commits only after a second approval. Its states are ANALYZE, SCOPE, CONFIRM, APPLY, REVIEW, APPROVAL and DONE.

### aid-summarize

An optional skill that builds `kb.html`, a single-file visual tour of the Knowledge Base. Run it after the Knowledge Base is approved. Running it again on an unchanged Knowledge Base does nothing.

## The Shortcut System

### Shortcut

A verb-first entry to AID, such as `/aid-fix`, `/aid-create api` or `/aid-update ui`. Each shortcut is a row of the shortcut catalog (`canonical/aid/templates/shortcut-catalog.yml`). A row is either a skill with its own folder in `canonical/skills/`, or a kind of one. You call a kind by typing its family and then the kind (`/aid-create api`). Some doorways are generated for the shared engine, and the rest are hand-written skills such as `aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`, `aid-deploy` and `aid-monitor`. A shortcut is one of three ways into AID, with `/aid-triage` and `/aid-describe`.

### Design seed

A file `.aid/design/<artifact>.md` that records a direction you have settled before you build it. It holds the problem, the options considered, the current direction, the constraints, the open questions and the destination. The `design` shortcut writes it and nothing else. A `create` shortcut that builds from the seed then deletes it. Later, `update` revises what `create` built.

### Shortcut engine

The shared state machine that every shortcut uses: INTAKE, CAPTURE, SPEC, PLAN, DETAIL, GATE, APPROVAL-HALT. It is defined in `canonical/aid/templates/shortcut-engine.md`. It skips no phase. It gathers the information for each phase in one run, without asking you at every step. You are asked only when a gap matters, and at the final approval. A mechanical GATE grades every generated document before that approval. The engine never executes the work. You start `/aid-execute` yourself after you approve.

### /aid-triage

A router skill that only suggests. Its states are INTAKE, CLASSIFY, SUGGEST and HALT. You give it one free-form description. It infers the `workType`, judges the scope, and names one next step. That step is a specific shortcut for a single, well-scoped change, or `/aid-describe` for anything broad, multi-part or unclear. Then it stops. It writes nothing: no work folder, no state file, no interview.

## Artifacts

### Feature section

(`REQUIREMENTS.md § 11`.) The specification of one feature. It is grounded in the Knowledge Base, and you treat it as a hypothesis that evidence from the build can refine. Each feature is a `### Feature NNN` section under § 11. It names the requirement it implements and the criteria it owns. `aid-specify` adds a `#### Technical Specification` subsection to it. There is no separate `SPEC.md` file.

### Delivery stanza

(`PLAN.md`.) The definition of one delivery: its objective, scope and gate criteria. `aid-plan` writes it as a `### delivery-NNN` stanza in `PLAN.md`. On the Lite path there is no plan, because one delivery needs no sequencing.

### DETAIL.md

The task definition. On the full path it lives at `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`, written by `aid-detail`. On the Lite path it lives at `.aid/works/{work}/tasks/task-NNN/DETAIL.md`, written by the shortcut engine.

### Q&A entry

A question recorded in a state file when a phase finds the Knowledge Base or an earlier artifact lacking. The Knowledge Base keeps its entries in `.aid/knowledge/STATE.md`, under `## Q&A (Pending)`. A work keeps its entries under `qa` in its `STATE.yml`. The phase that owns the question resolves it on its next run.

### STATE file

The record of progress for one area. The Knowledge Base uses `.aid/knowledge/STATE.md`. A work uses `.aid/works/{work}/STATE.yml`. On the full path, each delivery has `deliveries/delivery-NNN/STATE.yml` and each task has `tasks/task-NNN/STATE.yml`. On the Lite path there are no per-delivery or per-task files, so the work's `STATE.yml` holds those cells. State files also hold the Q&A and review history.

### IMPEDIMENT.md

A file written when the build finds that the plan or spec is wrong. It records what was assumed, what is true, the proposed revision and the impact. `/aid-execute` writes it as `IMPEDIMENT-task-NNN.md` in the work folder.

### Grading

The quality scale for reviews, from A+ to F. The grade follows from the issues a reviewer finds. The worst severity decides it, and the number of issues at that severity refines it. A+ means no issues, and F means the work does not build or run. A task must reach the minimum grade you set.

## Groups

| Group | Phases / Skills | Focus |
|-------|-----------------|-------|
| **Support** | aid-config (+ set/unset-connector, read/create/update-ticket) | Bootstrap and configuration |
| **Knowledge Base Maintenance** | Discover (+ Summarize, Housekeep, Update-KB, Ask) | Build and maintain the Knowledge Base |
| **Definition** | Describe → Define, Specify, Plan, Detail (+ Triage, shortcuts, Deploy/Monitor) | Define the problem, plan it, and detail the work |
| **Execution** | Execute | Build, review, and test |

## Install Profiles

AID supports five host AI tools. Each tool gets its own agents folder, and all of them share one set of skills and one runtime:

| Tool | Agents folder | Root instruction files |
|------|---------------|------------------------|
| **Claude Code** | `.claude/agents/` | `AGENTS.md`, and `CLAUDE.md` (imports `AGENTS.md`) |
| **Codex CLI** | `.codex/agents/` | `AGENTS.md` |
| **Cursor** | `.cursor/agents/` | `AGENTS.md` |
| **GitHub Copilot CLI** | `.github/agents/` | `AGENTS.md` |
| **Antigravity** | `.agent/agents/` | `AGENTS.md` |

The five agent folders differ only in model names and file format. The skills and runtime are written once per repo, to `.agents/skills/` and `.aid/runtime/`. The source of truth is `canonical/`; profiles are generated output (never hand-edit them).

## Install and Distribution

### aid CLI

The command you install once per machine. It adds, shows, updates and removes AID in your projects (`aid add`, `aid status`, `aid update`, `aid remove`). Every install channel gives you the same CLI. Only the way it gets onto your PATH differs.

### Bootstrap

The one-time step of putting the `aid` CLI on a machine. You use one of four channels: `curl | bash` (Linux and macOS), `irm | iex` (Windows PowerShell), `npm i -g aid-installer`, or `pipx install aid-installer`.

### Install channel

The method you used to put the `aid` CLI on a machine: the `curl` script, the `irm` script, npm or PyPI. For air-gapped machines you can also install from an offline bundle. The npm and PyPI wrappers record their channel in `AID_INSTALL_CHANNEL`, and `aid update self` prints the matching upgrade command.

### Profile

One tool's rendered agents: the agent files and the `aid-tool.conf` file that `aid add <tool>` places for that tool. There is one profile per tool. The generator builds profiles from `canonical/` into `profiles/<tool>/`. A profile has no skills and no runtime.

### Shared payload

The release artifact that holds the skills and the runtime, the same for every tool. `release.sh` builds it from `canonical/skills/` and `canonical/aid/`. You install it once per repo, whichever tools you add.

### Shared skills

(`.agents/skills/`.) The AID skill folders (`aid-*`), installed once per repo from the shared payload. Claude Code also reads a byte-identical mirror at `.claude/skills/`.

### Runtime

(`.aid/runtime/`.) The scripts, templates and `rules.md` that the skills run against. They are installed once per repo from the shared payload. The `aid` CLI owns this folder and records it in the install manifest.

### AID region

The text between `<!-- AID:BEGIN -->` and `<!-- AID:END -->` in a root instruction file (`AGENTS.md`, `CLAUDE.md`). AID writes only inside it. It never changes text you wrote outside the markers.

### Offline bundle

(`--from-bundle`.) An install mode that reads release artifacts from a local folder instead of fetching them from GitHub. Use it on air-gapped or security-sensitive machines. Run `aid add <tool> --from-bundle <dir>`. The folder holds the shared payload and each tool's artifact. The artifacts and `SHA256SUMS` are on the [GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases).

### Shared layout

The install layout that keeps skills and runtime once per repo, under `.agents/skills/` and `.aid/runtime/`, while each tool keeps only its agents. An older (v3) layout gave each tool its own `aid/` and skill folders. `aid update` upgrades a v3 repo and moves the old files to `.aid/.trash/`.

## Declared Doc-Set

### Declared doc-set

The set of Knowledge Base documents for a project, declared in `.aid/settings.yml` under `discovery.doc_set`. Because the set is declared, skills find documents by convention. An agent that looks for schemas always reads `schemas.md`, and one that looks for tech debt always reads `tech-debt.md`.

## Declared Review Criteria

### Declared review criteria

What a reviewer checks a file against. The criteria are declared, not improvised. They come from three levels, and the reviewer checks all of them together. **Global** and **per-document-type** criteria live in the project's conventions document (`.aid/knowledge/authoring-conventions.md`). **Per-file** exceptions live in the file's own `review-criteria:` frontmatter. When levels conflict, the most specific one wins: file over type over global. You write a criterion once, at the highest level where it is true. Most files declare nothing.

Two things follow. Criteria bind the writer first: an agent resolves them before it edits a file and follows them, so the reviewer is a backstop. And every finding cites the criterion `id` it breaks. A finding that cites nothing, or an `id` that resolves nowhere, is itself a defect.

## Related Terms

### SDD

(Spec-Driven Development.) A method where specifications drive code generation. AID includes SDD as its spec-and-build layer. It adds discovery, two-level planning, feedback loops and post-deployment phases.

### Brownfield

An existing codebase with history, technical debt and knowledge nobody wrote down. The Discover phase is built for brownfield systems.

### Greenfield

A new project with no code yet. A greenfield project skips Discover and starts at Describe.

### Canonical

The `canonical/` directory, the single source for all skill, agent, runtime and template content. The generator (`run_generator.py`) renders the agents in `canonical/` into the five `profiles/` trees, and `release.sh` packages the skills and runtime from it. Never edit `profiles/` directly. Edit `canonical/` and run the generator again.
