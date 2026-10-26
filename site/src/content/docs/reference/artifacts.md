---
title: Artifacts
description: Every named file the AID methodology produces — what each artifact is, what it contains, and where it lives.
sidebar:
  order: 7
  label: Artifacts
---

AID produces a well-defined set of named artifacts during its pipeline phases. Each artifact has a fixed path convention, a clear owner (the phase/skill that writes it), and a defined consumer (the next phase or skill that reads it).

See [Repository Structure](/reference/repository-structure/) for the layout of the repository itself. See [Knowledge Base doc types](/reference/kb/) for the 14 KB document templates.

## Work-area artifacts

These artifacts live under `.aid/{work-id}/` for each active work item. The **full path**
(entered via `/aid-describe`) nests delivery- and task-level artifacts under
`deliveries/delivery-NNN/`; the **lite path** (entered via a shortcut or `/aid-triage`)
flattens them to the work root — see [Lite-path artifact shape](#lite-path-artifact-shape)
below.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| `REQUIREMENTS.md` | `.aid/{work}/REQUIREMENTS.md` | `aid-describe` (full path) or the shortcut engine (lite path) | Functional and non-functional requirements. Contains user stories, acceptance criteria, constraints, assumptions, and priority rankings. |
| `PLAN.md` | `.aid/{work}/PLAN.md` | `aid-plan` (full path) or the shortcut engine (lite path) | The delivery plan: ordered deliverables (each a functional MVP), feature-to-delivery mapping, and the sequencing rationale. On the lite path there is a single implicit delivery. |
| Feature section | `.aid/{work}/REQUIREMENTS.md` § 11, one `### Feature NNN` per feature | `aid-define` (created) / `aid-specify` (technical specification appended) | The feature definition. A SECTION, not a file: there is no per-feature `SPEC.md` and no `features/` folder. |
| Delivery stanza | `.aid/{work}/PLAN.md`, one `### delivery-NNN` per delivery | `aid-plan` | The delivery definition -- objective, scope, gate criteria, dependencies -- in the document that already orders the deliveries. |
| `STATE.yml` (delivery-area) | `.aid/{work}/deliveries/{delivery}/STATE.yml` | `aid-plan` (created) / `aid-execute` (updated) | Full-path only. Delivery lifecycle state and gate criteria for one delivery. On the lite path, the sole delivery's lifecycle and gate are promoted into the work-area `STATE.md` instead. |
| `DETAIL.md` (task definition) | `.aid/{work}/deliveries/{delivery}/tasks/{task}/DETAIL.md` (full path) or `.aid/{work}/tasks/{task}/DETAIL.md` (lite path) | `aid-detail` (full path) or the shortcut engine (lite path) | Individual task definition. Each task has one of the eight types (`RESEARCH`, `DESIGN`, `IMPLEMENT`, `TEST`, `DOCUMENT`, `MIGRATE`, `REFACTOR`, `CONFIGURE`), acceptance criteria, scope, and dependencies. Tasks are the unit of execution for `aid-execute`. |
| `STATE.yml` (task-area) | `.aid/{work}/deliveries/{delivery}/tasks/{task}/STATE.yml` | `aid-detail` (created) / `aid-execute` (updated) | Full-path only. Task lifecycle state and review history for one task. The lite path has no per-task `STATE.md` — task cells live in the work-root `STATE.md` § `### Tasks lifecycle`. |
| `STATE.yml` (work-area) | `.aid/{work}/STATE.yml` | all skills | State machine state for the current work item. Records which phase the work is in, what has been completed, and Q&A/review history for re-entrant skill invocations. On the lite path, the sole delivery's gate and Q&A are promoted directly into this file. |
| `IMPEDIMENT-task-NNN.md` | `.aid/{work}/IMPEDIMENT-task-NNN.md` | `aid-execute` (developer agent) | Formal escalation artifact, produced by the Execute phase. Created when implementation reveals a spec contradiction or impossible acceptance criterion. Contains: type, evidence, blocked task, and proposed resolution. Triggers the appropriate feedback loop. |

### Lite-path artifact shape

The lite path (entered via a shortcut such as `/aid-fix` or `/aid-create-api`, or via
`/aid-triage`) flattens the tree above: a single implicit delivery, no `deliveries/` folder,
no `delivery-001/` folder.

```
.aid/
  work-NNN-name/
    STATE.yml         # work lifecycle, with the sole delivery's gate + Q&A promoted into it
    REQUIREMENTS.md   # § 11 carries the single feature section
    tasks/
      task-NNN/
        DETAIL.md      # task definition — the flattened path has NO per-task STATE.yml;
                       #   each task's cells live in the work-root STATE.yml `tasks_lifecycle`
```

The Lite path writes exactly TWO artifact types: `REQUIREMENTS.md` and one `DETAIL.md`
per task. There is no `SPEC.md` (the feature's technical specification is a section of
`REQUIREMENTS.md`) and no `PLAN.md` — with one feature and one delivery there is no
sequencing decision to record.

Terminology across both paths: **feature definition = a `REQUIREMENTS.md` § 11 section**,
**delivery definition = a `PLAN.md` `### delivery-NNN` stanza** (full path only), **task
definition = `DETAIL.md`**.

## Knowledge Base artifacts

These artifacts live under `.aid/knowledge/` and represent the living understanding of the project.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| KB documents (14 types) | `.aid/knowledge/{doc-type}.md` | `aid-discover`, `aid-housekeep` | The 14 standard Knowledge Base documents — architecture, coding-standards, domain-glossary, and more. See [KB doc types](/reference/kb/) for the full list. |
| `STATE.md` (knowledge-area) | `.aid/knowledge/STATE.md` | `aid-discover` | Discovery state: Q&A log, approval history, and the last-approved KB snapshot timestamp. Drives re-entrant discovery runs and `aid-housekeep` delta logic. |
| `knowledge-summary.html` | `.aid/knowledge/knowledge-summary.html` | `aid-summarize` | Self-contained HTML summary of the entire Knowledge Base with inlined Mermaid diagrams, light/dark theme, and click-to-expand lightbox. Generated on demand. |

## Generator artifacts (manifests)

These files are committed derived output, outside the content collection root.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Sync manifest | `site/scripts/.synced-manifest.json` | `sync-docs.mjs` | Lists the four doc-migration outputs owned by the sync script. Used by CI drift-check. |
| Reference manifest | `site/scripts/.reference-manifest.json` | `gen-reference.mjs` | Lists the four generated reference pages owned by the reference generator. Used by CI drift-check. |

## Install artifacts

These files are written by the `aid add` command into the target project.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| AID manifest | `.aid/.aid-manifest.json` | `aid add` | Records the top-level `aid_version` (the installed AID release), the shared files (skills, runtime, root regions, mirrors) with their owners and checksums, and each tool's own agent files. Drives `aid update`, `aid status` and `aid remove`. |
| Settings | `.aid/settings.yml` | `aid add` | Project settings. Created when missing. The standalone `.aid/.aid-version` marker file is retired: the installed version is recorded in the manifest. |
| `CLAUDE.md` | `CLAUDE.md` (project root) | `aid add claude-code` | Root instruction file for Claude Code. AID writes one region into it: an `@.aid/runtime/rules.md` import, plus `@.aid/knowledge/PROJECT.md` when the project card exists, so Claude Code loads the AID rules and the card even without `AGENTS.md`. Text outside the AID markers is yours and is kept. |
| `AGENTS.md` | `AGENTS.md` (project root) | `aid add <tool>` (every tool) | Root instruction file for every tool. AID writes one region into it: a SESSION START block that makes a Read of `.aid/runtime/rules.md` the first action, forbids answering before that Read and pre-empts "do not read files" prompts, plus the rules summary lifted from that file. Text outside the AID markers is yours and is kept. |

## Pipeline-scoped delivery artifacts

These artifacts are produced during `aid-execute` delivery branches.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Delivery branch | `aid/{work}-delivery-NNN` (git branch) | `aid-execute` | One git branch per delivery. `aid-execute` creates it, commits implementation work to it, and the delivery is merged when the review loop exits at grade ≥ minimum. |
| Delivery PR | GitHub Pull Request | `aid-operator` | The pull request that merges the delivery branch. `aid-operator` creates it with release notes and links to the tasks it closes. |

## Core Artifacts

| **Artifact** | Location | Produced By | Consumed By | Lifecycle |
|-------------|----------|------------|-------------|-----------|
| Knowledge Base (14 standard docs) | `.aid/knowledge/` | Discover | All phases | Living — updated throughout project |
| INDEX.md | `.aid/knowledge/` | Init, Discover, Describe | All phases | Seeded at init; regenerated by Discovery; maintained by Describe |
| STATE.md (discovery area) | `.aid/knowledge/` | Init, Discover, Summarize | Discover (resume), all phases | Living — grade, review & summarization history; any phase appends Q&A entries |
| project-index.md | `.aid/generated/` | Discover (pre-pass) | Discovery sub-agents | Regenerated each discovery run |
| REQUIREMENTS.md | `.aid/works/{work}/` | Describe (full path) or the shortcut engine's CAPTURE state (lite path) | Specify, Plan / the engine's own SPEC state | Frozen after approval (rev-tracked) |
| STATE.md (work area) | `.aid/works/{work}/` | Describe (full path) or the shortcut engine's INTAKE state (lite path) | All phases for this work | Process tracking |
| Feature section | `REQUIREMENTS.md § 11` | Describe + Specify (full path) | Plan, Detail, Execute | Living — Describe writes the requirements side, Specify adds the technical spec |
| known-issues.md | `.aid/works/{work}/` | Specify (Monitor updates) | Plan, Execute, Deploy, Monitor | Living — created when the first issue is registered |
| PLAN.md | `.aid/works/{work}/` | Plan (full path) or the shortcut engine's PLAN state (lite path) | Detail, Deploy | Living — rev-tracked; Detail appends the execution graph |
| Delivery stanza (delivery definition) | A `### delivery-NNN` section of `PLAN.md` | Plan (full path) or the shortcut engine's PLAN state (lite path) | Detail, Execute | Immutable — objective, scope, gate criteria, task listing, dependencies |
| STATE.md (delivery area) | Full path: `deliveries/delivery-NNN/`; lite path: promoted into the work-root `STATE.md § Delivery Lifecycle` | Plan | Execute | Living — delivery lifecycle, `Pending-Spec` → … → `Done`/`Blocked` |
| DETAIL.md (task definition) | Full path: `deliveries/delivery-NNN/tasks/task-NNN/`; lite path: `.aid/works/{work}/tasks/task-NNN/` | Detail (full path) or the shortcut engine's DETAIL state (lite path) | Execute | Immutable definition; rev-tracked if amended |
| STATE.md (task area) | Full path: `deliveries/delivery-NNN/tasks/task-NNN/`; lite path: rolled into the work-root `STATE.md § Tasks lifecycle` | Detail (seeded); Execute (updated) | Execute (resume), Monitor | Living — full review history for the task |
| IMPEDIMENT-task-NNN.md | `.aid/works/{work}/` | Execute | Specify, Detail, Discovery | Closed when resolved |
| package-NNN-{slug}.md | `.aid/works/{work}/packages/` | Deploy | Monitor, stakeholders | One per shipped release package |
| DEPLOYMENT-STATE.md | `.aid/works/{work}/` | Deploy | Deploy (resume) | Living — operation status + history |
| MONITOR-STATE.md _(deferred)_ | `.aid/works/{work}/` | Monitor | `/aid-fix` (bugs), `/aid-triage` (change requests) | Planned — currently an in-memory observation log across runs |
| KB-DELTA Q&A entry | `.aid/knowledge/STATE.md` | aid-housekeep | aid-discover (targeted re-discovery) | Appended by housekeep; resolved by next targeted discovery run |

Within Execute, the reviewer produces a structured issue list that `canonical/aid/scripts/grade.sh` scores; the issues, the grade, and the full review history are recorded in the task's own `STATE.md` (full path: `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`; lite path: the work-root `STATE.md § Tasks lifecycle` row). There is no separate persistent `REVIEW.md` or `TEST-REPORT.md` file.

## Templates Reference

Each artifact starts from a template in the repository. Open the template to see its exact shape:

- [requirements/requirements-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/requirements/requirements-template.md): the template for `REQUIREMENTS.md`.
- [specs/technical-specification-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/specs/technical-specification-template.md): the template for the Technical Specification body of a feature section.
- [task-detail-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/task-detail-template.md): the template for a task `DETAIL.md`.
- [task-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/task-state-template.yml): the template for a task `STATE.yml`.
- [delivery-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/delivery-state-template.yml): the template for a delivery `STATE.yml`.
- [work-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/work-state-template.yml): the template for a work `STATE.yml`.
- [known-issues.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/known-issues.md): the template for `known-issues.md`.
- [feedback-artifacts/IMPEDIMENT.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/feedback-artifacts/IMPEDIMENT.md): the template for an `IMPEDIMENT-task-NNN.md`.
- [package.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/package.md): the template for a release package.
