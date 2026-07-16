# Shortcut Scaffolding: prototype

Scaffolding reference for the **`prototype`** family (bare `aid-prototype` plus the
`ui` kind-sibling `aid-prototype-ui`; work-005 reframe of feature-005). `prototype` is now
a hand-authored collapse skill, **no longer consulted by the shared engine** -- instead the
hand-authored `aid-prototype` body reads this file for the per-slot capture / detail
guidance below. Neither row carries an alias (feature-005 SPEC "Catalog rows owned" -- 2
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

**Escalation.** Same minimal-escalation discipline the engine's Capture-Minimization
Rules define (the hand-authored collapse body applies it -- the engine no longer runs
this family): escalate to the one combined CAPTURE question only when the
direction/hypothesis or the success signal cannot be made concrete and testable from
`{description}` + KB context -- for a prototype this most
often means the validation question itself is missing, not merely terse. Fidelity
level never blocks CAPTURE -- default to `low-fi`.

## `aid-prototype` -- structure (no SPEC.md)

The collapse produces the throwaway model directly and emits no `SPEC.md`. A prototype is
throwaway (no schema change); the **validation narrative** it needs lives in the model + the
validation assessment (BUILD / PRESENT in `aid-prototype/SKILL.md`), not a
`## Technical Specification` section.

## `aid-prototype` -- what the collapse builds

The `aid-prototype` collapse body builds, in its BUILD state (it emits no tasks):

- the **low-fidelity model** of `{direction}` and captures the validation signal (DESIGN work); and
- **optionally, a throwaway runnable spike** -- only when a working model is required to make the
  success signal observable.

The runnable spike is **never a production build** (see Ownership boundary below); it exists
only to observe the direction's own success signal.

## `aid-prototype-ui` -- CAPTURE

| Slot | Notes |
|---|---|
| Target screen(s) / flow | the screen(s) or flow being wireframed |
| Key interactions + states | the interactions and states to mock (loading, empty, error, success, ...) |
| Visual reference | inspiration/reference material, if any |
| Navigation / placement context | where this screen/flow sits in the larger app |

**Escalation.** Same rule: escalate only when the target screen(s)/flow cannot be made
concrete from `{description}` + KB context.

## `aid-prototype-ui` -- structure (no SPEC.md)

A ui prototype likewise emits no `SPEC.md`: the **interaction flow** (states, transitions)
and **accessibility notes** (`task-type-rules.md ## DESIGN`) are part of the wireframe/mock
the collapse produces (no schema change), not a `### UI Specs` SPEC section.

## `aid-prototype-ui` -- what the collapse builds

For a ui prototype the collapse builds a **wireframe/mock of `{screens}` + interaction flow**
(states, transitions, a11y notes), and **optionally a clickable flow prototype** -- all
throwaway, all DESIGN work.

## Ownership boundary

A prototype **validates direction; it is not the production build**. When the user's
real intent is to build the validated thing, hand off to `aid-create[-artifact]` (or
`aid-change` when the target already exists) -- prototype work never touches production
modules; its optional runnable spike / clickable flow stays throwaway. Testing the
prototype with real users (usability testing, a controlled A/B test) is a G7 activity
(`aid-experiment` / `aid-test`), not part of this throwaway prototype work.

## See also

- `canonical/skills/aid-prototype/SKILL.md` -- the hand-authored collapse body that
  reads this file for per-slot capture/detail guidance (work-005; `prototype` is no
  longer engine-consulted)
- `canonical/aid/templates/shortcut-scaffolding/create.md` -- where the validated
  direction's real build routes
- `canonical/aid/templates/shortcut-scaffolding/test-experiment.md § aid-experiment` --
  where testing the prototype with users routes
- `features/feature-005-prototype-family/SPEC.md` (work-001-lite-aid-skills) -- the
  settled design this reference implements
- `canonical/skills/aid-execute/references/task-type-rules.md ## DESIGN` -- the
  per-type execution rule this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task DETAIL.md` -- the one-type-per-task
  contract
