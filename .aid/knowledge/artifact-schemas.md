---
kb-category: primary
source: hand-authored
objective: The structural schema of every artifact the AID methodology produces -- STATE files, REQUIREMENTS/feature-SPEC/delivery-BLUEPRINT/task-DETAIL files, settings, and the three manifest formats -- with required fields, closed enums, producers, consumers, and validation points.
summary: Read this to learn the required shape of any AID artifact (work/delivery/task/discovery STATE.md, REQUIREMENTS.md, feature SPEC.md, delivery BLUEPRINT.md, task DETAIL.md, settings.yml, install + emission + generated-files manifests) before producing or parsing one.
sources:
  - .claude/aid/templates/work-state-template.md
  - .claude/aid/templates/delivery-state-template.md
  - .claude/aid/templates/task-state-template.md
  - .claude/aid/templates/discovery-state-template.md
  - .claude/aid/templates/requirements/requirements-template.md
  - .claude/aid/templates/feature.md
  - .claude/aid/templates/delivery-blueprint-template.md
  - .claude/aid/templates/task-detail-template.md
  - .claude/aid/templates/settings.yml
  - canonical/EMISSION-MANIFEST.md
  - .claude/aid/templates/generated-files.txt
  - lib/aid-install-core.sh
  - canonical/aid/templates/kb-authoring/frontmatter-schema.md
  - canonical/skills/aid-describe/references/state-describe-seed.md
  - canonical/aid/templates/connectors/preset-catalog.md
  - canonical/aid/scripts/connectors/build-connectors-index.sh
  - canonical/skills/aid-discover/references/state-elicit.md
  - .aid/connectors/INDEX.md
tags: [C5, artifact-schemas, state-files, manifests, settings, enums, contracts]
see_also: [authoring-conventions.md, module-map.md, pipeline-contracts.md]
owner: architect
audience: [developer, architect]
contracts:
  - "Task State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled"
  - "Task Type enum (closed, 8): RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE"
  - "Delivery Lifecycle enum (closed): Pending-Spec | Specified | Executing | Gated | Done | Blocked"
  - "KB frontmatter source enum (closed, 3): hand-authored | forward-authored | generated"
  - "emission-manifest.jsonl record keys: profile, src, dst, sha256 (+ _manifest_version sentinel)"
  - "Connector descriptor connection_type enum (closed, 5): mcp | api | ssh | url | cli"
  - "Connector descriptor auth_method enum (closed, 5): none | token | pat | oauth | ssh-key"
