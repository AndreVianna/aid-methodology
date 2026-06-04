# Recipe Catalog

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Feature identified from REQUIREMENTS.md §§5,9,10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 Functional Requirements, §9 Acceptance Criteria (AC4), §10 Priority
- design-notes.md (authoritative ~51-recipe catalog table)

## Description

Populate the recipe catalog under the new schema/convention, **breadth-first**: first migrate
the 5 existing recipes with no loss of capability (`method-refactor`→`change-member`,
`add-crud-endpoint`→`add-api-endpoint`, `write-release-note`→`add-docs`/`add-report`,
`add-unit-test`→`add-test-coverage`, `bug-fix`→`fix-application`). Note: each rename must
update BOTH the filename and the `name:` field together (`parse-recipe.sh` WARNs when
`name` ≠ basename); and the recipe id `fix-application` is deliberately distinct from the
`bug-fix` **workType** value it carries in `applies-to:`. Then author the remaining
recipes — 40 add/change recipes across 11 target-kind families (20 pairs), 7 bug-fix recipes
(`fix-application/infrastructure/api/ui/integration/regression/security`), 3 refactor-only
(`improve-performance`, `bump-dependency`, `rename-symbol`), and the 1 cross-type
(`add-test-coverage`). Each recipe carries a `summary:` and follows the `add-X`/`change-X`/`fix-X`
naming convention. The merge-by-similarity consolidation is explicitly a **follow-up work**, not
part of this feature.

## User Stories

- As an **AID adopter**, I want a recipe for most common small jobs so my work instantiates a
  pre-filled SPEC + tasks in under a minute instead of falling through to the full interview.
- As an **AID maintainer**, I want every recipe to validate and follow a consistent naming
  convention so the catalog stays maintainable.

## Priority

Should (the full ~51 catalog) — with the 5-recipe **migration** as a Must slice, and bug-fix
specialization depth as Could (§10).

## Acceptance Criteria

- [ ] (AC4) The 5 existing recipes are migrated with **no loss** of capability and
  `parse-recipe.sh --validate` passes on each.
- [ ] (AC4) The full ~51-recipe catalog is authored per design-notes.md and
  `parse-recipe.sh --validate` passes on **every** recipe.
- [ ] All recipes follow the `add-X` / `change-X` / `fix-X` naming convention and carry a
  `summary:` (§6 NFR — greppable, consistent).
- [ ] (AC6, KB — catalog scope) KB `domain-glossary` § Recipes (incl. the "Seed Catalog (5 recipes)"
  entry) updated to reflect the new ~51-recipe catalog. (Enum KB refs are owned by feature-001;
  TRIAGE-flow KB by feature-002.)
- [ ] (AC5) Canonical change re-rendered to all 5 install trees
  (`antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`) via `/aid-generate`
  (byte-identical).

---

## Technical Specification

> This is a documentation/markdown change to `canonical/recipes/` (AID editing itself), not an
> application feature. There is no Data Model / API layer. The sections below are adapted: an
> **Overview**, the **Recipe Authoring Contract** (with one fully-worked exemplar), the complete
> **Catalog Manifest** (all ~51 recipes), the **Migration of the 5 Existing** recipes, the
> **Naming Convention**, the **README Seed Catalog + KB** updates feature-003 owns, and
> **Validation & Verification** + **Risks / Sequencing**. Every claim is grounded against the
> files on disk (the 5 seed recipes, `recipes/README.md`, `recipe-template.md`, and
> `parse-recipe.sh`) as of this writing.

### Overview

feature-003 is the **INSTANCES** slice of the lite-path recipe redesign (feature-001 = enum/schema
DEFINITION; feature-002 = TRIAGE CONSUMER). It populates the recipe catalog under the schema and
naming convention established by feature-001, **breadth-first**, in two parts:

- **(A) Migrate the 5 existing recipes** (`bug-fix.md`, `method-refactor.md`,
  `add-crud-endpoint.md`, `write-release-note.md`, `add-unit-test.md`) to the new schema /
  naming convention **with no loss of capability** — file rename + `name:` co-rename +
  `applies-to:` retarget to the 3-value enum + add `summary:`.
- **(B) Author the 47 new recipes** so the catalog reaches **51 total**, each conforming to the
  schema (including the `summary:` field from feature-001) and the `add-X` / `change-X` / `fix-X`
  naming convention, each passing `parse-recipe.sh --validate`.

**Final count = 51 recipes** (the migration absorbs 4 of the 5 existing names into the 51; the 5th,
`write-release-note`, **splits into two** new names — see § Migration). The
**merge-by-similarity consolidation is explicitly OUT OF SCOPE** — a follow-up work (design-notes
§ Decisions-locked 5 + § Merge axes). We author `add-X` and `change-X` as **separate** files now;
no `mode`-slot pre-merge.

**Boundary (firm).** feature-003 owns **all files under `canonical/recipes/`** — the 5 existing
recipe files, the 47 new ones, **and the README `## Seed Catalog` table** (the recipe inventory at
`recipes/README.md` ~lines 24–38) — plus the `domain-glossary.md` **Seed Catalog** term (line 168).
feature-003 does **not** touch: the recipe schema field docs / valid-`applies-to`-values table /
`summary:` field doc / recipe-template (feature-001), the enum in templates / tests / other KB
(feature-001), or `state-triage.md` and its sub-paths (feature-002). **README overlap rule:**
feature-001 owns the README **YAML-front-matter field table** + **valid-`applies-to`-values table**
+ the `summary:` field addition (`recipes/README.md` ~lines 48–80); feature-003 owns the README
**Seed Catalog table** (~lines 24–38). These two edits are in the same file but distinct,
non-overlapping line ranges.

