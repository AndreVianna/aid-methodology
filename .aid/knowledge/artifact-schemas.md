---
kb-category: primary
source: hand-authored
objective: The structural schema of every artifact the AID methodology produces -- STATE files, SPEC/REQUIREMENTS/feature/task files, settings, and the three manifest formats -- with required fields, closed enums, producers, consumers, and validation points.
summary: Read this to learn the required shape of any AID artifact (work/delivery/task/discovery STATE.md, REQUIREMENTS.md, SPEC.md, task spec, settings.yml, install + emission + generated-files manifests) before producing or parsing one.
sources:
  - .claude/aid/templates/work-state-template.md
  - .claude/aid/templates/delivery-state-template.md
  - .claude/aid/templates/task-state-template.md
  - .claude/aid/templates/discovery-state-template.md
  - .claude/aid/templates/requirements/requirements-template.md
  - .claude/aid/templates/feature.md
  - .claude/aid/templates/task-spec-template.md
  - .claude/aid/templates/settings.yml
  - canonical/EMISSION-MANIFEST.md
  - .claude/aid/templates/generated-files.txt
  - lib/aid-install-core.sh
tags: [C5, artifact-schemas, state-files, manifests, settings, enums, contracts]
see_also: [authoring-conventions.md, module-map.md, pipeline-contracts.md]
owner: architect
audience: [developer, architect]
contracts:
  - "Task State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled"
  - "Task Type enum (closed, 8): RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE"
  - "Delivery Lifecycle enum (closed): Pending-Spec | Specified | Executing | Gated | Done | Blocked"
  - "emission-manifest.jsonl record keys: profile, src, dst, sha256 (+ _manifest_version sentinel)"
changelog:
  - 2026-06-25: Initial authoring (aid-discover brownfield deep-dive / Analyst); replaces the schemas.md data-model seed
---

# Artifact Schemas

