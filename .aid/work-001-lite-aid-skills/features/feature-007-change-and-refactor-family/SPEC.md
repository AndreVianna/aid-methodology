# Change & Refactor Skill Family (G5)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G5), §5.3, §5.4 | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G5 — Change + Refactor)
- REQUIREMENTS.md §5.3 (Artifact-type dimension), §5.4 (Naming scheme)

## Description

The G5 shortcut skills for modifying an existing artifact: bare `aid-change` (modify an
artifact's behavior/intent with new acceptance criteria — internal code and residual) plus the
same eleven artifact-suffixed forms as `aid-create` and the `aid-update-*` alias family that
mirrors every change form (12 aliases). It also includes `aid-refactor` (bare) — restructuring
or optimizing code without changing behavior, absorbing rename-symbol and improve-performance.
`aid-refactor` stays bare, with no artifact-suffixed variants.

## User Stories

- As an AID adopter changing an existing artifact's behavior, I want `aid-change[-artifact]`
  (or the `aid-update` alias) so I get a Lite work with the change's new acceptance criteria
  captured.
- As an AID adopter cleaning up or optimizing code, I want `aid-refactor` (bare) so a
  behavior-preserving restructure gets its own scaffolded Lite work.

## Priority

Must

## Acceptance Criteria

- [ ] Given the G5 skills, when the catalog is checked, then `aid-change` and its eleven
  artifact-suffixed forms and `aid-refactor` exist with valid `SKILL.md` state machines and the
  `aid-` prefix, and the twelve `aid-update-*` aliases resolve correctly. (AC-1 — G5 subset)
- [ ] Given `aid-change`, when invoked with an artifact suffix, then it expands across the same
  eleven suffixes as `aid-create`; `aid-refactor` stays bare with no artifact-suffixed variants.
  (AC-4 — change-expansion + refactor-bare)
- [ ] Given each G5 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G5 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). Every G5 skill is a
> thin doorway binding `{verb, artifact}` and delegating to
> `canonical/aid/templates/shortcut-engine.md` (writes feature-001's flattened work, runs
> feature-004's gates). This feature contributes catalog rows + the change/refactor scaffolding
> reference; it does not re-spec the engine.

### Catalog rows owned (AC-1 — G5 subset)

**13 canonical (`aid-change` + 11 suffixes + `aid-refactor`) + 12 `aid-update-*` aliases = 25
`canonical/skills/aid-*/SKILL.md` directories.** `aid-update-*` mirrors **every** change form
(including bare `aid-update` == `aid-change`, §5.4). **`aid-refactor` is bare with NO alias and no
artifact suffixes** (only `aid-add`/`aid-update` are alias families; refactor stands alone, §5.4).

| Canonical | verb | artifact | Alias (`alias_of`) |
|---|---|---|---|
| `aid-change` | change | `""` (internal code + residual) | `aid-update` |
| `aid-change-api … aid-change-infra` (11: api, ui, theme, cli, data-model, data-pipeline, messaging, integration, job, config, infra) | change | each suffix | `aid-update-<suffix>` (11) |
| `aid-refactor` | refactor | `""` (bare) | — (none) |

### Per-skill binding & default-type (feature-003 A-6 mapping)

`aid-change` mirrors `aid-create`'s per-artifact mapping exactly (**`config → CONFIGURE`**,
**`data-model → MIGRATE`**, all others `IMPLEMENT`); aliases inherit their mirror. **`aid-refactor
→ REFACTOR`** (behavior-preserving; `task-type-rules.md ## REFACTOR` "NO behavior changes … test
suite AFTER must match baseline").

| Skill(s) | `default_type` | Task set (**= `aid-create`'s per-artifact chain, modify-framed**) |
|---|---|---|
| `aid-change` (bare/code), `-api`, `-ui`, `-theme`, `-cli`, `-messaging`, `-integration`, `-job`, `-data-pipeline`, `-infra` | `IMPLEMENT` | the **same task chain as creating that artifact** (feature-006): `-api` = IMPLEMENT + IMPLEMENT + TEST; `-ui`/`-cli`/`-messaging`/`-integration`/`-job`/`-data-pipeline` = IMPLEMENT + TEST; `-theme`/`-infra`/bare/code = single IMPLEMENT (matching create-theme/create-infra) |
| `aid-change-config` | `CONFIGURE` | single `CONFIGURE` task (== `create-config`) |
| `aid-change-data-model` | `MIGRATE` | `MIGRATE` (forward+rollback) + `IMPLEMENT` (update readers/writers) + `TEST` (== `create-data-model`) |
| `aid-refactor` | `REFACTOR` | `REFACTOR` (restructure) + `TEST` (verify baseline unchanged / benchmark) |

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/change-refactor.md`)

**Change inherits `aid-create`'s per-artifact task set** (feature-006 / `create.md`) — same
SPEC-section activation and the **same task chain** (a change to artifact X emits the same tasks as
creating X: `change-api` = 3, `change-data-model` = MIGRATE+IMPLEMENT+TEST, `change-ui` = 2, …),
just **modify-framed**. The reference does not duplicate the artifact matrix; it adds the
change-specific capture and defers artifact specifics to `create.md`. Activity shapes:
`digital-project-activities.md § 1` (perfective maintenance / refactor) and `§ 5` (edit content —
routed to `aid-document`).

**Change-specific CAPTURE (on top of the artifact's create slots):** current shape/behavior; target
shape/behavior; the **new acceptance criteria** the change introduces (§5.1 "new acceptance
criteria"); rationale. Grounded in the `change-*` recipes (`change-schema`: current-shape →
target-shape → rationale). The task **count and types equal the create artifact chain** above — the
change is scoped to the delta (edit current→target under the new acceptance criteria), not a reduced
task set.

**Refactor CAPTURE + task template** (absorbs `rename-symbol` + `improve-performance`, §5.1):
- slots: target (symbol / module / hot-path); refactor kind (`rename` \| `restructure` \|
  `performance`); rationale; for `performance` — measured baseline + target + constraints;
  behavior-preservation guarantee.
- `rename` → single `task-001` REFACTOR (rename across source/tests/docs; grep confirms no residual
  old name — the `rename-symbol` recipe shape).
- `restructure` → `task-001` REFACTOR + `task-002` TEST (full suite matches baseline).
- `performance` → `task-001` REFACTOR (eliminate bottleneck, behavior unchanged) + `task-002` TEST
  (reproducible benchmark meets target vs. baseline — the `improve-performance` recipe shape).
- SPEC activation: base `Layers & Components`; `performance` adds a "no behavior change" invariant
  note; Data Model "no schema changes."

### Ownership boundary

`aid-change` = modify an existing artifact's **behavior/intent** (new acceptance criteria);
`aid-refactor` = restructure/optimize **without** changing behavior — the split is behavior-changing
vs. not. Creating a *new* artifact is `aid-create` (feature-006). Correcting a **defect** is
`aid-fix` (feature-008), not `aid-change`. Editing **content/docs** is `aid-document`; changing
**tests** is `aid-test`; the `change-report`/`change-docs` legacy recipe territory moves to G8/G11
per the §5.3 ownership boundary and is **not** a `aid-change` artifact.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 25 rows** (13 canonical + 12 `aid-update-*`) |
| `canonical/aid/templates/shortcut-scaffolding/change-refactor.md` | **new** — change modify-framing + the refactor scaffolding (references `create.md` for artifact specifics) |
| `canonical/skills/aid-change*/`, `aid-update*/`, `aid-refactor/SKILL.md` × 25 | **generated** by feature-003's `build-shortcut-skills.py` — not hand-written |

No family-specific engine branch. Renders via the full `run_generator.py` to all five profiles
(NFR-1, AC-6).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-change-data-model` produces a flattened work
  with `### Data Model` + `### Migration Plan` activated and `tasks/` `001` MIGRATE (forward+
  rollback) → `002` IMPLEMENT → `003` TEST; halts pre-Execute (FR-10).
- **Refactor proof**: `aid-refactor` (performance mode) scaffolds `001` REFACTOR + `002` TEST with a
  behavior-preservation AC; a rename-mode invocation scaffolds a single REFACTOR task — proving
  `aid-refactor` stays bare and behavior-preserving (AC-4).
- **Alias equivalence**: `aid-update-api` ≡ `aid-change-api` shape (AC-1). Catalog↔dirs parity +
  `render-drift` cover the 25 rows/dirs (AC-1/AC-6).