**Smoke-test dual-ownership (same pattern, second file).** feature-003 **also owns** the
recipe-filename references in `tests/canonical/test-parse-recipe.sh` **Units 15–19** (the
seed-recipe `--validate` smoke units, ~lines 25–29 comment header and ~lines 797–866 bodies),
because feature-003's renames/removal are precisely what break them and keeping the smoke test
green is feature-003's own AC (Validation step 4). This is dual-ownership of one test file with
feature-001 — exactly like the README pattern: **feature-001 owns the enum-token fixtures**
(the `small-new-feature` literals at lines 145 and 205 — both lines carry `small-new-feature`),
**feature-003 owns the Units 15–19 recipe-filename references** (the old seed-recipe basenames).
Distinct line ranges,
no overlap. See § Scope & Files and § Validation step 4 for the exact old→new reference map.

### Scope & Files

The files feature-003 creates / renames / removes / edits. "Dual-owned" rows are shared with
another feature in the same work at **non-overlapping** line ranges (no merge conflict).

| Path | Action | Ownership | Notes |
|------|--------|-----------|-------|
| `canonical/recipes/*.md` (47 new) | create | feature-003 (sole) | The 47 newly authored recipes (incl. both `add-docs` + `add-report`) → catalog reaches 51. |
| `canonical/recipes/change-member.md` | rename | feature-003 (sole) | ← `method-refactor.md` (+ `name:` co-rename). |
| `canonical/recipes/add-api-endpoint.md` | rename | feature-003 (sole) | ← `add-crud-endpoint.md`. |
| `canonical/recipes/fix-application.md` | rename | feature-003 (sole) | ← `bug-fix.md` (`applies-to` stays `bug-fix`). |
| `canonical/recipes/add-test-coverage.md` | rename | feature-003 (sole) | ← `add-unit-test.md`. |
| `canonical/recipes/write-release-note.md` | **remove** | feature-003 (sole) | Splits into `add-docs.md` + `add-report.md` (new files); old name does not survive. |
| `canonical/recipes/README.md` `## Seed Catalog` (~lines 24–38) | edit | **dual-owned** w/ feature-001 | feature-003 owns the Seed Catalog table; feature-001 owns the field/enum/`summary:` tables (~lines 48–80). Non-overlapping. |
| `.aid/knowledge/domain-glossary.md` Seed Catalog term (line 168) + `changelog:` | edit | feature-003 (sole) | Enum/`applies-to`/Recipe terms are feature-001 / feature-002. |
| `tests/canonical/test-parse-recipe.sh` Units 15–19 recipe-filename refs (~lines 25–29, 797–866) | edit | **dual-owned** w/ feature-001 | feature-003 owns the 5 seed-recipe basename references (old→new map below); feature-001 owns the enum-token fixtures (`small-new-feature` at both lines 145 and 205). Non-overlapping line ranges, same file. |

**Units 15–19 old→new recipe-filename reference map** (each unit's `SEED_FILE=` path, its
`echo "=== Unit N: …"` banner, the `~lines 25–29` comment header, and both `assert_*` description
strings move together):

