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

The seed catalog ships five recipes:

| Recipe file         | applies-to        | Slots | Tasks | Typical use                          |
|---------------------|-------------------|-------|-------|--------------------------------------|
| `bug-fix.md`        | `bug-fix`         | 4     | 1     | Fix a known defect + add a unit test |
| `method-refactor.md`| `small-refactor`  | 5     | 1     | Refactor a single method             |
| `add-crud-endpoint.md` | `small-new-feature` | 6 | 3  | New CRUD endpoint with tests         |
| `write-release-note.md` | `single-doc`  | 4     | 1     | Draft a versioned release note       |
| `add-unit-test.md`  | `*`               | 4     | 1     | Add a unit test for any workType     |

The `add-unit-test` recipe uses `applies-to: *` because writing a unit test is
a cross-type pattern (useful for bug fixes, refactors, and new features alike).
All other seed recipes target a specific workType.

---

## Recipe Format

A recipe is a single Markdown file directly under `canonical/recipes/`. It has two
parts: a YAML front-matter block and a body containing `## spec` and `## tasks`
blocks.

### YAML Front-Matter

```
---
name: bug-fix
applies-to: bug-fix
slot-count: 4
task-count: 1
---
```

All four fields are required.

| Field        | Type            | Description                                                       |
|--------------|-----------------|-------------------------------------------------------------------|
| `name`       | string (kebab)  | Unique recipe id. Must match the file basename (without `.md`).   |
| `applies-to` | string          | The `workType` value this recipe matches. See valid values below. |
| `slot-count` | integer         | Number of unique `{{slot}}` tokens in the body.                   |
| `task-count` | integer         | Number of `### task-NNN` headings in the `## tasks` block.        |

Valid `applies-to` values:

| Value               | When used                                      |
|---------------------|------------------------------------------------|
| `bug-fix`           | Fixing a defect                                |
| `small-refactor`    | Refactoring — a method, a class                |
| `single-doc`        | Writing one document or artifact               |
| `small-new-feature` | Adding a small new feature                     |
| `*`                 | Cross-type: offered for any `workType`         |

The `*` value should be reserved for patterns that are genuinely useful regardless
of work type. Overuse adds catalog noise; the seed catalog ships only one `*`
recipe (`add-unit-test`).

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
substitution. Must include the sections that `aid-execute` and the FR2 delivery
gate consume: `# {title}`, `## Goal`, `## Context`, `## Acceptance Criteria`,
`## Tasks` (table), `## Execution Graph` (two tables), `## Revision History`.

**`## tasks` block** — one `### task-NNN — Title` sub-heading per task. Each
becomes a rendered `tasks/task-NNN.md` file. The task shape is the 6-section
flat form defined in `canonical/templates/delivery-plans/task-template.md`
(title heading, Type, Source, Depends on, Scope, Acceptance Criteria).

### Full Example (bug-fix recipe)

```markdown
---
name: bug-fix
applies-to: bug-fix
slot-count: 4
task-count: 1
---

## spec

# Fix: {{bug-title}}

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
| {{date}} | Created from recipe `bug-fix` | /aid-interview lite path |

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

---

## How Recipes Are Discovered by `/aid-interview` Triage

### Triage flow overview

`/aid-interview` runs 2–3 deterministic triage questions (T1 breadth, T2 size,
T3 type) and applies a routing rule:

- **FULL** — any single "large" signal routes to the full pipeline.
- **LITE** — all signals small → lite path, with a `workType` value derived from
  the T3 answer (`bug-fix`, `small-refactor`, `single-doc`, or `small-new-feature`).

### Recipe-offer step (T3 → recipe-offer)

The recipe-offer step fires **inside the lite path**, after the `workType` is
determined and after the user accepts or overrides the auto-selected sub-path
(LITE-BUG-FIX, LITE-DOC, LITE-REFACTOR, or LITE-FEATURE), but **before** the
sub-path's condensed interview begins. Sequencing:

```
T1 → T2 → T3
  → path = LITE, workType = bug-fix
  → sub-path: LITE-BUG-FIX (auto-selected; user may override)
  → user accepts sub-path
  → recipe-offer: filter catalog for applies-to == "bug-fix" OR applies-to == "*"
  → offer list presented; user picks a recipe OR declines
  → if recipe: slot-fill → emit → hand-off to /aid-execute
  → if declined: standard LITE-BUG-FIX condensed interview
