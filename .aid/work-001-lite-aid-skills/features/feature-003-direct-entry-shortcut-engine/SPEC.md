# Direct-Entry Shortcut Engine

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.2 (FR-1..FR-5), §5.5 (FR-6, FR-7), D-2, D-3, A-2 | /aid-define |
| 2026-07-08 | STRUCTURE/NAMING amendment cascade: the engine now authors `BLUEPRINT.md` (delivery definition incl. GATE CRITERIA) and `DETAIL.md` task files (no per-task `STATE.md`) and promotes `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` into the work `STATE.md`; catalog + 69-doorway topology unchanged (FR-15/FR-17, feature-001) | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.2 (Common behavior — FR-1, FR-2, FR-3, FR-4, FR-5)
- REQUIREMENTS.md §5.5 (FR-6, FR-7)
- REQUIREMENTS.md D-2, D-3, A-2

## Description

Provide the shared direct-entry mechanism every shortcut skill runs on. When a user invokes a
shortcut by name (with an optional artifact type and description), the engine skips the
`aid-describe` interview and triage, creates the `.aid/work-NNN-<name>/` work folder and its
`STATE.md` scaffold, and authors the collapsed lifecycle documents — `REQUIREMENTS.md`,
`SPEC.md`, `PLAN.md` — plus the executable `tasks/task-NNN/` set. Because the work-type is
already known (verb + artifact), the engine captures only the minimum information needed to fill
each document rather than running multi-feature decomposition, per-phase interviews, or
multi-delivery planning. It produces the **full** artifact set — it does not skip
Describe/Define/Specify/Plan/Detail, it collapses them — so the only difference from the full
path is the lighter information capture, cutting red tape while keeping structured, traceable
outputs. It generalizes the precedent `aid-describe` TRIAGE slot-fill mechanism.

**Open decision A-2 (deferred to /aid-specify — do NOT resolve here):** this engine carries the
implementation-topology question — whether the 45 named forms are 45 separate `SKILL.md`
directories, or a smaller set of verb skills that take the artifact as a parameter with the
`-{artifact}` forms as thin alias/entry points. Requirements fix only the user-facing naming and
behavior; the file topology (which materially affects maintenance scale) is settled later.

## User Stories

- As an AID adopter who already knows their change-type, I want to invoke a shortcut skill
  directly by name and receive a scaffolded, authored Lite work so I can skip the `aid-describe`
  interview and triage.
- As an AID maintainer, I want one shared direct-entry engine backing all shortcuts so ~45
  skills reuse the same scaffolding and authoring machinery instead of 45 bespoke
  implementations.

## Priority

Must

## Acceptance Criteria

- [ ] Given a shortcut invoked with an optional artifact + description, when the engine runs,
  then it creates the work without running the `aid-describe` interview/triage. (AC-2 —
  invocation half; FR-1)
- [ ] Given a shortcut invocation, when the engine scaffolds the work, then it creates the
  `.aid/work-NNN-<name>/` folder and a `STATE.md` scaffold. (FR-2)
- [ ] Given a shortcut run, when it authors the work, then it produces the full artifact set —
  `REQUIREMENTS.md`, `SPEC.md` (single feature), `PLAN.md` (single delivery), and one
  `tasks/task-NNN/` folder per task — with no skipped phases; the only difference from the full
  path is reduced information capture. (FR-3, FR-4, FR-6, FR-7)
- [ ] Given a shortcut invoked with an artifact type, when the engine runs, then it accepts the
  artifact type as a parameter and draws on the skill-internal scaffolding knowledge for that
  verb x artifact (there is no separate recipe/scaffolding catalog) to adapt the information
  capture and spec/task shape accordingly. (FR-5; AC-4 — scaffolding-drives-shape mechanism)
- [ ] Given the shortcut catalog, when the engine resolves an invocation, then all 45 canonical
  skills exist in `canonical/skills/` with a valid `SKILL.md` state machine and the `aid-`
  prefix, and the 24 aliases (`aid-add-*`, `aid-update-*`) resolve correctly. (AC-1 — anchor;
  verified cumulatively as each skill family lands)
