# Requirements

- **Name:** Convert Work-Tree STATE Files to YAML and Exclude Them From Review
- **Description:** Restructure the work-tree state trackers under `.aid/works/` from markdown `STATE.md` into YAML `STATE.yml` and remove them from the reviewable-artifact surface

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Initial capture (shortcut: aid-refactor) | /aid-refactor |
| 2026-08-12 | GATE Pass 1 -- definition documents corrected across the pass's REVIEW/FIX cycles | /aid-refactor GATE |

## 1. Objective

In the stakeholder's own words:

> "I want the STATE.md file used to keep track of the state of several phases in aid to be
> converted to either json or yml and be excluded from the review process."

Captured family slots (`change-refactor.md § aid-refactor -- CAPTURE`):

| Slot | Value |
|---|---|
| **Target** | The work-tree state trackers: `.aid/works/work-NNN-{name}/STATE.md` (all paths), plus `deliveries/delivery-NNN/STATE.md` and `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` on the full path. Their templates: `canonical/aid/templates/work-state-template.md`, `delivery-state-template.md`, `task-state-template.md`. |
| **Refactor kind** | `restructure` (the description names neither a rename nor a performance goal; the family default applies) |
| **Rationale** | State is machine data with a machine writer and two machine readers, but it is currently stored as prose. That mismatch costs on both sides: every writer and reader hand-rolls markdown-table and markdown-section parsing (`writeback-state.sh`'s four awk programs; `parsers.py`'s `_parse_tasks_line` / `_parse_features_line` / `_parse_deliveries_line` / `_parse_lifecycle_history_line`; the same set again in `reader.mjs`), and because the file *looks* like a document it keeps landing in reviewer scope and getting graded as prose. YAML makes the data a first-class structure and makes the review exclusion principled rather than a per-brief carve-out. |
| **Behavior-preservation guarantee** | The existing suites are the oracle -- coverage is not thin: 47 files / 777 `STATE.md` references under `tests/`, plus 51 files / 627 references under `dashboard/`. The pass/fail set after the refactor must match the pre-refactor baseline (see §9 AC-1). Because a pure filename/format swap necessarily edits format-asserting tests, one **characterization test** is added on top: the reader payload built from a legacy-markdown fixture must equal the payload built from its converted YAML twin, in both reader runtimes (§9 AC-2). |

The chosen format is **YAML (`STATE.yml`)**, not JSON, per the stakeholder's answer to the single
CAPTURE question. Three reasons carried the decision: the machine-parsed scalars are *already* a
YAML frontmatter block, so those fields lift across unchanged; YAML permits comments, so the
templates' inline enum hints survive; and it matches `.aid/settings.yml`, the format the project
already uses for configuration. Accepted trade-off: the AUTHORED markdown body sections
(Lifecycle History, `### Tasks lifecycle`, Delivery Gate, Interview State, Deploy State) become
YAML structures instead of markdown tables.

## 2. Problem Statement

Today a single file mixes three incompatible zones. `canonical/aid/templates/work-state-template.md`
names them itself (lines 26-42):