```

### Triage T3 → workType mapping

The triage's T3 question ("what kind of work is it?") maps directly to the
`workType` signal and from there to the recipe `applies-to` filter:

| T3 answer                  | workType            | Recipes offered (`applies-to`)       |
|----------------------------|---------------------|--------------------------------------|
| bug fix                    | `bug-fix`           | `bug-fix` + `*`                      |
| small refactor             | `small-refactor`    | `small-refactor` + `*`               |
| single document / artifact | `single-doc`        | `single-doc` + `*`                   |
| new feature or system      | `small-new-feature` | `small-new-feature` + `*`            |

If no recipe matches (the catalog is empty or no `applies-to` matches), the
recipe-offer step is skipped and the standard lite-path interview runs.

### Triage T3 → workType → standard-lite escalation

The relationship between T3, workType, the recipe-offer step, and standard-lite
is a chain, not a branch — recipes accelerate the lite path but do not replace it:

```
T3 → workType (LITE routing confirmed)
  └─ recipe-offer fires
       ├─ user picks recipe → slot-fill → emit (skips condensed interview)
       └─ user declines → standard lite-path condensed interview runs (unchanged)
            └─ if work proves large → escalate to FULL path (FR1 escalation)
```

A recipe-instantiated work can escalate at any point:
- During slot-fill: user types `/aid-interview escalate-from-recipe`. Slot values
  already supplied are preserved in the work-area `STATE.md ## Recipe Slots` block
  and seeded into the standard lite-path interview.
- After emission: same escalation path as any other lite work (FR1 lite → full).

---

## Authoring a New Recipe

1. Copy `canonical/recipes/RECIPE-TEMPLATE.md` to `canonical/recipes/{name}.md`
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
   `canonical/recipes/` into all three install trees (claude-code, codex, cursor).

### Conventions

- **One concern per recipe.** If a recipe needs more than 2–3 tasks and more than
  ~6 slots, it is probably not a lite-path pattern — consider the full pipeline
  instead.
- **Self-describing slot names.** Prefer `bug-description-one-sentence` over
  `desc`. The slot name is shown verbatim as the prompt label during slot-fill.
- **Slot-name lexical rule:** `[a-z][a-z0-9-]*`. No underscores, uppercase, dots,
  or spaces.
- **Reserve `applies-to: *` for cross-type patterns.** The seed catalog ships one
  `*` recipe (`add-unit-test`). A catalog with many `*` recipes creates noise on
  every lite-path triage.
- **No recipe versioning.** Updating a recipe file updates everyone's behavior. If
  a recipe needs breaking changes, author a new recipe (`bug-fix-v2`) and let the
  old one age out.
- **Flat layout.** Place recipes directly under `canonical/recipes/` — no
  subdirectories. Sub-directories may be introduced if the catalog grows past
  approximately 15 recipes.
- **Default task types:** IMPLEMENT for code changes, DOCUMENT for document
  artifacts, TEST for test-only tasks, REFACTOR for refactoring work.

---

## Relationship to the Lite Path and Standard Pipeline

```
/aid-interview
  ├─ FULL path  → Interview → Specify → Plan → Detail → /aid-execute
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
emerge. Project-local recipes live alongside the seed recipes in `canonical/recipes/`
if maintained with the canonical source.

To contribute a recipe back to the seed catalog, follow the authoring steps above,
verify slot and task counts, and submit the recipe file in a PR.
