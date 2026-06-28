# AID Recipes Catalog

Recipes are pre-filled lite-path templates for frequently occurring small-work
patterns. Instead of answering the condensed lite-path interview, the user picks
a recipe and fills in named slots — typically under one minute of user time.

A recipe-instantiated work is a standard lite work: same `.aid/work-NNN/SPEC.md`
+ `tasks/task-NNN.md` shape, same hand-off to `/aid-execute`. The recipe is only
a faster way to seed the lite path's output.

---

## Purpose

The lite path (feature-005) collapses Interview → Specify → Plan → Detail into a
single condensed flow, but the user still answers interview-style questions to
derive a SPEC and task list. For frequently recurring patterns — bug fixes,
refactors, release notes — that interview is redundant: the structure of the work
is already known. Recipes eliminate it by shipping the structure pre-filled;
the user provides only the work-specific slot values.

---

## Seed Catalog

The catalog ships 51 recipes across 4 groups.

### Group 1 — add/change pairs (40 recipes, 20 pairs across 11 target-kind families)

`add-X` recipes use `applies-to: new-feature`; `change-X` recipes use `applies-to: refactor`.

| # | Recipe | Slots | Tasks | Target-kind family |
|---|--------|-------|-------|--------------------|
| 1 | `add-member` | 4 | 1 | Objects / Models |
| 2 | `change-member` | 5 | 1 | Objects / Models |
| 3 | `add-interface` | 4 | 1 | Objects / Models |
| 4 | `change-interface` | 5 | 1 | Objects / Models |
| 5 | `add-api-endpoint` | 6 | 3 | API |
| 6 | `change-api-endpoint` | 6 | 2 | API |
| 7 | `add-api-middleware` | 4 | 2 | API |
| 8 | `change-api-middleware` | 5 | 1 | API |
| 9 | `add-ui-endpoint` | 5 | 2 | UI |
| 10 | `change-ui-endpoint` | 5 | 1 | UI |
| 11 | `add-ui-component` | 5 | 2 | UI |
| 12 | `change-ui-component` | 5 | 1 | UI |
| 13 | `add-ui-style` | 4 | 1 | UI |
| 14 | `change-ui-style` | 4 | 1 | UI |
| 15 | `add-cli-command` | 5 | 2 | CLI command |
| 16 | `change-cli-command` | 5 | 1 | CLI command |
| 17 | `add-entity` | 5 | 2 | DB / Storage |
| 18 | `change-schema` | 5 | 2 | DB / Storage |
| 19 | `add-container` | 4 | 1 | DB / Storage |
| 20 | `change-container` | 5 | 1 | DB / Storage |
| 21 | `add-config-option` | 4 | 1 | config / feature flag |
| 22 | `change-config-option` | 5 | 1 | config / feature flag |
| 23 | `add-feature-flag` | 4 | 1 | config / feature flag |
| 24 | `change-feature-flag` | 4 | 1 | config / feature flag |
| 25 | `add-job` | 5 | 2 | job |
| 26 | `change-job` | 5 | 1 | job |
| 27 | `add-event-handler` | 5 | 2 | event handler / consumer |
| 28 | `change-event-handler` | 5 | 1 | event handler / consumer |
| 29 | `add-queue` | 4 | 2 | event handler / consumer |
| 30 | `change-queue` | 5 | 1 | event handler / consumer |
| 31 | `add-message` | 4 | 1 | event handler / consumer |
| 32 | `change-message` | 5 | 1 | event handler / consumer |
| 33 | `add-rule` | 4 | 1 | validation / business rule |
| 34 | `change-rule` | 5 | 1 | validation / business rule |
| 35 | `add-docs` | 4 | 1 | documentation / report |
| 36 | `change-docs` | 4 | 1 | documentation / report |
| 37 | `add-report` | 4 | 1 | documentation / report |
| 38 | `change-report` | 4 | 1 | documentation / report |
| 39 | `add-integration` | 5 | 2 | integration / external client |
| 40 | `change-integration` | 5 | 1 | integration / external client |

### Group 2 — bug-fix recipes (7), `applies-to: bug-fix`