- [ ] Given a new or changed skill, when `aid-reviewer` reviews it, then it scores >= the
  resolved `minimum_grade` (A+) before shipping. (AC-7 — anchor; re-verified by every
  skill-authoring feature)
- [ ] Given any change under `canonical/`, when `run_generator.py` renders, then every skill
  (the shortcuts + `aid-triage` + the refactored `aid-describe`) renders to all five profiles,
  the VERIFY + `render-drift` CI is green, and the dogfood `.claude/` is byte-identical.
  (AC-6 — anchor; re-verified by every canonical-touching feature)
- [ ] Given a representative change, when a user invokes the matching shortcut, then it reaches
  the approved task set in materially fewer prompts/turns than the full `/aid-describe` interview,
  and the user can derive the correct skill name from {verb}+{artifact} without consulting docs.
  (AC-12 — NFR-5 speed & discoverability)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-A2` (the master topology decision) and the
> settled contract for this wave. This feature is the **keystone**: it writes feature-001's
> flattened structure and runs feature-004's gates. Cross-references to those two features
> are marked at the seams.

### Topology (settled A-2): 69 doorways (67 thin) over one shared engine

The generator makes the invocation name **equal to the skill directory name** and provides
**no alias facility**. In `render.py` the skills branch sets `skill_slug = skill_dir.name`,
loops one-to-one over `skill_dirs`, and carries the frontmatter `name:` through untouched
(`render.py` grep `skill_slug = skill_dir.name`; contrast `_translate_agent` which *does*
mint the output name from frontmatter). A repo-wide search finds no command-alias mechanism
(`research/spec-grounding.md § Q-A2` fact 3). Therefore **every distinct name a user can type
MUST be its own `canonical/skills/<name>/` directory** — the 45 canonical + 24 alias forms
require **69 `SKILL.md` directories** for AC-1 to hold under the current generator.

To satisfy NFR-8 (do not multiply maintenance cost) **67 of the 69** `SKILL.md` files are
**thin doorways**: minimal frontmatter plus a pointer that binds one `{verb, artifact}` and
delegates to a **single shared engine**. (The 2 `repurpose: true` rows — `aid-deploy` /
`aid-monitor` — are pre-existing **fat** pipeline skills feature-012 edits, NOT thin doorways;
see the Layers table + the `repurpose` field contract.) The engine logic is authored ONCE. This is
feasible today because the `canonical/aid/` subtree is copied verbatim per profile (`render.py`
`copy_tree` with `translate="none"`) and skills reference shared assets by install-path-
rewritten path (`render_lib.py` `rewrite_install_paths`: `canonical/aid/templates/...` ->
`<install_root>/aid/templates/...`). "Single brain, 67 thin doorways + 2 re-purposed."

### Data Model / Schemas

**1. The shortcut catalog — `canonical/aid/templates/shortcut-catalog.yml` (single source).**
One row per invocation name (69 total: 45 canonical + 24 alias). It renders verbatim to
`<root>/aid/templates/shortcut-catalog.yml` in all five profiles (a `.yml` is copied as bytes;
`.yml` is not in `render.py` `_TEXT_EXTENSIONS`, matching the shipped `templates/settings.yml`
precedent). It has two consumers: the maintainer build helper (below) and `/aid-triage`
(feature-014) at runtime.

```yaml
# canonical/aid/templates/shortcut-catalog.yml
version: 1
shortcuts:
  - name: aid-create-api      # == skill directory == /command (render.py: name == dir)
    group: G4                 # activity group (REQUIREMENTS.md 5.1)
    verb: create              # the verb the engine dispatches on
    artifact: api             # artifact suffix ("" for bare verbs: fix, refactor, ...)
    alias_of: null            # null = canonical form
    default_type: IMPLEMENT   # default task Type (closed 8-enum; see A-6 mapping)
    intent: "Create an API endpoint / middleware (contract, handler, validation)."
  - name: aid-add-api
    group: G4
    verb: create              # add == create (alias family)
    artifact: api
    alias_of: aid-create-api  # thin alias; identical engine binding
    default_type: IMPLEMENT
    intent: "Alias of aid-create-api."
