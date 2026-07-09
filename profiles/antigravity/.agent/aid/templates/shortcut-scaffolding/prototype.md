# Shortcut Scaffolding: prototype

Per-family scaffolding reference for the **`prototype`** verb (bare `aid-prototype`
plus the artifact-suffixed `aid-prototype-ui`; feature-005, work-001-lite-aid-skills).
Consulted by the shared engine
(`.agent/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field resolves to
`prototype`. Neither row carries an alias (feature-005 SPEC "Catalog rows owned" -- 2
canonical, no aliases). Free-form prose, like any other `state-*.md` reference doc --
the dispatched `aid-architect` reads this for judgment; it is not machine-parsed.

Grounded in what a prototype is for: a low-fidelity working model or wireframe that
de-risks a direction before committing to the full build --
`task-type-rules.md ## DESIGN` ("Create design artifacts ... mockups, wireframes,
flows ... Note accessibility considerations") is exactly a prototype's shape.

## `aid-prototype` -- CAPTURE

Bare verb, no artifact parameter:

| Slot | Notes |
|---|---|
| Direction / hypothesis | the specific direction being validated |
| Fidelity level | closed enum: `paper` \| `low-fi` \| `runnable spike`; default `low-fi` when the description does not name one |
| Success signal | the observable signal that would validate the direction |
| Scope boundary | what the prototype does **not** attempt (explicit -- keeps the model throwaway) |

**Escalation.** Same rule as the generic engine: escalate to the one combined CAPTURE
question only when the direction/hypothesis or the success signal cannot be made
concrete and testable from `{description}` + KB context -- for a prototype this most
often means the validation question itself is missing, not merely terse. Fidelity
level never blocks CAPTURE -- default to `low-fi`.

## `aid-prototype` -- SPEC

The mandatory three sections (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) always apply. `### Data Model` reads "no schema changes"
(a prototype is throwaway); `### Feature Flow` carries the validation narrative.
`aid-prototype` activates no conditional section on top of the mandatory three.

## `aid-prototype` -- DETAIL

| Task | Type | Notes |
|---|---|---|
| `task-001` | DESIGN | "Build the low-fidelity model of {direction} and capture the validation signal" |
| `task-002` (optional) | IMPLEMENT | throwaway runnable spike -- only when a working model is required to validate the direction; depends on `task-001` |

`task-002` is never a production build (see Ownership boundary below) -- it exists
only to make the direction's own success signal observable.

## `aid-prototype-ui` -- CAPTURE

| Slot | Notes |
|---|---|
| Target screen(s) / flow | the screen(s) or flow being wireframed |
| Key interactions + states | the interactions and states to mock (loading, empty, error, success, ...) |
| Visual reference | inspiration/reference material, if any |
| Navigation / placement context | where this screen/flow sits in the larger app |

**Escalation.** Same rule: escalate only when the target screen(s)/flow cannot be made
concrete from `{description}` + KB context.

## `aid-prototype-ui` -- SPEC

Activates `### UI Specs` on top of the mandatory three -- `### Feature Flow` carries
the interaction flow (states, transitions), `### Data Model` reads "no schema
changes" -- with an accessibility note per `task-type-rules.md ## DESIGN` ("Note
accessibility considerations").

## `aid-prototype-ui` -- DETAIL

| Task | Type | Notes |
|---|---|---|
| `task-001` | DESIGN | "Wireframe/mock {screens} + interaction flow (states, transitions, a11y notes)" |
| `task-002` (optional) | DESIGN | clickable flow prototype; depends on `task-001` |

## Ownership boundary

A prototype **validates direction; it is not the production build**. When the user's
real intent is to build the validated thing, hand off to `aid-create[-artifact]` (or
`aid-change` when the target already exists) -- prototype work never emits a
production `IMPLEMENT` task against real modules; its own optional
`IMPLEMENT`/`DESIGN` follow-up tasks stay scoped to the throwaway spike / clickable
flow only. Testing the prototype with real users (usability testing, a controlled
A/B test) is a G7 activity (`aid-experiment` / `aid-test`), not part of this
Detail-only prototype work.

## See also

- `.agent/aid/templates/shortcut-engine.md § Family Scaffolding Consult` -- how
  this file is looked up and what happens when it is absent
- `.agent/aid/templates/shortcut-scaffolding/create.md` -- where the validated
  direction's real build routes
- `.agent/aid/templates/shortcut-scaffolding/test-experiment.md § aid-experiment` --
  where testing the prototype with users routes
- `features/feature-005-prototype-family/SPEC.md` (work-001-lite-aid-skills) -- the
  settled design this reference implements
- `.agent/skills/aid-execute/references/task-type-rules.md ## DESIGN` -- the
  per-type execution rule this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task SPEC.md` -- the one-type-per-task
  contract
