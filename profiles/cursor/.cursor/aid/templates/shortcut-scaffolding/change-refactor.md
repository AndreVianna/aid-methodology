# Shortcut Scaffolding: change / refactor

Per-family scaffolding reference for the **`change`** verb (bare `aid-change`
plus the same eleven artifact-suffixed forms as `create`), the **`refactor`**
verb (bare `aid-refactor` only -- no artifact suffixes; feature-007,
work-001-lite-aid-skills), and, as a v2.1.0 coverage-gap follow-on, the bare
**`remove`** (`aid-remove` + `aid-delete` alias), **`deprecate`**
(`aid-deprecate`), and **`migrate`** (`aid-migrate`) verbs -- none of the three
takes an artifact suffix. Consulted by the shared engine
(`.cursor/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field
resolves to `change`, `refactor`, `remove`, `deprecate`, or `migrate` -- which
includes every `aid-update-*` alias row for `change` and the `aid-delete` alias
row for `remove` (an alias's `verb` already equals its canonical mirror's).
Free-form prose, like any other `state-*.md` reference doc -- the dispatched
`aid-architect` reads this for judgment; it is not machine-parsed.

Grounded in the `change-*` recipes this family generalizes (`change-schema`:
current-shape -> target-shape -> rationale) plus `rename-symbol` and
`improve-performance` (both absorbed into bare `aid-refactor`). Editing
**content** is routed to `aid-document`, not here.

**This file does not duplicate the artifact matrix.** `aid-change`'s
per-artifact SPEC-section activation and task-breakdown counts/types are
**identical to `aid-create`'s** (`shortcut-scaffolding/create.md`), just
modify-framed -- edit artifact specifics there, once; this file only adds the
change-specific capture on top and covers `aid-refactor`, `aid-remove`,
`aid-deprecate`, and `aid-migrate` (none of which `create.md` touches at all --
all four are bare verbs with their own CAPTURE/SPEC/DETAIL below, not
artifact-matrix entries).

## `change` -- CAPTURE, on top of the inherited artifact slots

`aid-change[-artifact]` first pulls the same per-artifact CAPTURE slots
`create.md § CAPTURE` lists for that `{artifact}` (e.g. `change-api` still
needs resource/endpoint/schema/security-notes), then adds:

| Slot | Notes |
|---|---|
| Current shape/behavior | what the artifact does/looks like **today** -- the delta's starting point |
| Target shape/behavior | what it should do/look like **after** the change |
| New acceptance criteria | the criteria this change introduces (§5.1 "new acceptance criteria") -- these become `SPEC.md § Acceptance Criteria`, not a rewrite of the artifact's pre-existing ones |
| Rationale | why the change is needed (bug report, new requirement, deprecation, etc.) |

**Escalation.** Same rule as the generic engine and `create.md`: escalate to
the one combined CAPTURE question only when the current-shape/target-shape
delta or the new acceptance criteria cannot be made concrete and testable from
`{verb, artifact, description}` + KB context.

## `change` -- SPEC section activation

Identical to `create.md § SPEC` for the same `{artifact}` (e.g. `change-api`
activates `### API Contracts`, `change-data-model` activates
`### Migration Plan`) -- consult that table directly; it is not repeated here.

## `change` -- DETAIL task breakdown

**The task count and types equal `create.md`'s artifact-matrix row for the
same `{artifact}`** -- a change to artifact X emits the same tasks as creating
X, modify-framed (task titles read "update"/"modify" instead of "build", and
each task's Scope is the delta under the new acceptance criteria, not a
from-scratch build). The change is scoped to the delta; it is never a reduced
task set relative to create's chain for that artifact. Consult
`create.md § DETAIL` for the authoritative per-artifact count/type table.

## `aid-refactor` -- CAPTURE

Absorbs the `rename-symbol` and `improve-performance` legacy recipes. Bare
verb, no artifact parameter:

| Slot | Notes |
|---|---|
| Target | the symbol / module / hot-path being refactored |
| Refactor kind | closed enum: `rename` \| `restructure` \| `performance` |
| Rationale | why the restructure/optimization is warranted |
| Behavior-preservation guarantee | how the invariant "no observable behavior change" will be verified (existing test suite; a new characterization test if coverage is thin) |
| (`performance` only) Measured baseline | the current metric, measured, not estimated |
| (`performance` only) Target + constraints | the metric to reach and any constraint (e.g. no new dependency) |

`refactor-kind` never blocks CAPTURE -- default to `restructure` when the
description does not clearly name `rename` or `performance`.