| Unit | Old reference | New reference | Handling |
|------|---------------|---------------|----------|
| 15 | `bug-fix.md` / `'bug-fix'` | `fix-application.md` / `'fix-application'` | Retarget to the renamed file. |
| 16 | `write-release-note.md` / `'write-release-note'` | `add-docs.md` / `'add-docs'` | **Retargeted** (old file removed): `write-release-note` splits into `add-docs` + `add-report`; this unit points at **`add-docs.md`** (release-note is `add-docs`'s canonical example — the documentation-family migration home). |
| 17 | `method-refactor.md` / `'method-refactor'` | `change-member.md` / `'change-member'` | Retarget to the renamed file. |
| 18 | `add-crud-endpoint.md` / `'add-crud-endpoint'` | `add-api-endpoint.md` / `'add-api-endpoint'` | Retarget to the renamed file. |
| 19 | `add-unit-test.md` / `'add-unit-test'` | `add-test-coverage.md` / `'add-test-coverage'` | Retarget to the renamed file. |

All five units keep their identical structure (the `[[ -f "$SEED_FILE" ]]` guard, `--validate`
call, `exits 0` + `OK: all checks passed` asserts) — only the basename/label strings change. After
the edit each unit validates a file that exists post-migration, so step 4 of § Validation stays
green. (Optionally a sixth unit could be added for `add-report.md` to cover the split's second
file, but that is not required for no-loss; the minimum is retargeting Unit 16 to `add-docs.md`.)

### Recipe Authoring Contract

Every recipe — migrated or new — is a single Markdown file directly under `canonical/recipes/`
named `<name>.md` (flat, no subdirectories), with this exact shape. The contract is derived from
`parse-recipe.sh` (the authority) and `recipes/README.md`:

**1. YAML front-matter — five fields, in order:**

```
---
name: <basename>
applies-to: <enum>
slot-count: <int>
task-count: <int>
summary: <one-line string>
---
```

- `name` **MUST equal the file basename without `.md`.** `parse-recipe.sh` WARNs (non-fatal) on
  mismatch (`mode_validate`, lines 404–409), but the convention is hard — a rename touches **both**
  the filename and `name:` together. The four required keys (`name`, `applies-to`, `slot-count`,
  `task-count`) are read by `parse_frontmatter()` via `grep -E '^<key>:'` (lines 164–167) and each
  is fatal-if-empty (lines 169–172).
- `applies-to` ∈ **`{ bug-fix, new-feature, refactor, * }`** (the new 3-value enum + cross-type
  wildcard, per feature-001). The validator does **not** enum-check this field (only asserts
  non-empty), but the catalog must use only these four values. Note `applies-to: "*"` is written
  **quoted** in the existing `add-unit-test.md` and the cross-type recipe carries it quoted.
- `slot-count` / `task-count` are integers (lines 174–180 enforce `^[0-9]+$`) and **MUST match the
  body** — `slot-count` = the count of **unique** `{{slot}}` tokens, `task-count` = the count of
  `### task-NNN` headings in `## tasks`. A mismatch is a WARN (non-fatal, lines 390–402) but every
  authored recipe MUST match exactly so `--validate` prints `OK: all checks passed` with no WARN.
- `summary:` (feature-001 addition) — a one-line free-form string, agent-read only (used by
  feature-002's description-first TRIAGE matching + the catalog listing). **Not** parser-enforced
  (unknown-field tolerance: `parse_frontmatter` reads only the four known keys; any other line —
  including `summary:` — is never consumed). It carries **no slot tokens** (it is not rendered into
  the work SPEC). Every recipe in this catalog carries one.

**2. Body — two blocks, in order, exact lowercase markers `## spec` then `## tasks`:**

- `## spec` block (case-sensitive marker; `get_spec_block` runs from `^## spec$` to `^## tasks$`)
  becomes the rendered `.aid/work-NNN/SPEC.md`. It MUST contain, per the work-root schema
  (`recipes/README.md` § Body Structure): `# {title}`; the 4-line bold **Metadata block**
  (`**Work:**`, `**Created:**`, `**Source:**`, `**Status:**`); `## Goal`; `## Context`;
  `## Acceptance Criteria`; `## Tasks` (table `Task | Type | Title`); `## Execution Graph`
  (two tables: `Task | Depends On` and `Can Be Done In Parallel`); `## Revision History`.
- `## tasks` block (marker `^## tasks$`; `get_tasks_block` runs to EOF) holds one
  `### task-NNN — Title` heading per task, each a 6-section flat task (title heading, `Type`,
  `Source: work-NNN → delivery-001`, `Depends on`, `Scope`, `Acceptance Criteria`) per
  `canonical/templates/delivery-plans/task-template.md`. `count_task_headings` counts
  `^### task-[0-9]`.

**3. Slot rules:**

- Lexical rule `[a-z][a-z0-9-]*` (lowercase ASCII first char, then lowercase/digit/hyphen). No
  underscores, uppercase, dots, or spaces. The slot regex in the script is
  `\{\{[a-z][a-z0-9-]*\}\}`.
- `slot-count` counts **unique** names (a name reused across Goal + Scope counts once).
- `{!{` → `{{` escape: to emit a literal `{{` (e.g. a recipe that quotes brace syntax), write
  `{!{`; the renderer rewrites `{!{` → `{{` at emit time. Recipes in this catalog do not need the
  escape unless their body discusses template/brace syntax as display content.

**4. Convention (carried from the seed recipes, kept stable for migration no-loss):** the Metadata
block uses literal `**Work:** work-NNN`, `**Created:** (auto-filled)`,
`**Source:** recipe \`<name>\` via /aid-interview lite path`, `**Status:** Active`; and the
`## Revision History` row uses `(auto-filled)` for the date — i.e. these are **not** counted as
slots (matching all 5 existing recipes, so migrated recipes keep their exact slot-count). This
matches the on-disk seed recipes (not the README's "Full Example", which counts `{{date}}` /
`{{work-name}}` as slots — an authoring choice the README itself flags as optional).

#### Fully-worked exemplar — `add-api-endpoint` (the migration target of `add-crud-endpoint`)

This is the end-to-end template execution must copy for every authored recipe. It is the
`add-crud-endpoint.md` shape, retargeted (`new-feature`), renamed, and `summary:`-bearing. It has
**6 unique slots** (`resource-name`, `endpoint-path`, `request-schema`, `response-schema`,
`persistence-layer-notes`, `security-notes`) and **3 tasks** — so `slot-count: 6`, `task-count: 3`.

```markdown
---
name: add-api-endpoint
applies-to: new-feature
slot-count: 6
task-count: 3
summary: Add a CRUD/REST API endpoint backed by persistence and covered by integration tests.
---

## spec

# Add API endpoint: {{resource-name}}

**Work:** work-NNN
**Created:** (auto-filled)
**Source:** recipe `add-api-endpoint` via /aid-interview lite path
**Status:** Active

## Goal

Implement a full CRUD REST endpoint for the `{{resource-name}}` resource at
`{{endpoint-path}}`, backed by the persistence layer, and covered by integration tests.

## Context

Request schema: {{request-schema}}

Response schema: {{response-schema}}

Persistence layer notes: {{persistence-layer-notes}}

Security notes: {{security-notes}}

## Acceptance Criteria

- [ ] GET / POST / PUT / DELETE endpoints exist under `{{endpoint-path}}`.
- [ ] Request and response schemas match the definitions above.
- [ ] All four operations are covered by integration tests (happy path + at least
  one error path per operation).
- [ ] Persistence layer correctly stores and retrieves `{{resource-name}}` records.
- [ ] Security controls specified in the security notes are enforced.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Define schema and migration for {{resource-name}} |
| task-002 | IMPLEMENT | Implement handler and persistence for {{resource-name}} |
| task-003 | TEST | Integration tests for {{resource-name}} endpoints |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| (auto-filled) | Created from recipe `add-api-endpoint` | /aid-interview lite path |

## tasks

### task-001 — Define schema and migration for {{resource-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: —
- Scope: Define the data model for `{{resource-name}}` using the persistence layer
  ({{persistence-layer-notes}}). Create any required schema migrations. Request
  schema: {{request-schema}}. Response schema: {{response-schema}}.
- Acceptance Criteria:
  - [ ] Data model for `{{resource-name}}` is defined and matches the request/response schemas.
  - [ ] Migration runs cleanly on a fresh database and on an existing one.
  - [ ] Model is unit-tested (validation rules, constraints).

### task-002 — Implement handler and persistence for {{resource-name}}

- Type: IMPLEMENT
- Source: work-NNN → delivery-001
- Depends on: task-001
- Scope: Implement GET / POST / PUT / DELETE handlers at `{{endpoint-path}}`.
  Wire handlers to the persistence layer. Enforce security controls: {{security-notes}}.
- Acceptance Criteria:
  - [ ] All four HTTP methods respond correctly with the defined schemas.
  - [ ] Security controls from the security notes are enforced on all operations.
  - [ ] Error responses follow the existing API error shape.

### task-003 — Integration tests for {{resource-name}} endpoints

- Type: TEST
- Source: work-NNN → delivery-001
- Depends on: task-002
- Scope: Write integration tests for all four CRUD operations at `{{endpoint-path}}`,
  covering happy-path and at least one error-path scenario per operation.
- Acceptance Criteria:
  - [ ] Happy-path tests pass for GET, POST, PUT, and DELETE.
  - [ ] At least one error-path test per operation (e.g., not-found, invalid input, unauthorized).
  - [ ] No regression in existing endpoint tests.
```

This exemplar passes `parse-recipe.sh --validate`: 6 unique slots = `slot-count: 6`; 3
`### task-` headings = `task-count: 3`; `## spec` + `## tasks` present; `name` = basename.

#### add/change pair slot-structure rule

For each of the 20 target-kind pairs, the `add-X` and `change-X` recipe **share the same slot
vocabulary** for the target plus its describing slots, differing only by verb intent:

- The `add-X` form carries: a `{{<target>-name}}` (or `-title`), the describing slots for the new
  thing, and (where relevant) a placement/path slot. Goal = "add a new …".
- The paired `change-X` form carries the **same** `{{<target>-name}}` plus `{{current-shape}}` /
  `{{target-shape}}` (or `{{current-behavior}}` / `{{intended-behavior}}`) + a `{{rationale}}`
  slot, mirroring the `method-refactor` shape (which uses `before-shape` / `after-shape` /
  `refactor-rationale`). Goal = "change an existing …".

This shared structure is what makes the deferred merge (Axis A: add↔change with a `mode` slot)
tractable later; for now they are separate files. The manifest's `slot-count` / `task-count`
columns reflect this: every `add-X`/`change-X` single-concern recipe is **1 task**; `change-X`
recipes carry **+1 slot** (the rationale/current-shape delta) over their `add-X` partner in most
families.

### Catalog Manifest (all 51 recipes)

The complete execution checklist. Every recipe MUST be authored exactly as listed (name,
`applies-to`, `summary:` draft one-liner, `slot-count`, `task-count`, target-kind family). Slot/task
counts are the authoring target the body must match for `--validate` to pass clean; the
`summary:` text is a draft one-liner execution may refine but must keep one-line. "Migrated?"
marks the 5 that carry over from an existing file (see § Migration for the no-loss mapping).

**Group 1 — add/change pairs (20 pairs = 40 recipes), `applies-to` = `new-feature` (add) /
`refactor` (change):**

| # | name | applies-to | summary (draft) | slots | tasks | target-kind family | Migrated? |
|---|------|-----------|-----------------|-------|-------|--------------------|-----------|
| 1 | `add-member` | new-feature | Add a field/property/method to an existing object or model. | 4 | 1 | Objects / Models | — |
| 2 | `change-member` | refactor | Refactor an existing member of an object or model without changing observable behavior. | 5 | 1 | Objects / Models | ← `method-refactor` |
| 3 | `add-interface` | new-feature | Add a new interface/contract/abstract type. | 4 | 1 | Objects / Models | — |
| 4 | `change-interface` | refactor | Change an existing interface/contract and update its implementors. | 5 | 1 | Objects / Models | — |
| 5 | `add-api-endpoint` | new-feature | Add a CRUD/REST API endpoint backed by persistence and covered by integration tests. | 6 | 3 | API | ← `add-crud-endpoint` |
| 6 | `change-api-endpoint` | refactor | Change an existing API endpoint's contract/behavior without breaking clients. | 6 | 2 | API | — |
| 7 | `add-api-middleware` | new-feature | Add API middleware (auth, logging, rate-limit) to the request pipeline. | 4 | 2 | API | — |
| 8 | `change-api-middleware` | refactor | Change existing API middleware behavior or ordering. | 5 | 1 | API | — |
| 9 | `add-ui-endpoint` | new-feature | Add a new UI page/route. | 5 | 2 | UI | — |
| 10 | `change-ui-endpoint` | refactor | Change an existing UI page/route's behavior or layout. | 5 | 1 | UI | — |
| 11 | `add-ui-component` | new-feature | Add a reusable UI component. | 5 | 2 | UI | — |
| 12 | `change-ui-component` | refactor | Change an existing UI component's props or behavior. | 5 | 1 | UI | — |
| 13 | `add-ui-style` | new-feature | Add a new style/theme rule or design token. | 4 | 1 | UI | — |
| 14 | `change-ui-style` | refactor | Change an existing style/theme rule without breaking layout. | 4 | 1 | UI | — |
| 15 | `add-cli-command` | new-feature | Add a new CLI subcommand with args and help text. | 5 | 2 | CLI command | — |
| 16 | `change-cli-command` | refactor | Change an existing CLI command's flags/behavior. | 5 | 1 | CLI command | — |
| 17 | `add-entity` | new-feature | Add a new persisted entity/table with a migration. | 5 | 2 | DB / Storage | — |
| 18 | `change-schema` | refactor | Change an existing DB schema with a forward + rollback migration. | 5 | 2 | DB / Storage | — |
| 19 | `add-container` | new-feature | Add a new storage container/bucket/collection. | 4 | 1 | DB / Storage | — |
| 20 | `change-container` | refactor | Change an existing storage container's config/structure. | 5 | 1 | DB / Storage | — |
| 21 | `add-config-option` | new-feature | Add a new configuration option with a documented default. | 4 | 1 | config / feature flag | — |
| 22 | `change-config-option` | refactor | Change an existing config option's default/validation. | 5 | 1 | config / feature flag | — |
| 23 | `add-feature-flag` | new-feature | Add a feature flag gating new behavior. | 4 | 1 | config / feature flag | — |
| 24 | `change-feature-flag` | refactor | Change or retire an existing feature flag. | 4 | 1 | config / feature flag | — |
| 25 | `add-job` | new-feature | Add a scheduled/background job. | 5 | 2 | job | — |
| 26 | `change-job` | refactor | Change an existing job's schedule or logic. | 5 | 1 | job | — |
| 27 | `add-event-handler` | new-feature | Add a handler/consumer for a domain or system event. | 5 | 2 | event handler / consumer | — |
| 28 | `change-event-handler` | refactor | Change an existing event handler's behavior. | 5 | 1 | event handler / consumer | — |
| 29 | `add-queue` | new-feature | Add a message queue/topic and its producer wiring. | 4 | 2 | event handler / consumer | — |
| 30 | `change-queue` | refactor | Change an existing queue's config or routing. | 5 | 1 | event handler / consumer | — |
| 31 | `add-message` | new-feature | Add a new message/event schema and emit it. | 4 | 1 | event handler / consumer | — |
| 32 | `change-message` | refactor | Change an existing message/event schema (versioned, back-compatible). | 5 | 1 | event handler / consumer | — |
| 33 | `add-rule` | new-feature | Add a validation or business rule. | 4 | 1 | validation / business rule | — |
| 34 | `change-rule` | refactor | Change an existing validation/business rule. | 5 | 1 | validation / business rule | — |
| 35 | `add-docs` | new-feature | Author a new documentation artifact (guide, README, release note). | 4 | 1 | documentation / report | ← `write-release-note` (split A) |
| 36 | `change-docs` | refactor | Update an existing documentation artifact. | 4 | 1 | documentation / report | — |
| 37 | `add-report` | new-feature | Author a new report/analysis artifact. | 4 | 1 | documentation / report | ← `write-release-note` (split B) |
| 38 | `change-report` | refactor | Update an existing report/analysis artifact. | 4 | 1 | documentation / report | — |
| 39 | `add-integration` | new-feature | Add a client/adapter for an external service. | 5 | 2 | integration / external client | — |
| 40 | `change-integration` | refactor | Change an existing external-service integration. | 5 | 1 | integration / external client | — |

**Group 2 — bug-fix recipes (7), `applies-to` = `bug-fix`:**

| # | name | applies-to | summary (draft) | slots | tasks | target-kind family | Migrated? |
|---|------|-----------|-----------------|-------|-------|--------------------|-----------|
| 41 | `fix-application` | bug-fix | Fix a domain/business-logic defect (the broad default) and add a regression test. | 4 | 1 | bug-fix (application) | ← `bug-fix` |
| 42 | `fix-infrastructure` | bug-fix | Fix an infrastructure/deployment/config defect and confirm in the target environment. | 4 | 1 | bug-fix (infrastructure) | — |
| 43 | `fix-api` | bug-fix | Fix an API-layer defect (status, contract, payload) and add a regression test. | 4 | 1 | bug-fix (api) | — |
| 44 | `fix-ui` | bug-fix | Fix a UI-layer defect (rendering, interaction, state) and add a regression test. | 4 | 1 | bug-fix (ui) | — |
| 45 | `fix-integration` | bug-fix | Fix a defect in an external-service integration and add a regression test. | 4 | 1 | bug-fix (integration) | — |
| 46 | `fix-regression` | bug-fix | Fix a regression: bisect to the introducing change, fix, and lock with a test. | 5 | 1 | bug-fix (regression) | — |
| 47 | `fix-security` | bug-fix | Fix a security vulnerability and add a test proving the exploit is closed. | 5 | 1 | bug-fix (security) | — |

**Group 3 — refactor-only recipes (3), `applies-to` = `refactor`:**

| # | name | applies-to | summary (draft) | slots | tasks | target-kind family | Migrated? |
|---|------|-----------|-----------------|-------|-------|--------------------|-----------|
| 48 | `improve-performance` | refactor | Improve performance of a hot path against a measured baseline, with no behavior change. | 5 | 2 | refactor-only | — |
| 49 | `bump-dependency` | refactor | Upgrade a dependency to a target version and reconcile breaking changes. | 4 | 2 | refactor-only | — |
| 50 | `rename-symbol` | refactor | Rename a symbol (class/method/variable) across the codebase with no behavior change. | 4 | 1 | refactor-only | — |

**Group 4 — cross-type recipe (1), `applies-to` = `*`:**

| # | name | applies-to | summary (draft) | slots | tasks | target-kind family | Migrated? |
|---|------|-----------|-----------------|-------|-------|--------------------|-----------|
| 51 | `add-test-coverage` | `*` | Add test coverage for any work type (bug fix, refactor, or new feature). | 4 | 1 | cross-type | ← `add-unit-test` |

**Totals:** 40 (add/change) + 7 (bug-fix) + 3 (refactor-only) + 1 (cross-type) = **51 recipes**.
Of the 5 existing seed files, only **4** reuse their existing file via an in-place rename
(`change-member` ← `method-refactor`, `add-api-endpoint` ← `add-crud-endpoint`,
`fix-application` ← `bug-fix`, `add-test-coverage` ← `add-unit-test`); the 5th seed file,
`write-release-note.md`, is **removed** and its capability splits into **two newly created** files
(`add-docs.md` + `add-report.md`). So: **newly authored = 47** new files (51 final − 4 in-place
renames = 47), including **both** `add-docs` and `add-report`. Net new files on disk = **47**; net
renamed (in-place) = 4; net removed = 1 (`write-release-note.md`). (The authoritative count gate
stays `ls canonical/recipes/*.md | wc -l = 51`.)

**File-change tally for feature-003** (recipe count is unchanged at **51**; this is the count of
files feature-003 touches): **47** new recipe files + **4** renamed recipe files + **1** removed
recipe file (`write-release-note.md`) + **3** in-place edits — `recipes/README.md` (Seed Catalog
table, dual-owned), `.aid/knowledge/domain-glossary.md` (Seed Catalog term + changelog), and
**`tests/canonical/test-parse-recipe.sh`** (Units 15–19 recipe-filename references, dual-owned w/
feature-001). **Total = 55 file changes** (47 new + 4 renamed + 1 removed + 3 in-place edits)
across **55 distinct paths** — each change lands on a different filesystem path (the 47 new
recipe paths, the 4 rename-target paths, the 1 removed `write-release-note.md` path, and the 3
edited paths: `recipes/README.md`, `domain-glossary.md`, `test-parse-recipe.sh`; the README and
test file are each a single edited path even though dual-owned). The 51-recipe catalog count and
all per-group counts (40 / 7 / 3 / 1) are unaffected by adding the test-file edit — it changes no
recipe.

> **Slot/task counts are the authoring contract, not a suggestion.** The body of each authored
> recipe MUST contain exactly the listed number of unique `{{slot}}` tokens and `### task-NNN`
> headings so `--validate` prints `OK: all checks passed` with no WARN. Where execution finds a
> recipe genuinely needs a different count, it adjusts the front-matter `slot-count`/`task-count` to
> match the body it writes (the two must agree); the manifest counts are the design target derived
> from the analogous seed-recipe shapes.

### Migration of the 5 Existing Recipes (no-loss)

Each migration is a **file rename + `name:` co-rename + `applies-to:` retarget + `summary:`
addition**, preserving every existing slot and task (no-loss). The `name:` field and the filename
**must change together** (`parse-recipe.sh` WARNs on mismatch). Note the **workType value vs.
recipe id** distinction: the `bug-fix` *workType* (an `applies-to:` value) is distinct from the
recipe *id* `fix-application` — the file is renamed to `fix-application.md` but still carries
`applies-to: bug-fix`.

| Old file / name | New file / name | `applies-to` old → new | Slots / tasks carried over | No-loss argument |
|-----------------|-----------------|------------------------|----------------------------|------------------|
| `method-refactor.md` | `change-member.md` | `small-refactor` → `refactor` | 5 slots (`class-name`, `method-name`, `refactor-rationale`, `before-shape`, `after-shape`), 1 task, unchanged | Body unchanged except `name:`/`Source:`/Revision-History recipe-id label `method-refactor`→`change-member`. Same slots, same task, same ACs. Same `slot-count: 5` / `task-count: 1`. A method is a "member"; `change-member` generalizes without dropping the method case. |
| `add-crud-endpoint.md` | `add-api-endpoint.md` | `small-new-feature` → `new-feature` | 6 slots, 3 tasks, unchanged | Identical body (the § exemplar above) except the recipe-id label. `add-api-endpoint` is the API-family `add` recipe; CRUD is its canonical instance. `slot-count: 6` / `task-count: 3` unchanged. |
| `write-release-note.md` | **split into** `add-docs.md` **and** `add-report.md` | `single-doc` → `new-feature` (both) | release-note slots fold into `add-docs` (the doc family); `add-report` is its sibling | **Decision: SPLIT (do not become one).** design-notes' documentation/report family has **four** target names (`add-docs`/`change-docs`/`add-report`/`change-report`); the eliminated `single-doc` workType folds into `new-feature` (add) / `refactor` (change). The release-note pattern is a documentation artifact → it migrates into **`add-docs`** (release notes are the canonical `add-docs` example; its `summary` and an AC reference release-note authoring). **`add-report`** is the new sibling for analysis/report artifacts. No capability is lost: the release-note body's headline/breaking/upgrade slots survive inside `add-docs`'s general doc-artifact shape, and the dedicated release-note flavor is preserved as `add-docs`'s exemplar wording. The old `write-release-note.md` file is **removed** (its name does not survive the new convention). |
| `bug-fix.md` | `fix-application.md` | `bug-fix` → `bug-fix` (unchanged) | 4 slots (`bug-title`, `bug-description-one-sentence`, `reproduction-steps`, `intended-behavior`), 1 task, unchanged | Body unchanged except recipe-id label. `fix-application` is the **broad default** bug-fix (domain/business-logic bugs not caught by api/ui), so `bug-fix.md`→`fix-application.md` is the natural home. `applies-to` **stays `bug-fix`** (the workType value is unchanged; only the recipe id renames). `slot-count: 4` / `task-count: 1` unchanged. |
| `add-unit-test.md` | `add-test-coverage.md` | `*` → `*` (unchanged, quoted `"*"`) | 4 slots (`target-class`, `target-method`, `test-framework`, `behavior-under-test`), 1 task, unchanged | Body unchanged except recipe-id label. `add-test-coverage` is the cross-type test recipe; "unit test" is its canonical use. `applies-to: "*"` stays quoted as on disk. `slot-count: 4` / `task-count: 1` unchanged. |

**Per-recipe in-body edits on migration** (besides front-matter): the `**Source:**` metadata line,
the `## Revision History` "Created from recipe `<id>`" cell, and any `### task` / Goal prose that
names the recipe by id are updated from the old id to the new id. The slot tokens themselves are
**not** renamed (renaming a slot would change the user-facing prompt and risk no-loss), so
`slot-count` is invariant across every migration.

**`add-docs` / `add-report` split note for execution:** author `add-docs.md` by generalizing
`write-release-note.md`'s body to a documentation artifact (keep release-note as the worked example
in Goal/Scope; 4 slots: `doc-title`, `doc-purpose`, `doc-outline`, `doc-acceptance` — or retain
the release-note slot names if execution prefers the literal carry-over). `add-report.md` is its
new sibling. Both carry `applies-to: new-feature` and 1 task. Their `change-` partners
(`change-docs`, `change-report`) are authored fresh per the manifest.

### Naming Convention

All 51 recipes follow `add-X` / `change-X` / `fix-X` (design-notes § Decisions-locked; AC3
"greppable, consistent"):

- **`add-X`** — `new-feature` work that introduces a new thing of kind X (20 recipes) + the
  cross-type `add-test-coverage`.
- **`change-X`** — `refactor` work that modifies an existing thing of kind X (20 recipes) + the 3
  refactor-only recipes, which use the verb that fits their action (`improve-performance`,
  `bump-dependency`, `rename-symbol` — all `refactor`; these are the documented exceptions to the
  literal `change-` prefix, kept as design-notes names).
- **`fix-X`** — `bug-fix` work in architectural area / bug-nature X (7 recipes).

Families map to names via the design-notes target-kind table (Group 1) and the bug-fix area list
(Group 2). Greppability check: `ls canonical/recipes/ | grep -cE '^(add|change|fix)-'` should equal
the recipe-file count (51, excluding `README.md`). The 3 refactor-only verbs
(`improve`/`bump`/`rename`) are intentional and called out so the grep gate uses the
`add|change|fix|improve|bump|rename` alternation, or treats those 3 as known exceptions.

### README Seed Catalog + KB (AC6 — catalog scope)

feature-003 updates **two** catalog inventories to reflect the new 51-recipe catalog. These are
**distinct** from feature-001's schema-table edits in the same README file:

**1. `canonical/recipes/README.md` `## Seed Catalog` section (~lines 24–38)** — feature-003 owns
this. Currently a 5-row table titled "The seed catalog ships five recipes". Replace it to reflect
the 51-recipe catalog. Because a 51-row table is unwieldy, render it as **grouped sub-tables** (the
four manifest groups: add/change pairs, bug-fix, refactor-only, cross-type) with a count header
("The catalog ships 51 recipes across 4 groups"), and keep the existing note that `add-test-coverage`
is the single `*` recipe (now reworded — it replaces `add-unit-test` as the cross-type entry).
**feature-003 does NOT edit** the adjacent **YAML Front-Matter field table** (~lines 48–66), the
**Valid `applies-to` values table** (~lines 68–80), or the **`summary:` field doc** — those are
feature-001's. The two edits sit in non-overlapping line ranges of the same file.

**2. `.aid/knowledge/domain-glossary.md` `Seed Catalog` term (line 168)** — feature-003 owns this.
Currently: `**Seed Catalog (5 recipes)** | \`bug-fix.md\`, \`method-refactor.md\`,
\`add-crud-endpoint.md\`, \`add-unit-test.md\`, \`write-release-note.md\`.` Replace with a
**51-recipe** definition: rename the term to `**Recipe Catalog (51 recipes)**` (or keep "Seed
Catalog" label but update the count to 51), and replace the 5-file enumeration with a description of
the 4 groups (40 add/change pairs across 11 target-kind families, 7 bug-fix, 3 refactor-only, 1
cross-type) pointing at `recipes/README.md` `## Seed Catalog`. **feature-003 does NOT touch** the
`workType` enum (line 147), `applies-to` term (line 167), `Recipe`/`Slot`/`Slot escape` terms
(lines 164–166), or the LITE-* sub-path rows — those are feature-001 / feature-002. Add a dated
`changelog:` front-matter entry to `domain-glossary.md`: "work-001 feature-003 — recipe catalog
expanded to 51 (5 seed recipes migrated + 46 new recipe names authored; 47 files newly created
on disk since the `write-release-note` split adds a second new file); Seed Catalog term updated."

### Validation & Verification

Run in order; all must pass:

1. **Every recipe validates clean.** Loop `--validate` over all recipe files and assert each prints
   `OK: all checks passed` with no `WARN`:
   ```sh
   fail=0
   for f in canonical/recipes/*.md; do
     [ "$(basename "$f")" = "README.md" ] && continue
     out=$(bash canonical/scripts/interview/parse-recipe.sh --validate "$f" 2>&1) || fail=1
     printf '%s\n' "$out" | grep -q '^OK: all checks passed' || { echo "FAIL: $f"; echo "$out"; fail=1; }
     printf '%s\n' "$out" | grep -q '^WARN' && { echo "WARN: $f"; echo "$out"; fail=1; }
   done
   [ "$fail" -eq 0 ] && echo "ALL RECIPES VALID (51)"
   ```
   This asserts `## spec` + `## tasks` present, `slot-count`/`task-count` match the body, and
   `name` = basename (no WARN) for all 51 (AC4).
2. **Catalog count = 51.** `ls canonical/recipes/*.md | grep -v '/README.md$' | wc -l` = 51; the
   old `write-release-note.md` is gone; the 4 renamed-away old names (`method-refactor.md`,
   `add-crud-endpoint.md`, `bug-fix.md`, `add-unit-test.md`) are gone; their new-named files exist.
3. **Naming-convention grep.** `ls canonical/recipes/ | grep -vE '\.md$|^README' ; ls
   canonical/recipes/ | grep -E '^(add|change|fix|improve|bump|rename)-' | wc -l` = 51 — every
   recipe file matches the convention (the 3 refactor-only verbs are the documented exceptions).
4. **Smoke test still green (feature-003 updates Units 15–19 in lockstep).**
   `bash tests/canonical/test-parse-recipe.sh` exits 0. Units 15–19 of that test reference the OLD
   seed-recipe filenames (`bug-fix.md`, `write-release-note.md`, `method-refactor.md`,
   `add-crud-endpoint.md`, `add-unit-test.md`); feature-003's renames/removal are what break them,
   so **feature-003 owns updating those references** as part of this work (see § Scope & Files for
   the dual-ownership with feature-001 and the per-unit old→new map). Apply the map: Unit 15
   `bug-fix.md`→`fix-application.md`, Unit 16 `write-release-note.md`→`add-docs.md` (retargeted —
   old file removed by the split), Unit 17 `method-refactor.md`→`change-member.md`, Unit 18
   `add-crud-endpoint.md`→`add-api-endpoint.md`, Unit 19 `add-unit-test.md`→`add-test-coverage.md`
   (each unit's `SEED_FILE=` path, banner, comment header at ~lines 25–29, and both `assert_*`
   strings move together). With these references retargeted, all five units validate files that
   exist post-migration and the smoke test stays green. feature-003 edits a **distinct line range**
   of this file from feature-001 (which owns the enum-token fixtures at lines 145, 205), so there is
   no conflict — only a sequencing requirement that both edits land in the same work (see § Risks).
5. **Re-render to 5 trees, byte-identical (AC5).** Run `/aid-generate`; recipes use the passthrough
   renderer (no front-matter injection), so canonical bytes flow unchanged. The deterministic
   verify (`verify_deterministic.py`) asserts the rendered recipes are byte-identical across
   `antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`. Confirm the 51 files (and the
   removal of `write-release-note.md`) propagated to all 5 trees.
6. **No old enum tokens in recipe files (contributes to the work-level AC1 gate).**
   `grep -nE 'small-refactor|small-new-feature|single-doc' canonical/recipes/*.md` returns nothing
   — every migrated recipe's `applies-to:` is on the new 3-value enum. (This is the recipe-file
   portion of the work-level "zero old tokens across all canonical files" sweep that runs after
   feature-003, per feature-001 SPEC.)

### Risks / Sequencing

- **Depends on feature-001 (DEFINITION).** The `summary:` field convention and the 3-value
  `applies-to` enum must exist in the schema docs before/with these recipes. feature-003's recipes
  carry `summary:` and use `{bug-fix, new-feature, refactor, *}` — both established by feature-001.
  Mitigation: same work/delivery, sequential spec; recipes parse regardless (unknown-field
  tolerance), so a recipe authored with `summary:` validates even if the README field-doc lands in
  the same PR.
- **Depends on feature-002 (CONSUMER).** feature-002's description-first TRIAGE matching consumes
  the `summary:` line. The catalog's `summary` one-liners must be discriminative (distinct per
  recipe) so matching works. Mitigation: the manifest's draft summaries are written to be
  distinguishing; execution keeps them one-line and distinct.