```

Field contract: `name` (required, `aid-` prefixed, equals the directory), `verb`, `artifact`
(may be `""`), `alias_of` (`null` for canonical; the mirrored canonical name for aliases —
`aid-add-*` -> `aid-create-*`, `aid-update-*` -> `aid-change-*`), `default_type` (one of the
byte-stable 8: `RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR |
CONFIGURE`, per `artifact-schemas.md § Contracts`), `group`, `intent`, `repurpose` (optional,
default `false`; `true` only for the 2 pre-existing **fat** pipeline skills `aid-deploy` /
`aid-monitor` that feature-012 re-purposes — the build helper does **not** generate or overwrite
`repurpose: true` rows; the catalog merely registers them so the parity check and `/aid-triage`
recognise them).

**2. Thin SKILL.md shape.** Minimal frontmatter (`name` == dir — **the invocation/command name is
the directory name** (`render.py` `skill_slug = skill_dir.name`), NOT derived from any frontmatter
field; `description` — a one-line summary that per AID convention also carries the skill's
`State machine:` line; `allowed-tools`; `argument-hint`) plus a short body that binds
`{verb, artifact}` and delegates. Example (`aid-create-api`):

```markdown
---
name: aid-create-api
description: >
  Direct-entry Lite-path shortcut: create an API endpoint / middleware without the
  aid-describe interview or triage. Binds VERB=create ARTIFACT=api and runs the shared
  shortcut engine, producing a fully-graded flattened Lite work that halts for approval.
  State machine: delegated to canonical/aid/templates/shortcut-engine.md
  (INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT).
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[description]  -- what to build; runs straight to a graded flattened Lite work"
---

# Shortcut: create api

Bind **VERB=`create`**, **ARTIFACT=`api`**, then run the shared engine at
`canonical/aid/templates/shortcut-engine.md`. The engine scaffolds the flattened Lite work
(feature-001 structure), authors REQUIREMENTS -> SPEC -> PLAN + BLUEPRINT -> DETAIL tasks with
reduced capture, runs the per-document Grading Gates (feature-004), and halts at the FR-10
approval gate. It never executes. This shortcut's `default_type`/`group`/`alias_of` are its row
in `canonical/aid/templates/shortcut-catalog.yml`.
```

Bare verbs (`aid-fix`, `aid-refactor`, `aid-experiment`, `aid-report`, ...) bind `ARTIFACT=""`.
Aliases carry the same `{verb, artifact}` binding as their canonical mirror (`add`==`create`,
`update`==`change`); they are separate directories, not a runtime alias.

**3. Engine state list + scaffolding references.** The engine
(`canonical/aid/templates/shortcut-engine.md`) owns the state machine (below) and the
capture-minimization rules, and at SPEC/DETAIL it **consults a per-family scaffolding reference**
at `canonical/aid/templates/shortcut-scaffolding/<family>.md` (keyed by `{verb, artifact}`) for the
per-verb x artifact **scaffolding guidance** (which SPEC sections to activate, which task set to
emit) — this is the per-work-type knowledge FR-14 migrates *into the skills* (as these sibling
references authored by family features 005–011, NOT a renamed recipe catalog), and the machine-readable defaults
(`default_type`, group) come from the catalog row. The default-type mapping is code-settled
(A-6: no enum change — extending the 8-type enum is a lockstep break across `grade.sh`, both
dashboard reader twins, and every grading skill per `artifact-schemas.md § Contracts`):

| Verb (representative) | Default task Type | Note |
|---|---|---|
| prototype | DESIGN | low-fidelity model / wireframe (`task-type-rules.md ## DESIGN`) |
| create / change (code, api, ui, cli, messaging, integration, infra) | IMPLEMENT | |
| create-data-model / change-data-model | MIGRATE (+ IMPLEMENT) | entity/schema + migration |
| create-config / change-config | CONFIGURE | feature-flag / rule |
| fix | IMPLEMENT | |
| refactor | REFACTOR | |
| test / test-* | TEST | |
| experiment | RESEARCH | hypothesis -> analyze -> recommend |
| document / document-* | DOCUMENT | |
| report | RESEARCH | EDA / analysis producing a document |
| show-dashboard | IMPLEMENT | a BI view is code/config |

