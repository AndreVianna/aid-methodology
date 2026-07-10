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
| `SPEC.md` (work-root) | `.aid/{work}/SPEC.md` | The shortcut engine | Lite path only. The work-root technical specification for the single implicit delivery. The full path has no work-root `SPEC.md` — specification happens per feature instead. |
| `SPEC.md` (per-feature) | `.aid/{work}/features/{feature}/SPEC.md` | `aid-specify` | Full-path only. One spec per feature, produced by `aid-specify`. Each feature SPEC is self-contained with its own acceptance criteria and technical decisions. |
| `PLAN.md` | `.aid/{work}/PLAN.md` | `aid-plan` (full path) or the shortcut engine (lite path) | The delivery plan: ordered deliverables (each a functional MVP), feature-to-delivery mapping, and the sequencing rationale. On the lite path there is a single implicit delivery. |
| `BLUEPRINT.md` (delivery definition) | `.aid/{work}/deliveries/{delivery}/BLUEPRINT.md` (full path) or `.aid/{work}/BLUEPRINT.md` (lite path) | `aid-plan` (full path) or the shortcut engine (lite path) | The delivery definition: objective, scope, gate criteria, task list, and dependencies. Full path: one per delivery, nested under `deliveries/delivery-NNN/`. Lite path: the sole delivery's definition, at the work root. |
| `STATE.md` (delivery-area) | `.aid/{work}/deliveries/{delivery}/STATE.md` | `aid-plan` (created) / `aid-execute` (updated) | Full-path only. Delivery lifecycle state and gate criteria for one delivery. On the lite path, the sole delivery's lifecycle and gate are promoted into the work-area `STATE.md` instead. |
| `DETAIL.md` (task definition) | `.aid/{work}/deliveries/{delivery}/tasks/{task}/DETAIL.md` (full path) or `.aid/{work}/tasks/{task}/DETAIL.md` (lite path) | `aid-detail` (full path) or the shortcut engine (lite path) | Individual task definition. Each task has one of the eight types (`RESEARCH`, `DESIGN`, `IMPLEMENT`, `TEST`, `DOCUMENT`, `MIGRATE`, `REFACTOR`, `CONFIGURE`), acceptance criteria, scope, and dependencies. Tasks are the unit of execution for `aid-execute`. |
| `STATE.md` (task-area) | `.aid/{work}/deliveries/{delivery}/tasks/{task}/STATE.md` | `aid-detail` (created) / `aid-execute` (updated) | Full-path only. Task lifecycle state and review history for one task. The lite path has no per-task `STATE.md` — task cells live in the work-root `STATE.md` § `### Tasks lifecycle`. |
| `STATE.md` (work-area) | `.aid/{work}/STATE.md` | all skills | State machine state for the current work item. Records which phase the work is in, what has been completed, and Q&A/review history for re-entrant skill invocations. On the lite path, the sole delivery's gate and Q&A are promoted directly into this file. |
| `IMPEDIMENT-task-NNN.md` | `.aid/{work}/IMPEDIMENT-task-NNN.md` | `aid-execute` (developer agent) | Formal escalation artifact, produced by the Execute phase. Created when implementation reveals a spec contradiction or impossible acceptance criterion. Contains: type, evidence, blocked task, and proposed resolution. Triggers the appropriate feedback loop. |

### Lite-path artifact shape

The lite path (entered via a shortcut such as `/aid-fix` or `/aid-create-api`, or via
`/aid-triage`) flattens the tree above: a single implicit delivery, no `deliveries/` folder,
no `delivery-001/` folder.

```
.aid/
  work-NNN-name/
    STATE.md          # work lifecycle, with the sole delivery's gate + Q&A promoted into it
    REQUIREMENTS.md
    SPEC.md
    PLAN.md
    BLUEPRINT.md       # the single delivery's definition, at the work root
    tasks/
      task-NNN/
        DETAIL.md      # task definition — the flattened path has NO per-task STATE.md;
                       #   each task's cells live in the work-root STATE.md § ### Tasks lifecycle
```

Terminology is unchanged across both paths: **delivery definition = `BLUEPRINT.md`**, **task
definition = `DETAIL.md`**, **feature definition = `SPEC.md`**.

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
| AID manifest | `.aid/.aid-manifest.json` | `aid add` | Records every file installed by `aid add`, the tool version, and checksum-based ownership records for root agent files. Drives `aid update` and `aid remove`. |
| Version file | `.aid/.aid-version` | `aid add` | Human-readable one-line version string — convenience companion to the manifest. |
| `CLAUDE.md` | `CLAUDE.md` (project root) | `aid add claude-code` | Claude Code project-context file. AID's root agent file for the Claude Code host tool. Protected from silent overwrites by the protect-on-diff mechanism. |
| `AGENTS.md` | `AGENTS.md` (project root) | `aid add {codex,cursor,copilot-cli,antigravity}` | Root agent file for Codex, Cursor, Copilot CLI, and Antigravity host tools. |

## Pipeline-scoped delivery artifacts

These artifacts are produced during `aid-execute` delivery branches.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Delivery branch | `aid/{work}-delivery-NNN` (git branch) | `aid-execute` | One git branch per delivery. `aid-execute` creates it, commits implementation work to it, and the delivery is merged when the review loop exits at grade ≥ minimum. |
| Delivery PR | GitHub Pull Request | `aid-operator` | The pull request that merges the delivery branch. `aid-operator` creates it with release notes and links to the tasks it closes. |
