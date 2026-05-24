# Recipes Catalog for Common Small-Work Patterns

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-24 | Feature created from REQUIREMENTS.md §5 FR8 (added in the same-day adaptiveness scope addition) | /aid-specify |
| 2026-05-24 | Technical Specification written — full draft (Data Model: `canonical/recipes/` directory + recipe file shape + YAML front-matter; Feature Flow: recipe-offer step in lite-path triage + slot-fill loop + emission; Layers & Components: aid-interview extension + canonical/recipes/ + work-002 generator integration; Migration Plan: additive — no breakage; Constraints) | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR8, §4 In Scope (recipes bullet), §9 FR8 ACs, §10 Priority (Should bucket), §10 pain-point coverage (pain-point 1 — second owner)

## Description

The lite path (FR1, owned by feature-005) collapses Interview → Specify → Plan →
Detail into a single condensed flow for small work — but the user still answers
interview-style questions to derive a SPEC and task breakdown. For frequently
occurring small-work patterns — a bug fix, a method refactor, adding a CRUD
endpoint, writing a release note, adding a unit test — that interview is wasted
reasoning: the structure of the work is already known. This feature adds a
**recipes catalog**: a directory of pre-filled lite-path templates the user can
instantiate by name. Each recipe ships a `SPEC.md` skeleton with `{{slot}}`
placeholders and a `tasks/task-NNN.md` skeleton list with sensible defaults; the
user fills in slots (a minute or so of typing) and the lite path emits an
execution-ready work-root `SPEC.md` + `tasks/` directly, skipping the full
lite-path interview. Recipes are open — the seed catalog ships five and projects
add their own as patterns emerge.

## User Stories

- As an AID end user repeatedly doing similar small work (e.g., fixing bugs),
  I want to instantiate from a pre-filled template by name so that I do not
  re-answer the same interview-style questions each time.
- As an AID end user, I want the lite-path triage to *offer* a matching recipe
  when one is available so that I do not have to remember the catalog names.
- As an AID end user, I want to fall back to the standard lite-path interview
  if the chosen recipe turns out to be a poor fit so that I am never stuck in
  an unsuitable template.
- As an AID methodology maintainer, I want each project to be able to add its
  own recipes for its own recurring patterns so that the catalog grows
  organically with project experience.

## Priority

Should

## Acceptance Criteria

- [ ] Given the canonical source has a `canonical/recipes/` directory with at
  least one recipe, when work-002's generator runs, then the rendered install
  trees ship a parallel `recipes/` directory; the lite-path triage discovers
  available recipes from the rendered directory at run time.
- [ ] Given the project has the rendered `recipes/` directory installed, when
  the seed catalog ships, then it contains at least five recipes:
  `bug-fix`, `method-refactor`, `add-crud-endpoint`, `write-release-note`,
  `add-unit-test`.
- [ ] Given any recipe file, when inspected, then it is a single Markdown file
  with YAML front-matter (`name`, `applies-to`, `slot-count`, `task-count`),
  a work-root `SPEC.md` skeleton body with `{{slot}}` placeholders, and a
  `tasks` block listing one or more task skeletons with type, scope, and
  acceptance-criteria defaults pre-filled.
- [ ] Given the lite-path triage has routed a work to lite (per FR1) and the
  triage's type-of-work answer matches the `applies-to` field of at least one
  recipe, when the triage step continues, then it offers the user the option
  to instantiate from a recipe (with the matching recipes listed).
- [ ] Given the user picks a recipe and answers the slot-fill prompts, when
  slot-filling completes, then the lite path emits an execution-ready
  work-root `SPEC.md` + `tasks/task-NNN.md` files within one minute of user
  time (slot-fill + render only — no free-form interview).
- [ ] Given a recipe-instantiated work proves a poor fit, when the user
  requests escalation, then the work falls back to the standard lite-path
  interview (FR1) without losing the slot values the user already supplied.

---

## Technical Specification