| # | Recipe | Slots | Tasks | Focus area |
|---|--------|-------|-------|------------|
| 41 | `fix-application` | 4 | 1 | domain / business-logic (broad default) |
| 42 | `fix-infrastructure` | 4 | 1 | infrastructure / deployment / config |
| 43 | `fix-api` | 4 | 1 | API-layer (status, contract, payload) |
| 44 | `fix-ui` | 4 | 1 | UI-layer (rendering, interaction, state) |
| 45 | `fix-integration` | 4 | 1 | external-service integration |
| 46 | `fix-regression` | 5 | 1 | regression (bisect to introducing change) |
| 47 | `fix-security` | 5 | 1 | security vulnerability |

### Group 3 — refactor-only recipes (3), `applies-to: refactor`

| # | Recipe | Slots | Tasks | Description |
|---|--------|-------|-------|-------------|
| 48 | `improve-performance` | 5 | 2 | Improve a hot path against a measured baseline |
| 49 | `bump-dependency` | 4 | 2 | Upgrade a dependency and reconcile breaking changes |
| 50 | `rename-symbol` | 4 | 1 | Rename a symbol across the codebase |

### Group 4 — cross-type recipe (1), `applies-to: *`

| # | Recipe | Slots | Tasks | Description |
|---|--------|-------|-------|-------------|
| 51 | `add-test-coverage` `*` | 4 | 1 | Add test coverage for any work type |

`add-test-coverage` is the single `*` recipe — writing tests is a cross-type pattern
(useful for bug fixes, refactors, and new features alike). All other recipes target
a specific `workType`.

---

## Recipe Format

A recipe is a single Markdown file directly under `.github/aid/recipes/`. It has two
parts: a YAML front-matter block and a body containing `## spec` and `## tasks`
blocks.

### YAML Front-Matter

```
---
name: bug-fix
applies-to: bug-fix
slot-count: 4
task-count: 1
summary: Fix a known defect and add a regression test.
---
```

The first four fields are required. `summary:` is optional.

| Field        | Type            | Description                                                       |
|--------------|-----------------|-------------------------------------------------------------------|
| `name`       | string (kebab)  | Unique recipe id. Must match the file basename (without `.md`).   |
| `applies-to` | string          | The `workType` value this recipe matches. See valid values below. |
| `slot-count` | integer         | Number of unique `{{slot}}` tokens in the body.                   |
| `task-count` | integer         | Number of `### task-NNN` headings in the `## tasks` block.        |
| `summary`    | string (one-line) | Optional. One-line description read by TRIAGE for description→recipe matching. Not validated by `parse-recipe.sh`. |

Valid `applies-to` values:

| Value        | When used                                      |
|--------------|------------------------------------------------|
| `bug-fix`    | Fixing a defect                                |
| `refactor`   | Refactoring — a method, a class                |
| `new-feature`| Adding a new feature                           |
| `*`          | Cross-type: offered for any `workType`         |

The `*` value should be reserved for patterns that are genuinely useful regardless
of work type. Overuse adds catalog noise; the catalog ships only one `*`
recipe (`add-test-coverage`).

### Slot Syntax

Slots are written as `{{slot-name}}` anywhere in the body — in the `## spec` block
or the `## tasks` block. During instantiation, the lite-path triage prompts the
user for each unique slot name in order; the supplied value replaces every
occurrence of that token.

**Slot-name lexical rule:** `[a-z][a-z0-9-]*` — starts with a lowercase ASCII
letter, followed by lowercase letters, digits, or hyphens. No underscores,
uppercase, dots, or spaces.

Valid slot names: `{{bug-title}}`, `{{class-name}}`, `{{release-version}}`

Invalid (will not be recognized as slots): `{{BugTitle}}`, `{{bug_title}}`,
`{{bug title}}`

**Escape sequence for literal `{{`:** If the rendered output should contain a
literal `{{` (not treated as a slot), write `{!{` in the recipe body. At emit time
the parser rewrites `{!{` to `{{`. This is needed when a recipe body discusses
template or shell brace syntax as display content.

