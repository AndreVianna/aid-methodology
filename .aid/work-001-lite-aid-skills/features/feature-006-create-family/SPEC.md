# Create Skill Family (G4)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G4), §5.3, §5.4 | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G4 — Create)
- REQUIREMENTS.md §5.3 (Artifact-type dimension), §5.4 (Naming scheme)

## Description

The G4 shortcut skills for creating a new artifact from scratch: bare `aid-create` (internal
code — module, interface, type, and any artifact with no suffix) plus the eleven artifact-suffixed
forms (`-api`, `-ui`, `-theme`, `-cli`, `-data-model`, `-data-pipeline`, `-messaging`,
`-integration`, `-job`, `-config`, `-infra`) and the `aid-add-*` alias family that mirrors every
create form (12 aliases). Each form draws on the skill-internal scaffolding knowledge for its `(create x artifact)`
combination to shape the spec and task set (there is no separate recipe/profile catalog).

## User Stories

- As an AID adopter who knows they are building something new, I want `aid-create[-artifact]`
  (or the `aid-add` alias) so I get a Lite work tuned to the artifact type without the interview.
- As an AID adopter, I want the `aid-add-*` aliases to resolve to their `aid-create`
  counterparts so I can guess either verb and land on the same skill.

## Priority

Must

## Acceptance Criteria

- [ ] Given the G4 skills, when the catalog is checked, then `aid-create` and its eleven
  artifact-suffixed forms exist with valid `SKILL.md` state machines and the `aid-` prefix, and
  the twelve `aid-add-*` aliases resolve correctly. (AC-1 — G4 subset)
- [ ] Given `aid-create`, when invoked with one of the eleven artifact suffixes, then it expands
  across those suffixes and drives the matching skill-internal scaffolding (spec shape + task set); bare `aid-create` covers internal code
  with no suffix. (AC-4 — create-expansion half)
- [ ] Given each G4 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G4 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). Every G4 skill is a
> thin doorway that binds `{verb=create, artifact}` and delegates to
> `canonical/aid/templates/shortcut-engine.md`, which writes feature-001's flattened work and runs
> feature-004's gates. This feature contributes catalog rows + the create scaffolding reference; it
> does not re-spec the engine.

### Catalog rows owned (AC-1 — G4 subset)

**12 canonical + 12 `aid-add-*` aliases = 24 `canonical/skills/aid-*/SKILL.md` directories.** The
alias family mirrors **every** create form (including bare `aid-add` == `aid-create`, per §5.4);
`add` binds the identical `{verb=create, artifact}` as its canonical mirror (feature-003: aliases
are separate dirs, not a runtime alias — there is no alias facility in the generator). Each is a
row in `canonical/aid/templates/shortcut-catalog.yml`:

| Canonical (`verb=create`) | artifact | Alias (`verb=create`, `alias_of`) |
|---|---|---|
| `aid-create` | `""` (bare = internal code: module/interface/type) | `aid-add` |
| `aid-create-api` | `api` | `aid-add-api` |
| `aid-create-ui` | `ui` | `aid-add-ui` |
| `aid-create-theme` | `theme` | `aid-add-theme` |
| `aid-create-cli` | `cli` | `aid-add-cli` |
| `aid-create-data-model` | `data-model` | `aid-add-data-model` |
| `aid-create-data-pipeline` | `data-pipeline` | `aid-add-data-pipeline` |
| `aid-create-messaging` | `messaging` | `aid-add-messaging` |
| `aid-create-integration` | `integration` | `aid-add-integration` |
| `aid-create-job` | `job` | `aid-add-job` |
| `aid-create-config` | `config` | `aid-add-config` |
| `aid-create-infra` | `infra` | `aid-add-infra` |

### Per-skill binding & default-type (feature-003 A-6 mapping)

Verb `create` maps to `IMPLEMENT` for code/api/ui/theme/cli/data-pipeline/messaging/integration/
job/infra; **`config → CONFIGURE`** and **`data-model → MIGRATE`** are the two exceptions per
feature-003's settled table. Aliases inherit their mirror's `default_type`. `default_type` is the
**primary** task's type; multi-task shortcuts still emit one Type per task (`artifact-schemas.md §
Task SPEC.md` — never mixed):

| verb×artifact | `default_type` | Multi-type task set |
|---|---|---|
| create (bare code), create-api, create-ui, create-theme, create-cli, create-messaging, create-integration, create-job, create-data-pipeline, create-infra | `IMPLEMENT` | code + `TEST` (some artifacts add a `TEST` task — see breakdown) |
| create-config | `CONFIGURE` | single `CONFIGURE` task |
| create-data-model | `MIGRATE` | `MIGRATE` (schema+migration) + `IMPLEMENT` (repo/model wiring) + `TEST` |

> Grounded change vs. the legacy recipes: `add-entity`/`change-schema` typed their migration task
> `IMPLEMENT`; feature-003's mapping types it **`MIGRATE`** (matching `task-type-rules.md ##
> MIGRATE` "reversible … idempotent … rollback script"). The create family follows feature-003.
> `infra` stays `IMPLEMENT` per feature-003 even though an IaC-only provision may carry a
> `CONFIGURE` sub-task; the row `default_type` is not changed.

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/create.md`)