> This feature is a **new mechanism inside the lite path (FR1)** plus a **new
> artifact type** — recipes — owned by the canonical source. It does **not** add
> a new skill, a new agent, a new pipeline phase, or a new artifact in the
> `.aid/work-NNN/` workspace. It changes only how the lite-path triage *can*
> seed its output: by instantiating a template instead of running the free-form
> condensed interview. A recipe-instantiated work IS a lite work — same
> `.aid/work-NNN/SPEC.md` + `tasks/` shape, same hand-off to `aid-execute` — it
> just got there faster.
>
> **Coordination.** This feature has a soft dependency on **feature-005**'s
> type-aware lite-path extension (the recipe-offer step keys on the
> `applies-to` field, which derives from feature-005's `workType` signal). It
> also depends on **work-002**'s `feature-001-profile-driven-generator` to render
> the `canonical/recipes/` directory into the install trees. Neither dependency
> is hard — without the type-aware extension the recipe offer becomes
> type-agnostic ("here are all recipes"); without work-002 the catalog can be
> manually copied — but the intended-state assumes both.

### Data Model

This feature adds **one new artifact type** (`recipe`) and **one new canonical
directory** (`canonical/recipes/`). It introduces no per-work artifact change:
the lite-path output a recipe produces is the same shape feature-005 defines (one
work-root `SPEC.md` + `tasks/task-NNN.md` files, with per-task state in the work
`STATE.md ## Tasks Status` row per work-003's FR2 area-STATE rule).

#### `canonical/recipes/` — directory and file layout

```
canonical/
  recipes/
    README.md              # catalog overview; how to author a new recipe
    bug-fix.md             # seed recipe
    method-refactor.md
    add-crud-endpoint.md
    write-release-note.md
    add-unit-test.md
```

One recipe = one Markdown file directly under `canonical/recipes/`. Sub-directories
are not used in the seed catalog (a flat listing keeps the triage's filtering
simple); a future extension may introduce categories if the catalog grows past
~15 recipes.

#### Recipe file shape

A recipe is a single Markdown file with **YAML front-matter** + a **body**
containing two blocks: the work-root `SPEC.md` skeleton and the `tasks` skeleton
list. Slot syntax is Mustache-style `{{slot-name}}` — any `{{...}}` token in the
body is a slot the user must fill.

```markdown
---
name: bug-fix
applies-to: bug-fix
slot-count: 4
task-count: 1
---

## spec

# Fix: {{bug-title}}

## Description

{{bug-description-one-sentence}}

## Reproduction

{{reproduction-steps}}

## Intended Behavior

{{intended-behavior}}

## tasks

### task-001 — Apply the fix

- Type: IMPLEMENT
- Source: this recipe
- Depends on: —
- Scope: Apply the fix described above; add or update a unit test covering the
  reproduced behavior.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the bug.
  - [ ] A unit test exists that fails on the pre-fix code and passes on the
    post-fix code.
  - [ ] No regression in adjacent test suites.
```

**YAML front-matter — fixed schema (extension allowed, but these are required):**

| Field | Type | Meaning |
|---|---|---|
| `name` | string (kebab-case) | Unique recipe id. Matches the file basename. |
| `applies-to` | string | The `workType` signal value (from feature-005's type-aware triage) this recipe matches. Example values: `bug-fix`, `single-doc`, `small-refactor`, `small-new-feature`. May be `*` to match any. |
| `slot-count` | integer | Number of unique `{{slot}}` tokens in the body. Used for display ("4 slots") and as a sanity check at parse time. |
| `task-count` | integer | Number of `### task-NNN` headings in the `## tasks` block. Used for display. |

**Body — two required blocks:**

| Block | Heading | Purpose |
|---|---|---|
| SPEC skeleton | `## spec` | The work-root `SPEC.md` content the lite path will emit after slot-fill. Slot tokens (`{{slot-name}}`) anywhere in this block become user prompts. |
| Tasks skeleton | `## tasks` | Zero or more `### task-NNN — Title` sub-headings, each with a body matching the 6-section `task-template.md` shape (Type, Source, Depends on, Scope, Acceptance Criteria — Title is the heading). Slots are allowed here too. |

#### Per-work output (unchanged from feature-005's lite-path output)

After slot-fill, the lite path emits the standard lite-path workspace shape:

```
.aid/work-NNN-{name}/
  STATE.md               ← work area STATE per work-003 FR2 area-STATE rule
  SPEC.md                ← rendered from the recipe's ## spec block, slots filled
  tasks/
    task-001.md          ← rendered from the recipe's ## tasks / ### task-001, slots filled
    task-002.md          ← (etc.)
```

Per-task state lives in **work `STATE.md ## Tasks Status`** per the work-003 FR2
area-STATE rule — this is the same contract feature-005 (lite path), feature-009
(parallel execution), and feature-004 (two-tier review) all read from. A
recipe-instantiated work is indistinguishable from a free-form-interview lite
work after the triage step — both produce the same artifact shape.

#### `recipe-template.md` for authoring new recipes

`canonical/templates/recipe-template.md` is the **meta-template** project
maintainers (or the user) use to author new recipes. It is the same shape as
above, with `{{slot}}` placeholders inside the front-matter and body explaining
the conventions.

### Feature Flow

The recipe mechanism is invoked **inside `aid-interview`'s lite-path triage** —
after FR1 routes the work to lite, but before the standard condensed interview
begins.

**Pre-recipe flow (today, post-feature-005 type-aware extension):**

1. `/aid-interview` runs its triage step (2–3 questions, deterministic routing).
2. The triage emits two signals: `path = lite | full` and `workType = bug-fix |
   single-doc | small-refactor | small-new-feature`.
3. If `path = lite`, control passes to the lite-path sub-path matched by
   `workType` (feature-005's type-aware extension). The sub-path runs a
   condensed free-form interview to derive `SPEC.md` + `tasks/`.

**Post-recipe flow (with FR8):**

1. `/aid-interview` runs its triage step — unchanged.
2. The triage emits `path` and `workType` — unchanged.
3. **NEW step 3a (recipe offer).** If `path = lite`, the triage reads the
   rendered `recipes/` directory and filters: `recipe.applies-to == workType`
   OR `recipe.applies-to == "*"`. If at least one recipe matches, the triage
   asks:
   ```
   I have N recipes for this kind of work. Instantiate from one?
   [1] bug-fix — Fix: {{title}} (4 slots, 1 task)
   [2] add-unit-test — Add unit test for {{class}}.{{method}} (3 slots, 1 task)
   [3] No — use the standard lite-path interview
   ```
   If the user picks a recipe → step 4 (slot-fill). Otherwise → unchanged step
   3 (feature-005's lite-path sub-path).
4. **NEW step 4 (slot-fill).** The triage parses the recipe, extracts unique
   `{{slot-name}}` tokens, and prompts the user for each in order — one
   question per slot, with the slot name as the prompt's label. Multi-line
   answers are accepted (the slot can hold a paragraph). Empty answers are
   rejected (the user must either supply a value or escalate).
5. **NEW step 5 (emit).** The triage substitutes every `{{slot-name}}` token in
   the recipe body with the user's value, splits the body at `## spec` /
   `## tasks`, and writes:
   - `.aid/work-NNN/SPEC.md` ← rendered `## spec` block content
   - `.aid/work-NNN/tasks/task-001.md` (and `task-002.md`, …) ← rendered
     `## tasks / ### task-NNN` blocks, one per `### task-NNN` heading
   - `.aid/work-NNN/STATE.md` ← initialised with `## Tasks Status` table
     populated from the task list (one row per task, Status = `Pending`)
6. **Hand-off (unchanged).** Print the same hand-off message feature-005's
   lite-path State L4 prints: `/aid-execute task-001 work-NNN`.

**Escalation (recipe-instantiated work proves a poor fit).** If, during slot-fill
or after emission, the user determines the recipe is wrong for the work, they
escalate via the same mechanism FR1 already provides (lite → full) — but to the
standard lite-path interview, not all the way to the full path:

1. The user types `/aid-interview escalate-from-recipe` (or selects an
   "escalate" option mid-slot-fill).
2. The slot values already supplied are preserved in `INTERVIEW-STATE.md`'s
   `§ Triage` block (or its area-STATE equivalent) as the seed answers for the
   standard lite-path interview's first questions — the user does not lose
   the slot answers.
3. The standard lite-path interview (feature-005) takes over from there.

The escalation path from recipe → standard lite → full path (via FR1) chains
naturally: a recipe-instantiated work can escalate twice if needed.

### Layers & Components

FR8 touches **one skill — `aid-interview` — and adds one new canonical directory
+ one meta-template.** No new agent. No new per-work artifact.

| Layer | Component | Change |
|---|---|---|
| Orchestration | `canonical/skills/aid-interview` SKILL.md — triage step | **Extended.** A new sub-step (recipe-offer + slot-fill + emit) is inserted between feature-005's type-aware lite-path routing and the standard lite-path sub-path. When the user declines a recipe, control passes through to feature-005's existing sub-path unchanged. |
| Canonical source | `canonical/recipes/` (NEW directory) | **New artifact type.** Seed catalog of 5 recipes ships in the canonical source. work-002's generator renders this directory into each profile's install tree. |
| Template authorship | `canonical/templates/recipe-template.md` (NEW file) | **New meta-template.** Project maintainers (or users) copy this template when authoring a new recipe. Documents the YAML schema, slot syntax, and section structure. |
| Build / generator | `work-002`'s `feature-001-profile-driven-generator` | **Soft dependency.** The generator's profile renderer must include `recipes/` in the rendered output. If the generator is unaware of `recipes/` it will still copy it (recipes are plain Markdown — no special rendering needed), but treating it as a known directory makes the contract explicit. Flag for work-002's spec if it isn't already covered by its "any new canonical directory is rendered" rule. |
| Lite-path execution | `feature-005-lite-path` | **Coordination point.** Feature-005's triage emits the `workType` signal FR8's recipe-offer step consumes. Feature-005 owns the type-aware sub-paths; FR8 layers on top. The two features integrate but do not overlap in code surface. |
| Per-task state | work `STATE.md ## Tasks Status` (per work-003 FR2 area-STATE rule) | **Unchanged.** Recipe-instantiated tasks live in the same table as free-form-interview tasks. The contract is identical. |

**Recipe-parser implementation.** The recipe parser is shell-based (one short
script in `canonical/skills/aid-interview/scripts/parse-recipe.sh`) that:

1. Splits the YAML front-matter from the body via `awk '/^---$/{c++; next} c==1'`.
2. Validates required YAML fields (`name`, `applies-to`, `slot-count`,
   `task-count`).
3. Extracts unique `{{slot-name}}` tokens from the body via `grep -oP '\{\{[a-z0-9_-]+\}\}' | sort -u`.
4. Compares the extracted slot count to the front-matter `slot-count` field
   (mismatch → warn the user; instantiation continues).
5. Splits the body on `## spec` and `## tasks` headings; returns each block to
   the orchestrator for slot substitution.

The orchestrator (the skill body) does the user-facing slot-fill loop, the slot
substitution (`sed`-based or in-orchestrator string replace), and the file
emission. The script is mechanical helper, not the substantive logic.

### Migration Plan

This feature is **additive** — no existing AID workspace, no existing recipe (none
exist pre-FR8), and no existing skill behavior breaks. The lite-path triage gains
one new sub-step that the user can decline (returning to the existing lite-path
flow). No backward-compatibility migration is required.

**Rollout sequence:**

1. **Canonical source first.** Author the 5 seed recipes in `canonical/recipes/`
   alongside `canonical/templates/recipe-template.md`. Author `aid-interview`'s
   triage extension in the canonical SKILL.md.
2. **Generator rendering.** Confirm work-002's generator renders the
   `canonical/recipes/` directory into the three install trees (Claude Code,
   Codex, Cursor). If not, file a small change against work-002's feature-001
   (one line in the generator's "directories to render" list).
3. **Smoke test.** Run `/aid-interview` against a sample small work; verify the
   recipe-offer step appears for matching `workType` values and the standard
   sub-path appears for non-matching ones; verify slot-fill produces a valid
   work-root `SPEC.md` + `tasks/`; verify `/aid-execute task-001` runs against
   the emitted output.
4. **Catalog hygiene.** Add a `canonical/recipes/README.md` documenting the
   catalog conventions, the slot syntax, the YAML schema, and how a project
   maintainer adds a new recipe. The README is itself a stable artifact —
   updated when the catalog conventions change, not per recipe.

### Constraints & Boundaries

- **Recipe is a fast path *inside* the lite path, not a third path.** A
  recipe-instantiated work is a lite work. The same FR1 escalation pattern
  (lite → full) applies; FR2 (two-tier review) treats the recipe's single
  delivery as one delivery for the per-delivery gate; FR6 (parallel pool) runs
  the recipe's tasks under the same `MaxConcurrent` cap as any other lite work;
  per-task state lives in the same work `STATE.md ## Tasks Status` row.
- **Slot-fill is not validation.** Slots are free-form text; the recipe author
  chooses how strict to be in slot names and bullet structure. There is no
  type checking, regex validation, or schema enforcement beyond "the slot was
  filled with something non-empty." Recipe quality is the recipe author's
  responsibility.
- **The catalog is open.** Five recipes is the *seed*; projects are expected to
  add their own as patterns emerge. A project's local recipes can live in
  `canonical/recipes/` (if maintained alongside the canonical source) or in a
  project-specific overlay (out of scope for this feature; flagged for future
  enhancement if user demand surfaces).
- **No recipe versioning.** A recipe is a single file at a path; updating it
  updates everyone's behavior. If a recipe needs to evolve in a
  breaking-changes way, the convention is to author a new recipe with a new
  `name` (e.g., `bug-fix-v2`) and let the old one age out of the catalog.
- **`applies-to == "*"` is for general-purpose recipes only.** A recipe with
  `applies-to: *` is offered for every lite work, regardless of `workType`. To
  prevent catalog noise this should be reserved for genuinely cross-type
  templates (e.g., a `chore` recipe for misc small work). The seed catalog
  ships zero `*`-applies recipes.
- **Methodology preserved (§7).** FR8 changes *what the lite-path triage can
  offer*, not *what the methodology does*. Phases, artifacts, gates, the
  reviewer ≠ executor invariant, deterministic grading, and the
  branch-per-delivery rule are all intact.
- **Scope boundary.** FR8 does **not** add an authoring tool for recipes
  (recipes are authored as Markdown files by hand), does **not** add recipe
  validation beyond YAML field presence, does **not** add a project-overlay
  mechanism for project-local recipes, does **not** add an analytics signal
  for "which recipes are most used" (that would be FR7 territory — dropped),
  and does **not** touch deploy / monitor. It is one skill extension + one new
  directory + one meta-template.