Example:
```
Use {!{variable} to expand in Bash.
```
Renders to: `Use {{variable} to expand in Bash.`

### Body Structure

The body contains two blocks in order:

```
## spec

<work-root SPEC.md skeleton — slot tokens allowed>

## tasks

### task-001 — <title>

- Type: <task type>
- Source: <work-name> → delivery-001
- Depends on: —
- Scope: <scope with slot tokens>
- Acceptance Criteria:
  - [ ] <criterion with slot tokens>
```

**`## spec` block** — becomes the rendered `.aid/work-NNN/SPEC.md` after slot
substitution. The lowercase `## spec` is intentional — it distinguishes the
in-recipe block-marker from any `## SPEC` heading the body might contain. The
parser matches this marker case-sensitively. Must include the sections that
`aid-execute` and the FR2 delivery gate consume (per feature-005 SPEC work-root
schema):

- `# {title}` — work title heading
- **Metadata block** — four bold key/value lines immediately after the title:
  - `**Work:** ...` — the work identifier (e.g., `work-NNN`)
  - `**Created:** ...` — creation date
  - `**Source:** ...` — originating recipe and path (e.g., `/aid-describe lite path`)
  - `**Status:** ...` — current status (e.g., `Active`)
- `## Goal`
- `## Context`
- `## Acceptance Criteria`
- `## Tasks` (table: Task | Type | Title)
- `## Execution Graph` (two tables: Task | Depends On; Can Be Done In Parallel)
- `## Revision History`

**`## tasks` block** — one `### task-NNN — Title` sub-heading per task. Each
becomes a rendered `tasks/task-NNN.md` file. The task shape is the 6-section
flat form defined in `.github/aid/templates/delivery-plans/task-template.md`
(title heading, Type, Source, Depends on, Scope, Acceptance Criteria).

### Full Example (fix-application recipe)

> **slot-count note:** `{{date}}` and `{{work-name}}` are counted as explicit
> slot tokens in this example (slot-count: 6). In a real recipe these two tokens
> would normally be auto-filled by the orchestrator from context (current date and
> the assigned work identifier), which would reduce the user-visible slot-fill
> count to 4. Whether to treat them as explicit slots or rely on auto-fill is an
> authoring choice; the parser-counting rule is the same either way — count every
> unique `{{slot-name}}` token present in the body.

```markdown
---
name: fix-application
applies-to: bug-fix
slot-count: 6
task-count: 1
---

## spec

# Fix: {{bug-title}}

**Work:** {{work-name}}
**Created:** {{date}}
**Source:** recipe `fix-application` via /aid-describe lite path
**Status:** Active

## Goal

Fix the defect described below.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the bug.
- [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
- [ ] No regression in adjacent test suites.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Apply the fix |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| {{date}} | Created from recipe `fix-application` | /aid-describe lite path |

## tasks

### task-001 — Apply the fix

- Type: IMPLEMENT
- Source: {{work-name}} → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the bug.
  - [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
  - [ ] No regression in adjacent test suites.
```

### Multi-Task Example (add-api-endpoint shape)

The following abbreviated example shows the `## tasks` block with multiple
`### task-NNN` headings. Front-matter and spec block are truncated for brevity.

