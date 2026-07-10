# Prototype Skill Family (G3)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G3) | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G3 — Prototype)

## Description

The G3 shortcut skills for building a low-fidelity working model to validate direction before a
full build: `aid-prototype` (bare) and `aid-prototype-ui` (wireframe/mock a UI plus its
interaction flow to validate UX direction). Each is invoked directly, enters the Lite path via
the shared direct-entry engine, and produces a flattened Lite work.

## User Stories

- As an AID adopter who wants to validate a direction before committing, I want to invoke
  `aid-prototype` (or `aid-prototype-ui`) directly so I get a scaffolded Lite work for a
  low-fidelity model without the full interview.

## Priority

Should

## Acceptance Criteria

- [ ] Given the G3 skills, when the catalog is checked, then `aid-prototype` and
  `aid-prototype-ui` exist in `canonical/skills/` with valid `SKILL.md` state machines and the
  `aid-` prefix. (AC-1 — G3 subset)
- [ ] Given each G3 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G3 subset)

---

## Technical Specification

> This family is **family-specific content on top of the settled shortcut engine
> (feature-003)** — it contributes catalog rows + scaffolding knowledge, not a re-spec of the
> engine. Every G3 skill is a thin doorway that binds `{verb, artifact}` and delegates to
> `canonical/aid/templates/shortcut-engine.md`, which writes feature-001's flattened work and
> runs feature-004's gates. Read those three specs for the engine, on-disk shape, and gate flow;
> they are not repeated here.

### Catalog rows owned (AC-1 — G3 subset)

Two canonical skills, no aliases ⇒ **2 `canonical/skills/aid-*/SKILL.md` directories**. Each is a
row in feature-003's single-source `canonical/aid/templates/shortcut-catalog.yml`:

| `name` (== dir == command) | verb | artifact | alias_of | group |
|---|---|---|---|---|
| `aid-prototype` | prototype | `""` (bare) | null | G3 |
| `aid-prototype-ui` | prototype | `ui` | null | G3 |

### Per-skill binding & default-type (feature-003 A-6 mapping)

Per feature-003's code-settled default-type table (**prototype → DESIGN**; the 8-type enum is
**not** extended — that is a lockstep break per `artifact-schemas.md § Contracts`):

| Skill | `default_type` | Task shape |
|---|---|---|
| `aid-prototype` | `DESIGN` | primary DESIGN (low-fidelity model); optional `IMPLEMENT` task only when a *throwaway runnable spike* is needed to validate direction |
| `aid-prototype-ui` | `DESIGN` | primary DESIGN (wireframe/mock + interaction flow); optional second DESIGN task for a clickable flow prototype |

DESIGN is the right fit — `task-type-rules.md ## DESIGN` is defined as "Create design artifacts …
mockups, wireframes, flows … Note accessibility considerations," which is exactly a prototype's
output. Authoring is dispatched to `aid-architect` (Large), the design specialist, matching
feature-003's authoring-state dispatch.

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/prototype.md`)

The per-`verb×artifact` scaffolding knowledge feature-003's engine consults (capture slots, which
SPEC sections to activate, the task-breakdown template) is authored **once** as a family reference
under `canonical/aid/`, keyed by `{verb, artifact}`. This is the concrete home for the
"per-work-type knowledge migrates into the skills" contract (FR-14 / A-2 "whether the skills share
a lightweight internal reference is a `/aid-specify` implementation detail"); co-locating it per
family keeps the byte-review surface modular (NFR-8) and lets the engine stay generic. Activity
shapes are grounded in `research/digital-project-activities.md § 4` (Design Thinking Prototype;
Double Diamond Develop).

**CAPTURE slots (minimum only — the engine infers stack/conventions from the KB, so it asks only
the load-bearing unknowns):**

| Skill | Capture slots |
|---|---|
| `aid-prototype` | direction/hypothesis to validate; fidelity level (paper / low-fi / runnable spike); the success signal that would validate the direction; explicit scope boundary (what the prototype does **not** attempt) |
| `aid-prototype-ui` | target screen(s)/flow; key interactions + states to mock; visual reference/inspiration; navigation/placement context |

**SPEC-section activation** (feature-001's single `SPEC.md` reuses `specs/spec-template.md`; the
engine activates only the conditional sections listed below and marks Data Model "no schema
changes" — a prototype is throwaway):

- `aid-prototype`: base `Feature Flow` (the validation narrative) only.
- `aid-prototype-ui`: `### UI Specs` + `Feature Flow` (interaction flow), with an accessibility
  note per `task-type-rules.md ## DESIGN`.

**Task-breakdown template:**

- `aid-prototype` → `task-001` DESIGN "Build the low-fidelity model of {direction} and capture the
  validation signal"; (conditional) `task-002` IMPLEMENT "Throwaway runnable spike" only if a
  working model is required. Execution graph: `task-002` depends on `task-001`.
- `aid-prototype-ui` → `task-001` DESIGN "Wireframe/mock {screens} + interaction flow (states,
  transitions, a11y notes)"; (conditional) `task-002` DESIGN "Clickable flow prototype."

### Ownership boundary

A prototype **validates direction; it is not the production build**. When the user's real intent is
to build the validated thing, the scaffolding hands off to `aid-create[-artifact]` (or
`aid-change`) — the prototype work does not emit production `IMPLEMENT` tasks against real modules.
Testing the prototype with users is a G7 activity (`aid-experiment` / `aid-test`), not part of the
Detail-only prototype work.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 2 rows** (`aid-prototype`, `aid-prototype-ui`) |
| `canonical/aid/templates/shortcut-scaffolding/prototype.md` | **new** — the family scaffolding reference (slots + SPEC activation + task templates above) |
| `canonical/skills/aid-prototype/SKILL.md`, `canonical/skills/aid-prototype-ui/SKILL.md` | **generated** by feature-003's `build-shortcut-skills.py` from the catalog — **not hand-written** thin doorways |

No family-specific engine branch is required — prototype rides the generic engine; only the
catalog rows and the scaffolding reference are new. Renders via the full `run_generator.py` to all
five profiles (verbatim `canonical/aid/` copy + generated skill dirs; NFR-1, AC-6).

### Testing strategy

- **Family scaffold proof** (canonical fixture): invoking `aid-prototype-ui` on a representative
  description produces a flattened Lite work — `REQUIREMENTS.md` + `SPEC.md` (with `### UI Specs`
  activated, Data Model "no schema changes") + `PLAN.md` + `tasks/task-001/` typed `DESIGN` — and
  halts pre-Execute (FR-10). Proves the binding drives the correct DESIGN-typed shape.
- **Catalog↔dirs parity**: the 2 rows/dirs are covered by feature-003's parity test (AC-1);
  render byte-stability by CI `render-drift` (AC-6).