Multi-task shortcuts (e.g. create-data-model -> MIGRATE + IMPLEMENT + TEST) emit several tasks,
each with one Type (never mixed — `artifact-schemas.md § Task SPEC.md`).

### Feature Flow (engine state machine)

The engine traverses the **definition phases only — Describe -> Define -> Specify -> Plan ->
Detail (NOT Execute)** — collapsing them into a single fast run, then halts at FR-10. States:

| State | Collapses | Does |
|---|---|---|
| **INTAKE** | (entry) | Parse `{verb, artifact, description}`; look up the catalog row for `default_type`/group; allocate `work-NNN`; scaffold `.aid/work-NNN-<slug>/STATE.md` from the verb-first `work-state-template.md` (Pipeline State only — no Triage/Recipe blocks; feature-002 removes those orphans). FR-2. |
| **CAPTURE** | Describe | Because the work-type is known (verb+artifact), capture only the minimum slots — NO multi-turn elicitation, NO triage — and author work-root `REQUIREMENTS.md` (all 10 numbered sections, terse but complete; pending -> `*(pending)*`). FR-1, FR-3, FR-7. |
| **SPEC** | Define + Specify | Author the single work-root `SPEC.md` (feature-001 shape: requirements-half + `## Technical Specification`), activating the SPEC sections the engine's per-verb guidance selects for this `verb x artifact`. NO feature decomposition, NO cross-reference (single feature). FR-3, FR-5, AC-4. |
| **PLAN** | Plan | Author the single work-root `PLAN.md` (one delivery; Deliverables + `## Execution Graph`) **and** the single work-root `BLUEPRINT.md` (delivery definition: objective, scope, **GATE CRITERIA**, task listing, deps). NO multi-delivery planning. FR-3. |
| **DETAIL** | Detail | Emit `tasks/task-NNN/DETAIL.md` (bold `**Type:**` shape, `**Source:** work-NNN-<name> -> delivery-001`; **no** per-task `STATE.md`), the `## Execution Graph` `\| Task \| Depends On \|` table in `PLAN.md`, and the promoted `### Tasks lifecycle` cells in the work `STATE.md`. FR-4, FR-17. |
| **GATE** | — | Run feature-004's two batched Grading Gate passes (REQUIREMENTS+SPEC+PLAN+BLUEPRINT; then task DETAILs) until each clears `minimum_grade`. FR-11. |
| **APPROVAL-HALT** | — | Present the flattened work; STOP. Never executes (human-gated, NFR-10). Execution is a separate user-initiated `/aid-execute`. FR-10. |

**Agent dispatch (C-2).** Authoring states (CAPTURE/SPEC/PLAN/DETAIL) dispatch `aid-architect`
(Large tier — design work, mirroring how `aid-describe` lite L2 TASK-BREAKDOWN uses
`aid-architect`); GATE dispatches `aid-reviewer` (Large). Reviewer tier >= executor tier and
the writer never grades its own work (`architecture.md § Agent / Sub-Agent Dispatch Model`).

**NFR-5 (the whole point).** The verb-first names make the skill guessable from `{verb}+{artifact}`
first-try, and the collapse removes the multi-turn interview/triage — reaching the approved task
set in materially fewer turns than full `/aid-describe` (AC-12). The engine keeps CAPTURE to a
bounded minimal-slot fill, escalating to a question only when a load-bearing slot is genuinely
unknown.

**Precedent generalized (D-2).** This is the `aid-describe` TRIAGE slot-fill mechanism
generalized: TRIAGE inferred `workType` then fanned out to 51 recipes via a runtime parameter
(`state-triage.md` grep `Find best-matching recipe`; `parse-recipe.sh`). The engine replaces
the recipe lookup with the bound `{verb, artifact}` and the engine's own scaffolding guidance
(FR-14: knowledge moves into the skills, not a renamed catalog).

### Layers & Components (canonical files + render)