```markdown
---
name: add-api-endpoint
applies-to: new-feature
slot-count: 5
task-count: 3
---

## spec

# Add API endpoint: {{resource-name}}

**Work:** {{work-name}}
**Created:** {{date}}
**Source:** recipe `add-api-endpoint` via /aid-describe lite path
**Status:** Active

## Goal

Add a full CRUD REST endpoint for the `{{resource-name}}` resource.

## Context

{{resource-description}}

## Acceptance Criteria

- [ ] GET / POST / PUT / DELETE endpoints exist for `/{{route-prefix}}/{{resource-name}}`.
- [ ] All endpoints are covered by integration tests.
- [ ] No regression in existing endpoint tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{resource-name}} data layer |
| task-002 | IMPLEMENT | Implement {{resource-name}} API handlers |
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
| {{date}} | Created from recipe `add-api-endpoint` | /aid-describe lite path |

## tasks

### task-001 — Implement {{resource-name}} data layer

- Type: IMPLEMENT
- Source: {{work-name}} → delivery-001
- Depends on: —
- Scope: Create the data model and repository layer for `{{resource-name}}`.
- Acceptance Criteria:
  - [ ] Data model defined for `{{resource-name}}`.
  - [ ] Repository CRUD methods implemented and unit-tested.

### task-002 — Implement {{resource-name}} API handlers

- Type: IMPLEMENT
- Source: {{work-name}} → delivery-001
- Depends on: task-001
- Scope: Add GET / POST / PUT / DELETE handlers at `/{{route-prefix}}/{{resource-name}}`.
- Acceptance Criteria:
  - [ ] All four HTTP methods respond correctly.
  - [ ] Error responses follow the existing API error shape.

### task-003 — Integration tests for {{resource-name}} endpoints

- Type: TEST
- Source: {{work-name}} → delivery-001
- Depends on: task-002
- Scope: Write integration tests covering all four CRUD operations.
- Acceptance Criteria:
  - [ ] Happy-path tests pass for all four operations.
  - [ ] At least one error-path test per operation.
```

---

## How Recipes Are Discovered by `/aid-describe` Triage

### Triage flow overview

`/aid-describe` uses a **description-first** triage flow:

1. The user gives a free-form work description in their own words.
2. The agent infers the internal `workType` ∈ `{bug-fix, new-feature, refactor}`
   from the description and finds the best-matching recipe by reading each
   recipe's `summary:` front-matter field.
3. The agent presents a **single confirmation turn**: "Looks like a {type} —
   recipe `{name}` ({summary}). Correct?"
4. The routing rule is intentionally conservative:
   - A confident single-recipe match that the user accepts → **lite path** with
     that recipe.
   - An ambiguous, multi-target, or no-match description, or a user rejection
     (`[2]`) → **full path**.

The user never picks a work type from a menu. `workType` is agent-inferred and
recorded internally in `STATE.md ## Triage`; the sub-path
(`LITE-BUG-FIX`, `LITE-REFACTOR`, or `LITE-FEATURE`) is derived from it.

### Recipe discovery — candidate set and matching

After the agent infers `workType`, it scans `.github/aid/recipes/` and reads each
recipe's `applies-to:` and `summary:` fields. The **candidate set** is:

```
recipe.applies-to == workType   OR   recipe.applies-to == '*'
```

Within the candidate set the agent picks the recipe whose `summary:` text best
matches the user's description (semantic match — agent inference, no script).
The `*` recipe (`add-test-coverage`) participates in the candidate set for every
inferred type.

If no recipe matches, the recipe-offer step is skipped and the standard lite-path
condensed interview runs.

### Description-first sequencing example

```
User: "fix the login crash on special characters"
  → agent infers workType = bug-fix
  → candidate set: applies-to == "bug-fix" OR "*"
  → summary match: fix-application ("Fix a domain/business-logic defect …")
  → confirmation turn: "Looks like a bug-fix — recipe `fix-application` (…). [1] Yes …"
  → user [1] → lite / LITE-BUG-FIX, recipe = fix-application
  → slot-fill → emit → hand-off to /aid-execute
```

### workType → Sub-path mapping

| `workType` | Sub-path |
|------------|----------|
| `bug-fix` | `LITE-BUG-FIX` |
| `refactor` | `LITE-REFACTOR` |
| `new-feature` | `LITE-FEATURE` |

Documentation and report work classifies as `new-feature` (creating a new
doc/report → `LITE-FEATURE`, recipes `add-docs`/`add-report`) or `refactor`
(editing an existing doc/report → `LITE-REFACTOR`, recipes `change-docs`/
`change-report`). There is no dedicated doc-only sub-path.

### Recipe-confirmed path and escalation

Once a recipe is confirmed the lite path continues immediately into slot-fill
(no separate condensed interview):

```
description → inferred workType → candidate set → best match → user confirms
  → slot-fill → emit SPEC.md + tasks/ → hand-off to /aid-execute
  └─ user declines recipe → standard lite-path condensed interview
       └─ if work proves large → escalate to FULL path (FR1 escalation)
```