- **Smoke-test fixture coupling — RESOLVED (feature-003 owns the fix; sequencing note only).**
  `tests/canonical/test-parse-recipe.sh` Units 15–19 hard-reference the 5 old seed-recipe
  filenames, and feature-003's renames/removal break those references. **Resolution (owner of all
  three features): feature-003 OWNS updating the Units 15–19 recipe-filename references**, because
  feature-003's renames cause the breakage and a green smoke test is feature-003's own AC
  (§ Validation step 4). This is **dual-ownership** of the test file with feature-001 at
  **non-overlapping** line ranges — feature-001 owns the enum-token fixtures (`small-new-feature`
  at both lines 145 and 205), feature-003 owns the Units 15–19 recipe-filename references
  (~lines 25–29, 797–866) — exactly the README dual-ownership pattern. The old→new map and the
  `write-release-note`→`add-docs.md` retarget are specified in § Scope & Files and § Validation
  step 4. **No Q&A / escalation is open or required.** Genuine sequencing note that remains: both
  feature-001 (enum fixtures) and feature-003 (Units 15–19 filename refs) edit this one test file
  at different lines, so both edits **must land in the same work** (PLAN must keep them in one
  delivery) for the smoke test to be green at the end of the work — a coordination constraint, not
  an unresolved decision.
- **Scale risk (47 new files).** Authoring ~47 recipes is the bulk of the effort and the main
  correctness risk (count drift, missing blocks, name/basename mismatch). Mitigation: (a)
  **breadth-first** — every recipe is the same minimal single-concern shape (1 task for most;
  2–3 for the few multi-step families), so each is a small delta from the `add-api-endpoint`
  exemplar; (b) the **fully-worked exemplar** above is the copy-paste template; (c) the add/change
  pairs **share slot structure**, halving the design effort per family; (d) the **automated
  `--validate` loop** (step 1) catches every count/block error before review, so quality does not
  depend on manual inspection of 51 files.
- **Merge deferred (scope discipline).** The 20 add/change pairs are obvious merge candidates
  (Axis A) but consolidation is **out of scope** — a follow-up work. Authoring them separately now
  is intentional (design-notes Decision 5); the shared slot structure documented above is what makes
  the later merge safe.