| Zone | What it holds | Who writes it | Storage today |
|---|---|---|---|
| **FRONTMATTER** | machine-parsed scalars: `pipeline.path`, `initiator`, `lifecycle`, `phase`, `active_skill`, `updated`, `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`, ... | `writeback-state.sh` only, via a surgical YAML-block rewrite | already YAML |
| **AUTHORED** | Interview State, Lifecycle History, Deploy State, `## Delivery Lifecycle` + `### Tasks lifecycle`, `## Delivery Gate` residue (Issue List, Block Reason/Artifact) | single writer per file (the work's active branch) | markdown tables + bullets |
| **DERIVED** | Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log, Dispatches -- plus Cross-phase Q&A, which is DERIVED on the full path but AUTHORED on the flattened Lite path (`artifact-schemas.md § Work STATE.md`) | **nobody** (the Q&A caveat aside) -- assembled at read time as a union over child files | markdown placeholder tables that exist only to be ignored |

Concrete pain, each with evidence:

1. **The writer carries four hand-rolled awk programs, not one.** `writeback-state.sh` has a YAML
   frontmatter awk program (`WB_SET_FRONTMATTER_AWK`, ~90 lines, used from both `:719` and
   `:725`), a separate markdown-table-row awk program for `### Tasks lifecycle`
   (`write_task_field_flat`, `:877-1022` = 146 lines of column-index arithmetic with
   `col_idx=3..7` positional cells), and **two** distinct section-replace awk programs -- one for
   `## Quick Check Findings` (`:1056`) and one for `## Delivery Gate` (`:1259`). And the markdown
   container leaks into the CLI
   contract: `mode_field` rejects any value containing `|` or a newline before it even resolves
   the target file ("pipe is the column separator"), a restriction the data does not have and
   which now applies even on the frontmatter path.
2. **The two reader twins must agree on markdown, not just on data.** `dashboard/reader/parsers.py`
   (2,964 lines) and `dashboard/server/reader.mjs` (5,526 lines) each re-implement
   `parse_state_md` / `parseStateText`, `parse_tasks_lifecycle_md`, `parse_delivery_gate`,
   `parse_quick_check_findings`, `hasTableSep`, `extractLatestHistoryDate`, and per-section
   line handlers. Every table shape is a parity surface maintained by hand across Python and
   Node.
3. **DERIVED sections are dead bytes on disk.** They are written as `_none yet_` placeholder
   tables purely so the file "looks complete"; the template states they are "NEVER written
   directly". A structured format can simply omit them.
4. **State keeps entering review as prose.** `canonical/skills/aid-execute/references/reviewer-brief.md:66`
   puts "every task's `STATE.md` row" into the per-delivery reviewer's `{{ARTIFACTS}}`; the
   per-delivery gate also hands the reviewer the full branch diff, which contains every state
   mutation the run made. Reviewers then grade a machine ledger against document rubrics. The
   Knowledge Base already solved this for its own state file -- `.aid/knowledge/STATE.md` carries
   `kb-category: meta` and is filtered out of the reviewed surface by `list_reviewable`
   (`canonical/skills/aid-discover/references/doc-set-resolve.md:311`, the function definition;
   its section starts at `:288`), enforced by
   `tests/canonical/test-kb-review-surface.sh` RS03. The work-tree state files have no equivalent
   rule.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| Pipeline agent (orchestrator / architect / developer / reviewer) | Writes state at every transition per the tracking-discipline mandate; reads it to resume | A write that cannot corrupt the file; no pipe-or-newline value restrictions; the same closed enums it binds to today |
| `writeback-state.sh` (+ its 7 renders and 1 deliberate fork) | The sole machine writer of every scalar | One parse/serialize path instead of four; the surgical single-key write and the sentinel lock preserved |
| Dashboard reader twins (`dashboard/reader/*.py`, `dashboard/server/reader.mjs`) | Build the `WorkModel` the dashboard renders, unioning every worktree branch | A structured read with no per-section markdown grammar; byte-parity between the two runtimes still provable |
| Shell consumers (`enumerate-works.sh`, `cleanup-classify.sh`, `dashboard/scripts/delete-pipeline.sh`) | Cheap scalar lookups for listings, cleanup safety signals and the delete guard | Keep working without a YAML dependency |
| Reviewer (`aid-reviewer`) | Grades artifacts against rubrics | State files never in `{{ARTIFACTS}}`; state churn in a diff never counted as a finding |
| AID maintainer | Owns canonical → 5-profile render + dogfood resync | One canonical edit point; the byte-identity gate green |
| Adopter with an in-flight work | Has live `STATE.md` files on disk from an installed AID | A migration that does not strand their work (§9 AC-8) |

## 4. Scope

### In Scope

The **work-tree state files** and every producer, consumer, template, doc and test that touches
them:

- `.aid/works/work-NNN-{name}/STATE.md` → `STATE.yml` (both the flattened Lite layout and the
  full path; the work-level file is the one the stakeholder's phrase denotes -- it is the only
  state file whose `phase:` scalar spans *several* phases, `Describe | Define | Specify | Plan |
  Detail | Execute`, and whose sections are per-phase: Interview State = Describe, Delivery
  Lifecycle = Plan/Specify, Delivery Gate = Execute).
- `deliveries/delivery-NNN/STATE.md` and `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`
  (full path only). **Deliberately included, not silently widened:** these three levels are one
  schema family with one writer, one reader pair and one template lineage
  (`.aid/knowledge/artifact-schemas.md § State-File Hierarchy`). `writeback-state.sh` resolves
  all three from the same `resolve_*_state_file` helpers and shares `wb_set_frontmatter` across
  them; the reader twins share `parse_state_md` / `parse_delivery_state_md` /
  `parse_task_state_md`. Converting only the work level would leave the writer emitting two
  formats and both twins carrying both parsers -- which removes none of the markdown-parsing
  cost that is the stated rationale, and adds a format boundary in the middle of one file tree.
- Templates: `canonical/aid/templates/work-state-template.md`,
  `delivery-state-template.md`, `task-state-template.md`.
- Writer: `canonical/aid/scripts/execute/writeback-state.sh` (every write mode) and, by hand, the
  deliberate fork `dashboard/scripts/writeback-state.sh`.
- Readers: both dashboard twins (`dashboard/reader/reader.py`, `parsers.py`, `models.py`,
  `derivation.py`, `state_schema.py`; `dashboard/server/reader.mjs`) and the shell readers
  `canonical/aid/scripts/works/enumerate-works.sh` (`_frontmatter_value` on `phase`/`lifecycle`)
  and `canonical/aid/scripts/housekeep/cleanup-classify.sh` (state signals at lines 326, 458, 538).
- **`dashboard/scripts/delete-pipeline.sh`** -- a third shell state reader, and a **safety** one.
  Its `Running` guard reads `lifecycle` from the candidate work's `STATE.md` (`:348`) and refuses
  deletion only when the value equals `Running` (`:349`); its own `_frontmatter_value`
  (`:164-168`) returns empty for a missing file, so an unretargeted path yields an empty
  `LIFECYCLE` and the guard **fails open** -- it would permit deleting a running pipeline's work
  folder or worktree. Its awk also carries the `NR==1 && $0=="---"` fence guard (`:168`), so even
  a retargeted path returns empty against a fence-less YAML file. Only one copy exists (no
  canonical source, no render, no PowerShell twin), so it is edited in place by hand. Its oracle
  is `tests/canonical/test-delete-pipeline.sh` (§5 FR-7a).
- **The dashboard server layer** -- `dashboard/server/server.mjs` (`:1242`, `:1280`, `:1555`) and
  `dashboard/server/server.py` (`:1503`, `:1540`, `:1803`) each build `AID_STATE_FILE` as
  *work-dir* + `STATE.md` before invoking `writeback-state.sh` for the three write-enabled edit
  surfaces (task set-notes, pipeline `Lifecycle=Completed`, task rename). Unretargeted, every one
  of them makes the writer `die "$STATE_FILE does not exist" 1` (`writeback-state.sh:1414` and the
  parallel existence checks at `:805`, `:894`, `:1039`, `:1133`, `:1206`, `:1240`), silently
  breaking every dashboard edit surface. Plus `dashboard/home.html:5816`, which builds the
  raw-state viewer's *fallback* source label from `workId` + `STATE.md`, and its ten sibling
  `STATE.md` UI strings/comments (`:3229`, `:4970`, `:5574`, `:5791`, `:5800`, `:5808`, `:5828`,
  `:5860`, `:5865`, `:5957`). Oracle:
  `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` (§5 FR-4e).
- The migration path for state files already on disk (§5 FR-9).
- The review-process exclusion (§5 FR-10).
- Every skill recipe and prose reference that names the path or parses a section -- notably
  `aid-execute` (SKILL.md + `state-execute.md` / `state-review.md` / `state-delivery-gate.md` /
  `state-fix.md`), `aid-plan`, `aid-specify`, `aid-describe`, `aid-detail`, `aid-deploy`,
  `aid-triage`, `aid-housekeep`, `aid-review`, `aid-ask`, and
  `canonical/aid/templates/shortcut-engine.md`.
- **Templates that resolve and read a work state file**, which the skill list above does not cover
  and which are routing logic written as prose: `canonical/aid/templates/work-initiation-gate.md`
  reads the chosen work's `STATE.md` frontmatter (`:131`) and routes the pipeline on its `phase`
  (`:141`), and also scaffolds the file on the NEW-work branch (`:123`);
  `downstream-worktree-entry.md:119` names a `STATE.md` read as one of the first resolutions that
  must land inside the entered worktree; `subagent-heartbeat-protocol.md:151` re-reads the work
  `lifecycle` for the cooperative stop-poll. `grep -rl STATE.md canonical/aid/templates` returns 30
  files in total, triaged per file: the `.aid/knowledge/STATE.md` and
  `discovery-state-template.md` matches are the out-of-scope ledger and must not change
  (`SPEC.md § L-7`).
- The render fan-out and dogfood resync (§5 FR-12).
- KB updates: `artifact-schemas.md`, `pipeline-contracts.md`, `quality-gates.md`,
  `architecture.md`, `module-map.md`, `test-landscape.md` wherever they state the state-file
  format.
- Test updates plus the added cross-format characterization/parity test (§9 AC-1, AC-2).
- The agent-context files (`CLAUDE.md`, `AGENTS.md`) wherever they name `STATE.md` by path.

### Out of Scope

- **`.aid/knowledge/STATE.md`** (the discovery-area / KB + cross-phase-process ledger). Excluded
  for three independent reasons: (a) it tracks one area, not several phases -- it does not carry
  the `phase:` scalar at all; (b) it is itself a Knowledge Base document with `kb-category: meta`
  frontmatter, indexed into `.aid/knowledge/INDEX.md` by `build-kb-index.sh` and lint-checked as
  a KB doc, so converting it would break the KB doc-set surface, a blast radius disjoint from the
  work tree; (c) the second half of the ask is already satisfied for it -- it is *already*
  review-exempt via `list_reviewable`, proven by `tests/canonical/test-kb-review-surface.sh`
  RS03. Its writer `canonical/aid/scripts/summarize/writeback-state.sh` and its readers
  `graph-preflight.sh`, `discover-preflight.sh`, `kb-write-fence.sh`, `kb-freshness-check.sh`,
  `stale-check.sh`, `complexity-score.sh` (`AID_KB_STATE`) are therefore all untouched.
- **A JSON Schema artifact and any CI schema-validation gate.** The stakeholder was offered the
  "YAML + JSON Schema validated in CI" variant and did not choose it. Not added. If a later phase
  judges a schema necessary, it is a follow-up, not a silent addition here (see §8 A-5).
- **JSON as the target format** -- decided against (see §1).
- **`.aid/.temp/HOUSEKEEP_STATE_*.md`** -- the `aid-housekeep` run-state file. Its own header
  states it "is NOT a work-area STATE.md" and `housekeep-state.sh` is path-agnostic
  (`--state`).
- **Control-signal and heartbeat files** (`.aid/.stop`, `.aid/.heartbeat/`). Already outside the
  state file's single-writer scope by construction --
  `canonical/aid/scripts/execute/write-control-signal.sh:56` states it "NEVER reads or writes
  `STATE.md`".
- **`tasks/task-NNN/DETAIL.md`, `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`** -- these
  are authored documents that *stay* markdown and *stay* reviewable. The review exclusion applies
  to state files only.
- **Any change to the state model itself**: no new field, no removed field, no widened or narrowed
  enum, no new zone, no change to the single-writer/disjoint-write rule, no change to
  most-advanced-wins reconcile ordering. `restructure` means the bytes move, the semantics do not.
- **Retiring the DERIVED read-time union model** in favour of persisted rollups. The DERIVED
  sections stop being *represented on disk* (§5 FR-2c) but the read-time derivation itself is
  unchanged.

## 5. Functional Requirements

- **FR-1 -- Filename and format.** Each in-scope state file is a YAML document named `STATE.yml`
  (`.yml`, matching `.aid/settings.yml`, not `.yaml`). The `.md` file no longer exists at that
  path after migration.
- **FR-2 -- Zone mapping.** The three zones map as follows, and nothing else changes:
  - **(a) FRONTMATTER → top-level YAML keys, verbatim.** Every key name, nesting shape
    (`pipeline.path`, `pipeline.initiator`) and closed-enum *string* is preserved byte-for-byte.
    The enum strings are a hard contract: `writeback-state.sh` validates against them
    (`mode_field`, `mode_delivery_lifecycle`, `mode_gate_field`) and both twins bind to the exact
    strings; the templates say so explicitly ("byte-identical to `delivery-state-template.md` --
    no byte-stability break").
  - **(b) AUTHORED markdown body → YAML structures.** `## Lifecycle History` becomes a sequence
    of mappings; `### Tasks lifecycle` becomes a mapping keyed by task id (or a sequence with an
    explicit id field) carrying `state` / `review` / `elapsed` / `notes` / `display_name`;
    `## Interview State`, `## Deploy State`, `## Delivery Gate` residue (Issue List, Block
    Reason, Block Artifact) and `## Quick Check Findings` likewise. The template's inline enum
    hints and single-writer/DERIVED annotations survive as YAML comments -- the reason YAML was
    chosen over JSON.
  - **(c) DERIVED sections are not represented on disk at all.** Features State, Plan/Deliveries,
    Tasks State, Delivery Gates, Calibration Log and Dispatches are read-time unions over child
    files; their `_none yet_` placeholder tables are dropped rather than translated. A reader
    encountering no such key derives the same union it derives today. Cross-phase Q&A keeps a
    key, because on the flattened Lite path it is AUTHORED, not derived
    (`artifact-schemas.md § Work STATE.md`).
- **FR-3 -- Templates.** The three in-scope templates become `.yml` templates carrying the same
  zone documentation as comments. `discovery-state-template.md` is untouched (out of scope).
- **FR-4 -- Writer: `writeback-state.sh`.** Every write mode the script's own header enumerates
  (`--pipeline --field`, `--task-id --field`, `--task-id --findings`, `--delivery-id --block`,
  `--lifecycle`, `--gate-field`, `--append-issue`) keeps its CLI surface, its exit-code contract
  (0/1/2/3/4/5/6), its enum validation, its `AID_*_FILE` override envs, and its flat-layout
  auto-detection (`is_flat_layout`: work-root BLUEPRINT.md present AND `tasks/task-NNN/DETAIL.md`
  present AND no `deliveries/`). What changes is that all four awk programs collapse onto one
  YAML write path.
  - **FR-4a** The **surgical single-key write** property is preserved: writing one key must not
    reorder, reflow, requote or otherwise touch any other part of the file. This is the property
    the header calls "body byte-invariance"; after the conversion the whole file is one zone, so
    the guarantee must be restated as "every **pre-existing** line other than the written key's
    own line is reproduced byte-for-byte". The one permitted addition is the create-parent-if-
    absent case the writer already performs for a nested key: writing a key whose parent mapping
    is not yet present inserts the parent key line plus the indented child line and nothing else.
    So the diff is one line for an existing key, and exactly the minimum new lines for an absent
    nested key -- never a reflow of anything already on disk.
  - **FR-4b** The `|`-and-newline rejection in `mode_field` is no longer a *format* constraint;
    values containing either must round-trip correctly (quoted/escaped as YAML requires) rather
    than being rejected. Existing callers that avoided those characters keep working.
  - **FR-4c** The CRLF normalization and trailing-newline preservation guards
    (`wb_set_frontmatter`, `has_crlf` / `had_trailing_nl`) are preserved.
  - **FR-4d** `dashboard/scripts/writeback-state.sh` is a **deliberate fork**, not a render: it
    additionally accepts `Deploy` as a `Phase` value. It is updated by hand and must NOT be
    resynced from canonical, per its own header and canonical's.
  - **FR-4e -- The dashboard server layer's write-path call sites.** The six `AID_STATE_FILE`
    constructions in `dashboard/server/server.mjs` (`:1242`, `:1280`, `:1555`) and
    `dashboard/server/server.py` (`:1503`, `:1540`, `:1803`) target `STATE.yml`, in lockstep
    across the two runtimes, so the three write-enabled dashboard edit surfaces (task set-notes,
    pipeline `Lifecycle=Completed`, task rename) keep working. The raw-state viewer's fallback
    source label (`dashboard/home.html:5816`) and its sibling `STATE.md` UI strings are retargeted
    with them. Oracle: `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py`.
- **FR-5 -- Reader twins.** Both `dashboard/reader/*.py` and `dashboard/server/reader.mjs` read
  the YAML state file and produce the identical `WorkModel` / payload they produce today, including
  graceful degradation: a missing, empty, unparseable or foreign file yields a minimal model plus a
  `parse_warning`, never an exception (`reader.py` `_minimal_work_model`; "Malformed STATE.md ->
  parse_warning + best-effort WorkModel; never aborts"). Per-work I/O stays **one file read**
  (`reader.py` step 5a, reused by `read_repo_detail` for `raw_state`) -- no extra read.
- **FR-6 -- No new runtime dependency.** Neither twin may take a YAML library. `packages/pypi/pyproject.toml`
  declares `dependencies = []`, and the repo-root `package.json` dependencies are explicitly
  "VERSION TRACKING ONLY ... never installed from this manifest". The parse must therefore be a
  hand-written parser over the exact YAML subset the schema uses (or a vendored parser under the
  existing `vendor/` convention, which would need its own justification). This is the same
  reasoning already recorded at `dashboard/reader/state_schema.py:226-251`: "Neither reader twin
  here uses a real YAML library for STATE.md ... both hand-parse via `parse_frontmatter_scalars`".
- **FR-7 -- Shell readers.** `enumerate-works.sh` (`_frontmatter_value` for `phase` / `lifecycle`)
  and `cleanup-classify.sh` (its three state-signal reads) target `STATE.yml` and keep their
  degrade-not-fail behavior (`"${phase:---}"`; `fail:no STATE.md found` messages updated to the
  new filename).
- **FR-7a -- The delete-pipeline safety guard.** `dashboard/scripts/delete-pipeline.sh` reads
  `lifecycle` from the candidate work's state file to refuse deleting a running pipeline (`:348-349`).
  Both halves must move: the path (`STATE.md` -> `STATE.yml`) **and** its `_frontmatter_value`
  awk (`:164-168`), which must lose the `NR==1 && $0=="---"` fence guard so it scans the whole
  fence-less YAML document -- exactly the change `enumerate-works.sh` gets under FR-7, since that
  helper is a documented verbatim mirror of it. The two halves are one change and must land
  together: retargeting the path without the awk, or the awk without the path, leaves the guard
  reading an empty `LIFECYCLE` for **every** work -- and because the guard fires only on the
  literal string `Running`, an empty read means it never fires at all. That is not a cosmetic
  miss; it is a safety guard silently converted into a no-op, permitting deletion of a running
  pipeline's work folder or worktree. The acceptance property is therefore behavioral, not
  textual: against a converted work whose `lifecycle` is `Running`, the script must still exit 7
  and refuse (§9 AC-13). The guard's *pre-existing* fail-open on a **missing** state file is
  unchanged by this work and carried forward as a recorded finding, not repaired here -- repairing
  it would be an observable behavior change `restructure` forbids (§4 Out of Scope).
- **FR-8 -- Skill recipes and prose.** Every skill/template that names the path, copies a
  template, or describes a section is updated: the `cp work-state-template` steps in
  `shortcut-engine.md § INTAKE Step 4` and `aid-review/SKILL.md`, every
  `writeback-state.sh --pipeline ...` recipe, and every "append to `## Lifecycle History`"
  instruction (now "append to the `lifecycle_history` sequence").
- **FR-9 -- Migration of existing on-disk state.** A migration script converts every in-scope
  `STATE.md` under `.aid/works/**` to `STATE.yml` in place, preserving every scalar value, every
  table row and the file's semantic content, and deleting the `.md` once the `.yml` verifies. It
  is **idempotent** (a second run is a no-op) and follows the established precedent
  `canonical/aid/scripts/migrate/migrate-work-hierarchy.sh` -- including its **PowerShell twin**
  `migrate-work-hierarchy.ps1`, so both twins exist here too. Migration is chosen over
  indefinite dual-format reads because the reader enumerates *every* work across *every* worktree
  root (`enumerate-works.sh`, `reader.mjs _enumerateWorktreeRoots`), so a half-converted repo
  renders a half-broken dashboard; and because keeping both parsers forever would forfeit the
  refactor's entire rationale.
- **FR-10 -- Exclusion from the review process.** State files are removed from the reviewable
  surface, at the narrowest points that actually decide it:
  - **(a)** `canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` gains an
    explicit rule: a state file is never listed in `{{ARTIFACTS}}`, and state churn appearing in
    a reviewed diff is not a finding. That doc is the single upstream point every brief derives
    from, and its deterministic-derivation mandate sits in its `## Brief generation` section.
  - **(b)** `canonical/skills/aid-execute/references/reviewer-brief.md:66` stops naming "every
    task's `STATE.md` row" in the per-delivery `{{ARTIFACTS}}`, and the per-task
    `{{DELIVERABLES}}` output location (line 54) is restated without implying the state file is
    reviewed content. The reviewer still *writes* its outcome into state -- writing state is not
    reviewing state.
  - **(c)** The shortcut engine's two GATE passes already exclude state files
    (`shortcut-engine.md` Steps 2-3 list only REQUIREMENTS/SPEC/PLAN/BLUEPRINT and the
    `DETAIL.md` set); the exclusion is made explicit in each pass's `OUT OF SCOPE` bullet so it
    cannot regress.
  - **(d)** No new grading mechanism, severity, ledger column or gate is introduced. `grade.sh`
    is not touched -- it grades a ledger, and reads no state file (verified: zero `STATE`
    references in `canonical/aid/scripts/grade.sh`).
- **FR-11 -- Documentation and KB.** `artifact-schemas.md` (§State-File Hierarchy, §Work/Delivery/Task
  STATE.md, §How Artifacts Relate, its validation-points table), `pipeline-contracts.md`,
  `quality-gates.md`, `architecture.md`, `module-map.md` and `test-landscape.md` are updated to
  state the new format, path and review status. Per `CLAUDE.md`, no KB doc may name this work or
  its folder; cite the durable artifacts on disk instead.
- **FR-12 -- Render fan-out.** All edits land in `canonical/` only, then the profile generator
  runs and the dogfood trees are resynced. Affected renders: **seven in total** -- 5 profiles ×
  (`aid/templates/*state-template*`, `aid/scripts/execute/writeback-state.sh`) plus this repo's
  own two per-tool dogfood trees (`.claude/`, `.cursor/`). Editing a render is a defect
  (`architecture.md`).
- **FR-13 -- Tests.** Every test asserting the old filename or markdown shape is updated in
  lockstep, and the change-set is enumerated so AC-1 can distinguish an intended update from a
  regression. Candidate inventory (files referencing `STATE.md`, to be triaged in-scope vs.
  out-of-scope before editing): 47 files under `tests/` and **37** under `dashboard/**/tests/`
  (51 is the count across all of `dashboard/`, not its test trees -- the figure §1's
  behavior-preservation slot states correctly).
  Heaviest **in-scope** ones: `tests/canonical/test-migrate-hierarchy.sh` (89 references),
  `test-disjoint-merge.sh` (73), `test-delivery-gate-aggregate.sh` (27), `test-aid-migrate.sh`
  (27), `test-housekeep-workfolder-safety.sh` (15), plus the fixture tree
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/`, which carries **seven**
  `STATE.md` files: the work root, `deliveries/delivery-001/`,
  `deliveries/delivery-001/tasks/task-001`, `task-002` and `task-004`,
  `deliveries/delivery-002/`, and `deliveries/delivery-002/tasks/task-003` -- four of the seven
  are per-task files, which an "every table row preserved" assertion must cover. Some of the 47 reference only the out-of-scope
  `.aid/knowledge/STATE.md` (`test-discover-preflight.sh`, `test-summarize-preflight.sh`,
  `test-kb-freshness-check.sh`, `test-grade-summary.sh`, `test-kb-review-surface.sh`) and must be
  left untouched -- editing one of those is itself a scope defect. `tests/coverage-baseline.tsv`
  (87 references) needs re-bootstrapping rather than row edits, because this is a corpus-wide
  change.

## 6. Non-Functional Requirements

- **NFR-1 -- Twin parity (hard).** The Python and Node readers must produce identical results for
  identical input. This is an existing enforced property with dedicated suites
  (`dashboard/reader/tests/test_flattened_layout_parity.py`,
  `test_resolve_work_dir_cross_runtime_parity.py`,
  `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py`,
  `test_task066_kb_parity.py`). A hand-written YAML subset parser in two languages is precisely
  the kind of change that breaks parity silently, so parity coverage must extend to the new parse
  path.
- **NFR-2 -- No implicit-typing dependence.** The on-disk schema must not depend on YAML implicit
  type resolution for correctness. The known landmine is recorded in the source:
  PyYAML's default 1.1 resolver coerces bare `yes`/`no`/`on`/`off` to bool at load time, while
  js-yaml's 1.2 core schema keeps them as strings
  (`dashboard/reader/state_schema.py:229-239`). Booleans are therefore written `true`/`false`,
  and any value whose bare form could resolve to a bool, number, date or null is quoted. The
  existing `parse_bool_yesno` tolerance for all four literals is retained for files a third-party
  tool may have re-dumped.
- **NFR-3 -- Concurrent-write safety, unchanged.** The sentinel-file lock (`set -o noclobber`
  atomic create + 0.5 s sleep-poll, `AID_LOCK_TIMEOUT` retries, exit 2 on contention), the
  write-to-temp + verify + atomic `mv` sequence, and the one-writer-per-file disjoint-write model
  must all survive. The AC that matters: no interleaving of concurrent writers can produce an
  unparseable file, and a failed write leaves the original untouched (every `die` path in
  `writeback-state.sh` already states "$FILE preserved"). `tests/canonical/test-disjoint-merge.sh`
  (73 references) is the existing oracle.
- **NFR-4 -- Cross-platform byte fidelity.** CRLF sources and files lacking a trailing newline
  must round-trip unchanged, on both Windows and POSIX awk builds -- the two defects
  `wb_set_frontmatter`'s guards exist to prevent.
- **NFR-5 -- Human readability and diffability.** State must remain hand-inspectable and produce
  a small, readable git diff for a single-field change. This is the acceptance condition behind
  choosing YAML-with-comments over JSON, and it is what makes the file usable as an audit trail.
- **NFR-6 -- Read cost.** One file read per work, unchanged (FR-5). No added stat or glob in the
  always-on read pass.
- **NFR-7 -- Render byte-identity.** `tests/canonical/test-dogfood-byte-identity.sh` must stay
  green, i.e. the dogfood `.claude/` tree is resynced from `profiles/claude-code/` after the
  generator runs. Related: `tests/canonical/test-multitool-isolation.sh` T21-T26 forbids any
  foreign-tool root path appearing in an operational script, including in comments.
- **NFR-8 -- Backward compatibility for an adopter mid-work.** Covered functionally by FR-9;
  as an NFR the requirement is that encountering a legacy `STATE.md` is a *diagnosable* state
  (an explicit warning naming the migration command), never a crash and never a silently empty
  dashboard row.
- **NFR-9 -- Security.** No new attack surface: state files stay local, no new network or
  process boundary. The reader's existing bounded-read protection
  (`dashboard/reader/io_bounds.py`, `MAX_READ_BYTES` in `reader.mjs`) applies unchanged to the new
  filename.
- **NFR-10 -- Performance budget.** *(pending)* -- no measured baseline for reader parse time
  exists, and no target was captured. The refactor is not motivated by performance
  (kind = `restructure`), so no target is invented here.

## 7. Constraints

- **C-1 Canonical-source discipline.** `canonical/` is the only edit point; `profiles/` and the
  dogfood trees are generated. `writeback-state.sh` opens with a banner about exactly this
  ("THIS FILE IS THE SOURCE. EIGHT RENDERS EXIST -- EDIT THIS ONE, NEVER A RENDER"), written
  because the mistake was already made once. **The banner's count is itself stale**: seven renders
  exist today (five profiles plus this repo's `.claude/` and `.cursor/` dogfood trees), so the
  quoted "EIGHT" is a defect in the shipped script, not a fact this work may inherit. The
  constraint the banner states -- canonical is the only edit point -- holds regardless; the count
  is corrected wherever *this* work states it (FR-12), and correcting the banner itself belongs to
  whichever task rewrites that banner region.
- **C-2 One deliberate fork.** `dashboard/scripts/writeback-state.sh` must be hand-updated and
  never resynced (FR-4d). No test catches an accidental resync -- the file's own header is the
  only guard.
- **C-3 Zero-runtime-dependency install.** No YAML library (FR-6).
- **C-4 Polyglot twin maintenance.** Every parse/serialize behavior must be implemented twice
  (Python + Node) and proven equal. The project's general rule is stated in `architecture.md`
  under *Polyglot parity* (there for the Bash/PowerShell install core, with its own
  `test-aid-cli-parity.sh`); for the readers the enforcement is the cross-runtime parity suites
  named in NFR-1.
- **C-5 Enum-string byte-stability.** Enum values are a cross-file contract shared by the writer,
  both twins, the templates and the KB; they may not drift (FR-2a).
- **C-6 Tracking discipline applies during the work itself.** Per `CLAUDE.md`, this work's own
  state must be written at every transition -- in whichever format is live at that moment. The
  conversion has to be sequenced so the work does not break its own tracking mid-flight, and a
  format change to AID's own on-disk work format must ship reader support before dogfood works
  are migrated.
- **C-7 KB may not name a work.** No KB doc may reference `work-009` or `.aid/works/work-009-*/`
  (FR-11).
- **C-8 The DERIVED zone must stay derived.** No requirement here may be met by persisting a
  rollup into a parent file (FR-2c, §4 Out of Scope).
- **C-9 `.yml`, not `.yaml`** -- matches `.aid/settings.yml`.

## 8. Assumptions & Dependencies

**Assumptions**

- **A-1** `STATE.yml` is the filename. Derived from the stakeholder's "yml" and the project's
  existing `.aid/settings.yml`; the exact string was not separately confirmed.
- **A-2** Frontmatter key names and enum strings carry over unchanged; only the body zones are
  restructured. This is what makes the stakeholder's "those fields lift across unchanged"
  rationale true, and it is required by C-5.
- **A-3** "Excluded from the review process" means excluded from **artifact review and grading**
  (reviewer `{{ARTIFACTS}}`, rubrics, ledgers, grades) -- not excluded from git, from the
  dashboard, or from the tracking-discipline mandate. State is still written, still committed,
  still read, still authoritative.
- **A-4** DERIVED sections may be dropped from disk entirely rather than emitted as empty YAML
  keys, because no writer writes them and every reader derives them. If any consumer is later
  found to read a DERIVED section *from the parent file*, this assumption fails and FR-2c needs
  revision.
- **A-5** No JSON Schema artifact and no CI schema-validation gate. The stakeholder was offered
  that variant and declined it. Recorded here as an explicit assumption rather than added
  silently; the enum validation that already lives in `writeback-state.sh` remains the only
  machine check.
- **A-6** No adopter has a state file with content that cannot be expressed in YAML. The values
  in play are short scalars, enum tokens, ISO timestamps, paths and one-line notes.

**Dependencies**

- Writer: `canonical/aid/scripts/execute/writeback-state.sh` (+ 7 renders, + the
  `dashboard/scripts/` fork).
- Readers: `dashboard/reader/{reader,parsers,models,derivation,state_schema,io_bounds}.py`;
  `dashboard/server/reader.mjs`;
  `canonical/aid/scripts/works/enumerate-works.sh`;
  `canonical/aid/scripts/housekeep/cleanup-classify.sh`;
  `dashboard/scripts/delete-pipeline.sh` (the `Running` safety guard -- §5 FR-7a).
- Write-path callers: `dashboard/server/{server.mjs,server.py}` (the six `AID_STATE_FILE`
  constructions -- §5 FR-4e) and `dashboard/home.html` (the raw-state viewer's fallback label and
  UI strings).
- Templates: the three in-scope `*-state-template.md`.
- Migration precedent: `canonical/aid/scripts/migrate/migrate-work-hierarchy.{sh,ps1}`.
- Review surface: `canonical/aid/templates/reviewer-dispatch.md`;
  `canonical/skills/aid-execute/references/reviewer-brief.md`;
  `canonical/aid/templates/shortcut-engine.md § GATE`;
  `canonical/aid/templates/reviewer-ledger-schema.md`.
- Skills that read or write state: `aid-execute`, `aid-plan`, `aid-specify`, `aid-describe`,
  `aid-define`, `aid-detail`, `aid-deploy`, `aid-triage`, `aid-housekeep`, `aid-review`,
  `aid-ask`, `aid-monitor`, plus `shortcut-engine.md`.
- KB: `.aid/knowledge/artifact-schemas.md`, `pipeline-contracts.md`, `quality-gates.md`,
  `architecture.md`, `module-map.md`, `test-landscape.md`, `capability-inventory.md`,
  `coding-standards.md`, `authoring-conventions.md`.
- Render + gates: the profile generator; `tests/canonical/test-dogfood-byte-identity.sh`;
  `test-multitool-isolation.sh`; the coverage-parity gate (`tests/coverage-baseline.tsv`, which
  itself carries 87 `STATE.md` references and will need re-bootstrapping for a corpus-wide
  change).
- Agent-context files: `CLAUDE.md`, `AGENTS.md`.

## 9. Acceptance Criteria

- **AC-1 (behavior preservation -- the family slot).** Given the full test suite is run on the
  pre-refactor tree and its per-test pass/fail set is recorded as a baseline, when the same suite
  is run on the post-refactor tree, then the pass/fail set matches the baseline exactly, with the
  sole permitted difference being tests explicitly enumerated in the FR-13 change-set as
  format-asserting updates. Any other newly-failing test, and any newly-*passing* test not on
  that list, is a regression. Read the suite's own summary line for counts, not grep over stdout.
- **AC-2 (cross-format characterization -- golden-master form).** The characterization compares
  the converted file's payload against a **recorded** payload of the legacy file, because the
  post-refactor readers deliberately no longer parse markdown state (FR-5, AC-5: a legacy
  `STATE.md` is *diagnosed*, not parsed). Concretely, in three parts:
  - **(a) Record.** Given a fixture work tree in the legacy markdown format, when it is read by
    the **pre-refactor** Python reader and by the **pre-refactor** Node reader, then the two
    payloads are equal on every field the dashboard renders and neither raises a `parse_warning`;
    that payload is committed as the golden baseline.
  - **(b) Compare.** Given the same tree converted by the FR-9 migration, when it is read by the
    **post-refactor** Python reader and by the **post-refactor** Node reader, then both payloads
    equal the golden baseline on every one of those fields (lifecycle, phase, active skill,
    updated, delivery state, gate tier/grade/timestamp, per-task
    state/review/elapsed/notes/display-name, lifecycle-history rows, Q&A entries, derived counts
    and percentages) and neither raises a `parse_warning`.
  - **(c) Diagnose.** Given the *unconverted* legacy tree, when it is read by the post-refactor
    readers, then both return the minimal-model degradation with the same `parse_warning` naming
    the file and the migration command -- identically in both runtimes. This is the required
    outcome, not a failure of (b); demanding a full payload from an unconverted legacy file would
    contradict FR-5/AC-5 and would require keeping the very markdown parsers this work deletes.
- **AC-3 (writer contract preserved).** Given a `STATE.yml` at any of the three levels, when each
  `writeback-state.sh` write mode is invoked, then the target key holds the new value, every
  other **pre-existing** line of the file is reproduced byte-for-byte (with the sole permitted
  addition being the create-parent-if-absent lines of FR-4a), the CLI surface and exit codes (0/1/2/3/4/5/6) are as
  documented, enum validation still rejects an out-of-enum value with exit 4, and a value
  containing `|`, a newline, a colon or a quote round-trips intact rather than being rejected.
- **AC-4 (write atomicity under concurrency).** Given N parallel writers targeting the same
  `STATE.yml` (the FR6 parallel-pool scenario `test-disjoint-merge.sh` already models), when they
  all run to completion, then every write is either fully applied or reports exit 2 (lock
  contention), the file parses cleanly at every observable moment, and no write is silently lost.
  Given a write that fails its verification step, the original file is byte-unchanged.
- **AC-5 (graceful degradation).** Given a state file that is absent / empty / truncated
  mid-document / valid YAML with an unknown key / a leftover legacy `STATE.md`, when either
  reader twin reads the work, then it returns a best-effort model with a `parse_warning` naming
  the file, raises no exception, and the dashboard still lists the work. For the legacy-`STATE.md`
  case the warning names the migration command (NFR-8).
- **AC-6 (review exclusion -- reviewer surface).** Given a per-delivery review dispatch, when the
  `{{ARTIFACTS}}` list is derived, then no state file appears in it -- verified by
  `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` carrying the explicit exclusion rule and by
  `aid-execute/references/reviewer-brief.md` no longer naming "every task's `STATE.md` row". A
  test asserts the exclusion mechanically, in the shape of the existing
  `tests/canonical/test-kb-review-surface.sh` RS03 (which proves the same property for the KB's
  meta ledgers).
- **AC-7 (review exclusion -- grading).** Given a completed review cycle whose reviewed diff
  includes state-file changes, when the ledger is graded by `grade.sh`, then no ledger row cites a
  state file as its `Doc`, and the grade is identical to the grade the same review produces with
  the state-file changes absent from the diff. `grade.sh` itself is unmodified.
- **AC-8 (existing on-disk works -- migration).** Given a repository whose `.aid/works/` contains
  works in the legacy format across one or more worktree roots -- covering both the flattened Lite
  layout and the full `deliveries/delivery-NNN/tasks/task-NNN/` layout, with
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/` (all **seven** state files:
  work root + delivery-001 + delivery-002 + the four per-task files under
  `delivery-001/tasks/task-001`, `task-002`, `task-004` and `delivery-002/tasks/task-003`)
  supplying the test's own copied-in input, not a live tree -- when the
  FR-9 migration
  script is run, then every in-scope `STATE.md` is replaced by a `STATE.yml` preserving every
  scalar, every table row and every Q&A entry; the `.md` file is gone; a second run changes
  nothing (idempotent); `enumerate-works.sh` lists every work with the same `phase`/`lifecycle`
  it reported before; and both reader twins render every work with no `parse_warning`. The Bash
  and PowerShell twins produce identical results on the same input.
- **AC-9 (no schema/model drift).** Given the converted templates and a migrated work, when the
  set of keys and the set of enum values on disk are compared against the pre-refactor set, then
  they are identical -- no key added, renamed or removed, no enum value changed, and no DERIVED
  section persisted as authored data.
- **AC-10 (render integrity).** Given the canonical edits are complete, when the profile generator
  runs and the dogfood trees are resynced, then `tests/canonical/test-dogfood-byte-identity.sh`
  and `tests/canonical/test-multitool-isolation.sh` pass, all 5 profile renders carry the change,
  no render was hand-edited, and `dashboard/scripts/writeback-state.sh` still accepts `Deploy` as
  a `Phase` value (proving it was hand-updated, not resynced).
- **AC-11 (documentation truth).** Given the refactor is complete, when every KB doc, skill,
  template, agent-context file, profile render and dogfood tree is grepped for `STATE.md` and for
  the retired section headings (`## Lifecycle History`, `### Tasks lifecycle`, `## Tasks State`,
  `## Delivery Gate`, `## Quick Check Findings`), then no remaining reference describes
  an in-scope work-tree state file as markdown or as a reviewable artifact; every surviving
  `STATE.md` reference is either the out-of-scope `.aid/knowledge/STATE.md` or an explicitly
  labelled legacy/migration reference. No KB doc names this work or its folder path.
- **AC-12 (dependency floor).** Given the post-refactor tree, when the reader twins are executed
  in a clean environment with no third-party packages installed, then both parse state files
  successfully -- proving no YAML library was introduced.
- **AC-13 (the two operational consumer layers still work).** Two properties, both behavioral:
  - **(a) The delete-pipeline safety guard still fires (FR-7a).** Given a converted work whose
    `STATE.yml` carries `lifecycle: Running`, when `dashboard/scripts/delete-pipeline.sh` is run
    against it, then it refuses and exits 7 -- proving the guard was not silently converted into a
    no-op by the rename. Asserted by `tests/canonical/test-delete-pipeline.sh`.
  - **(b) The dashboard write surfaces still work (FR-4e).** Given a converted work, when each of
    the three write-enabled server edit surfaces (task set-notes, pipeline
    `Lifecycle=Completed`, task rename) is exercised, then the write succeeds against `STATE.yml`
    in **both** server runtimes with identical results, and the raw-state viewer resolves the same
    source path in both. Asserted by
    `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py`.

## 10. Priority

**Must** -- the whole of §5 FR-1 … FR-13. The stakeholder's request has exactly two halves (the
format conversion and the review exclusion) and neither is optional; every other functional
requirement is a consumer that breaks if it is skipped.

Ordering within Must (dependency order, not importance):

1. FR-2/FR-3 -- settle the YAML schema and the templates first; everything else binds to it.
2. FR-5/FR-6 -- reader support before any migration, per C-6 (reader/CLI support must ship before
   dogfood works are converted).
3. FR-4 (+FR-4a-e) -- the writer, and the dashboard server layer's write-path call sites.
4. FR-7/FR-7a/FR-8 -- shell readers (including the `delete-pipeline.sh` safety guard) and skill
   recipes.
5. FR-9 -- migration of on-disk state, including the fixture tree.
6. FR-10 -- the review exclusion (independent of 1-5; may run in parallel).
7. FR-11/FR-12/FR-13 -- KB + docs, render fan-out, tests. Per the project's
   final-state-summaries rule, the generated summaries (`INDEX.md`, `kb.html`) refresh once at
   the end, not per step.

**Should:** nothing captured.

**Could:** nothing captured.

**Explicitly deferred:** a JSON Schema for the state file plus a CI validation gate (§8 A-5) --
offered to the stakeholder and declined; revisit only if a defect shows enum validation in
`writeback-state.sh` is insufficient.