A recipe-instantiated work can escalate at any point:
- During slot-fill: user types `/aid-describe escalate-from-recipe`. Slot values
  already supplied are preserved in the work-area `STATE.md ## Recipe Slots` block
  and seeded into the standard lite-path interview.
- After emission: same escalation path as any other lite work (FR1 lite → full).

---

## Authoring a New Recipe

1. Copy `.github/aid/templates/recipe-template.md` to `.github/aid/recipes/{name}.md`
   where `{name}` is the kebab-case recipe id.

2. Fill in the YAML front-matter:
   - `name` — must match the file basename (without `.md`).
   - `applies-to` — choose one value from the valid set, or `*` for cross-type
     (use `*` only if the recipe is genuinely useful for any workType).
   - `slot-count` — count unique `{{slot}}` token names in the body.
   - `task-count` — count `### task-NNN` headings in `## tasks`.

3. Write the `## spec` block: a work-root `SPEC.md` skeleton with `{{slot}}`
   placeholders for everything work-specific. Include all required sections
   (`## Goal`, `## Context`, `## Acceptance Criteria`, `## Tasks`,
   `## Execution Graph`, `## Revision History`).

4. Write the `## tasks` block: one `### task-NNN — Title` sub-heading per task,
   using the 6-section flat task shape. Slot tokens are allowed in task bodies.

5. Verify `slot-count` by counting unique `{{slot-name}}` tokens with:
   ```sh
   grep -oE '\{\{[a-z][a-z0-9-]*\}\}' {name}.md | sort -u | wc -l
   ```

6. Verify `task-count` by counting `### task-NNN` headings:
   ```sh
   grep -c '^### task-' {name}.md
   ```

7. After adding the file, re-run the work-002 generator to render the updated
   `.github/aid/recipes/` into all three install trees (claude-code, codex, cursor).

### Conventions

- **One concern per recipe.** If a recipe needs more than 2–3 tasks and more than
  ~6 slots, it is probably not a lite-path pattern — consider the full pipeline
  instead.
- **Self-describing slot names.** Prefer `bug-description-one-sentence` over
  `desc`. The slot name is shown verbatim as the prompt label during slot-fill.
- **Slot-name lexical rule:** `[a-z][a-z0-9-]*`. No underscores, uppercase, dots,
  or spaces.
- **Reserve `applies-to: *` for cross-type patterns.** The catalog ships one
  `*` recipe (`add-test-coverage`). A catalog with many `*` recipes creates noise on
  every lite-path triage.
- **No recipe versioning.** Updating a recipe file updates everyone's behavior. If
  a recipe needs breaking changes, author a new recipe (`bug-fix-v2`) and let the
  old one age out.
- **Flat layout.** Place recipes directly under `.github/aid/recipes/` — no
  subdirectories. Sub-directories may be introduced if the catalog grows past
  approximately 15 recipes.
- **Default task types:** IMPLEMENT for code changes, DOCUMENT for document
  artifacts, TEST for test-only tasks, REFACTOR for refactoring work.

---

## Relationship to the Lite Path and Standard Pipeline

```
/aid-describe/  ├─ FULL path  → Interview → Specify → Plan → Detail → /aid-execute
  └─ LITE path  (feature-005)
       └─ workType determined
            ├─ recipe-offer (feature-011)
            │    ├─ user picks recipe → slot-fill → emit → /aid-execute
            │    └─ user declines
            └─ standard condensed interview → SPEC.md + tasks/ → /aid-execute
```

Recipes are a speed layer inside the lite path. They do not change the methodology,
the artifact shapes, the review model (FR2), or the parallel execution model (FR6).
A recipe-instantiated work is processed by `aid-execute` identically to a
free-form-interview lite work.

---

## Adding Recipes to This Catalog

This catalog is open. Projects are expected to add their own recipes as patterns
emerge. Project-local recipes live alongside the seed recipes in `.github/aid/recipes/`
if maintained with the canonical source.

To contribute a recipe back to the seed catalog, follow the authoring steps above,
verify slot and task counts, and submit the recipe file in a PR.