| File | Change | Renders to |
|---|---|---|
| `canonical/skills/aid-<name>/SKILL.md` (69 dirs) | 67 **new** thin doorways generated from the catalog (43 canonical + 24 alias); the 2 `repurpose: true` rows (`aid-deploy`/`aid-monitor`) are pre-existing fat skills feature-012 edits — NOT generated | `<root>/skills/aid-<name>/SKILL.md`, all 5 profiles |
| `canonical/aid/templates/shortcut-engine.md` | **new** — the single shared engine (state machine + capture rules; consults the per-family scaffolding references) | `<root>/aid/templates/shortcut-engine.md` (verbatim; 5 profiles) |
| `canonical/aid/templates/shortcut-scaffolding/<family>.md` | **new** — per-family scaffolding references (SPEC-section activation + task templates keyed by `{verb, artifact}`); each authored by its family feature 005–011 | `<root>/aid/templates/shortcut-scaffolding/*.md` (verbatim; 5 profiles) |
| `canonical/aid/templates/shortcut-catalog.yml` | **new** — the 69-row single-source manifest | `<root>/aid/templates/shortcut-catalog.yml` (verbatim bytes; 5 profiles) |
| `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` | **new** — maintainer build helper: reads the catalog, emits/refreshes the thin-doorway `canonical/skills/aid-*/` dirs; **skips `repurpose: true` rows** (aid-deploy/aid-monitor are hand-authored, not regenerated) | not shipped (maintainer-only, like `run_generator.py`) |
| reused templates | `requirements/requirements-template.md`, `specs/spec-template.md`, the task-DETAIL template + delivery-BLUEPRINT template (renamed from `task-spec-template.md` / `delivery-spec-template.md` by **feature-015**), `work-state-template.md` (carrying feature-001's promoted `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` blocks) | the artifacts the engine fills; the flat path uses **no** per-task `task-state-template.md` (task cells live in the work `STATE.md § ### Tasks lifecycle`) |

The 69 dirs are **generated canonical source** (committed, but produced from the catalog — the
`INDEX.md`/`build-kb-index.sh` model). After any catalog edit the maintainer runs
`build-shortcut-skills.py` then the FULL `run_generator.py` (never a partial render — see
`architecture.md § Gotchas`), so the VERIFY byte-compare + `render-drift` CI stay green and the
dogfood `.claude/` is byte-identical (NFR-1, AC-6).

*Placement note (flag):* the build helper is maintainer tooling that writes canonical source, so
it must NOT live under `canonical/` (would ship). It is placed beside the maintainer generator
(`.claude/skills/generate-profile/scripts/`, the documented maintainer-only home per
`architecture.md`). Confirm this home vs. a top-level maintainer `scripts/` dir.

### Testing strategy

- **Catalog<->dirs parity** (new canonical test, the render-drift analog for the generated dirs):
  every `shortcut-catalog.yml` row maps to exactly one `canonical/skills/<name>/SKILL.md` whose
  frontmatter `name` == dir == row `name` and carries the `aid-` prefix; count == 69 (45 canonical
  + 24 alias); no orphan dir, no orphan row. For thin-doorway rows the body must bind the row's
  `{verb, artifact}` and delegate to the engine; for the 2 **`repurpose: true`** rows
  (`aid-deploy`/`aid-monitor`) the test asserts only dir-exists + name-match — they are pre-existing
  fat skills (feature-012 owns their bodies), not thin doorways. This is AC-1's mechanical proof.
- **Render determinism**: the 69 dirs flow through `render.py`'s existing skills path; the
  `--self-test` T3 (skills determinism) and CI `render-drift` cover byte-stability (AC-6).
- **Engine smoke** (fixture): a representative `verb x artifact` (e.g. `aid-create-api`) run
  produces the full flattened artifact set (feature-001 shapes: `REQUIREMENTS.md` + `SPEC.md` +
  `PLAN.md` + `BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md`, with the promoted `STATE.md` blocks and
  no per-task `STATE.md`) and halts pre-Execute — proving FR-3/FR-4/FR-6/FR-10/FR-17 without
  executing.

Seams: the engine **writes feature-001's** flattened folder + STATE blocks and **runs
feature-004's** gate/approval flow; those two features own those contracts and this engine
consumes them.
