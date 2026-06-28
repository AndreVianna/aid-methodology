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
  - canonical/aid/templates/kb-authoring/frontmatter-schema.md
  - canonical/skills/aid-describe/references/state-describe-seed.md
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
changelog:
  - 2026-06-27: aid-describe/aid-define split -- rekeyed REQUIREMENTS.md + lite work-root SPEC.md producers to aid-describe and feature SPEC stubs to aid-define; added the forward-authored source value + greenfield 5-element seed doc-set
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
| Seed Authoring | AUTHORED (greenfield only, by `aid-describe` DESCRIBE-SEED) | `Status`: `In Progress \| Complete`; 5-element checklist (domain-glossary/architecture mandatory, coding-standards/technology-stack deferrable, decisions conditional); `Coherence check`; `Review grade`. |
| Lifecycle History | AUTHORED | append-only audit table (Date, Phase Transition/Gate, Grade, Notes), newest last. |
| Deploy State | AUTHORED (by `aid-deploy` only) | one row per delivery (Delivery, State, PR, KB Updated, Tag, Notes). |
| Features State, Plan/Deliveries, Tasks State, Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches | **DERIVED** | read-only unions over per-delivery / per-task STATE.md; never written here. |

Producer: `execute/writeback-state.sh --pipeline ...` + the orchestrator (single
writer on the work's active branch). The `## Interview State`, `## Triage`, and
greenfield `## Seed Authoring` blocks are authored by `aid-describe`. Consumer: the
dashboard reader, `aid-execute`.

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
`writeback-state.sh --delivery-id NNN`. On the lite path, `aid-describe` creates
`delivery-001/STATE.md` directly (State `Executing`) during TASK-BREAKDOWN / recipe emit.

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
`.aid/knowledge/REQUIREMENTS.md` (uppercase). Produced by `aid-describe` (Phase 2a,
**full path**). On the **lite path**, `aid-describe` produces no REQUIREMENTS.md --
it instead emits a work-root `SPEC.md` (`.aid/{work}/SPEC.md`) plus a
`delivery-001/` task hierarchy (`tasks/task-NNN/SPEC.md` + `STATE.md`) via CONDENSED-INTAKE
+ TASK-BREAKDOWN (or recipe slot-fill + emit). The greenfield full path additionally
produces a forward-authored KB seed -- see [Greenfield KB Seed](#greenfield-kb-seed-forward-authored).

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
Per-feature artifact: the requirements-half stub is created by `aid-define` (Phase 2b,
full path only) when its FEATURE-DECOMPOSITION state decomposes the approved
`REQUIREMENTS.md` into `features/feature-NNN-name/` folders; the technical half is added
later by `aid-specify`. (`aid-define` also runs CROSS-REFERENCE to validate the feature
boundaries against the KB and codebase.)

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
REQUIREMENTS.md  -> feature SPEC.md (define/decomposition half) -> SPEC.md (specify half)
SPEC.md          -> PLAN.md -> delivery-NNN/ -> task-NNN SPEC.md (immutable)
task-NNN SPEC.md  ~ task-NNN/STATE.md (mutable state for the same task)
task STATE.md    -> delivery STATE.md (derived) -> work STATE.md (derived)
settings.yml     -> read by every skill via read-setting.sh
candidate-concepts.md -> domain-glossary.md (ground) OR spine-todo.md (dismiss)
greenfield intent -> forward-authored KB seed (5 docs in .aid/knowledge/) -> read by aid-specify/plan/execute
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
| task SPEC.md `Type` | `aid-execute` task-type rules | a missing/mixed type blocks execution (one type per task). |
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