The per-`create×artifact` knowledge the engine consults, authored once and keyed by artifact. It is
the recipe scaffolding **migrated in** (FR-14) minus the recipe's spec-header boilerplate (that is
now the standard `spec-template.md`/`PLAN.md`). CAPTURE lists only load-bearing unknowns (the
engine infers stack/framework/persistence-layer/test-framework from the KB via `technology-stack.md`
/ `test-landscape.md`, so those are never asked). Activity shapes: `digital-project-activities.md
§§ 1, 3` (build/create; data pipeline = DataOps orchestration, the one artifact with **no** legacy
recipe).

| artifact | SPEC section(s) activated | CAPTURE slots (min) | Task-breakdown template |
|---|---|---|---|
| bare (code) | `Layers & Components`, `Feature Flow` | target module/interface, contract, behavior | `001` IMPLEMENT (build + unit tests) |
| api | `### API Contracts` | resource, endpoint path, request/response schema, security notes | `001` IMPLEMENT schema/model, `002` IMPLEMENT handler+persistence, `003` TEST integration |
| ui | `### UI Specs` | component/page name, props/API **or** route, visual spec, usage context | `001` IMPLEMENT build, `002` TEST unit/UI |
| theme | `### UI Specs` (style) | token/style name, visual spec, affected components | `001` IMPLEMENT define tokens + apply (+ visual-regression note) |
| cli | `Layers & Components` | command signature, help text, output behavior, parent command | `001` IMPLEMENT register+wire, `002` TEST |
| data-model | `### Data Model` + `### Migration Plan` | entity/schema, relationships, validation rules | `001` MIGRATE schema+migration, `002` IMPLEMENT repo/model wiring, `003` TEST |
| data-pipeline | `### Batch/Jobs` + `### Data Model` | source, transform, sink, schedule/trigger, expected data-quality invariants | `001` IMPLEMENT pipeline, `002` TEST (deep data-quality → route to `aid-test-data-quality`) |
| messaging | `### Events & Messaging` | message/event schema, emit location, consumer/routing notes | `001` IMPLEMENT schema+emit, `002` TEST |
| integration | `### External Integrations` | service API, purpose, auth approach, error-handling strategy | `001` IMPLEMENT client/adapter, `002` TEST integration (stub/sandbox) |
| job | `### Batch/Jobs` | purpose, schedule/trigger, logic, error/retry policy | `001` IMPLEMENT job+schedule, `002` TEST |
| config | (base + document the option) | option name, purpose, default+validation, affected behavior | `001` CONFIGURE define+wire+document |
| infra | `### Cloud Support` / `### Hardware Requirements` | resource name, purpose, access policy, config/retention | `001` IMPLEMENT provision+wire+verify connectivity |

### Ownership boundary

Bare `aid-create` owns **internal code** (module/interface/type/member — no `-code` suffix, which
would collide with the bare verb). Per §5.3 the following do **not** belong to create even when
phrased as "create a …": **test → `aid-test`**, **experiment → `aid-experiment`**, **doc/content →
`aid-document`**, **report/dashboard → `aid-report` / `aid-show-dashboard`**. A create work still
emits its own `TEST` task for the artifact it builds (as the recipes did) — that is coverage of the
new artifact, not a standalone test-authoring request. Modifying an existing artifact is
`aid-change` (feature-007), not create.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 24 rows** (12 create + 12 `aid-add-*` aliases) |
| `canonical/aid/templates/shortcut-scaffolding/create.md` | **new** — the create scaffolding reference (table above) |
| `canonical/skills/aid-create*/`, `canonical/skills/aid-add*/SKILL.md` × 24 | **generated** by feature-003's `build-shortcut-skills.py` from the catalog — **not hand-written** |

No family-specific engine branch — the artifact parameter selects the scaffolding-reference row;
the engine is generic. Renders via the full `run_generator.py` to all five profiles (NFR-1, AC-6).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-create-api "orders resource"` produces a
  flattened Lite work whose `SPEC.md` has `### API Contracts` activated and whose `tasks/` are
  `001` IMPLEMENT (schema) → `002` IMPLEMENT (handler) → `003` TEST, with the `## Execution Graph`
  in `PLAN.md` carrying that dependency chain; it halts pre-Execute (FR-10). A second fixture for
  `aid-create-data-model` asserts a `MIGRATE`-typed `task-001` (the feature-003 reclassification).
- **Alias equivalence**: `aid-add-api` scaffolds the byte-identical work shape as `aid-create-api`
  (same `{verb, artifact}` binding) — proving the 12 aliases resolve correctly (AC-1).
- **Catalog↔dirs parity** + `render-drift` cover the 24 rows/dirs (feature-003's tests; AC-1/AC-6).
