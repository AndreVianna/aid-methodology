---
kb-category: primary
source: hand-authored
objective: The structural schema of every artifact the AID methodology produces -- STATE files, REQUIREMENTS.md with its § 11 feature sections, PLAN.md with its delivery stanzas, task DETAIL files, settings, and the three manifest formats -- with required fields, closed enums, producers, consumers, and validation points.
summary: Read this to learn the required shape of any AID artifact (work/delivery/task STATE.yml, discovery STATE.md, REQUIREMENTS.md and its § 11 feature sections, PLAN.md and its delivery stanzas, task DETAIL.md, settings.yml, install + emission + generated-files manifests) before producing or parsing one.
sources:
  - canonical/aid/templates/work-state-template.yml
  - canonical/aid/templates/delivery-state-template.yml
  - canonical/aid/templates/task-state-template.yml
  - .claude/aid/templates/discovery-state-template.md
  - .claude/aid/templates/requirements/requirements-template.md
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
see_also: [authoring-conventions.md, module-map.md, pipeline-contracts.md, tech-debt.md]
owner: architect
audience: [developer, architect]
review-criteria:
  - id: F-01
    kind: validate
    criterion: "Every enum this doc calls closed matches its implementation byte for byte -- Task State, Task Type, Delivery Lifecycle, KB frontmatter source, connector connection_type and auth_method"
    severity: HIGH
    why: "A closed enum is what a writer validates against; a value documented here but rejected by the writer, or accepted but undocumented, breaks a run at the write rather than here"
  - id: F-02
    kind: validate
    criterion: "The emission-manifest record keys are exactly profile, src, dst, sha256, plus the _manifest_version sentinel"
    severity: HIGH
    why: "The installer and the prune logic both read these keys positionally by name; an undocumented key change orphans files at uninstall"
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
- [Work STATE.yml](#work-stateyml)
- [Delivery STATE.yml](#delivery-stateyml)
- [Task STATE.yml](#task-stateyml)
- [Discovery STATE.md](#discovery-statemd)
- [REQUIREMENTS.md](#requirementsmd)
- [Feature section (`REQUIREMENTS.md § 11`)](#feature-section-requirementsmd--11)
- [Delivery stanza (`PLAN.md` `### delivery-NNN`)](#delivery-stanza-planmd--delivery-nnn)
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

---

## State-File Hierarchy

AID tracks a work as a **tree of STATE.yml files**, each with a single writer. Parent
views are DERIVED (assembled at read time, never represented as an on-disk key), never written
directly. The discovery-area ledger (`.aid/knowledge/STATE.md`) is the one exception -- it
stays markdown (`kb-category: meta`; see [Discovery STATE.md](#discovery-statemd)).

Each `STATE.yml` file is divided into three zones (stated in full-line `#` comments at the top
of every template): **FRONTMATTER** (single-writer, top-level machine-parsed scalars, written
surgically key-by-key by `writeback-state.sh`), **AUTHORED** (single-writer YAML structures
under a key, one key per former markdown section -- `interview`, `lifecycle_history`, `deploy`,
`delivery_lifecycle` [incl. its `tasks_lifecycle` child], `delivery_gate`, `qa`, `quick_check`,
`dispatch_log`), and **DERIVED** (read-only, assembled at read time -- Features State,
Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log, Dispatches -- **NOT represented
on disk at all**, no key of any kind; a reader seeing no key derives the same union it derives
today).

**Full path** (nests deliveries under a `deliveries/` parent, mirroring `features/`):

```
.aid/works/work-NNN-{name}/STATE.yml                             (work level)
  -> deliveries/delivery-NNN/STATE.yml                           (delivery level)
       -> tasks/task-NNN/STATE.yml                               (task level -- sole write target for task cells)
.aid/knowledge/STATE.md                                          (discovery area -- KB + summary state; stays markdown)
```

**Flattened Lite path** (exactly one delivery, no `deliveries/` folder, no per-task STATE.yml -- the work IS the delivery):

```
.aid/works/work-NNN-{name}/STATE.yml                  (work level -- ALSO carries the sole delivery's
                                                        `delivery_lifecycle` key [with its `tasks_lifecycle`
                                                        mapping] / `delivery_gate` key / `qa` key,
                                                        AUTHORED directly; see Work STATE.yml below)
  -> tasks/task-NNN/DETAIL.md                          (task DEFINITION only -- IMMUTABLE, no sibling STATE.yml;
                                                        mutable cells live in the work-root STATE.yml's
                                                        `tasks_lifecycle` mapping)
.aid/knowledge/STATE.md                                          (discovery area -- KB + summary state; stays markdown)
```

Cardinality: one work STATE.yml per work; one delivery STATE.yml per delivery on the full path
(zero on the flattened Lite path -- its single delivery's state lives in the work STATE.yml
instead); one task STATE.yml per task on the full path (zero on the flattened Lite path -- task
cells live in the work STATE.yml's `tasks_lifecycle` mapping); one discovery STATE.md per
project (unchanged, out of this conversion).

The **closed task State enum** and its reconcile ordering (SD-2) are shared by all
three work-tree levels:

`Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`

Most-advanced-wins order on multi-branch reconcile:
`Done > Canceled > In Review > In Progress > Blocked > Failed > Pending`.

---

## Work STATE.yml

Source: `work-state-template.yml`. Three zones -- **FRONTMATTER** (single-writer top-level
scalars, written surgically by `writeback-state.sh`), **AUTHORED** (single-writer YAML
structures under a key), and **DERIVED** (read-time union over child files; never written,
and **not represented on disk at all** -- no key of any kind).

| Former section | Zone | YAML key(s) | Key fields / enums |
|---------|------|-------------|--------------------|
| Pipeline State | FRONTMATTER | `pipeline.path`, `pipeline.initiator`, `started`, `minimum_grade`, `user_approved`, `lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`, `block_artifact`, `ticket_ref` | `lifecycle`: `Running \| Paused-Awaiting-Input \| Blocked \| Completed \| Canceled`; `phase`: `Describe \| Define \| Specify \| Plan \| Detail \| Execute`; `active_skill`: `aid-{skill} \| none`; `updated` (ISO-8601); `pause_reason`/`block_reason`/`block_artifact` conditional (`--` when not applicable). |
| Interview State | AUTHORED | `interview` (`state`, `grade`, `sections[]`) | 10-entry `sections[]` (Objective..Priority), each `state: Pending \| ...`, `updated`; `interview.state` + `interview.grade`. |
| Seed Authoring | **schema gap, not a template key** (tracked as tech-debt **SY-4**) | none declared | `aid-describe` DESCRIBE-SEED tracks `Status`/a 5-element checklist/`Coherence check`/`Review grade` for a greenfield work, but its own reference doc documents this as an ad hoc markdown block appended into the pre-conversion `STATE.md` -- never one of the three templates' declared keys, and now un-appendable into a pure-YAML `STATE.yml` without corrupting it. Carried as an open schema gap, not fixed by this conversion. |
| Lifecycle History | AUTHORED | `lifecycle_history[]` | append-only sequence (`date`, `event`, `grade`, `notes`), newest last. |
| Deploy State | AUTHORED (by `aid-deploy` only) | `deploy[]` | one entry per delivery (`delivery`, `state`, `pr`, `kb_updated`, `tag`, `notes`). |
| Delivery Lifecycle, Tasks lifecycle, Delivery Gate | AUTHORED -- **single-delivery FLATTENED (Lite) works only** (keys omitted entirely for full multi-delivery works) | `delivery_lifecycle` (+ nested `tasks_lifecycle`), `delivery_gate` | same shape as the full-path Delivery STATE.yml keys below, authored directly here because a flattened work has exactly one delivery and no `deliveries/` folder. `delivery_lifecycle` (`Pending-Spec`→`Specified` by the shortcut engine PLAN step, `Executing`→`Gated`→`Done`/`Blocked` by `aid-execute`); `tasks_lifecycle` (one entry per `task-NNN`, each with `state`/`review`/`elapsed`/`notes`/`display_name` -- the single-writer home for task cells, replacing the now-absent per-task `STATE.yml`; written by the engine DETAIL step and `writeback-state.sh --task-id NNN` flat-layout branch, targeting `tasks_lifecycle.task-NNN.<field>`); `delivery_gate.issue_list` (`aid-execute` delivery-gate result). |
| Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log, Dispatches | **DERIVED** (full path); on the flattened Lite path Plan/Deliveries, Delivery Gates, and the plural Tasks State view stay `_none yet_` (no per-delivery/per-task `STATE.yml` to union -- the authoritative task cells are the AUTHORED `tasks_lifecycle` mapping above) | none -- **no key at all**, on either layout | read-only unions over per-delivery / per-task `STATE.yml`; never written here, and never represented on disk (a reader seeing no key derives the same union it derives today). |
| Cross-phase Q&A | **DERIVED** for full-path works (union of each delivery's Q&A + work-owner entries); **AUTHORED** for flattened Lite works (no delivery `STATE.yml` to derive from -- the single delivery's Q&A is written directly into this key) | `qa[]` -- **AUTHORED only on the flattened Lite path**; no key at all on the full path (DERIVED) | per-entry: `category`, `impact`, `state`, `context`, `suggested`, `answer`, `applied_to`. |

Producer: `execute/writeback-state.sh --pipeline ...` + the orchestrator (single
writer on the work's active branch). The `interview` key and greenfield Seed Authoring
tracking are authored by `aid-describe`; the flattened-work `delivery_lifecycle` /
`tasks_lifecycle` / `delivery_gate` keys are authored by the shortcut engine and `aid-execute`.
Consumer: the dashboard reader, `aid-execute`.

---

## Delivery STATE.yml

Source: `delivery-state-template.yml` -- **FULL PATH ONLY**. Lives at
`deliveries/delivery-NNN/STATE.yml`; AUTHORED by this delivery's branch only. A flattened Lite
work has no delivery-level `STATE.yml` at all -- its single delivery's `delivery_lifecycle` /
`delivery_gate` / `qa` keys are AUTHORED directly in the work-root `STATE.yml`
instead (see the Work STATE.yml table above); its task cells live in the work-root
`STATE.yml`'s `tasks_lifecycle` mapping (no delivery layer, and no per-task `STATE.yml` to nest
under).

| Former section | Zone | YAML key(s) | Key fields / enums |
|---------|------|-------------|--------------------|
| Delivery Lifecycle | FRONTMATTER + AUTHORED | `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref` (FRONTMATTER); `delivery_lifecycle.{updated,block_reason,block_artifact}` (AUTHORED) | `delivery_state`: `Pending-Spec \| Specified \| Executing \| Gated \| Done \| Blocked` (independently authored -- NOT a task rollup, per SD-9); conditional `block_reason`/`block_artifact`. |
| Delivery Gate | FRONTMATTER + AUTHORED | `gate_tier`, `gate_grade`, `gate_timestamp` (FRONTMATTER); `delivery_gate.issue_list` (AUTHORED) | `gate_tier`: `Small \| Medium \| Large`; `gate_grade`; `issue_list` (severity-tagged strings, or `[]` when clean); `gate_timestamp`. |
| Cross-phase Q&A | AUTHORED | `qa[]` | per-entry: `category`, `impact` (`High \| Medium \| Low \| Required`), `state` (`Pending \| Answered \| Skipped`), `context`, `suggested`, `answer`, `applied_to`. |
| Tasks State | **DERIVED** -- no key at all | none | rollup from `tasks/task-NNN/STATE.yml` (relative to this delivery folder); never written here, never represented on disk. |

Producer: `aid-plan` (creates, `Pending-Spec`, at `deliveries/delivery-NNN/STATE.yml`),
`aid-specify` (`Specified`), `aid-execute` (`Executing`->`Gated`->`Done` / `Blocked`), via
`writeback-state.sh --delivery-id NNN`. On the flattened Lite path, the **shortcut engine**
writes the `delivery_lifecycle` (initial `Pending-Spec`) + `delivery_gate` keys directly
into the work-root `STATE.yml` during its PLAN/DETAIL steps (and `aid-execute` later advances the
lifecycle) -- no `delivery-001/STATE.yml` file is created; `writeback-state.sh --delivery-id 001`
auto-detects the flattened layout (declared `pipeline.path: lite`, or for an un-migrated work no `deliveries/` folder)
and targets the work-root `STATE.yml` instead.

---

## Task STATE.yml

Source: `task-state-template.yml` -- **FULL PATH** (lives at
`deliveries/delivery-NNN/tasks/task-NNN/STATE.yml`). Every key is a top-level scalar (no
separate frontmatter/body split at this level) -- the **sole write target** for all per-task
mutable state on the full path; all keys written by the owning delivery branch. A flattened
Lite work has **no per-task `STATE.yml`** -- each task is a `tasks/task-NNN/DETAIL.md`
definition only, and its mutable cells (`state`/`review`/`elapsed`/`notes`/`display_name`) live
in the work-root `STATE.yml`'s `tasks_lifecycle` mapping instead.

| Former section | YAML key(s) | Key fields |
|---------|-------------|-----------|
| Task State | `state`, `review`, `elapsed`, `notes`, `display_name`, `ticket_ref` | `state` (the closed 7-value enum above); `review` (tier + outcome, or `--`); `elapsed` (`HH:MM \| --`); `notes`; `display_name` (mutable override; documented as a documentation fix, not a schema change -- the writer already wrote it, it was simply never declared in the pre-conversion template). Written only by `writeback-state.sh --task-id NNN --field State --value V`. |
| Quick Check Findings | `quick_check.{reviewer_tier,findings[]}` | `reviewer_tier`: `Small` (quick check is always Small); `findings[]`: `severity: CRITICAL \| HIGH` / `description` / `source` / `disposition: Fixed-on-spot \| Deferred-to-gate`. No grade (grading is per-delivery). |
| Dispatch Log | `dispatch_log[]` | append-only sequence (`date`, `agent`, `eta_band`, `actual`, `outcome`); the work-level Calibration Log/Dispatches are derived unions of these. |

---

## Discovery STATE.md

Source: `discovery-state-template.md`. Lives at `.aid/knowledge/STATE.md`; tracks the
KB + the visual summary (absorbs the former DISCOVERY-STATE + SUMMARY-STATE). Unlike the three
work-tree levels above, this file is **not** part of the `STATE.yml` conversion -- it stays
markdown, with `---`-fenced YAML frontmatter, and stays a KB document in its own right
(`kb-category: meta`). The dashboard reader's KB-ledger parse path (`parsers.parse_kb_state`)
deliberately keeps the original, looser fenced-frontmatter scan for exactly this one caller.

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
artifact set (`REQUIREMENTS.md` →
`tasks/task-NNN/DETAIL.md`), collapsed and mostly autonomous, not a reduced one. The greenfield
full path additionally produces a forward-authored KB seed -- see
[Greenfield KB Seed](#greenfield-kb-seed-forward-authored).

Required structure: `# Requirements` with `Name` + `Description`, then 10
numbered sections:

1. Objective · 2. Problem Statement · 3. Users & Stakeholders (table) · 4. Scope
(In/Out) · 5. Functional Requirements · 6. Non-Functional Requirements · 7.
Constraints · 8. Assumptions & Dependencies · 9. Acceptance Criteria · 10. Priority.

Rules: **no `## Change Log` section** -- document history is git's
(`git log --follow -p`); unaddressed sections carry `*(pending)*`; sections may be
`N/A`; acceptance criteria must be testable; the stakeholder's own words are
preferred in Objective/Problem Statement.

---

## Feature section (`REQUIREMENTS.md § 11`)

Source: `feature.md`. A feature is a SECTION, not a file. `aid-define` (Phase 2b, full path
only) decomposes the approved `REQUIREMENTS.md` into one `### Feature NNN` section per feature
under `§ 11 Features`, writing the requirements half; `aid-specify` adds the technical half
later. (`aid-define` also runs CROSS-REFERENCE to validate the feature boundaries against the
KB and codebase.) The flattened Lite path is the same shape with exactly one section, written
by the shortcut engine's SPEC state.

There is no per-feature file. A separate `SPEC.md` per feature meant each criterion existed in
`§ 9` and again in every feature claiming it, and two sibling copies asserting different values
for one fact produced both CRITICAL findings in this project's largest work (D29).

Requirements half (required, authored by `aid-define`): `### Feature NNN — {Title}`,
`**Priority:**` (`Must | Should | Could`), `**Requirements:**` (the `§ 5 FR-N` it implements),
`**Criteria:**` (the `§ 9 AC-N` it owns -- CITED by id, never copied), `#### Description`,
`#### User Stories` (As a/I want/so that).

Specify half (added by `/aid-specify`, do not fill during define):
`#### Technical Specification` with `##### Data Model`, `##### Feature Flow`,
`##### Layers & Components`, plus whichever conditional subsections the feature activates.

The `AC-N` citation is load-bearing beyond traceability: it is the key
`slice-requirements.sh` uses to give a task only the criteria it implements, so a copied
criterion would have to be re-read to be trusted and could disagree with `§ 9`.

---

## Delivery stanza (`PLAN.md` `### delivery-NNN`)

The **immutable** delivery definition, written by `aid-plan` into that delivery's stanza in
`PLAN.md`. Not a state file -- the delivery's mutable lifecycle/gate lives in the delivery
`STATE.yml` (full path) or the work-root `STATE.yml` (flattened).

There is no `BLUEPRINT.md`. Its PRESENCE was the flat-layout signal in three separate
implementations, which made an ordinary document impossible to move or retire without silently
changing how a work was classified; layout is now read from the declared `pipeline.path` (D29).

Required within the stanza:

- `**Objective:**` -- what this delivery achieves and why it is a distinct unit.
- `**Scope:**` / `**Out of scope:**` -- bounded deliverables, and what is excluded.
- `**Gate Criteria**` -- ordered, concrete, independently testable checkboxes; the delivery gate
  (`grade.sh`) uses these as its rubric. The last is always "All section-6 quality gates pass".
- `**Notes:**` -- design notes/constraints not captured in the gate criteria. Omit when none.

NOT recorded in the stanza, because both are DERIVED and a stored copy can disagree with its
source: the task listing (from each task's `**Source:** ... -> delivery-NNN`) and the reverse
dependency edges (from the `**Depends on:**` fields across stanzas).

On the flattened Lite path there is no `PLAN.md` at all: one feature and one delivery means no
sequencing decision to record, and the work's `§ 9` criteria ARE the delivery's.

The delivery gate reads its criteria from that stanza on the full path and from
`REQUIREMENTS.md § 9` on the flat path, NOT from the delivery `STATE.yml` (whose `delivery_gate`
key records the *result*).

---

## Task DETAIL.md

Source: `task-detail-template.md`. The **immutable** task definition -- written once by
`aid-detail` (full path, at `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`) or by the shortcut
engine's DETAIL step (flattened Lite path, at `tasks/task-NNN/DETAIL.md`). Mutable state lives in
the sibling `task-NNN/STATE.yml` on the full path, or in the work-root `STATE.yml`'s
`tasks_lifecycle` mapping on the flattened path (no sibling `STATE.yml` there).

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
REQUIREMENTS.md    -> § 11 feature section (define half) -> its #### Technical Specification (specify half)
§ 11 sections    -> PLAN.md (a stanza per delivery) -> tasks/task-NNN/DETAIL.md (immutable)
task-NNN DETAIL.md  ~ task-NNN/STATE.yml (mutable state for the same task)
task STATE.yml     -> delivery STATE.yml (derived) -> work STATE.yml (derived)

Flattened Lite path (no deliveries/, no delivery-NNN/ folder, no per-task STATE.yml -- the work IS the sole delivery):
REQUIREMENTS.md    -> its single § 11 section -> tasks/task-NNN/DETAIL.md (immutable, directly under the work folder)
task-NNN DETAIL.md cells -> work STATE.yml `tasks_lifecycle` mapping (AUTHORED; no sibling STATE.yml)
delivery lifecycle/gate  -> work STATE.yml `delivery_lifecycle` / `delivery_gate` keys (AUTHORED directly)

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
| delivery | PLAN.md `### delivery-NNN` stanza | one-to-one |
| delivery | task | one-to-many |
| task DETAIL.md | task STATE.yml | one-to-one, full path only (flattened Lite has no per-task STATE.yml) |
| REQUIREMENTS.md | its own `§ 11` feature sections | one-to-many |
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
- **DERIVED sections are read-only.** A producer MUST write the per-unit `STATE.yml`,
  never a parent's derived view (work/delivery Tasks State, Delivery Gates,
  Cross-phase Q&A, Calibration Log -- the pre-conversion markdown carried these as `## Tasks
  State` / `## Delivery Gates` / `## Cross-phase Q&A` / `## Calibration Log` headings; the
  current `STATE.yml` templates omit them entirely, no key of any kind). The disjoint-write
  property (two delivery branches never collide on a shared file) depends on this. (The
  flattened Lite work is the single-writer exception: with exactly one delivery and one
  branch, its `delivery_lifecycle` / `tasks_lifecycle` / `delivery_gate` keys are AUTHORED
  directly in the work-root `STATE.yml`.)
- **One writer per file.** Each `STATE.yml` level has a single writer (the owning
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
| `STATE.yml` (write time) | `writeback-state.sh`'s own closed-enum validation (`Lifecycle`, `Phase`, `Active Skill`, `Minimum Grade`, `User Approved`, `Pipeline Path`, `Pipeline Initiator`, task `State`, etc.) | an out-of-enum value dies with exit 4 before any byte is written -- the write never lands. |
| `STATE.yml` (parse time, permitted YAML subset) | the shared cross-runtime conformance corpus (`state_yaml_conformance_corpus.py`, run identically by both the Python and Node twins) | every permitted shape (S1-S5), every rejected construct, every quoting mode and every implicit-typing literal is asserted against both readers; a rejected construct yields a `parse_warning` naming the file/line/construct and skips exactly that key -- it never raises. |
| `STATE.yml` (read time, semantic) | dashboard reader (Python/Node twins) | reader degrades gracefully; an unknown enum value is not in the closed set and mis-reconciles -- caught by the reader test suites and parity tests. A `STATE.md` with no sibling `STATE.yml` is diagnosed (a `parse_warning` naming the migration command), never parsed. |
| Frontmatter (on KB docs) | `lint-frontmatter.sh` | `[FM-MISSING]`/`[FM-INVALID]` HIGH findings; parse failure -> doc treated as primary/hand-authored + HIGH warning. |
| Reviewer ledger | `grade.sh` | only `[SEVERITY]`-tagged rows with Status `Pending`/`Recurred` count; a stray `## Summary` line would over-count (banned). |
| emission-manifest.jsonl | renderer determinism checks (`verify_deterministic.py`, `test_manifest_safety.py`) | a non-byte-stable or mis-keyed manifest fails the render-drift CI gate. |
| Install manifest | install-core (`manifest_exists`) | missing manifest on uninstall -> exit 6. |
| task DETAIL.md `Type` | `aid-execute` task-type rules | a missing/mixed type blocks execution (one type per task). |
| KB-doc citations | `kb-citation-lint.sh` | bare `file:LINE` -> exit 1, GENERATE blocked until fixed. |

There is **no central schema validator**; validation is distributed -- a lint, a
reader, or a skill gate owns each artifact class. **No JSON Schema artifact and no CI
schema-validation gate exists for `STATE.yml`, and none is planned** -- the writer's enum
validation (write time) plus the shared conformance corpus (parse time) are the only two
machine checks, and that is a considered decision, not a gap awaiting one: a schema tool
was offered and declined, because the closed enums + the two checks above already catch
every failure mode a schema would (revisit only if a defect shows the enum validation is
insufficient). The freshness baseline
(`kb_baseline`, `approved_at_commit`) degrades gracefully when absent (treated as
"baseline unknown", never a hard failure); a `source: forward-authored` doc is folded
to `current` by `kb-freshness-check.sh` regardless of baseline.