AID has no database. Its "data model" is the set of **Markdown, YAML, and JSON
artifacts** the pipeline reads and writes -- the state files that track a work, the
requirement/spec/task documents, the configuration, and the manifests that bound the
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
- [Task SPEC.md](#task-specmd)
- [settings.yml](#settingsyml)
- [Install Manifest (JSON)](#install-manifest-json)
- [Emission Manifest (JSONL)](#emission-manifest-jsonl)
- [Generated-Files Registry](#generated-files-registry)
- [Discovery Scratch Artifacts](#discovery-scratch-artifacts)
- [How Artifacts Relate](#how-artifacts-relate)
- [Contracts](#contracts)
- [Conventions](#conventions)
- [Validation](#validation)
- [Change Log](#change-log)

---

## State-File Hierarchy

AID tracks a work as a **tree of STATE.md files**, each with a single writer. Parent
views are DERIVED (assembled at read time), never written directly.

```
.aid/work-NNN-{name}/STATE.md                         (work level)
  -> delivery-NNN/STATE.md                            (delivery level)
       -> tasks/task-NNN/STATE.md                     (task level -- sole write target for task cells)
.aid/knowledge/STATE.md                               (discovery area -- KB + summary state)
```

Cardinality: one work STATE.md per work; one delivery STATE.md per delivery; one
task STATE.md per task; one discovery STATE.md per project.

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
| Pipeline State | AUTHORED | `Lifecycle`: `Running \| Paused-Awaiting-Input \| Blocked \| Completed \| Canceled`; `Phase`: `Interview \| Specify \| Plan \| Detail \| Execute \| Deploy \| Monitor`; `Active Skill`: `aid-{skill} \| none`; `Updated` (ISO-8601); conditional `Pause/Block Reason`, `Block Artifact`. |
| Triage | AUTHORED | `Path`: `lite \| full`; `Work Type`: `bug-fix \| new-feature \| refactor`; `Sub-path`: `LITE-BUG-FIX \| LITE-REFACTOR \| LITE-FEATURE \| --`; `Override`; `Recipe`. |
| Escalation Carry | AUTHORED | present only on lite->full escalation; captured slot values; artifacts-at-escalation. |
| Interview State | AUTHORED | 10-row section table (Objective..Priority), each `Pending \| ...`; State + Grade. |
| Lifecycle History | AUTHORED | append-only audit table (Date, Phase Transition/Gate, Grade, Notes), newest last. |
| Deploy State | AUTHORED (by `aid-deploy` only) | one row per delivery (Delivery, State, PR, KB Updated, Tag, Notes). |
| Features State, Plan/Deliveries, Tasks State, Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches | **DERIVED** | read-only unions over per-delivery / per-task STATE.md; never written here. |

Producer: `execute/writeback-state.sh --pipeline ...` + the orchestrator (single
writer on the work's active branch). Consumer: the dashboard reader, `aid-execute`.

---

## Delivery STATE.md

Source: `delivery-state-template.md`. AUTHORED by this delivery's branch only.

| Section | Key fields / enums |
|---------|--------------------|
| Delivery Lifecycle | `State`: `Pending-Spec \| Specified \| Executing \| Gated \| Done \| Blocked` (independently authored -- NOT a task rollup, per SD-9); `Updated`; conditional Block Reason/Artifact. |
| Delivery Gate | `Reviewer Tier`: `Small \| Medium \| Large`; `Grade`; `Issue List` (inline severity-tagged or `none`); `Timestamp`. |
| Cross-phase Q&A | per-Q block: `Category`, `Impact` (`High \| Medium \| Low \| Required`), `State` (`Pending \| Answered \| Skipped`), Context, Suggested, Answer, Applied-to. |
| Tasks State | **DERIVED** rollup from `tasks/task-NNN/STATE.md`; never written here. |

Producer: `aid-plan` (creates, `Pending-Spec`), `aid-specify` (`Specified`),
`aid-execute` (`Executing`->`Gated`->`Done` / `Blocked`), via
`writeback-state.sh --delivery-id NNN`.

---

## Task STATE.md

Source: `task-state-template.md`. The **sole write target** for all per-task mutable
state. All sections AUTHORED by the owning delivery branch.

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
`.aid/knowledge/REQUIREMENTS.md` (uppercase). Produced by `aid-interview`.

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

Source: `feature.md` (and the leaner `task-spec-template.md`-adjacent `feature` seed).
Per-feature artifact created by `aid-interview`, with the technical half added by
`aid-specify`.

Interview half (required): `# {Feature Title}`, `## Change Log`, `## Source`
(REQUIREMENTS refs), `## Description`, `## User Stories` (As a/I want/so that),
`## Priority` (`Must \| Should \| Could`), `## Acceptance Criteria`
(Given/When/Then checkboxes).

Specify half (added by `/aid-specify`, do not fill during interview):
`## Technical Specification` with `### Data Model`, `### Feature Flow`,
`### Layers & Components`, plus conditional sections (API Contracts, UI Specs,
Events & Messaging, BDD Scenarios, Migration Plan, Security Specs, ...) activated
only when relevant.

---

## Task SPEC.md

Source: `task-spec-template.md`. The **immutable** task definition (written once by
`aid-detail`); mutable state lives in the sibling `task-NNN/STATE.md`.

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
changed.

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

## How Artifacts Relate

```
REQUIREMENTS.md  -> feature SPEC.md (interview half) -> SPEC.md (specify half)
SPEC.md          -> PLAN.md -> delivery-NNN/ -> task-NNN SPEC.md (immutable)
task-NNN SPEC.md  ~ task-NNN/STATE.md (mutable state for the same task)
task STATE.md    -> delivery STATE.md (derived) -> work STATE.md (derived)
settings.yml     -> read by every skill via read-setting.sh
candidate-concepts.md -> domain-glossary.md (ground) OR spine-todo.md (dismiss)
canonical/ files -> emission-manifest.jsonl (one record each) -> profiles/<tool>/
install manifest <- install-core; consumed by uninstall/update
```

Cardinality summary:

| Parent | Child | Cardinality |
|--------|-------|-------------|
| work | delivery | one-to-many |
| delivery | task | one-to-many |
| task SPEC.md | task STATE.md | one-to-one (same task) |
| REQUIREMENTS.md | feature SPEC.md | one-to-many |
| profile | emission-manifest record | one-to-many |
| install manifest | tool entry | one-to-many |

---

## Contracts

> The structural shape a change MUST satisfy.

- **Closed enums are byte-stable.** Adding/renaming a value in the task State,
  Delivery Lifecycle, task Type, Pipeline Lifecycle/Phase, or Q&A Impact/Status
  enums is a breaking change -- the dashboard readers (Python + Node twins) and
  `writeback-state.sh` all bind to the exact strings. Both reader twins must change
  in lockstep.
- **DERIVED sections are read-only.** A producer MUST write the per-unit STATE.md,
  never a parent's derived view (work/delivery `## Tasks State`, `## Delivery Gates`,
  `## Cross-phase Q&A`, `## Calibration Log`). The disjoint-write property (two
  delivery branches never collide on a shared file) depends on this.
- **One writer per file.** Each STATE.md level has a single writer (the owning
  branch); cross-writes break the merge model.
- **Emission record = exactly 4 keys + sentinel.** Adding a key bumps
  `_manifest_version`; a consumer reading a higher version uses a different parser.
- **Required-section contract.** REQUIREMENTS.md keeps all 10 numbered sections
  (pending ones marked `*(pending)*`, not deleted); a task SPEC.md carries exactly
  one `Type`.

---

## Conventions

> How to add or change an artifact or field.

- **Adding a STATE field:** add it to the AUTHORED zone of the right level's
  template, teach `writeback-state.sh` to write it, and update **both** dashboard
  reader twins (`parsers.py` + `reader.mjs`) to parse it.
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
| task SPEC.md `Type` | `aid-execute` task-type rules | a missing/mixed type blocks execution (one type per task). |
| KB-doc citations | `kb-citation-lint.sh` | bare `file:LINE` -> exit 1, GENERATE blocked until fixed. |

There is **no central schema validator**; validation is distributed -- a lint, a
reader, or a skill gate owns each artifact class. The freshness baseline
(`kb_baseline`, `approved_at_commit`) degrades gracefully when absent (treated as
"baseline unknown", never a hard failure).

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial artifact-schemas doc (Analyst); replaces the schemas.md data-model seed |
