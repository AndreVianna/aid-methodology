# Test & Experiment Skill Family (G7)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G7), §5.3 | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G7 — Test & Experiment)
- REQUIREMENTS.md §5.3 (Artifact-type dimension — ownership boundary)

## Description

The G7 shortcut skills for establishing confidence that something works and meets its criteria:
`aid-test` (bare default — author/extend/run functional tests: unit, integration, e2e, plus
model evaluation) and the test-kind forms `aid-test-security` (SAST/DAST/fuzz/dependency audit),
`aid-test-performance` (benchmark/load/stress against thresholds), and `aid-test-data-quality`
(schema, freshness, completeness checks on a dataset/pipeline). It also includes `aid-experiment`
(bare) — design, run, and analyze a controlled experiment or A/B test (hypothesis to variants to
metric to significance). The test and experiment domain belongs wholly to these verbs
(ownership boundary), not to `aid-create`.

## User Stories

- As an AID adopter who wants to add or extend tests, I want `aid-test[-kind]` so I get a Lite
  work scoped to the test kind.
- As an AID adopter validating a hypothesis, I want `aid-experiment` so an A/B test gets its own
  scaffolded Lite work.

## Priority

Must

## Acceptance Criteria

- [ ] Given the G7 skills, when the catalog is checked, then `aid-test`, its three test-kind
  forms (`-security`, `-performance`, `-data-quality`), and `aid-experiment` exist with valid
  `SKILL.md` state machines and the `aid-` prefix. (AC-1 — G7 subset)
- [ ] Given each G7 skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before
  shipping. (AC-7 — G7 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). Every G7 skill is a
> thin doorway binding `{verb, artifact}` and delegating to
> `canonical/aid/templates/shortcut-engine.md` (writes feature-001's flattened work, runs
> feature-004's gates). This feature contributes catalog rows + the test/experiment scaffolding
> reference.

### Catalog rows owned (AC-1 — G7 subset)

**5 canonical skills, no aliases ⇒ 5 `canonical/skills/aid-*/SKILL.md` directories:**

| `name` | verb | artifact | alias_of | group |
|---|---|---|---|---|
| `aid-test` | test | `""` (bare default: unit/integration/e2e + model eval) | null | G7 |
| `aid-test-security` | test | `security` | null | G7 |
| `aid-test-performance` | test | `performance` | null | G7 |
| `aid-test-data-quality` | test | `data-quality` | null | G7 |
| `aid-experiment` | experiment | `""` (bare) | null | G7 |

### Per-skill binding & default-type (feature-003 A-6 mapping)

**`test / test-* → TEST`; `experiment → RESEARCH`** (hypothesis → analyze → recommend;
`task-type-rules.md ## RESEARCH` "compare ≥2 alternatives … end with a recommendation"):

| Skill | `default_type` | Multi-type task set |
|---|---|---|
| `aid-test`, `aid-test-security`, `aid-test-performance`, `aid-test-data-quality` | `TEST` | single `TEST` task (plan + author + run) |
| `aid-experiment` | `RESEARCH` | `RESEARCH` (design + analysis plan); optional `IMPLEMENT` when variants must be built |

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/test-experiment.md`)

Grounded in the `add-test-coverage` recipe (task=1 TEST) and `digital-project-activities.md § 6`
(ISTQB test process), `§ 2` (model evaluation), `§ 3` (data-quality checks), `§ 8` (security
verification SAST/DAST), `§ 9` (A/B experiment). The engine infers the test framework from the KB
(`test-landscape.md`), so the framework is never a capture slot.

| Skill | SPEC section | CAPTURE slots (min) | Task-breakdown template |
|---|---|---|---|
| `aid-test` | `### BDD Scenarios` (opt) | **`mode=functional`** (default): target (class/method/module/feature); level (unit \| integration \| e2e); behavior under test. **`mode=model-eval`**: `model`; `eval-dataset`; `metric`/`threshold` | **functional:** `001` TEST — author/extend + run; each test traces to an AC (`task-type-rules.md ## TEST`). **model-eval:** `001` TEST — run the evaluation harness against `eval-dataset` and assert `metric` meets `threshold` (maps to the `TEST` type — no enum change; §5.1 puts model evaluation inside bare `aid-test`) |
| `aid-test-security` | `### Security Specs` | target surface; technique (`SAST` \| `DAST` \| `fuzz` \| `dependency-audit`); threat focus | `001` TEST — **security-verification plan + run** (SAST/DAST/fuzz/audit); findings route to `aid-fix` |
| `aid-test-performance` | (base) | target/hot-path; workload profile; threshold/SLO; environment | `001` TEST — benchmark/load/stress against the threshold |
| `aid-test-data-quality` | `### Data Model` | dataset/pipeline; checks (`schema` \| `freshness` \| `completeness` \| `uniqueness`); thresholds | `001` TEST — data-quality checks on the dataset/pipeline |
| `aid-experiment` | (base) | hypothesis; ≥2 variants; success metric; significance criteria; audience/segment | `001` RESEARCH (design: hypothesis→variants→metric→significance); opt `002` IMPLEMENT (build variants); `003` RESEARCH (analysis + recommendation) |

### Ownership boundary

**Test/experiment belong wholly to G7, not to `aid-create`** (§5.3). `aid-test-security` only
*verifies/plans* — the remediation of any finding is **`aid-fix`** (vulnerability kind); building the
feature under test is `aid-create`/`aid-change`; documenting a test strategy is `aid-document`; the
data pipeline that `aid-test-data-quality` checks is `aid-create-data-pipeline`. Analytical insight
from usage data (as opposed to a controlled experiment) is `aid-report` (G11).

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 5 rows** |
| `canonical/aid/templates/shortcut-scaffolding/test-experiment.md` | **new** — the family scaffolding reference (table above) |
| `canonical/skills/aid-test*/`, `aid-experiment/SKILL.md` × 5 | **generated** by feature-003's `build-shortcut-skills.py` — not hand-written |

No family-specific engine branch. Renders via the full `run_generator.py` to all five profiles
(NFR-1, AC-6). `aid-test` is in the Phase-2 pilot cohort (REQUIREMENTS § 10).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-test-security` produces a flattened work with
  `### Security Specs` activated and `tasks/task-001/` typed `TEST` (SAST/DAST plan), halting
  pre-Execute (FR-10). An `aid-experiment` fixture asserts a `RESEARCH`-typed `task-001` (the
  non-code default-type mapping, AC-4).
- **Catalog↔dirs parity** + `render-drift` cover the 5 rows/dirs (feature-003's tests; AC-1/AC-6).