## `aid-refactor` -- SPEC section activation

The mandatory three sections (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) always apply, per the engine's own contract
(`shortcut-engine.md § State: SPEC` -- every generated SPEC.md carries the
mandatory three, `create.md § SPEC` likewise) -- `aid-refactor` activates no
additional conditional section for any `refactor-kind`. `### Data Model` and
`### Feature Flow` both read "unchanged -- behavior-preserving refactor" by
default (the refactor's own no-observable-behavior-change guarantee);
`### Layers & Components` carries the restructure substance -- the module(s)/
layer(s) actually touched -- which is the family's real focus (feature-007).
`performance` additionally adds a "no behavior change" invariant note to
`Feature Flow` (on top of its "unchanged" default), and a "no schema changes"
note to `Data Model` (on top of its "unchanged" default) when the hot-path
touches persistence. `rename` and `restructure` add no further note beyond
the "unchanged" default on those two sections.

## `aid-refactor` -- DETAIL task breakdown, by `refactor-kind`

| `refactor-kind` | Task-breakdown template |
|---|---|
| `rename` | single `task-001` REFACTOR -- rename across source/tests/docs; grep confirms no residual old name (the `rename-symbol` recipe shape) |
| `restructure` | `task-001` REFACTOR + `task-002` TEST -- full suite run after restructuring must match the pre-refactor baseline (same pass/fail) |
| `performance` | `task-001` REFACTOR (eliminate the bottleneck; behavior unchanged) + `task-002` TEST -- a reproducible benchmark meets the captured target vs. the captured baseline (the `improve-performance` recipe shape) |

`task-002` never folds back into `task-001` -- one type per task always holds
(`artifact-schemas.md § Task DETAIL.md`), matching `task-type-rules.md ## REFACTOR`
("NO behavior changes ... test suite AFTER must match baseline").

## `aid-remove` -- CAPTURE

Bare verb, no artifact parameter (v2.1.0 coverage-gap follow-on):

| Slot | Notes |
|---|---|
| Target to remove | the code artifact, endpoint, dependency, feature, or dead-code path being removed |
| Removal mode | closed enum: `hard-delete` (delete outright) \| `keep-shim` (leave a thin compatibility shim, e.g. for an already-deprecated API) |
| Callers / consumers | what currently depends on the target -- call sites, importers, downstream services (may be "none" for genuinely dead code) |

**Escalation.** Same rule as the generic engine: escalate to the one combined
CAPTURE question only when the target or its callers/consumers cannot be
identified concretely from `{description}` + KB context.

## `aid-remove` -- SPEC section activation

The mandatory three sections apply with no conditional section; `### Data Model`
and `### Feature Flow` read "removal only -- no new schema/flow, an existing one
is deleted"; `### Layers & Components` names every layer/consumer the removal
touches (the removal's real substance, mirroring `aid-refactor`'s own
"restructure substance" convention above).

## `aid-remove` -- DETAIL task breakdown

| Task | Type | Notes |
|---|---|---|
| `task-001` | REFACTOR | identify every usage/caller of `{target}` (grep/reference search across source, tests, docs), then remove the target itself |
| `task-002` | IMPLEMENT | update every dependent identified in `task-001` (call sites, config, wiring) so nothing references the removed target; depends on `task-001` |
| `task-003` | TEST | full suite run confirms no residual reference and no regression; depends on `task-002` |

Fold `task-002`/`task-003` into `task-001` only when the capture step found zero
dependents (genuinely dead code) -- state that explicitly in `BLUEPRINT.md § Scope`
when it applies. One type per task still holds
(`artifact-schemas.md § Task DETAIL.md`).

## `aid-deprecate` -- CAPTURE

Bare verb, no artifact parameter (v2.1.0 coverage-gap follow-on):

| Slot | Notes |
|---|---|
| Target | the existing artifact/API being deprecated -- not yet removed |
| Replacement / migration path | what callers should use instead, and how to move to it |
| Removal timeline | when the deprecated target is actually expected to go away (a version, a date, or "not yet scheduled") |

**Escalation.** Same rule: escalate only when the target or its
replacement/migration path cannot be made concrete from `{description}` + KB
context.

## `aid-deprecate` -- SPEC section activation

The mandatory three sections apply with no conditional section; `### Feature Flow`
documents the deprecation-warning path (where/how the warning surfaces to a
caller) layered on top of the target's existing, otherwise-unchanged flow.

## `aid-deprecate` -- DETAIL task breakdown

| Task | Type | Notes |
|---|---|---|
| `task-001` | IMPLEMENT | add the deprecation marker/warning (language-native deprecation annotation, runtime log warning, or doc banner, per KB convention) and write the migration-path note pointing at the replacement |

Single-task by default -- deprecating adds a marker/warning, it does not remove
anything yet (that is a later, separate `aid-remove` once the removal timeline
arrives).

## `aid-migrate` -- CAPTURE

Bare verb, no artifact parameter (v2.1.0 coverage-gap follow-on):

| Slot | Notes |
|---|---|
| From -> To | the current state and the target state (a dependency version, a framework, a platform, or a dataset's current location) |
| Scope | closed enum: `data` \| `dependency` \| `framework` \| `platform` -- narrows what the MIGRATE task actually moves. Non-schema: a schema/entity migration stays `aid-create-data-model`/`aid-change-data-model`, not here |
| Rollback plan | how to revert if the migration fails partway -- `task-type-rules.md ## MIGRATE` requires this unconditionally |

**Escalation.** Same rule: escalate only when the From -> To delta or the
rollback plan cannot be made concrete from `{description}` + KB context.

## `aid-migrate` -- SPEC section activation

The mandatory three sections apply; `### Migration Plan` additionally activates
(the same conditional section `create.md` activates for a `data-model` artifact)
-- it captures the From -> To delta, `{scope}`, and rollback plan as the concrete
plan the MIGRATE task executes against.

## `aid-migrate` -- DETAIL task breakdown

| Task | Type | Notes |
|---|---|---|
| `task-001` | MIGRATE | write the forward migration script/procedure per `{scope}`, with the captured rollback script/procedure (`task-type-rules.md ## MIGRATE`) |
| `task-002` | TEST | verify the migrated state matches `{To}`, and that the rollback script actually reverts; depends on `task-001` |

## Ownership boundary

`aid-change` = modify an existing artifact's **behavior/intent** (new
acceptance criteria). `aid-refactor` = restructure/optimize **without**
changing behavior -- the split is behavior-changing vs. not. Creating a *new*
artifact is `aid-create` (`shortcut-scaffolding/create.md`). Correcting a
**defect** is `aid-fix` (`shortcut-scaffolding/fix.md`), not `aid-change` --
a defect is "the code violates its own spec/intent"; new intent is a change.
Behavior-preserving cleanup with no observable defect is `aid-refactor`, not
`aid-fix`. Editing **content/docs** is `aid-document`; changing **tests** is
`aid-test`; the legacy `change-report`/`change-docs` recipe territory moves to
G8/G11 per the artifact-ownership boundary and is **not** a `aid-change`
artifact. **Removing** an artifact outright is `aid-remove`, not `aid-change` --
a change modifies behavior in place, a removal deletes the artifact and its
call sites. **Deprecating** is the middle step between `aid-change`/no action
and `aid-remove`: the target still works, but callers are warned off it ahead
of a later, separate removal -- `aid-deprecate` never deletes anything itself.
**Migrating** data/a dependency/a framework/a platform is `aid-migrate`, kept
distinct from a **schema** migration (`aid-create-data-model`/
`aid-change-data-model`, G4/G5's own `data-model` artifact suffix) by scope,
not by verb family. Assessing whether something *should* be removed/deprecated/
migrated, before committing to the change, is `aid-review`/`aid-research`
(G11, `shortcut-scaffolding/analyze-report.md`) -- this file's four verbs all
assume the decision to act has already been made.

## See also

- `.cursor/aid/templates/shortcut-scaffolding/create.md` -- the artifact
  matrix (SPEC sections + task breakdown) this file inherits by reference
- `.cursor/aid/templates/shortcut-scaffolding/analyze-report.md § aid-review /
  § aid-research` -- where the decision to remove/deprecate/migrate gets
  assessed before this file's verbs act on it
- `.cursor/aid/templates/shortcut-engine.md § Family Scaffolding Consult` --
  how this file is looked up and what happens when it is absent
- `features/feature-007-change-and-refactor-family/SPEC.md`
  (work-001-lite-aid-skills) -- the settled design this reference implements
- `.cursor/skills/aid-execute/references/task-type-rules.md ## MIGRATE /
  ## REFACTOR / ## IMPLEMENT` -- the per-type execution rules
  `aid-remove`/`aid-deprecate`/`aid-migrate` map onto
- `.aid/knowledge/artifact-schemas.md § Task DETAIL.md` -- the one-type-per-task
  contract
- `.cursor/skills/aid-execute/references/task-type-rules.md ## REFACTOR` --
  the behavior-preservation execution rule