changelog:
  - 2026-07-16: work-016 .aid/works/ container relocation -- updated the State-File Hierarchy diagrams, the REQUIREMENTS.md location, and the flattened-path BLUEPRINT.md location to the `.aid/works/work-NNN-{name}/` container tree.
  - 2026-07-09: work-001 lite-skills refresh -- renamed the task-definition section to Task DETAIL.md (source `task-detail-template.md`) and the delivery definition to BLUEPRINT.md (new Delivery BLUEPRINT.md section, source `delivery-blueprint-template.md`); rewrote the flattened Lite path throughout (shortcut engine produces work-root REQUIREMENTS/SPEC/PLAN/BLUEPRINT + tasks/task-NNN/DETAIL.md with NO per-task STATE.md -- cells live in the work-root STATE.md ### Tasks lifecycle); removed the retired Triage/Recipe + Escalation-Carry work-STATE blocks and the CONDENSED-INTAKE/TASK-BREAKDOWN/recipe-emit references; corrected the REQUIREMENTS.md location to the work root.
  - 2026-07-09: housekeep KB-DELTA connectors subsystem refresh -- added the Connector Registry Artifacts section (descriptor schema, derived management mode, secret_reference forms, preset catalog, generated INDEX.md, .mcp.json boundary note); corrected the Rev 1.2 changelog attribution to PR #132.
  - 2026-06-27: aid-describe/aid-define split -- rekeyed REQUIREMENTS.md + lite work-root SPEC.md producers to aid-describe and feature SPEC stubs to aid-define; added the forward-authored source value + greenfield 5-element seed doc-set
  - 2026-06-25: Initial authoring (aid-discover brownfield deep-dive / Analyst); replaces the schemas.md data-model seed
---

# Artifact Schemas

AID has no database. Its "data model" is the set of **Markdown, YAML, and JSON
artifacts** the pipeline reads and writes -- the state files that track a work, the
requirement/spec/blueprint/task documents, the configuration, and the manifests that bound the
installer and renderer. This document is the field-level schema for each one.

Per the signature-exception rule ([authoring-conventions.md](authoring-conventions.md)),
every closed enum and required field below is stated **inline** -- an agent can plan
and act from this doc without reaching into the templates.

> Two related docs: the *frontmatter* schema and the *reviewer-ledger* schema are
> authoring artifacts documented in [authoring-conventions.md](authoring-conventions.md)
> (their required-shape summary is repeated there). This doc covers the pipeline /
> install / render artifacts.

## Contents

- [State-File Hierarchy](#state-file-hierarchy)
- [Work STATE.md](#work-statemd)
- [Delivery STATE.md](#delivery-statemd)
- [Task STATE.md](#task-statemd)
- [Discovery STATE.md](#discovery-statemd)
- [REQUIREMENTS.md](#requirementsmd)
- [Feature SPEC.md](#feature-specmd)
- [Delivery BLUEPRINT.md](#delivery-blueprintmd)
- [Task DETAIL.md](#task-detailmd)
- [settings.yml](#settingsyml)
- [Install Manifest (JSON)](#install-manifest-json)
- [Emission Manifest (JSONL)](#emission-manifest-jsonl)
- [Generated-Files Registry](#generated-files-registry)
- [Discovery Scratch Artifacts](#discovery-scratch-artifacts)
- [Connector Registry Artifacts](#connector-registry-artifacts)
- [Greenfield KB Seed (Forward-Authored)](#greenfield-kb-seed-forward-authored)
- [How Artifacts Relate](#how-artifacts-relate)
- [Contracts](#contracts)
- [Conventions](#conventions)
- [Validation](#validation)
- [Change Log](#change-log)

---

## State-File Hierarchy

AID tracks a work as a **tree of STATE.md files**, each with a single writer. Parent
views are DERIVED (assembled at read time), never written directly.

**Full path** (nests deliveries under a `deliveries/` parent, mirroring `features/`):

```
.aid/works/work-NNN-{name}/STATE.md                              (work level)
  -> deliveries/delivery-NNN/STATE.md                            (delivery level)
       -> tasks/task-NNN/STATE.md                                (task level -- sole write target for task cells)
.aid/knowledge/STATE.md                                          (discovery area -- KB + summary state)
```

**Flattened Lite path** (exactly one delivery, no `deliveries/` folder, no per-task STATE.md -- the work IS the delivery):

```
.aid/works/work-NNN-{name}/STATE.md                   (work level -- ALSO carries the sole delivery's
                                                        ## Delivery Lifecycle [with its ### Tasks lifecycle
                                                        table] / ## Delivery Gate / ## Cross-phase Q&A,
                                                        AUTHORED directly; see Work STATE.md below)
  -> tasks/task-NNN/DETAIL.md                          (task DEFINITION only -- IMMUTABLE, no sibling STATE.md;
                                                        mutable cells live in the work-root STATE.md
                                                        ### Tasks lifecycle table)
.aid/knowledge/STATE.md                                          (discovery area -- KB + summary state)
```

Cardinality: one work STATE.md per work; one delivery STATE.md per delivery on the full path
(zero on the flattened Lite path -- its single delivery's state lives in the work STATE.md
instead); one task STATE.md per task on the full path (zero on the flattened Lite path -- task
cells live in the work STATE.md `### Tasks lifecycle`); one discovery STATE.md per project.

The **closed task State enum** and its reconcile ordering (SD-2) are shared by all
three work-tree levels:

`Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`

Most-advanced-wins order on multi-branch reconcile:
`Done > Canceled > In Review > In Progress > Blocked > Failed > Pending`.

---

## Work STATE.md

Source: `work-state-template.md`. Two zones -- **AUTHORED** (single-writer) and
**DERIVED** (read-time union over child files; never written here).

| Section | Zone | Key fields / enums |
|---------|------|--------------------|
| Pipeline State | AUTHORED | `Lifecycle`: `Running \| Paused-Awaiting-Input \| Blocked \| Completed \| Canceled`; `Phase`: `Describe \| Define \| Specify \| Plan \| Detail \| Execute`; `Active Skill`: `aid-{skill} \| none`; `Updated` (ISO-8601); conditional `Pause/Block Reason`, `Block Artifact`. |
| Interview State | AUTHORED | 10-row section table (Objective..Priority), each `Pending \| ...`; State + Grade. |
| Seed Authoring | AUTHORED (greenfield only, by `aid-describe` DESCRIBE-SEED) | `Status`: `In Progress \| Complete`; 5-element checklist (domain-glossary/architecture mandatory, coding-standards/technology-stack deferrable, decisions conditional); `Coherence check`; `Review grade`. |
| Lifecycle History | AUTHORED | append-only audit table (Date, Phase Transition/Gate, Grade, Notes), newest last. |
| Deploy State | AUTHORED (by `aid-deploy` only) | one row per delivery (Delivery, State, PR, KB Updated, Tag, Notes). |
| Delivery Lifecycle, Tasks lifecycle, Delivery Gate | AUTHORED -- **single-delivery FLATTENED (Lite) works only** (absent entirely for full multi-delivery works) | same shape as the full-path Delivery STATE.md sections below, authored directly here because a flattened work has exactly one delivery and no `deliveries/` folder. `## Delivery Lifecycle` (`Pending-Spec`→`Specified` by the shortcut engine PLAN step, `Executing`→`Gated`→`Done`/`Blocked` by `aid-execute`); `### Tasks lifecycle` (per-task `State`/`Review`/`Elapsed`/`Notes` rows -- the single-writer home for task cells, replacing the now-absent per-task `STATE.md`; written by the engine DETAIL step and `writeback-state.sh --task-id NNN` flat-layout branch); `## Delivery Gate` (`aid-execute` delivery-gate result). |
| Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log, Dispatches | **DERIVED** (full path); on the flattened Lite path Plan/Deliveries, Delivery Gates, and the plural `## Tasks State` view stay `_none yet_` (no per-delivery/per-task STATE.md to union -- the authoritative task cells are the AUTHORED `### Tasks lifecycle` above) | read-only unions over per-delivery / per-task STATE.md; never written here. |
| Cross-phase Q&A | **DERIVED** for full-path works (union of each delivery's Q&A + work-owner entries); **AUTHORED** for flattened Lite works (no delivery STATE.md to derive from -- the single delivery's Q&A is written directly into this section) | per-Q block: `Category`, `Impact`, `State`/`Status`, Context, Suggested, Answer, Applied-to. |

Producer: `execute/writeback-state.sh --pipeline ...` + the orchestrator (single
writer on the work's active branch). The `## Interview State` and greenfield
`## Seed Authoring` blocks are authored by `aid-describe`; the flattened-work
`## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` blocks are authored by the
shortcut engine and `aid-execute`. Consumer: the dashboard reader, `aid-execute`.

---

## Delivery STATE.md

Source: `delivery-state-template.md` -- **FULL PATH ONLY**. Lives at
`deliveries/delivery-NNN/STATE.md`; AUTHORED by this delivery's branch only. A flattened Lite
work has no delivery-level STATE.md at all -- its single delivery's `## Delivery Lifecycle` /
`## Delivery Gate` / `## Cross-phase Q&A` are AUTHORED directly in the work-root `STATE.md`
instead (see the Work STATE.md table above); its task cells live in the work-root
`STATE.md § ### Tasks lifecycle` (no delivery layer, and no per-task STATE.md to nest under).

| Section | Key fields / enums |
|---------|--------------------|
| Delivery Lifecycle | `State`: `Pending-Spec \| Specified \| Executing \| Gated \| Done \| Blocked` (independently authored -- NOT a task rollup, per SD-9); `Updated`; conditional Block Reason/Artifact. |
| Delivery Gate | `Reviewer Tier`: `Small \| Medium \| Large`; `Grade`; `Issue List` (inline severity-tagged or `none`); `Timestamp`. |
| Cross-phase Q&A | per-Q block: `Category`, `Impact` (`High \| Medium \| Low \| Required`), `State` (`Pending \| Answered \| Skipped`), Context, Suggested, Answer, Applied-to. |
| Tasks State | **DERIVED** rollup from `tasks/task-NNN/STATE.md` (relative to this delivery folder); never written here. |

Producer: `aid-plan` (creates, `Pending-Spec`, at `deliveries/delivery-NNN/STATE.md`),
`aid-specify` (`Specified`), `aid-execute` (`Executing`->`Gated`->`Done` / `Blocked`), via
`writeback-state.sh --delivery-id NNN`. On the flattened Lite path, the **shortcut engine**
writes the `## Delivery Lifecycle` (initial `Pending-Spec`) + `## Delivery Gate` sections directly
into the work-root `STATE.md` during its PLAN/DETAIL steps (and `aid-execute` later advances the
lifecycle) -- no `delivery-001/STATE.md` file is created; `writeback-state.sh --delivery-id 001`
auto-detects the flattened layout (a work-root `BLUEPRINT.md` present AND no `deliveries/` folder)
and targets the work-root STATE.md instead.

---

## Task STATE.md

Source: `task-state-template.md` -- **FULL PATH** (lives at
`deliveries/delivery-NNN/tasks/task-NNN/STATE.md`). The **sole write target** for all per-task
mutable state on the full path; all sections AUTHORED by the owning delivery branch. A flattened
Lite work has **no per-task STATE.md** -- each task is a `tasks/task-NNN/DETAIL.md` definition
only, and its mutable cells (State/Review/Elapsed/Notes) live in the work-root
`STATE.md § ### Tasks lifecycle` table instead.

| Section | Key fields |
|---------|-----------|
| Task State | `State` (the closed 7-value enum above); `Review` (tier + outcome, or `Pending`); `Elapsed` (`HH:MM \| --`); `Notes`. Written only by `writeback-state.sh --task-id NNN --field State --value V`. |
| Quick Check Findings | `Reviewer Tier`: `Small` (quick check is always Small); `Findings`: `[CRITICAL]` (Fixed-on-spot) / `[HIGH]` (Deferred-to-gate) items. No grade (grading is per-delivery). |
| Dispatch Log | append-only rows (Date, Agent, ETA Band, Actual, Outcome); the work-level Calibration Log/Dispatches are derived unions of these. |

---

## Discovery STATE.md

Source: `discovery-state-template.md`. Lives at `.aid/knowledge/STATE.md`; tracks the
KB + the visual summary (absorbs the former DISCOVERY-STATE + SUMMARY-STATE).

| Section | Key fields |
|---------|-----------|
| Header | `Status`: `Initial \| In Progress \| Approved`; `Current Grade`; `User Approved`; `Last KB Review`; `Last Summary`. |
| External Documentation | table (Path, Type, Accessible, Notes). |
| KB Documents Status | one row per doc in the confirmed `discovery.doc_set` (domain-driven, NOT hardcoded): Document, Status, Grade, Last Reviewed, Notes. |
| Knowledge Summary Status | Profile, Profile Source/Confidence, Theme, Machine/Human Grade, User Approved, Output, Mermaid version/cache. |
| Q&A (Pending) | per-Q block: ID `Q{N}`, Category, Impact (`High \| Medium \| Low \| Required`), Status (`Pending \| Answered \| Skipped`), Context, Suggested, Answer, Applied-to. |
| Review History / Summarization History | append-only, one row per cycle/run. |

Producer: `aid-config` (creates), `aid-discover` + `aid-summarize` (update). Note:
project-level settings (grades, parallelism) live in `settings.yml`, **not** here.

---

## REQUIREMENTS.md

Source: `requirements/requirements-template.md`. A first-class pipeline artifact at
`.aid/works/work-NNN-{name}/REQUIREMENTS.md` (uppercase, at the work root). Produced by `aid-describe`
(Phase 2a, **full path**) as the approved requirements document. On the **flattened Lite path**
it is produced instead by the **shortcut engine**'s CAPTURE step (written to the same work-root
path, all 10 sections) ahead of the engine's SPEC/PLAN/DETAIL steps -- the Lite path produces the
full artifact set (`REQUIREMENTS.md` → `SPEC.md` → `PLAN.md` + `BLUEPRINT.md` →
`tasks/task-NNN/DETAIL.md`), collapsed and mostly autonomous, not a reduced one. The greenfield
full path additionally produces a forward-authored KB seed -- see
[Greenfield KB Seed](#greenfield-kb-seed-forward-authored).

Required structure: `# Requirements` with `Name` + `Description`, a mandatory
`## Change Log` table, then 10 numbered sections:

1. Objective · 2. Problem Statement · 3. Users & Stakeholders (table) · 4. Scope
(In/Out) · 5. Functional Requirements · 6. Non-Functional Requirements · 7.
Constraints · 8. Assumptions & Dependencies · 9. Acceptance Criteria · 10. Priority.

Rules: the **Change Log is mandatory** (every edit gets a row); unaddressed sections
carry `*(pending)*`; sections may be `N/A`; acceptance criteria must be testable; the
stakeholder's own words are preferred in Objective/Problem Statement.

---

## Feature SPEC.md

Source: `feature.md`. Per-feature artifact: the requirements-half stub is created by
`aid-define` (Phase 2b, full path only) when its FEATURE-DECOMPOSITION state decomposes the
approved `REQUIREMENTS.md` into `features/feature-NNN-name/` folders; the technical half is added
later by `aid-specify`. (`aid-define` also runs CROSS-REFERENCE to validate the feature
boundaries against the KB and codebase.) On the flattened Lite path there is no `features/`
folder -- the shortcut engine writes a single consolidated work-root `SPEC.md` of the same shape
instead (see [How Artifacts Relate](#how-artifacts-relate)).

Requirements half (required, authored by `aid-define`): `# {Feature Title}`,
`## Change Log`, `## Source` (REQUIREMENTS refs), `## Description`, `## User Stories`
(As a/I want/so that), `## Priority` (`Must \| Should \| Could`), `## Acceptance Criteria`
(Given/When/Then checkboxes).

Specify half (added by `/aid-specify`, do not fill during define):
`## Technical Specification` with `### Data Model`, `### Feature Flow`,
`### Layers & Components`, plus conditional sections (API Contracts, UI Specs,
Events & Messaging, BDD Scenarios, Migration Plan, Security Specs, ...) activated
only when relevant.

---

## Delivery BLUEPRINT.md

Source: `delivery-blueprint-template.md`. The **immutable** delivery definition -- written once
by `aid-plan` (creates the stub) and refined by `aid-specify` on the full path (at
`deliveries/delivery-NNN/BLUEPRINT.md`), or authored by the shortcut engine's PLAN step on the
flattened Lite path (at the work root, `.aid/works/{work}/BLUEPRINT.md`). Not a state file -- the
delivery's mutable lifecycle/gate lives in the delivery `STATE.md` (full path) or the work-root
`STATE.md` (flattened).

Required structure: `# Delivery BLUEPRINT -- delivery-NNN: {Title}`, then:

- `## Objective` -- what this delivery achieves and why it is a distinct unit.
- `## Scope` -- bounded in-scope deliverables + an explicit `**Out of scope:**` line.
- `## Gate Criteria` -- ordered, concrete, independently testable checkboxes; the delivery gate
  (`grade.sh`) uses these as its rubric. The last is always "All section-6 quality gates pass".
- `## Tasks` -- a navigational table (`Task | Type | Title`); each task's full definition is its
  `tasks/task-NNN/DETAIL.md`.
- `## Dependencies` -- `**Depends on:**` / `**Blocks:**` (`delivery-NNN` or `-- (none)`).
- `## Notes` -- design notes/constraints not captured in the gate criteria.

The delivery gate reads its criteria from `BLUEPRINT.md § Gate Criteria`, NOT from the delivery
`STATE.md` (the STATE.md `## Delivery Gate` records the *result*).

---

## Task DETAIL.md

Source: `task-detail-template.md`. The **immutable** task definition -- written once by
`aid-detail` (full path, at `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`) or by the shortcut
engine's DETAIL step (flattened Lite path, at `tasks/task-NNN/DETAIL.md`). Mutable state lives in
the sibling `task-NNN/STATE.md` on the full path, or in the work-root `STATE.md § ### Tasks
lifecycle` on the flattened path (no sibling STATE.md there).

Required fields:

- `# task-NNN: {Title}`
- `Type` (closed enum, 8 values, **one type per task -- never mixed**):
  `RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE`
- `Source`: `work-NNN-{name} -> delivery-NNN`
- `Depends on`: `task-NNN[, task-NNN] | --`
- `Scope`: bounded list of what the task produces/modifies
- `Acceptance Criteria`: concrete, testable checkboxes; the last is always
  "All section-6 quality gates pass".

---

## settings.yml

Source: `templates/settings.yml`. YAML 1.2 at `.aid/settings.yml`; the single source
of truth for pipeline settings. Managed by `/aid-config`; read via `read-setting.sh`.

| Key | Type | Default / values |
|-----|------|------------------|
| `project.name` / `project.description` | string | set at INIT; description is the sole source (not duplicated in CLAUDE.md). |
| `project.type` | enum | `brownfield \| greenfield`. |
| `tools.installed` | list | e.g. `[claude-code, codex, cursor]`. |
| `review.minimum_grade` | grade | global REVIEW floor; default `A`. Valid: `A+..F`. |
| `execution.max_parallel_tasks` | int | parallel dispatch capacity (default 5). |
| `traceability.heartbeat_interval` | int (min) | sub-agent heartbeat cadence (default 1). |
| `kb_baseline.{branch,tip_date}` | block | git baseline the KB reflects; producer-written; absent => freshness check skipped. |
| `discovery.closure.{max_clean_passes,max_rounds,token_budget}` | ints | closure-loop caps (3-level path NOT readable via `read-setting.sh`; consumed via Step 5b override interface). |
| `discovery.doc_set` | list | confirmed doc set; conditional sibling written by Step 0d only when it differs from the seed. |
| `triage.{greenfield_max_source_files,greenfield_max_source_loc,large_min_source_loc,large_min_dirs,large_min_concepts}` | ints | recon-classify path thresholds. |
| `{skill}.minimum_grade` | grade | optional per-skill override of `review.minimum_grade`. |

Resolution order (`read-setting.sh`): per-skill override -> category default
(`review.*`) -> hardcoded `--default`. `read-setting.sh` resolves a **2-level**
`section.key` path only; 3-level keys (`discovery.closure.*`) are not readable by it.

---

## Install Manifest (JSON)

Written by the install-core libraries to record what was installed per tool (so
uninstall removes only AID's own files). Functions: `manifest_write` /
`Write-AidManifest`; readers `manifest_read_tool_paths`, `manifest_read_tool_version`,
`manifest_read_root_agent[_status]`.

Shape (per `lib/aid-install-core.sh` `Provides:` block):

```
{
  "tools": {
    "<tool-id>": {
      "version": "<x.y.z>",
      "paths":   ["<installed path>", ...]
    }
  },
  "root_agent_files": {
    "<tool-id>": {
      "<filename>": { "sha256": "<hex>", "status": "<status>" }
    }
  }
}
```

Producer: `install_tool` / `Install-AidTool` (atomic write/merge). Consumer:
`uninstall_tool` / `Uninstall-AidTool` (manifest-driven removal), update path. The
`root_agent_files` sha256 lets the installer detect whether a host file's AID region
changed. The in-place region replacement is performed by the install-core libs
(`lib/aid-install-core.sh` + its PowerShell twin `lib/AidInstallCore.psm1`); the region's
**content** is the `AID:BEGIN/END` body of the rendered root-agent file
(`profiles/<tool>/{CLAUDE.md,AGENTS.md}`). See authoring-conventions.md § Content Isolation.

---

## Emission Manifest (JSONL)

Source: `canonical/EMISSION-MANIFEST.md`. One `emission-manifest.jsonl` per profile,
at the profile's deepest common output parent. The **safety boundary** for the
renderer's pure-mirror deletion.

- **First line is a sentinel:** `{"_manifest_version": 1}`.
- **Every other line** is a JSON object with exactly four keys:
  `profile` (string), `src` (repo-relative `canonical/` path), `dst` (install-tree
  path relative to the manifest dir), `sha256` (lowercase hex of rendered bytes).
- **Ordering:** sorted lexicographically by `dst` (byte-stable re-runs).
- **Line endings:** LF only, one trailing `\n` per record incl. the last; written in
  binary mode.

Deletion contract: on re-render, `diff(prev, curr)` -> only `removed_dst` paths are
deleted; files outside any manifest are never touched.

---

## Generated-Files Registry

Source: `templates/generated-files.txt`. One line per generated file:

```
<output-path>|<build-command>
```

- `output-path` is relative to the target project root; `build-command` regenerates
  it from the project root. Comments (`#`) and blanks ignored. **Order matters** --
  dependencies first (run top-to-bottom).
- Source-form paths are `canonical/`-rooted; the renderer rewrites them to each
  profile's install root at render time.

Consumers: `aid-discover` FIX (refresh-all at cycle end) and the `test -f` existence
loop. Current entries: `project-index.md`, `metrics.md`, `INDEX.md`.

---

## Discovery Scratch Artifacts

Generated discovery outputs under `.aid/generated/` (each carries an
`AUTO-GENERATED` comment):

| Artifact | Producer | Shape |
|----------|----------|-------|
| `project-index.md` | `build-project-index.sh` | Summary + Language Breakdown + Notable/Largest files + full file inventory (Path, Language, Lines, Modified). |
| `candidate-concepts.md` | `harvest-coined-terms.sh` (+ synthesis channel) | Summary + Ranked Candidates table (`#, Source, Term, Class, Freq, Spread, Channels, Salience, Example source`). `Source` = `harvest \| synthesis`. |
| `spine-todo.md` | discovery agents (append-only) | `Term \| Status \| Disposition` -- the terminal-state work-list for candidate concepts (ground or dismiss; none silently dropped). |
| `metrics.md` | `build-metrics.sh` | numeric T3 facts (counts/tallies). |

---

## Connector Registry Artifacts

The connector registry (`.aid/connectors/`) is a **catalog**, not a connection
manager: it records what agents can use and how, and does not wire any host tool
(`aid-discover` ELICIT Steps E1/E2 + reconcile Steps R0-R5; STATE.md Q10). Two
management modes derive from a single field, `connection_type` -- no separate mode
field is stored.

**Connector descriptor** (`.aid/connectors/<connector>.md` frontmatter):

| Field | Type | Required | Meaning |
|-------|------|----------|---------|
| `name` | string | yes | Human name; slugified to the file's `<connector>` stem. |
| `connection_type` | closed enum: `mcp \| api \| ssh \| url \| cli` | yes | The transport; also the **sole source of the derived management mode** (below). `db` is not a value (folds into `cli`/`api`). |
| `endpoint` | string | yes | Aid-managed (`api\|ssh\|url\|cli`): the concrete connect target. Tool-managed (`mcp`): informational only -- AID never launches or wires it. |
| `auth_method` | closed enum: `none \| token \| pat \| oauth \| ssh-key` | yes | Orthogonal to `connection_type`. Always `none` for a tool-managed (`mcp`) connector. |
| `secret_reference` | string, one of three reference forms (below) | yes iff aid-managed AND `auth_method != none`; omitted otherwise | A *reference*, never a value; always omitted for a tool-managed (`mcp`) connector. |
| `preset` | string | yes | The catalog `preset-id` (e.g. `github`), or `custom`. |
| `objective`, `summary`, `tags`, `audience` | KB-style routing fields | yes | Reuses the KB frontmatter *format* (not its required-field set) -- see `preset-catalog.md`. |

**Derived management mode (STATE.md Q10).** A `connection_type: mcp` descriptor is
**tool-managed**: the host tool provides its own MCP server/plugin for the target and
handles auth; AID stores no credential and wires nothing. A
`connection_type: api | ssh | url | cli` descriptor is **aid-managed**: AID records the
descriptor and, when `auth_method != none`, a local credential resolved via
`secret_reference` at use-time. No `management_mode` field is stored -- it is always
re-derived from `connection_type` to avoid drift.

**`secret_reference` value format** -- three reference forms, never a credential value:

| Form | Meaning |
|------|---------|
| `env:<VAR>` | Resolve an environment variable at use-time. |
| `file:.aid/connectors/.secrets/<connector>` | Resolve the git-ignored local secret file (written by `connector-secret.sh`/`.ps1` `write`). |
| `keychain:<name>` | Resolve an entry in the OS keychain. |

**Preset catalog** (`canonical/aid/templates/connectors/preset-catalog.md`) -- a
`canonical/` asset that ships byte-identically into every profile's install tree and
pre-fills a descriptor for a curated set of known tools. Columns: `preset-id`, `name`,
`connection_type`, `endpoint-template`, `auth_method`, `secret_reference-form` (form
only, never a value; `--` for tool-managed presets), `notes`, `tags`. Consumed by
`aid-discover` ELICIT Step E2 (preset branch); an id not found in the catalog is
captured as `custom`, never guessed as a near match.

**Generated `INDEX.md`** (`.aid/connectors/INDEX.md`) -- the routing table between
agents and the registry: an agent reaches it via the `## Connectors` context-file
pointer, then opens the specific descriptor. Frontmatter: `source: generated`,
`generator: build-connectors-index`. Columns: `Connector | Type | Endpoint | Auth |
Secret Ref | Summary` (`Secret Ref` renders as an em dash when `auth_method: none`).
Deterministic -- no run timestamp or dated changelog entry, so an unchanged descriptor
set re-builds byte-identical (reconcile idempotence depends on this). A
zero-descriptor registry still gets a header-only `INDEX.md` (frontmatter + table
header, zero rows), never a missing file. Producer: `build-connectors-index.sh`/`.ps1`,
triggered by ELICIT authoring (add/update) and reconcile (Steps R0-R5).

**`.mcp.json`** (repo root) -- **not an AID artifact.** It is the host tool's (e.g.
Claude Code) native MCP-server registration file, read by the host tool itself; no AID
script or skill reads or writes it (`state-elicit.md`'s `mcp` management-mode branch:
"AID neither writes nor triggers any host MCP configuration"). A tool-managed (`mcp`)
connector descriptor never references or edits this file -- the host tool's own
MCP/plugin mechanism is out of the connector registry's scope entirely.

Producer: `aid-discover` ELICIT (Step E2 author, Steps R0-R5 reconcile) via
`canonical/aid/scripts/connectors/*`. Consumer: any agent needing a tool integration,
via the `INDEX.md` pointer; `connector-secret.sh`/`.ps1` (`write`/`purge`) is the sole
reader/writer of `.aid/connectors/.secrets/`.

---

## Greenfield KB Seed (Forward-Authored)

On the **greenfield full path**, `aid-describe`'s DESCRIBE-SEED state authors a KB seed
*from elicited intent before any code exists* -- the inverse of brownfield extraction.
These docs are **design-authoritative** (authority direction design->code) and are
written directly into `.aid/knowledge/`.

**The `source:` frontmatter enum is 3-valued (closed):**

| Value | Meaning |
|-------|---------|
| `hand-authored` | Written by humans / agents acting as humans (brownfield GENERATE). Full content review. |
| `forward-authored` | Authored from intent **before code exists** (the greenfield seed). Full content review (same rubric as hand-authored). **Design-authoritative:** freshness folds it to `current` (source-drift N/A); code->design divergence is detected by feature-005's separate conformance check, NOT by the f007 freshness check. |
| `generated` | Produced by a registered build script (`generator:` field MUST be set). Reviewer verifies regeneration, does not grade content. |

**The seed is a 5-element doc-set** (intent, not inventory -- kept minimal). Each doc
carries `source: forward-authored`, `sources: []` (a pure-intent doc; cited external
design notes go in `sources:`, never code files), and the element's concern-id `tags:`:

| # | Element | KB doc | kb-category | tags | Weight | Fit criterion (Open when NOT met) |
|---|---------|--------|-------------|------|--------|-----------------------------------|
| 1 | Declared concept-spine / ubiquitous language | `domain-glossary.md` | primary | `[C4, ...]` | MANDATORY | Every load-bearing term defined as this project uses it (not generic) + relationships + `## Invariants` + a concrete example; work explainable using only defined native terms + general knowledge (C4 bar). |
| 2 | Intended architecture (boundaries + relationships, sketch altitude) | `architecture.md` | primary | `[C1, ...]` | MANDATORY | Major parts / boundaries / relationships named + `## Invariants` present. Sketch altitude, not as-built. |
| 3 | Conventions & standards | `coding-standards.md` | primary | `[C3, ...]` | DEFERRABLE | Project rules stated OR an explicit "standard for `<stack>`, no project-specific deviations yet" statement. |
| 4 | Technology stack / medium | `technology-stack.md` | primary | `[C0, ...]` | DEFERRABLE | Chosen language / runtime / framework named (version MAY be "latest-at-init / TBD"). |
| 5 | Decisions & rationale | `decisions.md` | extension | `[D, ...]` | CONDITIONAL | Only when rationale-bearing choices are confirmed (propose->confirm gate). Each entry: what was decided + why + rejected alternative + `Status`. |

**decisions.md entry schema** (ADR-immutable -- a recorded decision is NEVER edited in
place; a change APPENDS a new `Status: Accepted` + `Supersedes:` entry and marks the
prior one `Status: Superseded` + `Superseded-by:`):

```
## <Decision title>
- **Status:** Accepted          (or Superseded)
- **Decided:** <what was decided>
- **Rationale:** <why>
- **Rejected alternative:** <what was not chosen and why not>
- **Supersedes:** <prior-title>     (present only when this entry replaces a prior one)
- **Superseded-by:** <new-title>    (present only when a later entry supersedes this one)
```

**Exclusions:** as-built docs with no greenfield source are NEVER authored in the seed --
`module-map.md`, `test-landscape.md`, `infrastructure.md`, `feature-inventory.md`,
`project-structure.md`, and (unless domain-promoted) `schemas.md` / `integration-map.md` /
`pipeline-contracts.md`.

Producer: `aid-describe` DESCRIBE-SEED (engine-driven elicitation -> author -> coherence
check -> greenfield-mode review gate). Consumers: `aid-specify` / `aid-plan` /
`aid-execute` read the seed unchanged; `kb-freshness-check.sh` short-circuits
forward-authored docs to `current`.

---

## How Artifacts Relate

```
Full path:
REQUIREMENTS.md    -> feature SPEC.md (define/decomposition half) -> SPEC.md (specify half)
SPEC.md            -> PLAN.md -> deliveries/delivery-NNN/BLUEPRINT.md -> tasks/task-NNN/DETAIL.md (immutable)
task-NNN DETAIL.md  ~ task-NNN/STATE.md (mutable state for the same task)
task STATE.md      -> delivery STATE.md (derived) -> work STATE.md (derived)

Flattened Lite path (no deliveries/, no delivery-NNN/ folder, no per-task STATE.md -- the work IS the sole delivery):
REQUIREMENTS.md    -> SPEC.md -> PLAN.md + BLUEPRINT.md -> tasks/task-NNN/DETAIL.md (immutable, directly under the work folder)
task-NNN DETAIL.md cells -> work STATE.md ### Tasks lifecycle (AUTHORED; no sibling STATE.md)
delivery lifecycle/gate  -> work STATE.md ## Delivery Lifecycle / ## Delivery Gate (AUTHORED directly)

settings.yml       -> read by every skill via read-setting.sh
candidate-concepts.md -> domain-glossary.md (ground) OR spine-todo.md (dismiss)
greenfield intent  -> forward-authored KB seed (5 docs in .aid/knowledge/) -> read by aid-specify/plan/execute
canonical/ files   -> emission-manifest.jsonl (one record each) -> profiles/<tool>/
install manifest   <- install-core; consumed by uninstall/update
```

Cardinality summary:

| Parent | Child | Cardinality |
|--------|-------|-------------|
| work | delivery | one-to-many |
| delivery | BLUEPRINT.md | one-to-one |
| delivery | task | one-to-many |
| task DETAIL.md | task STATE.md | one-to-one, full path only (flattened Lite has no per-task STATE.md) |
| REQUIREMENTS.md | feature SPEC.md | one-to-many |
| profile | emission-manifest record | one-to-many |
| install manifest | tool entry | one-to-many |

---

## Contracts

> The structural shape a change MUST satisfy.

- **Closed STATE enums are byte-stable.** Adding/renaming a value in the task State,
  Delivery Lifecycle, task Type, Pipeline Lifecycle/Phase, or Q&A Impact/Status enums
  is a breaking change -- the dashboard readers (Python + Node twins) and
  `writeback-state.sh` bind to the exact strings. Both reader twins must change in
  lockstep.
- **The KB frontmatter `source:` enum is closed (3 values).**
  `hand-authored | forward-authored | generated`. It is consumed by
  `kb-freshness-check.sh` (the `forward-authored` short-circuit to `current`) and the
  review rubric (source selects which rubric applies); adding a value is a breaking
  change across both. `forward-authored` is design-authoritative -- it gets the full
  hand-authored review rubric, but freshness treats it as never-stale-from-source, and
  code->design conformance is a SEPARATE check (feature-005), never the f007 freshness check.
- **DERIVED sections are read-only.** A producer MUST write the per-unit STATE.md,
  never a parent's derived view (work/delivery `## Tasks State`, `## Delivery Gates`,
  `## Cross-phase Q&A`, `## Calibration Log`). The disjoint-write property (two
  delivery branches never collide on a shared file) depends on this. (The flattened
  Lite work is the single-writer exception: with exactly one delivery and one branch,
  its `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` are AUTHORED
  directly in the work-root STATE.md.)
- **One writer per file.** Each STATE.md level has a single writer (the owning
  branch); cross-writes break the merge model.
- **Emission record = exactly 4 keys + sentinel.** Adding a key bumps
  `_manifest_version`; a consumer reading a higher version uses a different parser.
- **Required-section contract.** REQUIREMENTS.md keeps all 10 numbered sections
  (pending ones marked `*(pending)*`, not deleted); a task DETAIL.md carries exactly
  one `Type`.

---

## Conventions

> How to add or change an artifact or field.

- **Adding a STATE field:** add it to the AUTHORED zone of the right level's
  template, teach `writeback-state.sh` to write it, and update the Node reader twin
  `reader.mjs` (which ports the whole `dashboard/reader/*.py`) to parse it.
- **Adding an enum value:** update the template's inline enum comment, both reader
  twins, the SD-2 ordering if it affects reconcile, and this doc's inline contract.
- **Adding a settings key:** add it to `templates/settings.yml` with a comment;
  read it via `read-setting.sh` (2-level path) -- a 3-level key needs an explicit
  override interface, it is not auto-readable.
- **Adding a generated file:** append a `<output-path>|<build-command>` line to
  `generated-files.txt` (dependencies first).
- **Adding an artifact type:** add a template under `.claude/aid/templates/`, name
  its producer/consumer skills, and document its required vs optional sections here.

---

## Validation

> What happens when an artifact is malformed or missing a required section -- and
> where it is detected.

| Artifact | Validated by | On malformed/missing |
|----------|-------------|----------------------|
| `settings.yml` | `read-setting.sh` | exit 2 (unreadable/malformed YAML); a missing key with no `--default` -> exit 1. |
| STATE.md | dashboard reader (Python/Node twins) | reader degrades gracefully; an unknown enum value is not in the closed set and mis-reconciles -- caught by the reader test suites and parity tests. |
| Frontmatter (on KB docs) | `lint-frontmatter.sh` | `[FM-MISSING]`/`[FM-INVALID]` HIGH findings; parse failure -> doc treated as primary/hand-authored + HIGH warning. |
| Reviewer ledger | `grade.sh` | only `[SEVERITY]`-tagged rows with Status `Pending`/`Recurred` count; a stray `## Summary` line would over-count (banned). |
| emission-manifest.jsonl | renderer determinism checks (`verify_deterministic.py`, `test_manifest_safety.py`) | a non-byte-stable or mis-keyed manifest fails the render-drift CI gate. |
| Install manifest | install-core (`manifest_exists`) | missing manifest on uninstall -> exit 6. |
| task DETAIL.md `Type` | `aid-execute` task-type rules | a missing/mixed type blocks execution (one type per task). |
| KB-doc citations | `kb-citation-lint.sh` | bare `file:LINE` -> exit 1, GENERATE blocked until fixed. |

There is **no central schema validator**; validation is distributed -- a lint, a
reader, or a skill gate owns each artifact class. The freshness baseline
(`kb_baseline`, `approved_at_commit`) degrades gracefully when absent (treated as
"baseline unknown", never a hard failure); a `source: forward-authored` doc is folded
to `current` by `kb-freshness-check.sh` regardless of baseline.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial artifact-schemas doc (Analyst); replaces the schemas.md data-model seed |
| 1.1 | 2026-06-27 | work-001-aid-interview-improvements | aid-describe/aid-define split: rekeyed REQUIREMENTS.md + lite work-root SPEC.md producers to `aid-describe` and feature SPEC stubs to `aid-define`; added the `source: forward-authored` enum value, the greenfield 5-element seed doc-set section, the `## Seed Authoring` work-STATE block, and forward-authored contracts/validation notes |
| 1.2 | 2026-07-08 | PR #132 (branch `change-delivery`) | Delivery-folder layout rationalized: full path nests delivery folders under `deliveries/` (`deliveries/delivery-NNN/`); lite path drops the `delivery-001/` folder entirely (tasks live directly at `tasks/task-NNN/`) and the sole delivery's `## Delivery Lifecycle` + `## Delivery Gate` + `## Cross-phase Q&A` are AUTHORED directly in the work-root STATE.md. Updated the State-File Hierarchy diagram, Work/Delivery STATE.md tables, REQUIREMENTS.md section, and How Artifacts Relate diagram for both layouts. |
| 1.3 | 2026-07-09 | housekeep KB-DELTA | Connectors subsystem refresh: added the Connector Registry Artifacts section (descriptor frontmatter schema, derived management-mode rule, the three `secret_reference` forms, the preset-catalog format, the generated `INDEX.md` contract, and a boundary note that `.mcp.json` is not an AID artifact); added the closed `connection_type`/`auth_method` enums to the frontmatter `contracts:` list; corrected the Rev 1.2 row's Source attribution from "work-001-add-deliveries-folder task-001" to the source-verified PR #132 (branch `change-delivery`), content unchanged. |
| 1.4 | 2026-07-09 | work-001 lite-skills refresh | Renamed the task-definition section to **Task DETAIL.md** (source `task-detail-template.md`, replacing the deleted `task-spec-template.md`) and added a new **Delivery BLUEPRINT.md** section (source `delivery-blueprint-template.md`). Rewrote the flattened Lite path across the State-File Hierarchy, Work/Delivery/Task STATE.md sections, REQUIREMENTS.md, Feature SPEC.md, How Artifacts Relate, Cardinality, Contracts, and Validation: the shortcut engine produces work-root `REQUIREMENTS.md`/`SPEC.md`/`PLAN.md`/`BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` with **no per-task `STATE.md`** (cells live in the work-root `STATE.md § ### Tasks lifecycle`). Removed the retired `## Triage` (with its `Recipe` field) and `## Escalation Carry` work-STATE rows and the `CONDENSED-INTAKE` / `TASK-BREAKDOWN` / recipe-emit references (recipes + aid-describe lite/triage removed by work-001). Corrected the REQUIREMENTS.md location from `.aid/knowledge/` to the work root `.aid/work-NNN-{name}/`. |
