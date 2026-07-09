# Shortcut Scaffolding: create

Per-family scaffolding reference for the **`create`** verb (bare `aid-create` --
internal code, no artifact suffix -- plus the eleven artifact-suffixed forms;
feature-006, work-001-lite-aid-skills). Consulted by the shared engine
(`.codex/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field
resolves to `create` -- which includes every `aid-add-*` alias row (an alias's
`verb` already equals its canonical mirror's, per the engine's own resolution
rule). Free-form prose, like any other `state-*.md` reference doc -- the
dispatched `aid-architect` reads this for judgment; it is not machine-parsed.

Grounded in the `add-*` recipes this family generalizes (`add-api`, `add-ui`,
`add-entity`, ...) -- `data-pipeline` (DataOps pipeline orchestration) is the
one artifact with **no** legacy recipe precedent.

## CAPTURE -- minimal slot list, per artifact

Beyond the engine's generic slot inventory
(`shortcut-engine.md § Capture-Minimization Rules`), a create additionally
needs the slots below, keyed by `{artifact}`. The engine already infers
stack/framework/persistence-layer/test-framework from the KB
(`technology-stack.md` / `test-landscape.md`), so those are never asked here.

| artifact | CAPTURE slots (min) |
|---|---|
| bare (code) | target module/interface/type; contract; behavior |
| `api` | resource; endpoint path; request/response schema; security notes |
| `ui` | component/page name; props/API **or** route; visual spec; usage context |
| `theme` | token/style name; visual spec; affected components |
| `cli` | command signature; help text; output behavior; parent command |
| `data-model` | entity/schema; relationships; validation rules |
| `data-pipeline` | source; transform; sink; schedule/trigger; expected data-quality invariants |
| `messaging` | message/event schema; emit location; consumer/routing notes |
| `integration` | service API; purpose; auth approach; error-handling strategy |
| `job` | purpose; schedule/trigger; logic; error/retry policy |
| `config` | option name; purpose; default + validation; affected behavior |
| `infra` | resource name; purpose; access policy; config/retention |

**Escalation.** The generic engine rule already covers this: escalate to the
one combined CAPTURE question only when §5/§9 cannot be made concrete and
testable from `{verb, artifact, description}` + KB context -- for create this
most often means the target's contract/schema/shape is missing entirely, not
merely terse.

## SPEC -- conditional section activation, per artifact

The mandatory three sections (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) always apply. On top of those, `{artifact}` gates
one conditional `## Technical Specification` section (`config` and bare code
activate none beyond the mandatory three):

| artifact | Conditional section activated |
|---|---|
| bare (code) | none (mandatory three only) |
| `api` | `### API Contracts` |
| `ui` | `### UI Specs` |
| `theme` | `### UI Specs` (style) |
| `cli` | none (mandatory three only) |
| `data-model` | `### Migration Plan` |
| `data-pipeline` | `### Batch/Jobs` |
| `messaging` | `### Events & Messaging` |
| `integration` | `### External Integrations` |
| `job` | `### Batch/Jobs` |
| `config` | none -- base sections document the option directly |
| `infra` | `### Cloud Support` / `### Hardware Requirements` |

## DETAIL -- default task breakdown, per artifact

Every task chain below is one type per task (`artifact-schemas.md § Task
SPEC.md` -- never mixed), natural ordering
MIGRATE first when present, then RESEARCH -> DESIGN -> IMPLEMENT -> TEST ->
DOCUMENT. This table is the **canonical artifact matrix** the `aid-change`/
`aid-refactor` family (`shortcut-scaffolding/change-refactor.md`) inherits by
reference rather than duplicating -- edit artifact specifics here, once.

| artifact | Task-breakdown template |
|---|---|
| bare (code) | `task-001` IMPLEMENT (build + unit tests) |
| `api` | `task-001` IMPLEMENT (schema/model), `task-002` IMPLEMENT (handler + persistence), `task-003` TEST (integration) |
| `ui` | `task-001` IMPLEMENT (build), `task-002` TEST (unit/UI) |
| `theme` | `task-001` IMPLEMENT (define tokens + apply; note a visual-regression check if the KB's test-landscape names one) |
| `cli` | `task-001` IMPLEMENT (register + wire), `task-002` TEST |
| `data-model` | `task-001` MIGRATE (schema + migration), `task-002` IMPLEMENT (repo/model wiring), `task-003` TEST |
| `data-pipeline` | `task-001` IMPLEMENT (pipeline), `task-002` TEST (a deep data-quality need routes to `aid-test-data-quality` instead of expanding this task) |
| `messaging` | `task-001` IMPLEMENT (schema + emit), `task-002` TEST |
| `integration` | `task-001` IMPLEMENT (client/adapter), `task-002` TEST (integration, stub/sandbox) |
| `job` | `task-001` IMPLEMENT (job + schedule), `task-002` TEST |
| `config` | `task-001` CONFIGURE (define + wire + document) |
| `infra` | `task-001` IMPLEMENT (provision + wire + verify connectivity) |

Every multi-task artifact's task dependencies are strictly sequential
(`task-002` depends on `task-001`, `task-003` depends on `task-002`) --
DETAIL's `## Execution Graph` places each in its own wave.

## Ownership boundary

Bare `aid-create` owns **internal code** (module/interface/type/member -- no
`-code` suffix, which would collide with the bare verb). The following do
**not** belong to create even when phrased as "create a ...": **test ->
`aid-test`**, **experiment -> `aid-experiment`**, **doc/content ->
`aid-document`**, **report/dashboard -> `aid-report` / `aid-show-dashboard`**.
A create work still emits its own `TEST` task for the artifact it builds (the
same coverage the legacy `add-*` recipes carried) -- that is coverage of the
new artifact, not a standalone test-authoring request. Modifying an
**existing** artifact is `aid-change` (`shortcut-scaffolding/change-refactor.md`),
not create.

## See also

- `.codex/aid/templates/shortcut-engine.md § Family Scaffolding Consult` --
  how this file is looked up and what happens when it is absent
- `.codex/aid/templates/shortcut-scaffolding/change-refactor.md` -- inherits
  this file's artifact matrix, modify-framed
- `features/feature-006-create-family/SPEC.md` (work-001-lite-aid-skills) --
  the settled design this reference implements
- `.aid/knowledge/artifact-schemas.md § Task SPEC.md` -- the one-type-per-task
  contract
