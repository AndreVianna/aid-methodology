---
title: Artifacts
description: This page lists the named files AID produces, what each one is, and where it lives, so you can find any of them quickly.
sidebar:
  order: 7
  label: Artifacts
---

This page lists the named files AID produces, what each one is, and where it lives, so you can find any of them quickly.

Each artifact has a path, a writer (a skill, an agent, a command, a script, or you) and a purpose. To see how the pieces fit together, read [the pipeline](/concepts/pipeline/). For the layout of the repository itself, see [Repository Structure](/reference/repository-structure/). For the [Knowledge Base](/reference/glossary/#knowledge-base) document types, see [Knowledge Base documents](/reference/kb/).

## Work artifacts

These artifacts live under `.aid/works/{work}/`, one folder for each work item. The full path nests delivery and task artifacts under `deliveries/delivery-NNN/`. The [Lite path](/reference/glossary/#lite-path) flattens them to the work root. See [Lite-path artifact shape](#lite-path-artifact-shape) below.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| `REQUIREMENTS.md` | `.aid/works/{work}/REQUIREMENTS.md` | `aid-describe` (full path) or the [shortcut engine](/reference/glossary/#shortcut-engine) (Lite path) | The requirements document. It holds the objective, problem statement, users, scope, functional and non-functional requirements, constraints, assumptions, acceptance criteria and priorities. Section 11 holds the features. |
| [Feature section](/reference/glossary/#feature-section) | `.aid/works/{work}/REQUIREMENTS.md`, section 11, one `### Feature NNN` for each feature | `aid-define` creates it, `aid-specify` adds the technical specification | The definition of one feature. It is a section of `REQUIREMENTS.md`, not a file of its own. |
| `PLAN.md` | `.aid/works/{work}/PLAN.md` | `aid-plan` (full path) | The delivery plan. It holds the ordered deliveries and the execution graph. The Lite path writes no `PLAN.md`. |
| [Delivery stanza](/reference/glossary/#delivery-stanza) | `.aid/works/{work}/PLAN.md`, one `### delivery-NNN` for each delivery | `aid-plan` | The definition of one delivery: its objective, scope and gate criteria. |
| [`DETAIL.md`](/reference/glossary/#detailmd) | Full path: `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`. Lite path: `.aid/works/{work}/tasks/task-NNN/DETAIL.md` | `aid-detail` (full path) or the shortcut engine (Lite path) | The definition of one task. A task has one type: `RESEARCH`, `DESIGN`, `IMPLEMENT`, `TEST`, `DOCUMENT`, `MIGRATE`, `REFACTOR` or `CONFIGURE`. It also has a source, acceptance criteria, scope and dependencies. `aid-execute` runs tasks. |
| [`STATE.yml`](/reference/glossary/#state-file) (work) | `.aid/works/{work}/STATE.yml` | `aid-describe` or the shortcut engine creates it, and later skills update it | The state of the work: its pipeline identity, lifecycle, phase and approval, and the interview and feature cells. On the Lite path it also holds the delivery lifecycle, the delivery gate, the task cells and the question-and-answer entries. |
| `STATE.yml` (delivery) | `.aid/works/{work}/deliveries/delivery-NNN/STATE.yml` | `aid-plan` creates it, `aid-specify` and `aid-execute` update it | Full path only. The delivery lifecycle, from `Pending-Spec` through `Done` or `Blocked`, plus the gate result and the delivery's own question-and-answer entries. |
| `STATE.yml` (task) | `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/STATE.yml` | `aid-detail` creates it, `aid-execute` updates it | Full path only. The task `state`, its `review` result, the quick-check findings and the dispatch log. |
| `delivery-NNN-issues.md` | `.aid/works/{work}/delivery-NNN-issues.md` | `aid-execute`, in the delivery gate | The `[HIGH]` findings that task quick checks deferred to the gate. The gate reviewer reads it, and after the gate passes its rows are marked `Resolved` or `Accepted`. |
| `IMPEDIMENT-task-NNN.md` | `.aid/works/{work}/IMPEDIMENT-task-NNN.md` | `aid-execute` | Written when the executor meets something it cannot resolve. It records the type (`wrong-assumption`, `missing-dependency`, `architecture-conflict` or `kb-gap`), a description, the options and a recommendation. See [feedback loops](/concepts/feedback-loops/) for how each type is routed. |
| `known-issues.md` | `.aid/works/{work}/known-issues.md` | `aid-specify`, when it registers the first issue | Problems found in code that a feature touches. `aid-plan`, `aid-execute`, `aid-deploy` and `aid-monitor` read it. |

### Lite-path artifact shape

You enter the Lite path with a shortcut such as `/aid-fix` or `/aid-create api`, and `/aid-triage` can suggest one. It has a single implicit delivery, so there is no `deliveries/` folder.

```
.aid/
  works/
    work-NNN-name/
      STATE.yml         # work state, with the delivery lifecycle, gate and task cells in it
      REQUIREMENTS.md   # section 11 holds the single feature section
      tasks/
        task-NNN/
          DETAIL.md     # task definition; there is no per-task STATE.yml
```

The shortcut engine writes `REQUIREMENTS.md` and one `DETAIL.md` for each task, and it keeps their state in `STATE.yml`. It writes no `PLAN.md`: one delivery leaves no sequencing to record. The feature's technical specification is a section of `REQUIREMENTS.md`.

Across both paths, a feature definition is a section of `REQUIREMENTS.md`, a delivery definition is a `### delivery-NNN` stanza of `PLAN.md` (full path only), and a task definition is a `DETAIL.md`.

### Review results

During `aid-execute`, the reviewer lists its findings in a ledger under `.aid/.temp/review-pending/`, and `canonical/aid/scripts/grade.sh` scores that ledger. The task's `STATE.yml` records the `state` and `review` result. On the Lite path, the same cells sit in the work `STATE.yml`, in the `tasks_lifecycle` entry for the task.

## Knowledge Base artifacts

These artifacts live under `.aid/knowledge/`. They hold the living understanding of the project. See [the Knowledge Base](/concepts/knowledge-base/) for how they are built and used.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Knowledge Base documents | `.aid/knowledge/{document}.md` | `aid-discover`, `aid-update-kb`, `aid-housekeep` | The documents that describe your project. See [Knowledge Base documents](/reference/kb/) for the standard types. |
| `PROJECT.md` | `.aid/knowledge/PROJECT.md` | You write it, from the project card template | The optional one-page project card. When it exists, it is read first. |
| `README.md` and `INDEX.md` | `.aid/knowledge/README.md`, `.aid/knowledge/INDEX.md` | `aid-discover` regenerates them, `aid-describe` refreshes them | The completeness overview and the index of summaries. Open `INDEX.md` to find a document. |
| `STATE.md` (Knowledge Base) | `.aid/knowledge/STATE.md` | `aid-discover` creates it from the template, and `aid-discover` and `aid-summarize` update it | Discovery state: the question-and-answer log, the review history and the summarization history. |
| KB-DELTA question entry | `.aid/knowledge/STATE.md`, under `## Q&A (Pending)` | `aid-housekeep` | An entry that `aid-housekeep` appends when it finds a Knowledge Base gap. A targeted `/aid-discover` run resolves it. |
| `kb.html` | `.aid/knowledge/kb.html` | `aid-summarize` | A single self-contained HTML tour of the Knowledge Base. |
| `project-index.md` | `.aid/generated/project-index.md` | `aid-discover` (pre-pass) | The file inventory that the discovery sub-agents read. It sits outside the Knowledge Base. |

## Delivery and release artifacts

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Delivery branch | `aid/{work}-delivery-NNN` (git branch) | `aid-execute` | One git branch for each delivery. `aid-execute` creates it, and the delivery's tasks commit to it. |
| Release package | `.aid/works/{work}/packages/package-NNN-{name}.md` | `aid-deploy` | One file for each release package. |
| Deploy record | The `deploy` entries of `.aid/works/{work}/STATE.yml` | `aid-deploy` | One entry for each delivery: its state, pull request, whether the Knowledge Base was updated, tag and notes. |
| Pull request | A pull request on your git host | `aid-deploy` (the `aid-operator` agent), when the release is pull-request based | The pull request that carries the release, with a structured description. |

`aid-monitor` has no state file of its own. It keeps its findings in the context of the run.

## Generator artifacts (manifests)

These files are committed derived output, outside the content collection root.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| Sync manifest | `site/scripts/.synced-manifest.json` | `sync-docs.mjs` | Lists the four doc-migration outputs owned by the sync script. Used by CI drift-check. |
| Reference manifest | `site/scripts/.reference-manifest.json` | `gen-reference.mjs` | Lists the four generated reference pages owned by the reference generator. Used by CI drift-check. |

## Install artifacts

The `aid add` command writes these files into your project. See [the Installation guide](/guides/installation/) for the steps.

| Artifact | Path | Produced by | Description |
|----------|------|-------------|-------------|
| AID manifest | `.aid/.aid-manifest.json` | `aid add` | Records the top-level `aid_version` (the installed AID release), the shared files (skills, runtime, root regions, mirrors) with their owners and checksums, and each tool's own agent files. `aid update`, `aid status` and `aid remove` read it. |
| Settings | `.aid/settings.yml` | `aid add` | Project settings. `aid add` creates it when it is missing. See [Settings keys](/reference/settings/). |
| `CLAUDE.md` | `CLAUDE.md` (project root) | `aid add claude-code` | Root instruction file for Claude Code. AID writes one [region](/reference/glossary/#aid-region) into it: an `@.aid/runtime/rules.md` import, plus `@.aid/knowledge/PROJECT.md` when the project card exists. Text outside the AID markers is yours and is kept. |
| `AGENTS.md` | `AGENTS.md` (project root) | `aid add <tool>` (every tool) | Root instruction file for every tool. AID writes one region into it: a SESSION START block that makes a Read of `.aid/runtime/rules.md` the first action, forbids answering before that Read and pre-empts "do not read files" prompts, plus the rules summary lifted from that file. Text outside the AID markers is yours and is kept. |

## Templates

Artifacts that have a template link to it below, so you can see their exact shape. The others have no template and are produced by the writer named in the tables above. That covers the delivery branch, the pull request, the deploy record, `README.md`, `INDEX.md`, `kb.html`, the question entry, `project-index.md`, the AID manifest, the root instruction regions and the two generator manifests.

- [requirements/requirements-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/requirements/requirements-template.md): the template for `REQUIREMENTS.md`.
- [specs/technical-specification-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/specs/technical-specification-template.md): the template for the Technical Specification body of a feature section.
- [task-detail-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/task-detail-template.md): the template for a task `DETAIL.md`.
- [task-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/task-state-template.yml): the template for a task `STATE.yml`.
- [delivery-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/delivery-state-template.yml): the template for a delivery `STATE.yml`.
- [work-state-template.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/work-state-template.yml): the template for a work `STATE.yml`.
- [delivery-issues.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/delivery-issues.md): the template for `delivery-NNN-issues.md`.
- [known-issues.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/known-issues.md): the template for `known-issues.md`.
- [feedback-artifacts/IMPEDIMENT.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/feedback-artifacts/IMPEDIMENT.md): the template for an `IMPEDIMENT-task-NNN.md`.
- [knowledge-base/](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/knowledge-base/): the templates for the Knowledge Base documents.
- [settings.yml](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/settings.yml): the template for `.aid/settings.yml`.
- [package.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/package.md): the template for a release package.
- [discovery-state-template.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/discovery-state-template.md): the template for the Knowledge Base `STATE.md`.
- [project-card.md](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/project-card.md): the template for `PROJECT.md`.
