---
name: {{recipe-name}}  # Fill in before saving as .agent/recipes/{name}.md. These slots are placeholders, not real recipe slots.
applies-to: {{applies-to}}
slot-count: {{slot-count}}
task-count: {{task-count}}
---

## spec

# {{work-title}}

**Work:** {{work-name}}
**Created:** {{date}}
**Source:** recipe `{{recipe-name}}` via /aid-interview lite path
**Status:** Active

## Goal

{{goal-one-paragraph}}

## Context

{{context-constraints}}

## Acceptance Criteria

- [ ] {{acceptance-criterion-1}}
- [ ] {{acceptance-criterion-2}}

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | {{task-001-type}} | {{task-001-title}} |

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
| {{date}} | Created from recipe `{{recipe-name}}` | /aid-interview lite path |

## tasks

<!-- Multi-task recipes add ### task-002 etc. with `**Depends on:** task-NNN` per task; see .agent/recipes/add-crud-endpoint.md for a 3-task example. -->

### task-001 — {{task-001-title}}

- Type: {{task-001-type}}
- Source: {{work-name}} → delivery-001
- Depends on: —
- Scope: {{task-001-scope}}
- Acceptance Criteria:
  - [ ] {{task-001-criterion-1}}
  - [ ] {{task-001-criterion-2}}

---

<!--
RECIPE AUTHORING GUIDE
======================

## What this file is

This is the meta-template for AID lite-path recipes. Copy and fill it in to author
a new recipe. A recipe is a single Markdown file with YAML front-matter + a body
containing two blocks: `## spec` (the work-root SPEC.md skeleton) and `## tasks`
(the task-NNN.md skeletons).

## YAML front-matter fields (all required)

| Field        | Type            | Description                                                     |
|--------------|-----------------|-----------------------------------------------------------------|
| name         | string (kebab)  | Unique recipe id. Must match the file basename (without .md).   |
| applies-to   | string          | The workType this recipe matches. See valid values below.        |
| slot-count   | integer         | Number of unique {{slot}} tokens in the body. Used for display. |
| task-count   | integer         | Number of ### task-NNN headings in ## tasks. Used for display.  |

Valid `applies-to` values (from feature-005 type-aware triage):
  bug-fix            — a bug fix
  small-refactor     — a small refactor (a method, a class)
  single-doc         — a single document or artifact
  small-new-feature  — a small new feature
  *                  — matches any workType (use sparingly — see conventions)

## Slot syntax

Slots are written as {{slot-name}} anywhere in the body (spec block or tasks block).
Slot names follow the regex [a-z][a-z0-9-]* — lowercase ASCII letter first, then
lowercase letters, digits, or hyphens only. No underscores, uppercase, dots, or
spaces in slot names.

Examples of valid slot names:
  {{bug-title}}
  {{class-name}}
  {{release-version}}
  {{acceptance-criterion-1}}

If you need a literal {{ in the rendered output (e.g., the rendered SPEC.md should
contain {{ as a display character), write {!{ instead. The parser rewrites {!{ to
literal {{ at emit time without treating it as a slot token.

Example — a recipe that documents shell brace expansion:
  Use {!{variable} to expand a variable.
  Renders to: Use {{variable} to expand a variable.

## slot-count field

Count every unique {{slot-name}} token in the body. If the same slot name appears
more than once (e.g., {{class-name}} used in both Goal and Scope), count it once.
The parser warns if the declared slot-count does not match the actual unique token
count; instantiation continues but the mismatch is surfaced to the user.

## task-count field

Count the number of ### task-NNN headings in the ## tasks block. The parser warns
if the declared task-count does not match the actual heading count; instantiation
continues.

## ## spec block

The ## spec heading marks the start of the work-root SPEC.md skeleton. Everything
between ## spec and ## tasks (or end of file if no ## tasks block exists) becomes
the rendered work-root .aid/work-NNN/SPEC.md after slot substitution.

Lowercase ## spec is intentional — it distinguishes the in-recipe block-marker from
any ## SPEC heading the body might contain. The parser matches this marker
case-sensitively; ## Spec or ## SPEC are not recognized as the block-start marker.

The spec block must include the sections that aid-execute and the FR2 delivery gate
need (per feature-005 work-root SPEC.md schema):
  # {title}
  Metadata block — four bold key/value lines:
    **Work:** ...      — the work identifier
    **Created:** ...   — creation date
    **Source:** ...    — originating recipe and path
    **Status:** ...    — current status (typically Active)
  ## Goal
  ## Context
  ## Acceptance Criteria
  ## Tasks (table: Task | Type | Title)
  ## Execution Graph (two tables: Task | Depends On; Can Be Done In Parallel)
  ## Revision History

## ## tasks block

The ## tasks heading marks the start of the task skeletons. Each ### task-NNN — Title
sub-heading defines one task. The rendered task-NNN.md file follows the 6-section
flat shape (task title heading, Type, Source, Depends on, Scope, Acceptance Criteria)
as defined in .agent/templates/delivery-plans/task-template.md.

Slots are allowed in the tasks block. The Source field of each rendered task is
set to {work-name} → delivery-001 (the lite-path delivery id is always delivery-001).

## Naming and location

File must live directly under .agent/recipes/ (not in a subdirectory). Name the
file {recipe-name}.md where recipe-name matches the name field in the front-matter.

## Conventions

- applies-to: * should be reserved for genuinely cross-type patterns that are
  useful regardless of workType (e.g., adding a unit test). A recipe offered for
  every lite work adds catalog noise if it is not truly cross-type.
- Prefer 1–2 tasks for single-concern recipes. If a recipe needs 3+ tasks, verify
  the work is still "small" in the lite-path sense.
- Slot names should be self-describing. Prefer bug-description-one-sentence over
  desc. The slot name is shown verbatim as the prompt label during slot-fill.
- Default task types: IMPLEMENT for code changes, DOCUMENT for artifacts,
  TEST for test-only tasks, REFACTOR for refactoring work.
- If the recipe body needs to discuss AID slot syntax as content (e.g., a recipe
  that documents template authoring), use {!{ to represent literal {{ throughout.
-->
