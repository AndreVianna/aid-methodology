# Shortcut Scaffolding: test / experiment

Per-family scaffolding reference for the **`test`** verb (bare `aid-test` plus
the three test-kind forms `-security`, `-performance`, `-data-quality`) and the
**`experiment`** verb (bare `aid-experiment` only; feature-009,
work-001-lite-aid-skills). Consulted by the shared engine
(`.claude/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field
resolves to `test` or `experiment`. No `aid-test-*`/`aid-experiment` row carries
an alias (feature-009 SPEC "Catalog rows owned" -- 5 canonical, no aliases).
Free-form prose, like any other `state-*.md` reference doc -- the dispatched
`aid-architect` reads this for judgment; it is not machine-parsed.

Grounded in the `add-test-coverage` recipe (task = 1 TEST), covering ISTQB
test process, model evaluation, data-quality checks, security verification
(SAST/DAST), and A/B experimentation. The engine infers the test framework
from the KB (`test-landscape.md`), so the framework is never a capture slot.

## `aid-test` -- two modes

Bare `aid-test` covers **functional** testing by default, plus a **model-eval**
mode when the description names a model/dataset/metric. `mode` is inferred
from `{description}`, never a captured slot the user is asked to choose --
description language such as "eval", "model", "accuracy", "dataset",
"threshold" signals model-eval; everything else defaults to functional.

### CAPTURE

| Mode | Slots |
|---|---|
| `functional` (default) | target (class/method/module/feature); level (`unit` \| `integration` \| `e2e`); behavior under test |
| `model-eval` | `model`; `eval-dataset`; `metric`/`threshold` |

### SPEC

`### BDD Scenarios` activates optionally, when the behavior under test reads
naturally as Given/When/Then scenarios (functional mode only); otherwise the
mandatory three sections suffice for both modes.

### DETAIL

| Mode | Task-breakdown template |
|---|---|
| `functional` | single `task-001` TEST -- author/extend + run; **each test traces to a specific acceptance criterion** (`task-type-rules.md ## TEST`) |
| `model-eval` | single `task-001` TEST -- run the evaluation harness against `eval-dataset` and assert `metric` meets `threshold` (maps to the `TEST` type; no enum change -- §5.1 places model evaluation inside bare `aid-test`, not a separate type) |

## `aid-test-security`

### CAPTURE

| Slot | Notes |
|---|---|
| Target surface | the endpoint/module/dependency set under verification |
| Technique | closed enum: `SAST` \| `DAST` \| `fuzz` \| `dependency-audit` |
| Threat focus | what class of finding this run is looking for |

### SPEC

Activates `### Security Specs`.

### DETAIL

Single `task-001` TEST -- security-verification plan + run (SAST/DAST/fuzz/
audit, per the captured technique). **Findings route to `aid-fix`** (vulnerability
kind) -- remediation is never folded into this task; the task's own scope ends
at the verification report.

## `aid-test-performance`

### CAPTURE

| Slot | Notes |
|---|---|
| Target/hot-path | the code path or endpoint under load |
| Workload profile | benchmark, load, or stress shape (concurrency, request rate, data volume) |
| Threshold/SLO | the pass/fail bound the run is measured against |
| Environment | where the run executes (matters for reproducibility) |

### SPEC

Base sections only (no conditional section).

### DETAIL

Single `task-001` TEST -- benchmark/load/stress the target against the
captured threshold; the result must be reproducible (same environment, same
workload profile, re-runnable).

## `aid-test-data-quality`

### CAPTURE

| Slot | Notes |
|---|---|
| Dataset/pipeline | the target being checked |
| Checks | closed enum, may be more than one: `schema` \| `freshness` \| `completeness` \| `uniqueness` |
| Thresholds | the pass/fail bound per check |

### SPEC

Activates `### Data Model`.

### DETAIL

Single `task-001` TEST -- data-quality checks on the dataset/pipeline per the
captured checks/thresholds. A data-pipeline's own build-time coverage
(`aid-create-data-pipeline`'s `task-002` TEST) stays shallow; a **deep**
data-quality need routes here instead of expanding that task.

## `aid-experiment`

Bare verb, no artifact parameter. Design, run, and analyze a controlled
experiment or A/B test (hypothesis -> variants -> metric -> significance).

### CAPTURE

| Slot | Notes |
|---|---|
| Hypothesis | the specific, falsifiable claim under test |
| Variants | at least 2 (control + at least one treatment) |
| Success metric | the metric the experiment decides on |
| Significance criteria | the statistical bar a result must clear to be actionable |
| Audience/segment | who the experiment runs against |

### SPEC

Base sections only (no conditional section).

### DETAIL

`RESEARCH -> [IMPLEMENT] -> RESEARCH` chain (`task-type-rules.md ## RESEARCH`
"compare >= 2 alternatives ... end with a recommendation"):

| Task | Type | Notes |
|---|---|---|
| `task-001` | RESEARCH | design: hypothesis -> variants -> metric -> significance plan |
| `task-002` (optional) | IMPLEMENT | build the variants, only when the description says the variants must be built (not needed for a purely analytical experiment against existing variants) |
| `task-003` (`task-002` when the IMPLEMENT task is skipped) | RESEARCH | run the experiment, analyze results against the significance criteria, end with a recommendation |

## Ownership boundary

**Test/experiment belong wholly to G7, not to `aid-create`.** `aid-test-security`
only *verifies/plans* -- the remediation of any finding is **`aid-fix`**
(vulnerability kind); building the feature under test is `aid-create`/
`aid-change`; documenting a test strategy is `aid-document`; the data pipeline
that `aid-test-data-quality` checks is built by `aid-create-data-pipeline`.
Analytical insight from usage data (as opposed to a controlled experiment) is
`aid-report` (G11), not `aid-experiment`.

## See also

- `.claude/aid/templates/shortcut-engine.md § Family Scaffolding Consult` --
  how this file is looked up and what happens when it is absent
- `.claude/aid/templates/shortcut-scaffolding/fix.md § Ownership boundary` --
  where a security finding's remediation routes
- `features/feature-009-test-and-experiment-family/SPEC.md`
  (work-001-lite-aid-skills) -- the settled design this reference implements
- `.claude/skills/aid-execute/references/task-type-rules.md ## TEST / ## RESEARCH`
  -- the per-type execution rules this breakdown maps onto
